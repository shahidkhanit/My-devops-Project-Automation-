#!/bin/bash
set -e

CLOUD_PROVIDER=$1
COMPONENT=$2

if [ -z "$CLOUD_PROVIDER" ] || [ -z "$COMPONENT" ]; then
    echo "Usage: $0 [aws|azure|gcp] [kubernetes|monitoring|networking|storage|all]"
    exit 1
fi

BASE_DIR="infra-code/$CLOUD_PROVIDER"

apply_terraform() {
    local dir=$1
    echo "Applying Terraform in $dir..."
    
    cd "$dir"
    terraform init -upgrade
    terraform plan -out=tfplan
    terraform apply tfplan
    cd - > /dev/null
}

case $COMPONENT in
    "kubernetes")
        apply_terraform "$BASE_DIR/kubernetes"
        ;;
    "monitoring")
        apply_terraform "$BASE_DIR/monitoring"
        ;;
    "networking")
        apply_terraform "$BASE_DIR/networking"
        ;;
    "storage")
        apply_terraform "$BASE_DIR/storage"
        ;;
    "all")
        for comp in networking kubernetes storage monitoring; do
            if [ -d "$BASE_DIR/$comp" ]; then
                apply_terraform "$BASE_DIR/$comp"
            fi
        done
        ;;
    *)
        echo "Invalid component: $COMPONENT"
        exit 1
        ;;
esac

echo "Terraform apply completed for $CLOUD_PROVIDER/$COMPONENT"