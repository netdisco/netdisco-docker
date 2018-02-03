#!/usr/bin/env bash

export COL='\033[0;35m'
export NC='\033[0m'

su=( su-exec "${PGUSER:-postgres}" )

if [ ! -s "${PGDATA}/PG_VERSION" ]; then
  exec env POSTGRES_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1) \
    /usr/local/bin/docker-entrypoint.sh "$@"
fi

if [ "$1" = 'postgres' ]; then
  echo >&2 -e "${COL}netdisco-db-entrypoint: starting pg privately to container${NC}"
  "${su[@]}" pg_ctl -D "$PGDATA" -o "-c listen_addresses='localhost' -c log_min_error_statement=LOG -c log_min_messages=LOG" -w start

  /usr/local/bin/netdisco-updatedb.sh

  echo >&2 -e "${COL}netdisco-db-entrypoint: shutting down pg (will restart, listening for clients)${NC}"
  "${su[@]}" pg_ctl -D "$PGDATA" -m fast -w stop
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
