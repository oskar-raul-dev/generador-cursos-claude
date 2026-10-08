# 📍 Prompts de los documentos de la raíz del curso
## Python para desarrolladores Java senior

> ✅ **Estado: el camino base está escrito.** Las 18 fases (00–17), `BENCHMARKS.md` e
> `INSTINTOS.md` están publicados en la raíz del curso. Este documento pasa de ser **encargo** a
> ser **registro de lo que se decidió**: sigue mandando sobre cualquier revisión del camino base y
> sobre el material a la carta, pero ya no describe trabajo pendiente.
>
> Los tres documentos que este archivo encarga —`0-ESTRUCTURA-CURSO.md`,
> `00-convencion-de-git-y-tags.md` y el `README.md`— **existen y están publicados**, y a ellos se
> sumaron después `BENCHMARKS.md` e `INSTINTOS.md`, que la Fase 17 consolidó.

Tres documentos viven en la **raíz del curso**, no en `prompts/`, y **se escribieron antes que
cualquier fase** porque las 18 fases los enlazan. Cada uno se redactó en su propio chat.

📝 `00-historia-de-aurea.md` también está en la raíz y también precede a las fases, pero **no lo
encarga este documento**: es la fuente narrativa del curso, no un entregable de estructura.

Orden obligatorio: primero `0-ESTRUCTURA-CURSO.md`, después `00-convencion-de-git-y-tags.md`,
después el `README.md`. El tercero resume a los dos primeros, así que escribirlo antes garantiza
que se contradigan.

---

## # 0-ESTRUCTURA-CURSO.md

````markdown
Este chat produce un único archivo: `0-ESTRUCTURA-CURSO.md`, en la **raíz** del curso *Python
para desarrolladores Java senior* (no en `prompts/`).

## Marco

Fuentes de verdad, en este orden: `prompts/alcance-del-proyecto.md` —el techo; su §0 fija que el
curso es autocontenido y no hereda reglas de fuera de esta carpeta—,
`prompts/propuesta-fases-y-alcance.md`, `prompts/guia-de-estilo-y-convenciones.md`.

Este documento es **el mapa que el lector usa para orientarse**, y la fuente de verdad de la
estructura para quien escriba una fase. No repite el contenido de las fases: las sitúa.

## Qué tiene que contener

- **Qué es el curso en una frase** y cuál es su eje: *¿esto es un script, una herramienta o una
  aplicación?*
- **Para quién es**, con la regla explícita de que no se explica lo que un dev Java senior ya
  sabe, y qué se da por sabido.
- **Los tres bloques** (A, B, C) con su tesis, y por qué la frontera del Bloque B es la pieza
  central.
- **La tabla de las 18 fases**: número, nombre, bloque, registro de código, el reflejo que ataca,
  y qué proyecto avanza. Sale literal de `propuesta-fases-y-alcance.md` §4 — **no se reinventa ni
  se renumera**.
- **Los cuatro proyectos** que atraviesan el curso y en qué fase nace cada uno.
- **Cómo funciona cada fase**: las 10 secciones, el miniproyecto obligatorio, la medición, el tag.
- **Qué NO tiene el curso**: apéndices, teoría de ML, enseñar a programar, y los tracks
  opcionales que existen y se toman aparte.
- **Cómo se recorre**: en orden, sin saltarse el Bloque A, y qué pasa si alguien quiere ir
  directo al Bloque C (que puede, y cuál es el costo).

## Restricciones

- Prosa antes que listas; una sola tabla grande, la de las 18 fases.
- Sin horas por fase: bandas por bloque, y se calculan cuando las fases estén escritas
  (`propuesta-fases-y-alcance.md` §9.3). Si todavía no existen, se dice que se publicarán.
- Tono de la guía §2. No vender el curso: describirlo.
````

---

## # 00-convencion-de-git-y-tags.md

````markdown
Este chat produce un único archivo: `00-convencion-de-git-y-tags.md`, en la **raíz** del curso
*Python para desarrolladores Java senior*.

