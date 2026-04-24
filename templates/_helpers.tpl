{{- define "nats.instance" -}}
{{- default .Release.Name .Values.nats.instance -}}
{{- end }}


{{- define "greptimedb-standalone.fullname" -}}
{{- if .Values.global.greptime.fullnameOverride }}
{{- .Values.global.greptime.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.global.greptime.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}