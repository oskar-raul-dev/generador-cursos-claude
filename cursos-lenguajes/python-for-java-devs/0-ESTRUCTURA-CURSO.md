# 🗺️ Estructura del curso
## Python para desarrolladores Java senior

Este es el mapa. Sirve para dos cosas: para que sepas dónde estás parado mientras avanzas, y
para que cualquiera que retome el material sepa dónde va cada pieza. No repite el contenido de
las fases — las sitúa.

---

## 🎯 Qué es este curso

Un curso práctico que te enseña a **elegir el registro correcto de Python** —script,
herramienta o aplicación— y a escribir cada uno como se escribe de verdad, midiendo lo que
ganas y lo que pierdes frente al stack que ya dominas.

> 🧭 **La pregunta que ordena todo el material: ¿esto es un script, una herramienta o una
> aplicación?**

No aprendes a programar aquí. Aprendes a decidir. Y la decisión tiene dos formas de salir mal,
las dos caras y las dos simétricas: entregar un proyecto con capas, interfaces e inyección de
dependencias cuando el encargo eran cuarenta líneas, o no reconocer el momento en que ese
script de cuarenta líneas dejó de serlo y ya merece paquete, tipos, pruebas y una forma de
distribuirse.

El curso está organizado para que te equivoques en las dos direcciones a propósito, y después
te cobra el error con números.

---

## 👤 Para quién está escrito

Para un desarrollador **Java senior**, con ocho o más años de oficio. Alguien que domina
orientación a objetos, concurrencia, SQL, HTTP, pruebas, build, contenedores y despliegue, y
que lleva la vida entera resolviendo problemas con documentación abierta en otra pestaña.

De ahí salen las dos reglas que separan este material de un tutorial de Python normal, y que
conviene decir en voz alta antes de empezar:

> 🧭 **No se explica lo que ya sabes.** Nada de qué es una excepción, un mapa, una petición
> HTTP o una transacción. Si un párrafo explica eso, sobra, aunque esté bien escrito.
>
> 🧭 **La dificultad no se baja.** Los ejercicios y los miniproyectos están calibrados para ese
> perfil. Si un miniproyecto se pudiera terminar copiando el código de su fase, estaría mal
> diseñado.

Lo que sí se explica con calma es donde de verdad está el salto, que son cinco cosas: **el
modelo de datos de Python** —todo es objeto, mutabilidad, identidad contra igualdad—, **los
tres registros y la frontera entre ellos**, **el ecosistema de empaquetado y entornos**, **el
tipado gradual y por qué no es el tipado del compilador que conoces**, y **la concurrencia con
GIL y sin él**.

---

## 🧱 Los tres bloques

```text
Bloque A   Un archivo. Stdlib pura. Sin dependencias, sin pyproject, sin capas.
Bloque B ⭐ La frontera: cuándo un script deja de ser un script.
Bloque C   Herramientas y aplicaciones. El ecosistema completo.
```

**El Bloque A hace dos cosas a la vez.** Rompe el reflejo de *"agrego una dependencia para
parsear una fecha"* —que en el mundo Maven es gratis y en Python se paga caro, en superficie de
ataque, en reproducibilidad y en lo que tenga que instalar la persona que use tu herramienta— y
demuestra de paso que la biblioteca estándar **es** el reemplazo del shell. `pathlib`,
`subprocess`, `csv`, `json`, `tomllib`, `sqlite3`, `zipfile`, `argparse`, `http.server` vienen
en la caja, y alguien que viene de Java no tiene forma de saber cuánto viene en la caja.

**El Bloque B es la pieza central.** No es un trámite de empaquetado: es donde aprendes a
reconocer que tu script cruzó una línea, y a migrarlo sin reescribirlo. Si el curso funciona,
es la parte que vas a citar tres años después, probablemente discutiendo con alguien que quiere
empezar por el proyecto.

**El Bloque C es donde Python compite de frente** con lo que ya sabes hacer, y donde las
mediciones dejan de ser curiosidades y empiezan a decidir arquitecturas.

---

## 🪜 Las 18 fases

Esta tabla es la numeración oficial del curso. El número del archivo es el número de la fase, y
no cambia.

