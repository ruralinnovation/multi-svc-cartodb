FROM nginx:1.15-alpine AS base

EXPOSE 80
EXPOSE 443

COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./ssl/*.localhost.* /etc/ssl/
COPY ./ssl/*CA.pem /usr/local/share/ca-certificates/osscartoCA.crt

RUN chmod 644 /etc/ssl/*.crt \
 && chmod 640 /etc/ssl/*.key \
 && chown nginx:nginx /etc/ssl/*.localhost.* \
 && apk update \                                                                
 && apk add ca-certificates \                                                   
 && update-ca-certificates \                                                    
 && rm -rf /var/cache/apk/* 
