# `ia04` · Embeddings, búsqueda semántica, y cuándo Postgres gana

Código de la sección
[`ia04-embeddings-y-busqueda-semantica.md`](../../ia04-embeddings-y-busqueda-semantica.md).

| Archivo | Qué es |
|---|---|
| `schema.sql` | Una tabla con **los dos índices**: HNSW para vectores y GIN para texto completo |
| `embeddings.py` | El modelo local, en lotes y normalizado. Y la comprobación de dimensión |
| `db.py` | Conexión con los tipos de `pgvector` registrados |
| `search.py` | Las tres estrategias con la misma firma, y `fuse_ranks` como función pura |
| `bench_retrieval.py` | La medición de la sección 6: recall@5 por tipo de pregunta, MRR y latencia |
| `test_fusion.py` | Seis pruebas de la fusión, **sin Postgres y sin modelo**: `pytest test_fusion.py` |

## Antes de correr nada

```bash
export AUREA_DSN="postgresql:///aurea"       # la misma de la Fase 11
psql "$AUREA_DSN" -f schema.sql
```

`sentence-transformers` descarga el modelo la primera vez (unos cientos de megas) y arrastra
PyTorch. Por eso `search.py` **no** lo importa al cargarse: solo `vector_search` lo hace, y así la
búsqueda léxica y las pruebas de fusión corren sin él.

## Las dos comparaciones que hay que respetar

1. Las tres estrategias corren sobre **los mismos fragmentos** y con **los mismos filtros**. Si no,
   los números no son comparables y la tabla de la sección 6 no significa nada.
2. El competidor va **bien configurado**: diccionario `spanish` y `websearch_to_tsquery`, no
   `LIKE '%…%'` ni `'simple'`. Medir contra la versión débil sería exactamente lo que este curso
   le reprocha a los demás.

## Los datos

```bash
python generar_corpus.py --salida corpus     # 24 documentos, 129 fragmentos, 50 preguntas
```

Produce el corpus documental de Áurea —anexos tarifarios de cuatro aseguradoras ficticias, con la
estructura de cláusulas que espera `ingest.split_by_clause` de `ia05`—, su `manifiesto.json` y
`preguntas_anotadas.jsonl`. Un tercio de los documentos son **versiones derogadas** casi idénticas
a las vigentes: es el caso del miniproyecto de `ia05`, y solo los metadatos las distinguen.

La etiqueta de cada pregunta —`lexica` | `semantica` | `mixta`— se asigna **por construcción**,
porque cada plantilla sabe qué clase de consulta produce. Eso es legítimo con un corpus generado y
**no lo es** con uno real, donde etiquetar después de ver los resultados fabrica la conclusión.

Salida reproducible byte a byte con la misma semilla; los archivos generados no se versionan.
