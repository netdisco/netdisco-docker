{{/*
Expand the name of the chart.
*/}}
{{- define "netdisco.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "netdisco.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "netdisco.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "netdisco.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "netdisco.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "netdisco.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "netdisco.selectorLabels" -}}
app.kubernetes.io/name: {{ include "netdisco.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Database host: bundled postgresql service or external */}}
{{- define "netdisco.dbHost" -}}
{{- if .Values.postgresql.enabled -}}
{{ include "netdisco.fullname" . }}-postgresql
{{- else -}}
{{ required "db.host is required when postgresql.enabled is false" .Values.db.host }}
{{- end }}
{{- end }}

{{/* Security context — drop runAsUser on OpenShift */}}
{{- define "netdisco.securityContext" -}}
runAsNonRoot: true
{{- if not .Values.openshift }}
runAsUser: {{ .Values.securityContext.runAsUser }}
runAsGroup: {{ .Values.securityContext.runAsGroup }}
fsGroup: {{ .Values.securityContext.fsGroup }}
{{- end }}
{{- end }}

{{/* Common env vars for all netdisco containers */}}
{{- define "netdisco.env" -}}
- name: NETDISCO_DOMAIN
  value: {{ .Values.netdisco.domain | quote }}
- name: NETDISCO_DB_HOST
  value: {{ include "netdisco.dbHost" . | quote }}
- name: NETDISCO_DB_PORT
  value: {{ .Values.db.port | quote }}
- name: NETDISCO_DB_NAME
  value: {{ .Values.db.name | quote }}
- name: NETDISCO_DB_USER
  value: {{ .Values.db.user | quote }}
- name: NETDISCO_DB_PASS
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.db.existingSecret }}{{ .Values.db.existingSecret }}{{ else }}{{ include "netdisco.fullname" . }}-db{{ end }}
      key: db-password
{{- end }}

{{/* Common volume mounts */}}
{{- define "netdisco.volumeMounts" -}}
- name: config
  mountPath: /home/netdisco/environments
  readOnly: true
{{- if .Values.persistence.enabled }}
- name: nd-site-local
  mountPath: /home/netdisco/nd-site-local
{{- end }}
{{- end }}

{{/* Common volumes */}}
{{- define "netdisco.volumes" -}}
- name: config
  configMap:
    name: {{ include "netdisco.fullname" . }}-config
{{- if .Values.persistence.enabled }}
- name: nd-site-local
  persistentVolumeClaim:
    claimName: {{ include "netdisco.fullname" . }}-nd-site-local
{{- end }}
{{- end }}
