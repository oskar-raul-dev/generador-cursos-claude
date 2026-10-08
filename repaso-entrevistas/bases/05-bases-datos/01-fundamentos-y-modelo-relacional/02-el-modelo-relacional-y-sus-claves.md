# 02 — El modelo relacional y sus claves

> Qué es exactamente una relación y por qué no es una hoja de cálculo, y cuántas clases de clave hay
> de verdad: candidata, primaria, alternativa, compuesta y foránea. Cierra con la decisión que peor
> se argumenta en las entrevistas: **clave natural frente a clave sustituta**. **Asume leído:**
> [`01`](01-que-resuelve-un-dbms.md) — de ahí viene que el motor, y no tu código, es quien garantiza
> la integridad. **Vigencia:** 20 de septiembre de 2026.

---

## 1. 🎯 El problema

Te piden un informe sencillo: *"un renglón por pedido, con la fecha en que se creó"*. Como
`eventos_pedido` guarda el rastro de cada pedido, escribes el `JOIN` obvio y cuentas.

```text
tienda=# SELECT count(*) AS filas_join
tienda-#   FROM pedidos p JOIN eventos_pedido e ON e.pedido_id = p.id;
 filas_join
------------
    4100000
(1 fila)
```

Un millón de pedidos y el informe trae 4 100 000 renglones: 4,1 eventos por pedido de media, y
`PED-00042` tiene tres. `eventos_pedido.pedido_id` **no identifica una fila**, identifica un grupo.
El informe no está mal escrito, está mal razonado: asumió una clave que no existe.

Ese es el tema del capítulo: no "qué es una clave primaria" —eso lo recita cualquiera— sino **qué
conjuntos de columnas identifican de verdad una fila, cuáles declaraste y qué te cobra el motor**.

---

## 2. 🧱 Relación, tupla, atributo y dominio

Las cuatro palabras del modelo de Codd, con su traducción al SQL que sí escribes:
| Modelo relacional | En SQL | En el esquema de la tienda |
|---|---|---|
| Relación | Tabla | `clientes` |
| Tupla | Fila | el cliente `CLI-00311` |
| Atributo | Columna | `clientes.pais` |
| Dominio | Tipo + restricciones | `char(2)` con valores ISO 3166-1 |

El **dominio** es el que más se olvida. No es el tipo a secas: es el tipo **más todo lo que
restringe los valores admisibles**. Una violación, corrida de verdad y revertida:

```text
tienda=# BEGIN;
BEGIN
tienda=*# UPDATE pedidos SET estado = 'DEVUELTO' WHERE codigo = 'PED-00042';
ERROR:  new row for relation "pedidos" violates check constraint "pedidos_estado_check"
DETALLE:  Failing row contains (42, PED-00042, 26446, DEVUELTO, 3186.23, 2025-02-21 03:08:09.349067+00, null).
tienda=!# ROLLBACK;
ROLLBACK
```

- `DEVUELTO` no está en el dominio de `pedidos.estado`, y el motor te devuelve la fila entera que
  iba a escribir, incluido el `null` de `actualizado_en`. El tipo hace lo mismo un nivel más abajo:
  `UPDATE clientes SET pais = 'ESP'` responde `ERROR: value too long for type character(2)`.
  **Cuánto cuesta:** una comparación en memoria por fila escrita, sin E/S adicional.

Y aquí muere la analogía de la hoja de cálculo. Una relación **no tiene orden de filas** y **no
tiene celdas vacías**: tiene `NULL`, que es otra cosa y tiene su capítulo en
[`06`](06-nulos-y-logica-de-tres-valores.md).

> **Veredicto:** una relación es un conjunto de tuplas sobre dominios declarados. Si el orden de las
> filas importa en tu razonamiento, te falta un `ORDER BY`; si el dominio importa, un `CHECK`.

---

## 3. 🧱 La familia de claves

Una **clave candidata** es un conjunto **mínimo** de atributos que identifica una tupla de forma
única. Mínimo importa: si `(id)` identifica, `(id, email)` también, pero le sobra una columna. De
todas las candidatas eliges una y la declaras **primaria**; las demás son **alternativas** y se
declaran con `UNIQUE`. `clientes` tiene tres y las declara todas:

