# 🧬 or07 — Migraciones fuera de Alembic

> Python para desarrolladores Java senior · **Carta** · Track `or` — ORMs y acceso a datos desde
> Python · sección 7 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El camino base migra el esquema con Alembic, que es lo natural con SQLAlchemy. Pero no todos los proyectos de Áurea usan SQLAlchemy:
el reporte de cartera de `or06` es SQL en archivos, la herramienta de la franquicia está en Django, y la base que comparten varios
servicios (uno en Java) no es de ningún ORM. Este perfil viene de Flyway o Liquibase, y la pregunta que trae es concreta: **¿cuál es el
Flyway de Python?**

Hay varias respuestas, y todas resuelven lo mismo: una carpeta de migraciones numeradas, una tabla en la base que registra cuáles se
aplicaron, y un comando que aplica las que faltan en orden. **`yoyo-migrations`** es el más cercano a Flyway desde Python: migraciones en
SQL plano (o en Python), con su `rollback`. **Django** autodetecta los cambios de los modelos y genera las migraciones. **dbmate** es un
binario independiente del lenguaje. La sección aplica una serie de migraciones con `yoyo`, las revierte, y muestra lo que más se rompe:
editar una migración que ya se aplicó.

---

## 🧠 2. El modelo

| Herramienta | Versión | Escribe las migraciones | Revertir | Para qué |
|---|---|---|---|---|
| Alembic | 1.20.0 | Autogenera desde los modelos de SQLAlchemy | `downgrade` | Proyectos con SQLAlchemy (camino base) |
| `yoyo-migrations` | 9.0.0 💤 | **A mano, en SQL o Python** | Archivo `.rollback.sql` | **Bases sin ORM o compartidas**; lo más parecido a Flyway |
| Migraciones de Django | con Django 6.1.1 | Autodetecta desde los modelos | `migrate app 000N` | Proyectos Django |
| dbmate | (binario de Go) | A mano, en SQL | `rollback` | Equipos con varios lenguajes |
| Flyway (de Java) | — | A mano, en SQL | De pago | Si la casa ya lo usa: también migra bases que usa Python |

`yoyo-migrations` lleva desde agosto de 2024 sin versiones nuevas (💤). Hace poco, lo hace bien, y su formato es SQL plano: si el proyecto
se detuviera, las migraciones siguen siendo archivos `.sql` que cualquier otra herramienta puede aplicar.

### Esto sí funciona igual

El modelo de Flyway sobrevive intacto: migraciones versionadas, aplicadas en orden, registradas en una tabla de la base, nunca editadas
después de aplicadas. Quien sabe usar Flyway sabe usar `yoyo` en diez minutos; y si la casa ya tiene Flyway, nada impide seguir usándolo
para una base que también lee Python.

---

## 💻 3. El ejemplo que corre

```bash
uv add yoyo-migrations
```

Las migraciones, en `migraciones/`. `0001_planes.sql`:

```sql
-- depends:
CREATE TABLE plan (id INTEGER PRIMARY KEY, codigo TEXT NOT NULL UNIQUE, sede TEXT NOT NULL);
```

`0001_planes.rollback.sql`:

```sql
DROP TABLE plan;
```

`0002_fases.sql`:

```sql
-- depends: 0001_planes
CREATE TABLE fase (id INTEGER PRIMARY KEY, plan_id INTEGER NOT NULL REFERENCES plan(id), valor INTEGER NOT NULL);
```

`0002_fases.rollback.sql`:

```sql
DROP TABLE fase;
```

`migrar.py`:

```python
"""Aplicar, revertir y volver a aplicar con yoyo, y lo que pasa al editar una migración ya aplicada."""

import pathlib
import sqlite3

from yoyo import get_backend, read_migrations

backend = get_backend("sqlite:///aurea.db")


def status(label: str):
    migrations = read_migrations("migraciones")
    applied = [m.id for m in migrations if backend.is_applied(m)]
    tables = [r[0] for r in sqlite3.connect("aurea.db").execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE '\\_yoyo%' ESCAPE '\\' "
        "AND name NOT LIKE 'yoyo%' ORDER BY name")]
    print(f"{label:<28} aplicadas: {applied} · tablas: {tables}")


with backend.lock():
    backend.apply_migrations(backend.to_apply(read_migrations("migraciones")))
status("después de aplicar")

with backend.lock():
    backend.rollback_one(next(m for m in read_migrations("migraciones") if m.id == "0002_fases"))
status("después de revertir 0002")

with backend.lock():
    backend.apply_migrations(backend.to_apply(read_migrations("migraciones")))
status("después de reaplicar")

# Alguien "corrige" una migración ya aplicada en vez de escribir una nueva.
first = pathlib.Path("migraciones/0001_planes.sql")
first.write_text(first.read_text().replace("sede TEXT NOT NULL", "sede TEXT NOT NULL, activo INTEGER"))
pending = backend.to_apply(read_migrations("migraciones"))
print("pendientes tras editar 0001:", [m.id for m in pending], "· ¿tiene la columna activo?",
      "activo" in [c[1] for c in sqlite3.connect("aurea.db").execute("PRAGMA table_info(plan)")])
```

```bash
python3 migrar.py
yoyo list --database sqlite:///aurea.db migraciones
```

Salida (Python 3.14.7, 05/10/2026):

```text
después de aplicar           aplicadas: ['0001_planes', '0002_fases'] · tablas: ['fase', 'plan']
después de revertir 0002     aplicadas: ['0001_planes'] · tablas: ['plan']
después de reaplicar         aplicadas: ['0001_planes', '0002_fases'] · tablas: ['fase', 'plan']
pendientes tras editar 0001: [] · ¿tiene la columna activo? False
STATUS    ID           SOURCE
--------  -----------  -----------
A         0001_planes  migraciones
A         0002_fases   migraciones
```

