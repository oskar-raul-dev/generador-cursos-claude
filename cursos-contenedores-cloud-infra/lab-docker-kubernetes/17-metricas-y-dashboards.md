# 📊 Fase 17 — Métricas y tableros: lo que el cluster no sabe de tu negocio

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 17 de 27 · Parte III — Operarlo · **densa**
> **Perfil:** el cluster `lab` (control-plane y dos workers), con los valores de `minimo` (una réplica por servicio) desde la sección 5.5; `lab` completo para la línea base · **Observabilidad encendida:** métricas y tableros (Prometheus y Grafana), y metrics-server de la Fase 16
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: Prometheus y Grafana son pods del cluster
> **Servicios que toca:** los cuatro backends · **Paso de generación:** G6 · Métricas
> **Depende de:** [Fase 16](16-escalado-y-rollout.md) · **Habilita:** [Fase 18](18-logs.md)
> **Incidentes que reserva:** ninguno · **Medición:** la sexta entrega de B-00 (lo que cuesta cada pieza encendida) y las de sus secciones
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 04/10/2026 · macOS arm64
> **Objetivo:** que cada servicio diga cuánto trabaja, cuánto falla y cuánto tarda, con el mismo idioma en los cuatro runtimes; que un tablero lo muestre sin que nadie lo dibuje a mano; y saber cuánto cuesta tener todo eso encendido, para apagarlo cuando no se usa.

---

## 🧭 1. Dónde estamos

La [Fase 16](16-escalado-y-rollout.md) dejó el sistema vendiendo, desplegándose con carga sin perder
peticiones y creciendo solo cuando la CPU sube. Todo lo que se supo de él en esas mediciones salió de
k6, que estaba **afuera**, generando la carga. Adentro, el cluster sabe una sola cosa de cada pod: cuánta
CPU y cuánta memoria usa. Eso es lo que lee metrics-server.

La Parte III abre con la pregunta que el curso trae desde el principio. El 14 de octubre de 2025, las
cajas de las 263 droguerías se congelaron, y **durante los primeros cuarenta minutos nadie supo por qué**
(historia §1.14). En la reunión de arranque de esta parte, Germán la hace sin rodeos:

> *"Valentina, si el 14 de octubre hubiéramos tenido esto, ¿a qué hora nos enteramos? Y no me diga que
> antes. Dígame a qué hora."*

Valentina le contesta con lo que va a construir esta fase y las dos que siguen:

> *"Con métricas, Germán, nos enteramos de que algo va mal: las ventas por minuto se caen y la latencia
> se dispara, y eso se ve en un tablero a los quince segundos. Con logs, sabemos qué: cuál consulta,
> cuál droguería. Con trazas, sabemos dónde: en qué salto de qué servicio se fue el minuto. Hoy no
> teníamos ninguna de las tres. Esta fase pone la primera."*

Es la distinción que separa diagnosticar de adivinar, y el curso la usa hasta el final: **métricas para
saber que algo va mal, logs para saber qué, trazas para saber dónde**. Esta fase es la primera.

---

## 🎯 2. Objetivos de esta fase

1. Generar G6: `/metrics` en los cuatro backends, con el mismo histograma en los cuatro runtimes, y la
   primera métrica de negocio (las ventas).
2. Instalar Prometheus con su `scrape_config` escrito a mano, y entender el modelo de *pull* leyendo lo
   que hace.
3. Instalar Grafana con la fuente de datos y el tablero **como código**, versionados con el chart.
4. Estrenar los interruptores de observabilidad (`task obs:on`, `obs:off`), medir lo que cuesta cada
   pieza encendida y aprender a apagarla cuando no se usa.
5. Medir lo que pasa cuando una etiqueta tiene demasiados valores, que es el error más caro de las
   métricas.

---

## 🚫 3. Qué NO entra todavía

- **Alertas y una cadena de guardia.** Sin destinatario, una alerta es un ejercicio vacío: el laboratorio
  no tiene a quién despertar. La sección 12 dice qué haría falta.
- Logs estructurados y Loki → [Fase 18](18-logs.md). Trazas y Tempo → [Fase 23](23-grpc-y-el-balanceo.md).
- El operador de Prometheus, `ServiceMonitor` y `PodMonitor`: son lo que vas a encontrar en un cluster
  real, y por eso mismo esta fase escribe el `scrape_config` a mano, para que sepas qué generan. Se
  nombran en la traducción y en [a12](a12-operators-de-lectura.md).
- Retención y almacenamiento durables: aquí Prometheus guarda dos días en un `emptyDir`, y lo pierde
  todo si el pod se va.
- **`/metrics` visible desde afuera.** La ruta de cada servicio en la puerta es un prefijo entero, así que
  `api.localhost:8080/pricing/metrics` responde. Se nombra aquí y se cierra en la [Fase 20](20-seguridad-del-pod-y-de-la-red.md).

---

## 🧨 4. El problema, en el laboratorio

Sistema en el cluster `lab`, k6 haciendo de veinte droguerías que consultan el catálogo, los precios y
venden (`bench/trafico/la-vecina.js`, tres visitas por segundo). La pregunta de Germán, en su versión más chica: **¿cuántas ventas por
minuto está haciendo el sistema ahora mismo, y cuánto tarda cada una?**

Lo que el cluster sabe:

```text
$ kubectl -n apps top pods
NAME                          CPU(cores)   MEMORY(bytes)
catalog-549c857b59-hh8zw      35m          43Mi
inventory-87d4677cc-64xxf     13m          236Mi
pricing-5f4cd47f95-d6nws      4m           21Mi
replenish-bcb55dc64-k79g5     13m          52Mi
storefront-6ffd5b8b68-f4kfh   1m           7Mi
```

CPU y memoria, por pod. Ninguna venta, ninguna latencia, ningún error. Si `inventory` empieza a
contestar 503 porque `pricing` no responde, el CPU de `inventory` **baja**: está esperando. El tablero de
metrics-server se vería más tranquilo justo cuando el negocio está peor, que es lo que pasó el 14 de
octubre: el Siga contestaba, solo que tardaba un minuto.

Lo que queda, sin métricas, es leer los logs de texto de cuatro servicios con `kubectl logs` y contar a
mano. Con dos réplicas por servicio, son ocho flujos de log.

> 🧭 **Una tesis del curso, dicha aquí.** Exponer métricas es responsabilidad de la aplicación, no regalo
> de la plataforma. Lo que el cluster te da gratis —CPU, memoria, reinicios— te dice si el contenedor
> está vivo. No te dice nada de tu negocio: cuántas ventas, cuántas fallaron, cuánto tardó cobrar.

> 🩻 **Esto sí funciona igual.** `docker stats` en compose y `kubectl top` en el cluster leen lo mismo, de
> la misma fuente (los cgroups del kernel). Y un tablero con CPU y memoria es igual de útil, e igual de
> mudo sobre el negocio, en los dos lados.

---

## 🧩 5. Métricas, con `pricing`

### 5.1 Los tres pilares, y el *pull*

