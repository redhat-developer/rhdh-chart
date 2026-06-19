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
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rhdh.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rhdh.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
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
    {{- else if .Values.clusterRouterBase -}}
        {{- printf "%s-%s.%s" (include "rhdh.fullname" .) .Release.Namespace .Values.clusterRouterBase -}}
    {{- else -}}
        {{ fail "Unable to generate hostname: set host or clusterRouterBase" }}
    {{- end -}}
{{- end -}}

{{/*
Returns a secret name for service to service auth.
*/}}
{{- define "rhdh.backend-secret-name" -}}
    {{- if .Values.auth.backend.existingSecret -}}
        {{- .Values.auth.backend.existingSecret -}}
    {{- else -}}
        {{- printf "%s-auth" .Release.Name -}}
    {{- end -}}
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
*/}}
{{- define "rhdh.postgresql.host" -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}

{{/*
Return the configured Lightspeed runtime volume type and validate the required
source block is present.
*/}}
{{- define "rhdh.lightspeed.runtimeVolumeType" -}}
{{- $volume := .volume -}}
{{- $path := .path -}}
{{- $volumeType := default "emptyDir" $volume.type -}}
{{- if eq $volumeType "emptyDir" -}}
  {{- if not (hasKey $volume "emptyDir") -}}
    {{- fail (printf "%s.emptyDir must be set when %s.type=emptyDir" $path $path) -}}
  {{- end -}}
{{- else if eq $volumeType "persistentVolumeClaim" -}}
  {{- if or (not (hasKey $volume "persistentVolumeClaim")) (empty (get $volume "persistentVolumeClaim")) -}}
    {{- fail (printf "%s.persistentVolumeClaim must be set when %s.type=persistentVolumeClaim" $path $path) -}}
  {{- end -}}
  {{- $persistentVolumeClaim := get $volume "persistentVolumeClaim" -}}
  {{- if or (not (kindIs "map" $persistentVolumeClaim)) (empty (get $persistentVolumeClaim "claimName")) -}}
    {{- fail (printf "%s.persistentVolumeClaim.claimName must be set when %s.type=persistentVolumeClaim" $path $path) -}}
  {{- end -}}
{{- else -}}
  {{- fail (printf "%s.type must be one of emptyDir or persistentVolumeClaim" $path) -}}
{{- end -}}
{{- $volumeType -}}
{{- end -}}

{{/*
Return resolved Lightspeed values from .Values.lightspeed with legacy key migration.
*/}}
{{- define "rhdh.lightspeed" -}}
{{- $lightspeed := dict -}}
{{- if hasKey .Values "lightspeed" -}}
  {{- $raw := .Values.lightspeed -}}
  {{- if kindIs "bool" $raw -}}
    {{- $_ := set $lightspeed "enabled" $raw -}}
  {{- else if kindIs "map" $raw -}}
    {{- $lightspeed = deepCopy $raw -}}
    {{- if hasKey $raw "runtimeVolume" -}}
      {{- $rawRuntimeVolume := get $raw "runtimeVolume" -}}
      {{- if and (kindIs "map" $rawRuntimeVolume) (not (hasKey $rawRuntimeVolume "type")) -}}
        {{- if and (hasKey $rawRuntimeVolume "persistentVolumeClaim") (not (empty (get $rawRuntimeVolume "persistentVolumeClaim"))) -}}
          {{- $_ := set $lightspeed.runtimeVolume "type" "persistentVolumeClaim" -}}
        {{- else if hasKey $rawRuntimeVolume "emptyDir" -}}
          {{- $_ := set $lightspeed.runtimeVolume "type" "emptyDir" -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if $lightspeed.enabled -}}
  {{- if or (not (kindIs "map" $lightspeed.initContainer)) (empty $lightspeed.initContainer.name) -}}
    {{- fail "lightspeed.enabled=true requires the built-in Lightspeed init container configuration" -}}
  {{- end -}}
  {{- if or (not (kindIs "map" $lightspeed.sidecar)) (empty $lightspeed.sidecar.name) -}}
    {{- fail "lightspeed.enabled=true requires the built-in Lightspeed sidecar configuration" -}}
  {{- end -}}
  {{- if or (not (kindIs "map" $lightspeed.runtimeVolume)) (empty $lightspeed.runtimeVolume.name) (empty $lightspeed.runtimeVolume.mountPath) -}}
    {{- fail "lightspeed.enabled=true requires the built-in Lightspeed runtime volume configuration" -}}
  {{- end -}}
  {{- if or (not (kindIs "map" $lightspeed.ragVolume)) (empty $lightspeed.ragVolume.name) (empty $lightspeed.ragVolume.mountPath) (empty $lightspeed.ragVolume.initMountPath) -}}
    {{- fail "lightspeed.enabled=true requires the built-in Lightspeed RAG volume configuration" -}}
  {{- end -}}
  {{- $_ := include "rhdh.lightspeed.runtimeVolumeType" (dict "volume" $lightspeed.runtimeVolume "path" "lightspeed.runtimeVolume") -}}
{{- end -}}
{{- toYaml $lightspeed -}}
{{- end -}}

{{/*
Return the passed Lightspeed values or compute them from context.
*/}}
{{- define "rhdh.lightspeed.resolve" -}}
{{- $context := .context -}}
{{- $input := .input -}}
{{- if and (kindIs "map" $input) (hasKey $input "lightspeed") -}}
{{- toYaml (get $input "lightspeed") -}}
{{- else -}}
{{- include "rhdh.lightspeed" $context -}}
{{- end -}}
{{- end -}}

{{/*
Return the relative path for a Lightspeed payload file.
*/}}
{{- define "rhdh.lightspeed.filePath" -}}
{{- printf "files/lightspeed/%s" . -}}
{{- end -}}

{{/*
Return rendered content of a Lightspeed payload file.
*/}}
{{- define "rhdh.lightspeed.fileContent" -}}
{{- $path := include "rhdh.lightspeed.filePath" .file -}}
{{- $content := .context.Files.Get $path -}}
{{- $exists := gt (len (.context.Files.Glob $path)) 0 -}}
{{- if and (hasKey . "optional") (not .optional) -}}
  {{- $message := printf "missing required Lightspeed payload file %s" $path -}}
  {{- if hasKey . "ref" -}}
    {{- $message = printf "%s referenced by %s" $message .ref -}}
  {{- end -}}
  {{- $_ := required $message (ternary $path "" $exists) -}}
{{- end -}}
{{- $content -}}
{{- end -}}

{{/*
Return the stringData map for the Lightspeed Secret.
*/}}
{{- define "rhdh.lightspeed.secretStringData" -}}
{{- $context := . -}}
{{- if and (kindIs "map" .) (hasKey . "context") -}}
  {{- $context = get . "context" -}}
{{- end -}}
{{- $lightspeed := include "rhdh.lightspeed.resolve" (dict "context" $context "input" .) | fromYaml -}}
{{- if not $lightspeed.secret.create -}}
{{- dict | toYaml -}}
{{- else -}}
{{- include "rhdh.lightspeed.fileContent" (dict "context" $context "file" $lightspeed.secret.sourceFile "optional" $lightspeed.secret.optional "ref" "lightspeed.secret.sourceFile") | fromYaml | toYaml -}}
{{- end -}}
{{- end -}}

{{/*
Return the Lightspeed ConfigMap configuration for checksum calculation.
*/}}
{{- define "rhdh.lightspeed.configMapsChecksum" -}}
{{- $context := . -}}
{{- if and (kindIs "map" .) (hasKey . "context") -}}
  {{- $context = get . "context" -}}
{{- end -}}
{{- $lightspeed := include "rhdh.lightspeed.resolve" (dict "context" $context "input" .) | fromYaml -}}
{{- $configMaps := list -}}
{{- range $lightspeed.configMaps -}}
  {{- $configMaps = append $configMaps (dict
      "name" .name
      "create" (not (and (hasKey . "create") (not .create)))
      "nameOverride" .nameOverride
      "mountPath" .mountPath
      "subPath" .subPath
      "sourceFile" .sourceFile
      "optional" .optional
    ) -}}
{{- end -}}
{{- toJson $configMaps -}}
{{- end -}}

{{/*
Return the Lightspeed Secret configuration for checksum calculation.
*/}}
{{- define "rhdh.lightspeed.secretChecksum" -}}
{{- $context := . -}}
{{- if and (kindIs "map" .) (hasKey . "context") -}}
  {{- $context = get . "context" -}}
{{- end -}}
{{- $lightspeed := include "rhdh.lightspeed.resolve" (dict "context" $context "input" .) | fromYaml -}}
{{- dict
    "create" $lightspeed.secret.create
    "name" $lightspeed.secret.name
    "optional" $lightspeed.secret.optional
    "sourceFile" $lightspeed.secret.sourceFile
  | toJson -}}
{{- end -}}

{{/*
Return the Lightspeed secret name.
*/}}
{{- define "rhdh.lightspeed.secretName" -}}
{{- $context := . -}}
{{- if and (kindIs "map" .) (hasKey . "context") -}}
  {{- $context = get . "context" -}}
{{- end -}}
{{- $lightspeed := include "rhdh.lightspeed.resolve" (dict "context" $context "input" .) | fromYaml -}}
{{- if $lightspeed.secret.name -}}
  {{- $lightspeed.secret.name -}}
{{- else if $lightspeed.secret.create -}}
  {{- printf "%s-lightspeed-secret" $context.Release.Name -}}
{{- else -}}
  {{- fail "lightspeed.secret.name must be set when lightspeed.secret.create=false" -}}
{{- end -}}
{{- end -}}

{{/*
Return the Lightspeed ConfigMap name.
*/}}
{{- define "rhdh.lightspeed.configMapName" -}}
{{- $root := .root -}}
{{- $configMap := .configMap -}}
{{- $create := not (and (hasKey $configMap "create") (not $configMap.create)) -}}
    {{- if $configMap.nameOverride -}}
        {{- $configMap.nameOverride -}}
    {{- else if $create -}}
        {{- printf "%s-lightspeed-%s" $root.Release.Name $configMap.name | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
        {{- fail (printf "lightspeed.configMaps[%s].nameOverride must be set when create=false" $configMap.name) -}}
    {{- end -}}
{{- end -}}

{{/*
Return the Lightspeed ConfigMap volume name.
*/}}
{{- define "rhdh.lightspeed.configMapVolumeName" -}}
{{- printf "lightspeed-config-%s" .name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the computed EXTRA_CATALOG_INDEX_IMAGES env var value.
*/}}
{{- define "rhdh.catalogIndex.extraImagesEnvValue" -}}
{{- $root := . -}}
{{- $imgs := list -}}
{{- range (.Values.catalogIndex.extraImages | default list) -}}
  {{- $item := include "common.tplvalues.render" (dict "value" . "context" $root) | fromYaml -}}
  {{- $ref := printf "%s/%s:%s" $item.registry $item.repository $item.tag -}}
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
