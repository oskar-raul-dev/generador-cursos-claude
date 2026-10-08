# 05 — Del modelo ER al esquema

> Un diagrama ER no es documentación: es un esquema a medio escribir. Aquí se traduce cada trazo
> —cardinalidad, relación N:M, entidad débil— a la restricción que el motor sí hace cumplir (`NOT
> NULL`, `UNIQUE`, `CHECK`, `FOREIGN KEY` con `ON DELETE` y `ON UPDATE`), y se demuestra qué pasa
> cuando una de ellas falta. **Asume leído:** [`02`](02-el-modelo-relacional-y-sus-claves.md) — de
> ahí vienen clave primaria, candidata, foránea y compuesta, y la distinción entre natural y
> sustituta. **Vigencia:** 27 de septiembre de 2026.

---

## 1. 🎯 El problema

En el diagrama que el equipo pegó en la wiki, `pedidos` y `pagos` van unidos con un **1:1**: un
pedido, un pago. Los 820 000 pagos cargados le dan la razón —el máximo por pedido es 1—. Pero mira
qué acepta el esquema:

```text
tienda=# BEGIN;
BEGIN
tienda=*# INSERT INTO pagos (pedido_id, metodo, importe, pagado_en, referencia)
tienda-*# VALUES (42, 'EFECTIVO', 1.00, now(), NULL);
INSERT 0 1
tienda=*# SELECT count(*) AS pagos_del_42 FROM pagos WHERE pedido_id = 42;
 pagos_del_42 
--------------
            2
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
```

- `PED-00042` acaba de cobrarse dos veces y el motor no dijo nada: la única razón de que el máximo
  valiera 1 es que **el código que inserta pagos se ha portado bien hasta hoy**. El 1:1 del diagrama
  se implementa con una línea de DDL —`UNIQUE (pedido_id)` en `pagos`— y esa línea no está escrita.

Esa es la pregunta del capítulo: **qué restricción implementa cada decisión del diagrama, y qué se
rompe el día que falta.**

> **📝 Contexto.** Las sesiones de `psql` se volvieron a correr el 27 de septiembre de 2026 con
> `psql` en español, en una copia recién cargada del entorno; el prompt enseña el estado real de la
> transacción —`tienda=*#` dentro de ella, `tienda=!#` tras un error—.

---

## 2. 🧱 De la cardinalidad a la restricción

Un diagrama declara qué entidades hay, cómo se relacionan y con qué multiplicidad. El DDL tiene
cuatro herramientas para hacerlo cumplir, y la traducción es mecánica:

| Lo que dice el diagrama | Lo que hay que escribir |
|---|---|
| El lado "uno" es obligatorio | `cliente_id bigint NOT NULL REFERENCES clientes(id)` |
| El máximo del lado "muchos" es uno (1:1) | `UNIQUE` sobre la columna foránea |
| La relación es N:M | Tabla propia, con las dos foráneas dentro de su clave primaria |
| La entidad no existe sin su padre | `ON DELETE CASCADE`, y la clave del padre dentro de la del hijo |
| El atributo solo admite ciertos valores | `CHECK` con la lista o el rango |

Fíjate en la asimetría: **obligatoriedad y unicidad no viven en la misma cláusula**. `NOT NULL` dice
"esta fila tiene que apuntar a alguien"; `UNIQUE`, "nadie más puede apuntar al mismo". El error más
común es creer que la flecha con un "1" escribe las dos. Tres de las cuatro ya están en el esquema:

```text
tienda=# \d pedido_lineas
                 Table "public.pedido_lineas"
   Column    |     Type      | Collation | Nullable | Default
-------------+---------------+-----------+----------+---------
 pedido_id   | bigint        |           | not null |
 linea       | smallint      |           | not null |
 producto_id | bigint        |           | not null |
 cantidad    | integer       |           | not null |
 precio_unit | numeric(12,2) |           | not null |
Indexes:
    "pedido_lineas_pkey" PRIMARY KEY, btree (pedido_id, linea)
Check constraints:
    "pedido_lineas_cantidad_check" CHECK (cantidad > 0)
Foreign-key constraints:
    "pedido_lineas_pedido_id_fkey" FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
    "pedido_lineas_producto_id_fkey" FOREIGN KEY (producto_id) REFERENCES productos(id)
```

