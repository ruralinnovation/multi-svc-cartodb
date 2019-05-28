var config = {
    //// UNKNOWN SETTINGS ///////////////////////////////////////////////////

    // Setting: cache_enabled
    // Required: Unclear.
    // Purpose: Unclear, not referenced directly anywhere but in server_options,
    //          but that may mean it's getting passed to the node app in a way
    //          that causes it to be used by some external dependency.
    // Used in: Exported object from server_options.js, sets value of
    //          cache_enabled key. No default provided.
    // File: lib/cartodb/server_options.js
    // Values from sources:
    //      official:   true
    //      sverhoeven: false
    cache_enabled: false,

    //// FEATURE FLAGS //////////////////////////////////////////////////////

    enabledFeatures: {
        // Setting: 'enabledFeatures.cdbQueryTablesFromPostgres'
        // Required:
        // Purpose:
        // Notes from official: "whether the affected tables for a given SQL
        //      must query directly postgresql or use the SQL API"
        // Values from sources:
        //      official:   true
        //      sverhoeven: true
        cdbQueryTablesFromPostgres: true,

        // Setting: 'enabledFeatures.onTileErrorStrategy'
        // Required: No, if undefined defaults to true in api-router.js
        // Used in: createRendererFactory
        // Purpose: Feature flag for whether rendererFactory gets
        //          passed a function for onTileErrorStrategy (or undefined)
        // File: lib/cartodb/api/api-router.js
        // Notes from official: "whether it should intercept tile render errors
        //      an act based on them, enabled by default."
        // Values from sources:
        //      official:   true
        //      sverhoeven: true
        onTileErrorStrategy: true,

        // Setting: 'enabledFeatures.layerStats'
        // Required:
        // Used in:
        // Purpose:
        // File:
        // Notes from official: "whether in mapconfig is available stats &
        //      metadata for each layer"
        // Values from sources:
        //      official:   true
        //      sverhoeven: NOT PRESENT
        layerStats: true,

        // Setting: 'enabledFeatures.rateLimitsEnabled'
        // Required:
        // Used in:
        // Purpose:
        // File:
        // Values from sources:
        //      official:   false
        //      sverhoeven: NOT PRESENT
        rateLimitsEnabled: false,

        // Setting: 'enabledFeatures.rateLimitsByEndpoint'
        // Required:
        // Used in:
        // Purpose:
        // File:
        // Values from sources:
        //      official:   All subsettings are 'false'
        //      sverhoeven: NOT PRESENT
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
    // Values from sources:
    //      official:   true
    //      sverhoeven: true
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
    // Values from sources:
    //      official:   10000
    //      sverhoeven: NOT PRESENT
    gc_interval: 10000,

    //// HEALTH CHECK SETTINGS ///////////////////////////////////////////////

    // Setting: 'disabled_file'
    // Required: Yes
    // Used in: Somehow it's important to the health check if there's an error
    // Purpose: I can't really tell.
    // File: lib/cartodb/monitoring/health_check.js
    //       lib/cartodb/server-info-controller.js
    // Values from sources:
    //      official:   'pids/disabled'
    //      sverhoeven: 'pids/disabled'
    disabled_file: 'pids/disabled',

    // Setting: 'health'
    // Required: No, defaults to {} in lib/cartodb/server-info-controller.js
    health: {
        // Setting: 'health.enabled'
        // Nick's notes: If enabled is true, /health responds with some info.
        //      If false, it responds with just a 200 or 503
        // Notes from official: "Settings for the health check available at /health"
        // Values from sources:
        //      official:   false
        //      sverhoeven: false
        enabled: false,
        // Setting: 'health.username'
        // username: 'localhost', // can't find this used anywhere
        // Setting: 'health.z', 'health.x', 'health.y'
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
    // Notes from sverhoeven: "Parameters to pass to datasource plugin of mapnik
    //      See http://github.com/mapnik/mapnik/wiki/PostGIS
    // File: lib/cartodb/server_options.js
    //       lib/cartodb/backends/pg_connection.js
    //       lib/cartodb/api/middlewares/db-conn-setup.js
    postgres: {
        // Setting: 'postgres.type'
        // Values from sources:
        //      official:   NOT PRESENT
        //      sverhoeven: "postgis"
        type: "postgis",

        // Setting: 'postgres.user'
        // Values from sources:
        //      official:   "publicuser"
        //      sverhoeven: "publicuser"
        user: "publicuser",

        // Setting: 'postgres.password'
        // Values from sources:
        //      official:   "public"
        //      sverhoeven: "public"
        password: "public",

        // Setting: 'postgres.host'
        // Values from sources:
        //      official:   "127.0.0.1"
        //      sverhoeven: "127.0.0.1"
        host: "postgis",

        // Setting: 'postgres.port'
        // Values from sources:
        //      official:   5432
        //      sverhoeven: 5432
        port: 5432,

        // Setting: 'postgres.extent'
        // Values from sources:
        //      official:   NOT PRESENT
        //      sverhoeven: "-20037508.3,-20037508.3,20037508.3,20037508.3"
        extent: "-20037508.3,-20037508.3,20037508.3,20037508.3",

        // Setting: 'postgres.row_limit'
        // Values from sources:
        //      official:   NOT PRESENT
        //      sverhoeven: 65535
        row_limit: 65535,

        // Setting: 'postgres.simplify_geometries'
        // Values from sources:
        //      official:   NOT PRESENT
        //      sverhoeven: true
        simplify_geometries: true,

        // Setting: 'postgres.use_overviews'
        // Values from sources:
        //      official:   NOT PRESENT
        //      sverhoeven: true
        use_overviews: true,

        // Setting: 'postgres.persist_connection'
        // Values from sources:
        //      official:   NOT PRESENT
        //      sverhoeven: true
        persist_connection: false,

        // Setting: 'postgres.max_size'
        // Values from sources:
        //      official:   NOT PRESENT
        //      sverhoeven: 500
        max_size: 500,

        // Setting: 'postgres.pool'
        // Values from sources:
        //      official:   SEE BELOW
        //      sverhoeven: NOT PRESENT
        pool: {
            // Setting: 'postgres.pool.size'
            // Value from official: 16
            size: 16,          // max number of resources to create at any time

            // Setting: 'postgres.pool.idleTimeout'
            // Value from official: 3000
            idleTimeout: 3000, // ms before an unused resource is reaped

            // Setting: 'postgres.pool.reapInterval'
            // Value from official: 1000
            reapInterval: 1000 // frequency of idle resource check
        } // end of 'postgres.pool'
    }, // end of 'postgres'

    // Setting: 'redis'
    // Required: Yes
    // Used in: Setting up database connections
    // Purpose: connection and config for redis
    // File: lib/cartodb/server_options.js is the only place it's referenced
    //       directly from the config, but Redis is all over the app
    redis: {
        // Setting: 'redis.host'
        // Values from sources:
        //      official:   '127.0.0.1'
        //      sverhoeven: '127.0.0.1'
        host: 'redis',

        // Setting: 'redis.port'
        // Values from sources:
        //      official:   6379
        //      sverhoeven: 6379
        port: 6379,

        // Setting: 'redis.max'
        // Notes from official: "Max number of connections in each pool. Users 
        //      will be put on a queue when the limit is hit. Set to maxConnection 
        //      to have no possible queues. There are currently 2 pools involved 
        //      in serving windshaft-cartodb requests so multiply this number by 
        //      2 to know how many possible connections will be kept open by the 
        //      server. The default is 50.
        // Values from sources:
        //      official:   50
        //      sverhoeven: 50
        max: 50,

        // Setting: 'redis.returnToHead'
        // Notes from official: 'Defines the behavior of the pool.
        //      false   => queue
        //      true    => stack
        // Values from sources:
        //      official:   true
        //      sverhoeven: true
        returnToHead: true,

        // Setting: 'redis.idleTimeoutMillis'
        // Notes from official: "Idle time before dropping connection."
        // Values from sources:
        //      official:   1
        //      sverhoeven: 1
        idleTimeoutMillis: 1,

        // Setting: 'redis.reapIntervalMillis'
        // Notes from official: "Time between cleanups"
        // Values from sources:
        //      official:   1
        //      sverhoeven: 1
        reapIntervalMillis: 1,

        // Setting: 'redis.unwatchOnRelease'
        // Notes from official: "Send unwatch on release, see 
        //      http://github.com/CartoDB/Windshaft-cartodb/issues/161"
        // Values from sources:
        //      official:   false
        //      sverhoeven: false
        unwatchOnRelease: false,

        // Setting: 'redis.noReadyCheck'
        // Notes from official: "Check 'no_ready_check' at 
        //      https://github.com/mranney/node_redis/tree/v0.12.1#overloading"
        // Values from sources:
        //      official:   true
        //      sverhoeven: true
        noReadyCheck: true,

        slowQueries: {
            // Setting: 'redis.slowQueries.log'
            // Values from sources:
            //      official:   true
            //      sverhoeven: true
            log: true,

            // Setting: 'redis.slowQueries.elapsedThreshold'
            // Values from sources:
            //      official:   200
            //      sverhoeven: 200
            elapsedThreshold: 200,
        }, // end of 'redis.slowQueries'

        slowPool: {
            // Setting: 'redis.slowPool.log'
            // Notes from official: "Whether a slow acquire must be logged or not."
            // Values from sources:
            //      official:   true
            //      sverhoeven: true
            log: true,

            // Setting: 'redis.slowPool.elapsedThreshold'
            // Notes from official: "The threshold to determine a slow acquire."
            // Values from sources:
            //      official:   25
            //      sverhoeven: 25
            elapsedThreshold: 25,
        }, // end of 'redis.slowPool'

        emitter: {
            // Setting: 'redis.emitter.statusInterval'
            // Notes from official: "Time in ms between each status report emitted
            //      from the pool. Status is sent to statsd."
            // Values from sources:
            //      official:   5000
            //      sverhoeven: 5000
            statusInterval: 5000,
        }, // end of 'redis.emitter'
    }, // end of 'redis'

    //// RENDERER SETTINGS ///////////////////////////////////////////////////

    renderer: {
        // Setting: 'renderer.cache_ttl'
        // Notes from official: "Ms since last access before renderer cache item expires."
        // Values from sources:
        //      official:   60000
        //      sverhoeven: 60000
        cache_ttl: 60000,  

        // Setting: 'renderer.statsInterval'
        // Notes from official: "Ms between each report to statsd."
        // Values from sources:
        //      official:   5000
        //      sverhoeven: 5000
        statsInterval: 5000, 

        // Setting: 'renderer.mvt'
        // NOTE: Not present in sverhoeven.
        mvt: {
            // Setting: 'renderer.mvt.usePostGIS'
            // Notes from official: "If enabled, MVTs generated with PostGIS
            //      directly; if disabled, MVTs generated with Mapnik MVT."
            // Values from sources:
            //      official:   true
            //      sverhoeven: NOT PRESENT
            usePostGIS: true
        },

        mapnik: {
            // Setting: 'renderer.mapnik.poolSize'
            // Notes from official: "Size of pool of internal mapnik backend. 
            //      Pool size is per mapnik renderer created in Windshaft's 
            //      RendererFactory. See lib/windshaft/renderers/renderer_factory.js
            //      Important: check the configuration of uv_threadpool_size to
            //      use suitable value."
            // Values from sources:
            //      official:   8
            //      sverhoeven: 8
            poolSize: 8,

            // Setting: 'renderer.mapnik.poolMaxWaitingClients'
            // Notes from official: "Max number of waiting clients of the pool
            //      of internal mapnik backend. Max number is per mapnik renderer
            //      created in RendererFactory.
            // Values from sources:
            //      official:   64
            //      sverhoeven: NOT PRESENT
            poolMaxWaitingClients: 64,

            // Setting: 'renderer.mapnik.useCartocssWorkers'
            // Notes from official: "Whether grainstore will use a child process
            //      or not to transform CartoCSS into Mapnik XML. Prevents 
            //      blocking main thread."
            // Values from sources:
            //      official:   false
            //      sverhoeven: false
            useCartocssWorkers: false,

            // Setting: 'renderer.mapnik.metatile'
            // Notes from official: "Number of tiles-per-side that are going to 
            //      be rendered at once. If all of them will be requested we'd 
            //      have saved time; if only one would be, we'd waste time.
            // Values from sources:
            //      official:   2 
            //      sverhoeven: 2
            metatile: 2,

            // Setting: 'renderer.mapnik.bufferSize'
            // Notes from official: "Thickness in pixels of a buffer around the 
            //      rendered tile. Important for labels and other markers that 
            //      overlap tile boundaries. Setting to 128 ensures no render 
            //      artifacts. 64 may have artifacts but is faster. Less 
            //      important if we can turn metatiling on.
            // Values from sources:
            //      official:   64
            //      sverhoeven: 64
            bufferSize: 64,

            // Setting: 'renderer.mapnik.snapToGrid'
            // Notes from official: "SQL queries will be wrapped with 
            //      ST_SnapToGrid, snapping all points of the geometry to a 
            //      regular grid."
            // Values from sources:
            //      official:   false
            //      sverhoeven: false
            snapToGrid: false,

            // Setting: 'renderer.mapnik.clipByBox2d'
            // Notes from official: "SQL queries will be wrapped with 
            //      ST_ClipByBox2D, returning the portion of a geometry falling 
            //      within a bounding rectangle. ONLY WORKS IF snapToGrid 
            //      IS ENABLED."
            // Notes from sverhoeven: "This requires postgis >=2.2 and geos >=3.5"
            // Values from sources:
            //      official:   true
            //      sverhoeven: false
            clipByBox2d: false,

            // Setting: 'renderer.mapnik.cache-features'
            // Notes from official: "If enabled Mapnik will reuse teh features 
            //      retrieved from the database instead of requesting them once 
            //      per style inside a layer."
            // Values from sources:
            //      official:   true
            //      sverhoeven: NOT PRESENT
            'cache-features': true,

            // Setting: 'renderer.mapnik.metrics'
            // Notes from official: "Require metrics to the renderer"
            // Values from sources:
            //      official:   false
            //      sverhoeven: NOT PRESENT
            metrics: false,

            // Setting: 'renderer.mapnik.markers_symbolizer_caches.disabled'
            // Notes from official: "Options for markers attributes, ellipses
            //      and images caches."
            // Values from sources:
            //      official:   false
            //      sverhoeven: NOT PRESENT
            markers_symbolizer_caches: { disabled: false },

            // Setting: 'renderer.mapnik.metatileCache'
            // Notes from official: "tilelive-mapnik uses an internal cache to 
            //      store tiles/grids generated when using metatile. This option 
            //      allows tuning the behavior of that internal cache."
            metatileCache: { 
                // Setting: 'renderer.mapnik.metatileCache.ttl'
                // Notes from official: "Time an object must stay in cache until 
                //      it is removed."
                // Values from sources:
                //      official:   0
                //      sverheoven: 0
                ttl: 0, 

                // Setting: 'renderer.mapnik.metatileCache.deleteOnHit'
                // Notes from official: "Whether an object must be removed after
                //      the first hit. Usually you want to use true here when
                //      ttl > 0."
                // Values from sources:
                //      official:   false
                //      sverhoeven: false
                deleteOnHit: false 
            }, // end of 'renderer.mapnik.metatileCache'

            // Setting: 'renderer.mapnik.formatMetatile'
            // Notes from official: "Override metatile behavior depending on format."
            formatMetatile: { 
                // Setting: 'renderer.mapnik.formatMetatile.png'
                // Values from sources:
                //      official:   2
                //      sverhoeven: 2
                png: 2, 

                // Setting: 'renderer.mapnik.formatMetatile.grid.json'
                // Values from sources:
                //      official:   1
                //      sverhoeven: 1
                'grid.json': 1 
            },


            // Setting: 'renderer.
            // Notes from official: 
            // Values from sources:
            //      official:   
            //      sverhoeven: 
            geojson: {
                // Setting: renderer.geojson.clipByBox2d
                // Purpose: Wraps SQL queries in ST_ClipByBox2D, which returns
                //          the portion of a geometry falling in a bounding rect.
                //          Only works if snapToGrid is enabled.
                clipByBox2d: false,
                removeRepeatedPoints: false,
                dbPoolParams: {
                    size: 16,
                    idleTimeout: 3000,
                    reapInterval: 1000
                }
            },

            // Setting: 'renderer.
            // Notes from official: 
            // Values from sources:
            //      official:   
            //      sverhoeven: 
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
                // Time in ms a render request can take before failing.
                // 0 is 'no render limit'
                // It considers metatiling, naive implementation:
                //   (render timeout) * (number of tiles in metatile)
                render: 0,

                // A render will complete whether or not it times out. This
                // setting determines whether timed out renders are placed into
                // the cache or discarded. Uses more application memory to
                // hold those in memory, but makes subsequent requests instant.
                // If it's implemented, need a cache eviction policy for the
                // internal cache.
                cacheOnTimeout: true
            }, // end of 'renderer.mapnik.limits'
        }, // end of 'renderer.mapnik'

        // Setting: 'renderer.torque'
        // Notes from official: 
        // Values from sources:
        //      official:   
        //      sverhoeven: 
        torque: {},

        http: {
            timeout: 2000,
            proxy: undefined,
            whitelist: [
                '.*',
                //'http://{s}.example.com/{z}/{x}/{y}.png' // example
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
            endpoint: 'http://sqlapi:8080/api/v2/sql/job',
            hostHeaderTemplate: '{{=it.username}}.localhost'
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

    // Setting: 'mapnik_version'
    // Values from sources:
    //      official:   undefined
    //      sverhoeven: undefined
    mapnik_version: undefined,

    // Setting: 'mapnik_tile_format'
    // Values from sources:
    //      official:   'png8:m=h'
    //      sverhoeven: 'png8:m=h'
    mapnik_tile_format: 'png8:m=h',

    // Setting: 'statsd'
    statsd: {
        // Setting: 'statsd.host'
        // Values from sources:
        //      official:   'localhost'
        //      sverhoeven: 'localhost'
        host: 'localhost',

        // Setting: 'statsd.port'
        // Values from sources:
        //      official:   8125
        //      sverhoeven: 8125
        port: 8125,

        // Setting: 'statsd.port'
        // Values from sources:
        //      official:   'dev.'
        //      sverhoeven: 'dev.'
        prefix: 'dev.',

        // Setting: 'statsd.cacheDns'
        // Values from sources:
        //      official:   true
        //      sverhoeven: true
        cacheDns: true
    }, // end of 'statsd'

    millstone: {
        // Setting: 'millstone.cache_basedir'
        // Values from sources:
        //      official:   '/tmp/cdb-tiler-dev/millstone-dev'
        //      sverhoeven: '/tmp/cdb-tiler-dev/millstone-dev'
        cache_basedir: '/tmp/cdb-tiler-dev/millstone-dev'
    }, // end of 'millstone'

    httpAgent: {
        // Setting: 'httpAgent.keepAlive'
        // Values from sources:
        //      official:   true
        //      sverhoeven: true
        keepAlive: true,

        // Setting: 'httpAgent.keepAliveMsecs'
        // Values from sources:
        //      official:   1000
        //      sverhoeven: 1000
        keepAliveMsecs: 1000,

        // Setting: 'httpAgent.maxSockets'
        // Values from sources:
        //      official:   25
        //      sverhoeven: 25
        maxSockets: 25,

        // Setting: 'httpAgent.maxFreeSockets'
        // Values from sources:
        //      official:   256
        //      sverhoeven: 256
        maxFreeSockets: 256,
    }, // end of 'httpAgent'

    varnish: {
        // Setting: 'varnish.host'
        // Values from sources:
        //      official:   'localhost'
        //      sverhoeven: 'localhost'
        host: 'varnish',

        // Setting: 'varnish.port'
        // Notes from official: "Telnet port Varnish is listening on."
        // Values from sources:
        //      official:   6082
        //      sverhoeven: 6082
        port: 6082,

        // Setting: 'varnish.http_port'
        // Notes from official: "HTTP port Varnish is listening on."
        // Values from sources:
        //      official:   6081
        //      sverhoeven: 6081
        http_port: 6081,

        // Setting: 'varnish.purge_enabled'
        // Notes from official: "Whether purge/invalidation is enabled in Varnish."
        // Values from sources:
        //      official:   false
        //      sverhoeven: false
        purge_enabled: false,

        // Setting: 'varnish.secret'
        // TODO: Find out if this must match value in varnish secret file.
        // Values from sources:
        //      official:   'xxx'
        //      sverhoeven: 'xxx'
        secret: 'xxx',

        // Setting: 'varnish.ttl'
        // Values from sources:
        //      official:   86400
        //      sverhoeven: 86400
        ttl: 86400,

        // Setting: 'varnish.layergroupTtl'
        // Notes from official: "Max age for cache-control header in layergroup responses."
        // Values from sources:
        //      official:   86400
        //      sverhoeven: 86400
        layergroupTtl: 86400,
    }, // end of 'varnish'

    fastly: {
        // Setting: 'fastly.enabled'
        // Notes from official: "Whether the invalidation is enabled or not."
        // Values from sources:
        //      official:   false
        //      sverhoeven: false
        enabled: false,

        // Setting: 'fastly.enabled'
        // Notes from official: "the fastly api key"
        // Values from sources:
        //      official:   'wadus_api_key'
        //      sverhoeven: 'wadus_api_key'
        apiKey: 'wadus_api_key',

        // Setting: 'fastly.enabled'
        // Notes from official: "the service that will get surrogate key invalidation"
        // Values from sources:
        //      official:   'wadus_service_id'
        //      sverhoeven: 'wadus_service_id'
        serviceId: 'wadus_service_id',
    }, // end of 'fastly'

    // Setting: 'serverMetadata'
    // Related notes from sverhoeven, in section about 'resources_url_templates':
    //      Resource URLs expose endpoints to request/retrieve metadata
    //      associated to Maps: dataviews, analysis node status.
    //
    //      This URLs depend on how `base_url_detached` and `user_from_host`
    //      are configured: the application can be configured to accept request
    //      with the {user} in the header host or in the request path. It also
    //      might depend on the configured cdn_url via `serverMetadata.cdn_url`.
    //
    //      This template allows to make the endpoints generation more flexible,
    //      the template exposes the following params:
    //
    //          1. {{=it.cdn_url}}: will be used when `serverMetadata.cdn_url` exists.
    //          2. {{=it.user}}: will use the username as extraced from
    //              `user_from_host` or `base_url_detached`.
    //          3. {{=it.port}}: will use the `port` from this very same
    //              configuration file.
    //
    // NOTE: This entire section is not present in sverhoeven.
    serverMetadata: {
        cdn_url: {
            // Setting: 'serverMetadata.cdn_url.http'
            // Values from sources:
            //      official:   undefined
            //      sverhoeven: NOT PRESENT
            http: undefined,

            // Setting: 'serverMetadata.cdn_url.https'
            // Values from sources:
            //      official:   undefined
            //      sverhoeven: NOT PRESENT
            https: undefined,
        }, // end of 'serverMetadata.cdn_url'
    }, // end of 'serverMetadata'

    //// NETWORK AND URL SETTINGS ///////////////////////////////////////////

    // Setting: 'host'
    // Required: I think so?
    // Used in: module.exports.bind.host in server_options.js
    // Purpose: Sets the host of the server
    // File: lib/cartodb/server_options.js
    // Values from sources:
    //      official:   '127.0.0.1'
    //      sverhoeven: '0.0.0.0'
    host: '0.0.0.0',

    // Setting: 'port'
    // Required: I think so?
    // Used in: module.exports.bind.port in server_options.js
    // Purpose: Sets the port the app server listens on
    // File: lib/cartodb/server_options.js
    // Values from sources:
    //      official:   8181
    //      sverhoeven: 8181
    port: 8181,

    // Setting: 'user_from_host'
    // Required: No
    // Used in: CdbRequest function
    // Purpose: Sets the regex RE_USER_FROM_HOST, defaults to '^([^\\.]+)\\.',
    //          which extracts the first part of a dot separated hostname
    // File: lib/cartodb/models/cdb_request.js
    // Notes from official: "Regular expression pattern to extract username from
    //      hostname. Must have a single grabbing block."
    // Values from sources:
    //      official:   '^(.*)\\.localhost'
    //      sverhoeven: '^([^\\.]+)\\.'
    user_from_host: '^([^\\.]+)\\.',

    // Setting: 'routes'
    // Required: No, default values in lib/cartodb/server_options.js
    // Used in: server_options
    // Purpose: Sets the routes hash of the server_options module exports
    // File: lib/cartodb/server_options.js
    // Notes from official: "Base URLs for the APIs.
    //      See https://github.com/CartoDB/Windshaft-cartodb/wiki/Unified-Map-API"
    // Values from sources:
    //      official:   Nested object mirroring defaults in server_options.js
    //      sverhoeven: NOT PRESENT
    //routes: undefined,

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
        // Setting: 'resources_url_templates.http'
        // Values from sources:
        //      official:   'http://{{=it.user}}.localhost.lan:{{=it.port}}/api/v1/map'
        //      sverhoeven: 'http://cartodb.localhost/user/{{=it.user}}/api/v1/map'
        http: 'http://{{=it.user}}.localhost/api/v1/map',

        // Setting: 'resources_url_templates.http'
        // Values from sources:
        //      official:   'http://localhost.lan:{{=it.port}}/user/{{=it.user}}/api/v1/map'
        //      sverhoeven: 'http://cartodb.localhost/user/{{=it.user}}/api/v1/map'
        https: 'https://{{=it.user}}.localhost/api/v1/map'
    },

    // Setting: 'base_url_templated'
    // Required:
    // Used in:
    // Purpose:
    // File
    // Notes from sverhoeven: "Base URLs for the APIs
    //      See http://github.com/CartoDB/Windshaft-cartodb/wiki/Unified-Map-API
    //
    //      Base url for the Templated Maps API
    //          "/api/v1/map/named" is the new API,
    //          "/tiles/template" is for compatibility with versions up to 1.6.x
    // Values from sources:
    //      official:   NOT PRESENT
    //      sverhoeven: '(?:/api/v1/map/named|/user/:user/api/v1/map/named|/tiles/template)'
    base_url_templated: '(?:/api/v1/map/named|/user/:user/api/v1/map/named|/tiles/template)',

    // Setting: 'base_url_detached'
    // Required:
    // Used in:
    // Purpose:
    // File:
    // Notes from sverhoeven: "Base url for the Detached Maps API
    //      "maps" is the the new API,
    //      "tiles/layergroup" is for compatibility with versions up to 1.6.x
    // Values from sources:
    //      official:   NOT PRESENT
    //      sverhoeven: '(?:/api/v1/map|/user/:user/api/v1/map|/tiles/layergroup)'
    base_url_detached: '(?:/api/v1/map|/user/:user/api/v1/map|/tiles/layergroup)',

    //// LIMIT SETTINGS //////////////////////////////////////////////////////

    // Setting: 'uv_threadpool_size'
    // Required: No
    // Used in: app.js
    // Purpose: If present, sets the value of process.env.UV_THREADPOOL_SIZE
    //          Default size is 4, max is 128.
    //          See http://docs.libuv.org/en/latest/threadpool.html for info
    // File: app.js
    // Notes from official: "Size of the threadpool which can be used to run
    //      user code and get notified in the loop thread. Its default size
    //      is 4, but it can be changed at startup time (the absolute maximum
    //      is 128).See http://docs.libuv.org/en/latest/threadpool.html
    // Values from sources:
    //      official:   undefined
    //      sverhoeven: undefined
    uv_threadpool_size: undefined,

    // Setting: 'maxConnections'
    // Required: No, default set to 128 in app.js
    // Used in: app.js
    // Purpose: Sets the backlog arg value to server.listen()
    //          Based on total number of filedescriptors--should be about
    //          1/8th of total filedescriptors
    // File: app.js
    // Notes from official: "Max number of connections for one process. 128 is
    //      a good value with a limit of 1024 open file descriptors."
    // Values from sources:
    //      official:   128
    //      sverhoeven: 128
    maxConnections: 128,

    // Setting: 'maxUserTemplates'
    // Required: No, defaults to unlimited (via '0') in
    //           lib/cartodb/backends/template_maps.js
    // Used in: createTemplateMaps in api-router.js
    // Purpose: Sets the max number of user template maps
    // File: lib/cartodb/api/api-router.js
    // Notes from official: "Max number of templates per user. Unlimited by default."
    // Values from sources:
    //      official:   1024
    //      sverhoeven: 1024
    maxUserTemplates: 1024,

    // Setting: 'mapConfigTTL'
    // Required: No, default set to 7200 in lib/cartodb/server_options.js
    // Used in: server_options
    // Purpose: Sets the value of grainstore.default_layergroup_ttl
    // File: lib/cartodb/server_options.js
    // Notes from official: "Seconds since 'last creation' before a detached or
    //      template instance map expires. Or: how long do you want to be able
    //      to navigate the map without a reload? Defaults to 7200 (2 hours)."
    // Values from sources:
    //      official:   7200
    //      sverhoeven: 7200
    mapConfigTTL: 7200,

    //// APPARENTLY UNUSED SETTINGS //////////////////////////////////////////

    // Setting: 'socket_timeout'
    // Required: No, because it's not actually used anywhere
    // Purpose: From the example file, it says "idle socket timeout, in ms"
    // Notes from official: "Idle socket timeout in milliseconds."
    // Values from sources:
    //      official:   600000
    //      sverhoeven: 600000
    socket_timeout: 600000,

    // Setting: 'enable_cors'
    // Required: I don't think so, not actually referenced anywhere
    // Purpose: looks like a flag for turning cors on/off, but given it's not
    //          referenced anywhere else in the app code, I think it's useless
    // Values from sources:
    //      official:   true
    //      sverhoeven: true
    enable_cors: true,


};

module.exports = config;
