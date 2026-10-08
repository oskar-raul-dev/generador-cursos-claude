{{/*
Las plantillas compartidas de los servicios (Fase 13). Cada una recibe el contexto del subchart que
la incluye: .Chart.Name es el nombre del servicio y .Values son sus valores.
Los nombres de las plantillas son globales en Helm: llevan el prefijo lab-common para no chocar.
*/}}

{{/* Las labels recomendadas de Kubernetes (contrato §4), más las dos que pone Helm: quién lo
     instaló y en qué release. instance es lo que distingue a la segunda cadena (Fase 14). */}}
{{- define "lab-common.labels" -}}
{{ include "lab-common.labelsFor" (dict "ctx" . "component" .Values.component) }}
{{- end -}}

{{/* Lo mismo, con otro componente: el Job de migraciones es del servicio, pero no es el backend. */}}
{{- define "lab-common.labelsFor" -}}
app.kubernetes.io/name: {{ .ctx.Chart.Name }}
app.kubernetes.io/part-of: lab
app.kubernetes.io/component: {{ .component }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
app.kubernetes.io/managed-by: {{ .ctx.Release.Service }}
{{- end -}}

{{/* El selector usa solo el nombre: una label de más y el Deployment no encuentra sus pods
     (contrato §4, incidente 06). Es inmutable: cambiarlo obliga a borrar el Deployment. */}}
{{- define "lab-common.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
{{- end -}}

{{/* Las labels del pod: las de arriba más la versión, que es el tag del paso de generación. */}}
{{- define "lab-common.podLabels" -}}
{{ include "lab-common.labels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
{{- end -}}

{{/* La imagen del servicio. El tag no tiene valor por defecto a propósito: lo pone task deploy desde
     STEP_TAGS del Taskfile, que es el único lugar donde vive (o --set <svc>.image.tag=… a mano). */}}
{{- define "lab-common.image" -}}
{{ .Values.image.repository }}:{{ required (printf "falta %s.image.tag: el tag del paso (task deploy lo toma de STEP_TAGS)" .Chart.Name) .Values.image.tag }}
{{- end -}}

{{/* G3 (Fase 12): la base del servicio, desde su Secret <svc>-db. El Secret no es del chart: lo crea
     task platform:postgres con las contraseñas de .secrets/, que no van en ningún valor. */}}
{{- define "lab-common.databaseEnv" -}}
- name: DATABASE_URL
  valueFrom:
    secretKeyRef: {name: {{ .Chart.Name }}-db, key: DATABASE_URL}
{{- end -}}

{{/* Las sondas del contenedor (Fase 15), desde .Values.probes: readiness decide el tráfico, liveness
     decide la vida, y startup protege el arranque lento. Una sonda sin valor no se escribe. */}}
{{- define "lab-common.probes" -}}
{{- with .Values.probes.startup }}
startupProbe:
  httpGet: {path: {{ .path }}, port: http}
  periodSeconds: {{ .periodSeconds }}
  failureThreshold: {{ .failureThreshold }}
{{- end }}
{{- with .Values.probes.readiness }}
readinessProbe:
  httpGet: {path: {{ .path }}, port: http}
  periodSeconds: {{ .periodSeconds }}
  timeoutSeconds: {{ .timeoutSeconds }}
  failureThreshold: {{ .failureThreshold }}
{{- end }}
{{- with .Values.probes.liveness }}
livenessProbe:
  httpGet: {path: {{ .path }}, port: http}
  periodSeconds: {{ .periodSeconds }}
  timeoutSeconds: {{ .timeoutSeconds }}
  failureThreshold: {{ .failureThreshold }}
{{- end }}
{{- end -}}

{{/* Los recursos del contenedor (Fase 15): lo que se le promete al planificador (requests) y lo que
     impone el cgroup (limits). Sin límite de CPU, a propósito: la Fase 15 dice por qué. */}}
{{- define "lab-common.resources" -}}
resources:
  {{- toYaml .Values.resources | nindent 2 }}
{{- end -}}

{{/* Lo que el Deployment declara sobre su ciclo de vida (Fase 16): cómo reemplaza réplicas en un rollout,
     cuánto espera antes de declararlo atascado, y las réplicas, salvo que las maneje un HPA. */}}
{{- define "lab-common.deploymentSpec" -}}
{{- if not .Values.autoscaling.enabled }}
replicas: {{ .Values.replicaCount }}
{{- end }}
# Si el rollout no avanza en este tiempo, el Deployment lo marca ProgressDeadlineExceeded (incidente 16).
progressDeadlineSeconds: {{ .Values.rollout.progressDeadlineSeconds }}
strategy:
  type: RollingUpdate
  rollingUpdate:
    # Una réplica de más mientras sube la nueva, y ninguna de menos: nunca baja la capacidad.
    maxSurge: {{ .Values.rollout.maxSurge }}
    maxUnavailable: {{ .Values.rollout.maxUnavailable }}
{{- end -}}

{{/* El apagado del pod (Fase 16): primero el preStop espera a que el Service y la puerta se enteren de
     que el pod se va; después llega SIGTERM, y el proceso termina lo que tiene. Todo dentro del plazo. */}}
{{- define "lab-common.shutdown" -}}
{{- if gt (int .Values.shutdown.preStopSeconds) 0 }}
lifecycle:
  preStop:
    # Una pausa del kubelet, sin shell: sirve también en distroless.
    sleep: {seconds: {{ .Values.shutdown.preStopSeconds }}}
{{- end }}
{{- end -}}

{{/* El autoescalado (Fase 16): un HPA por CPU, si el servicio lo enciende. Mientras exista, el HPA es el
     dueño de las réplicas, y el Deployment no las declara (si las declarara, Helm y el HPA chocarían). */}}
{{- define "lab-common.hpa" -}}
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Chart.Name }}
  labels:
    {{- include "lab-common.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Chart.Name }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        # El porcentaje es de los requests de CPU, no de la máquina: sin requests, el HPA no puede calcular.
        target: {type: Utilization, averageUtilization: {{ .Values.autoscaling.cpuPercent }}}
{{- end }}
{{- end -}}

{{/* El Service: el mismo en los cuatro backends y en storefront, salvo el nombre. */}}
{{- define "lab-common.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}
  labels:
    {{- include "lab-common.labels" . | nindent 4 }}
spec:
  # ClusterIP: una dirección virtual solo dentro del cluster; la entrada desde afuera es el Gateway.
  type: ClusterIP
  selector:
    {{- include "lab-common.selectorLabels" . | nindent 4 }}
  ports:
    - name: http
      port: 8080          # el puerto del contrato (§3)
      targetPort: http    # el puerto con nombre del contenedor
    {{- if and .Values.global.mtls.enabled (eq .Chart.Name "pricing") }}
    # G8 (Fase 19): el puerto con TLS mutuo, solo para quien presente certificado.
    - name: tls
      port: 8443
      targetPort: tls
    # G10 (Fase 23): gRPC, con el mismo mTLS.
    - name: grpc
      port: 9090
      targetPort: grpc
    {{- end }}
{{- end -}}

{{/* La HTTPRoute de un backend: api.<host>/<svc>/… llega al servicio sin el prefijo (Fase 10).
     route.cors, si existe, agrega el filtro CORS del estándar con el origen del storefront. */}}
{{- define "lab-common.httproute" -}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ .Chart.Name }}
  labels:
    {{- include "lab-common.labels" . | nindent 4 }}
spec:
  # De qué puerta cuelga: el Gateway compartido, en su namespace.
  parentRefs:
    - name: {{ .Values.global.gateway.name }}
      namespace: {{ .Values.global.gateway.namespace }}
  hostnames: [{{ .Values.global.hosts.api | quote }}]
  rules:
    - matches:
        - path: {type: PathPrefix, value: /{{ .Chart.Name }}}
      filters:
        # El servicio no sabe de prefijos: /{{ .Chart.Name }}/health/live le llega como /health/live.
        - type: URLRewrite
          urlRewrite:
            path: {type: ReplacePrefixMatch, replacePrefixMatch: /}
        {{- with .Values.route.cors }}
        # La página del storefront vive en otro origen: el navegador solo le entrega la respuesta si la
        # puerta lo autoriza (HTTPRouteCORS, soporte extendido).
        - type: CORS
          cors:
            allowOrigins: [{{ printf "http://%s:%v" $.Values.global.hosts.storefront $.Values.global.publicPort | quote }}]
            allowMethods: {{ .allowMethods | toJson }}
            {{- with .allowHeaders }}
            allowHeaders: {{ . | toJson }}
            {{- end }}
        {{- end }}
      backendRefs:
        - name: {{ .Chart.Name }}
          port: 8080
{{- end -}}

{{/* Las migraciones del servicio (G3): un Job que Helm corre ANTES de instalar o actualizar nada,
     y espera a que termine. Reemplaza a task migrate (Fase 12). */}}
{{- define "lab-common.migrateJob" -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Chart.Name }}-migrate
  labels:
    {{- include "lab-common.labelsFor" (dict "ctx" . "component" "migration") | nindent 4 }}
  annotations:
    # Un hook: Helm lo aplica antes del resto, en cada install y en cada upgrade, y espera a que
    # termine. Si falla, el release falla y ningún Deployment se toca.
    "helm.sh/hook": pre-install,pre-upgrade
    # Los cuatro con el mismo peso: Helm los corre de a uno, por nombre (catalog, inventory, pricing,
    # replenish). Aquí el orden no importa, porque cada uno migra su base; si importara, lo fija el peso.
    "helm.sh/hook-weight": "0"
    # El Job anterior se borra justo antes de crear el nuevo: un Job no se puede volver a aplicar
    # (Fase 12), y así su log se puede leer hasta el próximo despliegue.
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  # Dos reintentos: el primero suele ser Postgres que todavía no acepta conexiones.
  backoffLimit: 2
  template:
    metadata:
      labels:
        {{- include "lab-common.labelsFor" (dict "ctx" . "component" "migration") | nindent 8 }}
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: {{ include "lab-common.image" . }}
          imagePullPolicy: {{ .Values.global.imagePullPolicy }}
          command: {{ .Values.migrate.command | toJson }}
          env:
            {{- include "lab-common.databaseEnv" . | nindent 12 }}
{{- end -}}


{{/* La seguridad del pod (Fase 20): nunca como root, con el usuario numérico (el kubelet no puede comprobar
     que "inventory" o "www-data" no son root), el filtro de llamadas al sistema por defecto del runtime, y
     sin el token de la API montado: ningún servicio del sistema le habla a Kubernetes. */}}
{{- define "lab-common.podSecurity" -}}
{{- if .Values.global.podSecurity.enabled }}
automountServiceAccountToken: false
securityContext:
  runAsNonRoot: true
  runAsUser: {{ .Values.securityContext.runAsUser }}
  runAsGroup: {{ .Values.securityContext.runAsUser }}
  seccompProfile: {type: RuntimeDefault}
{{- end }}
{{- end -}}

{{/* La seguridad de cada contenedor (Fase 20): sin escalar privilegios, sin ninguna capacidad del kernel y
     con la raíz de solo lectura; lo que el proceso necesita escribir va a un emptyDir montado en /tmp. */}}
{{- define "lab-common.containerSecurity" -}}
{{- if .Values.global.podSecurity.enabled }}
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities: {drop: [ALL]}
{{- end }}
{{- end -}}


{{/* G10 (Fase 23): las variables estándar de OpenTelemetry. Con las trazas encendidas, cada servicio manda sus
     spans a Tempo por OTLP/HTTP; apagadas, no se pone nada (y el agente de Java se apaga aparte). Solo trazas: las
     métricas y los logs ya tienen su camino (Fases 17 y 18). */}}
{{- define "lab-common.otelEnv" -}}
{{- if .Values.global.traces.enabled }}
- {name: OTEL_SERVICE_NAME, value: {{ .Chart.Name | quote }}}
- {name: OTEL_EXPORTER_OTLP_ENDPOINT, value: "http://tempo.observability.svc.cluster.local:4318"}
- {name: OTEL_EXPORTER_OTLP_PROTOCOL, value: http/protobuf}
- {name: OTEL_TRACES_EXPORTER, value: otlp}
- {name: OTEL_METRICS_EXPORTER, value: none}
- {name: OTEL_LOGS_EXPORTER, value: none}
- {name: OTEL_RESOURCE_ATTRIBUTES, value: "deployment.environment={{ .Release.Name }}"}
{{- else }}
- {name: OTEL_SDK_DISABLED, value: "true"}
{{- end }}
{{- end -}}

{{/*
G12 (Fase 25): por dónde viaja el aviso de reposición. EVENT_BUS=nats o valkey, con la dirección del bus en data;
sin bus, nada, y el aviso sigue siendo un POST a replenish (G5).
*/}}
{{- define "lab-common.busEnv" -}}
{{- if .Values.global.bus.nats.enabled }}
- {name: EVENT_BUS, value: nats}
- {name: NATS_URL, value: "nats://nats.data.svc.cluster.local:4222"}
{{- else if .Values.global.bus.valkey.enabled }}
- {name: EVENT_BUS, value: valkey}
- {name: VALKEY_URL, value: "redis://valkey.data.svc.cluster.local:6379"}
{{- end }}
{{- end -}}
