# 📡 Proyecto 2 — EventRelay Service
## Entrega fiable de eventos a socios comerciales · Meridian Retail Group

> **Eje técnico:** cliente HTTP, reintentos, idempotencia, contrapresión,
> resiliencia.
> **Nace:** Fase 02, en Go 1.13 · **Migra:** Fase 08 · **Cierra:** Fase 17.
> **Módulo:** `services/eventrelay` · **Binarios:** `eventrelay`, `fakeconsumer`.

---

## 1. El problema

Meridian integra a una treintena de socios: transportistas, pasarelas de pago,
marketplaces, el ERP del grupo. Cada uno quiere enterarse cuando pasa algo:
`order.created`, `payment.approved`, `shipment.dispatched`,
`settlement.completed`.

Hoy cada servicio productor llama directamente a los consumidores, y eso produce
el incidente que todo el mundo ha visto: **un socio lento cuelga al productor.**
La pasarela de un partner tarda ocho segundos, el hilo se queda esperando, el
pool se agota, y de pronto Meridian no puede registrar ventas porque un tercero
tiene un mal día.

**EventRelay** se pone en medio. El productor publica el evento, recibe un
acuse en milisegundos y sigue. La entrega ocurre en segundo plano, con
reintentos, retroceso exponencial, firma, historial de intentos y cola de
mensajes muertos.

Si OpsReport es el servicio que un dev de Spring ya sabe hacer, **EventRelay es
el que Go hace notablemente mejor**: miles de entregas concurrentes, cada una
esperando E/S de red, es exactamente el trabajo para el que existe una goroutine.

---

## 2. Objetivo funcional

1. Registrar y administrar endpoints de socios, con su secreto de firma.
2. Activar y desactivar un endpoint sin perder su historial.
3. Suscribir un endpoint a patrones de tipo de evento (`order.*`).
4. Publicar un evento, con clave de idempotencia opcional.
5. Crear una entrega por cada endpoint suscrito.
6. Entregar por HTTP con tiempo límite, firmado con HMAC.
7. Registrar cada intento con su estado, su latencia y su error.
8. Clasificar el fallo en recuperable o permanente, y reintentar solo el primero.
9. Aplicar retroceso exponencial con *jitter* y un máximo configurable.
10. Limitar la concurrencia global y por endpoint.
11. Mandar a la cola de muertos lo que agote los intentos.
12. Reprocesar manualmente una entrega o una cola de muertos completa.
13. Cancelar entregas pendientes de un endpoint dado de baja.
14. Recuperar el trabajo pendiente tras un reinicio.
15. Consumir el outbox de OpsReport (Fase 13).
16. Exponer `/health`, `/ready` y `/metrics`.

---

## 3. Entidades

### `Endpoint`

```text
ID            string
Name          string
URL           string      validada: solo https en producción, sin IP privada
Secret        string      nunca se devuelve por la API, nunca se registra en log
Enabled       bool
EventPatterns []string    order.*  ·  payment.approved  ·  *
MaxRPS        int         límite de tasa propio del socio
CreatedAt, UpdatedAt time.Time
```

> ⚠️ La validación de URL es un tema de seguridad, no de formato: aceptar
> `http://169.254.169.254/` convierte a EventRelay en una herramienta de SSRF
> contra la propia infraestructura. Se trata en la Fase 14 y tiene sus ejercicios
> 🔴.

### `Event`

```text
ID              string
Type            string
Payload         json.RawMessage   se guarda tal cual; no se reinterpreta
IdempotencyKey  string            único cuando está presente
Source          string            qué servicio lo publicó
CreatedAt       time.Time
```

### `Delivery`

```text
ID            string
EventID       string
EndpointID    string
Status        string     pending | delivering | delivered | retry_scheduled
                         | failed | cancelled | dead_letter
AttemptCount  int
NextAttemptAt *time.Time
LastError     string
CreatedAt     time.Time
CompletedAt   *time.Time
```

### `DeliveryAttempt`

```text
ID            string
DeliveryID    string
AttemptNumber int
StartedAt     time.Time
FinishedAt    time.Time
HTTPStatus    int          0 cuando ni siquiera hubo respuesta
DurationMS    int64
ErrorMessage  string
Classification string      transient | permanent
```

---

## 4. API objetivo

```http
POST   /endpoints
GET    /endpoints
GET    /endpoints/{id}
PUT    /endpoints/{id}
DELETE /endpoints/{id}

POST   /events                     con cabecera Idempotency-Key
GET    /events
GET    /events/{id}
GET    /events/{id}/deliveries

GET    /deliveries?status=&endpoint=&from=&to=
GET    /deliveries/{id}
GET    /deliveries/{id}/attempts
POST   /deliveries/{id}/retry
POST   /deliveries/{id}/cancel
POST   /dead-letters/replay

GET    /health · /ready · /metrics
```

La entrega saliente:

