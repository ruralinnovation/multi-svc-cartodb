#!/bin/sh

PREPARE_REDIS=yes
PREPARE_PGSQL=yes
CARTO_PGEXT_VERSION=0.26.1

while [ -n "$1" ]; do
    if test "$1" = "--skip-pg"; then
        PREPARE_PGSQL=no
        shift; continue
    elif test "$1" = "--skip-redis"; then
        PREPARE_REDIS=no
        shift; continue
    fi
done

die() {
    msg=$1
    echo "${msg}" >&2
    exit 1
}

TESTENV=../config/environments/test.js

# Determining settings for Postgres
PGUSER="${PGUSER:-postgres}"
PGHOST=`node -e "console.log(require('${TESTENV}').db_host || '')"`
PGPORT=`node -e "console.log(require('${TESTENV}').db_port || '')"`

echo "PostgreSQL settings: Host: [$PGHOST:$PGPORT], User: [$PGUSER]"
echo "PostgreSQL version: `psql -A -t -U $PGUSER -h $PGHOST -p $PGPORT -c 'SELECT version();'`"

# Settings for the Carto users
PUBLICUSER=`node -e "console.log(require('${TESTENV}').db_pubuser || 'xxx')"`
PUBLICPASS=`node -e "console.log(require('${TESTENV}').db_pubuser_pass || 'xxx')"`

TESTUSERID=1

TESTUSER=`node -e "console.log(require('${TESTENV}').db_user || '')"`
if test -z "$TESTUSER"; then
  echo "Missing db_user from ${TESTENV}" >&2
  exit 1
fi
TESTUSER=`echo ${TESTUSER} | sed "s/<%= user_id %>/${TESTUSERID}/"`

TESTPASS=`node -e "console.log(require('${TESTENV}').db_user_pass || '')"`
TESTPASS=`echo ${TESTPASS} | sed "s/<%= user_id %>/${TESTUSERID}/"`

TEST_DB=`node -e "console.log(require('${TESTENV}').db_base_name || '')"`
if test -z "$TEST_DB"; then
  echo "Missing db_base_name from ${TESTENV}" >&2
  exit 1
fi
TEST_DB=`echo ${TEST_DB} | sed "s/<%= user_id %>/${TESTUSERID}/"`

echo ""
echo "Carto PostgreSQL DB info for testing:"
echo "    Public user/pass: [$PUBLICUSER/$PUBLICPASS]"
echo "    Test user/pass:   [$TESTUSER/$TESTPASS]"
echo "    Test database:    [$TEST_DB]"

# Settings for Redis
REDIS_HOST=`node -e "console.log(require('${TESTENV}').redis_host || '')"`
REDIS_PORT=`node -e "console.log(require('${TESTENV}').redis_port || '')"`

echo ""
echo "Redis host and port: [$REDIS_HOST:$REDIS_PORT]"

export PGUSER PGHOST PGPORT REDIS_HOST REDIS_PORT

PGCONN=" -U $PGUSER -h $PGHOST -p $PGPORT "

if test x"$PREPARE_PGSQL" = xyes; then
    dropdb $PGCONN --if-exists ${TEST_DB}
    createdb $PGCONN -T template_postgis -E UTF8 ${TEST_DB}
    export PGOPTIONS='--client-min-messages=warning'
    psql $PGCONN -q -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' ${TEST_DB}
    psql $PGCONN -q -c 'CREATE EXTENSION IF NOT EXISTS "plpythonu";' ${TEST_DB}

    LOCAL_SQL_SCRIPTS='test populated_places_simple_reduced py_sleep quota_mock'
    REMOTE_SQL_SCRIPTS='CDB_QueryStatements CDB_QueryTables CDB_CartodbfyTable CDB_TableMetadata CDB_ForeignTable CDB_UserTables CDB_ColumnNames CDB_ZoomFromScale CDB_OverviewsSupport CDB_Overviews'
    ALL_SQL_SCRIPTS="${REMOTE_SQL_SCRIPTS} ${LOCAL_SQL_SCRIPTS}"

    BASE_PGEXT_URL="https://raw.githubusercontent.com/CartoDB/cartodb-postgresql/$CARTO_PGEXT_VERSION/"
    CURL_ARGS=""
    for i in ${REMOTE_SQL_SCRIPTS}
    do
        CURL_ARGS="${CURL_ARGS}\"${BASE_PGEXT_URL}scripts-available/$i.sql\" -o support/sql/$i.sql "
    done
    echo ${CURL_ARGS} | xargs curl -L -s

    for i in ${ALL_SQL_SCRIPTS}
    do
        echo "$i"
        cat support/sql/${i}.sql |
            sed -e 's/cartodb\./public./g' -e "s/''cartodb''/''public''/g" |
            sed "s/:PUBLICUSER/${PUBLICUSER}/" |
            sed "s/:PUBLICPASS/${PUBLICPASS}/" |
            sed "s/:TESTUSER/${TESTUSER}/" |
            sed "s/:TESTPASS/${TESTPASS}/" |
            psql $PGCONN -q -v ON_ERROR_STOP=1 ${TEST_DB} > /dev/null || exit 1
    done
fi