## Marco

Fuentes de verdad: `prompts/alcance-del-proyecto.md`, `prompts/propuesta-fases-y-alcance.md`,
`prompts/guia-de-estilo-y-convenciones.md` §8.1, `prompts/formato-de-miniproyectos.md` §4.8.

**Este documento sí lo lee el estudiante.** Es corto, operativo, y las 18 fases lo enlazan desde
su bloque 🏷️ **sin reexplicarlo**. Si una fase tiene que explicar la convención, este documento
falló.

## Qué tiene que contener

- **Por qué hay un repositorio**: para poder volver a un punto del curso, comparar dos fases con
  un `git diff`, y leer la factura de cada deuda 💸 que el curso paga.
- **Un repositorio nuevo**, creado en la Fase 00, con su `.gitignore` de Python — que incluye el
  entorno virtual, y esa es la primera lección de git del curso.
- **Prefijos de commit**: `fase NN: …` para el trabajo de la fase, `fase NN ejMM: …` para los
  ejercicios, `fase NN mini: …` para el miniproyecto.
- **Tags anotados**, y son dos familias:
  - `fase-NN` — cierra la fase, con el checklist de la sección 2 en el mensaje, una línea por
    ítem.
  - `mini-NN` — cierra el miniproyecto, y **en su mensaje va el número que arrojó su medición**.
    Es donde se recupera después con `git show mini-07`.
- **Ramas** con prefijo (`wip/`, `spike/`) para que no choquen con los tags.
- **Los tres usos concretos** que justifican todo lo anterior, con el comando exacto de cada uno:
  recuperar el estado de una fase anterior, leer la factura de una deuda entre dos tags, y
  comparar tu número del miniproyecto de la Fase 15 con el de la 02.
- Una nota sobre el **Bloque A**: hasta la Fase 07 no hay `pyproject.toml`, así que el repositorio
  de esas fases es un puñado de archivos `.py` sueltos, y está bien.

## Restricciones

- Máximo dos pantallas. Es una convención, no un tutorial de git: el lector lleva once años
  usándolo.
- Cero explicación de qué es un commit, una rama o un tag.
- Todos los comandos copiables y probados mentalmente contra el flujo real del curso.
````

---

## # README.md del curso

````markdown
Este chat produce un único archivo: `README.md`, en la **raíz** del curso *Python para
desarrolladores Java senior*.

## Marco

Fuentes de verdad: `0-ESTRUCTURA-CURSO.md` y `00-convencion-de-git-y-tags.md` —que ya existen
cuando este chat empieza—, más `prompts/alcance-del-proyecto.md` y la guía de estilo.

El `README.md` es **el escaparate**: lo lee alguien que todavía no decidió si toma el curso.
Resume, no duplica; cuando haga falta detalle, enlaza a `0-ESTRUCTURA-CURSO.md`.

## Qué tiene que contener

- **La frase que lo define** y la pregunta que lo ordena.
- **Para quién es y para quién no.** Esto último importa: alguien que no programa, o que no viene
  de un lenguaje con tipos y build, no es el lector.
- **Qué vas a construir**: los cuatro proyectos, en una línea cada uno, y el dominio de Áurea en
  un párrafo.
- **Cómo está organizado**: los tres bloques y el enlace a la tabla completa de fases.
- **Qué lo hace distinto**, y son tres cosas concretas: no hay apéndices, cada fase cierra con un
  miniproyecto difícil, y ninguna afirmación comparativa aparece sin su número.
- **Qué necesitas** para empezar: Python, un editor, y nada más hasta la Fase 07.
- **El veredicto como promesa**: el curso termina diciendo dónde Python no era la respuesta.
- Enlaces a `BENCHMARKS.md` e `INSTINTOS.md` cuando existan.

## Restricciones

- Una pantalla y media. Un README largo no lo lee nadie.
- Nada de promesas vacías ni de motivación de coach (guía §2).
- No repetir la tabla de fases: enlazarla.
````
