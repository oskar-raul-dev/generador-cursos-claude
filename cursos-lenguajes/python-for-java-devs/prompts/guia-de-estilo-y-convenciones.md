# ✍️ Guía de estilo, tono y convenciones de código
## Python para desarrolladores Java senior

Esta guía es la fuente de verdad editorial del curso. Cualquier chat que produzca un `.md` la
sigue. Su objetivo es simple: que todos los documentos se lean como escritos por la misma
mano, con la misma voz y el mismo criterio, y que todos apunten al mismo lugar — **que el
lector aprenda a elegir el registro correcto y a defender la elección con números.**

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que mañana
tiene que decidir, solo y sin comité, si esto se escribe en un archivo de cuarenta líneas o en
un proyecto.

> ✅ **Estado (13/09/2026).** Esta guía ya no describe un curso por escribir: describe uno escrito.
> Las **18 fases (00–17)** están publicadas y son el mejor ejemplo de cada regla de abajo — ante una
> duda que el texto no resuelva, gana lo que hagan las fases ya redactadas, y la regla se corrige
> aquí después.

> 🍽️ **Y el material a la carta.** Las secciones opcionales
> (`propuestas-temas-opcionales.md`) siguen esta guía **completa en lo editorial** —voz, tuteo,
> código en inglés con comentarios en español, analogías con su límite, ninguna comparación sin
> número— y **la relajan en lo estructural**: no llevan plantilla de diez secciones, ni miniproyecto
> obligatorio, ni medición obligatoria, ni las 25 ejercicios de una fase. Tampoco tienen que pasar
> por Áurea: una sección de la carta puede usar su propio ejemplo si le sirve mejor al tema. Las que
> sí aterrizan en Áurea son las que se escriben primero.

---

## 1. Principio rector

**Todo lo que se escribe apunta a una decisión de registro.**

No enseñamos Python "bonito". No formamos pythonistas devotos. Formamos criterio para mirar un
encargo y decir *"esto es un script y va a seguir siéndolo"*, *"esto ya no cabe en un archivo"*
o *"esto no debiste sacarlo de Java"*, y sostener cualquiera de las tres con el costo de las
otras dos en la mano.

El filtro para cada párrafo es este: **¿esto ayuda a decidir, a medir o a ejecutar?** Si no,
sobra. Aunque esté muy bien escrito. Sobre todo si está muy bien escrito.

Y hay un segundo filtro, específico de este perfil: **¿el lector ya lo sabe?** Un dev Java
senior sabe qué es una excepción, un mapa, una transacción y un contenedor. Explicárselo no es
generosidad, es ruido.

---

## 2. Tono

El tono es **semiformal, colegial y directo** — senior a senior, con humor cuando cae bien.
Piensa en un colega que hizo este cruce hace tres años, se equivocó lo suficiente, y te lo
cuenta sin solemnidad y sin venderte nada.

Cómo se ve eso en la práctica:

- **Tuteo latinoamericano, siempre.** *"Mide tu bucle antes de vectorizarlo."* Nada de voseo
  (*"medí"*, *"fijate"*), nada de "usted", nada de impersonal permanente ("se debe medir…")
  que enfría el texto.
- **Semiformal.** Cercano, pero no chat de WhatsApp. Frases completas, puntuación correcta,
  cero abreviaturas de mensajería.
- **Humor seco y con moderación.** Un 😉 bien puesto, un chiste sobre las dos horas que
  perdiste porque tu `venv` no estaba activado. Regla práctica: **máximo un chiste por
  sección**, y si no fluye solo, se borra.
- **Honesto sobre el costo.** Cada opción gana en algo y pierde en algo, y las pérdidas se
  dicen con número: *"`multiprocessing` te da 3.4× en este trabajo y te cuesta 180 ms de
  arranque por proceso y la serialización de todo lo que cruce la frontera"*.
- **Sin evangelismo, en ninguna dirección.** Ni *"Python es más productivo"* ni *"esto en Java
  sería más robusto"* sin la medición delante. El curso no tiene equipo.
- **Colegial sin condescendencia.** El lector es senior. Acompáñalo en la fricción, no le
  expliques HTTP.
- **Orientado a la duda real.** Anticipa el *"¿y esto por qué se hace así?"* y respóndelo,
  muchas veces con una 📝 **Nota de ecosistema** que dé el contexto: qué versión trajo esa
  API, qué reemplazó, y por qué lo anterior sigue vivo en medio internet.

Lo que evitamos: promesas vacías ("vas a dominar Python"), motivación de coach, solemnidad de
manual, y explicar lo obvio para el perfil.

---

## 3. Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no es código: títulos,
  explicaciones, ejercicios, referencias, callouts.
- **Los términos del ecosistema se quedan en inglés** cuando son el nombre real de la cosa:
  *type hint*, *dataclass*, *context manager*, *generator*, *wheel*, *entry point*,
  *free-threading*, *virtual environment*. Traducirlos forzadamente ("gestor de contexto",
  "rueda") confunde más de lo que aclara y no es lo que van a leer en la documentación.
- **Markdown siempre.** Nada de HTML embebido salvo que no haya alternativa.
- **Prosa antes que listas.** Un párrafo que explica *por qué* vale más que cinco viñetas que
  enumeran *qué*. Las listas se usan cuando la cosa es de verdad una lista — pasos
  secuenciales, ítems paralelos, opciones.
- **Listas antes que tablas en comparativas extensas.** Para comparar tres bibliotecas o
  cuatro estrategias, una lista con subtítulos. Una tabla de siete columnas se lee mal en
  pantalla, peor en móvil, y no deja espacio para explicar el porqué de cada celda.

  Formato recomendado para comparativas:

  ```markdown
  **Opción B — `multiprocessing` con `Pool`**

  Qué es: procesos reales, sin GIL compartido, memoria separada.
  Cuándo conviene: trabajo CPU-bound de más de ~200 ms por unidad.
  El costo: arranque por proceso, y todo lo que cruza la frontera se serializa.
  Veredicto: gana en la conciliación de ventas; pierde en cualquier cosa que toque disco.
  ```

- **Tablas solo para lo que de verdad es tabular y corto.** Versiones fijadas, mapeo
  concepto ⇄ concepto, matriz de decisión, tres columnas como máximo. Si necesitas explicar
  una celda, ya no es una tabla: es una lista.
- **Encabezados con emoji, con moderación.** Uno por sección de la plantilla. Un documento que
  parece un teclado de emojis pierde autoridad.

