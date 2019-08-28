#!/bin/bash

##############################################################################
# 
# PostgreSQL portion of the provisioning script. This section is adapted from
# the Dockerfile of the `postgres:10` official Docker hub image, and is meant
# to provision a base Debian stretch box to reach a state similar to the image
# created by that Dockerfile. 
#
##############################################################################

export DEBIAN_FRONTEND="noninteractive"
export PG_MAJOR="10"
export PG_VERSION="10.10-1.pgdg90+1"
export PYTHONDONTWRITEBYTECODE=1

DPKG_ARCH="$(dpkg --print-architecture)"

#### INSTALL INITIAL DEPENDENCIES ############################################

# Need to disable ipv6 for dirmngr in order to successfully add PG apt repo
# key via gpg. See this issue comment for context
#
#   https://github.com/inversepath/usbarmory-debian-base_image/issues/9#issuecomment-451635505
#
echo "disable-ipv6" >> ~/dirmngr.conf

apt-get update
apt-get install -y apt-utils
apt-get install -y --no-install-recommends \
    gnupg \
    dirmngr \
    ca-certificates \
    wget

rm -rf "$GNUPGHOME"

#### CREATE POSTGRES USER/GROUP ##############################################

groupadd -r postgres --gid=999
useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql \
    --shell=/bin/bash postgres
mkdir -p /var/lib/postgresql
chown -R postgres:postgres /var/lib/postgresql

#### INSTALL GOSU ############################################################

export GOSU_VERSION=1.11
export GNUPGHOME="$(mktemp -d)"
GOSU_KEY="B42F6819007F00F88E364FD4036A9C25BF357DD4"
GOSU_GH_URL="https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/"

# Retrieve binary and keyfile for gosu
wget -O /usr/local/bin/gosu "${GOSU_GH_URL}gosu-${DPKG_ARCH}"
wget -O /usr/local/bin/gosu.asc "${GOSU_GH_URL}gosu-${DPKG_ARCH}.asc"

# Verify binary using keyfile, then discard keyfile
gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys $GOSU_KEY
gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu
{ command -v gpgconf > /dev/null && gpgconf --kill all || :; }
rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc
chmod +x /usr/local/bin/gosu

gosu nobody true

#### INSTALL AND CONFIGURE LOCALE ############################################

# Create the en_US.UTF-8 locale so postgres will be utf-8 enabled by default
if [ -f /etc/dpkg/dpkg.cfg.d/docker ]; then
    # If this file exists we're probably in Docker, in debian:xxx-slim, and
    # locales are therefore excluded--so we need to remove the exclusion
    # so we can use locales.
    grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker
    sed -ri '/\/usr\/share\/locale/d' /etc/dpkg/dpkg.cfg.d/docker
    ! grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker
fi

# Install locales and generate the en_US.UTF-8 locale
apt-get install -y -q locales
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

export LANG="en_US.utf8"

#### INSTALL AND CONFIGURE POSTGRES PACKAGES #################################
# Note 2019-08-08: It appears that there's a problem with the public key
# for the Postgres Debian repo? It has multiple expiration dates, at least
# one of which should still be valid, but gpg is for whatever reason refusing
# to consider it authenticated properly. For now my solution is to use the
# --allow-unauthenticated flag for the packages in that repo. 
#
# Leaving the authentication logic in place so it can be amended if possible.

PG_DEB_KEY='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'
PG_APT_REPO="http://apt.postgresql.org/pub/repos/apt/"
PG_APT_FILE="/etc/apt/sources.list.d/pgdg.list"

# Retrieve and use key to auth PostgreSQL Debian repository
export GNUPGHOME="$(mktemp -d)"
gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$PG_DEB_KEY"
gpg --batch --export "$PG_DEB_KEY" > /etc/apt/trusted.gpg.d/postgres.gpg
command -v gpgconf > /dev/null && gpgconf --kill all
rm -rf "$GNUPGHOME"
apt-key list

echo "deb ${PG_APT_REPO} stretch-pgdg main $PG_MAJOR" > $PG_APT_FILE
apt-get update

apt-get install -y --allow-unauthenticated postgresql-common
PG_CREATE_CLUSTER_FILE="/etc/postgresql-common/createcluster.conf"
sed -ri 's/#(create_main_cluster) .*$/\1 = false/' $PG_CREATE_CLUSTER_FILE
apt-get install -y --allow-unauthenticated "postgresql-$PG_MAJOR=$PG_VERSION"

# Manually purge .pyc files not owned by a package.
PURGE_CMD='for pyc; do dpkg -S "$pyc" &> /dev/null || rm -vf "$pyc"; done'
find /usr -name '*.pyc' -type f -exec bash -c "$PURGE_CMD" -- '{}' +

# make the sample config easier to munge (and "correct by default")
mkdir -p "/usr/share/postgresql/${PG_MAJOR}"

dpkg-divert --add --rename --divert "/usr/share/postgresql/postgresql.conf.sample.dpkg" "/usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample"

cp -v /usr/share/postgresql/postgresql.conf.sample.dpkg /usr/share/postgresql/postgresql.conf.sample

ln -sv ../postgresql.conf.sample "/usr/share/postgresql/$PG_MAJOR/"

