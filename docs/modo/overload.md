{{define "overload" -}}
```mojo
{{.Signature}}
```

{{`{{<html>}}`}}<details>
<summary>{{`{{</html>}}`}}{{template "summary" . -}}{{`{{<html>}}`}}</summary>{{`{{</html>}}`}}
{{template "description" . -}}
{{template "func_parameters" . -}}
{{template "func_args" . -}}
{{template "func_returns" . -}}
{{template "func_raises" . -}}
{{`{{<html>}}`}}</details>{{`{{</html>}}`}}
{{end}}