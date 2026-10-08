# Track B — Pista Práctica (Paralela solo durante Fase 0)

Herramientas y flujos de trabajo actuales: agentes de código, MCP, modelos locales, fine-tuning. Corre en paralelo **solo durante la Fase 0** (~2 h/semana mientras haces ~4 h de matemáticas) y **se cierra con B4 antes de arrancar la Fase 1**.

**Filosofía:** ganar soltura práctica temprana con herramientas reales (sin "vibe coding" ciego), entender la arquitectura detrás de cada una — para no depender de que la moda específica siga vigente.

**Convergencia:** Track B da soltura práctica temprana; Track A explica *por qué* esas herramientas funcionan (o fallan) por debajo. En la Fase 9 se retoma todo lo de Track B con rigor de producción.

## Bloques

| Bloque | Tema | Intensidad |
|---|---|---|
| [B0](./B0-agentes-de-código/README.md) | Agentes de código: Claude Code, Codex CLI, Qwen Code | Primer tercio F0 |
| [B1](./B1-mcp/README.md) | MCP (Model Context Protocol) — construir un servidor propio | Primer tercio F0 |
| [B2](./B2-modelos-locales-ollama/README.md) | Modelos locales con Ollama; denso vs. MoE, cuantización | Segundo tercio F0 |
| [B3](./B3-fine-tuning/README.md) | Fine-tuning de un modelo de dominio específico (LoRA/QLoRA) | Segunda mitad F0 |
| [B4](./B4-cierre-integrador/README.md) | Cierre integrador: analizador de tendencias/ventas | Final F0 |
| [B5](./B5-puesta-al-día-opcional/README.md) | Puesta al día opcional: 1 herramienta/modelo nuevo | Medio día transición entre fases |

## Criterios de salida por bloque

- **B0:** Usas los tres agentes en proyecto real; entiendes diferencias (modelo cerrado vs. abierto)
- **B1:** Construyes y conectas un servidor MCP funcional
- **B2:** Comparas modelos densos vs. MoE; decides con criterio cuándo local vs. API
- **B3:** Fine-tuneado funcionando; documentas honestamente cuándo tiene sentido vs. prompt/RAG
- **B4:** API + dashboard demostrable integrando B0–B3
- **B5:** (Opcional) Al día con innovación reciente, sin obligación

## Cierre de Track B

Después de completar B4 (final de Fase 0), **Track B se cierra**. Las 6 h/semana pasan a ser 100% Track A, secuencial.

**Puesta al día (B5):** en vez de modo mantenimiento permanente, puedes dedicar **medio día al cerrar cada fase de Track A** a probar lo nuevo — pero sin obligación. Fase 9 retoma estado del arte con rigor de todas formas.

## Integración Track A ↔ Track B

- Track B acelera construcción (B0 agentes) y reduce fricción de infraestructura (B1 MCP, B2 local, B3 fine-tuning)
- Track A explica por qué Transformers funcionan (Fase 5 → 7), cómo se entrenan eficientemente (Fase 9), cuándo RL es la herramienta correcta (Fase 8)
- En Fase 9, vuelves a todos los temas de B0–B3 con rigor: evaluación exhaustiva, RLHF/DPO, arquitecturas de agentes, gobernanza
