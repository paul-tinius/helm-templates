{{/*
deployment.enabled checks if deployment mode is enabled.

Usage:
  {{- include "deployment.enabled" . -}}

Inputs:
  .Values.deployment.enabled (optional): Boolean to enable deployment mode
  .Release.Namespace (optional): Checks if namespace is deployment-related

Outputs:
  Boolean: true if deployment mode is enabled, false otherwise
*/}}
{{- define "deployment.enabled" -}}
{{- if .Values.deployment -}}
{{- .Values.deployment.enabled | default false -}}
{{- else -}}
{{- or (eq .Release.Namespace "deployment") (eq .Release.Namespace "deploy") -}}
{{- end -}}
{{- end }}

{{/*
deployment.labels creates deployment-specific labels.

Usage:
  {{- include "deployment.labels" . | nindent 4 -}}

Inputs:
  .Values.deployment.labels (optional): Custom deployment labels
  .Chart.Name: Chart name from Helm context
  .Chart.Version: Chart version from Helm context
  .Release.Name: Release name from Helm context

Outputs:
  String: Multi-line YAML labels including standard labels plus deployment-specific labels
*/}}
{{- define "deployment.labels" -}}
{{- include "helper.labels" . }}
{{- if .Values.deployment.labels -}}
{{- toYaml .Values.deployment.labels | nindent 0 -}}
{{- else -}}
environment: deployment
{{- end -}}
{{- end }}

{{/*
deployment.annotations creates deployment-specific annotations.

Usage:
  {{- include "deployment.annotations" . | nindent 4 -}}

Inputs:
  .Values.deployment.annotations (optional): Custom deployment annotations

Outputs:
  String: Multi-line YAML annotations for deployment debugging
*/}}
{{- define "deployment.annotations" -}}
{{- if .Values.deployment.annotations -}}
{{- toYaml .Values.deployment.annotations | nindent 0 -}}
{{- else -}}
debug: "true"
hot-reload: "true"
{{- end -}}
{{- end }}

{{/*
deployment.replicaCount returns the replica count for deployment.

Usage:
  {{- include "deployment.replicaCount" . -}}

Inputs:
  .Values.deployment.replicaCount (optional): Custom replica count for deployment
  .Values.replicaCount (optional): Fallback to general replica count

Outputs:
  Integer: Replica count (default 1 for deployment)
*/}}
{{- define "deployment.replicaCount" -}}
{{- if .Values.deployment -}}
{{- .Values.deployment.replicaCount | default 1 -}}
{{- else -}}
{{- .Values.replicaCount | default 1 -}}
{{- end -}}
{{- end }}

{{/*
deployment.resources returns resource limits and requests for deployment.

Usage:
  {{- include "deployment.resources" . | nindent 4 -}}

Inputs:
  .Values.deployment.resources (optional): Custom resource configuration for deployment
  .Values.resources (optional): Fallback to general resource configuration

Outputs:
  String: YAML resource configuration with deployment-friendly defaults
*/}}
{{- define "deployment.resources" -}}
{{- if .Values.deployment.resources -}}
{{- toYaml .Values.deployment.resources | nindent 0 -}}
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
deployment.envVars creates deployment-specific environment variables.

Usage:
  {{- include "deployment.envVars" . | nindent 8 -}}

Inputs:
  .Values.deployment.env (optional): Custom deployment environment variables
  .Values.deployment.debug (optional): Enable debug mode (default: true)

Outputs:
  String: List of environment variables for deployment
*/}}
{{- define "deployment.envVars" -}}
{{- if .Values.deployment.env -}}
{{- range $key, $value := .Values.deployment.env -}}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- else -}}
- name: SPRING_PROFILES_ACTIVE
  value: {{ .Values.deployment.profile | default "dev" | quote }}
- name: LOGGING_LEVEL_ROOT
  value: {{ .Values.deployment.logLevel | default "DEBUG" | quote }}
{{- if .Values.deployment.debug | default true -}}
- name: DEBUG
  value: "true"
