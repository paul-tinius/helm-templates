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
  {{- with $config.annotations }}
  annotations:
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
{{- $name := include "configmap.getName" (dict "root" $root "config" $config) -}}
{{- if contains $name $root.Release.Name -}}
  {{- $root.Release.Name -}}
{{- else -}}
  {{- printf "%s-%s" $root.Release.Name $name | include "name.truncateName" -}}
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
app.kubernetes.io/name: {{ include "configmap.getName" (dict "root" $root "config" $config) | quote }}
app.kubernetes.io/instance: {{ $root.Release.Name | quote }}
app.kubernetes.io/managed-by: {{ $root.Release.Service | quote }}
{{- with $config.labels }}
{{- toYaml . | nindent 0 }}
{{- end }}
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
