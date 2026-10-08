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
