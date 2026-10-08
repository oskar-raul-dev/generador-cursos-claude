# 04 — gRPC

Este taller es **opcional** y depende de [`03` — HTTP entre servicios](03-http-entre-servicios.md): parte
de su sistema, con `inventory` y `payments` fuera del monolito. Da a `inventory` un contrato `.proto` y
un servidor gRPC, **saca `orders` del monolito** como servicio Java que habla gRPC con el inventario, y
pone a prueba tres promesas de gRPC con evidencia: que el deadline viaja con la llamada (y qué pasa si
el servidor lo ignora), que un cambio incompatible del contrato lo caza una herramienta antes del
despliegue, y que "gRPC es más rápido" depende de qué midas. Termina cuando la suite `v1` pasa en verde
a través de Envoy con `orders` extraído, y las provocaciones y la medición tienen su salida pegada.

> Ejercita [`02/03` — gRPC](../02-comunicacion/03-grpc.md), [`02/04` — HTTP contra gRPC](../02-comunicacion/04-http-contra-grpc.md)
> y [`02/07` — Contratos y versionado](../02-comunicacion/07-contratos-y-versionado.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en `proxy.golang.org`, PyPI, Docker Hub y el
> BOM de Spring Boot 4.1.1; salidas corridas ese día en un Apple M1 Pro con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--parte-1-el-proto-es-el-contrato) · [6](#6--parte-2-orders-sale-del-monolito) · [7](#7--parte-3-el-deadline-que-el-servidor-ignora) · [8](#8--parte-4-buf-breaking-antes-del-despliegue) · [9](#9--parte-5-la-medición-honesta) · [10](#10--hallazgos-al-correrlo) · [11](#11--en-tres-plataformas) · [12](#12--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

```text
cliente ──► Envoy ─┬─ /api/v1/orders*, /api/v1/notifications ──► orders (Java) :28082 ──► ms_orders
                   │      x-jwt-payload (identidad ya verificada)   │  │  │
                   │                                                │  │  └─HTTP─► payments (Python)
                   │                                                │  └─HTTP (token relay)─► monolith: catálogo
                   │                                                └─gRPC, deadline 800 ms─► Toxiproxy :28193
                   │                                                                            └─► inventory (Go) :28093
                   └─ el resto ──► ms-monolith :28081 (catalog + customers)

contrato/proto/ms/inventory/v1/inventory.proto ──► Go (buf generate) · Java (build) · Python (al vuelo)
```

Cuatro ideas, una por parte:

- **El `.proto` es el contrato, y se compila.** Un archivo genera los stubs de tres lenguajes, y un
  linter y un detector de rupturas lo vigilan. La ventaja principal de gRPC no es el ancho de banda: es
  que el contrato falla al compilar en vez de en producción
  ([`02/03`](../02-comunicacion/03-grpc.md)).
- **`orders` sale, y el strangler lo nota solo en Envoy.** Dos rutas más específicas encima de la
  general y la suite no distingue quién responde. Lo que cambia por dentro es mucho: identidad del
  gateway, catálogo por red con el token del usuario, y una foto del correo del cliente.
- **El deadline viaja; que se respete es otra cosa.** Con el deadline propagado hasta la consulta, el
  servidor abandona el trabajo cuando el cliente se rinde. Con el contexto desacoplado, el servidor
  **trabaja para nadie** y deja una retención huérfana que la compensación no alcanza.
- **La medición honesta no da un número bonito.** La misma reserva por HTTP y por gRPC difiere medio
  milisegundo en la mediana, y en una de tres corridas gRPC pierde. Aquí manda la base de datos.

El precio, en las cinco monedas: **latencia** (un salto gRPC y uno HTTP más por pedido; el catálogo por
red en cada alta), **consistencia** (la foto del correo puede quedar vieja; el pedido y la reserva siguen
sin transacción común), **operación** (un proceso Java más, un generador de código en tres builds, un
proxy más), **dinero** (una instancia y una base más) y **esfuerzo** (≈ 1 250 líneas de Java en `orders`,
la mitad movidas del monolito; ≈ 110 de Go para el servidor gRPC; 69 de `.proto`).

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Todo lo de `06/03` | la de `06/03` §2 | Envoy, monolito, `inventory`, `payments`, PSP |
| `bufbuild/buf` (Docker) | `1.73.0` | lint, generación de Go y detección de rupturas; nada que instalar |
| Plugins remotos de buf | `protocolbuffers/go:v1.36.12` · `grpc/go:v1.6.2` | stubs de Go |
| `google.golang.org/grpc` · `…/protobuf` | `v1.84.0` · `v1.36.12` | servidor gRPC de `inventory` |
| `google.golang.org/genproto/googleapis/rpc` | `v0.0.0-20260928230214-8a89bd6388cc` | `errdetails` (detalle estructurado de errores) |
| gRPC Java · protobuf Java | `1.83.1` · `4.35.1` (BOM de Boot 4.1.1) | cliente gRPC de `orders`; `spring-boot-starter-grpc-client` |
| `io.github.ascopes:protobuf-maven-plugin` | la del BOM de Boot 4.1.1 | stubs de Java en cada build |
| `grpcio` · `grpcio-tools` | `1.84.0` | cliente Python y generación al vuelo (`tools/bench`) |

```text
python3 laboratorio/scripts/lab.py up && python3 laboratorio/scripts/lab.py seed
python3 laboratorio/scripts/lab.py psp                                            # terminal 1
python3 laboratorio/scripts/lab.py inventory                                      # terminal 2: HTTP :28083 y gRPC :28093
python3 laboratorio/scripts/lab.py payments                                       # terminal 3
python3 laboratorio/scripts/lab.py monolith --inventory remote --payments remote  # terminal 4
python3 laboratorio/scripts/lab.py orders                                         # terminal 5
```

- `up` publica ahora el proxy `inventory-grpc` (`28193` → `host.docker.internal:28093`); Envoy trae el
  clúster `orders`.
- `seed` añade `ms_orders`.
- `inventory` arranca además el servidor gRPC en `:28093`; `--detach-deadline` activa la provocación de
  §7.
- `orders` compila con `mvn -q -DskipTests package` —que genera los stubs Java del `.proto`— y arranca en
  `:28082`. `--deadline MS` cambia el plazo gRPC hacia `inventory` (800 ms por defecto).

Las órdenes nuevas de este taller:

```text
python3 laboratorio/scripts/lab.py buf lint | generate | breaking
python3 laboratorio/scripts/lab.py lock-stock SKU-001 --seconds 5
python3 laboratorio/scripts/lab.py bench --n 300
```

- `buf` ejecuta `bufbuild/buf:1.73.0` en Docker con el laboratorio montado y el directorio de trabajo en
  `contrato/proto`. `breaking` compara la copia de trabajo con el `.proto` del último estado congelado
  (`estados/04/`), que hace de "rama principal".
- `lock-stock` abre en `ms_inventory` una transacción que hace `SELECT … FOR UPDATE` sobre la fila del
  SKU y espera N segundos (`pg_sleep`): cualquier retención de ese SKU espera al bloqueo. Es la forma de
  hacer lento al servidor **sin tocar su código**.
- `bench` sincroniza `tools/bench` con `uv` y corre la medición de §9.

> **📝 Contexto:** el código tal como queda al terminar este taller está congelado en
> `laboratorio/estados/04/`, y las rutas con número de línea se refieren a esa copia. Si ya existen
> talleres posteriores, añade `--estado 04` a cada orden de `lab.py`.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/estados/04/                                (lab.py --estado 04)
├── contrato/
│   ├── proto/buf.yaml · buf.gen.yaml                  lint STANDARD, breaking FILE; plugins remotos
│   ├── proto/ms/inventory/v1/inventory.proto          el contrato gRPC
│   ├── envoy/envoy.yaml                               + rutas y clúster de orders
│   └── seed/orders/schema.sql                         ms_orders, sin FK a users ni products
├── inventory/
│   ├── gen/ms/inventory/v1/                           inventory.pb.go · inventory_grpc.pb.go (generados)
│   └── internal/grpcapi/server.go                     el servidor gRPC sobre el mismo store
├── orders/                                            el servicio extraído, Java
│   └── src/main/java/dev/ms/orders/
│       ├── inventory/GrpcInventory.java               cliente gRPC + capa anticorrupción
│       ├── catalog/HttpCatalog.java                   catálogo del monolito, con token relay
│       ├── web/ActorResolver.java                     identidad desde x-jwt-payload
│       └── service/ · payments/ · entity/ · …         movidos del monolito
└── tools/bench/bench.py                               cliente Python: HTTP frente a gRPC
```

El monolito **no cambia** en este taller: su código de pedidos sigue ahí, pero ya no le llega tráfico.
Es un strangler honesto: lo que se sustituye se deja de usar antes de borrarse (ejercicio 🟠 6).

## 4. 🔎 Recorrido de la base de código

Rutas relativas a `laboratorio/estados/04/`.

**¿Dónde se decide quién atiende `/api/v1/orders`?** `contrato/envoy/envoy.yaml`, líneas 56 y 58: dos
rutas por prefijo hacia el clúster `orders`, **antes** de la general, porque Envoy usa la primera que
casa.

**¿De dónde saca `orders` quién es el usuario?** `orders/.../web/ActorResolver.java`, línea 23: decodifica
`x-jwt-payload` (base64url) y lee `sub`, `email` y `role`. No verifica firma: confía en que el
encabezado lo puso Envoy. §10 muestra cuándo esa confianza es un agujero.

**¿Dónde nace el deadline y dónde muere?** Nace en `orders/.../inventory/GrpcInventory.java`, línea 47:
`withDeadlineAfter(deadlineMs, …)` en **cada** llamada. Viaja en el encabezado `grpc-timeout`. En el
servidor, `inventory/internal/grpcapi/server.go` lo recibe en el `ctx`: la línea 50 no empieza si ya
venció, y el `ctx` llega hasta la consulta de `pgx`, que se cancela al vencer. La línea 30 es la
provocación: `context.WithoutCancel(ctx)` desacopla el trabajo del plazo.

**¿Cómo viaja un "sin stock"?** `server.go`, línea 72: `FAILED_PRECONDITION` con dos detalles
estructurados, `PreconditionFailure` (qué SKU) y `ErrorInfo` (cuánto hay por SKU). En `GrpcInventory`,
línea 57 lo distingue de "no sé" y la 90 lee el `ErrorInfo`: el texto del mensaje no se parsea nunca.

**¿Cómo pide `orders` el catálogo?** `orders/.../catalog/HttpCatalog.java`, línea 42: reenvía el
`Authorization` de la petición en curso al monolito (*token relay*). `orders` no tiene credenciales
propias.

## 5. 🔀 Parte 1: el `.proto` es el contrato

**Qué es.** Un archivo, `inventory.proto`, con el servicio `InventoryService` y cuatro RPC unarias
(`GetStock`, `Hold`, `Release`, `Commit`), en el mismo vocabulario que la API HTTP del taller 02.

```proto
service InventoryService {
  rpc GetStock(GetStockRequest) returns (GetStockResponse);
  rpc Hold(HoldRequest) returns (HoldResponse);          // idempotente por referencia
  rpc Release(ReleaseRequest) returns (ReleaseResponse);
  rpc Commit(CommitRequest) returns (CommitResponse);
}
message HoldItem {
  string sku = 1;
  int32 qty = 2;                                         // el número es la identidad del campo
}
```

- `package ms.inventory.v1` y la ruta `ms/inventory/v1/` coinciden: es lo que exige el lint `STANDARD`, y
  el `v1` en el paquete es el sitio donde vivirá la próxima versión incompatible.
- Los errores no van en los mensajes: van en el `Status` (§4).

**Tres lenguajes, un archivo**:

```text
python3 laboratorio/scripts/lab.py buf lint           # sin salida = sin problemas
python3 laboratorio/scripts/lab.py buf generate       # → inventory/gen/ms/inventory/v1/*.pb.go
```

- Go: `buf generate` con los plugins remotos del Buf Schema Registry (`buf.gen.yaml`); sin `protoc` ni
  `protoc-gen-go` instalados. Los archivos generados se versionan con el servicio.
- Java: `protobuf-maven-plugin` los genera en cada `mvn package` a partir de `../contrato/proto`; no se
  versionan.
- Python: `grpc_tools.protoc` los genera al vuelo en `tools/bench/gen/` la primera vez.

> **Veredicto:** el contrato compilado cuesta un paso de generación en cada build y disciplina con los
> números de campo. A cambio, tres lenguajes no pueden discrepar sobre la forma de un mensaje, y el
> desacuerdo se descubre al compilar.

## 6. 🔀 Parte 2: `orders` sale del monolito

**Qué es.** El código de pedidos, pagos y notificaciones se muda a un servicio propio con su base
(`ms_orders`). No es un copiar y pegar: cada dependencia que en el monolito era una tabla ahora es una
llamada, y cada una obliga a una decisión.

| Lo que en el monolito era | En `orders` es | Decisión |
|---|---|---|
| `JwtDecoder` de Spring Security | `x-jwt-payload` de Envoy | confiar en el gateway; sin firma que verificar (§10 dice cuándo es un agujero) |
| `products` (tabla) | `GET /api/v1/products` del monolito | *token relay*: el token del usuario viaja |
| `users.email` para el aviso | `orders.customer_email` | foto del correo al crear el pedido, tomada del token |
| `LocalInventory` / `RemoteInventory` HTTP | `GrpcInventory` | deadline por llamada, errores estructurados |
| FK a `users` y `products` | referencias por identificador | la integridad pasa a ser del flujo |

**Envoy** solo añade dos rutas encima de la general:

```yaml
- match: { prefix: "/api/v1/orders" }
  route: { cluster: orders, timeout: 10s }
- match: { prefix: "/api/v1/notifications" }
  route: { cluster: orders, timeout: 10s }
- match: { prefix: "/" }                    # el resto sigue yendo al monolito
```

La suite a través de Envoy, 2026-09-29, **a la primera**:

```text
Success 01-health.hurl (1 request(s) in 7 ms)
Success 02-auth.hurl (5 request(s) in 380 ms)
Success 03-products.hurl (4 request(s) in 204 ms)
Success 04-orders.hurl (16 request(s) in 1021 ms)
Success 05-payment.hurl (12 request(s) in 2351 ms)
Success 06-cancel.hurl (8 request(s) in 197 ms)
Executed requests: 46 (11.0/s)
Succeeded files:   6 (100.0%)
```

Y la prueba de que quien responde es otro:

```text
06:31:38 POST /api/v1/orders → 201 29ms upstream=192.168.65.254:28082 via_upstream
06:31:40 GET /api/v1/notifications → 200 11ms upstream=192.168.65.254:28082 via_upstream
ms_orders.orders|6
ms_monolith.orders|0
```

- `04-orders.hurl` pasó de ≈ 400 ms a ≈ 1 000 ms: cada alta cruza ahora catálogo (HTTP), inventario
  (gRPC) y la base de `orders`. Es el precio en latencia, medido por la propia suite.

> **Veredicto:** extraer el corazón cuesta más que extraer las hojas: tres dependencias remotas, una
> foto de datos ajenos y una decisión de confianza. Con la costura y el gateway ya puestos, el cambio
> visible para el cliente fue cero.

## 7. 🧨 Parte 3: el deadline que el servidor ignora

**El síntoma.** El inventario va lento por bloqueos. `orders` responde `503` a tiempo, como debe, pero
aparecen retenciones que no corresponden a ningún pedido y el stock "desaparece".

```text
python3 laboratorio/scripts/lab.py lock-stock SKU-001 --seconds 5
```

**Con el deadline propagado** (el servidor normal). 2026-09-29:

```text
{"instance":"/api/v1/orders","status":503,"title":"Inventory unavailable","code":"INVENTORY_UNAVAILABLE"}
→ 503 en 0.850641s
--- inventory (log)
2026/09/29 01:32:08 Hold: context canceled (caller: context canceled)
--- holds
(0 rows)
 on_hand
---------
      20
WARN … inventory Hold for order e902cba4-…: Status{code=DEADLINE_EXCEEDED, description=CallOptions deadline exceeded after …
```

- `orders` recibió `DEADLINE_EXCEEDED` a los 800 ms y compensó. En `inventory`, el `ctx` de la llamada
  llegó hasta la consulta bloqueada; al irse el cliente, `pgx` la canceló y la transacción se deshizo:
  **ni una fila**, stock intacto.

**Con el contexto desacoplado** (`lab.py inventory --detach-deadline`), misma prueba:

```text
{"instance":"/api/v1/orders","status":503,"title":"Inventory unavailable","code":"INVENTORY_UNAVAILABLE"}
→ 503 en 0.862405s
--- inventory (log)
2026/09/29 01:32:38 Hold 77384a26-…: done AFTER the caller gave up (context canceled)
--- holds
              reference               |   sku   | qty | status |    creada
--------------------------------------+---------+-----+--------+--------------
 77384a26-2022-4f6e-ba08-7f75c3ad32c6 | SKU-001 |   1 | HELD   | 06:32:34.311
 on_hand
---------
      19
pedidos en ms_orders|0
```

**La cadena:**

```text
orders: Hold con deadline 800 ms ──► inventory espera el bloqueo de SKU-001
   │ 800 ms: DEADLINE_EXCEEDED, orders compensa con Release ──► Release no encuentra nada (0)
   ▼
inventory, con el contexto desacoplado, sigue esperando ──► a los 5 s consigue el bloqueo
   ▼
retiene 1 unidad para un pedido que no existe ──► HELD huérfana, stock 19
```

- Para el cliente, las dos corridas son idénticas: `503` en 0,85 s. La diferencia está **en el
  servidor**: en una abandona, en la otra trabaja para nadie y deja estado.
- La compensación no alcanza porque llegó **antes** de que existiera lo que tenía que compensar. Un
  `release` idempotente no arregla una operación que todavía no ha ocurrido.
- `creada` (`created_at`, 06:32:34) es la hora de **inicio** de la transacción, no del commit (06:32:38 en el
  log): `now()` en PostgreSQL es el instante en que empezó la transacción. Para una autopsia, la hora
  del log es la que dice cuándo se consolidó el daño.

> **Veredicto:** propagar el deadline es la mitad; la otra mitad es que el servidor lo **respete** hasta
> el último recurso que toca. Un `context.WithoutCancel` puesto para "silenciar errores de cancelación"
> convierte cada timeout del cliente en trabajo huérfano.

## 8. 🧨 Parte 4: `buf breaking` antes del despliegue

**La provocación**: alguien renumera un campo, "porque el 3 queda más ordenado".

```text
sed -i '' 's/  int32 qty = 2;/  int32 qty = 3;/' contrato/proto/ms/inventory/v1/inventory.proto
python3 laboratorio/scripts/lab.py buf breaking
```

- `sed -i ''` edita el archivo en su sitio (la forma de macOS; en Linux, `sed -i` sin comillas).
- `buf breaking` compara la copia de trabajo con `estados/04/contrato/proto`.

Salida literal, 2026-09-29:

```text
comparando contrato/proto con estados/04/contrato/proto
ms/inventory/v1/inventory.proto:40:1:Previously present field "2" with name "qty" on message "HoldItem" was deleted.
código de salida con el campo renumerado: 100
código de salida tras revertir: 0
```

- El cambio **compila** en los tres lenguajes: el nombre `qty` sigue ahí. Lo que se rompe es el cable:
  un cliente viejo manda la cantidad en el campo 2 y el servidor nuevo la busca en el 3, lee `0`, y
  retiene cero unidades sin error ([`02/03`](../02-comunicacion/03-grpc.md) §2).
- El código de salida 100 es lo que hace útil la herramienta: en un pipeline, el despliegue se detiene.

> **Veredicto:** un contrato compilado sin detector de rupturas protege a quien genera, no a quien ya
> está desplegado. `buf breaking` en el pipeline es la pieza que convierte "el número es la identidad"
> en una regla que nadie puede olvidar.

## 9. 🔀 Parte 5: la medición honesta

**Qué se mide.** La misma operación —retener y liberar una unidad de `SKU-002`— por HTTP (`:28083`) y por
gRPC (`:28093`) contra el mismo servicio y la misma base, desde un cliente Python secuencial con la
conexión reutilizada en los dos casos. 300 muestras más 30 de calentamiento.

**Qué no mide**: concurrencia, red real, TLS, mensajes grandes ni streaming. Reproducción local, un solo
nodo, sin red real, un Apple M1 Pro. **No se extrapola.**

Tres corridas seguidas, 2026-09-29:

```text
retener y liberar 1 × SKU-002, secuencial; cada muestra = 2 llamadas
HTTP   n=300  p50   3.20 ms   p90   4.64 ms   p99   7.94 ms   media   3.61 ms
gRPC   n=300  p50   2.66 ms   p90   3.44 ms   p99   4.90 ms   media   2.79 ms
HTTP   n=300  p50   3.18 ms   p90   4.45 ms   p99   5.79 ms   media   3.45 ms
gRPC   n=300  p50   2.59 ms   p90   3.16 ms   p99   3.67 ms   media   2.82 ms
HTTP   n=300  p50   3.22 ms   p90   4.00 ms   p99   5.42 ms   media   3.37 ms
gRPC   n=300  p50   3.17 ms   p90   4.86 ms   p99  11.64 ms   media   3.62 ms
```

- En dos corridas, gRPC gana ≈ 0,5 ms de mediana; en la tercera empata en mediana y pierde en la cola.
  Cada muestra son dos transacciones en PostgreSQL con `FOR UPDATE`: el protocolo es una fracción de un
  tiempo dominado por la base.
- La frase para la entrevista no es "gRPC fue un 17 % más rápido". Es: **"en este servicio el protocolo
  no es el cuello de botella; elijo gRPC por el contrato y el deadline, no por la latencia"**.

## 10. 🩺 Hallazgos al correrlo

No hubo errores de compilación ni de arranque: la suite pasó a la primera. Hubo tres hallazgos, y el
primero es el más importante del taller.

### La identidad del gateway se puede falsificar si se salta el gateway

```text
=== por Envoy: token de ana + x-jwt-payload que dice que ana es operator
1 pedido(s) visible(s)
=== directo a orders :28082 con el mismo encabezado
2 pedido(s) visible(s)
```

A través de Envoy, el filtro JWT **sobrescribe** `x-jwt-payload` con el contenido del token verificado:
el encabezado inventado desaparece. Directo al puerto de `orders`, nadie lo sobrescribe y `orders` lo
cree: una clienta se convierte en operadora. **Corrección** (no aplicada en el laboratorio, que expone
los puertos a propósito): que `orders` solo sea alcanzable desde Envoy —red interna, `NetworkPolicy`,
mTLS entre gateway y servicio— o que `orders` verifique la firma del token. **Lección:** "confiar en el
gateway" es una decisión de red, no de código.

### El servidor ve `context canceled`, no `deadline exceeded`

El cliente recibe `DEADLINE_EXCEEDED`; el servidor registra `context canceled`. El cliente vence su
plazo y cancela el *stream* (HTTP/2 `RST_STREAM`) un instante antes de que el servidor llegue a su propia
copia del plazo, calculada desde `grpc-timeout` al recibir la llamada. **Lección:** en el servidor, los
dos significan lo mismo —nadie espera ya la respuesta— y hay que tratarlos igual.

### La compensación llegó antes que la operación

Descrito en §7. **Lección:** la compensación inmediata cubre el caso en que la operación ya ocurrió; si
todavía no ha ocurrido, hace falta que la operación caduque sola o que el servidor respete el plazo.

## 11. 🧰 En tres plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | `spring-boot-starter-grpc-client` y la fábrica de canales; stubs generados en el build; `withDeadlineAfter` y `StatusProto` para leer detalles | Poner el deadline en **cada** llamada (un stub con plazo fijo caduca) y traducir cada código a su significado; en Boot 4, las claves de configuración exactas (`channel`, `target`) |
| **Go** | gRPC como ciudadano de primera: el deadline llega como `ctx` y `pgx` lo respeta; `status.FromContextError`, `errdetails` | No romper la cadena del `ctx` (el `WithoutCancel` de §7 es una línea) y generar con `buf` |
| **Python** | `grpcio` síncrono o `grpc.aio`; `timeout=` por llamada; stubs con `grpc_tools.protoc` | Elegir modelo (síncrono o `aio`) y no mezclarlos; en el servidor, comprobar `context.is_active()` o `time_remaining()` antes del trabajo caro |

La fila de Node/TS —`@grpc/grpc-js` con `deadline` en las opciones de la llamada— está en
[`02/03`](../02-comunicacion/03-grpc.md).

## 12. 🧹 Teardown

```text
Ctrl+C en las terminales de psp, inventory, payments, monolith y orders
python3 laboratorio/scripts/lab.py down
```

- `down` borra también `ms_orders`. Los stubs generados de Go (`inventory/gen/`) se quedan: se versionan.
  `tools/bench/gen/` y los `target/` son reproducibles y están en `.gitignore`.

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "gRPC es más rápido" | Aquí, medio milisegundo en la mediana y a veces nada: el tiempo es de la base. Se elige por contrato y deadline |
| "El deadline se propaga solo" | Viaja solo en la llamada; que el servidor lo respete depende de que el `ctx` llegue hasta el último recurso |
| "Si compila, el cambio del `.proto` es compatible" | Renumerar un campo compila en los tres lenguajes y rompe el cable; para eso está `buf breaking` |
| "Detrás del gateway no hace falta autenticar" | Solo si nadie puede llegar al servicio sin pasar por el gateway; si no, el encabezado de identidad se falsifica |
| "El error va en un campo `success: false`" | Va en el `Status`, con detalles estructurados; el texto del mensaje no se parsea |
| "Extraer el corazón es como extraer una hoja" | Cada tabla que era local es ahora una llamada con su latencia, su fallo y su decisión |

## 📚 Para profundizar

- **Libro** — Kasun Indrasiri y Danesh Kuruppu, *gRPC: Up and Running*, O'Reilly, 2020, cap. 5, "gRPC:
  Beyond the Basics" (deadlines, cancelación, manejo de errores).
- **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021, cap. 5, "Implementing
  Microservice Communication".
- **Documentación** — gRPC: [deadlines](https://grpc.io/docs/guides/deadlines/) ·
  [códigos de estado](https://grpc.io/docs/guides/status-codes/) · [manejo de errores](https://grpc.io/docs/guides/error/).
- **Documentación** — [buf: breaking](https://buf.build/docs/breaking/) · [buf: lint](https://buf.build/docs/lint/)
  · [Protocol Buffers: proto3](https://protobuf.dev/programming-guides/proto3/).
- **Documentación** — [Spring Boot: gRPC](https://docs.spring.io/spring-boot/reference/io/grpc.html) ·
  [Go: `context.WithoutCancel`](https://pkg.go.dev/context#WithoutCancel) ·
  [Envoy v1.39.1: `JwtProvider`](https://www.envoyproxy.io/docs/envoy/v1.39.1/api-v3/extensions/filters/http/jwt_authn/v3/config.proto).
- **Especificación** — [Google AIP-193, *Errors*](https://google.aip.dev/193) (el modelo de `google.rpc.Status` y
  sus detalles).

## 🧠 Preguntas

1. ¿Qué genera el `.proto` de `inventory` y quién lo genera en cada lenguaje? 🟢
2. ¿Por qué el deadline se pone en cada llamada y no una vez en el stub? 🟢
3. ¿Qué hace `lab.py lock-stock` y por qué provoca lentitud sin tocar el código del servidor? 🟢
4. ¿Qué es `x-jwt-payload` y quién lo escribe? 🟢
5. ¿Por qué `orders` guarda el correo del cliente en su propia tabla? 🟡
6. ¿Qué diferencia hay entre `DEADLINE_EXCEEDED` en el cliente y `context canceled` en el servidor? 🟡
7. ¿Por qué el detalle de "sin stock" va en `ErrorInfo` y no en el texto del mensaje? 🟡
8. ¿Qué te da Go para respetar el deadline hasta la base de datos, y qué línea lo rompe? 🟡
9. El cambio de `qty = 2` a `qty = 3` compila en los tres lenguajes. ¿Qué pasa en producción si se despliega? 🟡
10. Con el contexto desacoplado, la compensación del cliente no liberó nada. ¿Por qué, y qué la habría hecho funcionar? 🟠
11. La medición dio medio milisegundo a favor de gRPC en dos de tres corridas. ¿Qué dices si te preguntan cuál es más rápido? 🟠
12. ¿Es correcto que `orders` confíe en `x-jwt-payload`? ¿Qué tendría que ser verdad? 🟠
13. Dibuja el alta de un pedido con `orders` extraído: cada salto, su protocolo, su plazo y qué pasa si falla. 🔴
14. En producción, el stock de un SKU baja sin pedidos que lo expliquen y ves `DEADLINE_EXCEEDED` en el cliente. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

## 🧪 Ejercicios

1. 🟢 Añade al `.proto` un campo nuevo y compatible (`string note = 3` en `HoldRequest`) y demuestra con
   `lab.py buf breaking` que no rompe. Luego borra el campo `reference` y pega lo que dice.
2. 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde traduce `orders` un
   `FAILED_PRECONDITION` de `inventory` al `409 INSUFFICIENT_INVENTORY` del contrato, y qué dato usa para
   calcular el índice `lines[i]`.
3. 🟢 Repite §7 con `lab.py orders --deadline 3000` y el bloqueo de 5 s. ¿Qué cambia para el cliente y para
   el servidor? Pega la salida.
4. 🟡 Usa `grpcurl` en Docker (`fullstorydev/grpcurl`) para llamar a `GetStock` sin stubs. ¿Por qué falla sin
   reflexión, y qué dos formas hay de arreglarlo?
5. 🟠 Haz que `orders` rechace peticiones que no vengan de Envoy sin romper la suite: por ejemplo, un secreto
   compartido que Envoy añade como encabezado y `orders` comprueba. Repite la prueba de §10 y pega la salida.
6. 🟠 Borra del monolito el código de pedidos que ya no recibe tráfico. ¿Qué te dice `git diff --stat` sobre
   cuánto quedaba, y qué comprobarías antes de hacerlo en producción?
7. 🔴 Repite la medición de §9 con 20 clientes concurrentes. ¿Cambia la conclusión? ¿Qué parte de la
   diferencia atribuyes a HTTP/2 y cuál a la base?
8. 🔥 Expón `CreateOrder` de `orders` por gRPC además de HTTP, con el mismo caso de uso detrás, y mide cuánto
   código es transporte y cuánto es negocio.

---

**Anterior:** [`03` — HTTP entre servicios](03-http-entre-servicios.md). **Siguiente:**
[`05` — Resiliencia en tres plataformas](05-resiliencia-en-tres-plataformas.md). **Relacionado:** [`02/04` — HTTP contra gRPC](../02-comunicacion/04-http-contra-grpc.md).
