# 06 — Paginación y búsqueda de texto

> Las dos decisiones que toda pantalla de listado obliga a tomar: cómo se pasa de página y cómo se
> busca. Medido en PostgreSQL sobre el millón de pedidos: la primera página con `OFFSET` tarda 0,072
> ms y la página 25 000 tarda 302 ms, porque lee medio millón de filas para devolver veinte; la
> misma página por clave tarda 0,081 ms; y un pedido nuevo que llega entre dos páginas hace que
> `OFFSET` enseñe uno repetido. La búsqueda se decide con las cifras de
> [`09/05`](../09-otros-modelos/05-busqueda-de-texto.md). **Asume leído:**
> [`03/03`](../03-el-motor-por-dentro/03-compuestos-parciales-y-de-cobertura.md), los índices
> compuestos. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Desplazamiento y clave](#2--desplazamiento-y-clave)
- [3. La página lejana, medida](#3--la-página-lejana-medida) · [4. La página que se
  mueve](#4--la-página-que-se-mueve)
- [5. «Página 3 de 50 000»](#5--página-3-de-50-000) · [6. Buscar: cuándo basta PostgreSQL y cuándo
  no](#6--buscar-cuándo-basta-postgresql-y-cuándo-no)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La pantalla de pedidos del panel de la tienda enseña veinte pedidos, los más recientes primero, con
un botón de «siguiente». Se programa en cinco minutos con `LIMIT 20 OFFSET 20 * página`, funciona en
las pruebas, y en producción tiene dos defectos que solo aparecen con datos y con tráfico: las
páginas lejanas son cada vez más lentas, y a veces el mismo pedido sale en dos páginas seguidas o
uno no sale nunca.

Y encima de la lista hay una caja de búsqueda, que es la segunda decisión: `LIKE`, búsqueda de texto
de PostgreSQL o un motor aparte. [`09/05`](../09-otros-modelos/05-busqueda-de-texto.md) midió las
tres; aquí se decide con esas cifras.

> **📝 Contexto.** La paginación se corrió en la copia aislada `bd-lab-prueba`, con un índice sobre
> `pedidos (creado_en DESC, id DESC)` que el entorno principal no tiene y con un pedido nuevo,
> `PED-1000001`, que solo existe ahí. La búsqueda **no tiene sesiones nuevas**: cita las de `09/05`.
> **Longitud:** unas 315 líneas; capítulo normal. El recuento del §5 se corrió después del pedido
> nuevo del §4, y por eso cuenta 1 000 001.

---

## 2. 🧱 Desplazamiento y clave

**Qué es:** hay dos formas de pedir la página siguiente. Por **desplazamiento** —`OFFSET`—: «sáltate
las primeras cuarenta filas y dame veinte». Por **clave** —a veces llamada *keyset* o paginación por
cursor—: «dame veinte filas que vayan después de esta», donde «esta» es la última de la página
anterior, identificada por las columnas del orden.

**Quién lo manda:** `OFFSET` y `LIMIT` —o `FETCH FIRST`— son sintaxis de cada motor y del estándar;
la comparación de filas `(a, b) < (x, y)` es del **estándar**, y lo que la hace rápida es un índice
del **motor** con esas columnas en ese orden. La elección es **convención** de diseño de la API.

- **El orden tiene que ser total**: `ORDER BY creado_en DESC` solo no basta, porque dos pedidos
  pueden tener la misma marca de tiempo. Se añade la clave primaria como desempate, y el orden queda
  `creado_en DESC, id DESC`.
- **El índice tiene que coincidir** con ese orden, columna por columna, para que la base lea las
  filas ya ordenadas y pare en cuanto tenga veinte.

---

## 3. 🩺 La página lejana, medida

La primera página, la página 25 000 con `OFFSET` y la misma página por clave, tomando como cursor la
última fila de la página anterior:

```text
tienda=# CREATE INDEX pedidos_creado ON pedidos (creado_en DESC, id DESC);
CREATE INDEX
tienda=# EXPLAIN (ANALYZE, COSTS OFF, SUMMARY ON) SELECT codigo, creado_en FROM pedidos ORDER BY creado_en DESC, id DESC LIMIT 20 OFFSET 0;
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Limit (actual time=0.025..0.057 rows=20.00 loops=1)
   Buffers: shared hit=20 read=3
   I/O Timings: shared read=0.017
   ->  Index Scan using pedidos_creado on pedidos (actual time=0.024..0.051 rows=20.00 loops=1)
         Index Searches: 1
         Buffers: shared hit=20 read=3
         I/O Timings: shared read=0.017
 Planning:
   Buffers: shared hit=121 read=1
   I/O Timings: shared read=0.023
 Planning Time: 0.292 ms
 Execution Time: 0.072 ms
(12 filas)

tienda=# EXPLAIN (ANALYZE, COSTS OFF, SUMMARY ON) SELECT codigo, creado_en FROM pedidos ORDER BY creado_en DESC, id DESC LIMIT 20 OFFSET 500000;
                                              QUERY PLAN                                              
------------------------------------------------------------------------------------------------------
 Limit (actual time=301.817..301.828 rows=20.00 loops=1)
   Buffers: shared hit=499986 read=1915
   I/O Timings: shared read=10.298
   ->  Index Scan using pedidos_creado on pedidos (actual time=0.004..287.926 rows=500020.00 loops=1)
         Index Searches: 1
         Buffers: shared hit=499986 read=1915
         I/O Timings: shared read=10.298
 Planning Time: 0.017 ms
 Execution Time: 301.844 ms
(9 filas)

tienda=# SELECT creado_en, id FROM pedidos ORDER BY creado_en DESC, id DESC LIMIT 1 OFFSET 499999 \gset ultimo_
tienda=# EXPLAIN (ANALYZE, COSTS OFF, SUMMARY ON) SELECT codigo, creado_en FROM pedidos WHERE (creado_en, id) < (:'ultimo_creado_en', :ultimo_id) ORDER BY creado_en DESC, id DESC LIMIT 20;
                                                    QUERY PLAN                                                     
-------------------------------------------------------------------------------------------------------------------
 Limit (actual time=0.039..0.061 rows=20.00 loops=1)
   Buffers: shared hit=22 read=1
   I/O Timings: shared read=0.028
   ->  Index Scan using pedidos_creado on pedidos (actual time=0.038..0.059 rows=20.00 loops=1)
         Index Cond: (ROW(creado_en, id) < ROW('2024-05-15 07:00:41.373185+00'::timestamp with time zone, 671143))
         Index Searches: 1
         Buffers: shared hit=22 read=1
         I/O Timings: shared read=0.028
 Planning Time: 0.064 ms
 Execution Time: 0.081 ms
(10 filas)

```

- **Página 1 con `OFFSET 0`: 0,072 ms**, 20 filas leídas del índice.
- **Página 25 000 con `OFFSET 500000`: 302 ms**, y `rows=500020.00` en el `Index Scan`: el índice
  entrega ordenadas las 500 020 filas y el `Limit` tira las primeras 500 000. La documentación lo
  dice sin rodeos: las filas que se salta un `OFFSET` hay que calcularlas igual dentro del servidor,
  y un `OFFSET` grande puede ser ineficiente. Cada página es más lenta que la anterior.
- **`\gset ultimo_`** guarda en variables de `psql` las columnas de la última fila de la página
  anterior: `:ultimo_creado_en` y `:ultimo_id`. Es lo que una API devolvería como cursor.
- **La misma página por clave: 0,081 ms**, del orden de la primera. La línea `Index Cond` compara
  las filas dentro del índice: salta directamente al cursor y lee veinte filas. La página 25 000
  cuesta lo mismo que la 1.

> **Veredicto:** con `OFFSET`, el coste de una página crece con su número; por clave, es constante.
> Para listas largas o desplazamiento infinito, clave.

---

## 4. 🩺 La página que se mueve

Mientras alguien pagina, llega un pedido nuevo, que por ser el más reciente se coloca el primero:

```text
tienda=# SELECT codigo FROM pedidos ORDER BY creado_en DESC, id DESC LIMIT 3;
   codigo   
------------
 PED-246716
 PED-660744
 PED-947907
(3 filas)

tienda=# SELECT creado_en, id FROM pedidos ORDER BY creado_en DESC, id DESC LIMIT 1 OFFSET 2 \gset cursor_
tienda=# INSERT INTO pedidos (codigo, cliente_id, estado, total, creado_en) VALUES ('PED-1000001', 311, 'PENDIENTE', 10.00, now());
INSERT 0 1
tienda=# SELECT codigo FROM pedidos ORDER BY creado_en DESC, id DESC LIMIT 3 OFFSET 3;
   codigo   
------------
 PED-947907
 PED-25881
 PED-183146
(3 filas)

tienda=# SELECT codigo FROM pedidos WHERE (creado_en, id) < (:'cursor_creado_en', :cursor_id) ORDER BY creado_en DESC, id DESC LIMIT 3;
   codigo   
------------
 PED-25881
 PED-183146
 PED-853938
(3 filas)
```

- **Páginas de tres** para que se vea. La página 1 acaba en `PED-947907`, y el cursor guarda su
  fecha y su `id`.
- **Con `OFFSET 3`, la página 2 empieza por `PED-947907` otra vez**: el pedido nuevo empujó todas
  las filas una posición, y la tercera pasó a ser la cuarta. Con un borrado pasa lo contrario: un
  pedido se salta y no sale en ninguna página.
- **Por clave, la página 2 empieza justo después de `PED-947907`**, llegue lo que llegue delante: la
  página no depende de cuántas filas hay antes, sino de dónde se quedó la anterior.

---

## 5. 🧭 «Página 3 de 50 000»

Lo que la paginación por clave no da es **saltar a la página 3 000** ni decir cuántas páginas hay.
Contar tiene su precio:

```text
tienda=# \timing on
El despliegue de duración está activado.
tienda=# SELECT count(*) FROM pedidos;
  count  
---------
 1000001
(1 fila)

Duración: 58,233 ms
tienda=# \timing off
El despliegue de duración está desactivado.
```

- **58 ms por contar el millón y un pedido**, en cada carga de la pantalla si se enseña «de 50 000».
  Con un filtro —los pedidos de un cliente, los pendientes—, el recuento es otra consulta con su
  propio plan.
- **Las salidas habituales**, que son **convención** de interfaz: no enseñar el total, enseñar «más
  de mil», o un recuento aproximado de las estadísticas del planificador, que
  [`03/04`](../03-el-motor-por-dentro/04-estadisticas-y-el-planificador.md) explica.
- **Cuándo `OFFSET` sigue valiendo**: listas cortas y acotadas, donde saltar a una página concreta
  importa más que la coherencia —un panel de administración con filtros que dejan pocas filas—.

---

## 6. 🧭 Buscar: cuándo basta PostgreSQL y cuándo no

La caja de búsqueda encima de la lista, con las cifras de
[`09/05`](../09-otros-modelos/05-busqueda-de-texto.md) sobre las descripciones de los 5 000
productos:

| Necesidad | `LIKE '%texto%'` | Texto completo de PostgreSQL | OpenSearch |
|---|---|---|---|
| Encontrar sin tilde | No: 0 de 328 | Sí: 328 | Sí: 328 |
| Encontrar el singular de un plural | Solo si contiene los caracteres | No: 0 de 95 | Sí: 95 |
| Tolerar erratas | No | No; con `pg_trgm`, aproximado | Sí: 95 |
| Ordenar por relevancia | No | `ts_rank` sobre lo filtrado | BM25 sobre todo lo parecido |
| Usar un índice | No: `Seq Scan` | Sí, GIN | Su índice invertido |
| Ver un cambio al instante | Sí | Sí | Tras el refresco, cada segundo |

- **Con miles o decenas de miles de filas**, PostgreSQL basta: `tsvector` con GIN, `unaccent` para
  las tildes, `pg_trgm` para las erratas, probado con las palabras reales del catálogo, porque el
  *stemmer* español falló con el singular.
- **Con millones, relevancia afinada o facetas**, un motor aparte, pagando una copia que se ve con
  retraso y se tiene que poder reconstruir.
- **Búsqueda y paginación se combinan mal con `OFFSET`**: el resultado de una búsqueda se ordena por
  relevancia, que cambia con cada documento nuevo. Los motores de búsqueda ofrecen su propio cursor
  para paginar resultados profundos.

> **Veredicto:** la paginación por clave y la búsqueda de texto de PostgreSQL resuelven la pantalla
> de listado de casi cualquier tienda; el motor aparte se gana con volumen, no con la primera queja.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** La comparación de filas es del estándar, igual que `FETCH FIRST`; `LIMIT`
> y `OFFSET` son sintaxis extendida que casi todos los motores aceptan. Lo que hace rápida la
> paginación por clave es el índice compuesto del motor. Qué se enseña al usuario —total, saltos de
> página— es convención de interfaz.

| Afirmación | Categoría | PostgreSQL 18 |
|---|---|---|
| Un `OFFSET` grande lee todas las filas que se salta | Motor | Sí: 500 020 filas, 302 ms |
| La paginación por clave cuesta lo mismo en cualquier página | Motor | Sí: 0,081 ms en la página 25 000 |
| `OFFSET` es coherente si llegan filas nuevas | Motor | No: repitió `PED-947907` |
| La comparación de filas usa el índice compuesto | Estándar, con índice del motor | Sí, `Index Cond: ROW(…) < ROW(…)` |
| Contar el total es gratis | Motor | No: 58 ms por el millón |
| Orden total con la clave primaria como desempate | Convención | — |

**Convención, la que más se repite.** *«`OFFSET` es lo normal, todos los frameworks lo hacen»* — lo
hacen por defecto porque es lo más fácil de programar, y deja de valer con la primera tabla grande o
la primera lista que se actualiza mientras alguien la recorre.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con índice, `OFFSET` es rápido en cualquier página" | La página 25 000 leyó 500 020 filas del índice: 302 ms |
| "La paginación por clave es más lenta porque tiene un `WHERE`" | 0,081 ms en la página 25 000, del orden de la primera |
| "`OFFSET` enseña siempre filas distintas" | Un pedido nuevo hizo que `PED-947907` saliera dos veces |
| "Ordenar por fecha basta" | Dos filas con la misma fecha no tienen orden; se desempata con la clave primaria |
| "Enseñar el total de páginas no cuesta nada" | 58 ms por cada recuento del millón |
| "Para buscar hace falta un motor de búsqueda" | Con miles de filas, `tsvector` con GIN basta |
| "`LIKE '%texto%'` es una búsqueda" | Compara caracteres: 0 de 328 sin tilde |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «LIMIT and OFFSET»: el coste de un `OFFSET` grande.
  <https://www.postgresql.org/docs/18/queries-limit.html>
- **Documentación** — PostgreSQL 18, «Row and Array Comparisons»: la comparación de filas.
  <https://www.postgresql.org/docs/18/functions-comparisons.html>
- **Documentación** — PostgreSQL 18, «Introduction» a la búsqueda de texto.
  <https://www.postgresql.org/docs/18/textsearch-intro.html>

---

## 🧠 Preguntas

1. ¿Qué diferencia la paginación por desplazamiento de la paginación por clave? 🟢
2. ¿Qué es un orden total, y por qué hace falta para paginar por clave? 🟢
3. ¿Qué hace `\gset` en `psql`? 🟢
4. ¿Qué índice necesita la paginación por clave de los pedidos más recientes? 🟡
5. ¿Qué significa `rows=500020.00` en el plan de la página 25 000? 🟡
6. ¿Qué dice la documentación de PostgreSQL sobre un `OFFSET` grande? 🟡
7. ¿Qué devuelve una API con paginación por clave para pedir la página siguiente? ¿Qué parte es del
   motor y qué parte es convención? 🟡
8. ¿Qué no puede hacer la paginación por clave que sí hace `OFFSET`? 🟡
9. ¿Por qué `PED-947907` salió en dos páginas seguidas con `OFFSET`? 🟠
10. ¿Qué pasa con `OFFSET` si se borra un pedido mientras alguien pagina? 🟠
11. ¿Por qué la página 25 000 por clave tarda lo mismo que la primera? 🟠
12. ¿Qué cuesta enseñar «página 3 de 50 000», y qué alternativas hay? 🟠
13. ¿Cuándo sigue siendo razonable `OFFSET`? 🟠
14. ¿Cuándo basta la búsqueda de texto de PostgreSQL para la caja de búsqueda de la tienda, y cuándo
    no? 🟠
15. ¿Por qué combinar búsqueda por relevancia y `OFFSET` da problemas? 🟠
16. Diseña la API de listado de pedidos del panel: parámetros, orden, cursor, índice y qué pasa al
    llegar pedidos nuevos. 🔴
17. Diagnostica: el desplazamiento infinito de la app de la tienda se vuelve lento a partir de la
    página 200, y algunos usuarios ven productos repetidos. 🔴
18. Defiende o refuta mantener `OFFSET` en toda la aplicación «porque los usuarios nunca pasan de la
    página 5», con los números del capítulo. 🔴

---

**Anterior:** [`05`](05-multi-inquilino.md) — multi-inquilino · **Siguiente:**
[`07`](07-simulacion-de-entrevista.md) — la simulación de entrevista · **Relacionado:**
[`09/05`](../09-otros-modelos/05-busqueda-de-texto.md) — la búsqueda de texto, medida.
