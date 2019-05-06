#!/bin/bash
trap "exit 1" TERM
export TOP_PID=$$

#### CLI OPTIONS ############################################################

PREPARE_REDIS=yes
PREPARE_PGSQL=yes
TESTENV=../config/environments/test.js

while [ -n "$1" ]; do
    if test "$1" = "--skip-pg"; then
        PREPARE_PGSQL=no
        shift; continue
    elif test "$1" = "--skip-redis"; then
        PREPARE_REDIS=no
        shift; continue
    elif test "$1" = "--config"; then
        shift;
        TESTENV=$1
        shift; continue
    fi
done

#### FUNCTIONS ###############################################################

function echo_and_exit() {
    echo "$1" >&2           # echo first arg to STDERR
    kill -s TERM $TOP_PID   # send SIGTERM to script process id
}

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
PGHOST=$(from_test_env "db_host")
PGPORT=$(from_test_env "db_port")
PUBLICUSER=$(from_test_env "db_pubuser")
PUBLICPASS=$(from_test_env "db_pubuser_pass")
REDIS_HOST=$(from_test_env "redis_host")
REDIS_PORT=$(from_test_env "redis_port")
TESTUSER=$(from_test_env "db_user")
TESTUSERID=1
TESTUSER=`echo ${TESTUSER} | sed "s/<%= user_id %>/${TESTUSERID}/"`
TESTPASS=$(from_test_env "db_user_pass")
TESTPASS=`echo ${TESTPASS} | sed "s/<%= user_id %>/${TESTUSERID}/"`
TEST_DB=$(from_test_env "db_base_name")
TEST_DB=`echo ${TEST_DB} | sed "s/<%= user_id %>/${TESTUSERID}/"`

echo ""
echo "Settings found by $0: "
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

#### SCRIPT BODY #############################################################

PGCONN=" -U $PGUSER -h $PGHOST -p $PGPORT "
export PGOPTIONS='--client-min-messages=warning'

if [[ $PREPARE_PGSQL == "yes" ]]; then
    echo "Preparing the PostgreSQL test environment:"
    set -x
    dropdb $PGCONN --if-exists ${TEST_DB}
    createdb $PGCONN -T template_postgis -E UTF8 ${TEST_DB}
    psql $PGCONN -q -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' ${TEST_DB}
    psql $PGCONN -q -c 'CREATE EXTENSION IF NOT EXISTS "plpythonu";' ${TEST_DB}
    psql $PGCONN -q -c 'CREATE EXTENSION IF NOT EXISTS "cartodb";' ${TEST_DB}

    set +x
    LOCAL_SQL_SCRIPTS='test populated_places_simple_reduced py_sleep quota_mock'
    REMOTE_SQL_SCRIPTS='CDB_SearchPath'
#    REMOTE_SQL_SCRIPTS='CDB_SearchPath CDB_QueryStatements CDB_QueryTables '
#    REMOTE_SQL_SCRIPTS+='CDB_CartodbfyTable CDB_TableMetadata CDB_ForeignTable '
#    REMOTE_SQL_SCRIPTS+='CDB_UserTables CDB_ColumnNames CDB_ZoomFromScale '
#    REMOTE_SQL_SCRIPTS+='CDB_OverviewsSupport CDB_Overviews'
    ALL_SQL_SCRIPTS="${REMOTE_SQL_SCRIPTS} ${LOCAL_SQL_SCRIPTS}"
    BASE_PGEXT_URL="https://raw.githubusercontent.com/CartoDB/cartodb-postgresql/$CARTO_PGEXT_VERSION/"
    CURL_ARGS=""

    for i in ${REMOTE_SQL_SCRIPTS}
    do
        CURL_ARGS="${CURL_ARGS}\"${BASE_PGEXT_URL}scripts-available/$i.sql\" -o support/sql/$i.sql "
    done
    echo ""
    echo "Downloading remote SQL files from ${BASE_PGEXT_URL}..."

    echo ${CURL_ARGS} | xargs curl -L -s

    echo ""
    echo "Running SQL scripts against test database ${TEST_DB}"

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

