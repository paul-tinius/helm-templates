{{/*
Kubernetes Object Notes Library Chart Helpers

This library provides reusable templates for generating Kubernetes object notes.
These notes provide deployment metadata and useful information about the created resources,
typically used in ConfigMaps, pod annotations, or documentation purposes.

Usage:
  include "notes.deployment" .
  include "notes.pod" .
  include "notes.service" .
  include "notes.configMap" .
  include "notes.secret" .
  include "notes.full" .
  include "notes.mattermostWebhookPayload" .

Expected structure:
  notes:
    enabled: true                          # Optional: enable/disable notes generation (default: true)
    includeCommon: true                    # Optional: include common metadata (default: true)
    includeResources: true                # Optional: include resource information (default: true)
    includeNetworking: true                # Optional: include networking information (default: true)
    includeIstio: true                     # Optional: include Istio information (default: true)
    includeMattermost: true                # Optional: include Mattermost information (default: true)
    includeTroubleshooting: true           # Optional: include troubleshooting information (default: true)
    customNotes:                          # Optional: custom notes to include
      key1: "value1"
      key2: "{{ .Release.Name }}-value"
  service:
    type: "ClusterIP"                      # Optional: service type
    port: 80                               # Optional: service port
  ingress:
    enabled: true                          # Optional: ingress enabled
    hosts: ["example.com"]                 # Optional: ingress hosts
  destinationrule:
    enabled: true                          # Optional: DestinationRule enabled
    host: "my-service.default.svc.cluster.local"  # DestinationRule host
  gateway:
    enabled: true                          # Optional: Gateway enabled
    selector:
      istio: ingressgateway               # Gateway selector
  virtualservice:
    enabled: true                          # Optional: VirtualService enabled
    hosts: ["example.com"]                 # VirtualService hosts
    gateways: ["my-gateway"]              # VirtualService gateways
  mattermost:
    enabled: true                          # Optional: Mattermost enabled
    webhookUrl: "https://mattermost.example.com/hooks/..."  # Mattermost webhook URL
    channel: "deployments"                 # Optional: Mattermost channel
    username: "Helm"                       # Optional: Mattermost username (default: Helm)
    iconUrl: "https://example.com/icon.png"  # Optional: Mattermost icon URL

Inputs:
  - .Chart.Name: The chart name
  - .Chart.Version: The chart version
  - .Chart.AppVersion: The app version (optional)
  - .Release.Name: The release name
  - .Release.Namespace: The release namespace
  - .Release.Service: The release service (typically Helm)
  - .Release.Revision: The release revision number
  - .Values.notes.enabled: Enable/disable notes generation
  - .Values.notes.includeCommon: Include common metadata
  - .Values.notes.includeResources: Include resource information
  - .Values.notes.includeNetworking: Include networking information
  - .Values.notes.includeIstio: Include Istio information
  - .Values.notes.includeMattermost: Include Mattermost information
  - .Values.notes.includeTroubleshooting: Include troubleshooting information
  - .Values.notes.customNotes: Map of custom notes (supports template rendering)
  - .Values.service.type: Service type
  - .Values.service.port: Service port
  - .Values.ingress.enabled: Ingress enabled flag
  - .Values.ingress.hosts: Ingress host list
  - .Values.destinationrule.enabled: DestinationRule enabled flag
  - .Values.destinationrule.host: DestinationRule host
  - .Values.gateway.enabled: Gateway enabled flag
  - .Values.gateway.selector: Gateway selector
  - .Values.virtualservice.enabled: VirtualService enabled flag
  - .Values.virtualservice.hosts: VirtualService host list
  - .Values.virtualservice.gateways: VirtualService gateway list
  - .Values.mattermost.enabled: Mattermost enabled flag
  - .Values.mattermost.webhookUrl: Mattermost webhook URL
  - .Values.mattermost.channel: Mattermost channel
  - .Values.mattermost.username: Mattermost username
  - .Values.mattermost.iconUrl: Mattermost icon URL

Outputs:
  - notes.common: Common metadata notes (chart, release, labels)
  - notes.resources: Resource information notes (name, namespace, service account)
  - notes.networking: Networking information notes (service, ingress)
  - notes.istio: Istio information notes (DestinationRule, Gateway, VirtualService)
  - notes.mattermost: Mattermost information notes (webhook, channel, username)
  - notes.mattermostWebhookPayload: JSON payload for Mattermost webhook with rendered NOTES.txt
  - notes.troubleshooting: Troubleshooting information notes (commands, tips)
  - notes.custom: Custom notes from values
  - notes.deployment: Full deployment notes (common + resources + networking + istio + mattermost + troubleshooting)
  - notes.pod: Pod-specific notes (common + resources)
  - notes.service: Service-specific notes (common + networking)
  - notes.configMap: ConfigMap-specific notes (common + resources)
  - notes.secret: Secret-specific notes (common + resources)
  - notes.full: Complete notes including all sections
*/}}

