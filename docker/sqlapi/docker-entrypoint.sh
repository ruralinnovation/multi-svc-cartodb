#!/bin/bash

set -e

cd /carto/CartoDB-SQL-API
echo "Updating config files with current IP of container..."
sed -i "s/^[[:space:]]*\(module.exports.node_host\)[[:space:]]*=[[:space:]]*['\"]127.0.0.1[\"'][[:space:]]*;/\1 = '$(hostname -i)';/" ./config/environments/*.js
echo "Starting the node application..."
node app.js development 
