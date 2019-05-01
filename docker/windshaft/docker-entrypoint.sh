#!/bin/bash

set -e

cd /carto/Windshaft-cartodb
echo "Updating config files with current IP of container..."
sed -i "s/host: '127.0.0.1'/host: '$(hostname -i)'/" ./config/environments/*.js
#echo "Starting the node application..."
#node app.js development 
echo "Actually tailing /dev/null to keep container running."
tail -f /dev/null
