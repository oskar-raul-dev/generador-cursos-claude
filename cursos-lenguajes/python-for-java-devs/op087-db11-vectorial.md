# 🧭 db11 — Vectorial: pgvector y Qdrant

> Python para desarrolladores Java senior · **Carta** · Track `db` — Hablarle a cada sistema de
> datos desde Python · sección 11 de 15
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Las recepcionistas contestan por WhatsApp las mismas preguntas todo el día: si la limpieza duele, cuánto dura un control de
ortodoncia, si se puede pagar a cuotas. Hay doscientas respuestas aprobadas por Marcela, escritas en los procedimientos de las
sedes (`tx05`), y la idea es que el sistema sugiera las tres más parecidas a lo que escribió el paciente, aunque no use las
mismas palabras. Eso es búsqueda por similitud: cada texto se convierte en un vector (un *embedding*, que produce un modelo), y
se buscan los vectores más cercanos.

Esta sección no trata de producir los *embeddings* —eso es `ia`— sino de **guardarlos y buscarlos desde Python**, en las dos
opciones que más se usan: **pgvector**, una extensión de Postgres, y **Qdrant**, un motor vectorial propio. Y de la idea que
más le cuesta a quien llega de bases relacionales: **la búsqueda rápida es aproximada**. El índice devuelve casi siempre los
más cercanos, no siempre; cuántas veces acierta (el *recall*) es un parámetro que se elige, con su costo en tiempo.

---

## 🧠 2. El modelo

| | pgvector 0.8 (Postgres 18) | Qdrant 1.19 |
|---|---|---|
| Qué es | Una extensión: un tipo `vector` y operadores de distancia | Un motor dedicado, con API HTTP y gRPC |
| Desde Python | `psycopg` + `pgvector` 0.5.0 (registra el tipo) | `qdrant-client` 1.19.1 |
| Búsqueda exacta | Sin índice: recorre todo | `exact=True` |
| Búsqueda aproximada | Índice HNSW o IVFFlat; precisión con `hnsw.ef_search` | HNSW por defecto; precisión con `hnsw_ef` |
| Filtrar por otros campos | `WHERE` normal, con *joins* | Filtros sobre el *payload* |
| Operarlo | Ya está si hay Postgres | Un servicio más |

**El *recall*@k**: de los *k* vecinos más cercanos de verdad, cuántos devolvió el índice. Un *recall* de 0,9 con *k* = 10
significa que, en promedio, uno de los diez resultados no es de los diez mejores. Para sugerir respuestas a una recepcionista,
es más que suficiente; para una búsqueda donde faltar uno es grave, se sube el parámetro o se busca exacto.

### Tu instinto de Java dice… y esta vez se equivoca

Un índice B-tree de Postgres, o el de cualquier base que este perfil conozca, es exacto: el `WHERE` con índice devuelve las mismas
filas que sin índice, más rápido. El instinto supone lo mismo del índice vectorial, y no es así: **con el índice HNSW, la consulta
puede devolver resultados distintos** que sin él. No es un error; es el diseño.

---

## 💻 3. El ejemplo que corre

Los vectores son sintéticos (aleatorios, de 64 dimensiones): el ejemplo mide la búsqueda, no un modelo. Con *embeddings* reales,
las cifras cambian; la forma del resultado, no.

```bash
uv add "psycopg[binary]" pgvector qdrant-client numpy
```

`vecinos.py`:

