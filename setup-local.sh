#!/bin/bash
SCRIPT_NAME=$0
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# This file sets environment variables useful for building / using this
# repo. Note that to use it you should run `source setup-env.sh`, since
# if you just run the file directly it will spawn its own process
# instead of adding to the environment of the current shell.

# TODO: Need to make sure there's a good way to unset the env vars so they
#       can take a new value in a transparent way. Too easy to get stuck
#       in an incoherent state, particularly if you source this file
#       in your .bash_profile.

# These are used to git checkout each submodule to specific tags. Once the
# submodules are checked out to version tags, your docker-compose builds will
# include the appropriately versioned code.
export CARTO_PGEXT_VERSION="${CARTO_PGEXT_VERSION:-0.26.1}"
export CARTO_WINDSHAFT_VERSION="${CARTO_WINDSHAFT_VERSION:-7.0.0}"
export CARTO_CARTODB_VERSION="${CARTO_CARTODB_VERSION:-v4.26.1}"
export CARTO_SQLAPI_VERSION="${CARTO_SQLAPI_VERSION:-3.0.0}"
export CARTO_DATASVCS_CLIENT_VERSION="${CARTO_DATASVCS_CLIENT_VERSION:-0.26.2-client}"
export CARTO_DATASVCS_SERVER_VERSION="${CARTO_DATASVCS_SERVER_VERSION:-0.35.1-server}"

ALL_MODULES="PGEXT WINDSHAFT CARTODB SQLAPI DATASVCS_CLIENT DATASVCS_SERVER"

CARTO_PGEXT_SUBMODULE_PATH="${SCRIPT_DIR}/docker/postgis/cartodb-postgresql"
CARTO_WINDSHAFT_SUBMODULE_PATH="${SCRIPT_DIR}/docker/windshaft/Windshaft-cartodb"
CARTO_CARTODB_SUBMODULE_PATH="${SCRIPT_DIR}/docker/cartodb/cartodb"
CARTO_SQLAPI_SUBMODULE_PATH="${SCRIPT_DIR}/docker/sqlapi/CartoDB-SQL-API"
CARTO_DATASVCS_CLIENT_SUBMODULE_PATH="${SCRIPT_DIR}/docker/postgis/dataservices-api-client"
CARTO_DATASVCS_SERVER_SUBMODULE_PATH="${SCRIPT_DIR}/docker/postgis/dataservices-api-server"

export CARTO_DEFAULT_USER="${CARTO_DEFAULT_USER:-developer}"
export CARTO_DEFAULT_PASS="${CARTO_DEFAULT_PASS:-abc123def}"
export CARTO_DEFAULT_EMAIL="${CARTO_DEFAULT_EMAIL:-username@example.com}"

SET_CHECKOUTS=no
QUIET=no
GITQUIET=""
HORIZONTAL_LINE="\n$(printf '=%.0s' {1..79})\n\n"

function display_help() {
    local help_text=""
    IFS='' read -r -d '' help_text <<EOF

Usage: $SCRIPT_NAME [--set-submodule-versions] [-q|--quiet]

Purpose: Sets the following environment variables (current value in parens):

    CARTO_PGEXT_VERSION             ($CARTO_PGEXT_VERSION)
    CARTO_WINDSHAFT_VERSION         ($CARTO_WINDSHAFT_VERSION)
    CARTO_CARTODB_VERSION           ($CARTO_CARTODB_VERSION)
    CARTO_SQLAPI_VERSION            ($CARTO_SQLAPI_VERSION)
    CARTO_DATASVCS_CLIENT_VERSION   ($CARTO_DATASVCS_CLIENT_VERSION)
    CARTO_DATASVCS_SERVER_VERSION   ($CARTO_DATASVCS_SERVER_VERSION)
    CARTO_DEFAULT_USER              ($CARTO_DEFAULT_USER)
    CARTO_DEFAULT_PASS              ($CARTO_DEFAULT_PASS)
    CARTO_DEFAULT_EMAIL             ($CARTO_DEFAULT_EMAIL)

    If the --set-submodule-versions flag is present, resets the
    submodule directories to the version tags in those variables.

    Note that the values are set both in the local environment, and
    in the .env file that docker-compose uses to substitute environment
    variables. That file is excluded from version control, so you
    have to run this script at least once with --set-submodule-versions
    before attempting docker-compose build.

Flags:
    --set-submodule-versions   - For all submodules in the project,
                                 pull from master, then re-checkout
                                 to the version tag listed in the script.
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
        --set-submodule-versions)
            shift
            SET_CHECKOUTS=yes
            ;;
        -q|--quiet)
            shift
            QUIET=yes
            GITQUIET=" -q "
            ;;
        *)
            break
            ;;
    esac
