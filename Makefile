.PHONY: help cluster-config cluster-build cluster-up cluster-down generate-ssl install generate-build use-build docker-build-cartobase packer-build-postgis cluster-purge-volumes
.DEFAULT_GOAL := help

buildconf?=DEFAULT

help:
	@echo "Usage: make [cluster-build|cluster-up|cluster-down]"

cluster-config:
	@bin/compose-build-specific --buildconf $(buildconf) config

cluster-build:
	@bin/compose-build-specific --buildconf $(buildconf) build

cluster-up:
	@bin/compose-build-specific --buildconf $(buildconf) up

cluster-down:
	@bin/compose-build-specific --buildconf $(buildconf) down

cluster-purge-volumes:
	@docker volume ls -f name=osscarto-multi --format '{{.Name}}' | xargs docker volume rm

generate-ssl:
	@printf "\nGenerating SSL certificates into local-ssl directory\n\n"
	bin/generate-ssl-certs.sh -i

install: generate-ssl docker-build-cartobase generate-build use-build packer-build-postgis

generate-build:
	@bin/build-named-stack-config.sh --buildconf $(buildconf)

use-build:
	@bin/configure-repo-for-named-build.sh --buildconf $(buildconf)

docker-build-cartobase:
	@docker build -t cartobase:latest docker/CARTOBASE

packer-build-postgis:
	@bin/packer-build-specific --buildconf $(buildconf) build