```python
"""Buscar vecinos en pgvector y Qdrant: exacto contra aproximado, y el recall de cada uno."""

import os
import time

import numpy as np
import psycopg
from pgvector.psycopg import register_vector
from qdrant_client import QdrantClient, models

N, DIM, K = 50_000, 64, 10
rng = np.random.default_rng(42)
vectors = rng.normal(size=(N, DIM)).astype(np.float32)
queries = rng.normal(size=(50, DIM)).astype(np.float32)


def recall(found: list[list[int]], truth: list[list[int]]) -> float:
    return sum(len(set(f) & set(t)) for f, t in zip(found, truth)) / (K * len(truth))


# ------------------------------------------------- pgvector
dsn = os.environ.get("AUREA_PGV", "host=pgv dbname=postgres user=postgres password=aurea-local")
for _ in range(60):
    try:
        pg = psycopg.connect(dsn, autocommit=True)
        break
    except psycopg.OperationalError:
        time.sleep(1)
pg.execute("CREATE EXTENSION IF NOT EXISTS vector")
register_vector(pg)
pg.execute("DROP TABLE IF EXISTS respuesta")
pg.execute(f"CREATE TABLE respuesta (id int PRIMARY KEY, embedding vector({DIM}))")
with pg.cursor().copy("COPY respuesta (id, embedding) FROM STDIN WITH (FORMAT BINARY)") as copy:
    copy.set_types(["int4", "vector"])
    for i, v in enumerate(vectors):
        copy.write_row((i, v))


def pg_search(label: str) -> list[list[int]]:
    start = time.perf_counter()
    found = [[r[0] for r in pg.execute("SELECT id FROM respuesta ORDER BY embedding <-> %s LIMIT %s", (q, K))]
             for q in queries]
    print(f"  pgvector {label:<24} {(time.perf_counter() - start) / len(queries) * 1000:6.2f} ms por consulta", end="")
    return found


exact = pg_search("exacto (sin índice)")
print()
pg.execute("CREATE INDEX ON respuesta USING hnsw (embedding vector_l2_ops)")
for ef in (10, 40, 200):
    pg.execute(f"SET hnsw.ef_search = {ef}")
    print(f" · recall@{K} {recall(pg_search(f'HNSW, ef_search={ef}'), exact):.2f}")

# ------------------------------------------------- Qdrant
qd = QdrantClient(url=os.environ.get("AUREA_QDRANT", "http://qdrant:6333"), timeout=60)
if qd.collection_exists("respuesta"):
    qd.delete_collection("respuesta")
qd.create_collection("respuesta", vectors_config=models.VectorParams(size=DIM, distance=models.Distance.EUCLID),
                     optimizers_config=models.OptimizersConfigDiff(         # ver el detalle: sin esto, no hay HNSW que medir
                         indexing_threshold=1_000, default_segment_number=1, max_segment_size=1_000_000))
qd.upload_collection("respuesta", vectors=vectors, ids=range(N), batch_size=2_000)
while (info := qd.get_collection("respuesta")).status != models.CollectionStatus.GREEN or info.indexed_vectors_count < N:
    time.sleep(0.5)
print("  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count, "· segmentos:", info.segments_count)


def qd_search(label: str, **params) -> list[list[int]]:
    start = time.perf_counter()
    found = [[p.id for p in qd.query_points("respuesta", query=q, limit=K, search_params=models.SearchParams(**params)).points]
             for q in queries]
    print(f"  Qdrant   {label:<24} {(time.perf_counter() - start) / len(queries) * 1000:6.2f} ms por consulta", end="")
    return found


print(f" · recall@{K} {recall(qd_search('exacto', exact=True), exact):.2f}")
for ef in (10, 40, 200):
    print(f" · recall@{K} {recall(qd_search(f'HNSW, hnsw_ef={ef}', hnsw_ef=ef), exact):.2f}")
```

```bash
docker run -d --name aurea-pgv -e POSTGRES_PASSWORD=aurea-local -p 5432:5432 pgvector/pgvector:0.8.6-pg18
docker run -d --name aurea-qdrant -p 6333:6333 qdrant/qdrant:v1.19.1
AUREA_PGV="host=localhost dbname=postgres user=postgres password=aurea-local" \
AUREA_QDRANT=http://localhost:6333 python3 vecinos.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre; estos, de contenedores en un portátil):

```text
  pgvector exacto (sin índice)        5.62 ms por consulta
  pgvector HNSW, ef_search=10         0.28 ms por consulta · recall@10 0.34
  pgvector HNSW, ef_search=40         0.51 ms por consulta · recall@10 0.61
  pgvector HNSW, ef_search=200        1.66 ms por consulta · recall@10 0.90
  Qdrant   vectores en el índice HNSW: 50000 · segmentos: 2
  Qdrant   exacto                     5.44 ms por consulta · recall@10 1.00
  Qdrant   HNSW, hnsw_ef=10           0.83 ms por consulta · recall@10 0.34
  Qdrant   HNSW, hnsw_ef=40           0.94 ms por consulta · recall@10 0.62
  Qdrant   HNSW, hnsw_ef=200          1.39 ms por consulta · recall@10 0.90
