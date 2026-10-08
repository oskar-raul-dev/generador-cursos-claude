# 🔎 Fase 18 — Logs: qué pasó con esa venta

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 18 de 27 · Parte III — Operarlo · **media**
> **Perfil:** el cluster `lab` (control-plane y dos workers), con los valores de `minimo` (una réplica por servicio) · **Observabilidad encendida:** logs (Loki y Fluent Bit), y con ellos Grafana y Prometheus
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: el recolector lee los archivos del nodo, que son del runtime del cluster
> **Servicios que toca:** los cuatro backends · **Paso de generación:** G7 · Logs estructurados
> **Depende de:** [Fase 17](17-metricas-y-dashboards.md) · **Habilita:** [Fase 19](19-tls-y-certificados.md)
> **Incidentes que reserva:** ninguno · **Medición:** ninguna con identificador; las de esta fase quedan en sus secciones
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 04/10/2026 · macOS arm64
> **Objetivo:** que cada servicio escriba una línea JSON por evento a su salida estándar, con los mismos campos en los cuatro runtimes; que un recolector por nodo los lleve a Loki sin que ningún servicio lo sepa; y encontrar una venta en los cuatro servicios con una sola consulta.

---

## 🧭 1. Dónde estamos

La [Fase 17](17-metricas-y-dashboards.md) dejó un tablero que dice cuántas ventas por minuto hace el sistema y cuántas fallan. Es
la primera de las tres preguntas: **saber que algo va mal**. Esta fase contesta la segunda: **qué**.

Fabio Arenas, de operaciones, le trae a Valentina la pregunta en la forma en que llega siempre, sin
números ni tableros:

> *"Una regente de Duitama dice que a las 10 y media vendió un Dolex, que la caja le dijo que no, y que el
> cliente se fue con el producto. ¿Se vendió o no se vendió? Porque si no se descontó, el inventario de
> esa droguería ya está mal."*

El tablero dice que a esa hora hubo tres ventas fallidas. No dice cuál era la de Duitama, ni por qué
falló, ni en cuál de los cuatro servicios. Para eso hacen falta los logs: **un evento por línea, con su
contexto**. Y en un cluster, con réplicas que van y vienen, los logs tienen que estar en algún lado
cuando alguien los busque, que casi nunca es en el momento.

---

## 🎯 2. Objetivos de esta fase

1. Generar G7: los cuatro servicios logueando JSON a stdout, con los mismos campos, y la línea de cada
   petición con su `request_id`.
2. Entender por qué la regla es *a stdout, nunca a archivo*, y lo que cuesta cumplirla en Java y en PHP.
3. Instalar Fluent Bit como `DaemonSet` y Loki, y ver cómo un recolector por nodo encuentra los logs sin
   que nadie le diga dónde están.
4. Encontrar una venta en los cuatro servicios con una consulta de LogQL.
5. Medir lo que pasa cuando un identificador se vuelve etiqueta, que es la versión de los logs del error
   más caro de la [Fase 17](17-metricas-y-dashboards.md).

---

## 🚫 3. Qué NO entra todavía

- **Trazas** → [Fase 23](23-grpc-y-el-balanceo.md). El `request_id` de esta fase es la correlación pobre: dice que cuatro líneas son
  de la misma venta, no cuánto tardó cada salto ni en qué orden. Es a propósito.
- Alertas sobre logs: por la misma razón que en la [Fase 17](17-metricas-y-dashboards.md), no hay a quién despertar.
- Los logs del plano de control, de los nodos y del patrimonio: Fluent Bit lee solo los namespaces de las
  cadenas.
- Retención y almacenamiento de Loki: dos días en un `emptyDir`, como Prometheus.
- Logs de auditoría (quién hizo qué en el cluster): son otra cosa, y otra fuente.

---

## 🧨 4. El problema, en el laboratorio

Lo que había al cerrar la [Fase 17](17-metricas-y-dashboards.md): cuatro servicios escribiendo texto, cada uno a su manera. Las mismas
peticiones, en los cuatro:

```text
2026/10/04 16:43:44 GET /prices 200                                                   ← pricing
2026-10-04T16:43:41.507Z  INFO 1 --- [inventory] [nio-8080-exec-1] c.c.lab.inventory.RequestLogFilter       : POST /sales 422
[2026-10-04 16:43:44] production.INFO: GET /products 200                              ← catalog (Laravel)
127.0.0.1 -  04/Oct/2026:16:43:44 +0000 "GET /index.php" 200                           ← catalog (PHP-FPM)
10.244.1.2 - - [04/Oct/2026:16:43:44 +0000] "GET /products HTTP/1.1" 200 1037 "-" "Grafana k6/2.3.0" "192.168.0.7"
GET /health/ready 200                                                                  ← replenish
```

Y `replenish` arranca con colores:

```text
[32m[Nest] 1  - [39m10/04/2026, 5:24:40 PM [32m    LOG[39m [38;5;3m[NestFactory] [39m[32mStarting Nest application...[39m
```

Cuatro formatos de fecha (uno sin año), tres formas de decir el nivel, ninguna forma de saber que el `POST
/sales 422` de `inventory` y el `GET /products/SKU-9999 404` de `catalog` son **la misma venta**. Para
la regente de Duitama habría que leer cuatro flujos con `kubectl logs`, a ojo, comparando horas que no
están escritas igual.

Y hay un problema de fondo, que no es de formato: `kubectl logs` lee lo que el kubelet guarda en el
nodo, y eso **se va con el pod**. Un pod borrado por un rollout se lleva sus logs; uno reiniciado deja
ver solo los de la vida anterior (`--previous`), una sola. La venta de Duitama fue hace dos horas, y desde
entonces hubo un despliegue.

