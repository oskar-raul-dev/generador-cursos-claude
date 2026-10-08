# 01 — Familias del lenguaje y tipos

> SQL no es un lenguaje, son cuatro familias con reglas distintas —DDL, DML, DCL y TCL—, y la
> frontera que más duele es cuál se puede deshacer. Después, la otra mitad: los tipos donde se
> pierde dinero, se pierde la hora y se pierde el emoji. **Asume leído:**
> [`06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) — de ahí viene
> que un nulo no es un valor, y aquí reaparece dentro de un `jsonb`. **Vigencia:** 20 de septiembre
> de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema)
- [2. Las cuatro familias, y cuál se puede deshacer](#2--las-cuatro-familias-y-cuál-se-puede-deshacer)
- [3. Dinero: `numeric` frente a coma flotante](#3--dinero-numeric-frente-a-coma-flotante)
- [4. Tiempo: `timestamptz` guarda un instante; `timestamp`, un reloj de pared](#4--tiempo-timestamptz-guarda-un-instante-timestamp-un-reloj-de-pared)
- [5. Texto: `char` paga el relleno, y el `utf8` de MySQL no es UTF-8](#5--texto-char-paga-el-relleno-y-el-utf8-de-mysql-no-es-utf-8)
- [6. `uuid`, arrays y la pareja `json` / `jsonb`](#6--uuid-arrays-y-la-pareja-json--jsonb)
- [7. SQLite: el tipo lo tiene el valor, no la columna](#7--sqlite-el-tipo-lo-tiene-el-valor-no-la-columna)
- [8. Estándar, motor y convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes)
- [Para profundizar](#-para-profundizar)
- [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Contabilidad pide el importe total facturado: 3 500 000 líneas de pedido y una consulta de una
línea. La escribes dos veces, sobre la columna tal como está declarada —`numeric(12,2)`— y
convirtiendo a `double precision`, que es lo que hace cualquier lenguaje que lea ese resultado en un
`float`.

```text
tienda=# SELECT sum(cantidad * precio_unit)                   AS exacto_numeric,
tienda-#        sum(cantidad * precio_unit::double precision) AS aproximado_float
tienda-#   FROM pedido_lineas;
 exacto_numeric | aproximado_float
----------------+-------------------
  5178452860.88 | 5178452860.875059
(1 fila)

Duración: 977,255 ms
```

Los dos números salen de las mismas filas y no son el mismo número. Medio céntimo sobre cinco mil
millones, invisible hasta que el cierre mensual no cuadra. No es un error de la consulta ni del
motor: **es el tipo**. Eso, y qué familia de sentencias puedes deshacer, es el capítulo.

---

## 2. 🧱 Las cuatro familias, y cuál se puede deshacer

**Qué es.** El gremio reparte SQL en cuatro familias según lo que toca cada sentencia:

| Familia | Qué toca | Sentencias típicas |
|---|---|---|
| **DDL** *(Data Definition Language)* | La forma de los datos | `CREATE`, `ALTER`, `DROP`, `TRUNCATE` |
| **DML** *(Data Manipulation Language)* | Las filas | `INSERT`, `UPDATE`, `DELETE`, `SELECT` |
| **DCL** *(Data Control Language)* | Quién puede qué | `GRANT`, `REVOKE` |
| **TCL** *(Transaction Control Language)* | El límite de la transacción | `BEGIN`, `COMMIT`, `ROLLBACK` |

**Quién lo manda: convención.** ISO/IEC 9075 no usa esos cuatro nombres —habla de *SQL-schema
statements*, *SQL-data statements* y *SQL-transaction statements*— y **no he verificado la
cláusula**; lo verificable es que ningún manual de los tres motores se organiza así. Que el DDL de
PostgreSQL se deshaga con `ROLLBACK` y el de MySQL no está demostrado en
[`01/01`](../01-fundamentos-y-modelo-relacional/01-que-resuelve-un-dbms.md); lo que allí no está es
**qué dispara la confirmación implícita**, y no es solo el DDL:

```text
mysql> CREATE TABLE pagos_ensayo (id INT PRIMARY KEY, nota VARCHAR(20)) ENGINE=InnoDB;
mysql> START TRANSACTION;
mysql> INSERT INTO pagos_ensayo VALUES (1, 'antes del LOCK');
mysql> LOCK TABLES pagos_ensayo WRITE;
mysql> UNLOCK TABLES;
mysql> ROLLBACK;
mysql> SELECT count(*) AS tras_lock_tables FROM pagos_ensayo;
+------------------+
| tras_lock_tables |
+------------------+
|                1 |
+------------------+
```

- `LOCK TABLES` **no es DDL** y aun así confirmó lo pendiente. La lista de MySQL 9.7.2 incluye
  además `START TRANSACTION` —abrir una confirma la anterior—, `SET autocommit = 1`, `TRUNCATE
  TABLE`, `ANALYZE TABLE` y todo `CREATE`/`ALTER`/`DROP` sobre objetos persistentes. **La excepción
  que nadie espera:** las temporales no. La misma secuencia con `CREATE TEMPORARY TABLE` y `DROP
  TEMPORARY TABLE` en medio devuelve `0` tras el `ROLLBACK`.
- **Cuánto cuesta:** riesgo. Una migración de cinco `ALTER` que falla en el tercero deja a MySQL con
  dos aplicados y sin más vuelta que el `ALTER` inverso a mano. `pagos_ensayo` **se borró con `DROP
  TABLE` al terminar**.

> **⚠️ Advertencia.** *"Envuelve la migración en una transacción"* está escrito para PostgreSQL y se
> repite sin comprobar en MySQL, donde la transacción está y no protege nada.

---

## 3. 🧱 Dinero: `numeric` frente a coma flotante

**Qué es.** `numeric(p,s)` —`DECIMAL` en MySQL— guarda el número en base 10, dígito a dígito; `real`
y `double precision` guardan una aproximación binaria según IEEE 754. La diferencia no es de
precisión sino de **base**: un décimo no tiene representación finita en binario.

```text
tienda=# SELECT 0.1::float8 + 0.2::float8 AS suma_float,
tienda-#        0.1::float8 + 0.2::float8 = 0.3 AS igual_float,
tienda-#        (SELECT (sum(cantidad * precio_unit::float8)::numeric
tienda(#                 - sum(cantidad * precio_unit)) FROM pedido_lineas) AS desvio_total;
     suma_float      | igual_float | desvio_total
---------------------+-------------+--------------
 0.30000000000000004 | f           |     -0.00494
(1 fila)
```

- Medio céntimo de menos sobre 5 178 452 860,88 €, y **el error no se compensa al crecer**: no es
  ruido aleatorio, es el mismo sesgo de redondeo aplicado 3 500 000 veces. **Quién lo manda:** que
  `NUMERIC` sea exacto y `FLOAT`/`REAL`/`DOUBLE PRECISION` aproximados es categoría del estándar,
  respetada por los tres motores; cómo se aproxima lo fija IEEE 754.
- **Cuánto cuesta:** `3186.23` ocupa 10 bytes como `numeric(12,2)`, 8 como `double precision` y 4
  como entero de céntimos. La suma de las 3 500 000 líneas tardó **355 ms en `numeric` y 515 ms en
  `double precision`** aquí — al revés del folclore, porque el `::double precision` paga una
  conversión por fila.
- **Cuándo sí** coma flotante: magnitudes físicas donde el error relativo no importa, como un peso
  de envío. **Cuándo no:** lo que se vaya a cuadrar contra un extracto bancario. La tercera vía es
  el **entero de céntimos**: exacto, 4 bytes, y el punto decimal a cargo de tu código.

> **Veredicto:** dinero en `numeric(12,2)` o en entero de céntimos. La coma flotante no es
> "imprecisa": es exacta en base 2, y tu factura está en base 10.

---

## 4. 🧱 Tiempo: `timestamptz` guarda un instante; `timestamp`, un reloj de pared

**Qué es.** El nombre miente. `timestamptz` **no guarda ninguna zona**: convierte a UTC, guarda ocho
bytes de instante absoluto y lo renderiza en la zona de la sesión al leer. `timestamp` guarda ocho
bytes **sin decir de dónde son**, y no convierte nunca.

```text
tienda=# SELECT creado_en AS con_zona, creado_en AT TIME ZONE 'UTC' AS sin_zona,
tienda-#        extract(epoch FROM creado_en) AS epoch
tienda-#   FROM pedidos WHERE codigo = 'PED-00042';
           con_zona            |          sin_zona          |       epoch
-------------------------------+----------------------------+-------------------
 2025-02-21 03:08:09.349067+00 | 2025-02-21 03:08:09.349067 | 1740107289.349067
(1 fila)

tienda=# SET timezone = 'America/Bogota';
SET
tienda=# SELECT creado_en AS con_zona, creado_en AT TIME ZONE 'UTC' AS sin_zona,
tienda-#        extract(epoch FROM creado_en) AS epoch
tienda-#   FROM pedidos WHERE codigo = 'PED-00042';
           con_zona            |          sin_zona          |       epoch
-------------------------------+----------------------------+-------------------
 2025-02-20 22:08:09.349067-05 | 2025-02-21 03:08:09.349067 | 1740107289.349067
(1 fila)

tienda=# RESET timezone;
RESET
```

- `con_zona` cambió de día —del 21 al 20— y el `epoch` **no se movió ni un microsegundo**: `SET
  timezone` cambia lo que ves, no lo que hay en la página de disco.
- `sin_zona` —lo que guardaría una columna `timestamp`— es idéntico en las dos zonas, y ahí está el
  problema: **03:08 sin zona no identifica ningún instante**. Sirve para una hora de apertura, no
  para cuándo se creó un pedido. **Cuánto cuesta:** nada en espacio —los dos tipos ocupan 8 bytes— y
  una conversión de zona por valor leído.

> **🧠 Modelo mental.** `timestamptz` = un punto en la línea del tiempo. `timestamp` = lo que marcaba
> un reloj de pared que no dijo dónde estaba colgado.

---

## 5. 🧱 Texto: `char` paga el relleno, y el `utf8` de MySQL no es UTF-8

**Qué es.** `text` y `varchar(n)` guardan la cadena con su longitud real. `char(n)` **rellena con
espacios hasta `n`** y luego finge que no lo hizo.

```text
tienda=# SELECT octet_length('ES'::char(10))   AS bytes_char,
tienda-#        octet_length('ES'::varchar(10)) AS bytes_varchar,
tienda-#        length('ES'::char(10))          AS largo_char,
tienda-#        '['||'ES'::char(10)||']'        AS concatenado,
tienda-#        'E '::char(2) = 'E'             AS char_ignora_espacios,
tienda-#        'E '::text = 'E'                AS text_ignora_espacios;
 bytes_char | bytes_varchar | largo_char | concatenado | char_ignora_espacios | text_ignora_espacios
------------+---------------+------------+-------------+----------------------+----------------------
         10 |             2 |          2 | [ES]        | t                    | f
(1 fila)
```

- **Diez bytes guardados, dos declarados.** `length()` y la concatenación recortan el relleno, así
  que el coste está y no se ve. En `clientes.pais char(2)` el relleno es cero —ISO 3166-1 mide
  siempre dos— y ahí el tipo está bien elegido. El relleno además **cambia la igualdad**: en `char`,
  `'E '` es igual a `'E'`; en `text`, no. Es del estándar — los espacios finales son insignificantes
  en el tipo `CHARACTER`.
- **Cuánto cuesta:** espacio proporcional al hueco. En PostgreSQL `varchar(n)` y `text` rinden
  igual; el `VARCHAR(255)` que todos copian viene del máximo indexable de MySQL antiguo con cabecera
  de un byte, y aquí no significa nada.

Y la trampa que sigue viva en tablas de hace diez años: `SHOW CHARACTER SET LIKE 'utf8%'` declara
`utf8mb3` con `Maxlen` **3** y `utf8mb4` con `Maxlen` **4**.

```text
mysql> CREATE TABLE clientes_ensayo (nombre VARCHAR(40)) CHARACTER SET utf8mb3;
mysql> START TRANSACTION;
mysql> INSERT INTO clientes_ensayo VALUES ('Cafe con ñ, Madrid');
mysql> INSERT INTO clientes_ensayo VALUES ('Audio 🎧 PRD-00017');
ERROR 1366 (HY000) at line 6: Incorrect string value: '\xF0\x9F\x8E\xA7 P...' for column 'nombre' at row 1
mysql> ROLLBACK;
mysql> ALTER TABLE clientes_ensayo CONVERT TO CHARACTER SET utf8mb4;
mysql> INSERT INTO clientes_ensayo VALUES ('Audio 🎧 PRD-00017');
mysql> SELECT nombre, char_length(nombre) AS caracteres, length(nombre) AS bytes
    ->   FROM clientes_ensayo;
+----------------------+------------+-------+
| nombre               | caracteres | bytes |
+----------------------+------------+-------+
| Audio 🎧 PRD-00017 |         17 |    20 |
+----------------------+------------+-------+
```

- Tres bytes por carácter cubren el plano multilingüe básico y dejan fuera el plano suplementario,
  donde viven los emoji y el CJK extendido: el `ñ` entra con dos bytes, el 🎧 son cuatro y el motor
  lo rechaza; tras el `CONVERT`, esos 17 caracteres ocupan 20 bytes. En MySQL 9.7.2 `utf8` ya es
  sinónimo de `utf8mb4`, pero **una tabla creada con `utf8` en MySQL 5.7 sigue siendo `utf8mb3`
  hoy**.
- **Cuánto cuesta:** `CONVERT TO CHARACTER SET` reescribe la tabla y reconstruye sus índices: sobre
  una tabla grande, una ventana de mantenimiento. `clientes_ensayo` **se borró con `DROP TABLE` al
  terminar** y `SHOW TABLES` vuelve a dar las seis del esquema.

> **💡 Truco.** Con el cliente conectado en `latin1` —el defecto del cliente `mysql` de este
> contenedor— el emoji **no da error**: sus cuatro bytes entran como cuatro caracteres latin-1,
> caben en `utf8mb3` y al leer vuelven a salir bien. Medido: 20 caracteres y 24 bytes en lugar de 17
> y 20. El dato está corrupto y la pantalla lo disimula, hasta que lo lee otro cliente.

---

## 6. 🧱 `uuid`, arrays y la pareja `json` / `jsonb`

`uuid` es nativo y de 16 bytes en PostgreSQL; como `text` ocupa 40 —medido con `pg_column_size`— y
pierde la normalización, porque `'3F2504E0-4F89-11D3-9A0C-0305E82C3301'` y la variante sin guiones
entran las dos y salen iguales. Un **array** guarda varios valores en una columna:
`array_agg(producto_id ORDER BY linea)` sobre `PED-99999` da `{2356,2998,5,2435,5,3221}`, con el `5`
repetido, porque **admite duplicados y conserva el orden**; **cuándo no usarlo:** para modelar una
relación, porque no admite clave foránea. **Quién lo manda: motor.** ISO/IEC 9075 no define `UUID`
ni arrays —**cláusula no verificada**—; MySQL usa `BINARY(16)` con `UUID_TO_BIN()`, SQLite texto o
`BLOB`, y ninguno tiene arrays.

**Y la pareja que más se confunde.** `json` guarda **el texto que le diste**, tal cual. `jsonb` lo
parsea al insertar y guarda un árbol binario. Las dos consecuencias caben en una consulta:

```text
tienda=# SELECT '{"version": 1, "origen": "web", "version": 2}'::json  AS como_json,
tienda-#        '{"version": 1, "origen": "web", "version": 2}'::jsonb AS como_jsonb;
                   como_json                   |           como_jsonb
-----------------------------------------------+---------------------------------
 {"version": 1, "origen": "web", "version": 2} | {"origen": "web", "version": 2}
(1 fila)
```

- `jsonb` **perdió la clave duplicada** —se queda con la última— y **reordenó las claves**, por
  longitud y luego por bytes, que es como las indexa. **Cuándo sí `json`:** una firma, un *payload*
  (carga útil) que se devuelve byte a byte. **Cuándo no:** para consultarlo, porque cada acceso
  reparsea el texto.

Sobre los 4 100 000 documentos de `eventos_pedido.carga`, que es `jsonb`:

```text
tienda=# SELECT carga -> 'origen' AS flecha_simple, carga ->> 'origen' AS flecha_doble,
tienda-#        pg_typeof(carga -> 'origen') AS simple, pg_typeof(carga ->> 'origen') AS doble
tienda-#   FROM eventos_pedido WHERE pedido_id = 42 ORDER BY id LIMIT 1;
 flecha_simple | flecha_doble | simple | doble
---------------+--------------+--------+-------
 "web"         | web          | jsonb  | text
(1 fila)

tienda=# SELECT count(*) FROM eventos_pedido WHERE carga @> '{"origen": "movil", "version": 3}';
 count
--------
 466667
(1 fila)

Duración: 605,395 ms
```

- `->` devuelve `jsonb` y conserva las comillas; `->>` devuelve `text` y las quita. Comparar con
  `->` contra `'web'` no compila por tipos; contra `'"web"'::jsonb`, sí.
- `@>` pregunta "¿este documento contiene a este otro?" y permite pedir **dos claves a la vez**. La
  versión equivalente con `->>` tardó 471 ms frente a estos 605 **sin índice**; se invierte con un
  índice GIN, que solo `@>` puede usar; los índices son materia del bloque 03.
- **Quién lo manda.** `JSON` está en ISO/IEC 9075 como *SQL/JSON* desde SQL:2016 —**cláusula no
  verificada**—, pero `jsonb`, `->`, `->>` y `@>` son de PostgreSQL; MySQL 9.7.2 tiene un único
  `JSON`, binario y normalizador, sin `@>`. **Cuánto cuesta:** el `jsonb` del ejemplo ocupa **96
  bytes contra 75 en `json`**: el árbol pesa más y lo devuelve en acceso.

> **⚠️ Advertencia.** `jsonb` no es "un esquema flexible": es una columna sin restricciones. Ni
> `CHECK` por clave, ni `NOT NULL` por clave, ni clave foránea.

---

## 7. 🧱 SQLite: el tipo lo tiene el valor, no la columna

**Qué es.** En SQLite la columna no declara un tipo sino una **afinidad**: una preferencia de
conversión, y si el valor no se puede convertir se guarda como vino. Tampoco hay tipo fecha ni tipo
booleano — `true` es un entero y `CURRENT_TIMESTAMP` es texto:

```text
sqlite> SELECT typeof(true) AS booleano, typeof(CURRENT_TIMESTAMP) AS marca, typeof(1=1) AS comparacion;
integer|text|integer
sqlite> BEGIN;
sqlite> INSERT INTO pedido_lineas (pedido_id, linea, producto_id, cantidad, precio_unit)
   ...> VALUES (42, 9, 17, 'tres', '99.00');
sqlite> SELECT typeof(cantidad), cantidad FROM pedido_lineas WHERE pedido_id=42 AND linea=9;
text|tres
sqlite> SELECT sum(cantidad) AS suma FROM pedido_lineas WHERE pedido_id=42;
9.0
sqlite> ROLLBACK;
```

- La columna está declarada `cantidad INTEGER NOT NULL CHECK (cantidad > 0)` y entró la cadena
  `'tres'`. **El `CHECK` no protestó**: en el orden de clases de tipo de SQLite todo texto es mayor
  que todo número, así que `'tres' > 0` es cierto. El daño se ve una consulta más allá:
  `sum(cantidad)` de `PED-00042` vale **9 sin la fila falsa y `9.0` con ella** — la cadena suma cero
  y arrastra el resultado a coma flotante.
- **El precio está en `TEXT`** aquí, no por descuido: SQLite no tiene decimal exacto y `'99.00'`
  como texto es la forma de no perder céntimos; se paga al ordenar, alfabético sin `CAST`.
- **El arreglo se declara desde 3.37:** una tabla `STRICT` rechaza lo que no encaje. La misma
  inserción contra una copia `STRICT` de `pedido_lineas` responde `Error: cannot store TEXT value in
  INTEGER column pedido_lineas_estricta.cantidad`; se creó dentro de `BEGIN` y se deshizo con
  `ROLLBACK`.

---

### El filtro numérico que cuenta de más

La consecuencia que más caro sale no es guardar mal: es **comparar mal**. `pedidos.total` tiene
afinidad `TEXT`, y filtrar por un número no hace lo que parece:

```text
sqlite> SELECT count(*) AS "total > 5000"   FROM pedidos WHERE total > 5000;
451468
sqlite> SELECT count(*) AS "total > '5000'" FROM pedidos WHERE total > '5000';
451468
sqlite> SELECT count(*) AS "CAST a real"    FROM pedidos WHERE CAST(total AS REAL) > 5000;
481887
sqlite> SELECT total, CAST(total AS REAL) AS num FROM pedidos
   ...>  WHERE total > 5000 AND CAST(total AS REAL) <= 5000 LIMIT 3;
604.02|604.02
995.60|995.6
903.05|903.05
```

- **El filtro con el número y el filtro con la cadena dan la misma cifra**, 451 468, y ninguna es la
  correcta: PostgreSQL devuelve 481 887 sobre los mismos datos. Faltan 30 419 pedidos.
- **Quien se convierte es el literal, no la columna.** La afinidad `TEXT` de `total` se aplica al
  `5000`, así que la comparación pasa a ser alfabética. Por eso `604.02` entra: `'6'` va después de
  `'5'`. Es al revés de lo que sugiere la intuición, y de ahí que no se detecte leyendo la consulta.
- **No hay error, no hay aviso, y el informe sale firmado.** La defensa es `CAST(... AS REAL)` en el
  filtro, o mejor, una tabla `STRICT`, o mejor aún, guardar el dinero en céntimos enteros.

> **⚠️ Advertencia.** Un `WHERE` numérico sobre una columna de afinidad `TEXT` no falla: **cuenta
> otra cosa**. Si tu suite corre contra SQLite y producción contra PostgreSQL, los dos totales
> difieren y nadie compara los dos números.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas** para ninguna
> fila: donde la columna "Estándar" afirma algo es doctrina reproducida por los tres manuales, no
> una cláusula leída. Las columnas de motor están corridas en este entorno.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| Las sentencias se agrupan en DDL/DML/DCL/TCL | No: usa otra taxonomía | No lo usa en su doc | No lo usa en su doc | No lo usa en su doc |
| Un `ALTER TABLE` se deshace con `ROLLBACK` | No lo exige | **Sí** | **No**, ni tampoco tras `LOCK TABLES` o `TRUNCATE` | Sí |
| `NUMERIC` es exacto y `FLOAT` aproximado | Sí, son categorías distintas | Sí | Sí (`DECIMAL`) | **No hay decimal exacto**: afinidad sobre entero o real |
| El tipo de la columna restringe el valor, y hay fecha y booleano | Sí | Sí | Sí | **No** a las dos: afinidad salvo `STRICT`, y ni fecha ni booleano |
| Una marca con zona guarda un instante | No fija la representación | Sí: UTC, renderizado en la zona de sesión | `TIMESTAMP` sí; `DATETIME` no convierte | No hay tipo; texto ISO-8601 |
| Los espacios finales de `CHARACTER` no cuentan | Sí | Sí, y rellena hasta `n` | Sí, y rellena hasta `n` | No aplica: `CHAR(n)` es afinidad `TEXT` |
| Hay tipo `UUID` y arrays de columna | **No**, ninguno | `uuid` y arrays, con operadores | `BINARY(16)`; sin arrays | Texto o `BLOB`; sin arrays |
| Hay JSON | Sí, SQL/JSON desde SQL:2016 | `json` y `jsonb`, con `@>` | Un `JSON` binario, sin `@>` | `TEXT` + funciones `json_*` |

**Convención, no estándar:** los cuatro acrónimos, que ningún manual usa y toda entrevista pregunta;
`VARCHAR(255)`, heredado de MySQL antiguo; y *"`float` es más rápido"*, que solo vale sobre datos ya
guardados así — aquí la suma en `numeric` salió más rápida.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`float` con dos decimales vale para dinero" | La base binaria no representa `0.01`. Sobre 3 500 000 líneas el desvío medido fue de −0,00494 € |
| "Envuelve la migración en una transacción" | Cierto en PostgreSQL y SQLite. En MySQL cada `CREATE`/`ALTER`/`DROP`, y también `LOCK TABLES` y `TRUNCATE`, confirman antes de ejecutarse |
| "`timestamptz` guarda la zona horaria" | No guarda ninguna: convierte a UTC y renderiza en la zona de la sesión. El `epoch` no cambia al cambiar `TimeZone` |
| "`char(2)` es más eficiente que `varchar`" | `char(n)` rellena con espacios hasta `n` y los paga en disco: `char(10)` con `'ES'` ocupa 10 bytes y `length()` devuelve 2 |
| "El `utf8` de MySQL es UTF-8" | `utf8mb3` topa en tres bytes y no cubre el plano suplementario. El emoji da `ERROR 1366`, y con un cliente `latin1` entra corrupto sin avisar |
| "`jsonb` es igual que `json` pero más rápido" | `jsonb` reordena claves y descarta duplicadas, y ocupó 96 bytes contra 75. Si el documento es una firma, eso lo invalida |
| "SQLite es laxo pero el `CHECK` protege" | `CHECK (cantidad > 0)` aceptó la cadena `'tres'`: en SQLite todo texto es mayor que todo número. La defensa es `STRICT` |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Numeric Types»: exactitud de `numeric` e IEEE 754.
  <https://www.postgresql.org/docs/18/datatype-numeric.html>
- **Documentación** — PostgreSQL 18, «Date/Time Types»: qué guarda `timestamptz`.
  <https://www.postgresql.org/docs/18/datatype-datetime.html>
- **Documentación** — PostgreSQL 18, «Character Types»: el relleno de `char(n)`.
  <https://www.postgresql.org/docs/18/datatype-character.html>
- **Documentación** — PostgreSQL 18, «JSON Types»: `json` contra `jsonb`.
  <https://www.postgresql.org/docs/18/datatype-json.html>
- **Documentación** — MySQL 9.7, «Statements That Cause an Implicit Commit»: la lista completa.
  <https://dev.mysql.com/doc/refman/9.7/en/implicit-commit.html>
- **Documentación** — MySQL 9.7, «The utf8mb3 Character Set»: los tres bytes.
  <https://dev.mysql.com/doc/refman/9.7/en/charset-unicode-utf8mb3.html>
- **Documentación** — SQLite, «Datatypes In SQLite» y «STRICT Tables»: afinidad, orden entre clases
  de tipo y cómo apagarla. <https://www.sqlite.org/datatype3.html> ·
  <https://www.sqlite.org/stricttables.html>
- **Estándar** — ISO/IEC 9075-2 (*Foundation*), tipos exactos y aproximados, y SQL/JSON. De pago,
  sin URL pública y **no verificado en esta edición**.

---

## 🧠 Preguntas

1. Nombra las cuatro familias del lenguaje y una sentencia de cada una. 🟢
2. ¿Qué guarda exactamente `timestamptz` y qué pasa con ese valor cuando cambias `SET timezone`? 🟢
3. ¿Qué le hace `char(10)` a la cadena `'ES'` al guardarla, y qué devuelve `length()` después? 🟢
4. Di qué devuelve `->` y qué devuelve `->>` sobre una columna `jsonb`, con su tipo. 🟢
5. Diferencia `json` de `jsonb` en las dos cosas que `jsonb` no conserva. 🟡
6. ¿Qué diferencia hay entre `timestamp` y `timestamptz` para una columna que guarda cuándo se creó
   un pedido? 🟡
7. Que la agrupación DDL/DML/DCL/TCL exista, ¿lo fija el estándar o es convención del gremio? 🟡
8. ¿Qué es la afinidad de tipo de SQLite y en qué se diferencia de un tipo de columna? 🟡
9. Explica por qué la suma en `double precision` de las 3 500 000 líneas dio 0,00494 € menos, y por
   qué ese error no se compensa al crecer el número de filas. 🟠
10. En MySQL, ¿qué sentencias además del DDL cierran una transacción abierta, y cuál es la excepción
    que sí la respeta? 🟠
11. Un cliente conectado en `latin1` guarda un emoji en una columna `utf8mb3` sin ningún error y lo
    lee bien. ¿Por qué, y por qué es peor que el `ERROR 1366`? 🟠
12. `SELECT sum(cantidad)` sobre `PED-00042` en SQLite devuelve `9.0` en vez de `9`. Da la hipótesis
    más probable y la consulta con la que la confirmarías. 🟠
13. Que existan un tipo `UUID` nativo y los arrays de columna, ¿es del estándar o de cada motor? Di
    qué hace cada uno de los tres motores del corpus. 🟠
14. Escribe el DDL de una tabla `pagos_divisa` que guarde importes en varias monedas sin perder
    céntimos, con la moneda restringida a un catálogo cerrado y la marca de pago comparable entre
    zonas. Justifica cada tipo. 🔴
15. Escribe la secuencia completa —en PostgreSQL y en MySQL— para añadir una columna y un `CHECK` a
    `pedidos` de forma que, si el `CHECK` falla, no quede nada a medias. Di qué cambia entre los dos
    motores y qué harías en MySQL para conseguirlo. 🔴
16. Diseña la consulta que detecte, sobre `eventos_pedido`, los documentos `carga` a los que les
    falta la clave `version` o la tienen con un tipo que no es número. Usa solo operadores y
    funciones de `jsonb`. 🔴

---

**Anterior:** [README del bloque](README.md) · **Siguiente:** [`02`](02-select-y-el-orden-logico.md)
· **Relacionado:**
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) — el nulo de
SQL frente al `null` de dentro de un `jsonb` · [`05`](05-cte-y-recursion.md) — dónde vuelven a
aparecer los tipos al desarmar documentos.
