# 08 — Respuestas

> Solucionario del bloque **01 — Fundamentos y modelo relacional**: las 116 preguntas de los seis
> capítulos y las 28 preguntas `S#` más los cuatro escenarios de la simulación, con el enunciado
> copiado literalmente y la respuesta en tres capas.
>
> **Cómo se usa.** Responde primero en voz alta, con el cronómetro. La capa ⏱️ es lo que dices en
> los primeros treinta segundos; la 🗣️ es lo que añades cuando te dicen "cuéntame más"; la 🔬 es el
> matiz que casi nadie trae, y es donde vive la distinción entre **lo que manda el estándar, lo que
> hace tu motor y lo que es pura convención**.
>
> **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

- [Capítulo 01 — Qué resuelve un DBMS](#capítulo-01--qué-resuelve-un-dbms)
- [Capítulo 02 — El modelo relacional y sus claves](#capítulo-02--el-modelo-relacional-y-sus-claves)
- [Capítulo 03 — Álgebra relacional](#capítulo-03--álgebra-relacional)
- [Capítulo 04 — Normalización y desnormalización](#capítulo-04--normalización-y-desnormalización)
- [Capítulo 05 — Del modelo ER al esquema](#capítulo-05--del-modelo-er-al-esquema)
- [Capítulo 06 — Nulos y lógica de tres valores](#capítulo-06--nulos-y-lógica-de-tres-valores)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — Qué resuelve un DBMS

Las 18 preguntas de [`01`](01-que-resuelve-un-dbms.md).

**01 → 1.** **Nombra las cuatro garantías que un DBMS da y un fichero no. 🟢**

⏱️ **30 segundos** — Concurrencia arbitrada, integridad declarada, recuperación ante fallos y
consulta declarativa. Un fichero te da bytes en un orden; un DBMS te da hechos con reglas.

🗣️ **2 minutos** — La concurrencia es que muchos clientes pueden leer y escribir a la vez con reglas
definidas sobre qué ve cada uno. La integridad es que las restricciones del esquema se comprueban en
cada escritura venga de donde venga, no solo desde tu código. La recuperación es que lo confirmado
sobrevive a un corte y lo no confirmado no deja rastro. Y la consulta declarativa es que describes
el resultado y el motor elige la estrategia, que puede cambiar sin que tú toques nada.

🔬 **El detalle** — Las cuatro no son independientes: la recuperación se apoya en el mismo registro
secuencial —el WAL— que la concurrencia usa para las versiones. Y ninguna de las cuatro es gratis:
la concurrencia se paga en bloqueo, la integridad en tiempo por escritura, la recuperación en
latencia de `COMMIT` y lo declarativo en pérdida de control sobre el plan.

---

**01 → 2.** **¿Qué significa exactamente que una transacción esté confirmada? 🟢**

⏱️ **30 segundos** — Que los cambios están en el registro de escritura anticipada, en disco, y
sobrevivirán a un corte de corriente.

🗣️ **2 minutos** — No significa que estén en la tabla: el motor escribe primero en el WAL y aplica a
las páginas de datos cuando le conviene. Significa que si se va la luz un milisegundo después del
`COMMIT`, al arrancar el motor releerá el registro y dejará los datos como quedaron. Y significa que
otras transacciones ya pueden ver el cambio.

🔬 **El detalle** — Es **motor**, no estándar, cuánto aprieta esa garantía. En PostgreSQL la palanca
es `synchronous_commit`; en el entorno de este corpus está en `on`, que es el valor por defecto y el
que espera al `fsync`. Con `off`, el `COMMIT` responde antes de que el WAL esté en disco y se abre
una ventana de pérdida de unos cientos de milisegundos: los datos no se corrompen, pero las últimas
transacciones confirmadas pueden desaparecer.

---

**01 → 3.** **¿Qué es el WAL y para qué sirve? 🟢**

⏱️ **30 segundos** — Un registro secuencial donde el motor escribe qué va a hacer **antes** de tocar
la tabla. De ahí el nombre: *write-ahead log*.

🗣️ **2 minutos** — Sirve para dos cosas. La primera es recuperación: si el motor se cae a media
escritura, al arrancar relee el registro y rehace lo confirmado y deshace lo que no. La segunda es
rendimiento: escribir secuencialmente en un solo fichero es mucho más barato que salpicar escrituras
aleatorias por todas las páginas de todas las tablas, así que el motor confirma rápido y aplica a
las tablas después.

🔬 **El detalle** — Desde una sesión **no se observa su contenido**, solo que avanza:
`pg_current_wal_lsn()` pasó de `1/9341F048` a `1/9341F0C0` tras un `UPDATE` de una fila, 120 bytes.
Para ver qué hay dentro hace falta `pg_waldump` sobre los ficheros de `pg_wal`. En MySQL/InnoDB el
equivalente es el *redo log*, y además hay un *undo log* separado que PostgreSQL no tiene porque
guarda las versiones viejas en la propia tabla.

---

**01 → 4.** **¿Por qué una tabla no tiene orden de filas? 🟢**

⏱️ **30 segundos** — Porque el modelo relacional define una tabla como un conjunto, no como una
secuencia. Si quieres orden, lo pides con `ORDER BY`.

🗣️ **2 minutos** — Que a veces salgan en el orden en que las insertaste es una coincidencia del plan
que eligió el motor, no una garantía. En cuanto cambie el plan —porque aparezca un índice, porque
cambien las estadísticas, porque el motor decida paralelizar— el orden cambia. Y el orden físico
también se mueve solo: actualizar una fila en PostgreSQL escribe una versión nueva, que puede acabar
en otra página.

🔬 **El detalle** — Se ve con `ctid`, la dirección física `(página, posición)`. Para el cliente 26446
el corpus muestra `PED-00042` en la página 10 769 y `PED-03013` en la 67: el orden lógico por código
y el físico no tienen relación. Es **estándar**: la tabla como conjunto está en el modelo de Codd y
los tres motores lo respetan.

---

**01 → 5.** **¿Qué es una actualización perdida (*lost update*)? 🟢**

⏱️ **30 segundos** — Dos transacciones leen el mismo valor, cada una calcula el nuevo a partir de lo
que leyó, y la segunda en escribir pisa el cambio de la primera.

🗣️ **2 minutos** — Es el caso de los dos cajeros del capítulo: los dos leen un total de 3186.23, uno
aplica un pago de 10 y el otro de 20, y el total final es 3206.23. Se cobraron 30 y el pedido
refleja 20. Lo importante es que ninguna de las dos transacciones falló ni se corrompió nada: el
motor hizo exactamente lo que le pidieron.

🔬 **El detalle** — El problema es el patrón *leer, calcular fuera, escribir*. Si el cálculo ocurre
dentro del motor —`SET total = total + 10`— no hay pérdida, porque el `UPDATE` toma el bloqueo de
fila y lee el valor vigente. Es **estándar**: ISO/IEC 9075 lo reconoce como fenómeno, y **motor**
cuál es el nivel de aislamiento por defecto que lo permite. Ni `READ COMMITTED` de PostgreSQL ni
`REPEATABLE READ` de InnoDB lo evitan en este patrón.

---

**01 → 6.** **Diferencia entre que el motor impida la corrupción y que garantice que el dato sea
correcto. 🟡**

⏱️ **30 segundos** — La corrupción es que la fila quede a medias o ilegible; eso el motor lo impide
siempre. Que el número sea el correcto depende de qué garantía le pediste.

🗣️ **2 minutos** — En la sesión de los dos cajeros no hubo corrupción de ninguna clase: las dos
transacciones fueron atómicas, las dos confirmaron, la fila quedó perfectamente escrita. Y el total
está mal. El motor cumplió su contrato al pie de la letra; el contrato no incluía "y además que la
aritmética entre transacciones tenga sentido". Esa parte se pide con el nivel de aislamiento
adecuado, con un bloqueo explícito o moviendo el cálculo dentro del `UPDATE`.

🔬 **El detalle** — Esta distinción es la que separa una respuesta de entrevista de una recitada. La
forma corta de decirlo: **un DBMS te da garantías concretas que hay que pedir por su nombre; lo que
no pides, no lo tienes**. Es también la razón de que "usar una base de datos" no aparezca en ninguna
lista de garantías.

---

**01 → 7.** **¿En qué se diferencia una restricción declarada en el esquema de la misma comprobación
escrita en el código de la aplicación? 🟡**

⏱️ **30 segundos** — La del esquema se cumple siempre. La del código se cumple solo donde pasa ese
código.

🗣️ **2 minutos** — Los datos de una tabla de producción no entran únicamente por tu servicio: entran
por el script de migración, por la carga nocturna, por el job de conciliación, por el compañero con
`psql` abierto y por el servicio nuevo que escribió otro equipo. Cada uno de esos caminos tendría
que repetir la validación, y basta que uno se la salte para que el dato malo entre. Declarada en el
esquema, la comprobación está en un único sitio y no se puede rodear.

🔬 **El detalle** — El coste es real y hay que nombrarlo: cada clave foránea obliga a una búsqueda en
la tabla padre por cada inserción y toma un bloqueo compartido sobre la fila referenciada. Por eso
en cargas masivas se apagan, se carga y se vuelven a encender comprobando —exactamente lo que hace
la semilla de este corpus—. Lo que no es defendible es quitarlas *permanentemente* por rendimiento.

---

**01 → 8.** **`NULL`, cadena vacía y cero: ¿por qué no son lo mismo? 🟡**

⏱️ **30 segundos** — `NULL` significa *desconocido*. La cadena vacía y el cero son valores conocidos
que resultan ser vacío y cero.

🗣️ **2 minutos** — Un `pagos.referencia` nulo dice "este pago fue en efectivo, no hay referencia de
proveedor". Una cadena vacía diría "hay referencia, y es la cadena vacía", que es otra cosa y además
chocaría contra el `UNIQUE` en cuanto hubiera dos. Un `pedidos.actualizado_en` nulo dice "nadie lo
ha tocado nunca", que no es lo mismo que una fecha cualquiera.

🔬 **El detalle** — La consecuencia operativa es que `NULL` no se compara con `=` sino con `IS NULL`,
que `NULL = NULL` da *desconocido* y no *verdadero*, y que varios `NULL` conviven bajo una
restricción `UNIQUE` sin violarla: en este corpus hay 273 126 pagos con `referencia` nula bajo un
`UNIQUE`. Es **estándar** —la lógica de tres valores está en ISO/IEC 9075— y los tres motores
coinciden. El desarrollo entero es de `01/06`, que es su dueño.

---

**01 → 9.** **¿Qué quiere decir que SQL sea declarativo, y qué pierdes a cambio? 🟡**

⏱️ **30 segundos** — Que describes el resultado que quieres, no el algoritmo para obtenerlo. A
cambio pierdes el control sobre cómo se ejecuta.

🗣️ **2 minutos** — Dos consultas parecidas del capítulo producen estrategias completamente distintas
que nadie pidió: contar los pedidos ANULADOS acabó en un barrido secuencial que descarta 940 000
filas, y contar los pedidos de un cliente acabó en una tabla hash alimentada por un índice. El motor
decide con las estadísticas que tiene en ese momento. La contrapartida es que la misma consulta, con
los mismos datos, puede cambiar de plan mañana.

🔬 **El detalle** — Es **estándar** el lenguaje —`SELECT`, `JOIN`, `COUNT`— y **motor** absolutamente
todo lo demás: los nodos del plan, sus nombres, la sintaxis de `EXPLAIN` y los criterios de
elección. Los planes de PostgreSQL y de MySQL no son comparables nodo a nodo. Y el modo de fallo
típico es el que hay que reconocer: una consulta que iba a 50 ms pasa a 8 segundos sin que nadie
tocara el código, porque las estadísticas envejecieron y el planificador cambió de idea.

---

**01 → 10.** **¿El nivel de aislamiento por defecto lo fija el estándar o cada motor? Di cuál usan
PostgreSQL y MySQL. 🟠**

⏱️ **30 segundos** — Lo fija cada motor. El estándar define los cuatro niveles y qué fenómeno
permite cada uno, pero no cuál es el defecto.

🗣️ **2 minutos** — PostgreSQL arranca en `READ COMMITTED` y MySQL con InnoDB en `REPEATABLE READ`.
Es una de las diferencias que más sorprenden al portar una aplicación de un motor al otro, porque
cambia qué ve una transacción larga sin que nadie haya escrito una línea distinta. Y ninguno de los
dos, por defecto, evita la actualización perdida del patrón leer-calcular-escribir.

🔬 **El detalle** — Hay una capa más de matiz, y es la que sube la nota: **`REPEATABLE READ` no
significa lo mismo en los dos motores**. El de PostgreSQL es *snapshot isolation* y evita las
lecturas fantasma, aunque no el *write skew*; el de InnoDB las evita con *gap locks*, que no están
en el estándar. Y SQLite es `SERIALIZABLE` de facto porque solo admite un escritor a la vez. El
desarrollo completo pertenece al bloque de transacciones.

---

**01 → 11.** **¿El estándar SQL obliga a que un `ALTER TABLE` se pueda deshacer con `ROLLBACK`? ¿Qué
hace cada motor? 🟠**

⏱️ **30 segundos** — No lo obliga: el estándar no exige DDL transaccional. PostgreSQL y SQLite sí lo
permiten; MySQL no.

🗣️ **2 minutos** — En PostgreSQL un `ALTER TABLE` dentro de un `BEGIN` desaparece con el `ROLLBACK`:
la comprobación en `information_schema.columns` devuelve 0 columnas tras deshacer. En MySQL el mismo
`ALTER` provoca una confirmación implícita antes de ejecutarse, así que cuando llega el `ROLLBACK`
ya no hay nada que deshacer y la columna sigue ahí.

🔬 **El detalle** — La consecuencia práctica es grande y se pregunta: **una migración de esquema que
falla a la mitad deja a MySQL en un estado intermedio y a PostgreSQL intacto**. Por eso las
herramientas de migración se comportan tan distinto en uno y otro, y por eso en MySQL cada paso de
una migración tiene que ser reversible por sí mismo. La lista de sentencias que causan confirmación
implícita está en la documentación de MySQL 9.7.

---

**01 → 12.** **En la sesión de §2 ninguna de las dos transacciones falló y el dato quedó mal.
Explica por qué, y qué garantía faltó pedir. 🟠**

⏱️ **30 segundos** — Porque las dos leyeron el mismo valor antes de que ninguna escribiera, y cada
una calculó el nuevo total fuera del motor. Faltó pedir que la segunda leyera el valor ya
actualizado.

🗣️ **2 minutos** — La secuencia fue: A lee 3186.23, B lee 3186.23, A escribe 3196.23 y confirma, B
escribe 3206.23 y confirma. B esperó bloqueada a que A confirmara —el motor sí hizo de árbitro— pero
cuando la desbloqueó, B ya tenía calculado su resultado con el valor viejo. El aislamiento por
defecto no obliga a releer.

🔬 **El detalle** — Hay tres formas de pedir la garantía que faltaba, y cada una cuesta algo
distinto. Hacer la aritmética dentro del `UPDATE` es la más barata y resuelve este caso. Bloquear
con `SELECT … FOR UPDATE` sirve cuando el cálculo no cabe en una expresión, y serializa a los dos
cajeros sobre esa fila. Subir a `SERIALIZABLE` hace que el motor aborte a una de las dos y obliga a
reintentar en el código. Es **motor** cuál de las tres está disponible y cómo se llama.

---

**01 → 13.** **Tu suite de pruebas corre contra SQLite y producción contra PostgreSQL. Da dos
diferencias que harían pasar una prueba que debería fallar. 🟠**

⏱️ **30 segundos** — Las claves foráneas, que en SQLite vienen apagadas; y el tipado, que en SQLite
es por afinidad y acepta casi cualquier cosa en casi cualquier columna.

🗣️ **2 minutos** — En SQLite, `PRAGMA foreign_keys` devuelve 0 por defecto y hay que encenderlo **en
cada conexión**, no una vez en el esquema. Sin eso, insertar un pedido con un `cliente_id`
inexistente funciona y devuelve `changes()` = 1. La misma inserción en PostgreSQL falla con
`violates foreign key constraint`. La segunda diferencia es el tipado dinámico: SQLite no tiene tipo
fecha, ni booleano, ni `DECIMAL`, así que una prueba que guarda una fecha mal formada pasa en SQLite
y revienta en producción.

🔬 **El detalle** — Hay una tercera que muerde igual: la concurrencia. SQLite admite un solo
escritor, así que ninguna prueba de bloqueos, interbloqueos o aislamiento significa nada contra él.
Es **motor** puro: el `CHECK`, en cambio, sí se aplica siempre en SQLite, así que la trampa es
selectiva y por eso pasa desapercibida. La respuesta profesional es probar contra el mismo motor que
hay en producción.

---

**01 → 14.** **¿Por qué el planificador eligió leer la tabla entera para contar los 60 000 pedidos
ANULADOS en vez de usar un índice? 🟠**

⏱️ **30 segundos** — Porque no hay índice sobre `estado`, y aunque lo hubiera, 60 000 de un millón
es demasiada proporción para que bajar por el índice salga a cuenta.

🗣️ **2 minutos** — El plan muestra `Seq Scan` con `Rows Removed by Filter: 940000` y 10 770 páginas
leídas: la tabla entera. Un `Index Scan` habría tenido que recorrer 60 000 entradas del índice y,
por cada una, ir a buscar la fila a la tabla, saltando por páginas casi al azar. Leer 10 770 páginas
seguidas es más barato que 60 000 saltos.

🔬 **El detalle** — El umbral no es un número fijo: depende de `random_page_cost`, de cuánta tabla
quepa en caché y de la correlación física entre el índice y el orden de las filas. En el entorno de
este corpus `random_page_cost` está en 1.1, que asume disco SSD. Es **motor**: el criterio, el
nombre de los nodos y los parámetros son de PostgreSQL y no se trasladan a MySQL. El desarrollo
completo pertenece al bloque de índices y planes.

---

**01 → 15.** **En el error del `CHECK` de §3 aparece el identificador `1000002` aunque la fila se
rechazó. ¿Qué te dice eso sobre las claves generadas? 🟠**

⏱️ **30 segundos** — Que la secuencia avanza aunque la inserción falle. Los identificadores
generados tienen huecos, y eso es normal.

🗣️ **2 minutos** — El valor se pide a la secuencia antes de intentar escribir la fila, y no se
devuelve si la escritura falla. Tampoco se devuelve si la transacción hace `ROLLBACK`: sería
imposible, porque entonces dos transacciones concurrentes tendrían que coordinarse para repartirse
los huecos y la secuencia dejaría de ser rápida.

🔬 **El detalle** — De aquí sale una regla de diseño que se pregunta: **un identificador
autoincremental no es un contador de filas ni una serie sin huecos**, así que no sirve como número
de factura ni como nada que un auditor vaya a contar. Es **motor** cómo se llama el mecanismo
—`IDENTITY` y secuencias en PostgreSQL, `AUTO_INCREMENT` en MySQL, el `rowid` en SQLite— pero el
comportamiento de no devolver valores es común a los tres.

---

**01 → 16.** **Escribe la secuencia de sentencias —con `BEGIN` y `COMMIT`— que aplica los dos pagos
de §2 sin perder ninguno. Da dos soluciones distintas y di qué cuesta cada una. 🔴**

⏱️ **30 segundos** — O haces la aritmética dentro del `UPDATE`, o bloqueas la fila al leerla con
`SELECT … FOR UPDATE`.

🗣️ **2 minutos** — La primera solución elimina la lectura previa: `BEGIN; UPDATE pedidos SET total =
total + 10 WHERE codigo='PED-00042'; COMMIT;` en A y lo mismo con 20 en B. El `UPDATE` toma el
bloqueo de la fila y lee el valor vigente en ese momento, así que B suma sobre el resultado de A. La
segunda mantiene la lectura pero la bloquea: `BEGIN; SELECT total FROM pedidos WHERE
codigo='PED-00042' FOR UPDATE;` y después el `UPDATE` con el valor calculado; B se queda esperando
en el `SELECT`, no en el `UPDATE`, así que cuando lee ya ve 3196.23.

🔬 **El detalle** — El coste de las dos es concurrencia: los cajeros se serializan sobre esa fila, y
si el pedido es popular eso es un punto caliente. La primera es más barata porque el bloqueo dura lo
que dura el `UPDATE`; la segunda lo mantiene desde el `SELECT` hasta el `COMMIT`, que puede ser
mucho más si hay lógica de aplicación en medio. Una tercera vía es el bloqueo optimista con una
columna de versión, que no bloquea nada pero obliga a reintentar en el código. Las tres tienen su
capítulo en el bloque de transacciones.

---

**01 → 17.** **Tienes un proceso nocturno que carga dos millones de filas y tarda cuatro horas por
las claves foráneas. Da la secuencia completa que lo acelera sin dejar datos huérfanos, y di qué
riesgo asumes. 🔴**

⏱️ **30 segundos** — Cargar con las restricciones desactivadas dentro de una transacción, y **volver
a activarlas comprobando** antes de confirmar.

🗣️ **2 minutos** — La forma segura es que la validación se siga haciendo, solo que una vez al final
en bloque en lugar de dos millones de veces fila a fila. En PostgreSQL eso se consigue declarando
las claves foráneas como aplazables y difiriéndolas dentro de la transacción, o desactivando el
disparador de la restricción y volviéndolo a activar con una validación explícita. Lo que no vale es
desactivarlas, cargar y confirmar sin revalidar: ahí sí quedan huérfanos, y silenciosos.

🔬 **El detalle** — El riesgo que asumes es doble. Primero, **la ventana**: mientras las
restricciones están desactivadas, cualquier otra sesión que escriba puede meter datos inválidos.
Segundo, **el todo o nada**: la revalidación al final descubre el problema cuando ya cargaste dos
millones de filas, así que un solo huérfano tira la carga entera y hay que repetirla. Es **motor**:
la sintaxis y las garantías son distintas en PostgreSQL y en MySQL, y en MySQL `SET
FOREIGN_KEY_CHECKS = 0` **no revalida nada al volver a encenderlo**, que es precisamente la trampa.

---

**01 → 18.** **Un compañero propone quitar todas las restricciones del esquema "porque la aplicación
ya valida". Da tres argumentos concretos en contra, cada uno con el escenario donde la aplicación no
alcanza. 🔴**

⏱️ **30 segundos** — Porque la aplicación no es el único camino de escritura, porque las
restricciones son documentación ejecutable, y porque el planificador las usa para elegir planes
mejores.

🗣️ **2 minutos** — El primer escenario es el más común: el script de migración, la carga nocturna,
el job de conciliación y el compañero con `psql` abierto un viernes no pasan por tu validación.
Basta uno para meter el dato malo, y nadie se entera hasta que el informe mensual no cuadra. El
segundo es el servicio nuevo que escribe otro equipo contra la misma tabla dentro de seis meses, con
su propia idea de qué es válido. El tercero es que un `NOT NULL` o un `UNIQUE` le dicen al
planificador cosas que le permiten descartar comprobaciones y elegir planes que sin la restricción
no podría elegir.

🔬 **El detalle** — El contraargumento legítimo de tu compañero también hay que reconocerlo, o la
respuesta suena dogmática: **las restricciones cuestan**, en tiempo por escritura y en bloqueo sobre
la fila referenciada, y hay cargas masivas donde eso importa. La respuesta profesional es que se
desactivan **puntualmente y revalidando**, no permanentemente. Y el argumento que cierra la
discusión: una regla en el código se cumple donde pasa ese código; una regla en el esquema se cumple
siempre, incluida la vez que alguien arregle algo a mano en producción a las tres de la mañana.

---

## Capítulo 02 — El modelo relacional y sus claves

Las 20 preguntas de [`02`](02-el-modelo-relacional-y-sus-claves.md).

**02 → 1.** Traduce relación, tupla, atributo y dominio a su equivalente en SQL, con un ejemplo de
cada uno en la tienda. 🟢

⏱️ **30 segundos** — Relación es tabla, tupla es fila, atributo es columna y dominio es el tipo más
las restricciones que limitan los valores legales.

🗣️ **2 minutos** — En la tienda: la relación es `clientes`, la tupla es el cliente `CLI-00311`, el
atributo es `clientes.pais` y el dominio de ese atributo es `char(2)` restringido a los códigos ISO
3166-1. El dominio es el único de los cuatro que el motor te cobra si lo ignoras: se declara con el
tipo y con `CHECK`, y se evalúa antes de escribir cada fila. Las otras tres palabras son
vocabulario; ésta es una restricción ejecutable.

🔬 **El detalle** — La palabra "relación" no viene de "relacionarse con otra tabla", que es el
malentendido más extendido: viene de la relación matemática, un subconjunto del producto cartesiano
de los dominios. De ahí salen las dos propiedades que rompen la analogía con la hoja de cálculo: no
hay orden de filas y no hay celdas vacías, hay `NULL`. Categoría: modelo teórico, no estándar SQL —
de hecho SQL se separa del modelo al permitir tablas con filas duplicadas cuando no hay clave
declarada.

---

---

**02 → 2.** ¿Qué es una clave candidata, y qué le añade la palabra "mínima"? 🟢

⏱️ **30 segundos** — Un conjunto de atributos que identifica una tupla de forma única, y "mínima"
significa que si le quitas cualquier columna deja de identificar.

🗣️ **2 minutos** — Sin la minimalidad, cualquier superconjunto de una clave sería también clave: si
`(id)` identifica, `(id, email)` también lo hace, pero no es candidata porque le sobra una columna.
El conjunto de todos los atributos de la tabla siempre identifica de forma única cuando hay clave;
llamarlo clave no aportaría nada. Por eso la definición pide mínimo, no simplemente único.

🔬 **El detalle** — "Mínima" no es lo mismo que "la más pequeña de todas". Una tabla puede tener dos
candidatas de tamaños distintos y las dos son mínimas: en `clientes` conviven `(id)`, `(codigo)` y
`(email)`, las tres de una columna, pero nada impide que una tabla tenga una candidata de una
columna y otra de tres. Categoría: modelo relacional. El estándar SQL no usa la palabra "candidata":
habla de restricciones `UNIQUE` y `PRIMARY KEY`, y no distingue cuál es "la de verdad".

---

---

**02 → 3.** ¿Cuántas claves candidatas tiene `clientes`, cuáles son y cuál se declaró primaria? 🟢

⏱️ **30 segundos** — Tres: `id`, `codigo` y `email`. La primaria es `id`; las otras dos son
alternativas declaradas con `UNIQUE`.

🗣️ **2 minutos** — Se ven consultando `pg_constraint`: `clientes_pkey` con `contype = 'p'` y
`clientes_codigo_key` y `clientes_email_key` con `contype = 'u'`. `id` es candidata por
construcción, porque `GENERATED ALWAYS AS IDENTITY` no repite valores. `codigo` lo es porque el
negocio promete que `CLI-00311` designa a un solo cliente. `email` lo es porque la tienda decidió
que no haya dos cuentas con el mismo correo.

🔬 **El detalle** — La de `email` es la más frágil de las tres, y conviene decirlo: no es una verdad
del mundo sino una regla de producto. Dos personas pueden compartir buzón, y el día que la tienda
acepte cuentas familiares esa restricción cae. Cada `UNIQUE` cuesta un índice B-tree adicional en
cada escritura; en `pedidos`, la primaria ocupa 21 MB y la alternativa sobre `codigo` 30 MB con un
millón de filas. Categoría: convención de esquema.

---

---

**02 → 4.** ¿Cuál es la primaria de `pedido_lineas` y por qué ninguna de sus dos columnas sirve
sola? 🟢

⏱️ **30 segundos** — `PRIMARY KEY (pedido_id, linea)`, una clave compuesta. Sola, ninguna de las dos
identifica.

🗣️ **2 minutos** — `pedido_id` no identifica porque un pedido tiene varias líneas: `PED-00042` tiene
tres. `linea` tampoco, porque el número de línea se reinicia en cada pedido y hay cerca de un millón
de filas con `linea = 1`. El par sí es único, y el motor lo prueba: insertar `(42, 2)` devuelve
`duplicate key value violates unique constraint "pedido_lineas_pkey"` con el detalle `Key
(pedido_id, linea)=(42, 2) already exists`.

🔬 **El detalle** — El orden de las columnas dentro de la clave no cambia qué identifica —como
conjunto, `(pedido_id, linea)` y `(linea, pedido_id)` son la misma clave— pero sí cambia el índice
que el motor construye. El B-tree de `(pedido_id, linea)` sirve para `WHERE pedido_id = 42` y para
el par completo, y no sirve para `WHERE linea = 2` a secas. Categoría: la equivalencia es del
modelo, la diferencia de rendimiento es del motor.

---

---

**02 → 5.** ¿Por qué `pagos.referencia` no puede ser la clave primaria de `pagos`? 🟢

⏱️ **30 segundos** — Porque es anulable, y una clave primaria exige `NOT NULL`. De los 820 000
pagos, 273 126 no tienen referencia.

🗣️ **2 minutos** — La referencia la devuelve la pasarela de pago, y un pago en efectivo no pasa por
ninguna pasarela. Es lo que llamo una clave candidata parcial: identifica de forma única a las filas
que la tienen, y no dice nada de las que no. Sirve perfectamente como `UNIQUE` —que es como está
declarada— pero no como primaria, porque el modelo exige que la primaria esté siempre presente.

🔬 **El detalle** — PostgreSQL y MySQL 9.7.2 rechazan un nulo en la primaria; MySQL además convierte
la columna a `NOT NULL` en silencio si la declaras `PRIMARY KEY`. SQLite es la excepción: por un
fallo histórico que ya no se puede arreglar sin romper bases existentes, admite nulos en una
`PRIMARY KEY` salvo en `INTEGER PRIMARY KEY` o en tablas `STRICT`. Categoría: convergencia de
motores en PostgreSQL y MySQL, divergencia documentada en SQLite.

---

---

**02 → 6.** Diferencia clave alternativa de clave foránea: ¿qué restringe cada una? 🟡

⏱️ **30 segundos** — La alternativa restringe hacia dentro: no puede haber dos filas con el mismo
valor. La foránea restringe hacia fuera: el valor tiene que existir en otra tabla.

🗣️ **2 minutos** — Son ortogonales y se confunden porque ambas se declaran sobre columnas de la
misma tabla. `clientes.codigo` es alternativa: garantiza unicidad dentro de `clientes`.
`pedidos.cliente_id` es foránea: no garantiza nada sobre unicidad —un cliente tiene muchos pedidos—
sino que cada valor apunta a una fila real de `clientes`. Una columna puede ser las dos a la vez, y
ese es justo el patrón de una relación uno a uno.

🔬 **El detalle** — La foránea se verifica en las dos direcciones y las dos cuestan. Hacia adelante,
un `INSERT` con `cliente_id = 999999999` devuelve `Key (cliente_id)=(999999999) is not present in
table "clientes"`. Hacia atrás, borrar `CLI-00311` devuelve `Key (id)=(311) is still referenced from
table "pedidos"`, porque tiene 52 pedidos. El coste hacia atrás es el que sorprende: sin índice en
la columna hija, es un recorrido secuencial de la tabla hija entera. Categoría: motor.

---

---

**02 → 7.** ¿Qué significa que `UNIQUE` admita varios nulos, y cuántos hay hoy en
`pagos.referencia`? 🟡

⏱️ **30 segundos** — Significa que `UNIQUE` prohíbe dos valores conocidos iguales, no dos ausencias.
Hoy hay 273 126 nulos conviviendo en esa columna.

🗣️ **2 minutos** — El nulo no es un valor, es la marca de que no hay valor, y dos ausencias no son
iguales entre sí. Por eso puedes insertar tantas filas con `referencia` nula como quieras sin que la
restricción proteste; lo comprobé insertando dos más dentro de un `BEGIN … ROLLBACK` y el motor
respondió `INSERT 0 2`. Con un valor no nulo repetido sí corta: reinsertar `REF-000000001` devuelve
`duplicate key value violates unique constraint "pagos_referencia_key"`.

🔬 **El detalle** — PostgreSQL 15 en adelante permite invertir esa regla con `UNIQUE NULLS NOT
DISTINCT`, que trata los nulos como iguales. Sobre estos datos falla al construir el índice: `Key
(referencia)=(null) is duplicated`. MySQL 9.7.2 y SQLite se comportan como PostgreSQL por defecto y
no tienen esa cláusula. Categoría: el comportamiento por defecto es común a los tres motores; la
cláusula para cambiarlo es exclusiva de PostgreSQL. No he verificado qué dice ISO/IEC 9075 al
respecto.

---

---

**02 → 8.** Distingue clave natural de sustituta, y di cuál de las dos ve el usuario en este
esquema. 🟡

⏱️ **30 segundos** — La natural sale del negocio y el usuario la ve; la sustituta la inventa el
sistema y no significa nada fuera de él. Aquí el usuario ve `CLI-00311`, no el `id`.

🗣️ **2 minutos** — En este esquema conviven las dos en cada tabla a propósito: `id` es la sustituta
y es la primaria, y `codigo` es la natural, declarada `UNIQUE`. Esa convivencia no es indecisión, es
el reparto correcto: la sustituta sostiene las referencias internas, donde importa que sea compacta
y estable, y la natural sostiene la interfaz humana, donde importa que se pueda leer en un log,
dictar por teléfono o pegar en un ticket de soporte.

🔬 **El detalle** — El argumento de disco existe y es medible —el índice de `codigo` sobre un millón
de pedidos ocupa 30 MB contra 21 MB el de `id`, y esa columna replicada en los 3,5 millones de
líneas serían 36 MB contra 27 MB— pero no es el argumento bueno. El bueno es que una clave natural
es un dato del negocio, y los datos del negocio cambian. Categoría: convención, no estándar; ninguna
norma obliga a tener un `id`.

---

---

**02 → 9.** ¿`PRIMARY KEY` implica `NOT NULL` en los tres motores? Si alguno no, dilo y explica por
qué. 🟡

⏱️ **30 segundos** — En PostgreSQL y MySQL sí. En SQLite no: admite nulos en una `PRIMARY KEY` salvo
en `INTEGER PRIMARY KEY` o en tablas `STRICT`.

🗣️ **2 minutos** — En SQLite lo puedes comprobar en dos líneas: creas una tabla con `codigo TEXT
PRIMARY KEY`, insertas dos filas con `NULL` y las dos entran. Es un fallo histórico de las primeras
versiones que nunca se corrigió, porque arreglarlo habría roto bases de datos existentes; el propio
proyecto lo documenta en su página de rarezas. MySQL va al otro extremo: si declaras `PRIMARY KEY`
sobre una columna anulable, la convierte a `NOT NULL` sin avisarte.

🔬 **El detalle** — Esto es exactamente el tipo de afirmación que conviene etiquetar. No he
verificado la cláusula de ISO/IEC 9075 que obliga a `NOT NULL` en la primaria, así que lo que puedo
afirmar es lo que hacen los motores, comprobado en sesión: PostgreSQL 18.6 sí, MySQL 9.7.2 sí y
además convierte, SQLite 3.53.4 no. Decir "el estándar lo exige" sin haber leído la cláusula es el
error más caro que se puede cometer en esta pregunta, porque es falsable en dos minutos.

---

---

**02 → 10.** Que declarar una clave cree un índice, ¿lo manda el estándar o lo decide cada motor? 🟡

⏱️ **30 segundos** — Es decisión de cada motor. La restricción dice qué está prohibido; el índice es
el mecanismo con que el motor lo hace cumplir.

🗣️ **2 minutos** — La diferencia importa porque los tres motores lo implementan distinto. PostgreSQL
crea un B-tree con el mismo nombre de la restricción, y lo ves en `\d`. MySQL/InnoDB va más lejos:
la primaria no solo tiene índice, **es** el índice agrupado, y el orden físico de la tabla lo
determina ella. SQLite crea un índice salvo cuando la primaria es `INTEGER PRIMARY KEY`, que es un
alias del `rowid` y por tanto no necesita estructura aparte.

🔬 **El detalle** — Lo que puedo afirmar con seguridad es el comportamiento de los tres motores,
verificado. Lo que no puedo afirmar es qué dice ISO/IEC 9075: el estándar es de pago y no he
verificado sus cláusulas. La formulación honesta y publicable es "los tres motores crean un índice,
cada uno a su manera; no he comprobado si la norma lo exige". Categoría: motor, con la reserva
explícita sobre el estándar.

---

---

**02 → 11.** En el informe de §1, ¿por qué el `JOIN` devuelve 4 100 000 filas? Nombra la clave que
falta. 🟠

⏱️ **30 segundos** — Porque `eventos_pedido.pedido_id` no es clave de esa tabla: un pedido tiene
varios eventos, 4,1 de media. El `JOIN` multiplica.

🗣️ **2 minutos** — La clave de `eventos_pedido` es `id`, y `pedido_id` es solo la foránea. Unir
`pedidos` con `eventos_pedido` por `pedido_id` produce una fila por cada evento, no por cada pedido:
`PED-00042` aparece tres veces, una por cada uno de sus eventos `VALIDADO`, `PAGADO` y `PREPARADO`.
Con un millón de pedidos y 4 100 000 eventos, el resultado son exactamente 4 100 000 filas. El
informe no está mal escrito, está mal razonado: asumió una clave que no existe.

🔬 **El detalle** — Lo peligroso de este error es que no falla: devuelve un resultado plausible, y el
síntoma aparece río abajo, en un total que no cuadra. Si el requisito era "un renglón por pedido con
la fecha de creación", la forma correcta es filtrar el tipo de evento —lo que convierte `(pedido_id,
tipo)` en clave del subconjunto— o usar un `DISTINCT ON`, o un `LATERAL` con `LIMIT 1`. El
diagnóstico previo que lo habría evitado cabe en una consulta: agrupar por la columna del `JOIN` y
pedir `HAVING count(*) > 1`. Categoría: modelo, no motor.

---

---

**02 → 12.** Justifica por qué `pedidos.codigo` es `UNIQUE` y no `PRIMARY KEY`, con un argumento de
coste y otro de estabilidad del dato. 🟠

⏱️ **30 segundos** — Por coste, es más ancha: 30 MB de índice contra 21 MB, y 36 MB contra 27 MB al
replicarla en las líneas. Por estabilidad, es un dato del negocio y el negocio la puede cambiar.

🗣️ **2 minutos** — El coste se mide, no se estima: `pg_relation_size` da 30 MB para
`pedidos_codigo_key` y 21 MB para `pedidos_pkey` sobre el mismo millón de filas, un 43 % más, porque
el valor medio ocupa 10,9 bytes contra los 8 fijos del `bigint`. Replicada como foránea en los 3,5
millones de líneas, la diferencia es de 27 MB a 36 MB. El argumento de estabilidad es el que decide:
`codigo` es un dato del negocio, y el día que el formato cambie el cambio hay que propagarlo a todas
las tablas hijas.

🔬 **El detalle** — Con una clave natural de once caracteres los 9 MB de diferencia son discutibles;
con un correo o un código de barras deja de serlo, y además el texto largo arrastra el coste de
comparación con *collation* en cada descenso por el B-tree. Pero incluso si el coste fuera cero, la
razón de estabilidad seguiría en pie. Categoría: convención, y hay una excepción legítima —catálogos
cerrados como ISO 3166-1— que conviene nombrar para no sonar dogmático.

---

---

**02 → 13.** `clientes.pais` no lleva sustituta detrás y `clientes` sí. Explica el criterio que los
separa. 🟠

⏱️ **30 segundos** — Porque `pais` es un catálogo cerrado y estable: `ES` no va a cambiar de nombre.
`clientes.codigo` sí puede cambiar, porque lo fija el negocio.

🗣️ **2 minutos** — El criterio es la inmutabilidad del valor durante toda la vida de la fila. Los
códigos ISO 3166-1 los mantiene un organismo externo, cambian cada varios años y con aviso, y son de
dos caracteres. Meter una tabla `paises` con `id` sustituto delante solo añadiría un `JOIN` a cada
consulta que quiera mostrar el país, y a cambio no protegería de nada que vaya a pasar. Un código de
cliente, en cambio, lo puede reformatear marketing en cualquier sprint.

🔬 **El detalle** — El criterio completo son tres preguntas en este orden: ¿es inmutable?, ¿es
compacto y comparable barato?, y ¿lo puede generar el sistema sin coordinarse con nadie? `pais` pasa
las dos primeras y la tercera no aplica porque el valor viene de fuera. El caso incómodo es el
intermedio: los códigos ISO sí han cambiado alguna vez —`CS`, `YU`— y por eso el `CHECK` o la tabla
de referencia tienen que ser revisables. Categoría: criterio de diseño, no norma.

---

---

**02 → 14.** PostgreSQL no indexa la columna hija de una foránea y MySQL sí. ¿Qué consecuencia tiene
en un `DELETE FROM clientes`, y qué harías en cada motor? 🟠

⏱️ **30 segundos** — En PostgreSQL, cada borrado de cliente hace un recorrido secuencial del millón
de pedidos para comprobar si queda alguien apuntando. En MySQL no, porque InnoDB creó el índice
solo.

🗣️ **2 minutos** — La verificación hacia atrás de la foránea necesita responder "¿hay alguna fila en
`pedidos` con este `cliente_id`?". Con índice es una búsqueda; sin índice es un `Seq Scan` completo.
En este esquema `pedidos.cliente_id` no tiene índice, así que un borrado masivo de clientes se
vuelve cuadrático en la práctica. En PostgreSQL lo que haría es crear explícitamente el índice sobre
la columna hija; en MySQL no hay que hacer nada, pero conviene saberlo para no sorprenderse al ver
una `KEY` en el `SHOW CREATE TABLE` que nadie escribió.

🔬 **El detalle** — El mismo razonamiento vale para `ON DELETE CASCADE`, que además tiene que
localizar y borrar las filas hijas, no solo contarlas. El coste no es solo tiempo: el recorrido
secuencial ensucia la caché de páginas y el borrado en cascada toma bloqueos sobre todas las filas
hijas. Categoría: motor. No he verificado si ISO/IEC 9075 dice algo sobre la creación automática del
índice; en todo caso, el estándar no habla de índices.

---

---

**02 → 15.** Alguien propone `UNIQUE (cliente_id, creado_en)` en `pedidos` porque "hoy no hay
duplicados". ¿Qué le respondes, y qué comprobarías antes? 🟠

⏱️ **30 segundos** — Que "hoy no hay duplicados" es una observación, no una regla. Un `UNIQUE` es
una promesa de que nunca los habrá, y esta la rompe el primer cliente que haga dos pedidos en el
mismo instante.

🗣️ **2 minutos** — Lo comprobé y es cierto que hoy no hay ninguno: agrupando por `(cliente_id,
creado_en)` y pidiendo `HAVING count(*) > 1` salen cero pares repetidos. Pero eso es una propiedad
de estos datos, no del dominio. `creado_en` es un `timestamptz` con resolución de microsegundos, así
que la colisión es improbable pero perfectamente posible: dos pestañas del navegador, un reintento
automático, una importación por lotes que asigne la misma marca. El día que ocurra, el `INSERT`
falla en producción y nadie entiende por qué.

🔬 **El detalle** — La pregunta que separa una alternativa legítima de un accidente estadístico es:
"¿qué le digo al usuario cuando esto falle?". Si la respuesta es "no debería pasar nunca", la
restricción no es una regla de negocio. Y hay un coste concreto: un índice compuesto más sobre un
millón de filas, mantenido en cada `INSERT` y en cada `UPDATE` que toque cualquiera de las dos
columnas. Categoría: convención mal fundada. Si lo que se quería era evitar pedidos duplicados por
reintento, la herramienta correcta es una clave de idempotencia explícita, no la marca de tiempo.

---

---

**02 → 16.** El `ALTER TABLE … UNIQUE NULLS NOT DISTINCT (referencia)` falla hoy: explica por qué, y
qué tendría que cambiar en el negocio para que fuera la restricción correcta. 🟠

⏱️ **30 segundos** — Falla porque `NULLS NOT DISTINCT` trata los nulos como iguales, y hay 273 126.
El motor no puede construir el índice: `Key (referencia)=(null) is duplicated`.

🗣️ **2 minutos** — Con la semántica normal, los nulos no chocan entre sí y por eso los 273 126 pagos
en efectivo conviven bajo un `UNIQUE`. Al pedir `NULLS NOT DISTINCT` le dices al motor que considere
iguales todas esas ausencias, así que a partir del segundo pago sin referencia ya hay duplicado. El
`ALTER` falla al construir el índice y el `ROLLBACK` deja la tabla intacta. Para que esa restricción
tuviera sentido, el negocio tendría que garantizar que como mucho un pago carece de referencia, lo
cual no describe ninguna tienda real.

🔬 **El detalle** — La restricción que sí corresponde a la regla "cada pago tiene referencia y es
única" es otra: `NOT NULL` más el `UNIQUE` normal. Y eso exige antes decidir qué referencia lleva un
pago en efectivo, que es una decisión de producto, no de esquema. `NULLS NOT DISTINCT` existe desde
PostgreSQL 15 y sirve para otro caso: columnas donde el nulo significa un estado concreto y único,
como "la fila sin categoría", no "la fila cuyo dato no aplica". Categoría: motor — MySQL 9.7.2 y
SQLite no tienen la cláusula.

---

---

**02 → 17.** Escribe el DDL de una `pedido_lineas` con clave sustituta `id` como primaria en lugar
de la compuesta, conservando la garantía que hoy da `PRIMARY KEY (pedido_id, linea)`. 🔴

⏱️ **30 segundos** — Añades `id` como primaria y conviertes el par en un `UNIQUE`. Si no lo haces,
pierdes la garantía y permites dos líneas 2 en el mismo pedido.

🗣️ **2 minutos** — El DDL queda así:

```sql
CREATE TABLE pedido_lineas (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pedido_id    bigint NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  linea        smallint NOT NULL,
  producto_id  bigint NOT NULL REFERENCES productos(id),
  cantidad     integer NOT NULL CHECK (cantidad > 0),
  precio_unit  numeric(12,2) NOT NULL,
  UNIQUE (pedido_id, linea)          -- la clave candidata que antes era primaria
);
```

Lo que se gana: una referencia de una sola columna, útil si algún día otra tabla tiene que apuntar a
una línea concreta, y un identificador estable aunque se renumeren las líneas. Lo que se pierde: un
índice más que mantener en cada `INSERT`, y 8 bytes por fila multiplicados por 3,5 millones.

🔬 **El detalle** — El error que hay que no cometer es quedarse solo con `id` y quitar el `UNIQUE`:
el `id` garantiza que no hay dos filas idénticas, pero no impide `(42, 2)` dos veces, que es la
regla de negocio de verdad. El otro matiz es el orden físico: hoy la primaria compuesta hace que las
líneas de un pedido queden agrupadas en el índice, lo que favorece leerlas juntas; con `id` como
primaria esa agrupación solo la da el `UNIQUE` secundario. En MySQL/InnoDB el cambio es más grave,
porque la primaria **es** el índice agrupado y con `id` las líneas de un mismo pedido dejan de estar
físicamente contiguas. Categoría: motor.

---

---

**02 → 18.** Los códigos de cliente pasan de `CLI-00311` a `ES-CLI-00311`. Escribe la secuencia para
el esquema actual y la que haría falta si `codigo` fuera la primaria referenciada por `pedidos`, y
compara el bloqueo de cada una. 🔴

⏱️ **30 segundos** — Con el esquema actual es un solo `UPDATE` sobre 50 000 filas de `clientes`. Con
`codigo` como primaria referenciada, el mismo `UPDATE` arrastra un millón de filas de `pedidos` en
cascada.

🗣️ **2 minutos** — Con el esquema de hoy:

```sql
BEGIN;
UPDATE clientes SET codigo = 'ES-' || codigo;   -- 50 000 filas, nadie las referencia
COMMIT;
```

Si `codigo` fuera la primaria y `pedidos` la referenciara, la foránea tendría que llevar `ON UPDATE
CASCADE`, y el `UPDATE` propagaría:

```sql
BEGIN;
UPDATE clientes SET codigo = 'ES-' || codigo;   -- 50 000 en clientes
-- + 1 000 000 de filas reescritas en pedidos por la cascada
COMMIT;
```

Y si la foránea no tuviera `ON UPDATE CASCADE`, ni siquiera se podría: fallaría con violación de
clave foránea, y habría que soltar la restricción, actualizar las dos tablas y volver a crearla
validando el millón de filas.

🔬 **El detalle** — El coste no es solo el número de filas. En PostgreSQL un `UPDATE` escribe una
versión nueva de cada fila, así que un millón de filas reescritas son un millón de tuplas muertas
que `VACUUM` tendrá que limpiar, más la reescritura de cada índice que toque esas filas. Y las filas
modificadas quedan bloqueadas para escritura hasta el `COMMIT`: mientras dure, nadie puede cambiar
el estado de un pedido. La primera versión toca 50 000 filas sin cascada; la segunda toca 1 050 000
y bloquea la tabla más caliente del sistema. Categoría: motor.

---

---

**02 → 19.** Escribe las sentencias que demuestren, en una sesión con `BEGIN` y `ROLLBACK`, que
`pagos.referencia` acepta nulos repetidos y rechaza no nulos repetidos. Di qué esperas ver. 🔴

⏱️ **30 segundos** — Dos inserciones con `referencia` nula pasan, y una que repita una referencia
existente falla con violación de `pagos_referencia_key`. Todo dentro de un `BEGIN … ROLLBACK`.

🗣️ **2 minutos** — La secuencia:

```sql
BEGIN;
INSERT INTO pagos (pedido_id, metodo, importe, pagado_en, referencia)
VALUES (42, 'EFECTIVO', 10.00, now(), NULL),
       (42, 'EFECTIVO', 20.00, now(), NULL);      -- espero: INSERT 0 2
ROLLBACK;

BEGIN;
INSERT INTO pagos (pedido_id, metodo, importe, pagado_en, referencia)
SELECT 42, 'TARJETA', 10.00, now(), referencia
  FROM pagos WHERE referencia IS NOT NULL ORDER BY id LIMIT 1;
ROLLBACK;                                          -- espero: ERROR de unicidad
```

El primer bloque devuelve `INSERT 0 2`. El segundo devuelve `duplicate key value violates unique
constraint "pagos_referencia_key"` con `DETALLE: Key (referencia)=(REF-000000001) already exists`.
El `ROLLBACK` deja los 820 000 pagos y los 273 126 nulos donde estaban.

🔬 **El detalle** — El segundo `ROLLBACK` es obligatorio aunque la sentencia haya fallado: tras un
error, PostgreSQL deja la transacción en estado abortado —el prompt cambia a `tienda=!#`— y no
acepta más sentencias hasta que cierres. Detalle que sube la nota: para reforzar el primer bloque,
se puede pedir `SELECT count(*) FROM pagos WHERE referencia IS NULL` dentro de la transacción y ver
273 128, y repetirlo después del `ROLLBACK` para ver 273 126. Categoría: comportamiento común a
PostgreSQL y MySQL; en MySQL el equivalente se abre con `START TRANSACTION` y da el mismo resultado.

---

---

**02 → 20.** Diseña el DDL de una tabla de direcciones de envío para `clientes` donde cada cliente
tenga varias direcciones pero **solo una predeterminada**, con restricciones declaradas. 🔴

⏱️ **30 segundos** — Un índice único parcial sobre `cliente_id` filtrado por `predeterminada`. Es
una línea y lo garantiza el motor, no la aplicación.

🗣️ **2 minutos** — En PostgreSQL:

```sql
CREATE TABLE direcciones_envio (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cliente_id     bigint NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
  calle          text NOT NULL,
  ciudad         text NOT NULL,
  pais           char(2) NOT NULL,
  predeterminada boolean NOT NULL DEFAULT false,
  creada_en      timestamptz NOT NULL DEFAULT now()
);

-- Solo una predeterminada por cliente: el índice parcial solo indexa las filas true.
CREATE UNIQUE INDEX direcciones_envio_predet
  ON direcciones_envio (cliente_id) WHERE predeterminada;
```

Un `UNIQUE (cliente_id, predeterminada)` a secas no sirve: impediría dos direcciones no
predeterminadas del mismo cliente, que es justo lo contrario de lo que se pide. Lo que el índice
parcial no da es la otra mitad de la regla, "al menos una predeterminada": eso no se puede declarar
por fila.

🔬 **El detalle** — El índice parcial es una extensión de PostgreSQL y no existe en MySQL 9.7.2; allí
el patrón equivalente es una columna generada que valga `cliente_id` cuando la fila es
predeterminada y `NULL` cuando no, con un `UNIQUE` encima —y funciona precisamente porque los nulos
no chocan entre sí, que es el mecanismo de la pregunta 7—. SQLite sí admite índices parciales con la
misma sintaxis. Para "al menos una", las opciones declarativas son una foránea desde `clientes` a la
dirección elegida, con la circularidad que eso implica, o una restricción diferida verificada al
final de la transacción. Categoría: motor, y es un buen ejemplo de cómo la misma regla de negocio se
declara distinto según dónde vivas.

---

## Capítulo 03 — Álgebra relacional

Las 18 preguntas de [`03`](03-algebra-relacional.md).

**03 → 1.** **¿Qué hace la selección (σ) y qué hace la proyección (π), y con qué se escribe cada una
en SQL? 🟢**

⏱️ **30 segundos** — La selección se queda con filas y se escribe `WHERE`; la proyección se queda
con columnas y se escribe en la lista del `SELECT`.

🗣️ **2 minutos** — Son los dos únicos operadores unarios: trabajan sobre una sola relación. σ aplica
un predicado a cada tupla y no toca el esquema del resultado; π elige atributos y no cambia cuántas
tuplas hay… salvo por los duplicados. En una misma consulta suelen ir juntas: `SELECT codigo,
categoria, precio, activo FROM productos WHERE codigo = 'PRD-04980'` es π de cuatro columnas sobre σ
de una fila entre 5 000.

🔬 **El detalle** — La traducción no es exacta en π: la proyección del álgebra devuelve un conjunto y
`SELECT` devuelve una bolsa. Categoría: estándar, porque la semántica de bolsa la fija ISO/IEC 9075
y la comparten PostgreSQL, MySQL y SQLite. El coste también difiere: σ es CPU casi gratis pero toda
la E/S de la tabla si no hay índice; π es gratis, y `DISTINCT` no, porque obliga a ordenar o a
levantar una tabla hash.

---

---

**03 → 2.** **¿Cuáles son los tres operadores de conjunto del álgebra y qué palabra clave les
corresponde? 🟢**

⏱️ **30 segundos** — Unión, diferencia e intersección: `UNION`, `EXCEPT` e `INTERSECT`.

🗣️ **2 minutos** — Los tres exigen que las dos relaciones sean compatibles en unión: mismo número de
atributos y dominios compatibles. `UNION` deduplica, que es lo que hace el operador del álgebra;
`UNION ALL` no deduplica y por eso no está en el álgebra, es una optimización de SQL. En el dominio
de la tienda, la diferencia contesta "clientes sin pedidos" sin un solo join: `SELECT id FROM
clientes EXCEPT SELECT cliente_id FROM pedidos` devuelve una fila en 148 ms, el `id` de CLI-00007.

🔬 **El detalle** — Los tres son bloqueantes: materializan los dos lados antes de devolver la primera
fila, así que un `UNION` con `LIMIT 20` procesa los conjuntos enteros igual. Categoría motor:
`INTERSECT` y `EXCEPT` no existieron en MySQL hasta la 8.0.31; en la 9.7.2 del corpus funcionan,
verificado en sesión.

---

---

**03 → 3.** **¿Qué es un join externo y qué pone en las columnas del lado que se queda sin pareja?
🟢**

⏱️ **30 segundos** — Conserva las filas que no encuentran pareja y rellena las columnas del otro
lado con `NULL`.

🗣️ **2 minutos** — El join interno tira las filas sin pareja; el externo las mantiene. `LEFT`
conserva las de la izquierda, `RIGHT` las de la derecha y `FULL` las de los dos lados. En la tienda,
`clientes LEFT JOIN pedidos` sobre CLI-00007 devuelve una fila con `pedido` y `estado` vacíos: son
nulos, no cadenas vacías, porque no hubo pedido que emparejar.

🔬 **El detalle** — Esos nulos son los que hacen que `LEFT JOIN ... WHERE derecha IS NULL` funcione
como anti-join. Categoría motor: MySQL 9.7.2 **no tiene `FULL OUTER JOIN`** y responde con un error
1064 de sintaxis; SQLite sí lo tiene desde la 3.39.0 (2022-06-25), y la del corpus es la 3.53.4. Si
necesitas un full outer en MySQL, se emula con `UNION` de dos joins externos.

---

---

**03 → 4.** **¿Qué pregunta contesta la división relacional que no contesta ningún otro operador?
🟢**

⏱️ **30 segundos** — "¿Quiénes están relacionados con *todos* los elementos de este conjunto?", tipo
"clientes que compraron todos los productos de audio".

🗣️ **2 minutos** — Los demás operadores contestan sobre existencia —quién tiene al menos uno, quién
no tiene ninguno—, y la división contesta sobre universalidad. No tiene palabra clave en SQL, ni en
el estándar ni en ningún motor, así que se construye: o con doble `NOT EXISTS`, o agrupando y
comparando `count(DISTINCT …)` con el tamaño del divisor.

🔬 **El detalle** — La relación con la lógica es directa: "para todo x" se reescribe como "no existe
x tal que no…", y de ahí salen los dos `NOT EXISTS` anidados, que son dos anti-joins. Categoría
estándar/motor: que no exista el operador es común a los tres motores del corpus y no es una
carencia de ninguno; ISO/IEC 9075 tampoco define un `DIVIDE BY`.

---

---

**03 → 5.** **`SELECT categoria FROM productos` devuelve 5 000 filas y la proyección del álgebra
sobre ese atributo devuelve 7. ¿Por qué? 🟡**

⏱️ **30 segundos** — Porque el álgebra trabaja con conjuntos y SQL con bolsas: `SELECT` conserva los
duplicados y π no.

🗣️ **2 minutos** — Una relación, por definición, no tiene tuplas repetidas ni orden. Una tabla de
SQL sí puede tener filas repetidas en el resultado de una consulta, y por eso `SELECT categoria`
devuelve una fila por producto: 5 000. Para igualar la proyección hay que pedir `DISTINCT`, y
entonces salen las 7 categorías reales de la tabla: audio, deporte, hogar, informática, juguetes,
libros y vídeo.

🔬 **El detalle** — Categoría estándar: la semántica de bolsa la manda ISO/IEC 9075, no es una
licencia de PostgreSQL, y los tres motores del corpus coinciden. El coste de volver al conjunto no
es gratis: `DISTINCT` ordena o construye una tabla hash con todas las filas candidatas, que en
`pedido_lineas` serían 3 500 000. Y el mismo argumento aplica al orden: sin `ORDER BY` no hay orden
garantizado, el que ves es efecto del plan.

---

---

**03 → 6.** **Diferencia entre `UNION` y `UNION ALL`, y cuál de los dos es el operador del álgebra.
🟡**

⏱️ **30 segundos** — `UNION` deduplica y `UNION ALL` no. El del álgebra es `UNION`; el que
normalmente quieres en producción es `UNION ALL`.

🗣️ **2 minutos** — La unión del álgebra opera sobre conjuntos, así que eliminar repetidos está en su
definición. SQL ofrece las dos variantes porque deduplicar cuesta. Medido en la tienda: unir las
categorías de los productos de más de 900 con las de los productos inactivos da 602 filas con `UNION
ALL` y 7 con `UNION`; para dejarlas en 7, el motor ordena o levanta una tabla hash con esas 602.

🔬 **El detalle** — Categoría convención: teclear `UNION` por reflejo es costumbre del gremio, y se
paga en cada ejecución aunque no haya un solo duplicado posible. Cuando los dos lados son disjuntos
por construcción —pedidos `PAGADO` y pedidos `ANULADO`, por ejemplo—, `UNION ALL` da el mismo
resultado sin el `sort` ni el `hash`.

---

---

**03 → 7.** **Diferencia entre un semi-join y un join normal, y cómo se escribe cada uno. 🟡**

⏱️ **30 segundos** — El semi-join filtra la izquierda por existencia de pareja y no trae columnas de
la derecha; el join normal empareja y devuelve columnas de los dos lados.

🗣️ **2 minutos** — El semi-join se escribe con `EXISTS` o con `IN`; el join, con `JOIN ... ON`. La
diferencia que importa es que el join **multiplica**: si un cliente tiene 52 pedidos, aparece 52
veces. El semi-join no, porque para en la primera coincidencia. En la tienda, `clientes WHERE EXISTS
(SELECT 1 FROM pedidos …)` devuelve 49 999 filas, una por cliente, en 131 ms.

🔬 **El detalle** — De ahí sale la regla práctica: `EXISTS` no necesita `DISTINCT` y un `JOIN` a una
tabla hija sí, y ese `DISTINCT` que alguien añadió al informe suele ser la huella de haber usado un
join donde tocaba un semi-join. El semi-join tampoco tiene sintaxis propia: es el planificador quien
lo nombra, y en PostgreSQL lo verás como `Hash Semi Join` o `Nested Loop Semi Join` en el plan.

---

---

**03 → 8.** **`JOIN ... ON`, `JOIN ... USING` y `NATURAL JOIN` sobre las mismas tablas: ¿en qué se
diferencian el resultado y las columnas devueltas? 🟡**

⏱️ **30 segundos** — `ON` dice la condición explícita y devuelve las columnas de unión duplicadas;
`USING` nombra columnas y las devuelve una sola vez; `NATURAL JOIN` no nombra nada y une por todas
las columnas que coinciden de nombre.

🗣️ **2 minutos** — Los tres pueden dar el mismo resultado, pero solo `ON` deja el criterio escrito
en la consulta. `USING (pedido_id)` exige que la columna se llame igual en las dos tablas y colapsa
la pareja en una sola columna del resultado. `NATURAL JOIN` decide el criterio leyendo el esquema en
tiempo de análisis, y eso significa que un `ALTER TABLE` de la semana que viene puede cambiar lo que
devuelve la consulta sin que nadie la toque.

🔬 **El detalle** — Categoría estándar: los tres están en ISO/IEC 9075 y los implementan PostgreSQL,
MySQL y SQLite; que `NATURAL JOIN` sea mala idea es convención de oficio, no norma. La prueba en el
dominio está en la pregunta 10: `clientes NATURAL JOIN pedidos` devuelve cero filas porque las dos
tablas comparten `id`, `codigo` y `creado_en`.

---

---

**03 → 9.** **¿`INTERSECT` y `EXCEPT` los fija el estándar, y desde qué versión los tiene MySQL? Di
también qué motor del corpus sigue sin `FULL OUTER JOIN`. 🟠**

⏱️ **30 segundos** — Sí, los fija el estándar; MySQL los tiene desde la 8.0.31, y el que sigue sin
`FULL OUTER JOIN` es MySQL.

🗣️ **2 minutos** — Es el ejemplo perfecto de separar norma de motor: la norma los tiene desde hace
décadas y MySQL tardó hasta octubre de 2022 en implementarlos. Por eso media internet sigue
explicando cómo emular `EXCEPT` con `LEFT JOIN ... IS NULL` o con `NOT EXISTS`: era obligatorio en
5.7 y en las 8.0 anteriores a la 8.0.31, que son las que todavía hay desplegadas.

🔬 **El detalle** — Verificado en sesión contra el entorno del corpus: en MySQL 9.7.2 funcionan
`EXCEPT` e `INTERSECT`, y en MariaDB 12.3.3 también. `FULL OUTER JOIN` en MySQL 9.7.2 sigue
devolviendo `ERROR 1064 (42000)`, error de sintaxis. SQLite lo tiene desde la 3.39.0, según su
propio registro de cambios, y el binario del corpus es el 3.53.4. Categorías: estándar para la
existencia de los operadores, motor para la disponibilidad.

---

---

**03 → 10.** **Un `NATURAL JOIN` entre `clientes` y `pedidos` devuelve cero filas y no da error.
Explica por qué y qué columnas usó el motor para unir. 🟠**

⏱️ **30 segundos** — Porque unió por las tres columnas que se llaman igual en las dos tablas —`id`,
`codigo` y `creado_en`— en vez de por `pedidos.cliente_id = clientes.id`.

🗣️ **2 minutos** — El natural join no lee tu intención, lee el esquema: toma todos los nombres de
columna comunes y los iguala. `clientes` y `pedidos` comparten los tres, así que la condición
efectiva exige que el cliente y el pedido tengan el mismo `id`, el mismo `codigo` y la misma marca
de tiempo, y eso no pasa nunca. El resultado no es un error, es una relación vacía, que es peor:
parece una respuesta.

🔬 **El detalle** — El plan lo enseña sin ambigüedad: `EXPLAIN (COSTS OFF)` da un `Merge Join` con
`Merge Cond: (clientes.id = pedidos.id)` y `Join Filter: ((clientes.codigo = pedidos.codigo) AND
(pedidos.creado_en = clientes.creado_en))`. La generalización: añadir mañana una columna
`actualizado_en` a `clientes` cambiaría otra vez el significado de la consulta. Categoría
convención: "el natural join es más limpio" es costumbre de aula; en producción se escribe `ON`.

---

---

**03 → 11.** **¿Por qué prefieres `NOT EXISTS` a `NOT IN` cuando la subconsulta puede devolver
nulos? Apóyate en un número. 🟠**

⏱️ **30 segundos** — Porque un solo `NULL` dentro del `NOT IN` deja la consulta sin filas: medido, 0
contra 820 000.

🗣️ **2 minutos** — `x NOT IN (a, b, NULL)` se evalúa como `x <> a AND x <> b AND x <> NULL`, y esa
última comparación es *desconocido*, nunca *falso*, así que la conjunción no puede ser verdadera
para ninguna fila. En la tienda lo ves con `pagos`: los 273 126 pagos en efectivo tienen
`referencia` nula, así que `WHERE referencia NOT IN (SELECT referencia FROM pagos WHERE
metodo='EFECTIVO')` devuelve 0, mientras que el mismo anti-join con `NOT EXISTS` devuelve 820 000.

🔬 **El detalle** — Categoría estándar: es lógica de tres valores, la mandan ISO/IEC 9075 y la
cumplen los tres motores; no es un fallo de PostgreSQL. El dueño del tema en el corpus es `01/06`.
Como efecto secundario, el planificador tampoco puede convertir un `NOT IN` nullable en un `Hash
Anti Join`, así que además de dar mal suele ir más lento.

---

---

**03 → 12.** **Un compañero añade `DISTINCT` a un informe porque "salían filas repetidas". ¿Qué le
preguntas antes de aprobarlo, y qué sospechas? 🟠**

⏱️ **30 segundos** — Le pregunto de dónde salen los duplicados, y sospecho que hay un join a una
tabla hija donde hacía falta un semi-join.

🗣️ **2 minutos** — Los duplicados en un informe casi nunca son del dato: son de la consulta. Si unes
`pedidos` con `pedido_lineas` para filtrar por producto, cada pedido aparece una vez por línea —3,5
de media en este dominio—, y el `DISTINCT` tapa el síntoma pero deja el coste: el motor produjo
igual todas las filas antes de colapsarlas. La corrección suele ser `EXISTS`.

🔬 **El detalle** — Hay un caso peor, y es cuando el informe suma: si hay `sum(total)` en la
consulta, el `DISTINCT` no arregla nada, porque los importes ya se multiplicaron. La señal en el
plan es un `HashAggregate` justo encima de un join que no debería multiplicar. Categoría convención:
"ponle `DISTINCT` y listo" es costumbre, y es la que produce informes lentos y, a veces, cifras
infladas.

---

---

**03 → 13.** **La división sobre los 443 productos de audio devuelve cero filas. ¿Es un error de la
consulta? Justifica. 🟠**

⏱️ **30 segundos** — No. Es la respuesta correcta: no existe ningún cliente que haya comprado los
443.

🗣️ **2 minutos** — Un cociente vacío es lo normal cuando el divisor es grande, y conviene
comprobarlo antes de tocar la consulta. La comprobación es directa: agrupa por cliente y cuenta
productos de audio distintos; el máximo del conjunto de datos es 21, muy lejos de 443. Con un
divisor realista la misma consulta sí devuelve gente: restringiendo a los dos productos de audio que
pasan de 998, salen 13 clientes en 236 ms.

🔬 **El detalle** — La forma de defenderlo en la entrevista es enseñar el numerito del máximo, no
discutir la consulta. Y el matiz técnico: la versión con `GROUP BY ... HAVING` exige `count(DISTINCT
pr.id)`, no `count(*)`, porque un cliente que compró tres veces el mismo altavoz alcanzaría el
recuento sin cubrir el divisor. Categoría: ninguna norma interviene aquí; es semántica del operador.

---

---

**03 → 14.** **Unir `text` con `numeric` es un error en PostgreSQL 18.6 y devuelve filas en MySQL
9.7.2. ¿Cuál de los dos comportamientos puedes atribuir al estándar, cuál al motor, y cómo lo
comprobarías? 🟠**

⏱️ **30 segundos** — Lo honesto es decir que no verifiqué la cláusula: lo que sé es que PostgreSQL
lo rechaza y MySQL lo convierte a texto, y eso es motor.

🗣️ **2 minutos** — Lo que sí es del estándar es el requisito de compatibilidad en unión —mismo
número de columnas y dominios compatibles—; lo que cada motor considera "compatible" es donde se
separan. PostgreSQL 18.6 responde `ERROR: UNION types text and numeric cannot be matched`. MySQL
9.7.2, con la misma unión acotada a `CLI-00007` y `PED-00042`, devuelve dos filas bajo una columna
llamada `codigo`: `CLI-00007` y `3186.23`, el importe convertido a texto.

🔬 **El detalle** — Cómo se comprueba: el número de columnas es inapelable y lo rechazan los dos, así
que se aísla el tipo; después se lee la cláusula de ISO/IEC 9075-2 sobre `<query expression>`, que
es de pago, y mientras no se lea **se dice que no se verificó**. Inventarse la cláusula es el error
más caro que puedes cometer en esta respuesta, porque es falsable en dos minutos.

---

---

**03 → 15.** **Escribe la consulta que devuelve los clientes sin ningún pedido en las tres formas
del álgebra: anti-join, join externo y diferencia de conjuntos. 🔴**

⏱️ **30 segundos** — Tres escrituras del mismo resultado: `NOT EXISTS`, `LEFT JOIN ... IS NULL` y
`EXCEPT`. En la tienda las tres devuelven CLI-00007.

🗣️ **2 minutos** — El artefacto:

```sql
-- anti-join: la forma directa
SELECT c.codigo FROM clientes c
WHERE NOT EXISTS (SELECT 1 FROM pedidos p WHERE p.cliente_id = c.id);

-- join externo + IS NULL: la forma clásica
SELECT c.codigo FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id
WHERE p.id IS NULL;

-- diferencia de conjuntos
SELECT c.codigo FROM clientes c
WHERE c.id IN (SELECT id FROM clientes EXCEPT SELECT cliente_id FROM pedidos);
```

🔬 **El detalle** — El `IS NULL` del segundo tiene que ir sobre una columna `NOT NULL` de la derecha
—`p.id`—; sobre una columna que ya admite nulos, el filtro deja de distinguir "no hubo pareja" de
"el valor era nulo". La tercera forma es la más literal del álgebra y la más frágil: si
`pedidos.cliente_id` admitiera nulos, `EXCEPT` los trataría como un valor más. La primera es la que
el planificador convierte en `Hash Anti Join`, que en este esquema tarda 513 ms sobre un millón de
pedidos.

---

---

**03 → 16.** **Escribe la división "clientes que compraron todos los productos de la categoría
`audio`" en sus dos formas, doble `NOT EXISTS` y `GROUP BY ... HAVING`, y di qué supone cada una
sobre los duplicados. 🔴**

⏱️ **30 segundos** — Doble `NOT EXISTS` —"no hay producto de audio que este cliente no haya
comprado"— o agrupar y comparar `count(DISTINCT producto)` con el tamaño del divisor.

🗣️ **2 minutos** — El artefacto:

```sql
-- forma canónica: dos anti-joins anidados
SELECT c.codigo FROM clientes c
WHERE NOT EXISTS (
    SELECT 1 FROM productos pr
    WHERE pr.categoria = 'audio'
      AND NOT EXISTS (
          SELECT 1 FROM pedidos p JOIN pedido_lineas pl ON pl.pedido_id = p.id
          WHERE p.cliente_id = c.id AND pl.producto_id = pr.id));

-- forma agregada: una pasada
SELECT c.codigo FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id JOIN pedido_lineas pl ON pl.pedido_id = p.id
JOIN productos pr ON pr.id = pl.producto_id AND pr.categoria = 'audio'
GROUP BY c.codigo
HAVING count(DISTINCT pr.id) = (SELECT count(*) FROM productos WHERE categoria = 'audio');
```

🔬 **El detalle** — La primera no supone nada sobre duplicados: pregunta por existencia, y que un
cliente haya comprado el mismo altavoz cinco veces da igual. La segunda **sí supone** que el
dividendo no trae repetidos, y por eso lleva `count(DISTINCT pr.id)`; con `count(*)` bastaría
comprar cinco veces un solo producto para colar un falso positivo. El número medido: la agregada
devuelve 0 filas en 1,34 s —el divisor son 443 productos y el cliente con más variedad llegó a 21—,
mientras que la correlada sobre los 50 000 clientes no terminó en siete minutos con este esquema sin
índices.

---

---

**03 → 17.** **Te dan un plan con `Hash Anti Join` sobre `pedidos` y `pagos` y `rows=180000`.
Reconstruye la consulta que lo produjo y explica de dónde sale ese número. 🔴**

⏱️ **30 segundos** — Es "pedidos sin ningún pago": un `NOT EXISTS` de `pedidos` contra `pagos`. Y
180 000 son los `PENDIENTE` más los `ANULADO`.

🗣️ **2 minutos** — La consulta:

```sql
SELECT count(*) FROM pedidos p
WHERE NOT EXISTS (SELECT 1 FROM pagos pg WHERE pg.pedido_id = p.id);
```

El plan construye una tabla hash con las 820 000 filas de `pagos`, recorre secuencialmente el millón
de `pedidos` y emite las que no encuentran entrada: 1 000 000 − 820 000 = 180 000, que en el dominio
son los 120 000 `PENDIENTE` más los 60 000 `ANULADO`, los dos estados que no tienen pago. PED-99999
es uno de ellos.

🔬 **El detalle** — Que aparezca `Hash Anti Join` y no `Nested Loop Anti Join` es decisión del
planificador, no de la consulta: hay dos `Seq Scan` porque el esquema del corpus no trae más índices
que los de claves, y el `Hash` reparte en `Batches: 4` porque no cabe en los 8 MB de `work_mem`, lo
que se paga en ficheros temporales. El tiempo medido fue 513 ms. Categoría motor: el nombre del
operador es de PostgreSQL; MySQL 9.7.2, con `EXPLAIN FORMAT=TREE`, llama a lo mismo `Nested loop
antijoin`.

---

---

**03 → 18.** **Reescribe el anti-join de `pagos` contra los pagos en efectivo para que funcione
aunque `referencia` admita nulos, y di en una frase qué arregla tu versión. 🔴**

⏱️ **30 segundos** — Se cambia el `NOT IN` por `NOT EXISTS`, y así un `NULL` en la subconsulta deja
de anular la consulta entera.

🗣️ **2 minutos** — El artefacto:

```sql
-- rota: un solo NULL en la subconsulta y el resultado es 0
SELECT count(*) FROM pagos p
WHERE p.referencia NOT IN (SELECT referencia FROM pagos WHERE metodo = 'EFECTIVO');

-- correcta: el anti-join no compara contra nulos, comprueba existencia
SELECT count(*) FROM pagos p
WHERE NOT EXISTS (SELECT 1 FROM pagos q
                  WHERE q.metodo = 'EFECTIVO' AND q.referencia = p.referencia);
```

Medido: 0 filas la primera, 820 000 la segunda.

🔬 **El detalle** — La alternativa conservadora es dejar el `NOT IN` y filtrar la subconsulta con
`AND referencia IS NOT NULL`, que devuelve lo mismo, pero obliga a acordarse del nulo cada vez que
alguien toque la consulta; `NOT EXISTS` no lo exige. Categoría estándar: la lógica de tres valores
la manda ISO/IEC 9075 y la cumplen PostgreSQL, MySQL y SQLite por igual, así que no es un problema
que se arregle cambiando de motor. El dueño del tema en el corpus es `01/06`.

---

## Capítulo 04 — Normalización y desnormalización

Las 17 preguntas de [`04`](04-normalizacion-y-desnormalizacion.md).

**04 → 1.** **Escribe la definición de dependencia funcional `X → Y` en una frase, sin usar la
palabra "clave".** 🟢

⏱️ **30 segundos** — Si dos filas coinciden en `X`, tienen que coincidir en `Y`. Es una regla del
negocio, no una observación sobre los datos de hoy.

🗣️ **2 minutos** — Lo importante es el "tienen que": la dependencia la declara quien conoce el
dominio, y los datos solo pueden desmentirla, nunca confirmarla. En la tienda, `producto_id →
categoria` se cumple porque el negocio dice que un producto tiene una categoría; `producto_id →
precio_unit` no se cumple porque el precio de una línea es el del momento de la compra. Toda la
teoría de formas normales se deduce de este único concepto.

🔬 **El detalle** — Categoría: teoría relacional (Codd, 1970), **no** estándar SQL. ISO/IEC 9075 no
tiene ninguna sentencia para declarar una dependencia funcional; lo más cerca es `PRIMARY KEY` y
`UNIQUE`, que son el caso particular en que el lado izquierdo determina toda la fila. Normalizar
consiste, en la práctica, en convertir cada dependencia en una clave que el motor sepa defender.

---

---

**04 → 2.** **Nombra las tres anomalías clásicas y da un ejemplo de cada una sobre la tienda.** 🟢

⏱️ **30 segundos** — Actualización, inserción y borrado. Aparecen cuando un mismo hecho vive en
muchas filas.

🗣️ **2 minutos** — Con cliente y pedido aplanados en una tabla, los 52 pedidos de `CLI-00311` ocupan
175 filas y las 175 guardan su email: cambiarlo en un pedido deja al cliente con dos correos y
ninguna clave lo impide (actualización). Un producto nuevo que nadie ha comprado no se puede
registrar, porque no hay pedido al que colgarlo (inserción). Y borrar el último pedido de un cliente
borraría al cliente (borrado).

🔬 **El detalle** — Medido: el `UPDATE ... WHERE pedido = 'PED-01719'` tocó 6 de 175 filas y dejó 169
con el email viejo. En el esquema normalizado el mismo cambio es `UPDATE clientes SET email = …
WHERE codigo = 'CLI-00311'`, que devolvió `UPDATE 1` en 1,684 ms. La anomalía no la arregla
programar con cuidado: la arregla que el dato tenga un solo sitio donde vivir. `CLI-00007` es
justamente el cliente con cero pedidos que demuestra que las dos entidades son independientes.

---

---

**04 → 3.** **¿Qué exige la 2FN, y en qué caso es imposible que una tabla la incumpla?** 🟢

⏱️ **30 segundos** — Que ningún atributo no primo dependa solo de una parte de la clave. Si la clave
primaria es de una sola columna, es imposible incumplirla.

🗣️ **2 minutos** — La 2FN ataca la dependencia parcial, y esa solo existe si hay clave compuesta: no
puedes depender de "parte" de una columna única. En la tienda hay exactamente una clave compuesta,
`pedido_lineas (pedido_id, linea)`. Si metieras ahí `producto_nombre`, dependería de `producto_id` y
no del par: cinco mil nombres repetidos sobre 3 500 000 filas, y un cambio de nombre tocando cientos
de miles.

🔬 **El detalle** — Ojo con el atajo: "clave de una columna ⇒ 2FN" es cierto para la clave primaria
elegida, pero la normalización se razona sobre **todas** las claves candidatas, no solo la primaria.
Con una clave sustituta `bigint` siempre puedes declarar trivialmente la 2FN y seguir teniendo un
desastre de diseño escondido bajo la clave natural; por eso `pedidos` tiene `id` sustituto **y**
`codigo` natural.

---

---

**04 → 4.** **¿Qué columna del esquema está desnormalizada a propósito, y contra qué expresión se
recalcula?** 🟢

⏱️ **30 segundos** — `pedidos.total`, contra `SUM(pedido_lineas.cantidad *
pedido_lineas.precio_unit)` de ese pedido.

🗣️ **2 minutos** — Viola 3FN de la forma más descarada posible, porque es un agregado de otra tabla,
y el DDL lo declara con un comentario: `-- desnormalizado a propósito`. La razón es el informe de
facturación: `SELECT sum(total) … WHERE estado = 'ENTREGADO'` tardó 69,404 ms y el `SUM` equivalente
por `JOIN` tardó 606,118 ms sobre los mismos 300 000 pedidos.

🔬 **El detalle** — En páginas, que es la moneda que no depende de la caché: 10 770 buffers contra 39
937. El recálculo tiene que leer `pedido_lineas` entera, 3 500 000 filas, para armar un `Hash Join`
del que solo sobreviven 1 049 372, con un `Hash` de 15 815 kB. Para **un** pedido suelto no compra
nada: 0,292 ms leyendo `total` contra 0,319 ms sumando, porque la clave primaria `(pedido_id,
linea)` baja directo a las tres líneas.

---

---

**04 → 5.** **`pedidos.total` y `pedido_lineas.precio_unit` parecen el mismo tipo de duplicación.
¿Por qué solo una lo es?** 🟡

⏱️ **30 segundos** — `total` es redundancia, se recalcula exactamente. `precio_unit` es dato
histórico: no se puede recalcular, porque el precio del catálogo ya cambió.

🗣️ **2 minutos** — La prueba es formal. Para que `precio_unit` violara 3FN tendría que existir la
dependencia `producto_id → precio_unit`, y no existe: `PRD-00017` tiene 20 205 líneas con 2 792
precios distintos, entre 1,05 y 999,84, mientras el catálogo dice 31,79. Lo que sí se cumple es
`(pedido_id, linea) → precio_unit`: depende de la clave entera, o sea del par pedido-momento.
`total`, en cambio, sí se deduce enteramente de otras filas.

🔬 **El detalle** — La consecuencia práctica separa las dos: `total` puede desincronizarse en
silencio y exige dueño único de escritura más un conciliador; `precio_unit` no puede desincronizarse
de nada porque es la única copia del hecho, y le basta un `NOT NULL`. Si lo borras y lees el precio
de `productos`, la siguiente subida de tarifa reescribe todas las facturas del pasado. Eso no es un
problema de rendimiento, es el libro mayor. La regla general: pregúntate si el valor de origen puede
cambiar sin que el hecho cambie; si puede, no es una copia.

---

---

**04 → 6.** **¿Las formas normales las fija ISO/IEC 9075 o son teoría relacional? ¿Y cuál es el
único lugar del estándar donde asoma la noción de dependencia funcional?** 🟡

⏱️ **30 segundos** — Son teoría relacional: Codd 1970 y Boyce-Codd 1974. El estándar no las
menciona. Donde sí asoma la dependencia funcional es en `GROUP BY`.

🗣️ **2 minutos** — No hay ninguna sentencia SQL que valide una forma normal, ni en PostgreSQL, ni en
MySQL, ni en SQLite. Lo único que un motor hace cumplir es una restricción: `PRIMARY KEY`, `UNIQUE`,
`FOREIGN KEY`, `CHECK`. El estándar sí usa la noción de *known functionally dependent* en `<group by
clause>`, para decidir qué columnas puedes seleccionar sin agregarlas.

🔬 **El detalle** — Categoría de cada pieza: formas normales, teoría; `GROUP BY` con dependencia
funcional, estándar; cómo lo implementa cada motor, motor. La cita del estándar la doy por nombre de
cláusula y **no verifiqué el número de subcláusula** —9075 es de pago—; decir eso en voz alta es más
fuerte que inventarse una numeración. Y si alguien te dice "el estándar exige 3FN", es la señal de
que está recitando.

---

---

**04 → 7.** **Guardar `jsonb` en `eventos_pedido.carga`, ¿viola la 1FN? Justifica, y di qué se
pierde de verdad.** 🟡

⏱️ **30 segundos** — No la viola: `jsonb` es un valor atómico de su propio dominio. Lo que pierdes
es la validación del motor, no la forma normal.

🗣️ **2 minutos** — La 1FN pide un valor por celda del dominio de la columna, y el dominio aquí es
`jsonb`, igual que en otra columna es `numeric`. Lo que el motor deja de hacer por ti es todo lo
demás: nadie garantiza que `importe` sea un número, que `version` exista, ni puedes poner una clave
foránea sobre un campo de dentro. En `eventos_pedido` eso está bien, porque la carga es de auditoría
y opaca.

🔬 **El detalle** — El criterio es de patrón de acceso: si vas a filtrar, agregar o referenciar un
campo, sácalo a columna; si solo lo lees entero, déjalo en `jsonb`. Lo verdaderamente contrario a
1FN es la lista en una columna de texto, `'PRD-00017,PRD-00872'`, que no se indexa ni se valida. Y
cuidado con el eslogan: "NoSQL no significa sin esquema" significa que el esquema lo valida tu
código o no lo valida nadie; con `jsonb` dentro de PostgreSQL pasa exactamente lo mismo dentro de la
columna.

---

---

**04 → 8.** **¿Por qué comprobar con una consulta que una dependencia funcional se cumple hoy no
demuestra que exista?** 🟡

⏱️ **30 segundos** — Porque la consulta solo busca contraejemplos. Que no encuentre ninguno dice que
hoy nadie la rompe, no que el negocio la prohíba.

🗣️ **2 minutos** — Es lógica elemental, pero se falla mucho en entrevista. La dependencia es una
regla, y una regla se declara, no se mide. La consulta `GROUP BY X HAVING count(DISTINCT Y) > 1`
devolviendo `0` es compatible con dos mundos: uno donde la regla existe y otro donde existe pero aún
no llegó la fila que la rompe. Al revés sí es concluyente: si devuelve más de `0`, la dependencia
**no** existe, y ahí no hay discusión.

🔬 **El detalle** — Medido: `producto_id → categoria` devolvió `0` en 1228,693 ms, y `producto_id →
precio_unit` devolvió `1` en 1177,046 ms. El `1` es prueba; el `0` es indicio. Y hay una
consecuencia de diseño: si crees en una dependencia, no la dejes en un comentario — conviértela en
una clave o en un `CHECK`, porque solo así el motor la defiende contra la fila que aún no ha
llegado.

---

---

**04 → 9.** **Explica por qué la 3FN preserva siempre las dependencias y BCNF no, y qué haces cuando
chocan.** 🟠

⏱️ **30 segundos** — Toda tabla admite una descomposición a 3FN sin pérdida y con todas las
dependencias preservadas. A BCNF siempre hay descomposición sin pérdida, pero puede que alguna
dependencia deje de poder comprobarse en una sola tabla. Cuando chocan, me quedo en 3FN.

🗣️ **2 minutos** — BCNF es más estricta: exige que el lado izquierdo de toda dependencia no trivial
sea superclave, sin la excepción que la 3FN hace para los atributos primos. Esa exigencia extra
puede obligar a partir la tabla de forma que una dependencia quede repartida entre dos tablas, y
entonces solo la puedes comprobar con un `JOIN` o un disparador. Cambiaste una restricción que el
motor sabía defender por código que tienes que mantener tú.

🔬 **El detalle** — El criterio que digo en voz alta: "si al separar necesito un disparador para
recuperar una regla que antes era una clave, me quedo en 3FN y documento la anomalía residual".
Categoría: es teoría, ningún motor participa. Y el coste de la descomposición extra se paga en cada
lectura, con un `JOIN` más, y en cada despliegue, con una tabla más que migrar.

---

---

**04 → 10.** **Para un solo pedido, leer `total` tardó 0,292 ms y el `SUM` equivalente 0,319 ms.
¿Por qué el `SUM` es casi gratis ahí, y en qué caso deja de serlo?** 🟠

⏱️ **30 segundos** — Porque la clave primaria de `pedido_lineas` es `(pedido_id, linea)`: el motor
baja por el índice a las tres líneas de ese pedido y suma tres números. Deja de ser gratis cuando el
agregado cruza muchos pedidos.

🗣️ **2 minutos** — El coste de un agregado no lo fija la operación, lo fija cuántas filas hay que
tocar. Con el prefijo de la clave primaria, tocar las líneas de un pedido cuesta lo mismo que leer
la fila de `pedidos`. En cuanto el filtro es `estado = 'ENTREGADO'`, el planificador ya no puede
usar ese prefijo: escanea `pedido_lineas` entera y hace un `Hash Join`. Ahí pasas de 0,3 ms a 606
ms.

🔬 **El detalle** — El plan lo dice entero: `Seq Scan on pedido_lineas` con `rows=3500000`, `Hash
Join` con `rows=1049372` reales, `Buffers: shared hit=11929 read=28008`. Frente a eso, leer `total`
es un `Seq Scan on pedidos` con `Buffers: shared hit=10770`. Moraleja de diseño: **la
desnormalización no se justifica por la ficha, se justifica por el informe**, y si tu caso es solo
la ficha, la columna sobra.

---

---

**04 → 11.** **El agregado sobre 300 000 pedidos lee 10 770 páginas con `total` y 39 937 con el
`JOIN`. ¿Por qué comparar páginas es mejor argumento que comparar milisegundos?** 🟠

⏱️ **30 segundos** — Porque los milisegundos dependen de la caché, del disco y de la máquina, y las
páginas leídas no: son una propiedad del plan.

🗣️ **2 minutos** — Si mides en tiempo, el mismo plan da 100 ms con la tabla caliente y dos segundos
en frío, y alguien siempre te dirá "en mi portátil no lo reproduzco". Las páginas —`Buffers: shared
hit` más `read`— son estables entre ejecuciones y comparables entre máquinas, y escalan de forma
predecible cuando la tabla crece. Además separan el trabajo real del efecto de la caché, que es
justo lo que quieres aislar cuando defiendes una decisión de esquema.

🔬 **El detalle** — En el entorno del corpus el paralelismo está apagado y `jit` también,
precisamente para que los `cost` y los `rows` sean reproducibles; los `actual time` no lo son y así
está declarado. Por eso el argumento que escribo al lado de la columna desnormalizada incluye las
dos cifras: *"606 ms → 69 ms y 39 937 → 10 770 páginas"*. La segunda es la que sobrevive a la
revisión de otro equipo.

---

---

**04 → 12.** **`SELECT p.id, p.codigo, p.estado FROM pedidos p GROUP BY p.codigo` funciona en MySQL
9.7 con `ONLY_FULL_GROUP_BY` activo y falla en PostgreSQL 18. Explica por qué, y di cuál de los dos
se acerca más al estándar.** 🟠

⏱️ **30 segundos** — Porque MySQL reconoce la dependencia funcional sobre cualquier clave candidata
`UNIQUE NOT NULL`, y PostgreSQL solo sobre la clave primaria. MySQL es aquí el que más se acerca al
estándar.

🗣️ **2 minutos** — `codigo` es `NOT NULL UNIQUE` en los dos esquemas, así que agrupar por `codigo`
determina unívocamente `id` y `estado`: no hay ambigüedad posible. El estándar admite seleccionar
columnas *known functionally dependent* de las agrupadas, y MySQL implementa ese análisis completo.
PostgreSQL implementó solo el caso de la clave primaria, y lo dice en su documentación con esas
palabras. SQLite no analiza nada y devuelve una fila cualquiera del grupo, agrupes por lo que
agrupes.

🔬 **El detalle** — Lo corrido: PostgreSQL 18.6 responde `ERROR: column "p.id" must appear in the
GROUP BY clause or be used in an aggregate function`; MySQL 9.7.2 con `sql_mode` empezando por
`ONLY_FULL_GROUP_BY` devuelve `42 | PED-00042 | PAGADO`; SQLite 3.53.4 devuelve lo mismo sin
protestar. 📝 Contexto: casi todo lo que se lee por internet sobre "MySQL permite columnas sueltas en
`GROUP BY`" es de 5.6 o anterior; desde 5.7 el modo viene activo por defecto y lo que queda no es
permisividad, es análisis de dependencias. Y la trampa de portabilidad: esta consulta migra de MySQL
a PostgreSQL y revienta.

---

---

**04 → 13.** **Alguien propone declarar `pedidos.total` como columna generada para que el motor la
mantenga solo. ¿Por qué no se puede, y qué mensaje devuelve PostgreSQL 18?** 🟠

⏱️ **30 segundos** — Porque una columna generada solo puede mirar otras columnas de su propia fila,
y `total` es un agregado de otra tabla. PostgreSQL responde `ERROR: cannot use subquery in column
generation expression`.

🗣️ **2 minutos** — La expresión de generación tiene que ser determinista y evaluable con la fila
delante: nada de subconsultas, nada de funciones volátiles, nada de otras tablas. Tiene sentido,
porque si pudiera leer `pedido_lineas`, cada `UPDATE` de una línea tendría que reevaluar filas de
`pedidos` que el motor no está tocando. Lo mismo pasa en MySQL y en SQLite. La alternativa que sí
ofrece el motor es una vista materializada, que existe en PostgreSQL y no en MySQL ni en SQLite, y
que hay que refrescar a mano.

🔬 **El detalle** — Categoría: motor, no estándar. Además, 📝 en PostgreSQL 18 las columnas generadas
son **virtuales por defecto** —antes había que escribir `STORED`—, y una virtual se calcula al leer,
así que ni siquiera ahorraría E/S. Si quieres que el motor mantenga `total`, el camino real es un
disparador `AFTER INSERT OR UPDATE OR DELETE` sobre `pedido_lineas`, y aun así hace falta el
conciliador: un `COPY` o una carga con disparadores desactivados se lo salta.

---

---

**04 → 14.** **Escribe el DDL normalizado en 3FN de una tabla que hoy tiene `(pedido, cliente,
email, pais, linea, producto, categoria, cantidad, precio_unit)` en una sola fila, con claves
primarias y foráneas de cada tabla resultante.** 🔴

⏱️ **30 segundos** — Salen cuatro tablas: clientes, productos, pedidos y pedido_lineas. El único
atributo que se queda en la línea aunque parezca del producto es `precio_unit`, porque es histórico.

🗣️ **2 minutos** — Las dependencias son `cliente → email, pais`; `producto → categoria`; `pedido →
cliente`; y `(pedido, linea) → producto, cantidad, precio_unit`. Cada lado izquierdo se convierte en
la clave primaria de una tabla, y cada referencia entre ellas en una clave foránea.

```sql
CREATE TABLE clientes (
  id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo text NOT NULL UNIQUE,              -- CLI-00311: la clave natural
  email  text NOT NULL UNIQUE,
  pais   char(2) NOT NULL
);

CREATE TABLE productos (
  id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo    text NOT NULL UNIQUE,           -- PRD-00017
  categoria text NOT NULL
);

CREATE TABLE pedidos (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo     text NOT NULL UNIQUE,          -- PED-00042
  cliente_id bigint NOT NULL REFERENCES clientes(id)
);

CREATE TABLE pedido_lineas (
  pedido_id   bigint NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  linea       smallint NOT NULL,
  producto_id bigint NOT NULL REFERENCES productos(id),
  cantidad    integer NOT NULL CHECK (cantidad > 0),
  precio_unit numeric(12,2) NOT NULL,       -- precio congelado en el momento de la compra
  PRIMARY KEY (pedido_id, linea)            -- clave compuesta, a propósito
);
```

🔬 **El detalle** — Tres decisiones que hay que saber defender. **Una:** `categoria` sale de la línea
porque `producto_id → categoria` sí se cumple; la consulta lo devolvió con `0` contraejemplos.
**Dos:** `precio_unit` se queda porque `producto_id → precio_unit` **no** se cumple —2 792 precios
distintos para `PRD-00017`—, así que no es una dependencia transitiva y no viola 3FN. **Tres:**
conviven la clave sustituta `id` y la natural `codigo`; la foránea apunta al sustituto para que
renombrar un código no propague el cambio. `ON DELETE CASCADE` solo en `pedido_lineas`, porque una
línea sin pedido no significa nada, mientras que un cliente sin pedidos —`CLI-00007`— sí.

---

---

**04 → 15.** **Da la secuencia SQL exacta que desincroniza `pedidos.total` para `PED-00042` sin que
el motor emita ningún error, y la consulta que lo demuestra.** 🔴

⏱️ **30 segundos** — Basta un `UPDATE` a `pedido_lineas` que no toque `pedidos`. Ni error, ni aviso,
ni restricción violada.

🗣️ **2 minutos** — El invariante "`total` es igual a la suma de sus líneas" no lo conoce el motor:
no hay `CHECK` que pueda expresarlo, porque un `CHECK` no cruza tablas. Así que cualquier camino de
escritura que olvide actualizar la cabecera deja el pedido mintiendo, y lo hace en silencio.

```sql
BEGIN;
UPDATE pedido_lineas SET cantidad = cantidad + 1 WHERE pedido_id = 42 AND linea = 3;
SELECT total, (SELECT sum(cantidad*precio_unit) FROM pedido_lineas WHERE pedido_id = 42) AS recalculado
  FROM pedidos WHERE id = 42;
ROLLBACK;
```

```text
UPDATE 1
  total  | recalculado
---------+-------------
 3186.23 |     4168.98
(1 fila)
```

🔬 **El detalle** — Corrido de verdad: una sola sentencia y el pedido miente por 982,75, que es
exactamente el `precio_unit` de la línea 3 (`PRD-03623`). El `ROLLBACK` es parte de la respuesta, no
un adorno: demuestra la grieta sin dejar rastro, y al salir `SELECT count(*) FROM pedidos` sigue
dando 1 000 000 y el conciliador sigue dando `0`. Lo que esto prueba en entrevista es la tesis del
capítulo: **desnormalizar añade un invariante que el motor no vigila**, y por eso hace falta un
dueño único de la escritura más un conciliador periódico.

---

---

**04 → 16.** **Escribe la consulta de conciliación que detecta todos los pedidos con el total
desincronizado, y explica qué pasaría si la escribieras con `LEFT JOIN` en lugar de `JOIN`.** 🔴

⏱️ **30 segundos** — Se agrega `pedido_lineas` por pedido y se compara contra `pedidos.total`. Con
`LEFT JOIN` entran los pedidos sin líneas, cuya suma es `NULL`, y la comparación `<>` con `NULL` da
desconocido: no los detectarías igual, harían falta `COALESCE` o `IS DISTINCT FROM`.

🗣️ **2 minutos** — Con `JOIN` la consulta solo mira los pedidos que tienen al menos una línea, que
es lo que suele querer un conciliador nocturno. Si te importa además el caso "pedido con `total`
distinto de cero y sin ninguna línea" —que es un tipo de corrupción distinto y más grave—, necesitas
el `LEFT JOIN`, pero entonces tienes que tratar el nulo explícitamente.

```sql
-- Lo que corre a diario: pedidos con líneas cuyo total no cuadra.
SELECT count(*) AS pedidos_desincronizados FROM pedidos p
  JOIN (SELECT pedido_id, sum(cantidad*precio_unit) s FROM pedido_lineas GROUP BY 1) t
    ON t.pedido_id = p.id
WHERE p.total <> t.s;

-- La variante que además caza los pedidos huérfanos de líneas.
SELECT count(*) FROM pedidos p
  LEFT JOIN (SELECT pedido_id, sum(cantidad*precio_unit) s FROM pedido_lineas GROUP BY 1) t
    ON t.pedido_id = p.id
WHERE p.total IS DISTINCT FROM coalesce(t.s, 0);
```

🔬 **El detalle** — La primera devolvió `0` en 1819,711 ms sobre el millón de pedidos: ese es el
precio real de vigilar la desnormalización, y cabe de sobra en una ventana nocturna. El matiz del
nulo es lógica de tres valores: `3186.23 <> NULL` no es verdadero ni falso, es desconocido, y
`WHERE` descarta lo desconocido igual que lo falso. `IS DISTINCT FROM` es el operador del estándar
que sí compara nulos como valores; PostgreSQL y SQLite lo tienen, y MySQL usa además el operador
`<=>` para la igualdad segura con nulos.

---

---

**04 → 17.** **Diseña la columna `promocion` de §4 respetando BCNF: da las tablas resultantes, sus
claves candidatas y la dependencia que cada una hace cumplir. Después di qué se pierde frente a
dejarla en 3FN.** 🔴

⏱️ **30 segundos** — Se saca `promocion → producto_id` a su propia tabla, con `promocion` como clave
primaria, y en la línea se deja solo el código de promoción.

🗣️ **2 minutos** — El punto de partida es `pedido_lineas (pedido_id, linea, producto_id, cantidad,
precio_unit, promocion)` con dos reglas de negocio: un producto no se repite en dos líneas del mismo
pedido, y cada promoción aplica a un único producto. Eso da dos claves candidatas solapadas,
`{pedido_id, linea}` y `{pedido_id, producto_id}`, más la dependencia `promocion → producto_id`,
cuyo lado izquierdo no es superclave. Viola BCNF; la 3FN la tolera porque `producto_id` es primo.

```sql
-- Tabla 1. Clave candidata: {promocion}. Hace cumplir promocion -> producto_id.
CREATE TABLE promociones (
  promocion   text PRIMARY KEY,
  producto_id bigint NOT NULL REFERENCES productos(id)
);

-- Tabla 2. Claves candidatas: {pedido_id, linea} y {pedido_id, promocion}.
CREATE TABLE pedido_lineas (
  pedido_id   bigint NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  linea       smallint NOT NULL,
  promocion   text NOT NULL REFERENCES promociones(promocion),
  cantidad    integer NOT NULL CHECK (cantidad > 0),
  precio_unit numeric(12,2) NOT NULL,
  PRIMARY KEY (pedido_id, linea),
  UNIQUE (pedido_id, promocion)
);
```

🔬 **El detalle** — Lo que se pierde: la regla *"un producto no se repite en dos líneas del mismo
pedido"* ya no es declarable como clave, porque `producto_id` desapareció de la línea y ahora se
alcanza con un `JOIN` a `promociones`. Hacerla cumplir exige un disparador o un índice único sobre
una expresión que cruce tablas —que no existe—. Ese es exactamente el caso de libro **BCNF sin
preservación de dependencias**, y el criterio del capítulo manda: si al separar necesitas un
disparador para recuperar una regla que antes era una clave, quédate en 3FN y documenta la anomalía
residual. Categoría: teoría relacional pura; ningún motor opina.

---

## Capítulo 05 — Del modelo ER al esquema

Las 20 preguntas de [`05`](05-del-modelo-er-al-esquema.md).

**05 → 1.** **¿Qué cláusula del DDL implementa la obligatoriedad de una relación, y cuál su
unicidad? 🟢**

⏱️ **30 segundos** — La obligatoriedad es `NOT NULL` sobre la columna foránea; la unicidad es
`UNIQUE` sobre esa misma columna. Son cláusulas distintas y hacen cosas distintas.

🗣️ **2 minutos** — `NOT NULL` responde a "esta fila tiene que apuntar a alguien" y `UNIQUE`, a
"nadie más puede apuntar al mismo". El diagrama ER dibuja las dos cosas con la misma marca de
multiplicidad, y de ahí sale el error clásico: traducir un 1:1 solo con la clave foránea. La foránea
da el lado "uno" de un extremo, y sin el `UNIQUE` el otro extremo acepta N.

🔬 **El detalle** — En el esquema del corpus, `pagos.pedido_id` es `NOT NULL REFERENCES pedidos(id)`
y **no** lleva `UNIQUE`, así que el 1:1 del diagrama no está implementado: dentro de una transacción
se le inserta un segundo pago a `PED-00042` y el motor responde `INSERT 0 1`. El `UNIQUE` es la
única de las cuatro restricciones que cuesta un índice entero, con su espacio y una escritura extra
por `INSERT`. Categoría: las cuatro restricciones son del estándar y los cuatro motores del corpus
las tienen.

---

**05 → 2.** **¿Cuál es la clave primaria de `pedido_lineas` y por qué tiene dos columnas? 🟢**

⏱️ **30 segundos** — Es `(pedido_id, linea)`: la línea no se identifica sola, se identifica dentro
de su pedido.

🗣️ **2 minutos** — `linea` es un número correlativo por pedido, no un identificador global: hay 1
000 000 de filas con `linea = 1`, una por pedido. Poner la clave del padre dentro de la clave
primaria del hijo es justo cómo se escribe en DDL una entidad débil. Y de paso el índice de esa
clave primaria es el que la clave foránea usa para comprobarse.

🔬 **El detalle** — El orden de las columnas no es indiferente: `(pedido_id, linea)` deja el índice
utilizable para "dame las líneas del pedido X", mientras que `(linea, pedido_id)` no serviría para
eso. Categoría: la clave primaria compuesta es del estándar; qué índice crea con ella es del motor
—PostgreSQL crea un B-tree, InnoDB la usa como índice agrupado y ordena físicamente la tabla por
ella—.

---

**05 → 3.** **¿Qué valor devuelve `PRAGMA foreign_keys` en una conexión nueva de SQLite, y qué
implica? 🟢**

⏱️ **30 segundos** — Devuelve `0`: las claves foráneas están apagadas, y SQLite acepta filas
huérfanas aunque el esquema las declare.

🗣️ **2 minutos** — El `PRAGMA` es por conexión, no por fichero: no se guarda en la base, no se
hereda, y cada conexión nueva del pool vuelve a `0` salvo que el driver lo encienda explícitamente.
El esquema sigue mostrando el `REFERENCES ... ON DELETE CASCADE` en el `.schema`, así que el
desarrollador cree que están activas. Está apagado por compatibilidad hacia atrás con bases
anteriores a la versión 3.6.19.

🔬 **El detalle** — Medido contra el `tienda.db` del corpus: con el `PRAGMA` en `0` entra una línea
con `pedido_id = 9000001`, que no existe; y `DELETE FROM pedidos WHERE codigo = 'PED-00042'` deja 3
líneas y 1 pago huérfanos sin cascada y sin error. Encendiéndolo en la misma conexión, las dos
operaciones fallan con `FOREIGN KEY constraint failed`. Para auditar lo que ya entró existe `PRAGMA
foreign_key_check`. Categoría: motor, y es la divergencia más peligrosa de SQLite frente al
estándar.

---

**05 → 4.** **¿Cuál es la acción referencial por defecto cuando no se declara `ON DELETE`? 🟢**

⏱️ **30 segundos** — `NO ACTION`: el borrado del padre falla si queda algún hijo apuntándolo.

🗣️ **2 minutos** — Es el valor por defecto del estándar y coincide en PostgreSQL, MySQL/MariaDB y
SQLite. Por eso `pagos`, que no declara nada, impide borrar un pedido pagado, mientras que
`pedido_lineas` y `eventos_pedido`, que sí declaran `ON DELETE CASCADE`, se van con él. No declarar
nada **es** una decisión, no un olvido.

🔬 **El detalle** — `NO ACTION` no es exactamente `RESTRICT`: comprueba al final de la sentencia, no
en el acto. Categoría: estándar en la definición del valor por defecto; el matiz de cuándo se
comprueba también, pero cada motor decide además si la restricción puede declararse `DEFERRABLE`
—PostgreSQL sí, MySQL no—.

---

**05 → 5.** **Nombra las tres tablas que referencian a `pedidos` y di qué `ON DELETE` tiene cada
una. 🟢**

⏱️ **30 segundos** — `pedido_lineas` y `eventos_pedido` con `ON DELETE CASCADE`, y `pagos` sin nada,
o sea `NO ACTION`.

🗣️ **2 minutos** — La asimetría es deliberada. Las líneas y los eventos son partes del pedido: no
existen sin él y desaparecen con él. El pago es un hecho contable con vida propia, así que su
foránea bloquea el borrado del padre. El motor está defendiendo una regla de negocio —"un pedido que
se cobró no se borra"— que nadie escribió en el código de la aplicación.

🔬 **El detalle** — Medido: borrar `PED-99999` (anulado, 6 líneas, 6 eventos, 0 pagos) devuelve
`DELETE 1` y se lleva 12 filas hijas que no aparecen en el recuento; borrar `PED-00042` devuelve
`ERROR: update or delete on table "pedidos" violates foreign key constraint "pagos_pedido_id_fkey"`.
Categoría: convención de diseño del corpus, no del estándar; las acciones disponibles sí son del
estándar.

---

**05 → 6.** **¿Qué diferencia hay entre `NOT NULL` y `UNIQUE` sobre una columna foránea? 🟡**

⏱️ **30 segundos** — `NOT NULL` fija el mínimo de la cardinalidad —al menos uno— y `UNIQUE` fija el
máximo —como mucho uno—.

🗣️ **2 minutos** — Sin `NOT NULL`, la relación es opcional: puede haber hijos sin padre asignado.
Sin `UNIQUE`, el lado "muchos" es de verdad muchos. Un 1:1 obligatorio necesita las dos; un 0..1
necesita solo `UNIQUE`; un 1:N obligatorio, solo `NOT NULL`. El diagrama las dibuja juntas y el DDL
las separa, y ahí es donde se pierde la mitad de la semántica del modelo.

🔬 **El detalle** — El precio también es asimétrico: `NOT NULL` es un bit en la cabecera de la fila y
no cuesta nada medible, mientras que `UNIQUE` construye un índice con su espacio, su escritura extra
por `INSERT` y su punto de contención cuando dos transacciones escriben el mismo valor. Además
`UNIQUE` y `NULL` interactúan: en PostgreSQL varias filas con `NULL` conviven bajo un `UNIQUE`, que
es por lo que `pagos.referencia` puede ser nulo en 273 126 filas y único en el resto.

---

**05 → 7.** **¿Por qué `pedido_lineas` es entidad débil y `pagos` no, si las dos dependen de
`pedidos`? 🟡**

⏱️ **30 segundos** — Porque la identidad de la línea incluye la del pedido, y la del pago no: el
pago tiene su propia clave sustituta y existe por sí mismo.

🗣️ **2 minutos** — Una entidad débil no tiene identificador propio; se identifica por la clave del
padre más un discriminador local, aquí `(pedido_id, linea)`. `pagos` tiene su `id` propio, su
referencia del proveedor y sentido contable fuera del pedido. Esa diferencia conceptual se traduce
en dos decisiones de DDL: la clave primaria compuesta y el `ON DELETE CASCADE` para la débil; clave
sustituta propia y `NO ACTION` para la fuerte.

🔬 **El detalle** — Si falta cualquiera de las dos piezas, la dependencia es solo un dibujo: con
clave primaria compuesta pero sin `CASCADE`, borrar el pedido falla y hay que limpiar a mano; con
`CASCADE` pero con clave sustituta propia en la línea, nada impide que dos pedidos tengan "la línea
1" con el mismo significado. Categoría: el concepto de entidad débil es del modelo ER, no del
estándar SQL; el estándar solo te da las piezas.

---

**05 → 8.** **¿En qué se diferencian `NO ACTION` y `RESTRICT`, y en qué caso concreto se nota? 🟡**

⏱️ **30 segundos** — `RESTRICT` falla en el acto; `NO ACTION` comprueba al final de la sentencia. Se
nota cuando una sola sentencia borra el hijo y el padre.

🗣️ **2 minutos** — En el 99 % de los casos se comportan igual y por eso se usan como sinónimos. La
diferencia asoma cuando dentro de una misma sentencia se arregla la situación antes de que termine:
con `NO ACTION` la comprobación llega después y pasa; con `RESTRICT` el motor aborta en cuanto ve la
fila hija. En PostgreSQL, además, solo la comprobación de `NO ACTION` puede aplazarse hasta el
`COMMIT` con `DEFERRABLE INITIALLY DEFERRED`: `RESTRICT` actúa de inmediato aunque la restricción se
declare diferible.

🔬 **El detalle** — Medido en el lab: `WITH b AS (DELETE FROM pagos WHERE pedido_id=42 RETURNING id)
DELETE FROM pedidos WHERE id=42;` devuelve `DELETE 1` sin error, aunque el borrado directo del
pedido falle. Con `RESTRICT` en `pagos_pedido_id_fkey` esa misma sentencia no pasaría. Categoría: el
momento de la comprobación es del estándar; qué se puede diferir es del motor.

---

**05 → 9.** **¿Las cinco acciones referenciales las fija el estándar o cada motor? ¿Y que las
foráneas estén activas por defecto? 🟡**

⏱️ **30 segundos** — Las cinco acciones son del estándar y las tienen los tres motores. Que las
foráneas estén activas también lo manda el estándar, y **SQLite no lo cumple**: las trae apagadas.

🗣️ **2 minutos** — `CASCADE`, `SET NULL`, `SET DEFAULT`, `RESTRICT` y `NO ACTION` están en ISO/IEC
9075-2 y las tres implementaciones las reconocen. Donde los motores se separan es en el
cumplimiento: PostgreSQL y MySQL con InnoDB aplican siempre; SQLite las declara y no las aplica
hasta que la conexión ejecuta `PRAGMA foreign_keys = ON`. Esa es la afirmación del gremio —"la base
garantiza la integridad referencial"— que es cierta en dos motores de tres.

🔬 **El detalle** — Un caso medido que contradice a la propia documentación: MySQL 9.7 documenta que
InnoDB **rechaza** las definiciones con `ON DELETE SET DEFAULT`, y el 9.7.2 del lab creó la tabla
sin una queja. Es el tipo de detalle que sostiene la regla del corpus: la doc es la fuente citable,
la sesión es la fuente de verdad. No he verificado la numeración de cláusula del estándar; cito los
nombres de la BNF (`<referential triggered action>`), que es de pago.

---

**05 → 10.** **¿Por qué `precio_unit` vive en `pedido_lineas` y no se lee de `productos.precio`? 🟡**

⏱️ **30 segundos** — Porque es el precio congelado del día de la compra: un atributo de la relación,
no del producto.

🗣️ **2 minutos** — Si la factura leyera `productos.precio`, cambiar una tarifa reescribiría el
importe de todos los pedidos históricos. `cantidad` y `precio_unit` no pertenecen ni al pedido ni al
producto: pertenecen al cruce, y no hay dónde ponerlos si la tabla intermedia es solo `(pedido_id,
producto_id)`. Esa es la prueba de que una N:M con atributos propios es una entidad de negocio y no
una tabla puente.

🔬 **El detalle** — En `PED-00042` la línea 3 tiene `precio_unit = 982.75`, y ese número solo
significa algo anclado a la fecha del pedido. El tipo es `numeric(12,2)`, no coma flotante, por la
razón habitual: `numeric` es decimal exacto y `float` acumula error en las sumas. Categoría:
convención de modelado —la llaman *point-in-time data* o precio histórico—; el estándar no dice nada
al respecto.

---

**05 → 11.** **Un `DELETE` responde `DELETE 1` y ha borrado trece filas. Explica cómo y cómo lo
comprobarías. 🟠**

⏱️ **30 segundos** — Hay `ON DELETE CASCADE` en las tablas hijas: el recuento solo cuenta la tabla
nombrada en el `DELETE`, no lo que arrastró.

🗣️ **2 minutos** — El cliente reporta las filas afectadas de la relación objetivo. Todo lo que el
motor borre por acción referencial —y lo que borren los disparadores— queda fuera de ese número. Con
cascadas encadenadas, un `DELETE` de una fila puede llevarse millones sin que la salida lo insinúe.
Es el argumento serio contra poner `CASCADE` por comodidad: no es que borre de más, es que borra en
silencio.

🔬 **El detalle** — Cómo comprobarlo: contar antes y después dentro de una transacción con
`ROLLBACK`, que es lo que hace el capítulo con `PED-99999` (6 líneas y 6 eventos antes, 0 y 0
después, y `DELETE 1` en medio). Alternativas: `EXPLAIN ANALYZE` del `DELETE`, que muestra los nodos
de cascada, o `pg_stat_user_tables.n_tup_del` por tabla antes y después. Categoría: qué cuenta el
recuento de filas afectadas es del protocolo de cada motor, no del estándar.

---

**05 → 12.** **Hay 6 855 pedidos con un producto repetido y ningún `UNIQUE (pedido_id,
producto_id)`. Argumenta a favor y en contra de añadirlo. 🟠**

⏱️ **30 segundos** — A favor: cierra la puerta a duplicados por doble clic. En contra: mata casos
legítimos, como dos unidades del mismo producto a precios distintos.

🗣️ **2 minutos** — Si el negocio dice que una línea es "un producto en un pedido", el `UNIQUE`
convierte un error de datos en un error de inserción y protege los informes de agregación. Si el
negocio admite líneas con precios distintos, descuentos por línea o una línea de regalo, el `UNIQUE`
prohíbe algo válido y el equipo acabará esquivándolo con un producto ficticio, que es peor. Lo que
no es defendible es no haberlo decidido.

🔬 **El detalle** — Y hay un coste de migración: con 6 855 pedidos ya en conflicto sobre 3 500 000
líneas, añadir el `UNIQUE` exige primero fusionar o reclasificar esas filas, y la creación del
índice bloquea escrituras salvo que se use `CREATE UNIQUE INDEX CONCURRENTLY` y luego `ADD
CONSTRAINT ... USING INDEX`. Categoría: decisión de diseño; el esquema del corpus decide no ponerlo,
y lo declara.

---

**05 → 13.** **¿Por qué `ON DELETE SET NULL` no es declarable en ninguna foránea que apunte a
`pedidos`? 🟠**

⏱️ **30 segundos** — Porque las tres columnas foráneas son `NOT NULL`: la acción tendría que
escribir un `NULL` que la columna no admite.

🗣️ **2 minutos** — `SET NULL` solo tiene sentido cuando el vínculo es opcional y el hijo sobrevive
sin padre. En este esquema, una línea sin pedido y un pago sin pedido no significan nada, así que
`NOT NULL` es correcto y `SET NULL` queda descartado por construcción. PostgreSQL rechaza la
combinación en el momento del borrado, no al declararla, lo que la convierte en una bomba de
relojería si nadie la prueba.

🔬 **El detalle** — El patrón donde `SET NULL` sí es la respuesta correcta es el de referencias
débiles y opcionales: un `cliente_id` en una reseña que se conserva como anónima, o un
`responsable_id` en un ticket cuyo agente se dio de baja. Categoría: la acción es del estándar; el
conflicto con `NOT NULL` también, y los tres motores del corpus se comportan igual.

---

**05 → 14.** **¿Qué te cuesta una clave foránea en cada `INSERT` del hijo, y qué te cuesta no
tenerla? 🟠**

⏱️ **30 segundos** — Cuesta una lectura indexada en la tabla padre y un bloqueo de esa fila padre.
No tenerla cuesta datos huérfanos que nadie sabe cuándo entraron.

🗣️ **2 minutos** — La foránea es la única de las cuatro restricciones que toca **otra tabla** en
cada escritura: el motor baja por el índice de la clave referenciada —tres páginas en un B-tree
típico— y mantiene un bloqueo compartido sobre esa fila padre hasta el final de la transacción. Ese
bloqueo es lo que de verdad se paga en concurrencia: muchos hijos que apuntan al mismo padre
serializan más de lo que parece. Lo que no cuesta es espacio en disco.

🔬 **El detalle** — El argumento de "quitarlas por rendimiento" no elimina el problema, lo traslada:
la comprobación pasa a la aplicación, que la hace sin la transacción del motor y por tanto con una
ventana de carrera. Y falta el índice del lado hijo: si la foránea no está indexada, cada borrado
del padre obliga a un recorrido completo de la tabla hija para comprobarla. Categoría: coste medible
del motor, no del estándar.

---

**05 → 15.** **"MySQL ignora los `CHECK`, no los pongas". Responde con versión y número de error, y
di qué parte es del estándar y qué parte del motor. 🟠**

⏱️ **30 segundos** — Eso era cierto hasta 8.0.16. Desde entonces los aplica, y el 9.7.2 del lab
devuelve `ERROR 3819 (HY000): Check constraint 'pedido_lineas_chk_1' is violated.`

🗣️ **2 minutos** — Antes de 8.0.16, MySQL parseaba el `CHECK` y lo ignoraba en silencio, que es la
peor combinación posible: el esquema declara la regla y no se aplica. Su propia documentación lo
dice —*«Prior to MySQL 8.0.16, CREATE TABLE permits… but ignores»*—. El consejo sigue circulando
porque MySQL 5.7 todavía está desplegado en mucha empresa, así que la respuesta correcta en una
entrevista es "depende de la versión, y estas son las dos".

🔬 **El detalle** — Que el `CHECK` exista y se evalúe en cada escritura es del **estándar**. Que
hubiera una ventana de versiones donde se ignoraba es del **motor**. Y el mensaje concreto también:
MariaDB 12.3.3 usa otro código, `ERROR 4025 (23000): CONSTRAINT 'pedido_lineas.cantidad' failed`,
así que un código que discrimine errores por número no es portable entre MySQL y MariaDB. El riesgo
real está en la migración: con datos importados en un 5.7, entran filas con `cantidad = 0` que el
esquema declaraba imposibles.

---

**05 → 16.** **Con `GENERATED ALWAYS AS IDENTITY`, ¿por qué `ON UPDATE CASCADE` es código muerto, y
cuándo dejaría de serlo? 🟠**

⏱️ **30 segundos** — Porque el valor de una clave sustituta no cambia nunca; con `GENERATED ALWAYS`,
PostgreSQL ni siquiera admite el `UPDATE`. Dejaría de serlo con una clave natural renumerable.

🗣️ **2 minutos** — `ON UPDATE` define qué pasa cuando cambia el valor referenciado. Si la clave
primaria es un entero generado y sin significado, ese valor no tiene motivo para cambiar jamás, así
que la acción nunca se dispara. Por eso ninguna foránea del esquema del corpus declara `ON UPDATE`,
y no es un olvido. La cosa cambia si la clave referenciada es natural —un código de producto, un
NIF, un ISBN—, porque el negocio sí puede renumerarla.

🔬 **El detalle** — Dos sesiones medidas y dos frenos distintos. PostgreSQL: `UPDATE pedidos SET id =
9000042 WHERE id = 42` da `ERROR: column "id" can only be updated to DEFAULT` — ni llega a mirar la
foránea. MySQL, donde `AUTO_INCREMENT` sí deja tocar la columna: `ERROR 1451 … a foreign key
constraint fails ('tienda'.'pedido_lineas', CONSTRAINT 'fk_lineas_pedido' … ON DELETE CASCADE)`.
Fíjate en que se queja la restricción que tiene `ON DELETE CASCADE`: la cascada de borrado no dice
nada sobre las actualizaciones. El caso de clave natural no está demostrado en el lab porque ninguna
foránea del esquema apunta a una.

---

**05 → 17.** **Escribe el DDL completo de la relación N:M entre `pedidos` y `productos` tal como
está en el esquema, con las cuatro clases de restricción, y marca cuál implementa la dependencia de
la entidad débil. 🔴**

⏱️ **30 segundos** — Es `pedido_lineas`, con clave primaria `(pedido_id, linea)`, dos foráneas,
cinco `NOT NULL` y un `CHECK (cantidad > 0)`.

🗣️ **2 minutos** — El DDL de referencia:

```sql
CREATE TABLE pedido_lineas (
  pedido_id   bigint NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,  -- dependencia débil (1 de 2)
  linea       smallint NOT NULL,
  producto_id bigint NOT NULL REFERENCES productos(id),                  -- sin CASCADE: el producto no manda
  cantidad    integer NOT NULL CHECK (cantidad > 0),
  precio_unit numeric(12,2) NOT NULL,                                    -- precio congelado
  PRIMARY KEY (pedido_id, linea)                                         -- dependencia débil (2 de 2)
);
```

La dependencia de la entidad débil la implementan **dos** cláusulas a la vez: el `ON DELETE CASCADE`
de `pedido_id` y el hecho de que `pedido_id` sea la primera columna de la clave primaria. Con una
sola no hay dependencia: falta la identidad o falta el borrado.

🔬 **El detalle** — `producto_id` deliberadamente **no** lleva `ON DELETE CASCADE`: borrar un
producto no debe borrar la historia de ventas, y por eso el catálogo se retira con `activo = false`
y no con `DELETE`. Tampoco hay `UNIQUE (pedido_id, producto_id)`, decisión declarada en el capítulo.
Y `precio_unit` no tiene `CHECK`: nada impide una línea a precio negativo, que es un hueco real del
esquema.

---

**05 → 18.** **Da la secuencia de borrado que falla sobre `PED-00042` y la que funciona, con el
mensaje de error de PostgreSQL y el de MySQL. 🔴**

⏱️ **30 segundos** — Falla `DELETE FROM pedidos WHERE codigo = 'PED-00042'` directo, porque hay un
pago apuntándolo. Funciona borrando primero el pago y después el pedido.

🗣️ **2 minutos** — La que falla y su salida real en PostgreSQL:

```text
tienda=# DELETE FROM pedidos WHERE codigo = 'PED-00042';
ERROR:  update or delete on table "pedidos" violates foreign key constraint "pagos_pedido_id_fkey" on table "pagos"
DETALLE:  Key (id)=(42) is still referenced from table "pagos".
```

En MySQL el mismo borrado responde `ERROR 1451 (23000): Cannot delete or update a parent row: a
foreign key constraint fails ('tienda'.'pagos', CONSTRAINT 'fk_pagos_pedido' FOREIGN KEY
('pedido_id') REFERENCES 'pedidos' ('id'))`. La que funciona es `BEGIN; DELETE FROM pagos WHERE
pedido_id = 42; DELETE FROM pedidos WHERE id = 42; COMMIT;` — las líneas y los eventos se van solos
por `CASCADE`.

🔬 **El detalle** — En PostgreSQL también pasa en una sola sentencia, porque la acción es `NO ACTION`
y se comprueba al final: `WITH b AS (DELETE FROM pagos WHERE pedido_id=42 RETURNING id) DELETE FROM
pedidos WHERE id=42;` devuelve `DELETE 1`. Con `RESTRICT` no pasaría. Y la respuesta buena en una
entrevista añade la tercera opción: no borrar. En un dominio con dinero, cancelar un pedido es
`UPDATE pedidos SET estado = 'ANULADO'`, y los `ON DELETE` correctos son los que nunca se ejecutan.

---

**05 → 19.** **Convierte `pedidos`–`pagos` en un 1:1 real sobre 820 000 filas ya cargadas: escribe
el DDL y di qué comprobarías antes de ejecutarlo. 🔴**

⏱️ **30 segundos** — Un `UNIQUE (pedido_id)` en `pagos`, creando el índice `CONCURRENTLY` y
adosándolo después, y antes comprobar que no hay ya ningún pedido con dos pagos.

🗣️ **2 minutos** — La comprobación previa es obligatoria, porque si existe un solo duplicado el
`ALTER TABLE` falla después de haber leído las 820 000 filas:

```sql
-- 1. ¿Hay ya duplicados? Tiene que devolver cero filas.
SELECT pedido_id, count(*) FROM pagos GROUP BY pedido_id HAVING count(*) > 1;

-- 2. El índice, sin bloquear escrituras.
CREATE UNIQUE INDEX CONCURRENTLY pagos_pedido_id_key ON pagos (pedido_id);

-- 3. Adoptarlo como restricción, que es lo que el modelo declara.
ALTER TABLE pagos ADD CONSTRAINT pagos_pedido_id_key UNIQUE USING INDEX pagos_pedido_id_key;
```

🔬 **El detalle** — En el lab la consulta 1 da cero filas: el máximo de pagos por pedido es 1, así
que el dato ya respeta el 1:1 que el esquema no obliga. El paso 2 con `CONCURRENTLY` evita el
bloqueo de escrituras que impondría un `ALTER TABLE ... ADD UNIQUE` a secas, y a cambio hace dos
pasadas sobre la tabla y puede quedar `INVALID` si falla, caso en el que hay que borrar el índice y
repetir. Y conviene decidir qué pasa con los pagos parciales o los reintentos: si el negocio los
admite, el 1:1 es el modelo equivocado y lo correcto es un `UNIQUE (pedido_id, referencia)` o un
estado en el pago. Categoría: `CONCURRENTLY` es de PostgreSQL; MySQL usa DDL en línea con otra
sintaxis y otras limitaciones.

---

**05 → 20.** **Un `.db` de SQLite en producción tiene líneas huérfanas pese a declarar `REFERENCES
... ON DELETE CASCADE`. Da el diagnóstico, la consulta que lo confirma y las dos correcciones: la
del fichero y la de la aplicación. 🔴**

⏱️ **30 segundos** — Las claves foráneas nunca estuvieron activas: `PRAGMA foreign_keys` vale `0`
por defecto y hay que encenderlo en cada conexión.

🗣️ **2 minutos** — El esquema las declara, el `.schema` las muestra y el desarrollador las da por
buenas, pero SQLite no las aplica salvo que la conexión lo pida. Como el `PRAGMA` es por conexión y
no se guarda en el fichero, basta con que el pool abra una conexión sin encenderlo para que entren
huérfanas. La confirmación es doble: `PRAGMA foreign_keys;` debe dar `0`, y `PRAGMA
foreign_key_check;` lista todas las filas que violan alguna foránea, con su tabla, su `rowid` y la
restricción incumplida.

🔬 **El detalle** — Las dos correcciones. **En el fichero:** encender el `PRAGMA`, correr `PRAGMA
foreign_key_check`, limpiar o reasignar las filas que salgan y recontar. **En la aplicación:**
encender `foreign_keys = ON` en el *hook* de conexión del pool —no en el arranque, no una vez—,
porque cada conexión nueva vuelve a `0`. Medido en el lab: con el `PRAGMA` apagado entra una línea
con `pedido_id = 9000001` inexistente, y borrar `PED-00042` deja 3 líneas y 1 pago huérfanos;
encendido, las dos fallan con `Error near line 3: FOREIGN KEY constraint failed`. Categoría: motor,
y una divergencia declarada del estándar que SQLite documenta como compatibilidad hacia atrás.

---

## Capítulo 06 — Nulos y lógica de tres valores

Las 23 preguntas de [`06`](06-nulos-y-logica-de-tres-valores.md).

**06 → 1.** **¿Qué devuelve `NULL = NULL` y por qué no es `false`? 🟢**

⏱️ **30 segundos** — Devuelve `NULL`, o sea desconocido: el motor no tiene información para decidir
si dos ausencias son el mismo valor.

🗣️ **2 minutos** — `NULL` no es un valor, es la marca de que falta el dato, así que cualquier
comparación con él cae en el tercer valor lógico de SQL. Si `NULL = NULL` fuera falso, su negación
`NOT (NULL = NULL)` sería verdadera, y no lo es: también sale desconocida. Esa es justo la
diferencia con un booleano de dos estados, y de ahí salen todas las trampas del capítulo. Para
preguntar por la ausencia está `IS NULL`, que sí devuelve un booleano de verdad.

🔬 **El detalle** — Categoría: estándar; es la lógica de tres valores de ISO/IEC 9075 y los cuatro
motores del corpus coinciden, aunque no verifiqué la cláusula concreta. Detalle de lectura: `psql`
pinta el desconocido como celda **en blanco**, no como `f`, y mucha gente lee esa celda vacía como
"falso".

---

**06 → 2.** **¿Qué predicado se usa para preguntar si una columna no tiene valor, y por qué no sirve
`=`? 🟢**

⏱️ **30 segundos** — `IS NULL` (y `IS NOT NULL`). `= NULL` no sirve porque devuelve desconocido en
todas las filas, y `WHERE` descarta el desconocido.

🗣️ **2 minutos** — `IS NULL` es un predicado aparte, no azúcar de `=`: pregunta por la ausencia de
valor en lugar de comparar valores. `WHERE referencia = NULL` sobre los 820 000 pagos devuelve cero
filas aunque 273 126 tengan la referencia nula, y no da ningún error ni aviso. En la práctica el
fallo se detecta por el resultado vacío, no por el motor.

🔬 **El detalle** — Medido: `WHERE referencia = NULL` tarda 0,831 ms y `WHERE referencia IS NULL`
10,170 ms. La incorrecta es la rápida porque PostgreSQL resuelve el nodo como `Result → One-Time
Filter: false` y ni abre la tabla. Categoría: estándar, con los cuatro motores de acuerdo.

---

**06 → 3.** **Con `WHERE`, ¿qué pasa con una fila cuyo predicado da desconocido? 🟢**

⏱️ **30 segundos** — Se descarta, exactamente igual que si el predicado fuera falso. `WHERE` solo
deja pasar lo verdadero.

🗣️ **2 minutos** — Esa es la regla que hace invisible al tercer valor: desconocido se comporta como
un falso silencioso. Vale igual para `WHERE`, para el `ON` de un join y para la cláusula `HAVING`.
La consecuencia práctica es que una consulta con nulos no falla, simplemente devuelve menos filas de
las que crees, o ninguna.

🔬 **El detalle** — El contraste está en `CHECK`, que funciona al revés: una restricción solo se
considera violada cuando el predicado es **falso**, así que el desconocido ahí sí pasa. Misma lógica
de tres valores, umbral distinto. Categoría: estándar en ambos casos, con los cuatro motores
coincidiendo.

---

**06 → 4.** **Da el resultado de `falso AND desconocido`, `verdadero OR desconocido` y `NOT
desconocido`. 🟢**

⏱️ **30 segundos** — Falso, verdadero y desconocido, en ese orden.

🗣️ **2 minutos** — Las dos primeras son las filas de corte: con `AND`, un falso cierra el resultado
sin mirar el otro operando; con `OR`, un verdadero hace lo mismo. Cuando la falta de información no
cambiaría la respuesta, el motor responde igual. La tercera es la que duele: la negación no rescata
nada, el desconocido sigue siendo desconocido.

🔬 **El detalle** — De `NOT desconocido = desconocido` sale la trampa entera de `NOT IN`, porque `NOT
IN` es una cadena de `AND` con `<>` y necesita que todas las comparaciones sean verdaderas.
Categoría: estándar (lógica de tres valores de ISO/IEC 9075), verificado igual en PostgreSQL 18.6,
MySQL 9.7.2, MariaDB 12.3.3 y SQLite 3.53.4.

---

**06 → 5.** **¿Cuántos pagos hay en total y cuántos tienen referencia? Di qué agregado produce cada
número. 🟢**

⏱️ **30 segundos** — 820 000 pagos en total con `count(*)`, y 546 874 con referencia usando
`count(referencia)`.

🗣️ **2 minutos** — `count(*)` cuenta filas y `count(columna)` cuenta valores no nulos, así que la
diferencia son exactamente los 273 126 pagos en efectivo, que no llevan referencia del proveedor. No
es que un agregado sea más rápido que el otro: son preguntas distintas y devuelven números distintos
sobre la misma tabla.

🔬 **El detalle** — Desglosado por método: `EFECTIVO` 273 126 filas y 0 referencias; `TARJETA` 273
245 y 273 245; `TRANSFERENCIA` 273 629 y 273 629. Los mismos recuentos salen en los cuatro motores,
porque MySQL, MariaDB y SQLite importan los datos exportados de PostgreSQL. Categoría: estándar.

---

**06 → 6.** **¿Qué significa el nulo de `pedidos.actualizado_en` en este esquema? 🟢**

⏱️ **30 segundos** — Que nadie ha tocado el pedido desde que se creó. Es un nulo con significado, no
un hueco por rellenar.

🗣️ **2 minutos** — Hoy está nulo en el millón de pedidos, porque la semilla no actualiza ninguno. La
alternativa que mucha gente elige —copiar `creado_en` en el momento de crear— parece más limpia pero
borra información: para recuperar "nunca tocado" habría que comparar las dos columnas y confiar en
que coinciden al microsegundo. El nulo aquí es la forma más barata de decir "este evento no ha
ocurrido".

🔬 **El detalle** — El contraste dentro del mismo esquema es `pedidos.total`, que es `NOT NULL
DEFAULT 0`: un pedido siempre tiene total, aunque sea cero, y admitirlo nulo obligaría a meter
`coalesce` en cada suma del sistema. La regla de diseño: `NOT NULL` por defecto, y cada nulo se
justifica por lo que significa.

---

**06 → 7.** **¿En qué se diferencian `count(*)` y `count(referencia)` sobre la misma tabla? 🟡**

⏱️ **30 segundos** — `count(*)` cuenta filas; `count(referencia)` cuenta valores no nulos de esa
columna. Sobre `pagos` son 820 000 contra 546 874.

🗣️ **2 minutos** — Todos los agregados de columna —`count`, `sum`, `avg`, `min`, `max`— saltan los
nulos; `count(*)` es el único que no mira ninguna columna y por eso cuenta filas. La confusión
clásica es tratarlos como sinónimos con distinta velocidad, y entonces el informe cambia de número
según cuál escribiste. Para contar "cuántos pedidos hay" va `count(*)`; para "cuántos tienen
referencia registrada", `count(referencia)`.

🔬 **El detalle** — Ojo con el `count(columna)` tras un `LEFT JOIN`: ahí la columna de la tabla
derecha es nula en las filas sin pareja, así que `count(g.importe)` cuenta parejas encontradas, no
filas del resultado. Categoría: estándar; los cuatro motores coinciden.

---

**06 → 8.** **¿Por qué `IN` sí puede dar verdadero con un nulo en la lista y `NOT IN` no? 🟡**

⏱️ **30 segundos** — Porque `IN` es una cadena de `OR` y le basta un acierto, mientras que `NOT IN`
es una cadena de `AND` con `<>` y necesita que todas sean verdaderas.

🗣️ **2 minutos** — `'A' IN ('A', NULL)` se expande a `verdadero OR desconocido`, y el verdadero
corta: da verdadero. `'X' IN ('A', NULL)` es `falso OR desconocido`, que es desconocido. En cambio
`'X' NOT IN ('A', NULL)` es `verdadero AND desconocido`, que también es desconocido, y no hay ningún
valor de `X` que lo arregle. Por eso `NOT IN` sobre una lista con nulos no puede dar verdadero
nunca.

🔬 **El detalle** — El efecto no es "devuelve menos filas": es **cero filas**, porque `WHERE`
descarta el desconocido. Medido en el corpus: el informe de conciliación devuelve 0 con `NOT IN` y
173 619 con `NOT EXISTS`, con la misma intención y los mismos datos. Categoría: estándar; lo
verifiqué igual en los cuatro motores.

---

**06 → 9.** **`GROUP BY` junta los nulos en un grupo y `NULL = NULL` es desconocido: ¿cómo se
concilian? 🟡**

⏱️ **30 segundos** — Porque `GROUP BY` no usa igualdad, usa la noción de "no distinto": para
agrupar, dos nulos cuentan como el mismo valor.

🗣️ **2 minutos** — El estándar define agrupación, `DISTINCT`, `UNION` y las claves de índice sobre
"distinct from", no sobre `=`. Por eso el mismo `NULL` que no es igual a nada sí forma un grupo
consigo mismo. Son dos mecanismos diferentes y hay que aprenderlos por separado: en los agregados de
columna el nulo desaparece, en la agrupación y la deduplicación se junta.

🔬 **El detalle** — Medido: un `LEFT JOIN` de `pedidos` con `pagos` agrupado por `g.metodo` produce
un cuarto grupo sin nombre con 180 000 filas —los `PENDIENTE` y `ANULADO` sin pago—, y `SELECT
DISTINCT referencia FROM pagos` devuelve 546 875, que son los 546 874 valores más uno por todos los
nulos juntos. La excepción a la regla es `UNIQUE`, que sí usa la desigualdad y por eso admite nulos
repetidos.

---

**06 → 10.** **Diferencia entre `NULL` y la cadena vacía, y en qué motor conocido no la hay. 🟡**

⏱️ **30 segundos** — `''` es un valor con longitud cero; `NULL` es la ausencia de valor. En Oracle
no hay diferencia, porque guarda `''` como `NULL`.

🗣️ **2 minutos** — En PostgreSQL, MySQL, MariaDB y SQLite la cadena vacía se compara con `=`, es
igual a sí misma, tiene `length` 0 y choca contra un `UNIQUE` si se repite. El nulo no hace nada de
eso. La confusión viene de dos sitios: de Oracle, y de los formularios web que mandan `""` cuando el
usuario no escribe nada, con lo que la ausencia entra en la base como valor.

🔬 **El detalle** — Es un problema operativo real en este corpus: la exportación a CSV escribe el
nulo como campo vacío, y al importarlo sin `NULL '\N'` las 273 126 referencias nulas de `pagos` se
convierten en 273 126 cadenas vacías idénticas que chocan contra el `UNIQUE`. Categoría: convención
la creencia, motor la diferencia.

---

**06 → 11.** **¿`avg(importe)` y `sum(importe) / count(*)` dan lo mismo? Explica cuándo no. 🟡**

⏱️ **30 segundos** — No, cuando hay nulos: `avg` divide entre el número de valores no nulos y
`count(*)` cuenta todas las filas.

🗣️ **2 minutos** — `avg` es `sum` partido por `count(columna)`, no por `count(*)`. Mientras no haya
nulos los dos coinciden; en cuanto aparece uno, `avg` reduce el denominador y el número sube.
Ninguna de las dos fórmulas está mal: una responde "media de lo que hay" y la otra "media por fila",
y hay que decidir cuál quiere el informe antes de escribirlo.

🔬 **El detalle** — Medido sobre los pedidos `ANULADO` y `PAGADO` juntos tras un `LEFT JOIN` con
`pagos`: 310 000 pedidos, 250 000 con pago, `avg(g.importe)` = 5171,66 y `sum(g.importe) / count(*)`
= 4170,70. Un 24 % de diferencia, producida por los 60 000 anulados que no entran en el denominador
de `avg`. Categoría: estándar.

---

**06 → 12.** **¿Por qué `pagos.referencia` puede ser `UNIQUE` y tener 273 126 filas nulas a la vez?
🟡**

⏱️ **30 segundos** — Porque `UNIQUE` prohíbe que dos filas sean iguales, y dos nulos no son iguales:
son desconocidos.

🗣️ **2 minutos** — La restricción se evalúa con la misma lógica de tres valores: para rechazar una
fila el motor tiene que poder afirmar que ya existe otra con ese valor, y con nulos no puede
afirmarlo. Así que un `UNIQUE` sobre una columna anulable admite tantos nulos como filas tengas. Si
quieres que además sea obligatorio, eso lo dice `NOT NULL`, no `UNIQUE`.

🔬 **El detalle** — Verificado en transacción y deshecho con `ROLLBACK`: dos `INSERT` con referencia
nula entran (`INSERT 0 2`) y un valor repetido revienta con `duplicate key value violates unique
constraint "pagos_referencia_key"`. Igual en MySQL 9.7.2, MariaDB 12.3.3 y SQLite 3.53.4. La
excepción conocida es SQL Server, que solo admite un nulo; y desde PostgreSQL 15 existe `UNIQUE
NULLS NOT DISTINCT` para pedir ese comportamiento a propósito.

---

**06 → 13.** **¿El orden de los nulos en `ORDER BY … ASC` lo fija el estándar o el motor? Di qué
hace cada uno. 🟠**

⏱️ **30 segundos** — Lo fija el motor. PostgreSQL los pone al final en `ASC`; MySQL, MariaDB y
SQLite los ponen al principio.

🗣️ **2 minutos** — El estándar deja la posición del nulo a la implementación y solo le pide
coherencia, por eso la respuesta correcta en una entrevista es "depende del motor, y aquí está el
mío". En los cuatro, `DESC` invierte también los nulos, así que no es un caso especial: cada motor
trata el nulo como el extremo alto o el extremo bajo del dominio. Esto muerde de verdad en la
paginación por clave y en los tests que corren contra un motor distinto al de producción.

🔬 **El detalle** — Comprobado con `SELECT id, referencia FROM pagos ORDER BY referencia LIMIT 3` en
los cuatro: PostgreSQL 18.6 devuelve `REF-000000001` primero, y MySQL 9.7.2, MariaDB 12.3.3 y SQLite
3.53.4 devuelven las filas de `EFECTIVO` con referencia nula. Para fijarlo: `NULLS FIRST` / `NULLS
LAST` en PostgreSQL y SQLite, y `ORDER BY referencia IS NULL, referencia` cuando tiene que funcionar
también en MySQL y MariaDB.

---

**06 → 14.** **`IS NOT DISTINCT FROM` y `<=>`: ¿cuál es estándar, cuál de motor, y quién admite cada
uno? 🟠**

⏱️ **30 segundos** — `IS NOT DISTINCT FROM` es el estándar; `<=>` es una extensión de MySQL y
MariaDB. Los dos comparan tratando dos nulos como iguales.

🗣️ **2 minutos** — Es el caso de manual de "lo que hace tu motor no es lo que manda la norma": `<=>`
aparece en todos los tutoriales de MySQL y no existe en ningún otro motor del corpus. PostgreSQL y
SQLite implementan la forma estándar; SQLite además tiene sus propios `IS` / `IS NOT`, que hacen
exactamente lo mismo. Sirve para comparaciones seguras con nulos: sincronizaciones, detección de
cambios entre dos versiones de una fila, `MERGE`.

🔬 **El detalle** — Verificado: en MySQL 9.7.2 y MariaDB 12.3.3, `NULL <=> NULL` devuelve `1` y `'A'
<=> NULL` devuelve `0`, mientras que `SELECT NULL IS NOT DISTINCT FROM NULL` responde `ERROR 1064
(42000) … near 'DISTINCT FROM NULL'`. En SQLite 3.53.4 esa misma expresión devuelve `1` y en
PostgreSQL 18.6 `true`; ninguno de los dos entiende `<=>` (SQLite responde `Parse error … near
">"`).

---

**06 → 15.** **`= NULL` tarda 0,8 ms y `IS NULL` 10 ms: ¿por qué la incorrecta es la rápida, y qué
dice su plan? 🟠**

⏱️ **30 segundos** — Porque el planificador sabe de antemano que `columna = NULL` no puede ser
verdadero, así que no lee la tabla.

🗣️ **2 minutos** — El plan lo dice literalmente: el nodo es un `Result` con `One-Time Filter: false`
bajo el `Aggregate`, sin ningún acceso a `pagos`. La versión correcta con `IS NULL` sí recorre las
820 000 filas y devuelve 273 126, y por eso tarda diez veces más. Es un buen recordatorio de que
"rápido" y "correcto" son ejes distintos, y de que una consulta instantánea sobre una tabla grande
merece una mirada al plan.

🔬 **El detalle** — Las cifras exactas medidas en el entorno del corpus: 0,831 ms contra 10,170 ms.
Categoría: el resultado —cero filas— es estándar; el hecho de que se vea como `One-Time Filter:
false` es de PostgreSQL, y otros motores lo expresarán distinto en su propio `EXPLAIN`.

---

**06 → 16.** **Un `CHECK (actualizado_en > creado_en)` se acepta sobre un millón de filas con esa
columna nula: ¿por qué, y cómo lo escribirías para rechazarlas? 🟠**

⏱️ **30 segundos** — Porque un `CHECK` solo se viola cuando el predicado es **falso**; con la
columna nula da desconocido y la fila pasa. Para rechazarlas hay que exigir el `IS NOT NULL` dentro
del propio `CHECK`.

🗣️ **2 minutos** — Es la grieta menos conocida del tema, y la más peligrosa, porque una restricción
que no protege nada parece que protege. `pedidos.actualizado_en` es nulo en el millón de filas, así
que ninguna cumple el predicado y ninguna lo viola: el `ALTER TABLE` pasa sin una queja. La versión
que sí rechaza es `CHECK (actualizado_en IS NOT NULL AND actualizado_en > creado_en)`; si el nulo es
legítimo, lo correcto es dejar el `CHECK` como está y documentar por qué.

🔬 **El detalle** — Medido en transacción y deshecho con `ROLLBACK`: la validación del `CHECK` sobre
el millón de filas tarda 62,616 ms. Categoría: estándar; los cuatro motores lo tratan igual, aunque
SQLite y MySQL difieren en cuándo revalidan al alterar la tabla.

---

**06 → 17.** **Tras un `LEFT JOIN`, `WHERE g.metodo <> 'EFECTIVO'` tira las filas sin pago: por qué,
y dos arreglos. 🟠**

⏱️ **30 segundos** — Porque en las filas sin pareja `g.metodo` es nulo, el `<>` da desconocido y
`WHERE` lo descarta: el `LEFT JOIN` se convierte en `INNER JOIN`.

🗣️ **2 minutos** — Es el error de nulos más caro en consultas de informe, porque el resultado sigue
pareciendo razonable. Dos arreglos: usar `WHERE g.metodo IS DISTINCT FROM 'EFECTIVO'`, que trata el
nulo como "distinto" y conserva las filas sin pareja; o mover la condición al `ON`, con lo que
filtras qué pagos emparejan sin tocar qué pedidos sobreviven. Los dos son correctos, pero responden
a preguntas diferentes y hay que elegir a conciencia.

🔬 **El detalle** — Medido: `WHERE g.metodo <> 'EFECTIVO'` devuelve 546 874 filas y `WHERE g.metodo
IS DISTINCT FROM 'EFECTIVO'` devuelve 726 874. Las 180 000 de diferencia son los pedidos `PENDIENTE`
y `ANULADO` sin pago. `IS DISTINCT FROM` es estándar y está en PostgreSQL y SQLite; en MySQL y
MariaDB el equivalente es `NOT (g.metodo <=> 'EFECTIVO')`.

---

**06 → 18.** **¿Qué plan eligió el motor para `NOT EXISTS` y cuál para el `NOT IN` ya corregido, y
por qué la ventaja de `NOT EXISTS` no es la velocidad? 🟠**

⏱️ **30 segundos** — `NOT EXISTS` sale como `Hash Right Anti Join`; el `NOT IN` corregido, como un
`Seq Scan` que filtra contra la lista de la subconsulta, `hashed SubPlan`. Tardan lo mismo: la
ventaja de `NOT EXISTS` es que es correcto por construcción.

🗣️ **2 minutos** — `NOT IN` con subconsulta no se transforma en anti-join de forma general, justo
porque su semántica con nulos es distinta: el planificador tiene que preservar el "si hay un nulo,
no devuelvas nada". Con esta tabla, filtrar contra la lista en memoria cuesta lo mismo que el
anti-join, así que el plan distinto no se nota en el reloj. Lo que sí se nota es el mantenimiento:
el `IS NOT NULL` del `NOT IN` desaparece en la primera refactorización que toque la subconsulta.

🔬 **El detalle** — Medido en ocho corridas alternas sobre `pagos`: mediana de 228 ms con `NOT
EXISTS` y 234 con el `NOT IN` corregido, los dos devolviendo 173 619. Una primera medida suelta dio
163 frente a 212 y se publicó como «un 23 % más rápido»; repetida, la diferencia es ruido. El plan
es **motor** —una decisión del planificador de PostgreSQL 18.6, no del estándar—.

---

**06 → 19.** **Decide si `pedidos.total` debe admitir nulos, y el coste de equivocarse en cada
dirección. 🟠**

⏱️ **30 segundos** — No debe: `NOT NULL DEFAULT 0`. Un pedido siempre tiene total, aunque sea cero.

🗣️ **2 minutos** — La pregunta que decide siempre es la misma: ¿existe una fila donde este dato
legítimamente no exista? Para el total de un pedido, no; para la referencia de un pago en efectivo,
sí. Si lo dejas anulable, el nulo se cuela por la aplicación en algún camino raro y a partir de ahí
toda suma, toda comparación y todo informe necesitan `coalesce` para siempre, además de que `sum` y
`avg` empiezan a responder preguntas distintas sin avisar.

🔬 **El detalle** — El precio no es simétrico, y por eso la regla es `NOT NULL` por defecto: un `NOT
NULL` que sobra se quita con un `ALTER TABLE ... DROP NOT NULL` inmediato, mientras que uno que
falta deja años de filas ya escritas que hay que limpiar antes de poder añadirlo. En PostgreSQL,
añadir `NOT NULL` a una tabla grande exige una validación completa, así que el coste sube con el
tiempo.

---

**06 → 20.** **Reescribe el `NOT IN` de §1 para que dé las 173 619 filas, en dos versiones; di cuál
dejas. 🔴**

⏱️ **30 segundos** — Con `NOT EXISTS`, o con un `IS NOT NULL` dentro de la subconsulta. En el
repositorio dejo la de `NOT EXISTS`.

🗣️ **2 minutos** — La primera versión es `... AND NOT EXISTS (SELECT 1 FROM pagos q WHERE
q.pagado_en < '2024-01-01' AND q.referencia = p.referencia)`, con alias en la consulta externa. La
segunda conserva el `NOT IN` y añade `AND referencia IS NOT NULL` a la subconsulta. Las dos
devuelven 173 619, pero la segunda depende de que alguien se acuerde de escribirla cada vez, y
desaparece en la primera refactorización que toque esa subconsulta. La de `NOT EXISTS` es correcta
por construcción.

🔬 **El detalle** — Medido en §3 y §5 del capítulo: el `NOT IN` original devuelve 0 en 208 ms; las
dos correcciones, 173 619 en el mismo tiempo, alrededor de 230 ms. Coinciden en 173 619 porque
ningún pago con tarjeta tiene referencia nula; si la columna exterior también fuera anulable, las
dos versiones dejarían de ser equivalentes y habría que decidir explícitamente qué quieres para esa
fila.

---

**06 → 21.** **Da la tabla de verdad completa de `AND`, `OR` y `NOT` con tres valores. 🔴**

⏱️ **30 segundos** — Nueve combinaciones; lo que hay que recordar es que el falso corta en `AND`, el
verdadero corta en `OR`, y `NOT desconocido` sigue siendo desconocido.

🗣️ **2 minutos** — Con `a` en filas y `b` en columnas, y escribiendo D por desconocido: `AND` da V
solo con V,V; da F siempre que uno sea F —incluido `F AND D`—; y da D en el resto. `OR` da F solo
con F,F; da V siempre que uno sea V —incluido `V OR D`—; y da D en el resto. `NOT` invierte V y F y
deja D igual. Todo lo demás del capítulo se deduce de aquí.

🔬 **El detalle** — En tabla, corrido contra PostgreSQL 18.6 con `VALUES (true),(false),(NULL)`
cruzado consigo mismo:

| `a` | `b` | `a AND b` | `a OR b` | `NOT a` |
|---|---|---|---|---|
| F | F | F | F | V |
| F | V | F | V | V |
| F | D | **F** | D | V |
| V | F | F | V | F |
| V | V | V | V | F |
| V | D | D | **V** | F |
| D | F | **F** | D | D |
| D | V | D | **V** | D |
| D | D | D | D | D |

Las cuatro celdas en negrita son las interesantes: son las que demuestran que el corte funciona.
Categoría: estándar (ISO/IEC 9075), igual en los cuatro motores.

---

**06 → 22.** **Escribe un `ORDER BY referencia` que ponga los nulos al final en los cuatro motores,
sabiendo que dos no admiten `NULLS LAST`. 🔴**

⏱️ **30 segundos** — `ORDER BY referencia IS NULL, referencia`: la primera clave es un booleano que
vale 0 para los valores y 1 para los nulos, así que los nulos caen al final en todos.

🗣️ **2 minutos** — Funciona porque `IS NULL` devuelve siempre un booleano de dos estados, nunca
desconocido, y ordenar por él es completamente determinista. En PostgreSQL el booleano ordena
`false` antes que `true`; en MySQL, MariaDB y SQLite la expresión da 0 o 1 y ordena igual. Donde
puedas asumir el motor, la forma legible es `ORDER BY referencia NULLS LAST`, que PostgreSQL y
SQLite entienden; MySQL y MariaDB responden `ERROR 1064`. El truco antiguo de MySQL, `ORDER BY
-referencia DESC`, solo vale para números y no lo usaría.

🔬 **El detalle** — Verificado: `ORDER BY referencia LIMIT 3` da `REF-000000001` en PostgreSQL 18.6 y
filas de `EFECTIVO` con referencia nula en MySQL 9.7.2, MariaDB 12.3.3 y SQLite 3.53.4; `NULLS LAST`
se acepta en PostgreSQL y SQLite y falla con `ERROR 1064 (42000)` en los otros dos. Categoría: el
estándar define `NULLS FIRST`/`NULLS LAST` en `<sort specification>` pero **no** fija el orden por
defecto, que es de cada motor.

---

**06 → 23.** **Diseña la comprobación previa a un despliegue que encuentre los `NOT IN` peligrosos
del repositorio: qué buscas, qué descartas y qué consulta del catálogo dice si la columna es
anulable. 🔴**

⏱️ **30 segundos** — Busco los `NOT IN` con subconsulta, descarto los de lista literal sin `NULL`, y
para cada columna de la subconsulta miro `is_nullable` en `information_schema.columns`.

🗣️ **2 minutos** — En tres pasos. Primero, un `grep -rniE 'not[[:space:]]+in[[:space:]]*\('` sobre
el código y las migraciones, incluyendo el SQL embebido en el ORM. Segundo, el triaje: un `NOT IN
('A','B')` con literales no nulos es seguro y sale de la lista; lo que queda son los `NOT IN (SELECT
…)`, más los `NOT IN (?)` con parámetros que puedan traer nulos desde la aplicación. Tercero, por
cada subconsulta anoto tabla y columna proyectada y consulto el catálogo; si es anulable, el
hallazgo es real y se reescribe con `NOT EXISTS`. Cerraría añadiendo la regla al linter de SQL o a
la revisión de código, porque el hallazgo se repite.

🔬 **El detalle** — La consulta del catálogo en PostgreSQL:

```sql
SELECT table_name, column_name, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND is_nullable = 'YES'
ORDER BY table_name, column_name;
```

`information_schema` es estándar y existe también en MySQL y MariaDB; SQLite no lo tiene y hay que
usar `PRAGMA table_info(pagos)`, donde la columna `notnull` vale 0 si admite nulos. Un matiz que da
nota: una columna declarada `NOT NULL` puede aun así producir nulos en la subconsulta si viene de un
`LEFT JOIN` o de una expresión, así que el catálogo descarta casos pero no absuelve a todos.

---

## Simulación de entrevista

Las 28 preguntas `S#` y los cuatro escenarios de [`07`](07-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se diseñan en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**07 → S1.** **¿Qué es una clave candidata, y cuántas tiene `clientes` en este esquema? 🟢**

⏱️ **30 segundos** — Un conjunto mínimo de columnas que identifica una fila de forma única.
`clientes` tiene tres: `id`, `codigo` y `email`.

🗣️ **2 minutos** — Mínimo es la palabra que hace el trabajo: si le quitas una columna deja de
identificar, y si le añades una deja de ser mínimo. De las candidatas eliges una como primaria y las
demás quedan como alternativas, normalmente declaradas con `UNIQUE`. En `clientes` la primaria es
`id` y las alternativas son `codigo` y `email`.

🔬 **El detalle** — Se comprueba en el catálogo: `pg_constraint` para `clientes` devuelve tres
restricciones —`clientes_pkey`, `clientes_codigo_key` y `clientes_email_key`—. Que `email` sea
candidata es una decisión discutible del esquema, no una verdad del dominio: el día que dos personas
compartan correo, esa candidata desaparece. Es **estándar** el concepto y **motor** que declarar la
clave cree además un índice.

---

**07 → S2.** **El esquema guarda `id` y `codigo` en todas las tablas. Explica por qué las dos, y
cuál de las dos expondrías en la URL de una API. 🟠**

⏱️ **30 segundos** — `id` es la clave sustituta, interna y sin significado; `codigo` es la natural,
la que el usuario ve y dice por teléfono. En la URL expongo `codigo`.

🗣️ **2 minutos** — La sustituta existe porque es estable, estrecha y nunca cambia: sirve de destino
para las claves foráneas sin que un cambio de negocio obligue a propagarlo. La natural existe porque
el humano necesita referirse al pedido, y `PED-00042` se dicta por teléfono y `1000042` no. Exponer
la sustituta en la API filtra información —el ritmo de crecimiento del negocio, que un competidor
lee pidiendo dos recursos con un día de diferencia— y ata tu contrato público a un detalle de
implementación.

🔬 **El detalle** — El precio de mantener las dos es espacio e índices: en este corpus `pedidos_pkey`
ocupa 21 MB y `pedidos_codigo_key` 30 MB sobre una tabla de 84 MB. Son 30 MB por la comodidad de
tener un identificador legible, y es un intercambio que se defiende. La alternativa moderna —UUIDv7
como clave primaria, que es a la vez sustituta y exponible— cambia el problema de sitio pero no lo
elimina: sigue filtrando el orden de creación.

---

**07 → S3.** **`pedido_lineas` tiene clave primaria `(pedido_id, linea)`. ¿Qué te dice eso sobre la
identidad de una línea, y qué nombre recibe esa clase de entidad? 🟡**

⏱️ **30 segundos** — Que una línea no existe por sí sola: su identidad depende del pedido al que
pertenece. Se llama entidad débil.

🗣️ **2 minutos** — La línea 2 no significa nada sin decir de qué pedido. Por eso la clave es
compuesta y por eso lleva `ON DELETE CASCADE`: si el pedido desaparece, sus líneas no tienen a qué
colgarse. El número de línea es un discriminador dentro del padre, no un identificador global. Lo
contrario sería darle a `pedido_lineas` su propio `id` sustituto y declarar `UNIQUE (pedido_id,
linea)`, que también es válido y es lo que hacen casi todos los ORM.

🔬 **El detalle** — La consecuencia medible: hay **1 000 000 de filas con `linea = 1`**, una por
pedido, y eso demuestra que `linea` por sí sola no identifica nada. El orden de las columnas en la
clave compuesta no es indiferente: `(pedido_id, linea)` permite buscar todas las líneas de un pedido
por el índice de la primaria, y `(linea, pedido_id)` no. Ese detalle es **motor** y tiene su
capítulo en el bloque de índices.

---

**07 → S4.** **Un compañero propone cambiar la clave primaria de `pedidos` de `id` a `codigo`, "que
ya es único y además significa algo". Da tres consecuencias concretas, con números si puedes. 🔴**

⏱️ **30 segundos** — Engorda todas las claves foráneas que apuntan a `pedidos`, expone el negocio en
el contrato, y ata la identidad a un dato que el día que el negocio cambie de formato habrá que
propagar a millones de filas.

🗣️ **2 minutos** — La primera es puro tamaño: `pedido_lineas` tiene 3 500 000 filas y
`eventos_pedido` 4 100 000, y cada una lleva la referencia al pedido. Pasar de un `bigint` de ocho
bytes a un `text` de ancho variable multiplica el espacio de esas columnas y de todos sus índices.
La segunda es que lo natural cambia: basta que marketing decida que los pedidos de la nueva región
llevan otro prefijo para que tengas que actualizar la clave en cascada por tres tablas. La tercera
es que un `text` compara más caro que un entero en cada join y en cada descenso por el B-tree.

🔬 **El detalle** — Medido en este corpus: la columna replicada en los 3,5 millones de líneas ocupa
27 MB como `bigint` y 36 MB como `text`, con anchos medios de 8 y 10,9 bytes. Son 9 MB en una tabla,
y `eventos_pedido` tiene más filas todavía. La respuesta completa reconoce el punto legítimo de tu
compañero —una clave con significado ahorra un join cuando solo necesitas el código— y propone lo
que el esquema ya hace: sustituta como primaria y natural como `UNIQUE`, que da las dos cosas.

---

**07 → S5.** **¿Declarar una clave crea un índice? ¿Lo manda el estándar o lo decide cada motor? 🟠**

⏱️ **30 segundos** — Se crea en los tres motores, pero es decisión del motor, no del estándar. El
estándar exige que la unicidad se cumpla, no cómo.

🗣️ **2 minutos** — La diferencia importa porque explica un comportamiento que confunde: en
PostgreSQL y en MySQL una `PRIMARY KEY` o un `UNIQUE` crean un índice automáticamente, así que la
restricción y la estructura de datos vienen juntas. Pero una clave **foránea** no crea índice en
PostgreSQL y sí en InnoDB, y esa asimetría es la causa de que la misma consulta vuele en un motor y
se arrastre en el otro tras portar un esquema.

🔬 **El detalle** — Es **motor**, y se ve en el catálogo: este esquema declara seis primarias y cinco
restricciones `UNIQUE`, y `pg_indexes` sobre `public` devuelve exactamente **11 índices**, ni uno
más. En MySQL, `SHOW CREATE TABLE pagos` muestra una `KEY fk_pagos_pedido` que nadie escribió: la
creó InnoDB para su clave foránea. Si portas de MySQL a PostgreSQL y no recreas esos índices a mano,
los `JOIN` por la foránea pasan a barrido secuencial.

---

**07 → S6.** **`pedidos.total` duplica lo que se puede calcular desde `pedido_lineas`. ¿Qué forma
normal viola, y por qué está ahí de todas formas? 🟡**

⏱️ **30 segundos** — Es una dependencia transitiva sobre un valor derivable, así que rompe 3FN. Está
ahí porque el agregado que la evita cuesta casi diez veces más.

🗣️ **2 minutos** — En rigor, un valor calculable a partir de otras tablas no debería almacenarse:
cualquier duplicación abre la puerta a que las dos copias discrepen. La concesión se hace porque el
informe que suma el negocio del trimestre no puede permitirse recalcular tres millones y medio de
líneas cada vez. Es desnormalización deliberada, que no es lo mismo que un esquema mal normalizado:
la diferencia está en que se sabe qué se rompió, por qué, y qué se hace para detectarlo.

🔬 **El detalle** — El número que la sostiene, medido: el agregado sobre los pedidos ENTREGADO tarda
**69,404 ms** leyendo `total` y **606,118 ms** recalculando por `JOIN`, con el mismo resultado; en
páginas, **10 770 buffers contra 39 937**. Las formas normales son **teoría relacional** —Codd y
Boyce—, no ISO/IEC 9075, y esa precisión es parte de la respuesta.

---

**07 → S7.** **`pedido_lineas.precio_unit` también parece duplicar `productos.precio`. ¿Por qué esa
sí es legítima y la anterior es una concesión? 🟠**

⏱️ **30 segundos** — Porque no es una copia: es el precio congelado en el momento de la compra. No
depende del producto, depende del par producto-instante.

🗣️ **2 minutos** — Es la distinción entre redundancia y dato histórico, y casi nadie la sabe
explicar. `pedidos.total` se puede recalcular hoy y da el mismo valor, así que es redundante.
`precio_unit` **no** se puede recalcular: si el producto subió de precio el mes pasado,
`productos.precio` ya no te dice lo que el cliente pagó. Borrarlo destruiría información, no la
comprimiría. Por eso no viola 3FN: no hay dependencia funcional de `producto_id` hacia
`precio_unit`.

🔬 **El detalle** — Y se demuestra formalmente buscando contraejemplos. La consulta que busca
productos con más de un `precio_unit` distinto devuelve **exactamente 1**: `PRD-00017`, con **20 205
líneas y 2 792 precios distintos** frente a un precio de catálogo de 31,79. Ese único contraejemplo
es la prueba de que la dependencia funcional no existe, y por tanto de que no hay violación que
corregir.

---

**07 → S8.** **¿Las formas normales las fija ISO/IEC 9075? 🟡**

⏱️ **30 segundos** — No. Son teoría relacional, de Codd y Boyce. El estándar SQL define el lenguaje,
no cómo debes diseñar tu esquema.

🗣️ **2 minutos** — Es una confusión frecuente porque las dos cosas se estudian juntas. El estándar
te dice qué significa `CREATE TABLE`, qué es una restricción y cómo se comporta un `JOIN`; no tiene
ninguna opinión sobre si tu tabla debería estar en tercera forma normal. Nada en 9075 te impide
escribir un esquema espantoso perfectamente válido.

🔬 **El detalle** — El único sitio del estándar donde asoma algo parecido a la dependencia funcional
es la cláusula de `GROUP BY`, cuando permite seleccionar columnas *funcionalmente dependientes* de
las agrupadas. Y ahí los motores divergen: PostgreSQL 18.6 solo hace ese análisis sobre la clave
primaria y da `ERROR: column "p.id" must appear in the GROUP BY clause`, mientras que MySQL 9.7.2
con `ONLY_FULL_GROUP_BY` activo lo hace sobre **cualquier clave candidata** y devuelve la fila. **No
he verificado la numeración de la cláusula**: el estándar es de pago.

---

**07 → S9.** **Escribe la consulta que detecta si algún `pedidos.total` se ha desincronizado, y di
cada cuánto la correrías y por qué. 🔴**

⏱️ **30 segundos** — Un `JOIN` contra el agregado de las líneas, filtrando por desigualdad. La
correría a diario, fuera de hora punta, y alertaría con cualquier resultado distinto de cero.

🗣️ **2 minutos** — La consulta es `SELECT count(*) FROM pedidos p JOIN (SELECT pedido_id,
sum(cantidad*precio_unit) s FROM pedido_lineas GROUP BY pedido_id) t ON t.pedido_id = p.id WHERE
p.total <> t.s`. La frecuencia sale del riesgo: es un agregado sobre toda la tabla, así que no puede
correr en cada escritura, pero un desfase que tarda una semana en detectarse ya contaminó los
informes del mes. Diario y de madrugada es el equilibrio razonable.

🔬 **El detalle** — El coste medido sobre el millón de pedidos es **1 819,711 ms**, que es
perfectamente asumible una vez al día y absurdo cada minuto. El resultado hoy es **0**. Lo
importante de la respuesta no es la consulta, que es obvia, sino la parte que casi nadie dice:
**esta consulta es la que convierte la desnormalización en una decisión defendible**. Sin ella,
`pedidos.total` es un error; con ella, es un intercambio con control.

---

**07 → S10.** **Guardar `jsonb` en `eventos_pedido.carga`, ¿viola la primera forma normal? 🟠**

⏱️ **30 segundos** — Formalmente sí, porque el valor no es atómico. En la práctica es legítimo si
nunca consultas por dentro para unir o filtrar de forma crítica.

🗣️ **2 minutos** — La 1FN exige valores atómicos, y un documento JSON es una estructura. El
argumento a favor es que un evento es un registro inmutable de algo que pasó, con forma variable
según el tipo, y modelar cada variante como columnas obligaría a una tabla con treinta columnas
nulas o a seis tablas con herencia. El argumento en contra es que en cuanto empiezas a filtrar por
un campo de dentro en una consulta caliente, has perdido las restricciones, el tipado y buena parte
de las estadísticas del planificador.

🔬 **El detalle** — Lo que de verdad se pierde no es la pureza teórica: es que el motor no puede
declarar `NOT NULL` ni `CHECK` sobre un campo interno, ni mantener estadísticas de selectividad
sobre él como sobre una columna. La regla práctica: **lo que consultas, columna; lo que archivas,
documento**. Y si un campo del documento se vuelve consulta caliente, se promueve a columna
—posiblemente generada— y se indexa. Es **motor** que `jsonb` de PostgreSQL admita índices GIN sobre
su contenido, cosa que el `JSON` de MySQL resuelve de otra forma.

---

**07 → S11.** **¿Por qué `NULL = NULL` no es verdadero? 🟢**

⏱️ **30 segundos** — Porque `NULL` significa "desconocido", y dos valores desconocidos no se sabe si
son iguales. El resultado es desconocido, no falso.

🗣️ **2 minutos** — Si no sé la edad de Ana y no sé la de Luis, preguntar si tienen la misma edad no
se responde con sí ni con no: se responde con "no lo sé". Eso es la lógica de tres valores, y de ahí
sale todo el comportamiento raro de los nulos: `WHERE` solo deja pasar lo que es verdadero, así que
descarta tanto lo falso como lo desconocido. Por eso se compara con `IS NULL`, que sí es una
pregunta con respuesta binaria.

🔬 **El detalle** — Se ve en el plan: `WHERE referencia = NULL` devuelve 0 filas en 0,831 ms con un
nodo `Result → One-Time Filter: false` —el motor ni mira la tabla, sabe de antemano que nada puede
pasar—, mientras que `WHERE referencia IS NULL` devuelve 273 126 en 10,170 ms. La comparación segura
existe y es `IS NOT DISTINCT FROM` en el estándar y en PostgreSQL; MySQL y MariaDB usan `<=>`, que
no es estándar, y rechazan la forma estándar con `ERROR 1064`.

---

**07 → S12.** **`pagos.referencia` es `UNIQUE` y hay 273 126 filas con el valor nulo. ¿Por qué no
chocan entre sí? 🟡**

⏱️ **30 segundos** — Porque `UNIQUE` prohíbe valores iguales, y dos nulos no son iguales: son
desconocidos. La restricción nunca llega a considerarlos duplicados.

🗣️ **2 minutos** — Es consecuencia directa de la lógica de tres valores, no una excepción
arbitraria. La restricción se pregunta si el valor nuevo es igual a alguno existente; con nulos la
respuesta es "desconocido", nunca "sí", así que no hay violación. Es útil y deliberado: permite
modelar "este campo es único cuando existe", que es exactamente el caso de `referencia` —los pagos
en efectivo no tienen referencia de proveedor—.

🔬 **El detalle** — PostgreSQL 15 añadió la forma de pedir lo contrario: `UNIQUE NULLS NOT DISTINCT`,
que trata todos los nulos como el mismo valor. Sobre esta tabla falla hoy con `Key
(referencia)=(null) is duplicated`, lo que prueba lateralmente que hay nulos repetidos conviviendo
bajo la restricción normal. El comportamiento por defecto —nulos distintos— es **estándar** y
coincide en los cuatro motores.

---

**07 → S13.** **Un informe con `NOT IN (SELECT referencia FROM pagos …)` devuelve cero filas y nadie
entiende por qué. Diagnostica en voz alta y da la corrección. 🔴**

⏱️ **30 segundos** — La subconsulta devuelve algún `NULL`, y `NOT IN` con un nulo dentro nunca es
verdadero para ninguna fila. Se corrige con `NOT EXISTS`.

🗣️ **2 minutos** — `x NOT IN (a, b, NULL)` se expande a `x <> a AND x <> b AND x <> NULL`. Ese
último término es desconocido, y verdadero AND desconocido es desconocido, así que la condición
entera nunca llega a verdadera y `WHERE` no deja pasar nada. Da cero filas sin error y sin aviso,
que es lo que lo hace peligroso: parece un resultado, no un fallo. Y explica por qué "de repente"
dejó de funcionar: bastó que entrara el primer pago sin referencia.

🔬 **El detalle** — Medido sobre este corpus: la versión con `NOT IN` devuelve **0 filas en 208 ms**
y la equivalente con `NOT EXISTS` devuelve **173 619 filas en 170 ms**. La subconsulta arrastra 98
897 referencias nulas. Filtrar con `IS NOT NULL` dentro de la subconsulta también corrige, y en el
mismo tiempo, pero deja la trampa a la vista del siguiente que edite la consulta. La regla: **`NOT
EXISTS` por defecto, y `NOT IN` solo sobre una lista literal o una columna `NOT NULL`**.

---

**07 → S14.** **Diferencia entre `COUNT(*)` y `COUNT(referencia)` sobre `pagos`, con los dos
números. 🟢**

⏱️ **30 segundos** — `COUNT(*)` cuenta filas y da 820 000; `COUNT(referencia)` cuenta valores no
nulos y da 546 874.

🗣️ **2 minutos** — `COUNT(*)` no mira ninguna columna: cuenta cuántas filas cumplen el `WHERE`.
`COUNT(columna)` descarta los nulos, porque los agregados ignoran los nulos por definición en el
estándar. La diferencia entre los dos números es exactamente el número de nulos: 273 126, que son
los pagos en efectivo. Es la forma más rápida de saber cuántos nulos tiene una columna sin escribir
un `WHERE`.

🔬 **El detalle** — El mismo principio muerde en `AVG`, y ahí sí produce números equivocados que
nadie revisa: `avg(columna)` divide entre las filas **no nulas**, no entre el total. Sobre este
corpus, `avg` frente a `sum/count(*)` sobre los pedidos ANULADO y PAGADO da 5 171,66 contra 4
170,70, un 24 % de diferencia. Si lo que querías era "el importe medio por pedido, contando los que
no tienen", `avg` te miente. Es **estándar** y los cuatro motores coinciden.

---

**07 → S15.** **¿Dónde coloca cada motor los nulos en un `ORDER BY … ASC`, y cómo escribes un orden
que se comporte igual en los cuatro? 🟠**

⏱️ **30 segundos** — PostgreSQL los pone al final; MySQL, MariaDB y SQLite al principio. Para que
sea portable: `ORDER BY referencia IS NULL, referencia`.

🗣️ **2 minutos** — El estándar deja la posición al implementador, así que cada uno eligió.
PostgreSQL trata el nulo como mayor que cualquier valor, de ahí que en ascendente quede al final;
los otros tres lo tratan como menor. La consecuencia práctica es que una consulta paginada portada
de un motor a otro cambia de primera página sin que nadie toque el SQL.

🔬 **El detalle** — `NULLS FIRST` y `NULLS LAST` son la forma explícita, pero **solo funcionan en
PostgreSQL y SQLite**: MySQL y MariaDB responden `ERROR 1064`. Por eso el apaño portable es una
expresión booleana en el `ORDER BY`: `referencia IS NULL` da 0 o 1, y ordenar por ella primero
coloca los no nulos delante en los cuatro. Es **motor** puro, y de las diferencias que más se notan
al portar.

---

**07 → S16.** **`pedido_lineas` y `eventos_pedido` tienen `ON DELETE CASCADE`; `pagos` no. ¿Es un
olvido? Defiende la asimetría. 🟠**

⏱️ **30 segundos** — No es olvido: es la decisión correcta. Una línea sin su pedido no significa
nada; un pago sin su pedido sigue siendo dinero que entró.

🗣️ **2 minutos** — La cascada expresa dependencia existencial: la línea y el evento son partes del
pedido y mueren con él. El pago no: es un hecho contable con vida propia, que aparece en la
conciliación bancaria y que un auditor puede pedir años después. Que el borrado del pedido falle
cuando hay pagos no es un estorbo, es la restricción haciendo su trabajo y obligándote a decidir
explícitamente qué haces con el dinero.

🔬 **El detalle** — El efecto es medible y silencioso: `DELETE FROM pedidos WHERE codigo='PED-99999'`
devuelve `DELETE 1` y se lleva por delante **6 líneas y 6 eventos** sin decir una palabra. Con
`pagos` el mismo borrado habría fallado. Y una observación que sube la nota: en la práctica, casi
ningún sistema que maneje dinero borra pedidos —usa borrado lógico— precisamente para no tener esta
conversación. La cascada está ahí para el caso legítimo de corregir datos de prueba o de aplicar el
derecho al olvido.

---

**07 → S17.** **¿Qué devuelve `PRAGMA foreign_keys` en una conexión nueva de SQLite, y qué implica
para una suite de pruebas? 🟡**

⏱️ **30 segundos** — Devuelve `0`: vienen apagadas. Implica que tu suite no está probando la
integridad referencial salvo que alguien lo encienda en cada conexión.

🗣️ **2 minutos** — Es por compatibilidad hacia atrás: las claves foráneas llegaron tarde a SQLite y
encenderlas por defecto habría roto bases existentes. Lo peligroso es que el esquema las declara,
así que el DDL parece correcto y nadie sospecha. Una inserción huérfana entra y `changes()` devuelve
1, sin error. Y no basta con ponerlo una vez: es por conexión, así que cada pool, cada hilo y cada
reconexión necesita el `PRAGMA`.

🔬 **El detalle** — Comprobado en SQLite 3.53.4: apagado, un `INSERT` con `pedido_id = 9000001`
inexistente entra sin queja, y un `DELETE` del pedido de ejemplo dejó **3 líneas y 1 pago huérfanos
sin cascada y sin error**. Encendido en la misma conexión: `Error near line 3: FOREIGN KEY
constraint failed`. El `CHECK`, en cambio, se aplica siempre, y esa aplicación selectiva es lo que
hace que la trampa pase desapercibida: algunas restricciones sí fallan, así que parece que todas
funcionan.

---

**07 → S18.** **¿Qué diferencia hay entre `NO ACTION` y `RESTRICT`? 🟠**

⏱️ **30 segundos** — `RESTRICT` comprueba de inmediato; `NO ACTION` puede aplazar la comprobación al
final de la sentencia o de la transacción, si la restricción es aplazable.

🗣️ **2 minutos** — En el uso corriente se comportan igual y por eso se confunden. La diferencia
aparece cuando dentro de una misma sentencia borras el hijo y el padre: con `NO ACTION` la
comprobación ocurre al final y la operación pasa, porque para entonces ya no hay huérfanos; con
`RESTRICT` falla en cuanto lo intenta. `NO ACTION` es además el valor por defecto del estándar
cuando no declaras nada.

🔬 **El detalle** — Medido: `WITH b AS (DELETE FROM pagos WHERE pedido_id=42 RETURNING id) DELETE
FROM pedidos WHERE id=42;` devuelve `DELETE 1` sin error con `NO ACTION`. Es **estándar** la
distinción y **motor** hasta dónde llega el aplazamiento: PostgreSQL permite declarar la restricción
`DEFERRABLE INITIALLY DEFERRED` y llevarla al `COMMIT`, que es la palanca de las cargas masivas.

---

**07 → S19.** **Escribe el DDL de una relación N:M con atributos propios, y di por qué
`pedido_lineas` no lleva `UNIQUE (pedido_id, producto_id)`. 🔴**

⏱️ **30 segundos** — Tabla puente con las dos foráneas más sus propios atributos. Y no lleva ese
`UNIQUE` porque un pedido sí puede repetir producto en dos líneas.

🗣️ **2 minutos** — El DDL es el de `pedido_lineas`: las dos foráneas a `pedidos` y `productos`, más
`cantidad` y `precio_unit`, que son atributos de la relación y no de ninguna de las dos entidades.
Eso es lo que distingue una N:M de verdad de una tabla puente tonta: si la relación tiene datos
propios, es una entidad. Y la clave primaria `(pedido_id, linea)` en vez de `(pedido_id,
producto_id)` es lo que deja la puerta abierta a repetir producto.

🔬 **El detalle** — Y es una decisión, no un descuido: hay **6 855 pedidos que ya repiten producto**
en este conjunto de datos. Los casos reales son legítimos —dos líneas del mismo artículo con
distinto precio por una promoción parcial, o una línea añadida después—. Si el negocio decidiera lo
contrario, la restricción se añade y esas 6 855 filas hay que consolidarlas primero. La respuesta
completa dice las dos cosas: cuál es el diseño actual y qué costaría cambiarlo.

---

**07 → S20.** **Traduce a SQL el anti-join del álgebra relacional, y di qué nodo esperas ver en el
plan. 🟡**

⏱️ **30 segundos** — `NOT EXISTS` con una subconsulta correlacionada. En PostgreSQL espero un `Hash
Anti Join`.

🗣️ **2 minutos** — El anti-join devuelve las filas de la izquierda que no tienen pareja a la
derecha: los pedidos sin pago, los clientes sin pedidos. La forma canónica es `SELECT … FROM pedidos
p WHERE NOT EXISTS (SELECT 1 FROM pagos g WHERE g.pedido_id = p.id)`. El `LEFT JOIN … WHERE
derecha.id IS NULL` es equivalente y el planificador suele reconocerlo, pero se lee peor y es más
fácil de romper añadiendo una condición en el sitio equivocado.

🔬 **El detalle** — Medido: el plan da `Hash Anti Join` con `rows=180000` en 513 ms, que coincide con
los 180 000 pedidos PENDIENTE y ANULADO del conjunto de datos. Que el motor tenga un nodo con ese
nombre confirma que reconoce el patrón como operación de primera clase, no como un join filtrado. En
MySQL 9.7.2 el mismo plan se llama `Nested loop antijoin`, comprobado con `EXPLAIN FORMAT=TREE`: es
**motor**, y los nombres no se trasladan.

---

**07 → S21.** **¿Por qué `NATURAL JOIN clientes, pedidos` devuelve cero filas en este esquema? 🟠**

⏱️ **30 segundos** — Porque une por *todas* las columnas con el mismo nombre, y las dos tablas
comparten `id`, `codigo` y `creado_en`. Ninguna fila cumple las tres igualdades.

🗣️ **2 minutos** — El `NATURAL JOIN` no adivina la relación: toma la intersección de nombres de
columna y exige igualdad en todas. Aquí eso significa que el cliente y el pedido tendrían que
compartir identificador, código y fecha de creación a la vez. Da cero filas sin error, que es el
peor resultado posible: parece una respuesta. Por eso es un operador que conviene no usar nunca en
código que vaya a vivir: basta que alguien añada una columna con un nombre común para que la
consulta cambie de significado en silencio.

🔬 **El detalle** — Comprobado: devuelve **0 filas**, y el `Join Filter` del plan muestra las tres
igualdades —por `id`, por `codigo` y por `creado_en`—, que es la evidencia de qué hizo el motor. La
forma correcta es `JOIN … ON c.id = p.cliente_id`, explícita. `USING (columna)` es un punto medio
razonable: nombra las columnas y no depende de lo que alguien añada mañana.

---

**07 → S22.** **¿Qué significa que SQL sea declarativo, y cuál es el modo de fallo típico de esa
propiedad? 🟡**

⏱️ **30 segundos** — Que describes el resultado, no el algoritmo. El modo de fallo típico es que la
consulta se degrada sola, sin que nadie cambie el código.

🗣️ **2 minutos** — Tú escribes qué quieres y el planificador decide cómo: si barre la tabla, si baja
por un índice, si construye una tabla hash. La misma consulta con los mismos datos puede elegir un
plan distinto mañana porque las estadísticas cambiaron, porque la tabla creció o porque alguien creó
un índice. Eso es una ventaja enorme el 95 % del tiempo y un problema serio el 5 % restante, porque
el síntoma es que algo se rompió sin que nadie tocara nada.

🔬 **El detalle** — Un ejemplo del corpus: la misma pregunta —contar pedidos— produce `Seq Scan`
descartando 999 975 filas en un caso, y `Hash Join` alimentado por `Index Scan` en otro, según cómo
se filtre. Ninguna de las dos estrategias está en el SQL. Es **estándar** el lenguaje y **motor**
todo lo demás: los nodos, sus nombres y los criterios no son comparables entre PostgreSQL y MySQL.

---

**07 → S23.** ***"Si uso transacciones, no puedo perder una actualización."* Rebate con un caso
concreto en el que todo funciona correctamente y el dato acaba mal. 🟠**

⏱️ **30 segundos** — Dos cajeros leen el mismo total, cada uno suma su importe sobre lo que leyó, y
el segundo en escribir pisa al primero. Las dos transacciones confirman sin error.

🗣️ **2 minutos** — La secuencia es: A lee 3 186,23, B lee 3 186,23, A escribe 3 196,23 y confirma, B
escribe 3 206,23 y confirma. B incluso esperó bloqueada a que A terminara —el motor hizo de árbitro—
pero cuando la desbloqueó, B ya tenía su resultado calculado con el valor viejo. Se aplicaron pagos
por 30 y el total subió 20. Ninguna transacción falló, nada se corrompió, y el dato está mal.

🔬 **El detalle** — Es la actualización perdida, y el estándar la reconoce como fenómeno. Lo que la
permite no es un fallo del motor sino el patrón **leer, calcular fuera, escribir**. Ni el `READ
COMMITTED` por defecto de PostgreSQL ni el `REPEATABLE READ` de InnoDB lo evitan. Hay tres
correcciones con precios distintos: hacer la aritmética dentro del `UPDATE` —la más barata—,
bloquear con `SELECT … FOR UPDATE` —mantiene el bloqueo más tiempo—, o subir a `SERIALIZABLE` —el
motor aborta a una y hay que reintentar en el código—.

---

**07 → S24.** **El `COMMIT` te respondió `ROLLBACK`. ¿Qué pasó, y en qué motor estás? 🟠**

⏱️ **30 segundos** — Una sentencia anterior falló dentro de la transacción y la dejó abortada. Estás
en PostgreSQL.

🗣️ **2 minutos** — PostgreSQL, ante un error de sentencia, marca la transacción entera como abortada
y rechaza todo lo que venga después con `current transaction is aborted, commands ignored until end
of transaction block`. Cuando pides `COMMIT`, no tiene nada que confirmar y te responde con lo que
realmente hizo. Es una decisión de diseño deliberada: te impide confirmar a medias sin darte cuenta.

🔬 **El detalle** — Es **motor**, y es de las diferencias que más sorprenden al portar: MySQL y
SQLite dejan la transacción usable tras un error de sentencia, así que la sentencia falla y las
demás siguen su curso. La consecuencia práctica es que el mismo código de aplicación que traga una
excepción y continúa produce datos a medias en MySQL y nada en PostgreSQL. Los puntos de guardado
—`SAVEPOINT`— son la forma de tener el comportamiento intermedio en PostgreSQL cuando de verdad lo
quieres.

---

**07 → S25.** **¿Por qué el planificador prefiere leer un millón de filas antes que bajar por un
índice para devolver sesenta mil? Explícalo sin usar la palabra "optimización". 🟠**

⏱️ **30 segundos** — Porque leer páginas seguidas es mucho más barato que saltar a sesenta mil
sitios distintos. A partir de cierta proporción, la tabla entera sale más a cuenta.

🗣️ **2 minutos** — Un índice no te da la fila: te da su dirección. Por cada entrada que encuentra
tiene que ir a buscarla a la tabla, y esas visitas caen en páginas dispersas. Sesenta mil visitas
dispersas contra 10 770 páginas leídas en orden: el barrido gana. El umbral no es un porcentaje
fijo, depende de cuánto cuesta un salto frente a una lectura secuencial en tu disco, de cuánta tabla
quepa en memoria, y de si las filas que buscas están agrupadas físicamente o repartidas.

🔬 **El detalle** — En este entorno `random_page_cost` está en 1,1, que asume SSD y por tanto hace
los saltos casi tan baratos como las lecturas seguidas; con el valor clásico de 4, pensado para
disco giratorio, el planificador se inclinaría antes por el barrido. Es **motor** completo: el
parámetro, su nombre y el modelo de coste son de PostgreSQL. Y el corolario para entrevista: **el
índice que no se usa muchas veces no es un error del motor, es el motor teniendo razón**.

---

**07 → S26.** **Insertaste una fila, falló por una restricción, y el siguiente identificador
generado da un salto. ¿Es un fallo? ¿Qué implica para un número de factura? 🟡**

⏱️ **30 segundos** — No es un fallo: las secuencias no devuelven valores. Implica que un
autoincremental no sirve como número de factura.

🗣️ **2 minutos** — El valor se pide a la secuencia antes de intentar escribir, y no se devuelve si
la escritura falla ni si la transacción hace `ROLLBACK`. Y tiene que ser así: si se devolvieran, dos
transacciones concurrentes tendrían que coordinarse para repartirse los huecos, y la secuencia
dejaría de ser la operación barata y sin bloqueo que es. El hueco es el precio de la concurrencia.

🔬 **El detalle** — Se ve literalmente en el mensaje de error del corpus: el `DETAIL` de una
restricción violada muestra la fila rechazada con el identificador **1000002** ya asignado. Para un
número de factura, que un auditor puede exigir que sea consecutivo y sin saltos, hace falta otro
mecanismo: una tabla de contadores con bloqueo explícito, asumiendo la serialización que eso impone.
Es **motor** el nombre —`IDENTITY` y secuencias, `AUTO_INCREMENT`, `rowid`— pero el comportamiento
de no devolver es común a los tres.

---

**07 → S27.** ***"Probamos contra SQLite porque es más rápido y el SQL es el mismo."* Da tres
diferencias que harían pasar en verde una prueba que en producción falla. 🔴**

⏱️ **30 segundos** — Las claves foráneas apagadas por defecto, el tipado por afinidad que acepta
casi cualquier cosa, y que solo admite un escritor, así que ninguna prueba de concurrencia significa
nada.

🗣️ **2 minutos** — La primera es la más silenciosa: `PRAGMA foreign_keys` devuelve 0, así que una
prueba que verifica que no se puede crear un pedido huérfano pasa en verde comprobando lo contrario
de lo que cree. La segunda es el tipado: SQLite no tiene tipo fecha, ni booleano, ni `DECIMAL`, y
una columna declarada `TEXT` acepta un entero y lo guarda como entero, así que un dato mal formado
pasa la prueba y revienta en PostgreSQL. La tercera es que con un solo escritor no hay bloqueos, ni
interbloqueos, ni niveles de aislamiento que probar.

🔬 **El detalle** — Y hay una cuarta que muerde distinto: el dinero. Sin `DECIMAL`, la aritmética
sobre importes pasa por coma flotante, así que una prueba de totales puede dar un resultado
ligeramente distinto al de producción y el equipo aprende a ignorar ese decimal. Lo que hace la
trampa difícil de ver es que es **selectiva**: el `CHECK` sí se aplica siempre en SQLite, así que
parece que las restricciones funcionan. La respuesta profesional cabe en una frase: **probar contra
un motor distinto del de producción es probar otra cosa**, y la herramienta para no hacerlo son los
contenedores.

---

**07 → S28.** **Te dicen que el estándar SQL obliga a que `REPEATABLE READ` evite las lecturas
fantasma. Responde. 🔴**

⏱️ **30 segundos** — Es falso, y además es falso de tres maneras distintas según hables del
estándar, de PostgreSQL o de MySQL.

🗣️ **2 minutos** — El estándar **permite** fantasmas en `REPEATABLE READ`: es justo el fenómeno que
distingue ese nivel de `SERIALIZABLE`. PostgreSQL sí las evita, pero no por cumplir el estándar: su
`REPEATABLE READ` es *snapshot isolation*, que da una foto consistente de toda la base y por tanto
tampoco deja aparecer filas nuevas —aunque no evita el *write skew*, que es el fenómeno que snapshot
isolation sí permite—. MySQL con InnoDB también las evita, pero por un mecanismo tercero: los *gap
locks*, que bloquean el hueco entre índices y que no están en el estándar.

🔬 **El detalle** — Es el caso canónico de este corpus, y lo que se evalúa no es saber la respuesta
sino **distinguir las tres categorías al responder**. La frase que lo cierra: *"depende de si
hablamos del estándar, de tu motor, o de lo que se repite en las entrevistas; y los tres dan una
respuesta distinta"*. **No he verificado la cláusula concreta de ISO/IEC 9075** que define los
fenómenos por nivel: el estándar es de pago, y decirlo forma parte de responder bien.

---

**07 → E1.** **Escenario 1 — Las devoluciones**

⏱️ **30 segundos** — Una tabla `devoluciones` por cabecera y una `devolucion_lineas` que referencia
la línea original, nunca la reescribe, y lleva un `CHECK` de cantidad más una restricción agregada
que impide devolver más de lo comprado.

🗣️ **2 minutos** — La clave del diseño es que el histórico es inmutable: `pedido_lineas` no se toca
nunca. `devolucion_lineas` apunta a `(pedido_id, linea)` con una foránea compuesta, guarda la
cantidad devuelta y **su propio importe**, congelado igual que `precio_unit`. Sobre `pedidos.total`
la respuesta es que **no** debe reflejar la devolución: `total` significa "lo que se pidió", y
mezclarle el signo contrario lo convierte en un número que ya no se puede recalcular ni auditar. Lo
devuelto es una columna aparte, o un agregado sobre las devoluciones.

🔬 **El detalle** — La parte difícil es la tercera pregunta, porque **el motor no puede expresar "la
suma de las devoluciones de esta línea no supera su cantidad" con un `CHECK`**: un `CHECK` solo ve
la fila que se escribe. Las tres salidas, con su precio: un disparador `AFTER` que consulta el
agregado —funciona, y serializa las devoluciones de la misma línea—; una columna `cantidad_devuelta`
en `pedido_lineas` mantenida por la aplicación dentro de la transacción con `SELECT … FOR UPDATE`
—más rápido, y ahí sí desnormalizas—; o aceptar la comprobación en la aplicación y añadir la
consulta de conciliación nocturna. Reconocer que el `CHECK` no alcanza es lo que se está evaluando.

---

**07 → E2.** **Escenario 2 — El informe que devuelve cero**

⏱️ **30 segundos** — Casi seguro es un `NOT IN` con nulos en la subconsulta. La corrección es `NOT
EXISTS`.

🗣️ **2 minutos** — Las tres hipótesis en orden: **primera**, `NOT IN` sobre una columna que ahora
tiene nulos —encaja con "llevaba meses funcionando" y "nadie tocó el código", porque lo que cambió
fueron los datos—; **segunda**, un `JOIN` que se volvió vacío por un cambio de tipo o de formato en
la referencia del proveedor; **tercera**, un filtro de fechas relativo que se salió de rango. La
primera se confirma en una consulta: `SELECT count(*) FROM pagos WHERE referencia IS NULL`. Si da un
número distinto de cero, ya está.

🔬 **El detalle** — Da 273 126, y son los pagos en efectivo. La corrección es reescribir con `NOT
EXISTS`: 173 619 filas en 170 ms frente a 0 filas en 208 ms. La regla general que cierra el
escenario, que es lo que de verdad se pregunta: **`NOT IN` solo sobre una lista literal o una
columna declarada `NOT NULL`; en cualquier otro caso, `NOT EXISTS`**. Y la lección de fondo: el
fallo no fue una excepción sino un resultado plausible, así que la defensa no es mejor código sino
una prueba que afirme el número esperado, no solo que la consulta no reviente.

---

**07 → E3.** **Escenario 3 — El revisor y la columna redundante**

⏱️ **30 segundos** — Le concedo que se desincroniza y que rompe 3FN, y le enseño el número:
recalcular cuesta nueve veces más. La defensa no es negar el problema, es demostrar que está
controlado.

🗣️ **2 minutos** — Empiezo dándole la razón en lo técnico, porque la tiene: `total` es derivable y
por tanto redundante, y la redundancia se desincroniza. Después traigo el dato: el agregado sobre
300 000 pedidos lee **10 770 páginas** con `total` y **39 937** recalculando por `JOIN`, con tiempos
de 69 ms contra 606 ms. Y termino en el sitio correcto: esto no es un esquema mal normalizado, es
una desnormalización deliberada, y la diferencia entre las dos cosas es lo que hay alrededor.

🔬 **El detalle** — Los tres compromisos que hacen defendible la concesión, y que son la respuesta
que se busca: **uno**, un comentario en el DDL que diga que la columna es derivada y cuál es su
expresión de origen, porque dentro de un año nadie recordará esta conversación; **dos**, la consulta
de conciliación corriendo a diario con alerta —1 819,711 ms sobre el millón, perfectamente asumible—
y el compromiso de que su resultado sea cero; **tres**, un único camino de escritura que actualice
las dos cosas en la misma transacción, porque la desincronización no viene del diseño sino del
segundo servicio que escribe líneas sin tocar el total. Lo que no es defendible es la
desnormalización sin ninguna de las tres.

---

**07 → E4.** **Escenario 4 — El botón pulsado dos veces**

⏱️ **30 segundos** — Esto no lo resuelve la base de datos. El cobro duplicado nace de dos peticiones
HTTP legítimas e indistinguibles, y eso se ataja con una clave de idempotencia en la API, no con una
restricción.

🗣️ **2 minutos** — El problema es que las dos peticiones son válidas por separado: mismo cliente,
mismo pedido, mismo importe. Un cliente puede pagar dos veces el mismo pedido de forma legítima —un
pago parcial y luego otro—, así que la base de datos no tiene forma de distinguir el duplicado
accidental del intencionado. Lo que falta es información que solo existe aguas arriba: **que las dos
peticiones son el mismo intento**. Eso se transporta con una clave de idempotencia que el cliente
genera antes de enviar y repite en el reintento.

🔬 **El detalle** — Y ahora la parte que hay que decir para no quedarse en la crítica: **el `UNIQUE`
sí vale la pena, como última red**. Un `UNIQUE (pedido_id, clave_idempotencia)` en `pagos` convierte
el fallo silencioso en un error ruidoso, y lo convierte en el punto donde la carrera se resuelve de
verdad —dos peticiones concurrentes que pasaron las dos la comprobación de la aplicación chocan
aquí, y una pierde—. Sin restricción, la comprobación previa en el código es una condición de
carrera con ventana de milisegundos. La estructura de la respuesta es lo que se evalúa: **primero se
discute el encuadre de la pregunta, después se aporta lo que la capa de datos sí puede dar**.
Aceptar el marco y contestar "le pongo un `UNIQUE` y listo" es el fallo caro.

---

**Volver:** [README del bloque](README.md) · **Primer capítulo:** [`01`](01-que-resuelve-un-dbms.md)
— qué te da un DBMS que un fichero no te da.
