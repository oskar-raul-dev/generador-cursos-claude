# Guía de aprendizaje — cómo estudiar esta maestría autodidacta

> Documento de método, no de contenido. El *qué* estudiar está en `Curriculo_Maestro_IA_VFinal.md`; las restricciones personales, en `perfil_personal_VFinal.md`. Esto es el **cómo**.
>
> **Última actualización:** 2026-07-13

---

## 0. El problema que este documento resuelve

Problema declarado en el perfil: *dificultad para la lectura profunda; tendencia a saltar entre Wikipedia, prompts y tutoriales sin que quede residuo.*

El diagnóstico es preciso y no es falta de capacidad ni de disciplina. Es que **leer, ver videos y subrayar producen una sensación de fluidez que no es aprendizaje.** Reconoces el material, y el cerebro interpreta ese reconocimiento como dominio. Es una ilusión bien documentada: <cite index="12-1">la revisión de Dunlosky et al., que resume más de 200 estudios sobre métodos de estudio, concluye que las técnicas más comunes — releer y subrayar — no funcionan, mientras que las menos comunes — espaciar y autoevaluarse — sí</cite>.

La corrección no es leer *más* ni leer *más despacio*. Es cambiar el acto: **de reconocer a producir.**

Todo lo que sigue son consecuencias de esa única frase.

---

## 1. El modelo de aprendizaje: los tres actos

Cada tema que estudies pasa por tres actos. Ninguno es opcional, y el segundo es el que casi todo el mundo se salta.

### Acto 1 — Encuentro (entrada)
Leer el libro, ver la clase, escribir en el cuaderno. Es necesario, pero **no es aprendizaje todavía** — es materia prima. El error es creer que aquí termina el trabajo.

### Acto 2 — Reconstrucción (producción)
**Cierras el material y produces la respuesta desde cero.** Sin mirar. Por escrito o hablando en voz alta. Si puedes ver el texto, no es reconstrucción: es relectura con pasos extra.

Este acto se siente *mal* — es lento, incómodo, y a veces fracasas. Ese malestar es la señal de que está funcionando. La comodidad de releer es la señal de que no.

**El criterio Feynman del currículo es exactamente esto:** *¿puedo explicar esto sin notas y reconstruir el código desde cero?* No es una meta abstracta al final de la fase — es lo que haces cada sesión.

### Acto 3 — Repaso espaciado (retención)
Volver sobre lo reconstruido, en intervalos crecientes, justo antes de olvidarlo. Sin esto, lo del mes 3 se evapora para el mes 25 — y este plan dura ~32 meses.

**Regla operativa que une los tres actos — la regla del mazo:**

> Lo que **no logres producir** en el Acto 2, lo anotas. Esa lista de fallos **es** tu mazo de tarjetas.

Las tarjetas no salen de tus apuntes. Salen de tus **fallos**. Eso significa que no creas 200 tarjetas "por si acaso" de un capítulo: creas 5 tarjetas de las 5 cosas que no pudiste reconstruir. Una fracción del trabajo, el doble de efecto.

---

## 1b. "¿Cómo sé qué preguntarme?" — el problema de la metacognición

**La objeción, y es correcta:** *"no puedo saber qué olvidé. Si lo supiera, no lo habría olvidado. Sé lo que recuerdo; lo que se me fue no tengo forma de detectarlo."*

Es real y tiene nombre: **no puedes usar tu memoria para auditar tu memoria.** Cualquier método que dependa de que adivines dónde está tu hueco está roto de raíz.

### La salida: no busques el hueco. Produce el todo y deja que el hueco te bloquee.

El movimiento correcto no es preguntarte *"¿por qué la verosimilitud es un producto?"* — esa pregunta **ya contiene la respuesta**; solo la puedes formular si ya identificaste el hueco. El movimiento es:

> **"Deriva el MLE de μ para una gaussiana, de principio a fin, en una hoja en blanco."**

Y entonces intentas. **Te vas a trabar.** No necesitas *saber* dónde está el hueco: **el hueco es donde el lápiz se detiene.** El atasco es el detector. No lo predices — lo descubres tropezando.

