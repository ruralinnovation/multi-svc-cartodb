#!/bin/bash

DB_USER=postgres
DB_HOST=localhost
DB_CONN=" -U $DB_USER -h $DB_HOST "
DB_NAME="dataservices_db"

#psql $DB_CONN -c "CREATE DATABASE ${DB_NAME} ENCODING='UTF-8' LC_COLLATE='en_US.utf8' LC_CTYPE='en_US.utf8';"
#createuser $DB_CONN "geocoder_api"
#DB_CONN+="-d $DB_NAME "
#psql $DB_CONN -c "BEGIN;CREATE EXTENSION IF NOT EXISTS plproxy; COMMIT" -e
#psql $DB_CONN -c "BEGIN;CREATE EXTENSION IF NOT EXISTS cdb_dataservices_server;COMMIT;" -e
