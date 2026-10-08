# 06 — Nulos y lógica de tres valores

> Por qué `NULL = NULL` no es falso sino desconocido, cómo se propaga ese tercer valor por `AND`,
> `OR` y `NOT`, y qué se rompe en `WHERE`, `IN`, `NOT IN`, los agregados, `GROUP BY`, `ORDER BY`,
> `UNIQUE` y `CHECK`. Es el capítulo que más se cita desde fuera del bloque. **Asume leído:**
> [`02`](02-el-modelo-relacional-y-sus-claves.md) — de ahí vienen `UNIQUE` y clave candidata.
> **Vigencia:** 27 de septiembre de 2026.

---

## 1. 🎯 El problema

Conciliación de pagos. La tarea es de una línea: *"dame los pagos con tarjeta cuya referencia no
aparezca entre las referencias registradas antes de 2024"*. Hay 273 245 pagos con tarjeta y 298 202
anteriores a esa fecha, así que el informe tiene que devolver algo.

```text
tienda=# SELECT count(*) AS informe FROM pagos
tienda-# WHERE metodo = 'TARJETA'
tienda-#   AND referencia NOT IN (SELECT referencia FROM pagos WHERE pagado_en < '2024-01-01');
 informe 
---------
       0
(1 fila)

Duración: 208,208 ms
```

Cero filas, sin error y sin aviso, tras 208 ms recorriendo la tabla entera; el equipo ya había
concluido que no había discrepancias. El mismo informe con `NOT EXISTS` devuelve 173 619. La causa
no está en los pagos con tarjeta: la subconsulta arrastra 98 897 referencias nulas, y **una sola
basta para que `NOT IN` no pueda decir "no" de ninguna fila**.

> **📝 Contexto.** Las sesiones se corren con `\timing on`, puesto al abrir `psql`, y por eso cada
> salida acaba en `Duración:`. Se volvieron a correr el 27 de septiembre de 2026 con `psql` en
> español; los tiempos citados en la prosa que salen de un bloque pegado son los de esa corrida.

---

## 2. 🧱 `NULL` no es un valor, es la ausencia de uno

`NULL` es el marcador que dice *"aquí no hay dato"*. No es cero, no es cadena vacía y no es algo
comparable: comparar contra lo desconocido produce **desconocido**, el tercer valor lógico de SQL.

```text
tienda=# SELECT NULL = NULL AS igual, NULL <> NULL AS distinto, NULL IS NULL AS es_nulo;
 igual | distinto | es_nulo 
-------+----------+---------
       |          | t
(1 fila)

Duración: 0,591 ms
```

- Las dos primeras columnas salen **vacías**: no son `f`, son `NULL`. `psql` pinta el desconocido en
  blanco, y esa es la primera confusión del tema.
- `IS NULL` sí devuelve un booleano. **Es un predicado distinto de `=`**, no un atajo.

Por eso el filtro por igualdad no acierta ni en las 273 126 filas que sí tienen la referencia nula:
`EXPLAIN (ANALYZE)` de `WHERE referencia = NULL` resuelve el nodo en `Result → One-Time Filter:
false` y **ni abre la tabla**. Son 0,831 ms contra 10,170 ms de la versión con `IS NULL`: la mal
escrita es la rápida, y ahí está el peligro.

> **⚠️ Advertencia.** Cero filas en menos de un milisegundo sobre 820 000 registros es un síntoma,
> no un resultado.

**Veredicto:** `=` compara valores; para preguntar por la ausencia de valor se usa `IS NULL`, y no
hay sustituto.

---

## 3. ⚖️ La tabla de verdad de tres valores

SQL no opera con booleanos de dos estados sino de tres. La tabla sale del motor, no de un manual:

