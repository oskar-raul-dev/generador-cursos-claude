# 🧭 ia04 — Embeddings, búsqueda semántica, y cuándo Postgres gana

> Python para desarrolladores Java senior · Track `ia` · sección 4 de 8
> Depende de: `ia01`, `ia02`, y la Fase 11 (Postgres) · Habilita: `ia05`
> Registro de esta sección: aplicación
> Proyecto que avanza: NormaRAG — nace su recuperación

---

## 🎯 1. Propósito

En `ia02` convertiste una circular en datos. Pero la pregunta de Patricia —*"¿esta prepagada cubre
el retiro de brackets en el plan complementario?"*— no se contesta con una circular: se contesta
con el párrafo correcto de uno de los cientos de documentos que hay entre contratos, anexos
tarifarios, circulares y el manual de glosas. **Encontrar ese párrafo es el problema, y es la
mitad de NormaRAG.**

Esta sección construye la recuperación y trae la comparación más incómoda del track: contra los
embeddings compite **la búsqueda de texto completo que Postgres ya tenía instalada desde la Fase
11**, que no cuesta una dependencia, no cuesta un proceso de indexación y para una parte de estas
preguntas es mejor. No un poco mejor: mejor.

> 🧭 **La pregunta que ordena la sección: ¿esta consulta es léxica o es semántica?** Un código de
> procedimiento, un NIT y la palabra "brackets" son léxicos. *"¿Qué pasa si el paciente cambia de
> plan a mitad del tratamiento?"* no lo es. Y la respuesta correcta para Áurea, casi seguro, es
> que hacen falta las dos.

---

## ✅ 2. Qué queda listo al terminar

- [ ] El corpus documental está troceado, embebido y almacenado en Postgres con `pgvector`, y el
      índice HNSW existe y se usa (lo confirmas con `EXPLAIN`).
- [ ] La misma tabla tiene su columna `tsvector` en español con índice GIN, y las dos búsquedas
      corren contra los **mismos** fragmentos.
- [ ] `search.py` expone las tres estrategias —vectorial, léxica e híbrida— con la misma firma.
- [ ] Ninguna búsqueda devuelve resultados por debajo de un **umbral de similitud**, y el "no
      encontré nada" es una respuesta posible del sistema, no una lista de fragmentos irrelevantes.
- [ ] `bench_retrieval.py` produce la tabla de la sección 6 sobre las cincuenta preguntas
      anotadas: recall@5, MRR, latencia y costo de indexación.
- [ ] Puedes nombrar tres preguntas de Áurea donde la búsqueda léxica gana, con el número al lado.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Generar la respuesta con el modelo** → `ia05`. Aquí se recupera el fragmento y se para ahí. La
  separación es deliberada: **la mitad de los RAG que fallan, fallan en la recuperación**, y
  medirla sola es la única forma de saberlo.
- **La ingesta de PDF escaneados y el troceado fino** → `ia05`. Aquí el corpus llega como texto ya
  troceado por un script que se da.
- **Reordenamiento con un modelo (*reranking*)** → `ia05`, donde ya hay con qué medirlo.
- **Bases de datos vectoriales dedicadas** —Qdrant, Milvus, Weaviate— → track `db` a la carta. La
  decisión de este curso es `pgvector`, y su razón está en la sección 4.
- **Afinar o entrenar un modelo de embeddings** → fuera del curso.

---

## 🧠 4. Concepto mínimo

### Qué es un embedding, en términos operativos

Un modelo convierte un fragmento de texto en un vector de unos cuantos cientos de números. Dos
fragmentos que hablan de lo mismo quedan cerca; dos que no, lejos. "Cerca" se mide con una
distancia —coseno, en la práctica—, y buscar es ordenar por esa distancia y quedarse con los
primeros.

Eso es todo el mecanismo. Lo que importa para el diseño son tres consecuencias:

**El vector no entiende tu dominio; entiende el idioma en que se entrenó.** Sabe que "brackets" y
"aparatología" hablan de lo mismo. **No** sabe que `992102` es el código del retiro de brackets en
el manual tarifario: para el modelo eso es una cadena de dígitos parecida a cualquier otra cadena
de dígitos. Toda consulta que gire alrededor de un identificador —código, NIT, número de póliza—
está en el terreno donde la búsqueda léxica gana por diseño, no por casualidad.

**El fragmento que embebes es la unidad de recuperación.** Si troceas cada mil caracteres sin
mirar la estructura, un fragmento va a contener el final de una cláusula y el principio de otra, y
su vector va a quedar en el medio de dos temas: cerca de todo y útil para nada.

**El índice es aproximado, y está bien que lo sea.** HNSW no garantiza devolver el vecino más
cercano: garantiza devolver uno muy cercano, muy rápido. Se puede pedir más exactitud a cambio de
latencia. Que un índice tenga ese perilla no es un defecto — es la única forma de que la búsqueda
por similitud escale.

### Tu instinto de Java dice… y esta vez se equivoca

El reflejo no es sobre vectores: es sobre **qué significa que un índice no encuentre nada**.

En todo lo que has escrito en once años, una búsqueda que no encuentra devuelve vacío. `WHERE
procedure_code = '992102'` trae la fila o no la trae. Un `findById` devuelve `Optional.empty()`.
La ausencia es un resultado, y es el resultado más informativo que existe: significa *no está*.

