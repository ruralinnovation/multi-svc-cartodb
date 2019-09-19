FROM cartobase:latest

WORKDIR /carto

ENV CARTO_CARTODB_REPO https://github.com/CartoDB/cartodb.git

ARG CARTODB_VERSION
ENV CARTODB_VERSION=$CARTODB_VERSION

ARG CARTO_ENV
ENV CARTO_ENV=$CARTO_ENV
ENV RAILS_ENV=$CARTO_ENV

RUN git clone --recursive ${CARTO_CARTODB_REPO} \
 && cd /carto/cartodb \
 && git checkout ${CARTODB_VERSION} \
 && git submodule update --recursive \
 && npm install --unsafe-perm \
 && rm -r /tmp/npm-* /root/.npm \
 && pip install --no-binary :all: -r python_requirements.txt \
 && gem install bundler --version=1.17.3 \
 && gem install \
    compass \
    archive-tar-minitar \
    rack \
 && bundle update thin \
 && /bin/bash -l -c 'bundle install' \
 && cp config/grunt_development.json config/grunt_true.json \
 && bundle exec grunt --force --environment=$CARTO_ENV

WORKDIR /opt/bin
COPY ./scripts/create-user-and-org.sh /opt/bin/create-user-and-org.sh
COPY ./entrypoint.sh /opt/bin/entrypoint.sh

WORKDIR /carto/cartodb

COPY ./config/cartodb-app_config.yml /carto/cartodb/config/app_config.yml
COPY ./config/cartodb-database.yml /carto/cartodb/config/database.yml
COPY ./ssl/osscarto-multiCA.pem /usr/local/share/ca-certificates/osscartoCA.crt

RUN update-ca-certificates

# Build args with defaults
ARG CARTODB_LISTEN_PORT="3000"
ENV CARTODB_LISTEN_PORT=$CARTODB_LISTEN_PORT

ARG STACK_SCHEME="https"
ENV STACK_SCHEME=$STACK_SCHEME

ARG GEOCODER_DB_NAME="dataservices_db"
ENV GEOCODER_DB_NAME=$GEOCODER_DB_NAME

ARG REDIS_HOST="redis"
ENV REDIS_HOST=$REDIS_HOST

ARG REDIS_LISTEN_PORT="6379"
ENV REDIS_LISTEN_PORT=$REDIS_LISTEN_PORT

ARG POSTGIS_HOST="postgis"
ENV POSTGIS_HOST=$POSTGIS_HOST

ARG POSTGIS_LISTEN_PORT="5432"
ENV POSTGIS_LISTEN_PORT=$POSTGIS_LISTEN_PORT

# Build args without defaults
ARG USER_ACCOUNT_USER_NAME
ENV USER_ACCOUNT_USER_NAME=$USER_ACCOUNT_USER_NAME

ARG USER_ACCOUNT_PASSWORD
ENV USER_ACCOUNT_PASSWORD=$USER_ACCOUNT_PASSWORD

ARG USER_ADMIN_PASSWORD
ENV USER_ADMIN_PASSWORD=$USER_ADMIN_PASSWORD

ARG USER_ACCOUNT_EMAIL
ENV USER_ACCOUNT_EMAIL=$USER_ACCOUNT_EMAIL

ARG ORG_ACCOUNT_ORG_NAME
ENV ORG_ACCOUNT_ORG_NAME=$ORG_ACCOUNT_ORG_NAME

ARG ORG_ACCOUNT_USER_NAME
ENV ORG_ACCOUNT_USER_NAME=$ORG_ACCOUNT_USER_NAME

ARG ORG_ACCOUNT_EMAIL
ENV ORG_ACCOUNT_EMAIL=$ORG_ACCOUNT_EMAIL

ARG ORG_ACCOUNT_PASSWORD
ENV ORG_ACCOUNT_PASSWORD=$ORG_ACCOUNT_PASSWORD


EXPOSE $CARTODB_LISTEN_PORT

ENTRYPOINT ["/opt/bin/entrypoint.sh"]

CMD [""]
