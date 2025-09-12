{{- define "wds-helm-chart.pdb" }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ .name }}
  labels:
    app: {{ .name }}
    {{- include "wds-helm-chart.labels" .ctx | nindent 4 }}
spec:
  selector:
    matchLabels:
      app: {{ .name }}
      {{- include "wds-helm-chart.selectorLabels" .ctx | nindent 6 }}
  {{- if .minAvailable }}
  minAvailable: {{ .minAvailable }}
  {{- else if .maxUnavailable }}
  maxUnavailable: {{ .maxUnavailable }}
  {{- end }}
{{- end }}