Una búsqueda vectorial **nunca devuelve vacío**. Le pides los cinco más cercanos y te da cinco,
siempre, aunque tu pregunta no tenga absolutamente nada que ver con el corpus. Pregúntale a
NormaRAG por la receta del ajiaco y te va a devolver los cinco párrafos de contratos de
aseguradoras menos disímiles de un ajiaco, con toda seriedad y con su distancia calculada.

```python
# ❌ El reflejo. Nunca falla, y por eso es peligroso.
def search(question: str, k: int = 5) -> list[Chunk]:
    vector = embed(question)
    return repository.nearest(vector, k)   # siempre devuelve k. SIEMPRE.
```

Cuando esto alimenta a `ia05`, el resultado es el modo de fallo más caro de un RAG: **el sistema
contesta con seguridad usando el fragmento menos irrelevante**. Patricia lee una respuesta bien
redactada, con su cita, sobre una cláusula que no tiene nada que ver con su pregunta.

```python
# ✅ La distancia es un dato y hay que usarla. "No encontré" es una respuesta legítima.
def search(question: str, k: int = 5, max_distance: float = 0.35) -> list[Chunk]:
    """Devuelve hasta k fragmentos relevantes. Puede devolver ninguno, y eso es correcto."""
    vector = embed(question)
    candidates = repository.nearest(vector, k)
    return [c for c in candidates if c.distance <= max_distance]
```

El umbral hay que **calibrarlo con datos**, no elegirlo bonito: se toman las preguntas anotadas,
se miran las distancias de los aciertos y las de los fallos, y se corta donde separan mejor. Eso
es trabajo de la sección 6 y del miniproyecto.

> 🧭 **La regla:** en una búsqueda por similitud, el número que decide no es el orden, **es la
> distancia**. Un sistema que ignora la distancia no puede decir "no sé", y un sistema que no
> puede decir "no sé" va a inventar todos los días.

Hay un segundo reflejo, y es de arquitectura: **"esto necesita una base de datos vectorial"**. Casi
nunca. Áurea tiene del orden de decenas de miles de fragmentos; `pgvector` sobre el Postgres que ya
está corriendo lo resuelve sin agregar un servicio, sin un segundo lugar donde se pierden los
datos, y —lo que decide— **permite filtrar por metadatos y buscar por vector en la misma
consulta**, que es exactamente lo que hace falta cuando la pregunta es "en el contrato **vigente**
de **esta** aseguradora". Con un servicio aparte, ese filtro se vuelve dos consultas y una
intersección hecha a mano. La base de datos vectorial dedicada gana cuando el volumen o el
rendimiento la obligan, y ese día se migra; ese día no es hoy y no hay que fingir que lo es.

### Esto sí funciona igual

- **Es un índice.** Se crea, ocupa disco, hay que reconstruirlo cuando cambian los datos, y tiene
  parámetros que cambian el equilibrio entre exactitud y velocidad. Todo tu criterio sobre índices
  se transfiere.
- **`EXPLAIN` sigue siendo `EXPLAIN`.** Si el planificador decide no usar tu índice HNSW, lo vas a
  ver ahí, igual que siempre. Y la causa suele ser la misma de siempre: un filtro que lo impide.
- **La normalización del texto** es el mismo problema de la Fase 06 y de `ia02`. Basura entra,
  basura se embebe.
- **El costo de mantenimiento del índice** en escrituras es real y se mide como cualquier otro.
- **La medición de recuperación es una métrica de sistema de información clásica.** Recall,
  precisión y MRR llevan décadas definidos y no los inventó nadie de este ecosistema.

### Diccionario de traducción

| Java / tu stack | Track `ia` | Dónde se rompe el paralelo |
|---|---|---|
| Índice B-tree | Índice HNSW | Es **aproximado**: puede no devolver el vecino más cercano, y eso es una decisión de diseño, no un bug |
| `WHERE x = ?` que no encuentra | Búsqueda vectorial | Nunca devuelve vacío. La ausencia hay que fabricarla con un umbral de distancia |
| `LIKE '%texto%'` | Búsqueda de texto completo (`tsvector`) | Casi igual, y sigue siendo la herramienta correcta para códigos y nombres propios |
| `ORDER BY campo LIMIT k` | `ORDER BY embedding <=> ? LIMIT k` | Es SQL normal. La única novedad es el operador de distancia |
| Caché por clave | Búsqueda semántica | No hay clave: dos preguntas equivalentes son dos vectores distintos y dos consultas distintas |
| Relevancia = coincidencia exacta | Relevancia = distancia | Deja de ser booleana. Todo resultado tiene grado, y hay que decidir dónde se corta |
| Reindexar tras un `ALTER` | Reembeber tras cambiar de modelo | **Cambiar el modelo de embeddings invalida el corpus entero.** No hay migración incremental: se reembebe todo o se tienen dos espacios incompatibles |

