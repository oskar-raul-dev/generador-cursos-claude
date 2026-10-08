# 🗓️ Plan de producción: tandas, estado y checklist

Este documento dice **en qué orden se prepara y se escribe el corpus, cuándo una tanda está terminada
y dónde va la producción**. Hay dos fases: la **preparación** (tandas `P1`–`P8`), que solo toca
`prompts/` y no escribe ni un capítulo, y la **escritura** (tandas `T0`–`T25`), que no empieza hasta
que la preparación esté cerrada. Es operativo: se actualiza al cerrar cada sesión, y **cualquier
sesión que retome `03-poo-y-patrones/` empieza leyendo §3 (estado), §8 (bitácora) y §9 (checklist)**.

- La forma la manda [`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md).
- El contenido lo manda [`prompt-base.md`](prompt-base.md).
- La entrada de cada tanda es su prompt en [`prompts-de-fase.md`](prompts-de-fase.md).
- **El orden lo manda este documento.**

> **Caducidad:** es un documento de producción. El plan preveía borrarlo al cerrar T25; Oskar decidió conservarlo
> como registro. No se cita desde ningún capítulo ni README.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--las-reglas-de-orden) · [2](#2--qué-es-una-tanda) · [3](#3--estado) · [4](#4--las-verificaciones) · [5](#5--las-tandas-una-por-una) · [6](#6--deuda-de-enlaces-abierta) · [7](#7--deuda-de-ejecución) · [8](#8--bitácora) · [9](#9--checklist)

---

## 1. 🧭 Las reglas de orden

Las tandas van por **dependencia conceptual**, y cada una deja el corpus coherente y publicable.

1. **Ninguna tanda se cierra con el solucionario desactualizado.** Las preguntas de la tanda entran en
   el `NN-respuestas.md` de su bloque en la misma tanda, con el enunciado literal.
2. **Ningún enlace interno apunta a un documento que no existe.** La referencia va en prosa y se anota
   en la deuda de enlaces (§6); la tanda que escribe el destino la convierte en enlace.
3. **Ninguna salida se publica como real sin corrida.** Las esperadas se marcan y se anotan en la deuda
   de ejecución (§7), que vacían T23 y T24.
4. **Los README se escriben al final** (T25). Hasta entonces, el mapa es la tabla de §3.
5. **Nada se nombra sin comprobarlo en la misma sesión**: URL por código de estado, libro con edición y
   capítulo, JEP con su estado, característica de C++ con su estándar (§10.1 de la guía).
6. **La escritura no empieza con la preparación abierta.** `T0` exige `P1`–`P8` cerradas.
7. **Un bloque se cierra con su simulación.** La tanda que escribe el último capítulo de un bloque
   escribe también su simulación y deja el solucionario completo.
8. **Todo en el hilo principal, secuencial y sin agentes**, y sin commits: git lo hace Oskar.
9. **Nada se instala en la máquina, y Docker solo con permiso de Oskar** en T23 y T24.
10. **Los talleres se decidieron después de T25** (2026-10-04): versión intermedia, seis talleres en Java, en una
    tanda final, T26, que incluye su propia preparación (§13.2 de la guía, §18 del `prompt-base.md`).

**Prioridad si una entrevista aprieta:** las tandas que escriben capítulos de la ruta "entrevista esta
semana" van primero —T1, T2, T3, T5, T7, T8, T10, T11, T13, T20, T22—, saltando dentro de cada una
los capítulos que no son de la ruta. Lo que falte de las tandas saltadas va en prosa y a la deuda de
enlaces. Como esos capítulos se escriben autocontenidos (§12 de la guía), el salto no los rompe.

---

## 2. 📦 Qué es una tanda

### 2.1 Una tanda de preparación

Un documento de `prompts/`, o un paso que lo deja coherente con los demás. **No crea ni toca nada
fuera de `prompts/`.** Terminada cuando sus enlaces y anclas pasan el verificador y los documentos
que la citan están al día.

### 2.2 Una tanda de escritura

Un grupo de capítulos que se enlazan entre sí, **su parte del solucionario**, la simulación si cierra
el bloque, y las verificaciones corridas. La rutina, igual en todas:

1. Pegar el prompt de la tanda y seguir su protocolo de tres pasos.
2. Tener delante §14 de la guía: el checklist se recorre **al cerrar cada archivo**.
3. Releer la ficha de cada capítulo: "Cubre" es el piso, "Desmonta" es obligatorio.
4. Comprobar URLs, libros, JEPs y características del lenguaje **antes** de escribirlas.
5. Escribir en el orden en que los capítulos se enlazan; después de cada uno, sus respuestas.
6. Resolver la deuda de enlaces que la tanda cierra; anotar la nueva, y la de ejecución.
7. Correr el verificador (§4).
8. Actualizar §3, §6, §7, §8 y §9 de este documento.

### 2.3 Una tanda técnica (T23, T24)

Compila y ejecuta el código del corpus en un contenedor temporal (§13.1 de la guía). Terminada cuando
la deuda de ejecución de sus lenguajes está vacía o cada fila restante tiene su motivo escrito en el
capítulo, y los capítulos llevan `Versiones ejecutadas:`.

---

## 3. 📊 Estado

Leyenda: ⬜ pendiente · 🟡 en curso · ✅ terminada y verificada.

| Tanda | Entrega | Estado |
|---|---|---|
| **P1** | `propuesta-contenido.md`: temario, niveles, rutas, dominio y decisiones (borrada en P8) | ✅ |
| **P2** | `guia-de-estilo-y-convenciones.md` | ✅ |
| **P3** | `prompt-base.md`: las fichas de los 74 capítulos y las 13 simulaciones | ✅ |
| **P4** | `prompts-de-fase.md`: T0–T25 | ✅ |
| **P5** | Este plan | ✅ |
| **P6** | `verificar-corpus.py`, probado sobre `prompts/` | ✅ |
| **P7** | Fuentes: edición, año y editorial de la bibliografía (guía §10.1), comprobados; patrones por lenguaje y material suplementario | ✅ |
| **P8** | Revisión cruzada final y borrado de la propuesta, con permiso de Oskar | ✅ |
| **T0** | Carpetas de bloque y esqueletos de los 13 solucionarios | ✅ |
| **T1** | `01/01`–`01/04` | ✅ |
| **T2** | `01/05`–`01/08`, simulación `01/09`, `01/10` completo | ✅ |
| **T3** | `02/01`–`02/04` | ✅ |
| **T4** | `02/05`–`02/07`, simulación `02/08`, `02/09` completo | ✅ |
| **T5** | `03/01`–`03/05`, simulación `03/06`, `03/07` completo | ✅ |
| **T6** | `04/01`–`04/04` | ✅ |
| **T7** | `04/05`–`04/07`, simulación `04/08`, `04/09` completo | ✅ |
| **T8** | `05/01`–`05/04` | ✅ |
| **T9** | `05/05`–`05/07`, simulación `05/08`, `05/09` completo | ✅ |
| **T10** | `06/01`–`06/04` | ✅ |
| **T11** | `06/05`–`06/07` | ✅ |
| **T12** | `06/08`–`06/09`, simulación `06/10`, `06/11` completo; **decisión de talleres** | ✅ (talleres aplazados a después de T22) |
| **T13** | `07/01`–`07/03` | ✅ |
| **T14** | `07/04`–`07/05`, simulación `07/06`, `07/07` completo | ✅ |
| **T15** | `08/01`–`08/05`, simulación `08/06`, `08/07` completo | ✅ |
| **T16** | `09/01`–`09/03`, simulación `09/04`, `09/05` completo | ✅ |
| **T17** | `10/01`–`10/03` | ✅ |
| **T18** | `10/04`–`10/06`, simulación `10/07`, `10/08` completo | ✅ |
| **T19** | `11/01`–`11/03`, simulación `11/04`, `11/05` completo | ✅ |
| **T20** | `12/01`–`12/03` | ✅ |
| **T21** | `12/04`–`12/05`, simulación `12/06`, `12/07` completo | ✅ |
| **T22** | `13/01`–`13/04`, simulación final `13/05`, `13/06` completo | ✅ |
| **T23** | Revisión técnica de C++ y Java | ✅ |
| **T24** | Revisión técnica de Go, JS/TS, Python y C# | ✅ |
| **T25** | README del corpus y de los 13 bloques; verificación global; borrar este plan | ✅ (el plan se conserva, por decisión de Oskar) |
| **T26** | Talleres: preparación, `laboratorio/` (legado y seis estados), `14/01`–`14/06`, `14/07` completo y README del bloque | ✅ |

**Total del corpus: 114 documentos** —74 capítulos, 13 simulaciones, 13 solucionarios y 14 README—,
más los de `prompts/`. Con T26, **122**: seis talleres, su solucionario y su README, más el laboratorio (el legado y seis
estados, todos compilados y con sus pruebas en verde).

---

## 4. 🔍 Las verificaciones

Se corren al cerrar cada tanda, y todas en T25. **Una sola orden**, desde la raíz del corpus:

```bash
python3 prompts/verificar-corpus.py              # todo el corpus
python3 prompts/verificar-corpus.py 04-creacionales   # solo un bloque
```

- Comprueba **errores**: enlace interno roto; ancla que no existe; enlace relativo que sale del
  corpus; capítulo con distinto número de preguntas que su solucionario; emoji en un `###`.
- Y **avisos**, a revisar a mano: capítulo fuera de su banda de líneas o de preguntas; callout fuera
  de la lista de §9.3 de la guía; solucionario con entradas "pendiente".
- Sale con código distinto de cero si hay algún error.

Lo que el verificador **no** puede comprobar, y se hace a mano en cada tanda:

- **URLs externas**, por código de estado, en serie y con encabezado de navegador:

  ```bash
  curl -s -o /dev/null -w '%{http_code} %{url_effective}\n' -L -A 'Mozilla/5.0' '<URL>'
  ```

  - `-o /dev/null` descarta el cuerpo; `-w` imprime el código final y la URL donde se aterrizó.
  - `-L` sigue redirecciones, porque aterrizar en la portada en vez de en la página **cuenta como
    roto** aunque el código sea `200`.
  - `-A` manda un agente de navegador: algunos sitios responden `403` a `curl`.
- **Diagramas Mermaid**: al escribir, solo con la notación de §5.7 de la guía; el renderizado de
  todos se comprueba en T23 con `mermaid-cli` en el contenedor.
- **La literalidad** de los enunciados en el solucionario (el verificador cuenta, no compara texto;
  en T25 se compara entero).

---

## 5. 📦 Las tandas, una por una

### P7 — Fuentes

Comprobar por la página de la editorial (o por búsqueda web) edición, año y editorial de los catorce
libros del canon de §10.1 de la guía, y fijarlos en esa tabla. **Terminada cuando** la tabla no
tiene ningún dato sin comprobar y la bitácora dice cómo se comprobó cada uno.

### P8 — Revisión cruzada y borrado de la propuesta

Releer guía, `prompt-base.md`, prompts y plan juntos; que todo lo decidido en la propuesta (D1–D24)
esté en su sitio definitivo; y, **con permiso de Oskar**, borrar `propuesta-contenido.md` y limpiar
sus menciones. **Terminada cuando** el verificador no da errores en `prompts/` y ninguna decisión
vive solo en la propuesta.

### T0 — Arranque de la escritura

Las trece carpetas y los trece solucionarios en esqueleto, sin enlaces a capítulos inexistentes.

### T1 a T22 — La escritura

Ver el prompt de cada una. **Terminadas cuando** sus capítulos pasan §14 de la guía, el solucionario
del bloque tiene sus respuestas, el verificador sale limpio y las deudas están anotadas.

### T23 y T24 — La revisión técnica

Ver §2.3. No empiezan sin permiso de Oskar para Docker.

### T25 — Cierre

Ver su prompt. Con T26, la única tanda que toca README.

### T26 — Talleres

La tanda que añade el bloque opcional `14-talleres` (guía §13.2). Prepara sus reglas, escribe y corre el
laboratorio, y escribe los seis talleres con su solucionario. Es a la vez de preparación, de escritura y
técnica: el código se corre mientras se escribe, con Docker y la imagen de Maven fijada.

---

## 6. 🧾 Deuda de enlaces abierta

Cada mención en prosa que espera a que exista su destino. Formato: origen → destino → tanda que la
cierra.

| Origen | Destino pendiente | La cierra |
|---|---|---|

---

## 7. ⏳ Deuda de ejecución

Cerrada en T23 y T24 (2026-10-04). Cómo se verificó, en contenedores temporales y con los arneses fuera del corpus:

- **Sintaxis de todo el código**: los 442 bloques Java con `javac` de JDK 21 (y de nuevo con `--release 17`), los 112 de C++
  con GCC 14.4 en C++23 (con tipos de relleno para los nombres del dominio que el fragmento no declara), los 15 de Go con
  `gofmt`, los 8 de JavaScript con `node --check`, los 5 de TypeScript con `tsc --strict` 7.0.2 y los 13 de Python con
  `py_compile`. Los 59 diagramas Mermaid, renderizados con `mermaid-cli` 11.17.0.
- **Afirmaciones ejecutadas**: 42 de Java (JDK 21.0.12), 5 de Java 25 (JDK 25.0.4: `StableValue` en *preview*, Scoped
  Values, patrón `_`, constructor flexible), 22 de C++ (GCC 14.4), 9 de Spring y JPA (Spring Boot 4.1.1 con H2), 10 de Go
  (1.27.1), 11 de JavaScript (Node 24.21.0) más la exhaustividad y las marcas de TypeScript, 17 de Python (3.14.8, con
  SQLAlchemy 2.1.3 y Django 6.1.1) y 7 de C# (.NET 10.0.12). Todas confirmadas.
- **Errores a propósito**: los siete Java y los tres C++ marcados `// no compila` fallan con el motivo que dice el texto;
  los contratos de C++26 no los implementa ni GCC 14.4 ni GCC 15.3.
- **Java 17**: los bloques que solo compilan en 21 (todos por el `switch` de patrones) tienen su alternativa en un callout
  o en el 🔬 de su respuesta.

**Corregido por la verificación**: una variable que se referenciaba a sí misma en `06/11` (`boolean ana = cumple(r, ana,
…)`); una llamada con `/* ... */` y coma colgante en `05/07`; un esquema de firmas escrito como Java inválido en `03/07`
(ahora bloque `text`); las firmas del SDK de `05/01`, marcadas `// no compila`.

**La deuda que quedaba, ejecutada después de T25** (2026-10-04, a pedido de Oskar: "lo ejecutable"):

| Qué | Dónde | Cómo | Resultado |
|---|---|---|---|
| El SQL y los `CHECK`, `RETURNING`, `ON CONFLICT` | `02/07`, `02/09`, `07/02`, `07/07`, `08/03`, `08/07` | PostgreSQL 18.6, cuatro escenarios con el esquema mínimo que pide cada bloque | Todo como dice el texto: los `CHECK` rechazan las filas inválidas, el bloqueo optimista da `UPDATE 1` y luego `UPDATE 0`, `ON CONFLICT DO NOTHING` da `INSERT 0 0` al segundo |
| Lombok | `02/03`, `04/08`, `04/09` | Lombok 1.18.48 | `@Data` con ciclo: `StackOverflowError` en `toString`, `hashCode` y `HashSet.add`; con `Exclude`, no. `@Builder` en la clase deja nulos; en el constructor, valida |
| Controladores, DTO, sesión, `Specification`, seguridad, filtros de *servlet* | `06/05`, `06/11`, `07/05`, `08/01`, `08/02`, `08/04`, `13/01` §4 | Spring Boot 4.1.1 (Tomcat 11.0.24, Jackson 3.1.5, Spring Security 7.1.1) y `curl` contra cuatro instancias | Confirmados; tres correcciones (abajo) |
| El ciclo en Jackson | `02/03`, `08/02` | Jackson 2.22.3 y 3.1.5 | Ninguno desborda la pila: cortan por profundidad (1000 y 500). Corregido en el texto |
| Netty, `Selector` y `epoll` | `10/05`, `10/08` | Netty 4.2.18 con un bucle; JDK 21 y GCC 14.4 con cien y doscientos clientes | Con 50 ms bloqueantes en el bucle, el último espera ~5 s y el latido también; con el ejecutor aparte, todos ~60 ms. Sin `listos.remove()`, `NullPointerException` |
| Tipos *owned* de EF Core | `09/01` | EF Core 10.0.12 con SQLite | Se cargan sin `Include`; `Set<Documento>()` y declararlo como entidad aparte lanzan `InvalidOperationException` |

**Corregido por esta segunda pasada**: `08/02` §1 decía que la sesión abierta en la vista la activa "alguien" (Spring Boot la
trae activada y lo avisa al arrancar) y que el ciclo en JSON desborda la pila (Jackson lo corta por profundidad, y en la
prueba con el `200` ya enviado); `02/03` repetía el desbordamiento en Jackson, y su pregunta 16 cambió de enunciado (también
en `02/09`); el `FiltroAuditoria` de `06/05` no auditaba las peticiones que terminan en excepción (ahora con `finally`);
`07/07` 03→18 decía "activar" *Open Session in View*. Añadido: en `13/01` §4, que lo que la regla no nombra se deniega
(`401`/`403`), y en `10/08` 05→14, la consecuencia comprobada de olvidar el `remove()`.

**Lo único que no se ejecuta**: las carreras del `this` que escapa y del `notify` perdido (`10/01` §3, `10/02` §3). No se
reproducen de forma determinista; se razonan con el modelo de memoria, y el texto lo dice.

---

## 8. 📓 Bitácora

Una entrada por sesión, la más reciente arriba: qué se cerró, qué quedó a medias y por qué, qué se
comprobó y cómo, y las trampas que la próxima sesión debe conocer.

**2026-10-05 · Revisión posterior al cierre — diagramas a Mermaid.** A pedido explícito de Oskar, 106 bloques `text` pasaron
a Mermaid (`flowchart`) en 85 documentos: 85 árboles de decisión y mapas mentales (generados por un parser de `├─ └─` y
revisados uno por uno dibujados), 3 árboles a mano (`02/05`, `03/02`, `13/04` §2) y 18 diagramas de memoria y de flujo a mano
(referencias de `01/01` y `01/10`, `HashMap`, copia superficial y profunda, vtable, *slicing*, FK, DIP, validación,
Prototype, Mediator, Transaction Script, Front Controller, Immutable Object, DCL). Cuatro notas sueltas salieron del bloque a
prosa (`02/01`, `03/03`, `08/01`, `08/04`) y la de `03/02` se reescribió. Siguen en `text` doce bloques que son posición o
tiempo: los siete árboles de archivos de `14`, la carrera de hilos de `10/06`, la tabla de `07/04` §1, el bucle de `10/05`,
las métricas de `03/07` y la "Regla de dibujo" de `01/01`. Regla en la guía §3, §5.7, §6, §9.1 y §14; fichas del
`prompt-base.md` y prompts de `01/01` y `01/05` al día. **Comprobado:** `mmdc` 12.0.0 dibuja los 91 archivos con Mermaid
(166 diagramas, 0 fallos); verificador, 0 errores y 0 avisos. Es un cambio de forma: la `Vigencia:` de los capítulos no se
tocó (la de la guía, sí). Trabajo en `zz-code/03-poo-y-patrones-20261005-645b/` (archivado: no volver a correr los lotes,
los bloques ya no existen). Trampas: Mermaid apila en `LR` el último subgrafo declarado arriba; una lista de preguntas
sueltas en rombos sale kilométrica (van en caja); `<`, `>` y `|` en etiquetas, con `#lt;`, `#gt;` y `#124;`.

**2026-10-04 · Revisión de cierre.** Sin marcas de trabajo abierto en el corpus (`sin correr`, `TODO`, deudas de §6 y §7
vacías o justificadas, checklist completo). La `Vigencia:` pasó a 2026-10-04 en los siete documentos cuyo contenido corrigió la
deuda de ejecución (`02/03`, `02/09`, `06/05`, `07/07`, `08/02`, `10/08`, `13/01`); los demás conservan 2026-10-03 porque solo
ganaron su línea de versiones. Para el commit de Oskar: `prompts/__pycache__/` es residuo del verificador, y el
`.gitignore` de la raíz del repositorio no ignora ni `__pycache__` ni `target/`.

**2026-10-04 · T26 — Talleres.** Oskar aprobó los talleres en la versión intermedia (seis, en Java) como tanda final, con
"todos" escritos en ella. **Preparación:** reglas, divergencias y plantilla en §13.2 de la guía (más su bloque en el
checklist §14 y Feathers en §10.1, comprobado por su índice); fichas `14/01`–`14/07` y la tabla de pecados del legado en §18
del `prompt-base.md`; el prompt de T26 en `prompts-de-fase.md`; el verificador, extendido a talleres (banda de 8–12
preguntas, 300–650 líneas, sincronía de ejercicios `**NN → E#.**`). **Laboratorio:** `legado/` (561 líneas, 5 clases, sin
pruebas) y `estados/01`–`06` (de 20 a 33 pruebas), todos corridos con `maven:3.10.0-eclipse-temurin-21`, JUnit 6.1.3 y H2
2.5.252, copiando cada proyecto al *scratchpad* para que `target/` nunca se cree en el corpus. **Escritura:** seis
talleres (369–456 líneas), `07-respuestas.md` (60 preguntas en tres capas y 24 ejercicios con su código corrido) y el
`README.md` del bloque; el `README.md` del corpus gana el bloque en el mapa, en la ruta completa (107 documentos, ~242 h) y
en la tabla de versiones. **Comprobado:** cada salida pegada es de su corrida; literalidad de preguntas y ejercicios contra
el solucionario, sin diferencias; 20 URL nuevas, todas `200` sin redirección; verificador sin errores ni avisos.
**Hallazgos que cambiaron el texto:** la respuesta 10 de `14/02` (un `UNIQUE (numero, referencia)` en `movimiento` choca con
dos transferencias iguales, porque la transferencia guarda la otra cuenta en `referencia`; comprobado en E4 de `14/06`,
cuya solución usa una tabla `pago_aplicado`); la caracterización no cubría el orden de las reglas (E2 de `14/05`) ni
desbloquear una cuenta cerrada (pregunta 8 de `14/04`), y el texto lo dice. **Trampas:** la VM de Docker estuvo saturada
por un nodo de `kind` ajeno a la tanda (una construcción tardó 6 minutos; se esperó en lugar de matar nada ajeno); dos
corridas en paralelo sobre `~/.m2` se pisaron y no dejaron `target/`, así que las corridas van de a una; el verificador
marca "pendiente" dentro de "independiente" también en el solucionario de talleres; una negrita dentro de un enunciado no
cabe en el `**…**` del solucionario.

**2026-10-04 · Deuda de ejecución restante.** Ejecutado lo que T23 había dejado razonado (detalle en §7): SQL en
PostgreSQL 18.6, Lombok 1.18.48, un servidor Spring Boot 4.1.1 con cuatro instancias (vista, DTO, entidad expuesta con y
sin *Open Session in View*, sesión en dos servidores, `Specification`, cadena de seguridad, filtros de *servlet*), Jackson
2 y 3, Netty 4.2.18, `Selector` y `epoll` con clientes concurrentes, y EF Core 10.0.12. Seis correcciones de texto, todas
listadas en §7. **Trampas**: con `ContentNegotiatingViewResolver` y sin motor de plantillas, el nombre de vista
`persona/ficha` se reenvía como ruta relativa y cae en `/personas/{id}/ficha` con `id="persona"` (un `400` del arnés, no
del texto: el registro confirmó el nombre de vista y el modelo); en Spring Security 7, una ruta sin regla responde `401`
sin credenciales y `403` con ellas; la `postgres:18` se bajó aunque ya existía `postgres:18.6` en la máquina (se borra al
final con las demás).

**2026-10-04 · T25.** Cierre del corpus. `README.md` del corpus con las ocho rutas **calculadas por cierre de
prerrequisitos** (la misma lógica del verificador: todo lo que cada capítulo enlaza en su encabezado), con las horas a 2,5 h
por capítulo y 3 h por simulación y los solucionarios sin contar; las rutas rápidas crecieron respecto de la tabla de partida
del `prompt-base.md` (POO ~48 h, SOLID ~53 h, patrones ~102 h, persistencia ~98 h, concurrencia ~56 h, políglota ~88 h,
completa ~224 h, entrevista esta semana ~38 h), y el README lo dice. No hay mediciones reales de lectura con las que
recalibrar más. Los trece `README.md` de bloque (índice, orden de lectura, mapa mental, niveles, qué no está y versiones)
se generaron con un guion del *scratchpad* y textos propios de cada bloque. **Comprobado**: verificador con 0 errores y 0
avisos en todo el corpus, rutas incluidas; literalidad de los 87 documentos con preguntas contra sus trece solucionarios, 0
diferencias; las 281 URLs externas del corpus, todas `200` (una de MDN redirigía a su nueva ubicación y se cambió por la
final); la misma `Vigencia:` (2026-10-03) en todos los documentos, con `Versiones ejecutadas:` fechada aparte. **Por decisión
de Oskar este plan se conserva**: no se borró ni se limpiaron sus menciones. **Pendiente de Oskar**: la decisión sobre los
talleres (regla 10 de §1, guía §13.2, `prompt-base.md` §18), que tocaba tomar después de T22.

**2026-10-04 · T23 y T24.** Con el permiso de Docker de Oskar. Imágenes: `gcc:14` (14.4.0) y `gcc:15` (15.3.0),
`eclipse-temurin` 17 (17.0.20), 21 (21.0.12) y 25 (25.0.4), `golang:1.27` (1.27.1), `node:24` (24.21.0, con TypeScript 7.0.2
instalado en el contenedor), `python:3.14.8-slim-trixie` (con SQLAlchemy 2.1.3 y Django 6.1.1), `mcr.microsoft.com/dotnet/sdk:10.0`
(10.0.401, *runtime* 10.0.12), `maven:3-eclipse-temurin-21` (Spring Boot 4.1.1, Spring Framework 7.0.9, Hibernate 7.4.5, H2
2.4.240) y `minlag/mermaid-cli`. **Mermaid**: la imagen de `mermaid-cli` no trae Chrome para ARM64 y Rosetta no lo arranca; se
renderizó en un contenedor `node:24` con el Chromium de Debian y `@mermaid-js/mermaid-cli` 11.17.0 (comprobado que un diagrama
roto sí falla): 59 de 59. **Java**: un revisor sobre la API `JavaCompiler` probó cinco envolturas por bloque (unidad, miembros,
sentencias, declaraciones y sentencias separadas, firmas completadas) y separó errores de sintaxis de símbolos del dominio. Lo
que quedó se revisó a mano: dos defectos reales (`06/11`, `05/07`) y un esquema en `03/07`, corregidos; el resto eran
esquemas `// no compila` o fragmentos de firma y uso. **Hallazgo del arnés de Spring**: leer campos directamente de un bean
con proxy CGLIB devuelve los del proxy (vacíos); el arnés pasó a métodos. Se añadió `Versiones ejecutadas:` a los 98
documentos con código, según sus lenguajes, y se quitaron todas las marcas "sin correr". Detalle de lo verificado y de lo
que no, en §7. Contenedor y volumen temporales retirados; las imágenes quedan para que Oskar decida.

**2026-10-03 · T21 y T22.** Oskar pidió terminar T21–T25 en una sesión; al empezar dio permiso para Docker en T23–T24 y decidió
**conservar este plan** al cerrar T25. T21: `12/04`, `12/05`, la simulación `12/06` (revisión de código en vivo: 30 `S#` y cinco
fragmentos; el E5, un retiro bien hecho, se aprueba) y `12/07` completo. T22: `13/01`–`13/04`, la simulación final `13/05` (36
`S#` y 5 ejercicios; el que va sin patrón es `esMenorEn` en `Persona`) y `13/06` completo. **Deuda de enlaces vacía**: cerradas
las de `12/04` (Singletonitis, Service Locator, *lasagna*, pie de `12/03`) y `13/01` (`06/03` §7). Verificador: **0 errores, 0
avisos** en todo el corpus. **Decisiones de contenido**: `13/01` y `13/02` son capítulos de mapa (dónde está el patrón, cómo se
ve, qué muerde); `13/04` no lleva código (excepción declarada en su encabezado); `12/05` presenta *Reconstruction* de Foote y Yoder
como último recurso y no nombra patrones de arquitectura (el *Strangler Fig* queda fuera, §1.1 de la guía). **Comprobado**: el
artículo *Big Ball of Mud* (PLoP '97; "most frequently deployed", la lista de sus siete patrones); *Inversion of Control
Containers and the Dependency Injection pattern* de Fowler; Seemann y van Deursen, caps. 4 y 5; Ousterhout, caps. 4 y 7
(*pass-through methods*); la referencia de Spring Framework 7.0.9 (proxies JDK y CGLIB, autoinvocación en caché y
transacciones, `JdbcTemplate` "central class", `FactoryBean`, alcances frente al GoF, `RestTemplate` **obsoleto en favor de
`RestClient`**) y de Spring Security (`FilterChainProxy` y `SecurityFilterChain`); el catálogo de *Refactoring to Patterns* en
Industrial Logic (27 refactorizaciones; los problemas de *Replace Conditional Logic with Strategy*, *Replace State-Altering
Conditionals with State*, *Replace Implicit Tree with Composite* e *Inline Singleton*) y los caps. 6–11 del libro por búsqueda;
las Javadoc de `Runtime` ("single instance"), `Executor` ("decoupling task submission") y `Collections` (recorrer una colección
sincronizada exige el candado); cppreference (`std::stack` como adaptador, `std::pmr::polymorphic_allocator`); *Head First* 2.ª
ed., cap. 13; GoF, cap. 1, "How to Select a Design Pattern". **No se citó**: la tabla 1.2 del GoF (no comprobada). Longitudes:
290, 252, 278, 202, 233, 210; simulaciones 225 y 198.

**2026-10-03 · T20.** `12/01`–`12/03` y sus 52 respuestas en `12/07`. Estrena la plantilla de antipatrones (§6.5): los
*smells* de `12/01` y `12/02` en formato ligero (síntoma, por qué importa, refactorización) y los antipatrones de `12/03` con
sus seis etiquetas; el God Object con su salida completa en cinco pasos y el modelo anémico con el matiz del CRUD. `12/03` es
de la ruta corta y abre con un párrafo de lo que asume. Cerrada la deuda hacia `12/01`–`12/03` en los bloques 02–09,
solucionarios incluidos (el modelo anémico, el God Object, la generalización especulativa, los *smells* de `03/02`).
**Nombres**: los de *Refactoring* 2.ª ed. (Long Function, Repeated Switches, Lazy Element, Insider Trading), con el de la 1.ª
entre paréntesis; Parallel Inheritance Hierarchies se presenta como nombre de la 1.ª ed. que la 2.ª ya no lista. **Comprobado**:
el índice de *Refactoring* 2.ª ed. en la muestra de Pearson (lista de los 24 *smells* del cap. 3 y de las refactorizaciones
con su capítulo: 6 "A First Set", 7 "Encapsulation", 8 "Moving Features", 10 "Simplifying Conditional Logic", 11 "Refactoring
APIs", 12 "Dealing with Inheritance") y el de la 1.ª ed. (Long Method, Switch Statements, Parallel Inheritance Hierarchies,
Lazy Class, Inappropriate Intimacy); el catálogo de `refactoring.com` (16 páginas por código de estado); el bliki *CodeSmell*
("surface indication", el término es de Kent Beck), *CallSuper*, *AnemicDomainModel* (el síntoma y el "fundamental horror") y
*TellDontAsk*; la Javadoc de `Stack` (usar `Deque`) y de `Properties` (`put` "strongly discouraged"); *AntiPatterns*, cap. 5
(The Blob, Lava Flow, Poltergeists, Golden Hammer), por búsqueda; Ousterhout 2.ª ed., caps. 12 y 13; Bloch, ítems 18 y 22.
**Bibliografía ampliada**: *Refactoring*, 1.ª ed. (Addison-Wesley, 1999), solo por los nombres viejos, comprobada por su
índice y añadida a la guía §10.1. **Corregido al escribir**: `03/04` no nombra la ley de Demeter; `12/02` la nombra sin
atribuirla a ese capítulo. Los esquemas del God Object van con `// no compila: esquema…`. Longitudes: 269, 249, 379.

**2026-10-03 · T19.** Bloque 11 entero: `11/01`–`11/03`, la simulación `11/04` (30 `S#` y 5 ejercicios; el que va sin patrón
es el número de cuenta enmascarado, una función en cada lenguaje) y `11/05` completo: 54 respuestas de capítulo, 30 de
simulación y 5 ejercicios. Cerrada toda la deuda de enlaces "en Go / JS / Python" de los bloques 01, 04, 05, 06 y 10.
**Versiones de escritura**, comprobadas en sus sitios oficiales el día de la tanda (la revisión técnica fija las de la
corrida): Go 1.27.1 (`go.dev/VERSION`), Node.js 24 LTS "Krypton" (la 26 es *Current*), TypeScript 7.0.2 (npm), Python 3.14.8
(`python.org`); y en las páginas citadas, SQLAlchemy 2.1 y Django 6.1. **Decisiones de contenido**: los tres capítulos abren
con el error de quien escribe Java en ese lenguaje (Template Method con *embedding*, `this` perdido en `forEach`, `@decorator`
para auditar solo en producción); `11/03` compara SQLAlchemy (Unit of Work e Identity Map) con Django ORM (Active Record) con
código; repartos 4/5/5/4, 4/4/6/4 y 4/5/5/4 (los vecinos difieren). **Comprobado**: la FAQ de Go ("Yes and no"; *nil error*),
*Effective Go* (el receptor de un método promovido es el tipo interior; "share memory by communicating"), *Code Review
Comments* (interfaces en el paquete que las usa), `sync.OnceValue` (Go 1.21), iteradores (Go 1.23) y variables de bucle (Go
1.22); MDN (clases "built on prototypes", *run-to-completion*, `this`, `Proxy`), la documentación de Node sobre `EventEmitter`
(oyentes síncronos en orden de registro), el *handbook* de TypeScript ("Type annotations never change the runtime behavior";
tipado estructural; exhaustividad con `never`); Vanderkam, *Effective TypeScript* 2.ª ed., ítems 3, 4 y 64; el glosario de
Python (*decorator*, *duck-typing*), la PEP 544, la MRO C3, el glosario de SQLAlchemy (`Session` y *identity map*), los
principios de diseño de Django ("following Martin Fowler's Active Record design pattern"), *free threading* desde 3.13;
Bodner, *Learning Go* 2.ª ed. (caps. 7, 12 y 14, en la muestra del libro); Ramalho, *Fluent Python* 2.ª ed. (caps. 5, 9, 10, 13,
14 y 18, en el repositorio oficial del código); *Cosmic Python* (caps. 2 y 6). **No se citó**: *100 Go Mistakes* (sin capítulo
comprobado) ni el índice de Osmani 2.ª ed. (las fuentes mezclaban ediciones). **Trampa del verificador**:
"in**dependiente**" en `11/05`, reformulado. Longitudes: 320, 288, 315; simulación 181.

**2026-10-03 · T17 y T18.** Bloque 10 entero: `10/01`–`10/06`, la simulación `10/07` (30 `S#` y 5 ejercicios; el que va sin
patrón es el contador de transferencias del día, resuelto con un `LongAdder`) y `10/08` completo: 92 respuestas de capítulo,
30 de simulación y 5 ejercicios. T17 y T18 se escribieron seguidas: al cerrar T17, `10/03` enlazaba a `10/04`, que se
escribió a continuación; el verificador se corrió limpio con las dos tandas. Cerrada la deuda hacia `10/01` (`01/03` §2),
`10/02` (`02/09`) y `10/06` (`04/05` §5, `04/07` §4 y sus respuestas en `04/09`). **Decisiones de contenido**: `10/01`
publica la tabla de tarifas inmutable con referencia `volatile` (y `std::atomic<std::shared_ptr>` en C++) y lleva la autopsia
del `this` que escapa; `10/02` usa la cuenta **bloqueada** por cumplimiento como condición de espera y lleva la autopsia de
`notify`; `10/03` lleva la autopsia de `newFixedThreadPool` (cola sin cota) y una sección propia de *virtual threads* con
semáforo; `10/05` lleva la autopsia del bucle bloqueado con JDBC; `10/06` es dueño del DCL con su autopsia y separa
`volatile` (publicar) de `Atomic*` (leer y modificar). **Comprobado**: JLS 21 §17.5 (la condición de no dejar escapar la
referencia), §17.4.5 (*happens-before* de `volatile`) y §12.4.2; JEP 506 (Scoped Values, final en 25; *preview* en 21 por
la JEP 446), JEP 491 (entregada en **24**), JEP 444 ("should never be pooled", semáforos para limitar, paralelismo del
planificador igual a los procesadores), JEP 505 (concurrencia estructurada, quinta *preview* en 25), JEP 502 (*preview* en
25); el índice de *Java Concurrency in Practice* en el catálogo de la Biblioteca del Congreso y sus secciones en la muestra de
Pearson (3.2–3.5, 5.3, 6, 8.2, 13.5, 14.2–14.3, 16.2–16.3); los capítulos de POSA2 (3 Event Handling, 4 Synchronization, 5
Concurrency) en el sitio de Schmidt y por búsqueda; *A Tour of C++* 3.ª ed., cap. 18 "Concurrency"; las Javadoc de
`Object.wait` (despertares espurios), `notify` (elección arbitraria), `ReadWriteLock` (cuándo mejora), `Executors` (cola sin
cota de `newFixedThreadPool`), `CallerRunsPolicy`, `Future.get`, `DateTimeFormatter` ("immutable and thread-safe") y
`SimpleDateFormat`; cppreference (`std::async` y su destructor que bloquea, estáticas locales con inicialización única,
`call_once`, `atomic<shared_ptr>`); la documentación de Spring Security (`SecurityContextHolder` con `ThreadLocal`) y de
WebFlux (pocos hilos; Netty por defecto en Spring Boot); la de Node (*Don't Block the Event Loop*: un hilo de bucle y un pool
de trabajadores); `io_uring(7)`; el `EventLoop` de Netty; la declaración *"Double-Checked Locking is Broken"* (firmantes y el
arreglo con `volatile` desde JDK 5). **Corregido al escribir**: el año de la declaración no se pudo comprobar y se quitó; la
URL de Node se cita en su forma final (`nodejs.org/learn/...`); una afirmación sobre el origen histórico del monitor se quitó
por no comprobada. **Trampa del verificador**: "in**dependientes**" en `10/08`, reformulado. Longitudes: 333, 307, 332, 264,
277, 345; simulación 187.

**2026-10-03 · T16.** Oskar pidió seguir con T16–T20 en una sola sesión; como antes, el Paso 1 del protocolo se asumió con
los valores por defecto. Bloque 09 entero: `09/01`–`09/03`, la simulación `09/04` (30 `S#` y 5 ejercicios; el que va sin
patrón es "documento vigente" en un solo sitio, resuelto con un método en `Documento`) y `09/05` completo: 52 respuestas de
capítulo, 30 de simulación y 5 ejercicios. Cerrada toda la deuda de enlaces hacia `09/01`–`09/03` en los bloques 01–08,
solucionarios incluidos. **Decisiones de contenido**: tres agregados (`Persona` con sus documentos, `Cuenta`, y
`Movimiento`/`Transferencia` como registros inmutables que solo se insertan); `Documento` inmutable dentro del agregado; el
tutor pasa a `PersonaId`, lo que **matiza** el `Persona tutor` de `07/01` (declarado en `09/01` §5); la transferencia entre dos
cuentas en una base es la excepción declarada a "un agregado por transacción", y el *Saga* queda fuera del corpus; el Type
Object de `09/03` lleva una `PoliticaVencimiento` sellada (`NoVence`, `AniosDesdeEmision`, `HastaMayoriaDeEdad`) para la
lógica que no cabe en datos; el Null Object se muestra con un `enum` en Java y una referencia en C++, y su "cuándo no" es la
`CuentaNula` que hace desaparecer una transferencia. **Comprobado**: el índice de *Domain-Driven Design* en la muestra de
Pearson (cap. 5 Entities, Value Objects, Services; cap. 6 Aggregates, Factories, Repositories; cap. 9 Specification; cap. 10
la Specification declarativa); los capítulos de Vernon, *IDDD* (5 Entities, 7 Services, 8 Domain Events, 10 Aggregates, 11
Factories); las cuatro reglas de *Effective Aggregate Design* en sus PDF de la DDD Community; la *DDD Reference* de 2015
(Domain Events marcado como término nuevo, posterior al libro; Services y Factories); el bliki *DDD_Aggregate*; el artículo
*Specifications* de Evans y Fowler (validación, selección, construcción a pedido); la página de Spring Data sobre eventos de
agregados (`deleteById` no publica) y la de eventos transaccionales de Spring (sin transacción no se invoca, salvo
`fallbackExecution`); los tipos *owned* de EF Core (sin `DbSet` propio); la guía de .NET sobre eventos de dominio (despacho
diferido antes o después de `SaveChanges`); Nystrom, "Type Object" (intención y costos); *Introduce Special Case* con alias
*Introduce Null Object*, cap. 10 de *Refactoring* 2.ª ed.; `OutputStream.nullOutputStream()` y `Writer.nullWriter()` en la
API de Java 21. **Bibliografía ampliada**: *Pattern Languages of Program Design 3* (Addison-Wesley, 1998), por el "Null
Object" de Woolf, comprobado en InformIT y añadido a la guía §10.1. **Trampa del verificador, otra vez**: "como
**pendiente**" en `09/05`; reformulado como "sin enviar". Longitudes: 363, 333, 332; simulación 171.

**2026-10-03 · T15.** Bloque 08 entero: `08/01`–`08/05`, la simulación `08/06` (30 `S#` y 5 ejercicios; el que va sin
patrón es formatear el saldo con `NumberFormat` en lugar de una jerarquía de formateadores) y `08/07` completo: 76 respuestas
de capítulo, 30 de simulación y 5 ejercicios. Cerrada la deuda hacia `08/02`, `08/03` y `08/05` en los bloques 01, 02, 05 y
07. **Decisiones de contenido**: `08/01` separa el MVC original (con *Observer Synchronization*) del de servidor; `08/03` separa
el `FOR UPDATE` (bloqueo de la base, una transacción) del Pessimistic Offline Lock (tabla de bloqueos con caducidad), y
explica el Coarse-Grained Lock con `OPTIMISTIC_FORCE_INCREMENT` sobre la cuenta; `08/05` da el `repartir` de Money en Java y
C++ con el centavo sobrante asignado uno a uno. Las fichas C se escribieron con las cuatro etiquetas y en tabla en `08/05`, para
no alargar. **Comprobado**: *GUI Architectures* en `martinfowler.com` (*Separated Presentation*, *Observer Synchronization*);
la referencia de Spring MVC ("designed around the front controller pattern"); la ficha de DTO ("carries data between
processes in order to reduce the number of method calls") y el bliki *LocalDTO* (la cita de Randy Stafford); el artículo de
2014 sobre la primera ley; la Javadoc de `Version` y `LockModeType` de Jakarta Persistence 3.2; la ficha de Money (ninguna
librería base lo trae) y de Special Case; el bliki *ValueObject* (los objetos de valor deben ser inmutables); Spring Session;
RFC 7519. **Corregido al escribir**: el límite de un `long` de centavos (9,2 trillones, no "noventa mil billones"); una analogía
de `08/04` reemplazada por una frase directa; `08/04` ampliado con una sección de costos para entrar en la banda de 200.
Longitudes: 200, 224, 235, 200, 315; simulación 152.

**2026-10-03 · T14.** `07/04`, `07/05`, la simulación `07/06` (30 `S#` y 5 ejercicios; el que va sin patrón es marcar los
documentos vencidos con un solo `UPDATE`) y `07/07` completo: 34 respuestas de capítulo, 30 de simulación y 5 ejercicios.
Bloque 07 cerrado. **Desviación declarada**: `07/04` ejemplifica la herencia con la jerarquía de movimientos de `06/07`, no
con documentos, por el Type Object de `02/06`; y resuelve el titular polimórfico (`Cuenta → Titular`, deuda de `01/09` E3)
con dos FK opcionales y un `CHECK`. **Comprobado**: la especificación de Jakarta Persistence 3.2 ("Support for the table per
concrete class inheritance mapping strategy is optional in this release"); la Javadoc de `Embeddable` (un *record* puede ser
incrustable) e `InheritanceType`; la página de *Specifications* de Spring Data ("Based on the concept of a specification
from Eric Evans' book"); Evans cap. 6 (repositorios). **Corregido al escribir**: se evitó `Specification.where`, que las
versiones recientes de Spring Data marcan como obsoleto; se suavizó la afirmación sobre deshacer `EAGER` por consulta (los
grafos de entidad pueden, con soporte desigual). Longitudes: 330, 250; simulación 176.

**2026-10-03 · T13.** `07/01`–`07/03` y sus 50 respuestas en `07/07`. Estrena el reparto de Fowler: Java primero y
completo, y C++ declarado como "no aporta" en el encabezado de los tres capítulos. Cerrada la deuda hacia `07/01` y `07/03`
en los bloques 01–05. **Comprobado**: el índice completo de *PoEAA* en InformIT (Part 1: caps. 1 "Layering" a 8 "Putting it
all Together"; Part 2: caps. 9 a 18 con sus patrones); las fichas del catálogo de `martinfowler.com` de los 51 patrones de
los bloques 07 y 08 (todas `200`); la Javadoc de `EntityManager` de Jakarta Persistence 3.2 (contexto de persistencia
con "at most one entity instance", los cuatro estados, "there is no explicit update operation", la sincronización no
inmediata, `getReference`); la de `@Version` (para T15); `DbContext` de EF Core ("a combination of the Unit Of Work and
Repository patterns"); `spring.jpa.open-in-view` en `true` por defecto; la guía de Panache (modos Active Record y
repositorio). Longitudes: 321, 303, 317.

**2026-10-03 · T11 y T12.** Oskar pidió seguir con T11–T15. **Decisión de talleres** (la de T12) tomada **al empezar
la sesión**, porque bloqueaba T13: Oskar eligió **decidirla después de T22**, con el corpus teórico completo; se
corrigió la regla 10 de §1. T11: `06/05`–`06/07`; T12: `06/08`, `06/09`, la simulación `06/10` (32 `S#` y 5
ejercicios; el que va sin patrón es el `switch` exhaustivo que traduce `EstadoCuenta` a texto y color) y `06/11`
completo: 142 respuestas de capítulo en T11–T12, 32 de simulación y 5 ejercicios. Bloque 06 cerrado. **Decisiones de
contenido**: `06/05` abre con la aprobación por monto (cadena que se corta) y deja las validaciones de documento como la
variante que acumula, declarado en su encabezado; `06/07` usa la jerarquía sellada de **movimientos** (`Deposito`,
`Retiro`, `TransferenciaEnviada`, `TransferenciaRecibida`, `Comision`) en lugar de una jerarquía de documentos, porque en
el corpus los documentos se distinguen por Type Object (`02/06`); declarado. `06/06` muestra el ciclo de vida en una
tabla de transiciones en bloque `text` (Mermaid `stateDiagram` no está en la notación de la guía §5.7). `06/09` separa el
inserto de C# en su propia sección para dejar el callout de Java 17 en la del Interpreter (un callout por sección).
**Comprobado**: JEP 441 (final en 21; un `switch` de patrones sin caso aplicable lanza `MatchException`), JEP 440 (21),
JEP 456 (final en **22**, no en 25: el callout "En Java 25" lo dice); JLS 21 §8.1.1.2 (sellada y permitidas en el mismo
módulo, o paquete); cppreference `std::visit` (idioma `overloads`) y `std::generator` (C++23); la Javadoc de
`ConcurrentModificationException` y de `ArrayList` (*fail-fast*, sin garantía), `FileVisitor`, `ElementVisitor`;
Jakarta Servlet `Filter` y `FilterChain`; Spring Security (*Servlet Architecture*) e interceptores de Spring MVC; SpEL;
*expression trees* de C#; Bloch ítems 34 y 47. Longitudes: 354, 382, 384, 263, 214; simulación 179.

**2026-10-03 · T10.** `06/01`–`06/04` y sus 64 respuestas en `06/11`. Cerrada la deuda hacia `06/01` y `06/02`
en los bloques 01, 03, 04 y 05. **Desviación declarada del dominio fijo**: `TipoCuenta` (`AHORROS`, `CORRIENTE`,
`NOMINA`; `EMPRESARIAL` en una respuesta) en `06/01`; las reglas por país de `06/02` se declaran de ejemplo, no
normativa real. **Decisión de contenido**: en `06/04`, deshacer una transferencia es ejecutar la compensatoria
(`revertir()` devuelve otra `Transferencia`), nunca borrar; se dice como el matiz que el GoF no tiene. **Comprobado**:
la nota de obsolescencia de `Observable` (las tres razones y las tres alternativas); la sección de eventos de la
referencia de Spring ("Essentially, this is the standard Observer design pattern"; los oyentes son síncronos por
defecto) y la de eventos ligados a transacciones (`@TransactionalEventListener`, fase `AFTER_COMMIT` por defecto);
el artículo *Virtuality* de Sutter (Guideline #1, y que la librería estándar ya la sigue); la Javadoc de
`AbstractList` (basta con `get` y `size`), la de `HttpServlet` en Jakarta Servlet 6.0 ("almost no reason to override
the service method") y la de `JdbcTemplate` (*callbacks*); `Flow` y `SubmissionPublisher`; la página de eventos de
C#; Head First caps. 1, 2, 6 y 8; Iglberger cap. 5. **Corregido al escribir**: el `Map.of` con lambdas y una clase
como valores no infiere el tipo y se escribió `Map.<TipoCuenta, PoliticaComision>of`; una interfaz sellada con un
`permits` de una clase no definida se dejó abierta. **Longitud**: `06/03` quedó en 410 líneas, diez por encima de
la banda de 400, dentro de la tolerancia del verificador y con índice de salto rápido; el exceso es la autopsia del
*lapsed listener* y el diagrama de secuencia. Longitudes: 357, 353, 410, 338.

**2026-10-03 · T9.** `05/05`–`05/07`, la simulación `05/08` (30 `S#` y 5 ejercicios; el que va sin patrón es
el `ServicioFechas` sobre `java.time`, reemplazado por inyectar solo el `Clock`) y `05/09` completo: 102 respuestas
de capítulo, 30 de simulación y 5 ejercicios. Bloque 05 cerrado. **Desviaciones declaradas del dominio fijo**:
`UnidadOrganizativa`, `Area` y `Puesto` (con salarios de ejemplo) en `05/05`; `Aviso` y `Canal` en `05/06`;
`Regla` con `Todas` y `Alguna` en el E5 de la simulación. **Comprobado**: la Javadoc de `Node.appendChild`
(`HIERARCHY_REQUEST_ERR` en nodos que no admiten hijos), `java.awt.Container`, `java.sql.Driver`, `Boolean.valueOf`
("significantly better space and time performance"), `String.intern` ("All literal strings … are interned"),
`Optional.empty` ("There is no guarantee that it is a singleton": se corrigió el texto de `05/07`, que la
presentaba como instancia única); JEP 192 (deduplicación en G1, entregada en 8u20) y JEP 254 (cadenas compactas,
Java 9). **Trampa del verificador, otra vez**: "inde**pendiente**" en `05/09` (cuatro veces); reformulado. Cerrada
la deuda hacia `05/05`–`05/07`. Longitudes: 362, 273, 211, 178 (simulación).

**2026-10-03 · T8.** `05/01`–`05/04` y sus 62 respuestas en `05/09`. `05/03` es el dueño de la tabla de los tres
(Proxy, Decorator, Adapter) y lleva la autopsia de `@Transactional` en la llamada interna con diagrama de
secuencia; tiene índice de salto rápido aunque queda en 398 líneas. Cerrada la deuda hacia `05/01`–`05/04` en los
bloques 01, 03 y 04. **Comprobado**: la Javadoc de `Arrays.asList` ("fixed-size list backed by the specified
array"), `InputStreamReader` ("a bridge from byte streams to character streams"), `java.lang.reflect.Proxy`,
`BufferedInputStream`, `Collections.unmodifiableList` ("unmodifiable view"); el manual de SLF4J ("serves as a
simple facade"); la referencia de Spring sobre proxies (JDK si hay interfaces, CGLIB si no; clases y métodos
`final` y métodos `private` no se interceptan) y sobre `@Transactional` ("only external method calls coming in
through the proxy are intercepted"; desde Spring 6 también los métodos `protected` y de paquete en proxies de
subclase); Spring Boot configura CGLIB por defecto (`spring.aop.proxy-target-class=true`); el índice de *PoEAA*
(cap. 9 "Domain Logic Patterns" … cap. 18 "Base Patterns") y la ficha de Service Layer en `martinfowler.com`;
*Effective Java* ítem 18 (la clase de reenvío y el problema SELF); Iglberger caps. 6 y 9. Longitudes: 358, 360,
398 y 330, dentro de la banda de 250–400 de los capítulos de un patrón de nivel A.

**2026-10-03 · T7.** `04/05`–`04/07`, la simulación `04/08` (32 `S#` y 5 ejercicios; el que va sin patrón
es el `Movimiento` como `record` con constructor) y `04/09` completo: 136 respuestas de capítulo, 32 de
simulación y 5 ejercicios. Bloque 04 cerrado, con 0 avisos. Cerrada la deuda hacia `04/05`, `04/06` y
`04/07` en los bloques 01, 03 y 04. **Comprobado**: JEP 502 (*Stable Values*, entregada en 25 como
*preview*) y JEP 526 (rediseñada como `LazyConstant`, segunda *preview* entregada en 26), con sus ejemplos
de API; JLS 21 §8.9 (enums: reflexión prohibida, serialización especial) y §12.4.2; la especificación de
serialización (un enum se guarda por su nombre y se resuelve con `Enum.valueOf`); cppreference "Storage
duration" (estática local: una sola inicialización entre hilos; si lanza, se reintenta); la página de
*scopes* de Spring ("The GoF singleton hard-codes the scope… per ClassLoader"), la de inyección (el equipo
"generally advocates constructor injection"; `BeanCurrentlyInCreationException` en los ciclos), la de
`@Autowired` (un solo constructor no necesita la anotación) y la de proxies AOP; el bliki de Fowler sobre
IoC ("Hollywood Principle"); la validación de *scopes* de .NET en desarrollo; JEP 444 ("should never be
pooled"); la Javadoc de `Currency` ("never more than one Currency instance"); *Core Guidelines* I.3 y R.1.
**Corregido al escribir**: el contenedor de ejemplo de `04/06` usaba `computeIfAbsent` recursivo sobre un
`ConcurrentHashMap`, que lanza `IllegalStateException`; se reescribió con `get` y `putIfAbsent`. El
destructor no se dibuja en Mermaid (`~` es la marca de genéricos). **Desviación de banda**: `04/07` (varios
patrones) quedó en 358 líneas, ocho por encima de 350, dentro de la tolerancia del verificador. Longitudes:
372, 354, 358, 193 (simulación).

**2026-10-03 · T6.** Oskar pidió validar T0–T5 y seguir con T6–T10 en una sola sesión; como en T0–T5, el
Paso 1 del protocolo se asumió con los valores por defecto. **Validación de T0–T5**: verificador con 0
errores; literalidad de los 20 capítulos y las 3 simulaciones contra sus solucionarios, 0 diferencias;
control del §14 automatizado limpio. **T6**: `04/01`–`04/04` y sus 56 respuestas en `04/09`. **Decisiones
que heredan los patrones de nivel A**: "Cómo nació" en C++98 de 20 a 30 líneas, solo con el problema
original y lo que el tiempo dejó mal (casi siempre la propiedad); C++ moderno y Java completos; tabla
"Se confunde con / La diferencia, en una frase" en `⚖️`; `🧭 Cómo se elige` después de `🏷️`. Los de nivel B
con capítulo propio llevan secciones `##` (problema, mecanismo, código, con qué se confunde, dónde
aparece, cuándo sí y cuándo no). **Coherencia con `02/06`**: el problema de `04/01` no crea subclases de
`Documento` por tipo; la creación varía por una regla de vencimiento que no cabe en un dato, y el
capítulo remite al Type Object cuando sí cabe. **Comprobado**: el índice del GoF (cap. 3 "Creational
Patterns", cap. 4 "Structural Patterns", cap. 5 "Behavioral Patterns", con sus secciones por patrón) en
un catálogo de biblioteca; los capítulos de *Head First* 2.ª ed. (4 "The Factory Pattern"; 1 Strategy,
2 Observer, 3 Decorator, 5 Singleton, 6 Command, 7 Adapter y Facade, 8 Template Method, 9 Iterator y
Composite, 10 State, 11 Proxy) en O'Reilly; los de Iglberger, *C++ Software Design* (4 Visitor, 5 Strategy
y Command, 6 Adapter, Observer y CRTP, 7 Bridge, Prototype y External Polymorphism, 8 Type Erasure, 9
Decorator, 10 Singleton); los de Nystrom (Command, Flyweight, Observer, Prototype, Singleton, State; Object
Pool en "Optimization Patterns"); las *Core Guidelines* C.67 y C.130 (anclas por slug completo); la
Javadoc de `Cloneable`, `Document` (los `create*` y `WRONG_DOCUMENT_ERR`), `DocumentBuilderFactory`,
`ContentHandler`; los *designated initializers* en cppreference (orden de declaración, sin anidados); JEP
468 (*Derived Record Creation*) **candidata**; la página de `@Builder` de Lombok (clase, constructor o
método; no menciona records ni valida); la expresión `with` de C# (mismo tipo en tiempo de ejecución, copia
superficial). Más de 70 URLs por código de estado, todas `200`. Deuda de T6 hacia `04/01`, `04/03` y
`04/04` cerrada con enlaces en los bloques 01–03. Longitudes: 395, 273, 385, 258.

**2026-10-03 · Los cuatro pilares, después de T5.** Oskar notó que faltaban los cuatro pilares de la POO,
pregunta de apertura habitual. Se añadieron a `01/01` como §3 ("Los cuatro pilares, y lo que la pregunta
esconde"): una frase precisa por pilar, su simplificación, el capítulo dueño de cada uno, un fragmento con
los cuatro en `Cuenta` y `Titular`, y el matiz de que la lista es didáctica. Las secciones siguientes pasaron
de §3–§9 a §4–§10 (no había anclas entrantes). Cuatro preguntas nuevas (7, 14, 21 y 22; el capítulo pasa a 26)
con su solucionario renumerado, la remisión de `09 → S1` corregida, y `S37` en la simulación. Ficha de `01/01`
en el `prompt-base.md` ampliada (Cubre y Desmonta). **Bibliografía:** Booch y otros, *Object-Oriented
Analysis and Design with Applications*, 3.ª ed. (Addison-Wesley, 2007), cap. 2 "The Object Model", añadido
al canon de la guía §10.1; comprobados en el catálogo de Pearson los autores, el año y las secciones del
cap. 2, y por búsqueda los cuatro elementos mayores (abstracción, encapsulación, modularidad, jerarquía) y los
tres menores (tipificación, concurrencia, persistencia). No se afirmó en qué elemento trata Booch el
polimorfismo: no se pudo comprobar. La cita de Kay (2003) va sin URL. `01/01` queda en 437 líneas, con índice
de salto rápido.

**2026-10-03 · T5.** Bloque 03 entero: `03/01`–`03/05`, la simulación `03/06` (32 `S#` y 5 ejercicios; el
que va sin patrón es la edad como método de una línea) y `03/07` completo: 112 respuestas de capítulo,
32 de simulación y 5 ejercicios. Cerrada la deuda hacia `03/01`, `03/02` y `03/05` en los bloques 01 y 02,
solucionarios incluidos. **Bibliografía ampliada**: Martin, *Clean Architecture* (Prentice Hall, 2017),
añadido a la guía §10.1 (caps. 7–11, SOLID; cap. 14, "Component Coupling"), comprobado en el catálogo de
Pearson; es la fuente de "un actor" para el SRP, junto con el artículo del blog del autor (comprobado por
código de estado y por su texto: "This principle is about people"). **Comprobado además**: Meyer, *OOSC*
2.ª ed., caps. 11 y 12 y su PDF oficial en `bertrandmeyer.com/OOSC2`; Larman, caps. 17 y 25; Ousterhout,
caps. 4 y 5; Metz, caps. 2, 3 y 4; Seemann y van Deursen, caps. 4 y 5; la página de cppreference
"Contract assertions (since C++26)" con sus cuatro semánticas de evaluación; P2900R14 en `open-std.org`;
la recomendación de la JLS §14.10 de no usar `assert` para argumentos de métodos públicos. **Nombres de
*smells***: se usan los de *Refactoring* 2.ª ed. (*Repeated Switches*, no el *Switch Statements* de la 1.ª
y de Refactoring Guru). **Trampa del verificador, segunda forma**: "de**pendiente**" también dispara el
aviso. **Control del §14 automatizado** en el scratchpad (callouts por sección, filas de "Errores
frecuentes", entradas de "Para profundizar", libros, orden y reparto de la dificultad): limpio en los 20
capítulos de T1–T5. `01/02` pasó de 400 líneas y ganó su índice de salto rápido. Longitudes del bloque 03:
278, 328, 278, 283, 308.

**2026-10-03 · T4.** `02/05`–`02/07`, la simulación `02/08` (30 `S#` y 5 ejercicios; el que va sin
patrón es el `Telefono` como `record`) y `02/09` completo: 160 respuestas de capítulo, 30 de simulación
y 5 ejercicios. Cerrada la deuda hacia `02/05` y `02/06`, también en el solucionario del bloque 01.
**Comprobado**: Evans, cap. 5 "A Model Expressed in Software" y cap. 6 "The Life Cycle of a Domain
Object"; *PoEAA* cap. 3 "Mapping to Relational Databases"; la nota de la Javadoc de `BigDecimal(double)`
("somewhat unpredictable"); que la reflexión estática (P2996) se votó para C++26 en Sofía, junio de 2025;
las páginas del catálogo de *PoEAA* en `martinfowler.com` (*Embedded Value*, *Foreign Key Mapping*,
*Association Table Mapping*, *Identity Field*, *Money*) y *Replace Primitive with Object* en
`refactoring.com`. **Trampa nueva:** el verificador busca "pendiente" sin límite de palabra y encuentra
"inde**pendiente**"; se escribe "aislada" o se reformula. **Desviación declarada del dominio fijo:** en
respuestas y ejercicios aparecen `Titularidad` (cuenta con varios titulares y porcentaje) y `Telefono`
como objeto de valor; `Contacto` se modela como interfaz sellada con `ContactoEmail` y
`ContactoTelefono`. Longitudes: 287, 322, 272.

**2026-10-03 · T3.** `02/01`–`02/04` y sus 94 respuestas. `02/01` fija la notación Mermaid en uso:
relaciones con el rombo o el triángulo a la izquierda (`Persona "1" *-- "*" Documento`,
`Persona ..|> Titular`), multiplicidad entre comillas, sin anotaciones `<<interface>>` (la interfaz se dice
en el texto) y como mucho doce clases. **Comprobado**: el índice de *UML Distilled* 3.ª ed. en la muestra
oficial de Pearson (cap. 3 "Class Diagrams: The Essentials", con "Bidirectional Associations" y
"Programming Interpretation of Properties"; cap. 4 "Sequence Diagrams"; cap. 5 "Class Diagrams: Advanced
Concepts", con "Aggregation and Composition", "Qualified Associations" y "Association Class"); los
capítulos 9, 17 y 25 de Larman 3.ª ed.; los textos de Lombok sobre `@ToString` y `@EqualsAndHashCode`
("all non-static, non-transient fields"); las anclas de las *C++ Core Guidelines* (`#r-resource-management`,
`#r21-…`, `#r24-…`), que son slugs del título completo y no los `#Rr-…` de versiones viejas. **Sin URL**:
la Javadoc de Jackson (la versión publicada más reciente que responde es la 2.9); se citan las
anotaciones por nombre. **Trampa:** las líneas de continuación de una pregunta van con cuatro espacios;
con tres, el comprobador de literalidad no las une. Longitudes: 319, 350, 321 y 280.

**2026-10-03 · T2.** `01/05`–`01/08`, la simulación `01/09` (36 `S#` y 5 ejercicios, uno sin patrón:
el extracto como `record`) y `01/10` completo: 198 respuestas de capítulo, 36 de simulación y 5
ejercicios desarrollados. Las `S#` que ya eran preguntas de capítulo remiten (`Ver 02 → 25`). Deuda de
T1 hacia `01/05`, `01/06` y `01/08` cerrada con enlaces. **Comprobado**: anclas de la JLS 21 (§4.5.1,
§8.1.1.2, §8.4.8, §9.4.1.3, §15.12) descargando los capítulos; nota de la Javadoc de `Optional` ("primarily
intended for use as a method return type"); capítulos 6, 7 y 8 de Metz 2.ª ed. **Trampas nuevas:** el
verificador cuenta como aviso cualquier "pendiente" del solucionario, también en prosa ("salida
pendiente de confirmar"): se escribe "salida esperada, sin correr"; y en Java `a == b;` o `d.campo;` no
son sentencias válidas: el resultado se asigna (`boolean r = a == b;`). Los bloques que no compilan a
propósito llevan `// no compila: <motivo>` en la primera línea. Longitudes: `01/05` 361, `01/06` 385,
`01/07` 308, `01/08` 276.

**2026-10-03 · T0 y T1.** Oskar pidió trabajar T0–T5 en una sola sesión, así que el Paso 1 del
protocolo (preguntas antes de redactar) no se devolvió por separado: se asumió el valor por defecto en
todo, como en Q4–Q10. **T0**: trece carpetas y trece solucionarios en esqueleto, generados desde el
inventario del `prompt-base.md` §1; verificador con 0 errores y 13 avisos `PENDIENTE`. **T1**: `01/01`–`01/04`
y sus 100 respuestas. Fija las convenciones que heredan los demás: el diagrama de memoria (variables a
la izquierda, objetos a la derecha, flecha por referencia, regla de dibujo en `01/01` §6); el
solucionario con `**NN → P. Enunciado 🟢**` en una sola línea y las tres capas en líneas que empiezan
por su emoji; las afirmaciones sobre resultados van en comentarios del código (`// → 2`), sin `println`
ni salida pegada, y se anotan en la deuda de ejecución. **Fuentes comprobadas en la sesión**: la lista
completa de ítems de *Effective Java* 3.ª ed. (por un índice publicado), los capítulos de *A Tour of
C++* 3.ª ed. (1 "The Basics", 5 "Classes", 6 "Essential Operations", 8 "Concepts and Generic
Programming") y los ítems 17, 29 y 41 de *Effective Modern C++*; JEP 421 (entregada en 18) y JEP 513
(entregada en 25). **Trampa nueva:** `en.cppreference.com/w/cpp/...` redirige con `200` a
`en.cppreference.com/cpp/...`; se cita la URL final. **Longitud:** los cuatro capítulos quedaron entre
361 y 397 líneas, por encima de la banda de 350 de la guía §4.6 y dentro de la tolerancia del
verificador (450); el exceso son las 22–28 preguntas. Se revisa en T25 al escribir el README del
bloque.

**2026-10-03 · P8 cerrada: preparación terminada.** Con permiso de Oskar se borró
`propuesta-contenido.md`. Antes se pasó al `prompt-base.md` lo único que vivía solo en ella: la tabla
de rutas con sus capítulos (§16) y el boceto de los talleres (§18). Las decisiones D1–D24 quedan
repartidas en la guía, el `prompt-base.md` y este plan; las menciones a la propuesta y a los números
de decisión se limpiaron, salvo en esta bitácora, que es histórica. **Listo para T0**, en una sesión
nueva.

**2026-10-03 · P7, y las decisiones confirmadas.** Oskar confirmó D1–D24 una por una, con cinco
precisiones: D2 (la carpeta es `03-poo-y-patrones`), D5 (**Java 17 y 21** de trabajo, alternativa en 17
siempre; Java 25 solo en callouts), D11 (independencia aunque el repositorio público sea
`repaso-entrevistas/` entero), D18 (C# en su última versión estable) y D22 (bibliografía desde el GoF,
con los libros de patrones de cada lenguaje y cursos como material suplementario). Trasladadas a la
guía §1.2, §5.3, §10.1, §13.1 y §14, al `prompt-base.md`, a los prompts (marco y T23) y a este plan.
**P7 hecha por búsqueda web**: editorial y año de los 36 libros de §10.1 de la guía, comprobados uno
por uno en catálogos de editorial y de librería. Datos que corrigen lo que se daba por sabido:
*Effective Java* 3.ª ed. salió el 27 de diciembre de 2017 (se cita 2018, el año del copyright);
*Head First Design Patterns* 2.ª ed. figura como enero de 2021; *Node.js Design Patterns* 4.ª ed. es de
septiembre de 2025; *Design Patterns in .NET 6* es la 3.ª ed. del libro de Nesteruk. *Go Design
Patterns* (Castro Contreras, 2017) es anterior a los genéricos de Go: se cita con esa salvedad. Cursos
comprobados por búsqueda: Coursera (Alberta), los tres de Nesteruk en Udemy, la lista de Okhravi, las
charlas de Iglberger en CppCon 2021 y 2022. **Ninguna URL se comprobó por código de estado**: los
capítulos que citen una la comprueban al escribirse. **P8**: revisión cruzada hecha en la misma
sesión; solo falta borrar la propuesta, con permiso de Oskar. Después, T0.

**2026-10-03 · P1–P6.** Discutido con Oskar el temario en varias rondas y cerradas D1–D24 (registro
en `propuesta-contenido.md` §12): C++23 · Java 21 fijos; Go, JS/TS y Python en "los diferentes", C#
como inserto; niveles A/B/C; POO y diseño OO en los bloques 01–03; antipatrones en el 12; rutas de
estudio; dominio de personas y documentos con `TipoDocumento` como clase; Mermaid; repositorio
independiente. Las dudas Q4–Q10 se cerraron con la recomendación de la propuesta ("todo default"). La
carpeta se renombró de `02-patrones-diseno` a `02-poo-y-patrones`, y Oskar la movió después a `03-poo-y-patrones`; no se tocó nada fuera de ella.
Escritos guía, `prompt-base.md`, `prompts-de-fase.md`, este plan y `verificar-corpus.py`, probado
sobre `prompts/`. **No se comprobó ninguna URL ni edición de libro**: eso es P7. Siguiente: P7 y P8,
en una sesión nueva; después T0.

---

## 9. ✅ Checklist

Se marca `[x]` al cerrar cada punto. Una tanda se marca terminada en §3 solo cuando todos sus puntos lo
están.

### Preparación (`prompts/`)

- [x] P1 · `propuesta-contenido.md` con D1–D24 cerradas
- [x] P2 · `guia-de-estilo-y-convenciones.md`
- [x] P3 · `prompt-base.md`
- [x] P4 · `prompts-de-fase.md`
- [x] P5 · `plan-de-produccion.md`
- [x] P6 · `verificar-corpus.py` probado sobre `prompts/`
- [x] P7 · Edición, año y editorial de toda la bibliografía comprobados y fijados en la guía §10.1
- [x] P7 · Libros de patrones por lenguaje (C++, Java, C#, Python, JS/TS, Go) y material suplementario
- [x] P8 · Revisión cruzada de los cinco documentos (2026-10-03: decisiones confirmadas trasladadas, sin referencias viejas, verificador limpio)
- [x] P8 · Con permiso de Oskar: propuesta borrada y menciones limpias (rutas y talleres pasados al `prompt-base.md` §16 y §18)

### Antes de empezar cualquier tanda de escritura

- [x] Leídos §3, §6, §7 y §8 de este plan
- [x] Leído el prompt de la tanda en `prompts-de-fase.md`
- [x] Leídas la guía entera y las fichas de la tanda en el `prompt-base.md`
- [x] El verificador sale sin errores **antes** de empezar (si no, se arregla primero)
- [x] Las tandas de las que depende están ✅

Esta lista se recorre al empezar **cada** tanda; marcada por última vez en la sesión de T21–T25
(2026-10-03).

### T0 — Arranque

- [x] Trece carpetas de bloque con los nombres del inventario
- [x] Trece solucionarios en esqueleto

### T1 — Bloque 01, primera mitad

- [x] `01/01` Identidad, estado y referencias
- [x] `01/02` Igualdad, identidad y hash
- [x] `01/03` Inmutabilidad y objetos especiales
- [x] `01/04` Copia, ciclo de vida y recursos
- [x] Respuestas en `01/10` · verificador limpio · deudas anotadas

### T2 — Bloque 01, segunda mitad

- [x] `01/05` Polimorfismo y despacho
- [x] `01/06` Herencia vertical y horizontal
- [x] `01/07` Genéricos y varianza
- [x] `01/08` La ausencia y el error en el modelo
- [x] `01/09` Simulación de entrevista
- [x] `01/10` completo · verificador limpio · deudas anotadas

### T3 — Bloque 02, primera mitad

- [x] `02/01` UML lo justo, en Mermaid
- [x] `02/02` De la asociación al código
- [x] `02/03` Navegabilidad y coherencia
- [x] `02/04` Agregación, composición y propiedad
- [x] Respuestas en `02/09` · verificador limpio · deudas anotadas

### T4 — Bloque 02, segunda mitad

- [x] `02/05` Redundancia controlada
- [x] `02/06` Entidades, valores y primitivos
- [x] `02/07` Objetos frente a tablas
- [x] `02/08` Simulación de entrevista
- [x] `02/09` completo · verificador limpio · deudas anotadas

### T5 — Bloque 03

- [x] `03/01` Encapsulación de verdad
- [x] `03/02` SOLID sin catecismo
- [x] `03/03` GRASP
- [x] `03/04` Acoplamiento, cohesión y dependencias
- [x] `03/05` Diseño por contrato y *fail fast*
- [x] `03/06` Simulación de entrevista
- [x] `03/07` completo · verificador limpio · deudas anotadas

### T6 — Bloque 04, primera mitad

- [x] `04/01` Factory Method y fábricas estáticas
- [x] `04/02` Abstract Factory
- [x] `04/03` Builder
- [x] `04/04` Prototype
- [x] Respuestas en `04/09` · verificador limpio · deudas anotadas

### T7 — Bloque 04, segunda mitad

- [x] `04/05` Singleton, y por qué casi nunca
- [x] `04/06` Contenedores de inyección e IoC
- [x] `04/07` Más allá del GoF
- [x] `04/08` Simulación de entrevista
- [x] `04/09` completo · verificador limpio · deudas anotadas

### T8 — Bloque 05, primera mitad

- [x] `05/01` Adapter
- [x] `05/02` Decorator
- [x] `05/03` Proxy, y los tres que se confunden
- [x] `05/04` Facade
- [x] Respuestas en `05/09` · verificador limpio · deudas anotadas

### T9 — Bloque 05, segunda mitad

- [x] `05/05` Composite
- [x] `05/06` Bridge
- [x] `05/07` Flyweight
- [x] `05/08` Simulación de entrevista
- [x] `05/09` completo · verificador limpio · deudas anotadas

### T10 — Bloque 06, primer tercio

- [x] `06/01` Strategy
- [x] `06/02` Template Method
- [x] `06/03` Observer
- [x] `06/04` Command
- [x] Respuestas en `06/11` · verificador limpio · deudas anotadas

### T11 — Bloque 06, segundo tercio

- [x] `06/05` Chain of Responsibility
- [x] `06/06` State
- [x] `06/07` Visitor, y lo que lo reemplaza
- [x] Respuestas en `06/11` · verificador limpio · deudas anotadas

### T12 — Bloque 06, cierre

- [x] `06/08` Iterator y Mediator
- [x] `06/09` Memento e Interpreter
- [x] `06/10` Simulación de entrevista
- [x] `06/11` completo · verificador limpio · deudas anotadas
- [x] **Talleres decididos con Oskar**: aplazados; se deciden después de T22, con el corpus teórico completo

### T13 — Bloque 07, primera mitad

- [x] `07/01` Organizar la lógica de dominio
- [x] `07/02` Fuentes de datos
- [x] `07/03` Comportamiento objeto-relacional
- [x] Respuestas en `07/07` · verificador limpio · deudas anotadas

### T14 — Bloque 07, segunda mitad

- [x] `07/04` Estructura objeto-relacional
- [x] `07/05` Metadatos y consultas
- [x] `07/06` Simulación de entrevista
- [x] `07/07` completo · verificador limpio · deudas anotadas

### T15 — Bloque 08

- [x] `08/01` Presentación web
- [x] `08/02` Distribución
- [x] `08/03` Concurrencia offline
- [x] `08/04` Estado de sesión
- [x] `08/05` Patrones base
- [x] `08/06` Simulación de entrevista
- [x] `08/07` completo · verificador limpio · deudas anotadas

### T16 — Bloque 09

- [x] `09/01` Entidad, valor y agregado
- [x] `09/02` Eventos, servicios y fábricas de dominio
- [x] `09/03` Specification, Null Object y Type Object
- [x] `09/04` Simulación de entrevista
- [x] `09/05` completo · verificador limpio · deudas anotadas

### T17 — Bloque 10, primera mitad

- [x] `10/01` Inmutabilidad y confinamiento
- [x] `10/02` Esperar y coordinar
- [x] `10/03` Producer-Consumer y Thread Pool
- [x] Respuestas en `10/08` · verificador limpio · deudas anotadas

### T18 — Bloque 10, segunda mitad

- [x] `10/04` Future/Promise y Active Object
- [x] `10/05` Reactor y Proactor
- [x] `10/06` Inicialización perezosa segura (cierra la deuda de `04/05`)
- [x] `10/07` Simulación de entrevista
- [x] `10/08` completo · verificador limpio · deudas anotadas

### T19 — Bloque 11

- [x] `11/01` Go
- [x] `11/02` JavaScript y TypeScript
- [x] `11/03` Python
- [x] `11/04` Simulación de entrevista
- [x] `11/05` completo · deuda de enlaces de "en Go / JS / Python" cerrada · verificador limpio

### T20 — Bloque 12, primera mitad

- [x] `12/01` Code smells dentro de una clase
- [x] `12/02` Code smells entre clases
- [x] `12/03` Antipatrones de diseño OO
- [x] Respuestas en `12/07` · verificador limpio · deudas anotadas

### T21 — Bloque 12, segunda mitad

- [x] `12/04` El patrón mal usado
- [x] `12/05` Antipatrones de código y de proceso
- [x] `12/06` Simulación de entrevista (revisión de código en vivo)
- [x] `12/07` completo · verificador limpio · deudas anotadas

### T22 — Bloque 13

- [x] `13/01` Patrones en Spring
- [x] `13/02` Patrones en el JDK y en la STL
- [x] `13/03` Refactorizar hacia patrones, y desde ellos
- [x] `13/04` Cómo se elige
- [x] `13/05` Simulación final
- [x] `13/06` completo · **deuda de enlaces vacía** · verificador limpio

### T23 — Revisión técnica de C++ y Java

- [x] Permiso de Oskar para Docker
- [x] Versiones de GCC y JDK 17, 21 y 25 fijadas y anotadas
- [x] Bloques 01–10, 12 y 13 compilados y ejecutados
- [x] Todos los diagramas Mermaid renderizados con `mermaid-cli`
- [x] `Versiones ejecutadas:` en cada capítulo verificado
- [x] Deuda de ejecución de C++ y Java vacía o justificada

### T24 — Revisión técnica de los secundarios

- [x] Permiso de Oskar para Docker
- [x] Versiones de Go, Node, TypeScript, Python y .NET fijadas y anotadas
- [x] Bloque 11 y todos los insertos compilados o ejecutados
- [x] Deuda de ejecución vacía o justificada

### T25 — Cierre

- [x] `README.md` del corpus, con las rutas recalibradas y las versiones
- [x] `README.md` de los trece bloques
- [x] Verificador sin errores en todo el corpus, rutas incluidas
- [x] Literalidad de los trece solucionarios comprobada
- [x] URLs externas verificadas por código de estado
- [x] Misma `Vigencia:` en todo el corpus, o la diferencia justificada
- [x] Este plan: Oskar decidió conservarlo (2026-10-03), así que no se borra ni se limpian sus menciones

### T26 — Talleres

- [x] Permiso de Oskar para Docker (dado el 2026-10-04 para cerrar el curso)
- [x] Reglas y plantilla en §13.2 de la guía; fichas en §18 del `prompt-base.md`; prompt en `prompts-de-fase.md`
- [x] Verificador extendido a talleres
- [x] `laboratorio/legado/` corrido, con sus defectos comprobados
- [x] `14/01` Caracterización, con `estados/01`
- [x] `14/02` Igualdad, hash e inmutabilidad, con `estados/02`
- [x] `14/03` Partir el God Object, con `estados/03`
- [x] `14/04` Strategy y State, con `estados/04`
- [x] `14/05` Chain y Decorator, con `estados/05`
- [x] `14/06` Eventos y bloqueo optimista, con `estados/06`
- [x] `14/07` completo, con los ejercicios corridos
- [x] `14-talleres/README.md` y el `README.md` del corpus al día · verificador limpio · URLs comprobadas

