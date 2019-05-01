FROM ubuntu:16.04 AS base

RUN apt-get update \
 && apt-get -y install \
    software-properties-common \
    build-essential \
    pkg-config \
    locales \
    make \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg8-dev \
    libgif-dev \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

WORKDIR /carto

COPY ./setup_node_10.sh /carto/setup_node_10.sh

RUN /bin/bash -c /carto/setup_node_10.sh \
 && apt-get update \
 && apt-get install -y nodejs

COPY ./Windshaft-cartodb /carto/Windshaft-cartodb
COPY ./config/*.js /carto/Windshaft-cartodb/config/environments/

# Git is used during npm install. We have to re-add the remote to the repo
# because it's installed in the multi-svc-cartodb repo as a submodule, and
# gets quite upset when you copy only the submodule into the container and
# try to work with it absent the parent repo. It stays checked out at the
# revision in the submodule when copied, this just reconnects it to its
# source repository so git functions normally.
RUN apt-get install -y git \
 && rm -rf /carto/Windshaft-cartodb/.git \
 && cd /carto/Windshaft-cartodb \
 && git init \
 && git remote add origin https://github.com/CartoDB/Windshaft-cartodb.git \
 && mkdir logs \
 && npm install

#COPY ./test/*.sh /carto/Windshaft-cartodb/test/
#COPY ./docker-entrypoint.sh /carto/

#ENTRYPOINT ["/bin/bash", "-c", "/carto/docker-entrypoint.sh"]
