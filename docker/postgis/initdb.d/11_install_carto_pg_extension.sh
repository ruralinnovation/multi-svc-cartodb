#!/bin/bash


echo "Installing the cartodb-postgresql extension..."
cd /carto/cartodb-postgresql
make all install > /dev/null 2>&1
echo "Completed install of cartodb-postgresql extension."