> 🩻 **Esto sí funciona igual.** `docker logs` y `kubectl logs` leen lo mismo: lo que el proceso escribió
> en stdout y stderr, guardado por el runtime en un archivo del host. En compose, ese archivo es del
> motor; en el cluster, del nodo.

---

## 🧩 5. Logs, con `pricing`

### 5.1 La regla: a stdout, nunca a archivo

Un contenedor que escribe su log en un archivo propio rompe tres cosas a la vez. El runtime no lo ve, así
que `kubectl logs` no lo tiene. El recolector del nodo tampoco. Y el archivo crece **en la capa
escribible del contenedor**, que vive en el disco del nodo y se borra con el pod. La [Fase 01](01-primer-contenedor-y-dockerfile.md) lo dejó
anunciado; aquí está con número. `catalog` con el canal de log de fábrica de Laravel (`LOG_CHANNEL=stack`,
que escribe en `storage/logs/laravel.log`), mil peticiones:

```text
líneas JSON en la salida del contenedor (docker logs): 0
-rw-r--r--    1 www-data www-data    186899 Oct  4 19:31 laravel.log
1000 /app/storage/logs/laravel.log
$ docker diff t8-catalog | grep storage/logs
A /app/storage/logs/laravel.log
```

Cero líneas donde se buscan, 187 KB donde nadie mira, y nada que lo rote. La imagen de `catalog` tiene
`LOG_CHANNEL=stderr` desde la [Fase 04](04-empaquetar-los-cuatro-runtimes.md), que es por qué este problema no apareció antes. **La regla operativa
es una sola: el proceso escribe a su salida estándar, y de ahí en adelante es asunto de la plataforma.**

### 5.2 G7: una línea JSON por evento

El contrato de G7 está en el prompt de [a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g7): cada línea es un objeto JSON con `time`, `level`,
`service` y `msg`; la línea de cada petición agrega `method`, `uri` (el mismo patrón de ruta de la
[Fase 17](17-metricas-y-dashboards.md)), `path` (la ruta cruda, que en un log sí puede ir), `status`, `duration_ms` y `request_id`.

En `pricing` es casi gratis. Go trae `log/slog`, que escribe JSON con `time`, `level` y `msg`, y al
ponerlo como logger por defecto, los `log.Printf` que el servicio ya tenía salen en JSON sin tocarlos:

```go
func setupLogging() {
	handler := slog.NewJSONHandler(os.Stdout, nil)
	slog.SetDefault(slog.New(handler).With("service", "pricing"))
}
…
slog.Info("request", "method", r.Method, "uri", routeOf(r), "path", r.URL.Path, "status", rec.status,
	"duration_ms", float64(time.Since(start).Microseconds())/1000, "request_id", requestID(r))
```

```json
{"time":"2026-10-04T18:41:50.68819788Z","level":"INFO","msg":"request","service":"pricing","method":"GET","uri":"/prices","path":"/prices","status":200,"duration_ms":19.234,"request_id":"abc-123"}
```

Que la línea sea JSON cambia lo que se puede hacer con ella: un campo se filtra, se cuenta y se agrupa
sin expresiones regulares. *"Todas las peticiones de `pricing` con estado 5xx que tardaron más de 500 ms"*
es una consulta, no una búsqueda de texto.

### 5.3 El `request_id`, y quién lo pone

La correlación funciona así: la petición llega con una cabecera `X-Request-Id`; cada servicio la escribe
en sus líneas y, si llama a otro, **se la pasa**. Si no llegó ninguna, el servicio inventa una. En la venta,
el que llama es `inventory`: un interceptor de sus clientes HTTP copia el id a cada llamada a `catalog`,
`pricing` y `replenish`.

¿Y quién la pone en la petición original? La apuesta de esta fase decía que **Envoy, sin configurar
nada**, y así fue: la puerta genera un UUID para cada petición que entra y lo manda al servicio. Con eso,
una venta por la puerta deja esto en los cuatro:

```text
inventory  {"time":"2026-10-04T18:50:30.011736217Z","msg":"request","level":"INFO","request_id":"08a30398-…","method":"POST","uri":"/sales",…}
catalog    {"time":"2026-10-04T18:50:29.958+00:00","level":"INFO","service":"catalog","msg":"request","request_id":"08a30398-…","uri":"/products/{sku}",…}
pricing    {"time":"2026-10-04T18:50:29.977039342Z","level":"INFO","msg":"request","service":"pricing","uri":"/prices/{sku}",…,"request_id":"08a30398-…"}
replenish  {"time":"2026-10-04T18:50:30.086Z","level":"INFO","service":"replenish","msg":"request","method":"POST",…,"request_id":"08a30398-…"}
inventory  {"time":"2026-10-04T18:50:30.090110676Z","msg":"aviso a replenish: RO-0009 para SKU-0004 en DRO-011 (quedan 2)",…,"request_id":"08a30398-…"}
```

Y una sorpresa: la venta se mandó con `X-Request-Id: venta-de-prueba-f18`, y a `inventory` le llegó
`08a30398-…`. **Envoy reemplaza el id que trae el cliente** (en su configuración, `preserve_external_request_id`
está apagado por defecto). Es razonable para una puerta pública: un cliente no debería poder elegir el
identificador con el que se registran sus peticiones. Y es una trampa si esperabas buscar tu venta por el
id que tú mandaste.

### 5.4 Fluent Bit, un pod por nodo

