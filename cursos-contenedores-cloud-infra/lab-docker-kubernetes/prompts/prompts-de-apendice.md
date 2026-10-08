# 📎 Prompts iniciales por apéndice
## Laboratorio de contenedores y Kubernetes local — 16 sesiones, 16 entregables

Cada sección es el prompt de un apéndice. Como en los de fase, **el alcance no se copia aquí**: vive
en [`propuesta-apendices-y-alcance.md`](propuesta-apendices-y-alcance.md), y el prompt agrega lo que
esa ficha no dice.

**Una sesión, un archivo.** Los apéndices que crecen (`a03`, `a04`, `a05`) se abren con este prompt
y después reciben sus entradas desde las sesiones de fase, sin sesión propia.

> ⚠️ **El orden importa.** `a01` y `a02` se escriben **antes de F00**, y los dos dependen de la
> verificación de laboratorio (P11). `a03` va **antes de F02**, con los prompts G0. `a04` y `a05` se
> abren con su esqueleto y crecen. `a16`, el patrimonio, va en su tanda propia (T1b), después de `a01` y `a02` y antes de `a03`: los
> prompts G0 lo reciben como insumo. Los 🔥 (`a06`–`a15`) van al final y ninguna fase los espera.

---

## 🧱 El marco común a todos los apéndices

```markdown
## Marco (no lo repitas, aplícalo)

Fuentes de verdad, en orden: `prompts/alcance-del-proyecto.md`,
`prompts/guia-de-estilo-y-convenciones.md`, `prompts/contrato-del-cluster.md`,
`prompts/propuesta-apendices-y-alcance.md` con la ficha de este apéndice,
`prompts/plantillas-de-capitulo.md` (plantilla de apéndice, la laxa), `00-historia-de-la-vecina.md`,
y las fases y apéndices ya escritos. Los `_desechable-*` no cuentan y no se citan.

Reglas de apéndice:
- **Esto no se lee de corrido.** Índice de salto rápido, secciones cortas que responden a UNA
  pregunta, ejemplo mínimo ejecutable, tabla de "cuándo usar qué" al final.
- **Un apéndice no repite lo que explica una fase: enlaza.**
- **Nada sin ejecutar.** Ningún comando, ninguna versión, ninguna salida inventada. Solo se
  verifica en macOS arm64; lo de Windows 11 y Linux se marca como no verificado por el autor.
- **Ninguna versión fuera de `a01`**, salvo en `a01`, que es donde viven.
- **Los nombres técnicos son los del contrato del cluster.**
- **Los 🔥 declaran la memoria que suman al perfil `lab`**, medida, y qué apagar para que entren.
- **Declara qué queda fuera** en el encabezado; si es una exclusión del curso, sin decir dónde
  estaría.
- **El curso no nombra ningún otro curso del repositorio.**
- Cierre con el bloque 🏷️ en su variante negativa, salvo `a01`, `a03` y `a16`, que dejan archivos en el
  repositorio y llevan tag propio.
- **No toques ningún `README.md`**, tampoco los de `src/`, ni crees `0-ESTRUCTURA-CURSO.md`.
- Ejercicios: los de la ficha, cortos y de consulta, cada uno con **Criterio:**.
```

Y el **protocolo de tres pasos**: (1) preguntas bloqueantes numeradas y lectura de la ficha, sin
redactar; (2) ejecución y redacción cuando yo responda, parando a preguntar si aparece una duda
nueva; (3) autoverificación contra la guía §16, en lista corta.

---

## # a01 — El laboratorio

```markdown
Esta es la sesión del **Apéndice a01 — 🧰 El laboratorio**. Entregable: `a01-el-laboratorio.md`
**más `src/lab/Taskfile.yml`, `src/lab/kind/` y `src/lab/scripts/seed/`**. **8 ejercicios.**

{{marco común}}

## Alcance
La ficha a01, completa.

## Qué vigilar
- **Sale de P11.** Las versiones, los digests y la orden de magnitud de la memoria están en
  `prompts/verificacion-de-laboratorio/hallazgos.md` (H4, H11, H18); el borrador del Taskfile, los
  archivos de kind y el seed, en `prompts/verificacion-de-laboratorio/borrador/`. Las versiones se
  vuelven a comprobar el día que se escribe `a01`: si alguna cambió, gana la nueva y se anota.
- **B-00 en tres entregas** (ficha a01): aquí solo la infraestructura, con tres corridas por celda;
  el perfil `legacy` llega en T1b y los servicios en T2. La tabla lo dice en su encabezado.
- **Este es el único sitio del curso donde vive una versión.** Todo lo demás apunta aquí.
- **La tabla de memoria (B-00) es la promesa del curso**: perfil por perfil, motor por motor, en
  macOS arm64, con la memoria asignada a la máquina virtual de cada motor, y la columna de Windows y
  Linux vacía y marcada. Si `minimo` no entra en 8 GB, se dice con esas palabras y se propone qué
  achicar.
- **La política de versiones es D17**: todo en su última LTS, y donde no haya línea LTS, en su
  última estable, a la fecha de P11.
- **Cada tarea del Taskfile con el comando que corre debajo**: el lector tiene que poder prescindir
  del Taskfile si quiere.
- **La sección de scripts es corta (D31)**: dónde viven, cómo se crea el `.venv`, la ruta del
  intérprete que cambia en Windows, y el ejemplo del seed con Faker. Si se te alarga, es porque estás
  enseñando Python o `venv`: corta. Verifica en el paso 1 que la tarea corra en macOS arm64 y deja
  Windows y Linux marcados como no verificados.
- Lleva tag propio: `apendice-a01-laboratorio`.

{{protocolo}} Si te descubres explicando qué es kind o qué hace Helm, corta y enlaza a su fase.
```

