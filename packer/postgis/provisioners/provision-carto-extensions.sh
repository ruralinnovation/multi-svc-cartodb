#!/bin/bash

SCRIPT_NAME="provision-postgis-2.5.sh"

function output_message() {
    printf "**** PACKER PROVISIONER ($SCRIPT_NAME): "
    printf "$1"
    printf " ****\n"
}

output_message "Script starting"

export DEBIAN_FRONTEND="noninteractive"
export PYTHONDONTWRITEBYTECODE=1

apt-get -qq update

output_message "Installing build dependencies for Carto PG extensions"

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

output_message "Installing runtime dependencies for Carto PG extensions"
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

output_message "Cloning Carto PG extension repositories"
git clone --recursive ${CARTO_PGEXT_REPO}
git clone --recursive ${CARTO_DATASVCS_API_REPO}
git clone --recursive ${CARTO_DATASVCS_REPO}
git clone --recursive ${CARTO_ODBC_FDW_REPO}
git clone --recursive ${CARTO_CRANKSHAFT_REPO}
git clone --recursive ${CARTO_OBSERVATORY_REPO}

#### ODBC_FDW ################################################################
ODBC_FDW_VERSION="${ODBC_FDW_VERSION:-master}"
output_message "Installing ODBC FDW version ${ODBC_FDW_VERSION}"

cd /carto/odbc_fdw
git checkout ${ODBC_FDW_VERSION}
git submodule update --recursive
make install

#### CRANKSHAFT ##############################################################
CRANKSHAFT_VERSION="${CRANKSHAFT_VERSION:-master}"
output_message "Installing crankshaft version ${CRANKSHAFT_VERSION}"

cd /carto/crankshaft
git checkout $CRANKSHAFT_VERSION
make install
pip install --force-reinstall --no-cache-dir scikit-learn==0.17.0

#### CARTODB PG EXTENSION ####################################################
PGEXT_VERSION="${PGEXT_VERSION:-master}"
output_message "Installing cartodb-postgresql extension version ${PGEXT_VERSION}"

cd /carto/cartodb-postgresql
git checkout ${PGEXT_VERSION}
PGUSER=postgres make install

#### DATASERVICES ############################################################
DATASERVICES_VERSION="${DATASERVICES_VERSION:-master}"
output_message "Installing Data Services PG Extension version $DATASERVICES_VERSION"

cd /carto/data-services/geocoder/extension
git checkout $DATASERVICES_VERSION
PGUSER=postgres make all install

#### DATASERVICES API SERVER #################################################
DATASERVICES_API_SERVER_VERSION="${DATASERVICES_API_SERVER_VERSION:-master}"
output_message "Installing Data Services API Server extension version $DATASERVICES_API_SERVER_VERSION"

cd /carto/dataservices-api/server/extension
git checkout $DATASERVICES_API_SERVER_VERSION
PGUSER=postgres make install

# Install Python requirements
cd /carto/dataservices-api/server/lib/python/cartodb_services
pip install -r requirements.txt
pip install .

#### DATASERVICES API CLIENT #################################################
DATASERVICES_API_CLIENT_VERSION="${DATASERVICES_API_CLIENT_VERSION:-master}"
output_message "Installing Data Services API Client extension version $DATASERVICES_API_CLIENT_VERSION"

cd /carto/dataservices-api/client
git checkout $DATASERVICES_API_CLIENT_VERSION
PGUSER=postgres make install

#### OBSERVATORY #############################################################
OBSERVATORY_VERSION="${OBSERVATORY_VERSION:-master}"
output_message "Installing Observatory extension, version $OBSERVATORY_VERSION"

cd /carto/observatory-extension
git checkout $OBSERVATORY_VERSION
PGUSER=postgres make install
cd /usr/share/postgresql/10/extension
if [[ -f ./observatory--dev.sql ]]; then
    cp ./observatory--dev.sql ./observatory--current--1.9.0.sql
fi

output_message "Script finished"
