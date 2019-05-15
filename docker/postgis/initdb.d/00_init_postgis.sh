#!/bin/bash

set -e;

# Perform all actions as $POSTGRES_USER, or postgres if POSTGRES_USER unset
DB_USER="${POSTGRES_USER:-postgres}"
DB_NAME="template_postgis"
DB_CONN=" -U ${DB_USER} -d ${DB_NAME} "

# Create the 'template_postgis' template db and enable extensions
createdb -T template0 -O $DB_USER -E UTF8 $DB_NAME

EXTENSIONS="postgis postgis_topology fuzzystrmatch postgis_tiger_geocoder "
EXTENSIONS+="plpythonu"

for extension in $EXTENSIONS; do
    echo "Creating extension ${extension} in database ${DB_NAME}"
    psql $DB_CONN -c "CREATE EXTENSION IF NOT EXISTS ${extension};"
done
