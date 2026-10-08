# Bloque 12 — Diseño, y las decisiones que se preguntan

> Las decisiones de datos que llegan a una entrevista de arquitectura como una pizarra en blanco:
> qué motor, qué clave, qué columna para cada fecha e importe, cómo no perder el pasado, cómo
> separar inquilinos y cómo paginar y buscar. Al terminarlo sabes empezar cada respuesta por la
> pregunta que hace el negocio, elegir el mecanismo que la contesta y decir lo que cuesta.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

`01` primero: es la síntesis de los bloques 07–09. Los demás, en cualquier orden.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [Elegir motor](01-elegir-motor.md) | 18 | El punto de partida relacional, el árbol de cinco preguntas, las cifras de los bloques 07–09 en una tabla y lo que cuesta un motor más |
| `02` | [Identidad y claves](02-identidad-y-claves.md) | 18 | Natural o sustituta, entero o UUID, y el identificador que sale a la API; la clave natural medida y la RFC 9562 sobre usar un UUID como permiso |
| `03` | [Fechas, zonas y dinero](03-fechas-zonas-y-dinero.md) | 18 | Instante, día, hora local futura y duración; el cambio de hora, las reglas de zona que cambian, `DATETIME` frente a `TIMESTAMP`, y el dinero exacto, con moneda y sin céntimos perdidos |
| `04` | [Borrado lógico, auditoría e historial](04-borrado-logico-auditoria-e-historial.md) | 18 | Tres preguntas y tres mecanismos: índice único parcial, auditoría con disparadores, clave temporal de PostgreSQL 18 y tablas versionadas de MariaDB |
| `05` | [Multi-inquilino](05-multi-inquilino.md) | 18 | Columna, esquema o base por inquilino; seguridad a nivel de fila, la política que anula el índice y el `SET` que se queda en la conexión del *pool* |
| `06` | [Paginación y búsqueda de texto](06-paginacion-y-busqueda-de-texto.md) | 18 | `OFFSET` frente a clave, medidos en la página 25 000 y con un pedido nuevo entre dos páginas; cuándo basta la búsqueda de PostgreSQL |
| `07` | [Simulación de entrevista](07-simulacion-de-entrevista.md) | 26 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios |
| `08` | [Respuestas](08-respuestas.md) | 138 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**108 preguntas** en los seis capítulos y **30 más** en la simulación, todas con respuesta en
[`08`](08-respuestas.md).

> **📝 Longitud.** Los seis quedan entre 244 y 422 líneas: el bloque reutiliza las mediciones de los
> anteriores y solo corre lo nuevo. `01` es síntesis sin sesiones, y la búsqueda de `06` cita las
> cifras de [`09/05`](../09-otros-modelos/05-busqueda-de-texto.md). Todo lo que escribe se corrió
> en una copia aislada del entorno.

---

## 🧩 Qué asume leído

Casi todo el corpus, porque aquí se decide con lo medido antes:
[`09/01`](../09-otros-modelos/01-mas-alla-de-las-tablas.md) para `01`;
[`05/03`](../05-programacion-en-el-motor/03-claves-generadas.md) para `02`;
[`02/01`](../02-sql/01-familias-del-lenguaje-y-tipos.md) y
[`10/03`](../10-interfaz-con-los-lenguajes/03-mapeo-de-tipos.md) para `03`;
[`05/02`](../05-programacion-en-el-motor/02-disparadores.md) para `04`;
[`06/01`](../06-operacion/01-usuarios-roles-y-permisos.md) y
[`10/01`](../10-interfaz-con-los-lenguajes/01-el-driver-la-conexion-y-el-pool.md) para `05`; y
[`03/03`](../03-el-motor-por-dentro/03-compuestos-parciales-y-de-cobertura.md) para `06`.

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| El criterio para elegir motor, con las cifras juntas | `12/01` |
| Qué clave elegir y qué identificador exponer | `12/02` |
| Qué columna para cada caso horario y para el dinero | `12/03` |
| Borrado lógico, auditoría e historial temporal | `12/04` |
| Modelos multi-inquilino y seguridad a nivel de fila | `12/05` |
| Paginación por desplazamiento frente a clave | `12/06` |

CAP es de [`09/01`](../09-otros-modelos/01-mas-alla-de-las-tablas.md); la búsqueda de texto, de
[`09/05`](../09-otros-modelos/05-busqueda-de-texto.md); los disparadores de auditoría, de
[`05/02`](../05-programacion-en-el-motor/02-disparadores.md).

---

## 🧭 Si el calendario aprieta

**`01` y `05`.** «¿Qué base usarías aquí?» abre casi cualquier entrevista de arquitectura, y `01`
la contesta con cifras en vez de con modas. Multi-inquilino es la pregunta de diseño de toda
plataforma, y sus dos trampas —el índice anulado y la conexión que arrastra al inquilino— son las
que separan una respuesta de manual de una vivida.

---

**Anterior:** [`11`](../11-orms/README.md) · **Siguiente bloque:**
[`13 — Laboratorio`](../13-laboratorio/README.md) · **Volver:** [README del corpus](../README.md).
