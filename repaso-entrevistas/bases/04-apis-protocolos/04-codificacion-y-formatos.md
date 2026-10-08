# 04 — Codificación y formatos

> Cómo se declara qué es un cuerpo (tipos de medio), cómo se mete un binario por un canal pensado
> para texto (Base64, y cuánto cuesta exactamente), cómo se envían varias piezas en un mismo mensaje
> (`multipart/form-data`, capturado del cable), y las dos codificaciones que todo el mundo confunde:
> la de caracteres y la de URL.
>
> Todas las medidas de este capítulo están **ejecutadas**, no estimadas.
>
> **Vigencia:** 2026-09-17. · **Requisito:** [`02` — El mensaje](02-el-mensaje-y-los-encabezados.md).

---

## 1. 🎯 El problema

Hay que subir una factura en PDF junto con el identificador del pedido. Las tres opciones que se
proponen siempre en la reunión:

```text
A)  JSON con el PDF en Base64          { "pedido": "PED-00042", "archivo": "JVBERi0x…" }
B)  multipart/form-data                 dos partes en un solo cuerpo
C)  dos peticiones: metadatos + binario  POST /pedidos + PUT del contenido
```

Las tres funcionan. Elegir bien exige saber **cuánto cuesta cada una**, y ese número casi nadie lo
tiene: la opción A infla el cuerpo un **33 % exacto** y —esto sorprende— la compresión **no siempre
lo recupera**. La sección 4 lo mide. Debajo hay una cadena de preguntas que este capítulo ordena:
cómo se declara el formato, cómo se acuerda, cómo se empaqueta lo binario y dónde se pierden los
acentos.

> **Veredicto:** un cuerpo mal declarado o mal codificado no falla ruidosamente. Llega, se parsea a
> medias y produce datos corruptos que se descubren semanas después. Es la clase de bug más cara del
> protocolo.

---

## 2. 🧱 Tipos de medio

**Qué es.** El **tipo de medio** —lo que casi todo el mundo llama *tipo MIME*, por su origen en el
correo electrónico— es la etiqueta que dice qué es un cuerpo. Su sintaxis:

```text
application/json; charset=utf-8
└─────────┘ └──┘  └───────────┘
   tipo    subtipo   parámetro
```

- **El tipo, el subtipo y los nombres de parámetro no distinguen mayúsculas**; el valor de un
  parámetro sí, salvo donde su definición diga lo contrario.
- **Sin el tipo de medio no hay nada que parsear**: es lo que convierte una ristra de octetos en un
  documento, y por eso `Content-Type` es el encabezado más importante del cuerpo.
- **El catálogo vive en IANA, no en un RFC.** El mecanismo lo define la norma; los tipos concretos se
  registran, y ahí se comprueba si uno existe antes de inventárselo.

**Los tipos que hay que reconocer:**

| Tipo de medio | Qué es | Dónde aparece |
|---|---|---|
| `application/json` | JSON | El 90 % de las APIs |
| `application/problem+json` | Error estructurado (RFC 9457) | Respuestas de error |
| `text/plain`, `text/html`, `text/csv` | Texto | Web y exportaciones |
| `application/x-www-form-urlencoded` | Formulario simple, como una query string | Formularios HTML |
| `multipart/form-data` | Varias partes, incluidos binarios | Subida de archivos |
| `application/octet-stream` | "Bytes, no sé de qué" | Descarga genérica |
| `application/pdf`, `image/png` | Binarios concretos | Adjuntos |
| `text/event-stream` | Server-Sent Events | Tiempo real, capítulo `06` |

**Los dos sufijos y el árbol de proveedor**, que se preguntan:

```text
application/vnd.ejemplo.pedido+json    vnd. = árbol de proveedor; +json = "se parsea como JSON"
application/vnd.ejemplo.pedido.v2+json versión del contrato dentro del propio tipo
```