| # | Fase | Bloque | Registro | El reflejo que ataca 🪞 | Proyecto |
|---|---|---|---|---|---|
| 00 | 🛠️ Ambiente, editores y el mapa del ecosistema | A | — | "el IDE me resuelve el entorno" | — |
| 01 | 🧬 El modelo de datos | A | script | `==` contra `equals`; el argumento por defecto mutable | **nace el CLI** |
| 02 ⭐ | 🔁 Secuencias perezosas | A | script | construir la lista completa antes de recorrerla | CLI |
| 03 | 🎩 Python sin ceremonia | A | script | la clase con un solo método, la herencia profunda, el `AbstractBase` | CLI |
| 04 | 💥 Errores y recursos | A | script | comprobar antes en vez de intentar; el `catch` que se traga todo | CLI |
| 05 ⭐ | 🐚 El shell con esteroides | A | script | `shell=True` y concatenar cadenas | CLI |
| 06 | 📦 Formatos en la caja | A | script | buscar una biblioteca para lo que ya viene | CLI |
| 07 ⭐ | 🚪 Cuándo deja de ser un script | B | script → herramienta | empezar por el proyecto en vez de terminar en él | **el CLI migra** |
| 08 | 🔎 El contrato del código | B | herramienta | creer que el verificador es el compilador | CLI |
| 09 ⭐ | 🎁 Entregarle la herramienta a Patricia | B | herramienta | "que se instale Python y clone el repo" | CLI |
| 10 | ⚡ FastAPI y la validación en el borde | C | aplicación | validar dentro del servicio en vez de en la frontera | **nace la API** |
| 11 | 🗄️ Persistencia | C | aplicación | asumir que el ORM es Hibernate | API |
| 12 | 🏛️ Django y el veredicto web | C | aplicación | creer que son dos calidades y no dos registros | **nace el back-office** |
| 13 | 🌐 Integraciones | C | aplicación | el reintento que duplica el cobro | API |
| 14 ⭐ | 🧵 Concurrencia y el GIL | C | aplicación | `synchronized` cuando el estado vive en Postgres | los tres |
| 15 | 🌙 El proceso nocturno | C | aplicación | el cierre que no es reanudable ni idempotente | **nace el batch** |
| 16 | 🔭 Operación y rendimiento | C | aplicación | `print` como log; optimizar encima de una consulta mala | los cuatro |
| 17 🏁 ⭐ | ⚔️ El duelo y el veredicto | C | aplicación | comparar contra un competidor de paja | **la API ×2** |

Las fases marcadas ⭐ son las que sostienen la tesis del curso. Si tuvieras que saltarte algo
—no deberías— esas cinco son las que no.

---

## 💼 Los cuatro proyectos

El curso no construye ejemplos: construye software para **Áurea**, una red odontológica
colombiana de diez sedes, cuatro propias y seis franquiciadas. Su historia completa —los
personajes, las cifras, las reglas de negocio y por qué el software está como está— vive en
[`00-historia-de-aurea.md`](00-historia-de-aurea.md), y cada fase te da el pedazo que necesita.

Cada proyecto cubre un registro distinto, ninguno se solapa con otro, y ninguno nace al final
como un capstone desconectado: nacen temprano y crecen contigo.

| # | Registro | Qué es en Áurea | Nace |
|---|---|---|---|
| 1 | **Herramienta CLI** | La caja de herramientas de Patricia: consolida los archivos de las diez sedes, valida antes de generar, y produce lo que el país exige | Fase 01 |
| 2 | **API de servicio** | La agenda de la red: disponibilidad de diez sedes, identidad del paciente a través de la red, reservas desde la web y el bot | Fase 10 |
| 3 | **Monolito con baterías** | El back-office: cuarenta pantallas, permisos por sede y auditoría de accesos, con una usuaria que no es ingeniera | Fase 12 |
| 4 | **Proceso por lotes** | El cierre nocturno: conciliación, glosas por vencer, liquidación de regalías y comisiones | Fase 15 |

El primero es el que sostiene la tesis. **Nace como un archivo suelto de cuarenta líneas en la
Fase 01 y solo se vuelve paquete en la Fase 07**, seis fases después, cuando ya no le cabe la
ropa. Ese arco es el curso entero en miniatura.

