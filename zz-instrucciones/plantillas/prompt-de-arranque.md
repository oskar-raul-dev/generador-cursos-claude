# 🚀 Prompt de arranque de un curso nuevo

> ✏️ **Plantilla:** la ficha con la que el autor abre la **discusión** de un curso nuevo (etapa E0 del
> workflow). Se copia, se marca una opción por pregunta con `[x]` —o varias donde lo dice—, se
> completan las líneas de **Explica**, y se pega en una sesión nueva **desde la línea "Vamos a
> discutir…"**. Dos maneras de no decidir todavía: **en blanco**, la sesión asume su valor por
> defecto y lo marca como tal; **"Me lo sugieres tú en la sesión"**, la sesión abre la discusión de
> esa pregunta con opciones, preguntas y una recomendación, y no la da por cerrada hasta que el autor
> elija.
> No se copia al `prompts/` del curso tal cual: al cerrar la discusión, la sesión guarda la versión
> confirmada como `prompts/ficha-de-arranque.md`, que es la entrada de la etapa E1. La explicación de
> cada pregunta y un ejemplo lleno están en el `README.md` de `zz-instrucciones/`.

---

Vamos a discutir un curso nuevo. Esta sesión **no escribe ningún documento del curso**: su entregable
es la discusión, y al final, cuando yo la confirme, la ficha de abajo con las respuestas cerradas.

## 1. 🏷️ Título tentativo

{{El título como lo dirías hoy. Puede cambiar.}}

- [ ] **Me lo sugieres tú en la sesión** — dame tres o cuatro títulos con su tono

**De qué va, en una frase:** {{…}}
**Por qué ahora:** {{una entrevista, un proyecto que heredé, una migración, contenido para YouTube, un hueco…}}

## 2. 🧩 Tipo de curso

- [ ] **Curso completo** — el lector construye y opera algo que antes no sabía
- [ ] **Curso legacy** — el lector entra a un proyecto heredado y aprende sobre la marcha
- [ ] **Curso repaso** — el lector ya usó el tema y necesita ordenarlo y defenderlo en voz alta
- [ ] **Banco de preguntas de entrevista**
- [ ] **Banco de preguntas de examen** — con temario oficial
- [ ] **Mezcla u otro**
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

**Explica** (obligatorio si marcaste mezcla u otro; opcional en los demás): {{…}}

## 3. 👤 Audiencia

- [ ] **Dummie** — empieza de cero en el tema (y quizá en programar)
- [ ] **Con conocimientos** — sabe programar, no conoce este tema
- [ ] **Senior** — tiene oficio; no se le explican los fundamentos
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

**Qué sabe ya y qué no hay que explicarle:** {{…}}

## 4. 🔬 Profundidad

- [ ] **Lo básico** — lo necesario para usarlo con confianza
- [ ] **Medio** — usarlo bien y entender por qué funciona
- [ ] **Full geek** — por dentro: internals, mediciones, casos raros
- [ ] **Súper saiyajin** — profundidad teórica: modelos, papers, pruebas formales donde aplique
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

## 5. 🧪 Ejercicios

- [ ] **Sí** — {{cantidad aproximada por fase, o "la del tipo"}}
- [ ] **No**
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

**Si lleva ejercicios, su dificultad** (escala: muy fácil 🟢 · fácil 🟡 · medio 🟠 · difícil 🔴 · boss 🔥):

- [ ] **Equilibrados de punta a punta** — 🟢 🟡 🟠 🔴 y un 🔥 por fase
- [ ] **Equilibrados hasta medio** — 🟢 🟡 🟠, sin difíciles ni boss
- [ ] **Solo fáciles** — 🟢 🟡
- [ ] **Solo de medio a difícil** — 🟠 🔴 (y 🔥 si hay boss)
- [ ] **Aleatorio** — sin reparto fijo: cada fase pone los que pida su contenido
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

## 6. 🛠️ Taller

