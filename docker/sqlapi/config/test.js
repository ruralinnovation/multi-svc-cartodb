//// GENERAL SETTINGS ////////////////////////////////////////////////////////
//
// 'environment' controls the following:
//   - In app.js, sets the value of NODE_ENV for the process, if:
//      - the env string was not passed to the executable explicitly, AND
//      - process.env.NODE_ENV is unset
//   - In app/server.js, prevents batch jobs from being started in test env
//   - In app/middlewares/error.js, changes how errors are handled, by env
module.exports.environment  = 'test';

// Time in ms to force garbage collection cycle. Disable by setting to -1.
module.exports.gc_interval = 10000;

// This is a flag for whether to enable node-step-profiler, which is another
// Carto node package that does start/end profiling for requests (I believe).
// Look at app/server.js and app/stats/profiler-proxy.js for more info.
module.exports.useProfiler = true;

// The idle socket timeout, in ms. 
module.exports.node_socket_timeout    = 600000; // 10 minutes in ms

// Rate limiting
module.exports.ratelimits = {
    rateLimitsEnabled: false,   // whether to ratelimit any endpoints at all
    endpoints: {                // whether to ratelimit specific endpoints, if
        query: false,           // rateLimitsEnabled is set to true
        job_create: false,
        job_get: false,
        job_delete: false
    }
};

// Config object for the /health endpoint. 
// See app/controllers/health_check_controller.js.
module.exports.health = {
    enabled: true,
    username: 'vizzuality',
    query: 'select 1'
};

//// LOG SETTINGS ////////////////////////////////////////////////////////////
//
module.exports.log_format   = '[:date] :remote-addr :method '+
                              ':req[Host]:url :status :response-time ms '+
                              '-> :res[Content-Type] (:res[X-SQLAPI-Profiler])'+
                              '(:res[X-SQLAPI-Errors])';
// Since we want logging to go to STDOUT for test runs, we are going to leave
// log_filename undefined.
///module.exports.log_filename = 'logs/cartodb-sql-api.log';
module.exports.batch_log_filename = 'logs/batch-queries.log';
module.exports.dataIngestionLogPath = 'logs/data-ingestion.log';

//// URL / HTTP SETTINGS /////////////////////////////////////////////////////
//
// If the :user param is in the base_url, that is used. Otherwise falls back
// to whatever is in the host header, using the user_from_host regex.
module.exports.base_url     = '(?:/api/:version|/user/:user/api/:version)';
module.exports.user_from_host = '^([^.]*)\\.';
module.exports.node_port    = 8080;
module.exports.node_host    = '0.0.0.0';

//// PG DATABASE SETTINGS ////////////////////////////////////////////////////
//

// Name and password for the anonymous PostgreSQL user
module.exports.db_pubuser       = 'testpublicuser';
module.exports.db_pubuser_pass  = 'public';

// DB connection params
module.exports.db_base_name     = 'cartodb_test_user_<%= user_id %>_db';
module.exports.db_user          = 'test_cartodb_user_<%= user_id %>';
module.exports.db_user_pass     = 'test_cartodb_user_<%= user_id %>_pass';
module.exports.db_host          = 'postgis';
module.exports.db_port          = '5432';
module.exports.db_batch_port    = '5432';

// DB thread pool control (for the app, not the database server)
// Max db connections in the pool, subsequent connections wait for space.
// Note that this limit does not apply to OGR-mediated database access.
module.exports.db_pool_size = 500;
module.exports.db_pool_idleTimeout = 30000; // Ms before conn removed from pool
module.exports.db_pool_reapInterval = 1000; // Ms between idle reaping runs

// Validation of access control for certain restricted Postgres entities.
// Controls code block in app/services/pg-entities-access-validator.js.
module.exports.validatePGEntitiesAccess = false;

//// REDIS DATABASE SETTINGS /////////////////////////////////////////////////
//
module.exports.redis_host   = 'redis';
module.exports.redis_port   = 6379;
module.exports.redisPool    = 50;
module.exports.redisIdleTimeoutMillis   = 1000;
module.exports.redisReapIntervalMillis  = 10;
module.exports.redisLog     = false;

// tableCache settings
module.exports.tableCacheEnabled = true; // false by default
module.exports.tableCacheMax = 8192; // max entries in query tables cache
module.exports.tableCacheMaxAge = 1000*60*10; // max age of cache items, in ms

//// FILESYSTEM AND OS SETTINGS //////////////////////////////////////////////
//
// Temp directory, must be writable by the user that runs the node app.
module.exports.tmpDir = '/tmp';
module.exports.ogr2ogrCommand = 'ogr2ogr'; // name of the ogr2ogr executable
module.exports.zipCommand = 'zip'; // name of the zip executable
module.exports.disabled_file = 'pids/disabled';

//// JOB CONTROL SETTINGS ////////////////////////////////////////////////////
//
module.exports.finished_jobs_ttl_in_seconds = 2 * 3600; // 2 hours
module.exports.batch_query_timeout = 5 * 1000;  // 5 seconds
module.exports.copy_timeout = "'5h'";
module.exports.copy_from_max_post_size = 2 * 1024 * 1024 * 1024; // 2 GB
module.exports.copy_from_max_post_size_pretty = '2 GB';

// Maximum number of jobs a user can have on the queue at one time
module.exports.batch_max_queued_jobs = 64;

// Capacity strategy, tunes how many queries can run at one time.
// Values may be: 'fixed', 'http-simple', 'http-load'
module.exports.batch_capacity_strategy = 'fixed';

// This value used when batch_capacity_strategy is 'fixed'. Defines the max
// number of simultaneous users running queries on the same host.
module.exports.batch_capacity_fixed_amount = 4;

// This value used when batch_capacity_strategy is 'http-simple' or 'http-load'.
// Defines the HTTP endpoint to use to check db host load, in order to 
// determine the number of simultaneous users running queries on the db host.
//
// If the strategy is 'http-simple', number is based on 'available_cores'.
// If the strategy is 'http-load', number is based on 'cores' and 
// 'relative_load'. 1 is the default minimum. 
//
// If no template is provided here, the application forces the strategy to
// fall back to 'fixed'.
//
// Note from Nick B, 2019-04-26: The fact that they hit port 9999 with this
// means (I believe) that they are expecting to hit a tool called pgpool on
// the postgres host. However, that tool is not mentioned in their install
// instructions, and their prod environment settings also use 'fixed', so
// I think it's either a leftover from something they never use, or is
// evidence of undocumented installation of pgpool into their postgres host.
// For now I'll leave it here, but as far as I can tell this is untested code.
// FWIW, none of their config files use anything but 'fixed' for the 
// batch_capacity_strategy setting, and I suspect it isn't covered by any
// of their unit tests either, at least not the ones in the SQLAPI repo.
module.exports.batch_capacity_http_url_template = 'http://<%= dbhost %>:9999/load';