---

## 4. Pedagogía: cómo se explica

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar la herramienta, muestra el dolor que resuelve.
   *"Patricia tiene ocho archivos con las columnas en otro orden cada mes. Puedes escribir un
   parser por archivo y mantener ocho, o puedes…"*
2. **La herramienta después.** El nombre y la definición mínima: lo justo para usarla hoy, no
   el capítulo completo de la documentación.
3. **El código que corre.** El fragmento más pequeño que demuestra el punto, con comentarios
   que explican el porqué.

Presentar la herramienta antes que el problema produce gente que sabe escribir un generador
pero no sabe cuándo hace falta.

### 4.2 La traducción desde Java: una vez, y después se abandona

Un `dataclass` es primo de un `record`; un `Protocol` es un `interface` que nadie declara
implementar; un context manager es `try-with-resources`; `pytest` con fixtures no es JUnit con
`@BeforeEach` aunque lo parezca.

Dos límites, y los dos son estrictos: la analogía se usa **una vez, para abrir la puerta**, y
después se abandona; y **se dice explícitamente dónde se rompe**, que es donde está la
lección. *"Hasta acá el paralelo con `record` funciona. La diferencia es que un `dataclass` es
mutable salvo que lo congeles, y que su igualdad la decides tú campo por campo."*

Una analogía que no declara dónde se rompe es peor que ninguna: deja al lector confiado en un
modelo mental que va a fallarle en producción.

### 4.3 Explica el porqué, no solo el cómo

Cada decisión relevante lleva su porqué, aunque sea media línea entre paréntesis. Y cuando el
porqué es histórico —que en Python pasa seguido—, se dice también: *"esto está así porque
antes de 3.9 no había otra forma, y el código que vas a encontrar en internet sigue
escribiéndose así"*.

### 4.4 Densidad calibrada

- Un concepto nuevo por vez. Si un bloque de código introduce tres cosas desconocidas, se
  parte en tres bloques.
- Repetir lo importante está bien. Los conceptos que sostienen el curso —los tres registros,
  la frontera, qué se mide y contra qué— pueden reaparecer varias veces con otras palabras.
- **Ninguna sección teórica supera las dos pantallas sin que aparezca código.**

### 4.5 Cierra los bucles

Si abres un paréntesis pedagógico —*"esto lo vemos cuando el script deje de caber"*, *"acá
dejamos deuda 💸"*— tiene que cerrarse en algún documento del curso. Un 💸 sin fase de cobro es
un error de escritura, no una licencia.

### 4.6 La regla de la medición

> 🧭 **Ninguna afirmación comparativa entra al curso sin un número producido por el arnés del
> curso.** Ni "más rápido", ni "más liviano", ni "arranca antes", ni "sale más barato".

Si la medición todavía no existe, hay dos salidas honestas: escribirla, o escribir la frase
sin el comparativo. Lo que no se hace es afirmar y prometer el número para después.

Y la medición incluye **siempre al competidor de verdad**, no a un espantapájaros: si se
compara contra el stack de origen, se compara contra una implementación que alguien
defendería en una revisión de código.

---

## 5. Idioma del código fuente

> **Regla normativa y no negociable: todo el código fuente del curso se escribe en inglés
> —variables, funciones, clases, módulos, archivos, endpoints, constantes— y todos los
> comentarios y docstrings se escriben en español, con tildes.** Aplica a cada fragmento del
> curso, sin excepción: fases, miniproyectos, ejercicios resueltos, pruebas, migraciones,
> `Dockerfile` y scripts de shell.

La razón es la misma de siempre: el vocabulario que el lector practica durante meses tiene que
ser el que va a leer en producción, y ningún equipo escribe `calcular_regalias()`.

Y la contraparte importa igual: **los comentarios van en español** porque son el canal donde
se explica el *porqué* de una decisión, y ese razonamiento se lee en el idioma en que se
piensa el curso. Un comentario en inglés es un error de estilo aunque el código sea impecable.

**Los mensajes de error y de log van con los comentarios, no con el código.** Un
`raise ValueError(...)`, un `logger.warning(...)` o el detalle de un `422` son texto dirigido a
otro desarrollador: **en español, con tildes**. Los identificadores que los rodean siguen en
inglés.

### 5.1 Diccionario mínimo del dominio

Áurea es una red odontológica, y el dominio tiene que significar lo mismo en todo el curso:

- paciente → `patient`
- sede → `branch`; franquicia → `franchise`; franquiciado → `franchisee`
- cita → `appointment`; inasistencia → `no_show`
- tratamiento → `treatment`; **plan integral → `treatment_plan`**
- fase del plan → `phase` (`diagnosis` · `orthodontic` · `periodontal` · `restorative` ·
  `retention`)
- aliado externo → `partner`; remisión → `referral`; comisión → `referral_fee`
- odontólogo → `dentist`; especialidad → `specialty`
- factura → `invoice`; glosa → `claim_objection`; cartera → `receivables`
- regalía de franquicia → `royalty`; liquidación → `settlement`
- laboratorio dental → `lab`; pedido al laboratorio → `lab_order`
- aseguradora / prepagada → `insurer`; cobertura → `coverage`

Los nombres de funciones se arman combinando estos términos con los verbos habituales: `get`,
`fetch`, `build`, `validate`, `settle`, `reconcile`, `issue`, `refer`.

> ⚠️ **`plan` a secas está prohibido** como identificador. En este dominio "plan" significa
> tres cosas distintas —el plan de tratamiento, el plan de pagos y el plan de una prepagada— y
> el curso las va a nombrar en el mismo párrafo. Siempre `treatment_plan`, `payment_plan` o
> `coverage_plan`.

### 5.2 Convenciones de nombrado

Las de PEP 8, sin creatividad: `snake_case` para funciones, métodos, variables y módulos;
`PascalCase` para clases; `SCREAMING_SNAKE_CASE` para constantes; `_prefijo` para lo privado
por convención. Archivos y paquetes en `snake_case`, sin guiones.

El punto donde este perfil se equivoca por reflejo, y que conviene vigilar en cada revisión:

- **Nada de `Manager`, `Helper`, `Util`, `Impl` ni `AbstractBase`.** Si el nombre no dice qué
  hace, el problema es el diseño, no el nombre.
- **Nada de una clase con un solo método.** Eso es una función. Es el reflejo más común y el
  que más ruido produce.
