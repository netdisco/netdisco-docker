# netdisco-docker
Docker images for App::Netdisco

# One-time-Use Environment variables
These only affect things if `deployment.yml` doesn't exist when the container starts, as they are defining the values that get added to that config file. Normal running of the container references `deployment.yml` directly
- `NETDISCO_DB_HOST`
  - Defines the hostname of the postgres DB. Docker containers connected to user-defined networks have builtin DNS, so if you have a container called "netdiscodb", this can be set to "netdiscodb" and the netdisco container should be able to access the DB
  - Default value of "postgres"
- `NETDISCO_DB_PORT`
  - Defines the pgsql port
  - Default value of 5432
- `NETDISCO_DB_USER`
  - Defines the netdisco db user
  - Default value of "netdisco"
- `NETDISCO_DB_PASS`
  - Defines the netdisco db user's password
  - Default value of a 32 random characters
- `NETDISCO_RO_COMMUNITY`
  - Specifies the read-only community string
- `NETDISCO_WR_COMMUNITY`
  - Specifies the read-write community string

# Persistent Environment variables
These will affect settings everytime the container starts
- There are currently no supported global environment variables 