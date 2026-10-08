# 📌 Pendientes a futuro

> Material de autoría, no de lectura. Reúne las secciones «📌 Pendientes sugeridos» que cada fase y
> cada sección de `ia` y `ds` traía al final, sacadas de los documentos publicados el 07/10/2026
> para la etapa de publicación. Cada pendiente conserva su texto original; la revisión de esa fecha
> está al principio, en *Estado de la revisión*.
>
> **Vigencia:** 2026-10-07. Empieza por *Pendientes abiertos*: es la lista de trabajo.

## Pendientes abiertos

La lista de trabajo del curso después de su cierre. Se resuelven con el curso, en el orden que el
autor decida; al cerrar uno, se marca aquí con la fecha y se anota en la fase que cambió. El texto
original de cada pendiente sigue más abajo, en la sección del documento que lo generó.

- [ ] **1. `op013` (`au06`) · `LoadCredential=` en systemd.** *Se cierra:* corriendo la unidad en una
  máquina o máquina virtual con systemd (no en Docker Desktop, que no monta credenciales) y
  quitando la marca de «probado en parte» de la sección y del plan de la carta.
- [ ] **2. Mediciones en Windows 11 y Linux amd64** (F00, F05, F07, F09). *Se cierra:* repitiendo esas
  mediciones en las dos plataformas y, si un veredicto cambia (antivirus, `.pyz`, creación de
  procesos), reescribiendo su §6 y su fila de `BENCHMARKS.md`.
- [ ] **3. Las tablas de dos núcleos** (F14 y F17; F17 las pide antes de publicar). *Se cierra:* una
  sesión de medición con el duelo completo —FastAPI, Spring Boot y el generador de carga— en una
  máquina de dos núcleos.
- [ ] **4. Mediciones que faltan en el camino base:** GraalVM `native-image` y el *bytecode* compilado
  en la imagen (F17); base de datos remota (F11, F15); `py-spy` y la distorsión de `cProfile` (F16);
  el porqué del 1.14× del *free-threading* (F14, F16); `pyright` (F08); el `.pyz` con una dependencia
  compilada (F09); la comparación contra un script de shell (F05). *Se cierra:* cada una con el arnés
  del curso y su fila en `BENCHMARKS.md`; las de F08, F09, F16 y F17 necesitan antes el `src/` de
  esas fases.
- [ ] **5. Las mediciones `⏳` del track `ia`** (`ia01`–`ia08`, §6). *Se cierra:* corriéndolas con una
  clave de la API (cuestan dinero) y reescribiendo con sus cifras el veredicto de `ia08` §6.3.
- [ ] **6. Lo que necesita personas:** los juicios humanos de `ia06` y los cinco voluntarios de
  `ds05` §6.2. *Se cierra:* llenando `juicios_humanos.jsonl` con la rúbrica y corriendo el protocolo
  de `ds05`.
- [ ] **7. Los experimentos abiertos del track `ds`:** deriva (`ds07`, `ds09`), gradiente potenciado
  (`ds07`, `ds08`), calibración (`ds07`), interacciones del generador y `COLLISION_RATIO` (`ds08`),
  las celdas que faltan (Polars sobre Parquet en `ds03`, `pandas.plot()` en `ds05`), el repositorio
  real de `ds06`, el bootstrap de 2.000 remuestreos (`ds04`), el *backend* a mano y la concurrencia
  de `ds09`, y las comparaciones contra Java (`ds01`) y Postgres (`ds02`, `ds03`). *Se cierra:* cada
  uno con su medición; los que cambian un veredicto obligan a reescribirlo.
- [ ] **8. Decisiones de contenido del autor:** las restricciones de exclusión de Postgres (F11, F14);
  la migración del histórico de `sqlite3` en F11, como confiesa F17; la firma de código, que ningún
  track cubre (F09); el costo de la valoración gratuita en el generador de `ds04`; subir al cuerpo lo
  que hoy es ejercicio (`ds04` ej. 24, `ds05` ej. 21, `ds07` ej. 24, `ds08` §6.6, la sección de
  deriva de `ds`); la viabilidad del criterio 4 de `ia05`; el ejercicio de `SettingWithCopyWarning`
  en la carta. *Se cierra:* con la decisión escrita aquí y, si se agrega contenido, con la fase que
  lo recibe probada como el resto.

> 📝 Las celdas `⏳` de `op029` y `op036` no están en esta lista: son, por diseño, un ejercicio de su
> propia sección.

---

## Estado de la revisión

Revisión del 07/10/2026, pendiente por pendiente, contra el material publicado. Tres resultados:

**Ya estaban resueltos** (el material posterior los cumplía, o eran decisiones registradas y no
deuda): los 🪦, las fusiones declaradas de las Fases 03, 08, 16 y 17, los generadores de `ia` y `ds`,
los reflejos de `INSTINTOS.md` (todos están), las tasas en TOML (F06), el `Protocol` de
`SPECIAL_RULES` (F08), `StrEnum` (F10), la regla 9 (F11), el *outbox* (F15), la visibilidad del
cierre (F16), el `__main__` de `cli.py` (F09 y `contrato-del-cli.md`), `HTTP_422_UNPROCESSABLE_CONTENT`
(F10; Starlette 1.7.0 sigue avisando con el nombre viejo, comprobado), `ruff` todavía en 0.16.x,
los tracks `au` y `ar` (ya existen en la carta), y los cruces de `ia` que ya cumplían
(caché en `ia08`, NormaRAG fuera de `ia07`, el conjunto de `ia06` en `ia08`, el veredicto de `ds09`).

**Resueltos el 07/10/2026**, con una nota corta en la fase destino:

| Pendiente | Dónde se cerró |
|---|---|
| F01 ej. 24 · cuándo merece una clase | F03 §5.1 |
| F02 · el archivo de un generador no consumido | F04 §5.4 (`contextlib.closing`, comprobado) |
| F08 · `return` dentro de `except*` | F04 §4 (`SyntaxError`, comprobado en 3.14.7) |
| F04/F08 · `assert` con `-O` | F08 §4 |
| F01 ej. 13 y F03 · formato del dinero a la salida | F06 §5.2 (`quantize` y formato sin `locale`, comprobado) |
| F06 · los dos generadores con esquemas distintos | F06 §5.2 |
| F06 · la heurística del separador de miles | F10 §4 |
| F08/F11 · `ROUND_HALF_UP` contra `ROUND_HALF_EVEN` | F11 §5.1, con la diferencia medida en Postgres 18.6 |
| F06 · el dinero como `TEXT` y `Numeric`, citados entre sí | F11 §5.1 |
| F06 · `with connection:` no cierra, con *pool* | F11 §5.2 (`pool_timeout` 30 s, comprobado) |
| F04 · la regla 6 como restricción de unicidad | F11 §5.1 |
| F03 · el orden del tope mensual | F15 §7 (regla 3) |
| F13 · la reconciliación con el socio que miente | F15 §5.6 |
| F12 · la convivencia de dos frameworks | F15 §7 (esquema propio del cierre) |
| F13 · `http.server` | F16 §4 |
| F09 · qué versión corre en cada máquina | F16 §5.1 |
| F04 ej. 23 · `fsync` | F16 §5.8 |
| F05 y F14 · los nietos y el `Ctrl-C` | F16 §5.8 (`killpg`, comprobado) |
| F07 · el primer `import` lento con `uv` | F16 §5.8 y F17 §6 (lo que no se midió) |
| F01 ej. 9 · `sys.intern` | F16 §5.8 |
| F17 · la referencia a otro curso del repositorio | F17 §5 (el curso es autocontenido) |
| `ia03` · `hold_slot` y la tabla de propuestas | `ia03` §5 y el comentario de `src/ia03-…/agenda_client.py` |
| `ia02` · la inyección desde el documento | `ia07` §4 y el checklist de `ia08` |
| `ia05` · el OCR | `ia05` (ya existe `ar04`) y `op150-ar04` cita el informe de cobertura |
| `ia04` · el track `db` no contradice a `pgvector` | `op087-db11` |

