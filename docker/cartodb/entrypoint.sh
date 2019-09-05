#!/bin/bash

#### SETTINGS FROM ENVIRONMENT ###############################################

export CARTO_ENV=${CARTO_ENV:-development}
export RAILS_ENV=${CARTO_ENV}
CARTODB_LISTEN_PORT=${CARTODB_LISTEN_PORT:-3000}
STACK_SCHEME=${STACK_SCHEME:-https}
SSM_PARAM_SSL_CERT=${SSM_PARAM_SSL_CERT}
SSM_PARAM_SSL_KEY=${SSM_PARAM_SSL_KEY}

#### SCRIPT SETTINGS #########################################################

PG_READY=""
PG_READY_WAIT_SECONDS=5
COUNT=0
DB_CONFIG_FILE=/carto/cartodb/config/database.yml
APP_CONFIG_FILE=/carto/cartodb/config/app_config.yml
MIGRATION_LOG_FILE=/db_migration_output.log

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

# Usage: `value_from_parameter_json "$JSON_FROM_AWS_SSM_GET_PARAMETER"`
function ssm_value_from_parameter {
    local response=$(aws ssm get-parameter --output=json --with-decryption --name "$1")
    local val=$(echo $response | python3 -c 'import json,sys;x=json.load(sys.stdin);print(repr(x["Parameter"]["Value"]));')
    printf -- "$val"
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
        echo "--- Postgres unavailable, sleeping $PG_READY_WAIT_SECONDS seconds"
        sleep $PG_READY_WAIT_SECONDS
    fi
done

##############################################################################
#### PATCHES TO THE CARTO CODEBASES ##########################################
##############################################################################

#### FORCING HTTPS IN DEV ####################################################

if [[ $STACK_SCHEME = 'https' ]]; then
    CARTO_DB_INIT_FILE="/carto/cartodb/config/initializers/carto_db.rb"
    echo "--- Changing the self.use_https? method in $CARTO_DB_INIT_FILE to return true, so https works in dev."
    sed -i "/def self.use_https\?/,/end/c\  def self.use_https?\n    true\n  end" $CARTO_DB_INIT_FILE
else
    echo "--- STACK_SCHEME was not 'https', so not munging carto_db.rb initializer..."
fi

#### ALLOWING THE /diagnosis ENDPOINT ########################################
# By default there is a line of code in app/controllers/home_controller.rb
# that only allows you to view the /diagnosis endpoint if your config has
# cartodb_com_hosted set to true. We want to remove that line if we need to
# see the endpoint successfully.

ALLOW_DIAGNOSIS=${CARTODB_ALLOW_DIAGNOSIS:-false}
HOME_CONTROLLER="/carto/cartodb/app/controllers/home_controller.rb"
LINE_TO_REMOVE="return head(400) if Cartodb.config\[:cartodb_com_hosted\] == false"

if [[ $ALLOW_DIAGNOSIS = 'true' ]]; then
    echo "--- Removing the line that causes /diagnosis to return 400"
    sed -i -e "/${LINE_TO_REMOVE}/d" $HOME_CONTROLLER
else
    echo "--- CARTODB_ALLOW_DIAGNOSIS is not 'true', not munging home_controller.rb"
fi

#### TURNING OFF MX VALIDATION FOR EMAIL ADDRESSES ###########################
# The gem they use to do email address validation is bad as of 2019-08-15.
# See https://github.com/afair/email_address/issues/43 for context.
# Turning MX validation off since it behaves erratically inside Docker containers.

echo "--- Changing the email_address.rb initializer to not do MX validation"
MXVALID_INIT_FILE="/carto/cartodb/config/initializers/email_address.rb"
FIND_PATTERN="configure(local_format: :conventional)"
REPLACEMENT="configure(local_format: :conventional, host_validation: :syntax)"
if [[ -f $MXVALID_INIT_FILE ]]; then
    sed -i "s/${FIND_PATTERN}/${REPLACEMENT}/" $MXVALID_INIT_FILE
fi

##############################################################################
#### CREATE DATABASES AND USERS ##############################################
##############################################################################

#### CREATING THE DATABASE IF IT DOES NOT EXIST ##############################

cd /carto/cartodb

dev_db_exists=$(psql $PG_CONN -lqt | cut -d \| -f 1 | grep "$DB_NAME")
dev_db_name=$DB_NAME

if [[ -z $dev_db_exists ]]; then
    echo "--- Creating database $dev_db_name..."
    bundle exec rake db:create
    echo "--- Installing cartodb extension to db $dev_db_name..."
    psql $PG_CONN -c "CREATE EXTENSION IF NOT EXISTS cartodb CASCADE;"
else
    echo "--- Database $dev_db_name exists already, skipping create."
fi

#### MIGRATING THE DATABASE IF MIGRATIONS HAVE NOT RUN #######################

tables_in_dev_db=$(psql $PG_CONN -qAt -d $dev_db_name -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_catalog='$dev_db_name' AND table_schema='public';")

if [[ $tables_in_dev_db < 60 ]]; then
    echo "--- Fewer than 60 tables found in db $dev_db_name, assuming migrations have not run yet..."
    echo "--- Migration output in $MIGRATION_LOG_FILE"
    bundle exec rake db:migrate --trace > $MIGRATION_LOG_FILE 2>&1
    echo "--- Database migrations complete."
else
    echo "--- Number of tables in ${dev_db_name}: $tables_in_dev_db"
    echo "--- Assuming migrations have run, not rerunning. To run manually, call 'rake db:migrate'"
fi

#### CREATE DEV USER AND DEV ORG/USER ########################################

/opt/bin/create-user-and-org.sh

##############################################################################
#### START SERVICES ##########################################################
##############################################################################

cd /carto/cartodb
echo "--- Running restore_redis script..."
bundle exec script/restore_redis
echo "--- Starting Resque process, logging to /carto/cartodb/resque.log..."
bundle exec script/resque > /carto/cartodb/resque.log 2>&1 &

echo "--- Recreating API keys in database and Redis, so SQL API is authenticated..."
echo 'DELETE FROM api_keys;' | psql $PG_CONN -t -d $DB_NAME
bundle exec rake carto:api_key:create_default

echo "--- Starting rails server..."
bundle exec thin start --threaded -p $CARTODB_LISTEN_PORT -a 0.0.0.0 --threadpool-size 5 > /carto/cartodb/rails.log 2>&1 &

echo "--- Tailing /dev/null to keep the container running..."
tail -f /dev/null
