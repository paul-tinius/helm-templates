{{/*
Kubernetes Object Notes Library Chart Helpers - YAML output
*/}}

{{- define "notes.enabled" -}}
  {{- .Values.notes.enabled | default true -}}
{{- end -}}

{{- define "notes.sectionEnabled" -}}
  {{- $sectionKey := .key -}}
  {{- $defaultEnabled := .default | default false -}}
  {{- $enabled := false -}}
  {{- if and $.Values (hasKey $.Values "notes") $.Values.notes.enabled -}}
    {{- $enabled = true -}}
  {{- end -}}
  {{- if $enabled -}}
    {{- if hasKey $.Values.notes $sectionKey -}}
      {{- $enabled = index $.Values.notes $sectionKey -}}
    {{- else -}}
      {{- $enabled = $defaultEnabled -}}
    {{- end -}}
  {{- end -}}
  {{- $enabled -}}
{{- end -}}

{{- define "notes.common" -}}
  {{- if (include "notes.sectionEnabled" (dict "key" "includeCommon" "default" false "." $)) -}}
common:
  chart: {{ include "names.chart" . }}
  release: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
  version: {{ .Chart.AppVersion | default "N/A" }}
  revision: {{ .Release.Revision }}
  managedBy: {{ .Release.Service }}
  chartName: {{ .Chart.Name }}
  {{- end -}}
{{- end -}}

{{- define "notes.resources" -}}
  {{- if (include "notes.sectionEnabled" (dict "key" "includeResources" "default" false "." $)) -}}
resources:
  fullName: {{ include "names.fullName" . }}
  serviceAccount: {{ include "names.serviceAccountName" . }}
  hostname: {{ include "names.hostname" . }}
  {{- end -}}
{{- end -}}

{{- define "notes.networking" -}}
  {{- if (include "notes.sectionEnabled" (dict "key" "includeNetworking" "default" false "." $)) -}}
networking:
  {{- if .Values.service }}
  service:
    type: {{ .Values.service.type | default "ClusterIP" }}
    port: {{ .Values.service.port | default "N/A" }}
  {{- end }}
  {{- if .Values.ingress }}
  ingress:
    enabled: {{ .Values.ingress.enabled | default false }}
    {{- if .Values.ingress.hosts }}
    hosts:
      {{- range .Values.ingress.hosts }}
      - {{ if kindIs "map" . }}{{ .host }}{{ else }}{{ . }}{{ end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- end -}}
{{- end -}}

{{- define "notes.istio" -}}
  {{- if (include "notes.sectionEnabled" (dict "key" "includeIstio" "default" false "." $)) -}}
istio:
  {{- if or .Values.istio .Values.destinationrule }}
  destinationRule:
    enabled: {{ or .Values.istio.destinationRule.enabled .Values.destinationrule.enabled | default false }}
    {{- with .Values.istio.destinationRule.host }}
    host: {{ . }}
    {{- end }}
  {{- end }}
  {{- if or .Values.istio .Values.gateway }}
  gateway:
    enabled: {{ or .Values.istio.gateway.enabled .Values.gateway.enabled | default false }}
    {{- with .Values.istio.gateway.selector }}
    selector:
      {{- range $k, $v := . }}
      {{ $k }}: {{ $v }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if or .Values.istio .Values.virtualservice }}
  virtualService:
    enabled: {{ or .Values.istio.virtualService.enabled .Values.virtualservice.enabled | default false }}
    {{- with .Values.istio.virtualService.hosts }}
    hosts:
      {{- range . }}
      - {{ . }}
      {{- end }}
    {{- end }}
    {{- with .Values.istio.virtualService.gateways }}
    gateways:
      {{- range . }}
      - {{ . }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- end -}}
{{- end -}}

{{- define "notes.mattermost" -}}
  {{- if (include "notes.sectionEnabled" (dict "key" "includeMattermost" "default" false "." $)) -}}
  {{- if .Values.mattermost }}
mattermost:
  enabled: {{ .Values.mattermost.enabled | default false }}
  {{- if .Values.mattermost.enabled }}
  webhook: {{ .Values.mattermost.webhookUrl | default "" }}
  channel: {{ .Values.mattermost.channel | default "" }}
  username: {{ .Values.mattermost.username | default "Helm" }}
  iconUrl: {{ .Values.mattermost.iconUrl | default "" }}
  {{- end }}
  {{- end }}
  {{- end -}}
{{- end -}}