```http
POST https://partner.example.com/webhooks
Content-Type: application/json
X-Meridian-Event-Id: evt_01HQ...
X-Meridian-Event-Type: order.created
X-Meridian-Delivery-Id: dlv_01HQ...
X-Meridian-Attempt: 3
X-Meridian-Timestamp: 1772611920
X-Meridian-Signature: sha256=...
```

La firma se calcula sobre `timestamp + "." + body` y **el timestamp entra en el
hash** — si no, cualquiera puede reenviar un mensaje interceptado. Se explica en
la Fase 14 con su ataque de repetición.

---

## 5. Política de reintentos

Base pedagógica de la Fase 06, endurecida en la 10:

```text
intento 1  ->  inmediato
intento 2  ->  +1s     · con jitter de ±20%
intento 3  ->  +2s
intento 4  ->  +4s
intento 5  ->  +8s
...        ->  base * 2^(n-1), tope de 1h, máximo 12 intentos
agotado    ->  dead_letter
```

Clasificación, que **es una función pura y se prueba con tabla**:

```text
transient:  408, 429, 500, 502, 503, 504
            timeout, connection refused, DNS temporal, EOF
permanent:  400, 401, 403, 404, 410, 422
            URL inválida, certificado TLS inválido, cuerpo ilegible
```

El `429` con cabecera `Retry-After` se respeta, y eso también se prueba.

> 🧭 **La regla:** no todo fallo se reintenta, y reintentar un `400` doce veces
> no es resiliencia, es acoso a un socio que ya te dijo que el mensaje está mal.

---

## 6. `fakeconsumer`: el segundo binario

Dentro del propio módulo vive un consumidor falso, y es una pieza pedagógica de
primer orden: permite probar reintentos sin depender de internet ni de un socio
real.

```http
POST /ok          200 inmediato
POST /slow        responde tras N segundos (parametrizable)
POST /fail/{code} devuelve el código pedido
POST /flaky       falla las dos primeras veces, responde 200 a la tercera
POST /verify      valida la firma HMAC y responde 401 si no cuadra
POST /hang        acepta la conexión y no responde nunca
```

Nace en la Fase 05 con tres rutas y crece hasta la 14. Es también el sitio donde
el estudiante ve **el otro lado del webhook**, que es lo que le van a pedir
implementar en su trabajo tan a menudo como el emisor.

---

## 7. Arquitectura objetivo

```text
services/eventrelay/
  cmd/eventrelay/main.go
  cmd/fakeconsumer/main.go
  internal/relay/          dominio: evento, entrega, estados        (F02)
  internal/eventrelay/     casos de uso                             (F02)
  internal/memstore/                                                (F02)
  internal/postgres/                                                (F09)
  internal/httpapi/                                                 (F05)
  internal/dispatch/       cola, workers, planificador de reintentos (F06-F07)
  internal/deliver/        cliente HTTP, clasificación, backoff      (F10)
  internal/signature/      HMAC y verificación                       (F14)
  internal/ratelimit/      límite por endpoint sobre Valkey          (F12)
  migrations/ · testdata/
```

---

## 8. Avance por fase

**Fase 02 — nace.** `Endpoint`, `Event`, `Delivery` y la máquina de estados de la
entrega, que es más rica que la de OpsReport y por eso llega después. Servicios y
almacén en memoria.

**Fase 03.** Errores del dominio, configuración, y la decodificación del cuerpo
entrante con `json.RawMessage` — el payload del socio **no se reinterpreta**, y
explicar por qué es una clase entera sobre acoplamiento.

**Fase 04.** Tabla exhaustiva de la máquina de estados, tests de la clasificación
de errores, fake de reloj para probar el cálculo del retroceso sin esperar ocho
segundos. Es el primer sitio donde el estudiante ve **por qué el reloj se
inyecta**.

**Fase 05.** La API REST, el `fakeconsumer` con sus tres primeras rutas, y la
entrega todavía simulada.

**Fase 06 ⭐.** El motor real: cola de entregas con búfer acotado, N workers,
`select` sobre el canal de trabajo y el de apagado, el contador de intentos que
en la primera versión **tiene una carrera de datos a propósito** y `-race` la
encuentra. Laboratorio de contrapresión: qué pasa cuando el productor publica más
rápido de lo que los socios absorben.

💸 El planificador de reintentos vive en memoria con un `time.Timer` por entrega.
Funciona y es didáctico; **se paga en la Fase 09**, cuando la reprogramación pasa
a ser una columna `next_attempt_at` y una consulta.

**Fase 07.** Tiempo límite por entrega, cancelación propagada al cliente HTTP,
apagado ordenado que espera a las entregas en vuelo hasta un límite y después las
devuelve a `pending`.

**Fase 08.** Migra. Fuzzing (Go 1.18) sobre el verificador de firmas y el decodificador
de payloads —es el caso de uso perfecto y el curso lo aprovecha—, `slog`,
`errgroup` reemplazando el `WaitGroup` manual, y el `ServeMux` moderno.

