#!/bin/bash -e
SCRIPT_NAME=$0

#### Variables from environment vars #########################################

# Required
CARTO_ENV="${CARTO_ENV}"
USER_ACCOUNT_USER_NAME="${USER_ACCOUNT_USER_NAME}"
USER_ACCOUNT_PASSWORD="${USER_ACCOUNT_PASSWORD}"
USER_ADMIN_PASSWORD="${USER_ADMIN_PASSWORD}"
USER_ACCOUNT_EMAIL="${USER_ACCOUNT_EMAIL}"
GEOCODER_DB_NAME="${GEOCODER_DB_NAME}"
ORG_ACCOUNT_ORG_NAME="${ORG_ACCOUNT_ORG_NAME}"
ORG_ACCOUNT_USER_NAME="${ORG_ACCOUNT_USER_NAME}"
ORG_ACCOUNT_EMAIL="${ORG_ACCOUNT_EMAIL}"
ORG_ACCOUNT_PASSWORD="${ORG_ACCOUNT_PASSWORD}"

# Optional with defaults
DB_ADMIN="${PGUSER:-postgres}"
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_LISTEN_PORT="${REDIS_LISTEN_PORT:-6379}"
POSTGIS_HOST="${POSTGIS_HOST:-localhost}"
POSTGIS_LISTEN_PORT="${POSTGIS_LISTEN_PORT:-5432}"
REDIS_METADATA_DB="5"

# Composite
PG_METADATA_DB="carto_db_${CARTO_ENV}"
PG_CONN="-U ${DB_ADMIN} -h ${POSTGIS_HOST} -p ${POSTGIS_LISTEN_PORT}"

#### Env var validation ######################################################

REQUIRED_ENV_VARS=(CARTO_ENV USER_ACCOUNT_USER_NAME USER_ACCOUNT_PASSWORD
                   USER_ADMIN_PASSWORD USER_ACCOUNT_EMAIL GEOCODER_DB_NAME
                   ORG_ACCOUNT_ORG_NAME ORG_ACCOUNT_USER_NAME ORG_ACCOUNT_EMAIL
                   ORG_ACCOUNT_PASSWORD)

REQS_MET="yes"
for var in ${REQUIRED_ENV_VARS[@]}; do
    if [[ -z ${!var} ]]; then
        echo "CRITICAL: In script ${0}, ${var} not found in environment."
        REQS_MET="no"
    fi
done

if [[ $REQS_MET != "yes" ]]; then
    echo "${0} exiting, insufficient info from env."; exit 1
fi

#### Create the default user account #########################################

export RAILS_ENV=${CARTO_ENV}

cd /carto/cartodb

dev_user_exists=$(psql -qAt $PG_CONN -d $PG_METADATA_DB -c "SELECT 1 FROM users WHERE username = '$USER_ACCOUNT_USER_NAME' AND email = '$USER_ACCOUNT_EMAIL'")

if [[ -z $dev_user_exists ]]; then
    echo "--- Creating the default Carto user, '${USER_ACCOUNT_USER_NAME}'..."
    bundle exec rake cartodb:db:create_user --trace \
        SUBDOMAIN="${USER_ACCOUNT_USER_NAME}" \
        PASSWORD="${USER_ACCOUNT_PASSWORD}" \
        ADMIN_PASSWORD="${USER_ADMIN_PASSWORD}" \
        EMAIL="${USER_ACCOUNT_EMAIL}"

    echo "--- Setting quotas for user '${USER_ACCOUNT_USER_NAME}'..."
    bundle exec rake cartodb:db:set_user_quota["${USER_ACCOUNT_USER_NAME}",102400]
    bundle exec rake cartodb:db:set_unlimited_table_quota["${USER_ACCOUNT_USER_NAME}"]
    bundle exec rake cartodb:db:set_user_private_tables_enabled["${USER_ACCOUNT_USER_NAME}",'true']
    bundle exec rake cartodb:db:set_user_account_type["${USER_ACCOUNT_USER_NAME}",'[DEDICATED]']
    bundle exec rake cartodb:db:configure_geocoder_extension_for_non_org_users["${USER_ACCOUNT_USER_NAME}"]

    echo "--- Enabling sync tables for user '${USER_ACCOUNT_USER_NAME}'..."
    cat <<EOF | psql $PG_CONN -d $PG_METADATA_DB
