#!/bin/bash

set -e

DEFAULT_USER=${CARTO_DEFAULT_USER:-developer}
PASSWORD=${CARTO_DEFAULT_PASS:-dev123}
EMAIL=${CARTO_DEFAULT_EMAIL:-username@example.com}

PUBLIC_HOST=${PUBLIC_HOST:-localhost}
PUBLIC_PORT=${PUBLIC_PORT:-3000}

tail -f /dev/null
