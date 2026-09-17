{{/* Helper functions */}}

{{- define "unmanaged-resource-exists" -}}
    {{- $api := index . 0 -}}
    {{- $kind := index . 1 -}}
    {{- $namespace := index . 2 -}}
    {{- $name := index . 3 -}}
    {{- $releaseName := index . 4 -}}
    {{- $releaseNamespace := index . 5 -}}
    {{- $apiCapabilities := index . 6 -}}
    {{- if $apiCapabilities.Has (printf "%s/%s" $api $kind) }}
        {{- $existingOperator := lookup $api $kind $namespace $name -}}
        {{- if empty $existingOperator -}}
            {{- "false" -}}
        {{- else -}}
            {{- $isManagedResource := include "is-managed-resource" (list $existingOperator $releaseName $releaseNamespace) -}}
            {{- if eq $isManagedResource "true" -}}
                {{- "false" -}}
            {{- else -}}
                {{- "true" -}}
            {{- end -}}
        {{- end -}}
    {{- else -}}
        {{- "false" -}}
    {{- end -}}
{{- end -}}

{{- define "is-managed-resource" -}}
    {{- $resource := index . 0 -}}
    {{- $releaseName := index . 1 -}}
    {{- $releaseNamespace := index . 2 -}}
    {{- $resourceReleaseName := dig "metadata" "annotations" (dict "meta.helm.sh/release-name" "NA") $resource -}}
    {{- $resourceReleaseNamespace := dig "metadata" "annotations" (dict "meta.helm.sh/release-namespace" "NA") $resource -}}
    {{- if and (eq (get $resourceReleaseName "meta.helm.sh/release-name") $releaseName) (eq (get $resourceReleaseNamespace "meta.helm.sh/release-namespace") $releaseNamespace) -}}
        {{- "true" -}}
    {{- else -}}
        {{- "false" -}}
    {{- end -}}
{{- end -}}

{{- define "olm-version" -}}
    {{- $requested := default "auto" .Values.olmVersion -}}
    {{- if eq $requested "auto" -}}
        {{- if .Capabilities.APIVersions.Has "olm.operatorframework.io/v1/ClusterExtension" -}}
            {{- "v1" -}}
        {{- else -}}
            {{- "v0" -}}
        {{- end -}}
    {{- else -}}
        {{- $requested -}}
    {{- end -}}
{{- end -}}

{{- define "unmanaged-clusterextension-exists" -}}
    {{- $name := index . 0 -}}
    {{- $releaseName := index . 1 -}}
    {{- $releaseNamespace := index . 2 -}}
    {{- $apiCapabilities := index . 3 -}}
    {{- if $apiCapabilities.Has "olm.operatorframework.io/v1/ClusterExtension" -}}
        {{- $existingExtension := lookup "olm.operatorframework.io/v1" "ClusterExtension" "" $name -}}
        {{- if empty $existingExtension -}}
            {{- "false" -}}
        {{- else -}}
            {{- $isManagedResource := include "is-managed-resource" (list $existingExtension $releaseName $releaseNamespace) -}}
            {{- if eq $isManagedResource "true" -}}
                {{- "false" -}}
            {{- else -}}
                {{- "true" -}}
            {{- end -}}
        {{- end -}}
    {{- else -}}
        {{- "false" -}}
    {{- end -}}
{{- end -}}

{{- define "csv-version" -}}
    {{- $csv := index . 0 -}}
    {{- $packageName := index . 1 -}}
    {{- $version := trimPrefix (printf "%s." $packageName) $csv -}}
    {{- trimPrefix "v" $version -}}
{{- end -}}