{{/* Check if notes are enabled */}}
{{- define "notes.enabled" -}}
  {{- if not (hasKey .Values.notes "enabled") -}}
    {{- true -}}
  {{- else -}}
    {{- .Values.notes.enabled -}}
  {{- end -}}
{{- end -}}

{{/* Generate common metadata notes */}}
{{- define "notes.common" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeCommon | default true -}}
Chart: {{ include "names.chart" . }}
Release: {{ .Release.Name }}
Namespace: {{ .Release.Namespace }}
Version: {{ .Chart.AppVersion | default "N/A" }}
Revision: {{ .Release.Revision }}
Managed by: {{ .Release.Service }}
Chart Name: {{ .Chart.Name }}
{{- end -}}
  {{- end -}}
{{- end -}}

{{/* Generate resource information notes */}}
{{- define "notes.resources" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeResources | default true -}}
Full Name: {{ include "names.fullName" . }}
Service Account: {{ include "names.serviceAccountName" . }}
Hostname: {{ include "names.hostname" . }}
{{- end -}}
  {{- end -}}
{{- end -}}

{{/* Generate networking information notes */}}
{{- define "notes.networking" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeNetworking | default true -}}
Service Type: {{ .Values.service.type | default "ClusterIP" }}
Service Port: {{ .Values.service.port | default "N/A" }}

{{- if .Values.ingress.enabled -}}
Ingress Enabled: true
{{- if .Values.ingress.hosts -}}
Ingress Hosts:
{{- range .Values.ingress.hosts }}
  - {{ .host }}
{{- end -}}
{{- end -}}
{{- else -}}
Ingress Enabled: false
{{- end -}}
{{- end -}}
  {{- end -}}
{{- end -}}

{{/* Generate Istio information notes */}}
{{- define "notes.istio" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeIstio | default true -}}
{{- $drEnabled := false -}}
{{- $drHost := "" -}}
{{- if .Values.istio.destinationRule.enabled -}}
  {{- $drEnabled = true -}}
  {{- $drHost = .Values.istio.destinationRule.host -}}
{{- else if .Values.destinationrule.enabled -}}
  {{- $drEnabled = true -}}
  {{- $drHost = .Values.destinationrule.host -}}
{{- end -}}
{{- if $drEnabled -}}
DestinationRule Enabled: true
{{- if $drHost -}}
DestinationRule Host: {{ $drHost }}
{{- end -}}
{{- else -}}
DestinationRule Enabled: false
{{- end -}}

{{- $gwEnabled := false -}}
{{- $gwSelector := dict -}}
{{- if .Values.istio.gateway.enabled -}}
  {{- $gwEnabled = true -}}
  {{- $gwSelector = .Values.istio.gateway.selector -}}
{{- else if .Values.gateway.enabled -}}
  {{- $gwEnabled = true -}}
  {{- $gwSelector = .Values.gateway.selector -}}
{{- end -}}
{{- if $gwEnabled -}}
Gateway Enabled: true
{{- if $gwSelector -}}
Gateway Selector:
{{- range $k, $v := $gwSelector }}
  {{ $k }}: {{ $v }}
{{- end -}}
{{- end -}}
{{- else -}}
Gateway Enabled: false
{{- end -}}