Aplicar, revertir la segunda y volver a aplicarla funciona como en Flyway. La última línea del programa y el `yoyo list` muestran el problema: la
migración `0001` se editó para agregar una columna, y para `yoyo` sigue aplicada (`A`), sin pendientes y sin aviso. La base no tiene la columna.
Flyway, en el mismo caso, se negaría a seguir porque compara una suma de verificación de cada migración; `yoyo` no lo hace, y por eso la prueba
del ejercicio 8 hace falta.

**Detalles con intención**

- **`-- depends: 0001_planes`** declara el orden; `yoyo` arma el grafo de dependencias y aplica en ese orden, y revierte al revés.
- **`backend.lock()`** toma un bloqueo en la base para que dos despliegues simultáneos no apliquen la misma migración dos veces.
- **El archivo `.rollback.sql`** junto a cada migración es el `downgrade`: se escribe a mano, al mismo tiempo que la migración, o no existe.
- **La migración editada no se vuelve a aplicar**: `yoyo` registra que `0001_planes` ya corrió y no la mira más. La base no tiene la columna
  `activo`, y la próxima persona que cree la base desde cero sí la va a tener: dos bases distintas con el mismo historial.

---

## ⚠️ 4. Lo que se rompe

**Editar una migración aplicada.** Lo que muestra la última línea. La regla de Flyway vale igual: una migración aplicada no se toca; el cambio
va en una migración nueva (`0003_activo.sql`).

**Migraciones de esquema y de datos mezcladas.** Una migración que crea una columna y además recorre un millón de filas para llenarla bloquea la
tabla durante el despliegue. Se separan: primero la columna, después un proceso que llena por lotes.

**Dos herramientas para la misma base.** Si el servicio Java migra con Flyway y el de Python con `yoyo`, las dos tablas de control no se conocen y
el orden de los cambios queda a la suerte. Una base, una herramienta.

**Revertir en producción como plan.** Un `rollback` que borra una tabla con datos los pierde. En producción, la reversión de verdad suele ser una
migración nueva que deshace el cambio sin perder nada.

---

## ⚖️ 5. Cuándo NO usarlo

**`yoyo` en un proyecto con SQLAlchemy.** Alembic autogenera desde los modelos; mantener los modelos y las migraciones a mano por separado es
trabajo doble.

**`yoyo` en un proyecto Django.** Las migraciones de Django conocen sus modelos y su historial; otra herramienta las pisaría.

**Si la casa ya usa Flyway para esa base.** Se sigue usando; la base no sabe qué lenguaje la lee.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo y luego `yoyo list`. **Criterio:** explicas qué muestra para cada migración.
2. Escribe `0003_activo.sql` con su `rollback` para agregar la columna de la forma correcta. **Criterio:** se aplica y la columna aparece.
3. Mira la tabla de control de `yoyo` con `sqlite3`. **Criterio:** qué guarda de cada migración.

**🟡 Intermedio (4–6)**

4. Escribe una migración en Python (`step(...)`) que llene una columna nueva por lotes. **Criterio:** se aplica y se revierte.
5. Aplica las migraciones contra Postgres (`db01`). **Criterio:** las mismas migraciones, sin cambios, o lo que tuviste que cambiar.
6. Simula dos despliegues simultáneos aplicando desde dos procesos. **Criterio:** el bloqueo hace que solo uno aplique.

**🟠 Difícil (7–9)**

7. Haz el mismo historial con dbmate (binario). **Criterio:** las migraciones y la tabla de control que crea.
8. Escribe una prueba de CI que cree la base desde cero con todas las migraciones y la compare con un volcado del esquema de producción.
   **Criterio:** la prueba detecta la edición de `0001`.
9. Crea un modelo Django, genera la migración con `makemigrations` y mira el SQL con `sqlmigrate`. **Criterio:** compara con escribirla a mano.

**🔴 Muy difícil (10)**

10. Decide cómo se migran las bases de Áurea. **Criterio:** una página. *Rúbrica:* (a) qué base usa qué herramienta, y por qué una sola por base;
    (b) cómo se separan migraciones de esquema y de datos; (c) qué se hace en vez de revertir en producción; (d) cómo se detecta una migración
    editada.

---

## 📚 7. Referencias

**Documentación oficial**

- `yoyo-migrations`: https://ollycope.com/software/yoyo/latest/
- dbmate: https://github.com/amacneil/dbmate
- Django, migraciones: https://docs.djangoproject.com/en/stable/topics/migrations/
- Alembic: https://alembic.sqlalchemy.org/en/latest/

**Orden de lectura sugerido:** la documentación de `yoyo` (una página); después la de migraciones de Django, que explica bien el problema de las
migraciones de datos.

---

## 🚀 8. Cierre

Fuera de Alembic, las migraciones se hacen con `yoyo` (SQL plano, lo más parecido a Flyway), con las de Django en un proyecto Django, o con dbmate
entre lenguajes. La regla es la de siempre: versionadas, en orden, registradas en la base, y nunca editadas después de aplicadas. Una base, una
herramienta.

**La señal de que quedó bien:** *"La base de la franquicia se crea desde cero con las migraciones en el CI, y sale igual a la de producción."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-or-fase-07 -m "op or07 cerrada: migraciones con yoyo y la migración editada que nadie aplica"
> ```
>
> Los commits llevan su prefijo (`op or07: …`) y los de ejercicio su número
> (`op or07 ej07: …`).
