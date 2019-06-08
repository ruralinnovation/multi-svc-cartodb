#!/bin/bash

# Script location variables
SCRIPT_NAME=$0
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

function display_help() {
    local help_text=""
    IFS='' read -r -d '' help_text <<EOF

Usage: $SCRIPT_NAME [--force]

Purpose: Creates a directory local to the script, named 'ssl', then generates
         within that directory the following files:

           coriCA.key              Cryptographic key that the Certificate
                                    Authority root certificate is based on.

           coriCA.pem              The Certificate Authority root certificate.

           coriCA.srl              List of serial numbers already used by the
                                    CA to create unique certificates.

           cori.localhost.key      Cryptographic key that the SSL certificate
                                    is based on.

           cori.localhost.csr      Certificate signing request for the SSL
                                    certificate, which allows it to be signed
                                    via the Certificate Authority root cert.

           cori.localhost.crt      SSL certificate generated using the SSL key,
                                    the CA root certificate, and the certificate
                                    signing request.

         Note: If the coriCA.key and coriCA.pem files are found to already exist,
               they will not be recreated unless you use the --force flag. This 
               is so that you won't have to reimport the .pem file into your
               development machine's trusted CA list every time you regenerate
               the SSL certificates.

         Once those files are generated, the following happens:

           1. The cori.localhost.key and cori.localhost.crt files are copied
              into docker/router/ssl, so that they will be available within
              the build context of the router container's Dockerfile. The
              Nginx reverse proxy requires the key and cert files in order to
              serve content over HTTPS.
           2. The coriCA.pem CA root certificate file, which is used to
              verify the integrity of the cori.localhost.crt certificate, is
              copied into the 'ssl' directories within the build context of
              all the other containers, so that it can be placed into the 
              trusted certificate stores of each container.

         If each container has (and trusts) the root certificate that the 
         cori.localhost.crt file was signed with, then any process on that
         host which is aware of the system's trusted Certificate Authorities
         will consider the cori.localhost.crt file to be legitimate.

Flags:
        --force     Generates the CA root certificate even if one already exists.

EOF

    printf "$help_text"
}

FORCE="no"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        --force)
            FORCE="yes"
            shift
            ;;
        *)                                                                      
            break                                                               
            ;;                                                                  
    esac                                                                        
done

#### PRINT UNLESS QUIET FUNCTION #############################################

QUIET="no"
function echo_if_unquiet() {
    if [ "$QUIET" != "yes" ]; then
        printf "$1\n"
    fi
}

# SSL certificate info variables
DOMAIN="cori.localhost"
COMMON_NAME="${DOMAIN}"
COUNTRY="US"
STATE="Vermont"
LOCALITY="Hartland"
ORGANIZATION="CORI"
ORG_UNIT="Engineering"
EMAIL="noreply@ruralinnovation.us"
PASSWORD="abc123def"

SSL_BASE_NAME="${DOMAIN}"
SSL_KEYFILE="${SCRIPT_DIR}/ssl/${SSL_BASE_NAME}.key"
SSL_CSRFILE="${SCRIPT_DIR}/ssl/${SSL_BASE_NAME}.csr"
SSL_CERTFILE="${SCRIPT_DIR}/ssl/${SSL_BASE_NAME}.crt"

# Certificate authority info variables
CA_BASE_NAME="coriCA"
CA_KEYFILE="${SCRIPT_DIR}/ssl/${CA_BASE_NAME}.key"
CA_ROOTCERT="${SCRIPT_DIR}/ssl/${CA_BASE_NAME}.pem"

echo_if_unquiet "Creating 'ssl' directories if they don't already exist..."

mkdir -p ${SCRIPT_DIR}/ssl

docker_contexts=$(find ${SCRIPT_DIR}/docker ! -path ${SCRIPT_DIR}/docker -type d -maxdepth 1)

for dc in $docker_contexts; do
    mkdir -p $dc/ssl
done

if [ ! -f ${CA_KEYFILE} ] || [ ! -f ${CA_ROOTCERT} ] || [ "$FORCE" == "yes" ]; then
    echo_if_unquiet "Generating private key for CA root certificate..."
    openssl genrsa -des3 -passout pass:${PASSWORD} -out ${CA_KEYFILE} 2048

    echo_if_unquiet "Removing passphrase from CA root cert key..."
    openssl rsa -in ${CA_KEYFILE} -passin pass:${PASSWORD} -out ${CA_KEYFILE}

    echo_if_unquiet "Generating root certificate from CA root cert key..."
    openssl req -x509 -new -nodes -key ${CA_KEYFILE} -sha256 -days 1825 -out ${CA_ROOTCERT} \
        -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=$ORG_UNIT/CN=${COMMON_NAME}/emailAddress=${EMAIL}"
else
    echo_if_unquiet "\n*******\n\nSkipping generation of CA root cert key and root cert, as they already exist. Use --force to force regeneration of the .key and .pem files for the CA. You will have to reinstall the .pem file to your local trusted CAs if you do so.\n\n*******\n"
fi

echo_if_unquiet "Generating private key for SSL certificate..."
openssl genrsa -out ${SSL_KEYFILE} 2048

CSR_SUBJ="/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORG_UNIT}/CN=${DOMAIN}/emailAddress=${EMAIL}"

echo_if_unquiet "Creating certificate signing request for SSL cert, against CA root cert..."
openssl req -new -key ${SSL_KEYFILE} -out ${SSL_CSRFILE} -subj "${CSR_SUBJ}" 

SSL_CONFIG=""
IFS='' read -r -d '' SSL_CONFIG <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName=DNS:${DOMAIN}
EOF

openssl x509 -req -in ${SSL_CSRFILE} -CA ${CA_ROOTCERT} -CAkey ${CA_KEYFILE} -CAcreateserial \
    -out ${SSL_CERTFILE} -days 1825 -sha256 -extfile <(printf "$SSL_CONFIG")

echo_if_unquiet "Copying files to docker contexts..."
cp ${SSL_KEYFILE} ./docker/router/ssl
cp ${SSL_CERTFILE} ./docker/router/ssl

CONTAINERS="router cartodb windshaft sqlapi postgis redis varnish"
for container in $OTHER_CONTAINERS; do
    cp ${CA_ROOTCERT} ./docker/${container}/ssl/
done
