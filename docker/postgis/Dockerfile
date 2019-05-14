FROM postgres:10 AS base

# This file is based largely on mdillon's postgis Dockerfile for PostgreSQL 10
# and PostGIS 2.5. It inherits PG_MAJOR and PG_VERSION from the official
# postgres Docker image.

ENV POSTGIS_MAJOR 2.5
ENV POSTGIS_VERSION 2.5.2+dfsg-1~exp1.pgdg90+1

# The installation here is very specific in terms of versioning, because
# otherwise it is very easy to accidentally end up with Postgres 11 bits and
# pieces floating around. The addition of postgresql-server-dev-$PG_MAJOR is
# because in order to run the cartodb-postgresql Makefile, the `pg_config`
# executable has to be available. The installation of `make` is also to enable
# running that Makefile.
RUN apt-get update \
      && apt-cache showpkg postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
      && apt-get install -y --no-install-recommends \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts=$POSTGIS_VERSION \
           postgresql-server-dev-$PG_MAJOR=$PG_VERSION \
           postgis=$POSTGIS_VERSION \
           postgresql-plpython-$PG_MAJOR=$PG_VERSION \
           postgresql-$PG_MAJOR-plproxy \
           make \
      && rm -rf /var/lib/apt/lists/*

# Since we are sourcing the cartodb-postgresql extension from a local link
# to the cartodb-postgresql github repo (as a submodule of the current repo),
# we need to copy its contents to the image in order to install it. Note that
# the checked out branch of the submodule is set in the submodule folder,
# not here. If you want to try a different version of cartodb-postgresql,
# go into the submodule directory for it and do `git checkout <version-tag>`,
# and then rebuild the container.
WORKDIR /carto
COPY --chown=postgres:postgres ./cartodb-postgresql ./cartodb-postgresql
# The makefile expects a target of 'index' in the .git directory for the 
# module, which for git submodules is in the git directory of the parent
# module. In this case the parent will be missing entirely, because the 
# submodule has been copied into a Docker container and the repo root
# is outside the Docker build context. Consequently we need to remove the
# .git file in the submodule (which exists to reference the parent module's
# .git directory location), and replace it with a dummy folder with a blank
# index file in it. The Makefile doesn't actually *use* the index file for
# anything, it just requires that it be present.
RUN rm /carto/cartodb-postgresql/.git \
 && mkdir -p /carto/cartodb-postgresql/.git \
 && echo "fake index file to satisfy Makefile rule carto_version.sql" > /carto/cartodb-postgresql/.git/index

# Installing the dataservices api extensions
COPY ./dataservices-api-server /carto/dataservices-api-server
COPY ./dataservices-api-client /carto/dataservices-api-client

# The client extension has a ruby builder script that the Makefile uses,
# so we install and then remove ruby.
# One of the CDB functions in the postgres extension needs Python's redis
# module, so we have to install that too.
RUN apt-get update \
 && apt-get install -y ruby python-pip \
 && cd /carto/dataservices-api-client/client \
 && make install \
 && cd /carto/dataservices-api-server/server/extension \
 && make install \
 && cd /carto \
 && pip install redis \
 && apt-get remove -y ruby python-pip

# TODO: Figure out whether it's worth it to use pgbouncer.
# Installing pgbouncer because some parts of the CartoDB ecosystem expect
# it to be there.
#RUN apt-get update \
# && apt-get install -y \
#    pgbouncer \
# && mkdir -p /var/log/pgbouncer \
# && mkdir -p /var/run/pgbouncer \
# && chown -R postgres:postgres /var/log/pgbouncer \
# && chown -R postgres:postgres /var/run/pgbouncer 
#
#COPY ./pgbouncer/pgbouncer.ini /etc/pgbouncer/
#COPY ./pgbouncer/userlist.txt /etc/pgbouncer/

# The following parts of this are concerned with installing scripts to init
# the database on container run. The mechanism for doing so (by copying .sh
# and .sql files into /docker-entrypoint-initdb.d) comes from the base image,
# which expects any init scripts to live in that directory. Those scripts will
# be run by the `docker-entrypoint.sh` script that the base image installs
# in the filesystem root. Note that init files added to that directory will
# ONLY run if there is no initialized database in the data directory referenced
# by the PGDATA environment variable. If you are testing additions to the
# database init, watch out for the case where some part of your init fails--
# you can end up in a state where subsequent runs won't trigger the init 
# scripts at all, because some or all of the database files were created already.
RUN mkdir -p /docker-entrypoint-initdb.d \
 && chmod 777 /usr/share/doc \
 && chown -R postgres:postgres /usr/share/postgresql
COPY ./initdb.d/*.sh /docker-entrypoint-initdb.d/
COPY ./initdb.d/*.sql /docker-entrypoint-initdb.d/

EXPOSE 5432

ENV POSTGRES_USER postgres
