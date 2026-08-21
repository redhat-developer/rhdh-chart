{{/*
Expand the name of the chart.
*/}}
{{- define "rhdh.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rhdh.fullname" -}}
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
{{- define "rhdh.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rhdh.labels" -}}
helm.sh/chart: {{ include "rhdh.chart" . }}
{{ include "rhdh.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $) }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rhdh.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rhdh.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: backstage
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "rhdh.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rhdh.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the backstage image string, respecting global.imageRegistry.
*/}}
{{- define "rhdh.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "chart" .Chart) -}}
{{- end -}}

{{/*
Return an image reference from a value that may be a string or a map with registry/repository/tag fields.
When the value is a map, global.imageRegistry is applied via the bitnami common helper.
*/}}
{{- define "rhdh.image.render" -}}
{{- if kindIs "string" .image -}}
  {{- .image -}}
{{- else -}}
  {{- include "common.images.image" (dict "imageRoot" (.image | toYaml | fromYaml) "global" .global) -}}
{{- end -}}
{{- end -}}

{{/*
Merge global.imagePullSecrets and imagePullSecrets into a single imagePullSecrets block.
*/}}
{{- define "rhdh.imagePullSecrets" -}}
{{- $secrets := list -}}
{{- range ((.Values.global).imagePullSecrets) -}}
  {{- if kindIs "map" . -}}
    {{- $secrets = append $secrets .name -}}
  {{- else -}}
    {{- $secrets = append $secrets . -}}
  {{- end -}}
{{- end -}}
{{- range .Values.imagePullSecrets -}}
  {{- if kindIs "map" . -}}
    {{- $secrets = append $secrets .name -}}
  {{- else -}}
    {{- $secrets = append $secrets . -}}
  {{- end -}}
{{- end -}}
{{- if $secrets }}
imagePullSecrets:
  {{- range $secrets | uniq }}
  - name: {{ . }}
  {{- end }}
{{- end -}}
{{- end -}}

{{/*
Returns custom hostname.
*/}}
{{- define "rhdh.hostname" -}}
    {{- if .Values.host -}}
        {{- .Values.host -}}
    {{- else if .Values.openshift.clusterRouterBase -}}
        {{- printf "%s-%s.%s" (include "rhdh.fullname" .) .Release.Namespace .Values.openshift.clusterRouterBase -}}
    {{- else -}}
        {{ fail "Unable to generate hostname: set host or openshift.clusterRouterBase" }}
    {{- end -}}
{{- end -}}

{{/*
Returns the Secret name for service-to-service auth.
*/}}
{{- define "rhdh.backend-secret-name" -}}
    {{- if .Values.auth.backend.existingSecretRef.name -}}
        {{- .Values.auth.backend.existingSecretRef.name -}}
    {{- else -}}
        {{- printf "%s-auth" (include "rhdh.fullname" .) -}}
    {{- end -}}
{{- end -}}

{{/*
Returns the Secret key for service-to-service auth.
*/}}
{{- define "rhdh.backend-secret-key" -}}
    {{- .Values.auth.backend.existingSecretRef.key | default "backend-secret" -}}
{{- end -}}

{{/*
Returns the PostgreSQL secret name.
*/}}
{{- define "rhdh.postgresql.secretName" -}}
    {{- if ((((.Values).postgresql).auth).existingSecret) -}}
        {{- .Values.postgresql.auth.existingSecret -}}
    {{- else -}}
        {{- printf "%s-%s" .Release.Name "postgresql" -}}
    {{- end -}}
{{- end -}}

{{/*
Returns the PostgreSQL admin password key.
*/}}
{{- define "rhdh.postgresql.adminPasswordKey" -}}
    {{- if (((((.Values).postgresql).auth).secretKeys).adminPasswordKey) -}}
        {{- .Values.postgresql.auth.secretKeys.adminPasswordKey -}}
    {{- else -}}
        postgres-password
    {{- end -}}
{{- end -}}

{{/*
Returns the PostgreSQL hostname.
When postgresql.enabled is false, returns externalDatabase.host.
When enabled, appends -primary when postgresql.architecture is "replication".
*/}}
{{- define "rhdh.postgresql.host" -}}
{{- if not .Values.postgresql.enabled -}}
{{- .Values.externalDatabase.host -}}
{{- else if eq (default "standalone" .Values.postgresql.architecture) "replication" -}}
{{- printf "%s-postgresql-primary" .Release.Name -}}
{{- else -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
Return resolved Lightspeed values from .Values.lightspeed with validation.
*/}}
{{- define "rhdh.lightspeed" -}}
{{- $lightspeed := deepCopy .Values.lightspeed -}}
{{- if $lightspeed.enabled -}}
  {{- $volType := default "emptyDir" $lightspeed.runtimeVolume.type -}}
  {{- if and (ne $volType "emptyDir") (ne $volType "persistentVolumeClaim") -}}
    {{- fail "lightspeed.runtimeVolume.type must be emptyDir or persistentVolumeClaim" -}}
  {{- end -}}
  {{- if eq $volType "persistentVolumeClaim" -}}
    {{- if or (not (kindIs "map" $lightspeed.runtimeVolume.persistentVolumeClaim)) (empty $lightspeed.runtimeVolume.persistentVolumeClaim.claimName) -}}
      {{- fail "lightspeed.runtimeVolume.persistentVolumeClaim.claimName is required when type=persistentVolumeClaim" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- toYaml $lightspeed -}}
{{- end -}}

{{/*
Return the bundled filename for a Lightspeed config key.
*/}}
{{- define "rhdh.lightspeed.configFile" -}}
{{- $map := dict "stack" "lightspeed-stack.yaml" "server" "config.yaml" "profile" "rhdh-profile.py" -}}
{{- get $map . | required (printf "unknown lightspeed config key: %s" .) -}}
{{- end -}}

{{/*
Return the Lightspeed ConfigMap name for a given key.
If existingConfigMap.name is set, use it; otherwise generate from release name.
Expects: dict "root" $ "key" <key> "entry" <config entry>
*/}}
{{- define "rhdh.lightspeed.configMapName" -}}
{{- if .entry.existingConfigMap.name -}}
  {{- .entry.existingConfigMap.name -}}
{{- else -}}
  {{- printf "%s-lightspeed-%s" (include "rhdh.fullname" .root) .key | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Return the key to use for a Lightspeed ConfigMap volume mount.
If existingConfigMap.key is set, use it; otherwise use the bundled filename.
Expects: dict "key" <key> "entry" <config entry>
*/}}
{{- define "rhdh.lightspeed.configMapKey" -}}
{{- if .entry.existingConfigMap.key -}}
  {{- .entry.existingConfigMap.key -}}
{{- else -}}
  {{- include "rhdh.lightspeed.configFile" .key -}}
{{- end -}}
{{- end -}}


{{/*
Return the computed EXTRA_CATALOG_INDEX_IMAGES env var value.
*/}}
{{- define "rhdh.catalogIndex.extraImagesEnvValue" -}}
{{- $root := . -}}
{{- $imgs := list -}}
{{- range (.Values.catalogIndex.extraImages | default list) -}}
  {{- $item := include "common.tplvalues.render" (dict "value" . "context" $root) | fromYaml -}}
  {{- $ref := include "rhdh.image.render" (dict "image" $item "global" $root.Values.global) -}}
  {{- if $item.name -}}
    {{- if or (contains "," $item.name) (contains "=" $item.name) -}}
      {{- fail (printf "catalogIndex.extraImages[].name %q must not contain ',' or '='" $item.name) -}}
    {{- end -}}
    {{- $ref = printf "%s=%s" $item.name $ref -}}
  {{- end -}}
  {{- $imgs = append $imgs $ref -}}
{{- end -}}
{{- join "," $imgs -}}
{{- end -}}

{{/*
Return an orchestrator image, resolving tpl expressions in each field.
Expects: dict "image" <image map> "context" $
*/}}
{{- define "rhdh.orchestrator.image" -}}
{{- $resolved := dict
  "registry" (tpl (default "" .image.registry) .context)
  "repository" (tpl (default "" .image.repository) .context)
  "tag" (tpl (default "" .image.tag) .context)
  "digest" (tpl (default "" .image.digest) .context)
-}}
{{- include "rhdh.image.render" (dict "image" $resolved "global" .context.Values.global) -}}
{{- end -}}

{{/*
Return true if any field in a structured image map is non-empty.
Expects: an image map with registry/repository/tag/digest fields.
*/}}
{{- define "rhdh.image.hasOverride" -}}
{{- if or .registry .repository .tag .digest -}}true{{- end -}}
{{- end -}}

{{/*
Returns the orchestrator DB creation Job name, lowercased and truncated to 63 chars.
The version suffix is preserved in full; only the prefix is truncated.
*/}}
{{- define "rhdh.orchestrator.dbJobName" -}}
{{- $versionSuffix := printf "-%s" (.Chart.Version | replace "." "-") -}}
{{- $prefix := printf "%s-create-sf-db" (include "rhdh.fullname" .) | trunc (int (sub 63 (len $versionSuffix))) | trimSuffix "-" -}}
{{- printf "%s%s" $prefix $versionSuffix | lower -}}
{{- end -}}
