FROM cartobuilder:latest

WORKDIR /carto

ENV CARTO_SQLAPI_REPO https://github.com/CartoDB/CartoDB-SQL-API.git

RUN git clone --recursive ${CARTO_SQLAPI_REPO} \
 && cd /carto/CartoDB-SQL-API \
 && git checkout ${CARTO_SQLAPI_VERSION} \
 && git submodule update --recursive \
 && npm install --unsafe-perm \
 && npm install --unsafe-perm \
 && mkdir -p /carto/CartoDB-SQL-API/logs \
 && rm -r /tmp/npm-* /root/.npm 

COPY ./config/*.js /carto/CartoDB-SQL-API/config/environments/
COPY ./docker-entrypoint.sh /carto/

EXPOSE 8080

WORKDIR /carto/CartoDB-SQL-API

ENTRYPOINT ["/carto/docker-entrypoint.sh"]

CMD []
