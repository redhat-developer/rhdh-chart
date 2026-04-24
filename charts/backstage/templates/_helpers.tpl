{{/*
Returns custom hostname
*/}}
{{- define "rhdh.hostname" -}}
    {{- if .Values.global.host -}}
        {{- .Values.global.host -}}
    {{- else if .Values.global.clusterRouterBase -}}
        {{- printf "%s-%s.%s" (include "common.names.fullname" .) .Release.Namespace .Values.global.clusterRouterBase -}}
    {{- else -}}
        {{ fail "Unable to generate hostname" }}
    {{- end -}}
{{- end -}}

{{/*
Returns a secret name for service to service auth
*/}}
{{- define "rhdh.backend-secret-name" -}}
    {{- if .Values.global.auth.backend.existingSecret -}}
        {{- .Values.global.auth.backend.existingSecret -}}
    {{- else -}}
        {{- printf "%s-auth" .Release.Name -}}
    {{- end -}}
{{- end -}}

{{/*
Sets the secretKeyRef name for Backstage to the PostgreSQL existing secret if it present
*/}}
{{- define "rhdh.postgresql.secretName" -}}
    {{- if ((((.Values).global).postgresql).auth).existingSecret -}}
        {{- .Values.global.postgresql.auth.existingSecret -}}
    {{- else if .Values.postgresql.auth.existingSecret -}}
        {{- .Values.postgresql.auth.existingSecret -}}
    {{- else -}}
        {{- printf "%s-%s" .Release.Name "postgresql" -}}
    {{- end -}}
{{- end -}}

{{/*
Get the password secret.
Referenced from: https://github.com/bitnami/charts/blob/main/bitnami/postgresql/templates/_helpers.tpl#L94-L105
*/}}
{{- define "postgresql.v1.secretName" -}}
    {{- if .Values.global.postgresql.auth.existingSecret -}}
        {{- printf "%s" (tpl .Values.global.postgresql.auth.existingSecret $) -}}
    {{- else if .Values.auth.existingSecret -}}
        {{- printf "%s" (tpl .Values.auth.existingSecret $) -}}
    {{- else -}}
        {{- printf "%s" (include "common.names.fullname" .) -}}
    {{- end -}}
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
Return resolved Lightspeed values from global.lightspeed with legacy key migration.
*/}}
{{- define "rhdh.lightspeed" -}}
{{- $global := default dict .Values.global -}}
{{- $lightspeed := dict -}}
{{- if hasKey $global "lightspeed" -}}
  {{- $raw := get $global "lightspeed" -}}
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
    {{- else if hasKey $raw "sharedVolume" -}}
      {{- $legacySharedVolume := get $raw "sharedVolume" -}}
      {{- if kindIs "map" $legacySharedVolume -}}
        {{- if hasKey $legacySharedVolume "name" -}}
          {{- $_ := set $lightspeed.runtimeVolume "name" (get $legacySharedVolume "name") -}}
        {{- end -}}
        {{- if and (hasKey $legacySharedVolume "mountPaths") (kindIs "slice" (get $legacySharedVolume "mountPaths")) -}}
          {{- $legacyMountPaths := get $legacySharedVolume "mountPaths" -}}
          {{- if gt (len $legacyMountPaths) 0 -}}
            {{- $_ := set $lightspeed.runtimeVolume "mountPath" (first $legacyMountPaths) -}}
          {{- end -}}
          {{- if gt (len $legacyMountPaths) 1 -}}
            {{- $_ := set $lightspeed.ragVolume "mountPath" (index $legacyMountPaths 1) -}}
          {{- end -}}
        {{- end -}}
        {{- if hasKey $legacySharedVolume "initMountPath" -}}
          {{- $_ := set $lightspeed.ragVolume "initMountPath" (get $legacySharedVolume "initMountPath") -}}
        {{- end -}}
        {{- if and (hasKey $legacySharedVolume "ephemeral") (not (empty (get $legacySharedVolume "ephemeral"))) -}}
          {{- fail "global.lightspeed.sharedVolume.ephemeral is no longer supported; use global.lightspeed.runtimeVolume.persistentVolumeClaim or global.lightspeed.runtimeVolume.emptyDir instead" -}}
        {{- else if hasKey $legacySharedVolume "emptyDir" -}}
          {{- $_ := set $lightspeed.runtimeVolume "type" "emptyDir" -}}
          {{- $_ := set $lightspeed.runtimeVolume "emptyDir" (get $legacySharedVolume "emptyDir") -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if $lightspeed.enabled -}}
  {{- if or (not (kindIs "map" $lightspeed.initContainer)) (empty $lightspeed.initContainer.name) -}}
    {{- fail "global.lightspeed.enabled=true requires the built-in Lightspeed init container configuration" -}}
  {{- end -}}
  {{- if or (not (kindIs "map" $lightspeed.sidecar)) (empty $lightspeed.sidecar.name) -}}
    {{- fail "global.lightspeed.enabled=true requires the built-in Lightspeed sidecar configuration" -}}
  {{- end -}}
  {{- if or (not (kindIs "map" $lightspeed.runtimeVolume)) (empty $lightspeed.runtimeVolume.name) (empty $lightspeed.runtimeVolume.mountPath) -}}
    {{- fail "global.lightspeed.enabled=true requires the built-in Lightspeed runtime volume configuration" -}}
  {{- end -}}
  {{- if or (not (kindIs "map" $lightspeed.ragVolume)) (empty $lightspeed.ragVolume.name) (empty $lightspeed.ragVolume.mountPath) (empty $lightspeed.ragVolume.initMountPath) -}}
    {{- fail "global.lightspeed.enabled=true requires the built-in Lightspeed RAG volume configuration" -}}
  {{- end -}}
  {{- $_ := include "rhdh.lightspeed.runtimeVolumeType" (dict "volume" $lightspeed.runtimeVolume "path" "global.lightspeed.runtimeVolume") -}}
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

