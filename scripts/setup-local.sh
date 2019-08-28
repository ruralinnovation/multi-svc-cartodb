#!/bin/bash

#### SCRIPT / PATH VARIABLES #################################################
# These are used only inside this script.

SCRIPT_NAME=$0
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(dirname ${SCRIPT_DIR})"

#### MULTI-USE VARIABLES #####################################################
# Used in multiple contexts.

CARTO_USE_HTTPS="${CARTO_USE_HTTPS:-true}"
CARTO_SERVICES_ENV="${CARTO_SERVICES_ENV:-development}"

#### POSTGIS VARIABLES #######################################################
# Used in the `postgis` container.

POSTGIS_LISTEN_PORT="${POSTGIS_LISTEN_PORT:-5432}"
CARTO_PGEXT_VERSION="${CARTO_PGEXT_VERSION:-0.28.1}"
CARTO_DATASVCS_API_CLIENT_VERSION="${CARTO_DATASVCS_CLIENT_VERSION:-0.26.2-client}"
CARTO_DATASVCS_API_SERVER_VERSION="${CARTO_DATASVCS_SERVER_VERSION:-0.35.1-server}"
CARTO_DATASVCS_VERSION="${CARTO_DATASVCS_VERSION:-0.0.2}"
CARTO_ODBC_FDW_VERSION="${CARTO_ODBC_FDW_VERSION:-0.3.0}"
CARTO_CRANKSHAFT_VERSION="${CARTO_CRANKSHAFT_VERSION:-0.8.2}"
CARTO_OBSERVATORY_VERSION="${CARTO_OBSERVATORY_VERSION:-1.9.0}"

#### REDIS VARIABLES #########################################################
# Used in the `redis` container.

REDIS_LISTEN_PORT="${REDIS_LISTEN_PORT:-6379}"

#### CARTODB VARIABLES #######################################################
# Used in the `cartodb` container.

CARTO_ALLOW_DIAGNOSIS="${CARTO_ALLOW_DIAGNOSIS:-true}"
CARTO_CARTODB_VERSION="${CARTO_CARTODB_VERSION:-v4.29.0}"
CARTO_DEFAULT_USER="${CARTO_DEFAULT_USER:-developer}"
CARTO_DEFAULT_PASS="${CARTO_DEFAULT_PASS:-abc123def}"
CARTO_DEFAULT_EMAIL="${CARTO_DEFAULT_EMAIL:-username@example.com}"
CARTO_ORG_NAME="${CARTO_ORG_NAME:-dev-org}"
CARTO_ORG_USER="${CARTO_ORG_USER:-dev-org-admin}"
CARTO_ORG_EMAIL="${CARTO_ORG_EMAIL:-dev-org-admin@example.com}"
CARTO_ORG_PASS="${CARTO_ORG_PASS:-abc123def}"

#### SQLAPI VARIABLES ########################################################
# Used in the `sqlapi` container.

SQLAPI_VERSION="${SQLAPI_VERSION:-3.0.0}"
SQLAPI_ENVIRONMENT="${CARTO_SERVICES_ENV}"
SQLAPI_LISTEN_PORT="${SQLAPI_LISTEN_PORT:-8080}"
SQLAPI_LISTEN_IP="${SQLAPI_LISTEN_IP:-0.0.0.0}"
SQLAPI_POSTGIS_HOST="${SQLAPI_POSTGIS_HOST:-postgis}"
SQLAPI_POSTGIS_PORT="${POSTGIS_LISTEN_PORT}"
SQLAPI_REDIS_HOST="${POSTGIS_REDIS_HOST:-redis}"
SQLAPI_REDIS_PORT="${REDIS_LISTEN_PORT}"

#### WINDSHAFT VARIABLES #####################################################
# Used in the `windshaft` container.

CARTO_WINDSHAFT_VERSION="${CARTO_WINDSHAFT_VERSION:-7.1.0}"

#### ROUTER VARIABLES ########################################################
# Used in the `router` container.

#### VARNISH VARIABLES #######################################################
# Used in the `varnish` container.

#### .ENV FILE GENERATION ####################################################
# Write K/V pairs for all service variables to .env file.

eval 'VARS_CARTO=(${!'"CARTO_"'@})'
eval 'VARS_SQLAPI=(${!'"SQLAPI_"'@})'
eval 'VARS_WINDSHAFT=(${!'"WINDSHAFT_"'@})'
eval 'VARS_POSTGIS=(${!'"POSTGIS_"'@})'
eval 'VARS_REDIS=(${!'"REDIS_"'@})'
eval 'VARS_ROUTER=(${!'"ROUTER_"'@})'
eval 'VARS_VARNISH=(${!'"VARNISH_"'@})'

OUTPUT_VARS=( "${VARS_CARTO[@]}" "${VARS_SQLAPI[@]}" "${VARS_WINDSHAFT[@]}" "${VARS_POSTGIS[@]}" "${VARS_REDIS[@]}" "${VARS_ROUTER[@]}" "${VARS_VARNISH[@]}" )

DOT_ENV_FILE=${REPO_ROOT}/.env
PACKER_ENV_FILE=${REPO_ROOT}/packer-env.json

# Truncate the .env and packer-env.json files
true > $DOT_ENV_FILE
true > $PACKER_ENV_FILE

# Write KV pairs to .env
for var in "${OUTPUT_VARS[@]}"; do
    echo "${var}=${!var}" >> ${REPO_ROOT}/.env
done

function join_by {
    local IFS=${1}$'\n'
    shift
    printf "$*"
}

# Write KV pairs to packer-env.json

OUTPUT_JSON_KV_PAIRS=()
for var in "${OUTPUT_VARS[@]}"; do
    OUTPUT_JSON_KV_PAIRS+=('"'${var}'":"'${!var}'"')
done

printf "{" > $PACKER_ENV_FILE
join_by ',' ${OUTPUT_JSON_KV_PAIRS[@]} >> $PACKER_ENV_FILE
printf "}" >> $PACKER_ENV_FILE

#### HELP FUNCTION ###########################################################

function display_help() {
    local help_text=""
    IFS='' read -r -d '' help_text <<EOF

Usage: $SCRIPT_NAME

Purpose: Sets values in the .env file.

EOF

    printf "$help_text"
}


while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        *)
            break
            ;;
    esac
done