Las tres fuentes responden preguntas distintas, y conviene tenerlo claro antes de instalar nada:

| Fuente | Contesta | Qué es | Cuánto cuesta guardarla |
|---|---|---|---|
| **Métricas** | ¿va mal algo, y desde cuándo? | números agregados en el tiempo: contadores, histogramas | poco y fijo: no crece con el tráfico, crece con las combinaciones de etiquetas |
| **Logs** | ¿qué pasó exactamente? | un evento por línea, con su contexto | crece con el tráfico |
| **Trazas** | ¿en qué salto se fue el tiempo? | el recorrido de una petición por los servicios | crece con el tráfico; se muestrea |

Una métrica no sabe qué venta falló; sabe que en el último minuto fallaron doce. Por eso es barata, y por
eso es la que se mira primero.

**El modelo de *pull*.** Prometheus no recibe nada: **va a buscar**. Cada quince segundos le pide
`GET /metrics` a cada servicio que conoce, y el servicio le contesta con el estado actual de sus
contadores, en texto plano. Un contador nunca baja (salvo cuando el proceso reinicia y vuelve a cero), y
Prometheus calcula las tasas restando muestras. Tres consecuencias que importan en un cluster:

- **El servicio no sabe quién lo mide**, ni si alguien lo mide. Si Prometheus se apaga, el servicio no se
  entera ni se frena.
- **Prometheus tiene que saber dónde están los pods**, y en Kubernetes los pods cambian de IP en cada
  rollout. Se lo pregunta a la API de Kubernetes, que es lo que hace el `scrape_config` de la sección 5.3.
- **Lo que pasa entre dos visitas se ve como diferencia, no como evento.** Un pod que muere entre dos
  scrapes se lleva lo que contó desde el último (la apuesta de la sección 7 lo mide).

### 5.2 G6: el histograma que los cuatro hablan igual

El contrato de G6 está en la descripción de `GET /metrics` de los cuatro OpenAPI, y es corto: **un
histograma `http_server_requests_seconds`, en segundos, con las etiquetas `method`, `uri` y `status`**.
El mismo nombre en los cuatro runtimes, para que un solo tablero los lea. Cada servicio puede agregar las
suyas.

El nombre no es casual: es el que Spring Boot ya publica. Con `inventory` imponiendo el nombre por
defecto, los otros tres se adaptan y nadie escribe traducciones en el tablero.

Un histograma no guarda cada duración: guarda **cuántas peticiones tardaron menos que cada umbral**
(los *buckets*), más la suma y la cuenta. Con eso, Prometheus calcula percentiles después, y los suma
entre réplicas, cosa que con un percentil ya calculado en cada pod no se puede hacer (el promedio de dos
p95 no es el p95 de nada).

El prompt de G6 está en [a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g6); `pricing`, el piloto, lo cumple con
la librería oficial de Go y un middleware que ya existía, el de la línea de log:

```go
var requestDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
	Name:    "http_server_requests_seconds",
	Help:    "Duración de las peticiones HTTP atendidas, en segundos.",
	Buckets: []float64{0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10},
}, []string{"method", "uri", "status"})

handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
	start := time.Now()
	mux.ServeHTTP(rec, r)
	// El mux deja en r.Pattern la ruta que atendió: por eso se lee después, no antes.
	requestDuration.WithLabelValues(r.Method, routeOf(r), strconv.Itoa(rec.status)).
		Observe(time.Since(start).Seconds())
	…
})
```

`routeOf` convierte `"GET /prices/{sku}"` en `/prices/{sku}`. **La etiqueta es el patrón de la ruta,
nunca la ruta cruda**: con `/prices/SKU-0001` habría una serie por producto, y la sección 9 mide qué
pasa entonces. Lo que no cae en ninguna ruta se cuenta junto, como `/**`, que es como lo llama Spring.

Lo que `pricing` publica después de una lectura:

```text
$ curl -s -H 'Host: api.localhost' http://127.0.0.1:8080/pricing/metrics | grep _count
http_server_requests_seconds_count{method="GET",status="200",uri="/metrics"} 1
http_server_requests_seconds_count{method="GET",status="200",uri="/prices"} 1
http_server_requests_seconds_count{method="GET",status="404",uri="/prices/{sku}"} 1
http_server_requests_seconds_count{method="GET",status="404",uri="/**"} 1
```

Sí: lo leíste por la puerta pública. La sección 3 lo dejó dicho, y la [Fase 20](20-seguridad-del-pod-y-de-la-red.md) lo cierra.

**De estas series salen las tres métricas RED** —*Rate, Errors, Duration*—, que son las que miran casi
todos los tableros de servicios: cuántas peticiones por segundo (la tasa de `_count`), cuántas fallan (la
de las que tienen `status` 5xx) y cuánto tardan (un percentil de los buckets).

La suite de G6 lo comprueba en los cuatro, y de paso deja de pasar la de G4, que pedía un 404 en
`/metrics`: la suite de un paso valida la imagen de ese paso, como siempre.

```bash
task build -- pricing        # y los otros tres; los tags :g6 viven en STEP_TAGS
task images:load -- lab
task deploy -- lab
task conformance TARGET=cluster PROFILE=lab -- G6
```

```text
Success /suite/pricing.g6.hurl (2 request(s) in 16 ms)
Success /suite/replenish.g6.hurl (2 request(s) in 29 ms)
Success /suite/catalog.g6.hurl (2 request(s) in 34 ms)
Success /suite/inventory.g6.hurl (2 request(s) in 95 ms)
```

### 5.3 Prometheus, con el `scrape_config` a mano

Prometheus entra como un subchart más del umbrella, `charts/platform/charts/prometheus/`, con la
condición `observability.metrics.enabled`. Sus objetos viven en el namespace `observability`, que crea
plataforma (como `apps`), aunque el release sea el de `apps`: un chart puede poner objetos en otro
namespace si lo dice explícitamente.

Lo central es el `ConfigMap` con el `prometheus.yml`. El trabajo de los backends, completo:

```yaml
- job_name: backends
  metrics_path: /metrics
  kubernetes_sd_configs:
    - role: pod
      namespaces: {names: ["apps", "apps-b"]}
  relabel_configs:
    # Solo los pods del sistema que son backend: ni Postgres, ni el storefront, ni los Job.
    - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_part_of, __meta_kubernetes_pod_label_app_kubernetes_io_component]
      regex: lab;backend
      action: keep
    # Y de cada pod, solo el puerto que se llama http (en catalog, el de nginx).
    - source_labels: [__meta_kubernetes_pod_container_port_name]
      regex: http
      action: keep
    # Las etiquetas con que se guarda cada serie: servicio, cadena, namespace y pod.
    - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
      target_label: service
    - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_instance]
      target_label: chain
    …
```

