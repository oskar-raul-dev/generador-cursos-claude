# 🔌 Fase 23 — gRPC, y el balanceo que no balancea

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 23 de 27 · Parte IV — El lab de patrones distribuidos · **densa** ⭐
> **Perfil:** el cluster `lab`, con los valores de `minimo` · **Observabilidad encendida:** trazas (Tempo, con Grafana y Prometheus), por primera vez
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: el balanceo y las trazas viven en el cluster
> **Servicios que toca:** `pricing` e `inventory` (gRPC), los cuatro backends (trazas) · **Paso de generación:** G10 · gRPC y trazas
> **Depende de:** [Fase 22](22-resiliencia-y-caos.md) · **Habilita:** [Fase 24](24-la-saga-orquestada.md)
> **Incidentes que reserva:** ninguno · **Medición:** B-23
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 04/10/2026 · macOS arm64
> **Objetivo:** pasar la llamada de precio a gRPC, ver con números que el `Service` de Kubernetes deja todo el tráfico en una réplica, elegir el arreglo con sus costos, y seguir una venta por los cuatro servicios con su `traceId`.

---

## 🧭 1. Dónde estamos

La [Fase 22](22-resiliencia-y-caos.md) defendió a `inventory` de un vecino lento. Esta cambia la forma en que le habla a otro: la llamada de
precio, la de cada venta, pasa de JSON por HTTP a **gRPC**, con su contrato en Protobuf. Andrés lo propuso desde la
primera reunión de la Parte IV: un contrato binario y tipado para la llamada más frecuente.

Luz Marina lo aprobó con una advertencia que venía de 2012. Cuando el Siga pasó a un cluster de varios nodos detrás de
un balanceador (historia §1.6), las cajas de las droguerías abrían su conexión al Siga al encenderse y la mantenían el
día entero: el balanceador repartía conexiones, no peticiones, y el nodo que amanecía primero atendía el triple que los
otros. Lo arreglaron reiniciando cajas a mano los lunes. Su pregunta en la revisión fue exactamente esa:

> *"¿El balanceador de Kubernetes reparte peticiones o conexiones? Porque si reparte conexiones, ya sé cómo termina
> esto."*

Reparte conexiones. Esta fase lo mide, encuentra que el problema no empezó con gRPC sino cuatro fases antes, y elige
un arreglo con sus costos. La otra mitad cobra la deuda de la [Fase 18](18-logs.md): el `request_id` decía que cuatro
líneas eran de la misma venta, no cuánto tardó cada salto. *"¿Por qué esta venta tardó ocho segundos?"* solo lo
contesta una **traza**, y aquí se encienden por primera vez: OpenTelemetry en los cuatro runtimes, y Tempo.

---

## 🎯 2. Objetivos de esta fase

1. Escribir el contrato de `pricing` en Protobuf y generar el código de los dos lados: Go con `task proto`, Java en el
   build de Maven.
2. Generar G10: `pricing` sirve `GetPrice` por gRPC en el 9090, con el mismo mTLS de la [Fase 19](19-tls-y-certificados.md), e `inventory` lo pide en la venta.
3. Medir con B-23 cómo se reparten las llamadas entre tres réplicas de `pricing`, con el `Service` normal y con
   los arreglos.
4. Elegir el arreglo y defenderlo contra los otros: balanceo en el cliente, edad máxima de conexión, un proxy.
5. Instrumentar los cuatro servicios con OpenTelemetry, cada uno a su manera, y seguir una venta en Tempo.

---

## 🚫 3. Qué NO entra todavía

- **El mesh**, que balancea gRPC por llamada sin tocar el código → [a10](a10-service-mesh.md) (la sección 5.4 lo nombra).
- **gRPC por la puerta** (`GRPCRoute`): la llamada de esta fase es interna; la puerta sigue en HTTP/JSON.
- *Streaming*, gRPC-Web y la evolución del contrato (el ejercicio 13 la toca).
- **Muestreo** de trazas: el laboratorio guarda el 100 %.
- **Métricas y logs por OpenTelemetry**: ya tienen su camino ([Fase 17](17-metricas-y-dashboards.md) y [Fase 18](18-logs.md)).
- Las trazas de la saga → [Fase 24](24-la-saga-orquestada.md).

---

## 🧨 4. El problema, en el laboratorio

G10 ya está desplegado: `inventory` pide el precio por gRPC. `pricing` se escala a tres réplicas, como haría
cualquiera que ve subir las ventas, e `inventory` se reinicia para empezar con una conexión nueva. k6 hace veinte
ventas por segundo durante treinta segundos, y cada réplica cuenta las llamadas que recibe en su
`grpc_server_requests_total`. Tres corridas:

```text
$ task measure -- B-23 --runs 3 --rate 20
── B-23 · balancing=service · 3 réplicas de pricing · 20 ventas/s
   corrida 1: llamadas por réplica {rwht6: 0,   smbll: 600, wml8l: 0} · mediana 24,2 ms
   corrida 2: llamadas por réplica {rwht6: 601, smbll: 0,   wml8l: 0} · mediana 23,6 ms
   corrida 3: llamadas por réplica {rwht6: 0,   smbll: 600, wml8l: 0} · mediana 25,4 ms
```

**Seiscientas llamadas, todas a una réplica.** Las otras dos, listas, sanas y en el `Service`, recibieron cero. Cuál
de las tres se lleva todo cambia en cada corrida (la segunda le tocó a otra), y eso es la pista: se elige **una vez**,
al conectar, y después no se vuelve a elegir.

Kubernetes no lo vio: tres pods `Ready`, tres *endpoints*, y un HPA, si lo hubiera, escalaría a una cuarta réplica que
tampoco recibiría nada.

Y la sorpresa vino después. Para tener con qué comparar, la misma medición con gRPC apagado: el precio por HTTP, como
estaba desde la [Fase 19](19-tls-y-certificados.md), por el 8443 con mTLS. **Lo mismo,
sin gRPC:** 100 %, 99,8 % y 100 % a una réplica. El 8443 de `pricing` es un servidor HTTPS de Go, que ofrece HTTP/2 en
la negociación de TLS (ALPN), y el cliente HTTP del JDK lo pide por defecto. Un `curl` desde el pod de `inventory`:

```text
* ALPN: curl offers h2,http/1.1
* ALPN: server accepted h2
> GET /prices/SKU-0002?store=DRO-006 HTTP/2
```

Desde que la llamada de precio pasó a mTLS, hace cuatro fases, ya viajaba por **una sola conexión HTTP/2** y ya
caía entera en una réplica. Nadie lo notó, porque hasta hoy `pricing` corría con una. El problema no es de gRPC: es
de **HTTP/2**, que gRPC usa siempre y que el HTTPS moderno negocia solo.

> 🩻 **Esto sí funciona igual.** Un balanceador de capa 4 con clientes de conexiones largas se comporta así en cualquier
> parte, el de 2012 del Siga incluido. Lo nuevo es que HTTP/2 vuelve pegajoso lo que antes no lo era.

---

## 🧩 5. gRPC, el balanceo y las trazas

### 5.1 El contrato, en Protobuf

El contrato de la llamada vive en `src/lab/contracts/proto/pricing/v1/pricing.proto`, al lado de los OpenAPI de la
[Fase 02](02-compose-el-sistema-en-un-archivo.md). Es la misma pregunta que `GET /prices/{sku}?store=`, con un solo método:

