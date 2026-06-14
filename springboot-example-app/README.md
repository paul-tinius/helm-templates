# Spring Boot Example Application

A Spring Boot example application demonstrating the `application-k8s-yaml.tpl` template for generating Kubernetes ConfigMap with Spring Boot configuration files.

## Overview

This example chart demonstrates how to use the `application-k8s-yaml.tpl` template from the Helm Templates library to generate a ConfigMap containing Spring Boot application configuration for Kubernetes. The template automatically creates a ConfigMap with a properly formatted `application-k8s.yaml` file with database, cache, and application-specific settings.

## Features

- **application-k8s-yaml.tpl Integration** - Automatic generation of ConfigMap with Spring Boot configuration
- **ConfigMap** - Stores the generated application-k8s.yaml file
- **Secret** - Manages sensitive data (database credentials)
- **Deployment** - Spring Boot application deployment with health checks
- **Service** - LoadBalancer service for external access
- **ServiceAccount** - Service account with IAM role annotation
- **Autoscaling** - Horizontal Pod Autoscaler configuration
- **Notes** - Comprehensive deployment notes with troubleshooting commands

## Installation

### Prerequisites

- Helm 3.x installed
- Kubernetes cluster
- AWS EKS or similar cloud provider (for LoadBalancer and IAM annotations)

### Install the Spring Boot Example Application

```bash
# Navigate to the springboot-example-app directory
cd springboot-example-app

# Update Helm dependencies
helm dependency update

# Install the chart
helm install my-springboot-app . --namespace production --create-namespace
```

### Install with Custom Values

```bash
helm install my-springboot-app . --namespace production \
  --set environment=staging \
  --set replicaCount=2 \
  --set image.tag=2.0.0
```

### Install from the Parent Directory

```bash
# From the helm-templates directory
helm install my-springboot-app ./springboot-example-app --namespace production --create-namespace
```

## Configuration

The example chart demonstrates the `application-k8s.tpl` template through its `values.yaml` file. Key configuration sections:

### Application Configuration

```yaml
environment: production
replicaCount: 3

image:
  repository: springboot-app
  pullPolicy: IfNotPresent
  tag: "1.0.0"
```

### ConfigMap Configuration (application-k8s-yaml.tpl)

The `configmap` section provides the data structure required by the `applicationK8s.render` template:

```yaml
configmap:
  enabled: true
  name: springboot-config
  enabled:
    datasource: true
    redis: true
    management: true
    app: true
    server: true
  data:
    database:
      host: postgres.example.com
      port: 5432
    cache:
      host: redis.example.com
      port: 6379
    app:
      env: production
      log_level: info
      feature_flags:
        enabled: true
        new_ui: false
  labels:
    component: config
```

The `configmap.enabled` section allows you to enable or disable specific configuration sections in the generated `application-k8s.yaml`:
- `datasource` - Database configuration (default: true)
- `redis` - Redis cache configuration (default: true)
- `management` - Spring Actuator configuration (default: true)
- `app` - Application-specific configuration (default: true)
- `server` - Server configuration (default: true)

If not specified, all sections are enabled by default for backward compatibility.

This configuration generates a ConfigMap with the following `application-k8s.yaml` content:

```yaml
spring:
  application:
    name: springboot-example-app
  profiles:
    active: production
  datasource:
    url: jdbc:postgresql://postgres.example.com:5432/appdb
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
    driver-class-name: org.postgresql.Driver
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000
  redis:
    host: redis.example.com
    port: 6379
    timeout: 60000
    lettuce:
      pool:
        max-active: 8
        max-idle: 8
        min-idle: 0
  management:
    endpoints:
      web:
        exposure:
          include: health,info,metrics,prometheus
    endpoint:
      health:
        show-details: always
    metrics:
      export:
        prometheus:
          enabled: true

app:
  environment: production
  log-level: info
  feature-flags:
    enabled: true
    new-ui: false

server:
  port: 8080
  compression:
    enabled: true
  tomcat:
    threads:
      max: 200
      min-spare: 10
```

### Secret Configuration

```yaml
secret:
  enabled: true
  name: springboot-secret
  type: Opaque
  stringData:
    database.username: app_user
    database.password: changeme
  labels:
    component: secret
```

### Deployment Configuration

```yaml
deployment:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  containers:
    - name: app
      image: springboot-app:1.0.0
      ports:
        - name: http
          containerPort: 8080
        - name: management
          containerPort: 8081
      livenessProbe:
        httpGet:
          path: /actuator/health
          port: management
      readinessProbe:
        httpGet:
          path: /actuator/health/readiness
          port: management
```

