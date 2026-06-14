{{/*
Oracle Database Properties ConfigMap

This template renders a ConfigMap containing Oracle database connection properties
for multiple database instances.

Usage:
  include "dbProp.render" (dict "root" $ "databases" $Values.oracleDatabases)

Expected structure:
  oracleDatabases:
    - name: "primary"
      host: "oracle-primary.example.com"
      port: 1521
      service: "ORCLPDB1"
      username: "app_user"
      tnsAlias: "ORCL_PRIMARY"
      properties:
        connectionPool:
          minSize: 5
          maxSize: 20
          timeout: 30000
    - name: "standby"
      host: "oracle-standby.example.com"
      port: 1521
      service: "ORCLPDB2"
      username: "app_user"
      tnsAlias: "ORCL_STANDBY"
      properties:
        connectionPool:
          minSize: 3
          maxSize: 15
          timeout: 30000

Inputs:
  - .Chart.Name: The chart name
  - .Release.Name: The release name
  - .Release.Namespace: The release namespace
  - databases: List of Oracle database configurations

Outputs:
  - dbProp.render: Complete ConfigMap manifest with database properties
  - dbProp.getName: The ConfigMap name
  - dbProp.getFullName: The fully qualified ConfigMap name
  - dbProp.labels: YAML formatted labels
  - dbProp.data: YAML formatted data section with database properties
*/}}

{{/*
Render a ConfigMap with Oracle database properties

Parameters:
  - root: The root context (usually $)
  - databases: List of Oracle database configurations
  - name: Optional override for the configmap name

Returns:
  Complete ConfigMap manifest
*/}}
{{- define "dbProp.render" -}}
{{- $root := .root -}}
{{- $databases := .databases -}}
{{- $name := default "oracle-db-properties" .name -}}
{{- $fullName := include "dbProp.getFullName" (dict "root" $root "name" $name) -}}

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $fullName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "dbProp.labels" (dict "root" $root "name" $name) | nindent 4 }}
  annotations:
    {{- include "annotations" $root | nindent 4 }}
data:
  {{- include "dbProp.data" (dict "root" $root "databases" $databases) | nindent 2 }}
{{- end -}}

{{/*
Get the ConfigMap name

Parameters:
  - root: The root context (usually $)
  - name: The configmap name

Returns:
  The ConfigMap name
*/}}
{{- define "dbProp.getName" -}}
{{- default "oracle-db-properties" .name | include "name.truncateName" -}}
{{- end -}}

{{/*
Get the ConfigMap full name (with release prefix)

Parameters:
  - root: The root context (usually $)
  - name: The configmap name

Returns:
  The fully qualified ConfigMap name
*/}}
{{- define "dbProp.getFullName" -}}
{{- $root := .root -}}
{{- $name := default "oracle-db-properties" .name -}}
{{- if contains $name $root.Release.Name -}}
  {{- $root.Release.Name | include "name.truncateName" -}}
{{- else -}}
  {{- printf "%s-%s" $root.Release.Name $name | include "name.truncateName" -}}
{{- end -}}
{{- end -}}

{{/*
Generate standard labels for Database Properties ConfigMap

Parameters:
  - root: The root context (usually $)
  - name: The configmap name

Returns:
  YAML formatted labels
*/}}
{{- define "dbProp.labels" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $labels := dict -}}
{{- if $root.Values.global.labels -}}
  {{- range $k, $v := $root.Values.global.labels -}}
    {{- $labels = set $labels $k (tpl $v $root) -}}
  {{- end -}}
{{- end -}}
{{- $labels = set $labels "helm.sh/chart" (include "names.chart" $root) -}}
{{- $labels = set $labels "app.kubernetes.io/name" $root.Chart.Name -}}
{{- $labels = set $labels "app.kubernetes.io/component" "oracle-database-properties" -}}
{{- $labels = set $labels "app.kubernetes.io/instance" $root.Release.Name -}}
{{- if $root.Chart.AppVersion -}}
  {{- $labels = set $labels "app.kubernetes.io/version" $root.Chart.AppVersion -}}
{{- end -}}
{{- $labels = set $labels "app.kubernetes.io/managed-by" $root.Release.Service -}}
{{- toYaml $labels | nindent 0 -}}
{{- end -}}

{{/*
Generate ConfigMap data with Oracle database properties

Parameters:
  - root: The root context (usually $)
  - databases: List of Oracle database configurations

Returns:
  YAML formatted data section with database properties
*/}}
{{- define "dbProp.data" -}}
{{- $root := .root -}}
{{- $databases := .databases -}}
{{- range $db := $databases }}
  {{- $dbKey := printf "oracle.%s.properties" $db.name }}
{{ $dbKey }}: |
  # Oracle Database Configuration: {{ $db.name }}
  # TNS Alias: {{ $db.tnsAlias | default (printf "%s_%s" $db.name "DB") }}
  
  oracle.jdbc.url={{ $db.host }}:{{ $db.port }}/{{ $db.service }}
  oracle.jdbc.username={{ $db.username }}
  oracle.jdbc.service={{ $db.service }}
  oracle.jdbc.tnsAlias={{ $db.tnsAlias | default (printf "%s_%s" $db.name "DB") }}
  
  {{- if $db.properties }}
  {{- if $db.properties.connectionPool }}
  # Connection Pool Settings
  oracle.connectionPool.minSize={{ $db.properties.connectionPool.minSize | default 5 }}
  oracle.connectionPool.maxSize={{ $db.properties.connectionPool.maxSize | default 20 }}
  oracle.connectionPool.timeout={{ $db.properties.connectionPool.timeout | default 30000 }}
  {{- end }}
  {{- end }}
  
  {{- if $db.additionalProperties }}
  # Additional Properties
  {{- range $key, $value := $db.additionalProperties }}
  oracle.{{ $key }}={{ $value }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end -}}
