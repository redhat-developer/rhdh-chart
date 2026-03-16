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
{{- default (include "rhdh-must-gather.fullname" .) .Values.serviceAccount.name }}
{{- end }}


{{/*
Build a full image reference from registry, repository, and tag.
Usage: {{ include "rhdh-must-gather.image" (dict "image" .Values.image "defaultTag" .Chart.AppVersion) }}
*/}}
{{- define "rhdh-must-gather.image" -}}
{{- $registry := .image.registry -}}
{{- $repository := .image.repository -}}
{{- $tag := .image.tag | default .defaultTag | default "" -}}
{{- $digest := .image.digest -}}
{{- $ref := "" -}}
{{- if and $tag $digest -}}
{{- $ref = printf ":%s@%s" $tag $digest -}}
{{- else if $digest -}}
{{- $ref = printf "@%s" $digest -}}
{{- else if $tag -}}
{{- $ref = printf ":%s" $tag -}}
{{- end -}}
{{- if $registry -}}
{{- printf "%s/%s%s" $registry $repository $ref -}}
{{- else -}}
{{- printf "%s%s" $repository $ref -}}
{{- end -}}
{{- end -}}

