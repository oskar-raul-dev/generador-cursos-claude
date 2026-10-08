# ✍️ Guía de estilo, tono y convenciones

## Arquitectura de software — repaso para entrevistas de Backend Senior y Tech Lead

Esta guía es la fuente de verdad editorial de `repaso-arquitectura-entrevistas/` y manda
sobre **los cinco bloques** (`01-bases`, `02-eventos`, `03-datos`, `04-seguridad`,
`05-banca`). Cualquier chat que produzca o edite un `.md` de este corpus la sigue. Su
objetivo es que todos los documentos se lean como escritos por la misma mano y apunten al
mismo lugar: **que puedas defender una decisión de arquitectura en voz alta, en dos
minutos, delante de alguien que va a discutírtela**.

Desciende de la guía de [`repaso-entrevistas/cloud/01-aws`](../../../cloud/01-aws/prompts/guia-de-estilo-y-convenciones.md),
de la que hereda el tono, la pedagogía del andamio, el vocabulario visual y las reglas de
enlace. **Diverge en cuatro puntos declarados** —§4.2, §5, §7 y §8— por una razón de
fondo: aquel curso enseña a operar una nube que factura, y este enseña a razonar un
sistema. Aquí no hay comandos que ejecutar, ni cuenta que pague, ni recursos que destruir.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que mañana
tiene una entrevista y pasado mañana tiene que diseñar de verdad el sistema del que habló.

> **Vigencia:** 2026-09-18.

---

## 1. 🧭 Principio rector

**Todo lo que se escribe apunta a que alguien reconozca, explique, compare y decida —y
pueda decirlo en voz alta.**

No enseñamos arquitectura "completa". El catálogo de patrones tiene cientos de entradas y
recitarlas no hace a nadie mejor arquitecto; de hecho es la señal más clara de que alguien
estudió para el examen. Repasamos el vocabulario, los mecanismos y los matices que separan
a quien entiende el modelo de quien aprendió la lista.

```text
Un curso        → te enseña a construir el sistema.
Este repaso     → te enseña a decir por qué lo construirías así, y a qué precio.
```

El filtro para cada párrafo es este: **¿esto ayuda a reconocer, explicar, comparar o
decidir?** Si no, sobra. Aunque esté muy bien escrito.

Y el corolario, repetido tantas veces como haga falta:

> Cada concepto cierra con un veredicto. Cada patrón se nombra con su precio. Cada
> decisión responde a "¿por qué esto y no lo otro, y qué pierdo al elegirlo?".

Un patrón descrito sin su precio no está explicado: está anunciado. Y una sección que no
se puede convertir en una respuesta hablada está mal escrita para este corpus, por
correcta que sea.

---

## 2. 🎤 Tono

El tono es **semi formal, cálido y directo**, de colega a colega. Piensa en alguien que ya
pasó por esto —la entrevista donde propuso microservicios y le preguntaron por la
transacción, el `@Transactional` que no funcionaba y costó dos días, el sistema que se cayó
porque un servicio secundario se puso lento— y te lo explica con paciencia y sin solemnidad
de manual corporativo.

Cómo se ve en la práctica:

- **Tuteo latinoamericano, siempre.** Le hablas al lector de "tú": *"cuando te pregunten
  esto, lo que buscan es aquello"*, *"si esto te suena a ceremonia, es porque muchas veces
  lo es; aguanta dos secciones"*. Nada de voseo, nada de "usted", nada de impersonal
  permanente ("se debe separar el dominio…") que enfría el texto.
- **Semi formal.** Cercano, pero no chat. Frases completas, puntuación correcta, cero
  abreviaturas de mensajería.
- **Humor mínimo y seco.** Como mucho **un desdramatizador por documento**, y si no fluye
  solo, se borra. Este corpus se lee antes de una entrevista: el registro es de repaso
  serio, no de charla.
- **Honesto sobre la ceremonia.** Cuando un patrón sobra, se dice que sobra. *"Hexagonal
  en un CRUD sin reglas es carpeta ceremonial"* es contenido; *"hexagonal aísla el
  dominio"* es un folleto. El entrevistador valora más el criterio que el entusiasmo, y
  este corpus también.
- **Honesto sobre las simplificaciones.** Cuando la respuesta común de entrevista es una
  sobregeneralización —"microservicios escalan mejor", "el modelo anémico es un
  antipatrón", "uso exactly-once", "escalo horizontalmente"— **se nombra la simplificación
  y se da la versión precisa**. Este es el recurso pedagógico central del corpus, por
  encima de la analogía y del ejemplo. La sección `## ⚠️ Errores frecuentes` de cada
  capítulo existe para esto.
- **Honesto sobre el precio.** El equivalente aquí del "todo lo que cobra por hora se
  nombra con precio y unidad" de AWS: **todo patrón se nombra con lo que cuesta**, y el
  coste se expresa en las cuatro monedas reales de la arquitectura —latencia,
  consistencia, operación y dinero—. No hay eufemismos tipo "añade algo de complejidad":
  se dice qué complejidad, dónde y quién la paga.
- **Sin absolutos falsos.** Nada de "siempre" ni "nunca" salvo cuando es literalmente
  cierto (*una transacción, un agregado*; *exactly-once no existe de extremo a extremo*).
- **Cálido sin condescendencia.** Explicamos desde cero, pero nunca infantilizamos. "Como
  para un bebé" significa **cero ambigüedad**, no menos profundidad — ver §4.
- **Sin relleno motivacional.** Sin "¡tú puedes!", sin "vas a dominar la arquitectura".
  Quien lee ya sabe por qué está repasando, y probablemente tiene la entrevista cerca.

---

