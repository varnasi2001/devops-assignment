{{- define "mongodb.name" -}}mongodb{{- end -}}
{{- define "mongodb.fullname" -}}mongodb{{- end -}}
{{- define "mongodb.headless" -}}mongodb-headless{{- end -}}
{{- define "mongodb.labels" -}}
app.kubernetes.io/name: mongodb
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}
{{- define "mongodb.selectorLabels" -}}
app.kubernetes.io/name: mongodb
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
