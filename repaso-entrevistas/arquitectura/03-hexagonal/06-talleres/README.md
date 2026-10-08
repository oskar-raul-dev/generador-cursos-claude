# 06 — Talleres

Este bloque implementa el sistema de pedidos y pagos de los capítulos y lo hace correr. **Todo aquí
es opcional**: el corpus teórico (bloques 01–05) se sostiene solo, y ningún capítulo ni simulación
depende de un taller. Lo que el bloque añade es palpar dónde queda cada frontera cuando el framework
empuja en contra, y demostrarlo con un comando que termina en verde en vez de con un diagrama.

> **Vigencia:** 2026-09-28.

## 🧭 Mapa

```text
01 · contrato, suite, entorno                 prerrequisito de todo
 ├── 02 · frontend                             opcional incluso dentro del bloque
 ├── 03 · Java y Spring Boot (patrón) ┐
 ├── 04 · TypeScript y NestJS         │
 ├── 05 · Go                          ├ sabores: uno o varios, independientes entre sí
 ├── 06 · Python y FastAPI            │
 └── 07 · PHP y Laravel               ┘

01 + 03
 ├── 08 · colas (Artemis)             ┐
 ├── 09 · tópicos (Kafka)             ├ integraciones: solo Java, extienden el 03
 ├── 10 · gRPC                        │
 └── 11 · lotes (Spring Batch)        ┘
```

| Taller | Qué construye | Lo que se palpa | Depende de |
|---|---|---|---|
| [01 · Contrato OpenAPI y suite](01-contrato-openapi-y-suite.md) | `openapi.yaml`, suite `hurl`, compose, semilla, `lab.py` | el contrato como puerto de entrada visto desde fuera; "terminado" como comando | — |
| [02 · Frontend mínimo en React](02-frontend-minimo-react.md) | cliente HTTP detrás de un puerto, con MSW y con backend real | el frontend como *driving adapter* que no distingue entre ambos | 01 |
| [03 · Java y Spring Boot](03-caso-java-spring-boot.md) | las tres partes; ArchUnit; `OrderRecord` separado | proxies, `@Entity` como tentación, `@Transactional` en el borde | 01 |
| [04 · TypeScript y NestJS](04-caso-typescript-nestjs.md) | las tres partes; `dependency-cruiser`; Prisma | tipos que desaparecen al ejecutar, tokens, `AsyncLocalStorage` | 01 |
| [05 · Go](05-caso-go.md) | las tres partes; biblioteca estándar y `pgx` | transacción en el `context`, interfaces implícitas, errores como valores | 01 |
| [06 · Python y FastAPI](06-caso-python-fastapi.md) | las tres partes; `import-linter`; SQLAlchemy Core | `Protocol` sin comprobación, `Depends` como tentación, `ContextVar` | 01 |
| [07 · PHP y Laravel](07-caso-php-laravel.md) | las tres partes; `deptrac`; Query Builder sin Eloquent | *active record* que quiere ser el dominio, fachadas, manejador de errores web | 01 |
| [08 · Colas con JMS y ActiveMQ Artemis](08-colas-jms-activemq-artemis.md) | `orders.inbound` → `CreateOrder` → `orders.reply` | commit antes del ACK, re-entrega, DLQ, consumidores competidores | 01, 03 |
| [09 · Tópicos con Kafka](09-topicos-kafka.md) | outbox → `orders.events`; notificaciones y proyección | orden por clave, commit de offset tras el efecto, reconstrucción | 01, 03 |
| [10 · gRPC](10-grpc.md) | `payments-grpc` detrás del mismo `PaymentGateway` | plazos, `UNAVAILABLE` como resultado incierto, idempotencia por metadata | 01, 03 |
| [11 · Lotes con Spring Batch](11-lotes-spring-batch.md) | `stockAdjustment` y `dailyClose`; `AdjustStock` | chunk como transacción, `JobRepository` como checkpoint, reinicio exacto | 01, 03 |
| [12 · Respuestas](12-respuestas.md) | solucionario de los once talleres | 154 preguntas y 88 ejercicios con enunciado literal | — |

Cada sabor tiene las mismas tres partes —núcleo; cancelación con outbox; catálogo a MongoDB sin
tocar `domain/`, `application/` ni `inbound/`— y termina cuando la **misma** suite pasa contra él
cambiando solo la URL base. Esa es la prueba de que los cinco núcleos son intercambiables. Cada
integración añade una puerta de entrada o de salida al sabor Java y declara qué cambió en el núcleo
con `git diff --stat`.

