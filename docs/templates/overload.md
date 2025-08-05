{{define "overload" -}}
{{template "signature_func" .}}

{{`{{<html>}}`}}<details>
<summary>{{`{{</html>}}`}}{{if .Summary}}{{.Summary}}{{else}}Details{{end}}{{`{{<html>}}`}}</summary>{{`{{</html>}}`}}
{{template "description" . -}}
{{template "func_parameters" . -}}
{{template "func_args" . -}}
{{if .Returns}}{{template "func_returns" . -}}{{else}}{{template "func_returns_old" . -}}{{end}}
{{template "func_raises" . -}}
{{`{{<html>}}`}}</details>{{`{{</html>}}`}}
{{end}}