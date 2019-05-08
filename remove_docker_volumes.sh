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

cluster_running=0

if [[ -n $COMPOSE_PROJECT_NAME ]]; then
    images=$(docker ps --format '{{.Image}}' | grep "$COMPOSE_PROJECT_NAME" | xargs)
    if [[ -n $images ]]; then cluster_running=1; fi
fi

if [[ cluster_running -eq 0 ]]; then
    images=$(docker ps --format '{{.Image}}' | grep "$SCRIPT_BASE_DIR" | xargs)
    if [[ -n $images ]]; then cluster_running=1; fi
fi

volume_names=$(sed -nE '/^volumes:/,/^[a-zA-Z0-9"'"'"']/p' ./docker-compose.yml \
               | grep -e '^[[:space:]]' \
               | sed -E 's/^[ -]*//' \
               | sed -E 's/:?//g' \
               | xargs)

docker_volume_names=""

echo_if_unquiet "\nFound these volumes in ./docker-compose.yml:\n"

for vol in $volume_names
do
    msg="    $vol\n        - "
    matching_docker_volumes=$(docker volume ls -q | grep "$vol" | xargs)
    if [[ -n $matching_docker_volumes ]]; then
        match_found=0
        for mdvol in $matching_docker_volumes
        do
            matches_compose_name=0
            matches_basedir_name=0
            if [[ -n $COMPOSE_PROJECT_NAME && -n $(echo "$mdvol" | grep "$COMPOSE_PROJECT_NAME") ]]; then
                matches_compose_name=1; match_found=1
            fi
            if [[ -n $(echo "$mdvol" | grep "$SCRIPT_BASE_DIR") ]]; then
                matches_basedir_name=1; match_found=1
            fi

            if [[ $matches_compose_name -eq 1 || $matches_basedir_name -eq 1 ]]; then
                docker_volume_names+=" $mdvol"
                msg+="matches existing docker vol '$mdvol'"
            fi
            match_found=0
        done
        if [[ $match_found -eq 1 ]]; then
            msg+="has no current docker volume matching its name"
        fi
    else
        msg+="has no current docker volume matching its name"
    fi
    echo_if_unquiet "$msg"
done
echo_if_unquiet ""

docker_volume_names=$(echo "$docker_volume_names" \
                      | sed -E 's/ +/ /g' \
                      | sed -E 's/^ //' \
                      | sed -E 's/ +$//' \
                      | xargs)

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

if [[ cluster_running -eq 1 ]]; then
    echo_if_unquiet "\nCluster appears to be running, bringing it down...\n"
    if [[ $QUIET != "yes" ]]; then
        set -x
        COMPOSE_FILE="$PWD/docker-compose.yml" docker-compose down
        set +x
    else
        COMPOSE_FILE="$PWD/docker-compose.yml" docker-compose down > /dev/null 2>&1
    fi
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