```text
tienda=# SELECT conname, contype, pg_get_constraintdef(oid) AS definicion
tienda-#   FROM pg_constraint
tienda-#  WHERE conrelid = 'clientes'::regclass AND contype IN ('p','u')
tienda-#  ORDER BY contype DESC, conname;
       conname       | contype |    definicion
---------------------+---------+------------------
 clientes_codigo_key | u       | UNIQUE (codigo)
 clientes_email_key  | u       | UNIQUE (email)
 clientes_pkey       | p       | PRIMARY KEY (id)
(3 filas)
```

- `contype = 'p'` es la primaria, `'u'` las alternativas. `id` es candidata por construcción y
  `codigo` porque el negocio promete que `CLI-00311` es uno solo. `email` lo es porque la tienda
  decidió que no haya dos cuentas con el mismo correo — **una regla de negocio, no una verdad del
  mundo**: dos personas pueden compartir buzón.
- **Cuánto cuesta:** cada `UNIQUE` es un índice B-tree más. Sobre `pedidos`, la primaria ocupa 21 MB
  y la alternativa sobre `codigo` 30 MB; cada `INSERT` paga las dos.

**Cuándo sí declararla:** cuando la unicidad sea una regla del negocio. **Cuándo no:** cuando solo
*observas* que hoy no hay duplicados; es una promesa que alguien romperá a las tres de la mañana.

> **💡 Truco.** Ante "¿cuál es la clave primaria de esta tabla?", la respuesta que suma es "hay tres
> candidatas; la primaria es `id` **porque** las otras dos las fija el negocio y pueden cambiar".
> Nombrar la familia entera distingue al que estudió del que recita.

---

## 4. 🧱 Claves compuestas y foráneas

Una clave **compuesta** es una candidata de más de una columna. `pedido_lineas` es el caso: una
línea no existe sin su pedido, y dentro del pedido se numera desde 1.

```text
tienda=# BEGIN;
BEGIN
tienda=*# INSERT INTO pedido_lineas (pedido_id, linea, producto_id, cantidad, precio_unit)
tienda-*# VALUES (42, 2, 17, 1, 99.00);
ERROR:  duplicate key value violates unique constraint "pedido_lineas_pkey"
DETALLE:  Key (pedido_id, linea)=(42, 2) already exists.
tienda=!# ROLLBACK;
ROLLBACK
```

- Ni `pedido_id` ni `linea` identifican solos: hay tres filas con `pedido_id = 42` y un millón con
  `linea = 1`. El par sí, y `PED-00042` ya tenía su línea 2 ocupada.
- **El orden de las columnas no cambia qué identifica, pero sí el índice que el motor construye.**
  `PRIMARY KEY (pedido_id, linea)` sirve para `WHERE pedido_id = 42` y para el par completo, y
  **no** para `WHERE linea = 2` a secas. Es del motor, no del modelo.

Una clave **foránea** referencia una candidata de otra tabla —en la práctica, casi siempre la
primaria—. El motor la verifica en las dos direcciones:

```text
tienda=*# DELETE FROM clientes WHERE codigo = 'CLI-00311';
ERROR:  update or delete on table "clientes" violates foreign key constraint "pedidos_cliente_id_fkey" on table "pedidos"
DETALLE:  Key (id)=(311) is still referenced from table "pedidos".
```

- Hacia adelante impide apuntar a un cliente que no existe; hacia atrás, borrar uno al que alguien
  apunta: `CLI-00311` tiene 52 pedidos. Los dos intentos van dentro de `BEGIN … ROLLBACK`.
- **Cuánto cuesta:** cada `INSERT` en `pedidos` busca en `clientes_pkey`, y cada `DELETE` en
  `clientes` busca en `pedidos` si queda alguien apuntando; sin índice del lado hijo, esa segunda
  búsqueda es un recorrido secuencial de la tabla entera. **Cuándo no:** en cargas masivas, donde se
  suelta, se carga y se vuelve a validar en bloque.

> **⚠️ Advertencia.** PostgreSQL **no** indexa la columna hija de una foránea: aquí
> `pedidos.cliente_id` no tiene índice. MySQL/InnoDB sí lo crea solo, y aparece en el `SHOW CREATE
> TABLE` como una `KEY` que tú nunca escribiste. Es de motor, no de modelo.

---

## 5. 🧱 `UNIQUE` con nulos: la clave candidata parcial

`pagos.referencia` guarda el identificador que devuelve la pasarela. Es `UNIQUE` y anulable: un pago
en efectivo no tiene referencia, y 273 126 de los 820 000 pagos no la traen.

