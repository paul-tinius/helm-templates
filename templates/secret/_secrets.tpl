{{/*
Secret Library Chart Helpers

This library provides reusable templates for creating Kubernetes Secret objects.
It supports both literal data and string data, with flexible naming, labeling, and type support.

Usage:
  include "secret.render" (dict "root" $ "secret" $Values.secret.mySecret)

Expected structure:
  secret:
    name: "my-secret"                    # Optional: defaults to chart name
    type: "Opaque"                       # Optional: defaults to Opaque
    data:                                # Optional: base64-encoded key-value pairs
      key1: "dmFsdWUx"                    # base64 encoded "value1"
      key2: "dmFsdWUy"
    stringData:                          # Optional: plain text key-value pairs (auto-encoded)
      username: "admin"
      password: "secret123"
    dataFrom:                            # Optional: load data from files
      - file: "/path/to/file"
        key: "config-file"
    labels: {}                           # Optional: additional labels
    annotations: {}                      # Optional: additional annotations

Inputs:
  - .Chart.Name: The chart name
  - .Release.Name: The release name
  - .Release.Namespace: The release namespace
  - secret.name: Override for the secret name (optional)
  - secret.type: Kubernetes Secret type (optional, defaults to Opaque)
  - secret.data: Map of base64-encoded data key-value pairs (supports template rendering)
  - secret.stringData: Map of plain text data key-value pairs (supports template rendering)
  - secret.dataFrom: List of file-based data references
  - secret.labels: Additional labels (optional)
  - secret.annotations: Additional annotations (optional)

Outputs:
  - secret.render: Complete Secret manifest
  - secret.getName: The Secret name
  - secret.getFullName: The fully qualified Secret name
  - secret.labels: YAML formatted labels
  - secret.data: YAML formatted data section
  - secret.stringData: YAML formatted stringData section
  - secret.validate: Validation helper (fails on invalid config)
*/}}

{{/*
Render a Secret object

Parameters:
  - root: The root context (usually $)
  - secret: The secret values structure

Returns:
  Complete Secret manifest
*/}}
{{- define "secret.render" -}}
{{- $root := .root -}}
{{- $secret := .secret -}}
{{- $name := include "secret.getName" (dict "root" $root "secret" $secret) -}}
{{- $fullName := include "secret.getFullName" (dict "root" $root "secret" $secret) -}}
{{- $type := default "Opaque" $secret.type -}}

apiVersion: v1
kind: Secret
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "secret.labels" (dict "root" $root "secret" $secret) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
    {{- with $secret.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
type: {{ $type | quote }}
{{- if $secret.data }}
data:
  {{- include "secret.data" (dict "root" $root "secret" $secret) | nindent 2 }}
{{- end }}
{{- if $secret.stringData }}
stringData:
  {{- include "secret.stringData" (dict "root" $root "secret" $secret) | nindent 2 }}
{{- end }}
{{- if $secret.dataFrom }}
data:
  {{- include "secret.dataFrom" (dict "root" $root "secret" $secret) | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Get the Secret name

Parameters:
  - root: The root context (usually $)
  - secret: The secret values structure

Returns:
  The Secret name
*/}}
{{- define "secret.getName" -}}
{{- $secret := .secret -}}
{{- default .root.Chart.Name $secret.name | include "name.truncateName" -}}
{{- end -}}

{{/*
Get the Secret full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - secret: The secret values structure

Returns:
  The fully qualified Secret name
*/}}
{{- define "secret.getFullName" -}}
{{- $root := .root -}}
{{- $secret := .secret -}}
{{- if $secret.name -}}
  {{- $name := $secret.name -}}
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
Generate standard labels for Secret

Parameters:
  - root: The root context (usually $)
  - secret: The secret values structure

Returns:
  YAML formatted labels
*/}}
{{- define "secret.labels" -}}
{{- $root := .root -}}
{{- $secret := .secret -}}
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
{{- with $secret.labels -}}
  {{- range $k, $v := . -}}
    {{- $labels = set $labels $k $v -}}
  {{- end -}}
{{- end -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Generate Secret data from base64-encoded literals

Parameters:
  - root: The root context (usually $)
  - secret: The secret values structure

Returns:
  YAML formatted data section
*/}}
{{- define "secret.data" -}}
{{- $root := .root -}}
{{- $secret := .secret -}}
{{- if $secret.data -}}
  {{- range $key, $value := $secret.data }}
{{ $key }}: {{ tpl $value $root | quote }}
  {{- end }}
{{- end -}}
{{- end -}}

{{/*
Generate Secret stringData from plain text (auto-encoded by Kubernetes)

Parameters:
  - root: The root context (usually $)
  - secret: The secret values structure

Returns:
  YAML formatted stringData section
*/}}
{{- define "secret.stringData" -}}
{{- $root := .root -}}
{{- $secret := .secret -}}
{{- if $secret.stringData -}}
  {{- range $key, $value := $secret.stringData }}
{{ $key }}: {{ tpl $value $root | quote }}
  {{- end }}
{{- end -}}
{{- end -}}

{{/*
Generate Secret data from files

Parameters:
  - root: The root context (usually $)
  - secret: The secret values structure

Returns:
  YAML formatted data section from files
*/}}
{{- define "secret.dataFrom" -}}
{{- $root := .root -}}
{{- $secret := .secret -}}
{{- if $secret.dataFrom -}}
  {{- range $item := $secret.dataFrom }}
    {{- if $item.file }}
{{ $item.key }}: |
{{- $root.Files.Get $item.file | indent 2 }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate Secret configuration

Parameters:
  - root: The root context (usually $)
  - secret: The secret values structure

Returns:
  Error message if validation fails, empty string otherwise
*/}}
{{- define "secret.validate" -}}
{{- $secret := .secret -}}
{{- $dataCount := 0 -}}
{{- if $secret.data -}}{{ $dataCount = add1 $dataCount }}{{- end -}}
{{- if $secret.stringData -}}{{ $dataCount = add1 $dataCount }}{{- end -}}
{{- if $secret.dataFrom -}}{{ $dataCount = add1 $dataCount }}{{- end -}}
{{- if eq $dataCount 0 -}}
  {{- fail "Secret must have either 'data', 'stringData', or 'dataFrom' defined" -}}
{{- end -}}
{{- if gt $dataCount 1 -}}
  {{- fail "Secret cannot have more than one of 'data', 'stringData', or 'dataFrom' defined simultaneously" -}}
{{- end -}}
{{- end -}}
