#!/usr/bin/env bash

NETDISCO_DB_NAME="${NETDISCO_DB_NAME:-netdisco}"
NETDISCO_DB_USER="${NETDISCO_DB_USER:-netdisco}"
NETDISCO_DB_PASS="${NETDISCO_DB_PASS:-netdisco}"
NETDISCO_ADMIN_USER="${NETDISCO_ADMIN_USER:-guest}"

psql=( psql -X -v ON_ERROR_STOP=0 -v ON_ERROR_ROLLBACK=on )
psql+=( --username ${NETDISCO_DB_USER} --dbname ${NETDISCO_DB_NAME} )

echo >&2 "netdisco-db-entrypoint: bringing schema up-to-date"
ls -1 /var/lib/postgresql/netdisco-sql/App-Netdisco-DB-* | \
  xargs -n1 basename | sort -n -t '-' -k4 | \
  while read file; do
    "${psql[@]}" -f "/var/lib/postgresql/netdisco-sql/$file"
  done

echo >&2 "netdisco-db-entrypoint: importing OUI"
# TODO a way to refresh/update oui
NUMOUI=$("${psql[@]}" -A -t -c "SELECT count(oui) FROM oui")
if [ "$NUMOUI" -eq 0 ]; then
  "${psql[@]}" -f /var/lib/postgresql/netdisco-sql/oui.sql
fi

echo >&2 "netdisco-db-entrypoint: marking schema as up-to-date"
MAXSCHEMA=$(grep VERSION /var/lib/postgresql/netdisco-sql/DB.pm | sed 's/[^0-9]//g')
STAMP=$(date '+v%Y%m%d_%H%M%S.000')
"${psql[@]}" -c "CREATE TABLE dbix_class_schema_versions (version varchar(10) PRIMARY KEY, installed varchar(20) NOT NULL)"
"${psql[@]}" -c "INSERT INTO dbix_class_schema_versions VALUES ('${MAXSCHEMA}', '${STAMP}')"

echo >&2 "netdisco-db-entrypoint: adding admin user if none exists"
if [ -z $("${psql[@]}" -A -t -c "SELECT 1 FROM users WHERE admin") ]; then
  "${psql[@]}" -c "INSERT INTO users (username, port_control, admin) VALUES ('${NETDISCO_ADMIN_USER}', true, true)"
fi

echo >&2 "netdisco-db-entrypoint: adding session key if none exists"
if [ -z $("${psql[@]}" -A -t -c "SELECT 1 FROM sessions WHERE id = 'dancer_session_cookie_key'") ]; then
  "${psql[@]}" -c "INSERT INTO sessions (id, a_session) VALUES ('dancer_session_cookie_key', md5(random()::text))"
fi

echo >&2 "netdisco-db-entrypoint: queueing stats job"
"${psql[@]}" -c "INSERT INTO admin (action, status) VALUES ('stats', 'queued')"