Esa es toda la respuesta: **no sabes qué olvidaste, y no hace falta que lo sepas.** Solo hace falta intentar producir algo lo bastante completo como para que los huecos te bloqueen el paso.

### Las cuatro fuentes de tareas (ninguna requiere adivinar)

1. **Los criterios de salida y diagnósticos del currículo.** Ya están escritos, ya son tareas de producción, y **no los escribiste tú** — así que no están contaminados por lo que *crees* recordar. Es tu banco de tareas, gratis.
2. **La estructura del material.** Al terminar un capítulo, tapa el libro y **reconstruye el índice con una frase por sección**. Lo que no puedas expandir, ahí está el hueco. La estructura te lo señala; no adivinaste nada.
3. **Tres tareas genéricas que funcionan para cualquier tema, sin conocerlo de antemano:**
   - *"Explícaselo a alguien que no lo sabe"* — en voz alta. Se oye dónde te vuelves vago.
   - *"¿De dónde sale esto?"* — reconstruye la derivación o el argumento, no el resultado.
   - *"¿Cuándo NO aplica?"* — casi siempre revela que memorizaste una fórmula sin conocer sus supuestos. Brutalmente eficaz.
4. **El tutor.** Es literalmente la regla 5 de las instrucciones del Project (*mini-quiz de 3-5 preguntas al final de cada sesión*). El tutor sí puede hacer lo que tú no: conoce el tema completo, tú solo conoces lo que recuerdas. **Tu ceguera metacognitiva deja de ser un problema si las preguntas vienen de fuera.**

Con el tiempo, tu propio mazo se vuelve esa fuente externa — porque lo escribió el "tú" de hace tres meses, que sí sabía dónde había fallado.

---

## 1c. Ejemplo práctico completo (una semana real)

**Tema:** máxima verosimilitud (MLE), Fase 0.

**Martes, 80 min — Acto 1.** Lees la sección. Subrayas. Sigues la derivación que trae el libro. Todo tiene sentido; cierras el cuaderno satisfecho. **Esa satisfacción es la trampa:** seguir la derivación de otro es reconocimiento — cada paso "se ve bien" porque el autor ya eligió el correcto. Tú no elegiste nada.

**Jueves, 10 min — Acto 2.** No abres el libro. Hoja en blanco. Tarea: *"Plantea la verosimilitud de un modelo gaussiano y deriva el MLE de μ."* Lo que pasa realmente:

- **Sale:** "verosimilitud = probabilidad de los datos dados los parámetros". Bien.
- **Sale a medias:** escribes ∏ p(xᵢ|μ,σ²) y te frenas. ¿Por qué producto? *Porque asumo independencia* — lo recordaste al escribirlo, no lo tenías.
- **Se atora:** aplicas log. Sabes que "se usa el log", pero al justificar *por qué se puede* (monotonía) descubres que eso lo aceptaste sin verlo.
- **No sale:** derivas, igualas a cero, y el álgebra no llega a la media muestral.

**Ahora sí** abres el libro, ves dónde te desviaste, y arreglas los tres huecos — leyendo con tres preguntas concretas, no "cubriendo el capítulo".

**El mazo (solo los fallos, tres tarjetas, no treinta):**

| Tarjeta | Por qué está aquí |
|---|---|
| "¿Qué supuesto convierte la verosimilitud en un producto?" | Lo recordaste tarde |
| "¿Por qué se puede maximizar el log en vez de la función original?" | No lo sabías |
| "Deriva el MLE de μ para una gaussiana, de principio a fin" | Te atoraste |

No hiciste tarjeta de la definición de verosimilitud: **esa sí la produjiste.**

**La moraleja:** el martes leíste 80 minutos y aprendiste poco. El jueves fallaste 10 minutos y aprendiste mucho. Y hay un efecto secundario que la relectura jamás te da: la reconstrucción no solo consolida — **diagnostica**.

### Las tres formas de arruinarlo

