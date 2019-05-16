#!/bin/bash

set -e

echo "Starting the Windshaft node application..."
exec node app -c config/environments/development.js
#echo "Tailing the windshaft logs"
#tail -f /carto/Windshaft-cartodb/logs/node-windshaft.log