> 📝 **Nota de ecosistema.** El curso usa **`sentence-transformers` 6.0.1 con un modelo
> multilingüe que corre en tu portátil**, y no una API de embeddings alojada. Dos razones y una
> declaración honesta. La primera razón es la §5 de la historia de Áurea: un embedding local es la
> única vía compatible con la frontera clínica el día que alguien quiera indexar algo sensible. La
> segunda es que el curso tiene que poder tomarse entero sin gastar dinero, y embeber decenas de
> miles de fragmentos con una API cuesta. **Y la declaración:** un modelo alojado de última
> generación probablemente recupere mejor que el local, y este curso **no lo mide** porque no lo
> usa. Esa es una omisión declarada, no un resultado.

---

## 💻 5. Código mínimo con comentarios

El código vive en `src/ia04-embeddings-y-busqueda-semantica/`.

### 5.1 El esquema: los dos índices sobre la misma tabla

```sql
-- src/ia04-embeddings-y-busqueda-semantica/schema.sql
-- Una tabla, dos formas de buscar. Que compartan la fila no es economía: es lo que
-- permite comparar las dos estrategias sobre EXACTAMENTE los mismos fragmentos, que es
-- la condición para que la medición de la sección 6 signifique algo.

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE document_chunk (
    id              bigserial PRIMARY KEY,
    document_id     text        NOT NULL,   -- el archivo del que salió
    document_title  text        NOT NULL,
    clause          text,                   -- "Anexo 2, cláusula 4.3", si el troceo la conoce
    insurer_nit     text,                   -- para filtrar por aseguradora en la misma consulta
    valid_from      date,
    valid_to        date,                   -- NULL = vigente. Es el filtro que más se usa
    content         text        NOT NULL,
    embedding       vector(384) NOT NULL,   -- la dimensión la fija el modelo; ver embeddings.py

    -- La columna generada evita el problema clásico: un trigger que se olvida de correr
    -- deja el índice de texto desincronizado sin que nadie se entere durante meses.
    content_tsv     tsvector GENERATED ALWAYS AS (to_tsvector('spanish', content)) STORED
);

-- Índice vectorial. HNSW es aproximado a propósito: cambia exactitud por latencia, y sus
-- dos parámetros son la perilla. Se crea DESPUÉS de cargar los datos: construirlo sobre
-- una tabla vacía y llenarla después es más lento y da un grafo peor.
CREATE INDEX document_chunk_embedding_hnsw
    ON document_chunk USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Índice de texto completo. Es el competidor, y va bien configurado: diccionario en
-- español, no 'simple'. Medir contra un competidor mal configurado no prueba nada.
CREATE INDEX document_chunk_tsv_gin ON document_chunk USING gin (content_tsv);

-- Y el que de verdad se usa en producción, que ninguna de las dos estrategias tiene solo:
-- el filtro por aseguradora y vigencia. Es la razón por la que esto vive en Postgres.
CREATE INDEX document_chunk_scope ON document_chunk (insurer_nit, valid_to);
```

**Detalles con intención**

- **`vector(384)`** — la dimensión la impone el modelo y **no se puede cambiar sin reembeber
  todo**. Está escrita en el esquema para que el día que alguien cambie de modelo, la migración
  falle ruidosamente en vez de guardar vectores incompatibles.
- **La columna generada** en vez de un trigger. Un `tsvector` desincronizado es un fallo silencioso
  clásico y aquí es imposible por construcción.
- **`valid_to NULL` significa vigente**, y eso está en el esquema porque es la semántica del
  dominio: la mitad de los errores de NormaRAG van a ser citar un anexo derogado.
- **El índice HNSW se crea después de cargar.** Es una recomendación operativa real, no un detalle.

### 5.2 Los embeddings

```python
# src/ia04-embeddings-y-busqueda-semantica/embeddings.py
"""Embeddings locales.

Corre en tu máquina, no cuesta por token y no saca nada a internet. Lo que se paga a
cambio está declarado en la Nota de ecosistema de la sección 4, y es real.
"""

from __future__ import annotations

from collections.abc import Iterable, Iterator
from functools import lru_cache

from sentence_transformers import SentenceTransformer

# Modelo multilingüe pequeño: 384 dimensiones, corre en CPU en un portátil, y entiende
# español razonablemente. La dimensión está escrita en schema.sql: cambiar de modelo
# obliga a reembeber el corpus completo y a migrar la columna.
MODEL_NAME = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
DIMENSIONS = 384

# El lote no es un capricho de rendimiento: embeber de a uno sobre veinte mil fragmentos
# tarda un orden de magnitud más. Se mide en la sección 6.
BATCH_SIZE = 64


@lru_cache(maxsize=1)
def load_model() -> SentenceTransformer:
    """Carga el modelo una vez por proceso. Pesa cientos de megas y tarda en arrancar."""
    return SentenceTransformer(MODEL_NAME)


def embed_texts(texts: Iterable[str]) -> Iterator[list[float]]:
    """Embebe en lotes y devuelve un generador.

    Generador y no lista, por la razón de la Fase 02: el corpus de Áurea no cabe cómodo
    en memoria como matriz de flotantes, y quien consume esto lo va a insertar por lotes.
    """
    model = load_model()
    batch: list[str] = []

    for text in texts:
        batch.append(text)
        if len(batch) == BATCH_SIZE:
            # normalize_embeddings=True deja los vectores de norma 1. Con eso la
            # distancia coseno y el producto punto coinciden, y el operador <=> de
            # pgvector se comporta como esperas. Omitirlo es el error silencioso de
            # esta función: no falla, solo devuelve peores resultados.
            yield from model.encode(batch, normalize_embeddings=True).tolist()
            batch.clear()

    if batch:
        yield from model.encode(batch, normalize_embeddings=True).tolist()


def embed_query(question: str) -> list[float]:
    """Embebe una sola pregunta. Mismo modelo y misma normalización que el corpus.

    Usar un modelo distinto para la consulta y para el corpus es el error que produce
    resultados aleatorios sin lanzar ni un error: los dos vectores viven en espacios
    diferentes y la distancia entre ellos no significa nada.
    """
    return load_model().encode([question], normalize_embeddings=True)[0].tolist()
```

