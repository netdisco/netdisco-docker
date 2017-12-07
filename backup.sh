#!/bin/bash
## simple script to backup the db on an interval
## pulled from: https://metacpan.org/pod/distribution/App-Netdisco/lib/App/Netdisco/Manual/Deployment.pod#Database-Backups
## modified to pull host and creds from deployment.yml
## An optional arg is accepted to set the prefix of the backup files. The default is "manual"

prefix=$1

if [ "$prefix" == "" ]
then
    prefix="manual"
fi

backup_dir="${NETDISCO_HOME}/backups"

source /parse_yaml.sh
ENV_FILE="${NETDISCO_HOME}/environments/deployment.yml"

for i in `parse_yaml $ENV_FILE CONF_ | grep ^CONF_database` ; do export $i ; done
NETDISCO_DB_USER=`eval echo $CONF_database_user`
NETDISCO_DB_PASS=`eval echo $CONF_database_pass`
NETDISCO_DB_HOST=`eval echo $CONF_database_host | cut -d\; -f1`
# pull port from host config, set blank if no port specified
NETDISCO_DB_PORT=`eval echo $CONF_database_host | cut -d\; -f2 | sed "s/$NETDISCO_DB_HOST//" | cut -d\= -f2`
# coalesce DB port
NETDISCO_DB_PORT=${NETDISCO_DB_PORT:="5432"}


if [ ! -e "~/.pgpass" ]; then

    cat << EOF > ~/.pgpass 
${NETDISCO_DB_HOST}:${NETDISCO_DB_PORT}:netdisco:${NETDISCO_DB_USER}:${NETDISCO_DB_PASS}
EOF
    chmod 600 ~/.pgpass 
fi

mkdir -p $backup_dir


DATE=`date +%Y%m%d_%H%M%S`
backup_file=$backup_dir/$prefix-netdisco-pgsql-$DATE.dump
/usr/bin/pg_dump -F c --create -f $backup_file --host=${NETDISCO_DB_HOST} --port=${NETDISCO_DB_PORT} --user=${NETDISCO_DB_USER} netdisco
gzip -9f $backup_file
/usr/bin/find $backup_dir -type f -ctime +30 -exec rm {} \;
