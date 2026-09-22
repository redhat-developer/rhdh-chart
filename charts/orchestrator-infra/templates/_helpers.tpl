{{/* Helper functions */}}

{{- define "olm-version" -}}
    {{- $requested := default "v0" .Values.olmVersion -}}
    {{- $requested -}}
{{- end -}}

{{- define "csv-version" -}}
    {{- $csv := index . 0 -}}
    {{- $packageName := index . 1 -}}
    {{- $version := trimPrefix (printf "%s." $packageName) $csv -}}
    {{- trimPrefix "v" $version -}}
{{- end -}}
