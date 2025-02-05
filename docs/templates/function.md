Mojo function{{template "source_link" .}}

# `{{.Name}}`

{{`{{<expand-all>}}`}}

{{if .Overloads -}}
{{range .Overloads -}}
{{template "overload" . -}}
{{end -}}
{{else -}}
{{template "overload" . -}}
{{- end}}