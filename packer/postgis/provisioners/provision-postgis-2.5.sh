#!/bin/bash

#!/bin/bash
SCRIPT_NAME="provision-postgis-2.5.sh"

function output_message() {
    printf "**** PACKER PROVISIONER ($SCRIPT_NAME): "
    printf "$1"
    printf " ****\n"
}

output_message "Script starting"

export DEBIAN_FRONTEND="noninteractive"
export PG_MAJOR="${PG_MAJOR:-10}"
export PG_VERSION="${PG_VERSION:-10.10-1.pgdg90+1}"
export PYTHONDONTWRITEBYTECODE=1

export POSTGIS_MAJOR="2.5"
export POSTGIS_VERSION="2.5.2+dfsg-1~exp1.pgdg90+1"

output_message "Installing PostGIS packages"
apt-get -qq update
apt-get install -y --allow-unauthenticated --no-install-recommends \
    postgis=$POSTGIS_VERSION \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts=$POSTGIS_VERSION \
    postgresql-server-dev-$PG_MAJOR

output_message "Installing plpython and plproxy PG extensions"
apt-get install -y --allow-unauthenticated --no-install-recommends \
    postgresql-plpython-$PG_MAJOR \
    postgresql-$PG_MAJOR-plproxy

#### ADDING ENV VARIABLES TO PROFILE SCRIPT ##################################

output_message "Adding a profile script to add this script's export variables to the global env"

ENV_SCRIPT=/etc/profile.d/Z99_01_provision-postgis-2.5.sh
touch $ENV_SCRIPT
echo "export POSTGIS_MAJOR=\"${POSTGIS_MAJOR}\"" >> $ENV_SCRIPT
echo "export POSTGIS_VERSION=\"${POSTGIS_VERSION}\"" >> $ENV_SCRIPT
chmod 755 $ENV_SCRIPT

output_message "Script finished"
