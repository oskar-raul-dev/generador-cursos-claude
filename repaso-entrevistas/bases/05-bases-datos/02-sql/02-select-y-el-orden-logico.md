# 02 — `SELECT` y el orden lógico

> El esqueleto de una consulta —qué columnas pides, qué filas te quedas, en qué orden y cuántas— y
> por encima de todo el **orden lógico de evaluación**, que no es el orden en que escribes las
> cláusulas. De ahí salen casi todos los "¿por qué no me deja?" del principiante y unos cuantos del
> senior. **Asume leído:** [`01`](01-familias-del-lenguaje-y-tipos.md) — de ahí vienen los tipos con
> los que se comparan y se ordenan los valores. **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema)
- [2. El orden lógico de evaluación](#2--el-orden-lógico-de-evaluación)
- [3. El alias, y dónde se le puede llamar por su nombre](#3--el-alias-y-dónde-se-le-puede-llamar-por-su-nombre)
- [4. `WHERE` filtra filas, `HAVING` filtra grupos](#4-️-where-filtra-filas-having-filtra-grupos)
- [5. `ORDER BY` y `LIMIT`: lo que no garantizan](#5--order-by-y-limit-lo-que-no-garantizan)
- [6. `OFFSET` se degrada linealmente](#6--offset-se-degrada-linealmente)
- [7. Lo que se decide al final: `SELECT *` y `DISTINCT`](#7--lo-que-se-decide-al-final-select--y-distinct)
- [8. Estándar, motor y convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes)
- [Para profundizar](#-para-profundizar)
- [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Te piden el IVA de cada pedido, y solo los que pasan de 100. Escribes lo obvio, con el alias que
acabas de declarar dos palabras antes.

```text
tienda=# SELECT total * 0.21 AS iva FROM pedidos WHERE iva > 100 LIMIT 3;
ERROR:  column "iva" does not exist
LÍNEA 1: SELECT total * 0.21 AS iva FROM pedidos WHERE iva > 100 LIMI...
                                                       ^
Duración: 0,882 ms
```

El alias está escrito a la izquierda del `WHERE` y el motor dice que esa columna no existe. Esa
misma tarde, la pantalla de pedidos pagina bien al principio y se arrastra en la página 45 001:
**0,432 ms la primera, 631,392 ms la última**, misma consulta y un solo número cambiado. Los dos
síntomas tienen la misma causa, y no es el motor: **el orden en que se escribe un `SELECT` no es el
orden en que se evalúa**. Este capítulo es el dueño de ese concepto en todo el corpus.

---

## 2. 🧱 El orden lógico de evaluación

Un `SELECT` se escribe en un orden pensado para leerse en inglés y se evalúa en otro, pensado para
producir el resultado:

| Se escribe | Se evalúa | Qué hace en ese paso |
|---|---|---|
| 1 `SELECT` | 5 | Calcula las expresiones y **bautiza los alias** |
| 2 `FROM` | 1 | Resuelve las tablas y sus combinaciones |
| 3 `WHERE` | 2 | Descarta **filas**, una a una |
| 4 `GROUP BY` | 3 | Colapsa las filas supervivientes en **grupos** |
| 5 `HAVING` | 4 | Descarta **grupos** |
| 6 `ORDER BY` | 7 | Ordena lo que ya salió del `SELECT` |
| 7 `LIMIT` / `OFFSET` | 8 | Corta el resultado ya ordenado |

`DISTINCT` es el paso 6, entre el `SELECT` y el `ORDER BY`, y por eso tiene su propia trampa en §7.
**Esto es semántica, no implementación:** el motor reordena el trabajo real todo lo que quiera
mientras el resultado no cambie, y lo hace —empuja filtros hacia abajo, corta antes de terminar de
ordenar—. Lo que no puede cambiar es **qué nombres son visibles en cada cláusula**, y ahí el orden
lógico deja de ser teoría.

> **🧠 Modelo mental.** `FROM` → `WHERE` → `GROUP BY` → `HAVING` → `SELECT` → `DISTINCT` → `ORDER BY`
> → `LIMIT`. Un nombre solo existe a partir del paso que lo crea.

---

## 3. 🧱 El alias, y dónde se le puede llamar por su nombre

El alias nace en el paso 5. La consulta de §1 lo pedía en el paso 2, cuando todavía no existía nada
con ese nombre. Movido al `ORDER BY` —paso 7— funciona sin tocar nada más:

```text
tienda=# SELECT total * 0.21 AS iva FROM pedidos ORDER BY iva DESC LIMIT 3;
    iva
-----------
 4547.7747
 4424.3388
 4410.8652
(3 filas)

Duración: 116,940 ms
```

- **Cuánto cuesta:** 116,940 ms contra los 0,882 ms del error. No es el alias: es que esta sí se
  ejecuta, y ordenar un millón de expresiones calculadas obliga a recorrer la tabla entera.
- **La versión que falla se arregla** repitiendo la expresión —`WHERE total * 0.21 > 100`—, con una
  subconsulta o con un `WITH`. La repetición es la más barata: no materializa nada.

Y aquí la sorpresa que nadie espera de PostgreSQL, que tiene fama de estricto: **el alias sí vale en
el `GROUP BY`, y no vale en el `HAVING`**, aunque el `HAVING` se evalúe después.

```text
tienda=# SELECT estado AS situacion, count(*) FROM pedidos GROUP BY situacion;
 situacion | count
-----------+--------
 ENVIADO   | 270000
 ANULADO   |  60000
 PENDIENTE | 120000
 PAGADO    | 250000
 ENTREGADO | 300000
(5 filas)

tienda=# SELECT estado, count(*) AS n FROM pedidos GROUP BY estado HAVING n > 100000;
ERROR:  column "n" does not exist
LÍNEA 1: ...count(*) AS n FROM pedidos GROUP BY estado HAVING n > 100000...
                                                              ^
```

- No sale del orden lógico. Las notas de compatibilidad de PostgreSQL lo cuentan: en SQL-92 el
  `ORDER BY` solo admite nombres de la lista de salida y el `GROUP BY` solo nombres de entrada, y
  **PostgreSQL extiende cada una para aceptar también la otra**. Esa extensión no llega al `HAVING`.
- **MySQL 9.7.2, MariaDB 12.3.3 y SQLite 3.53.4 sí aceptan el alias en el `HAVING`**: esa segunda
  consulta, corrida en MySQL, devuelve sin protestar los cuatro grupos que superan el umbral.
- **SQLite va más lejos que ninguno y lo admite hasta en el `WHERE`.** La consulta con la que abre
  este capítulo, la que PostgreSQL rechaza, allí devuelve filas:

```text
sqlite> SELECT total * 0.21 AS iva FROM pedidos WHERE iva > 100 LIMIT 3;
iva
1459.3592999999999
1083.138
1334.4555
```

> **Veredicto:** que tu consulta con el alias en el `WHERE` funcione no significa que sea correcta;
> significa que estás en SQLite. Escríbela para el motor estricto y correrá en los cuatro.

---

## 4. ⚖️ `WHERE` filtra filas, `HAVING` filtra grupos

La frase se recita en todas partes y casi siempre se entiende como una cuestión de rendimiento —"pon
el filtro lo antes posible"— cuando es **una cuestión de resultado**, y el orden lógico explica por
qué: el `WHERE` corre en el paso 2, antes de que existan los grupos; el `HAVING` en el 4, cuando los
agregados ya están calculados sobre lo que sobrevivió al `WHERE`.

Medido sobre el dominio: los clientes con 38 pedidos o más son **seis**; añadiendo `WHERE estado <>
'ANULADO'` son **tres**. No bajan solo los números —`CLI-00311` pasa de 52 a 49—, **desaparecen tres
clientes del informe** porque sin sus anulados no llegan al umbral. Las dos consultas son correctas
y responden a preguntas distintas: "38 compras o más" y "38 compras efectivas o más". Elegir mal no
da error: da un informe que nadie audita.

- **Cuánto cuesta:** nada, aquí. Las dos recorren el millón de pedidos igual, porque `estado` no
  tiene índice. La diferencia aparece cuando el filtro sí es indexable: lo que cabía en `WHERE` y se
  puso en `HAVING` se paga entero.
- **Cuándo va en `HAVING`:** solo cuando la condición habla de un agregado —`count(*)`,
  `sum(total)`—, que en el paso 2 todavía no existe. **Cuándo no:** cuando habla de una columna de
  la fila.

> **⚠️ Advertencia.** `WHERE` y `HAVING` no son intercambiables "con una penalización de
> rendimiento". Tratarlos como sinónimos es el camino corto al informe que no cuadra.

El desarrollo completo —con las sesiones de las dos formas y el caso donde cambian las medias y no
la membresía— es de [`04`](04-agregacion-y-subconsultas.md), que es el dueño de la agregación.

---

## 5. 🧱 `ORDER BY` y `LIMIT`: lo que no garantizan

**Una tabla no tiene orden**, y eso es del modelo relacional, no del motor: un `SELECT` sin `ORDER
BY` devuelve las filas como le convenga, y eso cambia entre dos versiones, dos planes o dos motores.
La misma consulta, los mismos datos:

```text
tienda=# SELECT codigo, estado FROM pedidos WHERE estado = 'ANULADO' LIMIT 3;
   codigo   | estado
------------+---------
 PED-178323 | ANULADO
 PED-115603 | ANULADO
 PED-71382  | ANULADO
(3 filas)

sqlite> SELECT codigo, estado FROM pedidos WHERE estado = 'ANULADO' LIMIT 3;
codigo|estado
PED-00024|ANULADO
PED-00051|ANULADO
PED-00077|ANULADO
```

MySQL 9.7.2 devuelve exactamente los tres de SQLite, en ese orden. Ninguno de los dos resultados
está mal: los dos cumplen lo que pediste, que era "tres cualesquiera". **`LIMIT` sin `ORDER BY` es
un muestreo, no una consulta.**

Lo que casi nadie dice es que **poner `ORDER BY` tampoco basta si la columna no es única**. `estado`
tiene cinco valores para un millón de filas: hay 60 000 candidatos empatados al primer puesto, y
cuál sale depende del algoritmo de ordenación que elija el plan.

Se comprueba forzando el segundo plan. Con `LIMIT 5` el `EXPLAIN (ANALYZE)` del primero declara
`Sort Method: top-N heapsort Memory: 25kB`; envolviendo la misma consulta en un `WITH … AS
MATERIALIZED`, que le prohíbe ese atajo y lo obliga a ordenar el millón entero, declara `Sort
Method: external merge Disk: 28904kB`. Dos planes, dos respuestas a la misma pregunta:

```text
tienda=# SELECT codigo, estado FROM pedidos ORDER BY estado LIMIT 5;
   codigo   | estado
------------+---------
 PED-71382  | ANULADO
 PED-84001  | ANULADO
 PED-178323 | ANULADO
 PED-115603 | ANULADO
 PED-204227 | ANULADO
(5 filas)

tienda=# WITH ordenado AS MATERIALIZED (SELECT codigo, estado FROM pedidos ORDER BY estado)
tienda-# SELECT * FROM ordenado LIMIT 5;
   codigo   | estado
------------+---------
 PED-108298 | ANULADO
 PED-345400 | ANULADO
 PED-407820 | ANULADO
 PED-60189  | ANULADO
 PED-480119 | ANULADO
(5 filas)
```

- **Cinco pedidos distintos sin que cambie ni un dato ni una letra del `ORDER BY`.** Y lo que cuesta
  el atajo: el `top-N heapsort` no escribe nada, la ordenación completa escribe y relee 28 MB de
  temporales. Por eso el motor lo prefiere cuando hay `LIMIT`.
- **Cómo se arregla:** un desempate. `ORDER BY estado, id` hace la ordenación **total** —`id` es
  único— y el resultado deja de depender del plan.

> **💡 Truco.** "`ORDER BY` sobre una columna no única más `LIMIT` es no determinista" vale más en
> una entrevista que recitar los ocho pasos. Y la coletilla que lo remata: **si la ordenación no es
> total, la paginación repite filas y pierde otras entre páginas.**

---

## 6. 🩺 `OFFSET` se degrada linealmente

`OFFSET n` no le dice al motor "empieza por la fila n". Le dice **"produce las n primeras y
tíralas"**. La primera página —`LIMIT 20 OFFSET 0`— se resuelve con el mismo plan que la que sigue,
un `Limit` sobre `Index Scan using pedidos_pkey`, en **0,432 ms y 23 páginas leídas**. Y ahora la
página 45 001, que es exactamente la misma consulta con otro número:

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS)
tienda-# SELECT id, codigo, total FROM pedidos ORDER BY id LIMIT 20 OFFSET 900000;
 Limit  (cost=26832.28..26832.88 rows=20 width=25) (actual time=631.355..631.370 rows=20.00 loops=1)
   Buffers: shared hit=894660 read=7569
   I/O Timings: shared read=72.862
   ->  Index Scan using pedidos_pkey on pedidos  (cost=0.42..29813.60 rows=1000000 width=25) (actual time=0.007..605.801 rows=900020.00 loops=1)
         Index Searches: 1
         Buffers: shared hit=894660 read=7569
         I/O Timings: shared read=72.862
 Planning Time: 0.018 ms
 Execution Time: 631.392 ms
(9 filas)
```

- **`rows=20.00` arriba y `rows=900020.00` abajo, en el mismo nodo `Index Scan`.** El motor produjo
  las 900 020 filas y entregó veinte; lo demás lo tiró.
- **Cuánto cuesta:** 0,432 ms contra 631,392 ms —**1 462 veces más**— y 23 páginas leídas contra 902
  229. El plan es idéntico: lo único que creció es el trabajo desperdiciado.
- **La alternativa es la paginación por clave**, que en vez de contar filas recuerda la última que
  vio: `WHERE id > 900000 ORDER BY id LIMIT 20`. Medida en la misma sesión con el mismo `EXPLAIN
  (ANALYZE, BUFFERS)`, da **0,374 ms y 26 páginas**, el mismo coste que la primera página, porque el
  índice baja directo al valor. Sus contrapartidas —no puedes saltar a una página arbitraria ni
  escribir "página 45 001 de 50 000"— y el patrón completo le tocan al bloque de diseño de
  consultas, que aún no está escrito; el mapa está en el [README](README.md) de este bloque.

> **⏱️ Coste.** El coste de `OFFSET n` es **O(n)**, no O(1). Si tu API pagina con `OFFSET` y alguien
> puede pedir la página 45 000, tienes una denegación de servicio escrita por ti mismo.

---

## 7. 🧱 Lo que se decide al final: `SELECT *` y `DISTINCT`

**`SELECT *` no se desaconseja por pereza: tiene tres costes medibles.** El primero es de contrato:
el día que alguien añade una columna a `pedidos`, tu consulta empieza a devolverla y el código que
lee por posición o serializa la fila entera cambia de comportamiento sin que nadie tocara esa línea.
El segundo es el ancho de fila, y lo dice el propio `EXPLAIN`: sobre el mismo rango de 100 003
pedidos, `SELECT codigo` planifica `width=10` y `SELECT *` planifica `width=57`, **5,7 veces más
bytes** por fila cruzando el motor, la red y el *driver*, con idéntico coste de lectura.

El tercero es el que más pesa y el que casi nadie nombra: **`SELECT *` renuncia al *index-only
scan*** (recorrido que se resuelve solo con el índice, sin bajar a la tabla).

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
tienda-# SELECT codigo FROM pedidos WHERE codigo BETWEEN 'PED-00040' AND 'PED-00049';
 Index Only Scan using pedidos_codigo_key on pedidos (actual rows=10.00 loops=1)
   Index Cond: ((codigo >= 'PED-00040'::text) AND (codigo <= 'PED-00049'::text))
   Heap Fetches: 10
   Index Searches: 1
   Buffers: shared hit=13
 Planning:
   Buffers: shared hit=92
(7 filas)

tienda=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
tienda-# SELECT * FROM pedidos WHERE codigo BETWEEN 'PED-00040' AND 'PED-00049';
 Index Scan using pedidos_codigo_key on pedidos (actual rows=10.00 loops=1)
   Index Cond: ((codigo >= 'PED-00040'::text) AND (codigo <= 'PED-00049'::text))
   Index Searches: 1
   Buffers: shared hit=13
(6 filas)
```

- Pidiendo solo `codigo` el nodo es `Index Only Scan`; pidiendo `*` es `Index Scan` a secas. La
  columna que sobra es la que obliga a bajar a la tabla.
- **Honestidad sobre el número:** hoy las dos leen 13 páginas, y el `Heap Fetches: 10` dice por qué.
  Esta tabla se cargó y nunca se le pasó un `VACUUM`, así que su *visibility map* (mapa de
  visibilidad) está vacío y el *index-only scan* **todavía visita la tabla**. Gana el nodo, no aún
  la E/S; con el mapa al día esas diez visitas desaparecen.

**`DISTINCT` es el paso 6**, y de ahí sale su limitación más confundida: **no puede eliminar
duplicados por una columna que no proyectaste**, porque opera sobre la fila proyectada entera.

```text
tienda=# SELECT count(*) FROM (SELECT DISTINCT estado FROM pedidos) t;
 count
-------
     5
(1 fila)

tienda=# SELECT count(*) FROM (SELECT DISTINCT estado, cliente_id FROM pedidos) t;
 count
--------
 229700
(1 fila)

tienda=# SELECT DISTINCT estado FROM pedidos ORDER BY creado_en LIMIT 3;
ERROR:  for SELECT DISTINCT, ORDER BY expressions must appear in select list
LÍNEA 1: SELECT DISTINCT estado FROM pedidos ORDER BY creado_en LIMIT...
                                                      ^
```

- Cinco filas con una columna y 229 700 con dos: añadir `cliente_id` a la proyección multiplica el
  resultado por 45 940. Y el error de la tercera es el orden lógico otra vez: el `ORDER BY` ya no ve
  `creado_en` porque el `DISTINCT` colapsó las filas y esa columna dejó de existir.
- **Cuándo no usarlo:** cuando lo que quieres es "una fila por cliente". Para eso está `DISTINCT ON
  (cliente_id)` en PostgreSQL, o una función de ventana, que es portable y tiene su capítulo en este
  mismo bloque.

> **📝 Contexto.** El consejo *"`SELECT *` es más lento"* que circula desde los foros de los 2000 se
> justificaba solo con el ancho de fila. El argumento fuerte de hoy es el *index-only scan*, que en
> PostgreSQL no existió hasta la versión 9.2 y por eso no aparece en esos hilos.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas** para esta
> tabla salvo donde se dice lo contrario. Donde la columna "Estándar" dice *no verificado*, lo
> afirmado es lo que hacen los motores, comprobado en sesión.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 · MariaDB 12.3.3 | SQLite 3.53.4 |
|---|---|---|---|---|
| El alias del `SELECT` vale en el `WHERE` | No verificado; el orden lógico dice que no | **No**: `column "iva" does not exist` | **No**: `Unknown column 'iva' in 'where clause'` | **Sí**, y devuelve filas |
| … vale en el `GROUP BY` | En SQL-92 no: solo nombres de columna de entrada | **Sí**, extensión declarada en su manual | Sí | Sí |
| … vale en el `HAVING` | No verificado | **No**: `column "n" does not exist` | **Sí** | **Sí** |
| … vale en el `ORDER BY` | En SQL-92 sí, y **solo** ahí | Sí | Sí | Sí |
| `LIMIT n, m` equivale a `LIMIT m OFFSET n` | `LIMIT`/`OFFSET` no es del estándar; SQL:2008 introdujo `OFFSET … FETCH FIRST …` | No existe | Sí: `LIMIT 2, 3` da `PED-00003` a `PED-00005` | Sí, idéntico a MySQL |
| Un `SELECT` sin `ORDER BY` tiene orden definido | No verificado; el modelo relacional dice que no | No | No | No |
| `DISTINCT` admite ordenar por columna no proyectada | No verificado | **No**, error explícito | No | No |

- Las tres filas que sí dicen algo del estándar son **cita de segunda mano**: salen de las notas de
  compatibilidad del manual de PostgreSQL, no de haber leído la norma. Allí se lee que `LIMIT` y
  `OFFSET` son sintaxis propia suya y de MySQL, y que la forma normalizada llegó con SQL:2008.
- **Ojo al orden de los dos números.** En `LIMIT 2, 3` el primero es el desplazamiento; en `LIMIT 3
  OFFSET 2`, al revés. Mismos tres pedidos y dos lecturas opuestas si vas rápido: **escribe siempre
  la forma con `OFFSET`**.

**Convención:** *"nunca uses `SELECT *`"*. Es costumbre de gremio, no regla de ningún motor ni del
estándar, y mezcla dos orígenes distintos: el ancho de fila de los años del cable lento y el
contrato frágil de los ORM que mapeaban por posición. Es buena costumbre **en código que se
despliega** y perfectamente razonable en una sesión interactiva, donde lo que quieres justamente es
ver qué hay. Recitarla como dogma sin saber cuál de las tres razones aplica es lo que detecta la
entrevista.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El `SELECT` se ejecuta primero, por eso va primero" | Se **escribe** primero y se **evalúa** el quinto, después del `HAVING`. De ahí que el `WHERE` no vea sus alias |
| "`WHERE` y `HAVING` hacen lo mismo, uno es más rápido" | Filtran cosas distintas: con `estado <> 'ANULADO'` en el `WHERE`, el informe pasa de seis clientes a tres |
| "Con `ORDER BY` ya es determinista" | Solo si la ordenación es **total**. Sin `ORDER BY` cada motor devuelve otras tres filas, y con `ORDER BY estado LIMIT 5` salen cinco pedidos distintos según sea `top-N heapsort` o `external merge` |
| "`OFFSET` salta directo a la fila n" | Produce esas n filas y las descarta: 631,392 ms con `OFFSET 900000` contra 0,432 ms con `OFFSET 0`, y el mismo plan |
| "`SELECT *` solo trae columnas de más" | Además rompe el contrato cuando se añade una columna y **renuncia al *index-only scan***: el nodo pasa de `Index Only Scan` a `Index Scan` |
| "`DISTINCT` quita duplicados por la columna que me interesa" | Opera sobre la fila proyectada entera: `DISTINCT estado` da 5 filas y `DISTINCT estado, cliente_id` da 229 700 |
| "El alias en el `HAVING` es SQL válido, lo uso siempre" | Es de motor: MySQL, MariaDB y SQLite lo aceptan y PostgreSQL responde `column "n" does not exist` |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «SELECT»: la sintaxis completa y las notas de compatibilidad,
  donde `LIMIT`/`OFFSET` se declara extensión frente a `FETCH FIRST`.
  <https://www.postgresql.org/docs/18/sql-select.html>
- **Documentación** — PostgreSQL 18, «LIMIT and OFFSET»: por qué las filas descartadas se calculan
  igual y por qué sin `ORDER BY` el resultado no es estable.
  <https://www.postgresql.org/docs/18/queries-limit.html>
- **Documentación** — MySQL 9.7, «Problems with Column Aliases»: dónde admite MySQL el alias y dónde
  no, contado por el propio manual.
  <https://dev.mysql.com/doc/refman/9.7/en/problems-with-alias.html>
- **Documentación** — SQLite, «SELECT»: el orden de procesamiento y la tolerancia de SQLite con los
  alias fuera de la lista de salida. <https://www.sqlite.org/lang_select.html>
- **Estándar** — ISO/IEC 9075-2 (*Foundation*), `<query specification>` y `<result offset clause>`.
  De pago, sin URL pública y **no verificadas en esta edición**.
- **Referencia** — Markus Winand, *Use The Index, Luke!*, «Paging Through Results»: por qué el
  `OFFSET` se degrada y cómo se pagina por clave.
  <https://use-the-index-luke.com/sql/partial-results/fetch-next-page>

---

## 🧠 Preguntas

1. Escribe el orden lógico de evaluación completo, de `FROM` a `LIMIT`, y di en qué paso nacen los
   alias del `SELECT`. 🟢
2. ¿Por qué falla `WHERE iva > 100` cuando `iva` es un alias declarado en el `SELECT`? 🟢
3. ¿Cuál de las dos, `WHERE` o `HAVING`, filtra grupos, y por qué no puede ser la otra? 🟢
4. ¿Qué garantiza `LIMIT 10` sobre una consulta sin `ORDER BY`? 🟢
5. ¿Sobre qué opera exactamente `DISTINCT`: sobre la primera columna, sobre la fila proyectada o
   sobre la fila de la tabla? 🟢
6. Distingue "orden de escritura" de "orden de evaluación", y di si el motor está obligado a
   ejecutar en el orden lógico. 🟡
7. El `ORDER BY` acepta el alias del `SELECT` y el `WHERE` no. Explica la asimetría. 🟡
8. ¿El alias en el `HAVING` lo permite el estándar o depende del motor? Di qué hace cada uno de los
   cuatro motores del corpus. 🟡
9. `LIMIT 2, 3` y `LIMIT 3 OFFSET 2` devuelven lo mismo. ¿Cuál es la forma normalizada, qué motores
   entienden cada una y cuál escribirías tú? 🟡
10. Un compañero mueve `estado <> 'ANULADO'` del `WHERE` al `HAVING` "para que quede más limpio y
    sea equivalente". ¿Qué le muestras, con los números de §4? 🟠
11. `ORDER BY estado LIMIT 5` devolvió cinco pedidos distintos en dos ejecuciones del mismo motor
    sobre los mismos datos. Explica la causa y da la corrección de una línea. 🟠
12. Justifica por qué `OFFSET 900000` es O(n) y no O(1), apoyándote en el `rows=` del nodo hijo del
    plan. 🟠
13. Da las tres razones técnicas por las que se desaconseja `SELECT *` en código desplegado, y di en
    qué caso la costumbre no aplica. 🟠
14. En la sesión de §7, el `Index Only Scan` lee las mismas 13 páginas que el `Index Scan`. Explica
    por qué hoy no ahorra nada y qué tendría que pasar para que ahorrara. 🟠
15. `SELECT DISTINCT estado FROM pedidos ORDER BY creado_en` da error. Explícalo con el orden lógico
    y escribe dos formas correctas de obtener lo que pretendía. 🟠
16. Escribe la consulta que da, por cada estado, los tres pedidos más antiguos, con una ordenación
    total que no dependa del plan. Di qué columna usas de desempate y por qué. 🔴
17. Una API pagina con `LIMIT 20 OFFSET :n` sobre `pedidos ORDER BY estado`. Enumera sus tres fallos
    —uno de corrección y dos de coste— y escribe la consulta que los resuelve. 🔴
18. Diseña la comprobación que demuestre, con `EXPLAIN (ANALYZE, BUFFERS)`, que `SELECT *` renuncia
    al *index-only scan*. Di qué nodo esperas en cada caso y qué contador mirarías. 🔴

---

**Anterior:** [`01`](01-familias-del-lenguaje-y-tipos.md) · **Siguiente:** [`03`](03-joins.md) ·
**Relacionado:** [`04`](04-agregacion-y-subconsultas.md) — el `GROUP BY` y el `HAVING` en detalle ·
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) — por qué un
nulo no sobrevive a un `WHERE` y sí a un `DISTINCT`.