Y hay una costura deliberada entre el primero y el cuarto: en la Fase 15, **el proceso nocturno
importa el CLI como biblioteca**. La misma validación que Patricia corre a mano es la que corre
desatendida a las dos de la mañana sobre las diez sedes. Es el momento donde se cobra, en uso
real, todo lo que hiciste bien en la Fase 07.

---

## 🧩 Cómo funciona cada fase

Todas las fases tienen la misma forma, diez secciones y en el mismo orden, para que sepas
siempre dónde buscar:

**🎯 Propósito** y **✅ Qué queda listo al terminar** abren con lo concreto: qué vas a poder
decidir o construir, en forma de checklist verificable. Verificable quiere decir que se
comprueba ejecutando algo; "entender los generadores" no es un resultado.

**🚫 Qué NO entra todavía** dice qué se difiere y a qué fase exacta. Es tan importante como lo
que entra: la mitad de la pedagogía del curso está en el orden.

**🧠 Concepto mínimo** trae solo la teoría que hace falta para escribir el código de esa fase, y
es donde viven las secciones narrativas: 🪞 *tu instinto de Java dice… y esta vez se equivoca*,
🩻 *esto sí funciona igual*, y el 📖 diccionario de traducción, que va siempre en las dos
direcciones y declara dónde se rompe el paralelo. Una analogía sin su límite es peor que
ninguna.

**💻 Código mínimo con comentarios** es el grueso. Código que corre, escrito **en el registro de
su fase**: en el Bloque A no vas a ver una clase decorativa ni una dependencia, porque escribir
una aplicación en el Bloque A es justamente el error que el curso enseña a no cometer.

**📏 Medición** es el número que produce la fase, con su hipótesis, sus condiciones, su
competidor y su veredicto. El arnés es el mismo para todo el curso y se construye en la Fase
02, con biblioteca estándar. La regla detrás no admite excepciones cómodas: **ninguna
afirmación comparativa entra al curso sin un número**, y el competidor tiene que ser una
implementación que alguien defendería en una revisión de código. Una fase que no mide nada lo
dice en una línea y explica por qué.

**🧱 Miniproyecto** es obligatorio, uno por fase, difícil, y anclado al dominio de Áurea. Es la
**única** unidad de práctica grande del curso —aquí no hay cuaderno de incidentes ni batería de
ejercicios de relleno—, y por una razón: para este perfil, lo que consolida es un encargo
completo, no un ejercicio de rellenar huecos. Calcula entre dos y cinco horas cada uno.

**🧪 Ejercicios**, entre veinte y veinticinco, graduados 🟢🟡🟠🔴. La escala está calibrada para
ti: un 🟢 no es "copia el ejemplo", es "aplica lo de la fase a un caso que el texto no resolvió".
Un tercio son de diagnóstico o de medición —se te entrega algo que funciona mal y se te pide
localizarlo, explicarlo y cuantificarlo— y al menos dos por fase son **de registro**: dado un
encargo, decidir si es script, herramienta o aplicación, y justificarlo con el costo de las
otras dos opciones.

**📚 Referencias** y **🚀 Cierre** terminan la fase. El cierre incluye el recordatorio del tag:
cada fase se cierra en git con `fase-NN`, y cada miniproyecto con `mini-NN`, cuyo mensaje lleva
el número que arrojó su medición. La convención completa está en
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

### Las deudas, y por qué el curso las declara

Vas a ver el marcador 💸 por todo el material. Marca una **deuda técnica intencional**: un
atajo que el curso toma a propósito, con dos partes escritas siempre juntas —qué sería lo
correcto, y **en qué fase se paga**.

La primera aparece en la Fase 01, donde el CLI nace leyendo sus archivos con `open` y
`split(",")`, que es la forma equivocada, y se paga en la Fase 06 cuando ya te estrellaste con
una celda que traía una coma adentro. Una deuda 💸 sin fase de cobro sería un error de
escritura, no una licencia.

---

## 🚫 Qué NO tiene este curso