1. **Mirar "solo para arrancar".** Un vistazo al cuaderno y ya no es reconstrucción: es copia con demora. Si te atoras, **te quedas atorado y anotas dónde**. El atasco *es* el dato.
2. **Reconstruir demasiado pronto.** Hacerlo el martes mismo, 10 min después de leer, no sirve: sigue en memoria de trabajo. Por eso va al **jueves** — con 48 h de olvido encima, que es donde recuperar cuesta.
3. **Hacer tarjetas de todo el capítulo.** Ahí muere el sistema: 200 tarjetas de cosas que ya sabes = 40 min diarios de aburrimiento hasta abandonarlo en el mes 2. **Solo los fallos.**

---

## 1d. Subrayar y tomar apuntes: permitidos (y necesarios)

**Nada de esto está prohibido.** Subrayar y tomar apuntes son **Acto 1**, son útiles, y el cuaderno es tu mejor canal — no hay razón para tocarlo. La única afirmación es más modesta:

> **Subrayar y apuntar no son el Acto 2. No lo sustituyen.** Mientras el libro está abierto delante de ti, el texto te está sosteniendo. El Acto 2 empieza cuando **cierras el libro**.

Pero no todos los apuntes valen lo mismo:

| Tipo de apunte | Qué es | Veredicto |
|---|---|---|
| **Transcribir** | Copiar frases del libro al cuaderno | Poco valor — es fotocopiar con la mano |
| **Reformular** | Escribir la idea *en tus palabras*, sin mirar la frase original | **Muy valioso** — ya es una mini-reconstrucción |
| **Anotar preguntas** | "¿Por qué producto y no suma?" | **Muy valioso** — alimenta el Acto 2 y el mazo |
| **Rehacer la derivación del libro** | Seguirla paso a paso, escribiéndola | Útil, pero **no es reconstrucción**: el libro te da cada paso |
| **Subrayar** | Marcar para volver | Legítimo como **índice**. No es estudio en sí |

**Si reformulas en vez de transcribir, tu cuaderno ya hace buena parte del trabajo.** No te estoy quitando nada de lo que haces — te estoy pidiendo 10 minutos al final, con el libro cerrado.

### Video (YouTube, Platzi, cursos)

El video tiene un fallo que el libro no tiene: **avanza solo.** Si te distraes, el texto te espera; el video sigue, y "terminaste la clase" sin haber estado ahí. Por eso pausar no es opcional — *es lo que convierte el video en estudio*.

**Notas con timestamp: sí, pero con contenido.** El timestamp es un **índice** — te lleva al minuto 34:12 el jueves en vez de barrer 90 minutos. Eso ahorra fricción real. Pero cuidado con la trampa: una nota que solo dice `34:12 — MLE` no captura nada; captura una dirección postal. El formato útil:

```
[34:12] MLE — la verosimilitud es producto porque asume
        observaciones independientes.
        [PREGUNTA: ¿por qué se puede maximizar el log?]
```

Timestamp (índice) + **frase en tus palabras** (mini-reconstrucción) + **pregunta abierta** (semilla del mazo). El timestamp es lo *menos* importante de los tres.

**La mejor técnica para clases tipo CS229 o Karpathy: pausa antes de que el profesor resuelva.** Cuando plantea el problema y va a derivarlo, pausa e intenta el siguiente paso tú. Aciertes o no, al reanudar ya no estás mirando: estás **comparando**. Eso es Acto 2 *dentro* del Acto 1, y es lo más eficiente que se puede hacer con un video.

---

## 2. Repetición espaciada: qué es y por qué funciona

### El mecanismo, en dos ideas

**Idea 1 — La curva del olvido.** Tras aprender algo, tu capacidad de recuperarlo cae rápido: en horas al principio, luego en días. Es el hallazgo de Ebbinghaus (1885), y sigue en pie.

