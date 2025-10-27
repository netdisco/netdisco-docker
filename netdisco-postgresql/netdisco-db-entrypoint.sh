#!/usr/bin/env bash
set -efuo pipefail

export COL='\033[0;35m'
export NC='\033[0m'

# Explicit assign; we don't want to pick up PGUSER from environment
# because that many be the same as NETDISCO_DB_USER.
PGUSER="${NETDISCO_DB_SUPERUSER:=postgres}"
su=( su-exec "${PGUSER}" )

# fast quit if we've been upgraded already
if [ -f "${PGDATA}/NETDISCO_UPGRADED" ]; then exit 0; fi

# pass through if we're the current latest version
if [ "$PG_MAJOR" = "$NETDISCO_CURRENT_PG_VERSION" ]; then
  echo >&2 -e "${COL}netdisco-db-entrypoint: starting latest pg version ${PG_MAJOR}${NC}"
  if [ ! -s "${PGDATA}/PG_VERSION" ]; then
      echo >&2 -e "${COL}netdisco-db-entrypoint: generating random POSTGRES_PASSWORD${NC}"
      export POSTGRES_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  fi
  echo >&2 -e "${COL}netdisco-db-entrypoint: passing control to postgresql docker-entrypoint${NC}"
  exec /usr/local/bin/docker-entrypoint.sh "$@"
fi

# fast quit if we were never used and have no data
if [ ! -s "${PGDATA}/PG_VERSION" ]; then exit 0; fi

# so we have a database, but we are not the current.
# if there's any newer data, silently quit

TEST_FROM=$(($PG_MAJOR + 1))
TEST_TO=$(($NETDISCO_CURRENT_PG_VERSION - 1))

if [ $TEST_FROM -le $TEST_TO ]; then
  for ((VER=$TEST_FROM;VER<=TEST_TO;VER++)); do
    if [ -s "/var/lib/postgresql/$VER/docker/PG_VERSION" ]; then
      exit 0
    fi
  done
fi

# otherwise run on special port for data migration, wait until data deployed, then quit
echo >&2 -e "${COL}netdisco-db-entrypoint: ready for upgrade; starting on port 50432${NC}"

NOTIFY_SOCKET= "${su[@]}" \
  pg_ctl -D "$PGDATA" \
  -o "-c listen_addresses='*' -p 50432 -c log_min_error_statement=LOG -c log_min_messages=LOG" \
  -w start

while [ ! -f "${PGDATA}/NETDISCO_UPGRADED" ]; do
   sleep 2
done
echo >&2 -e "${COL}netdisco-db-entrypoint: data migration complete; stopping${NC}"

sleep 2
"${su[@]}" pg_ctl -D "$PGDATA" -m fast -w stop

exit 0