```text
tienda=# SELECT a::text AS a, b::text AS b, (a AND b)::text AS "AND", (a OR b)::text AS "OR", (NOT a)::text AS "NOT a"
tienda-# FROM (VALUES (true),(false),(NULL)) x(a), (VALUES (true),(false),(NULL)) y(b) ORDER BY 1,2;
   a   |   b   |  AND  |  OR   | NOT a 
-------+-------+-------+-------+-------
 false | false | false | false | true
 false | true  | false | true  | true
 false |       | false |       | true
 true  | false | false | true  | false
 true  | true  | true  | true  | false
 true  |       |       | true  | false
       | false | false |       | 
       | true  |       | true  | 
       |       |       |       | 
(9 filas)

Duración: 1,900 ms
```

Las tres reglas que hay que poder recitar en voz alta:

- **`falso AND desconocido` es falso.** El falso corta: da igual qué hubiera en el otro lado.
- **`verdadero OR desconocido` es verdadero.** Simétrico: el verdadero corta.
- **`NOT desconocido` es desconocido.** De ahí sale toda la trampa de `NOT IN`.

> **🧠 Modelo mental.** Desconocido no es "medio verdadero": es *"el motor no tiene información para
> responder"*. Si esa falta no cambiaría el resultado, responde igual; si lo cambiaría, se rinde.

**Veredicto:** memoriza las dos filas de corte y la negación; el resto se deduce.

---

## 4. 🩺 `WHERE`, `IN` y la trampa de `NOT IN`

**`WHERE` solo deja pasar la fila cuando el predicado es verdadero.** Falso y desconocido se
descartan igual, y por eso el desconocido es invisible: un falso silencioso.

`IN` es azúcar sintáctico de una cadena de `OR`; `NOT IN`, de una cadena de `AND` con `<>`. Corrido
sobre el motor, `'X' IN ('A', NULL)` y `'X' NOT IN ('A', NULL)` salen en blanco y `'A' IN ('A',
NULL)` sale `true`:

- `'X' IN ('A', NULL)` es `('X'='A') OR ('X'=NULL)` → `falso OR desconocido` → **desconocido**.
- `'A' IN ('A', NULL)` es `verdadero OR desconocido` → **verdadero**: a `IN` le basta un acierto.
- `'X' NOT IN ('A', NULL)` es `('X'<>'A') AND ('X'<>NULL)` → `verdadero AND desconocido` →
  **desconocido**. `NOT IN` **nunca puede dar verdadero** con un nulo en la lista, porque
  necesitaría que *todas* las comparaciones lo fueran.

Ahí está el informe de §1: cada fila acaba en desconocido y `WHERE` las tira. La corrección buena es
el anti-join (antijunta):

```text
tienda=# SELECT count(*) AS informe FROM pagos p
tienda-# WHERE p.metodo = 'TARJETA'
tienda-#   AND NOT EXISTS (SELECT 1 FROM pagos q
tienda(#                   WHERE q.pagado_en < '2024-01-01' AND q.referencia = p.referencia);
 informe 
---------
  173619
(1 fila)

Duración: 170,492 ms
```

- Añadir `AND referencia IS NOT NULL` a la subconsulta da el mismo 173 619, y en el mismo tiempo: en
  ocho corridas alternas, mediana de 234 ms frente a 228 de `NOT EXISTS`. Los planes sí son
  distintos —`NOT IN` filtra contra una lista con `hashed SubPlan`; `NOT EXISTS` es un `Hash Right
  Anti Join`—, pero **la ventaja de `NOT EXISTS` no es la velocidad**: es que no hay que acordarse
  de repetir el `IS NOT NULL` en cada refactorización. Coinciden porque ningún pago con tarjeta
  tiene referencia nula: **si la columna exterior también admitiera nulos, `NOT EXISTS` y `NOT IN`
  seguirían sin ser equivalentes.**

**Veredicto:** `NOT IN` sobre subconsulta solo es seguro si la columna es `NOT NULL` y puedes
demostrarlo; si no, `NOT EXISTS`.

---

## 5. 🧱 Agregados, `GROUP BY`, `DISTINCT` y `ORDER BY`

En unos sitios el nulo se ignora y en otros se junta consigo mismo. **Los agregados de columna lo
ignoran; `count(*)` no.**