**No tiene apéndices.** Es la decisión de forma más visible del curso, y es deliberada. Todo lo
que en otro curso sería material de consulta —el
ambiente, las herramientas, el puente entre versiones— es aquí una fase o una sección de una
fase. El ambiente de trabajo, por ejemplo, es la Fase 00 entera. Las razones: no necesitas
material de consulta de nivel básico, un apéndice de herramientas se desactualiza en silencio
mientras que dentro de una fase el desfase se ve al primer intento de ejecución, y el apéndice
suele ser donde se esconde lo que no supimos ubicar.

**No enseña a programar.** Sintaxis, estructuras de control y tipos primitivos se dan por
sabidos. Solo entra lo que difiere de Java de forma que produzca un error.

**No enseña teoría de aprendizaje automático ni cómputo científico pesado.** Los complementos
`ia` y `ds` enseñan a **usar y medir** un modelo, y a decidir si valía la pena; cómo se deriva un
gradiente o por qué converge un optimizador queda declarado fuera. La exclusión se declara en vez
de rozarse, y no se enlaza a ninguna parte.

**No hay fase de contenedores ni de orquestación.** La Fase 17 usa un contenedor porque lo
necesita para medir arranque en frío y costo, y ese es todo el alcance.

**No hay repositorio de partida.** Escribes el código desde cero, por la misma razón de siempre:
quien lee código ajeno no distingue una decisión de un accidente.

Lo que hay **después** de las dieciocho fases son dos cosas distintas, y conviene no
confundirlas.

Los **complementos `ia` y `ds`** son la continuación del curso: diecisiete secciones que
construyen los cuatro proyectos de IA y de datos que Áurea ya tiene planteados —NormaRAG y
Recepción asistida, Embudo y Ausentismo— sobre el código que tú dejaste escrito en el camino
base. Traen la misma plantilla de diez secciones, la misma medición obligatoria y el mismo
miniproyecto, y sus archivos son `ia01-…` y `ds01-…`. Se toman después de la Fase 17 porque
necesitan la API, el CLI y la base de datos funcionando.

Los **tracks a la carta** son otra cosa: secciones sueltas y opcionales que se leen cuando
necesitas una herramienta concreta, sin orden y sin compromiso. Tienen su propia sección, la
siguiente.

---

## 🍽️ La carta

La carta son **176 secciones en 22 tracks**, de unas 260 líneas cada una, sobre lo que el
camino base no alcanza a cubrir: legado e intercambio sectorial, automatización contra sistemas
ajenos, correo y transferencia de archivos, orquestación, pruebas, observabilidad, seguridad,
plantillas, interfaces sin frontend, una docena de motores de datos, la convivencia con la JVM, y así
hasta la visión por computador y los juguetes para enseñar. Sus archivos empiezan por `op`
(`op065-ui02-gradio.md`), de modo que todo lo opcional queda en un solo bloque al final y el camino
base se lista limpio.

El número `opNNN` es el orden en que se escribieron, no un orden de lectura. **Primer turno:** los
once tracks que tienen un encargo directo en Áurea, desde los portales de las aseguradoras que no
tienen API hasta el MySQL de Odontovía. **Segundo turno:** los seis cuyo encargo es real pero no
urgente. **Tercer turno:** los cinco que no tienen encargo en Áurea y usan su propio ejemplo, el que
la herramienta pide.