- El `PRIMARY KEY (pedido_id, linea)` identifica la fila y crea el índice B-tree por el que la
  foránea se comprueba. El `CHECK (cantidad > 0)` es la única regla de negocio que el motor defiende
  aquí: `precio_unit` no tiene ninguna, y una línea a precio negativo entraría sin queja.
- **Lo que no está:** ningún `UNIQUE (pedido_id, producto_id)` (§3).

> **⏱️ Coste.** `NOT NULL` es un bit en la cabecera de la fila y no cuesta nada medible; `CHECK`,
> una evaluación por fila escrita y cero disco; `UNIQUE`, **un índice entero**; `FOREIGN KEY`, una
> lectura indexada en el padre por escritura del hijo, más un bloqueo (*lock*) de esa fila padre. La
> foránea es la única que toca **otra tabla**, y por eso es la primera que alguien propone quitar
> "por rendimiento": ahorras tres páginas leídas y pagas no saber nunca cuándo entró la fila
> huérfana.

---

## 3. ⚖️ La N:M que no es una tabla puente tonta

Un pedido lleva muchos productos y un producto aparece en muchos pedidos: N:M de manual. La regla
que todos recitan —"se resuelve con una tabla intermedia de dos claves foráneas"— es cierta e
incompleta: se salta la pregunta que decide el diseño, **¿la relación tiene atributos propios?**

```text
tienda=# SELECT p.codigo, l.linea, pr.codigo AS producto, l.cantidad, l.precio_unit,
tienda-#        l.cantidad * l.precio_unit AS subtotal
tienda-# FROM pedidos p JOIN pedido_lineas l ON l.pedido_id = p.id
tienda-# JOIN productos pr ON pr.id = l.producto_id
tienda-# WHERE p.codigo = 'PED-00042' ORDER BY l.linea;
  codigo   | linea | producto  | cantidad | precio_unit | subtotal 
-----------+-------+-----------+----------+-------------+----------
 PED-00042 |     1 | PRD-01395 |        1 |      102.83 |   102.83
 PED-00042 |     2 | PRD-00872 |        5 |       27.03 |   135.15
 PED-00042 |     3 | PRD-03623 |        3 |      982.75 |  2948.25
(3 filas)
```

- `cantidad` y `precio_unit` **no pertenecen ni al pedido ni al producto**: pertenecen al cruce, y
  no hay dónde ponerlos si no es en la tabla de la relación.
- `precio_unit` es el precio congelado del día de la compra, no el vigente en `productos.precio`:
  con una tabla puente de solo `(pedido_id, producto_id)`, la factura de 2023 se recalcularía sola
  cada vez que alguien toca una tarifa. Una N:M con atributos propios **es una entidad**, y llamarla
  `pedido_lineas` y no `pedidos_productos` es lo que impide tratarla como plomería.

La segunda mitad es la identidad. `pedido_lineas` es una **entidad débil** (*weak entity*): `linea`
sola no identifica nada —hay 1 000 000 de filas con `linea = 1`, una por pedido— y la identidad real
es `(pedido_id, linea)`. En el DDL eso son dos cosas a la vez, la clave primaria compuesta que
empieza por la clave del padre y el `ON DELETE CASCADE` de §4; si falta una, la dependencia es solo
un dibujo.

Queda un hueco deliberado: nada impide repetir un producto dentro del mismo pedido —agrupando por
`(pedido_id, producto_id)` salen **6 855 pedidos** que ya lo hacen—. No es un error, puede ser una
línea de regalo; error sería no haberlo decidido.

