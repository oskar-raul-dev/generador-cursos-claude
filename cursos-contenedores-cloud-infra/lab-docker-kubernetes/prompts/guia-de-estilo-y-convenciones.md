# ✍️ Guía de estilo, tono y convenciones
## Laboratorio de contenedores y Kubernetes local

Esta guía es la fuente de verdad editorial del curso. Cualquier sesión que produzca un `.md` de este
proyecto la sigue. Su objetivo es que las veintiocho fases, los apéndices y el cuaderno de
incidentes se lean como escritos por la misma mano, y que todos apunten al mismo sitio: **que el
lector sepa qué le da el contenedor, qué le da el orquestador y qué le sigue tocando escribir a él,
y lo pueda demostrar en su laboratorio**.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que mañana tiene que
explicarle a su equipo por qué el pod de Java murió sin dejar ni una línea de log.

> **Precedencia.** Por encima de esta guía solo está
> [`alcance-del-proyecto.md`](alcance-del-proyecto.md), que decide **qué** enseña el curso; esta
> decide **cómo** se escribe. Por debajo van el [contrato del cluster](contrato-del-cluster.md), las
> dos propuestas, las plantillas, los prompts y el formato del cuaderno, que se actualizan después y
> nunca al revés. El `CLAUDE.md` del repositorio aplica en todo lo que este curso no haya declarado
> como excepción (§17).
>
> **Derivada de** la guía de la Ruta SQL (30/09/2026). Lo que se hereda sin cambios se hereda en
> silencio; lo que cambia está en §4 (el andamio de este curso), §5 (YAML, Dockerfile y dos
> shells), §6 (qué se mide), §8 (los marcadores propios), §9 (longitud por peso) y §17.

---

## 1. 🧭 Principio rector

**Todo lo que se escribe apunta a que alguien opere con criterio y lo pueda defender con su
laboratorio.**

No enseñamos productos ni formamos administradores de cluster. Formamos la capacidad de mirar un
sistema en contenedores y saber qué capa resuelve cada problema, qué cuesta cada decisión, y qué
mirar primero cuando algo se rompe.

El filtro para cada párrafo es este: **¿esto ayuda a construir, a diagnosticar, a medir o a
decidir?** Si no, sobra, aunque esté muy bien escrito. Sobre todo si está muy bien escrito.

> 🧠 **Primero funciona, después se entiende, y al final se rompe a propósito.** Es el orden de casi
> todas las fases.

---

## 2. 🎤 Tono

**Semiformal, cálido y directo**, con humor cuando cae bien. Un colega senior que ya se quedó
despierto por un certificado vencido y te lo explica con paciencia, sin solemnidad de manual y sin
palmaditas en la espalda.

- **Tuteo latinoamericano, siempre.** *"Corre `kubectl describe` y mira la sección de eventos"*.
  Nada de voseo, nada de "usted" y nada de impersonal permanente.
- **Los personajes hablan como hablan**, y es la excepción declarada a la regla anterior. En el
  diálogo citado entre comillas, los santandereanos usan *usted* y *mano*, y los boyacenses
  *sumercé*, como en la historia §8.3. La narración y toda instrucción al lector siguen en tuteo
  neutro. Una frase regional por escena, no un acento impostado.
- **Semiformal.** Frases completas, puntuación correcta, cero abreviaturas de mensajería.
- **Humor seco y con moderación**, máximo un chiste por sección. El que sale solo en este curso es
  el del YAML: úsalo con cariño, porque el lector va a escribir mucho.
- **Cálido sin condescendencia.** El lector sabe programar. Lo que se le explica con cero ambigüedad
  es lo que la plataforma hace con su programa.
- **Honesto sobre lo feo.** Si compose era suficiente para lo que la fase acaba de montar, se dice
  con esas palabras y con el número delante.

### 2.1 El tono de las autopsias

⚰️ Una autopsia se escribe sobre una **decisión**, jamás sobre una persona ni sobre una herramienta.
El riesgo en este curso es la guerra de herramientas: Docker contra Podman, Helm contra Kustomize,
Go contra Java. **Ninguna herramienta es la villana**, y un párrafo que suena a foro pierde al
lector que eligió la otra.

La versión que funciona **defiende la decisión antes de desmontarla**, en este orden:

1. La decisión, con su mejor argumento: *"le puse `-Xmx4g` porque así corría en la VM"*.
2. Por qué era razonable en ese contexto.
3. Qué pasó después, con número.
4. Cuánto costó salir, con número.
5. Qué capa, qué campo o qué pregunta habría cambiado el resultado.

Lo que nunca aparece: "obviamente", "cualquiera habría visto", "error de novato", "mala práctica" a
secas, ni ninguna variante de la misma superioridad.

---

## 3. 🗣️ Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no sea código o salida de
  terminal.
