# 05 — Respuestas

> Solucionario del bloque: el enunciado copiado literalmente de su capítulo y la respuesta en tres
> capas.
>
> **Cómo se usa.** Responde primero en voz alta, con el cronómetro. La capa ⏱️ es lo que dices en
> los primeros treinta segundos; la 🗣️ es lo que añades cuando te dicen "cuéntame más"; la 🔬 es el
> matiz que casi nadie trae, y es donde vive la distinción entre **lo que manda el estándar, lo que
> hace cada motor y lo que es pura convención**.
>
> **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [Capítulo 01 — Funciones y procedimientos](#capítulo-01--funciones-y-procedimientos)
- [Capítulo 02 — Disparadores](#capítulo-02--disparadores)
- [Capítulo 03 — Claves generadas](#capítulo-03--claves-generadas)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — Funciones y procedimientos

Las 18 preguntas de [`01`](01-funciones-y-procedimientos.md).

**01 → 1.** ¿Qué diferencia una función de un procedimiento en PostgreSQL? 🟢

⏱️ **30 segundos** — Una función devuelve un valor y se llama dentro de una consulta. Un
procedimiento se llama con `CALL`, no devuelve valor y puede confirmar o deshacer transacciones a
mitad de camino.

🗣️ **2 minutos** — `anular_pendientes` fue una función: `SELECT anular_pendientes(...)` devolvió
10 929. `anular_por_lotes` fue un procedimiento: hizo cuatro `COMMIT`, uno por lote, algo que una
función no puede hacer.

🔬 **El detalle** — **Motor**. En PostgreSQL existen desde la versión 11; antes, todo eran funciones.

---

**01 → 2.** ¿Qué son las tres categorías de volatilidad? 🟢

⏱️ **30 segundos** — `VOLATILE`, la de defecto: puede devolver algo distinto en cada llamada.
`STABLE`: lo mismo dentro de una consulta. `IMMUTABLE`: siempre lo mismo para los mismos argumentos.

🗣️ **2 minutos** — Decide qué puede hacer el planificador: una función `VOLATILE` se llama por fila
y no sirve en la condición de un índice; una `STABLE`, sí. La diferencia medida fue de 414 ms a
0,037.

🔬 **El detalle** — **Motor**. El motor se fía de lo declarado: declarar de más da resultados
incorrectos, declarar de menos da planes lentos.

---

**01 → 3.** ¿Qué es un cursor implícito en PL/pgSQL? 🟢

⏱️ **30 segundos** — El que crea un `FOR r IN SELECT … LOOP`: recorre el resultado fila a fila sin
cargarlo entero en memoria.

🗣️ **2 minutos** — `anular_pendientes` lo usó para recorrer los 10 929 pendientes. Con cursores
explícitos —`DECLARE … CURSOR`, `FETCH`— se controla más, pero para un recorrido basta el implícito.

🔬 **El detalle** — **Motor**. Recorrer fila a fila es cómodo y más lento que una sentencia por
conjuntos: 888 ms frente a 470.

---

**01 → 4.** ¿Qué hace `DELIMITER` en el cliente de MySQL? 🟢

⏱️ **30 segundos** — Cambia el terminador de sentencia del cliente, para que los `;` del cuerpo de
un procedimiento no lo corten antes de tiempo.

🗣️ **2 minutos** — En la sesión, `DELIMITER //` permitió escribir `contar_tareas` con su `;` dentro,
y `DELIMITER ;` lo devolvió. El servidor nunca ve el `DELIMITER`.

🔬 **El detalle** — Es del cliente `mysql`, no de SQL; un driver no lo necesita.

---

**01 → 5.** ¿Por qué declarar `IMMUTABLE` la función en SQL no cambió el plan? ¿Lo fija el estándar
o es cosa del motor? 🟡

⏱️ **30 segundos** — Porque una función en SQL de una sola expresión se integra en la consulta: el
planificador ve la expresión en lugar de la función y la calcula antes de ejecutar. El plan ya era
un `Index Scan` con `'PED-00042'` como constante.

🗣️ **2 minutos** — La diferencia de tiempo entre las dos ejecuciones fue de caché —la primera leyó
de disco—, no de la función. El *inlining* hace que una función SQL sencilla cueste cero.

🔬 **El detalle** — **Motor**. Una función PL/pgSQL no se integra nunca, y ahí la volatilidad pesa.

---

**01 → 6.** ¿Por qué la función PL/pgSQL `VOLATILE` produjo un `Seq Scan`, y qué la arregló? 🟡

⏱️ **30 segundos** — Porque una función `VOLATILE` puede devolver algo distinto en cada llamada, y
el índice necesita un valor calculado una vez. El motor la llamó un millón de veces: 414 ms.
Declararla `STABLE` dio un `Index Scan` de 0,037 ms.

🗣️ **2 minutos** — `VOLATILE` es el valor por defecto, así que es la trampa de quien no declara
nada. `Rows Removed by Filter: 999999` es la firma en el plan.

🔬 **El detalle** — **Motor**: la documentación dice que no es válido usar una función `VOLATILE` en
la condición de un recorrido de índice.

---

**01 → 7.** ¿Qué hace `GET DIAGNOSTICS n = ROW_COUNT`? 🟡

⏱️ **30 segundos** — Guarda en `n` cuántas filas tocó la última sentencia. En `anular_por_lotes`
servía para saber cuándo parar: con 0 filas, no quedaba nada que anular.

🗣️ **2 minutos** — Los lotes fueron 1 000, 1 000, 1 000 y 804, y el siguiente dio 0 y salió del
bucle.

🔬 **El detalle** — **Motor**, de PL/pgSQL. También existe la variable `FOUND`, que solo dice si tocó
alguna.

---

**01 → 8.** ¿Qué tiene SQLite en lugar de funciones y procedimientos en SQL? 🟡

⏱️ **30 segundos** — Funciones que la aplicación registra desde su lenguaje con
`sqlite3_create_function`. No hay procedimientos ni un lenguaje procedural dentro.

🗣️ **2 minutos** — Tiene sentido: SQLite vive dentro del proceso de la aplicación, así que no hay
viajes que ahorrar. La lógica está en la aplicación porque la base también lo está.

🔬 **El detalle** — **Motor**. Los disparadores de SQLite sí existen, con cuerpos en SQL.

---

**01 → 9.** Distingue programar una tarea con `EVENT` en MySQL y con `cron` fuera de la base. 🟡

⏱️ **30 segundos** — `EVENT` vive dentro de la base, se respalda con ella y no necesita otra
máquina; en la sesión ejecutó la tarea tres veces en doce segundos. `cron` fuera es otro sistema,
pero la tarea se versiona, se monitoriza y se reintenta como el resto del código.

🗣️ **2 minutos** — Dentro, un fallo solo queda en el registro del servidor y nadie se entera. Por
eso la tarea de negocio se programa fuera, y lo que se lanza —un procedimiento— puede vivir dentro.

🔬 **El detalle** — **Motor**: MySQL trae el programador encendido; PostgreSQL necesita `pg_cron`,
que la imagen oficial no trae.

---

**01 → 10.** ¿Por qué el bucle PL/pgSQL tardó casi el doble que la sentencia con
`UPDATE … RETURNING`? 🟠

⏱️ **30 segundos** — Porque el bucle vuelve a buscar cada pedido por su `id` y ejecuta un `UPDATE` y
un `INSERT` por fila, cada uno con su planificación y su ejecución. La sentencia única lo hace en
una pasada: 470 ms frente a 888.

🗣️ **2 minutos** — Los dos se ahorran los viajes de red; lo que el bucle no se ahorra es el trabajo
por fila. El `RETURNING` dentro de una CTE pasa los `id` cambiados al `INSERT` sin volver a leerlos.

🔬 **El detalle** — Es la regla del capítulo: primero la sentencia por conjuntos, después el bucle.

---

**01 → 11.** ¿Por qué un bloque con `EXCEPTION` multiplicó el coste del bucle, si no saltó ningún
error? 🟠

⏱️ **30 segundos** — Porque cada entrada en un bloque con `EXCEPTION` abre una subtransacción, para
poder deshacer lo que haga el bloque si salta un error. Se paga aunque no salte nunca: de 14 a 66
ms.

🗣️ **2 minutos** — La documentación lo avisa: un bloque así es «significativamente más caro» de
abrir y cerrar. Dentro de un bucle de miles de filas, se multiplica. Se captura fuera del bucle, o
se comprueba antes en vez de capturar.

🔬 **El detalle** — **Motor**. Con escrituras, cada subtransacción consume además un identificador.

---

**01 → 12.** ¿Qué riesgo tiene declarar `IMMUTABLE` una función que lee una tabla? 🟠

⏱️ **30 segundos** — Que el motor la trata como si siempre devolviera lo mismo: puede usarla en un
índice de expresión, que guardará resultados que dejan de ser ciertos cuando cambie la tabla, o
calcularla una vez y reutilizarla.

🗣️ **2 minutos** — No da ningún error: da resultados incorrectos. Lo mismo con una función que
depende de la zona horaria o de un parámetro de sesión.

🔬 **El detalle** — **Motor**: se declara la volatilidad más estricta que sea verdad, ni más ni
menos.

---

**01 → 13.** ¿Dónde se fueron los 6,2 s de la versión desde el cliente, si el cliente solo trabajó
medio segundo? 🟠

⏱️ **30 segundos** — En esperar: 21 858 sentencias, cada una con su viaje de ida y vuelta, unos 0,25
ms de más por sentencia por el puerto de Docker. El trabajo en la base era el mismo que el de la
función, 888 ms.

🗣️ **2 minutos** — `user` y `sys` sumaron medio segundo; `real`, 6,3. En una red de verdad cada
viaje cuesta más. La solución es mandar menos sentencias: una por conjuntos, por lotes, o una
función.

🔬 **El detalle** — Es el mismo fenómeno del N+1 de los ORM, en escritura.

---

**01 → 14.** ¿Por qué el procedimiento por lotes falló dentro de un `BEGIN`, y qué implica para un
ORM? 🟠

⏱️ **30 segundos** — Porque el control de transacciones solo funciona en un `CALL` desde el nivel
superior, sin una transacción abierta. Dentro del `BEGIN`, el `COMMIT` dio el error
`invalid_transaction_termination`, como lo nombra el motor.

🗣️ **2 minutos** — Un ORM o un *framework* que envuelve cada operación en una transacción rompe el
procedimiento. Hay que llamarlo con una conexión en modo de confirmación automática.

🔬 **El detalle** — **Motor**: la documentación lo acota, y la cadena `CALL → SELECT → CALL` tampoco
puede confirmar.

---

**01 → 15.** ¿Por qué confirmar por lotes es mejor que una transacción larga para anular miles de
pedidos? 🟠

⏱️ **30 segundos** — Porque cada `COMMIT` libera los bloqueos de ese lote y deja que `VACUUM` limpie
las versiones viejas; una transacción larga los retiene hasta el final. Y si el proceso muere, lo
confirmado queda hecho.

🗣️ **2 minutos** — `anular_por_lotes` confirmó cuatro lotes y, relanzado, sigue donde se quedó,
porque solo toca lo que sigue `PENDIENTE`. Es idempotente por diseño.

🔬 **El detalle** — Es la transacción larga de `04/05`: cuanto más dura, más filas muertas retiene.

---

**01 → 16.** Diseña la anulación nocturna de pedidos pendientes: qué va en la base, qué fuera y cómo
lo lanzas. 🔴

⏱️ **30 segundos** — Dentro, un procedimiento que anula por lotes con una sentencia por conjuntos y
confirma cada lote. Fuera, el programador —`cron` o el de la plataforma— que lo lanza con
confirmación automática, lo monitoriza y avisa si falla.

🗣️ **2 minutos** — El lote, con `UPDATE … RETURNING` alimentando el `INSERT` de eventos, sin bucle
fila a fila. Idempotente: relanzarlo no duplica eventos. El programador de fuera guarda la duración
y el recuento de cada noche.

🔬 **El detalle** — Lo que se evalúa es separar la lógica que va donde están las filas de la
orquestación, que va donde se opera.

---

**01 → 17.** Diagnostica: tras refactorizar una consulta para usar una función PL/pgSQL que
construye el código del pedido, el endpoint pasó de 2 ms a 400 ms. 🔴

⏱️ **30 segundos** — La función se creó sin declarar volatilidad, así que es `VOLATILE`, y la
condición sobre `codigo` dejó de usar el índice: un `Seq Scan` que la llama un millón de veces. Es
la sesión de §3, 414 ms.

🗣️ **2 minutos** — Lo confirmaría con `EXPLAIN (ANALYZE)`: `Seq Scan` y `Rows Removed by Filter`. Se
arregla declarándola `IMMUTABLE`, si solo depende de sus argumentos, o escribiéndola en SQL para que
se integre.

🔬 **El detalle** — **Motor**. Es la trampa de funciones más frecuente, y no da ningún error.

---

**01 → 18.** Defiende o refuta la regla «la lógica de negocio nunca va en la base de datos», con los
números del capítulo. 🔴

⏱️ **30 segundos** — Se matiza. La lógica que cambia a menudo va fuera, porque se prueba y se
despliega mejor. El trabajo sobre muchas filas va donde están las filas: 6,2 s desde el cliente
frente a 470 ms en una sentencia.

🗣️ **2 minutos** — Y la mayor parte de ese ahorro no pide una función, pide una sentencia por
conjuntos. La función se justifica cuando la lógica no cabe en una sentencia o cuando hay que
confirmar por lotes. Lo que no se defiende es ni el extremo de miles de líneas de PL/SQL ni el de
veinte mil viajes.

🔬 **El detalle** — Lo que se evalúa es sustituir la regla por un criterio: dónde están los datos y
cuánto cambia la lógica.

---

## Capítulo 02 — Disparadores

Las 18 preguntas de [`02`](02-disparadores.md).

**02 → 1.** ¿Qué es un disparador, y qué diferencia `BEFORE` de `AFTER`? 🟢

⏱️ **30 segundos** — Una función que el motor ejecuta sola cuando hay un `INSERT`, `UPDATE` o
`DELETE` en una tabla. `BEFORE` corre antes del cambio y puede modificarlo o cancelarlo; `AFTER`,
después, cuando el cambio ya está hecho.

🗣️ **2 minutos** — La regla de un solo pendiente fue `BEFORE INSERT`, porque tenía que poder
impedirlo. La auditoría y el total fueron `AFTER`, porque reaccionan a lo que ya pasó.

🔬 **El detalle** — **Estándar** la noción; cada motor, con sus extensiones.

---

**02 → 2.** ¿Qué diferencia `FOR EACH ROW` de `FOR EACH STATEMENT`? 🟢

⏱️ **30 segundos** — Por fila, la función se ejecuta una vez por cada fila tocada; por sentencia,
una vez por sentencia, toque las filas que toque.

🗣️ **2 minutos** — El `UPDATE` de 100 000 pedidos llamó 100 000 veces a `auditar_fila` y una sola a
`auditar_sentencia`. Por sentencia se ven las filas con las tablas de transición.

🔬 **El detalle** — **Estándar** las dos; MySQL y SQLite solo tienen la de fila.

---

**02 → 3.** ¿Qué son las tablas de transición? 🟢

⏱️ **30 segundos** — Las filas de antes y de después de una sentencia, vistas como dos tablas dentro
de un disparador por sentencia, con `REFERENCING OLD TABLE AS … NEW TABLE AS …`.

🗣️ **2 minutos** — `auditar_sentencia` hizo una sola inserción uniendo `antes` y `despues` por `id`,
en vez de 100 000. Permiten tratar en conjunto lo que el disparador por fila trata de una en una.

🔬 **El detalle** — **Estándar**, y PostgreSQL las implementa en disparadores `AFTER`.

---

**02 → 4.** ¿Qué son `NEW`, `OLD` y `TG_OP` en una función de disparador? 🟢

⏱️ **30 segundos** — `NEW` es la fila después del cambio, `OLD` la de antes, y `TG_OP` la operación:
`INSERT`, `UPDATE` o `DELETE`. En un `INSERT` no hay `OLD`; en un `DELETE`, no hay `NEW`.

🗣️ **2 minutos** — `auditar_fila` guardó `to_jsonb(OLD)` y `to_jsonb(NEW)`, y `TG_TABLE_NAME` y
`TG_OP` para saber de dónde venía cada fila de auditoría.

🔬 **El detalle** — **Motor**, de PL/pgSQL.

---

**02 → 5.** ¿Qué pasa si un disparador `BEFORE` por fila devuelve `NULL`? ¿Lo fija el estándar o es
cosa del motor? 🟡

⏱️ **30 segundos** — Se cancela el cambio de esa fila, sin error: la sentencia sigue con las demás.
Para que el cambio siga, hay que devolver `NEW`, o una fila modificada.

🗣️ **2 minutos** — En un disparador `AFTER`, lo devuelto se ignora, por eso los de auditoría y total
devolvían `NULL` sin problema. En uno `BEFORE`, devolver `NULL` por descuido hace desaparecer filas
en silencio.

🔬 **El detalle** — **Motor**. Para impedir un cambio con aviso, `RAISE EXCEPTION`, como en la regla
de §5.

---

**02 → 6.** ¿Qué motores del curso tienen disparadores por sentencia? ¿Lo fija el estándar o es cosa
del motor? 🟡

⏱️ **30 segundos** — Solo PostgreSQL. MySQL dio error 1064 con `FOR EACH STATEMENT`, y SQLite, error
de sintaxis.

🗣️ **2 minutos** — El manual de MySQL solo admite `FOR EACH ROW`, y la documentación de SQLite dice
que solo admite disparadores por fila, así que escribirlo es opcional.

🔬 **El detalle** — **Motor**. En MySQL y SQLite, lo que en PostgreSQL es una inserción por sentencia
son siempre N por fila.

---

**02 → 7.** ¿Por qué `recalcular_total` usa `coalesce(NEW.pedido_id, OLD.pedido_id)`? 🟡

⏱️ **30 segundos** — Porque la misma función sirve para `INSERT`, `UPDATE` y `DELETE`: en un
`DELETE` no hay `NEW`, y en un `INSERT` no hay `OLD`. `coalesce` toma el que exista.

🗣️ **2 minutos** — Si un `UPDATE` cambiara la línea de pedido, habría que recalcular los dos
pedidos, el viejo y el nuevo; la función del capítulo no lo cubre, y en producción hay que hacerlo.

🔬 **El detalle** — Es el tipo de detalle que un disparador esconde y una revisión no ve.

---

**02 → 8.** ¿En qué orden se ejecutan varios disparadores del mismo evento en PostgreSQL? 🟡

⏱️ **30 segundos** — Por orden alfabético de nombre, según la documentación. En los `BEFORE`, la
fila que devuelve cada uno es la entrada del siguiente.

🗣️ **2 minutos** — Es un orden que rara vez está en la cabeza de nadie: renombrar un disparador
puede cambiar el resultado. MySQL, en cambio, permite fijarlo con `FOLLOWS` y `PRECEDES`.

🔬 **El detalle** — **Motor**.

---

**02 → 9.** ¿Por qué el disparador por sentencia ahorró tan poco frente al de fila? 🟠

⏱️ **30 segundos** — Porque ahorró las 100 000 llamadas a la función, pero no escribir 100 000 filas
de auditoría con dos `jsonb` cada una, que es la mayor parte del coste: 1 861 ms frente a 2 119.

🗣️ **2 minutos** — Sin disparador fueron 882 ms. El coste de auditar es el de escribir el doble, y
eso no lo cambia la granularidad; lo cambia guardar menos, por ejemplo solo las columnas cambiadas.

🔬 **El detalle** — Por sentencia gana más cuando la función por fila hace consultas propias.

---

**02 → 10.** ¿Por qué mantener el total con un disparador multiplicó por 8,4 el coste, y cómo lo
reducirías? 🟠

⏱️ **30 segundos** — Porque cada línea recalcula su pedido entero, y cada pedido tiene de media 3,5
líneas: se recalcula y se reescribe tres veces y media. De 116 ms a 982 para 35 000 líneas.

🗣️ **2 minutos** — Cada reescritura de `pedidos` deja una versión muerta. Se reduce con un
disparador por sentencia que recalcule cada pedido afectado una sola vez, usando la tabla de
transición.

🔬 **El detalle** — Es el coste de la desnormalización de `01/04`, pagado en cada escritura.

---

**02 → 11.** ¿Por qué las dos sesiones pudieron insertar dos pedidos pendientes, si el disparador lo
comprobaba? 🟠

⏱️ **30 segundos** — Porque en `READ COMMITTED` cada una solo ve lo confirmado. Cuando `B` comprobó,
el pedido de `A` no estaba confirmado: las dos vieron cero pendientes y las dos insertaron.

🗣️ **2 minutos** — Es el sesgo de escritura de `04/02`: dos decisiones válidas por separado que
juntas rompen la regla. El tercer intento, en serie, sí falló, así que la regla pasa todas las
pruebas de una sesión.

🔬 **El detalle** — **Motor**. Toda regla que un disparador comprueba mirando otras filas tiene esta
carrera.

---

**02 → 12.** ¿Cómo corrige `FOR UPDATE` sobre la fila del cliente la carrera, y qué cuesta? 🟠

⏱️ **30 segundos** — Bloquea la fila del cliente antes de comprobar, así que la segunda sesión
espera a que la primera confirme; al seguir, su comprobación ya ve el pedido y falla.

🗣️ **2 minutos** — Cuesta que dos pedidos del mismo cliente ya no se insertan a la vez; los de
clientes distintos, sí. La alternativa es `SERIALIZABLE`, que aborta una de las dos y obliga a
reintentar.

🔬 **El detalle** — Es el bloqueo pesimista de `04/05`, puesto dentro del disparador.

---

**02 → 13.** ¿Qué restricción cumpliría la regla de §5 sin disparador? 🟠

⏱️ **30 segundos** — Un índice único parcial sobre `cliente_id` con `WHERE estado = 'PENDIENTE'`: no
puede haber dos filas pendientes del mismo cliente, y el motor lo garantiza con concurrencia.

🗣️ **2 minutos** — Antes hay que corregir los clientes que ya la incumplen, como `CLI-00311` con
seis. Y la segunda inserción concurrente espera a la primera y falla con clave duplicada, sin
carrera.

🔬 **El detalle** — Si la regla cabe en una restricción, va en una restricción.

---

**02 → 14.** ¿Por qué un disparador complica diagnosticar una lentitud? 🟠

⏱️ **30 segundos** — Porque la sentencia que tarda no dice que dispara otra cosa: el `UPDATE` de
líneas tardó 8,4 veces más y quien lo lanza solo ve su `UPDATE`.

🗣️ **2 minutos** — `EXPLAIN (ANALYZE)` muestra el tiempo de cada disparador al final, en una línea
`Trigger` por disparador, pero hay que saber mirarlo. Los disparadores encadenados lo complican más.

🔬 **El detalle** — Por eso se documentan junto a la tabla y se revisan con cada migración.

---

**02 → 15.** ¿Qué pasa con las reglas de un disparador durante una carga masiva que los apaga? 🟠

⏱️ **30 segundos** — Que no se cumplen: lo cargado no pasa por la auditoría, ni recalcula totales,
ni comprueba la regla. Las herramientas de carga y réplica los apagan precisamente para no pagarlos.

🗣️ **2 minutos** — Hay que revalidar después: recalcular los totales en bloque, comprobar la regla
con una consulta, y registrar la carga en la auditoría a mano.

🔬 **El detalle** — Es otra razón para preferir restricciones, que no se apagan con el disparador.

---

**02 → 16.** Diseña la auditoría de `pedidos`: qué guardas, con qué granularidad y qué coste
aceptas. 🔴

⏱️ **30 segundos** — Un disparador `AFTER` por sentencia con tablas de transición, que guarda quién,
cuándo, la operación y solo las columnas cambiadas, en una tabla aparte particionada por mes.

🗣️ **2 minutos** — Por sentencia ahorra las llamadas; guardar solo lo cambiado reduce la escritura,
que es la mayor parte del coste —2,4 veces el `UPDATE` con filas enteras—. Particionar por mes
permite borrar lo viejo con un `DROP`. Se acepta ese coste porque nadie debe poder saltarse la
auditoría.

🔬 **El detalle** — El usuario de la base suele ser el de la aplicación; el usuario real hay que
pasarlo en un parámetro de sesión.

---

**02 → 17.** Diagnostica: un proceso nocturno que actualiza el precio de 200 000 líneas pasó de un
minuto a ocho tras un despliegue en el que nadie tocó ese proceso. 🔴

⏱️ **30 segundos** — El despliegue añadió un disparador en `pedido_lineas`, probablemente uno que
recalcula el total del pedido: el coste medido fue 8,4 veces, y aquí es ocho.

🗣️ **2 minutos** — Lo confirmaría listando los disparadores de la tabla y con `EXPLAIN (ANALYZE)`
del `UPDATE`, que da el tiempo de cada uno. Corrección: disparador por sentencia que recalcule cada
pedido una vez, o apagarlo durante el proceso y recalcular en bloque al final.

🔬 **El detalle** — Lo que se evalúa es buscar el efecto invisible antes que culpar a los datos.

---

**02 → 18.** Defiende o refuta mantener `pedidos.total` con un disparador en la tienda, con los
números del capítulo. 🔴

⏱️ **30 segundos** — Se defiende con condiciones. El total se lee mucho más de lo que cambian las
líneas, y el disparador garantiza que cuadra venga el cambio de donde venga. A cambio, tocar líneas
cuesta 8,4 veces más por fila.

🗣️ **2 minutos** — Con disparador por sentencia, cada pedido se recalcula una vez. Si hay procesos
masivos sobre líneas, se apaga durante ellos y se recalcula al final. La alternativa, calcular el
total al leer, cuesta un `JOIN` en cada lectura.

🔬 **El detalle** — Lo que se evalúa es comparar el coste de escribir con el de leer, medidos.

---

## Capítulo 03 — Claves generadas

Las 18 preguntas de [`03`](03-claves-generadas.md).

**03 → 1.** ¿Qué es una secuencia, y qué es una columna `IDENTITY`? 🟢

⏱️ **30 segundos** — Una secuencia es un objeto que reparte números crecientes con `nextval`. Una
columna `IDENTITY` ata una secuencia a una tabla, de la forma que define el estándar.

🗣️ **2 minutos** — `pedidos.id` es `GENERATED ALWAYS AS IDENTITY`. `pg_get_serial_sequence` da el
nombre de la secuencia de debajo, y `setval` la mueve.

🔬 **El detalle** — **Estándar** `IDENTITY`; el `serial` de PostgreSQL es una abreviatura propia,
anterior.

---

**03 → 2.** ¿Qué diferencia `GENERATED ALWAYS` de `GENERATED BY DEFAULT`? 🟢

⏱️ **30 segundos** — `BY DEFAULT` usa la secuencia solo si no se da valor; `ALWAYS` rechaza el valor
dado, salvo con `OVERRIDING SYSTEM VALUE`.

🗣️ **2 minutos** — Con `BY DEFAULT`, insertar el 5 a mano desincronizó la secuencia. Con `ALWAYS`,
el `INSERT` con `id` dio error y sugirió `OVERRIDING SYSTEM VALUE`.

🔬 **El detalle** — **Estándar**. `ALWAYS` es la opción que evita la desincronización.

---

**03 → 3.** ¿Qué diferencia un UUIDv4 de un UUIDv7? 🟢

⏱️ **30 segundos** — El v4 es aleatorio. El v7 empieza por una marca de tiempo en milisegundos y
sigue con bits aleatorios, así que los generados después son mayores.

🗣️ **2 minutos** — Esa diferencia decide el índice: el v4 cae en cualquier hoja y la parte; el v7
cae al final, como un entero. Los dos miden 16 bytes.

🔬 **El detalle** — Los define la RFC 9562; PostgreSQL 18 trae `uuidv4()` y `uuidv7()`.

---

**03 → 4.** ¿Qué es el `rowid` de SQLite? 🟢

⏱️ **30 segundos** — El identificador entero de cada fila en una tabla de SQLite. Una columna
`INTEGER PRIMARY KEY` es un alias de él, y la tabla se guarda ordenada por él.

🗣️ **2 minutos** — El siguiente valor es normalmente el mayor en uso más uno, así que tras borrar el
3, la fila nueva recibió otra vez el 3.

🔬 **El detalle** — **Motor**. `WITHOUT ROWID` cambia el modelo, como vio `03/01` §7.

---

**03 → 5.** ¿Por qué un `ROLLBACK` deja un hueco en la secuencia? ¿Lo fija el estándar o es cosa del
motor? 🟡

⏱️ **30 segundos** — Porque `nextval` no se deshace: el número se reparte sin esperar a saber si la
transacción confirma. Si esperara, cada `INSERT` esperaría al anterior.

🗣️ **2 minutos** — La sesión dio 1, 2, 4, y MySQL lo mismo con `AUTO_INCREMENT`. Un `INSERT` que
falla por clave duplicada también gasta número: `cinco` recibió el 6.

🔬 **El detalle** — **Motor**: la documentación dice que abortos y caídas dejan huecos.

---

**03 → 6.** ¿Cómo se desincroniza una secuencia, y cómo se arregla? 🟡

⏱️ **30 segundos** — Insertando valores a mano sin pasar por ella: la secuencia no se entera, y
cuando llega a ese número, choca. Se arregla con `setval` al máximo de la tabla.

🗣️ **2 minutos** — Pasa tras importaciones y restauraciones parciales. En la sesión, el 5 a mano
hizo fallar el siguiente `INSERT`; `setval(…, max(id))` la dejó en 6.

🔬 **El detalle** — Con `GENERATED ALWAYS` no puede pasar sin una orden explícita.

---

**03 → 7.** ¿Qué hace `AUTOINCREMENT` en SQLite, y por qué su documentación dice que casi nunca hace
falta? 🟡

⏱️ **30 segundos** — Impide reutilizar identificadores: guarda el máximo usado en una tabla interna
y no lo repite, aunque se borre la fila. Con él, la fila nueva recibió el 4.

🗣️ **2 minutos** — La documentación advierte de que cuesta CPU, memoria, disco y E/S, y de que
normalmente no hace falta, porque sin él ya se genera un valor sin usar.

🔬 **El detalle** — Hace falta cuando el identificador sale de la base y no puede volver a significar
otra cosa.

---

**03 → 8.** ¿Qué miden `avg_leaf_density` y `leaf_fragmentation`? ¿Lo fija el estándar o es cosa del
motor? 🟡

⏱️ **30 segundos** — La densidad es cuánto de cada hoja del índice está ocupado; la fragmentación,
cuántas hojas no siguen el orden físico del fichero.

🗣️ **2 minutos** — `bigint` y UUIDv7 dieron 90 % y 0 %; UUIDv4, 71 % y casi 50 %. Hojas a medio
llenar son más páginas que leer y guardar; fuera de orden, recorridos más caros.

🔬 **El detalle** — **Motor**: `pgstatindex`, de la extensión `pgstattuple`, lee el índice entero.

---

**03 → 9.** ¿Qué hace `UUID_TO_BIN(UUID(), 1)` en MySQL? 🟡

⏱️ **30 segundos** — Convierte un UUID de texto a 16 bytes y, con el segundo argumento a 1, reordena
sus partes para que la de tiempo vaya delante. `UUID()` es versión 1, basada en el tiempo, así que
el resultado crece.

🗣️ **2 minutos** — Tardó lo mismo que `AUTO_INCREMENT`, 1,55 s, y solo pagó el ancho: 20,6 MB frente
a 16,5. Es la forma de tener un UUID ordenado en MySQL sin UUIDv7.

🔬 **El detalle** — **Motor**, según su manual. `BIN_TO_UUID(…, 1)` deshace el reordenado.

---

**03 → 10.** ¿Por qué el índice de UUIDv4 ocupó 38 MB y el de `bigint` 21, si la tabla tenía las
mismas filas? 🟠

⏱️ **30 segundos** — Por dos razones, casi a medias: el UUID mide 16 bytes y el `bigint` 8, y los
valores aleatorios parten hojas, que quedan al 71 %.

🗣️ **2 minutos** — El UUIDv7, del mismo ancho y creciente, ocupó 30: esos 9 MB son el ancho. Los 8
restantes hasta 38 son las hojas partidas.

🔬 **El detalle** — Y se midió con el índice en memoria; sin ella, la diferencia crece.

---

**03 → 11.** ¿Por qué UUIDv7 recuperó la densidad pero no el tamaño del `bigint`? 🟠

⏱️ **30 segundos** — Porque la densidad depende del orden, y el v7 crece como un entero: hojas al 90
% y ninguna fuera de orden. El tamaño depende del ancho, y el v7 sigue midiendo 16 bytes.

🗣️ **2 minutos** — 30 MB frente a 21, y 1,75 s frente a 1,09. Es el coste irreducible de un UUID.

🔬 **El detalle** — Por eso, si la clave no tiene que generarse fuera de la base, el `bigint` sigue
siendo más barato.

---

**03 → 12.** ¿Por qué la carga con UUIDv4 escribió más WAL? 🟠

⏱️ **30 segundos** — Porque tras un `CHECKPOINT`, la primera modificación de cada página se escribe
entera en el WAL, y el v4, al caer en hojas al azar, toca muchas más páginas distintas.

🗣️ **2 minutos** — 162 MB frente a 135 del `bigint` y 149 del v7. Más WAL es más disco, más réplica
y más copia de seguridad.

🔬 **El detalle** — Son las escrituras de página completa de `04/06`.

---

**03 → 13.** ¿Por qué en InnoDB el índice secundario sobre un `INT` engordó al cambiar la clave
primaria? 🟠

⏱️ **30 segundos** — Porque cada entrada de un índice secundario de InnoDB lleva colgada la clave
primaria entera. Con 16 bytes en vez de 8, pasó de 15,5 a 24,6 MB.

🗣️ **2 minutos** — Es la regla de `03/01` medida: clave estrecha y creciente. Con varios índices
secundarios, cada uno paga el ancho de la clave.

🔬 **El detalle** — **Motor**, de InnoDB. En PostgreSQL, los índices secundarios apuntan a la fila,
no a la clave.

---

**03 → 14.** ¿Qué riesgo tiene que SQLite reutilice el identificador de una fila borrada? 🟠

⏱️ **30 segundos** — Que algo fuera de la base que guardaba el identificador —un enlace, una caché,
otra base— pase a apuntar a otra fila sin saberlo.

🗣️ **2 minutos** — Tras borrar el 3, la fila nueva recibió el 3. Dentro de la base, con claves
foráneas, no pasa nada; fuera, es un error silencioso.

🔬 **El detalle** — `AUTOINCREMENT` lo evita, a su coste.

---

**03 → 15.** Contabilidad pregunta por qué faltan números de pedido. ¿Qué respondes, y qué harías si
necesitan una numeración sin huecos? 🟠

⏱️ **30 segundos** — Que es por diseño: cada transacción deshecha o fallida gasta un número, y la
secuencia no lo devuelve para no bloquear. No falta ningún pedido.

🗣️ **2 minutos** — Para facturas sin huecos, otra columna, asignada al confirmar con un contador en
una fila que se bloquea. Cuesta serializar las inserciones que lo usan, y por eso no es la clave.

🔬 **El detalle** — Lo que se evalúa es separar identificador técnico de numeración de negocio.

---

**03 → 16.** Diseña las claves de pedidos para una aplicación móvil que crea pedidos sin conexión y
los sincroniza después. 🔴

⏱️ **30 segundos** — UUIDv7 generado en el móvil como identificador del pedido, porque tiene que
existir antes de llegar a la base, y crece como un entero. Un código de negocio legible, asignado al
sincronizar.

🗣️ **2 minutos** — El v7 evita el desorden del v4: 30 MB frente a 38 en el índice. Si el móvil tiene
el reloj mal, el orden se resiente pero no la unicidad. En InnoDB, el mismo diseño con 16 bytes
ordenados.

🔬 **El detalle** — El reintento de sincronización es idempotente porque el identificador lo trae el
propio pedido.

---

**03 → 17.** Diagnostica: tras restaurar una copia parcial de `pedidos`, cada pedido nuevo falla con
clave duplicada durante un rato y después vuelve a funcionar. 🔴

⏱️ **30 segundos** — La secuencia quedó por detrás de los identificadores restaurados. Cada `INSERT`
choca con uno existente y gasta un número; cuando la secuencia supera el máximo restaurado, vuelve a
funcionar.

🗣️ **2 minutos** — Es la desincronización de §2, con muchos valores. Corrección: `setval` al máximo
en cuanto se restaura. Mientras tanto, los pedidos que fallaron se perdieron o hay que
reintentarlos.

🔬 **El detalle** — Una restauración completa lleva la secuencia; una parcial, por tablas o con
`COPY`, no.

---

**03 → 18.** Defiende o refuta pasar las claves de la tienda de `bigint` a UUIDv4, con los números
del capítulo. 🔴

⏱️ **30 segundos** — Se refuta. Con un millón de filas, el UUIDv4 tardó 2,8 s frente a 1,1, su
índice ocupó 38 MB frente a 21 con las hojas al 71 %, y escribió más WAL. Y la tienda no necesita
generar claves fuera de la base.

🗣️ **2 minutos** — Si llegara a necesitarlo, UUIDv7: 1,8 s y 30 MB, sin desorden. En MySQL, la clave
aleatoria duplicó la tabla y engordó el índice secundario. Y cambiar la clave después obliga a
reescribir la tabla y todas las claves foráneas.

🔬 **El detalle** — Lo que se evalúa es no confundir «moderno» con barato.

---

## Simulación de entrevista

Las 24 preguntas `S#` y los cuatro escenarios de [`04`](04-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**04 → S1.** ¿Qué diferencia una función de un procedimiento, y qué puede hacer el segundo que la
primera no? 🟢

⏱️ **30 segundos** — La función devuelve un valor y se llama dentro de una consulta; el
procedimiento se llama con `CALL` y no devuelve valor. Lo que solo puede el procedimiento es
confirmar o deshacer transacciones a mitad de camino.

🗣️ **2 minutos** — `anular_por_lotes` confirmó cuatro lotes, 1 000, 1 000, 1 000 y 804. Una función
no puede: toda ella corre dentro de la transacción de quien la llama.

🔬 **El detalle** — **Motor**. SQLite no tiene ninguno de los dos en SQL: registra funciones desde la
aplicación.

---

**04 → S2.** Una función sencilla en SQL y otra en PL/pgSQL hacen lo mismo. ¿Por qué solo la segunda
puede hundir un plan? 🟡

⏱️ **30 segundos** — Porque la función en SQL de una expresión se integra en la consulta: el
planificador ve la expresión y la calcula antes. La de PL/pgSQL es una caja negra, y su volatilidad
decide si puede usarse en la condición de un índice.

🗣️ **2 minutos** — La función SQL dio el mismo `Index Scan` con o sin `IMMUTABLE`. La PL/pgSQL
`VOLATILE` dio un `Seq Scan` de 414 ms.

🔬 **El detalle** — **Motor**, el *inlining* de PostgreSQL.

---

**04 → S3.** Explica la trampa de la volatilidad con la sesión: qué plan salió con `VOLATILE` y cuál
con `STABLE`. 🟠

⏱️ **30 segundos** — Con `VOLATILE`, `Seq Scan` de un millón de filas, llamando a la función en cada
una: 414 ms. Con `STABLE`, `Index Scan` con la función en la condición: 0,037 ms.

🗣️ **2 minutos** — `VOLATILE` es lo de defecto: el motor no puede suponer que devuelve lo mismo, así
que no puede calcularla una vez para buscar en el índice. Una palabra en la declaración, once mil
veces de diferencia.

🔬 **El detalle** — Y el error contrario, declarar `IMMUTABLE` lo que lee una tabla, da resultados
incorrectos sin avisar.

---

**04 → S4.** ¿Cuánto costaron las idas y vueltas al anular 10 929 pedidos, y qué forma fue la más
rápida? 🟠

⏱️ **30 segundos** — Desde el cliente, una sentencia por fila: 21 858 sentencias y 6,2 s. En un
bucle PL/pgSQL: 888 ms. En una sola sentencia con `UPDATE … RETURNING` alimentando el `INSERT`: 470
ms, la más rápida.

🗣️ **2 minutos** — El cliente solo trabajó medio segundo; el resto fue esperar respuestas. La
función ahorra los viajes; la sentencia ahorra además el trabajo por fila.

🔬 **El detalle** — Lo que se evalúa es ver que la mayor parte del ahorro no pide una función.

---

**04 → S5.** ¿Por qué un bloque `EXCEPTION` cuesta aunque no salte ningún error? 🟡

⏱️ **30 segundos** — Porque cada entrada en el bloque abre una subtransacción, para poder deshacer
lo que haga si falla. En un bucle de 200 000 vueltas, de 14 a 66 ms.

🗣️ **2 minutos** — La documentación lo dice: es «significativamente más caro» de abrir y cerrar. Se
captura fuera del bucle, o se comprueba antes en vez de capturar.

🔬 **El detalle** — **Motor**.

---

**04 → S6.** ¿Por qué un procedimiento que confirma por lotes puede fallar al llamarlo desde una
aplicación? 🟠

⏱️ **30 segundos** — Porque solo puede confirmar si se le llama desde el nivel superior, sin una
transacción abierta. Muchas aplicaciones envuelven cada llamada en una, y el `COMMIT` falla con
`invalid transaction termination`.

🗣️ **2 minutos** — Se reprodujo con `BEGIN` antes del `CALL`. La conexión que lo llame tiene que
estar en confirmación automática.

🔬 **El detalle** — **Motor**: la documentación acota dónde es posible el control de transacciones.

---

**04 → S7.** ¿Dónde programarías la anulación nocturna de pedidos, y por qué no dentro de la base? 🟡

⏱️ **30 segundos** — Fuera, en el programador de la plataforma o en `cron`, que lanza un
procedimiento por lotes. Fuera se versiona, se monitoriza y se reintenta como el resto del código.

🗣️ **2 minutos** — MySQL trae `EVENT` encendido, y ejecutó la tarea tres veces en doce segundos;
pero un fallo solo queda en el registro del servidor. PostgreSQL necesita `pg_cron`, que la imagen
no trae.

🔬 **El detalle** — Mantenimiento puro de la base sí puede vivir dentro.

---

**04 → S8.** Da los tres usos legítimos de un disparador y el coste medido de dos de ellos. 🟡

⏱️ **30 segundos** — Auditoría, desnormalización e integridad que una restricción no expresa. La
auditoría por fila multiplicó por 2,4 el `UPDATE` de 100 000 pedidos; mantener el total, por 8,4 el
de 35 000 líneas.

🗣️ **2 minutos** — Los tres comparten la razón de ser: se cumplen venga el cambio de donde venga,
también desde la consola. Y el mismo defecto: son invisibles para quien lanza la sentencia.

🔬 **El detalle** — La integridad, además, necesita bloqueo para ser segura con concurrencia.

---

**04 → S9.** Fila o sentencia: ¿qué ahorra un disparador por sentencia y qué no? 🟠

⏱️ **30 segundos** — Ahorra las llamadas a la función: una en vez de 100 000. No ahorra escribir las
100 000 filas de auditoría, que es la mayor parte del coste: 1 861 ms frente a 2 119.

🗣️ **2 minutos** — Con tablas de transición, la función ve todas las filas cambiadas y hace una sola
inserción. Gana más cuando la función por fila hace consultas propias.

🔬 **El detalle** — Solo PostgreSQL lo tiene entre los motores del curso.

---

**04 → S10.** ¿Por qué mantener un total con un disparador cuesta más de lo que parece? 🟠

⏱️ **30 segundos** — Porque cada línea recalcula su pedido entero, y un pedido tiene varias líneas:
se recalcula y reescribe tres veces y media. De 116 ms a 982.

🗣️ **2 minutos** — Cada reescritura deja una versión muerta de la fila del pedido. Por sentencia se
recalcula cada pedido una sola vez.

🔬 **El detalle** — Es el precio de la desnormalización, pagado al escribir.

---

**04 → S11.** Una regla de integridad comprobada en un disparador pasa todas las pruebas y falla en
producción. ¿Por qué? 🔴

⏱️ **30 segundos** — Porque las pruebas son de una sesión, y en producción llegan dos a la vez. En
`READ COMMITTED` ninguna ve lo que la otra no ha confirmado, y las dos pasan la comprobación.

🗣️ **2 minutos** — Dos sesiones insertaron dos pedidos pendientes para `CLI-00007` sin un error; el
tercer intento, en serie, sí falló. Se corrige bloqueando la fila del cliente con `FOR UPDATE`, con
`SERIALIZABLE`, o mejor con un índice único parcial, que el motor hace seguro.

🔬 **El detalle** — Es el sesgo de escritura de `04/02`.

---

**04 → S12.** ¿Qué motores del curso tienen disparadores por sentencia? 🟢

⏱️ **30 segundos** — Solo PostgreSQL. MySQL dio error 1064 y SQLite error de sintaxis con
`FOR EACH STATEMENT`.

🗣️ **2 minutos** — En MySQL y SQLite, toda la lógica del disparador corre una vez por fila.

🔬 **El detalle** — El estándar define las dos granularidades.

---

**04 → S13.** ¿En qué orden se ejecutan dos disparadores del mismo evento en PostgreSQL y en
MySQL? 🟡

⏱️ **30 segundos** — En PostgreSQL, por orden alfabético de nombre. En MySQL se fija al crearlos,
con `FOLLOWS` y `PRECEDES`.

🗣️ **2 minutos** — En PostgreSQL, renombrar un disparador puede cambiar el resultado, y es un orden
que nadie recuerda.

🔬 **El detalle** — **Motor**, los dos.

---

**04 → S14.** ¿Por qué una secuencia tiene huecos, y por qué no es un error? 🟢

⏱️ **30 segundos** — Porque `nextval` no se deshace: el número se reparte sin esperar a saber si la
transacción confirma. Un `ROLLBACK` dejó el hueco del 3, en PostgreSQL y en MySQL.

🗣️ **2 minutos** — Si esperara, cada inserción esperaría a la anterior. Un `INSERT` fallido también
gasta número.

🔬 **El detalle** — **Motor**: la documentación de PostgreSQL lo avisa.

---

**04 → S15.** ¿Cómo se desincroniza una secuencia, y qué opción de `IDENTITY` lo impide? 🟡

⏱️ **30 segundos** — Insertando valores a mano, que la secuencia no ve: al llegar a ese número,
choca. `GENERATED ALWAYS` rechaza el valor a mano, salvo con `OVERRIDING SYSTEM VALUE`.

🗣️ **2 minutos** — Con `BY DEFAULT`, el 5 a mano hizo fallar el siguiente `INSERT`, y se arregló con
`setval` al máximo.

🔬 **El detalle** — **Estándar** `IDENTITY`.

---

**04 → S16.** ¿Qué hace SQLite con el identificador de una fila borrada? 🟡

⏱️ **30 segundos** — Sin `AUTOINCREMENT`, puede reutilizarlo: tras borrar la 3, la fila nueva
recibió el 3. Con `AUTOINCREMENT`, el 4.

🗣️ **2 minutos** — El siguiente valor es normalmente el mayor en uso más uno. Si algo fuera de la
base guardaba el 3, ahora apunta a otra fila.

🔬 **El detalle** — **Motor**; su documentación dice que `AUTOINCREMENT` casi nunca hace falta.

---

**04 → S17.** UUIDv4 frente a UUIDv7 frente a `bigint`: las tres cifras que hay que saber. 🟠

⏱️ **30 segundos** — Para un millón de filas: 2,8 s, 1,8 s y 1,1 s de carga; índices de 38, 30 y
21 MB; hojas al 71 %, 90 % y 90 %.

🗣️ **2 minutos** — El v4 paga ancho y desorden; el v7, solo ancho. El v4 escribió además más WAL,
162 MB frente a 135.

🔬 **El detalle** — Con el índice en memoria; sin ella, la diferencia crece.

---

**04 → S18.** ¿Por qué en InnoDB una clave primaria aleatoria engorda también los índices
secundarios? 🟠

⏱️ **30 segundos** — Porque cada entrada de un índice secundario lleva la clave primaria entera. Con
16 bytes en vez de 8, el índice sobre un `INT` pasó de 15,5 a 24,6 MB.

🗣️ **2 minutos** — Y la tabla, que es el índice primario, pasó de 16,5 a 33,6 MB, porque las filas
se insertan en medio. Con UUID versión 1 reordenado, solo el ancho.

🔬 **El detalle** — Es la regla de `03/01`: clave estrecha y creciente.

---

**04 → S19.** ¿Cuándo sí usarías UUID como clave? 🟠

⏱️ **30 segundos** — Cuando la clave tiene que existir antes de llegar a la base —clientes sin
conexión, varios servicios generando— o cuando no se quiere publicar un número que dice cuántos hay.
Y entonces, UUIDv7.

🗣️ **2 minutos** — Con v7 se paga el ancho, 30 MB frente a 21, pero no el desorden. El v4, solo en
tablas pequeñas o como columna única aparte de una clave `bigint`.

🔬 **El detalle** — Lo que se evalúa es que el motivo sea dónde nace la clave, no la moda.

---

**04 → S20.** «Los procedimientos almacenados son una mala práctica». ¿Qué parte es cierta? 🟠

⏱️ **30 segundos** — Es cierta para la lógica de negocio que cambia a menudo: se prueba, versiona y
despliega peor dentro de la base, y ata la aplicación a un motor. No lo es para el trabajo sobre
muchas filas ni para los procesos por lotes que confirman a trozos.

🗣️ **2 minutos** — Anular 10 929 pedidos fue 6,2 s desde el cliente y 888 ms en PL/pgSQL. El péndulo
ha ido y ha vuelto; la respuesta es un criterio, no una regla.

🔬 **El detalle** — **Convención**.

---

**04 → S21.** «La lógica en la base es más rápida». Matízalo con los números del bloque. 🟠

⏱️ **30 segundos** — Es más rápida en viajes: 888 ms frente a 6,2 s. Pero un bucle fila a fila en la
base es más lento que la sentencia por conjuntos, 888 ms frente a 470.

🗣️ **2 minutos** — Y una función mal declarada puede ser once mil veces más lenta que no tenerla. La
velocidad sale de mandar menos sentencias y de declarar bien, no de dónde vive el código.

🔬 **El detalle** — Lo que se evalúa es no quedarse con la mitad cierta.

---

**04 → S22.** «Con un disparador, la regla se cumple siempre». Refútalo. 🔴

⏱️ **30 segundos** — Dos sesiones a la vez insertaron dos pedidos pendientes para el mismo cliente,
con un disparador que lo prohibía. En `READ COMMITTED` ninguna vio lo de la otra.

🗣️ **2 minutos** — Además, las cargas masivas apagan los disparadores, y durante ellas la regla no
se cumple. Una restricción, como un índice único parcial, no tiene ninguno de los dos problemas.

🔬 **El detalle** — El disparador se cumple siempre que se ejecuta; lo que no garantiza es que lo que
comprueba siga siendo cierto al confirmar.

---

**04 → S23.** «Los huecos en los números de pedido indican pedidos perdidos». Corrígelo. 🟡

⏱️ **30 segundos** — Los huecos son por diseño: cada transacción deshecha o `INSERT` fallido gasta
un número que no se devuelve. No falta ningún pedido.

🗣️ **2 minutos** — Si el negocio necesita numeración sin huecos, como las facturas, es otra columna,
asignada con un contador bloqueado al confirmar, que serializa.

🔬 **El detalle** — Identificador técnico y numeración de negocio son dos cosas.

---

**04 → S24.** «UUID es la clave moderna; `bigint` es de otra época». Refútalo con números. 🔴

⏱️ **30 segundos** — Un millón de UUIDv4 tardaron 2,8 s frente a 1,1 del `bigint`, con un índice de
38 MB frente a 21 y las hojas al 71 %. En InnoDB, la clave aleatoria duplicó la tabla.

🗣️ **2 minutos** — UUIDv7 arregla el desorden, no el ancho: 1,8 s y 30 MB. Si la clave no tiene que
generarse fuera, el `bigint` sigue siendo más barato; si tiene que hacerlo, v7.

🔬 **El detalle** — «Moderno» no es un criterio; dónde nace la clave, sí.

---

**04 → E1.** Escenario 1 — El cierre de mes que tarda una hora

⏱️ **30 segundos** — La hora se va casi seguro en idas y vueltas: leer y escribir fila a fila desde
el servicio. Lo comprobaría con el tiempo de CPU del servicio frente al de reloj, y con las
sentencias por segundo en la base.

🗣️ **2 minutos** — Movería el cálculo a una sentencia por conjuntos, o a pocas, y solo si no cabe, a
un procedimiento por lotes que confirme cada mes o cada cliente, reanudable porque solo toca lo no
procesado. El orden y la monitorización quedan en el servicio. Mil líneas de procedimiento, no: lo
que cambia cada trimestre, como las comisiones, se prueba mejor fuera.

🔬 **El detalle** — Lo que se evalúa es medir antes de reescribir, y que la sentencia por conjuntos
aparezca antes que el procedimiento.

---

**04 → E2.** Escenario 2 — La auditoría que nadie se salta

⏱️ **30 segundos** — Un disparador `AFTER` por sentencia con tablas de transición, que guarda quién,
cuándo, la operación y solo las columnas cambiadas, en una tabla particionada por mes.

🗣️ **2 minutos** — Coste esperado: el doble de escritura; con filas enteras fue 2,4 veces. El
usuario real se pasa en un parámetro de sesión que la aplicación fija al tomar la conexión, y la
consola entra con usuarios nominales. En una carga masiva que apague disparadores, se registra la
carga como un evento aparte.

🔬 **El detalle** — Lo que se evalúa es que la auditoría no dependa de quien escribe, y conocer su
coste.

---

**04 → E3.** Escenario 3 — Pedidos duplicados en la campaña

⏱️ **30 segundos** — El primero es la carrera del disparador: en campaña hay inserciones simultáneas
del mismo cliente y en `READ COMMITTED` ninguna ve la otra. El segundo, una secuencia que quedó por
detrás de los identificadores restaurados.

🗣️ **2 minutos** — Lo reproduciría con dos sesiones y las transacciones abiertas a la vez.
Correcciones: bloquear la fila del cliente en el disparador, que serializa sus inserciones; o un
índice único parcial, más barato y sin carrera. Para la restauración, `setval` al máximo justo
después, dentro del procedimiento de restauración.

🔬 **El detalle** — Lo que se evalúa es reconocer que preproducción no tiene concurrencia, y que una
restauración parcial no lleva la secuencia.

---

**04 → E4.** Escenario 4 — «El sistema de facturación falla: pongamos las facturas en la base»

⏱️ **30 segundos** — No lo resuelve la base. La transacción de la base no alcanza al proveedor
externo: si la llamada va dentro, la transacción queda abierta esperando a la red, retiene bloqueos,
y si el proveedor firma y la base aborta, queda igual de a medias.

🗣️ **2 minutos** — El patrón es guardar la factura con estado `PENDIENTE_FIRMA` y un evento en la
misma transacción, y que un proceso aparte llame al proveedor y actualice el estado, con reintentos
idempotentes gracias a una clave de idempotencia. En la base sí caben el estado y la numeración sin
huecos, asignada al confirmar.

🔬 **El detalle** — Lo que se evalúa es no aceptar el marco: la consistencia con un sistema externo
se consigue con estados y reintentos idempotentes, no alargando una transacción.

---

**Volver:** [README del bloque](README.md).
