# Arquitectura hexagonal: repaso técnico y entrevistas

Este corpus sirve para refrescar arquitectura hexagonal con criterio de producción y defender decisiones en entrevistas de Backend Senior, Tech Lead y Arquitecto. El hilo conductor es simple: distinguir política de detalle, orientar las dependencias hacia el núcleo y justificar cuándo una frontera paga su coste.

> **Vigencia:** 2026-09-28. · **Índice de arquitectura:** [`../README.md`](../README.md)

## 🧭 Recorrido recomendado

```text
fundamentos → núcleo y dominio → entradas → salidas y operación → plataformas
     │              │              │              │                    │
     └──────────────┴──────────────┴──────────────┴──── simulaciones ──┘

                              opcional: talleres (código que corre)
```

| Bloque | Decisión que entrenas | Contenido |
|---|---|---:|
| [01 · Fundamentos y modelo mental](01-fundamentos-y-modelo-mental/README.md) | reconocer política, detalle y dirección | 5 capítulos + simulación |
| [02 · Núcleo, aplicación y dominio](02-nucleo-aplicacion-y-dominio/README.md) | ubicar reglas, coordinación y consistencia | 7 capítulos + simulación |
| [03 · Adaptadores de entrada](03-adaptadores-de-entrada/README.md) | traducir drivers sin duplicar política | 5 capítulos + simulación |
| [04 · Adaptadores de salida y operación](04-adaptadores-de-salida-y-operacion/README.md) | aislar detalles y operar garantías reales | 7 capítulos + simulación |
| [05 · Plataformas y práctica](05-plataformas-y-practica/README.md) | aplicar la regla con mecanismos idiomáticos | 6 capítulos + simulación |
| [06 · Talleres](06-talleres/README.md) *(opcional)* | demostrar la frontera con código que pasa una suite | 11 talleres + solucionario |

Los bloques 01–05 son el recorrido: 30 capítulos, 5 simulaciones y 5 solucionarios, con 720 preguntas de capítulo y 150 preguntas transversales. El bloque 06 es **opcional** y no lo necesita ningún capítulo: once talleres —contrato, frontend, cinco sabores (Java, NestJS, Go, FastAPI, Laravel) y cuatro integraciones en Java (colas, Kafka, gRPC, lotes)— con 154 preguntas y 88 ejercicios en su propio solucionario.

## 🎯 Cómo estudiar

1. Lee el capítulo buscando una decisión, no una definición para memorizar.
2. Responde sus 24 preguntas sin consultar el solucionario.
3. Compara tu respuesta con las capas de 30 segundos, 2 minutos y detalle.
4. Al cerrar el bloque, haz la simulación y explica en voz alta frontera, trade-off y prioridad.
5. Vuelve al capítulo si tu respuesta depende de una anotación o herramienta sin poder explicar la regla.

Para una preparación corta, recorre primero los capítulos 01/02, 01/03, 02/02, 02/05, 04/03, 04/04, 04/06 y 05/01; después usa las cinco simulaciones como diagnóstico.

Si tienes una tarde libre y quieres pasar de explicar la frontera a verla fallar, haz el taller de contrato y el sabor de tu entrevista; el [README del bloque 06](06-talleres/README.md) propone recorridos según el perfil.

## 🧱 Sistema de ejemplo

Los capítulos siguen pedidos y pagos: `CreateOrder`, `AuthorizePayment`, reserva de inventario y notificación. HTTP, brokers, bases y frameworks aparecen como detalles conectados por adaptadores. Cuando una solución más simple basta, el texto lo dice y cuantifica la ceremonia que evita. Los talleres del bloque 06 implementan ese mismo sistema, con los mismos nombres.

## 📚 Documentos de producción

- [Guía de estilo y convenciones](prompts/guia-de-estilo-y-convenciones.md): tono, pedagogía, estructura y checklist.
- [Prompt base](prompts/prompt-base.md): inventario y contrato de contenido.

## ✅ Qué deberías poder defender al terminar

- qué cambio protege una frontera y cuánto cuesta mantenerla;
- quién define cada puerto y dónde se traduce cada contrato;
- qué es atómico, qué puede repetirse y qué queda incierto;
- qué prueba aporta evidencia en cada anillo;
- cómo migrar de forma gradual y cuándo detenerse;
- qué cambia entre Java, Node/TypeScript, Go y Python sin cambiar la regla central.

## 🔗 Relación con el resto del repositorio

La frontera con los módulos hermanos es **de altitud, no de tema**: aquí la pregunta es qué no debe
conocer el núcleo y cuánto cuesta sostener cada frontera. El único prerrequisito es `01-bases`; el
resto son sugerencias de estudio, y nada de este módulo exige haberlas leído.

- [`arquitectura/01-bases`](../01-bases/README.md) — la teoría troncal. Su capítulo
  [`03` — Arquitecturas de aplicación](../01-bases/01-bases/03-arquitecturas-de-aplicacion.md)
  compara capas, hexagonal, limpia y cebolla con su veredicto; este módulo baja a los puertos.
- [`arquitectura/02-monolito`](../02-monolito/README.md) — la unidad de despliegue que suele
  envolver al hexágono. Allí se decide qué va junto; aquí, cómo se protege por dentro.
- [`arquitectura/04-microservicios`](../04-microservicios/README.md) — los patrones entre
  servicios. Allí la estructura interna se usa
  ([`01/05`](../04-microservicios/01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md));
  aquí se justifica. Sus talleres comparten caso de estudio con los de este módulo.
- [`frameworks/01-spring-boot`](../../frameworks/01-spring-boot/) — Spring por dentro: proxies,
  scopes y transacciones; amplía lo que el bloque 05 cuenta de Spring en la medida en que afecta
  a los puertos.
- [`preguntas-entrevista/`](../../../preguntas-entrevista/) — bancos de ~100 preguntas con
  respuesta inline. Allí se repasa rápido; aquí se estudia con veredicto.
- `Entrevistas/` — material personal de búsqueda de empleo. **No se cita desde aquí**: este corpus
  está pensado para publicarse.

[Empezar por fundamentos →](01-fundamentos-y-modelo-mental/README.md)
