var config = {
    //////////////////////////////////////////////////////////////////////////
    // Scalar configuration values                                          //
    //////////////////////////////////////////////////////////////////////////

    environment:         process.env.SQLAPI_ENVIRONMENT || 'development',
    gc_interval:         10000,
    useProfiler:         true,
    node_socket_timeout: 600000,

    log_format: '[:date] :remote-addr :method '+
                ':req[Host]:url :status :response-time ms '+
                '-> :res[Content-Type] (:res[X-SQLAPI-Profiler])'+
                '(:res[X-SQLAPI-Errors])',

    log_filename:           'logs/cartodb-sql-api.log',
    batch_log_filename:     'logs/batch-queries.log',
    dataIngestionLogPath:   'logs/data-ingestion.log',

    base_url:       '(?:/api/:version|/user/:user/api/:version)',
    user_from_host: '^([^\\.]+)\\.',
    node_port:      process.env.SQLAPI_LISTEN_PORT || 8080,
    node_host:      process.env.SQLAPI_LISTEN_IP || '0.0.0.0',

    db_user:         'development_cartodb_user_<%= user_id %>',
    db_user_pass:    '<%= user_password %>',
    db_pubuser:      'publicuser',
    db_pubuser_pass: 'public',

    db_base_name:   'cartodb_dev_user_<%= user_id %>_db',
    db_host:        process.env.SQLAPI_POSTGIS_HOST || 'postgis',
    db_port:        process.env.SQLAPI_POSTGIS_PORT || '5432',
    db_batch_port:  process.env.SQLAPI_POSTGIS_PORT || '5432',

    db_pool_size:               500,
    db_pool_idleTimeout:        30000,
    db_pool_reapInterval:       1000,
    validatePGEntitiesAccess:   false,

    redis_host:                 process.env.SQLAPI_REDIS_HOST || 'redis',
    redis_port:                 process.env.SQLAPI_REDIS_PORT || '6379',
    redisPool:                  50,
    redisIdleTimeoutMillis:     100,
    redisReapIntervalMillis:    10,
    redisLog:                   false,

    tableCacheEnabled:  false,
    tableCacheMax:      8192,
    tableCacheMaxAge:   1000*60*10,

    tmpDir:         '/tmp',
    ogr2ogrCommand: 'ogr2ogr',
    zipCommand:     'zip',
    disabled_file:  'pids/disabled',

    finished_jobs_ttl_in_seconds:   2 * 3600,
    batch_query_timeout:            12 * 3600 * 1000,
    copy_timeout:                   "'5h'",
    copy_from_max_post_size:        2 * 1024 * 1024 * 1024,
    copy_from_max_post_size_pretty: '2 GB',

    batch_max_queued_jobs:              64,
    batch_capacity_strategy:            'fixed',
    batch_capacity_fixed_amount:        4,
    batch_capacity_http_url_template:   'http://<%= dbhost %>:9999/load',

    //////////////////////////////////////////////////////////////////////////
    // Nested configuration objects                                         //
    //////////////////////////////////////////////////////////////////////////

    db_keep_alive: {
        enabled: true,
        initialDelay: 5000
    },

    cache: {
        ttl:         60 * 60 * 24 * 365,
        fallbackTtl: 60 * 5
    },

    health: {
        enabled:    true,
        username:   'development',
        query:      'SELECT 1'
    },

//    statsd: {
//        host: 'localhost',
//        port: 8125,
//        prefix: 'dev.:host.',
//        cacheDns: true
//    },

    ratelimits: {
        rateLimitsEnabled: false,
        endpoints: {
            query:          false,
            query_format:   false,
            job_create:     false,
            job_get:        false,
            job_delete:     false,
            copy_from:      false,
            copy_to:        false
        }
    }
};

module.exports = config;
