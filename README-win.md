# netdisco-docker on windows10

## requirements

* windows 10 x64, version 1903, pro, enterprise or education edition.
  * nested virtualization needs to be enabled in the bios
  * the following features need to be enabled in windows:
    * containers
    * hyper-v
    * virtual machine platform
    * windows hypervisor platform 
* docker desktop for windows 2.0.5.0 (edge), community edition
  * docker must be set to use linux containers
  * in the edge edition it's not possible to turn of metrics
  * disable outstart of the docker / container services.
    * local volumes take some time to come online. if containers start before the volumes are online this can result in data loss.
    * not autostarting the netdisco containers is another option.
  * enabling "experimental features" might be required.

## limitations / work in progress

* unlike linux we use local volumes on windows, this takes care of differences in userid/acl handling.
* ipv6 support not tested
* openssh support not tested (ssh does not seem to be installed in the container image)
* very basic docker support, stuff like docker swarm etc will most likely not work
* upgrade procedure still needs to be figured out
* timezones don't match between windows host & containers, so scheduling/logging/etc is not exact.
* not yet tested with extended runtimes
* what happens when multiple containers try to use the same docker volumes?

## installing netdisco-docker on windows

unlike linux we use local volumes on windows, this takes care of differences in
userid/acl handling.

* first create local volumes for netdisco's storage
```shell script
    docker volume create -d local nd-pgdata-volume
    docker volume create -d local nd-sitelocal-volume
    docker volume create -d local nd-config-volume
    docker volume create -d local nd-logs-volume
```
* fetch the windows specific compose file:
```shell script
    curl -Ls -o docker-compose.yml https://raw.githubusercontent.com/netdisco/netdisco-docker/master/docker-compose-win.yml
    docker-compose up
```

## starting/stopping containers after the initial install can be done with:

* find out container id.
```shell script
    docker ps --all
```
* starting/stopping containers
```shell script
    docker stop __containerid__
    docker start __containerid__
```

## netdisco-do support

* fetch the windows specific compose file:
```shell script
    curl -Ls -o dc-netdisco-do.yml https://raw.githubusercontent.com/netdisco/netdisco-docker/master/dc-netdisco-do-win.yml
    docker-compose -f dc-netdisco-do.yml run netdisco-do <action>
```
* run it without < action > to get help

## connecting to a shell on netdisco-backend.

this can be used to edit configuration files or run "netdisco-do", but has not been fully tested yet. 

* find out the container id of netdisco-backend
```shell script
    docker ps
```
* connect to shell, replace __containerid__  with the actual id
```shell script
    docker exec -it __containerid__ /bin/ash
```
* exit shell
```shell script
    exit
```

## upgrading to newer netdisco versions. this has not yet been tested, but i assume it will go something like:

* stop containers
* pull newest images
  * docker pull netdisco/netdisco:latest-postgresql
  * docker pull netdisco/netdisco:latest-backend
  * docker pull netdisco/netdisco:latest-web
  * figure out how to link volumes to new images if not done automically
* start new containers
  * must make sure our container startup doesn't execute scripts that could overwrite existing data
* follow normal update procedure next (netdisco-deploy)?
* the provided docker-compose example for initial installation does not seem to update images to newer versions.