```text
tienda=# SELECT count(*) AS pagos, count(referencia) AS con_ref FROM pagos;
 pagos  | con_ref
--------+---------
 820000 |  546874
(1 fila)

tienda=# BEGIN;
BEGIN
tienda=*# INSERT INTO pagos (pedido_id, metodo, importe, pagado_en, referencia)
tienda-*# VALUES (42, 'EFECTIVO', 10.00, now(), NULL),
tienda-*#        (42, 'EFECTIVO', 20.00, now(), NULL);
INSERT 0 2
tienda=*# ROLLBACK;
ROLLBACK
```

Dos filas más con `referencia` nula entran sin protestar, y el `UNIQUE` sigue ahí. Por eso
`referencia` es **candidata parcial**: identifica a las filas que la tienen y no dice nada de las
273 126 que no. No puede ser primaria, porque una primaria exige `NOT NULL`. PostgreSQL 15 en
adelante deja cambiar esa regla con `NULLS NOT DISTINCT`, y aquí no cuela:

```text
tienda=# BEGIN;
BEGIN
tienda=*# ALTER TABLE pagos ADD CONSTRAINT pagos_referencia_estricta
tienda-*#   UNIQUE NULLS NOT DISTINCT (referencia);
ERROR:  could not create unique index "pagos_referencia_estricta"
DETALLE:  Key (referencia)=(null) is duplicated.
CONTEXTO:  parallel worker
tienda=!# ROLLBACK;
ROLLBACK
```

- `NULLS NOT DISTINCT` le pide al motor que trate los nulos como iguales. Con 273 126 nulos el
  índice no se puede construir y el `ALTER` falla antes de tocar nada. MySQL 9.7.2 se comporta igual
  que PostgreSQL por defecto —la misma inserción de dos nulos pasa— y **no tiene** esa cláusula.

> **🧠 Modelo mental.** `UNIQUE` no dice "no hay repetidos". Dice "no hay **dos valores conocidos**
> repetidos". El nulo no es un valor: es la ausencia de uno, y dos ausencias no son iguales.

---

## 6. ⚖️ Natural frente a sustituta

Una clave **natural** sale del negocio y el usuario la ve: `CLI-00311`, un NIF, un ISBN. Una
**sustituta** la inventa el sistema y no significa nada fuera de él: el `id` de `IDENTITY`. Aquí
conviven las dos en cada tabla, a propósito.

| Criterio | Natural (`codigo`, `text`) | Sustituta (`id`, `bigint`) |
|---|---|---|
| Índice de la clave, 1 000 000 de filas | 30 MB | 21 MB |
| Esa columna replicada en 3 500 000 líneas | 36 MB | 27 MB |
| Si el negocio cambia el formato | `ON UPDATE CASCADE` reescribe las filas hijas | no se entera |
| Legible en un log o en una URL | sí | no |
| Se puede asignar antes de insertar | sí | no, la da el motor |

Las dos primeras filas salen de `pg_relation_size` y de `sum(pg_column_size(...))` sobre las tablas
reales: **un 43 % más de índice y un 33 % más de columna replicada**, por una clave de once
caracteres. Pero el disco no es el argumento bueno: el bueno es que **una clave natural es un dato
del negocio, y los datos del negocio cambian**. El día que marketing decida que los códigos pasan a
`ES-CLI-00311`, con la sustituta actualizas 50 000 filas; con la natural propagas el cambio a
`pedidos`, `pedido_lineas`, `pagos` y `eventos_pedido`, con las tablas bloqueadas mientras dure.

El criterio cabe en tres preguntas: **¿el valor es inmutable?** —si alguien puede querer corregirlo,
es alternativa y no primaria—; **¿es compacto y comparable barato?**, porque ocho bytes de entero
contra cuarenta de texto con *collation* (reglas de ordenación) se notan en cada índice que lo
replica; y **¿lo genera el sistema sin coordinarse con nadie?**, que separa un `IDENTITY` de un UUID
que la aplicación asigna antes de insertar. Con una excepción: en **catálogos cerrados y estables**
la natural gana, y `clientes.pais char(2)` con ISO 3166-1 es exactamente eso.

