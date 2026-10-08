# Semana 4 — Sesión 3: Proyecto (2.5 h)

## Qué construyes

VectorSearchService: indexa en ChromaDB. Comando query que imprime recuperación sin LLM.

## Tareas

1. ChromaDB collection: almacena embeddings
2. QueryEmbedder: convierte pregunta en vector
3. VectorSearch: similitud coseno, topK
4. Comando `query("¿cuántos días de vacaciones?")` imprime:
   - Fragmento
   - Fuente
   - Distancia
   - Tokens

## Criterio de finalización

Comando existe. Muestra exactamente qué recuperó. Sin LLM todavía. Este es tu tool de debug permanente.

## Siguiente semana

Semana 5: Generación. RAG funcional con grounding, citas, abstención.
