# Currículo de Especialización en Inteligencia Artificial — V_Final (autodidacta, ~30–34 meses a 6 h/semana)

> **V_Final — 2026-07-13.** Cierra la revisión de la v2. Cambios:
> 1. **Fases renumeradas a enteros (0–10).** Desaparecen las fases ".5": la antigua 1.5 (datos) es ahora la **Fase 2**, y la antigua 2.5 (causal) es la **Fase 4**. Todas las referencias cruzadas del documento están actualizadas.
> 2. **Ubicación de datos confirmada** entre GOFAI y ML: la Fase 1 trabaja sobre instancias del problema (VRP/CSP), no sobre históricos; el primer consumidor real del pipeline es el ML. Decisión cerrada.
> 3. **Simulador de datos de operación**: entregable obligatorio de la Fase 2.
> 4. **Retención a largo plazo**: diagnóstico de entrada por fase (obligatorio) + repaso espaciado (opcional). Ver esa sección.
> 5. **Calendario semanal explícito** y **regla del costo real del video** (ver "Cómo se estudian las 6 horas").
> 6. **Bitácora por fase** y **nota de presupuesto de cómputo**.
> 7. **Sin fechas de calendario.** El plan se mide en semanas y horas de trabajo real, no en meses del año — la fecha de arranque se decide al empezar.
> 8. **Track B confirmado en 3 meses**, en paralelo solo con la Fase 0. Se evaluó y **se descartó** ampliarlo a 6 meses: duplicaría el aprendizaje de datos (que ya es la Fase 2, en el mes ~8.5), retrasaría todo el eje ~6 meses, y ampliaría precisamente la única parte del plan que caduca.
>
> Base: v2 ajustada al perfil real (ver `perfil_personal.md`).

**Perfil de entrada:** Licenciado en Ciencias de la Computación, especialista en desarrollo web. Base matemática universitaria sólida (matemáticas discretas, álgebra lineal, cálculo) — la Fase 0 se ajusta a esto: es un puente aplicado, no un curso desde cero.

**Filosofía del currículo (secuencial, con un solo bloque paralelo al inicio):**
- **Pista A (el eje del plan, estrictamente secuencial):** matemáticas aplicadas → IA simbólica clásica → ingeniería de datos → ML estadístico → redes neuronales → subcampos (visión, NLP, RL) → sistemas de producción. Aquí vive la profundidad que compone con el tiempo y no depende de qué herramienta esté de moda. A partir de la Fase 1, se estudia **una sola cosa a la vez**.
- **Pista B (práctica, en paralelo *solo durante la Fase 0*):** herramientas y flujos de trabajo actuales — agentes de código (Claude Code, Codex CLI), MCP, modelos locales (Ollama), fine-tuning de modelos de dominio específico. Corre junto a la reconstrucción matemática (aprox. 4 h/semana de matemáticas + 2 h/semana de Pista B) y **se cierra al terminar la Fase 0**; después el plan es secuencial. Ponerse al día con herramientas nuevas queda como actividad opcional en las transiciones entre fases, no como pista permanente.
- Ambas convergen igual que antes: la Pista B da soltura práctica temprana; la Pista A explica *por qué* esas herramientas funcionan (o fallan) por debajo, y en la Fase 9 se retoma todo lo de la Pista B con rigor de producción.
- Cada fase tiene: objetivos, temario, bibliografía **real y verificable**, cursos en video **reales** (no bootcamps), un mini-proyecto **productizable** (no "hola mundo"), y un criterio de salida.
- No hay examen ni certificado — el criterio de avance es: *¿puedo explicar esto sin notas y reconstruir el código desde cero?* (estándar tipo Feynman / Karpathy).
- **Diagnóstico de entrada por fase (obligatorio):** cada fase abre con 3–5 preguntas, redactadas con el tutor en la primera sesión (la Fase 0 ya tiene el suyo; el patrón se replica en todas). Incluye siempre **1–2 preguntas de fases anteriores**. Si esas fallan, el repaso del tema deja de ser opcional y se hace *antes* de avanzar. Es el seguro de retención del plan.
- **Bitácora por fase:** al cerrar cada fase, una página — qué costó, qué decisiones se tomaron, qué no funcionó. A ~34 meses es imposible reconstruir esto de memoria, y es la materia prima del case study de la Fase 10.
- Ritmo real: **6 h/semana, estables todo el año**. Con eso, el plan completo toma **~30–34 meses (2.5–3 años)**. Esto no es un problema: la prioridad declarada es profundidad sin apuro, y a 6 h/semana la constancia importa mucho más que la velocidad. Las fechas de la tabla son solo para poder planear — el criterio de avance real sigue siendo la fluidez, no el calendario.
- **Regla práctica a 6 h/semana:** mejor 4-5 sesiones cortas (60-90 min) que una maratón de sábado. Con práctica espaciada, 6 horas bien repartidas rinden más que 10 concentradas.

---

## Cómo se estudian las 6 horas (calendario y método)

**Calendario semanal:**

| Cuándo | Duración | Qué |
|---|---|---|
| 2 noches entre semana | 1.5 h c/u | Abre con **10 min de reconstrucción sin mirar** de la sesión anterior, luego material nuevo. Mejor canal aquí: libro + cuaderno (tolera la interrupción). |
| Sábado en la mañana | 1.5 h + break + 1.5 h | Material nuevo. **Cierra con 20–30 min reconstruyendo el bloque 1.** Aquí va el video pesado (pausar y retroceder no funciona en fragmentos cortos). |
| Viernes alterno | ~45 min | **Tiempo extra, no cuenta contra las 6 h.** Solo tarjetas de fases pasadas, antes de la noche libre. |

Los 10 min de apertura y los 20–30 de cierre salen *de dentro* de las 6 h — no las amplían.

**Regla del mazo:** si en una reconstrucción no logras producir algo, no lo saltas — lo anotas. Esa lista de fallos **es** el mazo de tarjetas del viernes alterno. Sin ese circuito, el repaso degenera en releer apuntes bonitos.

**Regla del costo real del video (importante para planear):** la duración nominal de un video **no** es su costo. Verlo bien — pausando, retrocediendo, tomando apuntes — cuesta **2–3× la duración nominal**. Un curso de "40 horas de video" son ~100 h de trabajo real. Los "cursos de 40 h" de las plataformas suman los reproductores, no el aprendizaje. **Corolario:** ver un video sin pausar es consumo, no estudio, y no cuenta contra las 6 h. Las duraciones de las fases de este currículo ya están calculadas en **horas de trabajo real**, no en horas de video — no hay que descontarlas.

**Microjornadas (fase 2, no ahora):** una vez que el calendario anterior sea hábito (~2 meses), se pueden añadir 10–15 min de tarjetas en días muertos. No antes: lo que rompe planes de 3 años no es la falta de ambición, es la ambición sin sostenibilidad.

## Retención a largo plazo

Un plan de ~3 años tiene un enemigo que ningún criterio de salida resuelve solo: lo aprendido en el mes 3 se oxida para el mes 25 (el propio perfil de entrada es la prueba). Dos mecanismos:

1. **Diagnóstico de entrada por fase — obligatorio.** Cada fase abre con 3–5 preguntas, de las cuales 1–2 son de fases anteriores. Fallar las de repaso convierte el repaso en prerequisito para avanzar. Es el auto-corrector: si el repaso opcional no está ocurriendo, esto lo detecta antes de que el hueco crezca.
2. **Repaso espaciado — opcional, tiempo extra.** Dos ingredientes, en orden de importancia:
   - **Recuperación activa:** cierras el material y **produces** la respuesta desde cero. No la reconoces — la escribes. Si puedes ver el texto, no es repaso, es relectura (y la relectura produce una *ilusión* de fluidez, no fluidez).
   - **Espaciado creciente:** se repasa justo cuando estás a punto de olvidar. Lo que dominas vuelve en semanas; lo que fallas vuelve en días. Anki (o equivalente) calcula el calendario.
   Al cerrar cada fase se escriben 10–15 **prompts de reconstrucción** — redactados como tareas de producción, no como preguntas de opción múltiple: *"deriva backprop para una red de 2 capas ocultas"*, *"explica d-separación con un ejemplo propio"*, *"¿por qué Parquet acelera analítica y ralentiza transaccional?"*. Se rotan en el viernes alterno.

## Presupuesto de cómputo

Para que no sea sorpresa en el mes 15: las Fases 0–4 corren en cualquier laptop (NumPy, scikit-learn, DuckDB no necesitan GPU). De la Fase 5 a la 8, entrenar redes requiere GPU en algún punto. Escalera de decisión:

1. **Google Colab gratuito** cubre los mini-proyectos de las Fases 5–7 con modelos pequeños y sesiones cortas (compatible con el formato de 90 min del plan).
2. **Colab Pro (~USD 10/mes)** solo durante las fases que lo necesiten. Es la opción por defecto — se activa y desactiva según la fase.
3. **GPU propia (usada, 12–16 GB VRAM)** solo si la rama post-Fase 10 elegida lo justifica. No comprarla por adelantado: a 2+ años vista el mercado de hardware habrá cambiado.

La Pista B ya lo contempla: Unsloth y Ollama tienen rutas documentadas para Colab gratuito y para GPU modesta.

---

## Mapa general

**Pista A (el eje, secuencial). Duraciones recalculadas a 6 h/semana:**

