# Helm Templates Library

A comprehensive Helm library chart providing reusable template helpers for Kubernetes resources. This library chart is designed to be included as a dependency in other Helm charts to provide consistent, well-tested template helpers for common Kubernetes objects.

## Overview

This library chart includes template helpers for:

- **Labels** - Standard Kubernetes labels with selector support
- **Annotations** - Global and pod-specific annotations
- **Names** - Resource naming with truncation and override support
- **ConfigMap** - ConfigMap creation with literal and file-based data
- **Deployment** - Deployment with containers, volumes, probes, and scheduling
- **Service** - Service with all types (ClusterIP, NodePort, LoadBalancer, ExternalName)
- **ServiceAccount** - ServiceAccount creation and management
- **Secret** - Secret creation with various data sources
- **Istio** - DestinationRule, Gateway, and VirtualService resources
- **Notes** - Comprehensive deployment notes with troubleshooting commands and Mattermost integration

## Installation as a Dependency

Add this library chart as a dependency in your `Chart.yaml`:

```yaml
dependencies:
  - name: helm-templates
    repository: file://../helm-templates
    version: 0.0.4
```

Then run:

```bash
helm dependency update
```

## Usage

### Labels

Generate standard Kubernetes labels:

```yaml
{{- include "labels.default" . | nindent 4 }}
```

Generate selector labels for pod matching:

```yaml
{{- include "labels.selectorLabels" . | nindent 4 }}
```

**Expected values structure:**

```yaml
global:
  labels:
    key1: "value1"
    key2: "{{ .Release.Name }}-value"
nameOverride: "my-name"
fullnameOverride: "my-full-name"
```

### Annotations

Generate global annotations:

```yaml
{{- include "annotations" . | nindent 4 }}
```

Generate pod-specific annotations:

```yaml
{{- include "podAnnotations" . | nindent 4 }}
```

**Expected values structure:**

```yaml
global:
  annotations:
    key1: "value1"
podAnnotations:
  key1: "value1"
  key2: "value2"
```

### Names

Generate chart name with version:

```yaml
{{- include "names.chart" . }}
```

Generate fully qualified name:

```yaml
{{- include "names.fullName" . }}
```

Generate chart name:

```yaml
{{- include "names.name" . }}
```

Generate service account name:

```yaml
{{- include "names.serviceAccountName" . }}
```

Generate hostname:

```yaml
{{- include "names.hostname" . }}
```

Generate fully qualified hostname:

```yaml
{{- include "names.fullQualifiedHostname" . }}
```

**Expected values structure:**

```yaml
nameOverride: "my-name"
fullnameOverride: "my-full-name"
global:
  nameOverride: "global-name"
  fullnameOverride: "global-full-name"
serviceAccount:
  create: true
  name: "my-service-account"
```

### ConfigMap

Render a ConfigMap:

```yaml
{{- include "configmap.render" (dict "root" $ "configmap" $Values.configmap.myConfig) }}
```

**Expected values structure:**

```yaml
configmap:
  name: "my-config"
  data:
    key1: "value1"
    key2: "value2"
  dataFrom:
    - file: "/path/to/file"
      key: "config-file"
  labels: {}
  annotations: {}
```

### Deployment

Render a Deployment:

```yaml
{{- include "deployment.render" (dict "root" $ "deployment" $Values.deployment) }}
```

**Expected values structure:**

```yaml
deployment:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  minReadySeconds: 0
  revisionHistoryLimit: 10
  containers:
    - name: app
      image: nginx:latest
      ports:
        - containerPort: 80
      env:
        - name: ENV_VAR
          value: "value"
      resources:
        limits:
          cpu: 500m
          memory: 512Mi
        requests:
          cpu: 250m
          memory: 256Mi
      livenessProbe:
        httpGet:
          path: /health
          port: 80
      readinessProbe:
        httpGet:
          path: /ready
          port: 80
  volumes:
    - name: config
      configMap:
        name: my-config
  volumeMounts:
    - name: config
      mountPath: /etc/config
  nodeSelector: {}
  tolerations: []
  affinity: {}
  labels: {}
  annotations: {}
```

### Service

Render a Service:

```yaml
{{- include "service.render" (dict "root" $ "service" $Values.service) }}
```

**Expected values structure:**

```yaml
service:
  name: "my-service"
  type: ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: 8080
      protocol: TCP
      nodePort: 30080
  selector: {}
  sessionAffinity: None
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
  externalIPs: []
  loadBalancerIP: ""
  loadBalancerSourceRanges: []
  externalTrafficPolicy: Cluster
  healthCheckNodePort: 0
  publishNotReadyAddresses: false
  ipFamilies: []
  ipFamilyPolicy: SingleStack
  labels: {}
  annotations: {}
```

