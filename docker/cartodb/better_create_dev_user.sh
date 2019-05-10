#!/bin/bash
SCRIPT_NAME=$0

RAILS_ENV_SOURCE="script environment"
if [[ ${RAILS_ENV:-undefinedbashvar} == "undefinedbashvar" ]]; then
    RAILS_ENV_SOURCE="this script (undefined in env of script)"
fi
RAILS_ENV=${RAILS_ENV:-development}
SUBDOMAIN=${SUBDOMAIN:-dev}
PASSWORD=${PASSWORD:-abc123def}
EMAIL=${EMAIL:-info@ruralinnovation.us}
QUIET="no"
RAKE_TRACE=" --trace "
CONFIRM="no"

function display_help() {
    local help_text=""
    IFS='' read -r -d '' help_text <<EOF

Usage: $SCRIPT_NAME [flags] [-q|--quiet]

Purpose: Creates a development user in the CartoDB database.

Flags:

    --subdomain     Supply a custom value for the username/subdomain.
                    If not supplied, will pull from env, or default to
                    value '$SUBDOMAIN'
    --password      Supply a custom value for the password. If not supplied
                    will pull from env, or default to value '$PASSWORD'
    --email         Supply a custom value for the email. If not supplied
                    will pull from env, or default to value '$EMAIL'
    --confirm       If running manually, you can use this to impose a values
                    check prior to actually running the create. It'll require
                    manual confirmation of the values for subdomain, password,
                    and email.
    --no-rake-trace Do not use the '--trace' flag with bundle exec rake.
    -q|--quiet      Do not output to STDOUT. Implies --no-rake-trace.
    -h|--help       Display this message.

EOF
    printf "$help_text"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        --subdomain)
            shift
            SUBDOMAIN="$1"
            shift
            ;;
        --password)
            shift
            PASSWORD="$1"
            shift
            ;;
        --email)
            shift
            EMAIL="$1"
            shift
            ;;
        --confirm)
            shift
            CONFIRM="yes"
            ;;
        --no-rake-trace)
            shift
            RAKE_TRACE=""
            ;;
        -q|--quiet)
            shift
            QUIET="yes"
            RAKE_TRACE=""
            ;;
        *)
            break
            ;;
    esac
done

if [[ $QUIET == "yes" && $CONFIRM == "yes" ]]; then 
    printf "Error: Can't use the --quiet and --confirm flags together.\n"
    exit 1
fi

function echo_if_unquiet() {
    if [[ $QUIET != "yes" ]]; then printf "$1\n"; fi
}

IFS='' read -r -d '' values <<EOF

Got the following values to pass to cartodb:db:create_dev_user rake task:

    SUBDOMAIN       [$SUBDOMAIN]
    PASSWORD        [$PASSWORD]
    EMAIL           [$EMAIL]

Note that the rake task will run with a RAILS_ENV of [$RAILS_ENV], sourced
from ${RAILS_ENV_SOURCE}.
EOF

echo_if_unquiet "$values"

if [[ $CONFIRM == "yes" ]]; then
    while true; do
        read -p "Run the create with those values? [Y/n] " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit 0;;
            * ) break;;
        esac
    done
fi

echo_if_unquiet "\nCalling the create task..."

set -x
RAILS_ENV="$RAILS_ENV" bundle exec rake cartodb:db:create_dev_user $RAKE_TRACE \
    SUBDOMAIN="${SUBDOMAIN}" \
    PASSWORD="${PASSWORD}" \
    EMAIL="${EMAIL}"
set +x

if [[ $? -ne 0 ]]; then exit 1; fi
