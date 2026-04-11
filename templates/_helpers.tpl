{{- define "mdai-hub.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mdai-hub.fullname" -}}
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

{{- define "mdai-hub.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mdai-hub.labels" -}}
helm.sh/chart: {{ include "mdai-hub.chart" . }}
{{ include "mdai-hub.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "mdai-hub.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mdai-hub.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "nats.secretName" -}}
{{- $secretName := "nats-secret" -}}
{{- if .Values.nats.auth.users -}}
  {{- $firstUser := index .Values.nats.auth.users 0 -}}
  {{- if and $firstUser.passwordFrom $firstUser.passwordFrom.secretKeyRef -}}
    {{- $secretName = $firstUser.passwordFrom.secretKeyRef.name -}}
  {{- end -}}
{{- end -}}
{{- $secretName -}}
{{- end -}}

{{- define "nats.passwordKey" -}}
{{- $passwordKey := "NATS_PASSWORD" -}}
{{- if .Values.nats.auth.users -}}
  {{- $firstUser := index .Values.nats.auth.users 0 -}}
  {{- if and $firstUser.passwordFrom $firstUser.passwordFrom.secretKeyRef -}}
    {{- $passwordKey = $firstUser.passwordFrom.secretKeyRef.key -}}
  {{- end -}}
{{- end -}}
{{- $passwordKey -}}
{{- end -}}

{{- define "nats.instance" -}}
{{- default .Release.Name .Values.nats.instance -}}
{{- end }}

{{- define "valkey.endpoint" -}}
{{- $port := .Values.valkey.service.port | int -}}
{{- $name := include "valkey.fullname" (dict "Values" .Values.valkey "Release" .Release "Chart" (dict "Name" "valkey")) -}}
{{- printf "%s.%s.svc.cluster.local:%d" $name .Release.Namespace $port -}}
{{- end -}}

{{- define "valkey.secretName" -}}
{{- .Values.valkey.auth.usersExistingSecret | default "valkey-secret" -}}
{{- end -}}

{{- define "valkey.passwordKey" -}}
{{- .Values.valkey.auth.aclUsers.default.passwordKey | default "VALKEY_PASSWORD" -}}
{{- end -}}

{{- define "valkey.endpointKey" -}}
{{- "VALKEY_ENDPOINT" -}}
{{- end -}}
