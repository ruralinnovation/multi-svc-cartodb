#!/bin/bash

#### SETTINGS FROM ENVIRONMENT ###############################################

VARNISH_HTTP_PORT=${VARNISH_HTTP_PORT}

REQUIRED_ENV_VARS=(VARNISH_HTTP_PORT)

REQS_MET="yes"
for var in ${REQUIRED_ENV_VARS[@]}; do
    if [[ -z ${!var} ]]; then
        echo "CRITICAL: In script ${0}, ${var} not found in environment."
        REQS_MET="no"
    fi
done

if [[ $REQS_MET != "yes" ]]; then
    echo "${0} exiting, insufficient info from env."; exit 1
fi

#### ENTRYPOINT TASKS ########################################################

echo "Starting varnishd (foregrounded) as container entrypoint."
/opt/varnish/sbin/varnishd -F \
    -a :${VARNISH_HTTP_PORT} \
    -s malloc,256m \
    -f /etc/varnish.vcl \
    -p http_req_hdr_len=32768
