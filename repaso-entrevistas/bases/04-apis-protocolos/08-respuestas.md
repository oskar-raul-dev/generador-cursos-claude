# 08 — Respuestas

> El solucionario completo del corpus: las 166 preguntas de los seis capítulos, las 40 transversales
> de la simulación y los seis escenarios. **Cada respuesta va en tres capas**, siempre las tres.
>
> ```text
> ⏱️ 30 segundos  → lo que dices primero, en una respiración
> 🗣️ 2 minutos    → lo que añades cuando dicen "cuéntame más"
> 🔬 El detalle   → el matiz, el número y la cita de la norma
> ```
>
> **Vigencia:** 2026-09-17.

---

## Salto rápido

| Capítulo | Preguntas | Ir |
|---|---|---|
| `01` Los RFC | 25 | [ir](#capítulo-01--los-rfc-la-fuente-de-verdad) |
| `02` El mensaje y los encabezados | 27 | [ir](#capítulo-02--el-mensaje-y-los-encabezados) |
| `03` Métodos, semántica e idempotencia | 28 | [ir](#capítulo-03--métodos-semántica-e-idempotencia) |
| `04` Codificación y formatos | 28 | [ir](#capítulo-04--codificación-y-formatos) |
| `05` TLS y seguridad del transporte | 29 | [ir](#capítulo-05--tls-y-seguridad-del-transporte) |
| `06` Versiones, proxies y tiempo real | 29 | [ir](#capítulo-06--versiones-proxies-y-tiempo-real) |
| `07` Simulación: transversales | 40 | [ir](#simulación--preguntas-transversales) |
| `07` Simulación: escenarios | 6 | [ir](#simulación--escenarios) |

---

## Capítulo 01 — Los RFC: la fuente de verdad

**01 → 1.** **¿Qué es un RFC y quién los publica? 🟢**

- ⏱️ Un documento numerado y permanente publicado por el RFC Editor, casi siempre producido por un
  grupo de trabajo del IETF. Es donde están escritas las normas de internet.
- 🗣️ El nombre —*Request for Comments*— es histórico: hoy un RFC en vía de estándar es una norma, no
  una propuesta a debate. El número es único y no se reutiliza jamás, así que citar "RFC 9110" es una
  referencia inequívoca y para siempre.
- 🔬 No todo RFC es un estándar: los hay informativos, experimentales, históricos y de práctica
  recomendada. Lo que determina su peso es la **categoría**, que va en la cabecera del documento.

**01 → 2.** **¿Qué pasa cuando el contenido de un RFC tiene que cambiar? 🟢**

- ⏱️ No se edita nunca: se publica un RFC nuevo que obsoleta al anterior.
- 🗣️ Por eso RFC 2616 sigue existiendo y sigue siendo accesible aunque lleve más de una década
  retirado: no se borró, se jubiló. La propia cabecera dice qué obsoleta y qué lo obsoleta.
- 🔬 Consecuencia práctica: **no existe "la versión 2" de un RFC**, existen cadenas. Lo primero que
  se mira al abrir uno es la cabecera, no el contenido.

**01 → 3.** **¿Qué significan `MUST`, `SHOULD` y `MAY`? 🟢**

- ⏱️ `MUST` es obligatorio, `SHOULD` es recomendado —se puede incumplir con motivo— y `MAY` es
  opcional de verdad: las dos opciones son conformes.
- 🗣️ Lo fija RFC 2119, que es **BCP 14**, y todos los RFC posteriores usan esas palabras con ese
  significado exacto. `REQUIRED` y `SHALL` son sinónimos de `MUST`; `RECOMMENDED`, de `SHOULD`.
- 🔬 RFC 8174 añadió que **solo cuentan en mayúsculas**: un "should" en minúscula dentro de un
  párrafo es prosa, no norma. Y `MAY` obliga al otro extremo: si un servidor `MAY` hacer algo, tu
  cliente tiene que tolerar las dos posibilidades.

**01 → 4.** **¿Qué RFC define la semántica de HTTP hoy? 🟢**

- ⏱️ RFC 9110, *HTTP Semantics*, que además es **STD 97**.
- 🗣️ Ahí están los métodos, los códigos de estado y los encabezados, y vale por igual para HTTP/1.1,
  HTTP/2 y HTTP/3. El caché tiene documento propio, RFC 9111, y cada versión del transporte el suyo:
  9112, 9113 y 9114.
- 🔬 Esa separación es de 2022 y es la idea central del corpus: **lo que significa `GET` no depende de
  la versión del protocolo**; lo que cambia entre versiones es cómo se codifica el mensaje.

**01 → 5.** **¿Está vigente RFC 2616? 🟢**

- ⏱️ No. Está obsoleto desde 2014, y sin embargo sigue siendo la fuente más citada de internet.
- 🗣️ Lo sustituyeron los RFC 7230 a 7235, que partieron HTTP/1.1 en seis documentos, y esos a su vez
  fueron obsoletados en 2022 por la familia 9110–9114.
- 🔬 Los hechos apenas cambiaron —la semántica de `GET` es la misma—, así que citar 2616 no suele
  llevar a una conclusión errónea; lleva a parecer alguien que aprendió HTTP hace quince años y no
  volvió a mirar.

**01 → 6.** **¿Qué dice RFC 6648 sobre el prefijo `X-`? 🟢**

- ⏱️ Lo desaconseja explícitamente, desde 2012, y es un *Best Current Practice*.
- 🗣️ La recomendación es usar un nombre descriptivo sin prefijo y, si hace falta, un espacio de
  nombres propio de la organización.
- 🔬 Es una recomendación, no una prohibición: `X-Total-Count` funciona en todas partes y está en el
  90 % de las APIs existentes. La respuesta completa distingue las dos cosas.

**01 → 7.** **¿En qué RFC se define `PATCH`? 🟢**

- ⏱️ En RFC 5789, no en el núcleo de HTTP.
- 🗣️ En RFC 9110, `PATCH` aparece solo tres veces, y las tres como referencia externa. Llegó seis
  años después del HTTP/1.1 que casi todo el mundo aprendió.
- 🔬 Ese dato zanja por sí solo la discusión sobre su idempotencia: no puede estar en la lista de
  métodos idempotentes de un documento que ni siquiera lo define.

**01 → 8.** **¿Qué diferencia hay entre un Standards Track y un BCP? 🟡**

- ⏱️ Un Standards Track define un protocolo; un BCP define una práctica recomendada por la comunidad.
- 🗣️ El primero describe algo que viaja por el cable; el segundo, cómo se opera o cómo se lee. RFC
  9110 es Standards Track; RFC 2119 y RFC 6648 son BCP.
- 🔬 Un BCP no es menos vinculante en una auditoría: RFC 8996, que deprecia TLS 1.0 y 1.1, es un BCP,
  y es exactamente lo que se cita en un informe de cumplimiento.

**01 → 9.** **¿Qué diferencia hay entre citar un STD y citar un RFC? 🟡**

- ⏱️ El número STD es estable y apunta a la idea; el número RFC apunta al texto concreto.
- 🗣️ STD 97 es "HTTP Semantics", y hoy lo materializa RFC 9110. Si mañana se publica un sucesor, STD
  97 pasará a apuntar al nuevo documento y el número 9110 seguirá señalando el texto de 2022.
- 🔬 Para discutir un detalle se cita el RFC y la sección; para un contrato o una política a largo
  plazo, el STD envejece mejor.

**01 → 10.** **¿Por qué la semántica de HTTP se separó del transporte en 2022? 🟡**

- ⏱️ Porque el mismo significado tenía que servir para tres codificaciones distintas: HTTP/1.1,
  HTTP/2 y HTTP/3.
- 🗣️ Antes de 2022, cada versión repetía o referenciaba de forma incómoda qué significaban los
  métodos y los códigos. Al extraer 9110, quedó un documento único de significado y documentos
  separados de sintaxis.
- 🔬 El efecto práctico es enorme para estudiar: **lo que aprendes de métodos, estados y encabezados
  no caduca al cambiar de versión**, y solo hay que aprender de nuevo el empaquetado.

**01 → 11.** **¿Qué implica para tu **cliente** que la norma diga que un servidor `MAY` hacer algo? 🟡**

- ⏱️ Que tu cliente tiene que funcionar correctamente en los dos casos: si lo hace y si no lo hace.
- 🗣️ Es el error de lectura más común: se lee `MAY` como "da igual" cuando significa "prepárate para
  ambas". Un servidor puede mandar o no mandar cierto encabezado, puede o no cerrar la conexión, y
  ambas conductas son conformes.
- 🔬 De ahí salen muchos bugs de integración que se atribuyen al proveedor: el servidor no está roto,
  está ejerciendo una opción que la norma le concede y que el cliente no contempló.

**01 → 12.** **¿Por qué solo cuentan las palabras clave en mayúsculas? 🟡**

- ⏱️ Porque en minúscula son prosa normal, y los RFC están escritos en inglés corriente donde
  "should" aparece constantemente sin intención normativa.
- 🗣️ Lo aclaró RFC 8174, precisamente porque hubo discusiones reales sobre si un "must" en minúscula
  dentro de un párrafo explicativo obligaba o no.
- 🔬 Por eso los RFC modernos incluyen un párrafo estándar al principio diciendo que las palabras
  clave se interpretan según RFC 2119 y RFC 8174 **cuando aparecen en mayúsculas**.

**01 → 13.** **¿Qué secciones de un RFC se leen primero y por qué? 🟡**

- ⏱️ La cabecera —categoría y qué obsoleta—, la tabla de contenidos, y después solo la sección
  concreta que te interesa.
- 🗣️ Nadie lee un RFC entero: RFC 9110 pasa de diez mil líneas. Se navega. Y hay dos secciones que
  siempre merecen la pena: *Security Considerations*, que explica qué puede salir mal escrito por
  quien diseñó el mecanismo, e *IANA Considerations*, que te lleva al registro vivo.
- 🔬 La sintaxis se define en ABNF (RFC 5234): con saber que `/` es alternativa, `*` repetición y los
  corchetes marcan lo opcional, se lee cualquier definición de encabezado.

**01 → 14.** **¿Qué hay en el registro de IANA que no está en el RFC? 🟡**

- ⏱️ El catálogo vivo: los valores concretos registrados desde que se publicó el documento.
- 🗣️ El RFC define el **mecanismo** —qué es un tipo de medio, qué es un encabezado— y IANA mantiene
  la **lista**. Para saber si `application/problem+json` existe, o si un encabezado que te encontraste
  está registrado, se mira IANA.
- 🔬 Es también donde se comprueba antes de inventar un nombre propio: si ya existe un encabezado
  estándar para lo que necesitas —`Link` para paginación, por ejemplo— inventar otro es peor.

**01 → 15.** **Dos servidores responden distinto a la misma petición y ninguno viola la norma. ¿Cómo es posible? 🟠**

- ⏱️ Porque el comportamiento en cuestión es un `SHOULD` o un `MAY`, no un `MUST`.
- 🗣️ Gran parte de la interoperabilidad incómoda de HTTP vive exactamente ahí. Un servidor puede
  cerrar la conexión o mantenerla, incluir o no un encabezado opcional, rechazar o procesar un
  mensaje ambiguo — y las dos conductas son conformes.
- 🔬 La conclusión operativa es que **el cliente robusto se escribe contra lo que la norma permite, no
  contra lo que un servidor concreto hace hoy**. Probar contra una sola implementación es cómo se
  producen integraciones que se rompen al cambiar de proveedor.

**01 → 16.** **¿Por qué el prefijo `X-` acabó siendo un problema? Explica el mecanismo. 🟠**

- ⏱️ Porque marcaba "experimental", y las extensiones que triunfan dejan de serlo sin poder cambiar
  de nombre.
- 🗣️ El ciclo es siempre el mismo: alguien crea `X-Algo` como experimento, lo adopta todo el mundo,
  deja de ser experimental, y cuando por fin se estandariza hay que elegir entre romper a todos los
  clientes o arrastrar una `X` que ya miente. `X-Forwarded-For` es el caso de manual: hoy convive con
  `Forwarded`, el estándar de RFC 7239, y el de facto sigue siendo el primero.
- 🔬 RFC 6648 resume el argumento: el prefijo no aporta información —no dice quién lo definió— y sí
  crea un coste de migración garantizado si la extensión tiene éxito.

**01 → 17.** **¿Es incorrecto usar `X-Total-Count` hoy? Responde con matiz. 🟠**

- ⏱️ No es incorrecto, es desaconsejado: funciona en todas partes y está desaconsejado por RFC 6648
  desde 2012.
- 🗣️ En una API existente, cambiarlo por cambiarlo no compensa: rompe clientes por un beneficio
  estético. En una API nueva, usaría un nombre sin prefijo, y antes de inventarlo miraría si el
  encabezado `Link` (RFC 8288) ya resuelve la paginación, que es su caso estándar.
- 🔬 Esta es la respuesta modelo de "norma, recomendación o convención": ninguna norma lo prohíbe,
  un BCP lo desaconseja, y la industria lo usa masivamente. Decir las tres cosas es lo que distingue.

**01 → 18.** **¿Cuándo vale más MDN que el RFC, y cuándo al revés? 🟠**

- ⏱️ MDN para aprender y para el día a día; el RFC cuando hay discusión, contrato o comportamiento
  raro.
- 🗣️ Un RFC está escrito para implementadores: es preciso y pésimo como material de aprendizaje. MDN
  traduce, da ejemplos y añade compatibilidad de navegadores, que el RFC nunca tendrá.
- 🔬 La regla de decisión: si la respuesta va a acabar en un contrato de API, en una auditoría o en
  una discusión que no se cierra, la fuente es el RFC. Para todo lo demás, MDN y se sigue trabajando.

**01 → 19.** **¿Por qué el caché tiene un RFC propio y qué te dice eso? 🟠**

- ⏱️ Porque es un subsistema completo, con su propio modelo de frescura, validación y almacenamiento
  compartido — no un par de encabezados.
- 🗣️ Que los editores le dedicaran un documento entero (RFC 9111, además **STD 98**) es una señal de
  peso: hay más semántica en el caché de HTTP que en la mayoría de las APIs que lo ignoran.
- 🔬 Y es, en la práctica, la funcionalidad más desaprovechada del protocolo: casi todas las APIs
  responden `no-cache` o nada, y se pierden `ETag`, `304`, `stale-while-revalidate` y la concurrencia
  optimista con `If-Match`.

**01 → 20.** **Un tercero te dice que su API es conforme a HTTP y hace algo que te sorprende. ¿Cómo lo verificas? 🟠**

- ⏱️ Busco el comportamiento concreto en RFC 9110 y miro si lo que hace está bajo un `MUST`, un
  `SHOULD` o un `MAY`.
- 🗣️ El orden es: reproducir el intercambio crudo —con `curl -v` o `--trace-ascii`, para ver los
  bytes y no la interpretación del cliente—, localizar la sección, y entonces decidir si es un
  incumplimiento, una opción legítima o una convención que yo daba por hecha.
- 🔬 Si resulta ser un `MAY` que yo no contemplaba, el que tiene que cambiar es mi cliente. Si es un
  `MUST` incumplido, ya tengo la cita exacta para el correo, y eso cambia por completo el tono de la
  conversación con el proveedor.

**01 → 21.** **Te piden definir tres encabezados propios para una API nueva. Escribe cómo los nombrarías y justifica cada decisión con su fuente. 🔴**

- ⏱️ Primero compruebo en IANA si ya existe uno estándar; si no, nombres descriptivos sin `X-`, con
  prefijo de organización solo si hay riesgo real de colisión.
- 🗣️ Ejemplo concreto para paginación, identificador de traza y clave de idempotencia:

  ```text
  Link: <…>; rel="next"     ← NO invento nada: RFC 8288 ya lo resuelve
  Total-Count: 4821         ← descriptivo, sin prefijo, por RFC 6648
  Idempotency-Key: 7f3c…    ← convención de industria, hoy en borrador IETF
  ```
- 🔬 Las tres decisiones son de tipo distinto y conviene decirlo así: la primera es **reutilizar un
  estándar registrado**; la segunda, **aplicar una recomendación** (RFC 6648) al inventar; la tercera,
  **adoptar una convención** ampliamente implantada aunque todavía no sea RFC, que es mejor que
  inventar un nombre propio para lo mismo. Y todo lo que invente va documentado en el contrato de la
  API, porque un cliente no puede deducirlo.

**01 → 22.** **En una revisión de código, un compañero afirma que `PATCH` es idempotente. Escribe tu respuesta completa, con la cita. 🔴**

- ⏱️ "No lo es por definición. RFC 9110 §9.2.2 dice que los idempotentes son `PUT`, `DELETE` y los
  métodos seguros; `PATCH` ni siquiera se define ahí, sino en RFC 5789."
- 🗣️ Y añadiría el matiz que evita quedar en pedante: **un `PATCH` concreto puede ser idempotente**
  según el formato del parche. `{"estado":"PAGADO"}` en Merge Patch lo es; una operación `add` de
  JSON Patch sobre un array no lo es, porque cada aplicación añade otro elemento.
- 🔬 La conclusión para el código que estamos revisando es lo que importa: **si algo puede reintentar
  esta petición —un proxy, el cliente, una cola— no podemos apoyarnos en el método**; la garantía
  tiene que venir del diseño de la operación o de una clave de idempotencia.

**01 → 23.** **Tu equipo va a publicar una API pública. Escribe la lista de comprobación de cinco puntos que usarías para verificar que cada afirmación del contrato tiene fuente, y di qué fuente aceptas para cada tipo de afirmación. 🔴**

- ⏱️ Cinco puntos: nombres de encabezado contra IANA, semántica de método y estado contra RFC 9110,
  formatos contra su RFC, todo lo inventado marcado como propio, y ninguna cita sin verificar.
- 🗣️ La lista, con la fuente aceptada para cada tipo:

  ```text
  1. ¿Cada encabezado propio está justificado?     → registro IANA + RFC 6648
  2. ¿Cada método y código se usa con su semántica? → RFC 9110, con sección
  3. ¿Cada tipo de medio existe o está bien formado? → IANA + RFC 6838
  4. ¿Qué es convención nuestra?                    → marcado como tal en el contrato
  5. ¿Cada URL de la documentación responde 200?    → comprobado por código de estado
  ```
- 🔬 El punto 5 es menos trivial de lo que parece: la documentación de muchos proveedores responde a
  una URL muerta con un `302` al índice, no con `404`, así que "no dio error" no significa "existe".
  Y el punto 4 es el que evita la discusión futura: un cliente tiene derecho a saber qué parte del
  contrato puede deducir de la norma y qué parte es nuestra.

**01 → 24.** **Un proveedor afirma que su servidor es conforme a HTTP y devuelve `200` con un cuerpo de error. Construye el argumento, con citas, para exigirle el cambio. 🔴**

- ⏱️ El argumento no es "queda feo": es que rompe a todos los intermediarios, que solo leen el código
  de estado.
- 🗣️ Desarrollado: RFC 9110 define `2xx` como "la petición se recibió, se entendió y se aceptó
  correctamente", y `4xx`/`5xx` para los fallos. Un `200` con error dentro significa que **las cachés
  guardan el error como si fuera una respuesta válida**, que los reintentos automáticos no se
  disparan, que los paneles de monitorización muestran cero errores, y que cualquier cliente genérico
  —un navegador, una pasarela, una biblioteca— hace exactamente lo contrario de lo correcto.
- 🔬 La petición concreta es doble: usar el código adecuado, y si quiere un cuerpo de error
  estructurado, usar `application/problem+json`, que está estandarizado en **RFC 9457** —ojo, que
  mucha documentación todavía cita el 7807, que es el obsoleto—. Y conviene concederle lo cierto: la
  norma **no le prohíbe** poner detalle en el cuerpo; lo que le impide es llamarlo `200`.

**01 → 25.** **Escribe el párrafo de una guía de estilo interna que fije cómo se nombran los encabezados propios de la empresa, citando las fuentes y previendo el caso de que uno se estandarice. 🔴**

- ⏱️ Un párrafo con tres reglas: no inventar si existe estándar, no usar `X-`, y declarar desde el
  principio qué pasa cuando algo propio se estandariza.
- 🗣️ El texto:

  > *Antes de definir un encabezado propio se consulta el registro de campos de IANA: si existe uno
  > estándar para ese propósito, se usa ese. Si no existe, se elige un nombre descriptivo **sin
  > prefijo `X-`**, desaconsejado por RFC 6648 (BCP) desde 2012; si hay riesgo de colisión con un
  > tercero, se antepone el nombre de la organización. Todo encabezado propio se documenta en el
  > contrato de la API indicando que es una extensión nuestra. Si un encabezado propio se estandariza
  > más adelante, se adopta el estándar y se mantiene el nuestro como alias durante dos versiones
  > mayores, anunciando la retirada en las notas de cada una.*
- 🔬 La última frase es la que casi nunca se escribe y la que evita el problema de `X-Forwarded-For`:
  **el coste de migrar se planifica el día que se inventa el nombre, no el día que hay que migrar**.
  Fijar una ventana explícita —dos versiones mayores— convierte lo que sería una discusión futura en
  una decisión ya tomada.

---

## Capítulo 02 — El mensaje y los encabezados

**02 → 1.** **¿Cuáles son las cuatro partes de un mensaje HTTP? 🟢**

- ⏱️ Línea de inicio, sección de campos, una línea en blanco y el cuerpo, que es opcional.
- 🗣️ La estructura es idéntica en petición y respuesta; lo único que cambia es la primera línea:
  `método target versión` en la petición, `versión código razón` en la respuesta.
- 🔬 La línea en blanco es exactamente un `CRLF` de más, y es el separador obligatorio. Sin ella, el
  servidor sigue esperando encabezados y la petición nunca se procesa.

**02 → 2.** **¿Qué separa los encabezados del cuerpo? 🟢**

- ⏱️ Una línea en blanco: la secuencia `\r\n\r\n`.
- 🗣️ Es lo que hace posible parsear el mensaje en dos fases: se leen líneas hasta encontrar una
  vacía, y a partir de ahí lo que venga son octetos de cuerpo cuya longitud ya se sabe por los
  encabezados que acabas de leer.
- 🔬 El separador de líneas es **CRLF**, no `\n`. Muchos servidores toleran `\n` solo, pero la norma
  pide los dos octetos, y escribir un cliente a mano con `echo` en vez de `printf` es cómo se
  descubre.

**02 → 3.** **¿Los nombres de encabezado distinguen mayúsculas y minúsculas? ¿Y los valores? 🟢**

- ⏱️ Los nombres no; los valores sí, salvo donde la definición del campo diga lo contrario.
- 🗣️ `Content-Type`, `content-type` y `CONTENT-TYPE` son el mismo campo (RFC 9110 §5.1). En HTTP/2 y
  HTTP/3 van **obligatoriamente en minúscula**, lo que confirma que la capitalización era decorativa.
- 🔬 Bastantes valores se comparan sin distinguir porque su definición lo dice: los tipos y subtipos
  de medio, las codificaciones de contenido, las opciones de `Connection`. Otros, como un `ETag` o el
  valor de una cookie, son octetos exactos.

**02 → 4.** **¿Qué diferencia hay entre `Accept` y `Content-Type`? 🟢**

- ⏱️ `Content-Type` describe el cuerpo que va en **este** mensaje; `Accept` expresa qué formato
  prefiero recibir en la respuesta.
- 🗣️ Por eso en un `POST` con JSON aparecen los dos y significan cosas distintas: envío JSON y espero
  JSON. En un `GET` sin cuerpo, `Content-Type` no pinta nada.
- 🔬 Es la confusión más común de todas, y se detecta al leer cualquier cliente mal escrito: poner
  `Content-Type: application/json` en un `GET` para "pedir JSON" no hace nada, porque describe un
  cuerpo que no existe.

**02 → 5.** **¿Para qué sirve `Content-Length`? 🟢**

- ⏱️ Para decir cuántos octetos exactos tiene el cuerpo, de modo que el receptor sepa dónde termina.
- 🗣️ Hace falta porque sobre una conexión reutilizada el cuerpo no tiene marca de fin: si el servidor
  no sabe cuántos octetos leer, no sabe dónde empieza la siguiente petición.
- 🔬 En la respuesta a un `HEAD` el campo describe el cuerpo **que habría tenido** la respuesta a un
  `GET`, aunque no se envíe ninguno. Es la única situación donde el valor "miente" por diseño.

**02 → 6.** **¿Qué es `Transfer-Encoding: chunked` y cuándo se usa? 🟢**

- ⏱️ Un modo de enviar el cuerpo en trozos, cada uno precedido de su tamaño, terminando con un trozo
  de tamaño cero.
- 🗣️ Se usa cuando no se conoce la longitud total al empezar a responder: un informe que se genera al
  vuelo, un listado que se transmite mientras se lee de la base de datos. Sin él habría que
  materializarlo todo en memoria solo para poder contar los octetos.
- 🔬 El tamaño de cada trozo va en **hexadecimal**, y después del trozo cero puede venir una sección
  de *trailers* —campos que solo se conocen al terminar, como una suma de verificación—, normalmente
  vacía.

**02 → 7.** **¿Por qué `Host` es obligatorio en HTTP/1.1? 🟢**

- ⏱️ Porque una misma IP sirve muchos sitios, y sin `Host` el servidor no sabe a cuál va dirigida la
  petición.
- 🗣️ En HTTP/1.0 no existía, y por eso hacía falta una IP por sitio. `Host` es lo que hizo viable el
  alojamiento compartido y, más tarde, todo el modelo de los CDN.
- 🔬 RFC 9112 §3.2 lo pone como `MUST` para el cliente, y comprobado en vivo: una petición HTTP/1.1
  sin `Host` a un servidor real devuelve `400 Bad Request`. Su equivalente en HTTP/2 y HTTP/3 es el
  pseudo-campo `:authority`.

**02 → 8.** **¿Qué significa la frase de motivo de la línea de estado? 🟢**

- ⏱️ Nada: es texto para humanos. Lo que procesa el cliente es el número de tres dígitos.
- 🗣️ `HTTP/1.1 201 Created` y `HTTP/1.1 201 Todo bien` son equivalentes para cualquier cliente
  conforme. Escribir lógica que lea la frase es un error garantizado.
- 🔬 La prueba definitiva: en HTTP/2 y HTTP/3 **la frase no existe**, porque no hay línea de estado.
  Si algo dependiera de ella, se rompería al cambiar de versión.

**02 → 9.** **Escribe a mano una petición `GET` completa y explica cada línea. 🟡**

- ⏱️ Tres líneas y una en blanco: la línea de petición, `Host`, `Connection` y el `CRLF` final.
- 🗣️ El intercambio, tal cual se manda por un socket:

  ```text
  GET /pedidos/PED-00042 HTTP/1.1     ← método, target, versión
  Host: api.ejemplo.com               ← obligatorio; a qué sitio va
  Accept: application/json            ← qué formato prefiero en la respuesta
  Connection: close                   ← cierra al terminar (opcional)
                                      ← línea en blanco: fin de encabezados
  ```
- 🔬 Sin cuerpo no hace falta `Content-Length` ni `Transfer-Encoding`. Y el detalle que se olvida al
  escribirla a mano: cada salto de línea es `\r\n`, incluido el de la línea vacía.

**02 → 10.** **¿Qué pasa si envías un espacio entre el nombre del encabezado y los dos puntos? 🟡**

- ⏱️ El servidor debe responder `400 Bad Request`. No es opcional.
- 🗣️ Comprobado contra un servidor real: `Host : example.com` devuelve `400` de inmediato, antes de
  que la petición llegue a ninguna aplicación.
- 🔬 RFC 9112 §5.1 lo pone como `MUST` y explica el porqué al lado: si dos intermediarios trataran ese
  espacio de forma distinta, interpretarían la petición de forma distinta, y ahí empieza el
  *request smuggling*. Es un `MUST` de seguridad disfrazado de detalle de sintaxis.

**02 → 11.** **¿Qué diferencia hay entre `Content-Encoding` y `Transfer-Encoding`? 🟡**

- ⏱️ `Content-Encoding` es una propiedad del recurso, de extremo a extremo; `Transfer-Encoding` es
  cómo se empaqueta para **este salto**.
- 🗣️ Si un recurso va con `Content-Encoding: gzip`, está comprimido como parte de su representación:
  su `ETag` corresponde a esa forma y el cliente final es quien descomprime. `Transfer-Encoding` lo
  puede quitar y poner cualquier intermediario.
- 🔬 De ahí que `Transfer-Encoding` sea *hop-by-hop* y `Content-Encoding` no. Y de ahí también un bug
  clásico: comprimir cambia el `ETag` fuerte, y una caché mal configurada acaba sirviendo una
  representación con el identificador de otra.

**02 → 12.** **Un encabezado aparece dos veces en el mensaje. ¿Es válido? 🟡**

- ⏱️ Sí, si la definición de ese campo admite lista separada por comas. Entonces equivale a una sola
  línea con los valores unidos por comas.
- 🗣️ `Accept: text/html` seguido de `Accept: application/json` es exactamente `Accept: text/html,
  application/json`. Repetir un campo que **no** admite lista —como `Content-Length`— es un mensaje
  mal formado, no una lista.
- 🔬 El orden entre campos distintos no importa; el orden entre repeticiones del mismo campo **sí** y
  hay que preservarlo al recombinar (RFC 9110 §5.3).

**02 → 13.** **¿Por qué `Set-Cookie` es la excepción a la regla anterior? 🟡**

- ⏱️ Porque su valor puede contener comas —en la fecha de expiración—, así que combinarlo con comas
  lo destruiría.
- 🗣️ Por eso toda API de servidor lo trata aparte: `getHeader("Set-Cookie")` devuelve algo inservible
  cuando hay varias cookies, y hay que usar la variante que devuelve lista.
- 🔬 Es el ejemplo canónico de que la regla general de campos tiene excepciones definidas por cada
  campo, y de por qué un parser genérico de HTTP no puede recombinar a ciegas.

**02 → 14.** **¿Qué son los encabezados *hop-by-hop* y qué les pasa al atravesar un proxy? 🟡**

- ⏱️ Son los que valen solo para un salto de la cadena: el proxy los consume y no los reenvía.
- 🗣️ La familia de control de conexión —`Connection`, `Transfer-Encoding`, `Upgrade`, `Keep-Alive`—
  es de este tipo. Lo demás es de extremo a extremo y llega intacto al origen.
- 🔬 Es la explicación de media docena de sorpresas al depurar detrás de un balanceador: el
  `Connection: keep-alive` que mandó tu cliente no es el que ve el servicio, y el `Upgrade` de un
  WebSocket muere en el proxy que no esté configurado para propagarlo.

**02 → 15.** **¿Para qué sirve `Vary` y qué rompe su ausencia? 🟡**

- ⏱️ Declara de qué encabezados de la petición depende la respuesta, para que las cachés no mezclen
  variantes.
- 🗣️ Si tu respuesta cambia según `Accept-Language` y no lo declaras, la primera respuesta que una
  caché compartida guarde se servirá a todo el mundo: el que pidió español recibe inglés, y solo a
  veces, según a qué nodo de CDN llegue.
- 🔬 Es el bug de caché más silencioso que existe, porque no falla: devuelve `200` con contenido
  válido, solo que el equivocado. Y es intermitente por diseño, lo que lo hace difícil de reproducir.

**02 → 16.** **¿Qué cuerpo lleva una respuesta a `HEAD`, y qué dice su `Content-Length`? 🟡**

- ⏱️ No lleva cuerpo, y `Content-Length` declara el que habría tenido la respuesta a un `GET`.
- 🗣️ La utilidad es justo esa: comprobar tamaño, tipo, fecha o `ETag` de un recurso sin descargarlo.
  Es como se implementa una comprobación de existencia barata o un cliente de descarga que decide si
  reanudar.
- 🔬 Es el único caso en que el campo describe algo que no viaja, y por eso un parser que asuma "si
  hay `Content-Length` hay que leer esos octetos" se queda colgado esperando un cuerpo que no llega.

**02 → 17.** **Llegan `Content-Length` y `Transfer-Encoding` en la misma petición. ¿Qué manda la norma? 🟠**

- ⏱️ `Transfer-Encoding` sobrescribe a `Content-Length`, y el servidor **debe cerrar la conexión**
  después de responder.
- 🗣️ RFC 9112 §6.1 permite además rechazar la petición, a elección del servidor. Lo que no permite es
  seguir usando la conexión, precisamente porque puede haber octetos sobrantes en el buffer.
- 🔬 La norma explica también de dónde viene la ambigüedad: implementaciones antiguas mandaban los
  dos —`chunked` para el framing y una longitud estimada para las barras de progreso—, así que se
  definió una precedencia en lugar de declararlos incompatibles. Esa decisión histórica es la raíz de
  toda la familia del *smuggling*.

**02 → 18.** **Explica el mecanismo del *request smuggling* a partir de la pregunta anterior. 🟠**

- ⏱️ Dos intermediarios en cadena interpretan el final del cuerpo de forma distinta, y los octetos
  que a uno le sobran el otro los lee como una petición nueva.
- 🗣️ El caso típico: el frontal se guía por `Content-Length` y el servidor de origen por
  `Transfer-Encoding`, o al revés. El atacante manda un cuerpo construido para que al segundo le
  sobre un trozo. Ese trozo, que él escribió, queda al principio del buffer y se combina con **la
  siguiente petición de otro usuario**, que acaba ejecutando algo ajeno o revelando su respuesta.
- 🔬 Por eso el `MUST` de cerrar la conexión: sin conexión reutilizada no hay buffer compartido y el
  ataque no tiene dónde ocurrir. Y por eso el `400` obligatorio ante un espacio antes de los dos
  puntos: la misma clase de discrepancia de parseo, en otro punto del mensaje. Las defensas reales
  son normalizar en el borde, rechazar lo ambiguo y que todos los saltos usen la misma versión.

**02 → 19.** **¿Por qué el tamaño de cada trozo de `chunked` va en hexadecimal y qué falla si lo lees en decimal? 🟠**

- ⏱️ Es lo que fija la norma; si lo lees en decimal, lees un número de octetos equivocado y el
  mensaje se desincroniza.
- 🗣️ El fallo es silencioso y desagradable: un trozo declarado `1a` son 26 octetos, no 1; interpretado
  mal, la lectura se desplaza y el siguiente encabezado de trozo cae en medio de los datos. A partir
  de ahí todo el flujo es basura, o el parser se queda esperando octetos que nunca llegan.
- 🔬 Es un error clásico de los parsers escritos a mano y, de nuevo, un vector de desincronización: si
  tu intermediario cuenta distinto que el siguiente, estás en el escenario de la pregunta 18.

**02 → 20.** **Si HTTP/2 es binario y HTTP/1.1 es texto, ¿por qué se dice que son el mismo protocolo? 🟠**

- ⏱️ Porque comparten la semántica —métodos, códigos, encabezados— y solo cambian la codificación.
- 🗣️ Esa separación está materializada en los documentos: RFC 9110 define qué significan las cosas, y
  9112, 9113 y 9114 definen cómo se escriben en el cable para cada versión. Un `GET` que devuelve
  `404` significa lo mismo en las tres.
- 🔬 Se comprueba a diario: `curl --http2` muestra los mismos encabezados que `curl --http1.1` porque
  los está descomprimiendo de HPACK para enseñártelos. Lo que cambia por debajo es que van indexados
  y en tramas, no en líneas de texto.

**02 → 21.** **¿Qué son los pseudo-campos de HTTP/2 y qué pasó con `Host`? 🟠**

- ⏱️ Son campos con nombre que empieza por dos puntos —`:method`, `:path`, `:scheme`,
  `:authority`— que sustituyen a la línea de inicio, y `:authority` ocupa el lugar de `Host`.
- 🗣️ En HTTP/2 no hay línea de petición ni de estado: todo son campos, así que la información que
  antes iba en la primera línea tuvo que convertirse en campos también, y se distinguen con el
  prefijo para que no colisionen con los normales.
- 🔬 Van obligatoriamente al principio de la sección y en minúscula. Un gateway que traduzca de
  HTTP/2 a HTTP/1.1 reconstruye la línea de inicio a partir de ellos — y ahí, de nuevo, hay
  oportunidades de discrepancia que las implementaciones tienen que cerrar con cuidado.

**02 → 22.** **Compara texto y binario como formato de protocolo. ¿Cuál es el coste real del texto? 🟠**

- ⏱️ El texto se depura a ojo y evoluciona fácil; el binario es compacto y determinista. El coste real
  del texto no es el tamaño: es la ambigüedad de parseo.
- 🗣️ El tamaño se arregla comprimiendo. Lo que no se arregla es que dos implementaciones puedan leer
  el mismo texto de dos formas: espacios donde no debería haberlos, encabezados repetidos,
  continuaciones de línea, longitudes contradictorias. Cada una de esas libertades ha producido una
  vulnerabilidad con nombre propio.
- 🔬 Ese es el argumento de fondo de HTTP/2, más que la velocidad: un formato con longitudes
  explícitas y tramas no admite esa clase de discrepancia. A cambio se pierde poder abrir un socket
  con `nc` y escribir la petición a mano, que es exactamente lo que hace este capítulo.

**02 → 23.** **Una respuesta se sirve en el idioma equivocado al 50 % de los usuarios y solo detrás del CDN. Diagnostica. 🔴**

- ⏱️ Falta `Vary: Accept-Language`: el CDN cachea la primera variante que ve y se la sirve a todos.
- 🗣️ Encaja con los tres síntomas: solo detrás del CDN —porque la caché compartida es la que mezcla—,
  a la mitad de los usuarios —los que caen en un nodo que guardó la variante equivocada— e
  intermitente, porque depende de qué petición llenó cada nodo primero.
- 🔬 La confirmación es directa: pedir el recurso con `Accept-Language` distinto y comparar; y mirar
  si la respuesta trae `Vary`. La corrección son tres cosas, no una: añadir `Vary: Accept-Language`,
  purgar la caché del CDN —si no, el contenido malo sigue vivo hasta que caduque— y revisar si otras
  respuestas negocian por `Accept`, `Accept-Encoding` o `Authorization` sin declararlo. Esta última
  es la peor de todas: una respuesta que depende de `Authorization` y no lo declara puede acabar
  sirviendo los datos de un usuario a otro.

**02 → 24.** **Diseñas un parser HTTP/1.1 desde cero. Enumera las cinco decisiones donde una lectura laxa se convierte en vulnerabilidad. 🔴**

- ⏱️ Framing contradictorio, espacios en los nombres de campo, `obs-fold`, terminadores de línea y
  `Content-Length` no numérico o repetido.
- 🗣️ Las cinco, con la decisión correcta:

  ```text
  1. Content-Length y Transfer-Encoding a la vez → rechazar, o Transfer-Encoding y CERRAR
  2. Espacio antes de los dos puntos            → 400, sin excepciones
  3. obs-fold (continuación indentada)           → 400 en peticiones; deprecado
  4. CR o LF sueltos como fin de línea           → no aceptarlos como CRLF
  5. Content-Length repetido o con signo/espacios → rechazar, nunca "coger el primero"
  ```
- 🔬 El principio común es que **ante lo ambiguo se rechaza, no se adivina**: cada vez que un parser
  elige una interpretación "razonable" en lugar de fallar, crea la posibilidad de que el siguiente
  salto elija la otra. Y el segundo principio es normalizar en el borde: el frontal reescribe el
  mensaje en forma canónica antes de reenviarlo, para que el origen no vuelva a decidir.

**02 → 25.** **Escribe a mano el intercambio completo —petición y respuesta— de una subida `PUT` de 348 octetos con su framing, y señala cada línea que la norma hace obligatoria. 🔴**

- ⏱️ `PUT` con `Host`, `Content-Type` y `Content-Length: 348`; respuesta `204` sin cuerpo.
- 🗣️ El intercambio:

  ```text
  > PUT /pedidos/PED-00042 HTTP/1.1
  > Host: api.ejemplo.com              ← MUST en HTTP/1.1
  > Content-Type: application/json     ← sin esto el cuerpo es indescifrable
  > Content-Length: 348                ← framing: sin él o sin chunked, no hay cuerpo válido
  >
  > {…348 octetos…}

  < HTTP/1.1 204 No Content
  < Date: Fri, 18 Sep 2026 02:22:22 GMT
  < ETag: "a3f9c1"                     ← opcional, y lo que permite If-Match después
  ```
- 🔬 Qué obliga qué: `Host` es `MUST` (RFC 9112 §3.2); el framing es obligatorio en cuanto hay cuerpo,
  con uno de los dos mecanismos y no los dos; `204` **no puede llevar cuerpo**, así que no lleva
  `Content-Length` ni `chunked`. `Content-Type` no es formalmente obligatorio, pero omitirlo deja al
  servidor adivinando, y adivinar el tipo es otra fuente conocida de vulnerabilidades.

**02 → 26.** **Un `400` aparece solo detrás del CDN y nunca llega a los logs de la aplicación. Da tres hipótesis ordenadas por probabilidad y cómo descartarías cada una. 🔴**

- ⏱️ Lo está generando el propio borde al parsear, así que nunca llega a la aplicación: sintaxis de
  encabezados, tamaño o framing.
- 🗣️ Las tres, en orden:

  ```text
  1. Sintaxis de un encabezado          espacio antes de ':', carácter ilegal, obs-fold
  2. Límite del borde superado           encabezado o URL más largos de lo permitido (suele ser 8 KB)
  3. Framing contradictorio o inválido   los dos encabezados de longitud, o chunked mal formado
  ```
- 🔬 Cómo se distinguen: reproducir la petición cruda con `curl --trace-ascii -` o con `nc` para ver
  los bytes exactos, e ir recortando encabezados hasta que deje de fallar —la bisección encuentra al
  culpable en cinco intentos—. Para la segunda, medir el tamaño total de la sección de campos, que es
  el sospechoso cuando el fallo aparece solo con algunos usuarios: la cookie larga es el caso más
  común. Y el dato que orienta desde el principio: **si la aplicación no lo ve, no es de la
  aplicación**; buscar en sus logs es perder la primera media hora.

**02 → 27.** **Defines el contrato de un endpoint que devuelve CSV o JSON según el cliente. Escribe los encabezados exactos de petición y respuesta, incluido lo que evita el bug de caché. 🔴**

- ⏱️ El cliente manda `Accept`, el servidor responde con `Content-Type` y, obligatoriamente,
  `Vary: Accept`.
- 🗣️ El contrato:

  ```text
  > GET /pedidos/informe HTTP/1.1
  > Host: api.ejemplo.com
  > Accept: text/csv;q=1.0, application/json;q=0.8

  < HTTP/1.1 200 OK
  < Content-Type: text/csv; charset=utf-8
  < Vary: Accept                                  ← sin esto, la caché mezcla variantes
  < Cache-Control: private, max-age=60
  < Content-Disposition: attachment; filename="informe.csv"
  ```
- 🔬 Tres decisiones que conviene justificar: `Vary: Accept` es lo que evita que un cliente reciba CSV
  cuando pidió JSON; el `charset` **sí** es pertinente aquí —a diferencia de JSON, donde es
  redundante—, porque el CSV no lleva codificación declarada por dentro y es donde se rompen los
  acentos; y `Content-Disposition` fuerza la descarga con nombre (RFC 6266). Si el cliente pide algo
  que no sabemos servir, la respuesta correcta es `406 Not Acceptable`, no devolver JSON por defecto.

---

## Capítulo 03 — Métodos, semántica e idempotencia

**03 → 1.** **¿Qué significa que un método sea seguro? 🟢**

- ⏱️ Que su semántica es esencialmente de solo lectura: el cliente no pide ni espera ningún cambio de
  estado en el servidor.
- 🗣️ Es lo que permite que un rastreador siga todos los enlaces y que un navegador precargue páginas
  sin miedo a provocar algo. `GET`, `HEAD`, `OPTIONS` y `TRACE` son seguros.
- 🔬 RFC 9110 §9.2.1 aclara que **puede haber efectos**: escribir en un log, calentar una caché,
  incluso —su propio ejemplo— cargar un anuncio a una cuenta publicitaria. Lo que define lo seguro es
  que el cliente no pidió ese efecto y no responde de él.

**03 → 2.** **¿Qué significa que un método sea idempotente? 🟢**

- ⏱️ Que el efecto de N peticiones idénticas es el mismo que el de una sola.
- 🗣️ Es la propiedad que hace que un reintento sea seguro, y por eso los clientes y los proxies
  reintentan automáticamente los métodos idempotentes y no los demás.
- 🔬 Es una propiedad del **efecto en el servidor**, no de la respuesta: dos peticiones idempotentes
  pueden devolver códigos distintos y seguir siéndolo.

**03 → 3.** **¿Qué métodos son seguros según RFC 9110? 🟢**

- ⏱️ `GET`, `HEAD`, `OPTIONS` y `TRACE`.
- 🗣️ Y todos ellos son además idempotentes, porque lo seguro está contenido en lo idempotente: si no
  cambias nada, repetirlo tampoco cambia nada.
- 🔬 Lo dice literalmente §9.2.1: *"Of the request methods defined by this specification, the GET,
  HEAD, OPTIONS, and TRACE methods are defined to be safe"*.

**03 → 4.** **¿Qué métodos son idempotentes según RFC 9110? 🟢**

- ⏱️ `PUT`, `DELETE` y los métodos seguros.
- 🗣️ Esa frase es literal de §9.2.2 y es la cita que zanja la discusión más frecuente sobre HTTP.
  `POST` y `PATCH` quedan fuera.
- 🔬 `PATCH` ni siquiera aparece en esa lista porque no se define en RFC 9110: está en RFC 5789.

**03 → 5.** **¿`POST` es idempotente? 🟢**

- ⏱️ No, y ese es precisamente su papel: es el método sin promesas.
- 🗣️ Por eso sirve para operaciones que no son "poner un estado": un pago, un envío, una importación,
  una búsqueda con cuerpo. Y por eso ningún intermediario debe reintentarlo por su cuenta.
- 🔬 Que no sea idempotente **por definición** no impide que una operación `POST` concreta lo sea por
  diseño: es exactamente lo que consigue una clave de idempotencia.

**03 → 6.** **¿Qué método usas para sustituir un recurso entero? 🟢**

- ⏱️ `PUT`, con el estado completo en el cuerpo y en la URI que el cliente conoce.
- 🗣️ Su semántica es "el estado de este recurso pasa a ser exactamente esto", y de ahí sale su
  idempotencia: mandarlo diez veces deja el mismo estado.
- 🔬 Si solo mandas unos campos con `PUT`, estás diciendo que el recurso pasa a tener **solo** esos
  campos. Es un error frecuente y silencioso: borra datos sin que nadie lo pida.

**03 → 7.** **¿Qué devuelve un `PUT` sobre una URI que no existía? 🟢**

- ⏱️ `201 Created` si lo creó, `200` o `204` si lo sustituyó.
- 🗣️ Sí: **`PUT` puede crear**. La idea de que "`POST` crea y `PUT` actualiza" es folclore, no norma.
- 🔬 La diferencia real con `POST` no es crear o no, sino **quién elige la URI**: con `PUT` la elige
  el cliente; con `POST` la asigna el servidor y la devuelve en `Location`.

**03 → 8.** **¿Qué es REST y quién lo definió? 🟢**

- ⏱️ Un estilo arquitectónico definido por Roy Fielding en su tesis doctoral de 2000. No es un RFC ni
  un estándar.
- 🗣️ Son seis restricciones: cliente-servidor, sin estado, cacheable, interfaz uniforme, sistema por
  capas y código bajo demanda (opcional). No dice nada sobre JSON ni sobre cómo se nombran las URLs.
- 🔬 Fielding participó además en los RFC de HTTP, lo que explica que REST y HTTP encajen tan bien:
  HTTP es, en buena medida, la instancia de referencia del estilo.

**03 → 9.** **¿Por qué "seguro" no es lo mismo que "sin efectos secundarios"? 🟡**

- ⏱️ Porque lo que importa es quién pidió el efecto, no si existe.
- 🗣️ Todo servidor escribe en un log con cada petición, y eso no deja de ser seguro. La norma incluso
  admite el caso de un `GET` que cobra a un anunciante: el cliente no pidió el cobro y no es
  responsable de él.
- 🔬 El límite lo pone la propia §9.2.1: si el propósito del recurso **es** ejecutar una acción
  insegura, el dueño **MUST** impedir que se dispare con un método seguro. Es decir, los efectos
  incidentales están permitidos; disfrazar una acción de lectura no lo está.

**03 → 10.** **¿Por qué `DELETE` es idempotente si la segunda llamada devuelve `404`? 🟡**

- ⏱️ Porque la idempotencia es del efecto, no de la respuesta: tras la segunda llamada el recurso
  sigue sin existir, que es el mismo estado.
- 🗣️ Es la confusión más común con esta propiedad. Un cliente que reintenta un `DELETE` tras un
  timeout y recibe `404` ha conseguido exactamente lo que quería.
- 🔬 De ahí una recomendación de diseño: un cliente robusto trata `404` en un reintento de `DELETE`
  como éxito, no como error. Y si el contrato lo permite, devolver `204` siempre simplifica la vida a
  todo el mundo.

**03 → 11.** **¿Cuándo usas `POST` y cuándo `PUT` para crear? 🟡**

- ⏱️ `PUT` si el cliente conoce o elige la URI; `POST` si la asigna el servidor.
- 🗣️ Con un identificador natural —un número de pedido que viene del negocio, un DNI, una clave
  idempotente generada por el cliente— `PUT /pedidos/PED-00042` es mejor: es idempotente y el
  reintento es gratis. Con un identificador generado por la base de datos, es `POST /pedidos` y la
  respuesta lleva `201` con `Location`.
- 🔬 Este es el argumento decisivo y casi nadie lo usa: **elegir `PUT` porque el cliente genere el
  identificador convierte la creación en una operación reintentable**, y eso elimina de raíz los
  duplicados por timeout.

**03 → 12.** **¿Qué formatos de parche existen y qué `Content-Type` llevan? 🟡**

- ⏱️ JSON Patch (`application/json-patch+json`, RFC 6902) y JSON Merge Patch
  (`application/merge-patch+json`, RFC 7396).
- 🗣️ JSON Patch es una lista de operaciones —`add`, `remove`, `replace`, `move`, `copy`, `test`—;
  Merge Patch es un documento parcial que se fusiona con el recurso, y es el que casi todo el mundo
  usa sin saber que tiene nombre y norma.
- 🔬 El error habitual no es elegir mal: es **no declarar el tipo**. Mandar un `PATCH` con
  `Content-Type: application/json` deja al servidor adivinando qué semántica aplicar, y por eso cada
  API se lo inventa.

**03 → 13.** **¿Qué hace un `null` en JSON Merge Patch? 🟡**

- ⏱️ **Borra el campo.** No lo pone a nulo.
- 🗣️ Consecuencia directa y muy poco conocida: con Merge Patch **es imposible asignar el valor
  `null`** a un campo, porque esa sintaxis ya está ocupada por el borrado.
- 🔬 Si tu dominio distingue "sin valor" de "no tocar" —un descuento que puede ser explícitamente
  nulo, una fecha de baja— Merge Patch no te sirve y necesitas JSON Patch, donde `replace` con valor
  `null` y `remove` son operaciones distintas.

**03 → 14.** **¿Es cacheable `POST`? 🟡**

- ⏱️ Sí, si la respuesta lleva información explícita de frescura. Pero casi nadie lo usa.
- 🗣️ Es el único método donde la cacheabilidad depende de la respuesta y no del método: `GET` y `HEAD`
  son cacheables por defecto, `POST` solo si se declara.
- 🔬 Tiene un caso de uso real: una búsqueda compleja que va por `POST` porque los criterios no caben
  en la URL. Aun así, lo habitual es que las cachés intermedias no lo implementen bien, así que en la
  práctica se prefiere `GET` con query o un recurso de búsqueda creado con `POST` y leído con `GET`.

**03 → 15.** **¿Qué es el modelo de madurez de Richardson y en qué nivel vive la industria? 🟡**

- ⏱️ Una escala de cuatro niveles: 0 un endpoint tipo RPC, 1 recursos, 2 verbos y códigos con su
  semántica, 3 hipermedia. **La industria vive en el 2.**
- 🗣️ Sirve para hablar de esto sin discutir de ortodoxia: en vez de "esto no es REST", se dice "esto
  es nivel 2, y está bien porque nuestros clientes son nuestros y el coste del 3 no compensa".
- 🔬 El nivel 3 es lo que Fielding considera obligatorio para llamarlo REST, y por eso dijo
  públicamente que casi ninguna API llamada REST lo es. Lo que la industria hace es **HTTP bien
  usado**, que ya es mucho más de lo que hace la media.

**03 → 16.** **¿Qué restricción de REST es la que más cuesta cumplir y por qué? 🟡**

- ⏱️ La de no tener estado: cada petición debe llevar todo lo necesario, sin que el servidor guarde
  contexto de sesión.
- 🗣️ Es la que permite escalar horizontalmente sin sesiones pegajosas y la que se rompe en cuanto
  alguien guarda un dato en la sesión del servidor "porque es más cómodo". A partir de ahí hace falta
  afinidad de sesión, y la elasticidad se acabó.
- 🔬 Cumplirla no significa que no haya estado, sino que **el estado de sesión vive en el cliente o en
  un almacén compartido**, no en la memoria de la instancia que atendió la petición anterior.

**03 → 17.** **¿Es `PATCH` idempotente? Responde completo. 🟠**

- ⏱️ No por definición, pero un `PATCH` concreto puede serlo según el formato y el contenido del
  parche.
- 🗣️ `{"estado":"PAGADO"}` en Merge Patch sí lo es: aplicarlo diez veces deja el mismo estado. Una
  operación `add` de JSON Patch sobre un array **no** lo es: cada aplicación añade otro elemento.
- 🔬 Y la consecuencia práctica, que es lo que importa: como la norma no lo garantiza, **ningún
  intermediario debe reintentar un `PATCH`**, y si tu cliente lo hace, la seguridad tiene que venir
  de tu diseño. Si quieres la garantía en el contrato, la das con `If-Match` y un `ETag`, o con una
  clave de idempotencia.

**03 → 18.** **Un cliente hace `POST /pagos`, el servidor cobra y la respuesta se pierde. ¿Qué debe hacer el cliente? 🟠**

- ⏱️ No puede saber si cobró, así que reintentar es peligroso y no reintentar también: la solución
  está en el contrato, no en el cliente.
- 🗣️ El cliente no puede distinguir "no llegó" de "llegó y se perdió la respuesta" — es el problema
  de los dos generales, y no se resuelve con más reintentos. Lo correcto es que la operación admita
  reintento: reintentar **con la misma clave de idempotencia**, o consultar el estado del pago por un
  identificador que el cliente generó antes de empezar.
- 🔬 Si el contrato no previó nada de eso, la única salida honesta es un proceso de conciliación
  posterior: buscar por referencia externa y anular el duplicado. Es caro, manual y evitable, y por
  eso el diseño del contrato es donde se resuelve.

**03 → 19.** **¿Qué garantiza y qué **no** garantiza una clave de idempotencia? 🟠**

- ⏱️ Garantiza que el mismo intento lógico no se ejecute dos veces; no garantiza atomicidad, ni
  duración, ni qué hacer ante conflictos.
- 🗣️ Los tres huecos: si el servidor cae **entre** ejecutar y guardar la clave, el reintento vuelve a
  ejecutar —hacen falta ambas cosas en la misma transacción, o un diseño en dos fases—; una clave que
  caduca a la hora no cubre a un cliente que reintenta al día siguiente; y si llega la misma clave con
  un cuerpo distinto, la norma no dice nada.
- 🔬 Para lo último, lo correcto es **rechazar** con `409` o `422`, nunca reejecutar ni devolver la
  respuesta antigua como si nada. Y todo esto va escrito en el contrato, porque `Idempotency-Key` es
  una convención de industria —hoy un borrador del IETF—, no un RFC que lo defina.

**03 → 20.** **Diferencia at-most-once, at-least-once y exactly-once. ¿Cuál es alcanzable? 🟠**

- ⏱️ At-most-once: cero o una vez, sin reintentos. At-least-once: una o más, con reintentos.
  Exactly-once no es alcanzable sobre una red que pierde mensajes.
- 🗣️ Lo que sí se consigue es **at-least-once más una operación idempotente**, y el resultado
  *observable* es el de exactly-once. Esa distinción entre garantía de entrega y efecto observado es
  la respuesta completa.
- 🔬 Decirlo así en una entrevista vale más que cualquier diagrama, porque es exactamente lo que
  hacen los sistemas de mensajería que anuncian "exactly-once": reintento más deduplicación por
  clave, dentro de un ámbito acotado.

**03 → 21.** **Un balanceador reintenta peticiones automáticamente. ¿Qué métodos puede reintentar sin riesgo y por qué? 🟠**

- ⏱️ Los idempotentes: `GET`, `HEAD`, `OPTIONS`, `TRACE`, `PUT` y `DELETE`. Nunca `POST` ni `PATCH`.
- 🗣️ El razonamiento es literal: reintentar es seguro exactamente cuando repetir no cambia el efecto,
  que es la definición de idempotente. Y hay un matiz que distingue: reintentar es seguro si el fallo
  fue **antes** de que la petición llegara; si fue un timeout, el balanceador tampoco sabe si se
  ejecutó, así que se apoya en la propiedad del método.
- 🔬 Configurar un balanceador para reintentar `POST` es una causa habitual y difícil de rastrear de
  duplicados en producción: los logs de la aplicación muestran dos peticiones idénticas y nadie mira
  al balanceador.

**03 → 22.** **Tu dominio distingue "poner a nulo" de "no tocar". ¿Qué formato de parche eliges? 🟠**

- ⏱️ JSON Patch (RFC 6902), porque Merge Patch no puede expresar "asigna `null`".
- 🗣️ En Merge Patch, `{"descuento": null}` borra el campo, y omitirlo significa no tocarlo: no queda
  ninguna sintaxis libre para asignar el valor nulo. JSON Patch sí la tiene, porque `replace` con
  valor `null` y `remove` son operaciones distintas y explícitas.
- 🔬 La alternativa, si el cliente es tuyo y quieres la simplicidad de Merge Patch, es modelar el
  dominio para que el nulo no haga falta: un campo `tieneDescuento` explícito, o un valor centinela
  documentado. Lo que no vale es usar Merge Patch y confiar en que nadie necesite nunca poner nulo.

**03 → 23.** **¿Cuándo dirías que una API **no** debería ser REST? 🟠**

- ⏱️ Cuando el dominio es de procedimientos y no de recursos, cuando el coste por llamada domina, o
  cuando el cliente necesita componer la consulta.
- 🗣️ Tres casos concretos: una operación como "recalcular el riesgo de la cartera" no es un recurso y
  forzarle un sustantivo es peor que llamarlo por su nombre —ahí RPC o gRPC es más honesto—;
  comunicación interna de alto volumen, donde un formato binario con contrato y multiplexación paga
  su complejidad; y un cliente que necesita pedir campos distintos en cada pantalla, que es el caso
  de GraphQL.
- 🔬 Decir esto en una entrevista demuestra criterio, siempre que vaya con el reverso: para una API
  pública, con clientes que no controlas y que tienen que entenderla sin preguntarte, REST sobre HTTP
  sigue siendo la opción por defecto, y el motivo es la infraestructura —cachés, proxies,
  herramientas— que ya la entiende.

**03 → 24.** **Rediseña `POST /pedidos/{id}/avanzar-estado` para que sea idempotente, sin perder funcionalidad. 🔴**

- ⏱️ Sustituir la orden relativa por una absoluta: `PUT /pedidos/{id}/estado` con el estado destino.
- 🗣️ El contrato:

  ```text
  PUT /pedidos/PED-00042/estado
  If-Match: "a3f9c1"
  Content-Type: application/json

  {"estado": "ENVIADO", "estadoAnterior": "EN_PREPARACION"}
  ```
  Aplicarlo diez veces deja el pedido en `ENVIADO`, que es el mismo estado: idempotente por
  construcción.
- 🔬 Dos refuerzos y su porqué. `If-Match` con el `ETag` da control de concurrencia optimista: si otro
  cambió el pedido entre tu lectura y tu escritura, recibes `412` en vez de pisar el cambio.
  `estadoAnterior` convierte la operación en una transición verificable: si el pedido ya está en
  `ENTREGADO`, el servidor responde `409 Conflict` en vez de retroceder. Lo que se pierde respecto al
  original es la comodidad de no tener que saber el estado actual — y eso, en un flujo con varios
  actores, no es una pérdida: es la comprobación que faltaba.

**03 → 25.** **Diseña el contrato completo de un endpoint de cobro seguro ante reintentos: método, clave, atomicidad, caducidad y qué hacer si llega la misma clave con otro cuerpo. 🔴**

- ⏱️ `POST` con `Idempotency-Key` generada por el cliente, clave y efecto en la misma transacción,
  caducidad declarada y `409` ante conflicto de cuerpo.
- 🗣️ El contrato, punto por punto:

  ```text
  POST /pagos
  Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000   ← UUID por INTENTO LÓGICO, no por reintento
  Content-Type: application/json

  201 Created        primera ejecución
  200 OK             repetición: se devuelve la MISMA respuesta guardada
  409 Conflict       misma clave, cuerpo distinto
  422                clave ausente cuando es obligatoria
  ```
- 🔬 Las cuatro decisiones difíciles y cómo se resuelven: **(1) atomicidad** — la clave, su respuesta
  y el efecto del cobro se guardan en la misma transacción; si no se puede, un registro de intención
  antes de cobrar y reconciliación después. **(2) caducidad** — 24 horas es el valor habitual, y se
  documenta: pasada la ventana la clave se olvida y un reintento vuelve a cobrar, así que el cliente
  tiene que saberlo. **(3) huella del cuerpo** — se guarda un hash de la petición junto con la clave;
  es lo que permite detectar el conflicto sin almacenar el cuerpo entero. **(4) concurrencia** — dos
  peticiones con la misma clave a la vez: la segunda espera o recibe `409`, y para eso hace falta un
  bloqueo o una restricción de unicidad en la tabla de claves. Ese último punto es el que casi todas
  las implementaciones caseras olvidan.

**03 → 26.** **Un rastreador borró cuatrocientos registros. Explica la causa raíz citando la norma y enumera las tres correcciones, ordenadas por eficacia. 🔴**

- ⏱️ Había una acción destructiva accesible por `GET`, que es un método seguro y que por tanto
  cualquier rastreador ejecuta por diseño.
- 🗣️ La norma lo previó literalmente: RFC 9110 §9.2.1 advierte del patrón `page?do=delete` y dice que
  si el propósito del recurso es una acción insegura, el dueño **MUST** impedir que se ejecute con un
  método seguro. No fue mala suerte: fue incumplir un `MUST`.
- 🔬 Las tres correcciones, de más a menos eficaz: **(1)** cambiar el contrato para que el borrado
  solo responda a `DELETE` —ataja la causa y arregla también al navegador que precarga y al antivirus
  corporativo que sigue enlaces—; **(2)** exigir autenticación y autorización en el panel, que habría
  evitado **este** incidente pero no el de un usuario legítimo cuyo navegador precargue; **(3)**
  `robots.txt` y `nofollow`, que es lo que mucha gente propone primero y es lo más débil de todo:
  depende de que el cliente coopere, y un rastreador que no lo haga, o un prefetch del navegador,
  vuelve a borrarlo todo. El orden de esta lista es la respuesta.

**03 → 27.** **Un balanceador reintenta `POST` por configuración heredada y aparecen duplicados en producción. Escribe el plan de corrección en tres frentes: inmediato, de contrato y de diseño. 🔴**

- ⏱️ Inmediato: quitar el reintento de `POST` en el balanceador. Contrato: clave de idempotencia.
  Diseño: convertir en idempotentes las operaciones que puedan serlo.
- 🗣️ El plan:

  ```text
  INMEDIATO (hoy)      reintentos solo para métodos idempotentes; medir cuántos duplicados hubo
  CONTRATO (semanas)   Idempotency-Key obligatoria en las operaciones con efecto económico
  DISEÑO (trimestre)   PUT con identificador del cliente donde el dominio lo permita
  ```
- 🔬 Y lo que no se omite: **hay que limpiar lo ya duplicado**, que es trabajo de conciliación con el
  negocio y no de ingeniería, y hay que **medir el alcance antes de anunciar nada** — buscando
  peticiones idénticas separadas por el timeout del balanceador. El detalle que hace al plan
  defendible es el orden: el frente inmediato para de sangrar en horas, y los otros dos eliminan la
  clase de fallo. Arreglar solo el balanceador deja el sistema a merced del siguiente reintento, venga
  de donde venga.

**03 → 28.** **Escribe el contrato completo de la operación "cambiar el estado de un pedido" en sus dos versiones —idempotente y no idempotente— y argumenta cuál defenderías ante el equipo. 🔴**

- ⏱️ La idempotente pone el estado destino con `PUT`; la otra ordena una transición con `POST`.
  Defiendo la primera salvo que el dominio exija registrar cada intento.
- 🗣️ Las dos:

  ```text
  IDEMPOTENTE
  PUT /pedidos/PED-00042/estado        {"estado":"ENVIADO"}      → 200/204, repetible
  NO IDEMPOTENTE
  POST /pedidos/PED-00042/transiciones {"accion":"ENVIAR"}       → 201 + Location de la transición
  ```
- 🔬 El argumento a favor de la primera: el reintento es gratis, que es la propiedad más valiosa en
  una API con red de por medio. El argumento a favor de la segunda, que hay que conceder: **modela la
  transición como un recurso**, así que queda registrada con su fecha, su autor y su motivo — y en un
  dominio auditado, como la banca, eso no es opcional. La síntesis que yo defendería: `PUT` del estado
  como operación pública, y el histórico de transiciones como recurso de solo lectura derivado de
  ella. Se obtiene la idempotencia y la trazabilidad, sin pedirle al cliente que cargue con las dos.

---

## Capítulo 04 — Codificación y formatos

**04 → 1.** **¿Qué es un tipo de medio y qué partes tiene? 🟢**

- ⏱️ La etiqueta que dice qué es un cuerpo: tipo, subtipo y parámetros opcionales, como
  `application/json; charset=utf-8`.
- 🗣️ Es lo que convierte una ristra de octetos en un documento parseable, y por eso `Content-Type` es
  funcionalmente el encabezado más importante del cuerpo.
- 🔬 Se le sigue llamando "tipo MIME" por su origen en el correo electrónico, pero el nombre actual en
  la norma es **tipo de medio** (*media type*). El tipo, el subtipo y los nombres de parámetro no
  distinguen mayúsculas.

**04 → 2.** **¿Quién mantiene el catálogo de tipos de medio? 🟢**

- ⏱️ IANA. El RFC define el mecanismo; el registro contiene los tipos concretos.
- 🗣️ Por eso, para saber si `application/problem+json` existe o cómo se llama el tipo de un formato
  concreto, se mira el registro y no un RFC.
- 🔬 El procedimiento de registro está en RFC 6838, que también define el árbol `vnd.` para tipos de
  una organización y los sufijos estructurados como `+json` y `+xml`.

**04 → 3.** **¿Qué es Base64 y para qué sirve? 🟢**

- ⏱️ Una codificación que representa octetos arbitrarios con un alfabeto de 64 caracteres seguros
  para canales de texto.
- 🗣️ Nació con MIME, porque el correo de los ochenta era de 7 bits y no dejaba pasar binarios. Hoy se
  usa para meter binarios pequeños dentro de documentos de texto: un JWT, un certificado PEM, una
  imagen en un `data:` URI, una firma dentro de un JSON.
- 🔬 El alfabeto son `A–Z`, `a–z`, `0–9` y dos símbolos —`+` y `/`, o `-` y `_` en la variante
  URL-safe—, más `=` como relleno. Está en RFC 4648.

**04 → 4.** **¿Cuánto infla Base64 y por qué exactamente ese número? 🟢**

- ⏱️ Un **33 %**: cada 3 octetos se convierten en 4 caracteres.
- 🗣️ La aritmética es la explicación entera: 3 octetos son 24 bits, que se reparten en 4 grupos de 6
  bits, y cada grupo es un carácter del alfabeto de 64. De ahí la proporción 4/3.
- 🔬 Medido: 3 000 octetos aleatorios producen exactamente 4 000 caracteres. Y hay un pequeño extra
  que se olvida — el relleno `=` y, si se parte en líneas, los saltos.

**04 → 5.** **¿Es Base64 una medida de seguridad? 🟢**

- ⏱️ No. Es una codificación reversible sin clave: cualquiera la deshace.
- 🗣️ El caso que lo ilustra es HTTP Basic: la credencial va en Base64 del usuario y la contraseña, y
  eso es texto plano a efectos prácticos. Solo tiene sentido dentro de TLS.
- 🔬 Confundir codificar con cifrar es de las respuestas que descartan a un candidato senior, porque
  sugiere que podría tomar la misma decisión con datos reales.

**04 → 6.** **¿Qué es `multipart/form-data` y para qué se usa? 🟢**

- ⏱️ Un cuerpo que contiene varios cuerpos, cada uno con sus propios encabezados, separados por una
  frontera.
- 🗣️ Es la forma estándar de enviar campos de texto y archivos binarios en la misma petición, y su
  ventaja frente a Base64 es que **el binario viaja tal cual**, sin sobrecoste, con su propio
  `Content-Type` declarado por parte.
- 🔬 Está definido en RFC 7578, y cada parte lleva `Content-Disposition: form-data; name="…"` y, si es
  un archivo, `filename="…"`.

**04 → 7.** **¿Qué encabezado fuerza la descarga de un archivo en el navegador? 🟢**

- ⏱️ `Content-Disposition: attachment; filename="factura.pdf"`.
- 🗣️ Con `inline` —o sin el encabezado— el navegador intenta mostrarlo; con `attachment` abre el
  diálogo de guardar. Es la forma correcta de servir una exportación.
- 🔬 Está en RFC 6266, que además define cómo enviar un nombre con caracteres no ASCII mediante el
  parámetro `filename*`, porque `filename` a secas no los admite de forma interoperable.

**04 → 8.** **¿Qué codificación de caracteres exige JSON? 🟢**

- ⏱️ UTF-8. Lo obliga RFC 8259 para el JSON intercambiado entre sistemas.
- 🗣️ Por eso declarar `charset=utf-8` en `application/json` es redundante, y declarar cualquier otra
  cosa es declarar algo que la norma no permite.
- 🔬 La norma admite otras codificaciones Unicode solo en entornos cerrados; en cuanto el documento
  cruza de un sistema a otro, es UTF-8.

**04 → 9.** **¿Qué significa el sufijo `+json` en un tipo de medio propio? 🟡**

- ⏱️ Que el documento se parsea como JSON aunque el cliente no conozca el tipo concreto.
- 🗣️ `application/vnd.ejemplo.pedido+json` le dice a cualquier herramienta genérica —un proxy, un
  navegador, una biblioteca— que puede tratarlo como JSON. Sin el sufijo, todos lo tratan como opaco.
- 🔬 Es lo mismo que hace `application/problem+json`, y es la diferencia entre inventar un tipo que
  funciona con el ecosistema e inventar uno que obliga a todos a conocerte.

**04 → 10.** **¿Para qué sirve el árbol `vnd.`? 🟡**

- ⏱️ Es el espacio de nombres para tipos de medio de una organización o producto.
- 🗣️ `application/vnd.ejemplo.pedido+json` deja claro de quién es el formato y evita chocar con un
  tipo estándar futuro. La alternativa mala es inventar `application/pedido`, que ocupa un nombre del
  árbol común sin ningún derecho.
- 🔬 Hay también un árbol `prs.` para tipos personales y uno `x.` para no registrados —que arrastra el
  mismo problema que el prefijo `X-` de los encabezados—. El procedimiento está en RFC 6838.

**04 → 11.** **¿Qué son los valores `q` en `Accept` y qué pasa si se omiten? 🟡**

- ⏱️ Un factor de calidad entre 0 y 1 que expresa preferencia relativa. Si se omite, vale 1.
- 🗣️ `Accept: text/csv;q=1.0, application/json;q=0.8` dice "prefiero CSV, me vale JSON". Es una
  preferencia, no una orden: el servidor puede servir otra cosa o responder `406 Not Acceptable`.
- 🔬 El mismo mecanismo vale para `Accept-Language` y `Accept-Encoding`, y ahí aparece el patrón útil
  `es-CO, es;q=0.8, en;q=0.5`: variante regional preferida, idioma general aceptable, inglés como
  último recurso.

**04 → 12.** **¿Qué hay que añadir a una respuesta negociada para no romper las cachés? 🟡**

- ⏱️ `Vary`, con los encabezados de los que depende la respuesta.
- 🗣️ Si varía por idioma, `Vary: Accept-Language`; por formato, `Vary: Accept`; por compresión,
  `Vary: Accept-Encoding`. Sin eso, una caché compartida guarda una variante y se la da a todos.
- 🔬 El caso peligroso, no solo molesto, es depender de `Authorization` sin declararlo: la caché
  puede acabar sirviendo la respuesta de un usuario a otro. Ahí la respuesta correcta suele ser
  `Cache-Control: private` o `no-store`, además del `Vary`.

**04 → 13.** **¿Cómo funciona la frontera de un `multipart` y quién la elige? 🟡**

- ⏱️ La elige el cliente, se declara como parámetro `boundary` del `Content-Type`, y en el cuerpo se
  usa precedida de dos guiones; la última lleva además dos guiones al final.
- 🗣️ Por eso la línea del cuerpo tiene dos guiones más que el valor del encabezado, que es lo que
  despista al mirar una captura por primera vez.
- 🔬 La condición crítica es que **no aparezca en ningún dato**: si apareciera, el cuerpo quedaría
  partido por la mitad. Por eso los clientes generan una parte aleatoria, y por eso una frontera
  nunca se escribe a mano.

**04 → 14.** **¿Qué riesgo tiene usar el `filename` de una parte para guardar el archivo? 🟡**

- ⏱️ Es entrada del usuario: puede contener `../` y escribir fuera del directorio previsto.
- 🗣️ Es el *path traversal* clásico de las subidas, y tiene variantes: nombres con caracteres nulos,
  nombres larguísimos, nombres que colisionan con archivos existentes, extensiones que el servidor
  web ejecuta.
- 🔬 La práctica correcta es generar el nombre en el servidor —un identificador propio—, guardar el
  original solo como metadato para mostrarlo, y no derivar nunca el tipo del archivo de su extensión.

**04 → 15.** **Diferencia codificación de caracteres y codificación porcentual. 🟡**

- ⏱️ La de caracteres va de texto a octetos —UTF-8, Latin-1—; la porcentual va de octetos a caracteres
  seguros dentro de una URI.
- 🗣️ Se aplican en cadena, y en ese orden: `ñ` se convierte primero a los octetos UTF-8 `C3 B1`, y
  esos octetos se escriben después como `%C3%B1`. Por eso un carácter produce dos grupos.
- 🔬 La porcentual está en RFC 3986 §2.5, y dice explícitamente que se codifica la representación en
  octetos, no el carácter. Confundir las dos es lo que produce los dobles codificados `%25C3%25B1`.

**04 → 16.** **¿Cuándo `+` significa espacio en una URL y cuándo no? 🟡**

- ⏱️ Solo dentro de `application/x-www-form-urlencoded`. En el resto de la URI es el carácter `+`.
- 🗣️ Esa asimetría rompe firmas de petición, filtros de búsqueda y direcciones de correo con
  etiqueta: `usuario+etiqueta@ejemplo.com` en una query puede llegar como `usuario etiqueta@…`.
- 🔬 La solución que no falla es codificar siempre el espacio como `%20` y el `+` literal como `%2B`,
  que es válido en ambos contextos.

**04 → 17.** **¿Por qué el fragmento `#…` no aparece en los logs del servidor? 🟡**

- ⏱️ Porque el cliente no lo envía: el fragmento se procesa enteramente en el cliente.
- 🗣️ Es parte de la URI pero no del *request-target*. El navegador lo usa para posicionarse en el
  documento o para enrutar en una aplicación de página única.
- 🔬 Tiene una consecuencia de seguridad conocida: poner un token en el fragmento evita que llegue a
  los logs del servidor —de ahí el flujo implícito de OAuth—, pero sigue quedando en el historial del
  navegador y accesible al JavaScript de la página.

**04 → 18.** **¿Recupera gzip el sobrecoste de Base64? Responde con datos. 🟠**

- ⏱️ Depende del dato: con contenido ya comprimido lo recupera casi entero; con contenido comprimible
  lo empeora mucho.
- 🗣️ Medido en el capítulo: 3 000 octetos aleatorios dan 3 031 comprimidos en crudo y 3 061
  comprimiendo el Base64 — un **1 %** de diferencia. Un texto de 18 622 octetos da 7 760 en crudo y
  11 071 pasando por Base64: **un 43 % más**.
- 🔬 La explicación es que Base64 desalinea los patrones respecto a los límites de octeto, así que el
  compresor deja de encontrarlos. Con datos incompresibles no había nada que encontrar y la pérdida
  no se nota. La conclusión práctica: para un JPEG o un PDF, el argumento del 33 % es casi falso en
  el cable; para un XML o un JSON embebido, es peor de lo que dice la regla.

**04 → 19.** **¿Cuál es el coste de Base64 que **no** se ve en el cable? 🟠**

- ⏱️ La memoria y la CPU: codificar, decodificar y sostener el documento entero como cadena, a menudo
  duplicado.
- 🗣️ Un servicio que recibe un PDF de 40 MB en Base64 dentro de un JSON tiene el archivo en memoria
  al menos dos veces —la cadena codificada y el binario decodificado—, más lo que el parser de JSON
  necesite. Con veinte peticiones concurrentes, eso tira el proceso.
- 🔬 Y es un coste que **no escala con el ancho de banda**: por eso un servicio que va bien en pruebas
  con archivos pequeños se cae el día que entra uno grande. La forma de eliminarlo es no pasar el
  binario por el servicio: `multipart` con procesamiento en flujo, o una URL prefirmada al
  almacenamiento de objetos.

**04 → 20.** **¿Por qué `charset=utf-8` es redundante en `application/json`? 🟠**

- ⏱️ Porque RFC 8259 ya obliga a UTF-8 para el JSON intercambiado entre sistemas: no hay alternativa
  que declarar.
- 🗣️ No es un error mandarlo, y muchos frameworks lo hacen por defecto. Lo que sí es un error es
  declarar otra cosa, o asumir que el parámetro cambia algo en el receptor.
- 🔬 El registro del tipo `application/json` no define el parámetro `charset`, así que un receptor
  estricto lo ignora. El sitio donde sí importa declararlo es en `text/csv` y `text/plain`, donde el
  formato no lleva la codificación por dentro — y es justamente donde se rompen los acentos.

**04 → 21.** **Un texto llega como `Ã±` en vez de `ñ`. Diagnostica dónde está el fallo. 🟠**

- ⏱️ Alguien leyó octetos UTF-8 interpretándolos como Latin-1: los dos octetos de `ñ` (`C3 B1`) se
  muestran como los dos caracteres `Ã` y `±`.
- 🗣️ El patrón identifica el error con precisión: `Ã±`, `Ã©`, `Ã¡` son siempre UTF-8 leído como
  Latin-1. El caso inverso —Latin-1 leído como UTF-8— produce el rombo con interrogación o un error
  de decodificación, no esos pares.
- 🔬 La corrupción ocurre **donde se hizo la conversión**, no donde se ve: hay que recorrer la cadena
  —base de datos, conexión, aplicación, encabezado de respuesta, archivo— y encontrar el punto donde
  se decodificó sin declarar la codificación. El sospechoso habitual es una conexión a base de datos
  o una lectura de archivo que usa la codificación por defecto de la plataforma en vez de una
  explícita.

**04 → 22.** **Un buscador falla cuando el término lleva `&`. ¿Qué pasó y cómo se arregla? 🟠**

- ⏱️ El `&` no se codificó y partió el parámetro en dos: el servidor ve una clave distinta.
- 🗣️ `?q=Marks & Spencer` llega como `q=Marks ` más un parámetro `Spencer` vacío. Es la inyección
  accidental más común, y tiene versiones peores: un `&` bien colocado puede sobrescribir otro
  parámetro de la query.
- 🔬 Se arregla codificando cada **valor** con la función de codificación de componentes de URI —no la
  de URI entera, que deja pasar los reservados por diseño—, y en cliente JavaScript la diferencia
  entre `encodeURI` y `encodeURIComponent` es exactamente esa. La regla: se codifica lo que es dato;
  se deja intacto lo que es estructura.

**04 → 23.** **¿Qué tiene que ver la compresión con BREACH y qué regla se sigue? 🟠**

- ⏱️ Comprimir una respuesta que mezcla un secreto con texto que controla el atacante filtra el
  secreto por el tamaño comprimido.
- 🗣️ El mecanismo: el compresor acorta más cuando hay repeticiones, así que si el atacante inyecta un
  texto que coincide parcialmente con el secreto, la respuesta se hace ligeramente más pequeña.
  Repitiendo con variaciones se deduce el secreto carácter a carácter. CRIME hacía lo mismo con la
  compresión de TLS, que por eso se eliminó en TLS 1.3.
- 🔬 La regla práctica: no comprimir respuestas que contengan un secreto —un token anti-CSRF, una
  clave— junto a entrada reflejada del usuario; o hacer que el secreto cambie en cada respuesta, o
  añadir relleno aleatorio de longitud. Comprimir todo lo demás sigue siendo correcto.

**04 → 24.** **¿Cuándo es defendible enviar Base64 dentro de un JSON pese a su coste? Da dos casos y el umbral que usarías. 🟠**

- ⏱️ Cuando la pieza es pequeña y la atomicidad importa, y cuando el receptor no puede procesar
  `multipart`. Umbral orientativo: unos pocos cientos de kilobytes.
- 🗣️ Los dos casos: **(1)** un adjunto pequeño que forma parte indivisible del documento —una firma,
  una miniatura, un certificado—, donde partirlo en dos peticiones introduce un estado intermedio
  inválido; **(2)** un consumidor rígido, típicamente un sistema heredado o un cliente que solo habla
  JSON por un bus de mensajería.
- 🔬 El umbral no es un dogma: sale de calcular el coste de memoria por petición concurrente. Con 256
  KB y 100 peticiones a la vez son unos 25 MB de cuerpos crudos, y aproximadamente el doble contando
  la copia decodificada — asumible. Con 40 MB y 20 concurrentes, no. La forma honesta de responder es
  dar el criterio y decir que el número sale de medir, no de una tabla.

**04 → 25.** **Hay que subir una factura de 40 MB con metadatos. Compara las cuatro opciones y elige, justificando el coste de memoria. 🔴**

- ⏱️ URL prefirmada al almacenamiento de objetos, y los metadatos por la API. Los 40 MB no deben pasar
  por el servicio.
- 🗣️ Las cuatro:

  ```text
  A) JSON + Base64      53 MB de cuerpo, todo en memoria y dos veces. Descartada
  B) multipart          40 MB, procesable en flujo. Viable si el framework NO lo materializa
  C) dos peticiones     POST de metadatos + PUT del binario. Viable, con estado intermedio
  D) URL prefirmada     el cliente sube directo al almacenamiento. ELEGIDA
  ```
- 🔬 El argumento decisivo es el coste por petición concurrente, no el tamaño en sí: con la opción A,
  cien subidas simultáneas son varios gigabytes de memoria en el servicio; con la D, son cero, porque
  el servicio solo emite una URL firmada y recibe después una notificación de que el objeto existe.
  El precio de la D es complejidad: hay que gestionar la caducidad de la URL, el caso del cliente que
  pide la URL y nunca sube —limpieza de huérfanos—, y validar el archivo **después** de subido, no
  antes. Es un precio que se paga con gusto a este tamaño, y que no compensaría con archivos de 50 KB.

**04 → 26.** **Diseña el contrato de un endpoint de subida: tipo de medio, límites, validación del nombre, respuesta de error y qué se declara en `Vary`. 🔴**

- ⏱️ `POST` `multipart/form-data`, límite declarado, nombre generado por el servidor, errores con
  `413` y `415`, y `Vary` solo si hay negociación.
- 🗣️ El contrato:

  ```text
  POST /pedidos/PED-00042/adjuntos
  Content-Type: multipart/form-data; boundary=…
    parte "metadatos" → application/json
    parte "archivo"   → application/pdf, máximo 25 MB

  201 Created + Location    éxito
  413 Content Too Large     supera el límite  ← declarado en la documentación, no descubierto
  415 Unsupported Media Type tipo no admitido
  422                        metadatos inválidos
  ```
- 🔬 Las decisiones que hay que justificar: el **nombre** del archivo se genera en el servidor y el
  `filename` del cliente se guarda solo como metadato, por el *path traversal*; el **tipo** se valida
  por el contenido —los primeros octetos— y no por la extensión ni por el `Content-Type` que declara
  el cliente, porque ambos son entrada del usuario; el **límite** se aplica en el borde además de en
  la aplicación, para no gastar ancho de banda en algo que vas a rechazar; y `Vary` **no hace falta
  aquí**, porque la respuesta no se negocia ni se cachea — decir eso explícitamente es mejor que
  añadirlo por costumbre.

**04 → 27.** **Escribe el intercambio completo de una subida `multipart` con dos partes, incluidos los encabezados de cada parte, y señala qué validarías en el servidor y por qué. 🔴**

- ⏱️ Un campo de texto y un archivo, con su frontera, sus `Content-Disposition` y el cierre con dos
  guiones al final.
- 🗣️ El cuerpo, tal como lo genera un cliente real:

  ```text
  POST /pedidos/PED-00042/adjuntos HTTP/1.1
  Host: api.ejemplo.com
  Content-Length: 349
  Content-Type: multipart/form-data; boundary=----------TkNf5CfQUimXQgGMD6Dlhn

  ------------TkNf5CfQUimXQgGMD6Dlhn
  Content-Disposition: form-data; name="pedido"

  PED-00042
  ------------TkNf5CfQUimXQgGMD6Dlhn
  Content-Disposition: form-data; name="archivo"; filename="factura.pdf"
  Content-Type: application/pdf

  %PDF-1.4 …
  ------------TkNf5CfQUimXQgGMD6Dlhn--
  ```
- 🔬 Qué se valida y por qué: **tamaño total y por parte**, antes de leer nada en memoria, porque un
  cuerpo sin límite es una denegación de servicio trivial; **número de partes**, por lo mismo; **el
  tipo real por los octetos iniciales**, porque el `Content-Type` de la parte lo escribe el cliente;
  **el `filename`**, que no se usa jamás como ruta; y **la coherencia entre partes** —que el pedido
  exista y sea del usuario autenticado—, que es lo único que no se puede delegar en la
  infraestructura. La frontera no se valida: la genera el cliente, y el parser ya falla si no cuadra.

**04 → 28.** **Un informe exportado en CSV llega con los acentos rotos solo a los usuarios de Windows. Diagnostica y escribe la corrección, incluido lo que declararías en la respuesta. 🔴**

- ⏱️ El CSV va en UTF-8 sin marca de orden de bytes, y Excel en Windows lo abre con la codificación
  local en lugar de UTF-8.
- 🗣️ Encaja con el síntoma de que dependa del usuario y no del servidor: el archivo es idéntico para
  todos; lo que cambia es la herramienta que lo abre. Un CSV no lleva su codificación por dentro, así
  que Excel usa la página de códigos del sistema y destroza los acentos; Google Sheets detecta UTF-8
  y por eso "se arregla" ahí.
- 🔬 La corrección tiene tres piezas, y ninguna sobra: **(1)** emitir el BOM de UTF-8 al principio del
  archivo, que es lo que hace que Excel lo detecte —es feo, es específico de una herramienta, y es lo
  que funciona—; **(2)** declarar `Content-Type: text/csv; charset=utf-8`, que aquí **no** es
  redundante, a diferencia de JSON; **(3)** `Content-Disposition: attachment; filename="informe.csv"`,
  para que se descargue con nombre en vez de mostrarse. Y la alternativa que conviene mencionar: si
  el destinatario real es siempre Excel, exportar a `.xlsx` elimina la clase entera de problema,
  porque ese formato sí lleva la codificación dentro.

---

## Capítulo 05 — TLS y seguridad del transporte

**05 → 1.** **¿Qué garantiza HTTPS? Nombra las tres propiedades. 🟢**

- ⏱️ Confidencialidad, integridad y autenticación **del servidor**.
- 🗣️ Nadie en medio lee el contenido, nadie lo modifica sin que se note, y hablas con quien dice el
  certificado. La tercera es la que casi nadie menciona y la más importante: sin ella, el cifrado
  sería con el atacante.
- 🔬 Lo que **no** da: no autentica al cliente, no oculta a qué dominio te conectas —SNI viaja en
  claro—, no oculta el tamaño ni el ritmo del tráfico, y no protege nada en los extremos.

**05 → 2.** **¿Qué diferencia hay entre SSL y TLS? 🟢**

- ⏱️ SSL fue el protocolo de Netscape; TLS es su sucesor en el IETF desde 1999. SSL está muerto en
  todas sus versiones.
- 🗣️ El nombre sobrevivió en los productos: "certificado SSL", "terminación SSL", `SSLContext`,
  `openssl`. Usarlo en conversación es normal; lo que distingue es saber que hoy todo es TLS.
- 🔬 SSL 2.0 está prohibido (RFC 6176) y SSL 3.0 deprecado (RFC 7568), este último tras POODLE.

**05 → 3.** **¿Qué versiones de TLS están vigentes hoy? 🟢**

- ⏱️ TLS 1.2 y TLS 1.3. Las anteriores están deprecadas.
- 🗣️ TLS 1.3 (RFC 8446) es el objetivo desde 2018 y es lo que negocia cualquier navegador moderno con
  un servidor actualizado; TLS 1.2 sigue muy presente en comunicación entre servicios y sistemas
  heredados.
- 🔬 TLS 1.0 y 1.1 están deprecados por RFC 8996, que es un **Best Current Practice** — y es
  exactamente lo que cita una auditoría. Curiosidad citable: RFC 8446 sigue siendo *Proposed
  Standard*, no *Internet Standard*, lo que no le resta ninguna vigencia.

**05 → 4.** **¿Qué es un certificado X.509 y qué contiene? 🟢**

- ⏱️ Un documento firmado que liga una clave pública a una identidad —unos nombres de dominio— durante
  un periodo de validez.
- 🗣️ Contiene el sujeto, el emisor, la clave pública, las fechas de validez, las extensiones —entre
  ellas SAN, con los nombres— y la firma de la autoridad.
- 🔬 Su perfil para internet está en RFC 5280. Y lo que **no** contiene es igual de importante: no
  dice nada sobre la legitimidad del negocio detrás del dominio.

**05 → 5.** **¿Quién firma un certificado y por qué confía el cliente en él? 🟢**

- ⏱️ Una autoridad de certificación, y el cliente confía porque encadena hasta una raíz que ya tiene
  en su almacén de confianza.
- 🗣️ El servidor envía su certificado de hoja y los intermedios; el cliente verifica cada firma de la
  cadena hasta llegar a una raíz que el sistema operativo, el navegador o el JDK ya traían.
- 🔬 La raíz no viaja por el cable: si viajara, no aportaría ninguna confianza. Por eso el almacén de
  confianza local es la pieza que sostiene todo el modelo, y por eso añadirle una raíz propia es una
  decisión de seguridad seria.

**05 → 6.** **¿Qué es SNI y para qué sirve? 🟢**

- ⏱️ Una extensión del saludo donde el cliente dice a qué nombre quiere hablar, **antes** de que el
  servidor elija el certificado.
- 🗣️ Sin SNI no habría varios sitios HTTPS en una misma IP: el servidor tendría que elegir certificado
  sin saber a cuál de sus sitios va la conexión. Es el equivalente de `Host` a nivel de TLS.
- 🔬 Y **viaja en claro**, porque es anterior al cifrado: por eso TLS no oculta a qué dominio te
  conectas. Hay una extensión para cifrarlo (ECH), todavía en despliegue.

**05 → 7.** **¿Qué es HSTS? 🟢**

- ⏱️ Un encabezado que le dice al navegador que a ese dominio solo se habla por HTTPS durante N
  segundos.
- 🗣️ `Strict-Transport-Security: max-age=31536000; includeSubDomains`. Su valor es eliminar la primera
  petición en claro, que es la que un atacante en la red puede secuestrar antes de que el redirect
  ocurra.
- 🔬 Está en RFC 6797, y tiene una lista de precarga que viene incrustada en los navegadores, para
  cubrir incluso la primerísima visita.

**05 → 8.** **¿En qué puerto va HTTPS y en cuál SSH? 🟢**

- ⏱️ HTTPS en el 443, SSH en el 22.
- 🗣️ HTTP sin cifrar va en el 80. Son convenciones registradas: nada impide servir HTTPS en otro
  puerto, solo que habría que escribirlo en la URL.
- 🔬 HTTP/3 usa el 443 igual que HTTP/2, pero **sobre UDP**, y eso es lo que hace que una regla de
  cortafuegos que solo abra TCP/443 deje a HTTP/3 fuera sin que nadie se entere: el cliente cae a
  HTTP/2 en silencio.

**05 → 9.** **¿Autentica HTTPS al cliente? 🟡**

- ⏱️ No, salvo que se configure mTLS explícitamente.
- 🗣️ El saludo estándar autentica solo al servidor. La identidad del usuario se resuelve por encima:
  credenciales, token, cookie de sesión. Confundir las dos capas es un error conceptual serio.
- 🔬 Con mTLS el servidor pide certificado al cliente en el mismo saludo, y entonces la autenticación
  es mutua. Se usa entre servicios y en mallas de servicio; su coste real no es criptográfico, sino
  la gestión del ciclo de vida de miles de certificados.

**05 → 10.** **¿Por qué un sitio de phishing puede tener candado? 🟡**

- ⏱️ Porque un certificado de validación de dominio solo prueba que quien lo pidió controla ese
  dominio, y es gratis y automático.
- 🗣️ El candado nunca significó "sitio de confianza": significa "canal cifrado con el titular de este
  nombre". Un atacante que registra `banco-seguro-ejemplo.com` obtiene su certificado en segundos.
- 🔬 Por eso los navegadores dejaron de mostrar la barra verde de los certificados de validación
  extendida: se comprobó que los usuarios no distinguían los niveles, y el indicador daba una falsa
  sensación de seguridad.

**05 → 11.** **¿Qué es la cadena de certificados y qué papel juega el intermedio? 🟡**

- ⏱️ La secuencia hoja → intermedio(s) → raíz, donde cada uno está firmado por el siguiente. El
  intermedio existe para que la raíz no tenga que firmar directamente.
- 🗣️ La clave de la raíz está fuera de línea, físicamente protegida, y solo firma intermedios. Así,
  comprometer un intermedio se resuelve revocándolo; comprometer una raíz obligaría a actualizar
  todos los dispositivos del mundo.
- 🔬 En la práctica, el intermedio es la causa número uno de fallos de despliegue: el servidor debe
  enviarlo junto con la hoja, y si se olvida, el navegador lo suele tener cacheado de otra visita
  mientras que `curl`, el JDK o un móvil fallan.

**05 → 12.** **¿Contra qué campo se valida el nombre del servidor? 🟡**

- ⏱️ Contra la extensión SAN (*Subject Alternative Name*), no contra el `CN`.
- 🗣️ El `CN` como identidad está obsoleto desde RFC 6125 y los navegadores llevan años ignorándolo.
  Un certificado que solo ponga el nombre en `CN` falla en clientes modernos aunque "se vea bien".
- 🔬 SAN permite además varios nombres en un mismo certificado y tipos distintos —DNS, IP, correo—, lo
  que es justamente lo que un `CN` único no podía expresar.

**05 → 13.** **¿Qué cubre y qué no cubre un certificado comodín? 🟡**

- ⏱️ `*.ejemplo.com` cubre un solo nivel: vale para `api.ejemplo.com` y no para `a.b.ejemplo.com` ni
  para `ejemplo.com` a secas.
- 🗣️ Las dos exclusiones sorprenden por igual. Para cubrir el dominio desnudo hay que incluirlo
  explícitamente como otro nombre en SAN, y eso se hace a diario sin pensarlo.
- 🔬 Y un comodín concentra riesgo: una sola clave privada sirve para todos los subdominios, así que
  comprometerla los compromete todos. Con emisión automatizada, muchos equipos prefieren
  certificados individuales por servicio.

**05 → 14.** **¿Qué es ALPN y qué se negocia con él? 🟡**

- ⏱️ Una extensión del saludo TLS donde se acuerda el protocolo de aplicación: `h2`, `http/1.1`, `h3`.
- 🗣️ Su valor es que no cuesta viajes extra: se decide dentro del saludo que ya se estaba haciendo. Es
  así como se negocia HTTP/2 sobre TLS, no con `Upgrade`.
- 🔬 Está en RFC 7301. Un detalle operativo que se pregunta: un balanceador que no soporte ALPN
  condena a todo el tráfico a HTTP/1.1 aunque cliente y servidor sepan HTTP/2.

**05 → 15.** **¿Qué es la confidencialidad futura y por qué importa? 🟡**

- ⏱️ Que las claves de sesión son efímeras, así que quien grabe el tráfico hoy y robe la clave privada
  del servidor mañana no puede descifrar lo grabado.
- 🗣️ Sin ella, un atacante paciente almacena tráfico cifrado durante años y lo descifra el día que
  consigue la clave. Con ella, cada sesión tiene su propio secreto, derivado y descartado.
- 🔬 En TLS 1.2 era opcional —dependía de elegir una suite con intercambio efímero— y mucha gente la
  tenía apagada por rendimiento. **TLS 1.3 la hace obligatoria**, que es una de sus mejoras más
  importantes y menos visibles.

**05 → 16.** **¿Qué diferencia el modelo de confianza de SSH del de TLS? 🟡**

- ⏱️ TLS delega en terceros —las autoridades—; SSH usa TOFU: confía en la huella que ve la primera
  vez y avisa si cambia.
- 🗣️ Por eso en TLS no hace falta haber visto nunca un servidor para confiar en él, y en SSH la
  primera conexión es un acto de fe. El aviso de que la huella cambió es literalmente la detección de
  un intermediario, y casi todo el mundo lo ignora borrando `known_hosts`.
- 🔬 La otra diferencia estructural es quién se autentica: en SSH, autenticar al cliente con un par de
  claves es **el caso normal**; en TLS es la excepción.

**05 → 17.** **¿Cuántos viajes cuesta el saludo en TLS 1.2 y en TLS 1.3, y por qué? 🟠**

- ⏱️ Dos en 1.2 y uno en 1.3, porque el cliente adivina el grupo de claves y lo manda ya en el primer
  mensaje.
- 🗣️ En 1.2 el cliente ofrece suites, el servidor elige y responde con su certificado, y solo entonces
  se intercambian las claves: dos idas y vueltas antes del primer octeto de HTTP. En 1.3 el
  `ClientHello` ya incluye `key_share`, y el servidor puede responder con su parte y el certificado
  **ya cifrado**.
- 🔬 En una conexión intercontinental eso son 100–200 ms menos en la primera petición, una de las
  mejoras de latencia más baratas que existen. Si el cliente adivina mal el grupo, el servidor pide
  reintento y se vuelve al coste de 1.2 — sigue sin ser peor.

**05 → 18.** **¿Qué riesgo tiene 0-RTT y con qué concepto del capítulo `03` se relaciona? 🟠**

- ⏱️ Los datos enviados en 0-RTT son **reproducibles** por un atacante, y por eso solo deben llevar
  peticiones idempotentes.
- 🗣️ La conexión es: al reanudar una sesión sin ningún viaje previo, no hay nada fresco que ate esos
  datos a esta conexión concreta, así que quien los capture puede reenviarlos y el servidor los
  aceptará otra vez. Si eso es un `GET`, no pasa nada; si es un `POST /pagos`, es un cobro duplicado.
- 🔬 RFC 8446 §2.3 lo advierte explícitamente y deja la mitigación a la aplicación. Es un ejemplo
  perfecto de que la idempotencia del capítulo `03` no es teoría: es lo que decide si puedes activar
  una optimización de transporte.

**05 → 19.** **Un certificado funciona en Chrome y falla en el JDK. Diagnostica. 🟠**

- ⏱️ Falta el certificado intermedio en la cadena que envía el servidor.
- 🗣️ Chrome lo tenía cacheado de otra visita —o lo obtiene con *AIA fetching*—, así que completa la
  cadena por su cuenta; el JDK y `curl` no hacen eso y fallan con `PKIX path building failed`.
- 🔬 Se confirma en un comando: `openssl s_client -showcerts` y contar los certificados que llegan; si
  solo viene la hoja, es eso. La corrección es en el servidor, no en el cliente: configurar el
  archivo de cadena completo. La solución que **no** vale es añadir el intermedio al almacén de
  confianza del cliente, porque arregla un cliente y deja rotos los demás.

**05 → 20.** **¿Por qué la revocación es el punto débil de la infraestructura de clave pública? 🟠**

- ⏱️ Porque comprobarla es caro, lento o filtra información, así que en la práctica muchos clientes no
  la comprueban de verdad.
- 🗣️ Las CRL son listas enormes que hay que descargar entero. OCSP consulta en línea, pero añade
  latencia y **le dice al validador qué sitios visitas**, que es un problema de privacidad real. Y si
  la consulta falla, casi todos los clientes continúan igualmente —el llamado *soft-fail*—, con lo
  que un atacante que bloquee la consulta desactiva la revocación.
- 🔬 El parche es el *OCSP stapling*: el servidor adjunta una prueba de no revocación ya firmada y
  reciente, sin consulta del cliente. Y la respuesta de fondo de la industria fue otra: **acortar
  drásticamente la vida de los certificados**, porque un certificado que dura semanas casi no
  necesita revocarse.

**05 → 21.** **¿Qué se pierde y qué se gana al terminar TLS en el balanceador? 🟠**

- ⏱️ Se gana rendimiento, gestión centralizada de certificados e inspección; se pierde el cifrado del
  tramo interno y la visibilidad directa del cliente.
- 🗣️ Ganas: un único sitio donde renovar certificados, descarga de trabajo criptográfico, y la
  posibilidad de aplicar reglas —limitación de tasa, cortafuegos de aplicación, caché— sobre tráfico
  en claro. Pierdes: tu servicio ya no ve la IP ni el certificado del cliente, y todo lo que va del
  balanceador hacia dentro está expuesto a quien esté en esa red.
- 🔬 La decisión honesta depende del dato y del modelo de amenaza. En banca o sanidad, lo normal es
  volver a cifrar el tramo interno —con certificados internos— y asumir el coste; en un sistema
  público sin datos sensibles, terminar en el borde es razonable. Lo que no es defendible es no haber
  decidido: es el supuesto que la confianza cero desmonta.

**05 → 22.** **¿Por qué `X-Forwarded-For` no es una fuente fiable de la IP del cliente? 🟠**

- ⏱️ Porque es un encabezado que cualquiera puede escribir en su petición.
- 🗣️ Si tu servicio lee el valor tal cual, un atacante añade `X-Forwarded-For: 10.0.0.1` y se hace
  pasar por una IP interna: se salta listas blancas, limitadores de tasa y auditorías. El encabezado
  es además una lista, y elegir el elemento equivocado tiene el mismo efecto.
- 🔬 La regla correcta: **el borde sobrescribe** el encabezado que llega de fuera en lugar de
  añadirse a él, y el servicio confía solo en el valor que pone su propio borde, contando desde la
  derecha tantos saltos como proxies propios haya. Y el estándar real es `Forwarded` (RFC 7239);
  `X-Forwarded-For` es la convención previa, que sigue siendo lo que verás en producción.

**05 → 23.** **¿Qué compromiso adquieres al publicar HSTS con `includeSubDomains`? 🟠**

- ⏱️ Que todos tus subdominios tienen que servir HTTPS válido durante todo el `max-age`, y no puedes
  retractarte para los navegadores que ya lo recibieron.
- 🗣️ El caso doloroso: un subdominio interno o heredado que solo habla HTTP deja de ser accesible para
  quien haya visitado el dominio principal. Y reducir el `max-age` no ayuda a los navegadores que ya
  tienen el valor antiguo; hay que esperar a que expire o que vuelvan a visitarte.
- 🔬 Por eso el despliegue se hace en escalera: `max-age` corto primero —minutos, luego días—,
  comprobar que ningún subdominio se rompe, y solo entonces subir a un año y plantearse la lista de
  precarga, que es prácticamente irreversible.

**05 → 24.** **¿Por qué TLS 1.3 redujo la lista de suites de cifrado a cinco? 🟠**

- ⏱️ Porque la mayor parte de los ataques históricos venían de suites débiles que seguían disponibles
  "por compatibilidad".
- 🗣️ Una lista larga es una superficie de ataque: basta que cliente y servidor puedan negociar a la
  baja para que exista un ataque de degradación. En 1.3 se eliminaron RC4, 3DES, los modos CBC
  problemáticos, MD5 y SHA-1 para firmas, la renegociación y la compresión de TLS.
- 🔬 Y hay un cambio de diseño detrás: en 1.3 la suite ya no mezcla intercambio de claves,
  autenticación y cifrado en un solo identificador; esos elementos se negocian por separado. Eso es
  lo que permite que queden cinco combinaciones, todas con confidencialidad futura y cifrado
  autenticado.

**05 → 25.** **Una auditoría exige desactivar TLS 1.0 y 1.1. Enumera qué comprobarías antes, qué romperías y cómo lo desplegarías. 🔴**

- ⏱️ Medir primero qué clientes usan esas versiones, avisar, desplegar por etapas y tener vuelta
  atrás.
- 🗣️ El plan:

  ```text
  1. MEDIR     % de saludos por versión en los logs del balanceador, 30 días
  2. IDENTIFICAR quién queda fuera: qué clientes, qué integraciones, qué volumen de negocio
  3. AVISAR    ventana con fecha, y contacto directo con los integradores afectados
  4. DESPLEGAR un entorno primero; luego un % del tráfico; luego todo
  5. VIGILAR   errores de handshake, no solo códigos HTTP: un fallo de TLS no deja traza HTTP
  ```
- 🔬 Qué se rompe, concretamente: Android muy antiguo, Java 7 sin actualizar, .NET Framework con la
  configuración por defecto antigua, dispositivos empotrados y algún cliente corporativo con
  inspección TLS obsoleta. El punto que casi siempre se olvida es el 5: **un cliente que no puede
  completar el saludo no aparece en tus métricas HTTP**, así que si solo miras tasas de error de
  aplicación, verás todo verde mientras pierdes integraciones. Y si la auditoría es de cumplimiento,
  la cita es RFC 8996, que es BCP.

**05 → 26.** **Diseña la seguridad de transporte de una API bancaria de extremo a extremo: navegador, CDN, balanceador, servicio y base de datos. Di qué proteges en cada tramo y con qué. 🔴**

- ⏱️ TLS 1.3 en todos los tramos, mTLS de servicio a servicio, cifrado también hacia la base de datos,
  y HSTS con precarga en el borde.
- 🗣️ Tramo a tramo:

  ```text
  navegador → CDN        TLS 1.3, HSTS + preload, certificado público, ALPN h2/h3
  CDN → balanceador      TLS con certificado propio; el CDN valida el origen
  balanceador → servicio mTLS con CA interna; identidad de servicio en el certificado
  servicio → servicio    mTLS, rotación automática (malla de servicios si la hay)
  servicio → base datos  TLS con verificación del certificado del servidor, no solo cifrado
  ```
- 🔬 Las decisiones que hay que saber defender: **(1)** re-cifrar entre CDN y origen no es paranoia,
  porque ese tramo cruza internet; **(2)** el último tramo es el que más se olvida — muchas conexiones
  a base de datos cifran pero **no verifican** el certificado, lo que deja pasar un intermediario;
  **(3)** mTLS interno resuelve autenticación de servicio, no autorización: sigue haciendo falta
  decidir qué puede hacer cada identidad; **(4)** el coste dominante no es la CPU, es el ciclo de vida
  de los certificados, así que sin emisión y rotación automatizadas este diseño se cae solo en tres
  meses. Y por encima de todo esto sigue haciendo falta la seguridad de aplicación —autenticación de
  usuario, autorización, auditoría—, que es de otro capítulo y de otro repaso.

**05 → 27.** **Escribe el procedimiento de renovación de certificados de una plataforma con veinte servicios: qué automatizas, qué monitorizas y cuál es la alerta que evita la caída. 🔴**

- ⏱️ Emisión y renovación automáticas con ACME, inventario centralizado, y una alerta por días
  restantes que dispara **muy** antes del vencimiento.
- 🗣️ El procedimiento:

  ```text
  AUTOMATIZAR  emisión y renovación vía ACME (RFC 8555) a un tercio de la vida del certificado
  INVENTARIAR  un registro con: dominio, emisor, caducidad, dónde está desplegado, quién responde
  MONITORIZAR  días restantes POR ENDPOINT EN PRODUCCIÓN, sondeado desde fuera
  ALERTAR      aviso a 30 días, alerta a 14, incidente a 7
  ENSAYAR      una renovación forzada al trimestre, para probar que el camino funciona
  ```
- 🔬 El detalle que marca la diferencia: **se monitoriza el certificado que sirve el endpoint, no el
  archivo en disco**. La caída típica no es "se nos olvidó renovar", es "se renovó y nadie recargó el
  proceso", o "se renovó en dos de los tres nodos". Sondear desde fuera con `openssl s_client` detecta
  las dos cosas; mirar el archivo, ninguna. Y la alerta a 30 días existe porque renovar puede requerir
  intervención de terceros —una entidad certificadora corporativa, un proveedor, un cambio de DNS— y
  siete días no siempre bastan.

**05 → 28.** **Un servicio expone mTLS a sus clientes internos. Enumera los cinco problemas de ciclo de vida que aparecerán y cómo los resolverías. 🔴**

- ⏱️ Emisión, distribución, rotación, revocación y depuración. Los cinco son operativos, ninguno es
  criptográfico.
- 🗣️ Los cinco, con su respuesta:

  ```text
  1. EMISIÓN      ¿quién decide que un cliente merece certificado? → CA interna + proceso de alta
  2. DISTRIBUCIÓN ¿cómo llega la clave privada al cliente sin exponerla? → gestor de secretos, nunca correo ni repo
  3. ROTACIÓN     caducan todos a la vez si se emitieron a la vez → escalonar y automatizar
  4. REVOCACIÓN   un cliente comprometido o dado de baja → CRL interna corta, o vidas muy cortas
  5. DEPURACIÓN   "me da 403 y no sé por qué" → mensajes que digan qué identidad se presentó
  ```
- 🔬 El problema 3 es el que tumba plataformas: veinte clientes dados de alta el mismo día caducan el
  mismo día, y la incidencia es simultánea y total. El 5 es el que consume más tiempo del equipo, y
  se resuelve barato: registrar el sujeto del certificado presentado en cada rechazo convierte horas
  de investigación en una línea de log. Y la decisión estratégica es la 4: en un entorno interno,
  **certificados de vida corta con rotación automática sustituyen a la revocación**, que es cara y
  poco fiable — es la misma conclusión a la que llegó la infraestructura pública.

**05 → 29.** **Te dan el informe de SSL Labs de un dominio con nota B. Escribe el orden en que atacarías los hallazgos y qué comprobarías antes de tocar nada. 🔴**

- ⏱️ Antes de tocar nada: qué clientes tiene ese dominio. Luego, de mayor a menor riesgo real: cadena,
  versiones, suites, y al final lo cosmético.
- 🗣️ El orden:

  ```text
  0. ANTES     inventario de clientes reales, por versión de TLS, desde los logs
  1. Cadena incompleta o certificado mal emitido   → rompe clientes HOY, aunque el navegador lo oculte
  2. Protocolos deprecados habilitados (1.0/1.1)   → el hallazgo que cita la auditoría
  3. Suites débiles o sin confidencialidad futura  → degradación y tráfico grabado
  4. Falta HSTS                                     → despliegue en escalera, no de golpe
  5. Cosmético (orden de suites, OCSP stapling)     → mejora la nota, no el riesgo
  ```
- 🔬 El paso 0 es el que distingue a alguien que ha operado: **la nota no es el objetivo, la
  compatibilidad con tus clientes sí**. Un A+ que deja fuera al 3 % de los integradores de una API
  bancaria es un incidente, no una mejora. El paso 1 va primero aunque SSL Labs no lo penalice mucho,
  porque es el único hallazgo que ya está fallando en producción para alguien. Y el paso 4 se
  despliega con `max-age` corto primero, por lo irreversible que es el compromiso.

---

## Capítulo 06 — Versiones, proxies y tiempo real

**06 → 1.** **¿Qué es el bloqueo de cabeza de línea? 🟢**

- ⏱️ Que un elemento lento al principio de la cola detiene a todos los que van detrás, aunque estén
  listos.
- 🗣️ En HTTP/1.1 ocurre por conexión: una respuesta lenta bloquea las peticiones siguientes de esa
  conexión. Es el hilo que explica las tres versiones posteriores del protocolo.
- 🔬 Hay dos niveles, y confundirlos es el error clásico: el de HTTP, que resolvió HTTP/2
  multiplexando, y el de TCP, que persiste con HTTP/2 y solo resuelve HTTP/3 cambiando de transporte.

**06 → 2.** **¿Qué aportó `keep-alive` en HTTP/1.1? 🟢**

- ⏱️ Reutilizar la misma conexión TCP para varias peticiones, en vez de abrir una por recurso.
- 🗣️ Lo que ahorra es el saludo: el de TCP y, si hay HTTPS, el de TLS. En una página con decenas de
  recursos eso es la diferencia entre lenta e inaceptable.
- 🔬 Es la razón de que haga falta un mecanismo de framing explícito —`Content-Length` o `chunked`—:
  con la conexión reutilizada, "el cuerpo termina cuando se cierra" deja de valer.

**06 → 3.** **¿Cuántas conexiones por origen abre un navegador con HTTP/1.1? 🟢**

- ⏱️ Seis, por convención. No lo fija ninguna norma.
- 🗣️ Es el límite de facto de todos los navegadores, y el que dio origen al *sharding* de dominios:
  repartir los recursos entre varios subdominios para multiplicar el número de conexiones.
- 🔬 Con HTTP/2 el límite deja de importar —una conexión multiplexa decenas de peticiones— y el
  *sharding* pasa de optimización a estorbo, porque multiplica saludos TLS y fragmenta la
  multiplexación.

**06 → 4.** **¿Qué es la multiplexación de HTTP/2? 🟢**

- ⏱️ Varias peticiones y respuestas a la vez sobre una sola conexión, en tramas intercaladas y sin
  orden impuesto.
- 🗣️ Cada intercambio va en un flujo con su identificador, y las tramas de flujos distintos se
  entrelazan. Así una respuesta lenta ya no bloquea a las demás.
- 🔬 Es lo que hace que las peticiones dejen de ser caras, y por tanto lo que invalida toda la familia
  de trucos de HTTP/1.1: concatenar, hacer sprites, incrustar en base64.

**06 → 5.** **¿Sobre qué transporte va HTTP/3? 🟢**

- ⏱️ Sobre QUIC, que a su vez va sobre UDP.
- 🗣️ QUIC (RFC 9000) reimplementa en espacio de usuario lo que TCP hacía en el núcleo —fiabilidad,
  orden, control de congestión— pero con flujos independientes, e integra TLS 1.3 en su propio
  saludo.
- 🔬 Decir "HTTP/3 es HTTP/2 sobre UDP" es impreciso: lo que cambia es el transporte entero, no solo
  el datagrama. UDP es únicamente el sobre que permite implementarlo fuera del núcleo.

**06 → 6.** **¿Qué diferencia hay entre `no-cache` y `no-store`? 🟢**

- ⏱️ `no-cache` permite guardar pero obliga a revalidar antes de usar; `no-store` prohíbe guardar.
- 🗣️ Casi todo el mundo que escribe `no-cache` quiere decir `no-store`. La diferencia importa: con
  `no-cache` la respuesta está en disco, en la caché del navegador o en un proxy, y eso con datos
  personales es un problema.
- 🔬 `max-age=0` es otra cosa más: la respuesta se guarda y nace caducada, así que se revalidará. En
  la práctica se parece a `no-cache`, pero `must-revalidate` marca la diferencia en el caso de que la
  revalidación falle.

**06 → 7.** **¿Qué es un `ETag`? 🟢**

- ⏱️ Un identificador opaco de la versión concreta de un recurso, que el servidor emite y el cliente
  devuelve para preguntar si sigue siendo válida.
- 🗣️ Con `If-None-Match` sirve para ahorrar cuerpo al leer: si no cambió, el servidor responde `304`
  sin contenido. Con `If-Match` sirve para no pisar cambios al escribir.
- 🔬 Es opaco por definición: el cliente no debe interpretarlo. Puede ser un hash, una versión, una
  marca de tiempo — es cosa del servidor.

**06 → 8.** **¿Qué es un proxy inverso? 🟢**

- ⏱️ Un intermediario que pone el **servidor** delante de sus servicios, y que para el cliente es
  indistinguible del origen.
- 🗣️ Es lo que hace nginx, un balanceador, una pasarela de API o un CDN: termina TLS, reparte carga,
  cachea, limita tasa y filtra. El proxy directo es el contrario: lo pone el cliente y el servidor no
  se entera.
- 🔬 Casi toda la depuración rara de HTTP en producción —encabezados que desaparecen, IPs que no
  cuadran, `400` que no llegan a la aplicación— ocurre en este punto de la cadena.

**06 → 9.** **¿Qué es SSE y qué tipo de medio usa? 🟢**

- ⏱️ *Server-Sent Events*: una respuesta HTTP que no termina y por la que el servidor va enviando
  eventos. Su tipo es `text/event-stream`.
- 🗣️ Es HTTP normal, así que atraviesa proxies, balanceadores y cachés sin configuración especial, y
  el navegador **reconecta solo**, enviando `Last-Event-ID` para continuar donde se quedó.
- 🔬 No está en un RFC: se define en la especificación HTML de WHATWG. Es unidireccional, del servidor
  al cliente, que es justamente el 80 % de los casos que la gente resuelve con WebSocket.

**06 → 10.** **¿Por qué el *pipelining* de HTTP/1.1 fracasó? 🟡**

- ⏱️ Porque las respuestas seguían teniendo que volver en orden, así que no eliminaba el bloqueo, y
  los intermediarios lo implementaban mal.
- 🗣️ Podías mandar varias peticiones sin esperar, pero si la primera respuesta era lenta, las demás
  esperaban igual. Y bastaba un proxy que reordenara o mezclara respuestas para corromper la sesión.
- 🔬 Los navegadores acabaron desactivándolo por defecto. Decir que **está muerto** —y por qué— es una
  respuesta de nivel, porque mucha documentación antigua sigue presentándolo como una optimización
  disponible.

**06 → 11.** **¿Por qué concatenar archivos era buena práctica y ya no lo es? 🟡**

- ⏱️ Porque con HTTP/1.1 cada petición era cara, y con HTTP/2 y HTTP/3 ya no lo es.
- 🗣️ Y además ahora hace daño: un único archivo concatenado invalida la caché entera cuando cambia una
  línea, mientras que veinte archivos separados invalidan solo el que cambió.
- 🔬 Lo mismo vale para los sprites, el *sharding* de dominios y el incrustado en base64. Es el mejor
  ejemplo de que una buena práctica es siempre **condicional a una restricción**, y que cuando la
  restricción desaparece hay que revisarla en vez de repetirla.

**06 → 12.** **¿Qué es HPACK y por qué importa en una API de muchas peticiones pequeñas? 🟡**

- ⏱️ La compresión de encabezados de HTTP/2: una tabla de índices compartida entre los dos extremos.
- 🗣️ No es gzip. Ambos lados mantienen una tabla, así que a la segunda petición un `User-Agent` de
  150 octetos, un `Authorization` largo o una cookie viajan como un índice de un octeto.
- 🔬 En una API con peticiones pequeñas, **los encabezados eran el grueso del tráfico**: un cuerpo
  JSON de 80 octetos con 600 de encabezados es un caso normal. Ahí HPACK no es una mejora marginal,
  es la diferencia. Su equivalente en HTTP/3 es QPACK, rediseñado para tolerar que los flujos lleguen
  desordenados.

**06 → 13.** **¿Qué pasó con el server push de HTTP/2 y qué lo sustituye? 🟡**

- ⏱️ Fracasó y está retirado de los navegadores. Lo sustituye `103 Early Hints`.
- 🗣️ El problema de fondo es que el servidor no sabe qué tiene ya el cliente en su caché, así que
  empujaba recursos que el navegador iba a descartar: gastaba ancho de banda en lugar de ahorrarlo.
- 🔬 `103 Early Hints` (RFC 8297) invierte el reparto: el servidor **sugiere** con enlaces de precarga
  y el cliente decide si los pide. Es la única familia de códigos `1xx` que se ve a diario, y se
  captura fácil: un `curl -I` a un sitio que lo use devuelve dos respuestas a una sola petición.

**06 → 14.** **Diferencia frescura y validación en la caché de HTTP. 🟡**

- ⏱️ La frescura evita la petición; la validación la hace pero puede ahorrarse el cuerpo.
- 🗣️ Con `max-age=300`, durante cinco minutos el cliente usa su copia sin preguntar: **cero
  peticiones**. Cuando caduca, pregunta con `If-None-Match` y puede recibir un `304` sin contenido:
  una petición, pero sin cuerpo.
- 🔬 Son complementarias y se usan juntas. El error habitual es implementar solo `ETag` y creer que ya
  se está cacheando: sin frescura, se sigue pagando un viaje completo por cada uso.

**06 → 15.** **¿Qué hace `stale-while-revalidate`? 🟡**

- ⏱️ Permite servir la copia caducada de inmediato mientras se revalida de fondo.
- 🗣️ El usuario nunca espera por la revalidación: recibe contenido ligeramente viejo al instante y la
  caché se actualiza para el siguiente. Es la directiva con mejor relación beneficio/esfuerzo del
  protocolo.
- 🔬 Encaja especialmente bien en un CDN delante de una API de lectura: un `max-age` corto con una
  ventana de `stale-while-revalidate` amplia absorbe los picos y protege el origen sin servir datos
  realmente viejos.

**06 → 16.** **¿Qué diferencia un `ETag` fuerte de uno débil? 🟡**

- ⏱️ El fuerte cambia con cualquier octeto; el débil (`W/"…"`) solo cuando cambia el significado.
- 🗣️ Un fuerte garantiza que dos representaciones con el mismo `ETag` son idénticas octeto a octeto,
  lo que hace falta para peticiones por rangos. Uno débil basta para decidir si merece la pena volver
  a descargar.
- 🔬 Comprimir una respuesta cambia el `ETag` fuerte, porque la representación es otra. Eso ha roto
  integraciones donde un intermediario comprimía sin ajustar el identificador, y es un argumento para
  usar `ETag` débil cuando lo único que quieres es validar.

**06 → 17.** **¿Qué es `Alt-Svc`? 🟡**

- ⏱️ Un encabezado con el que un servidor anuncia que el mismo servicio está disponible por otro
  protocolo o puerto — típicamente HTTP/3.
- 🗣️ `alt-svc: h3=":443"; ma=2592000` significa "esto también está en HTTP/3, recuérdalo un mes". El
  cliente sigue con la conexión actual y usa la alternativa la próxima vez.
- 🔬 Está en RFC 7838 y es el mecanismo real de descubrimiento de HTTP/3: por eso una primera visita
  casi siempre va por HTTP/2 y las siguientes por HTTP/3, y por eso medir "qué porcentaje usa HTTP/3"
  da resultados distintos según cuándo se mire.

**06 → 18.** **¿Qué pierdes al pasar a WebSocket tras el `101`? 🟡**

- ⏱️ Todo HTTP: métodos, códigos de estado, caché, encabezados por mensaje y el balanceo sin estado.
- 🗣️ Tras el cambio de protocolo el canal es un flujo de mensajes bidireccional y nada más. Todo lo
  que HTTP te daba gratis —semántica, reintentos, observabilidad por petición— hay que reimplementarlo
  dentro del protocolo de aplicación que te inventes.
- 🔬 Y ganas estado: la conexión vive en una instancia concreta, así que el balanceo necesita afinidad
  o un bus de mensajes detrás. Eso es lo que hace que un WebSocket funcione en local y falle en
  producción.

**06 → 19.** **¿Por qué HTTP/2 puede ir peor que HTTP/1.1 en una red con pérdidas? 🟠**

- ⏱️ Porque concentra todo en una conexión TCP, y TCP entrega en orden: un paquete perdido detiene
  **todos** los flujos.
- 🗣️ Con HTTP/1.1 y seis conexiones, una pérdida detiene una sexta parte del trabajo; las otras cinco
  siguen. Con una sola conexión multiplexada, la pérdida las para todas hasta la retransmisión.
- 🔬 Por eso el beneficio de HTTP/2 se nota mucho en redes buenas y puede invertirse en móvil con mala
  cobertura. Y por eso HTTP/3 no fue un capricho: es la respuesta exacta a este problema, moviendo la
  independencia de flujos al transporte.

**06 → 20.** **¿Por qué QUIC se implementó sobre UDP en vez de mejorar TCP? 🟠**

- ⏱️ Porque TCP vive en el núcleo del sistema operativo y está osificado por los intermediarios.
- 🗣️ Dos obstáculos: evolucionar TCP significa esperar a que todos los sistemas operativos del mundo
  se actualicen, lo que lleva una década; y los cortafuegos y NAT descartan o alteran lo que no
  reconocen, así que una opción TCP nueva a menudo no llega al otro extremo. UDP es un sobre que
  pasa, y permite implementar el transporte en espacio de usuario, donde se actualiza con la
  aplicación.
- 🔬 Además, hacerlo en espacio de usuario permitió cifrar prácticamente todo el transporte —incluidos
  los números de paquete—, lo que impide que un intermediario vuelva a osificarlo. Es una decisión de
  diseño explícita, no un efecto colateral.

**06 → 21.** **¿Qué permite el identificador de conexión de QUIC que TCP no permitía? 🟠**

- ⏱️ Sobrevivir a un cambio de IP: la conexión se identifica por un identificador propio, no por la
  tupla IP y puerto.
- 🗣️ El caso cotidiano es el móvil que pasa de wifi a datos: con TCP la conexión se rompe y hay que
  rehacer saludo de transporte y de TLS; con QUIC continúa, y la descarga o la videollamada no se
  cortan.
- 🔬 Esa propiedad —la migración de conexión— es de las que menos se nombran y más se notan en uso
  real, y es imposible de retroadaptar a TCP porque la identidad por tupla está en su definición.

**06 → 22.** **¿Cuál es el coste de HTTP/3 y por qué se mantiene la caída a HTTP/2? 🟠**

- ⏱️ UDP bloqueado en muchas redes, más CPU, y herramientas de diagnóstico que ven menos.
- 🗣️ Bastantes redes corporativas limitan o bloquean UDP saliente que no sea DNS; el procesamiento en
  espacio de usuario consume más ciclos que el TCP del núcleo, lo que importa a escala de CDN; y
  como casi todo va cifrado, depurar con capturas de red es mucho más difícil.
- 🔬 Por eso el descubrimiento es por `Alt-Svc` y no por imposición: el cliente prueba HTTP/3 y, si no
  funciona, sigue por HTTP/2 sin que el usuario note nada. Un diseño que exigiera HTTP/3 dejaría
  fuera a una parte real del tráfico empresarial.

**06 → 23.** **¿Cómo se usa `ETag` para control de concurrencia optimista al escribir? 🟠**

- ⏱️ El cliente devuelve el `ETag` que leyó en `If-Match`, y el servidor rechaza con `412` si el
  recurso cambió mientras tanto.
- 🗣️ El flujo: `GET` devuelve el recurso con `ETag: "a3f9c1"`; el usuario edita; el `PUT` lleva
  `If-Match: "a3f9c1"`. Si otro modificó el recurso entretanto, su `ETag` ya no coincide y la
  escritura se rechaza con `412 Precondition Failed` en vez de pisar el cambio ajeno.
- 🔬 Es el mejor uso de `ETag` en una API y casi nadie lo aprovecha: resuelve el problema de la última
  escritura gana sin bloqueos, sin campos de versión propios y sin inventar nada — está en RFC 9110
  §13.1.1. Su variante para creación es `If-None-Match: *`, que crea solo si no existía.

**06 → 24.** **¿SSE o WebSocket para el seguimiento del estado de un pedido? Justifica. 🟠**

- ⏱️ SSE. El flujo es del servidor al cliente, y no hace falta pagar el precio de WebSocket.
- 🗣️ El criterio, que es lo que se pregunta: si el cliente **no** necesita empujar datos con baja
  latencia, SSE gana en todo lo demás — es HTTP, atraviesa la infraestructura existente, reconecta
  solo con `Last-Event-ID`, se depura con `curl` y no necesita afinidad de sesión.
- 🔬 WebSocket es la respuesta cuando hay bidireccionalidad real —chat, edición colaborativa,
  juegos—, y entonces se asumen sus costes: estado en la instancia, reconexión propia, latidos,
  proxies que cortan. Responder "WebSocket" por defecto es el error más común de esta pregunta.

**06 → 25.** **Un WebSocket funciona en local y falla tras el balanceador. Diagnostica. 🟠**

- ⏱️ El balanceador no está propagando el cambio de protocolo, o corta la conexión por inactividad, o
  reparte sin afinidad.
- 🗣️ Las tres causas, en orden de frecuencia: **(1)** `Upgrade` y `Connection` son *hop-by-hop*, así
  que un proxy no configurado para WebSocket los consume y el `101` nunca llega; **(2)** el
  balanceador tiene un tiempo de inactividad —60 s es un valor típico— y cierra un canal que no envía
  nada; **(3)** cada reconexión cae en una instancia distinta que no conoce la sesión.
- 🔬 Cómo se distinguen: si falla **al conectar**, es la primera —se ve porque no hay `101`—; si falla
  **siempre al mismo tiempo** de conexión, es la segunda, y se arregla con latidos por debajo del
  umbral; si falla de forma intermitente tras reconectar, es la tercera, y la solución no es afinidad
  sino sacar el estado a un bus compartido.

**06 → 26.** **Diseña la estrategia de caché completa de una API con datos públicos, datos por usuario y datos que cambian cada segundo. Di las directivas exactas y por qué. 🔴**

- ⏱️ Públicos: `public` con `s-maxage` y `stale-while-revalidate`. Por usuario: `private` y `ETag`. De
  alta frecuencia: `no-store` o una ventana de un segundo.
- 🗣️ Las tres políticas:

  ```text
  PÚBLICOS (catálogo, tarifas)
    Cache-Control: public, max-age=60, s-maxage=300, stale-while-revalidate=600
    ETag: "…"                       ← el CDN absorbe el tráfico; el origen casi no se entera

  POR USUARIO (pedidos, perfil)
    Cache-Control: private, max-age=0, must-revalidate
    ETag: "…"   Vary: Authorization  ← nunca en caché compartida

  ALTA FRECUENCIA (cotización, estado en vivo)
    Cache-Control: no-store          ← o max-age=1, public, si el volumen lo justifica
  ```
- 🔬 Las decisiones que hay que justificar: **`s-maxage` mayor que `max-age`** deja que el CDN guarde
  más tiempo que el navegador, que es exactamente lo que quieres; **`private` más `Vary:
  Authorization`** es cinturón y tirantes contra el peor fallo posible, servir datos de un usuario a
  otro; y en los datos de alta frecuencia, `max-age=1` parece ridículo y no lo es — con 10 000
  peticiones por segundo, un segundo de caché compartida reduce la carga del origen en tres órdenes
  de magnitud. Lo que no se hace nunca es poner `no-cache` creyendo que impide guardar.

**06 → 27.** **Un equipo migra a HTTP/2 y no mejora nada. Enumera las cinco causas más probables, en orden. 🔴**

- ⏱️ Siguen los trucos de HTTP/1.1, se termina HTTP/2 antes de tiempo, la latencia no era el cuello de
  botella, la red pierde paquetes, o no se está negociando HTTP/2 en absoluto.
- 🗣️ Las cinco, en orden:

  ```text
  1. Sharding de dominios y concatenación siguen activos → anulan la multiplexación
  2. El CDN habla HTTP/2 con el navegador y HTTP/1.1 con el origen → mejora solo el primer tramo
  3. El cuello de botella era la base de datos o el backend, no el transporte
  4. Red con pérdidas: el bloqueo de TCP anula la ganancia
  5. No se negocia HTTP/2: falta ALPN en el balanceador, o falta TLS
  ```
- 🔬 El orden importa y es defendible: la 1 es la más frecuente porque migrar el protocolo es un
  cambio de infraestructura y nadie revisa el frontend; la 5 va al final porque es la más fácil de
  descartar —una línea de `curl -I` dice qué versión se negocia— aunque cuando ocurre lo explica todo.
  Y el aprendizaje de fondo: **medir antes de migrar**. Si nadie sabía cuánto tiempo se iba en
  transporte frente a backend, la migración no podía tener un resultado esperado con el que comparar.

**06 → 28.** **Diseña el mecanismo de seguimiento en vivo del estado de mil pedidos simultáneos: transporte, reconexión, qué pasa si el cliente estuvo desconectado y cómo escala tras el balanceador. 🔴**

- ⏱️ SSE sobre HTTP/2, con identificadores de evento y `Last-Event-ID`, un bus de publicación detrás y
  una ventana de historial por pedido.
- 🗣️ El diseño:

  ```text
  TRANSPORTE   GET /pedidos/{id}/eventos  →  text/event-stream, sobre HTTP/2
  IDENTIDAD    cada evento con id incremental por pedido
  RECONEXIÓN   la da el navegador; reenvía Last-Event-ID automáticamente
  HUECO        el servidor reenvía los eventos posteriores a ese id, desde un historial de N minutos
  ESCALA       las instancias se suscriben a un bus (Redis, Kafka, Pub/Sub); ninguna guarda estado propio
  LATIDO       un comentario cada 20 s para que proxies y balanceadores no corten por inactividad
  ```
- 🔬 Los cuatro puntos que hacen que esto funcione de verdad: **(1)** el historial por pedido es lo
  que convierte la reconexión en continuidad en vez de en un hueco silencioso, y su ventana se decide
  por cuánto puede durar una desconexión razonable —diez minutos cubre un túnel o un cambio de red—;
  **(2)** el bus elimina la necesidad de afinidad, así que cualquier instancia puede atender cualquier
  reconexión, y es lo que hace innecesario el WebSocket aquí; **(3)** el latido es obligatorio, no
  opcional, porque sin tráfico los intermediarios cierran; **(4)** con HTTP/1.1 mil conexiones abiertas
  chocarían con el límite de seis por origen y con el número de descriptores, así que HTTP/2 no es un
  detalle sino un requisito del diseño. Y el cierre honesto: si mañana el producto pide que el cliente
  empuje datos, esto se sustituye por WebSocket — y conviene decirlo al proponerlo.

**06 → 29.** **Un CDN sirve contenido caducado a unos usuarios y fresco a otros, de forma intermitente. Da tres hipótesis ordenadas y el experimento que distingue cada una. 🔴**

- ⏱️ Nodos con copias distintas por una purga incompleta, `Vary` mal declarado, o directivas
  contradictorias entre origen y CDN.
- 🗣️ Las tres, con su experimento:

  ```text
  1. PURGA INCOMPLETA   unos nodos actualizados y otros no
     → pedir el recurso desde varias regiones y comparar Age y ETag
  2. VARY INCORRECTO    variantes mezcladas, cada nodo guardó una distinta
     → repetir con distintos Accept-Encoding/Language y ver si cambia el resultado
  3. DIRECTIVAS EN CONFLICTO  s-maxage del origen frente a la configuración del CDN
     → comparar los encabezados del origen con los que devuelve el CDN
  ```
- 🔬 El encabezado que más orienta desde el principio es **`Age`**: dice cuántos segundos lleva esa
  copia en la caché, así que una respuesta con `Age` alto en un nodo y bajo en otro confirma la
  hipótesis 1 sin más investigación. La 2 se distingue porque el resultado correlaciona con el
  cliente —navegador, idioma, compresión— y no con la región. Y la 3 es la que más se pasa por alto:
  muchos CDN tienen reglas propias que **sobrescriben** lo que dice el origen, así que leer el
  `Cache-Control` que emite tu aplicación no basta; hay que mirar el que sale del CDN.

---

## Simulación — Preguntas transversales

**S1.** **¿Dónde está escrito lo que obliga HTTP, y cómo sabes si lo que lees sigue vigente? 🟡**

- ⏱️ En los RFC del IETF —hoy la familia 9110 a 9114— y se comprueba en la cabecera del documento, que
  dice qué obsoleta y qué lo obsoleta.
- 🗣️ Un RFC no se edita nunca: si algo cambia, se publica otro. Por eso lo primero que se mira no es
  el contenido sino la cabecera, y por eso RFC 2616 sigue siendo el primer resultado de búsqueda
  aunque lleve más de una década retirado.
- 🔬 Atajo práctico: la búsqueda del RFC Editor dice en veinte segundos si lo que ibas a citar sigue
  vigente. Y el número STD —97 para la semántica de HTTP— envejece mejor que el número de RFC.

**S2.** **Da tres ejemplos de cosas que todo el mundo hace y que **ninguna norma obliga**. 🟠**

- ⏱️ El prefijo `X-` en encabezados propios, las URLs de recurso en plural, y `Idempotency-Key`.
- 🗣️ Ninguna norma exige `/pedidos` en vez de `/pedido`; ninguna define `X-Total-Count`; y
  `Idempotency-Key`, pese a estar en todas las pasarelas de pago, es todavía un borrador del IETF.
  Añadiría un cuarto: envolver toda respuesta en `{"data": …}`, que es convención pura.
- 🔬 La aportación de este corpus es poder decir de cada afirmación si **obliga, se recomienda o es
  costumbre**. Es lo que separa a quien ha leído normas de quien ha leído resúmenes, y se nota en la
  primera frase.

**S3.** **Un compañero cita RFC 2616. ¿Qué le dices, y cambia eso su conclusión? 🟡**

- ⏱️ Que está obsoleto desde 2014 y que lo vigente es RFC 9110; y que, casi siempre, su conclusión no
  cambia.
- 🗣️ La semántica apenas se modificó al reorganizar los documentos, así que citar 2616 sobre `GET` o
  `POST` no suele llevar a una respuesta errónea. Lo que sí hace es restar credibilidad, y deja sin
  ver lo que sí cambió: la separación entre semántica y transporte.
- 🔬 Decirlo así —"no estás equivocado, estás citando un documento retirado"— es mejor respuesta que
  el "te equivocas" a secas, y además es lo cierto.

**S4.** **¿`SHOULD` y `MUST` cambian lo que tu cliente tiene que tolerar? Explica con un ejemplo. 🟠**

- ⏱️ Sí: ante un `MUST` puedes asumir el comportamiento; ante un `SHOULD` o un `MAY` tienes que
  tolerar las dos posibilidades.
- 🗣️ Ejemplo: la norma permite que un servidor cierre la conexión tras responder. Si tu cliente asume
  que se mantendrá viva, funcionará contra un servidor y fallará contra otro, **sin que ninguno de
  los dos esté roto**.
- 🔬 De ahí la regla de diseño: el cliente robusto se escribe contra lo que la norma permite, no
  contra lo que hace la implementación con la que probaste. Probar contra un único servidor es cómo
  se producen integraciones que se rompen al cambiar de proveedor.

**S5.** **¿Cómo nombrarías hoy un encabezado propio, y qué norma respalda esa decisión? 🟡**

- ⏱️ Descriptivo y sin prefijo `X-`, por RFC 6648; y antes de inventarlo, mirar si ya existe uno
  registrado en IANA.
- 🗣️ Para paginación, por ejemplo, el encabezado `Link` de RFC 8288 ya resuelve el caso y evita
  inventar nada. Si de verdad hace falta uno propio y hay riesgo de colisión, un prefijo con el
  nombre de la organización.
- 🔬 Y el matiz que completa la respuesta: usar `X-` no rompe nada y sigue siendo lo que hay en el 90 %
  de las APIs existentes. Es una recomendación, no una prohibición — y decir las dos cosas es la
  respuesta completa.

**S6.** **Escribe en la pizarra una petición HTTP completa, a mano, y explica cada línea. 🟢**

- ⏱️ Línea de petición, `Host`, encabezados, línea en blanco y, si hay cuerpo, su framing.
- 🗣️ La forma:

  ```text
  POST /pedidos HTTP/1.1
  Host: api.ejemplo.com
  Content-Type: application/json
  Content-Length: 48

  {"cliente":"C-100","total":250.00}
  ```
- 🔬 Los detalles que hay que señalar al dibujarla: `Host` es obligatorio en HTTP/1.1; los saltos de
  línea son CRLF; la línea en blanco es el separador; y sin `Content-Length` —o `chunked`— el
  servidor no sabe dónde termina el cuerpo. En HTTP/2 esto mismo viaja como pseudo-campos y tramas.

**S7.** **¿Cómo sabe el servidor dónde termina el cuerpo? Da los dos mecanismos. 🟢**

- ⏱️ `Content-Length` con el número exacto de octetos, o `Transfer-Encoding: chunked` con trozos que
  declaran su tamaño y terminan en uno de tamaño cero.
- 🗣️ Hace falta porque la conexión se reutiliza: sin saber dónde acaba un mensaje no se sabe dónde
  empieza el siguiente.
- 🔬 Si llegan los dos, manda `chunked` y el servidor **debe cerrar la conexión** al responder
  (RFC 9112 §6.1). Esa ambigüedad es la raíz del *request smuggling*.

**S8.** **¿Qué es un encabezado *hop-by-hop* y por qué te importa detrás de un balanceador? 🟡**

- ⏱️ Uno que vale para un solo salto: el proxy lo consume y no lo reenvía. `Connection`,
  `Transfer-Encoding`, `Upgrade`, `Keep-Alive`.
- 🗣️ Importa porque explica las sorpresas: el encabezado que mandaste no es el que ve tu servicio, y
  un `Upgrade` de WebSocket muere en el proxy que no esté configurado para propagarlo.
- 🔬 Es también el motivo de que la IP del cliente se transporte aparte, con `Forwarded` o
  `X-Forwarded-For` — y de que esos valores haya que filtrarlos en el borde, porque llegan
  falsificables.

**S9.** **¿Qué hace `Vary` y qué rompe su ausencia? 🟠**

- ⏱️ Declara de qué encabezados de la petición depende la respuesta; sin él, una caché compartida
  mezcla variantes.
- 🗣️ El síntoma clásico: la mitad de los usuarios recibe el idioma equivocado, solo detrás del CDN y
  de forma intermitente. No falla: devuelve `200` con contenido válido, pero el de otro.
- 🔬 El caso grave no es el idioma sino `Authorization`: una respuesta que depende de quién eres y no
  lo declara puede acabar sirviendo tus datos a otro. Ahí, además del `Vary`, corresponde `private` o
  `no-store`.

**S10.** **¿Por qué mandar `Content-Length` y `Transfer-Encoding` a la vez es un problema de seguridad? 🟠**

- ⏱️ Porque dos intermediarios pueden resolver la ambigüedad de forma distinta, y los octetos que a
  uno le sobran el otro los lee como una petición nueva.
- 🗣️ Ese trozo sobrante lo escribe el atacante y se combina con la siguiente petición de otro
  usuario. Es *request smuggling*, y toda su familia nace de aquí.
- 🔬 Por eso la norma obliga a **cerrar la conexión**: sin conexión reutilizada no hay buffer
  compartido. Las defensas reales son normalizar el mensaje en el borde y rechazar lo ambiguo en vez
  de interpretarlo.

**S11.** **¿`PUT` o `PATCH` para cambiar un campo? Y justifica. 🟡**

- ⏱️ `PATCH` con un formato de parche declarado, salvo que el recurso sea pequeño y quieras la
  idempotencia garantizada del `PUT`.
- 🗣️ Mandar solo un campo con `PUT` es un error silencioso: estás diciendo que el recurso pasa a tener
  **solo** ese campo, y borras el resto. Si usas `PATCH`, declara
  `Content-Type: application/merge-patch+json` o el de JSON Patch.
- 🔬 El matiz de nivel: `PATCH` no promete idempotencia, así que si algo puede reintentar la petición,
  la garantía tiene que venir de otro sitio — `If-Match` con `ETag`, o una clave de idempotencia.

**S12.** **¿Es idempotente `DELETE`? ¿Y `PATCH`? 🟡**

- ⏱️ `DELETE` sí; `PATCH` no por definición, aunque pueda serlo según el parche.
- 🗣️ `DELETE` lo es porque la idempotencia es del efecto: tras la segunda llamada el recurso sigue sin
  existir, aunque la respuesta sea `404`. `PATCH` depende: `{"estado":"PAGADO"}` en Merge Patch es
  idempotente; un `add` de JSON Patch sobre un array no.
- 🔬 La cita: RFC 9110 §9.2.2 — *"PUT, DELETE, and safe request methods are idempotent"*. `PATCH` no
  está porque se define en RFC 5789.

**S13.** **Diseña el cambio de estado de un pedido de forma idempotente. 🟠**

- ⏱️ `PUT /pedidos/{id}/estado` con el estado destino, no `POST .../avanzar`.
- 🗣️ Una orden absoluta —"ponlo en `ENVIADO`"— es repetible; una relativa —"avánzalo"— no lo es nunca.
  Con `If-Match` y el `ETag` se añade además protección contra escrituras concurrentes.
- 🔬 Y un refuerzo barato: incluir el estado anterior esperado, para que una transición inválida
  responda `409` en lugar de retroceder el pedido en silencio.

**S14.** **¿Qué garantiza una clave de idempotencia y qué **no** garantiza? 🟠**

- ⏱️ Garantiza que el mismo intento lógico no se ejecute dos veces; no garantiza atomicidad, ni
  cobertura indefinida, ni qué hacer ante un cuerpo distinto.
- 🗣️ Si el servidor cae entre ejecutar y guardar la clave, el reintento vuelve a ejecutar. Si la clave
  caduca antes que el reintento, lo mismo. Y si llega la misma clave con otro cuerpo, hay que
  rechazar con `409`, no reejecutar.
- 🔬 Nada de eso lo dice una norma: `Idempotency-Key` es convención de industria y hoy un borrador del
  IETF, así que todo esto va escrito en tu contrato o no existe.

**S15.** **¿Qué nivel de madurez de Richardson tiene tu última API y por qué está bien? 🟠**

- ⏱️ Nivel 2 —recursos, verbos y códigos con su semántica— y está bien porque el nivel 3 no aporta
  nada a clientes que controlamos.
- 🗣️ El valor de la hipermedia es desacoplar al cliente de las URLs, y eso paga cuando el cliente es
  de terceros y evoluciona por su cuenta. Con clientes propios versionados a la vez, añade complejidad
  sin quitar acoplamiento real.
- 🔬 Responder con la escala en vez de con "sí, es REST" demuestra que conoces la distinción; y
  reconocer que casi nadie llega al 3 —incluido lo que Fielding dijo al respecto— es lo honesto.

**S16.** **¿Cuándo dirías que una API **no** debería ser REST? 🟠**

- ⏱️ Cuando el dominio son procedimientos y no recursos, cuando el volumen interno justifica un
  contrato binario, o cuando el cliente necesita componer la consulta.
- 🗣️ "Recalcular el riesgo de la cartera" no es un sustantivo; forzarlo produce nombres artificiales.
  Para servicio a servicio de alto volumen, gRPC paga su complejidad. Para pantallas que piden campos
  distintos, GraphQL.
- 🔬 El reverso que hay que decir: para una API pública, con clientes que no controlas, REST sobre
  HTTP sigue siendo la opción por defecto — y el motivo no es la elegancia, es que toda la
  infraestructura del mundo ya la entiende.

**S17.** **Te piden subir un archivo por una API. Da las opciones y elige, con el coste de cada una. 🟠**

- ⏱️ Base64 en JSON, `multipart`, dos peticiones o URL prefirmada. Con archivos grandes, la
  prefirmada; con pequeños y metadatos, `multipart`.
- 🗣️ Base64 infla un 33 % y, peor, obliga a tener el archivo entero en memoria, a menudo dos veces.
  `multipart` manda el binario tal cual y se puede procesar en flujo. La prefirmada saca los bytes de
  tu servicio por completo.
- 🔬 El criterio de decisión es el coste **por petición concurrente**, no el tamaño de un archivo
  suelto: es lo que explica que un servicio funcione en pruebas y se caiga en producción.

**S18.** **¿Por qué existe Base64 y cuánto cuesta exactamente? 🟢**

- ⏱️ Porque había que meter binarios por canales de 7 bits pensados para texto; cuesta exactamente un
  33 %.
- 🗣️ Tres octetos —24 bits— se reparten en cuatro grupos de 6 bits, y cada grupo es un carácter del
  alfabeto de 64. De ahí la proporción 4/3. Viene de MIME, del correo electrónico.
- 🔬 Y no es seguridad: es reversible sin clave. HTTP Basic va en Base64, que es la razón de que solo
  tenga sentido dentro de TLS.

**S19.** **¿Recupera gzip lo que Base64 infla? 🟠**

- ⏱️ Con datos ya comprimidos, casi todo; con datos comprimibles, lo empeora bastante.
- 🗣️ Medido: 3 000 octetos incompresibles dan 3 031 comprimidos en crudo y 3 061 pasando por Base64 —
  un 1 %. Un texto de 18 622 da 7 760 en crudo y 11 071 vía Base64: un 43 % más.
- 🔬 La razón es que Base64 desalinea los patrones respecto a los límites de octeto y el compresor
  deja de encontrarlos. Traer el número medido a la conversación es lo que hace memorable la
  respuesta.

**S20.** **¿Qué diferencia hay entre codificar caracteres y codificar una URL? 🟡**

- ⏱️ Una va de texto a octetos —UTF-8—; la otra de octetos a caracteres seguros dentro de una URI.
- 🗣️ Se aplican en cadena: `ñ` da los octetos `C3 B1`, y esos octetos se escriben como `%C3%B1`. Por
  eso un carácter produce dos grupos porcentuales.
- 🔬 Confundirlas produce los dobles codificados `%25C3%25B1`, y en el otro extremo los `Ã±` de un
  UTF-8 leído como Latin-1.

**S21.** **¿Qué tipo de medio pondrías a un recurso propio versionado, y por qué con `+json`? 🟡**

- ⏱️ `application/vnd.ejemplo.pedido.v2+json`, con el sufijo para que cualquier cliente genérico sepa
  parsearlo.
- 🗣️ El árbol `vnd.` es el espacio de nombres de la organización; sin el sufijo `+json`, toda
  herramienta que no conozca el tipo lo trataría como opaco.
- 🔬 Versionar en el tipo de medio es una de las opciones; las otras son la ruta y un parámetro, y la
  comparación entre ellas está en el repaso de Spring, donde se trata el versionado de contratos.

**S22.** **¿Qué te da HTTPS y qué no te da? 🟢**

- ⏱️ Da confidencialidad, integridad y autenticación del servidor. No da autenticación del cliente, ni
  privacidad sobre con quién hablas, ni legitimidad del sitio.
- 🗣️ SNI viaja en claro, y el tamaño y el ritmo del tráfico también. Y un sitio de phishing tiene
  candado, porque un certificado de dominio es gratis y automático.
- 🔬 El candado significa "canal cifrado con el titular de este nombre", nunca "sitio de confianza".
  Es de las respuestas donde más se nota si alguien ha operado sistemas.

**S23.** **¿Cómo verifica un cliente que el certificado es legítimo? 🟡**

- ⏱️ Encadena hoja → intermedios → raíz, verifica cada firma, comprueba las fechas y que el nombre
  esté en SAN.
- 🗣️ La raíz no viaja: ya está en el almacén de confianza del sistema, del navegador o del JDK. Si
  falta un intermedio, la cadena no se completa y falla — aunque el navegador lo disimule porque lo
  tenía cacheado.
- 🔬 El nombre se valida contra **SAN**, no contra `CN`, que está obsoleto desde RFC 6125. Y la
  comprobación de revocación es el eslabón débil: cara, lenta y a menudo *soft-fail*.

**S24.** **"Funciona en Chrome y falla en el JDK." ¿Qué miras primero? 🟠**

- ⏱️ La cadena: casi siempre falta el certificado intermedio.
- 🗣️ Chrome completa la cadena por su cuenta —caché o descarga por AIA—; el JDK y `curl` no. El
  síntoma en Java es `PKIX path building failed`.
- 🔬 Se confirma con `openssl s_client -showcerts` contando los certificados que llegan, y se corrige
  en el servidor. Añadir el intermedio al almacén del cliente arregla un cliente y deja rotos los
  demás.

**S25.** **¿Qué ganó TLS 1.3 sobre 1.2, y qué riesgo trajo? 🟠**

- ⏱️ Un viaje menos de saludo, confidencialidad futura obligatoria y una lista de suites reducida a
  cinco; el riesgo es 0-RTT.
- 🗣️ El cliente adivina el grupo de claves en el primer mensaje, así que el saludo pasa de 2-RTT a
  1-RTT, y el certificado ya viaja cifrado. Se eliminaron RC4, 3DES, los modos CBC problemáticos, la
  renegociación y la compresión de TLS.
- 🔬 0-RTT permite reanudar sin ningún viaje, pero **esos datos son reproducibles**: solo deben llevar
  peticiones idempotentes. Es la conexión directa con el capítulo de métodos.

**S26.** **¿Ciframos el tramo entre el balanceador y el servicio? Argumenta las dos posturas. 🟠**

- ⏱️ En datos sensibles, sí; en un sistema público sin ellos, terminar en el borde es defendible. Lo
  que no vale es no haberlo decidido.
- 🗣️ A favor de no cifrar: menos CPU, menos certificados que gestionar, y la posibilidad de inspección
  y caché en el borde. A favor de cifrar: si alguien entra en la red interna, ve todo el tráfico en
  claro, y eso es exactamente lo que la confianza cero considera inaceptable.
- 🔬 El coste real de cifrar el tramo interno no es criptográfico: es el ciclo de vida de los
  certificados internos. Sin emisión y rotación automatizadas, el diseño se degrada solo en unos
  meses.

**S27.** **¿En qué se parecen y en qué no se parecen SSH y TLS? 🟡**

- ⏱️ Ambos cifran y usan criptografía asimétrica, pero difieren en el modelo de confianza y en quién
  se autentica.
- 🗣️ TLS delega en autoridades y autentica al servidor; SSH usa TOFU —confía en la huella de la
  primera conexión— y autenticar al cliente con clave es el caso normal.
- 🔬 El aviso de SSH cuando la huella cambia es literalmente la detección de un intermediario, y
  borrar `known_hosts` para "arreglarlo" es desactivar la única protección del modelo.

**S28.** **¿Qué problema resuelve HTTP/2 y cuál hereda? 🟡**

- ⏱️ Resuelve el bloqueo de cabeza de línea en la capa HTTP, multiplexando; hereda el de TCP.
- 🗣️ Con una sola conexión, decenas de peticiones van a la vez y ninguna espera a la anterior. Pero
  TCP entrega en orden, así que un paquete perdido detiene todos los flujos hasta la retransmisión.
- 🔬 Por eso HTTP/2 puede ir **peor** que HTTP/1.1 con seis conexiones en una red con pérdidas, y por
  eso existe HTTP/3: mover la independencia de flujos al transporte.

**S29.** **¿Qué aporta HTTP/3 y qué cuesta? 🟠**

- ⏱️ Aporta flujos realmente independientes, saludo integrado con TLS 1.3 y supervivencia al cambio de
  IP; cuesta UDP bloqueado en muchas redes, más CPU y menos visibilidad.
- 🗣️ La migración de conexión es lo que hace que una descarga no se corte al pasar de wifi a datos, y
  es imposible en TCP porque la conexión se identifica por IP y puerto.
- 🔬 Por eso el descubrimiento es por `Alt-Svc` y siempre hay caída a HTTP/2: un diseño que exigiera
  HTTP/3 dejaría fuera a una parte real del tráfico corporativo.

**S30.** **Diferencia `no-cache`, `no-store` y `max-age=0`. 🟡**

- ⏱️ `no-cache` guarda pero revalida siempre; `no-store` no guarda; `max-age=0` guarda y nace
  caducado.
- 🗣️ Para datos personales lo correcto es `no-store`, que es lo que la mayoría quiere decir cuando
  escribe `no-cache`. `max-age=0` con `must-revalidate` se acerca a `no-cache`, con matices sobre qué
  pasa si la revalidación falla.
- 🔬 Está en RFC 9111 §5.2, y es probablemente el error de configuración más extendido del protocolo.

**S31.** **¿Cómo usarías `ETag` para evitar que dos usuarios se pisen una edición? 🟠**

- ⏱️ Con `If-Match`: el cliente devuelve el `ETag` que leyó, y el servidor responde `412` si el
  recurso cambió mientras tanto.
- 🗣️ Es control de concurrencia optimista sin bloqueos, sin campos de versión propios y sin inventar
  nada: está en RFC 9110 §13.1.1.
- 🔬 Para creación existe la variante `If-None-Match: *`, que crea solo si el recurso no existía — y
  convierte un `PUT` de creación en una operación segura frente a carreras.

**S32.** **¿SSE o WebSocket? Da el criterio, no la preferencia. 🟠**

- ⏱️ Si el flujo va solo del servidor al cliente, SSE; si el cliente necesita empujar con baja
  latencia, WebSocket.
- 🗣️ SSE es HTTP: atraviesa la infraestructura existente, reconecta solo con `Last-Event-ID`, se
  depura con `curl` y no necesita afinidad. WebSocket da bidireccionalidad y a cambio pierdes caché,
  códigos de estado y balanceo sin estado.
- 🔬 Responder "WebSocket" por defecto es el error más común, y suele salir de no haber preguntado en
  qué dirección va el dato.

**S33.** **Un equipo migró a HTTP/2 y no mejoró nada. ¿Por dónde empiezas? 🟠**

- ⏱️ Por comprobar que se está negociando HTTP/2 de verdad, y por si siguen activos los trucos de
  HTTP/1.1.
- 🗣️ Las causas frecuentes: *sharding* y concatenación que anulan la multiplexación; el CDN habla
  HTTP/2 con el navegador y HTTP/1.1 con el origen; el cuello de botella estaba en el backend; la red
  pierde paquetes; o falta ALPN en el balanceador.
- 🔬 El aprendizaje de fondo es previo a todo eso: **si nadie midió el reparto entre transporte y
  backend antes de migrar, no había un resultado esperado con el que comparar**.

**S34.** **¿Por qué el código de estado `418` existe, y qué te dice eso sobre los RFC? 🟡**

- ⏱️ Es una broma del 1 de abril —el protocolo de la cafetera— y dice que no todo RFC es una norma.
- 🗣️ Hay RFC informativos, experimentales, históricos y humorísticos. Lo que determina el peso de un
  documento es su categoría, no el hecho de tener número.
- 🔬 Es además un buen ejemplo de la cultura del IETF, y de por qué "lo dice un RFC" no es un
  argumento completo: hay que decir cuál y de qué categoría.

**S35.** **¿Puede una respuesta `200` significar que la operación falló? ¿Está bien hacerlo? 🟠**

- ⏱️ Puede, técnicamente, y está mal: rompe a todos los intermediarios, que solo leen el código.
- 🗣️ Las cachés guardan el error como respuesta válida, los reintentos automáticos no se disparan, los
  paneles muestran cero errores, y cualquier cliente genérico hace lo contrario de lo correcto.
- 🔬 Si hace falta detalle estructurado en el cuerpo, existe `application/problem+json`, estandarizado
  en **RFC 9457** — y conviene saber que el 7807, que aún cita mucha documentación, es el obsoleto.

**S36.** **Si HTTP no tiene estado, ¿cómo funciona un carrito de compra? 🟡**

- ⏱️ El estado no está en el protocolo: viaja en cada petición, en una cookie o un token, y se guarda
  en el servidor o en el cliente.
- 🗣️ "Sin estado" significa que el servidor no necesita recordar la petición anterior **de esa
  conexión**: cada petición llega autocontenida. El carrito es un recurso más, identificado y
  recuperable.
- 🔬 La diferencia que importa en arquitectura: si el carrito vive en la memoria de una instancia,
  hace falta afinidad de sesión y se pierde la elasticidad; si vive en un almacén compartido o en el
  cliente, cualquier instancia atiende cualquier petición. Eso es lo que la restricción REST protege.

**S37.** **¿Puede un `GET` llevar cuerpo? ¿Y debería? 🟠**

- ⏱️ La norma no lo prohíbe, pero le niega semántica definida — así que en la práctica, no.
- 🗣️ Muchos intermediarios lo descartan, algunos clientes no lo permiten y ninguna caché lo tiene en
  cuenta al calcular la clave. Un `GET` con cuerpo funciona en pruebas y falla al atravesar
  infraestructura real.
- 🔬 Cuando la consulta no cabe en la URL, las salidas son: `POST` a un recurso de búsqueda que
  devuelve resultados, o crear el recurso "búsqueda" con `POST` y leerlo después con `GET` — lo que
  además vuelve a hacer cacheable el resultado.

**S38.** **Tu API tiene que devolver 200 000 registros. ¿Qué haces? 🔴**

- ⏱️ No los devuelvo en una respuesta: pagino, o cambio el modelo a exportación asíncrona o flujo.
- 🗣️ Tres caminos según el uso: **paginación** si es un consumo interactivo; **transmisión en flujo**
  con `chunked` y NDJSON si el cliente procesa según llega; **exportación asíncrona** —`202 Accepted`,
  un recurso de trabajo, y un archivo en almacenamiento cuando esté listo— si es un volcado de datos.
- 🔬 La pregunta real detrás es de memoria y timeouts: 200 000 registros materializados son cientos de
  megas en el servidor y una respuesta que ningún balanceador va a esperar. Y la pregunta que hay que
  devolver al entrevistador antes de elegir: **¿quién consume esto y para qué?** — porque la respuesta
  correcta es distinta para una pantalla, para un proceso por lotes y para una integración.

**S39.** **¿Qué pasa exactamente entre que escribes una URL y llega el primer octeto de HTML? Cuéntalo entero. 🔴**

- ⏱️ Resolución de nombre, conexión de transporte, saludo TLS, petición HTTP, respuesta — y en cada
  paso hay cachés.
- 🗣️ La secuencia:

  ```text
  1. URL          se parsea: esquema, autoridad, ruta (RFC 3986)
  2. DNS          caché del navegador → del sistema → resolutor → autoritativo
  3. TCP o QUIC   saludo de transporte; con HTTP/3, integrado con el criptográfico
  4. TLS          ClientHello con SNI y ALPN → certificado → validación de cadena y nombre → claves
  5. HTTP         petición con Host/:authority; el servidor responde
  6. Respuesta    posiblemente desde un CDN, con Age; posiblemente 304 si había caché válida
  ```
- 🔬 Lo que distingue una respuesta buena de una correcta son los detalles que se mencionan al pasar:
  que ALPN decide ahí si se hablará HTTP/2 o HTTP/1.1; que SNI viaja en claro; que con TLS 1.3 el
  saludo cuesta un viaje y no dos; que el navegador puede no llegar a pedir nada si su caché está
  fresca; y que el `103 Early Hints` puede llegar antes que la respuesta final. Es la pregunta que
  mejor mide profundidad, porque se puede contar en dos minutos o en veinte.

**S40.** **Si tuvieras que explicarle HTTP a alguien que sabe programar pero nunca ha tocado la red, ¿por dónde empezarías y qué dejarías fuera? 🔴**

- ⏱️ Empezaría escribiendo una petición a mano por un socket, y dejaría fuera las versiones y casi
  toda la lista de encabezados.
- 🗣️ El orden que funciona: ver un mensaje real y entender sus cuatro partes; luego método y código de
  estado como un contrato con toda la red, no como una etiqueta; luego `Content-Type` y el cuerpo;
  y solo entonces caché, idempotencia y TLS. Fuera, de entrada: HTTP/2 y HTTP/3, la teoría de REST,
  las familias completas de encabezados y todo lo que sea memorizar listas.
- 🔬 El criterio detrás es que HTTP se entiende cuando se ve que **es texto y se puede escribir a
  mano**; a partir de ahí todo lo demás son capas encima de algo concreto. Empezar por el modelo OSI
  o por la tabla de códigos de estado es el error habitual: se aprende vocabulario sin haber visto
  nunca el objeto.

---

## Simulación — Escenarios

**E1 — El contrato de subida de facturas 🔴**

- ⏱️ URL prefirmada al almacenamiento para el binario, metadatos por la API, e idempotencia por hash
  del contenido. Los 50 MB no pasan por el servicio.
- 🗣️ El contrato:

  ```text
  1. POST /facturas/subidas          {pedido, fecha, centroCoste, sha256, tamaño}
     → 201 + {idSubida, urlDestino, expiraEn}   URL prefirmada, 15 minutos
  2. PUT <urlDestino>                el cliente sube el PDF directo al almacenamiento
  3. notificación del almacenamiento → el servicio valida y publica el evento
     GET /facturas/subidas/{id}      → estado: PENDIENTE | VALIDADA | RECHAZADA
  ```
  El paso 1 es idempotente por el `sha256` más el pedido: repetirlo devuelve la misma subida en vez
  de crear otra.
- 🔬 Las decisiones y su coste: **(a)** con 20 000 al día y picos de diez veces, el pico son unos 14
  documentos por segundo; si cada uno pasara por el servicio con 50 MB, serían cientos de megas en
  vuelo permanentes — esa aritmética es el argumento para la prefirmada, no la elegancia. **(b)** La
  validación es posterior a la subida, así que el contrato necesita el estado explícito del paso 3 y
  el cliente tiene que contemplar `RECHAZADA`. **(c)** Límites declarados en la documentación —50 MB,
  solo `application/pdf`, validado por los octetos iniciales y no por la extensión—, con `413` y
  `415` como respuestas. **(d)** Huérfanos: quien pide URL y no sube deja un registro `PENDIENTE` que
  caduca a las 24 horas, y eso se dice en el contrato. **(e)** Qué es norma y qué es nuestro: `PUT`,
  `201`, `Location`, `413`, `415` son norma; la URL prefirmada, el flujo en tres pasos y usar el
  `sha256` como clave de idempotencia son decisiones nuestras y hay que documentarlas porque ningún
  cliente puede deducirlas.

**E2 — El cobro duplicado 🔴**

- ⏱️ Los 28 segundos apuntan a un reintento por timeout: del cliente, del balanceador o de una cola.
  La corrección definitiva es una clave de idempotencia atómica.
- 🗣️ Las tres hipótesis, ordenadas, y su experimento:

  ```text
  1. REINTENTO DEL BALANCEADOR O DEL CLIENTE tras timeout (0,3 % encaja con la cola de picos)
     → comparar los 28 s con los timeouts configurados; buscar si llegan por la misma conexión
  2. REPROCESO DE UNA COLA con visibilidad vencida antes de confirmar
     → mirar si hay un consumidor de mensajes en el camino y su tiempo de visibilidad
  3. DOBLE ENVÍO DEL USUARIO (doble clic, sin bloqueo en la interfaz)
     → mirar si las dos peticiones traen el mismo identificador de sesión y de traza
  ```
- 🔬 La corrección definitiva: `Idempotency-Key` generada por **intento lógico** —no por reintento—,
  con la clave, su respuesta y el efecto del cobro **en la misma transacción**, y una restricción de
  unicidad que resuelva dos peticiones concurrentes con la misma clave. Y lo que **no** funciona,
  que es la mitad de la respuesta: subir el timeout —solo mueve el problema—, deduplicar por
  "mismo importe y mismo cliente en los últimos N segundos" —rompe los cobros legítimamente
  repetidos—, y desactivar los reintentos sin más, que cambia duplicados por pagos perdidos. Mientras
  tanto, hay que medir el alcance histórico y conciliar lo ya cobrado con el negocio.

**E3 — Los acentos del informe 🟠**

- ⏱️ El archivo va en UTF-8 y Excel en Windows lo abre con la página de códigos local. El servicio no
  ha cambiado porque el fallo nunca estuvo en el servicio.
- 🗣️ La cadena completa y dónde puede romperse:

  ```text
  base de datos → driver → aplicación → serialización CSV → HTTP → disco → Excel
        ↑            ↑         ↑              ↑              ↑              ↑
     cotejamiento  charset  String        codificación    charset      página de códigos
                  de conexión           al escribir     declarado      ← AQUÍ
  ```
  La pista decisiva es que dependa de la herramienta y no del usuario ni del dato: el archivo es
  idéntico para todos.
- 🔬 La corrección tiene tres piezas: **(1)** emitir el BOM de UTF-8 al principio, que es lo que hace
  que Excel detecte la codificación —es específico de una herramienta y es lo que funciona—; **(2)**
  declarar `Content-Type: text/csv; charset=utf-8`, que aquí sí es pertinente porque el CSV no lleva
  la codificación dentro, a diferencia de JSON; **(3)** `Content-Disposition: attachment` con nombre.
  Y la alternativa que conviene poner sobre la mesa: si el destinatario real es siempre Excel,
  exportar a `.xlsx` elimina la clase entera de problema. Antes de tocar nada, se confirma con `file`
  o un volcado hexadecimal que el archivo generado es UTF-8 — para no "arreglar" lo que ya estaba
  bien.

**E4 — La caída del domingo 🟠**

- ⏱️ Un certificado caducado. Lo dicen los tres síntomas: de madrugada, sin despliegue reciente, error
  de conexión segura desde fuera y todo sano por dentro.
- 🗣️ Los primeros cinco minutos, en orden:

  ```bash
  # 1. ¿Es el certificado? Treinta segundos y cierra o descarta la hipótesis principal
  echo | openssl s_client -connect api.ejemplo.com:443 -servername api.ejemplo.com 2>/dev/null \
    | openssl x509 -noout -dates -subject

  # 2. ¿Llega la cadena completa? El segundo sospechoso
  echo | openssl s_client -connect api.ejemplo.com:443 -servername api.ejemplo.com -showcerts 2>/dev/null \
    | grep "^ *[0-9] s:"

  # 3. ¿Es solo un nodo? Repetir contra cada instancia por IP, con -servername
  # 4. ¿Qué dice el balanceador? Errores de handshake, que NO aparecen como errores HTTP
  ```
- 🔬 Por qué se sospecha eso antes de mirar: los certificados caducan a una hora exacta,
  independiente del tráfico y del despliegue, y "once días sin desplegar" descarta el cambio
  reciente; que el tráfico interno funcione sitúa el fallo en el borde; y "error de conexión segura"
  es literalmente el síntoma. La segunda hipótesis es una renovación que sí ocurrió pero que no se
  recargó en todos los nodos — de ahí el paso 3, que es el que distingue "caducó" de "se renovó a
  medias". Y la lección permanente: esto se evita monitorizando **el certificado que sirve el
  endpoint**, sondeado desde fuera, con alerta a 30 días.

**E5 — El seguimiento en vivo 🔴**

- ⏱️ SSE sobre HTTP/2, con identificadores de evento, historial corto por pedido y un bus de
  publicación detrás de las cuatro instancias.
- 🗣️ Por qué no los otros tres: **sondeo**, porque 50 000 clientes preguntando cada pocos segundos es
  un ataque de denegación de servicio autoinfligido; **sondeo largo**, porque consume una conexión
  igual que SSE sin darte reconexión ni continuidad; **WebSocket**, porque el flujo es
  unidireccional y pagarías estado en la instancia, reconexión propia, latidos manuales y afinidad de
  sesión a cambio de nada. SSE es HTTP, atraviesa los proxies corporativos como cualquier respuesta, y
  el navegador reconecta solo.
- 🔬 El diseño completo: cada evento lleva un `id` incremental por pedido; al reconectar, el navegador
  manda `Last-Event-ID` y el servidor **reenvía lo ocurrido desde ese punto** desde un historial de
  diez minutos — sin eso, una desconexión produce un hueco silencioso, que es el fallo que nadie
  detecta en pruebas. Las cuatro instancias no guardan estado: se suscriben a un bus, así que
  cualquiera puede atender cualquier reconexión. Un comentario de latido cada 20 segundos evita que
  los proxies que cortan conexiones inactivas maten el flujo. Y sobre los clientes corporativos tras
  proxies agresivos: si aun con latidos cortan, la caída elegante es sondeo con `ETag` cada 10
  segundos para esa minoría, que degrada la experiencia sin romperla.

**E6 — Lo que el protocolo no resuelve 🔴**

- ⏱️ HTTP no puede garantizar exactly-once, y ningún diseño REST lo cambia: lo que se consigue es
  at-least-once más una operación idempotente, cuyo **efecto observable** es el que pide.
- 🗣️ El argumento, ordenado: sobre una red que puede perder mensajes, el emisor nunca distingue "no
  llegó" de "llegó y se perdió la respuesta" — es el problema de los dos generales, y está demostrado
  que no tiene solución con un número acotado de mensajes. Por tanto solo hay dos opciones: no
  reintentar, y entonces se pueden perder órdenes; o reintentar, y entonces pueden llegar repetidas.
  `PUT` y `Idempotency-Key` no eliminan la repetición: hacen que **repetir sea inofensivo**, que es
  otra cosa y es justo lo que él quiere.
- 🔬 Qué hay que añadir por encima: la clave de idempotencia y el efecto en la **misma transacción**;
  una ventana de retención de la clave acordada por contrato —y decir explícitamente qué pasa pasada
  esa ventana—; unicidad en el almacén de claves para las carreras; un estado consultable de la orden
  para que el emisor pueda preguntar en vez de reintentar a ciegas; y una conciliación periódica entre
  los dos sistemas, que es la red de seguridad que ningún diseño elimina. Y cómo se lo diría: *"Lo
  que pides se consigue, y así es como lo vamos a conseguir; lo que no existe es una garantía de
  entrega única a nivel de protocolo, ni en HTTP ni en ninguna otra cosa que te ofrezcan. Quien te
  diga que su sistema hace exactly-once está haciendo exactamente esto por debajo y llamándolo de
  otra forma."* Esa última frase es la que convierte un "no se puede" en una propuesta.

---

**Anterior:** [`07` — Simulación de entrevista](07-simulacion-de-entrevista.md) ·
**Índice:** [README](README.md)
