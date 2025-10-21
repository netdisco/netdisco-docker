#!/usr/bin/env bash

NETDISCO_ADMIN_USER="${NETDISCO_ADMIN_USER:-guest}"

export COL='\033[0;35m'
export NC='\033[0m'

psql=( psql -X -v ON_ERROR_STOP=0 -v ON_ERROR_ROLLBACK=on )

echo >&2 -e "${COL}netdisco-db-entrypoint: bringing schema up-to-date${NC}"
ls -1 /home/netdisco/perl5/lib/perl5/auto/share/dist/App-Netdisco/schema_versions/App-Netdisco-DB-* | \
  xargs -n1 basename | sort -n -t '-' -k4 | \
  while read file; do
    "${psql[@]}" -f "/home/netdisco/perl5/lib/perl5/auto/share/dist/App-Netdisco/schema_versions/$file" >/dev/null 2>&1
  done

echo >&2 -e "${COL}netdisco-db-entrypoint: importing OUI${NC}"
"${psql[@]}" -f /var/lib/postgresql/netdisco-sql/netdisco-lookup-tables.sql

echo >&2 -e "${COL}netdisco-db-entrypoint: marking schema as up-to-date${NC}"
MAXSCHEMA=$(grep VERSION /home/netdisco/perl5/lib/perl5/App/Netdisco/DB.pm | sed 's/[^0-9]//g')
STAMP=$(date '+v%Y%m%d_%H%M%S.000')
"${psql[@]}" -c "CREATE TABLE dbix_class_schema_versions (version varchar(10) PRIMARY KEY, installed varchar(20) NOT NULL)" >/dev/null 2>&1
"${psql[@]}" -c "INSERT INTO dbix_class_schema_versions VALUES ('${MAXSCHEMA}', '${STAMP}')" >/dev/null 2>&1

echo >&2 -e "${COL}netdisco-db-entrypoint: adding admin user if none exists${NC}"
if [ -z $("${psql[@]}" -A -t -c "SELECT 1 FROM users WHERE admin") ]; then
  "${psql[@]}" -c "INSERT INTO users (username, port_control, admin) VALUES ('${NETDISCO_ADMIN_USER}', true, true)"
fi

echo >&2 -e "${COL}netdisco-db-entrypoint: adding session key if none exists${NC}"
if [ -z $("${psql[@]}" -A -t -c "SELECT 1 FROM sessions WHERE id = 'dancer_session_cookie_key'") ]; then
  "${psql[@]}" -c "INSERT INTO sessions (id, a_session) VALUES ('dancer_session_cookie_key', md5(random()::text))"
fi

echo >&2 -e "${COL}netdisco-db-entrypoint: queueing stats job${NC}"
"${psql[@]}" -c "INSERT INTO admin (action, status) VALUES ('stats', 'queued')"