| Fase | Tema | Duración | Horas reales | Acumulado |
|---|---|---|---|---|
| 0 | Reconstrucción activa: cálculo, álgebra lineal y probabilidad (20 años sin práctica — no es un repaso corto). **Única fase con Pista B en paralelo.** | 12–14 sem | ~72–84 h | ~3 meses |
| 1 | IA clásica / simbólica (GOFAI) | 11–14 sem | ~66–84 h | ~6 meses |
| 2 | **Ingeniería de datos** (pipeline + simulador de datos del proyecto tesis) | 8–10 sem | ~48–60 h | ~8.5 meses |
| 3 | Machine Learning estadístico | 14–17 sem | ~84–102 h | ~12 meses |
| 4 | Inferencia causal (correlación vs. causalidad) | 5–7 sem | ~30–42 h | ~13.5 meses |
| 5 | Redes neuronales y Deep Learning (fundamentos) | 14–17 sem | ~84–102 h | ~17.5 meses |
| 6 | Visión por computador | 12–14 sem | ~72–84 h | ~20.5 meses |
| 7 | NLP y modelos de lenguaje | 14–17 sem | ~84–102 h | ~24 meses |
| 8 | Aprendizaje por refuerzo **(comprimida)** | 6–8 sem | ~36–48 h | ~25.5 meses |
| 9 | Sistemas de IA en producción (MLOps, fine-tuning con rigor, agentes, gobernanza) | 14–17 sem | ~84–102 h | ~29 meses |
| 10 | Capstone productizable + portafolio + cierre | 7–12 sem | ~42–72 h | ~31–33 meses |

**Total: 117–147 semanas ≈ 27–34 meses** a 6 h/semana estables. Las horas son de **trabajo real**, no de duración nominal de videos.

**Pista B (práctica — corre en paralelo únicamente con la Fase 0, a ~2 h/semana):**

| Bloque | Tema | Intensidad |
|---|---|---|
| B0 | Agentes de código: Claude Code, Codex CLI, Qwen Code | Primer tercio de la Fase 0 |
| B1 | MCP (Model Context Protocol) — construir un servidor propio | Primer tercio de la Fase 0 |
| B2 | Modelos locales con Ollama; denso vs. MoE, cuantización | Segundo tercio de la Fase 0 |
| B3 | Fine-tuning de un modelo de dominio específico (LoRA/QLoRA) | Segunda mitad de la Fase 0 |
| B4 | Cierre integrador: analizador de tendencias/ventas | Final de la Fase 0 |
| B5 | Puesta al día opcional: probar 1 herramienta/modelo nuevo | Opcional, medio día en cada transición entre fases |

Detalle completo de la Pista B justo después de la Fase 0.

Si una fase se alarga, no se comprime la siguiente: se corre todo. Un plan de 3 años que se cumple en 3 años y medio sigue siendo un éxito; uno que se abandona en el mes 8 por ir "atrasado", no.

---

## Proyecto Tesis — el hilo conductor de toda la Pista A

Cada fase, además de su mini-proyecto propio (que existe para practicar la técnica de esa fase, ver más abajo), aporta **una pieza real a un solo sistema que crece durante los ~30-34 meses del plan**. Al llegar a la Fase 10 no armas un proyecto nuevo desde cero — integras y pules todo lo que ya construiste. Esa es la diferencia real frente al capstone "ATHENA" que descartamos: aquí cada componente ya fue construido, probado y entendido meses antes, no inventado de golpe al final.

**Dominio elegido: plataforma de operaciones logísticas e inventario retail** — última milla / delivery + gestión de inventarios de retail/supermercados, los dos dominios conductores declarados en el perfil. La razón técnica se mantiene: el ruteo de vehículos y la asignación de pedidos a repartidores *es* el problema de búsqueda y CSP de la Fase 1, el mejor escaparate posible para la IA clásica; y la cara de inventarios (pronóstico de demanda, reabastecimiento, quiebres de stock) es la capa analítica natural del mismo sistema — qué se pide, cuándo, dónde, y cuánto stock tener para responder. Los otros dos dominios de interés del perfil (trading/inversión y software legacy) no mapean bien a *todas* las fases, así que no son el hilo conductor: quedan como ramas de especialización opcionales al final del plan (ver sección de ramas).

| Fase | Aporta a la plataforma |
|---|---|
| 1 (GOFAI) | Motor de ruteo y asignación: resuelve el problema de ruteo de vehículos (VRP) con búsqueda informada/A* y CSP para asignar pedidos a repartidores respetando capacidad, horario y zona. **Primer componente real del sistema.** |
| 2 (Datos) | Esquema de datos y pipeline ETL de la plataforma; ingesta reproducible a formato columnar (Parquet + DuckDB); calidad y validación de datos; **y el simulador de datos de operación** que genera los históricos realistas que consumen todas las fases siguientes. **Es el sustrato sobre el que trabajan todas las fases siguientes**, y la semilla del data lake que la Fase 10 termina de pulir. |
| 3 (ML) | Predicción de tiempo de entrega (ETA), detección de pedidos de riesgo (dirección mal escrita, alta probabilidad de cancelación) y pronóstico de demanda por producto/zona para reabastecimiento de inventario, con modelos de gradient boosting sobre datos históricos. |
| 4 (Causal) | ¿Un cambio de política de despacho (ej. incentivo a repartidores, nueva zona) redujo de verdad las entregas tardías, o el cambio coincide con otra causa (temporada, clima)? |
| 5 (DL fundamentos) | Mejora del ETA con una red neuronal propia (embeddings de zona/dirección, features temporales), comparada rigurosamente contra el baseline de la Fase 3. |
| 6 (Visión) | Verificación de entrega por foto (paquete dañado o en el lugar correcto), lectura automática de etiquetas/direcciones (OCR). |
| 7 (NLP) | Chatbot de soporte sobre estado de pedidos con RAG sobre políticas reales, clasificación automática de quejas/reclamos. |
| 8 (RL) | Política de despacho dinámico que se adapta a tráfico/demanda en tiempo real — la aplicación de RL más fiel a como lo hacen empresas reales de delivery. |
| 9 (Producción) | Todo lo anterior con MLOps real: monitoreo de drift (¿cambió el patrón de tráfico?), agentes para manejar excepciones, gobernanza sobre las decisiones de asignación. |
| 10 (Capstone) | El data lake ya no es solo "tendencias de compra": es el sustrato completo de datos de operación (pedidos, rutas, entregas, clima, tráfico) + dashboard ejecutivo — todo integrado como producto desplegable y con potencial real de venderse como servicio (SaaS para pymes de delivery, comercios con flota propia, o cooperativas de repartidores).

**Importante para que esto no se vuelva otro ATHENA:** cada pieza se construye *solo cuando llegas a esa fase*, con el nivel de rigor que esa fase te da — no antes. Si en la Fase 5 el modelo de DL no supera al de gradient boosting de la Fase 3, esa es información real y honesta para tu documentación, no un fracaso a esconder.

---

## FASE 0 — Reconstrucción activa: cálculo, álgebra lineal y probabilidad

### Objetivos
Casi 20 años sin ejercitar cálculo, álgebra lineal ni probabilidad de forma activa borran la fluidez de producir sin ayuda, aunque los conceptos sigan siendo reconocibles. El objetivo aquí no es aprender de cero (esa base sí existe) ni un repaso de una semana — es **reconstruir fluidez mediante práctica espaciada y frecuente**. 12-14 semanas a 6 h/semana, repartidas aproximadamente en 4 h de matemáticas + 2 h de Pista B — esta es la única fase del plan donde corren dos cosas en paralelo.

### Diagnóstico rápido (ya hecho — referencia)
1. Deriva a mano el gradiente de `f(x) = ||Ax - b||²` respecto a `x`.
2. Explica qué representan los eigenvalores/eigenvectores de una matriz de covarianza y cómo se conectan con PCA.
3. Dado un dataset, plantea la función de verosimilitud (likelihood) de un modelo simple y deriva el estimador de máxima verosimilitud.
4. Aplica la regla de la cadena multivariable a una composición de 3 funciones (la esencia de backprop).
5. Explica la diferencia entre un prior, un likelihood y un posterior en el teorema de Bayes, con un ejemplo.

### Cómo practicar (esto es lo que cambia todo)
- **Sesiones cortas y frecuentes**, no maratones: 25-40 minutos, casi a diario, mejor que sesiones largas esporádicas. La práctica espaciada reconstruye fluidez oxidada mucho mejor que la concentrada.
- **Progresión gradual:** empieza en cálculo de una variable (derivadas, regla de la cadena básica) antes de saltar a multivariable; empieza en álgebra lineal con vectores/matrices concretas antes de eigendescomposición; empieza en probabilidad con distribuciones básicas antes de MLE/Bayes.
- Este chat (o el Project una vez montado) puede darte sets pequeños de ejercicios progresivos y revisar tus intentos con hints antes que soluciones — más efectivo que ver videos pasivamente para reconstruir fluidez mecánica.

### Temario
- Cálculo: derivadas de una variable → regla de la cadena → gradientes multivariable → jacobianos (la progresión completa, no solo el resultado final).
- Álgebra lineal: vectores/matrices concretas → normas y productos internos → eigenvalores/eigenvectores → SVD y su uso en PCA.
- Probabilidad y estadística: distribuciones básicas → esperanza y varianza → máxima verosimilitud (MLE) → Bayes (prior/likelihood/posterior).
- Python científico: NumPy vectorizado, Pandas, Matplotlib (probablemente esto sí lo conservas intacto por tu perfil de desarrollador — confírmalo rápido y no le dediques tiempo de más).
- **SymPy (álgebra simbólica) como verificador, no como tema.** Deriva a mano en el cuaderno, y usa SymPy para comprobar si acertaste. Es la corrección inmediata que esta fase necesita, sin salirte del ecosistema Python. **Nota:** se evaluaron Octave, SciLab y R para esta fase y **se descartaron** — ninguna fase posterior del currículo los usa, así que serían una sintaxis aprendida y nunca reutilizada. (R sí tiene un lugar legítimo, pero en la Fase 4: buena parte de la literatura y librerías de inferencia causal viven ahí. Anotado como opcional en esa fase.)

