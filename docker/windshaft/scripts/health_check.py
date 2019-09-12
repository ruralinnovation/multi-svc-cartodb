#!/usr/bin/env python3

##############################################################################
#                                                                            #
#   Windshaft Health Check                                                   #
#                                                                            #
#   Windshaft has a /health endpoint that should return JSON that looks like #
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

windshaft_port = os.environ.get('WINDSHAFT_LISTEN_PORT','8181')

url = "http://localhost:{}/health".format(windshaft_port)
try:
    with urllib.request.urlopen(url) as response:
        is_healthy = json.loads(response.read())['ok']
except Exception as e:
    exit(1)

if is_healthy:
    exit(0)
else:
    exit(1)
