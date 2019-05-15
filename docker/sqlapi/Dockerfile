FROM ubuntu:16.04 AS base

ENV PG_MAJOR 10
ENV CARTO_GIS_PPA_FINGERPRINT E54DBDF7355FE6DBEC654BAC6F44D37DD878D6C2

WORKDIR /carto

COPY ./setup_node_10.sh /carto/setup_node_10.sh
COPY ./dpkg_no_docs /etc/dpkg/dpkg.cfg.d/01_nodocs

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    software-properties-common \
    wget \
 && add-apt-repository ppa:cartodb/gis \
 && echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && /bin/bash -c /carto/setup_node_10.sh \
 && apt-get update \
 && apt-get -y install \
    build-essential \
    pkg-config \
    locales \
    make \
    zip \
    git \
    postgresql-server-dev-$PG_MAJOR \
    postgresql-client-10 \
    curl \
    gdal-bin \
    libgdal-dev \
    nodejs \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
 && cd /tmp \
 && wget http://download.redis.io/redis-stable.tar.gz \
 && tar xzvf redis-stable.tar.gz \
 && cd redis-stable \
 && make \
 && cp src/redis-cli /usr/local/bin/ \
 && chmod 755 /usr/local/bin/redis-cli \
 && rm -rf /tmp/redis-stable \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get remove -y curl wget

COPY ./CartoDB-SQL-API /carto/CartoDB-SQL-API

RUN rm -rf /carto/CartoDB-SQL-API/.git \
 && cd /carto/CartoDB-SQL-API \
 && git init \
 && git remote add origin https://github.com/CartoDB/CartoDB-SQL-API.git

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

WORKDIR /carto/CartoDB-SQL-API

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "-c", "/carto/docker-entrypoint.sh"]

CMD []