- name: JAVA_OPTS
  value: "-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"
{{- end -}}
{{- end -}}
{{- end }}

{{/*
deployment.serviceType returns the service type for deployment.

Usage:
  {{- include "deployment.serviceType" . -}}

Inputs:
  .Values.deployment.service.type (optional): Custom service type for deployment
  .Values.service.type (optional): Fallback to general service type

Outputs:
  String: Service type (default NodePort for deployment)
*/}}
{{- define "deployment.serviceType" -}}
{{- if .Values.deployment.service -}}
{{- .Values.deployment.service.type | default "NodePort" -}}
{{- else -}}
{{- .Values.service.type | default "NodePort" -}}
{{- end -}}
{{- end }}

{{/*
deployment.nodePort returns the NodePort for deployment.

Usage:
  {{- include "deployment.nodePort" . -}}

Inputs:
  .Values.deployment.service.nodePort (optional): Custom NodePort for deployment

Outputs:
  Integer: NodePort value (default 30000)
*/}}
{{- define "deployment.nodePort" -}}
{{- if .Values.deployment.service -}}
{{- .Values.deployment.service.nodePort | default 30000 -}}
{{- else -}}
{{- 30000 -}}
{{- end -}}
{{- end }}

{{/*
deployment.ingress creates deployment-specific ingress configuration.

Usage:
  {{- include "deployment.ingress" . -}}

Inputs:
  .Values.deployment.ingress.enabled (optional): Boolean to enable ingress (default: true)
  .Values.deployment.ingress.host (optional): Custom ingress host
  .Values.deployment.ingress.path (optional): Custom ingress path
  .Chart.Name: Chart name from Helm context
  .Release.Name: Release name from Helm context
  .Values.nameOverride (optional): Override for the chart name
  .Values.fullnameOverride (optional): Override for the full release name

Outputs:
  Ingress Kubernetes manifest with deployment-friendly configuration
*/}}
{{- define "deployment.ingress" -}}
{{- if and .Values.deployment .Values.deployment.ingress .Values.deployment.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "helper.fullname" . }}-deployment
  labels:
    {{- include "deployment.labels" . | nindent 4 }}
  annotations:
    {{- include "deployment.annotations" . | nindent 4 }}
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: {{ .Values.deployment.ingress.host | default (printf "%s.local" (include "helper.name" .)) }}
    http:
      paths:
      - path: {{ .Values.deployment.ingress.path | default "/" }}
        pathType: Prefix
        backend:
          service:
            name: {{ include "helper.fullname" . }}
            port:
              number: {{ include "helper.serverPort" . }}
{{- end -}}
{{- end }}

{{/*
deployment.hpa creates HorizontalPodAutoscaler for deployment.

Usage:
  {{- include "deployment.hpa" . -}}

Inputs:
  .Values.deployment.hpa.enabled (optional): Boolean to enable HPA (default: false)
  .Values.deployment.hpa.minReplicas (optional): Minimum replicas
  .Values.deployment.hpa.maxReplicas (optional): Maximum replicas
  .Values.deployment.hpa.targetCPUUtilizationPercentage (optional): CPU target
  .Chart.Name: Chart name from Helm context
  .Release.Name: Release name from Helm context
  .Values.nameOverride (optional): Override for the chart name
  .Values.fullnameOverride (optional): Override for the full release name

Outputs:
  HPA Kubernetes manifest if enabled
*/}}
{{- define "deployment.hpa" -}}
{{- if and .Values.deployment .Values.deployment.hpa .Values.deployment.hpa.enabled -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "helper.fullname" . }}-deployment
  labels:
    {{- include "deployment.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "helper.fullname" . }}
  minReplicas: {{ .Values.deployment.hpa.minReplicas | default 1 }}
  maxReplicas: {{ .Values.deployment.hpa.maxReplicas | default 3 }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.deployment.hpa.targetCPUUtilizationPercentage | default 70 }}
{{- end -}}
{{- end }}

{{/*
deployment.podDisruptionBudget creates PodDisruptionBudget for deployment.

Usage:
  {{- include "deployment.podDisruptionBudget" . -}}

Inputs:
  .Values.deployment.pdb.enabled (optional): Boolean to enable PDB (default: false)
  .Values.deployment.pdb.minAvailable (optional): Minimum available pods
  .Values.deployment.pdb.maxUnavailable (optional): Maximum unavailable pods
  .Chart.Name: Chart name from Helm context
  .Release.Name: Release name from Helm context
  .Values.nameOverride (optional): Override for the chart name
  .Values.fullnameOverride (optional): Override for the full release name

Outputs:
  PodDisruptionBudget Kubernetes manifest if enabled
*/}}
{{- define "deployment.podDisruptionBudget" -}}
{{- if and .Values.deployment .Values.deployment.pdb .Values.deployment.pdb.enabled -}}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "helper.fullname" . }}-deployment
  labels:
    {{- include "deployment.labels" . | nindent 4 }}
