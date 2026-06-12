{{/*
Istio DestinationRule Library Chart Helpers

This library provides reusable templates for creating Istio DestinationRule objects.
It supports load balancing, traffic policies, and subset configurations.

Usage:
  include "destinationrule.render" (dict "root" $ "destinationrule" $Values.destinationrule)

Expected structure:
  destinationrule:
    name: "my-destinationrule"           # Optional: defaults to chart name
    host: "my-service.default.svc.cluster.local"  # Required: destination host
    trafficPolicy:                        # Optional: traffic policy configuration
      loadBalancer:
        simple: ROUND_ROBIN
    subsets:                              # Optional: subset configurations
      - name: v1
        labels:
          version: v1
    labels: {}                           # Optional: additional labels
    annotations: {}                      # Optional: additional annotations

Inputs:
  - .Chart.Name: The chart name
  - .Release.Name: The release name
  - .Release.Namespace: The release namespace
  - destinationrule.host: Destination host (required)
  - destinationrule.name: Override for the destinationrule name (optional)
  - destinationrule.trafficPolicy: Traffic policy configuration (optional)
  - destinationrule.subsets: Subset configurations (optional)
  - destinationrule.labels: Additional labels (optional)
  - destinationrule.annotations: Additional annotations (optional)

Outputs:
  - destinationrule.render: Complete DestinationRule manifest
  - destinationrule.getName: The DestinationRule name
  - destinationrule.getFullName: The fully qualified DestinationRule name
  - destinationrule.labels: YAML formatted labels
  - destinationrule.validate: Validation helper (fails on invalid config)
*/}}

{{/*
Render a DestinationRule object

Parameters:
  - root: The root context (usually $)
  - destinationrule: The destinationrule values structure

Returns:
  Complete DestinationRule manifest
*/}}
{{- define "destinationrule.render" -}}
{{- $root := .root -}}
{{- $destinationrule := .destinationrule -}}
{{- $fullName := include "destinationrule.getFullName" (dict "root" $root "destinationrule" $destinationrule) -}}

apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "destinationrule.labels" (dict "root" $root "destinationrule" $destinationrule) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
    {{- with $destinationrule.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  host: {{ $destinationrule.host | quote }}
  {{- with $destinationrule.trafficPolicy }}
  trafficPolicy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $destinationrule.subsets }}
  subsets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}

{{/*
Get the DestinationRule name

Parameters:
  - root: The root context (usually $)
  - destinationrule: The destinationrule values structure

Returns:
  The DestinationRule name
*/}}
{{- define "destinationrule.getName" -}}
{{- $destinationrule := .destinationrule -}}
{{- default .root.Chart.Name $destinationrule.name | include "name.truncateName" -}}
{{- end -}}

{{/*
Get the DestinationRule full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - destinationrule: The destinationrule values structure

Returns:
  The fully qualified DestinationRule name
*/}}
{{- define "destinationrule.getFullName" -}}
{{- $root := .root -}}
{{- $destinationrule := .destinationrule -}}
{{- if $destinationrule.name -}}
  {{- $name := $destinationrule.name -}}
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
Generate standard labels for DestinationRule

Parameters:
  - root: The root context (usually $)
  - destinationrule: The destinationrule values structure

Returns:
  YAML formatted labels
*/}}
{{- define "destinationrule.labels" -}}
{{- $root := .root -}}
{{- $destinationrule := .destinationrule -}}
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
{{- with $destinationrule.labels -}}
  {{- range $k, $v := . -}}
    {{- $labels = set $labels $k $v -}}
  {{- end -}}
{{- end -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Validate DestinationRule configuration

Parameters:
  - root: The root context (usually $)
  - destinationrule: The destinationrule values structure

Returns:
  Error message if validation fails, empty string otherwise
*/}}
{{- define "destinationrule.validate" -}}
{{- $destinationrule := .destinationrule -}}
{{- if not $destinationrule.host -}}
  {{- fail "DestinationRule must have 'host' defined" -}}
{{- end -}}
{{- end -}}