## 🎯 Cómo elegir

- **Una tarde:** `01` y el sabor de tu entrevista. Para un perfil Java, `01` → `03`.
- **Tech Lead Java:** `01` → `03` → `08` o `09`, según el sistema use colas o log. Son las dos
  preguntas de mensajería que más se repiten: qué pasa entre el commit y el ACK, y por qué el offset
  se confirma después del efecto.
- **Comparar ecosistemas:** `01` → `03` y un segundo sabor que conozcas poco. `03` es el patrón y
  los otros cuatro se leen como diferencias sobre él; hacer los cinco enseña menos que hacer dos con
  atención.
- **Resiliencia hacia proveedores:** `10`. Es el único que convierte "el timeout es incertidumbre"
  del capítulo [04/02](../04-adaptadores-de-salida-y-operacion/02-clientes-http-grpc-y-servicios-externos.md)
  en un pedido que queda pendiente y no rechazado.
- **Procesos masivos o nocturnos:** `11`. Es el que más obliga a separar el caso de uso del mecanismo
  de ejecución.
- **Frontend:** `02` solo si quieres ver la frontera desde el otro lado; ningún sabor lo necesita.

No hace falta hacerlos en orden ni hacerlos todos. Lo que no conviene es saltarse `01`: sin la suite
no hay forma de saber cuándo un sabor está terminado.

## 🧰 Qué necesitas

Docker con Compose v5, `hurl` 8.0.1 y Python 3.11 o superior; todo lo demás (PostgreSQL, MongoDB,
Redis, Swagger UI, el mock, y los brokers de 08 y 09) lo trae el compose. Cada sabor pide además su
propia toolchain, con versión exacta en la sección 2 de su taller: JDK 25 y Maven para Java, Node 24
para NestJS y el frontend, Go 1.27, Python 3.14 con `uv`, PHP 8.4 con Composer y la extensión
`mongodb`.

El código vive en [`laboratorio/`](laboratorio/). Todo se orquesta con un único script,
`laboratorio/scripts/lab.py`, solo con biblioteca estándar, igual en macOS, Linux y Windows.

## ✅ Comprobar que el laboratorio arranca

La prueba de humo mínima, desde la carpeta del curso (`03-hexagonal/`):

```text
python3 06-talleres/laboratorio/scripts/lab.py check
python3 06-talleres/laboratorio/scripts/lab.py up
python3 06-talleres/laboratorio/scripts/lab.py seed --mongo
python3 06-talleres/laboratorio/scripts/lab.py java --catalog mongo        # en otra terminal
python3 06-talleres/laboratorio/scripts/lab.py suite --base-url http://localhost:8081
python3 06-talleres/laboratorio/scripts/lab.py down
```

- `check` confirma que `docker`, `docker compose` y `hurl` están en el `PATH` e imprime sus versiones.
- `up` levanta el compose común (`hex-postgres`, `hex-mongo`, `hex-redis`, `hex-swagger`) y espera
  a que los cuatro estén sanos.
- `seed --mongo` recarga la semilla de PostgreSQL y, con `--mongo`, también el catálogo en MongoDB.
- `java --catalog mongo` arranca el sabor Java en `:8081` con el catálogo en MongoDB (parte 3); se
  queda en primer plano, por eso va en otra terminal. Necesita `JAVA_HOME` apuntando a un JDK 25.
- `suite --base-url` corre los siete archivos `hurl` (`v1` y `v1.1`) contra esa URL; es el mismo
  comando para cualquier sabor, cambiando solo el puerto (`8082`–`8085`).
- `down` apaga y borra los contenedores; los datos no sobreviven, a propósito.

Salida de la suite en la máquina de referencia, 2026-09-28 (las rutas y los tiempos dependen del
sistema):

```text
Executed files:    7
Executed requests: 85 (18.4/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          4615 ms (0h:0m:4s:615ms)
```

Si esto termina en verde, cualquier taller puede empezar. Cada uno repite `up` al principio y
`down` al final.

## 🔗 Continuación

[← Plataformas y práctica](../05-plataformas-y-practica/README.md) · [Índice general](../README.md) · [Empezar por el contrato →](01-contrato-openapi-y-suite.md)