**No se pueden resolver todavía:** están en *Pendientes abiertos*, al principio de este documento.

Fuera de la lista porque no son deuda: las celdas `⏳` de `op029` y `op036` son, por diseño, un
ejercicio de su propia sección.

---

## `00-instalacion-ambiente-editores-y-ecosistema.md`

*🛠️ Fase 00 — Ambiente, editores y el mapa del ecosistema*

- 🪦 **`PyCharm Community` ya no existe como producto**, y el curso ya no lo
  nombra: sus versiones fijadas quedaron actualizadas
  a *PyCharm 2026.2.2, capa gratuita*, con la nota 🪦 que explica la unificación de 2025.3. Esta
  fase es la única que describe qué queda del lado Pro.
- **La medición es de una sola plataforma.** Faltan los números de Windows 11 y de Linux amd64,
  que el alcance pide cubrir sin nota al pie. El ejercicio 22 traslada el trabajo al lector, que
  es honesto pero no es lo mismo. Destino sugerido: producirlos antes de consolidar
  `BENCHMARKS.md` en la Fase 17, porque en Windows la diferencia puede invertir el veredicto.
- **`aur_cli.py` aparece nombrado aquí** en `launch.json`, antes de que la Fase 01 lo cree. Es
  deliberado, y la Fase 01 tiene que usar exactamente ese nombre.
- **El escenario del `sys.path` con `''` al principio** (ejercicio 7) toca el modelo de
  importación, que ninguna fase cubre de frente. Destino sugerido: una sección de la Fase 07,
  cuando el layout `src/` haga que la pregunta *"¿desde dónde se está importando esto?"* pase a
  importar de verdad.
- Verificar, al cerrar el curso, si `ruff` sigue en 0.16.x. Es la única herramienta de esta fase
  que se mueve rápido, y la versión está fijada en esta fase.

---

## `01-modelo-de-datos.md`

*🧬 Fase 01 — El modelo de datos*

- **El formato de moneda colombiano** (ejercicio 13) queda sin resolver de verdad: `locale`
  depende de la máquina y el curso no puede asumirla. Destino sugerido: una sección corta de la
  Fase 06, donde el formato de salida ya importa de verdad porque se genera el XML de la DIAN.
- **`sys.intern` y el costo en memoria de las cadenas repetidas** (ejercicio 9) es material que
  se roza aquí y se aprovecharía mejor en la Fase 16, con el perfilado delante. Anotado allí.
- **La pregunta del ejercicio 24 —¿cuándo merece una clase?— queda deliberadamente abierta**, y
  la Fase 03 tiene que contestarla de frente, citando este ejercicio. Si no lo hace, el bucle
  queda sin cerrar.
- **El generador de datos `generar_datos_f01.py`** produce los archivos de marzo. La Fase 02
  necesita el archivo de citas del trimestre —500.000 filas— y conviene que sea **el mismo
  generador extendido**, no uno nuevo: un solo script de datos para todo el curso envejece mejor
  que seis. Decidirlo al escribir la Fase 02.
- El export de Odontovía de esta fase tiene seis columnas y ninguna descripción de texto libre.
  **La Fase 06 necesita una columna con comas adentro** para que la factura de la deuda sea
  visible; conviene que el generador la agregue desde ya, aunque el Bloque A no la use.

---

## `02-secuencias-perezosas.md`

*🔁 Fase 02 ⭐ — Secuencias perezosas*

- **El archivo abierto por un generador no consumido** se nombra en §5.3 con su advertencia y no
  se resuelve: la herramienta correcta —`contextlib.closing`, y el `try/finally` dentro del
  generador— es de la Fase 04. Que la 04 lo retome citando esta fase, o el bucle queda abierto.
- **`tracemalloc` mide lo que asigna Python, no lo que el sistema le da al proceso.** La
  diferencia importa cuando el trabajo cruza a un proceso hijo, y eso llega en las Fases 14 y 16.
  El arnés tendrá que ampliarse ahí —ampliarse, no reemplazarse.
- **El ejercicio 24 abre la puerta a pandas** y la fase la cierra con la regla del Bloque A. Es una
  respuesta honesta pero incompleta: el track de datos debería contestarla con una medición de
  verdad sobre este mismo archivo, y citar este ejercicio.
- **El generador de datos quedó separado del de la Fase 01**, contra lo que sugería el 📌 de esa
  fase. La razón: producen archivos con esquemas distintos —pacientes contra citas— y unirlos
  habría obligado a un generador con banderas que no aporta nada pedagógico. Queda anotado como
  decisión, no como deuda.
- La **Fase 06 necesita que el generador emita la columna `descripcion` con comas adentro** para
  que la factura de la deuda 💸 sea visible. Este generador no la tiene todavía: agregarla al
  escribir la 06, y decidir allí si el archivo del trimestre también la lleva.

---

## `03-python-sin-ceremonia.md`

*🎩 Fase 03 — Python sin ceremonia*

- **La fusión cabe, y conviene dejar dicho por qué**, porque la propuesta de fases obligaba a
  declararlo: funciones y objetos comparten un solo 🪞 —la ceremonia—, un solo miniproyecto que lo
  ataca entero, y una medición que **necesita las dos mitades** para existir (la comparación de
  estilos no se puede hacer sin clases, y la de representaciones no se puede hacer sin
  `dataclass`). Separarlas produciría dos fases con media lección cada una. **No se propone
  deshacer la fusión.**
- **El orden importa en el tope mensual** (§5.3 y ejercicio 23) y esta fase solo lo declara. La
  Fase 15 tiene que resolverlo de verdad cuando el proceso nocturno sea reanudable: un cálculo
  cuyo resultado depende del orden de procesamiento no puede reanudarse a la mitad sin decidirlo.
- **El formato de `Decimal` en la salida** —`150000.00` contra `150000`— se nombra en la prueba de
  fuego y no se resuelve. Destino: Fase 06, donde se genera el XML de la DIAN y el formato pasa a
  ser un requisito, con `Decimal.quantize` como herramienta.
- **`SPECIAL_RULES` no declara la firma de lo que contiene**, que es la pérdida real frente a la
  clase base abstracta y está dicha en el veredicto de §6.1. La Fase 08 tiene que cerrar ese bucle
  con un `Protocol` verificado, citando esta fase.
- **Las tasas de los aliados son código hoy y deberían ser datos.** §5.3 anuncia que la Fase 06 las
  mueve a un TOML. Si la 06 no lo hace, la promesa de "0 sitios de código" de la tabla de §6.1
  queda sin cumplir.

---

## `04-errores-y-recursos.md`

*💥 Fase 04 — Errores y recursos*

- **El archivo abierto por un generador no consumido**, que la Fase 02 dejó anotado, se cierra
  aquí a medias: `contextlib.closing` aparece en las referencias y en un ejercicio 🔥, pero no en
  el cuerpo. Si al revisar el Bloque A parece poco, la sección 5.4 es el sitio natural para
  dedicarle un párrafo.
- **`assert` desaparece con `-O`** se dice en el diccionario y se deja ahí. La Fase 08 lo vuelve a
  necesitar —`pytest` usa `assert` a propósito, y ahí sí es correcto— y conviene que cierre el
  bucle explícitamente en vez de dar la impresión de contradecir a esta fase.
- **El ejercicio 23 apunta a un problema real que esta fase no puede resolver**: `os.replace` es
  atómico pero no garantiza que los datos estén en disco si se corta la luz. La respuesta es
  `os.fsync`, y su sitio natural es la Fase 16, donde la operación es el tema.
- **La regla 6 del miniproyecto —el duplicado— es en realidad una regla de negocio de la
  aseguradora**, y en la Fase 11 va a reaparecer como una restricción de unicidad en la base de
  datos. Conviene citarla desde allá: es el mismo invariante en dos registros distintos, y es un
  buen ejemplo de cómo cambia el costo de imponerlo.
