#!/usr/bin/env bash

NETDISCO_DB_NAME="${NETDISCO_DB_NAME:-netdisco}"
NETDISCO_DB_USER="${NETDISCO_DB_USER:-netdisco}"
NETDISCO_DB_PASS="${NETDISCO_DB_PASS:-netdisco}"

PGUSER="${PGUSER:-postgres}"
psql=( psql -X -v ON_ERROR_STOP=0 -v ON_ERROR_ROLLBACK=on )
psql+=( --username=${PGUSER} )

echo >&2 "netdisco-db-entrypoint: configuring Netdisco user and db"
"${psql[@]}" -c "CREATE ROLE ${NETDISCO_DB_USER} WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD '${NETDISCO_DB_PASS}'"
createdb --username=${PGUSER} -O ${NETDISCO_DB_USER} ${NETDISCO_DB_NAME}

/usr/local/bin/netdisco-updatedb.sh