```text
tienda=# SELECT metodo, count(*) AS filas, count(referencia) AS con_referencia
tienda-# FROM pagos GROUP BY metodo ORDER BY metodo;
    metodo     | filas  | con_referencia 
---------------+--------+----------------
 EFECTIVO      | 273126 |              0
 TARJETA       | 273245 |         273245
 TRANSFERENCIA | 273629 |         273629
(3 filas)

Duración: 80,639 ms
```

- Sobre la tabla entera, `count(*)` da **820 000** —cuenta filas— y `count(referencia)` da **546
  874** —cuenta valores no nulos—. La diferencia son los 273 126 pagos en efectivo. No es un
  agregado más rápido que otro: **es otra pregunta**.
- Lo mismo estropea las medias. Sobre los pedidos `ANULADO` y `PAGADO` juntos, tras un `LEFT JOIN`,
  `avg(g.importe)` da 5171,66 y `sum(g.importe) / count(*)` da 4170,70: un 24 % de diferencia,
  porque los 60 000 anulados **no entran en el denominador de `avg`**.

**`GROUP BY` y `DISTINCT`, en cambio, tratan los nulos como iguales entre sí**, lo que contradice a
`=`:

```text
tienda=# SELECT g.metodo, count(*) AS pedidos
tienda-# FROM pedidos p LEFT JOIN pagos g ON g.pedido_id = p.id
tienda-# GROUP BY g.metodo ORDER BY g.metodo;
    metodo     | pedidos 
---------------+---------
 EFECTIVO      |  273126
 TARJETA       |  273245
 TRANSFERENCIA |  273629
               |  180000
(4 filas)

Duración: 438,101 ms
```

- El cuarto grupo, sin nombre, son los 180 000 pedidos `PENDIENTE` y `ANULADO` sin pago: **todos los
  nulos cayeron en un grupo**. Igual `SELECT DISTINCT referencia FROM pagos`, que devuelve 546 875:
  los valores más **uno** por todos los nulos juntos.
- Fíjate en el orden: ese grupo cierra la lista. **PostgreSQL pone los nulos al final en `ASC`;
  MySQL 9.7.2, MariaDB 12.3.3 y SQLite 3.53.4 los ponen al principio**, comprobado con `ORDER BY
  referencia LIMIT 3` en los cuatro. `DESC` los invierte en todos.
- Para no depender del motor está `NULLS FIRST` / `NULLS LAST`, que **PostgreSQL y SQLite admiten y
  MySQL y MariaDB rechazan** con `ERROR 1064`. El apaño portable: `ORDER BY referencia IS NULL,
  referencia`.
- Y el `LEFT JOIN` que se vuelve `INNER JOIN` solo: filtrar luego con `WHERE g.metodo <> 'EFECTIVO'`
  da 546 874 filas y con `IS DISTINCT FROM`, 726 874 — los mismos 180 000 pedidos sin pago.

**Veredicto:** en agregados el nulo desaparece, en agrupación y deduplicación se junta consigo
mismo, y en ordenación depende del motor. Tres reglas distintas, no una.

---

## 6. 🧱 `UNIQUE` y `CHECK`, las dos restricciones que el nulo atraviesa

`pagos.referencia` es `UNIQUE` y anulable, y hay **273 126 filas con la referencia nula conviviendo
sin chocar**. No es un defecto: `UNIQUE` prohíbe que dos filas sean **iguales**, y dos nulos no son
iguales, son desconocidos.

```text
tienda=# BEGIN;
BEGIN
Duración: 0,381 ms
tienda=*# INSERT INTO pagos (pedido_id, metodo, importe, pagado_en, referencia)
tienda-*# VALUES (42, 'EFECTIVO', 10.00, now(), NULL), (42, 'EFECTIVO', 20.00, now(), NULL);
INSERT 0 2
Duración: 0,935 ms
tienda=*# INSERT INTO pagos (pedido_id, metodo, importe, pagado_en, referencia)
tienda-*# VALUES (42, 'TARJETA', 30.00, now(), 'REF-000000001');
ERROR:  duplicate key value violates unique constraint "pagos_referencia_key"
DETALLE:  Key (referencia)=(REF-000000001) already exists.
Duración: 0,516 ms
tienda=!# ROLLBACK;
ROLLBACK
Duración: 0,244 ms
```

