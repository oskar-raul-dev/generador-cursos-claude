# 02 — Modularidad y límites internos

Este bloque convierte las capacidades de `orders`, `inventory`, `payments` y `notifications` en límites internos verificables. Conecta APIs, dependencias y propiedad de datos dentro de un despliegue común.

## 🧭 Ruta de lectura

1. [01 — Módulos alrededor de capacidades de negocio](01-modulos-alrededor-de-capacidades-de-negocio.md)
2. [02 — API pública del módulo y encapsulación interna](02-api-publica-del-modulo-y-encapsulacion-interna.md)
3. [03 — Dirección de dependencias y ciclos entre módulos](03-direccion-de-dependencias-y-ciclos-entre-modulos.md)
4. [04 — Propiedad de datos en una base compartida](04-propiedad-de-datos-en-una-base-compartida.md)
5. [05 — Comunicación interna: llamadas, comandos y eventos](05-comunicacion-interna-llamadas-comandos-y-eventos.md)
6. [06 — Código compartido, *shared kernel* y controles arquitectónicos](06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md)
7. [07 — Simulación de entrevista: Modularidad y límites internos](07-simulacion-de-entrevista.md)
8. [08 — Respuestas: Modularidad y límites internos](08-respuestas.md)

## 🎤 Cómo practicar

Lee los 6 capítulos en orden y responde sus 144 preguntas antes de consultar respuestas. La [simulación](07-simulacion-de-entrevista.md) mezcla 30 preguntas con cinco escenarios; incluye una ronda de «las que descolocan». El [solucionario](08-respuestas.md) reinicia 1–24 por capítulo y reserva S1–S30 para la simulación.

Empieza con una respuesta de 30 segundos. Amplía con evidencia, alternativa, garantía y coste; usa el detalle para discutir fallos y excepciones. Las tres capas son niveles de profundidad, no textos que debas recitar ni duraciones exactas de lectura.

## ✅ Qué debes poder defender

Diseñar una API de módulo; asignar propietario de escritura; escoger comunicación local; justificar shared kernel, excepciones y controles verificables. Aplícalo a un cambio o incidente concreto: distingue lo observado de lo inferido y termina con una primera acción reversible y una condición para revisar tu decisión.

## 🔗 Continuar

[Índice general](../README.md) · [Bloque anterior: Fundamentos y modelo mental](../01-fundamentos-y-modelo-mental/README.md) · [Bloque siguiente: Datos, ejecución y operación](../03-datos-ejecucion-y-operacion/README.md)
