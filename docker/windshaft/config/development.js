var config = {
    //// FEATURE FLAGS //////////////////////////////////////////////////////

    enabledFeatures: {
        // Setting: 'enabledFeatures.cdbQueryTablesFromPostgres'
        // Required: No
        // Purpose: Doesn't actually appear to be used anywhere.
        //          It's referenced in some tests, but never sourced from here.
        //cdbQueryTablesFromPostgres: true,

        // Setting: 'enabledFeatures.onTileErrorStrategy'
        // Required: No, if undefined defaults to true in api-router.js
        // Used in: createRendererFactory
        // Purpose: Feature flag for whether rendererFactory gets
        //          passed a function for onTileErrorStrategy (or undefined)
        // File: lib/cartodb/api/api-router.js
        onTileErrorStrategy: true,

        // Setting: 'enabledFeatures.layerStats'
        // Required:
        // Used in:
        // Purpose:
        // File:
        layerStats: true,

        // Setting: 'enabledFeatures.rateLimitsEnabled'
        // Required:
        // Used in:
        // Purpose:
        // File:
        rateLimitsEnabled: false,

        // Setting: 'enabledFeatures.rateLimitsByEndpoint'
        // Required:
        // Used in:
        // Purpose:
        // File:
        rateLimitsByEndpoint: {
            anonymous: false,
            'static': false,
            static_named: false,
            dataview: false,
            dataview_search: false,
            analysis: false,
            analysis_catalog: false,
            tile: false,
            attributes: false,
            named_list: false,
            named_create: false,
            named_get: false,
            named: false,
            named_update: false,
            named_delete: false,
            named_tiles: false,
        }, // end of 'enabledFeatures.rateLimitsByEndpoint'
    }, // end of 'enabledFeatures'

    // Setting: 'useProfiler'
    // Required: 
    // Used in: server_options.useProfiler, api-router's register()
    // Purpose: Tells the api router whether to include profiling headers
    // File: lib/cartodb/api/api-router.js
    //       lib/cartodb/server_options.js
    useProfiler: true,

    //// GENERAL SETTINGS ////////////////////////////////////////////////////

    // Setting: 'environment'
    // Required: Not if an arg is passed to app.js, or NODE_ENV is set
    // Used in: app.js
    // Purpose: Sets the value of process.env.NODE_ENV if unset and no arg is
    //          passed to app.js on start
    // File: app.js
    environment: 'development',

    // Setting: 'gc_interval'
    // Required: No
    // Used in: app.js
    // Purpose: Sets the interval for forcing garbage collection, 
    //          defaults to 10000
    // File: app.js
    gc_interval: 10000,

    //// HEALTH CHECK SETTINGS ///////////////////////////////////////////////

    // Setting: 'disabled_file'
    // Required: Yes
    // Used in: Somehow it's important to the health check if there's an error
    // Purpose: I can't really tell.
    // File: lib/cartodb/monitoring/health_check.js
    //       lib/cartodb/server-info-controller.js
    disabled_file: 'pids/disabled',

    // Setting: 'health'
    // Required: No, defaults to {} in lib/cartodb/server-info-controller.js
    //
    health: {
        // If enabled is true, /health responds with some info. If false, it
        // responds with just a 200 or 503
        enabled: false,
        // username: 'localhost', // can't find this used anywhere
        // z: 0, x: 0, y: 0,      // can't find this used anywhere
    }, // end of 'health'


    //// LOGGING SETTINGS ///////////////////////////////////////////////////

    log_format: ':req[X-Real-IP] :method :req[Host]:url :status '+
                ':response-time ms -> :res[Content-Type] '+
                '(:res[X-Tiler-Profiler]) (:res[X-Tiler-Errors])',

    log_filename: 'logs/node-windshaft.log',

    //// DATABASE SETTINGS //////////////////////////////////////////////////

    // Setting: 'postgres_auth_user' and 'postgres_auth_pass'
    // Required: Only for test running
    // Purpose: Used in several places in the tests
    postgres_auth_user: 'development_cartodb_user_<%= user_id %>',
    postgres_auth_pass: '<%= user_password %>',

    // Setting: 'postgres'
    // Required: Yes
    // Used in: Setting up database connections
    // Purpose: connection and config info for PG
    // File: lib/cartodb/server_options.js
    //       lib/cartodb/backends/pg_connection.js
    //       lib/cartodb/api/middlewares/db-conn-setup.js
    postgres: {
        user: "publicuser",
        password: "public",
        host: "postgis",
        port: 5432,
        pool: {
            size: 16,          // max number of resources to create at any time
            idleTimeout: 3000, // ms before an unused resource is reaped
            reapInterval: 1000 // frequency of idle resource check
        } // end of 'postgis.pool'
    }, // end of 'postgis'

    // Setting: 'redis'
    // Required: Yes
    // Used in: Setting up database connections
    // Purpose: connection and config for redis
    // File: lib/cartodb/server_options.js is the only place it's referenced
    //       directly from the config, but Redis is all over the app
    redis: {
        host: 'redis',
        port: 6379,
        max: 50,
        returnToHead: true,
        idleTimeoutMillis: 1,
        reapIntervalMillis: 1,
        unwatchOnRelease: false,
        noReadyCheck: true,
        slowQueries: {
            log: true,
            elapsedThreshold: 200,
        }, // end of 'redis.slowQueries'
        slowPool: {
            log: true,
            elapsedThreshold: 25,
        }, // end of 'redis.slowPool'
        emitter: {
            statusInterval: 5000,
        }, // end of 'redis.emitter'
    }, // end of 'redis'

    //// RENDERER SETTINGS ///////////////////////////////////////////////////
    
    renderer: {
        cache_ttl: 60000,  // ms since last access before cache item expiry
        statsInterval: 5000, // ms between each report to statsd
        mvt: {
            // If enabled, MVTs generated with PostGIS directly
            // If disabled, MVTs generated with Mapnik MVT
            usePostGIS: true
        },
        mapnik: {
            poolSize: 8,
            poolMaxWaitingClients: 64,
            metatile: 2,
            bufferSize: 64,
            snapToGrid: false,
            clipByBox2d: true,
            'cache-features': true,
            metrics: false,
            markers_symbolizer_caches: { disabled: false },
            metatileCache: { ttl: 0, deleteOnHit: false },
            formatMetatile: { png: 2, 'grid.json': 1 },
            torque: {},

            postgis: {
                user: "publicuser",
                password: "public",
                host: "postgis",
                port: 5432,
                extent: "-20037508.3,-20037508.3,20037508.3,20037508.3",
                row_limit: 65535,
                persist_connection: false,
                simplify_geometries: true,
                user_overviews: true,
                max_size: 500,
                twkb_encoding: true
            }, // end of 'renderer.mapnik.postgis'

            limits: {
                render: 0,
                cacheOnTimeout: true
            }, // end of 'renderer.mapnik.limits'
        }, // end of 'renderer.mapnik'
        http: {
            timeout: 2000,
            proxy: undefined,
            whitelist: [
                '.*',
                'http://{s}.example.com/{z}/{x}/{y}.png'
            ], // end of 'renderer.http.whitelist'
            fallbackImage: {
                type: 'fs',
                src: __dirname + '/../../assets/default-placeholder.png'
            }, // end of 'renderer.http.fallbackImage'
        }, // end of 'renderer.http'
    }, // end of 'renderer'

    //// ANALYSIS SETTINGS ///////////////////////////////////////////////////

    analysis: {
        batch: {
            inlineExecution: false,
            endpoint: 'http://127.0.0.1:8080/api/v2/sql/job',
            hostHeaderTemplate: '{{=it.username}}.localhost.lan'
        }, // end of 'analysis.batch'
        logger: {
            filename: 'logs/node-windshaft-analysis.log'
        }, // end of 'analysis.logger'
        limits: {
            moran: { timeout: 120000, maxNumberOfRows: 1e5 },
            cpu2x: { timeout: 60000 }
        } // end of 'analysis.limits'
    }, // end of 'analysis'

    //// THIRD PARTY DEPENDENCY SETTINGS /////////////////////////////////////

    mapnik_version: undefined,
    mapnik_tile_format: 'png8:m=h',

    statsd: {
        host: 'localhost',
        port: 8125,
        prefix: 'dev.',
        cacheDns: true
    }, // end of 'statsd'

    millstone: {
        cache_basedir: '/tmp/cdb-tiler-dev/millstone-dev'
    }, // end of 'millstone'

    httpAgent: {
        keepAlive: true,
        keepAliveMsecs: 1000,
        maxSockets: 25,
        maxFreeSockets: 256,
    }, // end of 'httpAgent'

    varnish: {
        host: 'localhost',
        port: 6082,
        http_port: 6081,
        purge_enabled: false,
        secret: 'xxx',
        ttl: 86400,
        layergroupTtl: 86400,
    }, // end of 'varnish'

    fastly: {
        enabled: false,
        apiKey: 'wadus_api_key',
        serviceId: 'wadus_service_id',
    }, // end of 'fastly'

    serverMetadata: {
        cdn_url: {
            http: undefined,
            https: undefined,
        }, // end of 'serverMetadata.cdn_url'
    }, // end of 'serverMetadata'

    //// NETWORK AND URL SETTINGS ///////////////////////////////////////////

    // Setting: 'host'
    // Required: I think so?
    // Used in: module.exports.bind.host in server_options.js
    // Purpose: Sets the host of the server
    // File: lib/cartodb/server_options.js
    host: '127.0.0.1',

    // Setting: 'port'
    // Required: I think so?
    // Used in: module.exports.bind.port in server_options.js
    // Purpose: Sets the port the app server listens on
    // File: lib/cartodb/server_options.js
    port: 8181,

    // Setting: 'user_from_host'
    // Required: No
    // Used in: CdbRequest function
    // Purpose: Sets the regex RE_USER_FROM_HOST, defaults to '^([^\\.]+)\\.',
    //          which extracts the first part of a dot separated hostname
    // File: lib/cartodb/models/cdb_request.js
    user_from_host: '^([^\\.]+)\\.',

    // Setting: 'routes'
    // Required: No, default values in lib/cartodb/server_options.js
    // Used in: server_options
    // Purpose: Sets the routes hash of the server_options module exports
    // File: lib/cartodb/server_options.js
    routes: undefined,

    // Setting: 'resources_url_templates'
    // Required:
    // Used in:
    // Purpose: 
    //          From the example config's inline comments: Resource URLs expose
    //          endpoints to request/retrieve metadata associated to Maps:
    //          dataviews, analysis node status. This URLs depend on how `routes`
    //          and `user_from_host` are configured: the application can be
    //          configured to accept request with the {user} in the header host
    //          or in the request path. It also might depend on the configured
    //          cdn_url via `serverMetadata.cdn_url`.
    //
    //          This template allows to make the endpoints generation more
    //          flexible, the template exposes the following params:
    //
    //          1. {{=it.cdn_url}}: used when `serverMetadata.cdn_url` exists
    //          2. {{=it.user}}: uses username extracted from `user_from_host`
    //                  or `routes`
    //          3. {{=it.port}}: uses the port from this config file
    // File: lib/cartodb/models/resource-locator.js
    resources_url_templates: {
        http: 'http://{{=it.user}}.localhost.lan:{{=it.port}}/api/v1/map',
        https: 'https://localhost.lan:{{=it.port}}/user/{{=it.user}}/api/v1/map'
    },

    //// LIMIT SETTINGS //////////////////////////////////////////////////////

    // Setting: 'uv_threadpool_size'
    // Required: No
    // Used in: app.js
    // Purpose: If present, sets the value of process.env.UV_THREADPOOL_SIZE
    //          Default size is 4, max is 128.
    //          See http://docs.libuv.org/en/latest/threadpool.html for info
    // File: app.js
    uv_threadpool_size: undefined,

    // Setting: 'maxConnections'
    // Required: No, default set to 128 in app.js
    // Used in: app.js
    // Purpose: Sets the backlog arg value to server.listen()
    //          Based on total number of filedescriptors--should be about
    //          1/8th of total filedescriptors
    // File: app.js
    maxConnections: undefined,

    // Setting: 'maxUserTemplates'
    // Required: No, defaults to unlimited (via '0') in 
    //           lib/cartodb/backends/template_maps.js
    // Used in: createTemplateMaps in api-router.js
    // Purpose: Sets the max number of user template maps
    // File: lib/cartodb/api/api-router.js
    maxUserTemplates: undefined,

    // Setting: 'mapConfigTTL'
    // Required: No, default set to 7200 in lib/cartodb/server_options.js
    // Used in: server_options
    // Purpose: Sets the value of grainstore.default_layergroup_ttl
    // File: lib/cartodb/server_options.js
    mapConfigTTL: undefined,

    //// APPARENTLY UNUSED SETTINGS //////////////////////////////////////////

    // Setting: 'socket_timeout'
    // Required: No, because it's not actually used anywhere
    // Purpose: From the example file, it says "idle socket timeout, in ms"
    //socket_timeout: 600000,

    // Setting: 'enable_cors'
    // Required: I don't think so, not actually referenced anywhere
    // Purpose: looks like a flag for turning cors on/off, but given it's not
    //          referenced anywhere else in the app code, I think it's useless
    //enable_cors: true,
    

};

module.exports = config;