{{- $vsEnabled := false -}}
{{- $vsHosts := list -}}
{{- $vsGateways := list -}}
{{- if .Values.istio.virtualService.enabled -}}
  {{- $vsEnabled = true -}}
  {{- $vsHosts = .Values.istio.virtualService.hosts -}}
  {{- $vsGateways = .Values.istio.virtualService.gateways -}}
{{- else if .Values.virtualservice.enabled -}}
  {{- $vsEnabled = true -}}
  {{- $vsHosts = .Values.virtualservice.hosts -}}
  {{- $vsGateways = .Values.virtualservice.gateways -}}
{{- end -}}
{{- if $vsEnabled -}}
VirtualService Enabled: true
{{- if $vsHosts -}}
VirtualService Hosts:
{{- range $vsHosts }}
  - {{ . }}
{{- end -}}
{{- end -}}
{{- if $vsGateways -}}
VirtualService Gateways:
{{- range $vsGateways }}
  - {{ . }}
{{- end -}}
{{- end -}}
{{- else -}}
VirtualService Enabled: false
{{- end -}}

{{- end -}}
  {{- end -}}
{{- end -}}

{{/* Generate Mattermost information notes */}}
{{- define "notes.mattermost" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeMattermost | default true -}}
{{- $mmEnabled := false -}}
{{- $mmWebhookUrl := "" -}}
{{- $mmChannel := "" -}}
{{- $mmUsername := "" -}}
{{- $mmIconUrl := "" -}}
{{- if .Values.mattermost.enabled -}}
  {{- $mmEnabled = true -}}
  {{- $mmWebhookUrl = .Values.mattermost.webhookUrl -}}
  {{- $mmChannel = .Values.mattermost.channel -}}
  {{- $mmUsername = .Values.mattermost.username | default "Helm" -}}
  {{- $mmIconUrl = .Values.mattermost.iconUrl -}}
{{- end -}}
{{- if $mmEnabled -}}
Mattermost Enabled: true
{{- if $mmWebhookUrl -}}
Mattermost Webhook: {{ $mmWebhookUrl }}
{{- end -}}
{{- if $mmChannel -}}
Mattermost Channel: {{ $mmChannel }}
{{- end -}}
{{- if $mmUsername -}}
Mattermost Username: {{ $mmUsername }}
{{- end -}}
{{- if $mmIconUrl -}}
Mattermost Icon URL: {{ $mmIconUrl }}
{{- end -}}
{{- else -}}
Mattermost Enabled: false
{{- end -}}
{{- end -}}
  {{- end -}}
{{- end -}}

{{/* Generate Mattermost webhook payload for sending NOTES.txt */}}
{{- define "notes.mattermostWebhookPayload" -}}
{{- if .Values.mattermost.enabled -}}
{{- $notes := include "notes.full" . -}}
{
  "channel": "{{ .Values.mattermost.channel }}",
  "username": "{{ .Values.mattermost.username | default "Helm" }}",
  "icon_url": "{{ .Values.mattermost.iconUrl }}",
  "text": "### Helm Release: {{ .Release.Name }}\n\n**Chart:** {{ include "names.chart" . }}\n**Namespace:** {{ .Release.Namespace }}\n**Revision:** {{ .Release.Revision }}\n\n```{{ $notes }}```"
}
{{- end -}}
{{- end -}}

{{/* Generate troubleshooting information notes */}}
{{- define "notes.troubleshooting" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- if .Values.notes.includeTroubleshooting | default true -}}
=== Troubleshooting Commands ===

# Get pod status
kubectl get pods -n {{ .Release.Namespace }} -l app.kubernetes.io/name={{ .Chart.Name }}

# View pod logs
kubectl logs -n {{ .Release.Namespace }} -l app.kubernetes.io/name={{ .Chart.Name }} --tail=100

