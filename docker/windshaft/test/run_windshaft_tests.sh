#!/bin/bash
trap "exit 1" TERM
export TOP_PID=$$

#### FUNCTIONS A #############################################################

# Print the usage line.
function display_usage() {
    printf "\nUsage: $(basename "$0") [-h|--help]\n"
    printf "       $(basename "$0") [unit] [acceptance] [integration]\n\n"
    printf "Flags:\n"
    printf "    --skip-pg-setup      Do not set up the Postgres test db\n"
    printf "    --skip-redis-setup   Do not set up the Redis test db\n"
    printf "    --skip-tests         Do not run tests\n"
    printf "    --with-coverage      Produce coverage report\n"
    printf "    --config PATH        Path to alternate test.js\n\n"
}

# This is necessary to kill the script from within a function, which by 
# default does not have access to the parent's PID via the $$ bash var.
function echo_and_exit() {
    echo "$1" >&2           # echo first arg to STDERR
    kill -s TERM $TOP_PID   # send SIGTERM to script process id
}

#### CLI OPTIONS #############################################################

PREPARE_REDIS=yes
PREPARE_PGSQL=yes
RUN_TESTS=yes
COVERAGE=no
DEFAULT_TESTS="unit acceptance integration"
TESTS=""
TESTENV="../config/environments/test.js"

while [ -n "$1" ]; do
    if [[ ($1 == "-h") || ($1 == "--help") ]]; then
        display_usage; exit 0
    elif [[ $1 == "--skip-pg-setup" ]]; then
        PREPARE_PGSQL=no; shift; continue
    elif [[ $1 == "--skip-redis-setup" ]]; then
        PREPARE_REDIS=no; shift; continue
    elif [[ $1 == "--skip-tests" ]]; then
        RUN_TESTS=no; shift; continue
    elif [[ $1 == "--with-coverage" ]]; then
        COVERAGE=yes; shift; continue
    elif [[ $1 == "--config" ]]; then
        shift; TESTENV=$1; shift; continue
    else    # if we get here these are assumed to be tests to run
        TESTS+=" $1"; shift; continue
    fi
done

# If no tests were specifically named, use defaults
TESTS="${TESTS:-$DEFAULT_TESTS}"

#### ENV FILE FUNCTION AND VALIDATION ########################################

if [[ ! -r $TESTENV ]]; then
  echo_and_exit "Error: Cannot read test env config file ${TESTENV}"
fi

# Usage: from_test_env "configKey" [ "defaultVal" ]
function from_test_env() {
    # Get the value from the file
    local val=`node -e "console.log(require('${TESTENV}').${1} || '')"`

    # Check to see if we got a value from the file or not, apply default
    # value if one was passed in.
    if [[ -z $val ]]; then
        if [[ -z ${2+x} ]]; then    # No default value passed in
            echo_and_exit "Exiting $0: No '$1' value found in ${TESTENV}"
        else
            val=$2
        fi
    fi

    echo $val
}

#### VARIABLES / CONSTANTS ###################################################

CARTO_PGEXT_VERSION="${CARTO_PGEXT_VERSION:-0.26.1}"
PGUSER="${PGUSER:-postgres}"
PGHOST=$(from_test_env "postgres.host")
PGPORT=$(from_test_env "postgres.port")
PUBLICUSER=$(from_test_env "postgres.user")
PUBLICPASS=$(from_test_env "postgres.password")
REDIS_HOST=$(from_test_env "redis.host")
REDIS_PORT=$(from_test_env "redis.port")
TESTUSERID=1
TESTUSER=`echo $(from_test_env "postgres_auth_user") | sed "s/<%= user_id %>/${TESTUSERID}/"`
TESTPASS=`echo $(from_test_env "postgres_auth_pass") | sed "s/<%= user_id %>/${TESTUSERID}/"`
TEST_DB="${TESTUSER}_db"

echo ""
echo "Settings found by $0:"
echo ""
echo "PostgreSQL: Host: [$PGHOST:$PGPORT], User: [$PGUSER]"
echo "PostgreSQL version: `psql -A -t -U $PGUSER -h $PGHOST -p $PGPORT -c 'SELECT version();'`"
echo ""
echo "Redis host and port: [$REDIS_HOST:$REDIS_PORT]"
echo ""
echo "Carto PostgreSQL DB info for testing:"
echo "    Carto PG extension version: [$CARTO_PGEXT_VERSION]"
echo "    Public user/pass: [$PUBLICUSER/$PUBLICPASS]"
echo "    Test user/pass:   [$TESTUSER/$TESTPASS]"
echo "    Test database:    [$TEST_DB]"
echo ""

#### POSTGRESQL TEST DATABASE PREP ###########################################

PGCONN=" -U $PGUSER -h $PGHOST -p $PGPORT "
export PGOPTIONS="--client-min-messages=warning"

