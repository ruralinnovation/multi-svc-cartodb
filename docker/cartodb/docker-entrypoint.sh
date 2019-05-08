#!/bin/bash

set -e

DEFAULT_USER=${CARTO_DEFAULT_USER:-developer}
PASSWORD=${CARTO_DEFAULT_PASS:-dev123}
EMAIL=${CARTO_DEFAULT_EMAIL:-username@example.com}

dev_db_name=$(sed -n '/development:/,/test:/p;/test:/q' config/database.yml \
              | grep 'database:' \
              | sed 's/database://' \
              | sed -e 's/[[:space:]]//g')

dev_db_exists=$(psql -U postgres -h postgis -lqt \
                | cut -d \| -f 1 \
                | grep "$dev_db_name")

if [[ -n dev_db_exists ]]; then
    echo "Database $dev_db_name already exists in postgres, skipping db:create rake task"
    echo "Running database migrations, with silenced output."
    bundle exec rake db:migrate > /dev/null 2>&1
else
    echo "Creating database $dev_db_name..."
    bundle exec rake db:create
    echo "Migrating database $dev_db_name..."
    bundle exec rake db:migrate
fi



tail -f /dev/null