> **Veredicto:** si la relación tiene atributos propios, la tabla intermedia es una entidad con
> nombre de negocio, clave compuesta y reglas propias; si el par se repite o no, es diseño.

---

## 4. 🩺 Borrar y renumerar: `ON DELETE` y `ON UPDATE`

Aquí el esquema se pone interesante, porque **no trata igual a los tres hijos de `pedidos`**:

| Hijo | Acción declarada | Qué significa |
|---|---|---|
| `pedido_lineas` | `ON DELETE CASCADE` | La línea no existe sin su pedido: se va con él |
| `eventos_pedido` | `ON DELETE CASCADE` | El historial es del pedido: se va con él |
| `pagos` | nada, o sea `NO ACTION` | El pago es un hecho contable propio: **impide** borrar el pedido |

Primero, un pedido anulado y sin pago —`PED-99999`, `id` 99999—, que antes del borrado tiene 6
líneas, 6 eventos y 0 pagos:

```text
tienda=# BEGIN;
BEGIN
tienda=*# DELETE FROM pedidos WHERE id = 99999;
DELETE 1
tienda=*# SELECT count(*) AS lineas, (SELECT count(*) FROM eventos_pedido WHERE pedido_id=99999) AS eventos, (SELECT count(*) FROM pagos WHERE pedido_id=99999) AS pagos FROM pedido_lineas WHERE pedido_id=99999;
 lineas | eventos | pagos 
--------+---------+-------
      0 |       0 |     0
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
```

- `DELETE 1` cuenta **solo las filas de `pedidos`**: las 12 hijas no aparecen y la cascada solo se
  ve contando antes y después. Ese es el argumento contra poner `CASCADE` a la ligera: un `DELETE`
  que responde `1` pudo borrar doce filas o doce millones.

Ahora el mismo borrado sobre `PED-00042`, que está `PAGADO`:

```text
tienda=# BEGIN;
BEGIN
tienda=*# DELETE FROM pedidos WHERE codigo = 'PED-00042';
ERROR:  update or delete on table "pedidos" violates foreign key constraint "pagos_pedido_id_fkey" on table "pagos"
DETALLE:  Key (id)=(42) is still referenced from table "pagos".
tienda=!# ROLLBACK;
ROLLBACK
```

El motor acaba de hacer cumplir una regla que nadie escribió en el código: **un pedido que se cobró
no se borra**. Con `CASCADE` en `pagos`, el cobro habría desaparecido sin rastro: entre las dos
declaraciones va un error en pantalla o un descuadre contable.

Y `ON UPDATE`: **ninguna foránea del esquema lo declara**, así que todas están en `NO ACTION`. En
PostgreSQL el intento ni llega a la foránea —`UPDATE pedidos SET id = 9000042 WHERE id = 42` muere
antes con `ERROR: column "id" can only be updated to DEFAULT`, porque la clave es `GENERATED
ALWAYS`—. En MySQL, donde `AUTO_INCREMENT` sí deja tocar la columna, el que frena es la foránea:

```text
mysql> UPDATE pedidos SET id = 9000042 WHERE id = 42;
ERROR 1451 (23000) at line 2: Cannot delete or update a parent row: a foreign key constraint fails (`tienda`.`pedido_lineas`, CONSTRAINT `fk_lineas_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedidos` (`id`) ON DELETE CASCADE)
```

- Fíjate en quién se queja: la restricción de `pedido_lineas`, **que tiene `ON DELETE CASCADE`**: la
  cascada de borrado no dice nada sobre las actualizaciones.
- `ON UPDATE CASCADE` es código muerto aquí, porque **con claves sustitutas el valor de la clave no
  cambia nunca**. Solo sirve con una clave natural renumerable —un código, un NIF, un ISBN—, caso
  que **no demuestro con sesión**: ninguna foránea del esquema apunta a una clave natural.

