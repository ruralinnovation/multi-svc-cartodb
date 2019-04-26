#!/bin/bash

set -ex;

export PGUSER="${POSTGRES_USER:-postgres}"

createuser publicuser --no-createrole --no-createdb --no-superuser
createuser tileuser --no-createrole --no-createdb --no-superuser
