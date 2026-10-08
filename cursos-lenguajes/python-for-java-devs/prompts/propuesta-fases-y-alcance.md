# 🗺️ Propuesta de fases y alcance
## Python para desarrolladores Java senior

> ✅ **Estado: ejecutado.** Las 18 fases que este documento especifica **están escritas y
> publicadas** en la raíz del curso, con sus mediciones, sus miniproyectos y sus 450 ejercicios.
> Lo que sigue vale como **registro de las decisiones**: manda sobre cualquier revisión del camino
> base, y ya no describe trabajo pendiente. Donde el texto dice "se escribirá" o "se calculará",
> léase en pasado — y donde una previsión no se cumplió, está anotado.

> **Estado de las decisiones: cerrado.** Las siete que estaban en discusión quedaron resueltas y
> están en §9 con su porqué y con lo que se descartó a cambio. **La secuencia de 18 fases de §4
> es la numeración oficial del curso**; cambiarla a partir de aquí obliga a renumerar los
> archivos, así que se hace con la misma ceremonia que un cambio de alcance, no por comodidad
> al redactar.

Junto con `alcance-del-proyecto.md`, es la fuente de verdad estructural del curso.

---

## 1. Lo que hace distinto a este curso

Tres rasgos que lo separan de un curso técnico corriente, y que explican casi todas las
decisiones de abajo.

**El lector no aprende a programar: aprende a elegir el registro.** La pregunta que ordena
todo el material es *¿esto es un script, una herramienta o una aplicación?*, y el curso se
organiza para que el lector se equivoque en las dos direcciones a propósito y pague el costo
con números.

**No hay apéndices.** Todo lo que en otro curso sería material de consulta es aquí una fase o
una sección de fase. La razón completa está en `alcance-del-proyecto.md` §6; la consecuencia
práctica es que el ambiente de trabajo **es la Fase 00 entera** y no una nota al pie.

**Cada fase cierra con un miniproyecto difícil.** Ocupa el lugar del cuaderno de incidentes de
los cursos de legacy. La audiencia resuelve leyendo documentación y mirando ejemplos, así que
la unidad de práctica es un encargo completo, no un ejercicio de rellenar huecos. El formato y
su prueba de calibración están en [`formato-de-miniproyectos.md`](formato-de-miniproyectos.md).

> 📝 **Y una nota de método.** Aquí la estructura viene **antes** que el contenido: el alcance,
> la guía de estilo, la plantilla y el formato de miniproyectos ya están escritos, y este
> documento es el último eslabón que falta para empezar a redactar. Ordenar sobre la marcha es
> la alternativa, y produce un temario que hay que renumerar tres veces.

---

## 2. ✅ Decisiones cerradas

No se rediscuten en los chats siguientes; se dan por hechas.

| Pregunta | Decisión | Qué cambia |
|---|---|---|
| Eje del curso | **Script ⇄ herramienta ⇄ aplicación** | La estructura en tres bloques, y la frontera como pieza central |
| Apéndices | **No hay** | El ambiente es la Fase 00; lo que no quepa en una fase se queda fuera con su razón escrita |
| Práctica por fase | **Un miniproyecto obligatorio**, difícil | Sustituye al cuaderno de incidentes; ejercicios bajan a 20-25 |
| Dominio | Todo sale de `00-historia-de-aurea.md` | Ninguna fase lo amplía por su cuenta |
| Gestión de entorno | **`venv` + `pip`** en el Bloque A; comparación medida en la Fase 07; **`uv`** de ahí en adelante | conda se gana su lugar en el track de datos, no en el camino base |
| El duelo final | **Contra Spring Boot 3**, un solo endpoint | Sin Go ni Quarkus: una sola comparación, la que el lector usa |
| Empresa | **Áurea**, decisión cerrada | La alternativa evaluada se descartó y su documento salió de la carpeta |
| Editores | **VS Code (principal) + PyCharm, capa gratuita (alternativo)** | Los dos en la Fase 00, sin apéndice. La Community Edition ya no existe: ver `alcance-del-proyecto.md` §9 |
| Plataformas | **Windows 11, Linux amd64, macOS Apple Silicon** | Las tres se cubren en el cuerpo, sin nota al pie |
| Intérprete | **Python 3.14.x**, piso 3.13 | Fijado en `alcance-del-proyecto.md` §9 |
| Idioma del código | **Inglés**; comentarios y mensajes en español | Guía §5 |
| Comparaciones | **Ninguna sin número** | Cada fase produce una medición 📏, y la excepción se justifica |
| Número de fases | **18**, con cuatro fusiones deliberadas | §4 y §9.1; las fusiones traen su mitigación escrita |
| Calendario | **Bandas por bloque**, no horas por fase | ✅ Calculadas y publicadas en `0-ESTRUCTURA-CURSO.md`: **100–150 h** en total (A 40–60, B 15–25, C 45–65) |

---

## 3. 🧱 Los tres bloques

```text
Bloque A   Un archivo. Stdlib pura. Sin dependencias, sin pyproject, sin capas.
Bloque B ⭐ La frontera: cuándo un script deja de ser un script.
Bloque C   Herramientas y aplicaciones. El ecosistema completo.
```

**El Bloque A hace dos cosas a la vez.** Rompe el reflejo de *"agrego una dependencia para
parsear una fecha"* —que en el mundo Maven es gratis y en Python se paga caro— y demuestra que
la stdlib **es** el reemplazo del shell: `pathlib`, `subprocess`, `csv`, `json`, `argparse`,
`sqlite3`, `zipfile`, `http.server` vienen en la caja. Un senior de Java no tiene ni idea de
cuánto viene en la caja.

**El Bloque B es la pieza central del curso.** No es un trámite de empaquetado: es el momento
en que el lector aprende a reconocer que su script cruzó una línea, y a migrarlo sin
reescribirlo. Si el curso funciona, esa fase es la que el lector cita tres años después.

**El Bloque C es donde Python compite de frente** con lo que el lector ya sabe hacer, y donde
las mediciones dejan de ser curiosidades y empiezan a decidir arquitecturas.

> 🧭 **Lo que no se replica: la frontera por versión.** En Go, empezar en 1.13 tenía un pago
> pedagógico real. En Python el salto 3.8 → 3.14 da para dos secciones —`match`, `TaskGroup`,
> `ExceptionGroup`, PEP 695, `tomllib`, free-threading—, no para ocho fases. Forzarlo sería
> nostalgia sin pago.

---

## 4. 🪜 La secuencia — 18 fases

> 🧭 **Esta secuencia se diseñó desde las necesidades de Python**, no calcando el temario de
> otro lenguaje. La prueba está en las tres fases que solo tienen sentido aquí:

- **La frontera de Python es el empaquetado.** En un lenguaje que compila a un binario, la
  frontera sería la versión del compilador o el modelo de módulos; aquí es el momento en que un
  script deja de caber en un archivo, y por eso el Bloque B es donde vive la tesis.
- **Python no entrega un binario y se acabó la conversación.** Por eso hay una fase entera —la
  09— dedicada a **entregarle la herramienta a alguien que no es ingeniero**, que es la que más
  se parece al trabajo real del lector después del curso.
- **Python tiene dos registros web legítimos.** La fase 12 existe para que la comparación entre
  FastAPI y Django se viva en vez de leerse.
- **El GIL.** No hay nada que traducir desde Go, donde la concurrencia es la característica de
  portada. Aquí es una fase ⭐ con medición obligatoria.
- **Y lo que allá era fase y aquí no lo es:** Mongo, caché y el resto del panorama de
  persistencia se fueron al track `db`; el panorama de gestores, al track `pk`. En un curso
  cuyo eje es el registro, una fase por producto diluye la tesis.

