{{define "signature" -}}
```python
{{if .Signature}}{{.Signature}}{{else}}{{.Name}}{{end}}
```
{{- end}}