#!/usr/bin/env bash
set -efuxo pipefail

export COL='\033[0;35m'
export NC='\033[0m'

# Explicit assign; we don't want to pick up PGUSER from environment
# because that many be the same as NETDISCO_DB_USER.
PGUSER="${NETDISCO_DB_SUPERUSER:=postgres}"
PGDATABASE=template1

su=( su-exec "${PGUSER}" )
psql=( psql -X -v ON_ERROR_STOP=0 -v ON_ERROR_ROLLBACK=on )

# pass through if we're the current latest version
if [ "$PG_MAJOR" = "$NETDISCO_CURRENT_PG_VERSION" ]
then
  echo >&2 -e "${COL}netdisco-db-entrypoint: starting latest pg${NC}"
  if [ ! -s "${PGDATA}/PG_VERSION" ]
  then
      export POSTGRES_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  fi
  exec /usr/local/bin/docker-entrypoint.sh "$@"
fi

# quit if we were never used and have no data
if [ ! -s "${PGDATA}/PG_VERSION" ]; then exit 0; fi

# so we have a database, but we are not the current.
# if there's any newer data, silently quit

TEST_FROM=$(($PG_MAJOR + 1))
TEST_TO=$(($NETDISCO_CURRENT_PG_VERSION - 1))

if [$TEST_FROM -le $TEST_TO]
then
  for VER in $(seq $TEST_FROM $TEST_TO )
  do
    if [ -s "/var/lib/postgresql/$VER/docker/PG_VERSION" ]
    then
      exit 0
    fi
  done
fi

# otherwise run on special port for data migration, wait until data deployed, then quit

NOTIFY_SOCKET= "${su[@]}" \
  pg_ctl -D "$PGDATA" \
  -o "-c listen_addresses='*' -p 50432 -c log_min_error_statement=LOG -c log_min_messages=LOG" \
  -w start

while [ -z $("${psql[@]}" -h "${NETDISCO_DB_HOST}" -A -t -c "SELECT 1 FROM sessions WHERE id = 'dancer_session_cookie_key'") ]
do
   sleep 2
done

sleep 2
"${su[@]}" pg_ctl -D "$PGDATA" -m fast -w stop

exit 0