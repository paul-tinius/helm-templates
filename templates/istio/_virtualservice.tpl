{{/*
Istio VirtualService Library Chart Helpers

This library provides reusable templates for creating Istio VirtualService objects.
It supports HTTP, TCP, and TLS routing with flexible host and route configurations.

Usage:
  include "virtualservice.render" (dict "root" $ "virtualservice" $Values.virtualservice)

Expected structure:
  virtualservice:
    name: "my-virtualservice"             # Optional: defaults to chart name
    hosts:                                # Required: list of hosts
      - "example.com"
    gateways:                             # Optional: list of gateways
      - my-gateway
    http:                                 # Optional: HTTP routes
      - match:
        - uri:
            prefix: /
        route:
        - destination:
            host: my-service
            port:
              number: 80
    tcp:                                  # Optional: TCP routes
      - match:
        - port: 443
        route:
        - destination:
            host: my-service
            port:
              number: 443
    tls:                                  # Optional: TLS routes
      - match:
        - port: 443
        route:
        - destination:
            host: my-service
            port:
              number: 443
    labels: {}                           # Optional: additional labels
    annotations: {}                      # Optional: additional annotations

Inputs:
  - .Chart.Name: The chart name
  - .Release.Name: The release name
  - .Release.Namespace: The release namespace
  - virtualservice.hosts: List of hosts (required)
  - virtualservice.name: Override for the virtualservice name (optional)
  - virtualservice.gateways: List of gateways (optional)
  - virtualservice.http: HTTP route configurations (optional)
  - virtualservice.tcp: TCP route configurations (optional)
  - virtualservice.tls: TLS route configurations (optional)
  - virtualservice.labels: Additional labels (optional)
  - virtualservice.annotations: Additional annotations (optional)

Outputs:
  - virtualservice.render: Complete VirtualService manifest
  - virtualservice.getName: The VirtualService name
  - virtualservice.getFullName: The fully qualified VirtualService name
  - virtualservice.labels: YAML formatted labels
  - virtualservice.validate: Validation helper (fails on invalid config)
*/}}

{{/*
Render a VirtualService object

Parameters:
  - root: The root context (usually $)
  - virtualservice: The virtualservice values structure

Returns:
  Complete VirtualService manifest
*/}}
{{- define "virtualservice.render" -}}
{{- $root := .root -}}
{{- $virtualservice := .virtualservice -}}
{{- $fullName := include "virtualservice.getFullName" (dict "root" $root "virtualservice" $virtualservice) -}}

apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "virtualservice.labels" (dict "root" $root "virtualservice" $virtualservice) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
    {{- with $virtualservice.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  hosts:
    {{- toYaml $virtualservice.hosts | nindent 4 }}
  {{- with $virtualservice.gateways }}
  gateways:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $virtualservice.http }}
  http:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $virtualservice.tcp }}
  tcp:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $virtualservice.tls }}
  tls:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}

{{/*
Get the VirtualService name

Parameters:
  - root: The root context (usually $)
  - virtualservice: The virtualservice values structure

Returns:
  The VirtualService name
*/}}
{{- define "virtualservice.getName" -}}
{{- $virtualservice := .virtualservice -}}
{{- default .root.Chart.Name $virtualservice.name | include "name.truncateName" -}}
{{- end -}}

{{/*
Get the VirtualService full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - virtualservice: The virtualservice values structure

Returns:
  The fully qualified VirtualService name
*/}}
{{- define "virtualservice.getFullName" -}}
{{- $root := .root -}}
{{- $virtualservice := .virtualservice -}}
{{- if $virtualservice.name -}}
  {{- $name := $virtualservice.name -}}
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
Generate standard labels for VirtualService

Parameters:
  - root: The root context (usually $)
  - virtualservice: The virtualservice values structure

Returns:
  YAML formatted labels
*/}}
{{- define "virtualservice.labels" -}}
{{- $root := .root -}}
{{- $virtualservice := .virtualservice -}}
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
{{- with $virtualservice.labels -}}
  {{- range $k, $v := . -}}
    {{- $labels = set $labels $k $v -}}
  {{- end -}}
{{- end -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Validate VirtualService configuration

Parameters:
  - root: The root context (usually $)
  - virtualservice: The virtualservice values structure

Returns:
  Error message if validation fails, empty string otherwise
*/}}
{{- define "virtualservice.validate" -}}
{{- $virtualservice := .virtualservice -}}
{{- if not $virtualservice.hosts -}}
  {{- fail "VirtualService must have 'hosts' defined" -}}
{{- end -}}
{{- if not (kindIs "slice" $virtualservice.hosts) -}}
  {{- fail "VirtualService 'hosts' must be a list" -}}
{{- end -}}
{{- end -}}
