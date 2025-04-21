# Postgres upgrade required

Beginning from version 2.09000 netdisco-docker includes Postgres 17, 
while the existing database is an older major version.

## Upgrade with pgautoupgrade

It's possible to upgrade the old database in-place using pgautoupgrade, 
executed in the directory where docker-compose.yml is located. Make 
sure all other netdisco containers are stopped.

Before doing so, please make sure to have a working backup. If you don't
have one already, see the chapter below.

Afterwards, run pgautoupgrade:

```
cd /path/to/docker-compose.yml
docker-compose down
docker run --rm -it \
  --mount type=bind,source=$PWD/netdisco/pgdata,target=/var/lib/postgresql/data \
  -e PGAUTO_ONESHOT=yes \
  pgautoupgrade/pgautoupgrade:17-alpine
```

Now you should be able to start the netdisco/netdisco:latest-... containers again.

## Backup or continue using an older version


To start Postgres 13 once more to create a backup, or to avoid upgrading right now, edit
`docker-compose.yml` to use the last version of the images that used
Postgres 13:

```
    image: netdisco/netdisco:2.084002-postgresql
    image: netdisco/netdisco:2.084002-backend
    image: netdisco/netdisco:2.084002-web
    image: netdisco/netdisco:2.084002-do
```

Then a backup can be produced with:

```
docker-compose down ; docker-compose up netdisco-postgresql -d  
docker-compose exec -u postgres netdisco-postgresql \
    pg_dump -c -d netdisco -C --format=p > $HOME/netdisco-backup.sql
```

Verify this file and proceed to the pgautoupgrade step.

When you are ready to use Postgres 17, set the version numbers in image:
to `latest` again.

```
    image: netdisco/netdisco:latest-postgresql
    etc...
```

## Support

We apologize for the inconvenience. While we can not offer full
Postgres DBA support or assume responsibility for data loss, we try to
help with reported issues on github or the IRC channel. 

 * https://github.com/netdisco/netdisco-docker/issues
 * https://kiwiirc.com/nextclient/irc.libera.chat/netdisco

