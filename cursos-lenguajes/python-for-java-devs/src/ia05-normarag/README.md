# `ia05` · Proyecto · NormaRAG

Código de la sección [`ia05-normarag.md`](../../ia05-normarag.md).

| Archivo | Qué es |
|---|---|
| `ingest.py` | Del PDF al fragmento citable: troceo por cláusula, posiciones en el original, informe de cobertura |
| `answer.py` | Generación con contrato, y `verify_citations` — la función que decide si la respuesta se emite |
| `bench_answers.py` | La medición de la sección 6: cuatro enfoques, incluido el que puede recortar el proyecto |
| `test_normarag.py` | Catorce pruebas **sin red, sin Postgres y sin modelo** |

## Correr las pruebas

Importan de tres secciones anteriores, que en tu repositorio viven en el mismo paquete:

```bash
PYTHONPATH=../ia01-el-modelo-de-acceso-de-un-llm:../ia02-salida-estructurada:../ia04-embeddings-y-busqueda-semantica \
  pytest test_normarag.py -q
```

## Las dos piezas que se prueban sin nada

`chunk_text` y `verify_citations` son funciones puras, y no por purismo: son las que sostienen la
regla del proyecto —**sin cita verificada no hay respuesta**—, así que tienen que ser demostrables
en milisegundos. La prueba `test_cross_citation_is_rejected` es la importante: verifica que una
frase real, atribuida al documento equivocado, se rechaza. Es el error que a ojo nadie ve.

## Los datos

El corpus sale de `../ia04-embeddings-y-busqueda-semantica/generar_corpus.py`, que produce texto
plano con estructura de cláusulas. Los 24 documentos generados pasan por `chunk_text` sin que
ninguno quede *sin estructura*, que es la comprobación que hace utilizable al generador.

Los PDF escaneados del corpus real quedan fuera **y contados**: `IngestReport.coverage()` es el
número, y el OCR es del track `ar`.
