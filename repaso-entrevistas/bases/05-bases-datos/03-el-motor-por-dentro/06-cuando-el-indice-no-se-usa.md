# 06 — Cuándo el índice no se usa

> El catálogo completo: las seis razones por las que un índice que existe no aparece en el plan, o
> aparece y no ayuda; cómo se distingue cada una en dos minutos; lo que cuesta un índice en
> escritura, medido en registros de WAL; y cuándo el problema deja de ser de índices y pasa a ser de
> particionado. **Asume leído:** [`03`](03-compuestos-parciales-y-de-cobertura.md),
> [`04`](04-estadisticas-y-el-planificador.md) y [`05`](05-explain-y-explain-analyze.md) — este
> capítulo es la síntesis de los tres y reutiliza sus mediciones en vez de repetirlas. **Vigencia:**
> 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Las seis razones](#2--las-seis-razones) · [3. Razón 1 y
  razón 2, las que escribiste tú](#3--razón-1-y-razón-2-las-que-escribiste-tú)
- [4. Razón 3, el filtro no es selectivo](#4--razón-3-el-filtro-no-es-selectivo) · [5. Razón 4, el
  presupuesto está mal](#5--razón-4-el-presupuesto-está-mal)
- [6. Razón 5, el índice no aplica en ese contexto](#6--razón-5-el-índice-no-aplica-en-ese-contexto)
  · [7. Razón 6, el índice se usa y aun así pierde](#7--razón-6-el-índice-se-usa-y-aun-así-pierde)
- [8. Lo que cuesta un índice en escritura](#8--lo-que-cuesta-un-índice-en-escritura) · [9.
  Particionado, y cuándo compensa](#9--particionado-y-cuándo-compensa)
- [10. Estándar, motor y convención](#10--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El viernes alguien miró los informes lentos y creó tres índices. El lunes las tres consultas siguen
igual, y una va peor que antes:

```text
WHERE lower(email) = 'cliente311@ejemplo.test'   -> Seq Scan, 618 páginas, 17,522 ms
WHERE cantidad = 5                               -> usa el índice, 190,789 ms (el Seq Scan: 167,704)
WHERE metodo = 'EFECTIVO'                        -> Seq Scan, 8 232 páginas, 59,164 ms
```

Las tres cifras están medidas, y cada una está en su capítulo: la primera en
[`03`](03-compuestos-parciales-y-de-cobertura.md) §5, la segunda en
[`03`](03-compuestos-parciales-y-de-cobertura.md) §2, la tercera en
[`05`](05-explain-y-explain-analyze.md) §5. **Son tres causas distintas y ninguna es un error del
motor**: en la tercera, además, el planificador tiene razón y el índice sobra. La pregunta de
entrevista *"¿por qué no se usa mi índice?"* no tiene una respuesta: tiene seis, y lo que se evalúa
es que sepas **en qué orden descartarlas**. Las dos salidas de §6 se volvieron a correr el 27 de
septiembre de 2026 con `psql` en español.

---

## 2. 🧱 Las seis razones

**Qué es:** el catálogo cerrado de por qué un índice existente no aparece en el plan, o aparece y no
paga. Cada fila lleva la señal que la delata en el plan, para que no haya que adivinar.

| # | Razón | Cómo se ve en el plan | Dónde se mide |
|---|---|---|---|
| 1 | La columna va **envuelta** en una función, una expresión o una conversión | `Filter: (lower(email) = …)` sobre un `Seq Scan` | §3 |
| 2 | El filtro **no nombra el prefijo izquierdo** del compuesto | `Index Searches` mucho mayor que 1 | §3 |
| 3 | El filtro **no es selectivo** y barrer sale más barato | `Rows Removed by Filter` bajo respecto de las filas que salen | §4 |
| 4 | El **presupuesto está mal** y el motor decide con un número falso | `rows=` y `actual rows` separados por órdenes de magnitud | §5 |
| 5 | El índice **no es aplicable** en ese contexto: parcial, parámetro, `OR`, colación | El índice no sale en el plan y el filtro está entero en `Filter` | §6 |
| 6 | El índice **se usa y aun así pierde** por la vuelta al heap | `Heap Fetches` alto, o `Heap Blocks` mayor que las páginas del índice | §7 |

**Quién lo manda:** motor, entera. ISO/IEC 9075 no define índices ni planificador (§10), así que
ninguna de las seis sale de la norma; las seis se comportan igual en PostgreSQL, MySQL y SQLite en
lo esencial, y difieren en los detalles que §10 tabula.

**El orden en que se descartan** es lo que convierte el catálogo en un método. Son cuatro preguntas,
y cada una se responde mirando el plan, no el código:

```text
1. ¿Aparece el nombre del índice en el plan?
   No  -> razones 1, 2 o 5. Mira si el filtro está en `Filter` y cómo está escrito.
   Sí  -> sigue.
2. ¿La condición está en `Index Cond` o en `Filter`?
   En `Filter` -> el índice se usa para otra cosa; esa columna no la cubre.
3. ¿`rows=` y `actual rows` se parecen?
   No  -> razón 4. Todo lo que hay por encima se decidió con un número falso.
4. ¿Cuántas páginas se leyeron, y cuántas filas salieron?
   Muchas páginas y pocas filas -> razón 6. Muchas filas -> razón 3, y el motor tenía razón.
```

> **🧠 Modelo mental.** "El índice no se usa" es un síntoma, no un diagnóstico. En dos de los seis
> casos el motor está haciendo lo correcto, y el arreglo es dejar de pedir el índice; en los otros
> cuatro el arreglo está en sitios distintos —el `WHERE`, el orden de las columnas, las estadísticas
> o el `VACUUM`—, y aplicar el de uno al otro es el modo de fallo más común.

---

## 3. 🧱 Razón 1 y razón 2, las que escribiste tú

**Qué son:** las dos razones que no están en el motor ni en los datos, sino en cómo está escrita la
consulta. Van juntas porque comparten la corrección —reescribir— y la señal —el índice no aparece, o
aparece haciendo un trabajo que no esperabas—.

**Razón 1: un índice guarda la columna, no el resultado de una función sobre la columna.**
`clientes_email_key` guarda `email`; `lower(email)` es otra cosa, y el motor no sabe que una se
deriva de la otra. Medido en [`03`](03-compuestos-parciales-y-de-cobertura.md) §5: `Seq Scan` con
`Filter: (lower(email) = …)`, 618 páginas, 49 999 filas descartadas y **17,522 ms**; con un índice
funcional sobre `lower(email)` —2448 kB, 134,664 ms de construcción— la misma consulta pasa a `Index
Cond` y **0,041 ms**. La familia entera se reconoce por la forma, no por el caso:

```text
WHERE lower(email) = …                  -- función sobre la columna
WHERE creado_en::date = DATE '2026-01-01' -- conversión sobre la columna
WHERE total * 1.21 > 1000               -- aritmética sobre la columna
WHERE codigo LIKE '%00042'              -- comodín por la izquierda: no hay prefijo que buscar
WHERE extract(year FROM creado_en) = 2026
```

- **La corrección es siempre la misma y es gratis:** dejar la columna sola a un lado del operador.
  `creado_en >= DATE '2026-01-01' AND creado_en < DATE '2026-01-02'` usa el índice sobre
  `creado_en`; `creado_en::date = …` no. `total > 1000 / 1.21`, igual. **Cuándo no alcanza:** cuando
  la expresión es el criterio de negocio de verdad —comparar correos sin distinguir mayúsculas—, y
  entonces el índice funcional es la respuesta, con su precio: la expresión se evalúa **en cada
  `INSERT` y en cada `UPDATE`** de esa columna.
- **Cuánto cuesta equivocarse:** las 618 páginas contra 4 del ejemplo, que a 50 000 clientes son 17
  ms y a 50 millones son minutos. El coste no crece con el error: crece con la tabla.

**Razón 2: el filtro no nombra la primera columna del índice compuesto.** Es la regla del prefijo
izquierdo de [`03`](03-compuestos-parciales-y-de-cobertura.md) §2, y lo que la hace peligrosa hoy es
que 📝 desde PostgreSQL 18 **el índice sí aparece en el plan**: el *skip scan* de B-tree salta de un
valor de la primera columna al siguiente, así que el nombre del índice está ahí y el problema no.

- Medido: con `(producto_id, cantidad)` y `WHERE cantidad = 5`, el plan usa el índice con **`Index
  Searches: 51`** —una bajada por tramo—, lee **2 702 de sus 3 072 páginas, el 88 %**, y tarda
  **190,789 ms**; el `Seq Scan` que el motor descartó tarda **167,704 ms**. Eligió el índice porque
  le salía un 14 % más barato en coste estimado, y perdió.
- **La señal que hay que aprender es `Index Searches`.** Vale 1 cuando el filtro nombra el prefijo y
  el tramo es contiguo, y vale tantas como valores distintos tenga la columna que te falta: son 51
  con 5 000 productos delante, y **7** cuando el índice es `(cantidad, producto_id)` y delante solo
  hay siete valores de `cantidad`. Esa asimetría es la selectividad, y es la que decide cuál columna
  va primero.

> **⚠️ Advertencia.** Que el índice aparezca en el plan no significa que el índice sirva. Con *skip
> scan* la única forma de verlo es `Index Searches` y las páginas leídas; en PostgreSQL 17 y
> anteriores el mismo caso salía como `Seq Scan` limpio, que es como lo cuenta casi toda la
> documentación de internet que vas a encontrar.

> **Veredicto:** antes de crear nada, lee tu propio `WHERE`. Si la columna indexada está dentro de
> un paréntesis, o si no es la primera del índice, el problema no es del motor y no lo arregla otro
> índice.

---

## 4. 🩺 Razón 3, el filtro no es selectivo

**Qué es:** el caso en que el índice existe, sirve, el planificador lo evalúa y lo descarta **porque
barrer la tabla es más barato**. No es un fallo: es la decisión correcta, y es la razón que más
veces se diagnostica mal.

El mecanismo está en cómo se paga cada camino. Bajar por un índice y volver al heap por cada fila
son **saltos al azar** sobre el disco; leer la tabla en secuencia son páginas contiguas. En cuanto
el filtro deja pasar una fracción grande de la tabla, el número de saltos supera al de páginas y el
índice pierde. Medido en [`05`](05-explain-y-explain-analyze.md) §5, con `pagos`:

```text
tienda=# EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM pagos WHERE metodo = 'EFECTIVO';
                                 QUERY PLAN
----------------------------------------------------------------------------
 Aggregate (actual time=59.115..59.124 rows=1.00 loops=1)
   Buffers: shared read=8232
   I/O Timings: shared read=1.830
   ->  Seq Scan on pagos (actual time=0.137..48.733 rows=273126.00 loops=1)
         Filter: (metodo = 'EFECTIVO'::text)
         Rows Removed by Filter: 546874
         Buffers: shared read=8232
         I/O Timings: shared read=1.830
 Planning:
   Buffers: shared hit=78 read=2
   I/O Timings: shared read=0.030
 Planning Time: 0.351 ms
 Execution Time: 59.164 ms
(13 filas)
```

- **273 126 de 820 000 filas: el 33 %.** Un índice sobre `metodo` tendría que hacer 273 126 visitas
  al heap para ahorrarse 8 232 lecturas secuenciales. No hay forma de que gane, y por eso el
  capítulo `03` ni lo crea.
- **La cifra que decide** no es el porcentaje redondo que se recita —"a partir del 10 % ya no"— sino
  la relación entre `Rows Removed by Filter` y las filas que salen: 546 874 contra 273 126 es casi
  uno a dos, y eso es un filtro que no filtra. El mismo plan con 52 filas de un millón sería un
  índice desaprovechado.

**Cómo se comprueba que el motor tiene razón, sin creerle:** se le quita la opción y se mide el otro
camino. `SET enable_indexscan = off` más `enable_bitmapscan = off` fuerzan el `Seq Scan`, y
`enable_seqscan = off` fuerza lo contrario —no lo prohíbe: lo encarece con una constante, así que el
plan sigue siendo posible—. Es lo que dio los dos números de §3: **190,789 ms con índice contra
167,704 ms barriendo**. **Cuánto cuesta la prueba:** nada en disco, y solo vale para tu sesión;
**hay que devolverla con `RESET`**, porque si no los planes siguientes no se parecen a los del
corpus. **Cuándo sí** usarla: exactamente aquí, para tener el número del camino que el motor
rechazó. **Cuándo no:** dejarla puesta en producción como "arreglo".

> **🩺 Diagnóstico.** Si el plan dice `Seq Scan` y quieres saber si es un error, no crees el índice:
> apaga los accesos por índice, mide el otro camino y compara páginas. Si el `Seq Scan` gana, el
> arreglo no es un índice — es cambiar la consulta para que devuelva menos filas, o aceptar que ese
> informe lee la tabla entera porque pregunta por la tabla entera.

---

## 5. 🩺 Razón 4, el presupuesto está mal

**Qué es:** el índice existe y sirve, pero el planificador decide con una estimación que no se
parece a la realidad, y con ese presupuesto el plan que elige es el malo. Es la razón que más caro
sale, porque el síntoma aparece lejos de la causa. El dueño del mecanismo es
[`04`](04-estadisticas-y-el-planificador.md); aquí lo que importa es **reconocerla en el plan**.

Las tres formas medidas, con su número:

| Forma | Estimado | Real | Consecuencia |
|---|---|---|---|
| Correlación entre dos columnas del `WHERE` | `rows=80` | 14 864 | `Nested Loop` con 14 864 bajadas y 60 260 páginas |
| Estadística vieja tras una carga | `rows=124650` | 420 000 | El motor cree que `PENDIENTE` es el 12 % y ya es el 32 % |
| Expresión sin estadística ninguna | `rows=20500` | 1 366 667 | La misma estimación exacta para 0 filas y para 1,3 millones |

- **La primera** viene de multiplicar dos selectividades que no son independientes: `producto_id`
  determina `precio_unit` en el corpus, así que el segundo filtro no descarta nada que el primero no
  hubiera descartado. Se corrige declarando la dependencia con `CREATE STATISTICS … (dependencies)`,
  y el error cae **de 186 veces a un 11 %** —`rows=16461` contra 14 864— sin crear un solo índice.
- **La segunda** no necesita correlación: basta que los datos hayan cambiado. Tras un `ANALYZE`, la
  estimación es de 419 510 contra 420 000 reales, un 0,1 % de error en 150 ms. Y pasa **con
  autovacuum encendido**, porque su umbral es 50 filas más el 10 % de la tabla: un millón de pedidos
  necesita 100 050 modificaciones, y una carga nocturna de 90 000 filas no lo dispara nunca.
- **La tercera** es la que no se arregla con `ANALYZE`: `carga->>'origen'` es una expresión sobre
  `jsonb` y no hay estadística de expresiones que el planificador pueda consultar, así que cae en su
  selectividad por defecto. Ese `rows=20500` **es una constante disfrazada de estimación**: sale
  idéntica para una clave que no existe y para una que devuelve 1 366 667 filas.

**Cuánto cuesta:** en la primera forma, 60 260 páginas y 187,822 ms donde el plan correcto usa las
29 167 de la tabla y 129,280 ms. Y el coste que no se ve: **cuatro índices creados para arreglar un
plan cuyo problema era un `rows=`**, cada uno con su escritura extra por fila (§8).

> **🩺 Diagnóstico.** Recorre el plan de abajo arriba y para en el **primer** nodo donde `rows=` y
> `actual rows` se separan más de un orden de magnitud. Si ese nodo es un `Seq Scan` con dos filtros
> sobre la misma tabla, sospecha de la independencia asumida; si es uno solo y la tabla creció hace
> poco, de la estadística vieja; si el filtro lleva una expresión, de que no hay estadística que
> consultar.

---

## 6. 🧱 Razón 5, el índice no aplica en ese contexto

**Qué es:** el grupo de casos en que el índice es el correcto para esa columna y aun así el motor no
puede usarlo, porque algo del contexto —el predicado del índice, la forma del plan, el operador o la
colación— rompe la equivalencia. Es la razón más larga de enumerar y la que más veces produce el
*"en mi máquina sí se usaba"*.

**El índice parcial cuyo predicado no se puede demostrar.** Un parcial con `WHERE estado =
'ANULADO'` solo se usa si el planificador **prueba** que el `WHERE` de la consulta implica el del
índice. Medido en [`03`](03-compuestos-parciales-y-de-cobertura.md) §4: con `estado = 'ANULADO'` el
plan es un `Index Scan` sobre el parcial, sin línea `Filter` y en 0,024 ms; con `estado =
'PENDIENTE'` el parcial **ni aparece**, porque `PENDIENTE` no implica `ANULADO`, y cae al índice
completo con `Rows Removed by Filter: 46`. El coste de la asimetría: 1136 kB y 38 ms de construcción
que a esa consulta no le sirven de nada.

**El plan genérico con el valor en un parámetro.** Es el mismo caso, con el valor escondido: con
`WHERE estado = $1` el planificador no sabe qué vale `$1` mientras planifica, así que no puede
demostrar la implicación, y el parcial no se usa. PostgreSQL planifica una sentencia preparada cinco
veces con los valores reales y luego decide si guarda un **plan genérico**; desde ese momento el
parcial desaparece del plan sin que nada cambie en el código. Se ve con `EXPLAIN (GENERIC_PLAN)`
sobre la sentencia con `$1`, y se fuerza en los dos sentidos con `plan_cache_mode`. Se corre en
[`l01`](../13-laboratorio/l01-explain-e-indices-medidos.md#6--paso-5--el-plan-genérico-y-el-índice-parcial)
§6.

**El `OR` entre columnas distintas.** `WHERE cliente_id = 311 OR estado = 'ANULADO'` necesita **un
índice por rama**: con los dos, el motor puede combinarlos con `BitmapOr`; con uno solo, tiene que
leer la tabla entera igual, porque la otra rama podría traer cualquier fila. Con un solo índice, la
reescritura es partirla en dos y unirlas con `UNION`, pagando el `Sort` que deduplica. Se corre en
[`l01`](../13-laboratorio/l01-explain-e-indices-medidos.md#4--paso-3--el-or-entre-dos-columnas) §4.

**La colación, y el `LIKE` con prefijo.** Un índice B-tree ordena según la colación de la columna, y
`codigo LIKE 'PED-0004%'` solo se puede resolver como un rango si el orden del índice coincide con
el orden byte a byte que necesita el patrón. En una base con colación distinta de `C`, un índice
normal no sirve para `LIKE`, y hace falta declararlo con `text_pattern_ops` —o `COLLATE "C"`—. La
otra cara: ese índice ya no sirve para `ORDER BY codigo` con la colación de la base. Se corre en
[`l01`](../13-laboratorio/l01-explain-e-indices-medidos.md#5--paso-4--like-y-la-colación) §5.

**El índice que existe y no es válido.** `CREATE INDEX CONCURRENTLY` que falla deja el índice
**`indisvalid = false`**: ocupa disco, se mantiene en cada escritura y **no se usa en ninguna
consulta**. Es el peor de los cinco: paga el precio entero y no da nada. Se busca así:

```sql
SELECT c.relname, i.indisvalid, i.indisready
  FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
 WHERE NOT i.indisvalid OR NOT i.indisready;
```

```text
 relname | indisvalid | indisready 
---------+------------+------------
(0 filas)
```

- `indisvalid` en `false` es "no lo mires al planificar"; `indisready` en `false`, "no lo mantengas
  al escribir". La corrección es `DROP INDEX` y volver a crearlo.
- **Cero filas es el estado sano.** Para ver la otra salida hay que romperlo a propósito, con un
  `statement_timeout` en vez de un Ctrl-C; debajo, el error y la misma consulta recién lanzada.

```sql
SET statement_timeout = '1400ms';   -- corta la construccion a media fase
CREATE INDEX CONCURRENTLY ix_tmp_roto ON eventos_pedido (tipo);
```

```text
SET
ERROR:  canceling statement due to statement timeout

   relname   | indisvalid | indisready 
-------------+------------+------------
 ix_tmp_roto | f          | t
(1 fila)
```

- **`f` / `t` es el peor de los dos mundos**: no lo mira nadie al planificar y se mantiene en cada
  escritura. No es el único desenlace: cortando antes —`700ms` en esta misma base— sale **`f` /
  `f`**, que cuesta disco y nada más. **Decide la fase en que muere**, no el hecho de interrumpirlo.
  El teardown es la corrección: `DROP INDEX ix_tmp_roto;`, y la consulta vuelve a dar cero filas.
- **Quién lo manda:** motor, los cinco casos. **Cuánto cuestan:** el parcial y el parámetro, el
  disco del índice que no se usa; el `OR`, la tabla entera; la colación, un índice más; el inválido,
  todo el precio de escritura de §8 a cambio de nada.

> **📝 Contexto.** Aquí no se pega ningún plan del `OR`, del `LIKE` ni del plan genérico: **los tres
> se corren en vivo en `l01`**, con las cifras de §4, §5 y §6 de ese lab. El parcial está medido en
> [`03`](03-compuestos-parciales-y-de-cobertura.md) §4 y el inválido, justo arriba.

---

## 7. 🩺 Razón 6, el índice se usa y aun así pierde

**Qué es:** el plan dice el nombre del índice, la condición está en `Index Cond`, y la consulta
sigue siendo lenta. El trabajo no está en el índice: está en **la vuelta al heap**, que es lo que el
índice no puede ahorrar.

Un índice de PostgreSQL guarda la clave y un `ctid`, y **no guarda si la fila está viva**: eso lo
dice el heap. El *index-only scan* existe para evitar esa visita, y solo funciona si el *visibility
map* dice que la página entera es visible para todos. Medido en
[`03`](03-compuestos-parciales-y-de-cobertura.md) §6: un `Index Only Scan` sobre `(cliente_id,
total)` con **`Heap Fetches: 52`** de 52 filas, porque `pedidos` tiene `relallvisible = 0` de 10 770
páginas y nunca pasó por `VACUUM`.

| Lo que ves | Lo que significa | Qué se toca |
|---|---|---|
| `Index Only Scan` con `Heap Fetches` alto | El mapa de visibilidad está atrasado | `VACUUM`, no el índice |
| `Bitmap Heap Scan` con `Heap Blocks` cercano a las páginas de la tabla | Las filas están desperdigadas | El orden físico, o aceptar el barrido |
| `Bitmap Heap Scan` con `Heap Blocks: lossy` | El mapa de bits no cupo en `work_mem` | `work_mem`, o menos filas |
| `Index Scan` sobre un índice mucho mayor que su tabla | Índice hinchado por reescrituras | `REINDEX` |

- **El caso intermedio ya está medido** en [`05`](05-explain-y-explain-analyze.md) §7: 49 001 filas
  que viven en 2 253 páginas se resuelven mejor con `Bitmap Heap Scan` —12,298 ms— que con un `Index
  Scan` que visitaría el heap en orden de índice y leería la misma página muchas veces. Por eso el
  motor prefiere el mapa de bits en cuanto las filas pasan de unas pocas: **lee cada página una vez
  y en orden físico**.
- **Cuánto cuesta la vuelta al heap**, con los números del corpus: el `Index Only Scan` de 52 filas
  lee 21 páginas con el mapa atrasado y **3 con el mapa al día**. Siete veces, sobre el mismo índice
  y la misma consulta, sin tocar nada del esquema.
- **Cuándo el índice de cobertura no paga:** si añades una columna solo para cubrir, el índice se
  ensancha, entra menos por página y el árbol crece; medido en `03` §6, el de cobertura salió **tres
  páginas más caro** que el `Index Scan` equivalente, porque las visitas al heap seguían ahí.

> **Veredicto:** cuando el índice aparece y no ayuda, deja de mirar el índice y mira cuántas páginas
> del heap se tocan. `Heap Fetches` y `Heap Blocks` son las dos únicas cifras que responden a eso.

---

## 8. 🧱 Lo que cuesta un índice en escritura

**Qué es:** el otro lado del catálogo. Las seis razones explican cuándo un índice no rinde; esta
sección explica por qué un índice que no rinde no es neutro, sino que se paga en cada escritura de
la tabla. **La moneda que no depende de la caché es el registro de WAL**, y se mide con `EXPLAIN
(WAL)`.

Lo medido en [`03`](03-compuestos-parciales-y-de-cobertura.md) §7, sobre `pedidos`:

```text
100 000 INSERT, tabla sin índices propios      -> 303 976 registros de WAL, Insert 447 ms
100 000 INSERT, con dos índices encima         -> 504 640 registros de WAL, Insert 723 ms
39 905 UPDATE SET total = total + 0.01         -> 158 435 sin índice sobre `total`
39 905 UPDATE, con un índice sobre `total`     -> 200 027 con él
```

- **Dos registros más por fila, uno por índice.** No es una estimación: 504 640 menos 303 976 son
  200 664 para 100 000 filas y dos índices. Y un 62 % más de tiempo en el nodo `Insert`.
- **El `UPDATE` solo paga si toca una columna indexada**, y ahí está el matiz que casi nadie dice:
  en PostgreSQL un `UPDATE` que no toca ninguna columna indexada puede ser **HOT** —la versión nueva
  cabe en la misma página y los índices no se tocan—; en cuanto toca una, hay que escribir en todos
  los índices de la tabla, no solo en el de esa columna.
- **Lo que un índice cuesta, entero, en las cinco monedas:** disco —de 1136 kB el parcial a 31 MB el
  de cobertura, medidos—; tiempo de construcción —de 38 ms a 1 097 ms—; una escritura extra por
  `INSERT`, por `DELETE` y por cada `UPDATE` que toque sus columnas; su parte de `shared_buffers`,
  que se la quita a otro; y **concurrencia**: un `CREATE INDEX` normal bloquea las escrituras
  mientras construye, y el `CONCURRENTLY` que lo evita cuesta dos pasadas y puede dejar un índice
  inválido (§6).

> **⏱️ Coste.** La cuenta que hay que saber hacer en voz alta: **cinco índices en una tabla que
> recibe diez mil `INSERT` al minuto son 50 000 escrituras de índice al minuto**, más su WAL, más su
> replicación, más su parte de la caché. Un índice que no se usa no es gratis: es todo eso a cambio
> de nada.

---

## 9. 🧭 Particionado, y cuándo compensa

**Qué es:** partir una tabla grande en varias tablas físicas —particiones— que el motor presenta
como una sola. **No es una alternativa a los índices**, y confundirlo con eso es el error de esta
sección: cada partición lleva sus propios índices, y una consulta que no filtra por la clave de
particionado las recorre todas.

**El mecanismo que da el beneficio se llama eliminación de particiones** (*partition pruning*): si
la tabla está partida por rango de `ocurrido_en` y la consulta filtra por `ocurrido_en`, el
planificador descarta las particiones que no pueden contener filas **antes de mirar ningún índice**,
y en el plan se ve porque solo aparecen las que quedan. Si el filtro es por otra columna, no
descarta ninguna.

| Lo que el particionado arregla de verdad | Lo que no arregla |
|---|---|
| Borrar histórico: `DROP TABLE` de una partición en vez de un `DELETE` de millones de filas | Una consulta que no filtra por la clave de particionado |
| Mantenimiento por trozos: `VACUUM` y `ANALYZE` por partición, no sobre 4 100 000 filas | La selectividad del filtro, que es la razón 3 |
| Índices más pequeños, cada uno con su propio árbol | El `UNIQUE` global: solo es posible si la clave de particionado va dentro |
| Cargar y retirar datos en bloque, sin tocar el resto | Una tabla de 10 GB, donde añade complejidad y no quita trabajo |

- **Cuándo sí:** una tabla que crece sin parar por tiempo y se consulta casi siempre por tiempo
  —`eventos_pedido` es el candidato del corpus, con 4 100 000 filas—, y de la que se retira
  histórico. **Cuándo no:** como respuesta a una consulta lenta. Si el problema es una de las seis
  razones, particionar la reproduce en cada partición.
- **Lo que cuesta:** el `UNIQUE` global desaparece si la clave no está incluida; las claves foráneas
  que apuntan a una tabla particionada tienen restricciones; el planificador tiene que considerar
  todas las particiones y la planificación se alarga con el número de ellas; y **el cambio no es en
  caliente**: convertir una tabla existente en particionada es recrearla y mover los datos.
- **Aquí no se observa, y se declara.** Este corpus **no parte `eventos_pedido`**: recrearla
  cambiaría el tamaño, las estadísticas y **todos los planes pegados en el bloque**. Lo más cerca es
  [`l05`](../13-laboratorio/l05-los-otros-modelos.md#5--paso-4--timescaledb-la-tabla-partida-por-tiempo)
  §5: una hipertabla de 27 tramos por día, la exclusión de tramos y la misma regla del `UNIQUE`.

> **Veredicto:** se particiona para **operar** una tabla grande —retirar histórico, mantenerla por
> trozos—, no para acelerar una consulta. Si la frase que justifica el particionado es "va lenta",
> falta un plan por mirar.

---

## 10. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**; lo que sí es
> comprobable, y ya se dijo en [`03`](03-compuestos-parciales-y-de-cobertura.md) §8, es que **la
> norma no define índices ni planificador**. Las seis razones de este capítulo son, por tanto,
> comportamiento de motor de cabo a rabo: no hay ninguna que se pueda defender diciendo "lo manda el
> estándar".

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 / InnoDB | SQLite 3.53.4 |
|---|---|---|---|---|
| Una función sobre la columna impide usar el índice | No lo define | Sí, salvo con índice de expresión | Sí, salvo *functional key part* desde 8.0.13 | Sí, salvo índice de expresión |
| Falta el prefijo izquierdo y el índice aparece igual | No lo define | Sí, *skip scan* desde la 18 | Sí, *skip scan* desde 8.0.13 | **No**: cae a `SCAN` |
| El motor descarta el índice por selectividad | No lo define | Sí, por modelo de costes | Sí, por modelo de costes | Sí, más simple: sin coste publicado |
| Conversión implícita de tipo que tapa el índice | No lo define | Casi nunca: suele **fallar con error** en vez de convertir | **Sí, y es el caso clásico**: comparar texto con número convierte la columna | Sí: tipado por afinidad |
| Hay índices parciales, con predicado que se demuestra | No lo define | Sí | **No**: `ERROR 1064` de sintaxis | Sí |
| Se puede forzar u ocultar un índice | No lo define | No hay `hint`; se apagan métodos con `enable_*` | Sí: `FORCE INDEX`, `IGNORE INDEX`, índices invisibles | Sí: `INDEXED BY`, `NOT INDEXED` |
| Un índice puede quedar inválido y seguir ocupando disco | No lo define | Sí: `indisvalid = false` tras un `CONCURRENTLY` fallido | No de esa forma: el DDL confirma o falla | No |
| Hay particionado declarativo | No lo define | Sí, por rango, lista y hash | Sí, con límites propios | **No** |

**Convención, las tres que más se repiten.** *"Si el plan dice `Seq Scan`, falta un índice"* se
refuta con §4: 273 126 filas de 820 000 no se sacan por índice en ninguna base de datos del mundo.
*"Pon un índice por cada columna del `WHERE`"* viene de cuando los motores no combinaban índices, y
lo que produce es el precio de escritura de §8 multiplicado por columnas. Y la tercera, la más
moderna: *"el índice no se usa porque el planificador se equivocó"* — en la razón 3 el planificador
tiene razón, en la 6 el índice se usa de verdad, y en la 4 lo que está mal es el `rows=` que le
dieron, no la decisión que tomó con él.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El índice no se usa, hay que forzarlo" | En PostgreSQL no hay `hint`, y en los motores que lo tienen fuerza el plan **y la equivocación**. Primero se busca cuál de las seis razones es |
| "Si el índice sale en el plan, está funcionando" | Con *skip scan* sale y lee el 88 % de sus páginas: 190,789 ms contra los 167,704 del `Seq Scan` |
| "`creado_en::date = hoy` usa el índice de `creado_en`" | No: la columna va envuelta. La forma que lo usa es el rango `>= hoy AND < mañana`, y es gratis |
| "Un índice de más no molesta" | Medido: dos índices sobre `pedidos` pasan 100 000 `INSERT` de 303 976 a 504 640 registros de WAL y de 447 ms a 723 ms |
| "Particionar acelera las consultas" | Acelera las que filtran por la clave de particionado, por eliminación de particiones. Las demás recorren todas las particiones, con un índice por cada una |
| "El índice está creado, así que está en uso" | Un `CREATE INDEX CONCURRENTLY` fallido deja `indisvalid = false`: se mantiene en cada escritura y no se usa en ninguna consulta |
| "Con `OR` el motor usa los índices que tenga" | Necesita uno **por rama** para combinarlos con `BitmapOr`. Con uno solo, lee la tabla entera igual |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Examining Index Usage»: por qué un índice no se usa y qué
  mirar antes de crear otro. <https://www.postgresql.org/docs/18/indexes-examine.html>
- **Documentación** — PostgreSQL 18, «Operator Classes and Operator Families»: `text_pattern_ops` y
  el `LIKE` con prefijo. <https://www.postgresql.org/docs/18/indexes-opclass.html>
- **Documentación** — PostgreSQL 18, «Query Planning»: qué hacen de verdad los `enable_*` de §4, y
  `random_page_cost`. <https://www.postgresql.org/docs/18/runtime-config-query.html>
- **Documentación** — PostgreSQL 18, «Table Partitioning»: eliminación de particiones y sus límites.
  <https://www.postgresql.org/docs/18/ddl-partitioning.html>
- **Documentación** — MySQL 9.7, «Type Conversion in Expression Evaluation»: qué convierte el motor
  al comparar texto con número, que es la razón 1 en su forma de MySQL.
  <https://dev.mysql.com/doc/refman/9.7/en/type-conversion.html>
- **Referencia** — Markus Winand, *Use The Index, Luke!*, «Obfuscated Conditions»: las razones 1 y 2
  desde el lado del SQL que las provoca.
  <https://use-the-index-luke.com/sql/where-clause/obfuscation>
- **Libro** — Markus Winand, *SQL Performance Explained*, self-published, 2012, capítulo 2.

---

## 🧠 Preguntas

1. Enumera las seis razones por las que un índice existente no se usa, en una frase cada una. 🟢
2. ¿Qué línea del plan delata que la condición se evaluó sobre filas ya leídas en vez de resolverse
   bajando por el índice? 🟢
3. ¿Qué significa `Index Searches: 51` en un plan, y qué valor querrías ver? 🟢
4. ¿Qué es la eliminación de particiones, y de qué depende que ocurra? 🟢
5. Distingue la razón 3 —el filtro no es selectivo— de la razón 4 —el presupuesto está mal—, y di
   cuál de las dos es un error del motor. 🟡
6. `WHERE creado_en::date = DATE '2026-01-01'` no usa el índice sobre `creado_en`. Da la reescritura
   que sí lo usa y di qué cuesta cada una de las dos soluciones posibles. 🟡
7. ¿Qué diferencia hay entre un índice que no aparece en el plan y uno que aparece y no ayuda? Di
   qué mirarías en cada caso. 🟡
8. ¿La conversión implícita de tipos tapa el índice por igual en PostgreSQL 18.6 y en MySQL 9.7.2?
   Responde por separado y di si eso lo fija el estándar. 🟡
9. Distingue el `Heap Fetches` alto de un `Index Only Scan` del `Heap Blocks` alto de un `Bitmap
   Heap Scan`: ¿qué se toca en cada caso? 🟡
10. Un compañero quiere `FORCE INDEX` para arreglar un plan. Dale dos argumentos en contra, di qué
    tiene PostgreSQL 18.6 en su lugar, y di si el estándar dice algo sobre forzar un índice. 🟠
11. Justifica con los números de §4 por qué un índice sobre `pagos.metodo` no serviría para `WHERE
    metodo = 'EFECTIVO'`. 🟠
12. Explica por qué el índice parcial de `ANULADO` deja de usarse cuando el valor llega en un
    parámetro, y qué comando te lo confirma sin adivinar. 🟠
13. Con `(producto_id, cantidad)` y un `WHERE` solo por `cantidad`, el índice aparece en el plan y
    la consulta va más lenta que sin él. Explica el mecanismo y di cuánto, con las dos cifras. 🟠
14. Tienes una tabla con cinco índices y 10 000 `INSERT` por minuto. Haz la cuenta del coste de
    escritura y di qué moneda usarías para medirlo de verdad. 🟠
15. ¿Por qué un `UPDATE` puede no pagar nada por los índices de la tabla y otro pagar por todos? 🟠
16. Alguien propone particionar `eventos_pedido` porque un informe tarda ocho segundos. Da el
    argumento que convierte esa propuesta en una decisión, y di qué preguntarías antes. 🟠
17. Escribe la secuencia de diagnóstico completa —qué miras, en qué orden, y qué descartas en cada
    paso— para un índice que existe y no aparece en el plan. Máximo cinco pasos. 🔴
18. Un `CREATE INDEX CONCURRENTLY` se interrumpió anoche. Escribe la consulta que lo detecta, di qué
    está pagando la base ahora mismo y cuál es la corrección. 🔴
19. Este `WHERE` tiene tres razones distintas de las seis, a la vez: `WHERE lower(c.email) LIKE
    '%@ejemplo.test' OR p.estado = 'PENDIENTE'`. Nómbralas, di en qué orden las arreglarías y qué
    índices acabarías creando. 🔴
20. Diseña la sesión completa —comando a comando, sin dejar nada detrás— que demuestra que un índice
    sobre `pedidos(estado)` no compensa. Di qué comparas y qué cifra cierra el argumento. 🔴

---

**Anterior:** [`05`](05-explain-y-explain-analyze.md) · **Siguiente:**
[`07`](07-simulacion-de-entrevista.md) — las preguntas del bloque, mezcladas y con cronómetro ·
**Relacionado:** [`03`](03-compuestos-parciales-y-de-cobertura.md) — de donde salen las mediciones
de las razones 1, 2, 5 y 6 · [`04`](04-estadisticas-y-el-planificador.md) — el mecanismo de la razón
4.