- **El sufijo `+json` es lo que salva al cliente genérico**: cualquier herramienta sabe parsearlo sin
  conocer el tipo concreto, y sin él todos lo tratan como opaco. El árbol `vnd.` es el espacio de
  nombres de una organización, y la alternativa correcta a inventar `application/pedido`.
- **Versionar la API dentro del tipo de medio** es una de las opciones clásicas; se compara con las
  demás en `repaso-spring-entrevistas`, que trata el versionado de contratos.

> ⚠️ **`charset` solo aplica a texto**, y en `application/json` es redundante: RFC 8259 obliga a que
> JSON intercambiado entre sistemas sea **UTF-8**. Mandar `charset=utf-8` no está mal, pero declarar
> `charset=iso-8859-1` en JSON es declarar algo que la norma no permite.

---

## 3. 🧱 Negociación de contenido

El mismo recurso puede servirse en varias formas —JSON o CSV, español o inglés, comprimido o no—, y
el reparto es: el cliente expresa preferencias, el servidor decide.

```text
Accept: application/json;q=0.9, text/csv;q=1.0, */*;q=0.1
Accept-Language: es-CO, es;q=0.8, en;q=0.5
Accept-Encoding: gzip, br
```

- **`q` es un factor de calidad entre 0 y 1**; si se omite vale 1. Es una **preferencia, no una
  orden**: el servidor puede servir algo que no estaba pedido, o responder `406 Not Acceptable`.
- **`es-CO, es;q=0.8`** dice: prefiero español de Colombia, me vale cualquier español, y en inglés
  como último recurso. Es la forma correcta de pedir una variante regional sin excluir la general.
- **Toda respuesta negociada necesita `Vary`.** Si varía por idioma, `Vary: Accept-Language`. Sin eso,
  la primera respuesta cacheada se sirve a todo el mundo — el bug del capítulo `02`.

**Cuándo no negociar.** En una API interna entre servicios suele ser ceremonia: se fija JSON y se
acabó. Vale la pena con clientes que no controlas, con varios formatos de exportación o cuando el
idioma de los errores importa.

> 📝 **Frontera.** La configuración de la negociación en el servidor —convertidores de mensaje,
> `produces`/`consumes`, resolución por extensión o por parámetro— se trata en
> `repaso-spring-entrevistas`. Aquí queda el mecanismo del protocolo.

---

## 4. 🧱 Por qué existe Base64

**El problema.** Hay que meter bytes arbitrarios por un canal que solo garantiza texto.

**De dónde viene.** El correo de los años ochenta era de **7 bits**: el octavo no sobrevivía el
tránsito y ciertas secuencias —un punto solo en una línea, un `CR` suelto— eran de control. Adjuntar
una imagen exigía traducirla a un alfabeto seguro. Eso es MIME, y de ahí sale Base64.

```text
3 octetos = 24 bits   →   4 grupos de 6 bits   →   4 caracteres del alfabeto de 64
```

- El alfabeto son `A–Z`, `a–z`, `0–9` y dos símbolos: `+` y `/` en el estándar, o `-` y `_` en la
  variante **URL-safe**, porque `+` y `/` tienen significado dentro de una URL.
- **`=` es relleno**, para completar el último grupo cuando la entrada no es múltiplo de tres.
- De ahí el coste: **cuatro caracteres por cada tres octetos**, exactamente **+33 %**.

**Medido, no estimado** —3 000 octetos aleatorios y un documento de texto de 18 622 octetos—:

```text
                crudo     base64   gzip(crudo)  gzip(base64)
binario         3 000      4 000       3 031        3 061      ← +1 % sobre gzip del crudo
texto          18 622     24 832       7 760       11 071      ← +43 % sobre gzip del crudo
```

Y esto es lo que casi nadie sabe decir:

- **Con datos ya comprimidos —un JPEG, un PDF, un ZIP—, gzip recupera casi todo el sobrecoste de
  Base64** (+1 %). La objeción de "Base64 infla un tercio" es, en ese caso, casi falsa en el cable.
- **Con datos comprimibles, Base64 destroza la compresión**: de 7 760 a 11 071 octetos, **un 43 %
  más**. Al pasar por el alfabeto de 64, los patrones que gzip explotaba dejan de alinearse con los
  límites de octeto.
