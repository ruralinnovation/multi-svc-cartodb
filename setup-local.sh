#!/bin/bash
SCRIPT_NAME=$0

# This file sets environment variables useful for building / using this
# repo. Note that to use it you should run `source setup-env.sh`, since
# if you just run the file directly it will spawn its own process
# instead of adding to the environment of the current shell.

# These are used to git checkout each submodule to specific tags. Once the
# submodules are checked out to version tags, your docker-compose builds will
# include the appropriately versioned code.
export CARTO_PGEXT_VERSION="0.26.1"
export CARTO_WINDSHAFT_VERSION="7.0.0"
export CARTO_CARTODB_VERSION="v4.26.1"
export CARTO_SQLAPI_VERSION="3.0.0"

CARTO_PGEXT_SUBMODULE_PATH="./docker/postgis/cartodb-postgresql"
CARTO_WINDSHAFT_SUBMODULE_PATH="./docker/windshaft/Windshaft-cartodb"
CARTO_CARTODB_SUBMODULE_PATH="./docker/cartodb/cartodb"
CARTO_SQLAPI_SUBMODULE_PATH="./docker/sqlapi/CartoDB-SQL-API"

SET_CHECKOUTS=no
QUIET=no
GITQUIET=""
HORIZONTAL_LINE="\n$(printf '=%.0s' {1..79})\n\n"

function display_help() {
    local help_text=""
    IFS='' read -r -d '' help_text <<EOF

Usage: $SCRIPT_NAME [--set-submodule-versions] [-q|--quiet]

Purpose: Sets the following environment variables (current value in parens):

    CARTO_PGEXT_VERSION       ($CARTO_PGEXT_VERSION)
    CARTO_WINDSHAFT_VERSION   ($CARTO_WINDSHAFT_VERSION)
    CARTO_CARTODB_VERSION     ($CARTO_CARTODB_VERSION)
    CARTO_SQLAPI_VERSION      ($CARTO_SQLAPI_VERSION)

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

EOF

echo_if_unquiet "$vstrings"

if [[ "$SET_CHECKOUTS" = "yes" ]]; then
    # Need to set the values in the .env file, so docker-compose merge values
    # for individual containers work.
    echo "CARTO_PGEXT_VERSION=$CARTO_PGEXT_VERSION" > ./.env
    echo "CARTO_WINDSHAFT_VERSION=$CARTO_WINDSHAFT_VERSION" >> ./.env
    echo "CARTO_SQLAPI_VERSION=$CARTO_SQLAPI_VERSION" >> ./.env
    echo "CARTO_CARTODB_VERSION=$CARTO_CARTODB_VERSION" >> ./.env

    # Going to turn off warnings about detached head, but should be able to
    # set it back to the local value if there is one at the end of the script.
    CURRENT_DETACHED_HEAD_ADVICE=$(git config --global --get advice.detachedHead)
    git config --global advice.detachedHead false

    echo_if_unquiet "Setting checkouts to current version strings...\n"

    echo_if_unquiet "$HORIZONTAL_LINE"
    echo_if_unquiet "Carto PostgreSQL Extension\n\n"
    echo_if_unquiet "Checking out tag '$CARTO_PGEXT_VERSION' in $CARTO_PGEXT_SUBMODULE_PATH:\n\n"
    set -x
    git --git-dir=$CARTO_PGEXT_SUBMODULE_PATH/.git checkout $GITQUIET master
    git --git-dir=$CARTO_PGEXT_SUBMODULE_PATH/.git pull $GITQUIET
    git --git-dir=$CARTO_PGEXT_SUBMODULE_PATH/.git checkout $GITQUIET $CARTO_PGEXT_VERSION
    { set +x; } 2>/dev/null

    echo_if_unquiet "$HORIZONTAL_LINE"
    echo_if_unquiet "Carto Windshaft\n\n"
    echo_if_unquiet "Checking out tag '$CARTO_WINDSHAFT_VERSION' in $CARTO_WINDSHAFT_SUBMODULE_PATH:\n\n"
    set -x
    git --git-dir=$CARTO_WINDSHAFT_SUBMODULE_PATH/.git checkout $GITQUIET master
    git --git-dir=$CARTO_WINDSHAFT_SUBMODULE_PATH/.git pull $GITQUIET
    git --git-dir=$CARTO_WINDSHAFT_SUBMODULE_PATH/.git checkout $GITQUIET $CARTO_WINDSHAFT_VERSION
    { set +x; } 2>/dev/null

    echo_if_unquiet "$HORIZONTAL_LINE"
    echo_if_unquiet "Carto SQL API\n\n"
    echo_if_unquiet "Checking out tag '$CARTO_SQLAPI_VERSION' in $CARTO_SQLAPI_SUBMODULE_PATH:\n\n"
    set -x
    git --git-dir=$CARTO_SQLAPI_SUBMODULE_PATH/.git checkout $GITQUIET master
    git --git-dir=$CARTO_SQLAPI_SUBMODULE_PATH/.git pull $GITQUIET
    git --git-dir=$CARTO_SQLAPI_SUBMODULE_PATH/.git checkout $GITQUIET $CARTO_SQLAPI_VERSION
    { set +x; } 2>/dev/null

    echo_if_unquiet "$HORIZONTAL_LINE"
    echo_if_unquiet "CartoDB\n\n"
    echo_if_unquiet "Checking out tag '$CARTO_CARTODB_VERSION' in $CARTO_CARTODB_SUBMODULE_PATH:\n\n"
    set -x
    git --git-dir=$CARTO_CARTODB_SUBMODULE_PATH/.git checkout $GITQUIET master
    git --git-dir=$CARTO_CARTODB_SUBMODULE_PATH/.git pull $GITQUIET
    git --git-dir=$CARTO_CARTODB_SUBMODULE_PATH/.git checkout $GITQUIET $CARTO_CARTODB_VERSION
    { set +x; } 2>/dev/null

    if [[ -n $CURRENT_DETACHED_HEAD_ADVICE ]]; then
        git config --global advice.detachedHead "$CURRENT_DETACHED_HEAD_ADVICE"
    else
        git config --global --unset advice.detachedHead
    fi
fi