| Track | Tema | Secciones | Empieza en | Turno |
|---|---|---|---|---|
| `lg` | Legado e intercambio sectorial | 7 (op001–op007) | [`lg01`](op001-lg01-ancho-fijo-y-mainframe.md) | 1.º |
| `au` | Automatización externa | 7 (op008–op014) | [`au01`](op008-au01-http-contra-sistemas-ajenos.md) | 1.º |
| `co` | Comunicaciones y transferencia | 7 (op015–op021) | [`co01`](op015-co01-correo-saliente.md) | 1.º |
| `wf` | Orquestación de trabajos y flujos | 8 (op022–op029) | [`wf01`](op022-wf01-el-eje.md) | 1.º |
| `qa` | Calidad, pruebas y mantenimiento | 10 (op030–op039) | [`qa01`](op030-qa01-la-piramide-para-uno.md) | 1.º |
| `ob` | Observar el sistema propio | 7 (op040–op046) | [`ob01`](op040-ob01-las-senales.md) | 1.º |
| `se` | Seguridad aplicada y criptografía | 8 (op047–op054) | [`se01`](op047-se01-el-modelo.md) | 1.º |
| `tx` | Texto, plantillas y documentación | 9 (op055–op063) | [`tx01`](op055-tx01-el-eje.md) | 1.º |
| `ui` | Interfaces y entregables sin frontend | 13 (op064–op076) | [`ui01`](op064-ui01-el-modelo-y-su-costo.md) | 1.º |
| `db` | Hablarle a cada sistema de datos | 15 (op077–op091) | [`db01`](op077-db01-el-db-api.md) | 1.º |
| `jv` | Convivir con tu stack Java | 4 (op092–op095) | [`jv01`](op092-jv01-los-formatos-de-la-jvm.md) | 1.º |
| `so` | Optimización, simulación y decisiones | 7 (op096–op102) | [`so01`](op096-so01-describir-en-vez-de-programar.md) | 2.º |
| `or` | ORMs y acceso a datos | 8 (op103–op110) | [`or01`](op103-or01-el-eje.md) | 2.º |
| `vz` | Visualización y gráficos | 4 (op111–op114) | [`vz01`](op111-vz01-el-modelo-y-matplotlib.md) | 2.º |
| `sy` | El sistema operativo y los procesos | 8 (op115–op122) | [`sy01`](op115-sy01-subprocess-a-fondo.md) | 2.º |
| `pr` | Protocolos y contratos más allá de REST | 8 (op123–op130) | [`pr01`](op123-pr01-el-eje.md) | 2.º |
| `pk` | El panorama de gestores y empaquetado | 8 (op131–op138) | [`pk01`](op131-pk01-el-modelo-real.md) | 2.º |
| `ff` | La frontera nativa | 8 (op139–op146) | [`ff01`](op139-ff01-el-modelo.md) | 3.º |
| `ar` | Archivos y multimedia | 10 (op147–op156) | [`ar01`](op147-ar01-binario-de-verdad.md) | 3.º |
| `gi` | Geoespacial | 7 (op157–op163) | [`gi01`](op157-gi01-el-modelo.md) | 3.º |
| `cv` | Visión por computador | 8 (op164–op171) | [`cv01`](op164-cv01-el-modelo.md) | 3.º |
| `ed` | Didáctica, divulgación y juguetes | 5 (op172–op176) | [`ed01`](op172-ed01-turtle.md) | 3.º |

**Cómo se lee una sección.** Suelta: ninguna necesita otra sección de la carta, y las que se apoyan
en una fase del camino base lo dicen en su encabezado. Todas tienen la misma forma —qué problema
resuelve, el modelo, un ejemplo completo que corre, lo que se rompe, cuándo **no** usar la
herramienta, entre ocho y doce ejercicios con su criterio verificable, referencias y cierre— y
todas cierran con su tag, en su propio espacio de nombres: `op-<track>-fase-NN`
(`git tag -l 'op-*'` lista solo la carta, y `git tag -l 'fase-*'` sigue siendo el camino base).

**Qué se garantiza del código.** Cada ejemplo se corrió en un contenedor con Python 3.14.7, contra
los servicios reales cuando los hay (bases de datos, colas, correo, un PostGIS), y las salidas que
publica la sección son las de esa corrida, con su fecha. De las 176, **173 se probaron enteras** y
3 en parte; esas tres dicen en su encabezado qué quedó sin correr y por qué. El código de cada una
está además en `src/opNNN-…/`, extraído de la sección tal como se publica. Las versiones de cada
paquete se verificaron contra PyPI el día en que se escribió el track, y van en el texto. La carta cubre
Linux y macOS: lo que solo corre en Windows se dice y no se escribe. Los servicios corren en
contenedores con un `compose.yaml` dentro de la sección, y los modelos que hagan falta se bajan una
vez, de una URL fija que la sección nombra.

**Qué no es la carta.** No es la continuación del curso —eso son los complementos `ia` y `ds`— ni
una lista de lectura obligatoria. Sus secciones no tienen miniproyecto ni medición `⏳`: tienen
ejercicios con criterio, y las cifras que citan son de una corrida, dichas como tales.

---

## 🧭 Cómo se recorre

**En orden, y sin saltarse el Bloque A.** Suena a advertencia de manual, así que vale la pena
decir exactamente qué se pierde quien lo salte, porque es la tentación más obvia de este perfil:
ya sabe programar, quiere llegar a FastAPI, y las siete primeras fases parecen calentamiento.

