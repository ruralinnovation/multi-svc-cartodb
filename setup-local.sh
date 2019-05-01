#!/bin/bash

# This file sets environment variables useful for building / using this
# repo. Note that to use it you should run `source setup-env.sh`, since
# if you just run the file directly it will spawn its own process
# instead of adding to the environment of the current shell.

# COMPOSE_PROJECT_NAME is a docker-compose env var, and determines the prefix
# that will be used when naming containers created via docker-compose. 
# See https://docs.docker.com/compose/reference/envvars/ for more info.
export COMPOSE_PROJECT_NAME="carto-ms"

# These are used to git checkout each submodule to specific tags. Once the
# submodules are checked out to version tags, your docker-compose builds will
# include the appropriately versioned code.
export CARTO_PGEXT_VERSION="0.26.1"
export CARTO_WINDSHAFT_VERSION="7.0.0"
export CARTO_CARTODB_VERSION="v4.26.0"
export CARTO_SQLAPI_VERSION="3.0.0"

CARTO_PGEXT_SUBMODULE_PATH="./docker/postgis/cartodb-postgresql"
CARTO_WINDSHAFT_SUBMODULE_PATH="./docker/windshaft/Windshaft-cartodb"
CARTO_CARTODB_SUBMODULE_PATH="./docker/cartodb/cartodb"
CARTO_SQLAPI_SUBMODULE_PATH="./docker/sqlapi/CartoDB-SQL-API"

SET_CHECKOUTS=yes
QUIET=no
GITQUIET=""

# TODO: Add help text for the script.
while test $# -gt 0; do
    case "$1" in
        -h|--help)
            printf "Help for this script."
            exit 0
            ;;
        --no-set-submodule-versions)
            shift
            SET_CHECKOUTS=no
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

echo_if_unquiet "\nCurrent version strings for Carto submodules:\n"
echo_if_unquiet "    Carto PostgreSQL Extension: $CARTO_PGEXT_VERSION\n"
echo_if_unquiet "    Carto Windshaft:            $CARTO_WINDSHAFT_VERSION\n"
echo_if_unquiet "    Carto SQLAPI:               $CARTO_SQLAPI_VERSION\n"
echo_if_unquiet "    CartoDB:                    $CARTO_CARTODB_VERSION\n\n"

if [ "$SET_CHECKOUTS" = "yes" ]; then
    echo_if_unquiet "Setting checkouts to current version strings...\n"

    echo_if_unquiet "    Setting $CARTO_PGEXT_SUBMODULE_PATH to version $CARTO_PGEXT_VERSION... "
    git --git-dir=$CARTO_PGEXT_SUBMODULE_PATH/.git checkout $GITQUIET $CARTO_PGEXT_VERSION

    echo_if_unquiet "    Setting $CARTO_WINDSHAFT_SUBMODULE_PATH to version $CARTO_WINDSHAFT_VERSION... "
    git --git-dir=$CARTO_WINDSHAFT_SUBMODULE_PATH/.git checkout $GITQUIET $CARTO_WINDSHAFT_VERSION

    echo_if_unquiet "    Setting $CARTO_SQLAPI_SUBMODULE_PATH to version $CARTO_SQLAPI_VERSION... "
    git --git-dir=$CARTO_SQLAPI_SUBMODULE_PATH/.git checkout $GITQUIET $CARTO_SQLAPI_VERSION

    echo_if_unquiet "    Setting $CARTO_CARTODB_SUBMODULE_PATH to version $CARTO_CARTODB_VERSION... "
    git --git-dir=$CARTO_CARTODB_SUBMODULE_PATH/.git checkout $GITQUIET $CARTO_CARTODB_VERSION
fi
