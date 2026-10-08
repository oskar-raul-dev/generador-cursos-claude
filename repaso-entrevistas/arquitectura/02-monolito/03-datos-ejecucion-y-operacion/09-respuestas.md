# 09 — Respuestas: Datos, ejecución y operación

> Solucionario completo de los capítulos y de la simulación. Cada enunciado se conserva literalmente y cada respuesta usa tres capas.
>
> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#-01--transacciones-locales-y-límites-de-consistencia) · [02](#-02--concurrencia-locking-e-idempotencia) · [03](#-03--eventos-internos-jobs-y-procesamiento-asíncrono) · [04](#-04--rendimiento-caché-y-escalado) · [05](#-05--despliegues-migraciones-de-esquema-y-rollback) · [06](#-06--observabilidad-y-resiliencia-del-monolito) · [07](#-07--estrategia-de-pruebas-y-evidencia-de-modularidad) · [Simulación](#-respuestas-de-la-simulación)

## 📖 01 — Transacciones locales y límites de consistencia

### 1. 🟢 ¿Qué invariante de `CreateOrder` justifica que pedido y reserva compartan un `COMMIT`?

⏱️ **30 segundos:** Que un pedido `CONFIRMED` tenga una reserva viva por cada línea. Si esa es la promesa de negocio, las dos escrituras se confirman juntas o ninguna.

🗣️ **2 minutos:** Pedido y reserva están en la misma base y los decide el mismo caso de uso, así que un `COMMIT` compartido es la forma más barata de cumplirla. Separarlas obliga a gestionar el estado intermedio —pedido sin reserva— con compensación o reconciliación: más código, más estados visibles y más soporte.

🔬 **El detalle:** La invariante se escribe antes que la anotación. Si nadie puede enunciarla, la frontera se está eligiendo por comodidad del framework.

### 2. 🟢 ¿Qué garantizan por separado atomicidad, aislamiento y durabilidad, y cuál de las tres se suele suponer, por error, sobre una llamada de red?

⏱️ **30 segundos:** Atomicidad: todo o nada; aislamiento: qué ven las transacciones concurrentes; durabilidad: lo confirmado sobrevive a una caída. La que se supone por error sobre la red es la atomicidad.

🗣️ **2 minutos:** Una llamada HTTP dentro del bloque no se deshace con el rollback: ya ocurrió en otro sistema. El aislamiento tampoco alcanza al proveedor, que atiende sus propias peticiones concurrentes. Y la durabilidad empieza con el `COMMIT` exitoso; antes, nada está garantizado.

🔬 **El detalle:** La «C» de ACID no la aporta el motor por sí solo: la base preserva las reglas que están declaradas como restricciones, y el resto depende del código.

### 3. 🟢 ¿Por qué autorizar un pago no puede formar parte de la transacción local del pedido?

⏱️ **30 segundos:** Porque ocurre en otro sistema: la base local no puede deshacerla, y esperarla dentro del bloque retiene locks durante la latencia del proveedor.

🗣️ **2 minutos:** Si la autorización va dentro y después el `COMMIT` falla, el proveedor autorizó el pago de un pedido que no existe. Si va dentro y tarda, la fila del SKU queda bloqueada ese tiempo. El patrón es registrar la intención en la transacción y llamar después, con clave idempotente.

🔬 **El detalle:** El resultado incierto de esa llamada —timeout después de autorizar— y su reconciliación son el tema de fallos parciales del bloque 04; aquí basta con saber que el pago converge, no se confirma atómicamente con el pedido.

### 4. 🟢 ¿Qué significa una sesión `idle in transaction` y por qué es una señal relevante para este capítulo?

⏱️ **30 segundos:** Es una conexión con una transacción abierta que no está ejecutando ninguna sentencia: el código hace otra cosa, a menudo esperar a la red, mientras retiene locks.

🗣️ **2 minutos:** En este caso es la huella directa de la llamada al proveedor dentro de la transacción: la sesión tiene bloqueada la fila del SKU y no usa la base. Se ve en `pg_stat_activity` con el estado `idle in transaction` y la antigüedad de `xact_start`.

🔬 **El detalle:** `idle_in_transaction_session_timeout` corta esas sesiones y protege la base, pero es una barrera, no una corrección: el pedido falla en lugar de esperar.

### 5. 🟢 ¿Qué es un efecto no atómico posterior y qué registro necesita para no perderse?

⏱️ **30 segundos:** Un paso que debe ocurrir porque se confirmó el pedido pero no cabe en su `COMMIT`, como autorizar el pago o avisar al cliente. Necesita una fila durable escrita dentro de esa misma transacción.

🗣️ **2 minutos:** Si se lanza en memoria después del `COMMIT`, una caída entre ambos lo pierde sin rastro. Escrito como trabajo pendiente en la transacción, sobrevive y un worker lo ejecuta con reintentos. El precio es consistencia eventual: el aviso llega segundos después.

🔬 **El detalle:** El mecanismo concreto —tabla de trabajo, lease, deduplicación— es el del capítulo de eventos internos y jobs.

### 6. 🟢 ¿Qué diferencia hay entre una transacción por caso de uso y una transacción por petición HTTP?

⏱️ **30 segundos:** La del caso de uso rodea la invariante; la de la petición rodea todo lo que pasa mientras la conexión HTTP está abierta, incluida la red y la serialización de la respuesta.

🗣️ **2 minutos:** Los filtros que abren una transacción por petición, u *Open Session in View*, convierten cada endpoint en una transacción larga sin que nadie lo decida. La del caso de uso se abre en el servicio de aplicación, justo alrededor de las escrituras que protegen la invariante.

🔬 **El detalle:** Con una transacción por petición, un cambio en cómo se arma la respuesta puede alargar locks: el acoplamiento aparece donde nadie lo busca.

### 7. 🟡 Encuentras pedidos `CONFIRMED` sin reserva. ¿Qué hipótesis revisarías antes de culpar a la frontera transaccional?

⏱️ **30 segundos:** Que el pedido se confirmara bien y después un job o una cancelación liberara su reserva: el síntoma sería el mismo con otra causa.

🗣️ **2 minutos:** Cruzo cada pedido afectado con su historial. Si nunca hubo filas de reserva, apunta a commits separados; si las hubo y desaparecieron, apunta al proceso que libera reservas vencidas. También miro si los casos coinciden con errores de pool o timeouts entre dos escrituras.

🔬 **El detalle:** Separar observación de causa evita «arreglar» la transacción y dejar vivo el job que borra reservas de pedidos ya confirmados.

### 8. 🟡 ¿Por qué una transacción que envuelve la llamada al proveedor de pagos degrada también pedidos que no dependen de ese pago?

⏱️ **30 segundos:** Porque retiene locks de inventario y conexiones del pool durante la latencia del proveedor, y esos recursos los comparten todos los pedidos.

🗣️ **2 minutos:** Un pedido del SKU popular espera el lock que tiene otro pedido esperando al proveedor. Si además se agota el pool, esperan pedidos de SKU que nadie bloqueó. La latencia remota se vuelve contención local: acoplamiento temporal dentro de un solo proceso.

🔬 **El detalle:** La medición útil no es la latencia media del proveedor, sino cuánto tiempo retiene locks cada transacción y cuántas esperas de lock hay por SKU.

### 9. 🟡 ¿Cuándo es legítimo que una transacción local cruce los módulos `orders` e `inventory`?

⏱️ **30 segundos:** Cuando una sola invariante necesita escrituras de los dos, están en la misma base y cada módulo escribe solo sus tablas a través de su API.

🗣️ **2 minutos:** La transacción la coordina el caso de uso; `inventory` sigue siendo dueño de la reserva y de su regla. Lo ilegítimo es que `orders` escriba filas de `inventory` porque «total, es la misma transacción». Cruzar módulos dentro de un proceso es barato; perder el dueño del dato, no.

🔬 **El detalle:** Es una ventaja real del monolito modular: una garantía atómica entre módulos que, distribuidos, exigiría saga o reconciliación.

### 10. 🟡 Negocio cambia la promesa a «aceptamos el pedido y confirmamos el stock en segundos». ¿Qué cambia en la frontera transaccional?

⏱️ **30 segundos:** La invariante se debilita a propósito: el pedido puede existir en `PENDING_STOCK` y la reserva se confirma después, así que ya no necesitan el mismo `COMMIT`.

🗣️ **2 minutos:** Se gana menos contención en SKU calientes y se paga un estado intermedio visible, un proceso que confirme o rechace, y mensajes al cliente para el rechazo tardío. La decisión es de negocio; el cambio técnico solo la implementa.

🔬 **El detalle:** Cambiar la promesa sin cambiar la pantalla produce pedidos «confirmados» que luego se cancelan, y ese coste lo paga soporte.

### 11. 🟡 ¿Qué anomalía de concurrencia justificaría subir el nivel de aislamiento en este caso, y qué pagarías por hacerlo?

⏱️ **30 segundos:** Por ejemplo un *write skew*: dos reservas leen el mismo total disponible y escriben filas distintas que juntas superan el stock. Se paga con abortos por serialización que el código debe reintentar.

🗣️ **2 minutos:** En *read committed*, cada transacción ve un total válido y ninguna escribe la fila que la otra leyó, así que no hay conflicto que la base detecte. `SERIALIZABLE` sí lo detecta y aborta una. Antes de subirlo compruebo si un `UPDATE` condicional o una restricción resuelven la misma anomalía más barato.

🔬 **El detalle:** El aislamiento se elige por la anomalía concreta que se quiere impedir, no como «más seguro» en abstracto; y cada aborto reintentado es latencia y carga extra.

### 12. 🟡 ¿Por qué publicar un evento en memoria antes del commit rompe la garantía aunque el código esté dentro de `@Transactional`?

⏱️ **30 segundos:** Porque los consumidores reaccionan en cuanto se publica y, si la transacción hace rollback después, reaccionaron a un pedido que no existe.

🗣️ **2 minutos:** `@Transactional` delimita la base, no los listeners en memoria. La corrección es publicar después del commit —`@TransactionalEventListener`, cuya fase por defecto es tras el commit— o escribir el trabajo en la misma transacción si el efecto es obligatorio.

🔬 **El detalle:** Tras el commit tampoco es durable: si el proceso cae entre el `COMMIT` y el listener, el aviso se pierde. Lo obligatorio va a una tabla.

### 13. 🟡 ¿Qué debe registrar el flujo cuando el commit local tuvo éxito y la llamada posterior al proveedor falla?

⏱️ **30 segundos:** Que el pedido está pendiente de pago, el intento hecho, su clave idempotente y cuándo reintentar o reconciliar.

🗣️ **2 minutos:** El `COMMIT` ya ocurrió: no hay rollback que aplicar. El flujo deja un estado explícito, como `PAYMENT_PENDING`, y el worker consulta al proveedor por la clave antes de repetir, porque el fallo pudo ser un timeout después de autorizar. El cliente ve «procesando», no un error.

🔬 **El detalle:** Un `catch` que devuelve error al cliente después del commit produce el peor caso: el cliente reintenta, el pedido ya existe y el pago puede duplicarse.

### 14. 🟡 ¿Qué diferencia hay entre revertir una reserva y compensar una autorización de pago?

⏱️ **30 segundos:** Revertir la reserva es no confirmar filas locales; compensar la autorización es una operación nueva en el proveedor, que puede fallar.

🗣️ **2 minutos:** Antes del commit, el rollback elimina la reserva sin dejar rastro. La autorización remota ya produjo un efecto: se anula con otra llamada, con su propia idempotencia, y queda en el historial del proveedor. Por eso compensar necesita estado y observabilidad; revertir, no.

🔬 **El detalle:** Una compensación puede llegar tarde o ser imposible, por ejemplo si el cobro ya se liquidó; el diseño necesita una salida manual para ese caso.

### 15. 🟡 ¿Cómo influye el pool de conexiones en el coste de una transacción larga?

⏱️ **30 segundos:** Cada transacción abierta ocupa una conexión; alargarla reduce cuántas peticiones puede atender el pool a la vez.

🗣️ **2 minutos:** Con 20 conexiones y transacciones de 2 s, el techo ronda las 10 transacciones por segundo aunque la CPU esté ociosa (supuesto del ejemplo). Cuando el pool se agota, pedidos sin relación esperan conexión y el síntoma parece «la base está lenta». Acortar la transacción libera capacidad sin tocar hardware.

🔬 **El detalle:** Agrandar el pool traslada el problema a la base: más sesiones concurrentes compitiendo por los mismos locks.

### 16. 🟡 ¿Qué prueba demostraría que pedido y reserva son atómicos de verdad?

⏱️ **30 segundos:** Una prueba contra la base real que provoque un error después de escribir pedido y reserva y antes del `COMMIT`, y compruebe que no queda ninguna de las dos.

🗣️ **2 minutos:** Inyecto el fallo después de la segunda escritura y antes del `COMMIT`, por ejemplo con un doble de `inventory` que lance tras escribir. Después consulto ambas tablas desde otra conexión. Con un repositorio simulado la prueba no demuestra nada: la atomicidad la da la base.

🔬 **El detalle:** La misma prueba detecta la auto-invocación en Spring o el `db.Exec` en Go: el síntoma es que la primera escritura sobrevive.

### 17. 🟡 ¿Cómo cambia la frontera efectiva entre `@Transactional` de Spring y un `sql.Tx` explícito en Go?

⏱️ **30 segundos:** En Spring la frontera la marca un proxy alrededor del método y participa cualquier código que use la conexión ligada al hilo; en Go la frontera es el valor `sql.Tx` y solo participa quien lo recibe.

🗣️ **2 minutos:** Lo declarativo es cómodo y fácil de romper sin verlo: auto-invocación, otro hilo o un `REQUIRES_NEW` cambian la frontera sin cambiar el código de negocio. Lo explícito obliga a pasar `tx` por parámetro y hace visible qué participa, al coste de firmas más largas. En los dos, la red sigue fuera.

🔬 **El detalle:** `TransactionTemplate` da en Spring la versión explícita cuando la frontera es sutil y conviene que se lea en el código.

### 18. 🟠 ¿Qué error equivalente comparten mezclar un cliente global en Node/TypeScript y salir del contexto transaccional en Python?

⏱️ **30 segundos:** Los dos ejecutan una escritura fuera de la transacción creyendo que está dentro.

🗣️ **2 minutos:** En Node, llamar al cliente global en lugar del cliente de la transacción envía la sentencia por otra conexión, con autocommit. En Python, escribir después de salir del `with` o con otra sesión produce lo mismo. El código parece atómico y la prueba del camino feliz pasa; solo una prueba que provoque rollback lo revela.

🔬 **El detalle:** Pasar el objeto de transacción de forma explícita, como en Go, reduce ese riesgo en cualquier lenguaje.

### 19. 🟠 Un método `@Transactional` llama a otro método `@Transactional(propagation = REQUIRES_NEW)` de la misma clase para guardar la reserva. ¿Qué ocurre y cómo lo detectarías?

⏱️ **30 segundos:** La auto-invocación no pasa por el proxy: `REQUIRES_NEW` se ignora y la reserva se guarda en la transacción externa.

🗣️ **2 minutos:** Quien escribió `REQUIRES_NEW` esperaba que la reserva tuviera su propio `COMMIT`; no lo tiene. Lo detecto con el log de depuración de `org.springframework.transaction`, que registra cada transacción nueva, o con una prueba de rollback. La corrección es mover el método a otro bean o usar `TransactionTemplate`.

🔬 **El detalle:** Antes de corregir pregunto si de verdad hace falta otra transacción: a menudo `REQUIRES_NEW` encubre una frontera mal elegida.

### 20. 🟠 Tras un despliegue, la base muestra muchas sesiones `idle in transaction` de dos segundos. ¿Qué harías en la primera hora y qué después?

⏱️ **30 segundos:** Primero contener: revertir el despliegue si es posible o limitar la duración con `idle_in_transaction_session_timeout`; después, encontrar qué código espera dentro de la transacción.

🗣️ **2 minutos:** En la primera hora miro en `pg_stat_activity` la última sentencia de esas sesiones y busco en el diff llamadas remotas o lógica nueva dentro de métodos transaccionales. Revertir es la acción reversible más barata. Luego saco la espera del bloque y añado una alerta por duración de transacción.

🔬 **El detalle:** El timeout protege la base a costa de fallar pedidos; si queda como solución permanente, el defecto se esconde en la tasa de errores.

### 21. 🟠 Negocio exige que ningún pedido quede confirmado sin pago autorizado. ¿Cómo lo representarías sin meter al proveedor en la transacción?

⏱️ **30 segundos:** Con un estado: el pedido pasa a `CONFIRMED` solo cuando llega la autorización; mientras tanto está `PAYMENT_PENDING` con la reserva viva.

🗣️ **2 minutos:** La transacción local crea pedido pendiente, reserva y trabajo de autorización. Un worker llama al proveedor con clave idempotente, y otra transacción local confirma el pedido al recibir el resultado. La invariante se cumple por construcción sin retener locks durante la red. El precio es un estado intermedio visible y reservas que vencen si el pago no llega.

🔬 **El detalle:** Si la reserva vence antes que el pago, hay que decidir entre renovar, anular el pago o revisar a mano. Esa regla se escribe antes de producción, no durante el primer incidente.

### 22. 🟠 Quieres separar el `COMMIT` de pedido y reserva para reducir contención. ¿Qué paso reversible darías antes de cambiar la promesa?

⏱️ **30 segundos:** Medir cuántos pedidos esperan por locks de reserva y probar el estado intermedio detrás de una feature flag para un SKU o una cohorte.

🗣️ **2 minutos:** Añado el estado `PENDING_STOCK` y el proceso que lo resuelve sin activarlo; enciendo la flag para un grupo pequeño y comparo esperas de lock, rechazos tardíos y reclamos. Si el beneficio no aparece, apago la flag y la promesa original sigue intacta porque nunca se retiró.

🔬 **El detalle:** Lo irreversible es comunicar la nueva promesa a los clientes; la parte técnica se puede ensayar sin hacerlo.

### 23. 🟠 Dos equipos discrepan: uno quiere una transacción que incluya a `payments` y otro separar todo con eventos. ¿Cómo decidirías?