- **El coste que no se ve es el de memoria y CPU**: codificar, decodificar y sostener el documento
  entero en memoria como cadena, a menudo dos veces. En un servicio que recibe archivos de decenas de
  megas, eso —y no los bytes del cable— es lo que tira el servicio.

**Cuándo sí.** Piezas pequeñas dentro de un documento de texto: una firma, una clave, un certificado
en PEM —Base64 con cabeceras—, un JWT —tres partes en Base64 URL-safe—, una imagen diminuta en un
`data:` URI. **Cuándo no:** archivos grandes; ahí van `multipart` o un `PUT` del binario directo.

> ⚠️ **Base64 no es cifrado ni es seguridad.** Es una codificación reversible sin clave. `Basic` de
> HTTP Basic Auth es Base64 del usuario y la contraseña, y por eso **es texto plano a efectos
> prácticos** y solo tiene sentido dentro de TLS. Confundir codificar con cifrar es de las respuestas
> que descartan a un candidato senior.

---

## 5. 🧱 `multipart`: varias piezas, un cuerpo

**Qué es.** Un cuerpo que contiene varios cuerpos, cada uno con sus propios encabezados, separados
por una cadena delimitadora. También viene de MIME.

**Cómo se ve de verdad.** Esta captura es del socket, con `nc` escuchando y `curl` enviando:

```bash
# En una terminal: escuchar y volcar lo que llegue, sin interpretar nada
nc -l 8099 > captura.txt

# En otra: un campo de texto y un archivo con su tipo declarado
curl -F "pedido=PED-00042" -F "archivo=@factura.pdf;type=application/pdf" http://127.0.0.1:8099/
```

- `nc -l 8099` abre un socket de escucha: hace de servidor tonto, y sirve para ver los bytes exactos.
- `-F` hace que `curl` use `multipart/form-data` y genere la frontera; `@` significa "esto es un
  archivo", y `;type=` fija el tipo de esa parte —sin él, `curl` pondría `application/octet-stream`.

```text
POST / HTTP/1.1
Host: 127.0.0.1:8099
Content-Length: 349
Content-Type: multipart/form-data; boundary=------------------------TkNf5CfQUimXQgGMD6Dlhn

--------------------------TkNf5CfQUimXQgGMD6Dlhn
Content-Disposition: form-data; name="pedido"

PED-00042
--------------------------TkNf5CfQUimXQgGMD6Dlhn
Content-Disposition: form-data; name="archivo"; filename="factura.pdf"
Content-Type: application/pdf

%PDF-1.4 contenido de ejemplo

--------------------------TkNf5CfQUimXQgGMD6Dlhn--
```

Todo lo que hay que saber leer ahí:

- **La frontera se declara en `Content-Type` y se usa con dos guiones delante** —por eso la línea del
  cuerpo tiene dos guiones más que el valor del encabezado—, y **la última los lleva también al
  final**, que es lo que cierra el cuerpo.
- **La frontera la elige el cliente y debe ser una cadena que no aparezca en ningún dato** —de ahí la
  parte aleatoria que mete `curl`—. Si apareciera, el cuerpo quedaría partido por la mitad: es de las
  pocas partes de HTTP que **dependen de que no haya colisión**, y por eso no se escribe a mano.
- **Cada parte lleva sus propios encabezados**, y ahí está la ventaja frente a Base64: el binario
  viaja **tal cual**, sin sobrecoste, con su tipo declarado por separado.
- **`Content-Disposition: form-data; name=…`** identifica la parte; `filename` es el nombre original
  del archivo — **y es entrada del usuario**, así que jamás se usa como ruta en disco sin sanear. Ese
  es el *path traversal* clásico de las subidas.

**El mismo encabezado en la respuesta**, con otro significado: `Content-Disposition: attachment;
filename="factura.pdf"` le dice al navegador que descargue en vez de mostrar. Está en RFC 6266, y es
la forma correcta de forzar una descarga.

