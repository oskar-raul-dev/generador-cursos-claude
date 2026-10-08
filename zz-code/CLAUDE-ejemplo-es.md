# CLAUDE.md

> 📝 **Versión en español, solo para leer.** El `CLAUDE.md` que se usa es el de `CLAUDE-sample-en.md`
> copiado a la raíz del repositorio. Si prefieres editarlo en español, cambia este, y pide a tu LLM de
> confianza que lo traduzca al inglés antes de copiarlo. Borra este recuadro en la copia.

Este archivo guía a Claude Code en este repositorio. Contiene solo lo que aplica a **todos** los cursos
y a todas las sesiones; las decisiones de cada curso viven en su propio `prompts/`.

## Qué es este repositorio

Una colección de cursos en Markdown, escritos con asistencia de IA, para **cualquier audiencia**: desde
quien nunca programó hasta ingenieros senior. No hay lector por defecto. Cada curso declara su
audiencia, su profundidad y su evaluación en su ficha de arranque (`prompts/ficha-de-arranque.md`) y
en su alcance (`prompts/alcance-del-proyecto.md`); nunca supongas un lector que el curso no declaró.

## Cómo está organizado

- `cursos-<familia>/<curso>/` — los cursos publicados, agrupados por familia temática. La carpeta de
  familia es solo un contenedor (sin README ni contenido). Un curso puede agrupar subcursos un nivel
  más abajo. Lista los directorios para ver qué existe; este archivo no lleva inventario.
- `propuestas-cursos/` — borradores que todavía no son cursos. Lee primero su `README.md`. Nunca
  enlaces una propuesta desde material publicado.
- `zz-instrucciones/` — la maquinaria de producción: el flujo (etapas E0–E9), los tipos de curso, los
  prompts de etapa, las plantillas, las lecciones de producción y el verificador. **Empieza por
  `zz-instrucciones/QUICK-START.md`.**
- `zz-code/` — todo el código que escriben las sesiones para probar las ideas de un curso, un
  directorio por sesión, cada uno con su `MANIFIESTO.md` y un `README.md` que explica cómo repetir y
  medir cada prueba. Reglas en `zz-code/README.md`. Los cursos nunca lo citan.
- Las carpetas personales o privadas del autor (si las hay, se nombran aquí): no se editan ni se citan
  salvo que lo pida.

## Orden de autoridad

1. La guía y las decisiones del propio curso (`prompts/guia-de-estilo-y-convenciones.md`, la tabla
   `D-xx` del alcance, la ficha de arranque).
2. Este archivo.
3. Los documentos ya publicados del curso.

Un curso puede cambiar cualquier valor por defecto de abajo, pero **de forma explícita**: su guía
nombra el valor que reemplaza y por qué. Si no dice nada, aplica el valor por defecto.

## Anatomía de un curso

- El material publicado, en la raíz del curso: lecciones o fases `00-slug.md`, apéndices `a01-slug.md`,
  una historia opcional `00-historia-de-<slug>.md`, la convención de git `00-convencion-de-git-y-tags.md`
  si el lector escribe código (cada fase la enlaza desde su bloque 🏷️ de cierre; el lector copia el curso a
  un repositorio propio y trabaja ahí, nunca en este), documentos vivos (`cuaderno-incidentes.md`,
  `BENCHMARKS.md`, `INSTINTOS.md`) solo si el curso los usa, y su `README.md`.
- `prompts/` — la maquinaria del curso: ficha de arranque, alcance, propuestas, guía, diccionario,
  contrato de nombres, plantillas de capítulo, prompts de fase y de apéndice, plan de producción y
  verificador. Se conserva como referencia y **no** se publica. Léelo antes de escribir o editar
  cualquier cosa del curso.
- El código ejecutable va en `src/` (una carpeta por lección, con el nombre de la lección, o un solo
  proyecto que crece con tags de git) o en una carpeta con nombre propio (`laboratorio/`, `taller/`)
  que el README del curso nombra.
- Los tracks opcionales comparten carpeta con un prefijo: fases `beNN-slug.md`, apéndices
  `bea-NN-slug.md`, sus propios prompts y su cuaderno de incidentes como archivos nuevos, y sus tags de
  git en un espacio de nombres propio.

## Flujo de trabajo

Curso nuevo: sigue `zz-instrucciones/QUICK-START.md` (ficha de arranque → alcance → propuesta → plan
de producción → tandas). Curso existente: lee primero su `prompts/plan-de-produccion.md` —§3 estado,
§6 deuda de enlaces, §7 la entrada más reciente de la bitácora, §8 checklist— y trabaja solo la tanda
pedida. Preparar y escribir son sesiones distintas. El README del curso y su documento de estructura
se escriben al final, a partir de lo que de verdad existe.

