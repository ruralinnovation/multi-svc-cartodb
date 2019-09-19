FROM cartobase:latest

WORKDIR /carto

ENV SQLAPI_REPO https://github.com/CartoDB/CartoDB-SQL-API.git

ARG SQLAPI_VERSION

RUN git config --global advice.detachedHead false \
 && git clone --recursive ${SQLAPI_REPO} \
 && cd /carto/CartoDB-SQL-API \
 && git checkout ${SQLAPI_VERSION} \
 && git submodule update --recursive \
 && npm install --unsafe-perm \
 && npm install --unsafe-perm \
 && mkdir -p /carto/CartoDB-SQL-API/logs \
 && rm -r /tmp/npm-* /root/.npm 

WORKDIR /carto/CartoDB-SQL-API/config/environments

COPY ./config/sqlapi-config.js ./development.js
COPY ./config/sqlapi-config.js ./staging.js
COPY ./config/sqlapi-config.js ./test.js
COPY ./config/sqlapi-config.js ./production.js

COPY ./entrypoint.sh /carto/
COPY ./ssl/osscarto-multiCA.pem /usr/local/share/ca-certificates/osscartoCA.crt

WORKDIR /carto/CartoDB-SQL-API

RUN update-ca-certificates

EXPOSE 8080

ENTRYPOINT ["/carto/entrypoint.sh"]

CMD []
