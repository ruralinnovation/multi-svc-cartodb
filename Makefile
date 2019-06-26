.PHONY : init setup-local generate-ssl-certs generate-ssl-all

init : setup-local generate-ssl-all

setup-local :
	@printf "Writing contents of .env file in repo root..."
	@./scripts/setup-local.sh
	@printf "DONE\n"

generate-ssl-certs :
	@printf "Generating SSL directories and files..."
	@./scripts/generate_ssl_certs.sh
	@printf "DONE\n"

generate-ssl-all :
	@printf "Generating SSL directories, files, and root authority..."
	@./scripts/generate_ssl_certs.sh --force
	@printf "DONE\n"
	@printf "!!! Make sure to add the root authority .pem file to your local trusted certs. !!!"


