.PHONY: help compose-config compose-build compose-up compose-down generate-ssl install generate-build use-build docker-build-cartobase packer-build-postgis compose-purge-volumes
.DEFAULT_GOAL := help

buildconf?=DEFAULT

help:
	@echo "Usage: make [COMMAND] [buildconf=<BUILD_NAME>]"
	@echo ""
	@echo "Repo and build-configuration commands:"
	@echo ""
	@echo "    install                  - Meta-command, runs the following:"
	@echo "                                 docker-build-cartobase"
	@echo "                                 generate-build"
	@echo "                                 use-build"
	@echo "                                 packer-build-postgis"
	@echo "                                 compose-build"
	@echo ""
	@echo "    generate-ssl             - Runs the script bin/generate-ssl-certs.sh"
	@echo "                               in interactive mode, which will prompt"
	@echo "                               for values to use when creating SSL certs."
	@echo ""
	@echo "    docker-build-cartobase   - Runs 'docker build' to create the base"
	@echo "                               image ('cartobase:latest') that the"
	@echo "                               cartodb, windshaft, and sqlapi images"
	@echo "                               use as a starting point."
	@echo ""
	@echo "    generate-build           - For the supplied buildconf (DEFAULT by"
	@echo "                               default), generates config and env files"
	@echo "                               in a matching directory in builds/."
	@echo ""
	@echo "    use-build                - For the specified buildconf, copies the"
	@echo "                               built config files to the appropriate"
	@echo "                               docker contexts. Also copies the SSL"
	@echo "                               certificates from local-ssl to the"
	@echo "                               docker contexts that use them."
	@echo ""
	@echo "    packer-build-postgis     - Runs the 'packer build' command to"
	@echo "                               create the 'osscarto-multi-postgis:latest"
	@echo "                               image that Docker Compose includes as the"
	@echo "                               'postgis' part of the local stack."
	@echo ""
	@echo "Commands for controlling built Docker Compose cluster:"
	@echo ""
	@echo "     Note that these all run the corresponding 'docker-compose' command,"
	@echo "      using the env values appropriate to the named build-configuration."
	@echo "      (This is done via bin/compose-build-specific, if you want details.)"
	@echo ""
	@echo "    compose-config"
	@echo "    compose-build"
	@echo "    compose-up"
	@echo "    compose-down"
	@echo ""
	@echo "    compose-purge-volumes - This one is different. It will remove the"
	@echo "                            docker volumes that are named in the compose"
	@echo "                            file. Useful if you need to re-initialize the"
	@echo "                            PostgreSQL database."
	@echo ""

compose-config:
	@bin/compose-build-specific --buildconf $(buildconf) config

compose-build:
	@bin/compose-build-specific --buildconf $(buildconf) build

compose-up:
	@bin/compose-build-specific --buildconf $(buildconf) up

compose-down:
	@bin/compose-build-specific --buildconf $(buildconf) down

compose-purge-volumes:
	@docker volume ls -f name=osscarto-multi --format '{{.Name}}' | xargs docker volume rm

generate-ssl:
	@printf "\nGenerating SSL certificates into local-ssl directory\n\n"
	bin/generate-ssl-certs.sh -i

install: docker-build-cartobase generate-build use-build packer-build-postgis compose-build
	@echo ""
	@echo "*********************************************************************"
	@echo "*                                                                   *"
	@echo "*  Installation complete!                                           *"
	@echo "*                                                                   *"
	@echo "*  To start your local cluster, run                                 *"
	@echo "*                                                                   *"
	@echo "*      make compose-up                                              *"
	@echo "*                                                                   *"
	@echo "*********************************************************************"
	@echo ""

generate-build:
	@bin/build-named-stack-config.sh --buildconf $(buildconf)

use-build:
	@bin/configure-repo-for-named-build.sh --buildconf $(buildconf)

docker-build-cartobase:
	@docker build -t cartobase:latest docker/CARTOBASE

packer-build-postgis:
	bin/packer-build-specific --buildconf $(buildconf) build