- Dos nulos más en la misma columna `UNIQUE`: aceptados. Un valor repetido: rechazado. La
  restricción funciona; **no aplica a lo que no tiene valor**. MySQL, MariaDB y SQLite responden
  igual, con `ERROR 1062 (23000) Duplicate entry` y `UNIQUE constraint failed: pagos.referencia`.
- `CHECK` tiene la misma grieta, y es la menos conocida: **solo se viola cuando el predicado es
  falso; si es desconocido, la fila pasa.** `pedidos.actualizado_en` es nulo en el millón de filas,
  y un `ALTER TABLE pedidos ADD CONSTRAINT … CHECK (actualizado_en > creado_en)` se acepta en 62,616
  ms **sin que ninguna fila cumpla el predicado**. Si el nulo también debe ser inválido: `CHECK
  (actualizado_en IS NOT NULL AND actualizado_en > creado_en)`.

> **📝 Contexto.** Por internet leerás que *"UNIQUE solo permite un NULL"*. Es cierto en SQL Server y
> es la excepción: los cuatro motores del corpus admiten tantos como filas. Desde PostgreSQL 15 hay
> `UNIQUE NULLS NOT DISTINCT` para pedir lo contrario, y crearlo hoy sobre `pagos.referencia` falla.

Y de ahí sale el criterio de diseño. En `pagos.referencia` el nulo es correcto —un pago en efectivo
no tiene referencia del proveedor y nunca la va a tener— y en `pedidos.actualizado_en` es además
informativo: *"nadie lo ha tocado desde que se creó"*. En `pedidos.total` sería un error, y por eso
es `NOT NULL DEFAULT 0`. La pregunta que decide es *"¿existe una fila donde este dato legítimamente
no exista?"*, y **el precio de equivocarse no es simétrico**: el `NOT NULL` que sobra se quita con
un `ALTER TABLE`; el que falta deja tres años de filas que ninguna consulta filtra bien.

**Veredicto:** `UNIQUE` y `CHECK` protegen valores, no ausencias. Si la ausencia también debe ser
ilegal, se declara `NOT NULL`, que es lo que se pone por defecto.

---

## 7. 📜 Estándar, motor y convención

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 / MariaDB 12.3.3 | SQLite 3.53.4 |
|---|---|---|---|---|
| `NULL = NULL` da desconocido, no falso | Sí, lógica de tres valores de ISO/IEC 9075 | ✅ | ✅ | ✅ |
| `WHERE` descarta desconocido igual que falso | Sí | ✅ | ✅ | ✅ |
| `NOT IN` con un nulo en la lista no da verdadero | Sí, se deriva de `AND` y `<>` | ✅ 0 filas | ✅ 0 filas | ✅ 0 filas |
| Varios `NULL` conviven bajo `UNIQUE` | Sí | ✅ | ✅ | ✅ |
| Un `CHECK` desconocido no cuenta como violado | Sí | ✅ | ✅ | ✅ |
| `GROUP BY` y `DISTINCT` juntan los nulos | Sí | ✅ | ✅ | ✅ |
| `ORDER BY … ASC` pone los nulos al final | **No lo fija**: es cosa de la implementación | Al final | **Al principio** | **Al principio** |
| `NULLS FIRST` / `NULLS LAST` | Sí, en `<sort specification>` | ✅ | ❌ `ERROR 1064` | ✅ |
| Comparación segura con nulos | `IS NOT DISTINCT FROM` | ✅ | ❌ — usan `<=>`, que **no es estándar** | ✅ |

