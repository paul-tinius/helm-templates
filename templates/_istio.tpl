{{/*
istio.gateway creates an Istio Gateway resource.

Usage:
  {{- include "istio.gateway" . -}}

Inputs:
  .Values.istio.gateway.enabled (optional): Boolean to enable/disable gateway (default: true)
  .Values.istio.gateway.name (optional): Custom gateway name
  .Values.istio.gateway.selector (optional): Gateway selector labels (default: istio: ingressgateway)
  .Values.istio.gateway.servers (optional): List of server configurations
  .Chart.Name: Chart name from Helm context
  .Release.Name: Release name from Helm context
  .Values.nameOverride (optional): Override for the chart name
  .Values.fullnameOverride (optional): Override for the full release name

Outputs:
  Gateway Kubernetes manifest with:
  - Name: {fullname}-gateway or custom name
  - Labels: Standard chart labels
  - Selector: istio ingressgateway (or custom)
  - Servers: Configured servers (or default HTTP on port 80)
*/}}
{{- define "istio.gateway" -}}
{{- if .Values.istio.gateway.enabled -}}
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: {{ default (printf "%s-gateway" (include "helper.fullname" .)) .Values.istio.gateway.name }}
  labels:
    {{- include "helper.labels" . | nindent 4 }}
spec:
  selector:
    {{- toYaml (default (dict "istio" "ingressgateway") .Values.istio.gateway.selector) | nindent 4 }}
  servers:
  {{- if .Values.istio.gateway.servers }}
  {{- toYaml .Values.istio.gateway.servers | nindent 2 }}
  {{- else }}
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
  {{- end }}
{{- end }}
{{- end }}

{{/*
istio.virtualService creates an Istio VirtualService resource.

Usage:
  {{- include "istio.virtualService" . -}}

Inputs:
  .Values.istio.virtualService.enabled (optional): Boolean to enable/disable virtual service (default: true)
  .Values.istio.virtualService.name (optional): Custom virtual service name
  .Values.istio.virtualService.hosts (optional): List of hosts
  .Values.istio.virtualService.gateways (optional): List of gateway names
  .Values.istio.virtualService.http (optional): List of HTTP route configurations
  .Values.istio.virtualService.tls (optional): List of TLS route configurations
  .Values.istio.virtualService.tcp (optional): List of TCP route configurations
  .Chart.Name: Chart name from Helm context
  .Release.Name: Release name from Helm context
  .Values.nameOverride (optional): Override for the chart name
  .Values.fullnameOverride (optional): Override for the full release name

Outputs:
  VirtualService Kubernetes manifest with:
  - Name: {fullname}-virtualservice or custom name
  - Labels: Standard chart labels
  - Hosts: Configured hosts (or wildcard)
  - Gateways: Configured gateways (or default gateway)
  - HTTP/TLS/TCP routes: Configured routes (or default route to service)
*/}}
{{- define "istio.virtualService" -}}
{{- if .Values.istio.virtualService.enabled -}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: {{ default (printf "%s-virtualservice" (include "helper.fullname" .)) .Values.istio.virtualService.name }}
  labels:
    {{- include "helper.labels" . | nindent 4 }}
spec:
  hosts:
  {{- if .Values.istio.virtualService.hosts }}
  {{- toYaml .Values.istio.virtualService.hosts | nindent 2 }}
  {{- else }}
  - "*"
  {{- end }}
  gateways:
  {{- if .Values.istio.virtualService.gateways }}
  {{- toYaml .Values.istio.virtualService.gateways | nindent 2 }}
  {{- else }}
  - {{ printf "%s-gateway" (include "helper.fullname" .) }}
  {{- end }}
  {{- if .Values.istio.virtualService.http }}
  http:
  {{- toYaml .Values.istio.virtualService.http | nindent 2 }}
  {{- else if .Values.istio.virtualService.tls }}
  tls:
  {{- toYaml .Values.istio.virtualService.tls | nindent 2 }}
  {{- else if .Values.istio.virtualService.tcp }}
  tcp:
  {{- toYaml .Values.istio.virtualService.tcp | nindent 2 }}
  {{- else }}
  http:
  - match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: {{ include "helper.hostname" . }}
        port:
          number: {{ default 80 .Values.service.port }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
istio.destinationRule creates an Istio DestinationRule resource.

Usage:
  {{- include "istio.destinationRule" . -}}

Inputs:
  .Values.istio.destinationRule.enabled (optional): Boolean to enable/disable destination rule (default: true)
  .Values.istio.destinationRule.name (optional): Custom destination rule name
  .Values.istio.destinationRule.host (optional): Destination host
  .Values.istio.destinationRule.subsets (optional): List of subset configurations
  .Values.istio.destinationRule.trafficPolicy (optional): Traffic policy configuration
  .Chart.Name: Chart name from Helm context
  .Release.Name: Release name from Helm context
  .Values.nameOverride (optional): Override for the chart name
  .Values.fullnameOverride (optional): Override for the full release name

Outputs:
  DestinationRule Kubernetes manifest with:
  - Name: {fullname}-destinationrule or custom name
  - Labels: Standard chart labels
  - Host: Destination host (or chart hostname)
  - Subsets: Configured subsets (if provided)
  - TrafficPolicy: Configured traffic policy (if provided)
*/}}
{{- define "istio.destinationRule" -}}
{{- if .Values.istio.destinationRule.enabled -}}
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: {{ default (printf "%s-destinationrule" (include "helper.fullname" .)) .Values.istio.destinationRule.name }}
  labels:
    {{- include "helper.labels" . | nindent 4 }}
spec:
  host: {{ default (include "helper.hostname" .) .Values.istio.destinationRule.host }}
  {{- if .Values.istio.destinationRule.subsets }}
  subsets:
  {{- toYaml .Values.istio.destinationRule.subsets | nindent 2 }}
  {{- end }}
  {{- if .Values.istio.destinationRule.trafficPolicy }}
  trafficPolicy:
  {{- toYaml .Values.istio.destinationRule.trafficPolicy | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
istio.render renders a specific istio template.

Usage:
  {{- include "istio.render" (dict "name" "gateway" "context" $) -}}
  {{- include "istio.render" (dict "name" "virtualService" "context" $) -}}
  {{- include "istio.render" (dict "name" "destinationRule" "context" $) -}}

Inputs:
  .name: The template name to render (gateway, virtualService, destinationRule)
  .context: The context to pass to the template

Outputs:
  String: The rendered template output
*/}}
{{- define "istio.render" -}}
{{- if eq .name "gateway" -}}
{{- include "istio.gateway" .context -}}
{{- else if eq .name "virtualService" -}}
{{- include "istio.virtualService" .context -}}
{{- else if eq .name "destinationRule" -}}
{{- include "istio.destinationRule" .context -}}
{{- end -}}
{{- end }}
