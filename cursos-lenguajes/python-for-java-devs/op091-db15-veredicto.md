# ⚖️ db15 — Veredicto: el árbol de decisión

> Python para desarrolladores Java senior · **Carta** · Track `db` — Hablarle a cada sistema de
> datos desde Python · sección 15 de 15
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las catorce anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track habló con catorce sistemas desde Python: el DB-API ([`db01`](op077-db01-el-db-api.md)), MySQL y MariaDB
([`db02`](op078-db02-mysql-y-mariadb.md)), SQL Server y Oracle ([`db03`](op079-db03-sql-server-y-oracle.md)), SQLite
([`db04`](op080-db04-sqlite-a-fondo.md)), DuckDB ([`db05`](op081-db05-duckdb.md)), Valkey ([`db06`](op082-db06-valkey.md)),
MongoDB ([`db07`](op083-db07-mongodb.md)), Cassandra ([`db08`](op084-db08-cassandra.md)), Neo4j ([`db09`](op085-db09-neo4j.md)),
las series de tiempo ([`db10`](op086-db10-series-de-tiempo.md)), los vectores ([`db11`](op087-db11-vectorial.md)), la búsqueda
([`db12`](op088-db12-busqueda.md)), los objetos ([`db13`](op089-db13-objetos-s3.md)) y las bitácoras de eventos
([`db14`](op090-db14-bitacora-de-eventos.md)).

De cada uno quedó el ejemplo que corre y la trampa. Lo que queda es la pregunta que este perfil se va a hacer cada vez que
alguien proponga uno: **¿lo necesitamos, o Postgres ya lo hace?** La respuesta honesta del track es que, para el tamaño de
Áurea, **Postgres gana casi siempre**: tiene tipos exactos (`db01`), búsqueda de texto (`db12`), vectores con pgvector
(`db11`), series de tiempo con TimescaleDB (`db10`), documentos con `jsonb` (`db07`) y recorridos con `WITH RECURSIVE` (`db09`).
Cada sistema especializado gana en su terreno a partir de un volumen o de una forma de acceso que hay que poder nombrar con una
cifra.

---

## 🧠 2. El modelo

| Si la necesidad es… | Postgres lo resuelve con… | El especializado gana cuando… | Medido en |
|---|---|---|---|
| Consultar archivos y analizar millones de filas | `COPY` y una tabla | Los datos ya están en archivos y la consulta es de lectura | `db05`: 18 ms sobre Parquet, sin cargar nada |
| Caché y bloqueos con vencimiento | Una tabla con columna de vencimiento | Se necesitan milisegundos y miles de operaciones por segundo | `db06` |
| Documentos flexibles | `jsonb` con índice GIN | El modelo es un documento y no hay *joins* | `db07` |
| Escritura masiva distribuida | Particiones | Volumen de escritura y varios centros de datos | `db08` |
| Recorridos de profundidad variable | `WITH RECURSIVE` | Los recorridos son la consulta principal | `db09`: 40 004 contra 5 accesos con índice |
| Series de tiempo | TimescaleDB, que **es** Postgres | Volúmenes que Postgres no aguanta | `db10` |
| Vectores | pgvector, que **es** Postgres | Decenas de millones de vectores | `db11`: misma curva de *recall* |
| Búsqueda de texto | `tsvector` y `pg_trgm` | Facetas, relevancia afinada, búsqueda mientras se escribe | `db12` |
| Archivos | No (bytea no es un almacén) | Siempre: los archivos van a un almacén de objetos | `db13` |
| Eventos para varios lectores | Una tabla de eventos y `LISTEN/NOTIFY` | Muchos productores, muchos grupos, retención larga | `db14` |

Y los sistemas que no se eligen sino que se heredan —MySQL de Odontovía, SQL Server y Oracle de los aliados— no están en la tabla:
se leen con cuidado, con sus trampas, y no se escriben.

---

## 💻 3. El ejemplo que corre