⏱️ **30 segundos:** Con la invariante y los datos de contención: la transacción no puede incluir al proveedor, y separarlo todo rompe una garantía local que hoy es barata.

🗣️ **2 minutos:** Enumero qué debe ser atómico —pedido y reserva— y qué converge —pago y aviso—. Al primer equipo le muestro que el rollback no deshace la autorización; al segundo, que eventos entre pedido y reserva crean pedidos sin reserva que hoy no existen. Propongo transacción local más trabajo durable, con métricas de lock y de pendientes para revisar.

🔬 **El detalle:** La discusión suele destrabarse cuando ambos equipos escriben la invariante en una frase y comprueban qué base puede garantizarla.

### 24. 🟠 ¿Qué criterio te diría que la transacción ya protege la invariante mínima y no hay que ampliarla?

⏱️ **30 segundos:** La prueba de rollback pasa, no quedan sesiones `idle in transaction` atribuibles al caso de uso y las esperas de lock por SKU están dentro del objetivo.

🗣️ **2 minutos:** Si la invariante está protegida y el coste medido es aceptable, ampliar la transacción solo añade contención. Lo que queda —pago y aviso— ya tiene estado y worker. Reviso la frontera si cambia la promesa de negocio o si la contención vuelve a subir.

🔬 **El detalle:** Parar también es una decisión documentada: la invariante, la prueba que la demuestra y la métrica que obligaría a revisarla.

## 📖 02 — Concurrencia, locking e idempotencia

### 1. 🟢 ¿Qué diferencia hay entre una carrera y una repetición, y qué defensa corresponde a cada una?

⏱️ **30 segundos:** Carrera: dos intenciones distintas compiten por la misma fila. Repetición: una intención llega dos veces. La primera se defiende con la base comparando al escribir; la segunda, con una clave que identifica la intención.

🗣️ **2 minutos:** Se confunden porque las dos producen «una reserva de más». Pero un `UPDATE` condicional no distingue un reintento de un cliente nuevo, y una clave de idempotencia no impide que dos clientes con claves distintas se pisen. Hacen falta ambas defensas, cada una para su problema.

🔬 **El detalle:** La pregunta de diagnóstico es si los dos efectos tenían la misma intención. Si sí, falta identidad; si no, falta control de concurrencia.

### 2. 🟢 ¿Qué es una actualización perdida (*lost update*)?

⏱️ **30 segundos:** Dos transacciones leen el mismo valor, calculan a partir de él y escriben; la segunda escritura borra el efecto de la primera.

🗣️ **2 minutos:** En el ejemplo, veinte transacciones leyeron 5 y escribieron 4: la base aceptó cada escritura porque era válida por sí sola. No hay error ni excepción; el síntoma aparece después, como stock que no cuadra con las reservas concedidas.

🔬 **El detalle:** En PostgreSQL, *read committed* permite esta anomalía cuando el valor se calcula en la aplicación; *repeatable read* la detecta y aborta una de las transacciones con un error de serialización que hay que reintentar.

### 3. 🟢 ¿Por qué el `CHECK (available >= 0)` no saltó en la versión ingenua del ejemplo?

⏱️ **30 segundos:** Porque ningún valor escrito fue negativo: la restricción protege el número, no la regla de no vender más de lo que había.

🗣️ **2 minutos:** Cada transacción escribió un valor calculado sobre un 5 viejo, así que la base vio escrituras de 4, 3 o 2, todas válidas. La sobreventa está en la diferencia entre reservas concedidas y stock inicial, algo que ninguna fila individual refleja.

🔬 **El detalle:** Una restricción protege invariantes que caben en una fila o en una unicidad; las que dependen de cómo se sucedieron las escrituras necesitan que la comparación ocurra en la escritura misma.

### 4. 🟢 ¿Qué hace un `UPDATE ... WHERE available >= quantity` que no hace la secuencia leer, decidir y escribir?

⏱️ **30 segundos:** Hace que la base compare y reste sobre la fila bloqueada en una sola sentencia; si otra transacción ya la cambió, reevalúa la condición con el valor nuevo.

🗣️ **2 minutos:** En *read committed*, un `UPDATE` que encuentra la fila modificada por otra transacción confirmada vuelve a evaluar su `WHERE` sobre la versión nueva. Por eso nunca resta más de lo que hay. Las filas afectadas dicen si reservó, sin una segunda consulta.

🔬 **El detalle:** Solo funciona si la regla cabe en la sentencia. Una regla que depende de varias filas —límite por cliente, cupo por campaña— necesita lock explícito, restricción o aislamiento más fuerte.

### 5. 🟢 ¿Qué tres cosas une una clave de idempotencia?

⏱️ **30 segundos:** La identidad de la intención, el efecto que produjo y la respuesta que se devolvió.

🗣️ **2 minutos:** La clave dice «es la misma operación»; el efecto se aplica una sola vez; la respuesta se repite igual, incluido el rechazo. Sin respuesta guardada, el reintento no sabe qué contestar; sin unión con el efecto, puede quedar clave sin efecto o efecto sin clave.

🔬 **El detalle:** Guardar también el contenido de la petición, o su hash, es lo que permite detectar una clave reutilizada con otra intención.

### 6. 🟢 ¿Qué diferencia hay entre locking optimista y pesimista?

⏱️ **30 segundos:** El optimista deja trabajar en paralelo y detecta el conflicto al escribir; el pesimista bloquea la fila al leerla y hace esperar a los demás.

🗣️ **2 minutos:** El optimista paga reintentos cuando hay conflicto y nada cuando no lo hay; el pesimista paga espera siempre, pero no tira trabajo. Con poca contención gana el optimista; con una fila muy disputada, los reintentos pueden costar más que la espera.

🔬 **El detalle:** El `UPDATE` condicional es una tercera vía para reglas simples: sin versión ni `FOR UPDATE`, la base serializa sobre la fila solo mientras dura la sentencia.

### 7. 🟡 ¿Por qué un mutex dentro del proceso no evita la sobreventa cuando hay varias réplicas?

⏱️ **30 segundos:** Porque cada réplica tiene su propio mutex, y la fila está en la base que comparten todas.

🗣️ **2 minutos:** El mutex serializa hilos de un proceso; dos réplicas lo ejecutan en paralelo sin saberlo. Incluso con una sola réplica, solo protege mientras nadie más escriba esa fila, y un job o el backoffice lo harán. La defensa tiene que estar donde está el dato.

🔬 **El detalle:** Un lock distribuido, por ejemplo en Redis, reintroduce el problema con más piezas: lease, expiración y una réplica que cree seguir teniendo el lock.

### 8. 🟡 ¿Cuándo elegirías serializar la partición caliente con una cola por SKU en lugar de competir por la fila?

⏱️ **30 segundos:** Cuando un SKU concentra tanta contención que los conflictos o esperas dominan la latencia, y negocio acepta confirmar la reserva unos instantes después.

🗣️ **2 minutos:** Una cola por SKU convierte competencia en orden: un solo consumidor aplica las reservas de esa partición. Se gana previsibilidad en el pico y se paga latencia, un consumidor que operar y un estado pendiente visible. No elimina la idempotencia —la cola puede entregar dos veces— ni la restricción de base.

🔬 **El detalle:** Si solo uno o dos SKU se calientan durante una campaña, la cola puede limitarse a ellos y el resto seguir con el `UPDATE` condicional.

### 9. 🟡 ¿Qué evidencia distinguiría una sobreventa por carrera de una por ajustes manuales de stock?

⏱️ **30 segundos:** El historial de movimientos: si las unidades de más corresponden a reservas concurrentes sin otro escritor, es carrera; si coinciden con escrituras del backoffice, es un ajuste.

🗣️ **2 minutos:** Comparo la suma de reservas con los movimientos de stock en la ventana del incidente. Las carreras dejan marcas de tiempo muy próximas y ningún otro actor; los ajustes dejan usuario y hora. Sin tabla de movimientos solo hay un valor final, y eso no distingue causas.

🔬 **El detalle:** Por eso un libro de movimientos, aunque sea de auditoría, es una buena inversión en inventario: separa «cuánto hay» de «cómo se llegó ahí».

### 10. 🟡 ¿Por qué la misma clave con otro contenido debe rechazarse en lugar de devolver el resultado guardado?

⏱️ **30 segundos:** Porque es otra intención con una clave reutilizada; devolver el resultado anterior le diría al cliente que se aplicó algo que no pidió.

🗣️ **2 minutos:** Si `K-1` reservó una unidad y llega `K-1` pidiendo dos, devolver `RESERVED` hace creer al cliente que tiene dos. Rechazarla con un error explícito saca a la luz el defecto del cliente —claves repetidas entre operaciones— en lugar de esconderlo.

🔬 **El detalle:** HTTP no define ese caso; el borrador del IETF sobre la cabecera `Idempotency-Key` propone responder con un error, no con la respuesta anterior.

### 11. 🟡 ¿Por qué `OUT_OF_STOCK` también se guarda como respuesta de la clave?

⏱️ **30 segundos:** Porque el rechazo también es la respuesta a esa intención; si no se guarda, un reintento podría reservar si mientras tanto entró stock.

🗣️ **2 minutos:** El cliente preguntó una vez y recibió «sin stock». Si el reintento de la misma petición devuelve «reservado» porque hubo reposición, el cliente ve dos respuestas distintas a la misma pregunta. Guardar el rechazo hace estable la operación; quien quiere volver a intentar, usa una clave nueva.

🔬 **El detalle:** Los errores transitorios —timeout de base, conexión caída— no se guardan como respuesta: no son un resultado de negocio y el reintento debe ejecutarse.

### 12. 🟡 ¿Qué le pasa a un duplicado concurrente mientras sigue abierta la primera transacción que reclamó la clave?

⏱️ **30 segundos:** Espera en el índice único hasta que la primera transacción confirma o hace rollback.

🗣️ **2 minutos:** En PostgreSQL, el `INSERT ... ON CONFLICT DO NOTHING` del duplicado se bloquea sobre la clave sin confirmar. Si la primera confirma, el duplicado no inserta y lee la respuesta ya guardada; nunca ve `IN_PROGRESS`. El precio es que tarda lo que tarde la primera.

🔬 **El detalle:** Si el efecto fuera largo, esa espera sería un problema; entonces conviene confirmar `IN_PROGRESS` aparte y responder «en curso» al duplicado, a cambio de gestionar claves huérfanas.

### 13. 🟡 ¿Qué ocurre con la clave si la primera transacción hace rollback, y por qué es la conducta correcta?

⏱️ **30 segundos:** Desaparece con el rollback, y el duplicado que esperaba ejecuta la reserva como si fuera el primero.

🗣️ **2 minutos:** Si el primer intento falló por un error transitorio, el reintento debe poder hacer la operación. Una clave que sobreviviera al fallo bloquearía para siempre esa intención con un estado sin respuesta. Se comprobó en PostgreSQL 17: el duplicado esperó 1,7 s y, tras el rollback, insertó su clave.

🔬 **El detalle:** Esto vale porque clave y efecto comparten transacción. Si la clave se guardara en otra, el rollback del efecto la dejaría huérfana.

### 14. 🟡 ¿Cuándo es un error reintentar automáticamente un conflicto de versión?

⏱️ **30 segundos:** Cuando el reintento repetiría un efecto externo ya ocurrido, o cuando no tiene límite ni espera.

🗣️ **2 minutos:** Reintentar es seguro si se vuelve a ejecutar la transacción completa y todo su efecto es local. Si antes del conflicto se llamó a un proveedor o se publicó un mensaje, el reintento lo duplica. Y sin límite ni jitter, bajo contención alta todos reintentan a la vez y vuelven a chocar.

🔬 **El detalle:** Un patrón razonable: pocos reintentos con jitter y, si se agotan, un error explícito o el paso a una cola para esa partición.

### 15. 🟡 ¿Qué contención medirías para elegir entre locking optimista y pesimista?

⏱️ **30 segundos:** La tasa de conflictos de versión o de esperas de lock por fila, y la latencia que añaden en el percentil alto.

🗣️ **2 minutos:** Si menos del uno por ciento de las reservas choca, el optimista casi no cuesta; si un SKU choca en una de cada tres, los reintentos multiplican trabajo y el pesimista, o la cola, pueden salir más baratos. Se mide por partición caliente, no en promedio: el promedio esconde el SKU de la campaña.

🔬 **El detalle:** `pg_locks` y `pg_stat_activity` muestran las esperas; los conflictos de versión hay que contarlos en la aplicación, porque para la base son actualizaciones que afectaron cero filas.

### 16. 🟡 ¿Cuánto tiempo conservarías las claves de idempotencia y de qué depende?

⏱️ **30 segundos:** Al menos la ventana en que un cliente real puede reintentar, con margen; depende del cliente y del efecto.

🗣️ **2 minutos:** Si el cliente reintenta durante minutos, 24 horas suele sobrar; si hay procesos por lotes que reenvían al día siguiente, hace falta más. Pasada la ventana, una clave vieja se trata como nueva, así que la retención cubre el peor reintento real, no el típico.

🔬 **El detalle:** Sin purga, la tabla crece sin límite; la purga es un job con índice por fecha, y la ventana se publica en el contrato de la API.

### 17. 🟡 ¿Qué diferencia operativa hay entre una versión JPA y comprobar filas afectadas con `sql.Tx` en Go?

⏱️ **30 segundos:** Con `@Version`, JPA añade la versión al `WHERE` y lanza una excepción si no afectó filas; en Go, el código lee `RowsAffected` y decide él.

🗣️ **2 minutos:** JPA convierte el conflicto en `OptimisticLockException` al hacer flush, a menudo lejos de la línea que lo causó, y la transacción queda marcada para rollback. En Go el conflicto es un número que hay que mirar; si se olvida, el fallo pasa en silencio. Uno esconde el mecanismo; el otro lo deja olvidable.

🔬 **El detalle:** En los dos, el conflicto solo existe si la sentencia lleva la condición: un `UPDATE` nativo sin ella salta el control de versión.

### 18. 🟠 ¿Por qué el event loop de Node y el GIL de Python no reemplazan una restricción única compartida?

⏱️ **30 segundos:** Porque ambos serializan solo dentro de un proceso, y la restricción vive en la base que comparten todos.

🗣️ **2 minutos:** El event loop ejecuta un callback a la vez, pero entre el `await` de la lectura y el de la escritura atiende otras peticiones: la carrera cabe en ese hueco. El GIL impide que dos hilos ejecuten bytecode a la vez, no que dos procesos o dos réplicas escriban la misma fila. Solo la restricción en la base los ve a todos.

🔬 **El detalle:** En Node la carrera es fácil de pasar por alto porque el código parece secuencial; cada `await` es un punto donde otra petición puede entrar.

### 19. 🟠 El cliente reintenta un cobro tras un timeout y el proveedor no acepta claves de idempotencia. ¿Qué garantía puedes ofrecer y cuál no?

⏱️ **30 segundos:** Puedo garantizar que mi lado no inicia un segundo cobro por la misma intención; no puedo garantizar que el proveedor no haya cobrado ya si el timeout ocurrió después de cobrar.

🗣️ **2 minutos:** Registro la intención con mi clave antes de llamar y, ante timeout, no repito: consulto el estado por mi referencia si el proveedor lo permite, o dejo el pago en revisión. Si no hay ni idempotencia ni consulta, la automatización se limita y el riesgo se nombra ante negocio.

🔬 **El detalle:** Es el escenario de fallos parciales del bloque 04: la idempotencia local no se extiende sola a otro sistema.

### 20. 🟠 Tras escalar a tres réplicas aparecen conflictos de versión en el 30 % de las reservas de un SKU. ¿Qué harías primero?

⏱️ **30 segundos:** Medir si los conflictos se concentran en ese SKU y en qué escritura, antes de cambiar de mecanismo.

🗣️ **2 minutos:** Un 30 % de conflictos es trabajo tirado y latencia. Confirmo si vienen de la reserva o de otra escritura sobre la misma fila, como un contador de vistas. Si es la reserva, pruebo un `UPDATE` condicional sin versión; si persiste, una cola solo para ese SKU. Cada paso se puede revertir.

🔬 **El detalle:** Mezclar en una fila datos que cambian por motivos distintos —stock y estadísticas— crea contención artificial; separarlos a veces resuelve más que cambiar el lock.

### 21. 🟠 Aparece un deadlock al reservar pedidos de varias líneas. ¿Cuál es la causa típica y cómo la corregirías sin subir el aislamiento?

⏱️ **30 segundos:** Dos pedidos bloquean las mismas filas en orden distinto; se corrige reservando siempre en un orden fijo, por ejemplo por SKU.

🗣️ **2 minutos:** El pedido A reserva `SKU-001` y luego `SKU-003`; B, al revés; cada uno espera al otro y la base aborta uno. Ordenando las líneas por SKU antes de reservar, todos adquieren los locks en la misma secuencia y el ciclo desaparece. El abortado se puede reintentar una vez si su efecto es local.

🔬 **El detalle:** Subir el aislamiento no elimina deadlocks y suele aumentar los abortos. El orden de adquisición es la corrección barata.

### 22. 🟠 Quieres añadir la tabla de claves a un flujo que ya está en producción. ¿Qué despliegue reversible harías?

⏱️ **30 segundos:** Primero la tabla y el registro de claves sin usarlas para decidir; después, observar; y al final activar la respuesta guardada con una feature flag.

🗣️ **2 minutos:** Paso uno: migración aditiva que crea la tabla. Paso dos: registrar claves y respuestas sin cortar duplicados, midiendo cuántos llegan. Paso tres: devolver la respuesta guardada para una cohorte. Si algo falla, se apaga la flag y el flujo vuelve al anterior sin perder datos.

🔬 **El detalle:** La cabecera que envía el cliente también es contrato: quien no la envía necesita un comportamiento definido, no un error repentino.

### 23. 🟠 Dos equipos discrepan: uno quiere `SELECT ... FOR UPDATE` en toda reserva y otro solo `UPDATE` condicional. ¿Cómo decidirías?

⏱️ **30 segundos:** Con la regla y la contención: si la reserva cabe en una sentencia, el condicional basta; `FOR UPDATE` se justifica cuando la decisión necesita leer datos que la sentencia no ve.

