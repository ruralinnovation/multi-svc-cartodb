# Installation

This document covers how to install the `multi-svc-cartodb` repository to a local development machine, build its component Docker images, and run the cluster of containers enabled by the [`docker-compose.yml`](../docker-compose.yml) file in the repository root.

For information about deploying the containers to a cloud environment, please see [DEPLOYMENT.md](./DEPLOYMENT.md).

## Pre-requisites

To use this repository, you will need [Docker](https://www.docker.com/) (18.09+), `git` (2.21+), and access to a `bash` shell.

## Step by step instructions

1. Clone this repo to a local folder, and change directories into the root of the repo:

    ```bash
    git clone https://github.com/ruralinnovation/multi-svc-cartodb.git
    cd multi-svc-cartodb
    ```

1. Build the `cartobuilder:latest` Docker image, which has all of the dependencies for CartoDB, SQL-API, and Windshaft. Those images will be built off of that common base. This build process will take some time to complete (probably fifteen minutes to half an hour).

    ```bash
    docker build --tag cartobuilder:latest docker/BUILDER
    ```

1. You will build (and run) the rest of the containers using the `docker-compose` command. During the build process Compose will need some environment values that it can merge into the containers, for version strings, default user info, etc. We consolidate those values in a `.env` file in the root of the repo, which `docker-compose` will source automatically. To create that file, you can run the `scripts/setup-local.sh` script:

    ```bash
    ./scripts/setup-local.sh
    ```

1. You can view the file contents, which should look something like the following. If you would like to set custom values for any of the environment variables, you can: a) edit the `.env` file directly (note that it will be overwritten in any subsequent call to `setup-local.sh`); b) set a value for that variable for a single run of `setup-local.sh` by prepending it to the call (as in `CARTO_USE_HTTPS=false ./scripts/setup-local.sh`); or c) export a value for that variable in your `~/.bash_profile` file, which will be set in the environment of any new terminal window from which you might call `setup-local.sh`. Using option c will ensure that your new value is used for every new generation of the `.env` file.

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
    ./scripts/generate_ssl_certs.sh
    ```

1. You will also need to add an entry for `osscarto.localhost` to your `/etc/hosts` file, to make sure you get local DNS translation for your hostname and subdomain:

    ```bash
    echo "127.0.0.1   osscarto.localhost" | sudo tee -a /etc/hosts
    ```

1. In order to make your local browser consider the `router` container's signed certificate legitimate, you'll need to add the root certificate of the signing CA you created to your local development machine's trusted cert store. On a Linux host that probably means adding it to `/usr/local/share/ca-certificates/`, on a Mac it will mean adding it to your Keychain (for instructions see the Installing Your Root Certificate section [of this article about local HTTPS](https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/)). (TODO: Add Windows instructions.)
1. Now that you have a `.env` file and SSL certificate files, you can build the container images for `postgis`, `redis`, `sqlapi`, `windshaft`, `varnish`, `cartodb`, and `router`. This may take some time.

    ```bash
    docker-compose build
    ```

1. Start the cluster. For the first startup, the database and user will be initialized, so expect a lot of output. If you would like to detach the terminal from the output you can use [the `-d` flag](https://docs.docker.com/compose/reference/up/) to `docker-compose`.

    ```bash
    docker-compose up
    ```

1. The first time you bring the cluster up, Docker will create several data volumes (to persist Redis and PostgreSQL data), and the PostgreSQL data cluster will be initialized. Once the data cluster is created, a number of custom Carto PostgreSQL extensions will be installed. When that's complete, the `cartodb` container will be able to run its own initialization process. When all of those steps are completed, you should be able to load the application at `https://osscarto.localhost` in a browser.
1. You can log into the application using the username and password defined by the `CARTO_DEFAULT_USER` and `CARTO_DEFAULT_PASS` values in your `.env` file, or the ones from `CARTO_ORG_USER` and `CARTO_ORG_PASS`.
