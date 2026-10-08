# 01 — Los RFC: la fuente de verdad

> De dónde sale lo que HTTP obliga, quién lo escribe y cómo se lee sin leerlo entero. El vocabulario
> normativo —`MUST`, `SHOULD`, `MAY`— que decide si un servidor está roto o solo es distinto, la
> cadena de documentos que va de 2616 a 9110, y el caso del prefijo `X-`: una convención que media
> industria sigue usando y que está formalmente desaconsejada desde 2012.
> No asume nada leído. Es el primero por una razón: los otros cinco capítulos citan constantemente.
>
> **Vigencia:** 2026-09-17.

---

## 1. 🎯 El problema

Discusión real de equipo, en una revisión de código:

> — `PATCH` tiene que ser idempotente, como `PUT`.
> — No, `PATCH` no es idempotente.
> — Yo leí que sí. Está en la documentación de HTTP.

Los tres tienen razón en algo y ninguno puede demostrarlo, porque los tres están citando de memoria
un blog que citaba a otro blog. La discusión se resuelve en noventa segundos si alguien sabe **dónde
está escrito**:

```text
RFC 9110 §9.2.2 — "Of the request methods defined by this specification,
                   PUT, DELETE, and safe request methods are idempotent."
```

Y el detalle que zanja el asunto: **`PATCH` no está definido en RFC 9110**. Aparece tres veces en todo
el documento, y las tres como referencia externa. Se define en [RFC 5789](https://www.rfc-editor.org/rfc/rfc5789.html),
que llegó seis años después del HTTP/1.1 que todo el mundo aprendió.

Este capítulo existe porque en una entrevista de Tech Lead la diferencia entre *"creo que sí"* y
*"lo dice RFC 9110 sección 9.2.2, y `PATCH` ni siquiera está ahí"* es enorme, y no cuesta más
esfuerzo: cuesta saber dónde mirar.

> **Regla de entrevista:** cuando afirmes algo sobre el protocolo, di **si lo obliga la norma, lo
> recomienda, o es convención de la industria**. Son tres afirmaciones distintas y mezclarlas es lo
> que produce las discusiones que no se pueden cerrar.

---

## 2. 🧱 Qué es un RFC, y qué no

**Qué es.** Un documento numerado publicado por el **RFC Editor**, la mayoría producidos por grupos
de trabajo del **IETF**. El número es único y **permanente**.

**Cómo va.** Y aquí está la propiedad que todo el mundo desconoce y que lo explica casi todo:

```text
Un RFC NO se edita nunca.
Si algo cambia, se publica un RFC NUEVO que OBSOLETA al anterior.
```

- Por eso RFC 2616 sigue existiendo, sigue siendo accesible y sigue apareciendo el primero en muchas
  búsquedas: **no se borró, se jubiló**. El documento dice en su cabecera quién lo obsoleta, y ese
  campo es lo primero que hay que mirar.
- Por eso tampoco existe "la versión 2 de un RFC". Existen cadenas: un documento actualiza o obsoleta
  a otros, y esa cadena es rastreable.
- **"Request for Comments" es un nombre histórico**, de cuando eran literalmente eso. Hoy un RFC en
  vía de estándar es una norma, no una propuesta a debate.

**Qué no es.** No es un tutorial, no es documentación de producto y **no es necesariamente un
estándar**: hay RFC informativos, experimentales e incluso humorísticos —los del 1 de abril—. Lo que
determina su peso es su **categoría**, que es la sección 3.

**Cuánto cuesta ignorarlo.** Discusiones irresolubles, decisiones de contrato basadas en folclore, y
la respuesta de entrevista que no se puede defender cuando el entrevistador repregunta.

> **Veredicto:** el RFC es la única fuente que no opina. Todo lo demás —MDN, Stack Overflow, este
> corpus— es una traducción, y las traducciones envejecen.

---

## 3. 📜 Las categorías, y cuál obliga

No todos los RFC tienen el mismo peso, y la cabecera lo dice siempre:

| Categoría | Qué significa | Ejemplo del temario |
|---|---|---|
| **Standards Track** | Norma. Pasa por *Proposed Standard* y puede llegar a *Internet Standard* | RFC 9110 (HTTP Semantics) |
| **Internet Standard (STD)** | El escalón más alto: probado e interoperable | **STD 97** es RFC 9110 |
| **Best Current Practice (BCP)** | Práctica recomendada por la comunidad, no protocolo | **BCP 14** es RFC 2119 |
| **Informational** | Documenta algo sin normarlo | Muchos formatos propietarios |
| **Experimental** | Se publica para probarlo | Extensiones en evaluación |
| **Historic** | Superado o abandonado | Protocolos retirados |

Dos detalles que se preguntan:

- **El número STD/BCP es estable y el RFC que lo implementa puede cambiar.** STD 97 es "HTTP
  Semantics"; hoy lo materializa RFC 9110, y si mañana se publica un sucesor, STD 97 apuntará al
  nuevo. Citar el STD es citar la idea; citar el RFC es citar el texto.
- **Un BCP no es un protocolo.** RFC 2119 no define nada que viaje por el cable: define cómo se leen
  las otras normas. Y aun así es probablemente el documento más citado de todos.

---

## 4. 🧱 `MUST`, `SHOULD`, `MAY`: el vocabulario que decide

**El problema.** Dos servidores se comportan distinto ante la misma petición. ¿Cuál está roto?

**Qué es.** [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.html) —*Key words for use in RFCs to Indicate
Requirement Levels*, **BCP 14**— fija el significado exacto de unas pocas palabras, y todos los RFC
posteriores las usan con ese significado:

```text
MUST     / REQUIRED / SHALL       obligatorio. Incumplirlo es estar roto.
MUST NOT / SHALL NOT              prohibido.
SHOULD   / RECOMMENDED            recomendado. Se puede incumplir CON MOTIVO y entendiendo el coste.
SHOULD NOT                        desaconsejado, con la misma salvedad.
MAY      / OPTIONAL               opcional de verdad. Ambas opciones son conformes.
```

- **La respuesta a "¿cuál está roto?" casi siempre es "ninguno, era un `SHOULD`".** Mucha
  interoperabilidad incómoda vive en los `SHOULD` y en los `MAY`.
- **`MAY` obliga al otro lado.** Si la norma dice que un servidor `MAY` hacer algo, **tu cliente
  tiene que tolerar las dos posibilidades**. Es el error de lectura más frecuente: leer `MAY` como
  "da igual" en vez de "prepárate para las dos".
- [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174.html) añadió después una precisión que parece
  burocrática y no lo es: **solo cuentan en MAYÚSCULAS**. Un "should" en minúscula dentro de un
  párrafo es prosa, no norma.

> 💡 **Truco.** En una entrevista, decir *"eso es un `SHOULD`, no un `MUST`, así que un servidor puede
> no hacerlo y sigue siendo conforme"* demuestra que has leído normas y no resúmenes. Es de las
> frases que mejor relación esfuerzo/impresión tienen de todo el corpus.

---

## 5. 🧱 La cadena de HTTP: de 2616 a 9110

**El problema.** Buscas "HTTP RFC" y el primer resultado es RFC 2616. Está obsoleto **desde 2014** y
sigue siendo la fuente que más se cita en internet.

**La cadena real**, verificada en las cabeceras de cada documento:

```text
RFC 2616 (1999)  HTTP/1.1, todo en un documento    ← Fielding et al. OBSOLETO
      ↓
RFC 7230-7235 (2014)  se parte en seis documentos   ← OBSOLETOS a su vez
      ↓
RFC 9110 (2022)  HTTP Semantics          STD 97    ← métodos, estados, encabezados
RFC 9111 (2022)  HTTP Caching            STD 98    ← Cache-Control, ETag, 304
RFC 9112 (2022)  HTTP/1.1                STD 99    ← la sintaxis en el cable
RFC 9113 (2022)  HTTP/2                            ← obsoleta 7540
RFC 9114 (2022)  HTTP/3
```

**La reorganización de 2022 es la clave de todo el corpus**, y conviene entenderla:

- **La semántica se separó del transporte.** Qué significa `GET`, qué significa `404` y qué significa
  `Content-Type` está en **9110**, y vale igual para HTTP/1.1, HTTP/2 y HTTP/3. Lo que cambia entre
  versiones es **cómo se codifica**, no qué significa.
- Por eso este corpus dedica los capítulos `02`, `03` y `04` a la semántica —que no caduca con la
  versión— y solo el `06` a las diferencias entre versiones.
- **El caché tiene documento propio** (9111), lo que es una señal de su peso: es el capítulo `03` de
  aquí y casi nadie lo aprovecha.

> 📝 **Contexto.** Si encuentras una fuente que cita "RFC 2616 sección 9.5" para hablar de `POST`,
> no está equivocada de hechos —la semántica apenas cambió— pero está citando un documento retirado
> hace más de una década. En una entrevista, citar 2616 delante de alguien que conoce 9110 es una
> señal de que aprendiste HTTP hace tiempo y no volviste.

---

## 6. 🧱 Cómo se lee un RFC sin leerlo entero

**El problema.** RFC 9110 tiene más de diez mil líneas. Nadie lo lee entero, y no hace falta.

**Cómo va.** Un RFC de norma tiene una estructura fija, y se navega por ella:

```text
Cabecera        categoría, STD/BCP, qué obsoleta y qué lo obsoleta  ← MIRAR SIEMPRE PRIMERO
Status of This Memo / Abstract   de qué va, en un párrafo
Tabla de contenidos              la que se usa de verdad
Cuerpo numerado                  se salta a la sección concreta
Security Considerations          obligatoria en todo RFC; suele ser lo más interesante
IANA Considerations              qué registros crea o modifica  ← el catálogo vivo
Referencias normativas           las que hay que leer también
```

Tres cosas que aceleran mucho la lectura:

- **La sintaxis se escribe en ABNF** ([RFC 5234](https://www.rfc-editor.org/rfc/rfc5234.html)). No hace
  falta dominarla: basta saber que `/` es alternativa, `*` es repetición y los corchetes marcan lo
  opcional, y se entiende cualquier definición de encabezado.
- **`Security Considerations` es de lectura obligada** cuando vas a implementar algo. Ahí está lo que
  puede salir mal, escrito por quien diseñó el mecanismo.
- **`IANA Considerations` te lleva al registro**, y el registro es la lista viva. El RFC define el
  mecanismo de los tipos de medio; **IANA mantiene el catálogo** de cuáles existen. Para "¿existe
  este `Content-Type`?" se mira IANA, no el RFC.

**Cuándo sí** ir al RFC: cuando hay discusión, cuando el comportamiento observado no cuadra con lo
esperado, y cuando vas a escribir un contrato que otros van a consumir.

**Cuándo no.** Para aprender el concepto por primera vez. Un RFC está escrito para implementadores,
no para aprender: ahí MDN es mejor, y decirlo así es honesto.

---

## 7. 🪦 El caso `X-`: la convención que la norma desaconseja

**El problema.** Necesitas un encabezado propio para el total de registros de una respuesta paginada.
La convención que todo el mundo conoce dice `X-Total-Count`. ¿Es correcto?

**Lo que dice la norma.** [RFC 6648](https://www.rfc-editor.org/rfc/rfc6648.html) —*Deprecating the "X-"
Prefix and Similar Constructs*, **Best Current Practice**, publicado en **2012**— desaconseja
explícitamente el prefijo.

**El porqué, que es lo interesante.** La convención tenía una lógica: `X-` marcaba "experimental, no
estandarizado". El problema es lo que pasaba después:

```text
1. Alguien crea X-Forwarded-For como extensión experimental
2. La usa todo el mundo. Deja de ser experimental hace años
3. Se estandariza el concepto... pero el nombre ya tiene la X pegada para siempre
4. Y ahora conviven X-Forwarded-For (de facto) y Forwarded (RFC 7239, el estándar real)
```

- **El prefijo no aporta información y sí la estropea**: no dice quién lo definió, y cuando la
  extensión triunfa hay que elegir entre romper a todos los clientes o quedarse con una `X` mentirosa
  para siempre.
- La recomendación de 6648 es sencilla: **usa un nombre descriptivo sin prefijo**, y si el encabezado
  es de tu organización, usa un espacio de nombres propio y reconocible.

**Qué se hace hoy, en la práctica:**

```text
X-Total-Count        convención viejísima, viva, y desaconsejada por BCP desde 2012
Total-Count          lo que recomienda 6648: descriptivo y sin prefijo
Ejemplo-Total-Count  con prefijo de organización, si hay riesgo de colisión
Link                 la alternativa ESTÁNDAR para paginación: RFC 8288, encabezado ya registrado
```

> ⚠️ **Advertencia.** El matiz que hay que decir en una entrevista: **usar `X-` no rompe nada** —
> ningún servidor lo rechaza— y sigue siendo lo que verás en el 90 % de las APIs existentes. La
> respuesta correcta no es "está mal", es *"es una convención desaconsejada por RFC 6648 desde 2012;
> en una API nueva usaría un nombre sin prefijo, y para paginación miraría primero el encabezado
> `Link`, que ya está estandarizado"*. Eso distingue norma, convención y criterio en una sola frase.

---

## 8. 📜 Lo que dice la norma

El resumen citable de este capítulo, con la columna que este corpus nunca omite:

| Afirmación | Fuente | ¿Obliga o es convención? |
|---|---|---|
| `PUT`, `DELETE` y los métodos seguros son idempotentes | RFC 9110 §9.2.2 | **Norma** |
| `PATCH` no está definido en el núcleo de HTTP | RFC 5789 lo define aparte | **Norma** |
| `MUST` es obligatorio; `SHOULD` admite excepción justificada | RFC 2119 (BCP 14) | **Norma sobre cómo leer normas** |
| Las palabras clave solo cuentan en mayúsculas | RFC 8174 | **Norma** |
| La semántica de HTTP es independiente de la versión | RFC 9110, por diseño | **Norma** |
| RFC 2616 está obsoleto desde 2014 | Cabecera de 7230 y 9110 | **Hecho verificable** |
| El prefijo `X-` está desaconsejado | RFC 6648 (BCP) | **Recomendación**, no prohibición |
| `X-Total-Count` para paginación | Ninguna | **Convención de la industria** |
| El catálogo de tipos de medio vive en IANA | Sección IANA de los RFC | **Norma** |

---

## 9. 🔭 Dónde aparece de verdad

En la discusión de equipo que no se cierra porque nadie cita la fuente; en la revisión de un contrato
de API, cuando hay que decidir si un encabezado propio se llama `X-algo` o no; en el informe de una
auditoría, que cita el RFC y espera que tú sepas leerlo; en la integración con un tercero cuyo
servidor hace algo raro y hay que determinar si está incumpliendo la norma o aprovechando un
`SHOULD`; y en la entrevista, cuando alguien pregunta *"¿y eso dónde está escrito?"* — que es
exactamente la repregunta que separa al que sabe del que recuerda.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Lo dice el RFC de HTTP" | Hay cinco vigentes: 9110 semántica, 9111 caché, 9112/9113/9114 versiones |
| "RFC 2616 dice que…" | Está **obsoleto desde 2014**. Lo vigente es 9110 y siguientes |
| "`SHOULD` significa que hay que hacerlo" | Significa recomendado: se puede incumplir con motivo, y sigue siendo conforme |
| "`MAY` significa que da igual" | Significa que **tu cliente tiene que tolerar las dos opciones** |
| "Los encabezados propios llevan `X-`" | Desaconsejado por RFC 6648 desde 2012. Sin prefijo, o con uno de organización |
| "`PATCH` es idempotente como `PUT`" | No lo es por definición, y ni siquiera se define en RFC 9110 |
| "Un RFC se actualiza cuando cambia algo" | Nunca se edita: se publica otro que lo obsoleta |

---

## 📚 Para profundizar

- **RFC** — [RFC 9110 — *HTTP Semantics*](https://www.rfc-editor.org/rfc/rfc9110.html) (STD 97). **El
  documento central de este corpus.** Si solo abres uno, este; y empieza por su tabla de contenidos,
  no por la primera página.
- **RFC** — [RFC 2119 — *Key words for use in RFCs to Indicate Requirement Levels*](https://www.rfc-editor.org/rfc/rfc2119.html)
  (BCP 14), y su precisión posterior [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174.html). Dos páginas
  que cambian cómo lees todo lo demás.
- **RFC** — [RFC 6648 — *Deprecating the "X-" Prefix and Similar Constructs*](https://www.rfc-editor.org/rfc/rfc6648.html)
  (BCP). Corto, y resuelve una discusión que sigue viva en casi todos los equipos.
- **RFC** — [RFC 5789 — *PATCH Method for HTTP*](https://www.rfc-editor.org/rfc/rfc5789.html): la
  demostración de que `PATCH` llegó después y por separado.
- **Registro** — [IANA — HTTP Field Name Registry](https://www.iana.org/assignments/http-fields/http-fields.xhtml):
  el catálogo vivo de encabezados registrados. Antes de inventarte uno, se mira aquí.
- **Referencia** — [MDN — HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP): la traducción del
  RFC a lenguaje de persona, y la que vas a usar el 90 % de las veces. Con la salvedad de que es una
  traducción: cuando haya discusión, gana el RFC.
- **Libro** — Fielding, *Architectural Styles and the Design of Network-based Software Architectures*
  (tesis doctoral, 2000). El capítulo 5 es donde se define REST; leerlo explica por qué casi nada de
  lo que llamamos REST lo es.
- **Herramienta** — [RFC Editor — búsqueda](https://www.rfc-editor.org/search/rfc_search.php): para
  comprobar en veinte segundos si lo que ibas a citar sigue vigente.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Qué es un RFC y quién los publica? 🟢
2. ¿Qué pasa cuando el contenido de un RFC tiene que cambiar? 🟢
3. ¿Qué significan `MUST`, `SHOULD` y `MAY`? 🟢
4. ¿Qué RFC define la semántica de HTTP hoy? 🟢
5. ¿Está vigente RFC 2616? 🟢
6. ¿Qué dice RFC 6648 sobre el prefijo `X-`? 🟢
7. ¿En qué RFC se define `PATCH`? 🟢
8. ¿Qué diferencia hay entre un Standards Track y un BCP? 🟡
9. ¿Qué diferencia hay entre citar un STD y citar un RFC? 🟡
10. ¿Por qué la semántica de HTTP se separó del transporte en 2022? 🟡
11. ¿Qué implica para tu **cliente** que la norma diga que un servidor `MAY` hacer algo? 🟡
12. ¿Por qué solo cuentan las palabras clave en mayúsculas? 🟡
13. ¿Qué secciones de un RFC se leen primero y por qué? 🟡
14. ¿Qué hay en el registro de IANA que no está en el RFC? 🟡
15. Dos servidores responden distinto a la misma petición y ninguno viola la norma. ¿Cómo es
    posible? 🟠
16. ¿Por qué el prefijo `X-` acabó siendo un problema? Explica el mecanismo. 🟠
17. ¿Es incorrecto usar `X-Total-Count` hoy? Responde con matiz. 🟠
18. ¿Cuándo vale más MDN que el RFC, y cuándo al revés? 🟠
19. ¿Por qué el caché tiene un RFC propio y qué te dice eso? 🟠
20. Un tercero te dice que su API es conforme a HTTP y hace algo que te sorprende. ¿Cómo lo
    verificas? 🟠
21. Te piden definir tres encabezados propios para una API nueva. Escribe cómo los nombrarías y
    justifica cada decisión con su fuente. 🔴
22. En una revisión de código, un compañero afirma que `PATCH` es idempotente. Escribe tu respuesta
    completa, con la cita. 🔴
23. Tu equipo va a publicar una API pública. Escribe la lista de comprobación de cinco puntos que
    usarías para verificar que cada afirmación del contrato tiene fuente, y di qué fuente aceptas
    para cada tipo de afirmación. 🔴
24. Un proveedor afirma que su servidor es conforme a HTTP y devuelve `200` con un cuerpo de error.
    Construye el argumento, con citas, para exigirle el cambio. 🔴
25. Escribe el párrafo de una guía de estilo interna que fije cómo se nombran los encabezados
    propios de la empresa, citando las fuentes y previendo el caso de que uno se estandarice. 🔴
---

**Siguiente:** [`02` — El mensaje y los encabezados](02-el-mensaje-y-los-encabezados.md) ·
**Relacionado:** [`03` — Métodos, semántica e idempotencia](03-metodos-semantica-e-idempotencia.md)
