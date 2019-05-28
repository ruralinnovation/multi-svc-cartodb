#!/bin/bash

#### SETTINGS FROM ENVIRONMENT ###############################################

DEFAULT_USER=${CARTO_DEFAULT_USER:-developer}
PASSWORD=${CARTO_DEFAULT_PASS:-abc123def}
EMAIL=${CARTO_DEFAULT_EMAIL:-username@example.com}
CARTO_ENV=${CARTO_ENV:-development}
RAILS_ENV=${RAILS_ENV:-development}

# Exporting this so it is used by the various bundler calls.
export RAILS_ENV


#### SCRIPT SETTINGS #########################################################

PG_READY=""
PG_READY_WAIT_SECONDS=5
COUNT=0
DB_CONFIG_FILE=/carto/cartodb/config/database.yml
APP_CONFIG_FILE=/carto/cartodb/config/app_config.yml
MIGRATION_LOG_FILE=/carto/db_migration_output.log


#### FUNCTIONS ###############################################################

# Usage: value_from_dbconf 'env' 'value'
# Example: value_from_dbconf 'development' 'database'
function value_from_dbconf() {
    local val=$(echo "dbconf=YAML.load_file('${DB_CONFIG_FILE}');puts dbconf['${1}']['${2}'];" | ruby -ryaml)
    echo $val
}

function value_from_appconf() {
    local val=$(echo "appconf=YAML.load_file('${APP_CONFIG_FILE}');puts appconf['${1}']['${2}'];" | ruby -ryaml)
    echo $val
}

#### DATABASE SETTINGS AND POSTGRES READINESS CHECK ##########################

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


##############################################################################
#### BEGIN CONDITIONAL SETUP STEPS ###########################################
##############################################################################

#### FORCING HTTPS IN DEV ####################################################

# This section is a hack to make https stay on without changing the rails env
# to staging or production, which is otherwise required to get it to stop
# constructing http based urls.
USE_HTTPS=$(value_from_appconf 'defaults' 'use_https')
USE_HTTPS=${USE_HTTPS:-false}

if [[ $USE_HTTPS = 'true' ]]; then
    CARTO_DB_INIT_FILE="/carto/cartodb/config/initializers/carto_db.rb"
    echo "Changing the self.use_https? method in $CARTO_DB_INIT_FILE to return true, so https works in dev."
    sed -i "/def self.use_https\?/,/end/c\  def self.use_https?\n    true\n  end" $CARTO_DB_INIT_FILE
fi

#### CREATING THE DATABASE IF IT DOES NOT EXIST ##############################

cd /carto/cartodb

dev_db_exists=$(psql $PG_CONN -lqt | cut -d \| -f 1 | grep "$DB_NAME")
dev_db_name=$DB_NAME

if [[ -z $dev_db_exists ]]; then
    echo "Creating database $dev_db_name..."
    bundle exec rake db:create
    echo "Installing cartodb extension to db $dev_db_name..."
    psql $PG_CONN -c "CREATE EXTENSION IF NOT EXISTS cartodb CASCADE;"
else
    echo "Database $dev_db_name exists already, skipping create."
fi

#### MIGRATING THE DATABASE IF MIGRATIONS HAVE NOT RUN #######################

tables_in_dev_db=$(psql $PG_CONN -qAt -d $dev_db_name -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_catalog='$dev_db_name' AND table_schema='public';")

if [[ $tables_in_dev_db < 60 ]]; then
    echo "Fewer than 60 tables found in db $dev_db_name, assuming migrations have not run yet..."
    echo "Migration output in $MIGRATION_LOG_FILE"
    bundle exec rake db:migrate --trace > $MIGRATION_LOG_FILE 2>&1
    echo "Database migrations complete."
else
    echo "Number of tables in ${dev_db_name}: $tables_in_dev_db"
    echo "Assuming migrations have run, not rerunning. To run manually, call 'rake db:migrate'"
fi

#### CREATING THE DEVELOPMENT USER ###########################################

dev_user_exists=$(psql -qAt $PG_CONN -d $DB_NAME -c "SELECT 1 FROM users WHERE username = '$DEFAULT_USER' AND email = '$EMAIL';")

if [[ -z $dev_user_exists ]]; then
    echo "Dev user with subdomain/username '${DEFAULT_USER}' and email '${EMAIL}' does not exist for database '$DB_NAME', creating..."
    /carto/cartodb/script/better_create_dev_user.sh --quiet --subdomain "$DEFAULT_USER" --password "$PASSWORD" --email "$EMAIL"
else
    echo "Dev user with subdomain/username '${DEFAULT_USER}' and email '${EMAIL}' exists in database '$DB_NAME', skipping create."
fi

#### CREATING AN ORGANIZATION IF ONE DOES NOT EXIST ##########################

/carto/cartodb/script/setup_organization.sh 

##############################################################################
#### END OF CONDITIONAL SETUP STEPS ##########################################
##############################################################################

#### STARTING PROCESSES ######################################################

echo "Starting the Resque script. Not capturing output--if you need it, change the docker/cartodb/docker-entrypoint.sh script"

bundle exec ./script/resque > /carto/resque.log 2>&1 &

echo "Starting the CartoDB Builder application..."
bundle exec thin start --threaded -p 80 -a 0.0.0.0 --threadpool-size 5
