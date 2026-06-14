{{/*
Agent Configuration ConfigMap

This template renders a ConfigMap containing agent configuration
with values from the Helm chart.

Usage:
  include "agentconfig.render" (dict "root" $ "config" $Values.agentconfig)

Expected structure:
  agentconfig:
    name: "sgent-config"              # Optional: defaults to "sgent-config"
    enabled:
      agent: true
      monitoring: true
      logging: true
      security: true
    data:
      agent:
        name: "my-agent"
        version: "1.0.0"
        mode: "production"
      monitoring:
        enabled: true
        interval: 30
        metrics_port: 9090
      logging:
        level: "info"
        format: "json"
        output: "stdout"
      security:
        tls_enabled: true
        auth_token: "${AUTH_TOKEN}"

Inputs:
  - .Chart.Name: The chart name
  - .Values.environment: The environment profile
  - .Values.agentconfig.data: Configuration data structure
  - .Values.agentconfig.enabled: Enable/disable flags for each section (optional, defaults to true)

Outputs:
  - agentconfig.render: Complete ConfigMap manifest
  - agentconfig.getName: The ConfigMap name
  - agentconfig.getFullName: The fully qualified ConfigMap name
  - agentconfig.labels: YAML formatted labels
  - agentconfig.data: YAML formatted data section

Section Enable/Disable:
  Set .Values.agentconfig.enabled.<section> to false to exclude that section.
  Available sections: agent, monitoring, logging, security
  If not specified, all sections are enabled by default.
*/}}

{{/*
Render a ConfigMap with agent configuration

Parameters:
  - root: The root context (usually $)
  - config: The agentconfig values structure

Returns:
  Complete ConfigMap manifest
*/}}
{{- define "agentconfig.render" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- $name := include "agentconfig.getName" (dict "root" $root "config" $config) -}}
{{- $fullName := include "agentconfig.getFullName" (dict "root" $root "config" $config) -}}

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "agentconfig.labels" (dict "root" $root "config" $config) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
data:
  {{- include "agentconfig.data" (dict "root" $root "config" $config) | nindent 2 }}
{{- end -}}

{{/*
Get the ConfigMap name

Parameters:
  - root: The root context (usually $)
  - config: The agentconfig values structure

Returns:
  The ConfigMap name
*/}}
{{- define "agentconfig.getName" -}}
{{- $config := .config -}}
{{- default "sgent-config" $config.name | include "name.truncateName" -}}
{{- end -}}

{{/*
Get the ConfigMap full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - config: The agentconfig values structure

Returns:
  The fully qualified ConfigMap name
*/}}
{{- define "agentconfig.getFullName" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- $name := default "sgent-config" $config.name -}}
{{- if contains $name $root.Release.Name -}}
  {{- $root.Release.Name | include "name.truncateName" -}}
{{- else -}}
  {{- printf "%s-%s" $root.Release.Name $name | include "name.truncateName" -}}
{{- end -}}
{{- end -}}

{{/*
Generate standard labels for Agent ConfigMap

Parameters:
  - root: The root context (usually $)
  - config: The agentconfig values structure

Returns:
  YAML formatted labels
*/}}
{{- define "agentconfig.labels" -}}
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
{{- $labels = set $labels "app.kubernetes.io/component" "sgent-config" -}}
{{- $labels = set $labels "app.kubernetes.io/instance" $root.Release.Name -}}
{{- if $root.Chart.AppVersion -}}
  {{- $labels = set $labels "app.kubernetes.io/version" $root.Chart.AppVersion -}}
{{- end -}}
{{- $labels = set $labels "app.kubernetes.io/managed-by" $root.Release.Service -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Generate ConfigMap data with agent configuration

Parameters:
  - root: The root context (usually $)
  - config: The agentconfig values structure

Returns:
  YAML formatted data section with agent configuration
*/}}
{{- define "agentconfig.data" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- $enabled := $config.enabled -}}
sgent-config.yaml: |
  # Agent Configuration for Kubernetes
  # This file is templated from values.yaml

  {{- if or (not $enabled) (not (hasKey $enabled "agent")) (eq $enabled.agent true) }}
  # Agent configuration
  agent:
    name: {{ $config.data.agent.name }}
    version: {{ $config.data.agent.version }}
    mode: {{ $config.data.agent.mode }}
    environment: {{ $root.Values.environment }}
  {{- end }}

  {{- if or (not $enabled) (not (hasKey $enabled "monitoring")) (eq $enabled.monitoring true) }}
  # Monitoring configuration
  monitoring:
    enabled: {{ $config.data.monitoring.enabled }}
    interval: {{ $config.data.monitoring.interval }}
    metrics_port: {{ $config.data.monitoring.metrics_port }}
  {{- end }}

  {{- if or (not $enabled) (not (hasKey $enabled "logging")) (eq $enabled.logging true) }}
  # Logging configuration
  logging:
    level: {{ $config.data.logging.level }}
    format: {{ $config.data.logging.format }}
    output: {{ $config.data.logging.output }}
  {{- end }}

  {{- if or (not $enabled) (not (hasKey $enabled "security")) (eq $enabled.security true) }}
  # Security configuration
  security:
    tls_enabled: {{ $config.data.security.tls_enabled }}
    auth_token: {{ $config.data.security.auth_token }}
  {{- end }}
{{- end -}}