Sin dependencias. `arbol.py` es la tabla como función, aplicada a las necesidades reales de Áurea.

```python
"""¿Postgres o un especializado? El árbol del veredicto, aplicado a las necesidades de Áurea."""

from dataclasses import dataclass


@dataclass
class Need:
    name: str
    kind: str                       # "relacional", "archivos", "cache", "texto", "vectores", "serie", "eventos", "grafo", "documento"
    rows_per_year: int = 0
    readers: int = 1                # procesos distintos que leen lo mismo
    inherited: bool = False         # existe y no es nuestro


THRESHOLDS = {                      # a partir de cuánto el especializado se paga, para un equipo de uno
    "texto": 10_000_000, "vectores": 20_000_000, "serie": 1_000_000_000, "documento": 50_000_000,
}


def decide(n: Need) -> str:
    if n.inherited:
        return "leerlo como está, con sus trampas (db02, db03)"
    if n.kind == "archivos":
        return "almacén de objetos S3 (db13)"
    if n.kind == "cache":
        return "Valkey (db06), si una tabla con vencimiento no alcanza"
    if n.kind == "eventos":
        return "NATS JetStream (db14)" if n.readers > 2 else "tabla de eventos en Postgres"
    if n.kind in THRESHOLDS and n.rows_per_year > THRESHOLDS[n.kind]:
        return f"especializado para {n.kind}"
    extension = {"serie": " + TimescaleDB", "vectores": " + pgvector", "texto": " (tsvector, pg_trgm)",
                 "grafo": " (WITH RECURSIVE)", "documento": " (jsonb)"}.get(n.kind, "")
    return "Postgres" + extension


NEEDS = [
    Need("Agenda, abonos, cartera", "relacional", 2_000_000),
    Need("Odontovía de cada sede", "relacional", inherited=True),
    Need("Exportes nocturnos y reportes PDF", "archivos"),
    Need("Totales del tablero", "cache"),
    Need("Respuestas de WhatsApp por palabra", "texto", 200),
    Need("Respuestas de WhatsApp por similitud", "vectores", 200),
    Need("Minutos de espera por sede", "serie", 5_256_000),
    Need("Derivaciones entre sedes", "grafo", 20_000),
    Need("Cita confirmada para tres procesos", "eventos", 500_000, readers=3),
]
for n in NEEDS:
    print(f"{n.name:<38} → {decide(n)}")
```

```bash
python3 arbol.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
Agenda, abonos, cartera                → Postgres
Odontovía de cada sede                 → leerlo como está, con sus trampas (db02, db03)
Exportes nocturnos y reportes PDF      → almacén de objetos S3 (db13)
Totales del tablero                    → Valkey (db06), si una tabla con vencimiento no alcanza
Respuestas de WhatsApp por palabra     → Postgres (tsvector, pg_trgm)
Respuestas de WhatsApp por similitud   → Postgres + pgvector
Minutos de espera por sede             → Postgres + TimescaleDB
Derivaciones entre sedes               → Postgres (WITH RECURSIVE)
Cita confirmada para tres procesos     → NATS JetStream (db14)
```

Nueve necesidades, y seis terminan en Postgres, con o sin una extensión. Las otras tres son las que Postgres no hace bien por diseño
—archivos—, la que puede necesitar milisegundos —el caché—, y la que tiene varios lectores independientes —los eventos—. Ninguna
termina en MongoDB, Cassandra, Neo4j, InfluxDB, Qdrant ni OpenSearch: no porque sean malos, sino porque el volumen de Áurea está
lejos de los umbrales en los que se pagan.

**Detalles con intención**

- **Los umbrales de `THRESHOLDS` son suposiciones** de esta sección, a la vista y discutibles. Lo que no es discutible es que existan:
  un especializado sin una cifra que lo justifique es una moda.
- **"Un equipo de uno"** está en el comentario de los umbrales porque cambia todo: cada sistema más es algo que respaldar, actualizar
  y entender a las tres de la mañana. Con un equipo de plataforma, los umbrales bajan.