- El generador `generar_lote_febrero.py` siembra **106 problemas de siete clases** —105 de fila
  más el duplicado—, verificado al escribir la fase, y el número está en su docstring y en los
  criterios de aceptación. Si alguna fase posterior cambia el generador, ese número hay que
  recalcularlo en los tres sitios o el enunciado pasa a mentir.

---

## `05-shell-con-esteroides.md`

*🐚 Fase 05 ⭐ — El shell con esteroides*

- **Los procesos nietos que sobreviven a un `timeout`** se nombran en §5.2 con su advertencia y se
  trasladan al ejercicio 22, porque la solución completa —grupos de procesos— depende del sistema
  operativo y no cabe en el camino base. Si la Fase 16 toca la operación de procesos de larga
  duración, es el sitio para cerrarlo.
- **`Enum` aparece por primera vez en la pista 3 del miniproyecto** y no en el cuerpo de ninguna
  fase. Es de la biblioteca estándar, es trivial de usar, y quedó huérfano: conviene que la Fase
  06 o la 10 le dediquen un párrafo, o que la Fase 03 lo absorba en su sección de `dataclass`.
- **La medición no cubre Windows**, donde crear un proceso es más caro y el antivirus lo
  inspecciona. Es la plataforma de Patricia y la diferencia sería mayor: producirlo antes de
  consolidar `BENCHMARKS.md`.
- **El ejercicio 24 compara contra un script de shell** y esa comparación merecería ser una
  medición del curso, no solo un ejercicio: es la comparación más honesta que se le puede pedir al
  Bloque A. Destino sugerido: un bloque 📏 adicional en esta fase si se decide ampliarla, o una
  entrada propia en `BENCHMARKS.md`.
- **El simulador del firmador tiene una semilla por NIT** para que la medición compare lo que dice
  comparar. Si alguna fase posterior reutiliza el simulador, ese detalle no se puede cambiar sin
  invalidar la tabla de §6.

---

## `06-formatos-en-la-caja.md`

*📦 Fase 06 — Formatos en la caja*

- **El XML de la DIAN queda fuera con su razón escrita** (§3). Es la exclusión más discutible del
  Bloque A, porque Áurea lo genera de verdad. Si alguna vez se abre un track de integración
  tributaria colombiana, es su primer capítulo; mientras tanto, el curso lo trata como texto que se
  firma con el binario del proveedor.
- **La heurística del separador de miles** (§5.2) cubre el caso de Áurea y falla con decimales
  reales. Está declarada, y la solución honesta —rechazar el valor ambiguo— es una decisión de
  negocio que el curso no puede tomar. La Fase 10 la retoma desde la validación en la frontera.
- **El dinero como `TEXT` en SQLite** (§5.4) es una decisión defendible y no es la única; el
  ejercicio 24 pide compararla con enteros en centavos. Si al escribir la Fase 11 se decide otra
  cosa para Postgres, **las dos decisiones tienen que citarse entre sí** o el lector va a creer que
  el curso se contradice.
- **`with connection:` no cierra la conexión** es una trampa que esta fase nombra y que la Fase 11
  va a encontrar otra vez con un *pool* de por medio, donde las consecuencias son peores. Conviene
  citarla desde allá.
- **El archivo del trimestre de la Fase 02 no tiene la columna `descripcion`** que esta fase
  agregó a los exports. Los dos generadores conviven y producen esquemas distintos a propósito
  —uno es de citas y otro de procedimientos facturables— pero conviene decirlo en algún sitio del
  material antes de que alguien intente cruzarlos.

---

## `07-cuando-deja-de-ser-un-script.md`

*🚪 Fase 07 ⭐ — Cuándo deja de ser un script*

- **El primer `import` de 2.28 s con `uv`** es un hallazgo que merece más de lo que cabe aquí.
  Destino sugerido: la Fase 16, en el bloque 📏 de rendimiento, donde el bytecode y el arranque
  ya son tema; y la Fase 17, porque afecta directamente el arranque en frío del contenedor que se
  mide en el duelo.
- **La medición es de una sola plataforma y de una sola corrida por caso.** Las diferencias son de
  un orden de magnitud y aguantan, pero Windows falta y es donde `uv` tendría **más** ventaja.
  Destino: producirla antes de consolidar `BENCHMARKS.md`.
- **El `if __name__ == "__main__":` de `cli.py`** se conserva durante la migración y la Fase 09
  tiene que decidir si se queda. Si no lo decide, queda código muerto en el entregable final.
- **El ejercicio 25 puede descubrir un error en el corte de módulos de §5.2** — algo que el batch
  de la Fase 15 necesite y que hoy viva en `cli.py`. Si aparece, el contrato del CLI se corrige
  **antes** de escribir la Fase 15, no después.
- **`uv tool install` se nombra aquí de pasada** y es el mecanismo central de la Fase 09. Que la
  09 no lo introduzca como si fuera nuevo: enlázalo a esta fase.
- Al escribir el **track de datos e IA**, la tabla de la sección 6 se invierte y conda gana. La
  medición de aquí debería citarse allá explícitamente, para que el lector vea que el curso
  cambia de opinión con datos y no por capricho.

---

## `08-el-contrato-del-codigo.md`

*🔎 Fase 08 — El contrato del código*

- **El `return` dentro de `except*` era un error real del propio material del curso**, encontrado
  al ejecutar `mypy` sobre el código del Bloque A mientras se escribía esta fase. La Fase 04 usa
  `sys.exit(1)` en esa posición y por eso no lo tiene; **cualquier fase que en el futuro escriba un
  `except*` dentro de una función que retorne tiene que saberlo.** Conviene que la Fase 04 lo
  mencione en una línea, porque es el sitio donde el lector aprende `except*`.
- **La fusión de tipado y pruebas se sostiene**, y la prueba es que el miniproyecto es uno solo y
  las dos mitades se tocan: el `Protocol` de §5.2 es lo que hace falso el registro equivocado, y la
  prueba de propiedades es lo que hace falso el reparto. Si alguna vez se separan, el miniproyecto
  se parte en dos ejercicios más débiles.
- **`assert` con `-O`**: la Fase 04 advirtió que `assert` desaparece con la bandera de
  optimización, y esta fase lo usa como mecanismo central de `pytest`. **No hay contradicción y
  conviene decirlo explícitamente en alguna de las dos**: `pytest` corre sin `-O` a propósito, y
  usar `assert` para validar entradas de producción sigue estando mal.
- **`ROUND_HALF_UP` contra `ROUND_HALF_EVEN`** aparece en una pista y merece más: el valor por
  defecto de Python no es el de la contabilidad colombiana, y eso vale dinero. Destino sugerido:
  una nota 📝 en la Fase 11, donde el dinero se persiste.
- **No se midió `pyright`** (ejercicio 19), y el alcance lo declara como alternativa. Si alguna vez
  se produce ese número, esta sección debería citarlo.

---

## `09-distribucion.md`

*🎁 Fase 09 ⭐ — Entregarle la herramienta a Patricia*

- **Ninguna medición en Windows**, que es justamente la plataforma de Patricia y donde dos
  columnas de la tabla cambian: el antivirus con el congelado, y la asociación del doble clic del
  `.pyz`. Es el hueco más grande de esta fase. Destino: producirlas antes de consolidar
  `BENCHMARKS.md`, y si el resultado cambia el veredicto, reescribir §6.
- **`aur` no tiene dependencias de terceros**, lo que favorece al `.pyz` de una forma que deja de
  ser cierta en cuanto el proyecto tenga una sola dependencia compilada. La tabla debería
  repetirse con el paquete de la Fase 10 — el ejercicio 19 lo pide al lector, pero el curso
  debería traer su propio número.