### 5.3 Las tres búsquedas, con la misma firma

```python
# src/ia04-embeddings-y-busqueda-semantica/search.py
"""Tres estrategias de recuperación sobre los mismos fragmentos.

Misma firma para las tres. Es lo que permite que la medición de la sección 6 las trate
como intercambiables y que el miniproyecto pueda enrutar entre ellas.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from psycopg import Connection
from psycopg.rows import class_row

# `embeddings` se importa DENTRO de `vector_search`, no aquí. Importarlo arriba arrastra
# `sentence_transformers` y con él PyTorch: son segundos de arranque y cientos de megas
# para un proceso que quizá solo va a usar la búsqueda léxica. Es también lo que permite
# probar `fuse_ranks` sin tener el modelo instalado.

# Calibrado en la sección 6 sobre las preguntas anotadas, no elegido a ojo. Por encima
# de esta distancia coseno, los fragmentos dejaron de tener que ver con la pregunta.
DEFAULT_MAX_DISTANCE = 0.35

# Constante de la fusión de rangos recíprocos. 60 es el valor del artículo original y
# funciona bien; se deja explícito para que se pueda variar en un ejercicio.
RRF_K = 60


@dataclass(frozen=True, slots=True)
class Hit:
    """Un fragmento recuperado, con lo necesario para citarlo y para descartarlo."""

    chunk_id: int
    document_title: str
    clause: str | None
    content: str
    score: float  # comparable DENTRO de una estrategia, nunca entre estrategias


def vector_search(
    connection: Connection,
    question: str,
    *,
    k: int = 5,
    insurer_nit: str | None = None,
    on: date | None = None,
    max_distance: float = DEFAULT_MAX_DISTANCE,
) -> list[Hit]:
    """Búsqueda por similitud, con umbral y con filtros en la MISMA consulta.

    El filtro por aseguradora y vigencia dentro del SQL es la razón por la que esto vive
    en Postgres: con un servicio vectorial aparte serían dos consultas y una intersección
    a mano, y el `LIMIT k` se aplicaría antes de filtrar, que es peor de lo que parece.
    """
    from embeddings import embed_query  # importación diferida; ver la cabecera

    vector = embed_query(question)
    reference = on or date.today()

    with connection.cursor(row_factory=class_row(Hit)) as cursor:
        cursor.execute(
            """
            SELECT id                        AS chunk_id,
                   document_title,
                   clause,
                   content,
                   1 - (embedding <=> %(vector)s::vector) AS score
            FROM document_chunk
            WHERE (%(nit)s::text IS NULL OR insurer_nit = %(nit)s)
              AND (valid_from IS NULL OR valid_from <= %(on)s)
              AND (valid_to   IS NULL OR valid_to   >= %(on)s)
              AND (embedding <=> %(vector)s::vector) <= %(max_distance)s
            ORDER BY embedding <=> %(vector)s::vector
            LIMIT %(k)s
            """,
            {
                "vector": vector,
                "nit": insurer_nit,
                "on": reference,
                "max_distance": max_distance,
                "k": k,
            },
        )
        return cursor.fetchall()


def lexical_search(
    connection: Connection,
    question: str,
    *,
    k: int = 5,
    insurer_nit: str | None = None,
    on: date | None = None,
) -> list[Hit]:
    """Búsqueda de texto completo. El competidor, bien configurado.

    `websearch_to_tsquery` acepta lo que la gente escribe de verdad —comillas, guiones,
    la palabra "or"— en vez de exigir la sintaxis de tsquery. Usar `plainto_tsquery`
    aquí sería debilitar al competidor, y eso invalidaría la medición.
    """
    reference = on or date.today()

    with connection.cursor(row_factory=class_row(Hit)) as cursor:
        cursor.execute(
            """
            SELECT id AS chunk_id,
                   document_title,
                   clause,
                   content,
                   ts_rank(content_tsv, query) AS score
            FROM document_chunk,
                 websearch_to_tsquery('spanish', %(question)s) AS query
            WHERE content_tsv @@ query
              AND (%(nit)s::text IS NULL OR insurer_nit = %(nit)s)
              AND (valid_from IS NULL OR valid_from <= %(on)s)
              AND (valid_to   IS NULL OR valid_to   >= %(on)s)
            ORDER BY score DESC
            LIMIT %(k)s
            """,
            {"question": question, "nit": insurer_nit, "on": reference, "k": k},
        )
        return cursor.fetchall()


def fuse_ranks(rankings: list[list[Hit]], *, k: int, rrf_k: int = RRF_K) -> list[Hit]:
    """Fusión de rangos recíprocos: función pura, y por eso se puede probar sin Postgres.

    Se fusionan las POSICIONES, no los puntajes, y esa es la decisión importante: el
    `ts_rank` de la léxica y la similitud coseno de la vectorial no son comparables ni
    normalizándolos, porque no miden lo mismo. Sumar el inverso de la posición sí tiene
    sentido, y es lo que hace que la fusión funcione sin calibrar pesos.
    """
    fused: dict[int, float] = {}
    by_id: dict[int, Hit] = {}

    for hits in rankings:
        for position, hit in enumerate(hits, start=1):
            fused[hit.chunk_id] = fused.get(hit.chunk_id, 0.0) + 1 / (rrf_k + position)
            by_id[hit.chunk_id] = hit

    # El desempate por id no es cosmético: sin él, dos fragmentos con el mismo puntaje
    # fusionado se ordenan según el recorrido del diccionario y la búsqueda deja de ser
    # reproducible entre corridas.
    ranked = sorted(fused.items(), key=lambda item: (-item[1], item[0]))[:k]
    return [
        Hit(
            chunk_id=chunk_id,
            document_title=by_id[chunk_id].document_title,
            clause=by_id[chunk_id].clause,
            content=by_id[chunk_id].content,
            score=score,
        )
        for chunk_id, score in ranked
    ]


def hybrid_search(
    connection: Connection,
    question: str,
    *,
    k: int = 5,
    insurer_nit: str | None = None,
    on: date | None = None,
) -> list[Hit]:
    """Fusión de las dos listas. El trabajo real lo hace `fuse_ranks`."""
    pool = 4 * k  # se pide de más a cada una: la fusión necesita cola para trabajar
    vector_hits = vector_search(
        connection, question, k=pool, insurer_nit=insurer_nit, on=on, max_distance=1.0
    )
    lexical_hits = lexical_search(connection, question, k=pool, insurer_nit=insurer_nit, on=on)
    return fuse_ranks([vector_hits, lexical_hits], k=k)
```