### Recursos (con énfasis en práctica, no solo teoría)
- **Eje principal — práctica graduada con corrección inmediata:** Khan Academy, cursos de Cálculo (1, 2 y multivariable) y de Estadística y Probabilidad — diseñado exactamente para reconstruir fluidez con ejercicios progresivos, no para explicar conceptos nuevos a alguien que empieza de cero.
- **Refuerzo conceptual en paralelo (no como eje):** 3Blue1Brown, *Essence of Linear Algebra* y *Essence of Calculus* (YouTube), para la intuición geométrica.
- **Si algún tema puntual necesita más profundidad:** Gilbert Strang, *18.06 Linear Algebra* (MIT OCW), solo las lectures específicas de tu punto débil — no el curso completo.
- **Probabilidad aplicada a ML:** Joe Blitzstein, *Stat 110* (Harvard, YouTube) — las lectures de Bayes y MLE, que suelen ser el hueco real viniendo de una formación de cómputo.
- **Referencia de notación ML una vez recuperada la fluidez:** capítulos 2-4 de Goodfellow, Bengio, Courville, *Deep Learning* (gratis en deeplearningbook.org) — el "traductor" de matemática pura a notación de ML, útil al final de esta fase, no al principio.

### Mini-ejercicio: "Regresión desde cero"
Implementar en NumPy puro (sin scikit-learn) regresión lineal y logística con descenso de gradiente, y validar contra `sklearn`. Hazlo al final de la fase, como cierre que conecta cálculo (gradiente), álgebra (vectorización) y probabilidad (verosimilitud) — no al principio.

### Criterio de salida
Los 5 ejercicios del diagnóstico ya no representan esfuerzo consciente — los resuelves con fluidez, no solo "reconociendo" que sabes de qué se trata. No hay prisa por cerrar esto en un número exacto de semanas; la señal es la fluidez, no el calendario.

---

## PISTA B — Práctica paralela: herramientas y productos actuales

Esta pista corre **en paralelo únicamente con la Fase 0**, a razón de ~2 h/semana durante esos ~3 meses, y **se cierra con el bloque B4 antes de arrancar la Fase 1**. A partir de ahí el plan es estrictamente secuencial; ponerse al día con herramientas nuevas queda como actividad opcional en las transiciones entre fases (B5). El objetivo no es "dominar" cada herramienta a fondo (eso cambia cada pocos meses) sino ganar soltura real y entender la arquitectura detrás de cada una — para no depender de que la moda específica siga vigente. Como no hay urgencia de portafolio (ver perfil), esta pista se toma con calma: es alfabetización práctica, no una carrera por tener algo mostrable.

### B0 — Agentes de código: Claude Code, Codex CLI y alternativas open source

**Qué son:** Claude Code es una herramienta de codificación agéntica de Anthropic que lee tu código base, edita archivos, ejecuta comandos e integra tus herramientas de desarrollo, disponible en terminal, IDE, app de escritorio y navegador. Codex CLI es el agente de codificación de OpenAI, de código abierto y escrito en Rust, con una filosofía distinta de seguridad (sandboxing a nivel de sistema operativo/kernel en vez de permisos configurables paso a paso). **Qwen Code** es el equivalente open source de Alibaba: una CLI agéntica (originalmente un fork de Gemini CLI) diseñada para los modelos Qwen3-Coder, pero que también soporta APIs de OpenAI, Anthropic y Gemini, o modelos locales vía Ollama — es decir, puedes usar el mismo flujo agéntico con distintos "cerebros".

**Qué practicar:**
- Instala Claude Code, Codex CLI y Qwen Code, y úsalos en un proyecto real tuyo (no un "hola mundo"): pídeles implementar una funcionalidad completa, corregir un bug real, o explicarte una base de código que no conoces.
- Entiende el "bucle agente": el modelo lee contexto → planea pasos → ejecuta herramientas (editar archivo, correr comando, correr tests) → verifica el resultado → repite. Es la instancia práctica de la búsqueda y planeación de la Fase 1 — vale la pena notar el paralelo cuando llegues ahí.
- Compara explícitamente los tres: modos de aprobación/permisos, cómo manejan el contexto de un repo grande, cuándo uno se equivoca y otro no, y qué diferencia hay entre depender de un modelo cerrado (Claude/GPT) vs. uno abierto (Qwen3-Coder) corriendo por API o local.
- Practica dar buenas instrucciones (context engineering): qué información necesita el agente para no alucinar sobre tu codebase.
- Opcional, para tener panorama: mira (sin necesidad de dominarlas todas) otras alternativas open source activas de la comunidad, como Aider o `opencode`, que compiten en el mismo espacio con distintas filosofías de diseño.

**Recursos:** documentación oficial en docs.claude.com/en/docs/claude-code y repositorio `anthropics/claude-code`; repositorio `openai/codex`; repositorio `QwenLM/qwen-code` en GitHub.

**Aparte — OpenClaw (exploración opcional, con cautela real):** es un agente autónomo open source distinto a los anteriores: en vez de vivir en tu terminal para programar, actúa como un asistente personal que se conecta a WhatsApp/Telegram/Discord/etc. y puede operar tu sistema de archivos, navegador, correo y calendario de forma continua, sin que apruebes cada acción. Es un buen estudio de caso de arquitectura de agentes (gateway + "skills" + bucle de herramientas), pero tiene un historial documentado de incidentes reales de seguridad: una vulnerabilidad crítica de ejecución remota de código (CVE-2026-25253), una fuga de datos en una plataforma relacionada (Moltbook) que expuso más de un millón de credenciales, y casos reportados de el agente tomando acciones sensibles (legales, financieras, de citas) sin autorización explícita del usuario. Si lo exploras, hazlo en una máquina/entorno aislado, con permisos mínimos y sin conectarlo a cuentas reales de correo, bancos o mensajería personal — el valor educativo está en entender la arquitectura y los riesgos de los agentes con acceso amplio a herramientas, no en darle uso productivo sin control.

### B1 — MCP (Model Context Protocol)

**Qué es:** un estándar abierto para conectar herramientas de IA con fuentes de datos y sistemas externos — cliente-servidor: el agente (cliente MCP) se conecta a servidores MCP que exponen herramientas o datos (un CRM, una base de datos, tu propia API). Claude Code, Codex CLI y Qwen Code lo soportan de forma nativa.

**Qué practicar (aquí es donde tu experiencia de backend se activa directamente):**
- Construye tu propio servidor MCP simple que exponga una herramienta o fuente de datos real (ej. consultar una base de datos tuya, o una API que ya hayas construido antes).
- Conéctalo a Claude Code, Codex CLI o Qwen Code y compruébalo end-to-end.
- Esto es, en esencia, diseñar una API con un contrato específico — no es contenido nuevo para un backend dev, es un formato nuevo aplicado a algo que ya sabes hacer.

### B2 — Modelos locales con Ollama y diferencias reales de implementación entre LLMs

**Qué practicar:**
- Instala Ollama y corre 2-3 modelos abiertos distintos (por ejemplo de las familias Llama, Qwen o DeepSeek) para comparar tamaño, velocidad y calidad en tu propia máquina.
- Entiende cuantización (GGUF, Q4/Q8) y el trade-off tamaño/VRAM/calidad.
- Decide con criterio propio cuándo correr local tiene sentido (privacidad, costo, latencia, sin conexión) vs. cuándo usar una API — esto es exactamente el tipo de criterio de ingeniería que diferencia a alguien que solo "usa el LLM de moda".

**Entender las diferencias de implementación (esto conecta directo con la Fase 5, y vale la pena volver aquí después de esa fase):**
- **Denso vs. Mixture-of-Experts (MoE):** un modelo denso (la mayoría de la familia Llama) activa todos sus parámetros en cada token. Un modelo MoE como Qwen3-Coder (480B parámetros totales, mas solo ~35B activos por token) o DeepSeek-V3 (671B totales, ~37B activos) tiene muchos "expertos" pero solo activa unos pocos por token vía un mecanismo de enrutamiento — mucho más barato de correr por parámetro total.
- **Mecanismos de atención distintos:** de la atención multi-cabeza (MHA) estándar, pasando por Grouped-Query Attention (GQA, la más común hoy para reducir el caché KV), hasta la innovación propia de DeepSeek, **Multi-Head Latent Attention (MLA)**, que comprime el caché KV mediante proyecciones de bajo rango, logrando varias veces menos uso de memoria con pérdida mínima de calidad.
- **Enfoques de entrenamiento distintos:** RLHF clásico (modelo de recompensa + PPO) vs. **GRPO** (Group Relative Policy Optimization, usado por DeepSeek-R1), que elimina el modelo "crítico" separado y es notablemente más barato de entrenar — parte de por qué DeepSeek pudo entrenar modelos competitivos con un presupuesto de cómputo mucho menor al reportado por los laboratorios occidentales. También existe la **destilación** (transferir capacidad de razonamiento de un modelo grande a uno denso pequeño, como los modelos "DeepSeek-R1-Distill-Qwen").
- **Licenciamiento:** Qwen y DeepSeek publican pesos abiertos bajo licencias permisivas (Apache 2.0 en la mayoría de modelos Qwen recientes, MIT en DeepSeek), lo que permite auto-hospedar y ajustar sin restricciones de uso comercial — a diferencia de modelos cerrados (Claude, GPT, Gemini) donde solo accedes vía API, o de Llama, que usa una licencia propia con algunas restricciones.

**Ejercicio concreto:** corre localmente en Ollama un modelo denso y uno MoE de tamaño comparable, mide velocidad de generación y uso de memoria, y lee (aunque sea parcialmente) el reporte técnico de DeepSeek-V3 y el blog de lanzamiento de Qwen3-Coder como fuente primaria, en vez de solo resúmenes de terceros — es la mejor forma de que esta comparación deje de ser "de oído" y se vuelva conocimiento real de arquitectura, que es justo lo que la Fase 5 te da las bases para leer con criterio.



