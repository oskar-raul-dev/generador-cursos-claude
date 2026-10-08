# `ia07` · Proyecto · Recepción asistida

Código de la sección [`ia07-recepcion-asistida.md`](../../ia07-recepcion-asistida.md).

| Archivo | Qué es |
|---|---|
| `guardrails.py` | **La capa ①**: léxico, normalización y el criterio asimétrico. De esto depende que el proyecto sea defendible |
| `outbound.py` | **La capa ③**: lo que el agente está a punto de decir |
| `conversation.py` | El hilo como máquina de estados. `ESCALATED` es terminal para el agente |
| `assistant.py` | El ensamblaje: antes del modelo, el modelo, después del modelo |
| `generar_sintomas.py` | Los cuarenta mensajes con síntoma de la medición |
| `test_guardrails.py` · `test_conversation.py` | **55 pruebas sin red y sin modelo** |

## Correr las pruebas

```bash
pytest -q      # 55 pruebas, milisegundos
```

Es la sección con más pruebas del track y no es casualidad: aquí la garantía es legal, no de
producto. Dos de ellas fijan bugs reales que aparecieron al escribir esto:

- `test_ordinary_messages_do_not_escalate` — la primera versión ponía palabras y frases en una
  sola colección construida con `.split()`, que parte `"no puedo comer"` en tres términos. Con
  `"no"` como término de síntoma, **seis de ocho mensajes corrientes escalaban**.
- `test_conjugations_are_covered` — la lista tenía `"roto"` pero no `"rompió"`, e `"inflamado"`
  pero no `"inflamó"`. Los encontró el conjunto de medición, no la revisión a ojo.

## El número que hay que tener delante

```bash
python generar_sintomas.py      # -> sintomas.jsonl, 40 mensajes: 20 con vocabulario, 20 sin
```

Sobre esos cuarenta, el guardrail léxico escala **20 de 20** de los que usan su vocabulario y
**0 de 20** de los que no. La mitad exacta se le escapa, y por eso la deuda 💸 del clasificador
está declarada y el criterio 7 del miniproyecto —el informe de señal débil— existe.

Los cuarenta los escribió el autor, así que miden lo que el autor imaginó. **Los falsos negativos
reales solo se conocen mirando el registro de producción**, y esa es la omisión declarada más
importante del track.