When optional=false is passed, fail fast if the referenced payload file is missing.
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
{{- include "rhdh.lightspeed.fileContent" (dict "context" $context "file" $lightspeed.secret.sourceFile "optional" $lightspeed.secret.optional "ref" "global.lightspeed.secret.sourceFile") | fromYaml | toYaml -}}
{{- end -}}
{{- end -}}

{{/*
Return the Lightspeed ConfigMap configuration for checksum calculation.
This checksums the resolved configMaps values; payload file content is baked
into the chart archive so changes are captured by chart version bumps.
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
This checksums the resolved secret values; payload file content is baked
into the chart archive so changes are captured by chart version bumps.
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
  {{- fail "global.lightspeed.secret.name must be set when global.lightspeed.secret.create=false" -}}
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
        {{- fail (printf "global.lightspeed.configMaps[%s].nameOverride must be set when create=false" $configMap.name) -}}
    {{- end -}}
{{- end -}}

{{/*
Return the Lightspeed ConfigMap volume name.
*/}}
{{- define "rhdh.lightspeed.configMapVolumeName" -}}
{{- printf "lightspeed-config-%s" .name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the computed EXTRA_CATALOG_INDEX_IMAGES env var value from
global.catalogIndex.extraImages.  Returns an empty string when no extra
images are configured.
*/}}
{{- define "rhdh.catalogIndex.extraImagesEnvValue" -}}
{{- $root := . -}}
{{- $imgs := list -}}
{{- range (.Values.global.catalogIndex.extraImages | default list) -}}
  {{- $item := include "common.tplvalues.render" (dict "value" . "context" $root) | fromYaml -}}
  {{- $ref := printf "%s/%s:%s" $item.registry $item.repository $item.tag -}}
  {{- if $item.name -}}
    {{- if or (contains "," $item.name) (contains "=" $item.name) -}}
      {{- fail (printf "global.catalogIndex.extraImages[].name %q must not contain ',' or '='" $item.name) -}}
    {{- end -}}
    {{- $ref = printf "%s=%s" $item.name $ref -}}
  {{- end -}}
  {{- $imgs = append $imgs $ref -}}
{{- end -}}
{{- join "," $imgs -}}
{{- end -}}

{{/*
DEPRECATED: The following templates are deprecated. Please use the corresponding "rhdh.*" templates instead.
*/}}

{{/*
DEPRECATED: Use "rhdh.hostname" instead.
Returns custom hostname
*/}}
{{- define "janus-idp.hostname" -}}
    {{- include "rhdh.hostname" . -}}
{{- end -}}

{{/*
DEPRECATED: Use "rhdh.backend-secret-name" instead.
Returns a secret name for service to service auth
*/}}
{{- define "janus-idp.backend-secret-name" -}}
    {{- include "rhdh.backend-secret-name" . -}}
{{- end -}}

{{/*
DEPRECATED: Use "rhdh.postgresql.secretName" instead.
Sets the secretKeyRef name for Backstage to the PostgreSQL existing secret if it present
*/}}
{{- define "janus-idp.postgresql.secretName" -}}
    {{- include "rhdh.postgresql.secretName" . -}}
{{- end -}}