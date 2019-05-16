FROM postgres:10 AS base

# This file is based largely on mdillon's postgis Dockerfile for PostgreSQL 10
# and PostGIS 2.5. It inherits PG_MAJOR and PG_VERSION from the official
# postgres Docker image.

ENV POSTGIS_MAJOR 2.5
ENV POSTGIS_VERSION 2.5.2+dfsg-1~exp1.pgdg90+1

# Install system package dependencies
RUN apt-get update \
 && apt-cache showpkg postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
 && apt-get install -y --no-install-recommends \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts=$POSTGIS_VERSION \
    postgresql-server-dev-$PG_MAJOR \
    postgis=$POSTGIS_VERSION \
    postgresql-plpython-$PG_MAJOR \
    postgresql-$PG_MAJOR-plproxy \
    odbc-postgresql \
    unixodbc-dev \
    software-properties-common \
    build-essential \
    pkg-config \
    make \
    ruby \
    python-pip \
    python-dev \
 && pip install setuptools \
 && rm -rf /var/lib/apt/lists/*

# Install the Carto PostgreSQL extensions
COPY ./pg_extensions /carto/pg_extensions
ENV CARTO_PG_EXT_DIR /carto/pg_extensions

RUN rm ${CARTO_PG_EXT_DIR}/cartodb-postgresql/.git \
 && mkdir -p ${CARTO_PG_EXT_DIR}/cartodb-postgresql/.git \
 && echo "fake index file to satisfy Makefile rule carto_version.sql" > ${CARTO_PG_EXT_DIR}/cartodb-postgresql/.git/index \
 && cd ${CARTO_PG_EXT_DIR}/cartodb-postgresql \
 && make install \
 && cd ${CARTO_PG_EXT_DIR}/dataservices-api-client/client \
 && make install \
 && cd ${CARTO_PG_EXT_DIR}/dataservices-api-server/server/extension \
 && make install \
 && cd ${CARTO_PG_EXT_DIR}/dataservices-api-server/server/lib/python/cartodb_services \
 && pip install -r requirements.txt \
 && pip install . --upgrade \
 && cd ${CARTO_PG_EXT_DIR}/data-services/geocoder/extension \
 && make install \
 && cd ${CARTO_PG_EXT_DIR}/odbc_fdw \
 && make install 

WORKDIR /carto

RUN mkdir -p /docker-entrypoint-initdb.d \
 && chmod 777 /usr/share/doc \
 && chown -R postgres:postgres /usr/share/postgresql
COPY ./initdb.d/*.sh /docker-entrypoint-initdb.d/
COPY ./initdb.d/*.sql /docker-entrypoint-initdb.d/

EXPOSE 5432

ENV POSTGRES_USER postgres
