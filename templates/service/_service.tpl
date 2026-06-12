{{/*
Service Library Chart Helpers

This library provides reusable templates for creating Kubernetes Service objects.
It supports all service types including ClusterIP, NodePort, LoadBalancer, and ExternalName,
with flexible port configuration and selector management.

Usage:
  include "service.render" (dict "root" $ "service" $Values.service)

Expected structure:
  service:
    name: "my-service"                      # Optional: defaults to chart name
    type: ClusterIP                         # Optional: defaults to ClusterIP
    ports:                                  # Required: service ports
      - name: http
        port: 80
        targetPort: 8080
        protocol: TCP
        nodePort: 30080                     # Optional: for NodePort type
    selector: {}                            # Optional: pod selector labels
    sessionAffinity: None                   # Optional: None or ClientIP
    sessionAffinityConfig:                  # Optional: session affinity config
      clientIP:
        timeoutSeconds: 10800
    externalIPs: []                         # Optional: external IPs
    loadBalancerIP: ""                      # Optional: static LoadBalancer IP
    loadBalancerSourceRanges: []            # Optional: source ranges for LB
    externalTrafficPolicy: Cluster          # Optional: Cluster or Local
    healthCheckNodePort: 0                  # Optional: health check port for LB
    publishNotReadyAddresses: false         # Optional: publish not-ready addresses
    ipFamilies: []                          # Optional: IP families (IPv4, IPv6)
    ipFamilyPolicy: SingleStack             # Optional: IP family policy
    labels: {}                              # Optional: additional labels
    annotations: {}                         # Optional: additional annotations

Inputs:
  - .Chart.Name: The chart name
  - .Release.Name: The release name
  - .Release.Namespace: The release namespace
  - service.name: Override for the service name (optional)
  - service.type: Service type (optional, defaults to ClusterIP)
  - service.ports: List of port definitions (required)
  - service.selector: Pod selector labels (optional, defaults to selector labels)
  - service.sessionAffinity: Session affinity setting (optional)
  - service.sessionAffinityConfig: Session affinity config (optional)
  - service.externalIPs: List of external IPs (optional)
  - service.loadBalancerIP: Static LoadBalancer IP (optional)
  - service.loadBalancerSourceRanges: Source ranges for LoadBalancer (optional)
  - service.externalTrafficPolicy: External traffic policy (optional)
  - service.healthCheckNodePort: Health check node port (optional)
  - service.publishNotReadyAddresses: Publish not-ready addresses (optional)
  - service.ipFamilies: IP families (optional)
  - service.ipFamilyPolicy: IP family policy (optional)
  - service.labels: Additional labels (optional)
  - service.annotations: Additional annotations (optional)

Outputs:
  - service.render: Complete Service manifest
  - service.getFullName: The fully qualified Service name
  - service.getType: The service type
  - service.labels: YAML formatted labels
  - service.selectorLabels: YAML formatted selector labels
  - service.ports: YAML formatted port specifications
  - service.validate: Validation helper (fails on invalid config)
*/}}

{{/*
Render a Service object

Parameters:
  - root: The root context (usually $)
  - service: The service values structure

Returns:
  Complete Service manifest
*/}}
{{- define "service.render" -}}
{{- $root := .root -}}
{{- $service := .service -}}
{{- $fullName := include "service.getFullName" (dict "root" $root "service" $service) -}}

apiVersion: v1
kind: Service
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "service.labels" (dict "root" $root "service" $service) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
    {{- with $service.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  type: {{ include "service.getType" (dict "root" $root "service" $service) }}
  {{- with $service.sessionAffinity }}
  sessionAffinity: {{ . }}
  {{- end }}
  {{- with $service.sessionAffinityConfig }}
  sessionAffinityConfig:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $service.externalIPs }}
  externalIPs:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $service.loadBalancerIP }}
  loadBalancerIP: {{ . | quote }}
  {{- end }}
  {{- with $service.loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $service.externalTrafficPolicy }}
  externalTrafficPolicy: {{ . }}
  {{- end }}
  {{- if and (eq (include "service.getType" (dict "root" $root "service" $service)) "LoadBalancer") $service.healthCheckNodePort }}
  healthCheckNodePort: {{ $service.healthCheckNodePort }}
  {{- end }}
  {{- if $service.publishNotReadyAddresses }}
  publishNotReadyAddresses: {{ $service.publishNotReadyAddresses }}
  {{- end }}
  {{- with $service.ipFamilies }}
  ipFamilies:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $service.ipFamilyPolicy }}
  ipFamilyPolicy: {{ . }}
  {{- end }}
  selector:
    {{- include "service.selectorLabels" (dict "root" $root "service" $service) | nindent 4 }}
  ports:
    {{- include "service.ports" (dict "root" $root "ports" $service.ports) | nindent 4 }}
{{- end -}}

