# 04 — Normalización y desnormalización

> Qué es una dependencia funcional, qué se rompe si no la respetas, y cómo se sube la escalera 1FN →
> 2FN → 3FN con BCNF de cierre. Y la otra mitad, la que casi nadie defiende bien: **cuándo se
> desnormaliza a propósito, qué se paga y cómo se documenta**. **Asume leído:**
> [`02`](02-el-modelo-relacional-y-sus-claves.md) — de ahí vienen clave candidata, clave primaria,
> clave compuesta y atributo primo. **Vigencia:** 20 de septiembre de 2026.

---

## 1. 🎯 El problema

Finanzas pide el importe facturado de los pedidos entregados. Hay dos formas de contestar, y dan el
mismo número.

```text
tienda=# SELECT sum(total) FROM pedidos WHERE estado = 'ENTREGADO';
      sum
---------------
 1553913951.25
(1 fila)

Duración: 69,404 ms

tienda=# SELECT sum(l.cantidad * l.precio_unit) FROM pedidos p
tienda-#   JOIN pedido_lineas l ON l.pedido_id = p.id WHERE p.estado = 'ENTREGADO';
      sum
---------------
 1553913951.25
(1 fila)

Duración: 606,118 ms
```

Ocho veces y media. La primera lee `pedidos.total`, una columna que **no debería existir** según el
manual: es redundante y se recalcula desde `pedido_lineas`. La segunda es la "correcta" y tarda
medio segundo. El dolor contrario está en §3: aplanar cliente y pedido convierte un cambio de email
en **175 filas por acertar**.

---

## 2. 🧱 La dependencia funcional, que es la herramienta y no el adorno

`X → Y` significa: *si dos filas coinciden en `X`, tienen que coincidir en `Y`*. No es propiedad de
los datos de hoy, es **una regla del negocio** que deben cumplir siempre, y de ahí sale toda la
teoría de formas normales. Se falsa con una consulta, no con una opinión:

```text
tienda=# SELECT count(*) FROM (SELECT producto_id FROM pedido_lineas
tienda(#                       GROUP BY producto_id HAVING count(DISTINCT precio_unit) > 1) q;
 count
-------
     1
(1 fila)

Duración: 1177,046 ms (00:01,177)
```

- `1`: hay un producto —`PRD-00017`, lo verás en §6— que aparece con precios distintos en líneas
  distintas. **`producto_id → precio_unit` NO se cumple**, y eso lo cambia todo. La misma consulta
  cambiando `precio_unit` por `pr.categoria` contra `productos` devuelve `0` en 1228,693 ms: **la
  categoría sí depende del producto**, y copiarla a `pedido_lineas` sería redundancia pura.
- Ese `0` **no demuestra** la dependencia, solo dice que hoy nadie la rompe.
- **Quién lo manda:** teoría relacional (Codd, 1970), no el estándar SQL. **Cuánto:** ~1,2 s de `Seq
  Scan` sobre los 3,5 millones de líneas, y se corre al diseñar, no en producción.

> **🧠 Modelo mental.** Una dependencia funcional es una promesa del negocio escrita como flecha, y
> las formas normales solo dicen **dónde vive cada promesa** para que una clave la haga cumplir.

---

## 3. 🩺 Las tres anomalías, en una sesión

Aplano cliente, pedido, línea y producto en una tabla temporal —muere al cerrar la sesión— y cambio
el email en un solo pedido, que es el error exacto de una aplicación mal escrita:

```text
tienda=# CREATE TEMP TABLE pedidos_plano AS SELECT p.codigo AS pedido, c.codigo AS cliente, c.email,
tienda-#   c.pais, l.linea, pr.codigo AS producto, pr.categoria, l.cantidad, l.precio_unit
tienda-#   FROM pedidos p JOIN clientes c ON c.id = p.cliente_id JOIN pedido_lineas l ON l.pedido_id = p.id
tienda-#   JOIN productos pr ON pr.id = l.producto_id WHERE c.codigo = 'CLI-00311';
SELECT 175

tienda=# UPDATE pedidos_plano SET email = 'nuevo.311@ejemplo.test' WHERE pedido = 'PED-01719';
UPDATE 6

tienda=# SELECT email, count(*) FROM pedidos_plano GROUP BY email ORDER BY 2 DESC;
          email          | count
-------------------------+-------
 cliente311@ejemplo.test |   169
 nuevo.311@ejemplo.test  |     6
(2 filas)
```

