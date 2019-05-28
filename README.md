# Implementation of CartoDB in multiple services

## INSTALL

1. Create the `cartobuilder:latest` image, which is a docker image that has all the pre-requisities for CartoDB, SQL-API, and Windshaft. Those images will be built off of that common base:

    ```bash
    cd docker/BUILDER
    docker build -t cartobuilder:latest .
    cd ../..
    ```

1. Set the contents of the `.env` file to include versions and default user settings, and generate the SSL certificates for nginx, use the `setup-local.sh` script. If you want to cause the cartodb container to run without https, call `CARTO_USE_HTTPS=false ./setup-local.sh --generate-ssl-cert` (You still need to generate the certificates at least once, even if you won't be using them.)

    ```bash
    ./setup-local.sh --generate-ssl-cert
    ```

1. Build the container images for `postgis`, `redis`, `sqlapi`, `windshaft`, `varnish`, `cartodb`, and `router`:

    ```bash
    docker-compose build
    ```

1. Start the cluster. For the first startup, the database and user will be initialized, so expect a lot of output:

    ```bash
    docker-compose up
    ```

1. If you created custom values for the `CARTO_DEFAULT_USER` and `CARTO_DEFAULT_PASS` environment variables, you'll use those to log in, at `<CARTO_DEFAULT_USER>.localhost`. If you left the defaults (set in `setup-local.sh`), you'll go to `developer.localhost` and log in with username `developer` and password `abc123def`. You may need to amend your `/etc/hosts` file to include the domain.



## Overview

CartoDB is itself a multi-service application, made up of the following core pieces:

* **CartoDB Builder** - A Ruby on Rails application that provides user and map/data management for organizations on the Carto platform.
* **PostgreSQL/PostGIS, with Carto extension(s)** - Map and user data are principally stored in a number of PostgreSQL databases, which have been extended with both PostGIS, and the extension functions from Carto's own PostgreSQL extension.
* **Redis** - Configuration, state, and authentication data are stored in Redis. The Redis instance is hit both by CartoDB Builder and by the SQL-API and Windshaft tile server instances.
* **Carto SQL API** - A Node.js application responsible for handling passthrough of SQL to the PostgreSQL instance, allowing both public and authenticated requests. Public requests may perform SELECT on a subset of an organization's data, while requests authenticated by a non-public API key may be allowed to actively alter data on the server.
* **Windshaft Map Tile Server** - A Node.js application which serves map tiles based on data held in the PostgreSQL instance, with the Carto SQL API acting as an intermediary.

This repo adds an additonal container, `router`, which runs an Nginx reverse proxy in front of the other containers. That consolidates the requests to the various services so that they can all go through the same port on localhost, and allows us to use SSL when loading the application.