Se lee de arriba abajo. `kubernetes_sd_configs` le pide a la API **la lista de pods** de dos namespaces,
con todas sus labels convertidas en metadatos (`__meta_kubernetes_pod_label_<label>`). Cada regla de
`relabel_configs` decide algo sobre cada candidato: la primera descarta lo que no es un backend del
sistema, usando **las labels del contrato** (§4: `part-of: lab`, `component: backend`); la segunda elige
el puerto; las demás copian metadatos a etiquetas que van a quedar en cada serie. Así, cada serie de
`pricing` lleva `service="pricing"` y `chain="lab"`, y el tablero puede separar la segunda cadena sin que
ningún servicio sepa que existe.

Para preguntarle a la API, Prometheus necesita permiso: un `ServiceAccount` con un `ClusterRole` que puede
listar y mirar pods y nodos. Los nombres de lo que vive fuera de un namespace llevan el del release
(`lab-prometheus`), para que dos instalaciones no choquen.

El segundo trabajo trae **lo que el cluster da gratis**: la memoria y la CPU de cada contenedor, que mide
el kubelet (cAdvisor). Va por el proxy de la API, porque el certificado del kubelet de kind no lo acepta
nadie (es el incidente 17 de la [Fase 16](16-escalado-y-rollout.md)), y se queda solo con dos métricas:

```yaml
metric_relabel_configs:
  - source_labels: [__name__]
    regex: container_memory_working_set_bytes|container_cpu_usage_seconds_total
    action: keep
```

`metric_relabel_configs` actúa **después** de traer los datos y antes de guardarlos. Cada nodo de kind
publica entre 1.500 y 3.200 muestras de cAdvisor; Prometheus guarda 18. Sin ese recorte, cAdvisor solo
sería la mitad de todo lo que guarda.

Se enciende con el interruptor, y Prometheus queda en `prometheus.localhost:8080`:

```bash
task obs:on -- metrics
```

```text
$ curl -s -H 'Host: prometheus.localhost' 'http://127.0.0.1:8080/api/v1/targets?state=active' | …
backends replenish up http://10.244.1.63:8080/metrics
backends catalog up http://10.244.2.121:8080/metrics
backends pricing up http://10.244.2.120:8080/metrics
backends pricing up http://10.244.1.61:8080/metrics
… (ocho backends en lab, dos por servicio)
cadvisor lab-worker2 up https://kubernetes.default.svc:443/api/v1/nodes/lab-worker2/proxy/metr…
cadvisor lab-control-plane up …
cadvisor lab-worker up …
prometheus  up http://localhost:9090/metrics
```

Doce blancos, todos `up`, sin que nadie haya escrito una IP. Haz un `rollout restart` de `pricing` y
vuelve a mirar: las IP cambian y la lista se actualiza sola.

### 5.4 Grafana, como código

Grafana es el otro subchart (`observability.dashboards.enabled`), en `grafana.localhost:8080`. Dos
`ConfigMap` lo configuran **al arrancar**, sin clics:

```yaml
datasources.yaml: |
  apiVersion: 1
  datasources:
    - name: Prometheus
      uid: prometheus
      type: prometheus
      url: http://prometheus.observability:9090
      isDefault: true
      editable: false
dashboards.yaml: |
  apiVersion: 1
  providers:
    - name: lab
      folder: La Vecina
      type: file
      allowUiUpdates: false
      options: {path: /var/lib/grafana/dashboards}
```

El tablero es un JSON en `charts/grafana/dashboards/la-vecina-red.json`, que el chart monta con
`.Files.Glob`. Tiene seis paneles: peticiones por segundo, la proporción de 5xx y el p95 por servicio
(las tres RED), las **ventas por minuto**, la memoria por pod (de cAdvisor) y la cantidad de series de
Prometheus. La consulta del p95 es la que conviene leer despacio:

```promql
histogram_quantile(0.95,
  sum by (service, le) (rate(http_server_requests_seconds_bucket{chain=~"$chain",uri!~"/health.*|/metrics"}[1m])))
```

De adentro hacia afuera: la tasa por minuto de cada bucket, sumada entre las réplicas de cada servicio
(conservando `le`, el umbral), y el percentil 95 calculado sobre esa suma. Las sondas y el propio
`/metrics` se excluyen: son tráfico de la plataforma, no del negocio, y bajarían el p95 de mentira.

El panel de errores tiene una trampa que vale la pena ver una vez. La división de los 5xx sobre el total
**no devuelve nada** cuando no hubo ningún 5xx (no hay serie con `status=~"5.."`), y el panel dice
*No data*, que se lee como "no sé" cuando la verdad es "cero". La consulta del chart suma un cero
explícito:

```promql
(sum by (service) (rate(x{status=~"5.."}[1m])) or sum by (service) (rate(x[1m])) * 0)
  / sum by (service) (rate(x[1m]))
```

Y dos detalles del `Deployment` que son decisiones: el anónimo entra con rol `Editor` (puede explorar,
no administrar; en un cluster compartido no se hace, y la [Fase 20](20-seguridad-del-pod-y-de-la-red.md) vuelve sobre eso), y Grafana no sale a
internet a buscar actualizaciones ni a reportar uso.

`allowUiUpdates: false` es la regla de *como código*: lo que se cambie en la interfaz no se guarda. Si un
panel nuevo vale, se exporta su JSON al chart y se despliega; la anotación `checksum/provisioning`
reinicia Grafana con el tablero nuevo.

```bash
task obs:on -- dashboards
```

Con el tráfico de fondo a tres visitas por segundo, cuatro minutos después, el tablero dice esto (los
valores de la última muestra):

```text
Peticiones por segundo   catalog 3.64 req/s · pricing 3.51 · inventory 0.644 · replenish 0
Errores (5xx)            catalog 0% · inventory 0% · pricing 0%
Latencia p95             pricing 4.75 ms · catalog 24.5 ms · inventory 87.0 ms
Ventas por minuto        lab 28.8
Memoria por pod          inventory 212 MiB · replenish 45.4 · catalog 43.8 · pricing 18.8 · storefront 7.18
```

`replenish` en cero es correcto: con 500 unidades por producto, ninguna venta deja la existencia bajo el
umbral. Y lo que no se ve en el texto se ve en el tablero: el p95 de `inventory` es el de la venta, que
espera a `catalog` y a `pricing`.

### 5.5 Los interruptores, y lo que cuesta cada pieza

Los interruptores existen desde la [Fase 13](13-helm-el-paquete.md) como valores del chart; desde aquí instalan algo. Para no
tener que acordarse de pasarlos en cada `task deploy`, `task obs:on` los guarda en `.observability.json`
(fuera de git: es el estado de tu laboratorio, no del curso), y `task deploy` lo suma a los valores:

```bash
task obs:status
```

```text
metrics     encendida  Prometheus
dashboards  encendida  Grafana
logs        apagada    Loki y Fluent Bit
traces      apagada    Tempo
```

`task obs:off -- dashboards` apaga Grafana y redespliega. Encender `dashboards` enciende también `metrics`:
un Grafana sin Prometheus no tiene qué mostrar.

