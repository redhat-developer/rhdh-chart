{{/*
Expand the name of the chart.
*/}}
{{- define "rhdh-must-gather.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rhdh-must-gather.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "rhdh-must-gather.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rhdh-must-gather.labels" -}}
helm.sh/chart: {{ include "rhdh-must-gather.chart" . }}
{{ include "rhdh-must-gather.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rhdh-must-gather.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rhdh-must-gather.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rhdh-must-gather.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rhdh-must-gather.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Unique run ID based on the current timestamp (YYYYMMDDHHMMSS).
Appended to Job and data-retriever names so each helm install/upgrade
creates new resources, working around Kubernetes Job immutability.
*/}}
{{- define "rhdh-must-gather.runId" -}}
{{- now | date "20060102150405" }}
{{- end }}

{{/*
Job name with unique run ID suffix.
Base name is truncated to 48 chars to stay within the 63-char DNS limit.
*/}}
{{- define "rhdh-must-gather.jobName" -}}
{{- printf "%s-%s" (include "rhdh-must-gather.fullname" . | trunc 48 | trimSuffix "-") (include "rhdh-must-gather.runId" .) }}
{{- end }}

{{/*
Data retriever pod name with unique run ID suffix.
Base name is truncated to 32 chars to stay within the 63-char DNS limit.
*/}}
{{- define "rhdh-must-gather.dataRetrieverName" -}}
{{- printf "%s-data-retriever-%s" (include "rhdh-must-gather.fullname" . | trunc 32 | trimSuffix "-") (include "rhdh-must-gather.runId" .) }}
{{- end }}
