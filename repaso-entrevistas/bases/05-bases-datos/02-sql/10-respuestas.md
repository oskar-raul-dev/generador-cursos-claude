# 10 — Respuestas

> Solucionario del bloque: el enunciado copiado literalmente de su capítulo y la respuesta en tres
> capas.
>
> **Cómo se usa.** Responde primero en voz alta, con el cronómetro. La capa ⏱️ es lo que dices en
> los primeros treinta segundos; la 🗣️ es lo que añades cuando te dicen "cuéntame más"; la 🔬 es el
> matiz que casi nadie trae, y es donde vive la distinción entre **lo que manda el estándar, lo que
> hace tu motor y lo que es pura convención**.
>
> **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

- [Capítulo 01 — Familias del lenguaje y tipos](#capítulo-01--familias-del-lenguaje-y-tipos)
- [Capítulo 02 — `SELECT` y el orden lógico](#capítulo-02--select-y-el-orden-lógico)
- [Capítulo 03 — Joins](#capítulo-03--joins)
- [Capítulo 04 — Agregación y subconsultas](#capítulo-04--agregación-y-subconsultas)
- [Capítulo 05 — CTE y recursión](#capítulo-05--cte-y-recursión)
- [Capítulo 06 — Funciones de ventana](#capítulo-06--funciones-de-ventana)
- [Capítulo 07 — Escritura, upsert y vistas](#capítulo-07--escritura-upsert-y-vistas)
- [Capítulo 08 — Dialectos](#capítulo-08--dialectos)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — Familias del lenguaje y tipos

Las 16 preguntas de [`01`](01-familias-del-lenguaje-y-tipos.md).

**01 → 1.** Nombra las cuatro familias del lenguaje y una sentencia de cada una. 🟢

⏱️ **30 segundos** — DDL para la forma de los datos (`CREATE TABLE`), DML para las filas (`INSERT`),
DCL para los permisos (`GRANT`) y TCL para el límite de la transacción (`COMMIT`).

🗣️ **2 minutos** — El reparto sirve para acordarse de que no todas las sentencias se comportan igual
dentro de una transacción: el DML siempre se puede deshacer, y el DDL depende del motor. `SELECT` se
suele meter en DML aunque no manipule nada, y algunos manuales le inventan una quinta familia, DQL,
para él solo. Lo importante en una entrevista no es recitar los cuatro nombres sino saber qué
implica cada uno cuando algo falla a mitad de una migración.

🔬 **El detalle** — **Convención**, no estándar. ISO/IEC 9075 clasifica las sentencias con otra
taxonomía —*SQL-schema statements*, *SQL-data statements*, *SQL-transaction statements*— y ningún
manual de PostgreSQL, MySQL o SQLite se organiza con DDL/DML/DCL/TCL. Los acrónimos vienen de la
literatura de IBM y Oracle. No he verificado la cláusula exacta de la norma, que es de pago.

---

---

**01 → 2.** ¿Qué guarda exactamente `timestamptz` y qué pasa con ese valor cuando cambias `SET
timezone`? 🟢

⏱️ **30 segundos** — Guarda un instante absoluto en UTC, ocho bytes, y no guarda ninguna zona. `SET
timezone` solo cambia cómo te lo renderiza al leer.

🗣️ **2 minutos** — Al escribir, PostgreSQL convierte lo que le des a UTC usando la zona de la sesión
si el literal no traía desplazamiento. Al leer, hace el camino inverso contra `TimeZone`. Por eso
`creado_en` de `PED-00042` se ve como `2025-02-21 03:08:09.349067+00` en `Etc/UTC` y como
`2025-02-20 22:08:09.349067-05` en `America/Bogota`: cambia hasta el día, pero es el mismo momento.

🔬 **El detalle** — La prueba de que no se movió nada es el `epoch`: `1740107289.349067` en las dos
zonas, idéntico al microsegundo. **Motor**: el estándar no fija la representación; PostgreSQL guarda
UTC, el `TIMESTAMP` de MySQL también convierte pero su `DATETIME` no convierte nada, y SQLite no
tiene tipo de fecha. `SET` es transaccional en PostgreSQL, así que un `SET timezone` dentro de un
`BEGIN … ROLLBACK` se deshace con el resto.

---

---

**01 → 3.** ¿Qué le hace `char(10)` a la cadena `'ES'` al guardarla, y qué devuelve `length()`
después? 🟢

⏱️ **30 segundos** — La rellena con ocho espacios hasta los diez caracteres, pero `length()`
devuelve 2: el relleno se paga y no se ve.

🗣️ **2 minutos** — Medido en sesión: `octet_length('ES'::char(10))` da 10 y
`octet_length('ES'::varchar(10))` da 2. La concatenación también recorta, así que
`'['||'ES'::char(10)||']'` imprime `[ES]`. El relleno además cambia la igualdad: `'E '::char(2) =
'E'` es cierto y `'E '::text = 'E'` es falso.

🔬 **El detalle** — Que los espacios finales sean insignificantes en el tipo `CHARACTER` es **del
estándar**, y lo respetan PostgreSQL y MySQL; en SQLite `CHAR(n)` es solo afinidad `TEXT` y no
rellena nada. `clientes.pais char(2)` está bien elegido justamente porque ISO 3166-1 mide siempre
dos y el relleno es cero. **Cuánto cuesta:** espacio proporcional al hueco, más una trampa de
comparación que no avisa.

---

---

**01 → 4.** Di qué devuelve `->` y qué devuelve `->>` sobre una columna `jsonb`, con su tipo. 🟢

⏱️ **30 segundos** — `->` devuelve `jsonb` y conserva las comillas; `->>` devuelve `text` y las
quita.

🗣️ **2 minutos** — Sobre `eventos_pedido.carga`, `carga -> 'origen'` sale como `"web"` con
`pg_typeof` igual a `jsonb`, y `carga ->> 'origen'` sale como `web` con tipo `text`. La consecuencia
práctica es de tipos: comparar `carga -> 'origen' = 'web'` no compila, hay que escribir `carga ->
'origen' = '"web"'::jsonb` o usar `->>`.

🔬 **El detalle** — **Motor.** Los dos operadores son de PostgreSQL; MySQL tiene `->` y `->>` propios
con su sintaxis de ruta, y SQLite los resuelve con funciones `json_extract`. La versión con `->>`
sobre las dos claves tardó 471 ms contra los 605 ms de `@>` sin índice; con un índice GIN se
invierte, porque solo `@>` lo puede usar.

---

---

**01 → 5.** Diferencia `json` de `jsonb` en las dos cosas que `jsonb` no conserva. 🟡

⏱️ **30 segundos** — `jsonb` no conserva el orden de las claves ni las claves duplicadas; `json`
guarda el texto tal cual y conserva las dos cosas.

🗣️ **2 minutos** — Medido: `'{"version": 1, "origen": "web", "version": 2}'::json` sale igual que
entró, y el mismo literal como `jsonb` sale `{"origen": "web", "version": 2}` — perdió la primera
`version` y reordenó. El reorden no es alfabético: es por longitud de clave y después por bytes, que
es como `jsonb` las indexa. `json` es un `text` validado; `jsonb` es un árbol binario parseado al
insertar.

🔬 **El detalle** — Por eso `json` gana cuando el documento es una firma, un *payload* que hay que
devolver byte a byte o una prueba de auditoría, y pierde cuando hay que consultarlo, porque cada
acceso reparsea el texto entero. Y el binario no siempre es más pequeño: el documento de `PED-00042`
ocupa **96 bytes como `jsonb` y 75 como `json`**. **Motor**: `jsonb` es de PostgreSQL; MySQL 9.7.2
tiene un solo tipo `JSON`, también binario y también normalizador.

---

---

**01 → 6.** ¿Qué diferencia hay entre `timestamp` y `timestamptz` para una columna que guarda cuándo
se creó un pedido? 🟡

⏱️ **30 segundos** — `timestamptz` identifica un instante y `timestamp` no. Para "cuándo se creó un
pedido" solo sirve el primero.

🗣️ **2 minutos** — Los dos ocupan ocho bytes, así que la elección no es de espacio. La diferencia es
semántica: `timestamp` guarda una fecha y una hora sin decir de dónde son, y no convierte nunca. En
la sesión se ve claro: cambiando de `Etc/UTC` a `America/Bogota`, el valor con zona pasa de `03:08`
del día 21 a `22:08` del día 20 y el valor sin zona se queda en `2025-02-21 03:08:09.349067` en las
dos.

🔬 **El detalle** — Esa estabilidad aparente es el problema: `03:08` sin zona no identifica ningún
momento de la línea del tiempo. `timestamp` es el tipo correcto para una hora de apertura, un
cumpleaños o un horario que se repite; para una marca de auditoría, no. **Motor**: el `TIMESTAMP` de
MySQL convierte a la zona de la sesión al leer y su `DATETIME` no convierte, y SQLite guarda texto
ISO-8601.

---

---

**01 → 7.** Que la agrupación DDL/DML/DCL/TCL exista, ¿lo fija el estándar o es convención del
gremio? 🟡

⏱️ **30 segundos** — Es convención. El estándar usa otra taxonomía y ningún manual de motor se
organiza con esos cuatro acrónimos.

🗣️ **2 minutos** — ISO/IEC 9075 habla de *SQL-schema statements*, *SQL-data statements*,
*SQL-transaction statements* y *SQL-control statements*, entre otras categorías. Los acrónimos
DDL/DML/DCL/TCL vienen de los manuales de IBM y de Oracle y se han quedado como vocabulario
compartido. Que sea convención no los hace inútiles: la frontera DDL/DML es exactamente la que
decide si algo se puede deshacer.

🔬 **El detalle** — **Convención**, y la cláusula del estándar no la he verificado: la norma es de
pago. Lo que sí es comprobable es que la documentación de PostgreSQL 18, MySQL 9.7 y SQLite no usa
esa partición. Una buena respuesta de entrevista enumera las cuatro familias y añade que el reparto
es doctrina, no norma.

---

---

**01 → 8.** ¿Qué es la afinidad de tipo de SQLite y en qué se diferencia de un tipo de columna? 🟡

⏱️ **30 segundos** — La columna no declara un tipo sino una preferencia de conversión: si el valor
no se puede convertir, se guarda como vino. El tipo lo tiene el valor, no la columna.

🗣️ **2 minutos** — En la tienda, `pedido_lineas.cantidad` está declarada `INTEGER NOT NULL CHECK
(cantidad > 0)` y admite la cadena `'tres'`: `typeof(cantidad)` devuelve `text`. Tampoco hay tipo
fecha ni tipo booleano — `typeof(true)` es `integer` y `typeof(CURRENT_TIMESTAMP)` es `text`. La
diferencia con PostgreSQL o MySQL es que allí el tipo es una restricción y aquí es una sugerencia.

🔬 **El detalle** — El `CHECK` no protege: en el orden de clases de tipo de SQLite todo texto es
mayor que todo número, así que `'tres' > 0` es cierto. **Motor**, y se puede apagar: desde 3.37 una
tabla `STRICT` rechaza el valor con `Error: cannot store TEXT value in INTEGER column …`. Es la
única forma de tener tipado estático en SQLite.

---

---

**01 → 9.** Explica por qué la suma en `double precision` de las 3 500 000 líneas dio 0,00494 €
menos, y por qué ese error no se compensa al crecer el número de filas. 🟠

⏱️ **30 segundos** — Porque `double precision` representa los importes en base 2 y un céntimo no
tiene representación finita en binario; cada sumando entra ya redondeado y los redondeos van en la
misma dirección.

🗣️ **2 minutos** — La suma exacta en `numeric` da `5178452860.88` y la convertida a coma flotante
`5178452860.875059`, medido sobre las mismas filas. El error de cada valor es minúsculo, pero no es
ruido aleatorio con media cero: es el sesgo del redondeo al binario más cercano para esa familia de
importes, repetido 3 500 000 veces. Además, cuando el acumulador crece mucho, los sumandos pequeños
pierden bits al alinearse con él, que es la otra fuente de pérdida.

🔬 **El detalle** — **Estándar** en la categoría —`NUMERIC` es exacto y `FLOAT`/`REAL`/`DOUBLE
PRECISION` aproximados, y los tres motores lo respetan— y **IEEE 754** en cómo se aproxima. La
medida fue `−0,00494 €`. Y ojo con el mito de la velocidad: aquí la suma en `numeric` tardó 355 ms y
la convertida 515 ms, porque el `::double precision` paga una conversión por fila.

---

---

**01 → 10.** En MySQL, ¿qué sentencias además del DDL cierran una transacción abierta, y cuál es la
excepción que sí la respeta? 🟠

⏱️ **30 segundos** — `LOCK TABLES`, `TRUNCATE TABLE`, `ANALYZE TABLE`, `SET autocommit = 1` y hasta
un `START TRANSACTION` nuevo. La excepción son las tablas temporales.

🗣️ **2 minutos** — Lo comprobé abriendo una transacción, insertando una fila, ejecutando `LOCK
TABLES … WRITE` y `UNLOCK TABLES`, y haciendo `ROLLBACK`: la fila seguía ahí. `LOCK TABLES` no es
DDL y aun así confirmó lo pendiente. La misma secuencia con `CREATE TEMPORARY TABLE` y `DROP
TEMPORARY TABLE` en medio sí deshace la inserción.

🔬 **El detalle** — **Motor**, y es la razón por la que una migración de cinco `ALTER` que falla en
el tercero deja a MySQL con dos aplicados: no hay nada que deshacer, porque cada sentencia confirmó
antes de ejecutarse. En PostgreSQL y en SQLite el `ALTER TABLE` es transaccional y el `ROLLBACK` lo
revierte. El consejo *"envuelve la migración en una transacción"* está escrito para PostgreSQL.

---

---

**01 → 11.** Un cliente conectado en `latin1` guarda un emoji en una columna `utf8mb3` sin ningún
error y lo lee bien. ¿Por qué, y por qué es peor que el `ERROR 1366`? 🟠

⏱️ **30 segundos** — Porque el servidor interpreta los cuatro bytes del emoji como cuatro caracteres
latin-1, que sí caben en `utf8mb3`, y al leer los vuelve a convertir a latin-1 y salen iguales. La
corrupción da la vuelta completa sin que nadie se entere.

🗣️ **2 minutos** — Con `SET NAMES utf8mb4` el mismo `INSERT` responde `ERROR 1366 (HY000): Incorrect
string value: '\xF0\x9F\x8E\xA7 P...'`. Con el cliente por defecto del contenedor, que negocia
`latin1`, entra sin protestar. La diferencia se mide: `'Audio 🎧 PRD-00017'` bien guardado son 17
caracteres y 20 bytes; en el camino corrupto son **20 caracteres y 24 bytes**.

🔬 **El detalle** — Es peor porque el error se detecta en la escritura y la corrupción silenciosa se
detecta meses después, cuando lo lee otro cliente —una API en UTF-8, un exportador, un índice de
búsqueda— y ve cuatro caracteres basura. **Motor**: `utf8mb3` topa en tres bytes y no cubre el plano
suplementario. En MySQL 9.7.2 `utf8` ya es sinónimo de `utf8mb4`, pero una tabla creada con `utf8`
en MySQL 5.7 sigue siendo `utf8mb3` hoy, y arreglarla cuesta un `CONVERT TO CHARACTER SET` que
reescribe la tabla entera.

---

---

**01 → 12.** `SELECT sum(cantidad)` sobre `PED-00042` en SQLite devuelve `9.0` en vez de `9`. Da la
hipótesis más probable y la consulta con la que la confirmarías. 🟠

⏱️ **30 segundos** — Que alguna fila tiene en `cantidad` un valor que no es entero —texto, casi
seguro— y SQLite lo aceptó por afinidad; al sumar, arrastra el resultado a coma flotante.

🗣️ **2 minutos** — `sum()` en SQLite devuelve entero mientras todos los sumandos lo sean, y pasa a
real en cuanto uno no lo es. Un texto no convertible suma cero, así que además del `.0` el total se
queda corto. Lo confirmo con `typeof()`, que es la herramienta específica de este motor:

```sql
SELECT linea, typeof(cantidad), cantidad
  FROM pedido_lineas WHERE pedido_id = 42 AND typeof(cantidad) <> 'integer';
```

🔬 **El detalle** — **Motor.** Es el efecto de la afinidad: `cantidad INTEGER NOT NULL CHECK
(cantidad > 0)` aceptó `'tres'`, y el `CHECK` no protestó porque en el orden de clases de tipo de
SQLite todo texto es mayor que todo número. El mismo pedido da `9` sin la fila falsa y `9.0` con
ella. La defensa es declarar la tabla `STRICT`, disponible desde 3.37.

---

---

**01 → 13.** Que existan un tipo `UUID` nativo y los arrays de columna, ¿es del estándar o de cada
motor? Di qué hace cada uno de los tres motores del corpus. 🟠

⏱️ **30 segundos** — De cada motor. El estándar no define ninguno de los dos, y solo PostgreSQL los
tiene de verdad.

🗣️ **2 minutos** — PostgreSQL tiene `uuid` nativo de 16 bytes y arrays con sus operadores. MySQL
resuelve el UUID con `BINARY(16)` más `UUID_TO_BIN()`/`BIN_TO_UUID()` y no tiene arrays. SQLite
guarda el UUID como texto o `BLOB` y tampoco tiene arrays. Los tres se apañan; lo que cambia es
cuánto trabajo te queda a ti.

🔬 **El detalle** — **Motor**, y la cláusula del estándar no la he verificado —es de pago—, pero
ningún manual presenta estos tipos como parte de la norma. Lo que sí se mide es el precio de no usar
el nativo: `pg_column_size` da 16 bytes para `uuid` y 40 para el mismo valor como `text`, y en
`text` la mayúscula y la variante sin guiones serían valores distintos que un `UNIQUE` no
detectaría. Con un array, el aviso es al revés: no admite clave foránea, y modelar una relación con
él acaba en `unnest`.

---

---

**01 → 14.** Escribe el DDL de una tabla `pagos_divisa` que guarde importes en varias monedas sin
perder céntimos, con la moneda restringida a un catálogo cerrado y la marca de pago comparable entre
zonas. Justifica cada tipo. 🔴

⏱️ **30 segundos** — `numeric(14,2)` para el importe, `char(3)` con `CHECK` para la moneda ISO 4217
y `timestamptz` para la marca. Nada de `float` y nada de `timestamp` sin zona.

🗣️ **2 minutos** — El DDL, en la línea del esquema de la tienda:

```sql
CREATE TABLE pagos_divisa (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pago_id    bigint NOT NULL REFERENCES pagos(id),
  moneda     char(3) NOT NULL CHECK (moneda IN ('EUR','USD','COP','MXN')),
  importe    numeric(14,2) NOT NULL CHECK (importe > 0),
  pagado_en  timestamptz NOT NULL,
  referencia text UNIQUE                 -- nulo cuando el proveedor no la devuelve
);
```

🔬 **El detalle** — `numeric(14,2)` porque es exacto en base 10 —**categoría del estándar**— y 14
dígitos dejan sitio a monedas con importes grandes; la alternativa sería un entero de céntimos, 4 u
8 bytes, con el punto decimal a cargo del código. `char(3)` es correcto aquí precisamente porque ISO
4217 mide siempre tres y el relleno es cero, igual que `clientes.pais char(2)`; con `varchar` no
ganarías nada. El `CHECK` con lista cerrada mantiene el catálogo pequeño en el motor y no en la
aplicación. `timestamptz` para que el instante sea el mismo se mire desde donde se mire. Y **el
aviso de diseño**: `(moneda, importe)` juntos no bastan para comparar totales entre monedas; para
eso hace falta la tasa y su fecha, y eso es otra tabla.

---

---

**01 → 15.** Escribe la secuencia completa —en PostgreSQL y en MySQL— para añadir una columna y un
`CHECK` a `pedidos` de forma que, si el `CHECK` falla, no quede nada a medias. Di qué cambia entre
los dos motores y qué harías en MySQL para conseguirlo. 🔴

⏱️ **30 segundos** — En PostgreSQL basta con `BEGIN … COMMIT`. En MySQL no existe esa opción: cada
`ALTER` confirma solo, así que el "todo o nada" hay que fabricarlo con una sola sentencia o con un
`ALTER` inverso escrito de antemano.

🗣️ **2 minutos** — PostgreSQL, atómico de verdad:

```sql
BEGIN;
ALTER TABLE pedidos ADD COLUMN canal text;
ALTER TABLE pedidos ADD CONSTRAINT pedidos_canal_check
  CHECK (canal IS NULL OR canal IN ('WEB','MOVIL','TIENDA'));
COMMIT;   -- si el CHECK falla, el ROLLBACK implícito deja la tabla como estaba
```

MySQL, lo más cerca que se puede llegar:

```sql
ALTER TABLE pedidos
  ADD COLUMN canal VARCHAR(10) NULL,
  ADD CONSTRAINT pedidos_canal_check
    CHECK (canal IS NULL OR canal IN ('WEB','MOVIL','TIENDA'));
```

🔬 **El detalle** — **Motor.** En MySQL el `START TRANSACTION` que envuelva a los dos `ALTER` no
sirve: cada uno confirma implícitamente antes de ejecutarse, y si el segundo falla la columna ya
está puesta. Las dos salidas son juntarlo todo en **un solo `ALTER TABLE`**, que sí es atómico desde
8.0 gracias al diccionario de datos transaccional, o dejar escrito el `ALTER TABLE pedidos DROP
COLUMN canal` como compensación y ejecutarlo desde la herramienta de migración. Y el otro coste, que
no es de atomicidad sino de disponibilidad: comprobar el `CHECK` sobre el millón de filas existentes
lee la tabla entera. En PostgreSQL se evita con `ADD CONSTRAINT … NOT VALID` seguido de `VALIDATE
CONSTRAINT`, que no bloquea las escrituras.

---

---

**01 → 16.** Diseña la consulta que detecte, sobre `eventos_pedido`, los documentos `carga` a los
que les falta la clave `version` o la tienen con un tipo que no es número. Usa solo operadores y
funciones de `jsonb`. 🔴

⏱️ **30 segundos** — Con el operador `?` para la existencia de la clave y `jsonb_typeof` para el
tipo del valor, unidos con un `OR`.

🗣️ **2 minutos** — La consulta:

```sql
SELECT id, pedido_id, tipo, carga
  FROM eventos_pedido
 WHERE NOT (carga ? 'version')
    OR jsonb_typeof(carga -> 'version') <> 'number'
 LIMIT 20;
```

Y el recuento por caso, que es lo que se lleva uno a la reunión:

```sql
SELECT coalesce(jsonb_typeof(carga -> 'version'), 'ausente') AS estado, count(*)
  FROM eventos_pedido GROUP BY 1 ORDER BY 2 DESC;
```

🔬 **El detalle** — Tres matices. `carga ? 'version'` distingue **clave ausente** de **clave presente
con valor `null`**; `jsonb_typeof` devuelve `'null'` para el segundo caso y `NULL` de SQL para el
primero, y por eso hace falta el `coalesce` en el agrupado — es el nulo de
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) asomando
dentro del documento. Usar `(carga ->> 'version')::int` en su lugar es un error: revienta con
`invalid input syntax` en la primera fila mala en vez de encontrarla. **Motor**: `?`, `jsonb_typeof`
y `@>` son de PostgreSQL; en MySQL esto se escribe con `JSON_CONTAINS_PATH` y `JSON_TYPE`. **Cuánto
cuesta:** sobre 4 100 000 filas sin índice es un `Seq Scan`; un índice GIN sobre `carga` ayuda a `?`
y a `@>`, no a `jsonb_typeof`.

---

## Capítulo 02 — `SELECT` y el orden lógico

Las 18 preguntas de [`02`](02-select-y-el-orden-logico.md).

**02 → 1.** **Escribe el orden lógico de evaluación completo, de `FROM` a `LIMIT`, y di en qué paso
nacen los alias del `SELECT`. 🟢**

⏱️ **30 segundos** — `FROM` → `WHERE` → `GROUP BY` → `HAVING` → `SELECT` → `DISTINCT` → `ORDER BY` →
`LIMIT`. Los alias nacen en el paso del `SELECT`, que es el quinto.

🗣️ **2 minutos** — El `FROM` resuelve las tablas y sus combinaciones, el `WHERE` descarta filas una
a una, el `GROUP BY` colapsa las supervivientes en grupos, el `HAVING` descarta grupos ya agregados,
el `SELECT` calcula las expresiones y les pone nombre, el `DISTINCT` elimina filas proyectadas
repetidas, el `ORDER BY` ordena lo que salió y el `LIMIT` corta. Dicho así se ve por qué el `WHERE`
no puede ver un alias y el `ORDER BY` sí: uno va dos pasos antes de que el nombre exista y el otro
dos después.

🔬 **El detalle** — Es semántica, no plan de ejecución: el motor reordena el trabajo real todo lo que
quiera —empuja filtros hacia abajo, corta antes de terminar de ordenar— mientras el resultado no
cambie. Lo único que el orden lógico fija de verdad es **qué nombres son visibles en cada
cláusula**, y ahí no hay libertad.

---

---

**02 → 2.** **¿Por qué falla `WHERE iva > 100` cuando `iva` es un alias declarado en el `SELECT`?
🟢**

⏱️ **30 segundos** — Porque el `WHERE` se evalúa en el paso 2 y el alias nace en el paso 5. Cuando
el `WHERE` corre, todavía no existe nada llamado `iva`.

🗣️ **2 minutos** — PostgreSQL responde `ERROR: column "iva" does not exist` y te apunta con el
cursor a la palabra. No es un capricho ni una limitación del parser: es que la lista de salida aún
no se ha calculado. Se arregla de tres formas —repitiendo la expresión en el `WHERE`, metiendo el
cálculo en una subconsulta o en un `WITH`—, y la repetición es la más barata porque no materializa
nada intermedio.

🔬 **El detalle** — Es **motor**, no estándar, cuánto aprieta esa regla. PostgreSQL, MySQL 9.7.2 y
MariaDB 12.3.3 la rechazan; **SQLite 3.53.4 la acepta** y devuelve filas. Si tu consulta con alias
en el `WHERE` funciona, no es que sea correcta: es que estás en SQLite.

---

---

**02 → 3.** **¿Cuál de las dos, `WHERE` o `HAVING`, filtra grupos, y por qué no puede ser la otra?
🟢**

⏱️ **30 segundos** — El `HAVING`. El `WHERE` corre antes del `GROUP BY`, cuando todavía no hay
grupos que filtrar.

🗣️ **2 minutos** — El `WHERE` es el paso 2 y ve filas individuales; el `HAVING` es el paso 4 y ve
grupos con sus agregados ya calculados. Por eso una condición sobre `count(*)` o `sum(total)` solo
puede ir en el `HAVING`: en el paso 2 ese valor no existe. Y al revés, una condición sobre una
columna de la fila cabe en los dos sitios, pero en el `HAVING` obliga al motor a agrupar filas que
iba a tirar.

🔬 **El detalle** — El error caro es creer que la elección es de rendimiento. Es de **resultado**:
sobre `pedidos`, `HAVING count(*) >= 38` sin `WHERE` devuelve seis clientes, y con `WHERE estado <>
'ANULADO'` delante devuelve tres. No cambian solo los números: cambia quién sale en el informe.

---

---

**02 → 4.** **¿Qué garantiza `LIMIT 10` sobre una consulta sin `ORDER BY`? 🟢**

⏱️ **30 segundos** — Que te devuelve como mucho diez filas. Cuáles, no lo garantiza nadie.

🗣️ **2 minutos** — Una tabla no tiene orden: es del modelo relacional, no del motor. Sin `ORDER BY`,
el motor entrega las filas en el orden que le resulte más barato, y eso cambia si cambia el plan, la
versión o el motor. `SELECT codigo, estado FROM pedidos WHERE estado = 'ANULADO' LIMIT 3` devuelve
`PED-178323`, `PED-115603` y `PED-71382` en PostgreSQL, y `PED-00024`, `PED-00051` y `PED-00077` en
SQLite y en MySQL, con exactamente los mismos datos.

🔬 **El detalle** — `LIMIT` sin `ORDER BY` es un muestreo, no una consulta: sirve para mirar qué
pinta tienen los datos y para nada más. Y la trampa de segundo nivel es que **poner `ORDER BY`
tampoco basta si la columna no es única**; hace falta que la ordenación sea total.

---

---

**02 → 5.** **¿Sobre qué opera exactamente `DISTINCT`: sobre la primera columna, sobre la fila
proyectada o sobre la fila de la tabla? 🟢**

⏱️ **30 segundos** — Sobre la fila proyectada entera, la que salió del `SELECT`. No sobre la fila de
la tabla ni sobre una columna suelta.

🗣️ **2 minutos** — `DISTINCT` es el paso 6, justo después del `SELECT`, así que solo ve lo que
proyectaste. De ahí su limitación más confundida: **no puede eliminar duplicados por una columna que
no está en la lista de salida**, y cada columna que añades a la proyección multiplica el resultado.
Sobre `pedidos`, `SELECT DISTINCT estado` da 5 filas y `SELECT DISTINCT estado, cliente_id` da 229
700: 45 940 veces más.

🔬 **El detalle** — Cuando lo que quieres es "una fila por cliente" y no "combinaciones distintas",
`DISTINCT` no es la herramienta. En PostgreSQL está `DISTINCT ON (cliente_id)`, que el manual
declara **extensión del estándar**; la alternativa portable es una función de ventana con
`row_number()`.

---

---

**02 → 6.** **Distingue "orden de escritura" de "orden de evaluación", y di si el motor está
obligado a ejecutar en el orden lógico. 🟡**

⏱️ **30 segundos** — El de escritura es `SELECT … FROM … WHERE …`, pensado para leerse; el de
evaluación es `FROM → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT`. Y no, el
motor no está obligado.

🗣️ **2 minutos** — El orden lógico define **qué resultado es el correcto**, no cómo llegar a él. El
planificador reordena lo que quiera mientras el resultado no cambie: empuja predicados por debajo de
los joins, corta una ordenación en cuanto tiene las filas del `LIMIT`, calcula agregados sobre un
índice. Lo que no puede tocar es la visibilidad de nombres: el `WHERE` nunca verá un alias del
`SELECT`, por mucho que en el plan real el filtro se aplique al mismo tiempo que la proyección.

🔬 **El detalle** — El `Sort Method: top-N heapsort` de `ORDER BY estado LIMIT 5` es exactamente esa
libertad en acción: el motor no ordena el millón de filas, mantiene cinco en 25 kB de memoria.
Semánticamente "ordenó y cortó"; físicamente hizo otra cosa. Y por eso el resultado cambia si le
quitas el atajo.

---

---

**02 → 7.** **El `ORDER BY` acepta el alias del `SELECT` y el `WHERE` no. Explica la asimetría. 🟡**

⏱️ **30 segundos** — Porque el `ORDER BY` se evalúa después del `SELECT` y el `WHERE` antes. Cuando
el `ORDER BY` corre, el alias ya existe como nombre de columna de salida.

🗣️ **2 minutos** — `SELECT total * 0.21 AS iva FROM pedidos ORDER BY iva DESC LIMIT 3` funciona y
devuelve 4547,7747 en la cabeza, en 116,940 ms. La misma expresión en el `WHERE` da `column "iva"
does not exist` en 0,882 ms, porque ni siquiera llega a ejecutarse. La asimetría no es una excepción
arbitraria del lenguaje: es la consecuencia directa de que el paso 7 va después del paso 5 y el paso
2 antes.

🔬 **El detalle** — Aquí conviene separar categorías. Que el `ORDER BY` admita nombres de la lista de
salida **sí está en SQL-92**, según las notas de compatibilidad del manual de PostgreSQL; que el
`GROUP BY` los admita también **es extensión de PostgreSQL**, porque en SQL-92 el `GROUP BY` solo
acepta nombres de columna de entrada. Es cita de segunda mano y conviene decirlo así: no he leído la
norma.

---

---

**02 → 8.** **¿El alias en el `HAVING` lo permite el estándar o depende del motor? Di qué hace cada
uno de los cuatro motores del corpus. 🟡**

⏱️ **30 segundos** — Depende del motor. PostgreSQL lo rechaza; MySQL, MariaDB y SQLite lo aceptan.

🗣️ **2 minutos** — `SELECT estado, count(*) AS n FROM pedidos GROUP BY estado HAVING n > 100000`
responde `ERROR: column "n" does not exist` en PostgreSQL 18.6, y en MySQL 9.7.2 devuelve sin
protestar los cuatro estados que superan las cien mil filas. MariaDB 12.3.3 y SQLite 3.53.4 se
comportan como MySQL. Curiosamente PostgreSQL **sí** acepta el alias en el `GROUP BY` de la misma
consulta: lo que no extiende es esa tolerancia al `HAVING`.

🔬 **El detalle** — No he verificado la cláusula de ISO/IEC 9075 para el `HAVING`, y decirlo es parte
de la respuesta. Lo que sí está documentado por PostgreSQL es el reparto de SQL-92 entre `ORDER BY`
(nombres de salida) y `GROUP BY` (nombres de entrada). Consecuencia práctica: escribe siempre
`HAVING count(*) > 100000`, que corre en los cuatro.

---

---

**02 → 9.** **`LIMIT 2, 3` y `LIMIT 3 OFFSET 2` devuelven lo mismo. ¿Cuál es la forma normalizada,
qué motores entienden cada una y cuál escribirías tú? 🟡**

⏱️ **30 segundos** — Ninguna de las dos: la normalizada es `OFFSET 2 ROWS FETCH FIRST 3 ROWS ONLY`,
de SQL:2008. Yo escribo `LIMIT 3 OFFSET 2`.

🗣️ **2 minutos** — El manual de PostgreSQL dice que `LIMIT` y `OFFSET` son sintaxis propia suya y de
MySQL, y que el estándar introdujo `OFFSET … FETCH FIRST …` para lo mismo. `LIMIT n, m` lo entienden
MySQL, MariaDB y SQLite, y PostgreSQL no. Las tres formas devuelven aquí los mismos tres pedidos,
`PED-00003` a `PED-00005`.

🔬 **El detalle** — El peligro de `LIMIT n, m` no es la portabilidad: es que **el orden de los dos
números se invierte respecto de la otra forma**. En `LIMIT 2, 3` el primero es el desplazamiento y
el segundo el tamaño; en `LIMIT 3 OFFSET 2`, al revés. Leído deprisa en una revisión de código, es
un error que no da excepción, solo datos equivocados.

---

---

**02 → 10.** **Un compañero mueve `estado <> 'ANULADO'` del `WHERE` al `HAVING` "para que quede más
limpio y sea equivalente". ¿Qué le muestras, con los números de §4? 🟠**

⏱️ **30 segundos** — Le muestro las dos consultas corridas: seis clientes con el `WHERE` quitado y
tres con el `WHERE` puesto. No es equivalente, y no por rendimiento.

🗣️ **2 minutos** — Con `GROUP BY cliente_id HAVING count(*) >= 38` sin filtrar nada salen los
clientes 1, 311, 24891, 34761, 41363 y 42075. Añadiendo `WHERE estado <> 'ANULADO'` sobreviven tres:
el 1 baja de 50 a 48, el 311 de 52 a 49 y el 34761 de 42 a 41; los otros tres caen por debajo de 38
y **desaparecen del informe**. La condición sobre `estado` no es un filtro decorativo: decide qué
filas entran en el `count(*)`.

🔬 **El detalle** — Cuál de las dos es la correcta depende de la pregunta del negocio, y las dos son
defendibles: "38 compras o más" es la primera, "38 compras **efectivas** o más" es la segunda. Lo
que no es defendible es tratarlas como sinónimos. Elegir mal no produce un error: produce un informe
que nadie audita hasta que cuadra mal con contabilidad.

---

---

**02 → 11.** **`ORDER BY estado LIMIT 5` devolvió cinco pedidos distintos en dos ejecuciones del
mismo motor sobre los mismos datos. Explica la causa y da la corrección de una línea. 🟠**

⏱️ **30 segundos** — Porque `estado` no es única: hay 60 000 pedidos empatados en `ANULADO` y el
desempate lo decide el algoritmo de ordenación. La corrección es `ORDER BY estado, id`.

🗣️ **2 minutos** — Con `LIMIT 5`, PostgreSQL usa `Sort Method: top-N heapsort Memory: 25kB` y
devuelve `PED-71382`, `PED-84001`, `PED-178323`, `PED-115603` y `PED-204227`. Envolviendo la misma
consulta en un `WITH … AS MATERIALIZED`, que le prohíbe el atajo, el plan pasa a `Sort Method:
external merge Disk: 28904kB` y devuelve `PED-108298`, `PED-345400`, `PED-407820`, `PED-60189` y
`PED-480119`. Mismo motor, mismos datos, misma cláusula `ORDER BY`.

🔬 **El detalle** — Añadir `id` hace la ordenación **total**, porque `id` es único, y a partir de ahí
el resultado deja de depender del plan. El coste es real pero pequeño: una columna más en la clave
de ordenación. El coste de no hacerlo, en una API paginada, es que la página 2 repite filas que ya
salieron en la 1 y se salta otras que nunca aparecerán.

---

---

**02 → 12.** **Justifica por qué `OFFSET 900000` es O(n) y no O(1), apoyándote en el `rows=` del
nodo hijo del plan. 🟠**

⏱️ **30 segundos** — Porque el nodo hijo dice `rows=900020.00`: el motor produjo novecientas mil
veinte filas para entregar veinte. `OFFSET` no salta, descarta.

🗣️ **2 minutos** — Los dos planes tienen exactamente la misma forma, `Limit` sobre `Index Scan using
pedidos_pkey`. Con `OFFSET 0` el `Index Scan` reporta `rows=20.00`, 23 páginas leídas y `Execution
Time: 0.432 ms`. Con `OFFSET 900000` reporta `rows=900020.00`, 902 229 páginas y `Execution Time:
631.392 ms`: **1 462 veces más tiempo** sin que cambie ni el plan ni la consulta, solo el número.

🔬 **El detalle** — La alternativa es la paginación por clave: `WHERE id > 900000 ORDER BY id LIMIT
20`, medida en la misma sesión, da 0,374 ms y 26 páginas, el mismo coste que la primera página,
porque el índice baja directo al valor. Lo que pierdes es poder saltar a una página arbitraria y
escribir "página 45 001 de 50 000". Y el aviso operativo: si tu API acepta un `OFFSET` que llega del
cliente, tienes una denegación de servicio que escribiste tú.

---

---

**02 → 13.** **Da las tres razones técnicas por las que se desaconseja `SELECT *` en código
desplegado, y di en qué caso la costumbre no aplica. 🟠**

⏱️ **30 segundos** — Contrato frágil, ancho de fila y renuncia al *index-only scan*. En una sesión
interactiva la costumbre no aplica: ahí precisamente quieres ver todo.

🗣️ **2 minutos** — El contrato: el día que alguien añade una columna a `pedidos`, la consulta
empieza a devolverla y el código que lee por posición o serializa la fila entera cambia de
comportamiento sin que nadie tocara esa línea. El ancho: sobre el mismo rango de 100 003 pedidos,
`SELECT codigo` planifica `width=10` y `SELECT *` planifica `width=57`, 5,7 veces más bytes cruzando
el motor, la red y el *driver*, con idéntico coste de lectura de páginas. Y el tercero, el que casi
nadie nombra: pedir una columna que no está en el índice obliga a bajar a la tabla y cancela el
*index-only scan*.

🔬 **El detalle** — Es **convención**, no regla de ningún motor ni del estándar, y mezcla dos
orígenes distintos que hoy se recitan juntos: el ancho de fila de los años del cable lento y el
mapeo por posición de los ORM antiguos. El argumento fuerte de hoy —el *index-only scan*— no existía
en PostgreSQL hasta la 9.2, y por eso no aparece en los hilos de foro de los que viene la costumbre.

---

---

**02 → 14.** **En la sesión de §7, el `Index Only Scan` lee las mismas 13 páginas que el `Index
Scan`. Explica por qué hoy no ahorra nada y qué tendría que pasar para que ahorrara. 🟠**

⏱️ **30 segundos** — Porque el plan dice `Heap Fetches: 10`: el *index-only scan* tuvo que visitar
la tabla igualmente. Haría falta un `VACUUM` que pusiera al día el *visibility map*.

🗣️ **2 minutos** — Un *index-only scan* solo evita bajar a la tabla si el motor sabe que la página
es visible para todas las transacciones, y eso lo dice el mapa de visibilidad, que llena `VACUUM`.
La tabla `pedidos` del laboratorio se cargó y nunca se le pasó uno, así que el mapa está vacío y las
diez filas se resuelven con diez visitas al montón. Lo que sí cambia, y es lo que hay que mirar, es
el **nodo**: `Index Only Scan` pidiendo solo `codigo`, `Index Scan` a secas pidiendo `*`.

🔬 **El detalle** — El contador que lo delata es `Heap Fetches`. Con el mapa al día baja a cero y las
13 páginas se quedan en las del índice; con el mapa sucio, un `Index Only Scan` puede ser **más
caro** que un `Index Scan`, porque hace la comprobación del mapa y además la visita. En PostgreSQL
es además el argumento de fondo para vigilar el autovacuum en tablas de solo lectura, donde nunca se
dispara por sí solo.

---

---

**02 → 15.** **`SELECT DISTINCT estado FROM pedidos ORDER BY creado_en` da error. Explícalo con el
orden lógico y escribe dos formas correctas de obtener lo que pretendía. 🟠**

⏱️ **30 segundos** — Porque el `ORDER BY` corre después del `DISTINCT`, y para entonces `creado_en`
ya no existe: el `DISTINCT` colapsó las filas a una sola columna.

🗣️ **2 minutos** — PostgreSQL lo dice literalmente: `ERROR: for SELECT DISTINCT, ORDER BY
expressions must appear in select list`. No es un capricho: si dos filas con el mismo `estado`
tenían fechas distintas y el `DISTINCT` las fundió en una, no hay una respuesta única a "¿por cuál
de las dos fechas ordeno?". Lo que la consulta pretendía, casi seguro, era "los estados ordenados
por la fecha del pedido más antiguo de cada uno", y eso es una agregación, no un `DISTINCT`.

🔬 **El detalle** — Dos formas correctas, y no son equivalentes:

```sql
-- (a) agregando: los estados por su pedido más antiguo
SELECT estado, min(creado_en) AS primero
  FROM pedidos GROUP BY estado ORDER BY primero;

-- (b) quedándote con una fila entera por estado, extensión de PostgreSQL
SELECT DISTINCT ON (estado) estado, codigo, creado_en
  FROM pedidos ORDER BY estado, creado_en, id;
```

La (a) es portable; la (b) es `DISTINCT ON`, que el manual de PostgreSQL declara extensión del
estándar, y necesita el `id` de desempate para no depender del plan.

---

---

**02 → 16.** **Escribe la consulta que da, por cada estado, los tres pedidos más antiguos, con una
ordenación total que no dependa del plan. Di qué columna usas de desempate y por qué. 🔴**

⏱️ **30 segundos** — Una función de ventana con `row_number()` particionada por estado, ordenada por
`creado_en` y desempatada por `id`, envuelta en una subconsulta que filtra `r <= 3`.

🗣️ **2 minutos** — Así, corrida contra el millón de pedidos:

```sql
SELECT estado, codigo, creado_en FROM (
  SELECT estado, codigo, creado_en,
         row_number() OVER (PARTITION BY estado ORDER BY creado_en, id) AS r
    FROM pedidos) t
 WHERE r <= 3 ORDER BY estado, r;
```

Devuelve quince filas, tres por estado: `ANULADO` abre con `PED-967963` el 2023-01-01 a las
00:07:35, `ENVIADO` con `PED-308615` a las 00:03:17 y `PENDIENTE` con `PED-896622` a las 00:02:34.
El `WHERE r <= 3` va fuera porque la ventana se evalúa después del `WHERE` de su propia consulta;
por eso hace falta el nivel extra o una CTE.

🔬 **El detalle** — El desempate es `id`, y por dos razones: es la clave primaria, así que es
**único** y hace la ordenación total, y es la columna sobre la que ya hay un índice, así que no
añade una comparación cara. `creado_en` sola no sirve: es `timestamptz` con microsegundos y aquí no
repite, pero nada en el esquema lo garantiza, y una ordenación que depende de que los datos no
empaten es una ordenación que falla el día que empatan.

---

---

**02 → 17.** **Una API pagina con `LIMIT 20 OFFSET :n` sobre `pedidos ORDER BY estado`. Enumera sus
tres fallos —uno de corrección y dos de coste— y escribe la consulta que los resuelve. 🔴**

⏱️ **30 segundos** — Corrección: `estado` no es única, así que las páginas repiten y pierden filas.
Coste: el `OFFSET` crece linealmente, y el `ORDER BY` sin índice reordena el millón en cada página.

🗣️ **2 minutos** — El primero es el grave y el invisible: con 60 000 pedidos empatados en `ANULADO`,
el desempate lo decide el plan, y entre dos peticiones puede cambiar; el usuario ve el mismo pedido
en la página 1 y en la 2, y otro no aparece nunca. El segundo está medido: `OFFSET 900000` tarda
631,392 ms contra 0,432 ms de `OFFSET 0`, 1 462 veces más, produciendo 900 020 filas para entregar
veinte. El tercero es que ordenar por una columna sin índice obliga a un `Seq Scan` más un `Sort`
completo en cada página, y el trabajo no se reutiliza entre peticiones.

🔬 **El detalle** — La consulta que los resuelve, con paginación por clave y ordenación total:

```sql
-- primera página
SELECT id, codigo, estado FROM pedidos
 ORDER BY estado, id LIMIT 20;

-- siguientes: :estado e :id son los de la última fila entregada
SELECT id, codigo, estado FROM pedidos
 WHERE (estado, id) > (:estado, :id)
 ORDER BY estado, id LIMIT 20;
```

La comparación de tuplas `(estado, id) > (:estado, :id)` es la forma correcta de "sigue por donde te
quedaste" con clave compuesta, y se apoya en un índice sobre `(estado, id)` que hoy **no existe** en
el esquema del laboratorio y habría que crear. Lo que se pierde: no hay salto a página arbitraria ni
"página 45 001 de 50 000". Si el producto exige ese contador, la respuesta honesta no es una
consulta más lista, sino que el requisito cuesta dinero.

---

---

**02 → 18.** **Diseña la comprobación que demuestre, con `EXPLAIN (ANALYZE, BUFFERS)`, que `SELECT
*` renuncia al *index-only scan*. Di qué nodo esperas en cada caso y qué contador mirarías. 🔴**

⏱️ **30 segundos** — Dos `EXPLAIN` sobre el mismo rango de `pedidos.codigo`, uno proyectando solo
`codigo` y otro con `*`. Espero `Index Only Scan` en el primero e `Index Scan` en el segundo, y miro
`Heap Fetches` y `Buffers`.

🗣️ **2 minutos** — La secuencia, tal cual se corre:

```sql
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT codigo FROM pedidos WHERE codigo BETWEEN 'PED-00040' AND 'PED-00049';

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT * FROM pedidos WHERE codigo BETWEEN 'PED-00040' AND 'PED-00049';
```

El rango se elige estrecho a propósito, diez pedidos, para que el planificador elija el índice y no
un `Seq Scan`: con un rango del 10 % de la tabla leería la tabla entera y la comparación no probaría
nada. La columna del filtro y la de la proyección son la misma, `codigo`, porque es la única
cubierta por `pedidos_codigo_key`.

🔬 **El detalle** — Medido: los dos nodos son los esperados, y los dos leen `Buffers: shared hit=13`,
con `Heap Fetches: 10` en el primero. Es decir, **el ahorro de E/S no se observa hoy**, porque la
tabla se cargó y nunca se le pasó un `VACUUM` y su *visibility map* está vacío. Para que la
comprobación mida el ahorro y no solo el cambio de nodo hay que ejecutar `VACUUM pedidos` antes y
repetir: entonces `Heap Fetches` baja a cero y las páginas del primero caen por debajo de las del
segundo. Decir esto es parte de la respuesta: un plan que enseña el nodo correcto pero no el ahorro
está incompleto, y reconocerlo vale más que enseñar un número que no se midió.

---

## Capítulo 03 — Joins

Las 20 preguntas de [`03`](03-joins.md).

**03 → 1.** **¿Qué devuelve un `INNER JOIN` y qué filas se pierden respecto de las dos tablas de
origen? 🟢**

⏱️ **30 segundos** — Devuelve una fila por cada pareja que cumple la condición del `ON`, y pierde
todas las filas sin pareja, de los dos lados.

🗣️ **2 minutos** — Lo importante es que un join no "añade columnas" a la tabla de la izquierda:
empareja. Si una fila del padre tiene tres hijas, sale tres veces; si no tiene ninguna, desaparece
del resultado. Por eso el recuento del resultado no se parece al de ninguna de las dos tablas, y
cualquier agregado que pongas encima cuenta la misma fila del padre tantas veces como parejas tenga.
Si necesitas conservar las que no emparejan, lo que quieres es un externo.

🔬 **El detalle** — Medido en el corpus: `pedidos JOIN pedido_lineas` da 3 500 000 filas sobre 1 000
000 de pedidos, en 874 ms; `pedidos JOIN pagos` da 820 000, porque 180 000 pedidos `PENDIENTE` y
`ANULADO` no tienen pago. La palabra `INNER` es opcional en PostgreSQL 18.6, MySQL 9.7.2 y SQLite
3.53.4.

---

---

**03 → 2.** **¿Qué pone un join externo en las columnas del lado que se quedó sin pareja, y de dónde
sale ese valor? 🟢**

⏱️ **30 segundos** — Pone `NULL` en todas las columnas del lado que no emparejó, y ese nulo lo
fabrica el join: no está en los datos.

🗣️ **2 minutos** — En `pedidos` no hay una fila llena de nulos esperando a `CLI-00007`; lo que hay
es ausencia de fila, y el join inventa la fila nula para poder conservar al cliente. Una vez
fabricado, ese nulo se comporta como cualquier otro: propaga desconocido en las comparaciones y no
lo cuenta `count(columna)`. Es la razón de que un predicado sobre la tabla opcional puesto en el
`WHERE` borre justo esas filas.

🔬 **El detalle** — La distinción importa al contar: sobre el mismo `LEFT JOIN`, `count(*)` contó 75
124 filas y `count(p.id)` contó 60 000, porque las 15 124 restantes son filas rellenadas. La
categoría es de modelo, no de motor: los cuatro motores del corpus rellenan igual.

---

---

**03 → 3.** **`pedidos JOIN pedido_lineas` sobre las tablas enteras devuelve 3 500 000 filas y no 1
000 000. ¿Por qué? 🟢**

⏱️ **30 segundos** — Porque cada pedido tiene 3,5 líneas de media y el join devuelve una fila por
pareja, no una por pedido.

🗣️ **2 minutos** — `pedido_id` no identifica una fila de `pedido_lineas`, identifica un grupo: la
clave de esa tabla es `(pedido_id, linea)`. Al unir, cada pedido aparece tantas veces como líneas
tenga, y el pedido de ejemplo `PED-00042` sale tres veces. El número 3 500 000 es exactamente el de
filas de `pedido_lineas`, porque toda línea tiene su pedido gracias a la foránea.

🔬 **El detalle** — Medido: 3 500 000 filas en 874 ms. La consecuencia práctica es que `sum(p.total)`
sobre ese join no da el total de la tienda sino algo unas 3,5 veces mayor, y nada avisa.

---

---

**03 → 4.** **¿Qué cliente de los 50 000 no tiene pedidos, y con qué clase de join lo encuentras?
🟢**

⏱️ **30 segundos** — `CLI-00007`, el único de los 50 000. Con un `LEFT JOIN` a `pedidos` y `p.id IS
NULL`, o mejor con `NOT EXISTS`.

🗣️ **2 minutos** — Las tres formas dan lo mismo: el join externo con `IS NULL`, el anti-join con
`NOT EXISTS` y la diferencia de conjuntos con `EXCEPT`. La que se prefiere en producción es `NOT
EXISTS`, porque expresa que no quieres ninguna columna del otro lado y deja que el motor lo ejecute
como anti-join en vez de construir todas las parejas para descartarlas después.

🔬 **El detalle** — El plan del `NOT EXISTS` da `Hash Right Anti Join`, con `rows=2349` estimadas
contra `rows=1.00` reales y 160 ms de ejecución. Esa diferencia entre estimado y real es de
estadísticas, no del resultado.

---

---

**03 → 5.** **¿Qué es un join reflexivo y qué pregunta del dominio resuelve sobre `pedido_lineas`?
🟢**

⏱️ **30 segundos** — Unir una tabla consigo misma con dos alias. En `pedido_lineas` contesta qué
pedidos repiten el mismo producto en dos líneas distintas.

🗣️ **2 minutos** — No es una clase aparte de join: por dentro es un interno o un externo, y lo único
especial es que las dos ramas son la misma tabla, así que hacen falta alias para distinguirlas.
Sirve para toda comparación entre filas de la misma tabla: duplicados, pares consecutivos, pedidos
del mismo cliente en la misma semana. La condición de desigualdad ordenada es la que evita que cada
par salga dos veces.

🔬 **El detalle** — Medido: 13 764 parejas en 1 544 ms, que corresponden a 6 855 combinaciones
`(pedido, producto)` repetidas repartidas en 6 846 pedidos distintos; nueve pedidos repiten dos
productos diferentes. Tarda lo que tarda porque `(pedido_id, producto_id)` no está indexado: la
primaria es `(pedido_id, linea)`.

---

---

**03 → 6.** **Diferencia un semi-join de un join interno: ¿qué devuelve cada uno, y cuál puede
multiplicar filas? 🟡**

⏱️ **30 segundos** — El semi-join devuelve como mucho una fila por fila de la izquierda y ninguna
columna de la derecha; el interno devuelve una por pareja y puede multiplicar.

🗣️ **2 minutos** — El semi-join contesta "¿existe al menos una pareja?" y por eso puede parar en la
primera coincidencia. El interno contesta "dame las parejas", así que tiene que producirlas todas.
En SQL el semi-join no se escribe con una palabra clave: se escribe con `EXISTS`, y es el plan el
que le pone nombre. La consecuencia práctica es que un `EXISTS` nunca necesita `DISTINCT` y un
`JOIN` contra una tabla hija casi siempre sí.

🔬 **El detalle** — Medido: `EXISTS` sobre `pedidos` devolvió 49 999 clientes en 199 ms, uno por
cliente; el interno equivalente habría producido 1 000 000 de filas. Categoría: ni el estándar ni
ninguno de los tres motores del corpus dan sintaxis propia al semi-join.

---

---

**03 → 7.** **`CROSS JOIN` y la sintaxis de coma sin condición: ¿en qué se diferencian el resultado
y el plan? 🟡**

⏱️ **30 segundos** — No se diferencian en nada salvo en la intención escrita: el mismo resultado y,
medido, el mismo plan línea por línea.

🗣️ **2 minutos** — La sintaxis de coma sin condición es un producto cartesiano igual que `CROSS
JOIN`, solo que no lo parece. Por eso es peligrosa: cuando falta una condición de unión en un `FROM`
con cinco tablas separadas por comas, lo que falta es una línea que nadie escribió, y no hay nada
que leer. `CROSS JOIN` obliga a declarar que el producto es deliberado.

🔬 **El detalle** — Medido: `EXPLAIN` de las dos formas sobre `clientes` y `productos` da el mismo
`Nested Loop (cost=0.00..3126229.50 rows=250000000 width=20)`. Leer las dos tablas cuesta 1 217
unidades estimadas y producir el resultado, 3 126 229: no se ejecutó ninguna de las dos.

---

---

**03 → 8.** **Explica en una frase por qué unir por `pagos.referencia` no empareja ninguno de los
273 126 pagos en efectivo. 🟡**

⏱️ **30 segundos** — Porque el join solo conserva las parejas cuya comparación es **verdadera**, y
`NULL = NULL` no es verdadero sino desconocido.

🗣️ **2 minutos** — No es que "no haya con quién": cada uno de esos pagos tendría al menos una pareja
obvia, él mismo. Lo que falla es la condición, que no pregunta si el contenido coincide sino si la
comparación da verdadero. Sobre nulos nunca lo da, así que la fila ni siquiera se une consigo misma.
En un interno esas filas desaparecen; en un externo sobreviven sin pareja, rellenadas con nulos.

🔬 **El detalle** — Medido: `pagos a JOIN pagos b ON a.referencia = b.referencia` con `a.metodo =
'EFECTIVO'` devolvió 0 filas en 248 ms, sobre 273 126 candidatos de 820 000. Con `IS NOT DISTINCT
FROM`, un solo pago nulo se empareja con los 273 126.

---

---

**03 → 9.** **En el reflexivo de `pedido_lineas`, ¿por qué la condición es `b.linea > a.linea` y no
`b.linea <> a.linea`? 🟡**

⏱️ **30 segundos** — Para que cada par salga una sola vez y para que una fila no se empareje consigo
misma.

🗣️ **2 minutos** — Con `<>` la condición es simétrica: la pareja (línea 1, línea 2) y la pareja
(línea 2, línea 1) la cumplen las dos, así que el resultado sale duplicado y cualquier recuento
encima vale el doble. Con `>` impones un orden dentro del par y te quedas con uno de los dos
sentidos. De paso se descarta la fila contra sí misma, que `<>` ya excluía pero `>=` no.

🔬 **El detalle** — Medido: con `>` el recorrido completo da 13 764 parejas en 1 544 ms. Es la misma
idea que hay detrás de los duplicados de cualquier reflexivo: la condición de desigualdad ordenada
es lo que convierte un producto en una comparación de pares.

---

---

**03 → 10.** **¿`FULL OUTER JOIN` lo manda el estándar o es una extensión de PostgreSQL? Di qué
motores del corpus lo tienen y desde qué versión. 🟡**

⏱️ **30 segundos** — Está en el estándar; lo que cambia es quién lo implementa. PostgreSQL 18.6 y
SQLite —desde la 3.39.0— sí; MySQL 9.7.2 y MariaDB 12.3.3, no.

🗣️ **2 minutos** — En MySQL y MariaDB no es que devuelva algo raro: es un error de sintaxis, `ERROR
1064`, con `OUTER` y sin él. El apaño portable es un `LEFT JOIN` del primer lado unido con `UNION
ALL` al anti-join del segundo, con `WHERE clave IS NULL` en el segundo brazo para no duplicar las
parejas ya emparejadas. En SQLite existe, pero sin índices adecuados es caro.

🔬 **El detalle** — **No verifiqué la cláusula de ISO/IEC 9075-2**: lo que sé es que `<joined table>`
incluye el externo completo y que los motores se comportan como está dicho, comprobado en sesión.
Medido: la conciliación da 880 000 filas en PostgreSQL y las mismas 880 000 con el apaño de `UNION
ALL` en MySQL 9.7.2; en SQLite, el `FULL` entre `clientes` y `pedidos` completo no terminó en seis
minutos y hubo que acotarlo.

---

---

**03 → 11.** **El informe de §1 multiplica el importe por cuatro al añadir un `JOIN` a
`eventos_pedido`. Explica el mecanismo, y por qué `DISTINCT` no lo arregla. 🟠**

⏱️ **30 segundos** — Porque une dos tablas hijas del mismo padre que no tienen relación entre sí, y
cada línea se empareja con cada evento del mismo pedido.

🗣️ **2 minutos** — `pedido_lineas` y `eventos_pedido` cuelgan las dos de `pedidos`, pero entre ellas
no hay ninguna condición: al unirlas en la misma consulta se produce el producto de las dos ramas
dentro de cada pedido. Con 3,5 líneas y 4,1 eventos de media, cada importe de línea aparece unas
cuatro veces y el `sum` los suma todos. Es la trampa del abanico, y se arregla agregando cada hija
por separado.

🔬 **El detalle** — Medido: 272 035,61 pasó a 1 101 161,99, y las 175 filas de la primera consulta a
706. `DISTINCT` no arregla nada porque las filas no son idénticas: difieren en la columna del
evento, así que sobreviven a la deduplicación y encima pagas la ordenación.

---

---

**03 → 12.** **Con `estado = 'ANULADO'` en el `ON` salen 50 000 clientes y en el `WHERE` 34 876.
Explica el porqué apoyándote en el orden lógico de evaluación. 🟠**

⏱️ **30 segundos** — Porque el `ON` decide qué empareja mientras el join se construye, y el `WHERE`
filtra después, sobre las filas ya rellenadas con nulos.

🗣️ **2 minutos** — En el orden lógico, primero se forma el producto y se aplica la condición del
`ON`, que decide qué parejas existen y qué filas del lado conservado salen con nulos; solo después
entra el `WHERE`. Un predicado como `p.estado = 'ANULADO'` evaluado sobre una fila rellenada compara
`NULL` con un texto y da desconocido, que no es verdadero, así que esa fila se descarta. El
resultado es un join interno escrito como externo.

🔬 **El detalle** — Medido: con el predicado en el `ON`, 75 124 filas y los 50 000 clientes; con el
predicado en el `WHERE`, 60 000 filas y 34 876 clientes. Los 15 124 que faltan son los que no tienen
ningún pedido anulado, `CLI-00007` incluido.

---

---

**03 → 13.** **El plan pasa de `Hash Right Join` a `Hash Join` entre esas dos escrituras. ¿Qué
decidió el planificador, y por qué tenía permiso para hacerlo? 🟠**

⏱️ **30 segundos** — Decidió que el externo no aporta nada y lo ejecutó como interno, y tenía
permiso porque el predicado del `WHERE` rechaza los nulos.

🗣️ **2 minutos** — El razonamiento del planificador es correcto: si toda fila rellenada con nulos va
a ser eliminada por el `WHERE`, producirlas es trabajo inútil, así que el externo se puede
reescribir como interno sin cambiar el resultado de esa consulta. El problema no es la reescritura,
es que el resultado de esa consulta ya no era el que querías. El plan es el sitio donde se ve,
porque el nombre del operador cambia.

🔬 **El detalle** — Medido: `Hash Right Join` pasa a `Hash Join`, con el mismo árbol y el mismo
`cost=1743.00..25171.91`. MySQL 9.7.2 hace lo mismo —`Nested loop left join` pasa a `Nested loop
inner join`— y su manual lo documenta como *outer join simplification*. Es comportamiento de motor
en los dos casos; no verifiqué qué dice la norma al respecto.

---

---

**03 → 14.** **¿Por qué prefieres `NOT EXISTS` a `LEFT JOIN … IS NULL` cuando solo quieres saber si
hay pareja? Apóyate en lo que dice el plan. 🟠**

⏱️ **30 segundos** — Porque `NOT EXISTS` dice lo que quieres —que no haya pareja— y deja que el
motor lo ejecute como anti-join, sin construir antes todas las parejas.

🗣️ **2 minutos** — El `LEFT JOIN … WHERE x IS NULL` da el mismo resultado, pero le pide al motor que
fabrique el join externo completo y después tire casi todo. `NOT EXISTS` le deja parar en la primera
coincidencia y elegir la estrategia. Además no multiplica filas, así que no hace falta `DISTINCT`, y
se lee como lo que es. La excepción es cuando sí quieres columnas del otro lado: entonces no es un
anti-join.

🔬 **El detalle** — Medido: el plan de `NOT EXISTS` sobre `clientes` da `Hash Right Anti Join` en 196
ms; en MySQL 9.7.2 el mismo `NOT EXISTS` da `Nested loop antijoin`. El nombre del operador aparece
en el plan aunque no aparezca en la consulta.

---

---

**03 → 15.** **Un compañero propone unir por `IS NOT DISTINCT FROM` "para no perder los nulos". ¿Qué
le preguntas antes de aprobarlo, y con qué número lo sostienes? 🟠**

⏱️ **30 segundos** — Le pregunto cuántos nulos tiene esa columna, porque ese comparador empareja
todos los nulos entre sí y el resultado explota.

🗣️ **2 minutos** — `IS NOT DISTINCT FROM` no recupera las filas perdidas: las empareja en bloque,
grupo contra grupo. Si la columna tiene muchos nulos, el join deja de ser uno a uno y se vuelve un
producto cartesiano dentro del grupo de los nulos. Antes de aprobarlo hay que decidir qué significa
el nulo: si significa "sin referencia", no hay nada que emparejar y la consulta correcta es otra; si
significa "desconocido", el modelo está mal y lo que falta es un valor centinela declarado.

🔬 **El detalle** — Medido: un solo pago con `referencia` nula se empareja con 273 126. El resultado
completo serían 273 126², más de setenta y cuatro mil millones de parejas; no se ejecutó. En MySQL
9.7.2 el equivalente es `<=>` y la forma larga da error de sintaxis; SQLite acepta las dos.

---

---

**03 → 16.** **El mismo anti-join da `Hash Right Anti Join` en PostgreSQL y `Nested loop antijoin`
en MySQL, con índices distintos. ¿Qué parte de esa diferencia es del estándar, cuál del motor y cuál
del esquema? 🟠**

⏱️ **30 segundos** — Del estándar, nada: no fija ni el algoritmo ni el plan. El operador es del
motor, y el índice que usa cada uno es del esquema.

🗣️ **2 minutos** — Los dos motores reconocen el mismo patrón lógico —el anti-join— porque `NOT
EXISTS` es SQL corriente; lo que difiere es cómo lo ejecutan y con qué estructuras. PostgreSQL elige
una tabla hash sobre `clientes` y recorre `pedidos` entero; MySQL baja por un índice por
`cliente_id` en cada iteración. Ese índice existe en MySQL porque InnoDB lo crea solo al declarar la
foránea, y no existe en PostgreSQL porque allí la foránea no indexa el lado hijo.

🔬 **El detalle** — Medido: `Hash Right Anti Join` en PostgreSQL, 160 ms; `Nested loop antijoin` en
MySQL usando `fk_pedidos_cliente`, un índice que nadie escribió en el `CREATE TABLE`. El formato del
plan también es de motor: `EXPLAIN FORMAT=TREE` es de MySQL, PostgreSQL usa `EXPLAIN` y SQLite
`EXPLAIN QUERY PLAN`.

---

---

**03 → 17.** **Escribe la consulta que da, por cliente, el número de pedidos y el importe total de
sus líneas **sin inflar ninguno de los dos**, y explica en una frase qué evita tu versión. 🔴**

⏱️ **30 segundos** — Con dos subconsultas agregadas por separado, una por cada hija, en lugar de
unir las dos ramas en el mismo `FROM`.

🗣️ **2 minutos** — La consulta que entrego es esta, y lo que evita es que el join de una rama
multiplique las filas que cuenta la otra:

```sql
SELECT cl.codigo,
       (SELECT count(*) FROM pedidos p WHERE p.cliente_id = cl.id)                    AS pedidos,
       (SELECT sum(pl.cantidad * pl.precio_unit)                                      -- importe real
          FROM pedidos p JOIN pedido_lineas pl ON pl.pedido_id = p.id
         WHERE p.cliente_id = cl.id)                                                  AS importe
  FROM clientes cl;
```

Cada subconsulta se agrega sola y devuelve un escalar, así que ninguna puede inflar a la otra. La
misma idea se escribe con dos `LEFT JOIN LATERAL` a subconsultas ya agrupadas si quieres una sola
pasada.

🔬 **El detalle** — Medido sobre `CLI-00311` y `CLI-00007`: 52 pedidos y 272 035,61 de importe el
primero, 0 pedidos e importe nulo el segundo, en 165 ms. El nulo de `CLI-00007` es correcto y
distinto de cero: no hay líneas que sumar, y si el informe necesita un cero hay que ponerlo con
`coalesce`, no fingir que la suma valía cero.

---

---

**03 → 18.** **Escribe el `FULL OUTER JOIN` de conciliación de §3 tal como lo tendrías que entregar
para MySQL 9.7.2, y justifica las dos decisiones de escritura que hacen que el recuento coincida.
🔴**

⏱️ **30 segundos** — Un `LEFT JOIN` del primer lado unido con `UNION ALL` al anti-join del segundo,
porque MySQL 9.7.2 no tiene `FULL OUTER JOIN`.

🗣️ **2 minutos** — La consulta, con las dos decisiones marcadas:

```sql
SELECT p.id AS pedido_id, pg.id AS pago_id
  FROM (SELECT id FROM pedidos WHERE estado='ANULADO') p
  LEFT JOIN pagos pg ON pg.pedido_id = p.id
UNION ALL                                        -- no UNION: no hay duplicados que quitar
SELECT p.id, pg.id
  FROM pagos pg
  LEFT JOIN (SELECT id FROM pedidos WHERE estado='ANULADO') p ON pg.pedido_id = p.id
 WHERE p.id IS NULL;                             -- solo los huérfanos del segundo lado
```

La primera decisión es `UNION ALL`: el segundo brazo solo trae filas que el primero no pudo traer,
así que deduplicar no quitaría nada y costaría ordenar 880 000 filas. La segunda es el `WHERE p.id
IS NULL`: sin él, las parejas emparejadas saldrían en los dos brazos.

🔬 **El detalle** — Medido: 880 000 filas en MySQL 9.7.2, exactamente las mismas que el `FULL OUTER
JOIN` de PostgreSQL 18.6. Escribir `FULL OUTER JOIN` en MySQL o en MariaDB 12.3.3 da `ERROR 1064`,
también sin la palabra `OUTER`.

---

---

**03 → 19.** **Te dan un informe con un `LEFT JOIN` a `pagos` y un `WHERE pg.metodo = 'TARJETA'` que
"pierde pedidos". Da el diagnóstico, la corrección y las dos consultas con las que lo demostrarías.
🔴**

⏱️ **30 segundos** — El `LEFT JOIN` está bien y el `WHERE` lo convierte en interno: el predicado
sobre `pagos` tiene que ir en el `ON`.

🗣️ **2 minutos** — El diagnóstico se dice en una frase: `pg.metodo = 'TARJETA'` evaluado sobre las
filas rellenadas con nulos da desconocido, no verdadero, así que el filtro se lleva por delante
todos los pedidos sin pago con tarjeta, que era justo lo que el informe quería conservar. La
corrección es mover el predicado al `ON`, y si además hace falta quedarse solo con los que no
pagaron con tarjeta, eso es `WHERE pg.id IS NULL` después de moverlo, que sí es un anti-join
deliberado.

🔬 **El detalle** — Las dos consultas que lo demuestran son el antes y el después, contando filas:
`SELECT count(*) FROM pedidos p LEFT JOIN pagos pg ON pg.pedido_id = p.id WHERE pg.metodo =
'TARJETA'` devuelve **273 245**, y la misma con el predicado en el `ON` devuelve **1 000 000**, es
decir, todos los pedidos. Medido, 260 y 287 ms.

---

---

**03 → 20.** **Diseña la consulta que detecta líneas repetidas por producto dentro del mismo pedido
y devuelve una sola fila por `(pedido, producto)` con la suma de cantidades. Di qué recuento
esperas, y por qué no es el número de pedidos afectados. 🔴**

⏱️ **30 segundos** — Con `GROUP BY pedido_id, producto_id` y `HAVING count(*) > 1`, no con el
reflexivo, porque el reflexivo cuenta parejas.

🗣️ **2 minutos** — La consulta que entrego es esta:

```sql
SELECT pedido_id, producto_id, sum(cantidad) AS cantidad_total, count(*) AS lineas
  FROM pedido_lineas
 GROUP BY pedido_id, producto_id
HAVING count(*) > 1;
```

Devuelve una fila por combinación repetida, que es lo que pedía el enunciado. El reflexivo sirve
para ver las líneas enfrentadas una al lado de otra —qué cantidad tiene cada una—, pero su recuento
no es comparable: produce un par por cada dos líneas que coinciden, así que un producto repetido
tres veces aporta tres pares y una sola fila aquí.

🔬 **El detalle** — Medido: la agregada devuelve **6 855** combinaciones `(pedido, producto)`
repetidas en 1 386 ms; el reflexivo devuelve **13 764** parejas, y los pedidos afectados son **6
846**, porque nueve pedidos repiten dos productos distintos. Los tres números son correctos y
responden a tres preguntas diferentes.

---

## Capítulo 04 — Agregación y subconsultas

Las 20 preguntas de [`04`](04-agregacion-y-subconsultas.md).

**04 → 1.** **¿Cuántas filas de salida produce un `GROUP BY`, y qué puede aparecer en la lista de
selección? 🟢**

⏱️ **30 segundos** — Una por grupo. Y en la lista de selección solo caben columnas de agrupación o
agregados.

🗣️ **2 minutos** — `GROUP BY` colapsa: reparte las filas en grupos según el valor de las columnas
que le das y emite una fila por grupo. Por eso cualquier otra columna suelta no tiene respuesta
única —el grupo `PAGADO` tiene 250 000 códigos distintos— y el motor no elige uno: devuelve un error
de análisis. Lo que sí puede aparecer es un agregado, que es precisamente la función que resume el
grupo en un valor.

🔬 **El detalle** — El error llega en análisis, antes de ejecutar, así que no cuesta nada: `ERROR:
column "p.codigo" must appear in the GROUP BY clause or be used in an aggregate function`. Y hay una
excepción, que es de **motor**: si la columna está funcionalmente determinada por la de agrupación,
algunos motores la admiten. PostgreSQL 18.6 solo la deduce desde la clave primaria; MySQL 9.7.2
desde cualquier candidata `NOT NULL UNIQUE`.

---

---

**04 → 2.** **Da los tres números de `count(*)`, `count(referencia)` y `count(DISTINCT referencia)`
sobre `pagos`, y di qué cuenta cada uno. 🟢**

⏱️ **30 segundos** — 820 000, 546 874 y 546 874. Filas, valores no nulos y valores no nulos
distintos.

🗣️ **2 minutos** — `count(*)` cuenta filas y no mira ninguna columna. `count(referencia)` cuenta las
filas donde esa columna tiene valor, así que se deja fuera los 273 126 pagos en efectivo, que no
traen referencia del proveedor. `count(DISTINCT referencia)` cuenta además sin repetir, y da lo
mismo que el anterior porque `pagos.referencia` es `UNIQUE` y ningún valor se repite. Si ese tercer
número fuera menor, la restricción estaría suelta.

🔬 **El detalle** — El número que descoloca es el cuarto: `SELECT DISTINCT referencia FROM pagos`
devuelve **546 875**, uno más. No hay contradicción, hay dos reglas: `SELECT DISTINCT` deduplica
**filas** y el nulo es una fila, mientras que `count(DISTINCT …)` es un agregado de columna y los
agregados de columna ignoran el nulo.

---

---

**04 → 3.** **¿Qué es una subconsulta correlacionada, y en qué parte del plan se nota? 🟢**

⏱️ **30 segundos** — La que menciona una columna de la consulta de fuera. En el plan se ve como un
`SubPlan` con `loops` mayor que 1.

🗣️ **2 minutos** — Una subconsulta no correlacionada se puede evaluar una vez y reutilizar, porque
su resultado no depende de la fila externa. Una correlacionada depende, y conceptualmente se evalúa
una vez por cada fila de fuera. El plan de PostgreSQL lo delata con el contador `loops` del nodo que
cuelga del `SubPlan`: si vale 20, ese subárbol se ejecutó veinte veces.

🔬 **El detalle** — Medido: un `max(g.pagado_en)` correlacionado sobre veinte pedidos da `loops=20` y
605,536 ms, con `Rows Removed by Filter: 819999` en cada vuelta. El mismo resultado como `LEFT JOIN`
más `GROUP BY` sale en 114,327 ms. Pero correlacionada no es sinónimo de lenta: cuando la
correlación vive en `WHERE`, el planificador la aplana a un semi-join y `loops` vuelve a 1.

---

---

**04 → 4.** **¿Cuántos pedidos sin pago hay, y en qué grupo aparecen al agrupar por `pagos.metodo`?
🟢**

⏱️ **30 segundos** — 180 000, y caen todos en el mismo grupo: el grupo nulo, el que sale sin nombre.

🗣️ **2 minutos** — Son los pedidos `PENDIENTE` —120 000— y `ANULADO` —60 000—, que por definición
del conjunto de datos no tienen pago. Al hacer `LEFT JOIN` con `pagos` y agrupar por `g.metodo`,
esas filas traen `metodo` nulo, y `GROUP BY` mete **todos los nulos en un solo grupo**. Salen cuatro
grupos: los tres métodos y ese.

🔬 **El detalle** — Es la asimetría que hay que saber contar: `GROUP BY` y `DISTINCT` tratan los
nulos como iguales entre sí, mientras que `=` los trata como incomparables. Los cuatro motores del
corpus coinciden en agrupar; el dueño del tema es `01/06`. Y el mismo 180 000 es el recuento del
anti-join de §6.

---

---

**04 → 5.** **Escribe las dos formas de contar con condición dentro de un `GROUP BY` y di cuál es
portable. 🟡**

⏱️ **30 segundos** — `count(*) FILTER (WHERE …)` y `sum(CASE WHEN … THEN 1 ELSE 0 END)`. La portable
es la del `CASE`.

🗣️ **2 minutos** — `FILTER` es la cláusula del estándar: se pega a cada agregado y le dice qué filas
del grupo mirar, así que en una misma consulta puedes tener tres agregados con tres condiciones
distintas y cada uno lleva la suya al lado. El truco del `CASE` hace lo mismo sumando unos y ceros,
y funciona en cualquier motor porque solo usa una expresión condicional. La desventaja es de
lectura: hay que recorrer el `CASE` entero para saber qué cuenta.

🔬 **El detalle** — Comprobado en los cuatro: PostgreSQL 18.6 y SQLite 3.53.4 admiten `FILTER`;
**MySQL 9.7.2 y MariaDB 12.3.3 responden `ERROR 1064 (42000)`**, ni lo reconocen como sintaxis. Las
dos escrituras dan el mismo número en PostgreSQL —264 876 / 264 836 / 265 195— y el `CASE` da esos
mismos tres en MySQL, así que la elección es de legibilidad y portabilidad, no de rendimiento.

---

---

**04 → 6.** **Diferencia `WHERE` de `HAVING` diciendo sobre qué actúa cada uno. 🟡**

⏱️ **30 segundos** — `WHERE` decide qué filas entran al agregado; `HAVING`, qué grupos salen de él.

🗣️ **2 minutos** — La frase de manual —*"`HAVING` es el `WHERE` de los grupos"*— es cierta y se
queda corta, porque hace pensar que solo cambia el rendimiento. Cambia el resultado: `WHERE` actúa
antes de agrupar, sobre filas individuales, y `HAVING` después, sobre el valor ya agregado de cada
grupo. Por eso `HAVING` es el único sitio donde puedes poner una condición sobre un agregado, y
`WHERE` el único donde puedes filtrar por una columna que no está agrupada.

🔬 **El detalle** — Medido sobre `pagos`: `WHERE importe > 5000` da medias de 7726,29 / 7734,48 /
7733,31 sobre 131 426 / 131 668 / 131 940 pagos, y `HAVING avg(importe) > 5000` da 5171,35 / 5178,11
/ 5182,74 sobre los 273 126 / 273 245 / 273 629 de siempre. Mismos tres grupos, otras preguntas. Y
`HAVING` sin `GROUP BY` trata la tabla como un grupo único: devuelve una fila o ninguna.

---

---

**04 → 7.** **¿Por qué `count(DISTINCT referencia)` da 546 874 y `SELECT DISTINCT referencia` da 546
875? 🟡**

⏱️ **30 segundos** — Porque el agregado ignora el nulo y la deduplicación lo cuenta como una fila
más.

🗣️ **2 minutos** — `count(DISTINCT referencia)` es un agregado de columna, y los agregados de
columna descartan los nulos antes de contar: cuenta los 546 874 valores reales. `SELECT DISTINCT
referencia` no es un agregado, es deduplicación de filas, y ahí los 273 126 nulos se comportan como
en `GROUP BY` —se juntan todos en uno— y aportan **una** fila al resultado. De ahí el `+1` exacto.

🔬 **El detalle** — El `+1` es exacto justo porque hay nulos: si la columna fuera `NOT NULL`, los dos
números coincidirían. Es la misma asimetría de `01/06`: el nulo desaparece en los agregados de
columna, se junta consigo mismo en agrupación y deduplicación, y en ordenación depende del motor.
Tres reglas distintas, no una. Coste medido: unos 111 ms el trío de `COUNT` contra unos 125 el
`SELECT DISTINCT` envuelto.

---

---

**04 → 8.** **`EXISTS` e `IN` afirmativos, ¿dan el mismo plan en PostgreSQL 18.6? Di el nodo y los
tiempos. 🟡**

⏱️ **30 segundos** — Sí, el mismo: `Hash Semi Join` los dos. 503,821 ms con `EXISTS` y 572,838 ms
con `IN`.

🗣️ **2 minutos** — Los dos planes salen idénticos nodo a nodo: `Hash Semi Join` con `Hash Cond:
(p.id = g.pedido_id)`, `Seq Scan` sobre `pedidos` del lado sondeo y `Hash` de 820 000 filas en
cuatro lotes con 12 115 kB. Los 69 ms de diferencia son ruido entre corridas, no una propiedad de la
escritura: el árbol es el mismo. Lo que hay en el plan no es una subconsulta: es un semi-join, que
es el operador del álgebra para *"la fila izquierda si existe alguna derecha que empareje"*.

🔬 **El detalle** — Eso desmonta la convención *"`EXISTS` siempre es más rápido que `IN`"*, que viene
de los Oracle y SQL Server de hace veinte años y se sigue recitando. La diferencia de verdad aparece
en la forma negativa: `NOT EXISTS` da `Hash Anti Join` en 459,781 ms y `NOT IN` cae en `Materialize`
más bucle anidado, con coste estimado 12 893 024 520 y sin terminar en 3 min 23 s.

---

---

**04 → 9.** **¿Qué significa que `EXISTS` sea un semi-join, y en qué se distingue de un `JOIN`? 🟡**

⏱️ **30 segundos** — Que devuelve la fila izquierda **una vez**, haya una coincidencia o mil. El
`JOIN` devuelve el producto.

🗣️ **2 minutos** — Un semi-join es la operación *"existe al menos una"*: no trae columnas del lado
derecho ni multiplica filas, solo filtra el izquierdo. Un `JOIN` sí emite una fila por cada par que
empareja, así que si la tabla derecha tiene varias filas por clave, la izquierda se repite y todos
los agregados sobre ella quedan inflados. Por eso `EXISTS` e `IN` son intercambiables entre sí y no
siempre con `JOIN`.

🔬 **El detalle** — El número del capítulo: `pedidos JOIN pedido_lineas` con `estado='PAGADO'` da 874
913 filas y `sum(p.total)` 5 356 879 029,63; con `WHERE EXISTS (…)` son 250 000 filas y 1 292 915
896,63. Un 314 % de inflación. Hoy `pagos` no multiplica porque ningún pedido tiene dos pagos
—`GROUP BY pedido_id HAVING count(*) > 1` devuelve `0`—, pero **nada lo impide: `pagos.pedido_id` no
es `UNIQUE`**.

---

---

**04 → 10.** **`count(*) FILTER (WHERE …)`: ¿lo fija el estándar, y qué motores del corpus lo
admiten? 🟡**

⏱️ **30 segundos** — Sí, es del estándar —`<filter clause>`—, y lo admiten PostgreSQL y SQLite;
MySQL y MariaDB no.

🗣️ **2 minutos** — En los cuatro motores del corpus, PostgreSQL 18.6 y SQLite 3.53.4 lo aceptan, y
MySQL 9.7.2 y MariaDB 12.3.3 responden `ERROR 1064 (42000)`: no es que lo ignoren, es que ni
siquiera lo reconocen como sintaxis. Ahí la única escritura disponible es `sum(CASE WHEN … THEN 1
ELSE 0 END)`, que da exactamente los mismos números.

🔬 **El detalle** — **No he verificado la cláusula concreta de ISO/IEC 9075-2**: el estándar es de
pago. Lo que sí está comprobado en sesión es qué hace cada motor, y `FILTER` es de los pocos sitios
donde SQLite va por delante de MySQL en cobertura del estándar. Es un buen ejemplo de por qué *"esto
es SQL estándar"* no garantiza nada sobre si tu motor lo entiende.

---

---

**04 → 11.** **`HAVING media > 5000` funciona en MySQL y falla en PostgreSQL. ¿Estándar o motor, y
por qué? 🟠**

⏱️ **30 segundos** — Es de **motor**. El orden lógico dice que `HAVING` se evalúa antes que
`SELECT`, así que el alias todavía no existe.

🗣️ **2 minutos** — `FROM`, `WHERE`, `GROUP BY`, `HAVING`, `SELECT`, `ORDER BY`: cuando se evalúa
`HAVING`, la lista de selección aún no se ha proyectado y el nombre `media` no está definido.
PostgreSQL es estricto con eso y responde `ERROR: column "media" does not exist`. MySQL 9.7.2,
MariaDB 12.3.3 y SQLite 3.53.4 resuelven el identificador contra la lista de selección como
extensión propia, y funciona.

🔬 **El detalle** — El contraste con `ORDER BY` es lo que sube la nota: ahí **sí** puedes usar el
alias en los cuatro, porque `ORDER BY` se evalúa después de `SELECT`. O sea que el mismo nombre es
válido en una cláusula e inválido en la otra, y el orden lógico lo explica entero. La escritura
portable es repetir la expresión: `HAVING avg(importe) > 5000`.

---

---

**04 → 12.** **El informe de §1 da 874 913 filas y una suma inflada un 314 %. Explica el mecanismo y
da dos correcciones distintas. 🟠**

⏱️ **30 segundos** — El `JOIN` trae una fila por línea de pedido, así que `sum(p.total)` suma el
mismo total una vez por línea.

🗣️ **2 minutos** — Hay 250 000 pedidos `PAGADO` y unas 3,5 líneas por pedido, de ahí las 874 913
filas. Cada una lleva el `total` del pedido repetido, y la suma lo cuenta tantas veces como líneas.
No hay error ni aviso: la consulta es válida, solo responde a otra pregunta. La primera corrección
es dejar de unir y preguntar solo por existencia, con `WHERE EXISTS (SELECT 1 FROM pedido_lineas l
WHERE l.pedido_id = p.id)`; la segunda es agregar el lado que multiplica por separado, en una
subconsulta o CTE que devuelva una fila por pedido, y unir contra eso.

🔬 **El detalle** — La corrección que **no** vale es `DISTINCT`: arregla el recuento y deja la suma
mal, porque dos pedidos distintos pueden tener el mismo total y `SELECT DISTINCT` los colapsaría, o
`sum(DISTINCT p.total)` se comería los repetidos legítimos. El diagnóstico general: si `count(*)`
del `JOIN` supera al `count(*)` de la tabla izquierda, todos los agregados de la izquierda están
inflados.

---

---

**04 → 13.** **Agrupando por `pedidos.codigo`, PostgreSQL rechaza `p.id` y MySQL lo devuelve.
Explica de dónde sale la diferencia y si alguno de los dos incumple algo. 🟠**

⏱️ **30 segundos** — De hasta dónde llega el análisis de dependencia funcional de cada motor.
Ninguno incumple nada verificable.

🗣️ **2 minutos** — `pedidos.codigo` es `NOT NULL UNIQUE`, o sea clave candidata: agrupando por él,
`p.id` tiene un solo valor posible por grupo, así que la consulta tiene sentido. PostgreSQL 18.6
solo hace esa deducción **desde la clave primaria** —con `GROUP BY p.id` sí te deja sacar
`p.codigo`— y por eso aquí falla. MySQL 9.7.2, con `ONLY_FULL_GROUP_BY` activo, la hace desde
**cualquier candidata `NOT NULL UNIQUE`** y devuelve la fila. MySQL no está siendo laxo: está
analizando más.

🔬 **El detalle** — Que MySQL sí rechaza lo indeducible se comprueba enseguida: `GROUP BY p.estado`
con `p.codigo` suelto responde `ERROR 1055 (42000) … which is not functionally dependent on columns
in GROUP BY clause`. Y los otros dos motores no analizan: MariaDB 12.3.3 no trae
`ONLY_FULL_GROUP_BY` en su `sql_mode` por defecto y SQLite 3.53.4 nunca lo ha hecho; los dos
devuelven un valor arbitrario del grupo sin avisar. **No he verificado la cláusula de ISO/IEC 9075**
que regula esto; lo afirmado es lo medido en los cuatro motores.

---

---

**04 → 14.** **`NOT IN` sobre `pagos.referencia` da 0 y `NOT EXISTS` da 820 000. ¿Cuál responde a la
pregunta, y por qué el otro no da ningún error? 🟠**

⏱️ **30 segundos** — Responde `NOT EXISTS`, con 820 000. El `NOT IN` no falla: se queda en
desconocido y `WHERE` tira todas las filas.

🗣️ **2 minutos** — Los 273 126 pagos en efectivo no tienen `referencia`, así que la subconsulta
devuelve una lista con nulos dentro. `NOT IN` se expande a una cadena de `<>` unida por `AND`, y
basta una comparación contra nulo para que la conjunción no pueda ser verdadera nunca: como mucho
llega a desconocido, y `WHERE` descarta desconocido igual que falso. De ahí el cero. `NOT EXISTS` no
compara la fila contra una lista: pregunta si existe alguna fila que empareje, y como ninguna
referencia nula empareja con nada, el anti-join deja pasar las 820 000.

🔬 **El detalle** — La regla operativa: **`NOT IN` sobre subconsulta solo es seguro si la columna
interna es `NOT NULL` y puedes demostrarlo desde el catálogo**, no porque hoy no haya nulos. En `IN`
afirmativo el nulo no hace daño, porque a `IN` le basta un acierto para dar verdadero. El dueño de
la lógica de tres valores es `01/06`.

---

---

**04 → 15.** **¿Por qué el mismo `NOT IN` no termina con `work_mem` de 8 MB y tarda 587 ms con 64
MB? Nombra el nodo que cambia. 🟠**

⏱️ **30 segundos** — Porque con 8 MB la lista no cabe en una tabla hash y PostgreSQL cae en un bucle
anidado sobre un `Materialize`.

🗣️ **2 minutos** — Con `work_mem` en 8 MB el plan es `Seq Scan` sobre `pedidos` con `Filter: (NOT
(ANY (id = (SubPlan 1).col1)))` alimentado por un `Materialize` de 820 000 filas: un millón de filas
externas contra 820 000 materializadas, coste estimado 12 893 024 520. La cancelé a los 3 min 23 s.
Con `SET work_mem = '64MB'` las 820 000 claves caben en memoria y el nodo pasa a `(hashed SubPlan
1)`: mismas 180 000 filas en 587,898 ms.

🔬 **El detalle** — El nodo que cambia es ese: `SubPlan 1` con `Materialize` frente a `hashed SubPlan
1`. Es **de motor**, no del estándar, y conviene decirlo así en entrevista. MySQL 9.7.2 no tiene ese
acantilado porque reescribe el `NOT IN` a `Nested loop antijoin` sobre un `Materialize with
deduplication` con clave automática, y responde en 1,686 s de reloj. Aun así no lo escribirías: el
problema semántico de los nulos sigue ahí.

---

---

**04 → 16.** **La media por método sale 7726,29 con `WHERE` y 5171,35 con `HAVING`. Di cuál responde
a *"media de los pagos grandes"* y cuál a *"métodos cuya media es grande"*. 🟠**

⏱️ **30 segundos** — La de `WHERE` responde a *"media de los pagos grandes"*; la de `HAVING`, a
*"métodos cuya media es grande"*.

🗣️ **2 minutos** — `WHERE importe > 5000` descarta las filas pequeñas **antes** de agregar, así que
la media se calcula solo sobre los 131 426 pagos grandes de efectivo y sale 7726,29. `HAVING
avg(importe) > 5000` agrega primero los 273 126 pagos del método, obtiene 5171,35, y después decide
si el grupo se queda. Son dos preguntas distintas y las dos son legítimas; lo que no es legítimo es
elegir la cláusula por costumbre.

🔬 **El detalle** — El precio también difiere aunque aquí se note poco —86 contra 121 ms: sin índice
en `importe` las dos leen las 820 000 filas, y la de `WHERE` solo agrupa las que pasan el filtro—.
Con un índice utilizable, la condición en `WHERE` descarta antes de agrupar y la de `HAVING` no
puede: lo que cabía en `WHERE` y se filtró en `HAVING` se paga entero. La regla: condición sobre
fila, `WHERE`; condición sobre agregado, `HAVING`.

---

---

**04 → 17.** **Escribe la consulta que dé, por estado de pedido, el número de pedidos y el importe
total cobrado, sin que desaparezca ningún pedido sin pago y sin inflar ninguna suma. 🔴**

⏱️ **30 segundos** — `LEFT JOIN` con `pagos`, `count(DISTINCT p.id)` para los pedidos y
`sum(g.importe)` con `coalesce` para lo cobrado.

🗣️ **2 minutos** — El `LEFT JOIN` es lo que impide que desaparezcan los 180 000 pedidos sin pago:
con `JOIN` interno, `PENDIENTE` y `ANULADO` no saldrían en el informe. `count(DISTINCT p.id)` cuenta
pedidos y no filas, así que sigue siendo correcto el día que un pedido tenga dos pagos; `count(*)`
valdría hoy y mentiría mañana. Y `coalesce` convierte el nulo de los grupos sin pago en un cero
presentable, porque `sum` sobre un grupo entero de nulos devuelve nulo, no cero.

🔬 **El detalle** — La consulta entera, con el comentario que explica cada decisión:

```sql
-- Una fila por estado; ningún pedido desaparece y ninguna suma se infla.
SELECT p.estado,
       count(DISTINCT p.id)                        AS pedidos,
       round(coalesce(sum(g.importe), 0), 2)       AS cobrado
  FROM pedidos p
  LEFT JOIN pagos g ON g.pedido_id = p.id
 GROUP BY p.estado
 ORDER BY p.estado;
```

Corrido, da `ANULADO 60000 | 0.00`, `ENTREGADO 300000 | 1553913951.25`, `ENVIADO 270000 |
1398641108.28`, `PAGADO 250000 | 1292915896.63` y `PENDIENTE 120000 | 0.00`, en 1455,101 ms. El
`PAGADO` coincide con la cifra buena de §1, que es la comprobación de que el informe original estaba
inflado.

---

---

**04 → 18.** **Un informe une `pedidos` con `pedido_lineas` y con `pagos` a la vez y suma `p.total`.
Da tres hipótesis del número inflado en orden de probabilidad, y la consulta que confirma cada una.
🔴**

⏱️ **30 segundos** — Multiplicación por `pedido_lineas`, multiplicación por `pagos`, y las dos a la
vez multiplicándose entre sí.

🗣️ **2 minutos** — En orden de probabilidad: **una**, `pedido_lineas` tiene 3,5 filas por pedido y
es la causa casi segura; **dos**, algún pedido tiene más de un pago y `pagos` también multiplica;
**tres**, si las dos multiplican, el resultado es el producto de las dos cardinalidades, no la suma,
y la inflación se dispara. La tercera es la que explica los números absurdos, del tipo *"facturamos
diez veces el PIB"*.

🔬 **El detalle** — Cada una se confirma contando antes de sumar:

```sql
-- 1. ¿Multiplica pedido_lineas? Compara con las 250 000 de pedidos PAGADO.
SELECT count(*) FROM pedidos p JOIN pedido_lineas l ON l.pedido_id = p.id
 WHERE p.estado = 'PAGADO';
-- 2. ¿Hay pedidos con más de un pago?
SELECT count(*) FROM (SELECT pedido_id FROM pagos GROUP BY pedido_id HAVING count(*) > 1) t;
-- 3. ¿Cuánto multiplica cada lado por separado?
SELECT avg(n) FROM (SELECT count(*) AS n FROM pedido_lineas GROUP BY pedido_id) t;
```

Hoy la primera da 874 913 y la segunda `0`, así que la causa es solo `pedido_lineas`. La corrección
es agregar cada lado por separado —una subconsulta o CTE que devuelva una fila por pedido— y unir
contra eso, o pasar a `EXISTS` si lo único que hacía falta era descartar pedidos vacíos.

---

---

**04 → 19.** **Escribe la comprobación previa a un despliegue que detecte los `NOT IN` peligrosos de
un repositorio: qué buscas, qué descartas, y qué consulta del catálogo decide si la columna interna
es anulable. 🔴**

⏱️ **30 segundos** — Buscar todo `NOT IN (` seguido de un `SELECT`, descartar las listas literales,
y comprobar en `information_schema` si la columna interna admite nulos.

🗣️ **2 minutos** — Lo que se busca no es cualquier `NOT IN`: es el `NOT IN` sobre **subconsulta**,
porque el de lista literal es visible y tú controlas sus valores. De cada uno se saca la columna
proyectada por la subconsulta y se consulta el catálogo: si es anulable, la consulta puede devolver
cero filas en silencio en cuanto alguien inserte un nulo, aunque hoy no haya ninguno. Lo que **no**
vale como prueba es `SELECT count(*) WHERE col IS NULL` dando cero: eso es el dato de hoy, no la
garantía.

🔬 **El detalle** — La comprobación, en dos piezas:

```bash
# Los NOT IN sobre subconsulta del repositorio; el NOT IN de lista literal no entra.
grep -rniE 'not[[:space:]]+in[[:space:]]*\([[:space:]]*select' --include='*.sql' --include='*.java' .
```

```sql
-- Para cada columna sospechosa: ¿la declara el esquema como anulable?
SELECT table_name, column_name, is_nullable
  FROM information_schema.columns
 WHERE table_schema = 'public' AND is_nullable = 'YES'
 ORDER BY table_name, column_name;
```

Hoy `pagos.referencia` sale con `YES` y 273 126 nulos, y `pedidos.actualizado_en` con `YES` y un
millón. La corrección es `NOT EXISTS`, que además evita el acantilado de `work_mem` del `NOT IN` en
PostgreSQL. Y la regla que se lleva el equipo: un `NOT IN` sobre subconsulta necesita un `NOT NULL`
declarado detrás, no un recuento.

---

---

**04 → 20.** **El último pago de cada uno de los 1000 pedidos de un informe tarda minutos con
subconsulta correlacionada. Escribe la reescritura con agregación, di qué gana, y nombra la familia
de funciones que resolvería *"y además el importe de ese pago"*, que `GROUP BY` no resuelve. 🔴**

⏱️ **30 segundos** — Un `LEFT JOIN` con `GROUP BY` y `max(g.pagado_en)`, que lee `pagos` una vez en
vez de mil. La variante con el importe la resuelven las funciones de ventana.

🗣️ **2 minutos** — La correlacionada se evalúa una vez por fila externa: con veinte pedidos ya son
`loops=20`, veinte recorridos secuenciales completos de `pagos` y 605,536 ms; con mil, mil
recorridos. Reescrita con agregación, el motor lee `pagos` una sola vez y reparte por grupo, y los
mismos veinte pedidos salen en 114,327 ms sobre un `Hash Right Join`. Lo que gana no es un
porcentaje: es pasar de coste lineal en el número de filas externas a coste constante en ese factor.

🔬 **El detalle** — La reescritura:

```sql
-- Una pasada por pagos, un grupo por pedido.
SELECT p.codigo, max(g.pagado_en) AS ultimo
  FROM pedidos p
  LEFT JOIN pagos g ON g.pedido_id = p.id
 WHERE p.codigo BETWEEN 'PED-00040' AND 'PED-00059'
 GROUP BY p.codigo;
```

La variante *"y además el importe de ese pago"* ya no la resuelve `GROUP BY`: `max(g.pagado_en)` y
`max(g.importe)` pueden venir de filas distintas, y pedir `g.importe` suelto es justo el error de la
columna no agrupada. Eso es terreno de las **funciones de ventana** —`ROW_NUMBER` particionado por
`pedido_id` y ordenado por `pagado_en DESC`, quedándote con la primera—, que tienen su capítulo
propio en este bloque.

---

---

## Capítulo 05 — CTE y recursión

Las 16 preguntas de [`05`](05-cte-y-recursion.md).

**05 → 1.** ¿Qué es una CTE y qué crea en disco? 🟢

⏱️ **30 segundos** — Es una subconsulta con nombre, declarada en un `WITH` delante de la consulta
que la usa. No crea nada en disco: vive y muere con la sentencia.

🗣️ **2 minutos** — El nombre solo existe dentro de esa sentencia, así que no hay DDL, ni catálogo,
ni permisos que gestionar, ni nada que borrar después. Lo que compra es legibilidad y poder nombrar
un resultado intermedio varias veces sin repetir el SQL. Lo que cuesta depende de cómo decida el
motor evaluarla: si la integra con la consulta de fuera no cuesta nada extra, y si la materializa
paga un búfer de memoria o de disco temporal.

🔬 **El detalle** — Que no cree nada en disco no significa que no escriba en disco: cuando PostgreSQL
materializa, el resultado puede desbordar a fichero temporal. En el ejemplo del capítulo, `Storage:
Disk Maximum Storage: 47968kB` — 47 MB — para una CTE que devuelve una fila útil. Es de motor; no he
verificado qué manda ISO/IEC 9075 al respecto.

---

**05 → 2.** Nombra las dos mitades de una CTE recursiva y di cuál se menciona a sí misma. 🟢

⏱️ **30 segundos** — El término base y el término recursivo. El que se menciona a sí mismo es el
recursivo; el base es el que arranca y no se nombra.

🗣️ **2 minutos** — Van unidos por `UNION` o `UNION ALL`, con el base primero. El base produce las
filas de arranque —la raíz del árbol, el primer día del calendario—. El recursivo hace un `JOIN`
contra el nombre de la propia CTE y se alimenta **solo de las filas nuevas** de la vuelta anterior,
no del acumulado. El motor repite el término recursivo hasta que una vuelta devuelve cero filas.

🔬 **El detalle** — Que reciba solo las filas nuevas es lo que hace que sea un bucle y no una función
recursiva, y explica por qué un `count(*)` dentro del término recursivo no ve el total acumulado. La
palabra `RECURSIVE` la exigen PostgreSQL 18.6 y MySQL 9.7.2; SQLite 3.53.4 la acepta pero no la
pide.

---

**05 → 3.** ¿Cuándo deja de iterar una CTE recursiva? 🟢

⏱️ **30 segundos** — Cuando el término recursivo devuelve cero filas en una vuelta. Si nunca las
devuelve, no para.

🗣️ **2 minutos** — Lo normal es que pare porque se acabó el árbol —ningún hijo más que enganchar— o
porque una condición de parada explícita, del tipo `WHERE dia < DATE '2024-03-24'`, dejó de
cumplirse. Con un ciclo en los datos, en cambio, cada vuelta vuelve a producir filas y la consulta
crece hasta llenar el disco temporal. Las dos defensas son `UNION` en vez de `UNION ALL`, que
descarta las filas repetidas, y un contador de profundidad con `WHERE nivel < N`.

🔬 **El detalle** — No hay tope por defecto en PostgreSQL 18.6 ni en SQLite 3.53.4: lo que corta es
el `statement_timeout` o el disco. MySQL 9.7.2 sí lo tiene, `cte_max_recursion_depth = 1000`, y
aborta con `ERROR 3636 (HY000): Recursive query aborted after 1001 iterations`. MariaDB 12.3.3 hace
lo mismo con `max_recursive_iterations`. Es de motor, no de estándar.

---

**05 → 4.** En el informe de §1 se piden siete días y sale uno: ¿por qué, y de dónde salen los otros
seis? 🟢

⏱️ **30 segundos** — Porque `GROUP BY` solo agrupa filas que existen, y seis de esos días no tienen
ningún pedido. Los otros seis tienen que generarse: no están en ninguna tabla.

🗣️ **2 minutos** — Es el error clásico del informe con huecos. El `GROUP BY` es correcto, lo que
falta es el eje temporal. La solución es producir el calendario —con `generate_series` en PostgreSQL
o con una CTE recursiva si tiene que ser portable— y colgarle las ventas con un `LEFT JOIN` que vaya
del calendario hacia `pedidos`. Todas las condiciones del filtro tienen que ir en el `ON`, no en un
`WHERE`, o los días vacíos se vuelven a caer.

🔬 **El detalle** — Medido: el cliente `CLI-00311` tiene 52 pedidos repartidos en los 1 000 días que
cubre la tabla, así que la densidad es de un pedido cada 19 días y los huecos son la norma. Con el
calendario, el informe devuelve las siete filas y `count(p.id)` da 0 —no 1— en los seis días vacíos,
porque cuenta emparejamientos y no renglones del resultado.

---

**05 → 5.** Distingue `MATERIALIZED` de `NOT MATERIALIZED`: ¿cuál prohíbe qué? 🟡

⏱️ **30 segundos** — `MATERIALIZED` prohíbe integrar: obliga a evaluar la CTE aparte. `NOT
MATERIALIZED` prohíbe lo contrario: obliga a fundirla con la consulta de fuera.

🗣️ **2 minutos** — Lo importante es entender qué se gana y qué se pierde con cada prohibición.
Materializada, la CTE se evalúa una sola vez aunque se nombre diez, pero el motor ya no puede
empujar los filtros de fuera hacia dentro, así que un `WHERE` selectivo se aplica después de haber
leído todo. Integrada, el filtro entra y puede acabar en un `Index Cond`, pero si la CTE se nombra
varias veces el cálculo se repite tantas veces como aparezca el nombre.

🔬 **El detalle** — Las dos existen en PostgreSQL desde la 12 y en SQLite 3.53.4. MySQL 9.7.2 no
tiene ninguna de las dos: `WITH p AS MATERIALIZED (…)` responde `ERROR 1064` de sintaxis. Es de
motor.

---

**05 → 6.** ¿Qué tres condiciones exige PostgreSQL 12 para integrar una CTE? Señala la que más se
olvida. 🟡

⏱️ **30 segundos** — Que no sea recursiva, que no tenga efectos secundarios y que se referencie una
sola vez. La que más se olvida es la tercera.

🗣️ **2 minutos** — "Sin efectos secundarios" quiere decir que no contenga `INSERT`, `UPDATE`,
`DELETE` ni funciones volátiles: si los tuviera, integrarla cambiaría cuántas veces se ejecutan. La
de la referencia única es la que descoloca a la gente que ya se aprendió el cambio de la 12: dan por
hecho que "ahora las CTE se integran" y no es así en cuanto el nombre aparece dos veces, que es
justamente el caso en el que uno escribe una CTE. Y ahí materializar suele ser lo correcto.

🔬 **El detalle** — `NOT MATERIALIZED` levanta la tercera condición, no las otras dos: una CTE
recursiva no se integra aunque se lo pidas. Medido sobre la CTE `por_estado`, que se nombra dos
veces: 132,168 ms materializada por defecto contra 238,399 ms forzando `NOT MATERIALIZED`, porque el
`Seq Scan` del millón de pedidos se corre dos veces.

---

**05 → 7.** ¿`RECURSIVE` es obligatoria por estándar o por motor? Di qué hace cada uno de los tres.
🟡

⏱️ **30 segundos** — Por motor: no es uniforme. PostgreSQL 18.6 y MySQL 9.7.2 la exigen; SQLite
3.53.4 no, la acepta pero la recursión funciona sin ella.

🗣️ **2 minutos** — No he verificado la cláusula de ISO/IEC 9075, así que lo que puedo afirmar es lo
que hacen los motores, comprobado en sesión. PostgreSQL falla con `ERROR: relation "s" does not
exist` y encima sugiere la corrección: *"Use WITH RECURSIVE, or re-order the WITH items"*. MySQL
falla más feo, con `ERROR 1146 … Table 'tienda.s' doesn't exist`, porque busca una tabla de verdad
con ese nombre. MariaDB 12.3.3 da exactamente el mismo `ERROR 1146`.

🔬 **El detalle** — La lección es de diagnóstico: en MySQL, un *"table doesn't exist"* sobre un
nombre que tú acabas de declarar en un `WITH` casi siempre es un `RECURSIVE` que falta. Y escribir
`RECURSIVE` siempre que haya autorreferencia es portable: SQLite no protesta por tenerla de más.

---

**05 → 8.** En §3, ¿por qué el filtro del cliente va en el `ON` y no en el `WHERE`? 🟡

⏱️ **30 segundos** — Porque en el `WHERE` se aplicaría después del `LEFT JOIN` y tiraría las filas
de los días sin pedidos, que es justo lo que el informe quiere conservar.

🗣️ **2 minutos** — En un `LEFT JOIN`, las filas de la tabla izquierda que no emparejan salen con
nulos en las columnas de la derecha. Un `WHERE p.cliente_id = …` evalúa ese nulo como desconocido,
la fila no pasa el filtro y el día vacío desaparece: el informe vuelve a tener una sola fila. Puesto
en el `ON`, la condición decide qué empareja, no qué sobrevive, y el día vacío se conserva con su
cero. Es el mismo motivo por el que el rango de fechas también va en el `ON`.

🔬 **El detalle** — La única excepción útil es `WHERE p.id IS NULL`, que es deliberadamente un
anti-join y sirve para listar solo los días sin ventas. Y en la proyección hay que usar
`count(p.id)`, no `count(*)`: `count(*)` cuenta renglones del resultado y daría 1 en cada día vacío.

---

**05 → 9.** Que una recursión descontrolada se corte sola, ¿es del estándar o del motor? Di qué hace
cada uno. 🟠

⏱️ **30 segundos** — Es del motor, y no lo hacen todos. MySQL corta a las 1 000 vueltas; PostgreSQL
y SQLite no cortan nunca.

🗣️ **2 minutos** — MySQL 9.7.2 trae `cte_max_recursion_depth` con valor 1 000 y aborta con `ERROR
3636`, sugiriendo subirlo. MariaDB 12.3.3 hace lo mismo con `max_recursive_iterations`, también en 1
000. PostgreSQL 18.6 y SQLite 3.53.4 no tienen tope: la consulta crece hasta agotar el disco
temporal. En PostgreSQL, lo que en la práctica te salva es el `statement_timeout`, y por eso
conviene tenerlo puesto en la aplicación aunque nunca pienses en recursión.

🔬 **El detalle** — El tope de MySQL es una red de seguridad, no una defensa: si tu jerarquía tiene
más de 1 000 niveles legítimos, la consulta correcta también falla. La defensa de verdad está en el
SQL —`UNION`, o un contador de profundidad— y el tope solo evita que el incidente sea un disco
lleno. No he verificado si ISO/IEC 9075 dice algo sobre esto.

---

**05 → 10.** Alguien añade `MATERIALIZED` a todas las CTE "para que el plan sea estable". Dale el
argumento de coste, con los números de §2. 🟠

⏱️ **30 segundos** — Que materializar no estabiliza nada: prohíbe empujar el filtro dentro. En el
ejemplo del capítulo eso convierte 0,136 ms en 283,995 ms.

🗣️ **2 minutos** — El mismo `WITH p AS (SELECT … FROM pedidos) SELECT … WHERE codigo = 'PED-00042'`
sin la palabra da un `Index Scan using pedidos_codigo_key`, cuatro páginas leídas y 0,136 ms de
ejecución. Con `MATERIALIZED` da un `CTE Scan` sobre un `Seq Scan` del millón de filas, con `Rows
Removed by Filter: 999999`, 10 770 páginas y 283,995 ms: 2 088 veces más lento. Y además escribe 47
MB en un fichero temporal para quedarse con una fila. Lo que él llama "estabilidad" es tener siempre
el peor plan.

🔬 **El detalle** — De dónde viene la costumbre: hasta PostgreSQL 11 la CTE era una barrera de
optimización y se materializaba siempre, así que la gente la usaba a propósito para forzar el orden
de ejecución. Eso cambió el 3 de octubre de 2019, con la 12. La regla sana hoy es que `MATERIALIZED`
se escribe cuando mediste que el plan integrado es peor, y los dos `EXPLAIN` quedan en el ticket.

---

**05 → 11.** ¿Por qué `UNION` corta un ciclo y `UNION ALL` no, y en qué caso `UNION` **tampoco** lo
corta? 🟠

⏱️ **30 segundos** — Porque `UNION` elimina duplicados en cada vuelta, así que una fila ya vista se
descarta y el bucle se queda sin filas nuevas. Deja de funcionar si las filas no son idénticas.

🗣️ **2 minutos** — `UNION ALL` se limita a concatenar, de modo que un lazo en los datos produce las
mismas filas una y otra vez y la recursión nunca devuelve cero. `UNION` compara la fila entera con
lo acumulado. El problema es que "la fila entera" incluye las columnas que tú añadiste: en cuanto
metes un `nivel` que se incrementa, `('audio', 3)` y `('audio', 6)` son distintas y no se descarta
ninguna. Lo comprobé sobre la jerarquía con ciclo: con `nivel` dentro, la versión con `UNION` agota
el `statement_timeout` exactamente igual que `UNION ALL`.

🔬 **El detalle** — De ahí la segunda defensa, el contador con `WHERE nivel < 5`, que convive con
`UNION ALL` y además delata el ciclo en el resultado: los niveles repiten el patrón 1, 3, 1, 3, 7…
porque están dando vueltas al mismo lazo. PostgreSQL 14 en adelante tiene una tercera vía dedicada,
`CYCLE … SET … USING …`, que marca la fila donde se cierra el ciclo; MySQL 9.7.2 y SQLite 3.53.4 no
la tienen —`ERROR 1064` y `Parse error … near "CYCLE"`—. **Cuánto cuesta `UNION`:** una tabla hash o
un ordenamiento de lo acumulado en cada vuelta, que en un árbol grande y sin ciclos es puro gasto.

---

**05 → 12.** La CTE `por_estado` de §2 se nombra dos veces: ¿por qué `NOT MATERIALIZED` la hace más
lenta? 🟠

⏱️ **30 segundos** — Porque integrarla significa pegar el `GROUP BY` en los dos sitios donde aparece
el nombre, así que el `Seq Scan` del millón de pedidos se corre dos veces en vez de una.

🗣️ **2 minutos** — La CTE se menciona en el `FROM` y dentro del escalar que calcula el porcentaje
sobre el total. Materializada, el agregado se evalúa una vez y las dos referencias leen del mismo
búfer, que aquí son 17 kB en memoria. Integrada, el planificador produce dos `HashAggregate`
independientes, cada uno con su `Seq Scan` completo. Medido: 132,168 ms materializada contra 238,399
ms con `NOT MATERIALIZED`, y de 10 773 páginas se pasa a 21 543.

🔬 **El detalle** — Es la simetría exacta del caso de §2: ahí materializar era el desastre porque
impedía empujar un filtro muy selectivo; aquí materializar es lo correcto porque no hay filtro que
empujar y sí un cálculo caro que reutilizar. El criterio no es la palabra, es si hay un predicado
selectivo que quieras que entre. Y PostgreSQL 12 y posteriores ya eligen bien solos en los dos
casos: por eso ninguna de las dos palabras debería aparecer sin un `EXPLAIN` que la justifique.

---

**05 → 13.** ¿Cuándo preferirías una CTE recursiva a `generate_series`, sabiendo que es más lenta? 🟠

⏱️ **30 segundos** — Cuando la consulta tenga que correr también en MySQL o en SQLite.
`generate_series` es de PostgreSQL y la diferencia de tiempo es despreciable.

🗣️ **2 minutos** — Medido sobre los 1 000 días que cubre `pedidos`: la CTE recursiva tarda 0,937 ms
y `generate_series` 0,743 ms. Menos de dos décimas de milisegundo para mil filas, que al lado del
`LEFT JOIN` contra un millón de pedidos no se nota. En cambio, `generate_series(1,10)` en MySQL
9.7.2 responde `ERROR 1064`, y en SQLite existe una extensión del mismo nombre que trae el
intérprete de línea de órdenes pero que solo genera enteros, no fechas. Si el informe vive en una
consulta que se despliega contra varios motores, o en una migración, la CTE recursiva se paga sola.

🔬 **El detalle** — El mismo SQL con dos cambios corre en los dos motores: `dia + 1` en PostgreSQL es
`dia + INTERVAL 1 DAY` en MySQL. La otra diferencia relevante es que en PostgreSQL el término base
`SELECT DATE '2024-03-18'` puede llevar el tipo implícito, y conviene escribirlo explícito para que
el tipo de la columna acumulada no cambie entre vueltas.

---

**05 → 14.** Escribe la CTE recursiva que dé la cadena de ancestros de `audio` hasta la raíz, con el
nivel, sobre la tabla temporal de §4. 🔴

⏱️ **30 segundos** — Es el descenso al revés: el término base es la hoja y el `JOIN` del término
recursivo empareja `c.nombre = a.padre` en lugar de `c.padre = a.nombre`.

🗣️ **2 minutos** — El término base selecciona la fila de `audio` con nivel 0, y el recursivo sube un
escalón por vuelta buscando la fila cuyo `nombre` es el `padre` de la fila anterior. Termina solo
cuando llega a la raíz, porque `padre IS NULL` no empareja con ningún `nombre`. Da tres filas —
`audio`, `tecnologia`, `catalogo`— y es exactamente la consulta que se usa para pintar la miga de
pan de una ficha de producto.

🔬 **El detalle** — Corrido sobre la tabla temporal del capítulo:

```text
tienda=# WITH RECURSIVE ancestros (nombre, padre, nivel) AS (
tienda(#       SELECT nombre, padre, 0 FROM categorias WHERE nombre = 'audio'
tienda(#     UNION ALL
tienda(#       SELECT c.nombre, c.padre, a.nivel + 1
tienda(#         FROM categorias c JOIN ancestros a ON c.nombre = a.padre
tienda(# )
tienda-# SELECT nivel, nombre FROM ancestros ORDER BY nivel;
 nivel |   nombre
-------+------------
     0 | audio
     1 | tecnologia
     2 | catalogo
(3 filas)
```

Hay que arrastrar `padre` dentro de la CTE aunque no se proyecte al final: es la columna con la que
engancha la vuelta siguiente. Y si la jerarquía tuviera un ciclo, esta versión también colgaría, así
que en producción lleva su `WHERE a.nivel < N`.

---

**05 → 15.** El informe diario sin huecos tiene que correr con el mismo SQL en PostgreSQL y en MySQL
9.7.2: escribe la consulta y señala las diferencias de dialecto que resolviste. 🔴

⏱️ **30 segundos** — Se cambia `generate_series` por una CTE recursiva y la aritmética de fechas por
`INTERVAL 1 DAY`, que sí entienden los dos. Lo demás es idéntico.

🗣️ **2 minutos** — Las tres decisiones son: generar el calendario con `WITH RECURSIVE` porque
`generate_series` no existe en MySQL; escribir el salto de día como `dia + INTERVAL 1 DAY` en vez de
`dia + 1`, que en MySQL sumaría un número al valor de fecha; y dejar el rango como media abierta
—`>= c.dia AND < c.dia + INTERVAL 1 DAY`— en lugar de castear `creado_en` a fecha, porque el cast
también difiere entre motores y además impediría usar un índice sobre `creado_en`. El `LEFT JOIN`
con todas las condiciones en el `ON` y el `coalesce` funcionan igual en los dos.

🔬 **El detalle** — Corrido en MySQL 9.7.2, con las mismas siete filas que en PostgreSQL:

```text
mysql> WITH RECURSIVE calendario (dia) AS (
    ->       SELECT DATE '2024-03-18'
    ->     UNION ALL
    ->       SELECT dia + INTERVAL 1 DAY FROM calendario WHERE dia < DATE '2024-03-24')
    -> SELECT c.dia, count(p.id) AS pedidos, coalesce(sum(p.total),0) AS importe
    ->   FROM calendario c
    ->   LEFT JOIN pedidos p ON p.creado_en >= c.dia AND p.creado_en < c.dia + INTERVAL 1 DAY
    ->        AND p.cliente_id = (SELECT id FROM clientes WHERE codigo = 'CLI-00311')
    ->  GROUP BY c.dia ORDER BY c.dia;
+------------+---------+---------+
| dia        | pedidos | importe |
+------------+---------+---------+
| 2024-03-18 |       0 |    0.00 |
| 2024-03-19 |       0 |    0.00 |
| 2024-03-20 |       1 | 7983.79 |
| 2024-03-21 |       0 |    0.00 |
| 2024-03-22 |       0 |    0.00 |
| 2024-03-23 |       0 |    0.00 |
| 2024-03-24 |       0 |    0.00 |
+------------+---------+---------+
```

Diferencia menor pero real en la salida: MySQL devuelve `0.00` y PostgreSQL `0`, porque el
`coalesce` toma el tipo `DECIMAL(12,2)` de la columna. Si el informe se compara carácter a carácter
entre entornos, eso hay que formatearlo en la aplicación.

---

**05 → 16.** Te pasan una consulta recursiva que no vuelve en producción: escribe la secuencia de
diagnóstico —qué miras, con qué, en qué orden— y las dos correcciones posibles. 🔴

⏱️ **30 segundos** — Primero la corto, después busco el ciclo en los datos, y luego arreglo el SQL
con `UNION` o con un contador de profundidad.

🗣️ **2 minutos** — El orden importa, porque mientras la consulta corre está llenando el disco
temporal. Uno: localizar el `pid` en `pg_stat_activity` filtrando por `state = 'active'` y por el
texto de la consulta, y cortarla con `pg_cancel_backend(pid)`; si no responde,
`pg_terminate_backend`. Dos: confirmar que el problema es un ciclo y no un volumen legítimo,
corriendo la misma recursión con `UNION` y sin columnas acumuladas, y comparando el recuento con el
`count(*)` de la tabla: si alcanza más nodos de los que hay, hay lazo. Tres: localizar el lazo
concreto, que con el contador de profundidad se ve en el patrón de filas por nivel. Cuatro:
corregir.

🔬 **El detalle** — Las dos correcciones, con sus costes. `UNION` en vez de `UNION ALL` es la más
barata de escribir y sirve si solo necesitas el conjunto de nodos alcanzables; cuesta una tabla hash
o un ordenamiento de lo acumulado en cada vuelta y **deja de funcionar en cuanto la CTE lleva dentro
una columna que cambia**, como un `nivel`. El contador `WHERE nivel < N` convive con `UNION ALL`,
conserva nivel y ruta, y deja rastro de que hubo corte. En PostgreSQL 14 o posterior hay una
tercera, `CYCLE … SET … USING …`, que marca la fila donde se cierra el ciclo sin perder las columnas
acumuladas. Y la corrección de fondo no es de SQL: un `CHECK` o un disparador que impida crear el
lazo, más un `statement_timeout` en la aplicación para que el próximo incidente no sea un disco
lleno.

---

## Capítulo 06 — Funciones de ventana

Las 21 preguntas de [`06`](06-funciones-de-ventana.md).

**06 → 1.** ¿Cuántas filas devuelve una ventana comparada con `GROUP BY`, y qué se puede proyectar
con una que no con el otro? 🟢

⏱️ **30 segundos** — Una ventana devuelve **una fila por cada fila de entrada**; `GROUP BY` devuelve
una por grupo. Por eso con la ventana puedes proyectar columnas de detalle —el `codigo` del pedido—
que el `GROUP BY` ya perdió.

🗣️ **2 minutos** — `GROUP BY` colapsa: en §1, 97 filas de tres clientes salen como tres, y el
`codigo` del pedido deja de existir porque no está agrupado ni agregado. La ventana no colapsa nada:
calcula sobre un conjunto de filas vecinas y añade una columna al lado de las que ya había. Esa es
exactamente la razón de que existan, y lo que resuelve los problemas que con `GROUP BY` obligan a
subconsulta.

🔬 **El detalle** — El corte lo marca la palabra *colapsar*. Con agregación, la lista de selección
solo admite columnas agrupadas o funciones de agregación; con ventana, todo lo demás sigue
disponible porque se evalúa en el paso del `SELECT`, cuando la fila todavía está entera. Medido: el
top-3 por cliente sale en 45,634 ms con ventana y en 3862,349 ms con la subconsulta correlacionada
equivalente.

---

---

**06 → 2.** Nombra las dos cláusulas que van dentro de `OVER` y di qué hace cada una. 🟢

⏱️ **30 segundos** — `PARTITION BY`, que corta la tabla en grupos independientes, y `ORDER BY`, que
ordena dentro de cada grupo.

🗣️ **2 minutos** — `PARTITION BY` hace que la función se reinicie en cada grupo: por eso el top-N
por cliente tiene un puesto 1 por cliente y no uno global. Sin `PARTITION BY`, la ventana es la
partición entera. El `ORDER BY` de dentro de `OVER` define en qué orden se recorre cada partición, y
es independiente del `ORDER BY` de la consulta. Hay una tercera cosa que también va ahí y que casi
nadie escribe: el marco.

🔬 **El detalle** — Categoría motor, medido en los cuatro: la sintaxis `OVER (PARTITION BY … ORDER BY
… [marco])` funciona igual en PostgreSQL 18.6, MySQL 9.7.2, MariaDB 12.3.3 y SQLite 3.53.4. La
cláusula de ISO/IEC 9075 no la he verificado. El marco solo aparece cuando hay `ORDER BY`; sin él,
el defecto es la partición completa.

---

---

**06 → 3.** ¿Qué devuelven `LAG` y `LEAD` en los bordes de una partición, y cómo se cambia? 🟢

⏱️ **30 segundos** — Nulo: `LAG` en la primera fila y `LEAD` en la última. Se cambia con el tercer
argumento, que es el valor por defecto: `LAG(p.total, 1, 0)`.

🗣️ **2 minutos** — En la sesión de §4, la primera fila de `CLI-00311` sale con `anterior` y `delta`
vacíos porque no hay fila previa dentro de la ventana. El borde hay que decidirlo a conciencia:
poner 0 hace que el `delta` salga igual al total del pedido, lo que en una gráfica suele mentir más
que dejar el hueco. El segundo argumento, que es el desplazamiento, también se puede cambiar:
`LAG(total, 2)` mira dos filas atrás.

🔬 **El detalle** — El borde es de partición, no de tabla: con `PARTITION BY p.cliente_id`, `LAG` no
cruza del último pedido de un cliente al primero del siguiente, y devuelve nulo. Y ojo con la
pregunta que de verdad se hace: si quieres el valor del *día* anterior y hay días sin pedido, `LAG`
te da el pedido anterior, que puede ser de hace dos meses. Para eso hay que generar el calendario.

---

---

**06 → 4.** Escribe el marco por defecto cuando la ventana lleva `ORDER BY`, y di si lo fija el
estándar o cada motor. 🟢

⏱️ **30 segundos** — `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. No lo fija ningún motor
por su cuenta: los cuatro del corpus hacen lo mismo, y es coherente con el estándar, aunque la
cláusula de ISO/IEC 9075 no la he verificado.

🗣️ **2 minutos** — La trampa está en `RANGE`, no en `CURRENT ROW`. `RANGE` razona sobre valores del
`ORDER BY`, así que *current row* significa «esta fila y todas las que empatan con ella». Un `SUM`
acumulado sobre una columna con repetidos avanza por escalones en vez de fila a fila. Medido con los
diez clientes de §3: en el empate de 22 pedidos, `acum_range` salta de 99 a 143 y repite 143; con
`ROWS` sale 121 y luego 143.

🔬 **El detalle** — Categoría: medido como motor en los cuatro, con el mismo resultado —143, 143 y
224, 224, 224 en PostgreSQL 18.6, MySQL 9.7.2, MariaDB 12.3.3 y SQLite 3.53.4—, así que no es una
rareza de PostgreSQL. Sin `ORDER BY` en la ventana el defecto es otro: `RANGE BETWEEN UNBOUNDED
PRECEDING AND UNBOUNDED FOLLOWING`, o sea la partición entera.

---

---

**06 → 5.** Con los diez clientes de §3, ¿qué tres valores da `RANK` en el triple empate de 20
pedidos, y cuál es el siguiente rango? 🟢

⏱️ **30 segundos** — `RANK` da 7, 7 y 7 a los tres clientes empatados en 20 pedidos, y el siguiente
rango es 10.

🗣️ **2 minutos** — `RANK` reparte el mismo número a todos los empatados y después salta tantas
posiciones como filas empataron: tres filas en el 7 hacen que la siguiente sea la 10, no la 8. Es el
mismo mecanismo del doble empate de 22, que da 4, 4 y luego 6. `DENSE_RANK` sobre los mismos datos
da 6, 6, 6 y después 7, porque cuenta valores distintos, no filas.

🔬 **El detalle** — Número medido en la sesión de §3, con los diez clientes de `CLI-0031_`, cuyos
recuentos son 52, 24, 23, 22, 22, 21, 20, 20, 20 y 17. Categoría motor: los cuatro motores del
corpus dan las mismas columnas `rango` y `denso`; solo `ROW_NUMBER` difiere entre ellos.

---

---

**06 → 6.** Distingue `ROW_NUMBER`, `RANK` y `DENSE_RANK` en una frase por cada uno. 🟡

⏱️ **30 segundos** — `ROW_NUMBER` no repite nunca; `RANK` repite y salta; `DENSE_RANK` repite y no
salta.

🗣️ **2 minutos** — `ROW_NUMBER` numera 1, 2, 3… sin huecos, y cuando hay empate elige
arbitrariamente quién va antes. `RANK` da el mismo número a los empatados y deja un hueco del tamaño
del empate. `DENSE_RANK` da el mismo número y sigue por el siguiente entero. Sin empates las tres
dan exactamente lo mismo, y de ahí viene la confusión.

🔬 **El detalle** — Con el doble empate de §3: `ROW_NUMBER` 4 y 5, `RANK` 4 y 4 seguido de 6,
`DENSE_RANK` 4 y 4 seguido de 5. El criterio práctico: `ROW_NUMBER` para paginar o quedarte con N
por grupo; `RANK` para un podio donde el empate deja el puesto siguiente vacío; `DENSE_RANK` para
niveles o tramos, donde no quieres huecos.

---

---

**06 → 7.** Distingue `ROWS` de `RANGE` y di en qué caso dan exactamente el mismo resultado. 🟡

⏱️ **30 segundos** — `ROWS` cuenta filas y `RANGE` compara valores del `ORDER BY`. Dan el mismo
resultado cuando ese `ORDER BY` no tiene valores repetidos.

🗣️ **2 minutos** — Con `ROWS`, *current row* es esta fila y ninguna más, y `2 PRECEDING` son
exactamente dos filas hacia atrás. Con `RANGE`, *current row* arrastra a todas las filas que empatan
en el valor del `ORDER BY`, y un desplazamiento es una distancia de valor, no de posición. En la
sesión de §5 las tres primeras filas coinciden —52, 24 y 23 no empatan con nadie— y las dos columnas
se separan justo donde empieza el empate.

🔬 **El detalle** — `RANGE` con desplazamiento exige que el `ORDER BY` sea de un solo elemento y de
un tipo que admita resta: por eso funciona `RANGE BETWEEN INTERVAL '30 days' PRECEDING` sobre
`creado_en` en PostgreSQL 18.6 y en MySQL 9.7.2, y MariaDB 12.3.3 lo rechaza con `ERROR 1064`.
`ROWS` no pide nada de eso. Hay un tercer modo, `GROUPS`, que cuenta grupos de empatados: lo tienen
PostgreSQL y SQLite, y no MySQL ni MariaDB.

---

---

**06 → 8.** ¿Por qué el `ORDER BY` de la ventana y el de la consulta son independientes? 🟡

⏱️ **30 segundos** — Porque son dos ordenaciones en momentos distintos: la de la ventana decide con
qué orden se calcula la función, y la de la consulta decide cómo se presenta el resultado.

🗣️ **2 minutos** — En §2, la ventana ordena por `p.total DESC` para numerar del más caro al más
barato, y la consulta ordena por cliente y puesto para que el informe se lea. Podrías ordenar la
salida por fecha, por código o por nada, y la columna `puesto` no cambiaría ni un valor. En el
sentido contrario, cambiar el `ORDER BY` de dentro de `OVER` cambia todos los números.

🔬 **El detalle** — La consecuencia práctica: cuando alguien dice «el ranking sale desordenado», casi
siempre le falta el `ORDER BY` de fuera, no el de la ventana. Y el caso contrario es el de §5:
`acum_rows` da 204, 224 y 184 en una salida ordenada por cliente porque el acumulado avanzó por el
orden interno de la ventana, no por el de la pantalla.

---

---

**06 → 9.** ¿Dónde se evalúa una ventana en el orden lógico, y qué dos cláusulas quedan vetadas? 🟡

⏱️ **30 segundos** — En el paso del `SELECT`: después de `FROM`, `WHERE`, `GROUP BY` y `HAVING`, y
antes de `ORDER BY` y `LIMIT`. Quedan vetados el `WHERE` y el `HAVING`.

🗣️ **2 minutos** — La razón es de orden, no de capricho: cuando el `WHERE` se evalúa, la columna que
produce la ventana todavía no existe, y el `HAVING` filtra grupos, que también se resuelven antes.
Los mensajes son literales: `window functions are not allowed in WHERE` y `… in HAVING`. La
corrección es envolver la ventana en una CTE o en una subconsulta del `FROM` y filtrar desde fuera.

🔬 **El detalle** — Hay un tercer intento que despista, porque el mensaje habla de otra cosa: `WHERE
puesto <= 3` con `puesto` como alias del `SELECT` responde `column "puesto" does not exist`. Es la
misma regla del alias, no una regla de ventanas. Y envolver no cuesta un paso más: en el plan de §2,
PostgreSQL 18.6 empujó el filtro dentro del `WindowAgg` como `Run Condition: (row_number() OVER w1
<= 3)`.

---

---

**06 → 10.** `FILTER` sobre una ventana, ¿estándar o motor? Di qué hace cada uno de los cuatro. 🟡

⏱️ **30 segundos** — Motor, y con diferencias: PostgreSQL 18.6 y SQLite 3.53.4 lo admiten sobre una
ventana; MySQL 9.7.2 y MariaDB 12.3.3 responden `ERROR 1064` de sintaxis.

🗣️ **2 minutos** — `FILTER (WHERE …)` es la forma estándar de agregar con condición, y sobre ventana
permite cosas como `count(*) FILTER (WHERE estado = 'ANULADO') OVER ()`, que en el corpus devuelve
60 000 tanto en PostgreSQL como en SQLite. En MySQL y MariaDB hay que emularlo con `SUM(CASE WHEN …
THEN 1 ELSE 0 END) OVER (…)`, que es portable en los cuatro.

🔬 **El detalle** — No he verificado la cláusula de ISO/IEC 9075, así que la afirmación honesta es:
«dos de los cuatro lo tienen, medido en sesión». Es un buen ejemplo de la regla del corpus: decir
«el estándar exige FILTER» sería afirmar autoridad sobre algo que no comprobé, y se falsa en dos
minutos abriendo un `mysql`.

---

---

**06 → 11.** La cláusula `WINDOW v AS (…)`, ¿qué ahorra de verdad y qué no ahorra? 🟡

⏱️ **30 segundos** — Ahorra escribir la misma definición de ventana tres veces y, sobre todo, tener
que retocarla en tres sitios. Lo que no ahorra es trabajo del motor.

🗣️ **2 minutos** — En §3, las tres funciones comparten `WINDOW v AS (ORDER BY pedidos DESC)`. Si la
escribieras completa tres veces, el motor reconocería que son la misma ventana y usaría un solo
`Sort`, igual que con el nombre. El beneficio es de mantenimiento y de legibilidad: el día que
añadas una columna de desempate, la cambias una vez.

🔬 **El detalle** — Categoría motor, medido: `WINDOW … AS` funciona en los cuatro —PostgreSQL 18.6,
MySQL 9.7.2, MariaDB 12.3.3 y SQLite 3.53.4—, que es de las pocas cláusulas avanzadas de ventana
donde coinciden los cuatro. También admite ventanas derivadas, del tipo `WINDOW v AS (PARTITION BY
…), w AS (v ORDER BY …)`.

---

---

**06 → 12.** `SUM(count(*)) OVER (…)` no es un error de escritura. Explica por qué se puede escribir
eso. 🟠

⏱️ **30 segundos** — Porque la ventana se evalúa después del `GROUP BY`: el `count(*)` ya está
resuelto y el `SUM` de ventana acumula sobre las filas que el grupo dejó.

🗣️ **2 minutos** — Son dos pasos, no dos agregaciones anidadas. Primero `GROUP BY p.estado` colapsa
el millón de pedidos en cinco filas con su `count(*)`. Después, en el paso del `SELECT`, la ventana
toma esas cinco filas como su partición y las acumula. Por eso el resultado es 300 000, 570 000, 820
000, 940 000 y 1 000 000, y cierra exactamente en el millón de pedidos del corpus.

🔬 **El detalle** — Es el mismo argumento de orden lógico que veta la ventana en el `HAVING`: el
`HAVING` va antes y la ventana va después. Y sirve de comprobación cruzada, porque el último valor
del acumulado tiene que coincidir con el total de la tabla; si no coincide, el `GROUP BY` está
perdiendo filas.

---

---

**06 → 13.** En §5, `acum_range` da 143 dos veces y `acum_rows` da 121 y 143. Explica el mecanismo
exacto que produce esa diferencia. 🟠

⏱️ **30 segundos** — Porque el marco por defecto es `RANGE`, y `RANGE` mete en el marco a todas las
filas que empatan en el valor del `ORDER BY`. Las dos filas de 22 pedidos comparten marco, así que
las dos ven el acumulado de después de ambas.

🗣️ **2 minutos** — Paso a paso: hasta la fila de 23 el acumulado va en 99. Llegan dos clientes con
22. Con `RANGE … CURRENT ROW`, el marco de la primera incluye a la segunda, porque valen lo mismo;
    99 + 22 + 22 = 143, y la segunda ve exactamente el mismo marco, así que repite 143. Con `ROWS …
    CURRENT ROW` el marco es posicional: 99 + 22 = 121 para la primera, y 121 + 22 = 143 para la
    segunda.

🔬 **El detalle** — Es el fallo más caro del capítulo porque no da error y el total final cuadra: 241
en las dos columnas. Solo mienten los valores intermedios. Y no es específico de PostgreSQL: medido,
MySQL 9.7.2, MariaDB 12.3.3 y SQLite 3.53.4 dan también 143, 143. La corrección es una línea,
escribir `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

---

---

**06 → 14.** Los tres clientes empatados en 20 reciben 8, 9 y 7 en PostgreSQL y 7, 8, 9 en MySQL.
¿Incumple alguno el estándar? Justifica y di cómo se arregla. 🟠

⏱️ **30 segundos** — No incumple ninguno. `ROW_NUMBER` sobre un `ORDER BY` que no desempata no puede
ser determinista, y ningún motor promete un orden que tú no pediste. Se arregla añadiendo a la
ventana una columna que desempate.

🗣️ **2 minutos** — Los cuatro motores del corpus dan dos repartos distintos dentro del triple
empate de 20 pedidos: PostgreSQL 18.6 y MariaDB 12.3.3 asignan 8-9-7, y MySQL 9.7.2 y SQLite
3.53.4 asignan 7-8-9. Cada uno numera en el orden en que su ejecución fue entregando las
filas, que depende del plan. La corrección es `ORDER BY pedidos DESC, cliente` dentro de `OVER`, con
lo que el orden pasa a ser total y los cuatro coinciden.

🔬 **El detalle** — Categoría: estándar no verificado; lo medido es comportamiento de motor, y el
mismo motor podría cambiarlo entre versiones o entre planes de la misma versión. El riesgo real no
es el informe en pantalla: es un número de puesto que se guarda, se factura o se usa para paginar,
donde dos ejecuciones dan páginas distintas y algunas filas no salen nunca.

---

---

**06 → 15.** El top-3 por cliente tarda 45,634 ms con ventana y 3862,349 ms con subconsulta
correlacionada. Explica de dónde sale la diferencia, nombrando el nodo del plan. 🟠

⏱️ **30 segundos** — La subconsulta correlacionada se ejecuta una vez por cada fila candidata; la
ventana ordena las filas una sola vez y las recorre. El nodo es `WindowAgg` sobre un `Sort`.

🗣️ **2 minutos** — En el plan de la versión con ventana, el `Sort` ordena las 97 filas de los tres
clientes en 29 kB de memoria y el `WindowAgg` las numera encima, en una pasada. La versión
correlacionada baja al índice de `pedidos` una vez por fila candidata para calcular su propio top-3,
y esas 97 bajadas son las que cuestan los 3862,349 ms. La diferencia es de 85 veces sobre tres
clientes, y crece con el número de particiones, no con el tamaño de cada una.

🔬 **El detalle** — Hay un extra medido que conviene nombrar: el plan trae `Run Condition:
(row_number() OVER w1 <= 3)`, o sea que PostgreSQL 18.6 metió el `WHERE puesto <= 3` dentro del
`WindowAgg` y deja de producir filas en cuanto la partición pasa de tres. La lectura completa de un
plan es del bloque 03 del corpus.

---

---

**06 → 16.** Alguien escribe `WHERE puesto <= 3` y el motor responde `column "puesto" does not
exist` en lugar de hablar de ventanas. ¿Por qué ese mensaje y no el otro? 🟠

⏱️ **30 segundos** — Porque el `WHERE` no está rechazando una ventana: está buscando una columna.
`puesto` es un alias de la lista del `SELECT`, y en el paso del `WHERE` los alias del `SELECT`
todavía no existen.

🗣️ **2 minutos** — Son dos reglas distintas que producen dos mensajes distintos. Si escribes la
ventana entera dentro del `WHERE`, PostgreSQL responde `window functions are not allowed in WHERE`,
que habla de ventanas. Si escribes el alias, el analizador resuelve nombres antes de llegar a
ninguna regla sobre ventanas, no encuentra ninguna columna llamada `puesto` en `pedidos` y para ahí.
La corrección es la misma en los dos casos: envolver.

🔬 **El detalle** — Es la misma regla del alias del `SELECT` que ya aparece con las agregaciones, y
por eso confunde: el lector cree que descubrió una limitación de las ventanas cuando en realidad
tropezó con el orden lógico. Los cuatro motores vetan la ventana en el `WHERE`, cada uno con su
mensaje: `ERROR 3593` en MySQL 9.7.2, `ERROR 4015` en MariaDB 12.3.3 y `misuse of window function`
en SQLite 3.53.4.

---

---

**06 → 17.** ¿En qué caso `RANGE` es la respuesta correcta y `ROWS` la equivocada? Usa el ejemplo de
los 30 días de §5. 🟠

⏱️ **30 segundos** — Cuando la pregunta es por distancia de valor y no por número de filas. El
conteo de pedidos de los últimos 30 días necesita `RANGE BETWEEN INTERVAL '30 days' PRECEDING AND
CURRENT ROW`; con `ROWS` contarías las N filas anteriores, que pueden abarcar dos años.

🗣️ **2 minutos** — En la sesión de §5, la columna `ult_30_dias` de `CLI-00311` baja a 1 el 12 de
mayo de 2023 porque el pedido anterior fue el 10 de marzo, a más de 30 días. Un `ROWS BETWEEN 2
PRECEDING AND CURRENT ROW` habría contado 3 sin mirar el calendario. La regla es: si el enunciado
dice «últimos 30 días», «±100 euros» o cualquier umbral sobre el propio valor ordenado, es `RANGE`;
si dice «las tres últimas», es `ROWS`.

🔬 **El detalle** — El precio de esa precisión es portabilidad: `RANGE` con `INTERVAL` funciona en
PostgreSQL 18.6 y en MySQL 9.7.2, MariaDB 12.3.3 lo rechaza con `ERROR 1064` y SQLite 3.53.4 ni
siquiera tiene tipo intervalo, aunque sí acepta desplazamientos numéricos. Categoría motor; la
cláusula del estándar no la he verificado.

---

---

**06 → 18.** Escribe la consulta que dé, por cada uno de los cinco estados de `pedidos`, los dos
pedidos de mayor `total`, con su puesto. Que corra en PostgreSQL 18.6. 🔴

⏱️ **30 segundos** — Una CTE que numere con `ROW_NUMBER` particionando por estado, y un filtro por
fuera. Corrida en PostgreSQL 18.6, tarda 1384,732 ms sobre el millón de pedidos.

🗣️ **2 minutos** — El `ORDER BY` de la ventana lleva dos columnas a propósito: `p.total DESC` para
el criterio que pide el enunciado y `p.codigo` para que el desempate sea determinista y la consulta
dé lo mismo en cada ejecución y en cada motor. El filtro `puesto <= 2` va fuera porque una ventana
no puede aparecer en el `WHERE`.

```sql
WITH r AS (
  SELECT p.estado, p.codigo, p.total,
         ROW_NUMBER() OVER (PARTITION BY p.estado
                            ORDER BY p.total DESC, p.codigo) AS puesto  -- orden total
    FROM pedidos p
)
SELECT estado, codigo, total, puesto FROM r WHERE puesto <= 2 ORDER BY estado, puesto;
```

🔬 **El detalle** — La salida medida, para poder citarla: `ENTREGADO` con `PED-00791` a 21 656,07,
`PAGADO` con `PED-710775` a 21 068,28, `ENVIADO` con `PED-903775` a 20 881,36, `PENDIENTE` con
`PED-170855` a 20 726,10 y `ANULADO` con `PED-825599` a 20 572,73. Si quisieras el podio con empates
compartidos, `RANK` en vez de `ROW_NUMBER`, y entonces `puesto <= 2` puede devolver más de dos filas
por estado.

---

---

**06 → 19.** Un informe de acumulado mensual "cuadra al final pero miente en el medio". Da las tres
hipótesis en orden de probabilidad y la consulta con la que confirmarías la primera. 🔴

⏱️ **30 segundos** — La primera hipótesis es el marco por defecto: un `SUM(...) OVER (ORDER BY mes)`
con meses repetidos por alguna dimensión acumula por escalones. Se confirma poniendo la misma suma
con `ROWS` al lado y comparando columna contra columna.

🗣️ **2 minutos** — Las tres, en orden de probabilidad: uno, marco `RANGE` implícito sobre un `ORDER
BY` con valores repetidos, que es el caso de §5 y no da ningún error; dos, un `JOIN` que multiplica
filas antes de acumular, que infla los intermedios y también el total, así que se descarta rápido si
el total sí cuadra; tres, un `ORDER BY` de ventana que no es único y hace que el acumulado avance en
un orden distinto al de la presentación, que es lo que produce los 204, 224 y 184 de §5.

🔬 **El detalle** — La consulta de confirmación es literalmente la de §5: la misma expresión dos
veces, una con el marco implícito y otra con `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`,
sobre las mismas filas. Si las dos columnas divergen exactamente donde el `ORDER BY` tiene
repetidos, es la hipótesis uno y la corrección es una línea. Señal de diagnóstico: en las tres
hipótesis el último valor del acumulado cuadra, y por eso nadie lo detecta hasta que alguien suma a
mano.

---

---

**06 → 20.** Escribe la consulta que detecte, sobre `eventos_pedido` de un pedido, los huecos de más
de un día entre eventos consecutivos, y di qué marco usa. 🔴

⏱️ **30 segundos** — Un `LAG` sobre `ocurrido_en` ordenado por esa misma columna, y un filtro por
fuera sobre la diferencia. El marco no interviene: `LAG` no usa marco.

🗣️ **2 minutos** — `LAG` mira la fila anterior de la ventana, no un conjunto de filas, así que ni
`ROWS` ni `RANGE` cambian nada aquí. La diferencia entre dos `timestamptz` es un `interval`, y se
compara directamente con `INTERVAL '1 day'`. Corrida sobre `PED-00042`, sus tres eventos salen con
huecos de 00:37:00, o sea ninguno por encima del umbral.

```sql
WITH h AS (
  SELECT e.tipo, e.ocurrido_en,
         e.ocurrido_en - LAG(e.ocurrido_en) OVER (ORDER BY e.ocurrido_en) AS hueco
    FROM eventos_pedido e
    JOIN pedidos p ON p.id = e.pedido_id
   WHERE p.codigo = 'PED-00042'
)
SELECT tipo, ocurrido_en, hueco FROM h WHERE hueco > INTERVAL '1 day' ORDER BY ocurrido_en;
```

🔬 **El detalle** — Dos matices. El primer evento tiene `hueco` nulo y el `WHERE hueco > …` lo
descarta solo, porque una comparación con nulo no es verdadera; si quisieras marcarlo, `coalesce`.
El segundo: para hacerlo de todos los pedidos a la vez hay que añadir `PARTITION BY e.pedido_id`, o
el `LAG` cruzaría del último evento de un pedido al primero del siguiente y fabricaría huecos
falsos.

---

---

**06 → 21.** La misma consulta de ranking tiene que dar el mismo número de puesto en PostgreSQL,
MySQL, MariaDB y SQLite. Escríbela y señala las dos decisiones que lo garantizan. 🔴

⏱️ **30 segundos** — Hay que hacer dos cosas: usar solo el subconjunto que los cuatro implementan, y
dar a la ventana un `ORDER BY` que desempate del todo.

🗣️ **2 minutos** — El subconjunto seguro es `PARTITION BY`, `ORDER BY`, las funciones de numeración
y `ROWS`/`RANGE` con `UNBOUNDED`, `CURRENT ROW` y desplazamientos numéricos. Fuera quedan `FILTER`
sobre ventana, `GROUPS` y `EXCLUDE`, que MySQL 9.7.2 y MariaDB 12.3.3 no tienen, y `RANGE` con
`INTERVAL`, que MariaDB rechaza. La segunda decisión es el orden total, que es lo que hace que el
número de puesto sea el mismo en los cuatro.

```sql
SELECT c.codigo AS cliente, p.codigo AS pedido, p.total,
       ROW_NUMBER() OVER (PARTITION BY p.cliente_id
                          ORDER BY p.total DESC, p.codigo) AS puesto  -- desempate explícito
  FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
 WHERE c.codigo BETWEEN 'CLI-00310' AND 'CLI-00312';
```

🔬 **El detalle** — La prueba de que la segunda decisión hace falta está medida: sin la columna de
desempate, los tres clientes empatados en 20 pedidos de §3 reciben 8-9-7 en PostgreSQL 18.6 y en
MariaDB 12.3.3, y 7-8-9 en MySQL 9.7.2 y en SQLite 3.53.4. Con ella, los cuatro coinciden.
`WINDOW v AS (…)` también es portable en los cuatro, así que se puede usar; lo que no es portable es
todo lo que está en la tabla de §7 con una ❌.

---

---

## Capítulo 07 — Escritura, upsert y vistas

Las 17 preguntas de [`07`](07-escritura-upsert-y-vistas.md).

**07 → 1.** ¿Qué hace `UNION` que no hace `UNION ALL`, y con qué nodo del plan lo hace en
PostgreSQL? 🟢

⏱️ **30 segundos** — `UNION` elimina las filas repetidas y `UNION ALL` no. En PostgreSQL esa
deduplicación es un nodo `HashAggregate` encima del `Append`.

🗣️ **2 minutos** — Los dos apilan el resultado de dos consultas con el mismo número de columnas y
tipos compatibles; la diferencia está solo en lo que pasa después. En el plan de §2 el `Append` de
abajo es idéntico en las dos versiones, hasta en las páginas tocadas: `shared hit=21540` en ambas.
Lo único que aparece con `UNION` es un `HashAggregate` con `Group Key: pedidos.cliente_id` encima, y
ese nodo es la factura entera de la palabra que no escribiste. Por eso la regla es escribir `ALL`
salvo que puedas decir qué duplicado estás quitando.

🔬 **El detalle** — Medido: 274,114 ms contra 189,145 ms de tiempo de ejecución, **un 45 % más**, y
**5 657 kB** de memoria para la tabla hash —que fuera de `work_mem` serían ficheros temporales en
disco—. La deduplicación sí trabajó: 520 000 filas se quedaron en 49 993. Que `UNION` deduplique es
el comportamiento de los cuatro motores del corpus; la cláusula de ISO/IEC 9075 que lo manda no está
verificada en esta edición, porque el estándar es de pago.

---

---

**07 → 2.** ¿Qué devuelve `EXCEPT` y qué devuelve `INTERSECT`? 🟢

⏱️ **30 segundos** — `INTERSECT` devuelve las filas que están en las dos consultas; `EXCEPT`, las de
la primera que no están en la segunda.

🗣️ **2 minutos** — Los dos deduplican por defecto, igual que `UNION`, y los dos admiten `ALL` para
no hacerlo. `EXCEPT` es el anti-join escrito como conjunto: en §3, `SELECT id FROM pedidos EXCEPT
SELECT pedido_id FROM pagos` da los **180 000** pedidos sin ningún pago, que son los `PENDIENTE` más
los `ANULADO` del dominio. El `INTERSECT` del mismo apartado cruza las categorías que un cliente
compró en pedidos `ANULADO` con las que compró en `ENTREGADO` y devuelve seis de las siete: falta
`audio`, comprada en un lado y no en el otro.

🔬 **El detalle** — El `ALL` no es cosmético: `EXCEPT` tardó **767,933 ms** y `EXCEPT ALL`, **635,727
ms**, porque el segundo se ahorra deduplicar un conjunto donde `id` ya es único. **Motor:** SQLite
3.53.4 tiene `EXCEPT` e `INTERSECT` pero **no acepta sus variantes `ALL`** —`Parse error … near
"ALL"`—, y MySQL solo los tiene **desde 8.0.31**, de octubre de 2022.

---

---

**07 → 3.** ¿Qué es la pseudotabla `EXCLUDED` dentro de un `ON CONFLICT DO UPDATE`? 🟢

⏱️ **30 segundos** — Es la fila que *no* entró: los valores que proponía el `INSERT` y que el
conflicto dejó fuera, para que el `UPDATE` pueda usarlos.

🗣️ **2 minutos** — Sin ella el `DO UPDATE` no tendría de dónde sacar los valores nuevos, porque el
nombre de la tabla se refiere a la fila que ya estaba. Eso permite escribir el clásico `SET nombre =
EXCLUDED.nombre, pais = EXCLUDED.pais` para pisar, y también `SET total = clientes.total +
EXCLUDED.total` para acumular, que es el patrón de los contadores. El truco de diagnóstico que la
acompaña es `RETURNING`: sin él, `INSERT 0 1` no distingue haber insertado de haber actualizado, y
no cuesta ni una consulta ni latencia extra.

🔬 **El detalle** — **Motor, no estándar.** `INSERT … ON CONFLICT` es de PostgreSQL desde la 9.5, y
SQLite le copió la sintaxis desde la 3.24; MySQL no la tiene y usa `ON DUPLICATE KEY UPDATE`. El
acompañante `(xmax <> 0) AS fue_update` que aparece en §4 también es de PostgreSQL y no del
estándar: es MVCC puro, `xmax` vale 0 en una fila recién insertada y devolvió `t` porque allí hubo
actualización.

---

---

**07 → 4.** ¿Qué guarda una vista normal y qué guarda una materializada? 🟢

⏱️ **30 segundos** — La vista normal guarda la consulta; la materializada guarda las filas. Por eso
solo la segunda puede quedarse vieja.

🗣️ **2 minutos** — Una vista es un nombre para un `SELECT` en el catálogo: no ocupa espacio de datos
y, cuando la consultas, el motor la expande —sustituye el nombre por su definición— y planifica el
resultado entero. Se ve en que el plan ni la menciona: en §6 queda un `Index Scan using
pedidos_codigo_key`, con el `WHERE` de fuera convertido en `Index Cond` y el de la definición en
`Filter`, cuatro páginas y ningún resultado intermedio. La materializada, en cambio, escribe el
resultado en disco y hay que decidir cuándo se refresca.

🔬 **El detalle** — Medido sobre la misma consulta: viva, **366,176 ms**; desde la materializada,
**2,876 ms**, **127 veces menos**, a cambio de **3 600 kB** de disco y **857,911 ms** de `REFRESH`,
que **no es incremental** —vuelve a correr la consulta entera— y entre dos refrescos la vista
miente. **Motor:** PostgreSQL las tiene con refresco; MySQL 9.7.2 acepta la palabra `MATERIALIZED`
pero no tiene sentencia de refresco y deja `TABLE_ROWS` y `DATA_LENGTH` a `NULL`; SQLite 3.53.4 no
las tiene.

---

---

**07 → 5.** Distingue `ON CONFLICT DO NOTHING` de `DO UPDATE`: ¿cuál exige nombrar la columna, y por
qué? 🟡

⏱️ **30 segundos** — `DO UPDATE` exige nombrarla; `DO NOTHING` no. Porque para fusionar hay que
saber con qué fila, y para tragarse el choque no hace falta.

🗣️ **2 minutos** — `DO NOTHING` sin columnas vale para cualquier restricción única de la tabla: el
motor solo tiene que descartar la fila entrante. `DO UPDATE` necesita el *conflict target* porque
tiene que localizar la fila existente que va a actualizar, y `clientes` tiene dos candidatas
—`clientes_codigo_key` y `clientes_email_key`—, así que elegir por él sería adivinar. Si no lo
nombras, el error llega en planificación, antes de mirar un solo dato.

🔬 **El detalle** — El *conflict target* no es realmente una columna, es la forma de señalar un
índice: `ON CONFLICT (nombre)` falla con `there is no unique or exclusion constraint matching the ON
CONFLICT specification` aunque `nombre` exista como columna. **Motor:** todo esto es de PostgreSQL.
MySQL no permite elegir —`ON DUPLICATE KEY UPDATE` actualiza contra *cualquier* clave única—, que es
justo la garantía que se pierde al portar el lote.

---

---

**07 → 6.** `MINUS` y `EXCEPT`: ¿son lo mismo? Di qué acepta cada uno de los cuatro motores del
corpus. 🟡

⏱️ **30 segundos** — Semánticamente sí, pero `MINUS` es el nombre de Oracle y nunca fue el portable.
El nombre que funciona en los cuatro motores es `EXCEPT`.

🗣️ **2 minutos** — PostgreSQL 18.6 solo conoce `EXCEPT` y da error de sintaxis con `MINUS`. MySQL
9.7.2 tiene `EXCEPT` e `INTERSECT` desde 8.0.31 y responde `ERROR 1064` a `MINUS`. SQLite 3.53.4 usa
`EXCEPT` y da `Parse error` con `MINUS`. MariaDB 12.3.3 es la única de las cuatro que lo reconoce, y
con una condición medida: solo con `sql_mode='ORACLE'`; por defecto da el mismo `ERROR 1064`. Es
decir, los cuatro coinciden en `EXCEPT` y solo uno acepta `MINUS`, y bajo una bandera.

🔬 **El detalle** — **Dialecto de motor, no estándar.** La cláusula de ISO/IEC 9075 que define estos
operadores no está verificada en esta edición, pero lo que sí está medido es que los cuatro motores
coinciden en `UNION`, `UNION ALL`, `INTERSECT` y `EXCEPT` y divergen justo en `MINUS` y en las
variantes `ALL` de los dos últimos. La trampa de entrevista gemela es la contraria: decir que
*"MySQL solo tiene `UNION`"*, que describe un motor anterior a octubre de 2022.

---

---

**07 → 7.** ¿`RETURNING` es del estándar o del motor? Di qué hace cada uno de los cuatro. 🟡

⏱️ **30 segundos** — Del motor. PostgreSQL y SQLite lo tienen, MariaDB también, y MySQL 9.7.2 no:
responde `ERROR 1064`.

🗣️ **2 minutos** — En PostgreSQL está en `INSERT`, `UPDATE`, `DELETE` y, desde la 17, en `MERGE`
junto a `merge_action()`. SQLite lo tiene desde la 3.35. MariaDB 12.3.3 diverge aquí de MySQL:
**tiene `RETURNING` en `INSERT` y en `DELETE`** —medido—. Importa porque es lo que vuelve
diagnosticable una escritura idempotente: sin él, `INSERT 0 1` no te dice si insertó o actualizó, y
tienes que volver a consultar.

🔬 **El detalle** — El sustituto en MySQL es `ROW_COUNT()`, con una convención que hay que saberse:
vale **1 cuando insertó y 2 cuando actualizó** —medido—, y es también lo que delata a `REPLACE
INTO`. Que la norma lo incluya o no está **sin verificar**: ISO/IEC 9075 es de pago y en esta
edición solo se afirma del estándar que `MERGE` es suyo y `ON CONFLICT` no.

---

---

**07 → 8.** Un `CREATE VIEW` dentro de una transacción que luego se deshace: ¿qué queda en
PostgreSQL y qué queda en MySQL? 🟡

⏱️ **30 segundos** — En PostgreSQL no queda nada: el DDL es transaccional y el `ROLLBACK` borra la
vista. En MySQL queda la vista, porque el DDL confirma implícitamente.

🗣️ **2 minutos** — Es la diferencia que decide cómo se escribe el teardown de un laboratorio
compartido. En PostgreSQL basta envolver el `CREATE VIEW` en `BEGIN … ROLLBACK` y `pg_views` vuelve
a quedar vacío, que es exactamente como están hechas las pruebas de §6. En MySQL 9.7.2 el `CREATE
VIEW` cierra la transacción abierta y la crea de verdad, así que el teardown tiene que ser un `DROP
VIEW` explícito escrito junto al recurso, no al final de la serie. La misma asimetría aplica a
`REPLACE INTO`, que sí es DML y sí se deshizo con `ROLLBACK`.

🔬 **El detalle** — **Motor, sin duda.** SQLite también deshace el DDL de vistas con `ROLLBACK`; el
raro de los cuatro es MySQL, con su confirmación implícita antes y después de cada sentencia DDL. La
consecuencia práctica: cualquier migración MySQL que mezcle DDL y DML en la misma transacción no es
atómica, aunque el fichero lo parezca.

---

---

**07 → 9.** Alguien escribe `UNION` en un informe cuyas dos ramas filtran por estados distintos del
mismo pedido. Dale el argumento de coste con los números de §2. 🟠

⏱️ **30 segundos** — Si las ramas son disjuntas por construcción, el `HashAggregate` no quita ni un
duplicado y se paga entero: un 45 % más de tiempo y 5 657 kB de memoria por nada.

🗣️ **2 minutos** — El argumento se da con el plan, no con la opinión: el `Append` de abajo es
idéntico en las dos versiones —`shared hit=21540`—, así que la diferencia entera es el nodo de
deduplicación. Medido, 274,114 ms contra 189,145 ms. Un pedido no puede estar a la vez `PAGADO` y
`ENVIADO`, así que las dos ramas no comparten ninguna fila y el hash se construye para tirarlo.
Escribir `ALL` no es una optimización agresiva: es decir lo que ya sabes del dominio.

🔬 **El detalle** — El matiz que se falla: lo que decide si hay duplicados **no es el filtro, es la
columna proyectada**. El propio §2 filtra por dos estados disjuntos y aun así `UNION` recorta 520
000 filas a 49 993, porque proyecta `cliente_id` y un mismo cliente tiene pedidos en los dos
estados. Si el informe proyecta el pedido, no hay nada que quitar; si proyecta el cliente, sí. Y si
el hash no cabe en `work_mem`, el precio deja de ser memoria y pasa a ser ficheros temporales.

---

---

**07 → 10.** `pagos.referencia` es `UNIQUE` y admite nulos: explica por qué el upsert por
`referencia` no vuelve idempotente el lote de los pagos en efectivo. 🟠

⏱️ **30 segundos** — Porque `ON CONFLICT` consulta el índice único, y en ese índice dos nulos nunca
son iguales: el conflicto no se detecta y la fila se inserta siempre.

🗣️ **2 minutos** — `UNIQUE` no significa "no hay repetidos", significa "no hay dos valores iguales",
y `NULL` no es igual a nada, ni siquiera a otro `NULL`. Los **273 126** pagos en efectivo tienen
`referencia` a `NULL`, así que cada pasada del lote los vuelve a insertar sin error y sin aviso: el
trabajo parece idempotente porque no falla, y va duplicando filas en silencio. El arreglo no es
tocar el upsert, es el esquema: o la clave de negocio es `NOT NULL`, o para esas filas hace falta
otra clave de idempotencia.

🔬 **El detalle** — Esto viene de la lógica de tres valores, que está en
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md). **Motor:**
PostgreSQL admite varias filas con `NULL` en una columna `UNIQUE` por defecto, y desde la 15 existe
`UNIQUE NULLS NOT DISTINCT` para pedir lo contrario; esa cláusula no está medida en este capítulo.
Lo que sí está medido es el recuento: 273 126 de 820 000 pagos con la referencia nula.

---

---

**07 → 11.** ¿Por qué `MERGE` y `ON CONFLICT` fallan con errores distintos cuando la fuente trae dos
veces la misma clave, y qué revela esa diferencia sobre la concurrencia? 🟠

⏱️ **30 segundos** — Porque `MERGE` clasifica cada fila con la instantánea del principio y no vuelve
a mirar, y `ON CONFLICT` sí sabe que las dos apuntan al mismo destino.

🗣️ **2 minutos** — En §5, con `('REF-900000002', 10.00)` y `('REF-900000002', 20.00)` en la fuente,
`MERGE` marcó las dos como `NOT MATCHED`, las mandó a insertar y la segunda chocó contra el índice:
`duplicate key value violates unique constraint "pagos_referencia_key"`, un error de integridad
corriente. `ON CONFLICT` dio uno propio y más específico: `ON CONFLICT DO UPDATE command cannot
affect row a second time`. Los dos fallan, pero fallan distinto, y ese distinto es el mecanismo: `ON
CONFLICT` reintenta contra el índice dentro de la misma sentencia, `MERGE` no.

🔬 **El detalle** — Por eso **`MERGE` no es atómicamente equivalente a `ON CONFLICT` frente a
concurrencia**: lo que aquí produce la fuente duplicada, en producción lo produce otra sesión que
inserta la clave entre el `ON` y el `INSERT`. Honestidad del capítulo: ese caso concurrente **no se
reprodujo** —exigiría un `COMMIT` en una base compartida—, así que lo medido es el mecanismo
equivalente. **Categoría:** `MERGE` es del estándar y `ON CONFLICT` es de PostgreSQL, lo cual
invierte la intuición: aquí la extensión propietaria da la garantía mejor.

---

---

**07 → 12.** Un compañero propone `REPLACE INTO pedidos` para el lote nocturno. Da las tres
consecuencias medidas en §5, en orden de gravedad. 🟠

⏱️ **30 segundos** — `REPLACE` no actualiza: borra e inserta. Pierdes las filas hijas por cascada,
cambias el `id` y reinicias las columnas que no nombras.

🗣️ **2 minutos** — En orden de gravedad. Primera: **las seis líneas y los seis eventos de
`PED-99999` desaparecieron**, barridos por las foráneas `ON DELETE CASCADE` — es pérdida de datos, y
silenciosa. Segunda: el `id` pasó de 99999 a **1 000 004**, así que toda referencia externa
—integraciones, informes, enlaces— apunta a un pedido que ya no existe, y además consumes
`AUTO_INCREMENT` en cada pasada. Tercera: lo que no mencionas vuelve a su valor por defecto, porque
es una fila nueva. El verbo correcto, si lo que quieres es actualizar, es `ON DUPLICATE KEY UPDATE`.

🔬 **El detalle** — `ROW_COUNT()` a **2** lo delata: un `INSERT` limpio habría devuelto 1. La prueba
salió porque `PED-99999` está `ANULADO` y sin pagos; sobre `PED-00042`, cuya foránea desde `pagos`
es `NO ACTION`, el borrado habría fallado con un error de integridad, que es paradójicamente el
escenario bueno. **Convención falsa:** *"`REPLACE INTO` es el upsert de MySQL"* se repite desde
MySQL 4 y sobrevive porque en una tabla sin foráneas el resultado *parece* el mismo.

---

---

**07 → 13.** `EXCEPT` frente a `NOT EXISTS` para los pedidos sin pago: los dos dan 180 000, ¿por qué
el capítulo prefiere el segundo dentro de una consulta caliente? 🟠

⏱️ **30 segundos** — Porque `EXCEPT` obliga a resolver los dos lados enteros y a deduplicar,
mientras que `NOT EXISTS` le deja al planificador elegir un anti-join.

🗣️ **2 minutos** — El operador de conjunto impone la forma: materializa las dos ramas, las compara y
quita repetidos aunque no los haya. `NOT EXISTS` expresa la misma intención sin imponer nada, así
que el planificador puede usar el índice del lado de `pagos` y parar en el primer emparejamiento de
cada pedido. En una consulta caliente —la que corre mil veces al día— esa libertad es la diferencia;
en una reconciliación puntual, `EXCEPT` se lee mejor y da igual.

🔬 **El detalle** — Medido: `EXCEPT` tardó **767,933 ms** contra **635,727 ms** de `EXCEPT ALL`, y
esos 132 ms de diferencia son deduplicar un conjunto donde `id` **ya es único** por la clave
primaria, o sea, trabajo puro a cambio de nada. Si el operador de conjunto se queda, al menos se
escribe con `ALL`. La alternativa con `EXISTS` y `NOT EXISTS` se trata en
[`04`](04-agregacion-y-subconsultas.md).

---

---

**07 → 14.** `ON CONFLICT (nombre)` falla con `there is no unique or exclusion constraint
matching…`. Escribe el DDL mínimo que lo arreglaría en `clientes`, y di qué rompe ese DDL de los
datos actuales. 🔴

⏱️ **30 segundos** — `ALTER TABLE clientes ADD CONSTRAINT clientes_nombre_key UNIQUE (nombre);`. Y
el problema es que hoy pasaría sin quejarse, que es justo la trampa.

🗣️ **2 minutos** — El error es de planificación, no de datos: el upsert es una **decisión de
esquema**, y sin un índice único o una restricción de exclusión sobre la clave por la que quieres
ser idempotente, no existe. El DDL mínimo es esa restricción `UNIQUE`, que crea su índice único por
debajo. Lo que rompe no son los datos de hoy —`clientes` tiene 50 000 filas y 50 000 nombres
distintos, medido, así que el `ALTER` no encuentra ningún duplicado que le impida validar—, sino el
dominio: convierte un atributo descriptivo en clave de negocio y prohíbe para siempre dos clientes
homónimos, que es una regla que nadie pidió.

🔬 **El detalle** — El efecto concreto en el capítulo: el `INSERT` de §4, `('CLI-90002','Cliente
311', …)`, dejaría de dar el error de planificación y pasaría a dar `duplicate key value violates
unique constraint "clientes_nombre_key"`, porque `Cliente 311` ya existe como nombre del cliente
`CLI-00311` —comprobado—. Además el índice se mantiene en cada escritura. La respuesta buena en una
entrevista es no hacerlo: `clientes` ya tiene dos índices únicos, `clientes_codigo_key` y
`clientes_email_key`, y el upsert va por ahí.

---

---

**07 → 15.** Escribe el `MERGE` que aplica un lote del proveedor sobre `pagos` con sus tres ramas
—actualizar, borrar cuando el importe es cero, insertar— y devuelve qué le pasó a cada fila. 🔴

⏱️ **30 segundos** — Un `MERGE INTO pagos … USING (VALUES …) ON p.referencia = entrante.referencia`
con `WHEN MATCHED AND importe = 0 THEN DELETE`, `WHEN MATCHED THEN UPDATE`, `WHEN NOT MATCHED THEN
INSERT`, y `RETURNING merge_action()`.

🗣️ **2 minutos** — El artefacto es el de §5:

```sql
MERGE INTO pagos p
USING (VALUES ('REF-000000001', 7000.00), ('REF-000000003', 0.00),
              ('REF-900000001', 125.50)) AS entrante (referencia, importe)
   ON p.referencia = entrante.referencia
 WHEN MATCHED AND entrante.importe = 0 THEN DELETE
 WHEN MATCHED THEN UPDATE SET importe = entrante.importe
 WHEN NOT MATCHED THEN INSERT (pedido_id, metodo, importe, pagado_en, referencia)
      VALUES (42, 'TARJETA', entrante.importe, now(), entrante.referencia)
RETURNING merge_action() AS accion, p.id, p.referencia, p.importe;
```

Devolvió `UPDATE`, `DELETE` e `INSERT`, una por fila, en 2,648 ms, y en la borrada el `importe`
muestra el valor de **antes**. Lo que hay que saber defender es el orden: **gana la primera rama
cuyo predicado se cumple**, así que si el `DELETE` estuviera en segundo lugar el cero se habría
guardado como actualización.

🔬 **El detalle** — `RETURNING` con `merge_action()` existe en PostgreSQL **desde la 17**; `MERGE`
llegó en la 15. **Estándar:** `MERGE` sí es del estándar, y es lo que `ON CONFLICT` no puede hacer
—borrar, emparejar por una condición que no sea un índice único, y tratar distinto dos casos que
chocan con la misma clave—. Lo que no hereda es la atomicidad frente a concurrencia: clasifica con
su instantánea y no vuelve a mirar.

---

---

**07 → 16.** El mismo lote idempotente tiene que correr en PostgreSQL y en MySQL 9.7.2: escribe las
dos sentencias y señala qué garantía pierdes en MySQL. 🔴

⏱️ **30 segundos** — En PostgreSQL, `INSERT … ON CONFLICT (referencia) DO UPDATE … RETURNING`. En
MySQL, `INSERT … ON DUPLICATE KEY UPDATE`. Pierdes elegir contra qué clave única se resuelve el
conflicto, y pierdes `RETURNING`.

🗣️ **2 minutos** — PostgreSQL:

```sql
INSERT INTO pagos (pedido_id, metodo, importe, pagado_en, referencia)
VALUES (42, 'TARJETA', 125.50, now(), 'REF-000000001')
ON CONFLICT (referencia) DO UPDATE SET importe = EXCLUDED.importe
RETURNING id, referencia, importe, (xmax <> 0) AS fue_update;
```

MySQL 9.7.2:

```sql
INSERT INTO pagos (pedido_id, metodo, importe, pagado_en, referencia)
VALUES (42, 'TARJETA', 125.50, now(), 'REF-000000001') AS nuevo
ON DUPLICATE KEY UPDATE importe = nuevo.importe;
```

La primera garantía que se pierde es el *conflict target*: MySQL actualiza contra **cualquier**
clave única de la tabla sin que puedas decir cuál, así que si mañana alguien añade otra `UNIQUE`, el
lote cambia de comportamiento sin que nadie toque la consulta. La segunda es el diagnóstico: no hay
`RETURNING`, y te quedas con `ROW_COUNT()`, que vale **1 cuando insertó y 2 cuando actualizó**
—medido—.

🔬 **El detalle** — Lo que no se pone en su lugar es `REPLACE INTO`: parece el equivalente y es un
`DELETE` más un `INSERT`. **Motor:** ninguna de las dos formas es del estándar; la del estándar es
`MERGE`, y MySQL y MariaDB responden `ERROR 1064` a `MERGE`. MariaDB 12.3.3 sí tiene `RETURNING` en
`INSERT`, así que la pérdida de diagnóstico es de MySQL, no de la familia entera.

---

---

**07 → 17.** Un panel tarda 366 ms por consulta y lo abren 200 personas cada mañana. Da la secuencia
de diagnóstico y decisión —qué mides, en qué orden y qué artefacto creas al final— con los números
de §6. 🔴

⏱️ **30 segundos** — Primero `EXPLAIN (ANALYZE, BUFFERS)` de la consulta viva, luego cuánta
caducidad tolera quien lee, y solo entonces una vista materializada con su índice único y su
refresco programado.

🗣️ **2 minutos** — El orden importa. **Uno:** medir la consulta viva con el plan entero —366,176 ms
para agregar 49 999 clientes— y descartar que el problema sea un plan malo o un índice que falta,
porque una vista materializada sobre una consulta mal escrita congela el error. **Dos:** medir la
pregunta que no es técnica, cuánta caducidad tolera el panel; si es un cuadro de mando de mañana,
tolera horas. **Tres:** medir el precio del artefacto antes de crearlo: **3 600 kB** de disco,
**2,876 ms** de lectura —**127 veces menos**— y **857,911 ms** de `REFRESH`, que no es incremental.
**Cuatro:** crear la vista materializada más un índice único sobre `cliente`, y programar el
refresco. Con 200 aperturas, la cuenta se hace sola: 200 × 366 ms de trabajo repetido contra un solo
`REFRESH` de 858 ms.

🔬 **El detalle** — El índice único no es decorativo: `REFRESH MATERIALIZED VIEW … CONCURRENTLY` **no
bloquea las lecturas**, pero lo exige, y **no corre dentro de un bloque de transacción** —por eso en
§6 se usó la forma normal, que sí cabía en el `BEGIN … ROLLBACK` del laboratorio—. **Motor:** en
MySQL 9.7.2 y SQLite 3.53.4 este artefacto no existe, y el apaño es el mismo en los dos: una tabla
de resumen que rellenas tú, con su `INSERT … SELECT` periódico, su marca de última actualización y
el trabajo programado que la mantiene. Lo que nunca desaparece es la pregunta de la caducidad: entre
dos refrescos, la vista miente.

---

## Capítulo 08 — Dialectos

Las 20 preguntas de [`08`](08-dialectos.md).

**08 → 1.** Nombra las tres capas de portabilidad de §2 y pon un ejemplo de cada una. 🟢

⏱️ **30 segundos** — Núcleo, traducción y ruptura. Núcleo: `SELECT`, `JOIN … ON`, `GROUP BY`, las
restricciones y `BEGIN`/`COMMIT`, que corren igual en los cuatro. Traducción: la concatenación o el
límite de filas, que existen en todos pero se escriben distinto. Ruptura: `MERGE`, `RETURNING` o una
vista materializada, que en algún motor no existen.

🗣️ **2 minutos** — La utilidad de las tres capas es que te dicen qué te va a costar la migración
antes de intentarla. El núcleo no se toca. La capa de traducción es reescritura mecánica, y su
precio es legibilidad casi siempre y rendimiento a veces. La de ruptura es la cara: o la emulas con
otro mecanismo, o cambias la aplicación. Y lo que hace portable a un producto no es que todo su SQL
sea genérico, sino que lo específico esté concentrado en pocos sitios.

🔬 **El detalle** — Casi toda una aplicación CRUD vive en el núcleo. Lo de fuera no se reparte al
azar: se concentra en las consultas que alguien optimizó, que son justo las que más duelen.
**Categoría:** las tres capas son una clasificación de este corpus, no del estándar ni de ningún
manual.

---

---

**08 → 2.** ¿Qué devuelve `SELECT 'PED-00042' || ' — ' || 'PAGADO'` en MySQL 9.7.2, y por qué? 🟢

⏱️ **30 segundos** — Devuelve `0`. Para MySQL `||` es el `OR` lógico, no la concatenación: evalúa
`'PED-00042' OR ' — ' OR 'PAGADO'`, convierte cada cadena a número —las tres valen 0— y responde
falso.

🗣️ **2 minutos** — Lo grave no es que difiera, es que no falla: no hay `ERROR`, hay un `0` donde
esperabas una etiqueta. MariaDB 12.3.3 hace lo mismo, y PostgreSQL y SQLite concatenan. Tres de
cuatro coinciden y el cuarto miente en silencio. La forma portable es `CONCAT(codigo, ' — ',
estado)`, que los cuatro aceptan y que no cuesta tiempo, solo dos paréntesis.

🔬 **El detalle** — **Categoría: estándar contra motor.** La concatenación con `||` es la forma del
estándar y MySQL se aparta de ella; trae el interruptor desde hace veinte años —`SET
sql_mode='PIPES_AS_CONCAT'`, o `sql_mode='ANSI'`, que activa
`REAL_AS_FLOAT,PIPES_AS_CONCAT,ANSI_QUOTES,IGNORE_SPACE,ONLY_FULL_GROUP_BY`— y casi nadie lo
enciende porque rompe el código heredado que usaba comillas dobles para cadenas.

---

---

**08 → 3.** ¿Cuál de los cuatro motores del corpus no tiene `FULL OUTER JOIN`? 🟢

⏱️ **30 segundos** — MySQL 9.7.2. Responde `ERROR 1064` de sintaxis, con `OUTER` y sin él, y MariaDB
12.3.3 igual. PostgreSQL lo tiene siempre y SQLite desde la 3.39.0.

🗣️ **2 minutos** — El apaño portable es un `LEFT JOIN` unido con `UNION ALL` al anti-join del otro
lado, con un `WHERE … IS NULL` en el segundo brazo para no duplicar las parejas ya emparejadas. Da
exactamente las mismas filas: 880 000 en la conciliación de pedidos anulados contra pagos.

🔬 **El detalle** — Corrido contra PostgreSQL para aislar la escritura del motor, el apaño tarda
**297,223 ms frente a 172,666 ms** del nativo, y sobre cinco pasadas la mediana fue 300 ms contra
164 ms: **1,7×**. La razón es de mecanismo, no de optimizador: el `FULL` recorre `pagos` una vez y
el apaño lo recorre dos, una por brazo.

---

---

**08 → 4.** En un `ORDER BY` ascendente, ¿dónde coloca los nulos PostgreSQL y dónde los colocan los
otros tres? 🟢

⏱️ **30 segundos** — PostgreSQL los pone **al final**; MySQL, MariaDB y SQLite los ponen **al
principio**. Medido sobre los 273 126 nulos de `pagos.referencia`.

🗣️ **2 minutos** — Es la divergencia más silenciosa del capítulo, porque no da error: la primera
página de un informe paginado sale con tres referencias reales en PostgreSQL y con tres celdas
vacías en MySQL. Se controla con `NULLS FIRST`/`NULLS LAST`, que PostgreSQL y SQLite aceptan y MySQL
y MariaDB rechazan con `ERROR 1064`. La forma que corre en los cuatro es `ORDER BY referencia IS
NULL, referencia`.

🔬 **El detalle** — **Categoría: no verificado en el estándar.** No he leído la cláusula de ISO/IEC
9075 —es de pago—, así que lo afirmado es lo medido en los cuatro motores. Y la forma portable
cuesta: sobre `pagos.referencia`, que tiene índice único, pasa de 0,053 ms a 178,159 ms.

---

---

**08 → 5.** ¿Qué hace `SET sql_mode='ANSI'` en MySQL, y nombra dos cosas que **no** arregla? 🟢

⏱️ **30 segundos** — Activa de golpe
`REAL_AS_FLOAT,PIPES_AS_CONCAT,ANSI_QUOTES,IGNORE_SPACE,ONLY_FULL_GROUP_BY`: con él `||` concatena y
las comillas dobles vuelven a delimitar identificadores. No arregla ni `FILTER` ni `FULL OUTER JOIN`
—ni `NULLS LAST`, ni `MERGE`, ni `RETURNING`—.

🗣️ **2 minutos** — La distinción que hay detrás es útil en una entrevista: `sql_mode` cambia cómo se
**interpreta** lo que escribes, no lo que el motor **implementa**. Todo lo que falta por
implementación sigue faltando con `ANSI` encendido. Y casi nadie lo enciende, porque `ANSI_QUOTES`
rompe cualquier código heredado que usara comillas dobles para cadenas, que es la mitad del código
MySQL del mundo.

🔬 **El detalle** — **Categoría: motor.** `sql_mode` es un mecanismo propio de MySQL y MariaDB;
PostgreSQL y SQLite no tienen nada equivalente. MariaDB añade además `sql_mode='ORACLE'`, con el que
reconoce `MINUS` como sinónimo de `EXCEPT` — medido en el capítulo 07.

---

---

**08 → 6.** `LIMIT 3 OFFSET 2` y `OFFSET 2 ROWS FETCH FIRST 3 ROWS ONLY`: ¿cuál es la del estándar y
cuál corre en los cuatro motores? 🟡

⏱️ **30 segundos** — La del estándar es `OFFSET … FETCH FIRST …`, desde SQL:2008. La que corre en
los cuatro es `LIMIT 3 OFFSET 2`, que no es del estándar. Son objetivos distintos.

🗣️ **2 minutos** — La forma normalizada falla en dos de los cuatro motores del corpus: MySQL
responde `ERROR 1064` y SQLite `Parse error`; PostgreSQL y MariaDB la aceptan. La forma con `LIMIT`
la aceptan los cuatro, y el propio manual de PostgreSQL dice en su nota de compatibilidad que
`LIMIT` es sintaxis suya y de MySQL, no de la norma. Ese es el ejemplo con el que se explica la
tesis del capítulo.

🔬 **El detalle** — **Categoría: estándar contra motor**, y aquí sí con cita —de segunda mano— del
manual de PostgreSQL, no del texto de la norma, que es de pago. Ojo también con `LIMIT 2, 3` de
MySQL y SQLite: el primer número es el desplazamiento, al revés que en `LIMIT 3 OFFSET 2`. Escribe
siempre la forma con `OFFSET`.

---

---

**08 → 7.** Distingue "SQL estándar" de "SQL portable". Da un caso donde apuntan a formas distintas.
🟡

⏱️ **30 segundos** — "Estándar" es lo que manda ISO/IEC 9075; "portable" es lo que corre en los
motores que te importan. No coinciden, y a veces se oponen.

🗣️ **2 minutos** — El caso limpio es el límite de filas: `OFFSET … FETCH FIRST` es la forma de la
norma y falla en MySQL y SQLite; `LIMIT n OFFSET m` no está en la norma y corre en los cuatro. El
segundo caso es `MERGE`: es la sentencia de upsert del estándar y solo la tiene PostgreSQL, desde la
15; MySQL y SQLite responden error de sintaxis y hay que usar `ON DUPLICATE KEY UPDATE` o `ON
CONFLICT`.

🔬 **El detalle** — La causa de fondo es que **ningún motor implementa la norma entera y todos
implementan cosas que no están en ella**; el apéndice de conformidad de PostgreSQL lista lo que le
falta, servicio que pocos motores prestan. Por eso la pregunta útil nunca es "¿esto es ANSI?" sino
"¿esto corre en los motores de mi lista?".

---

---

**08 → 8.** ¿El nivel de aislamiento por defecto lo fija el estándar o cada motor? Di el de
PostgreSQL y el de MySQL. 🟡

⏱️ **30 segundos** — Lo fija cada motor. El estándar define los cuatro niveles, no cuál es el
predeterminado. PostgreSQL arranca en `read committed` y MySQL —y MariaDB— en `REPEATABLE-READ`.

🗣️ **2 minutos** — Es una de las diferencias que ninguna suite de pruebas detecta, porque no cambia
ni el SQL ni el resultado de una consulta aislada: cambia lo que ve una transacción larga. Mover una
aplicación de MySQL a PostgreSQL le quita, sin avisar, la estabilidad de lectura dentro de la
transacción de la que quizá dependía un informe o una comprobación de saldo.

🔬 **El detalle** — **Categoría: estándar para los niveles, motor para el defecto.** Comprobado en
sesión sobre este entorno: `SHOW default_transaction_isolation` da `read committed` en PostgreSQL, y
`@@session.transaction_isolation` da `REPEATABLE-READ` en MySQL 9.7.2 y en MariaDB 12.3.3. En SQLite
la pregunta casi no aplica: hay un solo escritor.

---

---

**08 → 9.** `"PAGADO"` entre comillas dobles: di qué hace cada motor y por qué la diferencia es de
categoría. 🟡

⏱️ **30 segundos** — En PostgreSQL y SQLite delimitan un **identificador**, así que `"PAGADO"` es
una columna que no existe y da error. En MySQL delimitan una **cadena** y la consulta funciona,
salvo con `ANSI_QUOTES`.

🗣️ **2 minutos** — La diferencia es de categoría porque no es que a un motor le falte algo: es que
el mismo carácter significa cosas distintas. Por eso el error de MySQL con `ANSI_QUOTES` encendido
es `Unknown column 'PAGADO'`, el mismo que da PostgreSQL. SQLite, además, lo dice con todas las
letras: *should this be a string literal in single-quotes?*.

🔬 **El detalle** — **Categoría: convención de motor sobre una regla del estándar.** Lo que se lleva
a la práctica es sencillo: **comillas simples para cadenas, comillas dobles solo para
identificadores**, y si un identificador necesita comillas, replantéate el nombre. Es la regla que
hace que el mismo SQL no cambie de significado al cambiar de motor.

---

---

**08 → 10.** MySQL y MariaDB: nombra tres divergencias medidas en este capítulo, con lo que hace
cada uno. 🟡

⏱️ **30 segundos** — Tres medidas: MariaDB acepta `OFFSET … FETCH FIRST` y MySQL no; MariaDB tiene
`RETURNING` en `INSERT` y `DELETE` y MySQL responde `ERROR 1064`; MariaDB no trae
`ONLY_FULL_GROUP_BY` activo y MySQL sí.

🗣️ **2 minutos** — La cuarta, si la piden: MariaDB reconoce `MINUS` como sinónimo de `EXCEPT`, pero
solo con `sql_mode='ORACLE'`. Y donde sí coinciden es en casi todo lo demás: `||` como `OR`,
comillas dobles para cadenas, división decimal, ausencia de `NULLS LAST`, de `FILTER` y de `MERGE`,
`REPEATABLE-READ` por defecto y DDL que confirma implícito.

🔬 **El detalle** — **Categoría: motor.** Tratarlos como un solo motor es un error que se paga en la
migración, y en la dirección menos esperada: el código escrito contra MariaDB con `RETURNING` o
`FETCH FIRST` no arranca en MySQL, aunque MariaDB naciera como su bifurcación. La compatibilidad va
perdiendo terreno en cada versión mayor de las dos.

---

---

**08 → 11.** Un informe con `sum(cantidad)/count(*)` se porta de MySQL a PostgreSQL y el número
baja. Explica el mecanismo y da la forma que devuelve lo mismo en los cuatro. 🟠

⏱️ **30 segundos** — Porque la división de dos enteros trunca en PostgreSQL y devuelve decimal en
MySQL. `PED-00043` tiene 11 unidades en 3 líneas: MySQL dice `3.6667` y PostgreSQL dice `3`.

🗣️ **2 minutos** — El mecanismo es el tipo del resultado: en PostgreSQL el operador `/` entre dos
enteros devuelve entero y descarta el resto; MySQL promueve a decimal. SQLite se comporta como
PostgreSQL, así que dos de tres coinciden y la respuesta que parece rara es la correcta. Nadie
sospecha de un informe que lleva dos años saliendo.

🔬 **El detalle** — La forma que devuelve lo mismo en los cuatro es **castear explícitamente uno de
los operandos**: `CAST(sum(cantidad) AS REAL) / count(*)`, o multiplicar por `1.0`. No es una
diferencia de portabilidad sintáctica —la consulta corre en todos— sino **semántica**, que es la
clase que no produce ningún error y por eso cuesta cara.

---

---

**08 → 12.** `FILTER` frente a `SUM(CASE WHEN …)` sale igual en tiempo, y `NULLS LAST` frente a su
forma portable sale 3 360× peor. ¿Qué distingue a los dos casos? 🟠

⏱️ **30 segundos** — Que `FILTER` y el `CASE` describen la misma agregación sobre las mismas filas,
mientras que `referencia IS NULL` envuelve una columna indexada en una **expresión** y con eso
desactiva el índice.

🗣️ **2 minutos** — En el primer caso el planificador produce literalmente el mismo árbol: mismo nodo
`Aggregate`, mismo coste estimado `37640.00..37640.01` y las mismas 17 640 páginas leídas; los
tiempos medidos fueron 54,861 ms y 56,285 ms, indistinguibles. En el segundo, `NULLS LAST` coincide
con el orden que el índice ya tiene y el `Limit` para en la tercera entrada, mientras que la forma
portable obliga a leer las 820 000 entradas y ordenarlas antes de quedarse con tres.

🔬 **El detalle** — Los números: 0,053 ms contra 178,159 ms —**3 360×**— y 5 páginas contra 2 353. De
ahí sale la regla práctica del capítulo: **el precio de una forma portable se predice preguntando si
envuelve una columna indexada en una expresión**. Si no, el precio es legibilidad; si sí, mídelo. Es
el mismo mecanismo que rompe un índice con `LOWER(email)` o con `CAST(total AS REAL)`.

---

---

**08 → 13.** El apaño de `FULL OUTER JOIN` con `UNION ALL` tarda 1,7× lo que el nativo sobre los
mismos datos. Explica de dónde sale ese factor mirando el mecanismo, no el plan. 🟠

⏱️ **30 segundos** — Porque el `FULL OUTER JOIN` nativo recorre `pagos` **una vez** y el apaño lo
recorre **dos**, una por cada brazo del `UNION ALL`.

🗣️ **2 minutos** — El apaño es un `LEFT JOIN` en el primer brazo y el anti-join del otro lado en el
segundo, con `WHERE p.id IS NULL` para no duplicar las parejas ya emparejadas. Ese segundo brazo
necesita volver a leer la tabla grande entera para descubrir qué filas no casaron. El nativo
construye una sola tabla de dispersión y va marcando las filas del lado derecho que quedaron sin
pareja mientras sondea, así que le basta una pasada.

🔬 **El detalle** — Medido contra PostgreSQL, con los dos sobre los mismos datos, para que la
comparación aísle la escritura y no el motor: **172,666 ms nativo contra 297,223 ms portable**, y
mediana de cinco pasadas de 164 ms contra 300 ms. Las 880 000 filas de resultado son idénticas. Es
el ejemplo de coste intermedio: se paga el doble, no tres mil veces, porque no se pierde ningún
índice.

---

---

**08 → 14.** Un compañero propone escribir todo el SQL en el mínimo común denominador "por si
acaso". Dale el argumento en contra y di en qué tres casos tendría razón. 🟠

⏱️ **30 segundos** — Que casi ningún producto cambia de motor, y el mínimo común denominador te
cuesta legibilidad todos los días y rendimiento a veces: hasta 3 360× en el caso medido. Es un
seguro caro contra un siniestro que probablemente no ocurra.

🗣️ **2 minutos** — Los tres casos donde sí tiene razón: un producto que se **instala en casa del
cliente**, donde el motor lo elige el cliente y la lista de motores soportados es una cláusula del
contrato; una **migración ya decidida y con fecha**, donde el cambio no es hipotético; y una
**biblioteca o framework** que otros van a apuntar contra un motor que no conoces. En los tres,
además, la suite de pruebas tiene que correr contra cada motor soportado, porque si no la
portabilidad es una intención.

🔬 **El detalle** — El matiz que cierra la discusión: **lo que hace portable a una aplicación no es
que su SQL sea genérico, sino que el SQL específico esté concentrado**. Si `RETURNING` aparece en
cuarenta sitios, la migración es imposible; si aparece en tres repositorios, es una tarde. Eso se
consigue con disciplina de diseño, no renunciando a `FILTER`.

---

---

**08 → 15.** ¿Por qué un ORM no te hace portable? Apóyate en la tabla de §3 para decir qué traduce y
qué no. 🟠

⏱️ **30 segundos** — Porque traduce el núcleo —`SELECT`, `JOIN`, `GROUP BY`, paginación, tipos
básicos— y poco más. Todo lo de la capa de ruptura lo acabas escribiendo a mano, y es justo lo que
no está en todos los motores.

🗣️ **2 minutos** — Mirando la tabla de §3: el ORM sí te resuelve el límite de filas, la
concatenación y el nombre de las funciones de fecha, porque son traducción mecánica. No te resuelve
`RETURNING`, `FILTER`, `MERGE`, las vistas materializadas, `jsonb` con `@>` ni los modos de marco de
ventana. Y todo lo que escribes en SQL nativo dentro del ORM —que en cualquier aplicación real es
una parte del total— pasa tal cual al motor.

🔬 **El detalle** — Y hay una segunda mitad que el ORM tampoco cubre y casi nadie mira: **el tipo del
dinero, la zona de la fecha, el aislamiento por defecto y qué pasa tras un error dentro de la
transacción**. Un ORM que genera SQL impecable no te salva de que MySQL siga ejecutando después de
un error y PostgreSQL no. **Categoría: convención.** *"Un ORM te hace portable"* es de las que más
se recitan y menos se comprueban.

---

---

**08 → 16.** Un lote inserta 10 000 filas en una transacción y falla en la 3 000. Di qué queda
confirmado en MySQL, qué queda en PostgreSQL y cómo lo igualas. 🟠

⏱️ **30 segundos** — En MySQL las 7 000 restantes se insertan y el `COMMIT` confirma un lote
incompleto que nadie marcó como roto. En PostgreSQL no entra ninguna: la transacción queda abortada
y rechaza todo hasta el `ROLLBACK`.

🗣️ **2 minutos** — La diferencia es de alcance del error: en PostgreSQL el fallo de una sentencia
envenena la transacción entera —`current transaction is aborted, commands ignored until end of
transaction block`, y el prompt pasa de `tienda=*#` a `tienda=!#`—; en MySQL y en SQLite el error es
de la sentencia y la siguiente corre como si nada. Comprobado en sesión en los tres.

🔬 **El detalle** — Se igualan con **un `SAVEPOINT` antes de cada sentencia que pueda fallar** y
`ROLLBACK TO SAVEPOINT` al capturarla: los cuatro motores lo tienen, y es del lenguaje de
aplicación, no del SQL. El sentido de la migración importa: portar ese lote de MySQL a PostgreSQL lo
mejora, porque deja de confirmar lotes a medias; portarlo al revés lo rompe en silencio.

---

---

**08 → 17.** Reescribe esta consulta para que corra sin cambios en los cuatro motores del corpus, y
di qué pierdes con cada cambio: `SELECT p.estado || ' / ' || c.pais AS grupo, count(*) FILTER (WHERE
p.total > 500) AS caros FROM pedidos p JOIN clientes c ON c.id = p.cliente_id GROUP BY p.estado,
c.pais ORDER BY grupo NULLS LAST OFFSET 10 ROWS FETCH FIRST 5 ROWS ONLY;` 🔴

⏱️ **30 segundos** — Cuatro cambios: `CONCAT` en vez de `||`, `SUM(CASE WHEN …)` en vez de `FILTER`,
`ORDER BY grupo IS NULL, grupo` en vez de `NULLS LAST`, y `LIMIT 5 OFFSET 10` en vez de `OFFSET …
FETCH FIRST`.

🗣️ **2 minutos** — Queda así: `SELECT CONCAT(p.estado, ' / ', c.pais) AS grupo, count(CASE WHEN
p.total > 500 THEN 1 END) AS caros FROM pedidos p JOIN clientes c ON c.id = p.cliente_id GROUP BY
p.estado, c.pais ORDER BY 1 LIMIT 5 OFFSET 10;`. El `JOIN … ON`, el `GROUP BY` y el `count` no se
tocan: son núcleo. Y conviene ordenar por posición o repetir la expresión, porque el alias en el
`ORDER BY` sí vale en los cuatro pero el alias dentro del `HAVING` no vale en PostgreSQL, y quien
escribe uno acaba escribiendo el otro.

🔬 **El detalle** — Qué pierdes con cada cambio: con `CONCAT`, legibilidad y nada más; con el `CASE`,
legibilidad y nada más —mismo plan, mismo coste, mismas páginas—; con el `IS NULL` en el `ORDER BY`,
**el índice**, que es donde está el precio real; y con `LIMIT`, nada, porque es la forma que corre
en los cuatro aunque no sea la del estándar. Aquí el grupo nunca es nulo, así que el `IS NULL` se
puede quitar del todo: **la forma portable más cara es la que se copia sin mirar si hay nulos**.

---

---

**08 → 18.** Da la lista de comprobación para portar una aplicación de MySQL 9.7.2 a PostgreSQL
18.6: qué revisas, en qué orden, y qué no detecta la suite de pruebas. 🔴

⏱️ **30 segundos** — Primero los tipos —dinero, fecha con zona y booleano—, después la semántica
silenciosa —división entera, orden de los nulos, comillas dobles—, después la sintaxis, que falla
ruidosa y se arregla sola, y al final el comportamiento transaccional.

🗣️ **2 minutos** — El orden no es caprichoso: va de lo que no produce error a lo que sí. (1)
`DECIMAL` a `numeric`, `TIMESTAMP`/`DATETIME` a `timestamptz` decidiendo qué era UTC, y `TINYINT(1)`
a `boolean` cuidando la conversión de `t`/`f` en la carga. (2) `sum(a)/count(*)` y cualquier
división entre enteros, el orden de los nulos en todo informe paginado, y las comillas dobles usadas
como cadena. (3) `||`, `LIMIT n,m`, `ON DUPLICATE KEY UPDATE`, alias en el `HAVING`, columnas no
agrupadas y `DATE_FORMAT`. (4) el aislamiento por defecto, que pasa de `REPEATABLE-READ` a `read
committed`, y el DDL, que en MySQL confirmaba implícito y ahora se deshace.

🔬 **El detalle** — Lo que la suite de pruebas no detecta, y hay que revisar a mano: **el aislamiento
por defecto, el orden de los nulos, el redondeo del dinero y que MySQL seguía ejecutando tras un
error dentro de la transacción**. Ninguna de las cuatro cambia el resultado de una consulta aislada,
que es lo único que una prueba unitaria mira. Y una advertencia de dirección: **probar contra un
motor embebido distinto del de producción no es probar la migración**, es probar otra cosa.

---

---

**08 → 19.** Escribe la conciliación de §4 —anulados contra pagos, con los dos descartes y la
intersección— en una forma que corra en los cuatro, y di qué le cuesta a cada uno. 🔴

⏱️ **30 segundos** — Con un `LEFT JOIN` unido por `UNION ALL` al anti-join del otro lado, contando
en la misma pasada los tres números con `SUM(CASE WHEN …)`. Es la única forma de las cuatro que
corre en MySQL.

🗣️ **2 minutos** — El esqueleto: el primer brazo es `(SELECT id FROM pedidos WHERE estado='ANULADO')
p LEFT JOIN pagos pg ON pg.pedido_id = p.id`; el segundo es `pagos pg LEFT JOIN (…) p ON
pg.pedido_id = p.id WHERE p.id IS NULL`. Envolviendo los dos en una subconsulta, los tres recuentos
salen con `count(CASE WHEN pago_id IS NULL THEN 1 END)`, `count(CASE WHEN pedido_id IS NULL THEN 1
END)` y el complementario. Da 880 000 filas: 60 000 anulados sin pago, 820 000 pagos que no son de
un anulado y cero en ambos lados.

🔬 **El detalle** — Qué le cuesta a cada uno. **PostgreSQL y SQLite pagan de más**, porque tienen
`FULL OUTER JOIN` nativo: medido en PostgreSQL, 297,223 ms contra 172,666 ms, un 1,7×. **MySQL no
paga nada extra**, porque no tiene alternativa. Y el `CASE` en vez de `FILTER` no cuesta tiempo en
ninguno: mismo plan, mismo coste, mismas páginas. **Es el resumen del capítulo: escribir portable
penaliza a los motores que sí tienen la función.**

---

---

**08 → 20.** Diseña el criterio con el que tu equipo decide, consulta a consulta, si usa la forma
portable o la del motor: tres reglas, aplicables sin medir cada vez. 🔴

⏱️ **30 segundos** — Tres reglas: el núcleo siempre portable; lo específico se usa cuando aporta y
se concentra en pocos sitios; y la forma portable se mide solo cuando envuelve una columna indexada
en una expresión.

🗣️ **2 minutos** — Aplicadas: (1) `JOIN … ON`, `GROUP BY`, `EXISTS` y las restricciones no tienen
alternativa específica que valga la pena, así que ahí la portabilidad sale gratis y no se discute.
(2) `FILTER`, `ON CONFLICT`, `RETURNING`, `jsonb` y las vistas materializadas existen porque
resuelven algo: se usan, se marcan y viven en el repositorio o en la capa de acceso, no esparcidos
por el código. (3) antes de aceptar una forma portable en una consulta caliente, se mira si toca un
índice; si lo toca, se mide con `EXPLAIN (ANALYZE, BUFFERS)` y si no, se acepta sin más trámite.

🔬 **El detalle** — Lo que hace aplicable el criterio sin medir cada vez es la regla 3, porque
convierte una pregunta empírica en una sintáctica: **¿hay una función o una expresión alrededor de
una columna indexada?** Con eso se separa el caso de 3 360× del caso de cero, que son los dos
extremos medidos en §4. Y una cuarta regla implícita, que es de equipo y no de consulta: **si la
lista de motores soportados no está escrita en algún sitio, no hay requisito de portabilidad, hay
una intuición.**

## Simulación de entrevista

Las 28 preguntas `S#` y los cuatro escenarios de [`09`](09-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**09 → S1.** **`pedidos.total` es `numeric(12,2)` en PostgreSQL y texto en SQLite, porque SQLite no
tiene decimal exacto. El mismo filtro `total > 1000` cuenta 481 887 filas en un motor y 451 468 en
el otro, sin un solo error. Explica el mecanismo y di cómo lo detectarías antes que contabilidad.
🟠**

⏱️ **30 segundos** — En SQLite la columna es texto, así que `total > 1000` es una comparación
alfabética, no numérica: `'999.50'` es mayor que `'1000.00'` porque compara carácter a carácter.
Salen 30 419 filas de diferencia y ningún error, porque para SQLite las dos cosas son comparables.

🗣️ **2 minutos** — El origen es que SQLite no tiene tipo decimal exacto: solo entero y real. El
corpus guarda `pedidos.total` como texto precisamente para no perder céntimos, y esa decisión —que
es la correcta para conservar el dato— convierte cualquier filtro o `ORDER BY` numérico en algo
distinto. No es un fallo de SQLite: es su modelo de afinidad, donde el tipo lo tiene el valor y no
la columna. La detección no es leer código, es **comparar recuentos entre motores sobre el mismo
conjunto de datos**: la misma consulta de control contra los cuatro, y cualquier divergencia se
investiga antes de creerse el número.

🔬 **El detalle** — Es **motor**, no estándar: el estándar distingue `NUMERIC` exacto de `FLOAT`
aproximado y SQLite no implementa esa categoría. La trampa de segundo orden es que la defensa obvia
—un `CHECK`— tampoco protege: `CHECK (cantidad > 0)` acepta la cadena `'tres'`, porque en el orden
de tipos de SQLite todo texto es mayor que todo número. La defensa real es declarar la tabla
`STRICT`, y aun así no aparece un decimal exacto: lo que aparece es el error cuando metes texto en
una columna numérica. Esto pertenece a la familia de divergencias que **no producen ningún error**,
que es la que hace daño de verdad al portar.

---

**09 → S2.** **Un servicio escribe `creado_en` en `timestamptz` desde tres regiones y un informe
agrupa por día. ¿Dónde se decide en qué día cae un pedido de las 23:40, y qué tiene que estar
escrito en algún sitio para que ese informe sea reproducible dentro de seis meses? 🟠**

⏱️ **30 segundos** — Lo decide la zona horaria de la sesión que corre el informe, no el dato.
`timestamptz` guarda un instante en UTC y lo renderiza en la zona de quien pregunta, así que el
mismo pedido cae en un día o en el siguiente según dónde se conecte el que lanza el informe.

🗣️ **2 minutos** — Lo que hay que tener claro es que `timestamptz` **no guarda ninguna zona**:
convierte a UTC al escribir y renderiza en `TimeZone` al leer. El `epoch` no cambia al cambiar `SET
timezone`; lo que cambia es la cadena que ves y, con ella, el `date_trunc('day', …)`. Para que el
informe sea reproducible hacen falta dos cosas escritas: **la zona en la que se define el día de
negocio** —que es una decisión del negocio, no del motor— y que el informe la fije explícitamente en
la consulta, con `AT TIME ZONE`, en vez de heredarla de la sesión.

🔬 **El detalle** — El caso que descoloca es el contrario: `timestamp` sin zona, que no convierte
nada y guarda un reloj de pared. Ese sí es reproducible y ese sí está mal, porque dos regiones
escriben el mismo número para dos instantes distintos. Al portar, la cosa se complica: el
`TIMESTAMP` de MySQL sí convierte, pero su `DATETIME` no, y SQLite no tiene tipo de fecha —es texto
ISO-8601—. `PED-00042` se lee `2025-02-21 03:08:09.349067+00` en PostgreSQL y sin sufijo en MySQL:
**el desplazamiento desaparece de la salida y con él la pista de que hubo una conversión.**

---

**09 → S3.** **Guardas la respuesta cruda del proveedor de pagos para poder auditarla más tarde.
¿`json` o `jsonb`? Nombra las dos cosas que decide la respuesta, y cuál de ellas es la que manda
aquí. 🟡**

⏱️ **30 segundos** — `json`. Las dos cosas que decide son **fidelidad del texto** y **velocidad de
consulta**, y aquí manda la fidelidad: si es una respuesta que hay que auditar, tiene que volver
byte a byte como llegó.

🗣️ **2 minutos** — `jsonb` guarda una representación binaria descompuesta: reordena las claves,
descarta las duplicadas y pierde los espacios del original. A cambio consulta rápido y admite
índices y operadores como `@>`. `json` guarda el texto tal cual y lo reparsea en cada acceso. Para
un documento que es prueba —una respuesta firmada, un recibo, algo que alguien va a comparar contra
lo que le mandó el proveedor— reordenar las claves invalida la firma, así que `json` es la única
opción. Si además hace falta consultar dentro con frecuencia, la salida es **las dos columnas**:
`json` para el original y `jsonb` derivada para consultar.

🔬 **El detalle** — Medido en el corpus: el mismo documento ocupó 75 bytes en `json` y 96 en `jsonb`.
El sentido de la diferencia sorprende, porque el discurso habitual es que `jsonb` es "igual pero
mejor". Y en portabilidad la distinción desaparece: MySQL tiene un solo `JSON`, binario y sin `@>`,
y SQLite guarda texto con funciones `json_*`. Es decir, **la pareja `json`/`jsonb` es de
PostgreSQL**, no del estándar, que desde SQL:2016 define SQL/JSON sin fijar dos tipos.

---

**09 → S4.** **`WHERE iva > 100`, con `iva` declarado como alias en el `SELECT`, falla en PostgreSQL
y devuelve filas en SQLite. Di si eso lo fija el estándar o el motor, y por qué el `ORDER BY` sí
acepta el alias en los cuatro. 🟡**

⏱️ **30 segundos** — Es **motor**. El orden lógico dice que el `WHERE` se evalúa antes que el
`SELECT`, así que cuando se filtra el alias todavía no existe: PostgreSQL y MySQL dan error y SQLite
lo acepta como extensión. El `ORDER BY` lo acepta en los cuatro porque se evalúa **después** del
`SELECT`, cuando el alias ya está creado.

🗣️ **2 minutos** — El orden lógico completo es `FROM` → `WHERE` → `GROUP BY` → `HAVING` → `SELECT` →
`DISTINCT` → `ORDER BY` → `LIMIT`, y los alias nacen en el sexto paso. De ahí sale toda la
asimetría: `WHERE` no los ve, `ORDER BY` sí, y `GROUP BY` y `HAVING` quedan en tierra de nadie, que
es donde cada motor hizo lo que quiso. PostgreSQL acepta el alias en el `GROUP BY` —extensión
declarada en su manual— y lo rechaza en el `HAVING` con `column "n" does not exist`; MySQL, MariaDB
y SQLite lo aceptan en los dos.

🔬 **El detalle** — La fila del `ORDER BY` es la única que sí puede citar el estándar con algo de
apoyo: en SQL-92 el alias vale ahí **y solo ahí**. Todo lo demás de esta pregunta es de motor. La
consecuencia práctica es la que se olvida: una consulta con alias en el `HAVING` que lleva años
corriendo en MySQL **no arranca** el día que se porta a PostgreSQL, y el error no habla de alias
sino de una columna que no existe, que es lo que despista.

---

**09 → S5.** **`ORDER BY estado LIMIT 5` devolvió cinco pedidos distintos en dos ejecuciones del
mismo motor, sobre los mismos datos y sin que nadie tocara nada. Explica qué cambió y da la
corrección, que cabe en una línea. 🟠**

⏱️ **30 segundos** — La ordenación no es **total**: hay 200 000 pedidos por estado y el `ORDER BY`
solo desempata por `estado`, así que cuáles son los cinco primeros lo decide el plan. Cambió el plan
—de `top-N heapsort` a `external merge` o al revés— y con él el desempate. Se corrige añadiendo una
columna única al final: `ORDER BY estado, id`.

🗣️ **2 minutos** — Esto es la versión sutil de "sin `ORDER BY` no hay orden". Con `ORDER BY` hay
orden, pero solo sobre lo que ordenas; el resto sigue siendo arbitrario, y `LIMIT` convierte lo
arbitrario en visible porque **elige** dentro del empate. El motor no está incumpliendo nada: está
devolviendo un resultado correcto de una consulta mal especificada. Cambia el plan por cosas que no
son "tocar nada": un `ANALYZE`, un cambio de `work_mem`, la caché caliente o fría, otra versión.

🔬 **El detalle** — La regla para llevarse a producción: **cualquier consulta con `LIMIT` necesita
una ordenación total**, y la forma barata de conseguirla es añadir la clave primaria como último
criterio. El coste suele ser cero porque el desempate solo actúa dentro del grupo empatado. Y hay un
corolario que se olvida: si la API pagina, la ordenación total no es una mejora estética, es lo
único que impide que una fila salga en dos páginas seguidas —que es exactamente el escenario 2—.

---

**09 → S6.** **Una API pagina con `LIMIT 20 OFFSET :n`. En la página 45 000 tarda 631,392 ms y en la
0 tarda 0,432 ms, con el mismo plan. Explica por qué, y di qué le cambia el orden de magnitud. 🟠**

⏱️ **30 segundos** — `OFFSET` no salta: **produce** las 900 000 filas anteriores y las descarta. Por
eso el plan es el mismo y el tiempo no: el trabajo está en el nodo hijo, que devuelve 900 020 filas
en vez de 20. Es O(n) sobre el desplazamiento.

🗣️ **2 minutos** — Se ve en el `rows=` del nodo hijo del `Limit`: ahí está la cuenta real de filas
producidas. El plan no cambia porque la forma de la consulta no cambia; lo único que cambia es
cuántas filas atraviesan el nodo antes de que el `Limit` corte. Lo que le cambia el orden de
magnitud es **dejar de contar filas y empezar a posicionarse por valor**: paginación por cursor,
`WHERE (estado, id) > (:ultimo_estado, :ultimo_id) ORDER BY estado, id LIMIT 20`. Con el índice
adecuado eso es una búsqueda en el árbol, no un recorrido, y tarda lo mismo en la página 0 que en la
45 000.

🔬 **El detalle** — La paginación por cursor tiene un precio que hay que decir en la misma frase:
**no permite saltar a una página arbitraria**. Si el producto exige un selector de página, la
respuesta honesta no es técnica, es de producto: o se acota el desplazamiento máximo, o se acepta la
degradación, o se cambia la interfaz por "siguiente/anterior" y un buscador. Y una segunda trampa:
el cursor solo funciona si la ordenación es total, por lo mismo que `S5`. Las dos preguntas son la
misma vista desde dos sitios.

---

**09 → S7.** **¿Por qué `SELECT *` puede convertir un `Index Only Scan` en un `Index Scan`, y qué le
cuesta eso a la consulta cuando la tabla es grande? 🟡**

⏱️ **30 segundos** — Porque el *index-only scan* solo es posible si **todas** las columnas que pides
están en el índice. Al pedir todas las columnas de la tabla, el motor tiene que ir a buscar la fila
completa al montón, y el nodo pasa a `Index Scan`: una lectura de índice más una lectura de tabla
por fila.

🗣️ **2 minutos** — El precio se mide en páginas leídas, y crece con cuántas filas devuelve la
consulta: para unas pocas es despreciable y para un rango grande es la diferencia entre leer el
índice y leer media tabla en orden aleatorio. En la sesión del capítulo las dos formas leyeron las
mismas 13 páginas, porque eran pocas filas y estaban en la caché; eso no invalida el mecanismo, lo
acota: **el `Index Only Scan` se pierde siempre, el coste se nota cuando hay volumen.**

🔬 **El detalle** — Las otras dos razones contra `SELECT *` en código desplegado son de contrato, no
de rendimiento: rompe el consumidor el día que alguien añade una columna, y rompe los ORM que mapean
por posición. Pero la frase *"nunca uses `SELECT *`"* es **convención**, no regla de ningún motor ni
del estándar, y en una sesión interactiva es exactamente lo que quieres. Recitarla como dogma sin
saber cuál de las tres razones aplica es justo lo que detecta la entrevista.

---

**09 → S8.** **Un informe une `pedidos` con `pedido_lineas` y suma `p.total`. Di por cuánto está
inflado el resultado sin mirar los datos, y de dónde sale ese factor. 🟢**

⏱️ **30 segundos** — Por **3,5**, que es el número medio de líneas por pedido: 3 500 000 líneas
entre 1 000 000 de pedidos. Un join produce parejas, no columnas, así que cada `p.total` se cuenta
una vez por línea del pedido.

🗣️ **2 minutos** — El join no devuelve un millón de filas con más columnas: devuelve 3 500 000
filas, una por pareja. Todo agregado que toque una columna de la tabla "de uno" —`sum(p.total)`,
`count(*)`, `avg(p.total)`— cuenta esa fila tantas veces como parejas tenga. Es el error que más se
repite en informes, y se llama *fan-out* o trampa del abanico. La señal de alarma es que el número
sube al añadir un join que "solo era para mostrar un dato más".

🔬 **El detalle** — El factor no es uniforme: 3,5 es la media, y por cliente concreto puede ser
cualquier cosa. Eso hace el error **más** peligroso, porque el total global sí es reconocible como
absurdo pero un cliente suelto no. Y explica por qué `DISTINCT` no arregla nada cuando hay dos
tablas hijas: las filas duplicadas difieren en la columna de la otra hija, así que no son duplicados
exactos y `DISTINCT` las conserva todas.

---

**09 → S9.** **Un compañero arregla ese informe añadiendo `DISTINCT`. Di en qué caso `DISTINCT`
arregla algo de verdad, en cuál no, y cuáles son las dos escrituras correctas. 🟠**

⏱️ **30 segundos** — `DISTINCT` solo arregla el **recuento**, y solo si las filas duplicadas son
idénticas. No arregla la **suma**, y con dos tablas hijas ni siquiera arregla el recuento, porque
las filas difieren en la columna de la otra hija. Las dos escrituras correctas son: agregar cada
hija por separado en su propia subconsulta y unir los resultados, o usar `EXISTS` cuando lo único
que quieres es saber si hay pareja.

🗣️ **2 minutos** — La razón por la que `DISTINCT` tienta es que el recuento sí mejora y parece que
la consulta "ya está bien". Pero `DISTINCT` opera sobre la fila proyectada entera, no sobre la
columna que te interesa: en el corpus, `DISTINCT estado` da 5 filas y `DISTINCT estado, cliente_id`
da 229 700. Si la fila lleva la columna de la otra hija, cada combinación es distinta y sobreviven
todas. La forma correcta es no dejar que el join multiplique: cada agregado se calcula sobre su
propia tabla y luego se juntan por la clave del pedido.

🔬 **El detalle** — La tercera escritura correcta, que es la más elegante cuando solo hace falta un
agregado, es la subconsulta en la lista de selección con agregado. Tiene su propio precio, y está
medido: en la lista de selección una correlacionada no se aplana, y con veinte filas de salida da
`loops=20` y 606 ms. En el `WHERE` sí se aplana a un semi-join y no cuesta nada. **La frase "una
correlacionada siempre es lenta" es falsa; lo preciso es que duele en la lista de selección.**

---

**09 → S10.** **Mover un predicado del `ON` al `WHERE` de un `LEFT JOIN` pasó el informe de 50 000
clientes a 34 876. Di qué decidió el planificador y en qué se ve en el plan. 🟡**

⏱️ **30 segundos** — Convirtió el externo en interno. Un predicado del `WHERE` sobre la tabla
derecha rechaza los nulos que el propio `LEFT JOIN` acababa de fabricar, así que las filas sin
pareja se descartan después de crearse: el join deja de aportar nada y el planificador lo degrada.
En el plan, `Hash Right Join` pasa a `Hash Join`.

🗣️ **2 minutos** — La diferencia semántica es la que hay que decir: en el `ON`, el predicado decide
**qué se empareja**; en el `WHERE`, decide **qué filas sobreviven al join**. Con un interno da
igual, porque no hay filas fabricadas. Con un externo, el `WHERE` que menciona la tabla derecha la
convierte en interno casi siempre, porque `columna = valor` es falso cuando la columna es nula. El
manual de MySQL le da nombre propio a esta transformación: *outer join simplification*.

🔬 **El detalle** — El caso que no cae en la trampa es `WHERE pg.id IS NULL`, que es justo lo
contrario: pide las filas fabricadas y por eso el externo se conserva. Es la escritura del anti-join
clásico. La convención que produce el error —*"los filtros van en el `WHERE`, que es donde van los
filtros"*— viene de la sintaxis de coma, donde no había `ON` y todo iba junto, y es exactamente lo
que rompe un externo.

---

**09 → S11.** **Unir por `pagos.referencia`, que tiene 273 126 nulos, no empareja ni una fila. Un
compañero propone `IS NOT DISTINCT FROM` "para no perder los nulos". Respóndele en dos frases: una
sobre lo que consigue y otra sobre lo que cuesta. 🟠**

⏱️ **30 segundos** — Consigue que los nulos se emparejen entre sí, que casi nunca es lo que quieres:
`NULL` es ausencia de información, y emparejar dos ausencias produce un producto cartesiano de 273
126 por 273 126 filas que no significan nada. Y cuesta el índice: `IS NOT DISTINCT FROM` no es una
igualdad, así que el motor no puede usar el índice de `referencia` y el join pasa a recorrer.

🗣️ **2 minutos** — El punto de partida es que una fila con la clave de unión nula **ni se une
consigo misma**: 273 126 candidatos, 0 parejas, y eso es correcto, no un fallo. La pregunta real no
es cómo emparejar los nulos, es **qué significa un pago sin referencia** en el dominio. Si significa
"pago manual", la respuesta es filtrarlos y tratarlos aparte; si significa "todavía no llegó la
referencia", es un estado y debería tener su columna. Proponer un comparador para taparlo es
resolver un problema de modelo con sintaxis.

🔬 **El detalle** — La portabilidad remata el argumento: `IS NOT DISTINCT FROM` es la forma larga y
MySQL **no la tiene** —da error de sintaxis—; su comparador es `<=>`. SQLite tiene las dos. Así que
la propuesta, además de ser semánticamente dudosa y de matar el índice, ata la consulta a dos de los
cuatro motores. Tres razones independientes, y la primera es la que hay que decir antes.

---

**09 → S12.** **Solo quieres saber si hay pareja, no traerla. Da las tres escrituras posibles, di
cuál prefieres y qué nodo esperas ver en el plan si el planificador te hace caso. 🟡**

⏱️ **30 segundos** — `EXISTS`, `IN` y `JOIN … DISTINCT`. Prefiero `EXISTS`: dice exactamente lo que
quiero, no puede multiplicar filas y deja al motor elegir un semi-join. En el plan espero `Hash Semi
Join`.

🗣️ **2 minutos** — `IN` afirmativo da el mismo plan y el mismo tiempo que `EXISTS` —medido: `Hash
Semi Join` en los dos, 503,821 ms contra 572,838 ms—, así que la elección entre esos dos es de
legibilidad. El `JOIN` es el que se descarta, porque solo es equivalente si la tabla derecha es
única por la columna de unión; sobre `pedido_lineas` infla la suma un 314 %. La versión negativa es
otra historia: `NOT EXISTS` da `Hash Anti Join` y 459,781 ms, y `NOT IN` se fue de tres minutos y
medio sin terminar.

🔬 **El detalle** — Semi-join y anti-join **no tienen sintaxis propia** en ningún motor del corpus:
son decisiones del planificador que se piden escribiendo `EXISTS` o `NOT EXISTS` y se comprueban en
el plan. Los nombres varían —`Anti Join` en PostgreSQL, `antijoin` en MySQL— pero el concepto es el
mismo. Que no haya sintaxis es lo que hace que mucha gente no sepa que existen, y por eso escriben
`LEFT JOIN … IS NULL`, que da el mismo resultado construyendo antes todas las parejas.

---
**09 → S13.** **`count(*)`, `count(referencia)` y `count(DISTINCT referencia)` sobre `pagos` dan
tres números distintos. Dilos, y di qué pregunta del negocio responde cada uno. 🟡**

⏱️ **30 segundos** — `count(*)` da 820 000 y responde *"cuántos pagos hay"*. `count(referencia)` da
546 874, ignora los nulos y responde *"cuántos pagos traen referencia"*. `count(DISTINCT
referencia)` da 546 874 también, porque la columna es única, y responde *"cuántas referencias
distintas hay"*.

🗣️ **2 minutos** — La regla es que `count(*)` cuenta filas y `count(expresión)` cuenta valores no
nulos de esa expresión. La diferencia entre los dos primeros son exactamente los 273 126 pagos sin
referencia, que es el mismo número que aparece en los joins que no emparejan y en el upsert que
duplica: **es el mismo hecho del dominio visto desde tres sitios distintos.** El tercero coincide
con el segundo aquí solo porque hay un `UNIQUE`; en una columna sin restricción los tres números
serían distintos.

🔬 **El detalle** — La comparación que descoloca es `count(DISTINCT referencia)` contra `SELECT
DISTINCT referencia`: 546 874 contra 546 875. El agregado ignora el nulo y la deduplicación lo
cuenta como una fila más, porque para `DISTINCT` todos los nulos son el mismo valor. Es la misma
asimetría de siempre —`NULL` no participa en agregados pero sí agrupa— y es de estándar, no de
motor: los cuatro hacen lo mismo.

---

**09 → S14.** **La media por método salió 7726,29 con la condición en el `WHERE` y 5171,35 con la
misma condición en el `HAVING`. Di cuál responde a *"media de los pedidos no anulados"* y por qué la
otra no está mal escrita: está respondiendo otra pregunta. 🟠**

⏱️ **30 segundos** — La del `WHERE`, 7726,29. El `WHERE` elige **qué filas entran al agregado**, así
que los anulados no cuentan en la media. El `HAVING` elige **qué grupos salen** después de
calcularla: los anulados ya están dentro del promedio y lo único que hace es esconder grupos enteros
del informe.

🗣️ **2 minutos** — Las dos consultas son SQL correcto y las dos devuelven un número verdadero de
algo; lo que cambia es de qué. Con la condición en el `HAVING`, el grupo "TARJETA" se calcula sobre
todos sus pedidos, anulados incluidos, y luego se decide si se muestra. Con la condición en el
`WHERE`, los anulados desaparecen antes de que exista el grupo. La frase que resume la distinción
es: **`WHERE` filtra filas, `HAVING` filtra grupos**, y por eso `HAVING` es el único que puede
mencionar un agregado.

🔬 **El detalle** — La versión de esta misma confusión que rompe informes sin cambiar ningún número
es la de `01/06` vista en el bloque anterior: mover `estado <> 'ANULADO'` de un sitio a otro pasó un
informe de seis clientes a tres, porque el predicado rechaza nulos. Y hay un remate de motor: el
alias de la lista de selección funciona en el `HAVING` de MySQL, MariaDB y SQLite, y PostgreSQL lo
rechaza con `column "media" does not exist`. Así que la consulta "limpia" que alguien escribió con
alias en el `HAVING` no arranca al portarla.

---

**09 → S15.** **"`EXISTS` siempre es más rápido que `IN`." Corrige la frase con los números del
bloque, y di dónde está la diferencia de verdad entre las dos formas. 🟡**

⏱️ **30 segundos** — En afirmativo es falsa: los dos dan el mismo `Hash Semi Join` y prácticamente
el mismo tiempo, 503,821 ms contra 572,838 ms. La diferencia de verdad está en la forma negativa, y
es **semántica antes que de plan**: `NOT IN` con un solo nulo en la lista no devuelve nada.

🗣️ **2 minutos** — La frase viene de los Oracle y los SQL Server de hace veinte años, donde `IN` se
materializaba y `EXISTS` no, y sobrevive porque suena a regla. Sobre este entorno, `NOT EXISTS` da
`Hash Anti Join` y 459,781 ms, `LEFT JOIN … IS NULL` da `Hash Right Join` más un filtro y 467,534
ms, y `NOT IN` se canceló a los 3 minutos y 23 segundos. Pero antes del tiempo está el resultado:
`NOT IN` sobre una columna con nulos devuelve cero filas, y cero filas es una respuesta que nadie
cuestiona.

🔬 **El detalle** — El mecanismo es el de la lógica de tres valores: `x NOT IN (a, b, NULL)` se
deriva a `x <> a AND x <> b AND x <> NULL`, y esa última comparación es `UNKNOWN`, que con `AND`
nunca deja pasar la fila. La lentitud es consecuencia de lo mismo: el motor no puede usar un
anti-join porque tendría que preservar esa semántica, así que cae en `Materialize` más bucle
anidado. **Lo preciso es "`EXISTS` e `IN` afirmativos son el mismo semi-join; `NOT IN` es otra cosa,
y lo es por los nulos antes que por el plan".**

---

**09 → S16.** **Escribes la comprobación que corre antes de cada despliegue para detectar los `NOT
IN` peligrosos del repositorio. Di qué los hace peligrosos, qué buscas exactamente, y por qué no
vale con mirar los planes. 🔴**

⏱️ **30 segundos** — Peligroso es un `NOT IN` cuya subconsulta devuelve una columna que **admite
nulos**. Busco los `NOT IN (SELECT …)` del repositorio, extraigo la columna proyectada y la cruzo
contra el catálogo: si `is_nullable` es `YES` y no hay un `WHERE … IS NOT NULL` dentro, es un
hallazgo. Los planes no sirven porque el problema aparece el día que entra el primer nulo, y ese día
el plan no ha cambiado.

🗣️ **2 minutos** — La comprobación tiene dos mitades. La estática es un `grep` sobre el código en
busca de `NOT IN (SELECT`, que es barato y encuentra casi todo. La dinámica consulta
`information_schema.columns` por la columna de cada subconsulta y filtra las que admiten nulos. El
hallazgo se arregla de una de tres formas: `NOT EXISTS`, que es equivalente y correcto; añadir
`WHERE columna IS NOT NULL` dentro; o declarar la columna `NOT NULL` si el dominio lo permite, que
es la que arregla la causa.

🔬 **El detalle** — Lo que hace esto digno de una comprobación automática y no de una revisión humana
es que **el fallo no produce error, no cambia el plan y no aparece en las pruebas**: devuelve cero
filas, que es un resultado plausible. Un informe de conciliación que lleva meses devolviendo filas y
de repente devuelve cero es exactamente esta clase de fallo, y el primer instinto de todo el mundo
es pensar que ya no hay nada que conciliar. Es el escenario 2 del bloque 01, y es el mismo hecho:
273 126 nulos que nadie declaró.

---

**09 → S17.** **"Las CTE son lentas porque materializan." Di desde cuándo dejó de ser cierto, qué
palabra la vuelve a hacer cierta, y qué le cuesta esa palabra cuando la pones sin pensar. 🟡**

⏱️ **30 segundos** — Dejó de ser cierto en PostgreSQL 12, de octubre de 2019: desde entonces una CTE
no recursiva, sin efectos secundarios y usada una sola vez se integra en la consulta. La palabra que
la vuelve a hacer cierta es `MATERIALIZED`, y lo que cuesta es que **impide empujar el filtro
dentro**: la CTE se calcula entera y se descarta casi todo.

🗣️ **2 minutos** — Medido en el capítulo: 0,136 ms integrada contra 283,995 ms materializada, sobre
la misma consulta. Con `MATERIALIZED`, el ejemplo del capítulo escribe 47 MB de disco temporal y
descarta 999 999 de las filas producidas, porque el `WHERE` de fuera ya no puede colarse dentro de
la CTE. `MATERIALIZED` **no es una optimización: es una prohibición**, y tiene sus usos —forzar que
algo se calcule una sola vez cuando se referencia varias, o aislar una CTE con efectos secundarios—,
pero ponerla "para que el plan sea estable" es pagar un peaje por nada.

🔬 **El detalle** — Las tres condiciones para que PostgreSQL integre son: no recursiva, sin efectos
secundarios y **usada una sola vez**. La tercera es la que se olvida, y explica el caso inverso: una
CTE referenciada dos veces se materializa igualmente, así que marcarla `NOT MATERIALIZED` la hace
más lenta, porque se calcula dos veces. En portabilidad, MySQL no tiene ninguna de las dos palabras
—`ERROR 1064`— y las funde siempre; SQLite tiene las dos.

---

**09 → S18.** **Una consulta recursiva no vuelve en producción. Di qué hace cada motor del corpus
cuando eso pasa —quién te para y quién no— y cuáles son las dos defensas que tienes que escribir tú.
🟠**

⏱️ **30 segundos** — MySQL y MariaDB te paran a las 1 000 vueltas: `cte_max_recursion_depth` y
`max_recursive_iterations`, con `ERROR 3636` en MySQL. PostgreSQL y SQLite **no tienen tope**:
crecen hasta agotar el disco temporal o hasta que salte un `statement_timeout`. Las dos defensas son
una columna de profundidad con su corte —`WHERE nivel < 50`— y `UNION` en vez de `UNION ALL` cuando
el grafo puede tener ciclos.

🗣️ **2 minutos** — El diagnóstico empieza por saber si es un ciclo o un crecimiento legítimo, y eso
se ve acotando: se le pone un `LIMIT` o un corte de nivel bajo y se mira si las filas que vuelven se
repiten. La columna de nivel sirve para las dos cosas: para cortar y para diagnosticar. El
`statement_timeout` no es una defensa de la consulta, es una defensa de la base: evita que una
recursión se coma el disco, pero no te dice qué pasó.

🔬 **El detalle** — La trampa que hay que saber es que **`UNION` no siempre corta el ciclo**. Corta
si las filas repetidas son idénticas; si la CTE arrastra un `nivel` acumulado, `('audio', 3)` y
`('audio', 6)` son filas distintas y el bucle sigue igual. PostgreSQL tiene desde la 14 una cláusula
dedicada, `CYCLE … SET … USING …`, que detecta ciclos sin depender de eso; MySQL y SQLite no la
tienen. Y `RECURSIVE` en sí es de motor: obligatoria en PostgreSQL y MySQL, opcional e ignorada en
SQLite.

---

**09 → S19.** **Un informe de acumulado mensual "cuadra al final pero miente en el medio". Da la
hipótesis más probable en una frase, el mecanismo exacto que la produce y el arreglo. 🟠**

⏱️ **30 segundos** — El marco por defecto. La ventana lleva `ORDER BY` y nadie escribió marco, así
que el motor pone `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`, que **agrupa los empates**:
todas las filas con el mismo valor de orden reciben el acumulado del grupo entero. Al final coincide
porque el último acumulado es la suma total; en el medio salta. El arreglo es escribir el marco:
`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

🗣️ **2 minutos** — `ROWS` cuenta filas y `RANGE` compara valores del `ORDER BY`. Coinciden solo si
ese orden no tiene repetidos, y un acumulado por día con varias filas por día los tiene siempre. En
el capítulo el acumulado salta de 99 a 143 y repite 143, mientras que con `ROWS` da 121 y 143. Los
cuatro motores del corpus ponen el mismo marco por defecto, así que esto no se arregla cambiando de
motor: se arregla escribiéndolo.

🔬 **El detalle** — Hay un caso donde `RANGE` es la respuesta correcta y `ROWS` la equivocada, y
conviene tenerlo listo para no sonar dogmático: cuando lo que quieres es precisamente *"todo lo que
ocurrió hasta este instante"* y las filas del mismo instante tienen que entrar juntas —un cierre por
día, una foto a una fecha—. Ahí contar filas daría un resultado que depende del orden arbitrario
dentro del empate. **La regla no es "usa `ROWS`", es "escribe el marco y sabe cuál de los dos
pediste".**

---

**09 → S20.** **La misma consulta de ranking tiene que dar el mismo número de puesto en PostgreSQL,
MySQL, MariaDB y SQLite. Di qué lo impide hoy y qué escribes para garantizarlo. 🔴**

⏱️ **30 segundos** — Lo impide que el `ORDER BY` de la ventana tenga empates: `ROW_NUMBER` los
reparte como quiera y no todos lo hacen igual. Medido sobre tres clientes empatados en 20
pedidos: 8-9-7 en PostgreSQL y en MariaDB, 7-8-9 en MySQL y en SQLite. Se garantiza
**haciendo total el orden de la ventana**: añadir `cliente_id` como último criterio.

🗣️ **2 minutos** — No es un fallo de ningún motor: `ROW_NUMBER` no puede ser determinista sin un
orden total, porque la pregunta *"cuál de estos tres empatados es el séptimo"* no tiene respuesta.
Si lo que quieres es que los empatados compartan puesto, la función correcta es otra: `RANK` da 4,
4, 6 y `DENSE_RANK` da 4, 4, 5. Elegir entre las tres es una decisión de negocio —si hay dos
segundos, ¿el siguiente es tercero o cuarto?— y conviene preguntarla en voz alta antes de escribir.

🔬 **El detalle** — La portabilidad completa de esta consulta tiene una segunda capa, que es la que
descoloca: aunque el orden sea total, si la consulta usa `FILTER` sobre la ventana o los modos de
marco `GROUPS` y `EXCLUDE`, MySQL y MariaDB dan `ERROR 1064` y `ERROR 1235`. Y MariaDB además
rechaza `RANGE BETWEEN INTERVAL … PRECEDING`, que MySQL sí acepta. Las ventanas están en los cuatro
motores desde 2018, pero **no el mismo subconjunto**.

---

**09 → S21.** **`pagos.referencia` es `UNIQUE` y admite nulos. Explica por qué el lote "idempotente"
que se apoya en esa columna duplica filas cada noche sin dar ningún error. 🟡**

⏱️ **30 segundos** — Porque un `UNIQUE` no restringe los nulos: varios `NULL` conviven bajo la misma
restricción, ya que `NULL = NULL` no es verdadero. Los 273 126 pagos sin referencia no chocan con
nada, así que el `ON CONFLICT` no se dispara y se insertan otra vez, cada noche, sin error.

🗣️ **2 minutos** — El upsert no compara valores: **consulta un índice único o una restricción de
exclusión**. Si la fila entrante no colisiona en ese índice, para el motor es una fila nueva y
punto. Con una columna que admite nulos, la idempotencia es una propiedad que solo tienen las filas
que traen valor. El arreglo es de modelo antes que de SQL: o la referencia es obligatoria y se
declara `NOT NULL`, o el lote necesita otra clave de idempotencia —el par proveedor más
identificador del fichero, por ejemplo— y esa sí se declara `NOT NULL UNIQUE`.

🔬 **El detalle** — La comprobación que detecta esto antes de que pase es contar: si `count(*)` menos
`count(columna_de_conflicto)` es distinto de cero, el lote no es idempotente para esas filas, y el
número es exactamente cuántas se van a duplicar por ejecución. Aquí, 273 126 por noche. Y hay una
vuelta de tuerca: `ON CONFLICT` sin índice que lo sostenga ni siquiera arranca, falla con `there is
no unique or exclusion constraint matching the ON CONFLICT specification` —que es el caso fácil,
porque al menos avisa—.

---

**09 → S22.** **Un compañero propone `REPLACE INTO pedidos` para el lote nocturno de MySQL. Da tres
consecuencias concretas y di cuál de las tres es la que rompe datos que nadie estaba mirando. 🟠**

⏱️ **30 segundos** — `REPLACE` no actualiza: **borra la fila y la inserta**. Uno, cambia el `id`,
así que cualquier referencia externa a ese identificador deja de apuntar a lo mismo. Dos, dispara
los `ON DELETE CASCADE`: las líneas y los pagos del pedido desaparecen. Tres, reinicia a su valor
por defecto todas las columnas que el lote no nombra. La segunda es la que rompe datos que nadie
estaba mirando.

🗣️ **2 minutos** — La convención *"`REPLACE INTO` es el upsert de MySQL"* se repite desde MySQL 4 y
viene de que existió años antes que `ON DUPLICATE KEY UPDATE`, que es el upsert de verdad de MySQL.
La tercera consecuencia es traicionera de otra manera: un lote que actualiza tres columnas de un
fichero deja las demás en su defecto, y si el pedido tenía una marca de revisión manual, se pierde
sin rastro. Ninguna de las tres da error.

🔬 **El detalle** — El borrado en cascada es el que no se ve porque el lote termina bien, el recuento
de `pedidos` es el mismo y solo `pedido_lineas` adelgaza. La detección es comparar el total de
líneas antes y después del lote, que es una comprobación de una línea que nadie pone. La alternativa
correcta en MySQL es `INSERT … ON DUPLICATE KEY UPDATE` nombrando las columnas; en PostgreSQL,
`INSERT … ON CONFLICT DO UPDATE`; y `MERGE`, que es la del estándar, la tiene PostgreSQL desde la 15
y ni MySQL ni SQLite.

---

**09 → S23.** **Un panel tarda 366 ms por consulta y lo abren 200 personas cada mañana. Alguien dice
*"hazla materializada"*. Di qué cambia exactamente, qué no cambia, y cuál es la pregunta que hay que
hacer antes de decidir. 🟠**

⏱️ **30 segundos** — Cambia dónde se paga: la lectura baja a 2,876 ms y aparece un `REFRESH` de
857,911 ms que hay que correr en algún sitio. No cambia el coste de la consulta, que es el mismo;
solo se ejecuta una vez en vez de doscientas. Y aparece algo nuevo que antes no existía: **datos
viejos entre un refresco y el siguiente**. La pregunta previa es cuántos minutos puede envejecer el
dato.

🗣️ **2 minutos** — Una vista normal no cambia nada: guarda la consulta, el motor la expande antes de
planificar y el plan ni la menciona. Si la vista va lenta, lo que va lenta es la consulta de dentro.
La materializada sí guarda filas, y por eso introduce las tres preguntas de toda caché: cuándo se
refresca, qué pasa si el refresco falla, y quién se entera de que el dato está viejo. Con 200
aperturas contra un refresco por hora, la aritmética sale a favor con mucho margen; con un requisito
de "siempre al día", no sale, porque ese requisito prohíbe la caché por definición.

🔬 **El detalle** — El `REFRESH` normal bloquea las lecturas mientras corre; en PostgreSQL existe
`REFRESH … CONCURRENTLY`, que no bloquea pero exige un índice único sobre la vista y tarda más. Y en
portabilidad esto no existe fuera de PostgreSQL: MySQL acepta la palabra pero **no tiene
`REFRESH`**, y SQLite da `Parse error`. Así que "hazla materializada" en un corpus de cuatro motores
es también una decisión de atarse a uno.

---
**09 → S24.** **"Si es ANSI, funciona en todos." Desmóntalo con el caso del límite de filas, y di
cuál es la lectura general que se saca de ahí. 🟠**

⏱️ **30 segundos** — Al revés de lo que suena. `OFFSET 2 ROWS FETCH FIRST 3 ROWS ONLY` es la forma
del estándar desde SQL:2008 y **falla en MySQL y en SQLite**; `LIMIT 3 OFFSET 2` no es del estándar
—es sintaxis propia de PostgreSQL y MySQL, y su manual lo dice— y corre en los cuatro. La lectura
general es que **lo estándar y lo portable no son lo mismo, y a veces son formas opuestas**.

🗣️ **2 minutos** — El mismo caso se repite con `MERGE`: es la sentencia de upsert del estándar y la
tiene un motor de cuatro. La razón de fondo es que ningún motor implementa la norma entera y todos
implementan cosas que no están en ella; el propio apéndice de conformidad de PostgreSQL lista lo que
le falta. La convención viene de los años en que los vendedores certificaban el nivel *Entry* de
SQL-92 y lo ponían en el folleto, y sobrevive porque suena a garantía.

🔬 **El detalle** — El remate para una entrevista es que **escribir "SQL estándar" y escribir "SQL
que corre en todas partes" son dos objetivos distintos**, y hay que saber cuál te están pidiendo.
MariaDB añade el matiz que descoloca: acepta `OFFSET … FETCH FIRST` aunque MySQL no, así que ni
siquiera "MySQL y MariaDB son el mismo motor" se sostiene. Divergen en cuatro filas medidas: `FETCH
FIRST`, `RETURNING`, `MINUS` con `sql_mode='ORACLE'` y `ONLY_FULL_GROUP_BY`, que MariaDB no trae
activo.

---

**09 → S25.** **¿Qué devuelve `SELECT 'PED-00042' || ' — ' || 'PAGADO'` en MySQL 9.7.2, y por qué
eso no es un error de sintaxis sino un resultado? 🟡**

⏱️ **30 segundos** — Devuelve `0`. En MySQL `||` es el `OR` lógico, no la concatenación: evalúa tres
cadenas como booleanos, ninguna empieza por un dígito distinto de cero, así que las tres valen falso
y el `OR` da 0. No hay error porque la expresión es válida; lo que cambia es el significado del
operador.

🗣️ **2 minutos** — Es el ejemplo canónico de la divergencia que más daño hace: la que **no produce
error**. Un `ERROR 1064` se arregla en dos minutos; una columna que devuelve `0` donde esperabas una
etiqueta se cuela en un informe. En PostgreSQL y SQLite `||` concatena, como manda el estándar. En
MySQL se puede arreglar con `SET sql_mode='PIPES_AS_CONCAT'`, pero eso cambia el comportamiento de
la sesión entera, no de la consulta; la forma portable es `CONCAT(…)`, que está en los tres.

🔬 **El detalle** — Hay otras dos de la misma familia, y conviene nombrarlas juntas porque tienen la
misma forma: las comillas dobles, que delimitan identificador en PostgreSQL y SQLite y **cadena** en
MySQL salvo `ANSI_QUOTES`; y la división entera, que da `3` para `11/3` en PostgreSQL y SQLite y
`3.6667` en MySQL. Esta última es la peor de las tres, porque un informe portado de MySQL a
PostgreSQL **baja de valor sin avisar** y el número sigue siendo plausible.

---

**09 → S26.** **Un lote inserta 10 000 filas dentro de una transacción y falla en la 3 000. Di qué
queda confirmado en PostgreSQL, qué queda confirmado en MySQL, cuál de los dos comportamientos es
más peligroso y cuál es el arreglo que funciona en los cuatro motores. 🔴**

⏱️ **30 segundos** — En PostgreSQL no entra ninguna: el error aborta la transacción entera y todo lo
que venga después se rechaza con `current transaction is aborted`. En MySQL y SQLite el error es de
la sentencia, no de la transacción: las 7 000 restantes se insertan y el `COMMIT` confirma un lote
incompleto. El peligroso es el de MySQL, porque **nadie marcó el lote como roto**. El arreglo
portable es un `SAVEPOINT` antes de cada sentencia que pueda fallar, y `ROLLBACK TO SAVEPOINT` al
capturarla.

🗣️ **2 minutos** — En PostgreSQL el aviso está hasta en el prompt de `psql`, que pasa de `tienda=*#`
a `tienda=!#`. El comportamiento de PostgreSQL es incómodo y correcto: te obliga a decidir. El de
MySQL es cómodo y silencioso: termina, confirma y deja una carga parcial que se descubre días
después cuadrando totales. **Portar ese lote de MySQL a PostgreSQL lo mejora; portarlo al revés lo
rompe en silencio.**

🔬 **El detalle** — El `SAVEPOINT` lo tienen los cuatro motores, y es la única defensa que no depende
del motor: con él, el lote decide explícitamente si una fila que falla se salta o aborta todo, en
vez de heredar la decisión del proveedor. Esta divergencia pertenece a la familia de cinco que no
están en el SQL sino debajo —el tipo del dinero, la fecha con zona, el booleano, el aislamiento por
defecto y esta—, y ninguna aparece en la lista de comprobación de nadie.

---

**09 → S27.** **"Un ORM te hace portable." Di qué traduce de verdad y nombra cinco cosas que vas a
escribir tú a mano y que no están en todos los motores. 🟠**

⏱️ **30 segundos** — Traduce el núcleo: `SELECT`, `JOIN … ON`, `WHERE`, `GROUP BY`, los tipos
básicos y el `LIMIT`. Lo que escribes tú a mano son `RETURNING`, `FILTER`, `MERGE`, `jsonb` con sus
operadores y las vistas materializadas — y son justo los que no están en todos.

🗣️ **2 minutos** — La lista no es arbitraria: coincide casi fila a fila con la tabla de divergencias
del capítulo, y por una razón estructural. El ORM traduce lo que es común, porque esa es su
definición de trabajo; en cuanto necesitas algo que le da ventaja a tu motor, sales del ORM y
escribes SQL, y ahí estás exactamente en la capa que no se porta. Se puede añadir a la lista la
sintaxis de upsert, que son tres formas distintas para lo mismo, y el orden de los nulos.

🔬 **El detalle** — El agujero que el ORM tampoco tapa, y que es el que de verdad cuesta caro, es lo
que no es SQL: el tipo que guarda el dinero, la zona de la fecha, si existe booleano, el nivel de
aislamiento por defecto —`read committed` en PostgreSQL, `REPEATABLE-READ` en MySQL y MariaDB— y qué
queda vivo después de un error. **Lo que se rompe al cambiar de motor no es el SQL: es el contrato
que no escribiste.**

---

**09 → S28.** **Tu equipo decide escribir todo el SQL en el mínimo común denominador "por si acaso".
Da el argumento que convierte esa petición en una decisión medible en vez de una intuición. 🔴**

⏱️ **30 segundos** — La pregunta previa es: **¿está escrita en algún sitio la lista de motores que
hay que soportar?** Si no lo está, no hay un requisito de portabilidad, hay una intuición, y se está
pagando un precio por un escenario que nadie ha comprometido. Si lo está, el criterio deja de ser
"por si acaso" y pasa a ser una regla que se aplica consulta a consulta.

🗣️ **2 minutos** — Con la lista escrita, el criterio tiene tres reglas. Una: donde la forma portable
no tiene alternativa mejor —`JOIN … ON`, `GROUP BY`, `EXISTS`, las restricciones— la portabilidad
sale gratis y no se discute. Dos: lo que existe porque resuelve algo —`FILTER`, `ON CONFLICT`,
`RETURNING`, `jsonb`, vistas materializadas— se usa, se marca y vive en un sitio concreto, la capa
de acceso o el repositorio, no esparcido por el código. Tres: antes de aceptar una forma portable en
una consulta caliente, se mira si toca un índice.

🔬 **El detalle** — Lo que hace aplicable la tercera regla sin medir cada vez es que convierte una
pregunta empírica en una sintáctica: **¿hay una función o una expresión alrededor de una columna
indexada?** Con eso se separan los dos extremos medidos en el capítulo. El orden de nulos portable
sobre `pagos.referencia` pasa de 0,053 ms a 178,159 ms y de 5 páginas a 2 353 —**3 360×**— porque
envuelve la columna indexada. Y `FILTER` frente a `SUM(CASE WHEN …)` da el mismo plan, el mismo
coste estimado y las mismas 17 640 páginas: ahí el precio es legibilidad, no tiempo. **Ni "escribir
portable no cuesta nada" ni "escribir portable siempre cuesta": depende de si tocas el índice, y eso
se ve mirando.**

---

**09 → E1.** **Escenario 1 — El informe que infla el importe**

⏱️ **30 segundos** — Es la trampa del abanico con dos tablas hijas. Unir `pedidos` con
`pedido_lineas` y con `eventos_pedido` multiplica cada pedido por sus líneas **y** por sus eventos,
así que `sum(p.total)` cuenta cada total tantas veces como el producto de las dos. No hace falta
mirar datos: el factor es predecible desde los recuentos de las tablas.

🗣️ **2 minutos** — Las dos reescrituras correctas son: agregar cada hija por separado —una
subconsulta que suma líneas por pedido, otra que cuenta eventos por pedido— y unir los dos
resultados por `pedido_id`; o dejar el join de líneas y sustituir el de eventos por un `count(*)
FILTER` sobre una agregación aparte, o por `EXISTS` si lo único que se quería era saber si hay
eventos. Elijo la primera, porque escala a una tercera hija sin volver a pensar y porque deja
explícito en el SQL qué se agrega sobre qué. La segunda es válida cuando solo hay una hija.

🔬 **El detalle — qué se está evaluando** — Tres cosas, y el orden importa. Primero, **si detectas el
mecanismo sin mirar los datos**: un join produce parejas, y el 314 % no es un misterio, es
aritmética de cardinalidades. Segundo, **si propones una comprobación en vez de solo un arreglo**;
la buena es contar filas antes y después de añadir un join —`SELECT count(*)` con y sin él— y exigir
que coincidan cuando el join no debería multiplicar, que es una línea en la revisión de código.
Tercero, **si evitas el `DISTINCT`**: con dos hijas ni siquiera funciona, porque las filas difieren
en la columna de la otra hija y no son duplicados exactos. Quien propone `DISTINCT` aquí está
tapando un síntoma que además no se tapa.

---

**09 → E2.** **Escenario 2 — La paginación que repite filas**

⏱️ **30 segundos** — Son dos problemas distintos con la misma causa aparente. El de las filas
repetidas es que `ORDER BY estado` **no es una ordenación total**: dentro del empate el orden lo
decide el plan, y entre dos peticiones puede cambiar. El de la lentitud es que `OFFSET` produce y
descarta todas las filas anteriores. El índice que piden no arregla ninguno de los dos del todo.

🗣️ **2 minutos** — El primero se arregla con `ORDER BY estado, id`: una columna única al final hace
total la ordenación y la página deja de bailar. El segundo se arregla cambiando de técnica, no de
índice: paginación por cursor, `WHERE (estado, id) > (:ultimo_estado, :ultimo_id) ORDER BY estado,
id LIMIT 20`, que con un índice sobre `(estado, id)` es una búsqueda en el árbol y tarda lo mismo en
cualquier página. El índice por sí solo puede ayudar al orden, pero no convierte el `OFFSET` en
O(1): las filas se siguen produciendo, aunque sea leyéndolas del índice.

🔬 **El detalle — qué se está evaluando** — Lo primero, **si separas los dos síntomas** en vez de
buscar una causa única; llegan juntos en el mismo ticket y no lo son. Lo segundo, **si concedes algo
al diseño actual**: si el producto expone un selector de página que salta a la 45 000, el cursor no
sirve, y la respuesta honesta es que hay que elegir —acotar el desplazamiento máximo, aceptar la
degradación en la cola, o cambiar la interfaz—. Lo tercero, **si arreglas la ordenación total en los
dos casos**, porque el cursor también la necesita: sin ella, `(estado, id) >` no define una
secuencia. Rechazar el índice sin más sería tan malo como aceptarlo sin más: ayuda, pero a otra
cosa.

---

**09 → E3.** **Escenario 3 — El lote que tiene que correr en los cuatro motores**

⏱️ **30 segundos** — Tres escrituras: `INSERT … ON CONFLICT (…) DO UPDATE` en PostgreSQL y SQLite,
`INSERT … ON DUPLICATE KEY UPDATE` en MySQL. `MERGE` es la del estándar y **solo la tiene
PostgreSQL**, así que la del estándar es justo la que no sirve aquí. Y hoy el lote no es idempotente
aunque `referencia` sea `UNIQUE`, porque admite nulos: los 273 126 pagos sin referencia se
reinsertan en cada ejecución sin error.

🗣️ **2 minutos** — El arreglo de la idempotencia es de modelo: hace falta una clave de idempotencia
**`NOT NULL UNIQUE`**, y si la referencia del proveedor puede faltar, esa clave tiene que ser otra
cosa —el par del fichero y su número de línea, por ejemplo—. Sobre la práctica de probar en SQLite
lo que corre en PostgreSQL, la recomendación es clara: **probar contra otro motor del que corre en
producción es probar otra cosa**. Aquí es peor de lo normal, porque los tres motores implicados
difieren exactamente en la sentencia que el lote usa, y además en qué pasa tras un error dentro de
la transacción.

🔬 **El detalle — qué se está evaluando** — Primero, **si distingues estándar de portable** sin que
haya que preguntártelo: el escenario está montado para que quien recite "usa `MERGE`, que es el
estándar" entregue algo que no arranca en dos de los tres entornos. Segundo, **si ves que el
problema de fondo no es de sintaxis sino de clave**: se puede escribir el upsert perfecto en los
tres motores y seguir duplicando. Tercero, **si dices algo sobre los entornos** en vez de aceptar
que son un dato inmutable; la respuesta completa incluye recomendar que integración y desarrollo
corran el motor de producción, y decir qué riesgo concreto se está asumiendo mientras no sea así.

---

**09 → E4.** **Escenario 4 — El panel que tiene que estar siempre al día**

⏱️ **30 segundos** — Los dos requisitos son incompatibles tal como están escritos, y eso es lo
primero que hay que decir. "Siempre al día" y "50 ms sobre una consulta de 366 ms" solo se cumplen a
la vez si el dato se precalcula, y precalcular es exactamente dejar de estar al día. **Esto no lo
resuelve la base de datos**: lo resuelve acordar cuántos minutos puede envejecer el dato.

🗣️ **2 minutos** — Con ese acuerdo, la base de datos aporta mucho. Una vista materializada baja la
lectura a 2,876 ms y mueve el coste a un `REFRESH` de 857,911 ms que corre una vez por periodo en
vez de doscientas por mañana; la aritmética sale a favor con margen enorme. Lo que **no** cambia es
el coste de la consulta en sí, y lo que aparece nuevo son las tres preguntas de toda caché: cada
cuánto se refresca, qué pasa si el refresco falla, y cómo sabe el que mira el panel de cuándo son
los datos. Esa última se resuelve poniendo la marca de tiempo del refresco en el propio panel, que
además convierte la conversación en algo que negocio puede ver.

🔬 **El detalle — qué se está evaluando** — Lo que se evalúa es **si discutes el encuadre antes de
resolver**. Aceptar el marco —*"lo materializo y ya"*— entrega un panel que en algún momento muestra
datos de hace una hora sin que nadie lo sepa, y el fallo aparece el día que alguien toma una
decisión con él. La respuesta de Tech Lead pregunta cuánto puede envejecer el dato, y con la
respuesta en la mano elige: si son minutos, materializada con refresco programado; si son segundos,
hay que mirar por qué la consulta tarda 366 ms antes de cachear nada; si de verdad tiene que ser
instantáneo, el camino es otro —mantener el agregado al escribir— y eso ya no es una vista, es un
cambio de diseño con su propio coste. **Hay una trampa secundaria**: alguien dirá "pues una vista
normal". Una vista normal no guarda filas, guarda la consulta, y el plan ni la menciona; no cambia
absolutamente nada del tiempo.

---

---

**Volver:** [README del bloque](README.md) · **Primer capítulo:**
[`01`](01-familias-del-lenguaje-y-tipos.md).