### ServiceAccount

Render a ServiceAccount:

```yaml
{{- include "serviceaccount.render" (dict "root" $ "serviceaccount" $Values.serviceAccount) }}
```

**Expected values structure:**

```yaml
serviceAccount:
  create: true
  name: "my-service-account"
  annotations: {}
  labels: {}
```

### Secret

Render a Secret:

```yaml
{{- include "secret.render" (dict "root" $ "secret" $Values.secret) }}
```

**Expected values structure:**

```yaml
secret:
  name: "my-secret"
  type: Opaque
  data:
    key1: "value1"
    key2: "value2"
  dataFrom:
    - file: "/path/to/file"
      key: "secret-file"
  stringData:
    key1: "value1"
  labels: {}
  annotations: {}
```

### Istio Resources

#### DestinationRule

```yaml
{{- include "destinationrule.render" (dict "root" $ "destinationrule" $Values.istio.destinationRule) }}
```

#### Gateway

```yaml
{{- include "gateway.render" (dict "root" $ "gateway" $Values.istio.gateway) }}
```

#### VirtualService

```yaml
{{- include "virtualservice.render" (dict "root" $ "virtualservice" $Values.istio.virtualService) }}
```

### Notes

Generate comprehensive deployment notes:

```yaml
{{- include "notes.full" . }}
```

Generate deployment-specific notes:

```yaml
{{- include "notes.deployment" . }}
```

Generate pod-specific notes:

```yaml
{{- include "notes.pod" . }}
```

Generate service-specific notes:

```yaml
{{- include "notes.service" . }}
```

Generate ConfigMap-specific notes:

```yaml
{{- include "notes.configMap" . }}
```

Generate Secret-specific notes:

```yaml
{{- include "notes.secret" . }}
```

Generate Mattermost webhook payload:

```yaml
{{- include "notes.mattermostWebhookPayload" . }}
```

**Expected values structure:**

```yaml
notes:
  enabled: true
  includeCommon: true
  includeResources: true
  includeNetworking: true
  includeIstio: true
  includeMattermost: true
  includeTroubleshooting: true
  customNotes:
    documentation: "https://docs.example.com"
    slack_channel: "#platform-apps"
service:
  type: LoadBalancer
  port: 80
ingress:
  enabled: true
  hosts:
    - app.example.com
istio:
  destinationRule:
    enabled: true
    host: my-service.default.svc.cluster.local
  gateway:
    enabled: true
    selector:
      istio: ingressgateway
  virtualService:
    enabled: true
    hosts:
      - app.example.com
    gateways:
      - my-gateway
mattermost:
  enabled: true
  webhookUrl: "https://mattermost.example.com/hooks/..."
  channel: "deployments"
  username: "Helm"
  iconUrl: "https://example.com/icon.png"
```

## Features

- **Consistent Naming**: All resources follow Kubernetes naming conventions with automatic truncation to 63 characters
- **Template Rendering**: All values support Helm template rendering using `tpl`
- **Validation**: Built-in validation helpers for each resource type
- **Override Support**: Global and local override support for names, labels, and annotations
- **Selector Labels**: Automatic selector label generation for pod matching
- **Standard Labels**: Includes standard Kubernetes labels following best practices

## Template Helper Reference

### Labels Library (`templates/_labels.tpl`)

- `labels.default` - Standard labels shared across objects
- `labels.selectorLabels` - Selector labels for pod matching

### Annotations Library (`templates/_annotations.tpl`)

- `annotations` - Global annotations
- `podAnnotations` - Pod-specific annotations

### Names Library (`templates/_names.tpl`)

- `names.chart` - Chart name and version
- `names.fullName` - Fully qualified app name
- `names.name` - Chart name
- `names.serviceAccountName` - Service account name
- `names.hostname` - Short hostname
- `names.fullQualifiedHostname` - Fully qualified hostname
- `name.truncateName` - Truncate name to 63 chars
- `name.getNameOverride` - Get appropriate nameOverride
- `name.getFullNameOverride` - Get appropriate fullnameOverride

### ConfigMap Library (`templates/configmap/_configmap.tpl`)

- `configmap.render` - Complete ConfigMap manifest
- `configmap.getName` - ConfigMap name
- `configmap.getFullName` - Fully qualified ConfigMap name
- `configmap.labels` - ConfigMap labels
- `configmap.data` - ConfigMap data section
- `configmap.validate` - Validation helper

### Deployment Library (`templates/deployment/_deployment.tpl`)

