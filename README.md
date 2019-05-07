# Implementation of CartoDB in multiple services

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

Once you have Docker and Git, you should clone this repo to your local machine and make sure its submodules are checked out to the appropriate versions:

```bash
cd /path/to/where/you/want/the/checkout
git clone https://github.com/ruralinnovation/multi-svc-cartodb.git
cd multi-svc-cartodb
source ./setup-local.sh --set-submodule-versions
```

Note that running `setup-local.sh` with the `--set-submodule-versions` flag has three important effects:

1. It updates (via a pull from `master`) each submodule repository, then checks out the appropriate version for the given tag
1. It sets several `CARTO_[...]_VERSION` environment variables in your shell
1. It populates the `.env` file with the version strings. Those values are used by `docker-compose` when building containers, during a pre-processing merge step. You can view the post-merge state of the compose file with `docker-compose config`.

**If you are going to add values to the `.env` file, you should add them by modifying the `setup-local.sh` script, not by adding them directly to the `.env` file! Otherwise they will be blown away the next time `setup-local.sh --set-submodule-versions` is run.** Note also that `.env` is in the `.gitignore` file, since it should only be constructed by `setup-local.sh`.

#### Optional: Adding the version env vars to your shell startup

**Note:** This assumes you use `/bin/bash` as your default shell. If you don't know what shell you're running, you can run `echo $SHELL` in a terminal. If you're purposely running `sh`, `zsh`, `csh`, or any of the special purpose shells well, you're on your own (though I look forward to reading your highly opinionated Usenet posts). More info about Bash startup files can be found in [the official bash documentation](https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html), as well as [this Stack Exchange answer about login vs. non-login shells](https://unix.stackexchange.com/a/46856).

If you want to have the various `CARTO_[...]_VERSION` variables that `setup-local.sh` exports set for every shell you open, add it to your `~/.bashrc` file using the following command:

```bash
cp ~/.bashrc ~/.bashrc.bak.$(date +%Y%m%d)
echo "source $PWD/setup-local.sh -q" >> ~/.bashrc
```

That will cause the script to run (in quiet mode) when a non-login shell is opened. For login shells to get it, you'll need to make your `~/.bash_profile` source your `~/.bashrc`. If you don't already do that, you can make it happen by running:

```bash
cp ~/.bash_profile ~/.bash_profile.bak.$(date +%Y%m%d)
echo "test -f ~/.bashrc && source ~/.bashrc" >> ~/.bash_profile
```

Feel free to omit the `cp` backup steps if you want. Hashtag YOLO, etc. If you've successfully modified your shell startup files, any new terminal window you open should show the four version strings if you run `env | grep "^CARTO"`. (In any currently open terminal session, you would need to run `source ~/.bash_profile` to make them available.)

### Building the Images

To build images from the Dockerfiles, call `docker-compose build` in the repository root (where the `docker-compose.yml` file is). This is likely to take some time--probably between fifteen and forty-five minutes, depending on your machine and internet speed.

## Usage

While each of the services here have their own Dockerfile, and it is possible to interact with them directly via the `docker` CLI utility, they are meant to be orchestrated via `docker-compose`. The `docker-compose.yml` file in the repository root defines the relationships between containers, and they expect to be able to make network requests to named hosts defined on the network `docker-compose` brings up. 

### Starting the cluster of services

Assuming you've built the images successfully, in the root directory of the repo run `docker-compose up`. This will bring up containers based on the images, in their internal dependency order as defined in `docker-compose.yml`.

Note that once they're up, docker-compose will continually stream their output to your terminal's STDOUT, with each line prefixed by the container name it comes from.

