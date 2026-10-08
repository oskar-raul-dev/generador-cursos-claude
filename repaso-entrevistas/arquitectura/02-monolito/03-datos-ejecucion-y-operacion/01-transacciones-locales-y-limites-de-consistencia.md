# 01 — Transacciones locales y límites de consistencia

Aprenderás a decidir qué escrituras de `CreateOrder` comparten un `COMMIT` y dónde termina la
transacción: lo bastante amplia para que un pedido confirmado nunca exista sin su reserva, y lo
bastante estrecha para no retener locks mientras el código espera a la red.

## 1. 🎯 Síntoma y decisión

Dos incidentes de la misma semana, en el mismo caso de uso. En el primero, soporte encuentra pedidos
`CONFIRMED` sin reserva: el código guardaba el pedido y reservaba el stock en dos transacciones
distintas, y un timeout del pool entre ambas dejó la primera confirmada y la segunda sin hacer. En el
segundo, durante una campaña, el p99 de checkout se dispara aunque la CPU está ociosa: la reserva y
la llamada al proveedor de pagos van dentro de la misma transacción, y la fila del SKU popular queda
bloqueada lo que tarde el proveedor.

La frontera es a la vez demasiado estrecha —parte una invariante en dos `COMMIT`— y demasiado ancha
—incluye una espera de red—. La decisión de este capítulo es qué escrituras confirman juntas y qué
queda fuera, registrado para ocurrir después.

## 2. 🧠 Modelo mental

Una transacción protege una **invariante**, no una petición. La de este caso cabe en una frase: *un
pedido `CONFIRMED` tiene una reserva viva por cada línea*. Pedido y reserva están en la misma base y
los decide el mismo caso de uso, así que un `COMMIT` compartido es la forma más barata de cumplirla.
«El pago está autorizado» no es una invariante que la base pueda garantizar: ocurre en otro sistema,
y solo puede converger.

```text
petición HTTP de CreateOrder ──────────────────────────────────────────────►
   ├─ validar carrito y precios                     sin transacción
   ├─ BEGIN
   │    orders: pedido · inventory: reserva · trabajo pendiente de pago
   │  COMMIT                                        ← aquí vive la invariante
   └─ después del COMMIT                            payments y notifications
                                                    trabajan desde la fila durable
```

Tres preguntas deciden la frontera: ¿qué invariante hay que proteger?, ¿qué datos viven en la misma
base y bajo qué dueño?, ¿qué efecto externo no se puede deshacer? Lo que responde a la tercera nunca
entra; se registra dentro y se ejecuta fuera.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | 37 pedidos `CONFIRMED` sin filas de reserva en una semana, todos con un timeout de pool en el log entre dos escrituras; sesiones `idle in transaction` de unos 2 s en `pg_stat_activity` durante la campaña; esperas de lock concentradas en tres SKU |
| Inferencia | pedido y reserva se confirman por separado; la transacción de la reserva incluye la llamada al proveedor |
| Diagnóstico | la frontera parte la invariante y a la vez retiene locks durante la red |
| Recomendación | una transacción con pedido, reserva y trabajo pendiente; la autorización, después del `COMMIT` y desde esa fila |

Las cifras son supuestos del ejercicio. Lo importante es qué las refutaría: si los pedidos sin
reserva sí tuvieron filas de reserva que luego desaparecieron, la causa es el proceso que libera
reservas vencidas, no la frontera transaccional. Y una sesión `idle in transaction` no dice por sí
sola qué espera; hay que mirar su última sentencia y el código que se ejecuta después. El mecanismo
para lo que queda fuera —tabla de trabajo, worker, reintento— es el de
[eventos internos y jobs](03-eventos-internos-jobs-y-procesamiento-asincrono.md).

## 4. 🛠️ Frontera transaccional por caso de uso