- **El escenario 3 —saber qué versión corre en cada máquina— se plantea y no se resuelve** para
  tres de las cuatro opciones. El ejercicio 24 lo traslada al lector. Si al escribir la Fase 16 la
  observabilidad ofrece una respuesta natural, conviene cerrar el bucle explícitamente allí.
- **El `if __name__ == "__main__":` de `cli.py`**, que la Fase 07 dejó pendiente de decisión:
  esta fase lo necesita para el `.pyz` y para el congelado, así que **se queda**. Anotarlo en el
  contrato del CLI para que ninguna fase posterior lo borre por limpieza.
- **La firma de código** queda fuera con su razón, y es la mitad del problema del congelado en
  Windows. Destino sugerido: track `pk`, junto con la publicación en índices.

---

## `10-fastapi.md`

*⚡ Fase 10 — FastAPI y la validación en el borde*

- **`StrEnum` entra aquí y cierra el 📌 que dejó la Fase 05**, donde `Enum` aparecía en una pista
  sin que ninguna fase lo introdujera. Si se decide moverlo a la Fase 03, esta sección tiene que
  dejar de presentarlo.
- **La medición en proceso contra la medición sobre HTTP** dio resultados distintos (33% contra
  0%), y la fase lo declara como nota de método. **Es material de `INSTINTOS.md`**: la lección
  —lo que mides cambia la respuesta— es transferible y vale más que el número.
- **`HTTP_422_UNPROCESSABLE_ENTITY` está obsoleto** en Starlette 0.5x y emite advertencia. Está
  dicho en §5.3; conviene verificarlo otra vez antes de publicar, porque es el tipo de detalle que
  cambia entre versiones menores.
- **El almacén en memoria de esta fase es deliberadamente insuficiente** y la Fase 11 lo reemplaza.
  Si al escribir la 11 el reemplazo obliga a cambiar los endpoints, la separación dominio/frontera
  de §5.1 no estaba bien hecha y hay que corregir **esta** fase, no la siguiente.
- **La regla 9 del miniproyecto —sin dos citas el mismo día en dos sedes— se plantea y no se
  resuelve bien** sin base de datos. El ejercicio 25 lo traslada al lector; la Fase 11 tiene que
  retomarlo explícitamente y decir si la solución propuesta aguanta.

---

## `11-persistencia.md`

*🗄️ Fase 11 — Persistencia*

- **La regla 9 de la Fase 10** —un paciente no puede tener dos citas el mismo día en dos sedes—
  queda ahora respondible en una consulta con índice, y esta fase debería mostrarlo explícitamente
  al reemplazar el almacén en memoria. Si al implementarlo hubo que tocar los endpoints de la Fase
  10, esa fase tiene un problema de separación y hay que corregirla **allí**.
- **`ROUND_HALF_UP` contra `ROUND_HALF_EVEN`**, que la Fase 08 dejó anotado, sigue sin sitio: aquí
  el dinero se persiste con `Numeric` y el redondeo ocurre en el cálculo. Destino sugerido: una
  📝 en esta fase, junto a la decisión de `Numeric`, o en la 15 cuando se liquide.
- **Las restricciones de exclusión de Postgres** son la respuesta correcta al solapamiento parcial
  de citas y quedan en un ejercicio 🟡 y uno 🔥. Si la Fase 14 no las usa, el curso deja el
  problema del solapamiento resuelto solo a medias — conviene decidirlo al escribirla.
- **La medición es sobre socket Unix local.** Con la base en otra máquina, el castigo del N+1
  crece y la diferencia Core/ORM se vuelve aún más irrelevante. El ejercicio 18 lo traslada al
  lector; el curso debería traer su propio número antes de consolidar `BENCHMARKS.md`.
- **No se midió el ORM contra Hibernate**, que sería la comparación que este perfil quiere de
  verdad. No cabe aquí —haría falta un proyecto Java equivalente— y la Fase 17 solo compara el
  endpoint completo. Queda declarado como lo que el curso **no** responde.

---

## `12-django-y-el-veredicto-web.md`

*🏛️ Fase 12 — Django y el veredicto web*

- **El hash de contraseñas con `sha256`** apareció al escribir la implementación de FastAPI para
  la medición de §6, y es un error de seguridad real que el curso convierte en argumento (§5.4).
  **Conviene que quede claro que esa implementación es de comparación y no de referencia**: si
  alguien la copia, copia el error. Está dicho, y vale la pena verificarlo al revisar la fase.
- **La versión de FastAPI de §6 no tiene CSRF ni paginación**, y está declarado en la tabla. Si
  alguna vez se completa para hacerla "justa", el conteo de líneas cambia **a favor de Django**,
  no en contra: conviene decirlo si alguien propone rehacer la medición.
- **El N+1 vuelve con el ORM de Django**, que sí tiene carga perezosa automática, justo después de
  que la Fase 11 celebrara que SQLAlchemy no la tiene. **No es una contradicción y hay que
  escribirlo así**: son dos decisiones de diseño distintas con costos distintos, y el lector que
  no lo vea explicado va a creer que el curso cambió de opinión.
- **La convivencia de dos frameworks sobre una base** (§5.5) se resuelve con una regla y no se
  mide. Es una decisión de arquitectura con consecuencias reales en las Fases 15 y 16: conviene
  que alguna de las dos la cite y diga si aguantó.
- **El ejercicio 25 termina en "esto lo revisa un abogado"**, y es deliberado: la frontera del
  curso está ahí. Si el track de datos toca alguna vez el habeas data, este ejercicio es su
  entrada natural.

---

## `13-integraciones.md`

*🌐 Fase 13 — Integraciones*

- **El socio mentiroso no tiene solución en esta fase**, y está declarado. La reconciliación que
  §5.4 propone **es** el proyecto 4 de la Fase 15: conviene que esa fase la cite explícitamente y
  cierre el bucle, o el lector se queda con un problema abierto y sin destino.
- **El patrón *outbox* se nombra en un ejercicio 🔥** y es de la Fase 15. Si esa fase no explica
  por qué el reintento no sustituye a la transacción, este ejercicio queda sin respuesta.
- **El envío es en serie a propósito**, y el ejercicio 12 pide la versión concurrente como adelanto
  de la Fase 14. Si la 14 no retoma ese número, el ejercicio queda huérfano.
- **El servidor de pruebas usa `http.server`**, que la propia documentación desaconseja para
  producción. Está bien para el curso y conviene que la Fase 16 lo mencione al hablar de
  seguridad: es el tipo de cosa que alguien deja puesta sin darse cuenta.
- **La automatización de portales sin API** —el track `au`— es trabajo real y frecuente de Áurea, y
  esta fase solo lo nombra. Si ese track se escribe alguna vez, esta es su entrada natural.

---

## `14-concurrencia-y-gil.md`

*🧵 Fase 14 ⭐ — Concurrencia y el GIL*

- **Todas las mediciones son de un portátil de ocho núcleos**, y el dominio de Áurea tiene una
  máquina virtual de dos. Está declarado en §6 y el miniproyecto lo traslada al lector, pero **el
  curso debería traer su propia tabla de dos núcleos** antes de consolidar `BENCHMARKS.md`: es la
  medición que de verdad decide.
- **El free-threading da 1.14× sobre la carga real y 2.27× sobre aritmética pura.** La diferencia
  merece más investigación de la que cabe aquí —¿es `hashlib`, es `Decimal`, es la asignación de
  objetos?— y sería un material excelente para la Fase 16, con el perfilador delante.
- **El solapamiento parcial de citas sigue sin resolverse** (§5.4): la restricción de unicidad
  cubre el mismo minuto y no el rango. Las restricciones de exclusión de Postgres son la
  respuesta, quedaron en un ejercicio de la Fase 11 y en uno de esta. **Si el curso cierra sin
  usarlas, deja el problema resuelto a medias** — conviene decidirlo antes de la Fase 17.
- **Los procesos huérfanos tras un `Ctrl-C`**, que la Fase 05 dejó anotado, vuelven aquí como
  criterio de aceptación del miniproyecto. Si al escribir la 16 aparece un sitio natural para
  cerrarlo del todo, es el momento.
