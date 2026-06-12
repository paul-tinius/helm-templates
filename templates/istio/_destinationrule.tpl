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
{{- $name := default $root.Chart.Name $destinationrule.name -}}
{{- if contains $name $root.Release.Name -}}
  {{- $root.Release.Name -}}
{{- else -}}
  {{- printf "%s-%s" $root.Release.Name $name -}}
{{- end -}}
{{- include "name.truncateName" . -}}
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
{{- include "labels.default" $root }}
{{- with $destinationrule.labels }}
{{- toYaml . | nindent 0 }}
{{- end }}
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