- `deployment.render` - Complete Deployment manifest
- `deployment.getFullName` - Fully qualified Deployment name
- `deployment.getReplicas` - Replica count
- `deployment.labels` - Deployment labels
- `deployment.selectorLabels` - Selector labels
- `deployment.podLabels` - Pod labels
- `deployment.containers` - Container specifications
- `deployment.env` - Environment variables
- `deployment.validate` - Validation helper

### Service Library (`templates/service/_service.tpl`)

- `service.render` - Complete Service manifest
- `service.getFullName` - Fully qualified Service name
- `service.getType` - Service type
- `service.labels` - Service labels
- `service.selectorLabels` - Selector labels
- `service.ports` - Port specifications
- `service.validate` - Validation helper

### ServiceAccount Library (`templates/service/_serviceaccount.tpl`)

- `serviceaccount.render` - Complete ServiceAccount manifest
- `serviceaccount.getName` - ServiceAccount name
- `serviceaccount.labels` - ServiceAccount labels
- `serviceaccount.validate` - Validation helper

### Secret Library (`templates/secret/_secrets.tpl`)

- `secret.render` - Complete Secret manifest
- `secret.getName` - Secret name
- `secret.getFullName` - Fully qualified Secret name
- `secret.labels` - Secret labels
- `secret.data` - Secret data section
- `secret.validate` - Validation helper

### Istio Libraries (`templates/istio/`)

- `destinationrule.render` - Complete DestinationRule manifest
- `gateway.render` - Complete Gateway manifest
- `virtualservice.render` - Complete VirtualService manifest

### Notes Library (`templates/_notes.tpl`)

- `notes.enabled` - Check if notes generation is enabled
- `notes.common` - Common metadata notes (chart, release, labels)
- `notes.resources` - Resource information notes (name, namespace, service account)
- `notes.networking` - Networking information notes (service, ingress)
- `notes.istio` - Istio information notes (DestinationRule, Gateway, VirtualService)
- `notes.mattermost` - Mattermost information notes (webhook, channel, username)
- `notes.mattermostWebhookPayload` - JSON payload for Mattermost webhook with rendered NOTES.txt
- `notes.troubleshooting` - Troubleshooting information notes (commands, tips)
- `notes.custom` - Custom notes from values
- `notes.deployment` - Full deployment notes (common + resources + networking + istio + mattermost + troubleshooting)
- `notes.pod` - Pod-specific notes (common + resources)
- `notes.service` - Service-specific notes (common + networking)
- `notes.configMap` - ConfigMap-specific notes (common + resources)
- `notes.secret` - Secret-specific notes (common + resources)
- `notes.full` - Complete notes including all sections with labels and annotations

## Best Practices

1. **Always use the `root` parameter** when calling template helpers that require it
2. **Validate your configuration** using the provided validation helpers before rendering
3. **Use template rendering** in values by wrapping values in `{{ }}` for dynamic content
4. **Leverage global overrides** for consistent naming across multiple charts
5. **Follow Kubernetes naming conventions** - the library handles truncation automatically

## Example Chart

Here's a complete example of how to use this library in a chart:

```yaml
# Chart.yaml
apiVersion: v2
name: my-app
version: 1.0.0
dependencies:
  - name: helm-templates
    repository: file://../helm-templates
    version: 0.0.4
```

```yaml
# values.yaml
deployment:
  replicas: 3
  containers:
    - name: app
      image: myapp:1.0.0
      ports:
        - containerPort: 8080

service:
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      targetPort: 8080
```

```yaml
# templates/deployment.yaml
{{- include "deployment.render" (dict "root" $ "deployment" $Values.deployment) }}
```

```yaml
# templates/service.yaml
{{- include "service.render" (dict "root" $ "service" $Values.service) }}
```

## Example Application

A complete, production-ready example application demonstrating all features of this library is included in the `example-app/` directory. This example shows:

- All template helpers in use
- Production-ready configuration
- Best practices for resource management
- Istio service mesh integration
- Comprehensive testing scripts

### Quick Start with Example

```bash
# Navigate to the example
cd example-app

# Update dependencies
helm dependency update

# Test the templates
./scripts/test.sh

# Install (dry-run first)
helm install my-app . --namespace production --dry-run --debug

# Install for real
./scripts/install.sh
```

See the [example-app README](example-app/README.md) for detailed documentation.

## Contributing

When adding new template helpers:

1. Follow the existing documentation format in the template comments
2. Include usage examples in the template header
3. Document expected input/output structures
4. Add validation helpers where appropriate
5. Ensure template rendering support with `tpl` where values are dynamic
6. Update the example application to demonstrate the new feature