- **El ejercicio 12 de la Fase 13** —notificar a los tres socios en paralelo— se retoma en §5.3 y
  en el ejercicio 25. El bucle queda cerrado; conviene verificar que los números coinciden si
  alguien hace los dos.

---

## `15-el-proceso-nocturno.md`

*🌙 Fase 15 — El proceso nocturno*

- **El hallazgo del punto de control cuadrático** —guardar el número de filas en vez del
  desplazamiento dispara el sobrecosto del 9% al 319%— salió de un error al escribir la medición, y
  es material de `INSTINTOS.md`: *"reanudar no es guardar por dónde vas, es guardar por dónde vas
  de forma que retomar sea constante"*.
- **El orden del tope mensual**, que la Fase 03 dejó anotado y que el ejercicio 23 de esa fase
  cuantificó, **llega aquí a su destino**: un cálculo cuyo resultado depende del orden de
  procesamiento no se puede reanudar a la mitad sin decidirlo. La solución de referencia lo
  resuelve procesando por (aliado, mes) completo, pero **conviene que el enunciado lo diga
  explícitamente** si esta fase se revisa.
- **La reconciliación contra el socio mentiroso**, que la Fase 13 dejó sin destino, encaja aquí
  como un cuarto trabajo nocturno. Esta fase no la construye; si se decide construirla, este es su
  sitio y hay que anotarlo en el enunciado del miniproyecto.
- **La medición es con `sqlite3` local.** Con el punto de control en Postgres remoto, cada
  confirmación es una ida y vuelta por red y el sobrecosto sube. El ejercicio 18 lo traslada al
  lector; el curso debería traer su propio número.
- **`cron` no tiene panel**, y el veredicto de §5.6 lo declara como costo aceptado. La Fase 16 es
  la que tiene que hacerlo llevadero: si al escribirla la visibilidad del cierre no queda
  resuelta, este veredicto queda sin respaldo.

---

## `16-operacion-y-rendimiento.md`

*🔭 Fase 16 — Operación y rendimiento*

- **La fusión se sostiene, y conviene dejar dicho por qué**, porque la propuesta de fases obligaba
  a declararlo: las dos mediciones están **separadas** (§6.1 y §6.2), con sus condiciones propias y
  sus veredictos propios, y el perfilado **no** quedó como nota al pie — tiene su propio bloque, su
  propio competidor y su propia regla. Lo que las une es el método: no se arregla lo que no se
  mide. **No se propone deshacer la fusión.**
- **`py-spy` se documenta y no se mide.** El ejercicio 18 lo traslada al lector; el curso debería
  traer su propio número, incluida la distorsión que introduce `cProfile`, antes de consolidar
  `BENCHMARKS.md`.
- **El free-threading a 1.14× de la Fase 14** merecía un perfil que dijera por qué —¿`hashlib`,
  `Decimal`, la asignación de objetos?— y esta fase tiene las herramientas para responderlo. Si se
  amplía alguna vez, este es el sitio.
- **`http.server` del servidor de pruebas de la Fase 13** queda nombrado allí como algo que no es
  para producción. Esta fase habla de seguridad y **no lo retoma**; es el tipo de cosa que alguien
  deja puesta, y una línea aquí lo cerraría.
- **El volumen de registro proyectado depende de supuestos de tráfico** que Áurea no tiene
  medidos. El número por evento es sólido; la proyección anual del ejercicio 7 es del lector, y
  está dicho así a propósito.

---

## `17-el-duelo-y-el-veredicto.md`

*⚔️ Fase 17 🏁 ⭐ — El duelo y el veredicto*

- **La fusión se sostiene, y conviene dejarlo dicho** porque la propuesta de fases obligaba a
  declararlo: **el miniproyecto es la defensa** y **el veredicto general tiene su propia sección
  numerada (§6.b)**, con sus tres partes —dónde ganó Python, dónde habría ganado Java, y las dos
  decisiones equivocadas—. No quedó como párrafo de cortesía al pie de la tabla. **No se propone
  deshacer la fusión.**
- **GraalVM native-image es el hueco más importante de §6**, porque cambiaría por completo la
  columna del arranque en frío y es la respuesta obvia de cualquier lector que sepa de Spring
  moderno. El ejercicio 17 lo traslada; **el curso debería traer su propio número**.
- **La confesión del generador de carga** —390 req/s falsos contra 13.834 reales— es material de
  `INSTINTOS.md` y probablemente la lección metodológica más transferible de las dieciocho fases.
- **Todo el duelo es en un portátil de ocho núcleos**, y §6.b lo reconoce como la debilidad
  metodológica mayor del curso. La tabla de dos núcleos (ejercicio 18) debería producirse antes de
  dar el material por publicado.
- **La decisión de que el histórico del CLI fuera `sqlite3`** queda reconocida como equivocada en
  §6.b. Si alguna vez se revisa el curso, la corrección no es cambiar la Fase 06 —donde `sqlite3`
  es correcto y está bien medido— sino que **la Fase 11 migre el histórico explícitamente**, y que
  esa migración sea material: es exactamente el tipo de decisión que un sistema real tiene que
  revisar.

---

## `ia01-el-modelo-de-acceso-de-un-llm.md`

*🤖 ia01 — El modelo de acceso de un LLM*

- **La medición de la sección 6 está en `⏳`.** Cuando se corra, su fila entra a `BENCHMARKS.md`
  con la fecha de la tarifa al lado del costo, y el umbral del veredicto reemplaza la expectativa.
  Hasta entonces, ninguna sección del track cita un número de aquí.
- 🪦 **El banco de veinte preguntas ya existe:** `src/ia01-…/generar_preguntas.py`, semilla fija,
  sin un solo dato clínico. Se regenera; el `.jsonl` no se versiona.
- **La deuda 💸 del `Protocol` de proveedores se paga en `ia06`.** Anotado allí para que no se
  pierda; el ejercicio 9 la anticipa a propósito.
- **`INSTINTOS.md` gana un reflejo nuevo:** *"reintento cualquier fallo de red"* → en un servicio
  con tarifa por token, el reintento es una compra. Va con el número del ejercicio 16 cuando
  alguien lo corra.
- **La caché de prompt se nombra dos veces aquí y no se explica.** Es correcto —es de `ia08`—,
  pero hay que verificar al escribir `ia08` que la promesa se cumple y que la medición usa
  `cache_read_input_tokens` como evidencia, no como adorno.

---

## `ia02-salida-estructurada.md`

*🧾 ia02 — Salida estructurada y el contrato del modelo*

- **La medición de la sección 6 sigue en `⏳`**, pero ya tiene sus dos insumos: 🪦
  `src/ia02-…/generar_circulares.py` produce las cien circulares y sus **197 reglas esperadas**,
  derivadas del texto que escribe —así el corpus y su anotación no pueden discrepar— con un 22% de
  reglas que exigen `no_dice`. Las 197 citas esperadas se verifican contra el texto generado y las
  197 pasan por `_normalize`, comillas tipográficas incluidas.
- **La deuda 💸 del costo por intento se paga en `ia08`.** Anotada allí.
- **La inyección desde el documento (ejercicio 24) merece más que un ejercicio.** Es el vector de
  ataque propio de este track y aquí solo se roza. **Destino: sección de guardrails en `ia07`, y
  una comprobación en el checklist de `ia08`.** No es un apéndice: es contenido de dos secciones
  que ya existen.
- **`INSTINTOS.md` gana el reflejo más valioso de la sección:** *"todo campo va `@NotNull`"* → en
  un contrato con un modelo, cada campo obligatorio es una invitación a inventar. Va con el número
  del ejercicio 2 cuando alguien lo corra.
- **Verificar al escribir `ia05`** que el índice de la cita del ejercicio 9 se usa de verdad para
  la atribución, o el ejercicio queda huérfano.

---