> **💡 Truco.** `NO ACTION` y `RESTRICT` no son sinónimos: `RESTRICT` falla en el acto y `NO ACTION`
> comprueba al final de la sentencia. Medido en el lab, `WITH b AS (DELETE FROM pagos WHERE
> pedido_id=42 RETURNING id) DELETE FROM pedidos WHERE id=42;` devuelve `DELETE 1` sin error; con
> `RESTRICT` en esa foránea, no pasaría.

---

## 5. 📜 Estándar, motor y convención

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 / MariaDB 12.3.3 | SQLite 3.53.4 |
|---|---|---|---|---|
| Existen `NOT NULL`, `UNIQUE`, `CHECK` y `FOREIGN KEY` | Sí, 9075-2, cláusula no verificada | Las cuatro | Las cuatro | Las cuatro |
| Las foráneas se hacen cumplir siempre | Sí | Siempre | Siempre con InnoDB | **No: apagadas por defecto**, `PRAGMA foreign_keys` da `0` |
| `CHECK` se evalúa en cada escritura | Sí | Sí | Sí desde 8.0.16; antes se parseaba y se ignoraba | Sí, siempre |
| Las cinco acciones referenciales existen | Sí, `<referential triggered action>`, cláusula no verificada | Las cinco | Las cinco en sintaxis; medido: 9.7.2 acepta `ON DELETE SET DEFAULT` pese a que su doc dice que InnoDB lo rechaza | Las cinco, si están encendidas |
| Por defecto, `ON DELETE` es `NO ACTION` | Sí | `NO ACTION` | `NO ACTION` | `NO ACTION` |

**Convención:** *"la base de datos garantiza la integridad referencial"*. Cierto en PostgreSQL y en
MySQL con InnoDB, **falso en SQLite mientras nadie encienda el interruptor**. Del `tienda.db` del
corpus, con el `REFERENCES pedidos(id) ON DELETE CASCADE` presente en el `.schema`:

```text
sqlite> PRAGMA foreign_keys;
0
sqlite> BEGIN;
sqlite> INSERT INTO pedido_lineas VALUES (9000001, 1, 17, 2, '19.90');
sqlite> SELECT count(*) FROM pedido_lineas WHERE pedido_id = 9000001;
1
sqlite> ROLLBACK;
```

La línea entró apuntando a un pedido que no existe, y el borrado tampoco arrastra: `DELETE FROM
pedidos WHERE codigo = 'PED-00042'` deja **3 líneas y 1 pago huérfanos** sin quejarse. Encendidas en
esa misma conexión, las dos fallan con `FOREIGN KEY constraint failed`.

> **⚠️ Advertencia.** `PRAGMA foreign_keys` es **por conexión, no por fichero**: no se guarda, no se
> hereda, y cada conexión nueva del pool vuelve a `0` salvo que el driver lo encienda. De ahí salen
> las huérfanas de tantas apps móviles: el `.schema` las declara y nunca se aplicaron.

---

## 6. 🧭 Cómo se elige la acción referencial

Tres preguntas, en orden, y la respuesta sale sola:

1. **¿El hijo tiene sentido sin el padre?** Si no —una línea, un evento—, es entidad débil:
   `CASCADE`.
2. **¿El hijo es un hecho que ocurrió?** Un pago, un asiento, un envío: `NO ACTION`, y el borrado
   del padre falla a propósito.
3. **¿El vínculo es opcional y su pérdida no invalida al hijo?** `SET NULL`, que exige columna
   nullable — aquí ni es declarable, porque las tres foráneas a `pedidos` son `NOT NULL`.
4. **¿Debería borrarse algo?** Un pedido cancelado es un cambio de `estado`, no un `DELETE`; con
   dinero de por medio, los `ON DELETE` correctos son los que nunca se ejecutan.

> **🧠 Modelo mental.** `CASCADE` es para partes de un todo; `NO ACTION`, para hechos con vida
> propia. En la duda, `NO ACTION`: equivocarte cuesta un error en pantalla, y al revés, un borrado
> silencioso que nadie ve hasta el cierre del mes.

---

## 7. 🔭 Dónde aparece de verdad

