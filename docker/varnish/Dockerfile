FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential \
    software-properties-common \
    wget \
    autotools-dev \
    automake \
    autoconf \
    libtool \
    libncurses-dev \
    xsltproc \
    groff-base \
    libpcre3-dev \
    pkg-config \
    libjemalloc-dev \
    libreadline7 \
    libreadline6-dev \
 && cd /opt \
 && wget http://varnish-cache.org/_downloads/varnish-3.0.7.tgz \
 && tar -zxf varnish-3.0.7.tgz \
 && cd varnish-3.0.7 \
 && ./configure --prefix=/opt/varnish \
 && make \
 && make install \
 && cd /opt \
 && rm -rf varnish-3.0.7 varnish-3.0.7.tgz \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get purge -y make automake autoconf wget

ARG VARNISH_HTTP_PORT="6081"
ENV VARNISH_HTTP_PORT=$VARNISH_HTTP_PORT

COPY ./entrypoint.sh /entrypoint.sh
COPY ./config/varnish.vcl /etc/varnish.vcl
COPY ./ssl/osscarto-multiCA.pem /usr/local/share/ca-certificates/osscartoCA.crt

EXPOSE $VARNISH_HTTP_PORT

RUN update-ca-certificates

ENTRYPOINT ["/entrypoint.sh"]
CMD []
