# Changelog for `multi-svc-carto`

* **2019-05-14, 1.0.0-rc.1**
    * Consolidated routing via Nginx reverse proxy in the `router` container.
    * HTTPS support via self-signed certificate.
* **2019-05-10, 1.0.0-beta**
    * All core containers running their respective processes.
    * No consolidated routing.

## Docker Image Sizes

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
