#!/bin/bash

set -e;

# Perform all actions as $POSTGRES_USER, or postgres if POSTGRES_USER unset
export PGUSER="${POSTGRES_USER:-postgres}"

# Create the 'template_postgis' template db and enable extensions
createdb -T template0 -O $PGUSER -E UTF8 template_postgis

psql --dbname template_postgis -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
psql --dbname template_postgis -c 'CREATE EXTENSION IF NOT EXISTS postgis_topology;'
psql --dbname template_postgis -c 'CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;'
psql --dbname template_postgis -c 'CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;'
psql --dbname template_postgis -c 'CREATE EXTENSION IF NOT EXISTS plpythonu;'
