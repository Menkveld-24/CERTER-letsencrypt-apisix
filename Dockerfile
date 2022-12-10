# [CERTER]
# APISIX Letsencrypt certificate generator Dockerfile
# Menke 2022

FROM alpine:3.14

# Default env variables
ENV TTL=60 \
    CERT_TYPE=staging \ 
    PORT=80 \ 
    CURL_DEBUG=false \
    CURL_QUIET=true \
    CURL_IGNORESSL=false \
    DELETE_OTHER_CERTS=true \
    AGREE_TOS=false

RUN apk update
RUN apk add bash certbot curl jq

ADD certer.sh /certer.sh
RUN ["chmod", "+x", "/certer.sh"]

EXPOSE 80
CMD ["/certer.sh"]