> **Veredicto:** clave sustituta como primaria, clave natural declarada como `UNIQUE` y usada en
> toda la interfaz humana. No es "una u otra": es **las dos, cada una en su puesto**, que es justo
> lo que hace este esquema.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas** para esta
> tabla. Donde la columna "Estándar" dice *no verificado*, lo afirmado es lo que hacen los motores,
> comprobado en sesión. Es la diferencia entre citar y recordar.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| `PRIMARY KEY` implica `NOT NULL` y unicidad | No verificado | Sí | Sí, y **convierte la columna a `NOT NULL` en silencio** | **No**: admite nulos salvo en `INTEGER PRIMARY KEY` o tabla `STRICT` |
| `UNIQUE` admite varios nulos | No verificado | Sí (medido: 273 126) | Sí (medido: 273 126) | Sí |
| Se pueden tratar los nulos como iguales | No verificado | Sí, `UNIQUE NULLS NOT DISTINCT` (15+) | No existe la cláusula | No existe la cláusula |
| Declarar la clave crea un índice | No verificado; es decisión de implementación | Sí, B-tree con el nombre de la restricción | Sí, y la primaria **es** el índice agrupado | Sí, salvo `INTEGER PRIMARY KEY`, que es alias del `rowid` |
| La columna hija de una foránea se indexa sola | No verificado | **No**: lo haces tú | Sí, InnoDB la crea si falta | No |

Lo de SQLite, comprobado en una base en memoria para no tocar `tienda.db`:

```text
sqlite> CREATE TABLE clientes (codigo TEXT PRIMARY KEY, nombre TEXT NOT NULL);
sqlite> INSERT INTO clientes VALUES (NULL, 'sin código');
sqlite> INSERT INTO clientes VALUES (NULL, 'otro sin código');
sqlite> SELECT count(*) AS filas, count(codigo) AS con_codigo FROM clientes;
filas|con_codigo
2|0
```

**Convención, no estándar:** que la primaria se llame `id`, sea un entero autogenerado y vaya
primera en el `CREATE TABLE`. No lo pide nadie: viene de los ORM de los 2000 y hoy es lo que un
revisor espera ver. La otra mitad de esa costumbre sí es falsa a medias —*"la primaria siempre debe
ser sustituta"*—: en catálogos cerrados la natural es más barata.

---

## 8. 🔭 Dónde aparece de verdad

- **El informe que trae filas de más.** Es el caso de §1: un `JOIN` contra una tabla donde la
  columna que usaste no es clave. El síntoma es un total que no cuadra, no un fallo.
- **El `UPDATE` que toca doce filas.** `UPDATE pedidos SET estado='ENVIADO' WHERE
  codigo='PED-00042'` toca una fila **porque `codigo` es `UNIQUE`**. Si alguien suelta esa
  restricción para una importación y olvida restaurarla, la sentencia sigue siendo válida y deja de
  ser correcta.

> **🩺 Diagnóstico.** Antes de culpar al `JOIN`, comprueba si la columna por la que unes es clave:
> `SELECT pedido_id, count(*) FROM eventos_pedido GROUP BY pedido_id HAVING count(*) > 1 LIMIT 5;`.
> Si devuelve algo, no es clave y tu informe multiplica filas.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La clave primaria es la que identifica la fila" | Es **una** de las candidatas, la elegida. `clientes` tiene tres y las tres identifican |
| "`UNIQUE` garantiza que no hay repetidos" | Garantiza que no hay dos **valores conocidos** repetidos. En `pagos.referencia` conviven 273 126 nulos |
| "Declarar una foránea es gratis" | Cuesta una búsqueda por `INSERT` en el hijo y otra por `DELETE` en el padre; sin índice del lado hijo, esa segunda es un recorrido secuencial |
| "Siempre clave sustituta" | En catálogos cerrados y estables —`pais char(2)` con ISO 3166-1— la natural es más barata y evita un `JOIN` |
| "El orden de las columnas de una clave compuesta da igual" | Da igual para el modelo y **no** para el índice: `(pedido_id, linea)` no sirve para `WHERE linea = 2` |
| "`PRIMARY KEY` implica `NOT NULL` en todos los motores" | En SQLite no, por compatibilidad histórica: dos filas con la clave nula entran sin queja |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Constraints»: primarias, únicas y foráneas, con el
  comportamiento de los nulos. <https://www.postgresql.org/docs/18/ddl-constraints.html>
- **Documentación** — PostgreSQL 18, «CREATE TABLE»: `NULLS NOT DISTINCT` y qué índice crea cada
  restricción. <https://www.postgresql.org/docs/18/sql-createtable.html>
- **Documentación** — MySQL 9.7, «FOREIGN KEY Constraints»: por qué InnoDB crea el índice del lado
  hijo. <https://dev.mysql.com/doc/refman/9.7/en/create-table-foreign-keys.html>
