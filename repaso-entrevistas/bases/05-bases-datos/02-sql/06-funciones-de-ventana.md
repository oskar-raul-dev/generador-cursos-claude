# 06 — Funciones de ventana

> Por qué una función de ventana devuelve todas las filas donde `GROUP BY` devuelve una por grupo,
> qué hacen de verdad `ROW_NUMBER`, `RANK` y `DENSE_RANK` cuando hay empates, cómo se mira la fila
> de al lado con `LAG` y `LEAD`, y **el marco por defecto**, que es el detalle que más acumulados ha
> roto en silencio. **Asume leído:** [`04`](04-agregacion-y-subconsultas.md) — de ahí vienen `GROUP
> BY`, `HAVING` y la subconsulta correlacionada. **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema)
- [2. La ventana no colapsa filas](#2--la-ventana-no-colapsa-filas)
- [3. Las tres numeraciones y los empates](#3--las-tres-numeraciones-y-los-empates)
- [4. LAG y LEAD: la fila de al lado](#4--lag-y-lead-la-fila-de-al-lado)
- [5. El marco: ROWS, RANGE y el que pones sin
  querer](#5--el-marco-rows-range-y-el-que-pones-sin-querer)
- [6. Dónde se puede poner una ventana y dónde no](#6--dónde-se-puede-poner-una-ventana-y-dónde-no)
- [7. Los cuatro motores](#7-️-los-cuatro-motores)
- [8. Estándar, motor y convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes)
- [Para profundizar](#-para-profundizar)
- [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Comercial pide *"los tres pedidos de mayor importe de cada cliente"*. Empiezas por lo que sabes
hacer: agrupar por cliente y quedarte con el máximo, acotado a tres clientes para que termine:

```text
tienda=# SELECT c.codigo AS cliente, count(*) AS pedidos, max(p.total) AS mayor
tienda-#   FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
tienda-#  WHERE c.codigo BETWEEN 'CLI-00310' AND 'CLI-00312'
tienda-#  GROUP BY c.codigo ORDER BY c.codigo;
  cliente  | pedidos |  mayor
-----------+---------+----------
 CLI-00310 |      23 | 12110.79
 CLI-00311 |      52 | 14222.43
 CLI-00312 |      22 |  8820.96
(3 filas)

Duración: 50,525 ms
```

Tres filas, y ninguna dice **qué pedido** es el de 14 222,43. `GROUP BY` colapsó las 97 filas de
esos tres clientes en tres, y con ellas se fue el `codigo`: no se puede proyectar una columna que no
está agrupada ni agregada. Y aunque el `max` diera el primero, el segundo y el tercero no tienen
función de agregación que los nombre. Con lo del capítulo `04` esto sale, pero con una subconsulta
correlacionada por fila. La pregunta es si hay forma de **ver todas las filas y además saber en qué
puesto va cada una**.

---

## 2. 🧱 La ventana no colapsa filas

Una **función de ventana** (*window function*) se calcula sobre un conjunto de filas vecinas —la
**ventana**— y devuelve **un valor por cada fila de entrada**. Es la diferencia entera con la
agregación: `GROUP BY` devuelve una fila por grupo; la ventana devuelve todas las filas y le añade
una columna. Se escribe con `OVER`, y dentro van dos cosas: `PARTITION BY`, que corta la tabla en
grupos independientes, y `ORDER BY`, que ordena dentro de cada grupo.

```text
tienda=# WITH ranqueados AS (
tienda(#   SELECT c.codigo AS cliente, p.codigo AS pedido, p.total,
tienda(#          ROW_NUMBER() OVER (PARTITION BY p.cliente_id ORDER BY p.total DESC) AS puesto
tienda(#     FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
tienda(#    WHERE c.codigo BETWEEN 'CLI-00310' AND 'CLI-00312'
tienda(# )
tienda-# SELECT cliente, pedido, total, puesto FROM ranqueados
tienda-#  WHERE puesto <= 3 ORDER BY cliente, puesto;
  cliente  |   pedido   |  total   | puesto
-----------+------------+----------+--------
 CLI-00310 | PED-870380 | 12110.79 |      1
 CLI-00310 | PED-542007 | 11117.75 |      2
 CLI-00310 | PED-596772 | 10272.60 |      3
 CLI-00311 | PED-717934 | 14222.43 |      1
 CLI-00311 | PED-925005 | 13679.27 |      2
 CLI-00311 | PED-457687 | 10731.94 |      3
 CLI-00312 | PED-583442 |  8820.96 |      1
 CLI-00312 | PED-210818 |  8594.55 |      2
 CLI-00312 | PED-741811 |  6675.61 |      3
(9 filas)

Duración: 45,634 ms
```

- `PARTITION BY p.cliente_id` **reinicia la numeración en cada cliente**: por eso hay tres unos y no
  un único puesto 1 global. Sin esa cláusula la ventana sería la tabla entera.
- `ORDER BY p.total DESC` es **el orden de la ventana**, no el de la salida: el `ORDER BY` de fuera
  reordena la tabla sin cambiar ni un valor de `puesto`.
- La columna `pedido` sigue ahí, y **eso es lo que no se puede hacer con `GROUP BY`**.

**Quién lo manda:** los cuatro motores del corpus lo hacen así; la cláusula concreta de ISO/IEC 9075
no la he verificado, porque el estándar es de pago.

**Cuánto cuesta.** La ventana necesita las filas de cada partición juntas y ordenadas, y eso es un
nodo `Sort` con un `WindowAgg` encima; medido con `EXPLAIN (ANALYZE, BUFFERS)`, el `Sort` ordena las
97 filas de estos tres clientes en 29 kB de memoria. El precio crece con las filas de la partición,
no con las de la salida. Ese plan enseña además un regalo del planificador de PostgreSQL 18.6, la
línea `Run Condition: (row_number() OVER w1 <= 3)`: el `WHERE puesto <= 3` de fuera se metió
**dentro** del `WindowAgg`, que deja de producir filas en cuanto una partición pasa de tres. Leer un
plan entero es de [`03/05`](../03-el-motor-por-dentro/05-explain-y-explain-analyze.md). Y frente a
la forma anterior a las ventanas —una subconsulta correlacionada, una ejecución por fila candidata—
la misma respuesta cuesta **3862,349 ms contra 45,634 ms**, 85 veces más.

> **Veredicto:** si la pregunta empieza por *"los N mejores de cada…"* o *"comparado con el
> anterior…"*, la respuesta es una ventana. `GROUP BY` solo sirve cuando de verdad quieres perder
> las filas.

---

## 3. 🧱 Las tres numeraciones y los empates

Las tres parecen lo mismo y solo se distinguen **cuando hay empates** en el `ORDER BY` de la
ventana. Los diez clientes del entorno de `CLI-00311` los traen de fábrica: un triple empate en 20
pedidos y uno doble en 22. Las tres columnas, en la misma salida:

```text
tienda=# WITH por_cliente AS (
tienda(#   SELECT c.codigo AS cliente, count(*) AS pedidos
tienda(#     FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
tienda(#    WHERE c.codigo LIKE 'CLI-0031_'
tienda(#    GROUP BY c.codigo
tienda(# )
tienda-# SELECT cliente, pedidos,
tienda-#        ROW_NUMBER() OVER v AS fila,
tienda-#        RANK()       OVER v AS rango,
tienda-#        DENSE_RANK() OVER v AS denso
tienda-#   FROM por_cliente
tienda-# WINDOW v AS (ORDER BY pedidos DESC)
tienda-#  ORDER BY pedidos DESC, cliente;
  cliente  | pedidos | fila | rango | denso
-----------+---------+------+-------+-------
 CLI-00311 |      52 |    1 |     1 |     1
 CLI-00319 |      24 |    2 |     2 |     2
 CLI-00310 |      23 |    3 |     3 |     3
 CLI-00312 |      22 |    4 |     4 |     4
 CLI-00318 |      22 |    5 |     4 |     4
 CLI-00317 |      21 |    6 |     6 |     5
 CLI-00314 |      20 |    8 |     7 |     6
 CLI-00315 |      20 |    9 |     7 |     6
 CLI-00316 |      20 |    7 |     7 |     6
 CLI-00313 |      17 |   10 |    10 |     7
(10 filas)

Duración: 54,591 ms
```

- **`ROW_NUMBER` no repite nunca**: 1..10 sin huecos. A los tres clientes de 20 pedidos les reparte
  8, 9 y 7, y ese reparto es **arbitrario** —fíjate en que la fila 7 aparece la tercera—, porque el
  `ORDER BY` de la ventana no los distingue. Para que sea reproducible, **añade a la ventana una
  columna que desempate**: `ORDER BY pedidos DESC, cliente`.
- **`RANK` repite y salta**: los dos de 22 son `4` y el siguiente es `6`, no `5`; el salto vale por
  cuántos empataron. Tras el triple empate en `7`, el último es `10`.
- **`DENSE_RANK` repite y no salta**: 4, 4, 5, 6, 6, 6, 7. Cuenta valores distintos, no filas.
- `WINDOW v AS (…)` nombra la ventana una vez y las tres funciones la usan. Escribirla tres veces
  cuesta lo mismo —el motor reconoce las ventanas iguales—, pero se retoca en tres sitios.

**Quién lo manda:** las tres funciones y la cláusula `WINDOW` dan lo mismo en los cuatro motores
—medido en §7—; la cláusula del estándar no la he verificado. **Cuánto cuesta:** nada por encima de
la ventana, porque las tres comparten el mismo `Sort`. **Cuándo no**: `ROW_NUMBER` para un ranking
que se publica; dos personas con el mismo número no pueden quedar en puestos distintos.

> **⚠️ Advertencia.** `ROW_NUMBER` sobre un `ORDER BY` con empates **no es determinista**: la misma
> consulta y los mismos datos dan repartos distintos según el motor. En §7 están los cuatro pegados,
> y son dos repartos: PostgreSQL y MariaDB por un lado, MySQL y SQLite por el otro. Si el número se
> guarda, se factura o se pagina, el `ORDER BY` de la ventana tiene que ser único.

---

## 4. 🧱 LAG y LEAD: la fila de al lado

`LAG(expr)` devuelve el valor de `expr` en la **fila anterior** de la ventana y `LEAD(expr)` el de
la **siguiente**; fuera del borde devuelven nulo, salvo que les des un tercer argumento con el valor
por defecto. Con ellas se responde *"¿cuánto varió respecto del pedido anterior?"* sin unir la tabla
consigo misma. Sobre los 52 pedidos de `CLI-00311`, los ocho primeros:

```text
tienda=# SELECT p.codigo, p.creado_en::date AS dia, p.total,
tienda-#        LAG(p.total)  OVER v AS anterior,
tienda-#        p.total - LAG(p.total) OVER v AS delta,
tienda-#        LEAD(p.creado_en::date) OVER v AS dia_siguiente
tienda-#   FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
tienda-#  WHERE c.codigo = 'CLI-00311'
tienda-# WINDOW v AS (ORDER BY p.creado_en)
tienda-#  ORDER BY p.creado_en
tienda-#  LIMIT 8;
   codigo   |    dia     |  total  | anterior |  delta   | dia_siguiente
------------+------------+---------+----------+----------+---------------
 PED-956061 | 2023-01-06 | 6445.28 |          |          | 2023-02-17
 PED-254970 | 2023-02-17 | 1473.84 |  6445.28 | -4971.44 | 2023-02-21
 PED-388526 | 2023-02-21 | 6246.78 |  1473.84 |  4772.94 | 2023-03-10
 PED-698306 | 2023-03-10 | 5662.14 |  6246.78 |  -584.64 | 2023-05-12
 PED-154641 | 2023-05-12 | 1589.47 |  5662.14 | -4072.67 | 2023-05-13
 PED-213670 | 2023-05-13 | 5587.39 |  1589.47 |  3997.92 | 2023-05-19
 PED-972484 | 2023-05-19 | 2099.76 |  5587.39 | -3487.63 | 2023-05-20
 PED-869060 | 2023-05-20 | 5253.58 |  2099.76 |  3153.82 | 2023-08-01
(8 filas)

Duración: 59,007 ms
```

- **La primera fila no tiene anterior**, así que `anterior` y `delta` son nulos. Ese borde se
  decide: `LAG(p.total, 1, 0)` devolvería 0 y el `delta` saldría igual al total, que para una
  gráfica suele ser peor que el hueco.
- `LEAD` mira hacia delante **dentro de la misma ventana**, no en la tabla. Aquí no hay `PARTITION
  BY` porque el `WHERE` ya dejó un solo cliente; con `PARTITION BY p.cliente_id`, **`LAG` no
  cruzaría de un cliente al siguiente**, que es justo el trabajo de la partición.

**Quién lo manda:** los cuatro motores. **Cuánto cuesta:** el mismo `Sort` de siempre; no añaden
pasadas. **Cuándo no**: si quieres el valor anterior *por fecha de calendario* y hay días sin
pedido, `LAG` te da el pedido anterior, no el día anterior, y hace falta generar el calendario, que
es de [`05`](05-cte-y-recursion.md).

> **💡 Truco.** `creado_en - LAG(creado_en) OVER (ORDER BY creado_en)` audita una serie temporal en
> una pasada: cero es un duplicado y más que el umbral es un hueco.

---

## 5. 🧱 El marco: ROWS, RANGE y el que pones sin querer

Hasta aquí la ventana era "todas las filas de la partición", y no es del todo cierto: dentro de la
partición cada fila tiene además un **marco** (*frame*), el subconjunto sobre el que se evalúa la
función. Ese marco tiene un valor por defecto que casi nadie escribe y casi nadie conoce:

```text
sin ORDER BY en la ventana  ->  RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
con ORDER BY en la ventana  ->  RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

La trampa está en la segunda línea, en la palabra `RANGE`. `ROWS` cuenta **filas**: *current row* es
esta fila y ninguna más. `RANGE` razona sobre **valores del `ORDER BY`**: *current row* significa
"esta fila y todas las que empatan con ella". El mismo `SUM` acumulado de las dos formas, sobre los
diez clientes de §3:

```text
tienda=# WITH por_cliente AS (
tienda(#   SELECT c.codigo AS cliente, count(*) AS pedidos
tienda(#     FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
tienda(#    WHERE c.codigo LIKE 'CLI-0031_'
tienda(#    GROUP BY c.codigo
tienda(# )
tienda-# SELECT cliente, pedidos,
tienda-#        SUM(pedidos) OVER (ORDER BY pedidos DESC) AS acum_range,
tienda-#        SUM(pedidos) OVER (ORDER BY pedidos DESC
tienda(#                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS acum_rows
tienda-#   FROM por_cliente
tienda-#  ORDER BY pedidos DESC, cliente;
  cliente  | pedidos | acum_range | acum_rows
-----------+---------+------------+-----------
 CLI-00311 |      52 |         52 |        52
 CLI-00319 |      24 |         76 |        76
 CLI-00310 |      23 |         99 |        99
 CLI-00312 |      22 |        143 |       121
 CLI-00318 |      22 |        143 |       143
 CLI-00317 |      21 |        164 |       164
 CLI-00314 |      20 |        224 |       204
 CLI-00315 |      20 |        224 |       224
 CLI-00316 |      20 |        224 |       184
 CLI-00313 |      17 |        241 |       241
(10 filas)

Duración: 57,748 ms
```

- **Las tres primeras filas coinciden** porque 52, 24 y 23 no empatan con nadie. El marco por
  defecto solo muerde donde hay valores repetidos.
- **En el empate de 22, `acum_range` salta de 99 a 143 de golpe y lo repite.** Las dos filas de 22
  comparten marco —`RANGE` mete en él a las dos—, así que las dos ven el acumulado *después* de
  ambas. La columna `acum_rows` hace lo que esperabas: 121 y luego 143, fila a fila.
- **En el triple empate de 20 se ve mejor:** `acum_range` da 224, 224, 224 y `acum_rows` da 204, 224
  y 184. Esos tres no están desordenados por error: `acum_rows` avanza por el orden **interno** de
  la ventana, el de la columna `fila` de §3 —`CLI-00316` es la 7 y se lleva 184, `CLI-00314` la 8 y
  204, `CLI-00315` la 9 y cierra en 224—, mientras la salida va ordenada por `cliente`. **Las dos
  rarezas del capítulo son la misma:** el `ORDER BY` de la ventana no desempata.
- **Cuánto cuesta:** nada en tiempo —las dos columnas salen del mismo `Sort`— y todo en
  credibilidad. Un acumulado que salta es un informe que cuadra al final y miente en el medio.

El marco también sirve para lo contrario: acotarlo. Una media móvil de tres pedidos y un conteo de
los últimos 30 días, sobre los mismos pedidos de `CLI-00311`:

```text
tienda=# SELECT p.creado_en::date AS dia, p.total,
tienda-#        round(AVG(p.total) OVER (ORDER BY p.creado_en
tienda(#                                 ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS media_movil_3,
tienda-#        count(*) OVER (ORDER BY p.creado_en
tienda(#                       RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW) AS ult_30_dias
tienda-#   FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
tienda-#  WHERE c.codigo = 'CLI-00311'
tienda-#  ORDER BY p.creado_en LIMIT 8;
    dia     |  total  | media_movil_3 | ult_30_dias
------------+---------+---------------+-------------
 2023-01-06 | 6445.28 |       6445.28 |           1
 2023-02-17 | 1473.84 |       3959.56 |           1
 2023-02-21 | 6246.78 |       4721.97 |           2
 2023-03-10 | 5662.14 |       4460.92 |           3
 2023-05-12 | 1589.47 |       4499.46 |           1
 2023-05-13 | 5587.39 |       4279.67 |           2
 2023-05-19 | 2099.76 |       3092.21 |           3
 2023-05-20 | 5253.58 |       4313.58 |           4
(8 filas)

Duración: 56,446 ms
```

- `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` es un marco de tres **filas**: en la primera solo hay
  una y la media es el propio total. No se rellena con ceros.
- `RANGE BETWEEN INTERVAL '30 days' PRECEDING` es un marco de **valor**: cuenta los pedidos cuyo
  `creado_en` cae en los 30 días anteriores al de esta fila. Por eso el 12 de mayo vuelve a 1, con
  el anterior el 10 de marzo. Aquí `RANGE` es lo correcto y `ROWS` respondería otra pregunta.

> **Veredicto:** en un acumulado, el marco se escribe siempre. `ROWS BETWEEN UNBOUNDED PRECEDING AND
> CURRENT ROW` es lo que quiere decir casi todo el mundo cuando escribe `SUM(...) OVER (ORDER BY
> ...)`, y el motor le pone `RANGE`.

> **🧠 Modelo mental.** `ROWS` cuenta filas y `RANGE` compara valores. Si el `ORDER BY` de la ventana
> tiene repetidos y no escribes marco, PostgreSQL, MySQL, MariaDB y SQLite te ponen `RANGE … CURRENT
> ROW` y tu acumulado avanza por escalones. Para un acumulado fila a fila, `ROWS` se escribe
> siempre, aunque hoy la columna no tenga empates.

---

## 6. 🩺 Dónde se puede poner una ventana y dónde no

Una ventana se evalúa **en el paso del `SELECT`**: después de `FROM`, `WHERE`, `GROUP BY` y
`HAVING`, y antes de `ORDER BY` y `LIMIT`. El orden lógico completo es de
[`02`](02-select-y-el-orden-logico.md); aquí importa la consecuencia: **cuando el `WHERE` se evalúa,
la columna de la ventana todavía no existe**. Los tres intentos naturales fallan.

```text
tienda=# SELECT p.codigo, p.total,
tienda-#        ROW_NUMBER() OVER (PARTITION BY p.cliente_id ORDER BY p.total DESC) AS puesto
tienda-#   FROM pedidos p
tienda-#  WHERE ROW_NUMBER() OVER (PARTITION BY p.cliente_id ORDER BY p.total DESC) <= 3;
ERROR:  window functions are not allowed in WHERE
LÍNEA 1: ...R BY p.total DESC) AS puesto FROM pedidos p WHERE ROW_NUMBER...
                                                              ^
tienda=# SELECT p.cliente_id, count(*) FROM pedidos p
tienda-#  GROUP BY p.cliente_id
tienda-# HAVING RANK() OVER (ORDER BY count(*) DESC) <= 3;
ERROR:  window functions are not allowed in HAVING
tienda=# SELECT p.codigo,
tienda-#        ROW_NUMBER() OVER (PARTITION BY p.cliente_id ORDER BY p.total DESC) AS puesto
tienda-#   FROM pedidos p WHERE puesto <= 3;
ERROR:  column "puesto" does not exist
```

- Los dos primeros son **el mismo error con dos nombres**: el `WHERE` filtra filas de entrada y el
  `HAVING` filtra grupos, y las dos cosas pasan antes de que exista la ventana.
- El tercero despista porque parece otra cosa: el alias `puesto` tampoco vale en el `WHERE`, y el
  motor ni lo menciona como ventana. Es la regla del alias del `SELECT`, que ya salió en `02`.
- **La corrección es envolver**: una CTE o una subconsulta en el `FROM` que calcule la ventana, y un
  `WHERE` de fuera sobre su resultado. Es lo que hace §2, y no cuesta un paso más, porque ahí el
  planificador metió el filtro dentro del `WindowAgg` como `Run Condition`.

Dónde **sí** se puede: en la lista del `SELECT` y en el `ORDER BY` de la consulta, y también **sobre
el resultado de una agregación**, que es lo que más se olvida. Como la ventana se calcula después
del `GROUP BY`, `SUM(count(*)) OVER (ORDER BY count(*) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND
CURRENT ROW)` sobre `GROUP BY p.estado` es legal: el `count(*)` lo resuelve el grupo y el `SUM` de
ventana acumula sobre esas cinco filas ya agregadas —300 000, 570 000, 820 000, 940 000 y 1 000
000—, que cierra en el millón de pedidos del corpus.

---

## 7. ⚖️ Los cuatro motores

Es de las pocas cosas del SQL moderno donde los cuatro motores coinciden casi del todo, porque
llegaron tarde y ya estandarizadas: **MySQL las estrenó en la 8.0, el 19 de abril de 2018, y SQLite
en la 3.25, el 15 de septiembre del mismo año**; PostgreSQL las tenía desde la 8.4, de 2009. La
consulta de §3 y §5 con las cinco columnas juntas, corrida en los otros tres. De MariaDB y de SQLite
se reproducen solo las tres filas del triple empate, que es lo único que cambia:

```text
-- MySQL 9.7.2, la misma consulta de §3 y §5
+-----------+---------+------+-------+-------+------------+-----------+
| cliente   | pedidos | fila | rango | denso | acum_range | acum_rows |
+-----------+---------+------+-------+-------+------------+-----------+
| CLI-00311 |      52 |    1 |     1 |     1 |         52 |        52 |
| CLI-00319 |      24 |    2 |     2 |     2 |         76 |        76 |
| CLI-00310 |      23 |    3 |     3 |     3 |         99 |        99 |
| CLI-00312 |      22 |    4 |     4 |     4 |        143 |       121 |
| CLI-00318 |      22 |    5 |     4 |     4 |        143 |       143 |
| CLI-00317 |      21 |    6 |     6 |     5 |        164 |       164 |
| CLI-00314 |      20 |    7 |     7 |     6 |        224 |       184 |
| CLI-00315 |      20 |    8 |     7 |     6 |        224 |       204 |
| CLI-00316 |      20 |    9 |     7 |     6 |        224 |       224 |
| CLI-00313 |      17 |   10 |    10 |     7 |        241 |       241 |
+-----------+---------+------+-------+-------+------------+-----------+

-- MariaDB 12.3.3: idéntica salvo las tres filas del triple empate
| CLI-00314 |      20 |    8 |     7 |     6 |        224 |       204 |
| CLI-00315 |      20 |    7 |     7 |     6 |        224 |       184 |
| CLI-00316 |      20 |    9 |     7 |     6 |        224 |       224 |
```

```text
-- SQLite 3.53.4: idéntica a la de MySQL en las diez filas, columna fila incluida
| CLI-00314 |      20 |    7 |     7 |     6 |        224 |       184 |
| CLI-00315 |      20 |    8 |     7 |     6 |        224 |       204 |
| CLI-00316 |      20 |    9 |     7 |     6 |        224 |       224 |
```

- **`RANK`, `DENSE_RANK`, el marco por defecto `RANGE` y la cláusula `WINDOW` con nombre dan lo
  mismo en los cuatro.** `acum_range` es 143, 143 y 224, 224, 224 en todos: el marco por defecto no
  es una rareza de PostgreSQL.
- **`ROW_NUMBER` dentro del empate no reparte igual en todos**: PostgreSQL y MariaDB dan 8-9-7, y
  MySQL y SQLite dan 7-8-9. Cuatro salidas, dos repartos, y **ninguna pareja es la que esperarías**
  —MariaDB se va con PostgreSQL y no con MySQL—. Es la demostración de §3 y no hace falta ninguna
  otra.

Donde sí divergen es en los extras. Todo lo de esta tabla está medido en esta edición:

| Cláusula | PostgreSQL 18.6 | MySQL 9.7.2 | MariaDB 12.3.3 | SQLite 3.53.4 |
|---|---|---|---|---|
| `WINDOW v AS (…)` con nombre | ✅ | ✅ | ✅ | ✅ |
| `agregado(…) FILTER (WHERE …) OVER (…)` | ✅ | ❌ `ERROR 1064` de sintaxis | ❌ `ERROR 1064` de sintaxis | ✅ |
| `GROUPS` como modo de marco | ✅ | ❌ `ERROR 1235 … doesn't yet support 'GROUPS'` | ❌ `ERROR 1064` de sintaxis | ✅ |
| `EXCLUDE CURRENT ROW` y compañía | ✅ | ❌ `ERROR 1235 … doesn't yet support 'EXCLUDE'` | ❌ `ERROR 4022 Frame exclusion is not supported yet` | ✅ |
| `RANGE BETWEEN INTERVAL … PRECEDING` | ✅ | ✅ | ❌ `ERROR 1064` de sintaxis | ❌ no hay tipo intervalo |
| `RANGE BETWEEN <número> PRECEDING` | ✅ | ✅ | ✅ | ✅ |
| Ventana en el `WHERE` | ❌ `not allowed in WHERE` | ❌ `ERROR 3593` | ❌ `ERROR 4015` | ❌ `misuse of window function` |

**El patrón que deja la tabla:** SQLite, el motor pequeño, implementa **más** que MySQL y MariaDB; y
MariaDB, que suele ir por delante de MySQL, aquí va por detrás en marcos de intervalo. Si el código
tiene que correr en los cuatro, el subconjunto seguro es `PARTITION BY`, `ORDER BY` y `ROWS`/`RANGE`
con `UNBOUNDED`, `CURRENT ROW` y desplazamientos numéricos. Qué es portable en general es de
[`08`](08-dialectos.md).

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas en esta
> edición**. Donde la columna "Estándar" dice *no verificado*, lo afirmado es lo que hacen los
> cuatro motores, medido en sesión.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| Una ventana devuelve una fila por fila de entrada | No verificado | Sí | Sí | Sí |
| El marco por defecto con `ORDER BY` es `RANGE … CURRENT ROW` | No verificado | Sí (medido: 143, 143) | Sí (143, 143) | Sí (143, 143) |
| `RANK` salta y `DENSE_RANK` no | No verificado | Sí | Sí | Sí |
| `ROW_NUMBER` es determinista con empates | No verificado; no lo puede ser sin orden total | **No**: 8-9-7 | **No**: 7-8-9 | **No**: 7-8-9 |
| Una ventana se puede usar en el `WHERE` | No verificado | **No** | **No** (`ERROR 3593`) | **No** (*misuse*) |
| `FILTER` se admite sobre una ventana | No verificado | Sí | **No**: `ERROR 1064` | Sí |
| Existen los modos de marco `GROUPS` y `EXCLUDE` | No verificado | Sí | **No**: `ERROR 1235` | Sí |

MariaDB 12.3.3 acompaña a MySQL en `FILTER`, `GROUPS` y `EXCLUDE` —las tres faltan— y se separa en
dos sitios: **reparte el empate de `ROW_NUMBER` como PostgreSQL**, 8-9-7 y no el 7-8-9 de MySQL, y
**rechaza `RANGE BETWEEN INTERVAL … PRECEDING`**, que MySQL sí acepta.

**Convención:** *"las ventanas son lentas, mejor un `GROUP BY` con una subconsulta"*. Viene de
cuando MySQL no las tenía y había que emularlas con variables de sesión. Hoy es al revés: el top-3
de §2 tarda **45,634 ms con ventana y 3862,349 ms con subconsulta correlacionada**. La otra media
verdad, *"`RANK` y `ROW_NUMBER` son lo mismo"*, vale hasta el primer empate.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Una función de ventana agrupa como `GROUP BY`" | No agrupa: no colapsa ninguna fila. Devuelve todas y añade una columna calculada sobre las vecinas |
| "`RANK` y `ROW_NUMBER` son lo mismo" | Solo sin empates. Con dos empatados, `RANK` da 4, 4, 6; `DENSE_RANK` da 4, 4, 5; `ROW_NUMBER` da 4, 5 en orden arbitrario |
| "Si no pongo marco, no hay marco" | Con `ORDER BY` en la ventana el marco por defecto es `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`, y agrupa los empates: el acumulado salta de 99 a 143 y lo repite |
| "`ROWS` y `RANGE` son sinónimos" | `ROWS` cuenta filas; `RANGE` compara valores del `ORDER BY`. Coinciden solo si ese orden no tiene repetidos |
| "`ROW_NUMBER` siempre da el mismo número a la misma fila" | Con empates en el `ORDER BY` de la ventana, no. Medido: PostgreSQL y MariaDB 8-9-7, MySQL y SQLite 7-8-9 |
| "Filtro por la ventana en el `WHERE`" | La ventana se evalúa en el paso del `SELECT`. En el `WHERE` y en el `HAVING` todavía no existe: hay que envolver en CTE o subconsulta |
| "Las ventanas son de PostgreSQL" | Los cuatro motores del corpus las tienen. MySQL desde la 8.0 y SQLite desde la 3.25, las dos de 2018 |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Window Function Calls»: `PARTITION BY`, `ORDER BY`, los tres
  modos de marco y el marco por defecto. <https://www.postgresql.org/docs/18/sql-expressions.html>
- **Documentación** — PostgreSQL 18, «Window Functions»: la lista de `ROW_NUMBER`, `RANK`,
  `DENSE_RANK`, `LAG`, `LEAD` y `NTILE`. <https://www.postgresql.org/docs/18/functions-window.html>
- **Documentación** — PostgreSQL 18, «Window Functions» del tutorial: por qué no se pueden usar en
  el `WHERE`. <https://www.postgresql.org/docs/18/tutorial-window.html>
- **Documentación** — MySQL 9.7, «Window Function Frame Specification»: los marcos, y qué modos no
  están. <https://dev.mysql.com/doc/refman/9.7/en/window-functions-frames.html>
- **Documentación** — SQLite, «Window Functions»: `FILTER`, `GROUPS` y `EXCLUDE`, que están desde la
  3.25 y la 3.28. <https://www.sqlite.org/windowfunctions.html>
- **Documentación** — MariaDB, «Window Functions»: la lista de lo soportado y los huecos.
  <https://mariadb.com/docs/server/reference/sql-functions/special-functions/window-functions>
- **Estándar** — ISO/IEC 9075-2 (*Foundation*), `<window function>` y `<window frame clause>`. De
  pago, sin URL pública y **no verificada en esta edición**.

---

## 🧠 Preguntas

1. ¿Cuántas filas devuelve una ventana comparada con `GROUP BY`, y qué se puede proyectar con una
   que no con el otro? 🟢
2. Nombra las dos cláusulas que van dentro de `OVER` y di qué hace cada una. 🟢
3. ¿Qué devuelven `LAG` y `LEAD` en los bordes de una partición, y cómo se cambia? 🟢
4. Escribe el marco por defecto cuando la ventana lleva `ORDER BY`, y di si lo fija el estándar o
   cada motor. 🟢
5. Con los diez clientes de §3, ¿qué tres valores da `RANK` en el triple empate de 20 pedidos, y
   cuál es el siguiente rango? 🟢
6. Distingue `ROW_NUMBER`, `RANK` y `DENSE_RANK` en una frase por cada uno. 🟡
7. Distingue `ROWS` de `RANGE` y di en qué caso dan exactamente el mismo resultado. 🟡
8. ¿Por qué el `ORDER BY` de la ventana y el de la consulta son independientes? 🟡
9. ¿Dónde se evalúa una ventana en el orden lógico, y qué dos cláusulas quedan vetadas? 🟡
10. `FILTER` sobre una ventana, ¿estándar o motor? Di qué hace cada uno de los cuatro. 🟡
11. La cláusula `WINDOW v AS (…)`, ¿qué ahorra de verdad y qué no ahorra? 🟡
12. `SUM(count(*)) OVER (…)` no es un error de escritura. Explica por qué se puede escribir eso. 🟠
13. En §5, `acum_range` da 143 dos veces y `acum_rows` da 121 y 143. Explica el mecanismo exacto que
    produce esa diferencia. 🟠
14. Los tres clientes empatados en 20 reciben 8, 9 y 7 en PostgreSQL y 7, 8, 9 en MySQL. ¿Incumple
    alguno el estándar? Justifica y di cómo se arregla. 🟠
15. El top-3 por cliente tarda 45,634 ms con ventana y 3862,349 ms con subconsulta correlacionada.
    Explica de dónde sale la diferencia, nombrando el nodo del plan. 🟠
16. Alguien escribe `WHERE puesto <= 3` y el motor responde `column "puesto" does not exist` en
    lugar de hablar de ventanas. ¿Por qué ese mensaje y no el otro? 🟠
17. ¿En qué caso `RANGE` es la respuesta correcta y `ROWS` la equivocada? Usa el ejemplo de los 30
    días de §5. 🟠
18. Escribe la consulta que dé, por cada uno de los cinco estados de `pedidos`, los dos pedidos de
    mayor `total`, con su puesto. Que corra en PostgreSQL 18.6. 🔴
19. Un informe de acumulado mensual "cuadra al final pero miente en el medio". Da las tres hipótesis
    en orden de probabilidad y la consulta con la que confirmarías la primera. 🔴
20. Escribe la consulta que detecte, sobre `eventos_pedido` de un pedido, los huecos de más de un
    día entre eventos consecutivos, y di qué marco usa. 🔴
21. La misma consulta de ranking tiene que dar el mismo número de puesto en PostgreSQL, MySQL,
    MariaDB y SQLite. Escríbela y señala las dos decisiones que lo garantizan. 🔴

---

**Anterior:** [`05`](05-cte-y-recursion.md) · **Siguiente:** [`07`](07-escritura-upsert-y-vistas.md)
· **Relacionado:** [`04`](04-agregacion-y-subconsultas.md) — `GROUP BY` y la subconsulta
correlacionada contra la que se mide el top-N · [`02`](02-select-y-el-orden-logico.md) — el orden
lógico que explica por qué la ventana no puede ir en el `WHERE` · [`08`](08-dialectos.md) — la tabla
maestra de lo que cambia entre los cuatro motores.
