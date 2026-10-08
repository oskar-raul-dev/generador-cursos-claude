# Guía operativa del Project — chats, prompts y estructura

> El **qué** estudiar está en `Curriculo_Maestro_IA_VFinal.md`.
> El **cómo aprender** está en `guia-aprendizaje.md`.
> Esto es el **cómo operar el Project en Claude**: qué chats crear, con qué prompts, y dónde vive cada archivo.
>
> Sustituye a `Guia_Proyecto_Claude_y_Prompts.md` (obsoleta: hablaba de 12-18 meses y del currículo v1).
> **Última actualización:** 2026-07-13

---

## 1. Montaje del Project

**Conocimiento del proyecto** (archivos que Claude ve en todos los chats):

| Archivo | Qué es | Lo actualizas… |
|---|---|---|
| `Curriculo_Maestro_IA_VFinal.md` | El plan: 11 fases, proyecto tesis, bibliografía, banco de módulos opcionales | Rara vez |
| `perfil_personal_VFinal.md` | Restricciones, decisiones cerradas **con sus razones** | Cuando cambie tu situación real |
| `guia-aprendizaje.md` | El método: los 3 actos, repaso espaciado, calendario | Rara vez |
| `bitacora_avance.md` | Dónde vas, qué falta, qué dudas tienes | **Cada semana** |
| `mazo_pendiente.md` | Fallos de reconstrucción aún no convertidos en tarjetas de Anki | Cada sesión |

**Instrucciones del proyecto:** están en `instrucciones_project.md` (documento aparte, listo para copiar y pegar).

**Memoria de Claude:** actívala en Ajustes. Aun así, `bitacora_avance.md` sigue siendo lo confiable — un plan de 33 meses no puede depender de que un sistema recuerde.

---

## 2. Convención de chats

Nomenclatura, para poder buscar y retomar meses después:

```
[F0-TEMARIO]  Fase 0 — syllabus detallado
[F0-CLASE]    Cálculo: regla de la cadena multivariable
[F0-EJERC]    Ejercicios de MLE
[F0-PROY]     Regresión desde cero en NumPy
[F0-REPASO]   Repaso espaciado — viernes alterno
[F0-CIERRE]   Examen oral de cierre de fase
[TB-B0]       Track B — agentes de código
[MO-1]        Módulo opcional — Deep RL
[TESIS]       Plataforma logística — hilo conductor (chat vivo)
```

**Dos chats especiales que duran todo el plan (no se cierran):**
- **`[TESIS]`** — el proyecto tesis atraviesa 10 fases. Un chat vivo donde registras cada pieza que le añades. Es lo que evita que en la Fase 10 no recuerdes por qué tomaste una decisión en la Fase 2.
- **`[BITACORA]`** — cierre semanal, 5 minutos.

**Regla de higiene:** cierra un chat a los ~15-20 mensajes. Pide "resume todo lo que hablamos", copia el resumen, y ábrelo como primer mensaje del chat nuevo. Un chat largo cuesta más y se vuelve inmanejable.

---

## 3. El ciclo de iteración de una fase

Así se recorre **cada fase**, de principio a fin. Los chats no son arbitrarios: cada uno corresponde a un momento del método.

```
┌─ AL ABRIR LA FASE ────────────────────────────────────┐
│ 1. [Fn-DIAGNOSTICO]  → 3-5 preguntas, 1-2 de fases    │
│    anteriores. Si fallas las de repaso, repasas ANTES  │
│    de avanzar. (Obligatorio — guia-aprendizaje §1b)    │
│ 2. [Fn-TEMARIO]      → syllabus semana a semana        │
└────────────────────────────────────────────────────────┘
                         ↓
┌─ DURANTE LA FASE (se repite por cada tema) ───────────┐
│ 3. Estudias por tu cuenta (libro/video + cuaderno)     │
│    ← ACTO 1. Claude NO participa aquí.                 │
│ 4. [Fn-CLASE]  → dudas puntuales, no resumen del tema  │
│ 5. Reconstruyes sin mirar   ← ACTO 2                   │
│ 6. [Fn-EJERC]  → quiz de producción; anotas los fallos │
│    → los fallos van a mazo_pendiente.md                │
└────────────────────────────────────────────────────────┘
                         ↓
┌─ PROYECTO DE LA FASE ─────────────────────────────────┐
│ 7. [Fn-PROY]  → mini-proyecto independiente            │
│ 8. [TESIS]    → la pieza que esta fase aporta al tesis │
└────────────────────────────────────────────────────────┘
                         ↓
┌─ AL CERRAR LA FASE ───────────────────────────────────┐
│ 9. [Fn-CIERRE] → examen oral. Si no pasas, no avanzas. │
│ 10. Escribes la BITÁCORA de la fase (1 página)         │
│ 11. Generas los 10-15 prompts de reconstrucción → Anki │
│ 12. (Opcional) B5: medio día de puesta al día          │
└────────────────────────────────────────────────────────┘

┌─ EN PARALELO, TODO EL TIEMPO ─────────────────────────┐
│ [Fn-REPASO]  Viernes alterno, 45 min. Tarjetas de      │
│              Anki de fases pasadas. Tiempo extra.      │
└────────────────────────────────────────────────────────┘
```

