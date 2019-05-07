#!/bin/bash

set -e

cd /carto/cartodb
echo "Updating config files with current IP of container..."
sed -i "s/127.0.0.1/$(hostname -i)/g" ./config/*.yml
echo "Starting the rails server process on $(hostname -i):3000..."
bundle exec rails server -b $(hostname -i) -d
bundle exec ./script/resque
