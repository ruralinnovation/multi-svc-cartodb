FROM ubuntu:18.04 AS base

FROM base AS cartobuilder

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update \
 && echo "Configuring locales..." \
 && apt-get install -y -q --no-install-recommends \
    apt-utils \
    software-properties-common \
    locales \
 && dpkg-reconfigure locales \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get -qq update \
 && echo "Installing build tools..." \
 && apt-get install -y -q --no-install-recommends \
    build-essential \
    autoconf \
    automake \
    libtool \
    checkinstall \
    ca-certificates \
    pkg-config \
    gnupg \
    net-tools \
    bison \
 && echo "Installing compression tools..." \
 && apt-get install -y -q --no-install-recommends \
    unp \
    zip \
    unzip \
    xz-utils \
    zlib1g \
 && echo "Installing network and version control tools..." \
 && apt-get install -y -q --no-install-recommends \
    git-core \
    git \
    subversion \
    curl \
    wget \
    openssl \
    libcrypto++-dev \
    libssl1.0.0 \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get -qq update \
 && echo "Installing development libraries..." \
 && apt-get install -y -q --no-install-recommends \
    libreadline7 \
    libgeos-dev \
    libgeos-c1v5 \
    libjson-c-dev \
    libproj-dev \
    libgdal-dev \
    postgresql-server-dev-10 \
    python2.7-dev \
    libmapnik-dev \
    python-all-dev \
    zlib1g-dev \
    libssl-dev \
    libyaml-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxslt-dev \
    libc6-dev \
    ncurses-dev \
    libpq-dev \
    libcurl4-gnutls-dev \
    libffi-dev \
    libgdbm-dev \
    libreadline6-dev \
    libcairo2-dev \
    libjpeg8-dev \
    libpango1.0-dev \
    libgif-dev \
    libgmp-dev \
    libicu-dev \
    ruby2.5-dev \
 && rm -rf /var/lib/apt/lists/*
    

RUN apt-get -qq update \
 && echo "Installing programming languages and dependencies..." \
 && apt-get install -y -q --no-install-recommends \
    ruby2.5 \
    python-simplejson \
    python-setuptools \
    python-mapnik \
    python-argparse \
    python-gdal \
    python-chardet \
    python-docutils \
    python-pip \
 && echo "Installing additional third party packages..." \
 && apt-get install -y -q --no-install-recommends \
    nginx-light \
    imagemagick \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get -qq update \
 && echo "Installing geospatial packages..." \
 && apt-get install -y -q --no-install-recommends \
    proj-bin \
    proj-data \
    gdal-bin \
    mapnik-utils \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get -qq update \
 && echo "Installing database packages..." \
 && apt-get install -y -q --no-install-recommends \
    libpq5 \
    postgresql-10 \
    postgresql-client-10 \
    postgresql-contrib-10 \
    postgresql-plpython-10 \
    postgresql-10-plproxy \
    postgresql-10-postgis-2.4 \
    postgresql-10-postgis-scripts \
    postgis \
    liblwgeom-2.4-0 \
    redis-server \
    sqlite3 \
 && rm -rf /var/lib/apt/lists/*

ARG GIT_USER_EMAIL="you@example.com"
ARG GIT_USER_NAME="Your Name"

RUN git config --global user.email $GIT_USER_EMAIL \
  && git config --global user.name $GIT_USER_NAME \
  && curl https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-x64.tar.xz |tar -Jxf - --strip-components=1 -C /usr \
  && npm install -g grunt-cli \
  && npm install -g npm@6 \
  && npm install -g yarn \
  && rm -r /tmp/npm-* /root/.npm