**Cuándo cada opción:**

| Situación | Elección |
|---|---|
| Archivo grande, solo el archivo | `PUT` del binario con su `Content-Type` |
| Archivo + metadatos en una operación | `multipart/form-data` |
| Binario pequeño dentro de un documento | Base64 en el JSON |
| Muchos archivos, clientes móviles, reanudación | URL prefirmada al almacenamiento de objetos |

> 💡 **La respuesta que suma en entrevista.** *"Para archivos grandes, ni Base64 ni `multipart` por mi
> API: emito una URL prefirmada y el cliente sube directo al almacenamiento de objetos. Mi servicio
> no toca los bytes, no le cuestan memoria y el archivo no atraviesa el servicio."* Eso sale de los
> repasos de AWS y GCP y es lo que se hace en producción.

---

## 6. 🧱 Las dos codificaciones que se confunden

Se llaman parecido y no tienen nada que ver.

**Codificación de caracteres** — de texto a octetos.

```text
"ñ"   UTF-8 → C3 B1   (2 octetos)     ISO-8859-1 → F1   (1 octeto)
"€"   UTF-8 → E2 82 AC (3 octetos)    ISO-8859-1 → no existe
```

- **UTF-8 es la respuesta por defecto** y en JSON es obligatoria: ASCII ocupa un octeto —compatible
  hacia atrás— y el resto de dos a cuatro.
- **El `?` o la `Ã±` en pantalla son el mismo error**: alguien leyó octetos UTF-8 como Latin-1, y la
  corrupción ocurre **donde se hizo mal la conversión**, no donde se ve.
- **Longitud no es número de octetos**: un límite de "255 caracteres" no es de 255 octetos, y el
  emoji ocupa cuatro — el capítulo de strings de `repaso-bases-entrevistas` lo desarrolla.

**Codificación porcentual** — de octetos a caracteres seguros en una URI, definida en RFC 3986.

```text
/buscar?q=camión pequeño   →   /buscar?q=cami%C3%B3n%20peque%C3%B1o
```

- Se codifica **cada octeto** de la representación UTF-8, no el carácter: por eso `ó` son dos grupos.
- **Los reservados —`? & = / # + espacio`— se codifican cuando forman parte de un valor y no de la
  estructura.** Un `&` sin codificar parte el parámetro en dos: la inyección accidental más común.
- **`+` significa espacio solo en `application/x-www-form-urlencoded`**, no en el resto de la URI.
  Esa asimetría rompe muchas firmas de petición y muchos filtros de búsqueda.
- **El fragmento `#…` nunca se envía al servidor.** Vive en el cliente. Buscar un `#` en los logs de
  acceso no lo encontrará nunca.

---

## 7. 🧱 Compresión

```text
Accept-Encoding: gzip, br      el cliente dice qué sabe descomprimir
Content-Encoding: gzip         el servidor dice qué aplicó
Vary: Accept-Encoding          obligatorio si hay caché de por medio
```

- **`gzip` es el suelo universal; `br` (Brotli) comprime más** a cambio de CPU, y `zstd` gana terreno
  por su relación velocidad/ratio.
- **El texto se comprime entre tres y diez veces**, y el JSON está en la parte alta por repetitivo:
  en la medida de la sección 4, un documento pasó de 18 622 a 7 760 octetos.
- **Lo ya comprimido no se recomprime**: JPEG, PNG, PDF moderno, ZIP. Gastas CPU para no ganar nada.
- **Comprimir respuestas que mezclan un secreto con entrada del usuario tiene riesgo real**: BREACH y
  CRIME deducen el secreto observando cómo cambia el tamaño comprimido. El capítulo `05` lo retoma.

---

## 8. 📜 Lo que dice la norma

