var config = {
    //////////////////////////////////////////////////////////////////////////
    // Scalar configuration values                                          //
    //////////////////////////////////////////////////////////////////////////

    environment: 'development',
    host: '0.0.0.0',
    port: 8181,
    maxConnections: 128,
    gc_interval: 10000,
    useProfiler: true,
    log_filename: 'logs/node-windshaft.log',
    log_format: ':req[X-Real-IP] :method :req[Host]:url :status '+
                ':response-time ms -> :res[Content-Type] '+
                '(:res[X-Tiler-Profiler]) (:res[X-Tiler-Errors])',
    cache_enabled: true,
    disabled_file: 'pids/disabled',
    enable_cors: true,
    mapConfigTTL: 7200,
    mapnik_tile_format: 'png8:m=h',
    mapnik_version: undefined,
    maxUserTemplates: 1024,
    socket_timeout: 600000,
    user_from_host: '^([^\\.]+)\\.',
    uv_threadpool_size: undefined,
    
    // Relevant to test runners only.
    postgres_auth_pass: '<%= user_password %>',
    postgres_auth_user: 'development_cartodb_user_<%= user_id %>',


    //////////////////////////////////////////////////////////////////////////
    // Nested configuration objects                                         //
    //////////////////////////////////////////////////////////////////////////

    health: { enabled: false, username: "localhost", "x": 0, "y": 0, "z": 0}, // end of health
    
    millstone: { cache_basedir: '/tmp/cdb-tiler-dev/millstone-dev' }, // end of millstone

    serverMetadata: { cdn_url: { http: undefined, https: undefined } }, // end of serverMetadata

    resources_url_templates: { 
        http: 'http://osscarto.localhost/user/{{=it.user}}/api/v1/map',
        https: 'https://osscarto.localhost/user/{{=it.user}}/api/v1/map'
    }, // end of resources_url_templates

    fastly: { 
        enabled: false, 
        apiKey: 'wadus_api_key', 
        serviceId: 'wadus_service_id' 
    }, // end of fastly

    httpAgent: { 
        keepAlive: true,
        keepAliveMsecs: 1000,
        maxSockets: 25,
        maxFreeSockets: 256
    }, // end of httpAgent

    statsd: { 
        host: 'localhost',
        port: 8125,
        prefix: 'dev.',
        cacheDns: true
    }, // end of statsd
     
    enabledFeatures: { 
        cdbQueryTablesFromPostgres: true,
        onTileErrorStrategy: false,
        layerStats: true,
        rateLimitsEnabled: false,
        rateLimitsByEndpoint: {
            analysis: false,
            analysis_catalog: false,
            anonymous: false,
            attributes: false,
            dataview: false,
            dataview_search: false,
            named: false,
            named_create: false,
            named_delete: false,
            named_get: false,
            named_list: false,
            named_tiles: false,
            named_update: false,
            'static': false,
            static_named: false,
            tile: false
        }
    }, // end of enabledFeatures

    varnish: { 
        host: 'varnish',
        port: 6082,
        http_port: 6081,
        purge_enabled: false,
        secret: 'xxx',
        ttl: 86400,
        layergroupTtl: 86400,
        fallbackTtl: 300,
    }, // end of varnish

    routes: { 
        v1: { 
            paths: [ '/api/v1', '/user/:user/api/v1' ],
            map: { paths: [ '/map' ] },
            template: { paths: [ '/map/named' ] }
        },
        v0: {
            paths: [ '/tiles' ],
            map: { paths: [ '/layergroup' ] },
            template: { paths: [ '/template' ] }
        }
    }, // end of routes

    analysis: {
        batch: {
            inlineExecution: false,
            endpoint: 'https://osscarto.localhost/api/v2/sql/job',
            hostHeaderTemplate: '{{=it.username}}.windshaft.localhost'
        }, // end of analysis.batch
        logger: { filename: 'logs/node-windshaft-analysis.log' }, // end of analysis.logger
        limits: {
            moran: { timeout: 120000, maxNumberOfRows: 1e5 },
            cpu2x: { timeout: 60000 }
        } // end of analysis.limits
    }, // end of analysis

    postgres: { 
        //extent: "-20037508.3,-20037508.3,20037508.3,20037508.3",
        host: "postgis",
        //max_size: 500,
        password: "public",
        //persist_connection: false,
        port: 5432,
        //row_limit: 65535,
        //simplify_geometries: true,
        //type: "postgis",
        //use_overviews: true,
        user: "publicuser",
        pool: { size: 16, idleTimeout: 3000, reapInterval: 1000 } // end of postgres.pool
    }, // end of postgres

    redis: { 
        host: 'redis',
        port: 6379,
        max: 50,
        returnToHead: true,
        idleTimeoutMillis: 1,
        reapIntervalMillis: 1,
        unwatchOnRelease: false,
        noReadyCheck: true,
        slowQueries: { log: true, elapsedThreshold: 200 }, // end of redis.slowQueries
        slowPool: { log: true, elapsedThreshold: 25 }, // end of redis.slowPool
        emitter: { statusInterval: 5000 } // end of redis.emitter
    }, // end of redis

    renderer: { 
        cache_ttl: 60000,
        statsInterval: 5000,

        mvt: { usePostGIS: true },

        torque: { }, 

        http: {
            timeout: 2000,
            proxy: undefined,
            whitelist: [ '.*' ],
            fallbackImage: {
                type: 'fs',
                src: __dirname + '/../../assets/default-placeholder.png'
            } // end of renderer.http.fallbackImage
        }, // end of renderer.http

        mapnik: {
            poolSize: 8,
            poolMaxWaitingClients: 64,
            useCartocssWorkers: false,
            metatile: 2,
            bufferSize: 64,
            snapToGrid: false,
            clipByBox2d: true,
            'cache-features': true,
            metrics: false,

            markers_symbolizer_caches: { disabled: false },

            metatileCache: { ttl: 0, deleteOnHit: false }, 

            formatMetatile: { png: 2, 'grid.json': 1 },

            limits: { render: 0, cacheOnTimeout: true },

            postgis: {
                user: "publicuser",
                password: "public",
                host: "postgis",
                port: 5432,
                extent: "-20037508.3,-20037508.3,20037508.3,20037508.3",
                row_limit: 65535,
                persist_connection: false,
                simplify_geometries: true,
                use_overviews: true,
                max_size: 500,
                twkb_encoding: true
            }, // end of renderer.mapnik.postgis
        } // end of renderer.mapnik
    } // end of renderer
}; // end of config

module.exports = config;
