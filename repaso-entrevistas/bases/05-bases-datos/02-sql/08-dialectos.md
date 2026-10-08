# 08 — Dialectos

> Qué parte de lo que escribes todos los días es SQL y qué parte es tu motor: las tres capas de
> portabilidad, la tabla de divergencias medida sobre los cuatro motores, lo que cuesta escribir
> para el mínimo común denominador —hay un caso a 3 360×— y lo que no es portable y casi nadie mira.
> **Asume leído:** [`07`](07-escritura-upsert-y-vistas.md) — de ahí vienen `ON CONFLICT`, `MERGE`,
> `RETURNING` y las vistas materializadas, media tabla de este capítulo. **Vigencia:** 20 de
> septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema)
- [2. Las tres capas de portabilidad](#2--las-tres-capas-de-portabilidad)
- [3. La tabla maestra de divergencias](#3-️-la-tabla-maestra-de-divergencias)
- [4. El precio de la portabilidad, medido](#4--el-precio-de-la-portabilidad-medido)
- [5. Cuándo escribir portable y cuándo no](#5--cuándo-escribir-portable-y-cuándo-no)
- [6. Estándar, motor y convención](#6--estándar-motor-y-convención)
- [7. Lo que no es portable y casi nadie mira](#7--lo-que-no-es-portable-y-casi-nadie-mira)

---

## 1. 🎯 El problema

El informe de unidades medias por pedido lleva dos años en producción contra MySQL. Alguien monta el
entorno nuevo sobre PostgreSQL, corre la misma consulta —carácter por carácter la misma— y el número
cambia. No falla, no avisa: cambia.

```text
tienda=# SELECT pedido_id, sum(cantidad) AS unidades, count(*) AS lineas,
tienda-#        sum(cantidad)/count(*) AS media
tienda-#   FROM pedido_lineas WHERE pedido_id BETWEEN 40 AND 44
tienda-#  GROUP BY pedido_id ORDER BY pedido_id;
 pedido_id | unidades | lineas | media 
-----------+----------+--------+-------
        40 |        4 |      1 |     4
        41 |        6 |      2 |     3
        42 |        9 |      3 |     3
        43 |       11 |      3 |     3
        44 |       14 |      4 |     3
(5 filas)
```

```text
mysql> SELECT pedido_id, sum(cantidad) AS unidades, count(*) AS lineas, sum(cantidad)/count(*) AS media
    ->   FROM pedido_lineas WHERE pedido_id BETWEEN 40 AND 44 GROUP BY pedido_id ORDER BY pedido_id;
+-----------+----------+--------+--------+
| pedido_id | unidades | lineas | media  |
+-----------+----------+--------+--------+
|        40 |        4 |      1 | 4.0000 |
|        41 |        6 |      2 | 3.0000 |
|        42 |        9 |      3 | 3.0000 |
|        43 |       11 |      3 | 3.6667 |
|        44 |       14 |      4 | 3.5000 |
+-----------+----------+--------+--------+
```

- **`PED-00043` tiene 11 unidades en 3 líneas.** PostgreSQL responde `3` y MySQL `3.6667`: la
  división entre dos enteros trunca en uno y devuelve decimal en el otro, y ninguno se queja.
- **SQLite responde `3`**, como PostgreSQL, que es lo peor que podía pasar: dos de tres coinciden,
  así que la respuesta divergente parece la rara y nadie sospecha del informe que lleva dos años.
- No hay `ERROR` ni aviso en el log. **El dialecto no se manifiesta rompiendo: se manifiesta
  cambiando el número.**

La pregunta del capítulo es esa: **de todo lo que escribes cada día, ¿qué es SQL y qué es tu
motor?** Y la respuesta útil no es un catálogo de cuarenta diferencias, sino un criterio para saber
en cuál de tres cajones cae cada cosa que escribes.

---

## 2. 🧱 Las tres capas de portabilidad

**Qué es.** Todo lo que escribes en SQL cae en una de tres capas, y la capa determina qué te va a
pasar el día que cambies de motor: nada, una reescritura mecánica, o un rediseño.

| Capa | Qué hay dentro | Qué pasa al cambiar de motor |
|---|---|---|
| **Núcleo** | `SELECT`, `FROM`, `WHERE`, `JOIN` con `ON`, `GROUP BY`, `HAVING`, `ORDER BY`, `UNION`, `EXISTS`, subconsultas, CTE no recursivas, `CASE`, `CAST`, restricciones `PRIMARY KEY`/`UNIQUE`/`NOT NULL`/`FOREIGN KEY`/`CHECK`, `BEGIN`/`COMMIT`/`ROLLBACK` | Nada. Corre igual en los cuatro |
| **Traducción** | Concatenación, límite de filas, comparación segura con nulos, upsert, orden de los nulos, `FULL OUTER JOIN`, fechas, agregación condicional | Reescritura mecánica. **Cuesta rendimiento o legibilidad, no diseño** |
| **Ruptura** | Vistas materializadas, `RETURNING`, `MERGE`, `FILTER`, `GROUPS`/`EXCLUDE` en ventanas, arrays, `jsonb` con `@>`, `CYCLE` en CTE recursivas, tipos exactos | Rediseño. O emulas con otro mecanismo, o cambias la aplicación |

El núcleo es más grande de lo que parece, y ese es el primer mensaje del capítulo: **casi toda una
aplicación CRUD vive ahí y es portable sin esfuerzo**. El problema es que lo que queda fuera no se
reparte al azar: se concentra justo en las consultas que alguien optimizó. Y la capa de traducción
tiene una trampa que conviene ver antes que ninguna otra, la concatenación:

```text
tienda=# SELECT codigo || ' — ' || estado AS etiqueta FROM pedidos WHERE codigo = 'PED-00042';
      etiqueta      
--------------------
 PED-00042 — PAGADO
(1 fila)
```

```text
mysql> SELECT codigo || ' — ' || estado AS etiqueta FROM pedidos WHERE codigo = 'PED-00042';
+----------+
| etiqueta |
+----------+
|        0 |
+----------+
```

- **MySQL no falla: devuelve `0`.** Para él `||` es el `OR` lógico, así que evalúa `'PED-00042' OR '
  — ' OR 'PAGADO'`, convierte cada cadena a número —todas valen 0— y responde falso. MariaDB 12.3.3
  hace exactamente lo mismo.
- SQLite concatena igual que PostgreSQL: **tres de cuatro hacen una cosa y el cuarto hace otra, en
  silencio**, el mismo patrón del `PED-00043` de §1. **La forma portable es `CONCAT(...)`**, que los
  cuatro aceptan; se paga en legibilidad, no en tiempo.

MySQL trae un interruptor para esto, y casi nadie lo enciende: `SET sql_mode='PIPES_AS_CONCAT'` hace
que `||` concatene, y `sql_mode='ANSI'` activa de golpe
`REAL_AS_FLOAT,PIPES_AS_CONCAT,ANSI_QUOTES,IGNORE_SPACE,ONLY_FULL_GROUP_BY` —medido en sesión—.
Lleva ahí veinte años y nadie lo toca porque rompe el código heredado que daba por buenas las
comillas dobles. **Saber que existe, y que no arregla `FILTER` ni `FULL OUTER JOIN` ni `NULLS LAST`,
es la respuesta que distingue en una entrevista.**

> **Veredicto:** antes de preguntarte si algo es portable, pregúntate en qué capa cae. Del núcleo no
> te preocupes; de la traducción, mídela; de la ruptura, decídela al diseñar y no al migrar.

---

## 3. ⚖️ La tabla maestra de divergencias

Todo lo medido en los siete capítulos anteriores, agrupado por tema y recomprobado contra las
versiones del corpus en esta edición. Donde una fila tiene dueño, el enlace va al capítulo que la
midió: ahí está la sesión entera.

### Sintaxis del día a día

| Qué escribes | PostgreSQL 18.6 | MySQL 9.7.2 · MariaDB 12.3.3 | SQLite 3.53.4 |
|---|---|---|---|
| `a \|\| b` para concatenar | Concatena | **Devuelve `0`**: es `OR` | Concatena |
| `CONCAT(a, b)` | Sí | Sí | Sí |
| `LIMIT 3 OFFSET 2` | Sí | Sí | Sí |
| `OFFSET 2 ROWS FETCH FIRST 3 ROWS ONLY` | Sí | MySQL **`ERROR 1064`**; MariaDB sí | **`Parse error`** |
| `LIMIT 2, 3` | No existe | Sí, y el primer número es el desplazamiento | Sí |
| `"PAGADO"` entre comillas dobles | **Error**: es un identificador | **Funciona**: lo toma por cadena, salvo con `ANSI_QUOTES` | Error, con sugerencia |
| `activo = 1` sobre un booleano | **Error**: `operator does not exist: boolean = integer` | Sí: el booleano es `TINYINT(1)` | Sí: el booleano es entero |
| `EXTRACT(YEAR FROM creado_en)` | Sí | Sí | **`Parse error`**; hay que usar `strftime('%Y', …)` |
| Truncar al mes | `date_trunc('month', …)` | `DATE_FORMAT(…, '%Y-%m-01')` | `strftime('%Y-%m-01', …)` |
| Alias del `SELECT` en el `HAVING` ([`02`](02-select-y-el-orden-logico.md)) | **No** | Sí | Sí |
| Columna ni agrupada ni agregada ([`04`](04-agregacion-y-subconsultas.md)) | Error siempre | Error en MySQL; MariaDB la acepta | Devuelve un valor arbitrario |

### Nulos y orden

| Qué escribes | PostgreSQL 18.6 | MySQL 9.7.2 · MariaDB 12.3.3 | SQLite 3.53.4 |
|---|---|---|---|
| Comparar dos nulos como iguales ([`03`](03-joins.md)) | `IS NOT DISTINCT FROM` | **Solo `<=>`**: la forma larga da `ERROR 1064` | Las dos formas |
| `ORDER BY referencia` ascendente | Los 273 126 nulos **al final** | Los nulos **al principio** | Los nulos **al principio** |
| `ORDER BY referencia NULLS LAST` | Sí | **`ERROR 1064`** | Sí |
| `ORDER BY referencia IS NULL, referencia` | Sí | Sí | Sí |

La última fila es la forma portable del orden de los nulos: corre en los cuatro y da lo mismo que
`NULLS LAST`. **Es la que cuesta 3 360×**, y §4 la mide.

### Conjuntos, escritura y vistas

| Qué escribes | PostgreSQL 18.6 | MySQL 9.7.2 · MariaDB 12.3.3 | SQLite 3.53.4 |
|---|---|---|---|
| `FULL OUTER JOIN` ([`03`](03-joins.md)) | Sí | **`ERROR 1064`**, con `OUTER` y sin él | Sí, desde 3.39.0 |
| `INTERSECT` y `EXCEPT` ([`07`](07-escritura-upsert-y-vistas.md)) | Sí | Sí, desde 8.0.31 | Sí, **pero no sus variantes `ALL`** |
| `MINUS` | No | Solo MariaDB con `sql_mode='ORACLE'` | No |
| Upsert ([`07`](07-escritura-upsert-y-vistas.md)) | `ON CONFLICT` | `ON DUPLICATE KEY UPDATE` | `ON CONFLICT`, desde 3.24 |
| `MERGE` | Sí, desde la 15 | **`ERROR 1064`** | **`Parse error`** |
| `RETURNING` | Sí | MySQL **`ERROR 1064`**; **MariaDB sí** | Sí, desde 3.35 |
| Vista materializada con `REFRESH` | Sí | **No** | **No** |
| `count(*) FILTER (WHERE …)` ([`04`](04-agregacion-y-subconsultas.md)) | Sí | **`ERROR 1064`** | Sí |
| `MATERIALIZED` / `NOT MATERIALIZED` en CTE ([`05`](05-cte-y-recursion.md)) | Sí, desde la 12 | **`ERROR 1064`** | Sí |
| `GROUPS` y `EXCLUDE` en ventanas ([`06`](06-funciones-de-ventana.md)) | Sí | **`ERROR 1235`** | Sí |

- **MySQL acumula los `ERROR 1064`**, y no es casualidad: es el motor que menos implementa de la
  capa de ruptura. Si tu SQL tiene que correr en los cuatro, **MySQL fija el techo**.
- **SQLite sorprende por arriba.** Tiene `FULL OUTER JOIN`, `FILTER`, `RETURNING`, `NULLS LAST` y
  upsert; lo que le falta es de la otra familia —tipos exactos, `EXTRACT`, vistas materializadas—.
- **MariaDB no es MySQL.** Diverge en cuatro filas medidas: `FETCH FIRST`, `RETURNING`, `MINUS` en
  modo Oracle y `ONLY_FULL_GROUP_BY`, que no trae activo. Tratarlas como un solo motor se paga.

---

## 4. 🩺 El precio de la portabilidad, medido

**Qué es.** Escribir para el mínimo común denominador no es gratis, y el precio no es siempre el
mismo: en un caso no se paga nada, en otro se paga el doble, y en el tercero se paga tres mil veces.
La diferencia está en si la forma portable **impide un acceso por índice** o solo cambia la
escritura.

El caso barato primero. `FILTER` es de PostgreSQL y SQLite; MySQL exige `CASE`. Sobre el millón:

```text
tienda=# \timing on
tienda=# SELECT count(*) FILTER (WHERE estado='PAGADO') AS pagados FROM pedidos;
 pagados 
---------
  250000
(1 fila)

Duración: 54,861 ms
tienda=# SELECT count(CASE WHEN estado='PAGADO' THEN 1 END) AS pagados FROM pedidos;
 pagados 
---------
  250000
(1 fila)

Duración: 56,285 ms
```

- **Indistinguibles**, y no por suerte: con `EXPLAIN (ANALYZE, BUFFERS)` las dos formas dan el mismo
  nodo `Aggregate`, el mismo coste estimado `37640.00..37640.01` y las mismas 17 640 páginas leídas.
  El planificador las trata como la misma agregación sobre un `Seq Scan`.
- **El precio aquí es cero en tiempo y todo en legibilidad**: `FILTER` dice lo que hace, y el `CASE`
  hay que leerlo dos veces para ver que el `ELSE` ausente devuelve nulo y que por eso el `count` no
  lo suma.

El caso intermedio: el apaño de `FULL OUTER JOIN` con `UNION ALL`, el mismo que [`03`](03-joins.md)
escribió para MySQL, corrido **contra PostgreSQL** para que la comparación aísle la escritura y no
el motor.

```text
tienda=# SELECT count(*) AS filas FROM (SELECT id FROM pedidos WHERE estado='ANULADO') p
tienda-#   FULL OUTER JOIN pagos pg ON pg.pedido_id = p.id;
 filas  
--------
 880000
(1 fila)

Duración: 172,666 ms
tienda=# SELECT count(*) AS filas FROM (
tienda(#   SELECT p.id AS pedido_id, pg.id AS pago_id
tienda(#     FROM (SELECT id FROM pedidos WHERE estado='ANULADO') p
tienda(#     LEFT JOIN pagos pg ON pg.pedido_id = p.id
tienda(#   UNION ALL
tienda(#   SELECT p.id, pg.id FROM pagos pg
tienda(#     LEFT JOIN (SELECT id FROM pedidos WHERE estado='ANULADO') p ON pg.pedido_id = p.id
tienda(#    WHERE p.id IS NULL) t;
 filas  
--------
 880000
(1 fila)

Duración: 297,223 ms
```

- Mismas 880 000 filas y **1,7× de tiempo**. Sobre cinco pasadas la mediana fue **164 ms nativo
  contra 300 ms portable**, con poca dispersión. La razón es de mecanismo: el `FULL` recorre `pagos`
  una vez; el apaño lo recorre **dos**, una por brazo del `UNION ALL`.

Y el caso caro, que es el que hay que llevarse. `pagos.referencia` tiene índice único
—`pagos_referencia_key`, uno de los 11 que trae el esquema— y la primera página del informe de
conciliación pide las tres primeras referencias.

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS) SELECT referencia FROM pagos ORDER BY referencia NULLS LAST LIMIT 3;
 Limit  (cost=0.42..0.48 rows=3 width=14) (actual time=0.039..0.041 rows=3.00 loops=1)
   Buffers: shared hit=5
   ->  Index Only Scan using pagos_referencia_key on pagos  (cost=0.42..14874.42 rows=820000 width=14) (actual time=0.038..0.039 rows=3.00 loops=1)
         Heap Fetches: 3
         Index Searches: 1
         Buffers: shared hit=5
 Planning:
   Buffers: shared hit=96
 Planning Time: 0.292 ms
 Execution Time: 0.053 ms
(10 filas)

tienda=# EXPLAIN (ANALYZE, BUFFERS) SELECT referencia FROM pagos ORDER BY referencia IS NULL, referencia LIMIT 3;
 Limit  (cost=25472.77..25472.78 rows=3 width=15) (actual time=178.144..178.145 rows=3.00 loops=1)
   Buffers: shared hit=2353
   ->  Sort  (cost=25472.77..27522.77 rows=820000 width=15) (actual time=178.144..178.144 rows=3.00 loops=1)
         Sort Key: ((referencia IS NULL)), referencia
         Sort Method: top-N heapsort  Memory: 25kB
         Buffers: shared hit=2353
         ->  Index Only Scan using pagos_referencia_key on pagos  (cost=0.42..14874.42 rows=820000 width=15) (actual time=0.007..59.670 rows=820000.00 loops=1)
               Heap Fetches: 761
               Index Searches: 1
               Buffers: shared hit=2345
 Planning:
   Buffers: shared hit=9
 Planning Time: 0.040 ms
 Execution Time: 178.159 ms
(14 filas)
```

- **0,053 ms contra 178,159 ms: 3 360 veces más lento**, y 5 páginas leídas contra 2 353. La
  consulta es la misma y el resultado es el mismo.
- **Qué lo causa:** `NULLS LAST` coincide con el orden que el índice ya tiene, así que el `Limit`
  para en la tercera entrada. `referencia IS NULL` es una **expresión** sobre la que no hay índice,
  y el motor no puede saber que ordena igual: tiene que leer las 820 000 entradas y ordenarlas antes
  de quedarse con tres.
- **Esta es la forma general del precio.** Un orden o un predicado portable que envuelve la columna
  en una expresión **desactiva el índice**. No es propio de los nulos: pasa igual con `LOWER(email)`
  y con cualquier función sobre la columna indexada.

> **Veredicto:** el precio de una forma portable se predice con una pregunta: **¿envuelve una
> columna indexada en una expresión?** Si no, el precio es legibilidad. Si sí, mídelo antes de
> aceptarlo.

---

## 5. 🧭 Cuándo escribir portable y cuándo no

El argumento a favor de la portabilidad es una hipótesis —*"algún día cambiaremos de motor"*— y
conviene mirarla de frente, porque **casi ningún producto cambia de motor**. Lo que sí pasa todos
los días es que escribes SQL, y la forma portable cuesta legibilidad siempre y rendimiento a veces:
un seguro caro contra un siniestro que probablemente no ocurra. Hay tres casos donde sí ocurre:

| Caso | Por qué ahí sí | Qué hacer |
|---|---|---|
| **Producto que se instala en casa del cliente** | El motor lo elige el cliente, no tú, y la lista de motores soportados es una cláusula del contrato | Portable de verdad, con la suite de pruebas corriendo contra cada motor soportado |
| **Migración ya decidida y con fecha** | El cambio no es hipotético: está en el plan | Portable **solo en el código que se va a mover**, y con inventario previo (§7) |
| **Biblioteca o framework que otros usan** | No sabes contra qué motor lo van a apuntar | Portable en lo que expones; específico en lo que ejecutas por dentro |

Y el criterio para todo lo demás, que es la mayoría:

- **Escribe el núcleo portable sin pensarlo.** `JOIN … ON`, `GROUP BY`, `EXISTS` y las restricciones
  no tienen alternativa específica que valga la pena, así que la portabilidad ahí sale gratis.
- **Usa lo específico de tu motor donde aporta**, y márcalo. `FILTER`, `ON CONFLICT`, `RETURNING`,
  `jsonb` y las vistas materializadas existen porque resuelven algo; renunciar a ellos por si acaso
  es regalar trabajo.
- **Concentra lo específico.** Si `RETURNING` aparece en 40 sitios, la migración es imposible. Si
  aparece en tres repositorios, es una tarde. **Lo que hace portable a una aplicación no es el SQL
  genérico: es que el SQL específico esté agrupado.**
- **No confundas un ORM con portabilidad.** Traduce el núcleo y poco más —lo corre
  [`11/04`](../11-orms/04-constructores-y-cuando-no-usar-orm.md) §4—: la capa de ruptura la
  escribes a mano.

> **⚠️ Advertencia.** La portabilidad que más falla no es la del SQL: es la de los **tipos y del
> comportamiento transaccional** (§7). Una aplicación cuyo SQL es perfectamente estándar puede
> romperse en la migración por el orden de los nulos, por el nivel de aislamiento por defecto o por
> qué pasa tras un error a mitad de un lote. Eso no lo ve ninguna suite de pruebas que corra sobre
> una sola base.

---

## 6. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado ninguna de sus cláusulas en
> esta edición**. Donde la columna "Estándar" dice *no verificado*, lo afirmado es lo que hacen los
> cuatro motores, medido en sesión. Las dos filas que sí afirman algo de la norma son **cita de
> segunda mano** de las notas de compatibilidad del manual de PostgreSQL, no lectura del texto.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| El límite de filas se escribe `OFFSET … FETCH FIRST …` | Sí, desde SQL:2008; `LIMIT` es sintaxis propia de PostgreSQL y MySQL | Acepta las dos | **Solo `LIMIT`**: `ERROR 1064` a la estándar | **Solo `LIMIT`**: `Parse error` |
| `\|\|` concatena cadenas | Sí | Sí | **No**: es `OR`, salvo `PIPES_AS_CONCAT` | Sí |
| Las comillas dobles delimitan un identificador | No verificado | Sí | **No**: delimitan cadena, salvo `ANSI_QUOTES` | Sí |
| La división de dos enteros da un entero | No verificado | Sí: 11/3 = 3 | **No**: 11/3 = 3.6667 | Sí: 11/3 = 3 |
| Existe un tipo booleano distinto del entero | No verificado | Sí: `activo = 1` es error | No: es `TINYINT(1)` | No: es entero |
| `EXTRACT(campo FROM marca)` está disponible | No verificado | Sí | Sí | **No**: `Parse error` |
| El orden de los nulos se controla con `NULLS FIRST`/`LAST` | No verificado | Sí; y por defecto van **al final** en ascendente | **`ERROR 1064`**; por defecto van **al principio** | Sí; por defecto **al principio** |
| `FILTER` sobre un agregado | Sí, `<filter clause>`; cláusula no verificada | Sí | **`ERROR 1064`** | Sí |
| `MERGE` es la sentencia de upsert | **Sí**, es la del estándar | Sí, desde la 15 | **`ERROR 1064`** | **`Parse error`** |
| El aislamiento por defecto es `READ COMMITTED` | No lo fija: el estándar define los cuatro niveles, no cuál es el defecto | Sí | **No: `REPEATABLE-READ`** | No aplica igual: un solo escritor |
| Un error dentro de una transacción la aborta entera | No verificado | **Sí**: `current transaction is aborted` | No: la siguiente sentencia corre | No: la siguiente sentencia corre |
| El DDL se deshace con `ROLLBACK` ([`01`](01-familias-del-lenguaje-y-tipos.md)) | No lo exige | Sí | **No**: confirma implícito | Sí |

MariaDB 12.3.3 acompaña a MySQL en `||`, en las comillas dobles, en la división, en `NULLS LAST`, en
`FILTER`, en `MERGE`, en el aislamiento por defecto y en el DDL. Se separa en dos filas medidas:
**acepta `OFFSET … FETCH FIRST`** y **tiene `RETURNING`**.

**La lectura de esta tabla es la tesis del capítulo, y es contraintuitiva: lo estándar no es lo
portable.** La forma normalizada del límite de filas falla en dos de los cuatro motores; la forma
que corre en los cuatro —`LIMIT n OFFSET m`— no es del estándar y su propio manual lo dice. Lo mismo
con `MERGE`: es la sentencia de la norma y solo la tiene PostgreSQL. **Escribir "SQL estándar" y
escribir "SQL que corre en todas partes" son dos objetivos distintos, y a veces opuestos.**

**Convención, no estándar:** *"si es ANSI, funciona en todos"*. Viene de los años en que los
vendedores certificaban el nivel *Entry* de SQL-92 y lo ponían en el folleto, y sobrevive porque
suena a garantía. Lo que hay debajo es que **ningún motor implementa la norma entera y todos
implementan cosas que no están en ella**: el propio apéndice de conformidad de PostgreSQL lista lo
que le falta. La otra media verdad del gremio, *"un ORM te hace portable"*, se cae con la misma
tabla: el ORM traduce el núcleo de §2, y los `ERROR 1064` de arriba están todos fuera del núcleo.

---

## 7. 🔭 Lo que no es portable y casi nadie mira

Las diferencias de sintaxis se descubren solas: el motor te da un `ERROR 1064` y lo arreglas. Las
que hacen daño de verdad son las que **no producen ningún error**, y no están en el SQL sino debajo.
Son cinco, y ninguna aparece en la lista de comprobación de nadie.

**El tipo del dinero.** `numeric(12,2)` en PostgreSQL, `DECIMAL(12,2)` en MySQL, y en SQLite **no
hay decimal exacto**: el corpus guarda `pedidos.total` como texto para no perder céntimos, y eso
convierte el filtro numérico en una comparación alfabética que cuenta 451 468 pedidos donde
PostgreSQL cuenta 481 887 ([`01`](01-familias-del-lenguaje-y-tipos.md)). **30 419 filas de
diferencia sin un solo error.**

**La fecha con zona.** `timestamptz` guarda un instante en UTC y lo renderiza en la zona de la
sesión. El `TIMESTAMP` de MySQL también convierte, pero `DATETIME` no convierte nada, y SQLite no
tiene tipo de fecha: es texto ISO-8601. `PED-00042` se lee `2025-02-21 03:08:09.349067+00` en
PostgreSQL y `2025-02-21 03:08:09.349067` sin sufijo en MySQL. **El desplazamiento desaparece de la
salida y con él la pista de que hubo una conversión.**

**El booleano.** No existe en MySQL ni en SQLite: es un entero. `activo = 1` funciona en los dos y
es un error de tipos en PostgreSQL, y al revés, `activo = true` funciona en los tres. La trampa real
está en la carga: exportar `t`/`f` de PostgreSQL a un `TINYINT(1)` guarda 0 en ambos casos y **deja
los 5 000 productos inactivos** sin que nadie se entere.

**El aislamiento por defecto.** PostgreSQL arranca en `read committed`, MySQL y MariaDB en
`REPEATABLE-READ`, comprobado en sesión. No lo fija el estándar: **fija los cuatro niveles, no cuál
es el predeterminado.** Mover una aplicación de MySQL a PostgreSQL le quita, sin avisar, la
estabilidad de lectura dentro de la transacción de la que quizá dependía; el bloque 04 es su dueño.

**Qué pasa tras un error dentro de una transacción.** Esta es la que más caro sale en un lote
nocturno:

```text
tienda=# BEGIN;
BEGIN
tienda=*# SELECT count(*) FROM pedidos WHERE estado='ANULADO';
 count 
-------
 60000
(1 fila)

tienda=*# SELECT 1/0;
ERROR:  division by zero
tienda=!# SELECT count(*) FROM pedidos WHERE estado='PAGADO';
ERROR:  current transaction is aborted, commands ignored until end of transaction block
tienda=!# ROLLBACK;
ROLLBACK
```

```text
mysql> START TRANSACTION;
mysql> SELECT count(*) AS anulados FROM pedidos WHERE estado='ANULADO';
+----------+
| anulados |
+----------+
|    60000 |
+----------+
mysql> SELECT * FROM pedidos WHERE estado_que_no_existe = 1;
ERROR 1054 (42S22) at line 3: Unknown column 'estado_que_no_existe' in 'where clause'
mysql> SELECT count(*) AS pagados FROM pedidos WHERE estado='PAGADO';
+---------+
| pagados |
+---------+
|  250000 |
+---------+
mysql> ROLLBACK;
```

- **PostgreSQL marca la transacción como abortada** —fíjate en el prompt, que pasa de `tienda=*#` a
  `tienda=!#`— y rechaza todo hasta el `ROLLBACK`. **MySQL y SQLite siguen adelante** como si nada:
  el error fue de la sentencia, no de la transacción.
- **Qué significa en un lote.** Un trabajo que inserta 10 000 filas dentro de una transacción y
  falla en la 3 000: en MySQL las 7 000 restantes se insertan y el `COMMIT` confirma un lote
  incompleto que nadie marcó como roto. En PostgreSQL no entra ninguna. **Portar ese lote de MySQL a
  PostgreSQL lo mejora; portarlo al revés lo rompe en silencio.**
- El arreglo portable no es del SQL sino de la aplicación: **un `SAVEPOINT` antes de cada sentencia
  que pueda fallar**, y `ROLLBACK TO SAVEPOINT` al capturarla. Los cuatro motores lo tienen.

> **🧠 Modelo mental.** El SQL es la parte visible y la que menos duele. Lo que de verdad se rompe al
> cambiar de motor es **el contrato que no escribiste**: qué tipo guarda el dinero, en qué zona
> vuelve la fecha, qué ve tu transacción y qué queda vivo después de un error.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "SQL es SQL" | El núcleo de §2 sí, y es grande. Fuera de él, la misma consulta devuelve `3` en PostgreSQL y `3.6667` en MySQL, y `||` concatena en tres motores y devuelve `0` en el cuarto |
| "Si es ANSI, funciona en todos" | Al revés de lo que suena: `OFFSET … FETCH FIRST` es la forma del estándar y falla en MySQL y SQLite; `LIMIT n OFFSET m` no es del estándar y corre en los cuatro |
| "Un ORM te hace portable" | Traduce el núcleo. `RETURNING`, `FILTER`, `MERGE`, `jsonb` y las vistas materializadas los escribes tú, y son justo los que no están en todos |
| "Escribir portable no cuesta nada" | El orden de nulos portable sobre `pagos.referencia` pasa de 0,053 ms a 178,159 ms y de 5 páginas a 2 353: **3 360×**, porque envuelve la columna indexada en una expresión |
| "Escribir portable siempre cuesta" | `FILTER` y `SUM(CASE WHEN …)` dan el mismo plan, el mismo coste estimado y las mismas 17 640 páginas. Ahí el precio es legibilidad, no tiempo |
| "MySQL y MariaDB son el mismo motor" | Divergen en cuatro filas medidas: `FETCH FIRST`, `RETURNING`, `MINUS` con `sql_mode='ORACLE'` y `ONLY_FULL_GROUP_BY`, que MariaDB no trae activo |
| "SQLite es el motor pobre, ahí seguro falta todo" | Tiene `FULL OUTER JOIN`, `FILTER`, `RETURNING`, `NULLS LAST` y upsert — más que MySQL 9.7.2. Lo que le falta es de otra familia: tipos exactos, `EXTRACT` y vistas materializadas |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «SQL Conformance»: qué partes del estándar implementa y cuáles
  no, listadas una a una. <https://www.postgresql.org/docs/18/features.html>
- **Documentación** — PostgreSQL 18, «LIMIT and OFFSET»: la nota de compatibilidad donde el propio
  manual dice que `LIMIT` no es del estándar.
  <https://www.postgresql.org/docs/18/queries-limit.html>
- **Documentación** — PostgreSQL 18, «Sorting Rows»: `NULLS FIRST` y `NULLS LAST`, y cuál es el
  defecto. <https://www.postgresql.org/docs/18/queries-order.html>
- **Documentación** — MySQL 9.7, «MySQL Standards Compliance»: las extensiones propias y las
  diferencias declaradas con la norma. <https://dev.mysql.com/doc/refman/9.7/en/compatibility.html>
- **Documentación** — MySQL 9.7, «Server SQL Modes»: `ANSI`, `PIPES_AS_CONCAT`, `ANSI_QUOTES` y
  `ONLY_FULL_GROUP_BY`. <https://dev.mysql.com/doc/refman/9.7/en/sql-mode.html>
- **Documentación** — SQLite, «SQL Features That SQLite Does Not Implement»: la lista de lo que
  falta, mantenida por el proyecto. <https://www.sqlite.org/omitted.html>
- **Documentación** — MariaDB, «sql_mode»: el modo `ORACLE` y en qué convierte al motor.
  <https://mariadb.com/docs/server/server-management/variables-and-modes/sql_mode>
- **Estándar** — ISO/IEC 9075-2 (*Foundation*), `<query expression>` y `<sort specification list>`.
  De pago, sin URL pública y **no verificado en esta edición**.

---

## 🧠 Preguntas

1. Nombra las tres capas de portabilidad de §2 y pon un ejemplo de cada una. 🟢
2. ¿Qué devuelve `SELECT 'PED-00042' || ' — ' || 'PAGADO'` en MySQL 9.7.2, y por qué? 🟢
3. ¿Cuál de los cuatro motores del corpus no tiene `FULL OUTER JOIN`? 🟢
4. En un `ORDER BY` ascendente, ¿dónde coloca los nulos PostgreSQL y dónde los colocan los otros
   tres? 🟢
5. ¿Qué hace `SET sql_mode='ANSI'` en MySQL, y nombra dos cosas que **no** arregla? 🟢
6. `LIMIT 3 OFFSET 2` y `OFFSET 2 ROWS FETCH FIRST 3 ROWS ONLY`: ¿cuál es la del estándar y cuál
   corre en los cuatro motores? 🟡
7. Distingue "SQL estándar" de "SQL portable". Da un caso donde apuntan a formas distintas. 🟡
8. ¿El nivel de aislamiento por defecto lo fija el estándar o cada motor? Di el de PostgreSQL y el
   de MySQL. 🟡
9. `"PAGADO"` entre comillas dobles: di qué hace cada motor y por qué la diferencia es de categoría.
   🟡
10. MySQL y MariaDB: nombra tres divergencias medidas en este capítulo, con lo que hace cada uno. 🟡
11. Un informe con `sum(cantidad)/count(*)` se porta de MySQL a PostgreSQL y el número baja. Explica
    el mecanismo y da la forma que devuelve lo mismo en los cuatro. 🟠
12. `FILTER` frente a `SUM(CASE WHEN …)` sale igual en tiempo, y `NULLS LAST` frente a su forma
    portable sale 3 360× peor. ¿Qué distingue a los dos casos? 🟠
13. El apaño de `FULL OUTER JOIN` con `UNION ALL` tarda 1,7× lo que el nativo sobre los mismos
    datos. Explica de dónde sale ese factor mirando el mecanismo, no el plan. 🟠
14. Un compañero propone escribir todo el SQL en el mínimo común denominador "por si acaso". Dale el
    argumento en contra y di en qué tres casos tendría razón. 🟠
15. ¿Por qué un ORM no te hace portable? Apóyate en la tabla de §3 para decir qué traduce y qué no.
    🟠
16. Un lote inserta 10 000 filas en una transacción y falla en la 3 000. Di qué queda confirmado en
    MySQL, qué queda en PostgreSQL y cómo lo igualas. 🟠
17. Reescribe esta consulta para que corra sin cambios en los cuatro motores del corpus, y di qué
    pierdes con cada cambio: `SELECT p.estado || ' / ' || c.pais AS grupo, count(*) FILTER (WHERE
    p.total > 500) AS caros FROM pedidos p JOIN clientes c ON c.id = p.cliente_id GROUP BY
    p.estado, c.pais ORDER BY grupo NULLS LAST OFFSET 10 ROWS FETCH FIRST 5 ROWS ONLY;` 🔴
18. Da la lista de comprobación para portar una aplicación de MySQL 9.7.2 a PostgreSQL 18.6: qué
    revisas, en qué orden, y qué no detecta la suite de pruebas. 🔴
19. Escribe la conciliación de §4 —anulados contra pagos, con los dos descartes y la intersección—
    en una forma que corra en los cuatro, y di qué le cuesta a cada uno. 🔴
20. Diseña el criterio con el que tu equipo decide, consulta a consulta, si usa la forma portable o
    la del motor: tres reglas, aplicables sin medir cada vez. 🔴

---

**Anterior:** [`07`](07-escritura-upsert-y-vistas.md) · **Siguiente:**
[`09`](09-simulacion-de-entrevista.md) — la simulación del bloque · **Relacionado:**
[`03`](03-joins.md) — el `FULL OUTER JOIN` y su apaño, medidos allí en MySQL y aquí en PostgreSQL ·
[`01`](01-familias-del-lenguaje-y-tipos.md) — los tipos, la parte no portable que nadie mira ·
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) — por qué el
orden de los nulos necesita sintaxis propia.
