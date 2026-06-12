{{/*
ServiceAccount Library Chart Helpers

This library provides reusable templates for creating Kubernetes ServiceAccount objects.
It supports automounting service account tokens, image pull secrets, and custom annotations.

Usage:
  include "serviceaccount.render" (dict "root" $ "serviceaccount" $Values.serviceAccount)

Expected structure:
  serviceAccount:
    create: true                           # Optional: whether to create a ServiceAccount (defaults to true)
    name: "my-service-account"             # Optional: override the service account name
    annotations: {}                        # Optional: additional annotations
    labels: {}                             # Optional: additional labels
    automountServiceAccountToken: false    # Optional: automount service account token (defaults to true)
    secrets: []                            # Optional: list of secret names
    imagePullSecrets:                      # Optional: image pull secrets
      - name: my-registry-secret
    metadata: {}                           # Optional: additional metadata

Inputs:
  - .Chart.Name: The chart name
  - .Release.Name: The release name
  - .Release.Namespace: The release namespace
  - serviceAccount.create: Whether to create a ServiceAccount (optional, defaults to true)
  - serviceAccount.name: Override for the service account name (optional)
  - serviceAccount.annotations: Additional annotations (optional)
  - serviceAccount.labels: Additional labels (optional)
  - serviceAccount.automountServiceAccountToken: Automount token setting (optional)
  - serviceAccount.secrets: List of secret names (optional)
  - serviceAccount.imagePullSecrets: Image pull secrets (optional)
  - serviceAccount.metadata: Additional metadata (optional)

Outputs:
  - serviceaccount.render: Complete ServiceAccount manifest
  - serviceaccount.getName: The ServiceAccount name
  - serviceaccount.getFullName: The fully qualified ServiceAccount name
  - serviceaccount.labels: YAML formatted labels
  - serviceaccount.validate: Validation helper (fails on invalid config)
*/}}

{{/*
Render a ServiceAccount object

Parameters:
  - root: The root context (usually $)
  - serviceaccount: The serviceaccount values structure

Returns:
  Complete ServiceAccount manifest
*/}}
{{- define "serviceaccount.render" -}}
{{- $root := .root -}}
{{- $serviceaccount := .serviceaccount -}}
{{- $fullName := include "serviceaccount.getFullName" (dict "root" $root "serviceaccount" $serviceaccount) -}}

apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "serviceaccount.labels" (dict "root" $root "serviceaccount" $serviceaccount) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
    {{- with $serviceaccount.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $serviceaccount.metadata }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- if ne (default true $serviceaccount.automountServiceAccountToken) true }}
automountServiceAccountToken: {{ $serviceaccount.automountServiceAccountToken }}
{{- end }}
{{- with $serviceaccount.secrets }}
secrets:
  {{- range . }}
  - name: {{ . | quote }}
  {{- end }}
{{- end }}
{{- with $serviceaccount.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Get the ServiceAccount name

Parameters:
  - root: The root context (usually $)
  - serviceaccount: The serviceaccount values structure

Returns:
  The ServiceAccount name
*/}}
{{- define "serviceaccount.getName" -}}
{{- $root := .root -}}
{{- $serviceaccount := .serviceaccount -}}
{{- if $serviceaccount.name -}}
  {{- $serviceaccount.name | include "name.truncateName" -}}
{{- else -}}
  {{- include "names.name" $root -}}
{{- end -}}
{{- end -}}

{{/*
Get the ServiceAccount full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - serviceaccount: The serviceaccount values structure

Returns:
  The fully qualified ServiceAccount name
*/}}
{{- define "serviceaccount.getFullName" -}}
{{- $root := .root -}}
{{- $serviceaccount := .serviceaccount -}}
{{- if $serviceaccount.name -}}
  {{- $name := $serviceaccount.name -}}
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
Generate standard labels for ServiceAccount

Parameters:
  - root: The root context (usually $)
  - serviceaccount: The serviceaccount values structure

Returns:
  YAML formatted labels
*/}}
{{- define "serviceaccount.labels" -}}
{{- $root := .root -}}
{{- $serviceaccount := .serviceaccount -}}
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
{{- with $serviceaccount.labels -}}
  {{- range $k, $v := . -}}
    {{- $labels = set $labels $k $v -}}
  {{- end -}}
{{- end -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Validate ServiceAccount configuration

Parameters:
  - root: The root context (usually $)
  - serviceaccount: The serviceaccount values structure

Returns:
  Error message if validation fails, empty string otherwise
*/}}
{{- define "serviceaccount.validate" -}}
{{- $serviceaccount := .serviceaccount -}}
{{- if $serviceaccount.secrets -}}
  {{- if not (kindIs "slice" $serviceaccount.secrets) -}}
    {{- fail "ServiceAccount 'secrets' must be a list" -}}
  {{- end -}}
{{- end -}}
{{- if $serviceaccount.imagePullSecrets -}}
  {{- if not (kindIs "slice" $serviceaccount.imagePullSecrets) -}}
    {{- fail "ServiceAccount 'imagePullSecrets' must be a list" -}}
  {{- end -}}
{{- end -}}
{{- end -}}
