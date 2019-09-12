#!/usr/bin/env python3

##############################################################################
#                                                                            #
#   Varnish Health Check                                                     #
#                                                                            #
#   The Varnish config should include the following:                         #
#                                                                            #
#   sub vcl_recv {                                                           #
#       if (req.request == "GET" && req.url == "/varnish-status") {          #
#           error 200 "OK";                                                  #
#       }                                                                    #
#   }                                                                        #
#                                                                            #
#   That will enable an endpoint at localhost:6081/varnish-status that, if   #
#   the varnish daemon is running, should return a 200. This script checks   #
#   for that, and if present it will exit normally, otherwise exiting 1.     #
#                                                                            #
##############################################################################

import os
import urllib.request

varnish_port = os.environ.get('VARNISH_HTTP_PORT','6081')

url = "http://localhost:{}/varnish-status".format(varnish_port)

try:
    with urllib.request.urlopen(url) as response:
        if response.getcode() == 200:
            exit(0)
        else:
            exit(1)
except Exception as e:
    exit(1)