{{- define "wds-helm-chart.hpa" }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .name }}
  labels:
    app: {{ .name }}
    {{- include "wds-helm-chart.labels" .ctx | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .name }}
  minReplicas: {{ .minReplicas }}
  maxReplicas: {{ .maxReplicas }}
  {{- if .metrics }}
  metrics:
    {{- toYaml .metrics | nindent 4 }}
  {{- else }}
  metrics:
    {{- if .cpu }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .cpu }}
    {{- end }}
    {{- if .memory }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .memory }}
    {{- end }}
  {{- end }}
{{- end }}
