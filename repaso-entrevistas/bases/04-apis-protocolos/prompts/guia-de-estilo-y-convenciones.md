# ✍️ Guía de estilo, tono y convenciones

## APIs y protocolos — repaso para entrevistas de Backend Senior, Tech Lead y Arquitecto

Esta guía es la fuente de verdad editorial de `repaso-apis-y-protocolos-entrevistas/` y manda sobre
sus seis capítulos, la simulación y el solucionario. Cualquier chat que produzca o edite un `.md` de
este corpus la sigue. Su objetivo es que todos los documentos se lean como escritos por la misma
mano y apunten al mismo lugar: **que puedas explicar qué viaja por el cable, por qué está definido
así, y dónde lo dice la norma**.

Desciende de la guía de
[`repaso-bases-entrevistas`](../../01-bases/prompts/guia-de-estilo-y-convenciones.md),
y por tanto de la de
[`repaso-arquitectura-entrevistas`](../../../arquitectura/01-bases/prompts/guia-de-estilo-y-convenciones.md).
Hereda el tono, la pedagogía del andamio, el vocabulario visual, la plantilla de capítulo, las tres
capas de respuesta y las reglas de enlace. **Diverge en cuatro puntos declarados** —§4.2, §5, §6.1 y
§10.1— por una razón de fondo: aquellos corpus enseñan a elegir un mecanismo que tú escribes, y este
enseña **un contrato que tú no controlas y que está escrito en un documento público**.

Un cambio **de forma y no de fondo** se añadió en la revisión del 2026-10-05, a pedido explícito del
autor: **los diagramas de nodos y flechas, y las secuencias de mensajes, van en Mermaid** (§9.5); el
intercambio en el cable sigue en `text` (§9.1). La madre hizo el mismo cambio ese día, así que no
cuenta como divergencia.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que mañana tiene una
entrevista donde le van a preguntar por qué `PUT` es idempotente y `POST` no.

> **Vigencia:** 2026-10-05.

---

## 1. 🧭 Principio rector

**Todo lo que se escribe apunta a que alguien entienda el contrato, sepa dónde está escrito, y pueda
defender una decisión de API en voz alta.**

No enseñamos "redes". El temario de redes tiene mil páginas y recitar las siete capas del modelo OSI
no ha ayudado nunca a nadie a diseñar una API. Repasamos **el protocolo que un backend toca todos los
días** —HTTP— y lo que hay justo debajo cuando falla.

```text
Un curso de redes   → te enseña las siete capas y el formato de una trama.
Este repaso         → te enseña por qué PATCH no es idempotente, dónde lo dice,
                      y qué pasa cuando el certificado caduca un domingo.
```

El filtro para cada párrafo es este: **¿esto ayuda a explicar, a decidir un contrato o a diagnosticar
un fallo?** Si no, sobra. Aunque sea cierto y esté en el RFC.

Y el corolario, que es la marca de este corpus:

> Cada afirmación normativa se cita con su RFC y su sección. Cada convención se distingue de lo que
> la norma obliga. Cada decisión responde a "¿por qué está definido así, y qué pasa si lo ignoro?".

Una afirmación sobre HTTP sin su fuente no está explicada: está recordada. Y la mitad de lo que
"todo el mundo sabe" sobre HTTP es convención, folclore o una versión obsoleta de la norma.

### 1.1 Qué NO es este corpus

Cuatro cosas quedan fuera por decisión editorial, y se declaran aquí para que ningún documento las
prometa:

- **No es un manual de redes.** Nada de subnetting, enrutamiento, BGP ni configuración de equipos.
  TCP entra solo hasta donde explica un fallo de aplicación.
- **No es diseño de API con un framework.** `@RestController`, `Pageable`, `ProblemDetail` y los
  clientes HTTP son de [`repaso-spring-entrevistas`](../../../frameworks/01-spring-boot/). Aquí se
  explica **la semántica**; allí, cómo se escribe.
- **No es seguridad de aplicación.** OAuth2, JWT, CORS, CSRF y mTLS como patrón son de
  [`repaso-arquitectura-entrevistas/04-seguridad`](../../../arquitectura/01-bases/04-seguridad/).
  Aquí entra TLS **como protocolo de transporte**.
- **No es infraestructura de nube.** VPC, DNS gestionado y balanceadores concretos son de
  [`repaso-aws-entrevistas`](../../../cloud/01-aws/) y
  [`repaso-gcp-entrevistas`](../../../cloud/02-gcp/).

---

