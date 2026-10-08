# maestria-ia: Especialización Autodidacta en Inteligencia Artificial

📚 Este directorio contiene un **currículo integral de especialización en IA** de ~30–34 meses (a 6 h/semana) diseñado para ingenieros con base sólida en desarrollo de software que buscan profundidad sistemática en aprendizaje automático, sistemas de IA y paradigmas de razonamiento.

## Visión General

**maestria-ia** es un programa autodidacta estructurado en dos pistas paralelas:

- **Pista A — El eje (secuencial):** Matemáticas aplicadas → IA simbólica → ingeniería de datos → ML → deep learning → subcampos especializados (visión, NLP, RL) → sistemas en producción.
  
- **Pista B — Práctica (solo Fase 0):** Herramientas modernas (agentes de código, MCP, fine-tuning, modelos locales) que corren en paralelo con la reconstrucción matemática, cerrándose al terminar la Fase 0.

**Filosofía:** El criterio de avance no es terminar lecciones; es poder **explicar cada concepto sin notas y reescribir el código desde cero** (estándar Feynman/Karpathy). Cada fase incluye un diagnóstico de entrada (obligatorio), mini-proyectos productibles, y bitácora de aprendizaje.

## Estructura de Directorios

```
maestria-ia/
├── README.md                           # Este archivo
│
├── 📋 Documentos Maestros
├── Curriculo_Maestro_IA_VFinal.md      # Mapa completo: 11 fases, duraciones, bibliografía
├── guia-estilo-maestria-ia.md          # Estándares editoriales (tono, lenguaje, convenciones)
├── guia-aprendizaje.md                 # Método de estudio: calendario, retención, repaso espaciado
├── guia-proyecto.md                    # Proyecto tesis: especificación y entregas
├── perfil_personal_VFinal.md           # Perfil del estudiante: restricciones, base matemática
├── instrucciones_project.md            # Detalles del capstone y evaluación
│
├── 📌 track_a/                         # PISTA A: Eje secuencial (11 fases, 0–10)
│   ├── README.md
│   ├── 00-reconstrucción-activa/       # Fase 0: Cálculo, álgebra lineal, probabilidad
│   ├── 01-ia-clásica-simbólica/        # Fase 1: GOFAI, búsqueda, razonamiento
│   ├── 02-ingeniería-de-datos/         # Fase 2: Pipelines, simulador de datos
│   ├── 03-machine-learning-estadístico/# Fase 3: Distribuciones, clasificación, regresión
│   ├── 04-inferencia-causal/           # Fase 4: Causalidad, d-separación, backdoors
│   ├── 05-redes-neuronales-deep-learning/   # Fase 5: Backprop, optimización, arquitecturas
│   ├── 06-visión-por-computador/       # Fase 6: CNNs, detección, segmentación
│   ├── 07-nlp-modelos-de-lenguaje/     # Fase 7: Transformers, atención, LLMs
│   ├── 08-aprendizaje-por-refuerzo/    # Fase 8: MDPs, Q-learning, políticas
│   ├── 09-sistemas-ia-producción/      # Fase 9: MLOps, fine-tuning riguroso, gobernanza
│   └── 10-capstone-productizable/      # Fase 10: Proyecto integrador + cierre
│
├── 🛠️ track_b/                         # PISTA B: Práctica (solo Fase 0, 2 h/semana)
│   ├── README.md
│   ├── B0-agentes-de-código/           # Claude Code, Codex CLI, Qwen Code
│   ├── B1-mcp/                         # Construir un servidor MCP
│   ├── B2-modelos-locales-ollama/      # Ollama, denso vs. MoE, cuantización
│   ├── B3-fine-tuning/                 # LoRA/QLoRA en modelos de dominio específico
│   ├── B4-cierre-integrador/           # Proyecto integrador: analizador de tendencias
│   └── B5-puesta-al-día-opcional/      # Exploración de nuevas herramientas (sin costo)
```

## Documentos Clave

### Para Comenzar
- **`Curriculo_Maestro_IA_VFinal.md`** — Lea primero. Mapa completo de fases, temario, estimaciones de tiempo, bibliografía real. Define qué es cada fase y sus criterios de salida.
- **`guia-aprendizaje.md`** — Calendario semanal (2 noches + sábado), regla del "costo real del video", sistema de repaso espaciado con tarjetas.
- **`perfil_personal_VFinal.md`** — Perfil del estudiante objetivo: CS, 6 h/semana estables, base matemática universitaria.

### Para Escribir Contenido
- **`guia-estilo-maestria-ia.md`** — Estándares editoriales no negociables. Lenguaje (inglés en código, español latinoamericano en narrativa), tono, recurrencias (ejercicios, anti-patrones, veredictos honestos).

### Para Proyectos
- **`guia-proyecto.md`** — Especificación del proyecto tesis (simulador de datos operacionales en Fase 2, refinamientos en Fases posteriores, capstone en Fase 10).
- **`instrucciones_project.md`** — Entregas específicas, rúbricas de evaluación.

