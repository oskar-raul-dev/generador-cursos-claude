# 03 — Resiliencia en la práctica

> Timeouts, reintentos, circuit breaker, bulkhead, límite de tasa y degradación: qué hace cada uno,
> con qué se implementa en cada plataforma, y con qué números se configura. Es la comparativa
> insignia del corpus. Asume leídos
> [`02-comunicacion/02`](../02-comunicacion/02-http-entre-servicios.md) y
> [`01-fundamentos-y-descomposicion/04`](../01-fundamentos-y-descomposicion/04-el-monolito-distribuido.md).
> El razonamiento de fondo está en
> [`arquitectura/01-bases/01-bases/09`](../../01-bases/01-bases/09-resiliencia.md).
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

`payments` tarda ocho segundos por una consulta lenta. Nadie ha desplegado nada. Y a los cinco minutos
`orders` devuelve errores en **todas** sus rutas, incluidas las que no tocan `payments`:

```text
payments lento (8 s)
   │
   ▼
orders: los hilos que llaman a payments se quedan esperando
   │
   ▼
el pool de hilos se agota
   │
   ▼
orders deja de atender TODO: también /catalog y /profile
```

La lección que hay que poder decir en una frase: **lo que se propaga no es el error, es la lentitud**,
y se propaga **hacia arriba**, contra la dirección de las llamadas. El servicio que se cae no es el
que falla.

Este capítulo son las seis piezas que cortan esa cadena, en orden de efecto: timeout, reintento con
criterio, circuit breaker, bulkhead, límite de tasa y degradación.

---

## 2. 🧱 Timeout: la pieza número uno

**Qué es.** El plazo máximo que esperas una respuesta antes de rendirte y liberar el recurso.

**Cómo va.** Se calcula, no se inventa:

```text
timeout ≈ p99 de la dependencia + margen
   …y SIEMPRE menor que el presupuesto de la petición que lo contiene
   …y decreciente según se baja en la cadena
```

Si tu endpoint promete un segundo y llamas a otro con timeout de dos, has roto tu promesa antes de
empezar. Y si el timeout del que llama es menor que el tuyo, tu trabajo se tira a la basura: él ya se
rindió.

**Con qué.** En el cliente HTTP ([`02-comunicacion/02`](../02-comunicacion/02-http-entre-servicios.md))
o en el deadline de gRPC ([`02-comunicacion/03`](../02-comunicacion/03-grpc.md)), que además se
propaga solo.

**Cuánto.** Cuesta elegir un número por dependencia y revisarlo cuando cambie el rendimiento del otro.
No cuesta nada más, y es la medida con mejor relación entre esfuerzo y efecto de todo el capítulo.

**Cuándo sí.** En toda llamada saliente, sin excepción.

**Cuándo no.** Si una operación legítimamente puede tardar minutos, no se le pone un timeout largo:
se saca de la ruta síncrona.

> **Veredicto:** sin timeout no hay resiliencia posible, porque ningún otro mecanismo llega a
> activarse: los recursos se agotan esperando. Es la única pieza de este capítulo que no es opcional
> en ningún escenario.

---

## 3. 🧱 Reintento: solo lo idempotente, y con jitter

**Qué es.** Volver a intentar lo que falló, cuando hay motivos para creer que puede funcionar.

**Cómo va.** Cuatro reglas, y las cuatro se preguntan en entrevistas:

- **Solo lo idempotente.** Un fallo de conexión es seguro; un timeout no, porque la operación pudo
  ejecutarse y perderse la respuesta. Sin clave de idempotencia, reintentar una escritura es apostar
  ([`03-datos-y-consistencia/04`](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md)).
- **Con espera exponencial.** Insistir de inmediato golpea al que ya iba mal.
- **Con jitter.** Sin aleatoriedad, todos los clientes reintentan sincronizados por el propio fallo y
  producen picos periódicos.
- **Con presupuesto.** Un tope de reintentos sobre el tráfico total —por ejemplo, un 10 %— evita que
  una degradación multiplique la carga.

