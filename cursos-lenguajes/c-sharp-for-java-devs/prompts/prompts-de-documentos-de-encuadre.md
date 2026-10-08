# 📐 Prompts de los documentos de encuadre
## C# para desarrolladores Java senior

Los documentos que **no** son fases y que el lector sí lee. Cada uno se escribe en su propio chat
y produce un solo archivo, igual que una fase.

Van **antes** que la Fase 00, salvo `BENCHMARKS.md` e `INSTINTOS.md`, que nacen con ella y crecen
después. El orden está en [`como-escribir-el-curso.md`](como-escribir-el-curso.md).

Todos usan el **§ Marco común** de [`prompts-de-fase.md`](prompts-de-fase.md) —fuentes de verdad,
las nueve reglas, plataforma, ficción— con una diferencia: **no siguen la plantilla de diez
secciones**, porque no son fases. Cada bloque de abajo dice qué forma tiene el suyo.

---

## # `README.md` del curso

````markdown
Produce el archivo `README.md` en la raíz del curso *C# para desarrolladores Java senior*.
Aplica el § Marco común de `prompts-de-fase.md`, con esta excepción: no sigue la plantilla de
diez secciones.

**Qué es:** el escaparate. Alguien que llega al directorio decide en dos minutos si este curso
es para él. No es un índice comentado ni un resumen del alcance.

**Qué lleva, en este orden:**
- Qué es el curso en dos frases, con la pregunta que lo ordena — *¿esto se migra, se envuelve o
  se deja quieto?*
- Para quién es y para quién **no**: dev Java senior con ocho años o más; no es un curso de
  introducción a la programación ni de certificación en Azure.
- El stack fijado, con sus versiones, tomado de `alcance-del-proyecto.md` §9 — no se inventa
  ninguna.
- **Windows 11 como requisito**, dicho en el escaparate y no en una nota al pie, con su razón:
  el sistema heredado son 340 formularios WinForms sobre .NET Framework.
- El mapa de los siete bloques y las veinticinco fases, con una línea por bloque. La tabla
  detallada vive en `0-ESTRUCTURA-CURSO.md`; aquí va el mapa, no el índice.
- La empresa: Cordillera Media en un párrafo, lo justo para que se entienda el dominio.
- Cómo se trabaja: un miniproyecto obligatorio por fase, una medición por fase, y el repositorio
  con sus tags.
- El veredicto que el curso se debe a sí mismo, citado: *si al final resultara que .NET moderno
  ganó todo, el curso estaría mal escrito.*

**Qué NO lleva:** instrucciones de instalación (son la Fase 00), el detalle de las fases (es
`0-ESTRUCTURA-CURSO.md`), ni promesas de lo que el lector "va a dominar".

**Cuidado con:** escribir un índice. Un README que solo enumera archivos no ayuda a nadie a
decidir si tomar el curso.
````

---

## # `0-ESTRUCTURA-CURSO.md`

````markdown
Produce el archivo `0-ESTRUCTURA-CURSO.md` en la raíz del curso. Aplica el § Marco común de
`prompts-de-fase.md`, con esta excepción: no sigue la plantilla de diez secciones.

**Qué es:** la fuente de verdad de la estructura **para el lector** — el equivalente legible de
`prompts/propuesta-fases-y-alcance.md`, sin el registro de decisiones ni el material de autoría.

**Qué lleva:**
- Los siete bloques, con el porqué de cada uno en un párrafo.
- La tabla de las veinticinco fases: número, nombre, estilo de código, el reflejo 🪞 que ataca y
  el proyecto que avanza. Sale literal de `propuesta-fases-y-alcance.md` §4.
- Los seis proyectos que atraviesan el curso, con la fase en que nace cada uno (§7 de la
  propuesta).
- Qué está fuera del alcance y por qué, incluidos los tracks opcionales.
- **La regla de forma:** no hay apéndices, y qué hacer cuando algo parezca uno.
- Las dependencias entre fases: qué necesita qué para existir.

**Qué NO lleva:** el registro de decisiones de §10 de la propuesta ni el libro de deudas de
§7.1 —son material de autoría—, ni horas por fase: el curso no las publica (§10.6); publica la
estimación del miniproyecto, de dos a cinco horas.

**Cuidado con:** dejar que se desincronice de la propuesta. Si al escribirlo aparece una
contradicción, se arregla **en la propuesta primero** y aquí después.
````

---

