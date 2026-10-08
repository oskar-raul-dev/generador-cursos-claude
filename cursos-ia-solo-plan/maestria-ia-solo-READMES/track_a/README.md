# Track A — Pista Principal (Secuencial)

Eje del currículo: matemáticas aplicadas → IA simbólica → ingeniería de datos → ML estadístico → redes neuronales → subcampos (visión, NLP, RL) → sistemas de producción.

**Filosofía:** estrictamente secuencial (una sola cosa a la vez) a partir de la Fase 1. Estudia con profundidad que compone con el tiempo y no depende de qué herramienta esté de moda.

**Tiempo total:** ~30–34 meses a 6 h/semana estables | ~117–147 semanas

## Fases

| Fase | Tema | Duración | Acumulado |
|---|---|---|---|
| [00](./00-reconstrucción-activa/README.md) | Reconstrucción activa: cálculo, álgebra lineal, probabilidad | 12–14 sem | ~3 meses |
| [01](./01-ia-clásica-simbólica/README.md) | IA clásica / simbólica (GOFAI) | 11–14 sem | ~6 meses |
| [02](./02-ingeniería-de-datos/README.md) | Ingeniería de datos | 8–10 sem | ~8.5 meses |
| [03](./03-machine-learning-estadístico/README.md) | Machine Learning estadístico | 14–17 sem | ~12 meses |
| [04](./04-inferencia-causal/README.md) | Inferencia causal | 5–7 sem | ~13.5 meses |
| [05](./05-redes-neuronales-deep-learning/README.md) | Redes neuronales y Deep Learning | 14–17 sem | ~17.5 meses |
| [06](./06-visión-por-computador/README.md) | Visión por computador | 12–14 sem | ~20.5 meses |
| [07](./07-nlp-modelos-de-lenguaje/README.md) | NLP y modelos de lenguaje | 14–17 sem | ~24 meses |
| [08](./08-aprendizaje-por-refuerzo/README.md) | Aprendizaje por refuerzo (comprimida) | 6–8 sem | ~25.5 meses |
| [09](./09-sistemas-ia-producción/README.md) | Sistemas de IA en producción | 14–17 sem | ~29 meses |
| [10](./10-capstone-productizable/README.md) | Capstone productizable + portafolio | 7–12 sem | ~31–33 meses |

## Proyecto Tesis — Hilo conductor

Cada fase aporta una pieza real a un solo sistema: **plataforma de operaciones logísticas e inventario retail** (última milla + gestión de inventarios).

- **F1:** Motor de ruteo y asignación (VRP + CSP)
- **F2:** Esquema de datos, pipeline ETL, simulador de datos
- **F3:** Predicción de ETA, detección de riesgo, pronóstico de demanda
- **F4:** Validación causal de políticas
- **F5:** Mejora de ETA con red neuronal
- **F6:** Verificación de entrega (visión), OCR
- **F7:** Chatbot de soporte + clasificación de quejas (NLP)
- **F8:** Despacho dinámico (RL)
- **F9:** MLOps, monitoreo, gobernanza, agentes
- **F10:** Integración final: data lake + API + dashboard

**Ventaja:** no es un capstone inventado de golpe al final — cada componente ya fue construido, probado y entendido meses antes.

## Método

- **6 h/semana, estables:** 4–5 sesiones cortas (60–90 min) mejor que una maratón
- **Reconstrucción sin mirar (10 min) al abrir** + material nuevo + cierre reconstruyendo (20–30 min)
- **Diagnóstico de entrada por fase (obligatorio):** 3–5 preguntas; 1–2 de fases anteriores. Si fallan, el repaso se vuelve prerequisito antes de avanzar
- **Bitácora por fase:** qué costó, qué decisiones se tomaron, qué no funcionó — materia prima del case study de F10
- **Retención a largo plazo:** recuperación activa + espaciado creciente (Anki o equivalente)

## Criterios de salida por fase

No hay examen ni certificado. Avanzas cuando: *¿puedo explicar esto sin notas y reconstruir el código desde cero?* (estándar Feynman/Karpathy).
