#!/bin/bash

while :
do
    sleep $SYNC_TABLES_INTERVAL
    bundle exec rake cartodb:sync_tables[true]
done
