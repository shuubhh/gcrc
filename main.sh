#!/bin/bash

SERVICE_NAME="tf-ko-run-service"
YAML_FILE="spec.yaml"
JS_FILE="script.js"
#KO_DOCKER_REPO="asia-south1-docker.pkg.dev/civic-replica-421010/example"

#fetch URL of Cloud Run service

get_service_url() {
    URL=$(gcloud run services describe $SERVICE_NAME --region=asia-south1 --format='value(status.url)')
    if [ -n "$URL" ]; then
        echo "$URL"
    else
        echo ""
    fi
}

#run until URL is fetched

while true; do
    URL=$(get_service_url)
    if [ -n "$URL" ]; then
        ESC_URL=$(echo $URL | sed 's/[\/&]/\\&/g')
        sed -i "/address:/ s/$/ $ESC_URL/" $YAML_FILE
        echo "URL added to $YAML_FILE"
        break
    else
        echo "Waiting for Cloud Run service to provision..."
        sleep 2
    fi
done

get_api_gateway() {
    GATEWAY_URL=$(gcloud api-gateway gateways describe apii-gateway --location "asia-northeast1" --format json | jq -r .defaultHostname)
    if [ -n "$GATEWAY_URL" ]; then
        echo "$GATEWAY_URL"
    else
        echo ""
    fi
}

while true; do
    GATEWAY_URL=$(get_api_gateway)
    if [ -n "$GATEWAY_URL"]; then
        ESC_GATEWAY_URL=$(echo $GATEWAY_URL | sed 's/[\/&]/\\&/g')
        sed -i "s/API_GATEWAY_URL/$ESC_GATEWAY_URL/" $JS_FILE
        echo "API Gateway URL added to $JS_FILE"
        break
    else
        echo "Waiting for API Gateway to provision..."
        sleep 2
    fi
done