Los 52 pedidos de `CLI-00311` ocupan 175 filas con el mismo email; ahora hay dos y **el motor no
sabe cuál es el bueno**, porque no hay clave que lo prohíba. Las anomalías clásicas son esa grieta
desde tres ángulos:

| Anomalía | Qué pasa en `pedidos_plano` | Qué lo impide en el esquema normalizado |
|---|---|---|
| **Actualización** | 175 filas guardan el email; cambiar 6 deja al cliente con dos | `clientes.email` vive una sola vez: `UPDATE 1` en 1,684 ms |
| **Inserción** | Un producto nuevo sin ventas no se registra: no hay pedido al que colgarlo | `productos` tiene clave propia y existe sin pedidos |
| **Borrado** | Borrar el último pedido de un cliente borraría al cliente | Son tablas distintas: `CLI-00007` existe con cero pedidos |

> **⚠️ Advertencia.** La anomalía de actualización **no la arregla programar con cuidado**: la
> arregla que el dato tenga un único sitio donde vivir.

---

## 4. 🧱 La escalera: 1FN, 2FN, 3FN, y BCNF de cierre

Cada escalón quita una clase de dependencia mal colocada, y se sube sobre una tabla y sus claves
candidatas.

**1FN — un valor por celda, filas sin orden ni repetición.** Nada de `'PRD-00017,PRD-00872'` en una
columna de texto: eso no se indexa, no se valida con clave foránea y no contesta "¿cuántas unidades
de este producto?" sin partir cadenas; de ahí que exista `pedido_lineas`. El caso incómodo es
`eventos_pedido.carga`, que es `jsonb` y mete `{"estado": "PAGADO", "importe": 3186.23}` en una
celda: formalmente es **un valor atómico del dominio `jsonb`** y la 1FN se cumple. Lo que pierdes es
**la validación del motor**: nadie garantiza que `importe` sea un número.

**2FN — ningún atributo no primo depende de *parte* de una clave compuesta.** En la tienda hay una
sola clave compuesta, `pedido_lineas (pedido_id, linea)`. Si añadieras ahí `producto_nombre`,
dependería de `producto_id` y no de la clave entera: cinco mil nombres repetidos sobre 3 500 000
filas.

**3FN — ningún atributo no primo depende de otro atributo no primo.** La transitiva: si `pedidos`
llevara `cliente_pais`, la cadena sería `id → cliente_id → pais` y el país estaría copiado en el
millón de pedidos.

**BCNF — en toda dependencia no trivial, el lado izquierdo es una superclave.** Sin excepciones; la
3FN sí tiene una, porque tolera que el lado derecho sea un atributo primo, y solo se activa con
**claves candidatas solapadas**. Añade a `pedido_lineas` una columna `promocion` —un producto no se
repite en dos líneas del mismo pedido, y cada promoción aplica a un solo producto— y tendrás dos
claves candidatas, `{pedido_id, linea}` y `{pedido_id, producto_id}`, más `promocion → producto_id`.
`promocion` no es superclave, así que **viola BCNF**; pero `producto_id` es primo, así que **la 3FN
lo da por bueno**. Ahí vive la diferencia, y por eso llamar "3.5FN" a BCNF es folclore de apuntes.

