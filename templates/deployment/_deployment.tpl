{{/*
Deployment Library Chart Helpers

This library provides reusable templates for creating Kubernetes Deployment objects.
It supports common deployment patterns including replicas, containers, volumes, and probes.

Usage:
  include "deployment.render" (dict "root" $ "deployment" $Values.deployment)

Expected structure:
  deployment:
    replicas: 3                              # Optional: defaults to 1
    strategy:                                # Optional: deployment strategy
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 1
        maxUnavailable: 0
    minReadySeconds: 0                       # Optional: defaults to 0
    revisionHistoryLimit: 10                 # Optional: defaults to 10
    containers:                              # Required: container definitions
      - name: app
        image: nginx:latest
        ports:
          - containerPort: 80
        env:
          - name: ENV_VAR
            value: "value"
        resources:                           # Optional: resource limits/requests
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 250m
            memory: 256Mi
        livenessProbe:                       # Optional: liveness probe
          httpGet:
            path: /health
            port: 80
        readinessProbe:                      # Optional: readiness probe
          httpGet:
            path: /ready
            port: 80
    volumes:                                 # Optional: volume definitions
      - name: config
        configMap:
          name: my-config
    volumeMounts:                            # Optional: volume mount definitions
      - name: config
        mountPath: /etc/config
    nodeSelector: {}                         # Optional: node selector
    tolerations: []                          # Optional: tolerations
    affinity: {}                             # Optional: affinity rules
    labels: {}                               # Optional: additional labels
    annotations: {}                          # Optional: additional annotations

Inputs:
  - .Chart.Name: The chart name
  - .Release.Name: The release name
  - .Release.Namespace: The release namespace
  - .Release.Service: The release service (typically Helm)
  - deployment.name: Override for the deployment name (optional)
  - deployment.replicas: Number of replicas (optional, defaults to 1)
  - deployment.strategy: Deployment strategy configuration (optional)
  - deployment.containers: List of container definitions (required)
  - deployment.volumes: List of volume definitions (optional)
  - deployment.volumeMounts: List of volume mount definitions (optional)
  - deployment.nodeSelector: Node selector configuration (optional)
  - deployment.tolerations: List of tolerations (optional)
  - deployment.affinity: Affinity rules (optional)
  - deployment.labels: Additional labels (optional)
  - deployment.annotations: Additional annotations (optional)

Outputs:
  - deployment.render: Complete Deployment manifest
  - deployment.getFullName: The fully qualified Deployment name
  - deployment.getReplicas: The replica count
  - deployment.labels: YAML formatted labels
  - deployment.selectorLabels: YAML formatted selector labels
  - deployment.podLabels: YAML formatted pod labels
  - deployment.containers: YAML formatted container specifications
  - deployment.env: YAML formatted environment variables
  - deployment.validate: Validation helper (fails on invalid config)
*/}}

