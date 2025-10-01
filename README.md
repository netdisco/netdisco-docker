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

The containers need some directories present in the mounted volume. In a directory of your choice, create this structure and allow the netdisco uid in the container (901) to write into it:

    cd $directory_of_your_choice
    mkdir -p netdisco/{logs,config,nd-site-local} 
    sudo chown -R 901:901 netdisco

*(this step is necessary on Linux hosts and can be omitted in the OS X and Windows versions of Docker)*

Download docker-compose.yml into the same directory and start everything 

    curl -Ls -o docker-compose.yml https://tinyurl.com/nd2-dockercompose
    docker-compose up

This will start the database, backend daemon, and web frontend listening on port 5000. If you have a device using the SNMP community `public`, enter it in the Netdisco homepage and click "Discover".

The default configuration is available in `netdisco/config/deployment.yml`. The backend and web daemons will automatically restart when you save changes to this file. Logs are available in `netdisco/logs/`.

The web frontend is initally configured to allow unauthenticated access with full admin rights. We suggest you visit the `Admin -> User Management` menu item, and set `no_auth: false` in `deployment.yml`, to remove this guest account and set up authenticated user access.

## Upgrading

Pulling new images and recreate the containers:

    docker-compose pull ; docker-compose down ; docker-compose up --force-recreate

When our database image starts it always updates the DB schema to the latest release.

If using your own database server or image, then you have to also run:

    docker-compose exec netdisco-backend bin/netdisco-deploy

You can also use that command to update the supporting data files (MAC address vendors, device vendors, and SNMP MIBs) any other time.

See [Headless Update](https://github.com/netdisco/netdisco/wiki/Headless-Update) if you need to update these files in an automated way or without internet access.

## Tips

The [netdisco-do](https://metacpan.org/dist/App-Netdisco/view/bin/netdisco-do) utility can be run like this (or without `<action>` to get help):

    docker-compose run netdisco-do <action> ...

Database username, password, database connection, and file locations, can all be set using [environment variables](https://github.com/netdisco/netdisco/wiki/Environment-Variables) described in our wiki. Of course the database container is optional and you can connect to an existing or external PostgreSQL server instead.

You can change the password of the netdisco PostgreSQL user with this command (and update in `netdisco/config/deployment.yml` too!):

    docker-compose exec netdisco-postgresql psql -U postgres -c "alter role netdisco password 'your new password';"

Local web or backend plugins can be installed into `netdisco/nd-site-local/` as per [our documentation](https://github.com/netdisco/netdisco/wiki). The PostgreSQL data files are stored in `netdisco/pgdata/` and we do not advise touching them (unless you wish to reinitialize the system).

##  Docker Requirements

 * Docker 20.10.0 (Linux) or Docker Desktop 3.3.0 (Win/Mac) 
 * docker-compose 1.28

## Getting Support

We have several other pages with tips for [understanding and troubleshooting Netdisco](https://github.com/netdisco/netdisco/wiki/Troubleshooting), [tips and tricks for specific platforms](https://github.com/netdisco/netdisco/wiki/Vendor-Tips), and [all the configuration options](https://github.com/netdisco/netdisco/wiki/Configuration).

You can also speak to someone in the [`#netdisco@libera`](https://kiwiirc.com/nextclient/irc.libera.chat/netdisco) IRC channel, or on the [community email list](https://lists.sourceforge.net/lists/listinfo/netdisco-users).

## Credits

Thanks to Ira W. Snyder and LBegnaud for inspiration. Thanks also to the PostgreSQL project for great examples of docker magic. We build with the support of the excellent GitHub Actions service. 