**Cuándo sí** descomponer: cuando la dependencia suelta permite guardar una contradicción, dos filas
diciendo que la misma promoción aplica a productos distintos. **Cuándo no:** cuando la
descomposición **pierde la dependencia**. BCNF siempre admite una descomposición sin pérdida de
información, pero **no siempre preserva todas las dependencias**, y la 3FN garantiza las dos; si al
separar necesitas un disparador para recuperar una regla que era una clave, quédate en 3FN.
**Cuánto:** una tabla más y un `JOIN` más en cada lectura.

> **💡 Truco.** *"Cada atributo depende de la clave, de toda la clave y de nada más que la clave"* es
> buena mnemotecnia de 1FN a 3FN, pero **es divulgación, no definición**: ignora las claves
> candidatas múltiples y se queda corta donde empieza BCNF.

---

## 5. 🧭 `pedidos.total`: desnormalizar a propósito

`pedidos.total` viola 3FN de la forma más descarada posible —es un agregado de otra tabla— y está
ahí a propósito. La defensa es medible. **Qué compra:** para un pedido suelto, nada; `SELECT total
FROM pedidos WHERE codigo = 'PED-00042'` devolvió `3186.23` en **0,292 ms** y el `SUM` equivalente
lo mismo en **0,319 ms**, porque la clave primaria `(pedido_id, linea)` baja directo a las tres
líneas. **Si tu caso es la ficha del pedido, `total` no se paga solo.** Se paga en el agregado:
leyéndolo, el plan es un `Seq Scan` con `Buffers: shared hit=10770` y `Execution Time: 101.346 ms`.
Sumando desde las líneas:

```text
 Aggregate  (cost=108036.42..108036.43 rows=1 width=32) (actual time=887.090..887.092 rows=1.00 loops=1)
   Buffers: shared hit=11929 read=28008
   I/O Timings: shared read=1.075
   ->  Hash Join  (cost=26951.25..100305.79 rows=1030750 width=10) (actual time=118.008..782.811 rows=1049372.00 loops=1)
         Hash Cond: (l.pedido_id = p.id)
         Buffers: shared hit=11929 read=28008
         I/O Timings: shared read=1.075
         ->  Seq Scan on pedido_lineas l  (cost=0.00..64167.00 rows=3500000 width=18) (actual time=0.133..196.416 rows=3500000.00 loops=1)
               Buffers: shared hit=1159 read=28008
               I/O Timings: shared read=1.075
         ->  Hash  (cost=23270.00..23270.00 rows=294500 width=8) (actual time=117.299..117.300 rows=300000.00 loops=1)
               Buckets: 524288  Batches: 1  Memory Usage: 15815kB
               Buffers: shared hit=10770
               ->  Seq Scan on pedidos p  (cost=0.00..23270.00 rows=294500 width=8) (actual time=0.007..68.833 rows=300000.00 loops=1)
                     Filter: (estado = 'ENTREGADO'::text)
                     Rows Removed by Filter: 700000
                     Buffers: shared hit=10770
 Planning:
   Buffers: shared hit=165
 Planning Time: 0.323 ms
 Execution Time: 887.315 ms
(21 filas)
```

- **10 770 páginas contra 39 937.** El `SUM` lee `pedido_lineas` entera —3 500 000 filas— para armar
  un `Hash Join` del que solo sobreviven 1 049 372, y el `Hash` se come 15 815 kB de `work_mem`. La
  moneda es la E/S: los milisegundos cambian con la caché, **las páginas leídas no**.

**Qué cuesta.** Que se desincroniza, y el motor no lo impide:

```text
tienda=# BEGIN;
BEGIN
tienda=*# UPDATE pedido_lineas SET cantidad = cantidad + 1 WHERE pedido_id = 42 AND linea = 3;
UPDATE 1
tienda=*# SELECT total, (SELECT sum(cantidad*precio_unit) FROM pedido_lineas WHERE pedido_id = 42) AS recalculado
tienda-*#   FROM pedidos WHERE id = 42;
  total  | recalculado
---------+-------------
 3186.23 |     4168.98
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
```

