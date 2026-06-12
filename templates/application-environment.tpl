{{/*
application.environment.get retrieves the APP_ENVIRONMENT value.

Usage:
  {{- include "application.environment.get" . -}}

Inputs:
  .Values.environment.appEnvironment (optional): Custom APP_ENVIRONMENT value
  .Release.Namespace (optional): Falls back to namespace if not set

Outputs:
  String: The APP_ENVIRONMENT value (custom value, namespace, or "development" default)
*/}}
{{- define "application.environment.get" -}}
{{- if .Values.environment -}}
{{- if .Values.environment.appEnvironment -}}
{{- .Values.environment.appEnvironment -}}
{{- else -}}
{{- default "development" .Release.Namespace -}}
{{- end -}}
{{- else -}}
{{- default "development" .Release.Namespace -}}
{{- end -}}
{{- end }}

{{/*
application.environment.set generates an environment variable entry for APP_ENVIRONMENT.

Usage:
  {{- include "application.environment.set" . | nindent 8 -}}

Inputs:
  .Values.environment.appEnvironment (optional): Custom APP_ENVIRONMENT value
  .Release.Namespace (optional): Falls back to namespace if not set

Outputs:
  String: YAML environment variable entry in format "- name: APP_ENVIRONMENT\n  value: <value>"
*/}}
{{- define "application.environment.set" -}}
- name: APP_ENVIRONMENT
  value: {{ include "application.environment.get" . | quote }}
{{- end }}

{{/*
application.environment.configMap generates a ConfigMap entry for APP_ENVIRONMENT.

Usage:
  {{- include "application.environment.configMap" . | nindent 2 -}}

Inputs:
  .Values.environment.appEnvironment (optional): Custom APP_ENVIRONMENT value
  .Release.Namespace (optional): Falls back to namespace if not set

Outputs:
  String: YAML ConfigMap entry in format "APP_ENVIRONMENT: <value>"
*/}}
{{- define "application.environment.configMap" -}}
APP_ENVIRONMENT: {{ include "application.environment.get" . | quote }}
{{- end }}

{{/*
application.environment.secret generates a Secret entry for APP_ENVIRONMENT.

Usage:
  {{- include "application.environment.secret" . | nindent 2 -}}

Inputs:
  .Values.environment.appEnvironment (optional): Custom APP_ENVIRONMENT value
  .Release.Namespace (optional): Falls back to namespace if not set

Outputs:
  String: YAML Secret entry in format "APP_ENVIRONMENT: <base64-encoded-value>"
*/}}
{{- define "application.environment.secret" -}}
APP_ENVIRONMENT: {{ include "application.environment.get" . | b64enc }}
{{- end }}
