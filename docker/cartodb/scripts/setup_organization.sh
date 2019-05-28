#!/bin/bash

DB_USER="${PGUSER:-postgres}"
DB_HOST="${DB_HOST:-postgis}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-carto_db_development}"
DB_CONN=" -U ${DB_USER} -h ${DB_HOST} -p ${DB_PORT} -d ${DB_NAME} "

ORG_NAME="${CARTO_ORG_NAME:-dev-org}"
ORG_USER="${CARTO_ORG_USER:-dev-org-admin}"
ORG_EMAIL="${CARTO_ORG_EMAIL:-dev-org-admin@example.com}"
ORG_PASS="${CARTO_ORG_PASS:-abc123def}"
RAILS_ENV="${RAILS_ENV:-development}"

export RAILS_ENV
export RUBYOPT="W0" # turn off Ruby warnings, which are INCREDIBLY ANNOYING

org_user_exists=$(psql -qAt $DB_CONN -c "SELECT 1 FROM users WHERE username = '$ORG_USER' AND email = '${ORG_EMAIL}';")

if [[ -z $org_user_exists ]]; then
    echo "Organization user with subdomain/username '${ORG_USER}' and email '${ORG_EMAIL}' does not exist for database '${DB_NAME}', creating..."
    bundle exec rake cartodb:db:create_user EMAIL="${ORG_EMAIL}" PASSWORD="${ORG_PASS}" SUBDOMAIN="${ORG_USER}"
    if [[ $? -ne 0 ]]; then exit 1; fi     # If the create failed, no use doing the rest of this stuff.

    echo "Setting unlimited table quota for org user '${ORG_USER}'..."
    bundle exec rake cartodb:db:set_unlimited_table_quota["${ORG_USER}"]

    echo "Creating organization '${ORG_NAME}' with owner '${ORG_USER}'..."
    bundle exec rake cartodb:db:create_new_organization_with_owner ORGANIZATION_NAME="${ORG_NAME}" USERNAME="${ORG_USER}" ORGANIZATION_SEATS=100 ORGANIZATION_QUOTA=102400 ORGANIZATION_DISPLAY_NAME="${ORG_NAME}"

    echo "Setting organization quota for organization '${ORG_NAME}'..."
    bundle exec rake cartodb:db:set_organization_quota[${ORG_NAME},5000]

    echo "Configuring geocoder extension for organization '${ORG_NAME}'..."
    bundle exec rake cartodb:db:configure_geocoder_extension_for_organizations[${ORG_NAME}]

    echo "Enabling sync tables for org user '${ORG_USER}'..."
    echo "UPDATE users SET sync_tables_enabled=true WHERE username='${ORG_USER}';" | psql -qAt $DB_CONN

    echo "Enabling private maps for org user '${ORG_USER}'..."
    echo "UPDATE users SET private_maps_enabled='t' WHERE username='${ORG_USER}';" | psql -qAt $DB_CONN

    echo "Enabling new dashboard for all users..."
    bundle exec rake cartodb:features:enable_feature_for_all_users["new_dashboard"]
fi
