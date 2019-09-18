#!/bin/bash
SCRIPT_NAME="provision-pgbouncer-1.10.sh"

function output_message() {
    printf "**** PACKER PROVISIONER ($SCRIPT_NAME): "
    printf "$1"
    printf " ****\n"
}

output_message "Script starting"

export DEBIAN_FRONTEND="noninteractive"
PGB_VERSION="1.10.0"

#### INSTALL INITIAL DEPENDENCIES ############################################

output_message "Installing initial dependencies"

apt-get update
apt-get install -y --no-install-recommends \
    make \
    build-essential \
    software-properties-common \
    pkg-config \
    openssl \
    libevent-dev

#### INSTALL PGBOUNCER #######################################################

cd /opt
wget https://pgbouncer.github.io/downloads/files/${PGB_VERSION}/pgbouncer-${PGB_VERSION}.tar.gz
tar -zxf pgbouncer-${PGB_VERSION}.tar.gz
ln -s pgbouncer-${PGB_VERSION} pgbouncer
cd pgbouncer
./configure --prefix=/opt/pgbouncer
make
make install
cd /opt
rm -rf pgbouncer-${PGB_VERSION}.tar.gz

output_message "Script finished"