### Service Configuration

```yaml
service:
  type: LoadBalancer
  port: 80
  targetPort: 8080
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

### Autoscaling Configuration

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

## Testing

### Template Validation

```bash
# Validate the templates
helm template my-springboot-app . --namespace production

# Lint the chart
helm lint .
```

### Dry Run Installation

```bash
helm install my-springboot-app . --namespace production --dry-run --debug
```

### View Generated Manifests

```bash
helm template my-springboot-app . --namespace production > output.yaml
cat output.yaml
```

### View Generated ConfigMap

```bash
helm template my-springboot-app . --namespace production | grep -A 50 "kind: ConfigMap"
```

## Uninstall

```bash
helm uninstall my-springboot-app --namespace production
```

## Features Demonstrated

### 1. application-k8s-yaml.tpl Template
- Automatic generation of ConfigMap with Spring Boot configuration files
- Database, cache, and application settings
- Spring Actuator configuration for monitoring
- Environment-specific configuration

### 2. ConfigMap
- Stores the generated application-k8s.yaml file
- Custom labels and annotations
- Template rendering support

### 3. Secret
- String data for sensitive information
- Integration with deployment environment variables
- Database credentials management

### 4. Deployment
- Spring Boot application with health checks
- Liveness, readiness, and startup probes
- Management port configuration (8081)
- Resource limits and requests
- Volume mounts for ConfigMap

### 5. Service
- LoadBalancer type with AWS annotations
- Port configuration for application access

### 6. ServiceAccount
- IAM role annotation for AWS EKS
- Custom annotations

### 7. Autoscaling
- Horizontal Pod Autoscaler (HPA) configuration
- CPU and memory utilization targets

### 8. Notes
- Comprehensive deployment metadata
- Resource information
- Networking details
- Troubleshooting commands

## Production Best Practices

This example demonstrates several production best practices:

1. **Configuration Management** - Externalized configuration via ConfigMap
2. **Secret Management** - Sensitive data stored in Kubernetes Secrets
3. **Health Checks** - Spring Actuator endpoints for liveness and readiness
4. **Resource Management** - Proper CPU and memory limits/requests
5. **High Availability** - Multiple replicas with pod anti-affinity
6. **Security** - Security context, non-root user, read-only filesystem
7. **Monitoring** - Prometheus annotations for metrics scraping
8. **Scalability** - Horizontal Pod Autoscaler for automatic scaling
9. **Rolling Updates** - Configured deployment strategy with surge and unavailable limits

## Customization

To customize this example for your own Spring Boot application:

1. Modify the `configmap.data` section in `values.yaml` with your application-specific settings
2. Update the container image and ports in the deployment section
3. Adjust resource limits based on your application requirements
4. Configure the database and cache hosts/ports
5. Update labels and annotations to match your organization's standards

## Troubleshooting

After installation, view the deployment notes for troubleshooting commands:

```bash
helm status my-springboot-app --namespace production
helm get notes my-springboot-app --namespace production
```

Common troubleshooting commands are included in the notes:
- Get pod status
- View pod logs
- Describe deployment
- Describe service
- Check events
- Port-forward to service
- Exec into pod

## application-k8s-yaml.tpl Template Reference

The `application-k8s-yaml.tpl` template provides the `applicationK8s.render` template which expects the following values structure:

```yaml
configmap:
  name: "application-k8s"              # Optional: defaults to "application-k8s"
  enabled:
    datasource: true
    redis: true
    management: true
    app: true
    server: true
  data:
    database:
      host: "postgres"
      port: 5432
    cache:
      host: "redis"
      port: 6379
    app:
      env: "production"
      log_level: "info"
      feature_flags:
        enabled: true
        new_ui: false
```

The template uses:
- `.Chart.Name` for the Spring Boot application name
- `.Values.environment` for the active profile
- `.Values.configmap.data` for configuration data structure
- `.Values.configmap.enabled` for enable/disable flags per section (optional, defaults to true)
- `.Values.configmap.name` for custom ConfigMap name (optional, defaults to "application-k8s")

The template renders a complete ConfigMap manifest with the following helper templates:
- `applicationK8s.render` - Complete ConfigMap manifest
- `applicationK8s.getName` - ConfigMap name
- `applicationK8s.getFullName` - Fully qualified ConfigMap name
- `applicationK8s.labels` - ConfigMap labels
- `applicationK8s.data` - ConfigMap data section with application-k8s.yaml content

For more information on the template, see the template documentation in the Helm Templates library.
