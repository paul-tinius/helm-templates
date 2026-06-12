{{/*
Labels Library Chart Helpers

This library provides reusable templates for generating Kubernetes labels.
It supports both default labels shared across objects and selector labels for pod matching.

Usage:
  include "labels.default" .
  include "labels.selectorLabels" .

Expected structure:
  global:
    labels:                                # Optional: global labels for all objects
      key1: "value1"
      key2: "{{ .Release.Name }}-value"
  nameOverride: "my-name"                 # Optional: override the chart name
  fullnameOverride: "my-full-name"       # Optional: override the full name

Inputs:
  - .Chart.Name: The chart name
  - .Chart.Version: The chart version
  - .Chart.AppVersion: The app version (optional)
  - .Release.Name: The release name
  - .Release.Service: The release service (typically Helm)
  - .Values.global.labels: Map of global labels (supports template rendering)
  - .Values.nameOverride: Override for the chart name
  - .Values.fullnameOverride: Override for the full name

Outputs:
  - labels.default: YAML formatted default labels including chart, version, and selector labels
  - labels.selectorLabels: YAML formatted selector labels for pod matching
*/}}

{{/* Common labels shared across objects */}}
{{- define "labels.default" -}}
{{- $labels := dict -}}
{{- if .Values.global.labels -}}
  {{- range $k, $v := .Values.global.labels -}}
    {{- $labels = set $labels $k (tpl $v .) -}}
  {{- end -}}
{{- end -}}
{{- $labels = set $labels "helm.sh/chart" (include "names.chart" .) -}}
{{- $labels = set $labels "app.kubernetes.io/name" (include "names.name" .) -}}
{{- $labels = set $labels "app.kubernetes.io/instance" .Release.Name -}}
{{- if .Chart.AppVersion -}}
  {{- $labels = set $labels "app.kubernetes.io/version" .Chart.AppVersion -}}
{{- end -}}
{{- $labels = set $labels "app.kubernetes.io/managed-by" .Release.Service -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/* Selector labels shared across objects */}}
{{- define "labels.selectorLabels" -}}
{{- $labels := dict -}}
{{- $labels = set $labels "app.kubernetes.io/name" (include "names.name" .) -}}
{{- $labels = set $labels "app.kubernetes.io/instance" .Release.Name -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}