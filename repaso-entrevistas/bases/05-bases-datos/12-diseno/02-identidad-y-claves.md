# 02 — Identidad y claves

> Clave natural o sustituta, entero o UUID, y qué identificador se enseña fuera de la base. Medido
> en PostgreSQL: el correo del cliente como clave primaria, referenciado por el millón de pedidos,
> ocupa un índice apenas mayor que el `bigint` —9 152 kB frente a 7 800— y cambiarlo reescribe los
> 52 pedidos de `CLI-00311` en 2 ms; el coste de verdad está en lo que la base no puede cambiar. Y
> un UUIDv7 publicado en una API dice, a quien lo reciba, cuándo se creó. **Asume leído:**
> [`05/03`](../05-programacion-en-el-motor/03-claves-generadas.md), que midió el coste de UUID en el
> índice, y
> [`01/02`](../01-fundamentos-y-modelo-relacional/02-el-modelo-relacional-y-sus-claves.md), las
> claves. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Natural o sustituta](#2--natural-o-sustituta)
- [3. Lo que cuesta una clave natural, medido](#3--lo-que-cuesta-una-clave-natural-medido) · [4.
  Entero o UUID](#4-️-entero-o-uuid)
- [5. La clave que sale a la API](#5--la-clave-que-sale-a-la-api) · [6. Cómo se
  elige](#6--cómo-se-elige)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Todo diseño de tabla empieza por la misma pregunta, y en una entrevista se hace con trampa: «¿qué
clave primaria le pondrías a `clientes`?». Si la respuesta es el correo, llega la repregunta —«¿y si
el cliente lo cambia?»—. Si es un entero autoincremental, llega otra —«¿y si lo enseñas en la
URL?»—. Si es un UUID, la tercera —«¿cuánto cuesta en el índice?»—.

Las tres repreguntas tienen respuesta medida.
[`05/03`](../05-programacion-en-el-motor/03-claves-generadas.md) midió la tercera. Este capítulo
mide la primera, ordena la segunda y termina con la decisión que casi todos los sistemas acaban
tomando: **una clave interna para la base y otro identificador para fuera**.

> **📝 Contexto.** Las sesiones se corrieron en la copia aislada `bd-lab-prueba`, recargada desde
> cero para el bloque 12 (22/22 en `verificar.sql`), con tablas de prueba —`clientes_nat` y
> `pedidos_nat`— que copian `clientes` y `pedidos` con el correo como clave. El índice sobre
> `pedidos (cliente_id)` que se crea para comparar no existe en el entorno principal. **Longitud:**
> unas 310 líneas; capítulo normal.

---

## 2. 🧱 Natural o sustituta

**Qué es:** una **clave natural** es un dato del negocio que ya identifica la fila: el correo de un
cliente, el código de un producto, un número de documento. Una **clave sustituta** es un valor sin
significado que genera la base —un entero, un UUID— solo para identificar.

**Quién lo manda:** el **estándar** define la clave primaria y la foránea; qué se elige como clave
es **convención** de diseño. La tienda usa las dos: `id bigint` como clave primaria sustituta y
`codigo` —`PED-00042`, `CLI-00311`— como clave natural con restricción `UNIQUE`.

| | Natural | Sustituta |
|---|---|---|
| **Significado** | Sí: se entiende sin mirar otra tabla | No |
| **Cambia** | A veces: un correo, un nombre, una normativa | Nunca, por definición |
| **Ancho** | El del dato: un correo, unos 25 bytes | 8 bytes un `bigint`, 16 un UUID |
| **Evita duplicados de negocio** | Sí, es la propia clave | No: hace falta además un `UNIQUE` sobre el dato |

- **La trampa de la sustituta sola**: sin un `UNIQUE` sobre el dato natural, dos filas con el mismo
  correo son dos clientes distintos para la base. La sustituta identifica filas, no clientes.
- **La trampa de la natural**: el dato que «nunca cambia» cambia. Los correos se cambian, los
  productos se renombran, los formatos de documento se reforman.

---

## 3. 🩺 Lo que cuesta una clave natural, medido

Dos tablas de prueba con el correo como clave primaria de los clientes y como clave foránea del
millón de pedidos, con `ON UPDATE CASCADE`, frente a la tienda real, que referencia por
`cliente_id`:

```text
tienda=# \timing on
El despliegue de duración está activado.
tienda=# CREATE TABLE clientes_nat AS SELECT email, nombre FROM clientes;
SELECT 50000
Duración: 30,910 ms
tienda=# ALTER TABLE clientes_nat ADD PRIMARY KEY (email);
ALTER TABLE
Duración: 129,171 ms
tienda=# CREATE TABLE pedidos_nat AS SELECT p.codigo, c.email AS cliente_email, p.total FROM pedidos p JOIN clientes c ON c.id = p.cliente_id;
SELECT 1000000
Duración: 555,006 ms
tienda=# ALTER TABLE pedidos_nat ADD FOREIGN KEY (cliente_email) REFERENCES clientes_nat (email) ON UPDATE CASCADE;
ALTER TABLE
Duración: 180,606 ms
tienda=# CREATE INDEX pedidos_nat_cliente ON pedidos_nat (cliente_email);
CREATE INDEX
Duración: 930,154 ms
tienda=# CREATE INDEX pedidos_cliente ON pedidos (cliente_id);
CREATE INDEX
Duración: 158,654 ms
tienda=# \timing off
El despliegue de duración está desactivado.
tienda=# SELECT pg_size_pretty(pg_relation_size('pedidos_nat_cliente')) AS fk_email, pg_size_pretty(pg_relation_size('pedidos_cliente')) AS fk_bigint;
 fk_email | fk_bigint 
----------+-----------
 9152 kB  | 7800 kB
(1 fila)

tienda=# SELECT email, (SELECT count(*) FROM pedidos_nat WHERE cliente_email = c.email) AS pedidos FROM clientes c WHERE codigo = 'CLI-00311';
          email          | pedidos 
-------------------------+---------
 cliente311@ejemplo.test |      52
(1 fila)

tienda=# \timing on
El despliegue de duración está activado.
tienda=# BEGIN;
BEGIN
Duración: 0,335 ms
tienda=*# UPDATE clientes_nat SET email = 'cliente311@nuevo.example' WHERE email = (SELECT email FROM clientes WHERE codigo = 'CLI-00311');
UPDATE 1
Duración: 1,964 ms
tienda=*# ROLLBACK;
ROLLBACK
Duración: 0,371 ms
tienda=# BEGIN;
BEGIN
Duración: 0,214 ms
tienda=*# UPDATE clientes SET email = 'cliente311@nuevo.example' WHERE codigo = 'CLI-00311';
UPDATE 1
Duración: 1,069 ms
tienda=*# ROLLBACK;
ROLLBACK
Duración: 0,195 ms
```

- **`ON UPDATE CASCADE`** hace que cambiar el correo en `clientes_nat` lo cambie en cada pedido que
  lo referencia. Sin él, el `UPDATE` fallaría por la clave foránea.
- **El índice sobre el correo: 9 152 kB frente a 7 800** del `bigint`, solo un 17 % más, aunque cada
  correo mide unas tres veces lo que un entero. Es la **deduplicación** del B-tree, que según su
  documentación junta las entradas repetidas en una lista: cada cliente aparece en veinte pedidos y
  su correo se guarda casi una sola vez.
- **Cambiar el correo de `CLI-00311`: 1,96 ms, frente a 1,07** en la tienda real. La cascada
  reescribió sus 52 pedidos, y los dejó bloqueados hasta el final de la transacción; con la clave
  sustituta, el cambio toca una fila.
- **Lo que la sesión no puede medir** es el coste de verdad: el correo viejo sigue en los registros,
  en las cachés, en los eventos ya publicados, en otros servicios y en las facturas emitidas. La
  cascada llega hasta donde llegan las claves foráneas de esta base, y ni un paso más.

> **Veredicto:** una clave natural no es cara en el índice ni en la cascada; es cara porque sale de
> la base y no vuelve cuando cambia. Por eso va en un `UNIQUE`, y la clave primaria es sustituta.

---

## 4. ⚖️ Entero o UUID

[`05/03`](../05-programacion-en-el-motor/03-claves-generadas.md) midió el coste en el índice, con un
millón de filas:

| Clave | Carga | Índice | Hojas llenas |
|---|---|---|---|
| `bigint` | 1,09 s | 21 MB | 90 % |
| UUIDv4 | 2,82 s | 38 MB | 71 % |
| UUIDv7 | 1,75 s | 30 MB | 90 % |

- **El entero** es el más barato y el más legible, y tiene dos límites: lo genera la base, así que
  no existe antes de insertar, y **dice cuántos hay**, que es §5.
- **UUIDv7** existe antes de llegar a la base —un móvil sin conexión, varios servicios— y paga el
  ancho, no el desorden.
- **UUIDv4** paga ancho y desorden, y en InnoDB duplica la tabla y engorda cada índice secundario,
  porque cada uno lleva la clave primaria colgada.

**Cuánto cuesta cambiar de idea después**: una clave primaria está en todas las claves foráneas que
la apuntan. Pasar de entero a UUID es reescribir la tabla y todas las que la referencian, con la
secuencia de expandir y contraer de [`06/04`](../06-operacion/04-expandir-contraer.md).

---

## 5. 🩺 La clave que sale a la API

El identificador que se pone en una URL —`/pedidos/PED-00042`— **lo ve cualquiera que reciba la
respuesta**, y cuenta cosas:

- **Un entero consecutivo dice cuántos hay y cuántos se crean al día**: con el pedido de hoy y el de
  la semana pasada, la resta es el volumen de ventas. Y deja probar el siguiente, `PED-00043`.
- **Un UUIDv7 dice cuándo se creó**:

```text
tienda=# SELECT uuidv7() AS clave, uuid_extract_version(uuidv7()) AS version, uuid_extract_timestamp(uuidv7()) AS creado;
                clave                 | version |           creado           
--------------------------------------+---------+----------------------------
 01a0e445-ea97-7834-b275-6bf1362b846f |       7 | 2026-09-27 19:09:42.423+00
(1 fila)

tienda=# SELECT uuid_extract_timestamp(uuidv4()) AS creado_v4;
 creado_v4 
-----------
 
(1 fila)
```

- **`uuid_extract_timestamp`** saca la marca de tiempo de un UUID de versión 1 o 7; para las demás,
  la documentación dice que devuelve nulo, y eso dio con el v4. Cualquiera que reciba un UUIDv7
  puede hacer lo mismo, en cualquier lenguaje: la fecha de alta del cliente o la hora del pedido van
  dentro.
- **Ninguno de los dos es un permiso**. La RFC 9562 lo dice en sus consideraciones de seguridad: no
  hay que suponer que un UUID es difícil de adivinar, y **no debe usarse como credencial** cuya mera
  posesión da acceso. Un UUIDv4 no se adivina, pero si se filtra en un enlace, un registro o una
  captura, sigue abriendo la puerta si la aplicación no comprueba de quién es el pedido.

> **⚠️ Advertencia.** El fallo que se pregunta es el acceso directo a objetos ajenos: la API
> devuelve `/pedidos/PED-00043` a quien lo pide sin comprobar que es suyo. Cambiar el entero por un
> UUID lo esconde, no lo arregla. Lo que lo arregla es **comprobar la propiedad en cada petición**,
> sea cual sea el identificador.

---

## 6. 🧭 Cómo se elige

- **Clave primaria sustituta, `bigint` con `IDENTITY`**, por defecto: estrecha, creciente, interna y
  con `GENERATED ALWAYS` para que nadie la desincronice.
- **La clave natural en un `UNIQUE`**, siempre que exista: evita los duplicados de negocio y se
  puede cambiar sin tocar las claves foráneas.
- **Un identificador público distinto** si la clave interna no debe verse: un código propio sin
  secuencia visible, o un UUID. UUIDv4 si no debe revelar nada; UUIDv7 si se acepta que revele la
  fecha a cambio de un índice ordenado.
- **UUIDv7 como clave primaria** cuando la clave tiene que existir antes de llegar a la base.
- **La autorización, aparte**: el identificador nunca decide quién puede ver qué.

**Cuánto cuesta**: una columna y un índice más por el identificador público, y la disciplina de no
exponer nunca la clave interna. A cambio, cambiarla o renumerarla no rompe ninguna URL.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** La clave primaria, la foránea y `ON UPDATE CASCADE` están en el estándar.
> La deduplicación del B-tree y `uuid_extract_timestamp` son de PostgreSQL; las versiones de UUID,
> de la RFC 9562. Qué se elige como clave y qué se expone es convención de diseño.

| Afirmación | Categoría | PostgreSQL 18 |
|---|---|---|
| Cambiar una clave natural se propaga a las foráneas | Estándar | Con `ON UPDATE CASCADE`: 52 pedidos en 1,96 ms |
| Un índice sobre texto repetido ocupa mucho más que uno sobre enteros | Motor | No: 9 152 kB frente a 7 800, por la deduplicación |
| Un UUIDv7 revela cuándo se creó | Estándar, la RFC | Sí: `uuid_extract_timestamp` |
| Un UUID sirve como control de acceso | Estándar, la RFC | No: la RFC lo prohíbe |
| La clave primaria es sustituta; la natural, un `UNIQUE` | Convención | — |
| Un identificador público distinto de la clave interna | Convención | — |

**Convención, la que más se repite.** *«Con UUID en la URL ya no pueden adivinar los pedidos»* — no
adivinan el siguiente, pero cualquier identificador que se filtre abre lo que la aplicación no
proteja. La defensa es la comprobación de propiedad, no el formato.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Una clave natural ocupa mucho más en los índices" | 9 152 kB frente a 7 800, gracias a la deduplicación |
| "Con `ON UPDATE CASCADE`, cambiar la clave natural es seguro" | Cambia esta base; los registros, cachés y otros servicios guardan el valor viejo |
| "La clave sustituta evita los duplicados" | Identifica filas; sin un `UNIQUE` sobre el correo, hay dos clientes iguales |
| "UUIDv7 es opaco como el v4" | Lleva la fecha dentro: `uuid_extract_timestamp` la devolvió |
| "Un UUID en la URL protege los datos" | La RFC 9562 prohíbe usarlo como credencial; hay que comprobar la propiedad |
| "Un entero en la URL no dice nada" | Dice cuántos hay y cuántos se crean |
| "Se puede cambiar el tipo de clave más adelante" | Obliga a reescribir la tabla y todas las que la referencian |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Constraints»: claves primarias, foráneas y `ON UPDATE`.
  <https://www.postgresql.org/docs/18/ddl-constraints.html>
- **Documentación** — PostgreSQL 18, «B-Tree Indexes»: la deduplicación.
  <https://www.postgresql.org/docs/18/btree.html>
- **Documentación** — PostgreSQL 18, «UUID Functions»: `uuid_extract_timestamp`.
  <https://www.postgresql.org/docs/18/functions-uuid.html>
- **Especificación** — RFC 9562, «Universally Unique IDentifiers (UUIDs)»: las consideraciones de
  seguridad. <https://www.rfc-editor.org/rfc/rfc9562.html>

---

## 🧠 Preguntas

1. ¿Qué diferencia una clave natural de una sustituta? 🟢
2. ¿Qué hace `ON UPDATE CASCADE`? 🟢
3. ¿Qué es la deduplicación de un índice B-tree? 🟢
4. ¿Qué devuelve `uuid_extract_timestamp` para un UUIDv4, y por qué? 🟢
5. ¿Por qué una clave sustituta necesita además un `UNIQUE` sobre el dato natural? 🟡
6. ¿Por qué el índice sobre el correo ocupó solo un 17 % más que el del `bigint`? ¿Lo fija el
   estándar o es cosa del motor? 🟡
7. ¿Qué información revela un entero consecutivo en una URL? 🟡
8. ¿Qué dice la RFC 9562 sobre usar un UUID como control de acceso? 🟡
9. ¿Qué gana la tienda con tener `id` y `codigo` a la vez? 🟡
10. ¿Por qué cambiar el correo con la clave natural tardó casi el doble, y qué más bloqueó? 🟠
11. ¿Qué parte del coste de una clave natural no se puede medir dentro de la base? 🟠
12. ¿Por qué un UUIDv7 en la API puede ser un problema, si es único y no se adivina? 🟠
13. ¿Por qué pasar a UUID en la URL no arregla el acceso a pedidos ajenos? 🟠
14. ¿Cuándo elegirías UUIDv7 como clave primaria, y cuándo solo como identificador público? 🟠
15. ¿Qué cuesta cambiar de `bigint` a UUID en una tabla que ya tiene claves foráneas? 🟠
16. Diseña las claves de `clientes` y `pedidos` para una API pública en la que los clientes
    consultan sus pedidos. 🔴
17. Diagnostica: un cliente denuncia que, cambiando un número en la URL de su pedido, ve los pedidos
    de otros. El equipo propone pasar a UUID. 🔴
18. Defiende o refuta usar el correo como clave primaria de `clientes`, con los números del
    capítulo. 🔴

---

**Anterior:** [`01`](01-elegir-motor.md) — elegir motor · **Siguiente:**
[`03`](03-fechas-zonas-y-dinero.md) — fechas, zonas y dinero · **Relacionado:**
[`05/03`](../05-programacion-en-el-motor/03-claves-generadas.md) — el coste de UUID en el índice.