### Bloque A · el registro *script* — un archivo, stdlib pura, cero dependencias · **7 fases**

| # | Fase | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|
| 00 | 🛠️ Ambiente, editores y el mapa del ecosistema | "el IDE me resuelve el entorno" | — |
| 01 | 🧬 El modelo de datos: todo es objeto, mutabilidad, identidad ⇄ igualdad | `==` contra `equals`; el argumento por defecto mutable | **nace el CLI** |
| 02 ⭐ | 🔁 Secuencias perezosas: iteradores, generadores, `itertools` | construir la lista completa antes de recorrerla | CLI |
| 03 | 🎩 **Python sin ceremonia**: funciones de primera clase, closures, decoradores, `dataclass`, `Protocol`, dunder | la clase con un solo método, la herencia profunda, el `AbstractBase` | CLI |
| 04 | 💥 Errores y recursos: EAFP, context managers, `ExceptionGroup` | comprobar antes en vez de intentar; el `catch` que se traga todo | CLI |
| 05 ⭐ | 🐚 El shell con esteroides: `pathlib`, `subprocess`, señales, `argparse` | `shell=True` y concatenar cadenas | CLI |
| 06 | 📦 Formatos en la caja: `csv`, `json`, `tomllib`, `sqlite3`, `zipfile` | buscar una biblioteca para lo que ya viene | CLI |

⚠️ **La Fase 03 es la más densa del curso y se sabe desde ahora.** Fusiona funciones y objetos
porque atacan el mismo reflejo —la ceremonia—, y esa unidad es lo que la justifica. Al
escribirla hay dos reglas extra: el 🪞 es uno solo y compartido, y el miniproyecto ataca el
reflejo conjunto, no cada mitad por su lado. Si al redactarla no cabe, la fusión se deshace y
se renumera, no se recorta el contenido.

### Bloque B · la frontera — donde vive la tesis · **3 fases**

| # | Fase | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|
| 07 ⭐ | 🚪 **Cuándo deja de ser un script**: `pyproject.toml`, layout `src/`, el refactor del Bloque A, y los gestores medidos | empezar por el proyecto en vez de terminar en él | **el CLI migra** |
| 08 | 🔎 **El contrato del código**: tipado gradual estricto y `pytest` | creer que el verificador es el compilador; traducir JUnit línea por línea | CLI |
| 09 ⭐ | 🎁 **Entregarle la herramienta a Patricia**: distribución para quien no es ingeniero | "que se instale Python y clone el repo" | CLI |

### Bloque C · el registro *aplicación* · **8 fases**

| # | Fase | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|
| 10 | ⚡ FastAPI y la validación en el borde | validar dentro del servicio en vez de en la frontera | **nace la API** |
| 11 | 🗄️ Persistencia: SQL directo, Core contra ORM, migraciones | asumir que el ORM es Hibernate | API |
| 12 | 🏛️ Django, y ⚖️ el veredicto de los dos registros web | creer que son dos calidades y no dos registros | **nace el back-office** |
| 13 | 🌐 Integraciones: HTTP saliente, resiliencia, idempotencia, webhooks | el reintento que duplica el cobro | API |
| 14 ⭐ | 🧵 Concurrencia y el GIL: hilos, procesos, `asyncio`, free-threading | `synchronized` cuando el estado vive en Postgres | los tres |
| 15 | 🌙 El proceso nocturno: lotes, colas, *outbox*, scheduling | el cierre que no es reanudable ni idempotente | **nace el batch** |
| 16 | 🔭 **Operación y rendimiento**: observabilidad, configuración, secretos, seguridad, perfilado | `print` como log; optimizar encima de una consulta mala | los cuatro |
| 17 🏁 ⭐ | ⚔️ **El duelo y el veredicto**: el mismo endpoint en FastAPI y en Spring Boot 3, capstone y defensa | comparar contra un competidor de paja | **la API ×2** |

⚠️ **Dos riesgos declarados de las fusiones, con su mitigación.** La Fase 16 junta dos oficios
con dos mediciones distintas: se escribe con **dos bloques 📏 separados**, no con uno
promediado, o el perfilado se degrada a nota al pie. Y la Fase 17 junta la medición con su
defensa: **el miniproyecto de esa fase es la defensa**, y el veredicto general ocupa su propia
sección — si termina siendo un párrafo de cortesía al final de una tabla, la fusión falló y se
deshace.

---

## 5. 📋 Las 18 fases, en detalle

Cada bloque de abajo es el encargo del chat que escribirá esa fase. **Lo que está aquí manda
sobre cualquier idea que aparezca al redactar**; lo que no está aquí se decide en el chat y se
registra en sus 📌.

Formato: propósito · qué entra · qué no entra · el reflejo 🪞 · la medición 📏 · el miniproyecto
🧱 · la deuda 💸 cuando la haya.

---

### Bloque A · el registro *script*

#### 🛠️ Fase 00 — Ambiente, editores y el mapa del ecosistema

**Registro:** — · **Proyecto:** —

**Propósito.** Dejar al lector con un intérprete que sabe cuál es, un entorno que entiende por
dentro, un editor que depura, y el mapa mental del ecosistema contra el que ya conoce. No es un
setup: es la primera lección de criterio.

**Qué entra.** El intérprete en las tres plataformas y el problema real de tener varios —`py -0`
en Windows, el `python3` del sistema que no se toca en Linux y macOS, y por qué el `python` que
responde en la terminal casi nunca es el que crees—. `venv` y `pip` **a mano**: crear, activar,
instalar, congelar, reproducir, y qué es exactamente un entorno virtual: un directorio con
enlaces y un `PATH` reordenado, no magia. `ruff` como formateador y linter desde el primer
archivo. **VS Code** como editor principal: extensión oficial de Python, selector de intérprete,
depurador con `launch.json`, descubrimiento de pruebas, integración de `ruff` — cuatro
extensiones, no catorce. **PyCharm en su capa gratuita** como alternativa completa, con el mapa de
equivalencias para quien viene de IntelliJ, incluido qué de lo que usaba **no está** en la
edición Community. Y el mapa del ecosistema contra Maven:

| Mundo Java | Mundo Python | Dónde se rompe el paralelo |
|---|---|---|
| `pom.xml` / `build.gradle` | `pyproject.toml` | No orquesta el build: declara metadatos y dependencias |
| Maven Central | PyPI | Sin *namespace* por organización; el nombre es de quien lo registra primero |
| `~/.m2` compartido | un entorno por proyecto | El aislamiento es por directorio, y es responsabilidad tuya |
| `mvn test` | `pytest` | No hay ciclo de vida estándar que lo invoque |
| JAR ejecutable | varias respuestas, y ninguna es "la" | La distribución es la decisión más pobre del ecosistema; se afronta en las Fases 07 y 09 |

**Qué no entra.** `pyproject.toml`, gestores, tipado, pruebas, contenedores. Todo eso llega
cuando duela.

> 🧭 **La regla que fija esta fase y sostiene el Bloque A entero:** *hasta la Fase 07 no
> instalas nada.* Si un ejercicio parece necesitar una dependencia, casi siempre no la necesita.

**Y dos limitaciones que se plantan aquí y se cobran en la 07**, dichas y no resueltas:
`pip freeze` **no es un lockfile** —es una foto de lo que resultó instalado, sin distinguir lo
que pediste de lo que vino arrastrado—, y **`pip` no te da un intérprete**: gestiona paquetes
dentro de un Python que ya tienes. Quien viene de un árbol de dependencias resuelto y un
`mvn dependency:tree` no espera ninguna de las dos cosas.

