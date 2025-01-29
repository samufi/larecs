{{define "methods" -}}
{{if .Functions}}## Methods

{{`{{<expand-all>}}`}}

{{range .Functions -}}
{{template "method" . -}}
{{end}}
{{end}}
{{- end}}