#!/bin/bash
## simple script to restore a backup
## pulled from: https://metacpan.org/pod/distribution/App-Netdisco/lib/App/Netdisco/Manual/Deployment.pod#Database-Backups



DATE=`date +%Y%m%d`
/usr/bin/pg_dump -F c --create -f ${NETDISCO_HOME}/backups/netdisco-pgsql-$DATE.dump netdisco
gzip -9f /path/to/backups/netdisco-pgsql-$DATE.dump
/usr/bin/find ${NETDISCO_HOME}/backups/ -type f -ctime +30 -exec rm {} \;