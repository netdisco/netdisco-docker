[![CPAN version](https://badge.fury.io/pl/App-Netdisco.svg)](https://metacpan.org/pod/App::Netdisco)
[![Release date](https://img.shields.io/github/release-date/netdisco/netdisco-docker.svg?label=released)](https://metacpan.org/pod/App::Netdisco)
[![Build Status](https://travis-ci.org/netdisco/netdisco.svg?branch=master)](https://travis-ci.org/netdisco/netdisco)
[![Docker Image](https://img.shields.io/badge/docker%20images-ready-blue.svg)](https://store.docker.com/community/images/netdisco/netdisco)

**Netdisco** is a web-based network management tool suitable for small to very large networks. IP and MAC address data is collected into a PostgreSQL database using SNMP, CLI, or device APIs. Some of the things you can do with Netdisco:

* Locate a machine on the network by MAC or IP and show the switch port it lives at
* Turn off a switch port, or change the VLAN or PoE status of a port
* Inventory your network hardware by model, vendor, software and operating system
* Pretty pictures of your network

See the demo at: [https://netdisco2-demo.herokuapp.com/](https://netdisco2-demo.herokuapp.com/)

Netdisco includes a lightweight web server for the interface, a backend daemon to gather data from your network, and a command line interface for troubleshooting. There is a simple configuration file in YAML format. 

##  Docker Deployment

Only if you are on Linux:

    # become root user
    groupadd netdisco -g 901
    useradd -u 901 -p x -g netdisco netdisco
    sudo mkdir -p ~netdisco/{logs,bin,environments,config,nd-site-local}
    sudo chown -R netdisco:netdisco ~netdisco

And then (for everyone):

    # become the user running docker
    cd ~netdisco
    curl -Ls -o docker-compose.yml https://tinyurl.com/nd2-dockercompose
    docker-compose up

This will start the database, backend daemon, and web frontend listening on port 5000. If you have a device using the SNMP community `public`, enter it in the Netdisco homepage and click "Discover".

The default configuration is available in `netdisco/config/deployment.yml`. The backend and web daemons will automatically restart when you save changes to this file. Logs are available in `netdisco/logs/`.

The [netdisco-do](https://metacpan.org/dist/App-Netdisco/view/bin/netdisco-do) utility can be run like this (run it without `<action>` to get help):

    docker-compose run netdisco-do <action>

Local web or backend plugins can be installed into `netdisco/nd-site-local/` as per [our documentation](https://github.com/netdisco/netdisco/wiki). Finally, the PostgreSQL data files are stored in `netdisco/pgdata/` and we do not advise touching them (unless you wish to reinitialize the system).

The web frontend is configured to allow unauthenticated access with full admin rights. We suggest you visit the `Admin -> User Management` menu item, and edit `no_auth` in `deployment.yml`, to remove this guest account and set up authenticated user access.

Other username, password, database connection, and file locations, can all be set using [environment variables](https://github.com/netdisco/netdisco/wiki/Environment-Variables) described in our wiki. Of course the database container is optional and you can connect to an existing or external PostgreSQL server instead.

## Getting Support

We have several other pages with tips for [understanding and troubleshooting Netdisco](https://github.com/netdisco/netdisco/wiki/Troubleshooting), [tips and tricks for specific platforms](https://github.com/netdisco/netdisco/wiki/Vendor-Tips), and [all the configuration options](https://github.com/netdisco/netdisco/wiki/Configuration).

You can also speak to someone in the [`#netdisco@libera`](https://kiwiirc.com/nextclient/irc.libera.chat/netdisco) IRC channel, or on the [community email list](https://lists.sourceforge.net/lists/listinfo/netdisco-users).

## Upgrading

Downloading new images is good enough. When our database image starts it always updates the DB schema to the latest release. To upgrade your own PostgreSQL database, run:

    docker-compose run --entrypoint=bin/netdisco-db-deploy netdisco-backend

## Credits

Thanks to Ira W. Snyder and LBegnaud for inspiration. Thanks also to the PostgreSQL project for great examples of docker magic. We build with the support of the excellent GitHub Actions service. 
