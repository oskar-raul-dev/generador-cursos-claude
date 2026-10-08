# 🧩 Plantilla de capítulo
## Python para desarrolladores Java senior

Este archivo contiene **un solo esqueleto**, el de fase, porque el curso **no tiene
apéndices** (`alcance-del-proyecto.md` §6). Se copia al abrir el chat que redacta una fase, se
rellenan los `{{placeholders}}` y se borran las notas entre llaves antes de entregar.

Junto con la guía de estilo y el alcance, forma el marco para que las fases, escritas cada una
en su chat, se lean como un solo documento.

> **Nota de coherencia:** el número de fases, sus nombres y su reparto salen de
> `propuesta-fases-y-alcance.md`. Si alguna vez cambian, **se cambian allí primero** y esta
> plantilla después.

---

> 🧩 **Qué aplica a los complementos `ia` y `ds`.** **Todo.** Las diecisiete secciones de esos dos
> tracks usan esta plantilla como molde literal, con sus diez secciones, su 📏 y su 🧱, igual que
> una fase base: son la continuación del curso sobre los proyectos de Áurea, no material suelto
> (`propuestas-fases-base-ia-datos.md` §0). Lo único que cambia es el encabezado —`Track ia ·
> sección 4 de 8` en vez de `Fase N de 18`— y el bloque 🏷️ del cierre, que pide `git tag -a
> ia-fase-04` y `ia-mini-04`.

> 🍽️ **Qué aplica al material a la carta.** Las secciones opcionales
> (`propuestas-temas-opcionales.md`) se leen sueltas y no construyen un sistema, así que **esta
> plantilla es para ellas una guía y no un molde**: una sección de la carta se resuelve con
> propósito, concepto, ejemplo que corre, ejercicio y cierre. Lo que sí heredan es el criterio de
> fondo —no explicarle al lector lo que ya sabe, y decir dónde se rompe cada analogía—, que es lo
> que separa una sección útil de una entrada de catálogo.

# 📐 Plantilla de fase

````markdown
# {{emoji}} Fase {{NN}} — {{Nombre}}

> Python para desarrolladores Java senior · Fase {{N}} de {{total}} · Bloque {{A|B|C}}
> Depende de: {{fase previa}} · Habilita: {{fase siguiente}}
> Registro de esta fase: {{script | herramienta | aplicación}}
> Proyecto que avanza: {{cuál de los cuatro, o "ninguno"}}

---

## 🎯 1. Propósito

{{Una o dos frases: qué resuelve esta fase y a qué decisión sirve. Anclar al dominio de Áurea.
No "aprenderás X": qué vas a poder decidir o construir que antes no.}}

---

## ✅ 2. Qué queda listo al terminar

- [ ] {{resultado verificable 1}}
- [ ] {{resultado verificable 2}}
- [ ] {{...3 a 5 ítems}}
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

{{Verificable = se comprueba ejecutando algo. "Entender X" no es un resultado verificable.}}

---

## 🚫 3. Qué NO entra todavía

- {{tema diferido}} → Fase {{M}}.
- {{...}}

{{Y si algo se difiere **fuera del curso**, se dice aquí con su razón. No hay apéndice al que
mandarlo.}}

---

## 🧠 4. Concepto mínimo

{{Solo la teoría que hace falta para escribir el código de esta fase. Prosa, no bullets. El
problema antes que la herramienta.}}

{{Aquí viven las secciones narrativas que la fase pida:}}

### Tu instinto de Java dice… y esta vez se equivoca

{{El reflejo concreto, el código que produce, por qué falla aquí, y qué se escribe en su
lugar. Con el contraejemplo al lado, porque la lección está en la comparación.}}

### Esto sí funciona igual

{{Lo que se transfiere sin cambios. Importa tanto como lo anterior.}}

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| {{...}} | {{...}} | {{...}} |

{{En las dos direcciones. La tercera columna es obligatoria: una analogía sin su límite es
peor que ninguna — guía §4.2.}}

> 📝 **Nota de ecosistema.** {{Qué versión trajo esta API, qué reemplazó, y por qué lo
> anterior sigue vivo en el código que el lector va a encontrar por ahí.}}

---

## 💻 5. Código mínimo con comentarios

{{El grueso de la fase. Código ejecutable con las versiones fijadas. Identificadores en
inglés, comentarios y docstrings en español con tildes, mensajes de error en español.}}