```

Las dos bases dibujan la misma curva, porque las dos usan HNSW. Con `ef = 10`, la búsqueda es veinte veces más rápida que la exacta en
pgvector y acierta un tercio de los diez mejores; con `ef = 200`, sigue siendo tres o cuatro veces más rápida y acierta nueve de cada
diez. Los vectores aleatorios de 64 dimensiones son el peor caso para un índice aproximado; con *embeddings* reales, que tienen
estructura, el *recall* para el mismo `ef` suele ser más alto. Por eso se mide con los datos propios.

**Detalles con intención**

- **`register_vector(pg)`** le enseña a `psycopg` el tipo `vector`: los arreglos de NumPy van y vuelven sin convertir a texto.
- **`<->`** es la distancia euclidiana en pgvector; `<=>` la del coseno y `<#>` el producto interno. El operador de la consulta tiene
  que coincidir con el del índice (`vector_l2_ops`), o el índice no se usa.
- **`hnsw.ef_search`** (pgvector) y **`hnsw_ef`** (Qdrant) son el mismo parámetro: cuántos candidatos examina el índice. Más
  candidatos, más *recall* y más tiempo. Es la perilla de la sección.
- **La configuración de optimizadores** es lo que hace que haya un HNSW que medir, y costó dos corridas descubrirlo. En la primera,
  Qdrant no construyó el índice: por defecto no indexa segmentos de menos de unos 20 MB (`indexing_threshold`), y estos vectores
  pesan 12,8 MB. En la segunda, con el índice construido, repartió los vectores en cuatro segmentos chicos y los siguió recorriendo
  enteros, porque prefiere la búsqueda exhaustiva cuando lo que hay que recorrer es chico (`full_scan_threshold`, 10 MB por
  defecto). Las dos veces dio *recall* 1,00 con cualquier `hnsw_ef` y el mismo tiempo que la búsqueda exacta. Con segmentos grandes,
  la curva es la de pgvector. Son buenas decisiones del motor para colecciones chicas, y una trampa para quien mide.
- **El *recall* se mide contra la búsqueda exacta** sobre los mismos datos. Sin esa medición, no se sabe cuántos resultados buenos se
  están perdiendo.

---

## ⚠️ 4. Lo que se rompe

**El índice que no se usa.** Una consulta con `<=>` (coseno) sobre un índice creado con `vector_l2_ops` recorre la tabla entera, sin
error. Con `EXPLAIN` se ve; sin él, solo se nota que es lenta.

**Filtrar después de buscar.** "Las tres respuestas más parecidas, pero de la sede Suba" con un `WHERE sede = 'Suba'` sobre un índice
HNSW puede devolver menos de tres: el índice trae sus candidatos y el filtro descarta. pgvector 0.8 tiene recorridos iterativos para
esto (`hnsw.iterative_scan`); Qdrant filtra durante la búsqueda.

**Cambiar de modelo de *embeddings*.** Los vectores de dos modelos distintos no son comparables. Cambiar de modelo es recalcular todos
los vectores y reconstruir el índice.

**Vectores de datos personales.** Un *embedding* de un texto que menciona a un paciente se puede usar para recuperar información del
texto. Los procedimientos y las respuestas aprobadas, sí; los mensajes de los pacientes, con el cuidado de `se01`.

---

## ⚖️ 5. Cuándo NO usarlo

**Qdrant, si ya hay Postgres y son miles de vectores.** Doscientas respuestas, o doscientas mil, caben en pgvector, con *joins* y
transacciones. Un motor vectorial se justifica con decenas de millones de vectores o necesidades de filtrado y escala que Postgres no
cubre.