---

## # a02 — Solución de problemas del ambiente

```markdown
Esta es la sesión del **Apéndice a02 — 🩺 Solución de problemas del ambiente**. Entregable:
`a02-problemas-del-ambiente.md`. **8 ejercicios.**

{{marco común}}

## Alcance
La ficha a02, completa.

## Qué vigilar
- **Windows y Linux no se ejecutan en esta sesión.** Sus entradas se escriben desde la
  documentación oficial y desde la guía de Windows del material preliminar —que es la lista de
  síntomas, no la fuente—, y cada una lleva la marca de no verificado por el autor. Lo de macOS sí
  se reproduce.
- **No duplica los cuatro incidentes de ambiente**: los enlaza por ID.
- **Cada entrada empieza por el síntoma literal**, como el cuaderno, para que se encuentre buscando
  el mensaje.
- **El script de alternancia de motores** se documenta en lo que tiene de diagnóstico (qué
  variables toca y por qué), no línea por línea.

{{protocolo}}
```

---

## # a03 — Los contratos y los prompts de generación

```markdown
Esta es la sesión del **Apéndice a03 — 📜 Los contratos y los prompts de generación**. Entregable:
`a03-contratos-y-prompts-de-generacion.md` **más `src/lab/contracts/`** (los cuatro OpenAPI y la
suite G0), `src/lab/contracts/docs/` con Swagger UI, y los `CLAUDE.md` de los cinco servicios.
**8 ejercicios.**

{{marco común}}

## Alcance
La ficha a03, completa, con la matriz del contrato del cluster §6.

## Qué vigilar
- **En esta sesión se escriben solo los prompts G0** y el marco de la matriz. Cada paso posterior
  agrega sus prompts desde la sesión de su fase, en la misma tanda.
- **Los OpenAPI llevan desde hoy todos los endpoints del curso**, con los pendientes marcados, porque
  la F02 congela el contrato.
- **Cada prompt se prueba**: se genera el servicio con él, se corre la suite, y si no pasa, se
  corrige el prompt, no el código a mano. El apéndice publica el prompt que funcionó.
- **Ningún prompt pide una capacidad antes de su paso.** Cada prompt dice explícitamente lo que
  el servicio **no** debe tener todavía.
- **Los prompts no dependen de una herramienta concreta**: Claude Code es la referencia, y el
  apéndice dice qué cambia con otra.
- **Los `CLAUDE.md` de cada servicio, cortos**: stack, comandos, convenciones y el contrato con los
  pasos futuros marcados.
- Lleva tag propio: `apendice-a03-contratos`.

{{protocolo}}
```

---

## # a16 — El patrimonio

```markdown
Esta es la sesión del **Apéndice a16 — 🏚️ El patrimonio**. Entregable: `a16-el-patrimonio.md`
**más `src/lab/legacy/`** (Contingencia, el portal y la Braqui) y la tarea `legacy:up`.
**6 ejercicios.** Va en la tanda T1b: después de `a01` y `a02`, antes de `a03` y de F00.

{{marco común}}

## Alcance
La ficha a16, completa, con la historia §1.7, §1.8, §1.9, §1.11, §3 y §5.3 como fuente de cada pieza.

## Qué vigilar
- **Las tres piezas se generan con prompts, y los prompts se publican en el apéndice.** Son
  mínimas: Contingencia con dos servicios SOAP, sus tablas y el procedimiento del préstamo en
  PL/pgSQL; el portal creado con `artisan`, con su catálogo y el job nocturno; la Braqui con su
  sondeo de treinta segundos y el script de traslados por archivo (D30): el `.txt` y su `.ok` en un
  volumen compartido, el `cron` de cinco minutos, el archivo de bloqueo y la tabla de procesados.
  SharePoint y Microsoft Graph no entran: el volumen hace de carpeta compartida.
- **Las mañas son a propósito y salen de la historia**: el portal con credenciales en el `.env` y
  sin pruebas, la Braqui leyendo tablas ajenas, el script que escribe después del commit y deduplica
  por nombre de archivo, Contingencia que se enciende cuando el Siga no contesta. No se arreglan aquí: las arregla el curso, fase por fase, y cada una tiene su destino.
- **GlassFish ya está verificado** (P11, H18): 8.0.4 nativa en arm64, con JDK 21 y con Metro y JAXB
  incluidos. En el paso 1, solo confirma que el digest de `a01` sigue siendo el vigente.
- **La memoria del perfil `legacy` se mide** y se agrega a la tabla de `a01`: el patrimonio tiene
  que caber en el presupuesto de la Parte 0.
- **La nota de licencias va en una línea y desde la historia**: Contingencia ya era GlassFish y
  Postgres en 2016. Sin tono de disculpa.
- **La sección de dialectos es 🔥 y corta**: el PL/SQL del préstamo como texto, frente a su versión
  en PL/pgSQL; contexto para la F24.
- Lleva tag propio: `apendice-a16-patrimonio`.

{{protocolo}}
```