## 2. 🎤 Tono

El tono es **semi formal, cálido y directo**, de colega a colega. Piensa en alguien que ya pasó por
esto —el `415` que nadie entendía, el certificado que caducó en producción un domingo, el `PATCH`
que borró campos porque alguien mandó el objeto entero— y te lo explica con paciencia y sin
solemnidad de RFC.

Cómo se ve en la práctica:

- **Tuteo latinoamericano, siempre.** Le hablas al lector de "tú". Nada de voseo, nada de "usted",
  nada de impersonal permanente.
- **Semi formal.** Cercano, pero no chat. Frases completas, puntuación correcta.
- **Humor mínimo y seco.** Como mucho **un desdramatizador por documento**, y si no fluye solo, se
  borra.
- **Honesto sobre la convención.** Cuando algo se hace "porque siempre se ha hecho así" y la norma
  dice otra cosa —el prefijo `X-`, `PUT` para actualizaciones parciales, `200` con un error dentro—
  **se dice que es convención y se dice qué dice la norma**. Este es el recurso pedagógico central
  del corpus.
- **Honesto sobre lo obsoleto.** Media internet cita RFC 2616, que está obsoleto desde 2014. Cuando
  una fuente que el lector va a encontrar esté anticuada, se nombra y se da la vigente.
- **Honesto sobre el precio.** Todo mecanismo se nombra con lo que cuesta, en las cuatro monedas de
  §4.2. Nada de "añade algo de latencia": se dice cuántos RTT.
- **Sin absolutos falsos.** Nada de "siempre" ni "nunca" salvo cuando la norma lo dice literalmente
  —y entonces se cita—.
- **Cálido sin condescendencia.** Explicamos desde cero, pero nunca infantilizamos.
- **Sin relleno motivacional.** Quien lee ya sabe por qué está repasando.

---

## 3. 🗣️ Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no sea código ni protocolo.
- **Los nombres del protocolo se quedan en inglés y tal cual aparecen en el cable.** `Content-Type`,
  `Cache-Control`, `If-None-Match`, `keep-alive`, `multipart/form-data`, *handshake*, *chunked*,
  *preflight*. Traducirlos confunde y no es lo que el lector va a ver en un `curl -v`. **Los nombres
  de encabezado se escriben con su capitalización canónica** aunque HTTP los trate sin distinguir
  mayúsculas: `Content-Type`, no `content-type`.
- **La primera vez que aparece un término en inglés, se da su traducción entre paréntesis**; después
  ya no.
- **Markdown siempre.** Nada de HTML embebido.
- **Estructura visual primero, pero la prosa no es el último recurso.** El orden de preferencia es
  intercambio real → tabla → lista → párrafo *para exponer una relación entre cosas*. El **porqué**
  de una decisión se escribe en prosa.
- **Nada de prosa telegrama.** Una frase corta y sola es un buen golpe de ritmo; tres seguidas son un
  telegrama. Regla práctica: **una frase aislada por sección, dos si la sección es larga**.
- **El recurso visual principal de este corpus es el intercambio real**, en bloque ` ```text `: la
  petición y la respuesta tal y como viajan, con sus encabezados. Es el equivalente aquí de la traza
  de ejecución de `repaso-bases-entrevistas`.
- **Tablas solo para comparar o mapear**, con tres o cuatro columnas como norma. **Si necesitas
  explicar una celda, ya no es una tabla.**
- **Encabezados con emoji, con moderación.** Uno por sección `##` numerada, **ninguno en las
  subsecciones `###`**. El emoji es funcional: 🎯 el problema, 🧱 mecanismo, 📜 lo que dice la norma,
  ⚖️ comparación, 🧭 criterio de elección, 🩺 diagnóstico, 🔭 dónde aparece de verdad, 🪦 lo obsoleto,
  ⚠️ errores frecuentes, 🧠 preguntas, 📚 referencias.

---

## 4. 🎓 Pedagogía: "como para un bebé"

> **"Como para un bebé" significa cero ambigüedad, no menos profundidad.**

No es escribir más simple: es no dejar ningún hueco donde el lector tenga que adivinar. Se explica
qué es exactamente un *boundary* de `multipart`, por qué existe, quién lo elige y qué pasa si aparece
dentro del contenido. No se dice "se envía como multipart" y se sigue adelante.

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar el mecanismo, muestra el dolor que resuelve. *"Quieres
   mandar un fichero binario y un par de campos de texto en la misma petición. HTTP transporta un
   único cuerpo. ¿Cómo metes tres cosas en un sitio donde cabe una?"*