**Idea 2 — El punto óptimo de repaso es cuando estás a punto de olvidar.** Esto es lo contraintuitivo. Repasar cuando aún lo recuerdas bien se siente productivo y sirve de poco. Repasar cuando ya casi lo perdiste **cuesta esfuerzo** — y ese esfuerzo de recuperación es lo que consolida la memoria. Cada recuperación exitosa hace dos cosas: te devuelve arriba, y **aplana la curva siguiente**. Por eso los intervalos crecen: 1 día → 3 → 8 → 20 → 60.

### La evidencia

No es autoayuda ni productividad de moda. Es de los resultados más sólidos de la psicología cognitiva:

- <cite index="8-1">El metaanálisis de Hattie y Donoghue (2021), sobre 242 estudios, 1.619 efectos y más de 169.000 participantes, replicó los hallazgos de Dunlosky et al. (2013) y concluyó que las dos técnicas más efectivas son la práctica distribuida (espaciado) y la práctica de recuperación (autoevaluación)</cite>. Son, exactamente, los Actos 2 y 3.
- <cite index="7-1">Los efectos del espaciado son robustos: aparecen con distintos materiales, procedimientos y perfiles de estudiante, y se han demostrado en numerosos estudios aleatorizados en aula, incluyendo específicamente el aprendizaje de matemáticas</cite> — relevante para tu Fase 0.
- <cite index="8-1">Una objeción común es que el autoexamen frecuente genera ansiedad. La investigación de Agarwal et al. (2014) encontró lo contrario: la práctica de recuperación redujo la ansiedad y aumentó la confianza</cite>.

### La frase que vale la pena interiorizar

<cite index="15-1">Normalmente la memoria es algo que pasa por casualidad: lees un libro y piensas "ojalá recuerde esto". Un sistema de repetición espaciada convierte la memoria en una decisión: si quieres recordar algo, escribes una pregunta sobre ello, y en unas semanas quedará codificado en memoria de largo plazo</cite>. Michael Nielsen lo resume como *"make memory a choice"* — la memoria como elección, no como lotería.

### Lecturas y recursos (todos gratuitos, todos de primera mano)

**Empieza por aquí (30-40 min, y es entretenido):**
- **Nicky Case — *How to Remember Anything Forever-ish*** — https://ncase.me/remember/ — cómic interactivo. Te explica el espaciado *usando* espaciado contigo mientras lees. Es la mejor puerta de entrada que existe.

**El ensayo seminal (1-2 h, léelo cuando quieras hacerlo en serio):**
- **Michael Nielsen — *Augmenting Long-Term Memory*** — http://augmentingcognition.com/ltm.html — el texto que convirtió Anki de "app de idiomas" en herramienta de comprensión profunda. Nielsen es físico y coautor del libro canónico de computación cuántica; no es un gurú de productividad.
- **Michael Nielsen — *Using spaced repetition systems to see through a piece of mathematics*** — http://cognitivemedium.com/srs-mathematics — **este es directamente relevante para tu Fase 0.** Cómo usar tarjetas para *matemáticas* y no solo para hechos sueltos.

**Cómo escribir buenas tarjetas (imprescindible antes de crear el primer mazo):**
- **Andy Matuschak — *How to write good prompts: using spaced repetition to create understanding*** — https://andymatuschak.org/prompts/ — la diferencia entre una tarjeta que memoriza y una que construye entendimiento.
- **Piotr Wozniak — *Twenty rules of formulating knowledge*** — reglas clásicas de diseño de tarjetas, del propio inventor del algoritmo que usa Anki.

**La evidencia académica (si quieres el respaldo):**
- **Dunlosky et al. (2013), *Improving Students' Learning With Effective Learning Techniques*** — https://journals.sagepub.com/doi/abs/10.1177/1529100612453266 — la revisión de referencia.

**Programación específicamente:**
- **Sasha Laundy — *Using flash cards to become a better programmer*** — https://sasha.wtf/writing/anki-post-1/ — aplicación al oficio, no a idiomas.

---

## 3. La herramienta: Anki

