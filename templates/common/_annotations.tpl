{{/*
Annotations Library Chart Helpers

This library provides reusable templates for generating Kubernetes annotations.
It supports both global annotations shared across objects and pod-specific annotations.

Usage:
  include "annotations" .
  include "podAnnotations" .

Expected structure:
  global:
    annotations:                           # Optional: global annotations for all objects
      key1: "value1"
      key2: "{{ .Release.Name }}-value"
  podAnnotations:                          # Optional: pod-specific annotations
    key1: "value1"
    key2: "value2"

Inputs:
  - .Values.global.annotations: Map of global annotations (supports template rendering)
  - .Values.podAnnotations: Map of pod annotations (supports template rendering)

Outputs:
  - annotations: YAML formatted annotation key-value pairs
  - podAnnotations: YAML formatted pod annotation key-value pairs
*/}}

{{/* Common annotations shared across objects */}}
{{- define "annotations" -}}
  {{- with .Values.global.annotations }}
    {{- range $k, $v := . }}
{{ $k }}: {{ tpl $v $ | quote }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/* Determine the Pod annotations used in the controller */}}
{{- define "podAnnotations" -}}
  {{- if .Values.podAnnotations -}}
    {{- tpl (toYaml .Values.podAnnotations) . -}}
  {{- end -}}
{{- end -}}