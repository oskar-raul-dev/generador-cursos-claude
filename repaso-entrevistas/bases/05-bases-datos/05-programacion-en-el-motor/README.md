# Bloque 05 — Programación en el motor

> Cuándo merece la pena poner lógica dentro de la base de datos y cuándo no: funciones y
> procedimientos, disparadores, y cómo genera cada motor sus claves. Al terminarlo sabes defender
> con números un bucle en PL/pgSQL frente a una sentencia, un disparador de auditoría frente a la
> aplicación, y un UUIDv7 frente a un `bigint`.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

`01` fija el PL/pgSQL que usa `02`; `03` se puede leer suelto.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [Funciones y procedimientos](01-funciones-y-procedimientos.md) | 18 | Lógica en la base frente al cliente, medida: 6,2 s fila a fila, 888 ms en PL/pgSQL, 470 ms en una sentencia; la volatilidad que decide el plan, `EXCEPTION` y los procedimientos que confirman |
| `02` | [Disparadores](02-disparadores.md) | 18 | Los tres usos legítimos —auditoría, desnormalización, integridad que una restricción no expresa— y su precio: 2,4 veces el coste de un `UPDATE`, y la regla que deja pasar dos pedidos a la vez |
| `03` | [Claves generadas](03-claves-generadas.md) | 18 | Secuencias, `IDENTITY`, `AUTO_INCREMENT` y el `rowid` de SQLite; huecos, secuencias desincronizadas y lo que cuesta un UUIDv4 o un UUIDv7 en el índice |
| `04` | [Simulación de entrevista](04-simulacion-de-entrevista.md) | 24 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios |
| `05` | [Respuestas](05-respuestas.md) | 82 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**54 preguntas** en los tres capítulos y **28 más** en la simulación, todas con respuesta en
[`05`](05-respuestas.md).

> **📝 Longitud.** Los tres quedan entre 452 y 482 líneas, por encima del disparador de 400 por las
> sesiones en tres motores; `03` está declarado denso en §4.6 de la guía de estilo. Las sesiones que
> escriben se corrieron en una copia aislada del entorno, y cada capítulo lo dice en su §1.

---

## 🧩 Qué asume leído

Los bloques [`03`](../03-el-motor-por-dentro/README.md), para leer los planes, y
[`04`](../04-transacciones-y-concurrencia/README.md), porque los disparadores se ejecutan dentro de
la transacción que los dispara y heredan su aislamiento.

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| Funciones, procedimientos y volatilidad | `05/01` |
| Disparadores y la auditoría escrita por la base | `05/02` |
| Generación de claves y el coste de UUID en el índice | `05/03` |

Qué clave elegir y qué identificador exponer fuera de la base es de
[`12/02`](../12-diseno/02-identidad-y-claves.md), que parte de las cifras de `03`.

---

## 🧭 Si el calendario aprieta

**`03` y `02`.** «¿Entero o UUID?» es una pregunta de diseño habitual, y `03` la contesta con el
índice medido. Los disparadores se preguntan casi siempre como trampa —«¿por qué tienen mala
fama?»—, y `02` da la respuesta con la carrera entre dos pedidos que la restricción no ve.

---

**Anterior:** [`04`](../04-transacciones-y-concurrencia/README.md) · **Siguiente bloque:**
[`06 — Operación`](../06-operacion/README.md) · **Volver:** [README del corpus](../README.md).