- **Los módulos son el paquete.** No hace falta una clase para agrupar funciones: el módulo ya
  es el espacio de nombres.

---

## 6. El estilo de código del curso

Aquí está la tentación grande, y en este curso tiene dos caras: escribir Python con
estructura de Java porque es lo que el lector sabe, o escribir Python "avanzado" —metaclases,
descriptores, decoradores de decoradores— porque impresiona. Las dos son falsas.

### 6.1 La regla que ordena todo

> 🧭 **El código se escribe en el registro de su fase.** Un script del Bloque A se escribe como
> un script: sin clases, sin capas, sin `main()` ceremonioso, sin dependencias. Una aplicación
> del Bloque C se escribe como una aplicación: con tipos, pruebas, configuración y frontera.
> Escribir una aplicación en el Bloque A es el error que el curso está enseñando a no cometer,
> y no se comete por descuido en el propio material.

El corolario, que es lo que el lector se lleva: **el registro no es una preferencia de estilo,
es una decisión de diseño, y se equivoca en las dos direcciones.**

### 6.2 Qué significa "estilo de script" (Bloque A)

- **Un archivo. Stdlib pura. Cero dependencias.** Ni siquiera para parsear una fecha.
- Funciones sueltas a nivel de módulo, y el trabajo bajo `if __name__ == "__main__":`.
- `argparse` para la interfaz, `pathlib` para rutas, códigos de salida que signifiquen algo.
- Errores que se propagan y matan el proceso con un mensaje útil, en vez de una jerarquía de
  excepciones propias.
- Tipos donde ayudan a leer, no como obligación.

Nada de esto es descuido: es el registro. El curso lo dice en voz alta cada vez que lo usa.

### 6.3 Qué significa "estilo de proyecto" (Bloques B y C)

- Layout `src/`, `pyproject.toml`, entorno declarado y reproducible.
- **Tipado estricto**, verificado en CI, con `Protocol` para las fronteras y sin `Any` como
  escape.
- `pytest` con fixtures de verdad, parametrización y dobles donde corresponda.
- `dataclasses` —o `Pydantic` cuando el dato viene de afuera y hay que validarlo— en vez de
  diccionarios anónimos que se pasan entre capas.
- `logging` configurado, no `print`.
- Errores del dominio como excepciones propias, con jerarquía mínima y mensajes en español.

### 6.4 Lo pythónico que este perfil no escribe solo

Cada uno de estos aparece cuando corresponde, y **siempre con su contraejemplo en el estilo
que el lector habría escrito**, porque la lección está en la comparación:

- **Iteradores y generadores** en vez de construir listas completas. Es la diferencia entre
  procesar un archivo de 500.000 filas y quedarse sin memoria.
- **Comprehensions** donde son más legibles, y `for` cuando no lo son. La comprehension de
  cuatro cláusulas anidadas es peor que el bucle.
- **EAFP sobre LBYL.** `try/except` en vez de comprobar antes. Es contra-instintivo para quien
  viene de checked exceptions y tiene una razón concreta: entre la comprobación y el uso, el
  mundo cambia.
- **Context managers** para todo lo que se abre y se cierra, incluidos los propios.
- **Desempaquetado, `enumerate`, `zip`, `itertools`** en vez de índices manuales.
- **Funciones de primera clase y decoradores** en vez de la clase con un solo método.
- **`dataclass` y `Protocol`** en vez de la jerarquía de herencia.

### 6.5 Tipado: gradual, pero no opcional

`ruff` corre desde el primer archivo del curso. El verificador de tipos corre en modo estricto
desde la fase que lo introduce, y **no se apaga nunca**, ni en un ejercicio ni para simplificar
un ejemplo.

Dos consecuencias que se escriben siempre igual:

- **`Any` está prohibido en el código del curso.** Donde el tipo no se conoce se usa `object`
  y se estrecha, o se define un `Protocol`.
- **`Optional` significa algo.** `validUntil: date | None` es "vigente indefinidamente";
  omitir el campo sería "no me molesté en decidirlo", y eso no entra al curso.

> 📝 **Y la nota honesta que acompaña a todo esto:** el tipado de Python no es el del
> compilador de Java. No hay garantía en tiempo de ejecución, el verificador es una herramienta
> aparte que alguien tiene que correr, y las bibliotecas que consumes pueden mentirte. El curso
> lo dice donde corresponde en vez de fingir equivalencia.

### 6.6 Fechas, dinero y zona horaria

Zona horaria explícita siempre: `datetime` con `tzinfo`, nunca un `datetime.now()` suelto
donde importe el día. Áurea opera en nueve husos y liquida por mes natural contra plataformas
que reportan en semanas ISO; ese conflicto es material del curso, no un detalle.

El dinero es `Decimal`, nunca `float`. Una cuota de un plan de veinticuatro meses que se
reparte entre tres profesionales es exactamente donde el error de redondeo se vuelve una
discusión con un franquiciado.

---

## 7. Marcadores y callouts

Vocabulario visual compartido por todos los documentos.

### 7.1 Marcadores de estado

- 💸 **Deuda técnica intencional.** Un atajo que se deja a propósito, declarando qué sería lo
  correcto y **en qué fase se paga**. Un 💸 sin destino es un error de escritura.
- 🔥 **Opcional o ampliación.** Secciones y ejercicios fuera del camino base.
- ⭐ **Pieza central.** Las fases de las que depende la tesis del curso.
- 🧱 **Miniproyecto.** Marca la sección obligatoria de cierre de cada fase.
- 📏 **Medición.** Marca un número producido por el arnés del curso, con sus condiciones.
- 🟢🟡🟠🔴 **Dificultad de ejercicios.** En este curso el piso está más arriba que en otros:
  ver §9.
- 🏷️ **Tag de progreso.** El recordatorio de cerrar la fase en git. Va una sola vez por
  documento, al final.
- 🪦 **Pendiente cerrado.** Un 📌 que se resolvió: se marca así en vez de borrarlo, con dónde
  quedó la respuesta.
- 🧨 **Rompe a propósito.** Un experimento destructivo con resultado observable.

### 7.2 Callouts en blockquote

- 📝 **Nota de ecosistema.** Qué versión trajo esta API, qué reemplazó, y por qué lo anterior
  sigue vivo en el código que el lector va a encontrar por ahí.