Los cuatro motores se quejan de lo mismo con palabras distintas, y reconocer el mensaje ajeno vale
en una guardia más que la teoría. Todos son la misma línea, `cantidad = 0` contra el `CHECK`:

```text
-- PostgreSQL 18.6
ERROR:  new row for relation "pedido_lineas" violates check constraint "pedido_lineas_cantidad_check"
DETALLE:  Failing row contains (42, 4, 17, 0, 19.90).

-- MySQL 9.7.2
ERROR 3819 (HY000) at line 2: Check constraint 'pedido_lineas_chk_1' is violated.

-- MariaDB 12.3.3
ERROR 4025 (23000) at line 2: CONSTRAINT `pedido_lineas.cantidad` failed for `tienda`.`pedido_lineas`

-- SQLite 3.53.4
Error near line 2: CHECK constraint failed: cantidad > 0
```

- **PostgreSQL es el único que te da la fila que falló**; los otros, solo el nombre de la
  restricción.
- **MySQL la llamó `pedido_lineas_chk_1`** porque el DDL no la nombró: escribir `CONSTRAINT
  cantidad_positiva CHECK (cantidad > 0)` convierte un mensaje inútil en uno que soporte entiende
  sin abrir el esquema.
- **MariaDB usa otro código para el mismo fallo** (`4025` contra `3819`): si discriminas errores por
  número, los dos motores no son intercambiables.
- Donde más duele es en la migración: se importa en un MySQL 5.7 —que parseaba los `CHECK` y los
  ignoraba (*«Prior to MySQL 8.0.16 … ignores»*, dice la doc de 8.0)— y durante dos años entran
  líneas con `cantidad = 0`, porque el esquema *dice* que no pueden existir.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Una N:M se resuelve con una tabla puente de dos claves foráneas" | Solo si la relación no tiene atributos propios. Con `cantidad` y `precio_unit` dentro es una entidad con nombre de negocio y reglas propias |
| "Una relación 1:1 se modela con una clave foránea" | La foránea da el lado "uno" de un solo extremo. El 1:1 lo implementa el `UNIQUE` sobre esa columna, y sin él el esquema acepta N |
| "SQLite respeta las claves foráneas del esquema" | Las declara y por defecto **no las aplica**: `PRAGMA foreign_keys` vale `0` y se enciende **en cada conexión**, no una vez en el fichero |
| "MySQL ignora los `CHECK`" | Era cierto hasta 8.0.16. Hoy los aplica y el 9.7.2 devuelve `ERROR 3819`; el consejo sigue circulando una década después |
| "`ON DELETE CASCADE` es lo cómodo, se pone en todas" | En `pagos` convertiría un error en pantalla en la desaparición silenciosa de un cobro. `CASCADE` es para partes de un todo, no para hechos |
| "Las foráneas son caras, se quitan en producción" | Cuestan una lectura indexada en el padre por escritura del hijo. Quitarlas no elimina el problema: lo traslada a un código sin transacción que lo proteja |
| "`ON UPDATE CASCADE` conviene por si acaso" | Con claves sustitutas la clave no cambia nunca, y con `GENERATED ALWAYS AS IDENTITY` el `UPDATE` ni se admite. Solo importa con claves naturales renumerables |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Constraints», las cuatro restricciones y las cinco acciones:
  <https://www.postgresql.org/docs/18/ddl-constraints.html>
- **Documentación** — PostgreSQL 18, «Identity Columns», por qué `GENERATED ALWAYS` bloquea el
  `UPDATE`: <https://www.postgresql.org/docs/18/ddl-identity-columns.html>
- **Documentación** — MySQL 9.7, «FOREIGN KEY Constraints», y las acciones que InnoDB dice rechazar:
  <https://dev.mysql.com/doc/refman/9.7/en/create-table-foreign-keys.html>
- **Documentación** — MySQL 9.7, «CHECK Constraints», y desde cuándo se aplican:
  <https://dev.mysql.com/doc/refman/9.7/en/create-table-check-constraints.html>
