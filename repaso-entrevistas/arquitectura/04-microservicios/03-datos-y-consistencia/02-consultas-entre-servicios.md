# 02 — Consultas entre servicios

> Cómo se responde "¿y cómo hago el `JOIN` si están en bases distintas?" con tres opciones y su
> precio: composición, proyección materializada y réplica de referencia. Asume leído
> [`01`](01-base-de-datos-por-servicio.md). La teoría de CQRS es de
> [`arquitectura/01-bases/03-datos/06`](../../01-bases/03-datos/06-cqrs.md);
> aquí se implementa.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

La pantalla de detalle del pedido necesita esto:

```text
ORD-00042                      ← orders
Cliente: Ana Torres            ← customers
Envío: calle… (la de entonces) ← orders (copia congelada)
2 × Teclado mecánico  89,90 €  ← catalog (nombre) + orders (precio pagado)
Estado: CONFIRMED              ← orders
Entrega estimada: 21/09        ← shipping
```

En el monolito era una consulta con tres `JOIN`. Ahora son tres servicios, y la pregunta del
entrevistador llega sola: *"¿y cómo haces ese join?"*.

La respuesta corta —"composición"— es incompleta. La buena enumera **tres opciones con su precio** y
añade una cuarta posibilidad incómoda: que la pregunta esté señalando que la frontera está mal
puesta.

---

## 2. 🧱 Composición en el llamador

**Qué es.** Alguien —un BFF, el gateway o el propio servicio— llama a los tres y junta el resultado.

**Cómo va.** La decisión de diseño no es *si* componer, es **cómo**:

```text
Secuencial            latencia = suma        (40 + 30 + 50 = 120 ms)
Paralelo              latencia = el más lento (max(40,30,50) = 50 ms)
```

Y con el paralelismo aparece la pregunta que de verdad importa: **qué pasa si uno falla**. Hay que
decidirlo explícitamente por cada dependencia:

| Dependencia | Si falla | Por qué |
|---|---|---|
| `orders` | Falla toda la respuesta | Sin el pedido no hay pantalla |
| `customers` | Se devuelve sin nombre, marcado | El pedido se entiende igual |
| `catalog` | Se usa el nombre copiado en el pedido | Ya lo teníamos congelado |
| `shipping` | Se omite la estimación | Es información secundaria |

**Con qué.** Composición concurrente en las cuatro plataformas, que es el ejemplo de §6.

**Cuánto.** Cuesta latencia —la del más lento— y fallo compuesto: con cuatro dependencias al 99,9 %,
la pantalla baja al 99,6 %. Y cuesta decidir la degradación de cada una, que es trabajo de producto.

**Cuándo sí.** Cuando el dato tiene que estar fresco, cuando el volumen de consultas es moderado y
cuando no quieres añadir estado nuevo.

**Cuándo no.** Cuando la pantalla es el listado principal y se consulta constantemente, o cuando la
composición necesita tantas llamadas que se convierte en un `N+1`
([`02-comunicacion/02`](../02-comunicacion/02-http-entre-servicios.md)).

> **Veredicto:** la composición es la primera opción porque no añade estado y se revierte
> desplegando. Su límite no es la elegancia: es la latencia y el fallo compuesto, y los dos se miden.

---

## 3. 🧱 Proyección materializada (CQRS)

**Qué es.** Un almacén de solo lectura, con la forma exacta que la pantalla necesita, mantenido por
los eventos de los servicios dueños.

**Cómo va.**

```text
orders ──OrderPlaced────────┐
customers ──CustomerUpdated─┼──► projector ──► order_detail_view
catalog ──ProductRenamed────┘                  (una fila = una pantalla)
                                                       │
                                        consulta de 1 salto, sin JOIN
```

Y las tres preguntas que hay que contestar **antes** de construirla, porque son las que se preguntan
en la entrevista:

1. **¿Cuánto se retrasa?** Segundos normalmente; se mide con el lag del proyector.
2. **¿Qué pasa si se corrompe?** Se reconstruye desde el principio del historial — y por eso la
   reconstrucción debe estar escrita y probada **antes** de necesitarla.
3. **¿Quién es su dueño?** El servicio que sirve esa pantalla. Una proyección sin dueño se
   desincroniza y nadie se entera.

**Con qué.** Un consumidor de eventos y un almacén cualquiera: la misma base relacional, un motor
documental o un índice de búsqueda si hay filtros y texto.