Una sentencia, sin error, sin aviso, y el pedido miente por 982,75. Tampoco puedes delegarlo en el
motor: una columna generada no mira otra tabla, y un `ALTER TABLE … GENERATED ALWAYS AS (SELECT
sum(…) FROM pedido_lineas …) STORED` responde `ERROR: cannot use subquery in column generation
expression`.

**Cómo se documenta.** Sin estas cuatro cosas es una bomba de relojería: **(1)** un comentario en el
DDL que diga que es deliberado —`-- desnormalizado a propósito`— y contra qué se recalcula; **(2)**
un **dueño único de la escritura**, porque si dos caminos de código tocan `total` ya se
desincronizó; **(3)** el conciliador de abajo, corriendo solo; y **(4)** el número que lo justifica
al lado —*"606 ms → 69 ms y 39 937 → 10 770 páginas"*—, sin el cual el próximo que lea el esquema
borrará la columna.

```text
tienda=# SELECT count(*) AS pedidos_desincronizados FROM pedidos p
tienda-#   JOIN (SELECT pedido_id, sum(cantidad*precio_unit) s FROM pedido_lineas GROUP BY 1) t
tienda-#     ON t.pedido_id = p.id
tienda-# WHERE p.total <> t.s;
 pedidos_desincronizados
-------------------------
                       0
(1 fila)

Duración: 1819,711 ms (00:01,820)
```

> **Veredicto:** desnormalizar es ingeniería válida cuando tienes la medida, el dueño de la
> escritura y el conciliador. Sin las tres no es desnormalizar: es un bug lento.

---

## 6. 🧱 `precio_unit`: dato histórico, que no es redundancia

Aquí se cae medio proceso de selección. `pedido_lineas.precio_unit` *parece* violar 3FN —"el precio
ya está en `productos`"— y no lo viola. En `PED-00042` las tres líneas coinciden con el catálogo
—102,83, 27,03 y 982,75— y por eso engaña. Mira el producto que sí cambió de precio:

```text
tienda=# SELECT count(*) AS lineas, count(DISTINCT precio_unit) AS precios,
tienda-#        min(precio_unit), max(precio_unit) FROM pedido_lineas WHERE producto_id = 17;
 lineas | precios | min  |  max
--------+---------+------+--------
  20205 |    2792 | 1.05 | 999.84
(1 fila)
```

- `PRD-00017` vale hoy 31,79 en catálogo y aparece con 2 792 precios distintos en su histórico, así
  que **`producto_id → precio_unit` no se cumple** —§2 lo devolvió con un `1`—. Sin esa dependencia
  no hay transitividad y **no hay violación de 3FN**. Lo que sí se cumple es `(pedido_id, linea) →
  precio_unit`: el precio depende de la línea, o sea del par pedido-momento.
- **La prueba definitiva es contable:** si borras `precio_unit` y lees el precio de `productos`, una
  subida de tarifa **reescribe todas las facturas del pasado**.

`pedidos.total` es **redundancia**: se recalcula exactamente, viola 3FN a propósito y exige dueño de
escritura y conciliador. `precio_unit` es **dato histórico**: no se recalcula, no viola nada y le
basta un `NOT NULL`.

> **🧠 Modelo mental.** Antes de llamar redundante a una columna, pregúntate si el valor de origen
> **puede cambiar sin que este hecho cambie**. Si puede, no es una copia: es otro hecho.

---

## 7. 📜 Estándar, motor y convención

| Afirmación | Estándar (ISO/IEC 9075) | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| Las formas normales se declaran en SQL | **No aparecen en 9075**; son teoría relacional (Codd 1970, Boyce-Codd 1974) | No hay sentencia | No hay sentencia | No hay sentencia |
| Se puede declarar `X → Y` como restricción | No hay `FUNCTIONAL DEPENDENCY`; se expresa con `PRIMARY KEY` o `UNIQUE` | Igual | Igual | Igual |
| `GROUP BY` admite columnas funcionalmente dependientes | Sí: noción de *known functionally dependent* en `<group by clause>` | **Solo por clave primaria** | **También por clave candidata `UNIQUE NOT NULL`** | Acepta cualquier columna suelta, sin análisis |
| Un agregado de otra tabla puede ser columna generada | No aplica | ❌ `cannot use subquery…` | ❌ prohibido | ❌ no soportado |
| Hay vista materializada para ese agregado | No normalizada en 9075 | ✅ `CREATE MATERIALIZED VIEW`, refresco manual | ❌ | ❌ |

