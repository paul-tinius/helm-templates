{{/*
Spring Boot Application Configuration ConfigMap

This template renders a ConfigMap containing Spring Boot application-k8s.yaml
configuration with values from the Helm chart.

Usage:
  include "applicationK8s.render" (dict "root" $ "config" $Values.configmap)

Expected structure:
  configmap:
    name: "application-k8s"              # Optional: defaults to "application-k8s"
    enabled:
      datasource: true
      redis: true
      management: true
      app: true
      server: true
    data:
      database:
        host: "postgres"
        port: 5432
      cache:
        host: "redis"
        port: 6379
      app:
        env: "production"
        log_level: "info"
        feature_flags:
          enabled: true
          new_ui: false

Inputs:
  - .Chart.Name: The chart name
  - .Values.environment: The environment profile
  - .Values.configmap.data: Configuration data structure
  - .Values.configmap.enabled: Enable/disable flags for each section (optional, defaults to true)

Outputs:
  - applicationK8s.render: Complete ConfigMap manifest
  - applicationK8s.getName: The ConfigMap name
  - applicationK8s.getFullName: The fully qualified ConfigMap name
  - applicationK8s.labels: YAML formatted labels
  - applicationK8s.data: YAML formatted data section

Section Enable/Disable:
  Set .Values.configmap.enabled.<section> to false to exclude that section.
  Available sections: datasource, redis, management, app, server
  If not specified, all sections are enabled by default.
*/}}

{{/*
Render a ConfigMap with Spring Boot application-k8s.yaml configuration

Parameters:
  - root: The root context (usually $)
  - config: The configmap values structure

Returns:
  Complete ConfigMap manifest
*/}}
{{- define "applicationK8s.render" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- $name := include "applicationK8s.getName" (dict "root" $root "config" $config) -}}
{{- $fullName := include "applicationK8s.getFullName" (dict "root" $root "config" $config) -}}

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "applicationK8s.labels" (dict "root" $root "config" $config) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
data:
  {{- include "applicationK8s.data" (dict "root" $root "config" $config) | nindent 2 }}
{{- end -}}

{{/*
Get the ConfigMap name

Parameters:
  - root: The root context (usually $)
  - config: The configmap values structure

Returns:
  The ConfigMap name
*/}}
{{- define "applicationK8s.getName" -}}
{{- $config := .config -}}
{{- default "application-k8s" $config.name | include "name.truncateName" -}}
{{- end -}}

{{/*
Get the ConfigMap full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - config: The configmap values structure

Returns:
  The fully qualified ConfigMap name
*/}}
{{- define "applicationK8s.getFullName" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- $name := default "application-k8s" $config.name -}}
{{- if contains $name $root.Release.Name -}}
  {{- $root.Release.Name | include "name.truncateName" -}}
{{- else -}}
  {{- printf "%s-%s" $root.Release.Name $name | include "name.truncateName" -}}
{{- end -}}
{{- end -}}

{{/*
Generate standard labels for Application ConfigMap

Parameters:
  - root: The root context (usually $)
  - config: The configmap values structure

Returns:
  YAML formatted labels
*/}}
{{- define "applicationK8s.labels" -}}
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
{{- $labels = set $labels "app.kubernetes.io/component" "application-k8s-config" -}}
{{- $labels = set $labels "app.kubernetes.io/instance" $root.Release.Name -}}
{{- if $root.Chart.AppVersion -}}
  {{- $labels = set $labels "app.kubernetes.io/version" $root.Chart.AppVersion -}}
{{- end -}}
{{- $labels = set $labels "app.kubernetes.io/managed-by" $root.Release.Service -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Generate ConfigMap data with Spring Boot application-k8s.yaml configuration

Parameters:
  - root: The root context (usually $)
  - config: The configmap values structure

Returns:
  YAML formatted data section with application-k8s.yaml content
*/}}
{{- define "applicationK8s.data" -}}
{{- $root := .root -}}
{{- $config := .config -}}
{{- $enabled := $config.enabled -}}
application-k8s.yaml: |
  # Spring Boot Application Configuration for Kubernetes
  # This file is templated from values.yaml

  spring:
    application:
      name: {{ $root.Chart.Name }}
    profiles:
      active: {{ $root.Values.environment }}

  {{- if or (not $enabled) (not (hasKey $enabled "datasource")) (eq $enabled.datasource true) }}
    # Database configuration
    datasource:
      url: jdbc:postgresql://{{ $config.data.database.host }}:{{ $config.data.database.port }}/appdb
      username: ${DATABASE_USERNAME}
      password: ${DATABASE_PASSWORD}
      driver-class-name: org.postgresql.Driver
      hikari:
        maximum-pool-size: 10
        minimum-idle: 5
        connection-timeout: 30000
  {{- end }}

  {{- if or (not $enabled) (not (hasKey $enabled "redis")) (eq $enabled.redis true) }}
    # Redis cache configuration
    redis:
      host: {{ $config.data.cache.host }}
      port: {{ $config.data.cache.port }}
      timeout: 60000
      lettuce:
        pool:
          max-active: 8
          max-idle: 8
          min-idle: 0
  {{- end }}

  {{- if or (not $enabled) (not (hasKey $enabled "management")) (eq $enabled.management true) }}
    # Actuator configuration
    management:
      endpoints:
        web:
          exposure:
            include: health,info,metrics,prometheus
      endpoint:
        health:
          show-details: always
      metrics:
        export:
          prometheus:
            enabled: true
  {{- end }}

  {{- if or (not $enabled) (not (hasKey $enabled "app")) (eq $enabled.app true) }}
  # Application-specific configuration
  app:
    environment: {{ $config.data.app.env }}
    log-level: {{ $config.data.app.log_level }}
    feature-flags:
      enabled: {{ $config.data.app.feature_flags.enabled }}
      new-ui: {{ $config.data.app.feature_flags.new_ui }}
  {{- end }}

  {{- if or (not $enabled) (not (hasKey $enabled "server")) (eq $enabled.server true) }}
  # Server configuration
  server:
    port: 8080
    compression:
      enabled: true
    tomcat:
      threads:
        max: 200
        min-spare: 10
  {{- end }}
{{- end -}}
