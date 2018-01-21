#!/usr/bin/env bash

su=( su-exec "${PGUSER:-postgres}" )

if [ ! -s "${PGDATA}/PG_VERSION" ]; then
  exec env POSTGRES_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1) \
    /usr/local/bin/docker-entrypoint.sh "$@"
fi

if [ "$1" = 'postgres' ]; then
  echo >&2 "netdisco-db-entrypoint: starting pg privately to container"
  "${su[@]}" pg_ctl -D "$PGDATA" -o "-c listen_addresses='localhost'" -w start

  /usr/local/bin/netdisco-updatedb.sh

  echo >&2 "netdisco-db-entrypoint: shutting down pg (will restart, listening for clients)"
  "${su[@]}" pg_ctl -D "$PGDATA" -m fast -w stop
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