- **Los términos del oficio se quedan en inglés** cuando son el nombre real de la cosa y así
  aparecen en la salida: *pod*, *rollout*, *readiness*, *liveness*, *sidecar*, *probe*, *DaemonSet*,
  *StatefulSet*, *CrashLoopBackOff*, *OOMKilled*, *backoff*, *circuit breaker*, *outbox*, *at least
  once*. Los que tienen traducción asentada se usan en español: contenedor, imagen, capa, nodo,
  réplica, volumen, espacio de nombres (o namespace, el mismo en todo el documento), certificado,
  sonda. **No inventar vocabulario**, y no alternar las dos formas en un mismo documento.
- **Los objetos de Kubernetes van en `código` y con su mayúscula**: `Deployment`, `Service`,
  `HTTPRoute`, `PersistentVolumeClaim`. Son nombres propios de la API.
- **Markdown siempre.** Nada de HTML embebido salvo que no haya alternativa.
- **Prosa antes que listas.** Un párrafo que explica *por qué* vale más que cinco viñetas que
  enumeran *qué*.
- **Nada de prosa telegrama.** Una frase corta y aislada es un golpe de ritmo; tres seguidas son un
  telegrama. **Una frase aislada por sección, dos si la sección es larga.**
- **Tablas solo para lo tabular y corto**: traducción, comparación medida, versiones, decisión. Tres
  o cuatro columnas como máximo.
- **Diagramas ASCII en bloques `text`** cuando hay estructura que mostrar: el camino de una petición
  desde el navegador hasta el pod, dos réplicas contestando cosas distintas, la cadena de confianza.

  ```text
  EL CAMINO DE UNA PETICIÓN, FASE 10

  navegador ──► localhost:8080 ──► Service del Gateway ──► proxy del Gateway
                                                              │ HTTPRoute: /api/pricing
                                                              ▼
                                        Service pricing (ClusterIP) ──► pod pricing
  ```

- **Salida de terminal literal**, en bloque `text`, sin embellecer y sin recortar la parte
  incómoda. El `Events:` de un `describe` enseña más editado a mano que nunca: por eso no se edita.
- **Encabezados con emoji, con moderación.** Uno por sección numerada, casi ninguno en
  subsecciones.

---

## 4. 🎓 Pedagogía: cómo se explica

El público es senior y programa todos los días. La regla que lo cubre: **no explicar lo que ya
sabe, y no dejar ambiguo nada de lo que no**.

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero, y en el laboratorio.** Algo que funciona deja de funcionar, o algo que
   el lector quiere hacer no se puede hacer con lo que tiene. *"Subes `inventory` a dos réplicas y
   el stock aparece y desaparece según quién conteste."*
2. **El mecanismo después.** El objeto, el campo o la herramienta, con la definición mínima para
   usarlo hoy.
3. **El comando que corre**, con su salida real y la línea que importa señalada.

Presentar el objeto antes que el problema produce lectores que saben recitar los campos de un
`StatefulSet` y no reconocen cuándo lo necesitan.

### 4.2 Del instinto se parte, no se reniega

El lector llega con un modelo mental que funciona casi siempre: el de compose, y a veces el de la
máquina virtual. Dos micro-secciones lo honran antes de corregirlo:

- 🩻 **"Esto sí funciona igual"**: lo que se transfiere sin cambios desde compose, entre motores o
  entre runtimes. Tranquiliza y ahorra páginas.
- 🪞 **"Tu instinto de compose dice… y esta vez se equivoca"**: el punto exacto donde el modelo se
  rompe, con la prueba en el laboratorio. **Uno por fase como mínimo**, y todos se acumulan en
  `INSTINTOS.md`.

### 4.3 Nada de cajas negras prematuras

**YAML plano antes que Helm, siempre.** `kubectl` antes que k9s. El `scrape_config` escrito a mano
antes que cualquier recurso que lo genere. `openssl` antes que cert-manager. Esas capas no son
malas: ocultan justo lo que el curso quiere enseñar, y llegan cuando el lector ya sintió el dolor
que resuelven.

### 4.4 Cuatro runtimes, sin cuatro manuales

**El piloto va primero y los demás lo siguen.** El patrón se construye completo con `pricing`, y
los otros tres se cuentan **solo donde no es mecánico**: PHP con dos procesos, Java que tarda en
estar listo, Node que carga dependencias que Go no tiene. Una sección que muestra el mismo
Dockerfile cuatro veces sin que cambie nada es relleno; las cuatro variantes completas viven en
`src/lab/` y se enlazan.

### 4.5 Dos motores, sin guerra

**Docker es el camino principal de los comandos, y Podman aparece donde diverge**, con el marcador
🦭. Si el comando es idéntico, se dice una vez y no se duplica. Las divergencias reales se cuentan
donde duelen y no en un capítulo de comparación.

### 4.6 Analogías, con fecha de caducidad

Se usan una vez, para abrir la puerta, y se abandonan diciendo dónde se rompen. La más peligrosa del
curso es **"un contenedor es una VM chica"**. Si aparece, se desmonta en el mismo párrafo.

