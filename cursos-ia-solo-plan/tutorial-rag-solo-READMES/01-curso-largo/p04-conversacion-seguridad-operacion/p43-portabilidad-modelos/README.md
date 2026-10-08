# P43 — Portabilidad de modelos

**Guía de proyecto · ~2 h**

## Qué construyes

Cambias de Ollama a OpenAI sin tocar el dominio.

## Contenidos

- EmbeddingProvider interface
- OllamaEmbeddingProvider, OpenAIEmbeddingProvider
- Configuration: dónde elegir proveedor
- Mismo modelo, diferente backend

## Criterio de finalización

Cambias en application.yml `embedding.provider=openai`. Recompilás. Sistema funciona igual. Mismo modelo, otro proveedor.

## Después de esta guía

Pasás a P44. Ahora despliegue y operación.
