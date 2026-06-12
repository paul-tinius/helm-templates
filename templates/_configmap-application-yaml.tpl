{{/*
Create a ConfigMap for Spring Boot application YAML with refresh support
*/}}
{{- define "chart.configmapApplication" -}}
{{- $configMapName := include "chart.fullname" . -}}
{{- $appName := include "chart.name" . -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $configMapName }}-application
  labels:
    {{- include "chart.labels" . | nindent 4 }}
data:
  application.yaml: |
    {{- if .Values.applicationConfig }}
    {{- .Values.applicationConfig | nindent 4 }}
    {{- else }}
    spring:
      application:
        name: {{ $appName }}
      config:
        import: optional:configmap:{{ $configMapName }}-application
    {{- end }}
{{- end }}

{{/*
Create volume definition for application ConfigMap
*/}}
{{- define "chart.configmapVolume" -}}
{{- $configMapName := include "chart.fullname" . -}}
- name: application-config
  configMap:
    name: {{ $configMapName }}-application
    items:
      - key: application.yaml
        path: application.yaml
{{- end }}

{{/*
Create volume mount definition for application ConfigMap
*/}}
{{- define "chart.configmapVolumeMount" -}}
- name: application-config
  mountPath: /config/application.yaml
  subPath: application.yaml
{{- end }}

{{/*
Create Spring Boot environment variables for ConfigMap refresh
*/}}
{{- define "chart.configmapEnvVars" -}}
- name: SPRING_CONFIG_IMPORT
  value: "optional:configmap:{{ include "chart.fullname" . }}-application"
- name: SPRING_CLOUD_CONFIG_ENABLED
  value: "false"
- name: SPRING_CLOUD_KUBERNETES_CONFIG_ENABLED
  value: "true"
- name: SPRING_CLOUD_KUBERNETES_CONFIG_NAME
  value: {{ include "chart.fullname" . }}-application
- name: SPRING_CLOUD_KUBERNETES_CONFIG_PATHS
  value: /config
- name: SPRING_CLOUD_KUBERNETES_RELOAD_ENABLED
  value: "true"
{{- end }}
