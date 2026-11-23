{{- define "unpackerr.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "unpackerr.labels" -}}
{{ include "unpackerr.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{/* Without the chart's version, so a release that changes only the chart doesn't restart Unpackerr. */}}
{{- define "unpackerr.podLabels" -}}
{{ include "unpackerr.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{- define "unpackerr.secretKeyRef" -}}
{{- $path := index . 0 }}
{{- $ref := (index . 1 | default dict).secretKeyRef | default dict }}
secretKeyRef:
  name: {{ required (printf "%s.secretKeyRef.name is required" $path) $ref.name }}
  key: {{ required (printf "%s.secretKeyRef.key is required" $path) $ref.key }}
{{- end }}
