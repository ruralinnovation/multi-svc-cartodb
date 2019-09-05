#!/bin/bash

CONFIG_FILE="config/environments/${CARTO_ENV}.js"
set -e

echo "Starting the Windshaft node application..."
exec node app -c $CONFIG_FILE