## # `00-convencion-de-git-y-tags.md`

````markdown
Produce el archivo `00-convencion-de-git-y-tags.md` en la raíz del curso. Aplica el § Marco común
de `prompts-de-fase.md`, con esta excepción: no sigue la plantilla de diez secciones.

**Qué es:** el documento que todas las fases enlazan desde su bloque 🏷️ **sin reexplicarlo**.
Corto, operativo, de consulta.

**Qué lleva:**
- Un repositorio para todo el curso, con la estructura de `src/` que fija la Fase 00.
- Commits con el prefijo de la fase: `fase 07: …`, los de ejercicio con su número
  (`fase 07 ej12: …`) y el miniproyecto con el suyo (`fase 07 mini: …`).
- Un tag anotado por fase cerrada: `fase-NN`, con el checklist de la sección 2 en el mensaje.
- Un tag anotado por miniproyecto: `mini-NN`, **con el número de su medición en el mensaje** —
  es donde se recupera después con `git show`.
- Ramas de trabajo con prefijo (`wip/`, `spike/`) para no chocar con los tags.
- Cómo se lee una factura de deuda 💸: `git diff fase-02 fase-09 -- <ruta>`, que es la forma en
  que el curso demuestra lo que costó un atajo.
- **Lo propio de este curso:** el legado y lo nuevo conviven en el mismo repositorio con dos
  runtimes. Di cómo se organizan las soluciones y por qué el tag de una fase mixta 🧬 cubre las
  dos mitades.

**Cuidado con:** enseñar git. El lector lleva años usándolo. Esto es una convención, no un
tutorial: que quepa en una pantalla y media.
````

---

## # `BENCHMARKS.md`

````markdown
Produce el archivo `BENCHMARKS.md` en la raíz del curso, en su versión inicial. Aplica el
§ Marco común de `prompts-de-fase.md` y **sigue `formato-de-mediciones.md` §5 literal**.

**Qué es:** el archivo consolidado de todas las mediciones del curso. **Nace con la Fase 00**,
vacío de resultados pero completo de forma, y cada fase agrega su entrada al cerrarse.

**Qué lleva en su versión inicial:**
- Qué es el arnés y dónde vive el código (lo escribe el miniproyecto de la Fase 00).
- Las siete reglas de honestidad de `formato-de-mediciones.md` §2, resumidas para el lector: el
  competidor defendible, primero SQL y después .NET, el dato realista, el empate publicado, y lo
  no ejecutado declarado con precio, fecha y región.
- El formato de una entrada: hipótesis, condiciones, competidores, tabla, veredicto **con
  umbral**, más la fase que la produjo y la fecha de ejecución.
- Cómo se marca 🪦 una medición que otra posterior contradijo, sin borrarla.
- La tabla de contenidos vacía, con una fila por fase, lista para llenarse.

**Cuidado con:** inventar resultados. En su versión inicial este archivo no tiene ni un número:
los produce cada fase con el arnés en la máquina de quien escribe.
````

---

## # `INSTINTOS.md`

````markdown
Produce el archivo `INSTINTOS.md` en la raíz del curso, en su versión inicial. Aplica el § Marco
común de `prompts-de-fase.md`, con esta excepción: no sigue la plantilla de diez secciones.

**Qué es:** el documento de reflejos recurrentes — la versión consolidada y consultable de todas
las secciones 🪞 del curso. Nace con la Fase 00 y cada fase le agrega el suyo al cerrarse.

**Qué lleva:**
- El reflejo, en una línea, en las palabras en que se le ocurre al lector.
- El código que produce, mínimo.
- Por qué falla **en C#**, y qué se escribe en su lugar.
- **Dónde se rompe el paralelo con Java**, que es la columna que hace útil el documento.
- La fase donde está desarrollado.

**Cómo se organiza:** por familia —tipos, ejecución diferida, asincronía, recursos, datos,
arquitectura— y no por número de fase, porque se consulta buscando un síntoma.

**Y una sección propia de este curso:** los reflejos que **no** son de lenguaje sino de
arquitectura — *reescribámoslo todo*, *no toquemos nada*, *primero refactorizamos y luego
migramos*, *si está viejo está mal*—, que son los caros y los que el veredicto final retoma.

**Cuidado con:** convertirlo en una lista de trucos. Cada entrada explica **por qué el instinto
existía y dónde era correcto**, porque un reflejo que se ridiculiza no se desaprende.
````
