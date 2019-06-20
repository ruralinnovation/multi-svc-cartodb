#!/bin/bash

echo "Starting varnish daemon..."
/opt/varnish/sbin/varnishd -a :6081 -T :6082 -s malloc,256m -f /etc/varnish.vcl
echo "Tailing /dev/null to keep the Docker image from closing."
tail -f /dev/null