**Cuánto.** Cuesta un proceso más, un almacén más, consistencia eventual visible para el usuario, y
la obligación de poder reconstruir. Es la opción más cara de las tres y la que más rinde cuando la
lectura domina.

**Cuándo sí.** Consultas muy frecuentes, filtros por campos de varios servicios, búsqueda por texto,
listados con paginación y orden.

**Cuándo no.** Cuando la consulta es esporádica, o cuando el dato tiene que ser exacto en el
instante: una proyección eventual no sirve para decidir un cobro.

> **💰 Costo:** una proyección no es "una tabla más". Es un proceso que consume eventos, un almacén
> que puede quedar desfasado, un procedimiento de reconstrucción y un panel de retraso. Antes de
> proponerla en una entrevista conviene nombrar las cuatro piezas: demuestra que se ha mantenido
> alguna.

---

## 4. 🧱 Réplica de datos de referencia

**Qué es.** El caso barato de la proyección: copiar localmente un conjunto pequeño y estable de datos
ajenos —países, divisas, categorías, tarifas— y consultarlo sin salir del servicio.

**Cómo va.** El dueño publica los cambios; cada servicio mantiene su copia. Como cambian poco, el
desfase es irrelevante y la reconstrucción es trivial: se vuelve a pedir el catálogo entero.

**Cuánto.** Casi nada: una tabla y un consumidor sencillo. El riesgo es el de siempre: que la copia
crezca hasta convertirse en un modelo entero replicado, y entonces ya es duplicación sin dueño.

**Cuándo sí.** Datos de referencia pequeños, estables y consultados constantemente.

**Cuándo no.** Datos de negocio que cambian con el flujo —el estado de un pedido, el saldo de una
cuenta—: ahí la copia desfasada produce decisiones incorrectas.

> **Veredicto:** replicar datos de referencia es la mejora con mejor relación entre coste y beneficio
> del bloque. Replicar datos transaccionales con el mismo argumento es cómo se construye un modelo
> compartido por la puerta de atrás.

---

## 5. ⚖️ Las tres, comparadas

| | Composición | Proyección | Réplica de referencia |
|---|---|---|---|
| **Frescura** | Máxima | Eventual, segundos | Eventual, tolerable por diseño |
| **Latencia** | La del más lento | Mínima, un salto | Mínima, local |
| **Estado nuevo** | Ninguno | Un almacén y un proceso | Una tabla pequeña |
| **Fallo** | Compuesto: N dependencias | Aislado: si el origen cae, sigues sirviendo | Aislado |
| **Coste de construir** | Bajo | Alto | Bajo |
| **Se revierte** | Desplegando | Retirando proyección y proceso | Desplegando |
| **Encaja con** | Detalle, consultas esporádicas | Listados, filtros, búsqueda | Catálogos estables |

Y la secuencia recomendada, que es la respuesta que conviene dar:

> "Empiezo componiendo en paralelo, porque no añade estado y se revierte desplegando. Si la latencia
> o el volumen no lo aguantan, paso a una proyección **con números delante**, no antes. Y los datos
> de referencia los replico desde el principio, porque eso sí es barato."

---

## 6. 🧰 En las cuatro plataformas

La composición concurrente es **el** caso donde las cuatro plataformas enseñan algo distinto, así que
aquí sí van los cuatro bloques (§5.3 de la guía).

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Composición asíncrona con la API de futuros, y con hilos virtuales el estilo bloqueante deja de ser caro | Elegir modelo y no mezclarlo; y propagar el contexto de traza al pool, donde se pierde |
| **Node/TS** | `Promise.all` y sus variantes: la concurrencia es el modelo natural | Que un fallo en una promesa no tire todas si no quieres: `allSettled` frente a `all` |
| **Go** | Goroutines y grupos de error con cancelación integrada por `context` | Recoger los resultados con cuidado: sin estructura, se acaba con canales y condiciones de carrera |
| **Python** | `asyncio.gather`, con opción de recoger excepciones en vez de propagarlas | No mezclar llamadas bloqueantes, que anulan la concurrencia sin avisar |

En Java, con hilos virtuales el código concurrente vuelve a leerse como secuencial:

```java
// Cada tarea es bloqueante y sencilla; el scope las lanza en paralelo y espera a todas.
try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
    var customer = scope.fork(() -> customersApi.byId(order.customerId()));
    var shipment = scope.fork(() -> shippingApi.estimate(order.id()));
    scope.join();                 // espera a las dos
    scope.throwIfFailed();        // si una falló, cancela la otra y lanza
    return OrderDetail.of(order, customer.get(), shipment.get());
}
```

