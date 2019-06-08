FROM cartobuilder:latest

WORKDIR /carto

ENV CARTO_WINDSHAFT_REPO https://github.com/CartoDB/Windshaft-cartodb.git

RUN git clone --recursive ${CARTO_WINDSHAFT_REPO} \
 && cd /carto/Windshaft-cartodb \
 && git checkout ${CARTO_WINDSHAFT_VERSION} \
 && git submodule update --recursive \
 && npm install --unsafe-perm \
 && mkdir -p /carto/Windshaft-cartodb/logs

WORKDIR /carto/Windshaft-cartodb

COPY ./config/*.js /carto/Windshaft-cartodb/config/environments/
COPY ./docker-entrypoint.sh /carto/
COPY ./ssl/coriCA.pem /usr/local/share/ca-certificates/coriCA.crt

RUN update-ca-certificates

EXPOSE 8181

ENV CURLOPT_SSL_VERIFYPEER 0

ENTRYPOINT ["/carto/docker-entrypoint.sh"]

CMD []
