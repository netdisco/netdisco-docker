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

if [ -z $("${psql[@]}" -Atc "SELECT to_regclass('device')") ] \
  || [ -z $("${psql[@]}" -Atc "SELECT ip FROM device LIMIT 1") ]; then
  TEST_TO=$(($NETDISCO_CURRENT_PG_VERSION - 1))

  if [ 13 -le $TEST_TO ]; then
    echo >&2 -e "${COL}netdisco-updatedb: finding upgrade candidate${NC}"

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
	        DATE=$(date '+%Y-%m-%d-%H:%M:%S')

          echo >&2 -e "${COL}netdisco-updatedb: making backup of db v${VER}${NC}"
          PGHOST= PGPORT= "pg_dump" --port=50432 --host=netdisco-postgresql-${VER} \
            -F c -x -f ${ROOT}/netdisco-db-$DATE.dump ${PGDATABASE}

          echo >&2 -e "${COL}netdisco-updatedb: making backup of db v${NETDISCO_CURRENT_PG_VERSION}${NC}"
          pg_dump -F c -x -f /var/lib/pgversions/new/${NETDISCO_CURRENT_PG_VERSION}/docker/netdisco-db-$DATE.dump ${PGDATABASE}

          echo >&2 -e "${COL}netdisco-updatedb: reinitialising and copying data${NC}"
          "${psql[@]}" -c "DROP OWNED BY ${PGUSER};"
	        pg_restore -c -d ${PGDATABASE} -x -1 -O --if-exists ${ROOT}/netdisco-db-$DATE.dump

          echo >&2 -e "${COL}netdisco-updatedb: signalling old pg version ${VER} to shutdown${NC}"
          touch "${ROOT}/NETDISCO_UPGRADED"
          break
        fi
      fi
    done
  fi
fi

echo >&2 -e "${COL}netdisco-updatedb: bringing schema up-to-date${NC}"
export NETDISCO_DB_DEPLOY_CONTAINER=1

# split on whitespace on purpose: the setting holds options such as "--force-step 57"
# which must reach netdisco-db-deploy as separate arguments
read -r -a DEPLOY_WORDS <<< "${NETDISCO_DB_DEPLOY_ARGS:-}"

DEPLOY_ARGS=()
RUN_CHECK=0
for WORD in ${DEPLOY_WORDS[@]+"${DEPLOY_WORDS[@]}"}; do
  if [ "${WORD}" = "--check" ]; then
    RUN_CHECK=1
  else
    DEPLOY_ARGS+=("${WORD}")
  fi
done

# a non-zero exit stops this script (set -e) and so the whole stack start
/home/netdisco/bin/netdisco-db-deploy ${DEPLOY_ARGS[@]+"${DEPLOY_ARGS[@]}"}

# after the upgrade, because the check refuses a database at another version
if [ "${RUN_CHECK}" -eq 1 ]; then
  /home/netdisco/bin/netdisco-db-deploy --check || true
fi
echo >&2 -e "${COL}netdisco-updatedb: schema is up-to-date${NC}"

echo >&2 -e "${COL}netdisco-updatedb: importing OUI${NC}"
"${psql[@]}" -f /var/lib/postgresql/netdisco-sql/netdisco-lookup-tables.sql

echo >&2 -e "${COL}netdisco-updatedb: adding admin user if required and none exists${NC}"
if [ "${DEPLOY_ADMIN_USER}" != "NO" ] && [ -z "$("${psql[@]}" -Atc "SELECT 1 FROM users WHERE admin LIMIT 1")" ]; then
  "${psql[@]}" -c "INSERT INTO users (username, port_control, admin) VALUES ('${NETDISCO_ADMIN_USER}', true, true)"
fi

echo >&2 -e "${COL}netdisco-updatedb: adding session key if none exists${NC}"
if [ -z $("${psql[@]}" -Atc "SELECT 1 FROM sessions WHERE id = 'dancer_session_cookie_key'") ]; then
  "${psql[@]}" -c "INSERT INTO sessions (id, a_session) VALUES ('dancer_session_cookie_key', md5(random()::text))"
fi

echo >&2 -e "${COL}netdisco-updatedb: queueing stats job${NC}"
"${psql[@]}" -c "INSERT INTO admin (action, status) VALUES ('stats', 'queued')"
