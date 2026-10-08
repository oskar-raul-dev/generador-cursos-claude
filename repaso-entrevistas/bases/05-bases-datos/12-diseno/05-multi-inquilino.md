# 05 — Multi-inquilino

> Cómo se sirve a muchos clientes de negocio desde una sola aplicación sin que uno vea los datos de
> otro: una columna que los distingue, un esquema por cliente o una base por cliente, con el coste
> operativo de cada uno. Medido en PostgreSQL: la seguridad a nivel de fila filtra por inquilino
> sola, pero el superusuario se la salta; una política que compara `char(2)` con texto anula el
> índice y tarda 177 ms donde podría tardar 18; un `SET` que sobrevive a la transacción enseña los
> datos de un inquilino a la siguiente petición; y doscientos esquemas son 6 600 objetos más en el
> catálogo. **Asume leído:** [`06/01`](../06-operacion/01-usuarios-roles-y-permisos.md), los
> permisos, y [`10/01`](../10-interfaz-con-los-lenguajes/01-el-driver-la-conexion-y-el-pool.md), el
> pool. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Tres modelos](#2--tres-modelos)
- [3. Columna discriminadora y seguridad a nivel de
  fila](#3--columna-discriminadora-y-seguridad-a-nivel-de-fila) · [4. La política que anula el
  índice](#4--la-política-que-anula-el-índice)
- [5. El inquilino que se queda en la conexión](#5--el-inquilino-que-se-queda-en-la-conexión) · [6.
  Esquema por inquilino](#6-️-esquema-por-inquilino)
- [7. Cómo se elige](#7--cómo-se-elige) · [8. Estándar, motor y
  convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La tienda se convierte en plataforma: otras tiendas contratan el servicio y cada una tiene sus
clientes, sus productos y sus pedidos. Son los **inquilinos**. La aplicación es una sola, y la
pregunta de diseño es dónde se separan sus datos.

Lo que se evalúa en una entrevista no es la opción, sino lo que cuesta: una fuga de datos entre
inquilinos es el peor fallo posible de una plataforma, y cada modelo la evita a un precio distinto
en rendimiento, en operación y en migraciones.

> **📝 Contexto.** Todo se corrió en la copia aislada `bd-lab-prueba`, con una tabla de prueba,
> `pedidos_mt`, que copia el millón de pedidos con el país del cliente como inquilino, un rol nuevo,
> `app_mt`, y doscientos esquemas vacíos. **Longitud:** unas 420 líneas; capítulo normal que pasa el
> disparador de 400.

---

## 2. 🧱 Tres modelos

| Modelo | Cómo se separan los datos | Fuga si se olvida algo | Operación |
|---|---|---|---|
| **Columna discriminadora** | Todas las tablas llevan `inquilino`; todo se filtra por ella | Una consulta sin filtro ve a todos | Una base, un esquema, una migración |
| **Esquema por inquilino** | Las mismas tablas, repetidas en un esquema por cliente | Una conexión con el esquema equivocado | Una migración por esquema; el catálogo crece |
| **Base por inquilino** | Una base de datos entera por cliente | Casi imposible entre bases | Un pool, un respaldo y una migración por base |

**Quién lo manda:** es **convención** de arquitectura; lo que la hace segura o no es el **motor**:
la seguridad a nivel de fila, los esquemas y cómo se conecta un cliente a una base.

---

## 3. 🧱 Columna discriminadora y seguridad a nivel de fila

**Qué es:** con una columna `inquilino` en cada tabla, la separación depende de que **cada
consulta** filtre por ella. La **seguridad a nivel de fila** (RLS) de PostgreSQL pone ese filtro en
la base: una **política** que se añade sola a toda consulta sobre la tabla.

```text
tienda=# CREATE TABLE pedidos_mt AS SELECT p.codigo, c.pais AS inquilino, p.total FROM pedidos p JOIN clientes c ON c.id = p.cliente_id;
SELECT 1000000
tienda=# CREATE INDEX ON pedidos_mt (inquilino);
CREATE INDEX
tienda=# SELECT inquilino, count(*) FROM pedidos_mt GROUP BY inquilino ORDER BY count(*) DESC LIMIT 3;
 inquilino | count  
-----------+--------
 US        | 145896
 CL        | 143431
 CO        | 142926
(3 filas)

tienda=# CREATE ROLE app_mt LOGIN PASSWORD 'app_mt';
CREATE ROLE
tienda=# GRANT SELECT ON pedidos_mt TO app_mt;
GRANT
tienda=# ALTER TABLE pedidos_mt ENABLE ROW LEVEL SECURITY;
ALTER TABLE
tienda=# CREATE POLICY por_inquilino ON pedidos_mt USING (inquilino = current_setting('app.inquilino'));
CREATE POLICY
tienda=# SET ROLE app_mt;
SET
tienda=> SELECT count(*) FROM pedidos_mt;
ERROR:  unrecognized configuration parameter "app.inquilino"
tienda=> SET app.inquilino = 'ES';
SET
tienda=> SELECT count(*) FROM pedidos_mt;
 count 
-------
 71108
(1 fila)

tienda=> SELECT count(*) FROM pedidos_mt WHERE inquilino = 'MX';
 count 
-------
     0
(1 fila)

tienda=> EXPLAIN (COSTS OFF) SELECT count(*) FROM pedidos_mt;
                                  QUERY PLAN                                  
------------------------------------------------------------------------------
 Aggregate
   ->  Seq Scan on pedidos_mt
         Filter: ((inquilino)::text = current_setting('app.inquilino'::text))
(3 filas)

tienda=> RESET ROLE;
RESET
tienda=# SELECT count(*) FROM pedidos_mt;
  count  
---------
 1000000
(1 fila)
```

- **`ENABLE ROW LEVEL SECURITY` y `CREATE POLICY … USING (…)`**: la condición se añade a cada
  consulta de `app_mt`. El plan lo enseña: un `Filter` que nadie escribió.
- **`app.inquilino`** es un parámetro inventado, que la aplicación fija al empezar cada petición.
  **`current_setting`** lo lee; sin él, da error, y la consulta falla **cerrada**: ninguna fila, en
  vez de todas. La documentación da un segundo argumento, `missing_ok`, para que devuelva nulo en
  lugar de error.
- **Con `ES`, 71 108 pedidos; y pidiendo expresamente los de `MX`, cero**: la política se suma al
  `WHERE` de la consulta, no lo sustituye.
- **El superusuario ve el millón**: la documentación dice que los superusuarios y los roles con
  `BYPASSRLS` se saltan siempre la seguridad de fila, y que el **dueño de la tabla** también, salvo
  que se active `FORCE ROW LEVEL SECURITY`. La aplicación no puede conectarse como dueño de las
  tablas, que es la regla de [`06/01`](../06-operacion/01-usuarios-roles-y-permisos.md).

> **Veredicto:** la seguridad de fila convierte el filtro por inquilino en una garantía de la base,
> siempre que la aplicación entre con un rol que no se la salte.

---

## 4. 🩺 La política que anula el índice

El plan de §3 hacía un `Seq Scan`, aunque `pedidos_mt` tiene un índice sobre `inquilino`. La columna
es `char(2)` —copia de `clientes.pais`— y `current_setting` devuelve texto:

```text
tienda=# SET ROLE app_mt;
SET
tienda=> SET app.inquilino = 'ES';
SET
tienda=> EXPLAIN (ANALYZE, COSTS OFF, SUMMARY ON) SELECT count(*) FROM pedidos_mt;
                                   QUERY PLAN                                    
---------------------------------------------------------------------------------
 Aggregate (actual time=176.684..176.692 rows=1.00 loops=1)
   Buffers: shared hit=6400
   ->  Seq Scan on pedidos_mt (actual time=0.010..173.852 rows=71108.00 loops=1)
         Filter: ((inquilino)::text = current_setting('app.inquilino'::text))
         Rows Removed by Filter: 928892
         Buffers: shared hit=6400
 Planning:
   Buffers: shared hit=76
 Planning Time: 0.241 ms
 Execution Time: 176.727 ms
(10 filas)

tienda=> RESET ROLE;
RESET
tienda=# ALTER POLICY por_inquilino ON pedidos_mt USING (inquilino = current_setting('app.inquilino')::char(2));
ALTER POLICY
tienda=# SET ROLE app_mt;
SET
tienda=> EXPLAIN (ANALYZE, COSTS OFF, SUMMARY ON) SELECT count(*) FROM pedidos_mt;
                                                 QUERY PLAN                                                 
------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=17.952..17.953 rows=1.00 loops=1)
   Buffers: shared hit=6371 read=61
   I/O Timings: shared read=0.595
   ->  Bitmap Heap Scan on pedidos_mt (actual time=2.835..15.440 rows=71108.00 loops=1)
         Recheck Cond: (inquilino = (current_setting('app.inquilino'::text))::character(2))
         Heap Blocks: exact=6370
         Buffers: shared hit=6371 read=61
         I/O Timings: shared read=0.595
         ->  Bitmap Index Scan on pedidos_mt_inquilino_idx (actual time=2.282..2.282 rows=71108.00 loops=1)
               Index Cond: (inquilino = (current_setting('app.inquilino'::text))::character(2))
               Index Searches: 1
               Buffers: shared hit=1 read=61
               I/O Timings: shared read=0.595
 Planning:
   Buffers: shared hit=11
 Planning Time: 0.090 ms
 Execution Time: 18.031 ms
(17 filas)

tienda=> RESET ROLE;
RESET
```

- **`(inquilino)::text`**: para comparar un `char(2)` con texto, el motor convierte **la columna**,
  y un índice sobre la columna no sirve para una expresión sobre ella. 928 892 filas descartadas,
  177 ms.
- **Convirtiendo el valor, no la columna** —`current_setting(…)::char(2)`—, el plan usa el índice:
  `Bitmap Index Scan`, 18 ms. Diez veces menos, con una conversión de tipo en la política.
- **La trampa es general**: la política es una expresión escondida en cada consulta, y lo que valga
  para un `WHERE` —el tipo, la volatilidad de
  [`05/01`](../05-programacion-en-el-motor/01-funciones-y-procedimientos.md)— vale para ella, sin
  que nadie la vea en el código.

---

## 5. 🩺 El inquilino que se queda en la conexión

Con un pool, la conexión que atendió una petición atiende la siguiente, de otro inquilino. Lo que se
fijó en ella puede quedarse:

```text
tienda=# SET ROLE app_mt;
SET
tienda=> BEGIN;
BEGIN
tienda=*> SET app.inquilino = 'ES';
SET
tienda=*> SELECT count(*) FROM pedidos_mt;
 count 
-------
 71108
(1 fila)

tienda=*> COMMIT;
COMMIT
tienda=> SELECT current_setting('app.inquilino') AS queda, count(*) FROM pedidos_mt;
 queda | count 
-------+-------
 ES    | 71108
(1 fila)

tienda=> RESET app.inquilino;
RESET
tienda=> BEGIN;
BEGIN
tienda=*> SET LOCAL app.inquilino = 'MX';
SET
tienda=*> SELECT count(*) FROM pedidos_mt;
 count  
--------
 140335
(1 fila)

tienda=*> COMMIT;
COMMIT
tienda=> SELECT current_setting('app.inquilino', true) AS queda, count(*) FROM pedidos_mt;
 queda | count 
-------+-------
       |     0
(1 fila)

tienda=> RESET ROLE;
RESET
```

- **`SET` dura toda la sesión**, no la transacción: tras el `COMMIT`, la conexión sigue con `ES`. La
  siguiente petición que reciba esa conexión del pool, de otro inquilino, **ve los pedidos de
  España** si olvida fijar el suyo.
- **`SET LOCAL` dura solo la transacción**: tras el `COMMIT` el valor queda vacío y la consulta
  devuelve cero filas. Falla cerrada.
- **La regla**: el inquilino se fija con `SET LOCAL` dentro de la transacción de cada petición, o se
  reinicia al devolver la conexión al pool: cada conexión de
  [`10/01`](../10-interfaz-con-los-lenguajes/01-el-driver-la-conexion-y-el-pool.md) vive muchas
  peticiones, y arrastra lo que cada una deje fijado.

> **⚠️ Advertencia.** Una fuga entre inquilinos por una conexión reutilizada no deja error en ningún
> registro: devuelve datos correctos del inquilino equivocado. Se prueba a propósito, con dos
> peticiones seguidas de inquilinos distintos por la misma conexión.

---

## 6. ⚖️ Esquema por inquilino

La alternativa es repetir las tablas en un esquema por cliente. Doscientos inquilinos con las seis
tablas de la tienda, vacías:

```text
tienda=# SELECT count(*) AS objetos FROM pg_class;
 objetos 
---------
     464
(1 fila)

tienda=# \timing on
El despliegue de duración está activado.
tienda=# DO $$ BEGIN FOR i IN 1..200 LOOP EXECUTE format('CREATE SCHEMA inquilino_%s', i); EXECUTE format('CREATE TABLE inquilino_%s.clientes (LIKE public.clientes INCLUDING ALL)', i); EXECUTE format('CREATE TABLE inquilino_%s.productos (LIKE public.productos INCLUDING ALL)', i); EXECUTE format('CREATE TABLE inquilino_%s.pedidos (LIKE public.pedidos INCLUDING ALL)', i); EXECUTE format('CREATE TABLE inquilino_%s.pedido_lineas (LIKE public.pedido_lineas INCLUDING ALL)', i); EXECUTE format('CREATE TABLE inquilino_%s.pagos (LIKE public.pagos INCLUDING ALL)', i); EXECUTE format('CREATE TABLE inquilino_%s.eventos_pedido (LIKE public.eventos_pedido INCLUDING ALL)', i); END LOOP; END $$;
DO
Duración: 1144,670 ms (00:01,145)
tienda=# \timing off
El despliegue de duración está desactivado.
tienda=# SELECT count(*) AS objetos FROM pg_class;
 objetos 
---------
    7064
(1 fila)

tienda=# \timing on
El despliegue de duración está activado.
tienda=# DO $$ BEGIN FOR i IN 1..200 LOOP EXECUTE format('ALTER TABLE inquilino_%s.pedidos ADD COLUMN canal text', i); END LOOP; END $$;
DO
Duración: 14,044 ms
tienda=# \timing off
El despliegue de duración está desactivado.
```

- **`LIKE public.clientes INCLUDING ALL`** copia la definición de la tabla con sus índices,
  restricciones y valores por defecto. **`format`** con `%s` compone el nombre de cada esquema.
- **De 464 a 7 064 objetos en `pg_class`**: 6 600 más, 33 por inquilino entre tablas, índices,
  secuencias y tablas TOAST. Cada objeto ocupa sitio en el catálogo, en la caché de cada conexión y
  en cada respaldo.
- **La migración tardó 14 ms**, porque las tablas están vacías; con datos, son **doscientas
  migraciones**, cada una con sus bloqueos de [`06/04`](../06-operacion/04-expandir-contraer.md), y
  una que falle a la mitad deja inquilinos en versiones distintas.
- **A cambio, la separación es más fuerte**: una consulta sin filtro solo ve su esquema, y restaurar
  o exportar un inquilino es un esquema entero.

**Base por inquilino** lleva eso más lejos: separación casi total, respaldo y restauración por
cliente. Y el coste del pool: en PostgreSQL una conexión es a una base, así que cada inquilino
necesita sus propias conexiones, y cien inquilinos con diez conexiones cada uno son mil procesos.

---

## 7. 🧭 Cómo se elige

- **Columna discriminadora con seguridad de fila**, por defecto: una base, una migración, un
  respaldo; la política con el tipo correcto, el rol de la aplicación sin `BYPASSRLS` ni propiedad,
  y el inquilino con `SET LOCAL`.
- **Esquema por inquilino** con pocos inquilinos grandes que exigen separación o exportación por
  cliente, sabiendo que cada migración se repite en todos.
- **Base por inquilino** cuando un contrato o una norma exige aislamiento físico, o un inquilino es
  tan grande que merece su propia máquina.
- **Mezclas**: los inquilinos pequeños en una base compartida con columna, los grandes en la suya.

**Cuánto cuesta equivocarse**: pasar de columna a esquema o a base con datos es una migración de
toda la plataforma; y una fuga entre inquilinos, por cualquiera de los tres caminos, es el fallo que
no se deshace.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** La seguridad a nivel de fila, `current_setting`, `SET LOCAL` y los
> esquemas como se usan aquí son de PostgreSQL; el estándar no define políticas de fila. Los tres
> modelos son convención de arquitectura.

| Afirmación | Categoría | PostgreSQL 18 |
|---|---|---|
| La base puede añadir el filtro por inquilino a cada consulta | Motor | Sí, con RLS: 71 108 de 1 000 000 |
| El superusuario respeta las políticas | Motor | No: vio el millón |
| La política puede anular un índice | Motor | Sí: 177 ms con conversión de la columna, 18 sin ella |
| Un `SET` de sesión se borra al confirmar | Motor | No: la conexión siguió con `ES` |
| `SET LOCAL` se borra al confirmar | Motor | Sí: cero filas después |
| Doscientos esquemas pesan en el catálogo | Motor | Sí: de 464 a 7 064 objetos |
| Columna con RLS por defecto; esquema o base cuando se exige separación | Convención | — |

**Convención, la que más se repite.** *«Con un `WHERE inquilino = ?` en el repositorio ya está»* —
funciona hasta la primera consulta escrita a mano, el primer informe o la primera conexión
reutilizada sin reiniciar. La seguridad de fila existe para que olvidarlo no sea una fuga.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con RLS nadie ve datos ajenos" | El superusuario y el dueño de la tabla se la saltan, salvo `FORCE` |
| "La política no afecta al rendimiento" | Con la conversión de la columna, 177 ms; sin ella, 18 |
| "Si falta el inquilino, la consulta devuelve todo" | Sin `app.inquilino`, dio error: falla cerrada |
| "El `SET` del inquilino dura la petición" | Dura la sesión: la conexión siguió con `ES` tras el `COMMIT` |
| "Un esquema por cliente es gratis" | Doscientos son 6 600 objetos más y doscientas migraciones |
| "Base por cliente, y listo" | Cada base necesita sus conexiones: cien clientes con diez son mil procesos |
| "El filtro en el código basta" | Basta hasta la primera consulta que lo olvide |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Row Security Policies»: quién se salta las políticas y
  `FORCE`. <https://www.postgresql.org/docs/18/ddl-rowsecurity.html>
- **Documentación** — PostgreSQL 18, «CREATE POLICY».
  <https://www.postgresql.org/docs/18/sql-createpolicy.html>
- **Documentación** — PostgreSQL 18, «System Administration Functions»: `current_setting` y
  `missing_ok`. <https://www.postgresql.org/docs/18/functions-admin.html>
- **Documentación** — PostgreSQL 18, «Schemas».
  <https://www.postgresql.org/docs/18/ddl-schemas.html>

---

## 🧠 Preguntas

1. ¿Qué es un inquilino en una plataforma? 🟢
2. ¿Cuáles son los tres modelos de separación? ¿Qué parte es del motor y qué parte es convención? 🟢
3. ¿Qué es la seguridad a nivel de fila? 🟢
4. ¿Qué diferencia `SET` de `SET LOCAL`? 🟡
5. ¿Qué pasa si una consulta con RLS se lanza sin haber fijado `app.inquilino`, y por qué es bueno?
   🟡
6. ¿Quién se salta las políticas de fila, según la documentación? 🟡
7. ¿Por qué la consulta de los pedidos de `MX` devolvió cero filas con `ES` fijado? 🟡
8. ¿Qué crece en el catálogo con un esquema por inquilino? 🟡
9. ¿Por qué la base por inquilino complica el pool de conexiones? 🟡
10. ¿Por qué la política con `current_setting` sin conversión anuló el índice? 🟠
11. ¿Cómo puede un pool de conexiones provocar una fuga entre inquilinos, y cómo se evita? 🟠
12. ¿Por qué la aplicación no puede conectarse como dueña de las tablas con RLS? 🟠
13. ¿Qué cuesta una migración con doscientos esquemas, y qué pasa si falla a la mitad? 🟠
14. ¿Cuándo elegirías esquema por inquilino en vez de columna discriminadora? 🟠
15. ¿Qué tienen en común la trampa del tipo en la política y la de la volatilidad de `05/01`? 🟠
16. Diseña la separación de datos de una plataforma con dos mil tiendas pequeñas y tres grandes que
    exigen aislamiento. 🔴
17. Diagnostica: un cliente de la plataforma ve, a veces, pedidos de otra tienda, siempre justo
    después de un pico de tráfico. 🔴
18. Defiende o refuta «un esquema por cliente es lo más seguro y lo más simple», con los números del
    capítulo. 🔴

---

**Anterior:** [`04`](04-borrado-logico-auditoria-e-historial.md) — borrado lógico, auditoría e
historial · **Siguiente:** [`06`](06-paginacion-y-busqueda-de-texto.md) — paginación y búsqueda de
texto · **Relacionado:**
[`10/01`](../10-interfaz-con-los-lenguajes/01-el-driver-la-conexion-y-el-pool.md) — el pool, cuyas
conexiones viven muchas peticiones.
