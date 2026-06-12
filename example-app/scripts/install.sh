#!/bin/bash
# Installation script for the example application chart

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
RELEASE_NAME="example-app"
NAMESPACE="production"
VALUES_FILE=""
DRY_RUN=false
CREATE_NAMESPACE=true

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --name NAME          Release name (default: example-app)"
    echo "  -s, --namespace NAMESPACE Namespace (default: production)"
    echo "  -f, --values FILE        Values file to use"
    echo "  -d, --dry-run           Perform a dry run installation"
    echo "  --no-create-namespace   Don't create namespace"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -n my-app -s staging -f custom-values.yaml"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -s|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -f|--values)
            VALUES_FILE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-create-namespace)
            CREATE_NAMESPACE=false
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Navigate to chart directory
cd "$CHART_DIR"

echo "=========================================="
echo "Installing Example Application Chart"
echo "=========================================="
echo "Release Name: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo "Dry Run: $DRY_RUN"
echo "=========================================="
echo ""

# Update Helm dependencies
echo "Updating Helm dependencies..."
helm dependency update

# Create namespace if needed
if [ "$CREATE_NAMESPACE" = true ] && [ "$DRY_RUN" = false ]; then
    echo "Creating namespace: $NAMESPACE"
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - || true
fi

# Build helm install command
HELM_CMD="helm install $RELEASE_NAME . --namespace $NAMESPACE"

if [ -n "$VALUES_FILE" ]; then
    if [ -f "$VALUES_FILE" ]; then
        HELM_CMD="$HELM_CMD --values $VALUES_FILE"
    else
        echo "Error: Values file not found: $VALUES_FILE"
        exit 1
    fi
fi

if [ "$DRY_RUN" = true ]; then
    HELM_CMD="$HELM_CMD --dry-run --debug"
fi

# Run helm install
echo ""
echo "Running: $HELM_CMD"
echo ""
eval $HELM_CMD

# Print installation notes if not dry run
if [ "$DRY_RUN" = false ]; then
    echo ""
    echo "=========================================="
    echo "Installation Complete!"
    echo "=========================================="
    echo ""
    echo "To view the deployment notes:"
    echo "  helm get notes $RELEASE_NAME --namespace $NAMESPACE"
    echo ""
    echo "To check the status:"
    echo "  helm status $RELEASE_NAME --namespace $NAMESPACE"
    echo ""
    echo "To uninstall:"
    echo "  helm uninstall $RELEASE_NAME --namespace $NAMESPACE"
    echo ""
fi