**🪞 El reflejo.** *"El IDE me resuelve el entorno."* En Java el proyecto declara su JDK y el
IDE lo administra; acá el editor solo apunta a un intérprete que tú creaste, y el 80% de los
"no me funciona" del primer mes son un entorno sin activar o el intérprete equivocado
seleccionado.

**📏 La medición.** Arranque en frío del intérprete contra el de la JVM, medido en las tres
plataformas: qué tarda `python -c "pass"` contra un *hola mundo* en Java. El veredicto no es
"Python gana": es qué significa ese número para una herramienta que un cron invoca cuatrocientas
veces, y qué deja de significar para un servicio que arranca una vez al día.

**🧱 Miniproyecto — *El diagnóstico de ambiente*.** Un script de stdlib pura que reporta qué
intérpretes hay en la máquina, cuál está activo, si hay un entorno virtual y de qué proyecto,
qué versiones tienen y de dónde salieron. El equivalente al `mvn -version` que el lector corre
sin pensar, escrito por él. La trampa: funciona distinto en las tres plataformas, y el lector va
a descubrir que "cuál es el Python activo" no tiene una sola respuesta.

---

#### 🧬 Fase 01 — El modelo de datos

**Registro:** script · **Proyecto:** **nace el CLI**

**Propósito.** Recalibrar el modelo mental de qué es un valor en Python, que es donde este
perfil arrastra los errores más silenciosos.

**Qué entra.** Todo es objeto y todo se pasa por referencia a un objeto. Mutabilidad e
inmutabilidad, y quién es *hashable*. Identidad contra igualdad: `is` frente a `==`, y por qué
funciona con enteros pequeños y deja de funcionar con los grandes. El **argumento por defecto
mutable**, que es la trampa más famosa del lenguaje y se cae sola. Verdad y falsedad de los
objetos, `None` como valor y no como ausencia de tipo. Desempaquetado, `f-strings`, rebanadas.

**Qué no entra.** Clases propias → Fase 03. Manejo de errores más allá de dejar que
revienten → Fase 04.

**🪞 El reflejo.** `==` contra `equals`: en Java el reflejo es que `==` compara referencias y hay
que escribir `equals`; en Python es al revés, y el lector va a escribir `is` donde quería `==`.
Y el segundo, más caro: *"copio la lista para no modificar la original"* — que en Python copia
la lista pero no lo que contiene.

**📏 La medición.** Pertenencia en `list` contra `set` contra `dict` sobre los 2.800 pacientes
activos de Áurea, con el número de comparaciones y el tiempo. Es la medición más barata del
curso y la que más código malo previene.

**🧱 Miniproyecto — *El consolidado que miente*.** Patricia manda el archivo de pacientes de
las diez sedes y hay duplicados: el mismo paciente atendido en Chapinero y en Suba, escrito
distinto. Hay que consolidarlo. La trampa es la igualdad: dos registros del mismo paciente no
son iguales por campo, y decidir qué los hace el mismo es una decisión de diseño que el enunciado
no toma.

**💸 Deuda.** El CLI nace leyendo con `open` y `split(",")`, sin el módulo `csv`. Funciona con el
archivo de ejemplo y va a fallar con el primer nombre que traiga una coma. **Se paga en la Fase
06**, y hasta entonces el lector convive con ella a propósito.

---

#### 🔁 Fase 02 ⭐ — Secuencias perezosas

**Registro:** script · **Proyecto:** CLI

**Propósito.** Que el lector deje de materializar colecciones completas, que es el hábito de
Java que más caro sale en Python.

**Qué entra.** El protocolo de iteración. Generadores con `yield`, expresiones generadoras,
`itertools` —`islice`, `groupby`, `chain`, `tee`, `accumulate`—, comprehensions y cuándo dejan
de ser legibles, y la diferencia entre una tubería perezosa y una cadena de listas intermedias.

**Qué no entra.** `async` y las corrutinas → Fase 14.

**🪞 El reflejo.** El *stream* de Java se consume una vez y el lector lo sabe; lo que no espera es
que un generador **también** se agote, que `len()` no funcione sobre él, y que recorrerlo dos
veces devuelva vacío la segunda sin error ni aviso.

**📏 La medición.** El archivo de citas del trimestre —unas 500.000 filas— procesado con lista
intermedia contra tubería perezosa: pico de memoria y tiempo total. El número que importa no es
el tiempo, es la memoria, y el veredicto incluye a partir de qué tamaño da igual.

**🧱 Miniproyecto — *El reporte que cabe en memoria*.** El informe trimestral de inasistencia por
sede y franja horaria, sobre el archivo completo, con un tope de memoria como criterio de
aceptación. La trampa: agrupar exige ordenar, y ordenar parece exigir materializar — hay una
salida, y encontrarla es el ejercicio.

---

#### 🎩 Fase 03 — Python sin ceremonia

**Registro:** script · **Proyecto:** CLI

> ⚠️ **Es la fase más densa del curso**, y fusiona funciones y objetos a propósito porque atacan
> el mismo reflejo. Se escribe con **un solo 🪞 compartido** y un miniproyecto que ataca el
> reflejo conjunto. Si al redactarla no cabe, la fusión se deshace y se renumera; no se recorta.

**Propósito.** Quitar la ceremonia. Que el lector escriba una función donde escribiría una clase,
y una `dataclass` donde escribiría una jerarquía.

**Qué entra.** Funciones de primera clase, closures, `functools` —`partial`, `wraps`,
`lru_cache`—, decoradores y para qué sirven de verdad. `dataclass` con sus opciones —`frozen`,
`slots`, `field`— y cuándo un `NamedTuple` o un `dict` bastan. `Protocol` y el tipado
estructural. Los dunder que importan: `__eq__`, `__hash__`, `__repr__`, `__iter__`,
`__contains__`. Herencia y MRO, **para explicar por qué casi nunca la necesitas**.

**Qué no entra.** Metaclases y descriptores: se nombran y se cierran en una línea. Validación de
datos externos → Fase 10.

**🪞 El reflejo compartido.** La ceremonia. La clase con un solo método que debió ser una función;
la jerarquía de tres niveles con un `AbstractBase` arriba; los getters y setters sobre atributos
públicos; la interfaz que alguien tiene que declarar que implementa. Cada uno con su
contraejemplo en las dos formas, lado a lado.

**📏 La medición.** El mismo cálculo de comisiones de aliados escrito en los dos estilos: líneas
de código, número de archivos, y —lo que de verdad decide— cuántos sitios hay que tocar para
agregar una regla nueva. Más el costo en memoria y acceso de `dataclass` contra `dict` contra
`NamedTuple` sobre cien mil registros.

**🧱 Miniproyecto — *El motor de comisiones*.** Cada uno de los veintitrés aliados tiene su
porcentaje, y tres tienen reglas especiales que no encajan: un mínimo por caso, un tope mensual,
y uno que cobra distinto según la especialidad. Hay que calcular lo que Áurea debe cobrar. La
trampa: el lector va a construir una jerarquía de estrategias, y el enunciado exige que agregar
el aliado veinticuatro no toque ningún archivo existente.

---

#### 💥 Fase 04 — Errores y recursos

**Registro:** script · **Proyecto:** CLI

**Propósito.** Reemplazar la disciplina de excepciones verificadas por la de Python, que es
distinta y no es menor.

**Qué entra.** EAFP contra LBYL, y por qué intentar y fallar suele ganarle a comprobar antes —la
condición cambia entre la comprobación y el uso—. La jerarquía de excepciones y cómo se diseña la
propia, corta. `try/except/else/finally` y para qué sirve el `else` que Java no tiene. Context
managers, los de la biblioteca y los propios con `contextlib`. `ExceptionGroup` y `except*` para
reportar todos los fallos de un lote en vez del primero.

