#!/bin/bash
set -e

MIMIR_URL="https://mimir.example.com"

echo "Deploying alertmanager configs..."

# Deploy DevOps alertmanager
./mimirtool alertmanager load \
    --address="$MIMIR_URL" \
    --id="_devops" \
    --key="$MIMIR_PASSWORD" \
    --user observe \
    alertmanager/devops/alertmanager.yaml \
    alertmanager/templates/slack.tmpl

# Deploy Apps alertmanager  
./mimirtool alertmanager load \
    --address="$MIMIR_URL" \
    --id="_apps" \
    --key="$MIMIR_PASSWORD" \
    --user observe \
    alertmanager/apps/alertmanager.yaml \
    alertmanager/templates/slack.tmpl

echo "Alertmanager configs deployed successfully"