## `ia03-tool-calling-y-el-bucle-de-agente.md`

*🛠️ ia03 — Tool calling y el bucle de agente*

- **La medición de la sección 6 está en `⏳`**, y su fila 4 —formulario más SQL— puede cambiar el
  alcance de `ia07`. Hay que correrla **antes** de escribir Recepción asistida, no después.
- 🪦 **`solicitudes_whatsapp.jsonl` ya se genera:** `src/ia03-…/generar_solicitudes.py`, treinta
  solicitudes con faltas y sin fecha explícita, **cada una etiquetada con la clase de dificultad
  que aporta** —fecha relativa, sede sin agenda, dos peticiones, urgencia…— para poder leer la
  medición por clase en vez de en agregado. Lo reusa `ia07`.
- **`agenda_client.py` se da por existente** porque viene de la Fase 13, pero `hold_slot` y la
  tabla de propuestas con vencimiento **son nuevos**: no estaban en el camino base. Hay que
  verificar al escribir `ia07` que la migración quedó documentada donde corresponde, o el lector
  se encuentra un método que nadie creó.
- **El ejercicio 25 —caché de prompt sobre la lista de herramientas— es material de `ia08`** y
  aquí solo se anticipa. Verificar que `ia08` lo recoge con su número.
- **`INSTINTOS.md` gana dos reflejos:** *"expongo la operación que el usuario quiere"* → la
  herramienta que muta necesita clave de idempotencia derivada y una persona en el medio; y *"la
  firma es el contrato"* → aquí el contrato es la prosa, y cada frase que falta cuesta un turno.

---

## `ia04-embeddings-y-busqueda-semantica.md`

*🧭 ia04 — Embeddings, búsqueda semántica, y cuándo Postgres gana*

- **La medición de la sección 6 está en `⏳` y es la que más puede cambiar el track.** Si la
  híbrida no le saca ventaja a la léxica, `ia05` tiene que reescribirse alrededor de ese
  resultado. **Correrla antes de empezar `ia05`.**
- 🪦 **El corpus y las preguntas anotadas ya se generan:** `src/ia04-…/generar_corpus.py` produce
  24 documentos con estructura de cláusulas, su manifiesto y las cincuenta preguntas con su
  fragmento correcto y su etiqueta. La etiqueta se asigna **por construcción** —cada plantilla sabe
  qué clase de consulta produce—, que es legítimo con un corpus generado y **no lo sería** con uno
  real. Un tercio de los documentos son versiones derogadas casi idénticas, para el miniproyecto de
  `ia05`. Los 24 pasan por el troceador de `ia05` sin que ninguno quede sin estructura.
- **La deuda 💸 del umbral único y global se paga en `ia06`.**
- **El troceado se da por hecho aquí y se construye en `ia05`.** El ejercicio 12 mide su efecto y
  probablemente descubra que es la variable dominante; si es así, `ia05` tiene que darle una
  sección propia y no un párrafo.
- **`INSTINTOS.md` gana el reflejo de la sección:** *"si no encuentra, devuelve vacío"* → una
  búsqueda por similitud nunca devuelve vacío, y sin umbral el sistema no puede decir "no sé".
- **Verificar al escribir el track `db`** que la sección de vectoriales dedicadas no contradice la
  decisión de `pgvector` de aquí, y que cita esta medición en vez de repetirla.

---

## `ia05-normarag.md`

*📚 ia05 — Proyecto · NormaRAG*

- **La medición de la sección 6 está en `⏳`**, y su fila 3 —devolver la cláusula sin generar—
  puede recortar la mitad del proyecto. Correrla antes de conectar NormaRAG a nada.
- **La deuda 💸 de la vigencia se paga en el miniproyecto de esta misma sección**, criterio 5. Es
  la única del track que se paga dentro de su sección y está hecho a propósito.
- **El OCR queda fuera y con su agujero medido.** Cuando el track `ar` exista, su sección de PDF
  tiene que citar el informe de cobertura de aquí en vez de repetir el problema.
- **La detección mecánica de contradicción (ejercicio 17 y criterio 4)** puede no ser viable con
  falsos positivos aceptables. Si al escribir la solución de referencia se confirma, hay que
  suavizar el criterio 4 y decirlo, en vez de dejar un miniproyecto que no se puede aprobar.
- **`INSTINTOS.md` gana el reflejo de la sección:** *"cabe en el contexto, luego lo mando"* → el
  contexto grande no reemplaza la recuperación, y sobre todo no permite verificar la procedencia.
- **Verificar al escribir `ia07`** si Recepción asistida debe llamar a NormaRAG como herramienta.
  La respuesta probablemente sea que no para preguntas de cobertura de un paciente concreto —ahí
  hay datos que no deben viajar—, y esa decisión hay que tomarla explícitamente.

---

## `ia06-evaluacion.md`

*⚖️ ia06 — Evaluación, regresiones y el juez que también se equivoca*

- **La medición de la sección 6 está en `⏳`**, y su resultado puede cambiar el track: si ningún
  juez supera 0.6 de kappa, `ia07` y `ia08` tienen que apoyarse en juicio humano asistido en vez de
  en evaluación automática, y hay que decirlo allá.
- **Se pagan dos deudas 💸 y se declara una nueva:** la comparación por pares se paga en `ia08`,
  donde hay dos versiones que comparar.
- 🪦 **`evalset.jsonl` ya se genera** desde el manifiesto del corpus: cincuenta casos, quince de
  abstención en dos sabores —aseguradora inexistente y, el difícil, código inexistente en una
  aseguradora que sí está—. Las referencias se derivan del hecho que generó el documento, no las
  escribe un modelo.
- ⏳ **`juicios_humanos.jsonl` sigue pendiente, y va a seguirlo:** es el único insumo del track que
  un script no puede producir. `preparar_juicios.py` deja la plantilla con el campo vacío y
  `bench_judges.py` **se niega a correr** si encuentra alguno sin llenar. Son veinte minutos con la
  rúbrica delante; fabricarlos con un modelo daría un kappa alto y vacío.
- **El número del ejercicio 16 —cuántos casos hacen falta— debería subir a `BENCHMARKS.md`** aunque
  no sea una medición de rendimiento: es el que limita todo lo que el track puede afirmar sobre
  calidad.
- **`INSTINTOS.md` gana el reflejo más difícil del track:** *"una prueba intermitente es una prueba
  rota"* → aquí la variación es la propiedad; se acota con `n` corridas y un intervalo, y el
  reintento es una alfombra.
- **Verificar al escribir `ia08`** que la comparación de frameworks usa este conjunto de evaluación
  y no uno nuevo. Comparar LangChain contra el bucle propio con conjuntos distintos no probaría
  nada.

---

## `ia07-recepcion-asistida.md`

*💬 ia07 — Proyecto · Recepción asistida*

- 🪦 **`sintomas.jsonl` ya se genera** (`generar_sintomas.py`), y su fila de la medición **ya está
  corrida**: el guardrail léxico deja pasar veinte de cuarenta. Las otras tres filas llaman al
  modelo y siguen en `⏳`.
- **Al generar el conjunto aparecieron dos huecos de conjugación** —`"rompió"`, `"inflamó"`— que la
  revisión a ojo no vio. Está corregido y fijado con prueba, y es el argumento de por qué el
  conjunto de medición se escribe antes que el código y no después.
- **La deuda 💸 del clasificador se paga en el ejercicio 14**, y su resultado puede cambiar el
  diseño: si baja los falsos negativos de forma clara, entra al cuerpo de la sección en una
  revisión futura y se dice.
- **El umbral de falsos negativos aceptables no lo decide el curso.** La sección lo deja explícito
  y el ejercicio 24 lo convierte en un documento firmable. Al escribir `ia08` hay que verificar que
  el veredicto del track no se lo salta.
- **`INSTINTOS.md` gana dos reflejos:** *"la regla va en el prompt"* → el prompt orienta, el código
  garantiza; y *"optimizo la tasa de éxito"* → con costos asimétricos, el agregado esconde el error
  caro. Van con los números del ejercicio 16 cuando alguien los corra.
