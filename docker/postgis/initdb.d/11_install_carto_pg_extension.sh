#!/bin/bash

set -ex;

cd /carto/cartodb-postgresql
make all install
psql -U postgres -d template_postgis -c 'CREATE EXTENSION cartodb;'
