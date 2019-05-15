#!/bin/bash

DB_USER=postgres
DB_CONN=" -U $DB_USER "
DB_NAME="dataservices_db"

echo "Creating the ${DB_NAME} database"
psql $DB_CONN -c "CREATE DATABASE ${DB_NAME} ENCODING='UTF-8' LC_COLLATE='en_US.utf8' LC_CTYPE='en_US.utf8' TEMPLATE=template_postgis;"

echo "Creating the geocoder_api user"
createuser $DB_CONN "geocoder_api"
DB_CONN+="-d $DB_NAME "

EXTENSIONS="plproxy plpythonu postgis cartodb cdb_geocoder cdb_dataservices_server"

for extension in $EXTENSIONS; do
    echo "Installing the $extension into $DB_NAME"
    psql $DB_CONN -c "BEGIN;CREATE EXTENSION IF NOT EXISTS $extension;COMMIT;" -e
done