```text
Sin jitter                     Con jitter
todos reintentan a la vez      se reparten en la ventana
▲    ▲    ▲                     ▁▂▃▂▁▂▃▂▁
```

**Cuánto.** Cada reintento multiplica la carga sobre un sistema que ya está peor. Dos reintentos
triplican el tráfico hacia la dependencia degradada.

**Cuándo no.** Cuando no sabes si la operación se ejecutó. Y **nunca en varias capas a la vez**: si
reintentan el cliente, la librería y el mesh, tres intentos se convierten en veintisiete.

> **⚠️ Advertencia:** el reintento es el único mecanismo de este capítulo que puede **empeorar** el
> incidente. Los demás, mal configurados, no ayudan; este, mal configurado, tumba lo que quedaba en
> pie.

---

## 4. 🧱 Circuit breaker

**Qué es.** Un interruptor que deja de intentarlo cuando está claro que la dependencia no responde.

```text
CERRADO ──(tasa de fallo > umbral)──► ABIERTO ──(pasa el tiempo)──► SEMIABIERTO
   ▲                                     │                              │
   │                                     └── rechaza sin llamar          │
   └──────────────(las pruebas van bien)─────────────────────────────────┘
```

**Cómo va.** Abierto, falla inmediatamente sin gastar recursos ni esperar timeouts. Tras un tiempo,
deja pasar unas pocas llamadas de prueba: si van bien, cierra; si no, vuelve a abrir.

**A quién protege.** Al que llama, no al caído. Aunque hay un efecto secundario útil: al dejar de
enviarle tráfico, el caído tiene margen para recuperarse. Y uno perjudicial: si todos los clientes
reabren a la vez, le mandan un pico justo cuando empieza a levantarse — por eso el semiabierto deja
pasar **unas pocas**, no todas.

**Con qué.** La tabla de §7. Y el detalle que casi nadie menciona: **el estado vive en el proceso**.
Con diez instancias hay diez circuit breakers independientes, cada uno con su visión parcial.

**Cuánto.** Cuesta elegir umbrales —tasa de fallo, ventana, tiempo de apertura— y aceptar que mientras
está abierto fallas rápido también las peticiones que habrían funcionado.

**Cuándo sí.** En dependencias que pueden degradarse y cuya caída no debe llevarse el servicio por
delante.

**Cuándo no.** En una dependencia sin la cual no puedes hacer nada: abrir el circuito contra tu propia
base de datos solo cambia un error por otro.

> **Veredicto:** el circuit breaker no evita la caída en cascada por sí solo: la evita el timeout,
> liberando recursos. Lo que añade el circuit breaker es dejar de gastar esos recursos en algo que ya
> sabes que va a fallar.

---

## 5. 🧱 Bulkhead, límite de tasa y degradación

**Bulkhead.** Compartimentos separados por dependencia: si `payments` va lento, consume su cuota de
hilos o de conexiones y no toca la del resto. Convierte un agotamiento total en una degradación
parcial, que es exactamente el fallo de §1.

```text
Sin bulkhead                    Con bulkhead
un pool para todo               un pool por dependencia
payments lento → pool agotado   payments lento → su pool agotado;
→ TODO falla                    el resto sigue atendiendo
```

📝 Con hilos virtuales, el argumento clásico del bulkhead —"los hilos son caros"— pierde fuerza, pero
el patrón no desaparece: el recurso escaso pasa a ser el pool de conexiones y la capacidad del otro
lado, y esos siguen necesitando compartimentos.

**Límite de tasa y rechazo temprano.** Aceptar solo lo que puedes atender. Rechazar rápido con `429`
es mejor para todos que aceptar una petición que va a agotar su timeout: consume recursos, ocupa
hilos y encima falla.

**Degradación.** Responder con menos en vez de no responder: el valor por defecto, la caché vieja, la
respuesta parcial marcada. Es la decisión que convierte una caída ajena en una molestia, y es de
producto tanto como técnica
([`03-datos-y-consistencia/02`](../03-datos-y-consistencia/02-consultas-entre-servicios.md)).

