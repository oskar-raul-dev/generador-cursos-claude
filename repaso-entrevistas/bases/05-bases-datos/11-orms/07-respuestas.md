# 07 — Respuestas

> Solucionario del bloque: el enunciado copiado literalmente de su capítulo y la respuesta en tres
> capas.
>
> **Cómo se usa.** Responde primero en voz alta, con el cronómetro. La capa ⏱️ es lo que dices en
> los primeros treinta segundos; la 🗣️ es lo que añades cuando te dicen "cuéntame más"; la 🔬 es el
> matiz que casi nadie trae, y es donde vive la distinción entre **lo que manda el estándar, lo que
> manda la especificación, lo que hace la biblioteca y lo que es pura convención**.
>
> **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [Capítulo 01 — El desajuste y los dos patrones](#capítulo-01--el-desajuste-y-los-dos-patrones)
- [Capítulo 02 — El problema N+1](#capítulo-02--el-problema-n1)
- [Capítulo 03 — Carga, cachés y la sesión](#capítulo-03--carga-cachés-y-la-sesión)
- [Capítulo 04 — Constructores, y cuándo no usar
  ORM](#capítulo-04--constructores-y-cuándo-no-usar-orm)
- [Capítulo 05 — Probar contra una base de datos
  real](#capítulo-05--probar-contra-una-base-de-datos-real)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — El desajuste y los dos patrones

Las 16 preguntas de [`01`](01-el-desajuste-y-los-dos-patrones.md).

**01 → 1.** ¿Qué es el desajuste objeto-relacional, en una frase? 🟢

⏱️ **30 segundos** — Que objetos y tablas modelan lo mismo con reglas distintas: identidad,
asociaciones, navegación, granularidad y herencia no significan lo mismo en los dos lados.

🗣️ **2 minutos** — En la tabla, la identidad es la clave primaria; en el objeto, la dirección en
memoria. Una colección `pedido.lineas` no existe en `pedidos`: existe como clave foránea en
`pedido_lineas`. Y navegar de un objeto a otro es gratis en memoria y una consulta por salto en la
base.

🔬 **El detalle** — Es una diferencia de modelos, no un fallo de nadie; el estándar SQL no habla de
objetos. Cada ORM decide qué hace con cada diferencia, y eso es lo que se elige al elegir ORM.

---

**01 → 2.** ¿Qué hace un mapa de identidad? 🟢

⏱️ **30 segundos** — Guarda, dentro de una sesión, un objeto por clave primaria: pedir dos veces la
misma fila devuelve el mismo objeto, y la segunda vez no va a la base.

🗣️ **2 minutos** — Corrido: Hibernate hizo una consulta para dos `find` del pedido 42 y devolvió
`mismo objeto: true`; SQLAlchemy, igual. Garantiza que dos partes del código no trabajen con dos
versiones de la misma fila.

🔬 **El detalle** — **Biblioteca**, y en JPA es el contexto de persistencia. Su precio es el dato
viejo de `03` §6: lo que la sesión cargó, lo recuerda como lo cargó.

---

**01 → 3.** ¿Qué es el *flush* de una sesión? 🟢

⏱️ **30 segundos** — El momento en que la sesión escribe en la base los cambios que ha ido anotando
en los objetos cargados.

🗣️ **2 minutos** — Ocurre antes de una consulta que podría verse afectada, al confirmar, o cuando se
pide. Corrido: cambiar `estado` no escribió nada; el `flush` generó el `UPDATE`.

🔬 **El detalle** — **Biblioteca**. El *flush* no confirma: escribe dentro de la transacción, que
todavía puede deshacerse, como se hizo en la prueba.

---

**01 → 4.** Nombra dos ORM que sigan *Active Record* y dos que sigan *Data Mapper*. 🟢

⏱️ **30 segundos** — *Active Record*: el de Rails y el de Django. *Data Mapper*: Hibernate con JPA y
el ORM de SQLAlchemy.

🗣️ **2 minutos** — Eloquent de Laravel es *Active Record*; Doctrine, *Data Mapper*. GORM y Drizzle
no encajan del todo en ninguno: guardan desde fuera del objeto pero sin sesión que recuerde nada.

🔬 **El detalle** — Los nombres vienen del catálogo de Martin Fowler, *Patterns of Enterprise
Application Architecture*, de 2002.

---

**01 → 5.** Distingue *Active Record* de *Data Mapper*: quién sabe guardar en cada uno. ¿Qué parte
es del motor y qué parte es convención? 🟡

⏱️ **30 segundos** — En *Active Record*, el propio objeto: `pedido.save()`. En *Data Mapper*, un
objeto aparte, la sesión, que mapea clases normales desde fuera.

🗣️ **2 minutos** — *Active Record* encaja cuando tabla y objeto son casi lo mismo, y ata el objeto a
la base. *Data Mapper* separa el dominio de la persistencia, a cambio de una sesión con estado que
decide cuándo va el SQL.

🔬 **El detalle** — **Convención** de nombres; la diferencia práctica es probar la lógica sin base,
que en *Active Record* cuesta más.

---

**01 → 6.** ¿Por qué Hibernate hizo una sola consulta al pedir dos veces el mismo pedido, y GORM
dos? 🟡

⏱️ **30 segundos** — Porque Hibernate tiene mapa de identidad: la segunda petición la sirve la
sesión. GORM no tiene sesión: cada `First` es una consulta.

🗣️ **2 minutos** — Corrido: una línea `Hibernate: select …` para dos `find`, y dos `SELECT * FROM
"pedidos" … LIMIT 1` en GORM. En GORM cada resultado es un valor nuevo, y dos funciones que leen el
mismo pedido tienen dos copias independientes.

🔬 **El detalle** — **Biblioteca.** Drizzle, igual que GORM: dos `select` iguales, dos consultas.

---

**01 → 7.** Diferencia el `UPDATE` que genera Hibernate del que genera SQLAlchemy al cambiar una
columna. 🟡

⏱️ **30 segundos** — Hibernate escribe todas las columnas: `update pedidos set codigo=?,estado=?,
total=? where id=?`. SQLAlchemy, solo la que cambió: `UPDATE pedidos SET estado=… WHERE …`.

🗣️ **2 minutos** — Hibernate prepara una sentencia fija por entidad para reutilizarla; SQLAlchemy la
construye con lo que cambió. `@DynamicUpdate` pone a Hibernate a hacer lo segundo.

🔬 **El detalle** — **Biblioteca.** Escribir todas las columnas genera más WAL por fila y puede pisar
una columna que otra transacción cambió; el `Save` de GORM hace lo mismo que Hibernate.

---

**01 → 8.** ¿Están el mapa de identidad o la unidad de trabajo en el estándar SQL, en JPA o en las
bibliotecas? Responde por separado. 🟡

⏱️ **30 segundos** — En el estándar SQL, no. En JPA, sí: el contexto de persistencia y el *flush*.
En las bibliotecas: Hibernate y SQLAlchemy los tienen; GORM y Drizzle, no.

🗣️ **2 minutos** — JPA los exige a quien la implementa, y Hibernate lo hace. SQLAlchemy los tiene
sin especificación. GORM y Drizzle dejan la identidad y la escritura en manos del código.

🔬 **El detalle** — ISO/IEC 9075 no habla de objetos. Los nombres de los patrones son del catálogo de
Fowler.

---

**01 → 9.** ¿Por qué la navegación de objetos es la diferencia del desajuste que más cuesta en
producción? 🟡

⏱️ **30 segundos** — Porque en memoria seguir una referencia es gratis y en la base es una consulta
por salto: recorrer una lista y navegar desde cada elemento es el N+1.

🗣️ **2 minutos** — Medido en `02`: 53 consultas para los 52 pedidos de un cliente con sus líneas, en
los cuatro lenguajes. El código que lo produce parece leer un atributo.

🔬 **El detalle** — Las otras diferencias cuestan en diseño; esta cuesta en cada petición, y crece
con los datos.

---

**01 → 10.** Un objeto cargado por Hibernate se modifica sin querer en una función de formato. ¿Qué
pasa al confirmar la transacción, y cómo lo evitarías? 🟠

⏱️ **30 segundos** — Que el cambio se escribe: el *dirty checking* ve el objeto distinto de como se
cargó y genera un `UPDATE`, aunque nadie llamó a guardar.

🗣️ **2 minutos** — Para evitarlo: formatear sobre una copia o una proyección, no sobre la entidad;
leer con consultas de solo lectura —Hibernate las tiene—; o separar el objeto de la sesión antes de
tocarlo.

🔬 **El detalle** — **Biblioteca.** Se detecta en el log de SQL: un `UPDATE` que nadie escribió en
una operación que solo leía.

---

**01 → 11.** ¿Qué cuesta que Hibernate escriba todas las columnas en cada `UPDATE`, y cuándo usarías
`@DynamicUpdate`? 🟠

⏱️ **30 segundos** — Más bytes en cada fila del WAL y el riesgo de pisar columnas que otra
transacción cambió. `@DynamicUpdate` en entidades anchas o con columnas que cambian procesos
distintos.

🗣️ **2 minutos** — A cambio, Hibernate reutiliza una sentencia preparada por entidad. En una tabla
de pocas columnas, la diferencia es pequeña; en una de cincuenta, grande.

🔬 **El detalle** — **Biblioteca.** Contra pisar columnas, la defensa de fondo no es `@DynamicUpdate`
sino una columna de versión, de `04/05` §3.

---

**01 → 12.** Dos funciones de un servicio en Go leen el mismo pedido con GORM, lo modifican y lo
guardan con `Save`. ¿Qué queda en la base, y cómo lo corriges? 🟠

⏱️ **30 segundos** — Queda la segunda escritura entera: `Save` escribe todas las columnas con lo que
hay en el objeto, y el cambio de la primera se pierde.

🗣️ **2 minutos** — Es la actualización perdida de `04/02` §6, hecha por el código. Corrección: un
`Update` de la columna que cambia, con la condición del estado leído en el `WHERE`, y mirar las
filas afectadas; o una columna de versión.

🔬 **El detalle** — **Biblioteca.** En Hibernate, con una sola sesión, las dos funciones trabajarían
sobre el mismo objeto; con dos sesiones, el problema es el mismo.

---

**01 → 13.** ¿Qué cuesta una sesión que vive mucho tiempo con mapa de identidad? 🟠

⏱️ **30 segundos** — Memoria, porque guarda todo lo que carga, y datos viejos, porque no refresca lo
que ya tiene.

🗣️ **2 minutos** — Un proceso por lotes que carga miles de entidades en una sesión acaba con miles
de objetos en memoria y un *dirty checking* que los compara todos en cada *flush*.

🔬 **El detalle** — **Biblioteca.** Por eso las sesiones son de una petición, y los lotes se vacían y
limpian cada pocos cientos de entidades.

---

**01 → 14.** Elige entre *Active Record* y *Data Mapper* para un servicio de pagos con reglas de
negocio propias, y justifica la elección. 🟠

⏱️ **30 segundos** — *Data Mapper*: las reglas de pagos tienen que poder probarse sin base, y el
dominio no debería depender de cómo se guarda.

🗣️ **2 minutos** — Con *Active Record*, cada objeto de pago hereda la persistencia, y la lógica y el
acceso a datos se mezclan. Con *Data Mapper*, la sesión y la transacción quedan en el borde del
servicio.

🔬 **El detalle** — El precio es entender la sesión: *flush*, identidad y carga. Para un servicio de
pagos, es un precio razonable.

---

**01 → 15.** Diseña cómo detectarías, en un servicio con Hibernate, escrituras que nadie pidió. Di
qué mirarías y dónde. 🔴

⏱️ **30 segundos** — El log de SQL de Hibernate en las pruebas, buscando `UPDATE` en operaciones de
lectura, y el log del servidor con `log_statement` para el rol, que da la verdad.

🗣️ **2 minutos** — En las pruebas de integración, contar sentencias por operación y fallar si una de
lectura escribe. En Hibernate, marcar las transacciones de solo lectura, que evita el *dirty
checking*. En producción, `pg_stat_statements` para ver `UPDATE` sobre tablas que una ruta no
debería tocar.

🔬 **El detalle** — **Biblioteca y motor.** La causa suele ser una entidad modificada en una capa que
no debía, como un formateo o un mapeo a JSON.

---

**01 → 16.** Escribe, en el lenguaje que prefieras, una operación que cambie el estado de un pedido
de forma que dos llamadas simultáneas no se pisen, con GORM o Drizzle. 🔴

⏱️ **30 segundos** — Un `UPDATE` que exige en el `WHERE` el estado leído, y mirar las filas
afectadas: si es 0, otro se adelantó.

🗣️ **2 minutos** — Corrido en GORM, dentro de una transacción deshecha al final:

```go
r := tx.Model(&Pedido{}).Where("id = ? AND estado = ?", 42, "PAGADO").Update("estado", "ENVIADO")
fmt.Printf("%s llamada: filas afectadas = %d\n", quien, r.RowsAffected)
```

```text
primera llamada: filas afectadas = 1
segunda llamada: filas afectadas = 0
```

🔬 **El detalle** — Es el control optimista de `04/05` §3, usando el estado como versión. Con una
columna de versión es más general; y la segunda escritura, en paralelo de verdad, espera al bloqueo
de fila y reevalúa el `WHERE`, como se corrió allí.

---

## Capítulo 02 — El problema N+1

Las 17 preguntas de [`02`](02-el-problema-n-mas-1.md).

**02 → 1.** ¿Qué es el problema N+1, en una frase? 🟢

⏱️ **30 segundos** — Una consulta trae una lista de N elementos y después se hace una consulta más
por cada uno para traer algo suyo.

🗣️ **2 minutos** — Medido: los 52 pedidos de `CLI-00311` con sus líneas fueron 53 consultas en los
cuatro lenguajes, con y sin carga perezosa.

🔬 **El detalle** — No es culpa del ORM: es de recorrer objetos sin decir qué se va a necesitar.

---

**02 → 2.** ¿Dónde se detecta un N+1 con certeza? 🟢

⏱️ **30 segundos** — En el log del servidor, contando sentencias: la misma consulta muchas veces
seguidas con un parámetro que cambia.

🗣️ **2 minutos** — Con `log_statement = 'all'` para el rol de la aplicación durante un rato, o con
`pg_stat_statements`, que cuenta cuántas veces se ejecutó cada sentencia.

🔬 **El detalle** — **Motor.** El tiempo de una prueba local no lo delata; el número de consultas sí.

---

**02 → 3.** Nombra las cuatro correcciones del N+1. 🟢

⏱️ **30 segundos** — Traerlo todo en un `JOIN`; una segunda consulta con `IN`; cargar por lotes; y
una proyección que no crea entidades.

🗣️ **2 minutos** — En Hibernate: `join fetch`, lotes con `default_batch_fetch_size` y consulta de
columnas. En SQLAlchemy: `joinedload`, `selectinload` y Core. En GORM: `Preload` y `Raw`. En
Drizzle: la consulta relacional y `innerJoin`.

🔬 **El detalle** — **Biblioteca.** La proyección es la que más se olvida y la mejor para listados.

---

**02 → 4.** ¿Qué parámetro de Hibernate activa la carga por lotes? 🟢

⏱️ **30 segundos** — `hibernate.default_batch_fetch_size`, o la anotación `@BatchSize` en la
asociación.

🗣️ **2 minutos** — Con 16, las 52 colecciones se cargaron en 4 consultas con `IN` de hasta 16
identificadores: 5 en total con la lista.

🔬 **El detalle** — **Biblioteca.** Es la corrección menos invasiva: no cambia ninguna consulta del
código.

---

**02 → 5.** Distingue `joinedload` de `selectinload` en SQLAlchemy: cuántas consultas hace cada una
y qué SQL. 🟡

⏱️ **30 segundos** — `joinedload` hace una: un `JOIN` de pedidos con líneas. `selectinload` hace
dos: los pedidos, y después todas las líneas con `IN`.

🗣️ **2 minutos** — Medido: 1 y 2 consultas, en 60 y 61 ms. El `JOIN` repite las columnas del pedido
en cada línea y obliga a `unique()`; el `IN` no repite nada.

🔬 **El detalle** — **Biblioteca.** Con varias colecciones, `selectinload` no multiplica filas y
`joinedload` sí.

---

**02 → 6.** ¿Por qué GORM y Drizzle también tienen N+1 si no tienen carga perezosa? 🟡

⏱️ **30 segundos** — Porque el N+1 lo escribe el código: un bucle con una consulta dentro. Corrido:
53 consultas en los dos.

🗣️ **2 minutos** — Sin carga perezosa es más visible, porque la consulta está escrita en el bucle,
pero no es menos frecuente.

🔬 **El detalle** — Es la prueba de que el N+1 no es un defecto de los ORM con sesión, sino de un
patrón de acceso.

---

**02 → 7.** ¿Qué hace la consulta relacional de Drizzle para traer todo en una sentencia? ¿Lo fija
el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — Un `LEFT JOIN LATERAL` con una subconsulta que agrega las líneas de cada pedido
en JSON con `json_agg`.

🗣️ **2 minutos** — Devuelve una fila por pedido, con las líneas dentro como JSON, sin repetir el
padre. Se vio en su log, y el servidor contó una sola sentencia.

🔬 **El detalle** — **Biblioteca** sobre dos piezas del **motor**: `LATERAL` y `json_agg`. Si las
líneas llevaran importes, pasarían por JSON, con la trampa de tipos de `10/03` §4.

---

**02 → 8.** ¿Está alguna de estas correcciones en el estándar SQL? Responde para la norma, para
PostgreSQL y para las bibliotecas. 🟡

⏱️ **30 segundos** — La norma tiene el `JOIN` y el `IN`, que son las piezas; las correcciones son de
cada biblioteca. PostgreSQL añade `LATERAL` y `json_agg`, que usa Drizzle.

🗣️ **2 minutos** — Ninguna biblioteca inventa SQL nuevo: eligen cuántas consultas hacer y con qué
forma. Lo que decide es la biblioteca, por consulta.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas; el ORM no aparece en
ella.

---

**02 → 9.** Con 52 pedidos y lotes de 16, ¿cuántas consultas hace Hibernate? Explica la cuenta. 🟡

⏱️ **30 segundos** — Cinco: una para la lista, y ⌈52 ÷ 16⌉ = 4 para las líneas, cada una con un
`IN`.

🗣️ **2 minutos** — Medido: 12 sentencias en el servidor, menos las 7 con que Hibernate inspecciona
la base al arrancar.

🔬 **El detalle** — **Biblioteca.** Con 500 pedidos serían 33 consultas; con `selectinload` o
`Preload`, siempre 2.

---

**02 → 10.** ¿Por qué el tiempo de una prueba local no delata un N+1, y qué número sí lo hace? 🟠

⏱️ **30 segundos** — Porque en local un viaje a la base cuesta décimas de milisegundo, y 52 viajes
de más casi no se notan. Lo delata el número de consultas, que crece con la lista.

🗣️ **2 minutos** — Aun así, la versión ingenua fue la más lenta en los cuatro lenguajes. Con la base
a 1 ms de red, 52 consultas de más son 52 ms por página; con 500 pedidos, medio segundo.

🔬 **El detalle** — Por eso la prueba útil cuenta sentencias y falla si crecen con los datos.

---

**02 → 11.** ¿Qué pasa si corriges con un `JOIN` una página que necesita dos colecciones de cada
pedido? 🟠

⏱️ **30 segundos** — Un producto cartesiano: cada línea se combina con cada elemento de la otra
colección, y las filas se multiplican.

🗣️ **2 minutos** — Con 3 líneas y 4 pagos por pedido son 12 filas por pedido en vez de 7. La
corrección es un `JOIN` para una colección y una segunda consulta con `IN` para la otra, o una
consulta con `IN` para cada una.

🔬 **El detalle** — **Motor**: un `JOIN` con dos relaciones uno a muchos multiplica por definición.

---

**02 → 12.** ¿Por qué poner la relación en ansiosa no es la corrección, y cuál es? 🟠

⏱️ **30 segundos** — Porque carga las líneas en cada lectura de un pedido, las necesite o no. La
corrección es decidir la carga **por consulta**.

🗣️ **2 minutos** — Con la asociación perezosa en el mapeo, cada consulta pide lo que va a usar:
`join fetch`, `selectinload`, `Preload` o una proyección.

🔬 **El detalle** — En JPA, además, lo ansioso en el mapeo se hereda por todas las consultas, y
Hibernate puede resolverlo con consultas extra en vez de un `JOIN`.

---

**02 → 13.** ¿Cuándo elegirías una proyección en vez de cargar entidades? 🟠

⏱️ **30 segundos** — Cuando solo se van a enseñar datos, no a modificarlos: listados, informes,
respuestas de API de solo lectura.

🗣️ **2 minutos** — La proyección es una consulta, trae solo las columnas necesarias y no llena la
sesión ni el mapa de identidad. Medido: una consulta en los cuatro lenguajes.

🔬 **El detalle** — No sirve para modificar: una proyección no es una entidad y la sesión no la
vigila.

---

**02 → 14.** ¿Qué cuesta dejar `log_statement = 'all'` activado en producción, y qué usarías en su
lugar? 🟠

⏱️ **30 segundos** — Disco y E/S: cada sentencia se escribe en el log. Usaría `pg_stat_statements`,
que agrega las sentencias iguales y cuenta ejecuciones.

🗣️ **2 minutos** — `log_statement` sirve un rato y para un rol, como en este bloque. Para vigilar de
forma permanente, `pg_stat_statements` o `log_min_duration_statement` con un umbral.

🔬 **El detalle** — **Motor.** `pg_stat_statements` necesita cargarse al arrancar el servidor, y es
del bloque 06.

---

**02 → 15.** Diagnostica: una ficha de cliente tarda 40 ms con clientes nuevos y 4 s con los
antiguos. Da la hipótesis, la prueba que la confirma y la corrección. 🔴

⏱️ **30 segundos** — Un N+1: el tiempo crece con el número de pedidos del cliente. Se confirma
contando consultas en el servidor para un cliente antiguo, y se corrige con una carga por consulta.

🗣️ **2 minutos** — Con `log_statement` para el rol durante una petición, las consultas contra
`pedido_lineas` serán tantas como pedidos. La corrección: `selectinload`, `Preload`, `join fetch` o
una proyección, según el lenguaje.

🔬 **El detalle** — Si con la corrección sigue creciendo, la siguiente hipótesis es la consulta de la
lista sin índice por `cliente_id`, que es del bloque 03.

---

**02 → 16.** Escribe, en el lenguaje que prefieras, la carga de los pedidos de un cliente con sus
líneas en dos consultas como mucho, y di qué SQL genera. 🔴

⏱️ **30 segundos** — En SQLAlchemy, `selectinload`: una consulta para los pedidos y otra con `IN`
para todas sus líneas.

🗣️ **2 minutos** — Corrido:

```python
select(Pedido).where(Pedido.cliente_id == 311).options(selectinload(Pedido.lineas))
```

Dos consultas en el servidor, descontadas las de arranque, y 175 líneas en 61 ms.

🔬 **El detalle** — En GORM, `Preload("Lineas")` hace lo mismo; en Hibernate, lotes o `join fetch`.

---

**02 → 17.** Diseña una regla de revisión de código que atrape el N+1 antes de producción en un
equipo que usa Hibernate. 🔴

⏱️ **30 segundos** — Todas las asociaciones `LAZY` en el mapeo, y una prueba de integración por
endpoint que cuente sentencias con datos de varios tamaños y falle si el número crece con ellos.

🗣️ **2 minutos** — En revisión: ningún recorrido de colección fuera de una consulta que la cargue.
En la prueba: las estadísticas de Hibernate dan el número de sentencias por sesión; se compara con 5
y con 50 elementos.

🔬 **El detalle** — `default_batch_fetch_size` como red de seguridad global limita el daño de lo que
se escape.

---

## Capítulo 03 — Carga, cachés y la sesión

Las 16 preguntas de [`03`](03-carga-caches-y-la-sesion.md).

**03 → 1.** ¿Qué diferencia hay entre carga perezosa y ansiosa? 🟢

⏱️ **30 segundos** — La perezosa carga una asociación la primera vez que se toca; la ansiosa, al
cargar la entidad que la contiene.

🗣️ **2 minutos** — La perezosa produce el N+1 si se recorre; la ansiosa trae datos que quizá no se
usen, en cada lectura.

🔬 **El detalle** — **Especificación y biblioteca**: en JPA depende del tipo de asociación.

---

**03 → 2.** ¿Cuál es el valor por defecto de `fetch` en `@ManyToOne` y en `@OneToMany`? 🟢

⏱️ **30 segundos** — `EAGER` en `@ManyToOne` y `LAZY` en `@OneToMany`.

🗣️ **2 minutos** — Corrido: cargar una línea trajo su pedido en un `JOIN` que nadie pidió. La
documentación de Jakarta Persistence lo dice: si no se especifica, `EAGER`.

🔬 **El detalle** — **Especificación**. SQLAlchemy es perezoso por defecto en las dos direcciones.

---

**03 → 3.** ¿Qué es *Open Session in View*, y es una regla de JPA o una convención de Spring Boot? 🟢

⏱️ **30 segundos** — Mantener la sesión abierta toda la petición HTTP, hasta que termina la vista o
el serializador, para que las colecciones perezosas se carguen en cualquier momento.

🗣️ **2 minutos** — Spring Boot lo trae encendido: `spring.jpa.open-in-view` vale `true`. Se
considera un antipatrón.

🔬 **El detalle** — **Spring Boot**, no JPA: la especificación no dice nada de cuánto vive la
sesión, y el valor `true` es una decisión del framework; dejarlo encendido es **convención**, y
mala. No se corrió en el entorno, que no tiene Spring Boot.

---

**03 → 4.** ¿Qué hace `refresh` en Hibernate? 🟢

⏱️ **30 segundos** — Vuelve a leer la fila de la base y sobrescribe el estado de la entidad ya
cargada.

🗣️ **2 minutos** — Corrido: tras un cambio desde otra conexión, la consulta devolvió `PAGADO`,
viejo; después de `refresh`, `ENVIADO`.

🔬 **El detalle** — **Biblioteca.** El equivalente en SQLAlchemy es `refresh` o `populate_existing`.

---

**03 → 5.** Distingue la caché de primer nivel de la de segundo nivel: qué es cada una, cuánto vive
y quién la ve. 🟡

⏱️ **30 segundos** — La de primer nivel es el mapa de identidad de la sesión: vive lo que la sesión
y solo la ve ella. La de segundo nivel se comparte entre sesiones, vive lo que se configure y viene
apagada.

🗣️ **2 minutos** — La primera no se puede apagar; la segunda en Hibernate necesita un proveedor y se
activa por entidad.

🔬 **El detalle** — **Biblioteca.** SQLAlchemy no trae segundo nivel: su documentación lo resuelve
con una receta aparte.

---

**03 → 6.** ¿Por qué aparece `LazyInitializationException`, y qué dice exactamente? 🟡

⏱️ **30 segundos** — Porque se toca una colección perezosa con la sesión cerrada. Dice que no puede
inicializar la colección porque no hay sesión: `(no session)`.

🗣️ **2 minutos** — Corrido: `Cannot lazily initialize collection of role 'Sesion$Pedido.lineas' with
key '42' (no session)`. En SQLAlchemy, `DetachedInstanceError`.

🔬 **El detalle** — **Biblioteca.** El error es honesto: se intentó una consulta fuera de la
transacción.

---

**03 → 7.** ¿Qué hace SQLAlchemy con los objetos de la sesión al hacer `commit`, y qué no hace
Hibernate? 🟡

⏱️ **30 segundos** — SQLAlchemy los expira —`expire_on_commit`, por defecto— y los recarga al volver
a tocarlos. Hibernate no los expira.

🗣️ **2 minutos** — Corrido: con un `commit` antes del cambio externo, SQLAlchemy dio `ENVIADO` a la
primera; sin él, dio `PAGADO`, como Hibernate.

🔬 **El detalle** — **Biblioteca.** El precio de expirar es recargar al tocar; y un objeto expirado y
separado de la sesión no se puede recargar.

---

**03 → 8.** ¿Está el defecto de carga en el estándar SQL, en JPA o en cada biblioteca? Responde por
separado. 🟡

⏱️ **30 segundos** — En el estándar SQL no. En JPA sí: `EAGER` para referencias y `LAZY` para
colecciones. En cada biblioteca, lo suyo: SQLAlchemy perezoso por defecto.

🗣️ **2 minutos** — Hibernate cumple JPA. GORM y Drizzle no tienen carga perezosa: cargan lo que se
pide.

🔬 **El detalle** — ISO/IEC 9075 no habla de objetos; el defecto de JPA está en la documentación de
`@ManyToOne`.

---

**03 → 9.** Una consulta JPQL vuelve a la base y devuelve un estado viejo. Explica por qué la base
no tiene la culpa. 🟠

⏱️ **30 segundos** — Porque la base devolvió el dato nuevo, pero la sesión ya tenía el objeto en su
mapa de identidad y no lo sobrescribe.

🗣️ **2 minutos** — Corrido: el log enseña la consulta, la base devolvió `ENVIADO`, y la entidad
siguió en `PAGADO`. Es la garantía de un objeto por fila, pagada en frescura.

🔬 **El detalle** — **Biblioteca.** Se ve el valor nuevo con `refresh`, `populate_existing` o una
sesión nueva.

---

**03 → 10.** ¿Por qué *Open Session in View* es un antipatrón, en dos consecuencias concretas? 🟠

⏱️ **30 segundos** — Esconde el N+1 en la serialización, fuera de cualquier sitio donde se piense en
SQL; y retiene la conexión toda la petición, también mientras se escribe la respuesta.

🗣️ **2 minutos** — Lo primero multiplica consultas; lo segundo aumenta el tiempo de retención y
agota el *pool* antes.

🔬 **El detalle** — **Spring Boot**, que lo trae por defecto. Se vería en el log de SQL: consultas
después de que el controlador devolvió su resultado.

---

**03 → 11.** ¿Qué pasa al apagar `spring.jpa.open-in-view` en un proyecto grande, y por qué es buena
noticia? 🟠

⏱️ **30 segundos** — Aparecen `LazyInitializationException` en todos los sitios que dependían de la
sesión abierta. Es buena noticia porque señala exactamente lo que hay que arreglar.

🗣️ **2 minutos** — Cada error es una carga perezosa que ocurría en la vista: se corrige cargando en
la consulta o devolviendo una proyección.

🔬 **El detalle** — Se apaga primero en pruebas, con cobertura de las respuestas, para que los
errores salgan antes que en producción.

---

**03 → 12.** ¿Para qué tablas de la tienda usarías una caché de segundo nivel, y para cuáles nunca?
🟠

⏱️ **30 segundos** — Para `productos`, un catálogo que se lee mucho y cambia poco. Nunca para
`pedidos` ni `pagos`, que cambian a cada rato.

🗣️ **2 minutos** — La condición es que solo la propia aplicación cambie la tabla: una actualización
por SQL directo o desde otro servicio no invalida la caché.

🔬 **El detalle** — **Biblioteca.** Una caché compartida con datos viejos es peor que el dato viejo
de una sesión: lo ven todas.

---

**03 → 13.** ¿Por qué declarar todas las asociaciones `LAZY` es la recomendación habitual en JPA? 🟠

⏱️ **30 segundos** — Porque lo ansioso en el mapeo se aplica a todas las consultas; lo perezoso deja
que cada consulta decida qué carga.

🗣️ **2 minutos** — Con `@ManyToOne` ansioso por defecto, una entidad con varias referencias arrastra
tablas en cada lectura. Con todo perezoso, la carga se pide con `join fetch` o lotes donde hace
falta.

🔬 **El detalle** — **Especificación**: lo perezoso es una pista para el proveedor, no una
obligación; Hibernate la respeta.

---

**03 → 14.** Diseña el acceso a datos de un endpoint que devuelve un pedido con sus líneas en JSON,
sin `LazyInitializationException` y sin *Open Session in View*. 🔴

⏱️ **30 segundos** — Una consulta que trae el pedido con sus líneas dentro de la transacción del
servicio, y una proyección o DTO que se devuelve a la capa web, sin entidades.

🗣️ **2 minutos** — En JPA: `join fetch` o una consulta de columnas a un *record*, dentro de un
método transaccional de servicio. El controlador recibe datos, no entidades, y el serializador no
puede disparar consultas.

🔬 **El detalle** — Con `open-in-view` apagado, cualquier carga perezosa olvidada falla en las
pruebas en vez de convertirse en una consulta oculta.

---

**03 → 15.** Diagnostica: un proceso por lotes con Hibernate que recorre pedidos durante una hora
toma decisiones con estados que ya cambiaron. Da el mecanismo y dos correcciones. 🔴

⏱️ **30 segundos** — Una sola sesión durante toda la hora: el mapa de identidad devuelve los pedidos
como los cargó, aunque otros procesos los cambien.

🗣️ **2 minutos** — Correcciones: sesiones cortas por tramo, que vacían el mapa; y comprobar el
estado en el propio `UPDATE`, con la condición en el `WHERE`, para que un estado viejo no se
convierta en una decisión.

🔬 **El detalle** — **Biblioteca.** Una transacción de una hora es además la transacción larga de
`04/05`, con sus facturas en el servidor.

---

**03 → 16.** Escribe la secuencia —sentencias y llamadas— que demuestra el dato viejo del mapa de
identidad en el ORM que prefieras, dejando la base como estaba. 🔴

⏱️ **30 segundos** — Cargar el pedido en una sesión; cambiarlo desde otra conexión y confirmar;
volver a consultarlo en la misma sesión; y compensar al final.

🗣️ **2 minutos** — Corrido en Hibernate:

```java
var p = s.find(Pedido.class, 42L);
otraConexion("UPDATE pedidos SET estado = 'ENVIADO' WHERE id = 42");
var otra = s.createQuery("from Pedido p where p.id = 42", Pedido.class).getSingleResult();
// tras la consulta: PAGADO (mismo objeto: true)
s.refresh(p);
// tras refresh: ENVIADO
otraConexion("UPDATE pedidos SET estado = 'PAGADO' WHERE id = 42");      // compensación, en un finally
```

🔬 **El detalle** — En SQLAlchemy hay que hacerlo **sin** `commit` entre la carga y el cambio, porque
`expire_on_commit` recargaría el objeto.

---

## Capítulo 04 — Constructores, y cuándo no usar ORM

Las 17 preguntas de [`04`](04-constructores-y-cuando-no-usar-orm.md).

**04 → 1.** ¿Qué es un constructor de consultas, y en qué se diferencia de un ORM? 🟢

⏱️ **30 segundos** — Una biblioteca en la que el SQL se escribe con la estructura del lenguaje
—`select`, `join`, `with`, `over`— y ella lo convierte en texto parametrizado. A diferencia de un
ORM, no hay sesión, mapa de identidad ni carga perezosa: lo que se escribe es lo que se ejecuta.

🗣️ **2 minutos** — El ORM parte de entidades y genera el SQL; el constructor parte del SQL y le da
forma de código. Con el constructor, el informe del capítulo salió igual en jOOQ, Core y Kysely:
`with recursive`, `union all`, `left join` y `over (order by …)`.

🔬 **El detalle** — **Biblioteca.** SQLAlchemy es las dos cosas a la vez: Core es el constructor y el
ORM va encima.

---

**04 → 2.** Nombra el constructor del corpus para cada uno de los cuatro lenguajes. 🟢

⏱️ **30 segundos** — jOOQ en Java, SQLAlchemy Core en Python, Kysely en TypeScript y sqlc en Go.

🗣️ **2 minutos** — Tres construyen el SQL al ejecutar; sqlc va al revés: lee un fichero `.sql` y
genera el código Go que lo ejecuta, con los tipos inferidos del esquema.

🔬 **El detalle** — En el informe, sqlc generó `ComprasMensuales(ctx, clienteID int64)` y el mes
como `pgtype.Date`, sin que se escribiera un tipo a mano.

---

**04 → 3.** ¿Qué es la escotilla de un constructor, y cuál es la de Kysely? 🟢

⏱️ **30 segundos** — El trozo de SQL literal que se mete donde el constructor no llega. En Kysely es
`` sql`…` ``.

🗣️ **2 minutos** — En jOOQ, `field("…")` y `table("…")`; en Core, `text()` y `literal_column()`. En
el informe, Kysely la usó para las fechas constantes y para sumar el intervalo, y jOOQ para el `at
time zone`.

🔬 **El detalle** — Usarla está previsto. Lo que se pierde en ese trozo es la comprobación de
nombres, y si se interpola un valor en vez de pasarlo como parámetro, la inyección de
[`10/02`](../10-interfaz-con-los-lenguajes/02-parametrizadas-e-inyeccion.md).

---

**04 → 4.** ¿Qué comando de PostgreSQL es el más rápido para cargar miles de filas? 🟢

⏱️ **30 segundos** — `COPY … FROM STDIN`: una sola sentencia que recibe las filas como un flujo.

🗣️ **2 minutos** — Medido con 10 000 eventos: entre 11 y 13 ms en los cuatro lenguajes, frente a
entre 1,1 y 1,6 s insertando fila a fila con el ORM.

🔬 **El detalle** — **Motor**, y no es del estándar. En Node depende de cómo se alimente: una línea
por trozo tardó 102 ms; un solo trozo, 12.

---

**04 → 5.** Distingue jOOQ o Kysely de sqlc: quién escribe el SQL y cuándo se comprueba. 🟡

⏱️ **30 segundos** — Con jOOQ y Kysely, el programador escribe código que construye el SQL al
ejecutar. Con sqlc escribe el SQL y la herramienta genera el código. sqlc lo comprueba entero contra
el esquema antes de compilar.

🗣️ **2 minutos** — jOOQ con clases generadas comprueba nombres y tipos al compilar; sin ellas, como
en el corpus, los nombres van como texto. Kysely comprueba contra el esquema escrito como tipos, que
puede mentir si no coincide con la base.

🔬 **El detalle** — **Biblioteca.** Si la consulta nombrara una columna inexistente, `sqlc generate`
fallaría antes de que exista una línea de Go.

---

**04 → 6.** ¿Puede JPA expresar una CTE recursiva con una función de ventana? ¿Y Hibernate? Responde
por separado. 🟡

⏱️ **30 segundos** — JPA no: la gramática de JPQL en Jakarta Persistence 3.2 tiene `UNION`, pero ni
`WITH` ni `OVER`. Hibernate sí: su HQL corrió el informe entero, con la CTE recursiva y la ventana.

🗣️ **2 minutos** — Hibernate 7.4 generó `with recursive meses (mes) as (…)` y `sum(…) over(order by
…)`, y devolvió las nueve filas. Necesitó `cast(:inicio as LocalDate)` en el término base para saber
el tipo, y `function('timezone', …)` como escotilla.

🔬 **El detalle** — **Especificación frente a biblioteca**: en JPA puro, una consulta así es nativa,
SQL en una cadena. Quien dice «JPA no hace ventanas» tiene razón sobre JPA y no sobre Hibernate.

---

**04 → 7.** ¿Por qué la clave `IDENTITY` impide a Hibernate agrupar inserciones, y cómo se evita? 🟡

⏱️ **30 segundos** — Porque para dar el identificador a cada objeto necesita que la base lo devuelva
al insertar, fila a fila. Se evita con una secuencia, que Hibernate pide por bloques.

🗣️ **2 minutos** — Medido: 1 372 ms con `IDENTITY` y `batch_size = 500`, 157 ms con secuencia y
lotes de 500. La documentación lo dice: *«Hibernate disables insert batching at the JDBC level
transparently if you use an identity identifier generator»*.

🔬 **El detalle** — **Biblioteca.** Con `allocationSize = 50` y la secuencia en `INCREMENT 50`,
Hibernate consulta la secuencia una vez cada 50 identificadores. Los dos valores tienen que
coincidir.

---

**04 → 8.** ¿Qué hace SQLAlchemy con 10 000 objetos nuevos al hacer `flush`, y en cuántas
sentencias? 🟡

⏱️ **30 segundos** — Los agrupa en sentencias de 1 000 filas con `RETURNING`: diez sentencias,
aunque la clave sea `IDENTITY`. Su registro lo llama `insertmanyvalues`.

🗣️ **2 minutos** — Corrido: `[generated in 0.03585s (insertmanyvalues) 1/10 (ordered)]` y 338 ms en
total. `RETURNING` le devuelve los identificadores de cada lote, así que no necesita ir fila a fila.

🔬 **El detalle** — **Biblioteca.** Core, con una lista de diccionarios y sin `RETURNING`, pasó una
sola sentencia al `executemany` de psycopg, que la envía en modo *pipeline*: 132 ms.

---

**04 → 9.** ¿Qué límite tiene un `INSERT` con muchas filas en PostgreSQL, y de dónde sale? ¿Lo fija
el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — 65 535 parámetros por sentencia. Sale del protocolo: el mensaje `Bind` lleva el
número de parámetros en un entero de 16 bits.

🗣️ **2 minutos** — Con tres columnas, son unas 21 800 filas por sentencia. Drizzle con 25 000 filas,
75 000 parámetros, falló.

🔬 **El detalle** — **Motor**, en el protocolo de mensajes. Por eso los lotes de GORM, Hibernate y
SQLAlchemy existen también para no llegar a ese techo.

---

**04 → 10.** Un informe mensual deja fuera los meses sin compras. ¿Qué le falta a la consulta, y
cómo lo escribirías? ¿Lo fija el estándar o es cosa del motor? 🟠

⏱️ **30 segundos** — Un calendario: una CTE recursiva que genera los meses, y un `LEFT JOIN` de las
compras contra él con `coalesce` a cero.

🗣️ **2 minutos** — Con el calendario, febrero y abril de `CLI-00311` salen con 0; sin él, el informe
tiene siete filas y el hueco no se ve. El acumulado, con `sum(…) over (order by mes)`.

🔬 **El detalle** — **Estándar**: `WITH RECURSIVE` y las ventanas están en ISO/IEC 9075. En
PostgreSQL, `generate_series` hace lo mismo que el calendario, sin recursión.

---

**04 → 11.** ¿Por qué usar `Raw` en GORM o `sql.raw` en Drizzle no es abandonar el ORM? 🟠

⏱️ **30 segundos** — Porque se usa la escotilla del ORM, dentro de su conexión y su transacción,
para lo que no es una entidad. El resultado se mapea igual a una estructura.

🗣️ **2 minutos** — Corrido: el mismo `informe.sql` que se probó en `psql` dio nueve filas en
`db.Raw` y en `db.execute(sql.raw(…))`. Es lo que hace sqlc, sin la comprobación previa.

🔬 **El detalle** — Drizzle 0.45 tiene `$with` pero ninguna variante recursiva: se leyó en la
biblioteca. Para el informe, SQL escrito era la única forma.

---

**04 → 12.** ¿Qué pierdes al cargar con `COPY` en vez de con el ORM, y cuándo te importa? 🟠

⏱️ **30 segundos** — Los identificadores generados, que `COPY` no devuelve; las validaciones y los
eventos del ORM; y la sesión, que no se entera de las filas.

🗣️ **2 minutos** — Importa si la aplicación necesita los identificadores para insertar hijos, o si
tiene lógica en los eventos de la entidad. Si solo hay que meter datos, no importa.

🔬 **El detalle** — **Motor** el `COPY`. Lo habitual para cargas grandes es cargar en una tabla
intermedia con `COPY` y pasar a la tabla definitiva con un `INSERT … SELECT`, que sí puede devolver
lo que haga falta.

---

**04 → 13.** Un compañero sube `hibernate.jdbc.batch_size` de 0 a 500 y la carga tarda lo mismo. Da
la causa probable y cómo la confirmarías. 🟠

⏱️ **30 segundos** — La entidad usa `GenerationType.IDENTITY`, y Hibernate desactiva los lotes de
inserción con ese generador. Se confirma mirando el generador de la entidad y el tiempo con una
secuencia.

🗣️ **2 minutos** — En el log del servidor saldrán 10 000 `INSERT` sueltos. Corrido: 1 372 ms con
`IDENTITY` y 157 con secuencia, con el mismo `batch_size`. Invertir el orden dio 1 314 y 236: no era
el calentamiento de la JVM.

🔬 **El detalle** — **Biblioteca**, y el registro no avisa. Por eso la primera pregunta de una carga
lenta con JPA es el generador de claves.

---

**04 → 14.** ¿Qué riesgo tiene un `UPDATE` masivo lanzado en medio de una sesión del ORM con
entidades cargadas? 🟠

⏱️ **30 segundos** — Que la sesión no se entera: las entidades cargadas siguen con el valor viejo, y
si después se guardan, pueden sobrescribir el cambio masivo.

🗣️ **2 minutos** — Es el dato viejo de [`03`](03-carga-caches-y-la-sesion.md) §6, provocado por la
propia aplicación. Se lanza al principio de la transacción o con la sesión limpia, y se recargan las
entidades que hagan falta.

🔬 **El detalle** — **Biblioteca.** El *dirty checking* de Hibernate compararía con el estado
cargado, no con el de la base, y el `UPDATE` de todas las columnas pisaría el cambio.

---

**04 → 15.** Un `insert` de Drizzle con 25 000 filas falla con `bind message has 9464 parameter
formats but 0 parameters`. Explica el mensaje y la corrección. 🔴

⏱️ **30 segundos** — 25 000 filas por tres columnas son 75 000 parámetros, y el protocolo cuenta los
parámetros en 16 bits: 75 000 − 65 536 = 9 464. El número dio la vuelta. Se corrige partiendo en
lotes.

🗣️ **2 minutos** — Con lotes de hasta unas 20 000 filas por sentencia, o de unos cientos, que dan
casi el mismo tiempo. Para cargas de ese tamaño, `COPY` es mejor que cualquier `INSERT`.

🔬 **El detalle** — **Motor**: el mensaje `Bind` lleva el número de parámetros en un `Int16`. El
error despista porque habla de formatos, no del límite.

---

**04 → 16.** Diseña la carga nocturna de un millón de eventos en un servicio que usa GORM para todo
lo demás: herramienta, transacción y qué pasa si falla a mitad. 🔴

⏱️ **30 segundos** — `CopyFrom` de pgx sobre una tabla intermedia, y después un `INSERT … SELECT` a
la tabla definitiva. En tramos con su propia transacción, anotando el último tramo cargado.

🗣️ **2 minutos** — Medido: `CopyFrom` cargó 10 000 filas en 11 ms, frente a 1 105 ms de `Create` uno
a uno. Tramos de, por ejemplo, 50 000 filas: si falla uno, se deshace ese tramo y se reanuda desde
el último confirmado. Una transacción de un millón de filas sería la transacción larga de
[`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md).

🔬 **El detalle** — GORM se queda para el resto del servicio. Lo que se decide es por tarea: la carga
masiva no pasa por entidades.

---

**04 → 17.** Escribe, en el constructor que prefieras, las compras mensuales de un cliente con los
meses sin compras y el acumulado. 🔴

⏱️ **30 segundos** — En Kysely: `withRecursive` para el calendario, `with` para las compras
agrupadas por mes, y un `leftJoin` con `sum(…).over(ob => ob.orderBy("m.mes"))`.

🗣️ **2 minutos** — Corrido:

```ts
db.withRecursive("meses(mes)", (db) =>
    db.selectNoFrom(sql<string>`date '2025-01-01'`.as("mes"))
      .unionAll(db.selectFrom("meses")
        .select(sql<string>`(mes + interval '1 month')::date`.as("mes"))
        .where("mes", "<", sql<string>`date '2025-09-01'`)))
  .with("compras", …)
  .selectFrom("meses as m").leftJoin("compras as c", "c.mes", "m.mes")
  .select((eb) => ["m.mes", …, eb.fn.sum<string>(eb.fn.coalesce("c.importe", sql<string>`0`))
    .over((ob) => ob.orderBy("m.mes")).as("acumulado")])
```

Nueve filas; la última,
`{"mes":"2025-09-01T00:00:00.000Z","pedidos":"1","importe":"4323.61","acumulado":"85985.35"}`.

🔬 **El detalle** — El mes se calcula en UTC en la consulta, con `at time zone 'UTC'`, para no
depender de la zona de la sesión.

---

## Capítulo 05 — Probar contra una base de datos real

Las 17 preguntas de [`05`](05-probar-contra-base-de-datos-real.md).

**05 → 1.** ¿Qué es Testcontainers, en una frase? 🟢

⏱️ **30 segundos** — Una biblioteca que, desde el programa de pruebas, arranca el motor de
producción en un contenedor de Docker, espera a que esté listo, entrega la URL y lo borra al
terminar.

🗣️ **2 minutos** — Existe para los cuatro lenguajes del corpus, con la misma idea. Corrido con
`postgres:18.6`: entre 1,5 y 2,2 s hasta estar listo.

🔬 **El detalle** — **Biblioteca** sobre **Docker**: necesita Docker donde corran las pruebas, en
local y en la integración continua.

---

**05 → 2.** ¿Qué es una base de datos embebida en memoria, y cuáles usa el corpus en cada lenguaje?
🟢

⏱️ **30 segundos** — Un motor que vive dentro del proceso, sin servidor, y desaparece al terminar.
En Java, H2; en Python, TypeScript y Go, SQLite en memoria.

🗣️ **2 minutos** — SQLite se abre con `sqlite3` en Python, con `node:sqlite` en Node y con
`modernc.org/sqlite` —SQLite escrito en Go— en Go.

🔬 **El detalle** — Son cómodas para las pruebas y, en el acceso a datos, prueban otro motor.

---

**05 → 3.** ¿Dónde pone PostgreSQL los nulos en un `ORDER BY … DESC`? 🟢

⏱️ **30 segundos** — Al principio. PostgreSQL trata el nulo como mayor que cualquier valor: al final
en `ASC` y primero en `DESC`.

🗣️ **2 minutos** — Corrido: el «último actualizado» salió `PED-00003`, el pedido sin fecha. H2 y
SQLite dieron `PED-00002`.

🔬 **El detalle** — **Motor.** `NULLS LAST` lo fija sin depender del motor, como en
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) §5.

---

**05 → 4.** ¿Qué hace Ryuk? 🟢

⏱️ **30 segundos** — Es un contenedor auxiliar de Testcontainers que vigila la conexión del proceso
de pruebas y, si el proceso muere sin limpiar, borra los contenedores que creó.

🗣️ **2 minutos** — Apareció como `testcontainers/ryuk:0.14.0` junto al de PostgreSQL. Tras cada
ejecución, `docker ps` no dejó nada con la etiqueta de Testcontainers.

🔬 **El detalle** — **Biblioteca.** Fue también el primer fallo al correrlo desde dentro de un
contenedor: `Could not connect to Ryuk at 172.17.0.1`.

---

**05 → 5.** Distingue lo que cambia `MODE=PostgreSQL` en H2 de lo que no cambia, con un ejemplo
corrido. 🟡

⏱️ **30 segundos** — En las cinco comprobaciones del capítulo no cambió nada: el mismo orden de
nulos y el mismo error de sintaxis con `ON CONFLICT … DO UPDATE`. Sí acepta `ON CONFLICT DO
NOTHING`.

🗣️ **2 minutos** — Corrido aparte: `DO NOTHING` dio `filas: 0`, y `DO UPDATE` falló con la marca
`[*]ON CONFLICT` en el sitio exacto. El modo imita partes de la sintaxis; cuáles, hay que
comprobarlo.

🔬 **El detalle** — **Motor**, H2. Un modo de compatibilidad no convierte a un motor en otro.

---

**05 → 6.** ¿Por qué `sum(total)` da `0.30000000000000004` en SQLite con una columna
`numeric(12,2)`? 🟡

⏱️ **30 segundos** — Porque en SQLite `numeric(12,2)` no es un tipo, es una afinidad: el `0.10`
literal se guarda como `REAL`, coma flotante binaria, y la suma es la de `0.1 + 0.2`.

🗣️ **2 minutos** — PostgreSQL y H2 guardan decimales exactos y dieron `0.30`. Una prueba de importes
contra SQLite prueba aritmética de coma flotante.

🔬 **El detalle** — **Motor**, SQLite, por diseño: su documentación explica que una columna con
afinidad `NUMERIC` guarda lo que parezca un real como `REAL`.

---

**05 → 7.** La misma línea huérfana se acepta en SQLite desde Python y se rechaza desde Node. ¿Por
qué? 🟡

⏱️ **30 segundos** — SQLite trae las claves foráneas desactivadas por defecto. `sqlite3` de Python
las deja así; `node:sqlite` las activa, con `enableForeignKeyConstraints` a `true` por defecto.

🗣️ **2 minutos** — `modernc.org/sqlite` en Go también las deja apagadas y aceptó la línea. Se
activan por conexión con `PRAGMA foreign_keys = ON`.

🔬 **El detalle** — **Motor y biblioteca**: el mismo motor miente distinto según quién lo abra.

---

**05 → 8.** ¿Por qué el módulo de PostgreSQL de Testcontainers espera dos veces la línea de «listo»?
🟡

⏱️ **30 segundos** — Porque la imagen oficial arranca un servidor para inicializar la base, lo para
y arranca el definitivo: la primera línea `ready to accept connections` es del servidor temporal.

🗣️ **2 minutos** — Lo dice el código del módulo de Go: `wait.ForLog("database system is ready to
accept connections").WithOccurrence(2)`, y después espera a que el puerto responda.

🔬 **El detalle** — **Biblioteca**, por un comportamiento de la **imagen**. Esperar solo la primera
daría pruebas que fallan a veces.

---

**05 → 9.** ¿Qué parte de las diferencias entre H2, SQLite y PostgreSQL es del estándar y qué parte
de cada motor? Responde para dos de ellas. 🟠

⏱️ **30 segundos** — Las claves foráneas y el `numeric` exacto son del estándar; SQLite se aparta en
los dos. `ON CONFLICT` no es del estándar: es de PostgreSQL, y SQLite lo copió.

🗣️ **2 minutos** — Para el orden de los nulos, el estándar da `NULLS FIRST` y `NULLS LAST` para no
depender de lo que haga cada motor.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas; la tabla del capítulo
lo marca así.

---

**05 → 10.** ¿Cuál de las cinco diferencias es la más peligrosa y por qué? 🟠

⏱️ **30 segundos** — El orden de los nulos, porque no falla: devuelve otro resultado. Una prueba que
espere `PED-00002` pasa en las cuatro bases en memoria y en producción sale `PED-00003`.

🗣️ **2 minutos** — Un error de sintaxis o de clave foránea avisa. Un resultado distinto y razonable
pasa todas las revisiones.

🔬 **El detalle** — Le sigue la suma en coma flotante, que tampoco avisa, pero se nota en céntimos.

---

**05 → 11.** ¿Cómo acaba una base de pruebas decidiendo el SQL de producción? Da el ejemplo del
upsert. 🟠

⏱️ **30 segundos** — Si las pruebas no aceptan una sentencia, el equipo la reescribe para que pasen.
H2 rechaza `ON CONFLICT … DO UPDATE`, y el equipo lo cambia por leer y después insertar o
actualizar.

🗣️ **2 minutos** — Esa reescritura tiene la carrera que el upsert evitaba: dos peticiones leen «no
existe» y las dos insertan. El SQL de producción queda peor para que pase una base que no es la de
producción.

🔬 **El detalle** — Escribir portable tiene su sitio, el de [`02/08`](../02-sql/08-dialectos.md) §5;
hacerlo para que pase H2 no es ese sitio.

---

**05 → 12.** ¿Por qué una suite comparte un solo contenedor, y qué precio tiene? 🟠

⏱️ **30 segundos** — Porque arrancarlo cuesta unos dos segundos: una vez por suite es aceptable, una
por prueba no. El precio es que las pruebas comparten base y hay que aislarlas.

🗣️ **2 minutos** — El aislamiento habitual es una transacción deshecha al final de cada prueba, y
los datos creados por la propia prueba.

🔬 **El detalle** — Reutilizar el contenedor entre ejecuciones también se puede —Java tiene
`testcontainers.reuse.enable`—, y se paga en limpieza entre una ejecución y otra.

---

**05 → 13.** ¿Qué no aísla deshacer la transacción al final de cada prueba, y qué harías en ese
caso? 🟠

⏱️ **30 segundos** — Lo que el código probado confirma por su cuenta o hace por otra conexión: eso
escapa al *rollback* y la siguiente prueba lo ve. Para ese código, `TRUNCATE` de las tablas entre
pruebas.

🗣️ **2 minutos** — El caso típico es `REQUIRES_NEW` de Spring, que es otra conexión, como se corrió
en [`10/05`](../10-interfaz-con-los-lenguajes/05-java.md) §6.

🔬 **El detalle** — No se corrió en este capítulo: depende del marco de pruebas. Se explica por el
mecanismo de la transacción.

---

**05 → 14.** ¿Qué riesgo tiene montar el socket de Docker en un contenedor, y cuándo es aceptable? 🟠

⏱️ **30 segundos** — Equivale a darle al contenedor control de administrador sobre Docker del
anfitrión: puede crear y borrar contenedores. Es aceptable en la integración continua y en un
entorno de pruebas; nunca en un contenedor de aplicación.

🗣️ **2 minutos** — Por eso en el corpus se monta solo en la orden que corre las pruebas, con `-v
/var/run/docker.sock:/var/run/docker.sock`, y no en el `compose`.

🔬 **El detalle** — Fuera de un contenedor, el caso normal en un portátil, Testcontainers usa el
Docker local y no hace falta montar nada.

---

**05 → 15.** Diagnostica: Testcontainers crea el contenedor pero falla con `Could not connect to
Ryuk at 172.17.0.1`. Da la causa y la corrección. 🔴

⏱️ **30 segundos** — Las pruebas corren dentro de un contenedor y Testcontainers busca los puertos
en la pasarela de la red por defecto de Docker, que no es la del contenedor. Se corrige con
`TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal` en Docker Desktop.

🗣️ **2 minutos** — Docker respondió y creó el contenedor: el socket funcionaba. Lo que fallaba era
llegar al puerto publicado. Con la variable, los cuatro lenguajes arrancaron PostgreSQL en unos dos
segundos.

🔬 **El detalle** — **Entorno**, no biblioteca. En Linux, la solución puede ser otra: la IP de la
pasarela de la red correcta o una red compartida.

---

**05 → 16.** Diseña la suite de pruebas de acceso a datos de un servicio con JPA que hoy prueba
contra H2: contenedores, esquema, aislamiento y el orden en que harías la migración. 🔴

⏱️ **30 segundos** — Un contenedor de `postgres` con la versión de producción, compartido por la
suite; el esquema con las migraciones reales; una transacción por prueba y `TRUNCATE` para lo que
confirma solo. Primero, las pruebas de repositorios con SQL propio.

🗣️ **2 minutos** — Orden: arrancar el contenedor en la clase base de pruebas; aplicar las
migraciones; mover primero las pruebas de consultas nativas y de upsert, que son las que H2 falsea;
después, el resto. Y revisar el SQL que se reescribió para H2.

🔬 **El detalle** — La imagen con versión exacta, nunca `latest`: la prueba debe correr contra lo
mismo que producción.

---

**05 → 17.** Escribe, en el lenguaje que prefieras, una prueba que falle contra H2 o SQLite y pase
contra PostgreSQL, y di qué comportamiento del motor la separa. 🔴

⏱️ **30 segundos** — En Python: una comprobación de que `sum(total)` de tres pedidos vale
exactamente `Decimal('0.30')`. Contra SQLite falla, porque llega `0.30000000000000004`; contra
PostgreSQL pasa.

🗣️ **2 minutos** — Corrido con el esquema del capítulo:

```python
with PostgresContainer("postgres:18.6", driver=None) as pg:
    with psycopg.connect(pg.get_connection_url(), autocommit=True) as con:
        suite("PostgreSQL 18.6 con Testcontainers", con)   # 2 suma de totales -> 0.30
suite("SQLite 3.46.1 en memoria", sqlite3.connect(":memory:", autocommit=True))
                                                           # 2 suma de totales -> 0.30000000000000004
```

🔬 **El detalle** — **Motor**: la afinidad `NUMERIC` de SQLite guarda el literal como `REAL`.

---

## Simulación de entrevista

Las 26 preguntas `S#` y los cuatro escenarios de [`06`](06-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**06 → S1.** Explica el mapa de identidad y el dato viejo que puede producir, con lo que se vio al
correrlo. 🟡

⏱️ **30 segundos** — La sesión guarda un objeto por fila cargada: pedir dos veces el mismo pedido da
el mismo objeto. Si otra conexión cambia la fila, la sesión sigue devolviendo el objeto como lo
cargó.

🗣️ **2 minutos** — Corrido en Hibernate: tras cambiar `PED-00042` a `ENVIADO` desde otra conexión,
la consulta fue a la base y devolvió `tras la consulta: PAGADO (mismo objeto: true)`; con `refresh`,
`ENVIADO`. SQLAlchemy, igual sin `commit` de por medio.

🔬 **El detalle** — **Biblioteca.** La base devolvió el valor nuevo; la sesión no lo sobrescribe. Se
evita con sesiones cortas, `refresh` o `populate_existing`.

---

**06 → S2.** Compara el `UPDATE` que generan Hibernate y SQLAlchemy al cambiar una sola columna, y
di qué riesgo tiene el primero. 🟡

⏱️ **30 segundos** — Hibernate escribe todas las columnas: `update pedidos set codigo=?,estado=?,
total=? where id=?`. SQLAlchemy, solo la que cambió. El riesgo del primero es pisar columnas que
otra transacción cambió.

🗣️ **2 minutos** — Hibernate lo hace para reutilizar una sentencia preparada por entidad;
`@DynamicUpdate` lo cambia. Además, escribe más en el WAL por cada fila.

🔬 **El detalle** — **Biblioteca.** La defensa de fondo contra pisar cambios es una columna de
versión, no `@DynamicUpdate`.

---

**06 → S3.** Dos peticiones a un servicio en Go con GORM editan el mismo pedido y una de las dos
pierde su cambio. Da el mecanismo y la corrección. 🟠

⏱️ **30 segundos** — Las dos leen, cambian y guardan con `Save`, que escribe todas las columnas:
gana la última y la primera se pierde. Es la actualización perdida.

🗣️ **2 minutos** — Corrección: un `Update` de la columna que cambia, con el estado leído en el
`WHERE`, y mirar las filas afectadas. Corrido: la primera llamada afectó 1 fila y la segunda 0.

🔬 **El detalle** — **Código**, no motor. GORM no tiene sesión que lo detecte; el control optimista
con versión de
[`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) §3 es
la forma general.

---

**06 → S4.** ¿Qué es *Open Session in View*, qué valor trae en Spring Boot y qué pasa al apagarlo? 🟠

⏱️ **30 segundos** — Mantener la sesión abierta toda la petición, para que las colecciones perezosas
se carguen durante la serialización. En Spring Boot, `spring.jpa.open-in-view` vale `true`. Al
apagarlo aparecen `LazyInitializationException` donde se dependía de él.

🗣️ **2 minutos** — Esconde el N+1 en el serializador y retiene la conexión toda la petición. Los
errores que salen al apagarlo son la lista exacta de lo que hay que arreglar: cargar en la consulta
o devolver proyecciones.

🔬 **El detalle** — **Spring Boot.** No se corrió en el corpus; se vería en el log de SQL, con
consultas después de que el controlador devolvió su resultado.

---

**06 → S5.** Una entidad cargada por Hibernate se modifica sin querer en una función de formato.
¿Qué ocurre al confirmar, y cómo lo detectarías? 🟠

⏱️ **30 segundos** — El *dirty checking* ve la entidad distinta de como se cargó y escribe un
`UPDATE` que nadie pidió. Se detecta con un `UPDATE` en el log de una operación que solo leía.

🗣️ **2 minutos** — Se evita formateando sobre proyecciones o copias, o con transacciones de solo
lectura, que no hacen *dirty checking*. En pruebas, contando sentencias por operación.

🔬 **El detalle** — **Biblioteca**: la unidad de trabajo de
[`01`](01-el-desajuste-y-los-dos-patrones.md) §5, funcionando como está diseñada.

---

**06 → S6.** Define el N+1 y di cuántas consultas dio en el corpus y dónde se contaron. 🟢

⏱️ **30 segundos** — Una consulta para la lista y una más por cada elemento. Los 52 pedidos de
`CLI-00311` con sus líneas dieron 53 consultas en los cuatro lenguajes.

🗣️ **2 minutos** — Se contaron en el log del servidor, con `log_statement = 'all'` para
`tienda_app` durante la prueba, descontando las consultas de arranque de Hibernate y SQLAlchemy.

🔬 **El detalle** — **Motor** el recuento. El log del ORM enseña lo que el ORM cree que manda.

---

**06 → S7.** Nombra las cuatro correcciones del N+1 y di cuál elegirías para un listado de solo
lectura. 🟡

⏱️ **30 segundos** — `JOIN`, segunda consulta con `IN`, carga por lotes y proyección. Para un
listado de solo lectura, la proyección.

🗣️ **2 minutos** — La proyección trae solo las columnas necesarias, no llena la sesión y fue una
consulta en los cuatro lenguajes. El `JOIN` repite el padre en cada hijo; el `IN` hace dos
consultas; los lotes, 1 + N ÷ tamaño.

🔬 **El detalle** — **Biblioteca** cada corrección. Si el listado necesita modificar las entidades,
la proyección no sirve.

---

**06 → S8.** ¿Por qué aparece el N+1 en GORM y Drizzle, que no tienen carga perezosa? 🟡

⏱️ **30 segundos** — Porque lo escribe el código: un bucle con una consulta dentro. Corrido: 53
consultas en los dos.

🗣️ **2 minutos** — Sin carga perezosa se ve mejor, porque la consulta está escrita en el bucle, pero
no es menos frecuente. Se corrige con `Preload` en GORM y la consulta relacional en Drizzle.

🔬 **El detalle** — Demuestra que el N+1 es un patrón de acceso, no un defecto de los ORM con sesión.

---

**06 → S9.** ¿Qué carga Hibernate al leer una entidad con un `@ManyToOne` sin `fetch` declarado, y
por qué? 🟢

⏱️ **30 segundos** — También la entidad referenciada, con un `JOIN`: el defecto de `@ManyToOne` en
JPA es `EAGER`.

🗣️ **2 minutos** — Corrido: cargar una línea trajo su pedido en un `join pedidos` que nadie
escribió. Por eso la recomendación es declarar todo `LAZY` y decidir la carga en cada consulta.

🔬 **El detalle** — **Especificación**, JPA. Las colecciones, `@OneToMany`, son perezosas por
defecto.

---

**06 → S10.** En local, una página con N+1 responde en 90 ms. ¿Por qué no es tranquilizador? 🟠

⏱️ **30 segundos** — Porque en local cada viaje a la base cuesta décimas de milisegundo. Con la base
a 1 ms de red, 52 consultas de más son 52 ms más por página, y crecen con los datos.

🗣️ **2 minutos** — El número que lo delata es el de consultas, que crece con la lista. Aun en local,
la versión ingenua fue la más lenta en los cuatro lenguajes.

🔬 **El detalle** — La prueba útil cuenta sentencias con datos de dos tamaños y falla si crecen.

---

**06 → S11.** ¿Qué da un constructor de consultas que no dan ni el ORM ni el SQL en una cadena? 🟡

⏱️ **30 segundos** — Estructura sin concatenar cadenas: el SQL que escribes es el que se ejecuta,
pero compuesto como código, con parámetros siempre y con comprobación de nombres.

🗣️ **2 minutos** — Frente al ORM, no hay sesión ni carga perezosa, y llega a CTE y ventanas. Frente
a la cadena, los filtros opcionales se componen sin riesgo de inyección.

🔬 **El detalle** — **Biblioteca.** El informe del bloque salió igual en jOOQ, Core, Kysely y sqlc.

---

**06 → S12.** «JPA no hace funciones de ventana». Responde con precisión. 🟡

⏱️ **30 segundos** — JPQL, la especificación, no: Jakarta Persistence 3.2 no tiene `OVER` ni `WITH`.
Hibernate sí: su HQL corrió el informe con la CTE recursiva y la ventana.

🗣️ **2 minutos** — En JPA puro, eso es una consulta nativa. En Hibernate 7.4, HQL genera `with
recursive` y `over(order by …)` y devuelve el resultado como tuplas.

🔬 **El detalle** — **Especificación frente a biblioteca.** Es el tipo de matiz que distingue a quien
lo ha corrido.

---

**06 → S13.** Elige la herramienta para cada tarea: la ficha editable de un pedido, el informe
mensual de un cliente, la carga nocturna de eventos y el paso de mil pedidos de un estado a otro. 🟠

⏱️ **30 segundos** — Ficha editable, el ORM. Informe, un constructor o SQL escrito. Carga nocturna,
`COPY`. Cambio masivo, un `UPDATE` con `WHERE`.

🗣️ **2 minutos** — El ORM sirve para una entidad cada vez. El informe no es una entidad. La carga
fila a fila costó cien veces más que `COPY`. Y cargar mil pedidos para cambiarlos son mil sentencias
y mil objetos en la sesión.

🔬 **El detalle** — Todo en el mismo servicio y la misma transacción si hace falta: los cuatro ORM
dejan ejecutar SQL dentro de su sesión.

---

**06 → S14.** ¿Por qué la clave `IDENTITY` hace lenta una carga con Hibernate y no con SQLAlchemy? 🟠

⏱️ **30 segundos** — Hibernate desactiva los lotes de inserción con `IDENTITY` porque necesita el
identificador de cada fila al insertarla. SQLAlchemy lo resuelve agrupando con `RETURNING`.

🗣️ **2 minutos** — Medido con 10 000 filas: Hibernate, 1 372 ms con `IDENTITY` y 157 con secuencia;
SQLAlchemy ORM, 338 ms en diez sentencias de 1 000 con la misma columna `IDENTITY`.

🔬 **El detalle** — **Biblioteca** en los dos casos. El motor ofrece `RETURNING`; quién lo aprovecha
lo decide la biblioteca.

---

**06 → S15.** ¿Qué límite tiene un `INSERT` de muchas filas en PostgreSQL, y cómo se reconoce su
error? 🟡

⏱️ **30 segundos** — 65 535 parámetros por sentencia, porque el protocolo cuenta los parámetros en
16 bits. El error dice algo como `bind message has 9464 parameter formats but 0 parameters`.

🗣️ **2 minutos** — El número del mensaje es el total menos 65 536: con 75 000 parámetros dio 9 464.
Se corrige en lotes o con `COPY`.

🔬 **El detalle** — **Motor**, en el mensaje `Bind` del protocolo.

---

**06 → S16.** Ordena por velocidad las formas de cargar 10 000 filas medidas en el bloque, con sus
cifras. 🟢

⏱️ **30 segundos** — `COPY`, entre 11 y 13 ms; lotes del driver o del ORM, de 30 a 340 ms; y el ORM
fila a fila, entre 1,1 y 1,6 s.

🗣️ **2 minutos** — En detalle: JDBC con lotes reescritos, 32 ms; GORM `CreateInBatches`, 32 ms;
Core, 132 ms; Hibernate con secuencia, 157 ms; Drizzle con un solo `insert`, 183 ms; SQLAlchemy ORM,
338 ms.

🔬 **El detalle** — `COPY` en Node, alimentado línea a línea, tardó 102 ms: el coste estaba en los
mensajes pequeños.

---

**06 → S17.** ¿Por qué no probarías el acceso a datos contra H2? Da dos diferencias corridas. 🟡

⏱️ **30 segundos** — Porque es otro motor. H2 pone los nulos al final en `DESC` y PostgreSQL al
principio, y H2 rechaza `ON CONFLICT … DO UPDATE` incluso en modo PostgreSQL.

🗣️ **2 minutos** — Con el mismo esquema, el «último actualizado» dio `PED-00002` en H2 y `PED-00003`
en PostgreSQL. Y el upsert, error de sintaxis en H2 y aceptado en PostgreSQL.

🔬 **El detalle** — **Motor.** El modo PostgreSQL de H2 no cambió ninguna de las cinco
comprobaciones.

---

**06 → S18.** ¿Qué hace Testcontainers, y cuánto cuesta? 🟢

⏱️ **30 segundos** — Arranca el motor de producción en un contenedor desde el programa de pruebas y
lo borra al terminar. Cuesta unos dos segundos por contenedor.

🗣️ **2 minutos** — Medido: entre 1 530 y 2 174 ms según el lenguaje, con la imagen ya descargada. Se
comparte un contenedor por suite. Necesita Docker en local y en la integración continua.

🔬 **El detalle** — **Biblioteca.** Ryuk limpia lo que quede si el proceso muere.

---

**06 → S19.** ¿Por qué SQLite en memoria miente distinto según la biblioteca que lo abra? 🟡

⏱️ **30 segundos** — Porque las claves foráneas se activan por conexión, y cada biblioteca decide:
`sqlite3` de Python y `modernc.org/sqlite` las dejan apagadas; `node:sqlite` las activa.

🗣️ **2 minutos** — La misma línea huérfana se aceptó en Python y en Go y se rechazó en Node. Las
otras mentiras —nulos, suma en coma flotante y `LIKE`— fueron iguales en los tres.

🔬 **El detalle** — **Motor y biblioteca**: SQLite las trae desactivadas por defecto, y `node:sqlite`
documenta `enableForeignKeyConstraints` a `true`.

---

**06 → S20.** ¿Qué no aísla deshacer la transacción al final de cada prueba? 🟠

⏱️ **30 segundos** — Lo que el código probado confirma por su cuenta o hace por otra conexión, como
un `REQUIRES_NEW`: escapa al *rollback* y la siguiente prueba lo ve.

🗣️ **2 minutos** — Para ese código, `TRUNCATE` de las tablas entre pruebas. Y los datos de cada
prueba, creados por ella.

🔬 **El detalle** — `REQUIRES_NEW` es otra conexión, corrido en
[`10/05`](../10-interfaz-con-los-lenguajes/05-java.md) §6.

---

**06 → S21.** ¿Qué parte de lo visto en este bloque es de JPA, qué parte de Hibernate y qué parte
del motor? Da un ejemplo de cada una. 🟡

⏱️ **30 segundos** — De JPA, que `@ManyToOne` sea ansiosa por defecto. De Hibernate, que `IDENTITY`
apague los lotes y que HQL tenga CTE y ventanas. Del motor, el orden de los nulos y el límite de
65 535 parámetros.

🗣️ **2 minutos** — Del estándar SQL, casi nada del bloque: ni sesiones, ni cachés, ni ORM. Lo que sí
es del estándar son las piezas de SQL, como `WITH RECURSIVE` y las ventanas.

🔬 **El detalle** — Separar capas es lo que se evalúa: la misma palabra, «Hibernate», cubre cosas que
manda la especificación y cosas que decide la biblioteca.

---

**06 → S22.** Diseña cómo atraparías en la integración continua el N+1 y las escrituras que nadie
pidió, antes de que lleguen a producción. 🔴

⏱️ **30 segundos** — Pruebas de integración contra PostgreSQL real con Testcontainers, que cuenten
las sentencias por operación con datos de dos tamaños y fallen si el número crece o si una operación
de lectura escribe.

🗣️ **2 minutos** — El recuento, con las estadísticas del ORM o con el log del servidor del
contenedor. Asociaciones `LAZY` en el mapeo, transacciones de solo lectura donde se lee, y
`open-in-view` apagado para que las cargas ocultas fallen en las pruebas.

🔬 **El detalle** — Contra H2 el recuento sería de otro motor: las consultas pueden ser las mismas,
pero lo que se quiere atrapar es lo que llega a PostgreSQL.

---

**06 → S23.** «Con un ORM no hace falta saber SQL». Refútalo con tres ejemplos del bloque. 🟠

⏱️ **30 segundos** — El N+1 solo se ve contando SQL en el servidor. El informe con CTE recursiva no
se escribe en JPQL. Y la carga masiva se arregla con `COPY`, que no es del ORM.

🗣️ **2 minutos** — Más: el `UPDATE` de todas las columnas de Hibernate, el dato viejo de la sesión y
el `UPDATE` condicional contra la actualización perdida se entienden en SQL.

🔬 **El detalle** — Los cuatro ORM del corpus tienen escotilla de SQL porque sus autores saben que
hace falta.

---

**06 → S24.** «El ORM hace el código portable entre bases de datos». ¿Qué parte es cierta? 🟡

⏱️ **30 segundos** — Traduce el núcleo: `SELECT`, `JOIN`, `INSERT` sencillos. No traduce la
semántica: el orden de los nulos, los tipos o el upsert siguen siendo de cada motor.

🗣️ **2 minutos** — Y en cuanto la consulta sale del núcleo —CTE, ventanas, `ON CONFLICT`, `COPY`—,
se escribe SQL del motor.

🔬 **El detalle** — La portabilidad de verdad es la de [`02/08`](../02-sql/08-dialectos.md): capas, y
el SQL específico agrupado.

---

**06 → S25.** «Si las pruebas pasan, el SQL está bien». ¿Cuándo es falso? 🟠

⏱️ **30 segundos** — Cuando las pruebas corren contra otro motor. Las cinco comprobaciones del
bloque dieron algo distinto de PostgreSQL en al menos una de las bases en memoria, y el orden de los
nulos, en todas.

🗣️ **2 minutos** — Y cuando las pruebas no miran lo que importa: el número de consultas, las
escrituras no pedidas o el plan. Una prueba verde sin contar sentencias no ve un N+1.

🔬 **El detalle** — La peor es la que no falla: el orden de los nulos devolvió otro pedido sin error.

---

**06 → S26.** «La caché de primer nivel es una optimización de rendimiento». Corrígelo. 🟡

⏱️ **30 segundos** — Es el mapa de identidad: su función es garantizar un objeto por fila dentro de
la sesión. El ahorro de consultas es un efecto secundario.

🗣️ **2 minutos** — Su efecto secundario más importante es el dato viejo: la sesión devuelve el
objeto que cargó aunque la base haya cambiado.

🔬 **El detalle** — **Biblioteca.** No se puede apagar; lo que se elige es cuánto dura la sesión.

---

**06 → E1.** Escenario 1 — La ficha de cliente que tarda cuatro segundos

⏱️ **30 segundos** — Un N+1: el tiempo crece con los pedidos del cliente. Se confirma con el log del
servidor durante una petición de un cliente antiguo: tantas consultas a `pedido_lineas` como
pedidos. Ni el *pool* ni un índice cambian el número de viajes.

🗣️ **2 minutos** — Con `open-in-view` encendido, las consultas salen en la serialización de la
respuesta, fuera del servicio. La corrección es por consulta: `join fetch`, carga por lotes o una
proyección para la ficha, y apagar `open-in-view` para que lo que quede falle en las pruebas. Subir
el *pool* solo retiene más conexiones durante la serialización.

🔬 **El detalle** — Lo que se evalúa es no aceptar el marco del equipo: el problema no es de
capacidad ni de índices, sino de cuántas consultas se mandan.

---

**06 → E2.** Escenario 2 — La carga nocturna de tres horas

⏱️ **30 segundos** — Con `IDENTITY`, Hibernate no agrupa inserciones, así que `batch_size` no hace
nada. Las alternativas medidas: secuencia y lotes, unas 9 veces más rápido; lotes del driver, unas
40; `COPY`, unas 100.

🗣️ **2 minutos** — Elegiría `COPY` a una tabla intermedia y un `INSERT … SELECT` a la definitiva,
por tramos confirmados y anotados para reanudar. Se pierden los identificadores devueltos, las
validaciones y los eventos del ORM; si hacen falta, se recuperan en el `INSERT … SELECT` o en un
paso posterior.

🔬 **El detalle** — Se espera el diagnóstico antes que la solución: nombrar el generador `IDENTITY` y
la frase de la documentación de Hibernate.

---

**06 → E3.** Escenario 3 — El monolito que prueba contra H2

⏱️ **30 segundos** — El orden y el upsert los habría atrapado Testcontainers: son diferencias de
motor. El índice que no se usa, no: una prueba funcional no mira el plan, y el contenedor tiene
otros datos y otras estadísticas.

🗣️ **2 minutos** — Suite: un contenedor de `postgres` con la versión de producción, compartido; el
esquema con las migraciones reales; una transacción por prueba y `TRUNCATE` para el código que
confirma solo. Primero, las pruebas de consultas nativas y de upsert. Y recuperar el `ON CONFLICT`
que se reescribió como «leer y escribir», que tiene una carrera.

🔬 **El detalle** — Lo que se evalúa es no vender Testcontainers como solución de todo: el plan de
una consulta depende de los datos y de las estadísticas, y eso se prueba de otra forma.

---

**06 → E4.** Escenario 4 — El estado que no cambia

⏱️ **30 segundos** — Esto no lo resuelve la base de datos. La consulta va a la base y la base
devuelve `ENVIADO`; es la sesión de Hibernate, abierta durante horas, la que devuelve el objeto que
ya tenía con `PAGADO`. Ni el aislamiento ni un índice tocan eso.

🗣️ **2 minutos** — Correcciones, de la más barata a la más robusta: `refresh` antes de decidir;
sesiones cortas, una por operación del operador; y leer el estado fresco en la propia operación. Y
en el reembolso, un `UPDATE … WHERE id = ? AND estado = 'PAGADO'` que mire las filas afectadas: si
es 0, el pedido ya no estaba pagado y no se reembolsa.

🔬 **El detalle** — Qué es de cada capa: el valor viejo es del **mapa de identidad**; la duración de
la sesión es decisión de la **aplicación**; lo único de la base es que devolvió el valor correcto,
como enseñó el log al correrlo. Lo que se evalúa es decirlo antes de proponer nada.

---

**Volver:** [README del bloque](README.md) · **Primer capítulo:**
[`01`](01-el-desajuste-y-los-dos-patrones.md).