**Fase 09.** PostgreSQL con el modelo de cuatro tablas, la cola en base de datos
con `SELECT ... FOR UPDATE SKIP LOCKED` —que es la joya de la fase—, y el test
que mata el proceso a mitad de una entrega y verifica que se recupera.

**Fase 10.** El cliente HTTP en serio: `Transport` reutilizado y dimensionado,
tiempos límite en las cuatro capas, drenaje del cuerpo antes de cerrarlo,
retroceso con *jitter*, cortacircuitos por endpoint, y **los mocks generados**
para verificar que reintentó tres veces y no cuatro.

**Fase 12.** Límite de tasa por socio sobre Valkey, e idempotencia distribuida
con `SET NX` y TTL.

**Fase 13.** Consume el outbox de OpsReport: los dos servicios se conectan por
fin, y el flujo `WorkItem completado → evento → entrega al socio` funciona de
punta a punta.

**Fase 14.** Firma HMAC con timestamp, validación de URL contra SSRF, secretos
que nunca aparecen en un log —con el ejercicio 🧨 de registrarlos a propósito y
ver qué queda en la salida—, métricas por endpoint, y trazas que cruzan de
OpsReport a EventRelay al socio.

**Fase 15.** Perfilado del despacho: cuánto cuesta la firma, cuánto la
serialización, cuánto el `Transport` mal reutilizado, y el rendimiento sostenido
de entregas por segundo contra el `fakeconsumer`.

---

## 9. Los temas que este proyecto enseña y los otros no

- **El cliente HTTP bien configurado**, que es de lo que menos se habla y más
  incidentes causa.
- **La semántica de entrega**: al menos una vez, idempotencia, duplicados, y por
  qué "exactamente una vez" no existe sobre HTTP.
- **La contrapresión** de verdad, con un productor rápido y un consumidor lento.
- **La clasificación de errores** como función pura y probada, en vez de un
  `catch (Exception e) { retry(); }`.
- **El fallo parcial**: veintinueve socios bien y uno caído, y que eso no degrade
  a los veintinueve.
- **La criptografía mínima** que un backend usa de verdad: HMAC, comparación en
  tiempo constante, y por qué `==` sobre firmas es un bug de seguridad.

---

## 10. Qué NO se construye aquí

Kafka, RabbitMQ ni NATS. La cola es PostgreSQL, y la Fase 13 explica con números
dónde deja de bastar. Tampoco hay multi-tenencia, ni entrega por lotes, ni
suscripciones con transformación de payload: son ampliaciones 🔥 listadas en la
Fase 17 para quien quiera seguir.

---

## 11. Criterio de finalización

1. Registra endpoints, valida sus URL y nunca devuelve ni registra el secreto.
2. Acepta un evento en menos de 20 ms p95 con la base bajo carga.
3. Dos publicaciones con la misma `Idempotency-Key` producen un solo evento.
4. Entrega firmada, y el `fakeconsumer` verifica la firma.
5. Un socio caído produce reintentos con retroceso y termina en la cola de
   muertos, sin afectar a los demás.
6. Un `400` no se reintenta ni una vez.
7. Un `429` con `Retry-After` respeta el valor indicado.
8. Matar el proceso a mitad de una entrega no pierde la entrega.
9. El límite de tasa por endpoint se respeta con dos instancias corriendo.
10. Apaga limpio, devolviendo a `pending` lo que no alcanzó a terminar.
11. `go test -race ./...` y la suite de integración en verde.
12. Sostiene el rendimiento declarado en su entrada de `BENCHMARKS.md` con el
    `fakeconsumer` como destino.

---

## 12. 📖 El diccionario de este proyecto

| Spring | EventRelay en Go | Dónde se rompe |
|---|---|---|
| `RestTemplate` / `WebClient` | `http.Client` con `Transport` propio | El cliente por defecto no tiene timeout; el tuyo sí o te cuelgas |
| `@Retryable` / `RetryTemplate` | Una función `backoff(attempt) time.Duration` | Es código tuyo: lo pruebas con tabla y lo lees entero |
| `@Recover` | La rama que marca `dead_letter` | No hay despacho por tipo de excepción; clasificas tú |
| `CircuitBreaker` de Resilience4j | Un struct con contador y ventana | Sin anotación, sin proxy, sin sorpresas de AOP |
| `@Async` + `CompletableFuture` | goroutine + canal | No hay `Future` que consultar; el resultado viaja o se guarda |
| `ThreadPoolTaskExecutor` | Canal con búfer + N workers | El tamaño de la cola es tuyo; no hay política de rechazo por defecto |
| WireMock | `httptest.Server` + `fakeconsumer` | Sin DSL de stubs: es un handler, y se lee mejor |
| `@Scheduled` para reprogramar | Consulta `next_attempt_at <= now()` | Con dos instancias hace falta `SKIP LOCKED`, no una anotación |
| `MessageDigest` / `Mac` | `crypto/hmac` + `hmac.Equal` | `hmac.Equal` es tiempo constante; `bytes.Equal` no, y eso importa |