`CreateOrder` necesita una invariante explícita. Si negocio promete que un pedido confirmado siempre
tiene inventario reservado, ambas escrituras pueden compartir la transacción local. Autorizar un
pago remoto o enviar correo no cabe en esa atomicidad: la base no puede deshacer un efecto que ya
ocurrió fuera de ella.

```text
misma base y misma invariante           efecto posterior
BEGIN                                   COMMIT confirmado
  INSERT order PENDING                      │
  UPDATE reservation                        └─► solicitar notificación
  UPDATE order CONFIRMED                        con reintento propio
COMMIT
```

ACID no significa «todo el flujo». Atomicidad agrupa cambios; aislamiento define qué interferencias
concurrentes son visibles; durabilidad comienza después de un commit exitoso. El nivel de aislamiento
se elige por anomalía que debe impedirse, porque un nivel más fuerte puede elevar esperas y abortos.

Una transacción que cruza módulos internos puede ser correcta si expresa una sola invariante y la
propiedad de cada dato sigue clara. Es sospechosa cuando engloba reporting, red o reglas que pueden
confirmarse por separado. Ante error antes del commit se revierte; ante error posterior se registra
un estado recuperable, no se finge un rollback global.

## 5. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | `@Transactional` mediante proxy o `TransactionTemplate` | no propaga atomicidad por red | suponer que la auto-invocación activa el proxy |
| Node/TypeScript | callback o cliente transaccional del driver/ORM | no mantiene contexto automáticamente en cualquier librería | mezclar el cliente global con el transaccional |
| Go | `sql.Tx` y `BeginTx` explícitos | no decide la frontera de negocio | usar `sql.DB` dentro de la operación transaccional |
| Python | context manager de sesión/conexión | no vuelve atómico un efecto externo | hacer I/O remoto antes del commit |

La columna que importa es «Trampa frecuente»: las cuatro son el mismo defecto, una escritura que
el desarrollador cree dentro de la transacción y no lo está. En Java aparece como auto-invocación que
salta el proxy; en Node, como el cliente global; en Go, como `db.Exec` en lugar de `tx.Exec`; en
Python, como una sesión distinta o una escritura después del `with`. Las cuatro se detectan con la
misma prueba: provocar un error después de la segunda escritura y comprobar, desde otra conexión, que
la primera no quedó.

## 6. ⚖️ Decisión y coste

Confirma pedido y reserva en una transacción local cuando esa sea la invariante acordada. Mantén fuera los efectos remotos y registra el trabajo obligatorio antes del commit. La frontera compartida paga contención y rollback conjunto; separar la reserva requiere cambiar explícitamente la promesa de negocio, no solo añadir una cola. Detén la ampliación de la transacción cuando ya proteja la invariante mínima.

## ⚠️ Errores frecuentes

- «Toda la solicitud en una transacción es lo más seguro». Retiene locks y conexiones mientras corre código que no protege ninguna invariante, incluida la espera de red.
- «Si el método tiene `@Transactional`, todo lo que llama es atómico». La auto-invocación, otro hilo o una conexión distinta quedan fuera, y un efecto remoto no entra nunca.
- «El rollback deshace el pago». Deshace filas locales; una autorización remota exige una anulación, que es otra operación con su propio fallo.
- «`SERIALIZABLE` resuelve la consistencia». Impide anomalías de concurrencia a cambio de abortos que hay que reintentar; no vuelve atómico lo que está fuera de la base.
- «Publicar el evento dentro del método transaccional es publicarlo con el commit». En memoria y antes del `COMMIT`, un rollback deja a los consumidores reaccionando a un pedido que no existe.

## 7. ✅ Veredicto

Dibuja la transacción alrededor de una invariante que puedas enunciar en una frase, y de nada más.
En el caso de ejemplo: pedido, reserva y la fila de trabajo pendiente en un `COMMIT`; pago y aviso
después, desde esa fila, con clave idempotente. Si otra garantía pide entrar, pregunta si comparte
base y dueño. Si no, es un estado que converge y necesita reconciliación, no una transacción más
grande.

