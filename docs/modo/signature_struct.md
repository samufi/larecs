{{define "signature_struct" -}}
```python
{{if .Convention}}@{{.Convention}}{{end}}
{{if .Signature}}{{.Signature}}{{else}}{{.Name}}{{end}}
```
{{- end}}