### B3 — Fine-tuning de un modelo de dominio específico

**Qué practicar (el ejemplo que mencionas: un modelo para Java enterprise, o uno con estilo narrativo para escribir):**
1. Curar un dataset pequeño pero limpio (cientos de ejemplos, no miles) en formato instrucción-respuesta para tu dominio elegido.
2. Fine-tunear con LoRA/QLoRA usando **Unsloth** (el framework más simple para esto en una sola GPU de consumo, con exportación directa a Ollama) sobre un modelo base pequeño (7-8B).
3. Fusionar el adaptador LoRA con el modelo base, convertir a GGUF, y correrlo en Ollama.
4. Evaluar rigurosamente: métricas específicas de tu tarea antes/después del fine-tuning, y una verificación de que el modelo no perdió capacidad general (comparación en un benchmark estándar).
5. Documentar honestamente cuándo fine-tuning tuvo sentido frente a simplemente usar un prompt bien diseñado o RAG — no todo problema necesita fine-tuning.

**Nota importante:** esto es una primera pasada práctica. En la Fase 9 (Pista A) se retoma fine-tuning con más rigor teórico (por qué funciona LoRA matemáticamente, RLHF/DPO, evaluación exhaustiva) — aquí el objetivo es perder el miedo y entender el flujo completo de punta a punta.

**Recursos:** documentación de Unsloth (unsloth.ai/docs) y de Ollama (ollama.com) — ambos con guías paso a paso actualizadas y notebooks gratuitos en Google Colab si no tienes GPU propia.

### B4 — Cierre integrador: analizador de tendencias/ventas

Cierre de la Pista B (final de la Fase 0): construir algo pequeño pero real que integre las herramientas de B0-B3, con la disciplina de no caer en vibe coding ciego. No hay presión de que sea "mostrable ya" — su valor es consolidar el flujo completo de punta a punta antes de guardar la Pista B:
1. Define el problema de negocio en una frase (ej. "detectar qué categorías de producto están creciendo o cayendo mes a mes y por qué").
2. Usa Claude Code o Codex CLI para acelerar la construcción (ingesta de datos, API, visualización) — pero revisando y entendiendo cada pieza generada, no solo aceptando.
3. Decide con criterio si alguna parte se beneficia de un modelo local/fine-tuneado (ej. clasificación de texto de reseñas o descripciones de producto) o si es mejor una API.
4. Entrega algo demostrable: una API + un dashboard simple, documentado.

Este proyecto es deliberadamente una versión rápida y ligera de ideas que se retomarán con más profundidad en el capstone de la Fase 10 — la diferencia es velocidad de entrega ahora vs. rigor de producción después.

### B5 — Puesta al día opcional (en las transiciones entre fases)

**Cambio respecto al borrador original:** el "modo mantenimiento" continuo del borrador original chocaba con la preferencia por un plan secuencial y con las 6 h/semana disponibles, así que deja de ser una pista paralela permanente. En su lugar: al **cerrar cada fase** de la Pista A (un momento natural de pausa), puedes dedicar medio día — opcional, no cuenta contra las 6 h de estudio — a probar lo más nuevo: un modelo recién lanzado en Ollama, una función nueva de Claude Code/Codex, un framework de agentes. El objetivo no es dominar cada novedad, sino no perder del todo el hábito de estar al día. Si en alguna transición no hay energía para esto, se omite sin culpa: la Fase 9 retoma el estado del arte con rigor de todas formas.

---

## FASE 1 — IA clásica / simbólica (Good Old-Fashioned AI)

### Objetivos
Entender la IA *antes* del deep learning: búsqueda, lógica, sistemas basados en reglas, planeación, CSP — la base conceptual que hace que entiendas por qué el ML no es "toda la IA".

### Temario
- Agentes inteligentes, formulación de problemas como búsqueda.
- Búsqueda no informada e informada (BFS, DFS, A*, IDA*).
- Búsqueda adversarial y juegos (minimax, poda alfa-beta).
- Problemas de satisfacción de restricciones (CSP).
- Lógica proposicional y de primer orden, inferencia.
- Sistemas expertos basados en reglas (motores de inferencia forward/backward chaining).
- Representación del conocimiento y planeación automática (STRIPS).
- Introducción a razonamiento bajo incertidumbre (redes bayesianas) como puente a la Fase 3.

### Recursos
- **Curso (el que mencionas):** Patrick H. Winston, *MIT 6.034 Artificial Intelligence* (Fall 2010) — playlist completa en YouTube y en MIT OCW (ocw.mit.edu/6-034F10). Cubre exactamente búsqueda, sistemas expertos basados en reglas, lógica, aprendizaje y arquitecturas — es el curso "de 2010" que citas y sigue siendo la mejor introducción conceptual disponible gratis.
- **Curso:** Berkeley CS188, *Introduction to Artificial Intelligence* — material y proyectos de Pac-Man (excelente para practicar búsqueda/CSP/juegos con código real), sitio del curso en inst.eecs.berkeley.edu/~cs188.
- **Libro canónico:** Stuart Russell & Peter Norvig, *Artificial Intelligence: A Modern Approach*, 4ª edición (Pearson, 2020/2021) — Partes I a IV (Solución de problemas, Conocimiento y razonamiento, Incertidumbre). Este es EL libro de referencia de todo el campo.
- **Código:** repositorio oficial `aima-python` (GitHub, org `aimacode`) con implementaciones de todos los algoritmos del libro.

### Mini-proyecto: "Sistema experto real" (independiente del proyecto tesis)
Elegir un dominio real —**varía el dominio, no repitas finanzas**: diagnóstico de fallas de un equipo, triage veterinario, reglas de clasificación de residuos reciclables, o asesoría académica automatizada (qué materias puede tomar un estudiante según prerrequisitos)— y construir:
1. Un motor de reglas (forward-chaining) en Python — puedes usar la librería `experta` o escribir el motor tú mismo (recomendado para entender el mecanismo).
2. Una base de conocimiento con al menos 30-40 reglas reales, no de juguete.
3. Un componente de explicación ("por qué llegaste a esta conclusión") — esto es lo que diferencia un sistema experto real de un `if/else` gigante.

**Conexión con el proyecto tesis (obligatoria, es la pieza de esta fase):** el motor de ruteo y asignación de pedidos a repartidores de la plataforma logística — resuélvelo con búsqueda informada (A*) para las rutas y CSP para la asignación (capacidad del vehículo, horario, zona). Este es el componente donde la Fase 1 brilla más que cualquier LLM: un problema de asignación real, exacto y verificable.

### Criterio de salida
Puedes explicar quién "gana" en cada escenario: cuándo usarías un sistema basado en reglas vs. un modelo estadístico, y por qué la lógica de primer orden no escala bien a mundos abiertos.

---

## FASE 2 — Ingeniería de datos

### Objetivos
En el borrador original esto era un módulo dentro del ML; aquí es fase propia con más profundidad, por decisión del perfil. La razón de fondo: todo lo que viene después (ML, causal, DL, producción) es tan bueno como los datos que lo alimentan, y la ingeniería de datos es además una habilidad con demanda propia en la industria. Tu experiencia de backend es una ventaja directa aquí — mucho de esto es ingeniería de software aplicada a datos.

### Temario
- Modelado de datos: esquemas relacionales vs. analíticos (estrella/copo de nieve), normalización y cuándo desnormalizar.
- SQL analítico en serio: window functions, CTEs, agregaciones complejas — el SQL que un backend dev típico no ejercita.
- Formatos y almacenamiento: filas vs. columnar (Parquet), particionamiento, y por qué el formato importa para analítica.
- Pipelines ETL/ELT reproducibles: idempotencia, backfills, manejo de fallos — como código versionado, no como scripts sueltos.
- Motores analíticos ligeros: DuckDB como laboratorio local (y noción de cuándo haría falta Spark, sin profundizar aún).
- Calidad y validación de datos: tests de datos, detección de anomalías de esquema, datos faltantes/duplicados.
- Orquestación básica: qué resuelve un orquestador (Airflow o similar) y cuándo un cron honesto es suficiente.
- Arquitectura bronze/silver/gold (la que el capstone de la Fase 10 usa) — entendida ahora, no improvisada al final.

### Recursos
- **Curso (gratuito, muy práctico):** DataTalks.Club, *Data Engineering Zoomcamp* — repositorio `DataTalksClub/data-engineering-zoomcamp` en GitHub; curso comunitario real, del mismo colectivo que el MLOps Zoomcamp ya citado en la Fase 9. Úsalo como eje práctico, adaptando las piezas cloud a local si prefieres.
- **Libro (canónico, de pago — candidato fuerte de compra):** Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly) — EL libro de fundamentos de sistemas de datos; no es un tutorial, es el "por qué" detrás de cada decisión de almacenamiento y procesamiento. Aparece con frecuencia en bundles de O'Reilly de Humble Bundle.
- **Documentación oficial:** DuckDB (duckdb.org/docs) y el formato Parquet (parquet.apache.org) — suficientes y actualizadas para la parte práctica local.

### Mini-proyecto: "Pipeline de datos honesto" (independiente del proyecto tesis)
Tomar una fuente de datos pública real y desordenada — **varía el dominio**: datos abiertos de movilidad urbana, registros públicos de calidad del aire, o datasets abiertos de contratación pública — y construir:
1. Un pipeline ETL reproducible (código versionado, ejecutable de cero con un comando) que aterrice los datos crudos en capas bronze/silver/gold en Parquet.
2. Validaciones de calidad automatizadas (esquema, rangos, duplicados) que fallen ruidosamente cuando los datos vienen mal.
3. Un conjunto de consultas analíticas en DuckDB con window functions que respondan 3-4 preguntas reales sobre el dataset.
4. Documentación breve de decisiones: por qué ese particionamiento, qué se descartó y por qué.

