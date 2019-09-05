#!/bin/bash

# Script location variables
SCRIPT_NAME=$0
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(dirname ${SCRIPT_DIR})"

#### HELP DOCUMENTATION ######################################################

function display_help() {
    local help_text=""
    IFS='' read -r -d '' help_text <<EOF

Usage: $SCRIPT_NAME [<OPTIONS>]

Purpose: Generates certificates for configuring the stack to use HTTPS locally.

         The script generates the following files, in 'docker/ssl', based on
         the values given for SUBDOMAIN and DOMAIN. Assuming the defaults of
         'osscarto-multi' and 'localhost', those files would be:

           osscarto-multiCA.key    Cryptographic key that the Certificate
                                    Authority root certificate is based on.

           osscarto-multiCA.pem    The Certificate Authority root certificate.

           osscarto-multiCA.srl    List of serial numbers already used by the
                                    CA to create unique certificates.

           osscarto-multi.localhost.key   Cryptographic key that the SSL certificate
                                           is based on.

           osscarto-multi.localhost.csr   Certificate signing request for the SSL
                                           certificate, which allows it to be signed
                                           via the Certificate Authority root cert.

           osscarto-multi.localhost.crt    SSL certificate generated using the SSL key,
                                            the CA root certificate, and the certificate
                                            signing request.

         Note: If the osscarto-multiCA.key and osscarto-multiCA.pem files are found to
               already exist, they will not be recreated unless you use the
               --force flag. This is so that you won't have to reimport the
               .pem file into your development machine's trusted CA list every
               time you regenerate the SSL certificates.

Options:    -h|--help         Display this message and exit.

            -f|--force        (Re-)generate the CA root certificate, even if one
                              already exists in docker/ssl. If you do this, it
                              will be necessary to re-add the root cert .pem file
                              to your local trusted certificate store in order to
                              have the site certificate trusted by browsers.

            -q|--quiet        Suppress incidental output. Implies -y.

            -v|--verbose      Include output from commands.

            -i|--interactive  Use interactive mode to gather SSL cert settings.
                              Disallows --quiet.

            -y                Do not ask for confirmation of settings.

            --subdomain <STRING>    Subdomain to use in constructing the FQDN
                                    used as the 'Common Name' in generating the
                                    SSL certificate for the host. Defaults to
                                    'osscarto-multi'.

            --domain <STRING>       Domain + TLD to use in constructing the
                                    FQDN used as the 'Common Name' in the
                                    SSL certificate for the host.
                                    Defaults to 'localhost'.

            --country <STRING>      Two letter country code used in generating
                                    the SSL certificate. Defaults to 'US'.

            --state <STRING>        State used in generating the SSL certificate.
                                    Defaults to 'Vermont'.

            --locality <STRING>     Locality used in generating the SSL cert.
                                    Defaults to 'Hartland'.

            --organization <STRING> Organization name used in generating the
                                    SSL cert. Defaults to 'OSS-Carto-Org'.

            --org-unit <STRING>     Organization unit used in generating the
                                    SSL cert. Defaults to 'Engineering'.

            --email <EMAIL>         Email address used in the certificate.
                                    Defaults to 'noreply@example.com'.
EOF

    printf "$help_text"
}

#### VARIABLES AND CLI ARGS ##################################################

# CLI arg defaults
FORCE="no"
QUIET="no"
VERBOSE="no"
AUTORUN="no"
INTERACTIVE="no"

SUBDOMAIN="osscarto-multi"
DOMAIN="localhost"
COUNTRY="US"
STATE="Vermont"
LOCALITY="Hartland"
ORGANIZATION="OSS-Carto-Org"
ORG_UNIT="Engineering"
EMAIL="noreply@example.com"

# Set values from CLI args
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_help; exit 0; ;;
        -f|--force)
            FORCE="yes"; shift; ;;
        -q|--quiet)
            QUIET="yes"; shift; ;;
        -v|--verbose)
            VERBOSE="yes"; shift; ;;
        -i|--interactive)
            INTERACTIVE="yes"; shift; ;;
        -y)
            AUTORUN="yes"; shift; ;;
        --subdomain)
            shift; SUBDOMAIN="$1"; shift; ;;
        --domain)
            shift; DOMAIN="$1"; shift; ;;
        --country)
            shift; COUNTRY="$1"; shift; ;;
        --state)
            shift; STATE="$1"; shift; ;;
        --locality)
            shift; LOCALITY="$1"; shift; ;;
        --organization)
            shift; ORGANIZATION="$1"; shift; ;;
        --org-unit)
            shift; ORG_UNIT="$1"; shift; ;;
        --email)
            shift; EMAIL="$1"; shift; ;;
        *)
            break; ;;
    esac
done

OUTPUT_DEVICE="/dev/null"   # Output nothing from ssl commands by default
if [[ $VERBOSE = "yes" ]]; then 
    QUIET="no"
    OUTPUT_DEVICE="1" # stdout file handle
fi

if [[ $INTERACTIVE = "yes" ]]; then
    # --quiet doesn't work with --interactive
    QUIET="no"

    echo "The following values will be used to construct the SSL files."
    read -p "Subdomain [$SUBDOMAIN]: " subdomain_input
    SUBDOMAIN=${subdomain_input:-$SUBDOMAIN}
    read -p "Domain [$DOMAIN]: " domain_input
    DOMAIN=${domain_input:-$DOMAIN}
    read -p "Country code [$COUNTRY]: " country_input
    COUNTRY=${country_input:-$COUNTRY}
    read -p "State [$STATE]: " state_input
    STATE=${state_input:-$STATE}
    read -p "Locality [$LOCALITY]: " locality_input
    LOCALITY=${locality_input:-$LOCALITY}
    read -p "Organization [$ORGANIZATION]: " organization_input
    ORGANIZATION=${organization_input:-$ORGANIZATION}
    read -p "Organizational unit [$ORG_UNIT]: " org_unit_input
    ORG_UNIT=${org_unit_input:-$ORG_UNIT}
    read -p "Email address [$EMAIL]: " email_input
    EMAIL=${email_input:-$EMAIL}