🗣️ **2 minutos:** `FOR UPDATE` en toda reserva retiene el lock durante la lógica de la aplicación, y cualquier espera dentro de la transacción la paga todo el SKU. El condicional lo retiene solo durante la sentencia. Pido un caso real que el condicional no cubra; si aparece, uso `FOR UPDATE` solo en ese camino.

🔬 **El detalle:** Los dos equipos suelen defender lo mismo —no sobrevender—; lo que discuten es cuánto tiempo aceptan tener la fila bloqueada.

### 24. 🟠 ¿Qué criterio te diría que no hace falta una cola por SKU?

⏱️ **30 segundos:** Que el `UPDATE` condicional mantenga conflictos y latencia del SKU más caliente dentro del objetivo en el pico medido.

🗣️ **2 minutos:** Una cola solo compra orden bajo contención extrema, y cobra latencia, un consumidor y un estado pendiente. Si el pico de la última campaña se sirvió sin sobreventa ni latencia inaceptable, no hay nada que comprar. Lo documento con la cifra medida y lo reviso antes de la siguiente campaña grande.

🔬 **El detalle:** El criterio se expresa con un percentil y una fecha de revisión, no con «por ahora aguanta».

## 📖 03 — Eventos internos, jobs y procesamiento asíncrono

### 1. 🟢 ¿Qué diferencia hay entre separar el tiempo de un trabajo y conservarlo?

⏱️ **30 segundos:** Separar el tiempo es que el trabajo ocurra después de responder; conservarlo es que sobreviva si el proceso cae antes de hacerlo. Un hilo o una promesa hacen lo primero; solo un almacenamiento durable hace lo segundo.

🗣️ **2 minutos:** `@Async`, `setImmediate`, una goroutine o un `submit` sacan el correo del camino de la respuesta y bajan la latencia. Pero el trabajo sigue en la memoria del proceso, y un despliegue lo borra. Para conservarlo, tiene que ser una fila confirmada junto con el pedido.

🔬 **El detalle:** «Lo hicimos asíncrono» no responde a «¿qué pasa si el proceso muere?». Son dos preguntas con dos mecanismos.

### 2. 🟢 ¿Qué garantía da un evento en memoria y cuándo basta?

⏱️ **30 segundos:** Que los observadores del mismo proceso se enteran mientras el proceso vive. Basta cuando perder el efecto es aceptable, como una métrica o una caché que se reconstruye.

🗣️ **2 minutos:** Es barato y no necesita infraestructura, pero no sobrevive a una caída, no reintenta y no deja rastro. Para un aviso al cliente, una factura o una reserva, no basta.

🔬 **El detalle:** Un evento en memoria publicado tras el commit sigue siendo útil para desacoplar código dentro del monolito; lo que no aporta es durabilidad.

### 3. 🟢 ¿Por qué el trabajo obligatorio se escribe en la misma transacción que el cambio de negocio?

⏱️ **30 segundos:** Porque así el trabajo existe si y solo si el cambio se confirmó: ni avisos de pedidos que no existen, ni pedidos sin aviso.

🗣️ **2 minutos:** Escrito antes y con rollback del pedido, habría un aviso de algo que no ocurrió; escrito después en otra transacción, una caída entre ambas lo pierde. En el mismo `COMMIT`, la base garantiza las dos cosas a la vez. Es el principio del outbox, sin broker.

🔬 **El detalle:** Solo funciona si la tabla de trabajo está en la misma base que el pedido; en otro almacén vuelve el problema de las dos escrituras.

### 4. 🟢 ¿Qué es un lease y qué problema resuelve en una tabla de trabajo?

⏱️ **30 segundos:** Un plazo durante el cual un worker tiene el trabajo reclamado; si vence sin completarlo, otro puede reclamarlo.

🗣️ **2 minutos:** Sin lease, un trabajo marcado «en curso» por un worker que murió queda bloqueado para siempre. Con lease, la muerte del worker se convierte en un retraso acotado. En el ejemplo, el worker B no pudo reclamar mientras el lease estaba vigente y lo hizo al vencer.

🔬 **El detalle:** El lease no sabe si el worker murió o solo va lento; por eso su vencimiento puede provocar dos ejecuciones simultáneas, y el efecto debe tolerarlo.

### 5. 🟢 ¿Qué significa *at-least-once* y por qué obliga a deduplicar el efecto?

⏱️ **30 segundos:** Que cada trabajo se ejecuta al menos una vez, quizá más; como no hay garantía de una sola vez, el efecto debe aceptar repeticiones.

🗣️ **2 minutos:** Una tabla con lease, un broker o un reintento HTTP entregan *at-least-once*: un fallo entre «hice el efecto» y «marqué hecho» provoca otra ejecución. La deduplicación va en el efecto, con la clave del trabajo, o en un registro de trabajos ya aplicados del consumidor.

🔬 **El detalle:** *Exactly-once* de extremo a extremo no lo da ningún mecanismo de entrega; se obtiene como *at-least-once* más un efecto idempotente.

### 6. 🟢 ¿Qué es *backpressure* y dónde aparece en un worker interno?

⏱️ **30 segundos:** La capacidad de frenar a quien produce cuando quien consume no da abasto; en un worker aparece como límite de concurrencia y de cola.

🗣️ **2 minutos:** Si el proveedor de correo se satura, un worker sin límite lanza más intentos y empeora la caída; una cola interna sin tope acumula tareas hasta agotar memoria. Con backpressure, el worker procesa a un ritmo fijo, la tabla crece de forma visible y los productores pueden rechazar o degradar.

🔬 **El detalle:** Con una tabla de trabajo, la presión se ve como edad del trabajo pendiente más antiguo, que es la métrica que conviene alertar.

### 7. 🟡 ¿Por qué publicar un evento antes del commit es peligroso aunque el consumidor esté en el mismo proceso?

⏱️ **30 segundos:** Porque el consumidor actúa sobre un cambio que todavía puede hacer rollback, y entonces actuó sobre algo que no ocurrió.

🗣️ **2 minutos:** Si el listener lee el pedido, puede no encontrarlo aún; si envía el correo, confirma al cliente un pedido que la base terminó descartando. Compartir proceso no cambia nada: el commit es una frontera de la base, no del proceso. Se publica tras el commit o se escribe el trabajo en la transacción.

🔬 **El detalle:** Spring ofrece `@TransactionalEventListener` para publicar tras el commit; en otras plataformas hay que hacerlo explícito después de confirmar.

### 8. 🟡 ¿Cuándo elegirías un evento en memoria aunque ya exista una tabla de trabajo?

⏱️ **30 segundos:** Cuando el efecto es prescindible o reconstruible, como invalidar una caché local o registrar una métrica.

🗣️ **2 minutos:** Una fila y un worker para cada efecto trivial añaden carga, operación y latencia. Si perder el efecto no deja a nadie sin algo prometido, el evento en memoria tras el commit es la respuesta proporcional. El criterio es la consecuencia de perderlo, no la importancia del módulo.

🔬 **El detalle:** La misma acción puede cambiar de categoría: una caché que se reconstruye sola es prescindible; un contador que se factura, no.

### 9. 🟡 En el ejemplo de Python, el worker A envió el aviso y murió. ¿Por qué el cliente recibió un solo aviso y qué lo habría duplicado?

⏱️ **30 segundos:** Porque el efecto deduplica por la clave del trabajo: el segundo intento chocó con la clave e `INSERT OR IGNORE` no creó otro aviso. Sin esa clave, habría habido dos.

🗣️ **2 minutos:** A envió y murió antes de `complete`; para la tabla, el trabajo seguía reclamado. Al vencer el lease, B lo reclamó —`attempts = 2`— y ejecutó otra vez el efecto. La tabla evitó la pérdida; la clave, el duplicado. Si el canal real no acepta una clave equivalente, el cliente recibe dos correos.

🔬 **El detalle:** Invertir el orden —marcar hecho y después enviar— cambia el riesgo de duplicar por el de perder; para un aviso, duplicar suele ser el mal menor.

### 10. 🟡 ¿Cómo elegirías la duración del lease?

⏱️ **30 segundos:** Más larga que la duración normal del trabajo con margen, y lo bastante corta para que un worker muerto no retrase demasiado la recuperación.

🗣️ **2 minutos:** Si enviar un correo tarda 2 s en el p99, un lease de 30 s tolera lentitud sin reclamos dobles y recupera un worker muerto en medio minuto. Si el trabajo es largo, el worker renueva el lease mientras avanza. Un lease más corto que el p99 garantiza ejecuciones dobles.

🔬 **El detalle:** La renovación también puede fallar; un worker que pierde su lease debe dejar de escribir resultados, o el trabajo termina con dos dueños.

### 11. 🟡 ¿Qué es un trabajo venenoso y cómo evitas que bloquee la cola?

⏱️ **30 segundos:** Un trabajo que falla siempre, por ejemplo por datos inválidos; se evita con un máximo de intentos y un estado final de fallo que lo saca de la cola.

🗣️ **2 minutos:** Sin límite, se reclama y falla para siempre, consume capacidad y, si la cola es ordenada, bloquea lo que viene detrás. Con máximo de intentos y backoff pasa a `FAILED` con el último error, se alerta y alguien lo corrige o lo descarta.

🔬 **El detalle:** Distinguir errores transitorios de permanentes ahorra intentos: un 400 del proveedor no mejora reintentando; un 503, quizá sí.

### 12. 🟡 ¿Qué orden necesita realmente el sistema de ejemplo y por qué no conviene un orden global?

⏱️ **30 segundos:** Orden por pedido: los avisos de un mismo pedido respetan su secuencia; entre pedidos distintos no importa.

🗣️ **2 minutos:** Un orden global exige un solo consumidor y convierte cualquier trabajo lento en un bloqueo para todos. El orden por pedido se consigue procesando en secuencia los trabajos de un mismo `order_id` y en paralelo los de pedidos distintos.

🔬 **El detalle:** Los reintentos rompen el orden si un trabajo falla y el siguiente del mismo pedido avanza; ordenar por clave implica no reclamar el siguiente hasta resolver el anterior.

### 13. 🟡 ¿Qué métricas dicen si el worker va al día?

⏱️ **30 segundos:** La edad del trabajo pendiente más antiguo, la cantidad pendiente y la tasa de fallos por tipo de trabajo.

🗣️ **2 minutos:** La cantidad sola engaña: mil trabajos recién creados son normales; diez de hace una hora, no. La edad del más antiguo mide el retraso que siente el cliente. Los fallos por tipo separan un proveedor caído de un defecto en un tipo concreto de trabajo.

🔬 **El detalle:** Alertar por edad, no por cantidad, evita alarmas en picos legítimos y detecta un worker detenido aunque la cola sea pequeña.

### 14. 🟡 ¿Qué cambia cuando dos réplicas ejecutan el mismo worker sobre la tabla?

⏱️ **30 segundos:** Que ambas pueden reclamar a la vez, así que el reclamo tiene que ser atómico en la base y el efecto tolerar la repetición.

🗣️ **2 minutos:** Con un `SELECT` y después un `UPDATE` separados, las dos réplicas pueden tomar el mismo trabajo. Un único `UPDATE ... RETURNING`, o `FOR UPDATE SKIP LOCKED` en PostgreSQL, da un dueño a cada trabajo. Dos réplicas también duplican capacidad, y hay que revisar el límite contra el proveedor.

🔬 **El detalle:** SQLite serializa escrituras y en el ejemplo el reclamo es atómico sin más; en PostgreSQL, sin `SKIP LOCKED`, los workers esperarían sobre la misma fila en lugar de tomar la siguiente.

### 15. 🟡 ¿Cuándo introducirías un broker con outbox en lugar de la tabla de trabajo?

⏱️ **30 segundos:** Cuando otros procesos o equipos necesitan consumir el hecho, o cuando el volumen y el fan-out superan lo que la base puede servir como cola.

🗣️ **2 minutos:** Un broker compra consumidores independientes, retención, reproducción y escala propia; cuesta infraestructura, contratos de eventos y operación. Con outbox, la publicación sigue naciendo en la misma transacción. Si el único consumidor es el propio monolito, la tabla da la misma garantía con menos piezas.

🔬 **El detalle:** La tabla de trabajo suele ser el primer paso hacia un outbox: la misma fila, con un publicador en lugar de un worker.

### 16. 🟡 ¿Qué debe ver el cliente mientras el aviso está pendiente o fallando?

⏱️ **30 segundos:** Un estado honesto: el pedido está confirmado y el aviso va en camino; si falla de forma persistente, alguien lo sabe y puede reenviarlo.

🗣️ **2 minutos:** El cliente no necesita el detalle del worker, pero tampoco un «error» cuando el pedido está bien. La vista del pedido lee el estado de la notificación de la tabla de trabajo. Si llega a `FAILED`, soporte ve el motivo y puede reintentar.

🔬 **El detalle:** Exponer ese estado evita la peor reacción: que el cliente repita la compra porque no le llegó el correo.

### 17. 🟡 ¿Qué garantía comparten un executor Java y una goroutine, y cuál requiere almacenamiento adicional?

⏱️ **30 segundos:** Comparten que el trabajo corre en paralelo o después de responder; ninguno lo conserva si el proceso cae, y esa garantía requiere almacenamiento.

🗣️ **2 minutos:** Un `Executor` encola la tarea en memoria; una goroutine es una función en ejecución en memoria. Los dos separan el tiempo y los dos pierden el trabajo en un despliegue. La durabilidad se añade escribiendo el trabajo en la base antes del commit, y dejando que el executor o las goroutines solo lo procesen.

🔬 **El detalle:** Ambos necesitan además límite: pool con cola acotada en Java, número fijo de workers o semáforo en Go.

### 18. 🟠 ¿Por qué omitir `await` en Node y hacer `submit` en Python no equivalen a entrega durable?

⏱️ **30 segundos:** Porque los dos dejan el trabajo en la memoria del proceso; si el proceso termina, el trabajo desaparece sin rastro.

🗣️ **2 minutos:** Sin `await`, la promesa sigue viva solo en el event loop: el ejemplo mostró que un `exit` tras responder elimina el aviso. `submit` deja la tarea en la cola del executor, que muere con el intérprete. Ninguno escribe nada en un lugar que sobreviva.

🔬 **El detalle:** En Node actual, además, una promesa rechazada que nadie maneja termina el proceso por defecto: el fire-and-forget puede tumbar lo que intentaba no bloquear.

### 19. 🟠 Tras un despliegue, 140 pedidos confirmados no tienen aviso ni fila de trabajo. ¿Qué investigas y qué cambias?

⏱️ **30 segundos:** Sin fila de trabajo, el trabajo nunca fue durable: busco dónde se lanza el aviso y si esos pedidos coinciden con los reinicios del despliegue.

🗣️ **2 minutos:** Cruzo la hora de creación con los reinicios: si todos caen en los segundos previos, el aviso vivía en memoria. Lo inmediato es reenviar a esos 140 desde una consulta; lo estructural, escribir el trabajo en la transacción. También reviso el apagado ordenado: drenar antes de terminar reduce pérdidas, pero no las elimina.

🔬 **El detalle:** El reenvío debe usar la misma clave que usará el worker, o el día que ambos convivan habrá duplicados.

### 20. 🟠 El proveedor de correo cae dos horas y la tabla acumula 30 000 trabajos. ¿Qué hace el worker durante la caída y qué pasa al volver?

⏱️ **30 segundos:** Durante la caída reintenta con backoff y concurrencia limitada sin tumbar nada; al volver, drena a un ritmo que el proveedor tolere.

🗣️ **2 minutos:** Los trabajos fallan de forma transitoria y se reprograman con espera creciente; la edad del pendiente más antiguo sube y alerta. Al volver, lanzar los 30 000 de golpe provoca un segundo corte por límite de tasa, así que el worker mantiene su ritmo. Los avisos muy viejos pueden no tener sentido: se decide si se envían o se descartan.

🔬 **El detalle:** Un circuit breaker evita gastar intentos mientras el proveedor sigue caído, pero su reapertura debe probar con poco tráfico.

### 21. 🟠 Un job programado se ejecuta dos veces al escalar a dos réplicas. ¿Cómo lo corriges sin volver a una sola réplica?

⏱️ **30 segundos:** Haciendo que la ejecución se reclame en la base —una fila por ejecución con unicidad, o un lock con lease— en lugar de confiar en que solo una réplica corre el scheduler.

🗣️ **2 minutos:** Cada réplica tiene su scheduler y ambas disparan a la misma hora. Una fila «ejecución de las 02:00» con restricción única deja pasar solo a una; un lock en la base con lease, como un *advisory lock* de PostgreSQL, también. El efecto del job debe tolerar dos ejecuciones por si el lease vence.

🔬 **El detalle:** Hay librerías que implementan este patrón en cada ecosistema; lo importante es que el reclamo viva en un almacén compartido, no en la réplica.

### 22. 🟠 Quieres reemplazar el envío en memoria por la tabla de trabajo sin perder avisos durante la transición. ¿Qué pasos reversibles darías?

⏱️ **30 segundos:** Escribir la fila de trabajo además del envío actual, con la misma clave, y apagar el envío en memoria cuando la tabla demuestre que no pierde nada.

🗣️ **2 minutos:** Paso uno: la transacción escribe la fila y el envío en memoria sigue; el efecto deduplica por clave, así que el worker no repite lo ya enviado. Paso dos: comparar avisos por ambos caminos. Paso tres: apagar el envío en memoria con una flag. En cualquier paso se puede volver atrás sin perder avisos.

🔬 **El detalle:** Durante la convivencia, la clave compartida es lo que evita dos correos: sin ella, la transición duplica en lugar de perder.

### 23. 🟠 Un equipo quiere Kafka para las notificaciones y otro defiende la tabla de trabajo. ¿Cómo decidirías?

⏱️ **30 segundos:** Con quién consume y cuánto volumen hay: si solo el monolito consume y la base aguanta, la tabla da la garantía con menos piezas; Kafka se justifica si otros equipos o procesos necesitan el hecho.

🗣️ **2 minutos:** Pregunto qué compra Kafka aquí: consumidores independientes, retención, reproducción, escala. Si nada de eso existe, añade un clúster, contratos de eventos y un outbox que igual hace falta. Si existe, la tabla actual se convierte en outbox y el cambio es incremental.