- 📚 **Referencia rápida inline.** El enlace útil justo donde nace la duda.
- ⚠️ **Advertencia.** Algo que rompe si lo ignoras.
- 💡 **Truco o atajo** que ahorra tiempo real.
- 🧭 **Regla del curso.** Una decisión que aplica en todo el material y que el lector debería
  poder citar de memoria al terminar.
- ⚖️ **Veredicto.** Dónde esto pierde, y contra qué.

### 7.3 Secciones narrativas recurrentes

Micro-secciones con nombre fijo, que aparecen cuando el contenido las pide. Las cuatro
primeras son las secciones insignia del curso y **son obligatorias donde la fase las pida**:

- 🪞 **"Tu instinto de Java dice… y esta vez se equivoca."** El reflejo concreto, el código que
  produce, por qué falla aquí, y qué se escribe en su lugar. Es la sección insignia del curso.
- 🩻 **"Esto sí funciona igual."** Lo que se transfiere sin cambios. Importa tanto como lo
  anterior: sin ella, el lector desconfía de todo su oficio.
- ⚰️ **Autopsia de anti-patrón.** Un mal uso recurrente con su costo en números antes y
  después.
- 📖 **Diccionario de traducción.** Concepto ⇄ concepto, en las **dos** direcciones.
- **Detalles con intención.** Lista corta con las decisiones deliberadas de un bloque de
  código y su porqué.
- **El patrón a memorizar.** Una o dos frases que destilan la lección transferible.
- **Prueba de fuego.** Verificación concreta: qué ejecutar, qué esperar, y qué mentira te va a
  contar la salida si miras el lugar equivocado.
- **La señal de que quedó bien.** En el cierre, un criterio en forma de cita.

---

## 8. Plantilla obligatoria de cada fase (10 secciones)

Toda fase produce un `.md` con exactamente estas diez secciones, en orden. El esqueleto
rellenable está en [`plantillas-de-capitulo.md`](plantillas-de-capitulo.md).

1. **🎯 Propósito** — qué resuelve la fase y a qué decisión sirve.
2. **✅ Qué queda listo al terminar** — checklist verificable, no promesas.
3. **🚫 Qué NO entra todavía** — qué se difiere y a qué fase exacta.
4. **🧠 Concepto mínimo** — la teoría justa, anclada al dominio. Aquí caben 🪞, 🩻, 📖 y las
   📝 Notas de ecosistema.
5. **💻 Código mínimo con comentarios** — el grueso. Código ejecutable, identificadores en
   inglés, comentarios en español, escrito en el registro de la fase.
6. **📏 Medición** — el número que esta fase produce, con sus condiciones y su veredicto.
   Formato y reglas de honestidad en [`formato-de-mediciones.md`](formato-de-mediciones.md). Las
   fases que no midan nada lo dicen en una línea y explican por qué.
7. **🧱 Miniproyecto** — obligatorio, uno por fase. Formato en
   [`formato-de-miniproyectos.md`](formato-de-miniproyectos.md).
8. **🧪 Ejercicios** — ver §9.
9. **📚 Referencias** — ver §10.
10. **🚀 Cierre** — qué sigue, por qué, La señal de que quedó bien y el recordatorio 🏷️ del
    tag.

Después de la décima, y fuera de lo que lee el lector, cada fase cierra con **📌 Pendientes
sugeridos**: lo que apareció al escribirla y no cabía adentro, con destino explícito. Es
material de autoría, no de lectura.

> 🧭 **No hay plantilla de apéndice porque no hay apéndices.** Es la decisión de forma del
> curso y está en `alcance-del-proyecto.md` §6. Cuando aparezca material que "sería un buen
> apéndice", los destinos legítimos son tres: sección de esta fase, fase propia, o 📌.

### 8.1 El recordatorio del tag, en el cierre

Toda fase termina con un bloque 🏷️ de forma fija, después de La señal de que quedó bien y
antes del `---` que abre los 📌:

````markdown
> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde,
> el miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-07 -m "F7 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 07: …`), los de ejercicio su número
> (`fase 07 ej12: …`) y el miniproyecto el suyo (`fase 07 mini: …`). El miniproyecto
> terminado lleva además su propio tag anotado, `mini-07`, cuyo mensaje incluye el
> número que arrojó su medición.
````

El nombre del tag es **`fase-` + el número de dos dígitos**, no el slug del archivo. El tag
`mini-NN` existe porque un miniproyecto es un entregable comparable entre lectores: el mensaje
del tag es donde vive su número, y `git show mini-07` es la forma de recuperarlo.

---

### 8.2 Nombres de archivo y tags: las tres convenciones del curso

El curso tiene **tres clases de material** y una convención de nombre para cada una. No son
variantes de nada externo —el curso es autocontenido, `alcance-del-proyecto.md` §0—: son las
convenciones del curso, y esta tabla es su definición.

| | Camino base | Complementos `ia` y `ds` | Carta opcional |
|---|---|---|---|
| Archivo | `NN-tema.md` — `07-cuando-deja-de-ser-un-script.md` | `<tt>NN-<slug>.md` — `ia01-el-modelo-de-acceso-de-un-llm.md` | `opNNN-<tt>NN-<slug>.md` — `op065-ui02-gradio.md` |
| Apéndices | **No aplica**: el curso no tiene apéndices | **No aplica** | **No aplica** |
| Código | `src/<nombre del documento>/` | Igual: `src/ia01-el-modelo-de-acceso-de-un-llm/` | Igual: `src/op065-ui02-gradio/` |
| Tags | `fase-NN` y `mini-NN` | `ia-fase-NN` y `ia-mini-NN` · `ds-fase-NN` y `ds-mini-NN` | `op-<tt>-fase-NN` y `op-<tt>-mini-NN` |
| Commits | `fase NN: …`, `fase NN ejMM: …`, `fase NN mini: …` | `ia 01: …`, `ia 01 ejMM: …`, `ia 01 mini: …` | `op ui02: …`, `op ui02 ejMM: …` |
| Plantilla, 📏 y 🧱 | Obligatorios | **Obligatorios, igual que una fase base** | Guía, no molde; no se exigen |

**Las dos propiedades que estas convenciones compran**, y que son la razón de que sean tres y no
una:

