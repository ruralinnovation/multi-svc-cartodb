# PostgreSQL / PostGIS

## Overview

The Dockerfile here generates a container based on the [official postgres docker image](https://hub.docker.com/_/postgres) for PostgreSQL 10.7. The base container OS is Debian (from the `debian:stretch-slim` image), and the following are installed as Debian system packages (on top of those installed in the base `postgres:10` image):

* `postgresql-10-postgis-2.5`
* `postgresql-10-postgis-2.5-scripts`
* `postgresql-server-dev-10`
* `postgis`
* `postgresql-plpython-10`
* `make`

The [CartoDB postgres extension](https://github.com/CartoDB/cartodb-postgresql) is installed after the database is initialized, which happens via the `docker-entrypoint.sh` script inherited from the `postgres:10` image. The mechanism for adding to the database initialization on the container is to place `.sh` or `.sql` files into the `initdb.d` directory of this repository. Any files placed there will be copied into the container on build and, if no database is already in the directory at `$PGDATA` (`/var/lib/postgresql/data` by default), those scripts will all run as part of the dbinit triggered by `docker-entrypoint.sh`.

Relevant links:

* [Dockerfile for the `postgres:10` image](https://github.com/docker-library/postgres/blob/85aadc08c347cd20f199902c4b8b4f736341c3b8/10/Dockerfile)
* [`docker-entrypoint.sh` from the same repository](https://github.com/docker-library/postgres/blob/85aadc08c347cd20f199902c4b8b4f736341c3b8/10/docker-entrypoint.sh)
* [Dockerfile for the `docker-postgis:10-2.5` image](https://github.com/appropriate/docker-postgis/blob/master/10-2.5/Dockerfile), which is not directly invoked here, but which the Dockerfile and init script used here are loosely based on.

## Assets

There are two asset types here: the `cartodb-postgresql` repository as a submodule, and db init scripts in the `initdb.d` folder. The submodule repo is checked out at a specific tag--the `0.26.1` release when this was written (2019-04-25). To change that, simply change into that directory and check out a different tag or revision, then rebuild the image.

The db init scripts are:

* `00_init_postgis.sh` - Creates the `template_postgis` database, and installs the following postgres extensions:
    * `postgis`
    * `postgis_topology`
    * `fuzzystrmatch`
    * `postgis_tiger_geocoder`
    * `plpythonu`
* `10_create_carto_users.sh` - Creates the `publicuser` and `tileuser` postgres users
* `11_install_carto_pg_extension.sh` - Installs the `cartodb-postgresql` extension (though it does not add it to any database or schema)
* `99_blank_file.sh` and `99_blank_file.sql` - Files with no content other than a descriptive comment. Present to ensure the Dockerfile does not fail on `COPY` if no other `.sh` or `.sql` files are present in the `initdb.d` directory.