**Y esta fase tiene un costo que el laboratorio cobró en vivo.** Con el sistema en `lab` a dos réplicas,
Prometheus recién encendido, Grafana arrancando y k6 haciendo diez visitas por segundo, la máquina virtual
de 4 GiB se ahogó: en un minuto k6 llegó a cien usuarios virtuales esperando, la API del cluster dejó de
contestar (`TLS handshake timeout`), Docker no respondió durante unos ocho minutos y los pods de un worker
se reiniciaron por sondas. Adentro de la máquina, la memoria intercambiándose a disco sin parar.

La causa tenía dos partes. Una, la de siempre: cada pieza suma, y la sección 8 dice cuánto. La otra no
era del curso: **el Kubernetes propio de Docker Desktop estaba encendido** en la misma máquina virtual, con
su nodo, su registry y su balanceador, ocupando 764 MiB de memoria y 115 más de swap, que el presupuesto de
[a01](a01-el-laboratorio.md) no contempla.
Si lo tienes encendido y no lo usas, apágalo antes de esta parte (Settings → Kubernetes); si lo usas,
dale a la máquina virtual esa memoria de más.

Desde aquí, la fase corre en el cluster `lab` con los valores de `minimo` (una réplica por servicio), que
alcanza para todo lo que mide:

```bash
task deploy CLUSTER=lab -- minimo
```

---

## 🔁 6. Los otros tres: donde no es mecánico

**`inventory` (Spring Boot): Actuator, pero solo para esto.** En la [Fase 15](15-salud-y-recursos.md), G4 dejó fuera a Actuator porque
su salud responde `{"status":"UP"}` y el contrato pide `ready`. Para métricas, en cambio, Actuator con
Micrometer es lo que el framework trae, y pelearse con él sería absurdo. Se agrega con tres decisiones
en `application.properties`:

```properties
management.endpoints.web.base-path=/
management.endpoints.web.exposure.include=prometheus
management.endpoints.web.path-mapping.prometheus=metrics
management.metrics.distribution.percentiles-histogram.http.server.requests=true
```

Las tres primeras ponen el endpoint en `/metrics` (no en `/actuator/prometheus`) y **no exponen nada
más**: ni `/health` de Actuator, ni `/env`, ni `/heapdump`. La cuarta es la que el prompt no puede
olvidar: sin ella, Micrometer publica un resumen (cuenta, suma y máximo) y **no hay buckets** de los
cuales sacar un p95. Y dos diferencias que el tablero absorbe: Spring agrega tres etiquetas propias
(`outcome`, `error`, `exception`), y sus buckets no son once sino **69 por combinación**. En reposo,
`inventory` publica 1.067 muestras por scrape; `pricing`, 132.

`inventory` también trae la primera métrica de negocio del sistema, un contador que `SalesController`
incrementa con cada venta registrada:

```java
this.sales = Counter.builder("lab.sales").description("Ventas registradas").register(registry);
…
sales.increment();
```

En Prometheus se llama `lab_sales_total`, y es el panel de ventas por minuto. **Ningún cluster te la va a
dar**: es exactamente la tesis de la sección 4.

**`replenish` (Node): la librería que ya no es.** El prompt nombraba `prom-client`, la librería que usa
casi todo Node desde hace una década. Se instaló con un aviso:

```text
npm warn deprecated prom-client@15.1.3: prom-client has been replaced by @prometheus-io/client
```

La heredera oficial, `@prometheus-io/client`, tiene la misma API, y pasó la suite sin cambiar una línea.
El patrón de la ruta sale de `req.route.path` en el evento `finish` de la respuesta (antes no existe), con
`:id` cambiado a `{id}` para que se escriba como en los otros tres.

**`catalog` (PHP-FPM): nada sobrevive a una petición.** Este es el que enseña algo de su runtime. Una
librería de métricas guarda los contadores en memoria y los escribe cuando alguien pide `/metrics`. En Go,
Java y Node, esa memoria es la del proceso, que vive mientras el contenedor vive. En PHP-FPM, **cada
petición la atiende un proceso hijo que olvida todo al terminar**: es el modelo *share-nothing*, y es la
razón por la que PHP escala tan fácil. Para las métricas es un problema.

Con el almacenamiento en memoria del proceso, `catalog` pasa la suite de G6 (el endpoint existe y tiene
el formato) y **no cuenta nada**:

```text
=== METRICS_STORAGE=memory · 200 peticiones a /products, de a 10 en paralelo
(ninguna línea con uri="/products")
=== METRICS_STORAGE=apcu · 200 peticiones a /products, de a 10 en paralelo
http_server_requests_seconds_count{method="GET",uri="/products",status="200"} 200
```

Cero de doscientas. Ni siquiera el propio `/metrics` aparece, porque se mide después de escribirlo. La
solución es **APCu**, una memoria compartida entre los hijos del mismo FPM, que no viene con la imagen de
PHP: se compila desde PECL en la misma capa que `pdo_pgsql`.

```dockerfile
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS postgresql-dev \
 && docker-php-ext-install pdo_pgsql \
 && pecl install apcu-5.1.28 && docker-php-ext-enable apcu \
 && apk del .build-deps && apk add --no-cache libpq
```

Y queda una consecuencia que conviene saber: APCu es de **un** FPM. Dos réplicas de `catalog` tienen dos
APCu, y Prometheus las suma como dos pods, que es lo correcto. Lo que no funcionaría es un pod con dos
FPM, o un contador que tenga que sobrevivir al reinicio del contenedor: para eso, un almacenamiento
afuera (Redis), que la librería también soporta.

---

## 🪞 7. Tu instinto de compose dice… y las apuestas

El instinto, en su mejor versión: *"las métricas son un tablero bonito que se instala al final; lo que
cuesta es la aplicación"*. Las apuestas, escritas antes de ejecutar:

> 🪞 **Apuesta antes de ejecutar.** En el perfil `lab`, con un scrape cada 15 s, Prometheus ocupa menos de
> 100 MiB después de 20 minutos; Grafana, sola, más de 300 MiB: más que Prometheus y que `pricing`,
> `catalog` y `replenish` juntos.
>
> **Resultado: empate.** Prometheus quedó en 99 MiB a los 20 minutos con tráfico, por debajo y por poco, y
> con una réplica por servicio, no dos (la sección 5.5 dice por qué). Grafana, en 231: **menos de 300**, y
> aun así más que Prometheus y que los otros tres servicios juntos (112).

> 🪞 **Apuesta antes de ejecutar.** Si `pricing` etiqueta con la ruta cruda en vez del patrón, 2.000 SKU
> distintos multiplican por más de 100 sus series, y la memoria de Prometheus crece más de un 50 %.
>
> **Resultado: ganada**, y con margen: por 228 las series y un 165 % la memoria (sección 9).

> 🪞 **Apuesta antes de ejecutar.** Con el almacenamiento en memoria del proceso, el contador de `catalog`
> cuenta menos del 30 % de las peticiones que recibió (cinco hijos de FPM, cada uno con el suyo); con APCu,
> las cuenta todas.
>
> **Resultado: perdida por quedarse corta.** No es un hijo de cinco: es **ninguno**. Cero de doscientas,
> porque el hijo no guarda nada entre una petición y la siguiente (sección 6).

