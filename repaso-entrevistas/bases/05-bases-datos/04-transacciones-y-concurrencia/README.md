# Bloque 04 — Transacciones y concurrencia

> Qué garantiza de verdad cada letra de ACID y dónde termina cada una, qué ve tu transacción de lo
> que hacen las demás, cómo se bloquea y cómo se provoca un interbloqueo, y qué significa
> «confirmado» cuando se va la luz. Al terminarlo sabes explicar por qué «`REPEATABLE READ` evita
> los fantasmas» son tres respuestas distintas según hables del estándar, de PostgreSQL o de InnoDB.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

Acumulativo, y más que en ningún otro bloque: `02` fija el vocabulario —los cuatro niveles y los
cinco fenómenos— que usan los cuatro capítulos siguientes.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [ACID con precisión](01-acid-con-precision.md) | 18 | Qué garantiza cada letra y qué no; el ámbito de la transacción, los puntos de guardado y el anidamiento que no existe |
| `02` | [Aislamiento y sus fenómenos](02-aislamiento-y-sus-fenomenos.md) | 22 | Los cuatro niveles; lectura sucia, no repetible, fantasma, actualización perdida y *write skew* |
| `03` | [MVCC frente a bloqueo](03-mvcc-frente-a-bloqueo.md) | 20 | `xmin`/`xmax`, la instantánea y su regla de visibilidad, el *undo log* de InnoDB, filas muertas y el horizonte |
| `04` | [Bloqueos e interbloqueos](04-bloqueos-e-interbloqueos.md) | 19 | Modos de tabla y de fila, `FOR UPDATE`, `NOWAIT` y `SKIP LOCKED`, el interbloqueo provocado y la cola detrás de un `ALTER TABLE` |
| `05` | [Optimista, pesimista y transacciones largas](05-optimista-pesimista-y-transacciones-largas.md) | 17 | Columna de versión frente a bloqueo; lo que cuesta una transacción que dura demasiado |
| `06` | [WAL, durabilidad y `fsync`](06-wal-durabilidad-y-fsync.md) | 18 | Qué significa «confirmado», qué se pierde en un corte y qué cuesta no perder nada |
| `07` | [Simulación de entrevista](07-simulacion-de-entrevista.md) | 26 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios |
| `08` | [Respuestas](08-respuestas.md) | 144 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**114 preguntas** en los seis capítulos y **30 más** en la simulación, todas con respuesta en
[`08`](08-respuestas.md).

> **📝 Longitud y evidencia.** Los seis quedan entre 483 y 550 líneas; `02` y `04` tocan el techo
> por las sesiones de dos terminales, que se pegan tal como salieron en el tiempo. Lo que cambia en
> cada corrida —`xmin`, `xmax`, identificadores de proceso— se declara donde aparece: lo que se lee
> es la relación entre los números, no el dígito.

---

## 🧩 Qué asume leído

Los bloques [`01`](../01-fundamentos-y-modelo-relacional/README.md),
[`02`](../02-sql/README.md) y [`03`](../03-el-motor-por-dentro/README.md). El bloque 03 explicaba
**cómo decide el motor cuando lee**; este explica **cómo arbitra cuando varios escriben a la vez**.

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| ACID letra por letra, ámbito y puntos de guardado | `04/01` |
| **Niveles de aislamiento y sus fenómenos** | `04/02` — lo usa todo el corpus |
| MVCC, instantáneas y *undo log* | `04/03` |
| Bloqueos explícitos e interbloqueos | `04/04` |
| Control optimista y transacciones largas | `04/05` |
| WAL, `fsync` y qué se pierde en un corte | `04/06` |

---

## ⚠️ La regla de escritura de este bloque

El bloque 03 creaba índices y los deshacía. **Este escribe datos**, y por eso:

> **Toda sesión de este bloque deja los datos exactamente como estaban.** Lo que se puede demostrar
> dentro de `BEGIN … ROLLBACK` va ahí. Lo que obliga a confirmar —una anomalía de concurrencia
> obliga, porque la segunda sesión tiene que ver el trabajo de la primera— se deshace con la
> sentencia de compensación inmediatamente después, escrita en el capítulo.

- **Se prefiere mover una fila existente a insertar una nueva.** `PED-99999` entra y sale del
  conjunto filtrado con un `UPDATE` que se revierte exacto; un `INSERT` adelantaría la secuencia de
  `id`, que no vuelve atrás ni deshaciendo.
- **Cuando el motor mata una de las dos sesiones**, en el interbloqueo de
  [`04`](04-bloqueos-e-interbloqueos.md) §5, compensa la que sobrevivió, y como cuál muere no se
  elige, la demostración no depende de ello y lo declara.

```bash
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d tienda -tAc \
  "SELECT count(*) FROM pedidos WHERE estado='PENDIENTE';"   # tiene que dar 120000
```

- **`-tAc`**: sin cabecera ni pie, sin alineación, y la consulta se ejecuta y sale.
- **120 000** es el reparto fijo de estados del documento de dominio: si cambia, una sesión dejó una
  fila fuera de su sitio.

---

## 🧭 Si el calendario aprieta

**`02` es el capítulo más rentable del corpus entero para una entrevista de banca**, con mucha
diferencia: los niveles de aislamiento, sus fenómenos y la trampa del `REPEATABLE READ` aparecen en
casi todas. `01` es su requisito, y se lee en veinte minutos.

---

**Anterior:** [`03`](../03-el-motor-por-dentro/README.md) · **Siguiente bloque:**
[`05 — Programación en el motor`](../05-programacion-en-el-motor/README.md) · **Volver:** [README
del corpus](../README.md).