UPDATE users SET sync_tables_enabled=true WHERE username='${USER_ACCOUNT_USER_NAME}';
EOF

    echo "--- Setting up dataservices client for user '${USER_ACCOUNT_USER_NAME}'..."
    select_stmt="SELECT database_name FROM users WHERE username='${USER_ACCOUNT_USER_NAME}';"
    USER_ACCOUNT_DB=$(psql $PG_CONN -d $PG_METADATA_DB --tuples-only --no-align -c "$select_stmt")
    cat <<EOF | psql $PG_CONN -d $USER_ACCOUNT_DB
CREATE EXTENSION IF NOT EXISTS cdb_dataservices_client;

SELECT CDB_Conf_SetConf(
    'user_config',
    '{"is_organization": false, "entity_name": "${USER_ACCOUNT_USER_NAME}"}'
);

SELECT CDB_Conf_SetConf(
    'geocoder_server_config',
    '{"connection_str": "host=${POSTGIS_HOST} port=${POSTGIS_LISTEN_PORT} dbname=${GEOCODER_DB_NAME} user=${DB_ADMIN}"}'
);
EOF

else
    echo "Dev user with subdomain/username '${USER_ACCOUNT_USER_NAME}' and email '${USER_ACCOUNT_EMAIL}' exists in database '$PG_METADATA_DB', skipping create."
fi

#### Create the default organization account #################################

org_user_exists=$(psql -qAt $PG_CONN -d $PG_METADATA_DB -c "SELECT 1 FROM users WHERE username = '$ORG_ACCOUNT_USER_NAME' AND email = '$ORG_ACCOUNT_EMAIL';")

if [[ -z $org_user_exists ]]; then
    echo "--- Creating the default Carto organization user account, '${ORG_ACCOUNT_USER_NAME}'..."
    bundle exec rake cartodb:db:create_user --trace \
        SUBDOMAIN="${ORG_ACCOUNT_USER_NAME}" \
        PASSWORD="${ORG_ACCOUNT_PASSWORD}" \
        EMAIL="${ORG_ACCOUNT_EMAIL}"

    echo "--- Setting quotas for org user '${ORG_ACCOUNT_USER_NAME}'..."
    bundle exec rake cartodb:db:set_unlimited_table_quota["${ORG_ACCOUNT_USER_NAME}"]

    echo "--- Creating the organization '${ORG_ACCOUNT_ORG_NAME}' with owner '${ORG_ACCOUNT_USER_NAME}'..."
    bundle exec rake cartodb:db:create_new_organization_with_owner \
        ORGANIZATION_NAME="${ORG_ACCOUNT_ORG_NAME}" \
        USERNAME="${ORG_ACCOUNT_USER_NAME}" \
        ORGANIZATION_SEATS=100 \
        ORGANIZATION_QUOTA=102400 \
        ORGANIZATION_DISPLAY_NAME="${ORG_ACCOUNT_ORG_NAME}"

    echo "--- Setting organization quota for org '${ORG_ACCOUNT_ORG_NAME}'..."
    bundle exec rake cartodb:db:set_organization_quota[${ORG_ACCOUNT_ORG_NAME},5000]

    echo "--- Setting up geocoder for org '${ORG_ACCOUNT_ORG_NAME}'..."
    bundle exec rake cartodb:db:configure_geocoder_extension_for_organizations[${ORG_ACCOUNT_ORG_NAME}]

    cat <<EOF | psql $PG_CONN -d $PG_METADATA_DB
UPDATE users SET sync_tables_enabled=true WHERE username='${ORG_ACCOUNT_USER_NAME}';
UPDATE users SET private_maps_enabled = 't';
EOF

else
    echo "Org user '$ORG_ACCOUNT_USER_NAME' with email '$ORG_ACCOUNT_EMAIL' already exists, skipping create."
fi

#### Enable the new dashboard for all users ##################################

bundle exec rake cartodb:features:enable_feature_for_all_users["new_dashboard"]