> **💡 Truco:** un fallback honesto dice que está degradado. Devolver un dato viejo o vacío sin
> marcarlo convierte un fallo visible en uno silencioso, y eso acaba en decisiones de negocio
> tomadas sobre datos incorrectos.

---

## 6. 🧱 Health checks, y el error que los convierte en incidente

Ya se definieron en
[`01-fundamentos-y-descomposicion/05`](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md);
aquí interesa su papel en la resiliencia:

```text
liveness   sin dependencias        → un fallo ajeno NUNCA debe reiniciarte
readiness  con las imprescindibles → un fallo propio te saca del balanceo
```

El error clásico —comprobar la base de datos en liveness— convierte una degradación en una caída
total con reinicios en bucle. Y hay una variante más sutil: poner en readiness una dependencia de la
que solo depende una ruta. Un fallo de `payments` sacaría del balanceo a un servicio que todavía puede
atender consultas, propagando la caída en vez de contenerla.

---

## 7. 🧰 En las cuatro plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti | Dónde vive el estado |
|---|---|---|---|
| **Java** | Librería de resiliencia completa —circuit breaker, reintento, bulkhead, límite de tasa— con anotaciones y métricas integradas | Elegir umbrales; y saber que la anotación va por proxy, así que una llamada interna del mismo objeto **no la atraviesa** | En el proceso, por instancia |
| **Node/TS** | Librería de circuit breaker que envuelve una función; el resto se compone a mano o con interceptores del marco | Reintento y bulkhead, que no vienen juntos; y cuidar que el estado no se comparta mal entre peticiones | En el proceso |
| **Go** | Circuit breaker como una struct que envuelve la llamada; `context` para plazos y cancelación | Todo lo demás: reintento con jitter, límite de concurrencia, métricas. Se ve entero | En el proceso, y hay que compartirlo entre goroutines explícitamente |
| **Python** | Decoradores de reintento muy maduros y circuit breaker como decorador | Que decoradores y modelo asíncrono convivan; y el estado por **proceso trabajador**, que con varios procesos multiplica |

En Java, la forma declarativa, con la trampa incluida:

```java
@CircuitBreaker(name = "payments", fallbackMethod = "paymentUnavailable")
@Retry(name = "payments")              // el reintento envuelve al circuit breaker: orden importante
public Payment charge(OrderId id, Money total) {
    return paymentsClient.charge(id, total);   // llamada real
}

private Payment paymentUnavailable(OrderId id, Money total, Throwable cause) {
    return Payment.pending(id);        // degradación EXPLÍCITA, no un null silencioso
}
```

- El orden entre reintento y circuit breaker no es cosmético: si el reintento envuelve al
  circuit breaker, cada intento cuenta como llamada y el circuito abre antes; al revés, los reintentos
  ocurren dentro y el circuito ve una sola llamada.
- La anotación funciona por proxy: si `charge` se llama desde otro método **del mismo objeto**, no
  pasa por el proxy y no se aplica nada. Es el fallo silencioso más común de este estilo.

En Go, lo mismo explícito, que es donde se ve lo que la anotación esconde:

```go
// El circuit breaker es una variable compartida: su estado es de este proceso.
var paymentsCB = gobreaker.NewCircuitBreaker(gobreaker.Settings{
    Name:        "payments",
    MaxRequests: 3,                    // llamadas de prueba en semiabierto
    Timeout:     30 * time.Second,     // cuánto permanece abierto
    ReadyToTrip: func(c gobreaker.Counts) bool {
        return c.Requests >= 20 && float64(c.TotalFailures)/float64(c.Requests) > 0.5
    },
})

res, err := paymentsCB.Execute(func() (any, error) {
    ctx, cancel := context.WithTimeout(ctx, 800*time.Millisecond) // timeout POR llamada
    defer cancel()
    return paymentsClient.Charge(ctx, id, total)
})
if errors.Is(err, gobreaker.ErrOpenState) {
    return pendingPayment(id), nil     // degradación explícita, igual que en Java
}
```

