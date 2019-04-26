#!/bin/bash

set -ex 

# Need to append the docker assigned IP of the host to the pg_hba.conf file
# so postgres can listen on the correct network interface for the virtual
# network in docker-compose. This adds it with a 32 bit mask on the IP range,
# so any of the other hosts in the docker network should be allowed to
# connect to the postgres server on this container.
echo -e "host\tall\t\tall\t\t$(hostname -i)/32\t\ttrust" >> /etc/postgresql/10/main/pg_hba.conf

service postgresql start
