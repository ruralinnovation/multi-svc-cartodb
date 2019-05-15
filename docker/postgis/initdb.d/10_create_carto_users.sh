#!/bin/bash

DB_USER="${POSTGRES_USER:-postgres}"
DB_HOST="localhost"
DB_CONN=" -U ${DB_USER} -h ${DB_HOST} "

createuser $DB_CONN publicuser --no-createrole --no-createdb --no-superuser
createuser $DB_CONN tileuser --no-createrole --no-createdb --no-superuser
