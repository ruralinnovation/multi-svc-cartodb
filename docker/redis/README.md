# Redis

This container is based largely on the one included in this repository:

[https://github.com/ihmeuw/cartodb-docker](https://github.com/ihmeuw/cartodb-docker)

That container is itself based on the official Docker image for Redis, and the only additions it makes is to pass options to the entrypoint script to enable persistent storage via `--appendonly` and `--appendfsync`.

The storage volume for persistence is defined in the `docker-compose.yml` file in the root of this repo, and can be changed to be either a Docker volume (the default) or a mount point in the host filesystem.
