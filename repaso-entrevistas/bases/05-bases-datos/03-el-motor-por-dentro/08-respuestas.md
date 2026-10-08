# 08 — Respuestas

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

- [Capítulo 01 — Cómo se almacena una tabla](#capítulo-01--cómo-se-almacena-una-tabla)
- [Capítulo 02 — Familias de índices](#capítulo-02--familias-de-índices)
- [Capítulo 03 — Compuestos, parciales y de
  cobertura](#capítulo-03--compuestos-parciales-y-de-cobertura)
- [Capítulo 04 — Estadísticas y el planificador](#capítulo-04--estadísticas-y-el-planificador)
- [Capítulo 05 — `EXPLAIN` y `EXPLAIN ANALYZE`](#capítulo-05--explain-y-explain-analyze)
- [Capítulo 06 — Cuándo el índice no se usa](#capítulo-06--cuándo-el-índice-no-se-usa)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — Cómo se almacena una tabla

Las 17 preguntas de [`01`](01-como-se-almacena-una-tabla.md).

**01 → 1.** ¿De qué tamaño es una página en PostgreSQL 18.6, en MySQL 9.7.2 y en SQLite 3.53.4? 🟢

⏱️ **30 segundos** — Ocho kilobytes en PostgreSQL, dieciséis en InnoDB y cuatro en SQLite.

🗣️ **2 minutos** — En PostgreSQL lo dice `SHOW block_size` y vale 8192; se fija al compilar el
motor, así que no se cambia sin recompilar. En MySQL lo dice `innodb_page_size`, vale 16384 y sí es
configurable al inicializar la instancia. En SQLite lo dice `pragma page_size`, vale 4096 y se puede
cambiar por base antes de escribir nada. La página es la unidad de E/S, de caché y de bloqueo de
búfer en los tres.

🔬 **El detalle** — **Motor puro.** El estándar no define almacenamiento, así que ningún tamaño de
página sale de ISO/IEC 9075. El número importa porque es la unidad en la que se mide todo lo demás:
`pedidos` son 10 770 páginas de 8 kB en PostgreSQL, y esas mismas 10 770 aparecen como `Buffers:
shared hit=1587 read=9183` en el `EXPLAIN` de un `Seq Scan`.

---

**01 → 2.** ¿Qué guarda un `ctid`, y qué es cada una de sus dos partes? 🟢

⏱️ **30 segundos** — El par (número de página, número de puntero de línea dentro de la página): la
dirección física de esa versión de la fila.

🗣️ **2 minutos** — La primera parte es el bloque dentro del fichero de la tabla, contando desde
cero; la segunda es la posición dentro del vector de punteros de línea de esa página. `PED-00042`
está en `(10769,20)`, o sea la página 10 769 y el vigésimo puntero. Es una columna de sistema que
existe en toda tabla sin declararla, y es lo único que un índice de PostgreSQL guarda para volver al
`heap`.

🔬 **El detalle** — Ocupa 6 bytes y **no es un identificador**: cambia con cada `UPDATE`, con `VACUUM
FULL` y con cualquier reorganización. Medido: un `UPDATE` sobre `PED-00042` dentro de `BEGIN …
ROLLBACK` lo movió de `(10769,20)` a `(10769,21)`. En InnoDB no hay equivalente expuesto y en SQLite
el papel lo hace el `rowid`, que sí es estable.

---

**01 → 3.** `pedidos` ocupa 10 770 páginas para un millón de filas: haz la aritmética desde los 8
192. 🟢

⏱️ **30 segundos** — De los 8 192 bytes se van 24 de cabecera; cada fila cuesta 4 de puntero más 84
de tupla; caben 92,8 por página, y un millón entre 92,8 da 10 770.

🗣️ **2 minutos** — Los 24 bytes son la cabecera de página. Los 4 son el puntero de línea, que vive
en el vector que crece desde arriba. Los 84 son el ancho medio real de la tupla, medido con
`heap_page_items` sobre una página concreta: en la 500 hay 93 filas con `lp_len` entre 80 y 88 y
media 84. Y `reltuples/relpages` del catálogo da 93, que es el mismo número por el otro camino.

🔬 **El detalle** — Lo que mueve esa densidad es el ancho medio de la fila, el `fillfactor` —100 por
defecto en PostgreSQL— y el espacio muerto que dejan `UPDATE` y `DELETE` hasta que `VACUUM` lo
recicla. Lo que **no** la mueve es cuántas columnas pide el `SELECT`: la unidad de lectura es la
página entera, y por eso leer una fila cuesta lo mismo que leer las 93 que la acompañan.

---

**01 → 4.** ¿Qué es el `heap` y qué orden tienen las filas dentro de él? 🟢

⏱️ **30 segundos** — Es el fichero donde PostgreSQL amontona las páginas de la tabla, y las filas no
tienen ningún orden: están donde cayeron.

🗣️ **2 minutos** — El nombre describe el contenido: un montón. Una fila nueva va al primer hueco
donde quepa, y una fila actualizada se reescribe donde haya sitio, no en su posición anterior. Por
eso los índices de PostgreSQL son estructuras separadas que apuntan al `heap` por `ctid`. En InnoDB
no hay `heap`: la tabla vive dentro del índice primario y está ordenada por la clave.

🔬 **El detalle** — Medido: cien claves consecutivas de `pedidos` —`id` de 1 a 100— viven en **89
páginas distintas**, casi una por fila. La causa es que la semilla inserta en orden y después
actualiza `total` desde las líneas, y ese `UPDATE` reescribió el millón. La métrica que lo resume es
la correlación de `pg_stats`: `0,2225301` para `pedidos.id`, cuando una tabla recién cargada y sin
tocar valdría 1.

---

**01 → 5.** ¿Qué es TOAST y cuáles son sus dos pasos, en orden? 🟢

⏱️ **30 segundos** — Es el almacén fuera de línea de PostgreSQL: primero comprime el valor ancho, y
solo si la fila sigue sin caber lo mueve a una tabla lateral dejando un puntero.

🗣️ **2 minutos** — Las siglas son *The Oversized-Attribute Storage Technique*. Se dispara porque una
fila no puede cruzar el borde de una página de 8 kB. El umbral es `TOAST_TUPLE_THRESHOLD`, unos 2
000 bytes, y se mide sobre **la fila completa**, no sobre la columna. Toda tabla con al menos una
columna de ancho variable nace con su tabla TOAST, aunque quede vacía para siempre.

🔬 **El detalle** — El orden de los dos pasos es lo que casi nadie dice, y se ve midiendo. Doce mil
caracteres repetidos comprimen a **162 bytes** y la fila se queda en línea con 224. Los mismos 12
009 caracteres de ruido `md5`, que no comprime, se van fuera y se parten en **9 trozos** de ~2 kB en
la tabla lateral; la fila se queda en 80 bytes, que es el puntero. Leer ese valor pasa a costar dos
accesos: la página del `heap` y los trozos por el índice de la TOAST.

---

**01 → 6.** Distingue `relpages` de `reltuples`: ¿cuál es exacto, cuál estimado, y por qué? 🟡

⏱️ **30 segundos** — `relpages` es exacto —el tamaño del fichero entre 8 192—; `reltuples` es una
estimación que dejó el último `ANALYZE`.

🗣️ **2 minutos** — `relpages` no se calcula: el motor sabe cuántos bloques tiene el fichero. Contar
filas, en cambio, exigiría recorrer la tabla entera, porque en PostgreSQL no hay un contador de
filas vivas —es consecuencia de MVCC: cuántas filas hay depende de qué transacción pregunta—. Por
eso `ANALYZE` muestrea y deja una estimación en el catálogo. En `pedidos` coincide con el millón
exacto porque los datos no se han movido desde la carga.

🔬 **El detalle** — **Motor.** La misma distinción aparece en MySQL con más violencia:
`information_schema.TABLES.TABLE_ROWS` dio **996 132** en lugar de 1 000 000, porque en InnoDB es
una estimación muestreada del índice primario y puede desviarse bastante. Es la razón por la que
`SELECT count(*)` es caro en PostgreSQL e InnoDB y era gratis en MyISAM, que sí llevaba contador
—pero a cambio no tenía transacciones—.

---

**01 → 7.** La suma por columna de `PED-00042` da 48 y la fila mide 80. Reparte los 32 bytes que
faltan. 🟡

⏱️ **30 segundos** — Veinticuatro de cabecera y ocho de relleno de alineación.

🗣️ **2 minutos** — La cabecera son los 23 bytes de `HeapTupleHeaderData` —identificadores de
transacción, puntero a la versión siguiente, bits de estado— más un byte de mapa de nulos,
redondeados al múltiplo de 8. `pageinspect` lo confirma: `t_hoff` vale 24 en cada fila de la tabla.
El relleno sale de que cada tipo tiene que empezar en una dirección múltiplo de su alineación:
`codigo` acaba en el byte 42 y `cliente_id` es `bigint`, así que se pierden 6 hasta el 48; `total` y
`creado_en` pierden uno cada uno.

🔬 **El detalle** — Esos 8 bytes son el 10 % de la fila, y dependen del **orden de declaración**.
Medido sin crear nada: `pg_column_size(ROW(bigint, smallint, bigint, smallint))` da 50 y la misma
lista agrupada de mayor a menor da 44 —un 13,6 % menos—. Es territorio de motor, no de estándar: la
regla es la alineación de la plataforma, que está en `pg_attribute.attalign` como `d` (8), `i` (4),
`s` (2) y `c` (1).

---

**01 → 8.** ¿Que la clave primaria decida dónde se guarda la fila lo fija el estándar o el motor? Di
qué hace cada uno de los tres. 🟡

⏱️ **30 segundos** — Lo fija el motor. El estándar define `PRIMARY KEY` como restricción lógica
—unicidad más no nulo— y no dice nada del almacenamiento.

🗣️ **2 minutos** — En PostgreSQL la clave primaria no decide nada: `pedidos_pkey` es un índice más,
de 21 MB, al lado de un `heap` de 84 MB sin orden. En InnoDB la clave primaria **es** la tabla: las
filas viven en las hojas de ese índice y están físicamente ordenadas por ella. En SQLite depende:
una columna `INTEGER PRIMARY KEY` se convierte en alias del `rowid` y sí manda; cualquier otra clave
no manda, salvo que declares la tabla `WITHOUT ROWID`.

🔬 **El detalle** — Es la respuesta que distingue a quien leyó el manual de quien recitó la
convención. La prueba en números: en MySQL `DATA_LENGTH` de `pedidos` y el índice `PRIMARY` dan
**los dos 71 MB**, porque son la misma estructura; en PostgreSQL son 84 MB de `heap` **más** 21 de
índice. Si no declaras clave primaria, InnoDB se inventa una oculta de 6 bytes y PostgreSQL
simplemente no tiene ninguna.

---

**01 → 9.** `eventos_pedido` pesa 641 MB y tiene tabla TOAST, pero vacía. ¿Es contradictorio? 🟡

⏱️ **30 segundos** — No. La tabla TOAST existe por el **tipo** de las columnas; se llena por el
**ancho** de los valores, y aquí ninguno llega al umbral.

🗣️ **2 minutos** — PostgreSQL crea `pg_toast_…` en cuanto la tabla tiene al menos una columna de
ancho variable, aunque nunca guarde nada. Los 4,1 millones de `carga` de `eventos_pedido` miden
entre 89 y 105 bytes, con media 98: están a veinte veces del umbral de ~2 kB. Los 641 MB son heap
puro, y lo que separa esa cifra de los 729 MB de `pg_total_relation_size` son los dos índices de la
tabla, no TOAST.

🔬 **El detalle** — De ahí el error de diagnóstico que hay que evitar: **que `pg_total_relation_size`
supere a `pg_relation_size` no es señal de valores fuera de línea**. Para saberlo hay que mirar
`pg_relation_size(reltoastrelid)`, que aquí daba 0 bytes en `pedidos`, `clientes` y
`eventos_pedido`. Y un aviso de laboratorio: tras meter valores grandes en una transacción que luego
revierte, la TOAST **conserva las páginas que reservó** —quedan muertas hasta que pase `VACUUM`—.

---

**01 → 10.** Cien claves consecutivas viven en 89 páginas distintas: explica por qué, sabiendo cómo
se cargó la tabla, y di qué métrica del catálogo lo resume. 🟠

⏱️ **30 segundos** — Porque la semilla actualizó `total` después de insertar, y ese `UPDATE`
reescribió el millón de filas en el primer hueco libre de cada momento. Lo resume la correlación de
`pg_stats`.

🗣️ **2 minutos** — En PostgreSQL un `UPDATE` no modifica la fila: escribe una versión nueva. La
carga inserta el millón de pedidos en orden de `id` —y por eso `PED-00042` es de verdad el `id` 42—,
pero luego calcula `total` desde `pedido_lineas` con un `UPDATE` masivo que reubica todo. El
resultado es que el `id` 42 acabó en la última página de la tabla, la 10 769, y los `id` 100 a 105
en las páginas 239, 391, 388, 251, 335 y 435.

🔬 **El detalle** — La métrica es `pg_stats.correlation`, que vale **0,2225301** para `pedidos.id`.
Va de −1 a 1 y mide cuánto se parece el orden lógico de la columna al orden físico de las filas. El
planificador la usa para decidir entre `Index Scan` y `Bitmap Heap Scan`, porque con correlación
baja una búsqueda por rango toca casi una página por fila; es tema de `03/04`. Y es también la razón
de ser de los índices BRIN, que solo sirven con correlación alta.

---

**01 → 11.** En InnoDB el índice sobre `codigo` mide 38 MB y en PostgreSQL 30, con las mismas filas:
¿por qué? 🟠

⏱️ **30 segundos** — Porque cada entrada carga algo distinto: en PostgreSQL el `ctid`, 6 bytes; en
InnoDB la clave primaria entera, aquí los 8 de un `BIGINT`.

🗣️ **2 minutos** — Como InnoDB guarda la tabla dentro del índice primario, la fila se mueve cuando
la clave se reorganiza, así que un índice secundario **no puede** apuntar a una dirección de disco:
apunta a la clave primaria y vuelve a bajar por el índice agrupado. PostgreSQL sí apunta a una
dirección, el `ctid`, y por eso su entrada es más estrecha. El precio se paga en el otro lado: en
InnoDB buscar por un secundario cuesta dos descensos de árbol, en PostgreSQL uno más un salto al
`heap`.

🔬 **El detalle** — En este caso la diferencia son 2 bytes por entrada y la página de 16 kB contra la
de 8, así que el 27 % extra es modesto. Se vuelve grave con claves anchas, y está medido en el mismo
esquema: `pagos.fk_pagos_pedido`, colgando de una clave de 8 bytes, pesa **23 bytes por fila**;
`pedido_lineas.fk_lineas_producto`, colgando de la compuesta `(pedido_id, linea)`, pesa **39,5 bytes
por fila** —un 70 % más— indexando exactamente la misma clase de columna.

---

**01 → 12.** Un compañero propone `UUIDv4` en `CHAR(36)` como clave primaria en MySQL. Dale las
**dos** facturas que va a pagar, con el mecanismo de cada una. 🟠

⏱️ **30 segundos** — Espacio en todos los índices secundarios, porque cada uno guarda la clave
entera; y páginas partidas en las escrituras, porque un UUID aleatorio inserta en medio de una tabla
ordenada.

🗣️ **2 minutos** — Primera factura, espacio: cada entrada de cada índice secundario pasa de cargar 8
bytes a cargar 36. Con tres índices y tres millones de filas son cientos de megabytes nuevos, y ese
volumen se traduce en más páginas leídas en cada consulta que use esos índices. Segunda factura,
escritura: en InnoDB las filas están físicamente ordenadas por la clave primaria, así que un valor
aleatorio cae en medio de una página ya llena, la parte en dos y deja las dos a medio llenar. Un
entero creciente siempre escribe al final y nunca parte nada.

🔬 **El detalle** — Las dos salidas honestas: `BINARY(16)` en lugar de `CHAR(36)` mata la mitad de la
primera factura —16 bytes en vez de 36—, y **UUIDv7**, que lleva la marca de tiempo en los bits
altos y por tanto es creciente, mata la segunda. Y el matiz de categoría: nada de esto aplica en
PostgreSQL, donde el `heap` no está ordenado y los índices apuntan por `ctid`; ahí un UUIDv4 cuesta
espacio en el índice, pero no parte páginas de la tabla.

---

**01 → 13.** ¿Por qué 12 009 caracteres repetidos se quedan en la página y 2 113 de ruido se van
fuera? 🟠

⏱️ **30 segundos** — Porque TOAST comprime antes de mover, y lo repetido comprime: los 12 009
caracteres quedaron en 162 bytes, muy por debajo del umbral.

🗣️ **2 minutos** — El orden de los dos pasos es lo que decide. Un `jsonb` con doce mil `x` seguidas
se reduce a 162 bytes y la fila entera ocupa 224 en la página: ni se plantea salir. El ruido de
`md5` es incompresible, así que 2 113 bytes siguen siendo 2 113 después de comprimir, la fila se
pasa del umbral y el valor se va a la tabla lateral dejando la fila en 80 bytes. El corte está justo
ahí: 1 917 bytes se quedan dentro —la fila mide 1 984—, 2 113 se van fuera.

🔬 **El detalle** — `TOAST_TUPLE_THRESHOLD` son unos **2 000 bytes** y se mide sobre la **fila
completa**, no sobre la columna: dos `text` de 1 200 bytes cada uno disparan TOAST aunque ninguno lo
haga por sí solo. La consecuencia de diseño es que el tipo de la columna no predice nada; lo que
predice es el ancho real de los datos y cuánto comprimen. Se controla por columna con `ALTER TABLE …
SET STORAGE`, que admite `PLAIN`, `MAIN`, `EXTERNAL` y `EXTENDED`.

---

**01 → 14.** ¿Que un `UPDATE` reescriba la fila en otra posición lo manda el estándar o es del
motor? Di qué consecuencia tiene para los índices de esa tabla. 🟠

⏱️ **30 segundos** — Es del motor: el estándar no dice nada de almacenamiento. En PostgreSQL un
`UPDATE` es un `INSERT` más un marcado de la versión vieja, y cada índice tiene que apuntar a la
dirección nueva.

🗣️ **2 minutos** — Como el índice guarda `ctid` y el `ctid` cambió, en principio hay que insertar
una entrada nueva en **todos** los índices de la tabla, aunque el `UPDATE` no tocara ninguna de sus
columnas. De ahí salen las dos facturas del modelo: espacio muerto que hay que reciclar con
`VACUUM`, y escrituras de índice que no pediste. En InnoDB el `UPDATE` se hace en su sitio siempre
que quepa, y los índices secundarios ni se enteran, porque apuntan a la clave primaria y esa no
cambió.

🔬 **El detalle** — PostgreSQL tiene una mitigación llamada **HOT** (*heap-only tuple*): si la nueva
versión cabe en la misma página y el `UPDATE` no toca ninguna columna indexada, se encadena dentro
de la página y **no se toca ningún índice**. Por eso dejar la tabla con `fillfactor` 100 —el
defecto— hace más probable que no quepa y se pierda la optimización. Medido en el capítulo: el
`UPDATE` sobre `PED-00042` fue de `(10769,20)` a `(10769,21)`, misma página. El mecanismo completo
de versiones es MVCC, del bloque 04.

---

**01 → 15.** Escribe el DDL de `pedido_lineas` reordenando las columnas para minimizar el relleno de
alineación en PostgreSQL, y justifica el orden tipo por tipo. 🔴

⏱️ **30 segundos** — Primero lo de alineación 8, luego lo de 4, luego lo de 2, y lo de ancho
variable al final: `pedido_id`, `producto_id`, `cantidad`, `linea`, `precio_unit`.

🗣️ **2 minutos** — El DDL queda así, con la clave compuesta intacta:

```sql
CREATE TABLE pedido_lineas (
  pedido_id    bigint   NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,  -- align 8
  producto_id  bigint   NOT NULL REFERENCES productos(id),                  -- align 8
  cantidad     integer  NOT NULL CHECK (cantidad > 0),                      -- align 4
  linea        smallint NOT NULL,                                           -- align 2
  precio_unit  numeric(12,2) NOT NULL,                                      -- ancho variable
  PRIMARY KEY (pedido_id, linea)
);
```

Los dos `bigint` van juntos al principio porque exigen empezar en múltiplo de 8 y, puestos después
de algo estrecho, obligarían a rellenar hasta 6 bytes. `cantidad` es `integer` y encaja sin hueco a
continuación. `linea` es `smallint` y cierra la parte fija. `precio_unit` es `numeric`, de ancho
variable, y va al final porque no impone alineación al resto.

🔬 **El detalle** — El orden de las columnas de la `PRIMARY KEY` **no cambia** al reordenar la
declaración: siguen siendo `(pedido_id, linea)`, que es lo que decide qué consultas usa el índice.
Son dos cosas independientes y se confunden a menudo. El ahorro se comprueba antes de migrar con
`pg_column_size(ROW(...))` —en el capítulo, 44 contra 50 bytes en un caso equivalente—, y si la
tabla ya existe, reordenar exige reescribirla entera, así que solo se hace en una tabla nueva o en
una migración que ya la iba a reescribir. Y es **motor**: el estándar no fija orden físico de bytes.

---

**01 → 16.** Te dan una tabla de 200 GB donde cada fila trae un `jsonb` de 40 kB y los informes
tardan. Escribe la secuencia de diagnóstico —qué consultas corres y en qué orden— y las dos
hipótesis de almacenamiento que confirmarías. 🔴

⏱️ **30 segundos** — Primero separo heap de TOAST de índices, luego mido el ancho real de la
columna, y con eso decido si el problema es que la tabla está gorda o que cada fila cuesta dos
accesos.

🗣️ **2 minutos** — La secuencia, en orden:

```sql
-- 1. Repartir los 200 GB: ¿heap, TOAST o índices?
SELECT pg_size_pretty(pg_relation_size(c.oid))            AS heap,
       pg_size_pretty(pg_relation_size(c.reltoastrelid))  AS toast,
       pg_size_pretty(pg_indexes_size(c.oid))             AS indices,
       c.relpages, c.reltuples::bigint
  FROM pg_class c WHERE c.relname = '<tabla>';

-- 2. ¿Cuánto ocupa de verdad el jsonb, y cuánto comprime?
SELECT min(pg_column_size(carga)), round(avg(pg_column_size(carga))),
       max(pg_column_size(carga)), round(avg(length(carga::text)))
  FROM <tabla> TABLESAMPLE SYSTEM (0.1);

-- 3. ¿El informe toca la columna gorda? El plan lo dice.
EXPLAIN (ANALYZE, BUFFERS) <la consulta del informe>;
```

Con eso ya sé si el informe lee la columna o no, y cuántas páginas de heap contra cuántas de TOAST
está tocando.

🔬 **El detalle** — Las dos hipótesis, en orden de probabilidad. **Una:** el `jsonb` comprime mal,
todo está fuera de línea, y cada fila que toca esa columna paga dos accesos —heap más trozos por el
índice de la TOAST—; se confirma porque el tamaño de la TOAST domina y el plan muestra muchos
buffers. La corrección es no seleccionar la columna en los informes que no la necesitan, o extraer a
columnas propias los tres campos que sí se filtran. **Dos:** el `jsonb` comprime bien y se quedó en
línea; entonces el heap está gordo, caben poquísimas filas por página, y **cualquier** consulta paga
—hasta un `count(*)`—; se confirma porque `relpages/reltuples` da una densidad ridícula y la TOAST
está casi vacía. La corrección es sacar la columna a una tabla aparte, o forzar `ALTER TABLE … ALTER
carga SET STORAGE EXTERNAL` para que salga siempre y la tabla principal adelgace.

---

**01 → 17.** Diseña la demostración que le harías a un entrevistador, en menos de tres minutos y sin
dejar nada creado, de que en PostgreSQL un `UPDATE` mueve la fila: las sentencias exactas y qué
salida esperas. 🔴

⏱️ **30 segundos** — Abro una transacción, leo el `ctid` de `PED-00042`, lo actualizo, lo vuelvo a
leer y hago `ROLLBACK`: el `ctid` cambia y después vuelve.

🗣️ **2 minutos** — Las sentencias, tal cual:

```sql
BEGIN;
SELECT ctid, id, estado FROM pedidos WHERE codigo = 'PED-00042';   -- (10769,20) | 42 | PAGADO
UPDATE pedidos SET estado = 'ENVIADO' WHERE codigo = 'PED-00042';  -- UPDATE 1
SELECT ctid, id, estado FROM pedidos WHERE codigo = 'PED-00042';   -- (10769,21) | 42 | ENVIADO
ROLLBACK;
SELECT ctid, id, estado FROM pedidos WHERE codigo = 'PED-00042';   -- (10769,20) | 42 | PAGADO
```

El puntero de línea pasa de 20 a 21 y vuelve a 20 tras deshacer. La transacción es lo que hace la
demostración segura: no deja nada en la base y no molesta a nadie más, porque las versiones nuevas
mueren con el `ROLLBACK`.

🔬 **El detalle** — Tres cosas que suman nota. **Una:** advertir que el `ctid` puede quedarse en la
misma página —como aquí— o saltar a otra si no cabe, y que eso depende del espacio libre y del
`fillfactor`. **Dos:** decir que si el `UPDATE` no tocara ninguna columna indexada y cupiera en la
página, PostgreSQL podría hacerlo **HOT** y no tocar ningún índice. **Tres:** nombrar el límite
honesto de la demostración —el `ctid` viejo sigue ocupando sitio hasta que pase `VACUUM`, y eso ya
es MVCC, del bloque 04—. Si el entrevistador pide verlo por dentro, `CREATE EXTENSION pageinspect`
dentro de la misma transacción enseña los `lp_len` y los `t_hoff`, y desaparece con el `ROLLBACK`
porque el DDL de PostgreSQL es transaccional.

---

## Capítulo 02 — Familias de índices

Las 15 preguntas de [`02`](02-familias-de-indices.md).

**02 → 1.** Nombra las cinco familias que cubre este capítulo y di en una frase qué estructura es
cada una. 🟢

⏱️ **30 segundos** — B-tree, un árbol ordenado; hash, una tabla de dispersión; GIN, un índice
invertido; GiST, un árbol de predicados que cubren regiones; y BRIN, el mínimo y el máximo de cada
tramo de páginas.

🗣️ **2 minutos** — El B-tree guarda los valores ordenados en las hojas y las encadena, así que bajar
cuesta la altura del árbol y seguir en orden no cuesta nada. El hash calcula `hash(valor)`, eso da
un cubo, y en el cubo están los punteros: no hay orden porque la dispersión lo destruye a propósito.
El GIN parte cada valor en elementos —las parejas clave-valor de un `jsonb`, las palabras de un
`tsvector`— y guarda una entrada por elemento con la lista de filas. El GiST es un árbol donde cada
nodo interno guarda un predicado que cubre a todos sus hijos: una caja que contiene cajas. El BRIN
no sabe dónde está nada; guarda el mínimo y el máximo de cada grupo de 128 páginas consecutivas y
solo sabe decir "en este tramo seguro que no está".

🔬 **El detalle** — **Motor puro: el estándar SQL no dice nada de familias de índice**, ni siquiera
define `CREATE INDEX`. `SELECT amname FROM pg_am WHERE amtype='i'` da **seis** en PostgreSQL 18.6
—`brin`, `btree`, `gin`, `gist`, `hash` y `spgist`—; SPGiST queda fuera del capítulo por ser la
variante particionada de GiST. Y cada forma trae su precio, medido sobre el corpus: el B-tree de
`pedidos(cliente_id)` cuesta 7,6 MB y 169 ms de construcción; su hash, 32 MB y 1 050 ms; el GIN de
`eventos_pedido(carga)`, 85 MB y 5,8 s más un coste alto por escritura; el BRIN de
`eventos_pedido(pedido_id)`, 40 kB y 173 ms. GiST no se midió aquí y se declara.

---

**02 → 2.** ¿Qué operador responde un índice hash, y cuáles no? 🟢

⏱️ **30 segundos** — Solo `=`. Ni `<`, ni `>`, ni `BETWEEN`, ni `ORDER BY`, ni `LIKE 'pre%'`.

🗣️ **2 minutos** — No es que el planificador los descarte por coste: **el método de acceso hash solo
declara el operador `=`**, así que para `>=` o `<=` el índice ni siquiera es candidato. Medido: con
el hash creado sobre `pedidos(cliente_id)`, el `BETWEEN 4210 AND 4260` vuelve a `Seq Scan` con `Rows
Removed by Filter: 998982`, 41,467 ms y 10 770 páginas, mientras el B-tree lo resuelve en 1,289 ms y
979 páginas. Y el `ORDER BY cliente_id LIMIT 10` cae a `Seq Scan` + `Sort` con `top-N heapsort`:
130,631 ms contra los 0,034 ms del B-tree, 3 842 veces.

🔬 **El detalle** — Para la igualdad pura el hash gana por un pelo, porque no baja por ningún árbol:
0,070 ms contra 0,118 ms, con las mismas 31 páginas. No compensa. **El precio:** 32 MB contra 7,6
MB, 4,2 veces más grande, y 1 050 ms de construcción contra 169 ms; es estructural, porque el B-tree
comparte prefijo entre vecinos y se compacta mientras el hash reserva cubos de tamaño fijo. El único
caso defendible es una columna **larga** consultada solo por igualdad —una URL, un texto de cientos
de bytes—, donde el hash guarda 32 bits por fila. Y **contexto**: *"los índices hash de PostgreSQL
no son seguros"* describe un motor anterior a **PostgreSQL 10, de octubre de 2017**; desde entonces
van al WAL y se replican.

---

**02 → 3.** ¿Qué guarda un BRIN por cada grupo de páginas, y por qué eso lo hace tan pequeño? 🟢

⏱️ **30 segundos** — El mínimo y el máximo de cada grupo de 128 páginas consecutivas; como no guarda
una entrada por fila sino dos valores por tramo, cabe en kilobytes.

🗣️ **2 minutos** — La aritmética lo explica sola: `eventos_pedido` son 82 017 páginas, que en tramos
de 128 dan unos 641 resúmenes. Por eso el BRIN sobre `pedido_id` ocupa **40 kB** mientras el B-tree
equivalente ocupa **51 MB**: mil trescientas veces más grande para responder el mismo rango. Lo que
el BRIN no puede hacer es ir a la fila: solo descarta tramos, y el motor recomprueba fila por fila
todo lo que quedó dentro. Por eso el plan siempre es un `Bitmap Heap Scan` con `Rows Removed by
Index Recheck`.

🔬 **El detalle** — **Motor.** El tamaño del tramo es el parámetro `pages_per_range`, 128 por defecto
en PostgreSQL. **El precio:** 40 kB de espacio y 173 ms de construcción sobre cuatro millones de
filas —contra 645 ms del B-tree—, y casi nada por escritura mientras se inserte al final, porque
solo hay que ampliar el min/max del último tramo. Lo que sí es caro es el `UPDATE` fuera de orden:
ensancha el rango de un tramo y el índice pierde poder de descarte sin que nadie avise.

---

**02 → 4.** ¿Qué significa que un GIN sea un índice "invertido"? 🟢

⏱️ **30 segundos** — Que en vez de una entrada por fila guarda una entrada por **elemento** del
valor, con la lista de filas en las que aparece.

🗣️ **2 minutos** — *Generalized Inverted Index*: el valor se parte antes de indexarse. En un `jsonb`
los elementos son las parejas clave-valor; en un `tsvector`, las palabras. Por eso responde "¿cuál
de estos documentos contiene esto?", que es lo que pregunta el operador `@>` —contención, *"el
documento de la izquierda contiene al de la derecha"*—. Un B-tree no puede ni plantearse esa
pregunta, porque indexa el documento entero como un valor opaco y solo sabe compararlo completo
contra otro completo. Medido sobre `eventos_pedido`: sin índice, `@>` es un `Seq Scan` de 82 017
páginas y 596,011 ms; con GIN, 137,793 ms.

🔬 **El detalle** — La mejora es de solo **4,3 veces**, muy lejos del 370× del B-tree, y el plan dice
por qué: el `Bitmap Index Scan` resuelve las 20 295 filas en 72 ms leyendo 3 860 páginas de índice,
pero esas filas están repartidas por **16 828 páginas del heap**. El índice hizo su trabajo; lo caro
es recoger las filas. **El precio:** 85 MB —un 13 % de los 641 MB de la tabla— y 5,8 s de
construcción con `maintenance_work_mem=256MB`; y es **caro de actualizar**, porque un `INSERT` no
añade una entrada sino tantas como elementos tenga el documento. PostgreSQL lo amortigua con la
lista pendiente (`fastupdate`, activa por defecto): inserción barata casi siempre y muy cara cuando
toca vaciarla. La variante `jsonb_path_ops` baja a **60 MB y 2,2 s** a cambio de servir solo para
`@>`.

---

**02 → 5.** `Index Cond` o `Filter`: ¿cuál usa el índice? ¿Lo fija el estándar o es cosa del motor?
🟡

⏱️ **30 segundos** — `Index Cond` es la condición que resuelve el índice; `Filter` es la que se
evalúa fila por fila después de traerlas. Solo la primera usa el índice.

🗣️ **2 minutos** — La señal que acompaña al `Filter` es `Rows Removed by Filter`: el motor leyó esas
filas y las tiró. En el `Seq Scan` de `pedidos WHERE cliente_id = 4210` dice `Rows Removed by
Filter: 999975` para devolver 25 filas, y cuesta 10 770 páginas y 43,684 ms. Con el B-tree creado,
ese mismo predicado aparece como `Index Cond: (cliente_id = 4210)`, desaparece el `Rows Removed by
Filter` y la consulta baja a 31 páginas y 0,118 ms. Es la diferencia entre *leer todo y descartar* y
*ir directo*.

🔬 **El detalle** — **Motor: es vocabulario de `EXPLAIN` de PostgreSQL**, no del estándar. Un
predicado puede quedarse en `Filter` aun habiendo índice, y ese es el error caro con `jsonb`: con el
GIN creado, `WHERE carga->>'origen' = 'callcenter'` sigue dando `Seq Scan` y **518,021 ms** medidos.
Hay un tercer apellido que conviene no confundir: `Recheck Cond` en un `Bitmap Heap Scan`, que no es
que el índice fallara, sino que el bitmap es aproximado; cuando además es `lossy`, el recheck es el
que hace de verdad el filtrado.

---

**02 → 6.** ¿Por qué el GIN de §4 no acelera `carga->>'origen' = 'callcenter'` si la columna es la
misma? 🟡

⏱️ **30 segundos** — Porque el índice no indexa la columna, indexa una **clase de operadores**, y
`->>` no está en ella: devuelve texto, no `jsonb`.

🗣️ **2 minutos** — El GIN sobre `carga` sabe responder `@>` y los operadores de existencia de clave,
porque son los que su clase de operadores declara. `carga->>'origen'` es una **expresión** que
produce `text`, y ninguna entrada del índice contiene ese texto como valor indexado: el índice
guarda parejas clave-valor del documento, no el resultado de extraer una clave. Medido: con el GIN
creado, esa consulta sigue en `Seq Scan` y **518,021 ms**. Lo que sí la acelera es un índice de
expresión sobre `(carga->>'origen')`, que es un B-tree corriente y es material de `03`.

🔬 **El detalle** — **Motor.** Es la versión concreta de una regla general: el planificador solo usa
un índice si el operador del `WHERE` pertenece a la clase de operadores del índice. La misma regla
explica por qué el hash ignora `BETWEEN` y por qué GiST falla sobre `timestamptz`. **El precio de
equivocarse aquí** es el peor de todos: pagas los 85 MB y los 5,8 s del GIN, pagas la escritura
extra en cada `INSERT`, y la consulta sigue tardando medio segundo. Un índice que no se usa es coste
puro.

---

**02 → 7.** Distingue `Heap Blocks: exact=` de `Heap Blocks: lossy=`: ¿qué implica cada uno para el
recheck? 🟡

⏱️ **30 segundos** — `exact` significa que el bitmap guarda filas concretas; `lossy`, que solo
guarda páginas enteras, así que el motor tiene que recomprobar todas las filas de esas páginas.

🗣️ **2 minutos** — El `Bitmap Index Scan` construye un mapa de bits de las filas candidatas.
Mientras cabe en `work_mem` es exacto; cuando no cabe, o cuando el índice solo sabe hablar de tramos
—el caso del BRIN—, el mapa degrada a páginas. Los dos planes del capítulo lo enseñan en la misma
tabla: el GIN da `Heap Blocks: exact=16828` y no aparece ningún `Rows Removed by Index Recheck`; el
BRIN forzado sobre `ocurrido_en` da `Heap Blocks: lossy=82017` —las 82 017 páginas de la tabla, o
sea todas— con `Rows Removed by Index Recheck: 4071472`.

🔬 **El detalle** — **Motor: `Rows Removed by Index Recheck` solo aparece en la rama lossy**, y es el
número que mide cuánto trabajo no hizo el índice. Por eso es la métrica de diagnóstico de un BRIN:
si el `lossy=` se parece al total de páginas de la tabla, no está descartando nada. Y lossy no es
sinónimo de inútil: el BRIN sobre `pedido_id`, con correlación 1, da `Heap Blocks: lossy=128` de 82
017 —descarta el 99,8 % del disco— y aun con 4 347 filas de recheck baja de 218,960 ms a **1,478
ms**.

---

**02 → 8.** ¿Las familias de índice las fija el estándar SQL o cada motor? Di qué tiene PostgreSQL
18.6, qué tiene MySQL 9.7.2 con InnoDB y qué tiene SQLite 3.53.4. 🟡

⏱️ **30 segundos** — Cada motor. El estándar SQL no dice nada de familias de índice: ni siquiera
define `CREATE INDEX`.

🗣️ **2 minutos** — Los índices son una decisión de implementación física, no del lenguaje, así que
toda la sintaxis —`USING`, las clases de operadores, los índices parciales— es extensión de cada
motor. PostgreSQL 18.6 tiene seis métodos de acceso: `btree`, `hash`, `gin`, `gist`, `spgist` y
`brin`. MySQL 9.7.2 con InnoDB tiene **solo B-tree** en tablas normales, más `FULLTEXT` y `SPATIAL`
como tipos aparte; el hash de verdad existe únicamente en el motor `MEMORY`. SQLite 3.53.4 tiene una
sola familia, B-tree, para índices y para tablas; la búsqueda de texto completo existe como **tabla
virtual** `FTS5`, no como índice sobre una columna.

🔬 **El detalle** — **Categoría: estándar, no verificado y declarado.** ISO/IEC 9075 es de pago y no
he leído la cláusula; lo que sí está verificado es que los tres motores aceptan `CREATE INDEX` con
sintaxis distinta e incompatible, y eso ya basta para no decir "el estándar dice". La consecuencia
práctica es de portabilidad: `USING gin` y `USING brin` ni se parsean en MySQL —`ERROR 1064 … right
syntax to use near 'GIN'`—, y en SQLite `USING` entero es un error de sintaxis. Del lado contrario,
lo que sí es común a los tres es que un índice B-tree responde `ORDER BY` sin nodo `Sort`.

---

**02 → 9.** Alguien escribe `CREATE INDEX … USING HASH` en MySQL y afirma que tiene un índice hash:
¿qué ocurrió de verdad, y cómo se lo demuestras en dos consultas? 🟠

⏱️ **30 segundos** — InnoDB aceptó la sintaxis y creó un B-tree. Se lo demuestro con `SHOW WARNINGS`
justo después del `CREATE`, y con `information_schema.STATISTICS`, donde `INDEX_TYPE` dice `BTREE`.

🗣️ **2 minutos** — El `CREATE INDEX` devuelve `Query OK` y emite una **`Note` 3502**: *"This storage
engine does not support the HASH index algorithm, storage engine default was used instead"*. El
problema es que una `Note` no la imprime el cliente por defecto ni la levanta la mayoría de los
drivers, así que desde fuera parece que todo salió bien y el equipo se queda creyendo que tiene un
índice hash. Las dos consultas son `SHOW WARNINGS` en la misma sesión y `SELECT INDEX_NAME,
INDEX_TYPE FROM information_schema.STATISTICS WHERE TABLE_NAME='pedidos'`, que devuelve `BTREE`. El
`USING HASH` sí funciona en el motor `MEMORY`, de donde viene la sintaxis.

🔬 **El detalle** — **Motor puro**, y con una trampa añadida: en el ejemplo del capítulo salieron
**dos** avisos, porque el índice duplicaba uno existente —`Warning 1831`, *duplicate index … this is
deprecated*—. **El precio de ese malentendido** es doble: el espacio y la escritura extra de un
índice que nadie pidió, y una expectativa falsa sobre qué consultas van a ir rápido. Y ojo con la
otra diferencia de motor: **en MySQL el DDL confirma implícitamente**, así que no hay `BEGIN …
ROLLBACK` que deshaga el experimento; hay que borrarlo con `DROP INDEX pedidos_cliente_id_hash ON
pedidos` y comprobar con `SHOW INDEX FROM pedidos` que vuelven a quedar los tres originales.

---

**02 → 10.** Te proponen un BRIN sobre `pedidos.creado_en` "porque es una fecha": ¿qué consultas
antes de responder, y qué contestas con el número que salga? 🟠

⏱️ **30 segundos** — Consulto `pg_stats.correlation` para esa columna. Da **-0,0073**, o sea cero:
ese BRIN no descartaría nada y la respuesta es no.

🗣️ **2 minutos** — La consulta exacta es `SELECT correlation FROM pg_stats WHERE schemaname='public'
AND tablename='pedidos' AND attname='creado_en'`. La correlación mide, entre -1 y 1, cuánto se
parece el orden lógico de los valores al orden físico en el heap, y es de lo único que depende la
utilidad de un BRIN: si cada tramo de 128 páginas contiene valores de todo el rango, todos los
tramos son candidatos y no se descarta nada. Que sea una fecha es irrelevante; lo que importa es si
se insertó en orden y no se tocó después. Aquí la semilla reparte las fechas al azar sobre 1 000
días, y es exactamente lo que le pasa a una tabla real que ha sufrido `UPDATE` y reutilización de
espacio.

🔬 **El detalle** — El hermano del caso está medido: `eventos_pedido.ocurrido_en` da **0,0098** y el
BRIN forzado con `SET LOCAL enable_seqscan = off` marca `Heap Blocks: lossy=82017` —la tabla
entera—, con `Rows Removed by Index Recheck: 4071472`, y termina en **387,232 ms contra los 328,042
ms** del `Seq Scan` que el planificador elige solo. **Aquí el BRIN no es neutro, es peor**: pagas el
índice, pagas su mantenimiento y encima la consulta tarda más si alguien fuerza el plan. La regla de
bolsillo: por debajo de ~0,9 de correlación, no te molestes. La que sí califica en este esquema es
`eventos_pedido.pedido_id`, con correlación 1.

---

**02 → 11.** Justifica por qué un BRIN de 40 kB puede sustituir a un B-tree de 51 MB sobre
`eventos_pedido(pedido_id)`, y di qué se pierde en el cambio. 🟠

⏱️ **30 segundos** — Porque `pedido_id` tiene correlación 1: los valores ya están ordenados en
disco, así que con el min/max de cada tramo el BRIN descarta el 99,8 % de las páginas sin guardar
una entrada por fila.

🗣️ **2 minutos** — Medido: `WHERE pedido_id BETWEEN 400000 AND 400500` da `Heap Blocks: lossy=128`
de 82 017 y baja de **218,960 ms sin índice a 1,478 ms**, 148 veces, con 4 347 filas de `Rows
Removed by Index Recheck`. El B-tree equivalente, en la misma máquina, ocupa **51 MB y tarda 645 ms
en construirse**, contra los **40 kB y 173 ms** del BRIN: mil trescientas veces más grande para
responder el mismo rango. Sobre cuatro millones de filas y 641 MB de tabla, esa diferencia de
espacio es la que decide si el índice cabe en caché o no.

🔬 **El detalle** — Lo que se pierde es todo lo que necesita saber *dónde* está una fila. **Igualdad
puntual**: el B-tree va a la fila, el BRIN trae las 128 páginas del tramo y recomprueba. **`ORDER
BY` sin `Sort`**: el BRIN no puede, porque no tiene orden que recorrer. **`UNIQUE`**: un BRIN no
puede respaldar una restricción de unicidad. Y **el recheck nunca desaparece**: incluso en el caso
bueno hay 4 347 filas descartadas después de leerlas. Además es frágil: basta con que empiecen a
llegar `pedido_id` fuera de orden, o con que un `UPDATE` masivo reescriba filas al final, para que
la correlación caiga y el índice deje de descartar, sin ningún error que lo anuncie. **Categoría:
motor**, el BRIN es de PostgreSQL y no existe en MySQL ni en SQLite.

---

**02 → 12.** ¿Por qué `CREATE INDEX … USING gist (ocurrido_en)` falla con "no default operator
class", y qué te enseña ese error sobre cómo funcionan los métodos de acceso? 🟠

⏱️ **30 segundos** — Porque un método de acceso no indexa tipos, indexa **clases de operadores**, y
`timestamptz` no tiene clase GiST por defecto.

🗣️ **2 minutos** — El mensaje completo es `data type timestamp with time zone has no default
operator class for access method "gist"`, y la sugerencia del motor es explícita: o especificas una
clase de operadores, o defines una por defecto para el tipo. El porqué conceptual está en lo que
GiST sabe hacer: solapamiento (`&&`), contención geométrica y proximidad (`<->`). **Un instante no
se solapa con otro instante**, así que no hay nada que un GiST pueda aportar sobre un `timestamptz`;
un `tstzrange` sí tendría clase, y para eso habría que cambiar el esquema. La extensión `btree_gist`
añade la clase, pero solo consigue que GiST imite a un B-tree, más grande y más lento.

🔬 **El detalle** — **Motor**, y es la misma regla que explica los otros dos fallos del capítulo: el
hash ignora `BETWEEN` porque solo declara `=`, y el GIN ignora `->>` porque no está en su clase. Un
índice no se elige por la columna, se elige por el **operador** del `WHERE`. **El precio de GiST,
declarado como no medido aquí**: es **con pérdida** por diseño —devuelve candidatos y el motor
recomprueba cada fila— y se construye más despacio que un B-tree; no tengo el número en este corpus
y no me lo invento. Dónde sí vale la pena: `EXCLUDE USING gist (sala WITH =, periodo WITH &&)` para
que dos reservas no se pisen, PostGIS entero, y `pg_trgm` para `LIKE '%texto%'`.

---

**02 → 13.** Un compañero propone crear en producción, y sin transacción, los cinco índices de este
capítulo "para probar cuál gana". Escribe la secuencia exacta que usarías tú en su lugar —comandos y
orden— y justifica cada paso, incluido el `ANALYZE`. 🔴

⏱️ **30 segundos** — Uno a uno, dentro de `BEGIN … ROLLBACK`, midiendo antes y después con `EXPLAIN
(ANALYZE, COSTS, BUFFERS)` y con un `ANALYZE` en medio; y no en producción, sino en una copia con
los mismos datos.

🗣️ **2 minutos** — La secuencia por cada candidato es siempre la misma cinco veces:

```text
EXPLAIN (ANALYZE, COSTS, BUFFERS) <consulta>;   -- línea base: tiempo y páginas
BEGIN;
CREATE INDEX <nombre> ON <tabla> USING <familia> (<columna>);
ANALYZE <tabla>;
SELECT pg_size_pretty(pg_relation_size('<nombre>'));
EXPLAIN (ANALYZE, COSTS, BUFFERS) <consulta>;   -- el plan nuevo
ROLLBACK;
```

El `ANALYZE` no es opcional: **sin estadísticas del índice el planificador no lo considera**, y
medirías un `Seq Scan` creyendo que el índice no sirve; también se deshace con el `ROLLBACK`. El
`pg_relation_size` es la mitad del resultado, porque la comparación no es solo de tiempo. Y el
`ROLLBACK` cierra: PostgreSQL tiene DDL transaccional, el índice existe para la sesión que lo creó,
sirve para medir y desaparece.

🔬 **El detalle** — Por qué **uno a uno** y no los cinco: con el hash y el B-tree presentes a la vez,
el planificador elige uno y del otro no aprendes nada; y los cinco a la vez suman su espacio y su
escritura extra sin que puedas atribuir el coste. Por qué **no en producción**: `CREATE INDEX`
normal **toma un bloqueo que impide escrituras** en la tabla mientras dura, y aquí eso son 169 ms
para el B-tree pero 5,8 s para el GIN. **Motor, y es la excepción que hay que saber:** `CREATE INDEX
CONCURRENTLY` evita ese bloqueo, pero **no puede ejecutarse dentro de un bloque de transacción**,
así que es incompatible con esta receta —es lo que se usa para el índice que ya decidiste dejar, no
para el experimento—. Cierre obligatorio: `SELECT count(*) FROM pg_indexes WHERE
schemaname='public'` debe volver a dar **11**, los de `PRIMARY KEY` y `UNIQUE` del esquema.

---

**02 → 14.** `eventos_pedido` se consulta por `carga @> '{…}'` y por rango de `pedido_id`. Diseña la
indexación completa con las familias de este capítulo, escribe el DDL y pon el precio de cada índice
en espacio y en construcción. 🔴

⏱️ **30 segundos** — Un GIN sobre `carga` para el `@>` y un BRIN sobre `pedido_id` para el rango.
Dos familias distintas porque son dos preguntas distintas.

🗣️ **2 minutos** — El DDL, con el precio medido al lado:

```text
-- 85 MB, 5,8 s de construcción; 60 MB y 2,2 s con jsonb_path_ops
CREATE INDEX eventos_pedido_carga_gin ON eventos_pedido USING gin (carga);

-- 40 kB, 173 ms de construcción
CREATE INDEX eventos_pedido_pedido_id_brin ON eventos_pedido USING brin (pedido_id);
```

El GIN porque `@>` es contención y hace falta indexar las partes del documento: baja de 596,011 ms a
137,793 ms. El BRIN porque `pedido_id` tiene **correlación 1** —comprobado en `pg_stats` antes de
crear nada—, y con eso el rango baja de 218,960 ms a 1,478 ms descartando el 99,8 % de las páginas.
Lo que **no** pongo: un B-tree sobre `pedido_id`, que costaría 51 MB y 645 ms para el mismo trabajo;
ni un B-tree sobre `carga`, que no sabe responder `@>`.

🔬 **El detalle** — El total son **85,04 MB sobre una tabla de 641 MB**, un 13,3 %, y casi todo es el
GIN. La decisión fina es `jsonb_path_ops`: 60 MB y 2,2 s en vez de 85 MB y 5,8 s, a cambio de servir
**solo** para `@>` —si algún día aparece un operador de existencia de clave, deja de valer—. **El
precio por escritura, que es el que se olvida:** el GIN no añade una entrada por `INSERT` sino
tantas como elementos tenga el documento, amortiguado por la lista pendiente de `fastupdate` —barato
casi siempre, muy caro cuando toca vaciarla—; el BRIN casi no cuesta mientras se inserte al final. Y
la advertencia que acompaña al diseño: si mañana alguien escribe `carga->>'origen' = …`, este GIN
**no lo acelera** —518,021 ms medidos— y hará falta un índice de expresión, que es un B-tree y es
material de `03`.

---

**02 → 15.** Tienes que defender ante un equipo que migra de PostgreSQL a MySQL 9.7.2 que dos de sus
índices no pueden viajar: escribe qué dos son, qué los sustituye del lado de MySQL y qué se degrada
en cada caso. 🔴

⏱️ **30 segundos** — El GIN sobre `jsonb` y el BRIN sobre `pedido_id`. En InnoDB no existe ninguna
de las dos familias: `USING GIN` y `USING BRIN` ni siquiera se parsean.

🗣️ **2 minutos** — **El GIN** se sustituye por **columnas generadas con un B-tree encima**: se
extrae cada clave que se consulta a una columna generada y se indexa. Lo que se degrada es la
generalidad: el GIN responde cualquier `@>` sobre cualquier combinación de claves con un solo
índice, y las columnas generadas solo responden las claves que alguien decidió extraer de antemano;
una consulta nueva sobre una clave no prevista vuelve al escaneo completo y obliga a un `ALTER
TABLE`. **El BRIN** no tiene sustituto de su forma: lo único disponible es un B-tree sobre
`pedido_id`, y ahí el precio se multiplica —**51 MB contra 40 kB**, 645 ms contra 173 ms de
construcción— más la escritura extra en cada `INSERT`. En rendimiento de lectura el B-tree incluso
gana; lo que se pierde es el espacio y la baratura de mantenimiento.

🔬 **El detalle** — **Categoría, y es el argumento que cierra la discusión: el estándar SQL no dice
nada de familias de índice**, así que nadie está incumpliendo nada; cada motor decide, y no hay
portabilidad que reclamar. Lo demostrable en dos minutos: `CREATE INDEX … USING GIN` da `ERROR 1064
… right syntax to use near 'GIN'` —no es que no esté soportado, es que no es una palabra del
lenguaje—. Y el tercer índice que conviene mencionar aunque no lo pregunten es el hash: **sí viaja,
en el sentido de que no falla**, y eso es peor, porque InnoDB acepta `USING HASH`, crea un B-tree y
solo avisa con una `Note 3502` que el cliente no imprime. Un índice que desaparece con un error se
arregla; uno que se convierte en otra cosa en silencio, no.

---

## Capítulo 03 — Compuestos, parciales y de cobertura

Las 16 preguntas de [`03`](03-compuestos-parciales-y-de-cobertura.md).

**03 → 1.** Enuncia la regla del prefijo izquierdo con la analogía de la guía telefónica. 🟢

⏱️ **30 segundos** — Un índice sobre `(a, b, c)` es una guía telefónica ordenada por apellido y
luego nombre: sirve para buscar por `a`, por `(a, b)` y por `(a, b, c)`, y no sirve para buscar solo
por `b` o solo por `c`.

🗣️ **2 minutos** — La razón es que las entradas están ordenadas físicamente por la primera columna:
en cuanto la fijas, todo lo demás queda contiguo y basta una bajada por el árbol. Si tu `WHERE` no
la nombra, los "Ana" están desperdigados por las mil páginas. Medido en el capítulo, con
`producto_id = 17` sobre `(producto_id, cantidad)`: `Index Searches: 1` y veintitrés páginas de
índice contra las 29 167 de la tabla. La misma consulta filtrando solo por `cantidad` necesita 51
bajadas. Quién lo manda: el motor —la estructura del B-tree—, no el estándar.

🔬 **El detalle** — El matiz de 2026 es que "no lo usa" ya no es literal. PostgreSQL 18 y MySQL desde
la 8.0.13 hacen *skip scan* y el índice aparece en el plan, pero eso no lo vuelve útil: 2 702 de las
3 072 páginas del índice —el 88 %— y 190,789 ms, contra los 167,704 ms del `Seq Scan`. El
planificador lo eligió porque estimó 64 421 contra 72 917, y se equivocó por un 14 % en el reloj.
**Categoría: motor.** El precio de ese compuesto: 24 MB y 829,309 ms de construcción, más una
escritura extra por cada `INSERT` y `DELETE` de `pedido_lineas`.

---

---

**03 → 2.** ¿Qué lleva un índice parcial en su definición que un índice normal no lleva? 🟢

⏱️ **30 segundos** — Un `WHERE` en su propia definición: solo guarda las filas que lo cumplen.
`CREATE INDEX … ON pedidos (cliente_id) WHERE estado = 'ANULADO'`.

🗣️ **2 minutos** — Se paga solo cuando la bandera está desbalanceada y siempre se filtra igual:
`pedidos` tiene 60 000 `ANULADO` de 1 000 000, así que indexar el otro 94 % es disco y escrituras
por filas que nadie consulta. La trampa es que el motor **solo lo usa si puede demostrar que el
`WHERE` de la consulta implica el del índice**: con `estado = 'PENDIENTE'` cae al índice completo, y
con `WHERE cliente_id = 311` a secas, igual. Cuándo no: cuando el `WHERE` varía, porque acabas con
un parcial por valor.

🔬 **El detalle** — El número con el que el planificador decide es una **estimación**: `reltuples`
dice 56 934 donde hay 60 000. El precio, medido lado a lado: 1136 kB y 38,254 ms el parcial contra
7800 kB y 191,090 ms el completo, diecisiete veces menos entradas; y por escritura solo paga la fila
que entra o sale del predicado —un `UPDATE` de `estado` la mete o la saca—. **Categoría: motor.**
PostgreSQL y SQLite lo tienen; MySQL 9.7.2 responde `ERROR 1064` de sintaxis al `WHERE`, y su
prefijo `email(10)` no es lo mismo.

---

---

**03 → 3.** ¿Qué guarda un índice funcional que no guarda un índice sobre la columna? 🟢

⏱️ **30 segundos** — El resultado de la expresión. `clientes_email_key` guarda `email`; el funcional
guarda `lower(email)`, que es exactamente lo que la consulta compara.

🗣️ **2 minutos** — El motor no sabe que uno se deriva del otro, así que con el `UNIQUE` sobre
`email` la consulta `WHERE lower(email) = ?` va a `Seq Scan`: 618 páginas, 17,522 ms y `Rows Removed
by Filter: 49999`. Con `CREATE INDEX ix_clientes_email_lower ON clientes (lower(email))` hay algo
que comparar y el plan pasa a `Index Scan` con `Index Cond: (lower(email) =
'cliente311@ejemplo.test'::text)`: 4 páginas y 0,041 ms. Es el mismo caso general que "la columna
envuelta en una función no usa su índice", visto desde la solución.

🔬 **El detalle** — **La expresión del índice y la del `WHERE` tienen que coincidir exactamente**:
`upper(email)`, `lower(trim(email))` o `email ILIKE …` son otras expresiones y no hay índice para
ellas. El precio: 2448 kB, 134,664 ms de construcción, y **la expresión se evalúa en cada `INSERT` y
en cada `UPDATE` de `email`** —un índice funcional cuesta más por escritura que uno normal del mismo
tamaño—. Cuándo no: si comparas sin distinguir mayúsculas *en todas partes*, eso es del tipo de la
columna —*collation* no determinista o `citext`—, no un índice por consulta. **Categoría: motor**:
nativo en PostgreSQL y SQLite, y en MySQL desde la 8.0.13 como *functional key part*,
`((lower(email)))`.

---

---

**03 → 4.** ¿Qué es un *index-only scan* y qué condición cumple el índice que lo permite? 🟢

⏱️ **30 segundos** — Es resolver la consulta sin tocar la tabla, porque el índice ya trae **todas**
las columnas que la consulta pide. Ese índice se llama de cobertura.

🗣️ **2 minutos** — Con `(cliente_id, total)`, un `SELECT sum(total) … WHERE cliente_id = 311` no
necesita el heap y el nodo del plan es `Index Only Scan`. Hay dos formas de cubrir: meter la columna
en la clave, o dejarla fuera con `INCLUDE (total)` —así viaja solo en las hojas, el árbol no
engorda, y a cambio no se puede filtrar ni ordenar por ella—. Basta pedir una columna que no esté en
el índice, como `max(creado_en)`, para que el plan vuelva a `Index Scan`.

🔬 **El detalle** — El matiz que separa recitar de entender: `Index Only Scan` dice que se
**intentó**, no que se consiguiera. Un índice de PostgreSQL no guarda la visibilidad, así que el
motor consulta el *visibility map* y, si la página no está marcada, va al heap igual: en el plan del
capítulo, `Heap Fetches: 52` sobre 52 filas. El precio del de cobertura es el más alto del capítulo,
**31 MB y 595,203 ms**, precisamente por ser el más ancho. **Categoría: motor.** `INCLUDE` es de
PostgreSQL desde la 11; en MySQL/InnoDB no hace falta porque el índice secundario ya lleva la PK, y
en SQLite no existe.

---

---

**03 → 5.** En un plan, ¿qué te dice la línea `Heap Fetches` y qué valor querrías ver? 🟢

⏱️ **30 segundos** — Cuántas veces el *index-only scan* tuvo que ir a la tabla de todas formas. El
valor que quieres ver es **0**.

🗣️ **2 minutos** — Un índice de PostgreSQL no guarda si la fila está viva para tu transacción; eso
lo dice el heap. Para no preguntarlo siempre, el motor mantiene un *visibility map* —un bit por
página, que `VACUUM` pone cuando todas sus filas son visibles para todos—. Si el bit está, el `Index
Only Scan` se ahorra el heap y `Heap Fetches` sale 0; si no está, va a la tabla y el nodo sigue
llamándose igual. En el plan de §6 el valor es 52 sobre 52 filas: no se ahorró ni una.

🔬 **El detalle** — Honestidad sobre el número: **en este corpus `Heap Fetches` nunca va a ser 0 en
`pedidos` ni en `clientes`, porque esas tablas nunca pasaron por `VACUUM`**. `pg_class` lo enseña:
`relallvisible = 0` de `relpages = 10770` en `pedidos` y 0 de 618 en `clientes`. La excepción es
`pedido_lineas`, 29 163 de 29 167, porque autovacuum la tocó tras la carga. Con el mapa al día —lo
normal en producción— ese plan daría `Heap Fetches: 0` y 3 páginas en vez de 21; aquí no se corre
`VACUUM` a propósito, porque movería los planes de todo el corpus. **Categoría: motor**,
consecuencia directa del MVCC de PostgreSQL.

---

---

**03 → 6.** Distingue el índice parcial de PostgreSQL del prefijo de columna `email(10)` de MySQL. 🟡

⏱️ **30 segundos** — El parcial indexa **menos filas**; el prefijo de MySQL indexa **menos
columna**. `email(10)` no deja fuera ni una sola fila.

🗣️ **2 minutos** — El parcial lleva un `WHERE` en su definición: `(cliente_id) WHERE estado =
'ANULADO'` guarda 56 934 entradas de 1 000 000 y ocupa 1136 kB contra 7800 kB del completo, y su
plan ni menciona `estado` en el `Index Cond`. El prefijo de MySQL guarda los diez primeros
caracteres del `email` de las 50 000 filas: `SHOW INDEX` responde `Sub_part = 10` y `Cardinality =
946`. Sirve para acortar la clave de una columna larga —y para poder indexar un `TEXT`—, no para
reducir el índice a un subconjunto de filas.

🔬 **El detalle** — **946 valores distintos de 50 000** es el precio real del prefijo: colisiona
muchísimo, así que el motor localiza un montón de candidatas y tiene que ir a la fila a confirmar el
valor completo; un `UNIQUE` sobre un prefijo ni siquiera significa lo mismo que sobre la columna.
**Categoría: motor en los dos casos**, y ninguno existe en el otro motor: MySQL 9.7.2 responde
`ERROR 1064` al `WHERE` de un parcial, y ni PostgreSQL ni SQLite tienen `col(n)`. SQLite sí tiene
parciales. El estándar no define ninguna de las dos cosas.

---

---

**03 → 7.** ¿Los índices los define el estándar SQL o cada motor? Di qué hay en ISO/IEC 9075 sobre
`CREATE INDEX`. 🟡

⏱️ **30 segundos** — Cada motor. **ISO/IEC 9075 no define los índices**: ni `CREATE INDEX` ni
`EXPLAIN` están en la norma, porque son estructuras de implementación.

🗣️ **2 minutos** — El estándar describe el resultado lógico de una consulta, no el camino para
llegar a él; elegir ese camino es trabajo del planificador, y los índices son la herramienta que le
das. Por eso todo lo de este capítulo —la regla del prefijo izquierdo, los parciales, los
funcionales, `INCLUDE`, el *skip scan*— se etiqueta como **motor**, y por eso las diferencias entre
PostgreSQL, MySQL y SQLite son tan grandes: cada uno inventó su sintaxis y sus extensiones sin nadie
que las armonizara.

🔬 **El detalle** — Decirlo es media respuesta; la otra mitad es qué implica. Que no esté en la norma
significa que **ningún DDL de índices es portable**: el mismo esquema pasa de PostgreSQL a MySQL
perdiendo los parciales y el `INCLUDE`, y de MySQL a PostgreSQL perdiendo los prefijos `col(n)`. Y
hay un límite honesto que conviene decir en voz alta: la norma es de pago, así que lo que se afirma
aquí es que no aparece, no una cita de cláusula verificada; lo que sí está medido en sesión es lo
que hace cada motor. **Categoría: motor**, en todas las filas de la tabla de §8.

---

---

**03 → 8.** Con `(producto_id, cantidad)` filtras solo por `cantidad`: ¿qué hacía PostgreSQL 17, qué
hace la 18 y por qué el consejo no cambia? 🟡

⏱️ **30 segundos** — La 17 ignoraba el índice y hacía `Seq Scan`. La 18 hace *skip scan* y el índice
sí aparece en el plan. El consejo no cambia porque sigue saliendo más caro que leer la tabla.

🗣️ **2 minutos** — El *skip scan* salta de un valor de `producto_id` al siguiente buscando `cantidad
= 5` en cada tramo. Con 5 000 productos distintos eso no es saltar: son 51 bajadas —`Index Searches:
51`, no 1— y **2 702 de las 3 072 páginas del índice, el 88 %**, y después el heap igual. Total,
190,789 ms; el `Seq Scan`, con los accesos por índice apagados, tarda 167,704 ms. Cambia el síntoma,
no el diagnóstico: un índice que necesita 51 bajadas y lee casi todas sus páginas no sirve para esa
consulta.

🔬 **El detalle** — Por qué el planificador se equivocó: estimó 64 421 para el plan por índice contra
72 917 para el `Seq Scan`, y el reloj dijo lo contrario por un 14 %. El aviso de contexto importa en
entrevista: casi todos los artículos que vas a encontrar dicen "el índice no se usa", que era exacto
hasta PostgreSQL 17 y hoy ya no describe lo que ves en el plan. **Categoría: motor.** MySQL hace lo
mismo desde la 8.0.13 y lo llama igual —`Covering index skip scan on pedido_lineas using
ix_lineas_prod_cant over cantidad = 5`—; SQLite no lo tiene.

---

---

**03 → 9.** `CREATE INDEX` dentro de `BEGIN … ROLLBACK`: ¿qué pasa en PostgreSQL y en MySQL? ¿Es
diferencia de estándar o de motor? 🟡

⏱️ **30 segundos** — En PostgreSQL el `ROLLBACK` deshace el índice, porque su DDL es transaccional.
En MySQL no: el DDL confirma implícitamente y el índice se queda. **Es diferencia de motor**, no de
estándar.

🗣️ **2 minutos** — Es la razón de que todas las sesiones de este capítulo abran con `BEGIN` y
cierren con `ROLLBACK`: así se miden índices sobre las tablas del corpus sin dejar ninguno detrás.
En MySQL esa red no existe, así que los cuatro índices de §8 hubo que borrarlos a mano con `DROP
INDEX … ON …`. SQLite se comporta como PostgreSQL y también deshace el DDL con `ROLLBACK`.

🔬 **El detalle** — El detalle que muerde en MySQL: al crear `ix_lineas_prod_cant`, InnoDB **eliminó
por redundante el índice implícito de la foránea** `fk_lineas_producto`, y luego se negó a soltar el
nuevo con `ERROR 1553 … needed in a foreign key constraint`; hubo que recrear el original antes de
poder limpiar. Es decir, en MySQL un `CREATE INDEX` puede cambiar el esquema en sitios que no
nombraste. La excepción en PostgreSQL es `CREATE INDEX CONCURRENTLY`, que no puede correr dentro de
una transacción y por tanto no es reversible con `ROLLBACK`: por eso este corpus no lo usa.
**Categoría: motor**; el estándar no define índices, así que no dice nada sobre si su DDL es
transaccional.

---

---

**03 → 10.** Te dan `(cantidad, producto_id)` y `(producto_id, cantidad)`, y solo puedes dejar uno
para un `WHERE producto_id = ? AND cantidad = ?`. Elige y justifica con la selectividad medida. 🟠

⏱️ **30 segundos** — Me quedo con `(producto_id, cantidad)`. `producto_id = 17` deja 20 205 filas de
3 500 000 —el 0,58 %—; `cantidad = 5` deja 438 435 —el 12,5 %—: delante va la más selectiva.

🗣️ **2 minutos** — Con las dos igualdades puestas, cualquiera de los dos mete todo en el `Index
Cond`; lo que decide es qué pasa cuando falta una, y en la práctica siempre falta. Medido sobre
`WHERE producto_id = 17`: con `(producto_id, cantidad)`, `Index Searches: 1` y veintitrés páginas de
índice; con `(cantidad, producto_id)`, `Index Searches: 7` —una bajada por cada valor de `cantidad`—
y 49 páginas. Y al revés no hay rescate: filtrar solo por `cantidad` con el índice bueno cuesta 51
bajadas y el 88 % de sus páginas. Siete saltos sobre cinco valores sale barato; 51 sobre 5 000, no.
Esa asimetría **es** la selectividad.

🔬 **El detalle** — El reloj no distingue nada aquí y hay que decirlo: el orden "malo" salió en
23,433 ms y el "bueno" en 34,492 ms, porque el heap del segundo estaba frío —`hit=8770` contra
`hit=381`—. Se decide por páginas y bajadas, no por milisegundos de una ejecución. El precio es casi
el mismo en espacio, 24 MB los dos, pero el inverso tardó **1 097,263 ms** en construirse contra
829,309 ms, y cada uno cobra una escritura extra por fila insertada o borrada; por eso dejar los dos
es lo peor de las dos opciones. **Categoría: motor.**

---

---

**03 → 11.** ¿Por qué el plan del índice parcial no tiene línea `Filter` y el del completo sí? 🟠

⏱️ **30 segundos** — Porque la condición `estado = 'ANULADO'` la garantiza la definición del índice:
si la entrada está ahí dentro, la fila la cumple. No hay nada que volver a comprobar.

🗣️ **2 minutos** — El plan del parcial trae `Index Cond: (cliente_id = 311)` y ninguna línea
`Filter`. El del completo trae `Index Cond: (cliente_id = 311)`, `Filter: (estado =
'PENDIENTE'::text)` y `Rows Removed by Filter: 46`: localizó las 52 filas del cliente, fue al heap a
por todas y tiró 46. Ese trabajo descartado es exactamente lo que el parcial no hace, y es el ahorro
de verdad —más que el tamaño del índice—.

🔬 **El detalle** — El motor solo lo usa si **puede demostrar que el `WHERE` de la consulta implica
el del índice**. Con `PENDIENTE` no implica `ANULADO` y cae al completo; con `WHERE cliente_id =
311` a secas, tampoco. Y el motivo número uno de "en mi máquina sí se usaba": con el valor en un
parámetro —`estado = $1`— el planificador no puede demostrar la implicación en un plan genérico y el
parcial se queda sin usar, aunque en `psql` con el literal funcionara. El precio, para poner la
decisión en contexto: 1136 kB y 38,254 ms el parcial contra 7800 kB y 191,090 ms el completo.
**Categoría: motor.**

---

---

**03 → 12.** Un compañero propone un índice parcial por cada uno de los cinco estados de `pedidos`.
Dale el argumento de coste en contra, con números. 🟠

⏱️ **30 segundos** — Cinco parciales que cubren los cinco estados no son cinco índices pequeños:
entre todos indexan el millón de filas, ocupan lo que un índice completo, y cobran **cinco
escrituras por fila** en vez de una.

🗣️ **2 minutos** — El parcial de `ANULADO` sale barato —1136 kB y 38,254 ms— precisamente porque
solo cubre 56 934 entradas de 1 000 000; en cuanto sumas los cinco estados vuelves al millón de
entradas y a los 7800 kB del índice completo, repartidos en cinco árboles en lugar de uno. Lo que no
se recupera es el lado de la escritura, que es donde está el coste real y se mide con `EXPLAIN
(WAL)`, lo único que no depende de la caché: cien mil `INSERT` en `pedidos` escriben 303 976
registros de WAL con la tabla tal cual y **504 640** con dos índices encima —dos más por fila, uno
por índice—, y el `Insert` pasa de 447 ms a 723 ms.

🔬 **El detalle** — Al mismo ritmo medido —un registro de WAL por fila y por índice—, cinco parciales
son cinco registros más por fila; y un `UPDATE` de `estado` es peor que un `INSERT`, porque saca la
fila de un árbol y la mete en otro, tocando dos de los cinco. Que un `UPDATE` solo paga si toca
columna indexada también está medido: 39 905 filas con `SET total = total + 0.01` dan 158 435
registros de WAL sin índice sobre `total` y 200 027 con él. Y hay un coste de plan: cinco parciales
por valor no se usan con `estado = $1`. La regla es **un índice por patrón de acceso**, no uno por
valor. **Categoría: convención mal entendida** —es la vieja "pon un índice por cada columna del
`WHERE`" con otro disfraz—; el mecanismo de debajo es del motor.

---

---

**03 → 13.** El *index-only scan* de §6 lee 21 páginas y el `Index Scan` equivalente 18: explica por
qué el de cobertura sale más caro y qué tendría que cambiar para que ganara. 🟠

⏱️ **30 segundos** — Porque el de cobertura es más ancho —lleva `total` además de `cliente_id`— y
encima va al heap igual: `Heap Fetches: 52` sobre 52 filas. Pagas el índice gordo y no te ahorras la
tabla. Lo que tendría que cambiar es el *visibility map*, no el índice.

🗣️ **2 minutos** — Un `Index Only Scan` solo evita el heap cuando el mapa dice que la página entera
es visible para todo el mundo, y ese bit lo pone `VACUUM`. En `pedidos` el mapa está vacío:
`relallvisible = 0` de `relpages = 10770`. El planificador lo sabe y lo cobra —25,05 estimado para
el plan de cobertura contra 25,10 del plan que sí necesita la tabla, cinco centésimas—, así que aquí
ni siquiera se está equivocando: está midiendo una tabla sin aspirar. Con `VACUUM` reciente ese
mismo plan daría `Heap Fetches: 0` y **3 páginas en vez de 21**, y ahí el de cobertura gana con
holgura.

🔬 **El detalle** — La prueba de que es el mapa y no el índice está en la misma consulta a
`pg_class`: `pedido_lineas` sí tiene 29 163 de 29 167 páginas marcadas, porque autovacuum la tocó
tras la carga. En este corpus no vas a ver el caso bueno a propósito: correr `VACUUM` cambiaría los
`Heap Fetches` de todos los planes de todos los capítulos. El precio del de cobertura, para cerrar
el argumento: **31 MB y 595,203 ms**, el más caro del capítulo, más una escritura extra por cada
`INSERT`, `DELETE` y `UPDATE` que toque `cliente_id` o `total`. **Categoría: motor** —es una
consecuencia del MVCC de PostgreSQL, no del estándar—; en InnoDB el índice secundario lleva la PK y
la pregunta ni se plantea igual.

---

---

**03 → 14.** Escribe el DDL de los índices para este panel: pedidos `ANULADO` de un cliente,
ordenados por `creado_en`, mostrando solo `codigo` y `total`. Justifica el orden de las columnas. 🔴

⏱️ **30 segundos** — Uno solo: `CREATE INDEX ix_pedidos_panel_anulado ON pedidos (cliente_id,
creado_en) INCLUDE (codigo, total) WHERE estado = 'ANULADO';` — parcial por el estado, `cliente_id`
delante, `creado_en` detrás para el orden, y las dos columnas de salida en `INCLUDE`.

🗣️ **2 minutos** — El orden sale del patrón de acceso, no del gusto. `cliente_id` va primero porque
es igualdad y es lo único que siempre está en el `WHERE`: garantiza una sola bajada por el árbol y
deja el tramo contiguo. `creado_en` va segunda porque, dentro de ese tramo, el índice ya entrega las
filas ordenadas y el `ORDER BY` se sirve solo, sin nodo de `Sort`. `estado` no va en la clave: va en
el `WHERE` del índice, porque el panel **solo** mira `ANULADO` —56 934 entradas en vez de 1 000 000,
1136 kB en vez de 7800 kB— y así el plan ni lo menciona en el `Index Cond`. `codigo` y `total` van
en `INCLUDE` porque no se filtra ni se ordena por ellas: viajan en las hojas, no engordan las ramas,
y completan la cobertura.

🔬 **El detalle** — Dos honestidades. La primera: sobre las tablas de este corpus ese índice daría
`Heap Fetches` distinto de cero aunque el plan diga `Index Only Scan`, porque `relallvisible` es 0
de 10 770 páginas en `pedidos`; la cobertura solo se cobra con el *visibility map* al día. La
segunda es el precio: un registro de WAL más por fila en cada `INSERT` y cada `DELETE`, y en cada
`UPDATE` que toque `cliente_id`, `creado_en`, `codigo`, `total` **o** `estado` —el `UPDATE` que
anula un pedido mete la fila en el índice, y el que lo reactiva la saca—. **Categoría: motor.**
`INCLUDE` es PostgreSQL desde la 11 y el `WHERE` parcial es PostgreSQL y SQLite; en MySQL 9.7.2
ninguna de las dos cláusulas existe —el `WHERE` da `ERROR 1064`— y habría que meterlo todo en la
clave. Si lo creas para medir, dentro de `BEGIN … ROLLBACK`.

---

---

**03 → 15.** Te pasan un plan con `Index Only Scan` y `Heap Fetches: 438435`: escribe la secuencia
de diagnóstico —qué miras, con qué catálogo, en qué orden— y la corrección. 🔴

⏱️ **30 segundos** — Lo primero que digo es que no toco el índice: un `Index Only Scan` con `Heap
Fetches` alto es **una tabla sin `VACUUM` reciente**, no un índice mal elegido.

🗣️ **2 minutos** — La secuencia, en orden. Uno: `SELECT relname, relpages, relallvisible FROM
pg_class WHERE relname = '<tabla>'` —si `relallvisible` es 0, o muy por debajo de `relpages`, el
diagnóstico ya está cerrado—. Dos: `last_vacuum` y `last_autovacuum` en `pg_stat_user_tables`, para
saber si autovacuum no corre o no llega. Tres: `n_dead_tup` y el ritmo de escritura de la tabla, que
es lo que explica *por qué* no llega. La corrección es un `VACUUM` de esa tabla, y si el síntoma
vuelve, bajarle `autovacuum_vacuum_scale_factor` con `ALTER TABLE … SET (…)` para que el mapa se
mantenga al día.

🔬 **El detalle** — El número delata el caso: 438 435 es justo el volumen que devuelve `cantidad = 5`
en `pedido_lineas`, así que ese `Index Only Scan` no se ahorró ni una visita al heap —degeneró en un
`Index Scan` con un índice más ancho—. Lo que **no** hay que hacer es añadir columnas al índice: eso
lo empeora. Y hay un caso en que el número es normal y la respuesta es otra: una tabla con escritura
constante nunca tendrá el mapa al día, y ahí lo correcto es no diseñar la consulta contando con el
*index-only scan*. **Categoría: motor.** En este corpus el número se deja alto a propósito: las
tablas nunca pasaron por `VACUUM` y `pedidos` marca `relallvisible = 0` de 10 770 páginas.

---

---

**03 → 16.** Haz que `WHERE lower(email) = ?` use un índice en PostgreSQL 18.6, MySQL 9.7.2 y SQLite
3.53.4: el DDL de los tres, y en qué se diferencian. 🔴

⏱️ **30 segundos** — Los tres lo permiten con un índice sobre la expresión y solo cambia la
sintaxis: PostgreSQL y SQLite, `CREATE INDEX ix_clientes_email_lower ON clientes (lower(email));`;
MySQL necesita un segundo par de paréntesis, `ON clientes ((lower(email)))`.

🗣️ **2 minutos** — Con el DDL puesto, los tres pasan de recorrer la tabla a buscar. PostgreSQL 18.6
da `Index Scan using ix_clientes_email_lower` con `Index Cond: (lower(email) =
'cliente311@ejemplo.test'::text)`: 4 páginas y 0,041 ms, contra el `Seq Scan` de 618 páginas y
17,522 ms. MySQL 9.7.2 da `-> Index lookup on clientes using ix_clientes_email_lower (lower(email) =
'cliente311@ejemplo.test') (cost=0.35 rows=1)`. SQLite 3.53.4 da `SEARCH clientes USING INDEX
ix_clientes_email_lower (<expr>=?)`. En los tres, la expresión del índice y la del `WHERE` tienen
que coincidir exactamente.

🔬 **El detalle** — Tres diferencias que conviene nombrar. **Sintaxis:** MySQL lo llama *functional
key part* y lo tiene desde la 8.0.13; sin el doble paréntesis entiende que `lower` es un nombre de
columna y falla. **Reversibilidad:** en PostgreSQL y SQLite el `CREATE INDEX` se deshace con
`ROLLBACK`; en MySQL confirma implícitamente y hay que limpiarlo con `DROP INDEX
ix_clientes_email_lower ON clientes`. **Precio:** en PostgreSQL, 2448 kB y 134,664 ms de
construcción, y la expresión se evalúa en cada `INSERT` y en cada `UPDATE` de `email` —un índice
funcional cuesta CPU por escritura, no solo espacio—. **Categoría: motor en todo**: el estándar no
define índices, así que aquí no hay nada que portar por norma.

---

---

## Capítulo 04 — Estadísticas y el planificador

Las 19 preguntas de [`04`](04-estadisticas-y-el-planificador.md).

**04 → 1.** ¿Qué hace exactamente `ANALYZE` y dónde deja lo que recoge? 🟢

⏱️ **30 segundos** — Muestrea la tabla, resume esa muestra y escribe el resumen en el catálogo
`pg_statistic`; la vista legible es `pg_stats`.

🗣️ **2 minutos** — No toca los datos ni reescribe la tabla: solo lee una muestra y deja frecuencias,
cardinalidad, histograma y correlación por columna. Es lo que alimenta el `rows=` de cada nodo del
plan, así que cuando un `rows=` no cuadra el primer sitio al que mirar es `pg_stats` de las columnas
del `WHERE`. Es barato comparado con lo que la gente teme: sobre el millón de filas de `pedidos`
tarda **150 ms**, y sobre los 3,5 millones de `pedido_lineas`, **174 ms**.

🔬 **El detalle** — Categoría: **motor entero**. El estándar SQL no define `ANALYZE`, ni
estadísticas, ni planificador: describe qué resultado devuelve una consulta, no cómo se ejecuta. La
muestra no es la tabla: son `300 × default_statistics_target` filas, o sea 30 000 con el valor por
defecto, el **0,86 %** de `pedido_lineas`. Y en PostgreSQL `ANALYZE` es **transaccional**: dentro de
un `BEGIN … ROLLBACK` las estadísticas vuelven a lo que eran.

---

**04 → 2.** ¿Qué columnas de `pg_stats` usa el planificador al estimar una igualdad, y qué guarda
cada una? 🟢

⏱️ **30 segundos** — `most_common_vals` y `most_common_freqs` para los valores frecuentes,
`n_distinct` y `histogram_bounds` para el resto, y `null_frac` para los nulos.

🗣️ **2 minutos** — `most_common_vals` (el MCV) y `most_common_freqs` van en el mismo orden y son la
pareja que hace la mayor parte del trabajo: si el valor del `WHERE` está en el MCV, la selectividad
se lee directamente de ahí. Si no está, se usa la frecuencia media de lo que el MCV no cubre, que
sale de `n_distinct` y del MCV. `histogram_bounds` son las cotas equipobladas para los rangos,
`null_frac` estima un `IS NULL`, `avg_width` alimenta el `width=` del plan y `correlation` decide
cuántas páginas cree el motor que saltará en un `Index Scan`.

🔬 **El detalle** — Categoría: **motor**. Los números medidos sobre `pedidos.estado`: `null_frac =
0`, `avg_width = 8`, `n_distinct = 5`, MCV `{ENTREGADO,ENVIADO,PAGADO,PENDIENTE,ANULADO}` con
frecuencias `{0.2945, 0.27203333, 0.2514, 0.121533334, 0.060533334}`, `histogram_bounds` nulo y
`correlation = 0.24938495`. En `pedido_lineas.producto_id` la foto cambia: `n_distinct = 4984`,
**56** valores en el MCV —de un límite de 100— y **101 cotas** de histograma.

---

**04 → 3.** ¿Qué significa un `n_distinct` negativo, y por qué PostgreSQL lo escribe así a veces? 🟢

⏱️ **30 segundos** — Positivo es un recuento absoluto de valores distintos; negativo es una
**proporción** del total de filas.

🗣️ **2 minutos** — `5` significa cinco valores distintos y punto. `-1` significa "todos distintos",
y `-0,319835` significa que el 32 % de las filas tiene un valor propio. PostgreSQL elige la forma
negativa cuando la muestra sugiere que el número de valores **crecerá con la tabla**: un recuento
absoluto se quedaría viejo en cuanto la tabla duplicara su tamaño, mientras que la proporción sigue
valiendo. Por eso `estado` sale como `5` y `pedidos.total` como `-0,319835`.

🔬 **El detalle** — Categoría: **motor**, y es una columna que se puede **fijar a mano** con `ALTER
TABLE … ALTER COLUMN … SET (n_distinct = …)` cuando sabes que la muestra miente: es el caso clásico
de una columna con muchísimos valores distribuidos de forma que 30 000 filas de muestra no bastan
para verlos. `pedidos.cliente_id` sale con `n_distinct = 47988` sobre 50 000 clientes reales: casi
bien, y aun así solo **dos** valores llegaron a su MCV.

---

**04 → 4.** ¿Qué dos cosas fija `default_statistics_target = 100`, y cuántas filas muestrea
`ANALYZE`? 🟢

⏱️ **30 segundos** — Fija **hasta 100 valores en el MCV y hasta 100 tramos de histograma**, y hace
que `ANALYZE` muestree `300 × 100 = 30 000` filas.

🗣️ **2 minutos** — El "hasta" importa: son topes, no cantidades garantizadas. En
`pedido_lineas.producto_id` solo llegaron **56** valores al MCV con el objetivo en 100, y en
`pedidos.cliente_id` solo **dos**, porque con 47 988 clientes y 30 000 filas de muestra casi ninguno
aparece dos veces. El histograma sí sale lleno: 101 cotas, que son 100 tramos. La tercera
consecuencia, indirecta, es el tamaño de la muestra, y con él el coste del `ANALYZE` y la calidad de
todas las estimaciones.

🔬 **El detalle** — Categoría: **motor**. 30 000 filas son el **0,86 %** de los 3,5 millones de
`pedido_lineas`: la estimación de una tabla grande se apoya en una fracción minúscula, y de ahí que
dos `ANALYZE` seguidos den números distintos. Se sube **por columna** con `ALTER TABLE … ALTER
COLUMN … SET STATISTICS n`, no en global.

---

**04 → 5.** En §2, `pedidos.estado` tiene `histogram_bounds` nulo. ¿Por qué? 🟢

⏱️ **30 segundos** — Porque el histograma solo describe lo que el MCV **no** cubre, y los cinco
estados ya están todos en el MCV.

🗣️ **2 minutos** — El MCV y el histograma se reparten el trabajo: primero PostgreSQL mete en el MCV
los valores frecuentes con su frecuencia exacta, y con lo que queda fuera construye el histograma.
Si la columna tiene cinco valores y el objetivo permite hasta cien en el MCV, no queda nada que
describir y la columna sale nula. La foto se invierte con cardinalidad alta: en `cliente_id`, con 47
988 valores distintos, el MCV se vacía —solo dos entradas— y el histograma aparece con sus 101
cotas.

🔬 **El detalle** — Categoría: **motor**. Que sea nulo es información útil, no una laguna: te dice
que **toda igualdad sobre esa columna se estima desde el MCV**, es decir, bien, siempre que las
estadísticas estén al día. Es exactamente el caso de §6: el MCV de `estado` seguía diciendo que
`PENDIENTE` era el 12,15 % cuando ya era el 32 %, y el error fue de 3,4 veces.

---

**04 → 6.** Distingue selectividad de cardinalidad, y di cuál de las dos aparece en el `rows=` del
plan. 🟡

⏱️ **30 segundos** — La selectividad es una **fracción** entre 0 y 1; la cardinalidad es un
**recuento** de filas o de valores distintos. En el `rows=` aparece la cardinalidad.

🗣️ **2 minutos** — El planificador calcula primero la selectividad del filtro —la fracción de filas
que cree que lo pasarán— y la multiplica por las filas que cree que tiene la tabla; el resultado, ya
en filas, es el `rows=` del nodo. `most_common_freqs` guarda selectividades; `n_distinct` guarda una
cardinalidad de valores distintos. Confundirlas lleva al error clásico de leer `n_distinct` como si
fuera una probabilidad.

🔬 **El detalle** — Categoría: **convención de vocabulario**; el estándar no define ninguno de los
dos términos porque no define el planificador. La cuenta medida: `most_common_freqs` da `0,2945`
para `ENTREGADO`, y `0,2945 × 1 031 558 = 303 794`, que es el `rows=` que sale en el plan, contra
300 000 filas reales —**1,3 % de error**—.

---

**04 → 7.** Un histograma equipoblado y uno de rangos iguales: ¿en qué se diferencian, y por qué el
planificador quiere el primero? 🟡

⏱️ **30 segundos** — El equipoblado pone **la misma cantidad de filas** en cada tramo; el de rangos
iguales pone el mismo ancho de valores. El planificador quiere el primero porque estima contando
tramos.

🗣️ **2 minutos** — Con tramos equipoblados, cada tramo vale `1/n` del total por construcción, así
que estimar un rango es contar cuántos tramos cubre, y eso funciona igual de bien con datos sesgados
que con datos uniformes. Con rangos iguales, un solo tramo puede contener el 90 % de las filas y la
estimación se rompe justo donde más duele. Se nota en las cotas: no están repartidas de forma
regular, se **ensanchan donde hay menos filas por valor**.

🔬 **El detalle** — Categoría: **motor**. PostgreSQL guarda `default_statistics_target + 1` cotas, o
sea **101 cotas para 100 tramos**, y el histograma describe solo lo que el MCV no cubre. Los cubos
`singleton` de MySQL son el otro extremo —uno por valor distinto, el equivalente de un MCV—; SQLite
no tiene histograma por columna, solo las muestras de `sqlite_stat4`.

---

**04 → 8.** ¿Qué mide `correlation` en `pg_stats`? Nombra las dos cosas con las que se confunde. 🟡

⏱️ **30 segundos** — Mide, de `-1` a `1`, cuánto se parece el orden lógico de **una** columna a su
orden **físico** en disco. Decide cuántas páginas cree el motor que saltará en un `Index Scan`.

🗣️ **2 minutos** — Es una propiedad de la tabla, no de la consulta: si los valores están casi
ordenados en disco, bajar por el índice lee páginas contiguas y sale barato; si están dispersos,
cada fila es un salto y el planificador prefiere barrer. Las dos confusiones habituales son creer
que mide la **relación entre dos columnas** —eso no está en `pg_stats`, se declara con `CREATE
STATISTICS`— y dar por hecho que **insertar en orden garantiza correlación 1**.

🔬 **El detalle** — Categoría: **motor**. La segunda confusión tiene número medido: `pedidos.id` sale
con `correlation` **0,2225**, no 1, aunque la carga insertó los pedidos en orden de `id`; el
`UPDATE` que rellenó `pedidos.total` reescribió todas las filas y cada versión nueva se colocó donde
había sitio. **Un `UPDATE` masivo destruye la correlación física de la tabla entera**, no solo de la
columna que toca.

---

**04 → 9.** ¿El estándar SQL define `ANALYZE`, los histogramas o el planificador? Di qué hace cada
motor. 🟡

⏱️ **30 segundos** — No define ninguno de los tres. ISO/IEC 9075 dice **qué resultado devuelve una
consulta, no cómo se ejecuta**: estadísticas, planificación y `EXPLAIN` son territorio de motor
entero.

🗣️ **2 minutos** — PostgreSQL recoge histogramas por columna siempre que corras `ANALYZE`, y los
recoge solo con autovacuum en cuanto la tabla acumula `50 + 10 %` de modificaciones. MySQL refresca
sola la cardinalidad de los índices —muestreando veinte páginas—, pero los **histogramas hay que
crearlos a mano** desde 8.0, columna a columna, y nunca se refrescan solos. SQLite es el extremo:
**no tiene ninguna estadística hasta que alguien corre `ANALYZE`**, y hasta entonces planifica con
conjeturas fijas.

🔬 **El detalle** — Categoría: **motor**, con una aclaración honesta: la norma es de pago y no se han
verificado sus cláusulas en esta edición; la columna "Estándar" no es una laguna de verificación
sino la respuesta, porque la norma se ocupa del resultado. El corolario práctico es que **ninguna
respuesta sobre planificación se puede dar "en SQL"**: hay que decir en qué motor.

---

**04 → 10.** Distingue el error de §3 —`rows=22` contra 52— del error de §5 —`rows=80` contra 14
864—. 🟡

⏱️ **30 segundos** — El primero es un **valor atípico fuera del MCV**, estimado por la media de los
demás; el segundo es **correlación entre columnas**, dos selectividades correctas multiplicadas como
si fueran independientes.

🗣️ **2 minutos** — En `WHERE cliente_id = 311` la estimación sale de `(1 − Σ most_common_freqs) /
(n_distinct − n_mcv)`, o sea de la frecuencia media de los 47 986 clientes que no llegaron al MCV;
`CLI-00311` tiene 52 pedidos, muchos más que la media, y por definición ningún atípico fuera del MCV
se estima bien. En `WHERE producto_id = 48 AND precio_unit = 117.86` las dos estimaciones son
correctas por separado, y el error nace de multiplicarlas: el segundo filtro no descarta nada que el
primero no descartara ya. También se arreglan distinto: el primero, subiendo `STATISTICS` de esa
columna para que el valor entre en el MCV; el segundo, con `CREATE STATISTICS (dependencies)`.

🔬 **El detalle** — Categoría: **motor** los dos. La magnitud los separa: **2,4 veces** el atípico
contra **186 veces** la correlación, y por eso solo el segundo cambia la forma del plan. El primero
era inofensivo aquí porque sin índice los dos planes eran el mismo `Seq Scan`; el segundo eligió un
`Nested Loop` con 14 864 descensos por `pedidos_pkey` y 60 260 páginas.

---

**04 → 11.** ¿Por qué el `rows=` de `ENTREGADO` salió 303 794 y no 294 500, si `most_common_freqs`
dice 0,2945 y la tabla tiene un millón de filas? 🟠

⏱️ **30 segundos** — Porque el planificador no multiplica por `reltuples`, sino por `reltuples`
**reescalado al tamaño físico de hoy**: `0,2945 × 1 031 558 = 303 794`.

🗣️ **2 minutos** — `pg_class` anota dos cosas cuando corre `ANALYZE`: las filas estimadas
(`reltuples`, exactamente 1 000 000) y las páginas que ocupaba entonces (`relpages`, 14 893). En el
momento de planificar, PostgreSQL mira cuántas páginas ocupa la tabla **ahora** —15 363— y corrige
la densidad; como la tabla creció un 3 % desde el último `ANALYZE`, supone un 3 % más de filas. Es
una salvaguarda barata contra estadísticas ligeramente viejas, y funciona: el error final contra las
300 000 filas reales es del **1,3 %**.

🔬 **El detalle** — Categoría: **motor**. Ese reescalado corrige el **tamaño**, nunca las
**frecuencias**, y ahí está el límite: en §6, tras insertar 300 000 `PENDIENTE`, el `rows=` subió de
los 121 533 teóricos a 124 650 porque la tabla había crecido, pero seguía a 3,4 veces de las 420 000
reales, porque el MCV todavía creía que `PENDIENTE` era el 12,15 % del total.

---

**04 → 12.** Tu tabla tiene 40 millones de filas y recibe 200 000 modificaciones al día. Con el
autovacuum por defecto, ¿cuándo corre el próximo `ANALYZE`? Haz la cuenta. 🟠

⏱️ **30 segundos** — El umbral es `50 + 0,1 × 40 000 000 = 4 000 050` modificaciones; a 200 000 al
día, **dentro de veinte días**.

🗣️ **2 minutos** — El autovacuum dispara `ANALYZE` cuando `n_mod_since_analyze` supera
`autovacuum_analyze_threshold + autovacuum_analyze_scale_factor × filas`, que por defecto son `50` y
`0.1`. La consecuencia es contraintuitiva: **cuanto más grande es la tabla, más tarda en
refrescarse**, porque el umbral crece con ella. Veinte días son una eternidad para una tabla con
carga diaria, y todo ese tiempo el planificador trabaja con frecuencias del mes pasado. La
corrección no es subir el umbral sino bajar el factor **en esa tabla**, con `ALTER TABLE … SET
(autovacuum_analyze_scale_factor = 0.01)`, o programar el `ANALYZE` detrás de la carga.

🔬 **El detalle** — Categoría: **motor**, y valores por defecto verificados en este entorno:
`autovacuum_analyze_threshold = 50`, `autovacuum_analyze_scale_factor = 0.1`, `autovacuum_naptime =
60` segundos, que se suman al final. Con un millón de filas ya hacen falta **100 050**
modificaciones, así que una carga nocturna de 90 000 filas no lo dispara **nunca**.

---

**04 → 13.** Justifica con los dos números medidos en §4 por qué subir `default_statistics_target` a
1 000 en toda la base es mala idea. 🟠

⏱️ **30 segundos** — El `ANALYZE` de `pedido_lineas` pasó de **174 ms a 649 ms**, 3,7 veces, y el
MCV pasó de 56 valores a 115 con 1 001 cotas: **cada planificación recorre arrays diez veces más
largos**.

🗣️ **2 minutos** — El primer coste se paga en el mantenimiento y se ve venir. El segundo se paga en
**cada sentencia que se planifica**, incluidas las que no ganan nada con más estadísticas, y no
aparece en ningún informe de `ANALYZE`: aparece como tiempo de planificación repartido por toda la
base. La ganancia, además, es desigual: en `pedidos.estado`, con cinco valores, subir el objetivo no
cambia absolutamente nada, porque los cinco ya estaban en el MCV. Lo que sí tiene sentido es subirlo
**por columna**, con `ALTER TABLE … ALTER COLUMN … SET STATISTICS n`, en columnas con muchos valores
distintos y reparto desigual donde lo que importa se cae del MCV.

🔬 **El detalle** — Categoría: **motor**. Fíjate en que el MCV subió de 56 a **115**, no a 1 000: el
objetivo es un tope, y multiplicar por diez el objetivo no multiplica por diez lo que se guarda.
Pagas 3,7 veces el `ANALYZE` para duplicar el MCV. La medición se hizo dentro de `BEGIN … ROLLBACK`,
que deshace el `ANALYZE` y devuelve las estadísticas a 56 y 101.

---

**04 → 14.** La estadística extendida bajó el error de 186 veces al 11 %, y un segundo `ANALYZE` dio
13 099 en vez de 16 461. ¿Por qué no queda exacto, y por qué da igual? 🟠

⏱️ **30 segundos** — Porque sigue siendo una **muestra**: 30 000 filas de 3,5 millones. Y da igual
porque lo que cambia el plan es el orden de magnitud, no el decimal.

🗣️ **2 minutos** — `CREATE STATISTICS … (dependencies)` no guarda las filas que cumplen el filtro,
guarda un **grado de dependencia funcional** entre columnas, medido sobre la misma muestra que todo
lo demás. Cada `ANALYZE` vuelve a muestrear y el número baila: 16 461 en una transacción, 13 099 en
otra, contra las mismas 14 864 reales. Pero el planificador no necesita el número exacto: necesita
saber si son decenas o decenas de miles, porque eso es lo que decide entre `Nested Loop` y `Hash
Join`, y entre bajar por un índice y barrer la tabla. Con 80 elegía un `Nested Loop` ruinoso; con 13
099 o con 16 461 elige lo mismo, y lo correcto.

🔬 **El detalle** — Categoría: **motor**; ni las estadísticas extendidas ni `CREATE STATISTICS`
existen en el estándar, y de los otros tres motores del corpus **ninguno** tiene equivalente. Lo que
sí se lee es el grado: `pg_stats_ext` devolvió `{"3 => 5": 0.993600, "5 => 3": 0.890933}`, por
número de columna —`producto_id` es attnum 3 y `precio_unit`, attnum 5—. No llega a 1 porque el
corpus reasignó líneas a `PRD-00017` sin tocar su precio; la inversa vale 0,89 porque hay precios
repetidos.

---

**04 → 15.** ¿Que `ANALYZE` se pueda deshacer con un `ROLLBACK` es cosa del estándar o del motor? Di
qué hace cada uno y qué consecuencia tiene al escribir un capítulo de este corpus. 🟠

⏱️ **30 segundos** — Del **motor**. En PostgreSQL `ANALYZE` es transaccional y muere con el
`ROLLBACK`; en MySQL el DDL confirma de forma implícita y no hay vuelta atrás; en SQLite, en la
práctica tampoco.

🗣️ **2 minutos** — La diferencia no es cosmética: en PostgreSQL puedes envolver `ANALYZE`, `CREATE
STATISTICS`, `SET default_statistics_target` e incluso un `INSERT` de 300 000 filas en un `BEGIN …
ROLLBACK`, medir el plan de dentro y dejar la base exactamente como estaba. En MySQL, un `ANALYZE
TABLE … UPDATE HISTOGRAM` se queda puesto, así que el teardown es explícito: `ANALYZE TABLE … DROP
HISTOGRAM ON …` en la misma sesión, y después `information_schema.COLUMN_STATISTICS` vuelve a cero
filas.

🔬 **El detalle** — Categoría: **motor**, y es la regla de higiene de este corpus. Unas estadísticas
confirmadas cambiarían los planes de **todos los capítulos**, porque todos miden sobre la misma base
sembrada. De ahí que cada sesión que escribe vaya dentro de una transacción que se deshace, que el
teardown se escriba junto al recurso y no al final, y que al cerrar se compruebe el estado:
`pg_indexes` de `public` = **11** y `SELECT count(*) FROM pg_statistic_ext` = **0**.

---

**04 → 16.** Un compañero dice que MySQL "ya tiene histogramas como Postgres". Corrígelo con los dos
`EXPLAIN` de §7 y di qué hay que hacer a mano. 🟠

⏱️ **30 segundos** — Los tiene desde 8.0, pero **no los crea ni los refresca solo**. Sin histograma,
`WHERE estado='ENTREGADO'` se estimó en `rows=99568`; con él, en `rows=298229`, contra 300 000
reales.

🗣️ **2 minutos** — Los 99 568 no salen de ninguna estadística: son el **10 % de 995 684**, la
conjetura fija que MySQL aplica a una igualdad sobre una columna no indexada. Erraba tres veces.
Tras `ANALYZE TABLE pedidos UPDATE HISTOGRAM ON estado WITH 5 BUCKETS` el error baja al **0,6 %**.
Lo que hay que hacer a mano es exactamente eso, **columna a columna**, y volver a hacerlo cuando los
datos cambien, porque nada lo refresca. Lo que sí se refresca solo en InnoDB es la cardinalidad de
los **índices**, muestreando veinte páginas (`innodb_stats_persistent_sample_pages = 20`): por eso
`pedidos` declara 996 132 filas y 974 338 códigos distintos cuando son exactamente un millón de
cada.

🔬 **El detalle** — Categoría: **motor**. Los cubos `singleton` del JSON guardan **frecuencia
acumulada**, no frecuencia: `ENTREGADO` va de `0,05884` a `0,35836`, o sea `0,29952`, y `0,29952 ×
995 684 = 298 229`. El histograma se calcula en memoria hasta `histogram_generation_max_mem_size`
—20 MB por defecto—, y si no cabe, muestrea: dos creaciones anteriores del mismo histograma dieron
**299 372 y 297 679**.

---

**04 → 17.** Una consulta que iba a 50 ms tarda 8 segundos y nadie tocó el código ni el esquema. Da
tres hipótesis en orden de probabilidad y, para cada una, la consulta que la confirma. 🔴

⏱️ **30 segundos** — Primero, **estadísticas viejas**; segundo, **correlación entre columnas del
`WHERE`** que el planificador ignora; tercero, un **valor atípico fuera del MCV**. Las tres se
confirman comparando el `rows=` estimado con el real.

🗣️ **2 minutos** — El diagnóstico empieza siempre igual: `EXPLAIN (ANALYZE, BUFFERS)` y bajar al
nodo de más abajo cuyo `rows=` estimado se separe del real. (1) *Estadísticas viejas* — es lo más
probable si hubo una carga, una migración o una restauración: `SELECT relname, n_live_tup,
n_mod_since_analyze, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE relname = '…';` y
si `n_mod_since_analyze` es grande o `last_analyze` es viejo, un `ANALYZE` lo resuelve. (2)
*Correlación* — si el filtro toca dos columnas de la misma tabla y la diferencia es de dos órdenes
de magnitud: `SELECT b, count(*) FROM t WHERE a = … GROUP BY 1;` enseña si `a` determina `b`. (3)
*Atípico* — `SELECT most_common_vals, most_common_freqs, n_distinct FROM pg_stats WHERE
tablename='…' AND attname='…';` dice si el valor concreto de la consulta está en el MCV o se está
estimando por la media.

🔬 **El detalle** — Categoría: **motor**. El orden no es arbitrario: la primera hipótesis se arregla
en 150 ms y sin cambiar nada, la segunda necesita un objeto nuevo en el esquema y la tercera, tocar
`STATISTICS` de una columna. Y cuidado con la trampa de §1: **que el plan sea malo no significa que
falte un índice**. Allí `pedidos_pkey` existía y se estaba usando; el problema era el `rows=80` del
otro lado del `JOIN`.

---

**04 → 18.** Escribe la secuencia completa —SQL incluido— para diagnosticar y corregir un `Nested
Loop` que hace 14 864 `Index Searches` donde el plan presupuestó 80, sin crear un solo índice. 🔴

⏱️ **30 segundos** — Confirmar la dependencia entre las dos columnas del filtro con un `GROUP BY`,
declararla con `CREATE STATISTICS … (dependencies)`, correr `ANALYZE` y volver a medir el plan.

🗣️ **2 minutos** — La secuencia, entera y dentro de una transacción mientras se prueba:

```sql
-- 1. el síntoma: estimado contra real en el nodo de más abajo
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT count(*) FROM pedido_lineas WHERE producto_id = 48 AND precio_unit = 117.86;

-- 2. la hipótesis: ¿una columna determina la otra?
SELECT precio_unit, count(*) FROM pedido_lineas WHERE producto_id = 48 GROUP BY 1;

-- 3. la corrección
BEGIN;
CREATE STATISTICS st_linea_producto_precio (dependencies)
  ON producto_id, precio_unit FROM pedido_lineas;
ANALYZE pedido_lineas;

-- 4. la prueba: el grado medido y el plan nuevo
SELECT dependencies FROM pg_stats_ext WHERE statistics_name = 'st_linea_producto_precio';
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT count(*) FROM pedido_lineas WHERE producto_id = 48 AND precio_unit = 117.86;
ROLLBACK;   -- en producción, COMMIT
```

- **Paso 1** — el `EXPLAIN (ANALYZE)` es el único que da estimado y real a la vez; sin él no hay
  diagnóstico, solo opinión.
- **Paso 2** — el `GROUP BY` devuelve **una sola fila**, `117.86 | 14864`: `producto_id` determina
  `precio_unit`, así que el segundo filtro no descarta nada.
- **Paso 3** — `CREATE STATISTICS` no crea un índice ni ocupa espacio apreciable: añade una entrada
  que `ANALYZE` rellena. El `ANALYZE` posterior es obligatorio, porque el objeto nace vacío.
- **Paso 4** — `rows=80` pasa a `rows=16461` contra 14 864 reales, y el error cae de **186 veces a
  un 11 %**.

🔬 **El detalle** — Categoría: **motor**. Solo PostgreSQL lo tiene, y solo para columnas de **la
misma tabla**: `CREATE STATISTICS` no cruza tablas, así que un error de estimación en un `JOIN`
entre dos tablas no se arregla por aquí. Cuándo no usarlo: si el error viene de estadísticas viejas,
esto no lo arregla; corre `ANALYZE` primero y vuelve a medir.

---

**04 → 19.** Un despliegue restaura la base con `pg_restore` a las 3:00 y a las 3:05 el primer
informe tarda veinte minutos. Explica qué pasó, qué añadirías al despliegue y qué consulta te lo
habría dicho en diez segundos. 🔴

⏱️ **30 segundos** — `pg_restore` no restaura estadísticas: la base quedó **sin `pg_stats`**, y el
planificador tiró de valores por defecto codificados. Hay que correr `ANALYZE` al final del
despliegue.

🗣️ **2 minutos** — Un volcado trae datos y esquema, no el contenido de `pg_statistic`. Con la base
recién restaurada, el planificador no sabe cuántas filas hay ni cómo se reparten, así que estima con
constantes y elige planes al azar; el informe que en caliente hacía un `Hash Join` hace un `Nested
Loop` sobre millones de filas. Y **el autovacuum no te salva**: su umbral es `50 + 10 %` de las
filas *modificadas*, y una restauración no deja modificaciones pendientes que lo disparen a tiempo,
además de la siesta de 60 segundos. Al procedimiento de despliegue se le añade, como paso
obligatorio y bloqueante antes de abrir tráfico, `vacuumdb --analyze-only --all` o un `ANALYZE` por
base; sobre un millón de filas cuesta **150 ms**, así que no hay excusa de ventana.

🔬 **El detalle** — Categoría: **motor**. La consulta que lo habría dicho en diez segundos:

```sql
SELECT relname, n_live_tup, last_analyze, last_autoanalyze
  FROM pg_stat_user_tables ORDER BY n_live_tup DESC LIMIT 10;
```

Con `last_analyze` y `last_autoanalyze` a `NULL` en las tablas grandes, el diagnóstico está cerrado
antes de mirar un solo plan. La comprobación equivalente a nivel de columna es `SELECT count(*) FROM
pg_stats WHERE schemaname = 'public';` — cero filas significa que no hay nada que planificar con
criterio.

---

## Capítulo 05 — `EXPLAIN` y `EXPLAIN ANALYZE`

Las 22 preguntas de [`05`](05-explain-y-explain-analyze.md).

**05 → 1.** **¿En qué orden se lee un plan de ejecución, y cuál es el nodo que corre primero? 🟢**

⏱️ **30 segundos** — De dentro hacia fuera y de abajo hacia arriba: el nodo más indentado corre
primero y el de arriba del todo es el último, el que entrega el resultado.

🗣️ **2 minutos** — Un plan no es una lista de pasos, es un árbol: cada `->` abre un hijo y la
indentación marca la profundidad. Cada nodo pide filas a sus hijos y se las entrega a su padre, así
que el trabajo empieza en las hojas. En el plan de §2, el primero que corre es el `Index Scan` sobre
`clientes_codigo_key`, que saca una fila; el último, el `Aggregate` que devuelve el `52`. Leerlo de
arriba abajo, como un programa, es lo que impide ver dónde se va el tiempo.

🔬 **El detalle** — El orden de los hijos **no** es decorativo: el primero es el lado externo
(*outer*) y el segundo el interno (*inner*), el que se sondea, que en un `Hash Join` es el que se
vuelve tabla hash —por eso el motor pone ahí el lado pequeño—. Categoría: **motor**. Ni el formato
de árbol, ni la indentación, ni el `->` están en el estándar SQL; MySQL imprime su propio árbol con
`FORMAT=TREE` y SQLite un `SCAN` de una línea, así que la regla de lectura se aprende por motor.

---

---

**05 → 2.** **`cost=0.00..23270.00` son dos números. ¿Qué es cada uno, y en qué unidad están? 🟢**

⏱️ **30 segundos** — El primero es el coste hasta la **primera** fila y el segundo hasta la
**última**. No son milisegundos: son unidades arbitrarias del planificador.

🗣️ **2 minutos** — La unidad está anclada en `seq_page_cost`, que vale 1,0 y es lo que cuesta leer
una página del disco en secuencia; todo lo demás se mide contra eso. Un coste de 23 270 significa
"unas 23 270 veces lo que cuesta leer una página secuencial". Sirve para comparar dos planes de la
misma consulta —es exactamente lo que hace el planificador al elegir— y **no predice ningún
tiempo**. Hay dos números porque hay nodos que no entregan nada hasta terminar.

🔬 **El detalle** — El coste de primera fila es el que decide con un `LIMIT`: un `Sort` no suelta
nada hasta ordenarlo todo, así que su coste de primera fila es casi el de la última, mientras que un
`Seq Scan` empieza en 0,00. La prueba de que no son milisegundos está en §2: el `Seq Scan` marca
`cost=0.00..27640.00` y tardó 60,962 ms. Categoría: **motor** —la escala de MySQL es otra y SQLite
directamente no publica coste—, y "el coste está en milisegundos" es **convención** falsa.

---

---

**05 → 3.** **¿Qué diferencia hay entre `rows=` y `actual rows=`, y cuál de los dos no aparece sin
`ANALYZE`? 🟢**

⏱️ **30 segundos** — `rows=` es lo que el planificador **estima**; `actual rows` es lo que salió de
verdad. Sin `ANALYZE` solo existe el primero, porque la consulta no se ha ejecutado.

🗣️ **2 minutos** — Cada nodo lleva dos paréntesis: el primero es lo que el planificador creyó
—coste, filas, ancho— y el segundo lo que pasó: tiempo real, filas reales y `loops`. La estimación
es una predicción y puede fallar por órdenes de magnitud; lo real es medición. Por eso el primer
gesto al leer un plan medido es comparar los dos números del mismo nodo.

🔬 **El detalle** — `actual rows` va **promediado por iteración**, y por eso lleva decimales
(`rows=3.50 loops=999`); el total es el producto. Categoría: **motor**. En MySQL los dos números
aparecen en la misma línea con otra sintaxis —`(cost=100698 rows=99568) (actual time=… rows=300000
loops=1)`— y en SQLite no aparece ninguno, porque `EXPLAIN QUERY PLAN` no imprime ni coste ni filas.

---

---

**05 → 4.** **¿Qué mide `width=`, y de qué columnas? 🟢**

⏱️ **30 segundos** — Los bytes por fila que ese nodo entrega **hacia arriba**, y solo de las
columnas que propaga, no de la fila entera de la tabla.

🗣️ **2 minutos** — Es una media estimada por el planificador, no una medición. Sirve para dos cosas:
para calcular cuánta memoria hará falta si por encima hay un `Sort` o un `Hash`, y como pista de que
estás arrastrando columnas que nadie usa. Un `width=0` es normal en un `count(*)`, porque no hace
falta ninguna columna; en el `Hash Join` de §2 el ancho es 0 por eso mismo.

🔬 **El detalle** — `width` cambia según lo que pide la consulta, no según el DDL: la misma tabla
puede dar `width=8` cuando solo se propaga el `id` y mucho más si se pide `SELECT *`. Categoría:
**motor**: el nombre `width` y su cálculo son de PostgreSQL; MySQL no imprime nada equivalente en su
árbol.

---

---

**05 → 5.** **Nombra los dos nodos que forman siempre la pareja de un acceso por mapa de bits. 🟢**

⏱️ **30 segundos** — `Bitmap Index Scan` debajo y `Bitmap Heap Scan` encima. Nunca van por separado.

🗣️ **2 minutos** — El de abajo recorre el índice y construye un mapa de bits de **páginas**, no de
filas. El de arriba lee esas páginas en orden físico ascendente y vuelve a aplicar la condición, que
es lo que significa `Recheck Cond`. Si el mapa de bits es de páginas y no de filas, hay que
recomprobar: por eso la condición aparece dos veces en el plan.

🔬 **El detalle** — En el plan de §7 el `Bitmap Heap Scan` imprime `Heap Blocks: exact=2253`, que es
el caso bueno. Si el mapa no cabe en `work_mem`, el motor degrada a marcar páginas enteras, aparece
`Heap Blocks: lossy` y el `Recheck` empieza a descartar filas de verdad. Categoría: **motor**: los
dos nombres son de PostgreSQL; MySQL llama a algo parecido *Index Merge* y SQLite no tiene nada
equivalente, así que **los planes no se comparan nodo a nodo entre motores**.

---

---

**05 → 6.** **¿Qué significa `Rows Removed by Filter` y por qué es de lo primero que hay que mirar?
🟢**

⏱️ **30 segundos** — Filas que el nodo leyó y tiró a la basura porque no pasaban el filtro. Es el
trabajo que pagaste y no aprovechaste.

🗣️ **2 minutos** — Solo aparece con `ANALYZE`, porque es una medición. Lo que importa es la
proporción contra las filas que sí salieron: en §5, 546 874 descartadas para quedarse con 273 126 es
normal en un filtro poco selectivo, pero cuando son cientos de miles para devolver decenas, el nodo
está leyendo de más y ahí es donde entra un índice. Es también la señal de que una condición se
evalúa como `Filter` en vez de como `Index Cond`.

🔬 **El detalle** — En un plan paralelo va en la misma moneda que el resto: el `Rows Removed by
Filter: 233333` de §8 es **por proceso**, con `loops=3`, así que el total es el triple. Junto con
`Sort Method`, es uno de los dos sitios donde un plan confiesa que tira trabajo, y casi nadie los
nombra en una entrevista. Categoría: **motor**; el nombre exacto de la línea es de PostgreSQL.

---

---

**05 → 7.** **Distingue `EXPLAIN` de `EXPLAIN ANALYZE` en una frase, y di qué pasa si el segundo se
corre sobre un `DELETE`. 🟡**

⏱️ **30 segundos** — `EXPLAIN` pide el plan y no ejecuta nada; `EXPLAIN ANALYZE` ejecuta la consulta
y añade lo que pasó. Sobre un `DELETE`, **borra las filas de verdad**.

🗣️ **2 minutos** — `EXPLAIN` a secas es instantáneo y seguro: solo trae la mitad izquierda de los
números, las estimaciones. `EXPLAIN ANALYZE` corre la sentencia y por eso puede añadir `actual
time`, `actual rows`, `loops` y `Rows Removed by Filter`. Con un `INSERT`, `UPDATE`, `DELETE` o
`MERGE` eso significa que la escritura ocurre; no se simula. La forma segura es siempre `BEGIN;
EXPLAIN ANALYZE …; ROLLBACK;`, con el `ROLLBACK` tecleado antes de ejecutar nada.

🔬 **El detalle** — El `ROLLBACK` deshace el dato, no el trabajo: se escribe WAL, se ensucian páginas
—el plan de §4 lo enseña con `Buffers: shared hit=44 dirtied=1`— y la fila queda bloqueada hasta que
cierras la transacción, así que en producción no sale gratis aunque se deshaga. Categoría:
**motor**, y aquí los motores ni siquiera coinciden: MySQL 9.7.2 se niega a ejecutar la escritura y
responde `<not executable by iterator executor>`.

---

---

**05 → 8.** **Un nodo dice `actual time=0.001..0.001 rows=3.50 loops=999`. ¿Cuánto tardó y cuántas
filas devolvió de verdad? 🟡**

⏱️ **30 segundos** — Devolvió 3 499 filas —3,50 × 999— y tardó alrededor de un milisegundo en total,
porque los 0,001 ms son **por vuelta**.

🗣️ **2 minutos** — `loops` es el multiplicador de todo lo que va en ese paréntesis: tiempo y filas
están promediados por iteración. Los decimales del `rows` están precisamente porque es un promedio.
En el `Nested Loop` de §3, el hijo interno se ejecuta una vez por cada fila del externo, y el `Index
Searches: 999` lo confirma desde el otro lado: una bajada por el índice por pedido.

🔬 **El detalle** — Es la causa número uno de leer mal un plan: un nodo con `actual time=0.8
loops=5000` se comió cuatro segundos y en pantalla parece que tardó menos de uno. Y hay que
combinarlo con la otra regla: el tiempo de un nodo **incluye el de sus hijos**, así que para saber
qué cuesta por sí mismo hay que restar. Categoría: **motor**: `loops` es vocabulario de PostgreSQL,
aunque MySQL imprime también un `loops` en su `EXPLAIN ANALYZE` con el mismo sentido.

---

---

**05 → 9.** **Distingue `Index Cond` de `Filter`. ¿Cuál de los dos delata que el índice no cubre la
condición? 🟡**

⏱️ **30 segundos** — El `Index Cond` se resuelve bajando por el árbol del índice; el `Filter` se
evalúa sobre filas ya leídas. Ver un `Filter` donde esperabas un `Index Cond` delata que el índice
no cubre esa condición.

🗣️ **2 minutos** — Un `Index Cond` solo toca las filas que cumplen: el motor se posiciona en el
índice y recorre el rango. Un `Filter` es una condición que se comprueba después, fila a fila, sobre
lo que el nodo ya trajo, y todo lo que no pasa se cuenta en `Rows Removed by Filter`. Es la
distinción que más nota da en una entrevista, porque es la que conecta el plan con el DDL del
índice.

🔬 **El detalle** — El caso medido está en el `Merge Join` de §7: el `Index Scan` recorre
`pedidos_pkey` entero y **descarta 750 000 filas** con un `Filter: (estado = 'PAGADO')`, porque
`estado` no está en esa clave primaria. Categoría: **motor**: los dos rótulos son de PostgreSQL; en
MySQL la misma idea aparece como `Index lookup` frente a un nodo `Filter:` separado, y los planes
**no son comparables nodo a nodo**.

---

---

**05 → 10.** **¿Qué diferencia hay entre `Index Scan` e `Index Only Scan`, y qué línea del plan dice
si el segundo está funcionando de verdad? 🟡**

⏱️ **30 segundos** — El `Index Scan` baja por el índice y va al heap por cada fila; el `Index Only
Scan` resuelve con el índice y no toca el heap. La línea que hay que mirar es `Heap Fetches`.

🗣️ **2 minutos** — El `Index Only Scan` solo es posible cuando el índice cubre todas las columnas
que la consulta pide. Pero "cubre" no basta: PostgreSQL necesita además saber que la fila es visible
para todo el mundo, y eso lo dice el mapa de visibilidad. Si la página no está marcada como visible,
el motor va igualmente al heap a comprobarlo, y cada una de esas visitas se cuenta en `Heap
Fetches`.

🔬 **El detalle** — Por eso un `Index Only Scan` con `Heap Fetches` alto es un `Index Scan`
disfrazado: en §3 el nodo sobre `pedidos_pkey` saca 999 filas y marca `Heap Fetches: 999`, es
decir, va al heap por todas. Categoría: **motor**, y muy específico de PostgreSQL: el mapa de
visibilidad es consecuencia de su MVCC en el heap, y en InnoDB, donde la tabla **es** el índice
agrupado, el problema no se plantea igual.

---

---

**05 → 11.** **¿La palabra `EXPLAIN` y los nombres de los nodos los fija el estándar SQL o cada
motor? Di qué imprime cada uno de los tres. 🟡**

⏱️ **30 segundos** — Cada motor. `EXPLAIN` no está en el estándar: ni la palabra, ni el formato, ni
los nombres de los nodos.

🗣️ **2 minutos** — PostgreSQL usa `EXPLAIN [(opciones)]` e imprime `Seq Scan`, `Hash Join` o `Bitmap
Heap Scan`. MySQL usa `EXPLAIN [FORMAT=…]` y dice `Table scan`, `Nested loop inner join` o `Index
lookup`. SQLite usa `EXPLAIN QUERY PLAN` y responde con `SCAN`, `SEARCH` y `USE TEMP B-TREE` —y su
`EXPLAIN` a secas es otra cosa, el volcado de *bytecode* de su máquina virtual—. Tampoco coinciden
las opciones ni los formatos de máquina.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas, así que el capítulo lo
declara como "no verificado; no consta"; lo comprobable es que las tres implementaciones son
mutuamente incompatibles, que es justo lo que se espera de algo que la norma no fija. Consecuencia
práctica: **los planes no son comparables nodo a nodo entre motores** —no hay equivalencia de
nombres, ni de unidades de coste, ni de lo que cuenta un `rows`—, aunque el método de diagnóstico sí
se traslade. Categoría: **motor**, sin ninguna capa de estándar debajo.

---

---

**05 → 12.** **Explica por qué `BUFFERS` mide mejor el trabajo de una consulta que los milisegundos,
con los números de §5. 🟠**

⏱️ **30 segundos** — Porque las páginas no cambian entre ejecuciones y los milisegundos sí: dependen
de qué había en la caché.

🗣️ **2 minutos** — La misma consulta sobre `pagos`, dos veces seguidas, lee **8 232 páginas** las
dos veces: eso es el trabajo, y son unos 64 MB recorridos para contar 273 126 filas. Lo que cambia
es el reparto entre `hit` y `read` —la segunda vez, `shared hit=188 read=8044`— y el tiempo, 59,164
ms contra 57,328 ms. Esos casi dos milisegundos de diferencia no son información: no ha cambiado
nada en la consulta. Comparado con eso, el `Index Scan` de §4 resuelve lo suyo con cuatro páginas, y
esa es la comparación que decide si un índice sirve.

🔬 **El detalle** — 📝 Desde PostgreSQL 18, `BUFFERS` viene incluido con `ANALYZE` sin pedirlo; en
versiones anteriores había que escribirlo. `shared hit` es página encontrada en `shared_buffers` y
`shared read` es página pedida al sistema operativo, que puede seguir sirviéndola de su propia caché
—así que `read` tampoco es necesariamente disco—. Categoría: **motor**: la opción no existe en MySQL
ni en SQLite.

---

---

**05 → 13.** **¿Cuándo prefiere el motor un `Bitmap Heap Scan` a un `Index Scan` sobre el mismo
índice, y qué problema evita al hacerlo? 🟠**

⏱️ **30 segundos** — Cuando el número de filas es intermedio: demasiadas para un `Index Scan`, pocas
para un `Seq Scan`. Evita visitar la misma página del heap muchas veces.

🗣️ **2 minutos** — Un `Index Scan` visita el heap en el orden del índice, que respecto del disco es
aleatorio, así que puede volver una y otra vez a la misma página. El acceso por mapa de bits separa
las dos fases: primero marca las páginas que hacen falta y después las lee **una sola vez y en orden
físico ascendente**. En §7, el mismo `pedidos_pkey` que en §3 daba `Index Only Scan` pasa a `Bitmap
Heap Scan` en cuanto se piden 49 001 filas y una columna que el índice no tiene: 49 001 filas
repartidas en 2 253 páginas, y 12,3 ms en total.

🔬 **El detalle** — El precio es memoria: el mapa de bits vive en `work_mem`, y si no cabe el motor
degrada a marcar páginas enteras en lugar de filas; entonces aparece `Heap Blocks: lossy` y el
`Recheck Cond` pasa de ser una formalidad a descartar filas de verdad. Categoría: **motor**, y
además es una elección **por consulta**, no por índice: el mismo índice da los tres nodos según
cuántas filas y qué columnas se pidan.

---

---

**05 → 14.** **`Sort Method: external merge Disk: 9648kB`. ¿Qué te dice esa línea, y qué dos cosas
puedes hacer al verla? 🟠**

⏱️ **30 segundos** — Que la ordenación no cupo en memoria y se fue a un fichero temporal: 9,6 MB
escritos en disco. O subes `work_mem`, o reduces las filas antes de ordenar.

🗣️ **2 minutos** — El corpus corre con `work_mem = '8MB'`, y esa ordenación de 820 000 filas
necesitaba más. Cuando cabe, la línea dice `quicksort Memory: …` —o `top-N heapsort` si hay un
`LIMIT`—, y ese es el contraste que hay que buscar. Reducir filas antes de ordenar suele ser mejor
que subir memoria: filtrar antes, ordenar menos columnas, o dejar que un índice entregue las filas
ya ordenadas y así el `Sort` desaparece del plan.

🔬 **El detalle** — Subir `work_mem` no es gratis ni global: se reserva **por operación de ordenación
o hash y por conexión**, así que multiplicarlo por cien conexiones es una forma conocida de quedarse
sin memoria. En el plan de §7 el `Sort` aparece porque se forzó un `Merge Join` con `SET
enable_hashjoin = off`, y ese camino costó 876,399 ms contra los 294,761 ms del `Hash Join` que el
planificador elige solo. Categoría: **motor**: `Sort Method` es un rótulo de PostgreSQL.

---

---

**05 → 15.** **En un plan paralelo, `Parallel Seq Scan … rows=100000 loops=3`. ¿Por qué `loops=3` no
significa lo mismo que en el `Nested Loop` de §3? 🟠**

⏱️ **30 segundos** — Porque ahí no son tres iteraciones, son tres **procesos**: los dos *workers*
más el que los coordina.

🗣️ **2 minutos** — En un `Nested Loop`, `loops=999` quiere decir que el nodo se ejecutó 999 veces,
una por cada fila del lado externo. En un plan paralelo, el mismo campo cuenta cuántos procesos
ejecutaron ese subárbol. La aritmética de multiplicar se mantiene —`rows=100000 loops=3` son las 300
000 filas de `ENTREGADO`, y `Rows Removed by Filter: 233333` va en la misma moneda—, pero la lectura
cambia: no es repetición, es reparto.

🔬 **El detalle** — `Gather` es la costura: por debajo todo corre en paralelo, por encima ya no.
`Partial Aggregate` cuenta lo suyo en cada proceso y `Finalize Aggregate` suma los parciales. Hay
que mirar también `Workers Planned` contra `Workers Launched`: si el `max_parallel_workers` global
está agotado se lanzan menos y la consulta va más lenta sin que el plan cambie. La ganancia medida
fue 51,749 ms contra 96,317 ms en serie —1,9 veces, no 3—. Categoría: **motor**.

---

---

**05 → 16.** **Este corpus corre con `max_parallel_workers_per_gather=0`. Justifica la decisión y di
qué hay que hacer para enseñar un `Gather` sin romperla. 🟠**

⏱️ **30 segundos** — Porque si no, los planes dejan de ser reproducibles: el número de *workers*
depende de los núcleos de la máquina. Para enseñar un `Gather` se sube con `SET` en tu sesión y se
devuelve con `RESET`.

🗣️ **2 minutos** — Con el paralelismo encendido, el mismo `SELECT` sale como `Parallel Seq Scan` en
un portátil de ocho núcleos y como `Seq Scan` en uno de dos, así que ningún plan pegado en el corpus
valdría como evidencia: quien siguiera el texto vería otro árbol. Apagado en el `compose`, todos ven
lo mismo. La secuencia para mirarlo es `SHOW max_parallel_workers_per_gather` para dejar constancia
de dónde partes, `SET … = 2`, el `EXPLAIN (ANALYZE)` y `RESET` inmediatamente después.

🔬 **El detalle** — `SET` vale solo para tu sesión: las demás conexiones siguen viendo 0, lo que es
bueno para no molestar y malo para olvidarse. Si no devuelves el valor, los planes siguientes de esa
misma sesión ya no se parecerán a los del resto del corpus. Categoría: **convención del
laboratorio** montada sobre un parámetro de **motor**; el estándar no dice nada del paralelismo del
ejecutor. El resto de la configuración fija —`work_mem`, `random_page_cost`, `jit`— se comprueba con
la opción `SETTINGS`.

---

---

**05 → 17.** **Alguien te dice que un `Seq Scan` en el plan siempre es un error. Dale la refutación
con números. 🟠**

⏱️ **30 segundos** — No lo es. Para traer una fracción grande de la tabla, el `Seq Scan` es **más
barato** que el índice, porque lee páginas contiguas en vez de saltar al azar por el heap.

🗣️ **2 minutos** — La creencia viene de mirar planes de tablas pequeñas. Bajar por un índice para
traer el 30 % de una tabla sale más caro: cada fila es un salto aleatorio al heap y se acaba
visitando la misma página muchas veces. Lo que convierte un `Seq Scan` en problema no es existir,
sino la proporción: cuando `Rows Removed by Filter` es enorme comparado con las filas que salen. En
§5, 546 874 descartadas para 273 126 devueltas es un filtro poco selectivo y el `Seq Scan` está
bien; en §1, leer un millón de filas para devolver 52 sí era el problema, y con el índice adecuado
el mismo plan pasó de 109,598 ms a 0,092 ms.

🔬 **El detalle** — El propio planificador lo dice con el coste: entre `Index Scan`, `Bitmap Heap
Scan` y `Seq Scan` elige comparando costes de la misma consulta, y el punto de corte depende de
`random_page_cost`, que aquí vale 1,1 porque el almacenamiento es SSD. En un disco giratorio, con
4,0 por defecto, el mismo plan se inclinaría antes hacia el `Seq Scan`. Categoría: **convención**
falsa por un lado, **motor** por el otro: el punto de corte es un parámetro, no una ley.

---

---

**05 → 18.** **¿`EXPLAIN ANALYZE` sobre un `UPDATE` escribe en la tabla? Responde por separado para
PostgreSQL 18.6 y para MySQL 9.7.2, y di si alguna de las dos respuestas la impone el estándar. 🟠**

⏱️ **30 segundos** — En PostgreSQL **sí**: la escritura ocurre de verdad. En MySQL **no**: responde
`<not executable by iterator executor>`. El estándar no impone ninguna de las dos.

🗣️ **2 minutos** — Está medido en §4: dentro de un `BEGIN`, el `EXPLAIN ANALYZE UPDATE` sobre
`PED-00042` dejó el pedido en `ENVIADO` con `actualizado_en` puesto, y solo el `ROLLBACK` lo
devolvió a `PAGADO` con el campo nulo. El nodo `Update` marca `rows=0.00` porque un `UPDATE` sin
`RETURNING` no entrega filas hacia arriba —las que tocó se cuentan en el hijo— y `Buffers: shared
hit=44 dirtied=1` delata la página ensuciada. MySQL, en cambio, se niega a ejecutar la sentencia por
ese camino.

🔬 **El detalle** — Que difieran es la prueba de que esto es **motor**: `EXPLAIN` no está en ISO/IEC
9075, así que no hay nada que imponga un comportamiento u otro. La consecuencia operativa es la
regla: `BEGIN; EXPLAIN ANALYZE …; ROLLBACK;` con el `ROLLBACK` tecleado antes de ejecutar, y
sabiendo que el `ROLLBACK` deshace el dato pero no el coste —WAL, páginas sucias y la fila bloqueada
mientras dura la transacción—.

---

---

**05 → 19.** **Reconstruye la consulta que produjo este plan y di qué tabla tiene índice útil y cuál
no: `Aggregate` → `Hash Join (Hash Cond: p.cliente_id = c.id)` → `Seq Scan on pedidos p` y `→ Hash →
Index Scan using clientes_codigo_key on clientes c (Index Cond: codigo = …)`. 🔴**

⏱️ **30 segundos** — Es un `SELECT count(*) FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
WHERE c.codigo = '…'`. `clientes` tiene índice útil —`clientes_codigo_key`—; `pedidos` no tiene
ninguno por `cliente_id`.

🗣️ **2 minutos** — Cada pieza del plan corresponde a una del SQL. El `Aggregate` de arriba es el
`count(*)`; el `Hash Cond: (p.cliente_id = c.id)` es la condición del `ON`; el `Index Cond: (codigo
= …)` es el `WHERE` sobre `clientes`, resuelto por índice único. Y el `Seq Scan on pedidos` es lo
que falta: el motor no tiene por dónde entrar a `pedidos` por `cliente_id`, así que lee la tabla
entera —un millón de filas— y la sondea contra la tabla hash de una sola fila. El arreglo es un
índice sobre `pedidos (cliente_id)`: el plan se convierte en `Nested Loop` con `Index Only Scan` y
pasa de 109,598 ms a 0,092 ms.

🔬 **El detalle** — El lado que se vuelve tabla hash es el **interno**, el segundo hijo, y por eso el
motor pone ahí el lado pequeño: construir la hash con un millón de filas en lugar de con una sería
absurdo. Dejar ese índice cuesta 177 ms de construcción, ~22 MB de disco y una escritura extra por
cada `INSERT` en `pedidos`. Categoría: **motor**: en MySQL la misma consulta sale con `Nested loop`
sin que nadie cree nada, porque **InnoDB crea un índice automáticamente por cada clave foránea** y
PostgreSQL no; los planes de los dos motores no se comparan nodo a nodo.

---

---

**05 → 20.** **Un `Seq Scan` estima `rows=20500` y devuelve `actual rows=1366667`. Da **tres
hipótesis en orden de probabilidad** y, para cada una, la consulta o el comando con el que la
confirmarías. 🔴**

⏱️ **30 segundos** — Primero, estadísticas viejas. Segundo, que el predicado no sea una columna sino
una expresión, y no haya estadística que consultar. Tercero, columnas correlacionadas que el
planificador multiplica como si fueran independientes.

🗣️ **2 minutos** — La primera se comprueba mirando cuándo se analizó la tabla: `SELECT last_analyze,
last_autoanalyze, n_mod_since_analyze FROM pg_stat_user_tables WHERE relname = 'eventos_pedido';`.
Es la más probable y la más barata de arreglar. La segunda se ve en la línea `Filter` del propio
plan —si dice `((carga ->> 'origen'::text) = 'movil'::text)`, el predicado es una expresión— y se
confirma con `SELECT * FROM pg_stats WHERE tablename = 'eventos_pedido' AND attname = 'carga';`: no
hay nada sobre el resultado de esa expresión. La tercera se confirma comparando la estimación de
cada condición por separado con la del `AND`: si cada una acierta y la combinada falla por el
producto, están correlacionadas.

🔬 **El detalle** — El caso medido del capítulo es el segundo: `rows=20500` sale **idéntico** para
una consulta que devuelve 0 filas y otra que devuelve 1 366 667, porque es el 0,5 % de las 4 100 000
filas, la selectividad por defecto de una igualdad. No es un error de cálculo: es una constante
disfrazada de estimación. El arreglo —índice sobre la expresión, que trae su propia estadística, o
estadísticas extendidas para el tercer caso— es de [`04`](04-estadisticas-y-el-planificador.md), que
es el dueño de por qué salen esos `rows=`. Categoría: **motor**, incluida la cifra del 0,5 %.

---

---

**05 → 21.** **Te pasan un plan de 40 líneas de una consulta que tarda ocho segundos. Escribe la
secuencia de diagnóstico —qué miras, en qué orden y qué decides en cada paso— en cinco pasos como
máximo. 🔴**

⏱️ **30 segundos** — Uno: `Planning Time` contra `Execution Time`. Dos: de abajo arriba, el primer
nodo donde `rows` y `actual rows` se separan un orden de magnitud. Tres: qué hay en ese nodo
—`Filter`, `Rows Removed by Filter`, `loops`—. Cuatro: resto el tiempo de los hijos para saber quién
tarda. Cinco: decido índice, memoria o reescritura.

🗣️ **2 minutos** — El orden importa porque cada paso invalida los siguientes si sale mal. Si el
`Planning Time` es el que se come el tiempo, el problema no está en la ejecución. Si hay una brecha
grande entre estimado y real, todo lo que hay por encima de ese nodo está construido sobre un número
falso y tocar los nodos de arriba no sirve de nada. En el nodo culpable, `Index Cond` contra
`Filter` dice si el índice cubre la condición, `Rows Removed by Filter` dice cuánto trabajo se tira,
y `loops` recuerda que los tiempos y las filas están promediados por iteración. Solo al final se
decide: índice o índice distinto si el acceso es el problema, `work_mem` si aparece `Sort Method:
external merge` o `Heap Blocks: lossy`, y reescritura de la consulta si el nodo caro no debería
existir.

🔬 **El detalle** — Dos trampas concretas: el tiempo de un nodo **incluye el de sus hijos**, así que
el nodo con mayor `actual time` no es el culpable —en §2 el `Hash Join` marca 109,539 ms, pero
60,962 son del `Seq Scan` de debajo—; y con `loops` alto, el nodo que en pantalla parece tardar
0,001 ms puede ser el que se lo come todo. Si el tiempo no es estable entre ejecuciones, se repite
con `BUFFERS` y se mira páginas en lugar de milisegundos. Categoría: **motor**; el método se
traslada a MySQL —la brecha de §6 también aparece allí, `rows=99568` contra 300 000 reales— pero el
vocabulario no.

---

---

**05 → 22.** **Escribe la sesión completa, comando a comando, para medir el efecto de un índice
nuevo sobre `pedidos(estado, creado_en)` **sin dejar nada detrás**, y di qué comparas antes y
después. 🔴**

⏱️ **30 segundos** — Dentro de una transacción que se deshace: `BEGIN`, medir antes, `CREATE INDEX`,
medir después, `ROLLBACK`. Se compara la forma del plan, las páginas y el tiempo.

🗣️ **2 minutos** — La sesión es esta, con la misma consulta las dos veces:

```text
tienda=# BEGIN;
tienda=*# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM pedidos
tienda-*#  WHERE estado = 'ENTREGADO' AND creado_en >= DATE '2026-01-01';
tienda=*# CREATE INDEX idx_pedidos_estado_creado ON pedidos (estado, creado_en);
tienda=*# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM pedidos
tienda-*#  WHERE estado = 'ENTREGADO' AND creado_en >= DATE '2026-01-01';
tienda=*# ROLLBACK;
```

Lo que se compara, en este orden: **la forma del árbol** —si el `Seq Scan` se convirtió en `Index
Only Scan` o en el par `Bitmap Index Scan` + `Bitmap Heap Scan`—; **si la condición pasó de `Filter`
a `Index Cond`**, con lo que `Rows Removed by Filter` debería caer a cero o casi; **las páginas de
`Buffers`**, que es la medida que no depende de la caché; y solo al final el `Execution Time`.
También se anota el tiempo que tardó el `CREATE INDEX`, porque es parte del precio.

🔬 **El detalle** — Funciona porque PostgreSQL tiene **DDL transaccional**: un `CREATE INDEX` no
concurrente se deshace con el `ROLLBACK` como cualquier otra sentencia, y por eso no queda nada. Dos
avisos: **`CREATE INDEX CONCURRENTLY` no sirve aquí**, porque no puede correr dentro de una
transacción; y el índice creado así toma un bloqueo sobre `pedidos` que bloquea las escrituras
mientras dura la transacción, así que en producción la medición se hace en una réplica o en una
copia. Categoría: **motor**, y de los que más separan: en MySQL 9.7.2 el DDL **no** es transaccional
y ese mismo `CREATE INDEX` se queda puesto aunque hagas `ROLLBACK`.

---

## Capítulo 06 — Cuándo el índice no se usa

Las 20 preguntas de [`06`](06-cuando-el-indice-no-se-usa.md).

**06 → 1.** **Enumera las seis razones por las que un índice existente no se usa, en una frase cada
una. 🟢**

⏱️ **30 segundos** — La columna va envuelta en una función o una expresión; el filtro no nombra el
prefijo izquierdo del índice compuesto; el filtro no es selectivo y barrer sale más barato; el
presupuesto del planificador está mal; el índice no es aplicable en ese contexto —parcial,
parámetro, `OR`, colación, índice inválido—; y el índice se usa y aun así pierde por la vuelta al
heap.

🗣️ **2 minutos** — Lo que convierte la lista en un método es el orden en que se descartan, y son
cuatro preguntas sobre el plan: ¿aparece el nombre del índice? Si no, es una de las tres primeras
familias —el `WHERE`, el prefijo o la aplicabilidad—. Si aparece, ¿la condición está en `Index Cond`
o en `Filter`? Después, ¿`rows=` y `actual rows` se parecen? Y por último, cuántas páginas se
leyeron para las filas que salieron. Cada razón tiene una señal distinta: `Filter` sobre un `Seq
Scan` para la primera, un `Index Searches` mucho mayor que 1 para la segunda, un `Rows Removed by
Filter` bajo respecto de las filas que salen para la tercera, la brecha entre estimado y real para
la cuarta, y `Heap Fetches` alto para la sexta.

🔬 **El detalle** — Categoría: **motor**, las seis. ISO/IEC 9075 no define índices ni planificador,
así que ninguna se puede defender diciendo "lo manda el estándar". Y el matiz que sube la nota: **en
dos de las seis no hay nada que arreglar en el índice**. En la tercera el motor tiene razón —273 126
filas de 820 000 no se sacan por índice— y en la sexta el índice funciona y lo que falta es un
`VACUUM`. Empezar por "voy a crear un índice" falla en dos casos de seis, y en un tercero —el
presupuesto— crea índices que tapan el síntoma.

---

**06 → 2.** **¿Qué línea del plan delata que la condición se evaluó sobre filas ya leídas en vez de
resolverse bajando por el índice? 🟢**

⏱️ **30 segundos** — La línea `Filter:`, con su `Rows Removed by Filter` debajo. Si la condición
estuviera resuelta por el índice, aparecería como `Index Cond:`.

🗣️ **2 minutos** — La distinción es la que más nota da al leer un plan. Un `Index Cond` se resuelve
bajando por el árbol: el motor solo toca las entradas que cumplen la condición. Un `Filter` se
evalúa sobre filas **ya leídas**, así que cada fila descartada es trabajo hecho y tirado, y eso es
lo que cuenta `Rows Removed by Filter`. Ver un `Filter` donde esperabas un `Index Cond` significa
que el índice no cubre esa condición: puede ser que la columna vaya dentro de una función, que el
índice sea otro, o que esa columna no esté en él.

🔬 **El detalle** — Medido en el bloque: en `03` §4, el índice parcial resuelve `estado = 'ANULADO'`
**sin línea `Filter`**, porque la condición la garantiza la definición del índice; el índice
completo sobre `cliente_id` resuelve la misma consulta con `Filter: (estado = 'PENDIENTE')` y `Rows
Removed by Filter: 46`. Categoría: **motor**. MySQL imprime lo mismo con otro vocabulario —`Filter:`
frente a `Index lookup on … using …`— y SQLite no lo distingue: su `EXPLAIN QUERY PLAN` dice
`SEARCH` cuando usa el índice y `SCAN` cuando no, sin decir qué parte del predicado resolvió.

---

**06 → 3.** **¿Qué significa `Index Searches: 51` en un plan, y qué valor querrías ver? 🟢**

⏱️ **30 segundos** — Cuántas veces el motor bajó desde la raíz del árbol del índice. Quiero ver 1:
significa que las entradas que buscaba estaban en un solo tramo contiguo.

🗣️ **2 minutos** — Es la cifra que delata que falta el prefijo izquierdo. Con un índice sobre
`(producto_id, cantidad)`, un filtro por `producto_id` baja una vez y lee entradas seguidas; un
filtro solo por `cantidad` obliga al motor a hacer *skip scan*: saltar de un valor de `producto_id`
al siguiente buscando `cantidad = 5` en cada tramo. Con 5 000 productos eso no es saltar, es
recorrer el índice: 51 bajadas y **2 702 de sus 3 072 páginas, el 88 %**.

🔬 **El detalle** — 📝 El *skip scan* de B-tree llegó en **PostgreSQL 18**; hasta la 17 ese plan era
un `Seq Scan` limpio y el índice no aparecía. Cambia el síntoma y no el consejo, y por eso hay que
saber leer `Index Searches`: es lo único que distingue un índice que sirve de uno que aparece en el
plan y no sirve. La asimetría con el índice invertido lo demuestra: `(cantidad, producto_id)`
filtrado por `producto_id` da **7** bajadas, porque delante solo hay siete valores de `cantidad`.
Categoría: **motor**; MySQL tiene *skip scan* desde 8.0.13 y SQLite no lo tiene.

---

**06 → 4.** **¿Qué es la eliminación de particiones, y de qué depende que ocurra? 🟢**

⏱️ **30 segundos** — Que el planificador descarte particiones enteras porque no pueden contener
filas que cumplan el filtro. Depende de que la consulta filtre por la clave de particionado.

🗣️ **2 minutos** — Si `eventos_pedido` está partida por rango de `ocurrido_en` y la consulta filtra
por `ocurrido_en`, el motor sabe por la definición de cada partición qué rangos puede haber dentro y
descarta las que no encajan **antes de mirar ningún índice**; en el plan se ve porque solo aparecen
las particiones que quedaron. Si el filtro es por otra columna —`estado`, `pedido_id`— no puede
descartar ninguna, y la consulta recorre todas, cada una con su propio índice. De ahí la regla: el
particionado paga cuando la clave de particionado es la que se filtra casi siempre.

🔬 **El detalle** — Hay dos momentos en que puede ocurrir: al planificar, cuando el valor está
escrito en la consulta, y al ejecutar, cuando llega en un parámetro o de un join —lo que PostgreSQL
llama eliminación en tiempo de ejecución—. Es el mismo problema del índice parcial con `$1`: lo que
no se conoce al planificar, no se puede descartar al planificar. Categoría: **motor**; el
particionado declarativo no está en ISO/IEC 9075, PostgreSQL 18.6 lo tiene por rango, lista y hash,
MySQL 9.7.2 lo tiene con límites propios, y **SQLite no lo tiene**.

---

**06 → 5.** **Distingue la razón 3 —el filtro no es selectivo— de la razón 4 —el presupuesto está
mal—, y di cuál de las dos es un error del motor. 🟡**

⏱️ **30 segundos** — En la razón 3 el número es bueno y la decisión es correcta: pasan tantas filas
que barrer sale más barato. En la razón 4 el número es falso, así que la decisión es racional y
pésima. **Ninguna de las dos es un error del motor.**

🗣️ **2 minutos** — Se distinguen mirando el mismo sitio: la pareja `rows=` contra `actual rows`. Si
se parecen y el filtro deja pasar una fracción grande de la tabla, es la razón 3 y el arreglo no es
un índice: es devolver menos filas, o aceptar que ese informe lee la tabla entera porque pregunta
por la tabla entera. Si se separan por órdenes de magnitud, es la razón 4, y el arreglo está en las
estadísticas: `ANALYZE`, una estadística extendida, o asumir que una expresión no tiene estadística
que consultar.

🔬 **El detalle** — Los dos casos medidos, para no confundirlos nunca: razón 3, `metodo = 'EFECTIVO'`
con 273 126 filas de 820 000 y 8 232 páginas secuenciales —un índice tendría que hacer 273 126
visitas al heap—; razón 4, `rows=80` contra 14 864 reales en `03/04` §1, que produjo un `Nested
Loop` con 14 864 bajadas y 60 260 páginas donde el plan correcto usa 29 167. En la razón 4 el
arreglo no crea índices: declarar la dependencia con `CREATE STATISTICS` bajó el error **de 186
veces a un 11 %**. Categoría: **motor** las dos; el estándar no define ni modelo de costes ni
estadísticas.

---

**06 → 6.** **`WHERE creado_en::date = DATE '2026-01-01'` no usa el índice sobre `creado_en`. Da la
reescritura que sí lo usa y di qué cuesta cada una de las dos soluciones posibles. 🟡**

⏱️ **30 segundos** — La reescritura es el rango: `creado_en >= DATE '2026-01-01' AND creado_en <
DATE '2026-01-02'`. Es gratis y usa el índice tal cual. El índice funcional solo hace falta cuando
la expresión es el criterio de negocio de verdad.

🗣️ **2 minutos** — El motor no sabe que `creado_en::date` se deriva de `creado_en`: un índice guarda
la columna, no el resultado de una función sobre ella, así que la condición cae a `Filter` sobre un
`Seq Scan`. Las dos soluciones tienen precios distintos. Reescribir como rango no cuesta nada: el
índice existente pasa a resolver la condición en `Index Cond`. Crear un índice funcional cuesta
disco, tiempo de construcción y **una evaluación de la expresión en cada `INSERT` y en cada
`UPDATE`** de esa columna. Con una fecha, reescribir gana siempre; el funcional se paga cuando la
expresión no se puede deshacer, como comparar correos sin distinguir mayúsculas.

🔬 **El detalle** — Medido en `03` §5 con el caso hermano: `lower(email)` daba un `Seq Scan` de 618
páginas y **17,522 ms**, y con `CREATE INDEX … (lower(email))` —2448 kB y 134,664 ms de
construcción— pasó a 4 páginas y **0,041 ms**. El detalle que casi nadie dice: **la expresión del
índice y la del `WHERE` tienen que coincidir exactamente**; `upper(email)` o `lower(trim(email))`
son otras expresiones y no lo usan. Categoría: **motor**; PostgreSQL 18.6 y SQLite 3.53.4 tienen
índices de expresión nativos y MySQL 9.7.2 los tiene desde 8.0.13 como *functional key part*, con la
expresión entre dos paréntesis.

---

**06 → 7.** **¿Qué diferencia hay entre un índice que no aparece en el plan y uno que aparece y no
ayuda? Di qué mirarías en cada caso. 🟡**

⏱️ **30 segundos** — Si no aparece, el problema está en cómo está escrita la consulta o en la
aplicabilidad del índice; si aparece y no ayuda, el problema está en la vuelta al heap o en un
presupuesto falso.

🗣️ **2 minutos** — Cuando no aparece se mira el `WHERE`, en este orden: ¿hay una función o una
conversión alrededor de la columna? ¿El filtro nombra la primera columna del índice? ¿El índice es
parcial y el predicado no se puede demostrar? ¿Hay un `OR` con una rama sin índice? Cuando sí
aparece se dejan de mirar las columnas y se miran las páginas: `Heap Fetches` en un `Index Only
Scan`, `Heap Blocks` en un `Bitmap Heap Scan`, y la relación entre páginas leídas y filas devueltas.
Son dos investigaciones distintas, con dos herramientas distintas.

🔬 **El detalle** — El caso que rompe la regla y hay que nombrar: con *skip scan*, el índice
**aparece** y el problema sigue siendo del `WHERE`. Ahí la señal no es el heap, es `Index Searches`:
51 bajadas y el 88 % de las páginas del índice, con 190,789 ms contra los 167,704 ms del barrido que
el motor descartó. Categoría: **motor**. Y una consecuencia práctica: la pregunta *"¿sale mi índice
en el plan?"* dejó de ser suficiente en PostgreSQL 18.

---

**06 → 8.** **¿La conversión implícita de tipos tapa el índice por igual en PostgreSQL 18.6 y en
MySQL 9.7.2? Responde por separado y di si eso lo fija el estándar. 🟡**

⏱️ **30 segundos** — No por igual. En MySQL 9.7.2 es el caso clásico: comparar una columna de texto
con un número convierte **la columna** y el índice deja de servir. En PostgreSQL 18.6 casi no pasa,
porque casi no hay conversiones implícitas de ese tipo: la consulta **falla con error** en vez de
convertir.

🗣️ **2 minutos** — En MySQL, `WHERE codigo = 42` sobre una columna `VARCHAR` es válido: el motor
aplica sus reglas de conversión, convierte cada valor de la columna a número y compara, así que el
orden del índice deja de ser útil y la consulta acaba recorriendo la tabla. En PostgreSQL, `codigo =
42` no tiene operador —`text = integer` no existe— y la respuesta es un error de tipos en vez de un
plan lento. Eso hace que la razón "conversión implícita" sea de MySQL mucho más que de PostgreSQL, y
que la lección sea la contraria de lo que parece: **el motor que te da un error te está haciendo un
favor**.

🔬 **El detalle** — El estándar **no lo fija**: ISO/IEC 9075 define reglas de compatibilidad de
tipos, pero no qué plan se elige, y el comportamiento observable aquí es puro motor. En PostgreSQL
sí quedan casos donde la conversión aparece y hay que mirarla —comparar una columna `bigint` con un
literal de otro tipo numérico, o el `::date` de la pregunta 6—, y en SQLite el problema es de otra
familia: su tipado es por afinidad, así que el valor puede acabar comparándose como texto sin que
nadie avise, que es el caso medido de `total > 5000` con 30 419 filas de diferencia entre motores.
No he verificado ninguna cláusula del estándar para esta respuesta.

---

**06 → 9.** **Distingue el `Heap Fetches` alto de un `Index Only Scan` del `Heap Blocks` alto de un
`Bitmap Heap Scan`: ¿qué se toca en cada caso? 🟡**

⏱️ **30 segundos** — `Heap Fetches` alto es un mapa de visibilidad atrasado: se toca `VACUUM`, no el
índice. `Heap Blocks` alto son páginas de la tabla que hay que leer porque las filas están
desperdigadas: se toca el orden físico o la forma del acceso.

🗣️ **2 minutos** — Un `Index Only Scan` promete no ir a la tabla, y solo puede cumplirlo si el
*visibility map* dice que la página entera es visible para todos; cada vez que no lo dice, va al
heap y lo cuenta en `Heap Fetches`. Un `Bitmap Heap Scan`, en cambio, **siempre** va al heap: lo que
hace es ir una vez por página y en orden físico, y `Heap Blocks: exact=N` dice cuántas páginas
fueron. El primero es un problema de mantenimiento; el segundo, un dato sobre la dispersión de las
filas que buscas.

🔬 **El detalle** — Medido: en `03` §6, un `Index Only Scan` con **`Heap Fetches: 52` de 52 filas**,
porque `pedidos` tiene `relallvisible = 0` de 10 770 páginas y las tablas de este corpus nunca
pasaron por `VACUUM`; con el mapa al día, el mismo plan leería 3 páginas en vez de 21. En `05` §7,
un `Bitmap Heap Scan` con **`Heap Blocks: exact=2253`** para 49 001 filas, resuelto en 12,298 ms. Y
el tercer caso, que es el que descoloca: `Heap Blocks: lossy` significa que el mapa de bits no cupo
en `work_mem` y el motor marcó páginas enteras, así que el `Recheck Cond` descarta filas de verdad.
Categoría: **motor**; nada de esto existe en InnoDB, donde el índice secundario lleva la clave
primaria y la "vuelta a la tabla" es otra bajada por el índice agrupado.

---

**06 → 10.** **Un compañero quiere `FORCE INDEX` para arreglar un plan. Dale dos argumentos en
contra, di qué tiene PostgreSQL 18.6 en su lugar, y di si el estándar dice algo sobre forzar un
índice. 🟠**

⏱️ **30 segundos** — Primero: un `hint` fija el plan **y la equivocación**, así que cuando los datos
cambien seguirá forzando el plan de hoy. Segundo: tapa el diagnóstico, y el problema de verdad casi
siempre es una de las seis razones. PostgreSQL no tiene `hint`: tiene los `enable_*` de sesión, que
sirven para medir, no para arreglar.

🗣️ **2 minutos** — El argumento honesto no es "los `hint` son malos": es que un `hint` es una
decisión congelada en el código sobre datos que se mueven. El índice que hoy gana con 52 filas
pierde cuando ese cliente tenga 200 000, y nadie va a revisar el `hint`. En PostgreSQL lo que hay es
`SET enable_indexscan = off`, `enable_bitmapscan`, `enable_seqscan` y compañía, que son de sesión y
existen para **medir el camino que el motor descartó**; `enable_seqscan = off` además no prohíbe el
barrido, lo encarece con una constante, así que el plan sigue siendo posible. Se devuelven con
`RESET`.

🔬 **El detalle** — Categoría: **motor**, y de las que más separan. MySQL 9.7.2 tiene `FORCE INDEX`,
`IGNORE INDEX` e índices invisibles; SQLite tiene `INDEXED BY` y `NOT INDEXED`; PostgreSQL no tiene
ninguno en el núcleo —hay una extensión, `pg_hint_plan`, que no es parte del motor—. El estándar no
dice nada de esto. La concesión que hay que hacer para no sonar dogmático: un `hint` es defendible
como **parche temporal con fecha**, cuando hay un incidente en curso y el arreglo real es una
estadística que tarda en llegar; lo que no es defendible es dejarlo sin un comentario que diga
cuándo se revisa.

---

**06 → 11.** **Justifica con los números de §4 por qué un índice sobre `pagos.metodo` no serviría
para `WHERE metodo = 'EFECTIVO'`. 🟠**

⏱️ **30 segundos** — Porque `metodo = 'EFECTIVO'` deja pasar 273 126 filas de 820 000, un 33 %. El
barrido lee 8 232 páginas en secuencia; el índice tendría que hacer 273 126 visitas al heap. No hay
forma de que gane.

🗣️ **2 minutos** — La comparación se hace en la moneda que no depende de la caché, que son páginas.
El `Seq Scan` medido imprime `Buffers: shared read=8232`: 8 232 páginas de 8 kB, unos 64 MB leídos
en orden, que es lo más barato que sabe hacer un disco. El acceso por índice tendría que bajar por
el árbol y luego visitar el heap una vez por fila, y esas visitas son saltos al azar; incluso
pasando por un mapa de bits, tocaría casi todas las páginas de la tabla igual, más las del índice.
La cifra que lo cierra no es el porcentaje: es `Rows Removed by Filter: 546874` contra las 273 126
que salen, que es un filtro que casi no filtra.

🔬 **El detalle** — El número redondo que se recita —"a partir del 10 % ya no sirve"— es
**convención**: no hay umbral fijo, hay un modelo de costes con `random_page_cost` y
`seq_page_cost`, que en este laboratorio valen 1,1 y 1,0. Lo que sí es método es comprobarlo en vez
de creerlo: con `SET enable_indexscan = off` y `enable_bitmapscan = off` se mide el otro camino y se
comparan páginas. Categoría: **motor**; el estándar no define modelo de costes, y los tres motores
del corpus deciden esto cada uno con su aritmética.

---

**06 → 12.** **Explica por qué el índice parcial de `ANULADO` deja de usarse cuando el valor llega
en un parámetro, y qué comando te lo confirma sin adivinar. 🟠**

⏱️ **30 segundos** — Porque con el valor en un parámetro el planificador no puede demostrar que el
`WHERE` de la consulta implica el del índice: no sabe qué vale `$1` cuando planifica. Lo confirma
`EXPLAIN (GENERIC_PLAN)` sobre la sentencia con `$1`.

🗣️ **2 minutos** — Un índice parcial solo se usa si el motor **prueba** la implicación. Con `estado
= 'ANULADO'` escrito en la consulta, la prueba es trivial y el plan usa el parcial sin línea
`Filter`. Con `estado = $1`, el valor no existe todavía. PostgreSQL planifica una sentencia
preparada las primeras veces con los valores reales —plan personalizado— y luego decide si le sale
más barato guardar un **plan genérico** y reutilizarlo; desde el momento en que lo guarda, el
parcial desaparece del plan sin que nadie haya tocado el código. Eso es el "en mi máquina sí se
usaba" más común que existe: en la consola se escribe el literal, y en la aplicación va un
parámetro.

🔬 **El detalle** — Las dos herramientas: `EXPLAIN (GENERIC_PLAN) SELECT … WHERE estado = $1`, que
planifica sin ejecutar y sin valores, y `plan_cache_mode`, que fuerza `force_custom_plan` o
`force_generic_plan` para ver las dos caras. Medido en `03` §4 está el lado literal: 0,024 ms con el
parcial contra 0,057 ms con el índice completo y `Rows Removed by Filter: 46`. **El caso del
parámetro no lo he medido en una sesión nueva**, y por eso en el capítulo no hay plan pegado de él.
Categoría: **motor**; los índices parciales no existen en MySQL 9.7.2 —`ERROR 1064`— y sí en SQLite
3.53.4.

---

**06 → 13.** **Con `(producto_id, cantidad)` y un `WHERE` solo por `cantidad`, el índice aparece en
el plan y la consulta va más lenta que sin él. Explica el mecanismo y di cuánto, con las dos cifras.
🟠**

⏱️ **30 segundos** — El motor hace *skip scan*: salta de un valor de `producto_id` al siguiente
buscando `cantidad = 5` en cada tramo. Son **51 bajadas** y el **88 %** de las páginas del índice, y
sale peor que barrer: **190,789 ms contra 167,704 ms**.

🗣️ **2 minutos** — El índice está ordenado por `producto_id` y luego por `cantidad`, así que todas
las líneas con `cantidad = 5` están desperdigadas por el árbol: hay un puñado dentro de cada uno de
los 5 000 productos. El *skip scan* recorre esos tramos uno a uno; con pocos valores delante es un
ahorro, y con 5 000 es leer el índice entero y después ir al heap igual. El planificador lo eligió
porque le salía un 14 % más barato en coste estimado —64 421 contra 72 917— y se equivocó: el coste
es un modelo, no una medida.

🔬 **El detalle** — 📝 Hasta PostgreSQL 17 ese plan era un `Seq Scan` y el índice no aparecía, que es
como lo cuenta casi toda la documentación que vas a encontrar por internet. El consejo no cambia y
la señal sí: hay que mirar `Index Searches` y las páginas, no si el nombre del índice sale. La
prueba de que es la selectividad y no el *skip scan* en sí: el índice invertido, `(cantidad,
producto_id)`, filtrado por `producto_id` hace **7** bajadas, porque delante solo hay siete valores
de `cantidad`. Categoría: **motor**; MySQL tiene *skip scan* desde 8.0.13 y SQLite no.

---

**06 → 14.** **Tienes una tabla con cinco índices y 10 000 `INSERT` por minuto. Haz la cuenta del
coste de escritura y di qué moneda usarías para medirlo de verdad. 🟠**

⏱️ **30 segundos** — Cinco índices por 10 000 filas son **50 000 escrituras de índice por minuto**,
además de las de la tabla. Y se mide en **registros de WAL**, con `EXPLAIN (WAL)`, porque es la
única moneda que no depende de qué había en la caché.

🗣️ **2 minutos** — Cada `INSERT` escribe la fila en la tabla y una entrada en **cada** índice, y
todo eso pasa por el WAL, que es lo que se replica y lo que se sincroniza a disco. Los milisegundos
de un `INSERT` bailan según la caché y el disco; los registros de WAL no. La cuenta hay que saber
hacerla en voz alta, y hay que añadirle lo que no se ve: ese WAL viaja a las réplicas, y los índices
se comen su parte de `shared_buffers`, que se la quitan a otro.

🔬 **El detalle** — Medido en `03` §7, sobre `pedidos`: cien mil `INSERT` escriben **303 976**
registros de WAL con la tabla sin índices propios y **504 640** con dos índices encima —200 664 más,
o sea **dos por fila, uno por índice**—, y el nodo `Insert` pasa de 447 ms a 723 ms, un 62 % más.
Extrapolar de dos índices a cinco es aritmética, no medición, y conviene decirlo así. Categoría:
**motor**: el WAL es de PostgreSQL, InnoDB tiene su *redo log* y su *change buffer* —que amortigua
justamente esto en índices secundarios no únicos— y SQLite tiene su propio WAL. El estándar no dice
nada de escrituras.

---

**06 → 15.** **¿Por qué un `UPDATE` puede no pagar nada por los índices de la tabla y otro pagar por
todos? 🟠**

⏱️ **30 segundos** — Porque en PostgreSQL un `UPDATE` que no toca ninguna columna indexada puede ser
**HOT** y no escribir en ningún índice; en cuanto toca una columna indexada, hay que escribir en
**todos** los índices de la tabla, no solo en el de esa columna.

🗣️ **2 minutos** — El motivo es que un `UPDATE` de PostgreSQL crea una versión nueva de la fila en
otro sitio, así que su dirección física cambia y los índices apuntaban a la vieja. La optimización
*HOT* evita el trabajo cuando se cumplen dos condiciones: que la versión nueva quepa en la misma
página y que ninguna columna indexada haya cambiado; entonces se enlazan las dos versiones dentro de
la página y los índices siguen valiendo. Si alguna columna indexada cambió, se insertan entradas
nuevas en todos los índices y las viejas quedan muertas hasta que pase `VACUUM`.

🔬 **El detalle** — Medido en `03` §7: 39 905 filas con `SET total = total + 0.01` escriben **158
435** registros de WAL sin índice sobre `total` y **200 027** con él. La consecuencia de diseño, que
es la que se pregunta: **no indexes una columna que se actualiza en cada petición** —un contador, un
`actualizado_en`— si no vas a filtrar por ella, porque le quitas el HOT a todos los `UPDATE` de esa
tabla. Categoría: **motor**, y muy específica de PostgreSQL: InnoDB actualiza en sitio dentro del
índice agrupado y su problema equivalente es otro, el de que cambiar la clave primaria mueve la fila
entera.

---

**06 → 16.** **Alguien propone particionar `eventos_pedido` porque un informe tarda ocho segundos.
Da el argumento que convierte esa propuesta en una decisión, y di qué preguntarías antes. 🟠**

⏱️ **30 segundos** — La pregunta es: ¿ese informe filtra por la clave por la que se quiere
particionar? Si no, particionar no descarta nada y el informe recorrerá todas las particiones. El
particionado se hace para **operar** una tabla grande, no para acelerar una consulta.

🗣️ **2 minutos** — Lo que convierte la propuesta en una decisión son tres preguntas. Primera: qué
dice el plan hoy —si el problema es una de las seis razones, particionar la reproduce en cada
partición—. Segunda: si el informe filtra por `ocurrido_en`, que es la única clave de particionado
razonable en `eventos_pedido`. Y tercera: si hay un problema de operación que sí resuelve, que es lo
que de verdad justifica el trabajo: retirar histórico con un `DROP TABLE` de la partición en vez de
un `DELETE` de millones de filas, y hacer `VACUUM` y `ANALYZE` por trozos en lugar de sobre 4 100
000 filas.

🔬 **El detalle** — El precio que hay que decir en voz alta: **el `UNIQUE` global desaparece** si la
clave de particionado no va dentro de la restricción; las claves foráneas contra tablas
particionadas tienen límites; la planificación se alarga con el número de particiones; y convertir
una tabla existente no es una operación en caliente, es recrearla y mover los datos. Categoría:
**motor**; no hay particionado en ISO/IEC 9075, PostgreSQL 18.6 lo tiene declarativo por rango,
lista y hash, MySQL 9.7.2 con sus propios límites, y **SQLite no lo tiene**. Este corpus **no parte
`eventos_pedido`** a propósito: cambiaría todos los planes pegados en el bloque.

---

**06 → 17.** **Escribe la secuencia de diagnóstico completa —qué miras, en qué orden, y qué
descartas en cada paso— para un índice que existe y no aparece en el plan. Máximo cinco pasos. 🔴**

⏱️ **30 segundos** — Cinco pasos: leer el `WHERE` tal y como está escrito; comprobar el prefijo del
índice; comparar `rows=` con `actual rows`; medir el camino que el motor descartó; y solo entonces
decidir si falta un índice, y cuál.

🗣️ **2 minutos** — La secuencia, con lo que se descarta en cada paso:

```text
1. ¿La columna está envuelta en una función, una conversión o un comodín por la izquierda?
   Sí -> razón 1. Reescribe como rango, o crea el índice funcional. Fin.
2. ¿El `WHERE` nombra la primera columna del índice? ¿El índice es parcial? ¿Hay un `OR`?
   -> razones 2 y 5. Mira `Index Searches` y `EXPLAIN (GENERIC_PLAN)` si el valor es un parámetro.
3. ¿`rows=` y `actual rows` se parecen en el nodo de más abajo?
   No -> razón 4. `ANALYZE`, o estadística extendida si el filtro toca dos columnas de la tabla.
4. ¿Cuántas filas pasan el filtro, y cuántas se descartan?
   Muchas -> razón 3. Apaga `enable_indexscan` y `enable_bitmapscan`, mide y compara páginas.
5. Si el índice aparece y no ayuda: `Heap Fetches`, `Heap Blocks` y el tamaño del índice.
   -> razón 6. `VACUUM` o `REINDEX`, no un índice nuevo.
```

🔬 **El detalle** — El orden no es arbitrario: está puesto de lo más barato de comprobar a lo más
caro de ejecutar. Los pasos 1 y 2 se resuelven leyendo, sin tocar la base; el 3 necesita un `EXPLAIN
ANALYZE`; el 4, dos mediciones; y el 5, mirar catálogos. Y el paso que casi nadie da es el 4, porque
exige aceptar que el motor pueda tener razón. Categoría: **motor** de principio a fin; lo que se
traslada a MySQL y a SQLite es el método, no el vocabulario.

---

**06 → 18.** **Un `CREATE INDEX CONCURRENTLY` se interrumpió anoche. Escribe la consulta que lo
detecta, di qué está pagando la base ahora mismo y cuál es la corrección. 🔴**

⏱️ **30 segundos** — La consulta mira `pg_index` buscando `indisvalid = false`. La base está pagando
el índice entero —disco y una escritura por cada `INSERT`— y **no lo usa en ninguna consulta**. La
corrección es `DROP INDEX` y volver a crearlo.

🗣️ **2 minutos** — Un `CREATE INDEX CONCURRENTLY` construye en dos pasadas para no bloquear las
escrituras, y si se interrumpe a medias deja el índice en el catálogo marcado como no válido:

```sql
SELECT c.relname, i.indisvalid, i.indisready
  FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
 WHERE NOT i.indisvalid OR NOT i.indisready;
```

Sobre la base sana del curso devuelve cero filas; con un `CONCURRENTLY` cortado a media construcción
—`SET statement_timeout = '1400ms'` sobre `eventos_pedido (tipo)`— devuelve esto:

```text
   relname   | indisvalid | indisready 
-------------+------------+------------
 ix_tmp_roto | f          | t
(1 fila)
```

`indisvalid = false` significa "no lo mires al planificar" y `indisready = false`, "no lo mantengas
al escribir". El desenlace depende de la fase en que muera el `CONCURRENTLY`: cortado tarde deja
`f` / `t`, **lo peor de los dos mundos** —se mantiene y no se usa—, y cortado pronto, `f` / `f`, que
solo cuesta disco. Lo correcto es `DROP INDEX CONCURRENTLY` y relanzarlo, no `REINDEX` a ciegas.

🔬 **El detalle** — Es la sexta razón de las seis en su forma más cara, y la única que no se
diagnostica mirando el plan: en el plan simplemente no aparece, igual que si no existiera. Por eso
la consulta de arriba entra en la revisión que se corre después de cada migración, y **devolver cero
filas es la respuesta correcta**. Categoría: **motor**, y específico de PostgreSQL: en MySQL 9.7.2
el DDL confirma o falla y no deja este estado intermedio; en SQLite tampoco existe. El precio, con
los números del corpus: un índice como el de cobertura son 31 MB y una escritura extra por fila, a
cambio de nada.

---

**06 → 19.** **Este `WHERE` tiene tres razones distintas de las seis, a la vez: `WHERE
lower(c.email) LIKE '%@ejemplo.test' OR p.estado = 'PENDIENTE'`. Nómbralas, di en qué orden las
arreglarías y qué índices acabarías creando. 🔴**

⏱️ **30 segundos** — Están la razón 1 —`lower(c.email)` envuelve la columna—, la razón 5 —el comodín
por la izquierda en el `LIKE`, y el `OR` que necesita índice en las dos ramas— y la razón 3 —`estado
= 'PENDIENTE'` son 120 000 pedidos de un millón, un filtro que no filtra—. Y antes de indexar nada,
hay que preguntar qué pretende esa consulta, porque mezcla dos búsquedas distintas con un `OR`.

🗣️ **2 minutos** — El orden en que las arreglaría: **primero el `OR`**, porque mientras esté ahí
ningún índice de una rama puede usarse solo; se parte en dos consultas y se unen con `UNION`, o se
acepta el barrido. Después la razón 3: `PENDIENTE` es el 12 % de la tabla y no merece índice; si el
filtro de verdad es "pendientes de un cliente", el índice es `(cliente_id)` o el parcial
`(cliente_id) WHERE estado = 'PENDIENTE'`, medido en 1136 kB y 38 ms. Y por último el `LIKE
'%@ejemplo.test'`: un B-tree no sirve para un comodín por la izquierda, porque no hay prefijo por el
que bajar. Acabaría creando un índice —el de la rama del cliente— y no cuatro.

🔬 **El detalle** — Lo que hay que saber del caso duro: buscar por el final de una cadena tiene dos
salidas honestas. Una es indexar la cadena **invertida** con un índice funcional —`reverse(email)`—
y convertir el sufijo en prefijo, que funciona si el patrón siempre es un sufijo. La otra es un
índice de trigramas con GIN, que sí resuelve `%texto%` y necesita una extensión, `pg_trgm`, que
**este corpus no instala y no mide**. Y si lo que se busca es el dominio del correo, la respuesta de
diseño es otra: es una columna, no una subcadena. Categoría: **motor** en todo; el estándar no dice
nada de cómo se indexa un `LIKE`.

---

**06 → 20.** **Diseña la sesión completa —comando a comando, sin dejar nada detrás— que demuestra
que un índice sobre `pedidos(estado)` no compensa. Di qué comparas y qué cifra cierra el argumento.
🔴**

⏱️ **30 segundos** — Se mide antes, se crea el índice dentro de una transacción, se mide después y
se deshace todo con `ROLLBACK`. Se comparan páginas y forma del plan, y la cifra que cierra el
argumento es `Rows Removed by Filter` contra las filas que salen.

🗣️ **2 minutos** — La sesión completa, con la misma consulta las dos veces:

```text
tienda=# BEGIN;
tienda=*# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM pedidos WHERE estado = 'ENTREGADO';
tienda=*# CREATE INDEX ix_pedidos_estado ON pedidos (estado);
tienda=*# ANALYZE pedidos;
tienda=*# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM pedidos WHERE estado = 'ENTREGADO';
tienda=*# SELECT pg_size_pretty(pg_relation_size('ix_pedidos_estado'));
tienda=*# ROLLBACK;
```

El `ANALYZE` no es opcional: sin él el planificador no tiene estadística del índice nuevo y la
comparación no es limpia. Lo que se compara, en este orden: si la forma del árbol cambió; si la
condición pasó de `Filter` a `Index Cond`; las páginas de `Buffers`, que es lo que no depende de la
caché; el tamaño del índice; y solo al final los milisegundos.

🔬 **El detalle** — La cifra que cierra el argumento está medida y no hace falta crear nada para
saberla: `estado = 'ENTREGADO'` deja pasar **300 000 filas de 1 000 000** y el `Seq Scan` lee 15 363
páginas en secuencia. Un índice sobre `estado` tendría que producir 300 000 visitas al heap para
ahorrarse eso, y además ocuparía disco y una escritura por cada `INSERT`. El `ROLLBACK` funciona
porque PostgreSQL tiene **DDL transaccional**, y con él no queda nada: es la regla de este bloque, y
la razón de que los planes de los seis capítulos sigan siendo reproducibles. Dos avisos: `CREATE
INDEX CONCURRENTLY` **no** vale aquí, porque no corre dentro de una transacción, y mientras la
transacción vive el índice bloquea las escrituras de `pedidos`. Categoría: **motor**; en MySQL 9.7.2
el DDL no es transaccional y ese `CREATE INDEX` se queda puesto aunque hagas `ROLLBACK`.

---

## Simulación de entrevista

Las 24 preguntas `S#` y los cuatro escenarios de [`07`](07-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**07 → S1.** **`pedidos` son 10 770 páginas de 8 kB, y cualquier plan que toque la tabla se mide en
páginas antes que en filas. Explica por qué el motor no puede leer "una fila" del disco, y qué
consecuencia tiene eso para el coste de cualquier acceso por índice. 🟡**

⏱️ **30 segundos** — Porque la unidad de E/S, de caché y de bloqueo de búfer es la página, no la
fila: el motor trae 8 kB enteros aunque le pidas una columna de una fila. Leer una fila de `pedidos`
cuesta lo mismo que leer las 93 que la acompañan.

🗣️ **2 minutos** — De ahí sale todo el coste de este bloque. Un índice no gana leyendo menos filas:
gana leyendo **menos páginas**. Y por eso un acceso por índice tiene un precio que sorprende: cada
fila que encuentra en el índice obliga a visitar la página del heap donde vive, y si las filas que
buscas están repartidas por toda la tabla, acabas leyendo casi todas sus páginas igual. La cuenta de
`pedidos` es comprobable: quedan 8 168 bytes útiles por página, cada fila consume su puntero de 4
bytes más sus 84 de ancho medio, caben 92,8, y un millón entre 92,8 son las 10 770 páginas del
catálogo.

🔬 **El detalle** — El número que lo cierra: 49 001 filas de `pedidos` viven en 2 253 páginas, así
que un `Index Scan` fila a fila visitaría páginas repetidas y el motor prefiere un `Bitmap Heap
Scan` que lee cada una **una vez y en orden físico**: 12,298 ms. Y lo que **no** cambia el número de
páginas leídas es cuántas columnas pide tu `SELECT`: la página se lee entera. Categoría: **motor**;
el estándar no define almacenamiento, y el tamaño de página es 8 kB en PostgreSQL 18.6, 16 kB en
InnoDB y 4 kB en SQLite.

---

**07 → S2.** **Un `UPDATE` sobre `PED-00042` movió su `ctid` de `(10769,20)` a `(10769,21)`. Di qué
guarda un `ctid`, por qué cambió sin que nadie borrara nada, y por qué eso les importa a todos los
índices de la tabla. 🟠**

⏱️ **30 segundos** — Un `ctid` es el par (página, puntero de línea): la dirección física de **esa
versión** de la fila. Cambió porque un `UPDATE` de PostgreSQL no modifica en sitio, escribe una
versión nueva. Y les importa a los índices porque es justo lo que guardan para volver al heap.

🗣️ **2 minutos** — La primera parte es el bloque dentro del fichero de la tabla, contando desde
cero; la segunda, la posición en el vector de punteros de esa página. Ocupa 6 bytes y **no es un
identificador**: cambia con cada `UPDATE`, con `VACUUM FULL` y con cualquier reorganización, así que
usarlo como clave en la aplicación es un error. La consecuencia para los índices es la que se
pregunta: si la fila se mueve, las entradas que apuntaban a la dirección vieja quedan obsoletas, y
hay que insertar entradas nuevas en todos los índices de la tabla.

🔬 **El detalle** — De ahí sale la optimización que explica por qué unos `UPDATE` son baratos y otros
no: **HOT**. Si la versión nueva cabe en la misma página y **ninguna columna indexada cambió**, el
motor enlaza las dos versiones dentro de la página y no toca ningún índice; en cuanto una columna
indexada cambia, escribe en todos. Medido: 39 905 filas con `SET total = total + 0.01` escriben 158
435 registros de WAL sin índice sobre `total` y 200 027 con él. Categoría: **motor**, y muy
específica: en InnoDB no hay equivalente expuesto, porque la fila vive dentro del índice primario y
lo que los índices secundarios guardan es la clave primaria.

---

**07 → S3.** **En InnoDB la tabla **es** el índice primario y en PostgreSQL es un heap aparte. Da
las dos consecuencias prácticas: una al elegir la clave primaria y otra al leer por un índice
secundario. 🟠**

⏱️ **30 segundos** — Al elegir la clave primaria: en InnoDB la clave se copia entera en **cada**
índice secundario, así que una clave ancha o aleatoria engorda y fragmenta todos los índices. Al
leer por un índice secundario: en InnoDB la "vuelta a la tabla" es otra bajada por el índice
primario, no un salto a una dirección física.

🗣️ **2 minutos** — En InnoDB la tabla **es** el índice primario: las filas viven en las hojas,
ordenadas por la clave, en páginas de 16 kB. Por eso `DATA_LENGTH` y el tamaño de `PRIMARY` son el
mismo número —71 MB para `pedidos`, medido— y por eso leer un rango por la clave primaria es
secuencial. En PostgreSQL el heap es un montón sin orden y los índices guardan un `ctid` de 6 bytes,
así que el tamaño de la tabla y el de la clave primaria son dos cosas: 84 MB de heap **más** 21 MB
de `pedidos_pkey`.

🔬 **El detalle** — El número que demuestra la primera consecuencia está medido en `01` §6 con dos
índices secundarios de una sola columna `BIGINT`: `fk_pagos_pedido`, que cuelga de una clave de 8
bytes, pesa 23 bytes por fila; `fk_lineas_producto`, que cuelga de la compuesta `(pedido_id,
linea)`, pesa 39,5 bytes por fila. **Un 70 % más caro por fila, y la única diferencia es el ancho de
la clave primaria.** Extrapolado a un `UUIDv4` en `CHAR(36)`: 36 bytes por entrada en cada índice
secundario en vez de 8, y además inserciones en medio del árbol que parten páginas — de ahí la regla
de InnoDB, clave **estrecha y creciente**, y de ahí UUIDv7. Categoría: **motor**: ISO/IEC 9075
define `PRIMARY KEY` como una restricción lógica y no dice una palabra de dónde viven las filas.

---

**07 → S4.** **Tienes que acelerar tres cosas: una igualdad por `pedidos.codigo`, un *"¿contiene
esta clave?"* sobre `eventos_pedido.carga`, que es `jsonb`, y un rango por `ocurrido_en` sobre 4 100
000 filas que se insertaron en orden de tiempo. Di qué familia de índice para cada una y por qué.
🟠**

⏱️ **30 segundos** — B-tree para la igualdad por `codigo`; GIN para el *"¿contiene?"* sobre `jsonb`;
y para el rango sobre 4 100 000 filas, BRIN **solo si la columna está correlacionada con el orden
físico** —y en este corpus `ocurrido_en` no lo está—, así que ahí la respuesta honesta es B-tree o
nada.

🗣️ **2 minutos** — Cada familia responde una pregunta distinta. El B-tree mantiene el orden, así que
sirve para `=`, para rangos, para `LIKE 'pre%'` y para `ORDER BY`; es la respuesta por defecto y
sobre `codigo` es exactamente eso. GIN es invertido: parte el documento en elementos y guarda una
entrada por elemento, que es lo único que puede responder `@>` sobre `jsonb`; medido, baja la
consulta de 596,011 ms a 137,793 ms y cuesta 85 MB y 5,8 s de construcción. BRIN guarda el mínimo y
el máximo de cada grupo de 128 páginas, así que solo sabe descartar tramos del disco.

🔬 **El detalle** — El hallazgo que da la nota está medido en `02` §6: la correlación de
`eventos_pedido.ocurrido_en` es **0,0098**, cero a efectos prácticos, aunque sea una fecha y las
fechas sean el ejemplo de manual de BRIN. Forzado, el BRIN marca `Heap Blocks: lossy=82017` —todas
las páginas de la tabla— y tarda **387,232 ms contra los 328,042 ms del `Seq Scan`**: ahí no es
neutro, es peor. La columna que sí está correlacionada es `pedido_id`, con correlación 1: ahí el
BRIN ocupa **40 kB** y baja de 218,960 ms a 1,478 ms, donde el B-tree equivalente ocupa 51 MB.
Categoría: **motor**: ninguna familia de índice está en el estándar, y de estas tres MySQL 9.7.2 no
tiene ninguna con ese nombre.

---

**07 → S5.** **¿Cuándo gana un índice hash a un B-tree sobre la misma columna, y por qué casi nunca
se usa? 🟡**

⏱️ **30 segundos** — Gana solo en igualdad pura, y por poco: 0,070 ms contra 0,118 ms medidos. No se
usa porque cuesta cuatro veces más disco y **no sabe responder nada más**: ni rango, ni `ORDER BY`,
ni `LIKE`.

🗣️ **2 minutos** — Un hash calcula `hash(valor)`, eso da un cubo, y en el cubo están los punteros.
No hay árbol y no hay orden, porque la dispersión destruye a propósito la relación entre el valor y
su posición. Medido sobre `pedidos.cliente_id`: 32 MB contra los 7,6 MB del B-tree y 1 050 ms de
construcción contra 169. Y lo que de verdad lo descarta no es el coste: el método de acceso hash
**solo declara el operador `=`**, así que para un `BETWEEN` ni es candidato y el plan vuelve a `Seq
Scan`; para un `ORDER BY cliente_id LIMIT 10` el motor lee el millón de filas y lo ordena, 130,631
ms contra 0,034 ms con el B-tree, **3 842 veces**.

🔬 **El detalle** — El caso defendible existe y conviene nombrarlo: una columna **larga** consultada
solo por igualdad —una URL, un texto de cientos de bytes—, donde el hash guarda un valor de tamaño
fijo y el B-tree guardaría la cadena entera. Sobre un `bigint` de 8 bytes no hay caso. Y un aviso de
📝 contexto: el consejo *"los índices hash de PostgreSQL no son seguros ante caídas"* describe un
motor anterior a **PostgreSQL 10**, de 2017, cuando no se escribían en el WAL; hoy se registran como
cualquier otro, y el motivo para no usarlos es otro. Categoría: **motor**.

---

**07 → S6.** **Un BRIN sobre `eventos_pedido.ocurrido_en` ocupa 40 kB donde un B-tree ocuparía
decenas de megabytes. Di de qué depende que sirva de algo, y qué le pasa al plan cuando eso no se
cumple. 🟠**

⏱️ **30 segundos** — Depende de **la correlación entre el orden de los valores y el orden físico en
disco**, que se mira en `pg_stats.correlation` antes de crear nada. Si es baja, el índice no
descarta ningún tramo, marca todas las páginas como candidatas y el plan sale **peor** que sin él.

🗣️ **2 minutos** — Un BRIN no guarda una entrada por fila: guarda el mínimo y el máximo de cada
grupo de 128 páginas consecutivas. Con eso no sabe dónde está una fila, solo sabe decir "en este
tramo seguro que no está". Si cada tramo contiene valores de todo el rango, todos son candidatos. La
señal en el plan es `Heap Blocks: lossy=N`: si `N` se parece al total de páginas de la tabla, el
índice no está descartando nada, y `Rows Removed by Index Recheck` dice cuántas filas tuvo que
filtrar el recheck.

🔬 **El detalle** — Los dos casos medidos, que son el mismo índice en dos columnas de la misma tabla:
`ocurrido_en`, correlación 0,0098, da `Heap Blocks: lossy=82017` —las 82 017 páginas de
`eventos_pedido`—, `Rows Removed by Index Recheck: 4071472` y **387,232 ms forzado contra 328,042 ms
del `Seq Scan`**; `pedido_id`, correlación 1, da `lossy=128` de 82 017 —descarta el 99,8 % del
disco—, ocupa **40 kB** frente a los 51 MB del B-tree equivalente, y baja de 218,960 ms a 1,478 ms.
El umbral práctico: por debajo de ~0,9 de correlación, no te molestes. Categoría: **motor**, y solo
PostgreSQL: ni MySQL 9.7.2 ni SQLite 3.53.4 tienen nada equivalente.

---

**07 → S7.** **Con un índice sobre `(producto_id, cantidad)` y un `WHERE cantidad = 5`, el índice
**aparece en el plan** y la consulta va más lenta que sin él. Da el mecanismo, la línea del plan que
lo delata y las dos cifras de tiempo. 🟠**

⏱️ **30 segundos** — Es *skip scan*: al no nombrar el prefijo izquierdo, el motor salta de un valor
de `producto_id` al siguiente buscando `cantidad = 5` en cada tramo. Lo delata **`Index Searches:
51`**, y cuesta **190,789 ms contra los 167,704 ms** del barrido que descartó.

🗣️ **2 minutos** — El índice está ordenado por `producto_id` y luego por `cantidad`, así que las
líneas con `cantidad = 5` están desperdigadas: un puñado dentro de cada uno de los 5 000 productos.
El *skip scan* recorre esos tramos uno por uno, y con 5 000 valores delante eso es leer el índice
entero —**2 702 de sus 3 072 páginas, el 88 %**— y después ir al heap igual. El planificador lo
eligió porque el coste estimado le salía un 14 % más bajo, 64 421 contra 72 917: el coste es un
modelo, no una medida.

🔬 **El detalle** — 📝 Hasta PostgreSQL 17 ese plan era un `Seq Scan` limpio y el índice **no
aparecía**, que es como lo cuenta casi toda la documentación que hay por internet. El consejo no
cambia y la señal sí: ya no basta preguntar si el índice sale en el plan, hay que mirar `Index
Searches` y las páginas. La prueba de que lo que manda es la selectividad: el índice invertido,
`(cantidad, producto_id)`, filtrado por `producto_id` hace **7** bajadas, porque delante solo hay
siete valores de `cantidad`. Categoría: **motor**; MySQL tiene *skip scan* desde 8.0.13 y SQLite no
lo tiene.

---

**07 → S8.** **Explica la regla del prefijo izquierdo sin usar la palabra "índice", y di dónde se
rompe la analogía que uses. 🟢**

⏱️ **30 segundos** — Una guía telefónica está ordenada por apellido y luego por nombre: sirve para
buscar por apellido, y también por apellido y nombre; **no sirve para buscar solo por nombre**,
porque todas las Ana están desperdigadas por las mil páginas.

🗣️ **2 minutos** — Lo mismo pasa con cualquier estructura ordenada por varias columnas: el orden
solo es aprovechable de izquierda a derecha y sin huecos. Ordenado por `(a, b, c)`, puedes acotar
por `a`, por `(a, b)` y por `(a, b, c)`; si empiezas por `b`, el orden no te sirve para acotar nada
y tienes que recorrer. La consecuencia de diseño es la que se pregunta: delante va la columna por la
que **siempre** filtras, y si las dos aparecen siempre juntas, delante va la más selectiva, porque
deja el tramo más corto que recorrer.

🔬 **El detalle** — Dónde se rompe la analogía, que es la mitad de la respuesta: una guía telefónica
no tiene un motor que decida recorrerla salteada. PostgreSQL 18 sí: con *skip scan* intenta buscar
"Ana" dentro de cada apellido, y con 5 000 apellidos eso son 51 bajadas y el 88 % de las páginas. Y
la guía tampoco tiene la segunda factura: cada índice se paga en escritura, dos registros de WAL más
por fila con dos índices, medido. Categoría: **motor** —el B-tree—; el estándar no define índices, y
por tanto tampoco esta regla.

---

**07 → S9.** **Un índice parcial con `WHERE estado = 'ANULADO'` se usa cuando el valor va escrito en
la consulta y deja de usarse cuando llega en un parámetro. Explica por qué, y di qué comando te lo
confirma sin adivinar. 🟠**

⏱️ **30 segundos** — Porque el motor solo usa un índice parcial si **demuestra** que el `WHERE` de
la consulta implica el del índice, y con el valor en un parámetro no sabe qué vale mientras
planifica. Lo confirma `EXPLAIN (GENERIC_PLAN)` sobre la sentencia con `$1`.

🗣️ **2 minutos** — Con el literal escrito, la prueba es trivial y el plan usa el parcial **sin línea
`Filter`**, porque la condición la garantiza la definición del índice: medido, 0,024 ms. Con `estado
= $1`, PostgreSQL planifica las primeras ejecuciones con los valores reales y luego decide si guarda
un **plan genérico** para reutilizarlo; desde ese momento el parcial desaparece sin que nadie haya
tocado el código. Es el "en mi máquina sí se usaba" más común que existe: en la consola se escribe
el valor y en la aplicación va un parámetro.

🔬 **El detalle** — Las dos herramientas: `EXPLAIN (GENERIC_PLAN)`, que planifica sin valores y sin
ejecutar, y `plan_cache_mode`, que fuerza `force_custom_plan` o `force_generic_plan` para ver las
dos caras. El lado literal está medido en `03` §4 —0,024 ms con el parcial, contra 0,057 ms con el
índice completo y `Rows Removed by Filter: 46`—; **el caso del parámetro no está medido en una
sesión nueva de este corpus** y por eso no hay plan pegado de él. Categoría: **motor**: los índices
parciales no existen en MySQL 9.7.2, que responde `ERROR 1064`, y sí en SQLite 3.53.4.

---

**07 → S10.** **Un nodo dice `rows=80` y `actual rows=14 864`, con dos filtros sobre la misma tabla.
Di qué falló, cómo se corrige **sin crear un solo índice**, y cuánto baja el error. 🟠**

⏱️ **30 segundos** — Falló la suposición de independencia: el planificador multiplicó las dos
selectividades y las columnas están relacionadas. Se corrige con `CREATE STATISTICS …
(dependencies)`, sin crear ningún índice, y el error baja **de 186 veces a un 11 %**.

🗣️ **2 minutos** — El caso medido es `producto_id = 48 AND precio_unit = 117.86` sobre
`pedido_lineas`: cada uno sale de su MCV con su frecuencia, pero `producto_id` **determina**
`precio_unit` —el precio se congela en la compra—, así que el segundo filtro no descarta nada que el
primero no hubiera descartado. Multiplicar da 80 donde hay 14 864. Y con ese presupuesto, bajar
ochenta veces por `pedidos_pkey` salía regalado: el plan real hizo **14 864 bajadas y 60 260
páginas**. Declarada la dependencia, la estimación pasa a `rows=16461` y el plan cambia de forma.

🔬 **El detalle** — `pg_stats_ext` lo publica por número de columna: `"3 => 5": 0.9936` es
*`producto_id` determina `precio_unit` con grado 0,9936*. **No queda exacto y da igual**: repitiendo
el `ANALYZE` en otra transacción la estimación salió 13 099 en vez de 16 461, contra las mismas 14
864 reales. Lo que se busca no es exactitud, es el orden de magnitud correcto, que es lo que cambia
el plan. Cuesta una entrada más en cada `ANALYZE` y nada en disco; y **no cruza tablas distintas**.
Categoría: **motor**: `CREATE STATISTICS` es de PostgreSQL, MySQL 9.7.2 no tiene equivalente y
SQLite tampoco.

---

**07 → S11.** **El mismo `rows=20500` sale para una consulta que devuelve 0 filas y para otra que
devuelve 1 366 667. Explica de dónde sale ese número y por qué no es una estimación. 🟡**

⏱️ **30 segundos** — Porque no es una estimación: es la selectividad **por defecto**.
`carga->>'origen'` es una expresión sobre `jsonb` y no hay estadística de expresiones que consultar,
así que el planificador cae en su constante y sale la misma cifra para 0 filas y para 1 366 667.

🗣️ **2 minutos** — Es importante decirlo así —"el planificador no se equivoca, no tiene nada que
consultar"— porque cambia el arreglo. `ANALYZE` no sirve: recoge estadísticas de columnas, no de
expresiones. Lo que sirve es darle algo medible sobre la expresión: una estadística extendida sobre
la expresión, un índice de expresión —que además crea su propia estadística—, o sacar el dato del
`jsonb` a una columna, que suele ser la respuesta de diseño cuando ese campo se consulta todos los
días.

🔬 **El detalle** — El número que lo demuestra es el contraste: la misma consulta con una clave que
**no existe** estima `rows=20500` y devuelve 0; con una que sí existe estima `rows=20500` y devuelve
1 366 667, leyendo las 4 100 000 filas en 523,944 ms. Ese `20500` es una constante disfrazada de
estimación. Para comparar, en la misma base una igualdad sobre columna con MCV se estima con un 1,3
% de error: `rows=303794` contra 300 000 reales. Categoría: **motor**; MySQL sin histograma hace lo
equivalente con otra constante, el 10 %: `rows=99568` contra 300 000 reales.

---

**07 → S12.** **Un despliegue restaura la base con `pg_restore` a las 3:00 y a las 3:05 el primer
informe tarda veinte minutos. Di qué pasó, qué línea faltaba en el despliegue y qué consulta te lo
habría dicho en diez segundos. 🟠**

⏱️ **30 segundos** — `pg_restore` deja la base **sin estadísticas**: no las copia y no las calcula.
Con `reltuples` a cero y ningún MCV, el planificador elige a ciegas. Faltaba un `ANALYZE` al final
del despliegue, y lo habría dicho en diez segundos una consulta a `pg_stat_user_tables`.

🗣️ **2 minutos** — La restauración copia datos e índices, pero la estadística es una foto que se
toma con `ANALYZE`, y al terminar no se ha tomado. Autovacuum acabará haciéndolo, pero con su ritmo:
umbral de 50 filas más el 10 % de la tabla, y hasta un minuto de `naptime`. A las 3:05, el primer
informe grande planifica con la nada: de ahí un `Nested Loop` sobre millones de filas donde tocaba
un `Hash Join`, y veinte minutos. La línea que falta es `ANALYZE`, o `vacuumdb --analyze-only` sobre
la base entera, **dentro del propio despliegue y antes de dar el servicio por arriba**.

🔬 **El detalle** — La consulta de diez segundos es `SELECT relname, n_live_tup, last_analyze,
last_autoanalyze FROM pg_stat_user_tables ORDER BY last_analyze NULLS FIRST` — si la columna está
vacía, ya tienes el diagnóstico. Y el hermano de este caso, medido en `04` §6, es el que pasa **con
autovacuum encendido y todo en orden**: insertar 300 000 filas dejó la estimación en `rows=124650`
contra 420 000 reales, 3,4 veces, y tras `ANALYZE` quedó en 419 510 en 150 ms. Categoría: **motor**;
el estándar no define ni estadísticas ni restauración.

---

**07 → S13.** **¿El detalle con que el motor conoce sus propios datos lo fija el estándar SQL o cada
motor? Responde con lo que tiene PostgreSQL 18.6, lo que tiene MySQL 9.7.2 y lo que tiene SQLite
3.53.4. 🟡**

⏱️ **30 segundos** — Lo fija cada motor: el estándar no define `ANALYZE`, ni histogramas, ni
planificador. PostgreSQL 18.6 recoge histograma y valores más frecuentes solo; MySQL 9.7.2 tiene
histogramas pero **hay que crearlos y refrescarlos a mano**; SQLite 3.53.4 **no tiene nada hasta que
corres `ANALYZE`**.

🗣️ **2 minutos** — PostgreSQL guarda por columna la fracción de nulos, el ancho medio, la
cardinalidad, los cien valores más frecuentes con su frecuencia, cien tramos de histograma y la
correlación física, y lo mantiene autovacuum. MySQL se apoya en muestrear páginas del índice —veinte
por defecto— para la cardinalidad, y para una columna sin índice no tiene nada: aplica su conjetura
del 10 %. SQLite guarda en tablas normales de la base lo que `ANALYZE` calcule, y si nadie lo corre,
planifica con conjeturas fijas.

🔬 **El detalle** — Los tres números que lo demuestran, medidos en `04`: PostgreSQL estima
`ENTREGADO` en `rows=303794` contra 300 000 reales, un 1,3 % de error. MySQL, sin histograma, dice
`rows=99568` —el 10 % de 995 684— y con histograma de cinco cubos pasa a **298 229**: la conjetura
erraba tres veces, el histograma yerra el 0,6 %. Y `sqlite_stat1` es exacto y no muestreado, porque
recorre el índice entero. Categoría: **motor** entera, y es una de las respuestas que más
diferencian: en PostgreSQL `ANALYZE` es **transaccional** y se deshace con un `ROLLBACK`; en MySQL
el histograma se queda puesto y hay que borrarlo con `DROP HISTOGRAM`.

---

**07 → S14.** **¿En qué orden se lee un plan de ejecución, y cuál es el primer número que mirarías,
antes del tiempo? 🟢**

⏱️ **30 segundos** — De dentro hacia fuera y de abajo hacia arriba: el nodo más indentado corre
primero y el de arriba entrega el resultado. Y el primer número que miro no es el tiempo: es la
distancia entre `rows=` estimadas y `actual rows`.

🗣️ **2 minutos** — Un plan es un árbol que empuja filas hacia arriba: cada `->` abre un hijo, cada
nodo pide filas a sus hijos y se las da a su padre. Por eso el tiempo de un nodo **incluye el de sus
hijos** y el nodo con más `actual time` casi nunca es el culpable. La razón de empezar por la brecha
de filas es que todo lo que está por encima del primer nodo donde estimado y real se separan un
orden de magnitud se decidió con un número falso: la forma del join, el orden de las tablas y si se
usa un índice.

🔬 **El detalle** — El orden completo que uso: brecha de filas, después `Rows Removed by Filter` y
`Sort Method` —los dos sitios donde un plan confiesa que tira trabajo—, después las páginas de
`Buffers`, y solo al final los milisegundos, que dependen de qué había en la caché. Medido: el mismo
`Seq Scan` imprime las mismas 8 232 páginas con 59,164 ms y con 57,328 ms en dos ejecuciones
seguidas; **los milisegundos bailan sin que nada cambie, y eso no es información**. Categoría:
**motor**: ni el formato de árbol, ni la indentación, ni los nombres de los nodos están en el
estándar.

---

**07 → S15.** **Un nodo dice `actual time=0.8 loops=5000`. Di cuánto tardó de verdad y por qué esto
es el error número uno al leer un `Nested Loop`. 🟡**

⏱️ **30 segundos** — Tardó unos cuatro segundos: 0,8 ms **por iteración** por 5 000 iteraciones. Es
el error número uno porque el número que se lee parece minúsculo y el total es el producto.

🗣️ **2 minutos** — En un `Nested Loop`, el hijo interno se ejecuta una vez por cada fila del
externo, y `EXPLAIN ANALYZE` imprime sus cifras **promediadas por iteración**: tanto `actual time`
como `actual rows`. De ahí los decimales en las filas: un nodo que dice `rows=3.50 loops=999` no
devolvió 3,5 filas, devolvió 3 499. `Index Searches` lo confirma desde otro ángulo, porque cuenta
bajadas reales: 999 en ese mismo plan.

🔬 **El detalle** — El caso caro de este bloque es exactamente este leído mal: el `Nested Loop` de
`04` §1 marca `actual time=0.003..0.003` en el hijo interno y `loops=14864`, con 60 260 páginas
acumuladas y 187,822 ms totales. Y hay una excepción que descoloca y conviene tener lista: en un
plan **paralelo**, `loops=3` no son tres iteraciones, son tres procesos —dos *workers* más el que
coordina—, así que `rows=100000 loops=3` son las 300 000 filas repartidas. Categoría: **motor**;
MySQL imprime también `loops` en su `EXPLAIN ANALYZE` y SQLite no tiene `EXPLAIN ANALYZE` en
absoluto.

---

**07 → S16.** **`Sort Method: external merge Disk: 9648kB`. Di qué te está confesando el plan y las
dos cosas que puedes hacer al verlo. 🟠**

⏱️ **30 segundos** — Que la ordenación **no cupo en `work_mem`** y se fue a un fichero temporal en
disco: 9,6 MB escritos. Las dos salidas son subir `work_mem` para esa sesión o reducir las filas
antes de ordenar.

🗣️ **2 minutos** — La línea `Sort Method` es la confesión del plan: si dice `quicksort Memory: …` o
`top-N heapsort Memory: …`, cupo en memoria; si dice `external merge Disk: …`, no cupo. En este
laboratorio `work_mem` vale 8 MB, y esos 9 648 kB lo pasan justo. Reducir filas antes de ordenar
suele ser la mejor de las dos: filtrar antes, agregar antes, o ordenar por una columna que ya llegue
ordenada desde un índice, que es la manera de que el `Sort` desaparezca del plan en vez de
abaratarse. Subir `work_mem` es válido, y hay que decir su precio: es **por operación de
ordenación**, no por conexión, así que multiplicarlo por consultas concurrentes es cómo se queda una
máquina sin memoria.

🔬 **El detalle** — El plan donde salió medido es un `Merge Join` forzado con `SET enable_hashjoin =
off`: `pedidos` llegaba ordenado por su clave primaria y `pagos` necesitaba ordenarse, con ese
`external merge Disk: 9648kB`, y el camino equivocado costó **876,399 ms contra los 294,761 ms del
`Hash Join`** que el planificador elige solo. Que el `Sort` se vaya a disco no siempre es el
problema principal: aquí el problema era el método de join. Categoría: **motor**.

---

**07 → S17.** **¿`EXPLAIN ANALYZE` sobre un `UPDATE` escribe en la tabla? Responde por separado para
PostgreSQL 18.6 y MySQL 9.7.2, y da la forma segura de medirlo. 🟡**

⏱️ **30 segundos** — En PostgreSQL 18.6 **sí**: ejecuta la escritura de verdad, la tabla queda
modificada. En MySQL 9.7.2 **no**: responde `<not executable by iterator executor>`. La forma segura
es envolverlo: `BEGIN; EXPLAIN ANALYZE …; ROLLBACK;`.

🗣️ **2 minutos** — `EXPLAIN` a secas nunca ejecuta: pide el plan y devuelve solo las estimaciones.
`EXPLAIN ANALYZE` ejecuta para poder imprimir `actual time`, `actual rows` y `loops`, y si la
sentencia es un `INSERT`, `UPDATE`, `DELETE` o `MERGE`, la ejecuta con todas las consecuencias. No
hay ningún aviso en pantalla. Medido en `05` §4 sobre `PED-00042`: el `UPDATE` cambió el estado y el
`actualizado_en` de verdad, y el `ROLLBACK` lo devolvió a `PAGADO` con `actualizado_en` nulo.

🔬 **El detalle** — El precio de la forma segura, que es lo que casi nadie dice: **la escritura
ocurre igual**. Se escribe WAL, se ensucian páginas —`dirtied=1` en el plan medido— y la fila queda
bloqueada hasta el `ROLLBACK`, así que en producción no sale gratis aunque se deshaga. Y el
`rows=0.00` del nodo `Update` no significa que no tocara nada: un `UPDATE` sin `RETURNING` no
entrega filas hacia arriba, y las que tocó se cuentan en el hijo. Categoría: **motor**; el estándar
no define `EXPLAIN`, y de los tres motores del corpus SQLite 3.53.4 **no tiene `EXPLAIN ANALYZE`**:
pedirlo es un error de sintaxis.

---

**07 → S18.** **Enumera las seis razones por las que un índice existente no se usa, y di cuáles de
las seis **no** son un error del motor. 🟢**

⏱️ **30 segundos** — La columna envuelta en una función o expresión; el filtro que no nombra el
prefijo izquierdo; el filtro poco selectivo; el presupuesto equivocado; la inaplicabilidad del
índice en ese contexto —parcial, parámetro, `OR`, colación, índice inválido—; y la vuelta al heap.
**No son error del motor la tercera y la sexta.**

🗣️ **2 minutos** — En la tercera el motor tiene razón y lo demuestra el número: `metodo =
'EFECTIVO'` deja pasar 273 126 filas de 820 000, y un índice tendría que hacer esas 273 126 visitas
al heap para ahorrarse 8 232 lecturas secuenciales. En la sexta el índice funciona: el `Index Only
Scan` está ahí, y lo que falta es un `VACUUM` que ponga al día el mapa de visibilidad —`Heap
Fetches: 52` de 52 filas, con `relallvisible = 0` de 10 770 páginas—. En las otras cuatro sí hay
algo que arreglar, y está en cuatro sitios distintos: el `WHERE`, el orden de las columnas del
índice, las estadísticas y la definición del índice.

🔬 **El detalle** — La cuarta merece un matiz, porque es la que se confunde con un error: el
planificador decide **racionalmente sobre un número falso**. `rows=80` contra 14 864 reales no es un
fallo de la decisión, es un fallo de la entrada, y por eso se arregla con `ANALYZE` o con una
estadística extendida y no con un índice. Categoría: **motor** las seis; ISO/IEC 9075 no define
índices ni planificador, así que ninguna se puede atribuir al estándar.

---

**07 → S19.** **`WHERE creado_en::date = DATE '2026-01-01'` no usa el índice sobre `creado_en`. Da
la reescritura que sí lo usa, di lo que cuesta, y di en qué caso hay que pagar un índice funcional
en su lugar. 🟡**

⏱️ **30 segundos** — La reescritura es el rango: `creado_en >= DATE '2026-01-01' AND creado_en <
DATE '2026-01-02'`. No cuesta nada y el índice existente la resuelve en `Index Cond`. El índice
funcional se paga cuando la expresión es el criterio de negocio y no se puede deshacer.

🗣️ **2 minutos** — El motor no sabe que `creado_en::date` se deriva de `creado_en`: un índice guarda
la columna, no el resultado de una función sobre ella, así que la condición cae a `Filter` sobre un
`Seq Scan`. Reescribir como rango es gratis. Un índice funcional cuesta disco, tiempo de
construcción y **una evaluación de la expresión en cada `INSERT` y en cada `UPDATE`** de esa
columna, y además obliga a que la expresión del `WHERE` coincida **exactamente** con la del índice:
`upper(email)` o `lower(trim(email))` son otras expresiones y no lo usan.

🔬 **El detalle** — Medido con el caso hermano en `03` §5: `lower(email)` daba `Seq Scan` de 618
páginas y **17,522 ms**, y con el índice funcional —2448 kB, 134,664 ms de construcción— pasó a 4
páginas y **0,041 ms**. Y el matiz que sube la nota: cuando la comparación insensible a mayúsculas
es la de toda la aplicación, la respuesta no es un índice por consulta sino el tipo de la columna
—una *collation* no determinista o `citext`—. Categoría: **motor**; PostgreSQL 18.6 y SQLite 3.53.4
tienen índices de expresión nativos y MySQL 9.7.2 desde 8.0.13, con la expresión entre dos
paréntesis.

---

**07 → S20.** **Te pasan un plan con `Index Only Scan` y `Heap Fetches: 438435`. Di qué mirarías,
con qué catálogo, en qué orden, y cuál es la corrección. 🟠**

⏱️ **30 segundos** — No es el índice: es la tabla sin `VACUUM`. Mirar `relallvisible` contra
`relpages` en `pg_class` y `last_autovacuum` en `pg_stat_user_tables`; la corrección es un `VACUUM`,
y revisar por qué autovacuum no llega.

🗣️ **2 minutos** — `Index Only Scan` no significa "no toqué la tabla": significa "intenté no
tocarla". Un índice de PostgreSQL no guarda la visibilidad de la fila, así que el motor consulta el
*visibility map* —un bit por página, que `VACUUM` pone cuando todas sus filas son visibles para
todos— y, cuando el bit no está, va al heap y lo cuenta en `Heap Fetches`. 438 435 fetches son 438
435 visitas que el plan prometía ahorrarse. El orden de la investigación es: primero el catálogo,
después por qué el mantenimiento no corre —una transacción abierta desde el martes, un umbral que no
se alcanza, autovacuum agotado—, y solo al final el índice.

🔬 **El detalle** — Medido en este corpus: `pedidos` tiene `relallvisible = 0` de 10 770 páginas y un
`Index Only Scan` de 52 filas da `Heap Fetches: 52`, leyendo 21 páginas donde con el mapa al día
leería 3. `pedido_lineas`, en cambio, tiene 29 163 de 29 167, porque autovacuum la tocó tras la
carga. Lo que **no** hay que hacer es cambiar el índice: añadir columnas para "cubrir mejor" lo
ensancha y sale más caro —el de cobertura medido salió tres páginas por encima del `Index Scan`
equivalente—. Categoría: **motor**, y muy específica de PostgreSQL: InnoDB no tiene este problema
porque el índice secundario lleva la clave primaria y la visibilidad se resuelve por otro camino.

---

**07 → S21.** **Una tabla con cinco índices recibe 10 000 `INSERT` por minuto. Haz la cuenta del
precio de escritura y di en qué moneda lo medirías para que el número no dependa de la caché. 🟠**

⏱️ **30 segundos** — Cinco índices por 10 000 filas son **50 000 escrituras de índice por minuto**,
además de las de la tabla, y todas pasan por el WAL. La moneda es **registros de WAL**, medidos con
`EXPLAIN (WAL)`, porque no dependen de la caché.

🗣️ **2 minutos** — Cada `INSERT` escribe la fila y una entrada en cada índice; cada `DELETE`, lo
mismo al revés; y cada `UPDATE` paga solo si toca una columna indexada, pero entonces paga en
**todos** los índices, no solo en el de esa columna. Los milisegundos de un `INSERT` bailan según lo
que hubiera en memoria; los registros de WAL no, y además son lo que se replica y lo que se
sincroniza a disco. Al precio hay que sumarle lo que no se ve: cada índice se come su parte de
`shared_buffers`, y ahí se la quita a otro.

🔬 **El detalle** — Medido en `03` §7 sobre `pedidos`: cien mil `INSERT` escriben **303 976**
registros de WAL sin índices propios y **504 640** con dos encima —200 664 más, o sea **dos por
fila, uno por índice**—, y el nodo `Insert` pasa de 447 ms a 723 ms, un 62 % más. De dos a cinco
índices es aritmética, no medición, y conviene decirlo así. La consecuencia de diseño: **un índice
que no se usa paga todo esto a cambio de nada**, y ahí entra la revisión de `pg_stat_user_indexes`.
Categoría: **motor**: el WAL es de PostgreSQL; InnoDB amortigua parte de esto con el *change buffer*
en índices secundarios no únicos.

---

**07 → S22.** **"Si el plan dice `Seq Scan`, falta un índice." Refútalo con **dos** casos medidos de
este bloque: uno donde el motor tiene razón y otro donde el índice existe, se usa y pierde igual.
🟠**

⏱️ **30 segundos** — Caso uno, el motor tiene razón: `metodo = 'EFECTIVO'` deja pasar 273 126 filas
de 820 000 y el barrido lee 8 232 páginas en secuencia; ningún índice gana eso. Caso dos, el índice
existe y pierde: con `(producto_id, cantidad)` y `WHERE cantidad = 5`, el índice se usa y tarda
190,789 ms contra los 167,704 ms del `Seq Scan`.

🗣️ **2 minutos** — Los dos casos juntos desmontan la frase por los dos extremos. En el primero el
`Seq Scan` es la decisión correcta y la cifra que lo demuestra no es el porcentaje sino `Rows
Removed by Filter: 546874` contra las 273 126 que salen: un filtro que casi no filtra. En el segundo
hay índice, el planificador lo elige, y pierde porque le faltaba el prefijo izquierdo: 51 bajadas y
el 88 % de sus páginas. La versión útil de la frase es la contraria: **un `Seq Scan` es un problema
cuando descarta mucho más de lo que devuelve**, no por existir.

🔬 **El detalle** — El tercer caso, para cerrar: un `Seq Scan` puede ser síntoma de un presupuesto
falso y no de falta de índice. En `04` §1 el índice existía —`pedidos_pkey`— y el problema era el
`rows=80` del otro lado del join. Así que de los tres `Seq Scan` que puedes ver, uno es correcto,
uno es culpa del `WHERE` y uno es culpa de las estadísticas, y crear un índice solo ayuda en ninguno
de los tres. Categoría: **convención** la frase; **motor** todo lo que la refuta.

---

**07 → S23.** **¿Los índices y el plan de ejecución están en el estándar SQL? Responde en una frase,
y di qué se sigue de esa respuesta para una entrevista donde te preguntan "cómo se optimiza una
consulta". 🟡**

⏱️ **30 segundos** — No: ISO/IEC 9075 define **qué resultado devuelve una consulta, no cómo se
ejecuta**. Ni `CREATE INDEX`, ni `EXPLAIN`, ni el planificador están en la norma. Lo que se sigue es
que toda respuesta sobre optimización hay que darla nombrando el motor y la versión.

🗣️ **2 minutos** — Es la respuesta que más nota da en una entrevista de datos, porque coloca todo lo
demás: si los índices no están en el estándar, "cómo se optimiza una consulta" no tiene respuesta
portable, y quien la da sin decir el motor está recitando. En la práctica: la regla del prefijo
izquierdo la cumplen los tres motores del corpus, los índices parciales los tienen PostgreSQL y
SQLite pero no MySQL, el *skip scan* lo tienen PostgreSQL desde la 18 y MySQL desde 8.0.13 pero no
SQLite, y el particionado declarativo no lo tiene SQLite.

🔬 **El detalle** — El matiz honesto, y hay que decirlo así: **el estándar es de pago y no he
verificado sus cláusulas**; lo que sí es comprobable es que los tres motores implementan `EXPLAIN`
con sintaxis, salidas y vocabulario mutuamente incompatibles —`Seq Scan` frente a `Table scan`
frente a `SCAN`—, y que las unidades de coste no son comparables entre ellos. Decir *"la cláusula
exacta no la tengo; lo que sí sé es que estos tres motores lo hacen así"* es una respuesta completa.
Inventarse la cláusula es lo que cuesta el puesto.

---

**07 → S24.** **Alguien te enseña un plan y te dice que la consulta tarda 8 segundos "por culpa del
`Seq Scan` de arriba". Di por qué el nodo de mayor `actual time` casi nunca es el culpable, y cuál
es la cifra que sí lo señala. 🟡**

⏱️ **30 segundos** — Porque **el tiempo de un nodo incluye el de sus hijos**, así que el de arriba
casi siempre es el más alto por construcción. La cifra que sí señala es la brecha entre `rows=` y
`actual rows`, leída de abajo hacia arriba.

🗣️ **2 minutos** — Para saber qué cuesta un nodo por sí mismo hay que restar: en el plan de `05` §2
el `Hash Join` marca 109,539 ms, pero 60,962 son del `Seq Scan` que tiene debajo. Y hay una segunda
trampa que suma: en los nodos con `loops > 1` los tiempos están **promediados por iteración**, así
que un nodo con `actual time=0.8 loops=5000` parece tardar menos de un milisegundo y se comió cuatro
segundos. Por eso el orden de lectura es: primero dónde se rompe la estimación, después dónde se
tira trabajo —`Rows Removed by Filter`, `Sort Method`—, después las páginas, y el reloj al final.

🔬 **El detalle** — Y la razón de fondo de por qué el reloj va al final: no es estable. El mismo `Seq
Scan` imprime las mismas 8 232 páginas con 59,164 ms y con 57,328 ms en dos ejecuciones seguidas,
con distinto reparto entre `hit` y `read`. Las páginas son el trabajo; los milisegundos son el
trabajo más el estado de la caché. Categoría: **motor**: que el tiempo de un nodo incluya el de sus
hijos es una decisión de cómo PostgreSQL instrumenta su ejecutor, y MySQL hace lo mismo en su
`EXPLAIN ANALYZE`.

---

**07 → E1.** **Escenario 1 — Los cuatro índices que no arreglaron nada**

⏱️ **30 segundos** — El problema nunca fue la falta de índices: era el `rows=80` contra 14 864
reales en el filtro de `pedido_lineas`. Con ese presupuesto, bajar ochenta veces por `pedidos_pkey`
parecía gratis, y en realidad son 14 864 bajadas y 60 260 páginas. Ningún índice arregla una
estimación.

🗣️ **2 minutos** — La corrección no crea índices: declara la dependencia entre las dos columnas del
filtro con `CREATE STATISTICS … (dependencies) ON producto_id, precio_unit FROM pedido_lineas` y
vuelve a correr `ANALYZE`; el error cae de 186 veces a un 11 % y el plan cambia de forma. Los cuatro
índices no podían ayudar porque el índice que el plan necesitaba ya existía —la clave primaria de
`pedidos`— y lo que estaba mal era cuántas veces iba a usarlo. Para borrar tres hace falta el dato,
no la intuición: `SELECT relname, indexrelname, idx_scan,
pg_size_pretty(pg_relation_size(indexrelid)) FROM pg_stat_user_indexes ORDER BY idx_scan` dice
cuántas veces se ha usado cada uno desde el último reinicio de contadores. Y el argumento de coste
es medible: cien mil `INSERT` pasan de 303 976 a 504 640 registros de WAL con dos índices encima,
dos más por fila y por índice, y el nodo `Insert` de 447 ms a 723 ms.

🔬 **El detalle — qué se está evaluando** — Tres cosas, en orden. Primero, **si comparas estimado con
real antes de proponer nada**: quien empieza por "voy a crear un índice" no ha mirado el plan.
Segundo, **si te atreves a proponer borrar**, que es la parte que casi nadie dice en una entrevista
y la que de verdad corresponde a un Tech Lead: un índice que no se usa paga disco, WAL y caché a
cambio de nada. Tercero, **si cualificas el dato de `idx_scan`**: cuenta desde el último reinicio de
contadores, **es por nodo** —una réplica tiene los suyos— y no cuenta el uso que hace una
restricción `UNIQUE`, así que antes de soltar un índice hay que comprobar que no respalda una
restricción y que la ventana observada cubre los informes mensuales.

---

**07 → E2.** **Escenario 2 — El índice que nadie usa y nadie se atreve a borrar**

⏱️ **30 segundos** — `indisvalid = false` significa que el planificador **no lo mira**, así que la
base está pagando 31 MB de disco, una escritura extra por cada `INSERT` y su parte de la caché a
cambio de nada. Ese índice no hay que debatirlo: hay que borrarlo y, si alguien lo quería, crearlo
otra vez bien.

🗣️ **2 minutos** — Lo primero es separar las dos preguntas, porque el equipo las tiene mezcladas.
"¿Está válido?" se contesta con `pg_index`: `SELECT c.relname, i.indisvalid, i.indisready FROM
pg_index i JOIN pg_class c ON c.oid = i.indexrelid WHERE NOT i.indisvalid OR NOT i.indisready`, y
aquí devuelve una fila, que es la respuesta. "¿Se usa?" se contesta con `pg_stat_user_indexes`
—`idx_scan`, `idx_tup_read`, `idx_tup_fetch`— y con `pg_stat_reset_time` de `pg_stat_database`, que
dice desde cuándo se está contando; sin esa fecha, un `idx_scan = 0` no significa nada. El
procedimiento: comprobar que no respalda una restricción `UNIQUE` ni una clave primaria —esas no se
sueltan con `DROP INDEX`—, guardar su definición con `pg_get_indexdef`, soltarlo con `DROP INDEX
CONCURRENTLY`, y dejar apuntado el DDL de vuelta atrás.

🔬 **El detalle — qué se está evaluando** — Lo primero, **si distingues "no es válido" de "no se
usa"**: son dos hallazgos distintos y el primero cierra el caso solo. Lo segundo, **si cualificas el
contador**: `idx_scan` cuenta desde el último reinicio, es local a ese nodo —las consultas que van a
la réplica cuentan allí, y es el error que más veces borra un índice que sí se usaba— y no refleja
el uso que hace una restricción. Lo tercero, **si el miedo del equipo se convierte en una ventana de
observación**: "nadie se atreve" no es un criterio; "llevamos 90 días contando y cubrimos el cierre
mensual" sí. Y el matiz de altitud: 31 MB no es la razón para borrarlo —eso es barato—; la razón es
la escritura por fila y el ruido que un índice inválido deja en cada revisión futura.

---

**07 → E3.** **Escenario 3 — El `CREATE INDEX` del viernes**

⏱️ **30 segundos** — Un `CREATE INDEX` normal toma un bloqueo que **deja leer y bloquea las
escrituras** de la tabla mientras construye, de principio a fin. `CONCURRENTLY` no las bloquea, pero
hace dos pasadas, espera a las transacciones abiertas, tarda bastante más y puede dejar un índice
inválido si falla. Y los 829 ms de pruebas no predicen nada.

🗣️ **2 minutos** — Por qué el tiempo del entorno de pruebas no vale: la construcción depende del
tamaño real de la tabla, de `maintenance_work_mem`, de qué había en la caché y, sobre todo, de la
escritura concurrente que en pruebas no existe; en producción el índice se construye mientras entran
`INSERT`. Lo que sí se mide antes: el tamaño que va a ocupar —comparable con los índices medidos del
corpus, de 1136 kB el parcial a 31 MB el de cobertura—, el tiempo en una copia restaurada del mismo
tamaño, y cuánto duran las transacciones más largas que hay abiertas, porque `CONCURRENTLY` las
espera. El plan de vuelta atrás son dos líneas: la consulta de `indisvalid` de arriba y `DROP INDEX
CONCURRENTLY` si el índice quedó a medias.

🔬 **El detalle — qué se está evaluando** — Primero, **si sabes qué bloquea exactamente**: la
respuesta "bloquea la tabla" es incompleta y suena a memorizada; bloquea las escrituras y no las
lecturas. Segundo, **si nombras el precio de `CONCURRENTLY`** en vez de venderlo como gratis: dos
pasadas, más tiempo total, no se puede ejecutar dentro de una transacción —así que no hay `BEGIN …
ROLLBACK` que te salve— y el fallo deja basura que hay que limpiar a mano. Tercero, **si propones
medir en una copia en vez de discutir**. Y el detalle de contraste que remata: en MySQL 9.7.2 el DDL
no es transaccional, así que la técnica que el resto de este corpus usa para medir un índice sin
dejar nada —`BEGIN; CREATE INDEX; …; ROLLBACK;`— allí no existe.

---

**07 → E4.** **Escenario 4 — El buscador que tiene que responder en 50 ms**

⏱️ **30 segundos** — Seis filtros opcionales son **64 combinaciones**, y el índice que sirve a una
no sirve a la siguiente. No existe un juego de índices que dé 50 ms a las 64, y crearlos hace que la
escritura se hunda y el buscador siga lento. Esto no lo resuelve la base de datos sola: lo que hay
que resolver primero es el requisito.

🗣️ **2 minutos** — Lo que sí se puede indexar de esa lista: el cliente, que es muy selectivo; el
rango de fechas, que un B-tree resuelve de verdad; y la combinación de los dos, con la columna más
selectiva delante. Lo que no: `estado`, porque cada valor es entre el 6 % y el 30 % de la tabla y
ahí el barrido gana; el país, que vive en `clientes` y por tanto es un join, no un filtro; y sobre
todo **el texto libre con comodín por la izquierda**, que un B-tree no puede tocar, porque no hay
prefijo por el que bajar. Para eso hay dos salidas honestas y las dos cuestan: un índice de
trigramas —que necesita una extensión que este corpus no instala ni mide— o un buscador aparte, con
su propia copia de los datos y su propio retraso. La pregunta que hay que hacerle a producto es
**cuáles de los seis filtros usa de verdad el 95 % de las búsquedas**, y la segunda, **cuántos
segundos puede envejecer el resultado**.

🔬 **El detalle — qué se está evaluando** — Lo primero, **si te niegas a aceptar el marco**: "te creo
los seis índices" produce una base con doce índices, un proceso de escritura el doble de lento —303
976 a 504 640 registros de WAL con solo dos índices, medido— y el mismo buscador lento. Lo segundo,
**si separas las tres clases de filtro** —selectivo e indexable, poco selectivo que no merece
índice, y búsqueda de texto que pertenece a otra herramienta— en vez de tratarlas como una lista
homogénea. Lo tercero, **si nombras la capa correcta para cada parte**: los filtros estructurados en
la base, con un índice por patrón de acceso real; el texto en un buscador o en un índice
especializado; y el "50 ms siempre" en una conversación con producto, porque tal como está escrito
no es un requisito, es una frase que nadie ha cuantificado. Ceder aquí es el fallo más caro de una
entrevista de Tech Lead.

---

**Volver:** [README del bloque](README.md) · **Primer capítulo:**
[`01`](01-como-se-almacena-una-tabla.md).