**Detalles con intención**

- **El umbral de distancia va en el `WHERE`, no en Python.** Filtrar después del `LIMIT` te deja
  con menos de `k` resultados por accidente; filtrar en la consulta le deja al planificador la
  decisión.
- **`websearch_to_tsquery` y diccionario `spanish`.** El competidor se configura bien: es la regla
  de honestidad del curso y aquí es la diferencia entre una medición y una demostración amañada.
- **La fusión suma posiciones, no puntajes.** Es el punto técnico que más se hace mal, y el
  comentario explica por qué: las dos escalas no son comparables.
- **`fuse_ranks` es una función pura, separada de la consulta.** No es purismo: es lo que permite
  probar la parte más fácil de escribir mal **sin Postgres, sin modelo y en milisegundos**.
  `test_fusion.py` tiene seis pruebas y una de ellas —la de los puntajes incomparables— es la que
  falla si algún día alguien "mejora" la fusión sumando los puntajes de origen.
- **`embeddings` se importa dentro de `vector_search`.** Importarlo arriba arrastra PyTorch al
  arranque de cualquier proceso que toque este módulo, incluida la búsqueda léxica, que no lo
  necesita.
- **`score` significa cosas distintas en cada estrategia**, y el `dataclass` lo dice en un
  comentario en vez de fingir que es una métrica única.

> 💸 **Deuda técnica intencional.** El umbral es **uno solo y global**, y no debería serlo: una
> pregunta de tres palabras y una de treinta producen distribuciones de distancia distintas. Lo
> correcto es un umbral relativo —la caída entre el primer resultado y el segundo— o uno calibrado
> por tipo de consulta. **Se paga en `ia06`**, donde el conjunto de evaluación permite calibrarlo
> con datos en vez de con intuición.

**El patrón a memorizar**

> Los embeddings buscan **por significado** y no ven identificadores; el texto completo busca **por
> palabra** y no ve sinónimos. La pregunta no es cuál es mejor: es **cuál de las dos falla en tu
> corpus**, y en un corpus de contratos con códigos tarifarios fallan en sitios distintos.

**Prueba de fuego**

```bash
uv run python -c "
from search import vector_search, lexical_search
from db import connect
with connect() as c:
    for name, fn in (('vectorial', vector_search), ('léxica', lexical_search)):
        hits = fn(c, '992102')
        print(name, [h.clause for h in hits])
"
```

Lo que tiene que salir: la léxica encuentra la cláusula que menciona el código `992102`; la
vectorial devuelve **cualquier cosa**, o nada si el umbral hace su trabajo. **La mentira que te va
a contar la salida si miras el lugar equivocado:** si corres solo la vectorial y le pasas una
pregunta en prosa, los resultados se ven plausibles y vas a concluir que funciona. La prueba que
importa es esta, la del código de procedimiento, porque es la que revela el agujero — y es la
consulta que Patricia hace veinte veces al día.

---

## 📏 6. Medición

**Hipótesis.** Sobre las preguntas reales de Patricia, **la búsqueda de texto completo de Postgres
le gana a `pgvector` en las consultas que contienen un identificador o un término técnico exacto,
y pierde claramente en las preguntas en prosa**. La híbrida gana a las dos en el agregado, y su
ventaja sobre la léxica sola es menor de lo que la literatura sugiere.

