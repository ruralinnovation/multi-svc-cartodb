FROM redis:5.0.3-alpine AS base

# Note on persistence: This is configured to create persistent data, which
# it will do in the /data directory on the container. If you want to use it
# in a way that persists data beyond the lifetime of the container, you 
# should attach a volume at /data. This file does not do so in favor of 
# doing it via docker-compose--please modify the docker-compose.yml file
# to adjust the storage, and make sure to either bring the container up 
# using `docker-compose`, or attach the volume explicitly via `--mount`
# flag to `docker run`.

COPY ./ssl/coriCA.pem /usr/local/share/ca-certificates/coriCA.crt

RUN apk update \
 && apk add ca-certificates \
 && update-ca-certificates \
 && rm -rf /var/cache/apk/*

EXPOSE 6379

# Options here are to run Redis with persistence.
ENTRYPOINT [ \
    "docker-entrypoint.sh", \
    "redis-server", \
    "--save", "900", "1", \
    "--appendonly", "yes", \
    "--appendfsync", "everysec" \
]

# Overrides CMD from the base image.
CMD []
