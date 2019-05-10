#!/bin/bash

DEFAULT_USER=${CARTO_DEFAULT_USER:-developer}
PASSWORD=${CARTO_DEFAULT_PASS:-abc123def}
EMAIL=${CARTO_DEFAULT_EMAIL:-username@example.com}

PG_READY=""
PG_READY_WAIT_SECONDS=5
COUNT=0
DB_CONFIG_FILE=/carto/cartodb/config/database.yml

until [[ -n "$PG_READY" || $COUNT -gt 5 ]]; do
    COUNT=$((COUNT+1))
    pg_isready -h postgis -U postgres > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
	    PG_READY="true"
    else
        echo "Postgres unavailable, sleeping $PG_READY_WAIT_SECONDS seconds"
        sleep $PG_READY_WAIT_SECONDS
    fi
done

dev_db_name=$(sed -n '/development:/,/test:/p;/test:/q' $DB_CONFIG_FILE \
              | grep 'database:' \
              | sed 's/database://' \
              | sed -e 's/[[:space:]]//g')

dev_db_exists=$(psql -U postgres -h postgis -lqt \
                | cut -d \| -f 1 \
                | grep "$dev_db_name")

if [[ -n $dev_db_exists ]]; then
    echo "Database $dev_db_name already exists in postgres, skipping db:create rake task"
    echo "Running database migrations, output sent to /carto/db_migration_output.log"
    bundle exec rake db:migrate > /carto/db_migration_output.log 2>&1
    echo "Database migrations complete."
else
    echo "Creating database $dev_db_name..."
    bundle exec rake db:create
    echo "Running database migrations, output sent to /carto/db_migration_output.log"
    bundle exec rake db:migrate > /carto/db_migration_output.log 2>&1
    echo "Database migrations complete"
fi

tail -f /dev/null
