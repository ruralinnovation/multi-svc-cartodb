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

# Git is used during npm install
RUN apt-get install -y git \
 && rm -rf /carto/CartoDB-SQL-API/.git \
 && cd /carto/CartoDB-SQL-API \
 && git init \
 && git remote add origin https://github.com/CartoDB/CartoDB-SQL-API.git \
 && npm install

COPY ./config/*.js /carto/CartoDB-SQL-API/config/environments/

#COPY 
