#!/bin/bash

echo "Starting varnish daemon..."
/opt/varnish/sbin/varnishd -a :6081 -s malloc,256m -f /etc/varnish.vcl
echo "Starting varnishlog -c to view client requests"
/opt/varnish/bin/varnishlog -c
