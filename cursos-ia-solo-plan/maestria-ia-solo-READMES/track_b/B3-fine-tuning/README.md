# B3: Fine-tuning de un modelo de dominio específico

**Intensidad:** Segunda mitad de Fase 0 | **Tiempo:** ~2 h/semana durante Fase 0

## Resumen

Primera pasada práctica en fine-tuning. **Nota:** Fase 9 retoma con más rigor teórico (por qué funciona LoRA matemáticamente, RLHF/DPO). Aquí: perder el miedo, entender flujo punta a punta.

## Pasos

1. Cura dataset pequeño pero limpio (cientos de ejemplos) en formato instrucción-respuesta para tu dominio
2. Fine-tunea con LoRA/QLoRA usando **Unsloth** (más simple en una GPU de consumo) sobre modelo base pequeño (7–8B)
3. Fusiona adaptador, convierte a GGUF, corre en Ollama
4. Evalúa rigurosamente: métricas específicas de tarea antes/después, verificación de que no perdió capacidad general
5. Documenta honestamente: cuándo fine-tuning tuvo sentido vs. prompt bien diseñado o RAG

## Recursos

- Unsloth: unsloth.ai/docs (guías paso a paso, notebooks gratuitos en Colab)
- Ollama: ollama.com
- Hugging Face `transformers`, `peft`, `trl` (stack más portable, más verboso)