No lo son. El Bloque A es donde se rompe el reflejo. Si llegas al Bloque C sin haber escrito
seis fases de Python sin capas, vas a escribir FastAPI con estructura de Spring —servicios,
repositorios, una interfaz por cada implementación— y va a funcionar, que es lo peor que puede
pasar, porque nada te va a avisar. El Bloque C no corrige ese reflejo: lo amplifica.

Quien de todos modos quiera ir directo al Bloque C, puede — es material de adultos. El costo es
concreto: se pierde el arnés de medición, que se construye en la Fase 02 y usan las quince fases
siguientes; se pierde el arco del CLI, que es donde la tesis se demuestra en vez de enunciarse;
y se llega a la Fase 14 sin el modelo de datos de la Fase 01, que es donde está la mitad de las
respuestas sobre qué se comparte entre hilos y qué no.

**Con la máquina delante.** Cada fase asume que ejecutas su código y corres su miniproyecto. El
checklist de la sección 2 se verifica ejecutando, no leyendo.

**Con el repositorio desde el primer día.** Se crea en la Fase 00 y se etiqueta al cerrar cada
fase. No es burocracia: es lo que permite volver a un punto, leer la factura de cada deuda con
un `git diff` entre dos tags, y comparar tu número de la Fase 15 con el de la Fase 02.

### Cuánto toma

El curso publica **bandas de dedicación por bloque**, no horas por fase. Una tabla de horas por
fase que nadie puede cumplir desprestigia al resto del documento, y aquí el tiempo real lo
domina el encargo, no la lectura: dos personas con el mismo material tardan lo mismo leyendo y
muy distinto construyendo.

Las bandas están calculadas sobre el material ya escrito, y conviene decir **de dónde salen**,
porque eso es lo que te permite ajustarlas a tu ritmo:

| Bloque | Fases | Lectura | Miniproyectos | Ejercicios (un tercio) | **Banda** |
|---|---|---|---|---|---|
| **A** · el script | 7 | 4.6 h | 14–35 h | ~19 h | **40–60 h** |
| **B** · la frontera | 3 | 1.9 h | 6–15 h | ~8 h | **15–25 h** |
| **C** · la aplicación | 8 | 4.8 h | 16–40 h | ~22 h | **45–65 h** |
| **Total** | 18 | **11.4 h** | 36–90 h | ~49 h | **100–150 h** |

La lectura es un número medido: **137.000 palabras** a 200 por minuto. Los miniproyectos salen de
su calibración —entre dos y cinco horas cada uno—, y la columna de ejercicios supone que haces
**uno de cada tres** de los 450, a unos veinte minutos. Si los haces todos, suma otras cien horas;
si no haces ninguno, resta cuarenta y nueve y el curso sigue funcionando, aunque bastante peor.

La carta no entra en estas bandas, porque no se recorre entera: son unas **262.000 palabras** de
prosa (sin contar el código), unas **22 horas** de lectura a ese mismo ritmo, y **1.722 ejercicios**.
Una sección son unas 1.500 palabras, ocho minutos de lectura; el resto es correr el ejemplo y los
ejercicios que elijas.

> 📝 **Lo que estas bandas no capturan** es el tiempo que vas a pasar peleando con algo que no
> entiendes, que es donde de verdad se aprende y que no se puede estimar. Tómalas como el piso, no
> como el presupuesto.

---

## ⚖️ Cómo termina

Con el veredicto. La Fase 17 implementa **el mismo endpoint dos veces** —en FastAPI y en Spring
Boot 3, con el mismo arnés— y mide rendimiento, arranque en frío, consumo, líneas de código y
costo mensual al volumen real de Áurea. Después escribe dónde Python no era la respuesta.

Eso no es un gesto de humildad al final: es el contenido. Alguien que sale de aquí sabiendo
elegir entre tres registros pero incapaz de decir *"esto debió quedarse en Java"* no aprendió a
decidir, aprendió a preferir.

> **Y la frase que cierra el curso, que conviene tener presente desde ahora:** si al final
> resultara que Python ganó todo, el curso estaría mal escrito.