- **Documentación** — MySQL 9.7, «Clustered and Secondary Indexes»: la primaria como índice
  agrupado. <https://dev.mysql.com/doc/refman/9.7/en/innodb-index-types.html>
- **Documentación** — SQLite, «Quirks», *PRIMARY KEYs Can Sometimes Contain NULL*: el fallo
  histórico que ya no se puede arreglar. <https://www.sqlite.org/quirks.html>
- **Estándar** — ISO/IEC 9075-2 (*Foundation*), cláusulas de restricción única y referencial. De
  pago, sin URL pública y **no verificadas en esta edición**.
- **Referencia** — Markus Winand, *Use The Index, Luke!*, «Concatenated Keys»: por qué el orden de
  las columnas de una clave compuesta decide qué consultas la aprovechan.
  <https://use-the-index-luke.com/sql/where-clause/the-equals-operator/concatenated-keys>

---

## 🧠 Preguntas

1. Traduce relación, tupla, atributo y dominio a su equivalente en SQL, con un ejemplo de cada uno
   en la tienda. 🟢
2. ¿Qué es una clave candidata, y qué le añade la palabra "mínima"? 🟢
3. ¿Cuántas claves candidatas tiene `clientes`, cuáles son y cuál se declaró primaria? 🟢
4. ¿Cuál es la primaria de `pedido_lineas` y por qué ninguna de sus dos columnas sirve sola? 🟢
5. ¿Por qué `pagos.referencia` no puede ser la clave primaria de `pagos`? 🟢
6. Diferencia clave alternativa de clave foránea: ¿qué restringe cada una? 🟡
7. ¿Qué significa que `UNIQUE` admita varios nulos, y cuántos hay hoy en `pagos.referencia`? 🟡
8. Distingue clave natural de sustituta, y di cuál de las dos ve el usuario en este esquema. 🟡
9. ¿`PRIMARY KEY` implica `NOT NULL` en los tres motores? Si alguno no, dilo y explica por qué. 🟡
10. Que declarar una clave cree un índice, ¿lo manda el estándar o lo decide cada motor? 🟡
11. En el informe de §1, ¿por qué el `JOIN` devuelve 4 100 000 filas? Nombra la clave que falta. 🟠
12. Justifica por qué `pedidos.codigo` es `UNIQUE` y no `PRIMARY KEY`, con un argumento de coste y
    otro de estabilidad del dato. 🟠
13. `clientes.pais` no lleva sustituta detrás y `clientes` sí. Explica el criterio que los separa. 🟠
14. PostgreSQL no indexa la columna hija de una foránea y MySQL sí. ¿Qué consecuencia tiene en un
    `DELETE FROM clientes`, y qué harías en cada motor? 🟠
15. Alguien propone `UNIQUE (cliente_id, creado_en)` en `pedidos` porque "hoy no hay duplicados".
    ¿Qué le respondes, y qué comprobarías antes? 🟠
16. El `ALTER TABLE … UNIQUE NULLS NOT DISTINCT (referencia)` falla hoy: explica por qué, y qué
    tendría que cambiar en el negocio para que fuera la restricción correcta. 🟠
17. Escribe el DDL de una `pedido_lineas` con clave sustituta `id` como primaria en lugar de la
    compuesta, conservando la garantía que hoy da `PRIMARY KEY (pedido_id, linea)`. 🔴
18. Los códigos de cliente pasan de `CLI-00311` a `ES-CLI-00311`. Escribe la secuencia para el
    esquema actual y la que haría falta si `codigo` fuera la primaria referenciada por `pedidos`, y
    compara el bloqueo de cada una. 🔴
19. Escribe las sentencias que demuestren, en una sesión con `BEGIN` y `ROLLBACK`, que
    `pagos.referencia` acepta nulos repetidos y rechaza no nulos repetidos. Di qué esperas ver. 🔴
20. Diseña el DDL de una tabla de direcciones de envío para `clientes` donde cada cliente tenga
    varias direcciones pero **solo una predeterminada**, con restricciones declaradas. 🔴

---

**Anterior:** [`01`](01-que-resuelve-un-dbms.md) · **Siguiente:** [`03`](03-algebra-relacional.md) ·
**Relacionado:** [`05`](05-del-modelo-er-al-esquema.md) — las cardinalidades del modelo ER
traducidas a estas restricciones · [`06`](06-nulos-y-logica-de-tres-valores.md) — por qué dos nulos
no chocan contra un `UNIQUE`.