{{Estilo obligatorio — guía §6:
- **Escrito en el registro de esta fase.** Bloque A: un archivo, stdlib pura, sin clases
  decorativas, sin dependencias. Bloques B y C: layout `src/`, tipado estricto, pruebas.
- Cero `Any`; nulabilidad explícita; `Decimal` para dinero; `datetime` con zona.
- Nada de `Manager`, `Helper`, `Util`, `Impl`, ni clase con un solo método.
- Lo pythónico que este perfil no escribe solo —generadores, EAFP, context managers,
  `dataclass`, `Protocol`— aparece con su contraejemplo en estilo Java.}}

{{💸 Marcar cada deuda técnica intencional con una nota de dos partes: qué sería lo correcto, y
**en qué fase se paga**. Si no se paga, decirlo y explicar por qué.}}

**Detalles con intención**
- {{decisión deliberada del bloque anterior}} — {{su porqué}}.

**El patrón a memorizar**
> {{Una o dos frases con la lección transferible del fragmento.}}

**Prueba de fuego**
{{Verificación concreta: qué ejecutar, qué esperar, y qué mentira te va a contar la salida si
miras el lugar equivocado.}}

---

## 📏 6. Medición

{{El número que esta fase produce. El formato de abajo y las reglas de honestidad están en
`formato-de-mediciones.md`; el arnés es el mismo para todo el curso y se construye en la Fase 02.}}

**Hipótesis:** {{la afirmación que se va a sostener o a tumbar, en una línea.}}

**Condiciones:** {{versión del intérprete, máquina, tamaño del dato, número de repeticiones,
qué se mide y con qué.}}

**Competidores:** {{contra qué se compara. Si el competidor es el stack de origen, tiene que
ser una implementación que alguien defendería en una revisión de código — guía §4.6.}}

**Resultado:**

| {{Opción}} | {{Métrica}} | {{Métrica 2}} |
|---|---|---|
| {{...}} | {{...}} | {{...}} |

> ⚖️ **Veredicto.** {{Qué gana, dónde pierde, y a partir de qué umbral cambia la respuesta.}}

{{Si esta fase no mide nada, esta sección dice en una línea por qué —y esa línea tiene que ser
convincente. Una fase sin medición es la excepción, no la norma.}}

---

## 🧱 7. Miniproyecto — {{Nombre}}

{{Obligatorio, uno por fase. El formato completo, con sus reglas de calibración, está en
`formato-de-miniproyectos.md` y se sigue literal. Va aquí desarrollado, no enlazado.}}

**El encargo** · **Por qué duele** · **Datos de entrada** · **Criterios de aceptación** ·
**Restricciones de registro** · **La trampa** · **Pistas** · **Cómo se entrega**

---

## 🧪 8. Ejercicios ({{total}})

**🟢 Fácil (1–{{a}})**
1. {{...}}

**🟡 Intermedio ({{a+1}}–{{b}})**
**🟠 Difícil ({{b+1}}–{{c}})**
**🔴 Muy difícil ({{c+1}}–{{total}})**
**🔥 Opcionales**

{{20 mínimo, 25 ideal. Escala calibrada para un dev Java senior: un 🟢 no es "copia el
ejemplo", es "aplícalo a un caso que el texto no resolvió" — guía §9. Al menos un tercio de
diagnóstico o medición, y al menos dos de registro: dado un encargo, decidir si es script,
herramienta o aplicación y justificarlo con el costo de las otras dos.}}

---

## 📚 9. Referencias

**Documentación oficial**
- {{URL completa}} — {{nota de versión; recordar que docs.python.org sirve la estable del día
  y hay que fijar la versión en el selector}}

**PEPs** (cuando expliquen el porqué de una decisión de diseño)
- {{...}}

**Libros / artículos** (si aplican)
**Video / apoyo**

**Orden de lectura sugerido:** {{qué leer antes de escribir código → qué consultar durante → a
qué volver después}}

> ⚠️ {{URLs, títulos y contenidos pueden haber cambiado; el lector debe verificarlos. No se
> inventan páginas, ISBN ni identificadores de video.}}

---

## 🚀 10. Cierre y conexión con la siguiente fase

{{Qué quedó construido y por qué la Fase {{siguiente}} es el paso natural: qué necesita de
esta fase para existir.}}

> **La señal de que quedó bien:** {{criterio en forma de cita — cómo se siente el trabajo bien
> hecho de esta fase.}}

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-{{NN}} -m "F{{N}} cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la fase llevan su prefijo (`fase {{NN}}: …`), los de ejercicio su número
> (`fase {{NN}} ej12: …`) y el miniproyecto el suyo (`fase {{NN}} mini: …`). El miniproyecto
> terminado lleva además su tag anotado `mini-{{NN}}`, y **en el mensaje de ese tag va el
> número que arrojó su medición** — es donde se recupera después con `git show`.