- `ReadyToTrip` con un mínimo de peticiones evita el fallo clásico: con tres llamadas y dos fallos, un
  umbral del 50 % abriría el circuito por ruido estadístico.
- El timeout va **dentro** de la ejecución protegida: el circuit breaker cuenta el timeout como fallo,
  que es lo que se quiere.

> **🧰 Plataforma:** la fila que más rinde de la tabla es la última. **El estado del circuit breaker
> vive en el proceso**, así que con diez instancias hay diez decisiones independientes: unas cortan y
> otras no, y el comportamiento agregado es gradual en vez de binario. En Python con varios procesos
> trabajadores, se multiplica también dentro de la misma instancia. Casi nadie lo dice, y explica
> comportamientos que si no parecen aleatorios.

---

## 8. 🩺 La cadena completa, y dónde se corta

```text
dependencia lenta
   │  ← timeout: libera el recurso  (medida 1)
hilos/conexiones ocupados
   │  ← bulkhead: limita el daño a esa dependencia  (medida 2)
pool agotado
   │  ← circuit breaker: deja de intentarlo  (medida 3)
cola de peticiones crece
   │  ← límite de tasa: rechaza temprano  (medida 4)
timeouts aguas arriba
   │  ← degradación: responde con menos  (medida 5)
caída
```

El orden de implantación es ese mismo, porque es el orden de relación entre efecto y esfuerzo. Un
equipo que solo pueda hacer una cosa, que ponga timeouts; si puede hacer dos, timeouts y degradación.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El circuit breaker evita la caída en cascada" | La evita el **timeout**, liberando recursos. El circuit breaker evita seguir gastándolos en algo que ya falla |
| "Reintentamos tres veces por si acaso" | Solo lo idempotente, con backoff, jitter y presupuesto. Y en una sola capa: reintentos anidados se multiplican |
| "El timeout por defecto está bien" | Varios clientes no traen timeout de lectura. "Por defecto" suele significar "esperar indefinidamente" |
| "Con el mesh ya no necesitas resiliencia en el código" | El mesh reintenta y corta, pero no sabe si tu operación es idempotente ni qué degradación tiene sentido |
| "El circuit breaker protege al servicio caído" | Protege al que llama. Al caído le da respiro, y le manda un pico cuando todos reabren a la vez |
| "Ponemos la base de datos en el liveness" | Eso reinicia todas tus instancias mientras la base está caída. Va en readiness, si acaso |
| "El fallback devuelve vacío y listo" | Un fallback sin marcar convierte un fallo visible en uno silencioso, y alguien decidirá sobre datos incorrectos |

---

## 📚 Para profundizar

1. **Libro** — Michael Nygard, *Release It!*, 2.ª ed., Pragmatic Bookshelf, 2018. Capítulos 5 y 6:
   antipatrones de estabilidad y patrones de estabilidad. **De aquí vienen el circuit breaker y el
   bulkhead tal como los usamos.**
2. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 12,
   "Resiliency", con el marco completo y la parte organizativa.