**Por qué Anki y no un cuaderno ni Google Docs.** No es por las tarjetas — es por el **calendario**. A los seis meses tendrás tarjetas de cinco fases distintas, cada una en un punto distinto de su curva de olvido. Decidir qué toca hoy es un cálculo por tarjeta, y tú vas a decidir mal de forma sistemática: repasarás lo que recuerdas (se siente bien) y evitarás lo que olvidaste (se siente mal). El algoritmo existe para quitarte esa decisión.

**Costo:**

| Plataforma | Precio |
|---|---|
| Escritorio (Windows/Mac/Linux) | Gratis, open source |
| AnkiWeb (sincronización + navegador) | Gratis |
| AnkiDroid (Android) | Gratis, open source |
| AnkiMobile (iPhone/iPad) | ~USD 25, pago único (financia el proyecto) |

**Recomendación:** empieza **solo con el escritorio**. Es donde vas a estar el viernes, con el cuaderno al lado. Si más adelante activas las microjornadas de 10-15 min y las quieres en el móvil, ahí decides. No compres una app para un hábito que aún no tienes.

**Advertencia seria:** Anki tiene un ecosistema de plugins, temas y configuraciones que puede tragarse un fin de semana entero. **No entres ahí.** Instalar → crear un mazo llamado "IA" → empezar. *Optimizar el sistema de estudio es la forma más elegante de no estudiar.*

### Cómo se escribe una tarjeta que sirve

Para este currículo, la mayoría deben ser **tareas de producción**, no preguntas de definición:

| Mal (reconocimiento) | Bien (producción) |
|---|---|
| "¿Qué es la regla de la cadena?" | "Deriva ∂/∂x de ‖Ax − b‖²" |
| "¿Qué es Parquet?" | "Explica por qué un formato columnar acelera una consulta analítica y la ralentizaría como base transaccional" |
| "¿Qué es backprop?" | "Programa backprop para una red de 2 capas ocultas, sin mirar" |
| "¿Qué es la d-separación?" | "Dame un ejemplo propio de d-separación en la plataforma logística" |

**Fuente ideal de tarjetas, sin inventar nada:** los **criterios de salida** y los **diagnósticos de entrada** del propio currículo ya están redactados como tareas de producción. Cópialos.

**Matemáticas:** el enunciado va en Anki; la derivación la haces **en el cuaderno** y luego comparas. Anki no necesita renderizar tu respuesta — solo preguntarte y llevar el calendario.

---

## 4. Calendario de trabajo

**6 h/semana de estudio + ~45 min de repaso cada dos semanas (tiempo extra).**

| Día | Duración | Estructura |
|---|---|---|
| **Martes noche** | 1.5 h | **10 min:** reconstrucción sin mirar de la sesión anterior → **80 min:** material nuevo (libro + cuaderno) |
| **Jueves noche** | 1.5 h | **10 min:** reconstrucción → **80 min:** material nuevo |
| **Sábado mañana** | 1.5 h + break 30 min + 1.5 h | **Bloque 1 (90 min):** material nuevo — *aquí va el video pesado* → **break** → **Bloque 2 (60 min):** práctica / código → **Cierre (20-30 min):** reconstruir el bloque 1 sin mirar |
| **Viernes alterno** | ~45 min | **Tiempo extra.** Solo tarjetas de Anki de fases pasadas. Antes de la noche libre. |

### Reglas del calendario

**Los 10 min y los 20-30 min salen de dentro de las 6 h.** No las amplían. Son el precio de que las otras 5 horas cuenten.

**El video pesado va al sábado.** Pausar y retroceder no funciona en fragmentos de 20 minutos; necesita bloque largo. Las noches de 1.5 h son para libro + cuaderno, que tolera mejor la interrupción.

**Regla del costo real del video.** La duración nominal **no** es el costo. Ver bien — pausando, retrocediendo, tomando apuntes — cuesta **2-3× la duración nominal**. Un curso de "40 horas de video" son ~100 h de trabajo real. Las plataformas suman los reproductores, no el aprendizaje. **Corolario: ver un video sin pausar es consumo, no estudio, y no cuenta contra las 6 h.**

