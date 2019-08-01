FROM cartobuilder:latest

WORKDIR /carto

ENV SQLAPI_REPO https://github.com/CartoDB/CartoDB-SQL-API.git

RUN git clone --recursive ${SQLAPI_REPO} \
 && cd /carto/CartoDB-SQL-API \
 && git checkout ${SQLAPI_VERSION} \
 && git submodule update --recursive \
 && npm install --unsafe-perm \
 && npm install --unsafe-perm \
 && mkdir -p /carto/CartoDB-SQL-API/logs \
 && rm -r /tmp/npm-* /root/.npm 

WORKDIR /carto/CartoDB-SQL-API/config/environments

COPY ./config/sqlapi-env-aware-config.js ./development.js
COPY ./config/sqlapi-env-aware-config.js ./staging.js
COPY ./config/sqlapi-env-aware-config.js ./test.js
COPY ./config/sqlapi-env-aware-config.js ./production.js

COPY ./docker-entrypoint.sh /carto/
COPY ./ssl/osscartoCA.pem /usr/local/share/ca-certificates/osscartoCA.crt

WORKDIR /carto/CartoDB-SQL-API

RUN update-ca-certificates

EXPOSE 8080

ENTRYPOINT ["/carto/docker-entrypoint.sh"]

CMD []
