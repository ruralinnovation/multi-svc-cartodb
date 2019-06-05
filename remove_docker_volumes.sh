#!/bin/bash

SCRIPT_NAME=$0
SCRIPT_BASE_DIR="${PWD##*/}"

QUIET=no
AUTORUN=no

function display_help() {
    local help_text=""
    IFS='' read -r -d '' help_text <<EOF

Usage: $SCRIPT_NAME [-q|--quiet] [-y|--yes]

Purpose: Removes all docker volumes listed in ./docker-compose.yml

Flags:
    -q|--quiet      Run without producing output to STDOUT. Implies --yes.
    -y|--yes        Do not prompt before removing volumes

Note: If you use the -q|--quiet flag, it assumes you want to delete the
      volumes without being prompted, so it automatically uses --yes.

EOF

    printf "$help_text"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        -q|--quiet)
            shift
            QUIET=yes
            AUTORUN=yes
            ;;
        -y|--yes)
            shift
            AUTORUN=yes
            ;;
        *)
            break
            ;;
    esac
done

function echo_if_unquiet() {
    if [[ $QUIET != "yes" ]]; then
        printf "$1\n"
    fi
}

volume_prefix=${PWD##*/}
if [[ -n $COMPOSE_PROJECT_NAME ]]; then volume_prefix=$COMPOSE_PROJECT_NAME; fi

volume_names=$(docker-compose config --volumes)
docker_volume_names=""

echo_if_unquiet "\nFound these volumes in ./docker-compose.yml:\n"

for vol in $volume_names
do
    msg="    $vol:\n        - "
    full_vol_name="${volume_prefix}_${vol}"
    match_found=$(docker volume ls -q --filter "name=${full_vol_name}")
    if [[ -n $match_found ]]; then
        msg+="matches existing docker volume ${full_vol_name}"
        docker_volume_names+=" $full_vol_name"
    else
        msg+="has no current docker volume matching its name"
    fi
    echo_if_unquiet "$msg"
done

echo_if_unquiet ""

if [[ -z $docker_volume_names ]]; then
    echo_if_unquiet "\nNo current docker volumes found that match those in ./docker-compose.yml, exiting.\n"
    exit 0
fi

echo_if_unquiet "If you proceed, the cluster will be brought down (if currently up) and these volumes deleted:\n"

for dvol in $docker_volume_names
do
    echo_if_unquiet "    $dvol"
done
echo_if_unquiet ""

if [[ $AUTORUN != "yes" ]]; then
    while true; do
        read -p "Delete these docker volumes? [y/N] " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit 0;;
            * ) exit 0;;
        esac
    done
fi

echo_if_unquiet "Running docker-compose down to make sure the volumes aren't going to be attached to existing containers..."
if [[ $QUIET != "yes" ]]; then
    set -x
    COMPOSE_FILE="$PWD/docker-compose.yml" docker-compose down
    set +x
else
    COMPOSE_FILE="$PWD/docker-compose.yml" docker-compose down > /dev/null 2>&1
fi

echo_if_unquiet "Removing volumes..."

for dvol in $docker_volume_names
do
    echo_if_unquiet "   Removing $dvol"
    if [[ $QUIET != "yes" ]]; then
        set -x; docker volume rm "$dvol"; set +x
    else
        docker volume rm "$dvol" > /dev/null 2>&1
    fi
done
