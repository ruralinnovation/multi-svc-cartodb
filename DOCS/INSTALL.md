# Installation

This document covers how to install the `multi-svc-cartodb` repository to a local development machine, build its component Docker images, and run the cluster of containers enabled by the [`docker-compose.yml`](../docker-compose.yml) file in the repository root.

For information about deploying the containers to a cloud environment, please see [DEPLOYMENT.md](./DEPLOYMENT.md).

## Pre-requisites

To use this repository, you will need:

* [Docker](https://www.docker.com/) (18.09+)
* [Packer](https://www.packer.io) (1.4.2+)
* `git` (2.21+)
* `make`
* Access to a `bash` shell.

## Step by step instructions

1. Clone this repo to a local folder, and change directories into the root of the repo:

    ```bash
    git clone https://github.com/ruralinnovation/multi-svc-cartodb.git
    cd multi-svc-cartodb
    ```

1. Look at the values in `build-configurations/DEFAULT.json`, and change those that seem appropriate, particularly the usernames, passwords, and email addresses. Be aware that changing other settings may impact your ability to build a running cluster, so only change values for things like version numbers, hostnames, etc. if you are confident of your choices. Note that if you change the passwords they will have to pass the Carto password test, which is that they are not included in [Carto's list of common passwords.](https://github.com/CartoDB/cartodb/blob/master/lib/carto/common_passwords.rb) Additionally, the organization name must be all one word, lowercase letters only.
1. You will also need to add an entry for `osscarto-multi.localhost` (or your chosen hostname if you changed the default) to your `/etc/hosts` file, to make sure you get local DNS translation for your hostname and subdomain:

    ```bash
    echo "127.0.0.1   osscarto-multi.localhost" | sudo tee -a /etc/hosts
    ```

1. Generate the SSL certificates by running `make generate-ssl` and following the prompts. You should only need to do this once, though you can regenerate the certificates at any time.
1. In order to make your local browser consider the `nginx` container's signed certificate legitimate, you'll need to add the root certificate of the signing CA you created to your local development machine's trusted cert store. On a Linux host that probably means adding it to `/usr/local/share/ca-certificates/`, on a Mac it will mean adding it to your Keychain (for instructions see the Installing Your Root Certificate section [of this article about local HTTPS](https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/)). (TODO: Add Windows instructions.) The file you'll be targeting is `local-ssl/osscarto-multiCA.pem` (assuming the default hostname).
1. Now you should be able to run the following (which can take quite a while, possibly up to an hour):

    ```bash
    make install
    ```


Running that meta task is the equivalent of running:

* `make docker-build-cartobase` - builds the base image that the `cartodb`, `sqlapi`, and `windshaft` containers are built on top of
* `make generate-build` - creates configuration and environment files based on `build-configurations/DEFAULT.json` and places them in `builds/DEFAULT`
* `make use-build` - copies build-specific config files to the appropriate docker contexts, and copies SSL certs to contexts as well
* `make packer-build-postgis` - builds the Docker image that the `postgis` container will be created from
* `make compose-build` - using the environment variables in `builds/DEFAULT/docker-compose-DEFAULT.env`, runs `docker-compose build` against the `docker-compose.yml` file in the repo root, to build the Docker images for the `nginx`, `redis`, `cartodb`, `sqlapi`, `windshaft`, and `varnish` containers to run from

Once that is complete, you should be able to start your cluster with `make compose-up`, and (once it finishes initializing), view it in a browser at `https://osscarto-multi.localhost`.