**Qué no entra.** Reintentos y *backoff* → Fase 13.

**🪞 El reflejo.** *"Si no está declarada, no puede lanzarse."* En Python cualquier cosa lanza
cualquier cosa y el compilador no te avisa; el contrato vive en la documentación y en las
pruebas. De ahí nacen los dos errores gemelos: el `except Exception` que se traga lo que
importaba, y el `try` gigante alrededor de cuarenta líneas donde no se sabe cuál falló.

**📏 La medición.** EAFP contra LBYL en el caso feliz y en el caso malo: qué cuesta una excepción
cuando el fallo es raro y qué cuesta cuando es frecuente, con el umbral en el que se invierte la
respuesta.

**🧱 Miniproyecto — *El validador que no se rinde en la primera fila*.** El lote que Patricia
manda a la aseguradora rebota entero por una fila mala y el mensaje no dice cuál. Hay que
validarlo antes de generar, reportando **todas** las filas malas con su fila, su campo y su
motivo. La trampa: lo natural es lanzar en la primera, y lo que se pide es acumular sin perder el
contexto de cada error.

---

#### 🐚 Fase 05 ⭐ — El shell con esteroides

**Registro:** script · **Proyecto:** CLI

**Propósito.** Demostrar la tesis de que la stdlib **es** el reemplazo del shell, y que un script
de Python es un ciudadano del sistema operativo, no un programa que casualmente corre ahí.

**Qué entra.** `pathlib` y por qué no se concatenan rutas. `subprocess` bien hecho: sin
`shell=True`, con listas de argumentos, con `timeout`, capturando y **mirando el código de
retorno**. Códigos de salida propios que signifiquen algo. Señales y apagado limpio. `argparse`
con subcomandos. Encoding en la frontera del proceso, `stdin`/`stdout` como tubería, `tempfile`,
variables de entorno.

**Qué no entra.** Distribución de la herramienta → Fase 09.

**🪞 El reflejo.** Dos, y los dos caros: concatenar cadenas para armar una ruta o un comando —que
en Windows falla y en el nombre con espacio falla en todas partes—, y **ignorar el código de
retorno** porque en Java la llamada externa habría lanzado. Un `subprocess.run` que falla y no se
revisa es un script que reporta éxito sobre un trabajo que no se hizo.

**📏 La medición.** El costo de crear un proceso, y qué pasa cuando el script invoca al binario
del proveedor una vez por factura contra una vez por lote: tiempo total con doscientas facturas y
el punto donde agrupar deja de compensar.

**🧱 Miniproyecto — *El firmador de facturas*.** El proveedor tecnológico entrega un binario que
firma el XML, se invoca por línea de comandos, a veces se cuelga y devuelve códigos no
documentados. Hay que orquestarlo para el lote del mes: con timeout, con un reintento, sin
`shell=True`, y con un código de salida que le diga a quien lo llamó desde `cron` si puede seguir.
La trampa: el binario escribe parte de sus errores en `stdout` y parte en `stderr`, y uno de sus
"éxitos" devuelve un código distinto de cero.

---

#### 📦 Fase 06 — Formatos en la caja

**Registro:** script · **Proyecto:** CLI

**Propósito.** Cerrar el Bloque A demostrando cuánto trabajo real se hace sin instalar nada — y
pagar la deuda de la Fase 01.

**Qué entra.** `csv` con sus dialectos, sus comillas y su `DictReader`; `json` y sus límites;
`tomllib` para configuración; `sqlite3` como almacén local de verdad, con transacciones e
índices; `zipfile` y `tarfile`; lectura en flujo de archivos que no caben. Encoding donde
duele: el BOM que manda Excel, el `latin-1` del export de Odontovía, y por qué `errors="ignore"`
es una decisión y no un arreglo.

**Qué no entra.** Bases de datos servidor → Fase 11.

**🪞 El reflejo.** *"Busco una biblioteca para esto."* En el mundo Maven agregar una dependencia
es gratis y aquí se paga caro, y la mitad de las veces la respuesta ya viene en la caja. El
segundo reflejo: asumir UTF-8 porque hace quince años que no piensa en encodings.

**📏 La medición.** Consultar el histórico consolidado releyendo los CSV contra tenerlo en
`sqlite3` con un índice: tiempo de consulta y tamaño en disco, con el umbral de filas en el que
el CSV deja de ser razonable.

**🧱 Miniproyecto — *El consolidador con memoria*.** El cierre de mes de las diez sedes: seis
exports distintos, un CSV con las columnas en otro orden, un archivo en `latin-1`, y un histórico
en `sqlite3` que permite responder *"¿esto ya lo facturamos el mes pasado?"* sin releerlo todo. La
trampa está en el encoding y en las comillas: hay una fila con una coma dentro de un nombre, y
es la que rompe el script de la Fase 01.

**💸 Se paga aquí** la deuda declarada en la Fase 01. La fase muestra el `git diff` entre los dos
tags como factura.

---

### Bloque B · la frontera

#### 🚪 Fase 07 ⭐ — Cuándo deja de ser un script

**Registro:** script → herramienta · **Proyecto:** **el CLI migra**

**Propósito.** La fase de la tesis. Reconocer que el script cruzó la línea, y migrarlo sin
reescribirlo.

**Qué entra.** Las señales de que cruzó: lo usan tres personas, tiene dos puntos de entrada,
alguien pidió una opción nueva, y ya duele probarlo. `pyproject.toml`: metadatos, dependencias
declaradas contra fijadas, *entry points*. El layout `src/` y por qué existe. El refactor real del
CLI del Bloque A, archivo por archivo, **sin empezar de cero**. Y el problema de la
reproducibilidad, que es donde el Bloque A se cobra: el mismo `pip install` en dos máquinas y en
dos días da árboles distintos.

**Aquí entra el arco de gestores completo, y entra medido**, no como desfile de herramientas:

| | Qué resuelve que `pip` + `venv` no | Qué cuesta |
|---|---|---|
| `pip` + `pip-tools` | Un *lock* de verdad, separando directas de transitivas | Dos archivos y un paso más; sigue sin darte intérprete |
| **`uv`** | *Lock*, resolución rápida, **e instala el intérprete**; y reemplaza a `pipx` en la Fase 09 | Herramienta joven que se mueve rápido |
| **Miniforge / `conda-forge`** | El entorno incluye el intérprete **y bibliotecas que no son Python**: otro universo de paquetes | Canales, `environment.yml`, y la convivencia incómoda de `conda install` con `pip install` |

> ⚖️ **El veredicto de esta fase, y se escribe sin rodeos:** para este stack **conda no hace
> falta**. FastAPI, SQLAlchemy, Django, httpx y pytest son wheels de PyPI que instalan sin
> compilar nada, y la ventaja real de conda es más estrecha que su reputación. Su modelo es el
> correcto cuando el paquete que necesitas **no es Python**, y eso llega en el track de datos, no
> aquí. El gestor del curso de aquí en adelante es **`uv`**, con versión fijada y fecha de
> verificación declarada.
>
> 📝 Cuando el curso use conda, usa **Miniforge con `conda-forge`**. Los canales por defecto de
> Anaconda no entran, y con eso el asunto del licenciamiento comercial desaparece del curso en
> vez de tener que explicarse.

**Qué no entra.** Tipos y pruebas → Fase 08. Entregarlo a un usuario final → Fase 09.