**Condiciones.** Python 3.14.7; PostgreSQL 18.0 con `pgvector` 0.5.0 y `pg_trgm`;
`sentence-transformers` 6.0.1 con `paraphrase-multilingual-MiniLM-L12-v2`. Corpus documental de
Áurea seudonimizado: contratos, anexos tarifarios, circulares y el manual de glosas, troceado por
cláusula, del orden de veinte mil fragmentos y **cero historia clínica**. Cincuenta preguntas
reales de Patricia y las auxiliares, cada una con **el fragmento correcto anotado a mano**, y
etiquetadas como *léxica*, *semántica* o *mixta* antes de correr nada — etiquetar después de ver
los resultados sería fabricar la conclusión. Máquina de referencia del curso, índice HNSW con
`m=16, ef_construction=64`. Se mide recall@5, MRR@10, latencia p50/p95 de la consulta, y el tiempo
y el disco que cuesta indexar.

**Competidores.** Los tres corren sobre **los mismos fragmentos y con los mismos filtros**, que es
lo que hace comparables los números. El texto completo va con diccionario en español y
`websearch_to_tsquery`, no con `LIKE '%…%'`: medir contra la versión débil del competidor sería
exactamente lo que este curso le reprocha a los demás.

**Resultado.**

| Estrategia | recall@5 · todas | recall@5 · léxicas | recall@5 · semánticas | MRR@10 | p95 consulta | Indexación |
|---|---|---|---|---|---|---|
| Texto completo (`tsvector`) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Vectorial (`pgvector` + HNSW) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Híbrida (fusión de rangos) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

```bash
uv run python bench_retrieval.py --preguntas preguntas_anotadas.jsonl --k 5
```

> ⚖️ **Veredicto — pendiente de correr, con la expectativa declarada.** Las dos columnas del medio
> son el contenido de la sección: esperamos que se crucen, y si se cruzan queda demostrado que la
> pregunta correcta no es *"¿embeddings o texto completo?"* sino *"¿qué clase de pregunta es
> esta?"*. **Los dos umbrales por determinar:** cuál es el umbral de distancia que separa mejor
> los aciertos de los fallos —hoy está en 0.35 por intuición y eso es una deuda 💸—, y **cuánto
> recall adicional aporta la híbrida sobre la léxica sola**. Si aporta menos de unos pocos puntos,
> la conclusión honesta para Áurea es que la mitad vectorial de NormaRAG no se justifica, y
> entonces se escribe eso: veinte mil fragmentos indexados y un modelo que mantener, para ganar
> tres puntos de recall, es un mal negocio para una empresa con un solo ingeniero.

> 📝 **Lo que esta medición no dice.** No compara contra un modelo de embeddings alojado, porque el
> curso no usa uno; es una omisión declarada y probablemente favorece a la búsqueda léxica en la
> comparación. Y no mide si la **respuesta** final es correcta: eso necesita el generador de `ia05`
> y la evaluación de `ia06`.

---

## 🧱 7. Miniproyecto — El enrutador, y las tres preguntas que lo tumban

**El encargo.** Construye `aur-buscar`, la capa de recuperación de NormaRAG: recibe una pregunta y
devuelve fragmentos citables o **nada**. Y hace algo más que elegir una estrategia fija: **decide
cuál usar según la pregunta**, y esa decisión está escrita en código que se puede leer y defender,
no delegada al modelo.

**Por qué duele.** Porque el enrutador es trivial de escribir y difícil de justificar. Cualquiera
escribe *"si la pregunta tiene un número, usa la léxica"*. Lo que se te pide es la versión que
sobrevive a las cincuenta preguntas anotadas y a las tres que diseñaste tú para tumbarla, con el
recall de cada rama medido por separado.

**Datos de entrada.** El corpus troceado y las cincuenta preguntas anotadas de la sección 6, más
**tres preguntas que escribes tú y que rompen tu propio enrutador**. Esas tres son parte del
entregable.

**Criterios de aceptación.**

1. `aur-buscar "..."` devuelve como máximo cinco fragmentos, cada uno con documento, cláusula y
   puntaje, o el texto **"no encontré nada que sostenga una respuesta"** — y ese caso ocurre de
   verdad al menos una vez en las cincuenta preguntas. Si nunca ocurre, tu umbral está mal.
2. `--explicar` imprime **por qué** se eligió esa estrategia, en una línea que Patricia entienda.
3. El recall@5 del enrutador es **mayor o igual** que el de la mejor estrategia fija sobre las
   cincuenta preguntas. Si no lo es, el enrutador no se justifica y el entregable es esa
   conclusión, medida y escrita.
4. `--estrategia vectorial|lexica|hibrida|auto` fuerza una, para poder reproducir la tabla de la
   sección 6 desde la misma herramienta.
5. El umbral de distancia **no está escrito a mano**: sale de un comando `aur-buscar calibrar` que
   lo deriva de las preguntas anotadas y escribe el valor en la configuración, con la fecha.
6. Las tres preguntas que rompen tu enrutador están en el repositorio, con lo que devuelve hoy y
   con lo que debería devolver. **No hay que arreglarlas todas**: hay que documentar cuál se
   arregló, cuál no y por qué.
7. Cambiar el modelo de embeddings falla ruidosamente: si la dimensión del modelo no coincide con
   la de la columna, el proceso de indexación se detiene con un mensaje que dice qué hacer.