Es la misma decisión que tomó el track `ia` para NormaRAG ([`ia04`](ia04-embeddings-y-busqueda-semantica.md)): decenas de miles de fragmentos sobre
el Postgres que Áurea ya opera. Esta sección no la contradice; la mide desde el otro lado, con Qdrant al lado.

**Un índice aproximado con pocos datos.** Con doscientas respuestas, la búsqueda exacta tarda microsegundos y acierta siempre.

**Búsqueda por similitud cuando lo que se quiere es una palabra exacta.** "Respuestas que mencionan *cuotas*" es búsqueda de texto
(`db12`), no de vectores.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** la tabla con tus tiempos y *recalls*, y el `ef` que elegirías para sugerir respuestas.
2. Haz `EXPLAIN` de la consulta con `<->` y con `<=>`. **Criterio:** muestras cuál usa el índice.
3. Baja `N` a 200 y compara exacto contra HNSW. **Criterio:** los tiempos, y por qué no vale la pena el índice.

**🟡 Intermedio (4–6)**

4. Agrega una columna `sede` y busca las diez más cercanas de Suba, con y sin `hnsw.iterative_scan`. **Criterio:** cuántos resultados
   devuelve cada una.
5. Agrega un *payload* `sede` en Qdrant y busca con filtro. **Criterio:** siempre diez resultados, todos de Suba.
6. Cambia la distancia a coseno en las dos bases. **Criterio:** los resultados exactos de las dos coinciden.

**🟠 Difícil (7–9)**

7. Genera *embeddings* reales de cien respuestas con un modelo local (`ia`) y busca con preguntas escritas a mano. **Criterio:** las
   tres sugerencias para cinco preguntas, y si son razonables.
8. Mide el tiempo de construcción del índice HNSW con 50 000 y 500 000 vectores, y el tamaño en disco. **Criterio:** la tabla.
9. Prueba IVFFlat en pgvector con distintos `lists` y `probes`. **Criterio:** la curva de *recall* contra tiempo, junto a la de HNSW.

**🔴 Muy difícil (10)**

10. Diseña el sugeridor de respuestas para las recepcionistas. **Criterio:** una página. *Rúbrica:* (a) dónde se guardan los vectores y
    por qué; (b) qué *recall* se necesita y cómo se mide; (c) qué pasa al cambiar una respuesta o el modelo; (d) qué datos no se
    vectorizan nunca.

---

## 📚 7. Referencias

**Documentación oficial**

- pgvector: https://github.com/pgvector/pgvector
- `pgvector-python`: https://github.com/pgvector/pgvector-python
- Qdrant, búsqueda y parámetros: https://qdrant.tech/documentation/concepts/search/
- Qdrant, HNSW: https://qdrant.tech/documentation/concepts/indexing/

**Lectura**

- Yu. A. Malkov y D. A. Yashunin, *Efficient and robust approximate nearest neighbor search using Hierarchical Navigable Small World
  graphs* (2016), el artículo de HNSW: https://arxiv.org/abs/1603.09320

**Orden de lectura sugerido:** el README de pgvector, que explica índices, operadores y filtrado; después la página de búsqueda de
Qdrant.

---

## 🚀 8. Cierre

Los vectores se guardan en pgvector (dentro de Postgres) o en Qdrant (un motor aparte), y se buscan desde Python con sus clientes. La
búsqueda rápida es aproximada: el índice HNSW cambia exactitud por tiempo con un parámetro, y el *recall* se mide contra la búsqueda
exacta en vez de suponerlo.

**La señal de que quedó bien:** *"El sugeridor propone tres respuestas en milisegundos, y sabemos que nueve de cada diez veces son las
tres mejores."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-db-fase-11 -m "op db11 cerrada: pgvector y Qdrant, exacto contra aproximado, recall medido"
> ```
>
> Los commits llevan su prefijo (`op db11: …`) y los de ejercicio su número
> (`op db11 ej07: …`).
