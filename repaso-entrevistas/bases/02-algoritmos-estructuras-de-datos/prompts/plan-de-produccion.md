# 🗓️ Plan de producción: tandas, estado y checklist

Este documento dice **en qué orden se prepara y se escribe el corpus, cuándo una tanda está terminada
y dónde va la producción**. Hay tres fases: la **preparación** (`P1`–`P8`), que solo toca `prompts/`;
la **escritura** (`T0`–`T38`), que no empieza hasta que la preparación esté cerrada; y la **pasada de
verificación** (`TV`), que corre todo el código y comprueba todos los enlaces al final, como decidió
Oskar. Es operativo: se actualiza al cerrar cada sesión, y **cualquier sesión que retome
`02-algoritmos-estructuras-de-datos/` empieza leyendo §3 (estado), §8 (bitácora) y §9 (checklist)**.

- La forma la manda [`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md).
- El contenido lo manda [`prompt-base.md`](prompt-base.md).
- La entrada de cada tanda es el prompt de §5.
- **El orden lo manda este documento.**

> **Caducidad:** es un documento de producción. Al cerrar el corpus se conserva en `prompts/` como
> referencia —`prompts/` no viaja al repositorio público—, salvo que Oskar pida borrarlo. No se cita desde
> ningún capítulo ni README.
>
> **Vigencia:** 2026-10-05.

**Salto rápido:** [1](#1--las-reglas-de-orden) · [2](#2--qué-es-una-tanda) · [3](#3--estado) · [4](#4--las-verificaciones) · [5](#5--el-prompt-de-una-tanda) · [6](#6--deuda-de-enlaces-abierta) · [7](#7--deuda-de-ejecución) · [8](#8--bitácora) · [9](#9--checklist) · [10](#10--directorios-de-zz-code)

---

## 1. 🧭 Las reglas de orden

Las tandas van por **dependencia conceptual**, y cada una deja el corpus coherente y publicable.

1. **La escritura no empieza con la preparación abierta.** `T0` exige `P1`–`P8` cerradas.
2. **Ninguna tanda se cierra con el solucionario desactualizado.** Las preguntas y las pistas 2 y 3 de
   los problemas de la tanda entran en el `NN-respuestas.md` de su bloque en la misma tanda.
3. **Un bloque se cierra con su simulación.** La tanda que escribe el último capítulo de un bloque
   escribe también su simulación y deja el solucionario completo.
4. **Ningún enlace interno apunta a un documento que no existe.** La referencia va en prosa y se anota
   en la deuda de enlaces (§6); la tanda que escribe el destino la convierte en enlace.
5. **Ninguna salida se publica como real sin corrida.** Se marca `salida esperada, sin correr` y se
   anota en la deuda de ejecución (§7), que vacía `TV`.
6. **Todo enlace nuevo se comprueba una vez al escribirlo**, con el método de su plataforma (§9.4 de la
   guía), y otra vez en `TV`.
7. **Los README de bloque y el del corpus definitivo se escriben al final** (`T37`). Hasta entonces, el
   mapa es la tabla de §3 y el README del corpus es el esqueleto de `T0`.
8. **Todo en el hilo principal, secuencial y sin agentes**, y sin commits: git lo hace Oskar.
9. **Nada se instala en la máquina sin permiso de Oskar.** `TV` usa las herramientas locales de §5.3
   de la guía.
10. **Nunca se borra un directorio.** Si algo sobra, se le pregunta a Oskar.

**Prioridad si una entrevista aprieta:** las tandas con capítulos de las rutas cortas van primero —`T1`,
`T2`, `T3`, `T4`, `T5`, `T6`, `T7`, `T9`, `T10`, `T11`, `T13`, `T16`, `T18`, `T19`, `T23`, `T24`, `T34`—,
saltando dentro de cada una los capítulos que no son de ruta corta. Como esos capítulos se escriben
autocontenidos (§13 de la guía), el salto no los rompe; lo que falte va en prosa y a la deuda de
enlaces.

---

## 2. 📦 Qué es una tanda

### 2.1 Una tanda de preparación

Un documento de `prompts/`, o un paso que lo deja coherente con los demás. **No crea ni toca nada fuera
de `prompts/`.** Terminada cuando sus anclas están bien y los documentos que la citan están al día.

### 2.2 Una tanda de escritura

Un grupo de capítulos que se enlazan entre sí, **su parte del solucionario**, la simulación si cierra el
bloque, y las comprobaciones de §4. La rutina, igual en todas:

1. Pegar el prompt de §5 con el número de la tanda.
2. Leer la guía entera (la primera vez de la sesión) y las fichas de la tanda en el `prompt-base.md`.
3. Comprobar libro y capítulo de la lectura troncal, y cada URL o problema, **antes** de escribirlos.
4. Escribir en el orden en que los capítulos se enlazan; después de cada uno, sus respuestas y sus
   pistas 2 y 3 en el solucionario.
5. Recorrer el checklist de §15 de la guía **al cerrar cada archivo**.
6. Resolver la deuda de enlaces que la tanda cierra; anotar la nueva y la de ejecución.
7. Correr el verificador (§4), cuando exista (`P6`).
8. Actualizar §3, §6, §7, §8 y §9 de este documento.

### 2.3 La pasada de verificación (`TV`)

Sigue §14 de la guía: compila y corre toda plantilla A y B con *stress test*, corre los ejemplos
trabajados y las trazas, valida cada problema propio con una solución de referencia que no se publica, y
comprueba todos los enlaces. Terminada cuando la deuda de ejecución está vacía o cada fila restante
tiene su motivo escrito en el capítulo, y el README del corpus tiene la fecha de la corrida y las
versiones.

---

## 3. 📊 Estado

Leyenda: ⬜ pendiente · 🟡 en curso · ✅ terminada.

| Tanda | Entrega | Estado |
|---|---|---|
| **P1** | Propuesta de contenido: temario, niveles, rutas, plataformas y decisiones (borrada en P8) | ✅ |
| **P2** | `guia-de-estilo-y-convenciones.md` | ✅ |
| **P3** | Versiones de los jueces y herramientas locales, fijadas en la guía §5.3 | ✅ |
| **P4** | `prompt-base.md`: 122 fichas, simulaciones, bloques 21–23, rutas | ✅ |
| **P5** | Este plan | ✅ |
| **P6** | `verificar-corpus.py`, probado sobre `prompts/` | ✅ |
| **P7** | Ediciones, años y capítulos de la bibliografía (guía §11.1 y lecturas troncales del `prompt-base.md`) | ✅ |
| **P8** | Revisión cruzada; propuesta borrada con permiso de Oskar | ✅ |
| **T0** | 23 carpetas, 20 solucionarios en esqueleto, README del corpus en esqueleto | ✅ |
| **T1** | `01/01`–`01/04` | ✅ |
| **T2** | `01/05`–`01/07`, simulación `01/08`, `01/09` completo | ✅ |
| **T3** | `02/01`–`02/03` | ✅ |
| **T4** | `02/04`–`02/06`, simulación `02/07`, `02/08` completo | ✅ |
| **T5** | `03/01`–`03/03` | ✅ |
| **T6** | `03/04`–`03/06`, simulación `03/07`, `03/08` completo | ✅ |
| **T7** | `04/01`–`04/05`, simulación `04/06`, `04/07` completo | ✅ |
| **T8** | `05/01`–`05/03` | ✅ |
| **T9** | `05/04`–`05/05`, simulación `05/06`, `05/07` completo | ✅ |
| **T10** | `06/01`–`06/04`, simulación `06/05`, `06/06` completo | ✅ |
| **T11** | `07/01`–`07/04` | ✅ |
| **T12** | `07/05`–`07/07`, simulación `07/08`, `07/09` completo | ✅ |
| **T13** | `08/01`–`08/04`, simulación `08/05`, `08/06` completo | ✅ |
| **T14** | `09/01`–`09/03` | ✅ |
| **T15** | `09/04`–`09/06`, simulación `09/07`, `09/08` completo | ✅ |
| **T16** | `10/01`–`10/03` | ✅ |
| **T17** | `10/04`–`10/06`, simulación `10/07`, `10/08` completo | ✅ |
| **T18** | `11/01`–`11/04`, simulación `11/05`, `11/06` completo | ✅ |
| **T19** | `12/01`–`12/03` | ✅ |
| **T20** | `12/04`–`12/06`, simulación `12/07`, `12/08` completo | ✅ |
| **T21** | `13/01`–`13/04` | ✅ |
| **T22** | `13/05`–`13/07`, simulación `13/08`, `13/09` completo | ✅ |
| **T23** | `14/01`–`14/03` | ✅ |
| **T24** | `14/04`–`14/06`, simulación `14/07`, `14/08` completo | ✅ |
| **T25** | `15/01`–`15/04` | ✅ |
| **T26** | `15/05`–`15/07`, simulación `15/08`, `15/09` completo | ✅ |
| **T27** | `16/01`–`16/04` | ✅ |
| **T28** | `16/05`–`16/08`, simulación `16/09`, `16/10` completo | ✅ |
| **T29** | `17/01`–`17/04` | ✅ |
| **T30** | `17/05`–`17/08` | ✅ |
| **T31** | `17/09`–`17/11`, simulación `17/12`, `17/13` completo | ✅ |
| **T32** | `18/01`–`18/06`, simulación `18/07`, `18/08` completo | ✅ |
| **T33** | `19/01`–`19/06`, simulación `19/07`, `19/08` completo | ✅ |
| **T34** | `20/01`–`20/05`, simulación `20/06`, `20/07` completo | ✅ |
| **T35** | Bloque `21`: 16 simulacros, `17-pistas.md` y README | ✅ |
| **T36** | Bloque `22` (opcional): 6 capítulos, solucionario y README | ✅ |
| **T37** | README de los bloques `01`–`21` y README del corpus definitivo | ✅ |
| **T38** | Bloque `23` (opcional): los 5 cuadernos generados y su README | ✅ |
| **TV** | Pasada de verificación (§2.3) | ✅ |
| **TC** | Cierre: verificadores limpios, literalidad comparada, casos de borde, `zz-code/` archivado | ✅ |

**Total del corpus:** en el hilo principal, 122 capítulos, 20 simulaciones, 20 solucionarios, 17
documentos del bloque `21`, 21 README de bloque y el README del corpus (**201 documentos**); en los
opcionales, 6 capítulos, 1 solucionario, 5 cuadernos y 2 README (**14**).

---

## 4. 🔍 Las verificaciones

Al cerrar cada tanda de escritura. **Desde `P6`, una sola orden** desde la raíz del corpus:

```bash
python3 prompts/verificar-corpus.py                    # todo el corpus
python3 prompts/verificar-corpus.py 12-dp-clasica      # solo un bloque
```

- Lo que comprueba está en §12.4 de la guía: enlaces internos y anclas, que nada salga del corpus,
  conteos de preguntas y de problemas contra el solucionario, bandas, emojis de `###`, callouts y rutas.
- Separa errores de avisos y sale con código distinto de cero si hay errores.

**Hasta `P6`**, las anclas se comprueban con un script provisional del *scratchpad*, que no se publica.

**Lo que no comprueba el verificador**, y se hace a mano:

- **URLs externas**, en serie y con encabezado de navegador:

  ```bash
  curl -s -o /dev/null -w '%{http_code} %{url_effective}\n' -L -A 'Mozilla/5.0' '<URL>'
  ```

  - `-o /dev/null` descarta el cuerpo, y `-w` imprime el código final y la URL donde se aterrizó.
  - `-L` sigue las redirecciones, porque aterrizar en la portada **cuenta como roto** aunque el código
    sea `200`.
  - `-A` manda un agente de navegador, porque algunos sitios responden `403` a `curl`.
- **Enlaces de problemas**, con el método de su plataforma (guía §9.4): API, `404` real, repositorio,
  título de la página o navegador.
- **La literalidad** de los enunciados en el solucionario: el verificador cuenta, no compara texto.

---

## 5. 📝 El prompt de una tanda

Es el mismo para todas las tandas de escritura; solo cambia el número. Se pega al empezar la sesión:

```text
Retoma el corpus repaso-entrevistas/bases/02-algoritmos-estructuras-de-datos/.
Tanda: T<N>.

1. Lee prompts/plan-de-produccion.md: §3, §6, §7, §8 y la sección de T<N> en §9.
2. Lee prompts/guia-de-estilo-y-convenciones.md entera y las fichas de la tanda en
   prompts/prompt-base.md.
3. Escribe los documentos de la tanda en orden, con su parte del solucionario
   (preguntas en tres capas, pistas 2 y 3), comprobando antes cada libro, URL y problema.
4. Recorre el checklist de §15 de la guía en cada archivo.
5. Anota la deuda de enlaces y de ejecución, actualiza §3, §8 y §9 del plan.
Secuencial, sin agentes, sin commits, sin instalar nada.
```

**Las tandas especiales:**

- **`T0`** crea las 23 carpetas con los nombres del inventario del `prompt-base.md` §1, los 20
  solucionarios con sus encabezados `# NN — Tema` y nada más, y un README del corpus en esqueleto con la
  tesis, el mapa y las rutas, marcado «en producción». Ningún enlace a capítulos que no existen.
- **`T35`** escribe los simulacros con problemas que no aparecen en ningún otro sitio del corpus.
- **`T37`** escribe los README de bloque (§7.4 de la guía) y reescribe el del corpus.
- **`T38`** genera los cuadernos a partir de las plantillas de los capítulos, y escribe las plantillas
  A en Go y en JavaScript, por decisión de Oskar.
- **`TV`** sigue §2.3 y §14 de la guía; antes, comprueba que las herramientas de §5.3 siguen ahí.
- **`TC`** corre el verificador del corpus y el base de `zz-instrucciones/` (perfiles `repaso` y
  `publicacion`), compara la literalidad de los solucionarios, deja `zz-code/` sin directorios *vigentes* y
  conserva este plan en `prompts/` como referencia.

---

## 6. 🧾 Deuda de enlaces abierta

Cada mención en prosa que espera a que exista su destino. Formato: origen → destino → tanda que la
cierra.

Las referencias en prosa `NN/MM` cuyo destino ya existe se convierten en enlace al cerrar cada tanda (la
primera mención de cada documento y todos los pies). La tabla se regenera con `deuda.py` y
`tabla_deuda.py` del *scratchpad*; los `NN/MM` que acaban en solucionario o simulación son esos
documentos (`01/09`, `02/08`, `03/08`, `04/07`, `05/07`, `06/06`, `07/09`, `08/06`, `09/08`).
Regenerada al cerrar T36 (2026-10-04): **no queda ninguna deuda abierta.** T36 cerró las dos últimas
(`16/07` y `16/10` → `22/01`; `14/05` y `14/08` → `22/04`) y enlazó la mención al bloque `22` de `10/05` con su
README. `deuda.py` confunde con referencias las fracciones entre acentos graves (`35/12`, `49/40`, `91/36`); se
descartan a mano.

| Origen | Destino pendiente | La cierra |
|---|---|---|
| — | — | — |

---

## 7. ⏳ Deuda de ejecución

Cada salida marcada `salida esperada, sin correr` y cada bloque marcado `no compila` o `falla`, a
confirmar en `TV`. Formato: capítulo → sección → qué confirmar.

**Vaciada en `TV` el 2026-10-04** (ver §8): de las 48 filas que había, de `01/04` a `23/05`, 46 se corrieron
enteras y se borraron de aquí; lo que cambió en el corpus está en la bitácora. Quedan dos, que no se pueden cerrar
desde esta máquina y llevan su motivo escrito donde se leen:

| Capítulo | Sección | Qué confirmar | Dónde está el motivo |
|---|---|---|---|
| `03/02` | §8 | Que el `ordered_set` de PBDS compila en LeetCode (exige un envío a la plataforma) | `03/02` §8 y el README del corpus |
| `21/01`–`21/16` | problemas externos | Resolver cada problema externo de los simulacros en su plataforma para confirmar las pistas 2 y 3 | Encabezado de `21/17` y el README del corpus |

---

## 8. 📓 Bitácora

Una entrada por sesión, la más reciente arriba: qué se cerró, qué quedó a medias y por qué, qué se
comprobó y cómo, y las trampas que la próxima sesión debe conocer.

**2026-10-05 · Diagramas a Mermaid (revisión posterior al cierre; secuencial, sin agentes).** Pedido de Oskar:
«que los diagramas se hagan todos en Mermaid», según `zz-instrucciones/` (Mermaid en un curso solo a pedido
explícito del autor). Inventario de los 930 bloques `text` del corpus: **106 diagramas** pasados a Mermaid en cuatro
lotes, incluidos todos los dudosos que Oskar eligió: 22 de estructura (árboles, grafos, flujos, conjuntos P/NP, la
reducción de 3-SAT), 32 decisiones de varios niveles, 32 de un nivel y los 20 «Orden de lectura» de los README de
bloque (una arista por «asume»; la simulación al final). Siguen en `text` las trazas, los arreglos, las tablas, las
rejillas, la E/S y las listas planas `¿…? → X` (`03/02`, `03/03`). Los bloques mixtos quedaron en dos: Mermaid y
debajo su `text`. **Guía:** regla en §3 («Diagramas» y «Convenciones de Mermaid»), §5.6 (G y T en Mermaid), §6.1,
§10.1, §15 y nota en el encabezado (no cuenta como divergencia: la madre hizo lo mismo). **Comprobado:** cada lote
dibujado a PNG con `mmdc` 12.0.0 y revisado a ojo; los 94 archivos con Mermaid dibujan sin error; verificador 0
errores. **Trampas:** dentro de un `subgraph` Mermaid reordena los hermanos (quedó en la guía: árboles ordenados sin
subgrafos, con `&` y nodo título); los `<br/>` manuales en etiquetas de arista parten mal, Mermaid ya ajusta.
**Arreglado de paso:** el título de `15/03` en el README del bloque 15 decía «A\ y heurísticas» (se había perdido el
`*`). **Queda:** `10/05` pasó de 700 a 701 líneas (aviso PARTIR del verificador), a decisión de Oskar.
Código en `zz-code/02-algoritmos-20261005-fd37/` (§10).

**2026-10-05 · TC (sesión 8503f1dc; secuencial, sin agentes).** **Corpus cerrado.** Pedido de Oskar: «termina la
TC y verifica lineamientos contra `zz-instrucciones/`». **Decisiones de Oskar sobre los hallazgos de TV:** (1) añadir
un caso de borde a cada problema propio con un solo caso; (2) `20/04` se queda sin «La plantilla» (es oficio de
pruebas de empresa, no plantilla de cuaderno); (3) `11/04` no cambia: el texto solo afirma lo que encontró la
búsqueda aleatoria. **Hecho:** (a) **anclas** — `verificar-corpus.py` calculaba el ancla con `isalnum()`, que no
borra los superíndices ni conserva el U+FE0F de `⏱️`; con la regla de GitHub (`\p{Word}`, comprobada con Ruby y
con 0 diferencias frente a `verificador_base.py` en 19 001 encabezados) salieron 117 enlaces rotos (102 a
`⏱️ La tabla de costes` y al mapa y las rutas del README, 9 con `10⁸`, `2⁶¹` y `n²`, 6 en `prompts/`): corregidos con
`--corregir-fe0f` y a mano; la guía §6.3 tenía el ejemplo equivocado y se corrigió; el `slug` de `t38/extrae.py`
también, y los cuadernos regenerados salen idénticos. (b) **Literalidad** de los 21 solucionarios y `21/17`,
uniendo las líneas de continuación: 3 723 enunciados y listas de problemas; 14 preguntas truncadas en su primera
línea (sin emoji de dificultad) y 5 con un enlace que el capítulo no tiene, corregidas; el verificador del corpus
no lo veía porque solo cuenta. (c) **Orden** de las preguntas de `15/03` (la 3 🟡 y la 4 🟢, intercambiadas en
capítulo y solucionario). (d) **Casos de borde** en 132 problemas (el 133.º, «La mesa sin conocidos», ya tenía
dos con la cabecera «Una salida válida»): entrada elegida a mano, salida de la referencia de TV, 824/824 casos
correctos; «Calendario compacto» con una referencia exacta por unión de intervalos (la de TV es fuerza bruta).
`11/02` quedó en 700 líneas recortando ese caso a una consulta. (e) Plan alineado con `zz-instrucciones`: el plan
se conserva, §10 de `zz-code/`, checklist de TC de la plantilla; README del corpus con el cierre. **Comprobado:**
`verificar-corpus.py` 0 errores y 28 avisos (las longitudes aceptadas, más `02/04` 605, `04/01` 615 y `09/03` 601,
que pasan de 600 por los casos nuevos, y `17/10` 305, ficha C con banda 150–300); `verificador_base.py --perfil=repaso` y `--perfil=publicacion`, 0 errores
(5 avisos: `⏱️` como callout y «pendiente» de una recta, permitidos por la guía); arneses de TV `ej*.py` y `b*.py`
(41, con JDK 21): todos en verde, así que las claves por línea siguen valiendo. **Lecciones subidas** a `zz-instrucciones/03-lecciones-de-produccion.md` §8 (superíndices y enunciados
truncados). **Recursos levantados:** ninguno (no se usó Docker). **`zz-code/`:** `02-algoritmos-20261005-d2f3/`
creado; al cerrar, Oskar borró los tres directorios del corpus (§10). **Efímero:** el *scratchpad* de las
sesiones fe66eed2, 0262b6fd, 3887b6be y 8503f1dc, borrado por Oskar. **Siguiente:** commit de
Oskar; E9 (publicar) cuando él lo decida.

**2026-10-04 · TV (sesión 3887b6be, continuación; secuencial, sin agentes).** **Pasada de verificación
cerrada.** Herramientas de la guía §5.3 comprobadas: GCC 16.2.0, Zulu 21.0.12, CPython 3.13.4 (y la gramática de
3.12 en los 262 bloques Python), Go 1.27.1, Node 24.21.0. **Corrido:** las 239 secciones de plantilla A y B en
cada lenguaje en que existen, contra *stress test* (unos 208 000 casos; uniformidad en las aleatorizadas,
juez por tuberías en las interactivas); las dos versiones de cada ejemplo trabajado (139 bloques sueltos) y unas
334 trazas y cifras del texto; los 403 problemas propios (692 casos de ejemplo, 692 correctos) contra
referencias no publicadas; los 1 509 enlaces con el método de su plataforma; las pruebas Go y JS de `23/04`–`23/05`.
**Cambios al corpus** (lista completa en `estres/CAMBIOS.md`): tres versiones ingenuas que fallaban (`06/03`
`growNaive`, `11/01` `smallestAfterRemoving` con NPE, `18/01` `collinearNaive` con puntos repetidos); `Pre: k >= 1`
en `topK` de `08/02`; el comentario de `WeightedDSU` en `08/04`; `import` y dependencias (`// gcd de 17/02`,
`// powMod de 17/03`) en diez bloques Java; dos `#include` y los alias de seis plantillas C++; las trazas de `√2`
(`05/04`) y del 2-SAT (`14/05`); la precisión de la FFT (`17/09` y `17/13`), medida de nuevo; la medida de caché de
`02/05`; los nombres de AtCoder y dos enlaces de documentación; las marcas «sin correr» de `01/04`, `01/05` y
`03/06`; `03/02` §8 y el encabezado de `21/17` dicen lo que no se pudo comprobar. Cuadernos `23/01`–`23/03`
regenerados; README del corpus con la sección «La pasada de verificación». Verificador: 0 errores, 24 avisos (las
longitudes ya aceptadas). **Deuda que queda** (§7): PBDS en LeetCode y los externos de `21`. **Hallazgos para
TC, sin tocar:** (1) 133 problemas propios traen un solo caso de ejemplo y §9.1 de la guía pide dos, uno de
ellos de borde; (2) el código de `20/04` vive bajo «Cómo va» sin un «La plantilla», así que el extractor de los
cuadernos no lo recoge (se probó igual); (3) en `11/04` la búsqueda propia con `n ≤ 9` no encontró un
contraejemplo menor que el del texto, que solo afirma eso. **Código intermedio:** `zz-code/02-algoritmos-20261004-fbe3/`
(*vigente*, con su `MANIFIESTO.md`): extractor y compilación, enlaces, referencias de los propios y los arneses
`estres/b*.py` y `ej*.py`, todos en verde al cerrar. **Siguiente:** TC.

**2026-10-04 · T36–T38 (sesión 3887b6be, secuencial, sin agentes).** **Escritura cerrada.** **T36:** bloque
`22` completo: seis capítulos (433–659 líneas), solucionario `22/07` (74 preguntas en tres capas y las pistas de 4
propios y 6 externos) y README; cerradas las dos últimas deudas de enlaces (`16/07`, `16/10` → `22/01`; `14/05`,
`14/08` → `22/04`) y la mención de `10/05`. La ficha de `22` en el `prompt-base.md` pasó de un nivel por capítulo a
niveles por sección (las secciones que son teoremas sin algoritmo bajan a B o C; un ejemplo trabajado por sección
A) y se declaró que solo `22/02` y `22/06` llevan problemas. **T37:** los 20 README de bloque `01`–`20`, generados
con `t37/gen_readme.py` desde los encabezados de cada capítulo (niveles, «Ruta corta», «Asume leído», lectura
troncal y las dos primeras filas de cada tabla de señales) y con el texto propio de cada bloque en `t37/manual.py`;
navegación añadida a los README de `21` y `22`; README del corpus definitivo: sin «en producción», así que el
verificador comprueba ya las rutas en modo estricto (todas pasan), horas recalibradas (Refrescamiento teórico ~50,
Arquitecto ~35; también en el §27 del `prompt-base.md`). **T38:** los cinco cuadernos y su README: C++, Java y
Python generados de los capítulos con `t38/gen_cuad.py` (233, 227 y 125 plantillas); Go y JavaScript escritos y
probados (123 A cada uno, ver §7). **Comprobado:** todo el código nuevo de `22` compilado y ejecutado (g++-16 con
`-fsanitize=undefined` en `22/06`, Zulu 21, Python 3.13), con fuerza bruta donde se podía; los enlaces externos
nuevos (cp-algorithms 2-SAT, el ancla `#writing-a-tokenizer` de `re`, seis problemas de LeetCode con
`isPaidOnly: false`). Verificador: 0 errores y 24 avisos (las 23 longitudes ya aceptadas y `22/06`, 659 líneas,
declarada en el README de `22`). **Hallazgos:** (1) `verificar-corpus.py` excluía `20/01`
(`01-ad-hoc-y-simulacion.md`) de todas las comprobaciones porque buscaba la subcadena «simulacion»; ahora compara
el nombre exacto (`NN-simulacion.md`) y `20/01` pasa limpio. (2) La tabla de §6 tenía restos de una versión
anterior pegados debajo; limpiada. (3) En el README de `03`, `SortedList` no está en los jueces: la señal dice
«en Python no hay». (4) La plantilla Python del parser de `22/06` se redujo a la línea de la división para no
pasar de 700 líneas. **Código intermedio:** `zz-code/02-algoritmos-20261004-9436/` (estado *vigente*, con su `MANIFIESTO.md`): los generadores de `22/07`, de los README y de los cuadernos, y los fuentes Go y JavaScript con sus pruebas; regenerar desde ahí da los cuadernos idénticos (comprobado por suma MD5). Lo efímero (binarios de los arneses, cálculos sueltos) quedó en el *scratchpad* de la sesión. **Siguiente:** TV (pasada de verificación), y después TC.

**2026-10-04 · T31–T35 (sesión 0262b6fd, continuación; secuencial, sin agentes).** Bloque `17` cerrado
(`17/09`–`17/12` y su solucionario completo), bloques `18`, `19` y `20` completos con sus simulaciones y
solucionarios, y el bloque `21` entero: 16 simulacros, `17-pistas.md` y su README. Verificador: 0 errores y 23
avisos (longitudes de capítulos anteriores). **Comprobado:** Java 21 (sdkman, `sdk use java 21.0.8-zulu` solo
en la shell; el `current` sigue en 17.0.16) compila todos los bloques Java de `10`–`17` con las mismas salidas;
plantillas de `18`–`20` con `g++-16 -std=c++20` y Zulu 21, varias con *stress test*; enlaces externos nuevos
por su método. **Hallazgos:** (1) 15 filas de tabla en 13 archivos tenían `|` sin escapar dentro de código y
rompían la tabla en GitHub (`17/02`, `17/07`, `15/03`, `16/05`…): escapadas como `\|`. (2) La guía pide 5–8
filas de errores frecuentes; 15/07, 16/08 y 17/09–17/11 tenían 4 (corregidos); 07/07, 08/03, 09/01, 09/04 y
09/06, anteriores a esta sesión, siguen con 4. (3) El contraejemplo de `atan2` depende de la libm: se eligió uno
que falla en Java y en Python. (4) Kattis «Simple Polygon» es «¿es simple?» con `n ≤ 40 000` (va en `18/05`).
(5) Codility solo tiene tres lecciones sin usar en el corpus (Brackets, Flags, MaxNonoverlappingSegments):
los simulacros `06`–`08` llevan una cada uno y el resto de LeetCode y HackerRank con reglas de Codility.
(6) Las páginas de problemas de Codeforces responden `403`: los concursos del bloque `21` son AtCoder Beginner
Contest, cuyos enunciados se leen sin navegador. (7) Trampa de zsh: `for a in "x y"; ./prog $a` no parte
palabras (argv vacío y *segfault*): `${=a}`. **Siguiente:** T36 (bloque `22`, opcional) o T37 (README de los
bloques `01`–`21` y del corpus).

**2026-10-04 · T16–T30 (sesión 0262b6fd, secuencial, sin agentes).** Bloques `10`–`16` completos y
`17/01`–`17/08`: 80 capítulos, 7 simulaciones y sus solucionarios (el de `17/13` queda abierto hasta T31).
Verificador: 0 errores y 24 avisos (longitudes 600–700 y rutas pendientes). **Comprobado:** problemas
externos por plataforma como en T6–T15, más CodinGame por su API (`Puzzle/findProgressByPrettyId`, con
`detailsPageUrl`), Project Euler por título (`/problem=N` responde 302 si no existe), y Library Checker
por el listado de GitHub. Trazas y muestras de los propios calculadas con Python antes de escribirlas,
casi todas contra fuerza bruta; plantillas Python probadas, y desde el bloque `14` también C++ (`clang++
-fsyntax-only` con sus propios `#include` y ejecución local de muchas) y Java (JDK 17 del `PATH`): ver §7.
**Hallazgos y correcciones:** (1) cp-algorithms **no tiene** páginas de *digit DP*, Aliens, *slope trick*,
las flores de Edmonds, el árbol de dominadores ni el *eertree* (404 en varias grafías): `13/02` y `13/07`
toman USACO Guide como troncal, `15/07` y `16/08` los artículos originales; actualizados la guía §11.2 y las
fichas de `13/02`, `13/07`, `15/07` y `16/08`. (2) `verificar-corpus.py` daba falso aviso de «pendiente»
con «la pendiente de una recta»: ahora busca la marca (línea que solo dice «pendiente» o «pendiente de
redactar/escribir/completar»), probado en una copia. (3) «Asume leído» rompía rutas en `13/06` (`12/01`
fuera de «Matemática para competir»), `15/04` (`08/04` fuera de «Refrescamiento teórico») y `17/05`
(`17/03` fuera de «DP a fondo»): quitados. (4) `pies.py` dejaba títulos partidos entre líneas al enlazar
pies antiguos: arreglados `01/04`, `02/04`, `02/06`, `05/03`, `05/04`, `06/03`, `07/07`, `08/02`, `08/04` y
`09/05`. (5) Afirmaciones corregidas por el cálculo: el voraz de monedas de `10/06` (contraejemplo
`[1, 1, 3, 2]`), costes de `11/01`, la tabla de padres de `12/01`, el contraejemplo mínimo de la mochila 0/1
de `11/04` (dos objetos), la traza de SPFA de `15/02` y el camino de Floyd `C → F` (11 por `C A B D F`). (6)
Los ejemplos trabajados son variaciones que no resuelven problemas listados; los que se excluyeron de las
listas por eso están en las notas de cada capítulo (LC 647 y 1092 por `12/04`, Flight Discount por `15/01`,
Min Cost to Connect All Points por `15/04`, Proving Equivalences por `14/05`, Arctic Network por `15/04`,
Longest Happy Prefix y Rotate String por `16/02`, Set Mismatch y Single Number III por `17/01`, Count Sorted
Vowel Strings por `17/05`). (7) El *JDK* del `PATH` es el 17: `Math.ceilDiv` (18+) no existe; `17/02` usa
`−Math.floorDiv`. **Longitud (avisos aceptados, 600–700):** `10/01` 698, `10/02` 691, `10/05` 700, `11/02` 695,
`11/03` 699, `12/01` 627, `12/02` 644, `12/03` 700, `12/04` 621, `14/02` 700, `14/03` 698, `15/02` 607, `17/04`
687, `17/05` 636. **Desviaciones declaradas:** en `14/02`, `14/03`, `15/06` y `16/07` algunas plantillas Java
(o C++ y Java) se describen como «la de §N con cambios» para no pasar de 700 líneas; las fichas C (`15/07`,
`16/08`) llevan práctica solo 💀. **Trampas nuevas:** (1) comprobar el nombre de la carpeta del bloque con
`ls` antes de escribir: se creó por error `15-grafos-con-pesos-y-flujos/` (la buena es
`15-grafos-pesos-y-flujos/`); el archivo se movió y la carpeta, vacía, **no se borró**: decide Oskar. (2)
Un problema no se repite en dos listas del corpus: buscarlo con `grep -rl` antes de añadirlo. (3) Los
heredocs con acentos graves, siempre con `<<'EOF'`. **Siguiente:** T31 (`17/09`–`17/12` y el solucionario
`17/13` completo).

**2026-10-04 · T6–T15 (misma sesión, secuencial, sin agentes).** Bloques `03` (resto), `04`, `05`, `06`,
`07`, `08` y `09` completos: 37 capítulos, 7 simulaciones y 7 solucionarios cerrados. **Comprobado:**
problemas externos por plataforma como en T0–T5; Library Checker es una SPA que responde 200 a cualquier
ruta, así que sus ids se verifican en el listado del repositorio `yosupo06/library-checker-problems`
(API de GitHub) y el título en su `info.toml`; SPOJ responde 403 al verificador y **no se enlaza**
(`08/03`, `09/04` y `09/06` lo declaran en su práctica externa). Los ejemplos de los problemas propios y
las trazas, calculados con Python antes de escribirlos; las plantillas de Python de varios capítulos,
probadas contra fuerza bruta (ver §7). **Hallazgos y correcciones:** (1) las plantillas de *quicksort* y
*quickselect* con Hoare tomaban el pivote aleatorio en su sitio; si caía en `hi` siendo el máximo, el corte
quedaba en `hi` y la vuelta no avanzaba (con azar termina, pero desperdicia): ahora el pivote se lleva a
`a[lo]` (`05/01`, `05/03`); (2) el Núcleo de `05/03`, `05/04`, `06/03`, `07/01` y `07/04` llevaba CSES o
Codeforces aunque las bases bastaban: movidos a Ampliación (§9.3 de la guía), con `mover.py` y
`ordenar.py`; (3) «Asume leído» rompía rutas en `05/04` (`02/04` fuera de «Desde cero»), `06/02`, `06/04` y
`07/02`: se cambió o se quitó la línea; (4) varias preguntas y ejemplos trabajados resolvían problemas
listados en la práctica (aquí o en otro capítulo del corpus): cambiados (por ejemplo, el ejemplo de la pila
monótona de `06/01` pasó a «precio con descuento» y el de la cola monótona a una DP con ventana). **Longitud
(avisos aceptados, 600–700):** `04/03` 671, `05/01` 681, `05/04` 628, `06/01` 603, `06/02` 662, `07/01` 672,
`07/02` 602, `08/01` 615, `08/02` 670. **Desviaciones declaradas:** en los capítulos avanzados (`05/05`,
`06/04`, `07/03`, `07/05`, `07/06`) el Núcleo completa con CSES, Codeforces o Library Checker porque las
bases no llegan; `07/07`, `08/03`, `09/04` y `09/06` (fichas C) llevan práctica corta o sin Núcleo, con la
razón escrita. **Trampas nuevas:** (1) `sol.py` exige que el nombre del problema en `@@ P` coincida
literal con el `###` (con sus backticks y cursivas); (2) «pendiente» como palabra suelta en un solucionario
dispara el aviso (se escribió «sin aplicar», «por visitar»); (3) los títulos de capítulos futuros citados en
prosa se comprueban contra `prompt-base.md` (se corrigieron `16/0x`, `17/xx`, `13/03`, `11/03`, `15/xx`);
(4) `reparto.py` compara con el capítulo anterior aunque sea de otro bloque. **Siguiente:** T16
(`10/01`–`10/03`).

**2026-10-04 · T0–T5 (una sesión, secuencial, sin agentes).** **T0:** 23 carpetas, 20 solucionarios
en esqueleto generados desde las fichas del `prompt-base.md` (título, blockquote, salto rápido y un
`# NN — Tema` por capítulo y simulación) y README del corpus en esqueleto con las 14 rutas; en la ruta
«Refrescamiento teórico», «Bloque `02`» se expandió a `02/01`–`02/06` para que el verificador compruebe
sus prerrequisitos, y en «Competidor» se quitó el código `20/04` (es una exclusión, no un capítulo de la
ruta). **T1–T5:** bloques `01` y `02` completos (13 capítulos, 2 simulaciones, 2 solucionarios) y
`03/01`–`03/03` con sus respuestas: unas 12 100 líneas, 54 problemas propios y 184 externos.
**Comprobado:** cada problema externo con el método de su plataforma (API de HackerRank, GraphQL de
LeetCode con `isPaidOnly: false`, `404` real en Codility, CSES, Kattis y AtCoder, API de Codeforces y
de CodeChef); cada URL de documentación por código de estado (cppreference redirige a `/cpp/…` y se cita
la URL final); los factores de crecimiento de `02/03` en el código fuente (libstdc++ ×2, `ArrayList`
×1,5 con capacidad 10, CPython 3.12 ~×1,125); los ejemplos de los problemas propios, calculados a mano
y repasados con Python en el *scratchpad* (no publicado). **Hallazgo y corrección:** la ficha de `03/03`
decía que `Arrays.sort` en primitivos es atacable; en la fuente de OpenJDK, `DualPivotQuicksort` cambia
a *heapsort* por profundidad desde **Java 14** (no está en 11 ni en 13; sí en 14, 17 y 21). Corregidos
`02/01`, `02/05`, sus respuestas, la respuesta 7 de `01/02` y la ficha de `03/03`. **Verificador:**
`solo_fichas_c` leía solo la primera línea de «Niveles» y tomaba un conjunto vacío como «solo C» (falso
aviso de longitud en `03/02`); ahora lee el campo entero y exige alguna etiqueta. **Desviaciones
declaradas:** `01/01` lleva núcleo de 6 y ampliación de 3 (la ficha decía «uno de cada base», la guía
manda 5–8); en `02/01`–`02/06` las técnicas A sin plantilla en tres lenguajes lo declaran (las fichas
fijan «ninguna» o «en Java»). **Trampas para la próxima sesión:** (1) los scripts de apoyo viven en el
*scratchpad* de la sesión `fe66eed2`: `vp.py` (verifica problemas por plataforma), `sol.py` (genera la
sección del solucionario copiando literal el enunciado; admite simulaciones con `S#`), `deuda.py`,
`linkify.py`, `pies.py` y `reparto.py` (detecta repartos 🟢🟡🟠🔴 iguales entre vecinos); (2) la palabra
«pendiente» en un solucionario dispara el aviso `PENDIENTE`; (3) nada de emoji en `###` (salió con
«💀 Por curiosidad»); (4) un callout seguido del veredicto son dos *blockquotes* seguidos: el callout va
antes de «Cuánto»; (5) de Laaksonen 3.ª ed. solo se citan los capítulos comprobados en P7 (1, 3 y los
de las fichas); (6) ningún ejemplo trabajado resuelve un problema de las listas de práctica (se cambiaron
LRU Cache e Insert Delete GetRandom en `02/06`, y `02/04` evita Movie Festival). **Retirada:**
`prompts/guia_refrescamiento_algoritmos.md` había reaparecido en `prompts/`; Oskar la borró el 04-10
(comprobado: ya no está). **Siguiente:** T6 (`03/04`–`03/06`, simulación `03/07`,
`03/08` completo).

**2026-10-03 · P6–P8, segunda revisión (antes de `T0`).** La primera sesión dio la preparación por
cerrada sin probar el verificador en el escenario de `T0`. **Hueco encontrado y corregido:** con el
README esqueleto de `T0`, que ya trae las rutas, cada código de ruta sin capítulo daba un error `RUTA …
no existe` (unos 150 hasta `T37`). Así, el punto «verificador limpio» no se podía cumplir en ninguna
tanda. Ahora, mientras el README diga «en producción», un código con ficha en el `prompt-base.md` que
aún no existe cuenta como pendiente y sale en **un solo aviso**. Un código que no tiene ficha sigue
siendo error, y con el README definitivo todo vuelve a ser error. Probado en el *scratchpad* en cuatro
casos: esqueleto limpio (0 errores, 1 aviso), errata `04/09` (error), README definitivo (errores) y
capítulo con errores sembrados (10 errores y 8 avisos, todos esperados). Comprobado también: las 122
fichas y las 20 simulaciones cuadran con las tandas de §3; las 14 rutas de §27 cuadran con las marcas
«Ruta corta: sí» de las fichas; ninguna ruta tiene un código inexistente ni metió geometría en una
ruta básica; las constantes del verificador cuadran con la guía (§4.6, §6.1, §7.3, §8.1, §8.3, §9.1,
§10.3, §13); y no queda ninguna mención a la propuesta ni a `guia_refrescamiento_algoritmos.md`, que
Oskar ya retiró. **Trampa para las tandas:** las fichas no fijan «Asume leído», solo «Se toca con».
Si un capítulo declara un «Asume leído» que alguna ruta temática no incluye, el verificador lo marca
como error. Se resuelve como manda §13 de la guía: el prerrequisito entra en la ruta, en el README y
en el §27 del `prompt-base.md` a la vez. **Preparación cerrada de verdad; siguiente: `T0`.**

**2026-10-03 · P6–P8.** **P6:** `verificar-corpus.py` escrito y probado en una copia del *scratchpad*
con errores sembrados (enlace roto, ancla, enlace fuera del corpus, emoji en `###`, sección que falta,
preguntas y pistas desincronizadas, ruta con un capítulo inexistente, geometría en ruta básica,
«asume leído» fuera de la ruta): todos detectados, sin falsos positivos. **Trampa:** los bloques de
código se quitan por líneas, porque un ` ```text ` en línea descuadra el emparejamiento de ```. **P7:**
por búsqueda web y catálogos: Brassard y Bratley (Prentice Hall, 1997; caps. 1–13 confirmados),
Laaksonen 3.ª ed. (Springer, 2024; 18 caps.), Medjedovic y otros (Manning, 2022), Mitzenmacher y
Upfal 2.ª ed. (2017; el hashing universal es el cap. 15, no el 5), Farrier (caps. 1–9 contenedores,
11–15 algoritmos), La Rocca (Bloom cap. 4, k-d cap. 9, MapReduce cap. 13), Kubica (Bloom 13, *skip
lists* 14), Goodrich 6.ª ed. (cap. 15 «Memory Management and B-Trees»), Hopcroft en español (Pearson,
2007), el dragón en español (Pearson, 2008), *EPI in Java* (2015, no 2018). Las 17 lecciones de
Codility, por código de estado. Se añadieron al canon los libros de referencia puntual que las fichas
citaban (Pólya, Engel, Bentley, Bryant, Tarjan, Navarro, Crandall, Strang, *Winning Ways*, O'Rourke y
tres artículos). **P8:** revisión cruzada hecha; pasaron a la guía los recursos libres, las plataformas
descartadas y la nota de Go. Con permiso de Oskar, propuesta borrada. **Preparación cerrada; listo
para `T0`** en cuanto Oskar retire `guia_refrescamiento_algoritmos.md` (o sin esperar, si lo dice).

**2026-10-03 · P1–P5.** Discutido con Oskar el temario en varias rondas y cerradas D1–D27 en la
propuesta. Lo que cambió el diseño: la competitiva es **el medio**, y la base son los libros de la
biblioteca; **ningún problema lleva solución publicada** (tres pistas y la IA como tutor); **todas las
pruebas al final** (`TV`); Go y JavaScript solo donde cambian el razonamiento (🔥). Escritos la guía, el
`prompt-base.md` (122 fichas) y este plan. **P3**, comprobado el mismo día: HackerRank ofrece G++ 14.2
en su opción «C++23» y **G++ 8.3 en la de «C++20»**, Java 21.0.4 y Python 3.14.2 (su página de entorno);
LeetCode, Clang 19 con libstdc++ 14, Java 25 y Python 3.14; Codility, G++ 10.3 y 13.3, Java 21 y Python
3.12 (los dos últimos responden `403` a `curl` y se comprobaron por buscador). Intersección fijada:
**C++20, Java 21, Python 3.12**. En local hay GCC 16.2 (`g++-16`, con PBDS), JDK 21 en sdkman (el `java`
del `PATH` es el 17), Python 3.13.4, Go 1.27.1 y Node 24.21; PyPy no está. Plataformas probadas: ver la
guía §9.4. **Trampas:** Coderbyte, SPOJ, Project Euler y LeetCode responden `403` a `curl`; Acepta el
reto, Jutge, eolymp, Timus y USACO responden `200` a todo y se verifican por título. **Siguiente:** P6, en
una sesión nueva.

---

## 9. ✅ Checklist

Se marca `[x]` al cerrar cada punto. Una tanda se marca terminada en §3 solo cuando todos sus puntos lo
están. **Para saber dónde estás: el primer `[ ]` de esta sección.**

### Preparación (`prompts/`)

- [x] P1 · Propuesta discutida; D1–D27 cerradas
- [x] P2 · `guia-de-estilo-y-convenciones.md`
- [x] P3 · Versiones de HackerRank, LeetCode y Codility; herramientas locales; guía §5.3
- [x] P4 · `prompt-base.md` con 122 fichas, simulaciones, bloques 21–23 y rutas
- [x] P5 · `plan-de-produccion.md`
- [x] P6 · `verificar-corpus.py` escrito
- [x] P6 · Probado sobre `prompts/` y con errores sembrados (9 errores y 8 tipos de aviso detectados; sin falsos positivos)
- [x] P7 · Ediciones, años y editoriales del canon (guía §11.1) comprobados
- [x] P7 · Capítulos de las lecturas troncales comprobados (Brassard y Bratley, Laaksonen 3.ª ed., Farrier, La Rocca, Kubica, Goodrich, Mitzenmacher); CLRS 3.ª ed. por su índice
- [x] P7 · Los *verificar* del `prompt-base.md` resueltos; `13/02` y `13/07` declarados sin libro del canon (guía §11.2)
- [x] P8 · Revisión cruzada de guía, `prompt-base.md` y plan: ninguna decisión vive solo en la propuesta
- [x] P8 · Con permiso de Oskar: propuesta borrada y menciones limpias (2026-10-03)
- [x] P6 · Rutas del README esqueleto: con el README «en producción», un capítulo con ficha que aún no existe es un solo aviso, no un error; probado en el *scratchpad* (2026-10-03, segunda revisión)
- [x] P8 · `guia_refrescamiento_algoritmos.md` retirada por Oskar (comprobado: no está en `prompts/`)
- [x] P8 · Segunda revisión: inventario (122 fichas, 20 simulaciones) contra las tandas de §3; 14 rutas contra las marcas «Ruta corta» de las fichas; constantes del verificador contra la guía

### Antes de empezar cualquier tanda de escritura

- [x] Leídos §3, §6, §7 y §8 de este plan
- [x] Leídas la guía entera y las fichas de la tanda
- [x] El verificador sale sin errores **antes** de empezar
- [x] Las tandas de las que depende están ✅

### T0 — Arranque

- [x] 23 carpetas de bloque con los nombres del inventario
- [x] 20 solucionarios en esqueleto
- [x] README del corpus en esqueleto (tesis, mapa, rutas; «en producción»)

### T1 — Bloque 01, primera mitad

- [x] `01/01` El juez, los veredictos y las plataformas
- [x] `01/02` Leer las restricciones
- [x] `01/03` Entrada, salida y la plantilla
- [x] `01/04` Tipos, desbordamiento y módulo
- [x] Respuestas y pistas en `01/09` · verificador limpio · deudas anotadas

### T2 — Bloque 01, segunda mitad

- [x] `01/05` Probar sin IDE y *stress test*
- [x] `01/06` El protocolo de resolución (incluye la IA como tutor)
- [x] `01/07` Programar en vivo
- [x] `01/08` Simulación
- [x] `01/09` Respuestas completo · verificador limpio · deudas anotadas

### T3 — Bloque 02, primera mitad

- [x] `02/01` Notación asintótica y casos
- [x] `02/02` Recurrencias y teorema maestro
- [x] `02/03` Análisis amortizado
- [x] Respuestas y pistas en `02/08` · verificador limpio · deudas anotadas

### T4 — Bloque 02, segunda mitad

- [x] `02/04` Corrección: invariantes, inducción, intercambio
- [x] `02/05` El coste real
- [x] `02/06` Tipos abstractos de datos
- [x] `02/07` Simulación
- [x] `02/08` Respuestas completo · verificador limpio · deudas anotadas

### T5 — Bloque 03, primera mitad

- [x] `03/01` C++: contenedores de la STL
- [x] `03/02` C++: algoritmos, *ranges* y PBDS
- [x] `03/03` Java: colecciones
- [x] Respuestas y pistas en `03/08` · verificador limpio · deudas anotadas

### T6 — Bloque 03, segunda mitad

- [x] `03/04` Python para competir
- [x] `03/05` La tabla de equivalencias
- [x] `03/06` Competir sin arsenal: Go y JavaScript
- [x] `03/07` Simulación
- [x] `03/08` Respuestas completo · verificador limpio · deudas anotadas

### T7 — Bloque 04

- [x] `04/01` Prefijos y diferencias
- [x] `04/02` Dos punteros y ventana
- [x] `04/03` Kadane y subarreglos
- [x] `04/04` Compresión y barrido
- [x] `04/05` Matrices
- [x] `04/06` Simulación
- [x] `04/07` Respuestas completo · verificador limpio · deudas anotadas

### T8 — Bloque 05, primera mitad

- [x] `05/01` Ordenación por comparación
- [x] `05/02` Ordenación lineal
- [x] `05/03` Inversiones y selección
- [x] Respuestas y pistas en `05/07` · verificador limpio · deudas anotadas

### T9 — Bloque 05, segunda mitad

- [x] `05/04` Búsqueda binaria
- [x] `05/05` Ternaria y exponencial
- [x] `05/06` Simulación
- [x] `05/07` Respuestas completo · verificador limpio · deudas anotadas

### T10 — Bloque 06

- [x] `06/01` Pilas, colas y monótonas
- [x] `06/02` Listas enlazadas
- [x] `06/03` Tablas hash
- [x] `06/04` Hashing de secuencias
- [x] `06/05` Simulación
- [x] `06/06` Respuestas completo · verificador limpio · deudas anotadas

### T11 — Bloque 07, primera mitad

- [x] `07/01` Árboles y recorridos
- [x] `07/02` BST y balanceados
- [x] `07/03` Árboles aleatorizados
- [x] `07/04` Tries
- [x] Respuestas y pistas en `07/09` · verificador limpio · deudas anotadas

### T12 — Bloque 07, segunda mitad

- [x] `07/05` LCA
- [x] `07/06` Técnicas sobre árboles
- [x] `07/07` Árboles dinámicos
- [x] `07/08` Simulación
- [x] `07/09` Respuestas completo · verificador limpio · deudas anotadas

### T13 — Bloque 08

- [x] `08/01` Montículo binario
- [x] `08/02` Patrones con heap
- [x] `08/03` Montículos fusionables
- [x] `08/04` Union-Find
- [x] `08/05` Simulación
- [x] `08/06` Respuestas completo · verificador limpio · deudas anotadas

### T14 — Bloque 09, primera mitad

- [x] `09/01` *Sparse table*
- [x] `09/02` Fenwick
- [x] `09/03` Segment tree
- [x] Respuestas y pistas en `09/08` · verificador limpio · deudas anotadas

### T15 — Bloque 09, segunda mitad

- [x] `09/04` Segment tree avanzado
- [x] `09/05` Raíz cuadrada y Mo
- [x] `09/06` Árbol cartesiano y *wavelet tree*
- [x] `09/07` Simulación
- [x] `09/08` Respuestas completo · verificador limpio · deudas anotadas

### T16 — Bloque 10, primera mitad

- [x] `10/01` Recursión
- [x] `10/02` Generar subconjuntos y permutaciones
- [x] `10/03` *Backtracking* y poda
- [x] Respuestas y pistas en `10/08` · verificador limpio · deudas anotadas

### T17 — Bloque 10, segunda mitad

- [x] `10/04` *Meet in the middle*, IDDFS y *Dancing Links*
- [x] `10/05` Divide y vencerás
- [x] `10/06` Juegos y búsqueda adversarial
- [x] `10/07` Simulación
- [x] `10/08` Respuestas completo · verificador limpio · deudas anotadas

### T18 — Bloque 11

- [x] `11/01` Cuándo funciona un voraz
- [x] `11/02` Intervalos
- [x] `11/03` Plazos, Huffman y monedas
- [x] `11/04` Matroides y contraejemplos
- [x] `11/05` Simulación
- [x] `11/06` Respuestas completo · verificador limpio · deudas anotadas

### T19 — Bloque 12, primera mitad

- [x] `12/01` De la recursión a la tabla
- [x] `12/02` DP lineal y LIS
- [x] `12/03` Mochilas
- [x] Respuestas y pistas en `12/08` · verificador limpio · deudas anotadas

### T20 — Bloque 12, segunda mitad

- [x] `12/04` DP sobre cadenas
- [x] `12/05` Rejillas e intervalos
- [x] `12/06` Conteo
- [x] `12/07` Simulación
- [x] `12/08` Respuestas completo · verificador limpio · deudas anotadas

### T21 — Bloque 13, primera mitad

- [x] `13/01` Máscaras de bits
- [x] `13/02` *Digit DP*
- [x] `13/03` DP en árboles y DAG
- [x] `13/04` Probabilidad y esperanza
- [x] Respuestas y pistas en `13/09` · verificador limpio · deudas anotadas

### T22 — Bloque 13, segunda mitad

- [x] `13/05` Optimizaciones
- [x] `13/06` Recurrencias lineales y matrices
- [x] `13/07` Trucos de nivel alto
- [x] `13/08` Simulación
- [x] `13/09` Respuestas completo · verificador limpio · deudas anotadas

### T23 — Bloque 14, primera mitad

- [x] `14/01` Representaciones
- [x] `14/02` BFS
- [x] `14/03` DFS
- [x] Respuestas y pistas en `14/08` · verificador limpio · deudas anotadas

### T24 — Bloque 14, segunda mitad

- [x] `14/04` Orden topológico
- [x] `14/05` Componentes fuertes y 2-SAT
- [x] `14/06` Puentes, articulación y Euler
- [x] `14/07` Simulación
- [x] `14/08` Respuestas completo · verificador limpio · deudas anotadas

### T25 — Bloque 15, primera mitad

- [x] `15/01` Dijkstra
- [x] `15/02` Bellman-Ford, Floyd y Johnson
- [x] `15/03` A\*
- [x] `15/04` Árbol de expansión mínima
- [x] Respuestas y pistas en `15/09` · verificador limpio · deudas anotadas

### T26 — Bloque 15, segunda mitad

- [x] `15/05` Flujo máximo
- [x] `15/06` Emparejamientos
- [x] `15/07` Grafos de nivel experto
- [x] `15/08` Simulación
- [x] `15/09` Respuestas completo · verificador limpio · deudas anotadas

### T27 — Bloque 16, primera mitad

- [x] `16/01` Cadenas y patrones básicos
- [x] `16/02` KMP
- [x] `16/03` Función Z y Manacher
- [x] `16/04` Hashing de cadenas
- [x] Respuestas y pistas en `16/10` · verificador limpio · deudas anotadas

### T28 — Bloque 16, segunda mitad

- [x] `16/05` Aho-Corasick
- [x] `16/06` *Suffix array* y *automaton*
- [x] `16/07` Autómatas y expresiones regulares
- [x] `16/08` *Eertree* y Ukkonen
- [x] `16/09` Simulación
- [x] `16/10` Respuestas completo · verificador limpio · deudas anotadas

### T29 — Bloque 17, primer tercio

- [x] `17/01` Bits
- [x] `17/02` Divisibilidad
- [x] `17/03` Aritmética modular
- [x] `17/04` Primos
- [x] Respuestas y pistas en `17/13` · verificador limpio · deudas anotadas

### T30 — Bloque 17, segundo tercio

- [x] `17/05` Combinatoria
- [x] `17/06` Probabilidad y esperanza
- [x] `17/07` Matrices y Gauss
- [x] `17/08` Teoría de juegos
- [x] Respuestas y pistas en `17/13` · verificador limpio · deudas anotadas

### T31 — Bloque 17, cierre

- [x] `17/09` FFT y NTT
- [x] `17/10` Teoría de números avanzada
- [x] `17/11` Funciones generadoras
- [x] `17/12` Simulación
- [x] `17/13` Respuestas completo · verificador limpio · deudas anotadas

### T32 — Bloque 18

- [x] `18/01` Vectores y orientación
- [x] `18/02` Rectas y segmentos
- [x] `18/03` Polígonos
- [x] `18/04` Envolvente convexa
- [x] `18/05` Barrido geométrico
- [x] `18/06` Geometría avanzada
- [x] `18/07` Simulación
- [x] `18/08` Respuestas completo · verificador limpio · deudas anotadas

### T33 — Bloque 19

- [x] `19/01` Las Vegas y Monte Carlo
- [x] `19/02` Hashing universal y análisis esperado
- [x] `19/03` Estructuras probabilísticas
- [x] `19/04` Muestreo y Markov
- [x] `19/05` Estructuras espaciales
- [x] `19/06` Datos masivos
- [x] `19/07` Simulación
- [x] `19/08` Respuestas completo · verificador limpio · deudas anotadas

### T34 — Bloque 20

- [x] `20/01` Ad hoc y simulación
- [x] `20/02` Constructivos
- [x] `20/03` Interactivos
- [x] `20/04` El estilo de las pruebas de empresa
- [x] `20/05` Heurísticos y aproximados
- [x] `20/06` Simulación
- [x] `20/07` Respuestas completo · verificador limpio · deudas anotadas

### T35 — Bloque 21, simulacros

- [x] `01`–`05` Simulacros de empresa en HackerRank o LeetCode
- [x] `06`–`08` Simulacros de empresa en Codility o Coderbyte
- [x] `09`–`12` Simulacros en vivo, con guion y rúbrica
- [x] `13`–`16` Simulacros de concurso
- [x] `17-pistas.md` y README del bloque · verificador limpio

### T36 — Bloque 22 (opcional)

- [x] `22/01`–`22/06`
- [x] `22/07` Respuestas y README · verificador limpio

### T37 — README

- [x] README de los bloques `01`–`21`
- [x] README del corpus definitivo, con las 14 rutas

### T38 — Bloque 23 (opcional)

- [x] Cuadernos de C++, Java y Python generados de los capítulos
- [x] Cuadernos de Go y JavaScript (plantillas A completas)
- [x] README del bloque

### TV — Pasada de verificación

- [x] Herramientas de la guía §5.3 comprobadas
- [x] Plantillas A y B compiladas y probadas con *stress test*
- [x] Ejemplos trabajados y trazas corridos
- [x] Problemas propios validados con solución de referencia
- [x] Enlaces y problemas externos comprobados con su método
- [x] Deuda de ejecución vacía o con motivos escritos
- [x] Fecha de la corrida y versiones en el README del corpus

### TC — Cierre

- [x] Verificador global sin errores, y `verificador_base.py` con `--perfil=repaso` y `--perfil=publicacion`
- [x] Literalidad de los 21 solucionarios y de `21/17` comparada (preguntas, simulaciones y listas de problemas)
- [x] Un caso de borde en cada problema propio que tenía uno solo (guía §9.1), validado con su referencia
- [x] Revisión de restos de producción: ningún documento publicado cita `prompts/`, el plan ni `zz-code/`
- [x] Ningún contenedor ni recurso de Docker del corpus (no se usó Docker)
- [x] `zz-code/`: ningún directorio del corpus *vigente* en §10; los tres, borrados por Oskar (2026-10-05)
- [x] Lo efímero de los *scratchpads* de las cuatro sesiones, borrado por Oskar; `prompts/__pycache__` también; `prompts/`
  conservado como referencia (este plan incluido)

---

## 10. 🧪 Directorios de `zz-code/`

Cada directorio de código intermedio que crearon las sesiones de este corpus, con su estado. Las reglas
están en `zz-code/README.md`. **Los tres primeros se borraron al cerrar el corpus (2026-10-05), por decisión de Oskar,
con sus `MANIFIESTO.md`**: lo que hacía cada uno queda descrito en la tabla y en las entradas de T36–T38, TV y
TC de la bitácora (§8), que se conservan como registro histórico.

Estados: *vigente* (se sigue usando) · *extraído* (lo útil ya pasó al corpus, a `prompts/` o a
`zz-instrucciones/herramientas/`) · *archivado* (se conserva como referencia) · *borrado* (ya no existe).

| Directorio | Tanda | Qué se probó | Estado | Regenerable liberado |
|---|---|---|---|---|
| `zz-code/02-algoritmos-20261004-9436/` | T36–T38 | Generadores de `22/07`, de los README y de los cuadernos; Go y JS de `23` con sus pruebas | borrado (2026-10-05) | sí, con el directorio |
| `zz-code/02-algoritmos-20261004-fbe3/` | TV | Arneses de *stress test*, ejemplos y trazas, referencias de los problemas propios, enlaces | borrado (2026-10-05) | sí, con el directorio |
| `zz-code/02-algoritmos-20261005-d2f3/` | TC | Literalidad de los solucionarios; casos de borde de 132 problemas propios | borrado (2026-10-05) | sí, con el directorio |
| `zz-code/02-algoritmos-20261005-fd37/` | Diagramas | Conversión de 106 bloques `text` a Mermaid (`lote1.py`–`lote4.py`) y dibujo con `mmdc` | archivado | no |
