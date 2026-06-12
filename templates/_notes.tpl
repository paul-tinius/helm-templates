{{/*
NOTES.txt helper - Generate service URL
*/}}
{{- define "notes.serviceUrl" -}}
{{- if .Values.service.type -}}
{{- if eq .Values.service.type "LoadBalancer" -}}
{{- printf "%s://%s" .Values.service.protocol (include "chart.fullname" .) -}}
{{- else if eq .Values.service.type "NodePort" -}}
{{- printf "%s://<NODE_IP>:<NODE_PORT>" .Values.service.protocol -}}
{{- else if eq .Values.service.type "ClusterIP" -}}
{{- printf "%s://%s.%s.svc.cluster.local:%d" .Values.service.protocol (include "chart.fullname" .) .Release.Namespace .Values.service.port -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
NOTES.txt helper - Get service port
*/}}
{{- define "notes.servicePort" -}}
{{- if .Values.service -}}
{{- .Values.service.port | default 80 -}}
{{- else -}}
{{- 80 -}}
{{- end -}}
{{- end }}

{{/*
NOTES.txt helper - Get service protocol
*/}}
{{- define "notes.serviceProtocol" -}}
{{- if .Values.service -}}
{{- .Values.service.protocol | default "http" -}}
{{- else -}}
{{- "http" -}}
{{- end -}}
{{- end }}

{{/*
NOTES.txt helper - Check if service is enabled
*/}}
{{- define "notes.serviceEnabled" -}}
{{- if .Values.service -}}
{{- .Values.service.enabled | default true -}}
{{- else -}}
{{- true -}}
{{- end -}}
{{- end }}

{{/*
NOTES.txt helper - Get ingress host
*/}}
{{- define "notes.ingressHost" -}}
{{- if .Values.ingress -}}
{{- if .Values.ingress.enabled -}}
{{- if .Values.ingress.hosts -}}
{{- index .Values.ingress.hosts 0 "host" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
NOTES.txt helper - Check if ingress is enabled
*/}}
{{- define "notes.ingressEnabled" -}}
{{- if .Values.ingress -}}
{{- .Values.ingress.enabled | default false -}}
{{- else -}}
{{- false -}}
{{- end -}}
{{- end }}

{{/*
NOTES.txt helper - Get secret name
*/}}
{{- define "notes.secretName" -}}
{{- if .Values.existingSecret -}}
{{- .Values.existingSecret -}}
{{- else -}}
{{- printf "%s-secret" (include "chart.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
NOTES.txt helper - Get configmap name
*/}}
{{- define "notes.configMapName" -}}
{{- if .Values.existingConfigMap -}}
{{- .Values.existingConfigMap -}}
{{- else -}}
{{- printf "%s-config" (include "chart.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
NOTES.txt helper - Get admin username from secret or values
*/}}
{{- define "notes.adminUsername" -}}
{{- if .Values.adminUsername -}}
{{- .Values.adminUsername -}}
{{- else -}}
{{- "admin" -}}
{{- end -}}
{{- end }}

{{/*
NOTES.txt helper - Generate credentials retrieval command
*/}}
{{- define "notes.getCredentials" -}}
{{- if .Values.existingSecret -}}
{{- printf "kubectl get secret %s -n %s -o jsonpath='{.data.%s}' | base64 --decode" (include "notes.secretName" .) .Release.Namespace .Values.secretKey -}}
{{- else -}}
{{- printf "kubectl get secret %s -n %s -o jsonpath='{.data.%s}' | base64 --decode" (include "notes.secretName" .) .Release.Namespace .Values.secretKey -}}
{{- end -}}
{{- end }}

{{/*
NOTES.txt helper - Generate pod status check command
*/}}
{{- define "notes.checkPodStatus" -}}
{{- printf "kubectl get pods -n %s -l app.kubernetes.io/name=%s,app.kubernetes.io/instance=%s" .Release.Namespace (include "chart.name" .) .Release.Name -}}
{{- end }}

{{/*
NOTES.txt helper - Generate service status check command
*/}}
{{- define "notes.checkServiceStatus" -}}
{{- printf "kubectl get svc -n %s -l app.kubernetes.io/name=%s,app.kubernetes.io/instance=%s" .Release.Namespace (include "chart.name" .) .Release.Name -}}
{{- end }}

{{/*
NOTES.txt helper - Generate logs command
*/}}
{{- define "notes.getLogs" -}}
{{- printf "kubectl logs -n %s -l app.kubernetes.io/name=%s,app.kubernetes.io/instance=%s --tail=100" .Release.Namespace (include "chart.name" .) .Release.Name -}}
{{- end }}

{{/*
NOTES.txt helper - Generate port-forward command
*/}}
{{- define "notes.portForward" -}}
{{- printf "kubectl port-forward -n %s svc/%s %d:%d" .Release.Namespace (include "chart.fullname" .) .Values.localPort (include "notes.servicePort" .) -}}
{{- end }}

{{/*
NOTES.txt helper - Generate uninstall command
*/}}
{{- define "notes.uninstall" -}}
{{- printf "helm uninstall %s -n %s" .Release.Name .Release.Namespace -}}
{{- end }}

{{/*
NOTES.txt helper - Generate upgrade command
*/}}
{{- define "notes.upgrade" -}}
{{- printf "helm upgrade %s . -n %s" .Release.Name .Release.Namespace -}}
{{- end }}

{{/*
NOTES.txt helper - Generate rollback command
*/}}
{{- define "notes.rollback" -}}
{{- printf "helm rollback %s -n %s" .Release.Name .Release.Namespace -}}
{{- end }}

{{/*
NOTES.txt helper - Conditional section rendering
*/}}
{{- define "notes.if" -}}
{{- if .condition -}}
{{- .content -}}
{{- end -}}
{{- end }}

{{/*
NOTES.txt helper - Render section with header
*/}}
{{- define "notes.section" -}}
{{- printf "\n%s\n%s\n" .title (repeat (len .title) "=") -}}
{{- end }}