Las seis primeras filas salen de correr lo mismo en los cuatro motores y obtener lo mismo. **No he
verificado la cláusula concreta de ISO/IEC 9075 de ninguna**: el estándar es de pago y no lo tengo
delante; lo comprobado es que los cuatro coinciden. Donde difieren, está medido:

```text
mysql> SELECT NULL = NULL AS igual, NULL <=> NULL AS seguro, 'A' <=> NULL AS a_null;
+-------+--------+--------+
| igual | seguro | a_null |
+-------+--------+--------+
|  NULL |      1 |      0 |
+-------+--------+--------+
```

`SELECT NULL IS NOT DISTINCT FROM NULL` en ese mismo motor responde `ERROR 1064 (42000) … near
'DISTINCT FROM NULL'`; en SQLite da `1` y en PostgreSQL `true`. **MySQL y MariaDB tienen `<=>` y no
`IS NOT DISTINCT FROM`; PostgreSQL y SQLite tienen el estándar y no `<=>`**, que no es portable.

**Convención — dos frases que se recitan y son falsas:**

| Lo que se recita | De dónde viene | Qué es en realidad |
|---|---|---|
| *"`NULL` es lo mismo que la cadena vacía"* | De Oracle, donde `''` sí se guarda como `NULL`, y de los formularios que mandan `""` | En los cuatro motores `''` es un valor: longitud 0, igual a sí mismo, y choca contra un `UNIQUE`. Por eso la exportación del corpus usa `NULL '\N'` |
| *"`NULL` es cero"* | De los lenguajes donde la variable sin inicializar vale 0 | `NULL + 1` es `NULL`, `sum()` lo ignora y `count(*)` lo cuenta. Para que sea cero se escribe `coalesce(importe, 0)` |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`NULL = NULL` es falso" | Es **desconocido**: si fuera falso, `NOT (NULL = NULL)` sería verdadero, y no lo es |
| "`NOT IN` devuelve menos filas cuando hay nulos" | Devuelve **cero**. No es una pérdida parcial: es la aniquilación del resultado |
| "`UNIQUE` impide dos nulos" | Impide dos **valores iguales**. En los cuatro motores del corpus caben tantos nulos como filas |
| "`count(*)` y `count(columna)` son lo mismo, uno más rápido" | Son **preguntas distintas**: 820 000 contra 546 874 sobre `pagos.referencia` |
| "`GROUP BY` descarta los nulos" | Los junta en **un grupo**, igual que `DISTINCT`. Los que los descartan son los agregados de columna |
| "Los nulos van al final al ordenar" | Al final en PostgreSQL con `ASC`; al principio en MySQL, MariaDB y SQLite. El estándar no lo fija |
| "`<=>` es el operador estándar de comparación segura" | El estándar es `IS NOT DISTINCT FROM`. `<=>` es de MySQL y MariaDB, y no existe en PostgreSQL ni en SQLite |
| "Un `CHECK` protege la columna" | Solo rechaza lo **falso**. Con la columna nula el predicado da desconocido y la fila entra |

---

## 📚 Para profundizar

- **Doc** — PostgreSQL 18, «Comparison Functions and Operators», `IS NULL` e `IS DISTINCT FROM`:
  <https://www.postgresql.org/docs/18/functions-comparison.html>
- **Doc** — PostgreSQL 18, «Subquery Expressions», `IN` y `NOT IN` con nulos:
  <https://www.postgresql.org/docs/18/functions-subquery.html>
- **Doc** — PostgreSQL 18, «Sorting Rows»: <https://www.postgresql.org/docs/18/queries-order.html>
- **Doc** — PostgreSQL 18, «Constraints», `UNIQUE` y `NULLS NOT DISTINCT`:
  <https://www.postgresql.org/docs/18/ddl-constraints.html>
- **Doc** — MySQL 9.7, «Working with NULL Values» y `<=>`:
  <https://dev.mysql.com/doc/refman/9.7/en/working-with-null.html>
- **Doc** — MariaDB Server, «NULL Values»:
  <https://mariadb.com/docs/server/reference/data-types/null-values>
