{{/* Helper functions */}}

{{- define "unmanaged-resource-exists" -}}
    {{- $api := index . 0 -}}
    {{- $kind := index . 1 -}}
    {{- $namespace := index . 2 -}}
    {{- $name := index . 3 -}}
    {{- $releaseName := index . 4 -}}
    {{- $apiCapabilities := index . 5 -}}
    {{- $unmanagedSubscriptionExists := "true" -}}
    {{- if $apiCapabilities.Has (printf "%s/%s" $api $kind) }}
        {{- $existingOperator := lookup $api $kind $namespace $name -}}
        {{- if empty $existingOperator -}}
            {{- "false" -}}
        {{- else -}}
            {{- $isManagedResource := include "is-managed-resource" (list $existingOperator $releaseName) -}}
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
    {{- $resourceReleaseName := dig "metadata" "annotations" (dict "meta.helm.sh/release-name" "NA") $resource -}}
    {{- if eq (get $resourceReleaseName "meta.helm.sh/release-name") $releaseName -}}
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
    {{- $apiCapabilities := index . 2 -}}
    {{- if $apiCapabilities.Has "olm.operatorframework.io/v1/ClusterExtension" -}}
        {{- $existingExtension := lookup "olm.operatorframework.io/v1" "ClusterExtension" "" $name -}}
        {{- if empty $existingExtension -}}
            {{- "false" -}}
        {{- else -}}
            {{- $isManagedResource := include "is-managed-resource" (list $existingExtension $releaseName) -}}
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