{{/*
Render a Deployment object

Parameters:
  - root: The root context (usually $)
  - deployment: The deployment values structure

Returns:
  Complete Deployment manifest
*/}}
{{- define "deployment.render" -}}
{{- $root := .root -}}
{{- $deployment := .deployment -}}
{{- $fullName := include "deployment.getFullName" (dict "root" $root "deployment" $deployment) -}}

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "deployment.labels" (dict "root" $root "deployment" $deployment) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
    {{- with $deployment.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  replicas: {{ include "deployment.getReplicas" (dict "root" $root "deployment" $deployment) }}
  {{- with $deployment.strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  minReadySeconds: {{ default 0 $deployment.minReadySeconds }}
  revisionHistoryLimit: {{ default 10 $deployment.revisionHistoryLimit }}
  selector:
    matchLabels:
      {{- include "deployment.selectorLabels" (dict "root" $root "deployment" $deployment) | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "deployment.podLabels" (dict "root" $root "deployment" $deployment) | nindent 8 }}
      annotations:
        {{- include "podAnnotations" $root | nindent 8 }}
        {{- with $deployment.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- with $deployment.serviceAccountName }}
      serviceAccountName: {{ . | quote }}
      {{- end }}
      {{- with $deployment.volumes }}
      volumes:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $deployment.initContainers }}
      initContainers:
        {{- include "deployment.containers" (dict "root" $root "containers" .) | nindent 8 }}
      {{- end }}
      containers:
        {{- include "deployment.containers" (dict "root" $root "containers" $deployment.containers) | nindent 8 }}
      {{- with $deployment.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $deployment.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $deployment.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end -}}

{{/*
Get the Deployment full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - deployment: The deployment values structure

Returns:
  The fully qualified Deployment name
*/}}
{{- define "deployment.getFullName" -}}
{{- $root := .root -}}
{{- $deployment := .deployment -}}
{{- if $deployment.name -}}
  {{- $name := $deployment.name -}}
  {{- if contains $name $root.Release.Name -}}
    {{- $root.Release.Name | include "name.truncateName" -}}
  {{- else -}}
    {{- printf "%s-%s" $root.Release.Name $name | include "name.truncateName" -}}
  {{- end -}}
{{- else -}}
  {{- printf "%s-%s" $root.Release.Name $root.Chart.Name | include "name.truncateName" -}}
{{- end -}}
{{- end -}}

{{/*
Get the replica count

Parameters:
  - root: The root context (usually $)
  - deployment: The deployment values structure

Returns:
  The replica count (defaults to 1)
*/}}
{{- define "deployment.getReplicas" -}}
{{- $deployment := .deployment -}}
{{- if kindIs "int" $deployment.replicas -}}
  {{- $deployment.replicas -}}
{{- else -}}
  {{- default 1 $deployment.replicas -}}
{{- end -}}
{{- end -}}

{{/*
Generate standard labels for Deployment

Parameters:
  - root: The root context (usually $)
  - deployment: The deployment values structure

Returns:
  YAML formatted labels
*/}}
{{- define "deployment.labels" -}}
{{- $root := .root -}}
{{- $deployment := .deployment -}}
{{- $labels := dict -}}
{{- if $root.Values.global.labels -}}
  {{- range $k, $v := $root.Values.global.labels -}}
    {{- $labels = set $labels $k (tpl $v $root) -}}
  {{- end -}}
{{- end -}}
{{- $labels = set $labels "helm.sh/chart" (include "names.chart" $root) -}}
{{- $labels = set $labels "app.kubernetes.io/name" $root.Chart.Name -}}
{{- $labels = set $labels "app.kubernetes.io/instance" $root.Release.Name -}}
{{- if $root.Chart.AppVersion -}}
  {{- $labels = set $labels "app.kubernetes.io/version" $root.Chart.AppVersion -}}
{{- end -}}
{{- $labels = set $labels "app.kubernetes.io/managed-by" $root.Release.Service -}}
{{- with $deployment.labels -}}
  {{- range $k, $v := . -}}
    {{- $labels = set $labels $k $v -}}
  {{- end -}}
{{- end -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Generate selector labels for Deployment

Parameters:
  - root: The root context (usually $)
  - deployment: The deployment values structure

Returns:
  YAML formatted selector labels
*/}}
{{- define "deployment.selectorLabels" -}}
{{- $root := .root -}}
{{- $deployment := .deployment -}}
{{- $labels := dict -}}
{{- $labels = set $labels "app.kubernetes.io/name" $root.Chart.Name -}}
{{- $labels = set $labels "app.kubernetes.io/instance" $root.Release.Name -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Generate pod labels

Parameters:
  - root: The root context (usually $)
  - deployment: The deployment values structure

Returns:
  YAML formatted pod labels
*/}}
{{- define "deployment.podLabels" -}}
{{- $root := .root -}}
{{- $deployment := .deployment -}}
{{- $labels := dict -}}
{{- $labels = set $labels "app.kubernetes.io/name" $root.Chart.Name -}}
{{- $labels = set $labels "app.kubernetes.io/instance" $root.Release.Name -}}
{{- with $deployment.podLabels -}}
  {{- range $k, $v := . -}}
    {{- $labels = set $labels $k $v -}}
  {{- end -}}
{{- end -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Render container definitions

Parameters:
  - root: The root context (usually $)
  - containers: The container definitions list

Returns:
  YAML formatted container specifications
*/}}
{{- define "deployment.containers" -}}
{{- $root := .root -}}
{{- range $container := .containers -}}
- name: {{ $container.name | quote }}
  image: {{ tpl $container.image $root | quote }}
  {{- with $container.imagePullPolicy }}
  imagePullPolicy: {{ . }}
  {{- end }}
  {{- with $container.command }}
  command:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $container.args }}
  args:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $container.ports }}
  ports:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $container.env }}
  env:
    {{- include "deployment.env" (dict "root" $root "env" .) | nindent 4 }}
  {{- end }}
  {{- with $container.envFrom }}
  envFrom:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $container.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $container.volumeMounts }}
  volumeMounts:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $container.livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $container.readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $container.startupProbe }}
  startupProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $container.lifecycle }}
  lifecycle:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $container.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
{{- end -}}

{{/*
Render environment variables with template support

Parameters:
  - root: The root context (usually $)
  - env: The environment variables list

Returns:
  YAML formatted environment variables
*/}}
{{- define "deployment.env" -}}
{{- $root := .root -}}
{{- range $env := .env -}}
- name: {{ $env.name | quote }}
  {{- if $env.value }}
  value: {{ tpl $env.value $root | quote }}
  {{- end }}
  {{- if $env.valueFrom }}
  valueFrom:
    {{- toYaml $env.valueFrom | nindent 4 }}
  {{- end }}
{{ end }}
{{- end -}}

{{/*
Validate Deployment configuration

Parameters:
  - root: The root context (usually $)
  - deployment: The deployment values structure

Returns:
  Error message if validation fails, empty string otherwise
*/}}
{{- define "deployment.validate" -}}
{{- $deployment := .deployment -}}
{{- if not $deployment.containers -}}
  {{- fail "Deployment must have 'containers' defined" -}}
{{- end -}}
{{- if not (kindIs "slice" $deployment.containers) -}}
  {{- fail "Deployment 'containers' must be a list" -}}
{{- end -}}
{{- range $container := $deployment.containers -}}
  {{- if not $container.name -}}
    {{- fail "Each container must have a 'name' defined" -}}
  {{- end -}}
  {{- if not $container.image -}}
    {{- fail "Each container must have an 'image' defined" -}}
  {{- end -}}
{{- end -}}
{{- end -}}
