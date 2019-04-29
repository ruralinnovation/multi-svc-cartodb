FROM ubuntu:16.04 AS base

ENV PG_MAJOR 10
ENV CARTO_GIS_PPA_FINGERPRINT E54DBDF7355FE6DBEC654BAC6F44D37DD878D6C2

RUN apt-get update \
 && apt-get -y install \
    software-properties-common \
    build-essential \
    pkg-config \
    locales \
    make \
    zip \
    wget \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Add all package indexes to the container
COPY ./sources.list.d/*.list /etc/apt/sources.list.d/

# Install PPA keys/fingerprints, then install PPA-sourced packages
RUN apt-key adv --keyserver=keyserver.ubuntu.com --recv-keys $CARTO_GIS_PPA_FINGERPRINT \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    postgresql-server-dev-$PG_MAJOR \
    gdal-bin \
    libgdal-dev

WORKDIR /carto

COPY ./setup_node_10.sh /carto/setup_node_10.sh

RUN /bin/bash -c /carto/setup_node_10.sh \
 && apt-get update \
 && apt-get install -y nodejs

ENV CARTODB_SQL_API_VERSION 3.0.0

COPY ./CartoDB-SQL-API /carto/CartoDB-SQL-API


# Git is used during npm install. We have to re-add the remote to the repo
# because it's installed in the multi-svc-cartodb repo as a submodule, and
# gets quite upset when you copy only the submodule into the container and
# try to work with it absent the parent repo. It stays checked out at the
# revision in the submodule when copied, this just reconnects it to its
# source repository so git functions normally.
RUN apt-get install -y git \
 && rm -rf /carto/CartoDB-SQL-API/.git \
 && cd /carto/CartoDB-SQL-API \
 && git init \
 && git remote add origin https://github.com/CartoDB/CartoDB-SQL-API.git

# These packages are needed in order to run the test suite for the app.
RUN apt-get install -y \
    postgresql-client-10 \
    curl 

# Something happens with this install such that you have to run it twice. The
# first run installs all the packages, but attempting to run the app after
# that results in "Error: Cannot find module 'pg'" being thrown by 
# internal/modules/cjs/loader.js. If you then run npm install *again*, it
# tells you that it:
#
#       updated 2 packages, moved 1 package and audited 927 packages
#
# Whatever that does apparently fixes the problem, so yay, double install.
RUN cd /carto/CartoDB-SQL-API && npm install && npm install

COPY ./config/*.js /carto/CartoDB-SQL-API/config/environments/
COPY ./test/*.sh /carto/CartoDB-SQL-API/test/
COPY ./docker-entrypoint.sh /carto/

ENTRYPOINT ["/bin/bash", "-c", "/carto/docker-entrypoint.sh"]