2. **El mecanismo después.** Ahora sí, el nombre y la definición mínima.
3. **El intercambio que lo demuestra.** La petición y la respuesta reales, con la viñeta que dice qué
   mirar en ellas.

Por eso **`## 1. 🎯 El problema` es la sección de apertura obligatoria de todo capítulo**.

### 4.2 Ninguna afirmación normativa sin fuente, y ningún mecanismo sin coste

**Divergencia declarada.** En `repaso-bases-entrevistas` el precio se pagaba en tiempo, espacio,
legibilidad y casos borde. Aquí las monedas son otras, porque el coste de un protocolo no se mide en
ciclos:

```text
round-trips · latencia · ancho de banda · modos de fallo
```

*"HTTP/2 multiplexa varias peticiones en una conexión, lo que elimina el coste de abrir una conexión
por recurso y el bloqueo de cabeza de línea **de la capa HTTP**, y lo paga con que un paquete perdido
bloquea todos los flujos, porque el bloqueo se mudó a TCP"* está completo. *"HTTP/2 es más rápido"*
no lo está.

**Y la mitad que define este corpus: la fuente.** Toda afirmación sobre lo que el protocolo **obliga**
va con su RFC y, cuando aporta, su sección:

```markdown
`PUT` es idempotente y `POST` no ([RFC 9110 §9.2.2](https://www.rfc-editor.org/rfc/rfc9110.html#section-9.2.2)).
```

- **Se distingue lo normativo de lo convencional.** "El RFC lo exige", "el RFC lo recomienda", "es
  convención de la industria" y "lo hace así Spring" son cuatro afirmaciones distintas y no se
  mezclan.
- **Se usa el vocabulario de [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.html): `MUST`, `SHOULD`,
  `MAY`.** Que algo sea `SHOULD` y no `MUST` es muchas veces la respuesta a "¿y por qué este servidor
  hace otra cosa?".
- **Nunca se cita un RFC obsoleto como vigente.** Si el lector va a encontrarse el viejo por internet
  —RFC 2616 es el caso canónico—, se nombra, se dice que está obsoleto y se da el que lo sustituye.

### 4.3 Explica el porqué, no solo el cómo

Cada decisión del protocolo lleva su porqué, aunque sea media línea: por qué el `boundary` lo elige
el cliente, por qué Base64 infla exactamente un 33 %, por qué TLS 1.3 quitó un RTT, por qué `PATCH`
no podía ser idempotente sin inventarse un formato.

Cuando el porqué es **histórico** —que en protocolos pasa constantemente— se dice también: *"`X-` se
convirtió en convención en los ochenta y se deprecó en 2012 porque los encabezados 'experimentales'
nunca dejaban de serlo y acababan estandarizándose con el prefijo pegado"*.

### 4.4 Ancla en `curl`, no en el framework

**Divergencia declarada respecto de `repaso-bases-entrevistas`**, que anclaba en la librería estándar
del lenguaje. Aquí el anclaje es **lo que se ve en el cable**, y la herramienta de referencia es
`curl -v`:

- Un encabezado se enseña como lo imprime `curl`, no como lo devuelve un `ResponseEntity`.
- Una negociación de contenido se enseña con `-H 'Accept: ...'` y la respuesta real.
- Un problema de certificado se enseña con el mensaje literal de `curl` o de `openssl s_client`.

Un concepto que no se puede observar con `curl` —el interior del handshake TLS, el framing de
HTTP/2— se explica igual, **pero se declara que no se ve** y se dice con qué sí se vería.

**Lo que no se hace nunca:** explicar un concepto de protocolo a través de la anotación de un
framework. Eso es de `repaso-spring-entrevistas` y tiene dueño.

### 4.5 Analogías con fecha de caducidad

Las analogías se usan **una vez, para abrir la puerta**, y después se abandonan diciendo dónde se
rompen. Cuidado especial con las tres más peligrosas del temario:

- **HTTP no es "una conexión"** (es un intercambio de mensajes; la conexión es de la capa de abajo y
  puede reutilizarse o no);
- **HTTPS no es "HTTP seguro"** (es HTTP sobre TLS: el protocolo no cambia, cambia por dónde viaja);
- **REST no es "una API con JSON y verbos"** (es un estilo con restricciones, y casi nada de lo que
  se llama REST las cumple todas).

### 4.6 Densidad calibrada, con techo de longitud

