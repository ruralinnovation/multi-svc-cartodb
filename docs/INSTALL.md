# Installation of `multi-svc-cartodb`

## Prerequisites

### Docker

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

### Git

If you don't have git (check with `git --version`), you can get it from the [official site](https://git-scm.com/download/).

### OpenSSL

You'll need openssl to generate the security certificate for connecting to the router container over HTTPS. You can check for it with `openssl version`. If you don't have it, you should be able to install it from a package manager (homebrew, etc.).

## Local Environment Setup

### Cloning the Repo(s)

Because this project uses [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules), your initial call to clone the repository needs to include the `--recurse-submodules` flag. Without it, you'll only get the top level submodules--and since the Carto repositories themselves have submodules, that will lead to potentially non-obvious holes in your codebase. This example checks the repo out to `~/CARTO/multi-svc-cartodb`, but feel free to put it wherever makes sense on your filesystem.

```bash
mkdir ~/CARTO
cd ~/CARTO
git clone --recurse-submodules https://github.com/ruralinnovation/multi-svc-cartodb.git
```

### Running the `setup-local.sh` Script

Once you've cloned the repository and all its submodules, you'll need to run the `setup-local.sh` Bash script, which is in the root of the checkout. That script does the following:

1. Each time it runs (regardless of CLI flags), it resets the contents of a file named `.env` in the root of the repository. That file is used to supply environment variable values to `docker-compose` when you run commands like `config`, `build`, `run`, and `up` that source values from the `docker-compose.yml` file. Because it supplies local (and possibly one-off) values, `.env` is excluded from version control, and does not exist until you run the `setup-local.sh` script at least once.
1. If `setup-local.sh` is run with the `--set-submodule-versions` flag, it enters each submodule directory included in the project and checks it out to a specific Git version tag. It also updates each submodule by pulling any recent commits to the repository, though commits after the version tag will not be available in the checked out branch.
1. If `setup-local.sh` is run with the `--generate-ssl-cert` flag, it creates `.crt` and `.key` files in the `docker/router/ssl` directory. These are necessary for having the nginx process in the router container serve over https. These files are also excluded from version control, so you must run `setup-local.sh --generate-ssl-cert` at least once before building the containers.

The values the script sets fall into two categories: submodule version strings, and credentials for the public user that will be created when you run the cartodb container for the first time. All of them have default values, and it is fine to leave them as-is. However, if you would like to change the user/password/email values you're welcome to do so. I recommend leaving the default password value (`abc123def`). If you do change it, the password can just be something you'll remember--it's not stored in a secrets manager, so it isn't secure. However! It does have to match the Carto password policy, which is:

* Min length: 6
* Max length: 64
* Cannot be the same as the username
* Cannot be blank
* Cannot be in their [common passwords list](https://github.com/CartoDB/cartodb/blob/3cfc359ff51d8549d949b144a1c04a050885be85/lib/carto/common_passwords.rb)

The script will source the values from existing env vars if there are any, so exporting values for user and email (and `CARTO_DEFAULT_PASS` if you're changing that) in your `~/.bash_profile` should cause them to be carried through into the script (make sure to change the fake values in this example code):

```bash
echo "export CARTO_DEFAULT_USER=jackjackson" >> ~/.bash_profile
echo "export CARTO_DEFAULT_EMAIL=you@somedomain.tld" >> ~/.bash_profile
source ~/.bash_profile
```

Then, to set up the local environment using the script, run:

```bash
cd ~/CARTO/multi-svc-cartodb
./setup-local.sh --set-submodule-versions --generate-ssl-cert
```

If the script ran successfully, the following should be true:

* There should be a `.env` file in the root of the repository, which includes your custom user/email values (if you set any)
* Running `docker-compose config` in the repo root should produce output with the values from the `.env` file merged into `docker-compose.yml`
* There should be `.crt` and `.key` files in `docker/router/ssl`

### Adding Routing to `username.localhost`

Carto relies on extracting a username from the subdomain used in the URL you hit it from. In this case, you'll be hitting `username.localhost`, where `username` is equivalent to the value you set for `CARTO_DEFAULT_USER`. While the various containers (principally the router) are fine to receive requests for that, you'll need to amend your machine's `/etc/hosts` file to makesure `username.localhost` is resolved to `127.0.0.1`. You can do that either by editing the hosts file directly, or running:

```bash
echo "127.0.0.1    $CARTO_DEFAULT_USER.localhost" | sudo tee -a /etc/hosts
```

You can test that it's working with the following, which should show it resolving to `127.0.0.1`:

```bash
nslookup "$CARTO_DEFAULT_USER.localhost"
```

### Forcing Browsers to Accept the Self-Signed SSL certificates

Since the router container is going to serve HTTPS content using a self-signed root certificate, most browsers will consider it to be insecure, and may refuse to serve it. There are workarounds in most browsers for at least allowing it to display page content (though it may still display a broken SSL lock icon).

**Chrome**

Per [this StackOverflow answer](https://stackoverflow.com/a/31900210/1461374), for Chrome, open a new window and load the following URL:

```
chrome://flags/#allow-insecure-localhost
```

Once open, you'll have the option to set that to 'enabled,' which will allow you to load pages without getting the insecure page blockage.

**Safari**

Per [this StackOverflow answer](https://stackoverflow.com/a/47492154/1461374), for Safari, add the certificate to your system keychain with the following (making sure to replace the `/path/to/my/wildcard-localhost.crt` with an actual path):

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /path/to/my/wildcard-localhost.crt
```

### Building the Images

To build images from the Dockerfiles, call `docker-compose build` in the repository root (where the `docker-compose.yml` file is). This is likely to take some time--probably between fifteen and forty-five minutes, depending on your machine and internet speed.

## Usage

While each of the services here have their own Dockerfile, and it is possible to interact with them directly via the `docker` CLI utility, they are meant to be orchestrated via `docker-compose`. The `docker-compose.yml` file in the repository root defines the relationships between containers, and they expect to be able to make network requests to named hosts defined on the network `docker-compose` brings up.


### Starting the cluster of services

Assuming you've built the images successfully, in the root directory of the repo run `docker-compose up`. This will bring up containers based on the images, in their internal dependency order as defined in `docker-compose.yml`.

Note that once they're up, docker-compose will continually stream their output to your terminal's STDOUT, with each line prefixed by the container name it comes from.

As it starts up, you'll see the redis and postgis containers reporting in first, as they don't have dependencies on other containers. The postgis container will have a lot of output on the initial run, because it will be creating the PostgreSQL database cluster (which persists on a docker volume) and installing extensions.

The windshaft and sqlapi containers will come up next, as they depend on postgis and redis. Finally the cartodb container will come up, and run its initial setup by creating the development database, running migrations, and creating a dev user based on the credentials from `CARTO_DEFAULT_USER`, `CARTO_DEFAULT_PASS`, and `CARTO_DEFAULT_EMAIL`.

You should be able to load the application by going to `subdomain.localhost` in a browser, where `subdomain` is the value of `CARTO_DEFAULT_USER`, and log in with the password in `CARTO_DEFAULT_PASS` (`abc123def` by default).

### Clearing the databases

If you need to remove the databases to force the containers to rebuild them, the easiest way to do that is to remove the docker volumes that the databases and postgres extensions are persisted on. There's a script in the root, `remove_docker_volumes.sh`, which will remove the appropriate volumes for you. Run `./remove_docker_volumes.sh --help` for more info. It runs with a manual confirmation step by default, so don't worry about accidentally dropping the volumes.

## Contributing

**If you are going to add values to the `.env` file, you should add them by modifying the `setup-local.sh` script, not by adding them directly to the `.env` file! Otherwise they will be blown away the next time `setup-local.sh --set-submodule-versions` is run.** Note also that `.env` is in the `.gitignore` file, since it should only be constructed by `setup-local.sh`.