> 🪞 **Apuesta antes de ejecutar.** A la tasa de B-16, el p95 de `pricing` con el histograma no empeora más
> de un 5 % respecto de G5.
>
> **Resultado: sin decidir.** Con la máquina virtual intercambiando memoria a disco, el p95 de la misma
> imagen saltó entre 38 y 106 ms de una corrida a otra, y un 5 % queda muy por debajo de ese ruido. Lo que sí
> se pudo leer es la mediana, que no se movió: 1,8–2,3 ms con G5 y 1,8–2,2 ms con G6.

> 🪞 **Apuesta antes de ejecutar.** Un pod que muere entre dos scrapes se lleva lo que contó desde el
> último; `rate()` absorbe el reinicio del contador sin mostrar una caída a cero.
>
> **Resultado: ganada.** Con tráfico, borré el pod de `inventory`. `lab_sales_total` crudo cayó a 0 y volvió
> a subir; `increase(lab_sales_total[6m])` dio 32,3, contra 32,7 ventas registradas (los 201 de `/sales`), y
> las ventas por minuto nunca bajaron de 2,7.

Las entradas están en [INSTINTOS.md](INSTINTOS.md#las-métricas-son-un-tablero-que-se-instala-al-final).

---

## 📏 8. La medición: lo que cuesta cada pieza

> 📏 **Medición B-00, sexta entrega · La observabilidad, pieza por pieza** · cluster `lab` con los valores
> de `minimo` (una réplica por servicio) · Docker Desktop (Engine 29.8.0), máquina virtual de 4 GiB **con el
> Kubernetes de Docker Desktop encendido** · kind 0.33.0, nodo 1.36.4 · MacBook Pro M1 Pro, 32 GB, macOS
> arm64 · 3 ciclos de apagar y encender, cada lectura 60 s después de encender · verificado el 04/10/2026
>
> | *Working set*, en MiB | recién encendida | a los 20 min, con 2 visitas/s |
> |---|---|---|
> | Prometheus, sola | 44 (43–73) | — |
> | Prometheus, con Grafana | 58 (52–90) | 99 |
> | Grafana | 252 (248–254) | 231 |
>
> Mediana, con mínimo y máximo entre paréntesis. Reproducir: `task obs:off -- all`, y `task obs:on` con
> cada pieza.

**Grafana cuesta entre tres y cinco veces lo que cuesta Prometheus**, y es la que menos falta hace para
saber si algo va mal: Prometheus tiene su propia interfaz de consultas. En la verificación de preparación
del curso, en reposo y sin servicios, Grafana había ocupado 359 MiB ([a01](a01-el-laboratorio.md)); aquí, entre 231 y 254.
Prometheus, en cambio, **crece con lo que guarda**: 44 MiB recién encendido y 99 a los veinte minutos, con
unas 3.700 series. La sección 9 muestra qué lo hace crecer de verdad.

Falta una columna, y es a propósito: **lo que sube la máquina virtual** al encender cada pieza, que es como
mide B-00 en las entregas anteriores. Con la máquina intercambiando memoria a disco (sección 5.5), la
memoria usada se quedó en 2,6–2,7 GiB encendiera lo que encendiera: lo que entraba, empujaba otra cosa al
swap. Esa lectura se repite sin el Kubernetes de Docker Desktop, y queda como pendiente en a01.

---

## ⚰️ 9. Autopsia: la etiqueta con la ruta cruda

**La decisión, con su mejor argumento.** Un `pricing` que etiqueta cada petición con su ruta tal cual:
`uri="/prices/SKU-0001"`. *"Así sé qué producto se consulta más, y no tengo que pensar en patrones."* Es lo
que sale de usar `r.URL.Path` en lugar de `r.Pattern`, y es la primera versión de casi cualquier middleware
escrito a mano.

**Por qué era razonable.** Con los ocho productos del catálogo sembrado, son ocho rutas: nadie lo nota. Y
la pregunta (*¿qué producto se consulta más?*) es legítima.

**Qué pasó después, con número.** La imagen de `pricing` trae un interruptor solo para medir esto
(`METRICS_URI=raw`). Con tráfico de 2.000 SKU distintos, uno por petición, primero con el patrón y después
con la ruta cruda:

```text
                                  con el patrón    con la ruta cruda   5 min después
series de pricing                       123             28.095            28.095
series totales en Prometheus          2.447             30.567            30.567
memoria de Prometheus (heap, MiB)          65                118               172
```

**Por 228 las series de `pricing`**, y Prometheus pasó de guardar 2.447 series a 30.567. Cada ruta nueva
no es una serie: son catorce (once buckets, el infinito, la suma y la cuenta), por cada estado distinto. Y la
memoria siguió subiendo después de la carga, de 118 a 172 MiB, mientras Prometheus las mantenía en su
bloque en memoria: un 165 % más que con el patrón. Eso, con 2.000 productos; el catálogo de La Vecina
tiene unas 9.500 referencias (historia §7), y una etiqueta con la droguería encima las multiplicaría por 263.

**Cuánto cuesta salir, con número.** Volver al patrón es una línea, y las series viejas dejan de recibir
datos; pero **no desaparecen**: Prometheus las guarda hasta que pasa su retención. En este laboratorio, dos
días. En un Prometheus administrado que cobra por serie, el mes entero.

**Qué lo habría cambiado.** La regla que trae el contrato de G6: **una etiqueta solo lleva valores de un
conjunto chico y conocido**: un método, un patrón de ruta, un estado, una droguería. Nunca un identificador.
Y la pregunta *¿qué producto se consulta más?* tiene otra respuesta: un log por petición con el SKU
([Fase 18](18-logs.md)), o una consulta a la base.

**Antes y después, con números:** 123 series de `pricing` con el patrón y 28.095 con la ruta cruda; 65 MiB de
Prometheus contra 172.

---

## 📖 10. Traducción

| En compose o en un servidor | En Kubernetes, con Prometheus | Lo que cambia |
|---|---|---|
| `docker stats` | cAdvisor, por el proxy de la API (`container_memory_working_set_bytes`) | lo mismo, guardado en el tiempo y consultable |
| un agente que empuja a un servidor (Nagios, Zabbix) | Prometheus que va a buscar (*pull*) | el servicio no sabe quién lo mide; Prometheus tiene que saber dónde está |
| la lista de servidores en un archivo | `kubernetes_sd_configs` con `relabel_configs` | la lista sale de la API y cambia sola con cada rollout |
| un tablero armado a mano en la interfaz | el JSON del tablero en el chart, provisionado al arrancar | se versiona, se revisa y se despliega como el código |
| un `ServiceMonitor` del operador de Prometheus | el `scrape_config` que genera, escrito a mano | aquí se ve lo que el operador esconde ([a12](a12-operators-de-lectura.md)) |

Y al revés, porque el lector que viene de un cluster con operador lo necesita: un `ServiceMonitor` que
selecciona por labels un `Service` es, por dentro, un trabajo con `kubernetes_sd_configs` de rol
`endpoints` y un `relabel_configs` con un `keep` sobre esas labels. Las filas completas, en
[a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En la nube, casi nadie instala Prometheus y Grafana a mano: el proveedor los ofrece administrados, con
almacenamiento durable y retención por meses, y se cobran por serie guardada y por consulta. Esa factura
es la sección 9 con otra unidad: cada etiqueta con demasiados valores se paga todos los meses.

---

## 🩺 11. Incidentes de esta fase

La fase no reserva incidentes del cuaderno. Las dos roturas que trae —el contador de PHP que no cuenta y
la etiqueta con la ruta cruda— se miden en las secciones 6 y 9, y vuelven en los ejercicios.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Prometheus no es un sistema contable.** Un contador vuelve a cero cuando el pod reinicia, y `rate()`
aproxima; Prometheus no garantiza haber visto cada incremento. `lab_sales_total` sirve para ver que las
ventas por minuto se cayeron, **no para cerrar la caja**: las ventas de verdad están en la tabla `sales`.

**Las métricas no saben de individuos.** Una etiqueta por droguería (veinte valores) está bien; una por
producto (miles) ya cuesta; una por venta o por cliente rompe Prometheus. Para "¿qué pasó con la venta
SALE-000123?" están los logs de la [Fase 18](18-logs.md).

**Grafana es la pieza más cara de la observabilidad** y la menos necesaria en el día a día: Prometheus
tiene su propia interfaz para consultar, y la sección 8 dice cuánto cuesta cada una. En un portátil, el
tablero se enciende cuando se mira.

**Sin alertas, esto es un espejo retrovisor.** Un tablero que nadie mira a las 6:40 p. m. del 14 de
octubre no habría cambiado nada. Hace falta una regla (`ventas por minuto < X durante 5 min`), un
Alertmanager que la mande a algún lado, y **alguien de guardia que la reciba**. El laboratorio no tiene a
nadie a quien despertar, y por eso no se monta; la empresa sí.

**Cuándo NO un Prometheus propio:** una empresa sin nadie que lo opere (retención, disco, actualizaciones)
está mejor con uno administrado; un servicio que corre una vez por noche (un `CronJob`) no se mide con
*pull*, porque cuando Prometheus pasa ya no está, y para eso existe el *Pushgateway*. **Cuándo sí:**
servicios que viven, con tráfico continuo, y un equipo que va a mirar el tablero y responder a lo que dice.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso con un puerto. El orquestador
te dio una API que sabe dónde están los pods, y cAdvisor, que mide cada contenedor. **Te tocó a ti**
decidir qué contar y con qué etiquetas, instrumentar cuatro runtimes para que hablen igual, el APCu de
PHP, y apagar el tablero cuando no lo miras.

---

## ⚠️ 13. Errores comunes y diagnóstico

**El blanco aparece `down` con `server returned HTTP status 404`.** El servicio todavía es de G5, o la
ruta de métricas no es `/metrics` (`/actuator/prometheus` en un Spring sin el `path-mapping`).

**El blanco no aparece.** Las labels del pod no pasan el `keep` (`part-of`, `component`), o el puerto no
se llama `http`. La página `Status → Service discovery` de Prometheus muestra los candidatos descartados
con sus metadatos.

**`histogram_quantile` devuelve `NaN`.** No hubo peticiones en la ventana (cero dividido cero). Con tráfico,
desaparece; en un tablero, se lee como "sin datos" y está bien.

**El p95 de `inventory` sale escalonado.** Sus buckets son otros que los de los demás (69 contra 11); el
percentil se interpola dentro de un bucket, y con buckets anchos el valor salta entre los umbrales.

**Grafana muestra el tablero viejo después de cambiar el JSON.** El `ConfigMap` cambió pero el pod no:
la anotación `checksum/provisioning` lo reinicia solo si el cambio pasó por `task deploy`.

**Todo se pone lento y la API no contesta.** La máquina virtual se quedó sin memoria (sección 5.5).
`task obs:off -- dashboards` primero; después, mira si hay otra cosa ocupándola.

---

## 📋 14. Checklist de validación

```text
[ ] task conformance TARGET=cluster PROFILE=lab -- G6, con los cuatro en verde
[ ] task obs:on -- metrics, y los blancos de backends, cadvisor y prometheus en up
[ ] task obs:on -- dashboards, y el tablero La Vecina · RED con datos del tráfico de fondo
[ ] task obs:status refleja lo encendido; task obs:off -- dashboards lo apaga
[ ] catalog con METRICS_STORAGE=memory no cuenta nada; con APCu cuenta todo
[ ] la autopsia: series y memoria de Prometheus con la ruta cruda, y de vuelta
[ ] la memoria de cada pieza, encendida y apagada
```

---

## 🧪 15. Ejercicios (24)

La mitad de diagnóstico o medición; varios con `catalog`, `inventory` y el tablero. Para los que piden
tráfico, `k6 run bench/trafico/la-vecina.js` (o con `-e RATE=… -e DURATION=…`).

## 🟢 Fácil — leer lo que el sistema cuenta (1–7)

### 🟢 Ejercicio 1 — `/metrics` por la puerta
Lee el `/metrics` de `pricing` y de `replenish` por `api.localhost:8080`, después de una lectura de precios.

**Criterio:** en los dos, una línea `http_server_requests_seconds_count` con el `uri` de la ruta en forma
de patrón.

<details><summary>Solución</summary>

`curl -s -H 'Host: api.localhost' http://127.0.0.1:8080/pricing/metrics | grep _count`, igual con
`/replenish/metrics`. Que responda por la puerta es lo que la [Fase 20](20-seguridad-del-pod-y-de-la-red.md) cierra.
</details>

### 🟢 Ejercicio 2 — Encender y apagar
Enciende las métricas, después los tableros, y apaga los tableros.

**Criterio:** `task obs:status` dice lo que corre, y `kubectl -n observability get pods` lo confirma en
cada paso.

<details><summary>Solución</summary>

`task obs:on -- metrics`, `task obs:on -- dashboards`, `task obs:off -- dashboards`. El archivo es
`.observability.json`; bórralo y el próximo `task deploy` apaga todo.
</details>

### 🟢 Ejercicio 3 — Los blancos
Abre `http://prometheus.localhost:8080/targets` y cuenta los blancos `up`.

**Criterio:** el número, explicado: cuántos backends, cuántos nodos de cAdvisor y Prometheus.

<details><summary>Solución</summary>

Con una réplica por servicio, cuatro backends, tres nodos y Prometheus: ocho. Con el perfil `lab`
completo, doce.
</details>

### 🟢 Ejercicio 4 — Una consulta
En la interfaz de Prometheus, la tasa de peticiones de `pricing` por ruta, en el último minuto.

**Criterio:** una serie por `uri`, sin las de `/health/*` si las filtras.

<details><summary>Solución</summary>

`sum by (uri) (rate(http_server_requests_seconds_count{service="pricing"}[1m]))`.
</details>

### 🟢 Ejercicio 5 — Las ventas por minuto
Con el tráfico de fondo, encuentra cuántas ventas hizo el sistema en los últimos cinco minutos.

**Criterio:** el número en el panel de ventas, y el mismo con una consulta.

<details><summary>Solución</summary>

`sum(increase(lab_sales_total[5m]))`. Compáralo con `select count(*) from sales` en la base de `inventory`:
se parecen, y no tienen por qué ser iguales (sección 12).
</details>

### 🟢 Ejercicio 6 — Cuánto guarda Prometheus
Encuentra cuántas series guarda Prometheus y cuántas aporta cada servicio.

**Criterio:** los dos números, y cuál de los cuatro aporta más.

<details><summary>Solución</summary>

`prometheus_tsdb_head_series` y `count by (service) ({job="backends"})`. `inventory`, por sus 69 buckets
por combinación (sección 6).
</details>

### 🟢 Ejercicio 7 — El tablero, en git
Cambia el título de un panel en el JSON del chart y despliega.

**Criterio:** Grafana reiniciado y el título nuevo, sin haber tocado la interfaz.

<details><summary>Solución</summary>

`charts/platform/charts/grafana/dashboards/la-vecina-red.json` y `task deploy -- minimo` (con
`CLUSTER=lab`). La anotación `checksum/provisioning` cambia y el `Deployment` reemplaza el pod.
</details>

## 🟡 Intermedio — llevar el patrón a otro sitio (8–14)

### 🟡 Ejercicio 8 — El p99
Agrega al tablero un panel con el p99 de cada servicio.

**Criterio:** el panel en el JSON del chart, con datos, y una frase sobre por qué el p99 de `catalog`
salta más que su p95.

<details><summary>Solución</summary>

La consulta del p95 con `0.99`. Con pocas peticiones por minuto, el p99 son una o dos peticiones: un solo
hijo de FPM ocupado lo mueve.
</details>

### 🟡 Ejercicio 9 — Una métrica de negocio en `replenish`
Haz que `replenish` cuente las órdenes de reposición creadas.

**Criterio:** `lab_replenishment_orders_total` en su `/metrics`, que sube con cada aviso de una venta.

<details><summary>Solución</summary>

Un `Counter` de `@prometheus-io/client` en `src/metrics.ts`, exportado, y un `inc()` en el controlador
después del `INSERT`. Es un cambio de contrato: primero el OpenAPI, después el código.
</details>

### 🟡 Ejercicio 10 — Menos buckets en `inventory`
Reduce los buckets del histograma de `inventory` a los once de los demás.

**Criterio:** `count(http_server_requests_seconds_bucket{service="inventory"})` baja, y el tablero sigue
funcionando.

<details><summary>Solución</summary>

`management.metrics.distribution.slo.http.server.requests=5ms,10ms,25ms,50ms,100ms,250ms,500ms,1s,2.5s,5s,10s`
y quitar `percentiles-histogram`. Menos series, y percentiles con la misma precisión que los otros tres.
</details>

### 🟡 Ejercicio 11 — El blanco que desaparece
Escala `replenish` a cero y mira los blancos. Después rompe su `/metrics` de otra forma: que el puerto
deje de llamarse `http`.

**Criterio:** la diferencia entre un blanco que no está y uno que está `down`, explicada.

<details><summary>Solución</summary>

Sin pods no hay candidatos: el blanco desaparece y `up{service="replenish"}` no existe (una alerta con
`up == 0` no salta; con `absent(up{service="replenish"})`, sí). Con el puerto renombrado, el pod existe y
el `keep` lo descarta: tampoco aparece, y la página de *Service discovery* lo muestra descartado.
</details>

### 🟡 Ejercicio 12 — Cada cinco segundos
Cambia el intervalo de scrape a 5 s.

**Criterio:** cuántas muestras por segundo guarda Prometheus antes y después, y cuánta memoria ocupa a los
diez minutos.

<details><summary>Solución</summary>

`scrapeInterval` en los valores del subchart. `rate(prometheus_tsdb_head_samples_appended_total[1m])` se
triplica; las series no cambian. La resolución sube, y el costo también.
</details>

### 🟡 Ejercicio 13 — La segunda cadena en el tablero
Instala `tenant-b` y sepárala en el tablero con la variable `Cadena`.

**Criterio:** el panel de peticiones con las dos cadenas, sin haber cambiado nada de Prometheus.

<details><summary>Solución</summary>

`task deploy TENANT=tenant-b -- minimo` (con su base). El trabajo ya busca en `apps-b`, y la etiqueta
`chain` sale de `app.kubernetes.io/instance`. Mira la memoria antes: la segunda cadena suma lo que dice
[a01](a01-el-laboratorio.md).
</details>

### 🟡 Ejercicio 14 — El contador que vuelve a cero
Con el tráfico de fondo, borra el pod de `inventory`. Mira `lab_sales_total` crudo y con `increase`.

**Criterio:** el crudo cae a cero; `increase(lab_sales_total[5m])` no muestra una caída.

<details><summary>Solución</summary>

`rate` e `increase` detectan que el contador bajó y lo tratan como un reinicio. Lo que se pierde son las
ventas contadas desde el último scrape hasta la muerte del pod.
</details>

## 🟠 Difícil — diagnosticar (15–20)

### 🟠 Ejercicio 15 — `catalog` no cuenta
Despliega `catalog` con `METRICS_STORAGE=memory` y genera tráfico. **Predice** qué muestra el tablero.

**Criterio:** el diagnóstico, con el `/metrics` del pod como evidencia, y de vuelta a APCu.

<details><summary>Solución</summary>

El panel de `catalog` queda vacío, aunque el blanco está `up` y el endpoint responde: cada hijo de FPM
olvida sus contadores al terminar la petición (sección 6).
</details>

### 🟠 Ejercicio 16 — El promedio de los p95
Con dos réplicas de `pricing`, calcula el promedio de los p95 de cada pod y compáralo con el p95 del
servicio.

**Criterio:** los dos números, y por qué el segundo es el correcto.

<details><summary>Solución</summary>

`avg(histogram_quantile(0.95, sum by (pod, le) (rate(…[5m]))))` contra `histogram_quantile(0.95, sum by
(le) (rate(…[5m])))`. El percentil no se promedia: se calcula sobre los buckets sumados.
</details>

### 🟠 Ejercicio 17 — Prometheus sin memoria
Baja el límite de Prometheus a 64 MiB y genera la autopsia de la sección 9.

**Criterio:** el diagnóstico desde `kubectl describe` y desde el panel de memoria (si alcanza a verse).

<details><summary>Solución</summary>

`OOMKilled`, y en el tablero un hueco: el que mide se murió. Los datos del `emptyDir` sobreviven al
reinicio del contenedor y no al del pod.
</details>

### 🟠 Ejercicio 18 — El hueco
Borra el pod de Prometheus y mira el tablero de la última media hora.

**Criterio:** qué se perdió y por qué; qué cambiaría con un `PersistentVolumeClaim`.

<details><summary>Solución</summary>

Todo lo anterior: el `emptyDir` es del pod. Con un PVC (y la estrategia `Recreate`, que ya tiene), la
historia sobrevive al pod; con dos días de retención en un portátil, decide si vale el disco.
</details>

### 🟠 Ejercicio 19 — Lo que se ve desde afuera
Desde tu máquina, lista todas las rutas de los cuatro servicios que aparecen en sus `/metrics`.

**Criterio:** la lista, y una frase sobre qué le cuenta eso a alguien de afuera.

<details><summary>Solución</summary>

Los `uri` de `http_server_requests_seconds_count`, más la versión del runtime y las métricas de proceso.
Es un mapa del sistema. La [Fase 20](20-seguridad-del-pod-y-de-la-red.md) lo cierra.
</details>

### 🟠 Ejercicio 20 — ¿Quién manda el 422?
Con el tráfico de fondo, encuentra qué servicio responde 4xx, a qué ruta y por qué.

**Criterio:** la consulta y la explicación desde el negocio.

<details><summary>Solución</summary>

`sum by (service, uri, status) (rate(http_server_requests_seconds_count{status=~"4.."}[5m]))`: `inventory`
en `/sales` con 422 (el `SKU-9999` del tráfico), y `catalog` en `/products/{sku}` con 404, que es la misma
venta vista desde el vecino.
</details>

## 🔴 Muy difícil — medir y diseñar (21–24)

### 🔴 Ejercicio 21 — Lo que cuesta instrumentar `inventory`
Repite la medición de la sección 8 para `inventory`: p95 con G5 y con G6, a la misma tasa.

**Criterio:** tres corridas por imagen, con la tabla y una conclusión que no pase de lo que miden.

**Rúbrica:** las mismas condiciones para las dos imágenes; la memoria de cada una, además del p95 (Actuator
y Micrometer no son gratis); y si la diferencia es menor que la dispersión, decirlo.

### 🔴 Ejercicio 22 — Una alerta sin destinatario
Escribe una regla de Prometheus que se encienda si las ventas por minuto caen a cero durante cinco minutos
con tráfico en la puerta.

**Criterio:** la regla en el `ConfigMap` del chart, en estado `firing` en la interfaz cuando apagas
`pricing`.

**Rúbrica:** la condición combina ventas y tráfico (sin tráfico, cero ventas es normal); y la pregunta de
la sección 12: ¿a quién le llega, y qué hace con ella?

### 🔴 Ejercicio 23 — Las ventas por droguería
Agrega la droguería como etiqueta de `lab_sales_total` y mide cuántas series suma, con la segunda cadena
encendida.

**Criterio:** las series antes y después, y una regla escrita para decidir qué etiqueta sí y cuál no.

**Rúbrica:** 20 y 40 droguerías son cientos de series y están bien; el producto (miles) multiplicado por la
droguería ya no; el número que decide es el producto de los valores de todas las etiquetas.

### 🔴 Ejercicio 24 — El tablero para Germán
Diseña un tablero que conteste la pregunta de la sección 1: *¿a qué hora nos enteramos?*

**Criterio:** en el chart, como código; con tráfico de fondo y `pricing` apagado a mano, el tablero muestra
el problema en menos de un minuto, sin abrir otro.

**Rúbrica:** las ventas por minuto contra la misma hora de antes, la proporción de 503 de `inventory` y la
latencia de la venta, en ese orden; nada de CPU en la primera fila.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Prometheus, *Configuration* (`kubernetes_sd_config` y `relabel_config`): https://prometheus.io/docs/prometheus/latest/configuration/configuration/
- Prometheus, *Metric and label naming*: https://prometheus.io/docs/practices/naming/
- Prometheus, *Histograms and summaries*: https://prometheus.io/docs/practices/histograms/
- Prometheus, *Instrumentation* (qué contar y con qué etiquetas): https://prometheus.io/docs/practices/instrumentation/
- Grafana, *Provisioning*: https://grafana.com/docs/grafana/latest/administration/provisioning/
- Spring Boot, *Metrics* (Actuator y Micrometer): https://docs.spring.io/spring-boot/reference/actuator/metrics.html
- promphp, *prometheus_client_php*: https://github.com/PromPHP/prometheus_client_php
- Prometheus, *client_js* (la heredera de `prom-client`): https://github.com/prometheus/client_js

**Libros y ensayos**

- Brian Brazil, *Prometheus: Up & Running*, 2.ª edición (2023): los capítulos de instrumentación y de
  descubrimiento de servicios.
- Betsy Beyer y otros (eds.), *Site Reliability Engineering* (2016), *Monitoring Distributed Systems*
  (las cuatro señales doradas): https://sre.google/sre-book/monitoring-distributed-systems/
- Tom Wilkie, *The RED Method: How to instrument your services* (2018): https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/

**Orden de lectura sugerido:** antes, el capítulo de SRE (qué mirar); durante, *Metric and label naming*
con la sección 5.2 delante; después, *Histograms and summaries*, que explica por qué el percentil se
calcula en Prometheus y no en el servicio.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 17 (cluster lab, valores de minimo)

  apps            pricing · inventory · catalog · replenish en :g6, storefront en :g5
                  /metrics en los cuatro: http_server_requests_seconds (method, uri, status)
                  inventory: lab_sales_total; catalog: APCu en la imagen
  observability   Prometheus (charts/prometheus: backends, cadvisor y él mismo; 2 días en emptyDir)
                  Grafana (charts/grafana: la fuente de datos y el tablero La Vecina · RED como código)
  gateway         el listener admite rutas de observability: prometheus.localhost, grafana.localhost
  tareas          task obs:on | obs:off | obs:status, con .observability.json (no versionado)
  bench/trafico   la-vecina.js, el tráfico de fondo de los tableros
```

> **La señal de que quedó bien:** *"Sé cuántas ventas por minuto hace el sistema sin abrir un log, puedo
> decir qué etiqueta no le pondría nunca a una métrica y cuánto cuesta ponérsela, y apago Grafana cuando
> no la estoy mirando."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, la suite de G6 pasando y `git status`
> limpio:
>
> ```bash
> git tag -a fase-17-metricas-y-dashboards -m "F17 cerrada: G6, /metrics con el histograma común en los cuatro runtimes y lab_sales_total; APCu en catalog; Prometheus con scrape_config a mano y Grafana como código en el chart; interruptores obs:on/obs:off; la autopsia de la cardinalidad"
> ```
>
> Commits con prefijo `f17:`.

---

## 📌 Pendientes sugeridos

- **F18:** qué venta falló, no cuántas: los logs JSON y Loki.
- **F20:** `/metrics` responde por la puerta pública; Grafana entra anónimo con rol de `Editor`.
- **F22:** el tablero de esta fase es el que va a mostrar el circuito abierto.
- **F23:** el tiempo de cada salto de la venta, que el histograma solo da por servicio.