- **Banda objetivo: 200 a 350 líneas por capítulo.** Un capítulo que pasa de 400 se poda o se parte,
  y la decisión se declara en el README.
- Un concepto nuevo por vez.
- Repetir lo importante está bien: la idempotencia, el coste en RTT y la diferencia entre norma y
  convención reaparecen con otras palabras.
- Ninguna sección supera las dos pantallas sin un intercambio, una tabla o un veredicto.
- **Todo documento de más de ~400 líneas abre con un índice de salto rápido** (§6.2).

### 4.7 Cierra los bucles

Si abres un paréntesis —*"esto se ve en `05`"*, *"el `Idempotency-Key` es de Spring `10`"*— tiene que
cerrarse con enlace real. **Mientras un documento no exista, el enlace apunta al README**, nunca a un
archivo que no está escrito.

---

## 5. 💻 El eje políglota de este corpus

> **Regla normativa: el eje de comparación de este corpus NO son cinco lenguajes, sino el cable
> frente al cliente.**

**Divergencia declarada respecto de `repaso-bases-entrevistas`**, cuyo eje eran Java, Python,
JavaScript, TypeScript y Go. Aquí ese eje no aporta: `Content-Type` significa lo mismo en los cinco,
y las diferencias interesantes no están entre lenguajes sino **entre lo que dice la norma y lo que
hace cada implementación**.

El eje correcto es:

| Nivel | Qué se enseña | Cómo se muestra |
|---|---|---|
| **El cable** | Lo que realmente viaja | Intercambio en bloque `text`, con encabezados |
| **La norma** | Lo que el RFC obliga o recomienda | Cita con RFC y sección |
| **El cliente** | Cómo lo pides tú | `curl`, y solo cuando aporta |
| **La implementación** | Dónde los servidores difieren | Solo si el lector va a tropezar con ello |

**Cuándo sí aparece un lenguaje:** cuando su comportamiento por defecto es una trampa —el cliente que
no manda `Accept-Encoding`, el que sigue redirecciones en silencio, el que no verifica certificados
si le pasas una bandera—. Entonces se nombra el lenguaje y se explica.

**Cuándo no:** para mostrar cómo se construye una petición. Eso es del corpus del framework.

### 5.1 Datos de ejemplo estables

**No se inventan dominios nuevos por capítulo.** Se usan los mismos del corpus hermano de
arquitectura, para que quien estudie los dos no tenga que recalibrar:

```text
Host de ejemplo        api.ejemplo.com
Recurso principal      /pedidos/{id}          y su colección /pedidos
Recursos secundarios   /productos/{id}, /clientes/{id}
Fichero de ejemplo     factura.pdf  (application/pdf)
Identificadores        PED-00042, PRD-00017
```

**Nunca uses `foo`, `bar`, `example.org/test` ni `/api/v1/thing`.** Un ejemplo sin significado
destruye la capacidad de reconocer el patrón en un caso real.

---

## 6. 🧱 Plantilla de los capítulos (`NN-tema.md`)

1. **Título** — `# NN — Tema` (dos dígitos, sin emoji en el título).
2. **Blockquote de encabezado** — qué cubre, qué asume leído con enlace, y **`Vigencia:`**.
3. **Índice de salto rápido** — solo si pasa de ~400 líneas (§6.2).
4. **`## 1. 🎯 El problema`** — apertura obligatoria (§4.1).
5. **Secciones `##` numeradas**, una por concepto, con emoji funcional y numeración arábiga continua.
6. **`## N. 📜 Lo que dice la norma`** — **obligatoria en todo capítulo**. Reúne las afirmaciones
   normativas del capítulo con su RFC y sección, y separa en una columna aparte **lo que es
   convención**. Es la sección que distingue a este corpus y la que hay que escribir con más cuidado.
7. **`## N. 🧭 Cómo se elige`** — recomendada cuando el capítulo presenta alternativas.
8. **`## N. 🔭 Dónde aparece de verdad`** — recomendada. Dónde se topa un backend con esto: un `415`
   en producción, un certificado caducado, un `PATCH` que borró campos.
9. **`## ⚠️ Errores frecuentes`** — obligatoria. Tabla de dos columnas, **"Se dice" contra "Lo
   preciso"**, con entre cinco y ocho entradas.
10. **`## 📚 Para profundizar`** — cierre obligatorio (§10), máximo ocho entradas.
11. **`## 🧠 Preguntas`** — cierre obligatorio, sin respuestas visibles (§8).
12. **Pie de navegación** — una línea con **Anterior**, **Siguiente** y **Relacionado**.

