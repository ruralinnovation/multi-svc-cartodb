#!/bin/bash

DB_USER="${POSTGRES_USER:-postgres}"
DB_CONN=" -U ${DB_USER} "

ROLES="publicuser tileuser"

for role in $ROLES; do
    createuser $DB_CONN $role --no-createrole --no-createdb --no-superuser
done
