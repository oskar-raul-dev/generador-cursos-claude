# 🧩 Plantillas de capítulo
## Laboratorio de contenedores y Kubernetes local

Los cuatro esqueletos que se copian al abrir una sesión nueva: **fase de plataforma** (F03–F26),
**fase de la Parte 0** (F00–F02), **fase de cierre** (F27) y **apéndice**. Las tres de fase son
rígidas y se siguen literales; la de apéndice es laxa a propósito. El bloque de cada incidente está
en [`formato-cuaderno-incidentes.md`](formato-cuaderno-incidentes.md) §8.

> **Nota de coherencia:** el peso, los ejercicios, los incidentes y las mediciones de cada fase son
> los de [`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md) §11. Si cambian, se cambian
> **allí primero** y aquí después. Las longitudes son las de la
> [guía](guia-de-estilo-y-convenciones.md) §9, y los nombres técnicos, los del
> [contrato del cluster](contrato-del-cluster.md).

---

# 🧩 Plantilla de fase de plataforma — F03 a F26

Copia el bloque, rellena los `{{placeholders}}` y borra las notas entre llaves antes de entregar.

````markdown
# {{emoji}} Fase {{NN}} — {{Tema}}: {{la promesa concreta del documento}}

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase {{NN}} de 27 · Parte {{romano}} — {{nombre de la parte}} · **{{ligera | media | densa}}** {{⭐}}
> **Perfil:** {{minimo | lab}} {{· `medicion` para 📏}} · **Observabilidad encendida:** {{ninguna | métricas, tableros, logs, trazas}}
> **Motor de referencia:** Docker · 🦭 {{dónde diverge Podman, o "no diverge en esta fase"}}
> **Servicios que toca:** {{…}} · **Paso de generación:** {{G… | ninguno}}
> **Depende de:** Fase {{NN-1}} · **Habilita:** Fase {{NN+1}}
> **Incidentes que reserva:** {{IDs | ninguno}} · **Medición:** {{B-NN | ninguna}}
> **Apéndices de apoyo:** {{a01, a04, …}}
> **Fecha de verificación ejecutada:** {{DD/MM/AAAA}} · macOS arm64
> **Objetivo:** {{una frase, verificable}}

---

## 🧭 1. Dónde estamos

{{Qué dejó la fase anterior, en qué estado está el sistema (qué corre, dónde, en qué perfil) y qué
falta. Si la historia tiene una escena para esta fase, va aquí: quién necesita qué y por qué. Prosa,
tres o cuatro párrafos. Si la parte acaba de empezar, se presenta la parte.}}

---

## 🎯 2. Objetivos de esta fase

{{3 a 5 objetivos verificables. "Entender las sondas" no es verificable; "hacer que `inventory` no
reciba tráfico hasta poder atender, y demostrarlo con un rollout sin un solo 503" sí lo es.}}

---

## 🚫 3. Qué NO entra todavía

- {{tema diferido}} → Fase {{M}}.
{{Sin destino, no se difiere: se corta, y si es exclusión del curso se declara sin decir dónde
estaría.}}

---

## 🧨 4. El problema, en el laboratorio

{{El dolor reproducido: el sistema tal como quedó, el cambio que lo rompe o la necesidad que no
puede cubrir, y la salida literal. Aquí se honra lo que el lector ya hacía: por qué funcionaba en
compose, en la VM o en la fase anterior.}}

---

## 🧩 5. {{El mecanismo}}, con `pricing`

{{El grueso de la fase, resuelto completo con el piloto. Regla del andamio en cada concepto: el
problema primero, el objeto o la herramienta después, y el comando con su salida real al final.
Cada campo del YAML con su porqué en un comentario. Si hay tarea del Taskfile, la tarea y lo que
corre debajo la primera vez.}}

> 🩻 **Esto sí funciona igual.** {{Lo que se transfiere sin cambios desde compose o entre motores.}}

**Prueba de fuego.** {{`task conformance -- G…` o un `kubectl` con su salida esperada.}}

**El patrón a memorizar.** {{Una o dos frases con la lección transferible.}}

---

## 🔁 6. Los otros tres: donde no es mecánico

{{Solo las fricciones reales de `inventory`, `catalog` y `replenish` (y de `storefront` si aplica)
al seguir el patrón del piloto. Si en esta fase el patrón se replica sin sorpresas, la sección lo
dice en un párrafo y enlaza a `src/lab/`. Nunca el mismo manifiesto cuatro veces.}}

---

## 🪞 7. Tu instinto de compose dice… y la apuesta

{{El instinto en su mejor versión. Después, la apuesta escrita ANTES de ejecutar y nunca editada,
lo que salió, y el resultado: ganada o perdida, con la prueba delante. Se copia a INSTINTOS.md.}}

> 🪞 **Apuesta antes de ejecutar.** {{predicción concreta, con número si hay medición}}
> **Resultado:** {{…}}

---

## 📏 8. {{La medición | La rotura}}

{{Si la fase tiene medición: el bloque 📏 con los seis datos de la guía §6, la tabla con dispersión
y la conclusión sobre la proporción; la entrada va a BENCHMARKS.md.
Si no la tiene: el experimento 🧨 que falla a propósito, con el cambio exacto, el síntoma literal y
lo que costó salir. Si tiene las dos, van las dos, primero la medición.}}

> 📏 **Medición {{B-NN}} · {{qué}}** · perfil `medicion` · {{motor y versión}} · {{máquina}} ·
> {{n}} corridas · verificado el {{fecha}}
>
> {{tabla}}
>
> Reproducir: `task measure -- {{B-NN}}`

---

## ⚰️ 9. Autopsia: {{la decisión}}

{{Estructura de la guía §2.1: la decisión con su mejor argumento; por qué era razonable; qué pasó
después, con número; cuánto cuesta salir, con número; qué capa, campo o pregunta lo habría
cambiado. Nunca un juicio sobre una persona ni sobre una herramienta.}}

**Antes y después, con números:** {{la misma operación con la decisión mala y con la buena.}}

---

## 📖 10. Traducción

{{Tabla corta en las dos direcciones: compose ⇄ Kubernetes cuando aplica, y 🌩️ local ⇄ nube con la
🚧 frontera de lo que el laboratorio no da. 🦭 si Podman cambia algo. Enlace a a05 para el
diccionario completo.}}

---

## 🩺 11. Incidentes de esta fase

{{Una línea por incidente reservado: el síntoma literal y el enlace a su entrada del cuaderno. La
solución NO va aquí. Si la fase no reserva incidentes, la sección se omite y la numeración sigue.}}

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

{{Las pérdidas con número. Cuándo compose, un contenedor suelto o un servicio del sistema operativo
alcanzaban. Y la pregunta del curso respondida para esta fase, en tres líneas: qué te dio el
contenedor, qué te dio el orquestador, y qué te tocó escribir a ti.}}

---

## ⚠️ 13. Errores comunes y diagnóstico

{{2 a 5 errores que no son incidentes del cuaderno: síntoma → salida literal → causa → comprobación
🩺 → salida.}}

---

## 📋 14. Checklist de validación

```text
[ ] {{comprobación ejecutable, con su comando}}
```

---

## 🧪 15. Ejercicios ({{total}})

{{Guía §10. Agrupados por dificultad con rango y conteo, un tercio de diagnóstico o medición, al
menos uno con un servicio distinto de pricing, cada uno con **Criterio:** verificable. Solución
plegada en 🟢 y 🟡; rúbrica en 🟠 y 🔴.}}

## 🟢 Fácil — {{tema}} (1–{{a}})
## 🟡 Intermedio — {{tema}} ({{a+1}}–{{b}})
## 🟠 Difícil — {{tema}} ({{b+1}}–{{c}})
## 🔴 Muy difícil — {{tema}} ({{c+1}}–{{total}})
## 🔥 Opcionales

---

## 📚 16. Referencias

**Documentación oficial** {{de la versión de a01}}
**Especificaciones y libros** {{por la edición fijada en la guía §11}}
**Charlas y tutoriales** {{con duración}}
**Orden de lectura sugerido:** {{antes de empezar → durante → después}}

> ⚠️ {{Las URL y los contenidos cambian; adviértelo si el enlace no es de la versión del curso.}}

---

## 🏁 17. Resultado de la fase

{{Qué queda construido y en qué estado, en diagrama o bloque text: qué corre, dónde y en qué
perfil.}}

> **La señal de que quedó bien:** {{criterio en forma de cita.}}

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, la suite del paso pasando y
> `git status` limpio:
>
> ```bash
> git tag -a fase-{{NN}}-{{slug}} -m "F{{NN}} cerrada: {{el checklist en una línea por ítem}}"
> ```
>
> Commits de la fase con prefijo `f{{NN}}:`, los de ejercicio `f{{NN}} ej17: …`.

---

## 📌 Pendientes sugeridos

{{Material de autoría. Lo que apareció al escribir y no cabía, con destino explícito.}}
````

---

## Recordatorios al rellenar una fase de plataforma

- **Peso, ejercicios, incidentes y medición de la propuesta §11**, longitud de la guía §9. No se
  improvisan.
- **Nada sin ejecutar.** Cada salida es literal y está fechada.
- **El problema va antes que el mecanismo**, y se reproduce en el laboratorio, no se cuenta.
- **`pricing` primero; los otros tres solo donde no es mecánico.**
- **El paso de generación de la fase llega en esta fase y no antes**, y su suite pasa al cerrar.
- **Los tres documentos vivos se alimentan al cerrar**: `BENCHMARKS.md`, `INSTINTOS.md` y los
  incidentes completos en `cuaderno-incidentes.md`.
- **Los apéndices que crecen reciben su parte en la misma tanda**: `a03` (prompts del paso), `a04`
  (lo que se estrenó de `kubectl`), `a05` (las filas de traducción).
- **Ningún `README.md` se toca, ni se crea `0-ESTRUCTURA-CURSO.md`**, al cerrar una fase.
- 🗑️ **No se cita nunca** un archivo `_desechable-*`, ni un documento de `prompts/`.

---

# 🧰 Plantilla de fase de la Parte 0 — F00 a F02

No tienen el aparato de apuesta y autopsia: son de manos en la masa. Rígida igual: se sigue literal,
y solo la sección 4 cambia de contenido según la fase.

````markdown
# {{emoji}} Fase {{NN}} — {{la promesa concreta del documento}}

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase {{NN}} de 27 · Parte 0 — Prolegómenos · **media**
> **Plataformas:** Windows 11 con WSL 2 · macOS Apple Silicon · Linux amd64
> **Motor de referencia:** Docker · 🦭 {{…}}
> **Servicios que toca:** {{ninguno | la Braqui | el patrimonio y los cinco nuevos}} · **Paso de generación:** {{— | G0}}
> **Depende de:** {{nada | Fase NN-1}} · **Habilita:** Fase {{NN+1}}
> **Incidentes que reserva:** {{01–04 y 27 | ninguno}}
> **Apéndices de apoyo:** {{a01, a02, a16 | a03, a16}}
> **Fecha de verificación ejecutada:** {{DD/MM/AAAA}} · macOS arm64 · Windows 11 y Linux: no verificados por el autor
> **Objetivo:** {{una frase, verificable}}

---

## 🧭 1. Dónde estamos
{{En F00: por qué existe este curso, la pregunta que lo ordena, a quién le habla, la empresa en una
página y el sistema que se va a construir. En F01 y F02: qué dejó la fase anterior.}}

## 🎯 2. Objetivos de esta fase
## 🚫 3. Qué NO entra todavía

## {{emoji}} 4. {{El grueso de la fase}}

{{F00: los dos motores instalados y conviviendo en las tres plataformas, con su validación y la
forma de alternar; la fecha de verificación visible. F01: los tres sustantivos, los verbos del día a
día, el primer Dockerfile de un solo stage con `pricing`, CMD contra ENTRYPOINT, puertos, volúmenes,
de dónde salen las imágenes y la limpieza del disco. F02: compose con los cinco servicios del paso
G0, la suite de conformidad corriendo contra compose, el contrato congelado y el calendario de las
tres oleadas.}}

## 🩻 5. Lo que ya sabías y sigue valiendo
{{Lo que el lector trae de su trabajo y se transfiere sin cambios. En F02, compose como herramienta
buena para lo que es: la crítica llega en la Fase 06.}}

## 🩺 6. Incidentes y errores comunes
{{En F00: los cuatro incidentes de ambiente, con su síntoma y el enlace al cuaderno, más los errores
menores. En F01 y F02: errores comunes con su salida literal.}}

## 📋 7. Checklist de validación
## 🧪 8. Ejercicios (20)
{{Guía §10, con Criterio verificable en cada uno.}}

## 📚 9. Referencias
## 🏁 10. Resultado de la fase

> **La señal de que quedó bien:** {{criterio en forma de cita.}}

> 🏷️ **Tag:** `fase-{{NN}}-{{slug}}` · prefijo de commit `f{{NN}}:`
````

---

# ⚖️ Plantilla de fase de cierre — F27

No introduce mecanismos: decide con lo que ya se midió y encarga el proyecto final. Su evidencia es
`BENCHMARKS.md`, y su entregable principal es el proyecto que el lector construye.

````markdown
# ⚖️ Fase 27 — {{la promesa concreta}}

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 27 de 27 · Cierre · **densa**
> **Evidencia:** BENCHMARKS.md, entradas {{B-NN…}} · INSTINTOS.md · cuaderno-incidentes.md
> **Depende de:** Fase 26 · **Habilita:** el proyecto final
> **Fecha de verificación ejecutada:** {{DD/MM/AAAA}}
> **Objetivo:** {{una frase, verificable}}

---

## 🧭 1. Dónde estamos
{{Lo que el lector construyó, en un diagrama, y la pregunta que el curso se ganó el derecho a hacer.}}

## 🎯 2. Objetivos de esta fase
## 🗂️ 3. La evidencia
{{Qué mediciones e instintos sostienen cada rama del veredicto, y qué no se midió.}}

## ⚖️ 4. El árbol de decisión honesto
{{¿Lo resolvía un contenedor y un servicio del sistema? ¿Compose en una máquina? ¿Dos servidores y
una lista de comprobación? ¿De verdad necesitas un orquestador? Cada rama con su número.}}

## 🌩️ 5. El diccionario local ⇄ nube, consolidado
{{En las dos direcciones, con la 🚧 frontera de lo que el laboratorio nunca pudo dar. Enlaza a a05.}}

## 🏗️ 6. El proyecto final
{{El encargo completo: el servicio nuevo, su contrato, su imagen, su subchart, sus sondas, sus
límites, sus métricas, su HTTPRoute y su papel en la saga. Los criterios de aceptación, todos
ejecutables: la suite de conformidad, el tablero, un rollout sin cortes, un incidente provocado y
diagnosticado.}}

## ⚠️ 7. Errores comunes
{{De criterio: el orquestador por reflejo, la medición única como argumento.}}

## 📋 8. Checklist de validación
## 🧪 9. Ejercicios (12)
{{De criterio y decisión: sistemas descritos, elegir la capa y defenderla con número.}}

## 📚 10. Referencias
## 🏁 11. Resultado del curso

> **La señal de que quedó bien:** {{criterio en forma de cita.}}

> 🏷️ **Tag:** `fase-27-{{slug}}` · prefijo de commit `f27:`
````

---

# 📎 Plantilla de apéndice

Laxa a propósito. Lo que comparten todos: encabezado, índice, secciones cortas con ejemplo mínimo,
tabla de decisión o de referencia, referencias y ejercicios.

````markdown
# 📎 Apéndice {{aNN}} — {{Nombre}}

> **Curso:** Laboratorio de contenedores y Kubernetes local · {{De laboratorio | Consulta | 🔥 Ampliación}}
> **Usado por:** {{fases}} · **Versiones cubiertas:** las de a01
> {{**Memoria que suma al perfil `lab`:** {{medida}} — solo en los 🔥 que instalan algo}}
> **Fecha de verificación ejecutada:** {{DD/MM/AAAA}} · {{plataformas}}

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale.
{{Una línea sobre qué problema resuelve.}}

**Qué queda fuera:** {{lo que no cubre; si es una exclusión del curso, sin decir dónde estaría.}}

---

## Índice
- [{{Sección 1}}](#)
- [Cuándo usar qué](#)
- [Referencias](#)

---

## {{Sección}}
{{Secciones cortas que responden a UNA pregunta, ejemplo mínimo ejecutable, nombres del contrato.}}

## 🧭 Cuándo usar qué
| {{Situación}} | {{Opción}} | {{Por qué}} |
|---|---|---|

## ⚠️ Advertencias
## 📚 Referencias
## 🧪 Ejercicios ({{los de la propuesta de apéndices}})

---

> 🏷️ **Este apéndice no lleva tag propio.** {{Variante excepcional, solo para a01, a03 y a16, que dejan
> archivos en el repositorio: el commit se etiqueta `apendice-{{aNN}}-{{slug}}`.}}
````

## Recordatorios al rellenar un apéndice

- **No lleva peso** y no cuenta como camino base.
- **Ningún `README.md` se toca**, tampoco los de `src/`: se escriben en su tanda final y aparte.
- **No repite lo que explica una fase: enlaza.**
- **Los 🔥 declaran la memoria que suman** y qué apagar para que entren.
- **Antes de escribir, confirma tres cosas:** qué versiones se cubren (las de `a01`), qué fases ya
  están escritas a esa altura, y qué queda fuera.