```protobuf
service Pricing {
  // El precio vigente de un producto en una droguería, con el tope regulado ya aplicado.
  // Sin precio: NOT_FOUND. Con sku o store mal formados: INVALID_ARGUMENT.
  rpc GetPrice(GetPriceRequest) returns (Price);
}

message Price {
  string sku = 1;
  string store = 2;
  int64 price = 3;            // en pesos, sin decimales
  string currency = 4;        // COP
  optional int64 regulated_cap = 5;
  bool capped = 6;
}
```

Los números de campo son el contrato, no los nombres: renombrar `price` no rompe a nadie; cambiarle el número, sí. Y
los errores dejan de ser códigos HTTP: son los de gRPC (`NOT_FOUND`, `INVALID_ARGUMENT`, `UNAVAILABLE`), y la venta
los traduce (un `NOT_FOUND` de `pricing` sigue siendo un 422 de `inventory`).

El código sale del `.proto` de dos maneras distintas, y las dos dentro de contenedores:

```bash
task proto        # Go: protoc y los dos generadores en un contenedor de Go; el resultado, pricingv1/, se versiona
task build -- inventory   # Java: el protobuf-maven-plugin lo genera al compilar, con el .proto
                          # que llega por un contexto de build aparte: --build-context proto=contracts/proto
```

El contexto de build aparte evita copiar el `.proto` en cada servicio: el `Dockerfile` lo toma con `COPY --from=proto`.
En Go, el código generado se versiona (costumbre del ecosistema); en Java, no (costumbre de Maven).

### 5.2 G10: `pricing` habla gRPC, e `inventory` le pregunta

El prompt de G10 está en [a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g10). En `pricing`, un segundo servidor en el 9090, con el **mismo
`tls.Config` del 8443**: los mismos certificados de cert-manager, la misma CA, la misma recarga de la [Fase 19](19-tls-y-certificados.md):

```go
opts := []grpc.ServerOption{grpc.Creds(credentials.NewTLS(tlsConfig)), grpc.UnaryInterceptor(observe),
	grpc.StatsHandler(otelgrpc.NewServerHandler())} // G10: un span por llamada, con el traceparent de los metadatos
```

El interceptor `observe` cuenta cada llamada en `grpc_server_requests_total{method,code}` (la evidencia de B-23) y
escribe la línea `request` de G7. En el apagado, `GracefulStop` termina las llamadas en vuelo y le manda a cada cliente
un `GOAWAY`: la manera de HTTP/2 de decir "conéctate a otro".

En `inventory`, el canal de grpc-java se arma con el *SSL bundle* `pricing` de G8 (y se rearma cuando se renueva); el
destino y la política de balanceo salen de dos variables del chart:

```java
channel = NettyChannelBuilder.forTarget(target)          // PRICING_GRPC_TARGET
        .sslContext(/* el bundle "pricing" de G8 */)
        .defaultLoadBalancingPolicy(policy)               // PRICING_GRPC_POLICY
        .intercept(requestId())
        .build();
```

`Guard`, el de G9, envuelve la llamada con su plazo (*deadline*, en gRPC) y cuenta `UNAVAILABLE` y
`DEADLINE_EXCEEDED` como fallas transitorias. Con `global.grpc.enabled` en `false`, el precio vuelve por HTTP.

### 5.3 Por qué todo va a una réplica

Un `Service` `ClusterIP` no es un proxy. Es una regla de kube-proxy en cada nodo que, **cuando se abre una conexión
TCP** hacia la IP del `Service`, elige un pod al azar y reescribe el destino. En el cluster `lab`, con kube-proxy en
modo `iptables`:

```text
$ docker exec lab-worker iptables-save -t nat | grep "apps/pricing:grpc ->"
-A KUBE-SVC-WCUGQSYENOS4NLYI -m comment --comment "apps/pricing:grpc -> 10.244.1.40:9090" -m statistic --mode random --probability 0.33333333349 -j KUBE-SEP-T4UOQ777D3MSYJML
-A KUBE-SVC-WCUGQSYENOS4NLYI -m comment --comment "apps/pricing:grpc -> 10.244.2.28:9090" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-YTF25OMOWMPYMZY4
-A KUBE-SVC-WCUGQSYENOS4NLYI -m comment --comment "apps/pricing:grpc -> 10.244.2.29:9090" -j KUBE-SEP-N2A4MLPVLKLHVWCN
```

Un tercio a la primera; de lo que queda, la mitad a la segunda; el resto a la tercera. Medido aparte, con treinta
conexiones de `nc` desde el pod de `inventory`: 7, 13 y 10. El dado es justo.

Pero el dado se tira **una vez por conexión**. Con HTTP/1.1, eso reparte bien, porque los clientes abren varias conexiones y
las renuevan. Con HTTP/2, una sola conexión multiplexa todas las llamadas, para siempre, y el `Service` ya no tiene
nada que repartir. Contadas desde el nodo, las conexiones establecidas al 8443 de cada réplica durante la corrida de
HTTP: **0, 1 y 0**.

> 🧠 **Modelo mental.** Un `Service` reparte **conexiones**; HTTP/2 multiplexa **llamadas** dentro de una. Si el
> cliente abre una sola conexión, el balanceo terminó en el primer milisegundo.

### 5.4 Tres arreglos, y lo que mide cada uno

Hay tres maneras de devolverle al balanceo algo que repartir, y las tres se usan en producción.

**Balancear en el cliente.** El cliente conoce todas las réplicas y reparte él. Para eso necesita las IP de los pods,
no la del `Service`, y eso es exactamente lo que da un `Service` *headless* (`clusterIP: None`): el DNS contesta con
una dirección por pod. El chart lo agrega como `pricing-grpc`, e `inventory` apunta ahí con la política `round_robin`
de grpc-java:

```yaml
# charts/platform/charts/inventory/templates/deployment.yaml, con global.grpc.balancing=client
- {name: PRICING_GRPC_TARGET, value: "dns:///pricing-grpc.apps.svc.cluster.local:9090"}
- {name: PRICING_GRPC_POLICY, value: round_robin}
```

El cliente abre una conexión por réplica y alterna las llamadas. B-23, con el mismo k6:

```text
── B-23 · balancing=client · 3 réplicas de pricing · 20 ventas/s
   corrida 1: llamadas por réplica {pz7bt: 201, scd4s: 200, wml8l: 200} · mediana 24,5 ms
   corrida 2: llamadas por réplica {pz7bt: 200, scd4s: 201, wml8l: 200} · mediana 23,1 ms
   corrida 3: llamadas por réplica {pz7bt: 200, scd4s: 200, wml8l: 200} · mediana 24,2 ms
```

Un tercio exacto cada una, y la venta igual de rápida. El certificado de `pricing` necesita el nombre del *headless*
en sus SAN (el ejercicio 15 lo quita).

**Cortar las conexiones desde el servidor.** `pricing` le pone edad máxima a cada conexión (`MaxConnectionAge` de
grpc-go; `GRPC_MAX_CONNECTION_AGE` en el laboratorio, `global.grpc.maxConnectionAge` en el chart): al cumplirla,
manda un `GOAWAY`, el cliente abre otra, y kube-proxy tira el dado de nuevo. No toca el cliente. Con el `Service`
normal y 10 s de edad:

```text
── B-23 · balancing=service+age · 3 réplicas de pricing · 20 ventas/s
   corrida 1: reparto [1.0, 0.0, 0.0]
   corrida 2: reparto [1.0, 0.0, 0.0]
   corrida 3: reparto [0.696, 0.304, 0.0]
```