- **El camino base se lista contiguo.** Los dígitos ordenan antes que las letras, así que `00-` a
  `17-` quedan juntos y arriba, sin que ningún material posterior se intercale. Los dos documentos
  de encuadre que el lector abre antes de empezar —`00-convencion-de-git-y-tags.md` y
  `00-historia-de-aurea.md`— llevan el mismo `00-` y **el orden alfabético los deja delante de la
  Fase 00**, que por eso se llama `00-instalacion-ambiente-editores-y-ecosistema.md`: el nombre
  del archivo reproduce el orden de lectura sin necesidad de un índice. Y `d` < `i` < `o`
  pone después los complementos y al final la carta, en el orden en que se escribieron.
- **Cada índice de tags es limpio.** `git tag -l 'fase-*'` devuelve exactamente el camino base;
  `'ia-*'` y `'ds-*'`, cada complemento; `'op-*'`, la carta entera. Un solo espacio de nombres
  habría mezclado las tres cosas en la misma consulta.

**Por qué los complementos no llevan `op`.** Los tracks `ia` y `ds` construyen los cuatro
proyectos de IA y datos de Áurea —NormaRAG, Recepción asistida, Embudo y Ausentismo— sobre el
código del camino base, con su medición y su miniproyecto. Son la continuación del curso, no un
catálogo de tutoriales sueltos, y esconderlos entre cien platos de la carta habría borrado esa
diferencia. La decisión completa, con su costo, está en `propuestas-fases-base-ia-datos.md` §0.

**Y por qué la carta lleva tres dígitos delante.** Con un prefijo por track —`ar01-`, `cl01-`,
`db01-`— y veinte tracks proyectados, los archivos se intercalan por el azar alfabético de sus dos
letras y el bloque opcional deja de ser un bloque. El `opNNN-` lo mantiene contiguo **y** añade lo
que un catálogo necesita y un conjunto de tracks sueltos no da: orden de publicación en el nombre.

**El costo, dicho entero:** tres convenciones en vez de una, y alguien que llegue nuevo tiene que
leer esta tabla para entenderlas. Se acepta porque las tres marcan tres cosas distintas
—obligatorio, complementario y suelto— y colapsarlas habría borrado justo esa distinción. El
número global de la carta, además, **no se puede deducir** del track ni del tema: hay que
consultarlo antes de crear un archivo.

📝 En prosa, toda sección fuera del camino base se cita corta —`ia04`, `ds03`, `ui02`, `db06`—.
El prefijo largo es del archivo, no del nombre de la sección. El detalle de la numeración de la
carta vive en [`propuestas-temas-opcionales.md`](propuestas-temas-opcionales.md) §2.

---

## 9. Ejercicios

- **Cantidad: 20 mínimo, 25 ideal por fase.** Es una banda deliberadamente estrecha: el curso
  invierte en el **miniproyecto** el esfuerzo que de otro modo iría en volumen de ejercicios,
  porque para este perfil la unidad de práctica útil es un encargo completo y no un ejercicio de
  rellenar huecos.
- **El piso de dificultad está más arriba.** Para un dev Java senior, un 🟢 no es "copia el
  ejemplo": es "aplica lo de la fase a un caso que no está resuelto en el texto". La escala
  completa está calibrada para ese lector:

  | | Qué significa **en este curso** |
  |---|---|
  | 🟢 | Aplicación directa de lo de la fase a un caso nuevo del dominio. Se resuelve leyendo la fase. |
  | 🟡 | Requiere consultar documentación oficial que la fase no transcribió. |
  | 🟠 | Combina dos o más temas, o exige depurar algo que falla de forma no obvia. |
  | 🔴 | Abierto o adversarial: medir un anti-patrón, romper una garantía, defender una decisión con números. |

- **Distribución para ~25 ejercicios:** unos 6 🟢, 8 🟡, 7 🟠 y 4 🔴, más los 🔥 aparte.
- **Numeración continua con encabezado de rango:**

  ```markdown
  ## 🧪 Ejercicios (25)

  **🟢 Fácil (1–6)**
  1. ...

  **🟡 Intermedio (7–14)**
  **🟠 Difícil (15–21)**
  **🔴 Muy difícil (22–25)**
  **🔥 Opcionales**
  ```

- **Accionables y verificables.** *"Haz que el reporte de 500.000 filas corra en memoria
  constante, y demuéstralo midiendo el pico con el arnés de la fase"* — no *"reflexiona sobre
  los generadores"*.
- **Al menos un tercio son de diagnóstico o de medición**, no de construcción: se entrega algo
  que funciona mal y se pide localizar, explicar y cuantificar.
- **Al menos dos por fase son de registro:** dado un encargo, decidir si es script, herramienta
  o aplicación, y justificarlo con el costo de las otras dos. Es el músculo central del curso y
  no se entrena solo.
- **Enganchados al dominio.** Pacientes, planes, fases, aliados, glosas, regalías. Nunca `foo`
  y `bar`.
- **Con el identificador vigente.** Si el ejercicio nombra código, usa el nombre en inglés que
  ya existe en la fase.

---

## 10. Bibliografía y referencias

**Regla:** documentación oficial de la versión fijada primero; después PEPs cuando expliquen
el porqué; después libros; después charlas y blogs. Siempre se advierte cuando un enlace
apunta a una versión distinta de la que usamos.

### 10.1 Formato

URLs completas y clicables, nunca solo el dominio. Dentro de "Referencias" se separa en
documentación oficial, PEPs, libros cuando apliquen, video y apoyo, y una línea final de
**orden de lectura sugerido**.

### 10.2 Fuentes por defecto

- **Documentación de Python:** `https://docs.python.org/3/` — con la advertencia de fijar la
  versión en el selector, porque por defecto sirve la estable del día.
- **PEPs:** `https://peps.python.org/` — se citan cuando explican una decisión de diseño, no
  como adorno de autoridad.
- **PyPI** para la ficha de cualquier dependencia que el curso fije.
- La documentación oficial de cada biblioteca del stack, enlazada a su versión.

### 10.3 Advertencias

- Cuando se cite un libro, artículo o charla, se aclara que el título o la URL pueden haber
  cambiado y conviene verificarlos. **No se inventan números de página, ISBN ni identificadores
  de video.**
- **No usar en el código principal** APIs posteriores a la versión fijada. Aparecen como
  comparación, marcadas 🔥.
- Cuidado con el material de internet anterior a la versión del curso: buena parte de lo que
  el lector va a encontrar sobre empaquetado, tipado y concurrencia describe un ecosistema que
  ya no existe. Cuando eso importe, se dice.

---

## 11. Coherencia de la ficción