## 3. 🗣️ Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no sea código.
- **Los nombres de patrón, estilo y término del oficio se quedan en inglés** cuando son el
  nombre real de la cosa: *bounded context*, *ports and adapters*, *eventually
  consistent*, *backpressure*, *dirty checking*, *strangler fig*, *thundering herd*,
  *circuit breaker*, *outbox*. Traducirlos a la fuerza ("contexto delimitado", "cortafuegos
  de circuito") confunde y no es lo que el lector va a oír en la entrevista ni leer en la
  bibliografía. Los que ya tienen traducción asentada —capa, dominio, agregado, evento,
  cola— se usan en español con naturalidad; lo importante es no inventar vocabulario.
  **La primera vez que aparece un término en inglés, se da su traducción entre
  paréntesis**; después ya no.
- **Markdown siempre.** Nada de HTML embebido.
- **Estructura visual primero, pero la prosa no es el último recurso.** El orden de
  preferencia es diagrama ASCII → tabla → lista → párrafo *para exponer una relación entre
  cosas*. Pero el **porqué** de una decisión se escribe en prosa: una tabla no puede
  explicar por qué separar un servicio no compra rendimiento aunque todo el mundo lo crea.
- **Nada de prosa telegrama.** Una frase corta y sola, con líneas en blanco a ambos lados,
  es un buen golpe de ritmo. Tres seguidas son un telegrama, y el lector deja de encontrar
  el argumento porque no hay párrafo donde buscarlo. Regla práctica: **una frase aislada
  por sección, dos si la sección es larga**.
- **Diagramas ASCII en bloques ` ```text `.** Es el recurso visual principal del corpus y
  se usa sin timidez para flujos, jerarquías, máquinas de estados, cadenas de fallo y
  árboles de decisión. Simples: cajas, flechas, texto. Sin arte ASCII elaborado.
- **Tablas solo para comparar o mapear**, con tres o cuatro columnas como norma: "SOA vs
  microservicios", "hexagonal vs limpia", "se dice / lo preciso", síntoma→causa. **Si
  necesitas explicar una celda, ya no es una tabla**: es una lista con subtítulos o un par
  de párrafos. Nunca se narra en tabla.
- **Encabezados con emoji, con moderación.** Uno por sección `##` numerada, **ninguno en
  las subsecciones `###`**, sin excepciones en este corpus. El emoji es funcional: señala
  de qué tipo es la sección (🎯 el problema, 🧱 mecanismo o estilo, ⚖️ comparación, 🧭
  criterio de elección, 🩺 diagnóstico, 🪦 lo que ya no se usa, ⚠️ errores frecuentes, 🧠
  preguntas, 📚 referencias). Un documento que parece un teclado de emojis pierde
  autoridad.

---

## 4. 🎓 Pedagogía: "como para un bebé"

El principio se enuncia igual que en el curso del que desciende:

> **"Como para un bebé" significa cero ambigüedad, no menos profundidad.**

No es escribir más simple: es no dejar ningún hueco donde el lector tenga que adivinar. Se
explica qué es un puerto, en qué se diferencia de una interfaz cualquiera, dónde vive el
archivo y qué cambia exactamente respecto de la arquitectura en capas. No se dice "el
dominio queda aislado" y se sigue adelante.

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar el patrón, muestra el dolor que resuelve.
   *"Tu entidad tiene `setEstado()`. Alguien llama a `pedido.setEstado(ENVIADO)` sobre un
   pedido sin pagar. No hay error: hay un pedido enviado y no cobrado, y lo descubre
   contabilidad tres semanas después."*
2. **El mecanismo después.** Ahora sí, el nombre y la definición mínima: lo justo para
   usarlo hoy, no el capítulo completo del libro.
3. **El código o el diagrama que lo demuestra.** El fragmento más pequeño que fija el
   punto, con la viñeta que dice qué mirar en él.

Presentar el patrón antes que el problema produce gente que sabe recitar "hexagonal aísla
el dominio de la infraestructura" y no sabe cuándo *no* usarlo — que es exactamente lo que
la entrevista pregunta.

Por eso **`## N. 🎯 El problema` es la sección de apertura obligatoria de todo capítulo**.

### 4.2 Ningún bloque de código queda sin desglose, y ninguna afirmación sin precio

**Divergencia declarada respecto de AWS/GCP.** Allí la regla era "ningún comando ni ningún
flag queda sin explicar", porque el lector ejecutaba contra una cuenta que le cobraba. Aquí
el código es **ilustrativo, no ejecutable**, así que la regla se traduce en dos mitades que
sí aplican, y ninguna admite excepciones.

**Primera mitad: el código.** Ningún bloque aparece sin una frase antes que diga qué
demuestra y sin viñetas después que digan qué mirar en él. Un bloque `java` suelto es un
error de estilo igual que lo era un bloque `bash` suelto.

```java
// Puerto: vive en el dominio. Habla de negocio, no de persistencia.
public interface RepositorioDePedidos {
    Optional<Pedido> porId(PedidoId id);
    void guardar(Pedido pedido);
}
```

- Fíjate en **dónde vive la interfaz**: en el dominio, no junto a su implementación. Esa
  es toda la diferencia con la arquitectura en capas.
- La firma habla de `Pedido` y `PedidoId`, no de `PedidoEntity`: el dominio no conoce el
  modelo de tablas.

Ese nivel es el estándar. Y los bloques de Java se mantienen **mínimos**: la firma y las
tres líneas que importan, nunca una clase completa con getters. Si un bloque introduce tres
cosas desconocidas, se parte en tres bloques.

**Segunda mitad: el precio.** Toda afirmación de beneficio lleva su contrapartida en la
misma sección, en las cuatro monedas de la arquitectura:

```text
latencia · consistencia · operación · dinero
```

*"Separar un servicio compra despliegue independiente y autonomía de equipo, y lo paga con
latencia de red, consistencia eventual, complejidad operativa y coste de infraestructura"*
está completo. *"Los microservicios dan escalabilidad"* no lo está.

### 4.3 Explica el porqué, no solo el cómo

Una regla sin justificación es una regla que el lector no puede adaptar cuando su caso real
difiera del ejemplo. Cada decisión relevante lleva su porqué, aunque sea media línea entre
paréntesis: por qué la interfaz del repositorio vive en el dominio, por qué el evento se
nombra en pasado, por qué el timeout se calcula desde el p99 y no a ojo.

Cuando el porqué es histórico y no técnico —que en arquitectura pasa seguido— se dice
también: *"el GoF se escribió en 1994 contra C++ y Smalltalk, y varios patrones son rodeos
alrededor de limitaciones del lenguaje, no verdades eternas"*.

### 4.4 Ancla en Spring, no en abstracciones

El equivalente aquí del "nada de cajas negras prematuras" de AWS. Todo concepto abstracto
se aterriza en algo que el lector ya usa sin saberlo, **en el mismo párrafo en que se
introduce**:

- `@Transactional` es Unit of Work, y además es Proxy.
- `JdbcTemplate` es Template Method — por eso se llama así.
- El contexto de persistencia de JPA es Identity Map, y es el caché de primer nivel.
- `BeanPostProcessor` es Decorator; la cadena de `Filter` es un pipeline.

Un concepto que no se puede anclar en el stack del lector se explica igual, pero se declara
que no tiene anclaje. Lo que no se hace es dejarlo flotando.

### 4.5 Analogías con fecha de caducidad

Las analogías se usan **una vez, para abrir la puerta**, y después se abandonan diciendo
dónde se rompen. Un repositorio se parece a una colección en memoria *hasta que descubres
que `findAll()` sobre un millón de filas no es lo mismo que recorrer una lista*. Una
analogía que no se cierra genera bugs conceptuales que aparecen tres capítulos después.

Cuidado especial con las cuatro más peligrosas del temario, que se desmontan en el mismo
párrafo en que aparecen:

- **un microservicio no es "un servicio pequeño"** (es uno dueño de sus datos);
- **hexagonal, limpia y cebolla no son "lo mismo"** ni son "tres cosas distintas";
- **un circuit breaker no protege al servicio caído** (protege al que llama);
- **exactly-once no es una garantía que puedas elegir**.

### 4.6 Densidad calibrada, con techo de longitud

**Divergencia declarada respecto de AWS/GCP**, que retiraba el techo de longitud. Aquí lo
reponemos, y el motivo es el calendario: este corpus compite con una entrevista que puede
caer la semana que viene, no con un libro.

- **Banda objetivo: 200 a 350 líneas por capítulo.** Un capítulo que pasa de 400 se poda o
  se parte, y la decisión se declara en el README del bloque.
- Un concepto nuevo por vez.
- Repetir lo importante está bien. Los conceptos que sostienen el corpus —acoplamiento
  temporal, consistencia eventual, el precio de separar, dónde vive la invariante—
  reaparecen con otras palabras. La repetición espaciada funciona; la enciclopedia no.
- Ninguna sección supera las dos pantallas sin un diagrama, una tabla, un bloque de código
  o un veredicto.
- **Todo documento de más de ~400 líneas abre con un índice de salto rápido** (§6.2). Hoy
  el único caso es el solucionario de cada bloque.

### 4.7 Cierra los bucles

Si abres un paréntesis —*"esto se ve en `07`"*, *"el outbox está en `02-eventos`"*— tiene
que cerrarse en algún documento del corpus, y con enlace real. Un pendiente que nunca se
resuelve es ruido y el lector deja de confiar en las promesas del texto.

**Mientras un bloque no exista, el enlace apunta a su README**, nunca a un archivo que no
está escrito. Un enlace roto dentro del propio corpus es peor que un enlace externo caído:
el externo tiene disculpa, el interno no.

---

## 5. 💻 Idioma del código y dominio de ejemplo

> **Regla normativa: todo lo que se ejecuta o se versiona va en inglés —tipos de
> framework, anotaciones, palabras clave— y todo lo que es dominio de negocio va en
> español, igual que los comentarios.**

**Divergencia declarada respecto de AWS/GCP.** Allí los nombres de recurso iban en inglés
porque eran identificadores reales en una nube. Aquí los identificadores son **modelo de
dominio**, y el dominio se nombra en el idioma del negocio: es la aplicación directa del
lenguaje ubicuo que el propio corpus enseña en `01-bases/06`. Escribir `OrderRepository` en
un capítulo que predica nombrar las cosas como las nombra el negocio sería incoherente.

| Elemento | Idioma | Ejemplo |
|---|---|---|
| Nombres de patrón, estilo y concepto | Inglés (nombre canónico) | *Strategy*, *ports and adapters*, *outbox* |
| Tipos y anotaciones del framework | Inglés (son API real) | `@Transactional`, `JpaRepository`, `Optional<T>` |
| Clases, métodos y campos del dominio | **Español** | `Pedido`, `porId()`, `estado`, `RepositorioDePedidos` |
| Estados y enumerados del dominio | Español, mayúsculas | `PAGADO`, `ENVIADO`, `SUSPENDIDA` |
| Comentarios dentro del código | Español | `// la invariante vive aquí` |
| Narrativa alrededor del código | Español | todo el texto fuera de los bloques |
| Términos del oficio consolidados | Inglés sin traducir | *eventually consistent*, *backpressure* |

### 5.1 Dominios de ejemplo estables

El equivalente aquí de los nombres fijos del laboratorio de AWS. **No se inventan dominios
nuevos por capítulo.** El corpus usa dos, y cada uno tiene su función:

**Dominio principal — comercio electrónico.** Es el que se usa por defecto, porque todo el
mundo lo entiende sin explicación previa y permite ejemplos de todos los estilos.

| Concepto | Nombres fijados |
|---|---|
| Agregados y entidades | `Pedido`, `LineaPedido`, `Cliente`, `Producto`, `Reserva` |
| Identificadores | `PedidoId`, `ClienteId`, `ProductoId` |
| Objetos de valor | `Money`, `Iban`, `RangoDeFechas` |
| Puertos | `RepositorioDePedidos`, `PuertoDeCobro` |
| Adaptadores | `RepositorioDePedidosJpa`, `PasarelaHttpAdapter` |
| Entidades de persistencia | `PedidoEntity`, `PagoEntity` |
| Eventos | `PedidoConfirmado`, `PedidoEnviado`, `PagoRechazado` |
| Contextos y servicios | `Catálogo`, `Carrito`, `Pedidos`, `Pagos`, `Inventario`, `Envíos`, `Clientes` |

**Dominio secundario — banca.** Se usa cuando el ejemplo necesita reglas reguladas,
consistencia dura o legado, y **siempre** en el bloque `05-banca`.

| Concepto | Nombres fijados |
|---|---|
| Agregados | `Cuenta`, `Transferencia`, `Poliza`, `Solicitud` |
| Estados de transferencia | `SOLICITADA`, `DEBITADA`, `ACREDITADA`, `COMPLETADA`, `REVERTIDA` |
| Sistemas externos | core bancario, ESB, pasarela de pagos, proveedor de scoring |

Un capítulo que necesite un tercer dominio —telecomunicaciones, salud, logística— **declara
por qué** los dos anteriores no servían. Sin esa justificación, se usa el de comercio
electrónico.

**Nunca uses `foo`, `Bar`, `MyService`, `doSomething()` ni "tu sistema"** en un ejemplo.
Un nombre sin significado destruye exactamente la capacidad que el corpus intenta enseñar:
nombrar las cosas como las nombra el negocio.

---

## 6. 🧱 Plantilla de los capítulos (`NN-tema.md`)

1. **Título** — `# NN — Tema` (dos dígitos, sin emoji en el título).
2. **Blockquote de encabezado** — qué cubre el documento en una o dos líneas, qué asume
   leído con enlace, y **`Vigencia:`** con la fecha en que se verificaron los enlaces. Ese
   campo es obligatorio: quien abre `07` sin pasar por el README tiene que saber qué tan
   reciente es lo que lee.
3. **Índice de salto rápido** — solo si el documento pasa de ~400 líneas (§6.2).
4. **`## N. 🎯 El problema`** — apertura obligatoria. El dolor antes que el nombre (§4.1).
5. **Secciones `##` numeradas**, una por concepto, con emoji funcional. **Numeración
   arábiga continua**, incluido el problema, que siempre es la `1`.
6. **`## N. 🧭 Cómo se elige`** — recomendada en todo capítulo que presente alternativas
   entre las que hay que decidir. Es un árbol de decisión en bloque `text`, seguido de la
   frase que se dice en voz alta.
7. **`## ⚠️ Errores frecuentes`** — obligatoria. Tabla de dos columnas, **"Se dice" contra
   "Lo preciso"**, con entre cinco y ocho entradas. Es donde se cumple la regla de §2 sobre
   nombrar las sobregeneralizaciones, y es de las secciones que más rinden del corpus.
8. **`## 📚 Para profundizar`** — cierre obligatorio (§10), máximo ocho entradas.
9. **`## 🧠 Preguntas`** — cierre obligatorio, sin respuestas visibles (§8).
10. **Pie de navegación** — una línea con **Anterior**, **Siguiente** y **Relacionado**.

### 6.1 El patrón fijo de cada concepto

Dentro de una sección `##` de concepto, el orden no varía:

```text
Qué es      → la definición mínima, en una o dos frases
Cuándo sí   → los casos donde se paga solo
Cuándo no   → los casos donde es ceremonia. NUNCA se omite.
Veredicto   → la frase que resume el criterio, en blockquote
```

**"Cuándo no" y "Veredicto" son obligatorios**, y son lo que distingue a este corpus de un
folleto. Un concepto sin "cuándo no" sugiere que siempre se usa, que es falso para
prácticamente todo lo que hay en el temario. La forma del veredicto:

```markdown
> **Veredicto:** hexagonal se paga con mapeo. Si el dominio no tiene invariantes que
> proteger, estás pagando el mapeo y no comprando nada.
```

Las secciones que no presentan un concepto elegible —el problema, el árbol de decisión, los
errores frecuentes— no llevan veredicto.

### 6.2 Índice de salto rápido

Formato fijo, justo después del blockquote de encabezado:

```markdown
**Salto rápido:** [01](#01--fundamentos-del-arquitecto) · [02](#02--estilos-de-despliegue) ·
[11 — escenarios](#11--simulación-escenarios-de-diseño)
```

**Cómo se calcula un ancla de GitHub**, porque es donde se rompen estos índices: se pasa el
encabezado a minúsculas, se eliminan los caracteres que no son letra, número, espacio,
guion o guion bajo —lo que se lleva por delante el punto de la numeración, el emoji, los
backticks y los paréntesis— y por último los espacios restantes se convierten en guiones.
Cada carácter borrado **deja su espacio**, y de ahí salen los guiones dobles:

| Encabezado | Ancla |
|---|---|
| `## 2. 🧱 Monolito modular` | `#2--monolito-modular` |
| `## 3. ⬡ Hexagonal (ports and adapters)` | `#3--hexagonal-ports-and-adapters` |
| `## 🧠 Preguntas` | `#-preguntas` |

Fíjate en el último: un encabezado que empieza por emoji genera un ancla que **empieza por
guion**. Verifica las anclas al escribirlas.

### 6.3 Excepciones declaradas a la plantilla

- **`README.md` de cada bloque** — índice, orden de lectura, mapa mental y la sección
  "Qué NO está aquí" que remite a los otros bloques.
- **`NN-simulacion-de-entrevista.md`** — el examen del bloque (§7.2).
- **`NN-respuestas.md`** — el solucionario (§7.3). No lleva preguntas propias, ni
  referencias, ni errores frecuentes.

---

## 7. 📐 Los tres tipos de documento

**Divergencia declarada respecto de AWS/GCP.** Allí había labs (`lNN-`) y apéndices
(`aNN-`) porque existía una serie práctica contra una nube real. **Este corpus no tiene
laboratorio**: es teoría y evaluación. La serie práctica sobre un sistema de ejemplo queda
fuera y se decide aparte; mientras no exista, ningún documento la promete.

Cada bloque tiene exactamente tres tipos de documento y ningún otro.

### 7.1 Capítulos `NN-tema.md`

El grueso del corpus. Siguen la plantilla de §6 sin desviaciones. Son **independientes
entre sí en lectura** pero acumulativos en vocabulario: cada uno declara en su encabezado
qué asume leído, y no vuelve a explicar lo que ya explicó otro.

### 7.2 Simulación `NN-simulacion-de-entrevista.md`

El examen del bloque, y el documento que más se parece a la entrevista real. Lleva:

- **Una sección de método** que fija cómo se usa: cronómetro a dos minutos, en voz alta,
  y solo después el solucionario.
- **Preguntas `S#` transversales**, agrupadas en bloques temáticos que cruzan capítulos.
  Entre 30 y 45. Incluyen un bloque final de **"las que descolocan"**: las de criterio
  personal, las de conflicto con el entrevistador, las de liderazgo técnico.
- **Escenarios de diseño**, entre cuatro y seis, de quince minutos y con papel. **Cada
  escenario se elige para forzar una frontera distinta** y lo declara explícitamente en una
  línea `**Fuerza:**`. Uno de ellos, obligatoriamente, es un caso donde **la respuesta
  correcta es no hacer el cambio**.
- **Las frases que hay que tener listas** como cierre: dos o tres, en blockquote, que
  resumen el bloque y sirven de ancla cuando el lector se queda en blanco.

Las `S#` no llevan respuesta propia en el solucionario si ya están cubiertas por una
pregunta de capítulo: el solucionario lo declara y remite. Los escenarios **sí** llevan
solución desarrollada, porque son ejemplos resueltos y no autochequeo de memoria.

### 7.3 Solucionario `NN-respuestas.md`

Uno por bloque, y es el documento que hace útil a todo lo demás: **es lo que permite
estudiar sin ver la respuesta al lado de la pregunta**.

- Abre con índice de salto rápido, siempre: pasa de 400 líneas por definición.
- Se organiza por capítulo, con encabezado `# NN — Tema` por cada uno.
- **El enunciado se copia literalmente**, no se parafrasea: es lo que permite localizar una
  respuesta buscando el texto de la pregunta.
- Formato de cada entrada: `**NN → P.** Enunciado literal en negrita.`
- **Respuesta en tres capas, siempre las tres y en este orden** (§8.3).

---

## 8. 🧠 Preguntas y respuestas

**Divergencia declarada respecto de AWS/GCP.** Allí eran 10–15 "preguntas rápidas" por
capítulo porque el peso evaluador estaba en los ejercicios de los labs, y `CLAUDE.md`
admite expresamente que la guía de cada curso reparta ese aparato de otra forma siempre que
lo diga y diga por qué. Aquí **no hay labs, así que todo el peso evaluador vive en las
preguntas** y la banda sube. No hay sección de 🧪 Ejercicios en ningún documento de este
corpus.

```text
capítulo             →  20 a 30 preguntas numeradas. Sin respuesta visible.
simulación           →  30 a 45 preguntas S# transversales + 4 a 6 escenarios.
solucionario         →  todas las respuestas, en tres capas, enunciado literal.
```

### 8.1 Las preguntas de capítulo

- **Cantidad: 20 a 30**, calibrada por cuántas cosas distintas enseña el capítulo y se
  pueden comprobar por separado — nunca por su longitud. Subir de 30 exige poder decir qué
  comprueba cada pregunta nueva que no comprobara ya otra.
- **Numeración arábiga continua dentro del capítulo**, reiniciada en cada capítulo.
- **Dificultad marcada al final del enunciado** con un solo emoji, siguiendo el formato de
  `preguntas-entrevista/`:

  | | Nivel | Qué pide |
  |---|---|---|
  | 🟢 | Definición | Reproducir un concepto que el capítulo enunció |
  | 🟡 | Distinción | Diferenciar dos conceptos que se confunden |
  | 🟠 | Decisión | Elegir entre alternativas y justificar el precio |
  | 🔴 | Diseño o diagnóstico | Abierto: un sistema que diseñar o un fallo que explicar |

- **Reparto orientativo:** alrededor de 25 % 🟢, 25 % 🟡, 30 % 🟠 y 20 % 🔴, con un escalón
  de margen. Un capítulo de vocabulario —GoF, PoEAA— carga hacia 🟢 y 🟡; uno de decisión
  —estilos de despliegue, resiliencia— carga hacia 🟠 y 🔴. **Que dos capítulos vecinos
  tengan idéntico reparto es señal de que el segundo se copió en vez de calibrarse.**
- **Orden: de menor a mayor dificultad.** El lector debe poder parar donde se le acabe el
  tiempo y haber cubierto lo esencial. Las 🔴 van al final, siempre.
- **Directas y verificables.** Cada pregunta tiene respuesta localizable en el propio
  capítulo o derivable de él. Nunca "reflexiona sobre…".
- **Las 🔴 piden un artefacto o una secuencia**, no una opinión: *"diseña la estructura de
  paquetes y di qué clase es pública"*, *"da tres hipótesis en orden de probabilidad"*,
  *"narra la cadena y di dónde la cortarías"*.
- **Sin respuesta en el documento.** Va todo al solucionario del bloque.

### 8.2 La regla de sincronía

**Quien agregue, elimine o reordene una pregunta refleja el mismo cambio en el solucionario
del bloque en la misma edición**, con el enunciado copiado literalmente. Un solucionario
desincronizado es peor que no tenerlo: el lector busca la respuesta 14 y encuentra la de
otra pregunta.

La comprobación es mecánica y se corre antes de cerrar:

```bash
# desde el directorio del bloque
for f in [01]?-*.md; do
  n=$(sed -n '/^## 🧠 Preguntas/,$p' "$f" | grep -cE '^[0-9]+\. ')
  printf '%-45s %s\n' "$f" "$n"
done
grep -cE '^\*\*[0-9]{2} → [0-9]+\.' *-respuestas.md   # debe igualar la suma
```

### 8.3 Las tres capas de la respuesta

Es lo que hace útil al solucionario, y no es negociable: **siempre las tres, siempre en
este orden, siempre con su emoji**.

```text
⏱️ 30 segundos  → lo que dices primero, sin que te lo pidan. Una o dos frases.
🗣️ 2 minutos    → lo que añades cuando dicen "cuéntame más". Tres a cinco frases.
🔬 El detalle   → para estudiar, no para decir en voz alta. El matiz, la excepción,
                  el dato que solo usas si te aprietan.
```

- **La capa de 30 segundos se escribe como se diría**, no como se escribiría. Si no cabe en
  una respiración, está mal.
- **La capa de 2 minutos añade, no repite.** Si parafrasea la primera, sobra.
- **El detalle es donde va la honestidad incómoda**: la excepción, el caso donde la
  respuesta anterior no aplica, el número que nadie recuerda.
- En las 🔴 de diseño, la capa de 2 minutos suele llevar un bloque `text` con la estructura
  propuesta, y el detalle enumera lo que el entrevistador preguntará después.

---

## 9. 🧷 Vocabulario visual: reglas y callouts

Vocabulario deliberadamente reducido, heredado de la guía de AWS sin cambios salvo los que
se indican.

### 9.1 Regla o mnemotecnia (bloque `text`)

Para una asociación mental que vale la pena aislar, en especial con forma de comparación,
ecuación corta o árbol de decisión. Se etiqueta antes con una línea breve: "Regla:", "Regla
mental:", "Regla de entrevista:" o "Regla de arquitectura:".

```text
Hexagonal → el dominio no conoce a nadie
Capas     → cada capa conoce a la de abajo
```

### 9.2 Frase de respuesta correcta (blockquote)

Para la única frase que deberías decir en voz alta, normalmente después de mostrar la
simplificación incorrecta. Sirve igual para blindar contra la mala respuesta ("Nunca
respondas: > …") que para dar la buena ("Mejor: > …"). También admite etiqueta corta de
énfasis —"Regla importante:", "Punto importante:"— cuando lo que sigue es una única frase
definitoria.

El **veredicto** de §6.1 es un caso particular de este recurso y usa siempre la etiqueta
`**Veredicto:**`.

Prueba práctica: si cabe en una oración y corrige o fija un concepto, va en blockquote; si
es lista, ecuación o comparación de dos o más líneas, va en bloque `text`.

### 9.3 Callouts admitidos

Se usan en blockquote, con negrita en la etiqueta, y solo cuando aportan. Ninguno es
obligatorio en ningún documento. **Como mucho uno por sección `##`, y nunca dos
seguidos.** Es un tope por densidad y no por documento: un capítulo largo puede sostener
cinco repartidos y uno corto con tres juntos ya convirtió el recurso en decoración. La
prueba: si al leer una sección el callout no te detiene, es porque hay demasiados.

- ⚠️ **Advertencia.** Ignorarlo produce una respuesta de entrevista objetivamente
  incorrecta, o rompe algo en producción. Uso escaso; nunca decorativo.
- 🧠 **Modelo mental.** La frase que hay que llevarse, no el detalle.
- 💡 **Truco.** El matiz que casi nadie dice y que sube la nota de la respuesta.
- 🩺 **Diagnóstico.** Cómo se confirma o descarta la hipótesis: qué mirarías primero.
- 💰 **Costo.** El precio del patrón, en latencia, consistencia, operación o dinero.
  **Obligatorio la primera vez que un capítulo introduce algo cuyo precio no es obvio.**
- 📝 **Contexto.** Por qué la respuesta "clásica" que el lector encontrará en fuentes
  viejas ya no aplica, o qué cambió en el lenguaje o el framework.
- 📚 **Referencia inline.** El enlace útil justo donde nace la duda, sin esperar al cierre.

**Escala de dificultad 🟢🟡🟠🔴.** Se usa **solo** en el enunciado de las preguntas (§8.1).
Fuera de ahí no aparece.

**Marcadores ✅ y ❌.** Se admiten como señal de sí/no dentro de tablas y de bloques `text`
de comparación. Nunca como decoración en prosa ni en un encabezado.

Fuera de esta lista, de ✅/❌, de la escala de dificultad y de los emojis de encabezado de
§3, **no se usan otros emojis**. Nada de 🚨, 💸, ⭐ ni 🎉. Las tres excepciones declaradas
son 🪦 para el encabezado de la sección "lo que ya no se usa", ⬡ 🥞 🧅 🔪 como emoji de
encabezado de las cuatro arquitecturas de aplicación en `01-bases/03`, y los tres de las
capas de respuesta ⏱️ 🗣️ 🔬 en los solucionarios.

### 9.4 Autopsia de una respuesta mala

El equivalente aquí de la "autopsia de un fallo" de la guía de AWS, y el recurso que mejor
aprovecha que este corpus prepara conversaciones y no despliegues. Cuando un capítulo
documenta un error de entrevista frecuente, la estructura es:

1. **La respuesta que da todo el mundo**, citada tal cual y sin caricaturizar.
2. **Por qué parece correcta.** Casi siempre lo es a medias, y reconocerlo es lo que hace
   creíble la corrección.
3. **La pregunta de seguimiento que la desmonta**, que es la que el entrevistador hará.
4. **La respuesta completa**, en blockquote, como se diría en voz alta.
5. **La generalización**, si la hay: qué clase de error es y dónde más aparece.

La tabla de `## ⚠️ Errores frecuentes` es la versión comprimida de esto, para los errores
que no merecen cinco pasos. Cuando un error sí los merece —"escalo horizontalmente",
"exactly-once", "microservicios escalan mejor"— se desarrolla en su propia sección.

Y los antipatrones se nombran sin piedad: reintentar lo no idempotente, el circuit breaker
protegiendo a quien no debía, el `@Service` de 900 líneas, el modelo canónico de empresa, el
ADR sin consecuencias negativas.

---

## 10. 📚 Bibliografía, referencias y enlaces

### 10.1 Enlaces externos y orden de autoridad

**Divergencia declarada respecto de AWS/GCP.** Aquella guía admitía **solo** documentación
oficial del proveedor y prohibía libros, blogs y video. Aquí **la arquitectura no tiene
proveedor**: la fuente canónica es bibliográfica, y quien inventó cada concepto lo publicó
en un libro o en su propio sitio. El cierre `## 📚 Para profundizar` admite, **en este
orden y marcando el tipo**:

1. **Libro**, con autor, título, editorial, año y **capítulo concreto**. Sin URL: un libro
   se identifica por su ficha, no por un enlace que caduca. **Todo capítulo cita al menos
   uno**, y cuando hay uno que destaca se dice cuál: *"si solo lees uno de todo el bloque,
   lee este"*.
2. **Fuente primaria del autor del concepto** — `martinfowler.com`, `microservices.io`,
   `c4model.com`, `alistair.cockburn.us`, `blog.cleancoder.com`, `jeffreypalermo.com`. Es
   el equivalente a la documentación oficial de un proveedor y se cita con URL.
3. **Documentación oficial del framework**, cuando el concepto se aterriza en código:
   `docs.spring.io`, `resilience4j.readme.io`, `grpc.io`, `archunit.org`.
4. **Material técnico de referencia de un proveedor**, cuando aporta el dato que no está en
   otro sitio: Amazon Builders' Library, Google SRE Book.
5. **Tutorial aplicado** — Refactoring Guru, GeeksforGeeks, Baeldung. Útil para ver el
   patrón en Java real. Van **al final y marcados como tutorial**, nunca mezclados con la
   fuente primaria. **Baeldung se cita por título entre comillas angulares y sin URL**
   (`Baeldung, «Guide to Resilience4j»`): su CDN responde `403` a cualquier verificación
   automática, así que un enlace suyo no se puede comprobar por código de estado y la regla
   de abajo lo prohíbe. El título es estable y se encuentra buscándolo.
6. **Video o charla**, solo por **canal o conferencia y título, sin URL**. Los enlaces de
   video se rompen y se reemplazan; el título se busca. Admitidos: GOTO Conferences,
   Devoxx, Spring I/O, Domain-Driven Design Europe, ByteByteGo, DeveloperToArchitect.

**Máximo ocho entradas por capítulo.** Es un repaso, no una bibliografía.

Reglas duras, heredadas sin cambios:

- **No se inventan URLs.** Un enlace que no se pudo verificar no se escribe: se cita el
  nombre exacto de la página y se omite el enlace. Inventar una ruta plausible de
  `martinfowler.com` es el error más caro de este corpus, porque parece correcta hasta que
  alguien la abre delante de un entrevistador.
- **Se comprueban por código de estado, no a ojo**, y en la misma edición en que se
  escriben. Aterrizar en la portada del sitio en vez de en la página concreta cuenta como
  roto.
- **Una URL por concepto**, específica. Si el capítulo explica el mapa de contextos, el
  enlace es a la página del mapa de contextos, no a la portada del sitio.
- **`martinfowler.com` limita la tasa**: verifícalo en serie y con cabecera de navegador, o
  devolverá `000` en paralelo y parecerá caído sin estarlo.

### 10.2 Enlaces internos

Son parte del producto, no un adorno, y hacen cumplir §4.7.

- **Formato:** enlace Markdown relativo, con el número del documento en el texto visible:

  ```markdown
  ver [`05` — Unit of Work](05-fowler-poeaa.md)
  ```

- **Con ancla cuando la sección destino existe y es estable:**

  ```markdown
  ver [`03` §3 — hexagonal](03-arquitecturas-de-aplicacion.md#3--hexagonal-ports-and-adapters)
  ```

- **Entre bloques, con ruta relativa al bloque:**

  ```markdown
  ver [`02-eventos`](../02-eventos/)
  ```

- **Cada capítulo enlaza al menos a los dos capítulos con los que más se toca**, y cierra
  con el pie de navegación de §6, punto 10.
- **Al renombrar un archivo o un encabezado se revisan los enlaces entrantes en la misma
  edición.**

Verificación mecánica de enlaces internos y anclas, que se corre antes de cerrar:

```bash
# desde el directorio del bloque: archivos referenciados que no existen
grep -oh '](\([0-9]\{2\}-[^)#]*\.md\)' *.md | sed 's/](//' | sort -u | while read -r f; do
  [ -f "$f" ] || echo "ROTO: $f"
done
```

### 10.3 Vigencia

El README de cada bloque declara la fecha de revisión general y **cada documento la repite
en su blockquote de encabezado**. Cuando un documento incorpora algo reciente —`sealed` y
pattern matching dejando obsoleto a Visitor, virtual threads cambiando el argumento del
bulkhead por hilos, Spring Modulith— se marca con 📝 en el propio texto, para que quien
repasa sepa que puede no coincidir con las respuestas "clásicas" de fuentes más viejas.

---

## 11. 🔗 Coherencia entre documentos

- **No contradecir documentos anteriores.** Si `03` establece que hexagonal no se justifica
  en un CRUD, `07` puede matizarlo, nunca contradecirlo.
- **Terminología estable.** Si `06` dice "contexto acotado", el resto del corpus no lo llama
  "contexto delimitado" ni alterna con "bounded context" sin motivo. Si `03` dice "puerto
  primario (driving)", esa es la forma en todo el corpus.
- **Los dominios de ejemplo de §5.1 mandan.** Cualquier desviación se declara en el
  documento que la introduce, con su porqué.
- **Un concepto tiene un solo dueño.** El capítulo que lo introduce lo explica entero; los
  demás lo usan y enlazan. `08` no vuelve a explicar qué es la idempotencia después de
  haberla definido; la usa y remite.
- **Los bloques no se repiten entre sí.** `01-bases` da el vocabulario común; `02` a `05`
  lo asumen leído y profundizan. Cuando un bloque roza el territorio de otro, lo declara y
  enlaza en vez de duplicar.
- **Fuentes de verdad, en orden:**
  1. **Esta guía y los demás documentos de `prompts/`**, que según la regla de precedencia
     de `CLAUDE.md` mandan sobre las normas por defecto del repositorio en todo lo que
     declaren explícitamente.
  2. **`CLAUDE.md` de la raíz**, para todo lo que esta guía no toca.
  3. **`README.md` del corpus**, para el alcance de los cinco bloques.
  4. **`README.md` del bloque**, para orden de lectura y mapa.
  5. **Documentos ya publicados** — no se contradicen, se matizan.
  6. Decisiones explícitas del chat actual.

---

## 12. ✅ Checklist antes de dar por cerrado un `.md`

**Estructura**

- [ ] Sigue la plantilla de §6, o está declarado como excepción (README, simulación,
      solucionario).
- [ ] Encabezado con objetivo, qué asume leído **con enlace**, y **`Vigencia:`**.
- [ ] Índice de salto rápido si pasa de ~400 líneas (§6.2).
- [ ] Abre con `## N. 🎯 El problema`, no con una definición (§4.1).
- [ ] Numeración `##` arábiga y continua; emoji funcional en `##`, **ninguno en `###`**.
- [ ] Cierra con pie de navegación: Anterior, Siguiente y Relacionado.

**Contenido**

- [ ] Cada concepto sigue **qué es → cuándo sí → cuándo no → veredicto** (§6.1), y
      **ninguno se queda sin "cuándo no" ni sin veredicto**.
- [ ] Toda afirmación de beneficio lleva su precio en latencia, consistencia, operación o
      dinero (§4.2).
- [ ] Ningún bloque de código sin frase antes y viñetas después; bloques de Java mínimos.
- [ ] Todo concepto abstracto anclado en Spring donde exista anclaje (§4.4).
- [ ] Se nombra explícitamente cuando una respuesta común de entrevista es una
      sobregeneralización (§2).
- [ ] Hay sección `## ⚠️ Errores frecuentes` con tabla "Se dice / Lo preciso", 5–8 entradas.
- [ ] Hay `## N. 🧭 Cómo se elige` si el capítulo presenta alternativas.
- [ ] Dominios de ejemplo de §5.1 respetados; sin `foo`, sin `MyService`, sin "tu sistema".
- [ ] Entre 200 y 350 líneas. Si pasa de 400, se poda o se parte.

**Forma**

- [ ] Tono semi formal y cálido, tuteo latinoamericano, humor casi ausente (§2).
- [ ] Sin prosa telegrama: una o dos frases aisladas por sección como mucho (§3).
- [ ] Tablas solo para comparar o mapear, máximo cuatro columnas, sin celdas que necesiten
      explicación.
- [ ] Como mucho un callout por sección `##`, nunca dos seguidos, y solo los de §9.3.
- [ ] Dominio en español, framework y patrones en inglés, comentarios en español (§5).

**Evaluación**

- [ ] Entre 20 y 30 preguntas, graduadas 🟢🟡🟠🔴, **ordenadas de menor a mayor
      dificultad**, sin respuesta visible (§8.1).
- [ ] Reparto de dificultad distinto al del capítulo vecino.
- [ ] **Si tocaste alguna pregunta, actualizaste el solucionario del bloque en la misma
      edición** (§8.2), con el enunciado copiado literal.
- [ ] En el solucionario: las tres capas ⏱️ 🗣️ 🔬 en todas las respuestas, sin excepción.

**Referencias y enlaces**

- [ ] `## 📚 Para profundizar` presente, máximo ocho entradas, ordenadas por autoridad
      (§10.1), con al menos un libro con capítulo concreto.
- [ ] Todas las URLs verificadas por código de estado **en esta edición**.
- [ ] Baeldung citado por título sin URL; video citado por canal y título sin URL.
- [ ] Al menos dos enlaces internos a los capítulos vecinos, y ningún enlace interno roto.
- [ ] Ningún enlace a un documento que todavía no existe: mientras tanto, al README del
      bloque (§4.7).

**Coherencia**

- [ ] No contradice ningún documento anterior, y la terminología coincide con la ya fijada
      (§11).
- [ ] Ningún bucle abierto sin cerrar: toda promesa de "esto se ve en X" tiene su enlace.