fi

if [[ $QUIET != "yes" ]]; then
    echo "The certificate files will generate with these values:"
    echo ""
    echo "Subdomain:     $SUBDOMAIN"
    echo "Domain:        $DOMAIN"
    echo "Country code:  $COUNTRY"
    echo "State:         $STATE"
    echo "Locality:      $LOCALITY"
    echo "Organization:  $ORGANIZATION"
    echo "Org unit:      $ORG_UNIT"
    echo "Email:         $EMAIL"
    echo ""

    if [[ $AUTORUN != "yes" ]]; then
        printf "Proceed? [N/y]: "
        read AUTORUN
    fi
fi

if [[ ! $AUTORUN =~ ^[Yy][eE]?[sS]?$ ]]; then exit 1; fi

# Imputed values
FQDN="${SUBDOMAIN}.${DOMAIN}"
FQDN=$(echo $FQDN | sed 's/^\.//')  # remove leading period if no subdomain
if [[ $FQDN = $DOMAIN ]]; then SUBDOMAIN=$DOMAIN; fi
COMMON_NAME="${FQDN}"
PASSWORD="abc123def"

SSL_DIRECTORY="${REPO_ROOT}/local-ssl"
mkdir -p $SSL_DIRECTORY

SSL_BASE_NAME="${FQDN}"
SSL_KEYFILE="${SSL_DIRECTORY}/${SSL_BASE_NAME}.key"
SSL_CSRFILE="${SSL_DIRECTORY}/${SSL_BASE_NAME}.csr"
SSL_CERTFILE="${SSL_DIRECTORY}/${SSL_BASE_NAME}.crt"

# Certificate authority info variables
CA_BASE_NAME="${SUBDOMAIN}CA"
CA_KEYFILE="${SSL_DIRECTORY}/${CA_BASE_NAME}.key"
CA_ROOTCERT="${SSL_DIRECTORY}/${CA_BASE_NAME}.pem"

# Echo function
function echo_if_unquiet() {
    if [ "$QUIET" != "yes" ]; then
        printf "$1\n"
    fi
}

if [ ! -f ${CA_KEYFILE} ] || [ ! -f ${CA_ROOTCERT} ] || [ "$FORCE" == "yes" ]; then
    echo_if_unquiet "Generating private key for CA root certificate..."
    openssl genrsa -des3 -passout pass:${PASSWORD} -out ${CA_KEYFILE} 2048 1>&${OUTPUT_DEVICE} 2>&1

    echo_if_unquiet "Removing passphrase from CA root cert key..."
    openssl rsa -in ${CA_KEYFILE} -passin pass:${PASSWORD} -out ${CA_KEYFILE} 1>&${OUTPUT_DEVICE} 2>&1

    echo_if_unquiet "Generating root certificate from CA root cert key..."
    openssl req -x509 -new -nodes -key ${CA_KEYFILE} -sha256 -days 1825 -out ${CA_ROOTCERT} \
        -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=$ORG_UNIT/CN=${COMMON_NAME}/emailAddress=${EMAIL}" 1>&${OUTPUT_DEVICE} 2>&1
else
    echo_if_unquiet "\n*******\n\nSkipping generation of CA root cert key and root cert, as they already exist.\nUse --force to force regeneration of the .key and .pem files for the CA.\nYou will have to reinstall the .pem file to your local trusted CAs if you do so.\n\n*******\n"
fi

echo_if_unquiet "Generating private key for SSL certificate..."
openssl genrsa -out ${SSL_KEYFILE} 2048 1>&${OUTPUT_DEVICE} 2>&1

CSR_SUBJ="/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORG_UNIT}/CN=${FQDN}/emailAddress=${EMAIL}"

echo_if_unquiet "Creating certificate signing request for SSL cert, against CA root cert..."
openssl req -new -key ${SSL_KEYFILE} -out ${SSL_CSRFILE} -subj "${CSR_SUBJ}" 1>&${OUTPUT_DEVICE} 2>&1

SSL_CONFIG=""
IFS='' read -r -d '' SSL_CONFIG <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName=DNS:${FQDN}
EOF

openssl x509 -req -in ${SSL_CSRFILE} -CA ${CA_ROOTCERT} -CAkey ${CA_KEYFILE} -CAcreateserial \
    -out ${SSL_CERTFILE} -days 1825 -sha256 -extfile <(printf "$SSL_CONFIG") 1>&${OUTPUT_DEVICE} 2>&1

echo ""
echo "************************************************************************"
echo "*                                                                      "
echo "* SSL files have been generated to cover the hostname:                 "
echo "*                                                                      "
echo "*                    $FQDN                                             "
echo "*                                                                      "
echo "* In order to use them, you must take the following manual steps:      "
echo "*                                                                      "
echo "*    1) Add the file docker/ssl/${SUBDOMAIN}CA.pem to your machine's   "
echo "*       trusted certificate store, so that your browser can use it to  "
echo "*       authenticate the certificate which Nginx uses for signing.     "
echo "*    2) Add the following line to your /etc/hosts file:                "
echo "*                                                                      "
echo "*       127.0.0.1    $FQDN                                             "
echo "*                                                                      "
echo "************************************************************************"
echo ""

