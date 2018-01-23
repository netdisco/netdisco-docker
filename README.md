[![Build Status](https://travis-ci.org/netdisco/netdisco.svg?branch=master)](https://travis-ci.org/netdisco/netdisco)
[![CPAN version](https://badge.fury.io/pl/App-Netdisco.svg)](https://metacpan.org/pod/App::Netdisco)

[![Docker netdisco-backend Image](https://img.shields.io/microbadger/image-size/netdisco/netdisco/latest-backend.svg?label=netdisco-backend)](https://store.docker.com/community/images/netdisco/netdisco)
[![Docker netdisco-web Image](https://img.shields.io/microbadger/image-size/netdisco/netdisco/latest-web.svg?label=netdisco-web)](https://store.docker.com/community/images/netdisco/netdisco)
[![Docker PostgreSQL Image](https://img.shields.io/microbadger/image-size/netdisco/netdisco/latest-postgresql.svg?label=PostgreSQL&logo=postgresql)](https://store.docker.com/community/images/netdisco/netdisco)
[![Docker netdisco-do Image](https://img.shields.io/microbadger/image-size/netdisco/netdisco/latest-do.svg?label=netdisco-do)](https://store.docker.com/community/images/netdisco/netdisco)

**Netdisco** is a web-based network management tool suitable for small to very large networks. IP and MAC address data is collected into a PostgreSQL database using SNMP, CLI, or device APIs. Some of the things you can do with Netdisco:

* Locate a machine on the network by MAC or IP and show the switch port it lives at
* Turn off a switch port, or change the VLAN or PoE status of a port
* Inventory your network hardware by model, vendor, software and operating system
* Pretty pictures of your network

See the demo at: [https://netdisco2-demo.herokuapp.com/](https://netdisco2-demo.herokuapp.com/)

Netdisco includes a lightweight web server for the interface, a backend daemon to gather data from your network, and a command line interface for troubleshooting. There is a simple configuration file in YAML format. 

##  Docker Deployment

[Download the `docker-compose.yml`](https://raw.githubusercontent.com/netdisco/netdisco-docker/master/docker-compose.yml) file and run:

    docker-compose up

This will start the database, backend daemon, and web frontend listening on port 5000. If you have a device using the SNMP community `public`, enter it in the Netdisco homepage and click "Discover".

The default configuration is available in `netdisco/config/deployment.yml`. The backend and web daemons will automatically restart when you save cahnges to this file. Logs are available in `netdisco/logs/netdisco-{backend,web}.log`.

You can also [download `dc-netdisco-do.yml`](https://raw.githubusercontent.com/netdisco/netdisco-docker/master/dc-netdisco-do.yml) for command-line management of Netdisco:

    docker-compose -f dc-netdisco-do.yml netdisco-do <action>
    # run it without <action> to get help

Local web or backend plugins can be installed into `netdisco/nd-site-local/` as per our documentation. Finally, the PostgreSQL data files are stored in `netdisco/pgdata/` and we do not advise touching them (unless you wish to reinitialize the system).

The web frontend is configured to allow unauthenticated access with full admin rights. We suggest you visit the `Admin -> User Management` menu item, and edit `no_auth` in `deployment.yml`, to remove this guest account and set up authenticated user access.

Other username, password, database connection, and file locations, can all be set using [environment variables](https://github.com/netdisco/netdisco/wiki/Environment-Variables) described in our wiki. Of course the database container is optional and you can connect to an existing or external PostgreSQL server instead.

## Getting Support

We have several other pages with tips for [alternate deployment scenarios](https://github.com/netdisco/netdisco/wiki/Install-Tips), [understanding and troubleshooting Netdisco](https://github.com/netdisco/netdisco/wiki/Troubleshooting), [tips and tricks for specific platforms](https://github.com/netdisco/netdisco/wiki/Vendor-Tips), and [all the configuration options](https://github.com/netdisco/netdisco/wiki/Configuration).

You can also speak to someone in the [`#netdisco@freenode`](https://webchat.freenode.net/?randomnick=1&prompt=1&channels=%23netdisco) IRC channel, or on the [community email list](https://lists.sourceforge.net/lists/listinfo/netdisco-users).

