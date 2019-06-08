FROM cartobuilder:latest

WORKDIR /carto

ENV CARTO_CARTODB_REPO https://github.com/CartoDB/cartodb.git

RUN git clone --recursive ${CARTO_CARTODB_REPO} \
 && cd /carto/cartodb \
 && git checkout ${CARTO_CARTODB_VERSION} \
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
 && /bin/bash -l -c 'bundle install'

WORKDIR /carto/cartodb

RUN /bin/bash -l -c 'bundle exec grunt --force --environment=development'

ENV RAILS_ENV development


COPY ./config/*.yml /carto/cartodb/config/
COPY ./config/environments/*.rb /carto/cartodb/config/environments/
COPY ./config/environments/*.rb.front /carto/cartodb/config/environments/
COPY ./scripts/better_create_dev_user.sh /carto/cartodb/script/
COPY ./scripts/setup_organization.sh /carto/cartodb/script/
COPY ./scripts/sync_tables_trigger.sh /carto/cartodb/script/
COPY ./docker-entrypoint.sh /carto/
COPY ./ssl/coriCA.pem /usr/local/share/ca-certificates/coriCA.crt

RUN update-ca-certificates

ENV SYNC_TABLES_INTERVAL 3600
# TODO: This should probably be ARG based so non-dev instances still verify.
ENV CURLOPT_SSL_VERIFYPEER 0

EXPOSE 80

ENTRYPOINT ["/carto/docker-entrypoint.sh"]