🔬 **El detalle:** Kafka no elimina la tabla: sin outbox, publicar en Kafka y confirmar en la base vuelven a ser dos escrituras.

### 24. 🟠 ¿Qué criterio te diría que la tabla de trabajo ya no alcanza?

⏱️ **30 segundos:** Que la tabla compita con el tráfico transaccional de la base, o que aparezcan consumidores fuera del monolito que necesitan el hecho.

🗣️ **2 minutos:** Señales: el polling de los workers se nota en la carga de la base, la tabla crece más rápido de lo que se purga, o su mantenimiento degrada otras consultas. También un segundo proceso que necesita los mismos eventos. Antes de cambiar, pruebo índices parciales, lotes más grandes y purga.

🔬 **El detalle:** El criterio se escribe con cifras —trabajos por segundo, edad máxima, carga de la base— para que el paso a un broker sea una decisión medida.

## 📖 04 — Rendimiento, caché y escalado

### 1. 🟢 ¿Qué diferencia hay entre latencia, throughput y saturación?

⏱️ **30 segundos:** Latencia es cuánto tarda una petición; throughput, cuántas se completan por unidad de tiempo; saturación, cuánto de un recurso está ocupado o en cola.

🗣️ **2 minutos:** Las tres se mueven juntas pero no igual: al acercarse a la saturación de un recurso, el throughput deja de crecer y la latencia se dispara porque aparecen colas. Por eso la saturación de pools, CPU o disco es la señal que anticipa el problema, y la latencia es la que lo confirma.

🔬 **El detalle:** Mirar solo throughput engaña: un sistema saturado puede mantenerlo mientras la latencia de cola crece sin que nadie lo vea en el promedio.

### 2. 🟢 ¿Por qué el SLO de checkout se mide en el borde del usuario y no por módulo?

⏱️ **30 segundos:** Porque el usuario sufre la suma: un módulo dentro de su objetivo no garantiza que el flujo lo esté.

🗣️ **2 minutos:** El SLO dice qué promete el sistema; las métricas internas explican quién consume el presupuesto. Medir por módulo sin el total permite que cada equipo cumpla su parte y checkout siga incumpliendo por esperas entre etapas, colas o reintentos que no pertenecen a nadie.

🔬 **El detalle:** Las métricas por módulo sirven para atribuir, no para prometer; confundirlas lleva a optimizar una etapa que no era el cuello.

### 3. 🟢 ¿Qué indica una CPU baja con latencia alta?

⏱️ **30 segundos:** Que la petición pasa el tiempo esperando: pool, lock, consulta lenta, disco o una dependencia externa.

🗣️ **2 minutos:** Si el proceso no está calculando, añadir réplicas o CPU no ayuda. La traza por etapa dice dónde está la espera: «esperando conexión» apunta al pool; una consulta larga, al plan o a un índice; un tramo HTTP, a la dependencia. Cada una tiene su corrección.

🔬 **El detalle:** Un perfil de CPU en ese estado muestra un proceso tranquilo y no explica nada; el perfil útil es de esperas o de bloqueos.

### 4. 🟢 ¿Qué necesita una caché para no servir datos equivocados?

⏱️ **30 segundos:** Un dueño, una clave que identifique el dato, una política de TTL o invalidación, y una conducta definida ante un fallo de la caché.

🗣️ **2 minutos:** El dueño decide cuándo el dato cambió; la clave evita mezclar variantes, como precio por región; el TTL o la invalidación acotan la obsolescencia; y el comportamiento ante fallo decide si se va a la base o se degrada. Sin esas cuatro, la caché es una copia que nadie mantiene.

🔬 **El detalle:** Lo más difícil no es llenar la caché sino invalidarla: cada escritura del dueño tiene que saber qué claves afecta.

### 5. 🟢 ¿Qué hace falta para que un monolito pueda replicarse horizontalmente?

⏱️ **30 segundos:** Que no guarde estado de usuario en memoria local, que sus jobs no se ejecuten dos veces y que la base aguante la suma de pools.

🗣️ **2 minutos:** Sesiones en memoria obligan a afinidad o se pierden; un scheduler en cada réplica duplica jobs; y cada réplica multiplica conexiones. Resuelto eso —sesión en un almacén compartido, jobs reclamados en la base, pools dimensionados—, replicar el mismo artefacto es la forma más barata de sumar cómputo.

🔬 **El detalle:** Replicar un monolito no exige partirlo: es el mismo artefacto detrás de un balanceador, con los mismos límites internos.

### 6. 🟢 ¿Qué relación hay entre throughput, tiempo de uso de una conexión y tamaño del pool?

⏱️ **30 segundos:** Conexiones ocupadas ≈ peticiones por segundo × segundos que cada petición retiene la conexión.

🗣️ **2 minutos:** Con 200 peticiones por segundo que retienen la conexión 50 ms, bastan unas 10 conexiones; si la retienen 500 ms, hacen falta 100. Reducir el tiempo de uso —transacciones cortas, sin red dentro— libera capacidad sin tocar el pool ni la base.

🔬 **El detalle:** Es la ley de Little aplicada al pool. Agrandar el pool sin reducir el tiempo de uso solo traslada la cola a la base.

### 7. 🟡 ¿Por qué extraer `inventory` sin medir la dependencia es una simplificación peligrosa?

⏱️ **30 segundos:** Porque si el cuello es la consulta o la base que usa `inventory`, el servicio extraído la sigue usando y añade red delante.

🗣️ **2 minutos:** La extracción cambia la topología, no el recurso: misma tabla, mismo índice ausente, misma base. Se suman serialización, una llamada remota y un despliegue más. La medición previa dice si el recurso limitante se separa con el módulo; si no se separa, la extracción empeora el SLO.

🔬 **El detalle:** Extraer puede ser correcto cuando el módulo tiene un recurso propio que compite con los demás, por ejemplo CPU aislable; eso también se demuestra midiendo.

### 8. 🟡 ¿Cuándo preferirías escalar verticalmente antes que añadir réplicas?

⏱️ **30 segundos:** Cuando el límite es memoria o CPU de un proceso y replicar multiplicaría conexiones contra una base ya ajustada.

🗣️ **2 minutos:** Una máquina más grande no abre más pools, no requiere sesión compartida y no cambia la coordinación de jobs. Tiene techo y un único punto de fallo, pero es el cambio más reversible para ganar margen mientras se optimiza. Las réplicas añaden disponibilidad además de capacidad.

🔬 **El detalle:** Si el proceso no aprovecha más núcleos —por un cuello interno o un runtime de un hilo—, el escalado vertical no sirve y la medición lo mostrará.

### 9. 🟡 Al pasar de 4 a 8 réplicas, el p99 empeora. ¿Qué explicación comprobarías primero?

⏱️ **30 segundos:** Que las réplicas nuevas multiplicaron conexiones contra la base y la saturaron: más esperas de pool, más contención de locks y rechazos.

🗣️ **2 minutos:** Miro conexiones activas en la base frente a `max_connections`, esperas en el pool de cada réplica y locks. Si la base es el límite, más réplicas solo añaden competidores. La corrección es reducir el tiempo de uso o poner un límite de concurrencia, y volver a las réplicas que hagan falta.

🔬 **El detalle:** Un pooler delante de la base, como PgBouncer, multiplexa conexiones, pero no crea capacidad de CPU ni elimina locks en la base.

### 10. 🟡 ¿Por qué cachear el stock para decidir una reserva rompe la invariante y cachear el catálogo no?

⏱️ **30 segundos:** Porque la reserva necesita el valor actual para no sobrevender, y el catálogo tolera unos segundos de obsolescencia sin romper ninguna promesa.

🗣️ **2 minutos:** Una caché de stock con 30 s de retraso puede decir «hay 3» cuando ya no queda ninguno. Para mostrar disponibilidad aproximada sirve; para decidir, la reserva tiene que ir a la fila con su `UPDATE` condicional. El catálogo —nombre, descripción, imagen— cambia poco y un dato viejo no crea un efecto erróneo.

🔬 **El detalle:** El precio está en medio: mostrar un precio viejo es tolerable si el cobro usa el precio vigente y el cliente ve la diferencia antes de pagar.

### 11. 🟡 ¿Qué es un read model y qué precio tiene frente a optimizar la consulta original?

⏱️ **30 segundos:** Una estructura de lectura precalculada para una consulta concreta; su precio es mantenerla sincronizada y aceptar que va algo retrasada.

🗣️ **2 minutos:** Optimizar la consulta —índice, plan, paginación— mantiene una sola fuente de verdad sin retraso. El read model sirve cuando la consulta es intrínsecamente cara, por ejemplo agregaciones sobre muchas filas. Cuesta una proyección que actualizar, su reconstrucción ante errores y su frescura visible.

🔬 **El detalle:** Dentro de un monolito, el read model puede ser una tabla o una vista materializada de la misma base; no exige otro almacén.

### 12. 🟡 ¿Cuándo es aceptable la afinidad de sesión y cuándo se vuelve un problema?

⏱️ **30 segundos:** Es aceptable como paso temporal durante una migración de sesión; es un problema cuando queda como solución permanente sin nombrarla.

🗣️ **2 minutos:** La afinidad evita perder sesiones en memoria, pero desequilibra la carga y concentra usuarios en réplicas que luego caen con ellos. Mientras se mueve la sesión a un almacén compartido, compra tiempo. Si nadie la retira, esconde estado por réplica y convierte cada despliegue en cierre de sesiones.

🔬 **El detalle:** Se nota en los despliegues: si reiniciar una réplica desconecta usuarios, la afinidad está sosteniendo estado que debería vivir fuera.

### 13. 🟡 ¿Qué cambias en un experimento de rendimiento y qué mantienes fijo?

⏱️ **30 segundos:** Cambias una sola variable —un índice, el tamaño del pool, las réplicas— y mantienes fija la carga, los datos y la versión del resto.

🗣️ **2 minutos:** Si cambian dos cosas a la vez, no sabes cuál produjo el efecto. La carga debe ser comparable en volumen y forma: el mismo mix de rutas y el mismo SKU caliente. Se mide antes y después con el mismo percentil y la misma ventana, y se conserva el cambio solo si mejora el SLO sin empeorar corrección ni coste.

🔬 **El detalle:** Una prueba de carga local da tendencias, no cifras de producción; se etiqueta como reproducción local y se confirma con tráfico real acotado.

### 14. 🟡 ¿Qué te dice un percentil alto que el promedio esconde?

⏱️ **30 segundos:** Las esperas de una minoría de peticiones: colas, locks, pausas de GC o el SKU caliente.

🗣️ **2 minutos:** Un promedio de 150 ms puede convivir con un p99 de 2 s si una de cada cien peticiones espera en el pool. Son justo esas peticiones las que ven los clientes de la campaña. El p99 por ruta y por SKU caliente muestra el cuello que el promedio disuelve.

🔬 **El detalle:** Promediar percentiles de varias réplicas no da el percentil global; hay que agregar histogramas.

### 15. 🟡 ¿Cómo afecta un proceso de reportes pesado al rendimiento de checkout dentro del mismo monolito?

⏱️ **30 segundos:** Compite por los recursos compartidos: conexiones, CPU, memoria y locks. Si no tiene límite, degrada checkout aunque no comparta código.

🗣️ **2 minutos:** Un reporte que ocupa la mitad del pool durante un minuto deja a checkout esperando conexión; uno que carga muchas filas en memoria presiona el GC de todo el proceso. La corrección está en el capítulo de observabilidad y resiliencia: cupos por tipo de trabajo, o reportes contra una réplica de lectura.

🔬 **El detalle:** Es el argumento de rendimiento más sólido para separar un workload: tiene un recurso propio que compite, y aislarlo lo demuestra la medición.

### 16. 🟡 ¿Qué coste por operación vigilarías además de la latencia?

⏱️ **30 segundos:** Consultas por petición, conexiones retenidas, memoria asignada y coste de infraestructura por pedido.

🗣️ **2 minutos:** Una optimización que baja latencia duplicando consultas a la base traslada el coste; una caché que baja latencia con el triple de memoria puede no compensar. El coste por operación dice si el sistema escala de forma sostenible cuando crece el tráfico.

🔬 **El detalle:** Las consultas por petición son la métrica más barata de recoger y la que antes delata un N+1 introducido por un cambio de ORM.

### 17. 🟡 ¿Qué señales compararías entre JFR en Java y `pprof` en Go antes de atribuir el cuello a CPU?

⏱️ **30 segundos:** Tiempo en CPU frente a tiempo bloqueado o esperando, y la presión de memoria y GC; en ambos, antes que el perfil de CPU.

🗣️ **2 minutos:** JFR registra eventos de CPU, bloqueos de monitor, esperas de E/S y pausas de GC; `pprof` ofrece perfiles de CPU, de bloqueo, de mutex y de heap. Si los perfiles de bloqueo dominan, el cuello no es la CPU. Comparar ambos tipos de perfil evita optimizar código que solo está esperando.

🔬 **El detalle:** El perfil de CPU de Go muestrea solo tiempo en CPU; una goroutine esperando no aparece, por eso hace falta el perfil de bloqueo.

### 18. 🟠 ¿Cómo distingues event loop bloqueado en Node de saturación de workers o de base en Python?

⏱️ **30 segundos:** En Node, el retraso del event loop crece y todas las peticiones del proceso se frenan a la vez; en Python con workers, los workers están ocupados esperando y la cola de peticiones crece.

🗣️ **2 minutos:** Un cálculo síncrono en Node bloquea el único hilo: sube la métrica de retraso del event loop aunque la base esté tranquila. En Python con procesos o hilos, si todos esperan a la base, los workers aparecen ocupados con CPU baja; el cuello está en la base o el pool. La métrica que sube dice dónde mirar.

🔬 **El detalle:** Añadir workers en Python ayuda si esperan I/O y hay capacidad en la base; en Node, un cálculo pesado se saca del hilo principal, no se tapa con más instancias.

### 19. 🟠 Negocio pide soportar el triple de tráfico en la campaña de diciembre. ¿Cómo planificarías la capacidad sin adivinar?

⏱️ **30 segundos:** Con una prueba de carga que reproduzca la forma del tráfico real al triple, para encontrar qué recurso se agota primero y cuánto margen hay.

🗣️ **2 minutos:** Tomo el mix de rutas y el SKU caliente de la última campaña, lo escalo por tres contra un entorno parecido y subo carga por escalones. El primer recurso que satura —pool, CPU, una consulta— es el plan de trabajo. Corrijo, repito, y dejo un plan de degradación para lo que no llegue a tiempo.

🔬 **El detalle:** La prueba mide el entorno de prueba; la diferencia con producción —tamaño de datos, red, caché fría— se declara y se compensa con margen.

### 20. 🟠 Una caché de catálogo con TTL de 10 minutos muestra precios viejos tras una rebaja. ¿Qué harías hoy y qué cambiarías?

⏱️ **30 segundos:** Hoy, invalidar a mano las claves afectadas y verificar que el cobro usa el precio vigente; después, invalidar desde la escritura de precios.

🗣️ **2 minutos:** Lo urgente es que nadie pague un precio que no corresponde: confirmo que el cálculo del total lee la fuente, no la caché. Luego hago que el módulo dueño del precio invalide o actualice las claves al cambiarlo. El TTL queda como red de seguridad, no como mecanismo principal.

🔬 **El detalle:** Si la invalidación se pierde, el TTL acota el daño; por eso se conservan los dos y se mide la edad de las entradas servidas.

### 21. 🟠 Tras un despliegue, el heap crece hasta el OOM cada seis horas y reinicia todo el monolito. ¿Qué harías primero?

⏱️ **30 segundos:** Contener —revertir el despliegue o reiniciar escalonadamente— y capturar un volcado de heap antes del siguiente OOM para encontrar qué retiene memoria.

🗣️ **2 minutos:** Revertir es la acción reversible más barata si el cambio es claro. Si no se puede, reinicios escalonados evitan que caigan todas las réplicas a la vez. El volcado de heap, o el perfil de asignación, muestra qué estructura crece: una caché sin límite, un lote que carga todo o una colección estática.

🔬 **El detalle:** En un monolito, el OOM de un módulo tumba a todos: es el argumento para límites de lote y cachés acotadas, y a veces para aislar el workload que más memoria consume.

### 22. 🟠 Quieres mover la sesión de memoria local a una caché compartida. ¿Cómo lo harías de forma reversible?

⏱️ **30 segundos:** Escribiendo la sesión en ambos lugares y leyendo primero de la local, con una flag para pasar a leer de la compartida por cohortes.

🗣️ **2 minutos:** Paso uno: doble escritura sin cambiar la lectura. Paso dos: leer de la compartida para un porcentaje de usuarios y comparar errores y latencia. Paso tres: toda la lectura desde la compartida y retirar la afinidad. Si la caché compartida falla, la flag devuelve la lectura a la local.

🔬 **El detalle:** La caché compartida se vuelve una dependencia de runtime de cada petición; su caída debe tener una conducta definida, como pedir nuevo inicio de sesión, no un error genérico.

### 23. 🟠 Un equipo quiere extraer `inventory` y otro prefiere un índice y un read model. ¿Cómo decidirías?

⏱️ **30 segundos:** Con la medición: si el tiempo se va en la consulta de disponibilidad y la base, el índice ataca el recurso limitante; la extracción no lo toca.

🗣️ **2 minutos:** Pido la traza por etapa y el plan de la consulta. Si el índice y el read model bajan el p99 bajo carga comparable, se quedan y la extracción deja de estar motivada por rendimiento. Si `inventory` tiene además razones de autonomía, esas se discuten aparte, con su propio coste.

🔬 **El detalle:** Separar el argumento de rendimiento del de autonomía evita que uno se use para justificar el otro.

### 24. 🟠 ¿Qué criterio te diría que el monolito ya no puede escalar como una sola unidad?

⏱️ **30 segundos:** Que un workload necesite un recurso o un perfil de escalado propio que compite con el resto y no puede aislarse dentro del proceso.

