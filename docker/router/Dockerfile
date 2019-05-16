FROM nginx:1.15-alpine AS base

EXPOSE 80
EXPOSE 443

COPY nginx.conf /etc/nginx/nginx.conf
COPY cartodb.nginx.proxy.conf /etc/nginx/conf.d/default.conf
COPY ./ssl/wildcard-localhost.* /etc/ssl/

RUN chmod 644 /etc/ssl/*.crt \
 && chmod 640 /etc/ssl/*.key \
 && chown nginx:nginx /etc/ssl/wildcard-localhost.*