## 📚 Referencias

- [Spring Transaction Management](https://docs.spring.io/spring-framework/reference/data-access/transaction.html)
- [Executing transactions in Go](https://go.dev/doc/database/execute-transactions)
- [PostgreSQL Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)

## 🧠 Preguntas

1. 🟢 ¿Qué invariante de `CreateOrder` justifica que pedido y reserva compartan un `COMMIT`?
2. 🟢 ¿Qué garantizan por separado atomicidad, aislamiento y durabilidad, y cuál de las tres se suele suponer, por error, sobre una llamada de red?
3. 🟢 ¿Por qué autorizar un pago no puede formar parte de la transacción local del pedido?
4. 🟢 ¿Qué significa una sesión `idle in transaction` y por qué es una señal relevante para este capítulo?
5. 🟢 ¿Qué es un efecto no atómico posterior y qué registro necesita para no perderse?
6. 🟢 ¿Qué diferencia hay entre una transacción por caso de uso y una transacción por petición HTTP?
7. 🟡 Encuentras pedidos `CONFIRMED` sin reserva. ¿Qué hipótesis revisarías antes de culpar a la frontera transaccional?
8. 🟡 ¿Por qué una transacción que envuelve la llamada al proveedor de pagos degrada también pedidos que no dependen de ese pago?
9. 🟡 ¿Cuándo es legítimo que una transacción local cruce los módulos `orders` e `inventory`?
10. 🟡 Negocio cambia la promesa a «aceptamos el pedido y confirmamos el stock en segundos». ¿Qué cambia en la frontera transaccional?
11. 🟡 ¿Qué anomalía de concurrencia justificaría subir el nivel de aislamiento en este caso, y qué pagarías por hacerlo?
12. 🟡 ¿Por qué publicar un evento en memoria antes del commit rompe la garantía aunque el código esté dentro de `@Transactional`?
13. 🟡 ¿Qué debe registrar el flujo cuando el commit local tuvo éxito y la llamada posterior al proveedor falla?
14. 🟡 ¿Qué diferencia hay entre revertir una reserva y compensar una autorización de pago?
15. 🟡 ¿Cómo influye el pool de conexiones en el coste de una transacción larga?
16. 🟡 ¿Qué prueba demostraría que pedido y reserva son atómicos de verdad?
17. 🟡 ¿Cómo cambia la frontera efectiva entre `@Transactional` de Spring y un `sql.Tx` explícito en Go?
18. 🟠 ¿Qué error equivalente comparten mezclar un cliente global en Node/TypeScript y salir del contexto transaccional en Python?
19. 🟠 Un método `@Transactional` llama a otro método `@Transactional(propagation = REQUIRES_NEW)` de la misma clase para guardar la reserva. ¿Qué ocurre y cómo lo detectarías?
20. 🟠 Tras un despliegue, la base muestra muchas sesiones `idle in transaction` de dos segundos. ¿Qué harías en la primera hora y qué después?
21. 🟠 Negocio exige que ningún pedido quede confirmado sin pago autorizado. ¿Cómo lo representarías sin meter al proveedor en la transacción?
22. 🟠 Quieres separar el `COMMIT` de pedido y reserva para reducir contención. ¿Qué paso reversible darías antes de cambiar la promesa?
23. 🟠 Dos equipos discrepan: uno quiere una transacción que incluya a `payments` y otro separar todo con eventos. ¿Cómo decidirías?
24. 🟠 ¿Qué criterio te diría que la transacción ya protege la invariante mínima y no hay que ampliarla?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [08 — Respuestas: Modularidad y límites internos](../02-modularidad-y-limites-internos/08-respuestas.md).

**Siguiente:** [02 — Concurrencia, locking e idempotencia](02-concurrencia-locking-e-idempotencia.md).