if [[ $PREPARE_PGSQL == "yes" ]]; then
    echo "Preparing the PostgreSQL test environment:"
    set -x
    dropdb $PGCONN --if-exists ${TEST_DB}
    createdb $PGCONN -T template_postgis -EUTF8 ${TEST_DB}
    psql $PGCONN -q -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' ${TEST_DB}
    psql $PGCONN -q -c 'CREATE EXTENSION IF NOT EXISTS "plpythonu";' ${TEST_DB}
    psql $PGCONN -q -c 'CREATE EXTENSION IF NOT EXISTS "cartodb";' ${TEST_DB}

    set +x
    LOCAL_SQL_SCRIPTS='analysis_catalog windshaft.test gadm4 '
    LOCAL_SQL_SCRIPTS+='countries_null_values '
    LOCAL_SQL_SCRIPTS+='ported/populated_places_simple_reduced '
    LOCAL_SQL_SCRIPTS+='cdb_analysis_check cdb_invalidate_varnish'
    REMOTE_SQL_SCRIPTS='CDB_SearchPath'
    ALL_SQL_SCRIPTS="${REMOTE_SQL_SCRIPTS} ${LOCAL_SQL_SCRIPTS}"

    BASE_PGEXT_URL="https://raw.githubusercontent.com/CartoDB/"
    BASE_PGEXT_URL+="cartodb-postgresql/"
    BASE_PGEXT_URL+="$CARTO_PGEXT_VERSION"

    CURL_ARGS=""

    for i in ${REMOTE_SQL_SCRIPTS}
    do
        CURL_ARGS+="\"${BASE_PGEXT_URL}/scripts-available/$i.sql\""
        CURL_ARGS+=" -o support/sql/$i.sql"
    done

    echo ""
    echo "Downloading remote SQL files from ${BASE_PGEXT_URL}..."

    set -x; echo ${CURL_ARGS} | xargs curl -L -s; set +x

    echo ""
    echo "Running SQL scripts against test database ${TEST_DB}:"

    for i in ${ALL_SQL_SCRIPTS}
    do
        echo "    $i"
        cat support/sql/${i}.sql |
            sed -e 's/cartodb\./public./g' -e "s/''cartodb''/''public''/g" |
            sed "s/:PUBLICUSER/${PUBLICUSER}/" |
            sed "s/:PUBLICPASS/${PUBLICPASS}/" |
            sed "s/:TESTUSER/${TESTUSER}/" |
            sed "s/:TESTPASS/${TESTPASS}/" |
            psql $PGCONN -q -v ON_ERROR_STOP=1 ${TEST_DB} > /dev/null || exit 1
    done
fi

#### REDIS TEST DATABASE PREP ################################################

REDIS_CONN=" -h ${REDIS_HOST} -p ${REDIS_PORT}"

if [[ $PREPARE_REDIS == "yes" ]]; then
    echo ""
    echo "Preparing the Redis test environment:"

    echo "    Creating a rails:users:localhost entry..."
    cat <<EOF | redis-cli $REDIS_CONN -n 50
        HMSET rails:users:localhost id ${TESTUSERID} \
                            database_name "${TEST_DB}" \
                            database_host localhost \
                            map_key 1234
        SADD rails:users:localhost:map_key 1235
EOF

    echo "    Creating a user configured as with cartodb-2.5.0+..."
    cat <<EOF | redis-cli $REDIS_CONN  -n 5
        HMSET rails:users:cartodb250user id ${TESTUSERID} \
                                 database_name "${TEST_DB}" \
                                 database_host "localhost" \
                                 database_password "${TESTPASS}" \
                                 map_key 4321
EOF

    echo "    Creating rails:${TEST_DB}:my_table and :test_table_private1..."
    cat <<EOF | redis-cli $REDIS_CONN -n 0
        HSET rails:${TEST_DB}:my_table infowindow "this, that, the other"
        HSET rails:${TEST_DB}:test_table_private_1 privacy "0"
EOF

    echo ""
    echo "Creating API keys in Redis:"

    echo "    Creating master API key..."
    cat <<EOF | redis-cli $REDIS_CONN -n 5
        HMSET api_keys:localhost:1234 \
            user "localhost" \
            type "master" \
            grants_sql "true" \
            grants_maps "true" \
            database_role "${TESTUSER}" \
            database_password "${TESTPASS}"
EOF

    echo "    Creating default public API key..."
    cat <<EOF | redis-cli $REDIS_CONN -n 5
        HMSET api_keys:localhost:default_public \
            user "localhost" \
            type "default" \
            grants_sql "true" \
            grants_maps "true" \
            database_role "test_windshaft_publicuser" \
            database_password "public"
EOF
    echo "    Creating API key 'regular1'..."
    cat <<EOF | redis-cli $REDIS_CONN -n 5
        HMSET api_keys:localhost:regular1 \
            user "localhost" \
            type "regular" \
            grants_sql "true" \
            grants_maps "true" \
            database_role "test_windshaft_regular1" \
            database_password "regular1"
EOF

    echo "    Creating API key 'regular2'..."
    cat <<EOF | redis-cli $REDIS_CONN -n 5
        HMSET api_keys:localhost:regular2 \
            user "localhost" \
            type "regular" \
            grants_sql "true" \
            grants_maps "false" \
            database_role "test_windshaft_publicuser" \
            database_password "public"
EOF

    echo "    Creating master API key for cartodb250user..."
    cat <<EOF | redis-cli $REDIS_CONN -n 5
        HMSET api_keys:cartodb250user:4321 \
            user "localhost" \
            type "master" \
            grants_sql "true" \
            grants_maps "true" \
            database_role "${TESTUSER}" \
            database_password "${TESTPASS}"
EOF

    echo "    Creating default public API key for cartodb250user..."
    cat <<EOF | redis-cli $REDIS_CONN -n 5
        HMSET api_keys:cartodb250user:default_public \
        user "localhost" \
        type "default" \
        grants_sql "true" \
        grants_maps "true" \
        database_role "test_windshaft_publicuser" \
        database_password "public"
EOF

fi # end of if PREPARE_REDIS

if [[ ($PREPARE_PGSQL == "yes") || ($PREPARE_REDIS == "yes") ]]; then
    printf "\nFinished preparing test environment.\n"
fi

if [[ $RUN_TESTS == "yes" && -n $TESTS ]]; then
    printf "Running tests...\n\n"

    PATH="/carto/Windshaft-cartodb/node_modules/.bin/:$PATH"

    for i in ${TESTS}
    do
        echo "Running $i tests:"
        _mocha -c -u tdd -t 5000 --exit $i
    done
fi