**El viernes libre se protege.** Cine, videojuegos, lectura recreativa. No es tiempo desperdiciado: es lo que hace que las 6 horas existan **durante 30 meses**. Lo que rompe planes de 3 años no suele ser la falta de ambición, sino la ambición sin sostenibilidad.

**Microjornadas de 10-15 min: fase 2.** Cuando el calendario de arriba sea hábito (~2 meses), añade tarjetas en días muertos. No antes.

---

## 5. Tips de estudio y enfoque

### Sobre la lectura (el punto débil declarado)

1. **Lee con una pregunta, no con un resaltador.** Antes de abrir el capítulo, escribe en el cuaderno qué esperas que responda. Leer para *contestar algo* es activo; leer para *cubrir páginas* es pasivo.
2. **Cierra la pestaña.** Después de cada sección, cierra el libro y escribe en tus palabras qué dijo. Lo que no puedas escribir, no lo leíste — lo miraste.
3. **Subraya y apunta — pero reformulando, no transcribiendo.** Ver la tabla de la sección 1d. El subrayado es un índice para volver; el estudio empieza cuando cierras el libro.
4. **Prohibido el salto a Wikipedia mientras lees.** Anota la duda y sigue. Resuélvelas todas al final de la sesión. El salto constante fragmenta la atención y es el hábito exacto que estás corrigiendo.

### Sobre la programación

5. **Escribe el código antes de pedirlo.** Si vas a pedirle código al tutor (a mí), primero intenta la lógica central tú. La regla 4 del Project existe para esto.
6. **Reconstruye, no copies.** Karpathy escribe `micrograd` en video; tú escribes *tu* versión. Copiar y que funcione es una sensación de progreso falsificada.
7. **Si algo funciona y no sabes por qué, no funciona.** Anótalo en el mazo.

### Sobre el enfoque

8. **Una sola cosa a la vez.** Es la decisión estructural del currículo. También aplica a la sesión: un tema por sesión, no tres.
9. **Sesión sin teléfono.** No hace falta un sistema — hace falta que esté en otra habitación.
10. **El malestar es la señal.** Si la sesión se sintió fluida y agradable de principio a fin, probablemente fue reconocimiento. La reconstrucción incomoda. Confía en la incomodidad más que en la fluidez.

### Sobre el largo plazo

11. **La bitácora por fase.** Al cerrar cada fase, una página: qué costó, qué decidiste, qué no funcionó. A 34 meses es imposible reconstruirlo de memoria — y es la materia prima del case study de la Fase 10.
12. **El diagnóstico de entrada es tu red de seguridad.** Cada fase abre con 3-5 preguntas, de las cuales 1-2 son de fases anteriores. Si fallas esas, el repaso deja de ser opcional. Es el mecanismo que detecta si el sistema se está degradando **antes** de que el hueco crezca.
13. **No rediseñes el plan cada vez que aparezca ansiedad.** Va a aparecer — sobre la obsolescencia, el mercado, la velocidad. El plan ya está construido casi enteramente sobre lo que *no* caduca. Rediseñarlo es una forma sofisticada de no avanzar.
14. **La constancia le gana a la intensidad.** A 6 h/semana durante 32 meses, la variable que decide el resultado no es cuánto rindes en tu mejor semana, sino cuántas semanas no te caes.

---

## 6. Resumen en una página

**El modelo:** Encuentro → **Reconstrucción** → Repaso espaciado. El del medio es el que casi todos se saltan y el único que produce aprendizaje.

**La regla del mazo:** lo que no puedas producir sin mirar, va a Anki. Las tarjetas salen de tus fallos, no de tus apuntes.

**El calendario:** martes 1.5 h, jueves 1.5 h, sábado 3 h (en dos bloques), viernes alterno 45 min de Anki.

**El test de honestidad, al terminar cualquier sesión:** *¿produje algo sin mirar, o solo reconocí cosas?*

Si la respuesta es "reconocí", la sesión fue entretenimiento con formato académico. Y ya sabes cómo se siente eso — es lo que llevas años haciendo con Wikipedia.