**El punto crítico del ciclo es el paso 3.** Claude no aparece ahí. Si le pides a Claude que te explique el tema **antes** de leerlo tú, conviertes el Acto 1 en algo aún más pasivo que un video — y el sistema entero se cae. Claude entra en el paso 4 (dudas), no en el 3 (encuentro).

---

## 4. Prompts plantilla

### 4.1 Diagnóstico de entrada (al abrir cada fase) — NUEVO
```
Abro la Fase [N] del currículo. Antes de empezar, hazme el diagnóstico de entrada:

- 3 preguntas sobre los prerequisitos de esta fase.
- 2 preguntas de FASES ANTERIORES (elígelas tú — yo no puedo saber qué olvidé).

Fórmulalas como tareas de producción ("deriva X", "explica Y con un ejemplo
propio"), no como preguntas de definición.

No me des las respuestas. Espera las mías, corrígeme, y dime honestamente si
puedo avanzar o si necesito repasar algo antes.
```

### 4.2 Temario detallado de la fase
```
Actúa como profesor diseñando el syllabus detallado de la Fase [N] de mi
currículo (ver Curriculo_Maestro_IA_VFinal.md).

Mi ritmo: 6 h/semana (martes 1.5h, jueves 1.5h, sábado 3h). Recuerda la regla
del costo real del video: 2-3x la duración nominal.

Dame:
1. Desglose semana a semana, con horas realistas por actividad.
2. Por semana: subtemas, lecturas EXACTAS (capítulos), y qué lecture del curso
   corresponde.
3. Qué va en sesión de noche (libro+cuaderno) y qué va al sábado (video pesado).
4. 2-3 tareas de producción por semana, sin respuesta.
5. Un checklist de "ya puedo avanzar".

No inventes referencias: usa solo lo que está en el currículo. Si no estás
seguro de un número de capítulo, dime que lo verifique yo.
```

### 4.3 Duda puntual (NO "explícame el tema")
```
Estoy estudiando [TEMA] en [FUENTE, ej. "ISLR cap. 6"]. Ya lo leí.

Mi duda concreta es: [DUDA].
Lo que creo entender hasta ahora: [TU INTENTO, aunque esté mal].

Corrígeme desde ahí. No me des un resumen del capítulo completo — ya lo leí.
```
> **Por qué así:** pedir "explícame X" convierte a Claude en otro canal pasivo. Pedir "aquí está lo que entendí, corrígeme" es Acto 2.

### 4.4 Quiz de producción (sin respuestas regaladas)
```
Hazme un quiz de 6 tareas sobre [TEMA]:
- 2 de derivación/cálculo a mano
- 2 de "explica por qué" (no "qué es")
- 2 de "encuentra el error" en código o razonamiento

Formúlalas como tareas de PRODUCCIÓN, no de reconocimiento.
No me des las respuestas. Espera cada respuesta mía y corrígeme con detalle.

Al final: dime cuáles fallé y redáctame las tarjetas de Anki correspondientes
(también como tareas de producción).
```

### 4.5 Mini-proyecto (sin vibe coding)
```
Empiezo el mini-proyecto de la Fase [N]: "[NOMBRE]".

Actúa como mentor, no como generador de código:
1. Primero, diseñamos la arquitectura en un documento. Sin código todavía.
2. En la parte central del algoritmo: NO me des la solución. Dame el esqueleto
   con pistas y revisa mi intento.
3. El boilerplate sí puedes dármelo completo.
4. Al final, ayúdame con el resumen de portafolio: problema, decisiones,
   resultados, LÍMITES (honestos).
```

