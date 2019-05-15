#!/bin/bash

set -x

echo "Installing the cartodb-postgresql extension..."

cd /carto/cartodb-postgresql
make all install

set +x
echo "Completed install of cartodb-postgresql extension."