🗣️ **2 minutos:** Por ejemplo, un cálculo intensivo en CPU que exige veinte réplicas mientras el resto necesita cuatro, o un consumo de memoria que obliga a máquinas grandes para todos. Si cupos, workers separados o réplicas de lectura no lo contienen, un proceso aparte para ese workload compra escalado selectivo, con su coste de red y despliegue.

🔬 **El detalle:** El criterio se formula con recursos medidos, no con el tamaño del código: un monolito grande que escala bien no tiene un problema de escalado.

## 📖 05 — Despliegues, migraciones de esquema y rollback

### 1. 🟢 ¿Por qué un rolling deployment obliga a pensar en versiones mixtas aunque el monolito sea un único artefacto?

⏱️ **30 segundos:** Porque durante el rollout conviven réplicas de la versión vieja y de la nueva, atendiendo tráfico sobre el mismo esquema.

🗣️ **2 minutos:** El artefacto es uno, pero se reemplaza réplica por réplica. Mientras tanto, la versión N y la N+1 leen y escriben las mismas tablas. Cualquier cambio de esquema tiene que servir a las dos, y el rollback vuelve a introducir la versión N sobre el esquema que haya en ese momento.

🔬 **El detalle:** Un canary o un blue-green alargan esa convivencia de minutos a horas, y con ella la ventana en que el esquema debe ser compatible.

### 2. 🟢 ¿Qué significan expandir y contraer en una migración de esquema?

⏱️ **30 segundos:** Expandir es añadir estructura sin quitar la existente; contraer es retirar la estructura vieja cuando ya nadie la usa.

🗣️ **2 minutos:** Primero se añade `total_cents` junto a `total`. Luego escritores y lectores migran con ambas columnas vivas y sincronizadas. Solo al final, en otro release, se borra `total`. Cada paso intermedio es compatible con las versiones que pueden estar corriendo.

🔬 **El detalle:** La expansión es barata de revertir: una columna que nadie usa se ignora. La contracción es el punto de no retorno.

### 3. 🟢 ¿Qué diferencia hay entre revertir código y revertir datos?

⏱️ **30 segundos:** Revertir código es volver a desplegar el artefacto anterior; revertir datos exige recuperar valores que ya cambiaron, y a veces no se puede.

🗣️ **2 minutos:** El artefacto anterior sigue existiendo y se reinstala en minutos. Una columna borrada o un valor convertido solo vuelven con una transformación inversa conocida o con una restauración de backup, que pierde lo escrito desde entonces. Por eso la reversibilidad se diseña en los datos, no en el pipeline.

🔬 **El detalle:** Un rollback de código seguro exige que la versión anterior entienda los datos que escribió la nueva.

### 4. 🟢 ¿Qué es un backfill y por qué debe ser reanudable?

⏱️ **30 segundos:** Es el proceso que rellena la estructura nueva con los datos existentes; debe poder reanudarse porque en tablas grandes tarda y puede interrumpirse.

🗣️ **2 minutos:** Un backfill de millones de filas se hace por lotes, con un marcador de progreso, para no retener locks ni llenar el log de transacciones. Si se corta —despliegue, error, límite de tiempo—, continúa desde el último lote confirmado en lugar de empezar de nuevo o dejar la tabla a medias sin saberlo.

🔬 **El detalle:** Un backfill idempotente por lote permite repetir el último sin miedo: vuelve a escribir los mismos valores.

### 5. 🟢 ¿Qué controla una feature flag y qué no puede controlar?

⏱️ **30 segundos:** Controla qué comportamiento del código se activa; no controla el esquema ni los datos ya escritos.

🗣️ **2 minutos:** Con una flag se separa desplegar de activar: el código que escribe `total_cents` puede estar desplegado y apagado. Pero la flag no hace compatible un esquema, no restaura una columna y no borra los datos que el comportamiento nuevo ya escribió mientras estuvo encendido.

🔬 **El detalle:** Apagar una flag es un rollback de comportamiento, no de estado: lo escrito con la flag encendida sigue ahí.

### 6. 🟢 ¿Qué es *roll-forward* y cuándo es la única salida?

⏱️ **30 segundos:** Corregir hacia adelante con un nuevo despliegue en lugar de volver atrás; es la única salida cuando los datos ya cambiaron de forma que la versión anterior no entiende.

🗣️ **2 minutos:** Si una migración destructiva ya corrió, volver al código viejo no sirve: espera un esquema que no existe. Lo que queda es desplegar una corrección, o restaurar un backup con pérdida de la ventana. El roll-forward exige un pipeline rápido y una corrección pequeña.

🔬 **El detalle:** Diseñar para no necesitarlo es el objetivo de expand-contract: mientras no se contrae, el rollback sigue disponible.

### 7. 🟡 ¿Por qué renombrar una columna en un solo paso rompe un rolling deployment?

⏱️ **30 segundos:** Porque las réplicas viejas siguen leyendo el nombre anterior y, en cuanto la migración corre, fallan.

🗣️ **2 minutos:** Renombrar es borrar un nombre y crear otro en la misma operación: para la versión N es una columna que desaparece. En el rollout, las réplicas N atienden tráfico hasta que se reemplazan, y todas sus consultas fallan. El renombrado seguro son tres pasos: añadir, migrar lectores y escritores, retirar.

🔬 **El detalle:** Una vista con el nombre viejo puede dar compatibilidad temporal en lecturas, pero no suele cubrir escrituras ni ORM que inspeccionan la tabla.

### 8. 🟡 ¿Cuándo aceptarías una ventana de mantenimiento en lugar de expand-contract?

⏱️ **30 segundos:** Cuando el negocio acepta la indisponibilidad y el cambio es lo bastante complejo como para que la compatibilidad cueste más que la parada.

🗣️ **2 minutos:** Con la aplicación parada no hay versiones mixtas: se migra, se valida y se arranca la versión nueva. Es más simple y menos arriesgado para transformaciones profundas. El precio es la indisponibilidad y un plan de vuelta atrás que sigue necesitando backup si la transformación es destructiva.

🔬 **El detalle:** La ventana de mantenimiento es una opción legítima, no un fracaso; lo que no vale es hacer una parada encubierta con un rolling deployment roto.

### 9. 🟡 ¿Por qué no conviene ejecutar la migración al arrancar cada réplica?

⏱️ **30 segundos:** Porque la primera réplica que arranca cambia el esquema para todas, sin que nadie decida el momento ni pueda abortar.

🗣️ **2 minutos:** Con varias réplicas arrancando a la vez, varias intentan migrar y dependen del lock de la herramienta. Una migración lenta retrasa el arranque y puede disparar reinicios por health check. Y el cambio queda atado al despliegue del código, cuando expand-contract necesita separarlos. Un paso de migración propio da control y un punto de aborto.

🔬 **El detalle:** Para migraciones aditivas y rápidas en un solo nodo, migrar al arrancar puede ser razonable; el problema aparece con cambios destructivos y varias réplicas.

### 10. 🟡 Durante la fase intermedia, ¿quién tiene la autoridad de escritura sobre `total` y `total_cents`, y cómo se mantienen sincronizadas?

⏱️ **30 segundos:** Mientras existan escritores antiguos, `total` es la autoridad y `total_cents` se deriva de ella en la misma transacción; la autoridad cambia solo cuando no queda ningún escritor viejo.

🗣️ **2 minutos:** La versión N+1 escribe ambas columnas; la versión N solo escribe `total`, así que hace falta una sincronización —trigger o escritura doble en el código— que mantenga `total_cents` al día. Cuando todas las réplicas son N+1 y el backfill terminó, `total_cents` pasa a ser la autoridad.

🔬 **El detalle:** Declarar la autoridad evita el peor caso: dos columnas que divergen y nadie sabe cuál es la verdadera.

### 11. 🟡 ¿Cómo evitas que el backfill sobrescriba valores que la aplicación escribió mientras corría?

⏱️ **30 segundos:** Haciendo que el backfill solo rellene filas pendientes —por ejemplo, donde `total_cents` es nulo— y respete lo que ya escribió la aplicación.

🗣️ **2 minutos:** Si el backfill copia sin condición, puede pisar con un valor calculado de una lectura vieja lo que la aplicación acaba de escribir. Con una condición en el `UPDATE` de cada lote, solo toca filas que nadie actualizó. Así backfill y escritores conviven sin coordinarse más.

🔬 **El detalle:** Es el mismo problema de la actualización perdida del capítulo de concurrencia: la condición se evalúa en la escritura, no en una lectura previa.

### 12. 🟡 ¿Qué señal observarías antes de contraer?

⏱️ **30 segundos:** Que ninguna versión desplegada ni ningún consumidor lea o escriba la columna vieja durante un período acordado.

🗣️ **2 minutos:** Busco el uso real: estadísticas de la base sobre accesos a la columna o la tabla, logs de consultas, y el inventario de consumidores fuera del monolito —reportes, ETL—. Si en una ventana completa nadie la tocó y la ventana de rollback cerró, contraer ya no rompe nada.

🔬 **El detalle:** Un consumidor no inventariado es el riesgo típico de la contracción; por eso el uso se observa, no se supone.

### 13. 🟡 ¿Qué define la duración de la ventana de rollback?

⏱️ **30 segundos:** El tiempo durante el cual quieres poder volver a la versión anterior del código; mientras dure, el esquema debe seguir sirviéndole.

🗣️ **2 minutos:** Se fija por el riesgo del cambio y el tiempo que tarda en aparecer un defecto: si un error de facturación se detecta a fin de mes, una ventana de una hora no sirve. Hasta que cierra, no se contrae. Cerrarla es una decisión explícita, no el efecto de olvidar la columna.

🔬 **El detalle:** La ventana también tiene coste: mantener dos representaciones sincronizadas es código y datos extra que conviene retirar con fecha.

### 14. 🟡 ¿Por qué un backfill grande no debe ir en la misma transacción que el DDL?

⏱️ **30 segundos:** Porque la transacción retendría el lock del DDL durante todo el backfill, bloqueando la tabla y creciendo sin límite.

🗣️ **2 minutos:** El DDL toma un lock fuerte sobre la tabla; si el backfill va en la misma transacción, ese lock dura minutos u horas y checkout espera. Además, un fallo al final revierte todo el trabajo. Separados, el DDL es breve y el backfill avanza por lotes confirmados.

🔬 **El detalle:** En PostgreSQL el DDL es transaccional, lo que tienta a meter todo en una transacción; esa capacidad es útil para DDL pequeños, no para mover datos.

### 15. 🟡 ¿Qué operaciones de DDL pueden bloquear la tabla en producción y cómo lo mitigas?

⏱️ **30 segundos:** Las que toman un lock exclusivo o reescriben la tabla —cambiar tipos, añadir restricciones que validan todas las filas, crear índices sin `CONCURRENTLY`—; se mitigan con variantes no bloqueantes y un `lock_timeout`.

🗣️ **2 minutos:** Incluso un `ALTER TABLE` rápido espera su lock exclusivo detrás de transacciones largas, y mientras espera bloquea a todos los que llegan después. Un `lock_timeout` corto hace que falle y se reintente en lugar de congelar la tabla. Para índices, `CREATE INDEX CONCURRENTLY`; para restricciones, añadirlas sin validar y validarlas aparte.

🔬 **El detalle:** Desde PostgreSQL 11, añadir una columna con un valor por defecto constante no reescribe la tabla; con un valor por defecto volátil, sí.

### 16. 🟡 ¿Qué aporta ensayar una restauración de backup que no aporta tenerlo?

⏱️ **30 segundos:** Saber que se puede restaurar, cuánto tarda y cuántos datos se pierden: sin el ensayo, el backup es una suposición.

🗣️ **2 minutos:** Un backup que nunca se restauró puede estar incompleto, cifrado con una clave perdida o tardar diez horas en cargar. El ensayo mide el tiempo de recuperación y el punto de recuperación reales, y deja escrito el procedimiento. Para una migración destructiva es la única vuelta atrás.

🔬 **El detalle:** El ensayo se hace antes del cambio arriesgado, no después del incidente; su resultado entra en la decisión de contraer.

### 17. 🟡 ¿Qué debe permanecer igual entre una migración lanzada desde Java y una ejecutada como comando Go separado?

⏱️ **30 segundos:** La secuencia versionada de migraciones, el registro de cuáles se aplicaron y la decisión explícita de cuándo se ejecutan.

🗣️ **2 minutos:** Que en Java la dispare el arranque de Spring o un paso del pipeline, y en Go un binario aparte, cambia el mecanismo, no el contrato. En ambos casos las migraciones están en el repositorio, se aplican en orden, quedan registradas en la base y se ejecutan una vez, antes o después del código según la fase de expand-contract.

🔬 **El detalle:** El comando separado de Go hace explícito lo que en Java conviene hacer explícito también: la migración es un paso del despliegue, no un efecto del arranque.

### 18. 🟠 ¿Por qué editar una migración ya aplicada es igual de riesgoso en Node/TypeScript y Python?

⏱️ **30 segundos:** Porque la base que ya la aplicó no la vuelve a ejecutar, y los entornos quedan con esquemas distintos aunque el archivo diga lo mismo.

🗣️ **2 minutos:** El registro de migraciones marca la versión como aplicada; el cambio en el archivo solo llega a entornos nuevos. Producción tiene el esquema viejo, un entorno recién creado el nuevo, y nadie lo nota hasta que falla. Algunas herramientas detectan la edición por checksum y otras no; en todas, la corrección es una migración nueva.

🔬 **El detalle:** La historia de migraciones es inmutable por la misma razón que un contrato publicado: alguien ya depende de ella.

### 19. 🟠 A mitad del rollout aparecen `column "total" does not exist` en las réplicas viejas. ¿Qué haces en los primeros minutos?

⏱️ **30 segundos:** Detener el rollout y restaurar la compatibilidad del esquema —volver a crear `total` sincronizada, o una vista— antes de intentar ningún rollback de código.

🗣️ **2 minutos:** El rollback del código no ayuda: la versión vieja necesita la columna. Lo más rápido suele ser recrear `total` y rellenarla desde `total_cents`, que tiene los mismos datos si el renombrado no los transformó. Con eso, ambas versiones vuelven a funcionar y se puede decidir con calma si seguir o volver.

🔬 **El detalle:** Si además se transformaron datos, recrear la columna exige la conversión inversa; es cuando el ensayo previo, o su ausencia, se nota.

### 20. 🟠 El backfill lleva el 60 % y detectas valores divergentes entre las dos columnas. ¿Continúas, pausas o reviertes?

⏱️ **30 segundos:** Pauso: el backfill es reanudable, y continuar con un error conocido solo multiplica filas que habrá que corregir.

🗣️ **2 minutos:** Busco la causa en una muestra: conversión mal hecha, escritores que no sincronizan o carrera entre backfill y aplicación. Con la causa corregida, reproceso las filas divergentes y reanudo. Revertir no hace falta: la columna nueva todavía no es la autoridad y nadie la lee.

🔬 **El detalle:** Esa es la ventaja de expandir primero: mientras `total_cents` no manda, un error en ella se corrige sin afectar a clientes.

### 21. 🟠 Una migración añade una columna `NOT NULL` con valor por defecto en una tabla grande. ¿Qué verificarías antes de lanzarla?

⏱️ **30 segundos:** Si el valor por defecto es constante —y entonces no reescribe la tabla en PostgreSQL 11 o posterior— y cuánto tiempo esperará el lock exclusivo detrás de transacciones largas.

🗣️ **2 minutos:** Con un valor por defecto volátil, como una función que genera identificadores, la tabla se reescribe entera con un lock que bloquea todo. Con uno constante, el cambio es de catálogo y rápido, pero igual necesita el lock un instante. Uso un `lock_timeout` y lo lanzo cuando no haya transacciones largas abiertas.

🔬 **El detalle:** Lo compruebo en una copia con el volumen real: la documentación dice qué hace el motor; el ensayo dice cuánto tarda con mis datos.

### 22. 🟠 El cambio de unidad monetaria de `total` exige convertir datos. ¿Cómo lo harías reversible hasta el último paso?

⏱️ **30 segundos:** Añadiendo una columna nueva con la unidad nueva y conservando la original sin tocar hasta cerrar la ventana de rollback.

🗣️ **2 minutos:** Nunca convierto en su sitio: `total` sigue con su unidad y su autoridad, y `total_minor` se llena con la conversión validada. Comparo ambas por muestreo y por totales. Cambio lectores a la nueva, luego escritores, y solo después retiro la vieja. Si la conversión resulta errónea, la original está intacta.

🔬 **El detalle:** La conversión se valida con reglas de negocio, no solo con tipos: redondeos, monedas sin decimales, pedidos históricos con otra moneda.

### 23. 🟠 Un equipo quiere desplegar esquema y código juntos «para simplificar» y otro separar en tres releases. ¿Cómo decidirías?

⏱️ **30 segundos:** Con la naturaleza del cambio: aditivo y compatible puede ir junto; destructivo o de renombrado necesita separar expandir, migrar y contraer.

🗣️ **2 minutos:** Añadir una columna opcional que el código nuevo usa puede ir en un solo release sin riesgo. Renombrar, cambiar tipos o borrar no: juntos, rompen el rollout y el rollback. Propongo una regla escrita —los cambios destructivos siempre en release aparte— en lugar de discutir cada caso.

🔬 **El detalle:** Tres releases no significan tres semanas: la contracción puede ser días después, pero tiene que ser otro despliegue.

### 24. 🟠 ¿Qué criterio te permite contraer y dar por cerrada la migración?

⏱️ **30 segundos:** Todas las versiones soportadas usan la estructura nueva, ningún consumidor toca la vieja en una ventana observada, la ventana de rollback cerró y la restauración está ensayada.

🗣️ **2 minutos:** Con esas cuatro condiciones, borrar la columna vieja ya no rompe a nadie y no elimina ninguna vuelta atrás que se quisiera conservar. Contraigo en un release propio, con el lock controlado, y retiro también la sincronización temporal.

🔬 **El detalle:** Una migración sin contracción queda a medias: dos columnas, un trigger y deuda que nadie recuerda por qué existe.

## 📖 06 — Observabilidad y resiliencia del monolito

### 1. 🟢 ¿Qué pregunta responde cada señal: logs, métricas y trazas?

