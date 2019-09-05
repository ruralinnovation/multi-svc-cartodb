FROM cartobuilder:latest

WORKDIR /carto

ENV WINDSHAFT_REPO https://github.com/CartoDB/Windshaft-cartodb.git

ARG WINDSHAFT_VERSION

RUN git config --global advice.detachedHead false \
 && git clone --recursive ${WINDSHAFT_REPO} \
 && cd /carto/Windshaft-cartodb \
 && git checkout ${WINDSHAFT_VERSION} \
 && git submodule update --recursive \
 && npm install --unsafe-perm \
 && mkdir -p /carto/Windshaft-cartodb/logs

WORKDIR /carto/Windshaft-cartodb/config/environments

COPY ./config/windshaft-config.js ./development.js
COPY ./config/windshaft-config.js ./staging.js
COPY ./config/windshaft-config.js ./test.js
COPY ./config/windshaft-config.js ./production.js
COPY ./entrypoint.sh /carto/
COPY ./ssl/osscarto-multiCA.pem /usr/local/share/ca-certificates/osscartoCA.crt

WORKDIR /carto/Windshaft-cartodb

RUN update-ca-certificates

EXPOSE 8181

ENTRYPOINT ["/carto/entrypoint.sh"]

CMD []
