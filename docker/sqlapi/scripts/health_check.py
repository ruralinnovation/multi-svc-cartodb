#!/usr/bin/env python3

##############################################################################
#                                                                            #
#   SQL API Health Check                                                     #
#                                                                            #
#   The SQL API server has an endpoint at /api/v2/health that should return  #
#   JSON that looks like:                                                    #
#                                                                            #
#      {"enabled":false,"ok":true}                                           #
#                                                                            #
#   The script checks for JSON having an 'ok' key with a true value. If      #
#   present, the script exits normally, if not it exits with code 1.         #
#                                                                            #
##############################################################################

import os
import json
import urllib.request

sqlapi_port = os.environ.get('SQLAPI_LISTEN_PORT','8080')

url = "http://localhost:{}/api/v2/health".format(sqlapi_port)
try:
    with urllib.request.urlopen(url) as response:
        is_healthy = json.loads(response.read())['ok']
except Exception as e:
    exit(1)

if is_healthy:
    exit(0)
else:
    exit(1)