**Restricciones de registro.** Aplicación: Postgres, tipos estrictos, pruebas, migraciones con
Alembic como en la Fase 11. La búsqueda **no llama al modelo de lenguaje** — ni para clasificar la
pregunta. Si tu enrutador necesita un LLM para decidir la estrategia, has convertido una decisión
de veinte microsegundos en una de dos segundos y medio centavo; puede que valga la pena, y en ese
caso lo mides y lo defiendes, pero por defecto no.

**La trampa.** El criterio 3. Es muy posible que tu enrutador **no le gane** a la híbrida a secas,
porque la fusión de rangos ya hace implícitamente lo que tú estás intentando hacer explícito. Si
eso pasa, el entregable correcto es la medición que lo demuestra y una recomendación de dos líneas
para Áurea: usar la híbrida y borrar el enrutador. Ese resultado vale igual que el otro y es más
difícil de entregar, porque implica borrar código que funciona.

**Pistas.** Etiqueta las cincuenta preguntas **antes** de mirar ningún resultado. Para calibrar el
umbral, grafica las distancias de los aciertos contra las de los fallos: si las dos nubes se
solapan del todo, el umbral no te va a salvar y hace falta otra señal. Y para las tres preguntas
adversariales, el terreno fértil es donde el corpus tiene dos cláusulas casi idénticas de dos
aseguradoras distintas.

**Cómo se entrega.** `git tag -a ia-mini-04`, y **en el mensaje del tag va el recall@5 del
enrutador y el de la mejor estrategia fija**, en ese orden. Si el segundo es mayor, se escribe
igual: es la medición.

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Embebe las frases *"retiro de brackets"*, *"remoción de aparatología"* y *"992102"*, y calcula
   las tres distancias entre sí. El resultado es la sección entera en tres números.
2. Corre `EXPLAIN (ANALYZE)` sobre la consulta vectorial y verifica que usa el índice HNSW. Después
   agrega un filtro muy selectivo por aseguradora y vuelve a mirar: ¿lo sigue usando?
3. Quítale `normalize_embeddings=True` a `embed_texts` y mide el recall de nuevo. Nada falla y los
   resultados empeoran: es el error silencioso de la sección 5.2.
4. Sube `max_distance` a 1.0 y cuenta cuántas de las cincuenta preguntas devuelven algo. Después
   bájalo a 0.15 y repite. Grafica las dos curvas.
5. Busca `"ajiaco"` con la vectorial y sin umbral. Lee los cinco resultados. Es la demostración más
   corta de por qué la ausencia hay que fabricarla.
6. Cambia el diccionario del `tsvector` de `'spanish'` a `'simple'` y mide el recall de la léxica.
   La diferencia es el costo de configurar mal al competidor.

**🟡 Intermedio (7–14)**

7. Mide el tiempo de indexación con `BATCH_SIZE` en 1, 16, 64 y 256, sobre mil fragmentos. Encuentra
   dónde deja de mejorar y explica por qué.
8. Implementa una cuarta estrategia: léxica sobre `pg_trgm` con similitud de trigramas, y mide si
   aporta algo en las preguntas con errores de escritura.
9. Varía `ef_search` en la consulta vectorial y grafica recall contra latencia. Esa curva es la
   perilla de la que habla la sección 4, y hay que haberla visto una vez.
10. Cambia `RRF_K` de 60 a 10 y a 200, y mide el efecto sobre el recall de la híbrida. Decide si el
    valor por defecto merecía ser un parámetro.
11. Añade a `Hit` la posición en cada lista de origen y haz que `--explicar` muestre de dónde vino
    cada resultado de la híbrida. Es lo que necesitas para depurar una fusión.
12. Trocea el mismo documento de tres formas —por cláusula, cada 500 caracteres, y cada 500 con
    solape de 100— y mide el recall de las tres. Es la variable que más mueve el resultado de un
    RAG, y aquí se ve.
13. Haz que la indexación sea reanudable: si se cae a la mitad de veinte mil fragmentos, que
    continúe donde iba. Es la Fase 15 aplicada aquí.
14. Escribe la migración de Alembic que añade la columna vectorial a una tabla que ya existe, y la
    de vuelta atrás. La de vuelta atrás es la que se te va a olvidar.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Te entregan un índice que recupera bien en desarrollo y mal en producción,
    con el mismo código. Hay tres causas plausibles —el corpus de producción tiene documentos
    derogados sin `valid_to`, el modelo de la consulta no es el del corpus, y el índice se
    construyó sobre la tabla vacía—. Diseña la comprobación de cada una y ordénalas por costo.
16. **Medición.** Cuantifica el costo de mantener el índice: mide la latencia de inserción de mil
    fragmentos con y sin el índice HNSW, y el tamaño en disco de cada índice. Es el número que
    falta en casi todas las comparaciones de bases de datos vectoriales.
17. Implementa la búsqueda por *ventana*: cuando un fragmento acierta, devuelve también el
    anterior y el siguiente del mismo documento. Mide si mejora el recall y cuánto contexto de más
    le cuesta a `ia05`.
18. **Diagnóstico.** Una pregunta sobre una aseguradora concreta devuelve fragmentos de otra. Con
    el esquema de la sección 5.1, encuentra las dos formas en que eso puede pasar y arregla la que
    sea un bug — la otra es una decisión de diseño y hay que reconocerla.
