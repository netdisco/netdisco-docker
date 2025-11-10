#!/usr/bin/env bash
set -euo pipefail

# User needs to either set these in docker-compose environment
# or else run wrapped in netdisco-env

: "${PGDATABASE:=${NETDISCO_DB_NAME:=netdisco}}"
: "${PGHOST:=${NETDISCO_DB_HOST:=netdisco-postgresql}}"
: "${PGPORT:=${NETDISCO_DB_PORT:=5432}}"
: "${PGUSER:=${NETDISCO_DB_USER:=netdisco}}"
: "${PGPASSWORD:=${NETDISCO_DB_PASS:=netdisco}}"

# the no_auth=true initial login user
: "${NETDISCO_ADMIN_USER:=guest}"

export COL='\033[0;35m'
export NC='\033[0m'

psql=( psql -X -v ON_ERROR_STOP=0 -v ON_ERROR_ROLLBACK=on )

# echo >&2 -e "${COL}netdisco-updatedb: making backup${NC}"
# DATE=`date +%Y%m%d`
# PGHOST= PGPORT= "pg_dump" --port=5432 --host=netdisco-postgresql -a -x ${PGDATABASE}
# /usr/bin/pg_dump -F c --create -f /path/to/backups/netdisco-pgsql-$DATE.dump netdisco

echo >&2 -e "${COL}netdisco-updatedb: checking if schema is up-to-date${NC}"
MAXSCHEMA=$(grep VERSION /home/netdisco/perl5/lib/perl5/App/Netdisco/DB.pm | sed 's/[^0-9]//g')

if [ -z $("${psql[@]}" -A -t -c "SELECT 1 FROM dbix_class_schema_versions WHERE version = '${MAXSCHEMA}'") ]; then
  echo >&2 -e "${COL}netdisco-updatedb: bringing schema up-to-date${NC}"

  ls -1 /home/netdisco/perl5/lib/perl5/auto/share/dist/App-Netdisco/schema_versions/App-Netdisco-DB-* | \
    xargs -n1 basename | sort -n -t '-' -k4 | \
    while read file; do
      "${psql[@]}" -f "/home/netdisco/perl5/lib/perl5/auto/share/dist/App-Netdisco/schema_versions/$file"
    done

  echo >&2 -e "${COL}netdisco-updatedb: marking schema as up-to-date${NC}"
  STAMP=$(date '+v%Y%m%d_%H%M%S.000')
  "${psql[@]}" -c "CREATE TABLE dbix_class_schema_versions (version varchar(10) PRIMARY KEY, installed varchar(20) NOT NULL)"
  "${psql[@]}" -c "INSERT INTO dbix_class_schema_versions VALUES ('${MAXSCHEMA}', '${STAMP}')"

  if [ -z $("${psql[@]}" -A -t -c "SELECT count(*) FROM sessions") ]; then
    echo >&2 -e "${COL}netdisco-updatedb: (empty v${NETDISCO_CURRENT_PG_VERSION}) finding upgrade candidate${NC}"
    TEST_TO=$(($NETDISCO_CURRENT_PG_VERSION - 1))

    if [ 13 -le $TEST_TO ]; then
      for ((VER=$TEST_TO;VER>=13;VER--)); do
        if [ $VER -eq 13 ]; then
          ROOT="/var/lib/pgversions/pg13"
        else
          ROOT="/var/lib/pgversions/new/${VER}/docker"
        fi
        echo >&2 -e "${COL}netdisco-updatedb: checking pg ${VER} datadir${NC}"

        if [ -f "${ROOT}/NETDISCO_UPGRADED" ]; then
          echo >&2 -e "${COL}netdisco-updatedb: pg ${VER} already migrated${NC}"
          break

        else
          if [ -f "${ROOT}/PG_VERSION" ]; then
            echo >&2 -e "${COL}netdisco-updatedb: found candidate pg version ${VER} to upgrade${NC}"

            echo >&2 -e "${COL}netdisco-updatedb: bringing old pg version up to date${NC}"
            ls -1 /home/netdisco/perl5/lib/perl5/auto/share/dist/App-Netdisco/schema_versions/App-Netdisco-DB-* | \
              xargs -n1 basename | sort -n -t '-' -k4 | \
              while read file; do
                PGHOST= PGPORT= "${psql[@]}" --port=50432 --host=netdisco-postgresql-${VER} \
                  -f "/home/netdisco/perl5/lib/perl5/auto/share/dist/App-Netdisco/schema_versions/$file"
              done

            echo >&2 -e "${COL}netdisco-updatedb: copying data${NC}"
            NEWDBHOST=$PGHOST
            PGHOST= PGPORT= "pg_dump" --port=50432 --host=netdisco-postgresql-${VER} -a -x ${PGDATABASE} \
              | "${psql[@]}" --port=5432 --host=${NEWDBHOST}

            echo >&2 -e "${COL}netdisco-updatedb: signalling old pg version ${VER} to shutdown${NC}"
            touch "${ROOT}/NETDISCO_UPGRADED"
            break
          fi
        fi
      done
    fi
  fi
fi

echo >&2 -e "${COL}netdisco-updatedb: importing OUI${NC}"
"${psql[@]}" -f /var/lib/postgresql/netdisco-sql/netdisco-lookup-tables.sql

echo >&2 -e "${COL}netdisco-updatedb: adding admin user if required and none exists${NC}"
if [ "${DEPLOY_ADMIN_USER}" != "NO" ] && [ -z $("${psql[@]}" -A -t -c "SELECT 1 FROM users WHERE admin") ]; then
  "${psql[@]}" -c "INSERT INTO users (username, port_control, admin) VALUES ('${NETDISCO_ADMIN_USER}', true, true)"
fi

echo >&2 -e "${COL}netdisco-updatedb: adding session key if none exists${NC}"
if [ -z $("${psql[@]}" -A -t -c "SELECT 1 FROM sessions WHERE id = 'dancer_session_cookie_key'") ]; then
  "${psql[@]}" -c "INSERT INTO sessions (id, a_session) VALUES ('dancer_session_cookie_key', md5(random()::text))"
fi

echo >&2 -e "${COL}netdisco-updatedb: queueing stats job${NC}"
"${psql[@]}" -c "INSERT INTO admin (action, status) VALUES ('stats', 'queued')"
