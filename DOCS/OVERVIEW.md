# Implementation of CartoDB in multiple services

This document explains how this project decomposes the CartoDB stack into multiple, (partially) independent services.

CartoDB is itself a multi-service application, made up of the following core pieces:

* **CartoDB Builder** - A Ruby on Rails application that provides user and map/data management for organizations on the Carto platform.
* **CartoDB Resque Task Runner** - An implementation of `resque` to process asynchronous jobs.
* **PostgreSQL/PostGIS, with Carto extension(s)** - Map and user data are principally stored in a number of PostgreSQL databases, which have been extended with both PostGIS, and the extension functions from Carto's own PostgreSQL extension.
* **Redis** - Configuration, state, and authentication data are stored in Redis. The Redis instance is hit both by CartoDB Builder and by the SQL-API and Windshaft tile server instances.
* **Carto SQL API** - A Node.js application responsible for handling passthrough of SQL to the PostgreSQL instance, allowing both public and authenticated requests. Public requests may perform SELECT on a subset of an organization's data, while requests authenticated by a non-public API key may be allowed to actively alter data on the server.
* **Windshaft Map Tile Server** - A Node.js application which serves map tiles based on data held in the PostgreSQL instance, with the Carto SQL API acting as an intermediary.
* **Varnish HTTP Cache** - A cache of hits against several of the underlying services.

For this project, those services are encapsulated in containers named:

* `cartodb` _(presently runs both the Rails app and the resque process)_
* `postgis`
* `redis`
* `sqlapi`
* `windshaft`
* `varnish`

Additionally this repo adds a seventh container, `router`, which runs an Nginx reverse proxy in front of the other containers. That consolidates the requests to the various services so that they can all go through the same port on localhost, and allows us to use SSL when loading the application.

Note that the image names, as created by `docker-compose`, will have the name of the root directory (where `docker-compose.yml` is located) prepended to them. They will show up via `docker image ls` as things like `multi-svc-cartodb_postgis`. If you would like to use a custom value for the prepended name, you can alter the directory name, or set a value for the [`COMPOSE_PROJECT_NAME` environment variable](https://docs.docker.com/compose/reference/envvars/) on your development machine. 
