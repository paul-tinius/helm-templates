# Helm Template Helpers

This repository contains a collection of reusable Helm template helpers organized into multiple template files.

## Table of Contents

- [Core Helpers (`_helpers.tpl`)](#core-helpers-_helperstpl)
- [Regex Helpers (`_regex.tpl`)](#regex-helpers-_regextpl)
- [ConfigMap Helpers (`_configmap-application-yaml.tpl`)](#configmap-helpers-_configmap-application-yamltpl)
- [NOTES Helpers (`_notes.tpl`)](#notes-helpers-_notestpl)

---

## Core Helpers (`_helpers.tpl`)

### helper.name

Expands the name of the chart.

**Usage:**
```helm
{{- include "helper.name" . -}}
```

**Inputs:**
- `.Chart.Name`: Chart name from Helm context
- `.Values.nameOverride` (optional): Override for the chart name

**Outputs:**
- String: The chart name truncated to 63 characters with trailing hyphens removed

---

### helper.fullname

Creates a default fully qualified app name.

**Usage:**
```helm
{{- include "helper.fullname" . -}}
```

**Inputs:**
- `.Chart.Name`: Chart name from Helm context
- `.Release.Name`: Release name from Helm context
- `.Values.nameOverride` (optional): Override for the chart name
- `.Values.fullnameOverride` (optional): Override for the full release name

**Outputs:**
- String: The fully qualified app name (release-name or release-name-chartname) truncated to 63 characters

**Logic:**
- If `fullnameOverride` is set, uses that value
- If the release name already contains the chart name, uses only the release name
- Otherwise, combines release name and chart name with a hyphen

---

### helper.chart

Creates chart name and version as used by the chart label.

**Usage:**
```helm
{{- include "helper.chart" . -}}
```

**Inputs:**
- `.Chart.Name`: Chart name from Helm context
- `.Chart.Version`: Chart version from Helm context

**Outputs:**
- String: Chart name and version in format "name-version" with `+` replaced by `_`, truncated to 63 characters

---

### helper.labels

Creates common labels for Kubernetes resources.

**Usage:**
```helm
{{- include "helper.labels" . | nindent 4 -}}
```

**Inputs:**
- `.Chart.Name`: Chart name from Helm context
- `.Chart.Version`: Chart version from Helm context
- `.Chart.AppVersion` (optional): Chart app version from Helm context
- `.Release.Name`: Release name from Helm context
- `.Release.Service`: Release service (typically Helm) from Helm context
- `.Values.nameOverride` (optional): Override for the chart name

**Outputs:**
- String: Multi-line YAML labels including:
  - `helm.sh/chart`: Chart name and version
  - `app.kubernetes.io/name`: App name
  - `app.kubernetes.io/instance`: Release name
  - `app.kubernetes.io/version`: App version (if available)
  - `app.kubernetes.io/managed-by`: Helm

---

### helper.selectorLabels

Creates selector labels for Kubernetes resources.

**Usage:**
```helm
{{- include "helper.selectorLabels" . | nindent 4 -}}
```

**Inputs:**
- `.Chart.Name`: Chart name from Helm context
- `.Release.Name`: Release name from Helm context
- `.Values.nameOverride` (optional): Override for the chart name

**Outputs:**
- String: Multi-line YAML selector labels including:
  - `app.kubernetes.io/name`: App name
  - `app.kubernetes.io/instance`: Release name

---

### helper.serviceAccountName

Creates the name of the service account to use.

**Usage:**
```helm
{{- include "helper.serviceAccountName" . -}}
```

**Inputs:**
- `.Chart.Name`: Chart name from Helm context
- `.Release.Name`: Release name from Helm context
- `.Values.nameOverride` (optional): Override for the chart name
- `.Values.fullnameOverride` (optional): Override for the full release name
- `.Values.serviceAccount.create`: Boolean indicating whether to create service account
- `.Values.serviceAccount.name` (optional): Custom service account name

**Outputs:**
- String: Service account name (custom name, fullname, or "default")

**Logic:**
- If `serviceAccount.create` is true, uses custom name or fullname
- Otherwise, uses custom name or "default"

---

### helper.hostname

Creates the hostname.

**Usage:**
```helm
{{- include "helper.hostname" . -}}
```

**Inputs:**
- `.Chart.Name`: Chart name from Helm context

**Outputs:**
- String: The chart name as hostname

---

### helper.fqdn

Creates the fully qualified domain name (FQDN).

**Usage:**
```helm
{{- include "helper.fqdn" . -}}
```

**Inputs:**
- `.Chart.Name`: Chart name from Helm context
- `.Release.Namespace`: Release namespace from Helm context

**Outputs:**
- String: FQDN in format "chartname.namespace.svc.cluster.local"

---

## Regex Helpers (`_regex.tpl`)

### regex.trimPrefix

Removes a prefix pattern from a string using regex.

**Usage:**
```helm
{{- include "regex.trimPrefix" (dict "string" "prefix-value" "pattern" "^prefix-") -}}
```

**Inputs:**
- `.string`: The input string to process
- `.pattern`: The regex pattern to match at the beginning of the string

**Outputs:**
- String: The input string with the matching prefix removed

---

### regex.trimSuffix

Removes a suffix pattern from a string using regex.

**Usage:**
```helm
{{- include "regex.trimSuffix" (dict "string" "value-suffix" "pattern" "-suffix$") -}}
```

**Inputs:**
- `.string`: The input string to process
- `.pattern`: The regex pattern to match at the end of the string

**Outputs:**
- String: The input string with the matching suffix removed

---

### regex.removeAll

Removes all occurrences of a pattern from a string using regex.

**Usage:**
```helm
{{- include "regex.removeAll" (dict "string" "a-b-c-d" "pattern" "-") -}}
```

**Inputs:**
- `.string`: The input string to process
- `.pattern`: The regex pattern to remove all occurrences of

**Outputs:**
- String: The input string with all matching patterns removed

---

## ConfigMap Helpers (`_configmap-application-yaml.tpl`)

### configmap.applicationYaml

Creates a ConfigMap for Spring Boot application YAML with refresh support.

**Usage:**
```helm
{{- include "configmap.applicationYaml" . -}}
```

**Inputs:**
- `.Values.application` (optional): Custom application YAML configuration string
- `.Chart.Name`: Chart name from Helm context
- `.Chart.AppVersion`: Chart app version from Helm context
- `.Release.Name`: Release name from Helm context
- `.Release.Namespace`: Release namespace from Helm context
- `.Values.nameOverride` (optional): Override for the chart name
- `.Values.fullnameOverride` (optional): Override for the full release name

**Outputs:**
- ConfigMap Kubernetes manifest with:
  - Name: `{fullname}-application-yaml`
  - Labels: Standard chart labels
  - Data: `application.k8s.yaml` with Spring Boot configuration

**Note:** This helper references `application.environment.get` which should be defined elsewhere.

---

### configmap.volume

Creates a volume definition for application ConfigMap.

**Usage:**
```helm
{{- include "configmap.volume" . -}}
```

**Inputs:**
- `.Chart.Name`: Chart name from Helm context
- `.Release.Name`: Release name from Helm context
- `.Values.nameOverride` (optional): Override for the chart name
- `.Values.fullnameOverride` (optional): Override for the full release name

**Outputs:**
- Kubernetes Volume definition referencing the application ConfigMap:
  - Name: `application-yaml-config`
  - ConfigMap reference: `{fullname}-application-yaml`
  - Items: `application-k8s.yaml` key mapped to `application-k8s.yaml` path

---

### configmap.volumeMount

Creates a volume mount definition for application ConfigMap.

**Usage:**
```helm
{{- include "configmap.volumeMount" . -}}
```

**Inputs:**
- None (uses fixed volume name)

**Outputs:**
- Kubernetes VolumeMount definition:
  - Name: `application-config`
  - MountPath: `/config/application-k8s.yaml`
  - SubPath: `application-k8s.yaml`

---

### configmap.envVars

Creates Spring Boot environment variables for ConfigMap refresh.

**Usage:**
```helm
{{- include "configmap.envVars" . -}}
```

**Inputs:**
- `.Chart.Name`: Chart name from Helm context
- `.Release.Name`: Release name from Helm context
- `.Values.nameOverride` (optional): Override for the chart name
- `.Values.fullnameOverride` (optional): Override for the full release name

**Outputs:**
- List of environment variables:
  - `SPRING_CONFIG_IMPORT`: Points to the ConfigMap
  - `SPRING_CLOUD_CONFIG_ENABLED`: Set to `false`
  - `SPRING_CLOUD_KUBERNETES_CONFIG_ENABLED`: Set to `true`
  - `SPRING_CLOUD_KUBERNETES_CONFIG_NAME`: ConfigMap name
  - `SPRING_CLOUD_KUBERNETES_CONFIG_PATHS`: `/config`
  - `SPRING_CLOUD_KUBERNETES_RELOAD_ENABLED`: Set to `true`
  - `APP_ENVIRONMENT`: Set to the deployment environment

**Note:** This helper references `application.environment.get` which should be defined elsewhere.

---

## NOTES Helpers (`_notes.tpl`)

These helpers are designed for use in `NOTES.txt` to provide post-installation instructions to users.

### notes.serviceUrl

Generate service URL based on service type.

**Usage:**
```helm
{{- include "notes.serviceUrl" . -}}
```

**Inputs:**
- `.Values.service.type`: Service type (LoadBalancer, NodePort, ClusterIP)
- `.Values.service.protocol`: Service protocol (http, https, etc.)
- `.Values.service.port`: Service port (for ClusterIP)

**Outputs:**
- String: Service URL formatted based on service type:
  - LoadBalancer: `{protocol}://{fullname}`
  - NodePort: `{protocol}://<NODE_IP>:<NODE_PORT>`
  - ClusterIP: `{protocol}://{fullname}.{namespace}.svc.cluster.local:{port}`

**Note:** This helper references `chart.fullname` which should be defined elsewhere.

---

### notes.servicePort

Get service port.

**Usage:**
```helm
{{- include "notes.servicePort" . -}}
```

**Inputs:**
- `.Values.service.port` (optional): Service port

**Outputs:**
- Integer: Service port (default: 80)

---

### notes.serviceProtocol

Get service protocol.

**Usage:**
```helm
{{- include "notes.serviceProtocol" . -}}
```

**Inputs:**
- `.Values.service.protocol` (optional): Service protocol

**Outputs:**
- String: Service protocol (default: "http")

---

### notes.serviceEnabled

Check if service is enabled.

**Usage:**
```helm
{{- include "notes.serviceEnabled" . -}}
```

**Inputs:**
- `.Values.service.enabled` (optional): Service enabled flag

**Outputs:**
- Boolean: Whether service is enabled (default: true)

---

### notes.ingressHost

Get ingress host.

**Usage:**
```helm
{{- include "notes.ingressHost" . -}}
```

**Inputs:**
- `.Values.ingress.enabled`: Whether ingress is enabled
- `.Values.ingress.hosts`: List of ingress host configurations

**Outputs:**
- String: First ingress host from the hosts list

---

### notes.ingressEnabled

Check if ingress is enabled.

**Usage:**
```helm
{{- include "notes.ingressEnabled" . -}}
```

**Inputs:**
- `.Values.ingress.enabled` (optional): Ingress enabled flag

**Outputs:**
- Boolean: Whether ingress is enabled (default: false)

---

### notes.secretName

Get secret name.

**Usage:**
```helm
{{- include "notes.secretName" . -}}
```

**Inputs:**
- `.Values.existingSecret` (optional): Name of existing secret

**Outputs:**
- String: Secret name (existing secret or `{fullname}-secret`)

**Note:** This helper references `chart.fullname` which should be defined elsewhere.

---

### notes.configMapName

Get configmap name.

**Usage:**
```helm
{{- include "notes.configMapName" . -}}
```

**Inputs:**
- `.Values.existingConfigMap` (optional): Name of existing ConfigMap

**Outputs:**
- String: ConfigMap name (existing ConfigMap or `{fullname}-config`)

**Note:** This helper references `chart.fullname` which should be defined elsewhere.

---

### notes.adminUsername

Get admin username from secret or values.

**Usage:**
```helm
{{- include "notes.adminUsername" . -}}
```

**Inputs:**
- `.Values.adminUsername` (optional): Admin username

**Outputs:**
- String: Admin username (default: "admin")

---

### notes.getCredentials

Generate credentials retrieval command.

**Usage:**
```helm
{{- include "notes.getCredentials" . -}}
```

**Inputs:**
- `.Values.existingSecret` (optional): Name of existing secret
- `.Values.secretKey`: Key in the secret containing credentials
- `.Release.Namespace`: Release namespace

**Outputs:**
- String: kubectl command to retrieve and decode credentials from secret

---

### notes.checkPodStatus

Generate pod status check command.

**Usage:**
```helm
{{- include "notes.checkPodStatus" . -}}
```

**Inputs:**
- `.Release.Namespace`: Release namespace
- `.Release.Name`: Release name

**Outputs:**
- String: kubectl command to check pod status

**Note:** This helper references `chart.name` which should be defined elsewhere.

---

### notes.checkServiceStatus

Generate service status check command.

**Usage:**
```helm
{{- include "notes.checkServiceStatus" . -}}
```

**Inputs:**
- `.Release.Namespace`: Release namespace
- `.Release.Name`: Release name

**Outputs:**
- String: kubectl command to check service status

**Note:** This helper references `chart.name` which should be defined elsewhere.

---

### notes.getLogs

Generate logs command.

**Usage:**
```helm
{{- include "notes.getLogs" . -}}
```

**Inputs:**
- `.Release.Namespace`: Release namespace
- `.Release.Name`: Release name

**Outputs:**
- String: kubectl command to get pod logs (last 100 lines)

**Note:** This helper references `chart.name` which should be defined elsewhere.

---

### notes.portForward

Generate port-forward command.

**Usage:**
```helm
{{- include "notes.portForward" . -}}
```

**Inputs:**
- `.Release.Namespace`: Release namespace
- `.Values.localPort`: Local port for port-forwarding
- `.Values.service.port`: Service port

**Outputs:**
- String: kubectl command to port-forward to the service

**Note:** This helper references `chart.fullname` and `notes.servicePort`.

---

### notes.uninstall

Generate uninstall command.

**Usage:**
```helm
{{- include "notes.uninstall" . -}}
```

**Inputs:**
- `.Release.Name`: Release name
- `.Release.Namespace`: Release namespace

**Outputs:**
- String: Helm uninstall command

---

### notes.upgrade

Generate upgrade command.

**Usage:**
```helm
{{- include "notes.upgrade" . -}}
```

**Inputs:**
- `.Release.Name`: Release name
- `.Release.Namespace`: Release namespace

**Outputs:**
- String: Helm upgrade command

---

### notes.rollback

Generate rollback command.

**Usage:**
```helm
{{- include "notes.rollback" . -}}
```

**Inputs:**
- `.Release.Name`: Release name
- `.Release.Namespace`: Release namespace

**Outputs:**
- String: Helm rollback command

---

### notes.if

Conditional section rendering.

**Usage:**
```helm
{{- include "notes.if" (dict "condition" true "content" "content to render") -}}
```

**Inputs:**
- `.condition`: Boolean condition
- `.content`: Content to render if condition is true

**Outputs:**
- String: Content if condition is true, empty string otherwise

---

### notes.section

Render section with header.

**Usage:**
```helm
{{- include "notes.section" (dict "title" "Section Title") -}}
```

**Inputs:**
- `.title`: Section title

**Outputs:**
- String: Section title with underline (using `=` characters)

---

## Dependencies

Some helpers reference other helpers that should be defined elsewhere:

- `chart.fullname` - Referenced in `_notes.tpl`
- `chart.name` - Referenced in `_notes.tpl`
- `application.environment.get` - Referenced in `_configmap-application-yaml.tpl`

Ensure these helpers are defined in your chart or replace them with appropriate alternatives.

---

## Usage Example

To use these helpers in your Helm chart, copy the template files to your `templates/` directory and include them as needed:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "helper.fullname" . }}-config
  labels:
    {{- include "helper.labels" . | nindent 4 }}
data:
  config.yaml: |
    {{ .Values.config | nindent 4 }}
```

For NOTES.txt:

```yaml
{{- if include "notes.serviceEnabled" . -}}
{{ include "notes.section" (dict "title" "Accessing the Service") }}
The service is available at: {{ include "notes.serviceUrl" . }}
{{- end -}}
```
