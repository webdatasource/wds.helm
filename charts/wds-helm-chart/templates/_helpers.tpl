{{/*
Expand the name of the chart.
*/}}
{{- define "wds-helm-chart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart labels.
*/}}
{{- define "wds-helm-chart.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "wds-helm-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Validate ingress basePath. It must be exactly '/' or end with '/'.
Usage: {{ include "wds-helm-chart.validateIngressBasePath" . }} (produces no output unless error)
*/}}
{{- define "wds-helm-chart.validateIngressBasePath" -}}
{{- $val := (default "/" .Values.global.ingress.basePath) -}}
{{- if not (or (eq $val "/") (regexMatch "/.+/$" $val)) -}}
{{- fail (printf "global.ingress.basePath must be '/' or end with '/'. Current value: '%s'" $val) -}}
{{- end -}}
{{- end -}}


{{/*
  dictAddMissing: shallow merge that only adds keys from src into dst
  without overwriting existing ones.
  Usage:
    {{- include "dictAddMissing" (list $dst $src) | fromYaml -}}
*/}}
{{- define "dictAddMissing" -}}
{{- $dst := deepCopy (index . 0) -}}
{{- $src := index . 1 -}}
{{- range $k, $v := $src }}
  {{- if not (hasKey $dst $k) }}
    {{- $_ := set $dst $k $v -}}
  {{- end }}
{{- end }}
{{- toYaml $dst -}}
{{- end }}