if [[ $PREPARE_REDIS == "yes" ]]; then
    echo ""
    echo "Preparing the Redis test environment:"

    echo "Deleting previous publicuser..."
    cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
HDEL rails:users:vizzuality database_host
HDEL rails:users:vizzuality database_publicuser
EOF

    echo "Creating a rails:users:vizzuality entry..."
  cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
HMSET rails:users:vizzuality \
 id 1 \
 database_name ${TEST_DB} \
 database_host ${PGHOST} \
 map_key 1234
SADD rails:users:vizzuality:map_key 1235
EOF

    echo "Creating a rails:users:cartodb250user entry..."
  cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
HMSET rails:users:cartodb250user \
 id ${TESTUSERID} \
 database_name ${TEST_DB} \
 database_host ${PGHOST} \
 database_password ${TESTPASS} \
 map_key 1234
SADD rails:users:cartodb250user:map_key 1234
EOF

    echo "Creating a rails:oauth_access_tokens entry..."
  cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 3
HMSET rails:oauth_access_tokens:l0lPbtP68ao8NfStCiA3V3neqfM03JKhToxhUQTR \
 consumer_key fZeNGv5iYayvItgDYHUbot1Ukb5rVyX6QAg8GaY2 \
 consumer_secret IBLCvPEefxbIiGZhGlakYV4eM8AbVSwsHxwEYpzx \
 access_token_token l0lPbtP68ao8NfStCiA3V3neqfM03JKhToxhUQTR \
 access_token_secret 22zBIek567fMDEebzfnSdGe8peMFVFqAreOENaDK \
 user_id 1 \
 time sometime
EOF

    echo "Creating a rails:users:cartofante entry..."
  cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
HMSET rails:users:cartofante \
 id 2 \
 database_name ${TEST_DB} \
 database_host ${PGHOST} \
 database_password test_cartodb_user_2_pass \
 map_key 4321
SADD rails:users:fallback_1:map_key 4321
EOF

    echo "Deleting previous jobs..."
cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
EVAL "return redis.call('del', 'defaultKey', unpack(redis.call('keys', ARGV[1])))" 0 "batch:jobs:*"
EOF

    echo "Deleting the job queue..."
cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
DEL batch:queues:localhost
EOF

    echo "Deleting the user index..."
cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
DEL batch:users:vizzuality
EOF

# User: vizzuality

# API Key Default public
    echo "Creating the default public API key..."
cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
HMSET api_keys:vizzuality:default_public \
  user "vizzuality" \
  type "default" \
  grants_sql "true" \
  database_role "testpublicuser" \
  database_password "public"
EOF

# API Key Master
    echo "Creating the master API key..."
cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
HMSET api_keys:vizzuality:1234 \
  user "vizzuality" \
  type "master" \
  grants_sql "true" \
  database_role "${TESTUSER}" \
  database_password "${TESTPASS}"
EOF

# API Key Regular1
    echo "Creating a normal API key at api_keys:vizzuality:regular1..."
cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
  HMSET api_keys:vizzuality:regular1 \
    user "vizzuality" \
    type "regular" \
    grants_sql "true" \
    database_role "regular_1" \
    database_password "regular1"
EOF

# API Key Regular1
    echo "Creating a normal API key at api_keys:vizzuality:regular2..."
cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
  HMSET api_keys:vizzuality:regular2 \
    user "vizzuality" \
    type "regular" \
    grants_sql "true" \
    database_role "regular_2" \
    database_password "regular2"
EOF

# User: cartodb250user

# API Key Default public
   echo "Creating a default public key at api_keys:cartodb250user:default_public..."
cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
HMSET api_keys:cartodb250user:default_public \
  user "cartodb250user" \
  type "default" \
  grants_sql "true" \
  database_role "testpublicuser" \
  database_password "public"
EOF

# API Key Master
    echo "Creating a master API key at api_keys:cartodb250user:1234"
cat <<EOF | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -n 5
HMSET api_keys:cartodb250user:1234 \
  user "cartodb250user" \
  type "master" \
  grants_sql "true" \
  database_role "${TESTUSER}" \
  database_password "${TESTPASS}"
EOF
fi

echo ""
echo "Congrats, you're ready to run the tests."
echo ""
