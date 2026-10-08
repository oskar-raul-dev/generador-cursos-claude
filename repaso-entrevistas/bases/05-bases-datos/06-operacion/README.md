# Bloque 06 — Operación: respaldos, migraciones y salud

> Lo que hace falta para que una base siga viva en producción: quién puede hacer qué, cómo se vuelve
> atrás cuando se borra lo que no se debía, cómo se cambia el esquema de una base que tiene datos y
> no puede parar, y qué se mira para saber que está sana. Al terminarlo sabes dar una política de
> respaldos con su RPO y su RTO, y desplegar un renombrado de columna sin parar la tienda.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

`03` y `04` van juntos: el primero lleva la cuenta de qué cambio se aplicó, el segundo dice cómo
aplicarlo sin parar. `01`, `02` y `05` se pueden leer sueltos.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [Usuarios, roles y permisos](01-usuarios-roles-y-permisos.md) | 18 | Mínimo privilegio para la aplicación, privilegios por defecto para las tablas futuras, permisos por columna y el rol de MySQL que no está activo |
| `02` | [Respaldos y recuperación](02-respaldos-y-recuperacion.md) | 18 | Lógico frente a físico, recuperación a un instante, RPO y RTO; el byte cambiado que detecta `pg_verifybackup` y la tabla restaurada sin sus índices |
| `03` | [Migraciones de esquema](03-migraciones-de-esquema.md) | 18 | Flyway y Alembic medidos: la línea base, la migración editada, el fallo que PostgreSQL deshace y MySQL deja a medias, y el renombrado que el ORM convierte en borrado |
| `04` | [Expandir y contraer](04-expandir-contraer.md) | 18 | Los cinco pasos de un renombrado sin parar; la cola de bloqueos detrás de un `ALTER`, `lock_timeout`, qué `ADD COLUMN` reescribe la tabla y el índice concurrente |
| `05` | [Monitorización y mantenimiento](05-monitorizacion-y-mantenimiento.md) | 18 | `pg_stat_statements`, las sesiones que retienen la limpieza, filas muertas, hinchazón y lo que cuesta devolver el espacio |
| `06` | [Simulación de entrevista](06-simulacion-de-entrevista.md) | 26 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios |
| `07` | [Respuestas](07-respuestas.md) | 120 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**90 preguntas** en los cinco capítulos y **30 más** en la simulación, todas con respuesta en
[`07`](07-respuestas.md).

> **📝 Longitud.** Los cinco quedan entre 343 y 476 líneas; `03` y `04` pasan el disparador de 400
> por las sesiones con dos herramientas de migración y con tres terminales. Todo lo que escribe o
> rompe se corrió en una copia aislada del entorno, y las versiones de Flyway y Alembic están
> fijadas en §4.9 del documento de dominio.

---

## 🧩 Qué asume leído

El bloque [`04`](../04-transacciones-y-concurrencia/README.md), sobre todo el WAL de `04/06` y los
bloqueos de `04/04`, y [`10/02`](../10-interfaz-con-los-lenguajes/02-parametrizadas-e-inyeccion.md),
donde el mínimo privilegio para una inyección que ya pasó. `02` usa las cifras del laboratorio
[`l03`](../13-laboratorio/l03-respaldo-y-restauracion.md).

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| Roles, mínimo privilegio y privilegios por defecto | `06/01` |
| RPO, RTO, respaldo lógico y físico, y PITR | `06/02` |
| **Migraciones de esquema, incluidas las generadas por ORM** | `06/03` |
| Expandir y contraer, y la cola de bloqueos del DDL | `06/04` |
| Monitorización, `VACUUM` e hinchazón | `06/05` |

---

## 🧭 Si el calendario aprieta

**`04` y `02`.** «¿Cómo cambias una columna en una tabla de producción sin parar?» y «¿cuánto
perderías si se borra una tabla ahora?» son las dos preguntas de operación que más llegan a una
entrevista de backend senior. `04` contesta la primera con la cola de bloqueos provocada; `02`, la
segunda con el RPO de cada estrategia.

---

**Anterior:** [`05`](../05-programacion-en-el-motor/README.md) · **Siguiente bloque:**
[`07 — Clave-valor`](../07-clave-valor/README.md) · **Volver:** [README del corpus](../README.md).
