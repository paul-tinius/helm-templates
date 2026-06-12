#!/bin/bash
# Test script for the example application chart

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Testing Example Application Chart"
echo "=========================================="
echo ""

# Function to print section header
print_section() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Function to run command and print output
run_command() {
    echo "Running: $@"
    echo ""
    eval "$@"
    echo ""
}

# Navigate to chart directory
cd "$CHART_DIR"

print_section "1. Update Helm Dependencies"
run_command helm dependency update

print_section "2. Lint Chart"
run_command helm lint .

print_section "3. Template Validation (Dry Run)"
run_command helm template my-app . --namespace production --dry-run --debug

print_section "4. Generate Manifests"
run_command helm template my-app . --namespace production > /tmp/example-app-output.yaml
run_command wc -l /tmp/example-app-output.yaml

print_section "5. Validate Generated Resources"
echo "Checking for expected resources..."
if grep -q "kind: ConfigMap" /tmp/example-app-output.yaml; then
    echo "✓ ConfigMap found"
else
    echo "✗ ConfigMap not found"
    exit 1
fi

if grep -q "kind: Secret" /tmp/example-app-output.yaml; then
    echo "✓ Secret found"
else
    echo "✗ Secret not found"
    exit 1
fi

if grep -q "kind: ServiceAccount" /tmp/example-app-output.yaml; then
    echo "✓ ServiceAccount found"
else
    echo "✗ ServiceAccount not found"
    exit 1
fi

if grep -q "kind: Deployment" /tmp/example-app-output.yaml; then
    echo "✓ Deployment found"
else
    echo "✗ Deployment not found"
    exit 1
fi

if grep -q "kind: Service" /tmp/example-app-output.yaml; then
    echo "✓ Service found"
else
    echo "✗ Service not found"
    exit 1
fi

if grep -q "kind: DestinationRule" /tmp/example-app-output.yaml; then
    echo "✓ DestinationRule found"
else
    echo "✗ DestinationRule not found"
    exit 1
fi

if grep -q "kind: Gateway" /tmp/example-app-output.yaml; then
    echo "✓ Gateway found"
else
    echo "✗ Gateway not found"
    exit 1
fi

if grep -q "kind: VirtualService" /tmp/example-app-output.yaml; then
    echo "✓ VirtualService found"
else
    echo "✗ VirtualService not found"
    exit 1
fi

print_section "6. Validate Labels"
echo "Checking for standard labels..."
if grep -q "app.kubernetes.io/name:" /tmp/example-app-output.yaml; then
    echo "✓ Standard labels found"
else
    echo "✗ Standard labels not found"
    exit 1
fi

print_section "7. Validate Annotations"
echo "Checking for global annotations..."
if grep -q "contact:" /tmp/example-app-output.yaml; then
    echo "✓ Global annotations found"
else
    echo "✗ Global annotations not found"
    exit 1
fi

print_section "8. Validate Template Rendering"
echo "Checking for template rendering..."
if grep -q "environment: production" /tmp/example-app-output.yaml; then
    echo "✓ Template rendering working"
else
    echo "✗ Template rendering not working"
    exit 1
fi

print_section "9. Test with Custom Values"
run_command helm template my-app . --namespace production --set global.labels.environment=staging --set replicaCount=1 > /tmp/example-app-custom.yaml
if grep -q "environment: staging" /tmp/example-app-custom.yaml; then
    echo "✓ Custom values override working"
else
    echo "✗ Custom values override not working"
    exit 1
fi

print_section "10. Test with Istio Disabled"
run_command helm template my-app . --namespace production --set istio.enabled=false > /tmp/example-app-no-istio.yaml
if ! grep -q "kind: DestinationRule" /tmp/example-app-no-istio.yaml; then
    echo "✓ Istio resources disabled correctly"
else
    echo "✗ Istio resources not disabled"
    exit 1
fi

print_section "11. Test with ConfigMap Disabled"
run_command helm template my-app . --namespace production --set configmap.enabled=false > /tmp/example-app-no-configmap.yaml
if ! grep -q "kind: ConfigMap" /tmp/example-app-no-configmap.yaml; then
    echo "✓ ConfigMap disabled correctly"
else
    echo "✗ ConfigMap not disabled"
    exit 1
fi

print_section "12. Test with Secret Disabled"
run_command helm template my-app . --namespace production --set secret.enabled=false > /tmp/example-app-no-secret.yaml
if ! grep -q "kind: Secret" /tmp/example-app-no-secret.yaml; then
    echo "✓ Secret disabled correctly"
else
    echo "✗ Secret not disabled"
    exit 1
fi

print_section "All Tests Passed! ✓"
echo ""
echo "Generated manifest saved to: /tmp/example-app-output.yaml"
echo "You can review it with: cat /tmp/example-app-output.yaml"