La misma consulta en los tres motores; `codigo` es `NOT NULL UNIQUE` en los tres esquemas:

```text
tienda=# SELECT p.id, p.codigo, p.estado FROM pedidos p WHERE p.codigo = 'PED-00042' GROUP BY p.codigo;
ERROR:  column "p.id" must appear in the GROUP BY clause or be used in an aggregate function
LÍNEA 1: SELECT p.id, p.codigo, p.estado FROM pedidos p WHERE p.codig...
                ^

mysql> SELECT p.id, p.codigo, p.estado FROM pedidos p WHERE p.codigo='PED-00042' GROUP BY p.codigo;
+----+-----------+--------+
| id | codigo    | estado |
+----+-----------+--------+
| 42 | PED-00042 | PAGADO |
+----+-----------+--------+
```

- **Con `ONLY_FULL_GROUP_BY` activo** —lo está: `SELECT @@sql_mode` lo lista el primero— **MySQL
  acepta lo que PostgreSQL rechaza.** No es laxitud: MySQL analiza la dependencia sobre cualquier
  clave candidata y PostgreSQL solo sobre la primaria, como enuncia su documentación: *"A functional
  dependency exists if the grouped columns (or a subset thereof) are the primary key"*. SQLite
  devolvió `42 | PED-00042 | PAGADO` sin protestar: no analiza nada. Y `GROUP BY` es **el único
  sitio del estándar donde asoma la dependencia funcional**; las formas normales no están.
- 📝 Media internet dice que MySQL "permite columnas sueltas en `GROUP BY`". Eso era 5.6 y anterior;
  desde 5.7 el modo viene activo, y no es permisividad sino análisis de dependencias.

**Convención.** *"Hay que normalizar hasta 3FN siempre"* es costumbre, no norma: este corpus la
rompe en una columna medida, y la regla útil es **normaliza por defecto, desnormaliza con número,
dueño y conciliador**. *"BCNF es 3.5FN"* es nomenclatura de apuntes (§4), y *"desnormalizar es de
vagos"* está al revés: añade un invariante que el motor no vigila y que vigilas tú.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El estándar SQL exige 3FN" | ISO/IEC 9075 **no menciona las formas normales**. Son teoría relacional; el motor solo sabe de claves y restricciones |
| "`precio_unit` viola 3FN porque el precio está en `productos`" | `producto_id → precio_unit` **no se cumple**: `PRD-00017` tiene 2 792 precios distintos. Sin dependencia no hay violación |
| "BCNF siempre es mejor que 3FN" | BCNF garantiza descomposición sin pérdida, pero **no siempre preserva las dependencias**; 3FN garantiza las dos |
| "Guardar JSON rompe la 1FN" | `jsonb` es un valor atómico de su dominio: la 1FN se cumple. Lo que se pierde es la **validación y las claves foráneas** |
| "Con `ONLY_FULL_GROUP_BY` MySQL y PostgreSQL se comportan igual" | No. MySQL analiza la dependencia sobre cualquier clave candidata; PostgreSQL **solo sobre la primaria** |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «SELECT — GROUP BY Clause»:
  <https://www.postgresql.org/docs/18/sql-select.html>
- **Documentación** — PostgreSQL 18, «Generated Columns»:
  <https://www.postgresql.org/docs/18/ddl-generated-columns.html>
- **Documentación** — MySQL 9.7, «Handling of GROUP BY»:
  <https://dev.mysql.com/doc/refman/9.7/en/group-by-handling.html>