**🪞 El reflejo.** Empezar por el proyecto. En Java el primer gesto es `mvn archetype:generate` y
la estructura completa; acá la estructura llega **al final**, cuando el archivo ya no cabe, y
llegar antes es pagar ceremonia por nada. El reflejo hermano: *"`requirements.txt` es mi `pom`"*,
que no es cierto ni en resolución, ni en transitividad, ni en reproducibilidad.

**📏 La medición.** La tabla de las tres opciones sobre el mismo problema: tiempo de resolución
en frío y en caliente, tamaño del entorno en disco, reproducibilidad en una máquina con otro
intérprete, y **cuántos pasos tiene que dar Patricia**. Esa última columna es la que decide, y es
la que ningún tutorial mide.

**🧱 Miniproyecto — *El entorno de Patricia*.** Entregar el CLI de modo que corra en el portátil
de la sede: Windows, con un Python distinto instalado por alguien hace dos años, y sin permisos
de administrador. Hay que resolverlo con las tres opciones y sostener la elección con la tabla. La
trampa: la que funciona más rápido en tu máquina no es la que menos pasos le pide a ella.

---

#### 🔎 Fase 08 — El contrato del código

**Registro:** herramienta · **Proyecto:** CLI

**Propósito.** Ponerle al proyecto las dos redes que en Java venían de fábrica —el compilador y
la suite— y entender en qué se parecen y en qué no.

**Qué entra.** Anotaciones de tipo y el verificador en modo estricto. `Protocol`, `TypedDict`,
genéricos con la sintaxis moderna, `Optional` como decisión de dominio. Y `pytest`: fixtures que
**no** son `@BeforeEach` —son inyección de dependencias con alcance—, `parametrize`, `conftest`,
dobles con `monkeypatch` y `unittest.mock`, cobertura con criterio, y pruebas basadas en
propiedades con Hypothesis donde el dominio lo pide.

**Qué no entra.** Pruebas de integración con base de datos → Fase 11.

**🪞 El reflejo.** Dos. *"El verificador es el compilador"*: no lo es — no hay garantía en tiempo
de ejecución, es una herramienta aparte que alguien tiene que correr, y las bibliotecas que
consumes pueden mentirte. Y *"traduzco JUnit"*: la clase de test con `setUp`, la jerarquía de
casos base, y el `assertThat` importado de una biblioteca cuando `assert` a secas ya da mejor
salida.

**📏 La medición.** Activar el verificador sobre el código del Bloque A y **contar**: cuántos
errores reales aparecen, cuántos son ruido, y cuántos de los reales habrían llegado a producción.
Es la medición más convincente del curso porque el código lo escribió el propio lector.

**🧱 Miniproyecto — *Blindar el motor de comisiones*.** Tipar y probar el cálculo de la Fase 03,
con una prueba basada en propiedades que verifique el invariante que de verdad importa: lo
repartido entre los profesionales de un plan **suma exactamente** lo cobrado, sin un peso de
diferencia. La trampa es `Decimal` contra `float`, y Hypothesis la encuentra sola.

---

#### 🎁 Fase 09 ⭐ — Entregarle la herramienta a Patricia

**Registro:** herramienta · **Proyecto:** CLI

**Propósito.** La fase que más se parece al trabajo real del lector: entregar software a
alguien que no es ingeniero, en una máquina que no controlas. En un lenguaje que produce un
binario estático esta conversación no existe; en Python es media docena de decisiones.

**Qué entra.** `pipx` y la instalación aislada. `zipapp` y el archivo único. PEP 723 y el script
con sus dependencias declaradas dentro. El ejecutable congelado, con su costo en tamaño y en
antivirus. El contenedor, y por qué en el portátil de una sede casi nunca es la respuesta. Y lo
que nadie enseña: **cómo se actualiza** lo que ya entregaste, y qué pasa cuando el usuario no
tiene Python y no va a instalarlo.

**Qué no entra.** Publicar en un índice de paquetes: es del track `pk`.

**🪞 El reflejo.** *"Que clone el repo y cree un entorno."* Es exactamente lo que el lector
respondería, y es la respuesta que hace que Patricia vuelva al Excel. En Java el reflejo es un
JAR ejecutable y un `java -jar`; aquí no existe esa respuesta única, y elegir entre las cuatro es
la lección.

**📏 La medición.** Las cuatro formas, con las columnas que importan del otro lado: pasos que da
el usuario, tamaño del entregable, tiempo de arranque, qué pasa si no tiene Python, y qué hace
falta para entregarle la versión siguiente.

**🧱 Miniproyecto — *La entrega de verdad*.** Empaquetar el CLI de las cuatro formas y escribir la
recomendación para Áurea con la tabla delante, sabiendo que quien la va a ejecutar cierra el mes
un viernes a las siete de la tarde. La trampa: la opción técnicamente mejor y la opción correcta
para Patricia no son la misma, y el miniproyecto se evalúa por la justificación, no por el
empaquetado.

---

### Bloque C · el registro *aplicación*

#### ⚡ Fase 10 — FastAPI y la validación en el borde

**Registro:** aplicación · **Proyecto:** **nace la API**

**Propósito.** Entrar al registro de aplicación con la idea que lo ordena: **validar en la
frontera**, una sola vez, y que hacia adentro el dato ya sea de fiar.

**Qué entra.** FastAPI y su modelo de dependencias. Pydantic como contrato: tipos del dominio,
validadores, y la diferencia entre el modelo de entrada, el de dominio y el de salida. `async`
lo justo para no escribir código que bloquee el bucle. OpenAPI generado y para qué sirve de
verdad. Errores HTTP honestos, paginación, y el borde que no confía en nadie.

**Qué no entra.** Base de datos → Fase 11. Concurrencia en serio → Fase 14.

**🪞 El reflejo.** El DTO con su *mapper* escrito a mano y la validación repartida por los
servicios. Aquí el modelo **es** el validador, y la capa de traducción que el lector espera
escribir en gran parte desaparece — con la contrapartida honesta de que Pydantic valida en
tiempo de ejecución y tiene un costo medible.

**📏 La medición.** Latencia y rendimiento del endpoint de disponibilidad, y **cuánto de esa
latencia es la validación**: el costo de Pydantic sobre una carga realista, para decidirlo con
un número y no con fe.

**🧱 Miniproyecto — *La cita imposible*.** El endpoint que consulta la disponibilidad de las diez
sedes y reserva. Debe rechazar en la frontera todo lo que no tiene sentido: una cita en el
pasado, una duración que no corresponde a la fase del plan, una sede que no presta esa
especialidad. La trampa: la mitad de esas reglas parecen de validación y son de negocio, y
meterlas todas en el modelo de entrada es un error que se paga en la Fase 12.

---

#### 🗄️ Fase 11 — Persistencia

**Registro:** aplicación · **Proyecto:** API

**Propósito.** Poner el dominio duro de Áurea contra una base de datos real, y desmontar la
expectativa de que el ORM de Python es Hibernate con otro nombre.

**Qué entra.** El driver y el SQL directo. SQLAlchemy **Core contra ORM**, que son dos
herramientas distintas y no dos niveles de abstracción. Sesión, unidad de trabajo, y el N+1 que
aquí es explícito en vez de mágico. Migraciones. Transacciones y aislamiento donde el dominio lo
exige: dos auxiliares reservando el mismo espacio de las 3:40.

**Qué no entra.** Otros motores → track `db`.

**🪞 El reflejo.** *"Cargo la entidad y navego las relaciones."* Sin carga perezosa automática, la
navegación que en Hibernate era gratis aquí es una consulta que tú pediste o un error que dice
que la sesión ya se cerró — y eso, incómodo como es, es mejor.

