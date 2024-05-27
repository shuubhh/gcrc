#!/bin/bash

SERVICE_NAME="tf-ko-test01"
YAML_FILE="spec.yaml"

export KO_DOCKER_REPO=asia-south1-docker.pkg.dev/civic-replica-421010/example

#fetch URL of Cloud Run service

get_service_url() {
    URL=$(gcloud run services describe $SERVICE_NAME --region=us-central1 --format='value(status.url)')
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
        sleep 1
    fi
done
