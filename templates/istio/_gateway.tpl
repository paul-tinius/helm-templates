{{/*
Istio Gateway Library Chart Helpers

This library provides reusable templates for creating Istio Gateway objects.
It supports multiple servers with flexible host, port, and TLS configuration.

Usage:
  include "gateway.render" (dict "root" $ "gateway" $Values.gateway)

Expected structure:
  gateway:
    name: "my-gateway"                     # Optional: defaults to chart name
    selector:                              # Required: selector for the Gateway
      istio: ingressgateway
    servers:                               # Required: server configurations
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
          - "*"
      - port:
          number: 443
          name: https
          protocol: HTTPS
        hosts:
          - "example.com"
        tls:
          mode: SIMPLE
          credentialName: my-tls-secret
    labels: {}                             # Optional: additional labels
    annotations: {}                        # Optional: additional annotations

Inputs:
  - .Chart.Name: The chart name
  - .Release.Name: The release name
  - .Release.Namespace: The release namespace
  - gateway.selector: Selector for the Gateway (required)
  - gateway.servers: List of server configurations (required)
  - gateway.name: Override for the gateway name (optional)
  - gateway.labels: Additional labels (optional)
  - gateway.annotations: Additional annotations (optional)

Outputs:
  - gateway.render: Complete Istio Gateway manifest
  - gateway.getName: The Gateway name
  - gateway.getFullName: The fully qualified Gateway name
  - gateway.labels: YAML formatted labels
  - gateway.validate: Validation helper (fails on invalid config)
*/}}

{{/*
Render an Istio Gateway object

Parameters:
  - root: The root context (usually $)
  - gateway: The gateway values structure

Returns:
  Complete Gateway manifest
*/}}
{{- define "gateway.render" -}}
{{- $root := .root -}}
{{- $gateway := .gateway -}}
{{- $fullName := include "gateway.getFullName" (dict "root" $root "gateway" $gateway) -}}

apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "gateway.labels" (dict "root" $root "gateway" $gateway) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
    {{- with $gateway.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  selector:
    {{- toYaml $gateway.selector | nindent 4 }}
  servers:
    {{- include "gateway.servers" (dict "root" $root "servers" $gateway.servers) | nindent 4 }}
{{- end -}}

{{/*
Get the Gateway name

Parameters:
  - root: The root context (usually $)
  - gateway: The gateway values structure

Returns:
  The Gateway name
*/}}
{{- define "gateway.getName" -}}
{{- $gateway := .gateway -}}
{{- default .root.Chart.Name $gateway.name | include "name.truncateName" -}}
{{- end -}}

{{/*
Get the Gateway full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - gateway: The gateway values structure

Returns:
  The fully qualified Gateway name
*/}}
{{- define "gateway.getFullName" -}}
{{- $root := .root -}}
{{- $gateway := .gateway -}}
{{- if $gateway.name -}}
  {{- $name := $gateway.name -}}
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
Generate standard labels for Gateway

Parameters:
  - root: The root context (usually $)
  - gateway: The gateway values structure

Returns:
  YAML formatted labels
*/}}
{{- define "gateway.labels" -}}
{{- $root := .root -}}
{{- $gateway := .gateway -}}
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
{{- with $gateway.labels -}}
  {{- range $k, $v := . -}}
    {{- $labels = set $labels $k $v -}}
  {{- end -}}
{{- end -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Render server configurations

Parameters:
  - root: The root context (usually $)
  - servers: The server configurations list

Returns:
  YAML formatted server specifications
*/}}
{{- define "gateway.servers" -}}
{{- $root := .root -}}
{{- range $server := .servers -}}
- port:
    {{- toYaml $server.port | nindent 6 }}
  {{- with $server.hosts }}
  hosts:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $server.tls }}
  tls:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $server.default }}
  default: {{ . }}
  {{- end }}
{{ end }}
{{- end -}}

{{/*
Validate Gateway configuration

Parameters:
  - root: The root context (usually $)
  - gateway: The gateway values structure

Returns:
  Error message if validation fails, empty string otherwise
*/}}
{{- define "gateway.validate" -}}
{{- $gateway := .gateway -}}
{{- if not $gateway.selector -}}
  {{- fail "Gateway must have 'selector' defined" -}}
{{- end -}}
{{- if not $gateway.servers -}}
  {{- fail "Gateway must have 'servers' defined" -}}
{{- end -}}
{{- if not (kindIs "slice" $gateway.servers) -}}
  {{- fail "Gateway 'servers' must be a list" -}}
{{- end -}}
{{- range $server := $gateway.servers -}}
  {{- if not $server.port -}}
    {{- fail "Each server must have 'port' defined" -}}
  {{- end -}}
  {{- if not $server.port.number -}}
    {{- fail "Each server port must have 'number' defined" -}}
  {{- end -}}
  {{- if not $server.port.name -}}
    {{- fail "Each server port must have 'name' defined" -}}
  {{- end -}}
  {{- if not $server.port.protocol -}}
    {{- fail "Each server port must have 'protocol' defined" -}}
  {{- end -}}
{{- end -}}
{{- end -}}