### 4.7 Explica el porqué

Cada campo del YAML que el curso escribe lleva su porqué, aunque sea media línea en el comentario:
por qué este `initialDelaySeconds`, por qué este `limit`, por qué `maxUnavailable: 0`.

### 4.8 Densidad calibrada

- Un concepto nuevo por vez.
- **Repetir lo importante está bien.** "El objeto no hace nada sin alguien que lo implemente", "la
  readiness decide el tráfico, la liveness decide la vida" y "esto no lo resuelve Kubernetes"
  reaparecen en todo el curso.
- Ninguna sección teórica supera las dos pantallas sin un comando, una salida o un diagrama.

### 4.9 Cierra los bucles

Si abres un paréntesis (*"el `SIGTERM` lo cobramos en la Fase 16"*, *"por ahora esto es deuda
💸"*), se cierra en algún documento del curso. Un pendiente que nunca se resuelve es ruido.

---

## 5. 💻 Código, comandos y archivos

> **Regla normativa:** todo lo que se ejecuta o se versiona va en inglés (nombres de archivo, rutas,
> variables de entorno, identificadores, labels, tareas del Taskfile, nombres de objetos) y **todos
> los comentarios van en español con tildes**.

- **Los nombres técnicos son los del [contrato del cluster](contrato-del-cluster.md)**: servicios,
  puertos, rutas, namespaces, hosts, labels, perfiles y tareas. Una fase no inventa uno; si lo
  necesita, lo agrega allí primero.
- **YAML:** dos espacios, un objeto por documento separado con `---`, labels recomendadas de
  Kubernetes y ninguna inventada, y **un comentario en cada campo que el curso elige a propósito**.
- **Dockerfile:** instrucciones en mayúsculas, un `FROM` por etapa con nombre (`AS build`), la base
  fijada por digest con el tag legible en un comentario.
- **Comandos:** bloques `bash` por defecto, que valen igual en macOS, Linux y WSL. **Cuando Windows
  diverge**, el equivalente va en un bloque `powershell` inmediatamente después, y solo ahí. Siempre
  que exista una tarea del Taskfile, se muestra la tarea **y** el comando que corre debajo la primera
  vez que aparece.
- **Nunca `foo`, `bar`, `test1` ni `my-app`.** Todo ejemplo usa los servicios y las entidades del
  curso con datos que parezcan reales.
- **Bloques de código con su lenguaje declarado**: `yaml`, `dockerfile`, `bash`, `powershell`,
  `go`, `java`, `php`, `typescript`, `python` (solo scripts), `proto`, `hurl`, `text` para salida
  de terminal.
- **Scripts:** en Python, uno solo para los tres sistemas, invocado desde una tarea del Taskfile
  (alcance §8). La regla de `bash` y `powershell` de arriba es para comandos sueltos en el texto, no
  para scripts: un script nunca se escribe dos veces.
- **Un bloque, una idea.** Si un manifiesto tiene tres objetos y la sección habla de uno, se muestra
  ese y se enlaza el archivo completo.

### 5.1 Versiones e imágenes

- **Digest, no tag**, con el tag legible en un comentario al lado. `:latest` no aparece nunca salvo
  como anti-patrón.
- **Ninguna versión se escribe de memoria.** Viven en un solo sitio, `a01`, con su fecha de
  verificación, y todo lo demás apunta allí.
- **Si algo no se verificó, se dice con esas palabras**: *"esto no lo ejecuté; la documentación de
  la versión X lo describe así"*.

### 5.2 Nombres de archivo del curso

- **Fases:** `NN-slug.md`, dos dígitos (`00` a `27`). Los slugs son los de la propuesta de fases §11.
- **Apéndices:** `aNN-slug.md`, dos dígitos. Los slugs son los de la propuesta de apéndices §2.
- **Documentos vivos**, en la raíz del curso: `BENCHMARKS.md`, `INSTINTOS.md` y
  `cuaderno-incidentes.md`.
- **Documentos de raíz:** `00-historia-de-la-vecina.md`, `00-convencion-de-git-y-tags.md`,
  `README.md` y `0-ESTRUCTURA-CURSO.md` (los dos últimos, al final: §14).
- **Código:** un único proyecto en `src/lab/` (contrato del cluster §2).

---

## 6. 📏 Cómo se presenta una medición

Una medición mal presentada es peor que ninguna, porque parece evidencia.

**Toda medición se publica con seis datos:**

1. **La hipótesis**, escrita antes de medir y en una línea.
2. **Qué se midió**, con la unidad.
3. **Con qué motor, qué versión de kind y qué perfil.**
4. **En qué máquina**: CPU, memoria y plataforma, porque aquí el tiempo sí es parte de lo medido.
5. **La dispersión**: cuántas corridas, y la mediana con su mínimo y su máximo. Nunca un número
   solo.
6. **Cómo reproducirlo**: `task measure -- <id>`.

Formato de una medición publicada:

```markdown
> 📏 **Medición B-04 · El costo de empaquetar cada runtime** · perfil `medicion` · Docker
> {{versión}} · MacBook {{modelo}}, {{RAM}} · 10 corridas · verificado el {{fecha}}
>
> | | imagen | build en frío | build con caché | hasta el primer 200 |
> |---|---|---|---|---|
> | `pricing` (Go) | {{MB}} | {{s, min–máx}} | {{s}} | {{ms}} |
> | `inventory` (Java) | … | … | … | … |
>
> Reproducir: `task measure -- B-04`
```

**La conclusión se escribe sobre la proporción, no sobre el absoluto.** *"La imagen de `inventory`
pesa once veces la de `pricing`"* sobrevive a la próxima máquina; *"pesa 312 MB"* no sobrevive a la
próxima versión.

**La apuesta** 🪞 se escribe antes de medir y no se edita después. Si se pierde, la pérdida se
cuenta entera.

**La rotura** 🧨 se documenta con el cambio exacto que la provoca, **el síntoma literal** (el estado
del pod, el evento, el error del cliente) y lo que había que cambiar para salir.

### 6.1 El formato de `BENCHMARKS.md`

Cada entrada lleva un identificador `B-NN`, con el número de la fase que la produce, y no se
reutiliza:

```markdown
### B-16 · Réplicas por runtime para la misma tasa
**Hipótesis:** {{la apuesta, tal como se escribió antes}}
**Condiciones:** perfil `lab` · {{motor y versión}} · {{máquina}} · k6 con {{escenario}}
**Resultado:** {{tabla con dispersión}} · **Apuesta:** ganada | perdida | empate
**Veredicto:** {{la guía que se desprende, en una o dos frases}}
**Reproducir:** `task measure -- B-16` · **Fecha:** {{DD/MM/AAAA}}
```

Una entrada publicada nunca se edita. Si la medición se rehace con otra versión, se agrega una
entrada nueva que cita a la anterior.

---

## 7. 📓 El cuaderno de incidentes

Su formato completo está en [`formato-cuaderno-incidentes.md`](formato-cuaderno-incidentes.md).
Lo que afecta a la escritura de una fase:

- Una fase **reserva** los IDs que le corresponden y **escribe sus incidentes completos en el
  cuaderno en la misma tanda**. No se deja un incidente reservado sin enunciado.
- Dentro de la fase, el incidente aparece como 🩺 en su sitio del texto, con el síntoma y un enlace
  al cuaderno. **La solución no se escribe en la fase**: vive solo en el cuaderno.

---

## 8. 🧷 Marcadores, callouts y encabezado

### 8.1 Bloque de encabezado obligatorio

```markdown
# 🩺 Fase 15 — Salud y recursos: la sonda que decide el tráfico y el límite que decide la vida

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 15 de 27 · Parte II — El despliegue · **densa** ⭐
> **Perfil:** `minimo` para el recorrido, `medicion` para 📏 · **Motor de referencia:** Docker; 🦭 donde diverge
> **Servicios que toca:** los cuatro backends · **Oleada o paso de generación:** G4
> **Depende de:** Fase 14 · **Habilita:** Fase 16
> **Incidentes que reserva:** 12, 13, 14, 15
> **Apéndices de apoyo:** a01, a04
> **Fecha de verificación ejecutada:** {{DD/MM/AAAA}} · macOS arm64
> **Objetivo:** …
```

El título es descriptivo y con carácter: `Fase NN — Tema: la promesa concreta del documento`.

### 8.2 Marcadores de estado

- ⭐ **Fase pieza central** del curso (solo en el encabezado y en el temario).
- 🌊 **Oleada de dominio** (G0, G1, G5).
- 💸 **Deuda intencional**, con la fase donde se cobra.
- 🔥 **Opcional o ampliación.**
- 🦭 **Divergencia Docker / Podman.**
- 🚧 **Hasta aquí llega el laboratorio**: lo que existe del otro lado y no se puede reproducir gratis.
- 🌩️ **La frontera con la nube**: qué es esto en un cluster gestionado.
- 🟢🟡🟠🔴 **Dificultad de ejercicios e incidentes.**

### 8.3 Callouts en blockquote

- 📏 **Medición.** El callout que sostiene cada "mejor que" (§6).
- 🪞 **Apuesta / instinto que falla.**
- 🧨 **Rotura provocada.**
- 🩺 **Incidente**: síntoma y enlace al cuaderno; o el comando que confirma una hipótesis.
- ⚰️ **Autopsia.** Con la estructura de §2.1.
- ⚖️ **Veredicto honesto.** Cuándo NO usar esto.
- 🩻 **Esto sí funciona igual.**
- 📖 **Traducción** compose ⇄ Kubernetes, local ⇄ nube, o entre runtimes.
- 🧠 **Modelo mental.** 🧭 **Principio.**
- ⚠️ **Advertencia.** 📝 **Nota de contexto.** 💡 **Truco.** 📚 **Referencia inline.**

### 8.4 Secciones narrativas recurrentes

- **Dónde estamos.** Qué dejó la fase anterior, en qué estado está el sistema, y qué falta.
- **Detalles con intención.** Las decisiones deliberadas de un manifiesto o un Dockerfile.
- **El patrón a memorizar.** Una o dos frases con la lección transferible.
- **Prueba de fuego.** Una verificación concreta dentro del flujo, casi siempre la suite de
  conformidad o un `kubectl` con su salida esperada.
- **La señal de que quedó bien.** En el cierre, un criterio en forma de cita.

---

## 9. 🧱 Las plantillas y la longitud

Los esqueletos completos están en [`plantillas-de-capitulo.md`](plantillas-de-capitulo.md): **fase
de plataforma** (F03–F26), **fase de la Parte 0** (F00–F02), **fase de cierre** (F27) y
**apéndice**. Las de fase son rígidas y se siguen literales; la de apéndice es laxa.

**Longitud del cuerpo**, medida cortando el documento por el encabezado de 🧪 Ejercicios y escalada
por peso:

| Peso | Palabras de cuerpo | Ejercicios |
|---|---|---|
| ligera | 2.500–3.500 | 12 |
| media | 3.500–4.500 | 20 |
| densa | 4.500–6.000 | 24 |
| cierre (F27) | 3.500–4.500 + el enunciado del proyecto | 12 |

El aparato de ejercicios agrega entre 1.300 y 2.800 palabras encima, y eso está bien.

Después de la última sección, fuera de lo que lee el estudiante, cada fase puede cerrar con **📌
Pendientes sugeridos**, con destino explícito.

---

## 10. 🧪 Ejercicios

- **Cantidad fija por peso** (§9), con el número de la propuesta de fases §11.

  > ⚠️ **La cantidad no arregla un aparato flojo.** Si al escribir el ejercicio 22 sale una variante
  > del 9, el número correcto era 21, y se dice en 📌.

- **La escala:**

  | | Nivel | Qué pide |
  |---|---|---|
  | 🟢 | Fácil | Reproducir lo que la fase acaba de mostrar, con otro servicio |
  | 🟡 | Intermedio | Aplicar el patrón a un servicio donde no es mecánico |
  | 🟠 | Difícil | Combinar, diagnosticar, decidir entre alternativas |
  | 🔴 | Muy difícil | Abierto o adversarial: se entrega el laboratorio roto y hay que razonarlo |
  | 🔥 | Extra | Fuera del alcance base; no cuenta |

- **Distribución ≈ 30 % 🟢, 30 % 🟡, 25 % 🟠, 15 % 🔴**, con desviación deliberada según la fase.
- **Al menos un tercio son de diagnóstico o de medición**: se entrega un manifiesto con un campo
  mal puesto, una imagen que pesa el triple, una sonda que corta tráfico, y se pide reproducir,
  medir y explicar.
- **Al menos uno por fase usa un servicio distinto de `pricing`**, porque el piloto es el caso fácil.
- **Predecir antes de ejecutar** en 🟠 y 🔴.
- **Cada ejercicio cierra con su criterio de éxito verificable**: `**Criterio:**` seguido de un
  comando y su resultado esperado. Nunca "despliega `catalog`" a secas; siempre *"…y
  `kubectl get endpointslices -n apps -l kubernetes.io/service-name=catalog` muestra dos
  direcciones listas"*.
- **Agrupados por dificultad, con encabezado de rango y el conteo en el título.**
- **Referencia de solución:** los 🟢 y 🟡 llevan la solución plegada en un `<details>` (única
  excepción permitida al "nada de HTML"); los 🟠 y 🔴, una rúbrica de lo que tiene que aparecer.

---

## 11. 📚 Bibliografía y referencias

**Orden de prioridad:** documentación oficial de la versión que usamos (Kubernetes, kind, Helm,
Gateway API, cert-manager, Prometheus, Grafana, Loki, Tempo, OpenTelemetry, Docker, Podman), después
especificaciones (OCI, Gateway API, OpenAPI, TLS en sus RFC), después libros, después charlas,
blogs y vídeos. **Siempre se advierte cuando un enlace apunta a otra versión.**

**Libros base del curso** (edición y año comprobados el 03/10/2026, en la tanda P11, y citados por
esa edición):

- Brendan Burns, Joe Beda, Kelsey Hightower y Lachlan Evenson, *Kubernetes: Up and Running*, 3.ª
  edición, O'Reilly, 2022.
- Marko Lukša y Kevin Conner, *Kubernetes in Action*, 2.ª edición, Manning, 2026.
- Betsy Beyer, Chris Jones, Jennifer Petoff y Niall Richard Murphy (eds.), *Site Reliability
  Engineering*, O'Reilly, 2016, de lectura libre en https://sre.google/sre-book/table-of-contents/.
- Sam Newman, *Building Microservices*, 2.ª edición, O'Reilly, 2021.
- Chris Richardson, *Microservices Patterns*, Manning, 2018. La 2.ª edición está en acceso
  anticipado (MEAP) y se nombra como "en preparación", sin citar sus capítulos.
- Charity Majors, Liz Fong-Jones, George Miranda y Austin Parker, *Observability Engineering*, 2.ª
  edición, O'Reilly, 2026.

Formato: URL completa, título y una nota de qué versión cubre y por qué vale. Cada fase cierra sus
referencias con un **orden de lectura sugerido**, y puede sumar charlas y tutoriales en vídeo
cuando son la mejor explicación disponible, con su duración.

> ⚠️ En todas las secciones de referencias va la advertencia de que las URL y los contenidos
> cambian.

---

## 12. 🐳🦭 Convención Docker / Podman y plataformas

- **Docker es el camino principal**, Podman aparece con 🦭 donde diverge (§4.5).
- **El motor activo se declara** en cada bloque que dependa de él, y `task engine:status` es la
  primera línea de cualquier diagnóstico del ambiente.
- **Solo macOS arm64 está verificado por el autor.** Toda instrucción propia de Windows 11 o de Linux
  lleva la marca *"no verificado por el autor; se confirma al hacer el curso"*, y cuando alguien la
  verifica, la marca se cambia por la fecha y la plataforma.
- **Las tres plataformas en el mismo orden siempre**: Windows 11 con WSL 2, macOS Apple Silicon,
  Linux amd64. Cuando las instrucciones difieren, van las tres, sin nota al pie.
- **La emulación se declara**: si algo corre bajo emulación en Apple Silicon, lo dice el encabezado,
  porque cambia los tiempos y a veces el arranque.
- **Ningún runtime en el host.** Si una instrucción pide instalar Java, Node, PHP o Go en la máquina
  del lector, está mal.

---

## 13. 🤝 Honestidad: las reglas que no se negocian

1. **Nada se publica sin haberse ejecutado.**
2. **Lo que no se verificó se declara con esas palabras**, donde el lector lo necesita.
3. **Cada opción gana en algún sitio y pierde en otro**, y las pérdidas van con número. Esto
   incluye a Kubernetes contra compose, y a la opción que el curso elige.
4. **La apuesta perdida se publica igual que la ganada.**
5. **Lo que el laboratorio no puede reproducir se declara** 🚧, y no se simula para que parezca.
6. **La divergencia con producción se dice en voz alta** donde ocurre: un Postgres compartido, un
   cluster de un nodo, una CA propia.

---

## 14. 🔗 Coherencia entre documentos

- **Los nombres del contrato no se renombran** entre fases.
- **Los apéndices no repiten lo que explica una fase, y viceversa: se enlazan.**
- **Una fase no cita el temario, el contrato ni el plan de producción**: cita otra fase, un
  apéndice o el cuaderno. Los documentos de `prompts/` son de autoría, no del lector.
- **Las fechas, cifras y nombres de la historia no se inventan de nuevo.** Si una fase necesita un
  dato que la historia no tiene, se agrega primero a `00-historia-de-la-vecina.md`.
- **El curso no nombra ningún otro curso del repositorio**, ni como prerrequisito ni como
  profundización.
- **Los README y `0-ESTRUCTURA-CURSO.md` no se tocan al escribir una fase o un apéndice.** Se
  escriben en una tanda final y aparte, cuando todo el contenido existe. Una fase que querría
  agregar algo a un README lo deja anotado en 📌.
- 🗑️ **Los documentos desechables no se citan nunca.** Los archivos `_desechable-*` son andamio y van
  a desaparecer.
- **Git:** contrato del cluster §8.

---

## 15. 📓 Los tres documentos vivos

Crecen durante todo el curso y son producto, no apuntes.

- **`BENCHMARKS.md`**: toda medición, con el formato de §6.1.
- **`INSTINTOS.md`**: los 🪞 acumulados, con la prueba que los demuestra y la fase donde
  aparecieron.
- **`cuaderno-incidentes.md`**: los 27 incidentes, con el formato de su documento.

> 🧭 **Cuando estés ejecutando, anota el error antes de arreglarlo.** Reconstruir un evento de
> memoria produce mensajes que no existen, y el cuaderno vive de mensajes literales.

---

## 16. ✅ Checklist antes de dar por cerrado un `.md`

```text
[ ] El bloque de encabezado está completo, con peso, perfil, incidentes y fecha de verificación
[ ] Todo comando, salida y número del documento salió de una ejecución real
[ ] Lo no verificado está declarado con esas palabras, incluidas las instrucciones de Windows y Linux
[ ] Toda medición trae los seis datos de §6 y está en BENCHMARKS.md
[ ] La apuesta se escribió antes de la medición y no se editó después
[ ] La rotura trae el cambio exacto y el síntoma literal
[ ] Los incidentes reservados están escritos completos en el cuaderno, sin la solución en la fase
[ ] El 🪞 de la fase está en INSTINTOS.md
[ ] Hay un ⚖️ veredicto honesto con la pérdida cuantificada, y la pregunta del curso respondida
[ ] Ninguna autopsia juzga a una persona ni a una herramienta
[ ] El piloto va primero; los otros runtimes aparecen solo donde no es mecánico
[ ] 🦭 donde Podman diverge; 🚧 y 🌩️ donde el laboratorio deja de parecerse a la nube
[ ] Ningún nombre técnico fuera del contrato del cluster
[ ] Ninguna capacidad en el código antes de la fase que la enseña; la suite del paso pasa
[ ] Ejercicios en la cantidad de la propuesta §11, agrupados, un tercio de diagnóstico, con Criterio
[ ] Cuerpo en la banda de §9 para su peso
[ ] Todo pendiente abierto tiene destino explícito
[ ] Tuteo en todo el documento; cero voseo, cero "usted"
[ ] Código en inglés, comentarios en español con tildes; bloques con lenguaje declarado
[ ] Ninguna versión escrita fuera de a01; imágenes por digest
[ ] Ningún otro curso del repositorio nombrado; ningún _desechable-* citado
[ ] Si cambió el temario o el estado, 0-ESTRUCTURA-CURSO.md y el README lo dicen
[ ] Todo diagrama en mermaid, dibujado con mmdc; fichas, árboles y salidas en text (§19.1)
[ ] python3 prompts/verificar-corpus.py sale en 0 errores y 0 avisos (§19.3)
```

---

## 17. ⚖️ Excepciones declaradas al `CLAUDE.md` del repositorio

El `CLAUDE.md` permite apartarse de los defaults si se nombra la regla y se dice por qué. Si no
estuvieran escritas aquí, cada sesión futura las "arreglaría" de vuelta.

1. **Sin reparto horario.** Cada fase declara su peso. Un curso donde media hora se va esperando un
   cluster o un build de Java no puede estimar horas con honestidad, y una cifra inventada es peor
   que ninguna.
2. **Ejercicios: 20 a 24 por fase media y densa, y 12 en la fase ligera (F05) y en la de cierre
   (F27).** La ligera es corta por diseño y la de cierre es de criterio, con el proyecto final como
   aparato principal.
3. **Los comentarios de código van en español con tildes**, no en inglés: en este curso el
   comentario es la parte pedagógica del manifiesto.
4. **Un solo proyecto de código en `src/lab/`**, y no una carpeta por fase: el curso construye un
   único artefacto, y la historia fase a fase vive en los tags de git.
5. **`0-ESTRUCTURA-CURSO.md` se escribe al final, no antes de la primera fase.** El papel de
   documento de alcance y estructura lo cumplen el [alcance](alcance-del-proyecto.md) y la
   [propuesta de fases](propuesta-fases-y-alcance.md), escritos antes. `0-ESTRUCTURA-CURSO.md` se
   reserva para el temario publicado, con el estado real, junto con los README.
6. **Las mediciones incluyen tiempos**, a diferencia de los cursos que miden la forma: aquí el
   tiempo de build y de arranque **es** el costo de plataforma. Se compensa con la regla de la
   proporción (§6) y la declaración de la máquina.
7. **El curso no enlaza a otros cursos del repositorio**, aunque traten temas vecinos: es
   autocontenido por decisión.
8. **Emoji en `###` donde son marcadores, no adorno**: el 🩺 de cada incidente del cuaderno, los
   marcadores de §8.2 (🦭, 🌊, 🚧, 🌩️, 💸) y el 🏚️ del patrimonio. La historia de la empresa, que es
   narrativa y no una fase, lleva un emoji por capítulo de su cronología y no tiene fecha de
   verificación. El verificador lo sabe (§19.3).
9. **Diagramas en Mermaid** (D44, §19.1), pedido explícito del autor en la revisión del 05/10/2026;
   el `CLAUDE.md` no fija formato.

Todo lo demás del `CLAUDE.md` aplica tal cual, incluidos `BENCHMARKS.md` e `INSTINTOS.md`.

---

## 18. 📌 Pendientes que afectan a esta guía

- ✅ **Versiones y digests** verificados en P11 (03/10/2026). Viven en `a01`, y esta guía solo apunta
  allí.
- ✅ **Ediciones de los libros base** comprobadas (§11).
- ✅ **La empresa** está cerrada: Droguerías La Vecina (D18).
- ✅ **El curso está cerrado** (05/10/2026), con las 44 decisiones en ✅. La pasada de verificación al
  tomar el curso está en [`pendientes-a-futuro.md`](pendientes-a-futuro.md), no aquí.

---

## 19. 🧾 Alineación con los lineamientos de producción del repositorio

> 📝 **Sección agregada el 05/10/2026**, en la revisión del curso cerrado contra los lineamientos de
> producción del repositorio. Va al final para no renumerar: el resto de `prompts/` cita esta guía por
> número de sección. El curso es anterior a esos lineamientos; casi todo lo que aquí se declara ya era
> su práctica, y desde ahora está escrito como decisión.

### 19.1 D44 · Diagramas en Mermaid

Todo diagrama —arquitectura, flujo, ciclo, árbol de decisión— va en un bloque `mermaid`. Se quedan en
`text`, porque no son diagramas y alineados en monoespaciado se leen mejor:

- las **fichas de cierre de fase** (`EL SISTEMA AL CERRAR LA FASE NN`), aunque lleven alguna flecha:
  son un inventario, y las veintiocho tienen la misma forma;
- los **árboles de archivos**, las **salidas de terminal** y las **capturas de pantalla** (k9s en `a04`);
- las correspondencias `a → b` y las tablas alineadas a mano.

La revisión convirtió **siete diagramas en seis documentos** (`00-el-ambiente`, F06, F10, F27 ×2,
`a03`, `a16`), y cada uno se dibujó con `mmdc` antes de publicarlo. Criterios para los que vengan:

- **`flowchart TD`** para jerarquías y árboles de decisión; **`LR`** para un camino de punta a punta
  (la petición de F10, el método de `a03`, el patrimonio de `a16`).
- **`subgraph`** para los namespaces (F27) y para un controlador con sus pasos (F06). Un `subgraph`
  sin flechas queda donde Mermaid quiera: se ancla con un enlace invisible (`A ~~~ B`).
- **Formas con sentido:** cilindro `[(…)]` para una base, `[[…]]` para el bus, `{…}` para una
  pregunta, `[/…/]` para un volumen de archivos.
- **Caracteres que Mermaid interpreta:** `<…>` se escribe `#lt;…#gt;` y las comillas dentro de una
  etiqueta van como «…».

### 19.2 Documentos de `prompts/` y lo que hace su papel

El curso es anterior a las plantillas de producción y está cerrado, así que no se crean a posteriori.
Esto es lo que cumple cada función:

- **Alcance:** [`alcance-del-proyecto.md`](alcance-del-proyecto.md).
- **Propuesta y registro de decisiones:** [`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md)
  (§12, D1–D44) y [`propuesta-apendices-y-alcance.md`](propuesta-apendices-y-alcance.md).
- **Plan de producción:** no queda. Fue un desechable y se borró al cerrar (T16); el estado vive en
  `0-ESTRUCTURA-CURSO.md`, el registro de decisiones y los
  [hallazgos](verificacion-de-laboratorio/hallazgos.md).
- **Contrato de nombres:** [`contrato-del-cluster.md`](contrato-del-cluster.md).
- **Diccionario de términos:** §3 de esta guía, y para el lector, `a05` (diccionarios).
- **Historia de la empresa:** `00-historia-de-la-vecina.md`, publicada como parte del curso.
- **Plantillas de capítulo, prompts y formato del cuaderno:** [`plantillas-de-capitulo.md`](plantillas-de-capitulo.md),
  [`prompts-de-fase.md`](prompts-de-fase.md), [`prompts-de-apendice.md`](prompts-de-apendice.md) y
  [`formato-cuaderno-incidentes.md`](formato-cuaderno-incidentes.md).
- **Verificación previa (E6):** [`verificacion-de-laboratorio/`](verificacion-de-laboratorio/hallazgos.md),
  con los hallazgos H1–H270, sus `logs/` y el `borrador/`.

El mapa completo, para quien abre `prompts/` por primera vez, está en [`README.md`](README.md).

### 19.3 Verificación

Desde la raíz del curso, sin tocar Docker ni el cluster:

```bash
python3 prompts/verificar-corpus.py                 # validaciones base + aviso DIAGRAMA
python3 prompts/verificar-corpus.py --publicacion   # además, lo que exige el repositorio público
```

- `verificar-corpus.py` es la subclase del perfil `courses-ia` de `verificador_base.py`, copiado de los
  lineamientos. Agrega los callouts y marcadores de §8 y los emoji en `###` de §17 (excepción 8), saca
  la historia de la regla de capítulo y avisa con `DIAGRAMA` de un bloque `text` con esquinas de caja o
  flechas verticales que no sea una ficha de cierre ni una captura.
- Lo que el verificador no ve y se revisa a mano: que la suite del paso pase (`task conformance`), que
  las cifras citadas coincidan con `BENCHMARKS.md` y que un diagrama dibujado solo con `├─` y `│` no se
  haya quedado en `text`.
- Al cerrar el curso, el 05/10/2026, los dos modos salen en **0 errores y 0 avisos**.

### 19.4 Lo que queda abierto

Nada de redacción. Lo que falta es la pasada del autor como lector: tomar el curso desde cero, en
macOS, Windows 11 y Linux, montar todos los contenedores y rehacer todas las pruebas. Sus reglas y
lo que pide atención en cada tramo están en [`pendientes-a-futuro.md`](pendientes-a-futuro.md).