spec:
  {{- if .Values.deployment.pdb.minAvailable -}}
  minAvailable: {{ .Values.deployment.pdb.minAvailable -}}
  {{- end -}}
  {{- if .Values.deployment.pdb.maxUnavailable -}}
  maxUnavailable: {{ .Values.deployment.pdb.maxUnavailable -}}
  {{- end -}}
  selector:
    matchLabels:
      {{- include "helper.selectorLabels" . | nindent 6 }}
{{- end -}}
{{- end }}

{{/*
deployment.render renders a specific deployment template.

Usage:
  {{- include "deployment.render" (dict "name" "enabled" "context" $) -}}
  {{- include "deployment.render" (dict "name" "labels" "context" $) -}}
  {{- include "deployment.render" (dict "name" "annotations" "context" $) -}}
  {{- include "deployment.render" (dict "name" "replicaCount" "context" $) -}}
  {{- include "deployment.render" (dict "name" "resources" "context" $) -}}
  {{- include "deployment.render" (dict "name" "envVars" "context" $) -}}
  {{- include "deployment.render" (dict "name" "serviceType" "context" $) -}}
  {{- include "deployment.render" (dict "name" "nodePort" "context" $) -}}
  {{- include "deployment.render" (dict "name" "ingress" "context" $) -}}
  {{- include "deployment.render" (dict "name" "hpa" "context" $) -}}
  {{- include "deployment.render" (dict "name" "podDisruptionBudget" "context" $) -}}

Inputs:
  .name: The template name to render (enabled, labels, annotations, replicaCount, resources, envVars, serviceType, nodePort, ingress, hpa, podDisruptionBudget)
  .context: The context to pass to the template

Outputs:
  String: The rendered template output
*/}}
{{- define "deployment.render" -}}
{{- if eq .name "enabled" -}}
{{- include "deployment.enabled" .context -}}
{{- else if eq .name "labels" -}}
{{- include "deployment.labels" .context -}}
{{- else if eq .name "annotations" -}}
{{- include "deployment.annotations" .context -}}
{{- else if eq .name "replicaCount" -}}
{{- include "deployment.replicaCount" .context -}}
{{- else if eq .name "resources" -}}
{{- include "deployment.resources" .context -}}
{{- else if eq .name "envVars" -}}
{{- include "deployment.envVars" .context -}}
{{- else if eq .name "serviceType" -}}
{{- include "deployment.serviceType" .context -}}
{{- else if eq .name "nodePort" -}}
{{- include "deployment.nodePort" .context -}}
{{- else if eq .name "ingress" -}}
{{- include "deployment.ingress" .context -}}
{{- else if eq .name "hpa" -}}
{{- include "deployment.hpa" .context -}}
{{- else if eq .name "podDisruptionBudget" -}}
{{- include "deployment.podDisruptionBudget" .context -}}
{{- end -}}
{{- end }}
