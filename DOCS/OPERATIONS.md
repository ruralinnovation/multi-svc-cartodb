# Operations Guide

This document provides information about how the application stack is built, and how it is operated.

## Application Initialization

### Initializing the PostgreSQL cluster (this happens automatically)

The first time the cluster is brought up, three docker volumes are created:

* `redis-data` - Persists the data store for the `redis` container
* `postgis-data` - Persists the data for the `postgis` container
* `postgis-extensions` - Persists the `/usr/share/postgresql` directory on the `postgis` container, so that the built extension files may be installed onto new databases created during runtime.

Once those volumes are created, the PostgreSQL data cluster has to be initialized. This will happen automatically, by virtue of the underlying `postgres:10` [official docker image](https://hub.docker.com/_/postgres) having a built-in init process when it is started with an empty data directory. As part of that process, the PostgreSQL process will attempt to execute any shell or SQL scripts it finds on the container in the directory `/docker-entrypoint-initdb.d`. The Dockerfile for the `postgis` container copies one startup script there, `multi-svc-cartodb/docker/postgis/initdb.d/00_setup_carto_pg.sh`. Once the PostgreSQL cluster is initiated, that script is used to:

1. Create the `publicuser` and `tileuser` PostgreSQL roles
1. Globally install the `plpythonu` PostgreSQL extension
1. Create the PostgreSQL template database `template_postgis`, and install the following extensions to it:
    * `plpgsql` - The pgsql procedural language
    * `postgis` - The PostGIS core extension
    * `postgis_topology` - The PostGIS topology extension
    * `plpythonu` - The python procedural language
    * `plproxy` - The PL/Proxy database partitioning system
    * `crankshaft` - One of Carto's geospatial extensions, found here: [https://github.com/cartodb/crankshaft](https://github.com/cartodb/crankshaft)
1. Create the `geocoder_api` PostgreSQL role
1. Create the `dataservices_db` database (owned by `geocoder_api`), and install the following extensions to it:
    * `plproxy`
    * `plpythonu`
    * `postgis`
    * `cartodb` - A Carto PostgreSQL extension that includes a substantial amount of the core program logic for the PostgreSQL side of the Carto applications. Found here: [https://github.com/cartodb/cartodb-postgresql](https://github.com/cartodb/cartodb-postgresql)
    * `cdb_geocoder` - Carto extension that powers their internal geocoder: [https://github.com/cartodb/data-services](https://github.com/cartodb/data-services)
    * `cdb_dataservices_server` - Carto extension that provides access to their geocoder: [https://github.com/cartodb/dataservices-api](https://github.com/cartodb/dataservices-api)
    * `cdb_dataservices_client` - Carto extension that gives client databases access to the geocoder api from `cdb_dataservices_server`. Also found at [https://github.com/cartodb/dataservices-api](https://github.com/cartodb/dataservices-api)
    * `observatory` - Carto extension that 'implements the row level functions needed by the Observatory service'. Found here: [https://github.com/CartoDB/observatory-extension](https://github.com/CartoDB/observatory-extension)
1. Load the fixture tables and data the Observatory extension depends on
1. Make grants to the `geocoder_api` role for tables and functions in the schema `observatory`
1. Add Carto application-specific configuration inside PostgreSQL, by making a number of `SELECT` statements that use the `cartodb.CDB_Conf_SetConf()` function.

### Creating the Carto application and user databases (also happens automatically)

When the `postgis` container has completed its cluster init, and the `cartodb` container is up and running, the `/carto/docker-entrypoint.sh` script on that container will do the following:

1. If the `CARTO_USE_HTTPS` value in your `.env` file was `true` at the time the container was built, the script will adjust a line of code in `/carto/cartodb/config/initializers/carto_db.rb` to allow HTTPS usage while the RAILS_ENV is set to `development`.
1. If `CARTO_USE_HTTPS` was not `true`, the script will copy the contents of `config/app_config_no_https.yml` into `config/app_config.yml`.
1. If the database name provided for the current environment in `config/database.yml` does not exist in the PostgreSQL cluster, it is created via the `db:create` rake task in the Carto Rails application.
1. If there are fewer than 60 tables found in that database, the script will execute the `db:migrate` rake task. (Running migrations multiple times wouldn't be harmful, it just takes up time so we skip it if there's already a lot of tables in the db.)
1. If there's no entry in the `users` table in that database for the `CARTO_DEFAULT_USER` and `CARTO_DEFAULT_EMAIL` values from your `.env` file, that user is created by executing the `script/better_create_dev_user.sh` script (one we've added to make that process more transparent). That script will also update a number of user settings in the database.
1. If no entries exist for the organization and org user defined by the `CARTO_ORG_NAME`, `CARTO_ORG_USER`, and `CARTO_ORG_EMAIL` entries in your `.env` file, that organization and user are created via the `script/setup_organization.sh` script (another of ours). That script also makes some settings changes for the organization and user.
1. Runs the `script/restore_redis` script
1. Starts the Resque process (the RoR job runner that Carto uses)
1. Clears existing API keys and regenerates them
1. Starts the rails server on port 80 (which the `router` container will reverse proxy to when incoming HTTPS connections are made)

### Destroying and recreating the persistent storage

If you are working on the process of initialization, or if you would like to test or re-run the PostgreSQL initialization process and script(s), it will be necessary to at the very least destroy (or otherwise make unavailable) the `postgis-data` Docker volume. If the PostgreSQL process finds anything other than a completely empty data directory (at `/var/lib/postgresql/data`), it will skip the cluster initialization process. To remove the `postgis-data` volume, you can run:

```bash
docker-compose down
docker volume ls -q --filter "name=postgis-data" | xargs docker volume rm
```

If you would like to remove _all_ of the volumes for the cluster, there is a utility script in the this repo's `/scripts` directory called `remove_docker_volumes.sh`. Note that if you remove them all, you may need to run `docker-compose build postgis` to repopulate the PostgreSQL extensions directory before bringing the cluster back up.

## Operating

### Starting and Stopping the Application Cluster

To start the cluster, you can use `docker-compose up`. This will create a Docker network and the Docker volumes if they do not already exist, then start the containers in dependency order. 

To stop the cluster, use `docker-compose stop`. This will attempt to gracefully stop all containers referenced in the `docker-compose.yml` file. If they cannot be gracefully stopped they are sent a hard stop signal and killed.

Note: Stopping the cluster does not remove the containers, it simply stops them. If you want to both stop the cluster and remove the stopped containers, use `docker-compose down`.

### Getting a shell on an individual container

If you would like to get a shell on any of the containers, you may do so with `docker exec`, called from the root of the repo:

```bash
cd multi-svc-cartodb
docker-compose exec cartodb /bin/bash
```

You can get a shell on any of the containers, but note that because both the `redis` and `router` containers are build on very minimal Alpine Linux installs, they do not have a `bash` shell by default. For those, use `docker-compose exec redis /bin/sh`.

### Connecting to the databases

#### PostgreSQL

Other than the `router` container, the `postgis` container is the only one that opens a port on the host machine. Consequently you can get an interactive session on that container's PostgreSQL instance by hitting `localhost:5432` as the user `postgres`:

```bash
psql -U postgres -h localhost
```

Alternatively, you can use the `psql` client on the container itself, by connecting to it with `docker-compose exec postgis psql -U postgres -h localhost` (or by getting a bash shell and running `psql` from there).

#### Redis

You can't directly connect to the Redis instance from the host machine, so you'll have to do it via the `redis-cli` utility on the container itself:

```bash
docker-compose exec redis redis-cli
```

Or by getting a `/bin/sh` shell on the container and calling `redis-cli` from that.