---

## # a04 — `kubectl` y k9s

```markdown
Esta es la sesión del **Apéndice a04 — ⌨️ `kubectl` y k9s**. Entregable: `a04-kubectl-y-k9s.md`,
**como esqueleto** que crece. **10 ejercicios**, que se escriben cuando el apéndice se cierra (T14).

{{marco común}}

## Alcance
La ficha a04. En esta sesión, solo el esqueleto: el índice por pregunta, la estructura de cada
entrada y las de la F07 (contextos y namespaces).

## Qué vigilar
- **Organizado por pregunta, no por verbo**: "qué le pasa a este pod" antes que "`describe`".
- **Cada entrada con su atajo de k9s al lado**, desde que k9s aparece.
- **Sin enlaces a fases que todavía no existen.**

{{protocolo}}
```

---

## # a05 — Los diccionarios

```markdown
Esta es la sesión del **Apéndice a05 — 📖 Los diccionarios**. Entregable: `a05-diccionarios.md`,
**como esqueleto** que crece. **6 ejercicios**, al cierre (T14).

{{marco común}}

## Alcance
La ficha a05. En esta sesión, las tres tablas vacías con su encabezado y su regla (las dos
direcciones, y qué no tiene traducción), y las filas de la F06.

## Qué vigilar
- **Las dos direcciones, siempre.** Una tabla que solo traduce hacia Kubernetes está a medias.
- **La tabla `Ingress` ⇄ Gateway API es para leer clusters ajenos**, no para desplegar: lo dice su
  encabezado.
- **La columna de la nube 🌩️ no nombra precios** ni promete comportamiento de un proveedor que no se
  verificó; dice qué pieza es y qué la diferencia del laboratorio.

{{protocolo}}
```

---

## # Los apéndices 🔥 — a06 a a15

Comparten un prompt, con la ficha y los vigilables de cada uno.

```markdown
Esta es la sesión del **Apéndice {{aNN}} — {{emoji}} {{nombre}}**, ampliación 🔥 del curso.
Entregable: `{{archivo de la propuesta de apéndices §2}}`. **{{N}} ejercicios.**

{{marco común}}

## Alcance
La ficha {{aNN}}, completa.

## Qué vigilar
- **Es opcional y ninguna fase depende de él.** Empieza diciendo qué fase lo señala y qué necesita
  tener corriendo el lector.
- **La memoria que suma al perfil `lab`, medida**, en el encabezado, y qué apagar para que entre.
- **La versión de lo que instala** se agrega a `a01` en la misma sesión, con su fecha.
- {{los vigilables propios, de la lista de abajo}}

{{protocolo}}
```

**Vigilables propios:**

- **a06 · Multiplataforma:** la emulación se mide, no se describe: el mismo arranque nativo y
  emulado.
- **a07 · Imágenes sin Docker:** la comparación usa el arnés de B-04 y cita esa entrada; no crea
  una medición nueva en `BENCHMARKS.md` salvo que el resultado lo merezca.
- **a08 · La JVM nativa:** tres variantes de `inventory` medidas con el mismo arnés, y el veredicto
  de lo que se pierde con la nativa dicho con la misma fuerza que lo que se gana. Nada de migrar
  entre versiones de Java.
- **a09 · Frontend con runtime:** el contrapunto exacto de la F11, con el mismo experimento de dos
  despliegues.
- **a10 · Service mesh:** Istio en modo ambient (D15), con su memoria medida delante; compara
  contra el mTLS a mano de la F19 y los reintentos de la F22, y nombra Linkerd y Cilium con sus
  ventajas y desventajas, sin instalarlos.
- **a11 · GitOps:** de lectura. Se puede instalar y mirar; el flujo no se construye.
- **a12 · Operators:** los ejemplos son lo que el curso ya instaló.
- **a13 · Respaldo:** el `CronJob` de respaldo y la restauración probada de punta a punta.
- **a14 · Las GUI:** sin guerra de herramientas; cada GUI con lo que muestra y lo que esconde.
- **a15 · `StatefulSet` de varios miembros:** decide el motor en el paso 1 por memoria; el failover
  se provoca.
