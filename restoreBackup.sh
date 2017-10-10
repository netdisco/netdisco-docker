#!/bin/bash
## simple script to restore a backup
## No args will restore the latest backup
## pass an integer arg, n, to choose the nth most-recent backup

choice=$1

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

count=0
for file in `find $backup_dir -name *netdisco-pgsql-*.gz -printf "%T+\t%p\n" | sort -r | awk '{ print $2 }'`
do
    count=$(( $count + 1 ))
    if [ $(( $choice + 0 )) -eq $count  ]
    then
        restore_file=$file
        echo "-->$count) $file"
    else
        echo "$count) $file"
    fi
done

if [ -e "$restore_file" ]
then
    echo "running backup before a restore and sleeping 30 seconds to allow time to cancel"
    /backup.sh beforeRestore
    
    sleep 30
    temp_restore_file=`mktemp`
    gzip -d $restore_file -c > $temp_restore_file
    /usr/bin/pg_restore --host=${NETDISCO_DB_HOST} --port=${NETDISCO_DB_PORT} --user=${NETDISCO_DB_USER} -c -n public -d netdisco -1 $temp_restore_file
else
    echo "Run this script again with a number from above as an argument. ex: '/restoreBackup.sh 1'"
fi
