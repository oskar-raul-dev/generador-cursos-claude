# 10 — Respuestas

> Solucionario centralizado del bloque `03-datos`. Cada respuesta en tres capas:
> **⏱️ 30 segundos**, **🗣️ 2 minutos** y **🔬 El detalle**. Los enunciados están copiados
> literalmente de su capítulo.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:**
[01](#01--cap-pacelc-y-consistencia) · [02](#02--transacciones-aislamiento-y-bloqueo) ·
[03](#03--relacional-nosql-y-dynamodb) · [04](#04--sharding-y-particionado) ·
[05](#05--réplicas-y-lag) · [06](#06--cqrs) · [07](#07--caché) ·
[08](#08--persistencia-políglota-y-multi-tenant) · [09 — escenarios](#09--simulación-escenarios-de-diseño)

---

# 01 — CAP, PACELC y consistencia

**01 → 1. ¿Qué significan las tres letras de CAP?**

⏱️ Consistencia (linealizabilidad), disponibilidad (todo nodo vivo responde) y tolerancia a
particiones (sigue funcionando aunque se pierdan mensajes entre nodos).
🗣️ La C es que toda lectura ve la última escritura confirmada, como si hubiera una sola copia. La
A es binaria y no dice nada sobre latencia: responder lento sigue siendo disponible. La P no es
opcional, porque las redes se parten.
🔬 El enunciado correcto: cuando hay partición, eliges entre C y A. Sin partición, CAP no dice
nada, y por eso hace falta PACELC.

**01 → 2. ¿Qué añade PACELC a CAP?**

⏱️ Cubre el caso normal: sin partición, eliges entre latencia y consistencia.
🗣️ Se lee así: si hay partición (P), elige entre disponibilidad (A) y consistencia (C); si no (E,
de *else*), elige entre latencia (L) y consistencia (C). La segunda mitad es la que importa,
porque las particiones son raras y el resto del tiempo es el 99,9 % de la vida del sistema.
🔬 El razonamiento: para que una lectura vea siempre la última escritura, esa escritura tuvo que
confirmarse en varias réplicas antes de responder — una ida y vuelta de red en cada escritura. La
consistencia cuesta latencia siempre.

**01 → 3. Nombra las cuatro garantías de sesión.**

⏱️ Read-your-writes, monotonic reads, monotonic writes y writes-follow-reads.
🗣️ Ves tus propias escrituras; no ves el tiempo ir hacia atrás entre dos lecturas; tus escrituras
se aplican en el orden en que las hiciste; y lo que escribes tras leer se ordena después de lo
leído.
🔬 Son mucho más baratas que la linealizabilidad y casi siempre son el requisito real: el usuario
no necesita que todo el mundo vea su pedido al instante, necesita verlo él.

**01 → 4. ¿Qué es la consistencia causal?**

⏱️ Si A causó B, todos ven A antes que B; las operaciones no relacionadas pueden verse en
cualquier orden.
🗣️ Es el punto dulce: evita las anomalías que el usuario nota —ver una respuesta antes que el
comentario— sin el coste de ordenar todo globalmente.
🔬 Es más fuerte que la eventual y más débil que la secuencial. Se implementa con relojes
vectoriales o con dependencias explícitas entre operaciones.

**01 → 5. ¿Qué es un quórum y qué condición da consistencia fuerte?**

⏱️ El número de réplicas que deben confirmar. Con N réplicas, si `W + R > N` hay consistencia
fuerte.
🗣️ La condición garantiza que el conjunto de réplicas que leo solapa con el conjunto que confirmó
la última escritura, así que al menos una tiene el dato actual. Con `W + R ≤ N` puede no solapar y
la consistencia es eventual.
🔬 Lo interesante es que convierte la consistencia en un dial **por consulta**: la misma tabla
puede servir una lectura crítica con quórum y una analítica con `R=1`.

**01 → 6. ¿Por qué "elige dos de tres" es una lectura incorrecta de CAP?**

⏱️ Porque la P no se elige: las redes se parten, y un sistema distribuido tiene que tolerarlo.
🗣️ El teorema solo dice algo **durante** una partición, y entonces la elección es entre C y A. El
resto del tiempo puedes tener las dos, así que no hay ningún "dos de tres" que escoger.
🔬 Además la A de CAP es tan estricta —toda petición a un nodo vivo responde— que casi ningún
sistema real es estrictamente A. Gilbert y Lynch formalizaron el teorema, y el propio Brewer
publicó después "CAP Twelve Years Later" matizando el titular.

**01 → 7. ¿En qué se diferencia la C de CAP de la C de ACID?**

⏱️ La de CAP es linealizabilidad; la de ACID es que se cumplan las restricciones de integridad.
🗣️ En ACID, consistencia significa que al terminar la transacción las reglas declaradas —claves
foráneas, `CHECK`, unicidad— siguen siendo ciertas. En CAP significa que el sistema se comporta
como si hubiera una sola copia del dato.
🔬 Son conceptos ortogonales: una base de datos puede cumplir ACID y no ser linealizable entre sus
réplicas. Confundirlas es el error más frecuente y el entrevistador lo busca.

**01 → 8. ¿Qué significa exactamente la A de CAP?**

⏱️ Que toda petición a un nodo que no ha fallado recibe una respuesta no errónea. No dice nada
sobre cuánto tarda.
🗣️ Un sistema que responde en treinta segundos sigue siendo "disponible" según CAP. Por eso CAP,
por sí solo, no sirve para razonar sobre experiencia de usuario ni sobre SLA.
🔬 Esa limitación es exactamente el hueco que llena PACELC con su L de latencia, y es la razón de
que PACELC sea más útil en una conversación de diseño real.

**01 → 9. ¿Por qué la consistencia cuesta latencia aunque no haya partición?**

⏱️ Porque para garantizar que una lectura ve la última escritura, esa escritura tuvo que
confirmarse en varias réplicas antes de responder.
🗣️ Eso es al menos una ida y vuelta de red adicional en cada operación. Dentro de una zona son
milisegundos; entre regiones, decenas. Y se paga siempre, haya o no partición.
🔬 Es la mitad "else" de PACELC y el motivo por el que DynamoDB cobra el doble por una lectura
fuertemente consistente: no es una tarifa arbitraria, refleja el trabajo extra.

**01 → 10. ¿Qué es read-your-writes y por qué suele ser el requisito real?**

⏱️ Que el usuario vea sus propias escrituras inmediatamente. Es el requisito real porque lo que
molesta es no ver **lo tuyo**, no que otro lo vea tarde.
🗣️ Cuando negocio pide "consistencia fuerte", casi siempre describe la escena de alguien que
guarda un cambio y no lo ve al recargar. Eso se resuelve enrutando sus lecturas al primario unos
segundos, que es barato, en vez de con linealizabilidad global, que es carísima.
🔬 Detectar esa diferencia es la jugada más rentable del capítulo: convierte un requisito que
obligaría a replicación síncrona en una marca en la sesión.

**01 → 11. ¿Qué diferencia hay entre lag y divergencia?**

⏱️ Lag es retraso: el sistema funciona y converge. Divergencia es que no converge: está roto.
🗣️ Con lag, si dejas de escribir, en unos segundos todas las copias coinciden. Con divergencia,
las copias no van a coincidir nunca sin intervención, normalmente por un conflicto resuelto mal o
por un evento perdido.
🔬 Se distinguen midiendo: una sonda que escribe y lee hasta ver el valor da el lag; una
comparación de conteos o sumas de control entre copias detecta la divergencia. La primera se
resuelve escalando o esperando, la segunda es un incidente de corrupción.

**01 → 12. ¿Por qué "somos AP" es una afirmación imprecisa?**

⏱️ Porque la posición depende de la configuración y de la consulta, no del producto.
🗣️ DynamoDB es AP con lectura eventual y CP con lectura fuertemente consistente, en la misma
tabla. Cassandra se ajusta por consulta con quórums. Postgres es CP con réplica síncrona y sirve
lecturas obsoletas con réplica asíncrona.
🔬 La respuesta precisa nombra el flujo: *"las lecturas de catálogo son eventuales y las de saldo
van al primario"*. Etiquetar el sistema entero con dos letras esconde justo la decisión que
importa.

**01 → 13. Con `N=3`, ¿qué combinaciones de `W` y `R` dan consistencia fuerte?**

⏱️ Las que cumplen `W + R > 3`: (3,1), (2,2), (1,3) y cualquiera mayor.
🗣️ `W=3, R=1` hace la escritura lenta y la lectura rápida: bueno si lees mucho más de lo que
escribes. `W=2, R=2` es el quórum clásico y equilibrado. `W=1, R=3` es raro. `W=1, R=1` da máxima
velocidad y consistencia eventual.
🔬 El matiz: `W=3` con N=3 significa que perder una réplica impide escribir, así que sacrifica
disponibilidad. El quórum `W=2, R=2` tolera la caída de una réplica manteniendo la consistencia,
y por eso es el valor por defecto en la práctica.

**01 → 14. ¿Por qué DynamoDB aparece dos veces en una tabla de clasificación PACELC?**

⏱️ Porque su consistencia no es una propiedad del producto, es un parámetro de cada consulta.
🗣️ Por defecto las lecturas son eventualmente consistentes: rápidas, baratas, PA/EL. Con
`ConsistentRead=true` la misma tabla da lectura fuerte: más latencia, el doble de coste, PC/EC.
🔬 Esa es la lección general del capítulo: clasificar productos es menos útil que clasificar
consultas. Y la excepción que hay que recordar: los GSI **no** admiten lectura fuerte bajo ninguna
configuración.

**01 → 15. ¿Cómo se mide la ventana de consistencia eventual?**

⏱️ Con una sonda sintética: escribir un valor con marca de tiempo y leerlo desde la réplica hasta
que aparezca.
🗣️ Ese número —el p99 de la diferencia— es el que se lleva a negocio y sobre el que se alerta.
Las métricas del motor (bytes o segundos de retraso) son complementarias, pero la sonda mide lo
que el usuario experimenta de verdad.
🔬 Conviene medirla por flujo y en el peor momento, no en media: la ventana se ensancha con la
carga de escritura, con migraciones de esquema y con backups. Un p50 de 50 ms y un p99 de 6
segundos son dos sistemas distintos.

**01 → 16. ¿Por qué "eventualmente consistente" sin plazo es una respuesta incompleta?**

⏱️ Porque "eventual" no dice cuándo, y sin el número no se puede decidir si es aceptable.
🗣️ Una ventana de 200 milisegundos y una de cuatro minutos son ambas "eventualmente
consistentes", y solo una de las dos es tolerable en un carrito de compra. Sin plazo, la
conversación con negocio es de opiniones.
🔬 La respuesta completa: *"eventual, con una ventana medida de menos de dos segundos en el p99, y
alerta si supera cinco"*. Eso convierte una propiedad cualitativa en un objetivo de servicio.

**01 → 17. ¿Cuándo citar CAP es ruido?**

⏱️ Cuando no hay réplicas ni particiones posibles: un sistema con una sola base de datos.
🗣️ Si hay un único nodo de escritura y ninguna réplica, no existe la partición que CAP describe, y
razonar sobre C contra A no aporta. Ahí los conceptos útiles son los niveles de aislamiento y la
concurrencia, que es otro capítulo.
🔬 También es ruido cuando la conversación es sobre latencia y no sobre fallo: ahí la herramienta
es la mitad "else" de PACELC, no CAP.

**01 → 18. ¿Qué preguntas para decidir si una lectura puede ser eventual?**

⏱️ ¿Qué pasa si devuelve un dato de hace dos segundos? Y ¿quién lo va a ver: el que escribió o
otro?
🗣️ Si la respuesta a la primera es "nada grave" —catálogo, historial, recomendaciones—, eventual.
Si el que lo ve es quien acaba de escribir, el requisito es read-your-writes y basta con enrutar
sus lecturas. Si se toma una decisión sobre dinero con ese dato, tiene que ser fuerte.
🔬 Una tercera pregunta que afina mucho: ¿se puede corregir después sin daño? Un contador de
visitas desactualizado se corrige solo; un límite de crédito mal leído produce una operación que
ya no se puede deshacer.

**01 → 19. ¿Por qué el quórum es mejor entendido como un dial por consulta?**

⏱️ Porque distintos flujos del mismo sistema tienen requisitos distintos, y el quórum permite
servirlos con la misma tabla.
🗣️ Una consulta de saldo puede pedir quórum mientras un informe analítico se conforma con `R=1`.
Configurar el quórum una vez para todo el sistema pierde esa ventaja y te deja pagando el coste
del caso más exigente en todas las consultas.
🔬 Cassandra lo expone literalmente por consulta; DynamoDB lo reduce a un interruptor por lectura;
Postgres lo expresa con la elección de leer del primario o de una réplica. El mecanismo cambia, la
idea es la misma.

**01 → 20. Te dicen "necesitamos consistencia fuerte en todo el sistema". ¿Qué preguntas y qué propones?**

⏱️ Pregunto qué escena concreta les preocupa, y casi siempre resulta ser read-your-writes en un
flujo. Propongo consistencia fuerte solo ahí.
🗣️ Las preguntas: ¿qué pasó o qué temen que pase? ¿Quién ve el dato desactualizado: el que
escribió o un tercero? ¿Se toma una decisión irreversible con él? ¿Toleran que cada escritura sea
más lenta a cambio? La cuarta suele cambiar la conversación, porque "consistencia fuerte en todo"
significa replicación síncrona y latencia en cada operación.
🔬 Lo que propongo: identificar los dos o tres flujos donde de verdad hace falta —saldo, límite,
confirmación de pago— y darles lectura del primario o quórum; para el resto, eventual con ventana
medida y alertada. Y resolver la escena que les preocupa con lectura pegajosa al primario tras
escribir, que cuesta casi nada. El argumento que cierra: la consistencia fuerte global no es una
casilla, es un coste en cada operación del sistema, incluidas las que no la necesitan.

**01 → 21. Diseña la estrategia de consistencia de un e-commerce: catálogo, carrito, stock, pedido y pago. Justifica cada elección.**

⏱️ Catálogo eventual y muy cacheado; carrito con read-your-writes; stock fuerte en el momento de
reservar; pedido fuerte; pago fuerte y además idempotente.
🗣️ El reparto:

```text
Catálogo → eventual, ventana de minutos. Cambia poco y nadie decide dinero con él.
Carrito  → read-your-writes obligatorio: es del usuario y lo ve él. Sesión pegajosa basta.
Stock    → CONSULTA eventual (mostrar "quedan pocos"), RESERVA fuerte y atómica.
           La distinción es clave: mostrar y comprometer son dos operaciones distintas.
Pedido   → fuerte. Es el registro de la intención del cliente y hay dinero detrás.
Pago     → fuerte + idempotencia por clave. Aquí no hay margen.
```

🔬 Lo que hace buena esta respuesta es la línea de stock: casi todo el mundo responde "fuerte"
para todo el stock, y la realidad es que **mostrar disponibilidad admite obsolescencia** —de hecho
todos los e-commerce la muestran desactualizada— mientras que **comprometer una unidad no**. La
reserva se hace con una sentencia atómica condicional (`UPDATE ... WHERE stock > 0`) o con
bloqueo, y si falla se le dice al usuario en el momento del pago. Añadiría dos cosas: la ventana
de cada flujo medida y alertada, y la decisión explícita sobre sobreventa —aceptarla y compensar,
o reservar en firme— que es de negocio y no técnica.

**01 → 22. "Los datos no están actualizados." Describe cómo investigas y qué te dice cada hallazgo.**

⏱️ Primero distingo lag de divergencia; luego localizo en qué capa se quedó el dato.
🗣️ El orden:

```text
1. ¿Converge si espero? → SÍ: es lag. NO: es divergencia, y es un incidente distinto.
2. Si es lag, ¿dónde?  → métricas de replicación de la BD
                        → lag del consumidor si hay proyección
                        → TTL de la caché si hay caché delante
3. ¿Es general o de un flujo? → general: capacidad. De un flujo: enrutamiento o clave.
4. ¿Coincide con algo? → despliegue, migración, backup, pico de escritura.
```

🔬 Qué me dice cada hallazgo. Lag alto en la replicación: la réplica no da abasto o hay una
operación pesada en el primario; se resuelve con recursos o esperando. Lag alto solo en un
consumidor: partición caliente o mensaje envenenado, y es
[`02-eventos/04`](../02-eventos/04-colas-dlq-y-reintentos.md). Todo en orden pero el usuario sigue
viendo viejo: es la caché, y el sospechoso es una invalidación que no cubre ese camino de
escritura. Y si no converge nunca, la causa suele ser un evento perdido o un conflicto resuelto
con "gana la última": eso no se arregla esperando, se arregla reconstruyendo desde la fuente de
verdad.

**01 → 23. Un banco pide que el saldo sea siempre exacto y que la app nunca falle. Explica el conflicto y propón una salida.**

⏱️ Es CAP en estado puro: bajo partición no se puede tener exactitud y respuesta a la vez.
Propongo distinguir saldo contable de saldo disponible.
🗣️ El conflicto: si la red entre centros se parte, o respondes con el saldo que tienes —que puede
no incluir un movimiento reciente— o no respondes. No hay tercera opción, y prometer las dos es
prometer algo imposible.
🔬 La salida, que es además cómo funcionan los bancos de verdad: separar **saldo contable** —el
firme, consistente, que manda para cualquier operación— de **saldo disponible** —el que se muestra,
que descuenta operaciones en tránsito y se marca con su hora—. La app siempre responde, mostrando
el disponible con su marca de tiempo y un aviso si la información no es reciente; las operaciones
que mueven dinero se validan contra el contable, con consistencia fuerte, y si esa validación no
se puede hacer, la operación se rechaza explícitamente en vez de ejecutarse a ciegas. Así la app
"nunca falla" para consultar y nunca miente, y la exactitud se conserva donde importa. Añadiría
que la conciliación diaria es la red de seguridad final: en banca la consistencia la garantiza la
conciliación, no el transporte.

---

# 02 — Transacciones, aislamiento y bloqueo

**02 → 1. ¿Qué significan las cuatro letras de ACID?**

⏱️ Atomicidad, consistencia, aislamiento y durabilidad.
🗣️ Atomicidad: todo o nada. Consistencia: las restricciones declaradas se cumplen al terminar.
Aislamiento: las transacciones concurrentes no se ven a medias. Durabilidad: lo confirmado
sobrevive a una caída.
🔬 Tres de las cuatro tienen letra pequeña: la C la garantiza tu modelo y no el motor, la I es un
dial y no un sí/no, y la D depende de si la replicación es síncrona.

**02 → 2. Nombra los cuatro niveles de aislamiento del estándar SQL.**

⏱️ Read Uncommitted, Read Committed, Repeatable Read y Serializable.
🗣️ Cada uno evita más anomalías que el anterior: lectura sucia, lectura no repetible y lectura
fantasma, en ese orden. Serializable las evita todas.
🔬 Los motores reales difieren del estándar: Postgres por defecto es Read Committed y su
Repeatable Read es snapshot isolation, que sí evita fantasmas. MySQL/InnoDB por defecto es
Repeatable Read con bloqueos de rango. Oracle no tiene Repeatable Read.

**02 → 3. ¿Qué es una lectura fantasma?**

⏱️ Repetir la misma consulta dentro de una transacción y obtener filas nuevas que antes no
estaban.
🗣️ Se distingue de la lectura no repetible en que esta afecta a una fila que cambió, y el fantasma
a un **conjunto** que creció: contar pedidos pendientes dos veces y obtener 40 y luego 42.
🔬 El estándar solo la evita en Serializable, pero Postgres la evita ya en Repeatable Read por su
implementación con instantáneas, y MySQL con bloqueos de rango. Es el ejemplo típico de que el
estándar y la práctica no coinciden.

**02 → 4. ¿Qué es el bloqueo optimista y cómo se implementa?**

⏱️ No bloquear nada: leer con una versión y comprobar al escribir que no cambió.
🗣️ En JPA basta un campo `@Version`: el `UPDATE` incluye `WHERE version = ?` y si afecta a cero
filas es que alguien escribió antes, así que se lanza `OptimisticLockException`.
🔬 No hay espera, así que el throughput no cae con la contención; lo que sube es la tasa de
fallos. Y obliga a decidir qué hacer con el conflicto, que es una decisión de negocio:
reintentar, fusionar o avisar al usuario.

**02 → 5. ¿Cuál es el nivel de aislamiento por defecto de Postgres?**

⏱️ Read Committed.
🗣️ Evita la lectura sucia y permite lectura no repetible, fantasmas y actualización perdida. Es
también el valor por defecto de Oracle y de SQL Server.
🔬 Que sea el defecto y permita la actualización perdida es exactamente el problema del ejemplo
del capítulo: `@Transactional` sin más no impide que dos hilos vendan la misma última unidad.

**02 → 6. ¿Qué diferencia hay entre lectura sucia y lectura no repetible?**

⏱️ La sucia lee algo **no confirmado** que luego se deshace; la no repetible lee algo confirmado
que cambió entre dos lecturas.
🗣️ La sucia es la más grave porque el dato que leíste nunca existió realmente. La no repetible lee
datos válidos, solo que de dos instantes distintos.
🔬 Read Committed evita la primera y permite la segunda, y ese es el compromiso que la mayoría de
los sistemas acepta: la sucia es inaceptable, la no repetible se tolera.

**02 → 7. ¿Qué es la actualización perdida y por qué no está en la tabla del estándar?**

⏱️ Dos transacciones leen el mismo valor, ambas escriben, y la segunda sobrescribe a la primera
sin haberla visto. No está en la tabla porque el estándar SQL no la contempló.
🗣️ Es la anomalía que más daño hace en aplicaciones reales —es la del ejemplo del capítulo— y sin
embargo no aparece en la tabla clásica de tres anomalías que todo el mundo memoriza.
🔬 Postgres en Repeatable Read la detecta y aborta una de las transacciones. En Read Committed no,
y hay que resolverla explícitamente: bloqueo optimista, pesimista, o una sentencia atómica
condicional.

**02 → 8. ¿Por qué `@Transactional` no evita una condición de carrera?**

⏱️ Porque da atomicidad, no exclusión mutua: abrir una transacción no impide que otra lea el
mismo dato a la vez.
🗣️ Con Read Committed, ambas transacciones leen `stock = 1`, ambas comprueban que es mayor que
cero y ambas escriben. Las dos son atómicas y el resultado es incorrecto.
🔬 Hace falta un mecanismo de concurrencia añadido: `@Version`, `SELECT FOR UPDATE`, o —mejor—
reformular la operación como una sentencia atómica condicional que no necesite leer antes.

**02 → 9. ¿Qué hace exactamente `REQUIRES_NEW`?**

⏱️ Suspende la transacción actual y abre una nueva e independiente; al terminar, reanuda la
anterior.
🗣️ La interna confirma o deshace por su cuenta, sin importar lo que le pase a la externa. Se usa
para lo que debe persistir aunque la principal falle: auditoría, registro de intentos, trazas de
negocio.
🔬 El detalle que se pregunta: la externa **sigue manteniendo sus bloqueos** mientras la interna
corre. Si ambas tocan la misma fila, se interbloquean consigo mismas y el hilo se queda esperando
a un bloqueo que él mismo posee.

**02 → 10. ¿Qué diferencia hay entre `REQUIRES_NEW` y `NESTED`?**

⏱️ `REQUIRES_NEW` abre una transacción independiente; `NESTED` crea un punto de guardado dentro de
la actual.
🗣️ Con `NESTED`, si la parte anidada falla se deshace solo ella y la externa puede continuar; pero
si la externa falla, se deshace todo, incluida la anidada. Con `REQUIRES_NEW`, lo confirmado por
la interna queda confirmado pase lo que pase.
🔬 `NESTED` requiere soporte de puntos de guardado en el motor y en el gestor de transacciones, y
no todos lo tienen; por eso se usa poco. La confusión entre ambas es frecuente y la consecuencia
—perder o conservar el registro de auditoría— es muy visible.

**02 → 11. ¿Por qué la C de ACID es "la letra rara"?**

⏱️ Porque no es una propiedad del motor sino de la aplicación: el motor aplica las restricciones
que tú declaraste.
🗣️ Si no declaras una clave foránea o un `CHECK`, la base de datos no tiene forma de saber que un
estado es inválido. La consistencia del dominio —"un pedido enviado tiene que estar pagado"— la
garantiza tu modelo, no ACID.
🔬 Kleppmann argumenta que la C está en el acrónimo porque encajaba la letra, no porque sea del
mismo tipo que las otras tres. Decirlo demuestra lectura y encaja con el argumento del agregado de
[`01-bases/07`](../01-bases/07-ddd-tactico.md): las invariantes las protege el dominio.

**02 → 12. ¿Qué letra pequeña tiene la D de ACID?**

⏱️ Que "confirmado" puede perderse si la replicación es asíncrona y el primario cae antes de
replicar.
🗣️ La durabilidad es local al nodo que confirmó. Si ese nodo muere y su log no llegó a ninguna
réplica, la transacción confirmada desaparece en la conmutación por error. Es el RPO real del
sistema.
🔬 También depende de la configuración de escritura a disco: muchos motores permiten confirmar
antes de sincronizar el log al disco físico, a cambio de rendimiento. Es el mismo compromiso a otra
escala, y se desarrolla en [`05`](#05--réplicas-y-lag).

**02 → 13. ¿Cuándo eliges bloqueo pesimista sobre optimista?**

⏱️ Cuando el conflicto es frecuente: esperar sale más barato que reintentar tres veces.
🗣️ El último asiento de un vuelo, el stock de un producto en oferta, un contador muy disputado.
Con contención alta, el optimista degenera en una tormenta de reintentos donde el trabajo se hace
varias veces y se descarta.
🔬 Y nunca al revés en dos casos: si hay un humano pensando entre leer y escribir —un formulario—,
un bloqueo pesimista duraría minutos; y si la transacción llama a un servicio externo, mantener el
bloqueo mientras esperas es la receta de una caída.

**02 → 14. ¿Por qué un bloqueo pesimista no sirve si hay un humano pensando?**

⏱️ Porque el bloqueo duraría lo que dura el formulario: minutos, y mientras tanto nadie más puede
tocar el dato.
🗣️ Además el usuario puede cerrar la pestaña y el bloqueo quedaría colgado hasta que expire la
transacción o la conexión. Es un patrón que bloquea recursos por tiempo indefinido según el
comportamiento de una persona.
🔬 La solución es optimista: se lee con la versión, el usuario piensa, y al guardar se comprueba.
Si alguien modificó mientras tanto, se le muestra el conflicto y se decide —recargar, fusionar,
sobrescribir—, que además es mejor experiencia que un "este registro está bloqueado".

**02 → 15. ¿Qué coste tiene subir a Serializable?**

⏱️ Throughput y reintentos: el motor aborta transacciones que no puede serializar, y hay que
reintentarlas.
🗣️ En Postgres, Serializable usa *serializable snapshot isolation*: no bloquea más, pero detecta
dependencias peligrosas y aborta una de las transacciones con un error de serialización. Tu código
**tiene que estar preparado para reintentar**, y mucho código no lo está.
🔬 Por eso casi siempre sale mejor quedarse en el nivel por defecto y resolver la concurrencia del
caso concreto con bloqueo explícito o con una sentencia atómica: subes el coste solo donde hace
falta en vez de en todo el sistema.

**02 → 16. ¿Por qué el Repeatable Read de Postgres evita fantasmas y el del estándar no?**

⏱️ Porque Postgres lo implementa con una instantánea de toda la base de datos, no con bloqueos de
fila.
🗣️ La transacción ve el estado congelado en el instante en que empezó, así que una consulta
repetida devuelve exactamente lo mismo, aunque otras transacciones hayan insertado filas. El
estándar solo exigía que las filas leídas no cambiaran, no que no aparecieran nuevas.
🔬 Es un caso claro de que los niveles del estándar describen **garantías mínimas** y cada motor
puede dar más. Por eso "usamos Repeatable Read" no significa lo mismo en Postgres, en MySQL y en
un libro de texto.

**02 → 17. ¿Cómo evitas el conflicto en vez de gestionarlo, con una sola sentencia?**

⏱️ Con una escritura atómica condicional: `UPDATE producto SET stock = stock - 1 WHERE id = ? AND
stock > 0`.
🗣️ No hay lectura previa, así que no hay ventana entre leer y escribir. El motor evalúa la
condición y aplica el decremento en una sola operación atómica. Si devuelve cero filas afectadas,
no había stock, y eso es la respuesta.
🔬 **Es la mejor opción y casi nadie la propone primero**, porque el instinto es leer, comprobar y
escribir. Funciona siempre que la regla se pueda expresar en la condición; cuando la lógica es más
compleja, entonces sí hacen falta bloqueos. Y es la misma idea que la idempotencia por
reformulación de [`02-eventos/03`](../02-eventos/03-garantias-orden-e-idempotencia.md).

**02 → 18. ¿Por qué `REQUIRES_NEW` puede interbloquearse consigo misma?**

⏱️ Porque la transacción externa mantiene sus bloqueos mientras la interna corre, y la interna
puede quedarse esperando uno de ellos.
🗣️ Si la externa actualizó una fila y la interna intenta actualizar la misma, la interna espera a
que la externa libere; pero la externa está suspendida esperando a que la interna termine. El hilo
se bloquea hasta que salte el timeout, y el mensaje de error no menciona que el culpable es el
mismo hilo.
🔬 Es difícil de diagnosticar porque la traza no sugiere nada raro. La defensa: que las
transacciones `REQUIRES_NEW` toquen datos disjuntos de la externa —típicamente una tabla de
auditoría propia—, que es para lo que están pensadas.

**02 → 19. ¿Qué le dices al usuario cuando falla un bloqueo optimista?**

⏱️ Depende del dominio, y es una decisión de negocio: reintentar en silencio, fusionar, o mostrar
el conflicto.
🗣️ Reintentar en silencio sirve cuando la operación es conmutativa —sumar un importe— y es
transparente. Fusionar sirve cuando los campos modificados son distintos y se puede combinar.
Mostrar el conflicto es lo correcto cuando la decisión es del usuario: *"otro usuario modificó
este registro; estos son los cambios"*.
🔬 Lo que **no** se hace es mostrar `OptimisticLockException` ni sobrescribir en silencio. Y en
formularios largos, la buena práctica es avisar en cuanto se detecta el cambio, no al guardar, para
que el usuario no pierda diez minutos de trabajo.

**02 → 20. ¿Por qué nunca se mantiene un bloqueo mientras llamas a un servicio externo?**

⏱️ Porque la duración del bloqueo pasa a depender de un sistema que no controlas.
🗣️ Si la pasarela de pago tarda cuatro segundos —o treinta, si se degrada—, la fila queda
bloqueada todo ese tiempo y los demás hilos se encolan. Una lentitud externa se convierte en
contención interna, y de ahí a agotar el pool de conexiones hay un paso. Es la cadena de fallo de
[`01-bases/09`](../01-bases/09-resiliencia.md) con un bloqueo de base de datos en medio.
🔬 La forma correcta: transacción corta para marcar el estado —"en trámite", con TTL—, commit,
llamada externa fuera de transacción, y otra transacción corta para registrar el resultado. Es
exactamente la estructura de una saga, y por eso el patrón aparece igual dentro de una base de
datos y entre servicios.

**02 → 21. Corrige el código de la sección 1 de tres formas distintas y compáralas.**

⏱️ Sentencia atómica condicional, bloqueo pesimista, o bloqueo optimista con reintento. La primera
es la mejor.
🗣️ Las tres:

```java
// 1. ATÓMICA CONDICIONAL — la mejor. Sin lectura previa, sin ventana.
int filas = repo.descontarSiHay(id);      // UPDATE ... SET stock=stock-1 WHERE id=? AND stock>0
if (filas == 0) throw new SinStock(id);

// 2. PESIMISTA — el segundo hilo espera. Correcto con contención alta.
Producto p = em.find(Producto.class, id, LockModeType.PESSIMISTIC_WRITE);
if (p.stock() > 0) p.descontarStock(); else throw new SinStock(id);

// 3. OPTIMISTA — @Version en la entidad; el segundo falla y hay que reintentar.
//    Correcto con contención baja; degenera si es alta.
```

🔬 La comparación: la 1 no bloquea, no reintenta y hace una sola ida y vuelta a la base de datos —
gana en todo salvo en expresividad, porque la regla tiene que caber en el `WHERE`. La 2 garantiza
el resultado al primer intento a cambio de serializar los accesos, y es la correcta para el "último
asiento" con miles de compradores. La 3 es la más barata de escribir sobre un modelo JPA existente
y la peor bajo contención alta, porque el trabajo se hace y se descarta. Un matiz que suele
pedirse: la 1 pierde el modelo de dominio rico —la regla vive en SQL y no en la entidad—, y ese es
su verdadero coste; en un agregado con muchas invariantes puede no compensar.

**02 → 22. Diseña la concurrencia de "comprar la última entrada" con 10.000 usuarios simultáneos. Justifica el mecanismo.**

⏱️ No compito por una fila: convierto la venta en inserción de asientos con clave única, y protejo
la entrada al sistema con una cola.
🗣️ Con 10.000 usuarios sobre el mismo recurso, cualquier mecanismo que serialice accesos a una
fila —pesimista— crea una cola de 10.000 esperas y el throughput se hunde; y cualquier mecanismo
optimista produce 9.999 fallos y reintentos. El diseño correcto cambia el modelo: en vez de un
contador `entradas_disponibles`, una tabla de **asientos individuales** con estado, y comprar es
`INSERT` de una reserva con restricción única sobre el asiento. Diez mil usuarios compitiendo por
mil asientos distintos no compiten entre sí: solo colisionan los que eligen el mismo.
🔬 Lo que añadiría alrededor, porque el problema real no es la base de datos: una **sala de
espera** que limite cuántos usuarios entran al flujo de compra a la vez —es lo que hacen todas las
plataformas de entradas—, reservas con **TTL** para que un carrito abandonado libere el asiento, e
idempotencia por usuario para que un doble clic no compre dos veces. Si el modelo tuviera que ser
un contador único y no se puede cambiar, entonces la respuesta es pesimista con la cola explícita,
y se declara que el throughput máximo es el de una transacción tras otra.

**02 → 23. Tras un despliegue aparecen `OptimisticLockException` masivas. Da tres hipótesis en orden y di cómo las confirmas.**

⏱️ Un proceso nuevo escribe sobre las mismas filas; una transacción se alargó; o el código
reintenta y amplifica el conflicto.
🗣️ Primera y más probable: el despliegue introdujo un trabajo por lotes, un consumidor de eventos
o un `@Scheduled` que actualiza las mismas entidades que el flujo de usuario. Antes no competían y
ahora sí. Segunda: una transacción del camino existente se alargó —una consulta más lenta, una
llamada externa añadida dentro de la transacción— y la ventana entre leer y escribir creció, así
que colisiona mucho más. Tercera: se añadió un reintento automático sin backoff, de modo que cada
conflicto genera más intentos y la contención se realimenta.
🔬 Cómo las confirmo, en ese orden: miro qué escribe sobre esas tablas desde el despliegue —logs de
consultas, trazas por origen— y si hay un componente nuevo; comparo la duración de la transacción
afectada antes y después, que es la métrica que delata la segunda; y reviso si hay reintentos
configurados y si llevan backoff y tope. Una cuarta hipótesis a descartar: que el despliegue haya
escalado instancias y ahora haya más concurrencia sobre lo mismo. Y la corrección depende de la
causa: separar los datos del proceso por lotes, sacar la llamada externa de la transacción, o
poner backoff con jitter al reintento.

---

# 03 — Relacional, NoSQL y DynamoDB

**03 → 1. Nombra las cuatro familias de NoSQL y para qué sirve cada una.**

⏱️ Clave-valor para acceso por clave; documento para agregados con esquema variable; columnar
ancho para escritura masiva ordenada; grafo para relaciones profundas.
🗣️ Redis y DynamoDB son clave-valor; MongoDB, documental; Cassandra, columnar ancho; Neo4j,
grafo. Clave-valor y documento son un continuo: DynamoDB guarda documentos dentro de un modelo
clave-valor.
🔬 Solo la familia de grafo resuelve algo que el relacional no puede: consultas de profundidad
variable. Las otras tres resuelven escala y forma, no expresividad.

**03 → 2. ¿Qué son la partition key y la sort key en DynamoDB?**

⏱️ La PK decide en qué partición física vive el elemento; la SK ordena los elementos dentro de esa
partición.
🗣️ La PK es obligatoria y solo admite igualdad exacta. La SK es opcional y permite condiciones de
rango: `begins_with`, `between`, mayor o menor. Juntas forman la clave primaria compuesta.
🔬 Elegir la PK es la decisión más importante e irreversible del diseño: determina el reparto del
tráfico y qué consultas son posibles. Cambiarla exige migrar la tabla entera.

**03 → 3. ¿Qué diferencia hay entre `Query` y `Scan`?**

⏱️ `Query` accede por PK exacta con condición opcional sobre la SK; `Scan` recorre toda la tabla y
filtra después.
🗣️ El coste de `Query` es proporcional a lo que devuelve; el de `Scan`, al tamaño de la tabla. El
filtro de `Scan` se aplica **después** de leer, así que pagas por todo aunque devuelvas tres
elementos.
🔬 Un `Scan` en producción es casi siempre la señal de que el modelo no sirve para esa consulta.
La salida es un índice secundario o rediseñar la clave, no un filtro más fino.

**03 → 4. ¿Qué es un GSI?**

⏱️ Un índice secundario global: una vista de la tabla con otra PK y otra SK, mantenida por
DynamoDB.
🗣️ Permite consultar por un atributo que no es la clave principal. Se puede crear en cualquier
momento, tiene su propia capacidad y se le elige qué atributos se proyectan.
🔬 Dos cosas que hay que saber sin dudar: es **siempre eventualmente consistente**, sin flag que lo
cambie; y cada GSI duplica el coste de escritura, porque escribir en la tabla implica escribir
también en el índice.

**03 → 5. ¿Qué es el TTL en DynamoDB y para qué se usa?**

⏱️ Un atributo con marca de tiempo: cuando llega, DynamoDB borra el elemento solo.
🗣️ Sirve para datos con caducidad natural —sesiones, tokens, cachés— y, sobre todo, para
implementar reservas con caducidad: es el TTL que toda saga necesita como red de seguridad.
🔬 El borrado no es instantáneo: DynamoDB lo hace en un plazo que puede llegar a días, así que el
código debe comprobar la caducidad al leer y no confiar en que el elemento ya no esté.

**03 → 6. ¿Qué cuatro razones justifican salir del modelo relacional?**

⏱️ Volumen de escritura que no cabe en una máquina; esquema muy variable entre filas; acceso
siempre por la misma clave; y latencia garantizada a cualquier escala.
🗣️ Cualquiera de las cuatro, con números, justifica la conversación. Sin ninguna de ellas, el
relacional es el valor por defecto porque te da gratis transacciones, integridad referencial,
consultas que no previste y décadas de herramientas.
🔬 La tercera es la más sutil: si siempre accedes por la misma clave, estás pagando un motor de
consultas que no usas. Y la cuarta habla de **garantía**, no de velocidad media: el relacional
puede ser muy rápido, pero su latencia se degrada con el volumen de formas difíciles de acotar.

**03 → 7. ¿Por qué `Scan` con filtro es casi siempre un bug?**

⏱️ Porque el filtro se aplica después de leer: pagas por toda la tabla aunque devuelvas tres
elementos.
🗣️ En una tabla de 50 GB, un `Scan` filtrado consume 50 GB de capacidad de lectura. Con `Query` el
coste es proporcional al resultado. Además `Scan` no escala: cuanto más crece la tabla, más caro y
más lento, aunque la respuesta sea del mismo tamaño.
🔬 Los usos legítimos son pocos y siempre fuera del camino del usuario: migraciones, exportaciones
puntuales, tablas pequeñas y acotadas. Y en esos casos se usa `Scan` paralelo con límite de tasa
para no consumir la capacidad de la tabla en producción.

**03 → 8. ¿Qué diferencias hay entre GSI y LSI?**

⏱️ El GSI cambia la PK y se crea en cualquier momento; el LSI mantiene la PK, solo cambia la SK, y
solo se puede crear al crear la tabla.
🗣️ El GSI tiene capacidad propia y es siempre eventualmente consistente. El LSI comparte capacidad
con la tabla y puede leerse con consistencia fuerte. Hay un límite de 20 GSI y de 5 LSI por tabla,
y los LSI no se pueden borrar.
🔬 En la práctica usarás GSI. El LSI es rígido —decidirlo al crear la tabla y no poder quitarlo— y
su única ventaja real, la lectura fuerte, rara vez compensa esa rigidez.

**03 → 9. ¿Qué consistencia tiene un GSI?**

⏱️ Siempre eventual. No hay configuración que lo cambie.
🗣️ Escribir en la tabla y leer inmediatamente por el GSI puede no devolver el elemento. La ventana
suele ser de milisegundos, pero no está garantizada, y bajo carga puede crecer.
🔬 Es una de las preguntas favoritas y casi nadie la sabe. La consecuencia práctica: cualquier
flujo que escriba y lea por un GSI en el mismo paso necesita leer por la clave principal, o
tolerar la ventana explícitamente.

**03 → 10. ¿Qué es single-table design?**

⏱️ Meter todas las entidades del dominio en una sola tabla, distinguidas por el prefijo de sus
claves.
🗣️ `PEDIDO#771 / CABECERA`, `PEDIDO#771 / LINEA#01`: un solo `Query` por `PK=PEDIDO#771` trae el
agregado entero, cabecera y líneas, en una operación. Es la forma de recuperar en DynamoDB lo que
en SQL sería un `JOIN`.
🔬 Su coste es legibilidad y evolución: la tabla es difícil de leer, los nombres de atributo se
vuelven genéricos, y cambiar el modelo de claves es caro. Por eso la recomendación madura es
empezar con una tabla por entidad si el dominio aún se mueve.

**03 → 11. ¿Qué son los DynamoDB Streams y para qué sirven?**

⏱️ Un log ordenado de los cambios de la tabla, consumible por Lambda u otros procesos. Es CDC
integrado.
🗣️ Cada inserción, modificación o borrado produce un registro con la imagen anterior y la
posterior. Es la forma canónica de construir proyecciones, propagar eventos a otros servicios,
replicar a otro almacén o alimentar analítica.
🔬 Une DynamoDB con [`02-eventos`](../02-eventos/): el patrón outbox sobre DynamoDB se implementa
escribiendo el evento en el mismo elemento —o en uno hermano dentro de la misma
`TransactWriteItems`— y dejando que el stream lo publique.

**03 → 12. ¿Qué familia de NoSQL resuelve algo que el relacional no puede?**

⏱️ La de grafo: consultas de profundidad variable.
🗣️ "Amigos de amigos hasta el sexto grado" o "caminos de transacciones sospechosas entre cuentas"
son consultas cuya profundidad no se conoce de antemano. En SQL requerirían `JOIN` recursivos cuyo
coste explota con la profundidad.
🔬 Las otras tres familias resuelven escala y forma: cualquier cosa que haga MongoDB o Cassandra se
puede modelar en relacional, más lento o más incómodo. El grafo es la única diferencia cualitativa,
y por eso casos como detección de fraude o recomendación lo justifican solos.

**03 → 13. ¿Por qué en DynamoDB se diseña a partir de los patrones de acceso?**

⏱️ Porque el modelo determina qué consultas son posibles, y cambiarlo después exige migrar la
tabla.
🗣️ En relacional normalizas y luego consultas como quieras: el motor resuelve. En DynamoDB la
clave decide qué se puede consultar de forma eficiente, y todo lo que no encaje será un `Scan` o
un GSI nuevo. Por eso lo primero que se escribe no es el esquema, es la lista de consultas.
🔬 La lista debe incluir la **forma** de cada acceso: por qué campo, con qué filtro, con qué orden,
con qué paginación, y con qué frecuencia. "Pedidos de un cliente" no basta: "los últimos 20 pedidos
de un cliente ordenados por fecha descendente, 3.000 veces por segundo" es un requisito de diseño.

**03 → 14. ¿Qué claves de partición producen particiones calientes y por qué?**

⏱️ Las de baja cardinalidad o con distribución desigual: un estado, una fecha del día, un país en
una app de un solo país.
🗣️ DynamoDB reparte por el hash de la PK y cada partición tiene un techo de throughput. Si millones
de elementos comparten dos valores de estado, todo el tráfico va a dos particiones mientras el
resto está ocioso, y se producen throttles con la tabla globalmente infrautilizada.
🔬 Las claves buenas tienen cardinalidad alta y reparto uniforme: `pedidoId`, `clienteId`,
`sesionId`. Y hay un caso intermedio frecuente: una clave de cardinalidad alta pero con un valor
dominante —el cliente que concentra el 30 % del tráfico—, que produce el mismo efecto localizado.

**03 → 15. ¿Qué es write sharding y qué cuesta?**

⏱️ Añadir un sufijo aleatorio acotado a una clave de baja cardinalidad para repartirla entre varias
particiones.
🗣️ En vez de `PENDIENTE`, usas `PENDIENTE#0` a `PENDIENTE#9`: el tráfico se reparte entre diez
particiones y el techo se multiplica por diez. Al consultar, lanzas las diez consultas en paralelo
y combinas.
🔬 El coste es esa multiplicación de consultas y la complejidad de combinar y ordenar los resultados
en la aplicación. Y hay que elegir bien el número de fragmentos: pocos no resuelven el problema,
muchos encarecen cada lectura. Se calibra con el throughput objetivo dividido por el techo de una
partición.

**03 → 16. ¿Por qué cada GSI encarece las escrituras?**

⏱️ Porque un GSI es una tabla derivada que DynamoDB mantiene: escribir en la principal implica
escribir también en cada índice.
🗣️ Con tres GSI, una escritura consume capacidad cuatro veces: una en la tabla y una por índice.
Además cada uno tiene su propia capacidad, que si se agota provoca throttles y retrasa la
propagación.
🔬 Por eso la proyección importa: con `KEYS_ONLY` el índice ocupa y cuesta menos, a cambio de
necesitar un `GetItem` adicional para traer los atributos. Añadir GSI "por si acaso" es la forma
más común de duplicar la factura de DynamoDB sin darse cuenta.

**03 → 17. ¿Cuándo NO usarías single-table design?**

⏱️ Cuando el dominio todavía cambia y el equipo no lo ha hecho antes.
🗣️ Single-table optimiza para traer varias entidades en un `Query`, y a cambio hace la tabla
difícil de leer, los atributos genéricos y la evolución cara. Si las entidades no se consultan
juntas, no compra nada y solo paga el coste.
🔬 La postura madura, y es hacia donde se ha movido la comunidad: empezar con una tabla por entidad,
que es legible y fácil de cambiar, y unificar solo cuando una consulta concreta lo exija. Recitar
single-table como dogma es la señal de haberlo leído y no haberlo mantenido.

**03 → 18. ¿Cómo haces bloqueo optimista en DynamoDB?**

⏱️ Con una escritura condicional: `ConditionExpression` que exija que el atributo de versión valga
lo que leíste.
🗣️ Lees el elemento con su `version`, y al escribir declaras la condición `version = :leida` y a la
vez incrementas la versión. Si otro escribió antes, la condición falla y DynamoDB rechaza la
operación con `ConditionalCheckFailedException`.
🔬 Es el mismo mecanismo que el `@Version` de JPA de [`02` → 4](#02--transacciones-aislamiento-y-bloqueo),
implementado dentro de la propia operación y sin transacción. Y es también cómo se implementa
"inserta solo si no existe": `attribute_not_exists(PK)`.

**03 → 19. ¿Cuándo eliges `on-demand` y cuándo `provisioned`?**

⏱️ `on-demand` con carga impredecible o desconocida; `provisioned` con carga predecible y
sostenida.
🗣️ `on-demand` cobra por petición, absorbe picos sin configurar nada y no requiere previsión: es lo
correcto para empezar, para cargas irregulares y para entornos de prueba. `provisioned` reserva
capacidad y sale bastante más barato por unidad cuando el tráfico es estable, con autoescalado para
seguir la curva diaria.
🔬 La forma práctica de decidir: empezar en `on-demand`, medir un mes, y cambiar a `provisioned` si
el perfil resulta estable y el ahorro justifica gestionar la capacidad. Se puede cambiar, con un
límite de frecuencia, así que no es una decisión irreversible como la clave.

**03 → 20. ¿Por qué elegir la clave de partición es la decisión más irreversible?**

⏱️ Porque determina dónde vive cada elemento, y cambiarla significa reescribir la tabla entera.
🗣️ No hay `ALTER TABLE` que cambie la clave: hay que crear una tabla nueva, migrar todos los
elementos, mantener las dos sincronizadas durante la transición y cambiar el código. Con 50
millones de elementos eso es un proyecto, no un cambio.
🔬 Y además condiciona lo que se puede consultar: una clave mal elegida obliga a añadir GSI para
cubrir accesos que deberían haber sido nativos, con su coste de escritura y su ventana de
consistencia. Por eso la lista de patrones de acceso se escribe antes: es lo único que permite
acertar a la primera.

**03 → 21. Diseña la tabla de DynamoDB para: pedido por id, pedidos de un cliente por fecha descendente, y pedidos pendientes de hoy.**

⏱️ Tabla con `PK=PEDIDO#id`, un GSI por cliente con la fecha en la SK, y un segundo GSI disperso
para los pendientes.
🗣️ El diseño:

```text
Tabla:  PK = PEDIDO#<id>        SK = CABECERA | LINEA#<n>
        → "pedido por id" es un Query por PK: trae cabecera y líneas juntas.

GSI1:   PK = CLIENTE#<id>       SK = FECHA#<AAAA-MM-DD>#<pedidoId>
        → "pedidos de un cliente por fecha descendente" es un Query con
          ScanIndexForward=false. La fecha en formato ordenable es lo que lo hace posible.

GSI2:   PK = PENDIENTE#<AAAA-MM-DD>   SK = <hora>#<pedidoId>
        → atributo presente SOLO mientras el pedido está pendiente: índice DISPERSO.
          Al enviarse, se borra el atributo y el elemento sale del índice solo.
```

🔬 Los detalles que el entrevistador buscará. El **índice disperso** del GSI2 es la clave: como
DynamoDB solo indexa los elementos que tienen los atributos del índice, borrar el atributo saca el
pedido del índice sin coste adicional, y el índice contiene solo lo pendiente en vez de toda la
historia. La **fecha en formato `AAAA-MM-DD`** en la SK es lo que permite el orden y los rangos;
con otro formato no funcionaría. Y hay un riesgo declarado: `PENDIENTE#<fecha>` es una clave de
cardinalidad baja —un valor por día— y concentra el tráfico del día en una partición; si el volumen
lo exige, se dispersa con sufijo (`PENDIENTE#2026-09-17#3`) y se consultan los fragmentos en
paralelo. Por último, los GSI son eventualmente consistentes, así que un pedido recién creado puede
tardar en aparecer en las listas: hay que decidir si eso importa.

**03 → 22. La factura de DynamoDB se triplicó en un mes sin subir el tráfico. Da tres hipótesis en orden y di cómo las confirmas.**

⏱️ Un `Scan` nuevo en el camino de usuario; un GSI añadido; o lecturas fuertemente consistentes
donde no hacían falta.
🗣️ Primera y más probable: alguien añadió una funcionalidad que hace `Scan` —una búsqueda, un
informe, un panel de administración— y su coste crece con el tamaño de la tabla, no con el uso.
Segunda: se añadió uno o más GSI, y cada uno multiplica el coste de cada escritura, además de tener
capacidad propia. Tercera: se activó `ConsistentRead=true` por costumbre o por copiar código, y eso
duplica el coste de cada lectura.
🔬 Cómo las confirmo: en CloudWatch, `ConsumedReadCapacityUnits` por operación y por índice —eso
separa inmediatamente tabla de GSI y `Scan` de `Query`—; reviso el historial de cambios de la tabla
para ver si se creó un índice; y busco `ConsistentRead` en el código reciente. Una cuarta hipótesis
frecuente: los datos crecieron aunque el tráfico no, y un `Scan` que ya existía ahora cuesta el
triple. Y una quinta operativa: se cambió de `provisioned` a `on-demand` sin recalcular, lo que
encarece si la carga era estable.

**03 → 23. Te piden migrar una tabla relacional de pedidos a DynamoDB "para que escale". ¿Qué preguntas y en qué casos dirías que no?**

⏱️ Pregunto qué consulta o qué escritura no aguanta hoy, con números, y si conocen todos los
patrones de acceso. Sin las dos cosas, digo que no.
🗣️ Las preguntas: ¿cuál es el cuello de botella medido, de lectura o de escritura? Si es de
lectura, réplicas y caché lo resuelven sin migrar. ¿Podéis enumerar todas las consultas actuales y
las previstas? ¿Hay informes, búsquedas ad hoc o analítica sobre esa tabla? ¿Hay transacciones que
cruzan pedidos y otras entidades? ¿Quién del equipo ha modelado DynamoDB antes?
🔬 Diría que no en tres casos. Uno: el cuello es de lectura, porque entonces la migración es un
proyecto para un problema que se resuelve con una réplica. Dos: hay consultas ad hoc o informes
sobre esos datos, porque DynamoDB las castiga y acabarían en `Scan` o en una copia analítica que
hay que mantener. Tres: el dominio todavía cambia, porque un modelo de claves equivocado es
carísimo de corregir. Y diría que sí si el problema es volumen de escritura sostenido con acceso
siempre por clave conocida y latencia estricta — que es exactamente para lo que DynamoDB está
hecho. Una alternativa intermedia que propondría antes de migrar entera: mover solo la parte
caliente —por ejemplo, la consulta de estado de pedido por id, que es la de más volumen— y dejar el
resto en relacional.

---

# 04 — Sharding y particionado

**04 → 1. ¿Qué diferencia hay entre particionado y sharding?**

⏱️ El particionado divide una tabla dentro del mismo motor; el sharding reparte entre instancias
independientes que no se conocen.
🗣️ Con particionado local sigues teniendo una base de datos: los `JOIN` funcionan, las
transacciones cruzan particiones y las consultas las resuelve el motor. Con sharding se acabaron
las dos cosas.
🔬 El particionado es barato y reversible; el sharding cambia el modelo de programación entero y
es prácticamente irreversible. Confundirlos lleva a proponer lo segundo cuando bastaba lo primero.

**04 → 2. Nombra cuatro estrategias de reparto.**

⏱️ Por rango, por hash, hash consistente y por directorio.
🗣️ Rango asigna intervalos de la clave a cada shard; hash reparte con `hash(clave) mod N`;
consistente coloca claves y nodos en un anillo; directorio mantiene una tabla que dice dónde vive
cada entidad.
🔬 Se eligen por **cómo consultas**: rango si las consultas son de rango, hash si solo importa el
reparto, consistente si los nodos van a cambiar, directorio si hay tenants de tamaños muy
dispares.

**04 → 3. ¿Qué es el hash consistente?**

⏱️ Colocar claves y nodos en un anillo, de modo que cada clave va al siguiente nodo del anillo.
🗣️ Su ventaja es el rebalanceo: añadir o quitar un nodo solo mueve la fracción de claves que le
corresponde, no todas. Pasar de 4 a 5 nodos mueve alrededor del 20 % en vez del 80 % que movería
`mod N`.
🔬 Se usa con **nodos virtuales**: cada nodo físico ocupa muchas posiciones del anillo, lo que
suaviza el reparto y evita que un nodo quede con un arco desproporcionado. Es lo que hacen
Cassandra, DynamoDB y los clústeres de Redis.

**04 → 4. ¿Qué problema resuelve el sharding?**

⏱️ Uno solo: escritura que no cabe en una máquina.
🗣️ Y crea muchos: se acaban los `JOIN`, las transacciones que cruzan, la unicidad global, las
agregaciones y la paginación por desplazamiento. Si el cuello de botella es de lectura, réplicas y
caché lo resuelven sin ninguna de esas consecuencias.
🔬 Por eso la respuesta a "hay que shardear" empieza siempre por comprobar qué está saturado. En la
práctica, la mayoría de los "problemas de escala" son planes de ejecución malos, falta de índices o
lecturas repetidas.

**04 → 5. ¿Cuáles son los tres criterios para elegir la clave de shard?**

⏱️ Cardinalidad alta, reparto uniforme y alineación con el patrón de acceso.
🗣️ Los dos primeros garantizan que los datos se distribuyen; el tercero, que las consultas
frecuentes caigan en un solo shard. El tercero es el que la gente olvida y el que más cuesta.
🔬 Casi siempre la clave correcta es la entidad de negocio por la que consultas —cliente, tenant,
cuenta—, porque mantiene juntas las cosas que se leen juntas. Shardear pedidos por `pedidoId`
reparte perfecto y hace que "pedidos de un cliente" toque todos los shards.

**04 → 6. ¿Por qué repartir por fecha produce un punto caliente?**

⏱️ Porque toda la escritura de hoy cae en el mismo shard: el que cubre el rango actual.
🗣️ Los datos temporales se escriben siempre en el extremo del rango, así que un shard recibe el
100 % de las inserciones mientras los demás solo sirven lecturas de histórico. El reparto de datos
es uniforme y el de **tráfico** no lo es en absoluto.
🔬 Es el modo de fallo clásico del reparto por rango y aparece también en DynamoDB con una PK de
fecha. Se mitiga combinando la fecha con otra dimensión —`fecha#region`, `fecha#fragmento`— o
eligiendo otra clave si el acceso lo permite.

**04 → 7. ¿Qué problema tiene `hash mod N` al añadir un nodo?**

⏱️ Que cambia la función de reparto para todas las claves, así que casi todos los datos hay que
moverlos.
🗣️ Pasar de 4 a 5 nodos reubica en torno al 80 % de las claves: una migración masiva con el
sistema en producción, durante la cual una clave puede estar en dos sitios o en ninguno.
🔬 Por eso se usa hash consistente, que acota el movimiento a la fracción del nodo nuevo. Y por eso
se sobre-particiona: con 1.024 particiones lógicas repartidas entre 4 nodos, añadir un nodo es
mover particiones enteras sin recalcular ninguna clave.

**04 → 8. ¿Qué es sobre-particionar y qué resuelve?**

⏱️ Crear muchas más particiones lógicas que nodos físicos desde el principio, y repartirlas.
🗣️ Con 1.024 particiones lógicas sobre 4 nodos, cada nodo tiene 256. Al añadir un quinto, se le
mueven unas 205 particiones enteras: no se recalcula ninguna clave, solo cambia el nodo que sirve
cada partición.
🔬 Es lo que hacen Kafka con sus particiones y Elasticsearch con sus shards, y por eso ambos piden
ese número al crear y no dejan reducirlo. La decisión es elegir un número alto desde el día uno: se
paga algo de sobrecarga por partición y se compra un rebalanceo manejable para siempre.

**04 → 9. ¿Qué pasa con los ids autoincrementales al shardear?**

⏱️ Dejan de servir: dos shards generarían el mismo identificador.
🗣️ Las salidas son UUID —sencillo, y produce índices peores porque no es ordenado—, UUIDv7 o ULID
—ordenables por tiempo, que recuperan buena parte de la localidad—, o un generador tipo Snowflake
que combina marca de tiempo, identificador de nodo y secuencia.
🔬 La elección tiene consecuencias de rendimiento: un identificador aleatorio en un índice
agrupado provoca inserciones dispersas y fragmentación. Por eso los formatos ordenables por tiempo
son hoy la opción por defecto.

**04 → 10. ¿Por qué el reparto por rango es bueno para consultas de rango?**

⏱️ Porque las claves contiguas viven en el mismo shard, así que una consulta de rango toca pocos.
🗣️ "Pedidos entre el 1 y el 7 de septiembre" con reparto por fecha se resuelve consultando uno o
dos shards. Con reparto por hash, esas mismas claves están dispersas y hay que preguntar a todos y
combinar.
🔬 Es el compromiso central del capítulo: rango da localidad y arriesga puntos calientes; hash da
reparto y destruye la localidad. Elegir sin mirar las consultas es cómo se acaba con un sistema que
reparte muy bien y responde muy mal.

**04 → 11. ¿Qué es la estrategia de directorio y cuándo se usa?**

⏱️ Una tabla de enrutamiento que dice explícitamente en qué shard vive cada entidad.
🗣️ Da máxima flexibilidad: puedes mover un cliente grande a su propio shard sin tocar la función de
reparto, y puedes mezclar modelos. Se usa cuando los tenants o clientes tienen tamaños muy
dispares.
🔬 Su coste: una indirección que hay que consultar en cada operación —y por tanto cachear— y que es
un punto único de fallo si no se replica. Es la base del modelo híbrido multi-tenant de
[`08`](#08--persistencia-políglota-y-multi-tenant).

**04 → 12. Enumera seis cosas que se rompen al shardear.**

⏱️ `JOIN` entre shards, transacciones cruzadas, ids autoincrementales, unicidad global,
agregaciones y paginación.
🗣️ Y dos más que se olvidan: las migraciones de esquema hay que aplicarlas N veces y pueden
divergir, y los backups son N que deben ser consistentes entre sí en el tiempo.
🔬 Poder enumerarlas es lo que demuestra que has shardeado de verdad. La que más duele en la
práctica es la paginación, y la que más riesgo de negocio tiene es la unicidad: "email único" deja
de garantizarlo la base de datos.

**04 → 13. ¿Por qué la paginación por desplazamiento deja de funcionar?**

⏱️ Porque para servir `OFFSET 10000` cada shard tiene que devolver 10.020 filas para poder ordenar
globalmente.
🗣️ El nodo que compone la respuesta no puede saber qué filas de cada shard caen en la página 500
sin traerlas todas hasta ahí. El coste crece con el desplazamiento y con el número de shards a la
vez.
🔬 La solución es paginación por cursor: "dame los 20 posteriores a esta clave". Cada shard
devuelve solo 20, el coste es constante y no depende de lo profundo que estés. El precio es que se
pierde el salto a una página arbitraria, que casi ninguna interfaz necesita de verdad.

**04 → 14. ¿Cómo garantizas unicidad global tras shardear?**

⏱️ O eliges el campo único como clave de shard, o necesitas un servicio dedicado que la garantice.
🗣️ Si shardeas por `email`, la unicidad del email la sigue garantizando la restricción local de ese
shard, porque todos los registros con ese email están ahí. Si shardeas por otra cosa, hace falta
una tabla o servicio central de reserva de emails, consultado antes de insertar.
🔬 El servicio central introduce un punto de coordinación y una posible incoherencia si la reserva
y la inserción no son atómicas: hay que reservar primero, insertar después, y liberar la reserva si
la inserción falla. Es una saga en miniatura, y por eso la primera opción —alinear la clave de
shard con la restricción— es mucho mejor cuando es posible.

**04 → 15. ¿Qué haces antes de shardear, y en qué orden?**

⏱️ Índices y consultas, escalar vertical, réplicas de lectura, caché, archivar lo frío, y separar
por dominio. En ese orden.
🗣️ El 80 % de los "problemas de escala" son un plan de ejecución malo o un índice que falta.
Duplicar la máquina es un ticket, no un proyecto. Si el problema es de lectura, réplicas y caché lo
resuelven entero. Y el 90 % de las filas suele ser histórico que nadie consulta, así que archivar
reduce el problema sin tocar la arquitectura.
🔬 El paso 6 —separar por dominio— es el que más se salta: si la tabla enorme mezcla tres
subdominios, darles bases de datos separadas puede resolver el volumen sin partir ninguna. Y si
tras los seis pasos el problema sigue siendo escritura que no cabe, entonces sí, sharding con los
ojos abiertos.

**04 → 16. ¿Por qué la estrategia se elige por cómo consultas y no por cómo escribes?**

⏱️ Porque la escritura siempre se reparte bien con una clave de cardinalidad alta; lo que se rompe
o no es la lectura.
🗣️ Cualquier hash reparte las escrituras. La pregunta difícil es si tus consultas van a tocar un
shard o todos. Elegir hash y descubrir que el 90 % de las consultas son por rango significa que
cada consulta pregunta a todos los nodos, y eso no se corrige sin migrar.
🔬 La excepción es el punto caliente de escritura —reparto por fecha—, que sí es un problema de
escritura. Pero incluso ahí la solución se busca mirando si las consultas toleran otra clave. La
regla práctica: escribe la lista de consultas frecuentes y comprueba cuántos shards toca cada una
con cada estrategia candidata.

**04 → 17. ¿Cómo haces un `COUNT(*)` global en un sistema shardeado?**

⏱️ Preguntando a todos los shards y sumando, o manteniendo un contador aproximado actualizado por
eventos.
🗣️ La consulta dispersa funciona y su latencia es la del shard más lento, así que no sirve para el
camino del usuario con muchos shards. El contador aproximado —incrementado por un consumidor de
eventos— responde al instante y puede desviarse, lo que casi siempre es aceptable para una cifra
de panel.
🔬 Lo importante es decir en voz alta lo que se pierde: **las cifras exactas en tiempo real dejan
de estar disponibles**. En dominios donde el número tiene que cuadrar —contabilidad, regulatorio—,
la salida es un proceso de agregación periódico con su marca de tiempo, y comunicar que la cifra es
"a las 3:00 de hoy" en vez de fingir que es instantánea.

**04 → 18. ¿Por qué el caso multi-tenant es el más limpio para shardear?**

⏱️ Porque `tenantId` cumple los tres criterios: cardinalidad alta, y toda consulta de un cliente
cae en un solo shard.
🗣️ Los datos de un tenant no se cruzan con los de otro, así que no hay `JOIN` entre shards que
echar de menos: el reparto coincide con la frontera natural del dominio. Es el único caso donde
shardear no rompe casi nada.
🔬 El único problema que queda es el reparto desigual: tenants de tamaños muy distintos. Se resuelve
con estrategia de directorio, que permite mover un tenant grande a su propio shard sin tocar a los
demás. Por eso el modelo híbrido de [`08`](#08--persistencia-políglota-y-multi-tenant) es la
respuesta habitual en producto B2B.

**04 → 19. ¿Qué pasa con las migraciones de esquema al shardear?**

⏱️ Hay que aplicarlas N veces, pueden fallar en algunas y quedar divergentes entre shards.
🗣️ Una migración que en un sistema normal es un despliegue pasa a ser una operación orquestada:
aplicar, verificar y controlar el estado de cada shard. Si falla en tres de veinte, tienes tres
esquemas distintos en producción y el código tiene que tolerarlo.
🔬 Lo que lo hace manejable: migraciones **siempre compatibles hacia atrás** con expand/contract,
de modo que un shard adelantado y otro atrasado puedan convivir con el mismo código; una
herramienta que controle el estado por shard; y una verificación que compare los esquemas y alerte
de divergencias.

**04 → 20. ¿Por qué el sharding es prácticamente irreversible?**

⏱️ Porque cambiar la clave o volver a un solo nodo exige mover todos los datos con el sistema en
producción.
🗣️ Y no es solo mover datos: el código se escribió asumiendo que no hay `JOIN`, que los ids son
UUID, que la unicidad la garantiza otro mecanismo y que las agregaciones se componen. Deshacer eso
es reescribir la capa de datos entera.
🔬 Por eso la decisión se toma con los seis pasos previos agotados y con la clave elegida a partir
de las consultas, no de la intuición. Es el ejemplo canónico de decisión de arquitectura de
[`01-bases/01`](../01-bases/01-fundamentos-del-arquitecto.md): cara de revertir, y por eso merece
análisis previo.

**04 → 21. Diseña el sharding de una plataforma multi-tenant con 5.000 clientes, donde tres concentran el 40 % del volumen.**

⏱️ Directorio con modelo híbrido: los 4.997 pequeños repartidos por hash de `tenantId` entre shards
compartidos, y los tres grandes con shard propio.
🗣️ El diseño:

```text
Tabla de directorio (replicada y cacheada): tenantId → shard
  tenant_grande_1 → shard_dedicado_1
  tenant_grande_2 → shard_dedicado_2
  tenant_grande_3 → shard_dedicado_3
  el resto        → hash(tenantId) sobre N shards compartidos

Clave de shard: tenantId. Toda consulta de un cliente cae en un shard.
```

El directorio es lo que permite mover un tenant sin cambiar la función de reparto: cuando uno de
los pequeños crece, se le asigna shard propio y se migra solo él.
🔬 Detalles que el entrevistador buscará. El **directorio se cachea agresivamente** —cambia muy
poco— y se replica, porque si cae no se puede enrutar nada. La **migración de un tenant** es un
procedimiento: doble escritura temporal, copia, verificación, cambio en el directorio, y limpieza.
Las **consultas transversales** —"cuántos pedidos hay en toda la plataforma"— dejan de ser una
consulta y pasan a ser una agregación periódica, y hay que decirlo. Y hay un caso que conviene
anticipar: un tenant que crece **dentro** de un shard compartido degrada a los que comparten shard
con él, así que hace falta vigilar el consumo por tenant y actuar antes de que moleste, no después.

**04 → 22. Te dicen "la base de datos no aguanta, hay que shardear". ¿Qué preguntas y qué propones antes?**

⏱️ Pregunto qué está saturado exactamente —lectura o escritura— y propongo los seis pasos previos
en orden.
🗣️ Las preguntas: ¿qué métrica dice que no aguanta: CPU, entrada/salida, conexiones, latencia de
qué consultas? ¿Es lectura o escritura? ¿Cuánto del volumen es histórico que nadie consulta? ¿Se ha
revisado el plan de ejecución de las consultas lentas? ¿Qué tamaño tiene la máquina y cuánto queda
por encima?
🔬 Lo que propongo, en orden y con el argumento de cada paso: revisar índices y consultas, porque el
80 % de los casos se resuelve ahí y cuesta días en vez de meses; escalar vertical, que es reversible
en minutos; réplicas si el cuello es lectura, que lo es casi siempre; caché si las mismas lecturas
se repiten; archivar el histórico, que suele reducir la tabla en un orden de magnitud; y separar por
dominio si la tabla mezcla subdominios. Y si tras todo eso la escritura sigue sin caber, entonces
shardeamos — con la lista de consultas delante para elegir la clave, y enumerando en voz alta lo que
vamos a perder. El argumento que cierra: el sharding es la decisión más cara de revertir del
sistema, así que se toma la última, no la primera.

**04 → 23. Tras shardear por `pedidoId`, la consulta "pedidos de un cliente" tarda 4 segundos. Diagnostica y propón dos salidas.**

⏱️ La clave de shard no está alineada con el patrón de acceso: esa consulta toca todos los shards y
la latencia es la del más lento.
🗣️ Con `pedidoId` como clave, los pedidos de un cliente están repartidos uniformemente entre todos
los shards. Cada consulta de cliente se convierte en una consulta dispersa a N nodos, con
composición y ordenación en la aplicación. La latencia no es la media, es el **máximo** de los N, y
empeora con cada shard que añades.
🔬 Dos salidas, con su coste. Primera: **re-shardear por `clienteId`**, que alinea la clave con el
acceso dominante y hace la consulta local a un shard. Es lo correcto de diseño y es una migración
completa de la capa de datos, con el riesgo de que un cliente muy grande desequilibre un shard.
Segunda: **mantener una proyección de lectura por cliente** —una vista alimentada por eventos o
CDC, indexada por `clienteId`— que sirva esa consulta sin tocar los shards. Es CQRS de
[`06`](#06--cqrs) y no requiere migrar, a cambio de consistencia eventual y de un componente más
que mantener. Yo propondría la segunda si "pedido por id" también es frecuente —porque
re-shardear la rompería— y la primera si el acceso por cliente es claramente dominante. Y en
cualquier caso mediría antes: si la consulta por cliente es el 5 % del tráfico, quizá cuatro
segundos son tolerables y no vale la pena ninguna de las dos.

---

# 05 — Réplicas y lag

**05 → 1. ¿Qué diferencia hay entre replicación síncrona y asíncrona?**

⏱️ La síncrona espera a que la réplica confirme antes de responder al cliente; la asíncrona
responde y replica después.
🗣️ La asíncrona es rápida y puede perder lo confirmado si el primario cae antes de replicar. La
síncrona no pierde nada y paga una ida y vuelta de red en cada escritura.
🔬 Es la elección de RPO expresada en la configuración del motor: asíncrona significa RPO mayor que
cero, y casi nadie comprueba cuál tiene su sistema. La asíncrona es el valor por defecto en la
mayoría de los motores.

**05 → 2. ¿Qué es el lag de replicación?**

⏱️ El retraso de una réplica respecto del primario, medido en segundos o en bytes de log
pendientes.
🗣️ No es constante: sube con la carga de escritura, con una migración de esquema, con un backup, o
si la réplica tiene menos recursos que el primario.
🔬 Es lo que rompe las garantías de sesión: read-your-writes, monotonic reads y writes-follow-reads.
Y se mide bien con una sonda sintética, no solo con la métrica del motor.

**05 → 3. ¿Qué es la replicación semisíncrona?**

⏱️ Esperar a que **una** réplica de N confirme, en vez de todas o ninguna.
🗣️ Es el compromiso habitual: garantiza que la escritura existe en al menos dos sitios sin pagar la
latencia de esperar a todas las réplicas ni depender de que todas estén vivas.
🔬 Su letra pequeña: si la única réplica síncrona cae, muchos motores degradan a asíncrona para no
bloquear escrituras, y en ese momento tu RPO deja de ser cero sin que nadie lo note. Conviene
alertar sobre ese cambio de modo.

**05 → 4. Nombra cuatro estrategias para enrutar lecturas.**

⏱️ Por tipo de operación, por criticidad declarada, pegajosa al primario tras escribir, y por token
de versión.
🗣️ Por tipo es lo más simple y rompe read-your-writes. Por criticidad —`readOnly = true`— es la más
usada. Pegajosa resuelve read-your-writes con muy poco esfuerzo. Por token es la única con garantía
real y la más cara.
🔬 La combinación que resuelve el 95 % de los casos: `readOnly` para enrutar más pegajosa al
primario durante unos segundos tras escribir. Barata, cubre read-your-writes y no requiere propagar
tokens.

**05 → 5. ¿Qué es el cerebro dividido?**

⏱️ Que dos nodos se creen primarios a la vez y ambos acepten escrituras.
🗣️ Ocurre cuando el primario no está muerto sino aislado por una partición de red: el sistema
promueve una réplica, y el viejo primario sigue aceptando escrituras que nadie replicará. Al
reunirse la red, hay dos historias incompatibles.
🔬 Se evita con quórum —solo se promueve si la mayoría está de acuerdo— y con *fencing*: un
mecanismo que hace al viejo primario incapaz de seguir escribiendo, típicamente un token creciente
que el almacenamiento rechaza si es antiguo.

**05 → 6. ¿Qué garantía de sesión rompe el lag más visiblemente?**

⏱️ Read-your-writes: escribes y al recargar no lo ves.
🗣️ Es la que el usuario nota de inmediato y la que genera tickets de soporte, porque parece que el
sistema no guardó el cambio. Las otras dos —monotonic reads y writes-follow-reads— producen
síntomas más raros y menos frecuentes.
🔬 Y es también la más barata de resolver: basta con enrutar las lecturas de quien acaba de escribir
al primario durante unos segundos. No hace falta replicación síncrona ni consistencia fuerte.

**05 → 7. ¿Por qué el lag no es constante?**

⏱️ Porque depende de la carga de escritura del primario y de los recursos de la réplica en ese
momento.
🗣️ Sube con picos de escritura, con migraciones de esquema que generan mucho log, con backups que
compiten por entrada/salida en la réplica, y con consultas analíticas pesadas ejecutándose en ella.
🔬 Por eso se mide el p99 y no la media: un sistema con p50 de 50 ms y p99 de 6 segundos se comporta
de dos formas distintas, y la segunda es la que produce los incidentes. Y por eso se alerta sobre el
lag, no solo se observa.

**05 → 8. ¿Qué relación hay entre replicación asíncrona y la D de ACID?**

⏱️ Que la durabilidad es local al nodo: lo confirmado por el primario puede perderse si muere antes
de replicar.
🗣️ La transacción se confirmó, el cliente recibió el acuse, y sin embargo esa escritura solo existía
en un disco. Si ese nodo se pierde y se promueve una réplica que no la recibió, la operación
desaparece.
🔬 Ese hueco es exactamente tu RPO, y hay que conocer su número. Se cierra con replicación síncrona
o semisíncrona, a cambio de latencia en cada escritura. Es una decisión de negocio disfrazada de
parámetro de configuración.

**05 → 9. ¿Qué es la lectura pegajosa al primario y qué resuelve?**

⏱️ Enrutar al primario todas las lecturas de un usuario durante N segundos después de que haya
escrito. Resuelve read-your-writes.
🗣️ Se implementa con una marca en la sesión o en el token: al escribir se anota el instante, y
mientras no pasen N segundos sus lecturas van al primario. El resto de usuarios sigue leyendo de
réplicas.
🔬 El valor de N se calibra por encima del p99 del lag, con margen. Su coste es carga adicional en
el primario proporcional a cuánta gente escribe, que suele ser una fracción pequeña del tráfico. Es
la solución con mejor relación coste/beneficio del capítulo.

**05 → 10. ¿Por qué `readOnly = true` puede introducir un bug?**

⏱️ Porque enruta la consulta a una réplica, y si esa consulta no tolera lag, has añadido una lectura
obsoleta sin darte cuenta.
🗣️ La anotación se pone por costumbre —es buena práctica para optimizar el contexto de persistencia—
y en un sistema con enrutamiento por ese flag pasa a tener una consecuencia distinta: decide de qué
base de datos lees.
🔬 Es un caso de acoplamiento accidental entre una optimización de JPA y una decisión de
arquitectura. La defensa: separar las dos cosas con una anotación propia que exprese la intención
—`@LeeDeReplica`— en vez de reutilizar `readOnly`, y revisar en la migración qué consultas lo tenían
por costumbre.

**05 → 11. ¿Qué son los CRDT y para qué sirven?**

⏱️ Estructuras de datos que convergen por construcción, sin necesidad de resolver conflictos.
🗣️ Un contador que solo suma, un conjunto donde solo se añade, un registro de "última escritura
gana" con orden bien definido: operaciones conmutativas cuyo resultado no depende del orden ni de
las repeticiones. Sirven para multi-primario sin coordinación.
🔬 Su límite es la expresividad: funcionan para contadores, conjuntos y poco más. No hay CRDT que
represente "descontar stock sin bajar de cero", porque esa regla no es conmutativa. Por eso en
dominios con invariantes no sustituyen a la coordinación.

**05 → 12. ¿Cómo se mide el lag de forma que sirva para hablar con negocio?**

⏱️ Con una sonda sintética: escribir un valor con marca de tiempo y leerlo de cada réplica hasta
verlo.
🗣️ La diferencia entre ambos instantes, en el p99, es el número que se lleva a negocio: *"un cambio
tarda hasta 800 milisegundos en verse desde una réplica"*. Las métricas del motor —bytes o segundos
de retraso— son útiles para operar pero no son el número que el negocio entiende.
🔬 Conviene medirla por réplica y en los momentos malos, no en media. Y conviene convertirla en un
objetivo declarado con alerta: si el p99 supera cinco segundos, hay incidente. Sin ese umbral
acordado, "el sistema va retrasado" es una queja y no un hecho medible.

**05 → 13. ¿Qué se pierde exactamente en una conmutación con réplica asíncrona?**

⏱️ Las transacciones confirmadas por el primario que no llegaron a replicarse antes de su caída.
🗣️ El volumen depende del lag en ese instante: si la réplica iba 500 ms por detrás, se pierde lo
escrito en esos 500 ms. Con un pico de escritura y un lag de varios segundos, pueden ser miles de
operaciones.
🔬 Y hay un problema añadido: esas operaciones **fueron confirmadas al cliente**, así que el usuario
cree que ocurrieron. Por eso en dominios con dinero se usa replicación síncrona al menos a una
réplica, y por eso la conciliación posterior es obligatoria: es la única forma de detectar qué se
perdió.

**05 → 14. ¿Cómo se evita el cerebro dividido?**

⏱️ Con quórum para promover y con *fencing* para impedir que el viejo primario siga escribiendo.
🗣️ El quórum asegura que solo se promueve si la mayoría de nodos lo acuerda, lo que impide que dos
mitades de una red partida elijan cada una su primario. El fencing añade la segunda mitad:
aunque el viejo primario se crea vivo, un token creciente hace que el almacenamiento rechace sus
escrituras.
🔬 El quórum solo no basta: el viejo primario puede estar aislado y seguir aceptando escrituras de
clientes que también están de su lado de la partición. Sin fencing, esas escrituras existen y se
pierden en la reunificación. Es el detalle que distingue una respuesta leída de una vivida.

**05 → 15. ¿Por qué monotonic reads es la rotura más desconcertante?**

⏱️ Porque el dato aparece y desaparece entre dos recargas, sin ningún patrón que el usuario pueda
entender.
🗣️ Ocurre cuando el balanceador reparte entre réplicas con lag distinto: la primera lectura va a una
réplica al día y ve el cambio; la segunda va a otra retrasada y no lo ve. Para el usuario, el
sistema "pierde" datos que acaba de mostrar.
🔬 Y es difícil de reproducir, porque depende de a qué réplica te toque. Se resuelve con afinidad de
sesión a una réplica concreta —cada usuario siempre a la misma— o enrutando al primario. La afinidad
es suficiente y barata: garantiza que el tiempo nunca va hacia atrás para un usuario dado.

**05 → 16. ¿Cuál es el paso más lento de una conmutación y por qué?**

⏱️ Redirigir a los clientes. Detectar y promover son rápidos; que todo el mundo se entere, no.
🗣️ Si la redirección depende de DNS, la caché de resolución de los clientes puede tardar minutos
aunque el TTL sea corto, porque no todos los resolvedores lo respetan. Si depende de un proxy o de
la configuración del driver, es más rápido pero hay que reiniciar pools de conexiones.
🔬 Ese total —detección más promoción más redirección— es tu RTO real, y casi siempre es mayor de lo
que la gente estima. Las arquitecturas que lo reducen usan un proxy de base de datos o un
descubrimiento de servicios que los clientes consultan, en vez de DNS. Y en cualquier caso hay que
medirlo en un ensayo, no estimarlo.

**05 → 17. ¿Por qué "gana la última escritura" pierde datos en silencio?**

⏱️ Porque descarta una de las dos escrituras conflictivas sin avisar a nadie.
🗣️ Si dos primarios reciben una modificación del mismo registro, la política elige una y tira la
otra. El usuario cuya escritura se descartó recibió confirmación de que su cambio se guardó, y no
volverá a aparecer nunca.
🔬 Y hay un problema añadido: "la última" se decide por marca de tiempo, que depende de relojes que
no están sincronizados entre máquinas. Una deriva de unos milisegundos puede hacer que gane la
escritura que llegó primero. Por eso en dominios con dinero no hay política de resolución
aceptable, y la salida es particionar para que el conflicto no pueda ocurrir.

**05 → 18. ¿Cuál es la salida al multi-primario en banca?**

⏱️ Particionar por entidad: cada cuenta tiene una región dueña que acepta sus escrituras, y la otra
sirve lecturas.
🗣️ Es activo-activo a nivel de plataforma —ambas regiones procesan trabajo real y están probadas— y
activo-pasivo a nivel de registro, lo que elimina el conflicto por diseño en vez de intentar
resolverlo después.
🔬 Lo que hay que resolver: el enrutamiento por cuenta en el borde, que añade complejidad; la
promoción de la región dueña cuando una cae, que debe ser un procedimiento explícito y ensayado; y
las operaciones que cruzan cuentas de regiones distintas —una transferencia—, que vuelven a ser una
saga. El RPO no es cero: es el retraso de replicación, y se declara o se compra síncrona solo para
las cuentas que lo justifiquen.

**05 → 19. ¿Qué combinación de enrutamiento resuelve el 95 % de los casos?**

⏱️ `readOnly` para enrutar a réplica, más pegajosa al primario unos segundos tras escribir, más
primario siempre para lo que decide dinero.
🗣️ La primera parte escala las lecturas, que es el objetivo. La segunda cubre read-your-writes, que
es el síntoma que el usuario nota. La tercera protege los flujos donde un dato obsoleto produce una
decisión incorrecta.
🔬 Lo que deliberadamente deja fuera es el token de versión, que es la única garantía real y la más
cara: se reserva para el flujo concreto donde la garantía sea un requisito escrito —un comprobante,
una confirmación legal— en vez de aplicarlo a todo el sistema. Esa selectividad es lo que hace la
combinación barata.

**05 → 20. ¿Qué pregunta desmonta un plan de conmutación por error?**

⏱️ ¿Cuándo fue la última vez que lo ensayaron?
🗣️ Casi siempre la respuesta es "nunca" o "cuando lo montamos". Un mecanismo que no se ha ejecutado
no está verificado: puede fallar la promoción, la redirección puede tardar más del RTO objetivo, o
la réplica puede resultar no tener los permisos o la configuración correctos.
🔬 Es exactamente la misma pregunta que la de los backups en
[`01-bases/10`](../01-bases/10-alta-disponibilidad-y-escalado.md), y por el mismo motivo: la
existencia de un mecanismo no es evidencia de que funcione. La segunda pregunta, igual de buena:
¿cuánto tardó, y coincide con el RTO que habéis declarado?

**05 → 21. Diseña el enrutamiento de lecturas de un e-commerce: qué va al primario, qué a réplica, y cómo garantizas read-your-writes.**

⏱️ Catálogo y búsqueda a réplica; carrito, checkout y todo lo que decida dinero al primario;
read-your-writes con pegajosa tras escribir.
🗣️ El reparto:

```text
PRIMARIO   → carrito del usuario, checkout, stock al reservar, pago, "mis pedidos"
             justo después de comprar
RÉPLICA    → catálogo, búsqueda, listados, recomendaciones, histórico de pedidos antiguo
PEGAJOSA   → tras cualquier escritura del usuario, sus lecturas van al primario N segundos
             (N = p99 del lag + margen)
```

La marca de pegajosidad va en la sesión o en el token, y se consulta en el enrutador del
`DataSource`.
🔬 Los matices que importan. **"Mis pedidos" cambia de lado según el momento**: justo después de
comprar va al primario por la pegajosa, y a partir de ahí a réplica. **El stock se lee de réplica
para mostrar y del primario para reservar**, que es la distinción clave del capítulo anterior.
**La búsqueda probablemente ni siquiera está en la base de datos** sino en un índice, y ahí el lag
es otro y se mide aparte. Y hay que vigilar `readOnly = true`: si se usa como criterio de
enrutamiento, cualquier consulta que lo tenga por costumbre pasa a leer de réplica, así que en la
migración hay que revisarlas una a una.

**05 → 22. Tras añadir réplicas, los usuarios reportan que sus cambios "a veces no se guardan". Diagnostica y propón dos soluciones con su coste.**

⏱️ No es que no se guarden: es read-your-writes roto. El usuario escribe en el primario y lee de
una réplica que aún no recibió el cambio.
🗣️ El diagnóstico se confirma con dos observaciones: los cambios sí están en la base de datos si se
consultan al primario, y el "a veces" correlaciona con el lag —falla más en horas de mucha
escritura—. Que sea intermitente es la firma: si fuera un bug de guardado, fallaría siempre.
🔬 Dos soluciones con su coste. **Pegajosa al primario tras escribir**: se marca la sesión al
escribir y sus lecturas van al primario durante un intervalo mayor que el p99 del lag. Coste: algo
más de carga en el primario, proporcional a la fracción de usuarios que escriben, que suele ser
pequeña. Es lo que yo haría. **Token de versión**: la escritura devuelve una posición del log, la
lectura la lleva y se enruta a una réplica que la haya alcanzado o al primario. Coste: propagar el
token por toda la aplicación, exponer la posición de cada réplica, y decidir qué hacer si ninguna la
alcanza en el timeout. Da garantía real y es bastante más trabajo. Una tercera opción barata que
mencionaría: devolver el objeto guardado en la respuesta de la escritura, para que la interfaz no
tenga que releer — resuelve el caso inmediato aunque no la recarga.

**05 → 23. Te piden multi-primario entre dos regiones para una app de mensajería. ¿Funciona aquí? Justifica y di qué cambiarías si fuera un banco.**

⏱️ En mensajería sí funciona razonablemente, porque las escrituras son mayoritariamente inserciones
independientes. En un banco no, y habría que particionar por cuenta.
🗣️ En mensajería, el patrón dominante es insertar mensajes nuevos: dos usuarios escribiendo en
regiones distintas no modifican el mismo registro, así que el conflicto es raro. Donde sí aparece
—estado de "leído", edición de un mensaje, nombre de un grupo— las anomalías son tolerables: que un
"leído" se resuelva mal no tiene consecuencias graves, y algunos de esos casos se modelan bien como
CRDT. El orden dentro de una conversación se resuelve con marcas lógicas y no requiere coordinación
global.
🔬 En un banco cambia todo, porque el registro conflictivo es el saldo y no hay política aceptable:
"gana la última" significa perder un movimiento, y además depende de relojes no sincronizados.
Además hay requisitos regulatorios de residencia y de trazabilidad que complican tener el mismo dato
escribible en dos jurisdicciones. Lo que propondría: **partición por cuenta con región dueña**,
ambas regiones activas sirviendo su porción y lecturas de la otra, con promoción explícita y
ensayada ante caída. Y modelar los movimientos como inserciones con identificador —no como
mutaciones de un contador— que es lo que hace que la conciliación pueda detectar y corregir
cualquier divergencia. En mensajería el conflicto es tolerable; en banca se elimina por diseño.

---

# 06 — CQRS

**06 → 1. ¿Qué significa CQRS?**

⏱️ *Command Query Responsibility Segregation*: separar el modelo que escribe del que lee.
🗣️ Un comando cambia estado y no devuelve datos; una consulta devuelve datos y no cambia estado.
Elevado a arquitectura, significa que cada lado puede tener su propio modelo, su propia forma y su
propio almacén.
🔬 No implica event sourcing, ni dos bases de datos, ni mensajería. Es un continuo de tres niveles,
y el error más común es saltar al tercero cuando el primero resolvía el problema.

**06 → 2. ¿De qué principio de Meyer deriva?**

⏱️ De CQS: *Command Query Separation*. Un método o cambia estado o devuelve datos, nunca ambos.
🗣️ Es un principio de diseño de objetos: hace el código más predecible, porque puedes llamar a una
consulta sin miedo a efectos secundarios. Greg Young lo elevó al nivel de arquitectura y lo llamó
CQRS.
🔬 La diferencia entre ambos es de escala: CQS habla de métodos, CQRS de modelos completos. Citar
la genealogía demuestra lectura y sitúa bien la respuesta.

**06 → 3. ¿Cuáles son los tres niveles de separación?**

⏱️ Modelos separados sobre la misma base de datos; bases separadas con réplicas; y un almacén de
lectura con otra forma.
🗣️ Nivel 1: la escritura usa el agregado y la lectura consulta con SQL directo a DTOs, sin pasar por
el dominio. Nivel 2: las lecturas van a réplicas. Nivel 3: una proyección construida desde eventos,
en otro almacén y con la forma que la consulta necesita.
🔬 El nivel 1 no tiene consistencia eventual y cuesta casi nada: es el 80 % del valor. La
consistencia eventual aparece en el nivel 2 y el coste completo —reconstrucción, una vista por
consulta— en el 3.

**06 → 4. ¿Qué es un comando y qué es una consulta, en este contexto?**

⏱️ El comando expresa una intención de cambio y devuelve como mucho un identificador; la consulta
devuelve datos sin modificar nada.
🗣️ `ConfirmarPedido` es un comando: puede rechazarse, cambia estado y no devuelve el listado de
pedidos. `PedidosDelCliente` es una consulta: no toca nada y devuelve una forma optimizada para
mostrar.
🔬 Un comando puede devolver el objeto creado, y de hecho conviene: es la forma más barata de
resolver la ventana de inconsistencia. Lo que no hace es devolver resultados de consulta que
obliguen al modelo de escritura a saber cómo se muestran las cosas.

**06 → 5. ¿Necesita CQRS event sourcing?**

⏱️ No. CQRS funciona perfectamente sobre tablas normales.
🗣️ Casi todo el CQRS útil que existe en producción no usa event sourcing: separa modelos y proyecta
desde eventos de integración o desde CDC, con el estado en tablas relacionales de toda la vida.
🔬 Adoptarlos juntos multiplica el coste: versionado de eventos para siempre, snapshots,
reconstrucción, consistencia eventual y una curva de entrada alta, todo a la vez. Separarlos es lo
que permite pagar solo lo que hace falta.

**06 → 6. ¿Necesita event sourcing CQRS?**

⏱️ Sí, obligatoriamente.
🗣️ El log de eventos responde muy bien a "dame el agregado X" y fatal a cualquier consulta por
criterio: "todas las cuentas con saldo negativo" obligaría a reconstruir todas las cuentas. La
única salida son proyecciones, y eso es CQRS.
🔬 Por eso, al evaluar event sourcing, hay que sumar el coste de CQRS entero. No son dos decisiones
independientes: elegir event sourcing es elegir también proyecciones, consistencia eventual y
reconstrucción.

**06 → 7. ¿Qué es el nivel 1 y qué cuesta?**

⏱️ Modelos separados sobre la misma base de datos: el agregado para escribir, SQL directo a DTOs
para leer. Cuesta casi nada.
🗣️ La consulta no pasa por el dominio ni por las entidades JPA: proyecta directamente a un `record`
con los campos que la pantalla necesita. Desaparecen el N+1, los DTO intermedios y las relaciones
perezosas puestas solo para que la vista funcione.
🔬 Y no tiene consistencia eventual, porque es la misma base de datos y la misma transacción. Es el
nivel que casi nadie llama CQRS y que resuelve la mayoría de los síntomas por los que la gente
propone CQRS.

**06 → 8. ¿En qué nivel aparece la consistencia eventual?**

⏱️ En el nivel 2, con réplicas, y se agrava en el 3 con proyecciones.
🗣️ El nivel 1 comparte base de datos y transacción, así que no hay ventana. El 2 introduce el lag de
replicación. El 3 añade el lag del consumidor que alimenta la proyección, que puede ser bastante
mayor.
🔬 Es un argumento práctico para quedarse en el nivel 1 cuando se puede: si el requisito incluye
consistencia inmediata en la lectura, los niveles 2 y 3 están descartados y conviene saberlo antes
de diseñar.

**06 → 9. ¿Qué diferencias hay entre el nivel 2 y el nivel 3?**

⏱️ El 2 es una copia del mismo modelo; el 3 es un modelo distinto con otra forma.
🗣️ En el nivel 2 la réplica tiene las mismas tablas: escalas lecturas pero las consultas siguen
teniendo la misma dificultad. En el nivel 3 construyes una vista desnormalizada, o un índice de
búsqueda, o una tabla plana: cambias la forma del dato para que la consulta sea trivial.
🔬 Por eso el nivel 2 resuelve problemas de **volumen** y el 3 resuelve problemas de **forma**. Si tu
consulta es lenta por hacer seis `JOIN`, añadir réplicas no la arregla: la hace lenta en más sitios.

**06 → 10. ¿Por qué el modelo único produce N+1 y DTOs intermedios?**

⏱️ Porque el modelo optimizado para proteger invariantes al escribir no es el que sirve para mostrar
listados.
🗣️ El agregado quiere cargarse entero y consistente; la pantalla quiere veinte campos de cinco
tablas. Forzar ambos sobre las mismas entidades produce relaciones perezosas que explotan al
serializar, `JOIN FETCH` puestos para casos concretos, y DTOs que aplanan lo que el dominio había
estructurado.
🔬 Es el mismo conflicto que el del agregado contra JPA de
[`01-bases/07`](../01-bases/07-ddd-tactico.md), visto desde el lado de la lectura. Y es la razón
por la que el nivel 1 de CQRS mejora tanto por tan poco: deja de pedirle al modelo de dominio que
sirva consultas.

**06 → 11. Nombra cuatro formas de manejar la ventana de cara al usuario.**

⏱️ Devolver el resultado en la respuesta del comando, leer del modelo de escritura lo propio, token
de versión, o decírselo al usuario.
🗣️ La primera resuelve el 80 % y casi nadie la propone: el `POST` devuelve el objeto creado y la
interfaz lo pinta sin consultar. La segunda cubre la recarga. La tercera da garantía real. La
cuarta es mostrar "procesando" y avisar después.
🔬 Solo la tercera es una garantía; las otras tres son mitigaciones de experiencia de usuario, que
casi siempre es lo que el problema pedía en realidad.

**06 → 12. ¿Por qué el nivel 1 es "el 80 % del valor"?**

⏱️ Porque elimina los síntomas más molestos —N+1, DTOs estériles, consultas lentas por el modelo—
sin introducir consistencia eventual ni infraestructura nueva.
🗣️ La mayoría de los equipos que proponen CQRS lo hacen porque una pantalla va lenta o porque el
modelo se ha vuelto incómodo. Ambas cosas se arreglan proyectando con SQL directo, y eso no requiere
eventos, ni otro almacén, ni reconstrucción.
🔬 Y deja la puerta abierta: una vez que el lado de lectura es independiente, moverlo al nivel 3 más
adelante es un cambio local, no un rediseño. Empezar por el 1 es además la ruta de menor riesgo
hacia el 3.

**06 → 13. ¿Cuándo NO compensa CQRS?**

⏱️ CRUD con poca lógica, lecturas y escrituras simétricas, volumen bajo, o equipo sin experiencia en
el nivel 3.
🗣️ Si lees lo mismo que escribes y la carga es moderada, no hay dos problemas distintos que separar:
CQRS añade clases y no quita nada. Y si el requisito incluye consistencia inmediata en la lectura,
el nivel 3 está descartado de entrada.
🔬 La señal de que sí compensa es concreta: **la consulta que duele existe y está identificada**, y
hay asimetría de carga medida. "Listado que cruza tres servicios, paginado y ordenado, con 3.000
peticiones por segundo" es un caso; "queremos CQRS" no lo es.

**06 → 14. ¿Qué dos señales indican que sí compensa?**

⏱️ Una consulta concreta identificada y medida que el modelo de escritura no puede servir bien, y
asimetría real de carga.
🗣️ La primera es de forma: la consulta necesita datos de varios agregados o servicios, con filtro,
orden y paginación. La segunda es de volumen: 10.000 lecturas por segundo contra 50 escrituras
justifica separar; 100 contra 80 no.
🔬 Si solo se da la segunda, réplicas bastan y no hace falta CQRS del nivel 3. Si solo se da la
primera, quizá basta el nivel 1 con una consulta bien escrita. El nivel 3 se justifica cuando ambas
coinciden.

**06 → 15. ¿Por qué CQRS se aplica por caso de uso y no al sistema?**

⏱️ Porque solo algunas consultas tienen el problema, y aplicarlo a todo duplica clases sin retorno.
🗣️ En un sistema típico, dos o tres pantallas concentran la dificultad y el resto son CRUD normales.
Separar modelos en esas dos o tres es barato y rentable; separarlos en las cuarenta restantes
significa mantener dos representaciones de todo y arriesgarse a que diverjan.
🔬 Es el mismo criterio que el DDD táctico de [`01-bases/07`](../01-bases/07-ddd-tactico.md):
ceremonia donde hay retorno, simplicidad donde no. Responder "lo aplicaría a esta consulta y no al
sistema" es la respuesta madura.

**06 → 16. ¿Qué preguntas antes de subir del nivel 1 al nivel 3?**

⏱️ ¿El problema es volumen o forma? ¿Tolera el negocio consistencia eventual en esa consulta?
¿Quién opera la proyección y cómo se reconstruye?
🗣️ Si el problema es volumen sobre los mismos datos, el nivel 2 basta. Si es la forma —búsqueda,
agregados, cruces entre servicios— entonces sí. Y si la consulta exige leer inmediatamente lo que se
acaba de escribir, el nivel 3 no sirve por definición.
🔬 La tercera pregunta es la que se olvida y la que más duele después: una proyección necesita
alguien que vigile su lag, un procedimiento de reconstrucción probado, y la disciplina de no meterle
efectos externos. Si el equipo no está preparado para eso, el nivel 3 crea más incidentes de los
que resuelve.

**06 → 17. ¿Por qué intentar eliminar la ventana es un error?**

⏱️ Porque eliminarla significa volver a la escritura síncrona, que es justo lo que se quería evitar.
🗣️ Si el comando no responde hasta que la proyección está actualizada, has acoplado la escritura a
la lectura y has perdido el beneficio: ahora la disponibilidad de escribir depende de que la
proyección funcione, y la latencia es la suma de ambas.
🔬 La pregunta correcta es qué ve el usuario **dentro** de la ventana, y casi siempre se resuelve
con la respuesta del comando o con un estado explícito. Quien persigue la eliminación acaba
reinventando una transacción distribuida, con todos sus problemas y ninguna de sus garantías.

**06 → 18. Si la ventana dura minutos en vez de milisegundos, ¿qué diagnosticas?**

⏱️ No es un problema de CQRS, es lag del consumidor: la proyección no da abasto o está bloqueada.
🗣️ Una ventana de milisegundos es el comportamiento esperado; una de minutos significa que el
consumidor va por detrás. Las causas habituales: falta de paralelismo, un mensaje envenenado que
bloquea una partición, o una proyección que hace demasiado trabajo por evento.
🔬 Se diagnostica con la métrica de lag del consumidor, y se distingue entre lag general —capacidad,
se escala— y lag en una sola partición —mensaje envenenado o partición caliente, y escalar no
ayuda—. Es [`02-eventos/04`](../02-eventos/04-colas-dlq-y-reintentos.md) y no un problema de diseño
de CQRS.

**06 → 19. ¿Qué pasa si aplicas CQRS por dogma a todo el sistema?**

⏱️ Duplicas el número de clases y repartes la lógica en dos sitios que pueden divergir.
🗣️ Cada entidad pasa a tener modelo de escritura, modelo de lectura y la traducción entre ambos. Un
cambio de negocio hay que aplicarlo en los dos lados, y cuando alguien olvide uno, la vista dirá
algo distinto que el modelo de escritura sin que ningún test lo detecte.
🔬 Y con el nivel 3, multiplicas también la infraestructura: una proyección por consulta, cada una
con su lag, su reconstrucción y sus alertas. El coste operativo crece linealmente con el número de
vistas, y la mayoría de ellas no lo justificaban.

**06 → 20. ¿Por qué CQRS sin event sourcing es lo común en producción?**

⏱️ Porque da el beneficio —modelos separados y vistas optimizadas— sin el coste de versionar eventos
para siempre.
🗣️ Se proyecta desde eventos de integración o desde CDC, con el estado en tablas normales. Puedes
reconstruir la vista desde la tabla de origen, que sigue siendo la fuente de verdad y admite
consultas ad hoc. Y si la proyección se estropea, el sistema sigue funcionando.
🔬 Con event sourcing, en cambio, el log es la única verdad: no hay tabla a la que recurrir, el
versionado de eventos es permanente y la reconstrucción depende de la retención. Separar las dos
decisiones permite quedarse con la parte barata, y por eso es lo que se ve en la mayoría de los
sistemas reales.

**06 → 21. Una pantalla cruza datos de pedidos, clientes y envíos, con filtro y paginación, y tarda 6 segundos. Diseña la solución por niveles.**

⏱️ Empiezo por el nivel 1 con una consulta bien escrita; si los datos están en servicios distintos,
subo al nivel 3 con una proyección.
🗣️ El razonamiento por niveles:

```text
Nivel 0 — ¿es un problema de consulta? Plan de ejecución, índices, N+1.
          Seis segundos con JOIN sobre tres tablas suele ser un índice que falta.
Nivel 1 — misma base de datos, consulta directa a DTO, sin pasar por entidades.
          Si las tres viven en el mismo esquema, esto probablemente lo resuelve.
Nivel 2 — si además hay volumen, esa consulta va a réplica. No arregla la forma.
Nivel 3 — si pedidos, clientes y envíos son SERVICIOS distintos con bases propias,
          no hay JOIN posible: proyección alimentada por eventos de los tres.
```

🔬 La pregunta que decide es si los tres son tablas del mismo esquema o servicios independientes. En
el primer caso, subir al nivel 3 sería sobre-ingeniería: una consulta bien indexada y proyectada a
un `record` resuelve el problema sin introducir consistencia eventual. En el segundo, no hay
alternativa: la composición de API no puede paginar ni ordenar por un campo de otro servicio. Y si
voy al nivel 3, declaro el paquete completo: una tabla desnormalizada por pedido, `upsert`
idempotente, tolerancia al desorden con versión por origen, sin efectos externos, y un procedimiento
de reconstrucción en paralelo. Mediría antes de decidir: si el problema es un índice, ninguna
arquitectura lo va a arreglar mejor que el índice.

**06 → 22. Te proponen CQRS con event sourcing y Kafka para un CRUD de catálogo. Argumenta y propón la alternativa.**

⏱️ Es tres decisiones caras para un problema que probablemente no existe. Pregunto qué consulta duele
y propongo el nivel 1.
🗣️ Un catálogo es el caso arquetípico de CRUD: se lee mucho, se escribe poco, no hay invariantes
complejas y nadie necesita saber cómo se llegó al estado actual. Event sourcing traería versionado
de eventos para siempre, snapshots y reconstrucción; Kafka, un sistema distribuido que operar; CQRS
del nivel 3, una proyección por consulta con su lag y sus alertas. Ninguna de las tres resuelve nada
que un catálogo pida.
🔬 Lo que propongo, en orden: revisar índices y consultas, porque un catálogo lento casi siempre es
eso; nivel 1 de CQRS —proyectar a DTOs con SQL directo— si el modelo estorba; y **caché** con
invalidación por evento si el volumen de lectura es alto, que es lo que un catálogo de verdad
necesita y cuesta una fracción. Si más adelante hace falta búsqueda por texto con facetas, entonces
sí un índice invertido alimentado por eventos — y eso es nivel 3 para **una** consulta, no para el
sistema. El argumento que suele funcionar: preguntar qué pregunta de negocio necesita el histórico
de cambios del catálogo. Si no hay ninguna, event sourcing está descartado por su propio criterio.

**06 → 23. Diseña el lado de lectura de "buscar pedidos por texto libre, filtrar por estado y ordenar por fecha", con 200 peticiones por segundo.**

⏱️ Índice invertido —Elasticsearch u OpenSearch— alimentado por eventos, con la tabla relacional
como fuente de verdad.
🗣️ El requisito que decide es el **texto libre**: una base relacional puede hacer búsqueda de texto,
pero combinarla con filtros y orden sobre 200 peticiones por segundo la castiga. Un índice invertido
está hecho exactamente para eso: texto con relevancia, facetas por estado y orden por fecha en la
misma consulta.

```text
Escritura → tabla relacional (fuente de verdad) + outbox
Proyección→ consumidor que indexa en Elasticsearch: id, texto, estado, fecha, cliente
Lectura   → consulta al índice, que devuelve ids + los campos mostrados
```

🔬 Lo que hay que decidir y declarar. **Qué se guarda en el índice**: si solo ids, hace falta un
`GetItem` por resultado contra la base de datos, lo que multiplica las llamadas; si se guardan los
campos mostrados, la búsqueda se resuelve entera en el índice a cambio de duplicar datos — que es lo
correcto aquí. **La ventana**: un pedido recién creado tarda en ser buscable, y hay que acordarlo
con negocio o mostrarlo desde el modelo de escritura si el usuario acaba de crearlo. **La
reconstrucción**: índice nuevo en paralelo, verificación y cambio por alias, que Elasticsearch
soporta de forma nativa. Y una alternativa que valoraría antes: si el "texto libre" es en realidad
buscar por número de pedido o nombre de cliente, la búsqueda de texto de Postgres con un índice GIN
puede bastar, y evita añadir un motor entero. Comprobarlo primero es más barato que descubrirlo
después.

---

# 07 — Caché

**07 → 1. Nombra cinco patrones de caché.**

⏱️ Cache-aside, read-through, write-through, write-behind y refresh-ahead.
🗣️ Cache-aside: la aplicación mira la caché y, si falla, consulta el origen y guarda. Read-through:
la caché consulta por ti. Write-through: escribes en la caché y esta escribe en el origen a la vez.
Write-behind: persiste después, asíncrono. Refresh-ahead: refresca lo popular antes de que caduque.
🔬 Cache-aside es el valor por defecto y el único que sobrevive con dignidad a que la caché se
caiga: se degrada a consultar el origen. Los demás se eligen por una razón concreta.

**07 → 2. ¿Qué es cache-aside?**

⏱️ La aplicación gestiona la caché: mira primero, y si falla, consulta el origen y guarda el
resultado.
🗣️ Solo se cachea lo que se pide, y la caché puede caerse sin romper nada porque la aplicación sabe
ir al origen. Es el patrón más usado con diferencia.
🔬 Su defecto: en cada fallo se paga la latencia completa, y **la primera petición de cada clave
siempre falla**. Es el patrón que sufre la estampida cuando una clave popular caduca.

**07 → 3. ¿Qué es el thundering herd aplicado a caché?**

⏱️ Que una clave popular caduca y miles de peticiones van al origen a la vez.
🗣️ Con 5.000 peticiones por segundo sobre la misma clave, el instante de la caducidad produce 5.000
fallos simultáneos y 5.000 consultas idénticas contra la base de datos, que puede caer llevándose
consigo al sistema que la caché protegía.
🔬 Las defensas: TTL con jitter, que es gratis y rompe la sincronía; bloqueo o coalescencia, donde
solo el primero recalcula; y refresh-ahead, que refresca antes de caducar. La primera resuelve la
mayoría de los casos.

**07 → 4. ¿Qué tres estrategias de invalidación existen?**

⏱️ TTL, invalidación explícita al escribir, e invalidación por evento.
🗣️ El TTL expira la entrada sola y no requiere coordinación. La explícita borra la entrada al
modificar el dato, y es precisa pero frágil. La de evento escucha al servicio dueño del dato y es la
única que funciona entre servicios.
🔬 La combinación correcta casi siempre son las tres: precisa para la frescura, **más TTL como red
de seguridad**. Sin TTL, un evento perdido deja un dato obsoleto para siempre y nadie lo detecta.

**07 → 5. ¿Qué es la caché fría?**

⏱️ Una caché vacía tras un reinicio o un despliegue: todo el tráfico va al origen.
🗣️ Es un caso de thundering herd que no depende del TTL sino del ciclo de vida del proceso. Con
caché en proceso, escalar a 50 instancias significa 50 cachés frías, y por eso escalar puede empeorar
el sistema en vez de mejorarlo.
🔬 Se mitiga con precalentamiento —poblar las claves más consultadas al arrancar—, con despliegues
graduales que no reinicien todo a la vez, y con una caché distribuida que sobreviva al reinicio de
la aplicación.

**07 → 6. ¿Qué diferencia hay entre write-through y write-behind?**

⏱️ Write-through escribe en el origen sincronizadamente; write-behind lo hace después, de forma
asíncrona.
🗣️ Con write-through la caché nunca está obsoleta y cada escritura paga la latencia de ambos. Con
write-behind las escrituras son muy rápidas y absorben picos, a cambio de que lo no persistido se
pierda si la caché cae.
🔬 Por eso write-behind solo es aceptable para datos desechables: contadores de visitas, métricas de
uso. Usarlo para datos de negocio es aceptar pérdida silenciosa a cambio de latencia.

**07 → 7. ¿Por qué write-behind puede perder datos?**

⏱️ Porque confirma la escritura antes de que esté en el almacén duradero.
🗣️ Entre el momento en que la caché acepta el dato y el momento en que lo persiste hay una ventana.
Si el nodo de caché cae en esa ventana, ese dato no existe en ninguna parte y nadie lo sabe: la
aplicación recibió confirmación.
🔬 Es exactamente el mismo problema que la replicación asíncrona de
[`05`](#05--réplicas-y-lag): confirmar antes de durar. La diferencia es que en una caché la pérdida
es total y no parcial, porque no hay log del que recuperar.

**07 → 8. ¿Por qué es más seguro borrar la entrada que actualizarla?**

⏱️ Porque con concurrencia, actualizar puede dejar el valor viejo en la caché de forma permanente.
🗣️ Si dos escrituras concurrentes actualizan la entrada, el orden en que llegan a la caché puede no
coincidir con el orden en que llegaron a la base de datos: la caché acaba con el valor antiguo y el
origen con el nuevo, y el TTL es lo único que lo corrige. Si borras, la siguiente lectura recarga el
valor correcto.
🔬 Hay una condición de carrera residual incluso borrando —una lectura que cargó el valor viejo y lo
guarda después del borrado— que se mitiga con TTL corto o con invalidación retardada. Pero es mucho
menos probable y menos duradera que la de actualizar.

**07 → 9. ¿Qué problema tiene la caché en proceso con varias instancias?**

⏱️ Que hay N copias que se invalidan por separado, así que pueden divergir.
🗣️ Con 20 instancias tienes 20 cachés. Invalidar en una no afecta a las otras 19, así que un usuario
puede ver el dato nuevo en una petición y el viejo en la siguiente, según a qué instancia le toque.
Es monotonic reads roto a nivel de caché.
🔬 Se resuelve con invalidación por evento —todas escuchan y borran— o aceptando la incoherencia con
un TTL muy corto y midiéndola. Y hay un segundo problema: N cachés frías al escalar o desplegar, que
convierte el escalado en un pico de carga sobre el origen.

**07 → 10. ¿Qué es el TTL con jitter y qué resuelve?**

⏱️ Añadir una variación aleatoria al TTL —300 ± 30 segundos— para que las entradas no caduquen todas
a la vez.
🗣️ Resuelve la estampida: sin jitter, las claves cargadas en el mismo instante caducan en el mismo
instante y producen un pico sincronizado. Con jitter, las caducidades se reparten y el origen recibe
una curva en vez de un muro.
🔬 Es la defensa más barata del capítulo —cuesta una línea— y es la misma idea que el jitter del
reintento de [`01-bases/09`](../01-bases/09-resiliencia.md): romper la sincronía accidental. Debería
ser el valor por defecto de cualquier caché con TTL.

**07 → 11. ¿Por qué la invalidación por evento es la única que funciona entre servicios?**

⏱️ Porque si el dato lo cambia otro equipo, tu código no tiene forma de "acordarse" de invalidar.
🗣️ La invalidación explícita exige que quien escribe conozca todas las cachés que contienen ese
dato. Entre servicios eso es imposible: el servicio de catálogo no sabe quién cachea sus productos y
no debería saberlo.
🔬 Con eventos, el servicio dueño publica `ProductoActualizado` y cada consumidor decide qué hacer.
La caché se convierte en un consumidor más, con su lag y su necesidad de idempotencia — que aquí es
trivial, porque invalidar dos veces es inofensivo.

**07 → 12. ¿Qué significa realmente el valor del TTL?**

⏱️ La cantidad de obsolescencia que el negocio acepta para ese dato.
🗣️ Un TTL de 60 segundos declara que servir un dato de hasta un minuto es aceptable. Eso no es un
parámetro técnico: es una decisión de producto que alguien debe haber tomado y que conviene tener por
escrito.
🔬 Por eso "TTL de 5 minutos" sin justificación es una respuesta incompleta. La buena nombra el dato
y el criterio: *"el catálogo cambia dos veces al día, así que cinco minutos de obsolescencia es
irrelevante; el saldo no se cachea en absoluto"*.

**07 → 13. ¿Por qué la invalidación explícita es frágil?**

⏱️ Porque hay que acordarse en **todos** los caminos de escritura, y siempre aparece uno que se
olvidó.
🗣️ El camino normal de la aplicación se cubre. Los que se olvidan: los trabajos por lotes, las
migraciones, el script de corrección que ejecutó soporte, el consumidor de eventos que actualiza el
dato por otra vía, y el endpoint de administración que nadie recordaba.
🔬 De ahí la regla de combinar siempre con TTL: la invalidación explícita da frescura en el camino
conocido, y el TTL garantiza que cualquier olvido tiene fecha de caducidad. La alternativa más
robusta es invalidar por evento o por CDC, que captura **todos** los cambios del dato por
construcción.

**07 → 14. ¿Por qué hay que combinar invalidación precisa y TTL?**

⏱️ Porque la precisa da frescura y el TTL garantiza que cualquier fallo de invalidación se corrige
solo.
🗣️ Con solo TTL, el dato está obsoleto durante todo el intervalo aunque haya cambiado hace un
segundo. Con solo invalidación precisa, un evento perdido o un camino de escritura olvidado deja el
dato obsoleto **para siempre**, y nadie lo detecta porque no hay error.
🔬 Juntas: la invalidación precisa hace que el dato esté fresco casi siempre, y el TTL acota el peor
caso a un valor conocido. Es exactamente el mismo razonamiento que outbox más idempotencia: un
mecanismo para el caso normal y otro para el fallo.

**07 → 15. ¿Cómo distingues una estampida de un pico de tráfico normal?**

⏱️ Por la periodicidad: si los picos coinciden con el intervalo del TTL, es estampida.
🗣️ Un pico de tráfico real viene acompañado de más peticiones entrantes. Una estampida no: las
peticiones entrantes son constantes y lo que sube es la carga sobre el **origen**, en picos
regulares separados exactamente por el TTL.
🔬 Se confirma comparando tres series: peticiones entrantes, tasa de aciertos de caché y consultas al
origen. Si las entrantes son planas, la tasa de aciertos cae en picos y las consultas al origen
suben a la vez, es estampida. La corrección inmediata es jitter, y la de fondo, coalescencia o
refresh-ahead.

**07 → 16. ¿Por qué escalar a 50 instancias con caché local puede empeorar el sistema?**

⏱️ Porque son 50 cachés frías y 50 conjuntos de claves distintos: la tasa de aciertos se hunde.
🗣️ Con una instancia, las claves populares se cachean una vez y se sirven muchas. Con 50, cada
instancia tiene que cargar por su cuenta las mismas claves, así que el origen recibe hasta 50 veces
más fallos iniciales. Y al desplegar, las 50 arrancan frías a la vez.
🔬 Es un caso en el que la intuición —más instancias, más capacidad— falla. La salida es caché
distribuida, que comparte una sola copia, o una caché de dos niveles con la local como acelerador y
Redis detrás. Y en cualquier caso, despliegues graduales para no enfriar todo a la vez.

**07 → 17. ¿Qué preguntas para saber si tu caché es una optimización o una dependencia?**

⏱️ ¿Aguanta el origen todo el tráfico si la caché desaparece ahora mismo?
🗣️ Con un 95 % de aciertos y 5.000 peticiones por segundo, el origen recibe 250. Si la caché cae,
recibe 5.000. Si la base de datos no aguanta 5.000, la caché no es una optimización: es un
componente crítico del que depende la disponibilidad del sistema.
🔬 La respuesta cambia cómo la operas: una dependencia crítica necesita alta disponibilidad,
monitorización, plan de recuperación y ensayo, no un nodo suelto. Y si no puedes darle eso, la
salida intermedia es **limitar la tasa hacia el origen** cuando la caché falla, sirviendo errores o
datos degradados al resto en vez de tumbar la base de datos.

**07 → 18. ¿Qué datos no se cachean y por qué?**

⏱️ Los que deciden dinero en el instante, los personales en cachés compartidas sin control de
acceso, y los que casi nunca se repiten.
🗣️ Un saldo disponible o un límite de crédito cacheados producen decisiones sobre datos obsoletos,
y eso no se corrige después. Los datos personales en una caché compartida son un problema de
cumplimiento normativo si no hay aislamiento por clave y por tenant. Y cachear lo que no se vuelve a
pedir es memoria gastada y complejidad añadida.
🔬 Hay un cuarto caso menos obvio: los datos con alta cardinalidad y baja repetición —resultados de
búsquedas muy específicas— que llenan la caché y desplazan a las claves realmente populares. Ahí la
caché no solo no ayuda, empeora la tasa de aciertos del resto.

**07 → 19. ¿Qué ganas y qué pierdes con una caché de dos niveles?**

⏱️ Ganas latencia de nanosegundos en el primer nivel; pierdes coherencia, porque el nivel local puede
divergir entre instancias.
🗣️ El nivel 1 en proceso sirve las claves más calientes sin salir a la red; el nivel 2 en Redis da
una sola copia compartida y sobrevive a los reinicios. La mayoría de las peticiones ni siquiera
llegan a Redis.
🔬 El TTL corto del nivel 1 **es** tu ventana de incoherencia: si es de cinco segundos, dos
instancias pueden servir valores distintos durante cinco segundos. Redis ofrece invalidación
empujada al cliente para acortar esa ventana, y es lo que hace viable el patrón cuando el dato
importa. En cualquier caso, es un modo de fallo más que hay que conocer y medir.

**07 → 20. ¿Qué haces si la caché cae y el origen no aguanta el tráfico?**

⏱️ Limitar la tasa hacia el origen y degradar el resto: servir errores o datos parciales antes que
tumbar la base de datos.
🗣️ La secuencia: un limitador delante del origen deja pasar solo lo que aguanta; el resto recibe una
respuesta degradada —contenido por defecto, lista vacía marcada como tal, o un error explícito—.
Así el sistema se degrada de forma controlada en vez de caer entero.
🔬 Y a medio plazo: si la caché es crítica, necesita alta disponibilidad —réplica, conmutación— y un
procedimiento de precalentamiento para no arrancar fría. Lo que no se hace es dejarlo como está y
llamarlo "optimización": el incidente ya demostró que no lo era. El caso del escenario E4 es
exactamente este.

**07 → 21. Diseña la caché de un catálogo: 5.000 productos, cambian dos veces al día, 40.000 lecturas por segundo, p99 de 50 ms.**

⏱️ El catálogo entero cabe en memoria: caché en proceso con recarga por evento, Redis como respaldo,
y TTL largo con jitter como red de seguridad.
🗣️ Los números deciden: 5.000 productos son decenas de megabytes, y la relación lectura/escritura es
de millones a uno. A 40.000 por segundo, incluso Redis añade una ida y vuelta por petición y se
convierte en contención.

```text
Nivel 1 → catálogo completo en memoria de cada instancia. Lectura = acceso a un mapa.
Nivel 2 → Redis, para poblar al arrancar sin golpear la base de datos.
Origen  → base de datos, consultada solo al refrescar.
Invalidación → evento CatalogoActualizado al publicar cambios; cada instancia recarga.
TTL     → largo (una hora) con jitter, solo como red de seguridad por si un evento se pierde.
```

🔬 Lo que declaro: incoherencia temporal entre instancias durante la recarga, del orden de segundos,
aceptable con un catálogo que cambia dos veces al día. Memoria por instancia, que limita el
crecimiento: si el catálogo llegara a millones de productos, este diseño no sirve y habría que volver
a Redis más CDN. Y el precalentamiento al arrancar es obligatorio: sin él, cada despliegue produce
un pico contra el origen. Añadiría una CDN delante para las respuestas cacheables por región, que
absorbe buena parte de los 40.000 antes de llegar a la aplicación.

**07 → 22. La base de datos tiene picos cada 5 minutos que coinciden con el TTL. Diagnostica y da tres soluciones con su coste.**

⏱️ Es estampida: las claves cargadas juntas caducan juntas. Las soluciones son jitter, coalescencia
y refresh-ahead.
🗣️ El diagnóstico se confirma con tres series: peticiones entrantes planas, tasa de aciertos que cae
en picos cada cinco minutos, y consultas al origen que suben en el mismo instante. Que la
periodicidad coincida exactamente con el TTL es la firma.
🔬 Las tres soluciones con su coste. **TTL con jitter**: cambiar 300 por 300 ± 30 aleatorio; coste
cero, una línea, y reparte las caducidades. Es lo primero que haría. **Coalescencia de peticiones**:
solo el primer fallo recalcula y los demás esperan su resultado; coste, un bloqueo distribuido que
gestionar y una espera para los que llegan. Resuelve el caso incluso con una sola clave muy caliente,
que el jitter no cubre. **Refresh-ahead**: refrescar las claves populares antes de caducar; coste,
consultas al origen que quizá nadie necesitaba, y un proceso más. Es la mejor experiencia y la más
cara. Aplicaría la primera de inmediato y la segunda si quedan claves individuales con tráfico
suficiente para tumbar el origen por sí solas.

**07 → 23. Un usuario ve el precio antiguo al recargar, y el nuevo al volver a recargar. Reconstruye qué está pasando y cómo lo arreglas.**

⏱️ Caché local por instancia con invalidación incompleta: unas instancias tienen el valor nuevo y
otras el viejo, y el balanceador reparte.
🗣️ La firma es la alternancia: si fuera un TTL, el valor viejo aparecería hasta caducar y luego el
nuevo de forma estable. Que alterne entre recargas significa que hay varias copias con estados
distintos, y la copia que ves depende de a qué instancia te dirija el balanceador. Es monotonic reads
roto a nivel de caché.
🔬 La causa raíz suele ser una de dos: invalidación explícita que solo borró la caché de la instancia
que procesó la escritura —las otras 19 no se enteraron—, o invalidación por evento que falló en
algunas instancias. El arreglo, en tres niveles. **Inmediato**: bajar el TTL del nivel local para
acotar la divergencia a segundos. **De fondo**: invalidación por evento a todas las instancias, o
mover el dato a una caché distribuida donde solo hay una copia. **Defensa**: TTL con jitter como red
de seguridad, y una alerta sobre divergencia —comparar el valor cacheado contra el origen en una
muestra periódica—. Si el precio es un dato que decide dinero, además revisaría si debería estar
cacheado en local en absoluto.

---

# 08 — Persistencia políglota y multi-tenant

**08 → 1. ¿Qué es la persistencia políglota?**

⏱️ Usar la tecnología de almacenamiento que mejor encaja con cada problema, en vez de forzar todo a
una sola.
🗣️ Relacional para pedidos y pagos; índice invertido para búsqueda con relevancia; clave-valor para
sesión; grafo para relaciones profundas. El término es de Fowler y Sadalage.
🔬 La justificación tiene que ser una **capacidad** que el motor actual no tiene, no una preferencia.
Y la primera pregunta es siempre si lo que necesitas cabe en lo que ya tienes: Postgres cubre más
casos de los que la gente supone.

**08 → 2. Nombra las tres estrategias de multi-tenancy.**

⏱️ Base de datos por tenant, esquema por tenant, y tabla compartida con `tenant_id`.
🗣️ La primera da aislamiento máximo y no escala a miles. La segunda es un punto intermedio con una
sola instancia que operar. La tercera escala a miles con coste marginal casi cero, y su aislamiento
depende del código.
🔬 En producción lo que se usa es el **modelo híbrido**: tabla compartida para la mayoría y base
propia para los tenants grandes o con requisitos de residencia, con un directorio que dice dónde vive
cada uno.

**08 → 3. ¿Qué es el vecino ruidoso?**

⏱️ Un tenant cuyo consumo degrada el servicio de los demás porque comparten recursos.
🗣️ En tabla compartida, un cliente que lanza consultas pesadas o que concentra el 40 % del volumen
consume la capacidad de la base de datos y todos lo notan. El problema no es suyo, es del reparto.
🔬 Se ataca con límites de tasa y cuotas por tenant, con índices que empiecen por `tenant_id` para
que las consultas no escaneen datos de otros, y —cuando uno crece demasiado— moviéndolo a su propia
base de datos con la estrategia de directorio.

**08 → 4. ¿Qué es Row-Level Security?**

⏱️ Una política del motor que filtra las filas automáticamente, aunque la consulta no lo pida.
🗣️ En Postgres se declara una política sobre la tabla y el motor añade el filtro a toda consulta de
esa sesión. Un desarrollador que olvide el `WHERE tenant_id = ?` no ve datos ajenos: el motor los
oculta.
🔬 Es la única defensa del modelo de tabla compartida que **no depende de la disciplina**. Todo lo
demás —filtro en el ORM, tenant en el contexto, tests— es mitigación, y basta un olvido para una fuga
entre clientes.

**08 → 5. ¿Qué motor usarías para búsqueda por texto con relevancia?**

⏱️ Un índice invertido: Elasticsearch u OpenSearch.
🗣️ Está hecho para eso: texto con puntuación de relevancia, facetas, sinónimos, tolerancia a erratas
y ordenación combinada, todo en la misma consulta y a gran volumen.
🔬 Antes de añadirlo conviene probar la búsqueda de texto de Postgres con un índice GIN: cubre
bastantes casos —buscar por nombre, por número, por descripción corta— y evita un motor entero con su
respaldo, su parcheo y su guardia. El criterio: si necesitas relevancia, facetas y escala, índice
invertido; si necesitas "contiene este texto", Postgres.

**08 → 6. ¿Qué justifica añadir un motor de datos nuevo?**

⏱️ Una capacidad concreta que el motor actual no tiene y que está identificada y medida.
🗣️ "Búsqueda por texto con relevancia y facetas", "consultas de profundidad variable sobre
relaciones", "escritura de series temporales a un volumen que el relacional no absorbe". Eso son
capacidades. "Es más moderno", "escala mejor" o "el equipo quiere aprenderlo" no lo son.
🔬 Y la pregunta previa siempre es si cabe en lo que ya tienes: `JSONB`, búsqueda de texto y
extensiones cubren muchos casos. Proponer eso antes que un motor nuevo es la respuesta barata que
casi nadie da primero.

**08 → 7. ¿Cuál es el coste real de añadir una tecnología de datos?**

⏱️ La guardia: alguien tiene que saber diagnosticarla a las tres de la mañana.
🗣️ El coste no es la licencia ni el servidor. Es el respaldo y su restauración probada, la
monitorización, el parcheo, el plan de recuperación, la experiencia acumulada, y un modo de fallo
nuevo que el equipo no ha visto.
🔬 Escala mal con el tamaño del equipo: un equipo de cuatro personas no puede mantener experiencia
operativa real en cinco motores distintos. Por eso la persistencia políglota es más defendible en
organizaciones grandes con equipos de plataforma, y más cuestionable en equipos pequeños.

**08 → 8. ¿Cómo se propagan los cambios entre dos almacenes?**

⏱️ Por eventos con outbox, o por CDC. Nunca con doble escritura en el mismo método.
🗣️ Escribir en Postgres y en Elasticsearch en el mismo método es el problema de la doble escritura:
dos sistemas, dos commits, y una ventana en la que uno se aplicó y el otro no. Se resuelve igual que
en [`02-eventos/06`](../02-eventos/06-outbox-y-cdc.md): el evento se escribe en la misma transacción
que el cambio, y un relay lo propaga.
🔬 Y hace falta un mecanismo de reconciliación que detecte la divergencia —conteos comparados,
muestreo periódico— más la capacidad de reconstruir el almacén derivado desde la fuente de verdad. Sin
esas dos cosas, la divergencia aparece y nadie se entera.

**08 → 9. ¿Qué ventajas tiene base de datos por tenant?**

⏱️ Aislamiento máximo: fallo, rendimiento y seguridad separados por construcción.
🗣️ Restaurar el backup de un solo cliente es trivial. Cumplir un requisito de residencia de datos por
país es directo. La facturación por consumo real es medible. Y un cliente no puede ver los datos de
otro ni por error de código.
🔬 Su coste: N migraciones de esquema que pueden divergir, N backups, y un pool de conexiones por
tenant que hace inviable el modelo con cientos de clientes. Es la opción correcta con decenas de
tenants grandes, no con miles pequeños.

**08 → 10. ¿Qué ventajas tiene la tabla compartida con `tenant_id`?**

⏱️ Una migración, un backup, un pool, y coste marginal casi cero por tenant.
🗣️ Escala a miles de clientes sin que la operación crezca: el esfuerzo de mantener 10 tenants y 10.000
es el mismo. Es lo que hace viable un producto con muchos clientes pequeños.
🔬 Su riesgo es el aislamiento, que depende del código: un `WHERE tenant_id = ?` olvidado es una fuga
de datos entre clientes, el incidente más grave posible en B2B. Por eso Row-Level Security no es
opcional en este modelo.

**08 → 11. ¿Por qué Postgres evita muchas decisiones de políglota?**

⏱️ Porque cubre con extensiones varios casos para los que la gente añade un motor entero.
🗣️ `JSONB` con índices GIN cubre buena parte del caso documental; la búsqueda de texto integrada
cubre búsquedas que no necesitan relevancia avanzada; `pg_trgm` cubre la búsqueda aproximada; y hay
extensiones para series temporales y para vectores.
🔬 La comparación honesta: ninguna de esas capacidades iguala al motor especializado a gran escala.
Pero "no iguala a Elasticsearch" y "no sirve para tu caso" son cosas distintas, y comprobar la
segunda antes de añadir un motor ahorra una dependencia operativa permanente.

**08 → 12. ¿Cuál es el riesgo principal de la tabla compartida?**

⏱️ Que el aislamiento depende del código: un filtro olvidado es una fuga de datos entre clientes.
🗣️ No hace falta un ataque: basta una consulta nueva escrita con prisa, un informe de administración,
o una corrección manual ejecutada sin el filtro. Y el fallo es silencioso: no hay error, solo datos de
otro cliente donde no deberían estar.
🔬 En un producto B2B es el incidente más grave posible, con consecuencias contractuales y
regulatorias. Por eso la defensa no puede ser la disciplina: tiene que ser Row-Level Security, que
hace que el motor filtre aunque el SQL no lo pida.

**08 → 13. ¿Por qué Row-Level Security es distinta de un filtro en el ORM?**

⏱️ Porque actúa en el motor y no se puede saltar: protege incluso el SQL escrito a mano.
🗣️ Un filtro del ORM cubre las consultas que pasan por el ORM. No cubre el SQL nativo, ni los
trabajos por lotes, ni las consultas de un informe, ni lo que ejecuta soporte en una consola. RLS
cubre todo lo que llegue por esa conexión.
🔬 Se configura estableciendo el tenant en la sesión de base de datos al principio de cada petición, y
la política lo usa. El detalle operativo importante: hay que asegurarse de que la conexión se limpia
al devolverla al pool, o una petición podría heredar el tenant de la anterior — que es exactamente la
fuga que se quería evitar.

**08 → 14. ¿Por qué `tenant_id` debe ser la primera columna del índice?**

⏱️ Porque si no, las consultas de un tenant recorren datos de todos antes de filtrar.
🗣️ Con un índice sobre `(fecha, tenant_id)`, buscar los pedidos de un cliente en un rango de fechas
recorre las fechas de todos los tenants y descarta. Con `(tenant_id, fecha)`, el índice salta
directamente al bloque de ese tenant.
🔬 Es un problema de rendimiento que se agrava con el número de clientes: funciona bien con diez
tenants y se degrada linealmente con mil. Y es también una defensa contra el vecino ruidoso, porque
evita que la consulta de un cliente pequeño haga trabajo proporcional al tamaño total de la tabla.

**08 → 15. ¿Qué significa "una fuente de verdad, el resto derivados"?**

⏱️ Que un almacén manda y los demás son proyecciones que se pueden borrar y reconstruir desde él.
🗣️ El relacional guarda los pedidos; Elasticsearch y Redis tienen copias con otra forma. Si divergen,
no se negocia: se reconstruyen desde la fuente. Eso convierte la divergencia en un incidente
recuperable en vez de en corrupción de datos.
🔬 Sin esa declaración explícita, dos almacenes con datos distintos plantean una pregunta sin
respuesta: ¿cuál es el correcto? Y la respuesta improvisada —"el que se escribió más tarde"— es la
política de "gana la última escritura", con su pérdida silenciosa.

**08 → 16. ¿Por qué base de datos por tenant no escala a miles?**

⏱️ Por las migraciones, los backups y las conexiones: todo se multiplica por el número de clientes.
🗣️ Mil tenants son mil migraciones que orquestar y verificar, con la posibilidad de que fallen en
algunas y queden esquemas divergentes. Son mil backups que gestionar y probar. Y son mil bases de
datos cuyos pools de conexiones no caben en la capacidad de un servidor.
🔬 Hay además un coste fijo por instancia —memoria, procesos, almacenamiento mínimo— que hace
antieconómico el modelo con clientes pequeños: un tenant que genera diez euros al mes no puede
costar una base de datos dedicada.

**08 → 17. ¿Cómo se ataca el vecino ruidoso?**

⏱️ Con límites de tasa y cuotas por tenant, y moviendo al grande a su propia base de datos.
🗣️ Lo primero es medir el consumo por tenant, que casi nadie hace: sin esa métrica no sabes quién
molesta. Después, límites por tenant en la capa de aplicación, y timeouts por consulta para que una
consulta pesada no bloquee recursos indefinidamente.
🔬 Y cuando un tenant crece lo suficiente, la solución estructural es moverlo: con una estrategia de
directorio, se le asigna una base de datos propia sin tocar a los demás. Eso es el modelo híbrido, y
es la razón por la que el directorio compensa su indirección.

**08 → 18. ¿Qué es el modelo híbrido y por qué es la respuesta real?**

⏱️ Tabla compartida para la mayoría, base propia para los grandes o los que tienen requisitos
especiales, y un directorio que dice dónde vive cada uno.
🗣️ Es la respuesta real porque los tenants no son homogéneos: en cualquier producto B2B, unos pocos
clientes concentran la mayor parte del volumen y algunos tienen requisitos regulatorios que los demás
no. Un modelo único obliga a pagar el coste del caso extremo para todos, o a no poder atenderlo.
🔬 El directorio es la pieza que lo hace posible: se cachea agresivamente porque cambia poco, se
replica porque sin él no se puede enrutar nada, y permite mover un tenant sin cambiar la función de
reparto. El procedimiento de migración de un tenant —doble escritura, copia, verificación, cambio en
el directorio— es lo que hay que tener escrito de antemano.

**08 → 19. ¿Qué pasa si no declaras quién manda cuando dos almacenes divergen?**

⏱️ Que la divergencia se convierte en corrupción: nadie sabe qué dato es el correcto.
🗣️ Sin fuente de verdad declarada, ante una discrepancia entre Postgres y Elasticsearch la respuesta
es una investigación caso por caso, y la corrección es manual y arriesgada. Con una declaración
clara, la respuesta es reconstruir el derivado y seguir.
🔬 Y hay una consecuencia de diseño: si el almacén derivado acepta escrituras directas —alguien
corrigió un documento en Elasticsearch a mano—, deja de ser derivado y ya no se puede reconstruir sin
perder esa corrección. La regla que lo evita: los derivados son de solo lectura para todo el mundo
salvo para su proceso de proyección.

**08 → 20. ¿Qué cinco medidas hacen aceptable el modelo de tabla compartida?**

⏱️ Row-Level Security, filtro automático en el ORM, tenant en el contexto de petición, tests de
aislamiento, e índices que empiecen por `tenant_id`.
🗣️ La primera es la única que no depende de la disciplina y es la que de verdad protege. La segunda y
la tercera reducen la probabilidad de error. La cuarta lo verifica en el pipeline: un test que
consulta con el tenant A y espera cero filas de B. La quinta es de rendimiento y evita el vecino
ruidoso.
🔬 Añadiría una sexta operativa: limpiar el tenant de la sesión al devolver la conexión al pool, para
que una petición no herede el de la anterior. Es un fallo sutil, difícil de detectar en pruebas
porque solo aparece bajo concurrencia, y produce exactamente la fuga que las otras cinco medidas
intentan evitar.

**08 → 21. Diseña la multi-tenancy de un SaaS con 3.000 clientes pequeños y 5 grandes, uno de ellos con requisito de residencia de datos en la UE.**

⏱️ Modelo híbrido: tabla compartida con RLS para los 3.000, base propia para los 5 grandes, y la del
cliente europeo desplegada en la UE. Un directorio enruta.
🗣️ El diseño:

```text
Directorio (replicado, cacheado): tenantId → destino
  3.000 pequeños  → clúster compartido, tabla común con tenant_id + Row-Level Security
  4 grandes       → base de datos dedicada cada uno, misma región
  1 europeo       → base de datos dedicada, región UE, con su propio backup y su clave de cifrado

Clave de reparto: tenantId. Toda consulta de un cliente cae en un destino.
```

🔬 Detalles que importan. El **enrutamiento** se resuelve en un punto único al principio de la
petición, no propagando el tenant como parámetro por todas las capas. Las **migraciones** son ahora
seis destinos y deben ser compatibles hacia atrás con expand/contract, porque no se aplicarán todas a
la vez. El **cliente europeo** necesita además que los backups, los logs y cualquier réplica se
queden en la UE, lo que afecta a la observabilidad y no solo a la base de datos. Las **consultas
transversales** —métricas de la plataforma— dejan de ser una consulta y pasan a ser una agregación
periódica desde los seis destinos. Y el **procedimiento de promoción** —cuando un pequeño crece y hay
que darle base propia— tiene que estar escrito y ensayado: doble escritura, copia, verificación,
cambio en el directorio, limpieza.

**08 → 22. Te proponen añadir MongoDB "porque el esquema del catálogo cambia mucho". ¿Qué preguntas y qué propones?**

⏱️ Pregunto qué cambia exactamente y con qué frecuencia, y propongo `JSONB` en Postgres antes de
añadir un motor.
🗣️ Las preguntas: ¿qué parte del catálogo varía, todos los campos o los atributos específicos de cada
tipo de producto? ¿Con qué frecuencia se añaden campos nuevos? ¿Se consulta y filtra por esos campos
variables o solo se muestran? ¿Cuál es el volumen? ¿Qué transacciones cruzan catálogo y otras
entidades? La tercera es la que más decide: mostrar un atributo variable es trivial en `JSONB`;
filtrar y ordenar por él necesita índices y ahí la comparación es más ajustada.
🔬 Lo que propongo: **modelo híbrido dentro de Postgres**, con las columnas estables como columnas
—id, nombre, precio, estado, categoría, que son las que se filtran e indexan— y los atributos
variables en una columna `JSONB` con índice GIN. Eso da esquema flexible donde hace falta y
integridad, transacciones y consultas relacionales donde importan. Añadiría que "el esquema cambia
mucho" a veces significa otra cosa: que faltó modelar bien los tipos de producto, y que la solución
es una tabla de atributos por tipo, no un motor sin esquema. Y si tras probarlo el rendimiento no
llega, entonces sí MongoDB — con la fuente de verdad declarada y la propagación por CDC, no con doble
escritura.

**08 → 23. Un cliente reporta que vio datos de otro cliente. Describe la investigación y las medidas, inmediatas y de fondo.**

⏱️ Es un incidente de seguridad de severidad máxima: contener primero, investigar el alcance después,
y notificar según obligación legal.
🗣️ La investigación, en orden. **Contener**: identificar la funcionalidad concreta donde ocurrió y
desactivarla si se puede; no desplegar arreglos a ciegas antes de entender el alcance. **Reproducir**:
qué consulta, qué usuario, qué tenant, qué momento. **Alcance**: revisar los logs de acceso para
determinar si ese camino se ejecutó otras veces y con qué tenants — la pregunta que legal va a hacer
es cuántos clientes se vieron afectados y qué datos. **Causa raíz**: casi siempre un filtro
`tenant_id` olvidado en una consulta nueva, SQL nativo que esquiva el ORM, un trabajo por lotes, o una
conexión del pool que heredó el tenant de la petición anterior.
🔬 Medidas inmediatas: corregir la consulta, desplegar, y verificar con un test que reproduzca el
caso. Medidas de fondo, que son las que evitan la repetición: **Row-Level Security**, para que el
motor filtre aunque el código no lo pida —si ya estaba, averiguar por qué no actuó, y la respuesta
suele ser que esa conexión no tenía el tenant establecido—; **limpieza del contexto al devolver la
conexión al pool**; **tests de aislamiento en el pipeline**, que consulten con un tenant y verifiquen
cero filas de otro; y **revisión de todo el SQL nativo** del sistema, que es donde el ORM no protege.
Y fuera de lo técnico: notificación al cliente afectado y, según la naturaleza de los datos y la
jurisdicción, a la autoridad de protección de datos dentro del plazo legal. Esa parte no la decide el
arquitecto, pero sí tiene que provocarla.

---

# 09 — Simulación: escenarios de diseño

> Las preguntas `S#` del bloque 2 de [`09`](09-simulacion-de-entrevista.md) se responden con las
> entradas de los capítulos correspondientes, que están arriba. Aquí van los cinco escenarios.

## E1 — El que NO hay que shardear

**Respuesta corta:** no shardeo. Con 200 escrituras y 3.000 lecturas por segundo, el problema es de
lectura y el sharding no lo resuelve.

**El diagnóstico con los números.** 200 escrituras por segundo las absorbe cualquier Postgres
razonable: el sharding, que solo resuelve escritura, no ataca nada. Y 1,2 TB con consultas de 8
segundos apunta a planes de ejecución malos o a falta de índices mucho antes que a volumen: 400
millones de filas con un índice adecuado se consultan en milisegundos.

**El orden que propongo**, y cada paso con lo que espero que dé:

```text
1. Plan de ejecución de las consultas lentas → aquí se resuelve el 80 % de los casos como este
2. Índices que falten, incluidos los compuestos que cubran las consultas frecuentes
3. Archivar: ¿cuántos de esos 400 M son envíos cerrados hace más de un año?
   En logística suele ser el 90 %. Particionado por fecha + purga o traslado a histórico.
4. Réplicas de lectura → 3.000 lecturas se reparten; es el cuello real
5. Caché para las consultas repetidas (estado de un envío se consulta muchas veces)
6. Escalar vertical si tras todo eso sigue justo
```

**Lo que además señalo sobre su propuesta.** Shardear por `envioId` repartiría perfecto las
escrituras y haría que cualquier consulta por cliente, por ruta o por rango de fechas tocara todos
los shards — es el error de alineación entre clave y patrón de acceso. Si algún día hay que
shardear, la clave candidata sería la entidad por la que consultan, no el identificador del envío.

**El particionado local, que es la pieza que más rinde aquí.** Particionar por fecha dentro de
Postgres no es sharding: sigue habiendo una base de datos, `JOIN` y transacciones. Da consultas más
rápidas cuando filtran por fecha, y convierte "borrar lo de hace tres años" en una operación de
metadatos en vez de un `DELETE` de cientos de millones de filas.

**El disparador acordado.** Volvería a plantear sharding si las escrituras superan lo que una
máquina grande absorbe y el archivado ya no reduce el conjunto activo. Ninguna de las dos está cerca.

## E2 — El modelo de DynamoDB

**Respuesta corta:** tabla con `PK=PEDIDO#id`, GSI1 por cliente con fecha ordenable, GSI2 disperso
para pendientes del día — y el cuarto acceso, por número de factura, es el que no encaja bien.

**El diseño**, y está desarrollado en la respuesta [03 → 21](#03--relacional-nosql-y-dynamodb). Lo
que añade este escenario es el cuarto patrón de acceso y los números.

**La búsqueda por número de factura.** Es un acceso por igualdad sobre un atributo que no es la
clave, así que un tercer GSI con `PK=FACTURA#<numero>` lo resuelve. Pero conviene decir en voz alta
lo que cuesta: son ya tres GSI, y cada escritura de pedido consume capacidad cuatro veces. Con 50
millones de pedidos eso es dinero. Si esa búsqueda es rara —soporte buscando una factura concreta—,
valoraría no crear el índice y resolverla desde otro sistema, o aceptar su latencia por otra vía.

**Los números y lo que implican.** 3.000 lecturas por segundo repartidas por `pedidoId` no producen
partición caliente, porque la cardinalidad es máxima. El GSI2, en cambio, tiene
`PK=PENDIENTE#<fecha>`: un solo valor por día concentra todas las lecturas de esa consulta. Si esa
consulta es frecuente, hay que dispersar con sufijo y leer los fragmentos en paralelo.

**Lo que declaro.** Los GSI son eventualmente consistentes, así que un pedido recién creado puede no
aparecer todavía en el listado del cliente ni en pendientes. Si el usuario acaba de crear el pedido y
espera verlo, se resuelve leyendo por la clave principal o devolviéndolo en la respuesta del comando.

**Lo que no haría.** Nada de `Scan` con filtro para ninguno de los cuatro accesos: en una tabla de 50
millones de elementos, cada uno costaría la tabla entera.

## E3 — Consistencia en un e-commerce

**Respuesta corta:** está desarrollado en [01 → 21](#01--cap-pacelc-y-consistencia). Lo que añade
este escenario es dónde vive cada dato y qué ve el usuario.

**Dónde vive cada cosa y por qué.**

```text
Catálogo → réplica + caché agresiva. Cambia poco, se lee mucho, nadie decide dinero con él.
Carrito  → primario (o almacén de sesión). Es del usuario y lo lee él: read-your-writes.
Stock    → primario para RESERVAR (atómico y condicional); réplica o caché para MOSTRAR.
Pedido   → primario. Es el registro de la intención y hay dinero detrás.
Pago     → primario + idempotencia por clave. Sin margen.
```

**La distinción que hace buena la respuesta** sigue siendo la del stock: mostrar disponibilidad
admite obsolescencia —todos los e-commerce la muestran desactualizada— y comprometer una unidad no.

**Qué ve el usuario con retraso, dato a dato.** Catálogo: un precio de hace un minuto, aceptable
siempre que el precio se **revalide al añadir al carrito y al pagar**. Stock: "quedan pocas
unidades" puede estar desfasado, y por eso el fallo real se comunica en el momento de la reserva, no
antes. Pedido: si acaba de comprar y no lo ve en su lista, se resuelve devolviéndolo en la respuesta
del comando y con pegajosa al primario unos segundos.

**La decisión de negocio que hay que provocar.** Si el stock se reserva solo al pagar, hay ventana
de sobreventa; si se reserva al añadir al carrito, hay inventario bloqueado por carritos
abandonados. La salida habitual es reservar en el checkout con TTL, y eso hay que acordarlo con
negocio con el número de sobreventas esperadas al mes.

## E4 — La caché que se volvió crítica

**Respuesta corta:** la caché no era una optimización, era una dependencia crítica sin alta
disponibilidad. Y el reinicio produjo una caché fría que la base de datos no podía absorber.

**La reconstrucción del incidente.** Con un 97 % de aciertos, la base de datos veía 1.200 lecturas
por segundo. Al reiniciarse Redis, la tasa de aciertos cayó a cero y la base de datos pasó a recibir
40.000: 33 veces su carga normal. Se saturó en segundos, y a partir de ahí cada petición que fallaba
reintentaba, amplificando la carga. Los 20 minutos de caída son el tiempo que tardó Redis en
repoblarse compitiendo con una base de datos ya saturada.

**Los tres fallos de diseño**, en orden de gravedad:

```text
1. La caché era crítica y se operaba como si no lo fuera: un nodo sin réplica ni failover.
2. No había límite de tasa hacia el origen, así que la caída de la caché se propagó entera.
3. No había precalentamiento, así que la recuperación fue lenta y competida.
```

**El rediseño.**

```text
Redis en alta disponibilidad → réplica y conmutación automática, para que un reinicio no vacíe todo
Límite de tasa hacia el origen → la base de datos nunca recibe más de lo que aguanta;
                                 el exceso recibe respuesta degradada, no un error de base de datos
Coalescencia de peticiones     → ante un fallo masivo, una sola consulta por clave, no 5.000
Caché en proceso como nivel 1  → el catálogo cabe en memoria: sobrevive al reinicio de Redis
Precalentamiento               → al arrancar, poblar las claves más consultadas antes de recibir tráfico
TTL con jitter                 → para que la repoblación no produzca caducidades sincronizadas
```

**La medida que lo cambia todo.** El nivel 1 en proceso es lo que convierte este incidente en un
no-evento: si el catálogo entero vive en la memoria de cada instancia, Redis puede reiniciarse sin
que la base de datos se entere. Es viable precisamente porque el conjunto de datos es pequeño.

**Lo que mediría después.** La carga que el origen recibe con un 0 % de aciertos, para saber cuál es
el escenario real; y un ensayo periódico de reinicio de Redis en un entorno de preproducción con
tráfico real, porque un mecanismo de recuperación no ensayado no está verificado.

## E5 — Multi-tenant con un cliente enorme

**Respuesta corta:** modelo híbrido con directorio: el cliente nuevo a su propia base de datos en la
UE, los 2.999 restantes en la tabla compartida con Row-Level Security.

**Por qué el cliente nuevo no puede quedarse en compartido.** Tres razones independientes, y
cualquiera bastaría: representa el 40 % del volumen, así que sería el vecino ruidoso definitivo;
exige residencia de datos en la UE, lo que afecta a backups, réplicas y logs, no solo a la base; y
pide un informe de aislamiento, que con tabla compartida es una conversación incómoda y con base
dedicada es un documento.

**El diseño.**

```text
Directorio → tenantId → destino. Replicado y cacheado.
Destino A  → clúster compartido, región actual, tabla común + RLS + índices por tenant_id
Destino B  → base de datos dedicada, región UE, backups y claves propias

Enrutamiento resuelto en un único punto al inicio de la petición.
```

**Lo que hay que resolver además de la base de datos.** La residencia afecta a todo el rastro del
dato: los logs de aplicación no pueden contener datos personales que salgan de la UE, las métricas
tampoco, y los backups deben quedarse en la región. Es la parte que se olvida y la que un auditor
mira primero.

**El procedimiento de migración**, porque el cliente ya está o va a estar en compartido: doble
escritura temporal a ambos destinos, copia del histórico, verificación por conteos y muestreo,
cambio en el directorio, periodo de observación, y limpieza de los datos del destino viejo. Con
vuelta atrás disponible hasta el último paso.

**Cómo protejo a los 2.999.** El aislamiento del grande los protege del vecino ruidoso por
construcción. Y añado lo que faltaba de todos modos: medición de consumo por tenant para detectar al
siguiente antes de que moleste, límites de tasa por tenant, y `tenant_id` como primera columna de los
índices para que las consultas de un cliente pequeño no hagan trabajo proporcional a la tabla
entera.

**Lo que declaro como coste.** Dos destinos significan dos migraciones de esquema, compatibles hacia
atrás con expand/contract porque no se aplicarán a la vez; métricas de plataforma que pasan de ser
una consulta a una agregación desde ambos; y un directorio que es ahora un componente crítico y
necesita replicación y caché.

---

**Anterior:** [`09` — Simulación de entrevista](09-simulacion-de-entrevista.md) ·
**Índice del bloque:** [README](README.md)
