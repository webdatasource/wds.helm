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
        {{- range $c := .containers }}
        - name: {{ $c.name }}
          {{- if $c.registry }}
          image: {{ $c.registry }}/{{ $c.image }}:{{ $c.tag }}
          {{- else }}
          image: {{ $c.image }}:{{ $c.tag }}
          {{- end }}
          imagePullPolicy: {{ $c.imagePullPolicy }}
          {{- if $c.command }}
          command:
            {{- range $c.command }}
            - {{ . | quote }}
            {{- end }}
          {{- end }}
          {{- if $c.args }}
          args:
            {{- range $c.args }}
            - {{ . | quote }}
            {{- end }}
          {{- end }}
          {{- if $c.env }}
          env:
            {{- range $c.env }}
            - name: {{ .name }}
              {{- if hasKey . "valueFrom" }}
              valueFrom:
                {{- toYaml .valueFrom | nindent 16 }}
              {{- else }}
              value: {{ .value | quote }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if $c.ports }}
          ports:
            {{- range $c.ports }}
            - name: {{ .name }}
              containerPort: {{ .containerPort }}
            {{- end }}
          {{- end }}
          livenessProbe:
            httpGet:
              path: {{ $c.livenessProbePath | default "/health" }}
              port: {{ $c.livenessProbePort | default 8080 }}
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: {{ $c.readinessProbePath | default "/ready" }}
              port: {{ $c.readinessProbePort | default 8080 }}
            initialDelaySeconds: 5
            periodSeconds: 10
        {{- end }}
{{- end }}