⏱️ **30 segundos:** Los logs, qué pasó en un evento concreto; las métricas, cómo evoluciona un recurso o un resultado en el tiempo; las trazas, dónde se fue el tiempo de una operación a través de sus etapas.

🗣️ **2 minutos:** En el incidente del cierre, las métricas muestran el pool saturado y los errores de checkout; la traza de una petición fallida muestra la espera de conexión; el log, con `order_id`, dice qué pedido y qué módulo. Ninguna señal sola cierra el diagnóstico.

🔬 **El detalle:** Correlacionarlas es lo que les da valor: un identificador compartido entre log y traza, y un exemplar que une una métrica con una traza concreta.

### 2. 🟢 ¿Qué es un *bulkhead* y qué separa?

⏱️ **30 segundos:** Un mamparo de capacidad: reserva o limita recursos por workload para que el fallo de uno no se lleve a los demás. Separa capacidad, no código.

🗣️ **2 minutos:** Un cupo de dos conexiones para reportes, un executor propio para notificaciones o una cola acotada por tipo de trabajo son bulkheads. Los reportes siguen en el mismo proceso y el mismo código; lo que cambia es que no pueden ocupar lo que checkout necesita.

🔬 **El detalle:** El nombre viene de los compartimentos estancos de un barco: una vía de agua inunda uno, no todos.

### 3. 🟢 ¿Qué diferencia hay entre liveness y readiness?

⏱️ **30 segundos:** Liveness responde si el proceso debe reiniciarse; readiness, si puede recibir tráfico ahora.

🗣️ **2 minutos:** Un proceso vivo pero sin conexión a la base debe dejar de recibir tráfico —readiness falla— y no reiniciarse, porque reiniciar no arregla la base. Liveness solo debe fallar cuando el proceso está roto por dentro: bloqueado, sin memoria, en un estado del que no sale solo.

🔬 **El detalle:** Mezclarlos convierte una degradación externa en una cascada de reinicios; es de los errores de configuración más caros en un incidente.

### 4. 🟢 ¿Qué es un presupuesto de tiempo (*timeout budget*) en una petición?

⏱️ **30 segundos:** El tiempo total que la petición puede gastar, repartido entre sus etapas, de modo que ninguna espere más de lo que queda.

🗣️ **2 minutos:** Si checkout promete responder en 800 ms, esperar conexión no puede llevarse 700. Cada etapa recibe lo que queda del presupuesto y falla de forma explícita cuando se agota. En el ejemplo, checkout espera conexión como máximo 150 ms y falla con un mensaje claro.

🔬 **El detalle:** El presupuesto se propaga con el contexto; en Go, un `context.Context` con deadline lo lleva hasta cada llamada.

### 5. 🟢 ¿Por qué un identificador de pedido va en logs y trazas y no como etiqueta de una métrica?

⏱️ **30 segundos:** Porque cada valor distinto de una etiqueta crea una serie nueva, y una serie por pedido hace crecer sin límite el almacenamiento de métricas.

🗣️ **2 minutos:** Las métricas agregan por dimensiones acotadas: módulo, ruta, resultado, versión. Los identificadores únicos van donde se consulta un caso concreto: logs y trazas. Si hace falta saltar de una métrica a un pedido, se usa un exemplar, no una etiqueta.

🔬 **El detalle:** Es el error de cardinalidad más habitual; el síntoma aparece semanas después, como un sistema de métricas lento o caro.

### 6. 🟢 ¿Qué significa degradar de forma explícita?

⏱️ **30 segundos:** Decidir de antemano qué función secundaria se rechaza o se simplifica cuando falta capacidad, y hacerlo visible, en lugar de que todo se vuelva lento a la vez.

🗣️ **2 minutos:** En el ejemplo, los reportes que no caben en su cupo se rechazan en el acto y checkout conserva sus conexiones. Degradar puede ser rechazar, diferir o responder con menos datos; lo importante es que lo decide el diseño y no el orden de llegada.

🔬 **El detalle:** Una degradación no documentada parece un fallo aleatorio; documentada, es una promesa de qué se protege primero.

### 7. 🟡 ¿Por qué medir solo la CPU agregada es una simplificación peligrosa?

⏱️ **30 segundos:** Porque el incidente típico de un monolito es una espera —pool, lock, cola—, y con la CPU baja la métrica agregada dice que todo va bien.

🗣️ **2 minutos:** En el cierre de mes, la CPU de las réplicas está tranquila mientras checkout espera conexión. Hace falta saturación por recurso —pool activo y en espera, profundidad de colas— y latencia por ruta. La CPU agregada, además, mezcla módulos y oculta cuál consume.

🔬 **El detalle:** Las métricas de saturación del pool son las más baratas de exponer y las que primero delatan este tipo de incidente.

### 8. 🟡 ¿Cuándo moverías los reportes a un worker o proceso separado en lugar de ponerles un cupo?

⏱️ **30 segundos:** Cuando el cupo desperdicie demasiada capacidad, cuando consuman otros recursos que el cupo no controla —memoria, CPU— o cuando el runtime no permita aislarlos.

🗣️ **2 minutos:** Un cupo de conexiones no impide que un reporte cargue un millón de filas en memoria y presione el GC de todo el proceso. Si eso ocurre, un worker aparte, o reportes contra una réplica de lectura, aíslan el recurso que el cupo no alcanza. Cuesta otro despliegue y datos quizá algo retrasados.

🔬 **El detalle:** Es un caso de extracción justificada por recurso, medida con el mismo incidente provocado antes y después.

### 9. 🟡 En el ejemplo Java, ¿por qué la línea del executor muestra `order_id=null` y qué hace `withContext`?

⏱️ **30 segundos:** Porque `ORDER_ID` es un `ThreadLocal` y la tarea corre en otro hilo, que no tiene el valor; `withContext` lo captura en el hilo que envía y lo restablece en el que ejecuta.

🗣️ **2 minutos:** El `ThreadLocal` vive en el hilo que atendió la petición. Al enviar trabajo a un executor, el hilo que lo corre no sabe nada del pedido. `withContext` lee el valor al crear la tarea y lo fija dentro del `Runnable` antes de ejecutarlo, así el log vuelve a decir `order_id=o-42`.

🔬 **El detalle:** Las librerías de telemetría hacen esto instrumentando los executors, para no depender de que cada llamada lo recuerde.

### 10. 🟡 ¿Por qué `withContext` limpia el valor en un `finally`?

⏱️ **30 segundos:** Porque los hilos de un pool se reutilizan, y sin limpiar, la siguiente tarea heredaría el pedido anterior.

🗣️ **2 minutos:** Un log con el `order_id` equivocado es peor que uno con `null`: atribuye trabajo a un pedido que no lo hizo. El `finally` garantiza la limpieza incluso si la tarea lanza una excepción.

🔬 **El detalle:** Es el mismo motivo por el que los filtros HTTP limpian el MDC al terminar cada petición.

### 11. 🟡 ¿Qué cuesta reservar conexiones para checkout con un cupo para reportes?

⏱️ **30 segundos:** Capacidad ociosa cuando no hay reportes, y reportes rechazados cuando sí los hay.

🗣️ **2 minutos:** En el ejemplo, seis reportes se rechazaron y, en un día sin reportes, dos conexiones del cupo quedan sin uso para ellos. Ese es el precio de que checkout conserve capacidad. El tamaño del cupo se decide con la medición del pool y el SLO de compra, no con una regla fija.

🔬 **El detalle:** Un cupo demasiado pequeño hace que los reportes nunca terminen; uno demasiado grande vuelve a dejar a checkout sin margen.

### 12. 🟡 ¿Por qué el cupo de reportes usa `tryAcquire` sin espera y checkout espera hasta 150 ms?

⏱️ **30 segundos:** Porque para reportes la degradación elegida es rechazar en el acto, y para checkout vale la pena esperar un poco dentro de su presupuesto antes de fallar.

🗣️ **2 minutos:** Si los reportes esperaran en su cupo, formarían una cola sin límite de trabajo pendiente. Checkout, en cambio, es la función que se protege: una espera corta absorbe picos momentáneos sin romper el SLO. Cada workload tiene la política que corresponde a su importancia.

🔬 **El detalle:** La espera de checkout tiene que caber en su presupuesto total; si se la come entera, el resto de etapas ya no tiene tiempo.

### 13. 🟡 ¿Qué pasa si liveness comprueba la base durante una saturación del pool?

⏱️ **30 segundos:** El check falla porque no consigue conexión, el orquestador reinicia réplicas sanas y el tráfico se concentra en las que quedan, que caen después.

🗣️ **2 minutos:** La réplica no estaba rota: estaba esperando a un recurso compartido. Reiniciarla pierde el trabajo en curso, alarga la recuperación y empuja más carga sobre las demás. Liveness solo comprueba el proceso; la base, si acaso, va en readiness.

🔬 **El detalle:** Readiness que falla por la base también tiene riesgo: si fallan todas, no queda nadie para servir ni siquiera una respuesta degradada.

### 14. 🟡 ¿Cómo se reparten timeouts y reintentos entre capas sin multiplicar la carga?

⏱️ **30 segundos:** Con un único presupuesto propagado y reintentos en una sola capa, con límite y jitter.

🗣️ **2 minutos:** Si el cliente, el controlador y el repositorio hacen hasta tres intentos cada uno, una dependencia lenta puede recibir 3 × 3 × 3 = 27 llamadas por petición. Se decide qué capa reintenta —normalmente la más cercana a la dependencia— y las demás propagan el error. Cada reintento descuenta del presupuesto que queda.

🔬 **El detalle:** Un circuit breaker complementa, no reemplaza: deja de intentar cuando la dependencia está claramente caída.

### 15. 🟡 ¿Qué es un exemplar y qué problema resuelve?

⏱️ **30 segundos:** Un enlace desde un punto de una métrica a una traza concreta que lo representa.

🗣️ **2 minutos:** Resuelve el salto de «el p99 subió» a «esta petición concreta tardó así» sin poner identificadores únicos en las etiquetas. Al mirar la métrica de latencia se abre una traza de ejemplo del percentil alto y se ve qué etapa esperó.

🔬 **El detalle:** Requiere que métricas y trazas compartan instrumentación; OpenTelemetry lo contempla.

### 16. 🟡 ¿Qué SLO definirías para checkout y dónde lo medirías?

⏱️ **30 segundos:** Por ejemplo, el 99 % de los checkouts termina con éxito en menos de 800 ms en ventanas de 30 días, medido en el borde del sistema.

🗣️ **2 minutos:** Se mide donde el cliente lo sufre: el balanceador o la entrada HTTP, no un módulo interno. Las métricas internas sirven para explicar quién consumió el presupuesto de error. El objetivo lo fija negocio con datos de uso; las cifras de aquí son de ejemplo.

🔬 **El detalle:** El presupuesto de error del SLO es lo que decide cuánta degradación tolerar antes de frenar despliegues o priorizar el aislamiento.

### 17. 🟡 ¿Qué problema común resuelven MDC/telemetría en Java y `context.Context` en Go, y cuál no resuelven?

⏱️ **30 segundos:** Ambos llevan el contexto de la operación a través de las llamadas; ninguno limita cuánto recurso consume esa operación.

🗣️ **2 minutos:** El MDC y la instrumentación de telemetría en Java hacen que logs y trazas sepan de qué pedido se trata; `context.Context` en Go lleva identificadores, deadline y cancelación. Con eso se atribuye y se cancela, pero ni uno ni otro reparte conexiones entre workloads: eso son pools y cupos.

🔬 **El detalle:** El deadline de `context.Context` sí acota tiempo, lo que ya es una forma de contención que el MDC no ofrece.

### 18. 🟠 ¿Qué se pierde al propagar contexto en Node o Python si los pools siguen sin cuotas?

⏱️ **30 segundos:** Nada de visibilidad y nada de protección: sabrás exactamente qué reporte agotó el pool, pero checkout seguirá fallando.

🗣️ **2 minutos:** `AsyncLocalStorage` y `contextvars` mejoran el diagnóstico: los logs dicen qué pedido y qué workload esperaban. Sin cuotas, el incidente es igual de grave, solo mejor explicado. La propagación es condición para poner cupos con criterio, no un sustituto.

🔬 **El detalle:** Es el orden correcto de trabajo: primero ver quién consume, después limitar con los datos en la mano.

### 19. 🟠 Cada cierre de mes checkout falla un 8 % durante quince minutos. ¿Qué harías antes del próximo cierre?

⏱️ **30 segundos:** Reproducir el incidente en un entorno de prueba con los reportes reales, poner un cupo a los reportes y un presupuesto de espera a checkout, y comprobar que el error desaparece bajo la misma carga.

🗣️ **2 minutos:** Primero, contexto en los logs y métricas de saturación del pool, para confirmar que son los reportes. Después, el cupo y la degradación, activables por flag. Y liveness sin dependencia de la base. Con el cierre provocado en prueba, se mide el antes y el después del SLO de compra.

🔬 **El detalle:** Si no hay tiempo para todo, lo mínimo es separar liveness de la base: evita que el incidente se amplifique con reinicios.

### 20. 🟠 Durante un incidente, el orquestador reinicia réplicas en cadena por health checks fallidos. ¿Qué haces primero?

⏱️ **30 segundos:** Detener la cascada: desactivar o relajar el liveness que depende de la dependencia caída, para que las réplicas dejen de reiniciarse.

🗣️ **2 minutos:** Cada reinicio pierde trabajo y concentra tráfico en menos réplicas. Con el liveness corregido, readiness saca de rotación a las que no pueden servir sin matarlas. Después se atiende la causa —la base o el pool— con las réplicas estables.

🔬 **El detalle:** La corrección permanente es la que evita el incidente siguiente: liveness que solo mire el proceso, escrito y probado antes de producción.

### 21. 🟠 Un cambio de librería HTTP hace que las trazas de `payments` aparezcan desconectadas del pedido. ¿Cómo lo detectarías y lo corregirías?

⏱️ **30 segundos:** Lo detecta una prueba o una alerta sobre trazas huérfanas —spans sin padre en rutas que siempre lo tienen—; se corrige instrumentando la librería nueva o propagando el contexto a mano en sus callbacks.

🗣️ **2 minutos:** La librería nueva ejecuta callbacks en su propio pool de hilos o no inyecta las cabeceras de traza, así que el span de la llamada no conoce al padre. Una prueba de integración que verifique que la llamada a `payments` comparte trace id con la petición lo detecta antes de producción.

🔬 **El detalle:** Es el mismo fallo que el `order_id=null` del ejemplo, en otra capa: todo salto de hilo o de proceso es un punto donde el contexto se pierde.

### 22. 🟠 Quieres introducir cupos por workload en producción. ¿Cómo lo harías de forma reversible?

⏱️ **30 segundos:** Midiendo primero el consumo real por workload, desplegando el cupo en modo observación y activándolo con una flag, empezando por un límite holgado.

🗣️ **2 minutos:** Paso uno: métricas de conexiones por workload, que exigen contexto propagado. Paso dos: el cupo cuenta sin rechazar, para ver cuántas veces se habría activado. Paso tres: rechazo real con un límite generoso, y ajuste gradual. Si algo se rompe, la flag vuelve al pool compartido.

🔬 **El detalle:** Avisar a finanzas antes de que sus reportes empiecen a ser rechazados también es parte del despliegue reversible.

### 23. 🟠 Un equipo quiere sacar los reportes a una réplica de lectura y otro prefiere un cupo en el proceso. ¿Cómo decidirías?

⏱️ **30 segundos:** Con qué recurso agotan los reportes y qué frescura necesitan: si es solo conexiones y necesitan datos al instante, el cupo; si también CPU y memoria de la base primaria y toleran segundos de retraso, la réplica.

🗣️ **2 minutos:** El cupo es barato y protege el pool, pero las consultas pesadas siguen cargando la base primaria. La réplica de lectura saca esa carga de la primaria a cambio de otra infraestructura y de datos algo retrasados. Pruebo el cupo primero porque es reversible en minutos, y mido si la primaria sigue sufriendo.

🔬 **El detalle:** Las dos opciones no se excluyen: cupo ya, réplica cuando la medición muestre que la primaria es el cuello.

### 24. 🟠 ¿Qué criterio te diría que el aislamiento interno ya no alcanza?

⏱️ **30 segundos:** Que con cupos y presupuestos bien dimensionados, el workload secundario siga degradando el SLO de checkout por un recurso que el proceso no puede repartir, como memoria o CPU.

🗣️ **2 minutos:** Si los reportes tienen su cupo de conexiones y aun así el GC de todo el proceso se dispara con sus lotes, o la CPU que consumen deja sin margen a checkout, el mamparo tiene que ser un proceso. Lo compruebo con el incidente provocado: si el SLO no se recupera con aislamiento interno, separar el workload es el siguiente paso medible.

🔬 **El detalle:** El criterio incluye el coste: separar un proceso añade despliegue y red, y se justifica solo si recupera un SLO que el aislamiento interno no pudo.

## 📖 07 — Estrategia de pruebas y evidencia de modularidad

### 1. 🟢 ¿Qué significa elegir «la prueba más cercana» a un riesgo?

⏱️ **30 segundos:** La prueba de menor alcance que todavía puede ponerse roja cuando el riesgo ocurre.

🗣️ **2 minutos:** Una regla de descuento se prueba en el módulo, sin base; una restricción `UNIQUE`, contra la base real, porque solo ahí existe. Más cercana significa más rápida y con un fallo más fácil de localizar, pero nunca tan cercana que el riesgo quede fuera de la prueba.

🔬 **El detalle:** El error típico es ir demasiado cerca —un mock que no puede fallar— o demasiado lejos —un E2E que falla sin decir por qué—.

### 2. 🟢 ¿Qué puede demostrar una prueba de módulo sin infraestructura y qué no?

⏱️ **30 segundos:** Puede demostrar las decisiones de la lógica del módulo; no puede demostrar nada que dependa de la base, la red o la concurrencia real.

🗣️ **2 minutos:** Que `orders` rechace un pedido vacío o calcule bien el total se prueba en milisegundos. Que dos reservas simultáneas no sobrevendan, que una restricción exista o que una transacción sea atómica, no: esos comportamientos no están en el código del módulo sino en la infraestructura.