### 6.1 El patrón fijo de cada concepto

**Divergencia declarada**, porque incorpora la fuente como paso obligatorio:

```text
Qué es      → la definición mínima, en una o dos frases
Cómo va     → el intercambio real, con sus encabezados
Qué obliga  → qué dice el RFC, y qué es solo convención. NUNCA se omite.
Cuánto      → round-trips, latencia, ancho de banda o modo de fallo. NUNCA se omite.
Cuándo sí   → los casos donde se paga solo
Cuándo no   → los casos donde sobra o es ceremonia. NUNCA se omite.
Veredicto   → la frase que resume el criterio, en blockquote
```

Las secciones que no presentan un concepto elegible —el problema, la tabla de la norma, los errores
frecuentes— no llevan veredicto.

### 6.2 Índice de salto rápido

Formato fijo, justo después del blockquote. **Cómo se calcula un ancla de GitHub**: se pasa el
encabezado a minúsculas, se eliminan los caracteres que no son letra, número, espacio, guion o guion
bajo, y los espacios restantes se convierten en guiones; cada carácter borrado deja su espacio, de
ahí los guiones dobles.

| Encabezado | Ancla |
|---|---|
| `## 3. 📜 Lo que dice la norma` | `#3--lo-que-dice-la-norma` |
| `## 🧠 Preguntas` | `#-preguntas` |

### 6.3 Excepciones declaradas a la plantilla

- **`README.md`** — índice, orden de lectura, mapa mental y "Qué NO está aquí".
- **`07-simulacion-de-entrevista.md`** — el examen (§7.2).
- **`08-respuestas.md`** — el solucionario (§7.3).

---

## 7. 📐 Los tres tipos de documento

**No hay laboratorio.** Se evaluó y se descartó: el valor de este corpus está en la norma y el
criterio, y los intercambios reales ya van dentro de los capítulos. Si en el futuro se añade una
serie práctica con `curl`, `openssl s_client` y `nc`, se declara aquí antes de escribirla.

### 7.1 Capítulos `NN-tema.md`

El grueso del corpus. Siguen la plantilla de §6 sin desviaciones. Son independientes en lectura pero
acumulativos en vocabulario. **`01` es dueño único de cómo se lee un RFC** y del vocabulario
`MUST`/`SHOULD`/`MAY`: los demás lo usan y no lo redefinen.

### 7.2 Simulación `07-simulacion-de-entrevista.md`

- **Una sección de método**: cronómetro a dos minutos, en voz alta.
- **Preguntas `S#` transversales**, entre 30 y 45, agrupadas por bloques temáticos, con un bloque
  final de **"las que descolocan"**.
- **Escenarios**, entre cuatro y seis: un contrato de API que diseñar, un fallo que diagnosticar. Uno
  de ellos, obligatoriamente, es un caso donde **la respuesta correcta es que el protocolo no lo
  resuelve** y hay que subir de capa.
- **Las frases que hay que tener listas** como cierre.

### 7.3 Solucionario `08-respuestas.md`

Uno para todo el corpus. Abre con índice de salto rápido, se organiza por capítulo, **el enunciado se
copia literalmente**, el formato de cada entrada es `**NN → P.** Enunciado en negrita`, y la
**respuesta va en tres capas, siempre las tres** (§8.3).

---

## 8. 🧠 Preguntas y respuestas

```text
capítulo      →  20 a 30 preguntas numeradas. Sin respuesta visible.
simulación    →  30 a 45 preguntas S# transversales + 4 a 6 escenarios.
solucionario  →  todas las respuestas, en tres capas, enunciado literal.
```

### 8.1 Las preguntas de capítulo

- **Cantidad: 20 a 30**, calibrada por cuántas cosas distintas enseña el capítulo.
- **Numeración arábiga continua dentro del capítulo**, reiniciada en cada capítulo.
- **Dificultad marcada al final del enunciado** con un solo emoji:

  | | Nivel | Qué pide |
  |---|---|---|
  | 🟢 | Definición | Reproducir algo que el capítulo enunció |
  | 🟡 | Distinción | Diferenciar dos cosas que se confunden |
  | 🟠 | Criterio | Decidir y justificar, o explicar un porqué no obvio |
  | 🔴 | Diseño o diagnóstico | Un contrato que definir o un fallo que explicar |

- **Reparto orientativo:** 25 % 🟢, 25 % 🟡, 30 % 🟠 y 20 % 🔴, con un escalón de margen. **Que dos
  capítulos vecinos tengan idéntico reparto es señal de que el segundo se copió.**
