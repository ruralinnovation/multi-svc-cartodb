#!/bin/bash

set -e

echo "Starting the SQLAPI node application..."
exec node app -c config/environments/development.js
