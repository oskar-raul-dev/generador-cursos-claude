# 08 — Respuestas

> Solucionario del bloque: el enunciado copiado literalmente de su capítulo y la respuesta en tres
> capas.
>
> **Cómo se usa.** Responde primero en voz alta, con el cronómetro. La capa ⏱️ es lo que dices en
> los primeros treinta segundos; la 🗣️ es lo que añades cuando te dicen "cuéntame más"; la 🔬 es el
> matiz que casi nadie trae, y es donde vive la distinción entre **lo que manda el estándar, lo que
> hace tu motor y lo que es pura convención**.
>
> **Vigencia:** 22 de septiembre de 2026.

---

## Salto rápido

- [Capítulo 01 — ACID con precisión](#capítulo-01--acid-con-precisión)
- [Capítulo 02 — Aislamiento y sus fenómenos](#capítulo-02--aislamiento-y-sus-fenómenos)
- [Capítulo 03 — MVCC frente a bloqueo](#capítulo-03--mvcc-frente-a-bloqueo)
- [Capítulo 04 — Bloqueos e interbloqueos](#capítulo-04--bloqueos-e-interbloqueos)
- [Capítulo 05 — Optimista, pesimista y transacciones
  largas](#capítulo-05--optimista-pesimista-y-transacciones-largas)
- [Capítulo 06 — WAL, durabilidad y `fsync`](#capítulo-06--wal-durabilidad-y-fsync)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — ACID con precisión

Las 18 preguntas de [`01`](01-acid-con-precision.md).

**01 → 1.** ¿Qué garantiza cada una de las cuatro letras de ACID, en una frase cada una? 🟢

⏱️ **30 segundos** — Atomicidad: todas las escrituras de la transacción o ninguna. Consistencia: la
base no queda violando lo que está declarado en el esquema. Aislamiento: qué ves de lo que hacen los
demás mientras tanto. Durabilidad: lo confirmado sobrevive a un corte.

🗣️ **2 minutos** — Las cuatro no son del mismo tipo, y eso es lo que conviene decir. La A y la D son
garantías que el motor da solo; la I es una palanca con cuatro posiciones que tú eliges; y la C no
es del motor casi nada: hace cumplir las restricciones declaradas —`NOT NULL`, `UNIQUE`, `CHECK`,
`FOREIGN KEY`— y no sabe nada de los invariantes que viven en tu código.

🔬 **El detalle** — **Estándar** para los cuatro nombres; **motor** para casi todo lo que importa: el
nivel de aislamiento por defecto, si el DDL se deshace, qué pasa tras un error de sentencia y si el
`COMMIT` espera al disco. La prueba de que las cuatro letras no bastan es la sesión de actualización
perdida de `01/01` §2: dos transacciones atómicas, aisladas al nivel por defecto y duraderas, y el
total quedó mal.

---

**01 → 2.** ¿Qué pasa si ejecutas un `UPDATE` sin haber escrito `BEGIN`? 🟢

⏱️ **30 segundos** — Que el motor abre una transacción, ejecuta el `UPDATE`, confirma y la cierra.
Sigue habiendo transacción: lo que no hay es control sobre ella.

🗣️ **2 minutos** — Es el modo autoconfirmado, y es el defecto en los tres motores del corpus. La
consecuencia práctica es que en cuanto la sentencia termina ya no hay nada que deshacer: si el
siguiente paso de tu operación falla, el anterior está confirmado. Por eso una operación de negocio
con dos escrituras se envuelve siempre en `BEGIN … COMMIT`.

🔬 **El detalle** — **Motor.** En `psql` el estado se ve en el prompt: `tienda=#` fuera de
transacción y `tienda=*#` dentro; en MySQL, con `SELECT @@autocommit`, que vale `1`. El precio del
autoconfirmado es **un `fsync` por sentencia**: cien mil `INSERT` sueltos son cien mil esperas al
disco, y los mismos cien mil dentro de una transacción, una.

---

**01 → 3.** ¿Qué es un punto de guardado y qué sentencia vuelve a él? 🟢

⏱️ **30 segundos** — Una marca con nombre dentro de la transacción, `SAVEPOINT nombre`, a la que se
vuelve con `ROLLBACK TO SAVEPOINT nombre` sin perder el resto del trabajo.

🗣️ **2 minutos** — Deshace lo hecho desde la marca y deja viva la transacción, así que el `COMMIT`
final confirma todo lo anterior al punto. En PostgreSQL tiene un uso extra y decisivo: es la única
forma de sobrevivir a un error de sentencia, porque sin punto de guardado la transacción queda
abortada y toda sentencia posterior falla hasta el `ROLLBACK`. `RELEASE SAVEPOINT` suelta la marca
sin deshacer nada.

🔬 **El detalle** — **Estándar** para `SAVEPOINT`, `ROLLBACK TO` y `RELEASE`, y están en los tres
motores. **Motor** para el precio: en PostgreSQL cada punto de guardado abre una subtransacción con
su propio identificador y la sesión solo cachea **64**; a partir de ahí, las demás sesiones pagan
contención buscando en disco si una fila es visible.

---

**01 → 4.** ¿Cuál es el alcance de una transacción: la petición, el método o la conexión? 🟢

⏱️ **30 segundos** — La conexión. Todo lo demás es una convención de tu marco de trabajo montada
encima.

🗣️ **2 minutos** — Una transacción vive en una sesión del motor, de principio a fin. Que coincida
con una petición HTTP o con un método anotado depende de que alguien haya atado la conexión a ese
ámbito, y es justo donde aparecen los fallos: un hilo que toma otra conexión no está en tu
transacción, y una conexión devuelta al pool sin `COMMIT` ni `ROLLBACK` se lleva la transacción
abierta a la petición siguiente.

🔬 **El detalle** — **Motor.** En PostgreSQL esas conexiones se ven en `pg_stat_activity` con `state
= 'idle in transaction'`, y son el sospechoso número uno cuando el espacio crece sin parar: mientras
esa transacción siga abierta, su instantánea impide limpiar versiones muertas **de toda la base**.

---

**01 → 5.** Nombra el parámetro que decide si el `COMMIT` espera al disco en PostgreSQL y en MySQL.
🟢

⏱️ **30 segundos** — `synchronous_commit` en PostgreSQL e `innodb_flush_log_at_trx_commit` en MySQL.
Los dos vienen en su posición segura.

🗣️ **2 minutos** — En PostgreSQL el valor por defecto es `on`: el `COMMIT` no vuelve hasta que el
registro WAL está en disco. Con `off` sigue siendo consistente —no se corrompe nada— pero se abre
una ventana de unos cientos de milisegundos de transacciones confirmadas que se pueden perder. En
MySQL el `1` es el equivalente; con `2` se pierde lo del último segundo solo si cae el sistema
operativo, y con `0`, también si cae solo el proceso de MySQL.

🔬 **El detalle** — **Motor**, los dos; el estándar no dice nada sobre `fsync`. En SQLite la palanca
es `PRAGMA synchronous`, con `FULL` por defecto, también en modo WAL con el binario del corpus —lo
dice [`06`](06-wal-durabilidad-y-fsync.md) §8—. Y el matiz que sube la nota: las tres relajaciones
pierden **transacciones enteras y recientes**, no dejan la base a medias, que es lo que las hace
aceptables para una tabla de eventos y no para `pagos`.

---

**01 → 6.** Distingue lo que garantiza la A de lo que garantiza la I, con un caso en que la A se
cumple y el dato acaba mal. 🟡

⏱️ **30 segundos** — La A garantiza que no quede media escritura tuya; la I, qué ves de lo que hacen
los demás. El caso es la actualización perdida.

🗣️ **2 minutos** — En la sesión de `01/01` §2, dos cajeros leen el total de `PED-00042` —3186.23—,
cada uno le suma su importe y escribe. Las dos transacciones son atómicas: ninguna dejó media fila.
Las dos son duraderas. Y el resultado es 3206.23: se aplicaron 10 y 20, y el total subió 20. El pago
de uno desapareció sin ningún error.

🔬 **El detalle** — **Motor.** Lo que falló no fue la atomicidad sino el aislamiento: con `READ
COMMITTED`, que es el defecto de PostgreSQL, la segunda transacción esperó a la primera y después
escribió encima con un valor que ya estaba viejo. La corrección no es subir de nivel: es dejar la
aritmética al motor —`SET total = total + 10`— o leer con `SELECT … FOR UPDATE`.

---

**01 → 7.** ¿Qué significa exactamente la C de ACID, y qué parte de ella no pone el motor? 🟡

⏱️ **30 segundos** — Que la transacción lleva la base de un estado válido a otro válido, pero
«válido» significa solo lo que esté declarado en el esquema. Todo lo demás lo pones tú.

🗣️ **2 minutos** — El motor comprueba `NOT NULL`, `UNIQUE`, `CHECK` y `FOREIGN KEY`, y lo hace en
toda escritura venga de donde venga: de tu servicio, de una migración o de alguien con `psql`
abierto. Lo que no comprueba es "el importe reembolsado no puede superar el total del pedido"
mientras esa regla viva en un `if` de tu código. La C no es una garantía que el motor te dé: es la
garantía de que no vas a poder romper lo que declaraste.

🔬 **El detalle** — **Estándar** para las restricciones y para `DEFERRABLE`; **motor** para el
alcance. PostgreSQL difiere foráneas, únicas y de exclusión; **MySQL 9.7.2 no tiene restricciones
diferibles**; SQLite difiere solo las foráneas con `PRAGMA defer_foreign_keys` y además las tiene
apagadas por defecto en cada conexión.

---

**01 → 8.** ¿`BEGIN` es del estándar? Responde por separado para la norma y para los tres motores. 🟡

⏱️ **30 segundos** — No: la norma escribe `START TRANSACTION`. `BEGIN` es una extensión, y la tienen
los tres.

🗣️ **2 minutos** — PostgreSQL acepta las dos formas y son equivalentes. MySQL también acepta las
dos. SQLite usa `BEGIN`, y además tiene variantes que no existen en los otros: `BEGIN IMMEDIATE`
toma el bloqueo de escritura desde el principio en vez de esperar a la primera escritura, que es la
forma de evitar un `SQLITE_BUSY` a mitad de una transacción.

🔬 **El detalle** — **No he verificado la cláusula de ISO/IEC 9075**: la norma es de pago y aquí no
se cita ninguna. Lo comprobable es que los tres motores documentan `BEGIN` como extensión y
`COMMIT`/`ROLLBACK` como estándar. El otro matiz de categoría: el modo autoconfirmado tampoco lo
fija la norma, y sin embargo es el defecto en los tres.

---

**01 → 9.** Tras un error de sentencia dentro de una transacción, ¿puedes seguir? Responde para
PostgreSQL, MySQL y SQLite. 🟡

⏱️ **30 segundos** — En PostgreSQL no: la transacción queda abortada. En MySQL y en SQLite sí: se
deshace solo la sentencia que falló.

🗣️ **2 minutos** — PostgreSQL responde `current transaction is aborted, commands ignored until end
of transaction block` a todo lo que venga después, y el `COMMIT` contesta `ROLLBACK`. La salida es
`ROLLBACK TO SAVEPOINT`, si tuviste la precaución de poner uno. En MySQL la transacción sigue viva y
usable, y en SQLite también salvo en los errores graves que dejan la base inutilizable.

🔬 **El detalle** — **Motor puro**; el estándar lo deja al implementador. La consecuencia cara está
en los lotes: un millón de filas partido en sentencias, con una que falla y un `COMMIT` al final,
confirma **todo lo demás** en MySQL y **nada** en PostgreSQL. El mismo código migrado cambia de
resultado sin cambiar una línea.

---

**01 → 10.** ¿En qué se diferencia deshacer en PostgreSQL de deshacer en InnoDB, y cuál de los dos
puede tardar más que el trabajo que deshace? 🟡

⏱️ **30 segundos** — PostgreSQL solo marca la transacción como abortada; InnoDB aplica el *undo log*
fila por fila, y ese es el que puede tardar más que el trabajo original.

🗣️ **2 minutos** — En PostgreSQL cada `UPDATE` escribió una versión nueva de la fila, así que
deshacer es apuntar que ese identificador de transacción no vale: es casi instantáneo, y lo que
queda por pagar son las versiones muertas, que ocupan páginas hasta que pase el `VACUUM`. InnoDB
guarda la versión antigua aparte y al deshacer la vuelve a escribir, una a una, sin posibilidad de
cancelar a mitad.

🔬 **El detalle** — **Motor.** Es la misma diferencia de diseño que explica por qué el `VACUUM` es un
tema en PostgreSQL y no en MySQL: los dos tienen que guardar la versión vieja, y se diferencian en
dónde. Un `ROLLBACK` de un millón de filas en InnoDB puede dejar la base ocupada minutos después de
que tú hayas perdido la paciencia y cerrado la conexión.

---

**01 → 11.** ¿Qué diferencia hay entre diferir una restricción y apagar la comprobación de claves
foráneas? 🟠

⏱️ **30 segundos** — Diferir mueve la comprobación al `COMMIT` y **la hace igual**; apagarla no
comprueba nada, ni antes ni después.

🗣️ **2 minutos** — Una restricción `DEFERRABLE INITIALLY DEFERRED` tolera estados intermedios
inválidos dentro de la transacción y verifica todo al confirmar: si no cuadra, el `COMMIT` falla y
no entra nada. Apagar `foreign_key_checks` en MySQL, en cambio, deja pasar filas que apuntan a nada,
y cuando vuelves a encenderlo el motor **no revisa lo que entró mientras estaba apagado**. Una es
una herramienta de orden; la otra es una carga a ciegas.

🔬 **El detalle** — **Estándar** para `DEFERRABLE` y `SET CONSTRAINTS`; **motor** para lo que hay de
verdad: PostgreSQL las difiere, MySQL 9.7.2 no tiene restricciones diferibles y SQLite solo las
foráneas. El precio de diferir: el error llega al `COMMIT`, cuando ya no sabes qué sentencia lo
provocó, y la lista de comprobaciones pendientes ocupa memoria de la transacción.

---

**01 → 12.** Un lote inserta cien mil filas con autoconfirmado y va lentísimo. Explica el mecanismo
del coste y di qué cambiarías, con su contrapartida. 🟠

⏱️ **30 segundos** — Cada sentencia es una transacción y cada transacción espera un `fsync`: son
cien mil esperas al disco. Se agrupan en transacciones de mil filas.

🗣️ **2 minutos** — El coste no está en el `INSERT` sino en la confirmación: el motor no puede
responder hasta que el registro está a salvo en disco, y eso es una espera física que no mejora con
más CPU. Envolver el lote en `BEGIN … COMMIT` convierte cien mil esperas en una. Es la razón por la
que la misma carga en SQLite mejora dos órdenes de magnitud sin tocar el SQL.

🔬 **El detalle** — La contrapartida, y es la parte que separa una buena respuesta: **una transacción
enorme se paga por el otro lado**. Mientras está abierta retiene su instantánea y bloquea la
limpieza de versiones muertas de toda la base; si falla al final, se deshace todo; y en InnoDB ese
deshacer puede tardar más que el trabajo. Por eso se agrupa en lotes de miles de filas, no en uno
solo de cien mil.

---

**01 → 13.** Explica por qué intercambiar dos valores de una columna única falla, y da las dos
maneras de resolverlo. 🟠

⏱️ **30 segundos** — Porque la restricción se comprueba al terminar cada sentencia, y a mitad del
intercambio el valor está repetido.

🗣️ **2 minutos** — Poner la línea 1 de `PED-00042` en 2 choca con la línea 2, que todavía existe:
`duplicate key value violates unique constraint "pedido_lineas_pkey"`. La primera solución es el
rodeo clásico, pasar por un valor temporal que no exista —a 99, luego a 1, luego a 2—, y funciona en
cualquier motor. La segunda es declarar la restricción `DEFERRABLE INITIALLY DEFERRED` y dejar que
se compruebe una sola vez en el `COMMIT`, que es la que expresa lo que de verdad quieres decir.

🔬 **El detalle** — **Motor** para lo que puedes elegir: la segunda solución no existe en MySQL
9.7.2, y en PostgreSQL una clave primaria no se puede diferir sin recrearla, así que el ejemplo del
capítulo añade una restricción única aparte. Y un tercer camino que a veces basta: un solo `UPDATE`
con `CASE` que cambia las dos filas en la misma sentencia, porque la comprobación es al final de la
sentencia, no de cada fila.

---

**01 → 14.** Un compañero pone un `SAVEPOINT` en cada vuelta de un bucle de diez mil iteraciones.
Dile qué se paga y dónde se va a notar. 🟠

⏱️ **30 segundos** — Cada punto de guardado es una subtransacción con su propio identificador, y la
sesión solo cachea 64. Pasado eso, la contención la pagan las **demás** sesiones.

🗣️ **2 minutos** — Cuando una sesión supera esos 64 identificadores, cualquier otra que necesite
saber si una fila es visible deja de resolverlo en memoria y tiene que ir a buscarlo a disco. El
síntoma es feo de diagnosticar porque aparece lejos: consultas ajenas que se vuelven lentas sin que
su plan haya cambiado, y una máquina que parece tener un problema de E/S. El patrón lo genera a
menudo un ORM al que se le ha pedido "seguir aunque una fila falle".

🔬 **El detalle** — **Motor**, y es específico de PostgreSQL. La alternativa suele ser sencilla:
validar antes de escribir, o partir el bucle en transacciones pequeñas sin puntos de guardado. Un
puñado de marcas con nombre en un procedimiento que sabe recuperarse es un uso legítimo; una por
iteración, no.

---

**01 → 15.** ¿Por qué una migración con tres `ALTER TABLE` se queda a medias en MySQL y no en
PostgreSQL? Di qué categoría es esa diferencia. 🟠

⏱️ **30 segundos** — Porque en MySQL el DDL confirma implícitamente: cada `ALTER` cierra la
transacción abierta. En PostgreSQL el DDL es transaccional y el `ROLLBACK` lo deshace.

🗣️ **2 minutos** — En MySQL, el primer `ALTER` confirma lo que llevaras y se aplica; si el segundo
falla, no hay nada que deshacer y la base queda con la mitad del cambio. En PostgreSQL los tres
`ALTER` viven dentro de la misma transacción, y si uno falla se revierte todo: la base queda
exactamente como estaba. Es la diferencia entre una migración que se puede reintentar y una que hay
que arreglar a mano.

🔬 **El detalle** — **Motor.** El estándar no exige DDL transaccional. Y en MySQL la lista de lo que
confirma implícitamente es más larga de lo que parece: no es solo el DDL, también `START
TRANSACTION` dentro de una transacción abierta confirma la anterior. SQLite sí deshace el DDL, como
PostgreSQL.

---

**01 → 16.** Escribe la secuencia completa —sentencia a sentencia— de una transacción que intente
una operación que puede fallar, se recupere del fallo y confirme el resto del trabajo. 🔴

⏱️ **30 segundos** — `BEGIN`, la parte segura, `SAVEPOINT`, la parte que puede fallar, y según el
resultado `RELEASE` o `ROLLBACK TO SAVEPOINT`; al final, `COMMIT`.

🗣️ **2 minutos** — La secuencia concreta:

```text
BEGIN;
UPDATE pedidos SET estado = 'ANULADO' WHERE codigo = 'PED-99999';
SAVEPOINT antes_del_pago;
INSERT INTO pagos (pedido_id, metodo, importe, pagado_en) VALUES (…);
-- si falla:
ROLLBACK TO SAVEPOINT antes_del_pago;
-- si va bien:
RELEASE SAVEPOINT antes_del_pago;
COMMIT;
```

Lo importante es que el `UPDATE` anterior al punto de guardado **sobrevive** al `ROLLBACK TO`, y que
sin ese punto, en PostgreSQL, el error habría abortado la transacción entera.

🔬 **El detalle** — **Motor.** En MySQL y SQLite el punto de guardado no es imprescindible para
recuperarse —tras un error la transacción sigue usable—, pero sigue siendo útil para deshacer un
bloque concreto. Y el aviso de precio: si esto se mete en un bucle largo, cada `SAVEPOINT` es una
subtransacción y por encima de 64 empieza a costar contención a las demás sesiones.

---

**01 → 17.** Diagnostica esto: la base crece sin parar y el `VACUUM` no libera espacio, aunque se
borran filas todos los días. Da tres hipótesis en orden de probabilidad y la consulta con la que
confirmarías la primera. 🔴

⏱️ **30 segundos** — Primera: hay una transacción abierta desde hace horas que retiene la
instantánea. Segunda: una réplica o un *slot* de replicación retrasado. Tercera: el autovacuum no
llega a esas tablas.

🗣️ **2 minutos** — Las tres comparten mecanismo: una versión muerta solo se puede limpiar cuando
nadie puede necesitarla. Una conexión en `idle in transaction` —el clásico: el pool devolvió una
conexión sin `COMMIT` ni `ROLLBACK`— congela ese horizonte para **toda la base**, no solo para las
tablas que tocó. Un *slot* de replicación sin consumir hace lo mismo. Y si nada de eso pasa, queda
que el autovacuum no dé abasto o que sus umbrales no se disparen en una tabla enorme.

🔬 **El detalle** — La consulta de la primera hipótesis:

```sql
SELECT pid, state, xact_start, now() - xact_start AS duracion, query
  FROM pg_stat_activity
 WHERE state = 'idle in transaction'
 ORDER BY xact_start;
```

Corrida con una segunda sesión que abre `BEGIN`, lee y se queda quieta, devuelve esto —el `pid` y la
hora cambian en cada corrida; lo que se lee es la fila y su `duracion`—:

```text
  pid  |        state        |          xact_start           |   duracion    |            query
-------+---------------------+-------------------------------+---------------+---------------------------
 89376 | idle in transaction | 2026-09-21 14:30:55.063796+00 | 00:00:04.3137 | SELECT count(*) FROM pe...
(1 fila)
```

**Motor**, entero: esto es PostgreSQL. En InnoDB el equivalente es el crecimiento del *undo log* por
una transacción larga, y se mira con `SHOW ENGINE INNODB STATUS`. El arreglo definitivo no es
`VACUUM FULL` —que reescribe la tabla y bloquea—, sino cerrar la transacción abierta y poner un
`idle_in_transaction_session_timeout`.

---

**01 → 18.** Defiende, ante alguien que propone `synchronous_commit = off` para toda la base, qué
tablas aceptarías y cuáles no, y di exactamente qué se pierde en cada caso. 🔴

⏱️ **30 segundos** — Lo aceptaría para `eventos_pedido` y no para `pagos`: lo que se pierde son
transacciones confirmadas de los últimos cientos de milisegundos, y en un pago eso es dinero.

🗣️ **2 minutos** — El argumento tiene que empezar por lo que **no** se pierde: apagarlo no corrompe
la base ni deja transacciones a medias; el motor sigue escribiendo el WAL, solo que el `COMMIT` no
espera a que llegue al disco. Lo que se pierde es una ventana de transacciones enteras y recientes
si se va la luz. Para una tabla de eventos —4 100 000 filas que se reescriben desde el origen si
hace falta— eso es aceptable y el rendimiento de escritura sube mucho. Para `pagos` no: un pago
confirmado al cliente que desaparece no se recupera de ningún sitio.

🔬 **El detalle** — **Motor**, y con un matiz que casi nadie trae: `synchronous_commit` **se puede
fijar por transacción**, no solo en el servidor. Se pone `SET LOCAL synchronous_commit = off` en la
transacción que escribe eventos y se deja `on` para todo lo demás, que es la respuesta correcta a la
propuesta: no es una decisión de la base, es una decisión por tipo de escritura. Y conviene recordar
que la D no implica réplica: eso se pide aparte, con `synchronous_standby_names`.

---

## Capítulo 02 — Aislamiento y sus fenómenos

Las 22 preguntas de [`02`](02-aislamiento-y-sus-fenomenos.md).

**02 → 1.** Nombra los cuatro niveles de aislamiento del estándar, de menos a más estricto. 🟢

⏱️ **30 segundos** — `READ UNCOMMITTED`, `READ COMMITTED`, `REPEATABLE READ` y `SERIALIZABLE`.

🗣️ **2 minutos** — El estándar los define por lo que **prohíbe** cada uno, no por cómo se consigue:
`READ UNCOMMITTED` permite las tres anomalías, `READ COMMITTED` prohíbe la lectura sucia,
`REPEATABLE READ` prohíbe además la no repetible, y `SERIALIZABLE` prohíbe también los fantasmas.
Que un motor prohíba más de lo exigido en un nivel es perfectamente legal, y es justo lo que hacen
PostgreSQL e InnoDB.

🔬 **El detalle** — **Estándar** para los cuatro nombres y para esa tabla. Lo que la norma **no**
fija es cuál es el defecto ni con qué mecanismo se cumple, y ahí es donde los motores se separan:
dos implementaciones opuestas —instantánea contra bloqueo— pueden cumplir la misma fila y
comportarse muy distinto bajo carga.

---

**02 → 2.** ¿Qué es una lectura sucia? 🟢

⏱️ **30 segundos** — Leer una fila que otra transacción escribió y todavía no confirmó. Si esa otra
deshace, trabajaste con un dato que nunca existió.

🗣️ **2 minutos** — Es la anomalía más grave y la única que casi nadie sufre, porque solo aparece en
`READ UNCOMMITTED` y ningún motor lo pone por defecto. Lo interesante es que sea la más fácil de
evitar: basta con no enseñar versiones no confirmadas, que es lo que hacen todos los motores basados
en versiones.

🔬 **El detalle** — **Motor.** En PostgreSQL **no se puede reproducir**: pedir `READ UNCOMMITTED` se
acepta, el nombre se guarda y el comportamiento es el de `READ COMMITTED`. En MySQL/InnoDB sí es
real. En SQLite solo existe con caché compartida, que no es el caso del corpus.

---

**02 → 3.** ¿Cuál es el nivel por defecto de PostgreSQL 18.6 y cuál el de MySQL 9.7.2? 🟢

⏱️ **30 segundos** — `READ COMMITTED` en PostgreSQL y `REPEATABLE READ` en MySQL.

🗣️ **2 minutos** — Es la diferencia que más silenciosamente rompe una migración: el mismo código,
sin tocar una línea, pasa a tolerar lecturas no repetibles al moverse de MySQL a PostgreSQL. En
sentido contrario aparece el problema opuesto, transacciones que empiezan a chocar porque InnoDB
mantiene la instantánea durante toda la transacción.

🔬 **El detalle** — **Motor**, y esta es la pregunta de categoría más rentable del bloque: **el
estándar define los cuatro niveles y no dice cuál es el defecto**. Se comprueba con `SHOW
transaction_isolation` en PostgreSQL y `SELECT @@transaction_isolation` en MySQL. SQLite no tiene
variable: con un solo escritor a la vez, el aislamiento entre conexiones es serializable de facto.

---

**02 → 4.** ¿Qué comando te dice en qué nivel estás, en cada uno de los dos motores? 🟢

⏱️ **30 segundos** — `SHOW transaction_isolation` en PostgreSQL y `SELECT @@transaction_isolation`
en MySQL.

🗣️ **2 minutos** — Los dos devuelven el nivel **de la sesión actual**, que puede no ser el del
servidor: `SET TRANSACTION ISOLATION LEVEL …` dentro de una transacción lo cambia solo para ella, y
`SET SESSION …` para la conexión. Conviene mirarlo antes de discutir un comportamiento raro, porque
muchos pools y ORMs lo fijan por su cuenta al abrir la conexión.

🔬 **El detalle** — **Motor.** En PostgreSQL, además, `SHOW default_transaction_isolation` dice con
qué nivel arrancan las transacciones nuevas, que es lo que de verdad toca mirar cuando sospechas de
la configuración y no de una sentencia suelta.

---

**02 → 5.** ¿Qué es el *write skew*, en una frase? 🟢

⏱️ **30 segundos** — Dos transacciones leen lo mismo, cada una decide algo válido por separado,
escriben filas distintas y entre las dos rompen una regla que ninguna violó sola.

🗣️ **2 minutos** — El ejemplo del capítulo: la regla dice que un pedido anulado no puede tener más
de un pago de compensación; dos operadores comprueban a la vez que `PED-99999` no tiene ninguno,
cada uno inserta el suyo, y quedan dos. Ninguna transacción escribió sobre lo que escribió la otra,
así que no hay conflicto de actualización que detectar.

🔬 **El detalle** — **No está en el estándar**: lo nombra el artículo de Berenson y otros, de 1995,
que amplió el catálogo porque los tres fenómenos de la norma no bastaban para clasificar los motores
reales. Es la anomalía que sobrevive al `REPEATABLE READ` de PostgreSQL y la razón entera de que
exista `SERIALIZABLE`.

---

**02 → 6.** ¿Qué `SQLSTATE` devuelve PostgreSQL cuando aborta una transacción por conflicto de
serialización? 🟢

⏱️ **30 segundos** — `40001`, *serialization_failure*. Y significa "vuelve a intentarlo", no "algo
está roto".

🗣️ **2 minutos** — Aparece en dos variantes que conviene distinguir: `could not serialize access due
to concurrent update`, cuando dos transacciones en `REPEATABLE READ` escriben la misma fila; y
`could not serialize access due to read/write dependencies among transactions`, en `SERIALIZABLE`,
cuando el detector de dependencias ve que el entrelazado no equivale a ningún orden en serie. La
segunda trae un `HINT` que lo dice literalmente: la transacción puede tener éxito si se reintenta.

🔬 **El detalle** — **Motor.** El código `40001` sí es del estándar como clase de error, pero **que
una transacción se aborte sola por conflicto no lo exige la norma**: InnoDB, en el mismo caso,
espera y al vencer `innodb_lock_wait_timeout` —50 segundos por defecto— devuelve `ERROR 1205`. Un
reintento rápido en un motor y una petición colgada en el otro.

---

**02 → 7.** Distingue una lectura no repetible de una lectura fantasma, y di por qué bloquear las
filas leídas evita una y no la otra. 🟡

⏱️ **30 segundos** — La no repetible es sobre una fila que ya habías leído y cambió; la fantasma es
sobre filas que no existían en tu resultado y aparecieron.

🗣️ **2 minutos** — Si tu mecanismo es bloquear lo que lees, evitas la primera: nadie puede modificar
una fila que tienes bloqueada. Pero no puedes bloquear lo que todavía no está, así que un `INSERT`
dentro de tu rango entra igual y tu segunda consulta devuelve una fila más. Por eso el fantasma
necesita otra cosa: o una instantánea estable de toda la transacción, o bloquear **el rango**,
huecos incluidos.

🔬 **El detalle** — **Estándar** para la distinción; **motor** para la solución. InnoDB bloquea el
rango con *next-key locks* —un invento suyo, no de la norma— y PostgreSQL usa la instantánea. El
efecto secundario del camino de InnoDB es que un `SELECT … FOR UPDATE` por rango hace esperar a
sesiones que insertan filas que no son tuyas.

---

**02 → 8.** ¿`REPEATABLE READ` evita los fantasmas? Da las tres respuestas: estándar, PostgreSQL e
InnoDB. 🟡

⏱️ **30 segundos** — El estándar los permite en ese nivel; PostgreSQL los evita porque su
`REPEATABLE READ` es *snapshot isolation*; InnoDB también, con instantánea y *next-key locks*.

🗣️ **2 minutos** — Son tres respuestas y hay que darlas separadas, porque la frase recitada es falsa
para la norma y cierta por motivos distintos para los dos motores. En PostgreSQL la transacción
entera ve una foto fija tomada al principio, así que ninguna fila nueva puede aparecer. En InnoDB
las lecturas consistentes ven su instantánea y las lecturas con bloqueo toman además el hueco entre
claves, que es lo que impide el `INSERT` de otra sesión.

🔬 **El detalle** — Lo que **sí** sobrevive al `REPEATABLE READ` de PostgreSQL es el *write skew*, y
esa es la respuesta completa: evita los tres fenómenos de la norma y no evita la anomalía que la
norma no nombra. En InnoDB, además, el `REPEATABLE READ` no detecta la actualización perdida en un
leer-decidir-escribir repartido entre aplicación y base.

---

**02 → 9.** ¿Está la actualización perdida entre los fenómenos del estándar? Di de dónde viene el
nombre. 🟡

⏱️ **30 segundos** — No. Los fenómenos de la norma son tres —sucia, no repetible y fantasma— y la
actualización perdida no está entre ellos. El nombre viene del artículo de Berenson y otros, de
1995.

🗣️ **2 minutos** — Ese artículo, «A Critique of ANSI SQL Isolation Levels», mostró que la tabla de
la norma no servía para clasificar los motores reales, y añadió las anomalías que faltaban: la
actualización perdida y el *write skew*, entre otras. Es la razón por la que el vocabulario de la
industria es más amplio que el del estándar, y por la que conviene decir de dónde viene cada
término.

🔬 **El detalle** — **Motor** para el tratamiento: PostgreSQL la detecta a partir de `REPEATABLE
READ` y aborta con `40001`; InnoDB en ese mismo nivel espera y aplica su `UPDATE` sobre la versión
más reciente, sin error, así que una escritura ciega sale bien y un leer-decidir-escribir se pierde
igual. En `READ COMMITTED` ocurre en los dos, y está medida en `01/01` §2.

---

**02 → 10.** Diferencia el `SERIALIZABLE` de PostgreSQL del de MySQL: ¿qué hace cada uno cuando dos
transacciones chocan? 🟡

⏱️ **30 segundos** — PostgreSQL detecta el conflicto y **aborta** una con `40001`; MySQL **bloquea**
desde el principio, convirtiendo cada `SELECT` en una lectura con bloqueo compartido.

🗣️ **2 minutos** — Son dos filosofías opuestas con el mismo nombre. PostgreSQL usa *serializable
snapshot isolation*: deja correr a las dos, sigue las dependencias de lectura y escritura entre
ellas, y si el entrelazado no equivale a ningún orden en serie cancela a una en el `COMMIT`. InnoDB
lo consigue por la vía clásica: si nadie puede leer sin bloquear, no hay entrelazados peligrosos. Lo
primero produce abortos y reintentos; lo segundo, esperas e interbloqueos.

🔬 **El detalle** — **Motor**, los dos; el estándar solo exige el resultado, no el método. La
consecuencia práctica para tu código: con PostgreSQL necesitas un bucle de reintento para el `40001`
y con MySQL necesitas tiempos de espera y una estrategia para los interbloqueos. Y en los dos, que
la transacción sea repetible sin efectos externos.

---

**02 → 11.** Explica por qué en PostgreSQL pedir `READ UNCOMMITTED` no cambia nada, y qué categoría
es esa afirmación. 🟡

⏱️ **30 segundos** — Porque PostgreSQL lo acepta y lo trata como `READ COMMITTED`: su control de
versiones no tiene forma de enseñar una fila no confirmada. Es afirmación de **motor**.

🗣️ **2 minutos** — El estándar exige admitir los cuatro niveles, y PostgreSQL los admite: la
sentencia funciona y `SHOW transaction_isolation` devuelve `read uncommitted`. Lo que no cambia es
el comportamiento. Cumplir por arriba —prohibir más anomalías de las exigidas— es legal, y es lo que
hace. La consecuencia práctica es que el "truco" de bajar de nivel para acelerar informes no acelera
absolutamente nada en este motor.

🔬 **El detalle** — En MySQL sí acelera un poco, porque InnoDB se ahorra construir la vista de
lectura, y el precio es tomar decisiones con datos que pueden deshacerse. La distinción de categoría
es justo la aportación del corpus: *"`READ UNCOMMITTED` permite lecturas sucias"* es **estándar**,
*"en PostgreSQL no"* es **motor**, y *"bajar de nivel acelera"* es **convención**.

---

**02 → 12.** ¿Qué es un *gap lock*, qué motor lo tiene, qué problema resuelve y a quién se lo cobra?
🟠

⏱️ **30 segundos** — Un bloqueo sobre el **hueco** entre dos claves de un índice. Lo tiene InnoDB,
resuelve los fantasmas en las lecturas con bloqueo, y se lo cobra a quien intente insertar en ese
hueco.

🗣️ **2 minutos** — Como no se puede bloquear una fila que no existe, InnoDB bloquea el espacio donde
podría aparecer: la combinación de bloqueo de fila y de hueco es el *next-key lock*. Con él, un
`SELECT … FOR UPDATE` sobre un rango impide que otra sesión inserte dentro, y por eso su `REPEATABLE
READ` no tiene fantasmas ni siquiera en lecturas con bloqueo. La factura la pagan sesiones que no
tocan ninguna fila tuya: solo querían insertar en el rango.

🔬 **El detalle** — **Motor puro**: no está en el estándar y PostgreSQL no tiene nada equivalente
—consigue lo mismo con la instantánea, y en `SERIALIZABLE` con seguimiento de dependencias—. Es el
origen de la mitad de los interbloqueos sorprendentes de MySQL, y el motivo de que un índice mal
elegido empeore la concurrencia: cuanto menos selectivo es el índice por el que se busca, más huecos
se bloquean.

---

**02 → 13.** En `REPEATABLE READ`, dos sesiones actualizan la misma fila. Di qué hace PostgreSQL y
qué hace InnoDB, y cuál de los dos puede perder una actualización. 🟠

⏱️ **30 segundos** — PostgreSQL aborta la segunda con `could not serialize access due to concurrent
update`. InnoDB la deja esperar y después aplica su cambio sobre la versión nueva. El que puede
perder una actualización es InnoDB.

🗣️ **2 minutos** — En PostgreSQL gana quien confirma primero: la segunda transacción descubre que la
fila cambió desde su instantánea y se cancela con `SQLSTATE 40001`, de modo que tu código tiene que
reintentarla entera. En InnoDB la segunda espera al `COMMIT` de la primera y entonces reevalúa: para
un `UPDATE` ciego del tipo `SET total = total + 10` el resultado es correcto, pero si el valor nuevo
se calculó en la aplicación con lo que leyó antes, ese cálculo estaba basado en un dato viejo y la
actualización de la primera desaparece.

🔬 **El detalle** — **Motor.** Ninguno de los dos incumple el estándar, porque la norma no nombra la
actualización perdida. La defensa que funciona en los dos y no cuesta nada es dejar la aritmética al
motor; la que funciona cuando hay que decidir en la aplicación es `SELECT … FOR UPDATE`, que
serializa a los dos escritores sobre esa fila.

---

**02 → 14.** Tienes un informe que lee cinco tablas y tiene que cuadrar consigo mismo. Elige nivel,
justifícalo y di qué te obliga a escribir esa elección. 🟠

⏱️ **30 segundos** — `REPEATABLE READ`: una instantánea para toda la transacción, así que las cinco
lecturas ven la misma foto. Y obliga a escribir un bucle de reintento para el `40001`.

🗣️ **2 minutos** — Con `READ COMMITTED` cada sentencia toma su propia instantánea, así que el total
de la primera consulta y el desglose de la tercera pueden no cuadrar aunque las dos sean correctas
por separado. Subir a `REPEATABLE READ` lo resuelve de raíz y es barato para un informe, porque solo
lee. `SERIALIZABLE` sería innecesario: no hay escrituras que puedan producir *write skew*.

🔬 **El detalle** — Lo que se paga: la instantánea envejece mientras dure el informe, y eso retiene
versiones muertas de toda la base —en un informe de veinte minutos eso ya no es gratis—. Y el matiz
que sube la nota: en PostgreSQL existe además `SET TRANSACTION SNAPSHOT`, que permite que dos
sesiones compartan exactamente la misma instantánea, que es como se hace un volcado consistente en
paralelo.

---

**02 → 15.** ¿Por qué subir el nivel de aislamiento no es gratis? Nombra las dos monedas y di cuál
se paga con cada mecanismo. 🟠

⏱️ **30 segundos** — Se paga en concurrencia, en una de dos monedas: **espera**, si el mecanismo es
bloqueo, o **abortos y reintentos**, si es instantánea.

🗣️ **2 minutos** — Un motor que aísla bloqueando hace que las transacciones se turnen: nadie pierde
trabajo, pero todos esperan, y la latencia sube con la contención. Un motor que aísla con
instantáneas deja correr a todos y cancela al que resulta incompatible: nadie espera, pero parte del
trabajo se tira y hay que repetirlo. En los dos casos el rendimiento agregado baja, y por eso ningún
motor pone `SERIALIZABLE` por defecto.

🔬 **El detalle** — **Motor** para el reparto: InnoDB paga sobre todo en espera —cincuenta segundos
de `innodb_lock_wait_timeout`— y PostgreSQL en abortos `40001`. Hay una tercera moneda menos obvia
en PostgreSQL: el `SERIALIZABLE` mantiene estructuras de seguimiento de lecturas, y cuando no caben
en memoria empieza a cancelar transacciones que ni siquiera están en conflicto real.

---

**02 → 16.** Un compañero propone `SERIALIZABLE` para toda la aplicación. Dale dos argumentos en
contra y una alternativa concreta para el caso que de verdad lo necesita. 🟠

⏱️ **30 segundos** — Primero: todo el código pasa a necesitar reintentos, incluido el que hoy no los
tiene. Segundo: el rendimiento agregado baja para el 95 % de las transacciones que no lo necesitan.
La alternativa es subir de nivel **solo** en la transacción que comprueba la regla.

🗣️ **2 minutos** — El nivel se elige por transacción, no por aplicación: `SET TRANSACTION ISOLATION
LEVEL SERIALIZABLE` dentro del `BEGIN` que lo necesita, y el resto sigue en el defecto. Y para el
caso concreto hay una alternativa aún más barata: **materializar el conflicto**, haciendo que las
dos transacciones escriban la misma fila —un contador, una fila de reserva, un `SELECT … FOR UPDATE`
sobre el pedido padre—. Así el *write skew* se convierte en un conflicto de actualización, que
`REPEATABLE READ` sí detecta.

🔬 **El detalle** — **Motor.** En PostgreSQL hay un requisito que casi nadie menciona: para que SSI
funcione, **todas** las transacciones implicadas tienen que correr en `SERIALIZABLE`. Si una de las
dos va en `READ COMMITTED`, no hay garantía que valga, y esa es la razón por la que "lo subimos solo
donde hace falta" hay que hacerlo con cuidado: es en el conjunto de transacciones que se cruzan, no
en una sola.

---

**02 → 17.** Explica por qué no debe haber una llamada a una pasarela de pago dentro de una
transacción que puede reintentarse. 🟠

⏱️ **30 segundos** — Porque el reintento repite la transacción entera, y la llamada externa se
ejecutaría otra vez: se cobra dos veces. La base puede deshacerse; la pasarela, no.

🗣️ **2 minutos** — Un `40001` cancela la transacción y el bucle la vuelve a lanzar desde el `BEGIN`.
Todo lo que sea escritura en la base se repite sin daño, porque la primera vez no dejó rastro. Lo
que salió de la base —un cobro, un correo, un mensaje en una cola— ya ocurrió. Hay una segunda
razón, igual de fuerte: la llamada externa tarda cientos de milisegundos y mantiene la transacción
abierta todo ese tiempo, reteniendo bloqueos y la instantánea.

🔬 **El detalle** — El patrón correcto es sacar el efecto externo de la transacción y hacerlo
idempotente con una clave: se escribe la intención en la base, se confirma, y un proceso aparte
llama a la pasarela con un identificador que permite repetir la llamada sin cobrar dos veces. **Esto
no lo resuelve ninguna letra de ACID**: la atomicidad es por transacción y por base, y dos sistemas
distintos no la comparten.

---

**02 → 18.** Un servicio migra de MySQL a PostgreSQL sin tocar código y empiezan a aparecer datos
incoherentes en un informe. Da la hipótesis más probable, la consulta que la confirma y la
corrección. 🔴

⏱️ **30 segundos** — Que el nivel por defecto cambió: de `REPEATABLE READ` en MySQL a `READ
COMMITTED` en PostgreSQL. El informe lee varias veces y ahora cada sentencia ve una foto distinta.

🗣️ **2 minutos** — El código no cambió, pero el contrato sí. En MySQL el informe tenía una
instantánea de transacción sin haberla pedido; en PostgreSQL cada sentencia toma la suya, así que
aparecen lecturas no repetibles y fantasmas entre las consultas del mismo informe. El síntoma
característico es exactamente el del capítulo: dos cifras que deberían cuadrar y difieren en una o
dos unidades, sin ningún error en los registros.

🔬 **El detalle** — La confirmación, y la corrección:

```sql
SHOW default_transaction_isolation;   -- lo que se aplica a las transacciones nuevas
SHOW transaction_isolation;           -- lo que está usando esta sesión
```

```text
 default_transaction_isolation
-------------------------------
 read committed
(1 fila)

 transaction_isolation
-----------------------
 read committed
(1 fila)
```

La corrección **no** es cambiar el defecto del servidor a `REPEATABLE READ`, que traslada el
problema a todo lo demás y obliga a reintentos en código que no los tiene: es poner `SET TRANSACTION
ISOLATION LEVEL REPEATABLE READ` en la transacción del informe. **Motor**, entero: el estándar no
fija el defecto de nadie.

---

**02 → 19.** Escribe el pseudocódigo del bucle de reintento para `SQLSTATE 40001`, con sus tres
condiciones. 🔴

⏱️ **30 segundos** — Repetir la transacción entera desde el `BEGIN`, solo para el `40001`, con
retardo creciente y un número máximo de intentos.

🗣️ **2 minutos** — El esqueleto:

```text
para intento en 1..4:
    abrir transacción con el nivel que toque
    intentar:
        hacer todo el trabajo            -- sin efectos externos dentro
        confirmar; salir del bucle
    capturar error:
        si SQLSTATE != '40001': deshacer y propagar     -- no todo error se reintenta
        deshacer
        esperar retardo_creciente(intento) + aleatorio  -- evita que todos vuelvan a la vez
si se agotaron los intentos: propagar el error
```

🔬 **El detalle** — Las tres condiciones, dichas por su nombre: **se reintenta la transacción
completa**, porque el estado que leíste ya no vale; **solo el `40001`**, porque un `23505` de clave
duplicada no se arregla repitiendo; y **el trabajo tiene que ser repetible**, sin correos ni cobros
dentro. El aleatorio del retardo no es cosmético: sin él, todas las transacciones canceladas vuelven
a chocar en el mismo instante.

---

**02 → 20.** Diseña la sesión completa de dos terminales —sentencia a sentencia, y dejando los datos
como estaban— que demuestra el *write skew* sobre la regla "un pedido anulado no puede tener más de
un pago". 🔴

⏱️ **30 segundos** — Las dos en `REPEATABLE READ`: las dos cuentan los pagos de `PED-99999` y ven
cero, las dos insertan el suyo, las dos confirman, y quedan dos pagos. Después se borran los dos.

🗣️ **2 minutos** — La secuencia, en orden temporal: A `BEGIN` y `SELECT count(*) FROM pagos WHERE
pedido_id = (SELECT id FROM pedidos WHERE codigo='PED-99999')` → 0; B lo mismo → 0; A inserta su
pago; B inserta el suyo; A `COMMIT`; B `COMMIT`. Ninguna escribió sobre la fila que leyó la otra,
así que no hay conflicto de actualización y `REPEATABLE READ` no cancela nada. La limpieza es un
`DELETE FROM pagos` por ese `pedido_id`, y hay que decir que la secuencia de `id` de `pagos` no
vuelve atrás.

🔬 **El detalle** — Repetida en `SERIALIZABLE`, el segundo `COMMIT` falla con `could not serialize
access due to read/write dependencies among transactions` y su `HINT` de reintentar. **Motor**: ni
la anomalía ni el mecanismo que la detecta están en el estándar. Y el contraste: en MySQL la misma
secuencia en `SERIALIZABLE` no aborta, bloquea, porque allí el nivel se implementa convirtiendo los
`SELECT` en lecturas con bloqueo compartido.

---

**02 → 21.** La regla es "la suma de los pagos de un pedido no puede superar su total". Da dos
formas de hacerla cumplir con el nivel por defecto y di qué cuesta cada una. 🔴

⏱️ **30 segundos** — Una: bloquear el pedido padre con `SELECT … FOR UPDATE` antes de comprobar y
escribir. Dos: mantener la suma en una columna del pedido y comprobarla con un `CHECK`, actualizando
las dos cosas en la misma sentencia.

🗣️ **2 minutos** — La primera materializa el conflicto: si las dos transacciones bloquean la misma
fila de `pedidos` antes de mirar `pagos`, dejan de ser concurrentes para este efecto y el *write
skew* desaparece. Cuesta serializar a todos los que pagan ese pedido, que en la práctica no es nada
porque son pocos. La segunda convierte una regla sobre un conjunto en una restricción sobre una
fila, que es lo que el motor sí sabe hacer cumplir: `pagado_acumulado <= total` como `CHECK`, y cada
`INSERT` en `pagos` actualiza esa columna en la misma transacción. Cuesta desnormalización y un
punto de contención en el pedido.

🔬 **El detalle** — La tercera vía, para completar: subir esa transacción concreta a `SERIALIZABLE` y
reintentar el `40001`. **Motor** para lo que se puede elegir: en MySQL 9.7.2 no hay `CHECK` que
pueda mirar otra tabla —ninguno de los tres lo permite— y tampoco restricciones diferibles, así que
el camino del bloqueo explícito es el más portable de los tres.

---

**02 → 22.** Diagnostica: en producción aparecen errores `40001` a las horas punta y alguien propone
bajar a `READ COMMITTED`. Da tres hipótesis en orden de probabilidad, la consulta con la que
mirarías la primera, y qué harías antes de tocar el nivel. 🔴

⏱️ **30 segundos** — Primera: una transacción larga que podría ser corta. Segunda: un punto
caliente, unas pocas filas que todo el mundo escribe. Tercera: el nivel está subido donde no hacía
falta. Lo primero que miraría es la duración de las transacciones abiertas.

🗣️ **2 minutos** — Los `40001` no son un fallo, son el motor diciendo "reintenta", así que la
pregunta correcta no es cómo hacerlos desaparecer sino por qué han subido. Una transacción que dura
segundos multiplica la ventana en la que otra puede entrar en conflicto con ella; un contador único
que todos actualizan produce conflictos aunque las transacciones sean cortas; y a veces resulta que
alguien puso `SERIALIZABLE` de forma global «por seguridad». Bajar el nivel sin mirar nada de esto
cambia errores visibles por datos mal.

🔬 **El detalle** — La consulta:

```sql
SELECT pid, state, now() - xact_start AS duracion, wait_event_type, query
  FROM pg_stat_activity
 WHERE xact_start IS NOT NULL
 ORDER BY duracion DESC
 LIMIT 20;
```

Corrida con una sesión parada dentro de un `BEGIN`, la culpable sale la primera —`pid` y duración
cambian en cada corrida, y la segunda fila es siempre la consulta misma—:

```text
  pid  |        state        |    duracion     | wait_event_type |            query
-------+---------------------+-----------------+-----------------+---------------------------
 89437 | idle in transaction | 00:00:03.214175 | Client          | SELECT count(*) FROM pe...
 89438 | active              | 00:00:00        |                 | SELECT pid, state, now(...
(2 filas)
```

- **`wait_event_type = Client` es la firma de la transacción abandonada**: el servidor no espera a
  un bloqueo ni al disco, espera a que alguien le mande algo. Ese es el `idle in transaction` que
  retiene el horizonte de limpieza de toda la base.

Antes de tocar el nivel: comprobar que **existe** un bucle de reintento y que hace retardo creciente
con aleatorio —sin él, un pico de conflictos se realimenta—, acortar la transacción sacando fuera lo
que no necesita estar dentro, y solo entonces plantear el nivel. Si al final hay que bajar a `READ
COMMITTED`, hay que decir qué anomalía se acepta a cambio y protegerla con `FOR UPDATE` donde
importe.

---

## Capítulo 03 — MVCC frente a bloqueo

Las 20 preguntas de [`03`](03-mvcc-frente-a-bloqueo.md).

**03 → 1.** ¿Qué guardan exactamente `xmin` y `xmax` en una versión de fila de PostgreSQL? 🟢

⏱️ **30 segundos** — `xmin` es el identificador de la transacción que creó esa versión de la fila;
`xmax`, el de la que la borró o la reemplazó. Mientras la versión sigue vigente, `xmax` vale 0.

🗣️ **2 minutos** — Son columnas de sistema: no las declaraste tú, no salen en un `SELECT *`, pero se
pueden pedir por su nombre. Entre las dos definen la ventana de tiempo en la que esa versión es
visible, y esa ventana es lo que el motor compara contra tu instantánea para decidir si te toca a ti
o no. Un `UPDATE` no modifica nada: pone el `xmax` de la versión vieja y escribe una nueva con su
propio `xmin`.

🔬 **El detalle** — **Motor**, solo de PostgreSQL: en InnoDB el equivalente son `DB_TRX_ID` y
`DB_ROLL_PTR`, y están ocultas. Los valores concretos no significan nada por sí mismos —dependen de
cuántas transacciones lleve la base—; lo que se lee es la relación entre el `xmin` de la versión
nueva y el `pg_current_xact_id()` de quien la escribió, que coinciden.

---

**03 → 2.** ¿Qué le pasa al `ctid` de una fila cuando la actualizas? 🟢

⏱️ **30 segundos** — Cambia. El `UPDATE` escribe una versión nueva en otra posición, así que la
dirección física ya no es la misma.

🗣️ **2 minutos** — El `ctid` es el par página y número de línea dentro de la página. Como PostgreSQL
no modifica la fila sino que escribe otra, la nueva ocupa una línea distinta: la vieja se queda
donde estaba con su `xmax` puesto, y la nueva aparece en `(8108,57)` donde antes había `(8108,42)`.
También cambia con un `VACUUM FULL`, que reescribe la tabla entera.

🔬 **El detalle** — **Motor.** De ahí sale la regla que ya estaba en `03/01` §3: **`ctid` no sirve
como identificador de fila**, ni para guardarlo, ni para comparar entre consultas. Sirve para mirar
dónde está algo ahora mismo, y nada más. El `rowid` de SQLite sí es estable, y esa diferencia es de
motor, no de estándar.

---

**03 → 3.** ¿Qué es una fila muerta y quién la recicla? 🟢

⏱️ **30 segundos** — Una versión de fila que ya no puede ver ninguna transacción. Ocupa sitio en la
página, no la devuelve ninguna consulta, y quien la recicla es `VACUUM` —normalmente el autovacuum—.

🗣️ **2 minutos** — Aparecen con cada `UPDATE` y con cada `DELETE`, porque los dos dejan la versión
anterior en la tabla. Mientras no pase el `VACUUM`, ese espacio sigue contando: la tabla pesa más, y
la misma consulta lee más páginas para encontrar las mismas filas vivas. El recuento está en
`pg_stat_user_tables.n_dead_tup`.

🔬 **El detalle** — **Motor.** `VACUUM` marca el espacio como reutilizable **dentro** de la tabla, y
solo devuelve al sistema de ficheros las páginas vacías del final; el resto lo recupera `VACUUM
FULL`, que reescribe la tabla y la bloquea en exclusiva. Y el matiz que es causa raíz de la mitad de
los incidentes: `VACUUM` **solo puede quitar lo que el horizonte le permita**.

---

**03 → 4.** Nombra las dos columnas ocultas con las que InnoDB hace el trabajo de `xmin` y `xmax`. 🟢

⏱️ **30 segundos** — `DB_TRX_ID`, que guarda la última transacción que tocó la fila, y
`DB_ROLL_PTR`, que apunta al registro de *undo* con la versión anterior.

🗣️ **2 minutos** — Ocupan seis y siete bytes, y no se pueden seleccionar: son internas. Con ellas
InnoDB hace lo contrario que PostgreSQL: la tabla guarda solo la versión más reciente, y si tu *read
view* no puede ver esa, sigues el `DB_ROLL_PTR` hacia atrás aplicando registros de *undo* hasta
llegar a una que sí puedas ver. Reconstruir, en vez de leer.

🔬 **El detalle** — **Motor**, y solo de InnoDB: otro motor de almacenamiento de MySQL no tiene nada
de esto. Hay una tercera columna oculta, `DB_ROW_ID`, que solo aparece cuando la tabla no declara
clave primaria ni un `UNIQUE NOT NULL`, porque InnoDB necesita una para organizar el índice
agrupado.

---

**03 → 5.** ¿Qué es el horizonte y qué lo fija? 🟢

⏱️ **30 segundos** — Es el punto por debajo del cual el motor puede reciclar versiones viejas. Lo
fija la transacción abierta más antigua: nada posterior a ella se puede limpiar.

🗣️ **2 minutos** — La lógica es conservadora a propósito: si hay una transacción abierta desde el
martes, el motor no sabe qué va a leer todavía, así que tiene que conservar todo lo que esa
transacción podría tener que ver. Da igual que esté inactiva y que no haya tocado esa tabla en su
vida; el horizonte es de la base entera, no de la tabla.

🔬 **El detalle** — **Motor.** En PostgreSQL lo mueven también las réplicas con
`hot_standby_feedback` y las transacciones preparadas, que son las dos causas que no se buscan
nunca. El equivalente en InnoDB es la *read view* más antigua, que impide purgar el *undo*, y el
indicador es `History list length`.

---

**03 → 6.** Distingue MVCC de bloqueo de dos fases: ¿quién espera a quién en cada uno? 🟡

⏱️ **30 segundos** — Con bloqueo de dos fases, el lector espera al escritor y el escritor al lector.
Con MVCC, ninguno de los dos espera al otro: solo esperan dos escritores sobre la misma fila.

🗣️ **2 minutos** — La diferencia está en qué hace el que escribe. En 2PL modifica la fila en su
sitio, así que tiene que impedir que nadie la lea mientras tanto; en MVCC escribe una versión nueva
y deja la vieja, así que el lector siempre tiene algo coherente que leer sin pedir permiso. La
moneda cambia con el mecanismo: 2PL paga esperas e interbloqueos, MVCC paga espacio y trabajo de
limpieza.

🔬 **El detalle** — **Motor**, íntegramente: el estándar no dice nada de mecanismos. Hoy usan MVCC
PostgreSQL, InnoDB, Oracle y SQLite en modo WAL; SQL Server usa 2PL por defecto y tiene MVCC como
opción. Y el matiz que completa la respuesta: MVCC **no elimina** el bloqueo entre dos escritores de
la misma fila, que sigue existiendo en los dos modelos.

---

**03 → 7.** ¿Qué es una instantánea, y por qué tomarla es instantáneo aunque la tabla tenga un
millón de filas? 🟡

⏱️ **30 segundos** — Es una fecha de corte, no una copia: tres datos sobre identificadores de
transacción. Por eso tomarla cuesta lo mismo con mil filas que con un millón.

🗣️ **2 minutos** — Los tres datos son el corte inferior —por debajo, todo terminó—, el corte
superior —por encima, nadie había empezado— y la lista de las que estaban en curso en ese instante.
Con eso y las marcas `xmin`/`xmax` de cada versión, el motor decide fila a fila cuál te toca, en el
momento de leerla. No hay nada que copiar ni nada que reservar.

🔬 **El detalle** — **Motor.** En PostgreSQL se ve con `pg_current_snapshot()`, que devuelve algo
como `15240800:15240806:15240802,15240804`. La regla de visibilidad completa: se ve si el `xmin`
está confirmado y no está en la lista de en curso, y además el `xmax` es 0, está abortado o está en
esa lista.

---

**03 → 8.** ¿Qué cambia entre `READ COMMITTED` y `REPEATABLE READ` en términos de instantánea, y
solo en esos términos? 🟡

⏱️ **30 segundos** — Cuándo se toma. En `READ COMMITTED`, una instantánea por sentencia; en
`REPEATABLE READ`, una sola por transacción, al principio, que dura hasta el final.

🗣️ **2 minutos** — Eso explica los dos fenómenos sin hablar de nada más. Si cada sentencia toma la
suya, la segunda consulta ve lo que se confirmó en medio: ahí están la lectura no repetible y el
fantasma. Si la instantánea es de la transacción, las dos consultas ven exactamente lo mismo, y las
dos anomalías desaparecen por construcción, sin bloquear nada.

🔬 **El detalle** — **Motor**, y coincide en los dos principales: PostgreSQL e InnoDB lo hacen igual.
Lo que no coincide es lo que pasa al **escribir** desde una instantánea vieja: PostgreSQL aborta con
`40001` y InnoDB espera y aplica sobre la versión actual (`02` §6). Y el precio de la instantánea
larga es el horizonte: cuanto más dura, más versiones hay que conservar.

---

**03 → 9.** ¿Dónde está la versión antigua de una fila en PostgreSQL y dónde en InnoDB? Di qué crece
en cada caso y qué categoría es esa diferencia. 🟡

⏱️ **30 segundos** — En PostgreSQL, en la propia tabla, y lo que crece es la tabla. En InnoDB, en el
*undo log*, y lo que crece es el espacio de *undo*.

🗣️ **2 minutos** — Es la misma factura pagada en dos sitios distintos, y conviene decirlo así porque
evita la falsa comparación de "cuál es mejor". En PostgreSQL las versiones muertas se mezclan con
las vivas en las mismas páginas, así que una tabla muy actualizada se hincha y sus consultas leen
más páginas. En InnoDB la tabla se mantiene compacta, pero el fichero de *undo* crece mientras haya
lectores antiguos, y recorrer cadenas largas de *undo* va haciendo más lentas las lecturas de
versiones viejas.

🔬 **El detalle** — **Motor.** Quien limpia es `VACUUM` en uno y el hilo de purga en el otro, y los
dos se quedan parados por la misma razón: un lector antiguo. El indicador es `n_dead_tup` en
`pg_stat_user_tables` frente a `History list length` en `SHOW ENGINE INNODB STATUS`.

---

**03 → 10.** ¿Está MVCC en el estándar? Responde por separado para la norma y para los tres motores
del corpus. 🟡

⏱️ **30 segundos** — No. El estándar dice qué anomalías tolera cada nivel de aislamiento y no dice
nada de cómo conseguirlo. MVCC es una decisión de cada motor.

🗣️ **2 minutos** — Por eso dos motores pueden cumplir la misma fila de la tabla de niveles con
mecanismos opuestos sin que ninguno incumpla nada. PostgreSQL lo hace con versiones en la tabla,
InnoDB con *undo log*, y SQLite no necesita casi nada porque solo admite un escritor a la vez; en
modo WAL, además, los lectores ven una instantánea mientras el escritor avanza.

🔬 **El detalle** — **Estándar** para los cuatro niveles y las anomalías; **motor** para
absolutamente todo lo demás: si la versión vieja se guarda o se reconstruye, si el `ROLLBACK` es una
anotación o un trabajo proporcional, quién limpia y cuándo. Es la misma distinción que `02` §2
fijaba para los niveles, aplicada al mecanismo.

---

**03 → 11.** Explica por qué `VACUUM` casi nunca encoge el fichero de la tabla, en qué caso sí lo
hace y qué lo encoge siempre, con su precio. 🟡

⏱️ **30 segundos** — Porque marca el espacio de las filas muertas como reutilizable dentro de la
tabla, en vez de mover filas. Solo encoge el fichero cuando las páginas del **final** quedan vacías
y consigue un instante de bloqueo exclusivo. Quien lo encoge siempre es `VACUUM FULL`, que reescribe
la tabla entera y la bloquea en exclusiva mientras lo hace.

🗣️ **2 minutos** — Es una decisión deliberada: liberar el hueco del medio exigiría compactar, y
compactar exige mover filas, y mover filas exige que nadie las esté leyendo. El `VACUUM` normal
corre en paralelo con todo lo demás precisamente porque no compacta; lo único que se permite es
cortar la cola vacía, y lo abandona si alguien tiene la tabla abierta. Corrido: con otra sesión
leyendo `pedidos` dijo `stopping truncate due to conflicting lock request`, y sin ella, `truncated
17640 to 10770 pages`.

🔬 **El detalle** — **Motor.** `VACUUM FULL` necesita además espacio libre para la copia nueva
mientras trabaja, así que en una tabla de 100 GB no es una opción a las tres de la tarde. Por eso el
consejo real es que **el *bloat* se previene, no se cura**: autovacuum bien ajustado y transacciones
cortas. En InnoDB el equivalente es `OPTIMIZE TABLE`, con el mismo tipo de coste.

---

**03 → 12.** Explica por qué un `ROLLBACK` de un millón de filas termina al instante en PostgreSQL y
puede tardar minutos en InnoDB. 🟠

⏱️ **30 segundos** — Porque en PostgreSQL no hay nada que deshacer: las versiones viejas nunca se
tocaron, y basta con anotar que la transacción abortó. InnoDB sí modificó las filas, así que tiene
que aplicar el *undo log* al revés, registro a registro.

🗣️ **2 minutos** — Es consecuencia directa de dónde vive cada versión. PostgreSQL escribió un millón
de filas nuevas y dejó intactas las viejas; al abortar, las nuevas dejan de ser visibles para todo
el mundo con un solo apunte, y el millón de filas muertas se lo lleva el `VACUUM` después. InnoDB
escribió sobre las filas y guardó el estado anterior aparte; para volver atrás hay que leer ese
estado y reescribirlo, que es tanto trabajo como el original o más.

🔬 **El detalle** — **Motor**, y tiene su reverso: lo que PostgreSQL ahorra al deshacer lo paga en
limpieza, porque ese millón de filas muertas hay que reciclarlo. La regla operativa que sale de aquí
es que en InnoDB **un lote enorme que puede fallar conviene partirlo**, porque el `ROLLBACK` de la
última fila arrastra el trabajo de todas las anteriores.

---

**03 → 13.** ¿Qué es una actualización HOT, qué dos condiciones pide y qué ahorra exactamente? 🟠

⏱️ **30 segundos** — Es un `UPDATE` que encadena la versión nueva dentro de la misma página y **no
escribe ninguna entrada de índice**. Pide dos cosas: que no cambie ninguna columna indexada y que la
versión nueva quepa en la página.

🗣️ **2 minutos** — Lo que ahorra es la escritura en todos los índices de la tabla, que es la parte
cara de un `UPDATE` cuando hay varios. Sin HOT, actualizar una fila obliga a insertar una entrada
nueva en cada índice y a dejar muerta la anterior, así que los índices se hinchan al mismo ritmo que
la tabla. Con HOT, el índice sigue apuntando a la misma línea y el motor sigue la cadena dentro de
la página.

🔬 **El detalle** — **Motor.** La segunda condición depende del `fillfactor`, que reserva espacio
libre en cada página justo para esto; en una tabla muy actualizada bajarlo del 100 % por defecto es
una de las pocas optimizaciones que se paga sola. Y la consecuencia de diseño: **indexar una columna
que se actualiza mucho mata el HOT de esa tabla**, y eso hay que contarlo entre los costes del
índice.

---

**03 → 14.** Una consola con un `BEGIN` olvidado desde el martes. Explica la cadena completa hasta
que el disco se llena, paso a paso. 🟠

⏱️ **30 segundos** — Esa transacción abierta fija el horizonte en el martes. `VACUUM` no puede
reciclar nada escrito después, las filas muertas se acumulan en todas las tablas, y la base crece
hasta llenar el disco.

🗣️ **2 minutos** — Paso a paso: la sesión queda `idle in transaction`, y como podría leer cualquier
cosa, el motor conserva toda versión que ella pudiera necesitar. El autovacuum sigue corriendo —eso
confunde el diagnóstico—, pero cada pasada no borra nada útil. Las tablas y sus índices crecen, las
filas vivas se reparten en más páginas, las consultas leen más páginas y todo se vuelve más lento
antes de que nadie mire el disco. Y no importa que esa sesión no haya tocado la tabla que crece: el
horizonte es de la base entera.

🔬 **El detalle** — **Motor.** Se confirma con `pg_stat_activity` ordenada por `xact_start`, buscando
la más antigua con `state = 'idle in transaction'`. La prevención tiene nombre de parámetro:
`idle_in_transaction_session_timeout`, que mata esas sesiones solas. En InnoDB es el mismo cuento
con la *read view* y el espacio de *undo* en lugar de la tabla.

---

**03 → 15.** Estás en `REPEATABLE READ` y otra sesión actualiza y confirma una fila que leíste. ¿Te
protege tu instantánea de escribir sobre un dato caducado? Responde para los dos motores. 🟠

⏱️ **30 segundos** — No. La instantánea te protege al **leer**, no al escribir. En PostgreSQL, si
escribes esa fila la transacción se aborta con `40001`; en InnoDB no se aborta: espera y escribe
sobre la versión más reciente.

🗣️ **2 minutos** — Es la confusión más cara del tema, porque "mi lectura es estable" suena a "estoy
a salvo". Lo que la instantánea garantiza es que tú sigues viendo el valor viejo; no impide que otro
lo cambie y confirme. En PostgreSQL el motor detecta que escribes sobre algo que cambió desde tu
instantánea y te obliga a reintentar; en InnoDB el `UPDATE` se aplica sin protestar, así que un
leer-decidir-escribir repartido entre aplicación y base pierde la actualización igual que en `READ
COMMITTED`.

🔬 **El detalle** — **Motor**, y es la fila que más separa a los dos. La defensa que funciona en
ambos es la misma de `02` §6: dejar la aritmética al `UPDATE`, o tomar el bloqueo al leer con
`SELECT … FOR UPDATE`, que es el material de [`04`](04-bloqueos-e-interbloqueos.md).

---

**03 → 16.** Un informe en MySQL va perdiendo velocidad según avanza, sin que cambie la consulta ni
los datos. Da el mecanismo y el indicador que lo confirma. 🟠

⏱️ **30 segundos** — Su *read view* envejece: cada fila que lee exige recorrer una cadena de *undo*
más larga para reconstruir la versión que a él le corresponde. El indicador es `History list length`
en `SHOW ENGINE INNODB STATUS`.

🗣️ **2 minutos** — Mientras el informe corre, el resto del sistema sigue actualizando filas, y cada
actualización añade un registro de *undo* que el informe tendrá que saltar. Como el hilo de purga no
puede limpiar nada que la *read view* del informe pudiera necesitar, esos registros se acumulan. El
informe no espera a nadie —eso es MVCC funcionando—, pero paga en E/S de reconstrucción lo que no
paga en espera.

🔬 **El detalle** — **Motor**, exclusivo de InnoDB: el equivalente de PostgreSQL no se degrada igual,
porque las versiones están en la tabla y no hay cadena que recorrer, aunque sí paga en páginas más
llenas de filas muertas. Las dos salidas son las mismas de siempre: acortar la transacción del
informe, o sacarlo a una réplica.

---

**03 → 17.** Alguien propone apagar el autovacuum «porque mete ruido en las horas punta». Dale la
contrapartida en las cinco monedas que apliquen. 🟠

⏱️ **30 segundos** — Cambia un coste continuo, medido y acotado por otro acumulado e imprevisible.
Lo que hoy son unos minutos de E/S de fondo, mañana es un `VACUUM FULL` con la tabla bloqueada.

🗣️ **2 minutos** — Moneda por moneda: **espacio**, la tabla y sus índices crecen sin límite;
**E/S**, la misma consulta lee más páginas porque las filas vivas están más dispersas; **tiempo**,
los planes empeoran porque `ANALYZE` también deja de correr y las estimaciones envejecen;
**concurrencia**, porque la cura —`VACUUM FULL`— exige bloqueo exclusivo sobre la tabla; y
**riesgo**, porque en PostgreSQL el `VACUUM` también evita el agotamiento de identificadores de
transacción, y ese sí para la base en seco.

🔬 **El detalle** — **Motor.** La respuesta correcta al problema real —el ruido en hora punta— no es
apagarlo sino ajustarlo: subir el coste que puede gastar por pasada para que termine antes, o bajar
el disparador de la tabla concreta que lo provoca. Apagarlo es de las pocas cosas de este corpus que
se pueden llamar directamente un error.

---

**03 → 18.** Diagnostica: la tabla `pedidos` ocupa el triple de lo que deberían pesar sus filas
vivas. Da tres hipótesis en orden de probabilidad, la consulta con la que confirmarías la primera, y
qué harías antes de tocar nada. 🔴

⏱️ **30 segundos** — Primera hipótesis: hay una transacción abierta antigua que fija el horizonte y
el `VACUUM` no puede limpiar. Segunda: el autovacuum no llega a esa tabla porque se actualiza mucho
más que el resto. Tercera: una ráfaga puntual de actualizaciones masivas ya limpiada, y lo que queda
es espacio reutilizable que nunca se reutilizó.

🗣️ **2 minutos** — El orden no es caprichoso: la primera explica el caso en que el `n_dead_tup` es
enorme **y** el autovacuum sí está corriendo, que es lo que más despista. La segunda se distingue
mirando la fecha del último autovacuum. La tercera es benigna: el fichero es grande pero la tabla ya
no acumula, y no hace falta hacer nada salvo que el espacio haga falta de verdad.

🔬 **El detalle** — La consulta para la primera:

```sql
SELECT pid, state, now() - xact_start AS duracion, query
  FROM pg_stat_activity
 WHERE xact_start IS NOT NULL
 ORDER BY duracion DESC
 LIMIT 10;
```

Corrida con una sesión parada dentro de un `BEGIN`, la culpable sale arriba —los `pid` y la duración
cambian en cada corrida—:

```text
  pid  |        state        |    duracion     |                query
-------+---------------------+-----------------+------------------------------------
 90463 | idle in transaction | 00:00:03.289643 | SELECT count(*) FROM pedidos WHE...
 90472 | active              | 00:00:00        | SELECT pid, state, now() - xact_...
(2 filas)
```

Antes de tocar nada: mirar `n_dead_tup` y `last_autovacuum` en `pg_stat_user_tables` para saber si
el problema es que no se limpia o que no se reutiliza, y **no lanzar un `VACUUM FULL` con tráfico**
—bloquea la tabla en exclusiva y necesita espacio para la copia—. Si hay una transacción de horas en
`idle in transaction`, la corrección es esa sesión y su causa, no la tabla.

---

**03 → 19.** Escribe la sesión de `psql` —sentencia a sentencia, y dejando los datos como estaban—
que enseña que un `UPDATE` crea una versión nueva: qué seleccionas antes, qué después, y qué tres
valores comparas. 🔴

⏱️ **30 segundos** — Seleccionas `ctid`, `xmin` y `xmax` de la fila; abres transacción, anotas
`pg_current_xact_id()`, actualizas, vuelves a seleccionar los tres, y deshaces con `ROLLBACK`.

🗣️ **2 minutos** — La secuencia completa:

```sql
SELECT ctid, xmin, xmax, estado FROM pedidos WHERE codigo = 'PED-99999';
BEGIN;
SELECT pg_current_xact_id();
UPDATE pedidos SET estado = 'PENDIENTE' WHERE codigo = 'PED-99999';
SELECT ctid, xmin, xmax, estado FROM pedidos WHERE codigo = 'PED-99999';
ROLLBACK;
```

Corrida entera, con la salida de las dos consultas:

```text
    ctid     | xmin | xmax | estado
-------------+------+------+---------
 (10769,104) | 1013 |    0 | ANULADO

 pg_current_xact_id
--------------------
               1014

    ctid     | xmin | xmax |  estado
-------------+------+------+-----------
 (10769,105) | 1014 |    0 | PENDIENTE
```

Los tres valores que se comparan: el **`ctid`**, que cambia de posición dentro de la página —de la
104 a la 105—; el **`xmin`** de la versión nueva, que es el identificador que devolvió
`pg_current_xact_id()`; y el **`xmax`** de la versión vieja, que ha dejado de ser 0.

🔬 **El detalle** — Aquí no hace falta compensación, y esa es media respuesta: **la sesión no
confirma**, así que el `ROLLBACK` deja los datos exactamente como estaban y la versión nueva queda
muerta. Para ver la versión vieja desde fuera haría falta otra sesión o la extensión `pageinspect`,
porque desde dentro de la transacción ya no es visible. Y el aviso honesto: los números de `xmin`
dependen de cuántas transacciones lleve la base, así que lo que se mira es la relación, no el
dígito.

---

**03 → 20.** Tienes una tabla de saldos que se actualiza cien veces por segundo sobre las mismas mil
filas. Defiende PostgreSQL o InnoDB para ese caso concreto, con el mecanismo y el coste de cada uno,
y di qué medirías para comprobar que acertaste. 🔴

⏱️ **30 segundos** — Para ese patrón concreto InnoDB tiene ventaja estructural: la tabla guarda una
sola versión, así que no se hincha. En PostgreSQL esas mil filas generan cien versiones muertas por
segundo que hay que reciclar sin parar.

🗣️ **2 minutos** — El argumento completo tiene dos mitades. La de InnoDB: las versiones viejas van
al *undo* y se purgan; la tabla y sus índices se mantienen compactos aunque lleven meses. La de
PostgreSQL: el mismo patrón produce *bloat* continuo, y solo se sostiene si el autovacuum va al día
y si las actualizaciones son **HOT** —ninguna columna indexada tocada y sitio en la página, lo que
obliga a bajar el `fillfactor` y a no indexar la columna de saldo—. Con esas dos condiciones
cumplidas, PostgreSQL aguanta perfectamente; sin ellas, se degrada.

🔬 **El detalle** — Qué mediría, que es lo que convierte la opinión en decisión: en PostgreSQL,
`n_dead_tup` frente a `n_live_tup` y la proporción de actualizaciones HOT en `pg_stat_user_tables`,
más el tamaño de la tabla a lo largo de una semana; en InnoDB, `History list length` y el tamaño del
espacio de *undo*. Y la advertencia de encuadre, que vale más que la elección: si las mil filas son
saldos de cuenta y hay contención real sobre las mismas, **el cuello no va a ser el motor sino el
bloqueo entre escritores**, y eso no lo arregla cambiar de base.

---

## Capítulo 04 — Bloqueos e interbloqueos

Las 19 preguntas de [`04`](04-bloqueos-e-interbloqueos.md).

**04 → 1.** ¿Qué bloqueo toma un `SELECT` normal, a quién estorba, y lo fija el estándar o el motor?
🟢

⏱️ **30 segundos** — Toma `ACCESS SHARE` sobre la tabla. Solo estorba a `ACCESS EXCLUSIVE`, que es
lo que piden `ALTER TABLE`, `DROP`, `TRUNCATE` y `VACUUM FULL`.

🗣️ **2 minutos** — Lo importante de esa respuesta es la mitad negativa: no estorba a otro `SELECT`,
ni a un `INSERT`, ni a un `UPDATE`. Un `SELECT` no bloquea a nadie que trabaje con datos. Lo que sí
hace, y es la causa de muchos incidentes de despliegue, es bloquear el DDL mientras dure: un informe
de cuarenta segundos retrasa cuarenta segundos el `ALTER TABLE` que llegue detrás.

🔬 **El detalle** — **Motor.** En MySQL el mecanismo se llama distinto —*metadata lock*— y hace lo
mismo: cualquier sentencia, incluido un `SELECT` dentro de una transacción abierta, bloquea el DDL
sobre esa tabla. El estándar no define ningún modo de bloqueo, así que toda esta respuesta es de
motor.

---

**04 → 2.** ¿Qué hace exactamente `SELECT … FOR UPDATE`? 🟢

⏱️ **30 segundos** — Lee las filas y además las reserva, como si las hubieras actualizado, hasta que
termine la transacción. Cualquier otra sesión que quiera escribirlas o bloquearlas espera.

🗣️ **2 minutos** — Sirve para cerrar el hueco del patrón leer-decidir-escribir: entre tu `SELECT` y
tu `UPDATE` ya no cabe nadie. Quien pide el mismo bloqueo se queda esperando **en el `SELECT`**, no
en el `UPDATE`, que es justo lo que se quiere: cuando despierta, lee el valor ya actualizado y
decide con él en vez de pisar el trabajo del otro.

🔬 **El detalle** — **Estándar** en cuanto a que `FOR UPDATE` existe como parte de la definición de
cursor; **motor** para la forma que todo el mundo usa, un `SELECT` suelto, y para los modos finos de
PostgreSQL —`FOR NO KEY UPDATE`, `FOR KEY SHARE`—. SQLite no lo tiene: con un solo escritor no hace
falta. Sobre la tabla toma solo `ROW SHARE`, que casi no estorba.

---

**04 → 3.** ¿Cuánto vale `deadlock_timeout` por defecto en PostgreSQL, y qué implica ese valor? 🟢

⏱️ **30 segundos** — Un segundo. Implica que el motor no busca ciclos hasta que una sesión lleva un
segundo esperando, así que un interbloqueo tarda siempre al menos ese segundo en aparecer.

🗣️ **2 minutos** — La razón es de coste: recorrer el grafo de esperas cada vez que alguien se
bloquea sería caro y casi siempre inútil, porque la mayoría de las esperas se resuelven solas en
milisegundos. Esperar un segundo antes de mirar convierte una comprobación constante en una rara. El
efecto lateral útil es de diagnóstico: si un error de interbloqueo apareció al instante, no era un
interbloqueo.

🔬 **El detalle** — **Motor.** InnoDB hace lo contrario: mantiene el grafo de esperas y detecta el
ciclo al momento, con `innodb_deadlock_detect` activado por defecto. Bajar `deadlock_timeout` en
PostgreSQL no reduce los interbloqueos; solo hace que se detecten antes y que el motor gaste más
tiempo buscándolos.

---

**04 → 4.** ¿Hay espera máxima por defecto en PostgreSQL y en MySQL? Di el parámetro y el valor de
cada uno. 🟢

⏱️ **30 segundos** — En PostgreSQL no: `lock_timeout` viene desactivado, así que una sesión
bloqueada espera indefinidamente. En MySQL sí: `innodb_lock_wait_timeout` vale 50 segundos.

🗣️ **2 minutos** — Es una de las diferencias que más se notan al migrar y que nadie anticipa. El
mismo código se comporta como una petición colgada para siempre en PostgreSQL y como un fallo tardío
en MySQL, con un error distinto del de interbloqueo —`ERROR 1205`—. En PostgreSQL, poner un
`lock_timeout` de sesión es de las cosas más baratas que se pueden hacer para que un incidente sea
un error en vez de una caída.

🔬 **El detalle** — **Motor.** SQLite tiene su propia versión, `busy_timeout`, también a 0 por
defecto, que devuelve `SQLITE_BUSY` al instante. Y el matiz que completa la respuesta:
`lock_timeout` cuenta **la espera por un bloqueo**, no la duración de la sentencia; para eso está
`statement_timeout`, y las dos se ponen por separado.

---

**04 → 5.** Distingue un bloqueo de tabla de uno de fila, y di quién toma cada uno. 🟡

⏱️ **30 segundos** — El de tabla protege la tabla como objeto —su estructura y su existencia— y lo
toma toda sentencia, incluido un `SELECT`. El de fila protege una fila concreta y lo toma quien
escribe, o quien lo pide con `FOR UPDATE`.

🗣️ **2 minutos** — Confundirlos lleva a dos errores opuestos. Uno es creer que un `UPDATE` «bloquea
la tabla»: toma `ROW EXCLUSIVE`, que no entra en conflicto consigo mismo, así que dos `UPDATE` sobre
filas distintas no se estorban en absoluto. El otro es creer que un `SELECT` no bloquea nada: toma
`ACCESS SHARE`, y eso basta para poner un `ALTER TABLE` en la cola.

🔬 **El detalle** — **Motor.** PostgreSQL tiene ocho modos de tabla y cuatro de fila, con una matriz
de conflictos publicada; los de fila son `FOR KEY SHARE`, `FOR SHARE`, `FOR NO KEY UPDATE` y `FOR
UPDATE`, de más débil a más fuerte. Los de fila se ven en `pg_locks` y también en el `xmax` de la
propia fila, que es donde el motor los anota cuando son pocos.

---

**04 → 6.** ¿Por qué dos `UPDATE` sobre filas distintas de la misma tabla no se estorban? 🟡

⏱️ **30 segundos** — Porque el bloqueo de tabla que toman, `ROW EXCLUSIVE`, no entra en conflicto
consigo mismo, y los bloqueos de fila son de filas distintas. No hay nada compartido en disputa.

🗣️ **2 minutos** — Es la consecuencia práctica de que haya dos niveles. El modo de tabla que toma un
escritor existe para excluir al DDL y a `VACUUM FULL`, no para excluir a otros escritores; a esos
los arbitra el bloqueo de fila. Por eso una tabla con mil escritores concurrentes funciona
perfectamente mientras escriban filas distintas, y se convierte en una fila india en cuanto todos
quieren la misma.

🔬 **El detalle** — **Motor.** La excepción que conviene nombrar es InnoDB con sus *next-key locks*
(`02` §5): ahí un `UPDATE` por rango puede bloquear **huecos** donde no hay ninguna fila, y entonces
sí estorba a un `INSERT` que no toca ninguna fila tuya. Es el caso en que la intuición de «filas
distintas, sin conflicto» falla, y solo falla en MySQL.

---

**04 → 7.** Diferencia `NOWAIT` de `SKIP LOCKED`: qué pasa con cada uno cuando la fila está
bloqueada. 🟡

⏱️ **30 segundos** — `NOWAIT` falla al instante con un error en vez de esperar. `SKIP LOCKED` no
falla: omite del resultado las filas bloqueadas y te devuelve las demás.

🗣️ **2 minutos** — Sirven para cosas distintas. `NOWAIT` es para un proceso que prefiere decir «está
ocupado, vuelve luego» antes que colgarse: devuelve `55P03` y tú decides. `SKIP LOCKED` es para
repartir trabajo entre varios consumidores sin coordinarlos: cada trabajador se lleva las filas que
nadie más tiene, y ninguno espera a nadie.

🔬 **El detalle** — **Motor**, aunque ya no distinga a nadie: PostgreSQL los tiene desde hace una
década y MySQL los añadió en 8.0; SQLite no tiene ninguno. El precio de `SKIP LOCKED` es que el
resultado deja de ser determinista —dos ejecuciones idénticas devuelven conjuntos distintos—, y el
`ORDER BY` no lo arregla porque ordena lo que quedó tras omitir. Por eso vale en una cola y es un
error en un informe.

---

**04 → 8.** ¿Está `FOR UPDATE` en el estándar? Responde por separado para la norma y para los tres
motores del corpus. 🟡

⏱️ **30 segundos** — Sí, la norma lo define en el contexto de los cursores. La forma que todo el
mundo usa —un `SELECT` suelto con `FOR UPDATE`— es de motor: la tienen PostgreSQL y MySQL, y SQLite
no.

🗣️ **2 minutos** — Es un buen ejemplo de cómo la costumbre se desplaza del estándar sin que nadie lo
note. El estándar habla de si un cursor es actualizable; lo que el gremio llama «hacer un `FOR
UPDATE`» es una extensión que los motores generalizaron y que hoy parece norma. Los modos finos son
directamente de PostgreSQL: `FOR NO KEY UPDATE` y `FOR KEY SHARE` no existen en ningún otro de los
tres.

🔬 **El detalle** — **Estándar** para la cláusula en cursores; **motor** para todo lo demás,
incluidos `NOWAIT` y `SKIP LOCKED`. SQLite no lo necesita porque solo admite un escritor a la vez:
la pregunta que `FOR UPDATE` responde no llega a plantearse. Es de las respuestas donde decir «no lo
he verificado en la cláusula concreta, la norma es de pago» es preferible a inventar el número.

---

**04 → 9.** ¿Qué `SQLSTATE` da el interbloqueo en PostgreSQL y cuál en MySQL, y qué consecuencia
tiene eso para tu bucle de reintento? 🟡

⏱️ **30 segundos** — PostgreSQL da `40P01`; MySQL da `40001`, el mismo que PostgreSQL usa para los
conflictos de serialización. La consecuencia: un bucle escrito para `40001` cubre el interbloqueo en
MySQL, y en PostgreSQL hay que añadir `40P01` aparte.

🗣️ **2 minutos** — Es un detalle pequeño con efecto grande, porque la gente copia el bucle de una
base a otra. En PostgreSQL, si solo reintentas `40001`, estás reintentando los conflictos de
`REPEATABLE READ` y `SERIALIZABLE` y dejando fuera los interbloqueos, que son los que más
seguramente vas a tener si hay bloqueos explícitos. Las dos familias se reintentan igual —la
transacción entera, desde el `BEGIN`— así que no cuesta nada cubrir las dos.

🔬 **El detalle** — **Motor.** Las tres condiciones del bucle son las mismas de `02` §9: se reintenta
la transacción entera y no la sentencia; se reintenta solo por los códigos que lo merecen, nunca un
`23505` de clave duplicada; y el trabajo tiene que ser repetible, lo que excluye llamadas externas
dentro de la transacción. Y retardo creciente, o un pico de contención se realimenta.

---

**04 → 10.** Explica por qué `FOR SHARE` es una fábrica de interbloqueos cuando las sesiones que lo
toman acaban escribiendo. 🟠

⏱️ **30 segundos** — Porque el compartido lo pueden tener varias a la vez, pero para escribir hace
falta el exclusivo, y nadie puede soltar el compartido hasta el final de su transacción. Dos
sesiones con el compartido sobre la misma fila, las dos queriendo escribir, se esperan en círculo.

🗣️ **2 minutos** — Es un ciclo perfecto y no hace falta que nadie ordene nada al revés: basta con
que las dos hagan exactamente lo mismo. A toma `FOR SHARE`, B toma `FOR SHARE` —conviven, ningún
problema—, A pide escribir y espera a que B suelte, B pide escribir y espera a que A suelte. El
motor mata a una. Por eso el patrón «leo con `FOR SHARE` para que no cambie, y luego decido si
escribo» es más peligroso que el `FOR UPDATE` directo.

🔬 **El detalle** — **Motor**, y la corrección es de una línea: **si vas a escribir, toma el bloqueo
fuerte desde el principio** con `FOR UPDATE`, aunque todavía no sepas si escribirás. Se paga algo de
concurrencia y se elimina la clase entera de interbloqueo. Esta es la escalada de bloqueo clásica, y
es el mismo mecanismo por el que el `SERIALIZABLE` de InnoDB —que convierte cada `SELECT` en lectura
compartida (`02` §8)— produce muchos más interbloqueos que el de PostgreSQL.

---

**04 → 11.** ¿Por qué un interbloqueo en PostgreSQL tarda al menos un segundo en aparecer, y cómo
usas ese dato para diagnosticar? 🟠

⏱️ **30 segundos** — Porque el detector no corre siempre: espera `deadlock_timeout`, un segundo por
defecto, antes de buscar un ciclo. Como diagnóstico sirve al revés: si el error tardó mucho más de
un segundo, hubo espera larga antes del ciclo.

🗣️ **2 minutos** — El uso práctico es separar dos incidentes que se confunden. Un interbloqueo
limpio aparece al segundo de que las dos sesiones se crucen; si en los registros ves errores de
interbloqueo a los treinta segundos, lo que hay delante es una transacción larga que retuvo el
bloqueo todo ese rato, y el interbloqueo es el síntoma final, no la causa. Y si el error apareció al
instante, no era PostgreSQL o no era un interbloqueo.

🔬 **El detalle** — **Motor.** El detalle del mensaje —qué proceso espera a cuál, y por qué
transacción— está en el `DETAIL`, y el texto de las consultas implicadas solo aparece en el log del
servidor, no en lo que recibe el cliente. Por eso el `log_lock_waits` activado es lo que convierte
un incidente en algo diagnosticable al día siguiente.

---

**04 → 12.** Un `ALTER TABLE ADD COLUMN` tarda un milisegundo y tumbó el sitio diez minutos. Explica
el mecanismo completo y la defensa de dos líneas. 🟠

⏱️ **30 segundos** — El `ALTER` pide `ACCESS EXCLUSIVE` y se pone a esperar detrás de un `SELECT`
largo. Todo lo que llega después se pone detrás del `ALTER`, que está delante en la cola. Lo que
tumba el sitio no es el `ALTER`: es la cola.

🗣️ **2 minutos** — El punto que hay que dejar claro es que las peticiones no adelantan. Los `SELECT`
del *checkout* no chocan con el informe —dos `ACCESS SHARE` conviven sin problema—, pero tampoco
pueden saltarse una petición de `ACCESS EXCLUSIVE` que llegó antes que ellos, porque eso dejaría al
DDL esperando para siempre. Así que un informe de cuarenta segundos se convierte en cuarenta
segundos de sitio caído, y si el informe dura diez minutos, diez minutos.

🔬 **El detalle** — La defensa:

```sql
SET lock_timeout = '3s';
ALTER TABLE pedidos ADD COLUMN canal text;
```

Corrida con un informe abierto delante, y con `\set VERBOSITY verbose` para ver el `SQLSTATE`:

```text
ERROR:  55P03: canceling statement due to lock timeout
```

No acelera nada: hace que **falle la migración**, que se puede reintentar, en vez de la aplicación.
**Motor**: en MySQL el mismo incidente se produce con el *metadata lock*, que sostiene cualquier
transacción abierta aunque solo haya leído. Y el matiz que cierra la respuesta: un `ADD COLUMN` sin
`DEFAULT` volátil solo toca el catálogo en PostgreSQL moderno, así que todo el riesgo está en
**conseguir** el bloqueo, no en usarlo.

---

**04 → 13.** ¿Por qué InnoDB mata a la transacción que menos trabajo ha hecho, y por qué PostgreSQL
no usa ese criterio? 🟠

⏱️ **30 segundos** — Porque en InnoDB deshacer cuesta proporcionalmente al trabajo hecho: matar a la
que menos escribió es lo más barato. En PostgreSQL deshacer es una anotación y cuesta lo mismo en
los dos casos, así que no hay nada que optimizar.

🗣️ **2 minutos** — Es una consecuencia directa de dónde vive cada versión de fila. InnoDB modifica
las filas y guarda el estado anterior en el *undo log*, así que un `ROLLBACK` tiene que aplicar ese
registro al revés, fila a fila. PostgreSQL escribe versiones nuevas y deja las viejas intactas: al
abortar, basta con marcar la transacción como abortada y todo lo suyo deja de ser visible. Sin coste
de deshacer, el criterio de víctima deja de importar y PostgreSQL mata simplemente a la que detecta
el ciclo.

🔬 **El detalle** — **Motor**, y es de los sitios donde dos capítulos encajan: el mecanismo está en
[`03`](03-mvcc-frente-a-bloqueo.md) §5. La consecuencia operativa en InnoDB es que **la transacción
grande tiende a sobrevivir y la pequeña a morir**, lo que en la práctica significa que tu lote
nocturno mata a las peticiones de usuario. No hay regla de antigüedad en ninguno de los dos motores.

---

**04 → 14.** Tienes una cola de pedidos pendientes y diez trabajadores. Explica qué pasa sin `SKIP
LOCKED` y qué se pierde al usarlo. 🟠

⏱️ **30 segundos** — Sin `SKIP LOCKED`, los diez piden las mismas filas más antiguas y nueve esperan
al primero: la cola se serializa. Con él, cada uno se lleva filas distintas y ninguno espera. Lo que
se pierde es el determinismo del resultado.

🗣️ **2 minutos** — El patrón es `SELECT … WHERE estado = 'PENDIENTE' ORDER BY creado_en LIMIT 10 FOR
UPDATE SKIP LOCKED` dentro de una transacción que procesa y confirma. Cada trabajador ve las diez
más antiguas **que nadie más tiene bloqueadas**, así que el reparto sale solo, sin tabla de
asignaciones, sin coordinador y sin nada que limpiar cuando un trabajador muere: si su transacción
se cae, sus filas quedan libres al instante.

🔬 **El detalle** — **Motor.** Lo que se pierde de verdad: dos ejecuciones idénticas devuelven
conjuntos distintos, y el `ORDER BY` ordena lo que quedó tras omitir, no la cola completa. Es
correcto en una cola de trabajo y un error en un informe. Y el encuadre que sube la nota: esto no
sustituye a una cola de mensajes cuando hay millones de mensajes al día, pero para decenas de miles
evita introducir un sistema entero.

---

**04 → 15.** Alguien propone subir `innodb_lock_wait_timeout` a 300 s «para que dejen de aparecer
interbloqueos». Dile por qué no funciona y qué empeora. 🟠

⏱️ **30 segundos** — Porque un interbloqueo es un ciclo, y un ciclo no se deshace esperando más. En
InnoDB además ni siquiera es ese parámetro el que actúa: el detector mata el ciclo al instante,
independientemente del *timeout*.

🗣️ **2 minutos** — Lo que sí toca ese parámetro son las esperas que **no** son ciclos: una
transacción que retiene un bloqueo mucho tiempo. Subirlo a cinco minutos significa que una sesión
bloqueada ocupa su conexión cinco minutos, y con un pool de veinte conexiones eso agota el pool y
convierte un problema localizado en una caída general. Se está cambiando un error rápido y manejable
por una degradación lenta.

🔬 **El detalle** — **Motor.** La dirección correcta es la contraria: bajarlo, y en PostgreSQL poner
un `lock_timeout` que por defecto no existe. Lo que de verdad elimina los interbloqueos es el orden
fijo de acceso; el *timeout* solo decide **cómo falla** lo que quede. Confundir las dos cosas es el
error de diagnóstico más común del capítulo.

---

**04 → 16.** Escribe la secuencia completa de dos sesiones —sentencia a sentencia, y dejando los
datos como estaban— que produce un interbloqueo, y di qué sesión escribe la compensación y por qué
la otra no. 🔴

⏱️ **30 segundos** — Dos sesiones que actualizan `PED-00042` y `PED-99999` en orden inverso. La que
sobrevive y confirma escribe la compensación; la víctima no necesita ninguna, porque el motor abortó
su transacción entera.

🗣️ **2 minutos** — La secuencia:

```text
-- sesión A                              -- sesión B
BEGIN;                                   BEGIN;
UPDATE pedidos SET estado='PENDIENTE'
  WHERE codigo='PED-00042';
                                         UPDATE pedidos SET estado='PENDIENTE'
                                           WHERE codigo='PED-99999';
UPDATE pedidos SET estado='PAGADO'
  WHERE codigo='PED-99999';   -- ⏸
                                         UPDATE pedidos SET estado='PAGADO'
                                           WHERE codigo='PED-00042';   -- ⏸
                                         ERROR:  deadlock detected
                                         ROLLBACK;
-- ▶ A continúa
COMMIT;
UPDATE pedidos SET estado='PAGADO'  WHERE codigo='PED-00042';
UPDATE pedidos SET estado='ANULADO' WHERE codigo='PED-99999';
```

🔬 **El detalle** — Por qué la víctima no compensa: el motor deshace su transacción completa, así que
no dejó nada escrito. La superviviente sí confirmó, y por eso devuelve los dos pedidos a sus estados
fijos del corpus —`PED-00042` a `PAGADO` y `PED-99999` a `ANULADO`— inmediatamente después del
`COMMIT`. Y el aviso honesto que hay que dar: **cuál de las dos muere no se elige**, así que la
demostración se escribe de forma que la compensación la ponga la que haya sobrevivido. En PostgreSQL
el error tarda al menos un segundo, el `deadlock_timeout`.

---

**04 → 17.** Diagnostica: a las 3 de la mañana aparecen interbloqueos tres noches de cada diez,
siempre entre los mismos dos procesos. Da tres hipótesis en orden de probabilidad, la consulta con
la que mirarías la primera, y la corrección definitiva. 🔴

⏱️ **30 segundos** — Primera hipótesis: los dos procesos tocan las mismas filas en orden distinto.
Segunda: uno de los dos usa `FOR SHARE` y luego escribe. Tercera: en MySQL, bloqueos de hueco por un
`UPDATE` con rango que se cruzan aunque las filas no coincidan.

🗣️ **2 minutos** — El orden va de más probable a menos, y «tres noches de cada diez» apunta
clarísimo a la primera: el cruce siempre fue posible y solo hace falta que coincidan en el tiempo.
Se confirma leyendo las dos sentencias implicadas —que están en el log del servidor, no en el error
que recibe el cliente— y comparando por qué columna ordena cada proceso su recorrido. La segunda se
reconoce porque el ciclo aparece entre dos sesiones que hacen exactamente lo mismo.

🔬 **El detalle** — La consulta, mientras el incidente está vivo:

```sql
SELECT bloqueada.pid, bloqueada.query,
       pg_blocking_pids(bloqueada.pid) AS bloqueada_por
  FROM pg_stat_activity AS bloqueada
 WHERE cardinality(pg_blocking_pids(bloqueada.pid)) > 0;
```

Corrida con un `ALTER TABLE` esperando detrás de un informe —los `pid` cambian en cada corrida—:

```text
  pid  |                   query                    | bloqueada_por
-------+--------------------------------------------+---------------
 90532 | ALTER TABLE pedidos ADD COLUMN canal text; | {90522}
(1 fila)
```

La corrección definitiva no es un *timeout* ni un reintento: es **imponer un orden de acceso único**
—por ejemplo `ORDER BY id` en el `SELECT … FOR UPDATE` que toma los bloqueos, en las dos rutas— y
dejarlo escrito donde se lea. El reintento se queda como red de seguridad para lo que sobreviva, con
`40P01` y `40001` en su lista.

---

**04 → 18.** Diseña el acceso de dos procesos que tienen que actualizar los mismos pedidos y pagos,
de forma que el interbloqueo sea **imposible** y no solo improbable. Di qué regla impones y dónde se
escribe. 🔴

⏱️ **30 segundos** — Dos reglas: las tablas se tocan siempre en el mismo orden —primero `pedidos`,
después `pagos`— y dentro de cada tabla las filas se bloquean ordenadas por su clave primaria. Con
un orden total sobre los recursos, el ciclo no se puede formar.

🗣️ **2 minutos** — El razonamiento es el del grafo: un interbloqueo necesita un ciclo de esperas, y
un ciclo necesita que dos procesos recorran los recursos en direcciones opuestas. Si todos los
recorren en el mismo orden, el que llegue segundo espera al primero, el primero termina y el segundo
sigue: hay espera, que es inevitable, pero nunca ciclo. En la práctica se traduce en un `SELECT id
FROM pedidos WHERE … ORDER BY id FOR UPDATE` al principio de la transacción, que toma todos los
bloqueos de golpe y en orden conocido, y después ya se escribe sin sorpresas.

🔬 **El detalle** — Dónde se escribe, que es la mitad que se olvida: en un único sitio del código
—una función que sea la puerta de entrada a esas actualizaciones—, no en una convención de equipo
que se pierde en tres meses. La regla completa que conviene enunciar en voz alta: **orden fijo de
tablas, orden fijo de filas, y una sola función que tome los bloqueos**. Lo que queda después es
espera, que se acota con `lock_timeout`, y no interbloqueo.

---

**04 → 19.** Tienes que migrar `pedidos` en producción con tráfico. Escribe la secuencia de
sentencias que usarías, con sus parámetros de sesión, y di qué falla y qué no falla en cada paso si
no consigues el bloqueo. 🔴

⏱️ **30 segundos** — `SET lock_timeout` primero, el `ALTER` después, y cada paso en su propia
transacción corta. Si no consigo el bloqueo, falla la migración —que se reintenta— y no la
aplicación.

🗣️ **2 minutos** — La secuencia:

```sql
SET lock_timeout = '3s';
ALTER TABLE pedidos ADD COLUMN canal text;          -- solo catálogo: instantáneo si entra
CREATE INDEX CONCURRENTLY idx_pedidos_canal ON pedidos (canal);
```

Corrida sin nadie delante, entra entera; el teardown va pegado, porque el esquema del corpus no
lleva esa columna:

```text
tienda=# ALTER TABLE pedidos ADD COLUMN canal text;
ALTER TABLE
tienda=# CREATE INDEX CONCURRENTLY idx_pedidos_canal ON pedidos (canal);
CREATE INDEX
tienda=# DROP INDEX idx_pedidos_canal;
DROP INDEX
tienda=# ALTER TABLE pedidos DROP COLUMN canal;
ALTER TABLE
```

Paso a paso: el `ADD COLUMN` sin `DEFAULT` volátil solo toca el catálogo, así que el único riesgo es
conseguir el `ACCESS EXCLUSIVE`; con `lock_timeout` a tres segundos, si hay un informe delante la
sentencia falla con `55P03` y no se forma cola detrás. El `CREATE INDEX CONCURRENTLY` toma `SHARE
UPDATE EXCLUSIVE` en vez de `SHARE`, no bloquea escrituras, y a cambio tarda más y **no puede ir
dentro de una transacción**.

🔬 **El detalle** — Qué falla y qué no: si el `ALTER` no consigue el bloqueo, no pasa nada más que
volver a intentarlo cuando no haya informes —y ese es todo el objetivo—. Si el `CREATE INDEX
CONCURRENTLY` falla, **deja un índice inválido** que hay que borrar a mano antes de reintentar; se
localiza con `indisvalid = false` en `pg_index`. **Motor**, todo: en MySQL el equivalente es el DDL
en línea con `ALGORITHM=INPLACE, LOCK=NONE`, y el que bloquea ahí es el *metadata lock* de cualquier
transacción abierta.

---

## Capítulo 05 — Optimista, pesimista y transacciones largas

Las 17 preguntas de [`05`](05-optimista-pesimista-y-transacciones-largas.md).

**05 → 1.** ¿Qué es el control optimista y qué el pesimista, en una frase cada uno? 🟢

⏱️ **30 segundos** — El pesimista reserva la fila antes de leerla, con `FOR UPDATE`, y el que llega
después espera. El optimista no reserva nada y, al escribir, comprueba que lo leído no ha cambiado;
si cambió, la escritura no se aplica.

🗣️ **2 minutos** — La diferencia es **cuándo se detecta el conflicto** y quién lo paga. El pesimista
lo detecta antes y lo cobra en espera: una conexión ocupada sin hacer nada. El optimista lo detecta
después y lo cobra en reintentos: el perdedor tira su trabajo, relee y vuelve a decidir. De ahí sale
la regla de uso: pesimista si el conflicto es frecuente y la transacción corta, optimista si el
conflicto es raro o hay algo entre leer y escribir que no controlas.

🔬 **El detalle** — **Convención** para los dos nombres: son del oficio, no de la norma. El optimista
no es una función de ningún motor, es un `WHERE version = :leida` con un `version = version + 1` en
el `SET`; el pesimista sí descansa en algo de motor, el `FOR UPDATE` de
[`04`](04-bloqueos-e-interbloqueos.md) §3.

---

**05 → 2.** ¿Qué señal devuelve un `UPDATE` optimista que perdió la carrera, en PostgreSQL? 🟢

⏱️ **30 segundos** — `UPDATE 0`. No hay error: la sentencia termina bien y no toca ninguna fila,
porque la versión ya no es la que exigía el `WHERE`.

🗣️ **2 minutos** — Por eso el patrón depende entero de que la aplicación **mire el número de filas
afectadas**. Si no lo mira, el guardado «funciona», el usuario ve un mensaje de éxito y su cambio no
está en ninguna parte. En la sesión corrida del capítulo, el operador A recibe `UPDATE 0` cuando B
ya había llevado el pedido a la versión 1, y al releer ve `PENDIENTE`.

🔬 **El detalle** — **Motor.** En `REPEATABLE READ`, si la carrera es simultánea, la señal cambia: el
perdedor no recibe `UPDATE 0` sino el `40001` de [`02`](02-aislamiento-y-sus-fenomenos.md) §6,
porque la fila cambió desde su instantánea. Las dos significan lo mismo y el código tiene que tratar
las dos.

---

**05 → 3.** Nombra las tres guillotinas de PostgreSQL para transacciones y sentencias largas, y di
su valor por defecto. 🟢

⏱️ **30 segundos** — `statement_timeout`, `idle_in_transaction_session_timeout` y
`transaction_timeout`. Las tres valen 0 por defecto, que quiere decir desactivadas.

🗣️ **2 minutos** — La primera corta una sentencia que tarda demasiado y deja viva la conexión. La
segunda corta una transacción abierta que lleva demasiado tiempo sin hacer nada. La tercera corta
una transacción que dura demasiado **en total**, trabaje o no. Las dos últimas no abortan la
transacción: cierran la conexión con `FATAL`.

🔬 **El detalle** — **Motor.** `transaction_timeout` es de PostgreSQL 17, y la mayoría de artículos
que vas a encontrar no la conocen. Corrida en el entorno con `3s`, una transacción que duerme cinco
segundos muere con `FATAL: terminating connection due to transaction timeout`. En MySQL 9.7.2 no hay
equivalente de las dos últimas; MariaDB 12.3.3 tiene `idle_transaction_timeout`.

---

**05 → 4.** ¿Qué es `hot_standby_feedback` y cuál es su valor por defecto? 🟢

⏱️ **30 segundos** — Un parámetro de la réplica de PostgreSQL que le cuenta al primario qué
versiones de fila siguen necesitando sus consultas. Por defecto está en `off`.

🗣️ **2 minutos** — Sirve para que el `VACUUM` del primario no borre lo que un informe de la réplica
todavía lee, y así la réplica no tenga que cancelar ese informe. El precio es que el horizonte de la
réplica pasa a frenar la limpieza del primario: la tabla de producción se hincha por una consulta
que corre en otra máquina.

🔬 **El detalle** — **Motor**, y comprobado en el servidor del corpus con `pg_settings`. El entorno
no tiene réplica, así que el efecto no se observa aquí; se vería con `pg_stat_database_conflicts` en
la réplica y con el `n_dead_tup` del primario subiendo mientras el informe corre.

---

**05 → 5.** ¿Existe el «bloqueo optimista» en el estándar o en algún motor del corpus como función
propia? 🟡

⏱️ **30 segundos** — No. Ni la norma ni PostgreSQL, MySQL o SQLite tienen una función de «bloqueo
optimista»: es un patrón construido con un `UPDATE` corriente y una condición en el `WHERE`.

🗣️ **2 minutos** — Lo que sí es de motor es el comportamiento que hace correcto el patrón: que un
`UPDATE` que espera al bloqueo de fila vuelva a evaluar su `WHERE` al despertar, y que devuelva
cuántas filas tocó. Los tres motores lo hacen, y en las dos cosas hay matices: MySQL devuelve filas
cambiadas y no encontradas, y PostgreSQL ofrece una versión de fila gratis, `xmin`.

🔬 **El detalle** — **Convención** para el nombre, que además engaña: el optimista **no bloquea nada
entre la lectura y la escritura**, pero su `UPDATE` toma el bloqueo de fila como cualquier otro, y
es esa espera la que resuelve la carrera del mismo milisegundo. Los marcos de persistencia lo
empaquetan con una anotación; por debajo es siempre este `WHERE`.

---

**05 → 6.** Diferencia `statement_timeout` de `idle_in_transaction_session_timeout`: qué corta cada
uno y qué mata. 🟡

⏱️ **30 segundos** — `statement_timeout` corta una sentencia que está trabajando demasiado y mata
solo la sentencia, con `ERROR`. `idle_in_transaction_session_timeout` corta una transacción que no
está haciendo nada y mata la conexión, con `FATAL`.

🗣️ **2 minutos** — Protegen de cosas opuestas. El primero, de la consulta que se come la CPU; el
segundo, de la transacción olvidada que retiene bloqueos y el horizonte sin gastar nada. Una
transacción puede ser larguísima sin que salte ninguno de los dos: muchas sentencias rápidas
seguidas, sin pausas, no disparan ni uno ni otro. Para ese caso está `transaction_timeout`.

🔬 **El detalle** — **Motor**, y corrido en el capítulo: A abre, hace `FOR UPDATE`, se queda ociosa,
y a los diez segundos su siguiente sentencia recibe `FATAL: terminating connection due to
idle-in-transaction timeout`. `psql` se reconecta solo; un *pool* no necesariamente.

---

**05 → 7.** ¿Por qué `FOR UPDATE` no sirve para proteger un formulario que el usuario tarda tres
minutos en guardar? 🟡

⏱️ **30 segundos** — Porque el bloqueo dura lo que dura la transacción, la transacción vive en una
conexión, y entre abrir el formulario y guardarlo hay dos peticiones HTTP que usan conexiones
distintas del *pool*.

🗣️ **2 minutos** — Para que funcionara habría que mantener la transacción abierta tres minutos,
atada a una conexión reservada para ese usuario. Eso es la transacción larga de §5 con todas sus
facturas: la fila bloqueada para los demás, el horizonte congelado, una conexión menos en el *pool*,
y si el usuario cierra la pestaña, una transacción huérfana hasta que algo la corte. El optimista
resuelve el mismo problema sin retener nada: la versión viaja con el formulario.

🔬 **El detalle** — **Motor** para el ámbito: la transacción es de la conexión en los tres motores
([`01`](01-acid-con-precision.md) §7). Es la razón de que el pesimista sea la herramienta de lo que
cabe entero dentro del servidor y el optimista la de lo que cruza una frontera de red.

---

**05 → 8.** En MySQL, un `UPDATE` que escribe el mismo valor que ya había devuelve 0. ¿Qué categoría
es esa diferencia con PostgreSQL y qué rompe en un control optimista? 🟡

⏱️ **30 segundos** — Es de **motor**: MySQL cuenta filas cambiadas y PostgreSQL filas encontradas.
En un control optimista que no cambie la versión, «0 filas» deja de significar «perdí la carrera».

🗣️ **2 minutos** — Corrido: `UPDATE pedidos SET estado = 'ANULADO' WHERE codigo = 'PED-99999'` con
el pedido ya anulado responde `Query OK, 0 rows affected` y `Rows matched: 1 Changed: 0`. PostgreSQL
responde `UPDATE 1` y SQLite da 1 en `changes()`. Si el código comprueba «si no tocó ninguna fila,
alguien se me adelantó», en MySQL confunde un guardado sin cambios con un conflicto.

🔬 **El detalle** — Dos defensas: que la versión **cambie siempre** —`version = version + 1` nunca
coincide con el valor anterior, así que la fila siempre cuenta como cambiada—, o pedir al protocolo
filas encontradas con la bandera `CLIENT_FOUND_ROWS`. Lo que haga tu conector por defecto hay que
comprobarlo, no suponerlo.

---

**05 → 9.** Compara un entero, una marca de tiempo y `xmin` como ficha de versión: cuándo sirve cada
uno. 🟡

⏱️ **30 segundos** — El entero sirve siempre que puedas añadir la columna. La marca de tiempo, solo
si las escrituras están espaciadas y hay un solo reloj. `xmin`, si no puedes tocar el esquema y no
piensas salir de PostgreSQL.

🗣️ **2 minutos** — La marca de tiempo falla con dos escrituras en el mismo milisegundo, que
comparten valor y no se distinguen, y con relojes de dos servidores que no coinciden. `xmin` es la
columna de sistema con el identificador de la transacción que escribió esa versión: cambia sola con
cada `UPDATE`, sin columna nueva, pero cambia también con escrituras que a ti no te importan y no
existe fuera de PostgreSQL.

🔬 **El detalle** — **Motor** para `xmin`, que el capítulo `03` usa para enseñar MVCC por dentro;
**convención** para el entero y la marca de tiempo. Añadir el entero costó 8,285 ms sobre el millón
de pedidos, porque con un `DEFAULT` constante PostgreSQL no reescribe la tabla: el precio real es de
4 bytes por fila y un incremento por escritura.

---

**05 → 10.** Dos sesiones lanzan el mismo `UPDATE … WHERE version = 1` en el mismo milisegundo, en
`READ COMMITTED`. Explica paso a paso qué hace el motor y por qué solo una gana. 🟠

⏱️ **30 segundos** — La primera que llega toma el bloqueo de fila y escribe. La segunda se queda
esperando ese bloqueo; cuando la primera confirma, la segunda vuelve a evaluar su `WHERE` contra la
versión confirmada, ve `version = 2`, y responde `UPDATE 0`.

🗣️ **2 minutos** — La clave es que la comprobación y la escritura van **en una sola sentencia**. Si
la aplicación leyera la versión en un `SELECT` y luego escribiera sin condición, las dos pasarían la
comprobación y la segunda pisaría. Con la condición dentro del `UPDATE`, el motor garantiza que
nadie escribe la fila mientras otro la tiene, y que quien esperaba decide con el dato nuevo. Corrido
en el capítulo: B espera a A, A confirma, B da `UPDATE 0` y al releer ve `ANULADO` en versión 2.

🔬 **El detalle** — **Motor.** PostgreSQL reevalúa la condición sobre la versión más reciente de la
fila; InnoDB, lo mismo, y medido: B esperó 2,826 s y respondió `0 rows affected`. En `REPEATABLE
READ` de PostgreSQL la segunda no daría `UPDATE 0` sino `40001`, porque la fila cambió desde su
instantánea.

---

**05 → 11.** Diez procesos compiten por la misma fila con control optimista. Haz la cuenta de
intentos y di a partir de qué punto cambiarías de estrategia. 🟠

⏱️ **30 segundos** — En cada ronda gana uno y repiten los demás: 10 + 9 + … + 1 son 55 intentos para
10 escrituras, más de cinco por escritura útil. Cambiaría a pesimista en cuanto los reintentos dejen
de ser la excepción.

🗣️ **2 minutos** — El coste crece con el cuadrado de los competidores: con N procesos son N·(N+1)/2
intentos. Cada intento perdido es una lectura, un cálculo y un `UPDATE 0` tirados, y si el cálculo
incluye algo caro, lo haces cinco veces. El pesimista hace esperar a los diez en fila, pero cada uno
escribe a la primera. El punto de cambio no es un número fijo: se mide la tasa de `UPDATE 0` y,
cuando es una fracción apreciable de los guardados, el optimista ha dejado de ser barato.

🔬 **El detalle** — Y antes de las dos, la pregunta de §4: si el cálculo cabe en el `UPDATE` —un
contador, un saldo que se descuenta—, `SET x = x - 1 WHERE x > 0` no necesita ni versión ni bloqueo
explícito y no tiene reintentos. **Convención** falsa que desmonta esta cuenta: «el optimista es más
rápido».

---

**05 → 12.** Una transacción en `READ COMMITTED` hizo un `FOR UPDATE` y lleva diez minutos ociosa,
con `backend_xmin` vacío. ¿Frena el `VACUUM`? Explica por qué. 🟠

⏱️ **30 segundos** — Sí. No tiene instantánea, porque en `READ COMMITTED` se suelta al terminar cada
sentencia, pero tiene **identificador de transacción** en curso, y eso fija el horizonte igual.

🗣️ **2 minutos** — `FOR UPDATE` obliga a pedir un identificador, porque marca la fila con él. El
motor no puede dar por muerta ninguna versión que una transacción en curso pudiera tener que ver o
que dependa de su resultado, y el cálculo del horizonte tiene en cuenta tanto las instantáneas de
cada sesión como los identificadores de las transacciones abiertas. En la sesión corrida,
`pg_stat_activity` enseñaba `backend_xid` 1052 con `backend_xmin` vacío.

🔬 **El detalle** — **Motor.** Por eso la consulta de diagnóstico de transacciones largas tiene que
mirar las dos columnas, o filtrar por `xact_start`, y no solo por `backend_xmin`. Además de frenar
el `VACUUM`, esa transacción retiene el bloqueo de fila: cualquier escritura sobre ese pedido
espera, para siempre si no hay `lock_timeout`.

---

**05 → 13.** Tu *pool* empieza a devolver conexiones que fallan en la primera consulta desde que
activaste `idle_in_transaction_session_timeout`. Explica el mecanismo y qué le pedirías al *pool*. 🟠

⏱️ **30 segundos** — El parámetro no aborta la transacción: cierra la conexión. El *pool* no se
entera, la guarda como buena, y la siguiente petición que la toma falla al primer uso.

🗣️ **2 minutos** — Al *pool* le pediría dos cosas. Que **valide la conexión al prestarla** —o
detecte el cierre por el propio fallo y reintente con otra—, y sobre todo que **nunca devuelva una
conexión con una transacción abierta**, que es la causa de que el parámetro salte. El síntoma bueno
es que los fallos desaparezcan porque ya no quedan transacciones ociosas, no porque el *pool* las
esconda.

🔬 **El detalle** — **Motor**, y corrido: la sentencia siguiente de la sesión cortada recibe `FATAL:
terminating connection due to idle-in-transaction timeout` y `el servidor ha cerrado la conexión
inesperadamente`. Los fallos que aparecen son la evidencia de un error de código que antes no se
veía: alguien olvidaba un `COMMIT` o un `ROLLBACK` en un camino de error.

---

**05 → 14.** Un informe de dos horas en una réplica de PostgreSQL se cancela todas las noches. Da
las dos salidas de configuración y el precio de cada una. 🟠

⏱️ **30 segundos** — Subir `max_standby_streaming_delay`, que por defecto es 30 s, para que la
réplica espere al informe; o activar `hot_standby_feedback`, para que el primario no borre lo que el
informe necesita. La primera retrasa la réplica; la segunda hincha el primario.

🗣️ **2 minutos** — El informe se cancela porque la réplica tiene que aplicar una limpieza del
primario que borra versiones que el informe todavía lee. Con más espera, la réplica deja de aplicar
cambios mientras el informe corre, y cualquiera que lea de ella ve datos de hace horas. Con
*feedback*, la réplica no se retrasa, pero el horizonte del informe frena el `VACUUM` del primario
dos horas cada noche.

🔬 **El detalle** — **Motor.** La tercera salida no es de configuración y suele ser la buena: una
réplica dedicada a informes, con su propia espera larga, separada de la que sirve lecturas de la
aplicación. El entorno del corpus no tiene réplica: el mecanismo se explica, no se observa.

---

**05 → 15.** Escribe la secuencia completa —sentencias y comprobaciones— de un guardado optimista de
un formulario sobre `pedidos`, desde que se abre la pantalla hasta que se confirma o se rechaza. 🔴

⏱️ **30 segundos** — Al abrir, leer el pedido con su versión y mandar la versión al formulario. Al
guardar, un `UPDATE` que incrementa la versión y exige la leída en el `WHERE`. Si toca una fila,
éxito; si toca cero, conflicto: releer y enseñárselo al usuario.

🗣️ **2 minutos** — La secuencia, con el esquema del capítulo:

```sql
-- 1. Petición de apertura: sin transacción explícita.
SELECT codigo, estado, version FROM pedidos WHERE codigo = 'PED-99999';
-- la versión viaja al formulario, por ejemplo en un campo oculto o un ETag

-- 2. Petición de guardado.
UPDATE pedidos
   SET estado = 'PAGADO', version = version + 1, actualizado_en = now()
 WHERE codigo = 'PED-99999'
   AND version = 0;                   -- la que llegó con el formulario
-- 3. La aplicación comprueba las filas afectadas:
--    1 -> confirmado, se devuelve la versión nueva
--    0 -> conflicto: se relee y se enseña el dato nuevo al usuario
```

Las dos peticiones usan conexiones distintas del *pool* y ninguna deja transacción abierta.

🔬 **El detalle** — Tres comprobaciones que suben la nota: que el `0` se distingue de un pedido que
ya no existe —el `SELECT` de la relectura lo dice—; que en MySQL la versión cambia siempre, para que
el recuento de filas cambiadas no mienta; y que si el guardado toca varias tablas, el `UPDATE`
versionado va primero dentro de la transacción corta, para que el conflicto aborte antes de escribir
nada más.

---

**05 → 16.** Diagnostica: la tabla `pedidos` del primario crece un 5 % al día y en el primario no
hay ninguna transacción larga. Da tres hipótesis en orden de probabilidad y la consulta con la que
comprobarías la primera. 🔴

⏱️ **30 segundos** — Primera, una réplica con `hot_standby_feedback` activado y un informe largo que
frena el `VACUUM` del primario desde otra máquina. Segunda, una ranura de replicación abandonada.
Tercera, un autovacuum que no da abasto con la tasa de escritura de esa tabla.

🗣️ **2 minutos** — La primera se comprueba en el primario, mirando el horizonte que declara cada
réplica:

```sql
SELECT application_name, backend_xmin, age(backend_xmin) AS antiguedad
  FROM pg_stat_replication
 ORDER BY age(backend_xmin) DESC NULLS LAST;
```

Si una réplica declara un `backend_xmin` de hace horas, ella fija el horizonte. La segunda se mira
en `pg_replication_slots`, con su `xmin` y si está activa. La tercera, en `pg_stat_user_tables`:
`n_dead_tup` alto y `last_autovacuum` antiguo sin que nada lo retenga.

🔬 **El detalle** — **Motor**, y fuera de lo que el entorno del corpus puede reproducir: las dos
consultas corren contra él y devuelven `(0 filas)`, porque no hay réplica ni ranura. Lo que se
evalúa es el reflejo de §6: cuando el primario está limpio, **el horizonte puede venir de otra
máquina**.

---

**05 → 17.** Un lote nocturno actualiza 270 000 pedidos en una sola transacción de cuarenta minutos.
Rediseña su forma de confirmar, di qué propiedad tiene que cumplir para poder reanudarse, y qué
ganas en cada una de las facturas del §5. 🔴

⏱️ **30 segundos** — Tramos de unos pocos miles de filas, cada uno en su transacción, recorridos por
clave. La propiedad: que cada tramo sea **idempotente y deje marca de hasta dónde llegó**, de modo
que repetirlo no haga daño y el lote sepa dónde seguir.

🗣️ **2 minutos** — La forma habitual es seleccionar el tramo por una condición que deje de cumplirse
al procesarlo —`WHERE estado = 'PAGADO' … LIMIT 5000`, pasando a `ENVIADO`—, o recorrer por `id` y
guardar el último procesado. Lo que se gana en cada factura: el horizonte avanza cada pocos segundos
y el `VACUUM` recicla lo de los tramos anteriores; los bloqueos de fila se sueltan al final de cada
tramo y no durante cuarenta minutos; y en InnoDB la cadena de *undo* nunca pasa del tamaño de un
tramo, así que un fallo deshace segundos, no cuarenta minutos.

🔬 **El detalle** — Lo que se pierde, y conviene decirlo: la atomicidad del lote entero. Si falla a
mitad, la mitad está confirmada; por eso la propiedad de reanudación no es opcional. El `fsync` por
confirmación también sube, pero con tramos de miles de filas son decenas de confirmaciones por
minuto, que no se notan. **Convención** que esto desmonta: «un lote debe ser una transacción para
ser seguro».

---

## Capítulo 06 — WAL, durabilidad y `fsync`

Las 18 preguntas de [`06`](06-wal-durabilidad-y-fsync.md).

**06 → 1.** ¿Qué dice la regla del registro anticipado, en una frase, y quién la fija: el estándar o
el motor? 🟢

⏱️ **30 segundos** — Ningún cambio llega a la página de la tabla en disco antes de que su
descripción haya llegado al registro en disco. La fija el motor: el estándar exige que lo confirmado
persista y no dice cómo.

🗣️ **2 minutos** — La regla es lo que permite que el `COMMIT` sea barato: en vez de escribir las
páginas de la tabla dispersas por el fichero, el motor escribe una descripción secuencial al final
del registro, espera a que esté en disco y responde. Las páginas se escriben después, agrupadas, y
si el servidor cae antes, se reconstruyen leyendo el registro.

🔬 **El detalle** — **Motor.** Los tres motores del corpus la aplican con nombres distintos: WAL en
PostgreSQL, *redo log* en InnoDB, y en SQLite el diario de reversión por defecto —comprobado:
`journal_mode` vale `delete` en `tienda.db`— o un WAL propio si se pide. La norma no nombra ninguno.

---

**06 → 2.** ¿Qué es un LSN y qué dos posiciones distingue PostgreSQL? 🟢

⏱️ **30 segundos** — Un LSN es una dirección dentro del registro, como `2/1ED05288`. PostgreSQL
distingue hasta dónde ha **anotado** en memoria, `pg_current_wal_insert_lsn()`, y hasta dónde está
**en disco**, `pg_current_wal_flush_lsn()`.

🗣️ **2 minutos** — La distancia entre las dos es lo que se perdería si el servidor cayera en ese
instante. En la sesión corrida del capítulo, con un `UPDATE` sin confirmar, la anotada iba por
`2/1ED052F8` y la volcada seguía en `2/1ED05288`; tras el `COMMIT`, las dos valían `2/1ED05320`.

🔬 **El detalle** — **Motor.** Restando dos LSN se obtienen bytes de registro: el `UPDATE` ocupó 112
y el `COMMIT` 40, contando el relleno hasta múltiplo de 8. `pg_walfile_name()` traduce un LSN al
fichero de segmento donde vive, que es lo que necesita `pg_waldump`.

---

**06 → 3.** ¿Qué es un punto de control y cada cuánto lo lanza PostgreSQL por defecto? 🟢

⏱️ **30 segundos** — Es el momento en que el motor escribe en la tabla todas las páginas modificadas
y anota que el registro anterior ya no hace falta para recuperar. Por defecto, cada 5 minutos o al
acumular 1 GB de WAL, lo que llegue antes.

🗣️ **2 minutos** — Los dos parámetros son `checkpoint_timeout` y `max_wal_size`. El punto de control
fija desde dónde empieza la recuperación tras una caída: cuanto más lejos quede, más registro hay
que rehacer. Y no se hace de golpe: `checkpoint_completion_target`, que vale 0.9, reparte la
escritura a lo largo del intervalo para no saturar el disco.

🔬 **El detalle** — **Motor**, con los valores leídos en el entorno. La recuperación corrida en el
capítulo empezó en el último punto de control y rehízo 150 MB —`distance=153841 kB`— en 0,54 s.

---

**06 → 4.** ¿Qué es una página rota y qué parámetro de PostgreSQL la previene? 🟢

⏱️ **30 segundos** — Una página de 8 kB que quedó escrita a medias porque el corte llegó entre dos
trozos: media nueva y media vieja. La previene `full_page_writes`, que está en `on`.

🗣️ **2 minutos** — El sistema de ficheros puede escribir la página en bloques de 4 kB, así que un
corte en medio deja una página que ningún registro del WAL sabe arreglar, porque todos describen
cambios sobre una página sana. Con `full_page_writes`, la primera modificación de cada página tras
un punto de control guarda **la página entera** en el WAL, y la recuperación parte de esa copia.

🔬 **El detalle** — **Motor.** El precio se midió: un `VACUUM` de `pedidos` escribió `18049 full page
images` y 135 MB de WAL. Apagarlo ahorra escritura y cambia ese coste por una corrupción que no se
ve hasta el día del corte.

---

**06 → 5.** ¿Cuánto vale por defecto `innodb_flush_log_at_trx_commit` y qué significa ese valor? 🟢

⏱️ **30 segundos** — Vale `1`: en cada `COMMIT`, InnoDB escribe su *redo log* y lo vuelca al disco
antes de responder. Es el equivalente del `synchronous_commit = on` de PostgreSQL.

🗣️ **2 minutos** — Los otros dos valores relajan la durabilidad. Con `2`, escribe el registro en
cada confirmación pero solo lo vuelca una vez por segundo: se pierde lo del último segundo si cae el
sistema operativo. Con `0`, ni siquiera escribe en cada confirmación: se pierde también si cae solo
el proceso.

🔬 **El detalle** — **Motor**, leído en MySQL 9.7.2 y MariaDB 12.3.3, las dos en `1`. El `0` se
corrió: con el contenedor muerto con `SIGKILL` justo después del `UPDATE`, el cambio se perdió en 2
de 3 intentos; con `1`, en ninguno de 2. En MySQL el *binlog* tiene su propia palanca,
`sync_binlog`, que vale 1; en MariaDB vale 0 y el *binlog* viene apagado.

---

**06 → 6.** Distingue `synchronous_commit = off` de `fsync = off`: qué pierde cada uno. 🟡

⏱️ **30 segundos** — `synchronous_commit = off` pierde las últimas transacciones confirmadas,
enteras, y deja la base coherente. `fsync = off` puede dejar la base **corrupta**, porque ya nada
garantiza que el registro llegue a disco antes que las páginas.

🗣️ **2 minutos** — El primero solo cambia **cuándo responde** el `COMMIT`: el registro sigue
escribiéndose en orden y volcándose, unos cientos de milisegundos más tarde. El segundo le quita al
motor la herramienta con la que cumple la regla del registro anticipado: tras un corte puede haber
páginas escritas cuyo registro nunca llegó, y la recuperación no tiene cómo saberlo.

🔬 **El detalle** — **Motor.** El primero es una decisión razonable por transacción; el segundo solo
tiene sentido en una base desechable, como una carga inicial que se repetiría desde cero si falla.
Corrido en el capítulo: con `off`, 8 pérdidas en 12 caídas provocadas y ninguna corrupción.

---

**06 → 7.** ¿Está el WAL en el estándar SQL? Responde para la norma y para los tres motores del
corpus. 🟡

⏱️ **30 segundos** — No. La norma exige durabilidad y no dice cómo conseguirla. Los tres motores
usan un registro anticipado, cada uno el suyo.

🗣️ **2 minutos** — PostgreSQL tiene el WAL, que además es su mecanismo de replicación y de
recuperación a un punto en el tiempo. InnoDB tiene el *redo log* para recuperarse y, aparte, el
*binlog* para replicar. SQLite, por defecto, un diario de reversión que guarda las páginas **antes**
de cambiarlas, y opcionalmente un WAL que guarda las páginas **nuevas**.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas: lo que se afirma de la
norma es que no define mecanismos de almacenamiento, en coherencia con que tampoco define índices ni
planes. **Motor** todo lo demás, con `journal_mode = delete` leído en la base SQLite del corpus.

---

**06 → 8.** Diferencia la defensa de PostgreSQL contra la página rota de la de InnoDB. 🟡

⏱️ **30 segundos** — PostgreSQL guarda la página entera **en el WAL** la primera vez que la modifica
tras un punto de control. InnoDB escribe cada página **dos veces** al volcarla: primero en una zona
aparte, el *doublewrite buffer*, y luego en su sitio.

🗣️ **2 minutos** — Las dos resuelven lo mismo —tener una copia sana de la página para cuando la de
su sitio quede a medias— y lo pagan en sitios distintos. PostgreSQL lo paga en volumen de WAL, más
alto justo después de cada punto de control. InnoDB lo paga en escritura de páginas, cada vez que
las vuelca, pero no engorda su *redo log*.

🔬 **El detalle** — **Motor.** `full_page_writes = on` en PostgreSQL 18.6 e `innodb_doublewrite = ON`
en MySQL 9.7.2 y MariaDB 12.3.3, leídos en el entorno. Los dos se pueden apagar si el sistema de
ficheros o el disco garantizan escrituras atómicas de página, y esa garantía hay que tenerla por
escrito, no suponerla.

---

**06 → 9.** ¿Qué diferencia hay entre `remote_write`, `on` y `remote_apply` cuando hay réplica
síncrona? 🟡

⏱️ **30 segundos** — Hasta dónde espera el `COMMIT` en la réplica. Con `remote_write`, a que la haya
recibido y entregado a su sistema operativo; con `on`, a que esté en su disco; con `remote_apply`, a
que la haya aplicado y sea visible en sus lecturas.

🗣️ **2 minutos** — Cada nivel cierra un hueco y añade espera. `remote_write` sobrevive a la caída
del primario pero no a un corte simultáneo de los dos. `on` sobrevive a los dos. `remote_apply`
añade lo que ninguno de los anteriores da: que una lectura en la réplica justo después del `COMMIT`
vea el dato.

🔬 **El detalle** — **Motor**, y de la documentación: el entorno no tiene réplica. Sin
`synchronous_standby_names`, los cuatro valores con réplica —`local`, `remote_write`, `on`,
`remote_apply`— se comportan igual que `local`, que es el caso por defecto y es replicación
asíncrona.

---

**06 → 10.** Explica qué hace PostgreSQL al arrancar después de una caída, y de qué depende cuánto
tarda. 🟠

⏱️ **30 segundos** — Detecta que no se apagó bien, busca el último punto de control, y vuelve a
aplicar el registro desde ahí hasta el final. Tarda lo que tarde en leer y aplicar ese tramo, que
depende de cuánto WAL se escribió desde el último punto de control.

🗣️ **2 minutos** — Corrido en el capítulo matando el contenedor justo después de un `COMMIT`: el log
dice `database system was not properly shut down; automatic recovery in progress`, `redo starts at
2/16AE2F48`, `redo done at 2/2011F408` en 0,54 s, y un punto de control de fin de recuperación. El
cambio confirmado estaba al arrancar, aunque su página nunca se escribió antes de morir.

🔬 **El detalle** — **Motor.** El tramo fue de 150 MB porque incluía un `VACUUM` con muchas páginas
enteras. Lo que acota el tiempo son `checkpoint_timeout` y `max_wal_size`: con los de fábrica, en el
peor caso se rehacen cinco minutos o 1 GB de registro. `invalid record length … got 0` en ese log no
es un error: marca el final del registro.

---

**06 → 11.** Con `synchronous_commit = off`, ¿cuánto puedes perder y qué nunca pierdes? Da el número
y su origen. 🟠

⏱️ **30 segundos** — Puedes perder las transacciones confirmadas en los últimos **600 ms** como
mucho, que son tres veces `wal_writer_delay`, 200 ms. Nunca pierdes la coherencia: lo que se pierde
son transacciones enteras, no medias.

🗣️ **2 minutos** — El *WAL writer* vuelca cada 200 ms lo que los `COMMIT` asíncronos dejaron
anotado, y la documentación fija la ventana máxima en tres ciclos porque en momentos de carga
prefiere escribir páginas enteras. Y se pierde **también si solo cae el proceso**, no solo con un
corte: los búferes de WAL viven en memoria compartida, y un reinicio por caída los descarta.

🔬 **El detalle** — **Motor**, y provocado en el capítulo: `psql` respondió `UPDATE 1`, un proceso
del servidor se mató en la sentencia siguiente, y tras la recuperación el pedido seguía en
`ANULADO`. En 12 caídas con `off` se perdió en 8; con `on`, en 0 de 8. La proporción no es un dato
del motor: depende de cuándo caiga el golpe dentro de la ventana.

---

**06 → 12.** `pg_test_fsync` da 9 000 volcados por segundo en tu servidor. ¿Es buena noticia?
Explica qué puede significar y cómo lo comprobarías. 🟠

⏱️ **30 segundos** — Depende. Son unos 110 µs por volcado, y eso solo es posible si responde una
caché: si está protegida ante cortes, es buena noticia; si es volátil, tus `COMMIT` pueden
desaparecer en un corte aunque todo esté bien configurado.

🗣️ **2 minutos** — `pg_test_fsync` mide velocidad, no verdad. Un disco sin caché protegida tarda del
orden de milisegundos en un volcado real. Lo primero es preguntar qué hardware hay: controladora con
batería, SSD con protección ante cortes, o un disco de consumo. Y la única comprobación de verdad es
cortar la corriente en plena carga y verificar que todo lo confirmado sigue ahí, que es lo que hace
`diskchecker.pl`, al que remite la documentación de PostgreSQL.

🔬 **El detalle** — El entorno del corpus da exactamente ese número: `fdatasync` a 9 345,888
operaciones por segundo, 107 µs, sobre un contenedor en un portátil con una virtualización cuya
garantía no he verificado. **Ni estándar ni motor**: es del sistema operativo y del hardware, y la
documentación del motor advierte que muchos SSD no respetan las órdenes de vaciado por defecto.

---

**06 → 13.** ¿Por qué el `VACUUM` de una tabla grande puede generar más WAL que los datos que
limpia? 🟠

⏱️ **30 segundos** — Porque la primera vez que toca cada página después de un punto de control, el
WAL guarda la página entera, 8 kB, aunque el cambio sea de unos bytes. Un `VACUUM` que recorre miles
de páginas escribe miles de páginas enteras.

🗣️ **2 minutos** — Medido en esta tanda: un `VACUUM` de `pedidos` escribió `19806 records, 18049
full page images, 135941599 bytes`. Retiró unas 79 000 versiones muertas y marcó miles de páginas
como visibles o congeladas; cada marca es un cambio pequeño, pero sobre una página que no se había
tocado desde el último punto de control, así que va con su copia entera.

🔬 **El detalle** — **Motor**, por `full_page_writes`. Por eso un `VACUUM` grande se nota en la
réplica, en el archivado de WAL y en la siguiente recuperación: los 150 MB rehechos al matar el
servidor en el capítulo eran, en su mayor parte, ese `VACUUM`.

---

**06 → 14.** Un lote de eventos de navegación y los pagos viven en la misma base. Propón cómo
relajar la durabilidad de uno sin tocar la del otro, con la sentencia exacta. 🟠

⏱️ **30 segundos** — Con `synchronous_commit` por transacción: las transacciones del lote de eventos
hacen `SET LOCAL synchronous_commit = off` al empezar, y las de pagos no tocan nada.

🗣️ **2 minutos** — Corrido:

```text
tienda=# BEGIN;
BEGIN
tienda=*# SET LOCAL synchronous_commit = off;
SET
tienda=*# SHOW synchronous_commit;
 synchronous_commit
--------------------
 off
(1 fila)

tienda=*# COMMIT;
COMMIT
tienda=# SHOW synchronous_commit;
 synchronous_commit
--------------------
 on
(1 fila)
```

`SET LOCAL` dura hasta el final de la transacción, así que no contamina la conexión cuando vuelve al
*pool*. Si el lote usa su propio rol, también se puede fijar para ese rol entero, con `ALTER ROLE …
SET synchronous_commit = off`, y ningún código tiene que acordarse.

🔬 **El detalle** — **Motor.** Lo que se pierde: como mucho 600 ms de eventos confirmados en una
caída, enteros, nunca a medias. Lo que no se pierde: nada de `pagos`, que sigue esperando al disco
en cada `COMMIT`. En MySQL `innodb_flush_log_at_trx_commit` es global, no por transacción, y esta
separación no se puede hacer igual.

---

**06 → 15.** En MySQL, ¿qué diferencia hay entre perder el proceso y perder el sistema operativo con
`innodb_flush_log_at_trx_commit = 2`? 🟠

⏱️ **30 segundos** — Con `2`, cada `COMMIT` escribe el registro en el sistema operativo, pero solo
se vuelca a disco una vez por segundo. Si cae solo el proceso, no se pierde nada: el sistema
operativo lo tiene. Si cae el sistema operativo o la luz, se pierde hasta un segundo.

🗣️ **2 minutos** — Es la diferencia entre «entregado al núcleo» y «en disco». El proceso puede morir
y el núcleo seguirá escribiendo lo que se le entregó; un corte se lleva la caché del núcleo con él.
Con `0` ni siquiera se entrega en cada `COMMIT`, y por eso pierde también con la caída del proceso.

🔬 **El detalle** — **Motor**, de la documentación de MySQL 9.7, que además advierte que el volcado
por segundo **no está garantizado al 100 %**. Del corpus, lo corrido es la mitad comprobable: con
`0` y el contenedor muerto con `SIGKILL`, el cambio se perdió en 2 de 3 intentos. El caso del `2`
pide que caiga el sistema operativo, y el entorno no lo produce.

---

**06 → 16.** Escribe la secuencia de sentencias que demuestra, desde `psql`, que un `COMMIT` es lo
que vuelca el registro a disco, y di qué dos números comparas. 🔴

⏱️ **30 segundos** — Abro una transacción, hago un `UPDATE`, comparo la posición anotada con la
volcada, confirmo, y las comparo otra vez. Antes del `COMMIT` la volcada va por detrás; después,
coinciden.

🗣️ **2 minutos** — La secuencia, con su compensación:

```sql
BEGIN;
UPDATE pedidos SET estado = 'PENDIENTE' WHERE codigo = 'PED-99999';
SELECT pg_current_wal_insert_lsn() AS insertado, pg_current_wal_flush_lsn() AS en_disco;
COMMIT;
SELECT pg_current_wal_insert_lsn() AS insertado, pg_current_wal_flush_lsn() AS en_disco;
UPDATE pedidos SET estado = 'ANULADO' WHERE codigo = 'PED-99999';   -- compensación
```

Corrida en el capítulo: antes del `COMMIT`, `2/1ED052F8` anotado contra `2/1ED05288` volcado;
después, `2/1ED05320` y `2/1ED05320`.

🔬 **El detalle** — Dos trampas que conviene nombrar. Las consultas tienen que ir **seguidas**: el
*WAL writer* vuelca en segundo plano cada 200 ms y, si esperas, la posición volcada puede alcanzar a
la anotada sin que nadie confirme. Y la prueba dice que el registro está volcado, no que el disco lo
tenga de verdad: eso es §6, y ninguna consulta lo demuestra.

---

**06 → 17.** Diagnostica: tras un corte de corriente falta un pago que el cliente vio confirmado. Da
tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

⏱️ **30 segundos** — Primera, que esa transacción corriera con la durabilidad relajada. Segunda, que
el disco o la controladora tuvieran una caché volátil que mintió al volcar. Tercera, que el
«confirmado» que vio el cliente no fuera el `COMMIT` de la base.

🗣️ **2 minutos** — Para la primera: `synchronous_commit` en el servidor, en el rol de la aplicación
—`ALTER ROLE … SET` deja rastro en `pg_db_role_setting`— y en el código, buscando `SET LOCAL`. Para
la segunda: el hardware, la configuración de caché de la controladora, y si existe, una prueba de
corte. Para la tercera: el camino del código, porque es frecuente que el servicio responda «pagado»
antes de confirmar, o que confirme en una réplica o en una cola y no en la base.

🔬 **El detalle** — La tercera suele ser la más barata de descartar y la primera que conviene mirar
en el código: una respuesta HTTP enviada antes del `COMMIT` pierde el pago con cualquier
configuración. Y si la base tenía réplica asíncrona y se promovió tras el corte, hay una cuarta: el
pago estaba en el primario muerto y no llegó a la réplica promovida.

---

**06 → 18.** Te piden que el servidor vuelva en menos de un minuto tras una caída, y hoy tarda
cinco. Di qué parámetros tocarías, en qué dirección, y qué pagas a cambio. 🔴

⏱️ **30 segundos** — Bajaría `checkpoint_timeout` y `max_wal_size`, para que haya menos registro que
rehacer desde el último punto de control. Lo pago en más puntos de control, más páginas enteras en
el WAL y más escritura de fondo.

🗣️ **2 minutos** — El tiempo de recuperación es proporcional al registro escrito desde el último
punto de control. Si hoy se rehacen cinco minutos, bajar `checkpoint_timeout` de 5 min a 1 min acota
ese tramo en el caso normal, y bajar `max_wal_size` lo acota en los picos de escritura. Antes de
tocar nada mediría: en el log de la última recuperación, `redo starts`, `redo done` y el tiempo de
`elapsed`, y en `pg_stat_checkpointer`, cuántos puntos de control se disparan por tiempo y cuántos
por volumen.

🔬 **El detalle** — **Motor.** El precio es concreto: con puntos de control más frecuentes, cada
página vuelve a ir entera al WAL la primera vez que se toca tras cada uno, así que el volumen de WAL
sube, y con él la réplica y el archivado. Y hay un tope que no se baja con parámetros: si el
requisito es un minuto **incluida** la conmutación a otra máquina, eso ya es alta disponibilidad, y
no se resuelve en este capítulo.

---

## Simulación de entrevista

Las 26 preguntas `S#` y los cuatro escenarios de [`07`](07-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**07 → S1.** Recita las cuatro letras de ACID y, de cada una, di **dónde termina**: qué caso
concreto no cubre. 🟡

⏱️ **30 segundos** — La A: todo o nada, pero no dice nada de lo que hace otro a la vez. La C: el
motor hace cumplir lo declarado en el esquema, no tus reglas de negocio. La I: se configura, y a
ningún nivel práctico es gratis. La D: sobrevive a un corte, pero en el disco de **un** servidor.

🗣️ **2 minutos** — Cada frontera tiene su caso. La A no impide la actualización perdida: dos pagos
de 10 y 20 sobre `PED-00042` y el total sube 20, con las dos transacciones atómicas. La C no sabe
que los pagos no pueden superar el total si esa regla vive en un `if`. La I por defecto de
PostgreSQL deja pasar el fantasma de 120 000 a 120 001. Y la D depende de un parámetro, de que el
disco no mienta y de que el servidor vuelva.

🔬 **El detalle** — **Estándar** para los cuatro nombres; **motor** para dónde termina cada uno. La
prueba medida de que las cuatro letras no bastan es la de `01/01` §2, y la de que la D es
condicional, la confirmación perdida de [`06`](06-wal-durabilidad-y-fsync.md) §4: `UPDATE 1` y, tras
la caída, el pedido como estaba.

---

**07 → S2.** Una conexión vuelve al *pool* con una transacción abierta porque un camino de error no
hizo ni `COMMIT` ni `ROLLBACK`. Di qué le pasa a la siguiente petición que la toma y qué le pasa a
la base mientras tanto. 🟠

⏱️ **30 segundos** — La siguiente petición trabaja **dentro** de esa transacción ajena: ve lo que no
debería y lo que escriba se confirmará o se perderá con ella. Mientras tanto, la transacción retiene
sus bloqueos y el horizonte de limpieza de toda la base.

🗣️ **2 minutos** — En PostgreSQL, si la transacción quedó abortada por el error, la siguiente
petición recibe `current transaction is aborted` en todo lo que haga, hasta que alguien haga
`ROLLBACK`. Si no quedó abortada, es peor: todo parece ir bien. En los dos casos, mientras la
conexión espera en el *pool*, aparece en `pg_stat_activity` como `idle in transaction`, bloquea las
filas que tocó y frena el `VACUUM`.

🔬 **El detalle** — **Motor.** La defensa es doble: el *pool* tiene que hacer `ROLLBACK` al recibir
una conexión, y la base puede cortar las olvidadas con `idle_in_transaction_session_timeout`, que
cierra la conexión con `FATAL` ([`05`](05-optimista-pesimista-y-transacciones-largas.md) §5). La
segunda sin la primera cambia un fallo silencioso por uno ruidoso, y eso ya es una mejora.

---

**07 → S3.** La misma migración, con tres `ALTER TABLE` dentro de un `BEGIN`, falla en el segundo.
Di cómo queda el esquema en PostgreSQL y cómo en MySQL, y qué categoría es esa diferencia. 🟡

⏱️ **30 segundos** — En PostgreSQL, como estaba: el DDL es transaccional y el fallo aborta la
transacción entera. En MySQL, con el primer `ALTER` aplicado y sin vuelta atrás, porque cada DDL
confirma implícitamente.

🗣️ **2 minutos** — En MySQL el `BEGIN` no sirve de nada ahí: el primer `ALTER` confirmó lo que
hubiera antes y se confirmó a sí mismo, y el segundo falló solo. El guion queda a medias y hay que
deshacer a mano. En PostgreSQL basta con arreglar y relanzar.

🔬 **El detalle** — **Motor**: el estándar no exige que el DDL sea transaccional. SQLite también lo
deshace. Por eso en MySQL las migraciones se escriben con un cambio por paso y su vuelta atrás
explícita, y en PostgreSQL se pueden agrupar.

---

**07 → S4.** «`REPEATABLE READ` evita las lecturas fantasma». Da las tres respuestas: la del
estándar, la de PostgreSQL y la de InnoDB, cada una con su porqué. 🟡

⏱️ **30 segundos** — El estándar dice que no: permite fantasmas en ese nivel. PostgreSQL dice que
sí, porque su `REPEATABLE READ` es una instantánea fija para toda la transacción. InnoDB dice que
sí, con dos mecanismos: la instantánea para las lecturas normales y los *next-key locks* para las
que bloquean.

🗣️ **2 minutos** — La tabla del estándar solo prohíbe la lectura sucia y la no repetible en ese
nivel; prohibir más es legal. PostgreSQL no puede ver filas nuevas porque su instantánea se tomó al
principio. InnoDB, en un `SELECT … FOR UPDATE` por rango, bloquea también los huecos entre claves, y
un `INSERT` de otra sesión en ese hueco espera.

🔬 **El detalle** — **Estándar** en la primera, **motor** en las otras dos, y es la pregunta más
rentable del bloque. El precio es distinto: la instantánea cuesta versiones retenidas; el bloqueo de
hueco cuesta esperas a sesiones que insertan y no tocan ninguna fila tuya.

---

**07 → S5.** Un informe cuenta los pedidos pendientes dos veces en la misma transacción y obtiene
120 000 y 120 001. Nombra la anomalía, di por qué es posible con la configuración de fábrica de
PostgreSQL y da la corrección con su precio. 🟠

⏱️ **30 segundos** — Es una lectura fantasma: apareció una fila que cumple la condición y antes no
estaba. Es posible porque PostgreSQL viene en `READ COMMITTED`, que toma una instantánea por
sentencia. La corrección es abrir el informe en `REPEATABLE READ`.

🗣️ **2 minutos** — Corrido en [`02`](02-aislamiento-y-sus-fenomenos.md) §5: otra sesión movió
`PED-99999` a `PENDIENTE` entre las dos cuentas. Con `REPEATABLE READ`, la transacción del informe
toma una instantánea al principio y la usa hasta el final, así que las dos cuentas cuadran. Un
informe de solo lectura no recibe errores de serialización por eso.

🔬 **El detalle** — El precio es el de [`03`](03-mvcc-frente-a-bloqueo.md) §6: mientras el informe
dure, su instantánea fija el horizonte y el `VACUUM` no recicla nada posterior. Si el informe dura
cuarenta minutos, es mejor sacarlo a una réplica, con el precio que
[`05`](05-optimista-pesimista-y-transacciones-largas.md) §6 le pone a eso.

---

**07 → S6.** Un servicio migra de MySQL a PostgreSQL sin tocar una línea y el nivel de aislamiento
cambia sin que nadie lo decida. Di de cuál a cuál, y qué anomalía nueva puede aparecer y cuál
desaparece. 🟠

⏱️ **30 segundos** — De `REPEATABLE READ` en InnoDB a `READ COMMITTED` en PostgreSQL. Aparecen la
lectura no repetible y el fantasma dentro de una transacción. Y no desaparece ninguna: la
actualización perdida estaba en los dos, porque InnoDB en su nivel por defecto tampoco la detecta.

🗣️ **2 minutos** — El código que leía dos veces lo mismo en una transacción y confiaba en que
cuadrara deja de poder confiar. Lo que cambia además es la señal de conflicto: en InnoDB, dos
escrituras sobre la misma fila en `REPEATABLE READ` esperan y **la segunda aplica sin error**; en
PostgreSQL `REPEATABLE READ` la segunda recibe `40001`. Si el servicio sube a ese nivel, necesita un
bucle de reintento que antes no tenía.

🔬 **El detalle** — **Motor**, las dos: el estándar no fija el nivel por defecto. Medido en
[`02`](02-aislamiento-y-sus-fenomenos.md) §6: InnoDB esperó 2,878 s y escribió sin error. La
hipótesis se confirma con `SHOW transaction_isolation` en un lado y `SELECT @@transaction_isolation`
en el otro.

---

**07 → S7.** «Un pedido anulado no puede tener más de un pago de compensación». Dos operadores lo
comprueban a la vez y los dos insertan. Nombra la anomalía, di por qué `REPEATABLE READ` no la ve en
PostgreSQL, y da dos formas de impedirla. 🟠

⏱️ **30 segundos** — Es *write skew*: los dos leen el mismo conjunto, cada uno decide algo válido y
las dos escrituras juntas rompen la regla. `REPEATABLE READ` no la ve porque ninguno escribió lo que
escribió el otro: no hay conflicto de fila que detectar.

🗣️ **2 minutos** — Las dos formas: `SERIALIZABLE`, que en PostgreSQL detecta la dependencia y aborta
al segundo en el `COMMIT` —corrido en [`02`](02-aislamiento-y-sus-fenomenos.md) §7, con `Canceled on
identification as a pivot`—; o **materializar el conflicto**, haciendo que los dos escriban la misma
fila, por ejemplo con un `SELECT … FOR UPDATE` sobre el pedido antes de contar sus pagos.

🔬 **El detalle** — **Motor**: el *write skew* no está en el estándar, lo nombra el artículo de
Berenson y otros de 1995. El precio: `SERIALIZABLE` cobra en abortos y reintentos; el `FOR UPDATE`
del padre, en espera, solo entre operaciones sobre el mismo pedido.

---

**07 → S8.** Di dónde vive la versión antigua de una fila en PostgreSQL y dónde en InnoDB, y qué
fichero crece en cada uno cuando alguien deja una transacción abierta. 🟡

⏱️ **30 segundos** — En PostgreSQL, en la propia tabla: un `UPDATE` escribe una fila nueva y deja la
vieja con su `xmax`. En InnoDB, en el *undo log*: la tabla solo tiene la última y las anteriores se
reconstruyen hacia atrás. Con una transacción abierta crece la tabla en PostgreSQL y el espacio de
*undo* en InnoDB.

🗣️ **2 minutos** — En PostgreSQL las versiones que nadie puede ver se vuelven filas muertas y las
recicla el `VACUUM`, pero solo por debajo del horizonte que fija la transacción abierta más antigua.
En InnoDB las recicla el hilo de purga, con la misma condición, y el indicador de que va por detrás
es `History list length`.

🔬 **El detalle** — **Motor**, todo: la norma no habla de mecanismos. Es el mismo incidente con dos
ficheros distintos creciendo, y por eso se dice que MVCC cambia espera por espacio.

---

**07 → S9.** Un `ROLLBACK` de un millón de filas termina al instante en un motor y tarda más que el
trabajo original en el otro. Di cuál es cuál y el mecanismo. 🟠

⏱️ **30 segundos** — Instantáneo en PostgreSQL, lento en InnoDB. PostgreSQL no restaura nada: anota
que la transacción abortó y sus versiones nuevas dejan de ser visibles. InnoDB tiene que aplicar el
*undo* al revés, fila a fila.

🗣️ **2 minutos** — En PostgreSQL la versión vieja nunca se tocó; lo que queda tras el `ROLLBACK` son
un millón de versiones muertas que el `VACUUM` tendrá que reciclar después. En InnoDB la tabla se
modificó en sitio y el `ROLLBACK` tiene que devolverla a su estado, sin poder cancelarse a mitad.
Por eso InnoDB elige como víctima de un interbloqueo a la transacción con menos trabajo hecho.

🔬 **El detalle** — **Motor.** Ninguno de los dos se ahorra el coste: PostgreSQL lo paga después en
espacio y E/S de limpieza, InnoDB lo paga en el momento. Conviene decirlo así en la entrevista: no
se ganó ni se perdió, se cambió de moneda.

---

**07 → S10.** La tabla `pedidos` ocupa el triple de lo que pesan sus filas vivas y el autovacuum
corre sin liberar nada. Da la cadena completa desde la causa más probable hasta el disco lleno, y la
primera consulta que lanzarías. 🟠

⏱️ **30 segundos** — Una transacción abierta desde hace horas fija el horizonte; el `VACUUM` no
puede reciclar nada posterior; las filas muertas se acumulan, la tabla y sus índices crecen, y las
consultas leen más páginas. Primera consulta: `pg_stat_activity` ordenada por `xact_start`.

🗣️ **2 minutos** — La consulta:

```sql
SELECT pid, state, xact_start, backend_xid, backend_xmin
  FROM pg_stat_activity
 WHERE xact_start IS NOT NULL
 ORDER BY xact_start;
```

Arriba saldrá una sesión `idle in transaction` de hace horas, con `backend_xmin` o con
`backend_xid`: cualquiera de los dos frena la limpieza. Si no la hay, la siguiente hipótesis es una
réplica con `hot_standby_feedback` o una ranura de replicación abandonada.

🔬 **El detalle** — Y un matiz que se midió en esta tanda: aun cerrada la causa, el `VACUUM` normal
**solo devuelve al disco las páginas vacías del final**; el hueco del medio queda reutilizable
dentro de la tabla. Corrido: `truncated 17640 to 10770 pages` cuando nadie tenía la tabla abierta, y
`stopping truncate due to conflicting lock request` cuando sí.

---

**07 → S11.** Un `ALTER TABLE … ADD COLUMN` que tarda un milisegundo tumbó el sitio diez minutos.
Explica el mecanismo y la defensa de dos líneas. 🟠

⏱️ **30 segundos** — El `ALTER` pide `ACCESS EXCLUSIVE` y se pone en la cola detrás de un informe
que lee la tabla. Todo lo que llega después, incluidos los `SELECT` de la aplicación, se pone en la
cola detrás del `ALTER`. La defensa: `SET lock_timeout = '3s'` antes del `ALTER`.

🗣️ **2 minutos** — Los `SELECT` del *checkout* no chocan con el informe, pero no pueden adelantar al
`ALTER`, que llegó antes y choca con todo. Lo que cae no es el `ALTER`: es la cola. Con
`lock_timeout` el que se rinde es la migración, con `canceling statement due to lock timeout`, y se
reintenta cuando no haya informes.

🔬 **El detalle** — **Motor**. En MySQL el mismo final viene del *metadata lock* que retiene
cualquier transacción abierta, incluida una que solo leyó. Y el `ADD COLUMN` con `DEFAULT` constante
no reescribe la tabla en ninguno de los dos: todo el riesgo está en **conseguir** el bloqueo.

---

**07 → S12.** Te proponen subir el tiempo de espera de bloqueo para que dejen de aparecer
interbloqueos. Di por qué no sirve y cuál es la única solución completa. 🟡

⏱️ **30 segundos** — Porque un interbloqueo es un ciclo, y un ciclo no se deshace esperando más. La
única solución completa es que todas las rutas de código tomen los bloqueos **en el mismo orden**.

🗣️ **2 minutos** — Si A tiene lo que B quiere y B lo que A quiere, esperar más solo retrasa el
momento en que el motor mata a una. Con un orden fijo —`ORDER BY id` en el `SELECT … FOR UPDATE` de
todos los procesos— no se puede formar el ciclo. Lo demás son paliativos: transacciones cortas,
`lock_timeout` y un bucle de reintento para lo que quede.

🔬 **El detalle** — **Motor**: PostgreSQL busca el ciclo tras `deadlock_timeout`, un segundo, y
InnoDB al instante. En la corrida de [`04`](04-bloqueos-e-interbloqueos.md) §5 murió A, la primera
en ponerse a esperar; qué sesión muere no se elige, y por eso el código tiene que poder reintentar
cualquiera de las dos.

---

**07 → S13.** Diez trabajadores sacan tareas de la misma tabla de pedidos pendientes. Di qué pasa
sin `SKIP LOCKED`, qué pasa con él, y qué se pierde al usarlo. 🟡

⏱️ **30 segundos** — Sin él, los diez piden las mismas filas más antiguas y nueve esperan en fila
detrás del primero. Con él, cada uno se salta lo que otro tiene bloqueado y se lleva filas
distintas, sin esperar. Se pierde el determinismo: dos ejecuciones iguales devuelven filas
distintas.

🗣️ **2 minutos** — Corrido en [`04`](04-bloqueos-e-interbloqueos.md) §4 con dos sesiones y `LIMIT
5`: cinco pedidos cada una, ninguno repetido, y los de la segunda eran exactamente los cinco
siguientes por `creado_en`. Es la cola de trabajo de una línea: correcto para repartir tareas,
incorrecto para un informe, que necesita ver todas las filas.

🔬 **El detalle** — **Motor**: PostgreSQL lo tiene desde hace una década y MySQL desde 8.0; SQLite
no, porque con un solo escritor no hay a quién saltarse. No sustituye a una cola de verdad con
millones de mensajes, pero evita un sistema entero para decenas de miles al día.

---

**07 → S14.** Tu bucle de reintento captura `SQLSTATE 40001`. Di qué errores de concurrencia cubre
en PostgreSQL y en MySQL, y cuál se le escapa en PostgreSQL. 🟠

⏱️ **30 segundos** — En PostgreSQL cubre los fallos de serialización de `REPEATABLE READ` y
`SERIALIZABLE`. En MySQL cubre el interbloqueo, que allí es `ERROR 1213` con `SQLSTATE 40001`. Se le
escapa el interbloqueo de PostgreSQL, que es `40P01`.

🗣️ **2 minutos** — Por eso el bucle de PostgreSQL necesita dos códigos, `40001` y `40P01`, y el de
MySQL con uno le basta para el interbloqueo. La espera vencida es aparte y no conviene reintentarla
a ciegas: `55P03` en PostgreSQL con `lock_timeout`, y `ERROR 1205` en MySQL tras 50 s.

🔬 **El detalle** — **Motor**, y la coincidencia es casual: el mismo código significa cosas distintas
en cada uno. Las tres condiciones del bucle no cambian: se reintenta la transacción entera desde el
`BEGIN`, solo con los códigos que lo merecen, y solo si el trabajo es repetible.

---

**07 → S15.** Un operador abre un pedido en el panel, tarda tres minutos y guarda. ¿`FOR UPDATE` o
columna de versión? Defiende una y di por qué la otra no puede funcionar aquí. 🟡

⏱️ **30 segundos** — Columna de versión. `FOR UPDATE` no puede funcionar porque el bloqueo muere con
la transacción, la transacción vive en una conexión, y abrir el formulario y guardarlo son dos
peticiones con conexiones distintas.

🗣️ **2 minutos** — Para que `FOR UPDATE` funcionara habría que mantener una transacción abierta tres
minutos, atada a una conexión reservada para ese usuario: la fila bloqueada para los demás, el
horizonte congelado y una conexión menos en el *pool*. La versión viaja con el formulario, el
guardado exige en el `WHERE` que siga siendo la misma, y no se retiene nada mientras el operador
piensa.

🔬 **El detalle** — **Convención** para los nombres de las dos familias; **motor** para lo que hace
correcto al optimista: que el segundo `UPDATE` espere al bloqueo de fila y reevalúe su `WHERE`,
corrido en [`05`](05-optimista-pesimista-y-transacciones-largas.md) §3.

---

**07 → S16.** Tu guardado optimista recibe `UPDATE 0`. Di qué significa, qué tiene que hacer la
aplicación, y en qué caso el mismo `0` miente en MySQL. 🟠

⏱️ **30 segundos** — Que otro guardó antes y la versión ya no es la que leíste. La aplicación tiene
que releer y enseñar el dato nuevo al usuario, no reintentar a ciegas. En MySQL el `0` miente cuando
el `UPDATE` escribe los mismos valores que ya había, porque MySQL cuenta filas cambiadas, no
encontradas.

🗣️ **2 minutos** — Corrido en MySQL: un `UPDATE` que pone `ANULADO` sobre un pedido ya anulado
responde `0 rows affected` y `Rows matched: 1 Changed: 0`. PostgreSQL responde `UPDATE 1` a la misma
sentencia. Si la versión siempre se incrementa, la fila siempre cambia y el problema desaparece.

🔬 **El detalle** — **Motor.** La alternativa es pedir al protocolo filas encontradas con
`CLIENT_FOUND_ROWS`. Y el error más frecuente del patrón no es este: es que la aplicación no mire el
número de filas afectadas, y entonces el control optimista no existe.

---

**07 → S17.** Una sesión hizo `FOR UPDATE` en `READ COMMITTED` y lleva diez minutos ociosa, con
`backend_xmin` vacío en `pg_stat_activity`. ¿Frena la limpieza de la base? ¿Y a quién más estorba? 🟠

⏱️ **30 segundos** — Sí la frena: no tiene instantánea, pero tiene identificador de transacción, y
eso fija el horizonte igual. Y estorba a cualquiera que quiera escribir esa fila, que espera sin
límite si no tiene `lock_timeout`.

🗣️ **2 minutos** — `FOR UPDATE` obliga a pedir identificador para marcar la fila. Corrido en
[`05`](05-optimista-pesimista-y-transacciones-largas.md) §5: `backend_xid` 1052 con `backend_xmin`
vacío, y el `UPDATE` de otra sesión sobre el mismo pedido cortado por su `lock_timeout` de 2 s. Por
eso el diagnóstico de transacciones largas filtra por `xact_start` y mira las dos columnas.

🔬 **El detalle** — **Motor.** Y una tercera víctima: un `ALTER TABLE` sobre `pedidos` se pondría en
la cola detrás de ella, con todo lo que viene después, que es el incidente de S11.

---

**07 → S18.** Activas `idle_in_transaction_session_timeout` y al día siguiente el *pool* reparte
conexiones muertas. Di por qué y qué arreglo es el de verdad. 🟡

⏱️ **30 segundos** — Porque el parámetro no aborta la transacción: cierra la conexión con `FATAL`, y
el *pool* no se entera. El arreglo de verdad es el código que deja transacciones abiertas, no el
parámetro.

🗣️ **2 minutos** — El *pool* tiene que validar las conexiones al prestarlas o reintentar con otra al
primer fallo; eso quita el síntoma. Pero cada conexión muerta es una transacción que alguien olvidó
cerrar, normalmente en un camino de error. El parámetro las ha hecho visibles.

🔬 **El detalle** — **Motor.** Corrido: `FATAL: terminating connection due to idle-in-transaction
timeout`, y `psql` se reconecta solo. MySQL no tiene el equivalente; MariaDB sí, con
`idle_transaction_timeout`, a 0 por defecto.

---

**07 → S19.** ¿Qué tiene que estar en disco para que PostgreSQL responda `COMMIT`? Contéstalo con
las dos posiciones del registro que se pueden consultar desde `psql`. 🟡

⏱️ **30 segundos** — El registro del WAL hasta el propio registro de `COMMIT`. Se ve comparando
`pg_current_wal_insert_lsn()`, lo anotado, con `pg_current_wal_flush_lsn()`, lo volcado: antes del
`COMMIT` la segunda va por detrás; después, coinciden.

🗣️ **2 minutos** — Corrido en [`06`](06-wal-durabilidad-y-fsync.md) §2: con el `UPDATE` hecho y sin
confirmar, `2/1ED052F8` anotado contra `2/1ED05288` volcado; tras el `COMMIT`, `2/1ED05320` las dos.
La página de la tabla **no** está en disco en ese momento, y no hace falta: se reconstruye desde el
registro.

🔬 **El detalle** — **Motor.** `pg_waldump` enseña los bytes: un `HOT_UPDATE` de 109 bytes y un
`COMMIT` de 34. Y el matiz final: «en disco» quiere decir que `fdatasync` volvió, lo que a su vez
depende de que el disco no mienta.

---

**07 → S20.** Con `synchronous_commit = off`, ¿cuánto puedes perder, qué nunca pierdes, y hace falta
un corte de corriente para perderlo? 🟠

⏱️ **30 segundos** — Hasta 600 ms de transacciones confirmadas, tres veces `wal_writer_delay`. Nunca
pierdes la coherencia: se pierden transacciones enteras, no medias. Y no hace falta un corte: basta
con que caiga el proceso.

🗣️ **2 minutos** — Los búferes de WAL viven en memoria compartida, y un reinicio por caída los
descarta. Provocado en [`06`](06-wal-durabilidad-y-fsync.md) §4 matando un proceso del servidor en
la sentencia siguiente: `UPDATE 1`, reinicio, y el pedido como estaba. En la tanda se perdió en 8 de
12 caídas con `off` y en 0 de 8 con `on`.

🔬 **El detalle** — **Motor.** En MySQL el equivalente es `innodb_flush_log_at_trx_commit = 2`, que
**no** pierde con la caída del proceso, porque entrega el registro al sistema operativo en cada
`COMMIT`; el que pierde con la caída del proceso es el `0`, y se corrió: 2 de 3.

---

**07 → S21.** `pg_test_fsync` dice que tu disco hace 9 300 volcados por segundo. Di por qué eso no
prueba que sea durable y qué lo probaría. 🟠

⏱️ **30 segundos** — Porque mide velocidad, no verdad. Unos 107 µs por volcado solo son posibles
respondiendo desde una caché, y la pregunta es si esa caché sobrevive a un corte. Lo probaría cortar
la corriente en plena carga y comprobar que lo confirmado sigue ahí.

🗣️ **2 minutos** — Una caché protegida por batería o condensadores hace ese número legítimo. Una
volátil lo hace peligroso: el `COMMIT` responde, el disco dice que escribió, y un corte se lo lleva.
La documentación de PostgreSQL advierte que muchos SSD no respetan las órdenes de vaciado por
defecto, y remite a `diskchecker.pl` para comprobarlo.

🔬 **El detalle** — **Ni estándar ni motor**: es del hardware y del sistema operativo. El número es
el del entorno del corpus, un contenedor sobre un portátil con una virtualización cuya garantía no
está verificada, y por eso el capítulo no afirma que sea durable.

---

**07 → S22.** ¿Qué hace PostgreSQL al arrancar después de una caída, y qué dos parámetros acotan
cuánto tarda? 🟢

⏱️ **30 segundos** — Busca el último punto de control y vuelve a aplicar el WAL desde ahí hasta el
final. Lo acotan `checkpoint_timeout`, 5 min, y `max_wal_size`, 1 GB.

🗣️ **2 minutos** — Corrido matando el contenedor justo después de un `COMMIT`: `automatic recovery
in progress`, `redo starts`, `redo done` en 0,54 s tras rehacer unos 150 MB, y el cambio confirmado
en su sitio. Cuanto más registro desde el último punto de control, más tarda.

🔬 **El detalle** — **Motor.** Puntos de control más frecuentes acortan la recuperación y aumentan el
WAL, por las páginas enteras que `full_page_writes` guarda tras cada uno.

---

**07 → S23.** «Con transacciones no hay condiciones de carrera». Refútalo con **dos** casos de este
bloque, uno con el nivel por defecto y otro con `REPEATABLE READ`. 🟠

⏱️ **30 segundos** — Con el nivel por defecto de PostgreSQL, la actualización perdida: dos pagos de
10 y 20 sobre el mismo pedido y el total sube 20. Con `REPEATABLE READ`, el *write skew*: dos
operadores comprueban que no hay pago de compensación y los dos insertan uno.

🗣️ **2 minutos** — En los dos casos las transacciones son atómicas, duraderas y cumplen su nivel. La
primera se evita dejando la aritmética al `UPDATE` o con `FOR UPDATE`; la segunda, con
`SERIALIZABLE` o materializando el conflicto. Ninguna de las dos se ve como error: se ve como un
dato que no cuadra semanas después.

🔬 **El detalle** — **Convención** falsa, y la más cara en banca. Los dos casos están corridos: el
primero en `01/01` §2, de 3186.23 a 3206.23; el segundo en [`02`](02-aislamiento-y-sus-fenomenos.md)
§7, con dos filas en `pagos` donde la regla permite una.

---

**07 → S24.** ¿Cuáles de estas cosas están en el estándar SQL: los cuatro niveles de aislamiento,
MVCC, `FOR UPDATE`, `SKIP LOCKED`, el WAL y el nivel por defecto? Una palabra por cada una, y la
consecuencia para una entrevista. 🟡

⏱️ **30 segundos** — Niveles: sí. MVCC: no. `FOR UPDATE`: sí, en cursores. `SKIP LOCKED`: no. WAL:
no. Nivel por defecto: no. La consecuencia: casi todo lo que importa en producción es de motor, y
hay que decir de cuál.

🗣️ **2 minutos** — El estándar define qué anomalías tolera cada nivel y deja al implementador el
mecanismo, el valor por defecto y la durabilidad. Por eso «¿qué hace `REPEATABLE READ`?» no tiene
una respuesta sino tres, y «¿qué significa `COMMIT`?» depende de un parámetro de cada motor.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas: lo afirmado de la norma
es doctrina asentada que reproducen las documentaciones de los tres motores. Decirlo así en la
entrevista suma, no resta.

---

**07 → S25.** «Si el motor dijo `UPDATE 1` y `COMMIT`, está guardado». Da tres situaciones en que
eso es falso, de la más probable a la menos. 🟠

⏱️ **30 segundos** — Primera, que la transacción corriera con `synchronous_commit = off` y cayera el
proceso en los 600 ms siguientes. Segunda, que el disco tuviera una caché volátil que mintió al
volcar. Tercera, que el servidor no volviera y la réplica fuera asíncrona.

🗣️ **2 minutos** — La primera se provocó en el bloque: `UPDATE 1` y, tras la caída, el dato como
estaba. La segunda no la produce ningún parámetro del motor y solo se descarta sabiendo qué hardware
hay. La tercera es la frontera de la D: durable es en el disco de un servidor, y sin réplica
síncrona lo confirmado se pierde con la máquina.

🔬 **El detalle** — Hay una cuarta, más probable que todas en la práctica y que no es de la base: que
el «guardado» que vio el usuario saliera del servicio **antes** del `COMMIT`. Nombrarla primero en
un diagnóstico real ahorra horas.

---

**07 → S26.** «InnoDB en `REPEATABLE READ` protege mejor que PostgreSQL, porque bloquea en vez de
abortar». Refútalo con lo que hace cada uno cuando dos transacciones escriben la misma fila. 🟠

⏱️ **30 segundos** — InnoDB hace esperar a la segunda y luego **aplica su escritura sin error**
sobre la versión confirmada. PostgreSQL la aborta con `40001`. Si la segunda decidió con un dato que
leyó antes, InnoDB acaba de perder una actualización; PostgreSQL se lo ha avisado.

🗣️ **2 minutos** — Medido en [`02`](02-aislamiento-y-sus-fenomenos.md) §6: InnoDB esperó 2,878 s y
escribió. Para una escritura ciega —`SET x = x + 1`— el resultado es correcto; para un
leer-decidir-escribir repartido entre la aplicación y la base, es la actualización perdida igual que
en `READ COMMITTED`. El aborto de PostgreSQL no es peor protección: es el contrato que obliga a
reintentar con el dato nuevo.

🔬 **El detalle** — **Motor**, los dos cumplen el estándar. Lo que cambia es la moneda: InnoDB cobra
en espera —y hasta 50 s si la otra no confirma—; PostgreSQL, en reintentos. Ninguno exime de `FOR
UPDATE` o de la columna de versión cuando la decisión se toma fuera de la base.

---

**07 → E1.** Escenario 1 — Los pagos que superan el total

⏱️ **30 segundos** — Es *write skew*: cada inserción lee la suma, ve que cabe, e inserta una fila
**distinta**; ninguna escribió lo que escribió la otra y `READ COMMITTED` no tiene nada que
detectar. La regla hay que moverla a un sitio donde las dos choquen.

🗣️ **2 minutos** — Tres formas, de más barata a más cara:

1. **Bloquear el padre**: `SELECT … FROM pedidos WHERE id = :p FOR UPDATE`, sumar los pagos,
   comparar e insertar, todo en la misma transacción. Los pagos del mismo pedido se ponen en fila;
   los de pedidos distintos no se tocan. Se paga en **espera**, corta y local.
2. **Columna acumulada con condición**: `UPDATE pedidos SET pagado = pagado + :importe WHERE id = :p
   AND pagado + :importe <= total`, e insertar el pago solo si devuelve 1. La comprobación y la
   escritura son una sentencia sobre la misma fila. Se paga en **esquema**: una columna redundante
   que mantener, y un cambio de DDL.
3. **`SERIALIZABLE`** en esa transacción, con bucle de reintento para `40001`. No toca el esquema.
   Se paga en **abortos** bajo carga.

Elegiría la primera: no cambia el esquema, el conflicto es raro y la espera es de milisegundos. Lo
que **no** sirve es un `INSERT … SELECT … WHERE suma + importe <= total` suelto: cada sentencia lee
su propia instantánea y las dos pasan.

🔬 **El detalle** — Lo que se evalúa es que nombres la anomalía antes que la solución y que digas por
qué el `CHECK` no llega: las restricciones de tabla miran una fila, y esta regla mira varias. La
comprobación se hace con dos sesiones, como en [`02`](02-aislamiento-y-sus-fenomenos.md) §7: sin la
corrección salen dos pagos; con ella, la segunda sesión espera en el `FOR UPDATE`, lee la suma nueva
y no inserta. **Motor** para el mecanismo, **convención** para el nombre de las tres técnicas.

---

**07 → E2.** Escenario 2 — La base que engorda y los despliegues que se cuelgan

⏱️ **30 segundos** — Una transacción que se queda abierta: fija el horizonte y el `VACUUM` no
recicla —la tabla crece y el informe lee más páginas—, y retiene un bloqueo sobre `pedidos` que deja
al `ALTER TABLE` en la cola, con la aplicación detrás. Los tres síntomas son uno.

🗣️ **2 minutos** — Las dos consultas: `pg_stat_activity` ordenada por `xact_start`, buscando `idle
in transaction` de hace horas; y `pg_stat_user_tables` para `pedidos`, con `n_dead_tup` alto y el
autovacuum pasando sin bajarlo. `VACUUM FULL` no arregla la causa: con la transacción abierta
tampoco puede quitar esas versiones, bloquea la tabla en exclusiva mientras la reescribe y necesita
espacio para la copia. Las tres medidas: que el *pool* haga `ROLLBACK` al recibir una conexión y el
código cierre la transacción en todo camino de error; `idle_in_transaction_session_timeout` en el
rol de la aplicación; y `lock_timeout` en cada migración.

🔬 **El detalle** — Lo que se evalúa es no tratar tres incidentes por separado. Y el matiz medido:
cerrada la causa, el `VACUUM` normal devuelve al disco solo las páginas vacías del final —`truncated
17640 to 10770 pages` en esta tanda—; el resto queda reutilizable dentro de la tabla, que dejará de
crecer aunque no encoja. Solo si hace falta el espacio se planifica un `VACUUM FULL`, fuera de
horas.

---

**07 → E3.** Escenario 3 — El Black Friday y el `COMMIT` que no espera

⏱️ **30 segundos** — `synchronous_commit = off` pierde, como mucho, 600 ms de transacciones
confirmadas si cae el servidor, y nunca corrompe. `fsync = off` puede corromper la base entera. La
primera se acepta tabla por tabla; la segunda, nunca en producción.

🗣️ **2 minutos** — Relajaría solo lo que se puede perder sin nadie esperando al otro lado: eventos
de navegación, métricas, cachés materializadas. Nunca `pagos` ni `pedidos`. Sin tocar el servidor,
con `SET LOCAL synchronous_commit = off` en esas transacciones, o con `ALTER ROLE … SET` para el rol
del servicio que las escribe. Antes mediría: la latencia de `COMMIT` actual y cuánto pesa en el
tiempo de la petición. En el entorno del corpus la diferencia fue de 0,181 ms a 0,087 ms por
confirmación, el doble de transacciones por segundo, pero sobre un disco que confirma en 107 µs.

🔬 **El detalle** — Lo que se evalúa es separar las dos propuestas y dar números con origen: los 600
ms son tres veces `wal_writer_delay`, de la documentación; la pérdida se provocó, 8 de 12 caídas con
`off`. Y proponer la alternativa que no sacrifica nada: agrupar escrituras en menos transacciones,
que reduce los `fsync` sin perder ninguno.

---

**07 → E4.** Escenario 4 — El pedido pagado que el inventario no descontó

⏱️ **30 segundos** — Esto no lo resuelve la base de datos. Una transacción vive en una conexión de
un motor, y la llamada HTTP no está dentro de ninguna; `SERIALIZABLE` es aislamiento dentro de una
base, no atomicidad entre dos. Lo que la base sí aporta es que el pago y **el aviso de que hay que
descontar** se confirmen juntos.

🗣️ **2 minutos** — El diseño: en la misma transacción que registra el pago, se inserta una fila en
`eventos_pedido` con tipo `PAGO_REGISTRADO` —esa es la mitad atómica, y es lo que se conoce como
*outbox* (bandeja de salida)—. Un proceso aparte recoge los eventos pendientes con `FOR UPDATE SKIP
LOCKED`, llama al inventario y marca el evento como enviado. Si la llamada falla, se reintenta; y
como puede llegar dos veces, el inventario guarda el identificador del evento en una columna
`UNIQUE` y descarta los repetidos. Entrega al menos una vez más consumidor idempotente es igual a
efecto exactamente una vez.

🔬 **El detalle** — Lo que se evalúa es decir en voz alta qué letra se pide —la A— y por qué no
existe entre dos motores sin un protocolo de confirmación en dos fases, que casi nadie usa entre
servicios por lo que cuesta en disponibilidad. Y reconocer las dos mitades: la base garantiza que
pago y evento van juntos, y el `UNIQUE` del inventario garantiza que el descuento no se repite; el
reintento y el orden son de la aplicación. Si falla el descuento de forma definitiva —no hay
existencias—, hace falta una **compensación**: otro evento que devuelve el pago, que también es
trabajo de la aplicación y no del motor.

---

**Volver:** [README del bloque](README.md) · **Primer capítulo:** [`01`](01-acid-con-precision.md).