- **Doc** — SQLite, «NULL Handling in SQLite Versus Other Database Engines»:
  <https://www.sqlite.org/nulls.html>
- **Estándar** — ISO/IEC 9075-2, lógica de tres valores y `<sort specification>`. De pago y sin URL
  pública; las filas de §7 marcadas como estándar **no** se verificaron contra la cláusula.

---

## 🧠 Preguntas

1. ¿Qué devuelve `NULL = NULL` y por qué no es `false`? 🟢
2. ¿Qué predicado se usa para preguntar si una columna no tiene valor, y por qué no sirve `=`? 🟢
3. Con `WHERE`, ¿qué pasa con una fila cuyo predicado da desconocido? 🟢
4. Da el resultado de `falso AND desconocido`, `verdadero OR desconocido` y `NOT desconocido`. 🟢
5. ¿Cuántos pagos hay en total y cuántos tienen referencia? Di qué agregado produce cada número. 🟢
6. ¿Qué significa el nulo de `pedidos.actualizado_en` en este esquema? 🟢
7. ¿En qué se diferencian `count(*)` y `count(referencia)` sobre la misma tabla? 🟡
8. ¿Por qué `IN` sí puede dar verdadero con un nulo en la lista y `NOT IN` no? 🟡
9. `GROUP BY` junta los nulos en un grupo y `NULL = NULL` es desconocido: ¿cómo se concilian? 🟡
10. Diferencia entre `NULL` y la cadena vacía, y en qué motor conocido no la hay. 🟡
11. ¿`avg(importe)` y `sum(importe) / count(*)` dan lo mismo? Explica cuándo no. 🟡
12. ¿Por qué `pagos.referencia` puede ser `UNIQUE` y tener 273 126 filas nulas a la vez? 🟡
13. ¿El orden de los nulos en `ORDER BY … ASC` lo fija el estándar o el motor? Di qué hace cada uno.
    🟠
14. `IS NOT DISTINCT FROM` y `<=>`: ¿cuál es estándar, cuál de motor, y quién admite cada uno? 🟠
15. `= NULL` tarda 0,8 ms y `IS NULL` 10 ms: ¿por qué la incorrecta es la rápida, y qué dice su
    plan? 🟠
16. Un `CHECK (actualizado_en > creado_en)` se acepta sobre un millón de filas con esa columna nula:
    ¿por qué, y cómo lo escribirías para rechazarlas? 🟠
17. Tras un `LEFT JOIN`, `WHERE g.metodo <> 'EFECTIVO'` tira las filas sin pago: por qué, y dos
    arreglos. 🟠
18. ¿Qué plan eligió el motor para `NOT EXISTS` y cuál para el `NOT IN` ya corregido, y por qué la
    ventaja de `NOT EXISTS` no es la velocidad? 🟠
19. Decide si `pedidos.total` debe admitir nulos, y el coste de equivocarse en cada dirección. 🟠
20. Reescribe el `NOT IN` de §1 para que dé las 173 619 filas, en dos versiones; di cuál dejas. 🔴
21. Da la tabla de verdad completa de `AND`, `OR` y `NOT` con tres valores. 🔴
22. Escribe un `ORDER BY referencia` que ponga los nulos al final en los cuatro motores, sabiendo
    que dos no admiten `NULLS LAST`. 🔴
23. Diseña la comprobación previa a un despliegue que encuentre los `NOT IN` peligrosos del
    repositorio: qué buscas, qué descartas y qué consulta del catálogo dice si la columna es
    anulable. 🔴

---

**Anterior:** [`05`](05-del-modelo-er-al-esquema.md) · **Siguiente:** —, es el último capítulo
teórico del bloque · **Relacionado:** [`02`](02-el-modelo-relacional-y-sus-claves.md), de donde
salen `UNIQUE` y las clases de clave, y [`03`](03-algebra-relacional.md), el álgebra relacional, que
no tiene nulos y por eso no predice nada de esto. El mapa está en el [README del bloque](README.md).
