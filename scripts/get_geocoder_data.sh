#!/bin/bash
SCRIPT_NAME=$0
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO_ROOT="$( dirname ${SCRIPT_DIR} )"
GEOCODER_DATA_DIR="${REPO_ROOT}/docker/postgis/geocoder_data/"

QUIET="no"
WGET_QUIET=""

function display_help() {                                                       
    local help_text=""                                                          
    IFS='' read -r -d '' help_text <<EOF                                        
                                                                                
Usage: $SCRIPT_NAME [-h|--help] [-q|--quiet]

Purpose: Downloads a local copy of the SQL data files that power the internal
         geocoder for the Carto dataservices API.

         The files will be downloaded to:

             $GEOCODER_DATA_DIR

         If you intend to change that location please be aware that the
         Dockerfile for the postgis container expects them to be there.

         Also be aware that this will download 5.8GB of data, so make sure
         you have the disk space available.
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
            WGET_QUIET=" -q "
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

HORIZONTAL_LINE="\n$(printf '=%.0s' {1..79})\n\n"
BASE_URL="https://s3.amazonaws.com/data.cartodb.net/geocoding/dumps"
VERSION="0.0.1"
DUMP_LIST="admin0_synonyms.sql available_services.sql country_decoder.sql "
DUMP_LIST+="admin1_decoder.sql global_cities_alternates_limited.sql "
DUMP_LIST+="global_cities_points_limited.sql global_postal_code_points.sql "
DUMP_LIST+="global_province_polygons.sql ip_address_locations.sql "
DUMP_LIST+="ne_admin0_v3.sql global_postal_code_polygons.sql"

mkdir -p $GEOCODER_DATA_DIR

echo_if_unquiet "\nFiles will be saved in $GEOCODER_DATA_DIR \n"

for file in $DUMP_LIST; do
    file_url="${BASE_URL}/${VERSION}/$file"
    echo_if_unquiet "${HORIZONTAL_LINE}Retrieving ${file_url}...\n\n"
    wget $WGET_QUIET -c --directory-prefix=$GEOCODER_DATA_DIR $file_url
done
