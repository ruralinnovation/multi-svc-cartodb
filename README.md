# Implementation of CartoDB in multiple services

The instructions below are detailed--the [Quickstart is here](./docs/QUICKSTART.md).

## Overview

CartoDB is itself a multi-service application, made up of the following core pieces:

* **CartoDB Builder** - A Ruby on Rails application that provides user and map/data management for organizations on the Carto platform.
* **PostgreSQL/PostGIS, with Carto extension(s)** - Map and user data are principally stored in a number of PostgreSQL databases, which have been extended with both PostGIS, and the extension functions from Carto's own PostgreSQL extension.
* **Redis** - Configuration, state, and authentication data are stored in Redis. The Redis instance is hit both by CartoDB Builder and by the SQL-API and Windshaft tile server instances.
* **Carto SQL API** - A Node.js application responsible for handling passthrough of SQL to the PostgreSQL instance, allowing both public and authenticated requests. Public requests may perform SELECT on a subset of an organization's data, while requests authenticated by a non-public API key may be allowed to actively alter data on the server.
* **Windshaft Map Tile Server** - A Node.js application which serves map tiles based on data held in the PostgreSQL instance, with the Carto SQL API acting as an intermediary.

## Installation

### Prerequisites

#### Docker

You will need to have Docker (Community Edition) installed on your local machine. Installation instructions can be found at <a href="https://docs.docker.com/install/" target="_blank">https://docs.docker.com/install/</a>. This should provide you with the Docker engine, as well as the `docker` and `docker-compose` CLI utilities.

For reference, these are the versions of the primary parts of Docker installed on my machine at the time this was under development (April, 2019):

```bash
$ docker --version
Docker version 18.09.2, build 6247962

$ docker-machine --version
docker-machine version 0.16.1, build cce350d7

$ docker-compose --version
docker-compose version 1.23.2, build 1110ad01
```

#### Git

If you don't have git (check with `git --version`), you can get it from the [official site](https://git-scm.com/download/).

### Setting up your dev environment

Once you have Docker and Git, you should clone this repo to your local machine:

```bash
cd /path/to/where/you/want/the/checkout
git clone --recurse-submodules https://github.com/ruralinnovation/multi-svc-cartodb.git
cd multi-svc-cartodb
```

This project uses [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to bring in the various Carto sources, and you'll need to make sure those submodules are each checked out to an appropriate version. To streamline that process, and to make the versioning consistent, there's a script called `setup-local.sh` in the root of the repository.

That script does two things:

1. Each time it runs, it writes values for a number of variables to a `.env` file in the root of the repository. The `.env` file is used by `docker-compose` to merge values into the `docker-compose.yml` file prior to executing any other instructions. 
1. If run with the `--set-submodule-versions` flag, it will update the submodule repositories, and make sure they are checked out to the version tags given in the file (or sourced from your bash environment).

The values the script sets fall into two categories: submodule version strings, and credentials for the public user that will be created when you run the cartodb container for the first time. All of them have default values, and it is fine to leave them as-is. However, if you would like to change the user/password/email values you're welcome to do so. The password can just be something you'll remember--it's not stored in a secrets manager, so it isn't secure. However! It does have to match the Carto password policy, which is:

* Min length: 6
* Max length: 64
* Cannot be the same as the username
* Cannot be blank
* Cannot be in their [common passwords list](https://github.com/CartoDB/cartodb/blob/3cfc359ff51d8549d949b144a1c04a050885be85/lib/carto/common_passwords.rb)

The script will source the values from existing env vars if there are any, so exporting values for user, password, and email in your `~/.bash_profile` should cause them to be carried through into the script (make sure to change the fake values in this example code):

```bash
echo "export CARTO_DEFAULT_USER=jackjackson" >> ~/.bash_profile
echo "export CARTO_DEFAULT_PASS=somepassword" >> ~/.bash_profile
echo "export CARTO_DEFAULT_EMAIL=you@somedomain.tld" >> ~/.bash_profile
source ~/.bash_profile
```

Once you've done that, you can call the setup script with the `--set-submodule-versions` flag:

```bash
./setup-local.sh --set-submodule-versions
```

Assuming the script ran successfully, you should now be able to see your custom values for user/password/email merged into the output of `docker-compose config`, which shows the `docker-compose.yml` file after variable and path expansion.

### Building the Images

To build images from the Dockerfiles, call `docker-compose build` in the repository root (where the `docker-compose.yml` file is). This is likely to take some time--probably between fifteen and forty-five minutes, depending on your machine and internet speed.

## Usage

While each of the services here have their own Dockerfile, and it is possible to interact with them directly via the `docker` CLI utility, they are meant to be orchestrated via `docker-compose`. The `docker-compose.yml` file in the repository root defines the relationships between containers, and they expect to be able to make network requests to named hosts defined on the network `docker-compose` brings up.

### Starting the cluster of services

Assuming you've built the images successfully, in the root directory of the repo run `docker-compose up`. This will bring up containers based on the images, in their internal dependency order as defined in `docker-compose.yml`.

Note that once they're up, docker-compose will continually stream their output to your terminal's STDOUT, with each line prefixed by the container name it comes from.

## Contributing

**If you are going to add values to the `.env` file, you should add them by modifying the `setup-local.sh` script, not by adding them directly to the `.env` file! Otherwise they will be blown away the next time `setup-local.sh --set-submodule-versions` is run.** Note also that `.env` is in the `.gitignore` file, since it should only be constructed by `setup-local.sh`.
