#!/usr/bin/env bash
set -efuo pipefail

# If running in docker-compose, user gets an initialised database
# using default username/etc as below.

: "${NETDISCO_DB_NAME:=netdisco}"
: "${NETDISCO_DB_USER:=netdisco}"
: "${NETDISCO_DB_PASS:=netdisco}"

# Explicit assign; we don't want to pick up PGUSER from environment
# because that many be the same as NETDISCO_DB_USER.
PGUSER="${NETDISCO_DB_SUPERUSER:=postgres}"
PGDATABASE=template1

export COL='\033[0;35m'
export NC='\033[0m'

psql=( psql -X -v ON_ERROR_STOP=0 -v ON_ERROR_ROLLBACK=on )

echo >&2 -e "${COL}netdisco-initdb: configuring Netdisco user and db${NC}"
"${psql[@]}" -c "CREATE ROLE ${NETDISCO_DB_USER} WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD '${NETDISCO_DB_PASS}'"
createdb --username=${PGUSER} -O ${NETDISCO_DB_USER} ${NETDISCO_DB_NAME}
