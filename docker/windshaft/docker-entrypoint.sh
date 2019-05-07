#!/bin/bash

set -e

cd /carto/Windshaft-cartodb
echo "Updating config files with current IP of container..."
sed -i "s/127.0.0.1/$(hostname -i)/" ./config/environments/*.js
echo "Starting the node application..."
node app.js development 