La empresa del curso se llama **Áurea** y es ficticia. Su historia completa —personajes,
cifras, cronología y reglas de negocio— vive en
[`00-historia-de-aurea.md`](../00-historia-de-aurea.md), que es la fuente de verdad
narrativa. El curso **construye su software pieza por pieza**: al terminar, el lector tiene el
código en su disco y puede abrir cualquier archivo del que el material haya hablado.

Eso impone cuatro reglas.

**Regla 1 — Si el curso afirma que algo está así en Áurea, tiene que poder mostrarlo.** *"Así
lo resuelve Áurea"* es legítimo cuando el código está en alguna fase, y solo entonces.

**Regla 2 — Lo que Áurea tiene y el curso no construye se cuenta como historia, no como
observación.** Hay cosas que importan y no caben: las cuarenta pantallas de Odontovía, el
Excel de Patricia, los veintitrés convenios con aliados. Se cuentan **en pasado y como
contexto**:

> ✅ *"Patricia lleva las comisiones en una pestaña que actualiza cuando se acuerda; acá
> construyes la conciliación de esas comisiones y el reflejo que te llevas es que un ingreso
> sin soporte no es un ingreso."*
>
> ❌ *"El módulo de comisiones tiene un bug en el redondeo."*

La segunda promete un código que nadie puede abrir.

**Regla 3 — La cronología es fija.** Consultorio en 2013, marca Áurea en 2019, primera
franquicia en 2022, el lector entra en 2025, el curso ocurre en 2026. Ninguna decisión de
Áurea puede justificarse con algo que no existía cuando se tomó.

**Regla 4 — Ningún ejercicio pide algo que solo se pueda hacer con un sistema que el lector no
tiene.** Ni "compara con cómo lo resuelve tu empresa", ni "pregúntale a tu equipo", ni
"verifica esto contra tu instalación". Las versiones están fijadas.

> 🧭 **El corolario, que es lo que se gana:** el curso se puede tomar entero, de principio a
> fin, sin acceso a nada más que a esta carpeta y a un intérprete de Python. Cualquier
> frase que rompa eso es un error de estilo, aunque esté bien escrita.

**Y la frontera legal es parte de la ficción.** La historia clínica de Áurea es reservada, con
auditoría de accesos obligatoria. Ningún ejercicio, miniproyecto ni ejemplo puede sacar datos
clínicos identificables hacia un servicio externo, y cuando el material roce ese límite, lo
nombra.

---

## 12. Coherencia entre documentos

- **No contradecir fases anteriores.** Un fragmento de la fase 12 no puede usar una forma del
  dominio distinta a la que definió la fase 4.
- **No reescribir decisiones aprobadas** sin señalar la incompatibilidad y explicar por qué.
- **Nombres estables.** Módulos, funciones y modelos se mantienen idénticos entre fases. Si
  algo se renombra, se documenta y se ajustan las fases afectadas.
- **Fuentes de verdad, en este orden:** (1) `alcance-del-proyecto.md` —el techo, y su §0 fija que
  no hay nada por encima—, (2) `propuesta-fases-y-alcance.md`, (3) esta guía,
  (4) `plantillas-de-capitulo.md`, `formato-de-miniproyectos.md` y `formato-de-mediciones.md`,
  (5) `00-historia-de-aurea.md` para todo lo narrativo, (6) entregables ya aprobados de
  fases anteriores, (7) decisiones explícitas del chat actual.

  `propuestas-fases-base-ia-datos.md` y `propuestas-temas-opcionales.md` son **material
  exploratorio**: alimentan la discusión de fases, y pierden contra (2) y (3) en cualquier
  contradicción.

- **Autocontención.** El curso **no nombra ningún otro curso**, ni como material necesario ni como
  profundización opcional. Cuando un tema queda fuera, se declara la exclusión y se para ahí:
  decir dónde vive ese material es una promesa que esta carpeta no puede cumplir
  (`alcance-del-proyecto.md` §0).

---

## 13. Checklist antes de dar por cerrado un `.md`

- [ ] Sigue la plantilla de 10 secciones, sin secciones extra ni reordenadas.
- [ ] Tono semiformal y colegial, tuteo latinoamericano, humor con moderación.
- [ ] No explica nada que un dev Java senior ya sabe.
- [ ] Explica el problema antes que la herramienta, y el porqué de cada decisión.
- [ ] Prosa antes que listas; listas antes que tablas en comparativas extensas.
- [ ] Todo el código corre con las versiones fijadas en `alcance-del-proyecto.md` §9.
- [ ] **Todo el código en inglés** y **todos los comentarios y docstrings en español, con
      tildes**; mensajes de error y de log también en español (§5).
- [ ] El código está escrito **en el registro de su fase** (§6.1): sin ceremonia en el Bloque
      A, con tipos y pruebas en los Bloques B y C.
- [ ] Cero `Any`; nulabilidad explícita; `Decimal` para dinero; `datetime` con zona.
- [ ] Cada analogía con Java declara **dónde se rompe** (§4.2).
- [ ] Cada 💸 declara dónde se paga, o por qué no se paga.
- [ ] Cada afirmación comparativa tiene su 📏 con condiciones y competidor real (§4.6).
- [ ] Tiene 20-25 ejercicios con rangos 🟢🟡🟠🔴 calibrados para el perfil, un tercio de
      diagnóstico o medición y al menos dos de registro.
- [ ] **Tiene su miniproyecto 🧱**, con criterios de aceptación verificables y calibrado para
      que no se resuelva copiando la fase.
- [ ] Referencias con URL completa a la versión correcta, con advertencia cuando no lo sea, y
      sin datos bibliográficos inventados.
- [ ] No contradice ninguna fase anterior, ni en pedagogía ni en nombres.
- [ ] Coherencia de la ficción (§11): nada que afirme sobre Áurea algo que el curso no pueda
      mostrar, y ningún ejercicio que exija un sistema externo.
- [ ] Incluye "La señal de que quedó bien" en el cierre.
- [ ] Lleva el bloque 🏷️ del tag al final, con el número correcto (§8.1).
- [ ] **No hay ningún apéndice** ni ninguna promesa de uno.
- [ ] **No se nombra ningún otro curso ni ningún archivo de fuera de esta carpeta.** El curso es
      autocontenido (`alcance-del-proyecto.md` §0), y una exclusión se declara sin decir dónde
      estaría el material excluido.

---

## 14. La carta: forma, excepciones y reglas de producción

