#!/bin/bash
# File modified from originals at https://github.com/sheeprine/docker-netdisco and https://github.com/kkniffin/docker-netdisco 

if [ ! -e "${NETDISCO_HOME}/perl5" ] 
then
    
    while true; do echo "netdisco is not installed. This is a test image, then" ; sleep 30; done

fi

ENV_FILE="$NETDISCO_HOME/environments/deployment.yml"
CRON_FILE="$NETDISCO_HOME/environments/crontabs"

## function from https://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script
source /parse_yaml.sh

cleanup() {
    echo "Exitting NetDisco..."
    netdisco-web stop
    netdisco-daemon stop
    sleep 5

    exit
}
trap cleanup INT TERM

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

    mkdir -p `dirname $ENV_FILE`
    cp $NETDISCO_HOME/perl5/lib/perl5/auto/share/dist/App-Netdisco/environments/deployment.yml $ENV_FILE
    chmod 600 $ENV_FILE
    
    NETDISCO_DB_USER=netdisco
    # generate random password
    NETDISCO_DB_PASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32`
    NETDISCO_DB_HOST=${NETDISCO_DB_HOST:='postgres'}
    NETDISCO_DB_PORT=${NETDISCO_DB_PORT:='5432'}
    NETDISCO_DOMAIN=${NETDISCO_DOMAIN:="`hostname -d`"}
    NETDISCO_RO_COMMUNITY=${NETDISCO_RO_COMMUNITY:='public'}
    NETDISCO_WR_COMMUNITY=${NETDISCO_WR_COMMUNITY:='private'}

    sed -i "s/user: 'changeme'/user: '$NETDISCO_DB_USER'/" $ENV_FILE
    sed -i "s/pass: 'changeme'/pass: '$NETDISCO_DB_PASS'/" $ENV_FILE
    sed -i "s/#*host: 'localhost'/host: '$NETDISCO_DB_HOST;port=$NETDISCO_DB_PORT'/" $ENV_FILE
    sed -i "s/#*domain_suffix: '.example.com'/domain_suffix: '$NETDISCO_DOMAIN'/" $ENV_FILE
    sed -i "s/community: 'public'/community: '$NETDISCO_RO_COMMUNITY'/" $ENV_FILE
    sed -i "s/#no_auth: false/no_auth: true/" $ENV_FILE

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

create_cron() {
    if [ ! -e "$CRON_FILE" ]; then
        ## create standard cron file
        mkdir -p `dirname ${CRON_FILE}`
cat << EOF > "$CRON_FILE"
# min   hour    day     month   weekday command

# backup every morning at 2am, with prefix of "cron"
0  2   *   *   *   /backup.sh cron >> $NETDISCO_HOME/logs/netdisco-backup.log 2>&1

# export to rancid every hour
#0  *   *   *   *   netdisco-rancid-export >> $NETDISCO_HOME/logs/netdisco-backend.log 2>&1

# put failed devices back into pending file daily
0  8   *   *   *   cat "${NETDISCO_HOME}/environments/failed_devices.txt" >> "${NETDISCO_HOME}/environments/pending_devices.txt" && rm "${NETDISCO_HOME}/environments/failed_devices.txt" -f
EOF
    fi

    crontab "$CRON_FILE"
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

create_cron

# Provide Answers to Configuration Questions of Netdisco
echo "running netdisco-deploy, the download can take a while"
#sed -i "s/new('netdisco'.*/new('netdisco', \\*STDIN, \\*STDOUT);/" $NETDISCO_HOME/perl5/bin/netdisco-deploy
#$NETDISCO_HOME/perl5/bin/netdisco-deploy << ANSWERS
sed -i "s/new('netdisco'.*/new('netdisco', \\*STDIN, \\*STDOUT);/" $NETDISCO_HOME/perl5/bin/netdisco-deploy

## pass oui.txt as arg and skip mibs if already present
## mibs should only be downloaded the first run of the image, but can be run again if the mibs dir is deleted
$NETDISCO_HOME/perl5/bin/netdisco-deploy ${NETDISCO_HOME}/oui.txt << ANSWERS
y
y
y
`if [ -e "${NETDISCO_HOME}/netdisco-mibs" ] ; then echo n ; else echo y ; fi`
ANSWERS

netdisco-web start
netdisco-daemon start
sleep 5

netdisco-backend status || cleanup

tail -f $NETDISCO_HOME/logs/netdisco-*.log &

PENDING_FILE="${NETDISCO_HOME}/environments/pending_devices.txt"
FAILED_FILE="${NETDISCO_HOME}/environments/failed_devices.txt"


## Loop serves to keep docker container running as well as provide a simple way to push devices into netdisco
## 
while true
do
    sleep 30
    ## clean up file to split by spaces
    if [ ! -e "$PENDING_FILE" ]; then
        touch "$PENDING_FILE"
    fi
    
    sed -i 's/ /\n/g; /^$/d;' "$PENDING_FILE"
    ## loop over lines that are IP addresses
    for device in `cat "$PENDING_FILE" | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
    do
        echo "Processing device from pending_devices.txt: $device"
        discover_output=`netdisco-do -D discover -d $device 2>&1`
        # preserve device for later if discovery was a failure
        echo "$discover_output" | grep -q status\ done || (echo "${device}" | sort | uniq >> "$FAILED_FILE")
        sed -i "/^${device}$/d" "$PENDING_FILE"
    done
done