| Afirmación | Fuente | ¿Obliga o es convención? |
|---|---|---|
| El tipo y el subtipo no distinguen mayúsculas | RFC 9110 §8.3.1 | **Norma** |
| El catálogo de tipos de medio lo mantiene IANA | RFC 6838 | **Norma** |
| Base64 usa 4 caracteres por cada 3 octetos | RFC 4648 §4 | **Norma** (de ahí el +33 %) |
| Existe una variante URL-safe con `-` y `_` | RFC 4648 §5 | **Norma** |
| JSON intercambiado entre sistemas **MUST** ser UTF-8 | RFC 8259 §8.1 | **Norma** |
| `multipart/form-data` y su `Content-Disposition` | RFC 7578 | **Norma** |
| `Content-Disposition: attachment` para forzar descarga | RFC 6266 | **Norma** |
| La codificación porcentual se aplica a octetos UTF-8 | RFC 3986 §2.5 | **Norma** |
| `+` es espacio solo en formularios urlencoded | Especificación HTML | **Norma**, de otra norma |
| El prefijo `vnd.` para tipos de organización | RFC 6838 | **Norma** |
| Mandar `charset=utf-8` en `application/json` | Ninguna; es redundante | **Convención** |
| Usar `application/octet-stream` cuando no se sabe | RFC 9110 | **Convención razonable** |

---

## 9. 🔭 Dónde aparece de verdad

En la subida de archivos que funciona en pruebas y tira el servicio con un PDF de 40 MB porque iba
en Base64; en los acentos rotos que aparecen solo en los datos que vienen del formulario antiguo; en
la búsqueda que falla cuando el término lleva `&`; en la respuesta que se sirve comprimida a un
cliente que no lo pidió porque faltaba `Vary`; en la integración que rechaza tu JSON por un
`Content-Type` sin declarar; y en la entrevista, donde *"¿cómo subes un archivo por una API?"* —la
pregunta que le hicieron al autor de este corpus— se responde mal si solo se conoce una de las tres
opciones.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Base64 es una forma de seguridad" | Es codificación reversible sin clave. No protege nada |
| "Base64 siempre infla un 33 % en el cable" | En datos ya comprimidos, gzip recupera casi todo (+1 % medido) |
| "gzip arregla el coste de Base64" | En datos comprimibles lo empeora: +43 % sobre el gzip del crudo |
| "MIME type" | El nombre actual es **tipo de medio**; MIME es su origen en el correo |
| "Pongo `charset` en el JSON por si acaso" | RFC 8259 ya obliga a UTF-8; es redundante |
| "La frontera de `multipart` la elijo yo" | La genera el cliente, y **debe** no aparecer en los datos |
| "Uso `filename` para guardar el archivo" | Es entrada del usuario: *path traversal* directo |
| "Codificación de caracteres y de URL son lo mismo" | Una va de texto a octetos; la otra de octetos a caracteres seguros |
| "`+` es espacio en las URLs" | Solo en `x-www-form-urlencoded`; en el resto es un carácter |
| "Comprimo todo, siempre" | No lo ya comprimido, y con cuidado si mezclas secretos con entrada del usuario |

---

## 📚 Para profundizar