- [ ] **No**
- [ ] **Uno global** — un proyecto que crece a lo largo de todo el curso
- [ ] **Por sección** — un taller independiente al final de cada sección
- [ ] **Miniproyecto boss por sección + boss final**
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

**Explica** (de qué va el taller o los bosses, si ya lo sabes): {{…}}

## 7. ✅ Respuestas

- [ ] **Documento de respuestas separado** — para practicar sin ver la solución
- [ ] **Respuestas en cada ejercicio** — plegadas debajo del enunciado
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

## 8. 💻 Código de ejemplo

- [ ] **Sí** — lenguaje, stack y versiones: {{…}}
- [ ] **No**
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

## 9. 🎨 Inspiración

Rutas absolutas o relativas a cursos, notas o temarios, y **qué tomar** de cada una:

| Ruta | Tomar el tema | Tomar el estilo | Tomar la estructura |
|---|---|---|---|
| {{ruta}} | {{sí / no}} | {{sí / no}} | {{sí / no}} |

{{Si uno de ellos es la base del curso nuevo —se hereda su maquinaria—, dilo: la siguiente etapa es E1b.}}

- [ ] **Me lo sugieres tú en la sesión** — busca en el repositorio los cursos que se parezcan y dime qué tomar de cada uno

## 10. 📐 Diagramas

- [ ] **No**, o a criterio de quien escribe
- [ ] **Sí, en ASCII** (bloques `text`)
- [ ] **Sí, en Mermaid**
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

## 11. 🧫 Tipo de prueba

Cómo se verifica lo que el curso afirma antes de publicarlo:

- [ ] **Inspección de código** — se revisa, no se ejecuta; lo no ejecutado se marca así
- [ ] **Creación y ejecución en contenedor** — todo corre en contenedores etiquetados, sin tocar la máquina
- [ ] **Creación, instalación y ejecución en la máquina local** — lo que se instala lo instalo yo, con las instrucciones que me des
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

## 12. 📦 Código generado en `zz-code/`

- [ ] **Sí, con documentación completa** — cada directorio con su `README.md` de corrida y medición
- [ ] **No** — el código va igual a `zz-code/`, con su `MANIFIESTO.md`, pero sin el README detallado
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

## 13. 🎭 Historia

- [ ] **No** — sistema de ejemplo neutro
- [ ] **Sí, con mi idea:** {{empresa o sistema, lugar, personajes, el dolor que la mueve}}
- [ ] **Sí, que la IA proponga** — dame dos o tres ideas para elegir
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

## 14. 🧱 Organización

Si el tema es bastante extenso, el curso se puede dividir en bloques o pistas
(`zz-instrucciones/01-tipos-de-curso.md` §10):

- [ ] **Una sola secuencia** — fases o capítulos numerados de punta a punta, agrupados en partes si hace falta
- [ ] **En bloques** — cada bloque en su propio directorio, con sus capítulos, su README y su cierre; uno es el troncal
- [ ] **En pistas paralelas** — un eje secuencial y una pista de práctica que corre a la par durante un tramo y se cierra
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

**Explica** (los bloques o pistas que ya ves, cuál es el troncal, cuáles serían opcionales): {{…}}

## 15. 📚 Referencias

Todo documento cita la documentación oficial y los libros base que respaldan lo que afirma; eso no se
pregunta. Esto es lo **otro**: el material externo que el curso le recomienda al lector para seguir
estudiando (guía §10.4). Marca **varias** si aplica.

**Qué material:**

- [ ] **Ninguno extra** — solo las citas oficiales y los libros base
- [ ] **Bibliografía** — libros, papers, especificaciones
- [ ] **Blogs y artículos** de autor reconocido
- [ ] **Cursos gratis** — YouTube, cursos abiertos de universidades o del fabricante
- [ ] **Cursos de pago** — Udemy, Coursera, Pluralsight, O'Reilly…
- [ ] **Sitios de tutoriales** — Baeldung, GeeksforGeeks, Real Python, MDN…
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

**Dónde van:**

