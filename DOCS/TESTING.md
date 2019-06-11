# Testing CartoDB

## CartoDB (Rails application)

## Windshaft Tile Server (Node application)

## SQL API (Node application)

## CARTO PostgreSQL Extensions

### `cartodb` application logic extension

To run tests for the `cartodb` extension, execute:

```bash
docker-compose up postgis
docker-compose exec postgis /bin/bash
```

In the `postgis` container's bash shell, execute:

```bash
cd /carto/cartodb-postgresql
PGUSER=postgres make installcheck
```

[Example test run for cartodb extension](./test_examples/cartodb.txt)

***

### `crankshaft` spatial analysis extension

To run tests for the `crankshaft` extension, execute:

```bash
docker-compose up postgis
docker-compose exec postgis /bin/bash
```

In the `postgis` container's bash shell, execute:

```bash
cd /carto/crankshaft
make test
```

[Example test run for crankshaft extension](./test_examples/crankshaft.txt)

***

### `odbc_fdw` foreign data wrapper extension

Detailed instructions for testing this extension can be found here:

https://github.com/CartoDB/odbc_fdw/blob/master/test/README.md

TODO: Determine test run requirements / procedure for the `postgis` container.

***
