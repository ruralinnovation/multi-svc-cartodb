#!/usr/bin/env python3

##############################################################################
#                                                                            #
#   Carto Rails Health Check                                                 #
#                                                                            #
#   The Rails app has an endpoint at /status that, if it passes its checks,  #
#   will return a 200 response code with an empty body. This script checks   #
#   the response code and exits normally if all is well, or exits with code  #
#   1 if something is wrong.                                                 #
#                                                                            #
##############################################################################

import os
import urllib.request

cartodb_port = os.environ.get('CARTODB_LISTEN_PORT','3000')

url = "http://localhost:{}/status".format(cartodb_port)

try:
    with urllib.request.urlopen(url) as response:
        if response.getcode() == 200:
            exit(0)
        else:
            exit(1)
except Exception as e:
    exit(1)
