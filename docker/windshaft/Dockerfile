FROM ubuntu:16.04 AS base

WORKDIR /carto

ENV PG_MAJOR 10                                                                 
ENV CARTO_GIS_PPA_FINGERPRINT E54DBDF7355FE6DBEC654BAC6F44D37DD878D6C2

COPY ./sources.list.d/*.list /etc/apt/sources.list.d/
COPY ./setup_node_10.sh /carto/setup_node_10.sh

RUN apt-get update \
 && apt-get -y install \
    software-properties-common \
    build-essential \
    pkg-config \
    locales \
    make \
    git \
    wget \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg8-dev \
    libgif-dev \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
 && apt-key adv --keyserver=keyserver.ubuntu.com --recv-keys $CARTO_GIS_PPA_FINGERPRINT \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    postgresql-server-dev-$PG_MAJOR \
 && /bin/bash -c /carto/setup_node_10.sh \
 && apt-get update \
 && apt-get install -y nodejs

COPY ./Windshaft-cartodb /carto/Windshaft-cartodb

# Git is used during npm install. We have to re-add the remote to the repo
# because it's installed in the multi-svc-cartodb repo as a submodule, and
# gets quite upset when you copy only the submodule into the container and
# try to work with it absent the parent repo. It stays checked out at the
# revision in the submodule when copied, this just reconnects it to its
# source repository so git functions normally.
RUN rm -rf /carto/Windshaft-cartodb/.git \
 && cd /carto/Windshaft-cartodb \
 && git init \
 && git remote add origin https://github.com/CartoDB/Windshaft-cartodb.git \
 && mkdir logs \
 && npm install

# Tests need curl, psql, and redis-cli
RUN apt-get -y install \
    curl \
    postgresql-client-$PG_MAJOR \
 && cd /tmp \
 && wget http://download.redis.io/redis-stable.tar.gz \
 && tar xzvf redis-stable.tar.gz \
 && cd redis-stable \
 && make \
 && cp src/redis-cli /usr/local/bin/ \
 && chmod 755 /usr/local/bin/redis-cli \
 && rm -rf /tmp/redis-stable


COPY ./docker-entrypoint.sh /carto/
COPY ./config/*.js /carto/Windshaft-cartodb/config/environments/
COPY ./test/*.sh /carto/Windshaft-cartodb/test/

WORKDIR /carto/Windshaft-cartodb

EXPOSE 8181

ENTRYPOINT ["/bin/bash", "-c", "/carto/docker-entrypoint.sh"]
