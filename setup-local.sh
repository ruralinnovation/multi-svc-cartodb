#!/bin/bash
SCRIPT_NAME=$0
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

#### GIT VERSIONS FOR CARTO MODULES ##########################################

# Whether CartoDB will construct https links or not
CARTO_USE_HTTPS="${CARTO_USE_HTTPS:-true}"

# Core modules
CARTO_CARTODB_VERSION="${CARTO_CARTODB_VERSION:-v4.26.1}"
CARTO_WINDSHAFT_VERSION="${CARTO_WINDSHAFT_VERSION:-7.1.0}"
CARTO_SQLAPI_VERSION="${CARTO_SQLAPI_VERSION:-3.0.0}"
# PostgreSQL extensions
CARTO_PGEXT_VERSION="${CARTO_PGEXT_VERSION:-0.26.1}"
CARTO_DATASVCS_API_CLIENT_VERSION="${CARTO_DATASVCS_CLIENT_VERSION:-0.26.2-client}"
CARTO_DATASVCS_API_SERVER_VERSION="${CARTO_DATASVCS_SERVER_VERSION:-0.35.1-server}"
CARTO_DATASVCS_VERSION="${CARTO_DATASVCS_VERSION:-0.0.2}"
CARTO_ODBC_FDW_VERSION="${CARTO_ODBC_FDW_VERSION:-0.3.0}"
CARTO_CRANKSHAFT_VERSION="${CARTO_CRANKSHAFT_VERSION:-0.8.2}"
CARTO_OBSERVATORY_VERSION="${CARTO_OBSERVATORY_VERSION:-1.9.0}"

#### VALUES USED TO SET UP DEVELOPMENT USERS IN CARTODB ######################

CARTO_DEFAULT_USER="${CARTO_DEFAULT_USER:-developer}"
CARTO_DEFAULT_PASS="${CARTO_DEFAULT_PASS:-abc123def}"
CARTO_DEFAULT_EMAIL="${CARTO_DEFAULT_EMAIL:-username@example.com}"
CARTO_ORG_NAME="${CARTO_ORG_NAME:-dev-org}"
CARTO_ORG_USER="${CARTO_ORG_USER:-dev-org-admin}"
CARTO_ORG_EMAIL="${CARTO_ORG_EMAIL:-dev-org-admin@example.com}"
CARTO_ORG_PASS="${CARTO_ORG_PASS:-abc123def}"

#### VERSION STRING PRINTING #################################################

IFS='' read -r -d '' dot_env_lines <<EOF
CARTO_USE_HTTPS=$CARTO_USE_HTTPS
CARTO_WINDSHAFT_VERSION=$CARTO_WINDSHAFT_VERSION
CARTO_SQLAPI_VERSION=$CARTO_SQLAPI_VERSION
CARTO_CARTODB_VERSION=$CARTO_CARTODB_VERSION
CARTO_PGEXT_VERSION=$CARTO_PGEXT_VERSION
CARTO_DATASVCS_API_CLIENT_VERSION=$CARTO_DATASVCS_API_CLIENT_VERSION
CARTO_DATASVCS_API_SERVER_VERSION=$CARTO_DATASVCS_API_SERVER_VERSION
CARTO_DATASVCS_VERSION=$CARTO_DATASVCS_VERSION
CARTO_ODBC_FDW_VERSION=$CARTO_ODBC_FDW_VERSION
CARTO_CRANKSHAFT_VERSION=$CARTO_CRANKSHAFT_VERSION
CARTO_OBSERVATORY_VERSION=$CARTO_OBSERVATORY_VERSION
CARTO_DEFAULT_USER=$CARTO_DEFAULT_USER
CARTO_DEFAULT_PASS=$CARTO_DEFAULT_PASS
CARTO_DEFAULT_EMAIL=$CARTO_DEFAULT_EMAIL
CARTO_ORG_NAME=$CARTO_ORG_NAME
CARTO_ORG_USER=$CARTO_ORG_USER
CARTO_ORG_EMAIL=$CARTO_ORG_EMAIL
CARTO_ORG_PASS=$CARTO_ORG_PASS
EOF

printf "$dot_env_lines" > ${SCRIPT_DIR}/.env

#### SCRIPT SETTINGS AND FLAGS ###############################################

GENERATE_CERT="no"
QUIET="no"

#### HELP FUNCTION ###########################################################

function display_help() {
    local help_text=""
    IFS='' read -r -d '' help_text <<EOF

Usage: $SCRIPT_NAME [--generate-ssl-cert]

Purpose: Sets values in the .env file, and generates SSL cert files.

Flags:
    --generate-ssl-cert        - Creates .crt and .key files for the nginx
                                 router container to use for signing localhost.
    -q|--quiet                 - Display no output.

EOF

    printf "$help_text"
}


while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        --generate-ssl-cert)
            shift
            GENERATE_CERT=yes
            ;;
        -q|--quiet)
            shift
            QUIET=yes
            ;;
        *)
            break
            ;;
    esac
done

#### PRINT UNLESS QUIET FUNCTION #############################################

function echo_if_unquiet() {
    if [ "$QUIET" != "yes" ]; then
        printf "$1"
    fi
}

#### SSL CERTIFICATE GENERATION ##############################################

if [[ $GENERATE_CERT = "yes" ]]; then
    echo_if_unquiet "Generating SSL .crt and .key files in docker/router/ssl...\n"

    cert_output=$(openssl req -x509 \
    -out docker/router/ssl/wildcard-localhost.crt \
    -keyout docker/router/ssl/wildcard-localhost.key \
    -newkey rsa:2048 -nodes -sha256 \
    -subj '/CN=*.localhost' -extensions EXT -config <( \
    printf "[dn]\nCN=*.localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:*.localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth") 2>&1)

    echo_if_unquiet "Completed generating SSL .crt and .key files.\n"

    chmod 644 docker/router/ssl/wildcard-localhost.crt
    chmod 640 docker/router/ssl/wildcard-localhost.key
fi