---

{{📌 Los pendientes —lo que apareció al escribir la fase y no cabía adentro, con destino explícito:
otra fase, un ejercicio 🔥, una medición que falta o una decisión de proyecto— **no van en el
documento publicado** desde el 07/10/2026: van a `prompts/pendientes-a-futuro.md`, en la sección
del documento que los generó. **Nunca "un apéndice": no existen.**}}
````

---

## Recordatorios al rellenar una fase

- **Declara el registro de la fase en el encabezado.** Es lo primero que el lector necesita
  saber, y lo que evita que copie la ceremonia del Bloque C dentro de un script del Bloque A.
- El número de fases y sus nombres salen de `propuesta-fases-y-alcance.md`. Ninguna fase se
  renumera por su cuenta.
- No contradecir nombres de módulos, funciones ni modelos definidos en fases previas. Ante la
  duda, revisar el entregable anterior y el diccionario de la guía §5.1.
- **Cada fase produce una medición**, y la excepción se justifica en una línea.
- **Cada fase produce un miniproyecto**, y no se resuelve copiando la fase. Si se resuelve
  copiando la fase, está mal calibrado: `formato-de-miniproyectos.md` §3.
- Las versiones salen de `alcance-del-proyecto.md` §9. Ninguna se da por buena de memoria.
- Coherencia de la ficción: Áurea es del curso. Si una fase afirma que algo está así en Áurea,
  tiene que poder mostrarlo (guía §11), y la frontera de la historia clínica no se cruza.
- **Si aparece material que "sería un buen apéndice"**, tiene tres destinos legítimos: sección
  de esta fase, fase propia, o 📌 con su razón escrita.

---

# 🍽️ Plantilla de sección de la carta

Agregada el 05/10/2026 (guía §14). Es **guía y no molde**: las ocho secciones van en este orden,
pero una sección puede fundir dos si el tema lo pide, y las secciones «Tu instinto de Java dice…», «Esto sí funciona igual» y el diccionario (sin emoji en el `###` desde el 07/10/2026) aparecen solo cuando hay un
reflejo de Java que recalibrar. Unas 400 líneas.

````markdown
# {{emoji}} {{tt}}{{NN}} — {{Nombre}}

> Python para desarrolladores Java senior · **Carta** · Track `{{tt}}` — {{nombre del track}} ·
> sección {{N}} de {{M}}
> Se lee suelta: no hace falta ninguna otra sección de la carta. {{Conviene haber leído la Fase NN.}}
> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas
> rotuladas «Salida esperada, sin correr» no salen de una corrida.

---

## 🎯 1. Qué problema resuelve

{{El problema concreto, y quién lo tiene. En Áurea si le sirve al tema; con su propio ejemplo si
no. Dos o tres párrafos.}}

## 🧠 2. El modelo

{{La idea que hace que el resto encaje. 🪞 si hay un reflejo de Java que se rompe; 📖 si hay
traducción en las dos direcciones; un diagrama Mermaid si hay estructura que mostrar.}}

## 💻 3. El ejemplo que corre

{{Instalación (`uv add …` o el `compose.yaml`), el código completo en un bloque por archivo,
cómo se ejecuta, y la salida rotulada.}}

## ⚠️ 4. Lo que se rompe

{{Las dos o tres trampas reales, cada una con su síntoma y su arreglo.}}

## ⚖️ 5. Cuándo NO usarla

{{Contra qué pierde, con número o con su medición ⏳; y la alternativa.}}

## 🧪 6. Ejercicios ({{8–12}})

**🟢 Fácil (1–{{n}})**
1. {{…}} **Criterio:** {{verificable}}.

**🟡 Intermedio** · **🟠 Difícil** · **🔴 Muy difícil** (con *Rúbrica:* de tres o cuatro puntos)

## 📚 7. Referencias

{{Documentación oficial, PyPI, artículos; orden de lectura sugerido.}}

## 🚀 8. Cierre

{{Qué te llevas, y La señal de que quedó bien.}}

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-{{tt}}-fase-{{NN}} -m "op {{tt}}{{NN}} cerrada: <lo que hiciste, en una línea>"
> ```
>
> Los commits llevan su prefijo (`op {{tt}}{{NN}}: …`) y los de ejercicio su número
> (`op {{tt}}{{NN}} ej07: …`).
````
