#!/bin/bash

DB_USER="${POSTGRES_USER:-postgres}"

#### CREATE ROLES ############################################################

createuser -U $DB_USER publicuser --no-createrole --no-createdb --no-superuser
createuser -U $DB_USER tileuser --no-createrole --no-createdb --no-superuser

#### GLOBALLY INSTALL plpythonu EXTENSION ###################################

psql -U $DB_USER -c "CREATE EXTENSION plpythonu;"

#### CREATE TEMPLATE DATABASE ################################################

TEMPLATE_DB="template_postgis"

createdb -U $DB_USER -T template0 -O $DB_USER -E UTF8 $TEMPLATE_DB
psql -U $DB_USER -d $TEMPLATE_DB -c "CREATE OR REPLACE LANGUAGE plpgsql;" -e

cat <<EOF | psql -U $DB_USER -d postgres
UPDATE pg_database
SET datistemplate='true'
WHERE datname='template_postgis';
EOF

#### INSTALL POSTGRES EXTENSIONS TO TEMPLATE DB ##############################

cat <<EOF | psql -U $DB_USER -d $TEMPLATE_DB -e
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION plpythonu;
CREATE EXTENSION plproxy;
CREATE EXTENSION crankshaft VERSION 'dev';
GRANT ALL ON geometry_columns TO PUBLIC;
GRANT ALL ON spatial_ref_sys TO PUBLIC;
EOF

#### CREATE GEOCODER DATABASE ################################################

# NOTE: These values MUST match those given in cartodb's app_config.yml,
#       for the keys geocoder.api.dbname and geocoder.api.user.
# TODO: Make these environment sourced both here and in app_config.yml.
GEOCODER_DB="dataservices_db"
GEOCODER_USER="geocoder_api"

createuser -U $DB_USER $GEOCODER_USER

createdb -U $DB_USER -T template_postgis -E UTF8 \
    --lc-collate='en_US.utf8' --lc-ctype='en_US.utf8' $GEOCODER_DB

cat <<EOF | psql -U $DB_USER -d $GEOCODER_DB -e
CREATE EXTENSION IF NOT EXISTS plproxy;
CREATE EXTENSION IF NOT EXISTS plpythonu;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS cartodb;
CREATE EXTENSION IF NOT EXISTS cdb_geocoder;
CREATE EXTENSION IF NOT EXISTS cdb_dataservices_server;
CREATE EXTENSION IF NOT EXISTS cdb_dataservices_client;
CREATE EXTENSION IF NOT EXISTS observatory VERSION 'dev';
EOF

psql -qt -U $DB_USER -d $GEOCODER_DB -f /carto/observatory-extension/src/pg/test/fixtures/load_fixtures.sql

# The 'observatory' schema doesn't exist until the load_fixtures.sql file is run.
cat <<EOF | psql -U $DB_USER -d $GEOCODER_DB -e
GRANT SELECT ON ALL TABLES IN SCHEMA cdb_observatory TO ${GEOCODER_USER};
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA cdb_observatory TO ${GEOCODER_USER};
GRANT USAGE ON SCHEMA cdb_observatory TO ${GEOCODER_USER};
GRANT SELECT ON ALL TABLES IN SCHEMA observatory TO ${GEOCODER_USER};
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA observatory TO ${GEOCODER_USER};
GRANT USAGE ON SCHEMA observatory TO ${GEOCODER_USER};
EOF

#### CONFIGURATION VALUES FOR GEOCODER DATABASE ##############################
#
# See https://github.com/CartoDB/dataservices-api#local-install-instructions
#

cat <<EOF | psql -U $DB_USER -d $GEOCODER_DB -e
SELECT cartodb.CDB_Conf_SetConf(
  'redis_metadata_config',
  '{"redis_host": "redis",
    "redis_port": 6379,
    "sentinel_master_id": "",
    "timeout": 0.1,
    "redis_db": 5}'
);
EOF

cat <<EOF | psql -U $DB_USER -d $GEOCODER_DB -e
SELECT cartodb.CDB_Conf_SetConf(
  'redis_metrics_config',
  '{"redis_host": "redis",
    "redis_port": 6379,
    "sentinel_master_id": "",
    "timeout": 0.1,
    "redis_db": 5}'
);
EOF

cat <<EOF | psql -U $DB_USER -d $GEOCODER_DB -e
SELECT cartodb.CDB_Conf_SetConf(
  'user_config',
  '{"is_organization": false,
    "entity_name": "${GEOCODER_USER}"}'
);
EOF

cat <<EOF | psql -U $DB_USER -d $GEOCODER_DB -e
SELECT cartodb.CDB_Conf_SetConf(
  'heremaps_conf',
  '{"geocoder": {"app_id": "here_geocoder_app_id",
                 "app_code": "here_geocoder_app_code",
                 "geocoder_cost_per_hit": "1"},
    "isolines" : {"app_id": "here_isolines_app_id",
                  "app_code": "here_geocoder_app_code"}}'
);
EOF

cat <<EOF | psql -U $DB_USER -d $GEOCODER_DB -e
SELECT cartodb.CDB_Conf_SetConf(
    'mapzen_conf',
    '{"routing": {"api_key": "valhalla_app_key",
                  "monthly_quota": 999999},
      "geocoder": {"api_key": "search_app_key",
                   "monthly_quota": 999999},
      "matrix": {"api_key": "",
      "monthly_quota": 1500000}}'
);
EOF

cat <<EOF | psql -U $DB_USER -d $GEOCODER_DB -e
SELECT cartodb.CDB_Conf_SetConf(
    'mapbox_conf',
    '{"routing": {"api_keys": "",
                  "monthly_quota": 999999},
      "geocoder": {"api_keys": "",
                   "monthly_quota": 999999},
      "matrix": {"api_keys": "",
                 "monthly_quota": 1500000}}'
);
EOF

cat <<EOF | psql -U $DB_USER -d $GEOCODER_DB -e
SELECT cartodb.CDB_Conf_SetConf(
    'tomtom_conf',
    '{"routing": {"api_keys": "",
                  "monthly_quota": 999999},
      "geocoder": {"api_keys": "",
                   "monthly_quota": 999999},
      "isolines": {"api_keys": "",
                   "monthly_quota": 1500000}}'
);
EOF

cat <<EOF | psql -U $DB_USER -d $GEOCODER_DB -e
SELECT cartodb.CDB_Conf_SetConf(
    'data_observatory_conf',
    '{"connection": {"whitelist": [],
                     "production": "host=postgis port=5432 dbname=${GEOCODER_DB} user=${GEOCODER_USER}",
                     "staging": "host=postgis port=5432 dbname=${GEOCODER_DB} user=${GEOCODER_USER}",
                     "development": "host=postgis port=5432 dbname=${GEOCODER_DB} user=${GEOCODER_USER}"}}'
);
EOF

cat <<EOF | psql -U $DB_USER -d $GEOCODER_DB -e
SELECT cartodb.CDB_Conf_SetConf(
    'server_conf',
    '{"environment": "development"}'
);
EOF