- **Orden: de menor a mayor dificultad.** Las 🔴 van al final, siempre.
- **Al menos dos preguntas por capítulo distinguen norma de convención**, que es la aportación propia
  de este corpus: *"¿el prefijo `X-` es obligatorio, recomendado o desaconsejado?"*.
- **Las 🔴 piden un artefacto o una secuencia**, no una opinión: *"escribe el intercambio completo"*,
  *"da tres hipótesis en orden de probabilidad"*.
- **Sin respuesta en el documento.** Va todo al solucionario.

### 8.2 La regla de sincronía

**Quien agregue, elimine o reordene una pregunta refleja el mismo cambio en el solucionario en la
misma edición**, con el enunciado copiado literalmente. La comprobación se corre antes de cerrar:

```bash
for f in 0[1-6]-*.md; do
  n=$(sed -n '/^## 🧠 Preguntas/,$p' "$f" | grep -cE '^[0-9]+\. ')
  printf '%-45s %s\n' "$f" "$n"
done
grep -cE '^\*\*[0-9]{2} → [0-9]+\.' 08-respuestas.md   # debe igualar la suma
```

### 8.3 Las tres capas de la respuesta

```text
⏱️ 30 segundos  → lo que dices primero. Una o dos frases.
🗣️ 2 minutos    → lo que añades cuando dicen "cuéntame más". Tres a cinco frases.
🔬 El detalle   → el matiz, la excepción, el número, y **la cita del RFC cuando aplica**.
```

- **La capa de 30 segundos se escribe como se diría.** Si no cabe en una respiración, está mal.
- **La capa de 2 minutos añade, no repite.**
- **El detalle es donde vive la fuente.** Es la capa natural para "lo dice RFC 9110 §9.2.2" y para la
  distinción entre lo que obliga la norma y lo que hace la industria.

---

## 9. 🧷 Vocabulario visual: reglas y callouts

### 9.1 El intercambio (bloque `text`)

El recurso principal. Petición y respuesta como viajan, con `>` y `<` al estilo de `curl -v` cuando
se quiera marcar la dirección:

```text
> PATCH /pedidos/PED-00042 HTTP/1.1
> Host: api.ejemplo.com
> Content-Type: application/merge-patch+json
>
> {"estado":"ENVIADO"}

< HTTP/1.1 200 OK
< Content-Type: application/json
```

### 9.2 Frase de respuesta correcta (blockquote)

Para la única frase que deberías decir en voz alta. El **veredicto** de §6.1 es un caso particular y
usa siempre la etiqueta `**Veredicto:**`.

### 9.3 Callouts admitidos

Se usan en blockquote, con negrita en la etiqueta. **Como mucho uno por sección `##`, y nunca dos
seguidos.**

- ⚠️ **Advertencia.** Ignorarlo produce una respuesta incorrecta o un fallo real.
- 🧠 **Modelo mental.** La frase que hay que llevarse.
- 💡 **Truco.** El matiz que casi nadie dice y que sube la nota.
- 🩺 **Diagnóstico.** Qué mirarías primero, y con qué herramienta.
- 📜 **La norma.** Lo que el RFC obliga, cuando merece destacarse fuera de la sección de §6, punto 6.
- ⏱️ **Coste.** Round-trips, latencia o ancho de banda cuando no es obvio.
- 📝 **Contexto.** Por qué la respuesta "clásica" que el lector encontrará por internet ya no aplica.
- 📚 **Referencia inline.** El enlace útil justo donde nace la duda.

**Escala de dificultad 🟢🟡🟠🔴.** Solo en el enunciado de las preguntas (§8.1).

**Marcadores ✅ y ❌.** Solo como señal de sí/no en tablas y bloques `text`.

Fuera de esta lista, de ✅/❌, de la escala y de los emojis de encabezado de §3, **no se usan otros
emojis**. Nada de 🚨, 💸 ni 🎉. La excepción declarada es 🪦 para la sección "lo obsoleto".

### 9.4 Autopsia de un fallo

Cuando un capítulo documenta un fallo real, la estructura es:

1. **El síntoma**, tal y como lo ve el equipo.
2. **El intercambio real** que lo provoca, con sus encabezados.
3. **Qué dice la norma** sobre ese caso, con su cita.
4. **La corrección**, y si es de contrato o de configuración.
5. **La generalización**: qué clase de error es y dónde más aparece.

### 9.5 Diagramas: Mermaid para lo que tiene flechas, `text` para lo que viaja