- **RFC** — [RFC 9110 §8 — *Representations*](https://www.rfc-editor.org/rfc/rfc9110.html#section-8):
  `Content-Type`, `Content-Encoding`, `Content-Language` y la negociación, en la fuente.
- **RFC** — [RFC 4648 — *The Base16, Base32, and Base64 Data Encodings*](https://www.rfc-editor.org/rfc/rfc4648.html):
  el alfabeto, el relleno y la variante URL-safe. Quince páginas y se entiende entero.
- **RFC** — [RFC 7578 — *Returning Values from Forms: multipart/form-data*](https://www.rfc-editor.org/rfc/rfc7578.html):
  la norma de las subidas, con sus advertencias sobre la frontera y el nombre de archivo.
- **RFC** — [RFC 6266 — *Use of the Content-Disposition Header Field*](https://www.rfc-editor.org/rfc/rfc6266.html):
  cómo se fuerza una descarga y cómo se envía un nombre con acentos.
- **RFC** — [RFC 3986 §2 — *Characters*](https://www.rfc-editor.org/rfc/rfc3986.html#section-2): reservados,
  no reservados y codificación porcentual. La referencia para las discusiones de URL.
- **RFC** — [RFC 8259 — *The JSON Data Interchange Format*](https://www.rfc-editor.org/rfc/rfc8259.html):
  seis páginas, y la que obliga a UTF-8.
- **Registro** — [IANA — Media Types](https://www.iana.org/assignments/media-types/media-types.xhtml):
  el catálogo. Antes de inventar un tipo propio, se mira aquí.
- **Artículo** — [Joel Spolsky — *The Absolute Minimum Every Software Developer Must Know About
  Unicode*](https://www.joelonsoftware.com/2003/10/08/the-absolute-minimum-every-software-developer-absolutely-positively-must-know-about-unicode-and-character-sets-no-excuses/):
  de 2003 y sigue siendo la mejor explicación de por qué se rompen los acentos.
- **Referencia** — [MDN — MIME types](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/MIME_types):
  la lista práctica de los tipos que se usan a diario.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Qué es un tipo de medio y qué partes tiene? 🟢
2. ¿Quién mantiene el catálogo de tipos de medio? 🟢
3. ¿Qué es Base64 y para qué sirve? 🟢
4. ¿Cuánto infla Base64 y por qué exactamente ese número? 🟢
5. ¿Es Base64 una medida de seguridad? 🟢
6. ¿Qué es `multipart/form-data` y para qué se usa? 🟢
7. ¿Qué encabezado fuerza la descarga de un archivo en el navegador? 🟢
8. ¿Qué codificación de caracteres exige JSON? 🟢
9. ¿Qué significa el sufijo `+json` en un tipo de medio propio? 🟡
10. ¿Para qué sirve el árbol `vnd.`? 🟡
11. ¿Qué son los valores `q` en `Accept` y qué pasa si se omiten? 🟡
12. ¿Qué hay que añadir a una respuesta negociada para no romper las cachés? 🟡
13. ¿Cómo funciona la frontera de un `multipart` y quién la elige? 🟡
14. ¿Qué riesgo tiene usar el `filename` de una parte para guardar el archivo? 🟡
15. Diferencia codificación de caracteres y codificación porcentual. 🟡
16. ¿Cuándo `+` significa espacio en una URL y cuándo no? 🟡
17. ¿Por qué el fragmento `#…` no aparece en los logs del servidor? 🟡
18. ¿Recupera gzip el sobrecoste de Base64? Responde con datos. 🟠
19. ¿Cuál es el coste de Base64 que **no** se ve en el cable? 🟠
20. ¿Por qué `charset=utf-8` es redundante en `application/json`? 🟠
21. Un texto llega como `Ã±` en vez de `ñ`. Diagnostica dónde está el fallo. 🟠
22. Un buscador falla cuando el término lleva `&`. ¿Qué pasó y cómo se arregla? 🟠
23. ¿Qué tiene que ver la compresión con BREACH y qué regla se sigue? 🟠
24. ¿Cuándo es defendible enviar Base64 dentro de un JSON pese a su coste? Da dos casos y el
    umbral que usarías. 🟠
25. Hay que subir una factura de 40 MB con metadatos. Compara las cuatro opciones y elige,
    justificando el coste de memoria. 🔴
26. Diseña el contrato de un endpoint de subida: tipo de medio, límites, validación del nombre,
    respuesta de error y qué se declara en `Vary`. 🔴
27. Escribe el intercambio completo de una subida `multipart` con dos partes, incluidos los
    encabezados de cada parte, y señala qué validarías en el servidor y por qué. 🔴
28. Un informe exportado en CSV llega con los acentos rotos solo a los usuarios de Windows.
    Diagnostica y escribe la corrección, incluido lo que declararías en la respuesta. 🔴

---

**Anterior:** [`03` — Métodos, semántica e idempotencia](03-metodos-semantica-e-idempotencia.md) ·
**Siguiente:** [`05` — TLS y seguridad del transporte](05-tls-y-seguridad-del-transporte.md)