- **La omisión declarada de la sección 6 —que los mensajes de prueba los escribió el autor— es la
  más importante del track.** `ia08` tiene que recogerla con el registro de producción, o el
  proyecto se despliega midiendo la imaginación de quien lo escribió.

---

## `ia08-produccion-y-el-veredicto.md`

*⚖️ ia08 — Producción, y el veredicto del track*

- **Las dos mediciones de la sección 6 están en `⏳`**, y la 6.2 es la más cara de producir del
  track: implementar la misma tarea en tres frameworks para poder compararla honestamente es
  trabajo de días. Si solo se hace una, que sea la 6.1, que es barata y cambia decisiones.
- **Se paga la deuda 💸 de `ia06`** (comparación por pares) y **se declara la última del track**:
  el presupuesto en memoria, que se paga en el criterio 3 del miniproyecto.
- **El veredicto de la §6.3 está escrito antes de que existan los números que lo sostienen**, y eso
  está dicho en su texto. **Cuando se corran las mediciones de `ia04`, `ia05` y `ia07`, hay que
  volver aquí** y reescribirlo con las cifras — o contradecirlo, que sería el mejor resultado
  posible para el curso.
- **La omisión declarada de `ia07` —que los mensajes de prueba los escribió el autor— se recoge
  aquí** con el criterio 6 del miniproyecto, que es el procedimiento de revisión humana. Verificar
  que quien escriba el track `ui` no lo convierta en un panel que exponga el texto del paciente.
- **`BENCHMARKS.md` gana dos filas más y el resumen del track.** Y `INSTINTOS.md`, el reflejo de la
  caché de prefijo, que es el más transferible de esta sección.
- **El track `ds` hereda dos cosas de aquí:** el arnés de presupuesto —entrenar también cuesta— y
  la disciplina del veredicto. Verificar que `ds09` cierra con la misma estructura y no con un
  resumen.

---

## `ds01-numpy-y-el-modelo-vectorizado.md`

*🧮 ds01 — NumPy y el modelo vectorizado*

- 🪦 **El ejercicio 16 ya tiene su archivo:** `src/ds01-…/ejercicio_16_lento.py`, con sus dos
  defectos sembrados —una comparación de cadenas por fila dentro de lo que dice ser vectorizado, y
  un `astype` dentro del bucle— y sin una sola pista en los comentarios.
- **El ejercicio 24 —la comparación contra Java— es material de `BENCHMARKS.md`**, no solo un
  ejercicio. Si alguien lo corre, la entrada entra al consolidado con sus condiciones.
- **La conversión de la sección 6 se puede bajar mucho** (ejercicio 15) y eso cambiaría el
  veredicto del umbral de reúso. Si alguien lo hace, **se corrige la sección 6 y se anota el
  porqué**, no se deja la cifra vieja.
- `INSTINTOS.md` gana el reflejo de la sección: *"vectorizar siempre gana"* → **gana el cálculo,
  y muchas veces pierde el programa**, porque la conversión se paga cada vez.
- 🪦 **La pauta de Áurea está revisada contra el resto de la ficción y cuadra.** Son 6.059
  millones de pesos en 27 meses —unos 224 al mes, que parecían muchos— contra **83.378 millones de
  valor contratado**: un **7,3%**, que para una compra electiva y cara es una cifra sana. El costo
  de adquisición global es de **999.059 COP sobre un plan medio de 13,7 millones**. Lo que se ve
  feo en la tabla de la sección 4 no es el negocio: es la atribución al último toque, que le carga
  a TikTok un tercio del gasto y le acredita 215 pacientes.

---

## `ds02-pandas.md`

*🐼 ds02 — pandas y el modelo de DataFrame*

- **El ejercicio 24 —la misma pregunta contra Postgres— es la primera fila de la tabla de
  `ds03`.** Si alguien lo corre antes, ese número entra a `ds03` §6 y hay que reconciliar las
  condiciones: la medición de aquí excluye la lectura de disco y la de `ds03` no puede.
- 🪦 **`ds03` mantuvo la costumbre:** sus cuatro tamaños chicos son recortes reales del conjunto
  —un mes, un trimestre, un año y la historia completa— y solo los dos grandes son sintéticos, y
  lo declaran. Esta medición sigue siendo la única que no necesita **ningún** tamaño inventado
  para tener algo que medir.
- **La columna de RSS varía unos ±4 MB entre corridas.** La tabla publica una corrida, y eso es
  suficiente para una relación de 2× pero no lo sería para una de 10%. Si alguna vez la
  diferencia entre dos variantes baja de ese margen, hay que repetir y reportar dispersión.
- `INSTINTOS.md` gana el reflejo de la sección: *"recorro las filas y decido"* → **la decisión es
  una máscara sobre la columna**, y `apply(axis=1)` es el bucle disfrazado que cuesta 24×.
- **El `SettingWithCopyWarning` ya no existe y medio internet todavía lo explica.** Vale la pena
  un ejercicio 🔥 en la carta (`track db` o similar) sobre migrar código de pandas 1.x que
  dependía de las vistas.

---

## `ds03-polars-y-el-modelo-lazy.md`

*🦆 ds03 — Polars, DuckDB y el modelo lazy*

- **Falta la celda Polars sobre Parquet** en la tabla 6.1 (ejercicio 12). Se dejó fuera para
  que la comparación de formatos tuviera un solo motor y no dos variables a la vez, pero es la
  celda que más gente va a querer. Si alguien la corre, entra a la tabla **con esa nota**.
- **El ejercicio 22 —el consolidado contra Postgres— es una entrada de `BENCHMARKS.md`**, no
  solo un ejercicio. Necesita declarar si cuenta el costo de cargar los datos, y esa decisión
  cambia el resultado.
- **La sección 5.5 encontró algo que vale para todo el curso**: una medición puede depender de
  qué **otras** dependencias hay instaladas. Está en `INSTINTOS.md` con los reflejos de método.
- **El umbral de 30.000–115.000 filas se estrechó hasta donde alcanzaban los datos reales.**
  Afinarlo más exigiría tamaños intermedios sintéticos, y el curso prefirió un rango honesto
  sobre un punto inventado. Si alguien quiere el punto exacto, que lo mida y diga cómo.
- `INSTINTOS.md` gana el reflejo de la sección: *"lazy es lazy loading"* → **aquí perezoso
  significa planear antes de leer**, que es lo contrario del N+1 que te enseñó a temerle.

---

## `ds04-embudo.md`

*💸 ds04 — Proyecto · Embudo*

- **El ejercicio 24 —el experimento de incrementalidad— es el único que resolvería la
  pregunta de la sección**, y cuesta plata de pauta real. Si alguna vez se diseña completo,
  merece ser una sección propia y no un ejercicio: es donde el curso pasaría de describir a
  intervenir.
- **El costo de la valoración gratuita no está en el conjunto** y es el hueco más grande del
  informe: silla y tiempo de dos especialistas por cada lead que llega a `valoracion_asistida`
  —11.114 de ellos—. Agregarlo al generador cambiaría todos los CAC hacia arriba y de forma
  desigual entre canales. **Decisión pendiente:** si se agrega, se agrega en el generador y se
  vuelve a correr esta sección entera.
- 🪦 **La zona y la especialidad de los aliados ya no son la misma partición.** Nacieron las
  dos del índice del aliado —`i % 5` y `(i * 3) % 5`— y sobre veintitrés aliados partían el
  conjunto igual, así que agrupar por una o por otra daba la misma tabla y la pregunta de la
  §6.1 no se podía hacer. La zona ahora se sortea, y hay una prueba en el generador.
- **El intervalo bootstrap tarda 12 segundos** con 200 remuestreos, casi todo en recalcular
  créditos. El ejercicio 10 pide bajarlo; si alguien lo logra, sube a 2.000 remuestreos y se
  reescriben los intervalos de la sección 6.
