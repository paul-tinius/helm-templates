{{/*
ConfigMap Library Chart Helpers

This library provides reusable templates for creating Kubernetes ConfigMap objects.
It supports both literal data and file-based data, with flexible naming and labeling.

Usage:
  include "configmap.render" (dict "root" $ "configmap" $Values.configmap.myConfig)

Expected structure:
  configmap:
    name: "my-config"                    # Optional: defaults to chart name
    data:                                # Required: key-value pairs
      key1: "value1"
      key2: "value2"
    dataFrom:                            # Optional: load data from files
      - file: "/path/to/file"
        key: "config-file"
    labels: {}                           # Optional: additional labels
    annotations: {}                      # Optional: additional annotations

Inputs:
  - .Chart.Name: The chart name
  - .Release.Name: The release name
  - .Release.Namespace: The release namespace
  - configmap.name: Override for the configmap name (optional)
  - configmap.data: Map of literal data key-value pairs (supports template rendering)
  - configmap.dataFrom: List of file-based data references
  - configmap.labels: Additional labels (optional)
  - configmap.annotations: Additional annotations (optional)

Outputs:
  - configmap.render: Complete ConfigMap manifest
  - configmap.getName: The ConfigMap name
  - configmap.getFullName: The fully qualified ConfigMap name
  - configmap.labels: YAML formatted labels
  - configmap.data: YAML formatted data section
  - configmap.validate: Validation helper (fails on invalid config)
*/}}

{{/*
Render a ConfigMap object

Parameters:
  - root: The root context (usually $)
  - configmap: The configmap values structure

Returns:
  Complete ConfigMap manifest
*/}}
{{- define "configmap.render" -}}
{{- $root := .root -}}
{{- $config := .configmap -}}
{{- $name := include "configmap.getName" (dict "root" $root "config" $config) -}}
{{- $fullName := include "configmap.getFullName" (dict "root" $root "config" $config) -}}

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "configmap.labels" (dict "root" $root "config" $config) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
    {{- with $config.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
data:
  {{- include "configmap.data" (dict "root" $root "config" $config) | nindent 2 }}
{{- end -}}

{{/*
Get the ConfigMap name

Parameters:
  - root: The root context (usually $)
  - config: The configmap values structure

Returns:
  The ConfigMap name
*/}}
{{- define "configmap.getName" -}}
{{- $config := .config -}}
{{- default .root.Chart.Name $config.name | include "name.truncateName" -}}
{{- end -}}

{{/*
Get the ConfigMap full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - config: The configmap values structure

Returns:
  The fully qualified ConfigMap name
*/}}
{{- define "configmap.getFullName" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- if $config.name -}}
  {{- $name := $config.name -}}
  {{- if contains $name $root.Release.Name -}}
    {{- $root.Release.Name | include "name.truncateName" -}}
  {{- else -}}
    {{- printf "%s-%s" $root.Release.Name $name | include "name.truncateName" -}}
  {{- end -}}
{{- else -}}
  {{- include "names.fullName" $root -}}
{{- end -}}
{{- end -}}

{{/*
Generate standard labels for ConfigMap

Parameters:
  - root: The root context (usually $)
  - config: The configmap values structure

Returns:
  YAML formatted labels
*/}}
{{- define "configmap.labels" -}}
{{- $root := .root -}}
{{- $config := .config -}}
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
{{- with $config.labels -}}
  {{- range $k, $v := . -}}
    {{- $labels = set $labels $k $v -}}
  {{- end -}}
{{- end -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Generate ConfigMap data from literals and/or files

Parameters:
  - root: The root context (usually $)
  - config: The configmap values structure

Returns:
  YAML formatted data section
*/}}
{{- define "configmap.data" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- if $config.data -}}
  {{- range $key, $value := $config.data }}
{{ $key }}: {{ tpl $value $root | quote }}
  {{- end }}
{{- end -}}
{{- if $config.dataFrom -}}
  {{- range $item := $config.dataFrom }}
    {{- if $item.file }}
{{ $item.key }}: |
{{- $root.Files.Get $item.file | indent 2 }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate ConfigMap configuration

Parameters:
  - root: The root context (usually $)
  - config: The configmap values structure

Returns:
  Error message if validation fails, empty string otherwise
*/}}
{{- define "configmap.validate" -}}
{{- $config := .config -}}
{{- if not (or $config.data $config.dataFrom) -}}
  {{- fail "ConfigMap must have either 'data' or 'dataFrom' defined" -}}
{{- end -}}
{{- if and $config.data $config.dataFrom -}}
  {{- fail "ConfigMap cannot have both 'data' and 'dataFrom' defined simultaneously" -}}
{{- end -}}
{{- end -}}
