#!/bin/bash
set -e

CLUSTER=$1
MIMIR_URL="https://mimir.example.com"

if [ "$CLUSTER" = "devops" ]; then
    TENANT_ID="_devops"
    ALERT_DIR="alerts/devops"
elif [ "$CLUSTER" = "apps" ]; then
    TENANT_ID="_apps"
    ALERT_DIR="alerts/apps"
else
    echo "Usage: $0 [devops|apps]"
    exit 1
fi

echo "Deploying alerts for cluster: $CLUSTER, tenant: $TENANT_ID"

./mimirtool rules load \
    --address="$MIMIR_URL" \
    --id="$TENANT_ID" \
    --key="$MIMIR_PASSWORD" \
    --user observe \
    $ALERT_DIR/*.yaml \
    alerts/common/*.yaml

echo "Alerts deployed successfully"