# Describe deployment
kubectl describe deployment -n {{ .Release.Namespace }} {{ include "names.fullName" . }}

# Describe service
kubectl describe service -n {{ .Release.Namespace }} {{ include "names.fullName" . }}

# Check events
kubectl get events -n {{ .Release.Namespace }} --sort-by='.lastTimestamp'

# Port-forward to service
kubectl port-forward -n {{ .Release.Namespace }} svc/{{ include "names.fullName" . }} 8080:{{ .Values.service.port | default "80" }}

# Exec into pod
kubectl exec -n {{ .Release.Namespace }} -it $(kubectl get pod -n {{ .Release.Namespace }} -l app.kubernetes.io/name={{ .Chart.Name }} -o jsonpath='{.items[0].metadata.name}') -- sh

# Common Issues:
# - Pod not starting: Check logs and describe pod for events
# - Service unreachable: Verify service endpoints and pod labels
# - Ingress not working: Check ingress controller and DNS configuration
# - Istio routing issues: Verify VirtualService and DestinationRule configurations
{{- end -}}
  {{- end -}}
{{- end -}}

{{/* Generate custom notes from values */}}
{{- define "notes.custom" -}}
  {{- if (include "notes.enabled" .) -}}
    {{- with .Values.notes.customNotes -}}
      {{- range $k, $v := . }}
{{ $k }}: {{ tpl $v $ }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Generate full deployment notes */}}
{{- define "notes.deployment" -}}
  {{- if (include "notes.enabled" .) -}}
{{ include "notes.common" . }}
{{ include "notes.resources" . }}
{{ include "notes.networking" . }}
{{ include "notes.istio" . }}
{{ include "notes.mattermost" . }}
{{ include "notes.troubleshooting" . }}
{{ include "notes.custom" . }}
  {{- end -}}
{{- end -}}

{{/* Generate pod-specific notes */}}
{{- define "notes.pod" -}}
  {{- if (include "notes.enabled" .) -}}
{{ include "notes.common" . }}
{{ include "notes.resources" . }}
{{ include "notes.custom" . }}
  {{- end -}}
{{- end -}}

{{/* Generate service-specific notes */}}
{{- define "notes.service" -}}
  {{- if (include "notes.enabled" .) -}}
{{ include "notes.common" . }}
{{ include "notes.networking" . }}
{{ include "notes.custom" . }}
  {{- end -}}
{{- end -}}

{{/* Generate ConfigMap-specific notes */}}
{{- define "notes.configMap" -}}
  {{- if (include "notes.enabled" .) -}}
{{ include "notes.common" . }}
{{ include "notes.resources" . }}
{{ include "notes.custom" . }}
  {{- end -}}
{{- end -}}

{{/* Generate Secret-specific notes */}}
{{- define "notes.secret" -}}
  {{- if (include "notes.enabled" .) -}}
{{ include "notes.common" . }}
{{ include "notes.resources" . }}
{{ include "notes.custom" . }}
  {{- end -}}
{{- end -}}

{{/* Generate complete notes including all sections with labels */}}
{{- define "notes.full" -}}
  {{- if (include "notes.enabled" .) -}}
=== Deployment Metadata ===
{{ include "notes.common" . }}

=== Resource Information ===
{{ include "notes.resources" . }}

=== Networking Information ===
{{ include "notes.networking" . }}

=== Istio Information ===
{{ include "notes.istio" . }}

=== Mattermost Information ===
{{ include "notes.mattermost" . }}

=== Troubleshooting ===
{{ include "notes.troubleshooting" . }}

=== Custom Notes ===
{{ include "notes.custom" . }}

=== Labels ===
{{- if .Values.global.labels -}}
{{- range $k, $v := .Values.global.labels -}}
{{ $k }}: {{ $v }}
{{- end -}}
{{- end -}}
helm.sh/chart: {{ include "names.chart" . }}
app.kubernetes.io/name: {{ include "names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion -}}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}



=== Annotations ===
{{ include "annotations" . }}
  {{- end -}}
{{- end -}}