### 4.6 Revisión de código propio
```
Aquí está mi implementación de [ALGORITMO], Fase [N]:
[código]

No lo reescribas. Dame:
1. Errores de CONCEPTO, no de estilo.
2. Preguntas que yo debería hacerme para encontrar el error solo.
3. Solo si sigo sin encontrarlo: la corrección puntual, explicada.
```

### 4.7 Repaso espaciado (viernes alterno) — NUEVO
```
Sesión de repaso. Estoy en la Fase [N].

Genera 8-10 tareas de producción sobre fases ANTERIORES (tú eliges cuáles: yo
no puedo saber qué olvidé — es el problema de metacognición de guia-aprendizaje).

Prioriza:
- Lo más antiguo (más olvidado)
- Lo que es prerequisito de lo que estoy estudiando ahora
- Lo que fallé antes, si lo recuerdas del historial

Una a la vez. Espera mi respuesta. Al final, dime qué tarjetas nuevas debo
añadir a Anki.
```

### 4.8 Cierre de fase — examen oral
```
Cerremos la Fase [N]. Hazme de examinador.

- Una pregunta a la vez, sobre los temas centrales de la fase.
- Espera mi respuesta. Solo avanzas cuando esté sólida o me hayas corregido.
- Incluye los criterios de salida del currículo para esta fase.
- Al final: dime honestamente si estoy listo, sin edulcorarlo.

Después del examen, ayúdame a:
1. Escribir la bitácora de la fase (qué costó, qué decidí, qué no funcionó).
2. Generar 10-15 prompts de reconstrucción para el mazo de Anki.
```

### 4.9 Retomar tras una pausa
```
Retomo después de [X semanas]. Según bitacora_avance.md estaba en [Fase/Tema].

1. Resume en 2-3 párrafos lo clave de ese punto.
2. Hazme 3 tareas de producción para ver qué se me olvidó de verdad.
No me des las respuestas antes de que conteste.
```

### 4.10 Tentación de dispersión — NUEVO
```
Apareció [TEMA/HERRAMIENTA] y me llama la atención, pero no está en la fase
actual ni en el proyecto tesis.

Sé honesto: ¿es necesario ahora, o es dispersión? Si es dispersión, propón la
entrada para el banco de módulos opcionales (MO) del currículo, y sigamos.
```
> **Por qué existe este prompt:** es tu mecanismo de defensa. No dices "no", dices "después" — y eso baja la ansiedad de dejarlo pasar sin romper la secuencia.

---

## 5. Estructura de directorios

Numeración alineada con las fases del currículo (0-10). **Markdown como formato nativo** — tú lo conviertes a DOCX/PDF con tus CLIs cuando quieras leer en móvil o tablet.

```
IA-Maestria/
│
├── 00-Meta/
│   ├── Curriculo_Maestro_IA_VFinal.md
│   ├── perfil_personal_VFinal.md
│   ├── guia-aprendizaje.md
│   ├── guia-proyecto.md              <- este documento
│   ├── instrucciones_project.md
│   ├── bitacora_avance.md            <- semanal
│   ├── mazo_pendiente.md             <- fallos aún no pasados a Anki
│   └── glosario_personal.md
│
├── F00-Matematicas/
│   ├── notas/                        <- AAAA-MM-DD_tema.md
│   ├── ejercicios/
│   ├── bitacora-fase.md              <- se escribe AL CERRAR la fase
│   └── proyecto-regresion-numpy/     <- README.md con link al repo
│
├── F01-IA-Simbolica/
├── F02-Ingenieria-Datos/             <- aquí nace el simulador
├── F03-Machine-Learning/
├── F04-Inferencia-Causal/
├── F05-Deep-Learning/
├── F06-Vision/
├── F07-NLP/
├── F08-Reinforcement-Learning/
├── F09-Produccion-MLOps/
├── F10-Capstone/
│   (cada una con: notas/ ejercicios/ bitacora-fase.md proyecto-*/)
│
├── TB-Track-B/                       <- solo durante la Fase 0
│   ├── B0-agentes-codigo/
│   ├── B1-mcp/
│   ├── B2-ollama/
│   ├── B3-finetuning/
│   └── B4-cierre-integrador/
│
├── TESIS-Plataforma-Logistica/       <- el hilo conductor, 10 fases
│   ├── decisiones.md                 <- por qué elegiste cada cosa, con fecha
│   ├── esquema-datos.md
│   └── README.md                     <- link al repo de código
│
├── MO-Modulos-Opcionales/            <- el banco. Casi siempre vacío
│
├── Referencias/
│   ├── papers/
│   └── libros/
│
└── Portafolio/
    ├── case-studies/
    └── cv.md
```

