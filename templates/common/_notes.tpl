{{/*
Kubernetes Object Notes Library Chart Helpers - YAML output
*/}}

{{- define "notes.enabled" -}}
  {{- .Values.notes.enabled | default true -}}
{{- end -}}

{{- define "notes.common" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeCommon | default true -}}
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
{{- end -}}

{{- define "notes.resources" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeResources | default true -}}
resources:
  fullName: {{ include "names.fullName" . }}
  serviceAccount: {{ include "names.serviceAccountName" . }}
  hostname: {{ include "names.hostname" . }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "notes.networking" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeNetworking | default true -}}
networking:
  service:
    type: {{ .Values.service.type | default "ClusterIP" }}
    port: {{ .Values.service.port | default "N/A" }}
  ingress:
    enabled: {{ .Values.ingress.enabled | default false }}
    {{- if .Values.ingress.hosts }}
    hosts:
      {{- range .Values.ingress.hosts }}
      - {{ if kindIs "map" . }}{{ .host }}{{ else }}{{ . }}{{ end }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "notes.istio" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeIstio | default true -}}
istio:
  destinationRule:
    enabled: {{ or .Values.istio.destinationRule.enabled .Values.destinationrule.enabled | default false }}
    {{- with .Values.istio.destinationRule.host }}
    host: {{ . }}
    {{- end }}
  gateway:
    enabled: {{ or .Values.istio.gateway.enabled .Values.gateway.enabled | default false }}
    {{- with .Values.istio.gateway.selector }}
    selector:
      {{- range $k, $v := . }}
      {{ $k }}: {{ $v }}
      {{- end }}
    {{- end }}
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
  {{- end }}
{{- end }}

{{- define "notes.mattermost" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeMattermost | default true -}}
mattermost:
  enabled: {{ .Values.mattermost.enabled | default false }}
  {{- if .Values.mattermost.enabled }}
  webhook: {{ .Values.mattermost.webhookUrl | default "" }}
  channel: {{ .Values.mattermost.channel | default "" }}
  username: {{ .Values.mattermost.username | default "Helm" }}
  iconUrl: {{ .Values.mattermost.iconUrl | default "" }}
  {{- end }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "notes.troubleshooting" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeTroubleshooting | default true -}}
troubleshooting:
  commands:
    get pods: `kubectl get pods -n {{ .Release.Namespace }} -l app.kubernetes.io/name={{ .Chart.Name }}`
    logs: `kubectl logs -n {{ .Release.Namespace }} -l app.kubernetes.io/name={{ .Chart.Name }} --tail=100`
    describe deployment: `kubectl describe deployment -n {{ .Release.Namespace }} {{ include "names.fullName" . }}`
    describe service: `kubectl describe service -n {{ .Release.Namespace }} {{ include "names.fullName" . }}`
    events: `kubectl get events -n {{ .Release.Namespace }} --sort-by='.lastTimestamp'`
    port forward: `kubectl port-forward -n {{ .Release.Namespace }} svc/{{ include "names.fullName" . }} 8080:{{ .Values.service.port | default "80" }}`
    exec pod: `kubectl exec -n {{ .Release.Namespace }} -it $(kubectl get pod -n {{ .Release.Namespace }} -l app.kubernetes.io/name={{ .Chart.Name }} -o jsonpath='{.items[0].metadata.name}') -- sh`
    health check: `kubectl get pods -n {{ .Release.Namespace }} -l app.kubernetes.io/name={{ .Chart.Name }} -o jsonpath='{.items[*].status.phase}'`
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "notes.custom" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- with .Values.notes.customNotes -}}
customNotes:
      {{- range $k, $v := . }}
  {{ $k }}: {{ tpl (toString $v) $ }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "notes.database" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeDatabase | default false -}}
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
{{- end -}}

{{- define "notes.security" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeSecurity | default false -}}
security:
  tls:
    enabled: {{ .Values.tls.enabled | default false }}
    {{- if .Values.tls.enabled }}
    secret: {{ .Values.tls.secret | default "N/A" }}
    {{- end }}
  serviceAccount:
    create: {{ .Values.serviceAccount.create | default true }}
    name: {{ include "names.serviceAccountName" . }}
  podSecurityContext:
    {{- with .Values.podSecurityContext }}
    {{- toYaml . | nindent 4 }}
    {{- else }}
    {}
    {{- end }}
    {{- end -}}
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
{{- if .Values.notes.includeDatabase | default false -}}
{{ include "notes.database" . }}
{{- end }}
{{- if .Values.notes.includeSecurity | default false -}}
{{ include "notes.security" . }}
{{- end }}
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