[![CPAN version](https://badge.fury.io/pl/App-Netdisco.svg)](https://metacpan.org/pod/App::Netdisco)
[![Docker Image](https://img.shields.io/badge/docker%20images-ready-blue.svg)](https://store.docker.com/community/images/netdisco/netdisco)

**Netdisco** is a web-based network management tool suitable for small to very large networks. IP and MAC address data is collected into a PostgreSQL database using SNMP, CLI, or device APIs. Some of the things you can do with Netdisco:

* Locate a machine on the network by MAC or IP and show the switch port it lives at
* Turn off a switch port, or change the VLAN or PoE status of a port
* Inventory your network hardware by model, vendor, software and operating system
* Pretty pictures of your network

See the demo at: [https://netdisco2-demo.herokuapp.com/](https://netdisco2-demo.herokuapp.com/)

Netdisco includes a lightweight web server for the interface, a backend daemon to gather data from your network, and a command line interface for troubleshooting. There is a simple configuration file in YAML format. 

##  Docker Deployment

Container images are provided for `linux/arm64` and `linux/amd64`.

On Linux hosts, create these directories and allow the service uid (`901`) to write into it:

*(this step is only necessary on Linux hosts and can be omitted in the macOS and Windows versions of Docker)*

    mkdir -p netdisco/{logs,config,nd-site-local} 
    sudo chown -R 901:901 netdisco

Download `compose.yaml` and start everything:

    curl -Ls -o compose.yaml https://tinyurl.com/nd2-dockercompose
    docker-compose up --detach

This runs the database, backend daemon, and web frontend listening on port 5000. If you have a device using the SNMP community `public`, enter it in the Netdisco homepage and click "Discover".

The default configuration is available in `netdisco/config/deployment.yml`. The daemons automatically restart when you save changes to this file. Logs are available in `netdisco/logs/`.

The web frontend is initally configured to allow unauthenticated access with full admin rights. We suggest you visit the `Admin -> User Management` menu item, and set `no_auth: false` in `deployment.yml`, to remove this guest account and set up authenticated user access.

##  Upgrading

Pull new images and recreate the containers:

    curl -Ls --clobber -o compose.yaml https://tinyurl.com/nd2-dockercompose
    docker-compose pull ; docker-compose down ; docker-compose up --force-recreate --detach

With our standard `compose.yaml` file (as above), the database schema is automatically upgraded.

##  Using an external PostgreSQL database

We have a [mix-in Docker Compose file](https://raw.githubusercontent.com/netdisco/netdisco-docker/refs/heads/master/compose.mixin.extpg.yaml) for this. It stops our own database container from running and will look to either [environment variables](https://github.com/netdisco/netdisco/wiki/Environment-Variables) or a local `deployment.yml` configuration file for connection details.

Download the mix-in and start the services:

    curl -Ls -O https://raw.githubusercontent.com/netdisco/netdisco-docker/refs/heads/master/compose.mixin.extpg.yaml
    docker-compose -f compose.yaml -f compose.mixin.extpg.yaml up --detach

If the database is on the same host as your Docker service, then use `host.docker.internal` for its hostname (either in the configuration file or with the `NETDISCO_DB_HOST` environment variable).

##  Pointing at a different configuration file

We have an example [mix-in Docker Compose file](https://raw.githubusercontent.com/netdisco/netdisco-docker/refs/heads/master/compose.mixin.homeenv.yaml) for this. The example points to `deployment.yml` in a user's home directory.

Download the mix-in and start the services:

    curl -Ls -O https://raw.githubusercontent.com/netdisco/netdisco-docker/refs/heads/master/compose.mixin.homeenv.yaml
    docker-compose -f compose.yaml -f compose.mixin.homeenv.yaml up --detach

Edit the mix-in to point to another location.

##  Refreshing MAC vendors

The following command will download and update the MAC vendor database:

    curl -Ls https://raw.githubusercontent.com/netdisco/upstream-sources/refs/heads/master/bootstrap/netdisco-lookup-tables.sql | docker-compose run -T netdisco-do psql

Each containerised Netdisco release also includes the latest MAC vendors, and automatically updates them when starting.

##  Tips

The [netdisco-do](https://metacpan.org/dist/App-Netdisco/view/bin/netdisco-do) utility can be run like this (or without `<action>` to get help):

    docker-compose run netdisco-do <action> ...

Local web or backend plugins can be installed into `netdisco/nd-site-local/` as per [our documentation](https://github.com/netdisco/netdisco/wiki). The PostgreSQL data files are stored in `netdisco/pgdata/` and we do not advise touching them (unless you wish to reinitialize the system).

The `NETDISCO_RO_COMMUNITY` environment variable allows you to override the default of `public` (and avoiding the need to edit the configuration file).

##  Rebuilding

If you wish to build the images locally, use [this compose file](https://raw.githubusercontent.com/netdisco/netdisco-docker/refs/heads/master/compose.build.yaml). Note that it's not a mix-in:

    docker-compose -f compose.build.yaml build --no-cache

## Getting Support

We have several other pages with tips for [understanding and troubleshooting Netdisco](https://github.com/netdisco/netdisco/wiki/Troubleshooting), [tips and tricks for specific platforms](https://github.com/netdisco/netdisco/wiki/Vendor-Tips), and [all the configuration options](https://github.com/netdisco/netdisco/wiki/Configuration).

You can also speak to someone in the [`#netdisco@libera`](https://kiwiirc.com/nextclient/irc.libera.chat/netdisco) IRC channel, or on the [community email list](https://lists.sourceforge.net/lists/listinfo/netdisco-users).

## Credits

Thanks to Ira W. Snyder and LBegnaud for inspiration. Thanks also to the PostgreSQL project for great examples of docker magic. We build with the support of the excellent GitHub Actions service. 