Los servicios escriben a stdout y el runtime de cada nodo lo guarda en `/var/log/containers/`, un archivo
por contenedor, con un nombre que dice de quién es (`<pod>_<namespace>_<contenedor>-<id>.log`). Un
recolector solo tiene que estar en cada nodo y leer esa carpeta. **Ese es el `DaemonSet`**: un pod por
nodo, que aparece solo cuando llega un nodo nuevo. En un cluster de un nodo es indistinguible de un
`Deployment`; por eso la fase corre en `lab`.

Fluent Bit es el subchart `charts/fluent-bit/` (condición `observability.logs.enabled`, como Loki). Su
configuración, entera:

```yaml
pipeline:
  inputs:
    - name: tail
      path: /var/log/containers/*_apps_*.log,/var/log/containers/*_apps-b_*.log
      multiline.parser: cri
      tag: kube.*
  filters:
    - name: kubernetes        # las labels del pod, desde la API; y si la línea es JSON, sus campos
      match: kube.*
      merge_log: on
      keep_log: off
  outputs:
    - name: loki
      match: kube.*
      host: loki.observability.svc.cluster.local
      labels: job=fluent-bit, namespace=$kubernetes['namespace_name'], service=$kubernetes['labels']['app.kubernetes.io/name'], container=$kubernetes['container_name']
      remove_keys: kubernetes, stream, _p
      line_format: json
```

El pod monta `/var/log` del nodo con un `hostPath`, de solo lectura: es lo que le permite leer los logs de
los demás, y es exactamente lo que la [Fase 20](20-seguridad-del-pod-y-de-la-red.md) va a mirar con desconfianza.

```bash
task obs:on -- logs
kubectl -n observability get pods -l app.kubernetes.io/name=fluent-bit -o wide
```

```text
fluent-bit-gzg65   1/1   Running   0   lab-worker
fluent-bit-khzjg   1/1   Running   0   lab-worker2
```

Dos, no tres. El control-plane tiene un *taint* (`node-role.kubernetes.io/control-plane:NoSchedule`) y
este `DaemonSet` no lo tolera: "un pod por nodo" quiere decir **por nodo donde puede correr**. Aquí está
bien, porque ningún pod de `apps` corre en el control-plane; un recolector que tenga que leer los logs de
todo el cluster necesita la `toleration`.

### 5.5 Loki, y la venta de Duitama

Loki guarda las líneas agrupadas en **flujos** (*streams*): un flujo es una combinación de etiquetas
(`namespace`, `service`, `container`), y solo esas etiquetas se indexan. El contenido de la línea **no**
se indexa: se recorre al consultar. Es lo que hace a Loki barato, y lo que la sección 9 pone a prueba.

No tiene interfaz propia: se consulta desde Grafana (*Explore*, fuente Loki), que `task obs:on -- logs`
enciende junto con Prometheus. La venta, con una consulta:

```logql
{namespace="apps"} | json | request_id="08a30398-f67a-4566-9497-96fbc3d69f9f"
```

`{namespace="apps"}` elige los flujos (por etiqueta, rápido); `| json` convierte los campos de cada línea
en etiquetas de esa consulta, y el filtro se queda con las de la venta. Seis líneas, cuatro servicios. Y
la pregunta de Fabio, sin saber el id: *las ventas que fallaron en una droguería a una hora*:

```logql
{service="inventory"} | json | uri="/sales" | status >= 400
```

La línea de `inventory` no dice la droguería (no es un campo del contrato), y ese es el primer ejercicio
difícil de la fase.

---

## 🔁 6. Los otros tres: donde no es mecánico

**`inventory` (Spring Boot): JSON con una propiedad, el contrato con seis.** Spring Boot trae el log
estructurado de fábrica: `logging.structured.format.console=logstash` y todo sale en JSON. Pero con sus
nombres (`@timestamp`, `message`, `logger_name`, `thread_name`, `level_value`, `@version`, `tags`). Para el
contrato hacen falta renombrar, recortar y agregar, también con propiedades:

```properties
logging.structured.format.console=logstash
logging.structured.json.rename[@timestamp]=time
logging.structured.json.rename.message=msg
logging.structured.json.exclude=@version,level_value,thread_name,logger_name,tags
logging.structured.json.add.service=inventory
spring.main.banner-mode=off
```

La primera versión escribía `rename.@timestamp=time`, y Spring la ignoró sin decir nada: una clave de mapa
con `@` va entre corchetes. El banner de arranque, el dibujo en ASCII de Spring, sale en texto y hay que
apagarlo. El `request_id` va al **MDC** (el contexto del hilo), y así lo lleva cualquier línea de la
petición; el hilo virtual del aviso a `replenish` no lo hereda y se le copia a mano. Y queda una línea que
no se puede callar, cuando le pasas opciones a la JVM por `JAVA_TOOL_OPTIONS` (el `jvm.options` del chart,
vacío por defecto, que la [Fase 15](15-salud-y-recursos.md) usó para dimensionarla):

```text
Picked up JAVA_TOOL_OPTIONS: -XX:+UseSerialGC
```

La escribe la JVM antes de que exista ningún logger, y no tiene interruptor. Es la única excepción que acepta
el verificador de G7. Hubo otra que sí se pudo callar: la
carga de sqlite-jdbc dispara cuatro avisos en texto de Java 25 sobre acceso nativo, y
`--enable-native-access=ALL-UNNAMED` en el `CMD` los apaga.

**`catalog` (PHP-FPM y nginx): tres procesos que escriben, y solo uno es tuyo.** Monolog escribe JSON con
su `JsonFormatter`, pero con otros nombres (`message`, `level_name`, `datetime`) y el contexto anidado; el
formateador propio son veinte líneas. Lo que más costó estuvo alrededor:

- **PHP-FPM** escribe su propia línea de acceso en texto (`127.0.0.1 - 04/Oct/2026:… "GET /index.php" 200`)
  y sus avisos de arranque. La línea de acceso se apaga (`access.log = /dev/null`: la de la petición la
  escribe Laravel) y los avisos, con `log_level = warning`.
- **nginx** escribe la suya en su formato, y al arrancar, **22 líneas de texto**: el entrypoint de la imagen
  anunciando cada script y los `[notice]` del proceso. La línea de acceso se reescribe en JSON con
  `log_format … escape=json`; los avisos piden un `nginx.conf` principal propio (`error_log /dev/stderr
  warn`) y `NGINX_ENTRYPOINT_QUIET_LOGS=1`.

La apuesta de esta fase esperaba otro problema, el clásico: que PHP-FPM envolviera cada línea del hijo en
`WARNING: [pool www] child 12 said into stderr: …`. No pasó: la imagen oficial ya trae
`decorate_workers_output = no`. Sí trae otra cosa que conviene saber: `log_limit = 8192`, y una línea más
larga que eso **se corta**, y deja de ser JSON.

**`replenish` (Node): un logger propio, y listo.** Nest escribe texto con colores, también los mensajes de
su arranque. Un `LoggerService` de treinta líneas que escribe JSON, pasado a `NestFactory.create`, reemplaza
todo desde el primer mensaje. Es el más corto de los tres, y el único que necesitó escribir el logger.

La suite de G7 lo comprueba en dos mitades: Hurl manda peticiones con `X-Request-Id: g7-conformance-…`, y
`scripts/conformance/logs.py` lee el log reciente de los cuatro y revisa cada línea:

```bash
task conformance TARGET=cluster PROFILE=lab -- G7
```

```text
Success /suite/inventory.g7.hurl (3 request(s) in 281 ms)
…
pricing       10 líneas · ok
inventory     21 líneas · ok
catalog       12 líneas · ok
replenish     19 líneas · ok
```

---

## 🪞 7. Tu instinto de compose dice… y las apuestas

El instinto, en su mejor versión: *"el log es texto para leer cuando algo falla; `docker logs` y un `grep`
alcanzan"*. Las apuestas, escritas antes de ejecutar:

> 🪞 **Apuesta antes de ejecutar.** Spring Boot loguea JSON con una sola propiedad; Laravel, en cambio,
> escribe a un archivo por defecto, y PHP-FPM, cuando se le pide stderr, envuelve cada línea del hijo
> (`WARNING: [pool www] child N said into stderr: …`), lo que rompe el JSON.
>
> **Resultado: perdida en lo importante.** Spring sí sale en JSON con una propiedad, y para el contrato
> hicieron falta seis. Laravel sí escribe a un archivo por defecto (sección 5.1). Pero PHP-FPM no envolvió
> nada: la imagen oficial ya lo apaga. Lo que rompió el JSON en `catalog` fue lo que nadie apostó: la línea
> de acceso de FPM y las 22 líneas de arranque de nginx (sección 6).

> 🪞 **Apuesta antes de ejecutar.** En `lab`, Fluent Bit corre un pod por nodo (tres), cada uno con menos
> de 20 MiB.
>
> **Resultado: mitad y mitad.** Dos pods, no tres: el control-plane tiene un *taint* que el `DaemonSet` no
> tolera (sección 5.4). Y cada uno, entre 5,6 y 7,3 MiB.

> 🪞 **Apuesta antes de ejecutar.** Con una hora de logs del sistema en reposo y una carga corta, Loki
> ocupa menos de 150 MiB.
>
> **Resultado: ganada, sin llegar a la hora.** Entre 91 y 117 MiB en la primera media hora, con diez minutos
> de tráfico; 107 después de reiniciarlo y cinco minutos a cinco visitas por segundo. La hora no se completó:
> la autopsia de la sección 9 obligó a reiniciarlo, y el `emptyDir` empieza de cero.

> 🪞 **Apuesta antes de ejecutar.** Envoy agrega `x-request-id` a cada petición sin configurar nada; con que
> `inventory` lo reenvíe, una sola consulta de LogQL encuentra la venta en los cuatro servicios.
>
> **Resultado: ganada, con sorpresa.** Lo agrega, y también **reemplaza** el que trae el cliente (sección 5.3).

> 🪞 **Apuesta antes de ejecutar.** Poner `request_id` como etiqueta de Loki en vez de dejarlo en la línea
> multiplica los flujos por el número de peticiones, y Loki empieza a rechazar o a crecer en memoria con
> unos pocos miles.
>
> **Resultado: ganada, las dos cosas** (sección 9).

