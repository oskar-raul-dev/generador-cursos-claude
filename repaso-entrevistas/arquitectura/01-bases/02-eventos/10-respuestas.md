# 10 — Respuestas

> Solucionario centralizado del bloque `02-eventos`. Cada respuesta en tres capas:
> **⏱️ 30 segundos** (lo que dices primero), **🗣️ 2 minutos** (lo que añades cuando dicen
> "cuéntame más") y **🔬 El detalle** (para estudiar, no para recitar). Los enunciados están
> copiados literalmente de su capítulo.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:**
[01](#01--fundamentos-de-eda) · [02](#02--brokers-comparados) ·
[03](#03--garantías-orden-e-idempotencia) · [04](#04--colas-dlq-y-reintentos) ·
[05](#05--saga) · [06](#06--outbox-y-cdc) · [07](#07--event-sourcing) ·
[08](#08--proyecciones-y-streaming) · [09 — escenarios](#09--simulación-escenarios-de-diseño)

---

# 01 — Fundamentos de EDA

**01 → 1. ¿Qué es un evento y cómo se nombra?**

⏱️ Un hecho del pasado, inmutable, con nombre de negocio en pasado: `PedidoConfirmado`,
`PagoRechazado`.
🗣️ Ya ocurrió, así que nadie puede rechazarlo ni deshacerlo: solo reaccionar. El nombre en
pasado no es cosmética, es lo que te obliga a modelar hechos en vez de órdenes.
🔬 Lleva además un identificador propio, una marca de tiempo del momento en que ocurrió y
normalmente la versión del agregado. La marca de tiempo del evento, no la del consumidor,
es la que se usa al procesarlo.

**01 → 2. ¿Qué diferencia a un comando de un evento?**

⏱️ El comando es una orden a alguien concreto y puede rechazarse; el evento es un hecho
consumado dirigido a nadie en particular.
🗣️ El comando se nombra en imperativo (`ConfirmarPedido`), tiene un destinatario conocido y
acopla al emisor con él. El evento se nombra en pasado, no tiene destinatario y el emisor
no sabe quién lo escucha.
🔬 La prueba práctica: si añadir un consumidor nuevo te obliga a cambiar el mensaje, era un
comando. Mandar un comando por un broker es asíncrono pero sigue siendo RPC acoplado.

**01 → 3. Nombra las tres formas de colaborar por eventos de Fowler.**

⏱️ Notificación por evento, transferencia de estado por evento, y event sourcing.
🗣️ En la notificación el evento dice qué pasó y el consumidor llama de vuelta si necesita
datos. En la transferencia de estado el evento lleva los datos y el consumidor guarda su
copia. Event sourcing es otra cosa: no es integrar, es persistir.
🔬 Las dos primeras son formas de integrar y se eligen según si el consumidor debe
sobrevivir a la caída del emisor. Mezclarlas en el mismo sistema es normal y sano.

**01 → 4. ¿Qué cuatro cosas gana una arquitectura dirigida por eventos?**

⏱️ Desacoplamiento temporal, desacoplamiento estructural, absorción de picos y auditoría
natural.
🗣️ Temporal: el consumidor puede estar caído sin romper al productor. Estructural: añadir un
consumidor no toca al productor. Picos: la cola amortigua y el consumidor va a su ritmo.
Auditoría: el log de eventos es la historia de lo que pasó.
🔬 El orden importa: los dos primeros son el motivo real; los otros dos son beneficios
colaterales que a veces se citan como si fueran la razón, y no lo son.

**01 → 5. ¿Qué diferencia hay entre evento de dominio y evento de integración?**

⏱️ El de dominio es interno y habla tu lenguaje ubicuo; el de integración es un contrato
público entre contextos y está versionado.
🗣️ Cambiar el de dominio no rompe a nadie de fuera y viaja en memoria. Cambiar el de
integración rompe a consumidores que no controlas, así que necesita compatibilidad y
versionado.
🔬 Se traducen en la frontera: el evento de dominio dispara un publicador que emite uno de
integración más estable, con tipos primitivos y con el mínimo de campos.

**01 → 6. ¿Por qué mandar un comando por Kafka no es EDA?**

⏱️ Porque sigue habiendo acoplamiento estructural: el emisor sabe a quién le habla y qué
quiere que haga.
🗣️ EDA se define por la ignorancia del emisor, no por el transporte. `EnviarCorreo` en un
topic es una llamada RPC con una cola en medio: asíncrona, sí, pero el emisor sigue
conociendo al receptor y su responsabilidad.
🔬 No es que esté mal: las colas de comandos son un patrón legítimo y a veces el correcto.
Lo que está mal es llamarlo EDA y esperar sus beneficios.

**01 → 7. ¿Qué es event-carried state transfer y qué problema resuelve?**

⏱️ El evento lleva los datos que el consumidor necesita, y este mantiene una copia local.
Resuelve la llamada de vuelta.
🗣️ Sin él, el consumidor recibe `PedidoConfirmado{id}` y tiene que llamar al productor para
saber qué contiene: vuelve el acoplamiento temporal y pierdes el beneficio principal. Con
los datos dentro, facturación funciona con pedidos caído.
🔬 Su precio: duplicación de datos, consistencia eventual entre las copias, y eventos más
grandes y más frágiles al cambio de esquema.

**01 → 8. ¿Qué tipos llevan los campos de un evento de integración y por qué?**

⏱️ Primitivos y cadenas, no tus objetos de valor: el consumidor no tiene tus clases.
🗣️ `Money` se publica como importe más moneda, y `PedidoId` como cadena. Si publicas tus
tipos, obligas al consumidor a compartir una librería contigo, y esa librería se convierte
en un núcleo compartido que acopla los ciclos de despliegue.
🔬 Lo mismo con los enumerados: se publican como cadena con valores documentados, porque
añadir un valor nuevo a un enum compartido rompe a quien deserializa estrictamente.

**01 → 9. ¿Por qué el nombre del evento va en pasado?**

⏱️ Porque describe algo que ya ocurrió y no se puede rechazar.
🗣️ `EnviarPedido` es un comando: alguien puede decir que no. `PedidoEnviado` ya pasó: la
única respuesta posible es reaccionar. El tiempo verbal te obliga a modelar hechos, y eso
impide que el emisor vuelva a acoplarse sin darse cuenta.
🔬 Es también un test de diseño: si te cuesta nombrar algo en pasado, probablemente estabas
modelando una orden y no un hecho.

**01 → 10. ¿Qué pierde una arquitectura por eventos respecto de una síncrona?**

⏱️ Consistencia inmediata y depurabilidad. Y gana un problema nuevo: los duplicados.
🗣️ El usuario confirma el pedido y la factura todavía no existe, así que hay que decidir qué
ve. El flujo deja de estar en ninguna función: está repartido entre productores y
consumidores, y sin trazas distribuidas depurar es arqueología. Y como la entrega es
at-least-once, todo consumidor debe ser idempotente.
🔬 Se suma el coste de operar el broker, que en el caso de Kafka no es una dependencia más
sino un sistema distribuido con su propia guardia.

**01 → 11. ¿Cómo detectas que un "evento" era en realidad un comando disfrazado?**

⏱️ Si tiene un solo consumidor y el emisor sabe qué va a hacer con él, era un comando.
🗣️ Otras señales: el nombre está en imperativo o contiene un verbo de acción; el emisor
espera una respuesta o consulta después si "funcionó"; añadir un consumidor obligaría a
cambiar el mensaje; el mensaje lleva campos que solo tienen sentido para ese único
consumidor.
🔬 No siempre hay que arreglarlo. Si de verdad hay un destinatario y siempre será uno, el
comando explícito es más honesto y mucho más fácil de depurar que un pseudo-evento.

**01 → 12. ¿Qué pasa si publicas tus eventos de dominio directamente al broker?**

⏱️ Tu modelo interno se convierte en API pública y pierdes la libertad de refactorizarlo.
🗣️ Cada campo publicado es un campo que ya no puedes quitar ni renombrar sin coordinar con
todos los consumidores. El agregado deja de ser tuyo: cambiar un detalle interno se
convierte en un proyecto con tres equipos.
🔬 Se descubre tarde, que es lo que lo hace caro: todo funciona durante meses hasta el día
en que necesitas cambiar algo. La solución cuesta una clase de traducción y se toma el
primer día o no se toma.

**01 → 13. ¿Cuándo la notificación por evento es mejor que llevar los datos?**

⏱️ Cuando los datos son grandes, sensibles, o el consumidor los necesita pocas veces.
🗣️ Publicar el detalle completo de un expediente médico o de una nómina a un topic que
varios equipos leen es un problema de cumplimiento normativo, no de diseño. Y si el
consumidor solo necesita el detalle en el 2 % de los casos, llevarlo siempre es desperdicio.
🔬 El precio de la notificación es que vuelve el acoplamiento temporal en la llamada de
vuelta. Un término medio frecuente: el evento lleva lo que casi todos necesitan y el
consumidor consulta solo el detalle raro.

**01 → 14. ¿Cuál es el precio concreto de event-carried state transfer?**

⏱️ Duplicación de datos en cada consumidor, consistencia eventual entre las copias, y
eventos grandes difíciles de evolucionar.
🗣️ Cada consumidor mantiene su copia, así que el mismo dato vive en cinco sitios con cinco
retrasos distintos. Y como el evento lleva muchos campos, cualquier cambio de esquema
afecta a todos: has ampliado la superficie del contrato.
🔬 Un coste menos obvio: el volumen. Eventos gordos multiplicados por millones son ancho de
banda y retención, y en Kafka la retención es dinero.

**01 → 15. ¿Por qué "con eventos no hay acoplamiento" es falso?**

⏱️ Porque el esquema del evento es un contrato, y romperlo rompe a todos los consumidores.
🗣️ Lo que desaparece es el acoplamiento **temporal** —no necesitas que el otro esté vivo— y
parte del **estructural** —no sabes quién escucha—. Pero el acoplamiento **semántico** se
mantiene entero: todos dependen de qué significan tus campos.
🔬 Y aparece uno nuevo: el acoplamiento al broker. Todos los servicios dependen de que
Kafka esté vivo y de su modelo de particiones. Has cambiado N dependencias por una, que es
mejor, pero no es ninguna.

**01 → 16. ¿Qué pregunta decide si el evento lleva datos o solo notifica?**

⏱️ *"¿El consumidor puede hacer su trabajo con el emisor caído?"*
🗣️ Si la respuesta tiene que ser sí, el evento lleva los datos: es la única forma de que el
consumidor sea autónomo. Si puede esperar o consultar, basta con notificar y el contrato se
mantiene pequeño y estable.
🔬 La pregunta se hace por consumidor, no por evento. Es perfectamente válido que el mismo
evento lleve datos para uno y sea solo notificación para otro, que consulta lo que le falta.

**01 → 17. ¿Por qué depurar un sistema por eventos es más difícil, y qué lo mitiga?**

⏱️ Porque el flujo no existe en ningún sitio: está repartido entre productores y
consumidores. Lo mitiga la traza distribuida con correlation ID.
🗣️ En síncrono sigues la pila de llamadas. En eventos tienes que reconstruir mentalmente
quién publicó qué y quién lo consumió, saltando entre servicios y logs con marcas de tiempo
distintas.
🔬 Lo que hace falta, y es parte del coste del patrón: un identificador de correlación que
se propaga en las cabeceras de cada mensaje, trazas distribuidas que unan productor y
consumidor, y un registro de esquemas que documente qué hay en cada topic. Sin las tres, el
sistema es opaco.

**01 → 18. Un sistema dice ser event-driven pero cada consumidor llama de vuelta al productor. ¿Qué diagnosticas?**

⏱️ Notificación por evento sin transferencia de estado. Técnicamente es EDA, pero conserva
el acoplamiento temporal que se quería eliminar.
🗣️ El síntoma es que si el productor cae, los consumidores tampoco pueden trabajar: tienen
los eventos pero no los datos. Han pagado toda la complejidad de la mensajería —duplicados,
orden, DLQ, consistencia eventual— y no han comprado la autonomía.
🔬 No siempre es un error: si los datos son sensibles o enormes, la notificación es la
decisión correcta y el acoplamiento es el precio aceptado. El diagnóstico es malo solo si
nadie lo decidió: si llegaron ahí por inercia, conviene mover a transferencia de estado los
consumidores que de verdad necesitan ser autónomos, y dejar el resto como está.

**01 → 19. ¿Qué le dices a negocio cuando la factura tarda 30 segundos en aparecer?**

⏱️ Que es una decisión de diseño con una contrapartida concreta, y le presento las dos
opciones con su precio.
🗣️ Lo planteo así: hoy podemos confirmar pedidos aunque facturación esté caída, y el precio
son esos segundos. La alternativa es confirmar solo cuando la factura exista, y entonces
una caída de facturación detiene las ventas. Con los números de disponibilidad delante, la
decisión suele caer sola.
🔬 Y ofrezco mitigaciones que no cambian la arquitectura: mostrar el estado "generando
factura" en vez de un hueco, avisar cuando esté lista, y alertar si el retraso supera un
umbral acordado. Casi siempre lo que molestaba no eran los 30 segundos sino no saber qué
estaba pasando.

**01 → 20. Rediseña el ejemplo síncrono de la sección 1 con eventos: qué publica `Pedidos`, qué consume cada servicio y qué falla si uno se cae.**

⏱️ `Pedidos` publica `PedidoConfirmado` con los datos que los consumidores necesitan, y los
cinco servicios lo consumen de forma independiente.
🗣️ El diseño:

```text
Pedidos ──PedidoConfirmado{id, clienteId, líneas, total, momento}──► topic
    ├─► Inventario   descuenta stock            (idempotente por pedidoId)
    ├─► Facturación  emite factura              (idempotente por pedidoId)
    ├─► Notificaciones envía correo             (dedupe por pedidoId, NUNCA reprocesable)
    ├─► Logística    crea envío                 (idempotente por pedidoId)
    └─► Analítica    registra                   (proyección, reconstruible)
```

`Pedidos` confirma en su base de datos y escribe el evento en su outbox, en la misma
transacción. Su disponibilidad ya no depende de nadie.
🔬 Qué falla y qué no. Si cae cualquier consumidor, los pedidos siguen entrando y ese
consumidor se pone al día después: la única consecuencia es lag, y por eso se alerta sobre
lag y no sobre error. Si cae el broker, el outbox acumula y nada se pierde. Dos matices que
el entrevistador buscará: **inventario deja de ser una validación**, así que si el stock
puede agotarse hay que reservarlo antes de confirmar —o aceptar sobreventa y compensar, que
es una decisión de negocio—; y **notificaciones tiene un efecto irreversible**, así que no
puede reprocesarse como los demás y necesita su propia tabla de deduplicación permanente.

**01 → 21. Tienes que añadir un sexto consumidor a un flujo de eventos existente sin tocar al productor. ¿Qué tiene que ser cierto ya para poder hacerlo?**

⏱️ Que el evento lleve lo que el consumidor nuevo necesita, que el transporte sea pub/sub y
que exista histórico si tiene que procesar el pasado.
🗣️ Tres condiciones concretas. Una: el contrato del evento debe contener los datos, porque
si no habrá que ampliarlo y eso sí toca al productor. Dos: el transporte tiene que permitir
otro consumidor independiente —grupo nuevo en Kafka, cola nueva suscrita al mismo SNS—, no
una cola compartida donde robarías mensajes. Tres: si debe procesar lo ocurrido antes de
existir, hace falta retención suficiente o log compactado.
🔬 La cuarta condición, menos obvia: que el productor no tenga una lista de destinatarios en
su configuración. Si publicar implica enumerar suscriptores, el desacoplamiento estructural
era aparente. Y una quinta, operativa: que añadir un grupo de consumidores no degrade a los
existentes, lo que en Kafka es cierto y en una cola compartida no.

**01 → 22. Diseña el contrato de `PedidoConfirmado` como evento de integración: qué campos lleva, cuáles no, y cómo lo versionas.**

⏱️ Lleva identificadores, el resumen que los consumidores necesitan y metadatos de
mensajería; no lleva estructuras internas del agregado ni nada que solo entienda `Pedidos`.
🗣️ El contrato:

```text
Metadatos:  eventId (uuid, clave de dedupe) · eventType · eventVersion
            occurredAt (cuándo PASÓ) · correlationId
Datos:      pedidoId · clienteId · totalImporte · totalMoneda
            lineas[]: {productoId, cantidad, precioUnitarioImporte}
NO lleva:   el estado interno del agregado, descuentos calculados,
            datos personales del cliente, referencias a tablas propias
```

Todo en primitivos y cadenas. `occurredAt` es cuándo ocurrió, no cuándo se publicó, y es lo
que permite reprocesar sin calcular mal.
🔬 El versionado, por orden de preferencia: solo cambios compatibles —añadir campos
opcionales, nunca quitar ni renombrar—, validado en el pipeline con un registro de esquemas
que rechace cambios incompatibles. Si hace falta un cambio que rompe, se publica un tipo
nuevo (`PedidoConfirmadoV2`) en paralelo durante un periodo acordado, se migran los
consumidores midiendo quién sigue en la V1, y se retira la vieja cuando el contador llegue a
cero. Lo que **no** hago es cambiar el significado de un campo dejando la estructura igual:
pasa todas las validaciones y rompe la lógica del consumidor en silencio.

---

# 02 — Brokers comparados

**02 → 1. ¿Cuál es la diferencia estructural entre una cola y un log?**

⏱️ En una cola el mensaje se consume y desaparece; en un log se lee y se queda, y cada
consumidor lleva su propia posición.
🗣️ De ahí sale todo lo demás: en un log puedes releer el pasado, añadir un consumidor nuevo
que procese lo viejo y tener varios consumidores independientes del mismo flujo. En una cola
no: lo que uno consume, otro ya no lo ve.
🔬 También cambia quién lleva la cuenta. En una cola, el broker registra qué entregó y qué
se confirmó. En un log, el consumidor guarda su offset y el broker solo almacena.

**02 → 2. ¿Qué es una partición en Kafka y para qué sirve?**

⏱️ Es una subdivisión ordenada del topic, y es a la vez la unidad de orden y la de
paralelismo.
🗣️ El orden solo está garantizado dentro de una partición. El reparto lo decide la clave del
mensaje: misma clave, misma partición. Y como cada partición se asigna a un solo consumidor
del grupo, el número de particiones es el techo del paralelismo.
🔬 Se decide al crear el topic y solo se puede aumentar, no reducir. Aumentarlas cambia la
asignación clave→partición de los mensajes futuros, así que el orden se rompe en la
transición.

**02 → 3. ¿Qué es un grupo de consumidores?**

⏱️ Un conjunto de consumidores que se reparten las particiones de un topic y comparten un
offset.
🗣️ Dentro del grupo, cada partición va a un solo miembro, así que el trabajo se reparte sin
duplicar. Entre grupos distintos no hay relación: cada uno lee todo el topic con su propio
offset y sin estorbar a los demás.
🔬 Es el mecanismo que da las dos semánticas a la vez: reparto de trabajo dentro del grupo,
publish-subscribe entre grupos. Cuando un miembro entra o sale se produce un rebalanceo, que
detiene el consumo unos instantes.

**02 → 4. ¿Qué cuatro tipos de exchange tiene RabbitMQ?**

⏱️ `direct`, `topic`, `fanout` y `headers`.
🗣️ `direct` enruta por clave exacta; `topic` por patrón con comodines (`pedido.*`); `fanout`
a todas las colas ligadas, ignorando la clave; `headers` por las cabeceras del mensaje.
🔬 Es enrutamiento declarativo: se configura en el broker, no se escribe código. Es
exactamente lo que Kafka no tiene, y el motivo principal para elegir RabbitMQ.

**02 → 5. ¿Qué hace SNS y qué hace SQS?**

⏱️ SNS es pub/sub y no almacena; SQS es una cola y sí almacena, con reintento y DLQ.
🗣️ El patrón canónico en AWS es combinarlos: SNS reparte a varias colas SQS, una por
consumidor, y cada cola da durabilidad y reintento a su consumidor. Usarlos por separado
casi nunca es lo que quieres.
🔬 SNS solo entrega a quien esté escuchando en ese momento; si el suscriptor está caído, el
mensaje se pierde sin error. Es el fallo de diseño más común en AWS.

**02 → 6. ¿Por qué en Kafka leer no borra el mensaje?**

⏱️ Porque es un log de solo-anexado: los mensajes se retienen por tiempo o por tamaño, no
por consumo.
🗣️ El consumidor solo avanza un puntero. Eso permite que varios grupos lean lo mismo sin
estorbarse, que uno vuelva atrás si hizo mal el trabajo y que un consumidor nuevo procese el
histórico completo.
🔬 La consecuencia operativa: el almacenamiento no baja porque consumas. Se dimensiona por
retención y volumen, y eso es un coste que hay que presupuestar.

**02 → 7. ¿Qué es el offset y quién lo guarda?**

⏱️ La posición del consumidor dentro de una partición. Lo guarda el consumidor,
confirmándolo en un topic interno de Kafka.
🗣️ Que lo lleve el consumidor y no el broker es lo que permite volver atrás, saltar hacia
delante o tener varios grupos independientes. El broker solo almacena el valor cuando se lo
confirmas.
🔬 De cuándo lo confirmas depende la garantía de entrega: confirmar antes de procesar da
at-most-once; confirmar después da at-least-once. Es el mismo punto de
[`03` → 5](#03--garantías-orden-e-idempotencia).

**02 → 8. ¿Qué es el visibility timeout de SQS y qué pasa si es muy corto?**

⏱️ El tiempo que un mensaje queda oculto tras ser recibido. Si es más corto que el proceso,
el mensaje reaparece y se procesa dos veces en paralelo.
🗣️ SQS no borra el mensaje al entregarlo: lo oculta. Si el consumidor lo borra dentro del
plazo, desaparece; si no, vuelve a estar disponible. Por eso el timeout debe ser mayor que
el tiempo de proceso del percentil alto, no del promedio.
🔬 Si el proceso puede durar más de lo previsto, existe `ChangeMessageVisibility` para
extenderlo en marcha. Y en cualquier caso el consumidor debe ser idempotente: el
procesamiento duplicado en paralelo es el modo de fallo característico de SQS.

**02 → 9. ¿Por qué SNS sin SQS detrás pierde mensajes?**

⏱️ Porque SNS no almacena: entrega a quien esté escuchando y, si no hay nadie, el mensaje
desaparece.
🗣️ SNS reintenta con una política propia, pero su modelo no es de almacenamiento durable. Un
suscriptor HTTP caído durante un despliegue pierde todo lo publicado en esa ventana, y no
hay error visible en ningún lado.
🔬 La solución es suscribir una cola SQS al tópico: SQS sí almacena, reintenta y tiene DLQ,
así que el consumidor puede estar caído y ponerse al día. Una DLQ sobre la suscripción de
SNS captura solo los fallos de entrega, no lo que se publicó mientras nadie escuchaba.

**02 → 10. ¿Qué diferencia hay entre una cola standard y una FIFO en SQS?**

⏱️ Standard es at-least-once sin orden y escala sin límite práctico; FIFO garantiza orden y
deduplicación dentro de un grupo, con throughput acotado.
🗣️ FIFO añade `MessageGroupId` —la unidad de orden, equivalente a la clave de partición de
Kafka— y `MessageDeduplicationId` para descartar duplicados dentro de una ventana de cinco
minutos.
🔬 El precio de FIFO es el throughput: mucho menor que standard, aunque el modo de alto
rendimiento lo mejora repartiendo por grupo. Y la deduplicación de cinco minutos no
sustituye a la idempotencia del consumidor: solo cubre reintentos inmediatos del productor.

**02 → 11. ¿Qué aporta IBM MQ que ningún otro de la lista da?**

⏱️ Participación en transacciones XA de dos fases: poner el mensaje y escribir en la base de
datos pueden ser atómicos de verdad.
🗣️ Es la razón por la que sigue vivo en core bancario: resuelve el problema de la doble
escritura de [`06`](#06--outbox-y-cdc) por la vía del coordinador distribuido, que era la
única disponible cuando esos sistemas se construyeron.
🔬 Lo que cuesta: XA bloquea recursos durante toda la transacción, el coordinador es un punto
único de fallo, y la recuperación ante fallo del coordinador es territorio hostil. Por eso
el mundo se movió a outbox más idempotencia, que da garantías equivalentes sin coordinador.

**02 → 12. ¿Qué es la compactación de log y para qué se usa?**

⏱️ Una política de retención que conserva el último valor de cada clave indefinidamente, en
vez de borrar por antigüedad.
🗣️ Convierte el topic en una tabla: para cada clave siempre está el estado más reciente. Un
consumidor nuevo puede leerlo entero y reconstruir el estado completo sin necesitar todo el
histórico.
🔬 Es lo que sostiene la transferencia de estado por evento de
[`01` → 7](#01--fundamentos-de-eda): el topic compactado es la fuente desde la que cualquiera
se pone al día. Detalle: un valor `null` para una clave es una lápida y marca su borrado.

**02 → 13. ¿Qué limita el paralelismo de un grupo de consumidores en Kafka?**

⏱️ El número de particiones. Más consumidores que particiones significa consumidores
ociosos.
🗣️ Cada partición se asigna a un solo miembro del grupo, precisamente para garantizar el
orden dentro de ella. Con seis particiones y diez consumidores, cuatro no reciben nada.
🔬 Por eso las particiones se dimensionan pensando en el paralelismo máximo futuro y se
sobredimensionan un poco: se pueden aumentar pero no reducir, y aumentarlas rompe el reparto
por clave. Si el paralelismo real que necesitas supera lo razonable en particiones, la
salida es procesar en paralelo **dentro** del consumidor, respetando el orden por clave.

**02 → 14. ¿Cuándo RabbitMQ es mejor elección que Kafka?**

⏱️ Cuando necesitas enrutamiento por contenido, prioridades o reintento con retardo por
mensaje, y no necesitas releer.
🗣️ Repartir trabajo entre trabajadores con enrutamiento declarativo es exactamente su caso:
lo hace mejor, con menos operación y con menos gente especializada. Kafka no tiene
prioridades ni TTL por mensaje, y emularlos con topics de reintento rompe el orden.
🔬 También gana cuando el volumen es moderado y el equipo es pequeño: operar Kafka en
producción —particiones, rebalanceos, retención, consumidores rezagados— es un trabajo, y
RabbitMQ pide mucho menos. Lo que no puede darte es releer el pasado.

**02 → 15. ¿Por qué no se pueden reducir las particiones de un topic?**

⏱️ Porque habría que mover mensajes entre particiones, y eso rompería el orden que la
partición garantiza.
🗣️ La asignación es `hash(clave) mod nºParticiones`. Reducir cambiaría esa función para todas
las claves y obligaría a redistribuir lo ya escrito. Kafka prefiere no ofrecerlo a ofrecerlo
roto.
🔬 Aumentar sí se puede, y también tiene consecuencia: los mensajes ya escritos se quedan
donde están, pero los nuevos de la misma clave pueden ir a otra partición. Durante la
transición conviven mensajes de la misma entidad en dos particiones y el orden no está
garantizado entre ellas.

**02 → 16. ¿Por qué acumular millones de mensajes en RabbitMQ degrada el broker?**

⏱️ Porque sus colas están diseñadas para vaciarse, no para almacenar: la cola vive en memoria
y volcarla a disco degrada el rendimiento de todo el broker.
🗣️ Cuando una cola crece más allá de la memoria disponible, RabbitMQ empieza a paginar
mensajes a disco, y esa operación afecta al nodo entero, no solo a esa cola. Es un modo de
fallo que arrastra a consumidores que no tenían nada que ver.
🔬 Kafka no tiene ese problema porque el log **es** un archivo desde el principio: acumular
es su estado normal. Es otra forma de ver la diferencia estructural de la pregunta 1. Las
colas cuórum y las *stream queues* modernas mejoran el caso, pero el principio se mantiene.

**02 → 17. ¿Por qué el mundo dejó XA y se fue a outbox más idempotencia?**

⏱️ Porque XA bloquea recursos, tiene un coordinador que es punto único de fallo, y la mayoría
de las tecnologías modernas no lo soportan.
🗣️ El bloqueo durante toda la transacción distribuida hace que el throughput caiga con la
contención. Si el coordinador muere entre la preparación y el commit, los participantes
quedan bloqueados esperando resolución. Y ni Kafka, ni las APIs de terceros, ni la mayoría
de bases NoSQL participan en XA.
🔬 Outbox más idempotencia da lo mismo por otra vía: la atomicidad se consigue dentro de una
sola base de datos —escribir el cambio y el evento en la misma transacción local— y el
duplicado se resuelve en el consumidor. Sin coordinador, sin bloqueo distribuido, y funciona
con cualquier transporte.

**02 → 18. ¿Cuándo NO usarías ningún broker?**

⏱️ Cuando el volumen es bajo, hay un consumidor y ya tienes una base de datos transaccional.
Una tabla con estado y un proceso que la recorre es suficiente.
🗣️ Con unos pocos mensajes por segundo, una tabla `tareas` con `estado` y un poller da
durabilidad, reintento, DLQ —una columna `intentos`— y orden, todo dentro de la transacción
que ya tienes. Sin broker que operar, sin duplicados entre sistemas, y depurable con un
`SELECT`.
🔬 Es la misma mecánica del relay del outbox, con `FOR UPDATE SKIP LOCKED` para varias
instancias. El umbral para cambiar suele ser: varios consumidores independientes, necesidad
de releer, o volumen que la base de datos ya no absorbe. Proponer esto en entrevista
demuestra que sabes lo que cuesta un broker.

**02 → 19. Necesitas prioridades y reintento con retardo por mensaje. ¿Qué broker y por qué el otro no sirve?**

⏱️ RabbitMQ. Kafka no tiene ninguna de las dos y emularlas rompe el orden.
🗣️ RabbitMQ soporta colas con prioridad y TTL por mensaje, y el retardo se construye con una
cola de espera cuyo dead-letter-exchange devuelve a la original: el mensaje "duerme" y vuelve
solo. En Kafka el orden del log es inmutable, así que no hay forma de adelantar un mensaje ni
de retrasarlo sin sacarlo a otro topic.
🔬 El patrón equivalente en Kafka son los topics de reintento escalonados, y su precio está en
[`04` → 12](#04--colas-dlq-y-reintentos): el mensaje desviado vuelve detrás de otros más
nuevos, así que pierdes el orden por clave. Si tu caso necesita prioridades **y** orden,
Kafka directamente no es la herramienta.

**02 → 20. Un consumidor nuevo tiene que procesar los últimos seis meses de eventos. ¿Qué broker lo permite y qué hace falta haber configurado?**

⏱️ Kafka, y hace falta que la retención cubra esos seis meses, o que el topic esté compactado.
🗣️ El consumidor nuevo se une con un grupo nuevo y offset `earliest`, y lee desde el
principio sin afectar a los demás. Lo que no es gratis es el almacenamiento: seis meses de
retención es una decisión de coste que hay que haber tomado al crear el topic.
🔬 Con compactación el planteamiento cambia: conservas el último valor por clave, así que el
consumidor reconstruye el **estado** pero no la **historia**. Sirve para poblar una vista, no
para auditar qué pasó. Y en cualquier caso hay que pensar el impacto del reproceso: un
consumidor leyendo seis meses a máxima velocidad compite por el ancho de banda del broker con
los que van en vivo, y no debe tener efectos externos.

**02 → 21. Diseña el transporte para: pedidos confirmados que consumen facturación, inventario y analítica, con analítica reprocesando el histórico cada mes. Elige broker y justifica.**

⏱️ Kafka, un topic `pedidos` con clave `pedidoId`, tres grupos de consumidores y retención
suficiente para el reproceso mensual.
🗣️ El requisito que decide es el reproceso: analítica necesita releer el histórico, y eso solo
lo da un log. Un topic con clave `pedidoId` conserva el orden por pedido, que facturación e
inventario necesitan para no aplicar un envío antes que una confirmación. Tres grupos
independientes leen lo mismo sin estorbarse, y cada uno tiene su propio lag y sus propias
alertas.
🔬 Las decisiones que el entrevistador querrá explorar. Particiones: dimensionadas por el
paralelismo máximo previsto, con margen, porque no se reducen. Retención: al menos el doble
del periodo de reproceso —dos meses si reprocesa el último— y eso es dinero, así que se
declara. El reproceso de analítica va con un grupo aparte y con límite de tasa, para no
competir con los consumidores en vivo. Y una alternativa que mencionaría: si analítica solo
necesita agregados, alimentarla por CDC hacia un almacén analítico evita el reproceso sobre
el topic y sale más barato.

**02 → 22. En AWS, tus consumidores procesan mensajes duplicados en paralelo. Reconstruye qué pasó y cómo lo arreglas.**

⏱️ El visibility timeout es más corto que el tiempo de proceso: el mensaje reaparece mientras
el primer consumidor sigue trabajando.
🗣️ La reconstrucción: un consumidor recibe el mensaje, SQS lo oculta N segundos, el proceso
tarda más de N —porque una dependencia se puso lenta, o porque el percentil alto siempre fue
mayor que el promedio con el que se calibró—, SQS lo vuelve a entregar a otro consumidor, y
ahora dos procesan el mismo mensaje a la vez. Lo confirmo comparando el tiempo de proceso del
p99 contra el valor configurado, y buscando en los logs el mismo `MessageId` en dos
instancias con marcas de tiempo solapadas.
🔬 El arreglo tiene dos mitades y ambas hacen falta. La inmediata: subir el visibility timeout
por encima del p99 con margen, y usar `ChangeMessageVisibility` para extenderlo en procesos
largos. La de fondo: **el consumidor debe ser idempotente**, porque el duplicado en SQS no es
una anomalía sino el comportamiento documentado; subir el timeout reduce la frecuencia pero
no elimina el caso. Si además el orden importaba, esto revela que una cola standard no era la
elección correcta y habría que valorar FIFO con `MessageGroupId`.

**02 → 23. Te piden migrar de RabbitMQ a Kafka "porque escala más". ¿Qué preguntas antes y en qué casos dirías que no?**

⏱️ Pregunto qué problema concreto tienen hoy, y si no hay uno medible, digo que no.
🗣️ Las preguntas: ¿cuál es el throughput actual y dónde está el techo medido? ¿Necesitáis
releer el histórico o añadir consumidores que procesen el pasado? ¿Hay varios consumidores
independientes del mismo flujo? ¿Usáis enrutamiento por contenido, prioridades o retardos —que
Kafka no tiene—? ¿Quién va a operar Kafka y tiene experiencia? "Escala más" sin un número es
una aspiración, no un requisito.
🔬 Diría que no en tres casos. Uno: el volumen está lejos del techo de RabbitMQ y no hay
proyección que lo acerque; migrar es riesgo sin retorno. Dos: dependen de enrutamiento,
prioridades o retardos, porque en Kafka eso se pierde o se emula peor. Tres: no hay nadie que
sepa operar Kafka, y entonces la migración cambia un sistema que funciona por uno que caerá
de formas que el equipo no sabrá diagnosticar. Y diría que sí, sin dudar, si la razón real es
releer o añadir consumidores sobre el histórico: eso RabbitMQ no lo da y no hay forma de
conseguirlo. La conversación útil es esa, no la del throughput.

---

# 03 — Garantías, orden e idempotencia

**03 → 1. ¿Qué tres garantías de entrega existen?**

⏱️ At-most-once, at-least-once y exactly-once. En la práctica usas la segunda.
🗣️ At-most-once puede perder y no reintenta: sirve para datos desechables. At-least-once
puede duplicar y reintenta: es el 99 % de los casos. Exactly-once no existe de extremo a
extremo.
🔬 La elección entre las dos primeras no es configuración del broker: es el orden entre
confirmar el mensaje y procesarlo.

**03 → 2. ¿Qué significa *effectively-once*?**

⏱️ Que el mensaje llega varias veces y el efecto observable ocurre una sola.
🗣️ Es at-least-once más idempotencia en el consumidor. Es lo que la gente quiere decir
cuando pide exactly-once, y es lo único construible.
🔬 La parte del transporte la da el broker; la parte del efecto es tuya y no se puede
delegar. Por eso "usamos un broker que da exactly-once" nunca es una respuesta completa.

**03 → 3. Nombra las cuatro formas de conseguir idempotencia.**

⏱️ Reformular la operación, clave de idempotencia, deduplicación por id de mensaje y
comprobación de estado.
🗣️ En ese orden de preferencia. Reformular elimina el problema en vez de gestionarlo: en vez
de "sumar 100", registras el movimiento con su identificador. La clave de idempotencia es el
estándar de las APIs de pago. La deduplicación es la más implementada y la que más cuidado
requiere. La comprobación de estado es barata y frágil.
🔬 La pregunta de entrevista real no es qué es idempotencia, sino cuál de las cuatro
aplicarías en un caso concreto y por qué.

**03 → 4. ¿En qué unidad garantiza Kafka el orden?**

⏱️ Dentro de una partición. No hay orden global entre particiones.
🗣️ Para tener orden por entidad se usa su identificador como clave del mensaje: todos los
eventos de ese pedido caen en la misma partición y se consumen en secuencia.
🔬 Y eso cuesta: una clave con mucho tráfico crea una partición caliente, el paralelismo
queda acotado por el número de particiones, y cambiar ese número rompe la asignación.

**03 → 5. ¿Qué línea de tu código decide si la entrega es at-most-once o at-least-once?**

⏱️ La que confirma el mensaje, según vaya antes o después de procesarlo.
🗣️ Confirmar antes de procesar es at-most-once: si el proceso muere, el mensaje ya está
confirmado y se pierde. Confirmar después es at-least-once: si muere, reaparece y se procesa
de nuevo.
🔬 En Kafka es dónde haces el commit del offset —y por eso el autocommit periódico da una
garantía difusa que no es ninguna de las dos limpiamente—. En SQS es dónde llamas a
`DeleteMessage`. En RabbitMQ, dónde haces el `ack`.

**03 → 6. ¿Por qué el emisor no puede distinguir "no llegó" de "se perdió el acuse"?**

⏱️ Porque en los dos casos observa exactamente lo mismo: ausencia de respuesta.
🗣️ El emisor solo ve que el tiempo se agotó. Si el mensaje no llegó, reintentar es correcto;
si llegó y se perdió la confirmación, reintentar duplica. Y no tiene forma de saber cuál de
los dos ocurrió.
🔬 Es un límite de la información disponible, no de la implementación: ningún protocolo lo
resuelve, porque la confirmación de la confirmación tendría el mismo problema. Es el
argumento por el que exactly-once es imposible.

**03 → 7. ¿En qué caso el exactly-once de Kafka sí es real?**

⏱️ Cuando la entrada y la salida están las dos dentro de Kafka: leer de un topic, transformar
y escribir en otro.
🗣️ El productor transaccional permite commitear el offset de lectura y el mensaje de salida
en la misma transacción, porque ambos viven en el mismo sistema. Es real y funciona.
🔬 En cuanto el efecto sale del broker —tu base de datos, una pasarela, un correo— vuelves a
at-least-once, porque ya son dos sistemas con dos commits. Y casi todos los efectos que
importan salen.

**03 → 8. ¿Quién genera la clave de idempotencia y por qué?**

⏱️ El emisor, porque es el único que sabe si "cobrar 100" es un intento nuevo o el reintento
del anterior.
🗣️ Si la generara el receptor, cada petición tendría clave distinta y no serviría de nada: no
habría forma de reconocer el reintento. El receptor guarda clave → resultado y ante una
repetición devuelve el resultado almacenado sin volver a ejecutar.
🔬 Detalle que se pregunta: qué hacer si llega la misma clave con un cuerpo distinto. Lo
correcto es rechazar con un 422, porque significa que el emisor reutilizó una clave para otra
intención y aceptarlo enmascararía un bug suyo.

**03 → 9. ¿Qué es una partición caliente y qué la causa?**

⏱️ Una partición que recibe mucho más tráfico que las demás. La causa es una clave con
distribución desigual.
🗣️ Un cliente que concentra el 30 % de los eventos, o una clave de baja cardinalidad como el
país o el tipo de producto. El consumidor de esa partición se convierte en el cuello de
botella y el lag crece solo ahí, mientras los demás están ociosos.
🔬 Salidas: componer la clave con algo que reparta (`clienteId + tipo`), subir la cardinalidad
si el orden lo permite, o aceptar el desorden para esa entidad y diseñar el consumidor con
versión para tolerarlo.

**03 → 10. ¿Cuándo at-most-once es una elección correcta?**

⏱️ Cuando el dato es desechable y el siguiente mensaje corrige al anterior.
🗣️ Métricas, telemetría, la posición de un cursor, el estado de un sensor. Perder uno de cada
mil no cambia nada porque el siguiente trae el valor actualizado, y a cambio te ahorras toda
la maquinaria de idempotencia.
🔬 Lo importante es que sea una **elección declarada** y no un descuido. Confirmar antes de
procesar "porque es más simple" en un flujo de pagos es el mismo código y una decisión
completamente distinta.

**03 → 11. ¿Por qué "un fallo de entrega" no significa que la operación no ocurrió?**

⏱️ Porque un timeout solo dice que no recibiste respuesta, no que no se ejecutó.
🗣️ La operación pudo completarse enteramente y perderse la confirmación de vuelta. Tratar el
timeout como "no pasó" y reintentar a ciegas es exactamente cómo se producen los cobros
duplicados.
🔬 Lo correcto ante un estado ambiguo: si la operación es idempotente, reintentar es seguro;
si no lo es, consultar el estado antes de reintentar, o dejarlo a un proceso de conciliación
que resuelva los casos dudosos. La frase que cierra la respuesta: un timeout significa que
**no sabes**, y "no sabes" se trata distinto de "no pasó".

**03 → 12. ¿Por qué la marca de deduplicación debe ir en la misma transacción que el efecto?**

⏱️ Porque si van separadas, un fallo entre ambas deja la operación sin hacer y marcada como
hecha, o hecha dos veces.
🗣️ Si marcas primero y mueres antes de escribir el efecto, al reintentar el consumidor ve el
id como procesado y descarta el mensaje: el efecto nunca ocurrió y nadie se entera. Si
escribes primero y mueres antes de marcar, al reintentar se procesa dos veces.
🔬 Con una base de datos relacional es directo: la fila de dedupe y el efecto en la misma
`@Transactional`, con restricción única sobre el id. Si el efecto es externo y no hay
transacción posible, el patrón se invierte: registrar la intención, llamar, registrar el
resultado, y conciliar los casos que quedaron ambiguos.

**03 → 13. ¿Qué pasa si marcas primero y el proceso muere antes de escribir?**

⏱️ El mensaje queda marcado como procesado sin que el efecto haya ocurrido. Se pierde en
silencio y para siempre.
🗣️ Es el peor de los dos fallos posibles, porque no deja rastro: el reintento se descarta
como duplicado, las métricas dicen que todo va bien, y el problema aparece semanas después
cuando alguien cuadra cifras.
🔬 Es también el más difícil de detectar en una revisión de código, porque el código
**parece** correcto: hay deduplicación, hay transacción, y la marca está antes del trabajo
"para que no se procese dos veces". La única defensa es la regla de la pregunta anterior.

**03 → 14. ¿Cómo diseñas un consumidor que tolere el desorden?**

⏱️ Con una versión o marca de tiempo en el evento: guardas la última aplicada por entidad y
descartas lo más viejo.
🗣️ El consumidor mantiene, junto al estado proyectado, la versión del último evento aplicado.
Si llega uno con versión menor o igual, lo ignora. Con un solo campo consigues idempotencia
y tolerancia al desorden a la vez.
🔬 Requiere que el productor lleve una versión monótona por entidad, que casi siempre ya
existe: es la versión del agregado. Alternativas: operaciones conmutativas —que solo
funcionan en contadores— y reconciliación periódica, que es lo que hace la banca. Límite: no
sirve si el consumidor ejecuta efectos irreversibles que dependen del orden, como enviar
correos.

**03 → 15. Reformula "sumar 100 al saldo" para que sea idempotente **y** soporte concurrencia.**

⏱️ Registrar el movimiento con su propio identificador y derivar el saldo, en vez de mutar un
contador.
🗣️ "Fijar el saldo en 1100" es idempotente pero introduce una carrera: dos operaciones
concurrentes leen el mismo saldo y una pisa a la otra. "Insertar el movimiento `7f3a` de
+100" es idempotente por la clave única —reintentar viola la restricción y no hace nada— y
además conmutativo, así que dos concurrentes no se pisan.
🔬 El saldo pasa a ser un valor derivado: o se calcula como suma de movimientos, o se
mantiene como campo actualizado en la misma transacción que la inserción. En banca esto no es
una técnica de mensajería, es cómo funciona la contabilidad: el asiento es el hecho y el
saldo es el resultado. Y da gratis la auditoría que un contador mutable no tiene.

**03 → 16. ¿Qué cuesta exigir orden por clave?**

⏱️ Paralelismo y flexibilidad: el techo es el número de particiones, y aparecen particiones
calientes.
🗣️ Al forzar que todos los eventos de una entidad vayan a la misma partición, el reparto deja
de ser uniforme: una entidad con mucho tráfico satura a un consumidor. Y el número de
particiones, que es el techo del paralelismo, se fija al crear el topic y no se puede
reducir.
🔬 Coste adicional menos visible: el orden se rompe en cuanto introduces reintentos con
retardo, porque el mensaje desviado vuelve detrás de otros más nuevos. Si necesitas orden
**y** tolerancia a fallos transitorios, la salida es parar el consumo de esa partición en vez
de desviar el mensaje.

**03 → 17. ¿Qué haces con la idempotencia cuando el efecto es una llamada externa y no hay transacción?**

⏱️ Invierto el patrón: registro la intención, llamo, registro el resultado, y concilio los
casos ambiguos.
🗣️ Antes de llamar escribo una fila "intento X sobre la operación Y, en curso" con commit.
Llamo. Al volver, actualizo esa fila con el resultado. Si el proceso muere entre medias, la
fila queda "en curso" y un proceso de conciliación consulta al tercero para averiguar qué
pasó realmente.
🔬 Lo que hace esto viable es que el tercero acepte una clave de idempotencia o permita
consultar por referencia: si no puedo preguntarle "¿ejecutaste la operación Y?", no hay
conciliación posible y solo queda decidir con negocio qué error se prefiere. Es exactamente
la conversación que aparece al integrar pasarelas de pago.

**03 → 18. ¿Por qué "pongo la clave al azar para repartir mejor" es una decisión y no un detalle?**

⏱️ Porque al hacerlo renuncias al orden por entidad, y eso cambia lo que el consumidor puede
asumir.
🗣️ Con clave aleatoria el reparto es perfecto y los eventos de un mismo pedido pueden caer en
particiones distintas, así que se procesan en cualquier orden. Si el consumidor aplica
transiciones de estado, puede aplicar "enviado" antes que "confirmado".
🔬 Es una decisión legítima si el consumidor está diseñado para tolerarlo —con versión, como
en la pregunta 14— y entonces conviene tomarla explícitamente porque compra reparto uniforme.
Lo que no es legítimo es tomarla por rendimiento sin saber que se perdió el orden, y
descubrirlo cuando aparecen estados imposibles en producción.

**03 → 19. Tu consumidor procesa duplicados en producción. Da tres hipótesis en orden de probabilidad.**

⏱️ Falta idempotencia y siempre los hubo; el visibility timeout o el tiempo de sesión es
menor que el proceso; o la deduplicación no es atómica con el efecto.
🗣️ Primera y más probable: nunca hubo deduplicación y los duplicados llevan ahí desde el
principio, pero solo se notan ahora porque subió el volumen o porque algo empezó a fallar y a
reintentar. Segunda: el consumidor tarda más que el plazo que le da el broker —visibility
timeout en SQS, `max.poll.interval.ms` en Kafka—, así que el mensaje se reasigna mientras el
primero sigue trabajando; en Kafka esto además provoca rebalanceos continuos, que son la
pista. Tercera: hay deduplicación pero vive en otra transacción que el efecto, así que la
ventana entre ambas produce duplicados ocasionales.
🔬 Cómo las distingo, en ese orden: busco si existe tabla de dedupe o clave de idempotencia;
comparo el p99 del tiempo de proceso contra el plazo configurado y miro los logs de
rebalanceo; y reviso si la marca y el efecto comparten `@Transactional`. Una cuarta hipótesis
menos común: el **productor** publica dos veces —un reintento suyo sin idempotencia
habilitada—, y entonces el problema no está en el consumidor.

**03 → 20. Diseña el consumidor idempotente de `PagoConfirmado` que carga una cuenta: tablas, transacción y qué pasa en cada punto de fallo.**

⏱️ Una tabla de movimientos con clave única por identificador de evento, el saldo actualizado
en la misma transacción, y nada fuera de ella.
🗣️ El diseño:

```text
movimientos(id_evento PK, cuenta_id, importe, aplicado_en)   ← la clave única ES el dedupe
cuentas(id, saldo, version)

@Transactional
  INSERT INTO movimientos (id_evento, ...)   → si ya existe, viola la PK: salimos, ya estaba
  UPDATE cuentas SET saldo = saldo + :importe WHERE id = :cuenta
  commit
  → y SOLO después: ack del mensaje
```

La restricción única hace el trabajo de deduplicación sin tabla aparte, y el `UPDATE`
incremental es conmutativo, así que dos mensajes de cuentas distintas no se pisan.
🔬 Los puntos de fallo: si muere antes del commit, nada ocurrió y el mensaje se reentrega
—correcto—; si muere después del commit y antes del ack, el mensaje se reentrega, el `INSERT`
choca con la clave única y se descarta —correcto—; si muere entre `INSERT` y `UPDATE`, la
transacción no commiteó y ambos se deshacen —correcto—. Lo que **no** puede haber: ningún
efecto externo dentro de este método, porque el reintento lo repetiría. Si hay que notificar,
se escribe en un outbox dentro de la misma transacción. Y el `ack` va siempre después del
commit, nunca antes.

**03 → 21. Un consumidor nuevo reprocesa seis meses de eventos y dispara correos a clientes. Reconstruye qué faltó en el diseño.**

⏱️ El consumidor mezclaba proyección con efecto externo. Un efecto irreversible nunca puede
estar en un componente reprocesable.
🗣️ Lo que pasó: alguien añadió un grupo de consumidores nuevo con offset `earliest` —para
poblar una vista, o para corregir un bug— y el mismo listener que actualizaba la tabla
enviaba el correo. Kafka hizo exactamente lo que debía: entregar el histórico. El error es de
diseño, no de operación.
🔬 Lo que faltaba, en tres niveles. Separación: la proyección y la notificación tienen que ser
consumidores distintos, porque tienen propiedades distintas —uno es reproducible, el otro
no—. Protección: el consumidor de notificaciones debe llevar deduplicación permanente por
`eventId` y, además, descartar eventos cuyo `occurredAt` sea anterior a un umbral razonable,
porque notificar algo de hace seis meses no tiene sentido aunque no se hubiera notificado.
Y procedimiento: el arranque de un grupo nuevo desde `earliest` debería ser una operación
deliberada y revisada, no el valor por defecto de una configuración copiada.

**03 → 22. Te piden "garantía de orden total de todos los eventos del sistema". Responde: qué cuesta, qué alternativa propones y cómo lo argumentas.**

⏱️ Cuesta una sola partición y por tanto un solo consumidor: has convertido tu sistema
distribuido en uno secuencial. Propongo orden por entidad, que es lo que el negocio necesita
de verdad.
🗣️ El orden total exige que todos los eventos pasen por un punto único que los secuencie. En
Kafka eso es un topic de una sola partición: el throughput queda limitado a lo que procese un
consumidor, y no escala añadiendo máquinas. Además cualquier mensaje lento bloquea todo lo
demás, así que un incidente en una entidad detiene el sistema entero.
🔬 La alternativa y cómo la argumento: pregunto qué caso concreto necesita el orden. Casi
siempre la respuesta es "que los movimientos de una cuenta se apliquen en orden" o "que no se
envíe antes de confirmar", y eso es orden **por entidad**: se consigue con la clave de
partición y escala sin límite. Si de verdad hiciera falta orden global —un libro de órdenes
de trading, un registro notarial—, entonces el requisito es real y la respuesta correcta es
un componente secuenciador dedicado y dimensionado para ello, no forzar todo el sistema a
pasar por ahí. La frase que cierra: *"el orden total es casi siempre un requisito mal
formulado; el real es orden por algo"*.

---

# 04 — Colas, DLQ y reintentos

**04 → 1. ¿Qué es una cola de mensajes muertos?**

⏱️ El destino de los mensajes que no se pudieron procesar tras agotar los reintentos.
🗣️ En SQS y RabbitMQ es una cola aparte; en Kafka, un topic `<topic>.dlt`. Su función es
sacar el mensaje del flujo para que no bloquee, conservándolo para diagnosticar y
eventualmente reprocesar.
🔬 La infraestructura es trivial; lo difícil es el proceso: alerta por tasa, panel, forma de
reprocesar y política de caducidad. Sin las cuatro, es un vertedero.

**04 → 2. ¿Qué es un mensaje envenenado?**

⏱️ Un mensaje que falla siempre y bloquea todo lo que viene detrás.
🗣️ Es un fallo permanente en un transporte que garantiza orden: el consumidor no puede
avanzar, así que los mensajes buenos esperan a uno que nunca pasará.
🔬 En Kafka detiene la partición entera y el lag crece; en SQS o RabbitMQ solo se reentrega
mientras los demás siguen en paralelo. Por eso el problema es mucho peor en Kafka.

**04 → 3. ¿Cuáles son los dos tipos de fallo y qué se hace con cada uno?**

⏱️ Transitorio, que se reintenta con retardo; y permanente, que va directo a la DLQ sin
gastar reintentos.
🗣️ Transitorio: timeout, 503, deadlock, conexión caída. El tiempo lo arregla. Permanente:
JSON inválido, campo obligatorio ausente, referencia a algo que no existe. Fallará igual
dentro de una hora.
🔬 La regla práctica: si es excepción de validación o deserialización, es permanente; si es de
red, tiempo o recurso ocupado, es transitorio. En Spring Kafka las no reintentables se
declaran en una lista.

**04 → 4. Nombra cuatro cosas que debe llevar un mensaje en la DLQ.**

⏱️ El mensaje original intacto, la excepción con su traza, el origen y offset, y el número de
intentos.
🗣️ Y dos más que valen mucho: la marca de tiempo del último fallo, para medir antigüedad, y el
correlation ID, para atarlo a la traza distribuida.
🔬 Sin el original intacto no puedes reprocesar, que es el error más común al implementarla.
Sin la excepción, la DLQ es una caja de mensajes de la que nadie sabe qué hacer.

**04 → 5. ¿Por qué `Thread.sleep` no sirve para retardar un reintento?**

⏱️ Porque bloqueas el hilo del consumidor: mientras duerme no procesa nada más.
🗣️ Y en Kafka es peor: si no vuelves a hacer `poll` dentro de `max.poll.interval.ms`, el
broker te considera muerto y te expulsa del grupo, provocando un rebalanceo. Un `sleep` de
cinco minutos en un consumidor es una forma garantizada de romper el grupo.
🔬 Lo correcto es devolver el mensaje al transporte con un retardo y seguir consumiendo:
cola de espera con TTL en RabbitMQ, `DelaySeconds` en SQS, topics de reintento en Kafka.

**04 → 6. ¿Cómo se implementa un retardo en RabbitMQ?**

⏱️ Con una cola cuyo TTL expira y cuyo dead-letter-exchange apunta de vuelta a la cola
original.
🗣️ El mensaje se publica en una cola de espera con `x-message-ttl`. Al expirar, RabbitMQ lo
envía al exchange de dead-letter configurado, que lo devuelve a la cola de trabajo. El
mensaje "duerme" sin ocupar ningún hilo.
🔬 Para varios escalones se crean varias colas de espera con TTL distinto. Existe además un
plugin de mensajes retardados, pero el patrón TTL más DLX es el estándar y no requiere
instalar nada.

**04 → 7. ¿Cómo se implementa un retardo en Kafka, que no lo tiene nativo?**

⏱️ Con topics de reintento escalonados: `pedidos.retry.5s`, `retry.1m`, `retry.10m`, y
finalmente `pedidos.dlt`.
🗣️ Cuando un mensaje falla, el consumidor lo publica en el topic de reintento siguiente. Un
consumidor de ese topic espera lo necesario antes de reprocesarlo, o el propio framework
gestiona la espera. Spring Kafka lo genera con `@RetryableTopic`.
🔬 El precio es que **rompe el orden por clave**: el mensaje desviado vuelve un minuto después,
detrás de los que llegaron mientras tanto. Si el consumidor dependía del orden, ya no puedes
dar esa garantía.

**04 → 8. ¿Por qué un mensaje envenenado es peor en Kafka que en SQS?**

⏱️ Porque en Kafka detiene la partición entera; en SQS los demás mensajes siguen
procesándose en paralelo.
🗣️ Kafka entrega en orden dentro de la partición y el consumidor avanza un único offset: si no
puede procesar el mensaje actual, no puede avanzar al siguiente. Una sola entidad problemática
bloquea a miles que compartían partición. En SQS no hay orden que preservar, así que el
mensaje malo se reentrega mientras el resto fluye.
🔬 Por eso en Kafka hay que decidir explícitamente entre saltar, parar o desviar; en SQS el
comportamiento por defecto ya es aceptable y la DLQ se encarga sola.

**04 → 9. ¿Qué cuatro cosas necesita una DLQ para no ser un vertedero?**

⏱️ Alerta por tasa, un panel donde verla, una forma de reprocesar y una política de caducidad.
🗣️ La alerta va sobre la tasa, no sobre cada mensaje: uno es normal, cien en una hora es un
incidente. El panel agrupa por tipo de excepción, que es como se descubre que 900 mensajes son
el mismo bug. El reproceso permite recuperar tras arreglar la causa. Y la caducidad decide qué
pasa con lo que lleva tres meses ahí.
🔬 Las cuatro son proceso, no infraestructura. Crear la cola son dos líneas de configuración;
lo otro es lo que hace que sirva de algo.

**04 → 10. ¿Por qué una DLQ sin alerta es peor que no tenerla?**

⏱️ Porque crea la ilusión de que los fallos están controlados mientras se acumulan sin que
nadie mire.
🗣️ Sin DLQ, un mensaje que falla en bucle es ruidoso: llena los logs, dispara alertas de error,
alguien se entera. Con DLQ silenciosa, el fallo desaparece del radar: el consumidor va bien,
las métricas están verdes, y el trabajo simplemente no se hizo.
🔬 Es el mismo patrón que el fallback que devuelve lista vacía de
[`01-bases/09`](../01-bases/09-resiliencia.md): convertir un incidente visible en un dato
incorrecto silencioso siempre es un empeoramiento.

**04 → 11. ¿Cómo clasificas un fallo como transitorio o permanente?**

⏱️ Por el tipo de excepción: validación y deserialización son permanentes; red, tiempo y
recurso ocupado son transitorios.
🗣️ En la práctica se declara una lista de excepciones no reintentables y todo lo demás se
reintenta. La lista incluye las de deserialización, las de validación de negocio y las de
integridad referencial que no se van a resolver solas.
🔬 Cuando no puedes clasificar con confianza, trátalo como transitorio con un tope bajo: es el
error menos caro de los dos, porque reintentar tres veces algo permanente cuesta poco, mientras
mandar a la DLQ algo transitorio pierde trabajo recuperable. Hay un caso ambiguo frecuente: un
`404` de una dependencia puede ser permanente —el recurso no existe— o transitorio —todavía no
se ha propagado—, y ahí hace falta conocer el dominio.

**04 → 12. ¿Qué precio oculto tienen los topics de reintento de Kafka?**

⏱️ Rompen el orden por clave: el mensaje desviado vuelve detrás de otros más nuevos de la
misma entidad.
🗣️ Si tu consumidor aplicaba transiciones de estado confiando en el orden de la partición, tras
introducir retry topics esa garantía ya no existe: puede llegar "enviado" y después "confirmado"
del mismo pedido.
🔬 Las salidas: diseñar el consumidor con versión para tolerar el desorden —lo de
[`03` → 14](#03--garantías-orden-e-idempotencia)—, o renunciar al desvío y parar el consumo de
la partición cuando algo falla, aceptando que el lag crece. No hay forma de tener las dos cosas
con este patrón, y decirlo es lo que demuestra que lo has usado.

**04 → 13. ¿Cuáles son las tres salidas ante un mensaje envenenado y qué cuesta cada una?**

⏱️ Saltarlo, parar el consumo, o desviarlo. Cuestan trabajo perdido, lag, y orden
respectivamente.
🗣️ Saltarlo: avanzas el offset y lo mandas a la DLQ; sigues procesando, pero ese trabajo no se
hizo y alguien tiene que saberlo. Parar: alertas y un humano decide; el lag crece y es lo
correcto cuando saltar es inaceptable. Desviar a retry o DLT: sigues consumiendo y pierdes el
orden por clave.
🔬 Elegir entre las tres **es una decisión de negocio**, no técnica: la pregunta real es
*"¿prefieres perder este mensaje o parar la cola?"*. En proyecciones y analítica se salta
porque la vista se reconstruye; en movimientos de dinero se para y se avisa.

**04 → 14. ¿Cuándo saltar un mensaje es inaceptable y qué haces en su lugar?**

⏱️ Cuando el mensaje representa un hecho de negocio que no se puede perder: dinero,
contabilidad, obligación regulatoria. En su lugar, se para el consumo y se alerta.
🗣️ Parar significa que el consumidor deja de avanzar el offset de esa partición y dispara una
alerta de severidad alta. El lag crece, lo cual es visible y recuperable, frente a un mensaje
perdido, que no lo es.
🔬 Para que parar sea viable hace falta que la alerta llegue a alguien de guardia y que exista
un procedimiento: diagnosticar, corregir el dato o el código, y reanudar. Si no hay nadie
mirando, parar no es más seguro que saltar: solo convierte una pérdida en una caída.

**04 → 15. ¿Por qué reprocesar desde la DLQ puede dejar un estado peor?**

⏱️ Porque el mundo cambió: el mensaje llega después de otros más nuevos de la misma entidad y
puede pisar un estado correcto.
🗣️ Tres trampas. El orden ya está roto, así que un `PedidoConfirmado` de hace tres días
reprocesado hoy puede sobrescribir un `PedidoCancelado` posterior. El consumidor puede usar la
fecha actual en vez de la del evento y calcular mal. Y si no es idempotente, el reproceso
duplica.
🔬 Lo que lo hace seguro: consumidores con versión que descartan lo viejo, uso de `occurredAt`
del evento en vez de `now()`, e idempotencia. Si el consumidor no tiene las tres, reprocesar
requiere análisis caso por caso y no puede ser un botón.

**04 → 16. ¿Qué tiene que usar el consumidor para que un reproceso tardío no calcule mal?**

⏱️ La marca de tiempo del evento —cuándo ocurrió—, no la del momento en que lo procesa.
🗣️ Si el consumidor calcula "aplicar la tarifa vigente hoy" usando `now()`, un mensaje de hace
tres días reprocesado aplica la tarifa de hoy, que puede ser otra. Usando `occurredAt` aplica
la que correspondía.
🔬 Es la misma distinción que tiempo de evento contra tiempo de proceso de
[`08`](#08--proyecciones-y-streaming), aplicada al caso más simple. Por eso todo evento lleva
su propia marca de tiempo del momento en que ocurrió, y no basta con la que añade el broker al
recibirlo.

**04 → 17. ¿Sobre qué se alerta en una DLQ: sobre cada mensaje o sobre la tasa?**

⏱️ Sobre la tasa. Un mensaje aislado es normal; una ráfaga es un incidente.
🗣️ Alertar por cada mensaje produce fatiga de alertas y acaba en una regla de filtrado que
silencia todo. Alertar por tasa —"más de N en M minutos"— distingue el caso normal del
sistémico, que es lo que de verdad requiere intervención.
🔬 Conviene una segunda alerta complementaria: sobre la **antigüedad** del mensaje más viejo en
la DLQ, para detectar que nadie la está mirando. Una DLQ con veinte mensajes de hace dos meses
no dispara la alerta de tasa y es exactamente el vertedero que se quería evitar.

**04 → 18. ¿Qué mensaje se descarta en vez de reprocesarse?**

⏱️ El que era estructuralmente inválido y nunca debió existir: se documenta, se descarta, y se
arregla al productor.
🗣️ Si el mensaje tiene un campo obligatorio ausente o una referencia a algo que no existe,
reprocesarlo volverá a fallar. Lo útil es analizarlo para entender qué bug del productor lo
generó, corregir ahí, y decidir con negocio si ese hecho hay que reconstruirlo por otra vía.
🔬 La decisión de descartar se registra: cuántos, de qué tipo, en qué ventana, y qué impacto de
negocio tuvo. En dominios regulados esa nota es obligatoria, y en cualquier caso es lo que
permite responder cuando alguien pregunta seis meses después por qué faltan esos datos.

**04 → 19. El lag crece en una sola partición y las demás van bien. ¿Qué diagnosticas y cómo lo confirmas?**

⏱️ Mensaje envenenado en esa partición, o partición caliente. El lag concentrado en una sola es
la firma.
🗣️ Si el lag crece en todas por igual, es capacidad y se escala. Si crece en una sola, hay dos
causas posibles: un mensaje que falla en bucle y bloquea el avance del offset, o una clave con
tráfico desproporcionado que satura a ese consumidor.
🔬 Cómo las distingo. Miro el offset de esa partición: si está **parado**, es envenenado; si
**avanza pero más lento** que la escritura, es partición caliente. Confirmo el envenenado
buscando en los logs del consumidor la misma excepción con el mismo offset repitiéndose, y la
partición caliente mirando la distribución de claves. Las soluciones son opuestas: el
envenenado se salta, se para o se desvía; la partición caliente se resuelve cambiando la clave
o aceptando el desorden, y escalar consumidores no ayuda en ninguno de los dos casos.

**04 → 20. Diseña la estrategia de fallos de un consumidor de pagos: clasificación, reintentos, DLQ y qué se para. Justifica cada decisión.**

⏱️ Clasificación estricta, dos reintentos cortos para lo transitorio, DLQ inmediata para lo
permanente, y **parada del consumo** ante cualquier ambigüedad sobre dinero.
🗣️ El diseño:

```text
Permanente (validación, deserialización, importe negativo)
    → DLQ inmediata, sin reintentos. Alerta de severidad media.
Transitorio (timeout de la pasarela, 503, deadlock)
    → 2 reintentos con backoff y jitter, sin desviar a otro topic (conservo el orden)
Ambiguo (timeout DESPUÉS de haber llamado a la pasarela)
    → NO reintento a ciegas: consulto el estado en la pasarela por la referencia.
      Si no puedo consultar, PARO y alerto.
```

No uso retry topics, porque en pagos el orden por cuenta importa y desviarlos lo rompe.
🔬 Lo que se para y por qué: cualquier mensaje que no pueda clasificarse con certeza detiene el
consumo de su partición y dispara alerta de guardia. En pagos, un mensaje perdido es un
descuadre contable que aparece semanas después; el lag es visible, recuperable y molesta hoy.
La asimetría de coste justifica la decisión. Añado tres cosas más: idempotencia por
identificador de operación con clave única, porque los reintentos son inevitables; deduplicación
atómica con el efecto; y una conciliación diaria contra la pasarela que detecte lo que ninguna
de las capas anteriores atrapó. En banca la conciliación no es un extra: es la red de seguridad
que hace aceptable todo lo demás.

**04 → 21. Hay 4.000 mensajes en la DLQ tras un incidente de 3 horas. Describe el procedimiento completo de recuperación.**

⏱️ Agrupar por causa, arreglar el origen, reprocesar en lotes controlados verificando, y
documentar lo descartado.
🗣️ El procedimiento:

```text
1. Contener: ¿sigue entrando? Si la causa no está resuelta, arreglarla ANTES de reprocesar.
2. Agrupar por tipo de excepción. 4.000 mensajes suelen ser 2 o 3 causas distintas.
3. Por cada grupo, decidir: reprocesable / descartable / requiere corrección manual.
4. Reprocesar en lotes pequeños, con límite de tasa, verificando el primero a mano.
5. Vigilar que no vuelvan a la DLQ. Si vuelven, parar: la causa no estaba resuelta.
6. Documentar: cuántos, de qué tipo, cuántos descartados y con qué impacto.
```

Los lotes con límite de tasa evitan que 4.000 mensajes de golpe tumben la dependencia que se
acaba de recuperar: es el thundering herd de
[`01-bases/09`](../01-bases/09-resiliencia.md) aplicado al reproceso.
🔬 Lo que hay que verificar antes de empezar, y suele olvidarse: que el consumidor use
`occurredAt` y no `now()`; que sea idempotente, porque parte de esos mensajes quizá sí se
procesaron antes de fallar; que tolere el desorden, porque van a llegar después de eventos más
nuevos; y que no tenga efectos externos, o 4.000 clientes recibirán notificaciones de hace tres
horas. Si alguna de las cuatro no se cumple, el reproceso masivo no es seguro y hay que ir caso
por caso o reconstruir por otra vía. Y comunicación: si el incidente tuvo impacto visible,
negocio y soporte tienen que saber qué se recuperó y qué no.

**04 → 22. Tu consumidor necesita orden por cliente Y tolerancia a fallos transitorios. ¿Cómo lo resuelves sin renunciar a ninguno de los dos?**

⏱️ No desvío el mensaje: reintento **en el sitio**, bloqueando solo esa partición, con backoff
acotado. Y si se agota, paro esa partición en vez de saltar.
🗣️ El conflicto es real: los retry topics dan tolerancia y rompen el orden; parar conserva el
orden y detiene el flujo. La solución intermedia es reintentar dentro del consumidor sin
devolver el mensaje al broker, usando el mecanismo que Kafka ofrece para esto —pausar la
partición y reanudar—, que mantiene vivo el heartbeat sin avanzar el offset. El orden se
conserva porque el mensaje nunca sale de su sitio, y las demás particiones siguen procesando
con normalidad.
🔬 Los límites que hay que declarar. El backoff tiene que caber dentro de un presupuesto
acotado —del orden de segundos, no de minutos—, porque mientras tanto esa partición no avanza.
Si el fallo persiste más allá de ese presupuesto, ya no es transitorio y la decisión es de
negocio: parar y alertar, que es lo correcto cuando el orden importa tanto. Y una alternativa
de diseño que conviene mencionar: si el consumidor tolerara el desorden con una versión, todo
este problema desaparecería y podrías usar retry topics libremente. Antes de construir la
solución compleja, conviene comprobar si el orden era un requisito real o una suposición.

---

# 05 — Saga

**05 → 1. ¿Qué es una saga?**

⏱️ Una secuencia de transacciones locales, cada una con commit propio, donde el fallo se
resuelve con compensaciones en orden inverso.
🗣️ Sustituye a la transacción distribuida cuando cada servicio tiene su base de datos. No es
atómica: es eventualmente consistente, y durante la ventana el sistema está en un estado
intermedio que otros pueden observar.
🔬 Cada paso commitea de verdad, así que no hay "preparado pendiente": el asiento queda
reservado y visible. Esa visibilidad es la fuente de los tres problemas de aislamiento.

**05 → 2. ¿Qué diferencia hay entre coreografía y orquestación?**

⏱️ En coreografía no hay director: cada servicio reacciona a eventos. En orquestación un
componente conoce el flujo y envía comandos.
🗣️ La coreografía acopla menos y reparte el flujo entre todos, de modo que no existe en ningún
sitio. La orquestación concentra el flujo en un componente legible, al precio de un servicio
más y de acoplamiento estructural deliberado.
🔬 La diferencia que más pesa en producción no es el acoplamiento sino la depurabilidad: con
orquestación consultas el estado de la saga; con coreografía reconstruyes la cadena entre seis
logs.

**05 → 3. ¿Qué es una compensación?**

⏱️ Una operación de negocio que contrarresta a otra ya commiteada. No es un rollback.
🗣️ Compensar un cobro es reembolsar: genera su propio movimiento, su propia comisión y su
propia entrada en el extracto. El cliente ve las dos operaciones, no una que desapareció.
🔬 Tiene cuatro propiedades que la separan del rollback: no es simétrica, puede fallar, hay
pasos que no se pueden compensar, y la ventana entre la operación y su compensación es visible.

**05 → 4. Nombra los tres problemas de aislamiento de una saga.**

⏱️ Lectura sucia, actualización perdida y lectura no repetible.
🗣️ Lectura sucia: otro proceso lee un dato de un paso que luego se compensa. Actualización
perdida: otra saga modifica el mismo dato y la compensación lo pisa. Lectura no repetible: la
saga lee dos veces y obtiene valores distintos.
🔬 Son consecuencia de que una saga no tiene la I de ACID. Las contramedidas —semántica de
bloqueo, registro conmutativo, reordenación, relectura, versión— son lo que sustituye a los
bloqueos de la base de datos, y ahora las modelas tú en el dominio.

**05 → 5. ¿Por qué no se usa 2PC entre microservicios?**

⏱️ Porque bloquea recursos toda la operación, el coordinador es punto único de fallo, y la
mitad de tus dependencias no lo soportan.
🗣️ Con el cobro tardando cuatro segundos, el asiento queda bloqueado esos cuatro segundos; con
volumen, eso es contención masiva. Si el coordinador muere entre la preparación y el commit,
los participantes quedan esperando. Y Kafka, las APIs de terceros y la mayoría de bases NoSQL
no participan.
🔬 Es el mismo argumento por el que el outbox sustituyó a XA: conseguir la garantía dentro de
una sola base de datos y resolver el resto con idempotencia sale más barato que coordinar.

**05 → 6. ¿Por qué una compensación no es un rollback?**

⏱️ Porque el rollback borra como si nada hubiera pasado, y la compensación añade un hecho nuevo
que queda registrado.
🗣️ La transacción ya commiteó: el dinero se movió, el asiento se ocupó, el correo puede haberse
enviado. No hay forma de volver atrás en el tiempo. Lo único posible es una operación nueva que
contrarreste el efecto, y esa operación es visible para el negocio y para el cliente.
🔬 En contabilidad esto no es una limitación técnica sino la norma: no se borra un asiento, se
emite el contrario. La saga replica la forma en que el mundo real ya resolvía este problema.

**05 → 7. ¿Qué es el pivote de una saga?**

⏱️ El paso que decide: antes de él se puede volver atrás, después ya no.
🗣️ En una reserva de vuelo, el pivote es el cobro. Todo lo compensable va antes; todo lo
irreversible —enviar el billete, notificar al proveedor— va después, cuando ya sabes que la saga
va a salir adelante.
🔬 Ordenar los pasos alrededor del pivote es la decisión de diseño más útil del patrón: elimina
la mayoría de los casos imposibles. Si un paso irreversible tiene que ir antes, se convierte en
compensable encolándolo en vez de ejecutándolo.

**05 → 8. ¿Por qué el orquestador tiene que persistir su estado?**

⏱️ Porque si muere a mitad de una saga, al reiniciar tiene que saber en qué paso iba para
continuar o compensar.
🗣️ Un orquestador sin memoria pierde todas las sagas en vuelo al reiniciarse: los pasos ya
ejecutados quedan sin compensar y los recursos reservados quedan bloqueados para siempre. Con
el estado persistido, al arrancar recupera las sagas incompletas y las resuelve.
🔬 En la práctica el orquestador es un agregado: una fila por saga con su estado, su paso actual
y sus datos. Y aun así hace falta el TTL en las reservas, porque puede haber casos que ni
siquiera el estado persistido resuelva.

**05 → 9. ¿Qué envía un orquestador: comandos o eventos? ¿Y por qué importa?**

⏱️ Comandos. Importa porque es acoplamiento estructural deliberado, y es lo que le permite
compensar.
🗣️ El orquestador sabe a quién le habla y qué quiere que haga: `ReservarAsiento` dirigido a
`Asientos`. Esa es precisamente la información que necesita para saber qué compensar si algo
falla. Con eventos no sabría a quién dirigirse.
🔬 Los participantes responden con eventos —`AsientoReservado`, `ReservaRechazada`— y el
orquestador reacciona. Así que el flujo es comandos hacia fuera y eventos hacia dentro, y esa
asimetría es característica del patrón.

**05 → 10. ¿Qué es la semántica de bloqueo como contramedida?**

⏱️ Marcar el registro con un estado "en trámite" para que ninguna otra operación lo toque
mientras la saga está en curso.
🗣️ En vez de un bloqueo de base de datos, que no puede durar toda la saga, se usa un estado del
dominio: el asiento pasa a `RESERVADO` y cualquier otra saga que lo intente encuentra que no
está disponible. Es un bloqueo modelado explícitamente.
🔬 Es la contramedida más usada de las seis, y necesita TTL sin excepción: si la saga muere sin
compensar, el estado `RESERVADO` tiene que caducar solo. Sin TTL, un fallo deja el recurso
bloqueado indefinidamente y hace falta intervención manual.

**05 → 11. ¿Por qué toda reserva de una saga necesita TTL?**

⏱️ Porque es la red de seguridad para cuando la compensación nunca llega.
🗣️ Si el orquestador muere de forma que no puede recuperarse, o si una compensación falla
repetidamente, el recurso queda marcado como reservado sin que nadie lo libere. Con TTL, expira
solo y el sistema vuelve a un estado consistente sin intervención.
🔬 El TTL se calibra por encima del tiempo máximo esperado de la saga, con margen. Y su
expiración debe ser un evento observable —`ReservaExpirada`— para que el orquestador, si sigue
vivo, sepa que perdió el recurso y actúe en consecuencia en vez de seguir creyendo que lo tiene.

**05 → 12. ¿Cuál es el coste real de la coreografía y por qué no es técnico?**

⏱️ Es cognitivo: el flujo no existe en ningún sitio y nadie lo tiene entero en la cabeza.
🗣️ No hay archivo, clase ni diagrama generado que lo describa. Para entender por qué una reserva
quedó a medias hay que reconstruir mentalmente qué publicó cada uno y quién reaccionó, saltando
entre servicios. Con más de tres o cuatro pasos, eso deja de ser viable.
🔬 Y se agrava con el acoplamiento cíclico: `Pedidos` publica, `Inventario` reacciona, `Pedidos`
vuelve a reaccionar. Los ciclos son difíciles de razonar y peores de depurar, y aparecen solos
en cuanto hay compensaciones. El coste se paga en cada incidente, que es cuando peor viene.

**05 → 13. ¿Cómo ordenas los pasos de una saga y por qué ese orden?**

⏱️ Compensables primero, el pivote en medio, e irreversibles al final.
🗣️ Todo lo que se puede deshacer —reservar, bloquear, apuntar— va antes, para que cualquier
fallo temprano se resuelva limpiamente. El pivote es el paso que decide, normalmente el cobro.
Y todo lo irreversible —enviar correos, notificar a terceros, imprimir— va después, cuando ya
sabes que la saga sale adelante.
🔬 Ese orden elimina la mayoría de los casos imposibles de resolver. Si un paso irreversible
tiene que ir antes por una razón de negocio, se convierte en compensable: en vez de enviar el
correo, se encola y se confirma su envío después del pivote. Convertir irreversible en diferible
es la técnica clave.

**05 → 14. ¿Qué haces con un paso que no se puede compensar?**

⏱️ Lo muevo detrás del pivote. Si no puedo, lo convierto en diferible: en vez de ejecutarlo, lo
encolo y lo confirmo después.
🗣️ Un correo enviado no se desenvía y una llamada a un tercero que ya ejecutó tampoco. Las dos
salidas son reordenar —que resuelve la mayoría de los casos— o transformar el paso en una
intención que solo se materializa cuando la saga tiene éxito.
🔬 Si ninguna de las dos es posible —el tercero exige ejecutar antes y no da marcha atrás—,
entonces hay que aceptar que ese paso puede quedar ejecutado en una saga fallida, y diseñar el
proceso de negocio que lo resuelve: una compensación manual, una nota al cliente, un ajuste. Es
una decisión de negocio y hay que llevarla a negocio, no esconderla en el código.

**05 → 15. ¿Qué pasa si una compensación falla?**

⏱️ Se reintenta de forma idempotente, y si se agota el presupuesto, se escala a intervención
humana. Nunca se ignora.
🗣️ Una saga que asume compensaciones infalibles está mal diseñada. La compensación necesita el
mismo tratamiento que cualquier operación distribuida: reintento con backoff, idempotencia por
identificador de saga, y un límite. Al agotarse, la saga queda en un estado terminal de error
que alguien tiene que resolver.
🔬 Lo que hace tolerable ese caso es el TTL de las reservas: aunque la compensación nunca
llegue, los recursos se liberan solos y el daño queda acotado a un registro inconsistente que
la conciliación detecta. Sin TTL, una compensación fallida bloquea recursos para siempre.

**05 → 16. ¿Cuándo una saga es el síntoma de una frontera mal puesta?**

⏱️ Cuando los pasos siempre van juntos y siempre fallan juntos: eso sugiere que pertenecían al
mismo servicio o al mismo agregado.
🗣️ Una saga de seis pasos sobre datos que nadie consulta por separado, con seis compensaciones
que nunca se ejecutan aisladas, es una transacción que alguien partió sin necesidad. El coste
—compensaciones, TTL, aislamiento, depuración— se está pagando sin recibir autonomía a cambio.
🔬 La comprobación: ¿algún participante despliega por su cuenta, escala distinto o lo posee otro
equipo? Si la respuesta es no en los tres casos, la separación no compra nada. La saga más
barata es la que no existe, y revisar la frontera antes de diseñarla es la respuesta madura.

**05 → 17. ¿Por qué la coreografía no puede responder "¿en qué punto va mi pedido?"?**

⏱️ Porque nadie guarda el estado del flujo: cada servicio sabe lo suyo y ninguno sabe el
conjunto.
🗣️ Para responder habría que preguntar a los cinco participantes y correlacionar sus respuestas,
y aun así no sabrías si el sexto paso está en curso o no ha empezado. En orquestación es un
campo de una fila.
🔬 Se puede mitigar añadiendo un consumidor que escuche todos los eventos y mantenga una
proyección del estado del flujo — pero eso **es** un orquestador pasivo, con el coste de
mantener el conocimiento del flujo en dos sitios. Si necesitas el estado, casi siempre sale más
barato orquestar desde el principio.

**05 → 18. ¿Cuándo un orquestador se convierte en un ESB?**

⏱️ Cuando empieza a decidir reglas de negocio que pertenecen a los participantes.
🗣️ Su trabajo es coordinar: saber qué paso va después y qué compensar. Si empieza a validar si
el cliente tiene crédito, a calcular descuentos o a decidir qué producto aplica, ha absorbido
inteligencia que era de otros, y todos los equipos pasan a depender de él para cualquier cambio.
🔬 Es la ruptura de *smart endpoints, dumb pipes* de
[`01-bases/02`](../01-bases/02-estilos-de-despliegue.md). La señal de alarma: cambios de negocio
en un participante que obligan a desplegar el orquestador. Si eso pasa, la lógica está en el
sitio equivocado.

**05 → 19. ¿Qué ve el usuario durante la ventana entre un paso y su compensación?**

⏱️ Un estado intermedio real: el asiento aparece reservado, el saldo descontado, el pedido en
curso. No es un detalle de implementación.
🗣️ Otro usuario que mire ese asiento lo verá ocupado aunque la saga acabe fallando, y el propio
usuario verá su saldo disponible reducido aunque el cobro se revierta. Eso hay que diseñarlo,
no descubrirlo.
🔬 Lo que se hace: modelar el estado intermedio explícitamente en la interfaz —"reservando",
"procesando", "pendiente de confirmación"— en vez de mostrar el estado final prematuramente. Y
en dominios financieros, distinguir saldo contable de saldo disponible, que es exactamente cómo
los bancos resuelven este problema desde antes de que existieran los microservicios.

**05 → 20. Diseña la saga de reserva de vuelo —asiento, equipaje, cobro—: pasos, compensaciones, pivote, y qué pasa en cada punto de fallo.**

⏱️ Saga orquestada con `Reserva` como agregado propio, reservas temporales con TTL, el cobro
como pivote y la emisión del billete después.
🗣️ El flujo:

```text
T1 reservar asiento    (estado RESERVADO, TTL 15 min)   C1 liberar asiento
T2 reservar equipaje   (estado RESERVADO, TTL 15 min)   C2 liberar equipaje
T3 COBRAR  ← PIVOTE                                     C3 reembolsar (no se usa a ciegas)
T4 confirmar reserva y emitir billete  ← irreversible, va después del pivote
T5 notificar al cliente                ← irreversible, va después
```

Los fallos: en T1 no hay nada que compensar, se rechaza. En T2 se ejecuta C1. En T3 se ejecutan
C2 y C1 en orden inverso. En T4, el cobro ya está hecho y **no se revierte automáticamente**: se
reintenta, y si se agota, se marca para intervención.
🔬 Lo que hay que decir sí o sí. Las reservas de T1 y T2 son **temporales con TTL**, no
definitivas: si el orquestador muere sin compensar, expiran solas y el sistema se recupera sin
intervención — es lo que salva el diseño. Cada paso lleva el `reservaId` como clave de
idempotencia, porque la entrega es at-least-once. El usuario ve estado "procesando" y no una
pantalla bloqueada; la confirmación llega por notificación. Y elijo orquestación sobre
coreografía porque hay cuatro pasos, compensaciones, dinero y una pregunta de estado que
responder — cualquiera de las cuatro bastaría.

**05 → 21. El orquestador murió con 200 sagas a medias. Describe qué pasa al reiniciarlo y qué tuvo que estar diseñado de antemano.**

⏱️ Al arrancar carga las sagas no terminadas de su almacén y las reanuda o compensa según el
paso en que estaban. Para eso el estado tenía que estar persistido y los pasos ser idempotentes.
🗣️ La secuencia: consulta las sagas en estado no terminal; por cada una, determina el último
paso confirmado; si el siguiente paso es viable, lo reintenta; si el estado indica que ya se
había decidido compensar, ejecuta las compensaciones pendientes. Los pasos que quizá se
ejecutaron antes de morir se reintentan sin daño porque son idempotentes.
🔬 Lo que tuvo que estar diseñado de antemano, y son cuatro cosas: **estado persistido** tras
cada transición, no solo en memoria; **idempotencia** en cada paso, porque no puedes saber si el
comando llegó antes de morir; **TTL en las reservas**, por si alguna saga no se puede resolver ni
siquiera con el estado; y un **límite de reanudación**, para que una saga que lleva días
intentándose no se reintente eternamente sino que escale a intervención. Y una quinta, operativa:
el arranque no debe lanzar 200 sagas simultáneas contra los participantes, sino con límite de
tasa — si no, el reinicio del orquestador tumba a quienes se estaban recuperando.

**05 → 22. Dos sagas concurrentes tocan la misma cuenta y una compensación pisa el cambio de la otra. Diagnostica y propón dos contramedidas.**

⏱️ Es la actualización perdida, uno de los tres problemas de aislamiento. Las contramedidas:
registro conmutativo, o versión con rechazo de escrituras obsoletas.
🗣️ El diagnóstico: la saga A lee el saldo, la saga B lo modifica y confirma, y luego la
compensación de A escribe el valor que había leído, borrando el cambio de B. La causa raíz es
que la compensación asigna un valor absoluto calculado con información obsoleta.
🔬 Primera contramedida, y la mejor: **registro conmutativo**. La compensación no fija el saldo,
inserta un movimiento con su propio identificador y signo contrario. Dos compensaciones
concurrentes se suman en vez de pisarse, y el saldo se deriva. Es la misma solución que
[`03` → 15](#03--garantías-orden-e-idempotencia) y funciona sin coordinación. Segunda:
**bloqueo optimista por versión**, donde cada escritura lleva la versión leída y se rechaza si
no coincide, obligando a releer y reintentar; funciona, pero introduce reintentos y contención.
Y una tercera que conviene mencionar: **semántica de bloqueo**, marcar la cuenta como "en
trámite" para que la segunda saga ni siquiera empiece, lo que serializa y cuesta throughput.
Yo elegiría la primera: en dominios de dinero, modelar movimientos en vez de mutar contadores
resuelve esto y la auditoría a la vez.

**05 → 23. Te piden convertir una saga coreografiada de 6 pasos a orquestada sin detener el negocio. ¿Cómo lo haces?**

⏱️ Introduzco el orquestador primero como **observador pasivo**, lo verifico contra el flujo
real, y luego le doy el control paso a paso.
🗣️ Las fases. Primera: el orquestador se despliega escuchando todos los eventos del flujo y
manteniendo una proyección del estado de cada saga, sin enviar nada. Eso ya aporta valor solo
—por fin se puede consultar en qué punto va cada reserva— y me permite verificar que mi modelo
del flujo coincide con la realidad, que casi nunca es así al principio. Segunda: tomo el control
de un paso, el último de la cadena, sustituyendo la reacción a evento por un comando del
orquestador, con feature flag para volver atrás. Tercera: repito hacia atrás, paso a paso,
verificando entre cada uno. Cuarta: cuando controla todos, elimino las suscripciones residuales.
🔬 Lo que hace que esto funcione: el orquestador pasivo descubre los casos que nadie
documentó —el paso que a veces se salta, la rama que solo ocurre los viernes— antes de que
tenga responsabilidad. Los riesgos a vigilar: durante la transición conviven dos mecanismos
para el mismo paso, así que la idempotencia de los participantes deja de ser opcional; y hay
que decidir qué pasa con las sagas en vuelo al cambiar cada flag, que normalmente se resuelve
dejando que terminen por el camino viejo y aplicando el nuevo solo a las que empiecen. Mido el
avance por porcentaje de sagas gestionadas por el orquestador, no por pasos migrados.

---

# 06 — Outbox y CDC

**06 → 1. ¿Qué es el problema de la doble escritura?**

⏱️ Que cambiar el estado en la base de datos y publicar el evento son dos sistemas con dos
commits, y no hay orden entre ellos que sea correcto.
🗣️ Si publicas primero y el commit falla, anunciaste algo que no pasó. Si commiteas primero y
mueres antes de publicar, el cambio ocurrió y nadie se enteró. El segundo caso es el frecuente
y el silencioso.
🔬 El problema no es el orden: es que son dos sistemas. Cualquier solución pasa por reducirlos a
uno, y eso es exactamente lo que hace el outbox.

**06 → 2. ¿Qué es el patrón outbox?**

⏱️ Escribir el evento en una tabla de tu propia base de datos, dentro de la misma transacción
que el cambio de estado. Un proceso aparte la lee y publica.
🗣️ La atomicidad es real y gratis: dos escrituras en la misma base de datos, un solo commit, sin
coordinador ni XA. Si el relay está caído, la fila espera; el evento no se pierde nunca.
🔬 Lo que **no** resuelve: el relay puede publicar dos veces si muere entre publicar y marcar, así
que la entrega sigue siendo at-least-once y los consumidores siguen necesitando idempotencia.

**06 → 3. ¿Qué es CDC?**

⏱️ Change Data Capture: leer el log de transacciones de la base de datos y publicar los cambios
como eventos.
🗣️ Debezium es el estándar: lee el WAL de Postgres o el binlog de MySQL. Captura lo que
realmente se commiteó, en orden de commit, con latencia de milisegundos y sin carga de consulta
sobre la base de datos.
🔬 Su precio: un sistema distribuido más que operar, permisos de replicación en la base de datos
y acoplamiento fuerte al motor concreto.

**06 → 4. ¿Qué es el patrón inbox?**

⏱️ El espejo del outbox en el consumidor: registrar el identificador del mensaje en la misma
transacción que el efecto.
🗣️ Al recibir, compruebas si ya procesaste ese id; si no, escribes la marca y el efecto juntos.
Es la implementación concreta de la regla de que la deduplicación debe ser atómica con el
efecto.
🔬 El id puede ser el de la fila del outbox del emisor, viajando en una cabecera: así se cierra
el circuito de extremo a extremo. Necesita purga por antigüedad, con margen mayor que la
retención del broker.

**06 → 5. ¿Por qué publicar dentro de `@Transactional` no es atómico?**

⏱️ Porque el broker no participa en esa transacción: es otro sistema con su propio commit.
🗣️ `@Transactional` gestiona la transacción de la base de datos. La llamada a Kafka sale por una
conexión distinta, a un sistema distinto, y se ejecuta inmediatamente, no al commit. Estar
dentro del bloque no la mete dentro de la transacción.
🔬 La ilusión viene de que el código *parece* estar en el mismo ámbito. Se detecta preguntando
qué pasa si el commit falla después del `send`: el evento ya salió y no hay forma de retirarlo.

**06 → 6. ¿Por qué no hay un orden correcto entre commitear y publicar?**

⏱️ Porque cada orden falla de una forma distinta y ninguna es aceptable.
🗣️ Publicar y luego commitear: si el commit falla, publicaste un hecho falso y los consumidores
actúan sobre algo que no existe. Commitear y luego publicar: si mueres entre medias, el cambio
ocurrió y nadie se enteró, sin error ni rastro.
🔬 El segundo es el que se elige casi siempre porque parece menos grave, y es el peor de
diagnosticar precisamente porque es silencioso: descubres semanas después que faltan eventos y
no sabes cuántos.

**06 → 7. ¿Qué garantiza el outbox y qué **no** garantiza?**

⏱️ Garantiza que el evento no se pierde. No garantiza que no se duplique.
🗣️ La atomicidad entre cambio y evento es real: o están los dos o ninguno. Pero el relay puede
publicar una fila y morir antes de marcarla, y al reiniciar la publicará otra vez.
🔬 Por eso outbox e inbox son complementarios: uno evita perder, el otro evita duplicar. Juntos
dan *effectively-once* de extremo a extremo sin transacción distribuida, y eso es lo que
sustituyó a XA.

**06 → 8. ¿Para qué sirve la columna `agregado_id` en la tabla de outbox?**

⏱️ Como clave de partición al publicar, para conservar el orden por entidad.
🗣️ Sin ella, el relay publicaría sin clave y los eventos del mismo pedido podrían caer en
particiones distintas, perdiendo el orden. Con ella, todos los eventos de `PedidoId=4711` van a
la misma partición y se consumen en secuencia.
🔬 Es una de esas columnas que parecen redundantes —el id ya está en el payload— y que existen
por una razón operativa: el relay no debe deserializar el payload para publicar, solo leer
columnas.

**06 → 9. ¿Qué hace `FOR UPDATE SKIP LOCKED` en el relay?**

⏱️ Permite que varias instancias del relay tomen filas distintas sin bloquearse ni duplicar.
🗣️ `FOR UPDATE` bloquea las filas seleccionadas; `SKIP LOCKED` hace que las instancias que
llegan después salten las ya bloqueadas en vez de esperar. Cada una se lleva un lote distinto y
todas trabajan en paralelo.
🔬 Sin él hay dos malos finales: sin `FOR UPDATE`, dos instancias leen las mismas filas y
publican duplicados masivos; con `FOR UPDATE` solo, la segunda espera a la primera y el relay se
serializa. Es una línea de SQL que decide si el patrón escala.

**06 → 10. ¿Qué diferencias hay entre polling y CDC como relay?**

⏱️ Polling es tu código consultando una tabla; CDC es un componente leyendo el log de
transacciones. Latencia, carga y operación cambian.
🗣️ Polling: latencia igual al intervalo, carga constante de consulta sobre la base de datos,
cero dependencias nuevas, depurable con un `SELECT`. CDC: latencia de milisegundos, carga
mínima, y un Debezium sobre Kafka Connect que operar.
🔬 Mi recomendación por defecto es polling: si un segundo de retardo es tolerable —y casi siempre
lo es—, no añadas un sistema distribuido. CDC se gana el sitio cuando la latencia importa, cuando
ya lo tienes para otra cosa, o cuando el legado no te deja escribir una tabla de outbox.

**06 → 11. ¿Por qué el inbox debe escribirse en la misma transacción que el efecto?**

⏱️ Porque si van separados, un fallo entre ambos deja el trabajo sin hacer y marcado como hecho.
🗣️ Es el mismo argumento que en [`03` → 12](#03--garantías-orden-e-idempotencia): marcar primero
y morir pierde el mensaje en silencio; escribir el efecto primero y morir lo duplica al
reintentar. Solo compartiendo commit ambas cosas son consistentes.
🔬 Y de ahí sale el límite del patrón: si el efecto es externo, no hay transacción que compartir,
y el inbox no sirve. Ahí se invierte a registrar intención, ejecutar, registrar resultado, y
conciliar.

**06 → 12. ¿Por qué CDC sobre tablas de negocio es un antipatrón para integrar?**

⏱️ Porque publicas tu esquema en vez de tus eventos, y pierdes la intención de lo que pasó.
🗣️ Los consumidores acaban dependiendo de tus nombres de columna: renombrar `estado` a
`situacion` rompe a tres equipos. Y un `UPDATE` que cambia `estado` de `PAGADO` a `ENVIADO` no
dice si fue un envío normal, una corrección manual o una migración; el evento `PedidoEnviado`
sí.
🔬 Hay un tercer problema: no puedes emitir lo que no es un cambio de fila.
`LimiteDeCreditoSuperado` no corresponde a ninguna columna, y sin embargo es exactamente el
tipo de hecho que el negocio quiere consumir. La versión buena del patrón es **CDC sobre la
tabla de outbox**: la latencia del CDC con el contrato explícito del outbox.

**06 → 13. ¿Para qué **sí** sirve CDC sobre tablas de negocio?**

⏱️ Para replicar datos: alimentar un almacén analítico, sincronizar una réplica de lectura,
migrar de un sistema a otro.
🗣️ Ahí el objetivo es mover filas, no comunicar significado, y que el contrato sea el esquema es
aceptable porque el consumidor es un sistema de datos, no un dominio de negocio con su propio
lenguaje.
🔬 Es también la única vía cuando el origen es un legado que no puedes modificar: no hay forma de
añadirle una tabla de outbox, así que se captura lo que escribe y se traduce a eventos de
integración en un adaptador aparte. Ese adaptador es una capa anticorrupción.

**06 → 14. ¿Qué métrica es la que de verdad indica la salud de un outbox?**

⏱️ La antigüedad de la fila pendiente más vieja, no el número de filas pendientes.
🗣️ Mil filas publicándose a buen ritmo es un sistema sano con tráfico. Una sola fila de hace
diez minutos es un incidente: significa que el relay no avanza. El número de filas mide carga; la
antigüedad mide si el mecanismo funciona.
🔬 Se complementa con la tasa de publicación —que cayendo a cero con filas pendientes confirma
que el relay está muerto— y con los errores del relay. Pero si solo puedes tener una alerta, que
sea la antigüedad.

**06 → 15. ¿Cuál es el modo de fallo silencioso característico del outbox?**

⏱️ Que el relay muera y nadie lo note: el sistema sigue aceptando escrituras con normalidad y
los eventos se acumulan invisibles.
🗣️ No hay error para el usuario, ni excepción en los logs de la aplicación, ni caída de ningún
endpoint. Todo está verde salvo que los consumidores dejaron de recibir. El daño se descubre
cuando alguien pregunta por qué no llegan las facturas.
🔬 Es paradójicamente una mejora: sin outbox, ese mismo fallo perdía los eventos para siempre;
con outbox, están todos en la tabla esperando. El patrón convierte un fallo irrecuperable en uno
recuperable, y esa conversión **es** su valor. Pero solo si alguien vigila la métrica.

**06 → 16. ¿Cuándo el inbox no compra nada?**

⏱️ Cuando la operación ya es idempotente por naturaleza: fijar un valor, o insertar con una
clave única de negocio.
🗣️ Si el consumidor hace `upsert` sobre una proyección, procesarlo dos veces deja el mismo
resultado y la tabla de inbox solo añade una escritura y mantenimiento. Lo mismo si insertas un
movimiento cuya clave única es el identificador del evento: la restricción ya deduplica.
🔬 La segunda es especialmente elegante porque la deduplicación y el efecto comparten
transacción por construcción, sin tabla aparte. Cuando puedes diseñarlo así, es mejor que el
inbox: menos tablas, menos purga, y la garantía la da la base de datos.

**06 → 17. ¿Cómo se conserva el orden por entidad con un outbox?**

⏱️ Publicando con la clave de partición correcta —`agregado_id`— y leyendo la tabla ordenada por
inserción.
🗣️ El relay lee ordenado por `creado_en` o por un identificador secuencial, y publica cada fila
con su `agregado_id` como clave. Así los eventos de la misma entidad salen en el orden en que se
escribieron y caen en la misma partición.
🔬 El detalle que rompe esto: varias instancias del relay con `SKIP LOCKED` pueden publicar en
paralelo filas de la misma entidad en orden distinto. La solución es que el reparto entre
instancias sea también por `agregado_id` —cada instancia toma un rango de hash— o aceptar el
desorden y usar consumidores con versión.

**06 → 18. ¿Por qué el outbox sustituyó a las transacciones XA?**

⏱️ Porque da una garantía equivalente sin coordinador distribuido, sin bloqueo y funcionando con
cualquier transporte.
🗣️ XA conseguía la atomicidad coordinando dos sistemas; el outbox la consigue evitando el
segundo sistema: ambas escrituras van a la misma base de datos. Lo que XA resolvía con
coordinación, el outbox lo resuelve con un cambio de diseño.
🔬 La contrapartida honesta: XA daba exactly-once y el outbox da at-least-once, así que hace
falta idempotencia en el consumidor. La industria aceptó ese cambio porque la idempotencia es
barata y local, mientras que el coordinador distribuido era caro, frágil y no funcionaba con
Kafka ni con APIs externas.

**06 → 19. ¿Qué haces si el legado no te deja escribir una tabla de outbox?**

⏱️ CDC sobre sus tablas, y traducir a eventos de integración en un adaptador propio.
🗣️ No puedo modificar el legado, pero sí leer lo que escribe. Debezium captura los cambios de
fila y los publica en un topic técnico; un adaptador mío los consume, aplica la lógica de
traducción —qué combinación de cambios significa "pedido confirmado"— y publica eventos de
integración con mi contrato.
🔬 Ese adaptador es una capa anticorrupción y concentra toda la fealdad: los códigos numéricos,
los campos de ochenta posiciones, las reglas implícitas del tipo "si el campo 47 está en blanco
significa X". Su precio: la traducción es frágil porque depende del esquema del legado, y hay
que probarla contra datos reales capturados. Es lo mejor disponible cuando no se puede tocar el
origen, no una opción preferible.

**06 → 20. "Facturación no recibe eventos." Describe el orden en que investigas y qué te dice cada hallazgo.**

⏱️ Miro primero la tabla de outbox: si hay filas pendientes, el evento está a salvo y el problema
es el relay; si está vacía, el evento nunca se escribió.
🗣️ El orden:

```text
1. ¿Hay filas pendientes en outbox?
     SÍ  → el evento existe. Problema en el relay o en el broker. Nada perdido.
     NO  → el evento nunca se escribió. Problema en el productor.
2. Si es el relay: ¿está vivo? ¿publica? ¿da errores? ¿el broker acepta?
3. Si el relay publica bien: ¿llegó al topic? Consumo el topic directamente.
4. Si llegó al topic: el problema es del consumidor. ¿Lag? ¿DLQ? ¿grupo correcto?
5. Si no está en outbox: ¿el código escribe la fila? ¿la transacción commitea?
```

Cada paso descarta la mitad del sistema, y el primero es el que más información da por menos
esfuerzo.
🔬 Lo que hace este diagnóstico posible es precisamente el outbox: sin él, el paso 1 no existe y
tendrías que decidir entre "no se publicó" y "se publicó y se perdió" sin evidencia. Dos
hallazgos frecuentes que conviene anticipar: el consumidor cambió de `group.id` en un despliegue
y empezó desde `latest`, saltándose lo acumulado; o el relay está vivo pero publicando a un
topic con otro nombre tras un cambio de configuración.

**06 → 21. Diseña el outbox completo para `PedidoConfirmado`: tabla, transacción, relay, métricas y qué pasa en cada punto de fallo.**

⏱️ Tabla con id, agregado, tipo, payload y marcas; escritura en la transacción del caso de uso;
relay con `SKIP LOCKED`; alerta por antigüedad.
🗣️ El diseño:

```text
outbox(id UUID PK, agregado_tipo, agregado_id, tipo, payload JSONB,
       creado_en, publicado_en NULL)

@Transactional                              ← la del caso de uso, no una propia
  pedido.confirmar();  repositorio.guardar(pedido);
  outbox.insertar(new FilaOutbox(uuid, "Pedido", id, "PedidoConfirmado", json));
  commit                                    ← ambas o ninguna

relay (cada 200 ms, N instancias):
  SELECT ... WHERE publicado_en IS NULL ORDER BY creado_en
    LIMIT 100 FOR UPDATE SKIP LOCKED
  publicar con key = agregado_id, header eventId = id
  UPDATE publicado_en = now()
```

El `id` de la fila viaja como cabecera y es la clave de deduplicación del consumidor.
🔬 Los puntos de fallo: si muere antes del commit, ni el pedido ni el evento existen —correcto—;
si muere después del commit, la fila espera y el relay la recogerá —correcto—; si el relay
publica y muere antes del `UPDATE`, republicará y el consumidor deduplicará —at-least-once, por
diseño—; si el broker está caído, las filas se acumulan y la antigüedad dispara la alerta.
Métricas: antigüedad de la fila más vieja como alerta principal, filas pendientes y tasa de
publicación como contexto. Y dos decisiones a declarar: el payload es el **evento de
integración** ya serializado, no el de dominio; y las filas publicadas se purgan por antigüedad
—o se particiona la tabla— porque si no crece sin límite.

**06 → 22. Tras un incidente del broker hay 80.000 filas pendientes en el outbox. ¿Qué pasa al recuperarse y qué habría que haber previsto?**

⏱️ El relay publica las 80.000 de golpe y puede tumbar al broker recién recuperado y saturar a
los consumidores. Hace falta límite de tasa en el relay.
🗣️ El comportamiento por defecto es que el relay vacía la tabla lo más rápido que pueda, lo que
produce un pico muy por encima del tráfico normal. Es el thundering herd de
[`01-bases/09`](../01-bases/09-resiliencia.md) aplicado al relay: el sistema que se estaba
recuperando recibe todo lo acumulado más el tráfico nuevo.
🔬 Lo que habría que haber previsto: **límite de tasa en el relay**, configurable, para vaciar a
un ritmo sostenible; **lotes acotados** con pausa entre ellos; y **prioridad al tráfico nuevo**
si el dominio lo permite, porque un evento de hace tres horas suele importar menos que el de
ahora. Del lado de los consumidores: autoescalado por lag para absorber el pico, e idempotencia
—que ya debería estar—. Y algo que se olvida: verificar que los consumidores usan `occurredAt` y
no `now()`, porque 80.000 eventos antiguos procesados de golpe con la hora actual calculan mal.
Por último, comunicación: si el retraso tuvo impacto visible, soporte y negocio deben saber que
se está recuperando y cuánto va a tardar.

**06 → 23. Te piden CDC directo sobre las tablas "porque es más rápido de implementar". Argumenta en contra y propón la alternativa.**

⏱️ Es más rápido hoy y más caro para siempre: publicas tu esquema como contrato. Propongo outbox,
y si quieren la latencia del CDC, CDC **sobre la tabla de outbox**.
🗣️ Los tres argumentos, en orden de fuerza. Uno: el esquema pasa a ser contrato público, así que
renombrar una columna deja de ser un refactor y se convierte en un proyecto con todos los
consumidores — y eso ocurrirá, porque los esquemas evolucionan. Dos: se pierde la intención; un
cambio de `estado` no distingue un envío real de una corrección manual o de una migración
masiva, y los consumidores actuarán igual en los tres casos. Tres: hay hechos de negocio que no
son cambios de fila y simplemente no se pueden emitir.
🔬 La alternativa que propongo, y lo importante es que no renuncia a lo que les interesaba:
mantener Debezium, pero apuntándolo a la tabla de outbox en vez de a las tablas de negocio.
Obtienen la misma latencia de milisegundos y la misma ausencia de carga sobre la base de datos,
y a cambio el contrato es explícito, versionable y desacoplado del esquema. El coste adicional
es una tabla y un `INSERT` en la transacción que ya existe — mucho menos de lo que parece
cuando lo comparan con "implementar el outbox entero". Si aun así el argumento es el plazo,
propondría hacerlo bien para los eventos que cruzan contextos y admitir CDC crudo solo para
alimentar el almacén analítico, que es su caso legítimo.

---

# 07 — Event sourcing

**07 → 1. ¿Qué es event sourcing?**

⏱️ Persistir la secuencia inmutable de hechos en vez del estado, y derivar el estado aplicándolos
en orden.
🗣️ La tabla de saldos, si existe, es una proyección que se puede borrar y reconstruir. La fuente
de verdad es el log. Responde "¿cómo llegamos aquí?", que un `UPDATE` no puede responder porque
destruyó la información.
🔬 No confundir con publicar eventos: eso es integración y tu estado sigue en una tabla. Event
sourcing es persistencia, y la diferencia es si el log **es** la verdad o solo la anuncia.

**07 → 2. ¿Qué es un snapshot y qué relación tiene con el log?**

⏱️ Una foto del estado en una versión concreta, para no tener que reaplicar miles de eventos al
cargar.
🗣️ Se carga el snapshot más reciente y se aplican solo los eventos posteriores. Es caché, no
fuente de verdad: debe poder borrarse y regenerarse desde el log en cualquier momento.
🔬 Si alguna vez no se puede regenerar, el diseño está roto. Y los snapshots también se
versionan: si cambia la forma del estado, los viejos dejan de deserializarse y hay que
regenerarlos.

**07 → 3. ¿Qué es el upcasting de eventos?**

⏱️ Convertir en memoria un evento de una versión antigua a la actual al leerlo, sin tocar lo
almacenado.
🗣️ Una función traduce `PedidoCreadoV1` a `V2`, rellenando los campos que no existían con valores
por defecto. El evento original sigue intacto en el log, que es lo que preserva la inmutabilidad.
🔬 Su problema es la acumulación: al cabo de años tienes cadenas `V1→V2→V3→V4` que nadie entiende
y nadie se atreve a borrar. Y los valores por defecto que inventas son decisiones de negocio
escondidas en código de infraestructura.

**07 → 4. Nombra tres cosas que compra event sourcing.**

⏱️ Auditoría perfecta por construcción, viaje en el tiempo y respuesta retroactiva a preguntas
nuevas.
🗣️ Auditoría: cada cambio es un hecho con su causa y su momento, sin log paralelo que alguien
tenga que acordarse de escribir. Viaje en el tiempo: el estado en cualquier instante del pasado.
Retroactividad: una proyección nueva responde sobre todo el histórico, no solo desde hoy.
🔬 Añadiría una cuarta que vale mucho en producción: depuración real, porque puedes reproducir la
secuencia exacta que produjo un bug en vez de intentar reconstruirla.

**07 → 5. ¿Qué diferencia hay entre publicar eventos y hacer event sourcing?**

⏱️ Publicar eventos es integración con el estado en una tabla; event sourcing es que el log **sea**
el estado.
🗣️ En el primero puedes borrar el topic y tu sistema sigue funcionando: la verdad está en tus
tablas. En el segundo, borrar el log destruye el sistema, porque no hay nada más.
🔬 Casi todos los sistemas que dicen hacer event sourcing hacen lo primero, y está bien: es más
simple, más barato y suficiente el 95 % de las veces. Lo que no está bien es confundirlos y
esperar los beneficios del segundo.

**07 → 6. ¿Cómo se corrige un evento escrito con un dato mal?**

⏱️ Añadiendo un evento de corrección. Los eventos son inmutables: no se editan.
🗣️ Si `Depositado{1500}` debía ser `{1000}`, se añade `DepositoCorregido{-500, motivo}` o el
evento de corrección que el dominio defina. El estado derivado queda bien y la historia refleja
que hubo un error y quién lo corrigió.
🔬 Es exactamente cómo funciona la contabilidad: no se borra un asiento, se emite el contrario.
Editar el evento destruiría la auditoría, que era la razón principal de usar el patrón, y además
invalidaría cualquier snapshot o proyección ya construida sobre él.

**07 → 7. ¿Para qué sirve la versión del agregado en cada evento?**

⏱️ Da orden dentro del agregado y permite bloqueo optimista al insertar.
🗣️ Al añadir un evento declaras la versión esperada; si ya existe, alguien escribió antes que tú y
tu operación se rechaza. Es control de concurrencia sin bloqueos, implementado con una restricción
única sobre `(agregadoId, version)`.
🔬 Y sirve para reconstruir: los eventos se aplican en orden de versión, no de marca de tiempo,
porque los relojes no son fiables entre máquinas. También es lo que permite a las proyecciones
descartar eventos que llegan tarde.

**07 → 8. ¿Por qué event sourcing arrastra CQRS obligatoriamente?**

⏱️ Porque el log responde bien a "dame el agregado X" y fatal a cualquier consulta por criterio.
🗣️ "Todas las cuentas con saldo negativo" obligaría a reconstruir todas las cuentas. La única
salida es mantener proyecciones: consumidores del log que construyen vistas en la forma que cada
consulta necesita.
🔬 Por eso, al evaluar el coste del patrón, hay que sumar el de CQRS entero: proyecciones,
consistencia eventual visible, reconstrucción, y una vista nueva por cada consulta nueva. No son
dos decisiones, es una.

**07 → 9. ¿Qué tres estrategias hay para versionar eventos?**

⏱️ Solo cambios compatibles, upcasting, y reescribir el log.
🗣️ Compatibles —añadir campos opcionales, nunca quitar ni renombrar— es lo primero que se intenta
y aguanta menos de lo que parece. Upcasting traduce al leer y es lo más usado. Reescribir el log
es limpio y rompe la inmutabilidad.
🔬 Ninguna es barata a largo plazo. Es la deuda que el patrón obliga a asumir el primer día y a
pagar durante años, y la razón número uno por la que los proyectos de event sourcing se
abandonan.

**07 → 10. ¿Por qué el snapshot no puede ser la fuente de verdad?**

⏱️ Porque es una optimización derivada: si diverge del log, el log manda.
🗣️ Si el snapshot fuera la verdad, perderías la capacidad de corregir un bug de reconstrucción
recalculando, que es una de las razones de usar el patrón. Y no podrías cambiar la forma del
estado sin migrar datos.
🔬 La prueba práctica: borra todos los snapshots en producción. Si el sistema se recupera —más
lento, pero correcto—, el diseño está bien. Si no puede, tienes una base de datos de estado con
un log al lado, que es lo peor de los dos mundos.

**07 → 11. ¿Qué problema tiene el derecho de supresión del RGPD aquí?**

⏱️ El log es inmutable por diseño y la ley exige poder borrar datos personales. Son requisitos
directamente opuestos.
🗣️ No puedes eliminar un evento sin romper la reconstrucción de todo lo posterior, ni reescribir
el log sin destruir la propiedad que hacía valioso el patrón. Y en banca el conflicto es peor,
porque hay obligaciones de retención que conviven con el derecho de supresión.
🔬 La salida estándar es el *crypto-shredding*: se cifra cada dato personal con una clave por
sujeto y se guarda la clave aparte; al ejercerse el derecho, se destruye la clave y el evento
queda ilegible sin haberse borrado. La estructura del log se conserva, las agregaciones siguen
funcionando, y el dato es irrecuperable.

**07 → 12. ¿Qué es crypto-shredding y qué problema resuelve?**

⏱️ Cifrar los datos personales con una clave por sujeto y destruir la clave para "borrarlos" sin
tocar el log.
🗣️ El evento sigue ahí, con su posición y su versión, así que la reconstrucción no se rompe y los
agregados por cliente siguen siendo correctos. Lo que desaparece es la capacidad de leer el
contenido personal.
🔬 Lo que hay que diseñar: un almacén de claves por sujeto, separado del log y con su propio ciclo
de vida; qué campos se cifran y cuáles no —el identificador interno no, porque lo necesitas para
la integridad referencial—; y qué devuelve la reconstrucción cuando encuentra un evento ilegible.
Mencionarlo en una entrevista de banca es de las cosas que más impresionan.

**07 → 13. ¿Por qué el upcasting se degrada con los años?**

⏱️ Porque se acumula: cada cambio añade un eslabón y nadie se atreve a quitar los viejos.
🗣️ Al cabo de tres años tienes cadenas `V1→V2→V3→V4→V5` que hay que recorrer al leer cualquier
evento antiguo. Nadie recuerda por qué el paso `V2→V3` pone ese valor por defecto, nadie puede
probar que quitarlo sea seguro, y el código crece monótonamente.
🔬 Se mitiga con disciplina: documentar cada upcaster con la decisión de negocio que
implementa, y tener tests con eventos reales de cada versión histórica. Pero es mitigación, no
solución: la única forma de quitar eslabones es reescribir el log, con sus propios problemas.

**07 → 14. ¿Qué peligro tiene reescribir el log para versionar?**

⏱️ Rompe la inmutabilidad, que era media gracia del patrón, y rompe cualquier referencia externa a
versiones concretas.
🗣️ Si otro sistema, una auditoría o un informe guardaron "el estado en la versión 4711", tras la
reescritura esa referencia ya no significa lo mismo. Y en dominios regulados, alterar el registro
histórico puede ser directamente ilegal.
🔬 La forma menos mala es *copy-transform*: crear un log nuevo transformando el viejo y
conservando el original como archivo inmutable. Sigue siendo caro —hay que migrar proyecciones,
snapshots y referencias— pero al menos no destruye la evidencia.

**07 → 15. ¿Qué pasa cuando hay que reconstruir una proyección de 500 millones de eventos?**

⏱️ Tarda horas, así que hay que construirla en paralelo y cambiar al terminar, nunca borrarla y
rehacerla en el sitio.
🗣️ Se crea la proyección nueva vacía, un consumidor la alimenta desde el principio mientras la
vieja sigue sirviendo, se verifica comparando conteos y muestras, y se cambian las lecturas
atómicamente con un alias o una feature flag.
🔬 Y hay que dimensionar el impacto: leer 500 millones de eventos a máxima velocidad compite por
el ancho de banda del almacén con el tráfico en vivo, así que conviene limitar la tasa y hacerlo
en horas valle. Es el mismo procedimiento de
[`08` → 14](#08--proyecciones-y-streaming), y es la operación que justifica todo el patrón.

**07 → 16. ¿Por qué "un `UPDATE` es una pérdida de información deliberada"?**

⏱️ Porque sobrescribe el valor anterior y con él la historia de cómo se llegó al actual.
🗣️ Tras el `UPDATE` no sabes si el saldo de 1.000 viene de un ingreso, de diez, o de un ingreso
grande y varios reintegros. La información existió y la destruiste al guardar solo el resultado.
🔬 La mayoría de las veces es la decisión correcta: guardar toda la historia cuesta espacio,
complejidad y consultas peores. Lo que importa es saber que la estás tomando, porque cuando
alguien pregunte retroactivamente ya no habrá vuelta atrás.

**07 → 17. ¿En qué dominios el patrón se descubre en vez de imponerse, y por qué?**

⏱️ Contabilidad, trading, seguros y expedientes: dominios donde el negocio ya piensa en hechos
inmutables, no en estado mutable.
🗣️ Un contable no actualiza un saldo: registra un asiento. Un actuario no cambia una póliza:
emite un suplemento. El modelo de eventos no se impone sobre esos dominios, los describe. Y por
eso el lenguaje ubicuo coincide de forma natural con los nombres de los eventos.
🔬 La señal de que el patrón encaja: el experto de negocio habla espontáneamente en pasado y en
hechos, y le resulta raro que el sistema "pierda" los movimientos. Cuando el experto habla de
campos y de estados actuales, imponerle event sourcing es fricción sin retorno.

**07 → 18. ¿Cuándo basta con un log de auditoría en vez de event sourcing?**

⏱️ Cuando quieres saber quién cambió qué y cuándo, pero el estado actual sigue siendo la verdad
operativa.
🗣️ Una tabla de auditoría, o CDC hacia un almacén, o eventos publicados con outbox te dan
trazabilidad sin asumir versionado eterno, CQRS obligatorio, consistencia eventual y curva de
entrada. Cubre el 95 % de los casos donde alguien pide "queremos saber qué pasó".
🔬 La diferencia real: con auditoría, el log es un producto secundario que puedes perder sin
consecuencias operativas; con event sourcing, es el sistema. Si nadie necesita **reconstruir** el
estado desde los hechos ni responder preguntas retroactivas nuevas, el patrón caro no aporta.

**07 → 19. ¿Qué significa aplicar event sourcing "selectivamente" y por qué es la respuesta madura?**

⏱️ Usarlo solo en los agregados donde se paga —normalmente uno o dos del núcleo— y dejar el resto
en CRUD.
🗣️ `Cuenta` puede ser event-sourced porque tiene obligación regulatoria de trazabilidad y el
negocio piensa en movimientos; el catálogo de productos no lo necesita y sería ceremonia. Ambos
conviven en el mismo sistema sin problema.
🔬 Es maduro por dos razones. Una: acota el coste —versionado, CQRS, curva de entrada— a donde hay
retorno, en vez de imponerlo a todo el equipo. Dos: reconoce que el patrón es una decisión por
agregado, igual que el DDD táctico de
[`01-bases/07`](../01-bases/07-ddd-tactico.md). Responder "todo o nada" en una entrevista
señala que no se ha mantenido en producción.

**07 → 20. Diseña el agregado `Cuenta` con event sourcing: eventos, reconstrucción, snapshots, concurrencia y proyecciones.**

⏱️ Eventos en pasado con versión, reconstrucción por `fold`, snapshot cada N eventos, concurrencia
por versión esperada y proyecciones para toda consulta que no sea por id.
🗣️ El diseño:

```text
Eventos:  CuentaAbierta{titular, moneda, v:1}
          Depositado{importe, referencia, v:n}
          Retirado{importe, referencia, v:n}
          CuentaBloqueada{motivo, v:n}   CuentaCerrada{v:n}

Almacén:  eventos(agregado_id, version, tipo, payload, occurred_at)
          PRIMARY KEY (agregado_id, version)   ← esta PK ES el bloqueo optimista

Cargar:   snapshot(v:N) + eventos WHERE version > N, aplicados en orden de version
Escribir: INSERT con version = esperada+1; si viola la PK, alguien escribió antes → reintentar
Snapshot: cada 500 eventos, regenerable, versionado aparte
```

🔬 Detalles que el entrevistador buscará. **Las invariantes se comprueban sobre el estado
reconstruido, no sobre el evento**: `Retirado` solo se emite si el saldo derivado lo permite, y
por eso hay que cargar el agregado antes de decidir. **La concurrencia la resuelve la clave
primaria**, sin bloqueos y sin `SELECT FOR UPDATE`. **Las proyecciones** son obligatorias:
"saldos actuales" para consultas por cliente, "movimientos" para el extracto, y cualquier
consulta por criterio necesita la suya. **El RGPD** se resuelve con crypto-shredding sobre los
datos del titular. Y una decisión que declararía: el saldo disponible —que descuenta operaciones
en tránsito— es una proyección distinta del saldo contable, exactamente como en un banco real.

**07 → 21. Negocio cambia el significado de un evento que lleva tres años escribiéndose. Describe las opciones y elige una.**

⏱️ Tres opciones: upcasting con una regla que distinga por fecha, un tipo de evento nuevo en
paralelo, o reescribir el log. Elijo el tipo nuevo.
🗣️ Opción A, upcasting con corte temporal: el upcaster mira `occurredAt` y aplica una
interpretación u otra. Funciona y esconde una regla de negocio dentro de código de
infraestructura, donde nadie la encontrará dentro de dos años. Opción B, tipo nuevo: se deja de
emitir el evento viejo y se emite `XxxV2` con la semántica nueva; el código de reconstrucción
maneja los dos, cada uno con su significado, y la distinción queda explícita en el dominio.
Opción C, reescribir: se transforma el log para unificar la semántica; es lo más limpio de leer
después y rompe la inmutabilidad y las referencias externas.
🔬 Elijo B y lo justifico así: es la única que deja la decisión **visible en el modelo de
dominio** en vez de enterrada en un upcaster, y no destruye evidencia. Su coste es que el código
de reconstrucción maneja dos tipos para siempre, lo cual es honesto porque el negocio de verdad
tuvo dos significados en dos periodos. Descartaría C salvo obligación regulatoria de unificar, y
A solo si el cambio es cosmético y no afecta a la interpretación de los datos. Lo que **no**
haría en ningún caso es reinterpretar los eventos viejos con la semántica nueva en silencio: eso
falsea la historia y produce informes retroactivos incorrectos.

**07 → 22. Te proponen event sourcing para todo un sistema nuevo. ¿Qué preguntas y qué recomiendas?**

⏱️ Pregunto quién paga por saber cómo se llegó al estado, y recomiendo aplicarlo a uno o dos
agregados del núcleo, no al sistema.
🗣️ Las preguntas: ¿hay obligación regulatoria de trazabilidad, o es un "estaría bien"? ¿El negocio
habla en hechos o en estados? ¿Alguien va a hacer preguntas retroactivas sobre el histórico?
¿Podéis asumir consistencia eventual visible en la interfaz? ¿Quién del equipo lo ha mantenido en
producción antes? Si las respuestas son "estaría bien", "estados", "no", "no lo hemos pensado" y
"nadie", la recomendación es clara.
🔬 Lo que recomiendo en su lugar, por orden de coste creciente: si solo quieren trazabilidad, una
tabla de auditoría o CDC; si quieren integración, eventos publicados con outbox; si quieren
lecturas rápidas, CQRS **sin** event sourcing, que son separables y casi siempre conviene
separarlos. Y si de verdad hay un agregado que lo justifica —una cuenta, una póliza—, event
sourcing ahí y CRUD en el resto. El argumento que suele convencer: el coste del patrón no se
paga al construirlo sino al mantenerlo tres años, cuando haya que versionar eventos y nadie del
equipo original siga.

**07 → 23. Un cliente ejerce su derecho de supresión sobre datos que están en 40.000 eventos inmutables. ¿Qué haces?**

⏱️ Crypto-shredding: destruyo la clave de cifrado de ese sujeto y los 40.000 eventos quedan
ilegibles sin tocarlos.
🗣️ Requiere que el diseño lo previera: los datos personales se cifran al escribir el evento con
una clave por sujeto, guardada en un almacén aparte. Al ejercerse el derecho, se destruye esa
clave. La estructura del log se conserva, la reconstrucción no se rompe, los agregados y los
informes históricos siguen cuadrando, y el contenido personal es irrecuperable.
🔬 Si el diseño **no** lo previó, las opciones son todas malas y conviene decirlo así: reescribir
el log con los campos anonimizados —caro, rompe inmutabilidad y referencias—, o mantener un mapa
de identidades reversible que se destruye, que solo funciona si los datos personales estaban
centralizados en un solo sitio. Hay además una conversación jurídica que no es del arquitecto
pero que hay que provocar: el derecho de supresión no es absoluto y convive con obligaciones de
retención —en banca, la normativa de prevención de blanqueo exige conservar diez años—, así que
lo primero es que legal defina qué hay que borrar exactamente y qué se conserva amparado por otra
base legal. La respuesta técnica sin esa definición es prematura.

---

# 08 — Proyecciones y streaming

**08 → 1. ¿Qué es una proyección?**

⏱️ Un consumidor de eventos que mantiene una vista de lectura optimizada para una consulta
concreta.
🗣️ No tiene lógica de negocio: traduce eventos en filas. Su valor es que la respuesta está ya
calculada cuando alguien pregunta, en vez de componerse en el momento a partir de cuatro
servicios.
🔬 Es una caché con contrato: lo que la distingue de una caché normal es que sabes exactamente
cómo regenerarla, y eso cambia cómo la operas.

**08 → 2. ¿Cuáles son las tres propiedades que definen una proyección?**

⏱️ Derivada, desechable y especializada.
🗣️ Derivada: se construye desde los eventos. Desechable: no es fuente de verdad, así que si
diverge se rehace. Especializada: una por consulta, sin miedo a duplicar datos entre ellas.
🔬 La tercera choca con el instinto relacional: aquí la normalización no es virtud. Cada
proyección guarda lo suyo aunque se repita, porque el objetivo es responder rápido a una
consulta concreta, no minimizar almacenamiento.

**08 → 3. ¿Qué diferencia hay entre tiempo de evento y tiempo de proceso?**

⏱️ El de evento es cuándo ocurrió, según la marca del propio evento; el de proceso, cuándo lo
leíste.
🗣️ Si agrupas "ventas por minuto" por tiempo de proceso, un consumidor lento mueve las ventas de
minuto: el resultado depende de tu infraestructura y no de lo que pasó. Casi siempre eso es un
bug.
🔬 Por eso los frameworks serios agrupan por tiempo de evento y manejan los rezagados con marcas
de agua. Y por eso todo evento lleva su propio `occurredAt`, que no es la marca que añade el
broker al recibirlo.

**08 → 4. ¿Qué problema resolvía la arquitectura Lambda y por qué se abandonó?**

⏱️ Combinaba una capa batch exacta con una de velocidad aproximada. Se abandonó porque obligaba a
escribir la misma lógica dos veces.
🗣️ La capa batch recalculaba todo periódicamente y era la verdad; la de velocidad daba resultados
inmediatos pero aproximados; las consultas combinaban ambas. Mantener la misma lógica en dos
tecnologías, dando el mismo resultado, era su defecto fundamental.
🔬 Kappa la sustituyó con un solo camino: todo es streaming, y el "recálculo batch" es reprocesar
el flujo desde el principio. Requiere retención suficiente y un motor capaz de reprocesar rápido,
que es justo lo que Kafka hizo viable.

**08 → 5. ¿Por qué una proyección usa `upsert` y no `insert`?**

⏱️ Porque la entrega es at-least-once y el mismo evento va a llegar dos veces.
🗣️ Con `insert` el duplicado revienta por clave o crea una fila repetida; con `upsert` escribe el
mismo estado final y el resultado es idéntico. Es idempotencia casi gratis, sin tabla de
deduplicación.
🔬 La regla más general: **escribir el estado final en vez de incrementar**. Un `SET total = X`
es idempotente; un `SET total = total + 1` no lo es y necesita deduplicación explícita.

**08 → 6. ¿Por qué no se normalizan las proyecciones?**

⏱️ Porque el objetivo es responder una consulta concreta en un solo acceso, no minimizar
almacenamiento.
🗣️ Si la vista necesita el nombre del producto, se guarda desnormalizado aunque ya esté en otra
proyección. Hacer `JOIN` para ahorrar espacio contradice la razón de existir de la vista.
🔬 El coste aceptado es la duplicación y la posibilidad de que dos proyecciones diverjan
temporalmente. Como son desechables, esa divergencia se resuelve reconstruyendo, no
sincronizando.

**08 → 7. ¿Por qué una proyección no debe tener lógica de negocio?**

⏱️ Porque esa regla estaría duplicada respecto del agregado y acabará divergiendo.
🗣️ Si la proyección decide si un pedido "cuenta como entregado", esa regla vive en dos sitios y
cualquier cambio tiene que aplicarse en ambos. Cuando alguien olvide uno —y lo olvidará—, la vista
dirá algo distinto que el modelo de escritura.
🔬 La proyección traduce: recibe hechos y escribe filas. Las decisiones se toman en el agregado y
llegan como eventos ya decididos, con nombres que reflejan la decisión —`PedidoEntregado`, no
`EstadoCambiado{a:3}`—.

**08 → 8. ¿Qué es la composición de API y dónde falla?**

⏱️ El gateway llama a varios servicios y junta las respuestas. Falla al paginar y al ordenar por
un campo de otro servicio.
🗣️ Para ordenar 10.000 pedidos por el nombre del cliente tendrías que traerlos todos de ambos
servicios y ordenar en memoria. Y la latencia es la suma —o el máximo— de las llamadas, con la
disponibilidad multiplicándose.
🔬 Funciona bien y es la opción correcta cuando el número de elementos es pequeño y conocido:
la pantalla de detalle de un pedido concreto. Para listados con filtros, orden y paginación, hace
falta una proyección.

**08 → 9. ¿Qué aporta Kafka Streams frente a un consumidor con una tabla?**

⏱️ Estado local gestionado y tolerante a fallos, ventanas temporales y uniones de flujos.
🗣️ El framework guarda el estado en disco local, lo respalda en un topic compactado y lo restaura
solo si el proceso muere. Las agregaciones por ventana son una línea en vez de un `cron` con una
tabla. Y puede cruzar dos flujos sin llamar a nadie.
🔬 Lo que no aporta: simplicidad. Para "evento entra, fila sale" un consumidor con SQL gana en
legibilidad, en depuración y en cuánta gente sabe mantenerlo.

**08 → 10. ¿Qué es una marca de agua y para qué sirve?**

⏱️ Es la afirmación de que ya no van a llegar eventos anteriores a cierto instante. Sirve para
decidir cuándo cerrar una ventana.
🗣️ Sin ella, una agregación por ventana de cinco minutos nunca sabría cuándo emitir el resultado,
porque siempre podría llegar un rezagado. La marca de agua fija el compromiso: espero hasta
aquí, después cierro.
🔬 Y de ahí sale la decisión de diseño: cuánto esperas. Más espera es más exactitud y más latencia;
menos espera es al revés. Los eventos que llegan después de cerrar la ventana son *late events*,
y hay que decidir si se descartan, se emiten como corrección o reabren la ventana.

**08 → 11. ¿Qué es la arquitectura Kappa?**

⏱️ Un solo camino de procesamiento: todo es streaming, y el recálculo histórico es reprocesar el
flujo desde el principio.
🗣️ Elimina la duplicación de lógica de Lambda: una sola implementación sirve para el tiempo real y
para el recálculo. Requiere un log con retención suficiente y un motor que reprocese rápido.
🔬 Es exactamente el mecanismo de "reconstruir una proyección" elevado a arquitectura de datos. Y
por eso las dos preguntas que la limitan son las mismas: ¿hay retención bastante? ¿los consumidores
toleran el reproceso?

**08 → 12. Nombra cuatro formas de manejar la ventana de inconsistencia de cara al usuario.**

⏱️ Devolver el resultado en la respuesta del comando, leer del modelo de escritura para lo propio,
token de versión, o decírselo al usuario.
🗣️ La primera resuelve el 80 % y casi nadie la propone: el `POST` devuelve el objeto creado y la
interfaz lo pinta sin consultar. La segunda lee los datos recién creados del agregado en vez de
la proyección. La tercera hace que la consulta espere a que la proyección alcance una versión. La
cuarta es mostrar "procesando" y avisar después.
🔬 Solo la tercera da garantía real de *read-your-writes*, y exige que la proyección exponga por
dónde va. Las otras tres son mitigaciones de experiencia de usuario, que casi siempre es lo que
el problema pedía en realidad.

**08 → 13. ¿Por qué una proyección nunca debe tener efectos externos?**

⏱️ Porque se va a reprocesar, y al reprocesar repetiría esos efectos.
🗣️ Reconstruir una proyección es una operación normal: por un bug, por un campo nuevo, por un
cambio de forma. Si el mismo consumidor que actualiza la tabla envía correos, la reconstrucción
envía correos de hace dos años a todos los clientes.
🔬 Por eso proyección y notificación son consumidores distintos, con propiedades distintas: uno es
reproducible y el otro no. El de notificaciones necesita deduplicación permanente y un descarte
por antigüedad del evento.

**08 → 14. Describe el procedimiento de reconstrucción sin parar el sistema.**

⏱️ Construir la nueva en paralelo desde el principio, verificar, cambiar las lecturas
atómicamente y borrar la vieja después.
🗣️ Los pasos: crear la proyección nueva vacía sin que nadie la lea; alimentarla con un consumidor
aparte desde el offset inicial; cuando alcanza la cabeza, seguir en vivo; verificar comparando
conteos y muestras contra la vieja; cambiar las lecturas con un alias o una feature flag; borrar
la vieja tras un margen.
🔬 Nunca se borra y se rehace en el sitio, porque durante la reconstrucción no habría vista y eso
es una caída. El paso de verificación es el que la gente se salta y el que evita cambiar a una
vista peor. Y la feature flag permite volver atrás en segundos.

**08 → 15. ¿Qué hace falta en el log para poder reconstruir una proyección entera?**

⏱️ Retención suficiente para cubrir todo el histórico, o compactación, o event sourcing de verdad.
🗣️ Con retención de siete días solo puedes reconstruir siete días. Si la proyección necesita el
estado completo desde el principio, hace falta retención larga —que cuesta dinero—, un topic
compactado que conserve el último valor por clave, o que el log sea la fuente de verdad.
🔬 La compactación reconstruye el **estado** pero no la **historia**: sirve para poblar una vista
de saldos actuales, no para una vista de movimientos. Elegir entre ambas es una decisión que se
toma al crear el topic y condiciona qué proyecciones podrás construir después.

**08 → 16. ¿Por qué agrupar por tiempo de proceso suele ser un bug?**

⏱️ Porque el resultado depende de tu infraestructura en vez de lo que pasó.
🗣️ Si el consumidor va con retraso, las ventas de las 14:00 se contabilizan a las 14:30 y el
informe dice que ese minuto fue flojo. Peor: al reprocesar el histórico, todo cae en el mismo
instante y las agregaciones quedan sin sentido.
🔬 La excepción legítima: cuando lo que mides **es** tu infraestructura —throughput del consumidor,
lag, tasa de procesamiento—. Ahí el tiempo de proceso es exactamente la dimensión correcta. En
todo lo que sea negocio, es el de evento.

**08 → 17. ¿Cuándo NO usarías Kafka Streams?**

⏱️ Cuando la proyección es "evento entra, fila sale": un consumidor con SQL es más simple y más
mantenible.
🗣️ La mayoría de las vistas de lectura son eso. Kafka Streams añade un modelo de programación
propio, estado local que hay que dimensionar en disco, topics internos que aparecen solos, y una
curva de entrada que limita quién puede tocarlo.
🔬 También lo evitaría cuando el equipo no tiene experiencia y el caso no lo exige: la
depuración de una topología con estado es sustancialmente más difícil que la de un listener y una
tabla. Se gana el sitio con ventanas, uniones de flujos o estado intermedio grande, no por
defecto.

**08 → 18. ¿Qué garantiza read-your-writes y qué cuesta?**

⏱️ Que el usuario vea inmediatamente lo que acaba de escribir. Cuesta propagar y esperar una
versión.
🗣️ El comando devuelve la versión resultante; la consulta la lleva y la proyección espera a
haberla alcanzado antes de responder. Es la única de las cuatro salidas que da garantía real, no
solo una mejora de experiencia.
🔬 El coste: la proyección tiene que exponer su posición, el cliente tiene que transportar el
token, y la consulta puede bloquearse o fallar si la proyección va muy retrasada —lo que obliga a
un timeout y a decidir qué hacer entonces—. Por eso se reserva para los flujos donde de verdad
importa, no para todo el sistema.

**08 → 19. ¿Por qué una proyección es "una caché con contrato"?**

⏱️ Porque es un dato derivado y desechable, como una caché, pero con un procedimiento conocido y
determinista para regenerarla.
🗣️ Una caché normal se invalida y se repuebla consultando el origen, con toda la incertidumbre de
qué estaba obsoleto. Una proyección se reconstruye aplicando el log desde el principio, y el
resultado es exactamente reproducible.
🔬 Esa diferencia cambia cómo la operas: ante una divergencia no investigas qué entrada está mal,
reconstruyes. Y es lo que permite tratar los bugs de la vista como incidentes recuperables en vez
de como corrupción de datos.

**08 → 20. Diseña la proyección de "pedidos del cliente con estado de envío y factura": qué eventos consume, qué tabla mantiene y cómo se reconstruye.**

⏱️ Una tabla desnormalizada por pedido, alimentada por eventos de tres contextos, con `upsert`
idempotente y reconstrucción en paralelo.
🗣️ El diseño:

```text
Consume:  PedidoConfirmado, PedidoCancelado   (contexto Pedidos)
          EnvioCreado, EnvioEntregado         (contexto Envíos)
          FacturaEmitida, FacturaPagada       (contexto Facturación)

Tabla:    vista_pedidos_cliente(
            pedido_id PK, cliente_id, fecha, total_importe, total_moneda,
            estado_pedido, estado_envio, estado_factura,
            ultima_version_aplicada)
          ÍNDICE (cliente_id, fecha DESC)   ← la consulta que existe para servir

Escritura: UPSERT por pedido_id, campo a campo según el evento.
           Descarta si evento.version <= ultima_version_aplicada.
```

Cada evento actualiza solo su columna, así que el orden entre contextos distintos no importa.
🔬 Decisiones a justificar. **Desnormalizada a propósito**: el cliente y el total se copian aquí
aunque estén en otro sitio, porque la consulta debe resolverse sin `JOIN`. **Tolerante al
desorden** con la versión por contexto, porque tres productores independientes no tienen orden
entre sí. **Sin lógica de negocio**: si "entregado parcialmente" es un estado, lo decide Envíos y
llega como evento, no se calcula aquí. **Sin efectos externos**, para poder reconstruir.
Reconstrucción: tabla nueva en paralelo desde el offset inicial de los tres topics, verificación
por conteo y muestreo, cambio por feature flag. Y la ventana de inconsistencia se resuelve
devolviendo el pedido creado en la respuesta del comando.

**08 → 21. Al reconstruir una proyección se enviaron 400.000 correos antiguos. Reconstruye el error de diseño y cómo se evita.**

⏱️ El mismo consumidor proyectaba y notificaba. Un efecto irreversible no puede vivir en un
componente reprocesable.
🗣️ Lo que pasó: alguien arrancó un grupo nuevo desde `earliest` para rehacer la vista, y el
listener que actualizaba la tabla también enviaba el correo. Kafka entregó el histórico, que es su
trabajo. El fallo es de diseño, no de operación.
🔬 Cómo se evita, en cuatro niveles. **Separación**: proyección y notificación son consumidores
distintos, porque uno es reproducible y el otro no. **Deduplicación permanente** en el de
notificaciones, por `eventId`, sin TTL corto. **Descarte por antigüedad**: un evento con
`occurredAt` de hace más de X no se notifica, porque notificar algo de hace dos años no tiene
sentido aunque no se hubiera notificado. Y **procedimiento**: arrancar un grupo desde `earliest`
debe ser una operación deliberada y revisada, no el valor por defecto de una configuración
copiada. Añadiría una quinta defensa práctica: un interruptor global de envío que se pueda apagar
antes de cualquier reproceso.

**08 → 22. El usuario crea un pedido y no lo ve en su lista. Da cuatro soluciones, con su coste, y elige una justificándola.**

⏱️ Devolver el pedido en la respuesta, leer del modelo de escritura para lo propio, token de
versión, o mostrar "procesando". Elijo la primera.
🗣️ Las cuatro con su coste. **Devolver el resultado en la respuesta del `POST`**: coste casi
cero, el cliente pinta el pedido sin consultar; no cubre el caso de recargar la página.
**Leer del modelo de escritura los datos propios recientes**: coste medio, rompe la separación de
CQRS y añade carga al lado de escritura; cubre la recarga. **Token de versión**: coste alto,
requiere propagar la versión y que la proyección exponga su posición; es la única con garantía
real. **Mostrar "procesando"**: coste cero técnico y alto de producto, porque cambia la
experiencia.
🔬 Elijo la primera como base y la combino con la cuarta: devuelvo el pedido creado y, si el
usuario recarga en los primeros segundos, muestro el pedido con un indicador de "confirmando" en
lugar de ocultarlo. Justificación: el 80 % de los casos es el usuario mirando la pantalla justo
después de crear, y eso se resuelve sin tocar la arquitectura. Reservaría el token de versión
para un flujo concreto donde la garantía sea un requisito —una confirmación legal, un
comprobante— porque su coste no se justifica a nivel de sistema. Y antes de todo eso preguntaría
cuánto dura de verdad la ventana: si son minutos y no milisegundos, el problema no es de CQRS
sino de lag, y se arregla escalando el consumidor.

**08 → 23. Necesitas "pedidos rechazados por cliente en los últimos 15 minutos" en tiempo real. ¿Consumidor con tabla o Kafka Streams? Justifica.**

⏱️ Kafka Streams. Es exactamente su caso: agregación con ventana deslizante, que con un
consumidor y una tabla se implementa mal.
🗣️ Con consumidor y tabla tendrías que insertar cada rechazo con su marca de tiempo, y en cada
consulta contar los de los últimos 15 minutos, además de un proceso de limpieza. Funciona, pero la
tabla crece con el volumen, la consulta escanea un rango en cada petición y la limpieza es un
`cron` más que mantener. Con Kafka Streams es una ventana deslizante sobre una agregación por
clave: el framework mantiene el estado, lo purga solo y emite actualizaciones.
🔬 Lo que hay que decidir además, y es donde se ve si lo has usado: **agrupar por tiempo de
evento**, no de proceso, porque si no un consumidor retrasado desplaza la ventana y el resultado
mide tu lag en vez de los rechazos. **La marca de agua**, es decir cuánto esperas a los rezagados
antes de cerrar; con 15 minutos de ventana, unos segundos suele bastar. Y **qué se hace con los
eventos tardíos**: descartarlos o emitir una corrección. Matizaría una cosa: si "en tiempo real"
significa de verdad segundos y el volumen es alto, Streams gana claramente; si significa "en el
último minuto" y el volumen es moderado, un `SELECT` con índice sobre una tabla de rechazos es
más simple y suficiente, y lo propondría primero.

---

# 09 — Simulación: escenarios de diseño

> Las preguntas `S#` del bloque 2 de [`09`](09-simulacion-de-entrevista.md) se responden con las
> entradas de los capítulos correspondientes, que están arriba. Aquí van los cinco escenarios, que
> sí llevan solución desarrollada.

## E1 — El que NO necesita broker

**Respuesta corta:** no monto Kafka. Una tabla con estado y un proceso que la recorre resuelve el
caso entero, y propongo el criterio objetivo por el que cambiaría de opinión.

**Los números.** 300 órdenes al día son unas 40 por hora en horario laboral: menos de una por
minuto. Dos consumidores conocidos y fijos. Un equipo de cuatro personas, sin nadie dedicado a
operar infraestructura. No hay ningún requisito de releer, ni de añadir consumidores futuros
desconocidos, ni de absorber picos.

**Lo que propongo.** Una tabla `eventos_pendientes` en la base de datos que ya existe, escrita en
la misma transacción que la aprobación de la orden —que es un outbox, aunque no haga falta
llamarlo así—, y un proceso programado que la recorre con `FOR UPDATE SKIP LOCKED`, notifica a
contabilidad y actualiza el panel. Eso da durabilidad, reintento, orden, una columna `intentos`
que hace de DLQ, y todo dentro de la transacción que ya tienen. Se depura con un `SELECT`.

**Lo que cuesta Kafka aquí**, y lo digo con nombres: un clúster que dimensionar y parchear,
particiones que decidir sin datos para decidirlas, rebalanceos que diagnosticar, retención que
presupuestar, y un modo de fallo —consumidor rezagado, partición caliente, mensaje envenenado—
que nadie del equipo ha visto nunca. Para 40 mensajes por hora, esa factura no la amortiza nada.

**El disparador acordado.** Cambiaría de opinión si aparece cualquiera de estas tres: consumidores
independientes que no conocemos hoy y que quieran el histórico; volumen que la base de datos ya no
absorba; o necesidad de reprocesar. Ninguna está en el horizonte.

**Cómo lo digo al equipo**, porque el fondo no basta: reconozco que quieren aprender Kafka y que
es una motivación legítima, y propongo separarla del producto —un proyecto interno, una prueba de
concepto— en vez de introducir una dependencia crítica en un sistema que no la necesita.

## E2 — Doble escritura en producción

**Respuesta corta:** es el problema de la doble escritura. Se arregla con outbox, y antes hay que
cuantificar y recuperar lo ya perdido.

**El diagnóstico.** El método confirma en la base de datos y publica a Kafka; el `send` está fuera
de la transacción aunque parezca dentro. Si el commit ocurre y el `send` falla —o el proceso muere
entre ambos—, el pedido queda confirmado y nadie se entera. Que pase una vez por semana encaja con
reinicios de pods, despliegues o hipos del broker. La pista definitiva: los pedidos huérfanos
coinciden en el tiempo con reinicios del servicio.

**Cuantificar lo perdido**, que es lo primero y nadie lo hace: una consulta que cruce pedidos
confirmados contra facturas emitidas en el mismo periodo da la lista exacta de huérfanos. Eso
convierte "nadie sabe cuántos" en un número, y con el número se decide si se reprocesan
manualmente, si se generan las facturas faltantes, o si hay un impacto contable que declarar.

**La solución.** Outbox: el evento se escribe en una tabla de la propia base de datos dentro de la
transacción del caso de uso, y un relay con `FOR UPDATE SKIP LOCKED` publica y marca. La
atomicidad pasa a ser real porque son dos escrituras en un solo sistema.

**Lo que hay que añadir para que no vuelva a pasar en silencio.** Alerta sobre la **antigüedad de
la fila pendiente más vieja**, que es la métrica que importa; tasa de publicación y errores del
relay como contexto. Con eso, el mismo fallo pasa de "se perdió un evento y lo descubrimos meses
después" a "hay filas esperando y lo sabemos en minutos".

**Lo que no cambia y hay que decir.** El outbox elimina la pérdida, no el duplicado: el relay
puede publicar y morir antes de marcar, así que facturación tiene que ser idempotente por
`pedidoId`. Si no lo era, esa es la segunda mitad del trabajo.

**La migración.** Se despliega el outbox escribiendo la fila **y** manteniendo el `send` actual
durante un periodo, con facturación deduplicando; se verifica que el relay publica todo; y se
retira el `send` directo. Así no hay ventana en la que nada publique.

## E3 — Consistencia entre servicios

**Respuesta corta:** saga orquestada, con `Reserva` como agregado propio, reservas temporales con
TTL, el cobro como pivote y estado visible para el usuario.

**El flujo y sus compensaciones** están en la respuesta
[05 → 20](#05--saga) y no los repito. Lo que añade este escenario es **qué ve el usuario**, que es
la parte que se suele olvidar y la que el entrevistador va a explorar.

**El usuario no espera bloqueado.** La petición devuelve inmediatamente un identificador de reserva
y un estado `PROCESANDO`. La interfaz muestra progreso real —"asiento reservado", "procesando
pago"— consultando el estado de la saga, que existe precisamente porque elegí orquestación. Cuando
termina, la confirmación llega por notificación y por el propio estado.

**Por qué no hago esperar al usuario síncronamente.** Con tres servicios en cadena, la latencia es
la suma y la disponibilidad el producto; una pasarela lenta convierte la reserva en un timeout. Y
si el usuario cierra la pestaña, la saga tiene que terminar igual: eso solo funciona si el proceso
es independiente de la conexión.

**Los fallos, en lenguaje de usuario.** Si falla el asiento: "no hay disponibilidad", inmediato. Si
falla el equipaje: se libera el asiento y se ofrece reservar sin equipaje o cancelar. Si falla el
cobro: se libera todo y se explica el motivo que devuelva la pasarela. Si falla la confirmación
tras el cobro: **no se revierte el cobro automáticamente**; se muestra "estamos confirmando tu
reserva" y se escala a intervención, porque revertir un cobro correcto por un fallo de
infraestructura es peor que un minuto de espera.

**Lo que no es negociable.** TTL de 15 minutos en las reservas de asiento y equipaje, para que un
fallo del orquestador no bloquee inventario para siempre. Idempotencia por `reservaId` en cada
paso. Estado persistido tras cada transición. Y los pasos irreversibles —emitir billete,
notificar— estrictamente después del pivote.

## E4 — Reprocesar sin romper

**Respuesta corta:** proyección nueva en paralelo, verificación contra la vieja, cambio por feature
flag — y antes de nada, comprobar si la retención de 30 días cubre lo que hay que corregir.

**El límite que decide todo.** El bug lleva tres semanas y la retención es de 30 días: entra
justo, con poco margen. Lo primero que verifico es que los eventos más antiguos afectados siguen en
el topic. Si el bug llevara cinco semanas, reconstruir desde el log no sería posible y habría que
corregir por otra vía —recalcular desde el modelo de escritura, o aceptar que los pedidos anteriores
quedan como están—. Decirlo primero demuestra que se conoce la restricción real del patrón.

**El procedimiento.**

```text
1. Corregir el código de la proyección. Sin esto, reconstruir reproduce el bug.
2. Crear vista_pedidos_v2 vacía. Nadie la lee.
3. Consumidor nuevo, grupo nuevo, desde el offset de hace 30 días (o earliest).
   Con límite de tasa, para no competir con el tráfico en vivo.
4. Alcanza la cabeza y sigue en vivo. Ahora hay dos vistas actualizándose.
5. VERIFICAR: conteos totales, y muestreo de los pedidos parcialmente enviados,
   que son los que el bug afectaba. Comparar contra el modelo de escritura, no
   contra la vista vieja: la vieja está mal, es lo que estamos arreglando.
6. Cambiar las lecturas de la app con feature flag, por porcentaje si se puede.
7. Observar métricas de la app 24-48 h. Borrar la vieja después.
```

**Por qué no borro y rehago en el sitio.** Dos millones de usuarios se quedarían sin vista durante
la reconstrucción. Eso es una caída, no un mantenimiento.

**Lo que hay que verificar antes de arrancar el consumidor.** Que la proyección **no tenga efectos
externos** —si el mismo listener notificaba algo, el reproceso lo dispararía—; que use `occurredAt`
y no `now()`; y que sea idempotente y tolerante al desorden, porque va a procesar eventos antiguos
mezclados con nuevos.

**El plan de vuelta atrás.** La feature flag permite volver a la vista vieja en segundos si algo
sale mal. Por eso no se borra la vieja hasta pasados uno o dos días, aunque ocupe espacio.

**Lo que comunico.** Soporte tiene que saber que durante tres semanas el estado mostrado pudo ser
incorrecto, para poder responder a los usuarios que lo noten, y que a partir del cambio se corrige
retroactivamente.

## E5 — Migración de síncrono a eventos

**Respuesta corta:** desacoplo primero lo que no es requisito para confirmar —notificaciones,
analítica, envíos, facturación—, dejo síncrono lo que sí lo es —inventario, si el stock puede
agotarse—, y convivo con las dos formas usando outbox.

**El análisis previo, que es donde está el valor.** De las cinco dependencias, la pregunta es cuál
tiene que haber terminado para poder decirle "confirmado" al usuario:

```text
Inventario     → ¿puede agotarse el stock? Si sí, es requisito: o reserva antes, o hay sobreventa.
Facturación    → no. La factura puede tardar.
Envíos         → no. El envío se crea después.
Notificaciones → no, evidentemente.
Analítica      → no.
```

Cuatro de cinco no son requisito. Ahí está el 4 segundos y buena parte del 2 % de fallos.

**El orden de migración**, de menor a mayor riesgo:

```text
1. Analítica        → es una proyección, reconstruible, cero riesgo de negocio.
2. Notificaciones   → cuidado: efecto irreversible, necesita deduplicación permanente.
3. Facturación      → el impacto es que la factura tarda; se acuerda con negocio.
4. Envíos           → similar, con su propia ventana.
5. Inventario       → el último y quizá nunca, según la decisión sobre sobreventa.
```

**Cómo convivo con las dos formas.** En cada paso, el monolito escribe el evento en su tabla de
outbox dentro de la transacción de confirmación, **y** mantiene la llamada síncrona. El consumidor
nuevo procesa en paralelo y se verifica que produce el mismo resultado. Cuando cuadra durante un
periodo, se retira la llamada síncrona. Así nunca hay una ventana en la que la funcionalidad
dependa solo de lo nuevo sin haberlo probado.

**La decisión de inventario**, que es la única de negocio: o se reserva el stock antes de confirmar
—síncrono, y sigue siendo un punto de fallo—, o se acepta sobreventa con compensación —evento, y
alguien decide qué se le dice al cliente cuyo pedido se cancela después—. Llevo las dos opciones con
sus números: cuántas sobreventas habría al mes con el volumen actual, y qué cuesta cada una.

**Cómo mido el avance.** No por dependencias migradas, sino por **latencia p99 de la confirmación**
y **tasa de fallo de la confirmación**. Si tras migrar analítica y notificaciones el p99 no baja,
la hipótesis sobre dónde estaba el tiempo era falsa y hay que revisarla antes de seguir.

---

**Anterior:** [`09` — Simulación de entrevista](09-simulacion-de-entrevista.md) ·
**Índice del bloque:** [README](README.md)
