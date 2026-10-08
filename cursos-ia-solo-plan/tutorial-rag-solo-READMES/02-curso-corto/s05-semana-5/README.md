# Semana 5 — Grounding, citas y abstención · PUNTO DE PARADA

**5.5 h totales · Objetivo: RAG funcional end-to-end**

## Resumen

Integrás la generación al pipeline. Recuperás fragmentos → construís prompt → LLM genera respuesta. Pero el detalle crucial es que el prompt tiene que exigir grounding: responder solo con lo que ve. Y si falta evidencia, tiene que abstenerse.

Al terminar esta semana tenés un RAG completo funcionando.

## Estructura de la semana

### Sesión 1 — Teoría (1.5 h)

Grounding es la instrucción crítica en el prompt: obligas al modelo a responder solo con lo recuperado. Sin grounding, responde con su conocimiento (alucina).

Citas son trazabilidad: cada afirmación → fuente. Abstención es profesionalismo: si no hay evidencia, dices "no sé" en lugar de inventar.

Los dos errores opuestos: alucinación (responder sin evidencia) y falsa abstención (rechazar cuando la evidencia existe).

### Sesión 2 — Laboratorio (1.5 h)

Tres versiones del mismo prompt:
1. Sin grounding. El modelo ve fragmentos pero ninguna regla.
2. Con grounding explícito.
3. Con grounding + citas obligatorias.

Luego el experimento decisivo: preguntá por licencia de maternidad (no en corpus) con cada variante. ¿Cuál inventa? ¿Cuál se abstiene?

### Sesión 3 — Proyecto (2.5 h)

Integrás generador. Fragmentos recuperados → prompt formateado → LLM → respuesta procesada para extraer citas.

Probás con cuatro preguntas:
1. "¿Con cuánta anticipación solicito vacaciones?" → Responde, cita
2. "¿Cuántos días remoto?" → Responde, cita
3. "¿Necesito factura para 350.000?" → Interpreta "mayor a 200.000", responde
4. "¿Licencia de maternidad?" → **Abstención verificable**

## Criterio de finalización

Las cuatro preguntas funcionan como se espera. La abstención en la cuarta **no es porque sí; es porque el prompt se lo exige al modelo**.

**PUNTO DE PARADA:** No continúes a Semana 6 si esto no funciona. No es un checkpoint: es un punto de parada. Aquí resolvés o aquí paras.

## Contenidos de cada carpeta

```
s05-semana-5/
├── sesion-01-teoria/
│   └── README.md           # Grounding, citas, abstención
├── sesion-02-laboratorio/
│   └── README.md           # Experimentos de prompt con y sin grounding
└── sesion-03-proyecto/
    └── README.md           # Integración de generación, citas, abstención
```

## Después de esta semana

Si seguís, pasás a Semana 6 con un RAG funcional. Si necesitabas solo esto, es parada legítima y completa: 5 semanas de curso, sistema operativo.
