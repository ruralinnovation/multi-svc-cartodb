#!/bin/bash
SCRIPT_NAME="provision-pg-10.sh"

function output_message() {
    printf "**** PACKER PROVISIONER ($SCRIPT_NAME): "
    printf "$1"
    printf " ****\n"
}

output_message "Script starting"

export DEBIAN_FRONTEND="noninteractive"
export PG_MAJOR="10"
export PG_VERSION="10.10-1.pgdg90+1"
export PYTHONDONTWRITEBYTECODE=1

DPKG_ARCH="$(dpkg --print-architecture)"

#### INSTALL INITIAL DEPENDENCIES ############################################

output_message "Installing initial dependencies"

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

output_message "Creating the postgres user and group, home dir /var/lib/postgresql"

groupadd -r postgres --gid=999
useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql \
    --shell=/bin/bash postgres
mkdir -p /var/lib/postgresql
chown -R postgres:postgres /var/lib/postgresql

#### INSTALL GOSU ############################################################

output_message "Installing gosu for privilege management"

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

output_message "Installing and configuring locale"

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

output_message "Installing PostgreSQL packages from the Postgres APT repo"

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

output_message "Configuring installed PostgreSQL packages"

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

#### ADDING ENV VARIABLES TO PROFILE SCRIPT ##################################

output_message "Adding a profile script to add this script's export variables to the global env"

ENV_SCRIPT=/etc/profile.d/Z99_01_provision-pg-10.sh
touch $ENV_SCRIPT
echo "export LANG=\"${LANG}\"" >> $ENV_SCRIPT
echo "export PATH=\"${PATH}\"" >> $ENV_SCRIPT
echo "export PGDATA=\"${PGDATA}\"" >> $ENV_SCRIPT
echo "export PG_MAJOR=\"${PG_MAJOR}\"" >> $ENV_SCRIPT
echo "export PG_VERSION=\"${PG_VERSION}\"" >> $ENV_SCRIPT
chmod 755 $ENV_SCRIPT

output_message "Script finished"