sed -ri "s/^#?(listen_addresses)\s*=\s*\S+.*/\1 = '*'/" /usr/share/postgresql/postgresql.conf.sample

mkdir -p /var/run/postgresql
chown -R postgres:postgres /var/run/postgresql
chmod 2777 /var/run/postgresql

mkdir -p /pg-initdb.d

export PATH="${PATH}:/usr/lib/postgresql/$PG_MAJOR/bin"
export PGDATA="${PGDATA:-/var/lib/postgresql/data}"
# this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"

##############################################################################
#
# PostGIS section of the provisioning script. This is an adaptation of the
# commands in the Dockerfile we used previous to switching the build to 
# Packer (so that a Docker image and an AWS AMI could be built from the same
# base, since we'll have to run this as an EC2 instance). It installs both
# the PostGIS packages and their relevant dependencies, as well as a number
# of custom PostgreSQL extensions created by CARTO.
#
##############################################################################

export POSTGIS_MAJOR="2.5"
export POSTGIS_VERSION="2.5.2+dfsg-1~exp1.pgdg90+1"

echo "Installing PostgreSQL/PostGIS..."
apt-get -qq update
apt-get install -y --allow-unauthenticated --no-install-recommends \
    postgis=$POSTGIS_VERSION \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts=$POSTGIS_VERSION \
    postgresql-server-dev-$PG_MAJOR

echo "Installing plpython and plproxy PG extensions..."
apt-get install -y --allow-unauthenticated --no-install-recommends \
    postgresql-plpython-$PG_MAJOR \
    postgresql-$PG_MAJOR-plproxy

echo "Installing build dependencies for Carto PG extensions..."
apt-get install -y --allow-unauthenticated --no-install-recommends \
    make \
    git \
    build-essential \
    ruby \
    python-pip \
    python-dev \
    python-setuptools \
    python-wheel \
    unixodbc-dev

echo "Installing runtime dependencies for PG extensions..."
apt-get install -y --allow-unauthenticated odbc-postgresql

export CARTO_PGEXT_REPO="https://github.com/CartoDB/cartodb-postgresql.git"
export CARTO_DATASVCS_API_REPO="https://github.com/CartoDB/dataservices-api.git"
export CARTO_DATASVCS_REPO="https://github.com/CartoDB/data-services.git"
export CARTO_ODBC_FDW_REPO="https://github.com/CartoDB/odbc_fdw.git"
export CARTO_CRANKSHAFT_REPO="https://github.com/CartoDB/crankshaft.git"
export CARTO_OBSERVATORY_REPO="https://github.com/CartoDB/observatory-extension.git"

mkdir -p /carto && cd $_

# Suppress "You are in detached HEAD..." warnings
git config --global advice.detachedHead false

echo "Cloning PG extension repositories into /carto..."
git clone --recursive ${CARTO_PGEXT_REPO}
git clone --recursive ${CARTO_DATASVCS_API_REPO}
git clone --recursive ${CARTO_DATASVCS_REPO}
git clone --recursive ${CARTO_ODBC_FDW_REPO}
git clone --recursive ${CARTO_CRANKSHAFT_REPO}
git clone --recursive ${CARTO_OBSERVATORY_REPO}

echo "Installing cartodb-postgresql extension v${CARTO_PGEXT_VERSION}..."
cd /carto/cartodb-postgresql
git checkout ${CARTO_PGEXT_VERSION}
git submodule update --recursive
make install

echo "Installing dataservices-api client extension v${CARTO_DATASVCS_API_CLIENT_VERSION}..."
cd /carto/dataservices-api
git checkout ${CARTO_DATASVCS_API_CLIENT_VERSION}
git submodule update --recursive
cd /carto/dataservices-api/client
make install

echo "Installing dataservices-api server extension v${CARTO_DATASVCS_API_SERVER_VERSION}..."
cd /carto/dataservices-api
git checkout ${CARTO_DATASVCS_API_SERVER_VERSION}
git submodule update --recursive
cd /carto/dataservices-api/server/extension
make install
cd /carto/dataservices-api/server/lib/python/cartodb_services
pip install --no-cache-dir -r requirements.txt
pip install . --upgrade --no-cache-dir

echo "Installing data-services extension v${CARTO_DATASVCS_VERSION}..."
cd /carto/data-services
git checkout ${CARTO_DATASVCS_VERSION}
git submodule update --recursive
cd /carto/data-services/geocoder/extension
make install

echo "Installing odbc_fdw extension v${CARTO_ODBC_FDW_VERSION}..."
cd /carto/odbc_fdw
git checkout ${CARTO_ODBC_FDW_VERSION}
git submodule update --recursive
make install

echo "Installing crankshaft extension v${CARTO_CRANKSHAFT_VERSION}..."
cd /carto/crankshaft
git checkout ${CARTO_CRANKSHAFT_VERSION}
git submodule update --recursive
make install

echo "Installing observatory extension v${CARTO_OBSERVATORY_VERSION}..."
cd /carto/observatory-extension
git checkout ${CARTO_OBSERVATORY_VERSION}
git submodule update --recursive
make install
cd /usr/share/postgresql/10/extension
cp ./observatory--dev.sql ./observatory--current--1.9.0.sql

echo "Chowning the extensions directory to postgres..."
chmod 777 /usr/share/doc
chown -R postgres:postgres /usr/share/postgresql
