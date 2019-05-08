FROM ubuntu:16.04 AS base

ENV PG_MAJOR 10
ENV CARTO_GIS_PPA_FINGERPRINT E54DBDF7355FE6DBEC654BAC6F44D37DD878D6C2
ENV BRIGHTBOX_RUBY_PPA_FINGERPRINT 80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6

# Install first party packages from Xenial repositories
RUN apt-get update \
 && apt-get -y install \
    software-properties-common \
    build-essential \
    pkg-config \
    locales \
    make \
    zip \
    git \
    wget \
    unp \
    python-dev \
    python-pip \
    libicu-dev \
    imagemagick \
    tzdata \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Add third party package indexes to the container
COPY ./sources.list.d/*.list /etc/apt/sources.list.d/

# Add the node 10 setup script
COPY ./setup_node_10.sh /carto/setup_node_10.sh

# Set up third party repositories, install packages from them
RUN apt-key adv --keyserver=keyserver.ubuntu.com --recv-keys $CARTO_GIS_PPA_FINGERPRINT \
 && apt-key adv --keyserver=keyserver.ubuntu.com --recv-keys $BRIGHTBOX_RUBY_PPA_FINGERPRINT \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && /bin/bash -c /carto/setup_node_10.sh \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    postgresql-server-dev-$PG_MAJOR \
    postgresql-client-$PG_MAJOR \
    gdal-bin \
    libgdal-dev \
    ruby2.4 \
    ruby2.4-dev \
    ruby-bundler \
    nodejs \
 && gem install compass

ENV CPLUS_INCLUDE_PATH /usr/include/gdal
ENV C_INCLUDE_PATH /usr/include/gdal
ENV PATH $PATH:/usr/include/gdal

WORKDIR /carto

COPY ./cartodb /carto/cartodb

# Make the cartodb source directory a real git repo instead of a headless
# submodule (which is what it is after direct copy out of our repo.
RUN rm -rf /carto/cartodb/.git \
 && cd /carto/cartodb \
 && git init \
 && git remote add origin https://github.com/CartoDB/cartodb.git

# Upgrade pip, install python packages, install node modules, install gems
RUN cd /carto/cartodb \
 && pip install setuptools \
 && pip install --no-binary :all: -r python_requirements.txt \
 && RAILS_ENV=development bundle install \
 && npm install

# Compile static assets, precompile assets
ENV PATH $PATH:/carto/cartodb/node_modules/grunt-cli/bin
RUN cd /carto/cartodb \
 && npm run carto-node \
 && npm run build:static \
 && bundle exec grunt --environment=development --force

COPY ./config/*.yml /carto/cartodb/config/

ENV RAILS_ENV development

COPY ./docker-entrypoint.sh /carto/

WORKDIR /carto/cartodb

ENTRYPOINT ["/carto/docker-entrypoint.sh"]

CMD []
