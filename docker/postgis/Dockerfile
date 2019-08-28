FROM postgres:10 AS base

#### NOTES ###################################################################
#
#  * This file is a combination of work from mdillon's postgis Dockerfile for
#    PostgreSQL 10 and PostGIS 2.5, and sverhoeven's single-container Dockerfile
#    for running all Carto services.
#
#  * PG_MAJOR and PG_VERSION are inherited from the base image, which is the
#    official Postgres docker for pg 10.
#
#  * It isn't necessary to add the official PostgreSQL apt repos, because they
#    have been added in the base image.
#
#  * The adjustments to locales recommended by Carto are done in the base image.
#    Specifics in the postgres:10 Dockerfile: https://git.io/fj4bJ
#
##############################################################################

ENV DEBIAN_FRONTEND noninteractive
ENV POSTGIS_MAJOR 2.5
ENV POSTGIS_VERSION 2.5.2+dfsg-1~exp1.pgdg90+1

RUN echo "Installing PostgreSQL/PostGIS..." \
 && apt-get -qq update \
 && apt-get install -y -q --no-install-recommends \
    postgis=$POSTGIS_VERSION \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts=$POSTGIS_VERSION \
    postgresql-server-dev-$PG_MAJOR \
 && echo "Installing plpython and plproxy PG extensions..." \
 && apt-get install -y -q --no-install-recommends \
    postgresql-plpython-$PG_MAJOR \
    postgresql-$PG_MAJOR-plproxy \
 && rm -rf /var/lib/apt/lists/*

RUN echo "Installing build dependencies for Carto PG extensions..." \
 && apt-get -qq update \
 && apt-get install -y -q --no-install-recommends \
    make \
    git \
    build-essential \
    ruby \
    python-pip \
    python-dev \
    python-setuptools \
    python-wheel \
    unixodbc-dev \
 && echo "Installing runtime dependencies for PG extensions..." \
 && apt-get install -y -q --no-install-recommends \
    odbc-postgresql \
 && rm -rf /var/lib/apt/lists/*

ENV CARTO_PGEXT_REPO https://github.com/CartoDB/cartodb-postgresql.git
ENV CARTO_DATASVCS_API_REPO https://github.com/CartoDB/dataservices-api.git
ENV CARTO_DATASVCS_REPO https://github.com/CartoDB/data-services.git
ENV CARTO_ODBC_FDW_REPO https://github.com/CartoDB/odbc_fdw.git
ENV CARTO_CRANKSHAFT_REPO https://github.com/CartoDB/crankshaft.git
ENV CARTO_OBSERVATORY_REPO https://github.com/CartoDB/observatory-extension.git

WORKDIR /carto

#### POSTGRES EXTENSION DEPENDENCIES #########################################
#
# Dependencies by extension:
#
#   * cartodb-postgresql
#       * make
#   * dataservices-api-client
#       * make
#       * ruby
#   * dataservices-api-server
#       * dataservices-api-server/server/extension:
#           * make
#       * dataservices-api-server/server/lib/python/cartodb_services:
#           * python-pip
#           * python-dev
#           * python-setuptools
#           * build-essential
#   * data-services (geocoder)
#       * make
#   * odbc_fdw
#       * make
#       * build-essential
#       * unixodbc-dev
#       * odbc-postgresql <== Not required for `make install`, but probably at runtime
#   * crankshaft
#       * make
#       * build-essential
#       * python-pip
#       * python-dev
#       * python-wheel
#       * python-setuptools
#   * observatory
#       * make
#
##############################################################################

ARG CARTO_PGEXT_VERSION="master"
ARG CARTO_DATASVCS_API_CLIENT_VERSION="master"
ARG CARTO_DATASVCS_API_SERVER_VERSION="master"
ARG CARTO_DATASVCS_VERSION="master"
ARG CARTO_ODBC_FDW_VERSION="master"
ARG CARTO_CRANKSHAFT_VERSION="master"
ARG CARTO_OBSERVATORY_VERSION="master"

RUN git clone --recursive ${CARTO_PGEXT_REPO} \
 && cd /carto/cartodb-postgresql \
 && git checkout ${CARTO_PGEXT_VERSION} \
 && git submodule update --recursive \
 && make install \
 && cd /carto \
 && git clone --recursive ${CARTO_DATASVCS_API_REPO} \
 && cd /carto/dataservices-api \
 && git checkout ${CARTO_DATASVCS_API_CLIENT_VERSION} \
 && git submodule update --recursive \
 && cd /carto/dataservices-api/client \
 && make install \
 && cd /carto/dataservices-api \
 && git checkout ${CARTO_DATASVCS_API_SERVER_VERSION} \
 && git submodule update --recursive \
 && cd /carto/dataservices-api/server/extension \
 && make install \
 && cd /carto/dataservices-api/server/lib/python/cartodb_services \
 && pip install --no-cache-dir -r requirements.txt \
 && pip install . --upgrade --no-cache-dir \
 && cd /carto \
 && git clone --recursive ${CARTO_DATASVCS_REPO} \
 && cd /carto/data-services \
 && git checkout ${CARTO_DATASVCS_VERSION} \
 && git submodule update --recursive \
 && cd /carto/data-services/geocoder/extension \
 && make install \
 && cd /carto \
 && git clone --recursive ${CARTO_ODBC_FDW_REPO} \
 && cd /carto/odbc_fdw \
 && git checkout ${CARTO_ODBC_FDW_VERSION} \
 && git submodule update --recursive \
 && make install \
 && cd /carto \
 && git clone --recursive ${CARTO_CRANKSHAFT_REPO} \
 && cd /carto/crankshaft \
 && git checkout ${CARTO_CRANKSHAFT_VERSION} \
 && git submodule update --recursive \
 && make install \
 && cd /carto \
 && git clone --recursive ${CARTO_OBSERVATORY_REPO} \
 && cd /carto/observatory-extension \
 && git checkout ${CARTO_OBSERVATORY_VERSION} \
 && git submodule update --recursive \
 && make install \
 && cd /usr/share/postgresql/10/extension \
 && cp ./observatory--dev.sql ./observatory--current--1.9.0.sql

RUN mkdir -p /docker-entrypoint-initdb.d \
 && chmod 777 /usr/share/doc \
 && chown -R postgres:postgres /usr/share/postgresql

COPY ./initdb.d/*.sh /docker-entrypoint-initdb.d/
COPY ./initdb.d/*.sql /docker-entrypoint-initdb.d/
COPY ./ssl/osscartoCA.pem /usr/local/share/ca-certificates/osscartoCA.crt

RUN update-ca-certificates

EXPOSE 5432

ENV POSTGRES_USER postgres