Las entradas están en [INSTINTOS.md](INSTINTOS.md#con-docker-logs-y-un-grep-alcanza).

---

## 📏 8. Lo que cuestan

Con el tráfico de fondo a dos visitas por segundo, diez minutos, en el cluster `lab` con una réplica por
servicio (crudos en la verificación de laboratorio, como siempre):

```text
fluent-bit (lab-worker)      5.6 MiB        Grafana       210 MiB
fluent-bit (lab-worker2)     5.6 MiB        Prometheus    106 MiB
loki                        91.4 MiB

líneas recibidas en 10 min:  5.853        bytes:  1.294.360        flujos:  6
```

**Fluent Bit es la pieza más barata de toda la observabilidad**: seis megas por nodo, cuarenta veces
menos que Grafana. Loki, con los logs de media hora, ocupa lo que Prometheus. Lo caro de los logs no está
en la memoria de quien los recibe: está en **lo que se escribe**. 1,3 MB en diez minutos, con un tráfico que
es una fracción mínima del de un día de la casa. Y **sin tráfico, el sistema no se calla**: en dos minutos
de reposo, 253 líneas y 54 KB, de las cuales 177 son sondas (el 70 %) y 40 son los scrapes de Prometheus
(otro 16 %). Unos 39 MB por día en los que nadie vendió nada.

Encendidos los logs, la observabilidad completa sin trazas sumaba 419–447 MiB en el laboratorio: Grafana,
la mitad.

---

## ⚰️ 9. Autopsia: el `request_id` como etiqueta

**La decisión, con su mejor argumento.** Agregar `request_id` a las etiquetas de cada flujo. *"Si es lo que
más busco, que esté indexado: las etiquetas son lo que Loki indexa."* Es exactamente lo que la sección 5.5
explicó, aplicado al revés.

**Por qué era razonable.** El argumento es correcto a medias: Loki sí busca rápido por etiqueta. Y en una
prueba con diez peticiones funciona perfecto.

**Qué pasó después, con número.** La etiqueta, en los valores del chart de Fluent Bit (`request_id=$request_id`),
y cinco minutos de tráfico a cinco visitas por segundo:

```text
                            antes      después de 5 min
flujos en Loki                  6                 5.001
memoria de Loki (MiB)          90                   145
errores de Fluent Bit           0         589 y 727 (uno por pod)
```

```text
maximum active stream limit exceeded when trying to create stream {container="php-fpm", …,
request_id="cf119a82-…", service="catalog"}, reduce the number of active streams (reduce labels or reduce label values)
[error] [engine] chunk '1-1791141060.69755506.flb' cannot be retried: task_id=2, input=tail.0 > output=loki.0
```

Loki tiene un límite de flujos activos por usuario (5.000 por defecto) y, al llegar, **rechaza** con un 429.
Fluent Bit reintenta, y cuando un bloque ya no se puede reintentar, lo descarta. ¿Cuánto se perdió?
Contando las peticiones de los últimos siete minutos de dos formas —las que contó cada servicio en
Prometheus, y las líneas `request` que llegaron a Loki—:

```text
pricing    prometheus=1958  loki=1506        catalog    prometheus=1993  loki=1536
inventory  prometheus=603   loki=493         replenish  prometheus=154   loki=116
```

**Cerca de una línea de cada cuatro, perdida**, en los cuatro servicios por igual: no solo las nuevas, porque
cada bloque descartado lleva líneas de todos. Y la etiqueta no sirvió ni para lo que se puso: la venta
de Duitama podía ser una de las perdidas.

**Cuánto cuesta salir, con número.** Quitar la etiqueta es una línea en los valores; los flujos ya creados
siguen contando contra el límite hasta que se vacían, y aquí hubo que reiniciar Loki para volver a cero (con
el `emptyDir`, perdiendo todo lo anterior). Con las etiquetas del chart y cinco minutos del mismo tráfico,
**6 flujos y entre 0 y 3 % de diferencia** entre Loki y Prometheus, que es lo que separa contar líneas de
extrapolar una tasa.

**Qué lo habría cambiado.** La regla de la [Fase 17](17-metricas-y-dashboards.md), que en Loki vale igual: **una etiqueta lleva valores de un
conjunto chico y conocido**. El `request_id` va **en la línea**, y `| json | request_id="…"` lo encuentra
recorriendo solo los flujos que las etiquetas eligieron. Es más lento que un índice, y alcanza.

**Antes y después, con números:** 6 flujos y ninguna línea perdida con las etiquetas del chart; 5.001
flujos, Loki de 90 a 145 MiB y una línea de cada cuatro perdida con el `request_id` como etiqueta.

---

## 📖 10. Traducción

| En compose o en un servidor | En Kubernetes, con Loki | Lo que cambia |
|---|---|---|
| `docker logs` | `kubectl logs` | lo mismo; con réplicas, una por vez (o `-l` con un selector), y se va con el pod |
| un archivo en `/var/log/miapp/` con `logrotate` | stdout, y el kubelet rota el archivo del nodo | el servicio no decide dónde ni cuánto; si escribe a un archivo propio, nadie lo ve |
| el agente de logs instalado en el servidor | un `DaemonSet` (Fluent Bit) | un pod por nodo, que aparece solo con cada nodo nuevo, y lee los logs de todos |
| `grep` sobre los archivos | LogQL: etiquetas para elegir flujos, filtros para el contenido | lo que se indexa son las etiquetas; el contenido se recorre |
| el id de transacción que el monolito ya tenía | `X-Request-Id`, que pone la puerta y cada servicio reenvía | si un servicio no lo reenvía, la cadena se corta ahí |

Y al revés: un `DaemonSet` de recolector en un cluster ajeno es, en compose, un contenedor más con el
socket o la carpeta de logs del motor montados; la etiqueta de Loki es el nombre del archivo de log del
servidor de antes, y una consulta de LogQL con `| json` es el `grep` con `jq` que hacías a mano. Las
filas completas, en [a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En la nube, los logs de stdout de cada contenedor los recoge casi siempre un agente que instala el
proveedor, y se pagan **por GB ingerido y por GB guardado**. La sección 8 dice cuánto escribe el sistema
con tráfico liviano; la factura sale de multiplicar.

---

## 🩺 11. Incidentes de esta fase

La fase no reserva incidentes del cuaderno. Sus roturas —el log a un archivo, las líneas de texto de
nginx y la JVM, el id que Envoy reemplaza, la etiqueta que explota— se miden en las secciones 5, 6 y 9, y
vuelven en los ejercicios.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Loki no es un buscador de texto completo.** Busca rápido por etiquetas y recorre el contenido. Para
*"todas las líneas que mencionan SKU-0004 en el último mes"*, sin una etiqueta que acote, recorre todo el
mes. Si la pregunta habitual es de ese tipo, la herramienta es otra (un índice de texto completo, con lo
que cuesta).

**El `request_id` no es una traza.** Junta las líneas de una venta; no dice que `catalog` tardó 63 ms de
los 270 de la venta, ni en qué orden se llamaron. Para eso, la [Fase 23](23-grpc-y-el-balanceo.md).

**Loguear todo cuesta.** Cada petición de una sonda es una línea en los cuatro servicios, cada cinco o diez
segundos, para siempre: en reposo, el 86 % de lo que entra a Loki son sondas y scrapes (sección 8). Un
servicio real filtra o muestrea las líneas de la plataforma; aquí se dejaron para que el costo se vea.

**Cuándo NO un Loki propio:** lo mismo que Prometheus: sin alguien que lo opere, uno administrado. Y para
un servicio que escribe poco y lo lee una persona, `kubectl logs` con `--previous` alcanza. **Cuándo sí:**
cuando los pods van y vienen más rápido de lo que alguien busca sus logs, que en un cluster es siempre.

**La pregunta del curso, para esta fase:** el contenedor te dio stdout, y el runtime lo guarda. El
orquestador te dio el `DaemonSet` para poner un recolector en cada nodo y la API para saber de quién es cada
línea. **Te tocó a ti** que los cuatro escriban lo mismo, callar lo que el runtime escribe en texto,
reenviar el `request_id`, y no poner un identificador donde va una etiqueta.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`kubectl logs` no muestra nada y el servicio responde.** Escribe a un archivo (sección 5.1). Míralo
con `kubectl exec … ls` en la carpeta de logs del framework.

**En Loki aparece el campo `log` con todo el texto adentro.** La línea no era JSON y `merge_log` no pudo
separarla: banner, colores, un aviso del runtime, o una línea cortada por `log_limit` en PHP-FPM.

**Las líneas de una venta no tienen el mismo `request_id`.** Algún servicio no reenvía la cabecera (en
`inventory`, el interceptor), o el hilo del aviso perdió el contexto.

**Busqué mi venta por el id que mandé y no está.** Envoy lo reemplazó (sección 5.3). Búscala por otro
campo (`path`, la hora) y toma el id de ahí.

**Fluent Bit escribe `cannot be retried` y `429`.** Loki está rechazando: casi siempre, demasiados flujos
(sección 9).

**El `DaemonSet` tiene menos pods que nodos.** Algún nodo tiene un *taint* que no tolera (`kubectl
describe node | grep Taints`).

---

## 📋 14. Checklist de validación

```text
[ ] task conformance TARGET=cluster PROFILE=lab -- G7, con las cuatro suites y el verificador en ok
[ ] una venta por la puerta: el mismo request_id en inventory, catalog, pricing y (con aviso) replenish
[ ] task obs:on -- logs: Fluent Bit en los dos workers, Loki listo, la fuente Loki en Grafana
[ ] la venta encontrada con una consulta de LogQL
[ ] catalog con LOG_CHANNEL=stack: nada en la salida, el archivo creciendo adentro
[ ] la autopsia: request_id como etiqueta, los 429 y las líneas perdidas; y de vuelta
```

---

## 🧪 15. Ejercicios (20)

La mitad de diagnóstico o medición. Para los que piden tráfico, `k6 run bench/trafico/la-vecina.js`; las
consultas de LogQL, en Grafana (*Explore*, fuente Loki).

## 🟢 Fácil — leer lo que el sistema escribe (1–6)

### 🟢 Ejercicio 1 — Una línea de cada uno
Lee la última línea de petición de cada backend con `kubectl logs`.

**Criterio:** cuatro líneas JSON con los mismos siete campos de la petición.

<details><summary>Solución</summary>

`kubectl -n apps logs -l app.kubernetes.io/name=<svc>,app.kubernetes.io/component=backend --tail=20 | grep
'"msg":"request"' | tail -1`. En `catalog`, `--all-containers`, y la de nginx tiene `msg` `nginx`.
</details>

### 🟢 Ejercicio 2 — Los logs encendidos
Enciende los logs y encuentra los pods de Fluent Bit y de Loki.

**Criterio:** `task obs:status` con `logs` encendida, un Fluent Bit por worker y Loki listo.

<details><summary>Solución</summary>

`task obs:on -- logs` (enciende también Grafana y Prometheus) y `kubectl -n observability get pods -o wide`.
</details>

### 🟢 Ejercicio 3 — Los flujos
Encuentra cuántos flujos guarda Loki y cuáles son.

**Criterio:** la lista, uno por contenedor de `apps`.

<details><summary>Solución</summary>

`count by (service, container) (count_over_time({job="fluent-bit"}[10m]))`. Seis: los cuatro backends, el
nginx de `catalog` y el `storefront`.
</details>

### 🟢 Ejercicio 4 — Tu venta
Vende por la puerta y encuentra la venta en los cuatro servicios.

**Criterio:** una consulta, y las líneas de `inventory`, `catalog` y `pricing` (y `replenish`, si quedó bajo
el umbral) con el mismo `request_id`.

<details><summary>Solución</summary>

El id lo pone Envoy: búscalo primero (`{service="inventory"} | json | uri="/sales"`) y después
`{namespace="apps"} | json | request_id="…"`.
</details>

### 🟢 Ejercicio 5 — Los errores de una hora
Con el tráfico de fondo, cuenta las peticiones con estado 4xx de cada servicio en la última hora, desde
Loki.

**Criterio:** la consulta, y los números comparados con los del tablero de la [Fase 17](17-metricas-y-dashboards.md).

<details><summary>Solución</summary>

`sum by (service) (count_over_time({namespace="apps"} | json | msg="request" | status >= 400 [1h]))`.
Se parecen, y la diferencia es la que hay entre contar líneas y contar en el servicio.
</details>

### 🟢 Ejercicio 6 — El `DaemonSet`
Describe el `DaemonSet` de Fluent Bit y explica por qué tiene dos pods en un cluster de tres nodos.

**Criterio:** el *taint* que lo impide, leído del nodo.

<details><summary>Solución</summary>

`kubectl describe node lab-control-plane | grep Taints`: `node-role.kubernetes.io/control-plane:NoSchedule`,
y el `DaemonSet` no tiene la `toleration`.
</details>

## 🟡 Intermedio — llevar el patrón a otro sitio (7–12)

### 🟡 Ejercicio 7 — La droguería en la línea
Haz que la línea de la venta de `inventory` diga la droguería y el producto, y contesta la pregunta de Fabio:
las ventas fallidas de `DRO-011` en la última hora.

**Criterio:** los campos `store` y `sku` en la línea de `/sales`, y la consulta que los usa.

<details><summary>Solución</summary>

En `SalesController`, una línea propia con `addKeyValue("store", …)` y `addKeyValue("sku", …)`; o el MDC.
La consulta: `{service="inventory"} | json | uri="/sales" | status >= 400 | store="DRO-011"`. Como campo
de la línea, no como etiqueta de Loki (sección 9).
</details>

### 🟡 Ejercicio 8 — El pod que ya no está
Haz una venta, borra el pod de `inventory`, y encuentra la venta.

**Criterio:** `kubectl logs` ya no la tiene; Loki sí.

<details><summary>Solución</summary>

Es la razón de la fase: lo que el kubelet guardaba se fue con el pod.
</details>

### 🟡 Ejercicio 9 — `storefront` también
Haz que el nginx del `storefront` escriba su línea de acceso en JSON con los campos comunes.

**Criterio:** sus líneas en Loki, con `| json` y sin el campo `log`.

<details><summary>Solución</summary>

El mismo `log_format … escape=json` de `catalog`, en su plantilla de nginx, y `NGINX_ENTRYPOINT_QUIET_LOGS=1`.
</details>

### 🟡 Ejercicio 10 — Cuánto escribe cada uno
Mide cuántos bytes escribe cada servicio a Loki en diez minutos de tráfico.

**Criterio:** la tabla por servicio, y qué parte son sondas.

<details><summary>Solución</summary>

`sum by (service) (bytes_over_time({job="fluent-bit"}[10m]))`, y lo mismo con `|= "/health/"`.
</details>

### 🟡 Ejercicio 11 — Sin el ruido de las sondas
Haz que Fluent Bit descarte las líneas de las sondas antes de mandarlas.

**Criterio:** ninguna línea con `/health/` en Loki, y las demás iguales.

<details><summary>Solución</summary>

Un filtro `grep` con `exclude path ^/health/` después del de `kubernetes` (el campo ya está separado por
`merge_log`). Decide antes si una sonda que falla te importa: también se descartaría.
</details>

### 🟡 Ejercicio 12 — Envoy y el id del cliente
Haz que la puerta conserve el `X-Request-Id` que manda el cliente. **Predice** qué cambia para la
seguridad.

**Criterio:** una venta con tu id, encontrada por tu id.

<details><summary>Solución</summary>

En Envoy Gateway, la política de tráfico del cliente (`ClientTrafficPolicy`) tiene la opción de preservar la
cabecera. Un cliente puede ahora elegir el id: dos peticiones con el mismo se mezclan en los logs.
</details>

## 🟠 Difícil — diagnosticar (13–17)

### 🟠 Ejercicio 13 — El log que no llega
Despliega `catalog` con `LOG_CHANNEL=stack` y genera tráfico. **Predice** qué ves en Loki y dónde quedan
las líneas.

**Criterio:** el diagnóstico desde adentro del contenedor, y de vuelta a `stderr`.

<details><summary>Solución</summary>

En Loki, solo nginx. Las de Laravel, en `storage/logs/laravel.log`, en la capa escribible: `kubectl exec
… -c php-fpm -- ls -la /app/storage/logs` (sección 5.1).
</details>

### 🟠 Ejercicio 14 — La línea cortada
Haz que `catalog` escriba una línea de más de 8 KB y búscala en Loki.

**Criterio:** la línea cortada, con el campo `log` en lugar de los campos, y la causa.

<details><summary>Solución</summary>

`log_limit = 8192` de la imagen de PHP-FPM: el hijo escribe por stderr y el maestro corta. Se sube en la
configuración global de FPM; o no se escriben líneas de ese tamaño.
</details>

### 🟠 Ejercicio 15 — La cadena cortada
Quita el interceptor de `inventory` que reenvía el `request_id` y vende.

**Criterio:** las líneas de `catalog` y `pricing` con otro id, y cómo se ve eso en la consulta de la venta.

<details><summary>Solución</summary>

Cada vecino inventa el suyo: la consulta trae solo las de `inventory`. Es por qué G7 lo pide en el contrato.
</details>

### 🟠 Ejercicio 16 — Las opciones de la JVM
Ponle a `inventory` un `jvm.options` y corre la suite de G7. Después quita la excepción del verificador.

**Criterio:** la línea en texto, dónde aparece en Loki, y por qué no tiene arreglo dentro del servicio.

<details><summary>Solución</summary>

`Picked up JAVA_TOOL_OPTIONS: …`, en Loki con el campo `log`. La escribe la JVM antes de cualquier logger;
lo único que cambia algo es no usar la variable (opciones en el `CMD`).
</details>

### 🟠 Ejercicio 17 — Loki se queda sin memoria
Baja el límite de Loki a 96 MiB y repite la autopsia. **Predice** qué pasa primero.

**Criterio:** lo que muestran Fluent Bit, Loki y `kubectl describe`.

<details><summary>Solución</summary>

Con la etiqueta de más, Loki crece; con un límite bajo, `OOMKilled`, y Fluent Bit reintentando contra un
Loki que no está. Mira también si se perdieron líneas.
</details>

## 🔴 Muy difícil — medir y diseñar (18–20)

### 🔴 Ejercicio 18 — La factura de un día
Con el tráfico de fondo a tres visitas por segundo durante treinta minutos, estima cuántos GB por día
escribiría el sistema, y cuánto de eso son las sondas.

**Criterio:** el número, con el método, y una frase sobre qué cambia con el tráfico real.

**Rúbrica:** `bytes_over_time` de la ventana, extrapolado y dicho como extrapolación; la parte de las
sondas, que no crece con el tráfico; y sin convertirlo en los domicilios de La Vecina (historia §7).

### 🔴 Ejercicio 19 — La regente de Duitama
Diseña lo que haría falta para contestar la pregunta de la sección 1 sin saber el `request_id`: una venta
fallida, en una droguería, a una hora aproximada.

**Criterio:** los campos que tiene que tener cada línea, la consulta, y la prueba con una venta tuya.

**Rúbrica:** la droguería y el producto en la línea (ejercicio 7); el motivo del fallo como campo; la
consulta acotada por servicio y hora; y qué cosas no deberían ir en el log (datos del cliente).

### 🔴 Ejercicio 20 — Las etiquetas de verdad
Decide qué etiquetas debería tener cada flujo de Loki en un cluster con veinte cadenas y cincuenta
servicios, y mide el costo de tu propuesta en el laboratorio.

**Criterio:** la lista, la cuenta de flujos posibles, y la medición con `tenant-b` encendida.

**Rúbrica:** el producto de los valores de todas las etiquetas, como en la [Fase 17](17-metricas-y-dashboards.md); lo que va a etiqueta
(se filtra siempre, pocos valores) y lo que va a la línea; y el límite de flujos de Loki como techo.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Kubernetes, *Logging Architecture* (stdout, la rotación del kubelet, los recolectores por nodo): https://kubernetes.io/docs/concepts/cluster-administration/logging/
- Kubernetes, *DaemonSet*: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/
- Fluent Bit, *Kubernetes filter*: https://docs.fluentbit.io/manual/pipeline/filters/kubernetes
- Fluent Bit, *Loki output*: https://docs.fluentbit.io/manual/pipeline/outputs/loki
- Grafana Loki, *LogQL*: https://grafana.com/docs/loki/latest/query/
- Grafana Loki, *Label best practices* (la cardinalidad): https://grafana.com/docs/loki/latest/get-started/labels/bp-labels/
- Spring Boot, *Structured logging*: https://docs.spring.io/spring-boot/reference/features/logging.html#features.logging.structured
- Envoy, *x-request-id*: https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-request-id

**Libros y ensayos**

- Adam Wiggins, *The Twelve-Factor App*, *XI. Logs* (2011): https://12factor.net/logs
- Cindy Sridharan, *Distributed Systems Observability* (2018): el capítulo de logs y sus límites.

**Orden de lectura sugerido:** antes, el factor XI (la regla de esta fase en una página); durante,
*Logging Architecture* con la sección 5.4 delante; después, *Label best practices*, con la sección 9.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 18 (cluster lab, valores de minimo)

  apps            pricing · inventory · catalog · replenish en :g7, storefront en :g5
                  una línea JSON por evento (time, level, service, msg); la de cada petición, con request_id
                  inventory reenvía X-Request-Id a los vecinos; catalog con nginx-main.conf propio
  observability   Loki (charts/loki: un proceso, 2 días en emptyDir)
                  Fluent Bit (charts/fluent-bit: DaemonSet, un pod por worker, hostPath /var/log)
                  Grafana con la fuente Loki cuando los logs están encendidos
  conformance     <svc>.g7.hurl y scripts/conformance/logs.py, que task conformance corre en G7
```

> **La señal de que quedó bien:** *"Le contesto a Fabio qué pasó con una venta con una consulta, aunque el
> pod que la atendió ya no exista; sé qué escribe cada runtime en texto y por qué; y no le pongo a Loki
> una etiqueta que no le pondría a Prometheus."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, la suite de G7 pasando y `git status`
> limpio:
>
> ```bash
> git tag -a fase-18-logs -m "F18 cerrada: G7, logs JSON con los mismos campos en los cuatro runtimes y request_id reenviado; Fluent Bit como DaemonSet y Loki en el chart; la venta en LogQL; la autopsia del request_id como etiqueta"
> ```
>
> Commits con prefijo `f18:`.

---

## 📌 Pendientes sugeridos

- **F19:** cada línea de la puerta y de los servicios viaja hoy en texto plano entre pods.
- **F20:** el `hostPath` de Fluent Bit y el `ClusterRole` que le deja mirar todos los pods.
- **F23:** el orden y la duración de cada salto de la venta, que el `request_id` no da.