Lo que decide el formato es qué se dibuja:

- **` ```mermaid ` con `sequenceDiagram`** para los intercambios entre dos o más partes donde importa
  el orden y no los bytes: el saludo TLS 1.2 y 1.3, la respuesta que se pierde por *timeout*. Los
  participantes con alias (`participant C as cliente`), la respuesta perdida con `--x` y los
  comentarios en `Note`, nunca en la flecha. Sin `;` en los mensajes: Mermaid lo lee como fin de
  línea.
- **` ```mermaid ` con `flowchart`** para nodos y flechas: la cadena navegador → CDN → balanceador,
  las pilas de protocolos, los proxies, los *streams* de una conexión, las partes de un mensaje y las
  decisiones (`{…}` para la pregunta, `([…])` para el resultado, la respuesta en la arista).
  Formas para distinguir, nunca color: sin `style`, `classDef` ni `%%{init}%%`.
- **` ```text `** para lo que es literal o posición: el intercambio byte a byte (§9.1), la salida de
  `curl` y `openssl`, la línea de inicio con sus partes subrayadas, la línea de tiempo de una
  conexión y las comparaciones planas `X → Y`. Mermaid no alinea columnas, y un intercambio dibujado
  como flechas pierde los encabezados, que son lo que se enseña.
- **Se valida dibujándolo**: todo `.md` con Mermaid pasa por `mmdc` en un directorio de `zz-code/`
  antes de cerrar.

---

## 10. 📚 Bibliografía, referencias y enlaces

### 10.1 Enlaces externos y orden de autoridad

**Divergencia declarada.** En los corpus hermanos la fuente canónica era un libro o la documentación
del lenguaje. Aquí **la fuente canónica es la norma**, y está publicada, es gratuita y es citable con
precisión. El cierre `## 📚 Para profundizar` admite, **en este orden y marcando el tipo**:

1. **El RFC**, con número, título y URL de `rfc-editor.org`, y **sección concreta** cuando el
   capítulo se apoya en un punto específico. Es la primera entrada de casi todos los capítulos.
2. **Registro de IANA**, cuando lo que importa es la lista viva: tipos de medio, encabezados,
   códigos de estado. El RFC define el mecanismo; IANA mantiene el catálogo.
3. **Documentación de referencia de la web abierta** — MDN. Es la mejor traducción del RFC a lenguaje
   de persona y la que el lector va a usar de verdad.
4. **Libro**, con autor, título, editorial, año y **capítulo concreto**. Sin URL.
5. **Herramienta o especificación complementaria**: `curl`, OpenSSL, la documentación de un servidor.
6. **Tutorial aplicado**, al final y marcado como tutorial. **Baeldung se cita por título entre
   comillas angulares y sin URL**: su CDN responde `403` a cualquier verificación automática.
7. **Video o charla**, solo por canal y título, sin URL.

**Máximo ocho entradas por capítulo.**

Reglas duras, heredadas sin cambios:

- **No se inventan URLs ni números de RFC.** Un RFC mal citado es el error más caro de este corpus,
  porque parece autoridad. Todo número se comprueba contra `rfc-editor.org` antes de escribirlo.
- **Se comprueban por código de estado**, en la misma edición en que se escriben.
- **Nunca se cita un RFC obsoleto sin decirlo.** Si se menciona 2616 o 7230, se dice que están
  obsoletos y se da el vigente.
- **Una URL por concepto**, específica.

### 10.2 Enlaces internos

- **Formato:** enlace Markdown relativo, con el número del documento en el texto visible.
- **Con ancla cuando la sección destino existe y es estable.**
- **Hacia otros corpus, con ruta relativa y diciendo qué hay allí**, no solo enlazando:

  ```markdown
  El `Idempotency-Key` como patrón de diseño de API está en
  [`repaso-spring-entrevistas` `10`](../../../frameworks/01-spring-boot/) — aquí se explica por qué
  el protocolo lo necesita.
  ```

- **Cada capítulo enlaza al menos a los dos capítulos con los que más se toca**, y cierra con el pie
  de navegación.

Verificación mecánica antes de cerrar:

```bash
grep -oh '](\([0-9]\{2\}-[^)#]*\.md\)' *.md | sed 's/](//' | sort -u | while read -r f; do
  [ -f "$f" ] || echo "ROTO: $f"
done
```

### 10.3 Vigencia

