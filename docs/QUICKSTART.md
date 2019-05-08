# TL;DR / Quickstart for Multi Service Carto

If you just want to get started without reading the detailed instructions, do the following:

1. Make sure Docker and git are installed on your system.
1. Run this (subbing in real values) to make sure your default Carto user will get set up with values you'll remember (by default it'll be username: `developer`, password: `dev123`, email: <code>username@example.com</code>). These values won't be securely stored, so just use a password value you'll remember.

    ```bash
    echo "export CARTO_DEFAULT_USER=jackjackson" >> ~/.bash_profile
    echo "export CARTO_DEFAULT_PASS=somepassword" >> ~/.bash_profile
    echo "export CARTO_DEFAULT_EMAIL=you@somedomain.tld" >> ~/.bash_profile
    source ~/.bash_profile
    ```

1. Clone the `multi-svc-cartodb` repository:

    ```bash
    cd /path/to/where/you/want/the/checkout
    git clone https://github.com/ruralinnovation/multi-svc-cartodb.git
    cd multi-svc-cartodb
    ```

1. In the repo, run the `setup-local.sh` script, which will populate some environment variables that the docker build will need, as well as check out the various submodules to the correct version tags. Then have your bash startup files source the script so the environment is populated for new terminals:

    ```bash
    source ./setup-local.sh --set-submodule-versions
    echo "source $PWD/setup-local.sh -q" >> ~/.bashrc
    echo "test -f ~/.bashrc && source ~/.bashrc" >> ~/.bash_profile
    ```

1. If all that went well, you should have a `.env` file in the root of the repo, and if you run `docker-compose config`, you should see your values for user/password/email substituted into the compose file.
1. Build the containers. This'll probably take a little while the first time.

    ```bash
    docker-compose build
    ```

1. Bring up the cluster:

    ```bash
    docker-compose up
    ```

1. Go to the Carto login screen at `http://localhost/` in a browser.