19. **De registro.** La recuperación de NormaRAG: decide si es script, herramienta o aplicación, y
    **cuantifica el costo de las otras dos**. Después contesta la incómoda: con veinte mil
    fragmentos y quince consultas al día, ¿no bastaba con la búsqueda de texto completo?
20. **De registro.** Julián leyó que hace falta "una base de datos vectorial". Escribe la
    respuesta de media página, con el número de fragmentos de Áurea, lo que costaría el servicio
    adicional y **la condición concreta bajo la cual cambiarías de opinión**.
21. Reembebe el corpus con un modelo de dimensión distinta y documenta el procedimiento completo
    de migración sin caída del servicio. Es el escenario que la sección 4 llama sin migración
    incremental, y hay una forma de hacerlo.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Construye el conjunto de diez preguntas donde la búsqueda vectorial le gana a
    la híbrida. Si no lo consigues, escribe por qué no y qué dice eso de la fusión de rangos.
23. Diseña y mide la evaluación de la **cobertura del corpus**: qué fracción de las preguntas de
    Patricia no tiene respuesta en ningún documento. Ese número decide si NormaRAG puede existir, y
    nadie lo mide nunca.
24. **Adversarial.** Un anexo derogado y su reemplazo son casi idénticos: cinco párrafos iguales y
    uno distinto, que es el que importa. Demuestra que tu recuperación devuelve el vigente **por
    el mecanismo correcto** y no por suerte, y después rompe el mecanismo para comprobar que la
    prueba sirve.
25. Toma la medición de la sección 6 y escribe la recomendación para Áurea en una página: qué se
    construye, qué no, con qué números, y bajo qué condición se revisa la decisión. Tiene que ser
    defendible ante alguien que quiere que la respuesta sea "usemos IA".

**🔥 Opcionales**

- Compara el modelo multilingüe pequeño contra uno grande en la misma máquina: recall, latencia y
  memoria. La decisión no es obvia en un portátil.
- Implementa el reordenamiento con el modelo de `ia01` sobre los veinte primeros resultados y mide
  cuánto recall@5 compra y cuánto cuesta. Es un anticipo de `ia05`.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://github.com/pgvector/pgvector` — el operador `<=>`, los tipos de índice y los parámetros
  de HNSW. Léelo entero: es corto y contesta el 90% de las dudas de esta sección.
- `https://www.postgresql.org/docs/18/textsearch.html` — búsqueda de texto completo, diccionarios,
  `ts_rank` y `websearch_to_tsquery`. El capítulo que casi nadie lee antes de decidir que necesita
  embeddings.
- `https://www.postgresql.org/docs/18/pgtrgm.html` — similitud por trigramas, para el ejercicio 8.
- `https://sbert.net/` — `sentence-transformers`: `encode`, normalización, lotes y el catálogo de
  modelos con sus dimensiones.
- `https://docs.python.org/3.14/library/statistics.html` — para las métricas del arnés.

**Artículos**

- El artículo original de la fusión de rangos recíprocos (Cormack, Clarke y Buettcher, SIGIR 2009)
  es la fuente del `RRF_K = 60`. Búscalo por título; los datos bibliográficos exactos hay que
  verificarlos y aquí no se inventan.

**Orden de lectura sugerido:** el capítulo de texto completo de PostgreSQL **antes** que nada
—para saber contra qué compites y para no reinventarlo—, después el README de `pgvector` mientras
escribes el esquema, y `sbert.net` solo para elegir el modelo y entender la normalización.

> ⚠️ URLs, títulos y contenidos pueden haber cambiado desde la fecha de verificación; el lector
> debe comprobarlos. Aquí no se inventan páginas, ISBN ni identificadores de video.

---

## 🚀 10. Cierre y conexión con la siguiente sección

Terminas con la recuperación construida y —más importante— **medida por separado de la
generación**, que es la decisión metodológica que salva a la mitad de los RAG que fracasan. Tienes
las dos búsquedas sobre los mismos fragmentos, la fusión que las combina sin inventar pesos, y un
umbral que le permite al sistema decir que no encontró nada. Y tienes una tabla que puede
concluir, con datos, que la mitad vectorial no valía la pena en Áurea.

En `ia05` se cierra el circuito: los fragmentos entran al modelo y sale una respuesta que **cita
documento, versión y cláusula, o no se emite**. Ese requisito, que viene del negocio y no de la
ingeniería, es el que obliga a que el troceado conserve el encabezado de la cláusula, y es donde
se cobra todo lo que hiciste bien aquí: **un fragmento que no se puede citar no sirve, por muy
bien recuperado que esté**.

> **La señal de que quedó bien:** cuando ante una pregunta nueva tu primer reflejo sea clasificarla
> —*esto es léxico*— en vez de embeberla, y cuando un *"no encontré nada"* te parezca una respuesta
> de calidad en vez de un fallo de la búsqueda.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ia-fase-04 -m "ia04 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ia 04: …`), los de ejercicio su número
> (`ia 04 ej12: …`) y el miniproyecto el suyo (`ia 04 mini: …`). El miniproyecto terminado lleva
> además su tag anotado `ia-mini-04`, con **el recall del enrutador y el de la mejor estrategia
> fija** en el mensaje. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