**Conexión con el proyecto tesis (obligatoria, es la pieza de esta fase):** el esquema de datos y pipeline ETL de la plataforma logística/inventario — modelo de datos de pedidos, rutas, entregas e inventario, con ingesta reproducible a Parquet + DuckDB. Las Fases 3 en adelante entrenan sus modelos **sobre este sustrato**, y la Fase 10 lo termina de pulir como data lake completo.

**Simulador de datos de operación (entregable obligatorio de esta fase):** la plataforma logística no es una empresa real, así que sin esto cada fase improvisaría su dataset y el hilo conductor se rompería en la práctica. El simulador genera datos de operación sintéticos pero realistas — pedidos con zonas, horas pico, cancelaciones, direcciones mal escritas (tasa configurable), tiempos de entrega afectados por tráfico y clima, inventario con estacionalidad y quiebres de stock. Requisitos:

1. **Parametrizable y con semilla reproducible:** el mismo comando con la misma semilla produce el mismo dataset — condición para comparar modelos entre fases con honestidad.
2. **Anclado en realismo, no inventado:** antes de escribirlo, revisar 1–2 datasets públicos del dominio (movilidad urbana, last-mile delivery) para calibrar distribuciones plausibles, y documentar de dónde salió cada supuesto.
3. **Evoluciona con el plan:** cada fase le añade lo que necesita. La Fase 4 (causal) requiere que exista un "cambio de política" con efecto conocido; la Fase 8 (RL) construye su entorno interactivo *sobre* este simulador. Se versiona como código, igual que el pipeline.

Es, además, el mejor ejercicio de modelado de datos posible: te obliga a decidir qué entidades, atributos y relaciones tiene el dominio antes de escribir una sola consulta.

### Criterio de salida
Puedes explicar por qué un formato columnar acelera una consulta analítica y la ralentizaría como base transaccional; tu pipeline se puede borrar y reconstruir de cero con un solo comando sin intervención manual; y el simulador genera, con semilla fija, un dataset de operación que las Fases 3+ consumen sin retoques manuales.

---

## FASE 3 — Machine Learning estadístico

### Objetivos
Dominar los fundamentos de ML *antes* de tocar redes neuronales: qué es aprender de datos, sesgo/varianza, regularización, validación, y la mayoría de modelos "clásicos" que siguen siendo el default en la industria (árboles, boosting, SVM).

### Temario
- Aprendizaje supervisado: regresión, clasificación, árboles de decisión, random forests, gradient boosting (XGBoost/LightGBM).
- SVM y kernels.
- Aprendizaje no supervisado: k-means, clustering jerárquico, PCA, reducción de dimensionalidad.
- Teoría: sesgo-varianza, validación cruzada, regularización, métricas de evaluación correctas (no solo accuracy).
- Ingeniería de características y pipelines reproducibles.
- Introducción a causalidad y por qué correlación no es causalidad (importante para no hacer ML ingenuo).