3. **Material de referencia** — Amazon Builders' Library, «Timeouts, retries, and backoff with
   jitter», la fuente canónica del jitter y del presupuesto de reintentos:
   [builder.aws.com/content/3EumjoZascWd1oZiEgL8ORlv3qE/timeouts-retries-and-backoff-with-jitter](https://builder.aws.com/content/3EumjoZascWd1oZiEgL8ORlv3qE/timeouts-retries-and-backoff-with-jitter).
4. **Material de referencia** — Google SRE Book, «Handling Overload», para el rechazo temprano y el
   límite de tasa:
   [sre.google/sre-book/handling-overload/](https://sre.google/sre-book/handling-overload/).
5. **Fuente primaria** — Chris Richardson, «Pattern: Circuit Breaker»:
   [microservices.io/patterns/reliability/circuit-breaker.html](https://microservices.io/patterns/reliability/circuit-breaker.html).
6. **Documentación** — Resilience4j, circuit breaker y sus parámetros, que son los que hay que saber
   explicar:
   [resilience4j.readme.io/docs/circuitbreaker](https://resilience4j.readme.io/docs/circuitbreaker).
7. **Documentación** — `sony/gobreaker`, para ver el mismo patrón sin marco:
   [pkg.go.dev/github.com/sony/gobreaker](https://pkg.go.dev/github.com/sony/gobreaker).
8. **Charla** — GOTO Conferences, «Stop Rate Limiting! Capacity Management Done Right». El mejor
   argumento contra reintentar sin presupuesto.

---

## 🧠 Preguntas

1. ¿Qué se propaga en una caída en cascada, y en qué dirección? 🟢
2. ¿Cómo se calcula un timeout? 🟢
3. Enumera las cuatro reglas del reintento. 🟢
4. ¿Cuáles son los tres estados de un circuit breaker? 🟢
5. ¿Qué es un bulkhead y qué convierte en qué? 🟢
6. ¿A quién protege el circuit breaker? 🟡
7. ¿Por qué el reintento es el único mecanismo que puede empeorar un incidente? 🟡
8. ¿Por qué hace falta jitter además de backoff? 🟡
9. ¿Dónde vive el estado del circuit breaker, y qué consecuencia tiene con diez instancias? 🟡
10. ¿Por qué un circuit breaker contra tu propia base de datos no suele tener sentido? 🟡
11. ¿Qué cambia en el argumento del bulkhead con hilos virtuales? 🟡
12. ¿Por qué un fallback debe decir que está degradado? 🟡
13. ¿Qué forma tiene el circuit breaker en cada plataforma, y qué esconde cada una? 🟡
14. Tu endpoint promete 1 s y llamas a dos servicios. Reparte los plazos y justifica. 🟠
15. ¿En qué orden implantarías las cinco medidas si solo tienes una semana? 🟠
16. ¿Qué umbrales pondrías a un circuit breaker contra `payments`, y cómo los justificas? 🟠
17. Un equipo reintenta en el cliente, en la librería y en el mesh. ¿Qué pasa y qué corriges? 🟠
18. ¿Qué dependencias pondrías en readiness y cuáles no, en un servicio que llama a tres? 🟠
19. La anotación de circuit breaker no se aplica y nadie sabe por qué. Da la causa más probable. 🟠
20. ¿Cómo evitas el pico contra un servicio que acaba de recuperarse? 🟠
21. ¿Qué métricas necesitas para saber si tu resiliencia funciona? 🟠
22. Diseña la configuración de resiliencia completa de `orders` hacia sus tres dependencias, con
    valores y justificación de cada uno. 🔴
23. Diagnostica: p99 de `orders` en 8 s, CPU normal, hilos al máximo, `payments` con una consulta
    lenta. Explica la cadena y di dónde la cortarías, en orden. 🔴
24. Diseña la degradación completa de una pantalla con cuatro dependencias, diciendo qué ve el
    usuario en cada fallo y cómo se detecta que está degradada. 🔴
25. Un equipo propone poner todos los reintentos en el mesh y quitarlos del código. Responde con lo
    que concedes y lo que rechazas. 🔴

---

**Anterior:** [`02` — API gateway y BFF](02-api-gateway-y-bff.md) · **Siguiente:**
[`04` — Observabilidad y trazas](04-observabilidad-y-trazas.md) · **Relacionado:**
[`05` — Service mesh y sidecar](05-service-mesh-y-sidecar.md) ·
[`arquitectura/01-bases/01-bases/09`](../../01-bases/01-bases/09-resiliencia.md)

**Talleres, opcionales:** [`06/03` — HTTP entre servicios](../06-talleres/03-http-entre-servicios.md) · [`06/05` — Resiliencia en tres plataformas](../06-talleres/05-resiliencia-en-tres-plataformas.md).
