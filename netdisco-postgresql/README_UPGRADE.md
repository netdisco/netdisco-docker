
Beginning from version 2.09000 netdisco-docker includes Postgres 17, 
while the existing database is an older major version.

It's possible to upgrade the old database in-place using pgautoupgrade, 
executed in the directory where docker-compose.yml is located:

```
docker run --name pgauto -it \
  --mount type=bind,source=$PWD/netdisco/pgdata,target=/var/lib/postgresql/data \
  -e PGAUTO_ONESHOT=yes \
  pgautoupgrade/pgautoupgrade:17-alpine
```

Before doing so, please make sure to have a working backup. A simple way
to create one is:

```
docker-compose exec -u postgres netdisco-postgresql \
    pg_dump -c -d netdisco -C --format=p > $HOME/netdisco-backup.sql

```

For the above command to work, or to avoid upgrading right now, edit
docker-compose.yml to use the last version of the images that used
Postgres 13:

```
    image: netdisco/netdisco:2.080003-postgresql
    image: netdisco/netdisco:2.080003-backend
    image: netdisco/netdisco:2.080003-web
    image: netdisco/netdisco:2.080003-do
```

We apologize for the inconvenience.

