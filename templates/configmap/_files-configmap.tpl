{{/*
Files ConfigMap Template

This template renders a ConfigMap containing arbitrary files with key:value properties
defined in values.yaml. Each file can have its own name and content structure.

Usage:
  include "filesconfigmap.render" (dict "root" $ "config" $Values.filesconfigmap)

Expected structure in values.yaml:
  filesConfigmap:
    name: "my-config"                    # Optional: defaults to "files-config"
    component: "my-component"             # Optional: component label value
    files:
      - name: "application.properties"   # The key in ConfigMap data
        content:                          # The content (will be converted to YAML)
          app.name: "my-app"
          app.version: "1.0.0"
          database.url: "jdbc:postgresql://localhost:5432/mydb"
      - name: "config.yaml"
        content:
          server:
            port: 8080
            host: "0.0.0.0"
          logging:
            level: "info"
      - name: "custom.conf"
        content: |
          # Raw string content
          server.port=8080
          server.host=localhost
        raw: true                         # Set to true for raw string content

Inputs:
  - .Chart.Name: The chart name
  - .Release.Name: The release name
  - .Release.Namespace: The release namespace
  - config: The filesconfigmap values structure

Outputs:
  - filesconfigmap.render: Complete ConfigMap manifest
  - filesconfigmap.getName: The ConfigMap name
  - filesconfigmap.getFullName: The fully qualified ConfigMap name
  - filesconfigmap.labels: YAML formatted labels
  - filesconfigmap.data: YAML formatted data section
*/}}

{{/*
Render a ConfigMap with file configurations

Parameters:
  - root: The root context (usually $)
  - config: The filesconfigmap values structure

Returns:
  Complete ConfigMap manifest
*/}}
{{- define "filesconfigmap.render" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- $name := include "filesconfigmap.getName" (dict "root" $root "config" $config) -}}
{{- $fullName := include "filesconfigmap.getFullName" (dict "root" $root "config" $config) -}}

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "filesconfigmap.labels" (dict "root" $root "config" $config) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
data:
  {{- include "filesconfigmap.data" (dict "root" $root "config" $config) | nindent 2 }}
{{- end -}}

{{/*
Get the ConfigMap name

Parameters:
  - root: The root context (usually $)
  - config: The filesconfigmap values structure

Returns:
  The ConfigMap name
*/}}
{{- define "filesconfigmap.getName" -}}
{{- $config := .config -}}
{{- default "files-config" $config.name | include "name.truncateName" -}}
{{- end -}}

{{/*
Get the ConfigMap full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - config: The filesconfigmap values structure

Returns:
  The fully qualified ConfigMap name
*/}}
{{- define "filesconfigmap.getFullName" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- $name := default "files-config" $config.name -}}
{{- if contains $name $root.Release.Name -}}
  {{- $root.Release.Name | include "name.truncateName" -}}
{{- else -}}
  {{- printf "%s-%s" $root.Release.Name $name | include "name.truncateName" -}}
{{- end -}}
{{- end -}}

{{/*
Generate standard labels for Files ConfigMap

Parameters:
  - root: The root context (usually $)
  - config: The filesconfigmap values structure

Returns:
  YAML formatted labels
*/}}
{{- define "filesconfigmap.labels" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- $component := default "files-config" $config.component -}}
{{- $labels := dict -}}
{{- if $root.Values.global.labels -}}
  {{- range $k, $v := $root.Values.global.labels -}}
    {{- $labels = set $labels $k (tpl $v $root) -}}
  {{- end -}}
{{- end -}}
{{- if $config.labels -}}
  {{- range $k, $v := $config.labels -}}
    {{- $labels = set $labels $k (tpl $v $root) -}}
  {{- end -}}
{{- end -}}
{{- $labels = set $labels "helm.sh/chart" (include "names.chart" $root) -}}
{{- $labels = set $labels "app.kubernetes.io/name" $root.Chart.Name -}}
{{- $labels = set $labels "app.kubernetes.io/component" $component -}}
{{- $labels = set $labels "app.kubernetes.io/instance" $root.Release.Name -}}
{{- if $root.Chart.AppVersion -}}
  {{- $labels = set $labels "app.kubernetes.io/version" $root.Chart.AppVersion -}}
{{- end -}}
{{- $labels = set $labels "app.kubernetes.io/managed-by" $root.Release.Service -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Generate ConfigMap data with file configurations

Parameters:
  - root: The root context (usually $)
  - config: The filesconfigmap values structure

Returns:
  YAML formatted data section with file configurations
*/}}
{{- define "filesconfigmap.data" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- $files := $config.files -}}
{{- range $file := $files }}
  {{- $fileName := $file.name -}}
  {{- if $file.raw -}}
    {{- /* Raw string content */ -}}
  {{ $fileName }}: |
{{ $file.content | indent 2 }}{{ printf "\n" }}
  {{- else -}}
    {{- /* YAML content - convert to YAML string */ -}}
  {{ $fileName }}: |
{{ $file.content | toYaml | indent 2 }}{{ printf "\n" }}
  {{- end -}}
{{- end -}}
{{- end -}}