- **El orden de los `if` es la política**: lo heredado se respeta antes que nada, y los archivos nunca van a la base.

---

## ⚠️ 4. Lo que se rompe

**Elegir por la conferencia.** El motor nuevo de la charla resuelve un problema de una empresa con cien veces más datos. La pregunta
es por la cifra propia.

**Postgres para todo, sin mirar.** El veredicto no es "nunca otro". Un caché en Postgres que recibe diez mil escrituras por segundo, o
archivos de cien MB en `bytea`, son los errores del lado contrario.

**La extensión que no está en el servicio administrado.** TimescaleDB, pgvector y `pg_trgm` se instalan en un Postgres propio; en un
servicio de nube, hay que verificar cuáles ofrece. La decisión "Postgres + extensión" depende de dónde corre Postgres.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Con un equipo de datos y de plataforma.** Los umbrales bajan y los especializados se pagan antes.

**Si el sistema ya existe y funciona.** Migrar de MongoDB a Postgres "porque el veredicto lo dice" es un proyecto con riesgo y sin
beneficio inmediato. El árbol es para decisiones nuevas.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Agrega tres necesidades de un sistema tuyo a `NEEDS`. **Criterio:** la salida, y si estás de acuerdo con cada decisión.
2. Cambia el umbral de vectores a 100. **Criterio:** qué necesidad cambia y si el cambio tiene sentido.

**🟡 Intermedio (3–4)**

3. Agrega la dimensión "corre en un Postgres administrado sin la extensión". **Criterio:** la serie de tiempo cambia de decisión.
4. Escribe las pruebas de `decide` con un caso por fila de la tabla de §2. **Criterio:** diez casos, todos pasan.

**🟠 Difícil (5–6)**

5. Reemplaza un umbral por uno medido: el volumen de texto a partir del cual `tsvector` tarda más de 100 ms en tu máquina. **Criterio:**
   la medición y el umbral nuevo.
6. Haz el ejercicio al revés: busca el volumen de citas al que Áurea tendría que llegar para que Cassandra se justificara. **Criterio:**
   una estimación con sus supuestos.

**🔴 Muy difícil (7–8)**

7. Escribe la política de datos de Áurea. **Criterio:** una página. *Rúbrica:* (a) la base por defecto y sus extensiones; (b) los
   sistemas heredados y cómo se leen; (c) la cifra que haría adoptar cada especializado; (d) quién decide y cómo se registra.
8. Audita los sistemas de datos de un equipo real. **Criterio:** una tabla. *Rúbrica:* (a) cada sistema con su necesidad; (b) la
   decisión del árbol; (c) los que sobran y los que faltan; (d) el costo de operar los que sobran.

---

## 📚 7. Referencias

- Postgres, extensiones incluidas: https://www.postgresql.org/docs/current/contrib.html
- Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017). El libro de referencia sobre
  por qué cada sistema existe.

**Orden de lectura sugerido:** los capítulos 2 y 3 de Kleppmann, que explican los modelos de datos y el almacenamiento; el resto del track
tiene sus referencias en cada sección.

---

## 🚀 8. Cierre

Para el tamaño de Áurea, Postgres —con sus extensiones— resuelve seis de cada nueve necesidades, y los especializados ganan con una cifra
que se puede nombrar. Lo heredado se lee con sus trampas; los archivos van a un almacén de objetos; y cada sistema nuevo es algo que un
equipo de uno tiene que operar a las tres de la mañana.

**La señal de que quedó bien:** *"Alguien propuso MongoDB para las respuestas de WhatsApp, y la discusión terminó con el volumen real:
doscientas filas."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-db-fase-15 -m "op db15 cerrada: el árbol de decisión y por qué Postgres gana casi siempre"
> ```
>
> Los commits llevan su prefijo (`op db15: …`) y los de ejercicio su número
> (`op db15 ej07: …`).