Las reconexiones ocurren (conntrack ve una nueva cada diez segundos), pero cada una cae en **una** réplica: en treinta
segundos, tres tiradas. Con una muestra de tres minutos, las dieciocho
reconexiones quedaron 6/6/6: **el promedio largo se empareja; en cada instante, sigue trabajando una sola réplica.**
Rota la carga; no la reparte.

**Poner un proxy que entienda HTTP/2.** Un proxy de capa 7 (Envoy, o el *sidecar* de un mesh) termina la conexión del
cliente y reparte **cada llamada**. No toca ni el cliente ni el servidor, y cuesta un salto y una pieza más. No se midió
aquí (el ejercicio 21 lo hace); el mesh es [a10](a10-service-mesh.md).

| | Reparte por | Ve réplicas nuevas | Toca | Lo que cuesta |
|---|---|---|---|---|
| `Service` normal | conexión | al reconectar (nunca, si la conexión no se cae) | nada | todo a una réplica (B-23: 100 %) |
| *Headless* + `round_robin` | llamada, en el cliente | **no**, hasta que algo falle (sección 5.5) | el cliente y el chart | una conexión por réplica en cada cliente; cada lenguaje lo configura distinto |
| Edad máxima | conexión, rotando | al cumplirse la edad | el servidor | en cada instante, una réplica; un saludo TLS más por edad cumplida |
| Proxy L7 o mesh | llamada, en el proxy | sí | la plataforma | un salto y una pieza más ([a10](a10-service-mesh.md)); no medido aquí |

### 5.5 La réplica que nunca recibió nada

El balanceo en el cliente tiene su propia trampa. grpc-java resuelve el DNS del *headless* al conectar, y **no vuelve
a resolver mientras ninguna conexión falle**: una réplica nueva está en el DNS y el cliente no se entera. La prueba:
dos réplicas, sesenta segundos de ventas, y la tercera a los veinte:

```text
$ task measure -- B-23 --scale --modes client,client+age --rate 20
── B-23 · la réplica nueva · balancing=client · 2 → 3 réplicas a los 20 s de 60
   la nueva recibió 0 de 1200 llamadas · {c9b49: 600, wdmgc: 0, z6mp6: 600}
── B-23 · la réplica nueva · balancing=client+age · 2 → 3 réplicas a los 20 s de 60
   la nueva recibió 237 de 1201 llamadas · {62zsg: 237, 65758: 482, 95krh: 482}
```

**Cero de mil doscientas**: el HPA de la [Fase 16](16-escalado-y-rollout.md) escalando para nada, con el arreglo puesto. Con la edad máxima, el
`GOAWAY` obliga a reconectar, y reconectar es volver a resolver: 237, cerca de las ~267 que le tocaban.

El laboratorio queda con **las dos cosas**: `round_robin` sobre el *headless* para repartir, y 10 s de edad máxima
para descubrir réplicas nuevas (`global.grpc.balancing: client`, `global.grpc.maxConnectionAge: 10s`). En producción,
la edad se mide en minutos: cuánto aceptas que una réplica nueva espere trabajo.

> 💡 **Insight de diseño.** Con balanceo en el cliente, la pregunta deja de ser "¿cuántas réplicas hay?" y pasa a ser
> "¿cuántas *cree* el cliente que hay, y desde cuándo?".

### 5.6 Las trazas: OpenTelemetry y Tempo

Una traza es un árbol de *spans*: cada servicio abre uno por petición que atiende y otro por llamada que hace, todos
con el mismo `trace_id`, que viaja en la cabecera `traceparent` (W3C Trace Context) o en los metadatos de gRPC. Es el
`request_id` de la [Fase 18](18-logs.md), más el tiempo y el orden de cada salto.

Los spans van a **Tempo**, en `observability`, por OTLP (HTTP, en el 4318). Los cuatro leen las mismas variables
estándar, que el chart pone solo con las trazas encendidas (`task obs:on -- traces`):

```yaml
- {name: OTEL_SERVICE_NAME, value: "inventory"}
- {name: OTEL_EXPORTER_OTLP_ENDPOINT, value: "http://tempo.observability.svc.cluster.local:4318"}
- {name: OTEL_EXPORTER_OTLP_PROTOCOL, value: http/protobuf}
- {name: OTEL_TRACES_EXPORTER, value: otlp}
- {name: OTEL_METRICS_EXPORTER, value: none}      # las métricas ya tienen su camino (Fase 17)
- {name: OTEL_LOGS_EXPORTER, value: none}         # y los logs, el suyo (Fase 18)
```

Apagadas, el chart pone `OTEL_SDK_DISABLED=true` (y `OTEL_JAVAAGENT_ENABLED=false` en `inventory`): la
instrumentación sigue en la imagen, y no hace nada. La `NetworkPolicy` de salida de la [Fase 20](20-seguridad-del-pod-y-de-la-red.md) suma una regla, la del 4318 de
Tempo, y la sección 6 muestra lo que esa política hace cuando Tempo no está.

`pricing` se instrumenta con código, y por eso es el piloto: el SDK en `otel.go`, `otelhttp` en el manejador y
`otelgrpc` en el servidor gRPC. El `trace_id` entra en su línea `request` de G7: el puente entre la traza y el log.

### 5.7 La venta, seguida por su `trace_id`

La deuda de la [Fase 18](18-logs.md): la misma venta, ahora con su traza. Una venta bajo el umbral, para que también avise a
`replenish`, y su `trace_id` sale de la línea `request` de `inventory`. Con él, Tempo devuelve la traza entera: en
Grafana, *Explore* con la fuente Tempo; en la terminal, `task obs:trace`, que abre un `port-forward`, le pide la traza
a la API de Tempo y la imprime como árbol de tiempos:

```text
$ task obs:trace -- 6b6fc07d0df8394f914c7fb2fab1ff98
14 spans ['catalog', 'inventory', 'pricing', 'replenish']
     0.0 ms     51.6 ms  inventory  SERVER  POST /sales
     1.7 ms     24.2 ms  inventory  CLIENT  GET
     5.4 ms     19.0 ms  catalog    SERVER  GET /products/{sku}
     8.5 ms     15.3 ms  catalog    CLIENT  sql SELECT
    26.8 ms      5.2 ms  inventory  CLIENT  lab.pricing.v1.Pricing/GetPrice
    30.4 ms      0.9 ms  pricing    SERVER  lab.pricing.v1.Pricing/GetPrice
    32.4 ms      1.0 ms  inventory  CLIENT  SELECT inventory.stock_levels
    33.7 ms      0.5 ms  inventory  CLIENT  UPDATE inventory.stock_levels
    34.6 ms      0.5 ms  inventory  CLIENT  INSERT inventory.sales
    35.4 ms      0.3 ms  inventory  CLIENT  INSERT inventory.stock_movements
    51.0 ms     38.6 ms  inventory  CLIENT  POST
    81.9 ms      6.8 ms  replenish  SERVER  POST
    81.9 ms      0.1 ms  replenish  CLIENT  pg-pool.connect
    81.9 ms      4.1 ms  replenish  CLIENT  pg.query:INSERT replenish
```

Lo que el `request_id` no decía, ahora con números: la venta duró 51,6 ms; casi la mitad fue `catalog` (24,2 ms desde
`inventory`, 19,0 ms dentro de `catalog`, 15,3 de ellos en su consulta); `pricing` atendió en 0,9 ms, y los 4,3 ms
restantes del cliente gRPC son red y TLS. Y el aviso a `replenish` (el `POST` a los 51,0 ms) **termina después que la
venta**: es el "sin esperar su respuesta" de G5, dibujado.