- `ShutdownOnFailure` implementa "si una falla, cancela el resto": es lo correcto cuando **todas** son
  imprescindibles. Para degradar, se capturan los fallos por tarea en vez de propagarlos.
- 📝 Este estilo es reciente; en bases de código anteriores el mismo patrón se escribe con futuros
  combinados, y el problema que hay que vigilar es idéntico: el contexto de traza no cruza solo al
  pool.

En Node/TS, la distinción que decide la degradación:

```ts
// all → si una falla, falla todo. allSettled → decides tú qué hacer con cada una.
const [customer, shipment] = await Promise.allSettled([
  customersApi.byId(order.customerId),
  shippingApi.estimate(order.id),
]);

return {
  ...order,
  customer: customer.status === 'fulfilled' ? customer.value : null,   // degradación explícita
  estimatedDelivery: shipment.status === 'fulfilled' ? shipment.value : null,
};
```

- Usar `all` donde querías degradar es el error más común: una dependencia secundaria tumba la
  pantalla entera.

En Go, el grupo de error con cancelación:

```go
g, ctx := errgroup.WithContext(ctx) // si una falla, ctx se cancela y las demás abandonan
var customer Customer
var shipment Shipment

g.Go(func() error { var err error; customer, err = customersAPI.ByID(ctx, o.CustomerID); return err })
g.Go(func() error { var err error; shipment, err = shippingAPI.Estimate(ctx, o.ID); return err })

if err := g.Wait(); err != nil { return nil, err } // Wait devuelve el PRIMER error
```

- La cancelación se propaga por el `ctx`: al fallar una, las demás dejan de trabajar. Es el
  equivalente exacto de `ShutdownOnFailure`, y sale del modelo del lenguaje.

Y en Python, con el detalle que cambia el comportamiento:

```python
customer, shipment = await asyncio.gather(
    customers_api.by_id(order.customer_id),
    shipping_api.estimate(order.id),
    return_exceptions=True,        # sin esto, la primera excepción cancela el resto
)
customer = customer if not isinstance(customer, Exception) else None
```

- `return_exceptions=True` es el equivalente de `allSettled`: convierte el fallo en un valor que
  decides tú cómo tratar.

> **🧰 Plataforma:** las cuatro tienen la misma decisión escondida en un parámetro: **¿fallo total o
> degradación?** Se llama `ShutdownOnFailure`, `all` frente a `allSettled`, `errgroup` y
> `return_exceptions`. Saber cuál usas es saber qué ve el usuario cuando una dependencia se cae.

---

## 7. 🧭 Cómo se elige

```text
¿La consulta necesita el dato exacto de ahora mismo?
├─ sí ─► composición. Y si son muchas llamadas, endpoint por lote.
└─ no
   │
   ├─ ¿Es un catálogo pequeño y estable? ─────► réplica de referencia
   │
   ├─ ¿Es una pantalla muy consultada, con
   │   filtros u orden por campos de varios
   │   servicios? ────────────────────────────► proyección materializada
   │
   └─ ¿La consulta necesita datos ajenos para
       DECIDIR, no para mostrar? ─────────────► revisa la frontera: probablemente
                                                 la decisión pertenece al otro servicio
```

La última rama es la que más puntúa. Cuando un servicio necesita datos de otros tres **para aplicar
una regla**, el problema rara vez es de consultas: es que la regla vive en el sitio equivocado.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Montamos un servicio que consulta todas las bases" | Eso es la base de datos compartida con un proceso delante. Se compone por API o se proyecta por eventos |
| "La vista materializada siempre está desactualizada" | Se retrasa segundos y se mide. Lo grave no es el retraso: es no poder reconstruirla |
| "Componemos en el gateway y ya está" | Componer está bien; decidir reglas de negocio ahí, no. Y hay que definir la degradación por dependencia |
| "CQRS es tener dos bases de datos" | Es separar el modelo de lectura del de escritura. La segunda base es una consecuencia, no la definición |
| "Con `Promise.all` ya va en paralelo" | Sí, y si una falla, fallan todas. Para degradar hace falta la variante que recoge resultados parciales |
| "La proyección la mantiene el equipo de datos" | La mantiene el dueño de la pantalla. Sin dueño se desincroniza y nadie se entera |
| "Replicamos los datos que necesitamos y listo" | Replicar referencia estable, sí. Replicar datos transaccionales es construir un modelo compartido por la puerta de atrás |

---

## 📚 Para profundizar

1. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 7, "Implementing
   queries in a microservice architecture": composición y CQRS con sus contraindicaciones. **El
   capítulo de referencia.**
2. **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017. Capítulo 11,
   sobre vistas derivadas y reconstrucción desde el log.
3. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 4, sección de
   composición y del papel del BFF.
4. **Fuente primaria** — Chris Richardson, «Pattern: API Composition»:
   [microservices.io/patterns/data/api-composition.html](https://microservices.io/patterns/data/api-composition.html).
5. **Fuente primaria** — Chris Richardson, «Pattern: CQRS»:
   [microservices.io/patterns/data/cqrs.html](https://microservices.io/patterns/data/cqrs.html).
6. **Fuente primaria** — Martin Fowler, «CQRS», con el aviso sobre cuándo no usarlo:
   [martinfowler.com/bliki/CQRS.html](https://martinfowler.com/bliki/CQRS.html).
7. **Documentación** — Go, `errgroup`, para el patrón de composición con cancelación:
   [pkg.go.dev/golang.org/x/sync/errgroup](https://pkg.go.dev/golang.org/x/sync/errgroup).
8. **Charla** — GOTO Conferences, «Event Sourcing and CQRS» (Greg Young). Útil sobre todo por la
   parte que explica cuándo **no** hace falta.

---

## 🧠 Preguntas

1. ¿Cuáles son las tres opciones para consultar datos repartidos entre servicios? 🟢
2. ¿Qué diferencia hay entre componer en secuencia y en paralelo? 🟢
3. ¿Qué tres preguntas hay que responder antes de construir una proyección? 🟢
4. ¿Qué es una réplica de datos de referencia? 🟢
5. ¿Quién debe ser dueño de una proyección? 🟢
6. ¿Qué significa degradar una dependencia en una composición? 🟢
7. ¿Por qué la composición empeora la disponibilidad de la pantalla? 🟡
8. ¿Por qué la reconstrucción de una proyección debe escribirse antes de necesitarla? 🟡
9. Diferencia entre replicar datos de referencia y replicar datos transaccionales. 🟡
10. ¿Por qué `Promise.all` y `allSettled` implican decisiones de producto distintas? 🟡
11. ¿En qué se parece "un servicio que consulta todas las bases" a la base de datos compartida? 🟡
12. ¿Qué indica que una consulta necesite datos de tres servicios para decidir, no para mostrar? 🟡
13. ¿Cómo se compone en paralelo en cada plataforma, y qué parámetro decide el fallo parcial? 🟡
14. La pantalla de detalle tarda 400 ms componiendo cuatro llamadas. ¿Qué haces primero? 🟠
15. Diseña la degradación de la pantalla del §1: qué se muestra si falla cada dependencia. 🟠
16. ¿Cuándo pasarías de composición a proyección? Da los números que te harían decidir. 🟠
17. La proyección se ha desincronizado. ¿Cómo lo detectas y cómo lo arreglas? 🟠
18. ¿Qué almacén elegirías para una proyección con filtros y búsqueda por texto, y por qué? 🟠
19. Te piden un listado con orden y paginación por campos de dos servicios. ¿Qué propones? 🟠
20. ¿Cómo evitas que una réplica de referencia crezca hasta ser un modelo compartido? 🟠
21. ¿Qué le respondes a un entrevistador que pregunta "¿y cómo haces el join?" en treinta segundos?
    🟠
22. Diseña la proyección `order_detail_view`: qué eventos la alimentan, qué contiene, cómo se
    reconstruye y qué se monitoriza. 🔴
23. Diagnostica: la pantalla de pedidos muestra datos de hace horas en algunos casos y actuales en
    otros. Da tres hipótesis ordenadas. 🔴
24. Diseña la consulta de "pedidos de un cliente con filtro por estado y por producto", decidiendo
    entre las tres opciones y justificando con números. 🔴
25. Un equipo propone un servicio de consultas que lee de las bases de los demás "solo para leer".
    Responde con alternativas concretas. 🔴

---

**Anterior:** [`01` — Base de datos por servicio](01-base-de-datos-por-servicio.md) · **Siguiente:**
[`03` — Saga](03-saga.md) · **Relacionado:**
[`02-comunicacion/02`](../02-comunicacion/02-http-entre-servicios.md) ·
[`arquitectura/01-bases/03-datos/06`](../../01-bases/03-datos/06-cqrs.md)

**Taller, opcional:** [`06/11` — Consultas entre servicios y tiempo real](../06-talleres/11-consultas-y-tiempo-real.md).
