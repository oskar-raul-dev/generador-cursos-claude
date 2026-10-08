# 05 — CTE y recursión

> Qué nombra de verdad un `WITH`, por qué la respuesta clásica —*"las CTE son lentas porque
> materializan"*— dejó de ser cierta en 2019, y cómo se escribe una CTE recursiva que produce una
> serie de días o recorre una jerarquía sin colgarse. **Asume leído:**
> [`04`](04-agregacion-y-subconsultas.md) — de ahí vienen `GROUP BY` y la diferencia entre
> subconsulta correlacionada y no correlacionada. **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema)
- [2. `WITH`: un nombre, y la materialización que cambió en 2019](#2--with-un-nombre-y-la-materialización-que-cambió-en-2019)
- [3. `WITH RECURSIVE`: término base, término recursivo y la serie](#3--with-recursive-término-base-término-recursivo-y-la-serie)
- [4. La jerarquía, sobre una tabla que se crea y se borra](#4--la-jerarquía-sobre-una-tabla-que-se-crea-y-se-borra)
- [5. La recursión que no termina, y las dos defensas](#5--la-recursión-que-no-termina-y-las-dos-defensas)
- [6. Estándar, motor y convención](#6--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes)
- [Para profundizar](#-para-profundizar)
- [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El gerente pide el informe diario del cliente `CLI-00311` para la semana del 18 al 24 de marzo de
2024: un renglón por día, con los pedidos y el importe. Escribes el `GROUP BY` obvio.

```text
tienda=# SELECT p.creado_en::date AS dia, count(*) AS pedidos, sum(p.total) AS importe
tienda-#   FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
tienda-#  WHERE c.codigo = 'CLI-00311'
tienda-#    AND p.creado_en >= DATE '2024-03-18' AND p.creado_en < DATE '2024-03-25'
tienda-#  GROUP BY 1 ORDER BY 1;
    dia     | pedidos | importe
------------+---------+---------
 2024-03-20 |       1 | 7983.79
(1 fila)
```

Siete días pedidos, **una fila devuelta**. No es un error: `GROUP BY` agrupa las filas que existen,
y el 19 de marzo no existe ninguna. Pegado en una hoja de cálculo, ese informe dibuja el hueco como
continuidad y la gráfica miente. Para que salgan los seis días sin ventas alguien tiene que
**generar los siete días**: no están en ninguna tabla. Ese es el primer caso del capítulo; el
segundo es el simétrico, recorrer algo que sí está en una tabla pero cuya profundidad no conoces. Y
por el camino se cae el mito de rendimiento que más se repite sobre `WITH`.

---

## 2. 🧱 `WITH`: un nombre, y la materialización que cambió en 2019

Una **CTE** (*common table expression*, expresión de tabla común) es una subconsulta a la que le
pones nombre delante de la consulta que la usa: no crea nada en disco, no sobrevive a la sentencia y
compra legibilidad. **Quién lo manda:** el `WITH` no recursivo lo aceptan los tres motores del
corpus; no he verificado en qué cláusula de ISO/IEC 9075 aparece.

Lo que cuesta es otra historia, y es lo que casi nadie tiene actualizado. **Materializar** una CTE
es ejecutarla entera, guardar el resultado en un búfer —memoria o disco temporal— y leer de ahí;
**integrarla** (*inlining*) es lo contrario, fundirla con la consulta de fuera, que entonces puede
empujarle los filtros dentro. La misma consulta, dos veces, cambiando una palabra:

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# WITH p AS (
tienda(#   SELECT id, codigo, cliente_id, total FROM pedidos
tienda(# )
tienda-# SELECT codigo, total FROM p WHERE codigo = 'PED-00042';
                                                           QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Index Scan using pedidos_codigo_key on pedidos  (cost=0.42..2.64 rows=1 width=17) (actual time=0.108..0.111 rows=1.00 loops=1)
   Index Cond: (codigo = 'PED-00042'::text)
   Index Searches: 1
   Buffers: shared hit=1 read=3
   I/O Timings: shared read=0.063
 Planning:
   Buffers: shared hit=87
 Planning Time: 0.227 ms
 Execution Time: 0.136 ms
(9 filas)

Duración: 1,210 ms
```

El plan **ni menciona la CTE**: el `WHERE` viajó hacia dentro y acabó como `Index Cond` del índice
`pedidos_codigo_key`. Cuatro páginas, 0,136 ms. Ahora con la palabra que prohíbe integrarla:

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# WITH p AS MATERIALIZED (
tienda(#   SELECT id, codigo, cliente_id, total FROM pedidos
tienda(# )
tienda-# SELECT codigo, total FROM p WHERE codigo = 'PED-00042';
                                                          QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------
 CTE Scan on p  (cost=20770.00..43270.00 rows=1 width=48) (actual time=69.617..281.020 rows=1.00 loops=1)
   Filter: (codigo = 'PED-00042'::text)
   Rows Removed by Filter: 999999
   Storage: Disk  Maximum Storage: 47968kB
   Buffers: shared hit=3227 read=7543, temp written=5996
   I/O Timings: shared read=0.584, temp write=15.425
   CTE p
     ->  Seq Scan on pedidos  (cost=0.00..20770.00 rows=1000000 width=33) (actual time=0.192..92.742 rows=1000000.00 loops=1)
           Buffers: shared hit=3227 read=7543
           I/O Timings: shared read=0.584
 Planning:
   Buffers: shared hit=89
 Planning Time: 0.506 ms
 Execution Time: 283.995 ms
(14 filas)

Duración: 285,923 ms
```

- `CTE p` es ahora un nodo aparte con su `Seq Scan` del millón de filas, y el filtro se aplica
  **después**: `Rows Removed by Filter: 999999`. **Cuánto cuesta:** cuatro páginas contra 10 770,
  0,136 ms contra 283,995 ms de ejecución —**2 088 veces**— y 47 MB escritos en un fichero temporal,
  que es lo que dice la línea `Maximum Storage: 47968kB`.

> **📝 Contexto.** Hasta PostgreSQL 11 inclusive, **el segundo plan era el único posible**: una CTE
> era una barrera de optimización y se materializaba siempre. De ahí sale el *"no uses `WITH`, es
> lento"* que todavía llena internet. **PostgreSQL 12, del 3 de octubre de 2019, lo cambió**: una
> CTE que no es recursiva, no tiene efectos secundarios y se referencia **una sola vez** se integra
> por defecto, y aparecieron `MATERIALIZED` y `NOT MATERIALIZED` para forzar cada lado. Un artículo
> anterior a esa fecha describe un motor que ya no existe.

La condición que más se olvida es la tercera. A un `WITH por_estado AS (SELECT estado, count(*) …)`
que después se nombra dos veces —en el `FROM` y en el escalar del porcentaje sobre el total—
PostgreSQL **lo materializa solo** aunque no se lo pidas, y ahí materializar es lo correcto:
forzando lo contrario, esas cinco filas tardan **238,399 ms en vez de 132,168 ms**, porque el `GROUP
BY` se pega en los dos sitios y el `Seq Scan` del millón de pedidos se corre dos veces.

- **Cuándo sí cada una:** `MATERIALIZED` para un cálculo caro que se reutiliza, una función volátil
  o un plan integrado peor; `NOT MATERIALIZED` para una CTE barata nombrada varias veces donde
  quieres que entre el filtro de fuera. **Cuándo no:** ponerla "por si acaso".

> **Veredicto:** un `WITH` es un nombre, no una tabla, y desde PostgreSQL 12 no es una barrera de
> optimización salvo que se lo pidas. Ninguna de las dos palabras se escribe sin un `EXPLAIN` que la
> justifique.

---

## 3. 🧱 `WITH RECURSIVE`: término base, término recursivo y la serie

Una CTE **recursiva** se nombra a sí misma. Tiene dos mitades unidas por `UNION` o `UNION ALL`: el
**término base**, que produce las filas de arranque, y el **término recursivo**, que se alimenta
solo de lo que dio la vuelta anterior y se repite hasta devolver cero filas. Con eso se resuelve §1.

```text
tienda=# WITH RECURSIVE calendario (dia) AS (
tienda(#       SELECT DATE '2024-03-18'                   -- término base: una fila
tienda(#     UNION ALL
tienda(#       SELECT dia + 1 FROM calendario             -- término recursivo: se nombra a sí mismo
tienda(#        WHERE dia < DATE '2024-03-24'             -- la condición de parada
tienda(# )
tienda-# SELECT c.dia, count(p.id) AS pedidos, coalesce(sum(p.total), 0) AS importe
tienda-#   FROM calendario c
tienda-#   LEFT JOIN pedidos p
tienda-#          ON p.creado_en >= c.dia AND p.creado_en < c.dia + 1
tienda-#         AND p.cliente_id = (SELECT id FROM clientes WHERE codigo = 'CLI-00311')
tienda-#  GROUP BY c.dia ORDER BY c.dia;
    dia     | pedidos | importe
------------+---------+---------
 2024-03-18 |       0 |       0
 2024-03-19 |       0 |       0
 2024-03-20 |       1 | 7983.79
 2024-03-21 |       0 |       0
 2024-03-22 |       0 |       0
 2024-03-23 |       0 |       0
 2024-03-24 |       0 |       0
(7 filas)

Duración: 56,739 ms
```

- **El calendario manda y los pedidos se cuelgan de él**, así que el `LEFT JOIN` va de `calendario`
  hacia `pedidos` y **las tres condiciones viven en el `ON`**: en un `WHERE`, el filtro del cliente
  tiraría los días vacíos y volveríamos al informe de §1. `count(p.id)` cuenta emparejamientos, no
  renglones, y por eso da 0 donde `count(*)` daría 1.
- **Cuánto cuesta:** el rango real de `pedidos` va de `2023-01-01 00:02:34.919783` a `2025-09-26
  23:58:06.785848` —medido—, o sea **1 000 días exactos**: generarlos así tarda 0,937 ms y con
  `generate_series(…, interval '1 day')`, 0,743 ms.
- **Cuándo no:** en PostgreSQL, casi nunca para una serie; el argumento de la CTE recursiva es la
  **portabilidad**. `generate_series` es de PostgreSQL: MySQL 9.7.2 responde `ERROR 1064` y en
  SQLite es una extensión del intérprete que solo genera enteros.

---

## 4. 🧱 La jerarquía, sobre una tabla que se crea y se borra

El esquema de la tienda **no tiene jerarquía**: `productos.categoria` es texto plano con siete
valores. Hay que fabricarla, y aquí se declara cómo: **`CREATE TEMP TABLE`, poblada desde esas siete
categorías reales, que se destruye sola al cerrar la sesión**. El esquema del corpus no se toca.

```text
tienda=# CREATE TEMP TABLE categorias (
tienda(#   nombre text PRIMARY KEY,
tienda(#   padre  text REFERENCES categorias(nombre)   -- foránea reflexiva: el padre es otra fila
tienda(# );
CREATE TABLE
tienda=# INSERT INTO categorias VALUES ('catalogo', NULL), ('tecnologia','catalogo'),
tienda-#                               ('ocio','catalogo'), ('casa','catalogo');
INSERT 0 4
tienda=# INSERT INTO categorias (nombre, padre)
tienda-# SELECT DISTINCT p.categoria,
tienda-#        CASE p.categoria WHEN 'audio' THEN 'tecnologia' WHEN 'informatica' THEN 'tecnologia'
tienda-#             WHEN 'video' THEN 'tecnologia' WHEN 'hogar' THEN 'casa' ELSE 'ocio' END
tienda-#   FROM productos p;
INSERT 0 7
```

Once nodos: cuatro inventados —la raíz y tres agrupadores— y las siete reales. El descenso desde la
raíz, acumulando nivel y ruta:

```text
tienda=# WITH RECURSIVE arbol (nombre, nivel, ruta) AS (
tienda(#       SELECT nombre, 0, nombre                 -- término base: la raíz
tienda(#         FROM categorias WHERE padre IS NULL
tienda(#     UNION ALL
tienda(#       SELECT c.nombre, a.nivel + 1, a.ruta || ' > ' || c.nombre
tienda(#         FROM categorias c JOIN arbol a ON c.padre = a.nombre
tienda(# )
tienda-# SELECT nivel, ruta FROM arbol ORDER BY ruta;
 nivel |                ruta
-------+-------------------------------------
     0 | catalogo
     1 | catalogo > casa
     2 | catalogo > casa > hogar
     1 | catalogo > ocio
     2 | catalogo > ocio > deporte
     2 | catalogo > ocio > juguetes
     2 | catalogo > ocio > libros
     1 | catalogo > tecnologia
     2 | catalogo > tecnologia > audio
     2 | catalogo > tecnologia > informatica
     2 | catalogo > tecnologia > video
(11 filas)
```

- El término recursivo **une el árbol parcial con la tabla**: `arbol` del lado del padre y
  `categorias` del lado del hijo. Invertirlo sube en vez de bajar, que es como se pide la cadena de
  ancestros de una hoja.
- `nivel` y `ruta` **se acumulan en la propia recursión**, y son la razón por la que esto no se
  escribe con `JOIN` sueltos: con profundidad desconocida no sabes cuántos poner. **Cuánto cuesta:**
  una lectura de la tabla por nivel; sin índice sobre `padre`, cada nivel es un recorrido completo.
- **Teardown:** nada que borrar a mano. Una tabla `TEMP` vive en `pg_temp` y **desaparece al
  desconectar**; `\dt` en una sesión nueva vuelve a listar las seis tablas del dominio.

> **🧠 Modelo mental.** Una CTE recursiva no es una función que se llama a sí misma: es un bucle.
> Cada vuelta recibe **solo las filas nuevas** de la anterior, no el acumulado, y termina cuando una
> vuelta no produce ninguna.

---

## 5. 🩺 La recursión que no termina, y las dos defensas

Si la jerarquía tiene un ciclo, el bucle no encuentra nunca su vuelta vacía. Se provoca a propósito
sobre la misma tabla temporal, poniendo la raíz por debajo de una hoja:

```text
tienda=# UPDATE categorias SET padre = 'audio' WHERE nombre = 'catalogo';
UPDATE 1
tienda=# SET statement_timeout = '5s';
SET
tienda=# WITH RECURSIVE arbol (nombre, nivel) AS (
tienda(#       SELECT nombre, 0 FROM categorias WHERE nombre = 'tecnologia'
tienda(#     UNION ALL
tienda(#       SELECT c.nombre, a.nivel + 1 FROM categorias c JOIN arbol a ON c.padre = a.nombre
tienda(# )
tienda-# SELECT count(*) FROM arbol;
ERROR:  canceling statement due to statement timeout
```

Sin ese `statement_timeout` la consulta crece hasta llenar el disco temporal. **Primera defensa:
`UNION` en lugar de `UNION ALL`**, que elimina duplicados en cada vuelta; cuando el ciclo reproduce
una fila ya vista la descarta, y el bucle se queda sin filas nuevas.

```text
tienda=# WITH RECURSIVE arbol (nombre) AS (
tienda(#       SELECT nombre FROM categorias WHERE nombre = 'tecnologia'
tienda(#     UNION
tienda(#       SELECT c.nombre FROM categorias c JOIN arbol a ON c.padre = a.nombre
tienda(# )
tienda-# SELECT count(*) AS nodos, string_agg(nombre, ',' ORDER BY nombre) FROM arbol;
 nodos |                                     string_agg
-------+-------------------------------------------------------------------------------------
    11 | audio,casa,catalogo,deporte,hogar,informatica,juguetes,libros,ocio,tecnologia,video
(1 fila)
```

- **Cuidado con qué columnas lleva dentro la CTE.** Con `nivel` en la lista, esa misma consulta con
  `UNION` **tampoco termina**: `('audio', 3)` y `('audio', 6)` son distintas y no se descarta
  ninguna; lo comprobé, y agota el `statement_timeout` igual que `UNION ALL`. **Cuánto cuesta
  `UNION`:** una tabla hash o un ordenamiento de lo acumulado en cada vuelta.

**Segunda defensa: un contador de profundidad**, que convive con `UNION ALL` y no depende de que las
filas sean idénticas.

```text
tienda=# WITH RECURSIVE arbol (nombre, nivel) AS (
tienda(#       SELECT nombre, 0 FROM categorias WHERE nombre = 'tecnologia'
tienda(#     UNION ALL
tienda(#       SELECT c.nombre, a.nivel + 1 FROM categorias c JOIN arbol a ON c.padre = a.nombre
tienda(#        WHERE a.nivel < 5                       -- el corte: nunca más de cinco niveles
tienda(# )
tienda-# SELECT nivel, count(*) AS filas FROM arbol GROUP BY nivel ORDER BY nivel;
 nivel | filas
-------+-------
     0 |     1
     1 |     3
     2 |     1
     3 |     3
     4 |     7
     5 |     1
(6 filas)
```

- Termina, y **el resultado delata el ciclo**: el nivel 2 vuelve a tener una fila y el 3 otra vez
  tres, porque ya va por la segunda vuelta del mismo lazo. **Cuándo sí cada una:** `UNION` si solo
  quieres los nodos alcanzables; el contador si necesitas el nivel, la ruta o saber que hubo corte.

> **Veredicto:** toda recursión sobre datos que alguien puede editar lleva defensa, y la única que
> no se rompe al añadir columnas es el contador de profundidad.

> **🩺 Diagnóstico.** Recursiva que no vuelve: localiza el `pid` en `pg_stat_activity` y córtala con
> `pg_cancel_backend(pid)`. Antes de tocar el SQL, busca el lazo con la versión de `UNION` sin
> columnas acumuladas: si alcanza más nodos de los que tiene la tabla, hay ciclo.

---

## 6. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**: donde la
> columna "Estándar" dice *no verificado*, lo afirmado es lo que hacen los motores, medido en
> sesión.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| La palabra `RECURSIVE` es obligatoria | No verificado | Sí: `ERROR: relation "s" does not exist`, y sugiere añadirla | Sí: `ERROR 1146 … Table 'tienda.s' doesn't exist` | **No**: es opcional y se ignora; la recursión funciona sin ella |
| Una CTE usada una vez se materializa | No verificado; es decisión de implementación | **No desde la 12**; hasta la 11, siempre | No: la funde con la consulta de fuera | No: la aplana |
| Existen `MATERIALIZED` y `NOT MATERIALIZED` | No verificado | Sí, desde la 12 | **No**: `ERROR 1064` de sintaxis | Sí, las dos |
| Hay tope de profundidad de la recursión | No verificado | **No**: crece hasta agotar disco o `statement_timeout` | Sí: 1 000 por `cte_max_recursion_depth`, y aborta con `ERROR 3636` | **No** |
| `UNION` en el término recursivo corta ciclos | No verificado | Sí (medido: 11 nodos de 11) | Sí (medido: 3 filas) | Sí (medido: 3 filas) |
| Hay cláusula dedicada de detección de ciclos | No verificado | Sí: `CYCLE … SET … USING …`, desde la 14 | No: `ERROR 1064` | No: `Parse error … near "CYCLE"` |

MariaDB 12.3.3 hace lo mismo que MySQL: exige `RECURSIVE` —mismo `ERROR 1146`— y tiene su propio
tope, `max_recursive_iterations`, también en 1 000.

**Convención:** *"las CTE son lentas porque materializan"*. Fue cierto hasta PostgreSQL 11 y dejó de
serlo con la 12, en octubre de 2019: hoy, en la 18.6, el ejemplo de §2 mide **0,136 ms integrado
contra 283,995 ms materializado**, y la penalización la trae la palabra `MATERIALIZED`, no el
`WITH`. La otra mitad —*"úsala para forzar el orden de ejecución"*— tampoco vale ya sin
`MATERIALIZED`.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un `WITH` crea una tabla temporal" | No crea nada. Es un nombre para una subconsulta, y el motor decide si la evalúa aparte o la funde |
| "Las CTE son lentas porque materializan" | Desde PostgreSQL 12 se integran si no son recursivas, no tienen efectos secundarios y se usan una sola vez. Medido: 0,136 ms contra 283,995 ms |
| "`MATERIALIZED` es una optimización" | Es una prohibición: impide empujar el filtro dentro. En §2 cuesta 47 MB de disco temporal y 999 999 filas descartadas |
| "Con `UNION` ya no hay recursión infinita" | Solo si las filas repetidas son idénticas. Con un `nivel` acumulado, `('audio', 3)` y `('audio', 6)` son distintas y el bucle sigue |
| "`RECURSIVE` hace falta en todos los motores" | En PostgreSQL 18.6 y MySQL 9.7.2 sí; en SQLite 3.53.4 es opcional y se ignora |
| "Si la recursión se descontrola, el motor la para" | MySQL sí, a las 1 000 vueltas. PostgreSQL y SQLite no tienen tope: crecen hasta agotar el disco temporal |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «WITH Queries»: término base, término recursivo, `MATERIALIZED`
  y `CYCLE`. <https://www.postgresql.org/docs/18/queries-with.html>
- **Documentación** — PostgreSQL 12, notas de la versión: la línea que cambió la materialización por
  defecto. <https://www.postgresql.org/docs/release/12.0/>
- **Documentación** — PostgreSQL 18, «Set Returning Functions»: `generate_series`.
  <https://www.postgresql.org/docs/18/functions-srf.html>
- **Documentación** — MySQL 9.7, «WITH (Common Table Expressions)»: `RECURSIVE` obligatoria y
  `cte_max_recursion_depth`. <https://dev.mysql.com/doc/refman/9.7/en/with.html>
- **Documentación** — SQLite, «The WITH Clause»: `MATERIALIZED`, `NOT MATERIALIZED` y por qué
  `RECURSIVE` es opcional. <https://www.sqlite.org/lang_with.html>
- **Estándar** — ISO/IEC 9075-2 (*Foundation*), cláusula `<with clause>` y su opción `RECURSIVE`. De
  pago, sin URL pública y **no verificada en esta edición**.

---

## 🧠 Preguntas

1. ¿Qué es una CTE y qué crea en disco? 🟢
2. Nombra las dos mitades de una CTE recursiva y di cuál se menciona a sí misma. 🟢
3. ¿Cuándo deja de iterar una CTE recursiva? 🟢
4. En el informe de §1 se piden siete días y sale uno: ¿por qué, y de dónde salen los otros seis? 🟢
5. Distingue `MATERIALIZED` de `NOT MATERIALIZED`: ¿cuál prohíbe qué? 🟡
6. ¿Qué tres condiciones exige PostgreSQL 12 para integrar una CTE? Señala la que más se olvida. 🟡
7. ¿`RECURSIVE` es obligatoria por estándar o por motor? Di qué hace cada uno de los tres. 🟡
8. En §3, ¿por qué el filtro del cliente va en el `ON` y no en el `WHERE`? 🟡
9. Que una recursión descontrolada se corte sola, ¿es del estándar o del motor? Di qué hace cada
   uno. 🟠
10. Alguien añade `MATERIALIZED` a todas las CTE "para que el plan sea estable". Dale el argumento
    de coste, con los números de §2. 🟠
11. ¿Por qué `UNION` corta un ciclo y `UNION ALL` no, y en qué caso `UNION` **tampoco** lo corta? 🟠
12. La CTE `por_estado` de §2 se nombra dos veces: ¿por qué `NOT MATERIALIZED` la hace más lenta? 🟠
13. ¿Cuándo preferirías una CTE recursiva a `generate_series`, sabiendo que es más lenta? 🟠
14. Escribe la CTE recursiva que dé la cadena de ancestros de `audio` hasta la raíz, con el nivel,
    sobre la tabla temporal de §4. 🔴
15. El informe diario sin huecos tiene que correr con el mismo SQL en PostgreSQL y en MySQL 9.7.2:
    escribe la consulta y señala las diferencias de dialecto que resolviste. 🔴
16. Te pasan una consulta recursiva que no vuelve en producción: escribe la secuencia de diagnóstico
    —qué miras, con qué, en qué orden— y las dos correcciones posibles. 🔴

---

**Anterior:** [`04`](04-agregacion-y-subconsultas.md) · **Siguiente:**
[`06`](06-funciones-de-ventana.md) — las funciones de ventana · **Relacionado:**
[`04`](04-agregacion-y-subconsultas.md) — `GROUP BY` y las subconsultas que un `WITH` ordena ·
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) — por qué el
`LEFT JOIN` del calendario devuelve nulos que hay que envolver en `coalesce`.
