#!/usr/bin/env bash

NETDISCO_DB_NAME="${NETDISCO_DB_NAME:-netdisco}"
NETDISCO_DB_USER="${NETDISCO_DB_USER:-netdisco}"
NETDISCO_DB_PASS="${NETDISCO_DB_PASS:-netdisco}"
NETDISCO_ADMIN_USER="${NETDISCO_ADMIN_USER:-guest}"

psql=( psql -X -v ON_ERROR_STOP=0 -v ON_ERROR_ROLLBACK=on )
psql+=( --username ${NETDISCO_DB_USER} --dbname ${NETDISCO_DB_NAME} )

echo >&2 "netdisco-db-entrypoint: configuring Netdisco db user"
echo "*:*:${NETDISCO_DB_NAME}:${NETDISCO_DB_USER}:${NETDISCO_DB_PASS}" > ~/.pgpass
chmod 0600 ~/.pgpass
createuser -DRSw ${NETDISCO_DB_USER}
createdb -O ${NETDISCO_DB_USER} ${NETDISCO_DB_NAME}
rm ~/.pgpass

/usr/local/bin/netdisco-updatedb.sh
