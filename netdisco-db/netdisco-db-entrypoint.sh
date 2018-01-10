#!/usr/bin/env bash
set -e

if [ "$1" = 'postgres' ] && [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo >&2 "netdisco-db-entrypoint: copying initial database files"
  cp -a /var/lib/postgresql/netdisco-data/* /var/lib/postgresql/data/
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