**📏 La medición.** La misma consulta de disponibilidad en SQL directo, en Core y en ORM: tiempo,
consultas emitidas y filas traídas. Más el N+1 provocado a propósito, con su costo en el
endpoint de la Fase 10.

**🧱 Miniproyecto — *El plan de tratamiento*.** Modelar el plan de Arquitectura de Sonrisa con
sus cinco fases, su responsable y su sede por fase, su consentimiento por fase y su plan de
pagos en paralelo — y responder en una consulta *"¿qué planes llevan más de noventa días quietos
en la fase 2?"*. La trampa: el modelo obvio hace que esa pregunta cueste diez consultas.

---

#### 🏛️ Fase 12 — Django y el veredicto web

**Registro:** aplicación · **Proyecto:** **nace el back-office**

**Propósito.** Que la comparación entre los dos registros web sea una decisión vivida y no un
párrafo leído.

**Qué entra.** Django con baterías: ORM, migraciones, formularios, autenticación, permisos y el
admin. El modelo de permisos por fila que Áurea necesita —Édgar ve Suba y nada más— y la
auditoría de accesos, que aquí no es una mejora sino un requisito legal. Y el ⚖️ veredicto
FastAPI ⇄ Django, con el criterio explícito: **son dos registros, no dos calidades.**

**Qué no entra.** Frontend propio: no hay equipo de frontend, y esa restricción es parte del
problema.

**🪞 El reflejo.** Elegir framework por rendimiento cuando lo que decide es cuántas pantallas
tienes que escribir y quién las va a mantener. El admin de Django no tiene equivalente en la
conversación que el lector trae de Java, y por eso lo subestima.

**📏 La medición.** El mismo CRUD con permisos por fila y auditoría, en los dos: líneas escritas,
archivos tocados, tiempo hasta la primera pantalla usable, y qué hace falta para agregar la
pantalla número cuarenta y uno.

**🧱 Miniproyecto — *Lo que el franquiciado no debe ver*.** El back-office del plan de
tratamiento con permisos por sede y registro de cada acceso a un dato de paciente: quién, cuándo
y por qué. La trampa: el permiso por fila es fácil de poner en la vista y es ahí donde no sirve,
porque la fuga se cuela por el admin, por un reporte y por una exportación.

---

#### 🌐 Fase 13 — Integraciones

**Registro:** aplicación · **Proyecto:** API

**Propósito.** Hablar con sistemas que no controlas sin que un fallo ajeno se convierta en un
error propio — ni en un cobro duplicado.

**Qué entra.** `httpx` y el cliente bien configurado: timeouts en todas las capas, límites,
reutilización de conexión. Reintentos con *backoff* y qué **no** se reintenta.
**Idempotencia**, que es el corazón de la fase. Webhooks: emitirlos y recibirlos, con firma y con
la garantía de entrega que de verdad tienes. Fallos parciales y degradación.

**Qué no entra.** Automatizar portales sin API → track `au`.

**🪞 El reflejo.** *"Si falló, reintento."* El reintento sobre una operación que no es idempotente
es cómo se le cobra dos veces a un paciente, y en el dominio de Áurea eso no es una métrica: es
una llamada de Clara.

**📏 La medición.** Comportamiento bajo fallo inyectado —latencia, 500 intermitentes, respuestas
truncadas—: cuántas operaciones se pierden, cuántas se duplican y cuánto tarda en recuperarse,
con y sin las defensas puestas.

**🧱 Miniproyecto — *El webhook del socio*.** Notificar a los socios cada cambio de
disponibilidad, sabiendo que uno de ellos responde lento, otro responde 200 y no procesa, y el
tercero exige firma. La trampa: la entrega "al menos una vez" obliga a que el receptor sea
idempotente, y el enunciado pide diseñar **las dos puntas**.

---

#### 🧵 Fase 14 ⭐ — Concurrencia y el GIL

**Registro:** aplicación · **Proyecto:** los tres

**Propósito.** La fase donde el instinto de Java es más fuerte y más inútil, y donde todo se
decide midiendo.

**Qué entra.** Qué es el GIL exactamente y qué no. Hilos y para qué **sí** sirven —E/S—.
Procesos, con su costo de arranque y de serialización. `asyncio`: el bucle, las corrutinas,
`TaskGroup`, y el error de bloquearlo. El intérprete sin GIL y qué cambia de verdad. Y el
estado compartido que no vive en memoria sino en Postgres, que es el caso real de Áurea.

**Qué no entra.** Colas y trabajos de fondo → Fase 15.

**🪞 El reflejo.** `synchronized`, `ConcurrentHashMap` y el pool de hilos. Ninguno de los tres
resuelve el problema cuando dos auxiliares en dos sedes reservan la misma franja, porque el
estado está en la base de datos y el bloqueo tiene que estar ahí — con bloqueo optimista y una
restricción, no con una primitiva del lenguaje.

**📏 La medición.** La conciliación de ventas —CPU-bound de verdad, sobre millones de líneas— en
las cuatro formas: secuencial, hilos, procesos y sin GIL. Y por separado, una carga de E/S en las
mismas cuatro, porque el veredicto se invierte y esa inversión **es** la lección.

**🧱 Miniproyecto — *La conciliación del trimestre*.** Conciliar el archivo de ventas contra lo
facturado, eligiendo el modelo de concurrencia con la medición delante y justificando por qué los
otros tres pierden. La trampa: el que gana en tu portátil de ocho núcleos no es el que gana en la
máquina virtual de dos que tiene Áurea.

---

#### 🌙 Fase 15 — El proceso nocturno

**Registro:** aplicación · **Proyecto:** **nace el batch**

**Propósito.** Escribir el proceso que corre solo a las dos de la mañana y que alguien tiene que
poder auditar ocho meses después.

**Qué entra.** Lotes reanudables con punto de control. Idempotencia a nivel de proceso. El patrón
*outbox* y por qué la cola no sustituye a la transacción. Colas y planificadores, comparados sin
devoción. Reintentos, cola de fallidos, y **auditoría línea por línea**: qué se sumó, con qué
tasa, bajo qué cláusula.

**Qué no entra.** Observabilidad → Fase 16.

**🪞 El reflejo.** El job que arranca de cero cuando falla. En una ventana nocturna de seis horas
que se cae en la hora cinco, reiniciar desde cero no es una molestia: es que el cierre no salió.

**📏 La medición.** El cierre completo con un fallo inyectado en la hora cinco: cuánto trabajo se
pierde y cuánto tarda en recuperarse, con punto de control y sin él.

**🧱 Miniproyecto — *La liquidación que se puede defender*.** Liquidar las regalías de los seis
franquiciados y las comisiones de los treinta y cuatro contratistas, reanudable, idempotente, y
**reproducible a ocho meses** con la tasa, la regla y la fecha que se usaron entonces. La trampa:
reproducir el número exige guardar la tasa de cambio del día, y nadie la guarda hasta que un
autor impugna su liquidación.

---

#### 🔭 Fase 16 — Operación y rendimiento

**Registro:** aplicación · **Proyecto:** los cuatro

> ⚠️ **Fusión con riesgo declarado.** Son dos oficios y se escriben con **dos bloques 📏
> separados**, nunca con uno promediado. Si al redactar el perfilado queda como nota al pie de la
> observabilidad, la fusión falló y se deshace.

**Propósito.** Dejar los cuatro proyectos operables por alguien que no los escribió, y optimizar
con evidencia en vez de con intuición.

