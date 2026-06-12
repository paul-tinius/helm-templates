# Example Application

A production-ready example application demonstrating the full feature implementation of the Helm Templates library.

## Overview

This example chart demonstrates how to use all features of the Helm Templates library in a real-world scenario, including:

- **ConfigMap** - Application configuration management
- **Secret** - Sensitive data management
- **Deployment** - Application deployment with containers, probes, and scheduling
- **Service** - Service exposure with LoadBalancer type
- **ServiceAccount** - Service account with IAM role annotation
- **Istio Resources** - DestinationRule, Gateway, and VirtualService for service mesh
- **Notes** - Comprehensive deployment notes with troubleshooting commands

## Installation

### Prerequisites

- Helm 3.x installed
- Kubernetes cluster with Istio enabled (for Istio resources)
- AWS EKS or similar cloud provider (for LoadBalancer and IAM annotations)

### Install the Example Application

```bash
# Navigate to the example-app directory
cd example-app

# Update Helm dependencies
helm dependency update

# Install the chart
helm install my-app . --namespace production --create-namespace
```

### Install with Custom Values

```bash
helm install my-app . --namespace production \
  --set environment=staging \
  --set replicaCount=2 \
  --set image.tag=1.24
```

### Install from the Parent Directory

```bash
# From the helm-templates directory
helm install my-app ./example-app --namespace production --create-namespace
```

## Configuration

The example chart demonstrates all available features through its `values.yaml` file. Key configuration sections:

### Global Configuration

```yaml
global:
  labels:
    environment: production
    team: platform
  annotations:
    contact: platform-team@example.com
```

### Deployment Configuration

```yaml
deployment:
  replicas: 3
  strategy:
    type: RollingUpdate
  containers:
    - name: app
      image: nginx:1.25
      ports:
        - name: http
          containerPort: 8080
      resources:
        limits:
          cpu: 1000m
          memory: 1Gi
        requests:
          cpu: 500m
          memory: 512Mi
```

### Istio Configuration

```yaml
istio:
  enabled: true
  destinationRule:
    enabled: true
    trafficPolicy:
      loadBalancer:
        simple: LEAST_CONN
  gateway:
    enabled: true
    selector:
      istio: ingressgateway
  virtualService:
    enabled: true
    hosts:
      - app.example.com
```

## Testing

### Template Validation

```bash
# Validate the templates
helm template my-app . --namespace production

# Lint the chart
helm lint .
```

### Dry Run Installation

```bash
helm install my-app . --namespace production --dry-run --debug
```

### View Generated Manifests

```bash
helm template my-app . --namespace production > output.yaml
cat output.yaml
```

## Uninstall

```bash
helm uninstall my-app --namespace production
```

## Features Demonstrated

### 1. Labels and Annotations
- Global labels applied to all resources
- Pod-specific annotations for monitoring
- Template rendering support in values

### 2. ConfigMap
- Literal data with template rendering
- Custom labels and annotations
- Environment-specific configuration

### 3. Secret
- String data for sensitive information
- Template rendering for dynamic values
- Integration with deployment environment variables

### 4. Deployment
- Multiple containers with ports
- Resource limits and requests
- Liveness, readiness, and startup probes
- Volume mounts and volumes
- Node selector and tolerations
- Pod anti-affinity for high availability
- Security context configuration

### 5. Service
- LoadBalancer type with AWS annotations
- Custom service annotations
- Port configuration

### 6. ServiceAccount
- IAM role annotation for AWS EKS
- Custom annotations

### 7. Istio Resources
- DestinationRule with traffic policy and subsets
- Gateway with HTTP and HTTPS servers
- VirtualService with routing rules and retries

### 8. Notes
- Comprehensive deployment metadata
- Resource information
- Networking details
- Istio configuration summary
- Troubleshooting commands
- Custom notes

## Production Best Practices

This example demonstrates several production best practices:

1. **Resource Management** - Proper CPU and memory limits/requests
2. **High Availability** - Multiple replicas with pod anti-affinity
3. **Security** - Security context, non-root user, read-only filesystem
4. **Monitoring** - Prometheus annotations for metrics scraping
5. **Health Checks** - Liveness, readiness, and startup probes
6. **Rolling Updates** - Configured deployment strategy
7. **Service Mesh** - Istio configuration for traffic management
8. **Documentation** - Comprehensive notes for troubleshooting

## Customization

To customize this example for your own application:

1. Modify the `values.yaml` file with your application-specific settings
2. Update the container image and ports in the deployment section
3. Adjust resource limits based on your application requirements
4. Configure Istio resources based on your routing needs
5. Update labels and annotations to match your organization's standards

## Troubleshooting

After installation, view the deployment notes for troubleshooting commands:

```bash
helm status my-app --namespace production
helm get notes my-app --namespace production
```

Common troubleshooting commands are included in the notes:
- Get pod status
- View pod logs
- Describe deployment
- Describe service
- Check events
- Port-forward to service
- Exec into pod