{{/*
Get the Service full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - service: The service values structure

Returns:
  The fully qualified Service name
*/}}
{{- define "service.getFullName" -}}
{{- $root := .root -}}
{{- $service := .service -}}
{{- if $service.name -}}
  {{- $name := $service.name -}}
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
Get the Service type

Parameters:
  - root: The root context (usually $)
  - service: The service values structure

Returns:
  The service type (defaults to ClusterIP)
*/}}
{{- define "service.getType" -}}
{{- $service := .service -}}
{{- $type := default "ClusterIP" $service.type -}}
{{- if or (eq $type "ClusterIP") (eq $type "NodePort") (eq $type "LoadBalancer") (eq $type "ExternalName") -}}
  {{- $type -}}
{{- else -}}
  {{- fail "Service type must be one of: ClusterIP, NodePort, LoadBalancer, ExternalName" -}}
{{- end -}}
{{- end -}}

{{/*
Generate standard labels for Service

Parameters:
  - root: The root context (usually $)
  - service: The service values structure

Returns:
  YAML formatted labels
*/}}
{{- define "service.labels" -}}
{{- $root := .root -}}
{{- $service := .service -}}
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
{{- with $service.labels -}}
  {{- range $k, $v := . -}}
    {{- $labels = set $labels $k $v -}}
  {{- end -}}
{{- end -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Generate selector labels for Service

Parameters:
  - root: The root context (usually $)
  - service: The service values structure

Returns:
  YAML formatted selector labels
*/}}
{{- define "service.selectorLabels" -}}
{{- $root := .root -}}
{{- $service := .service -}}
{{- if $service.selector -}}
  {{- toYaml $service.selector | nindent 0 }}
{{- else -}}
  {{- $labels := dict -}}
  {{- $labels = set $labels "app.kubernetes.io/name" $root.Chart.Name -}}
  {{- $labels = set $labels "app.kubernetes.io/instance" $root.Release.Name -}}
  {{- toYaml $labels | nindent 0 -}}
{{- end -}}
{{- end -}}

{{/*
Render port definitions

Parameters:
  - root: The root context (usually $)
  - ports: The port definitions list

Returns:
  YAML formatted port specifications
*/}}
{{- define "service.ports" -}}
{{- $root := .root -}}
{{- range $port := .ports -}}
- name: {{ $port.name | quote }}
  port: {{ $port.port }}
  {{- with $port.targetPort }}
  targetPort: {{ . }}
  {{- end }}
  {{- with $port.protocol }}
  protocol: {{ . }}
  {{- end }}
  {{- with $port.nodePort }}
  nodePort: {{ . }}
  {{- end }}
{{- end -}}
{{- end -}}

{{/*
Validate Service configuration

Parameters:
  - root: The root context (usually $)
  - service: The service values structure

Returns:
  Error message if validation fails, empty string otherwise
*/}}
{{- define "service.validate" -}}
{{- $service := .service -}}
{{- if not $service.ports -}}
  {{- fail "Service must have 'ports' defined" -}}
{{- end -}}
{{- if not (kindIs "slice" $service.ports) -}}
  {{- fail "Service 'ports' must be a list" -}}
{{- end -}}
{{- if not $service.ports -}}
  {{- fail "Service must have at least one port defined" -}}
{{- end -}}
{{- range $port := $service.ports -}}
  {{- if not $port.port -}}
    {{- fail "Each port must have a 'port' defined" -}}
  {{- end -}}
  {{- if not $port.name -}}
    {{- fail "Each port must have a 'name' defined" -}}
  {{- end -}}
{{- end -}}
{{- $type := default "ClusterIP" $service.type -}}
{{- if and (eq $type "ExternalName") $service.selector -}}
  {{- fail "Service of type ExternalName cannot have a selector" -}}
{{- end -}}
{{- end -}}
