#!/bin/sh
## simple script to backup the db on an interval
## pulled from: https://metacpan.org/pod/distribution/App-Netdisco/lib/App/Netdisco/Manual/Deployment.pod#Database-Backups


DATE=`date +%Y%m%d`
/usr/bin/pg_dump -F c --create -f /path/to/backups/netdisco-pgsql-$DATE.dump netdisco
gzip -9f /path/to/backups/netdisco-pgsql-$DATE.dump
/usr/bin/find /path/to/backups/ -type f -ctime +30 -exec rm {} \;