# `ia03` · Tool calling y el bucle de agente

Código de la sección
[`ia03-tool-calling-y-el-bucle-de-agente.md`](../../ia03-tool-calling-y-el-bucle-de-agente.md).

| Archivo | Qué es |
|---|---|
| `agenda_client.py` | La frontera con AgendaAPI: el `Protocol`, la propuesta con vencimiento y una agenda en memoria para pruebas |
| `tools.py` | Las tres herramientas y sus descripciones. **La descripción es prompt**: se lee como código |
| `agent.py` | El bucle, a mano, sesenta líneas |
| `agent_runner.py` | Lo mismo con `tool_runner`, para comparar (ejercicio 13) |
| `bench_agent.py` | La medición de la sección 6 |
| `test_tools.py` | Nueve pruebas **sin red y sin modelo**: `pytest test_tools.py` |

## Dependencias entre secciones

`agent.py` usa `pricing.py` de `ia01`. En tu repositorio los dos viven en el mismo paquete.

`agenda_client.py` es la parte de AgendaAPI que estas herramientas necesitan. El cliente real es
el de la Fase 13; **`hold_slot` y la tabla de propuestas con vencimiento son nuevos de esta
sección** y no estaban en el camino base.

## Los datos

```bash
python generar_solicitudes.py    # -> solicitudes_whatsapp.jsonl, 30 solicitudes
```

Con faltas, sin fecha explícita, con "el jueves" y "por la tarde". Eso no es color: es la
dificultad de la medición. Cada solicitud trae etiquetada **la clase de dificultad que aporta**
—fecha relativa, otra sede, sede sin agenda, urgencia, dos peticiones…— para poder leer los
resultados por clase en vez de en agregado.

## Por qué las pruebas no tocan el modelo

Es el criterio 7 del miniproyecto, en pequeño. La idempotencia, la carrera por el espacio de las
3:40 y el vencimiento de la propuesta son garantías del **sistema**, y se demuestran sin la API.
Si dependen de que el modelo se comporte bien, no son garantías.

`test_expired_proposal_frees_the_slot` existe por un bug real: la primera versión mezclaba
`datetime` con zona y sin zona entre `free_slots` y `hold_slot`, así que un espacio apartado
seguía apareciendo libre. Los dos son `datetime` y ningún tipo lo detecta.
