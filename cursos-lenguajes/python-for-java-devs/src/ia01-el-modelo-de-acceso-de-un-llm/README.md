# `ia01` · El modelo de acceso de un LLM

Código de la sección [`ia01-el-modelo-de-acceso-de-un-llm.md`](../../ia01-el-modelo-de-acceso-de-un-llm.md).

| Archivo | Qué es |
|---|---|
| `pricing.py` | Las tarifas, en `Decimal`, con su fecha de verificación. El único lugar donde se tocan |
| `llm.py` | El cliente y `ask()`: la única puerta por la que el track habla con la API |
| `count_and_price.py` | Estimar el costo **antes** de enviar la petición |
| `local.py` | El mismo trabajo contra un modelo local con Ollama |
| `bench_models.py` | La medición de la sección 6, ampliando el arnés de la Fase 02 |
| `test_failures.py` | Los fallos, provocados a mano. `pytest -m network` |

## Antes de correr nada

```bash
export ANTHROPIC_API_KEY=...     # o `ant auth login`
ollama pull gemma3               # solo si vas a correr local.py
```

Las versiones exactas son las que fija la sección
[`ia01`](../../ia01-el-modelo-de-acceso-de-un-llm.md), con su fecha. **La tarifa de
`pricing.py` se reverifica antes de repetir cualquier medición de costo**: es el dato que más
rápido envejece del curso.

## Los datos

```bash
python generar_preguntas.py      # -> preguntas_patricia.jsonl, 20 preguntas
```

Veinte preguntas de cobertura y tarifa, **sin un solo dato clínico**: ningún paciente
identificable, ningún diagnóstico. Son cortas a propósito — la hipótesis de la sección 6 es que
en preguntas de una línea Haiku empata con Opus, y para probarla hacen falta preguntas de una
línea. El archivo generado no se versiona: se regenera.