**Qué entra.** `logging` bien configurado y estructurado, trazas con OpenTelemetry, métricas que
alguien mire. Configuración por ambiente y secretos fuera del repositorio. Seguridad de las que
muerden en Python: `pickle`, `yaml.load`, `shell=True`, y la cadena de suministro —el paquete con
el nombre parecido—. Y el perfilado: `cProfile`, muestreo con `py-spy`, memoria, y las salidas de
emergencia cuando el perfil dice que el problema es el intérprete.

**🪞 El reflejo.** `print` como registro y la optimización sin medir. Y el específico del dominio:
optimizar el código Python que está encima de una consulta mala. **Primero SQL, después Python** —
al revés es teatro.

**📏 Las dos mediciones.** *(a)* El costo de la observabilidad: latencia y volumen de registro con
y sin instrumentación. *(b)* El perfil del cierre nocturno, que tiene que terminar señalando
dónde está el tiempo de verdad, con el reparto entre consulta, serialización e intérprete.

**🧱 Miniproyecto — *Bajar el cierre de seis horas*.** Instrumentar el proceso de la Fase 15,
encontrar dónde se va el tiempo y reducirlo, con la condición de que cada cambio venga con su
número antes y después. La trampa: la primera mejora grande no está en Python, y el miniproyecto
no se aprueba si el lector optimiza antes de perfilar.

---

#### ⚔️ Fase 17 🏁 ⭐ — El duelo y el veredicto

**Registro:** aplicación · **Proyecto:** **la API ×2**

> ⚠️ **Fusión con riesgo declarado.** El miniproyecto de esta fase **es la defensa del capstone**,
> y el veredicto general ocupa su propia sección. Si termina siendo un párrafo de cortesía al pie
> de una tabla, la fusión falló.

**Propósito.** Cerrar el curso con la única comparación que al lector le sirve el lunes, y con la
admisión honesta de dónde el curso se equivocó.

**Qué entra.** El contenedor, con lo justo para medir: imagen, capas, arranque en frío. **El mismo
endpoint implementado dos veces**, en FastAPI y en Spring Boot 3, con el mismo arnés:
rendimiento sostenido, latencia de cola, arranque en frío, consumo de memoria, líneas de código,
y costo mensual al volumen real de Áurea. Y el veredicto general del curso: script, herramienta,
aplicación… o Java.

**🪞 El reflejo.** Comparar contra un competidor de paja. El Spring Boot del duelo tiene que ser
uno que alguien defendería en una revisión de código, o la medición no vale nada y el lector lo
sabrá.

**📏 La medición.** La tabla final, con sus condiciones declaradas y **el empate donde haya
empate** — que es la palabra que menos aparece en los cursos de tecnología y la que más falta
hace.

**🧱 Miniproyecto — *La defensa*.** Presentar a Clara y a Julián, por escrito y en una página,
las decisiones del curso con sus números: qué se construyó, qué se debió comprar, qué debió
quedarse en un script de cuarenta líneas y qué debió escribirse en Java. La trampa: el lector
llega convencido de que Python ganó, y el ejercicio exige encontrar al menos dos decisiones donde
no fue así. **Si al final del curso resultara que Python ganó todo, el curso estaría mal
escrito.**

---

## 6. 🧳 Qué se absorbió de lo que habría sido apéndice

Para que la decisión de "sin apéndices" sea auditable, conviene dejar la lista de lo que en
otro curso habría tenido su `aNN-` y dónde quedó aquí:

| Habría sido apéndice | Dónde vive |
|---|---|
| Instalación y gestión de intérpretes | Fase 00 |
| Entornos virtuales | Fase 00 (`venv` + `pip`) y Fase 07 (`uv`, comparado con `pip-tools` y Miniforge) |
| Configuración de VS Code | Fase 00 |
| PyCharm para quien viene de IntelliJ | Fase 00 |
| Empaquetado | Fase 07 ⭐ |
| Distribución a un usuario no técnico | Fase 09 ⭐, que existe por esto |
| Comparación de gestores | Fuera del camino base: track opcional `pk` |
| Diccionario Java ⇄ Python | 📖 repartido: cada fase trae el suyo, del tema que enseña |
| `asyncio` de referencia | Fase 14, con su medición |
| Convención de git y tags | `00-convencion-de-git-y-tags.md`, en la raíz del curso — no es apéndice: es un documento de encuadre que el lector sí abre, antes de la Fase 00 |

---

## 7. 💼 Los cuatro proyectos que atraviesan el curso

Cada uno cubre un registro distinto, ninguno se solapa con otro, y **ninguno se toca desde los
miniproyectos** (`formato-de-miniproyectos.md` §5).

| # | Registro | Qué es en Áurea | Nace |
|---|---|---|---|
| 1 | **Herramienta CLI** | La caja de herramientas de Patricia: consolida los archivos de las diez sedes, valida antes de generar, y produce lo que el país exige. **Nace como un archivo de cuarenta líneas en la Fase 01 y solo se vuelve paquete en la Fase 07.** Es el proyecto que sostiene la tesis | F01 |
| 2 | **API de servicio** | La agenda de la red: disponibilidad de diez sedes, identidad del paciente a través de la red, reservas desde la web y el bot. Es la contraparte del duelo final | F10 |
| 3 | **Monolito con baterías** | El back-office: cuarenta pantallas, permisos por sede y auditoría de accesos, con una usuaria que no es ingeniera | F12 |
| 4 | **Proceso por lotes** | El cierre nocturno: conciliación, glosas por vencer, liquidación de regalías y comisiones. Reanudable, idempotente y auditable línea por línea | F15 |

---

## 8. 🧩 Tracks opcionales

Fuera del camino base y declarados como tales. Su inventario vive en
[`propuestas-temas-opcionales.md`](propuestas-temas-opcionales.md) y los tracks de IA y datos
en [`propuestas-fases-base-ia-datos.md`](propuestas-fases-base-ia-datos.md). **Los dos son
material exploratorio**: se revisan después de cerrar el camino base, con el mismo criterio de
forma —sin apéndices, un miniproyecto por fase— y su propio prefijo de archivo.

---

## 9. 🚦 Las decisiones, y dónde quedó cada una

**Todas cerradas.** Se dejan escritas con su porqué para que no vuelvan a discutirse, y para
que quien las herede sepa qué se descartó y a cambio de qué.

🪦 **9.1 · Cerrada: 18 fases.** Se consolidó agresivamente: **03+04** (funciones y objetos →
*Python sin ceremonia*), **09+10** (tipado y pruebas → *El contrato del código*), **18+19**
(operación y rendimiento) y **20+21** (el duelo y el veredicto). Las dos fusiones que traen
riesgo llevan su mitigación escrita en §4 y son vinculantes al redactar: la Fase 03 es la más
densa del curso y su miniproyecto ataca el reflejo conjunto; la Fase 16 lleva dos bloques 📏
separados; la Fase 17 convierte la defensa del capstone en su miniproyecto.

🪦 **9.2 · Cerrada: el arco de gestores es de tres tiempos.** `venv` + `pip` a mano en la Fase
00, por el mecanismo; la comparación medida de `pip-tools`, `uv` y Miniforge en la Fase 07,
provocada por el encargo de entregarle el CLI a Patricia; y **`uv` como gestor del curso** de ahí
en adelante, con versión fijada y fecha de verificación.

**conda no entra al camino base**, y la razón es que el camino base no tiene una sola
dependencia binaria: FastAPI, SQLAlchemy, Django, httpx y pytest son wheels de PyPI que instalan
sin compilar nada. Adoptarlo significaría enseñar canales, `environment.yml` y la convivencia de
`conda install` con `pip install` para comprar un problema que el curso no tiene. **Se gana su
lugar en el track de datos e IA**, donde NumPy y PyTorch hacen el problema binario genuino y
`conda-forge` pasa a ser el gestor por defecto de ese track. El panorama completo —Poetry, PDM,
`pip-tools`, `mamba`— vive en el track opcional `pk`.

