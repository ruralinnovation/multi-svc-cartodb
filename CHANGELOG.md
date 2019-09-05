# Changelog for `multi-svc-carto`

* **2019-09-05, 1.0.0-rc-3**
    * Pretty major overhaul.
    * Support for multiple build configurations.
    * Interactions with the repo are now largely via `make`
    * The `postgis` Docker image is now built by Packer. This is to support building both a local docker image and a remote AWS AMI, since to run the PostgreSQL component of the stack efficiently in AWS will require running it as an EC2 instance, which needs a base AMI to start from. (This is because the PostgreSQL component cannot run in AWS RDS since it has custom extensions that are not supported by that service.)
    * The bugs that caused map updates to fail to publish have been corrected. (TL;DR is that because hostname components were missing from the `vizjson_cache_domains` array in the cartodb `app_config.yml` file, map/visualization entries in Redis were not being properly purged. Changing the value of `vizjson_cache_domains` fixed it.)
    * It is a known issue that adding analyses to a map will fail. The error message is misleading--it fails because the geocoder is not correctly configured. Working on it.
    * The `router` container was renamed to `nginx` to make its contents clearer.
* **2019-06-08, 1.0.0-rc-2**
    * HTTPS support updated to use a fake local CA for cert signing
    * Updates to the config for RoR app, to make internal tiler connections via http directly to the tiler host, per suggestions [in issue 22 in sverhoeven](https://github.com/sverhoeven/docker-cartodb/issues/22)
    * Container build process altered to use a single base image for dependency management of the `cartodb`, `sqlapi`, and `windshaft` containers
* **2019-05-14, 1.0.0-rc.1**
    * Consolidated routing via Nginx reverse proxy in the `router` container.
    * HTTPS support via self-signed certificate.
* **2019-05-10, 1.0.0-beta**
    * All core containers running their respective processes.
    * No consolidated routing.

## Docker Image Sizes

At 1.0.0-rc.3, 2019-09-05, image sizes are:

```
$ docker image ls multi-svc-cartodb* --format '{{printf "%-36s" .Repository}} {{.Size}}'
multi-svc-cartodb_nginx              16.7MB
multi-svc-cartodb_cartodb            2.96GB
multi-svc-cartodb_varnish            353MB
multi-svc-cartodb_windshaft          1.76GB
multi-svc-cartodb_sqlapi             1.43GB
multi-svc-cartodb_redis              51.4MB
multi-svc-cartodb_postgis            1.62GB
```

At 1.0.0-rc.2, 2019-06-08, image sizes are:

```
$ docker image ls multi-svc-cartodb* --format '{{printf "%-36s" .Repository}} {{.Size}}'
multi-svc-cartodb_postgis            1.62GB
multi-svc-cartodb_varnish            394MB
multi-svc-cartodb_cartodb            2.95GB
multi-svc-cartodb_windshaft          1.91GB
multi-svc-cartodb_router             16.7MB
multi-svc-cartodb_sqlapi             1.41GB
multi-svc-cartodb_redis              51.4MB
```

At 1.0.0-rc.1, 2019-05-14, image sizes are:

```
$ docker image ls multi-svc-cartodb* --format '{{printf "%-36s" .Repository}} {{.Size}}'
multi-svc-cartodb_cartodb            2.33GB
multi-svc-cartodb_postgis            962MB
multi-svc-cartodb_router             16.1MB
multi-svc-cartodb_windshaft          994MB
multi-svc-cartodb_sqlapi             1.16GB
multi-svc-cartodb_redis              50.8MB
```
