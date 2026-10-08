# B2: Modelos locales con Ollama

**Intensidad:** Segundo tercio de Fase 0 | **Tiempo:** ~2 h/semana durante Fase 0

## Resumen

Correr LLMs abiertos localmente. Entender cuantización, trade-offs tamaño/VRAM/calidad. Decidir con criterio cuándo local tiene sentido vs. API.

## Qué practicar

- Instala Ollama, corre 2–3 modelos abiertos distintos (Llama, Qwen, DeepSeek)
- Compara: tamaño, velocidad, calidad
- Entiende cuantización (GGUF, Q4/Q8) y sus trade-offs
- Decide con criterio: privacidad, costo, latencia, sin conexión vs. API

## Diferencias de implementación (conexión con Fase 5)

- **Denso vs. MoE:** Llama (denso, todos parámetros/token) vs. Qwen3-Coder/DeepSeek-V3 (MoE, solo ~35–37B activos de 480–671B totales)
- **Atención:** MHA estándar vs. GQA (Grouped-Query) vs. MLA (Multi-Head Latent, DeepSeek)
- **Entrenamientos:** RLHF clásico vs. GRPO (Group Relative Policy Optimization, DeepSeek)
- **Licenciamiento:** Qwen/DeepSeek abiertos (Apache 2.0, MIT) vs. cerrados (Claude, GPT, Gemini) vs. Llama (licencia propia)

## Recursos

- Ollama: ollama.com
- DeepSeek reportes técnicos en arxiv.org
- Qwen blog: qwen.ai/blog
