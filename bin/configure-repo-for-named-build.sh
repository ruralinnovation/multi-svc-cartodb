#!/bin/bash
SCRIPT_NAME=$0
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(dirname ${SCRIPT_DIR})"

function display_help() {
    local help_text=""
    IFS='' read -r -d '' help_text <<EOF

Usage: $SCRIPT_NAME [-h|--help] [-c|--conf CONF_NAME]

Purpose:

Options:    -h|--help           Display this message and exit.

            --buildconf CONF_NAME  Specify the build configuration file to use.
                                   If none is specified, the DEFAULT.json file is
                                   used. Note that you do not need to include the
                                   .json file extension.

EOF

    printf "$help_text"
}

BUILD_CONF_NAME="DEFAULT"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        --buildconf)
            shift
            BUILD_CONF_NAME=$1
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Remove .json extension if present
BUILD_CONF_NAME=$(echo $BUILD_CONF_NAME | sed 's/.json$//')
THIS_BUILD_DIR="${REPO_ROOT}/builds/${BUILD_CONF_NAME}"
THIS_BUILD_CONFIG_DIR="$THIS_BUILD_DIR/config"

echo ""
echo "Removing current configuration files found in docker/packer contexts:"

CONF_FILES_TO_REMOVE=(docker/varnish/config/varnish.vcl
                      docker/sqlapi/config/sqlapi-config.js
                      docker/windshaft/config/windshaft-config.js
                      docker/cartodb/config/cartodb-app_config.yml
                      docker/cartodb/config/cartodb-database.yml
                      docker/nginx/config/nginx.conf)

ANY_FILES_REMOVED="no"
for filepath in ${CONF_FILES_TO_REMOVE[@]}; do
    if [[ -f ${REPO_ROOT}/$filepath ]]; then
        ANY_FILES_REMOVED="yes"
        echo "    ${filepath}"
        rm ${REPO_ROOT}/${filepath}
    fi
done

if [[ $ANY_FILES_REMOVED != "yes" ]]; then
    echo "    None of the known config files were present, removing nothing."
fi

echo ""
echo "Adding configuration files from builds/${BUILD_CONF_NAME}/config to docker/packer contexts:"

cp $THIS_BUILD_CONFIG_DIR/varnish.vcl ${REPO_ROOT}/docker/varnish/config/
echo "    docker/varnish/config/varnish.vcl"
cp $THIS_BUILD_CONFIG_DIR/sqlapi-config.js ${REPO_ROOT}/docker/sqlapi/config/
echo "    docker/sqlapi/config/sqlapi-config.js"
cp $THIS_BUILD_CONFIG_DIR/windshaft-config.js ${REPO_ROOT}/docker/windshaft/config/
echo "    docker/windshaft/config/windshaft-config.js"
cp $THIS_BUILD_CONFIG_DIR/cartodb-app_config.yml ${REPO_ROOT}/docker/cartodb/config/
echo "    docker/cartodb/config/cartodb-app_config.yml"
cp $THIS_BUILD_CONFIG_DIR/cartodb-database.yml ${REPO_ROOT}/docker/cartodb/config/
echo "    docker/cartodb/config/cartodb-database.yml"
cp $THIS_BUILD_CONFIG_DIR/nginx.conf ${REPO_ROOT}/docker/nginx/config/
echo "    docker/nginx/config/nginx.conf"
echo ""

echo "Removing current local SSL files from docker/packer contexts:"

CONTEXTS=(docker/varnish
          docker/redis
          docker/sqlapi
          docker/windshaft
          docker/cartodb
          docker/nginx)

for context in ${CONTEXTS[@]}; do
    SSL_DIR=${REPO_ROOT}/${context}/ssl
    find $SSL_DIR -type f ! -iname "README.md" -print -exec rm -f {} +
done
echo ""

echo "Adding local SSL root authority cert to docker contexts:"
for context in ${CONTEXTS[@]}; do
    SSL_DIR=${REPO_ROOT}/${context}/ssl
    echo "    ${context}/ssl/osscarto-multiCA.pem"
    cp ${REPO_ROOT}/local-ssl/osscarto-multiCA.pem $SSL_DIR
done
echo ""

echo "Adding certificate files to the Nginx docker context"
cp ${REPO_ROOT}/local-ssl/*.localhost.* ${REPO_ROOT}/docker/nginx/ssl/