> 📝 **Sección agregada el 05/10/2026**, al abrir la escritura de la carta. Va después del
> checklist para no renumerar nada: §13 sigue siendo el checklist del camino base y de los
> complementos. Lo que aquí se decide manda sobre la carta y solo sobre la carta. Las decisiones
> marcadas *por defecto* las tomó la sesión para no bloquearse y esperan revisión del autor.

### 14.1 Lo que el autor decidió (05/10/2026)

- **Se escribe la carta entera**, encadenada, en el orden de `propuestas-temas-opcionales.md` §19
  (primero los tracks con encargo en Áurea, después los demás). El orden y el estado viven en
  [`plan-de-produccion-carta.md`](plan-de-produccion-carta.md).
- **Forma ligera, unas 400 líneas por sección**: problema → modelo → ejemplo que corre → lo que se
  rompe → cuándo NO usarla → ejercicios → referencias → cierre. El esqueleto está en
  [`plantillas-de-capitulo.md`](plantillas-de-capitulo.md), *Plantilla de sección de la carta*.
- **El código se escribe por inspección, sin ejecutar.** Cada sección lo declara en su
  encabezado, y toda salida que muestre va rotulada **«Salida esperada, sin correr»**. La deuda de
  ejecución se lleva en el plan, y una tanda de verificación final la paga.
- **Prueba de humo cuando es barata** (*por defecto, a revisar*). Si el ejemplo corre con
  dependencias de PyPI y sin servicios, la sesión lo corre en un contenedor `python:3.14.7` antes de
  cerrar la sección. Entonces el encabezado dice **«Código probado el 05/10/2026 con Python 3.14.7,
  en contenedor»** (o «probado en parte», diciendo qué), y sus salidas se rotulan **«Salida
  (Python 3.14.7, 05/10/2026)»**. En las cinco primeras secciones la prueba encontró dos errores
  reales —un dígito de verificación mal calculado y una fecha sin zona que FHIR rechaza—: por eso
  se hace aunque el autor no la exija.
- **Lo que pasó en la práctica (actualizado el 05/10/2026, al cerrar T19).** La prueba de humo
  dejó de ser la excepción: se extendió a servicios en contenedores con red propia y sin puertos
  publicados, y **de las 156 secciones de T1–T19, 150 están probadas enteras y 6 en parte**
  (op002, op013, op019, op029, op036 y op120, marcadas 🟡 en el plan, con lo que falta dicho en su
  encabezado). «Por inspección» queda como el piso, no como la norma: una sección nueva se prueba
  salvo que no se pueda, y entonces lo declara.
- **Cómo terminó (07/10/2026, al cerrar T24).** Las 176 secciones están escritas y **173 probadas
  enteras**; quedan 3 en parte, cada una con su razón en el encabezado: op013 (systemd no monta
  credenciales dentro del contenedor de prueba) y op029 y op036, cuyas celdas `⏳` son un ejercicio de
  la propia sección. T20–T22 se escribieron ya con la corrida delante —el código y la salida que
  publica cada sección se ensamblan desde la corrida—, y T24 creó `src/opNNN-…/` extrayendo los
  archivos del Markdown publicado.

### 14.2 Excepciones a las reglas de la carta y del repositorio

| Regla general | Lo que hace la carta | Por qué |
|---|---|---|
| 20–30 ejercicios por sección (valor por defecto del repositorio; 20–25 en este curso, §9) | **8 a 12 ejercicios**, con el mismo reparto 🟢🟡🟠🔴 y la misma escala de §9 | Decisión del autor: una sección suelta de 400 líneas no sostiene veinte ejercicios sin relleno |
| Cada ejercicio con solución de referencia o rúbrica | **Cada ejercicio cierra con `**Criterio:**` verificable**; los 🔴 llevan además una rúbrica de tres o cuatro puntos. No se publican soluciones | *Por defecto, a revisar*: el criterio verificable es lo que el lector necesita para saber si terminó, y una solución escrita por inspección sería código sin correr presentado como respuesta |
| El código de cada documento vive en `src/<nombre del documento>/` (§8.2) | **El código va en la sección**, completo y en un solo bloque por archivo; `src/opNNN-…/` se genera desde la sección (T24, 07/10/2026) y **la sección manda** si difieren | *Por defecto, a revisar*: escribir cada archivo dos veces sin poder correrlo duplica el riesgo de que diverjan, que es justo lo que la regla de `src/` quiere evitar |
| Ninguna salida inventada | Las salidas van **rotuladas como esperadas y sin correr**; ningún número de rendimiento se presenta como medido | Mismo método que las mediciones `⏳` del curso: la especificación se publica, el número espera |
| Diagramas a criterio de quien escribe | **Mermaid**, salvo árboles de archivos, salidas y correspondencias en columnas, que van en `text` | *Por defecto, a revisar*: es la elección que el autor pidió el 05/10/2026 para los cursos de esta familia; el camino base no se convierte aquí |
| Una sección por plataforma | **Linux y macOS**; lo que solo corre en Windows se dice y no se escribe | El curso no fija Windows, y la carta no lo agrega |

### 14.3 Reglas de producción que heredan todas las secciones

- **Versiones desde [`inventario-verificado.md`](inventario-verificado.md)**, que genera
  `check-inventario.py` contra PyPI. Una sección no nombra una versión que no esté ahí; si nombra
  un paquete nuevo, se agrega al inventario y se regenera antes. Un paquete marcado 💤 se nombra con
  su fecha y su veredicto (quieto porque está terminado, o quieto porque está muerto: §18 de la
  propuesta).
- **URL por código de estado**, verificadas al cerrar cada tanda. Aterrizar en la portada de la
  documentación cuenta como roto.
- **Autocontenida y suelta**: una sección enlaza fases del camino base y documentos del curso, y
  secciones de la carta **anteriores** a ella; nunca una posterior, y nunca otra cosa de fuera de
  esta carpeta.
- **Áurea cuando le sirve al tema**, con los nombres de la historia y el diccionario de §5.1; un
  ejemplo propio cuando no. Ningún dato clínico identificable en ningún ejemplo (historia §5).
- **Los servicios corren en contenedores** con un `compose.yaml` dentro de la sección, imágenes
  oficiales con etiqueta fija y puertos por defecto (el lector los reconoce).