## Flujo de Estudio Esperado

| Mes | Fase | Tema | Pista B (si aplica) | Duración |
|---|---|---|---|---|
| 0–3 | 0 | Reconstrucción activa: matemática | **Sí** (B0–B4, ~2 h/semana) | 12–14 sem |
| 3–6 | 1 | IA clásica / GOFAI | No | 11–14 sem |
| 6–8.5 | 2 | Ingeniería de datos + simulador | No | 8–10 sem |
| 8.5–12 | 3 | Machine Learning estadístico | No | 14–17 sem |
| 12–13.5 | 4 | Inferencia causal | No | 5–7 sem |
| 13.5–17.5 | 5 | Redes neuronales y deep learning | No | 14–17 sem |
| 17.5–20.5 | 6 | Visión por computador | No | 12–14 sem |
| 20.5–24 | 7 | NLP y modelos de lenguaje | No | 14–17 sem |
| 24–25.5 | 8 | Aprendizaje por refuerzo | No | 6–8 sem |
| 25.5–29 | 9 | Sistemas de IA en producción | No | 14–17 sem |
| 29–33 | 10 | Capstone productizable + cierre | No | 7–12 sem |

**Total:** ~31–34 meses a 6 h/semana, estudiadas en sesiones de 60–90 minutos.

## Criterios de Avance

Cada fase cierra con:

1. **Diagnóstico de entrada (obligatorio)** — 3–5 preguntas, incluyendo 1–2 de fases anteriores. Si fallas el repaso, no avanzas hasta dominarlo.
2. **Fluidez conceptual** — Explains el tema sin notas. Rescribo el código desde cero.
3. **Mini-proyecto productible** — No "hola mundo"; algo con forma de aplicación real.
4. **Bitácora de fase** — Una página: qué costó, decisiones, qué no funcionó, lecciones para el siguiente ciclo.

## Estándares Editoriales

Todo el contenido sigue **`guia-estilo-maestria-ia.md`:**

- **Código en inglés** (identificadores, APIs, comentarios en bloques)
- **Narrativa en español latinoamericano neutral (tuteo)** — "tú", no "usted", "vos", ni "vosotros"
- **Tono semiformal** — Colega ingeniero a ingeniero, con precisión y sin condescendencia
- **Honesto sobre límites** — "esto cuesta la primera vez y es normal releerlo dos veces"
- **Sin promesas falsas** — Nada de "dominarás X en esta fase"
- **Por qué antes que cómo** — El contexto viene antes del código

## Estructura de una Fase (track_a o track_b)

Cada directorio de fase típicamente contiene:

```
fase-N/
├── README.md                  # Introducción, objetivos, mapa
├── 00-setup.md               # Instalación y ambiente
├── 01-nombre-leccion.md      # Lecciones numeradas
├── 02-nombre-leccion.md
├── ...
├── A1-nombre-apendice.md     # Apéndices para profundización
├── A2-nombre-apendice.md
├── INSTINTOS.md              # Insights y patrones recurrentes
└── BENCHMARKS.md             # Mediciones contra alternativas (si aplica)
```

## Recursos Computacionales

- **Fases 0–4:** Laptop estándar (NumPy, scikit-learn, DuckDB).
- **Fases 5–7:** GPU opcional. Colab gratuito cubre los mini-proyectos; Colab Pro (~USD 10/mes) durante esas fases si lo necesitas.
- **Fases 8–10:** Depende de la rama elegida post-Fase 10. No compres hardware por adelantado.

La Pista B documenta rutas para Colab gratuito y GPU modesta (Unsloth, Ollama).

## Notas Prácticas

- **Sin examen ni certificado.** La métrica es tu capacidad de explicar y reescribir, evaluada en los diagnósticos de entrada y el capstone.
- **Bitácoras obligatorias.** A ~34 meses, la memoria falla. Las bitácoras son tu materia prima para la reflexión final (Fase 10).
- **Repaso espaciado, no relectura.** Se reconstruyen conceptos activamente, no se releen apuntes. Anki o equivalente calcula el calendario de repaso.
- **Constancia > velocidad.** 6 horas semanales estables rinden más que 20 horas concentradas en un fin de semana.

## Relacionado

- **ruta-no-sql** — Cursos de dominio en modelos de acceso NoSQL (estructura similar, contenido diferente)
- **vue2-legacy-for-backend-devs** — Frontend para ingenieros backend
- **tutorial-rag** — Contenido de IA a nivel tutorial (fundacional, pre-maestría)

---

**Punto de entrada recomendado:** Lee `Curriculo_Maestro_IA_VFinal.md` para entender el mapa completo. Luego, consulta `guia-aprendizaje.md` para estructurar tu semana, y comienza en `track_a/00-reconstrucción-activa/` (con `track_b` en paralelo si lo deseas).
