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
BUILD_CONFIGURATIONS_DIR="${REPO_ROOT}/build-configurations"
THIS_BUILD_CONF_FILE="${BUILD_CONFIGURATIONS_DIR}/${BUILD_CONF_NAME}.json"

# If the named build configuration doesn't exist, exit.
if [[ ! -f $THIS_BUILD_CONF_FILE ]]; then
    echo "CRITICAL: Build configuration '${BUILD_CONF_NAME}' did not resolve to a real file at $THIS_BUILD_CONF_FILE"
    echo "Exiting."
    exit 1
else
    printf "\n$0: Using build configuration: $BUILD_CONF_NAME (build-configurations/$BUILD_CONF_NAME.json)\n\n"
fi

TEMPLATES_DIR="${REPO_ROOT}/templates"
BUILDS_DIR="${REPO_ROOT}/builds"
THIS_BUILD_DIR="${BUILDS_DIR}/${BUILD_CONF_NAME}"
THIS_BUILD_CONFIG_DIR="${THIS_BUILD_DIR}/config"
THIS_BUILD_BIN_DIR="${THIS_BUILD_DIR}/bin"
THIS_BUILD_DOT_ENV_FILE="${THIS_BUILD_DIR}/docker-compose-${BUILD_CONF_NAME}.env"
THIS_BUILD_PACKER_ENV_FILE="${THIS_BUILD_DIR}/packer-env-${BUILD_CONF_NAME}.json"
RENDER_SCRIPT="${REPO_ROOT}/bin/render-template.js"

# Make sure we have a location for our build assets
mkdir -p $THIS_BUILD_CONFIG_DIR $THIS_BUILD_BIN_DIR

echo "Removing existing config and env files for build $BUILD_CONF_NAME:"
find $THIS_BUILD_CONFIG_DIR -type f -print -exec rm -f {} +
find $THIS_BUILD_BIN_DIR -type f -print -exec rm -f {} +
find $THIS_BUILD_DIR -name *.env -print -exec rm -f {} +

echo ""

CONF_TEMPLATES=(varnish.vcl 
                sqlapi-config.js
                windshaft-config.js
                cartodb-app_config.yml
                cartodb-database.yml
                nginx.conf)

echo "Populating build directory with config and env files"

for template in ${CONF_TEMPLATES[@]}; do
    printf "    Writing config file builds/${BUILD_CONF_NAME}/config/${template}..."
    node $RENDER_SCRIPT $THIS_BUILD_CONF_FILE ${TEMPLATES_DIR}/${template}.mustache > ${THIS_BUILD_CONFIG_DIR}/${template}
    printf "DONE\n"
done

printf "    Writing env file builds/${BUILD_CONF_NAME}/docker-compose-${BUILD_CONF_NAME}.env..."
node $RENDER_SCRIPT $THIS_BUILD_CONF_FILE ${TEMPLATES_DIR}/docker-compose-BUILD.env.mustache > $THIS_BUILD_DOT_ENV_FILE
printf "DONE\n"

printf "    Writing env file builds/${BUILD_CONF_NAME}/packer-env-${BUILD_CONF_NAME}.json..."
node $RENDER_SCRIPT $THIS_BUILD_CONF_FILE ${TEMPLATES_DIR}/packer-env-BUILD.json.mustache > $THIS_BUILD_PACKER_ENV_FILE
printf "DONE\n"
