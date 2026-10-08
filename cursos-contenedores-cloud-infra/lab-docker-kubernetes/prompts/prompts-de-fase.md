# 🗺️ Prompts iniciales por fase
## Laboratorio de contenedores y Kubernetes local — 28 sesiones, 28 entregables

Cada sección es el prompt completo de una fase, listo para pegar en la sesión que la redacta. **El
alcance de cada fase no se copia aquí**: vive en su ficha de
[`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md) §5, y el prompt la cita. Lo que el
prompt agrega es lo que la ficha no dice: qué vigilar, qué riesgo tiene la fase y qué tiene que estar
hecho antes. Así, si la ficha cambia, el prompt no queda desactualizado.

**Una sesión, un archivo de fase**, más lo que la fase alimenta en la misma tanda: sus incidentes en
el cuaderno, su medición en `BENCHMARKS.md`, su 🪞 en `INSTINTOS.md`, su paso de generación en
`a03` y en `src/lab/`, y sus filas en `a04` y `a05`.

> ⚠️ **Antes de la primera sesión.** Tienen que estar a mano, en este orden:
> `prompts/alcance-del-proyecto.md`, `prompts/guia-de-estilo-y-convenciones.md`,
> `prompts/contrato-del-cluster.md`, `prompts/propuesta-fases-y-alcance.md`,
> `prompts/propuesta-apendices-y-alcance.md`, `prompts/plantillas-de-capitulo.md`,
> `prompts/formato-cuaderno-incidentes.md` y `00-historia-de-la-vecina.md`.
> **No se usa** ningún archivo `_desechable-*`: el curso no los cita.

> ⚠️ **Antes de F00.** Tienen que estar escritos y verificados `a01`, `a02` y `a16` (el patrimonio
> funcionando con `task legacy:up`), y hecha la verificación de laboratorio (P11). Sin versiones fijadas, ninguna fase publica un comando de
> instalación. **Antes de F02**, además, `a03` con los prompts G0 y la suite del paso.

---

## 🧱 El marco común

Va entero en el prompt de F00 y se cita en los demás. **No lo repitas en el documento: aplícalo.**

```markdown
## Marco (no lo repitas, aplícalo)

Fuentes de verdad, en este orden: (1) `prompts/alcance-del-proyecto.md`,
(2) `prompts/guia-de-estilo-y-convenciones.md`, (3) `prompts/contrato-del-cluster.md`, con los
nombres técnicos, (4) `prompts/propuesta-fases-y-alcance.md`, con la ficha de esta fase y su fila
de §11, (5) `prompts/propuesta-apendices-y-alcance.md`, (6) `prompts/plantillas-de-capitulo.md`,
(7) `prompts/formato-cuaderno-incidentes.md`, (8) `00-historia-de-la-vecina.md`, que es la fuente
de todo lo narrativo, con la escena de esta fase en la tabla de escenas de
`prompts/prompts-de-fase.md`, (9) las fases y apéndices ya escritos y el código de `src/lab/` en el
tag de la fase anterior, (10) las decisiones de esta sesión. Los documentos `_desechable-*` no cuentan y
no se citan.

Reglas que no se negocian:
- **Nada se publica sin haberse ejecutado.** Ningún comando, ninguna salida, ningún número
  inventado. Lo que no se verificó se declara con esas palabras. Solo se verifica en macOS arm64;
  lo propio de Windows 11 y de Linux se escribe desde la documentación oficial y se marca *"no
  verificado por el autor; se confirma al hacer el curso"*.
- **Ninguna versión fuera de `a01`.** Las imágenes, por digest.
- **El problema primero, en el laboratorio; el mecanismo después.**
- **`pricing` primero; los otros tres solo donde no es mecánico.**
- **Ninguna capacidad en el código antes de su fase.** El paso de generación de esta fase se hace
  con los prompts de `a03`, y la suite del paso pasa antes de cerrar.
- **YAML plano antes que Helm; `kubectl` antes que k9s; `openssl` antes que cert-manager.**
- **Tamaño mínimo.** Perfil `minimo` salvo que la fase declare otro; la observabilidad que no se
  usa, apagada.
- **Docker como camino principal, 🦭 donde Podman diverge.** Tres plataformas, siempre en el mismo
  orden, cuando las instrucciones difieren.
- **Autopsia, no juicio**: ni personas ni herramientas son villanas.
- **Ningún objeto `Ingress`.** La entrada al sistema es Gateway API.
- **Código en inglés, comentarios en español con tildes.** Nombres técnicos, los del contrato.
- **Los datos de la historia no se inventan.** Si falta uno, se propone agregarlo a la historia.
- **El curso no nombra ningún otro curso del repositorio.**
- **No toques ningún `README.md`**, ni el del curso ni los de `src/`, **ni crees
  `0-ESTRUCTURA-CURSO.md`**. Se escriben en una tanda final y aparte. Si algo debería constar en
  ellos, déjalo en 📌 Pendientes sugeridos.
- La plantilla se sigue literal, sin secciones extra ni reordenadas, y el cierre lleva el bloque 🏷️.
```

Y el **protocolo de tres pasos**, que cierra todos los prompts:

```markdown
## Cómo quiero que trabajes

**Paso 1 — Preguntas antes de escribir.** No redactes. Devuélveme: (a) preguntas bloqueantes
numeradas, marcando cuáles puedes asumir con un valor por defecto; (b) tu lectura de la ficha y si
el peso y los ejercicios de §11 cuadran con ella; (c) la apuesta que propones, escrita ya en su
forma final, y la rotura o la medición que esperas; (d) el orden en que vas a ejecutar el
laboratorio, con los comandos; (e) un esbozo de la sección más larga; (f) cualquier contradicción
con lo ya escrito o con el contrato: dímela, no la resuelvas.
**Paso 2 — Laboratorio y redacción**, cuando yo responda. Primero se ejecuta y se anota (el error
antes de arreglarlo, literal); después se escribe. Si aparece una duda nueva, **para y pregunta**.
**Paso 3 — Autoverificación** contra el checklist de la guía §16, reportada en lista corta, más las
entradas nuevas de `BENCHMARKS.md`, `INSTINTOS.md` y el cuaderno, y lo que se agregó a `a03`, `a04`
y `a05`.
```

---

## 🎭 Las escenas de la historia, por fase

Cada fase abre con una escena de `00-historia-de-la-vecina.md`, en la voz de quien tiene el
problema. Esta tabla dice cuál, para que ninguna sesión la invente ni la repita. **La escena es
candidata**: la sesión la puede ajustar en su paso 1, pero los hechos salen de la historia y, si
falta uno, se agrega allí primero.

| Fase | La escena que la abre | La voz | De la historia |
|---|---|---|---|
| 00 | La noche del salbutamol, el 14 de octubre y la pregunta de Germán; el continuo del cuaderno a Contingencia; el patrimonio de La Rebotica | narrador, Germán | §1, §3, §5 |
| 01 | Valentina pelea con el portátil corporativo y mete la Braqui en su primer contenedor | Valentina, la Braqui | §1.9, §6 |
| 02 | El patrimonio corriendo en un archivo; los cuatro equipos acuerdan el contrato y Daniela defiende el catálogo del portal | Valentina, Daniela | §2, §5.3 |
| 03 | *"¿Y eso es una máquina virtual chiquita?"*: la primera pregunta de Luz Marina | Luz Marina | §6, Parte I |
| 04 | La factura de Java por empleado y la imagen base de `inventory`: qué distribución de la JVM | Germán, Martha Lucía | §4 |
| 05 | Compras no aprueba otra suscripción por puesto: La Rebotica tiene que andar con Docker y con Podman | Valentina | §5.4 |
| 06 | El Siga multiplicado y no separado contra lo que promete el cluster | Luz Marina | §1.6, §1.7, §1.10 |
| 07 | Tres portátiles y un presupuesto de cero: La Rebotica arranca | Valentina | §5.3 |
| 08 | La circular de precios que tarda dos semanas: por qué `pricing` va primero | Luz Marina, Valentina | §3, §5.4 |
| 09 | Los cuatro equipos, cada uno con su almacén, sin llamarse todavía | Valentina | §2 |
| 10 | La entrada única al sistema, y Contingencia perdiendo el tráfico de precios hasta cero: el *strangler* | Andrés, Daniela | §1.7, §3 |
| 11 | *"Salió la circular y las droguerías siguen cobrando lo viejo"*: el tope regulado configurable | Fabio Arenas, Yolanda | §8.1 |
| 12 | Las dos réplicas que dicen que hay y que no hay; y la Braqui pegada a las tablas del Siga | Luz Marina, la Braqui | §1.9, §1.10, §1.11 |
| 13 | Dos perfiles, doce archivos casi iguales, y Martha Lucía pidiendo cuánto cuesta cada uno | Martha Lucía | §2 |
| 14 | *"¿Se puede instalar para una segunda cadena sin copiarlo todo?"*: la cadena de Don Rodrigo | Germán | §1.13, §5.4 |
| 15 | `inventory` muere sin decir nada: el `-Xmx` que venía de los tiempos de WebLogic; y Contingencia, que no se prendió | el Núcleo, Luz Marina | §1.6, §1.14, §3 |
| 16 | Quincena en Bogotá; Valentina le explica a Germán por qué un portátil no es la nube | Valentina, Germán | §7 |
| 17 | El 14 de octubre, cuarenta minutos sin saber por qué se congelaban las cajas | Fabio Arenas | §1.14, §3, §6 |
| 18 | Seguir una venta de Chapinero por cuatro servicios; *"hoy comemos pizza"* | Valentina | §2, §8.2 |
| 19 | El certificado del portal de afiliados vencido un domingo, y el proxy que firma todo | el área comercial, mesa de ayuda | §3, §6 |
| 20 | Las dos cadenas en el mismo cluster, y la base que cualquiera podía ver | Germán | §1.13 |
| 21 | Una noche de pizza contada con método: los primeros treinta segundos | Luz Marina, Wilson | §2 |
| 22 | *"Girón un martes"*, *"Sogamoso con lluvia"*, *"Bogotá en quincena"* | Wilson | §9 |
| 23 | Todas las cajas preguntando precio a una sola réplica | Valentina | §5.4 |
| 24 | El procedimiento del préstamo sale de la base y se vuelve saga; *"siempre llega"* no es *"siempre llega ya"* | Doña Graciela, Andrés | §1.2, §1.7, §1.9, §1.10 |
| 25 | El aviso a la Braqui que se perdió, y los huérfanos de los lunes | Wilson, Luz Marina | §1.9, §1.10, §1.11 |
| 26 | Las dos motos con el mismo inhalador | Wilson | §1.9, §1.10 |
| 27 | La recomendación de Valentina a Germán, en dos ramas; la servilleta de Don Aurelio, de cierre | Valentina, Germán | §5.5, §6 |

---

## # Fase 00 — El ambiente

```markdown
Esta es la sesión de la **Fase 00 — 🛠️ El ambiente: dos motores y tres plataformas**, del curso
Laboratorio de contenedores y Kubernetes local. Su entregable es `00-el-ambiente.md`, más las
entradas 01–04 y 27 del cuaderno.

## Marco (no lo repitas, aplícalo)

{{pega aquí el marco común completo}}

## Identidad

- Fase 00 de 27 · Parte 0 · **media** · 20 ejercicios · plantilla de la Parte 0
- Depende de: `a01` y `a02` · Habilita: F01 · Reserva los incidentes 01–04 y 27

## Alcance

El de la ficha F00 de la propuesta, completo.

## Qué vigilar

- **Es la primera página que lee el lector**: la sección 1 presenta el curso, la pregunta que lo
  ordena, la empresa en una página y el sistema que se va a construir. Una página, no diez: la
  historia existe y se enlaza.
- **Tres plataformas, sin nota al pie**, siempre en el orden Windows, macOS, Linux. Solo macOS se
  ejecuta en esta sesión: Windows y Linux van desde la documentación oficial y con la marca de no
  verificado, que es la parte del curso que más va a corregir quien lo haga.
- **La convivencia de los dos motores** es el corazón técnico: cómo saber cuál está activo
  (`task engine:status`), cómo alternar, y por qué no conviene que corran los dos a la vez. El
  script de Windows se usa, no se explica línea por línea.
- **La memoria que se le da a la máquina virtual** de cada motor sale de la tabla de `a01`, y se
  explica por qué importa para un curso de tamaño mínimo.
- **Los cinco incidentes de ambiente** van al cuaderno con su síntoma literal; en la fase, solo
  el síntoma y el enlace. La cola larga va a `a02`, no aquí. El 27 (el proxy corporativo) es el
  que más reconoce el lector de esta historia: un portátil de empresa con Windows y una política
  de seguridad razonable. Se describe desde la documentación y se marca no verificado si no se
  puede reproducir en macOS.
- **La empresa se presenta desde la noche del salbutamol y el 14 de octubre de 2025** (historia §1 y
  §3): el curso es el proyecto Paracelso, que Alquimia construye en La Rebotica, y el lector
  tiene que saberlo en la primera página.
- **Es el material que más rápido envejece**: fecha de verificación visible arriba.

{{protocolo de tres pasos}}
```

---

## # Fase 01 — Tu primer contenedor, y tu primer Dockerfile

```markdown
Esta es la sesión de la **Fase 01 — 📦 Tu primer contenedor, y tu primer Dockerfile**. Entregable:
`01-primer-contenedor-y-dockerfile.md`.

## Marco
El de F00, más F00 cerrada.

## Identidad
- Fase 01 de 27 · Parte 0 · **media** · 20 ejercicios · plantilla de la Parte 0
- Pieza: **la Braqui**, del patrimonio (`src/lab/legacy/braqui/`) · Apéndices: a01, a02, a16

## Alcance
El de la ficha F01, completo, con la nota del toolchain.

## Qué vigilar
- **No se recrea en nada.** Vocabulario mínimo y se detiene; cada tentación de profundizar tiene
  fase de destino (capas y OCI en F03, multi-stage y caché en F04).
- **CMD contra ENTRYPOINT** es lo único que se explica a fondo, con los dos probados.
- **El Dockerfile es de un solo stage a propósito**, y la fase dice que la F04 lo va a reescribir.
- **El primer contenedor es código que existe**, con sus mañas: la Braqui tal como vino en 2020. La
  fase no la arregla; la empaqueta. `pricing` todavía no existe.
- **La limpieza del disco** va con la salida real de `system df` antes y después.
- **🦭 los verbos son iguales en Podman**: se dice una vez con 🩻 y se sigue.

{{protocolo}}
```

---

## # Fase 02 — Compose: el sistema entero en un archivo

```markdown
Esta es la sesión de la **Fase 02 — 🧩 Compose: el sistema entero en un archivo**. Entregable:
`02-compose-el-sistema-en-un-archivo.md`, más el paso G0 en `src/lab/` (los cinco servicios
generados, `compose/compose.yaml` y la suite G0).

## Marco
El de F00, más F01 cerrada, `a03` escrito con los prompts G0 y `a16` con el patrimonio funcionando.

## Identidad
- Fase 02 de 27 · Parte 0 · **media** · 20 ejercicios · plantilla de la Parte 0
- Paso de generación: **G0 · Esqueleto** 🌊 · Servicios: los cinco

## Alcance
El de la ficha F02, completo.

## Qué vigilar
- **Primero el patrimonio, después lo nuevo.** `task legacy:up` levanta Contingencia, su Postgres,
  el portal y la Braqui; el esqueleto G0 corre al lado. Los prompts G0 reciben el código del
  patrimonio del que se extrae cada servicio (contrato §6).
- **El contrato se congela aquí.** Los OpenAPI de los cuatro servicios llevan desde hoy los
  endpoints que todavía no existen, marcados como pendientes. Después de esta fase, cambiar una
  forma de payload exige cambiar el contrato y la suite primero.
- **La suite de conformidad es la estrella silenciosa**: el lector tiene que salir entendiendo que
  un servicio es válido porque la pasa, y que por eso puede regenerarlo o escribirlo a mano.
- **Swagger UI se presenta como lector de los contratos** (`task contracts:docs`), en una línea:
  la fuente de verdad es el OpenAPI y la suite, no la página.
- **Generar los cinco servicios con los prompts de `a03`, en esta sesión**, con `pricing` primero.
  Si el código generado trae `/metrics`, logs en JSON o cualquier capacidad de fases posteriores,
  se regenera: la regla del contrato §1.3 no admite excepciones.
- **El sistema no hace nada interesante, y se dice** con el calendario de las tres oleadas.
- **🦭 `docker compose` y `podman compose` no son el mismo programa**: el marcador se estrena aquí,
  corto.
- **Compose se disfruta**: nada de críticas; la 🪞 llega en la Fase 06.

{{protocolo}}
```

---

## # Fase 03 — El contenedor por dentro, y su ciclo de vida

```markdown
Esta es la sesión de la **Fase 03 — 🔬 El contenedor por dentro, y su ciclo de vida**. Entregable:
`03-el-contenedor-por-dentro.md`.

## Marco
El de F00, más la Parte 0 cerrada.

## Identidad
- Fase 03 de 27 · Parte I · **media** · 20 ejercicios · plantilla de plataforma
- Servicios: `pricing` como sujeto; `inventory` para el ejemplo de señales si hace falta

## Alcance
El de la ficha F03, completo.

## Qué vigilar
- **La tentación del tratado de kernel se resiste.** cgroups y namespaces se nombran, se muestra
  el proceso del contenedor visto desde el host (o desde la máquina virtual del motor), y se sigue.
  Si una sección pasa de "se explica hasta que cambia una decisión", se corta.
- **La analogía de la VM se desmonta en el mismo párrafo** en que aparece.
- **PID 1 y `SIGTERM`**: la demostración es un contenedor que tarda el tiempo de gracia completo en
  morir porque su proceso no atiende la señal, medido. La deuda 💸 queda declarada para la F16.
- **`dive` se estrena aquí** para ver capas, y la F04 lo usa para medir.
- **Rootless**: solo lo que evita el `CrashLoopBackOff` de permisos; `securityContext` es de la F20.

{{protocolo}}
```

---

## # Fase 04 — Empaquetar los cuatro runtimes

```markdown
Esta es la sesión de la **Fase 04 — 🏗️ Empaquetar los cuatro runtimes** ⭐. Entregable:
`04-empaquetar-los-cuatro-runtimes.md`, más los Dockerfile definitivos de `src/lab/services/` y la
tarea `measure` funcionando.

## Marco
El de F00, más F03 cerrada y `BENCHMARKS.md` con su esqueleto.

## Identidad
- Fase 04 de 27 · Parte I · **densa** · 24 ejercicios · plantilla de plataforma
- Medición: **B-04**, la primera del curso · Servicios: los cinco

## Alcance
El de la ficha F04, completo.

## Qué vigilar
- **Esta fase fija el arnés.** `task measure -- B-04` tiene que ser reproducible, con el crudo en
  `src/lab/bench/`, dispersión real y la máquina declarada. Las otras cinco mediciones van a copiar
  esta forma: si queda floja, arrastra al curso.
- **El patrón es uno y cada runtime lo paga distinto**: esa es la tesis. `pricing` completo, y los
  otros tres solo en lo que difieren (Java y su JRE, PHP con FPM y nginx, Node y sus dependencias,
  el `storefront` que termina en archivos estáticos).
- **Imágenes base con criterio**: musl contra glibc, el shell que se pierde, y qué depurar sin él.
  Ninguna base elegida sin su porqué.
- **El digest contra el tag** cierra la fase con el ⚰️ de *"pero si yo desplegué el arreglo"*.
- **La conclusión se escribe sobre la proporción**, no sobre los megabytes.

{{protocolo}}
```

---

## # Fase 05 — Los dos motores, sin guerra

```markdown
Esta es la sesión de la **Fase 05 — 🦭 Los dos motores, sin guerra**. Entregable:
`05-los-dos-motores.md`.

## Marco
El de F00, más F04 cerrada.

## Identidad
- Fase 05 de 27 · Parte I · **ligera** · 12 ejercicios · plantilla de plataforma
- Medición: **B-05** · Plataforma verificada: macOS arm64; lo de Windows y Linux, marcado

## Alcance
El de la ficha F05, completo.

## Qué vigilar
- **Sin guerra.** Ninguna frase de foro. Cada motor gana en algún sitio de la medición, y si
  empatan, se llama empate.
- **La medición es publicada y opcional de ejecutar**: el lector puede no tener los dos motores.
- **La carga de imágenes a kind con Podman** se resuelve aquí una vez, porque la F08 la va a
  necesitar, y queda escondida en `images:load`.
- **Es ligera**: 2.500–3.500 palabras. Si crece, algo de la F03 o de la F07 se coló.

{{protocolo}}
```

---

## # Fase 06 — Del compose al cluster

```markdown
Esta es la sesión de la **Fase 06 — 🪜 Del compose al cluster**. Entregable:
`06-del-compose-al-cluster.md`, más el esqueleto de `a05` con la tabla compose ⇄ Kubernetes.

## Marco
El de F00, más F05 cerrada.

## Identidad
- Fase 06 de 27 · Parte I · **densa** · 24 ejercicios · plantilla de plataforma
- Sin cluster todavía: la fase razona sobre compose y usa `podman kube play` como puente

## Alcance
El de la ficha F06, completo.

## Qué vigilar
- **Es la sección insignia del curso**: la 🪞 de dónde se rompe el instinto de compose, con cada
  caso **demostrado** en compose, no contado. `depends_on` que no espera se ve fallar.
- **El bucle de reconciliación** es el concepto del que cuelga todo lo demás. Se explica con un
  diagrama y sin cluster; la F08 lo va a mostrar en vivo.
- **El diccionario en las dos direcciones** va completo a `a05`; en la fase, la tabla corta.
- **Lo que no tiene traducción** se nombra con destino (qué fase lo trae).
- **Compose gana en algo, con número**: esta es una de las fases donde se concede.

{{protocolo}}
```

---

## # Fase 07 — El cluster local

```markdown
Esta es la sesión de la **Fase 07 — ☸️ El cluster local**. Entregable: `07-el-cluster-local.md`,
más `src/lab/kind/` y el esqueleto de `a04`.

## Marco
El de F00, más la Parte I cerrada.

## Identidad
- Fase 07 de 27 · Parte II · **media** · 20 ejercicios · plantilla de plataforma
- Perfiles: `minimo` y `lab` (los dos se levantan) · Medición: **B-07**

## Alcance
El de la ficha F07, completo.

## Qué vigilar
- **Un nodo alcanza para casi todo**, y la fase lo dice con la memoria medida de los dos clusters.
  El de tres nodos se levanta, se mira y se apaga.
- **La comparación de clusters se hace una vez y se archiva**: nada de volver a ella en otra fase.
  Si alguno no corre sobre Podman, se declara.
- **Contextos y la higiene de no equivocarse de cluster**: al menos un ejercicio lo provoca.
- **Por qué `localhost` llega o no llega al pod** se deja planteado; se resuelve en la F10.

{{protocolo}}
```

---

## # Fase 08 — El primer despliegue, en YAML plano

```markdown
Esta es la sesión de la **Fase 08 — 🚀 El primer despliegue, en YAML plano** ⭐. Entregable:
`08-el-primer-despliegue.md`, más `src/lab/deploy/manifests/` con `pricing` y las entradas 05–06 del
cuaderno.

## Marco
El de F00, más F07 cerrada y el cuaderno con su esqueleto.

## Identidad
- Fase 08 de 27 · Parte II · **densa** · 24 ejercicios · plantilla de plataforma
- Servicio: solo `pricing`, en el namespace `default` a propósito · Incidentes: 05, 06

## Alcance
El de la ficha F08, completo.

## Qué vigilar
- **Cada campo a mano y con su porqué.** Ninguna herramienta genera nada.
- **El bucle de reconciliación en vivo**: borrar un pod y ver volver otro, y leer los eventos.
- **Los dos primeros incidentes de plataforma** se escriben completos en el cuaderno, con sus tags
  y su `inc:break`; en la fase, solo el síntoma.
- **`describe`, `logs` y `events`** se estrenan en el incidente que los necesita, no en una lista.
- **Estrena `task inc:break`**: se explica una vez, corto.

{{protocolo}}
```

---

## # Fase 09 — Los cuatro servicios dentro

```markdown
Esta es la sesión de la **Fase 09 — 🧱 Los cuatro servicios dentro**. Entregable:
`09-los-cuatro-servicios-dentro.md`, más el paso G1 en `src/lab/` y la entrada 07 del cuaderno.

## Marco
El de F00, más F08 cerrada y los prompts G1 en `a03`.

## Identidad
- Fase 09 de 27 · Parte II · **media** · 20 ejercicios · plantilla de plataforma
- Paso de generación: **G1 · Almacén propio** 🌊 · Incidente: 07

## Alcance
El de la ficha F09, completo.

## Qué vigilar
- **SQLite dentro del pod es una deuda 💸 con fecha**: la F12. Se declara aquí con esas palabras, y
  la fase no la "arregla" antes de tiempo.
- **Nadie se llama todavía**: el `ConfigMap` con las URL de los vecinos existe y no se usa, y eso
  es deliberado.
- **Los otros tres siguen a `pricing`**, y la sección 6 cuenta solo sus fricciones.
- **La suite G1 corre contra el cluster** por primera vez.

{{protocolo}}
```

---

## # Fase 10 — La entrada al sistema

```markdown
Esta es la sesión de la **Fase 10 — 🌐 La entrada al sistema**. Entregable:
`10-la-entrada-al-sistema.md`, más `src/lab/platform/gateway/`, la entrada 08 del cuaderno y la
tabla `Ingress` ⇄ Gateway API en `a05`.

## Marco
El de F00, más F09 cerrada. Envoy Gateway, con su versión fijada en `a01`.

## Identidad
- Fase 10 de 27 · Parte II · **media** · 20 ejercicios · plantilla de plataforma
- Plataforma verificada: macOS arm64; lo de Windows y Linux, marcado · Incidente: 08

## Alcance
El de la ficha F10, completo.

## Qué vigilar
- **El *strangler* es el cierre de la fase (D27)**: Contingencia en el namespace `legacy`, detrás del
  mismo `Gateway`, y los pesos de la `HTTPRoute` de precios moviéndose hasta cero. Se demuestra con
  tráfico real y se cuenta como lo que Paracelso tiene que hacer con el Siga de verdad.
- **Ningún objeto `Ingress` se despliega.** La sección 📖 enseña a leer uno y traducirlo, y dice
  por qué el curso no lo usa, sin tono de funeral.
- **`LoadBalancer` en `Pending` primero, y después cloud-provider-kind** delante del lector: la
  lección es que un objeto no hace nada sin alguien que lo implemente. Si en alguna plataforma o
  con algún motor no llega al host, la fase lo declara y usa la alternativa de `a01`.
- **El reparto de papeles de Gateway API** (quién escribe el `Gateway`, quién la `HTTPRoute`) es el
  concepto, no la sintaxis.
- **Envoy Gateway es el que se instala, y no el único**: la tabla de alternativas (Traefik, NGINX
  Gateway Fabric, kgateway, Istio, Cilium) da ventajas y desventajas de criterio, sin medir ni
  instalar ninguna. Si una ventaja no se puede sostener con la documentación oficial, no se escribe.
- **8080 y 8443, nunca 80 y 443**, con el porqué de Podman sin privilegios.
- **`.localhost` y el `curl` que a veces no llega**: la excepción se muestra en la plataforma donde
  ocurra.

{{protocolo}}
```

---

## # Fase 11 — Configuración y secretos

```markdown
Esta es la sesión de la **Fase 11 — ⚙️ Configuración y secretos** ⭐. Entregable:
`11-configuracion-y-secretos.md`, más el paso G2 del `storefront` y las entradas 09–10 del cuaderno.

## Marco
El de F00, más F10 cerrada.

## Identidad
- Fase 11 de 27 · Parte II · **media** · 20 ejercicios · plantilla de plataforma
- Paso de generación: **G2 · Configuración en arranque** (`storefront`) · Incidentes: 09, 10

## Alcance
El de la ficha F11, completo.

## Qué vigilar
- **La pieza central son dos despliegues de la misma imagen del `storefront`** que apuntan a sitios
  distintos, y cómo uno de los dos falla. Se reproduce, no se cuenta.
- **base64 no es cifrado**, demostrado con un comando.
- **Cambiar un `ConfigMap` no reinicia nada**: incidente 09, y la prevención (el hash de
  configuración en la plantilla) queda anunciada para Helm en la F13.
- **Gestores de secretos externos: exclusión declarada**, sin decir dónde estaría.

{{protocolo}}
```

---

## # Fase 12 — Estado, almacenamiento y datos iniciales

```markdown
Esta es la sesión de la **Fase 12 — 💾 Estado, almacenamiento y datos iniciales**. Entregable:
`12-estado-y-almacenamiento.md`, más `src/lab/platform/data/postgres/`, el paso G3 y la entrada 11
del cuaderno.

## Marco
El de F00, más F11 cerrada y los prompts G3 en `a03`.

## Identidad
- Fase 12 de 27 · Parte II · **densa** · 24 ejercicios · plantilla de plataforma
- Paso de generación: **G3 · Postgres** · Medición: **B-12** · Incidente: 11

## Alcance
El de la ficha F12, completo.

## Qué vigilar
- **Abre rompiendo**: el stock fantasma con dos réplicas sobre SQLite. **Es el riesgo más grande de
  la Parte II**: si el experimento no produce un fallo silencioso claro, la fase entera se
  replantea, y hay que decirlo en el paso 1 antes de escribir nada.
- **Postgres con la imagen oficial y un `StatefulSet` escrito a mano**, sin charts de terceros.
- **La divergencia se declara en voz alta**: un servidor con una base por servicio en vez de
  instancias separadas, y qué se pierde.
- **Migraciones contra rollout**: qué pasa si dos réplicas migran a la vez, provocado.
- **El seed es el script de Python de `a01`** (D31), empaquetado en una imagen y corrido como `Job`.
  No se reescribe: se enlaza.
- **B-12 compara SQLite contra Testcontainers** en tiempo de suite y en fidelidad, con el bug que
  SQLite no detecta.
- **⚖️ Postgres en el cluster**: lo vas a hacer aquí y probablemente no en producción.
- **La autopsia es la de la Braqui pegada a las tablas del Siga** (historia §1.11), con su mejor
  argumento antes que el del curso: Germán quería una sola verdad, y la tuvo. Y se muestra en vivo:
  la Braqui del patrimonio sondea las tablas de Contingencia, y la fase lo deja ver antes de darle a
  `replenish` su base propia.
- **El script de traslados pasa a `CronJob` (D30)**: `concurrencyPolicy: Forbid` y
  `activeDeadlineSeconds` en vez del archivo de bloqueo, con el bloqueo huérfano provocado antes.
  Las demás mañas del script se nombran y se dejan para la Parte IV, sin arreglarlas aquí.

{{protocolo}}
```

---

## # Fase 13 — Helm: el paquete

```markdown
Esta es la sesión de la **Fase 13 — 📦 Helm: el paquete**. Entregable: `13-helm-el-paquete.md`, más
`src/lab/charts/platform/` con los tres perfiles e interruptores.

## Marco
El de F00, más F12 cerrada.

## Identidad
- Fase 13 de 27 · Parte II · **densa** · 24 ejercicios · plantilla de plataforma
- Herramienta: Helm 4, la versión de `a01`

## Alcance
El de la ficha F13, completo.

## Qué vigilar
- **Abre con el dolor**: los archivos casi idénticos, contados en el repositorio del lector.
- **El chart reproduce exactamente lo que el YAML plano hacía**: la prueba es que la suite pasa igual
  y el `diff` de los manifiestos renderizados contra los de la F12 es vacío o explicado línea a
  línea.
- **Los interruptores de observabilidad y de bus nacen aquí como valores**, aunque todo siga
  apagado: el contrato §5 manda en los nombres.
- **Los *hooks* reemplazan los `Job` sueltos** del seed y las migraciones.
- **Si Helm 4 cambió algo que la documentación vieja da por hecho**, se dice con esas palabras.

{{protocolo}}
```

---

## # Fase 14 — Helm en operación

```markdown
Esta es la sesión de la **Fase 14 — 🔧 Helm en operación**. Entregable: `14-helm-en-operacion.md`.

## Marco
El de F00, más F13 cerrada.

## Identidad
- Fase 14 de 27 · Parte II · **media** · 20 ejercicios · plantilla de plataforma
- Perfiles: los tres, en uso real

## Alcance
El de la ficha F14, completo.

## Qué vigilar
- **La red de seguridad**: `upgrade`, `rollback`, `--dry-run` y el diff previo, cada uno usado en
  un cambio que sale mal.
- **Kustomize, sección corta y sin guerra**: plantillas contra parches, con el mismo cambio hecho de
  las dos formas.
- **GitOps queda como apéndice `a11`**: puntero y se sigue.
- **La segunda cadena** (`tenant-b` en `apps-b`) es la cuarta pregunta del encargo de la historia.
  La prueba es que no se toca código: solo un archivo de valores. Se apaga al cerrar la fase.

{{protocolo}}
```

---

## # Fase 15 — Salud y recursos

```markdown
Esta es la sesión de la **Fase 15 — 🩺 Salud y recursos** ⭐. Entregable: `15-salud-y-recursos.md`,
más el paso G4 y las entradas 12–15 del cuaderno.

## Marco
El de F00, más F14 cerrada y los prompts G4 en `a03`.

## Identidad
- Fase 15 de 27 · Parte II · **densa** · 24 ejercicios · plantilla de plataforma
- Paso de generación: **G4 · Readiness real** · Incidentes: 12, 13, 14, 15

## Alcance
El de la ficha F15, completo.

## Qué vigilar
- **La autopsia del `OOMKilled` es la de Java 25**, no la de la JVM que ignoraba el contenedor. Se
  reproduce con una decisión razonable (un `-Xmx` heredado, o `MaxRAMPercentage` cerca del cien),
  se mide la memoria que no es heap, y se arregla con número antes y después. Si la explicación
  histórica aparece, es como una línea de contexto, no como la causa.
- **Readiness contra liveness** es el concepto que casi nadie tiene claro: los dos fallos se
  provocan y se ven, uno cortando tráfico y el otro reiniciando pods sanos.
- **El mismo campo significa cosas distintas por runtime**: la sección 6 es la más importante de
  la fase, no un apéndice de la 5.
- **El AOT cache es sección corta 🔥** y apunta a `a08`.
- **Las cuotas por namespace se muestran con las dos cadenas encendidas**, y la memoria que suma la
  segunda se mide y se declara.
- **Cuatro incidentes en una fase**: los cuatro completos en el cuaderno, y en la fase solo el
  síntoma. Es la fase donde más fácil se filtra una solución.

{{protocolo}}
```

---

## # Fase 16 — Escalado y rollout

```markdown
Esta es la sesión de la **Fase 16 — 📈 Escalado y rollout**. Entregable: `16-escalado-y-rollout.md`,
más el paso G5 (el flujo de venta) y las entradas 16–17 del cuaderno.

## Marco
El de F00, más F15 cerrada y los prompts G5 en `a03`.

## Identidad
- Fase 16 de 27 · Parte II · **densa** · 24 ejercicios · plantilla de plataforma
- Paso de generación: **G5 · El flujo de venta** 🌊 · Perfil: **`lab`**, por primera vez en uso
- Medición: **B-16** · Incidentes: 16, 17

## Alcance
El de la ficha F16, completo.

## Qué vigilar
- **Es la primera vez que un servicio llama a otro por trabajo de negocio**, y se dice. El aviso a
  `replenish` sin esperar respuesta queda como deuda 💸 para la F25, con esas palabras.
- **La decepción honesta del HPA**: reacciona tarde, mide una métrica, y con PHP-FPM se comporta
  distinto. Medido, no opinado.
- **Se cobra el `SIGTERM` de la F03**: un rollout con carga, primero cortando peticiones y después
  sin cortar ninguna, contado con k6.
- **B-16 cierra la tesis de la Parte II**: réplicas y memoria por runtime para la misma tasa.
- **🚧 PodDisruptionBudget, autoescalado de nodos y multi-zona**: se nombran y se sigue.

{{protocolo}}
```

---

## # Fase 17 — Métricas y dashboards

```markdown
Esta es la sesión de la **Fase 17 — 📊 Métricas y dashboards**. Entregable:
`17-metricas-y-dashboards.md`, más `src/lab/platform/observability/` (métricas y tableros) y el paso
G6.

## Marco
El de F00, más la Parte II cerrada y los prompts G6 en `a03`.

## Identidad
- Fase 17 de 27 · Parte III · **densa** · 24 ejercicios · plantilla de plataforma
- Paso de generación: **G6 · Métricas** · Observabilidad: métricas y tableros encendidos

## Alcance
El de la ficha F17, completo.

## Qué vigilar
- **El `scrape_config` a mano**, sin Operator, con el modelo de *pull* explicado sobre él.
- **Los interruptores se estrenan de verdad**: la fase mide la memoria de cada pieza encendida y el
  lector sale sabiendo apagarla.
- **La instrumentación de los cuatro runtimes, comprimida**: es el mismo concepto cuatro veces, y
  `inventory` cumple la ruta `/metrics` remapeando Actuator, dicho una vez.
- **La tesis**: exponer métricas es responsabilidad de la aplicación.
- **Alertas: exclusión declarada.**

{{protocolo}}
```

---

## # Fase 18 — Logs

```markdown
Esta es la sesión de la **Fase 18 — 🔎 Logs**. Entregable: `18-logs.md`, más el paso G7 y la pieza
de logs en `src/lab/platform/observability/`.

## Marco
El de F00, más F17 cerrada y los prompts G7 en `a03`.

## Identidad
- Fase 18 de 27 · Parte III · **media** · 20 ejercicios · plantilla de plataforma
- Paso de generación: **G7 · Logs estructurados** · Perfil: `lab` · Observabilidad: logs encendidos

## Alcance
El de la ficha F18, completo.

## Qué vigilar
- **La fricción real de Java y PHP**, que loguean texto plano por defecto, es el contenido. Node y
  Go van en un párrafo.
- **El `DaemonSet` se ve en el perfil `lab`**: un pod de Fluent Bit por nodo, contado.
- **LogQL para seguir una venta por cuatro servicios**, sin `traceId` todavía: la fase muestra lo
  incómodo que es, y deja la deuda 💸 para la F23.

{{protocolo}}
```

---

## # Fase 19 — TLS y certificados

```markdown
Esta es la sesión de la **Fase 19 — 🔐 TLS y certificados** ⭐. Entregable:
`19-tls-y-certificados.md`, más `src/lab/platform/cert-manager/`, el paso G8 y las entradas 18–24 del
cuaderno.

## Marco
El de F00, más F18 cerrada y los prompts G8 en `a03`.

## Identidad
- Fase 19 de 27 · Parte III · **densa** · 24 ejercicios · plantilla de plataforma
- Paso de generación: **G8 · Cliente mTLS** · Incidentes: 18 a 24, los siete de certificados
- Plataforma verificada: macOS arm64. La confianza en el host y el incidente 24 divergen por
  plataforma: lo de Windows y Linux, marcado

## Alcance
El de la ficha F19, completo.

## Qué vigilar
- **`openssl` primero, cert-manager después**: la cadena de confianza se entiende a mano antes de
  que nada la automatice.
- **El listener HTTPS es del `Gateway`**, no de ningún `Ingress`.
- **Siete incidentes, completos en el cuaderno**, con su literal. El 24 (registry con CA propia) es
  el 🦭 más rico del curso: la confianza se configura en tres sitios según quién trae la imagen, y
  los tres se prueban.
- **mTLS a mano entre `inventory` y `pricing`** y nada más: el mesh es `a10`.
- **La confianza instalada en el host se desinstala al terminar**, y la fase lo dice.

{{protocolo}}
```

---

## # Fase 20 — Seguridad del pod y de la red

```markdown
Esta es la sesión de la **Fase 20 — 🛡️ Seguridad del pod y de la red**. Entregable:
`20-seguridad-del-pod-y-de-la-red.md`, más las entradas 25–26 del cuaderno.

## Marco
El de F00, más F19 cerrada. La verificación ya decidió si kindnet aplica `NetworkPolicy`.

## Identidad
- Fase 20 de 27 · Parte III · **media** · 20 ejercicios · plantilla de plataforma
- Incidentes: 25, 26

## Alcance
El de la ficha F20, completo.

## Qué vigilar
- **El experimento que lo justifica**: la base de datos alcanzable desde cualquier pod, demostrada
  con un pod cualquiera antes de escribir una política.
- **Una política no hace nada si la red no la aplica**: si hace falta otro CNI, la fase lo instala y
  lo dice; si no, lo demuestra.
- **RBAC mínimo y provocado por un fallo real**, no como tabla de verbos.
- **El aislamiento entre las dos cadenas** cierra la fase, y lo que no resuelve (los datos en el
  mismo Postgres, la identidad) se declara como frontera de un SaaS de verdad.
- **Se cobra lo que la F03 sembró** sobre usuarios y permisos.
- **Mesh: puntero a `a10`** y se sigue.

{{protocolo}}
```

---

## # Fase 21 — Diagnóstico: el kit y el cuaderno

```markdown
Esta es la sesión de la **Fase 21 — 🩻 Diagnóstico: el kit y el cuaderno**. Entregable:
`21-diagnostico.md`, y después, en la misma tanda, la sesión de revisión del cuaderno
(`formato-cuaderno-incidentes.md` §11).

## Marco
El de F00, más F20 cerrada y los incidentes 01–27 escritos.

## Identidad
- Fase 21 de 27 · Parte III · **densa** · 24 ejercicios · plantilla de plataforma
- Herramientas: `describe`, `logs --previous`, `events`, `exec`, `port-forward`, `kubectl debug`,
  k9s

## Alcance
El de la ficha F21, completo.

## Qué vigilar
- **El método se enseña con incidentes que el lector ya tiene**, no con nuevos: la fase remite al
  cuaderno y recorre tres o cuatro entradas con el método explícito.
- **Cada herramienta se estrena en el incidente que la necesita**, nunca en una lista. La lista
  vive en `a04`.
- **El método de la fase y el del cuaderno §5 dicen lo mismo con las mismas palabras.**
- **Los ejercicios son laboratorios rotos sin decir qué tienen**: aquí el tercio de diagnóstico
  sube a la mitad.

{{protocolo}}
```

---

## # Fase 22 — Resiliencia, y el generador de caos

```markdown
Esta es la sesión de la **Fase 22 — 🔥 Resiliencia, y el generador de caos**. Entregable:
`22-resiliencia-y-caos.md`, más `src/lab/chaos/` y el paso G9.

## Marco
El de F00, más la Parte III cerrada y los prompts G9 y del generador en `a03`.

## Identidad
- Fase 22 de 27 · Parte IV · **media** · 20 ejercicios · plantilla de plataforma
- Paso de generación: **G9 · Resiliencia** · Perfil: `lab`, con métricas encendidas

## Alcance
El de la ficha F22, completo.

## Qué vigilar
- **La pregunta que ordena la Parte IV** se hace aquí por primera vez: ¿esto va en tu código o en
  la plataforma? Y se responde con honestidad: algunas cosas van en los dos sitios.
- **El reintento que empeora las cosas** se provoca y se mide en el tablero.
- **El generador de caos es código propio en Go**, generado como los servicios, corto y legible.
- **El mesh aparece solo como puntero** (`a10`): es una de las respuestas y no la única.

{{protocolo}}
```

---

## # Fase 23 — gRPC, y el balanceo que no balancea

```markdown
Esta es la sesión de la **Fase 23 — 🔌 gRPC, y el balanceo que no balancea** ⭐. Entregable:
`23-grpc-y-el-balanceo.md`, más `src/lab/contracts/proto/` y el paso G10.

## Marco
El de F00, más F22 cerrada y los prompts G10 en `a03`.

## Identidad
- Fase 23 de 27 · Parte IV · **densa** · 24 ejercicios · plantilla de plataforma
- Paso de generación: **G10 · gRPC y trazas** · Medición: **B-23** · Observabilidad: trazas
  encendidas por primera vez

## Alcance
El de la ficha F23, completo.

## Qué vigilar
- **El fallo que justifica la fase**: todo el tráfico en una réplica. Si no se reproduce con
  claridad en el perfil `lab`, se para y se replantea antes de escribir.
- **B-23 mide la distribución antes y después**, y el arreglo elegido se defiende contra las
  alternativas (balanceo en el cliente, `Service` headless, proxy).
- **OpenTelemetry en los cuatro runtimes** separa otra vez a PHP (la extensión) de los demás; la
  fricción es contenido.
- **Se cobra la deuda de la F18**: la misma venta, ahora seguida por su `traceId`.

{{protocolo}}
```

---

## # Fase 24 — La saga orquestada

```markdown
Esta es la sesión de la **Fase 24 — 🎬 La saga orquestada**. Entregable:
`24-la-saga-orquestada.md`, más el paso G11.

## Marco
El de F00, más F23 cerrada y los prompts G11 en `a03`.

## Identidad
- Fase 24 de 27 · Parte IV · **densa** · 24 ejercicios · plantilla de plataforma
- Paso de generación: **G11 · Saga orquestada** · Perfil: `lab`, con trazas encendidas

## Alcance
El de la ficha F24, completo.

## Qué vigilar
- **Abre con el procedimiento del préstamo** en PL/pgSQL dentro de Contingencia (D28): una
  transacción en una sola base, que funciona. La saga existe porque esa base deja de ser una.
- **"Deshacer" es una operación de negocio**: cada compensación sale de una regla de la historia.
  Si la historia no la tiene, se agrega allí primero.
- **El fallo a mitad de saga se provoca con el generador de caos** y se observa en las trazas, con
  el sistema a medio compensar.
- **La saga que ya existía (D30)**: el aviso de traslados por archivo, sin compensaciones, se
  muestra antes de la primera compensación escrita. Es de donde salen los huérfanos de los lunes.
- **Nada de esto lo resuelve Kubernetes**, y la fase lo dice en su veredicto con esas palabras.

{{protocolo}}
```

---

## # Fase 25 — La coreografía, y los mensajes que se pierden

```markdown
Esta es la sesión de la **Fase 25 — 📡 La coreografía, y los mensajes que se pierden**. Entregable:
`25-la-coreografia.md`, más el paso G12 y `src/lab/platform/data/` con Valkey y NATS.

## Marco
El de F00, más F24 cerrada y los prompts G12 en `a03`.

## Identidad
- Fase 25 de 27 · Parte IV · **densa** · 24 ejercicios · plantilla de plataforma
- Paso de generación: **G12 · Coreografía** · Bus: Valkey y después NATS, encendidos por interruptor

## Alcance
El de la ficha F25, completo.

## Qué vigilar
- **Abre rompiendo**: el mensaje del pub/sub que no existió nunca. Tiene que verse, no contarse.
- **Se cobra la deuda 💸 de la F16**: el aviso a `replenish` sin esperar respuesta.
- **El antecedente es el `.txt` de la Braqui (D30)**: el archivo leído a medio subir es el mensaje
  que no existió nunca, en 2020. Se nombra en una escena corta, no se reconstruye.
- **El veredicto orquestación contra coreografía** es lo que nadie dice: cuándo conviene cada una,
  con lo que se midió en las dos fases.
- **La factura del arreglo queda abierta a propósito**: "al menos una vez" es "a veces dos veces",
  y la F26 la paga.

{{protocolo}}
```

---

## # Fase 26 — Idempotencia y outbox

```markdown
Esta es la sesión de la **Fase 26 — 🔁 Idempotencia y outbox** ⭐. Entregable:
`26-idempotencia-y-outbox.md`, más el paso G13.

## Marco
El de F00, más F25 cerrada y los prompts G13 en `a03`.

## Identidad
- Fase 26 de 27 · Parte IV · **densa** · 24 ejercicios · plantilla de plataforma
- Paso de generación: **G13 · Idempotencia y outbox**

## Alcance
El de la ficha F26, completo.

## Qué vigilar
- **La escritura dual se provoca** antes de arreglarla: el dato escrito y el evento perdido, o al
  revés, en el momento exacto en que el pod muere.
- **Los dos parches del script que no alcanzaron (D30)**: la tabla de procesados por nombre de
  archivo contra la clave de idempotencia por traslado, y el `.txt` escrito después del commit como
  la escritura dual de La Vecina. El outbox lo reemplaza, y la fase lo dice.
- **El publicador del outbox como *sidecar* nativo** es el sitio donde el curso muestra ese patrón;
  si la versión de Kubernetes fijada lo cambia, se dice.
- **Event sourcing y CQRS: exclusión declarada**, sin decir dónde estarían.

{{protocolo}}
```

---

## # Fase 27 — El veredicto honesto, y el proyecto final

```markdown
Esta es la sesión de la **Fase 27 — ⚖️ El veredicto honesto, y el proyecto final**. Entregable:
`27-el-veredicto-y-el-proyecto-final.md`.

## Marco
El de F00, más las 27 fases anteriores cerradas, `BENCHMARKS.md` con sus seis entradas del camino
base y `a05` con los diccionarios completos.

## Identidad
- Fase 27 de 27 · Cierre · **densa** · 12 ejercicios · plantilla de cierre

## Alcance
El de la ficha F27, completo.

## Qué vigilar
- **Cada rama del árbol de decisión cita una medición o un instinto** del curso. Una rama que se
  sostiene con opinión se reescribe.
- **La primera pregunta del árbol es la más incómoda**: ¿lo resolvía un contenedor y un servicio del
  sistema? Y en algunos casos la respuesta es sí.
- **El proyecto final es ejecutable de punta a punta**: se hace una vez con un servicio de prueba
  antes de publicar el enunciado, y los criterios de aceptación son comandos.
- **La frontera con la nube 🚧 🌩️** se consolida sin prometer lo que el laboratorio no mostró.

{{protocolo}}
```

---

## 🧾 Recordatorio de cierre del curso

El curso se cerró el 05/10/2026: las 28 fases, los apéndices 🔥, el cierre de los que crecen, el README y
`0-ESTRUCTURA-CURSO.md`. El plan de producción se borró con los demás desechables; lo que una sesión futura necesita
saber del estado está en `0-ESTRUCTURA-CURSO.md`, en la propuesta de fases §12 (decisiones D1–D43) y en
`verificacion-de-laboratorio/hallazgos.md`.
