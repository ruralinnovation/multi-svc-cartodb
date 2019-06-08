FROM nginx:1.15-alpine AS base

EXPOSE 80
EXPOSE 443

COPY nginx.conf /etc/nginx/nginx.conf
COPY cartodb.nginx.proxy.conf /etc/nginx/conf.d/default.conf
COPY ./ssl/cori.localhost.* /etc/ssl/
COPY ./ssl/coriCA.pem /usr/local/share/ca-certificates/coriCA.crt

RUN chmod 644 /etc/ssl/*.crt \
 && chmod 640 /etc/ssl/*.key \
 && chown nginx:nginx /etc/ssl/cori.localhost.* \
 && apk update \                                                                
 && apk add ca-certificates \                                                   
 && update-ca-certificates \                                                    
 && rm -rf /var/cache/apk/* 