{{- define "notes.troubleshooting" -}}
  {{- if (include "notes.sectionEnabled" (dict "key" "includeTroubleshooting" "default" false "." $)) -}}
troubleshooting:
  commands:
    get pods: `kubectl get pods -n {{ .Release.Namespace }} -l app.kubernetes.io/name={{ .Chart.Name }}`
    logs: `kubectl logs -n {{ .Release.Namespace }} -l app.kubernetes.io/name={{ .Chart.Name }} --tail=100`
    describe deployment: `kubectl describe deployment -n {{ .Release.Namespace }} {{ include "names.fullName" . }}`
    describe service: `kubectl describe service -n {{ .Release.Namespace }} {{ include "names.fullName" . }}`
    events: `kubectl get events -n {{ .Release.Namespace }} --sort-by='.lastTimestamp'`
    port forward: `kubectl port-forward -n {{ .Release.Namespace }} svc/{{ include "names.fullName" . }} 8080:{{ if .Values.service }}{{ .Values.service.port | default "80" }}{{ else }}80{{ end }}`
    exec pod: `kubectl exec -n {{ .Release.Namespace }} -it $(kubectl get pod -n {{ .Release.Namespace }} -l app.kubernetes.io/name={{ .Chart.Name }} -o jsonpath='{.items[0].metadata.name}') -- sh`
    health check: `kubectl get pods -n {{ .Release.Namespace }} -l app.kubernetes.io/name={{ .Chart.Name }} -o jsonpath='{.items[*].status.phase}'`
  {{- end -}}
{{- end -}}

{{- define "notes.custom" -}}
  {{- if (include "notes.sectionEnabled" (dict "key" "includeCustom" "default" false "." $)) -}}
    {{- with .Values.notes.customNotes -}}
customNotes:
      {{- range $k, $v := . }}
      {{ $k }}: {{ tpl (toString $v) $ }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "notes.database" -}}
  {{- if (include "notes.sectionEnabled" (dict "key" "includeDatabase" "default" false "." $)) -}}
    {{- with .Values.database -}}
database:
  type: {{ .type | default "N/A" }}
  host: {{ .host | default "N/A" }}
  port: {{ .port | default "N/A" }}
  name: {{ .name | default "N/A" }}
  {{- if .existingSecret }}
  secret: {{ .existingSecret }}
  {{- end }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "notes.security" -}}
  {{- if (include "notes.sectionEnabled" (dict "key" "includeSecurity" "default" false "." $)) -}}
security:
  {{- if .Values.tls }}
  tls:
    enabled: {{ .Values.tls.enabled | default false }}
    {{- if .Values.tls.enabled }}
    secret: {{ .Values.tls.secret | default "N/A" }}
    {{- end }}
  {{- end }}
  {{- if .Values.serviceAccount }}
  serviceAccount:
    create: {{ .Values.serviceAccount.create | default true }}
    name: {{ include "names.serviceAccountName" . }}
  {{- end }}
  {{- if .Values.podSecurityContext }}
  podSecurityContext:
    {{- toYaml .Values.podSecurityContext | nindent 4 }}
  {{- else }}
  podSecurityContext: {}
  {{- end }}
  {{- end -}}
{{- end -}}

{{- define "notes.full" -}}
  {{- if (include "notes.enabled" .) -}}
---
{{ include "notes.common" . }}
{{ include "notes.resources" . }}
{{ include "notes.networking" . }}
{{ include "notes.istio" . }}
{{ include "notes.mattermost" . }}
{{ include "notes.troubleshooting" . }}
{{ include "notes.custom" . }}
{{ include "notes.database" . }}
{{ include "notes.security" . }}
labels:
{{- if .Values.global.labels }}
{{- range $k, $v := .Values.global.labels }}
  {{ $k }}: {{ $v }}
{{- end }}
{{- end }}
  helm.sh/chart: {{ include "names.chart" . }}
  app.kubernetes.io/name: {{ include "names.name" . }}
  app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
  app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
  {{- $annotations := include "annotations" . -}}
  {{- if $annotations -}}
annotations: {{ $annotations | nindent 2 }}
  {{- end -}}
  {{- end -}}
{{- end -}}