- [ ] **Al final de cada documento** — en la sección 📚 de su plantilla, después de las fuentes oficiales
- [ ] **Al final de cada bloque o parte** — una lista curada en el README del bloque
- [ ] **Al final del curso** — un apéndice de bibliografía y recursos
- [ ] **Me lo sugieres tú en la sesión** — no lo tengo claro: propónmelo y lo discutimos

**Explica** (recursos que ya conoces y quieres que estén, idioma —¿solo en español, o también en
inglés?—, si prefieres solo gratis): {{…}}

## 16. 📝 Lo demás

- **Lo que NO quiero:** {{…}}
- **Tamaño o tiempo disponible:** {{horas, número de fases o de bloques, "lo que pida el tema"}}
- **Notas libres:** {{…}}

---

## Cómo quiero que trabajes

**Paso 1 — Antes de responder**, lee `zz-instrucciones/00-workflow-de-un-curso.md`,
`01-tipos-de-curso.md`, `04-usar-en-cada-repositorio.md` y el `CLAUDE.md` del repositorio. Si di rutas
de inspiración, léelas lo suficiente para saber qué ofrecen (README, guía y una fase).

**Paso 2 — Devuélveme, sin escribir ningún archivo:**

(a) el curso contado en un párrafo, como lo entendiste, y la pregunta que lo ordena, en una línea;
(b) si el tipo que marqué es el correcto, y si no, cuál y por qué;
(c) **las combinaciones que chocan** o piden una excepción (una audiencia dummie con profundidad
súper saiyajin, un curso legacy sin código, una audiencia que contradice el `CLAUDE.md`, un tamaño
que no cabe en una sola secuencia o unos bloques tan distintos que serían cursos hermanos) y cómo las
resolverías;
(d) cada respuesta traducida a su decisión `D-xx` del alcance, con el valor propuesto, y las que yo
dejé en blanco con tu valor por defecto marcado como tal;
(e) lo que tomarías de cada inspiración, y lo que no;
(f) si marqué historia sin idea: dos o tres ideas de historia, de un párrafo cada una;
(g) preguntas bloqueantes numeradas, separando las que puedes asumir con un valor por defecto;
(h) **por cada pregunta donde marqué "Me lo sugieres tú en la sesión"**: dos a cuatro opciones
concretas pensadas para este curso (no las genéricas de la ficha), qué gana y qué pierde cada una,
tu recomendación con su porqué, y las preguntas que me harías para afinarla. Ordénalas de la que más
condiciona a las demás (tipo, audiencia, profundidad) a la que menos.

**Paso 3 — Cuando yo responda**, ajusta y repite lo que cambió, hasta que diga que está cerrado. Las
preguntas que marqué con "Me lo sugieres tú" siguen abiertas hasta que yo elija: en cada vuelta,
vuelve a listar las que falten, con nuevas ideas si las anteriores no me convencieron y con lo que
mis respuestas a las otras cambiaron de ellas. No cierres ninguna por mí.

**Paso 4 — Cierre:** guarda en `<carpeta del curso>/prompts/ficha-de-arranque.md` esta ficha con
las respuestas confirmadas y, debajo, la tabla de decisiones `D-xx` del paso 2. La carpeta del curso
es la que fija `04-usar-en-cada-repositorio.md` §1 para este repositorio (`cursos-<familia>/<slug>/`
o `repaso-entrevistas/<área>/<NN-curso>/`); si el curso va en bloques o pistas, la ficha va en el
`prompts/` de la raíz del curso, no en un bloque. Si yo ya dejé ahí el borrador, la versión
confirmada lo reemplaza; si la carpeta no existe, créala donde corresponda. Dime qué prompt de etapa
sigue (E1, o E1b si el curso se basa en otro) y qué parte de la ficha alimenta cada una de sus
secciones.

Reglas: git lo manejo yo; no instales nada ni toques nada fuera de la carpeta nueva; todo en secuencia
y sin subagentes salvo que lo pida.
