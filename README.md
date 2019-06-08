# Implementation of CartoDB in multiple services

## Overview

CartoDB is itself a multi-service application, made up of the following core pieces:

* **CartoDB Builder** - A Ruby on Rails application that provides user and map/data management for organizations on the Carto platform.
* **PostgreSQL/PostGIS, with Carto extension(s)** - Map and user data are principally stored in a number of PostgreSQL databases, which have been extended with both PostGIS, and the extension functions from Carto's own PostgreSQL extension.
* **Redis** - Configuration, state, and authentication data are stored in Redis. The Redis instance is hit both by CartoDB Builder and by the SQL-API and Windshaft tile server instances.
* **Carto SQL API** - A Node.js application responsible for handling passthrough of SQL to the PostgreSQL instance, allowing both public and authenticated requests. Public requests may perform SELECT on a subset of an organization's data, while requests authenticated by a non-public API key may be allowed to actively alter data on the server.
* **Windshaft Map Tile Server** - A Node.js application which serves map tiles based on data held in the PostgreSQL instance, with the Carto SQL API acting as an intermediary.
* **Varnish HTTP Cache** - A cache of hits against the SQL API.

Those services are encapsulated in containers named:

* `cartodb`
* `postgis`
* `redis`
* `sqlapi`
* `windshaft`
* `varnish`

Additionally this repo adds a seventh container, `router`, which runs an Nginx reverse proxy in front of the other containers. That consolidates the requests to the various services so that they can all go through the same port on localhost, and allows us to use SSL when loading the application.

Note that the image names, as created by `docker-compose`, will have the name of the root directory (where `docker-compose.yml` is located) prepended to them. They will show up via `docker image ls` as things like `multi-svc-cartodb_postgis`. If you would like to use a custom value for the prepended name, you can alter the directory name, or set a value for the [`COMPOSE_PROJECT_NAME` environment variable](https://docs.docker.com/compose/reference/envvars/) on your development machine. 

## INSTALL

1. Clone this repo to a local folder, and change directories into the root of the repo:

    ```bash
    git clone https://github.com/ruralinnovation/multi-svc-cartodb.git
    cd multi-svc-cartodb
    ```

1. Build the `cartobuilder:latest` Docker image, which has all of the dependencies for CartoDB, SQL-API, and Windshaft. Those images will be built off of that common base. This build process will take some time to complete (probably 15 minutes to half an hour).

    ```bash
    docker build --tag cartobuilder:latest docker/BUILDER
    ```

1. You will build (and run) the rest of the containers using the `docker-compose` command. During the build process Compose will need some environment values that it can merge into the containers, for version strings, default user info, etc. It can get those values from various places, but we'll consolidate them in a `.env` file in the root of the repo. To create that file, you can run the `setup-local.sh` script in the repo root:

    ```bash
    ./setup-local.sh
    ```

1. You can view the file contents, which should look something like the following. If you would like to set custom values for any of the environment variables, you can: a) edit the `.env` file directly (note that it will be overwritten in any subsequent call to `setup-local.sh`, as in the next step of this guide); b) set a value for that variable for a single run of `setup-local.sh`, by prepending it to the call (as in `CARTO_USE_HTTPS=false ./setup-local.sh`); or c) export a value for that variable in your `~/.bash_profile` file, which will be set in the environment of any new terminal window from which you might call `setup-local.sh`. Using option c will ensure that your new value is used for every new generation of the `.env` file.

    ```
    $ cat .env
    CARTO_USE_HTTPS=true
    CARTO_WINDSHAFT_VERSION=7.1.0
    CARTO_SQLAPI_VERSION=3.0.0
    CARTO_CARTODB_VERSION=v4.26.1
    CARTO_PGEXT_VERSION=0.26.1
    CARTO_DATASVCS_API_CLIENT_VERSION=0.26.2-client
    CARTO_DATASVCS_API_SERVER_VERSION=0.35.1-server
    CARTO_DATASVCS_VERSION=0.0.2
    CARTO_ODBC_FDW_VERSION=0.3.0
    CARTO_CRANKSHAFT_VERSION=0.8.2
    CARTO_OBSERVATORY_VERSION=1.9.0
    CARTO_DEFAULT_USER=developer
    CARTO_DEFAULT_PASS=abc123def
    CARTO_DEFAULT_EMAIL=username@example.com
    CARTO_ORG_NAME=dev-org
    CARTO_ORG_USER=dev-org-admin
    CARTO_ORG_EMAIL=dev-org-admin@example.com
    CARTO_ORG_PASS=abc123def
    ```

1. In order to support HTTPS (and to build the `router` container), you will need to generate a number of SSL related files (primarily a root certificate for a local certificate authority, and .crt and .key files for a signed SSL certificate). You can do this by using the `generate_ssl_certs.sh` script:

    ```bash
    ./generate_ssl_certs.sh
    ```

1. You will also need to add an entry for `cori.localhost` to your `/etc/hosts` file, to make sure you get local DNS translation for your hostname and subdomain:

    ```bash
    echo "127.0.0.1   cori.localhost" | sudo tee -a /etc/hosts
    ```

1. And in order to make your local browser consider the `router` container's signed certificate legitimate, you'll need to add the root certificate of the signing CA you created to your local development machine's trusted cert store. On a Linux host that probably means adding it to `/usr/local/share/ca-certificates/`, on a Mac it will mean adding it to your Keychain (for instructions see the Installing Your Root Certificate section [of this article about local HTTPS](https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/)). (TODO: Add Windows instructions.)
1. Now that you have a `.env` file and SSL certificate files, you can build the container images for `postgis`, `redis`, `sqlapi`, `windshaft`, `varnish`, `cartodb`, and `router`. This may take some time.

    ```bash
    docker-compose build
    ```

1. Start the cluster. For the first startup, the database and user will be initialized, so expect a lot of output. If you would like to detach the terminal from the output (only possible at startup), you can use [the `-d` flag](https://docs.docker.com/compose/reference/up/) to `docker-compose`.

    ```bash
    docker-compose up
    ```

1. Once the application cluster is initialized (see below for details), load the cluster in a browser, at `https://cori.localhost/`. You should be able to log in with the values for `CARTO_DEFAULT_USER` and `CARTO_DEFAULT_PASS` from your `.env` file. You may need to adjust your browser settings to allow for a self-signed SSL certificate for localhost. In Chrome you can do this by loading `chrome://flags/#allow-insecure-localhost` in the browser and changing the setting to enabled. You will still get some warnings (the browser's SSL lock icon will almost certainly tell you it is an insecure connection), but it won't prevent you loading the page.

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

If you would like to remove _all_ of the volumes for the cluster, there is a utility script in the root of the repo called `remove_docker_volumes.sh`. Note that if you remove them all, you may need to run `docker-compose build postgis` to repopulate the PostgreSQL extensions directory before bringing the cluster back up.

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

## Contributing

Hey, thanks for thinking about helping with this effort! Here's our [contribution guidelines](./CONTRIBUTING.md).