- `INSTINTOS.md` gana el reflejo de la sección: *"cada hecho tiene un dueño"* → **la
  conversión no tiene dueño**, y el `GROUP BY` que se lo asigna toma una decisión de negocio
  sin avisar.

---

## `ds05-visualizacion.md`

*📊 ds05 — Visualización, y cuándo una tabla gana*

- **La medición 6.2 está en `⏳` y es la única del track que necesita personas.** El
  protocolo está completo; lo que falta son cinco voluntarios y media hora. Es el ejercicio
  22 y también una entrada pendiente de `BENCHMARKS.md`.
- **Falta la celda de Polars en la tabla de `ds03`** y falta aquí la de `pandas.plot()`
  (ejercicio 11). Las dos son celdas que la gente va a buscar.
- **La paleta de Áurea no está en la historia de la empresa**, se definió aquí. Si alguna vez
  se agrega a `00-historia-de-aurea.md`, los cinco colores tienen que salir de allí y esta
  sección citarlos, no definirlos.
- **El tablero de estacionalidad del ejercicio 21 es el contraejemplo de esta sección** —el
  caso donde el gráfico gana claro— y merecería estar en el cuerpo y no en un ejercicio. Si
  alguien lo escribe, considerar moverlo a la sección 6 como segunda comparación.
- `INSTINTOS.md` gana el reflejo de la sección: *"la presentación es la capa final"* → **es
  donde se pierde la información**, y elegir el gráfico simple es tirar el hallazgo.

---

## `ds06-notebooks-y-reproducibilidad.md`

*📓 ds06 — Cuadernos y reproducibilidad*

- **El "1 de 6" es una demostración, no una estadística.** El ejercicio 22 pide el número
  sobre un repositorio real; si alguien lo trae, entra a `BENCHMARKS.md` **con sus
  condiciones** y esta sección lo cita en vez de su propio número.
- 🪦 **La detección de estado oculto sin ejecutar ya la hace `ruff`**, con `F821`, y se
  descubrió al linterar la carpeta generada. Está en la sección 5.4 como 💡 y cambió el
  ejercicio 7, que ahora pide comparar la versión propia con la de la herramienta en vez de
  escribirla a ciegas. Lo que sigue abierto es cuánto de los otros cuatro defectos se puede
  detectar estáticamente.
- **marimo resuelve uno de los cinco defectos** y el texto lo dice. Falta medir el otro lado
  de esa moneda: cuánto ecosistema se pierde. El ejercicio 20 lo pide y nadie lo ha hecho.
- 🪦 **El `temporary_kernel` que esta sección tuvo en su primera versión no existe más.**
  Instalaba una especificación de kernel en un directorio temporal para "no ensuciar la
  máquina", y resultó que `nbclient` **ignora** el argumento con que se le pasaba —lo avisa
  con un `DeprecationWarning` de `traitlets` que es fácil no leer— y que el kernel venía
  desde el principio de `ipykernel`. Treinta líneas de maquinaria inútil con una explicación
  convincente y falsa: se reemplazó por `require_kernel`, que son ocho y dicen la verdad.
- `INSTINTOS.md` gana el reflejo de la sección: *"los cuadernos son un desastre"* → **medio
  correcto**, y la mitad buena es el bucle de exploración que estás dejando sobre la mesa.

---

## `ds07-scikit-learn.md`

*🎯 ds07 — scikit-learn y la línea base honesta*

- **El ejercicio 16 es el experimento que esta sección no pudo hacer**: introducir deriva en el
  generador y volver a correr la tabla 6.2. Si alguien lo hace, **el resultado cambia el
  veredicto 4** y hay que reescribirlo. Es el pendiente más importante de la sección.
- **El ejercicio 24 —el gradiente potenciado— debería estar en el cuerpo.** Es el competidor
  real de `ds08`, no la red neuronal, y dejarlo fuera le regala a la red una comparación
  cómoda. Si alguien lo mide, entra a la tabla 6.1 y `ds08` tiene que reaccionar.
- **La calibración no está medida** y `ds08` la necesita para la discusión del
  sobreagendamiento: sin saber si un 0,3 significa 30%, no se puede decidir cuántos pacientes
  de más caben en el jueves.
- **El paciente sin historial recibe el mismo puntaje que el paciente perfecto** (ejercicio
  21). Es una decisión de diseño que la sección no toma y que el miniproyecto obliga a
  defender. Merece una variable propia —"primera cita"— y medirla.
- `INSTINTOS.md` gana el reflejo de la sección: *"es una función: entra un caso, sale una
  predicción"* → **no hay correcto, hay mejor o peor que una línea base**, y la línea base se
  escribe primero.

---

## `ds08-ausentismo.md`

*🧠 ds08 — Proyecto · Ausentismo*

- **El gradiente potenciado sigue sin medirse**, y es el competidor que de verdad importaba
  para datos tabulares de este tamaño. Está como ejercicio 16 aquí y 24 en `ds07`. **Si alguien
  lo corre y le gana a los cuatro, el veredicto de esta sección se reescribe**, y es
  perfectamente posible.
- **El ejercicio 23 —darle cuatro interacciones al generador— es el que convierte el veredicto
  en un umbral.** Hoy la sección dice "aquí la red no compra nada"; con ese experimento podría
  decir "a partir de N interacciones, sí". Es el pendiente más valioso.
- **El `COLLISION_RATIO` es un número inventado y declarado.** Tres veces peor es un valor de
  partida para poder hacer la cuenta, no una medición de Áurea. El ejercicio 19 pide diseñar
  cómo estimarlo; mientras tanto, toda la sección 6.3 depende de él y la 6.3 lo dice.
- **La sección 6.6 no tiene código que la haga cumplir.** El ejercicio 21 pide convertirla en
  pruebas, y debería ser parte del cuerpo: una política ética que no se puede comprobar es una
  declaración de intenciones.
- `INSTINTOS.md` gana el reflejo de la sección: *"si el modelo más complejo gana, uso el
  modelo más complejo"* → **la pregunta es por cuánto gana y qué le pasa a esa ventaja si le
  escribes al competidor una columna que el dominio ya conocía**.

---

## `ds09-servir-el-modelo.md`

*🚢 ds09 — Servir el modelo, y el ⚖️ veredicto del track*

- **La detección de deriva no se puede medir con este conjunto** —`ds07` §6.2 lo demostró— y
  es lo que falta para que el ciclo de la sección 5.5 esté completo. El ejercicio 17 pide
  diseñarla simulando la deriva; el ejercicio 23 de `ds08` pide el generador que la produce.
  **Los dos juntos son una sección propia**, y probablemente la décima del track si alguna vez
  se amplía.
- **El backend "a mano" del ejercicio 10** —seis multiplicaciones y una sigmoide, sin
  dependencias— debería estar en la tabla de la sección 6. Es el espíritu del track y su
  ausencia le regala a ONNX una comparación cómoda, igual que la ausencia del gradiente
  potenciado se la regaló a la red en `ds08`.
- **La medición no incluye concurrencia.** 500 peticiones secuenciales contestan una pregunta
  y no la otra; el arnés de la Fase 17 existe y podría cerrarla.
- 🪦 **`shared.py` de esta sección tuvo que llamarse `upstream.py`.** `ds08` ya tenía un
  módulo con ese nombre, el directorio del script va primero en `sys.path`, y el de aquí
  tapaba al de allá con un `ImportError` que no menciona el archivo culpable. Es el costo real
  del atajo de `sys.path` —**el espacio de nombres pasa a ser plano entre las tres carpetas**—
  y quedó documentado en el módulo.
- `INSTINTOS.md` gana el reflejo de la sección: *"serializar es serializar"* → **un artefacto
  de modelo es un ejecutable disfrazado de dato**, y el reflejo que sí tienes de la JVM no se
  dispara porque el `.pkl` no se siente como código.
