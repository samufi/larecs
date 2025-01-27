{{define "overload" -}}
{{template "signature" .}}

{{`{{<html>}}`}}<details>
<summary>{{`{{</html>}}`}}{{if .Summary}}{{.Summary}}{{else}}Details{{end}}{{`{{<html>}}`}}</summary>{{`{{</html>}}`}}
{{template "description" . -}}
{{template "func_parameters" . -}}
{{template "func_args" . -}}
{{template "func_returns" . -}}
{{template "func_raises" . -}}
{{`{{<html>}}`}}</details>{{`{{</html>}}`}}
{{end}}