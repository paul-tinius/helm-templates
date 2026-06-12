{{/*
Names Library Chart Helpers

This library provides reusable templates for generating Kubernetes resource names.
It supports name truncation, overrides, and service account naming conventions.

Usage:
  include "names.chart" .
  include "names.fullName" .
  include "names.name" .
  include "names.serviceAccountName" .
  include "names.hostname" .
  include "names.fullQualifiedHostname" .
  include "name.truncateName" "my-name"
  include "name.getNameOverride" .
  include "name.getFullNameOverride" .

Expected structure:
  nameOverride: "my-name"                 # Optional: override the chart name
  fullnameOverride: "my-full-name"       # Optional: override the full name
  global:
    nameOverride: "global-name"           # Optional: global name override
    fullnameOverride: "global-full-name"  # Optional: global full name override
  serviceAccount:
    create: true                          # Optional: create a service account
    name: "my-service-account"            # Optional: service account name

Inputs:
  - .Chart.Name: The chart name
  - .Chart.Version: The chart version
  - .Release.Name: The release name
  - .Values.nameOverride: Local override for the chart name
  - .Values.fullnameOverride: Local override for the full name
  - .Values.global.nameOverride: Global override for the chart name
  - .Values.global.fullnameOverride: Global override for the full name
  - .Values.serviceAccount.create: Whether to create a service account
  - .Values.serviceAccount.name: Service account name override

Outputs:
  - names.chart: Chart name and version (truncated to 63 chars)
  - names.fullName: Fully qualified app name (truncated to 63 chars)
  - names.name: Chart name (truncated to 63 chars)
  - names.serviceAccountName: Service account name
  - names.hostname: Short hostname (uses fullName)
  - names.fullQualifiedHostname: Fully qualified hostname (Chart.Name.Release.Namespace.svc.cluster.local)
  - name.truncateName: Truncated name (max 63 chars, trailing dash removed)
  - name.getNameOverride: Appropriate nameOverride value (local or global)
  - name.getFullNameOverride: Appropriate fullnameOverride value (local or global)
*/}}

{{/* Create chart name and version as used by the chart label */}}
{{- define "names.chart" -}}
    {{- $name := printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
    {{- include "name.truncateName" $name -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "names.fullName" -}}
    {{- $name := include "names.name" . -}}
    {{- $fullNameOverride := include "name.getFullNameOverride" . -}}
    {{- if $fullNameOverride -}}
        {{- $name = $fullNameOverride -}}
    {{- else if contains $name .Release.Name -}}
        {{- $name = .Release.Name -}}
    {{- else -}}
        {{- $name = printf "%s-%s" .Release.Name $name -}}
    {{- end -}}
    {{- include "name.truncateName" $name -}}
{{- end -}}

{{/* Expand the name of the chart */}}
{{- define "names.name" -}}
    {{- $nameOverride := include "name.getNameOverride" . -}}
    {{- default .Chart.Name $nameOverride | include "name.truncateName" -}}
{{- end -}}

{{/* Create the name of the ServiceAccount to use */}}
{{- define "names.serviceAccountName" -}}
    {{- if .Values.serviceAccount.create -}}
        {{- default (include "names.fullName" .) .Values.serviceAccount.name -}}
    {{- else -}}
        {{- default "default" .Values.serviceAccount.name -}}
    {{- end -}}
{{- end -}}

{{/* Create short hostname (uses fullName) */}}
{{- define "names.hostname" -}}
    {{- include "names.fullName" . -}}
{{- end -}}

{{/* Create fully qualified hostname (Chart.Name.Release.Namespace.svc.cluster.local) */}}
{{- define "names.fullQualifiedHostname" -}}
    {{- printf "%s.%s.%s.svc.cluster.local" (include "names.fullName" .) .Release.Name .Release.Namespace -}}
{{- end -}}

{{/* Helper: Truncate name to 63 chars and trim trailing dash */}}
{{- define "name.truncateName" -}}
    {{- . | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Helper: Get the appropriate nameOverride value (local or global) */}}
{{- define "name.getNameOverride" -}}
    {{- if .Values -}}
        {{- if hasKey .Values "global" -}}
            {{- default .Values.nameOverride .Values.global.nameOverride -}}
        {{- else -}}
            {{- .Values.nameOverride -}}
        {{- end -}}
    {{- end -}}
{{- end -}}

{{/* Helper: Get the appropriate fullnameOverride value (local or global) */}}
{{- define "name.getFullNameOverride" -}}
    {{- $globalOverride := "" -}}
    {{- if .Values -}}
        {{- if hasKey .Values "global" -}}
            {{- $globalOverride = .Values.global.fullnameOverride -}}
        {{- end -}}
        {{- default .Values.fullnameOverride $globalOverride -}}
    {{- end -}}
{{- end -}}