La pregunta *"¿por qué esta venta tardó?"* la contestó la primera venta después de reiniciar
`inventory`: 1.358 ms, de los cuales **826 ms están en el cliente gRPC y 14 en el servidor de `pricing`**. El tiempo
no se fue en `pricing`, sino en abrir el canal: la primera llamada resuelve el DNS y hace los saludos TLS. Sin la traza, `pricing` habría dicho "14 ms", `inventory` "1,3 s", y la discusión habría sido entre equipos.

**La primera versión de la traza tenía tres servicios, no cuatro.** El aviso a `replenish` sale en un hilo virtual
propio, para no hacer esperar la venta, y un hilo nuevo **no hereda el contexto**: ni el MDC (por eso G7 ya copiaba
el `request_id` a mano) ni la traza. El agente de Java instrumenta las llamadas, pero no puede adivinar que ese hilo
es parte de la venta. El aviso salía como una traza aparte, y su línea de log, sin `trace_id`. El arreglo es una línea,
y va al lado del MDC:

```java
// El hilo nuevo no hereda el MDC ni la traza: el request_id se copia a mano, y el contexto de
// OpenTelemetry se le pasa envolviendo la tarea (G10, Fase 23). Sin eso, el aviso es otra traza.
String requestId = MDC.get("request_id");
Thread.ofVirtual().start(Context.current().wrap(() -> { … }));
```

`Context` es de `opentelemetry-api` (la versión de Spring Boot; el agente la enlaza, y sin trazas no hace nada). Es la
única línea que pidió la instrumentación "sin tocar el código" de Java.

> 🧭 **Principio.** Una traza es tan completa como su hilo más suelto. Todo lo asíncrono —un hilo, una cola, un
> *callback*— corta la traza salvo que alguien le pase el contexto a mano. Las Fases [24](24-la-saga-orquestada.md) y [25](25-la-coreografia.md) están llenas de eso.

Dos detalles de la consulta. Los spans no llegan a la vez: PHP los manda al terminar cada petición, y Go, Java y Node
en lotes cada pocos segundos, así que una traza pedida enseguida puede venir con dos spans de `catalog` y nada más.
Y Tempo guarda en un `emptyDir`, como Prometheus y Loki: si se reinicia, las trazas se van con él.

---

## 🔁 6. Los otros tres: cuatro maneras de instrumentar

G10 es donde los runtimes se separan otra vez, y la fricción es contenido. Lo que cada uno sumó a su imagen, medido
con `docker history` contra su paso anterior:

| | Cómo se instrumenta | Líneas de `Dockerfile` | Lo que pesa |
|---|---|---|---|
| `pricing` (Go) | **código**: el SDK, `otelhttp`, `otelgrpc` | 0 (dos archivos más en el `COPY`) | +5,7 MB de binario, con gRPC incluido |
| `inventory` (Java) | **agente**: `-javaagent`, sin tocar el código… casi (sección 5.7) | 4: el `ADD` con suma y el `CMD` | +26,4 MB del agente; +20,1 MB de gRPC aparte |
| `catalog` (PHP) | **extensión** de PECL y paquetes de Composer | 2: el `pecl install` en las **dos** etapas | +0,7 MB de la extensión y +7,0 MB de `vendor` |
| `replenish` (Node) | **`--import`** de la autoinstrumentación | 1: el `CMD` | **+80 MB** de `node_modules` (de 30 a 110) |

**Java** es el más cómodo de activar: el agente se baja en el build con su suma (`ADD --checksum`), y cada ruta de
Spring, cada llamada del `RestClient`, cada consulta JDBC y cada llamada de grpc-java sale como span. Dos tropiezos: el
`ADD` dejó el jar en `0600`, ilegible para el usuario 10001 (va con `--chmod=644`), y la JVM con el agente escribe dos
líneas de texto al arrancar que la suite de G7 tuvo que declarar como excepciones.

**PHP** es el que más se resiste. La instrumentación de Laravel necesita la extensión `opentelemetry` de PECL para
engancharse a las funciones, y Composer se niega a armar el autoload sin ella: la extensión se compila **dos veces**,
en la etapa de build y en la final (ignorar el requisito de plataforma no alcanza). Y FPM tiene una particularidad que los otros tres no: cada petición es un proceso
que arranca limpio, así que el SDK se carga en cada una (`OTEL_PHP_AUTOLOAD_ENABLED=true`) y los spans se vacían al
terminarla, **dentro de la misma petición**.

Eso último tiene un costo que se midió apagando Tempo (cero réplicas) con las trazas encendidas, y sesenta lecturas
seguidas por la puerta a cada servicio:

```text
                         con Tempo                  Tempo en 0
pricing   /prices        mediana 3,7 ms  máx 66     mediana 5,9 ms  máx 34
replenish /orders        mediana 6,0 ms  máx 37     mediana 13,2 ms máx 158
catalog   /products      mediana 26,1 ms máx 284    mediana 8,8 ms  máx 15.093
venta                    201                        503 en 3,5 s: "catalog no contesta: … HTTP connect timed out"
```

Go, Java y Node exportan en segundo plano: sin Tempo, sus lotes fallan y nadie espera. PHP exporta al final de cada
petición, y el log de `php-fpm` cuenta qué pasó: mientras el pod de Tempo se apagaba, `cURL error 7 … after 0 ms` (un
rechazo, barato); cuando ya no había pod, `cURL error 28: Connection timed out after 10001 milliseconds`. Es el hallazgo
de la [Fase 21](21-diagnostico.md) otra vez: con la `NetworkPolicy`, un destino sin pods no rechaza, **cuelga**. Cada proceso de FPM espera
diez segundos por petición, los cinco se ocupan, `inventory` no consigue conectarse, y la venta falla. **El sistema de
observabilidad tumbó al observado.** La mediana de `catalog` bajó, y no separé por qué; el
máximo es el corte de quince segundos de la puerta, y ese es el número que importa.

**Node** se activa con una línea (`node --import @opentelemetry/auto-instrumentations-node/register`) y es el que más
pesa: trae instrumentaciones para decenas de bibliotecas que `replenish` no usa. El chart limita las activas
(`OTEL_NODE_ENABLED_INSTRUMENTATIONS=http,express,nestjs-core,pg`); las demás solo meten ruido.

> 🩻 **Esto sí funciona igual.** Que la instrumentación de Java sea un agente y la de Go sea código no es de los
> contenedores: es de los runtimes, y pasaría igual en un servidor. Lo que sí es del curso es que las cuatro leen las
> mismas variables, y que el chart las enciende y las apaga a todas a la vez.

---

## 🪞 7. Tu instinto de compose dice… y las apuestas

El instinto, en su mejor versión: *"si la llamada es lenta o el servicio no da abasto, se escala a tres réplicas y el
`Service` reparte; y si algo tarda, el log dice dónde"*. Las apuestas, escritas antes de ejecutar:

> 🪞 **Apuesta antes de ejecutar.** Con tres réplicas de `pricing` y gRPC por un `Service` normal, más del 90 % de las
> llamadas van a una sola réplica; con balanceo en el cliente, cada una recibe entre el 25 % y el 40 %.
>
> **Resultado: ganada:** 100 % y 33 % exacto (secciones 4 y 5.4).

> 🪞 **Apuesta antes de ejecutar.** La mediana de la venta no cambia más de un 10 % al pasar el precio de HTTP a gRPC.
>
> **Resultado: ganada:** 23–25 ms en los cinco modos (sección 8).