### Recursos
- **Curso (rigor matemático):** Andrew Ng, *CS229: Machine Learning* (Stanford, versión con notas y derivaciones matemáticas completas) — buscar "Stanford CS229 Andrew Ng" en YouTube; notas en el sitio cs229.stanford.edu.
- **Curso (aplicado, más suave, mismo autor):** *Machine Learning Specialization* (DeepLearning.AI / Coursera) — buena base práctica, pero complementa con CS229 para no quedarte en superficie.
- **Libro (teoría accesible):** James, Witten, Hastie, Tibshirani, *An Introduction to Statistical Learning* (ISLR), 2ª edición — PDF gratuito oficial en statlearning.com.
- **Libro (teoría profunda, referencia):** Hastie, Tibshirani, Friedman, *The Elements of Statistical Learning* — PDF gratuito en el sitio de Hastie en Stanford (web.stanford.edu/~hastie/ElemStatLearn).
- **Libro (práctico/ingeniería):** Aurélien Géron, *Hands-On Machine Learning with Scikit-Learn, Keras & TensorFlow*, 3ª ed. (O'Reilly) — el mejor puente entre teoría y código de producción.

### Mini-proyecto: "Scoring productizable" (independiente del proyecto tesis)
Construir un sistema completo de scoring/predicción con un dataset real de negocio — **varía el dominio en cada fase, no vuelvas siempre a finanzas**: predicción de rendimiento/calidad de cosecha en agricultura, predicción de inasistencia a citas médicas (operación de salud, no diagnóstico clínico), predicción de deserción estudiantil, o predicción de falla de equipo (mantenimiento predictivo):
1. Pipeline de feature engineering reproducible (no notebook desordenado — usa `sklearn.Pipeline` o similar).
2. Comparación rigurosa de 3-4 modelos (regresión regularizada, random forest, gradient boosting) con validación cruzada y métricas correctas para el problema (AUC, F1, calibración, no solo accuracy).
3. Servir el modelo como API con FastAPI (aprovecha tu experiencia de desarrollo web) con logging de predicciones.
4. Documentar el "model card": supuestos, límites, datos de entrenamiento, sesgos conocidos.

**Conexión con el proyecto tesis:** predicción de tiempo de entrega (ETA) y detección de pedidos de riesgo (dirección mal escrita, alta probabilidad de cancelación) para la plataforma logística, usando los mismos pasos de arriba.

### Criterio de salida
Puedes explicar por qué un modelo con 95% de accuracy puede ser inútil, y puedes justificar matemáticamente cuándo usar L1 vs L2.

---

## FASE 4 — Inferencia causal (correlación vs. causalidad, con rigor)

### Objetivos
Esta es una pieza rescatada de un plan anterior que valía la pena conservar: casi ningún currículo de ML la incluye, y es exactamente lo que conecta con la conversación que tuvimos sobre "pañales y cerveza" — la diferencia entre encontrar una correlación y poder afirmar que una acción de negocio *causó* un resultado. Es una de las habilidades más escasas y mejor pagadas en ciencia de datos aplicada, precisamente porque casi nadie la estudia formalmente.

### Temario
- Por qué correlación no es causalidad, con rigor: paradoja de Simpson, variables confusoras (confounders).
- El marco de Judea Pearl: grafos causales dirigidos acíclicos (DAGs), d-separación, la "escalera de causalidad" (asociación → intervención → contrafactual).
- Métodos de identificación causal: diferencias en diferencias, variables instrumentales, propensity score matching.
- A/B testing con rigor estadístico real (no solo "corrí un test y gané").

### Recursos
- **Libro (gratuito, el más accesible):** Scott Cunningham, *Causal Inference: The Mixtape* — completo y gratis en mixtape.scunning.com.
- **Libro (divulgativo pero fundacional):** Judea Pearl & Dana Mackenzie, *The Book of Why* — el marco conceptual de los DAGs explicado sin necesitar matemáticas pesadas primero.
- **Librerías reales de producción:** DoWhy (Microsoft) y EconML (Microsoft Research) — ambas open source, usadas en industria, con ejemplos ejecutables.
- **R (opcional, solo aquí):** buena parte de la literatura y las librerías de inferencia causal viven en R (`dagitty`, `MatchIt`). No es obligatorio — Python cubre la fase — pero si algún método que necesitas solo existe bien en R, esta es la única fase del plan donde vale la pena el desvío.

### Mini-proyecto: "¿Esto realmente funcionó?" (independiente del proyecto tesis)
Con un dataset real o simulado con realismo —**varía el dominio**: ¿una intervención de salud pública redujo contagios?, ¿un cambio de metodología mejoró notas de estudiantes?, ¿un programa de reforestación tuvo efecto medible?— responde con rigor causal, no con una correlación disfrazada:
1. Plantea el DAG del problema: qué variables confunden la relación entre la acción y el resultado.
2. Aplica al menos un método de identificación (diferencias en diferencias o propensity score matching) con DoWhy o EconML.
3. Compara explícitamente el resultado con lo que diría un análisis ingenuo de correlación — este contraste es el corazón del proyecto.
4. Documenta los supuestos que tu método asume y qué pasa si no se cumplen (esto es lo que un analista junior nunca hace, y lo que te diferencia).

**Conexión con el proyecto tesis:** ¿un cambio de política de despacho (incentivo a repartidores, nueva zona de cobertura) redujo de verdad las entregas tardías de la plataforma logística, o coincide con otra causa (temporada, clima)? Mismos 4 pasos, aplicados a tu propio sistema. **Ventaja del simulador:** como tú controlas el generador de datos, puedes inyectar un efecto causal de magnitud conocida (ej. "el incentivo reduce las entregas tardías en 8%"), aplicar luego el método *fingiendo que no lo sabes*, y verificar si lo recuperas. Con datos reales esto es imposible — nunca conoces la verdad, así que nunca sabes si aplicaste bien la técnica o te engañaste. El simulador te da un examen con solucionario.

### Criterio de salida
Puedes explicar con un ejemplo propio la diferencia entre P(Y|X) y P(Y|do(X)), y por qué esa diferencia es la que separa un analista de datos de alguien que realmente informa decisiones de negocio.

---

## FASE 5 — Redes neuronales y Deep Learning (fundamentos)

### Objetivos
Entender una red neuronal desde el álgebra hasta el código — no como "caja negra de Keras", sino sabiendo exactamente qué hace cada línea de backpropagation.

### Temario
- Perceptrón, MLP, funciones de activación.
- Backpropagation derivado matemáticamente y luego implementado a mano.
- Descenso de gradiente estocástico, momentum, Adam.
- Regularización en redes: dropout, batch norm, weight decay.
- Introducción a arquitecturas: CNN (idea general), RNN/LSTM (idea general), Transformers (idea general) — el detalle profundo viene en las Fases 6 y 7.
- Autograd: cómo un framework calcula gradientes automáticamente.

### Recursos
- **Curso (el más real y honesto que existe):** Andrej Karpathy, *Neural Networks: Zero to Hero* (YouTube, canal propio de Karpathy) — construye backpropagation, un micro-autograd (`micrograd`) y un GPT desde cero, literalmente carácter por carácter. Es el antídoto perfecto contra el "vibe coding".
- **Curso:** MIT 6.S191, *Introduction to Deep Learning* — se actualiza cada año, disponible en YouTube (canal "Alexander Amini") y en introtodeeplearning.com.
- **Libro canónico:** Goodfellow, Bengio, Courville, *Deep Learning* — texto completo gratuito en deeplearningbook.org.
- **Video de intuición:** 3Blue1Brown, serie *Neural Networks* (4 videos) — para visualizar backprop antes de programarlo.

### Mini-proyecto: "Autograd + clasificador real" (independiente del proyecto tesis)
1. Implementar tu propio motor de autograd minimalista (siguiendo/estudiando `micrograd` de Karpathy, pero escribiendo tu propia versión, no copiando).
2. Construir un MLP con ese motor y entrenarlo en un dataset real de clasificación — **varía el dominio**: clasificación de especies en imágenes de biodiversidad, clasificación de géneros musicales por características de audio, o clasificación de documentos administrativos.
3. Migrar el mismo modelo a PyTorch y verificar que los resultados coincidan — esto demuestra que entiendes lo que el framework hace por ti.

**Conexión con el proyecto tesis:** mejora del ETA de entrega con una red neuronal propia (embeddings de zona/dirección, features temporales), comparada rigurosamente contra el baseline de gradient boosting de la Fase 3.

### Criterio de salida
Puedes explicar y programar backpropagation sin mirar apuntes, para una red de al menos 2 capas ocultas.

---

## FASE 6 — Visión por computador

### Objetivos
Entender CNNs y arquitecturas modernas de visión, y ser capaz de construir un sistema de visión de punta a punta (dato → modelo → producto).

### Temario
- Convoluciones, pooling, arquitecturas clásicas (LeNet, AlexNet, VGG, ResNet).
- Transfer learning y fine-tuning.
- Detección de objetos y segmentación (arquitecturas tipo YOLO / detección en dos etapas).
- Redes generativas (idea general de GANs y modelos de difusión).
- Métricas de evaluación en visión (mAP, IoU) y curación de datasets de imágenes.

### Recursos
- **Curso canónico:** Stanford CS231n, *Convolutional Neural Networks for Visual Recognition* — notas del curso en cs231n.github.io, sitio oficial cs231n.stanford.edu, y grabaciones completas en YouTube (la versión 2017, impartida por Karpathy y Fei-Fei Li, es la más citada; también existen ediciones más recientes, hasta 2025).
- **Libro canónico:** Richard Szeliski, *Computer Vision: Algorithms and Applications*, 2ª edición — PDF gratuito en el sitio del autor (szeliski.org/Book).

### Mini-proyecto: "Sistema de detección real" (independiente del proyecto tesis)
Construir un sistema de detección/conteo aplicado a un caso concreto y productizable — **varía el dominio**:
- Detección de plagas o estado de madurez en cultivos (agro, muy relevante en Colombia).
- Inspección de calidad (defectos en piezas/empaques de manufactura).
- Conteo de vehículos/personas en un video de tráfico urbano.

Pasos: recolectar o usar un dataset real, etiquetar una porción tú mismo (para entender el costo real de esto), fine-tunear una arquitectura pre-entrenada, medir mAP/IoU, y desplegar como servicio con una API que reciba imágenes y devuelva detecciones.

**Conexión con el proyecto tesis:** verificación de entrega por foto (paquete dañado o en el lugar correcto) y lectura automática de etiquetas/direcciones (OCR) para la plataforma logística.

### Criterio de salida
Puedes explicar por qué una convolución tiene menos parámetros que una capa densa equivalente y qué es el "receptive field".

---

## FASE 7 — NLP y modelos de lenguaje

### Objetivos
Entender NLP desde embeddings hasta Transformers y LLMs modernos — la teoría detrás de lo que hoy se usa como "vibe coding", para que puedas construir, evaluar y depurar sistemas de NLP en serio, no solo llamar una API.

### Temario
- Representación de texto: bag-of-words, TF-IDF, embeddings (Word2Vec, GloVe).
- Redes recurrentes, LSTM, atención.
- Arquitectura Transformer (el paper "Attention Is All You Need", leído y entendido línea por línea).
- Modelos preentrenados: BERT (encoder), GPT (decoder), diferencias y usos.
- Fine-tuning vs. prompting vs. RAG — cuándo usar cada uno y por qué (con criterio de ingeniería, no de moda).
- Evaluación rigurosa de sistemas de NLP/LLMs (no solo "se ve bien").

### Recursos
- **Curso canónico:** Stanford CS224N, *Natural Language Processing with Deep Learning* (Christopher Manning) — grabaciones completas y gratuitas en YouTube (hay varias ediciones actualizadas, la más reciente pública es 2024), notas en web.stanford.edu/class/cs224n.
- **Papers seminales (léelos con calma, con anotaciones propias):** "Attention Is All You Need" (Vaswani et al., 2017), "BERT: Pre-training of Deep Bidirectional Transformers" (Devlin et al., 2018).
- **Libro:** Dan Jurafsky & James H. Martin, *Speech and Language Processing*, 3ª edición (borrador en línea, gratuito, en el sitio de Jurafsky en Stanford).
- **Curso complementario:** Andrej Karpathy, *"Let's build GPT from scratch"* (parte de la serie Zero to Hero) — construir un GPT pequeño carácter por carácter conecta directamente la Fase 5 con esta.

### Mini-proyecto: "Pipeline de NLP productizable" (independiente del proyecto tesis)
Elegir un caso de uso real de extracción/clasificación de información no trivial — **varía el dominio**: extracción estructurada de historias clínicas veterinarias, un asistente RAG de extensión agrícola (preguntas sobre manejo de cultivos con respuestas ancladas a guías reales), o clasificación de solicitudes ciudadanas a una entidad pública:
1. Extracción estructurada de la fuente de datos elegida.
2. Construir un sistema RAG *evaluado rigurosamente* (con métricas de recuperación y de generación, no solo "parece que responde bien") sobre un corpus propio.
3. Comparar un enfoque clásico (TF-IDF + reglas), uno con embeddings + modelo fine-tuneado pequeño, y uno con un LLM vía API — y documentar honestamente costos, latencia y calidad de cada uno.

**Conexión con el proyecto tesis:** chatbot de soporte al cliente sobre estado de pedidos con RAG sobre políticas reales de la plataforma logística, más clasificación automática de quejas/reclamos.

### Criterio de salida
Puedes explicar mecanismo de atención (Q, K, V) matemáticamente y programar una capa de self-attention desde cero.

---

## FASE 8 — Aprendizaje por refuerzo (comprimida — 6–8 semanas)

> **Decisión de la V_Final:** esta fase se recorta de 10–12 a **6–8 semanas**. Razón honesta: es la fase con peor relación esfuerzo/retorno del plan — RL es la rama de la IA con menos aplicación fuera de laboratorios y unas pocas empresas grandes. Pero **no se elimina**: es una de las tres grandes ramas conceptuales de la IA, y el despacho dinámico es una pieza real del proyecto tesis. Lo que se recorta es la profundidad de implementación, **no la comprensión conceptual**. El contenido restante se mueve al **módulo opcional MO-1** (ver banco de módulos opcionales al final).

### Objetivos
Entender la tercera gran rama de la IA (junto a simbólica y estadística/deep learning): agentes que aprenden por interacción con un entorno. **Objetivo calibrado a 6–8 semanas: comprensión teórica sólida + una implementación tabular funcionando.** Basta para leer papers de RL con criterio, para saber cuándo RL es (y no es) la herramienta correcta, y para construir el despacho dinámico del proyecto tesis. No basta para ser practicante de deep RL — y eso es deliberado.

### Temario (núcleo comprimido)
- Procesos de decisión de Markov (MDP) — el marco formal. **No se recorta: es la base de todo.**
- Programación dinámica, Monte Carlo, diferencias temporales (TD).
- Q-learning y SARSA, **implementados de forma tabular** (no con redes).
- Exploración vs. explotación (ε-greedy, y por qué el problema es difícil).
- Valor vs. política: la distinción conceptual, y policy gradient **como idea**, sin derivación completa.
- Por qué RL es difícil de aplicar de forma segura en el mundo real (sample efficiency, reward hacking, sim-to-real).

**Movido al módulo opcional MO-1:** Deep Q-Networks (DQN) con implementación completa, policy gradient derivado (REINFORCE, actor-critic), PPO, y el tuning serio de agentes profundos.

### Recursos
- **Libro canónico:** Richard S. Sutton & Andrew G. Barto, *Reinforcement Learning: An Introduction*, 2ª edición — PDF gratuito y oficial de los autores en incompleteideas.net/book/the-book-2nd.html. **Alcance comprimido: capítulos 3–6** (MDPs, programación dinámica, Monte Carlo, TD). El resto queda para MO-1.
- **Curso canónico:** David Silver (DeepMind/UCL), *Reinforcement Learning Course* — grabaciones completas en YouTube. **Alcance comprimido: lectures 1–5.**

### Mini-proyecto: "Agente de decisión tabular" (independiente del proyecto tesis)
Resolver un problema de decisión secuencial con **Q-learning tabular**, no con redes — **varía el dominio**: gestión de inventario de un solo producto con demanda estocástica, asignación de riego en un cultivo simulado, o un entorno sencillo de Gymnasium. El énfasis está en que puedas **explicar y programar la actualización de Q desde cero**, no en obtener el mejor score. Documenta el proceso de exploración/explotación y qué pasa cuando cambias ε.

**Conexión con el proyecto tesis:** política de despacho dinámico que adapta rutas/asignaciones de la plataforma logística a tráfico y demanda en tiempo real — la aplicación de RL más fiel a cómo lo hacen empresas reales de delivery.

### Criterio de salida
Puedes explicar la diferencia entre métodos basados en valor y basados en política, y por qué RL es difícil de aplicar de forma segura en el mundo real.

---

## FASE 9 — Sistemas de IA en producción (MLOps, LLMs de verdad, agentes)

### Objetivos
Aquí es donde por fin entran los LLMs modernos y los agentes — pero con la base de las 6 fases anteriores, entendiendo arquitectura, límites, costos, evaluación y despliegue, no solo "prompt engineering de moda".

### Temario
- Ciclo de vida de un sistema de ML en producción: versionado de datos/modelos, monitoreo, drift.
- Fine-tuning eficiente (LoRA/QLoRA), cuantización, inferencia eficiente.
- Arquitecturas de agentes (planeación, uso de herramientas, memoria) — con ojo crítico sobre qué es marketing y qué es ingeniería real.
- Evaluación de sistemas basados en LLM (benchmarks, evaluación humana, evaluación automática con límites conocidos).
- Consideraciones de seguridad, sesgo e interpretabilidad.
- **Gobernanza y cumplimiento (rescatado de un plan anterior, con alcance realista):** qué exige en la práctica la Ley de IA de la UE para sistemas de "alto riesgo" (la misma que mencionamos al hablar de sistemas expertos y explicabilidad), y por qué la auditabilidad determinista sigue ganando terreno frente a la caja negra pura. No hace falta estudiar cada marco regulatorio de memoria — el objetivo es poder leer un requisito de cumplimiento y saber qué pieza técnica lo satisface (logging, model card, motor de reglas de gobernanza, explicabilidad tipo SHAP).
- **Hardware, en la medida justa:** ya tienes práctica con cuantización desde Ollama en la Pista B — aquí se profundiza en por qué funciona (precisión int8/int4, trade-off tamaño-calidad) y en el panorama general GPU vs. TPU, sin necesidad de volverte experto en arquitectura de chips.

### Recursos
- **Curso:** *Full Stack Deep Learning* (fullstackdeeplearning.com) — curso gratuito centrado en llevar modelos a producción, muy honesto sobre lo que realmente cuesta operar IA.
- **Curso:** fast.ai, *Practical Deep Learning for Coders* (Jeremy Howard, course.fast.ai) — buen complemento aplicado, con enfoque "top-down" que contrasta bien con el enfoque "bottom-up" del resto del currículo.
- **Curso (gratuito, muy práctico):** DataTalks.Club, *MLOps Zoomcamp* — repositorio en GitHub (`DataTalksClub/mlops-zoomcamp`), un curso comunitario real y bien valorado, con proyecto final incluido.
- **Libro:** Chip Huyen, *Designing Machine Learning Systems* (O'Reilly) — referencia moderna de MLOps.
- **Libro (interpretabilidad, gratuito):** Christoph Molnar, *Interpretable Machine Learning* — disponible en línea en christophm.github.io/interpretable-ml-book.
- **Libro (impacto social de algoritmos, divulgativo):** Cathy O'Neil, *Weapons of Math Destruction* — buen contrapeso humano a todo el rigor técnico de las fases anteriores.

### Mini-proyecto: productizar el proyecto tesis (independiente ya no aplica — aquí convergen todas las piezas)
Toma todos los componentes que ya construiste para la plataforma logística (Fases 1 a 8) y dales tratamiento de producción real: versionado de modelos, monitoreo de drift (¿cambió el patrón de tráfico o demanda?), agentes para manejar excepciones (ej. una entrega fallida), y una capa de gobernanza sobre las decisiones de asignación (auditar por qué el sistema asignó un pedido a tal repartidor).

### Criterio de salida
Puedes diseñar (en un documento técnico) la arquitectura completa de un sistema de IA productivo: ingesta, features, entrenamiento, servido, monitoreo — y justificar cada decisión.

---

## FASE 10 — Capstone productizable + portafolio

### El capstone es la integración final del proyecto tesis

A diferencia de un capstone tradicional que arranca de cero, aquí no construyes nada nuevo: **pules e integras** la plataforma logística que vienes construyendo desde la Fase 1. Tu idea original (data lake de tendencias de compra) queda como la capa analítica de esta misma plataforma, no como un proyecto aparte:

1. **Ingesta y data lake:** pipeline de ingestión de datos de operación (pedidos, rutas, entregas, inventario, clima, tráfico — reales o simulados con realismo) hacia un data lake con estructura bronze/silver/gold en Parquet + DuckDB (o Spark si quieres más músculo). **Nada de esto se improvisa aquí:** el esquema y el pipeline base vienen de la Fase 2 — en el capstone se extienden y pulen, no se inventan.
2. **Feature store / capa analítica:** aquí vive tu idea de tendencias de demanda — series de tiempo por zona/categoría, estacionalidad, elasticidad simple.
3. **Integración de todos los componentes:** motor de ruteo (Fase 1) + ETA y scoring de riesgo (Fase 3/5) + validación causal de políticas (Fase 4) + verificación visual (Fase 6) + soporte conversacional (Fase 7) + despacho dinámico (Fase 8) + gobernanza y monitoreo (Fase 9), todo sirviendo del mismo data lake.
4. **Servido y producto:** API + dashboard (backend con FastAPI, frontend con lo que domines) que muestre operación, tendencias y predicciones a un "cliente" ficticio o real (una pyme de delivery, un comercio con flota propia).
5. **Documentación tipo "case study"** para portafolio: problema de negocio, arquitectura, decisiones, resultados, limitaciones — este documento es lo que enseñas en una entrevista o a un cliente, y el que de verdad demuestra más de dos años de trabajo acumulado, no una demo de un fin de semana.

### Portafolio final
El portafolio tiene dos capas: (a) los mini-proyectos independientes de cada fase, variados en dominio (sistema experto, pipeline de datos, scoring, causal, visión, NLP, RL) — muestran que dominas cada técnica por separado; y (b) la plataforma logística integrada — muestra que sabes construir un sistema real y coherente, no solo ejercicios aislados. Esa combinación es más creíble frente a un empleador o cliente que cualquier certificado de bootcamp, y bastante más honesta que un mega-proyecto inventado de golpe al final.

### Nota sobre el proyecto "ATHENA" de tu plan anterior
El plan que rescataste tenía un capstone final ("ATHENA") con 5-8 componentes (recomendador, chatbot, forecasting, generación de contenido, atribución causal, pricing con RL, panel ejecutivo) construidos todos de golpe en 3-4 semanas, con cifras de negocio del tipo "$450M ARR", "camino a IPO" o "próximo unicornio". Vale la pena ser honesto sobre esto: esas cifras no están sustentadas en nada verificable — leen como relleno generado por IA sin números reales detrás, no como análisis de negocio. Si las llevas a una entrevista o a un inversor real, el efecto es el opuesto al buscado: una persona con criterio las identifica de inmediato como no creíbles.

Lo que sí rescatamos de la idea es el alcance técnico de integrar varios componentes en un solo sistema — pero construido pieza por pieza durante más de dos años, con cada componente ya probado y entendido, es exactamente lo que el proyecto tesis de este currículo hace bien y ATHENA hacía mal.

**Regla práctica para enmarcar el potencial de negocio de cualquier mini-proyecto (úsala en vez de inventar cifras):**
1. Nombra el problema real en una frase, sin jerga.
2. Si citas un tamaño de mercado o una cifra de precio, que sea de una fuente real y verificable (o simplemente omítela) — no completes con un número que "suena bien".
3. Describe qué harías distinto a una solución existente, en términos técnicos concretos, no en adjetivos ("revolucionario", "líder").
4. Cierra con métricas que tú mismo puedes medir en tu propio proyecto (precisión, latencia, costo de inferencia) — no con proyecciones de ingresos a 5 años que nadie puede verificar.

---

## Bibliografía consolidada (núcleo canónico)

Marcada según el presupuesto del perfil (mayormente gratis, compras puntuales): **[GRATIS]** = legal y gratuito directamente de los autores/editores; **[PAGO]** = requiere compra.

1. Stuart Russell & Peter Norvig — *Artificial Intelligence: A Modern Approach*, 4ª ed. (Pearson). **[PAGO]**
2. Ian Goodfellow, Yoshua Bengio, Aaron Courville — *Deep Learning* (MIT Press; gratis en deeplearningbook.org). **[GRATIS]**
3. Richard S. Sutton & Andrew G. Barto — *Reinforcement Learning: An Introduction*, 2ª ed. (MIT Press; gratis en incompleteideas.net). **[GRATIS]**
4. Trevor Hastie, Robert Tibshirani, Jerome Friedman — *The Elements of Statistical Learning* (Springer; gratis en el sitio de Hastie). **[GRATIS]**
5. Gareth James et al. — *An Introduction to Statistical Learning* (Springer; gratis en statlearning.com). **[GRATIS]**
6. Richard Szeliski — *Computer Vision: Algorithms and Applications*, 2ª ed. (Springer; gratis en szeliski.org). **[GRATIS]**
7. Dan Jurafsky & James H. Martin — *Speech and Language Processing*, 3ª ed. (borrador gratuito en línea). **[GRATIS]**
8. Aurélien Géron — *Hands-On Machine Learning with Scikit-Learn, Keras & TensorFlow*, 3ª ed. (O'Reilly). **[PAGO]**
9. Chip Huyen — *Designing Machine Learning Systems* (O'Reilly). **[PAGO]**
10. Christoph Molnar — *Interpretable Machine Learning* (gratis en línea). **[GRATIS]**
11. Marc Peter Deisenroth, A. Aldo Faisal, Cheng Soon Ong — *Mathematics for Machine Learning* (Cambridge University Press; gratis en mml-book.com) — el "traductor" matemático completo, útil como referencia durante toda la Pista A. **[GRATIS]**
12. Scott Cunningham — *Causal Inference: The Mixtape* (gratis en mixtape.scunning.com). **[GRATIS]**
13. Judea Pearl & Dana Mackenzie — *The Book of Why* (Basic Books) — divulgativo, buena puerta de entrada conceptual a los DAGs causales. **[PAGO]**
14. Cathy O'Neil — *Weapons of Math Destruction* (Crown) — divulgativo, sobre el impacto social de los algoritmos. **[PAGO]**
15. Martin Kleppmann — *Designing Data-Intensive Applications* (O'Reilly) — añadido por la Fase 2 de ingeniería de datos. **[PAGO]**

**Guía de compras (según el perfil):** el núcleo del currículo es cubrible casi por completo con los recursos [GRATIS], que son ediciones oficiales de los propios autores — no hace falta recurrir a copias de origen dudoso. Si vas a comprar pocos títulos, el orden de prioridad sugerido es: **(1) Géron** (Fase 3 — el puente práctico que más horas de uso tendrá), **(2) Kleppmann** (Fase 2), **(3) Chip Huyen** (Fase 9 — hay tiempo de sobra para conseguirlo). Los tres son de O'Reilly y aparecen periódicamente en bundles de programación/data de **Humble Bundle** a precios muy bajos — vale la pena vigilar esos bundles con anticipación, dado que el plan es largo. AIMA (Russell & Norvig) es caro; para las Fases 1 y 3 se puede avanzar con los cursos MIT 6.034/CS188 + el repositorio `aima-python`, y decidir la compra solo si lo extrañas como referencia. *The Book of Why* y *Weapons of Math Destruction* son divulgativos: bibliotecas públicas o ediciones de segunda mano son opciones perfectamente válidas.

## Recursos de la Pista Práctica (cambian rápido — usa siempre la documentación oficial, no tutoriales viejos)

1. Documentación oficial de Claude Code — docs.claude.com/en/docs/claude-code (y repositorio `anthropics/claude-code` en GitHub).
2. Documentación oficial de Codex CLI — repositorio `openai/codex` en GitHub.
3. Qwen Code — repositorio `QwenLM/qwen-code` en GitHub; blog de Qwen (qwen.ai/blog) para los lanzamientos de Qwen3-Coder.
4. DeepSeek — reportes técnicos oficiales de DeepSeek-V3 y DeepSeek-R1 (arxiv.org, buscar "DeepSeek-V3 Technical Report" y "DeepSeek-R1"), la fuente primaria para entender MoE, MLA y GRPO en detalle.
5. Especificación y documentación de MCP (Model Context Protocol) — modelcontextprotocol.io.
6. Ollama — documentación y catálogo de modelos en ollama.com.
7. Unsloth — guías de fine-tuning con LoRA/QLoRA en unsloth.ai/docs.
8. Hugging Face — documentación de `transformers`, `peft` y `trl` (el stack estándar de fine-tuning, más portable que Unsloth aunque más verboso).

## Cursos en video (núcleo canónico, todos reales, la mayoría gratuitos)

1. MIT 6.034 — *Artificial Intelligence* (Patrick Winston, 2010).
2. Berkeley CS188 — *Introduction to Artificial Intelligence*.
3. Stanford CS229 — *Machine Learning* (Andrew Ng).
4. MIT 6.S191 — *Introduction to Deep Learning*.
5. Stanford CS231n — *CNNs for Visual Recognition*.
6. Stanford CS224N — *NLP with Deep Learning* (Christopher Manning).
7. David Silver / UCL/DeepMind — *Reinforcement Learning Course*.
8. Andrej Karpathy — *Neural Networks: Zero to Hero*.
9. Gilbert Strang — *18.06 Linear Algebra* (MIT).
10. Joe Blitzstein — *Stat 110: Probability* (Harvard).
11. fast.ai — *Practical Deep Learning for Coders*.
12. Full Stack Deep Learning.

## Lo que este currículo deliberadamente NO es
No es un curso de "usa el LLM de moda para generar código sin entenderlo". La Pista B te pone a usar Claude Code, Codex, MCP, Ollama y fine-tuning desde la semana 1 — pero siempre con la disciplina de entender qué hace cada pieza, evaluar resultados, y documentar por qué elegiste una herramienta y no otra. La diferencia entre esto y "vibe coding" no es *cuándo* tocas las herramientas modernas, sino *cómo*: con criterio, evaluación y la profundidad que la Pista A va construyendo en paralelo. En la Fase 9 se retoma todo lo de la Pista B con rigor de producción — evaluación exhaustiva, por qué funciona LoRA matemáticamente, arquitecturas de agentes más allá de "usar la herramienta".

## Banco de módulos opcionales (MO)

Contenido que se **sacó deliberadamente del eje** por ser marginal, muy específico, o de baja relación esfuerzo/retorno. No está eliminado: está aparcado. Cada módulo se puede tomar en una transición entre fases, después de la Fase 10, o nunca — la decisión es tuya en el momento, con información que hoy no tienes.

**Regla de oro:** un módulo opcional **nunca** se toma en paralelo con una fase del eje. Se toma entre fases, o no se toma. Las 6 h/semana no se parten.

| ID | Módulo | De dónde salió | Cuándo tendría sentido |
|---|---|---|---|
| **MO-1** | **Deep RL completo** — DQN implementado, policy gradient derivado (REINFORCE, actor-critic), PPO, tuning serio de agentes profundos | Recorte de la Fase 8 | Solo si el despacho dinámico del proyecto tesis lo pide de verdad, o si te interesa investigación en RL |
| **MO-2** | **Spark y big data distribuido** | Mencionado sin profundizar en la Fase 2 | Solo si trabajas con datos que DuckDB no aguante. A 6 h/semana y con datos simulados, casi seguro que no |
| **MO-3** | **Modelos generativos de imagen** — GANs y difusión con profundidad | Idea general en la Fase 6 | Si la rama de visión te atrapa. No aporta nada al proyecto tesis |
| **MO-4** | **Arquitectura de hardware para IA** — GPU vs. TPU, kernels, precisión numérica a fondo | Tocado "en la medida justa" en la Fase 9 | Solo si acabas en infraestructura de ML |
| **MO-5** | **Orquestación de producción** — Kubernetes, Airflow/Kubeflow, observabilidad | Mencionado en la Fase 9 y en las ramas | Si la rama MLOps es la que eliges al final |

**Cómo se añade un módulo a este banco:** cuando en una fase aparezca un tema que sea (a) interesante, (b) no necesario para el eje ni para el proyecto tesis, y (c) tentador — se anota aquí en vez de estudiarlo. Es el mecanismo de defensa contra la dispersión: no se dice "no", se dice "después", y eso baja la ansiedad de dejarlo pasar.

---

## Ramas de especialización opcional (después de la Fase 10)

Idea rescatada de tu plan anterior, simplificada: una vez cerrado el currículo completo, en vez de "seguir aprendiendo todo" sin foco, elige una rama para profundizar 2-3 meses más según hacia dónde quieras llevar tu carrera:

- **Visión por computador aplicada:** revisitar la Fase 6 con un proyecto de producción real (detección en tiempo real, edge deployment).
- **NLP / IA generativa:** revisitar Fases 7 y 9 con fine-tuning más ambicioso y arquitecturas multimodales (visión + lenguaje).
- **MLOps / Ingeniería de plataforma de IA:** profundizar Fase 9 con Kubernetes, orquestación (Airflow/Kubeflow) y observabilidad a nivel de producción real.
- **Investigación:** énfasis en leer y reproducir papers (empezando por los ya citados: Transformer, DeepSeek-V3, AlphaZero) en vez de solo construir productos.
- **Producto/estrategia de IA:** si tu interés vira más hacia gestión que a código, complementa con causalidad (Fase 4) y gobernanza (Fase 9) más a fondo, y menos tiempo en Fases 6/8.
- **IA aplicada a inversión/trading (dominio de interés declarado en el perfil):** combina series de tiempo (Fase 3), causalidad (Fase 4 — separar señal de coincidencia es *el* problema del dominio) y RL (Fase 8), aplicados a datos de mercado. Se deja como rama y no como hilo conductor por dos razones: no mapea bien a las fases de visión/NLP/GOFAI, y es un dominio donde el sobreajuste y las conclusiones espurias son la norma — conviene llegar con toda la caja de herramientas estadística y causal ya consolidada, no aprenderla sobre este terreno. La misma regla del currículo aplica reforzada: métricas medibles y honestas (backtests con sus limitaciones documentadas), nunca promesas de retorno.
- **IA para software legacy (dominio de interés declarado en el perfil):** retoma la Pista B con la profundidad de las Fases 7 y 9 — agentes de código sobre bases de código legacy reales, RAG sobre documentación y código antiguo, fine-tuning de un modelo para un stack específico (el ejemplo de "modelo para Java enterprise" del bloque B3 es exactamente esta rama), y evaluación rigurosa de cuánto ayudan de verdad estas herramientas en mantenimiento y modernización. Conecta directo con tu experiencia profesional actual, así que es la rama con retorno más inmediato si quieres aplicar lo aprendido en tu trabajo.

No hace falta decidir esto ahora — es una nota para cuando termines la Fase 10 y quieras seguir sin perder foco.