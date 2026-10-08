# Bloque 11 — ORMs: qué resuelven y qué rompen

> Qué problema resuelve un ORM y por qué nunca lo resuelve del todo, contado en los cuatro lenguajes
> del corpus: el desajuste entre objetos y filas, el N+1, la carga y las cachés, cuándo no usar
> ORM, y por qué una prueba contra una base en memoria miente. Al terminarlo sabes detectar un N+1
> en el log del motor, arreglarlo de cuatro formas y defender cuándo el ORM estorba.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

En orden: `01` da el mapa de identidad y la unidad de trabajo que usan los demás.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [El desajuste y los dos patrones](01-el-desajuste-y-los-dos-patrones.md) | 16 | El desajuste entre objetos y filas; *Active Record* y *Data Mapper*; mapa de identidad y unidad de trabajo, en Hibernate y SQLAlchemy frente a GORM y Drizzle |
| `02` | [El problema N+1](02-el-problema-n-mas-1.md) | 17 | Cómo nace, cómo se detecta en el log del motor y las cuatro correcciones —`JOIN`, `IN`, lotes y proyección—, con los 52 pedidos de `CLI-00311` |
| `03` | [Carga, cachés y la sesión](03-carga-caches-y-la-sesion.md) | 16 | Carga perezosa y ansiosa, el error de la sesión cerrada, *Open Session in View*, y las cachés de primer y segundo nivel |
| `04` | [Constructores, y cuándo no usar ORM](04-constructores-y-cuando-no-usar-orm.md) | 17 | Un informe con CTE recursiva y ventana en jOOQ, SQLAlchemy Core, Kysely y sqlc; una carga de 10 000 filas de 1,4 s a 12 ms |
| `05` | [Probar contra una base de datos real](05-probar-contra-base-de-datos-real.md) | 17 | Cinco comprobaciones contra H2, SQLite y PostgreSQL: la base en memoria miente en dos de cinco o en cuatro; Testcontainers en los cuatro lenguajes |
| `06` | [Simulación de entrevista](06-simulacion-de-entrevista.md) | 26 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios |
| `07` | [Respuestas](07-respuestas.md) | 113 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**83 preguntas** en los cinco capítulos y **30 más** en la simulación, todas con respuesta en
[`07`](07-respuestas.md).

> **📝 Longitud.** Los cinco quedan entre 267 y 413 líneas; `02` está declarado denso por las
> sesiones en cuatro lenguajes contando consultas en el servidor. Cada ejemplo corre en el
> contenedor de su lenguaje, con las versiones fijadas en §4.6 del documento de dominio.

---

## 🧩 Qué asume leído

El bloque [`10`](../10-interfaz-con-los-lenguajes/README.md), sobre todo
[`10/05`](../10-interfaz-con-los-lenguajes/05-java.md) y
[`10/06`](../10-interfaz-con-los-lenguajes/06-python-typescript-y-go.md), que presentan las capas
de cada ecosistema; y [`02/05`](../02-sql/05-cte-y-recursion.md) y
[`02/06`](../02-sql/06-funciones-de-ventana.md) para el informe de `04`.

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| Desajuste objeto-relacional, mapa de identidad y unidad de trabajo | `11/01` |
| El N+1 y sus correcciones | `11/02` |
| Carga perezosa y ansiosa, y las cachés del ORM | `11/03` |
| Constructores de consultas y cuándo no usar ORM | `11/04` |
| Pruebas contra la base real y Testcontainers | `11/05` |

Las migraciones que genera un ORM son de [`06/03`](../06-operacion/03-migraciones-de-esquema.md).

---

## 🧭 Si el calendario aprieta

**`02` y `03`.** El N+1 y la `LazyInitializationException` son las dos preguntas de ORM que llegan
a casi cualquier entrevista de Java con Spring, y `03` explica además por qué *Open Session in
View* es un antipatrón. `05` es la respuesta madura a «¿cómo pruebas tu capa de datos?».

---

**Anterior:** [`10`](../10-interfaz-con-los-lenguajes/README.md) · **Siguiente bloque:**
[`12 — Diseño`](../12-diseno/README.md) · **Volver:** [README del corpus](../README.md).