El README declara la fecha de revisión general y **cada documento la repite en su encabezado**.
Cuando un documento incorpora algo reciente —HTTP/3 en producción, TLS 1.3 como mínimo exigido, la
deprecación de un encabezado— se marca con 📝 en el texto.

---

## 11. 🔗 Coherencia entre documentos

- **No contradecir documentos anteriores.** Si `01` establece que `SHOULD` admite excepciones
  justificadas, `03` no lo trata como obligación.
- **Terminología estable.** Si `02` dice "encabezado", el resto no alterna con "cabecera" ni con
  "header" sin motivo.
- **Un concepto tiene un solo dueño.** `01` es dueño de cómo se lee un RFC; `03` de la semántica de
  los métodos; `05` del handshake. Los demás usan y enlazan.
- **La frontera con los otros corpus es de altitud, no de tema.** Aquí se explica **qué obliga el
  protocolo**; en `repaso-spring-entrevistas`, **cómo se escribe con el framework**; en
  `repaso-arquitectura-entrevistas`, **qué decisión de sistema implica**. Los tres pueden hablar de
  idempotencia sin duplicarse, y cada uno enlaza a los otros dos.
- **Fuentes de verdad, en orden:**
  1. **Esta guía**, que manda sobre las normas por defecto del repositorio en lo que declare.
  2. **`CLAUDE.md` de la raíz**, para lo que esta guía no toca.
  3. **`README.md` del corpus**, para el alcance y el orden de lectura.
  4. **Documentos ya publicados** — no se contradicen, se matizan.
  5. Decisiones explícitas del chat actual.

---

## 12. ✅ Checklist antes de dar por cerrado un `.md`

**Estructura**

- [ ] Sigue la plantilla de §6, o está declarado como excepción.
- [ ] Encabezado con objetivo, qué asume leído **con enlace**, y **`Vigencia:`**.
- [ ] Abre con `## 1. 🎯 El problema`, no con una definición.
- [ ] Numeración `##` arábiga y continua; emoji funcional en `##`, **ninguno en `###`**.
- [ ] Hay sección **`📜 Lo que dice la norma`**, con la columna de convención separada.
- [ ] Cierra con pie de navegación: Anterior, Siguiente y Relacionado.

**Contenido**

- [ ] Cada concepto sigue **qué es → cómo va → qué obliga → cuánto → cuándo sí → cuándo no →
      veredicto** (§6.1), sin saltarse ninguno de los tres obligatorios.
- [ ] **Toda afirmación normativa lleva su RFC**, y se distingue de la convención.
- [ ] Ningún RFC obsoleto citado como vigente.
- [ ] Todo mecanismo lleva su precio en round-trips, latencia, ancho de banda o modo de fallo.
- [ ] Hay al menos un **intercambio real** con encabezados.
- [ ] Secuencias de mensajes y diagramas de nodos en Mermaid; intercambios, salidas y líneas de
      tiempo en `text` (§9.5). Todo Mermaid dibujado con `mmdc`.
- [ ] Nada que sea territorio de Spring, arquitectura, AWS o GCP: se enlaza, no se reescribe (§1.1).
- [ ] Datos de ejemplo de §5.1 respetados; sin `foo`, sin `/api/v1/thing`.
- [ ] Entre 200 y 350 líneas. Si pasa de 400, se poda o se parte.

**Forma**

- [ ] Tono semi formal y cálido, tuteo latinoamericano (§2).
- [ ] Encabezados con su capitalización canónica (§3).
- [ ] Sin prosa telegrama; tablas sin celdas que necesiten explicación.
- [ ] Como mucho un callout por sección `##`, y solo los de §9.3.

**Evaluación**

- [ ] Entre 20 y 30 preguntas, graduadas 🟢🟡🟠🔴, **ordenadas de menor a mayor dificultad**.
- [ ] Al menos dos preguntas distinguen norma de convención.
- [ ] Reparto de dificultad distinto al del capítulo vecino.
- [ ] **Solucionario actualizado en la misma edición** (§8.2), con enunciado literal.
- [ ] Las tres capas ⏱️ 🗣️ 🔬 en todas las respuestas.

**Referencias y enlaces**

- [ ] `## 📚 Para profundizar` presente, máximo ocho entradas, ordenadas por autoridad (§10.1).
- [ ] **Todos los números de RFC comprobados contra `rfc-editor.org`** en esta edición.
- [ ] Todas las URLs verificadas por código de estado.
- [ ] Al menos dos enlaces internos, y ningún enlace interno roto.
- [ ] Los enlaces a otros corpus dicen **qué hay allí**, no solo enlazan.
