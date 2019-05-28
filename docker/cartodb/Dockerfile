FROM cartobuilder:latest

WORKDIR /carto

ENV CARTO_CARTODB_REPO https://github.com/CartoDB/cartodb.git

RUN git clone --recursive ${CARTO_CARTODB_REPO} \
 && cd /carto/cartodb \
 && git checkout ${CARTO_CARTODB_VERSION} \
 && git submodule update --recursive \
 && npm install --unsafe-perm \
 && pip install --no-binary :all: -r python_requirements.txt \
 && gem install bundler --version=1.17.3 \
 && gem install compass \
 && bundle update thin \
 && /bin/bash -l -c 'bundle install' \
 && cp config/grunt_development.json config/grunt_true.json \
 && /bin/bash -l -c 'bundle exec grunt --force'

ENV RAILS_ENV development

WORKDIR /carto/cartodb

COPY ./config/*.yml /carto/cartodb/config/
COPY ./config/environments/*.rb /carto/cartodb/config/environments/
COPY ./config/environments/*.rb.front /carto/cartodb/config/environments/
COPY ./scripts/better_create_dev_user.sh /carto/cartodb/script/
COPY ./scripts/setup_organization.sh /carto/cartodb/script/
COPY ./docker-entrypoint.sh /carto/

EXPOSE 80

ENTRYPOINT ["/carto/docker-entrypoint.sh"]
