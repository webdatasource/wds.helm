{{- define "wds-helm-chart.deployment" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .name }}
  labels:
    app: {{ .name }}
    {{- include "wds-helm-chart.labels" .ctx | nindent 4 }}
    {{- with .labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  replicas: {{ .replicas }}
  selector:
    matchLabels:
      app: {{ .name }}
      {{- include "wds-helm-chart.selectorLabels" .ctx | nindent 6 }}
  template:
    metadata:
      labels:
        app: {{ .name }}
        {{- include "wds-helm-chart.selectorLabels" .ctx | nindent 8 }}
    spec:
      {{- if .nodeSelector }}
      nodeSelector:
        {{- toYaml .nodeSelector | nindent 8 }}
      {{- end }}
      {{- if .tolerations }}
      tolerations:
        {{- toYaml .tolerations | nindent 8 }}
      {{- end }}
      {{- if .affinity }}
      affinity:
        {{- toYaml .affinity | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .name }}
          image: {{ .registry }}/{{ .image }}:{{ .tag }}
          imagePullPolicy: {{ .imagePullPolicy | default "IfNotPresent" }}
          {{- if .env }}
          env:
            {{- range .env }}
            - name: {{ .name }}
              {{- if hasKey . "valueFrom" }}
              valueFrom:
                {{- toYaml .valueFrom | nindent 16 }}
              {{- else }}
              value: {{ .value | quote }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if .ports }}
          ports:
            {{- range .ports }}
            - name: {{ .name }}
              containerPort: {{ .containerPort }}
            {{- end }}
          {{- end }}
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
{{- end }}
