
# [CERTER]
## Letsencrypt APISIX certificate generator
---
[CERTER] is a Docker image that generates a Letsencrypt certificate and uploads it to [APISIX](https://apisix.apache.org/). Run this container every within every 90 days (Letsencrypt certificate expiration) to generate certificates for APISIX hassle-free!

### Lifecycle
1. A temporary route is created for certbot in APISIX. (prio 100)
2. Certbot created a letsencrypt certificate
3. Old certificates in APISIX are deleted
4. The new certificate is uploaded to APISIX

### Environment variables
| Name   |      Description      |  Default | Required |
|----------|-------------|------|:---:|
| DOMAIN | Domain for the certificate | null | Y |
| EMAIL | Email for the certificate | null | Y |
| APISIX_URL |  eg. http://ip:port | null | Y |
| APISIX_KEY |  APISIX admin api key | null | Y |
| AGREE_TOS | Agree to Certbot TOS | false | Y |
| CERT_TYPE | Generate staging or production certificates (staging/production) | staging | N |
| PORT | The external HTTP port of the container (Used for the temporary route to the container) | 80 | N |
| HOST | The ip address/domain of the container (Used for the temporary route to the container) | (ip of docker container) | N |
| TTL |  TTL for the temporary certbot route | 60 | N |
| DELETE_OTHER_CERTS |  Delete other present certificates for DOMAIN before uploading | true | N |
| CURL_DEBUG | Adds the -v flag to curl requests | false | N |
| CURL_QUIET | Displays curl output in terminal (including certificates) | false | N |
| CURL_IGNORESSL | Ignore ssl errors when making requests to APISIX | true | N |