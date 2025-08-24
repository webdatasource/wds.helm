{{- define "wds-helm-chart.service" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}
  labels:
    app: {{ .app | default .name }}
    {{- include "wds-helm-chart.labels" .ctx | nindent 4 }}
    {{- with .labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  ports:
    {{- range .ports }}
    - name: {{ .name }}
      port: {{ .port }}
      targetPort: {{ .name }}
      protocol: TCP
    {{- end }}
  selector:
    app: {{ .app | default .name }}
    {{- include "wds-helm-chart.selectorLabels" .ctx | nindent 4 }}
{{- end }}