### Drive vs. Obsidian vs. Git

**Los tres, cada uno para lo suyo:**

| Qué | Dónde | Por qué |
|---|---|---|
| **Código** | **GitHub** | Drive no versiona. En Drive solo un `README.md` con el link |
| **Notas, bitácoras, documentos** | **Obsidian sobre una carpeta sincronizada con Drive** | Obsidian es Markdown puro sobre archivos locales — no es un formato propietario. Drive lo sincroniza como carpeta normal |
| **Lectura en móvil/tablet** | **DOCX/PDF generados con tus CLIs**, subidos a Drive | Markdown en móvil se lee mal; tus conversores ya resuelven esto |

**Por qué Obsidian y no Google Docs:** Obsidian trabaja **sobre tus archivos .md tal cual**. No hay importación ni exportación — el archivo en disco *es* la nota. Eso significa que tus CLIs, Git y Claude ven exactamente lo mismo. Google Docs te encerraría en su formato y romperías la cadena.

**Rutina de conversión:** al cerrar cada fase, corres tu CLI sobre `notas/` y subes el DOCX/PDF resultante a Drive. Ese es tu material de lectura para los ratos muertos.

---

## 6. Skills — solo una

Tú ya tienes CLIs que convierten Markdown → HTML/DOCX/PDF y te funcionan para texto + código. **No necesitas las skills de Word ni de PDF.** Reemplazarlas por una skill sería cambiar algo que ya controlas por algo que no.

**La única que sí te falta: presentaciones (PPTX).** Y no es urgente — la vas a necesitar en la Fase 10 (portafolio, case study, quizá una presentación interna en el trabajo). Actívala cuando llegues ahí, no antes.

Regla general: **skill solo donde no tengas ya una herramienta propia.** Todo lo demás es sobreingeniería del sistema de estudio, que es la forma más elegante de no estudiar.

---

## 7. Formato de la bitácora

**Semanal** (`00-Meta/bitacora_avance.md`), 5 minutos, viernes o sábado:

```markdown
## Semana 1 — Fase 0
- Hecho: derivadas de una variable (Khan), 3B1B caps. 1-3. NumPy confirmado ok.
- Reconstruí: regla de la cadena básica ✓ / gradiente multivariable ✗
- Al mazo: "deriva ∂/∂x de ||Ax-b||²" (me atoré en la transpuesta)
- Track B: instalé Claude Code, probé en el repo de [proyecto real]
- Duda abierta: por qué el gradiente es un vector columna y no fila
```

**Por fase** (`F0n-*/bitacora-fase.md`), al cerrar, 1 página:

```markdown
# Bitácora — Fase 0

## Qué costó más de lo esperado
...
## Decisiones que tomé y por qué
...
## Qué NO funcionó
...
## Qué le aporté al proyecto tesis
...
## Si volviera a empezar esta fase
...
```

> Esta segunda es la que alimenta el case study de la Fase 10. A 33 meses no la vas a poder reconstruir de memoria — y sin ella, el portafolio final es una demo sin historia.

---

## 8. Higiene de contexto

- **Chats cortos.** 15-20 mensajes y cierras. Pide resumen, cópialo, abre chat nuevo.
- **Los archivos del Project no se recargan** en cada mensaje — súbelos sin miedo.
- **Instrucciones del Project: cortas y estables.** Lo específico de una sesión va en el chat.
- **Junta preguntas relacionadas** en un mensaje en vez de mandarlas de a una.
- **Limpia el conocimiento del Project** de archivos muertos (la guía vieja, el currículo v2) — solo generan confusión sobre cuál es la versión vigente.