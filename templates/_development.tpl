{{/*
development.enabled checks if development mode is enabled.

Usage:
  {{- include "development.enabled" . -}}

Inputs:
  .Values.development.enabled (optional): Boolean to enable development mode
  .Release.Namespace (optional): Checks if namespace is development-related

Outputs:
  Boolean: true if development mode is enabled, false otherwise
*/}}
{{- define "development.enabled" -}}
{{- if .Values.development -}}
{{- .Values.development.enabled | default false -}}
{{- else -}}
{{- or (eq .Release.Namespace "development") (eq .Release.Namespace "dev") -}}
{{- end -}}
{{- end }}

{{/*
development.labels creates development-specific labels.

Usage:
  {{- include "development.labels" . | nindent 4 -}}

Inputs:
  .Values.development.labels (optional): Custom development labels
  .Chart.Name: Chart name from Helm context
  .Chart.Version: Chart version from Helm context
  .Release.Name: Release name from Helm context

Outputs:
  String: Multi-line YAML labels including standard labels plus development-specific labels
*/}}
{{- define "development.labels" -}}
{{- include "helper.labels" . }}
{{- if .Values.development.labels -}}
{{- toYaml .Values.development.labels | nindent 0 -}}
{{- else -}}
environment: development
{{- end -}}
{{- end }}

{{/*
development.annotations creates development-specific annotations.

Usage:
  {{- include "development.annotations" . | nindent 4 -}}

Inputs:
  .Values.development.annotations (optional): Custom development annotations

Outputs:
  String: Multi-line YAML annotations for development debugging
*/}}
{{- define "development.annotations" -}}
{{- if .Values.development.annotations -}}
{{- toYaml .Values.development.annotations | nindent 0 -}}
{{- else -}}
debug: "true"
hot-reload: "true"
{{- end -}}
{{- end }}

{{/*
development.replicaCount returns the replica count for development.

Usage:
  {{- include "development.replicaCount" . -}}

Inputs:
  .Values.development.replicaCount (optional): Custom replica count for development
  .Values.replicaCount (optional): Fallback to general replica count

Outputs:
  Integer: Replica count (default 1 for development)
*/}}
{{- define "development.replicaCount" -}}
{{- if .Values.development -}}
{{- .Values.development.replicaCount | default 1 -}}
{{- else -}}
{{- .Values.replicaCount | default 1 -}}
{{- end -}}
{{- end }}

{{/*
development.resources returns resource limits and requests for development.

Usage:
  {{- include "development.resources" . | nindent 4 -}}

Inputs:
  .Values.development.resources (optional): Custom resource configuration for development
  .Values.resources (optional): Fallback to general resource configuration

Outputs:
  String: YAML resource configuration with development-friendly defaults
*/}}
{{- define "development.resources" -}}
{{- if .Values.development.resources -}}
{{- toYaml .Values.development.resources | nindent 0 -}}
{{- else if .Values.resources -}}
{{- toYaml .Values.resources | nindent 0 -}}
{{- else -}}
limits:
  cpu: 1000m
  memory: 512Mi
requests:
  cpu: 250m
  memory: 128Mi
{{- end -}}
{{- end }}

{{/*
development.envVars creates development-specific environment variables.

Usage:
  {{- include "development.envVars" . | nindent 8 -}}

Inputs:
  .Values.development.env (optional): Custom development environment variables
  .Values.development.debug (optional): Enable debug mode (default: true)

Outputs:
  String: List of environment variables for development
*/}}
{{- define "development.envVars" -}}
{{- if .Values.development.env -}}
{{- range $key, $value := .Values.development.env -}}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- else -}}
- name: SPRING_PROFILES_ACTIVE
  value: {{ .Values.development.profile | default "dev" | quote }}
- name: LOGGING_LEVEL_ROOT
  value: {{ .Values.development.logLevel | default "DEBUG" | quote }}
{{- if .Values.development.debug | default true -}}
- name: DEBUG
  value: "true"
- name: JAVA_OPTS
  value: "-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"
{{- end -}}
{{- end -}}
{{- end }}

{{/*
development.serviceType returns the service type for development.

Usage:
  {{- include "development.serviceType" . -}}

Inputs:
  .Values.development.service.type (optional): Custom service type for development
  .Values.service.type (optional): Fallback to general service type

Outputs:
  String: Service type (default NodePort for development)
*/}}
{{- define "development.serviceType" -}}
{{- if .Values.development.service -}}
{{- .Values.development.service.type | default "NodePort" -}}
{{- else -}}
{{- .Values.service.type | default "NodePort" -}}
{{- end -}}
{{- end }}

{{/*
development.nodePort returns the NodePort for development.

Usage:
  {{- include "development.nodePort" . -}}

Inputs:
  .Values.development.service.nodePort (optional): Custom NodePort for development

Outputs:
  Integer: NodePort value (default 30000)
*/}}
{{- define "development.nodePort" -}}
{{- if .Values.development.service -}}
{{- .Values.development.service.nodePort | default 30000 -}}
{{- else -}}
{{- 30000 -}}
{{- end -}}
{{- end }}