done

function echo_if_unquiet() {
    if [ "$QUIET" != "yes" ]; then
        printf "$1"
    fi
}

IFS='' read -r -d '' vstrings <<EOF

Current version strings for Carto submodules:
    Carto PostgreSQL Extension: $CARTO_PGEXT_VERSION
    Carto Windshaft:            $CARTO_WINDSHAFT_VERSION
    Carto SQLAPI:               $CARTO_SQLAPI_VERSION
    CartoDB:                    $CARTO_CARTODB_VERSION
    Dataservices API (client)   $CARTO_DATASVCS_CLIENT_VERSION
    Dataservices                $CARTO_DATASVCS_SERVER_VERSION

EOF

echo_if_unquiet "$vstrings"

IFS='' read -r -d '' dot_env_lines <<EOF
CARTO_PGEXT_VERSION=$CARTO_PGEXT_VERSION
CARTO_WINDSHAFT_VERSION=$CARTO_WINDSHAFT_VERSION
CARTO_SQLAPI_VERSION=$CARTO_SQLAPI_VERSION
CARTO_CARTODB_VERSION=$CARTO_CARTODB_VERSION
CARTO_DATASVCS_CLIENT_VERSION=$CARTO_DATASVCS_CLIENT_VERSION
CARTO_DATASVCS_SERVER_VERSION=$CARTO_DATASVCS_SERVER_VERSION
CARTO_DEFAULT_USER=$CARTO_DEFAULT_USER
CARTO_DEFAULT_PASS=$CARTO_DEFAULT_PASS
CARTO_DEFAULT_EMAIL=$CARTO_DEFAULT_EMAIL
EOF

if [[ "$SET_CHECKOUTS" = "yes" ]]; then
    # Need to set the values in the .env file, so docker-compose merge values
    # for individual containers work.
    echo "$dot_env_lines" > ./.env

    # Going to turn off warnings about detached head, but should be able to
    # set it back to the global value if there is one at the end of the script.
    CURRENT_DETACHED_HEAD_ADVICE=$(git config --global --get advice.detachedHead)
    git config --global advice.detachedHead false

    echo_if_unquiet "Setting checkouts to current version strings...\n"

    git --git-dir=${SCRIPT_DIR}/.git submodule update $GITQUIET --init --recursive
    git --git-dir=${SCRIPT_DIR}/.git pull $GITQUIET --recurse-submodules
    for module in $ALL_MODULES
    do
        version_key="CARTO_${module}_VERSION"
        path_key="CARTO_${module}_SUBMODULE_PATH"
        eval version='$'$version_key
        eval path='$'$path_key

        echo_if_unquiet "$HORIZONTAL_LINE"
        echo_if_unquiet "Module $module:\n\n"
        echo_if_unquiet "Checking out tag '$version' in $path:\n\n"
        if [[ $QUIET != "yes" ]]; then set -x; fi
        git --git-dir=$path/.git checkout $GITQUIET $version
        if [[ $QUIET != "yes" ]]; then { set +x; } 2>/dev/null; fi
    done

    if [[ -n $CURRENT_DETACHED_HEAD_ADVICE ]]; then
        git config --global advice.detachedHead "$CURRENT_DETACHED_HEAD_ADVICE"
    else
        git config --global --unset advice.detachedHead
    fi
fi