> 📄 **Y con eso el licenciamiento deja de ser un tema.** Donde el curso use conda, usa
> **Miniforge con `conda-forge`**, que es comunitario y libre. Los canales por defecto de
> Anaconda —cuyos términos comerciales dependen del tamaño de la organización y han cambiado más
> de una vez— **no entran al curso**. Se nombra en una línea por qué, y se sigue. Un curso que
> tiene que explicar un umbral de empleados para que el lector pueda instalar algo eligió mal la
> herramienta.

> ⚠️ **Lo que sí hay que declarar en la Fase 07:** `uv` es joven y se mueve rápido. Se fija
> versión exacta y se declara la fecha de verificación, igual que con todo lo demás. La
> mitigación de fondo ya está puesta: la Fase 00 enseña `pip` y `venv` a mano, así que quien
> llegue a una empresa donde solo hay `pip` sabe trabajar igual. El curso no ata al lector a una
> herramienta.

🪦 **9.3 · Cerrada: bandas por bloque, no horas por fase.** El curso publica un rango de
dedicación por bloque —A, B y C— y la estimación de cada miniproyecto (2-5 h), y nada más. Una
tabla de horas por fase que nadie puede cumplir desprestigia al resto del documento, y aquí el
tiempo real lo domina el encargo, no la lectura. Las bandas se calculan cuando las 18 fases
estén escritas, no antes: estimarlas ahora sería inventarlas.

> ✅ **Cumplido.** Con las 18 fases escritas, las bandas se derivaron de material medible —137.000
> palabras a 200 por minuto, 18 miniproyectos de 2–5 h, y un tercio de los 450 ejercicios— y se
> publicaron en `0-ESTRUCTURA-CURSO.md` con esa derivación a la vista: **A 40–60 h, B 15–25 h,
> C 45–65 h, total 100–150 h.**

🪦 **9.4 · Cerrada: el duelo es contra Spring Boot 3 y nada más.** Un solo endpoint, el mismo
a los dos lados, con el mismo arnés: rendimiento, arranque en frío, consumo, líneas de código y
costo mensual al volumen real de Áurea. Ni Go ni Quarkus: el lector tiene Spring Boot, y meter
un tercer competidor diluye la única comparación que le va a servir el lunes.

🪦 **9.5 · Cerrada: el CLI nace leyendo con `open` y `split`, sin el módulo `csv`.** Nace
deliberadamente mal y la deuda 💸 se declara en la propia Fase 01 con su destino: **se paga en
la Fase 06**, cuando el lector ya se estrelló con una celda que traía una coma y comillas. Es
la primera vez que el curso usa su propio mecanismo de deuda, y por eso conviene que sea
visible y barata.

🪦 **9.6 · Cerrada: no hay fase de contenedores ni de orquestación.** La Fase 17 usa un
contenedor porque lo necesita para medir arranque en frío y costo, y eso es todo el alcance. El
resto —redes, volúmenes, orquestación, despliegue— **queda declarado fuera y no se enlaza a
ninguna parte**, que es la regla del curso (`alcance-del-proyecto.md` §0).

🪦 **9.7 · Cerrada: la empresa es Áurea.** La alternativa que se evaluó durante la discusión de
fases —una casa editorial— quedó descartada y **su documento ya no vive en esta carpeta**: el
dominio odontológico gana por la frontera legal de la historia clínica, que obliga a decisiones
de diseño reales, y material que el curso no usa es peso muerto que alguien va a leer por error
(`alcance-del-proyecto.md` §0).

---

## 10. 📁 Convención de nombres de archivo

Todo ordenable por nombre, con dos dígitos. **El número del archivo es el número de la fase.**

```text
README.md
0-ESTRUCTURA-CURSO.md
00-convencion-de-git-y-tags.md
00-instalacion-ambiente-editores-y-ecosistema.md
01-modelo-de-datos.md
02-secuencias-perezosas.md
03-python-sin-ceremonia.md
04-errores-y-recursos.md
05-shell-con-esteroides.md
06-formatos-en-la-caja.md
07-cuando-deja-de-ser-un-script.md
08-el-contrato-del-codigo.md
09-distribucion.md
10-fastapi.md
11-persistencia.md
12-django-y-el-veredicto-web.md
13-integraciones.md
14-concurrencia-y-gil.md
15-el-proceso-nocturno.md
16-operacion-y-rendimiento.md
17-el-duelo-y-el-veredicto.md
BENCHMARKS.md
INSTINTOS.md
prompts/
```

No hay `aNN-`. Los tracks opcionales, si se escriben, llevan el prefijo `op-` más sus dos
letras de track (`opNNN-ui02-gradio.md`): es una de las tres convenciones de nombre del curso,
con su motivo en la guía de estilo §8.2.

---

## 11. ✅ Lo que se hizo, y lo que sigue

**El orden de escritura que este documento fijó se siguió, y funcionó.** Se deja registrado
porque la decisión de escribir fuera del orden numérico —las ⭐ de la tesis antes que el resto—
era la más discutible del plan y resultó acertada:

| Turno | Qué | Resultado |
|---|---|---|
| 1 | Los tres documentos de la raíz | Escritos. `00-convencion-de-git-y-tags.md` quedó enlazado por las 18 fases sin reexplicarse nunca |
| 2 | Fases **00** y **01** | Fijaron voz, registro y el CLI. La 01 estrenó la deuda 💸, que la 06 cobró |
| 3 | Fases **07** y **09** ⭐ | **La apuesta del plan.** Escribirlas antes obligó a congelar la forma del CLI en `contrato-del-cli.md`, y eso evitó reescribir el Bloque A |
| 4 | Resto del Bloque A (02–06) | La 02 construyó el arnés que usaron las quince fases siguientes |
| 5 | **08** y Bloque C (10–16) | Sin sorpresas de estructura |
| 6 | **17** + `BENCHMARKS.md` + `INSTINTOS.md` | El duelo contra Spring Boot 3.5.16 y los dos consolidados |

📝 **Lo que el plan no previó**, y quedó anotado en los 📌 de las fases: que el material
necesitaría un documento más —`contrato-del-cli.md`—, que casi todas las mediciones saldrían de
un portátil de ocho núcleos cuando el dominio tiene una máquina de dos, y que ejecutar el código
contradiría al texto media docena de veces. Esto último es lo mejor que le pasó al curso.

### Lo que sigue: el material **a la carta**

Los tracks opcionales se revisan ahora, y **con un criterio de forma distinto al que este
documento fijó para el camino base**. La diferencia está argumentada en
[`propuestas-temas-opcionales.md`](propuestas-temas-opcionales.md) y se resume así:

| | Camino base (este documento) | Material a la carta |
|---|---|---|
| Cómo se lee | En orden, con dependencias | Suelto, cuando hace falta |
| Miniproyecto | **Obligatorio**, uno por fase | Solo si el tema lo pide |
| Medición | **Obligatoria**, una por fase | Solo si hay algo que comparar |
| Dominio | **Siempre Áurea** | Áurea decide la **prioridad**, no la admisión |
| Tamaño | Cerrado: 18 fases | Abierto: puede llegar a cien secciones |
| Archivos | `NN-nombre.md` | `opNNN-<tt>NN-nombre.md` |

⚠️ **Y la regla que no cambia**, porque es la que hace creíble al curso entero: ninguna afirmación
comparativa sin su número, ninguna biblioteca recomendada sin mirar su fecha de última
publicación, y el empate se llama empate.
