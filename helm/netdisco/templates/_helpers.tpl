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

{{/* True when any credential injection is active */}}
{{- define "netdisco.credentialsEnabled" -}}
{{- or .Values.vault.enabled .Values.eso.enabled }}
{{- end }}

{{/* Common env vars — DB password from Secret unless Vault injects it */}}
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
{{- if not .Values.vault.enabled }}
- name: NETDISCO_DB_PASS
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.db.existingSecret }}{{ .Values.db.existingSecret }}{{ else }}{{ include "netdisco.fullname" . }}-db{{ end }}
      key: db-password
{{- end }}
{{- end }}

{{/* Vault Agent Injector pod annotations */}}
{{- define "netdisco.vaultAnnotations" -}}
{{- if .Values.vault.enabled }}
vault.hashicorp.com/agent-inject: "true"
vault.hashicorp.com/role: {{ .Values.vault.role | quote }}
vault.hashicorp.com/agent-inject-secret-db-credentials: {{ .Values.vault.dbPath | quote }}
vault.hashicorp.com/agent-inject-template-db-credentials: |
  {{`{{- with secret `}}"{{ .Values.vault.dbPath }}"{{` -}}`}}
  database:
    pass: '{{`{{ .Data.data.`}}{{ .Values.vault.dbPasswordKey }}{{` }}`}}'
  {{`{{- end }}`}}
{{- end }}
{{- end }}

{{/* Init container that merges ConfigMap + injected credential files */}}
{{- define "netdisco.initContainer" -}}
{{- if include "netdisco.credentialsEnabled" . }}
- name: merge-config
  image: alpine:3
  command:
    - sh
    - -c
    - |
      cp /config-src/deployment.yml /merged/deployment.yml
      {{- if .Values.vault.enabled }}
      cat /vault/secrets/db-credentials >> /merged/deployment.yml
      {{- end }}
      {{- if .Values.eso.enabled }}
      cat /credentials/device_auth.yml >> /merged/deployment.yml
      {{- end }}
  volumeMounts:
    - name: config-src
      mountPath: /config-src
      readOnly: true
    - name: config
      mountPath: /merged
    {{- if .Values.eso.enabled }}
    - name: credentials
      mountPath: /credentials
      readOnly: true
    {{- end }}
{{- end }}
{{- end }}

{{/* Volume mounts for app containers */}}
{{- define "netdisco.volumeMounts" -}}
- name: config
  mountPath: /home/netdisco/environments
  {{- if not (include "netdisco.credentialsEnabled" .) }}
  readOnly: true
  {{- end }}
{{- if .Values.persistence.enabled }}
- name: nd-site-local
  mountPath: /home/netdisco/nd-site-local
{{- end }}
{{- end }}

{{/* Volumes */}}
{{- define "netdisco.volumes" -}}
{{- if include "netdisco.credentialsEnabled" . }}
- name: config-src
  configMap:
    name: {{ include "netdisco.fullname" . }}-config
- name: config
  emptyDir: {}
{{- else }}
- name: config
  configMap:
    name: {{ include "netdisco.fullname" . }}-config
{{- end }}
{{- if .Values.eso.enabled }}
- name: credentials
  secret:
    secretName: {{ include "netdisco.fullname" . }}-credentials
{{- end }}
{{- if .Values.persistence.enabled }}
- name: nd-site-local
  persistentVolumeClaim:
    claimName: {{ include "netdisco.fullname" . }}-nd-site-local
{{- end }}
{{- end }}