- **Documentación** — SQLite, «Quirks, Caveats and Gotchas»: <https://www.sqlite.org/quirks.html>
- **Estándar** — ISO/IEC 9075-2, `<group by clause>`, noción de *known functionally dependent*. De
  pago; **no verifiqué el número de subcláusula**, así que se cita por nombre.
- **Artículo** — E. F. Codd, «A Relational Model of Data for Large Shared Data Banks», *CACM* 13(6),
  1970. Sin URL: ACM responde `403` a cualquier verificación automática.

---

## 🧠 Preguntas

1. Escribe la definición de dependencia funcional `X → Y` en una frase, sin usar la palabra "clave".
   🟢
2. Nombra las tres anomalías clásicas y da un ejemplo de cada una sobre la tienda. 🟢
3. ¿Qué exige la 2FN, y en qué caso es imposible que una tabla la incumpla? 🟢
4. ¿Qué columna del esquema está desnormalizada a propósito, y contra qué expresión se recalcula? 🟢
5. `pedidos.total` y `pedido_lineas.precio_unit` parecen el mismo tipo de duplicación. ¿Por qué solo
   una lo es? 🟡
6. ¿Las formas normales las fija ISO/IEC 9075 o son teoría relacional? ¿Y cuál es el único lugar del
   estándar donde asoma la noción de dependencia funcional? 🟡
7. Guardar `jsonb` en `eventos_pedido.carga`, ¿viola la 1FN? Justifica, y di qué se pierde de
   verdad. 🟡
8. ¿Por qué comprobar con una consulta que una dependencia funcional se cumple hoy no demuestra que
   exista? 🟡
9. Explica por qué la 3FN preserva siempre las dependencias y BCNF no, y qué haces cuando chocan. 🟠
10. Para un solo pedido, leer `total` tardó 0,292 ms y el `SUM` equivalente 0,319 ms. ¿Por qué el
    `SUM` es casi gratis ahí, y en qué caso deja de serlo? 🟠
11. El agregado sobre 300 000 pedidos lee 10 770 páginas con `total` y 39 937 con el `JOIN`. ¿Por
    qué comparar páginas es mejor argumento que comparar milisegundos? 🟠
12. `SELECT p.id, p.codigo, p.estado FROM pedidos p GROUP BY p.codigo` funciona en MySQL 9.7 con
    `ONLY_FULL_GROUP_BY` activo y falla en PostgreSQL 18. Explica por qué, y di cuál de los dos se
    acerca más al estándar. 🟠
13. Alguien propone declarar `pedidos.total` como columna generada para que el motor la mantenga
    solo. ¿Por qué no se puede, y qué mensaje devuelve PostgreSQL 18? 🟠
14. Escribe el DDL normalizado en 3FN de una tabla que hoy tiene `(pedido, cliente, email, pais,
    linea, producto, categoria, cantidad, precio_unit)` en una sola fila, con claves primarias y
    foráneas de cada tabla resultante. 🔴
15. Da la secuencia SQL exacta que desincroniza `pedidos.total` para `PED-00042` sin que el motor
    emita ningún error, y la consulta que lo demuestra. 🔴
16. Escribe la consulta de conciliación que detecta todos los pedidos con el total desincronizado, y
    explica qué pasaría si la escribieras con `LEFT JOIN` en lugar de `JOIN`. 🔴
17. Diseña la columna `promocion` de §4 respetando BCNF: da las tablas resultantes, sus claves
    candidatas y la dependencia que cada una hace cumplir. Después di qué se pierde frente a dejarla
    en 3FN. 🔴

---

**Anterior:** [`03`](03-algebra-relacional.md) · **Siguiente:**
[`05`](05-del-modelo-er-al-esquema.md) · **Relacionado:**
[`02`](02-el-modelo-relacional-y-sus-claves.md) — de dónde salen las claves candidatas que deciden
2FN, 3FN y BCNF · [`06`](06-nulos-y-logica-de-tres-valores.md) — por qué el conciliador con `<>` no
ve los nulos.
