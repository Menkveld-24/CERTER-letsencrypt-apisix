#! /bin/bash

# [CERTER]
# APISIX Letsencrypt certificate generator script
# Menke 2022

# Exit on any command fail
set -e

# Send the exit code
trap 'echo "Exited with exit code $?."' EXIT

# ENV variable validation
mail=${MAIL:?"is not set!"}
url=${APISIX_URL:?"is not set!"}
apikey=${APISIX_KEY:?"is not set!"}
domain=${DOMAIN:?"is not set!"}
host=${HOST:=$(hostname -i)}
ttl=${TTL:=60}
port=${PORT:=80}
stagingOrProd=${CERT_TYPE:="staging"}
deleteOtherCerts=${DELETE_OTHER_CERTS:=true}
ignoreSSL=$([ $CURL_IGNORESSL == "true" ] && echo "-k" || echo "")
showOutput=$([ $CURL_QUIET == "true" ] && echo "-o /dev/null" || echo "-o /tmp/debug_body")
debugCurl=$([ $CURL_DEBUG == "true" ] && echo "-v" || echo "")
agreeCertbotTOS=$([ $AGREE_TOS == "true" ] && echo "--agree-tos" || echo "")

echo "[CERTER} v1.0.0"
echo "[CERTER] Generating certificates for: $domain"

# Validate the response of any curl
validateHTTPResponse() {
    if [[ $CURL_QUIET != "true" ]]; then
        echo "[CERTER] Response with code $1: $(cat /tmp/debug_body)"
    fi
    if [[ $1 != 201 && $1 != 200 ]]; then 
        echo "[ERROR] HTTP response is a $1"
        exit 1
    fi
}

# Creating temporary route for the acme challenge
validateHTTPResponse `curl -H "X-API-KEY: $apikey" -s $ignoreSSL $debugCurl $showOutput -w "%{http_code}" -X POST -d "{
    \"uri\": \"/.well-known/acme-challenge/*\",
    \"name\": \"$domain certbot\",
    \"description\": \"Certbot signing route...\",
    \"host\": \"$domain\",
    \"priority\": 100,
    \"upstream\": {
        \"type\": \"roundrobin\",
        \"nodes\": {
            \"$host:$port\": 100
        }
    }
}" "$url/apisix/admin/routes?ttl=$ttl"`
echo "[CERTER] Created temporary acme challenge route!"

# Starting certbot to generate a certificate
echo "[CERTER] Certbot output vvvvvvvvvvvvvvvvvvvvvv"
if [[ $stagingOrProd == "production" ]]; then 
    echo "[CERTER] Generating production certificates...."
    certbot certonly --standalone --domains $domain --email $mail $agreeCertbotTOS --non-interactive
else
    echo "[CERTER] Generating staging certificates...."
    certbot certonly --standalone --staging --domains $domain --email $mail $agreeCertbotTOS --non-interactive
fi 
echo "[CERTER] Certbot output ^^^^^^^^^^^^^^^^^^^^^^"
echo "[CERTER] Generated certificates!"

# Cleaning up and deleting old certificates
if [[ $deleteOtherCerts == "true" ]]; then
    validateHTTPResonse=`curl -H "X-API-KEY: $apikey" -s $ignoreSSL $debugCurl -o /tmp/response -w "%{http_code}" -X GET "$url/apisix/admin/ssl"`

    deletedCerts=0
    for id in $(cat /tmp/response | jq -r ".node.nodes[]|select(.value.snis[0] == \"$domain\")|.value.id"); do
        validateHTTPResponse `curl -H "X-API-KEY: $apikey" -s $ignoreSSL $debugCurl $showOutput -w "%{http_code}" -X DELETE "$url/apisix/admin/ssl/$id"`
        deletedCerts=$(expr $deletedCerts + 1)
    done

    if [[ $deletedCerts -gt 0 ]]; then
        echo "[CERTER] Deleted $deletedCerts existing certificate(s)!"
    else
        echo "[CERTER] No certificates to clean up"
    fi
fi

# Saving new certificate
validateHTTPResponse `curl -H "X-API-KEY: $apikey" -s $ignoreSSL $debugCurl $showOutput -w "%{http_code}" -X POST -d "{
    \"cert\": \"$(cat /etc/letsencrypt/live/$domain/fullchain.pem)\",
    \"key\": \"$(cat /etc/letsencrypt/live/$domain/privkey.pem)\",
    \"snis\": [\"$domain\"],
    \"validity_end\": $(expr $(date +%s) + 90 \* 24 \* 60 \* 60)
}" "$url/apisix/admin/ssl"`

echo "[CERTER] Uploaded certificates!"