- **Documentación** — SQLite, «Foreign Key Support», el interruptor y por qué está apagado:
  <https://sqlite.org/foreignkeys.html>
- **Documentación** — SQLite, «Pragma statements», `foreign_keys` y `foreign_key_check`:
  <https://sqlite.org/pragma.html>
- **Estándar** — ISO/IEC 9075-2 (*Foundation*), `<referential constraint definition>` y
  `<referential triggered action>`. De pago, sin URL pública; **la numeración de cláusula no está
  verificada aquí**.

---

## 🧠 Preguntas

1. ¿Qué cláusula del DDL implementa la obligatoriedad de una relación, y cuál su unicidad? 🟢
2. ¿Cuál es la clave primaria de `pedido_lineas` y por qué tiene dos columnas? 🟢
3. ¿Qué valor devuelve `PRAGMA foreign_keys` en una conexión nueva de SQLite, y qué implica? 🟢
4. ¿Cuál es la acción referencial por defecto cuando no se declara `ON DELETE`? 🟢
5. Nombra las tres tablas que referencian a `pedidos` y di qué `ON DELETE` tiene cada una. 🟢
6. ¿Qué diferencia hay entre `NOT NULL` y `UNIQUE` sobre una columna foránea? 🟡
7. ¿Por qué `pedido_lineas` es entidad débil y `pagos` no, si las dos dependen de `pedidos`? 🟡
8. ¿En qué se diferencian `NO ACTION` y `RESTRICT`, y en qué caso concreto se nota? 🟡
9. ¿Las cinco acciones referenciales las fija el estándar o cada motor? ¿Y que las foráneas estén
   activas por defecto? 🟡
10. ¿Por qué `precio_unit` vive en `pedido_lineas` y no se lee de `productos.precio`? 🟡
11. Un `DELETE` responde `DELETE 1` y ha borrado trece filas. Explica cómo y cómo lo comprobarías. 🟠
12. Hay 6 855 pedidos con un producto repetido y ningún `UNIQUE (pedido_id, producto_id)`. Argumenta
    a favor y en contra de añadirlo. 🟠
13. ¿Por qué `ON DELETE SET NULL` no es declarable en ninguna foránea que apunte a `pedidos`? 🟠
14. ¿Qué te cuesta una clave foránea en cada `INSERT` del hijo, y qué te cuesta no tenerla? 🟠
15. "MySQL ignora los `CHECK`, no los pongas". Responde con versión y número de error, y di qué
    parte es del estándar y qué parte del motor. 🟠
16. Con `GENERATED ALWAYS AS IDENTITY`, ¿por qué `ON UPDATE CASCADE` es código muerto, y cuándo
    dejaría de serlo? 🟠
17. Escribe el DDL completo de la relación N:M entre `pedidos` y `productos` tal como está en el
    esquema, con las cuatro clases de restricción, y marca cuál implementa la dependencia de la
    entidad débil. 🔴
18. Da la secuencia de borrado que falla sobre `PED-00042` y la que funciona, con el mensaje de
    error de PostgreSQL y el de MySQL. 🔴
19. Convierte `pedidos`–`pagos` en un 1:1 real sobre 820 000 filas ya cargadas: escribe el DDL y di
    qué comprobarías antes de ejecutarlo. 🔴
20. Un `.db` de SQLite en producción tiene líneas huérfanas pese a declarar `REFERENCES ... ON
    DELETE CASCADE`. Da el diagnóstico, la consulta que lo confirma y las dos correcciones: la del
    fichero y la de la aplicación. 🔴

---

**Anterior:** [`04`](04-normalizacion-y-desnormalizacion.md) · **Siguiente:**
[`06`](06-nulos-y-logica-de-tres-valores.md) · **Relacionado:**
[`02`](02-el-modelo-relacional-y-sus-claves.md) — las clases de clave que aquí se traducen a DDL.