{{/*
development.ingress creates development-specific ingress configuration.

Usage:
  {{- include "development.ingress" . -}}

Inputs:
  .Values.development.ingress.enabled (optional): Boolean to enable ingress (default: true)
  .Values.development.ingress.host (optional): Custom ingress host
  .Values.development.ingress.path (optional): Custom ingress path
  .Chart.Name: Chart name from Helm context
  .Release.Name: Release name from Helm context
  .Values.nameOverride (optional): Override for the chart name
  .Values.fullnameOverride (optional): Override for the full release name

Outputs:
  Ingress Kubernetes manifest with development-friendly configuration
*/}}
{{- define "development.ingress" -}}
{{- if and .Values.development .Values.development.ingress .Values.development.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "helper.fullname" . }}-development
  labels:
    {{- include "development.labels" . | nindent 4 }}
  annotations:
    {{- include "development.annotations" . | nindent 4 }}
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: {{ .Values.development.ingress.host | default (printf "%s.local" (include "helper.name" .)) }}
    http:
      paths:
      - path: {{ .Values.development.ingress.path | default "/" }}
        pathType: Prefix
        backend:
          service:
            name: {{ include "helper.fullname" . }}
            port:
              number: {{ include "helper.serverPort" . }}
{{- end -}}
{{- end }}

{{/*
development.hpa creates HorizontalPodAutoscaler for development.

Usage:
  {{- include "development.hpa" . -}}

Inputs:
  .Values.development.hpa.enabled (optional): Boolean to enable HPA (default: false)
  .Values.development.hpa.minReplicas (optional): Minimum replicas
  .Values.development.hpa.maxReplicas (optional): Maximum replicas
  .Values.development.hpa.targetCPUUtilizationPercentage (optional): CPU target
  .Chart.Name: Chart name from Helm context
  .Release.Name: Release name from Helm context
  .Values.nameOverride (optional): Override for the chart name
  .Values.fullnameOverride (optional): Override for the full release name

Outputs:
  HPA Kubernetes manifest if enabled
*/}}
{{- define "development.hpa" -}}
{{- if and .Values.development .Values.development.hpa .Values.development.hpa.enabled -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "helper.fullname" . }}-development
  labels:
    {{- include "development.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "helper.fullname" . }}
  minReplicas: {{ .Values.development.hpa.minReplicas | default 1 }}
  maxReplicas: {{ .Values.development.hpa.maxReplicas | default 3 }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.development.hpa.targetCPUUtilizationPercentage | default 70 }}
{{- end -}}
{{- end }}

{{/*
development.podDisruptionBudget creates PodDisruptionBudget for development.

Usage:
  {{- include "development.podDisruptionBudget" . -}}

Inputs:
  .Values.development.pdb.enabled (optional): Boolean to enable PDB (default: false)
  .Values.development.pdb.minAvailable (optional): Minimum available pods
  .Values.development.pdb.maxUnavailable (optional): Maximum unavailable pods
  .Chart.Name: Chart name from Helm context
  .Release.Name: Release name from Helm context
  .Values.nameOverride (optional): Override for the chart name
  .Values.fullnameOverride (optional): Override for the full release name

Outputs:
  PodDisruptionBudget Kubernetes manifest if enabled
*/}}
{{- define "development.podDisruptionBudget" -}}
{{- if and .Values.development .Values.development.pdb .Values.development.pdb.enabled -}}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "helper.fullname" . }}-development
  labels:
    {{- include "development.labels" . | nindent 4 }}
spec:
  {{- if .Values.development.pdb.minAvailable -}}
  minAvailable: {{ .Values.development.pdb.minAvailable -}}
  {{- end -}}
  {{- if .Values.development.pdb.maxUnavailable -}}
  maxUnavailable: {{ .Values.development.pdb.maxUnavailable -}}
  {{- end -}}
  selector:
    matchLabels:
      {{- include "helper.selectorLabels" . | nindent 6 }}
{{- end -}}
{{- end }}

{{/*
development.render renders a specific development template.

Usage:
  {{- include "development.render" (dict "name" "enabled" "context" $) -}}
  {{- include "development.render" (dict "name" "labels" "context" $) -}}
  {{- include "development.render" (dict "name" "annotations" "context" $) -}}
  {{- include "development.render" (dict "name" "replicaCount" "context" $) -}}
  {{- include "development.render" (dict "name" "resources" "context" $) -}}
  {{- include "development.render" (dict "name" "envVars" "context" $) -}}
  {{- include "development.render" (dict "name" "serviceType" "context" $) -}}
  {{- include "development.render" (dict "name" "nodePort" "context" $) -}}
  {{- include "development.render" (dict "name" "ingress" "context" $) -}}
  {{- include "development.render" (dict "name" "hpa" "context" $) -}}
  {{- include "development.render" (dict "name" "podDisruptionBudget" "context" $) -}}

Inputs:
  .name: The template name to render (enabled, labels, annotations, replicaCount, resources, envVars, serviceType, nodePort, ingress, hpa, podDisruptionBudget)
  .context: The context to pass to the template

Outputs:
  String: The rendered template output
*/}}
{{- define "development.render" -}}
{{- if eq .name "enabled" -}}
{{- include "development.enabled" .context -}}
{{- else if eq .name "labels" -}}
{{- include "development.labels" .context -}}
{{- else if eq .name "annotations" -}}
{{- include "development.annotations" .context -}}
{{- else if eq .name "replicaCount" -}}
{{- include "development.replicaCount" .context -}}
{{- else if eq .name "resources" -}}
{{- include "development.resources" .context -}}
{{- else if eq .name "envVars" -}}
{{- include "development.envVars" .context -}}
{{- else if eq .name "serviceType" -}}
{{- include "development.serviceType" .context -}}
{{- else if eq .name "nodePort" -}}
{{- include "development.nodePort" .context -}}
{{- else if eq .name "ingress" -}}
{{- include "development.ingress" .context -}}
{{- else if eq .name "hpa" -}}
{{- include "development.hpa" .context -}}
{{- else if eq .name "podDisruptionBudget" -}}
{{- include "development.podDisruptionBudget" .context -}}
{{- end -}}
{{- end }}