## Reglas editoriales por defecto (cuando el curso no dice nada)

- **Idioma:** español latinoamericano neutro con tuteo (sin *vos*, sin *vosotros*, sin términos
  peninsulares). Código, identificadores, comandos y salida de terminal en inglés; los comentarios
  dentro del código, en inglés.
- **Tono:** colegial y ajustado a la audiencia declarada. Honesto con los trade-offs: cada opción gana
  en algo y pierde en algo, y lo que pierde lleva números.
- **Afirmaciones:** "X es mejor para Y" necesita una medición (en `BENCHMARKS.md` o en el bloque de
  medición de la lección), nunca una anécdota. Ningún comando, salida ni número se inventa.
- **Forma:** prosa antes que listas; tablas solo para comparar o mapear; un emoji por encabezado
  principal; callouts 📝 contexto · 🧭 principio · 🧠 modelo mental · ⚠️ trampa · 💡 idea de diseño.
- **Ejercicios**, si el curso los lleva: dificultad 🟢 muy fácil · 🟡 fácil · 🟠 medio · 🔴 difícil ·
  🔥 boss, con la cantidad y el reparto que el curso declaró. Cada ejercicio cierra con un
  `**Criterio:**` verificable, y las respuestas van donde el curso decidió (plegadas bajo el ejercicio
  o en un documento de respuestas aparte, sincronizado en la misma edición).
- **Diagramas:** el formato que decidió el curso (`D-12`); Mermaid solo si se pidió.
- **Historia:** si el curso la tiene, es la fuente de verdad de todo dato narrativo; ninguna lección
  inventa un nombre, una cifra o una regla que no esté allí.
- **Todo curso cierra con un veredicto honesto:** cuándo NO usar lo que enseñó.
- **Nombres de archivo:** `<prefijo>-<número>-<tema>`, en minúsculas, con guiones y ceros a la
  izquierda. No se mezclan estilos de apéndice dentro de un curso.

## Reglas de sesión (no se negocian)

- **Git es del autor.** Nada de commits, `git add`, `git rm` ni `git mv`; no ofrezcas mensajes de
  commit. Git de solo lectura (`status`, `log`, `diff`) está bien. Los tags que pide el plan se dejan
  escritos en su bitácora.
- **Borra solo archivos nombrados**, con `rm`; nunca directorios completos ni `rm -rf`. La única
  excepción es `zz-code/limpiar.py --borrar`, que corre o autoriza el autor.
- **Trabajo en secuencia y sin subagentes**, salvo que el autor los pida.
- **No instales nada ni generes cargos** en la máquina del autor. Si hace falta algo, di qué y cómo; lo
  instala el autor.
- **Docker:** inventario inicial a un log; todo con la etiqueta `curso=<slug>`; puertos altos y
  aleatorios ligados a `127.0.0.1` (`-p 127.0.0.1::PUERTO`), nunca los de por defecto; al terminar,
  borra solo tus contenedores con sus volúmenes. Nunca `prune` sin filtro de etiqueta, nunca toques lo
  que ya existía, y restaura cualquier configuración de la máquina que hayas cambiado.
- **Todo el código va a `zz-code/`:** crea el directorio de la sesión con
  `python3 zz-code/nuevo.py <slug-del-curso>`; lo efímero va a su `salidas/`. Nunca el scratchpad,
  nunca `/tmp`. Un comando suelto que produce algo citable se copia a un archivo, y el `README.md` del
  directorio se mantiene al día mientras se prueba.
- **Pregunta antes de escribir.** Todo prompt de etapa y de fase empieza con un paso de preguntas; si a
  mitad de la sesión aparece una duda nueva, para y pregunta. Anota el error literal antes de
  arreglarlo.
- **Antes de cerrar la sesión:** corre el verificador del curso (`python3 prompts/verificar-corpus.py`,
  o `zz-instrucciones/herramientas/verificador_base.py <carpeta-del-curso>` mientras no exista) y deja
  el plan al día (§3, §6, §7, §8) con las trampas, las decisiones por defecto, los recursos que quedan
  levantados y los tags para el autor.

## Memoria

El plan de producción es el estado del curso; la memoria guarda **punteros**, no contenido: dónde está
el plan, qué sigue, las decisiones del autor que no se ven en los documentos y las trampas que
comparten varios cursos. No guardes lo que el repositorio ya registra.

## Ante la duda

Tono o forma → la guía del curso. Estructura → su propuesta y su plan. Una afirmación → mídela o
quítala. Una decisión que es del autor → pregunta, con la opción que recomiendas primero. Todo lo
demás → `zz-instrucciones/`.