🔬 **El detalle:** Por eso una suite con solo pruebas de módulo puede tener cobertura alta y no cubrir los riesgos de datos.

### 3. 🟢 ¿Por qué una restricción de base solo se prueba contra una base real?

⏱️ **30 segundos:** Porque la restricción la aplica el motor; un mock no tiene restricciones y acepta cualquier cosa que el código le pase.

🗣️ **2 minutos:** Si alguien borra el `CHECK` en una migración, todas las pruebas con mocks siguen en verde. Una prueba de integración que intenta violar la restricción y espera el error se pone roja. Lo mismo vale para índices únicos, claves foráneas y niveles de aislamiento.

🔬 **El detalle:** La base de prueba debe ser del mismo motor y versión mayor que producción; SQLite en lugar de PostgreSQL cambia justo esa semántica.

### 4. 🟢 ¿Qué evidencias combinadas sostienen que un monolito es modular?

⏱️ **30 segundos:** Imports permitidos, escritura de cada tabla solo por su dueño, contratos pequeños entre módulos y cambios que se quedan dentro de un módulo.

🗣️ **2 minutos:** Cada una la aporta una herramienta distinta: reglas arquitectónicas para imports, permisos de base o análisis de consultas para la escritura, revisión del contrato para su tamaño, e historial de cambios para la contención. Una sola en verde no basta: los imports pueden estar limpios y los datos mezclados.

🔬 **El detalle:** La contención de cambios es la evidencia más cercana al objetivo real de la modularidad, y la única que no se obtiene de una prueba sino del historial.

### 5. 🟢 ¿Qué es una prueba de caracterización?

⏱️ **30 segundos:** Una prueba que registra el comportamiento actual de un código, correcto o no, para detectar cualquier cambio mientras se refactoriza.

🗣️ **2 minutos:** No afirma que el comportamiento sea el deseado; afirma que no cambió. Sirve en código legado sin pruebas, donde antes de mover nada hace falta una red de seguridad. Cuando el comportamiento se corrige a propósito, la prueba se actualiza con esa decisión explícita.

🔬 **El detalle:** Es temporal por naturaleza: una vez aisladas las reglas, se reemplaza por pruebas que expresan la intención.

### 6. 🟢 ¿Para qué sirven los E2E en esta estrategia?

⏱️ **30 segundos:** Para comprobar que la composición completa funciona —configuración, cableado, rutas— en unos pocos flujos críticos.

🗣️ **2 minutos:** Un E2E de checkout demuestra que el sistema arrancado con su configuración real completa una compra. No es el lugar para probar cada regla: es lento, frágil y, cuando falla, no dice qué parte falló. Pocos, estables y sobre los flujos que más importan.

🔬 **El detalle:** Un E2E intermitente no se ignora ni se reintenta en silencio: o se estabiliza o se elimina, porque enseña al equipo a desconfiar del rojo.

### 7. 🟡 ¿Por qué contar cobertura como evidencia de modularidad es una simplificación peligrosa?

⏱️ **30 segundos:** Porque la cobertura dice qué líneas se ejecutaron, no qué módulo escribe qué tabla ni qué imports cruzan límites.

🗣️ **2 minutos:** Un `UPDATE` de `orders` sobre las reservas de `inventory` puede estar cubierto al cien por cien por una prueba con mocks que confirma que se llama. La cobertura no distingue si el acceso respeta el límite. La modularidad se mide con reglas de dependencia, permisos y contención de cambios.

🔬 **El detalle:** Una cobertura baja sí es una señal útil; una alta no demuestra nada sobre límites.

### 8. 🟡 ¿Cuándo usarías una prueba de caracterización temporal porque el legado impide aislar una regla?

⏱️ **30 segundos:** Cuando la regla está mezclada con persistencia y otros módulos, y no se puede probar sola sin antes refactorizar.

🗣️ **2 minutos:** Antes de extraer la lógica de cancelación de un método de 400 líneas, grabo sus entradas y salidas actuales contra la base real. Con esa red, muevo la regla a su módulo y la pruebo aislada. Cuando la prueba nueva cubre la intención, retiro la caracterización.

🔬 **El detalle:** Sin fecha de retiro, las pruebas de caracterización petrifican comportamientos erróneos y frenan su corrección.

### 9. 🟡 ¿Qué prueba habría detectado la sobreventa del capítulo de concurrencia, y por qué los mocks no?

⏱️ **30 segundos:** Una prueba de concurrencia real contra la base: muchos hilos o goroutines reservando a la vez la misma unidad y comprobando reservas concedidas frente a stock.

🗣️ **2 minutos:** Es exactamente el arnés del capítulo de concurrencia: veinte reservas simultáneas sobre cinco unidades. Con un mock, cada llamada ve el valor que el mock devuelve, sin interleavings ni locks; no hay carrera posible. La anomalía existe entre transacciones en la base, y solo ahí se reproduce.

🔬 **El detalle:** Se repite varias veces y se afirma sobre el invariante —reservas ≤ stock— y no sobre un número exacto de éxitos.

### 10. 🟡 ¿Cómo probarías que un rolling deployment no se rompe con una migración?

⏱️ **30 segundos:** Ejecutando la migración sobre una base de prueba y corriendo contra ella la suite de la versión anterior y la de la nueva.

🗣️ **2 minutos:** Si la suite de la versión N falla después de la migración de N+1, el rollout romperá. La prueba se automatiza en CI con la imagen de la versión desplegada. Así la compatibilidad de esquema deja de depender de la memoria de quien revisa la migración.

🔬 **El detalle:** Es la aplicación más directa de expand-contract a las pruebas: el esquema intermedio tiene que servir a dos versiones, y se comprueba con las dos.

### 11. 🟡 ¿Qué detecta una regla arquitectónica y qué escritura cruzada se le escapa?

⏱️ **30 segundos:** Detecta dependencias de código prohibidas, como un import de `orders` hacia el paquete interno de `inventory`; se le escapa un acceso por SQL a la tabla de otro módulo.

🗣️ **2 minutos:** Si `orders` ejecuta `UPDATE inventory.reservations ...` como texto, no hay import que la regla vea. El límite de código está limpio y el de datos, roto. Para ese caso hacen falta permisos de base por módulo o una prueba que analice qué tablas toca cada módulo.

🔬 **El detalle:** Las reglas estáticas son baratas y conviene tenerlas; el error es darlas por prueba completa de modularidad.

### 12. 🟡 ¿Cómo complementan los permisos de base a una regla de imports?

⏱️ **30 segundos:** Hacen que la escritura cruzada falle en ejecución: si `orders` usa un rol que no puede escribir las tablas de `inventory`, el `UPDATE` directo da error.

🗣️ **2 minutos:** Con un rol o esquema por módulo, la base aplica el límite de datos igual que el compilador aplica el de código. En pruebas de integración, el error de permisos aparece antes de producción. Cuesta configurar roles y conexiones por módulo, y a veces un pool por rol.

🔬 **El detalle:** Es la misma idea que el `REVOKE` del capítulo de propiedad de datos, usada como evidencia en la suite.

### 13. 🟡 ¿Qué medirías para saber si los módulos contienen los cambios en la práctica?

⏱️ **30 segundos:** Cuántos cambios de negocio tocan un solo módulo frente a varios, a partir del historial de commits o pull requests.

🗣️ **2 minutos:** Si un cambio de reglas de reserva suele tocar `inventory` y nada más, el límite contiene. Si la mitad de los cambios cruzan tres módulos, el límite está mal puesto o la API es demasiado grande. Es evidencia de resultado, no de estructura, y ninguna prueba automática la produce.

🔬 **El detalle:** Se mide sobre cambios de negocio, no sobre refactors masivos, que por naturaleza tocan todo.

### 14. 🟡 ¿Cuándo es útil un mock y cuándo engaña?

⏱️ **30 segundos:** Es útil para forzar respuestas de un colaborador —un error, un timeout— y verificar cómo decide el código; engaña cuando se usa para probar algo que solo existe en el colaborador real.

🗣️ **2 minutos:** Simular que `payments` devuelve un resultado incierto y comprobar que `orders` deja el pedido pendiente es una buena prueba. Simular el repositorio para «probar» que la reserva no sobrevende no prueba nada: el mock no tiene concurrencia ni restricciones.

🔬 **El detalle:** La regla práctica: se simula lo que se posee y se quiere controlar; lo que da la garantía, se usa de verdad.

### 15. 🟡 ¿Cómo documentarías una excepción a una regla arquitectónica para que no se vuelva permanente?

⏱️ **30 segundos:** En la propia regla, con dueño, motivo y fecha de caducidad, de modo que la prueba falle cuando la fecha pase.

🗣️ **2 minutos:** Una excepción de lectura de reportes sobre `inventory/internal/sql` lleva quién la pidió, por qué y hasta cuándo. Al vencer, la suite se pone roja y obliga a renovarla o retirarla con una decisión. Sin fecha, la excepción se convierte en la frontera real sin que nadie lo decida.

🔬 **El detalle:** Algunas herramientas permiten congelar las violaciones existentes y fallar solo con las nuevas; es útil para empezar, no para quedarse.

### 16. 🟡 ¿Qué haces con un E2E que falla de forma intermitente?

⏱️ **30 segundos:** Lo investigo o lo retiro, pero no lo dejo reintentándose en silencio: un rojo que se ignora enseña a ignorar todos.

🗣️ **2 minutos:** Busco la causa: esperas fijas, datos compartidos entre pruebas, dependencia de orden o un recurso externo. Si revela una carrera real del sistema, es valioso y se convierte en prueba de integración determinista. Si es fragilidad de la prueba, se corrige o se elimina y se cubre el riesgo más cerca.

🔬 **El detalle:** Contar la tasa de intermitencia por prueba permite priorizar: pocas pruebas suelen causar casi todos los falsos rojos.

### 17. 🟡 ¿Qué propiedades distintas cubren ArchUnit/Testcontainers en Java y el race detector en Go?

⏱️ **30 segundos:** ArchUnit cubre la dirección de dependencias entre paquetes; Testcontainers, el comportamiento real de la base; el race detector de Go, accesos concurrentes a memoria dentro del proceso.

🗣️ **2 minutos:** Son tres propiedades sin solapamiento: estructura del código, semántica de datos y carreras de memoria. Ninguna cubre las carreras entre réplicas sobre una fila, que requieren concurrencia real contra la base. Elegir una no exime de las otras.

🔬 **El detalle:** `go test -race` solo detecta carreras que ocurren durante la ejecución de la prueba; una carrera en un camino que la prueba no recorre pasa inadvertida.

### 18. 🟠 ¿Qué falso positivo comparten mocks de ORM en Node/TypeScript y Python frente a una base real?

⏱️ **30 segundos:** Una prueba verde para una consulta que en la base real fallaría o devolvería otra cosa: restricciones ausentes, SQL inválido para el motor, orden o aislamiento distintos.

🗣️ **2 minutos:** Con el ORM simulado, la prueba confirma que se llamó al método correcto con ciertos argumentos. No sabe si la consulta generada es válida en PostgreSQL, si respeta un índice único o qué ve bajo concurrencia. El verde es sobre la llamada, no sobre el efecto.

🔬 **El detalle:** El mismo falso positivo aparece al usar una base distinta a la de producción, como SQLite en memoria: el código pasa contra una semántica que producción no tiene.

### 19. 🟠 Hubo tres incidentes en el trimestre y ninguno rompió una prueba antes. ¿Cómo reorganizarías la suite?

⏱️ **30 segundos:** Empezaría por los incidentes: para cada uno, escribo la prueba más cercana que lo habría puesto rojo, y con ese criterio reviso qué más falta.

🗣️ **2 minutos:** Sobreventa: prueba de concurrencia contra la base. Rollout roto: la suite de la versión desplegada corriendo tras la migración nueva. Escritura cruzada: permisos por módulo y regla arquitectónica. Luego mapeo los riesgos críticos restantes a pruebas y retiro las que no pueden fallar por ninguno.

🔬 **El detalle:** Cada prueba nueva se valida reintroduciendo el defecto: si no se pone roja con el incidente reproducido, no es la prueba correcta.

### 20. 🟠 La suite tarda 40 minutos y los desarrolladores la saltan. ¿Qué recortarías sin perder evidencia?

⏱️ **30 segundos:** Las pruebas que no pueden fallar por ningún riesgo, los E2E que duplican pruebas más cercanas y las esperas fijas; y paralelizaría la integración.

🗣️ **2 minutos:** Mido tiempo por prueba y qué riesgo cubre cada una. Los E2E que prueban reglas ya cubiertas en módulo se retiran; las pruebas con mocks que solo repiten la implementación, también. La integración con base real se paraleliza con bases aisladas por hilo. Así la suite rápida corre en cada commit y la lenta, antes de fusionar.

🔬 **El detalle:** Una suite que nadie ejecuta no da evidencia; reducirla con criterio aumenta la cobertura efectiva.

### 21. 🟠 Una prueba de integración pasa con la imagen de base de CI y falla en producción. ¿Qué diferencia buscarías?

⏱️ **30 segundos:** Versión del motor, configuración —aislamiento, collation, zona horaria, extensiones— y volumen o forma de los datos.

🗣️ **2 minutos:** Una versión menor distinta cambia planes o funciones; una collation distinta cambia el orden y la unicidad de textos; el aislamiento por defecto cambia qué anomalías aparecen. Y con diez filas de prueba no aparecen los planes ni los locks de millones. Alineo imagen y configuración con producción y añado datos representativos donde el riesgo lo pida.

🔬 **El detalle:** Fijar la imagen exacta en CI, sin `latest`, evita que la diferencia aparezca sola un día cualquiera.

### 22. 🟠 Quieres introducir una regla arquitectónica en un legado con 300 violaciones. ¿Cómo lo harías sin bloquear al equipo?

⏱️ **30 segundos:** Congelando las violaciones existentes y haciendo que la regla falle solo con las nuevas, con un plan para reducir las viejas por módulo.

🗣️ **2 minutos:** Registro las 300 como línea base; desde ese día, una violación nueva rompe la suite. Las existentes se retiran cuando se toca el código cercano o en un plan por módulo con dueño. El equipo sigue trabajando, la deuda deja de crecer y la cifra baja de forma visible.

🔬 **El detalle:** La línea base congelada tiene fecha de revisión; si no baja, la regla está mal planteada o el límite es el equivocado.

### 23. 🟠 Un equipo quiere cambiar todos los mocks por Testcontainers y otro quiere mantener la suite rápida. ¿Cómo decidirías?

⏱️ **30 segundos:** Por riesgo: base real donde el riesgo vive en la base, mocks donde se prueba la decisión del código; ninguna de las dos cosas para todo.

🗣️ **2 minutos:** Reemplazar todos los mocks alarga la suite sin ganar evidencia en las reglas puras. Mantenerlos todos deja sin prueba restricciones y carreras. Clasifico las pruebas por riesgo cubierto: las de persistencia pasan a base real, las de lógica siguen rápidas. Mido el tiempo resultante y lo ajusto con paralelización.

🔬 **El detalle:** Los dos equipos suelen tener razón en su mitad; el mapa de riesgos convierte la discusión de gustos en una lista concreta.

### 24. 🟠 ¿Qué criterio te diría que la suite ya cubre los riesgos críticos y no hay que seguir ampliándola?

⏱️ **30 segundos:** Que cada riesgo crítico del mapa tenga una prueba que se ponga roja al reintroducir el defecto, y que las pruebas nuevas solo dupliquen evidencia existente.

🗣️ **2 minutos:** Reviso el mapa: reglas, restricciones, carreras, límites, migraciones y composición, cada uno con su prueba validada por mutación o por reproducción del incidente. Si una prueba adicional no cubre un riesgo nuevo, añade tiempo sin añadir evidencia. Reviso el mapa cuando aparece un incidente sin prueba roja previa.

🔬 **El detalle:** El criterio se expresa como mapa de riesgos con fecha, no como porcentaje de cobertura.

## 🎤 Respuestas de la simulación

### S1. 🟢 ¿Dónde comienza una garantía transaccional?

⏱️ **30 segundos:** En una transacción real sobre los recursos que participan: empieza con el `BEGIN` y cubre lo que se escribe con esa conexión hasta el `COMMIT`.

🗣️ **2 minutos:** El nombre del método o una anotación no definen la garantía; lo hace qué conexión se usa y qué recursos están dentro. Pedido y reserva en la misma base y conexión se confirman juntos; una llamada al proveedor de pagos queda fuera aunque esté en el mismo método. Identifico conexión, commit y rollback antes de afirmar atomicidad.

🔬 **El detalle:** Las trampas típicas —auto-invocación en Java, cliente global en Node, `db` en lugar de `tx` en Go— sacan escrituras de la transacción sin avisar.

### S2. 🟢 ¿Qué controla una restricción única de operación?

⏱️ **30 segundos:** Que una misma operación no produzca su efecto dos veces: la base rechaza la segunda inserción con la misma clave.

🗣️ **2 minutos:** Una restricción única sobre la clave de idempotencia, reclamada en la misma transacción que el efecto, convierte un reintento en una lectura del resultado guardado. No depende de una consulta previa, que tendría carrera, sino de la base. Protege contra repeticiones, no contra carreras entre operaciones distintas.

🔬 **El detalle:** Para carreras entre intenciones distintas hace falta otra defensa, como un `UPDATE` condicional sobre el stock.

### S3. 🟢 ¿Qué diferencia evento en memoria de trabajo durable?

⏱️ **30 segundos:** El evento en memoria se pierde si el proceso cae; el trabajo durable se escribe en la misma transacción que el cambio y sobrevive.

🗣️ **2 minutos:** Un evento en memoria sirve para observadores prescindibles; si el efecto es obligatorio, como avisar al cliente, hace falta una fila de trabajo confirmada con el pedido y un worker que la procese con lease y reintentos. Durable no significa una sola vez: la deduplicación del efecto lo garantiza.

🔬 **El detalle:** La pregunta que decide es si perder el efecto es aceptable.

### S4. 🟢 ¿Qué debe medir un SLO de compra?

⏱️ **30 segundos:** La experiencia de compra en el borde: que las solicitudes válidas reciban respuesta correcta dentro de un plazo, y que los pedidos lleguen a un estado terminal.