> 🪞 **Apuesta antes de ejecutar.** Con `pricing` cortando cada conexión a los 10 s y el `Service` normal, la réplica más
> cargada recibe entre el 40 % y el 70 % en treinta segundos.
>
> **Resultado: perdida:** 100 %, 100 % y 70 % (sección 5.4).

> 🪞 **Apuesta antes de ejecutar.** Con balanceo en el cliente, una réplica que aparece a mitad de las ventas recibe
> menos del 5 %; con la edad máxima, más del 15 %.
>
> **Resultado: ganada:** 0 de 1200, y 237 de 1201 (sección 5.5).

> 🪞 **Apuesta antes de ejecutar.** Una venta aparece en Tempo como una sola traza con los cuatro servicios.
>
> **Resultado: ganada, después de un arreglo:** la primera traza tuvo tres servicios (sección 5.7).

> 🪞 **Apuesta antes de ejecutar.** La instrumentación de `catalog` (PHP) es la que más líneas de `Dockerfile` agrega, y
> Tempo ocupa menos de 100 MiB en reposo.
>
> **Resultado: perdida, las dos:** Java agrega cuatro líneas y PHP dos (sección 6); Tempo ocupa 132 MiB (sección 8).

Una apuesta sobre HTTP/1.1 nació de una premisa falsa (suponía que el 8443 iba por HTTP/1.1, y iba por HTTP/2); se
corrigió antes de medir el 8080, y quedó a medias: 50 % de mediana, con una réplica en cero en las tres corridas. Y la
de Tempo caído, escrita antes de apagarlo ("sube menos de 5 ms"), se perdió de la peor manera (sección 6). Las entradas están
en [INSTINTOS.md](INSTINTOS.md#tres-réplicas-reparten-el-tráfico-entre-tres).

---

## 📏 8. Lo que cuesta

B-23 completo, con veinte ventas por segundo y tres réplicas de `pricing`, tres corridas por modo:

| Cómo llega el precio | La réplica más cargada | Mediana de la venta |
|---|---|---|
| gRPC, `Service` normal | **100 %** (las tres corridas) | 23,6–25,4 ms |
| gRPC, *headless* + `round_robin` | **33 %** (las tres) | 23,1–24,5 ms |
| gRPC, `Service` normal + 10 s de edad | 100 %, 100 %, 70 % | 24,1–25,7 ms |
| HTTP/2 por el 8443 (mTLS), como desde la F19 | 100 % (las tres) | 23,4–24,0 ms |
| HTTP/1.1 por el 8080 (sin mTLS) | 100 %, 50 %, 50 %, y siempre una en cero | 23,1–24,0 ms |

A esta tasa, **el protocolo no cambia la latencia; cambia el reparto**, que importa el día que una réplica no da
abasto. En el laboratorio no llegó: veinte ventas por segundo son poco para Go. Es el día del pico de domicilios.

Lo demás que cuesta G10:

- **Conexiones.** Con `round_robin`, cada réplica de `inventory` abre una conexión a cada réplica de `pricing`. Con diez
  de cada lado son cien, cada una con su saludo TLS. Con el `Service` normal, eran diez.
- **La edad máxima.** Un saludo TLS por cliente cada diez segundos. En el laboratorio, invisible en la mediana; en
  producción, la edad se mide en minutos.
- **Tempo:** 132 MiB en reposo, y cinco `OOMKilled` con su límite de 384 MiB mientras la máquina virtual estaba sin
  memoria. Las imágenes, en la sección 6.
- **La máquina virtual.** Con trazas, Prometheus, Grafana y el agente de Java a la vez, los 4 GiB no alcanzaron: el
  plano de control empezó a reiniciarse (sección 13). La fase se verificó con Prometheus y Grafana apagados.

---

## ⚰️ 9. Autopsia: escalar `pricing` y dar el reparto por hecho

**La decisión, con su mejor argumento.** Subir `pricing` a tres réplicas cuando las ventas crecen. *"Para eso está el
`Service`: reparte entre las réplicas listas. Es lo que hicimos en la [Fase 16](16-escalado-y-rollout.md), y funcionó."*

**Por qué era razonable.** En la [Fase 16](16-escalado-y-rollout.md) funcionó (B-16), porque las lecturas entraban por la puerta y Envoy reparte
**cada petición**. Nada en el `Service` avisa que con otro cliente se comporta distinto.

**Qué pasó después, con número.** Con la llamada de precio por gRPC, **600 de 600 llamadas a una réplica**, en las tres
corridas. Y desde la [Fase 19](19-tls-y-certificados.md), el precio por HTTPS ya iba entero a una. Dos réplicas pagadas, listas y sin trabajo.

**Cuánto cuesta salir, con número.** Un *headless*, un nombre más en el certificado, dos variables en `inventory` y una
en `pricing`: 200/200/200, y 237 llamadas para la réplica nueva. A cambio, una conexión por réplica en cada cliente.

**Qué lo habría cambiado.** Contar las llamadas **por réplica**, no por servicio. El `grpc_server_requests_total` de
G10 lo hace, y una consulta de Prometheus por pod lo habría mostrado el primer día.

**Antes y después, con números:** 600/0/0 con el `Service` normal; 200/200/200 con el *headless* y `round_robin`; y
la réplica nueva, de 0 de 1200 a 237 de 1201 con la edad máxima.

---

## 📖 10. Traducción

| En compose o en un servidor | En Kubernetes | Lo que cambia |
|---|---|---|
| el balanceador de capa 4 delante del cluster | el `Service` `ClusterIP` (kube-proxy) | reparte conexiones, igual; con HTTP/2, una conexión es todo |
| el balanceador de capa 7 (un proxy HTTP) | la puerta (Envoy, Gateway API) o un mesh ([a10](a10-service-mesh.md)) | reparte llamadas, pero solo lo que pasa por él |
| la lista de servidores en la configuración del cliente | un `Service` *headless* y el DNS del cluster | la lista cambia sola; el cliente tiene que volver a preguntar |
| el `request_id` en los logs | el `traceparent` y el `trace_id` | dice qué pasó, y además cuánto tardó cada salto y en qué orden |
| el APM con su agente en el servidor | OpenTelemetry y Tempo | estándar, de cualquier proveedor; cada runtime se instrumenta a su manera |

Y al revés: un *headless* es, sin Kubernetes, un DNS con varios registros A que el cliente tiene que volver a consultar;
y un `Service` delante de un cliente gRPC, el balanceador de 2012 del Siga. Las filas completas, en [a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En la nube, los balanceadores de aplicación y los mesh gestionados reparten gRPC por llamada: la respuesta de "un
proxy", con la factura de un proxy.

---

## 🩺 11. Incidentes de esta fase

La fase no reserva incidentes. El balanceo que no balancea es su rotura principal, y vuelve en los ejercicios 15 a 20.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**gRPC no hace más rápida una llamada corta.** B-23 lo mide: misma mediana que HTTP/2 y que HTTP/1.1. Se gana un
contrato tipado y binario, y se pierde poder llamar con `curl`, leer el tráfico a simple vista y que la puerta lo sirva
al navegador sin más piezas. Para una llamada interna, frecuente y de contrato estable, vale; para una API que lee un
humano, no.

**El balanceo en el cliente vive en cada cliente.** Cada lenguaje lo escribe distinto, y cada cliente nuevo puede
olvidarlo. Con un cliente gRPC, es razonable; con diez, un proxy o un mesh, que lo hace una vez para todos, gana.

**La edad máxima sola no reparte.** Rota la carga y le da trabajo a la réplica nueva, pero en cada instante sigue
trabajando una. Es el complemento del balanceo en el cliente, no su reemplazo.

**Las trazas no deberían poder tumbar lo que observan, y en PHP lo hicieron** (sección 6). Antes de encender trazas en
un runtime que exporta dentro de la petición, o se baja el timeout del exportador o se pone un recolector local (un
OpenTelemetry Collector en el nodo); el ejercicio 22 mide los dos.

**Las trazas cuestan memoria, imagen y atención.** En el laboratorio se guarda el 100 %; en producción se muestrea. Y
un hilo que no hereda el contexto parte la traza en dos (sección 5.7).

**Cuándo NO G10 entero:** un sistema con dos servicios que se hablan poco, donde los logs con `request_id` alcanzan; un
servicio que se consume desde el navegador. **Cuándo sí:** una llamada interna en el camino caliente de cada venta, y un
sistema donde la pregunta "¿por qué tardó?" cruza cuatro servicios.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso que abre conexiones. El orquestador te dio
un `Service` que reparte conexiones y un DNS que conoce cada pod. **Te tocó a ti** saber que tu protocolo mete todo en
una conexión, decidir quién reparte las llamadas, y pasarle la traza a cada hilo que abres.

---

## ⚠️ 13. Errores comunes y diagnóstico

**La venta en 503 con `pricing no contesta (gRPC): Status{code=UNAVAILABLE…}` después de tocar el certificado.** Si el
`Certificate` de `pricing` pierde el nombre del *headless* (`pricing-grpc.apps.svc.cluster.local`) en sus SAN, el
saludo TLS falla contra cada réplica. El chart lo agrega; el ejercicio 15 lo rompe a propósito.

**Todo el tráfico a una réplica, con `balancing: client`.** `PRICING_GRPC_TARGET` sigue apuntando al `Service` normal,
o la política es `pick_first`: mira las variables del `Deployment` de `inventory`.

**Una réplica nueva sin tráfico.** Es la sección 5.5: sin `maxConnectionAge`, el cliente no vuelve a resolver.

**Tempo en `CrashLoopBackOff` con `field compactor not found in type app.Config`.** Una configuración de Tempo 2 en
Tempo 3: la retención va en `backend_worker.compaction.block_retention`. Y el log de Tempo escribe `error calling
scheduler … no jobs found` cada quince segundos: no es un error, es un trabajador sin trabajo.

**`task obs:on` falla con `conflict with "kubectl" with subresource "scale"`.** Después de un `kubectl scale` (B-23 lo
hace), `kubectl` es dueño de `.spec.replicas`: despliega con `FORCE=true`.

**`catalog` lento o colgado con las trazas encendidas, y `Export failure … cURL error 28` en el log de `php-fpm`.**
Tempo no está (sección 6): levántalo, o apaga las trazas (`task obs:off -- traces`). Esas líneas no son JSON, ni las
del agente de Java en `inventory`: la suite de G7 falla hasta que los pods se reinician.

**Un servicio sin spans.** Las trazas están apagadas (`OTEL_SDK_DISABLED=true` en el `Deployment`), o el servicio no
llega al 4318 de Tempo por la `NetworkPolicy`.

**Con todo encendido, el plano de control se reinicia y `kubectl logs` da `TLS handshake timeout`.** La máquina virtual
se quedó sin memoria: apaga Prometheus y Grafana mientras trabajas con trazas.

---

## 📋 14. Checklist de validación

```text
[ ] task proto, sin cambios en pricingv1/ (el código generado está al día)
[ ] task conformance TARGET=cluster PROFILE=lab -- G5, G7 y G8, con los cuatro en :g10
[ ] B-23: 100 % a una réplica con balancing=service, y un tercio cada una con client
[ ] la réplica nueva recibe llamadas con maxConnectionAge
[ ] task obs:on -- traces, y Tempo en Running
[ ] una venta bajo el umbral en Tempo, con los cuatro servicios en una sola traza
[ ] el trace_id de la venta en las líneas de log de inventory y de pricing
```

---

## 🧪 15. Ejercicios (24)

La mitad es contar llamadas por réplica y leer trazas: es lo que esta fase enseña a hacer antes de decidir nada.

## 🟢 Fácil — ver el reparto y la traza (1–7)

### 🟢 Ejercicio 1 — El contrato, generado
Corre `task proto` y comprueba que `pricingv1/` no cambia. Después agrega un comentario al `.proto`, vuelve a generar y
mira qué archivos cambian.

**Criterio:** `git status` limpio en la primera corrida; en la segunda, solo los dos `.pb.go` (y por el comentario).

<details><summary>Solución</summary>

El comentario del `.proto` viaja al código generado. Quita el comentario y regenera: vuelve a quedar limpio. Si
cambian otras líneas, tu `protoc` o tus generadores no son los de `a01`: por eso `task proto` corre en un contenedor.
</details>

### 🟢 Ejercicio 2 — Contar por réplica
Con tres réplicas de `pricing`, haz veinte ventas y cuenta cuántas llamadas recibió cada réplica en su
`grpc_server_requests_total`.

**Criterio:** tres números que suman veinte (o lo que sumen las ventas que llegaron a `pricing`).

<details><summary>Solución</summary>

`task measure -- B-23 --runs 1 --rate 20 --modes client` lo hace por ti; a mano, `kubectl exec` a un pod que pueda
llegar al 8080 de cada réplica (`replenish`, por la `NetworkPolicy`) y un `fetch` a `http://<ip-del-pod>:8080/metrics`.
Por el `Service` no sirve: cada lectura cae en una réplica distinta.
</details>

### 🟢 Ejercicio 3 — El *headless*, por dentro
Resuelve `pricing` y `pricing-grpc` desde un pod del namespace `apps`.

**Criterio:** una IP para `pricing` (la del `Service`) y una por réplica para `pricing-grpc`.

<details><summary>Solución</summary>

Un contenedor efímero con busybox (`kubectl debug … --image=busybox@sha256:…`, la de `a01`) y `nslookup`. El *headless*
no tiene IP propia: su DNS contesta con las de los pods listos.
</details>

### 🟢 Ejercicio 4 — Las reglas de kube-proxy
Encuentra en un nodo las reglas de `iptables` del puerto gRPC de `pricing` y explica las probabilidades.

**Criterio:** las tres reglas, y por qué 0,33 y 0,5 dan un tercio a cada una.

<details><summary>Solución</summary>

`docker exec lab-worker iptables-save -t nat | grep "apps/pricing:grpc ->"`. La primera regla atrapa un tercio; de los
dos tercios que pasan, la segunda atrapa la mitad (otro tercio); la tercera, el resto.
</details>

### 🟢 Ejercicio 5 — Una conexión
Durante una corrida con `balancing=service`, cuenta las conexiones establecidas al 9090 de cada réplica.

**Criterio:** 1, 0 y 0 (en algún orden).

<details><summary>Solución</summary>

`pricing` es distroless y no trae `ss`: se lee `/proc/<pid>/net/tcp6` del proceso desde el nodo (`crictl inspect` da el
PID) y se cuentan las filas con puerto local `2382` (9090) y estado `01`. Con `balancing=client`, son tres conexiones,
una por réplica.
</details>

### 🟢 Ejercicio 6 — La traza de una venta
Haz una venta bajo el umbral, saca su `trace_id` del log de `inventory` y mírala con `task obs:trace`.

**Criterio:** los cuatro servicios en la traza, y el `POST` a `replenish` terminando después que `POST /sales`.

<details><summary>Solución</summary>

Un `COUNT` que deje la existencia en el umbral y una venta de una unidad (sección 5.7). Si sale con dos spans de
`catalog` y nada más, espera unos segundos: los demás exportan en lotes.
</details>

### 🟢 Ejercicio 7 — El mismo `trace_id` en los logs
Con el `trace_id` del ejercicio 6, encuentra las líneas de los cuatro servicios en sus logs.

**Criterio:** la línea `request` de `inventory` y la de `pricing` con ese `trace_id`; y las de `catalog` y `replenish`
con el `request_id`, que es lo que llevan.

<details><summary>Solución</summary>

G10 pidió el `trace_id` en la línea `request` de `pricing`; el agente lo pone en el MDC de `inventory`. `catalog` y
`replenish` no lo escriben en el log: es el ejercicio 12.
</details>

## 🟡 Intermedio — llevar el patrón a otro sitio (8–14)

### 🟡 Ejercicio 8 — B-23 con cinco réplicas
Repite B-23 con cinco réplicas de `pricing` (cambia el `3` de `B23Run` o escala a mano).

**Criterio:** 100 % a una con `service` y un 20 % cada una con `client`.

<details><summary>Solución</summary>

El reparto de `round_robin` es exacto mientras el cliente conozca todas; el de `service` no depende de cuántas haya.
</details>

### 🟡 Ejercicio 9 — Dos réplicas de `inventory`
Con dos réplicas de `inventory` y el `Service` normal, ¿cuántas réplicas de `pricing` trabajan?

**Criterio:** el reparto medido, y la cuenta de por qué es "una o dos".

<details><summary>Solución</summary>

Cada `inventory` abre su conexión y tira su dado: las dos pueden caer en la misma réplica (1/3) o en distintas. La
carga de `pricing` queda atada a cuántos clientes hay, no a cuántas réplicas.
</details>

### 🟡 Ejercicio 10 — La edad, en minutos
Pon `global.grpc.maxConnectionAge: 2m` y repite la prueba de la réplica nueva (`--scale --modes client+age`, ajustando
la edad en `B23Run.set_mode`).

**Criterio:** cuánto tardó la réplica nueva en recibir su primera llamada.

<details><summary>Solución</summary>

Hasta dos minutos (más el ±10 % de grpc-go): en una corrida de sesenta segundos puede recibir cero. Es el precio de
saludar menos: la edad es la espera máxima de una réplica nueva.
</details>

### 🟡 Ejercicio 11 — `replenish` como cliente gRPC
Si `replenish` también le pidiera precios a `pricing` por gRPC, ¿qué tendría que configurar? Escribe las variables y
la línea de Node que elige la política.

**Criterio:** el destino `dns:///` al *headless*, la política `round_robin` en la configuración del canal de
`@grpc/grpc-js`, y el certificado de cliente.

<details><summary>Solución</summary>

En `@grpc/grpc-js`, la opción del canal es `'grpc.service_config'` con `loadBalancingConfig: [{round_robin: {}}]`. Es
la sección 12: cada lenguaje lo escribe distinto, y cada cliente nuevo puede olvidarlo.
</details>

### 🟡 Ejercicio 12 — El `trace_id` en PHP y en Node
Agrega el `trace_id` a la línea `request` de `catalog` o de `replenish`.

**Criterio:** la línea con el mismo `trace_id` que la traza, y la suite de G7 pasando.

<details><summary>Solución</summary>

En los dos, la API de OpenTelemetry da el span activo (`Span::getCurrent()->getContext()->getTraceId()` en PHP;
`trace.getActiveSpan()?.spanContext().traceId` en Node). Es un campo opcional para el contrato de G7.
</details>

### 🟡 Ejercicio 13 — Un campo nuevo en el contrato
Agrega al `Price` un campo `string valid_until = 7;`, genera los dos lados y despliega solo `pricing`.

**Criterio:** `inventory` (sin regenerar) sigue vendiendo; explica por qué.

<details><summary>Solución</summary>

Protobuf ignora los campos que no conoce: un número nuevo no rompe al cliente viejo. Lo que rompe es cambiar el tipo o
el número de uno que ya existe, o reutilizar un número borrado (para eso está `reserved`).
</details>

### 🟡 Ejercicio 14 — El canal frío
Reinicia `inventory`, haz una venta, haz otra, y compara en sus trazas el span del cliente gRPC con el del servidor.

**Criterio:** la diferencia entre los dos spans en la primera venta y en la segunda.

<details><summary>Solución</summary>

En la verificación: 826 ms contra 14 en la primera, y 5,2 contra 0,9 en una venta en caliente. La primera abre el canal
(DNS y TLS). Un *warm-up* que haga una llamada antes de declararse listo lo evita; la readiness de G4 no la hace.
</details>

## 🟠 Difícil — diagnosticar (15–20)

### 🟠 Ejercicio 15 — El nombre que falta
Quita `pricing-grpc.apps.svc.cluster.local` de los `dnsNames` del `Certificate` de `pricing`, espera la renovación y haz
una venta.

**Criterio:** el error exacto en el log de `inventory`, y cuál de las cuatro preguntas de la [Fase 19](19-tls-y-certificados.md) falló.

<details><summary>Solución</summary>

Falla la del nombre: el cliente pidió `pricing-grpc…` y el certificado no lo tiene. Con `balancing=service` funcionaría,
porque el nombre del `Service` normal sí está. `task deploy FORCE=true` lo devuelve.
</details>

### 🟠 Ejercicio 16 — Todo a una, con `client`
Alguien dejó `balancing: client` y el reparto sigue en 100 %. Encuentra por qué sin mirar el chart.

**Criterio:** la variable que delata el error, leída del pod.

<details><summary>Solución</summary>

`kubectl -n apps get deploy inventory -o jsonpath='{..env}'`: `PRICING_GRPC_POLICY=pick_first`, o un destino sin
`dns:///` que apunta al `Service`. La línea `canal gRPC a pricing: …` del log de `inventory` también lo dice.
</details>

### 🟠 Ejercicio 17 — La réplica fría
Escala `pricing` a cuatro con `maxConnectionAge` vacío y `balancing: client`. ¿Cuánto tarda la cuarta en recibir
algo? Provoca que la reciba sin reiniciar `inventory`.

**Criterio:** cero llamadas antes, y la acción que lo cambió.

<details><summary>Solución</summary>

Nunca, mientras nada falle. Borrar uno de los pods de `pricing` lo cambia: la conexión cae, grpc-java vuelve a
resolver, y aparece la cuarta. Es un arreglo por accidente; la edad máxima es el de verdad.
</details>

### 🟠 Ejercicio 18 — La traza partida
Quita el `Context.current().wrap(...)` de `SalesController`, reconstruye y busca el aviso a `replenish` en Tempo.

**Criterio:** dos trazas para una venta, y el `trace_id` ausente en la línea del aviso.

<details><summary>Solución</summary>

La traza de la venta tiene tres servicios; el `POST` a `replenish` aparece como raíz de otra traza. Es lo que pasó en la
verificación de esta fase.
</details>

### 🟠 Ejercicio 19 — ¿Por qué tardó esta venta?
Con el caos de la [Fase 22](22-resiliencia-y-caos.md) encendido (`perfil sogamoso-con-lluvia`), haz diez ventas, elige la más lenta y explica con su
traza dónde se fue el tiempo.

**Criterio:** el span que se lleva el tiempo, y cuántos intentos hizo `inventory` a `catalog`.

<details><summary>Solución</summary>

Con el agente, cada llamada del `RestClient` es un span de cliente: los intentos de G9 deberían verse como spans
hermanos bajo la venta, con sus esperas entre uno y otro y el corte de cada uno a los 2 s. Si no se ven así, eso
también es una respuesta: dice qué instrumenta el agente y qué no.
</details>

### 🟠 Ejercicio 20 — HTTP/1.1, a propósito
Con gRPC apagado, fuerza HTTP/1.1 en el cliente del JDK de `inventory` (`HttpClient.Version.HTTP_1_1`) y repite B-23
en modo `http`.

**Criterio:** el reparto, comparado con el de HTTP/2 (100 %) y el del 8080 (50 % de mediana).

<details><summary>Solución</summary>

Con HTTP/1.1, el pool abre una conexión por petición concurrente: a veinte por segundo, una o dos. El reparto mejora un
poco y no se arregla. La conclusión es la misma de B-23: el problema es la conexión que dura.
</details>

## 🔴 Muy difícil — medir y diseñar (21–24)

### 🔴 Ejercicio 21 — Un proxy en el medio
Pon un Envoy (o la puerta, con un `GRPCRoute`) entre `inventory` y `pricing`, y repite B-23 con el `Service` normal.

**Criterio:** el reparto y la mediana de la venta, en la tabla de la sección 8.

**Rúbrica:** el reparto por llamada (un tercio cada una), el salto de más en la mediana, y quién termina el mTLS:
el proxy tiene que presentar el certificado de cliente a `pricing`, o `pricing` tiene que aceptar al proxy.

### 🔴 Ejercicio 22 — Que Tempo no tumbe a `catalog`
Con Tempo en cero réplicas, haz que `catalog` siga contestando rápido sin apagar las trazas.

**Criterio:** sesenta lecturas de `catalog` con Tempo caído, con un máximo menor de un segundo.

**Rúbrica:** dos caminos. Bajar el timeout del exportador (`OTEL_EXPORTER_OTLP_TIMEOUT`, en milisegundos), que limita
la espera pero la sigue cobrando en cada petición; o un OpenTelemetry Collector en el nodo (un `DaemonSet`), al que los
cuatro exportan y que contesta siempre, con o sin Tempo. Mide los dos, y di cuál pondrías en producción.

### 🔴 Ejercicio 23 — La tabla de B-23, completa
Corre B-23 con los cinco modos y la prueba de la réplica nueva en tu máquina.

**Criterio:** la tabla de la sección 8 y la de `BENCHMARKS.md`, con tus números.

**Rúbrica:** las mismas conclusiones, o la explicación de por qué no. Ojo con la memoria: con trazas, Prometheus y
Grafana encendidos a la vez, la máquina virtual de 4 GiB no alcanzó.

### 🔴 Ejercicio 24 — La recomendación para Luz Marina
Contesta la pregunta de la sección 1 en una página: qué cambia en La Vecina si las llamadas internas van por gRPC, y
qué hace falta para que el `Service` no repita el balanceador de 2012.

**Criterio:** una página, con B-23 como evidencia.

**Rúbrica:** el `Service` reparte conexiones; el arreglo elegido y sus dos piezas; el costo por cliente; cuándo
convendría un mesh; y el caso de Tempo caído, que es el riesgo nuevo que trae la fase.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- gRPC, *Load Balancing*: https://grpc.io/blog/grpc-load-balancing/
- gRPC, *Keepalive* y *MaxConnectionAge* (grpc-go): https://pkg.go.dev/google.golang.org/grpc/keepalive
- gRPC Java, *NameResolver y LoadBalancer*: https://grpc.github.io/grpc-java/javadoc/io/grpc/LoadBalancer.html
- Kubernetes, *Headless Services*: https://kubernetes.io/docs/concepts/services-networking/service/#headless-services
- Kubernetes, *Virtual IPs and Service Proxies*: https://kubernetes.io/docs/reference/networking/virtual-ips/
- Protocol Buffers, *Language Guide (proto 3)*: https://protobuf.dev/programming-guides/proto3/
- OpenTelemetry, *Context propagation*: https://opentelemetry.io/docs/concepts/context-propagation/
- OpenTelemetry, *Java agent*: https://opentelemetry.io/docs/zero-code/java/agent/
- OpenTelemetry, *PHP auto-instrumentation*: https://opentelemetry.io/docs/zero-code/php/
- OpenTelemetry, *Node.js zero-code*: https://opentelemetry.io/docs/zero-code/js/
- Grafana Tempo, *Configuration*: https://grafana.com/docs/tempo/latest/configuration/
- W3C, *Trace Context*: https://www.w3.org/TR/trace-context/

**Libros y ensayos**

- Benjamin H. Sigelman y otros, *Dapper, a Large-Scale Distributed Systems Tracing Infrastructure* (Google, 2010): de
  donde salen los spans y las trazas.
- Austin Parker y otros, *Distributed Tracing in Practice* (O'Reilly, 2020): instrumentación, propagación y muestreo.
- William Morgan, *gRPC Load Balancing on Kubernetes without Tears* (Buoyant, 2018): el mismo problema de esta fase,
  contado desde un mesh.

**Orden de lectura sugerido:** antes, *gRPC Load Balancing* (el blog de gRPC); durante, *Headless Services* con la
sección 5.4 delante; después, el artículo de Dapper, para ver de dónde salió todo lo de la sección 5.6.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 23 (cluster lab, valores de minimo)

  apps           los cuatro backends en :g10; pricing sirve GetPrice por gRPC en el 9090 con mTLS;
                 inventory lo pide por el headless pricing-grpc con round_robin, y pricing corta las
                 conexiones a los 10 s (global.grpc: enabled, balancing=client, maxConnectionAge=10s)
  observability  Tempo (Tempo 3, backend_worker), encendido con task obs:on -- traces
  contracts      contracts/proto/pricing/v1/pricing.proto; task proto genera pricingv1/
  tareas         proto, obs:trace; task measure -- B-23 [--scale] [--modes …]
  bench/b23      ventas.js y los resultados de B-23
```

> **La señal de que quedó bien:** *"Sé cuántas llamadas recibe cada réplica, no solo el servicio; elijo quién reparte
> y cómo ve las réplicas nuevas; y ante una venta lenta abro su traza antes de abrir cuatro logs."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, las suites pasando y `git status` limpio:
>
> ```bash
> git tag -a fase-23-grpc-y-el-balanceo -m "F23 cerrada: G10, pricing por gRPC con mTLS y el contrato en Protobuf; B-23, el Service reparte conexiones y HTTP/2 manda todo por una, headless con round_robin y edad máxima de conexión; trazas con OpenTelemetry en los cuatro runtimes y Tempo, con el contexto pasado al hilo del aviso"
> ```
>
> Commits con prefijo `f23:`.

---

## 📌 Pendientes sugeridos

- **F24:** la saga, sobre trazas que ya cruzan los cuatro servicios; cada paso y cada compensación, un span.
- **F25:** el aviso a `replenish` que se pierde: la traza ya muestra que sale después de la venta, y no que llegó.
- **`a10`:** el balanceo por llamada sin tocar el cliente, con un mesh; y el ejercicio 21, con números.
- **La máquina virtual:** con trazas, Prometheus y Grafana a la vez, 4 GiB no alcanzaron; queda medirlo en B-00.