- **Fusiones y mudanzas de la propuesta, ya aplicadas a la numeración** (plan §5): `cl` vive dentro
  de `ui` como `ui10`–`ui12`; `ed05` se muda a `ui01`; `au04` se muda a `qa09` y el track `au`
  queda en siete secciones; `vz` se recorta a cuatro; EPUB es un 🔴 desafío de `ar06`.
- **Reparto de `qa` y `ob`** alrededor del cierre nocturno (*por defecto, a revisar*): `qa` prueba
  el cierre **antes** de que corra —integración, propiedades, carga—; `ob` lo observa **mientras**
  corre y después —bitácoras, métricas, trazas, alertas—. Ninguna sección de un track repite un
  ejemplo del otro.
- **Track `cv`**: camino (a) de la propuesta §13. La técnica se enseña con rostros del propio lector
  o sintéticos, y **ninguna imagen de paciente** aparece ni se sugiere; `cv05` y `cv08` dicen por
  qué Áurea no puede desplegar reconocimiento.

### 14.4 Checklist de una sección de la carta

- [ ] Encabezado con track, posición, «se lee suelta», fecha de versiones y la declaración de
      si el código se probó (entero, en parte —diciendo qué— o sin ejecutar).
- [ ] Se lee sin haber leído ninguna otra sección de la carta.
- [ ] Explica qué problema resuelve la herramienta **y cuándo no usarla** (⚖️).
- [ ] Un ejemplo completo, con su instalación (`uv add …` o `compose.yaml`), identificadores en
      inglés y comentarios en español **en todos los lenguajes**, también C, Rust o Typst (§5).
- [ ] Toda salida rotulada («Salida esperada, sin correr» o la de la prueba de humo); ningún
      número presentado como medido.
- [ ] Toda versión nombrada está en `inventario-verificado.md`; los 💤 llevan su fecha.
- [ ] Ninguna comparación sin número, o sin la medición `⏳` que la sostendría.
- [ ] 8–12 ejercicios con rangos 🟢🟡🟠🔴, cada uno con `**Criterio:**`, y rúbrica en los 🔴.
- [ ] Referencias con URL completa y verificada, y orden de lectura.
- [ ] Cierra con La señal de que quedó bien y el bloque 🏷️ `op-<tt>-fase-NN`.
- [ ] Enlaza solo hacia atrás, y nada de fuera de esta carpeta.

---

## 15. Excepciones a los lineamientos del repositorio

> 📝 **Sección agregada el 05/10/2026**, en la revisión de `prompts/` contra los lineamientos de
> producción del repositorio (`zz-instrucciones/`). Va al final para no renumerar nada: §13 sigue
> siendo el checklist y §14 la carta, y así los citan los demás documentos. Esta guía se escribió
> antes de que esos lineamientos existieran: lo que aquí se declara ya era la práctica del curso, y
> desde ahora está escrito como decisión.

El `CLAUDE.md` del repositorio y las plantillas de los lineamientos dan **valores por defecto**; esta
guía los reemplaza donde lo dice. Lo que esta sección no menciona se hereda tal cual. Las
excepciones propias de la carta están en §14.2.

| Regla general | Lo que hace este curso | Por qué |
|---|---|---|
| Comentarios dentro del código en inglés (repositorio) | **En español, con tildes**, igual que los mensajes de error y de log (§5) | El comentario es el canal del *porqué*, y el curso piensa en español; los identificadores siguen en inglés |
| 20–30 ejercicios por sección (repositorio) | **20 mínimo, 25 ideal** por fase (§9); 8–12 en la carta (§14.2) | El miniproyecto obligatorio consolida la fase; más volumen sería relleno |
| Solución de referencia o rúbrica por ejercicio (repositorio); solución plegada en 🟢🟡 (plantilla) | **Sin soluciones publicadas.** En el camino base, la evaluación verificable es el miniproyecto con sus criterios de aceptación (`formato-de-miniproyectos.md`); en la carta, cada ejercicio cierra con `**Criterio:**` y los 🔴 con rúbrica | Los ejercicios son enunciados accionables y verificables (§9); escribir cientos de soluciones duplicaría el curso |
| Apéndices `aNN-` y su propuesta | **Ninguno** (alcance §6) | Todo es fase, complemento o sección de la carta |
| Diagramas a criterio de quien escribe (`D-12` de los lineamientos) | **Mermaid** para los diagramas; `text` para árboles de archivos, muestras de datos, salidas y correspondencias en columnas | Pedido explícito del autor el 05/10/2026 para los cursos de esta familia. La carta ya lo cumple; la conversión del camino base y de los complementos es una tarea aparte, pendiente |

### 15.1 Lo que el curso no tiene, y qué hace su papel

- **Diccionario de términos** con ese nombre de archivo: hace su papel §5.1 de esta guía (el
  diccionario del dominio, de español a identificador en inglés).
- **Contrato de nombres** con ese nombre de archivo: lo hacen [`contrato-del-cli.md`](contrato-del-cli.md)
  (los nombres del CLI de Patricia, congelados fase a fase) y §5.1. No se renombran, por el bloqueo
  de contenido.
- **Plan de producción del camino base y de los complementos:** se escribieron antes de que los
  lineamientos lo pidieran, y su registro está en `README.md` (las tandas T0–T13). La carta sí tiene
  el suyo: [`plan-de-produccion-carta.md`](plan-de-produccion-carta.md), con la forma de la
  plantilla (§1–§9, incluido el registro de directorios de `zz-code/`).
- **Propuesta de apéndices y prompts de apéndice:** no hay apéndices.
- **Fecha de versión en el encabezado** de cada documento de `prompts/`: solo la llevan el plan y
  el inventario, que cambian a diario. Los demás fechan cada cambio en el propio texto, como esta
  sección.
- **Verificador:** [`verificar-corpus.py`](verificar-corpus.py), subclase del perfil `courses-ia`
  de [`verificador_base.py`](verificador_base.py) (copia idéntica a la de los lineamientos), con los
  chequeos `CARTA-*` de la carta. Se corre desde la raíz del curso con
  `python3 prompts/verificar-corpus.py`. Con `--perfil=publicacion` da 0 errores desde el
  07/10/2026: se quitaron los emoji de los 292 encabezados `###` (la escala 🟢🟡🟠🔴🔥💀 se
  conserva; los `##` conservan los suyos), los enlaces y menciones a `prompts/` desde material
  publicado, y las fases del camino base llevan su fecha de verificación. Quedan avisos: los 🧭,
  callout del repositorio que ese perfil no lista.

