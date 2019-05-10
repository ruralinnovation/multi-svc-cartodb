#!/bin/bash

DEFAULT_USER=${CARTO_DEFAULT_USER:-developer}
PASSWORD=${CARTO_DEFAULT_PASS:-abc123def}
EMAIL=${CARTO_DEFAULT_EMAIL:-username@example.com}
CARTO_ENV=${CARTO_ENV:-development}

PG_READY=""
PG_READY_WAIT_SECONDS=5
COUNT=0
DB_CONFIG_FILE=/carto/cartodb/config/database.yml

# Usage: value_from_dbconf 'env' 'value'
# Example: value_from_dbconf 'development' 'database'
function value_from_dbconf() {
    local val=$(echo "dbconf=YAML.load_file('${DB_CONFIG_FILE}');puts dbconf['${1}']['${2}'];" | ruby -ryaml)
    echo $val
}

DB_HOST=$(value_from_dbconf $CARTO_ENV 'host')
DB_PORT=$(value_from_dbconf $CARTO_ENV 'port')
DB_USER=$(value_from_dbconf $CARTO_ENV 'username')
DB_NAME=$(value_from_dbconf $CARTO_ENV 'database')
PG_CONN=" -U $DB_USER -h $DB_HOST -p $DB_PORT "

until [[ -n "$PG_READY" || $COUNT -gt 5 ]]; do
    COUNT=$((COUNT+1))
    pg_isready $PG_CONN > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
	    PG_READY="true"
    else
        echo "Postgres unavailable, sleeping $PG_READY_WAIT_SECONDS seconds"
        sleep $PG_READY_WAIT_SECONDS
    fi
done

dev_db_exists=$(psql $PG_CONN -lqt | cut -d \| -f 1 | grep "$DB_NAME")

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

dev_username_exists=$(psql -qAt $PG_CONN -d $DB_NAME \
                      -c "SELECT 1 FROM users WHERE username = '$DEFAULT_USER';")
dev_email_exists=$(psql -qAt $PG_CONN -d $DB_NAME \
                   -c "SELECT 1 FROM users WHERE email = '$EMAIL';")

if [[ -z $dev_username_exists && -z $dev_email_exists ]]; then
    echo "Dev user with subdomain/username '${DEFAULT_USER}' and email '${EMAIL}' does not exist for database '$DB_NAME', creating..."
    /carto/cartodb/script/better_create_dev_user.sh \
        --subdomain "$DEFAULT_USER" \
        --password "$PASSWORD" \
        --email "$EMAIL"
fi

echo "Starting the Resque script. Not capturing output--if you need it, change the docker/cartodb/docker-entrypoint.sh script"
bundle exec ./script/resque > /dev/null 2>&1 &

echo "Starting the CartoDB Builder application..."
exec bundle exec rails server -b 0.0.0.0