🗣️ **2 minutos:** Se mide donde lo vive el usuario, no por módulo: latencia y tasa de éxito de checkout. Conviene separar aceptación —identificación o rechazo en un segundo— de completitud —pedido terminal en minutos—. Las métricas internas explican qué módulo consume el presupuesto, pero no sustituyen al SLO del flujo.

🔬 **El detalle:** Un SLO que solo mide respuestas rápidas puede cumplirse con pedidos atascados en pendiente.

### S5. 🟡 ¿Cómo detectas lost update en stock?

⏱️ **30 segundos:** Comparando reservas confirmadas con el stock inicial y buscando escrituras de valores calculados desde lecturas viejas, casi simultáneas, desde réplicas distintas.

🗣️ **2 minutos:** Si se entregaron siete reservas con cinco unidades y ninguna restricción saltó, las escrituras pusieron valores positivos calculados a partir de una lectura obsoleta. Lo confirmo con marcas de tiempo cercanas y con una prueba concurrente contra la base real. Descarto antes otros escritores, como ajustes manuales del backoffice.

🔬 **El detalle:** Un `CHECK (available >= 0)` no detecta esta sobreventa, porque ningún valor escrito es negativo.

### S6. 🟡 ¿Cuándo eliges bloqueo pesimista?

⏱️ **30 segundos:** Cuando la contención es alta y los conflictos optimistas repetidos cuestan más que esperar el bloqueo.

🗣️ **2 minutos:** Con pocos conflictos, el control optimista o un `UPDATE` condicional son baratos. Si un SKU caliente produce conflictos en un tercio de las reservas, los reintentos multiplican la carga y bloquear la fila durante la transacción puede ser más eficiente. Mido la tasa de conflictos y las esperas antes de decidir, y mantengo la transacción corta.

🔬 **El detalle:** Los bloqueos en varias filas se toman en un orden fijo, por ejemplo por SKU, para evitar interbloqueos.

### S7. 🟡 ¿Qué debe hacer un retry tras conflicto optimista?

⏱️ **30 segundos:** Releer, volver a decidir con el estado actual y reintentar solo si sigue teniendo sentido, con límite y jitter.

🗣️ **2 minutos:** Un conflicto de versión dice que otro cambió la fila; repetir la misma escritura sin releer pisaría su cambio. Se relee, se reaplica la regla y se reintenta unas pocas veces con espera aleatoria. Si la contención es sostenida, el problema es de diseño y los reintentos solo lo agravan.

🔬 **El detalle:** Si el reintento implica un efecto externo, primero se consulta por la clave para no duplicarlo.

### S8. 🟡 ¿Cómo limitas una cola interna?

⏱️ **30 segundos:** Con una capacidad máxima y una política cuando se llena: rechazar, bloquear al productor o degradar.

🗣️ **2 minutos:** Una cola sin límite convierte un pico en memoria agotada o en latencia que nadie ve hasta que el proceso cae. Con un límite, la presión se hace visible: el productor recibe un rechazo o espera, y la métrica de ocupación avisa. Si el trabajo es obligatorio, va a una tabla durable con control de ritmo en lugar de a memoria.

🔬 **El detalle:** El límite se dimensiona con la tasa de salida real del consumidor, no con un número redondo.

### S9. 🟡 ¿Qué implica afirmar entrega at-least-once?

⏱️ **30 segundos:** Que el efecto puede ejecutarse más de una vez y el consumidor debe deduplicarlo o ser idempotente.

🗣️ **2 minutos:** Una tabla de trabajo o un broker garantizan que el mensaje no se pierde, pero un worker que muere tras actuar y antes de marcar provoca un segundo intento. Afirmar *at-least-once* compromete a tener una clave del efecto y a que el destino la respete. Si el canal no la acepta, puede haber duplicados visibles, y hay que decirlo.

🔬 **El detalle:** «Exactamente una vez» extremo a extremo casi nunca existe; se consigue efecto único con deduplicación.

### S10. 🟡 ¿Qué perfilas antes de escalar CPU?

⏱️ **30 segundos:** Dónde espera la petición: traza por etapa primero y perfil de CPU solo si la traza señala al proceso.

🗣️ **2 minutos:** Si el tiempo se va esperando conexión o un lock, más CPU no ayuda. Si la traza muestra cómputo en el proceso —serialización, cálculo—, entonces perfilo con JFR, `pprof` o equivalente y busco el hotspot. Escalar CPU sin saber si es el recurso limitante es gastar sin resolver.

🔬 **El detalle:** Un perfil de CPU impecable de una aplicación que espera la base optimiza lo que no importa.

### S11. 🟡 ¿Cómo afecta una caché a la garantía de lectura?

⏱️ **30 segundos:** La relaja: una lectura de caché puede estar desfasada, así que solo sirve para lo que tolera esa obsolescencia.

🗣️ **2 minutos:** Cachear el catálogo acepta segundos de retraso en precios o descripciones; cachear el stock para decidir una reserva rompe la invariante, porque se decidiría con un dato viejo. Cada caché necesita dueño, clave, TTL o invalidación y un comportamiento ante fallo. La garantía de lectura exacta queda en la base.

🔬 **El detalle:** Una caché también puede servir datos viejos tras una rebaja si su invalidación depende solo del TTL.

### S12. 🟡 ¿Qué riesgo tiene aumentar el pool de conexiones?

⏱️ **30 segundos:** Que traslade la espera a la base: más conexiones contra un límite fijo empeoran la contención en lugar de resolverla.

🗣️ **2 minutos:** Si el pool se agota porque cada petición retiene la conexión mucho tiempo, subirlo solo abre más sesiones que compiten por la misma base, y con varias réplicas se superan sus límites. Lo eficaz es reducir el tiempo de uso —transacciones cortas, sin red dentro— y dimensionar los pools contra la base.

🔬 **El detalle:** Conexiones ocupadas ≈ peticiones por segundo × tiempo que cada una retiene la conexión.

### S13. 🟡 ¿Qué significa rollback de código?

⏱️ **30 segundos:** Reemplazar el artefacto por la versión anterior; no revierte los datos que la versión nueva ya escribió o transformó.

🗣️ **2 minutos:** El código vuelve atrás con un despliegue; el esquema y los datos no. Si la versión nueva borró una columna o convirtió valores, la anterior puede no funcionar con ellos. Por eso el rollback de código solo es seguro mientras la versión vieja entienda los datos actuales, y la contracción del esquema se deja para cuando ya no hace falta volver.

🔬 **El detalle:** Tras una transformación destructiva, la única vuelta atrás es restaurar un backup con pérdida de ventana, o corregir hacia adelante.

### S14. 🟡 ¿Cómo probarías una migración compatible?

⏱️ **30 segundos:** Ejecutándola con la versión vieja y la nueva conviviendo sobre el esquema intermedio, y comprobando que ambas funcionan.

🗣️ **2 minutos:** La prueba aplica la expansión, arranca la versión N y la N+1 contra ese esquema y ejecuta sus flujos críticos. También prueba el backfill reanudable y el rollback del código mientras el esquema sigue expandido. Solo cuando pasa, la migración es compatible con un rolling deployment.

🔬 **El detalle:** Probar solo la versión nueva contra el esquema final no detecta el fallo de las réplicas viejas durante el despliegue.

### S15. 🟡 ¿Qué aporta correlación entre logs y trazas?

⏱️ **30 segundos:** Permite seguir una operación concreta por todos los hilos y módulos que atraviesa, y saber qué etapa consumió el tiempo.

🗣️ **2 minutos:** Con un `request_id` y un `order_id` en logs y trazas, un incidente deja de ser «hubo timeouts» y pasa a ser «este pedido esperó 2 s por una conexión que retenían los reportes». Las métricas dicen que algo va mal; la correlación dice qué y dónde. Los identificadores únicos van en logs y trazas, no como etiquetas de métrica.

🔬 **El detalle:** El contexto se pierde en cada salto de hilo o executor si nadie lo copia.

### S16. 🟡 ¿Qué limita un bulkhead dentro del monolito?

⏱️ **30 segundos:** El consumo de un recurso compartido por un workload, para que uno secundario no agote lo que necesita checkout.

🗣️ **2 minutos:** Un cupo de conexiones para reportes, colas acotadas por tipo de trabajo o límites de lote reparten capacidad dentro del proceso. Si los reportes llenan su cupo, se rechaza su sobrante y checkout conserva conexiones. Separa capacidad, no código, y cuesta capacidad reservada que en días tranquilos queda sin usar.

🔬 **El detalle:** Si el cupo desperdicia demasiado o el runtime no permite aislar, el siguiente paso es otro proceso o una réplica de lectura.

### S17. 🟡 ¿Cómo compararías transacción declarativa Java y sql.Tx de Go?

⏱️ **30 segundos:** La anotación de Java aplica la transacción mediante un proxy y es fácil salirse sin saberlo; `sql.Tx` en Go es explícito: solo está dentro lo que usa `tx`.

🗣️ **2 minutos:** En Spring, una auto-invocación, otro hilo o una conexión distinta quedan fuera del proxy aunque el método esté anotado. En Go, el error típico es usar `db.Exec` en lugar de `tx.Exec` dentro de la operación. La prueba que detecta ambos es la misma: provocar un fallo tras la segunda escritura y comprobar desde otra conexión que la primera no quedó.

🔬 **El detalle:** Lo explícito cuesta más código y hace más visible la frontera; lo declarativo es cómodo y esconde sus bordes.

### S18. 🟡 ¿Qué comparten tareas async de Python y Promises de Node?

⏱️ **30 segundos:** Las dos deciden cuándo corre el trabajo, no si sobrevive: viven en memoria y se pierden si el proceso cae.

🗣️ **2 minutos:** Una tarea `asyncio` o una `Promise` lanzada sin esperar es trabajo que nadie registra. Si el efecto es obligatorio, omitir `await` o hacer `create_task` sin persistir es fire-and-forget con pérdida posible. La durabilidad la da escribir el trabajo en un almacenamiento que comparta commit con el cambio de negocio.

🔬 **El detalle:** Tampoco limitan por sí solas la concurrencia: sin semáforo o cola acotada, un pico lanza miles de tareas.

### S19. 🟡 ¿Qué prueba complementa un mock de repositorio?

⏱️ **30 segundos:** Una prueba de integración contra la base real, que ejercite SQL, restricciones y aislamiento de verdad.

🗣️ **2 minutos:** Un mock de repositorio prueba que el código llama al repositorio; no prueba que la restricción exista, que la consulta sea correcta ni cómo se comportan dos transacciones concurrentes. Testcontainers u otra base efímera con la misma imagen que producción cubre esos riesgos. Los mocks siguen siendo útiles para forzar errores.

🔬 **El detalle:** Una prueba de concurrencia real, repetida, es la única que habría detectado la sobreventa.

### S20. 🟡 ¿Qué diferencia readiness de proceso vivo?

⏱️ **30 segundos:** Readiness dice si la instancia puede recibir tráfico; liveness, si el proceso debe reiniciarse porque está roto.

🗣️ **2 minutos:** Una instancia sin conexión a la base puede no estar lista, pero reiniciarla no arregla nada. Si liveness comprueba dependencias externas, una caída de la base provoca reinicios en cadena y agrava el incidente. Liveness debería comprobar solo el propio proceso; las dependencias, como mucho, readiness.

🔬 **El detalle:** Durante una saturación, reiniciar réplicas concentra el tráfico en las que quedan y empeora todo.

### S21. 🟠 ¿Una prueba end-to-end verde demuestra modularidad?

⏱️ **30 segundos:** No: demuestra que la composición funciona, no quién escribe cada tabla ni si los cambios quedan contenidos.

🗣️ **2 minutos:** Un E2E pasa aunque `orders` actualice por SQL las reservas de `inventory`. La modularidad se sostiene con varias evidencias: reglas de imports, permisos de base que impiden escrituras ajenas, contratos pequeños y cambios que se quedan en un módulo. El E2E cubre la composición, no los límites.

🔬 **El detalle:** Además, los E2E son lentos y localizan mal los fallos; conviene tener pocos.

### S22. 🟠 ¿Restaurar un backup siempre deshace una compra?

⏱️ **30 segundos:** No: restaura la base, pero los efectos externos —cobros, correos— siguen ocurridos y hay que reconciliarlos.

🗣️ **2 minutos:** Si se restaura la base a un punto anterior, una compra autorizada en el proveedor puede desaparecer de los registros locales mientras el cobro sigue hecho. La recuperación incluye reconciliar con el proveedor, las claves de idempotencia y los avisos enviados. Por eso se ensaya la restauración completa, no solo la copia.

🔬 **El detalle:** Restaurar también puede hacer retroceder claves, y un reintento posterior podría duplicar un cobro si no se casan con el proveedor.

### S23. 🟠 ¿Un job exactamente una vez es una afirmación suficiente?

⏱️ **30 segundos:** No: lo que se puede garantizar es que el trabajo no se pierde y que su efecto se deduplica.

🗣️ **2 minutos:** Con réplicas, reinicios y reintentos, un job puede ejecutarse dos veces; un lease en la base reduce las ejecuciones simultáneas, pero un worker lento con el lease vencido puede coincidir con otro. Lo que da efecto único es una clave del efecto que el destino respete. Afirmar «exactamente una vez» sin eso es una promesa que el sistema no cumple.

🔬 **El detalle:** La afirmación correcta es «al menos una vez, con efecto idempotente».

### S24. 🟠 ¿Una transacción más grande siempre es más segura?

⏱️ **30 segundos:** No: retiene locks y conexiones, aumenta conflictos y no alcanza a efectos externos.

🗣️ **2 minutos:** Una transacción que incluye reporting o una llamada de red bloquea recursos mientras espera y degrada a quien no depende de esa espera. Tampoco hace atómico el pago remoto. La transacción se dibuja alrededor de la invariante mínima; lo demás se registra dentro y se ejecuta después.

🔬 **El detalle:** Un nivel de aislamiento más fuerte tiene el mismo matiz: más garantía a cambio de más esperas y abortos.

### S25. 🟠 ¿Un canary sin errores permite contraer el schema?

⏱️ **30 segundos:** No por sí solo: hay que confirmar que ninguna versión soportada lee lo viejo, que el backfill convergió y que la ventana de rollback cerró.

🗣️ **2 minutos:** Un canary sin errores muestra que la versión nueva funciona, no que la vieja ya no exista en ningún sitio. Antes de contraer, compruebo que no quedan réplicas, jobs ni reportes leyendo la columna vieja, que los datos convergieron y que ya no hace falta volver a la versión anterior. La contracción es el único paso irreversible.

🔬 **El detalle:** Un reporte que lee la base directamente es el consumidor que más se olvida.

### S26. 🟠 En E1, ¿qué verificas al añadir réplicas y qué corriges primero?

⏱️ **30 segundos:** Verifico dónde vive la sesión, cómo se reclaman los jobs y si el canal deduplica; corrijo primero la sesión y la ejecución duplicada de avisos.

🗣️ **2 minutos:** Con cuatro réplicas, la sesión en memoria se pierde al cambiar de instancia, y un job programado corre en cada réplica y envía dos avisos. Muevo la sesión a un almacén compartido y hago que el job reclame el trabajo con lease en la base y deduplique por clave. Lo pruebo con cambios de réplica y ejecuciones concurrentes antes de escalar más.

🔬 **El detalle:** Escalar no crea garantía de ejecución única; hay que construirla con estado compartido y claves.

### S27. 🟠 En E2, ¿cómo contienes la migración que rompe réplicas antiguas?

⏱️ **30 segundos:** Detengo el rollout, no ejecuto más pasos destructivos y restauro la compatibilidad antes de pensar en revertir el binario.

🗣️ **2 minutos:** Primero contengo: pauso el despliegue y evito que más réplicas nuevas cambien el esquema. Si la columna ya no existe, revertir el código no basta; la opción rápida suele ser volver a añadirla y rellenarla desde los datos disponibles, o avanzar la versión nueva a todas las réplicas si es compatible. Después rediseño la migración con expand-contract.

🔬 **El detalle:** Separar el rollback del binario de la reparación del esquema evita empeorar el incidente destruyendo más datos.

### S28. 🟠 En E3, ¿qué haces con el último stock en competencia?

⏱️ **30 segundos:** La base decide: un `UPDATE` condicional o un bloqueo de fila hace que una reserva gane y la otra reciba sin stock.

🗣️ **2 minutos:** Dos `CreateOrder` que leen «queda 1» y escriben «queda 0» venden dos veces. La corrección es que la comprobación y la resta ocurran juntas en la base, o que una transacción bloquee la fila hasta confirmar. Lo verifico con un ensayo concurrente reproducible y compruebo también el comportamiento del reintento del perdedor.

🔬 **El detalle:** Un mutex en el proceso no sirve con varias réplicas: cada una tiene el suyo.

### S29. 🟠 En E4, ¿cómo proteges compra cuando crece la cola de avisos?

⏱️ **30 segundos:** Aíslo los recursos de compra frente a los avisos y controlo la admisión de trabajo nuevo, sin descartar avisos comprometidos.

🗣️ **2 minutos:** Mido las tasas de entrada y salida de avisos y dónde compiten con compra: conexiones, hilos o CPU. Doy a los avisos un cupo propio y un límite de concurrencia, y mantengo su entrega durable con alerta por edad. La compra conserva sus recursos y el aviso se retrasa de forma visible, sin perderse.

🔬 **El detalle:** Escalar el consumidor de avisos solo ayuda si el cuello es su capacidad, no el proveedor de correo.

### S30. 🟠 En E5, ¿cómo decides el siguiente ensayo de rendimiento?

⏱️ **30 segundos:** Mido consulta y contención que explican la latencia.

🗣️ **2 minutos:** CPU baja y pool saturado sugieren espera, pero confirmo con trazas y DB antes de aumentar réplicas.

🔬 **El detalle:** Comparo bajo carga equivalente y con invariantes verificadas.

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [08 — Simulación de entrevista: Datos, ejecución y operación](08-simulacion-de-entrevista.md).

**Siguiente:** [01 — Anatomía y evidencia del monolito distribuido](../04-monolito-distribuido/01-anatomia-y-evidencia-del-monolito-distribuido.md).
