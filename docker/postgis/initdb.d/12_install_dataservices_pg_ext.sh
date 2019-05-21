#!/bin/bash

DB_USER=postgres
DB_CONN=" -U $DB_USER "
DB_NAME="dataservices_db"

echo "Creating the ${DB_NAME} database"
psql $DB_CONN -c "CREATE DATABASE ${DB_NAME} ENCODING='UTF-8' LC_COLLATE='en_US.utf8' LC_CTYPE='en_US.utf8' TEMPLATE=template_postgis;"

echo "Creating the geocoder_api user"
createuser $DB_CONN "geocoder_api"
DB_CONN+="-d $DB_NAME "

EXTENSIONS="plproxy plpythonu postgis cartodb cdb_geocoder cdb_dataservices_server"

for extension in $EXTENSIONS; do
    echo "Installing the $extension into $DB_NAME"
    psql $DB_CONN -c "BEGIN;CREATE EXTENSION IF NOT EXISTS $extension;COMMIT;" -e
done

# Need to set config values in the database
# See https://github.com/CartoDB/dataservices-api#server-configuration

psql $DB_CONN -c "SELECT CDB_Conf_SetConf('redis_metadata_config', '{\"redis_host\": \"redis\", \"redis_port\": 6379, \"sentinel_master_id\": \"\", \"timeout\": 0.1, \"redis_db\": 5}');" -e
psql $DB_CONN -c "SELECT CDB_Conf_SetConf('redis_metrics_config', '{\"redis_host\": \"redis\", \"redis_port\": 6379, \"sentinel_master_id\": \"\", \"timeout\": 0.1, \"redis_db\": 5}');" -e
psql $DB_CONN -c "SELECT CDB_Conf_SetConf('user_config', '{\"is_organization\": false, \"entity_name\": \"nick\"}');" -e
psql $DB_CONN -c "SELECT CDB_Conf_SetConf('server_conf', '{\"environment\": \"development\"}');" -e
psql $DB_CONN -c "SELECT CDB_Conf_SetConf('heremaps_conf', '{\"geocoder\": {\"app_id\": \"here_geocoder_app_id\", \"app_code\": \"here_geocoder_app_code\", \"geocoder_cost_per_hit\": \"1\"}, \"isolines\" : {\"app_id\": \"here_isolines_app_id\", \"app_code\": \"here_geocoder_app_code\"}}');" -e 
