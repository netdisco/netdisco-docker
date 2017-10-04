#!/bin/bash
# File modified from originals at https://github.com/sheeprine/docker-netdisco and https://github.com/kkniffin/docker-netdisco 


ENV_FILE="$NETDISCO_HOME/environments/deployment.yml"

## function from https://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

provision_netdisco_db() {
    psql $PSQL_OPTIONS -c "CREATE ROLE netdisco WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE password '$NETDISCO_DB_PASS'"
    psql $PSQL_OPTIONS -c "CREATE DATABASE netdisco OWNER netdisco"
}

check_postgres() {
    if [ -z `psql $PSQL_OPTIONS -tAc "SELECT 1 FROM pg_roles WHERE rolname='netdisco'"` ]; then
        provision_netdisco_db
    fi
}

set_environment() {

    mkdir `dirname $ENV_FILE`
    cp $NETDISCO_HOME/perl5/lib/perl5/auto/share/dist/App-Netdisco/environments/deployment.yml $ENV_FILE
    chmod 600 $ENV_FILE
    
    NETDISCO_DB_USER=netdisco
    # generate random password
    NETDISCO_DB_PASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32`
    NETDISCO_DB_HOST=${NETDISCO_DB_HOST:='postgres'}
    NETDISCO_DB_PORT=${NETDISCO_DB_PORT:='5432'}
    NETDISCO_DOMAIN=${NETDISCO_DOMAIN:="'`hostname -d`"}
    NETDISCO_RO_COMMUNITY=${NETDISCO_RO_COMMUNITY:='public'}
    NETDISCO_RO_COMMUNITY=${NETDISCO_WR_COMMUNITY:='private'}

    sed -i "s/user: 'changeme'/user: '$NETDISCO_DB_USER'/" $ENV_FILE
    sed -i "s/pass: 'changeme'/pass: '$NETDISCO_DB_PASS'/" $ENV_FILE
    sed -i "s/#*host: 'localhost'/host: '$NETDISCO_DB_HOST;port=$NETDISCO_DB_PORT'/" $ENV_FILE
    sed -i "s/#*domain_suffix: '.example.com'/domain_suffix: '$NETDISCO_DOMAIN'/" $ENV_FILE

    sed -i "s/community: 'public'/community: '$NETDISCO_RO_COMMUNITY'/" $ENV_FILE

    if [ -n $NETDISCO_WR_COMMUNITY ]; then
        sed -i "/snmp_auth:/a\  - tag: 'default_v2_for_write'" $ENV_FILE
        sed -i "/^  - tag: 'default_v2_for_write/a\    write: true" $ENV_FILE
        sed -i "/^  - tag: 'default_v2_for_write/a\    read: false" $ENV_FILE
        sed -i "/^  - tag: 'default_v2_for_write/a\    community: '$NETDISCO_WR_COMMUNITY'" $ENV_FILE
    fi

    sed -i "/#schedule:/, /when: '20 23 \* \* \*'/ s/#//" $ENV_FILE

}

check_environment() {
    # check if Environment File Exists, if not create with sane defaults
    if [ ! -e "$ENV_FILE" ]; then
        set_environment
    fi
}


check_environment


for i in `parse_yaml $ENV_FILE CONF_ | grep ^CONF_database` ; do export $i ; done
NETDISCO_DB_USER=`eval echo $CONF_database_user`
NETDISCO_DB_PASS=`eval echo $CONF_database_pass`
NETDISCO_DB_HOST=`eval echo $CONF_database_host | cut -d\; -f1`
# pull port from host config, set blank if no port specified
NETDISCO_DB_PORT=`eval echo $CONF_database_host | cut -d\; -f2 | sed "s/$NETDISCO_DB_HOST//" | cut -d\= -f2`
# coalesce DB port
NETDISCO_DB_PORT=${NETDISCO_DB_PORT:="5432"}

# options to initialize DB
DB_POSTGRES_USER=postgres
PSQL_OPTIONS="-h "$NETDISCO_DB_HOST" -p "$NETDISCO_DB_PORT" -U $DB_POSTGRES_USER"

check_postgres

# Provide Answers to Configuration Questions of Netdisco
sed -i "s/new('netdisco')/new('netdisco', \\*STDIN, \\*STDOUT)/" $NETDISCO_HOME/perl5/bin/netdisco-deploy
$NETDISCO_HOME/perl5/bin/netdisco-deploy /tmp/oui.txt << ANSWERS
y
y
y
y
ANSWERS

netdisco-web start
netdisco-daemon start
tail -f $NETDISCO_HOME/logs/netdisco-*.log &

while true
do
    sleep 5
    ## clean up file to split by spaces
    sed -i 's/ /\n/g; /^$/d;' ${NETDISCO_HOME}/pending_devices.txt
    ## loop over lines that are IP addresses
    for device in `cat ${NETDISCO_HOME}/pending_devices.txt | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
    do
        echo "Processing device from pending_devices.txt: $device"
        netdisco-do discover -d $device && sed "/^${device}$/d" || echo "--Failed to discover this device"
    done
done
