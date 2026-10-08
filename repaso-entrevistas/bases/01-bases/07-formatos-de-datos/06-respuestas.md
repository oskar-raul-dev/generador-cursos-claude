# 06 — Respuestas

> Solucionario centralizado del bloque `07-formatos-de-datos`. Cada respuesta en tres capas:
> **⏱️ 30 segundos**, **🗣️ 2 minutos** y **🔬 El detalle**. Los enunciados están copiados
> literalmente de su capítulo.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:**
[01](#01--json) · [02](#02--xml-y-los-esquemas) · [03](#03--yaml) ·
[04](#04--csv-y-los-formatos-tabulares) ·
[05 — transversales](#05--simulación-preguntas-transversales) ·
[05 — pizarra](#05--simulación-problemas-de-pizarra)

---

# 01 — JSON

**01 → 1. ¿Cuántos tipos tiene JSON y cuáles son?**

⏱️ Seis: objeto, array, cadena, número, booleano y nulo.
🗣️ Esa lista es toda la gramática, y por eso hay parser de JSON en cualquier lenguaje. Lo importante
no es memorizarla sino lo que **no** está: no hay fecha, no hay distinción entre entero y decimal, no
hay binario y no hay comentarios.
🔬 Está definido dos veces y a propósito de forma compatible: RFC 8259 en el IETF y ECMA-404. Las
claves de un objeto son siempre cadenas, y el orden de las claves no está garantizado por la norma
aunque casi todas las bibliotecas lo conserven.

**01 → 2. ¿Tiene JSON un tipo fecha?**

⏱️ No. Las fechas viajan como cadena, normalmente en ISO-8601.
🗣️ `"2026-09-18T14:30:00Z"` es texto para JSON: quien decide que eso es una fecha es el contrato
entre las dos partes y el código que lo deserializa.
🔬 De ahí salen tres problemas reales: cada biblioteca parsea un subconjunto distinto de ISO-8601;
la zona horaria se pierde si no se escribe; y hay quien manda milisegundos desde época, que es un
número y arrastra el problema de precisión de la pregunta 9. Lo que se escribe en el contrato es el
formato exacto, no "una fecha".

**01 → 3. ¿Qué diferencia hay entre entero y decimal en JSON?**

⏱️ Ninguna: hay un solo tipo `number`.
🗣️ La distinción la inventa la biblioteca al deserializar. Jackson sube a `Long` o `BigInteger` según
quepa; Python usa `int` o `float` según haya punto; Go mete todo en `float64` salvo que se lo
impidas.
🔬 La norma ni siquiera fija la precisión: RFC 8259 §6 se limita a decir que la interoperabilidad
máxima se consigue quedándose en lo que un `double` IEEE 754 representa exactamente. Todo lo demás
es acuerdo entre implementaciones.

**01 → 4. ¿Por qué JSON no admite comentarios?**

⏱️ Porque su autor los quitó a propósito.
🗣️ El motivo que dio es que la gente los usaba para meter directivas de parseo, y eso convierte un
formato de datos en un lenguaje con dialectos incompatibles.
🔬 La consecuencia práctica es que **la configuración se mudó a YAML**: un archivo que va a leer y
editar una persona necesita explicarse. Las variantes con comentarios —JSON5, JSONC— existen pero no
son JSON, y un parser conforme las rechaza.

**01 → 5. ¿Cómo se envía un binario dentro de un JSON y qué cuesta?**

⏱️ En Base64 dentro de una cadena, con un 33 % más de tamaño.
🗣️ Tres octetos se convierten en cuatro caracteres, de ahí la proporción exacta. Con contenido ya
comprimido —un PDF, un JPEG— gzip recupera casi todo ese sobrecoste en el cable.
🔬 **El coste caro no es el cable, es la memoria**: el documento entero queda en memoria como cadena
y otra vez como binario decodificado. Por eso un servicio que va bien con adjuntos pequeños se cae
con uno grande, y por eso los archivos grandes van por `multipart` o por una URL prefirmada al
almacenamiento de objetos.

**01 → 6. ¿Qué son las dos formas de parsear un documento?**

⏱️ Árbol, que construye el documento entero en memoria, y flujo, que emite un token cada vez.
🗣️ El árbol es cómodo —se navega en los dos sentidos, admite consultas— y el flujo es un bucle sin
marcha atrás donde tú decides qué guardas.
🔬 La elección es de memoria y no de velocidad: los dos son `O(n)` en tiempo. El árbol cuesta del
orden de ocho veces el tamaño del archivo; el flujo, lo que tú acumules. En XML esos dos modos se
llaman DOM y SAX/StAX, y es la misma decisión.

**01 → 7. ¿Qué devuelve `JSON.parse` en TypeScript?**

⏱️ `any`. No hay ninguna comprobación de tipos.
🗣️ Por eso un `as Pedido` compila sin error aunque el documento traiga un número donde se esperaba
una cadena: el `as` es una afirmación del programador, no una verificación.
🔬 Verificado: `JSON.parse('{"id": 42, "total": "cien"}') as Pedido` pasa `tsc --strict --noEmit` sin
un solo error, y en ejecución `p.total.toFixed` es `undefined`. Lo que cierra el agujero es un
validador en tiempo de ejecución —Zod, io-ts, un esquema— en la frontera del sistema.

**01 → 8. ¿Qué norma define JSON?**

⏱️ RFC 8259 en el IETF, y ECMA-404, que son compatibles a propósito.
🗣️ RFC 8259 es **Internet Standard** y obsoleta a RFC 7159, que a su vez había obsoletado a RFC 4627.
Es de las normas más cortas que existen: seis páginas, y se lee entera en un café.
🔬 La sección que importa es la 6, *Numbers*, que es donde avisa de los `2^53` sin imponer ningún
límite. Y la 8.1, que obliga a UTF-8 para el JSON intercambiado entre sistemas — por eso declarar
`charset` en `application/json` es redundante.

**01 → 9. ¿Por qué un identificador grande llega cambiado a JavaScript?**

⏱️ Porque el tipo `number` de JavaScript es un `double` IEEE 754 y no representa todos los enteros
por encima de `2^53`.
🗣️ El parser no falla ni avisa: redondea al `double` más cercano, que es lo que se le pide. Desde su
punto de vista no ha ocurrido nada anómalo.
🔬 Verificado: `JSON.parse('{"id": 9007199254740993}').id` devuelve `9007199254740992`. No aparece en
pruebas porque los identificadores pequeños funcionan; aparece cuando la tabla crece, o con marcas
de tiempo en nanosegundos, o con identificadores de redes sociales, o con números de cuenta largos.

**01 → 10. ¿Cuál es el valor exacto a partir del cual empieza el problema y por qué ese?**

⏱️ `9007199254740991`, que es `2^53 - 1`, el `Number.MAX_SAFE_INTEGER` de JavaScript.
🗣️ Un `double` de 64 bits dedica 52 bits a la mantisa más un bit implícito: 53 bits de precisión.
Hasta ese valor, cada entero tiene su propia representación; a partir de ahí hay enteros que
comparten representación con su vecino.
🔬 "Seguro" significa exactamente eso: que `n` y `n+1` son distinguibles. Por encima, `2^53` y
`2^53 + 1` son el mismo `double`, que es justo el caso de la pregunta anterior.

**01 → 11. ¿Por qué Python y Java no sufren ese problema?**

⏱️ Porque no están obligados a usar coma flotante para los enteros.
🗣️ Python tiene enteros de precisión arbitraria: no tiene que elegir tipo, le caben todos. Jackson
elige el tipo más pequeño donde quepa el número y sube a `Long` o `BigInteger` cuando hace falta.
🔬 Verificado con el mismo documento: Python devuelve `9007199254740993` como `int`, y Jackson lo
devuelve como `Long` tanto en un `Map` como en el árbol. Pero ojo con el decimal: `0.1` en Java sigue
siendo un `double` salvo que pidas `decimalValue()`, con lo que el problema de dinero de
`06-numeros-tiempo-concurrencia` sigue vigente.

**01 → 12. ¿Por qué Go sí lo sufre, y cómo se evita?**

⏱️ Porque al deserializar en `interface{}` todo número cae en `float64`. Se evita con
`decoder.UseNumber()`.
🗣️ Es una decisión de diseño, no un descuido: sin tipo destino, la biblioteca tiene que elegir uno, y
eligió el que cubre todo el rango de JSON aunque pierda precisión en los extremos.
🔬 Verificado: por defecto `9007199254740993` llega como `9.007199254740992e+15`; con `UseNumber()`
llega como `json.Number`, que es una cadena que tú conviertes cuando decides el tipo. Si
deserializas en un `struct` con un campo `int64`, tampoco hay problema: el caso malo es solo el mapa
genérico.

**01 → 13. ¿Cuánta memoria cuesta parsear a árbol frente a parsear en flujo?**

⏱️ El árbol cuesta del orden de ocho veces el tamaño del archivo; el flujo, prácticamente nada.
🗣️ No es un defecto de ninguna biblioteca: un objeto con tres claves ocupa mucho más como estructura
de datos —cabeceras, punteros, cadenas— que como texto.
🔬 Medido con un archivo de 30 MB y 400 000 objetos: en Java, línea base de la JVM 42 MB, árbol
`readTree` 323 MB, flujo con `JsonParser` 99 MB. En Python, línea base 14 MB y `json.load` 225 MB.
Ese factor de entre cinco y diez es la cifra que hay que llevar a una entrevista.

**01 → 14. ¿Qué hace Go con un campo que no está en el `struct`? ¿Y Jackson?**

⏱️ Go lo ignora en silencio; Jackson lanza `UnrecognizedPropertyException` por defecto.
🗣️ Son las dos filosofías opuestas ante la evolución de un contrato: una permite que el productor
despliegue antes que el consumidor, la otra convierte cada campo nuevo en una incidencia.
🔬 Verificado con `{"a":1,"desconocido":9}`: Go devuelve `{A:1}` con `err = nil`; Jackson falla con
*"Unrecognized field \"desconocido\" … not marked as ignorable"*. En Java se cambia con
`FAIL_ON_UNKNOWN_PROPERTIES` a `false`, y es de las primeras decisiones de un contrato entre
servicios. Go ofrece el camino contrario con `DisallowUnknownFields()`.

**01 → 15. ¿Qué es un *tolerant reader*?**

⏱️ Un consumidor que ignora lo que no entiende en lugar de fallar.
🗣️ Es lo que permite desacoplar despliegues: el productor añade un campo y los consumidores antiguos
siguen funcionando sin coordinación. Es la base práctica de la compatibilidad hacia atrás en
contratos de servicios.
🔬 Su complemento es el principio de robustez —sé conservador en lo que envías, liberal en lo que
aceptas—, que hoy se cita con matices, porque la tolerancia excesiva también propaga errores: si
nadie se queja de un campo mal escrito, el error vive años. La formulación moderna es *ignora lo que
no conoces, valida estrictamente lo que sí*.

**01 → 16. ¿Qué pasa con las claves duplicadas y qué dice la norma?**

⏱️ En la práctica gana la última, y la norma solo dice que las claves *SHOULD* ser únicas.
🗣️ Verificado con `{"a":1,"a":2}`: JavaScript, Python y Go devuelven `2` los tres. Pero eso es una
coincidencia de implementaciones, no una garantía.
🔬 Y ahí está el problema de seguridad: si dos parsers distintos de la misma cadena de proxies eligen
valores distintos, un atacante puede hacer que el validador vea un valor y el ejecutor vea otro. Es
la misma familia de ataques que la desincronización de peticiones, aplicada al cuerpo. Un parser
estricto que rechace duplicados es la defensa.

**01 → 17. ¿Por qué las claves de un objeto son siempre texto y qué rompe eso?**

⏱️ Porque la gramática solo admite cadenas como clave. Rompe cualquier mapa con clave no textual.
🗣️ Un `Map<Integer, String>` serializado sale con claves `"1"`, `"2"`, y al deserializar hay que
volver a convertirlas — si la biblioteca sabe a qué tipo. Con claves compuestas o con objetos como
clave, directamente no hay forma.
🔬 La salida limpia es no serializar mapas con clave no textual: se convierte en un array de objetos
`[{"clave": 1, "valor": "..."}]`, que además sobrevive a cualquier cambio del tipo de la clave y es
lo que un contrato debería declarar.

**01 → 18. ¿Por qué un `id` debe viajar como cadena si es un número?**

⏱️ Porque un identificador no se suma: es una etiqueta, y como cadena no puede corromperse.
🗣️ El razonamiento completo tiene dos patas. La primera es semántica: no haces aritmética con un `id`,
no lo promedias y no lo ordenas aritméticamente. La segunda es práctica: como cadena, ningún parser
lo redondea.
🔬 Cuesta dos comillas y elimina de raíz una corrupción que ninguna prueba unitaria encuentra, porque
en pruebas los identificadores son pequeños. Es el ejemplo canónico de decisión de contrato que no
tiene coste y sí tiene beneficio, y decirlo así en una entrevista es mejor que citar el `2^53`.

**01 → 19. ¿Cuándo elegirías flujo en vez de árbol, y con qué dato lo justificas?**

⏱️ En cuanto el tamaño del documento no lo controle yo. Y lo justifico con el factor ocho.
🗣️ El criterio no es "cuando sea grande": es **cuando no haya un límite que yo imponga**. Una
importación, una exportación, un fichero de un tercero o un endpoint sin límite de tamaño de cuerpo
pueden crecer sin avisar.
🔬 El dato: 30 MB de archivo produjeron 323 MB de memoria residente en la JVM con árbol, frente a 99
MB con flujo. Multiplicado por las peticiones concurrentes, eso es la diferencia entre un servicio y
un `OutOfMemoryError`. Para documentos pequeños y acotados, el árbol es más corto de escribir y más
fácil de revisar, y ahí gana él.

**01 → 20. ¿Es siempre correcto ignorar los campos desconocidos? Da un contraejemplo.**

⏱️ No. En un mensaje donde el campo desconocido pueda cambiar el significado de la operación, hay que
rechazar.
🗣️ El contraejemplo canónico es financiero: llega una orden con un campo nuevo `condicionEspecial` o
`moneda` que tu versión no conoce. Ignorarlo significa ejecutar la orden **con otro significado del
que el emisor quiso**, y eso es peor que rechazarla.
🔬 La política que funciona es por dirección y por criticidad: tolerante en lectura de datos de
consulta, estricto en operaciones con efecto irreversible. Y cuando se rechaza, el error tiene que
decir **qué campo** no se entendió, porque si no, el emisor no puede corregir. Los formatos con
esquema —Protobuf, Avro— resuelven esto con campos marcados explícitamente como requeridos o no.

**01 → 21. ¿Por qué el `as Pedido` de TypeScript no protege, y qué lo protege?**

⏱️ Porque `JSON.parse` devuelve `any` y el `as` es una afirmación, no una comprobación. Protege un
validador en tiempo de ejecución.
🗣️ TypeScript comprueba tipos en compilación, y los datos que llegan por la red no existen en
compilación. El compilador confía en lo que tú le dices con `as`, y ahí puedes mentirle sin querer.
🔬 Verificado: compila limpio con `--strict` y en ejecución `id` es `number` y `total` es `string`,
con `toFixed` inexistente. La defensa es un esquema en la frontera —Zod, io-ts, Ajv— que valide y
**devuelva el tipo**: así el tipo estático deja de ser una promesa y pasa a ser una consecuencia. La
frase que lo resume: el tipo protege tu código, el validador protege tus datos.

**01 → 22. ¿Por qué firmar un JSON sin canonicalizar es un fallo de seguridad?**

⏱️ Porque el mismo documento lógico tiene infinitas representaciones textuales, y la firma se calcula
sobre el texto.
🗣️ Espacios, orden de claves, escapes Unicode, `1.0` frente a `1`, `1e2` frente a `100`: todo eso
cambia los octetos sin cambiar el significado. Si el verificador reserializa antes de comprobar, o si
el firmante y el verificador usan bibliotecas distintas, la firma deja de cuadrar — o, peor, cuadra
con un documento que no es el que se firmó.
🔬 La solución es una forma canónica acordada, y hay un documento que la fija: JCS, *JSON
Canonicalization Scheme* (RFC 8785, *Informational*), que define orden de claves, escapes y
representación de números. La alternativa práctica,
y la que usa JWT, es **firmar el texto exacto y transportarlo tal cual** en Base64, sin volver a
serializarlo nunca.

**01 → 23. Un servicio se cae al importar un archivo de 200 MB que en pruebas iba bien con 2 MB. Diagnostica y corrige.**

⏱️ Está parseando a árbol: 200 MB de archivo son más de 1,5 GB de objetos. Se corrige pasando a
flujo.
🗣️ El diagnóstico se confirma en un minuto: el error es `OutOfMemoryError` o una muerte del
contenedor por límite de memoria, no una excepción de parseo; y escala con el tamaño del archivo, no
con su contenido. El factor de ocho de la pregunta 13 predice el número casi exacto.
🔬 La corrección tiene tres piezas y la tercera es la que se olvida: **(1)** parsear en flujo,
procesando y descartando cada registro; **(2)** acotar el tamaño de petición en el borde, para
rechazar antes de leer; **(3)** revisar si el procesamiento acumula resultados en memoria, porque
cambiar a flujo y luego construir una lista con los 200 MB deja el problema igual. Y si el volumen
va a seguir creciendo, la respuesta de diseño no es un parser mejor: es trocear la importación.

**01 → 24. ¿Qué diferencia práctica hay entre `{"nota": null}` y `{}`, y dónde importa?**

⏱️ El primero dice "el campo existe y vale nulo"; el segundo, "el campo no viene". Importa en toda
operación de actualización parcial.
🗣️ En un `PATCH` con Merge Patch la diferencia es exacta: `null` **borra** el campo y la ausencia
significa "no lo toques". Confundirlos borra datos que nadie pidió borrar.
🔬 Y hay un segundo sitio donde importa: la deserialización a un objeto con valores por defecto. Con
`{}` el campo mantiene su valor anterior o el por defecto; con `null` lo pisa. La consecuencia de
diseño es que **el contrato tiene que elegir una de las dos formas y prohibir la otra**, porque la
mayoría de las bibliotecas no distinguen "ausente" de "nulo" al mapear a un tipo, y si tu dominio lo
necesita hace falta un envoltorio explícito.

**01 → 25. Te proponen NDJSON en vez de un array JSON para una exportación. ¿Qué ganas y qué pierdes?**

⏱️ Ganas procesamiento línea a línea, troceado y paralelización; pierdes ser un documento JSON válido
en sí mismo.
🗣️ Con un array de un giga, el consumidor tiene el mismo problema de memoria que tú acabas de
resolver: o hace flujo o se cae. Con un objeto por línea, cualquiera lo lee con un bucle de
`readLine` y un `parse` por línea, y `split`, `head` o `wc -l` funcionan.
🔬 Lo que se pierde: no se puede validar con un validador de JSON de golpe, ni abrir con una
herramienta que espere un documento; y hay que declarar la codificación y que **ningún objeto contenga
saltos de línea sin escapar** —que JSON garantiza, porque los escapa, pero conviene decirlo—. En una
exportación cuyo consumidor es un proceso, NDJSON gana casi siempre; si el consumidor es un navegador
o una herramienta de escritorio, el array puede ser más cómodo.

**01 → 26. Diseña el contrato JSON de un pedido con dinero, fechas, identificadores y un adjunto. Justifica el tipo elegido para cada campo.**

⏱️ Identificadores como cadena, dinero como cadena decimal con divisa aparte, fechas en ISO-8601 con
zona, y el adjunto por referencia y no incrustado.
🗣️ El contrato:

```json
{
  "id": "PED-00042",
  "creadoEn": "2026-09-18T14:30:00Z",
  "fechaEntrega": "2026-09-25",
  "total": { "importe": "1250.00", "divisa": "COP" },
  "adjunto": { "url": "https://.../factura.pdf", "sha256": "…", "bytes": 48213 }
}
```
🔬 Campo por campo: **`id` como cadena** por lo de la pregunta 18, y además deja evolucionar el
formato sin cambiar el tipo. **Dinero como cadena decimal con la divisa al lado**, porque `number`
es un `double` en el otro extremo y porque un importe sin divisa no es un importe; el entero de
céntimos es igual de defendible si el contrato declara la escala. **Dos tipos de fecha distintos a
propósito**: `creadoEn` es un instante y lleva zona; `fechaEntrega` es una fecha de calendario y no
debe llevarla, porque el 25 de septiembre es el 25 en todas partes. **El adjunto por referencia**,
con hash y tamaño, para que el cuerpo no crezca sin control y para que el receptor pueda verificar
lo que descarga. Y todo lo que sea acuerdo —el formato de fecha, la escala del importe— va escrito
en el contrato, porque JSON no lo expresa.

**01 → 27. Dos equipos discuten si el consumidor debe fallar ante un campo desconocido. Escribe la política que propondrías, con los casos en que se invierte.**

⏱️ Tolerante por defecto en lectura, estricto en operaciones con efecto irreversible, y siempre
declarado en el contrato.
🗣️ La política, en cuatro líneas:

```text
1. Los consumidores IGNORAN campos desconocidos en respuestas y eventos de consulta.
2. Los consumidores RECHAZAN campos desconocidos en órdenes con efecto económico o legal.
3. El productor NUNCA reutiliza un nombre de campo con otro significado. Nombre nuevo, campo nuevo.
4. Quitar un campo es un cambio mayor; añadirlo, menor. Se anuncia y se versiona.
```
🔬 Lo que hace defendible la política es el punto 3, que casi nadie escribe: la tolerancia del punto
1 solo es segura si el productor se compromete a no cambiar el significado de un nombre existente —
si `estado` pasa de ser `"OK"` a ser un objeto, ningún consumidor tolerante se salva. El punto 2 se
invierte cuando el coste de rechazar es mayor que el de ejecutar con información incompleta, que es
raro pero existe: telemetría, auditoría y cualquier flujo donde perder el mensaje sea peor que
procesarlo a medias. Y en los dos casos se **registra** lo desconocido, porque un campo ignorado en
silencio durante seis meses es un error que nadie descubre.

**01 → 28. Te dan un JSON de 4 GB y hay que calcular tres agregados. Escribe el enfoque, la estructura de datos y el coste en memoria.**

⏱️ Flujo de una pasada, tres acumuladores, memoria constante.
🗣️ El enfoque: un parser de flujo que emita tokens; un bucle que reconozca el fin de cada elemento
del array raíz; y para cada elemento, actualizar los acumuladores y **descartarlo**. Nada se guarda.
🔬 La estructura depende del agregado: suma y conteo son dos `long`; una media son esos dos; un
máximo es una variable; **un "top 10" es un montículo de tamaño 10**, no una lista ordenada de todo —
que es donde conecta con `04-arboles-grafos/02`. Un distinto-conteo exacto necesitaría memoria
proporcional a la cardinalidad, y ahí la respuesta senior es preguntar si vale una estimación y usar
HyperLogLog, del capítulo `03-orden-busqueda/06`. Coste: `O(n)` en tiempo, `O(1)` en memoria salvo
el caso del conteo distinto exacto. Y una última pieza: si el archivo fuera **NDJSON** en vez de un
array gigante, el problema sería trivialmente paralelizable por líneas — proponer ese cambio de
formato al productor suele ser mejor respuesta que optimizar el parseo.

**01 → 29. Tu API devuelve un `Map<Integer, String>` serializado. Explica qué llega al cliente y cómo lo rediseñarías.**

⏱️ Llegan las claves convertidas a cadena —`{"1":"a","2":"b"}`— y el rediseño es devolver un array de
objetos.
🗣️ Las claves de un objeto JSON solo pueden ser cadenas, así que el entero se convierte. Al
deserializar, si la biblioteca conoce el tipo destino lo revierte; si el cliente es JavaScript o
recibe un mapa genérico, se queda con cadenas — y `Object.keys()` devuelve `["1","2"]` en orden de
inserción o numérico según el motor, que es otra sorpresa.
🔬 El rediseño: `[{"clave": 1, "valor": "a"}, …]`. Es más largo y sobrevive a todo: a que la clave
cambie de tipo, a que sea compuesta, y al orden, que en un array sí está garantizado y en un objeto
no. La regla general que hay detrás: **un mapa cuya clave no sea texto no es un objeto JSON, es una
lista de pares**, y modelarlo así desde el principio evita una migración incompatible más adelante.

**01 → 30. Escribe la prueba automatizada que detectaría la corrupción de identificadores grandes antes de llegar a producción, y di por qué las pruebas actuales no la detectan.**

⏱️ Una prueba de contrato de ida y vuelta con un identificador por encima de `2^53`, ejecutada **en el
lenguaje del consumidor**.
🗣️ La prueba: serializar un objeto con `id = 9007199254740993`, pasarlo por el cliente real y afirmar
que el identificador recuperado es **idéntico como cadena**, no como número.

```text
dado   {"id": 9007199254740993}
cuando lo parsea el cliente (JavaScript / Go con mapa genérico)
espera el texto original, carácter a carácter
```
🔬 Por qué las pruebas actuales no lo ven, que es la parte que se evalúa: **(1)** los datos de prueba
usan identificadores pequeños, porque los genera un contador que empieza en 1; **(2)** las pruebas del
productor son en Java o Python, donde el valor **sí** sobrevive, así que verdes; **(3)** la prueba de
integración compara objetos deserializados por la misma biblioteca, que redondea en los dos lados de
la comparación y por tanto coinciden. Las tres condiciones tienen que romperse a la vez para que la
prueba sirva: dato grande, consumidor real y comparación textual. Y la prevención de fondo sigue
siendo el contrato: identificadores como cadena.

**01 → 31. Dos servicios intercambian JSON y uno empieza a recibir importes con tres decimales donde esperaba dos. Diagnostica sin acceso al código del otro.**

⏱️ Casi seguro el emisor está serializando un `double` o un decimal sin escala fijada, y apareció un
valor cuyo redondeo o cuya escala natural tiene tres dígitos.
🗣️ El diagnóstico se hace sobre el cable, no sobre el código: capturar varios mensajes y mirar si el
importe viene entrecomillado o como número, y si los tres decimales aparecen siempre o solo en ciertos
valores. Si es solo en algunos, es cálculo —una división, un porcentaje, un prorrateo— y el emisor no
está redondeando antes de serializar. Si es en todos, cambiaron el tipo o la configuración.
🔬 Lo que hay que mirar, en orden: **(1)** ¿es número o cadena en el JSON? Si es número, ya hay un
problema latente de precisión aparte de la escala. **(2)** ¿Coincide el cambio con un despliegue del
emisor? **(3)** ¿Hay un valor concreto reproducible? Con eso se escribe el informe. Y lo que **no**
hay que hacer es "arreglarlo" redondeando en tu lado en silencio: eso oculta una diferencia de
contrato y la convierte en un descuadre contable que aparecerá en la conciliación. La corrección es
fijar la escala en el contrato y que el emisor la respete; mientras tanto, **rechazar o registrar**
lo que no cumpla, no truncarlo.

---

# 02 — XML y los esquemas

**02 → 1. ¿Qué es un espacio de nombres en XML y para qué sirve?**

⏱️ Un prefijo asociado a una URI que cualifica los nombres de elementos y atributos, para que dos
vocabularios distintos puedan convivir en el mismo documento.
🗣️ Sirve para que la etiqueta `<cuenta>` del banco A y la del banco B no colisionen aunque aparezcan
en el mismo mensaje. Es lo que permite componer formatos: un sobre SOAP con un cuerpo ISO 20022
dentro.
🔬 La URI es un identificador, **no una dirección que se descargue**: no hace falta que responda a
nada. El prefijo (`xsd:`, `soap:`) es local al documento y se puede renombrar sin cambiar el
significado — lo que cuenta es la URI. JSON no tiene nada equivalente, y por eso componer dos
vocabularios en JSON es una convención de prefijos de campo.

**02 → 2. ¿Qué es XPath?**

⏱️ Un lenguaje de consulta sobre el árbol XML: selecciona nodos por ruta, posición, atributo o
predicado.
🗣️ `/pedido/lineas/linea[@id='3']/total` saca un valor sin escribir un recorrido a mano, y
`count(//linea)` da un agregado sin deserializar nada a objetos.
🔬 Está en la biblioteca estándar de Java y de Python. **Necesita el árbol**, así que hereda su coste
de memoria, y cada expresión con `//` recorre el documento entero: diez consultas son diez
recorridos, `O(n)` cada una. En JSON no hay equivalente normativo: JSONPath es una convención con
dialectos incompatibles entre bibliotecas.

**02 → 3. ¿Qué es un XSD?**

⏱️ Un esquema: un documento XML que describe qué documentos XML son válidos.
🗣️ Declara qué elementos existen, en qué orden, con qué cardinalidad y de qué tipo. Con él, el parser
rechaza un documento mal formado **antes** de que llegue a tu lógica de negocio, y el error señala
el elemento exacto.
🔬 Es la diferencia práctica con JSON: en XML el contrato es un artefacto que el socio te entrega y
que la biblioteca aplica sola; en JSON hay que añadir JSON Schema, elegir validador y decidir quién
mantiene el esquema. El coste del XSD es tiempo: validar recorre el documento otra vez y con
esquemas grandes puede costar más que parsear, por eso se valida una sola vez y en el borde.

**02 → 4. ¿Cuáles son los tres modos de parsear XML?**

⏱️ DOM, que construye el árbol; SAX, que es flujo de empuje; y StAX, que es flujo de tirón.
🗣️ DOM da navegación en los dos sentidos y es lo único sobre lo que corre XPath. SAX llama a tus
métodos según va leyendo, y tú mantienes el estado a mano. StAX te devuelve el control con un bucle
que pide el siguiente evento cuando quiere.
🔬 La diferencia entre empuje y tirón parece menor y decide la legibilidad del código: con SAX
acabas con banderas y pilas para saber dónde estás; con StAX puedes delegar una subsección a otro
método y volver. Hoy, para documentos grandes, se usa StAX; SAX solo si mantienes código que ya lo
usa.

**02 → 5. ¿Qué es XXE?**

⏱️ *XML External Entity*: una entidad declarada en el `DOCTYPE` que apunta a un recurso externo, y
que el parser resuelve leyendo un archivo del servidor o haciendo una petición de red.
🗣️ Sirve para exfiltrar archivos —`file:` a una ruta local—, para escanear la red interna desde tu
servidor, y para provocar denegaciones de servicio apuntando a recursos lentos.
🔬 Verificado: `DocumentBuilderFactory.newInstance()` de Java 17, sin configurar, lee el archivo
apuntado y lo devuelve como contenido del elemento. Es una de las categorías históricas del top de
OWASP, y sigue apareciendo porque el valor por defecto de la biblioteca es el inseguro.

**02 → 6. ¿Trae Node un parser de XML?**

⏱️ No. `DOMParser` es del navegador; en Node no existe.
🗣️ Verificado: `typeof DOMParser` devuelve `undefined` en Node 24. Hay que instalar una biblioteca
—`xml2js`, `fast-xml-parser`, `libxmljs`— y elegirla con criterio, porque cada una hace un mapeo
distinto de atributos y texto.
🔬 Que el ecosistema nacido en la web no traiga XML y el ecosistema empresarial lo traiga entero en
la biblioteca estándar dice bastante sobre dónde vive cada formato.

**02 → 7. ¿Está JAXB en el JDK?**

⏱️ No desde Java 11. Hoy es una dependencia externa.
🗣️ `javax.xml.bind` se marcó obsoleto en Java 9 y salió del JDK en Java 11, junto con el resto de los
módulos de Java EE. Verificado: `Class.forName("javax.xml.bind.JAXBContext")` lanza
`ClassNotFoundException` en un JDK 17 limpio.
🔬 Y la migración tiene una trampa añadida: el paquete pasó de `javax.xml.bind` a `jakarta.xml.bind`
con el cambio de Java EE a Jakarta EE, así que no basta con añadir una dependencia — hay que tocar
los `import`. Lo que **sí** sigue en el JDK es JAXP: DOM, SAX, StAX, XPath y validación XSD.

**02 → 8. ¿Cuánto ocupa un XML frente a un JSON equivalente?**

⏱️ Entre dos y cinco veces más, por las etiquetas de cierre y los atributos de espacio de nombres.
🗣️ Pero comprimido la diferencia casi desaparece, porque las etiquetas repetidas son exactamente lo
que un compresor explota mejor.
🔬 Por eso el argumento del tamaño es el más débil contra XML. Los costes reales son otros: un parser
mucho mayor, una superficie de ataque mayor —entidades, esquemas externos, XSLT— y más complejidad
para el que escribe el cliente.

**02 → 9. ¿Qué diferencia hay entre SAX y StAX?**

⏱️ Quién controla el bucle: en SAX el parser te llama (empuje); en StAX tú pides el siguiente evento
(tirón).
🗣️ Con SAX implementas un manejador con métodos como *inicio de elemento* y *fin de elemento*, y
mantienes tú el estado de dónde estás. Con StAX escribes un `while` normal, con lo que puedes parar,
saltar o delegar sin inventarte una máquina de estados.
🔬 En coste son equivalentes: los dos son `O(n)` en tiempo y `O(profundidad)` en memoria. La
diferencia es de mantenimiento, y es la razón por la que StAX ganó. El paralelo exacto en JSON es
Jackson: `JsonParser` es de tirón, y los manejadores de eventos son de empuje.

**02 → 10. ¿Cuándo pones un dato en un atributo y cuándo en un elemento?**

⏱️ Dato del dominio, elemento; metadato sobre cómo leer el dato, atributo.
🗣️ Un importe es un elemento; su divisa, su unidad o su idioma son atributos. Un identificador de
referencia interna suele ser atributo; el nombre del cliente, elemento.
🔬 **No hay respuesta normativa**, y decirlo así es mejor que defender un bando. Hay dos restricciones
reales que sí ayudan a decidir: un atributo no puede repetirse ni contener estructura, así que todo
lo que pueda ser múltiple o crecer tiene que ser elemento; y los atributos no admiten contenido
mixto. En la práctica, la regla que más evita rediseños es **ante la duda, elemento**, porque un
elemento siempre puede crecer y un atributo no.

**02 → 11. ¿Qué puede representar XML que JSON no puede?**

⏱️ Contenido mixto, orden significativo entre elementos distintos, espacios de nombres, comentarios y
firma parcial.
🗣️ El contenido mixto es el caso que JSON no puede expresar sin inventarse una convención: en
`<p>hola <b>mundo</b> adiós</p>` el texto y los elementos se alternan y el orden importa. XML nació
para documentos; JSON, para datos.
🔬 La firma parcial es la que más pesa en banca: XML Signature permite firmar **un subárbol** y dejar
el resto modificable, algo que en JSON obliga a partir el documento o a firmar el todo. Y los
comentarios, que parecen menores, son lo que hace que un XSD o un archivo de configuración XML se
puedan revisar entre personas.

**02 → 12. Diferencia XXE de *billion laughs*.**

⏱️ XXE usa una entidad **externa** para leer algo de fuera; *billion laughs* usa entidades
**internas** anidadas para agotar la memoria.
🗣️ El primero es exfiltración y petición de red desde tu servidor; el segundo es denegación de
servicio pura: diez niveles de diez referencias cada uno son 10^10 nodos a partir de un archivo de
diez líneas.
🔬 Se confunden porque ambos viven en el `DOCTYPE`, y esa es justamente la razón por la que **la
defensa buena es prohibir el `DOCTYPE` entero** en vez de desactivar entidades externas: una sola
bandera cierra las dos familias. Verificado que no protegen lo mismo: Java corta la expansión
anidada a las 64 000 entidades pero resuelve las externas; Python rechaza las externas pero expandió
300 000 caracteres sin quejarse.

**02 → 13. ¿Qué hace el parser de Java por defecto ante una entidad externa? ¿Y ante una anidada?**

⏱️ La externa la resuelve y lee el archivo; la anidada la corta a las 64 000 expansiones.
🗣️ Es decir: vulnerable a XXE, protegido contra *billion laughs*. La combinación es peligrosa porque
da la sensación de que el parser "ya trae protecciones".
🔬 El mensaje del corte es citable: `JAXP00010001: The parser has encountered more than "64000" entity
expansions in this document; this is the limit imposed by the JDK`. Ese límite se controla con la
propiedad `jdk.xml.entityExpansionLimit`. Para XXE no hay límite que valga: hay que desactivarlo
explícitamente.

**02 → 14. ¿Y el de Python? ¿Y el de Go?**

⏱️ Python rechaza la entidad externa pero expande las internas sin límite; Go rechaza cualquier
entidad no estándar.
🗣️ Verificado con los mismos archivos: `ElementTree` responde *"undefined entity &xxe;"* ante la
externa, y expandió 300 000 caracteres ante la anidada sin protestar. `encoding/xml` de Go falla con
*"invalid character entity"* en los dos casos.
🔬 De ahí la conclusión del bloque: **ninguno de los tres está protegido en las dos columnas y la
protección depende de la biblioteca, no del formato**. En Python la recomendación oficial para XML
externo es `defusedxml`; la propia documentación del módulo `xml` trae una tabla de qué ataque
afecta a qué parser. En Go no hace falta hacer nada porque nunca soportó entidades personalizadas —
que es también la razón de que no sirva para ciertos formatos empresariales.

**02 → 15. ¿Qué línea blinda el parser de Java y por qué esa y no otra?**

⏱️ `f.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)`, porque prohíbe el
`DOCTYPE` entero y cierra de golpe las dos familias de ataque.
🗣️ Las alternativas —desactivar entidades generales, desactivar entidades de parámetro, prohibir
esquemas externos— hay que ponerlas todas y en el orden correcto, y dejar una fuera deja un hueco.
Una sola bandera no se olvida.
🔬 Hay que ponerla en las **tres** fábricas, porque una aplicación normal usa más de una:
`DocumentBuilderFactory`, `SAXParserFactory` y `XMLInputFactory`. El único caso en que estorba es un
dominio que use DTD de verdad, que hoy es raro; si lo necesitas, entonces sí toca la lista larga de
banderas, y la referencia es la hoja de OWASP.

**02 → 16. ¿Por qué XPath no tiene equivalente estándar en JSON?**

⏱️ Porque JSON nació sin él y lo que hay —JSONPath— es una convención con dialectos incompatibles.
🗣️ XPath se diseñó junto con XML, por un organismo, y con una semántica definida para nodos,
atributos, ejes y predicados. JSONPath apareció después como un artículo de blog y cada biblioteca
lo implementó a su manera: el mismo filtro devuelve resultados distintos según el lenguaje.
🔬 Hay un esfuerzo posterior de normalización de JSONPath en el IETF, pero el ecosistema ya está
fragmentado. La consecuencia práctica: si necesitas consultar documentos sin deserializar y el
resultado tiene que ser portable entre lenguajes, XML con XPath es una ventaja real de XML, no
nostalgia.

**02 → 17. ¿Qué se pierde al usar `encoding/xml` de Go frente a Java?**

⏱️ XPath, validación XSD, y el manejo completo de espacios de nombres.
🗣️ `encoding/xml` cubre el caso de mapear un XML sencillo a un `struct` con etiquetas, y lo hace
bien. Lo que no cubre es el XML empresarial: sin validación de esquema, sin consultas y con soporte
parcial de espacios de nombres — la propia documentación lo advierte.
🔬 Es un reparto deliberado, coherente con el resto de Go: biblioteca estándar pequeña y suficiente,
y lo especializado fuera. La implicación de arquitectura es concreta: si el dominio te exige validar
contra XSD y firmar subárboles, Go no es el lenguaje para ese servicio, y decirlo es mejor que
reimplementar medio JAXP.

**02 → 18. ¿Por qué XML sigue vivo en banca y seguros?**

⏱️ Porque esos dominios necesitan esquema validable, espacios de nombres y firma parcial, y los tres
vienen de serie.
🗣️ ISO 20022 para pagos, XBRL para información financiera, formatos nacionales de facturación
electrónica: son estándares definidos por organismos, con esquemas publicados y con obligación legal
de cumplirlos. Cambiar de formato no es una decisión técnica.
🔬 Y hay una razón menos obvia: **la firma parcial**. En un mensaje de pago que atraviesa varios
intermediarios, cada uno añade información y la firma del emisor tiene que seguir siendo válida sobre
su parte. XML Signature lo resuelve; en JSON habría que rediseñar el flujo. Por eso la respuesta
correcta a "¿por qué no lo migran a JSON?" no es inercia: es que perderían capacidades.

**02 → 19. ¿Cuándo dirías que XML es la elección incorrecta?**

⏱️ En una API interna nueva, donde pagas toda la complejidad y no usas ninguna de sus capacidades.
🗣️ Si no vas a usar espacios de nombres, ni XSD, ni firma parcial, ni contenido mixto, entonces XML
es JSON con más caracteres y más superficie de ataque. Y si el consumidor es un navegador, aún peor,
porque tendrá que traer una biblioteca.
🔬 La forma honesta de plantearlo en una reunión es invertir la pregunta: *"¿cuál de las cuatro cosas
que XML hace y JSON no vamos a usar?"*. Si la respuesta es ninguna, la decisión está tomada. Si es
alguna, entonces XML puede ser correcto y hay que decirlo con la misma tranquilidad.

**02 → 20. Un fichero de intercambio de 500 MB tumba el servicio al parsearlo. Diagnostica y corrige.**

⏱️ Está usando DOM. 500 MB de XML son varios gigabytes de árbol. Se corrige pasando a StAX.
🗣️ El diagnóstico se confirma igual que en JSON: el fallo es de memoria y no de parseo, y escala con
el tamaño del archivo. Con XML el factor es incluso peor que el ocho de JSON, porque un nodo DOM
arrastra más metadatos.
🔬 La corrección completa: **(1)** StAX, procesando registro a registro y descartando; **(2)** si hay
XSD, validar **en flujo**, que es posible y mucha gente no sabe —un validador se puede encadenar a un
lector StAX— en lugar de validar el árbol completo; **(3)** revisar que el procesamiento no acumule,
porque cambiar a StAX y construir una lista de 500 MB de objetos no arregla nada; **(4)** si el
fichero seguirá creciendo, negociar con el emisor trocearlo, que es una decisión de contrato y no de
código.

**02 → 21. ¿Por qué validar con XSD en el borde y no dentro de la lógica?**

⏱️ Porque un documento inválido no debe llegar a la lógica de negocio, y porque validar dos veces
cuesta el doble.
🗣️ En el borde el rechazo es barato y el mensaje de error es preciso —línea y elemento—. Dentro, ya
has deserializado, ya has abierto una transacción y el error llega mezclado con reglas de negocio.
🔬 El argumento adicional es de seguridad: la validación es también un filtro de tamaño y de forma,
así que ejecutarla antes reduce lo que llega al resto del sistema. Y el coste importa: validar es
otro recorrido `O(n)` sobre el documento, con esquemas grandes puede costar más que parsear, así que
se hace **una vez**. Un esquema que existe y no se aplica es documentación, no contrato.

**02 → 22. ¿Por qué prohibir el DOCTYPE es mejor blindaje que desactivar entidades externas?**

⏱️ Porque cierra las dos familias de ataque con una sola bandera, y no deja huecos que se olviden.
🗣️ Desactivar entidades externas deja vivas las internas anidadas, y hay más banderas relacionadas
—entidades de parámetro, `XMLConstants.ACCESS_EXTERNAL_DTD`, esquemas externos— que hay que poner
todas. Cada una que falte es un hueco.
🔬 Y hay un argumento de revisión de código: una línea es verificable de un vistazo y difícil de
revertir por accidente; seis líneas de configuración se diluyen en un refactor. El precio es perder
el soporte de DTD, que en un servicio moderno no se usa — y si se usa, se sabe.

**02 → 23. Un socio te manda XML firmado y solo una parte del documento va firmada. ¿Qué implica eso al procesarlo?**

⏱️ Que hay que procesar **solo lo firmado** y tratar el resto como no fiable.
🗣️ Es el error clásico: se verifica la firma, da válida, y a continuación se leen campos que estaban
fuera del subárbol firmado. Un intermediario puede haberlos modificado sin invalidar nada.
🔬 El procedimiento correcto tiene tres pasos y el tercero es el que se salta todo el mundo: **(1)**
verificar la firma; **(2)** determinar **qué nodos cubre exactamente** la referencia firmada; **(3)**
extraer los datos de negocio **de ese subárbol**, no del documento. Y hay una trampa añadida, la
*XML Signature wrapping*: un atacante mueve el contenido original a otra parte del documento y pone
el suyo donde tu código lo lee, de modo que la firma sigue verificando sobre el fragmento
desplazado. La defensa es exactamente el paso 3.

**02 → 24. ¿Por qué un XSD se valida una sola vez y no en cada capa?**

⏱️ Porque cada validación es otro recorrido `O(n)` sobre el documento, y con esquemas grandes puede
costar más que parsear.
🗣️ Validar en el borde y una vez da lo que se busca —rechazar lo inválido antes de tocar nada— sin
pagar el coste repetido. Validar otra vez en la capa de servicio no aporta garantía nueva: el
documento no ha cambiado.
🔬 El matiz que conviene añadir: **eso vale dentro de un límite de confianza**. Si el documento cruza
una frontera donde otro sistema puede modificarlo —un bus, una cola, un intermediario que enriquece—,
entonces la validación de origen ya no dice nada sobre lo que te llega, y hay que volver a validar.
La regla no es "una vez en el proceso", es **una vez por frontera de confianza**.

**02 → 25. Te dan un XML sin XSD de un socio nuevo. ¿Qué haces antes de escribir el primer mapeo?**

⏱️ Pedir el XSD. Y si no existe, inferir uno de las muestras y **hacer que el socio lo confirme por
escrito**.
🗣️ Sin esquema no hay contrato: cada campo opcional, cada cardinalidad y cada tipo que deduzcas de
tres ejemplos es una suposición que se romperá con el ejemplar número mil.
🔬 El procedimiento: recoger el máximo de muestras reales —no las tres bonitas—, inferir el esquema
con una herramienta, y revisar a mano exactamente lo que ninguna inferencia puede saber: qué campos
son **opcionales** frente a los que simplemente no aparecían en la muestra, qué cardinalidades son
`0..n` frente a `1..n`, qué formatos tienen las fechas y los importes, y qué espacios de nombres son
estables. Ese documento se le manda al socio para que lo confirme, y a partir de ahí es el contrato.
Escribir el mapeo antes de ese paso es garantizar reescribirlo.

**02 → 26. ¿Cuándo preferirías StAX sobre DOM aunque el documento sea pequeño?**

⏱️ Cuando el tamaño no lo controlo yo, cuando solo necesito unos pocos campos del principio, y cuando
el documento viene de fuera.
🗣️ "Pequeño" suele ser una afirmación sobre la muestra, no sobre el sistema: los documentos crecen y
el atacante elige el suyo. Y si solo necesito el identificador y el total, StAX puede parar al
encontrarlos sin leer el resto.
🔬 El caso a favor de DOM sigue siendo fuerte y hay que decirlo: si hace falta XPath, si hay que
recorrer el documento varias veces o navegar hacia atrás, o si el código lo va a mantener alguien que
no conoce StAX, el árbol es más corto y más claro. La decisión no es ideológica: es **quién controla
el tamaño** y **cuántas veces vas a recorrerlo**.

**02 → 27. Tienes que exponer el mismo recurso en XML y en JSON. Escribe qué decides para atributos, espacios de nombres, fechas y nulos, y qué se pierde en cada dirección.**

⏱️ Modelo canónico primero, y de ahí dos serializaciones; los atributos se aplanan, los espacios de
nombres se pierden, las fechas van en ISO-8601 en ambos, y el nulo se representa distinto.
🗣️ Las cuatro decisiones:

```text
ATRIBUTOS   en XML solo metadatos (divisa, idioma, id). En JSON se aplanan a campos hermanos.
NAMESPACES  se declaran en XML y NO se representan en JSON: se documenta la pérdida.
FECHAS      ISO-8601 en los dos; instante con zona, fecha de calendario sin ella.
NULOS       XML: elemento ausente, o xsi:nil="true" si hay que distinguir. JSON: null o ausente, y se elige UNA.
```
🔬 Qué se pierde en cada dirección, que es lo que se evalúa. **De XML a JSON** se pierden los espacios
de nombres, el orden entre elementos distintos, el contenido mixto y la distinción entre atributo y
elemento; si el XML original venía firmado, la firma tampoco sobrevive. **De JSON a XML** se pierde
poco en estructura, pero hay que inventar nombres para los elementos de un array —`<lineas><linea>`—
y decidir si un array de un solo elemento se distingue de un elemento suelto, que es la ambigüedad
clásica de las conversiones automáticas. La conclusión que conviene decir: **la conversión
automática entre los dos no es reversible**, así que el canónico es el modelo, no ninguno de los dos
documentos.

**02 → 28. Escribe la revisión de seguridad de un servicio que recibe XML de terceros: qué miras, en qué orden y con qué prueba lo confirmas.**

⏱️ Primero el endurecimiento del parser, luego los límites de tamaño, luego la validación de esquema,
y cada punto con una petición que lo demuestre.
🗣️ El orden y la prueba de cada uno:

```text
1. ¿Está prohibido el DOCTYPE en TODAS las fábricas?   → enviar un XXE con file: y ver 400, no el archivo
2. ¿Hay límite de tamaño de cuerpo en el borde?        → enviar 1 GB y ver el rechazo antes de parsear
3. ¿Se valida contra XSD antes de la lógica?           → enviar un documento con un campo de más
4. ¿Se usa DOM con documentos sin límite?              → enviar el máximo permitido y medir memoria
5. ¿Se procesa solo lo firmado, si hay firma?          → mover un nodo fuera del subárbol firmado
6. ¿Se registran los rechazos con detalle suficiente?  → comprobar que el log dice qué y dónde falló
```
🔬 El punto 1 se comprueba en las tres fábricas por separado, porque es normal que una aplicación
endurezca `DocumentBuilderFactory` y se olvide de `XMLInputFactory` en otro módulo — un `grep` por
`newInstance()` de las tres clases es más rápido que leer el código. El punto 5 solo aplica si hay
firma, pero cuando aplica es el más grave. Y la prueba del punto 2 tiene que ir **antes** que la del
4, porque si no hay límite de tamaño, medir memoria no tiene sentido: el atacante elige el número.

**02 → 29. Un XML de 2 GB tiene que convertirse a JSON conservando solo tres campos por registro. Diseña el procesamiento y di su coste en memoria.**

⏱️ StAX de entrada, NDJSON de salida, una pasada, memoria constante.
🗣️ El diseño: un lector StAX avanza hasta cada elemento `<registro>`; se extraen los tres campos a
variables locales; se escribe una línea JSON en el flujo de salida; se descarta todo y se sigue. No
se construye ninguna colección.
🔬 Cuatro detalles que hacen la diferencia. **(1)** La salida es **NDJSON** —un objeto por línea— y no
un array JSON gigante, porque un array obliga al consumidor a parsearlo entero o a hacer flujo, y
NDJSON se procesa línea a línea y se parte en trozos trivialmente. **(2)** El escritor va con búfer y
se vacía cada N registros: escribir sin búfer domina el tiempo total. **(3)** Coste: `O(n)` en
tiempo y `O(1)` en memoria, unas decenas de megas de búferes, independiente de los 2 GB. **(4)** Y el
punto que distingue una respuesta senior: **hay que decidir qué se hace con un registro corrupto a
mitad del archivo** — abortar, saltar y contar, o escribir a un archivo de rechazos. Procesar 2 GB y
morir en el registro 4 000 001 sin haber escrito nada es el peor resultado posible.

**02 → 30. Un servicio Java lleva años parseando XML de terceros sin endurecer el parser y no ha pasado nada. Escribe el argumento para priorizar el arreglo.**

⏱️ Que no haya pasado nada no es evidencia de que sea seguro: es evidencia de que nadie lo ha
intentado. Y la corrección es una línea.
🗣️ El argumento tiene tres patas y ninguna es alarmista. **Coste:** una línea por fábrica, más una
prueba; horas, no semanas. **Impacto:** lectura de cualquier archivo que el proceso pueda leer
—credenciales, claves, configuración— y peticiones de red desde dentro de la red, que es el primer
paso de un movimiento lateral. **Detectabilidad:** un XXE con éxito no deja error en ningún log, así
que la ausencia de incidentes registrados **no prueba nada**.
🔬 Y lo que convierte el argumento en una decisión: enseñarlo funcionando. Reproducirlo en el entorno
de pruebas con un documento que lea un archivo inocuo y enseñar la salida convierte una discusión
abstracta en un hecho de treinta segundos. El cierre honesto es dar también el riesgo del arreglo,
que es prácticamente nulo salvo que el dominio use DTD — y eso se comprueba antes con un `grep` por
`DOCTYPE` en los documentos recibidos.

**02 → 31. Migras un servicio de XML a JSON manteniendo el XML durante un año. Diseña la convivencia: modelo, validación, versiones y qué haces con los documentos históricos.**

⏱️ Un modelo canónico interno, dos adaptadores en el borde, validación propia de cada formato, y los
históricos se quedan en XML con un lector que no se toca.
🗣️ El diseño:

```text
MODELO      un modelo de dominio único; ni el XML ni el JSON son el modelo
ENTRADA     dos adaptadores en el borde: XML→modelo (validado con XSD) y JSON→modelo (validado con JSON Schema)
SALIDA      dos serializadores; el contenido lo decide el modelo, no el formato
NEGOCIACIÓN el consumidor elige con Accept / Content-Type; nada de un parámetro inventado
HISTÓRICOS  se quedan como están; el lector XML se mantiene mientras haya que leerlos, que es MÁS de un año
```
🔬 Las tres decisiones que hacen que esto no se convierta en un problema. **(1) El canónico es el
modelo, no uno de los dos documentos**: si se elige "JSON es la verdad y el XML se genera", se hereda
la pérdida de la conversión —espacios de nombres, orden, firma— y ya no se puede volver. **(2) La
paridad se prueba**: una batería que tome documentos reales en XML, los lleve al modelo y los
serialice a JSON y de vuelta, comparando contra el original — ahí es donde aparecen las pérdidas, y
hay que decidir cada una explícitamente en vez de descubrirla en producción. **(3) El plazo del año
es del *contrato nuevo*, no del lector antiguo**: los documentos históricos hay que poder leerlos
mientras exista la obligación legal de conservarlos, que en banca son años, así que ese lector no se
borra al terminar la migración — y conviene decirlo al planificar, porque es lo que la gente olvida
al estimar.

---

# 03 — YAML

**03 → 1. ¿Para qué se usa YAML y por qué no JSON?**

⏱️ Para archivos que escriben y revisan personas: configuración, canalizaciones de CI, manifiestos.
Se usa porque JSON no tiene comentarios.
🗣️ A eso se suma que YAML no obliga a llaves, comas ni comillas, y que la indentación hace visible la
estructura. En un archivo de 300 líneas revisado en un *pull request*, eso importa más que la
velocidad de parseo.
🔬 La contrapartida es todo este capítulo: gramática enorme, conversión implícita de tipos y dos
versiones de la norma en uso. El reparto sensato es **YAML para lo que lee una persona, JSON para lo
que lee una máquina**.

**03 → 2. ¿Es todo JSON un YAML válido?**

⏱️ En YAML 1.2 sí; en 1.1 no del todo.
🗣️ La compatibilidad con JSON fue el objetivo declarado de la revisión 1.2 de 2009, y por eso un
documento JSON se puede pegar dentro de un YAML y funciona.
🔬 El matiz importa porque **PyYAML y SnakeYAML implementan 1.1**, que es donde viven las diferencias
de escapes y de tipos implícitos. Así que "todo JSON es YAML" es cierto sobre el papel de la norma
vigente y no necesariamente sobre la biblioteca que tienes instalada.

**03 → 3. ¿Qué es el problema de Noruega?**

⏱️ Que `NO`, el código ISO de Noruega, se interpreta como el booleano falso.
🗣️ En YAML 1.1 son booleanos `yes`, `no`, `on`, `off`, `true`, `false` y sus variantes en mayúsculas.
Una lista de códigos de país funciona perfectamente hasta que alguien añade Noruega.
🔬 Verificado: `paises: [NO, SE]` da `[False, 'SE']` en PyYAML y `[false, SE]` en SnakeYAML. En Go con
`yaml.v3` da `["NO", "SE"]`, porque aplica el esquema de 1.2. La corrección son dos comillas:
`["NO", "SE"]`.

**03 → 4. ¿Qué vale `022` en YAML?**

⏱️ 18. Se lee en octal por el cero inicial.
🗣️ Afecta a todo lo que lleve cero a la izquierda y parezca número: puertos, códigos de sucursal,
días del mes, códigos postales.
🔬 Verificado en los tres lenguajes: PyYAML, SnakeYAML y `yaml.v3` devuelven 18. Es de los pocos
puntos donde 1.1 y 1.2 coinciden, así que no hay biblioteca que te salve: la única defensa son las
comillas.

**03 → 5. ¿Qué es un ancla y qué es un alias?**

⏱️ El ancla (`&nombre`) le pone nombre a un nodo; el alias (`*nombre`) lo reutiliza en otro sitio.
🗣️ Con la clave de fusión `<<` se copian las claves de un mapa anclado en otro, que es como se
factoriza la configuración común entre entornos sin repetirla.
🔬 Verificado: con `base: &comun {reintentos: 3, timeout: 5}` y `dev: {<<: *comun, timeout: 30}`, el
resultado es `{reintentos: 3, timeout: 30}` — la clave local gana sobre la fusionada. JSON no tiene
nada equivalente, y ese es uno de los pocos argumentos técnicos reales a favor de YAML.

**03 → 6. ¿Qué diferencia hay entre `|` y `>`?**

⏱️ `|` conserva los saltos de línea; `>` los pliega en espacios.
🗣️ `|` para lo que tiene estructura de líneas —un script, un certificado, una clave—; `>` para un
párrafo largo que escribes en varias líneas y quieres leer como una.
🔬 Verificado: el mismo bloque de dos líneas da `'linea 1\nlinea 2\n'` con `|` y `'linea 1 linea 2\n'`
con `>`. Los dos admiten el modificador `-` para quitar el salto final: `|-` es lo que se usa en una
clave o un *token*, porque ese `\n` de más invalida una firma o rompe una comparación.

**03 → 7. ¿Se puede indentar con tabuladores?**

⏱️ No. La norma lo prohíbe.
🗣️ El motivo es que la anchura de un tabulador depende del editor y la indentación es sintaxis: un
archivo indentado con tabuladores significaría cosas distintas según quién lo abra.
🔬 Y el detalle que cuesta tiempo real: **el error no menciona la palabra tabulador**. Verificado, el
mensaje de PyYAML es *"while scanning for the next token"*, que no orienta a nadie. Es lo primero que
hay que mirar ante un error de parseo inexplicable, y por eso los editores muestran los caracteres
invisibles en los archivos YAML.

**03 → 8. ¿Qué trae Node de serie para YAML?**

⏱️ Nada. Hay que instalar `yaml` o `js-yaml`.
🗣️ Verificado en Node 24. Y la elección importa más de lo que parece: las dos bibliotecas no aplican
exactamente el mismo esquema de tipos, con lo que arrastran la misma clase de divergencia que este
capítulo describe entre lenguajes.
🔬 Ninguno de los cinco lenguajes del corpus trae YAML en su biblioteca estándar — ni Java, ni Python,
ni Go, ni Node. Es un dato revelador: el formato que domina la configuración de la industria no está
en ninguna biblioteca estándar, y eso explica por qué el comportamiento depende tanto de la
dependencia elegida.

**03 → 9. ¿Por qué hay dos versiones de YAML en uso y qué cambia entre ellas?**

⏱️ Porque 1.2, de 2009, se realineó con JSON, y buena parte del ecosistema se quedó en 1.1, de 2005.
🗣️ Lo que cambia y se nota: en 1.1 son booleanos `yes/no/on/off`; en el *core schema* de 1.2 solo
`true/false`. También cambian los tipos implícitos de fecha y el sexagesimal.
🔬 Verificado con el mismo archivo: `yes` da `True` en PyYAML y `true` en SnakeYAML —ambas 1.1— y la
cadena `"yes"` en `yaml.v3` de Go. Y `12:30` da `750` en las dos primeras y `"12:30"` en Go. El
octal, en cambio, coincide en las tres. Esa mezcla es la razón de que el problema sea difícil de
razonar de memoria y haya que probarlo.

**03 → 10. ¿Qué pasa con `12:30` y por qué?**

⏱️ En YAML 1.1 se lee como sexagesimal y vale 750: 12 × 60 + 30.
🗣️ El tipo implícito de entero en 1.1 admite notación de base 60 separada por dos puntos, pensada
para ángulos y duraciones. El efecto colateral es que cualquier hora escrita sin comillas deja de ser
una hora.
🔬 Verificado: `750` en PyYAML y en SnakeYAML; `"12:30"` en Go, que no implementa el sexagesimal. Es
el error más difícil de detectar de los cuatro del capítulo, porque 750 es un número plausible y no
se parece en nada a una hora — nadie ve la relación al leer el log.

**03 → 11. ¿Qué vale una clave sin valor?**

⏱️ `null`, no la cadena vacía.
🗣️ `descripcion:` sin nada detrás produce un nulo, igual que `descripcion: ~` y que
`descripcion: null`. Si el código esperaba una cadena, ahí está el `NullPointerException` que aparece
solo en un entorno.
🔬 Para la cadena vacía hay que escribirla: `descripcion: ""`. Y conviene saber que `~` es nulo,
porque es lo que hace que un archivo se lea distinto de como se ve — un `~` suelto no parece un valor
y lo es.

**03 → 12. ¿Cómo se evita toda la conversión implícita?**

⏱️ Entrecomillando los valores que son texto.
🗣️ `["NO", "SE"]`, `"1.10"`, `"022"`, `"12:30"`. Las comillas son la forma que da YAML de decir "esto
es una cadena y no lo interpretes".
🔬 Pero la regla no es "entrecomillar todo": es **entrecomillar lo que es texto**. En Kubernetes,
`replicas: "3"` falla porque ahí sí se espera un número. La formulación correcta de la regla es:
todo lo que sea un código, un identificador, una versión o una hora va entrecomillado; lo que sea una
cantidad, no. Y para el esquema completo existen validadores —`kubeval`, esquemas JSON aplicados a
YAML— que lo comprueban en la integración continua.

**03 → 13. ¿Qué hace la clave de fusión `<<` y qué riesgo tiene?**

⏱️ Copia las claves de un mapa anclado dentro de otro. El riesgo es que no es portable.
🗣️ Es una extensión de YAML 1.1, no parte del núcleo, así que hay bibliotecas y herramientas que no
la soportan o la tratan como una clave literal llamada `<<`.
🔬 Es de las primeras cosas que se rompen al cambiar de parser o al pasar un archivo por una
herramienta distinta de la que lo escribió. Regla práctica: úsala en archivos que solo lee tu
herramienta; no la pongas en un archivo que va a cruzar herramientas o equipos.

**03 → 14. ¿Por qué las anclas permiten un ataque de expansión?**

⏱️ Porque un alias es una referencia y se puede anidar: diez niveles de diez referencias son 10^10
nodos desde un archivo de unas pocas líneas.
🗣️ Es la misma forma que el *billion laughs* de XML, con otra sintaxis. El archivo malicioso pesa
menos de un kilobyte y la expansión agota la memoria del proceso.
🔬 Por eso los parsers modernos limitan la profundidad y el número de alias expandidos, y por eso **un
YAML que viene de fuera se trata con el mismo cuidado que un XML de fuera**. La defensa completa
incluye además límite de tamaño de entrada y carga con la función segura de la pregunta siguiente.

**03 → 15. ¿Qué diferencia hay entre `yaml.load` y `yaml.safe_load`?**

⏱️ `load` puede construir objetos arbitrarios del lenguaje a partir de etiquetas del documento;
`safe_load` solo admite los tipos básicos.
🗣️ Es la diferencia entre leer un archivo y **ejecutar lo que diga**. Si el atacante controla el
YAML, con `load` controla qué objetos se instancian, y de ahí sale ejecución remota de código.
🔬 Verificado: `safe_load` rechaza una etiqueta `!!python/object/apply:...` con *"could not determine
a constructor for the tag"*. En Java es lo mismo con otro nombre —SnakeYAML necesita un
`SafeConstructor`—, con la diferencia de que **SnakeYAML 2.x cambió el valor por defecto a seguro**,
así que ahí hay que saber qué versión se está usando. Las vulnerabilidades de esta familia no son
teóricas: han producido ejecución remota en aplicaciones muy conocidas, siempre con la misma forma.

**03 → 16. ¿Por qué `replicas: "3"` falla en Kubernetes si entrecomillar era la recomendación?**

⏱️ Porque ahí el esquema espera un entero, y `"3"` es una cadena.
🗣️ La recomendación nunca fue entrecomillar todo: era entrecomillar **lo que es texto**. Una cantidad
es un número y debe ir sin comillas; un código que casualmente parece número es texto y debe llevarlas.
🔬 Esta pregunta existe para desmontar la regla mal aprendida, que es la que produce el otro fallo. La
formulación que funciona: *¿haría aritmética con este valor?* Si sí, número; si no, cadena
entrecomillada. Y cuando hay esquema —como en Kubernetes— el esquema manda, y se valida en la
integración continua en vez de descubrirlo en el despliegue.

**03 → 17. ¿Por qué YAML es más lento de parsear que JSON?**

⏱️ Porque su gramática es mucho mayor y además hay que resolver la conversión implícita de tipos.
🗣️ Un parser de JSON reconoce seis formas; uno de YAML tiene que manejar indentación significativa,
escalares de bloque, anclas, alias, etiquetas, documentos múltiples y una tabla de expresiones
regulares para decidir si `12:30` es un número.
🔬 En configuración da igual: se lee una vez al arrancar y son kilobytes. Donde importa es si alguien
propone YAML como formato de intercambio en caliente — ahí se paga el parser en cada mensaje, y
además se hereda toda la superficie de ataque del capítulo.

**03 → 18. El mismo archivo da tipos distintos en Go y en Java. ¿Por qué, y qué haces al respecto?**

⏱️ Porque implementan versiones distintas de la norma: `yaml.v3` aplica el esquema de 1.2 y SnakeYAML
el de 1.1. Se resuelve entrecomillando y validando contra un esquema.
🗣️ Verificado: `yes` es `true` en Java y `"yes"` en Go; `12:30` es `750` en Java y `"12:30"` en Go.
Ninguna de las dos bibliotecas tiene un bug: cumplen normas distintas.
🔬 Qué hago, en orden: **(1)** entrecomillar en el archivo todo lo que sea texto, que hace que las dos
lean lo mismo; **(2)** definir un esquema —JSON Schema aplicado al YAML— y validarlo en la
integración continua, en el mismo paso para los dos consumidores; **(3)** si el archivo es crítico,
una prueba que lo cargue con las dos bibliotecas y compare el resultado, que es cinco líneas y
detecta la divergencia el día que alguien añade Noruega.

**03 → 19. ¿Cuándo usarías `|-` en vez de `|`, y qué se rompe si te equivocas?**

⏱️ Cuando el valor no debe llevar salto de línea final: una clave, un *token*, un hash. Se rompe la
comparación o la firma.
🗣️ `|` conserva el `\n` final del bloque; `|-` lo quita. Ese carácter invisible viaja dentro del
secreto y hace que el servidor remoto rechace la autenticación con un mensaje que no dice nada útil.
🔬 Es uno de los errores más frustrantes de depurar porque el valor **se ve idéntico** al imprimirlo:
solo se detecta comparando longitudes o mirando el `repr`. La regla práctica: si el valor va a un
sistema externo que lo compara byte a byte, `|-`; si es un fichero o un script, `|`, que ahí el salto
final sí hace falta.

**03 → 20. ¿Por qué YAML no debería ser el formato de una API?**

⏱️ Porque paga un parser enorme, una superficie de ataque grande y una ambigüedad de tipos que nadie
quiere en un contrato.
🗣️ Un contrato de API necesita que las dos partes lean exactamente lo mismo, y este capítulo entero
demuestra que con YAML eso depende de la biblioteca de cada extremo.
🔬 Añade dos razones operativas: el coste de parseo se paga por mensaje y no una vez al arrancar, y
las bibliotecas de YAML han acumulado más CVE que las de JSON precisamente por su superficie. La
excepción razonable es una API de administración que reciba manifiestos escritos a mano — y aun ahí
se convierte a un modelo validado en el borde, como hace Kubernetes.

**03 → 21. ¿Qué buscarías con `grep` en una revisión de seguridad de un proyecto que usa YAML?**

⏱️ `yaml.load(` sin cargador seguro, y la construcción de `Yaml()` en Java sin `SafeConstructor`.
🗣️ En Python, `yaml.load(x)` a secas o con `Loader=yaml.Loader`/`UnsafeLoader`. En Java, `new Yaml()`
en versiones 1.x, y cualquier uso de `Constructor` permisivo. En Go el riesgo es otro, porque
`yaml.v3` no instancia tipos arbitrarios.
🔬 Y dos búsquedas más que suelen dar fruto: de dónde **viene** el YAML —si hay una ruta desde una
petición HTTP o desde un archivo subido por un usuario hasta una carga, el riesgo es real y no
teórico— y si hay límite de tamaño antes de cargar, por lo de las anclas. Un `yaml.load` sobre un
archivo del propio repositorio es una deuda menor; sobre una entrada de usuario es un incidente.

**03 → 22. Una lista de países deja de funcionar al añadir Noruega. Explica la causa y las dos correcciones posibles.**

⏱️ `NO` se convirtió en el booleano falso. Se corrige entrecomillando, o cambiando de esquema de
tipos.
🗣️ El síntoma típico es que la lista pasa de tener códigos a tener un `False` en medio, y el error
aparece aguas abajo —al buscar el país, al comparar cadenas— lejos de donde se cargó el archivo.
🔬 Las dos correcciones: **(1)** comillas en el archivo, `["NO", "SE"]`, que funciona con cualquier
biblioteca y es lo que se hace; **(2)** forzar el esquema del parser para que no aplique los tipos
implícitos de 1.1 — en PyYAML se consigue con un cargador personalizado que quite los resolvedores
de booleano, y en SnakeYAML configurando el `Resolver`. La segunda es más limpia conceptualmente y
más frágil en la práctica, porque afecta a todo el archivo y el siguiente que lo toque no lo sabrá.
La respuesta senior menciona además la prevención: un esquema validado en integración continua que
declare que esa clave es una lista de cadenas.

**03 → 23. Un despliegue apunta a la versión equivocada y el archivo dice `version: 1.10`. Diagnostica.**

⏱️ `1.10` se leyó como número decimal, y como número `1.10` es `1.1`.
🗣️ El cero final desaparece porque en coma flotante no hay diferencia entre `1.10` y `1.1`. El
despliegue busca la versión `1.1`, que existe y es otra, así que no falla: hace lo incorrecto en
silencio.
🔬 Verificado: PyYAML, SnakeYAML y `yaml.v3` devuelven los tres `1.1` como flotante. La corrección son
comillas, y la prevención es un esquema que declare esa clave como cadena. Es el ejemplo perfecto de
por qué **una versión nunca es un número**: tampoco lo es en `package.json`, ni en un `pom.xml`, y por
eso el versionado semántico se escribe siempre como texto.

**03 → 24. ¿Por qué ninguna biblioteca estándar de los cinco lenguajes trae YAML, y qué implica?**

⏱️ Porque la especificación es enorme y cambiante, y ninguno quiso cargar con mantenerla. Implica que
el comportamiento depende por completo de la dependencia que elijas.
🗣️ Verificado: ni el JDK, ni Python, ni Go, ni Node lo traen. JSON sí está en Python, Go y Node; XML
está en Java, Python y Go. YAML, en ninguno.
🔬 Las implicaciones son tres y las tres importan: **(1)** las divergencias de este capítulo no son un
accidente, son la consecuencia directa de que cada implementación eligió su versión de la norma;
**(2)** hay una dependencia más que auditar y actualizar, y las bibliotecas de YAML acumulan CVE
precisamente por su superficie; **(3)** cambiar de biblioteca **cambia el significado de tus archivos**
— por eso una actualización de SnakeYAML 1.x a 2.x altera el comportamiento por defecto de la carga y
no es una actualización rutinaria.

**03 → 25. ¿Cuándo es preferible generar el YAML desde código en vez de escribirlo a mano?**

⏱️ Cuando hay muchos archivos parecidos, cuando los valores vienen de otro sitio, y cuando lo que
cambia entre entornos es sistemático.
🗣️ Es lo que hacen las herramientas de plantillas de Kubernetes, y el motivo es que la repetición a
mano es donde aparecen los errores de indentación, las claves duplicadas y las comillas olvidadas.
🔬 El reverso que hay que decir: generar YAML **anula su única ventaja**, que es ser legible y
comentable por una persona. Si nadie lo va a leer, el formato correcto es JSON y no YAML. Y hay una
trampa concreta al generar: **las plantillas de texto no saben de YAML**, así que un valor con dos
puntos o que empiece por `*` rompe el archivo generado; si se genera, se genera **serializando una
estructura** con la biblioteca, no interpolando texto. Eso también resuelve el entrecomillado solo.

**03 → 26. Escribe la política de uso de YAML de tu equipo: qué se entrecomilla, qué está prohibido, cómo se carga lo externo y cómo se verifica en la integración continua.**

⏱️ Comillas en todo lo que sea texto, prohibidas las anclas en archivos compartidos y la carga
insegura, y validación de esquema en cada *pull request*.
🗣️ La política:

```text
ENTRECOMILLAR   códigos, identificadores, versiones, horas, y todo lo que no sea una cantidad
NO ENTRECOMILLAR cantidades y booleanos reales, que el esquema espera tipados
PROHIBIDO       yaml.load sin cargador seguro; anclas y << en archivos que cruzan herramientas
EXTERNO         límite de tamaño + carga segura + validación de esquema, en ese orden
CI              validar cada YAML contra su esquema, y linter que marque tabuladores y claves duplicadas
```
🔬 Los dos puntos que casi nunca se escriben y son los que más devuelven: **las claves duplicadas**,
que en YAML son legales para muchos parsers y se resuelven quedándose con la última —un `linter` las
detecta y un parser no—; y **la prueba de doble biblioteca** para los archivos que leen dos
lenguajes, del caso de la pregunta 18. Y la política tiene que decir dónde vive el esquema y quién lo
mantiene, porque un esquema sin dueño deja de reflejar el archivo en dos meses.

**03 → 27. Tienes que soportar el mismo archivo de configuración desde un servicio Java y una herramienta Go. Di qué reglas impones para que ambos lean lo mismo.**

⏱️ Entrecomillar todo lo textual, prohibir las construcciones no portables y validar el archivo
contra un esquema único en la integración continua.
🗣️ Las reglas, en orden de importancia:

```text
1. Todo valor textual entrecomillado          → elimina la divergencia 1.1 / 1.2 de golpe
2. Sin anclas, alias ni clave de fusión <<    → 1.1 las tiene, el núcleo de 1.2 no
3. Sin fechas sin comillas                    → el tipo implícito de fecha difiere entre bibliotecas
4. Un único esquema, validado por ambos       → la fuente de verdad no es el archivo, es el esquema
5. Prueba que cargue con las dos bibliotecas y compare
```
🔬 La regla 1 es la que hace el 90 % del trabajo, porque todas las divergencias verificadas —`yes`,
`NO`, `12:30`— desaparecen en cuanto hay comillas. La 5 es la que da garantía: son cinco líneas en la
integración continua, cargan el archivo con SnakeYAML y con `yaml.v3`, serializan los dos resultados
a JSON y comparan. Detecta la divergencia el día que entra, no el día del despliegue. Y conviene
decir la alternativa de diseño: **si el archivo es crítico y lo leen dos lenguajes, el formato
correcto probablemente sea JSON**, y YAML solo la capa de edición que se convierte a JSON en el
`build`.

**03 → 28. Un archivo con anclas funciona en tu herramienta y falla en la del equipo vecino. Diagnostica y propón las dos salidas.**

⏱️ Su parser no soporta anclas o no soporta la clave de fusión `<<`, que es una extensión de 1.1 y no
del núcleo de 1.2.
🗣️ El síntoma delata cuál de las dos: si aparece una clave literal llamada `<<` en el resultado, es la
fusión; si falla al resolver `*nombre`, son los alias. Muchos parsers de 1.2 estricto no implementan
`<<` porque nunca fue parte del núcleo.
🔬 Las dos salidas: **(1)** quitar las anclas y repetir la configuración, aceptando la duplicación a
cambio de portabilidad — es lo correcto en un archivo que cruza herramientas; **(2)** mantenerlas y
**generar** una versión aplanada para el consumidor que no las soporta, con un paso en la integración
continua que las resuelva. La segunda conserva la comodidad de edición y añade un artefacto derivado,
que hay que versionar o regenerar siempre. Lo que no vale es dejar el archivo como está y pedirle al
equipo vecino que cambie de biblioteca.

**03 → 29. Escribe la prueba de integración continua que detecta que dos lenguajes leen el mismo YAML de forma distinta, y di qué cinco valores pondrías en el caso de prueba.**

⏱️ Cargar el archivo con las dos bibliotecas, volcar el resultado a JSON con claves ordenadas y
comparar las dos cadenas.
🗣️ La prueba:

```text
1. cada lenguaje carga el YAML con SU biblioteca
2. cada uno serializa el resultado a JSON canónico (claves ordenadas)
3. el paso de CI compara los dos JSON y falla si difieren, mostrando el diff
```
🔬 Los cinco valores del caso de prueba, elegidos para cubrir cada divergencia verificada: **`NO`** (el
booleano de Noruega), **`yes`** (booleano de 1.1), **`12:30`** (sexagesimal), **`022`** (octal) y
**`1.10`** (versión que se vuelve número). Con esos cinco, la prueba falla hoy y pasa en cuanto se
entrecomillan. Y conviene añadir un sexto que no es de tipos sino de estructura: una **clave
duplicada**, que muchos parsers aceptan quedándose con la última y un `linter` detecta. La prueba no
comprueba que el archivo sea correcto: comprueba que **ambos lean lo mismo**, que es una propiedad
distinta y la que de verdad importa aquí.

**03 → 30. Te piden aceptar YAML subido por usuarios en una herramienta interna. Escribe los controles, en orden, y qué rechazas antes de parsear.**

⏱️ Límite de tamaño y de profundidad antes de tocarlo, carga con la función segura, validación contra
esquema, y todo con tiempo límite.
🗣️ Los controles en orden, y el orden es la respuesta:

```text
ANTES DE PARSEAR   límite de tamaño (KB, no MB) · rechazar si contiene & o * si no permites anclas
AL PARSEAR         safe_load / SafeConstructor · límite de profundidad y de alias · timeout
DESPUÉS            validación contra esquema: claves permitidas, tipos, rangos
SIEMPRE            registrar qué se rechazó y por qué, sin volcar el contenido completo al log
```
🔬 Tres razones para ese orden. **(1)** El límite de tamaño va primero porque es el único control que
no requiere haber leído el archivo, y el ataque de expansión de alias empieza con un archivo
diminuto: limitar el tamaño **no** basta contra él, por eso hace falta además el límite de alias del
segundo bloque. **(2)** La carga segura va antes que la validación de esquema porque la carga
insegura ya ejecuta código: validar después no sirve de nada si el daño ocurrió al parsear. **(3)** La
lista blanca de claves es mejor que la lista negra, y conviene decirlo: en una herramienta interna es
perfectamente viable declarar exactamente qué claves se aceptan y rechazar el resto. Y el cierre
honesto: si la herramienta puede aceptar JSON en vez de YAML, casi todo esto desaparece.

---

# 04 — CSV y los formatos tabulares

**04 → 1. ¿Qué norma define CSV?**

⏱️ Ninguna que obligue. Lo más parecido es RFC 4180, que es **Informational**.
🗣️ Ese RFC no impone nada: documenta lo que hacía la mayoría en 2005. Por eso conviven delimitadores,
codificaciones y finales de línea distintos sin que ninguno sea "el incorrecto".
🔬 La categoría se comprueba en la cabecera del propio documento, y saber distinguirla es lo que
permite responder bien: un *Standards Track* obliga, un *Informational* describe. De ahí que todo
intercambio en CSV necesite un acuerdo escrito y no una referencia a un RFC.

**04 → 2. ¿Cuándo hay que entrecomillar un campo?**

⏱️ Cuando contiene el delimitador, una comilla doble o un salto de línea.
🗣️ Fuera de esos casos las comillas son opcionales, y la mayoría de los generadores las omiten para
ahorrar espacio. Algunos las ponen siempre, que también es válido y más seguro.
🔬 Un lector correcto tiene que aceptar las dos formas en el mismo archivo, campo a campo. Y hay una
variante que conviene conocer: los espacios **fuera** de las comillas no están definidos por el RFC,
así que `a, "b"` es terreno ambiguo y cada biblioteca decide — motivo de más para acordar el formato.

**04 → 3. ¿Cómo se escribe una comilla dentro de un campo entrecomillado?**

⏱️ Duplicándola: `""`.
🗣️ `"Muebles ""El Roble"", S.A."` es un solo campo cuyo valor es `Muebles "El Roble", S.A.`. No se
escapa con barra invertida: CSV no tiene escapes de barra.
🔬 Es la diferencia que rompe a quien viene de JSON y aplica `\"` por costumbre: el resultado es un
campo con una barra literal dentro y, según el parser, un archivo que deja de cuadrar a partir de ahí.
Verificado en el capítulo: Python y Go leen la forma duplicada idénticamente.

**04 → 4. ¿Puede un campo contener un salto de línea?**

⏱️ Sí, si el campo va entre comillas.
🗣️ Y esa es la razón por la que "una línea es un registro" es falso, y por la que un bucle de
`readLine()` parte los registros por la mitad en cuanto aparece una dirección postal.
🔬 Verificado: un campo con `Calle 5\nBogotá` se lee como un único valor con Python y con Go. El
efecto práctico es que **no se puede contar registros contando líneas**, ni trocear el archivo por
líneas para paralelizar sin un parser que respete las comillas.

**04 → 5. ¿Distingue CSV entre nulo y cadena vacía?**

⏱️ No. `a,,b` no dice cuál de los dos es.
🗣️ Los dos se escriben igual: nada entre delimitadores. Si el dominio los distingue —una fecha de
baja ausente frente a una cadena vacía—, el formato no puede expresarlo.
🔬 La salida es acordar un centinela explícito —`\N` como hace PostgreSQL en su `COPY`, o `NULL`, o
una columna adicional— y escribirlo en el acuerdo de intercambio. Lo que no vale es asumir: la mitad
de las importaciones con datos raros vienen de que un lado interpretó el vacío como nulo y el otro
como cadena.

**04 → 6. ¿Trae Java un lector de CSV en el JDK?**

⏱️ No. Hay que usar Apache Commons CSV u OpenCSV.
🗣️ Sorprende siendo el lenguaje con más carga de procesos por lotes del mercado, y es una pregunta
donde la respuesta correcta es simplemente "no está, y uso Commons CSV".
🔬 De los cinco lenguajes del corpus, solo Python y Go lo traen. Commons CSV además incluye formatos
predefinidos —`RFC4180`, `EXCEL`, `TDF`— que resuelven de una línea el acuerdo de delimitador y
comillas con la contraparte.

**04 → 7. ¿Qué es el BOM y para qué se usa en un CSV?**

⏱️ Tres octetos al principio del archivo (`EF BB BF`) que marcan que el contenido es UTF-8.
🗣️ No es texto: es una marca. Se usa porque CSV no lleva su codificación dentro y porque es lo que
hace que Excel en Windows detecte UTF-8 en lugar de aplicar la página de códigos local.
🔬 Es específico de una herramienta, es feo y es lo que funciona. Su coste está en la pregunta 14: un
parser que no lo espere se lo encuentra pegado al primer nombre de columna.

**04 → 8. ¿Qué es la inyección de fórmulas en CSV?**

⏱️ Que una celda que empieza por `=`, `+`, `-` o `@` la interpreta como fórmula la hoja de cálculo que
la abra.
🗣️ Si tu exportación incluye texto escrito por usuarios, un usuario puede colocar una fórmula que se
ejecutará en el escritorio de otra persona: leer otras celdas y enviarlas a una URL, o invocar
programas externos con la confirmación del usuario.
🔬 El vector no es tu aplicación, es el consumidor del archivo, y por eso se escapa de casi todas las
revisiones de seguridad. La defensa es de una línea al exportar: si el valor empieza por uno de esos
cuatro caracteres, se antepone un apóstrofo o se fuerza el tipo texto. OWASP lo documenta como *CSV
Injection*.

**04 → 9. ¿Por qué RFC 4180 no obliga a nadie?**

⏱️ Porque su categoría es *Informational*, no *Standards Track*.
🗣️ Se publicó en 2005, veinte años después de que el formato ya estuviera en uso, con el objetivo de
registrar el tipo de medio `text/csv` y describir la práctica común. No podía obligar a nadie porque
ya había millones de archivos escritos de otras formas.
🔬 Y es un buen ejemplo de la distinción que conviene manejar: una norma puede describir o puede
mandar, y saber cuál es cada documento cambia lo que puedes exigirle a un proveedor. Con CSV no
puedes exigir conformidad: solo puedes acordar un formato.

**04 → 10. ¿Por qué en español el separador suele ser punto y coma?**

⏱️ Porque el separador decimal es la coma, y no puede ser a la vez el delimitador de campos.
🗣️ `1.234,56` con delimitador coma sería ilegible o exigiría entrecomillar todos los números. Por eso
Excel en configuración regional española genera y espera punto y coma.
🔬 El resultado es el síntoma más común del intercambio internacional: el mismo archivo se abre en
columnas en una máquina y en una sola columna en otra, sin que nadie haya hecho nada mal. Se resuelve
acordando el delimitador por escrito, o entregando `.xlsx`, que no tiene el problema.

**04 → 11. ¿Qué le pasa a `007` al abrir el archivo en una hoja de cálculo?**

⏱️ Se convierte en `7`: la hoja lo interpreta como número y pierde los ceros a la izquierda.
🗣️ Y no es el único: `1-2` se convierte en una fecha, un identificador largo pasa a notación
científica y un teléfono pierde el `+`. **El archivo estaba bien**; lo rompió el visor.
🔬 Lo grave viene después: si el usuario guarda el archivo desde la hoja de cálculo, la corrupción se
escribe en disco y ya es real. Verificado que los parsers de Python y Go devuelven `'007'` intacto,
así que el problema nunca es el formato ni la biblioteca. Las mitigaciones son `.xlsx`, o una columna
declarada como texto, o aceptar que el consumidor humano va a romperlo y validar al recibirlo de
vuelta.

**04 → 12. ¿Por qué falla `split(',')` y con qué dato concreto?**

⏱️ Con cualquier campo que contenga una coma. El caso canónico es una razón social:
`Muebles "El Roble", S.A.`
🗣️ Verificado: la línea de ejemplo del capítulo tiene cuatro campos y `split(',')` devuelve cinco, con
el segundo partido por la mitad. A partir de ahí todas las columnas se desplazan y los datos entran
en los campos equivocados **sin ningún error**.
🔬 Y los otros dos casos que lo rompen igual: las comillas duplicadas y el salto de línea dentro del
campo. `split` es correcto exactamente cuando tú generas el archivo y controlas los datos; en cuanto
entra texto de un tercero, deja de serlo. No hay ninguna ganancia de rendimiento en usarlo: un parser
correcto es también una pasada `O(n)`.

**04 → 13. ¿Por qué `readLine()` no basta para leer registros?**

⏱️ Porque un campo entrecomillado puede contener saltos de línea, y entonces un registro ocupa varias
líneas.
🗣️ El bucle de `readLine()` entrega media dirección postal como si fuera un registro completo, y el
resto como otro. Igual que con `split`, no hay error: hay datos mal.
🔬 Tiene dos consecuencias que se preguntan: **no se puede contar registros contando líneas**, y **no
se puede trocear el archivo por líneas** para repartirlo entre hilos o entre trabajos sin un parser
que respete las comillas. Es justo lo que hace que paralelizar la importación de un CSV grande sea
menos trivial de lo que parece.

**04 → 14. ¿Qué problema causa el BOM a un parser que no lo espera?**

⏱️ Que se pega al primer nombre de columna: la clave deja de ser `id` y pasa a ser `﻿id`.
🗣️ El síntoma es un `KeyError: 'id'` o un campo que sale siempre vacío, mientras el archivo **se ve
perfecto** en cualquier editor, porque el BOM es invisible.
🔬 La corrección es abrir con la codificación que lo consume —en Python, `encoding='utf-8-sig'`— o
quitarlo explícitamente. Y es una asimetría incómoda que conviene tener presente: **lo que hace falta
para que Excel lo lea bien es exactamente lo que rompe al parser del otro lado**, así que el acuerdo
de intercambio tiene que decir si lleva BOM o no.

**04 → 15. ¿Qué resuelven `DictReader` de Python y `FieldsPerRecord` de Go?**

⏱️ El descuadre entre la cabecera y las filas: qué hacer cuando una fila tiene más o menos campos de
los esperados.
🗣️ `DictReader` mapea cada fila a un diccionario usando la cabecera, y deja los campos sobrantes en
una clave especial y los que faltan como nulos. `FieldsPerRecord` de Go comprueba el número de campos
y falla si no coincide.
🔬 Son dos filosofías —tolerar y avisar frente a fallar— y la elección depende de si prefieres
procesar un archivo imperfecto o rechazarlo. Lo que no se puede es ignorarlo: una fila descuadrada
que pasa en silencio mete todos los valores en la columna equivocada, y ese error se descubre semanas
después en un informe.

**04 → 16. ¿Cuánto ocupa un CSV frente a un JSON con los mismos datos tabulares?**

⏱️ Entre dos y cuatro veces menos.
🗣️ La razón es que CSV escribe los nombres de columna **una vez**, en la cabecera, y JSON los repite
en cada objeto. Con diez columnas y un millón de filas, eso son diez millones de nombres de campo
repetidos.
🔬 Comprimido, la diferencia se reduce mucho, porque las claves repetidas son justo lo que el
compresor elimina mejor. Pero sigue habiendo una diferencia real en memoria y en tiempo de parseo, y
por eso para datos tabulares grandes CSV no compite con JSON: compite con formatos columnares como
Parquet.

**04 → 17. ¿Cuál es el coste en memoria de parsear CSV correctamente?**

⏱️ `O(1)` por registro: es una máquina de estados de una pasada.
🗣️ El parser lee carácter a carácter, mantiene si está dentro de comillas o no, y emite campos. No
necesita ver el archivo entero ni retroceder.
🔬 Es el formato del bloque que mejor se comporta con volumen: `O(n)` en tiempo, `O(1)` en memoria y
troceable si respetas las comillas. La memoria se dispara solo si **tú** acumulas —cargar el archivo
entero en una lista es la forma habitual de arruinarlo— y ese es el error, no el formato.

**04 → 18. ¿Cuándo dirías que CSV es la elección correcta frente a JSON?**

⏱️ Cuando los datos son tabulares, homogéneos, muchos, y el consumidor es un proceso o una hoja de
cálculo.
🗣️ Volcados de base de datos, importaciones masivas, informes que alguien va a abrir en Excel,
intercambio con sistemas antiguos. Ahí CSV ocupa menos, se procesa en flujo de forma natural y lo
entiende todo el mundo.
🔬 Y el reverso: en cuanto hay anidamiento, tipos que importen o campos opcionales por registro, CSV
empieza a necesitar convenciones inventadas —columnas con JSON dentro, centinelas, columnas
repetidas— y eso es la señal de que el formato ya no encaja. La frase que resume: **CSV es correcto
mientras los datos quepan en una tabla sin trucos**.

**04 → 19. Te piden distinguir nulo de vacío en un CSV. ¿Qué propones?**

⏱️ Un centinela explícito y documentado, o una columna acompañante.
🗣️ Las opciones reales: un valor imposible acordado —`\N`, que es lo que usa PostgreSQL en `COPY`—;
distinguir el campo vacío sin comillas del campo `""` con comillas, que algunos parsers respetan;
o una columna booleana adicional para los casos en que de verdad importe.
🔬 La primera es la que funciona entre herramientas distintas, y hay que elegir un centinela que no
pueda aparecer como dato real — lo que obliga a escapar el centinela si aparece, que es el detalle
que se olvida. La segunda es la más elegante y la menos portable: muchos parsers no la conservan. Y
la respuesta que conviene decir antes que ninguna: **si la distinción es importante, CSV puede no ser
el formato**, y proponer JSON Lines para ese intercambio es legítimo.

**04 → 20. ¿Cómo se sanea una exportación con texto de usuario, y por qué es responsabilidad tuya?**

⏱️ Anteponiendo un apóstrofo o forzando texto en toda celda que empiece por `=`, `+`, `-` o `@`. Es
tuya porque tú produces el archivo.
🗣️ El principio es el mismo de siempre —escapar en la frontera de salida, según el consumidor— solo
que aquí el consumidor no es un navegador sino una hoja de cálculo, y por eso se olvida.
🔬 El argumento de responsabilidad es el que hay que saber defender en una reunión: el usuario que
abre el archivo no tiene forma de protegerse, no eligió el contenido y confía en que tu exportación
sea datos. Decir "es un problema de Excel" es cierto y es irrelevante: tú eres quien puede evitarlo
con una línea. Y conviene medirlo: si la exportación incluye **cualquier** campo de texto libre
escrito por otro, aplica.

**04 → 21. Los acentos se rompen solo para algunos usuarios. Diagnostica la cadena entera.**

⏱️ El archivo va en UTF-8 sin BOM y esos usuarios lo abren con una herramienta que aplica la página de
códigos local.
🗣️ La pista que lo resuelve es que dependa del usuario y no del dato: el archivo es idéntico para
todos, así que el fallo está en quién lo abre. Si dependiera del dato, sería un problema de
conversión en el servidor.
🔬 La cadena completa que hay que recorrer, y dónde puede romperse cada eslabón: **cotejamiento de la
base de datos** → **codificación de la conexión** → **cadenas en memoria** → **codificación al
escribir el archivo** → **`charset` declarado en la respuesta HTTP** → **la herramienta que lo abre**.
Se confirma con un volcado hexadecimal del archivo generado: si `ñ` son los octetos `C3 B1`, el
archivo es UTF-8 correcto y el problema está en el último eslabón. La corrección es BOM, `charset` en
el `Content-Type` y, si el destinatario siempre es una hoja de cálculo, proponer `.xlsx`.

**04 → 22. ¿Por qué proponer `.xlsx` puede ser mejor respuesta que arreglar el BOM?**

⏱️ Porque elimina la clase entera de problemas en vez de parchear uno: lleva codificación y tipos
dentro del archivo.
🗣️ Con `.xlsx` no hay BOM, no hay delimitador que negociar, no hay `007` convertido en 7 y no hay
inyección de fórmulas por texto plano. El formato declara qué es cada celda.
🔬 El coste hay que decirlo también, porque si no la propuesta no es honesta: necesita una biblioteca
—Apache POI, `openpyxl`— que es mucho más pesada que escribir CSV; no se procesa en flujo con la
misma facilidad; y si el consumidor real era un proceso automático y no una persona, es un paso
atrás. La regla: **si el destinatario es humano, `.xlsx`; si es una máquina, CSV bien acordado**.

**04 → 23. Un fichero de diez millones de filas hay que agregarlo por cliente. ¿Qué estructura y qué coste en memoria?**

⏱️ Un mapa de cliente a acumulador, leyendo en flujo. La memoria es proporcional al número de clientes
distintos, no al de filas.
🗣️ Se lee fila a fila, se actualiza la entrada del mapa y se descarta la fila. Diez millones de filas
con cincuenta mil clientes son cincuenta mil entradas en memoria, que son unos pocos megas.
🔬 Tres detalles que completan la respuesta. **(1)** Si los clientes distintos también son millones, el
mapa deja de caber y la respuesta cambia: ordenar el archivo por cliente y agregar por grupos
contiguos, que es memoria constante a cambio de un ordenamiento externo — el clásico patrón de
*sort-merge*. **(2)** Si el archivo viniera **ya ordenado** por cliente, la agregación es directa en
`O(1)` de memoria, y preguntarlo es lo primero que hay que hacer. **(3)** Los importes se acumulan en
entero de céntimos o `BigDecimal`, no en `double`, por lo de `06-numeros-tiempo-concurrencia/01`:
diez millones de sumas en coma flotante acumulan error visible.

**04 → 24. ¿Por qué no se puede paralelizar la lectura de un CSV troceándolo por bytes?**

⏱️ Porque un corte arbitrario puede caer **dentro de un campo entrecomillado**, y entonces el trozo
siguiente no sabe si empieza dentro o fuera de comillas.
🗣️ Es la misma razón por la que `readLine()` no basta: un salto de línea dentro de comillas no termina
un registro, así que "empezar a leer desde el siguiente salto de línea" puede empezar a mitad de una
dirección postal y desplazar todas las columnas del trozo.
🔬 Las salidas reales: **(1)** una pasada previa que localice los límites reales de registro y reparta
por ellos, que es `O(n)` pero secuencial y barata; **(2)** garantizar por contrato que el archivo no
tiene saltos ni comillas dentro de campos, y entonces el troceado por líneas sí vale — es lo que
hacen muchos sistemas de datos, declarándolo; **(3)** usar un formato pensado para trocearse, como
NDJSON o un columnar. La respuesta completa menciona que este problema no es de CSV en particular:
lo tiene todo formato donde el significado de un byte dependa del estado acumulado.

**04 → 25. ¿Qué ventaja tiene un formato columnar frente a CSV, y cuándo compensa el cambio?**

⏱️ Lee solo las columnas que necesitas, comprime mucho mejor y lleva tipos y esquema dentro. Compensa
cuando hay analítica repetida sobre el mismo volumen.
🗣️ En CSV, para sumar una columna hay que leer y parsear todas las demás. En un columnar, esa columna
está contigua en disco: se lee una fracción de los bytes y se comprime mejor, porque valores del
mismo tipo juntos se comprimen mucho más que filas mezcladas. Además trae estadísticas por bloque, con
lo que se pueden saltar bloques enteros.
🔬 Cuándo **no** compensa, que es lo que completa la respuesta: si el archivo se escribe una vez y se
lee una vez, si el consumidor es una persona con una hoja de cálculo, o si el intercambio es con un
socio que solo acepta texto. El coste del cambio es una dependencia, un formato que no se inspecciona
con `head`, y un paso de conversión. La regla: **CSV para intercambiar, columnar para analizar**, y
muchas plataformas hacen exactamente eso — reciben CSV y lo convierten al ingerir.

**04 → 26. Te dan un CSV con cabecera y otro sin ella, del mismo origen. ¿Cuál prefieres y por qué?**

⏱️ Con cabecera, porque hace el archivo autodescriptivo y desacopla el orden de las columnas.
🗣️ Sin cabecera, el contrato es posicional: si el emisor inserta una columna en medio, todo lo demás
se desplaza y **el archivo sigue pareciendo válido**. Es el fallo silencioso más caro de este formato.
Con cabecera, el lector mapea por nombre y detecta el cambio.
🔬 El argumento a favor de no llevarla existe y hay que reconocerlo: en ficheros de intercambio de
volumen muy alto, la cabecera obliga a tratar la primera línea de forma especial al trocear, y algunos
formatos heredados de posición fija no la contemplan. La postura defendible es: **cabecera siempre,
y además validarla** —comprobar que los nombres y el orden son los esperados y fallar si no—, porque
una cabecera que nadie comprueba solo documenta, no protege.

**04 → 27. Escribe el acuerdo de intercambio de CSV con un socio: los cinco puntos que hay que fijar y qué pasa si falta cada uno.**

⏱️ Delimitador, codificación, comillas, fin de línea y representación de nulos y decimales.
🗣️ El acuerdo, con la consecuencia de omitir cada punto:

```text
1. DELIMITADOR      coma o punto y coma      → falta: el archivo se abre en una sola columna
2. CODIFICACIÓN     UTF-8, con o sin BOM     → falta: acentos rotos para media plantilla
3. COMILLAS         cuándo y cómo se escapan → falta: las razones sociales descuadran las columnas
4. FIN DE LÍNEA     CRLF o LF                → falta: un campo de más o un carácter \r pegado al último
5. NULOS Y DECIMALES centinela y separador   → falta: vacíos ambiguos e importes mal leídos
```
🔬 Y tres puntos más que conviene añadir aunque no se pidan: **cabecera sí o no y con qué nombres
exactos**, porque cambiar el orden de las columnas sin cabecera es un incidente silencioso; **qué
pasa con las filas inválidas**, si abortan el archivo o se rechazan individualmente; y **cómo se
declara el fin del archivo**, porque un archivo truncado por un fallo de red es indistinguible de uno
completo si nadie manda un recuento de filas o un hash. Ese último punto es el que más disgustos
evita en un intercambio diario real.

**04 → 28. Diseña la importación robusta de un CSV de origen desconocido: validación, filas descuadradas, codificación, informe de errores y qué haces con la fila 4 000 001 que viene mal.**

⏱️ Validar en dos fases, procesar en flujo, rechazar por fila y no por archivo, y acumular un informe
de errores con número de línea.
🗣️ El diseño:

```text
FASE 0  detectar: codificación (BOM y heurística), delimitador, cabecera. CONFIRMAR con el emisor.
FASE 1  pasada de validación: contar filas, campos por fila, tipos por columna. Nada se escribe.
FASE 2  pasada de carga: en flujo, por lotes, con transacción por lote y no por archivo.
ERRORES fila rechazada → archivo de rechazos con número de línea, contenido original y motivo.
FINAL   informe: filas leídas, cargadas, rechazadas, y las 20 primeras causas agrupadas.
```
🔬 La pregunta de la fila 4 000 001 es la que decide la respuesta, y tiene tres salidas defendibles
según el contrato: **abortar** y no cargar nada —correcto si el archivo es un estado completo que
sustituye al anterior, porque una carga parcial deja el sistema inconsistente—; **saltar y registrar**
—correcto en datos de hechos independientes, y es lo habitual—; o **parar y pedir intervención**, si
el volumen de rechazos supera un umbral, porque cien mil rechazos no son filas malas: son un archivo
mal acordado. Lo que no es defendible es ninguna de las tres **sin haberlo decidido antes**: la peor
importación es la que carga cuatro millones de filas, muere, y deja al operador sin saber qué entró.
Por eso la fase 1 existe: es barata comparada con descubrir el problema a mitad de la carga, y
permite rechazar el archivo entero antes de tocar nada.

**04 → 29. Diseña la exportación de un informe de diez millones de filas que un usuario descarga desde el navegador. Di qué pasa con la memoria, el tiempo y los errores a mitad.**

⏱️ Asíncrona: el usuario pide, el servidor genera en segundo plano y le avisa con un enlace. La
descarga directa no es viable.
🗣️ Por qué no se hace síncrona, con los tres problemas:

```text
MEMORIA  si se construye la respuesta entera, son gigas por petición. Hay que escribir en flujo.
TIEMPO   diez millones de filas tardan minutos; ningún balanceador ni navegador espera eso.
ERRORES  si falla a la mitad, el usuario ya recibió 200 OK y medio archivo: no hay forma de avisar.
```
🔬 El diseño: `POST /informes` devuelve `202` y un identificador; un trabajo en segundo plano genera el
CSV **en flujo** hacia el almacenamiento de objetos; el usuario consulta el estado y descarga con una
URL prefirmada cuando está listo. Eso resuelve los tres a la vez: la memoria es constante, el tiempo
deja de importar y un fallo a mitad deja el trabajo en estado `ERROR` con un motivo, sin haber
entregado nada. **El tercer problema es el decisivo y el que casi nadie menciona**: con la descarga
directa, un error después del primer byte es indistinguible de un archivo completo, porque el código
de estado ya se envió — la única mitigación en ese modelo es un recuento de filas al final que el
consumidor tenga que comprobar. Si el volumen fuera pequeño, la respuesta en flujo con `chunked` sí
sería correcta y mucho más simple, y decir dónde está esa frontera forma parte de la respuesta.

**04 → 30. Un socio te entrega ficheros diarios y un día llega uno truncado por un fallo de red. Diseña la detección y la recuperación.**

⏱️ Detección por metadatos que acompañen al fichero —recuento de filas y hash— y recuperación
reintentando la entrega completa, nunca completando lo que falta.
🗣️ El diseño:

```text
DETECCIÓN   fichero de control junto al de datos: nº de registros, suma de un importe, SHA-256
            + comprobar que la última línea termina en salto de línea
PROCESO     validar el control ANTES de cargar nada; si no cuadra, no se procesa
RECUPERACIÓN pedir reenvío completo; la carga es idempotente por (socio, fecha, hash)
ALERTA      avisar al socio y al operador el mismo día, no al cerrar el mes
```
🔬 Tres puntos que hacen la diferencia. **(1) Un fichero truncado es sintácticamente válido**: CSV no
tiene marca de fin, así que sin metadatos externos no hay forma de distinguirlo de uno completo — por
eso el fichero de control no es burocracia, es el único mecanismo. **(2) Nunca se completa un fichero
parcial** con el reenvío: se descarta y se carga el nuevo entero, porque no hay garantía de que el
corte cayera en un límite de registro ni de que el contenido no haya cambiado. **(3) La idempotencia
de la carga** es lo que hace segura la recuperación: si se identifica por socio, fecha y hash, un
reenvío del mismo fichero no duplica nada y un reenvío de uno corregido se distingue solo. Y la
comprobación barata que conviene añadir aunque no haya fichero de control: **que el último byte sea un
salto de línea** detecta buena parte de los truncamientos por unos pocos microsegundos de coste.

---

# 05 — Simulación: preguntas transversales

**05 → S1. Tienes que elegir formato para una API pública nueva. ¿Cuál y por qué no los otros tres?**

⏱️ JSON, porque lo parsea todo el mundo sin dependencias y el contrato se valida con JSON Schema si
hace falta.
🗣️ XML no, porque pagaría espacios de nombres, esquema y firma que no voy a usar, y obligaría a mis
consumidores a traer una biblioteca. YAML no, porque su ambigüedad de tipos es inaceptable en un
contrato. CSV no, porque no representa anidamiento.
🔬 La respuesta cambia si el dominio impone un estándar —ISO 20022, facturación electrónica— o si
necesito firmar una parte del mensaje: ahí XML sí. Decir esa excepción es lo que convierte una
preferencia en un criterio.

**05 → S2. ¿Y para un fichero de intercambio diario de diez millones de registros?**

⏱️ CSV, y con un acuerdo escrito de cinco puntos.
🗣️ Ocupa entre dos y cuatro veces menos que JSON, se procesa en flujo de forma natural y lo lee
cualquier herramienta. Diez millones de objetos JSON repetirían los nombres de campo diez millones
de veces.
🔬 Si los datos no son tabulares, NDJSON —un JSON por línea— conserva el anidamiento y la capacidad de
trocear por líneas. Y si el consumidor es analítico y el volumen sigue creciendo, lo que compite ya
no es JSON sino un formato columnar como Parquet.

**05 → S3. ¿Y para la configuración de un servicio?**

⏱️ YAML, porque admite comentarios y lo va a editar una persona.
🗣️ Es la única razón de peso: un archivo de configuración se lee en una revisión de código y necesita
explicarse. A cambio hay que asumir las reglas del capítulo `03`, empezando por entrecomillar todo lo
textual.
🔬 Si el archivo lo genera una herramienta y no lo edita nadie, JSON es mejor: menos ambigüedad, menos
superficie y más rápido. Y si lo leen dos lenguajes distintos, la respuesta honesta es JSON con una
capa YAML de edición que se convierte en el `build`.

**05 → S4. ¿Y para un mensaje de pago hacia un banco?**

⏱️ El que diga el banco, que casi siempre será XML con un XSD, y no es negociable.
🗣️ ISO 20022 define esquemas XML para pagos, y el cumplimiento suele ser contractual o legal. La
pregunta técnica no es qué formato prefiero sino si mi servicio puede validar contra ese XSD y firmar
lo que haga falta.
🔬 Y de ahí sale una consecuencia de arquitectura que conviene decir: si el lenguaje elegido no
soporta bien XSD ni firma parcial —Go, por ejemplo— ese servicio concreto probablemente deba estar en
otro lenguaje, en lugar de reimplementar medio JAXP.

**05 → S5. ¿Cuál de los cuatro tiene contrato validable de serie, y qué compra eso?**

⏱️ XML, con XSD. Compra rechazar lo inválido antes de que llegue a la lógica de negocio.
🗣️ El resto lo tiene añadido o no lo tiene: JSON con JSON Schema, que es externo y hay que elegir
validador; YAML se valida con esquemas JSON; CSV no tiene nada.
🔬 Lo que compra en la práctica es un error preciso —elemento y línea—, una frontera clara de
responsabilidad con el socio y menos código defensivo dentro. Lo que cuesta es otro recorrido `O(n)`
y mantener el esquema vivo: un XSD que ya no refleja la realidad es peor que no tenerlo.

**05 → S6. ¿Cuál ocupa menos y cuánto menos? Da el orden con números.**

⏱️ CSV, luego JSON con entre dos y cuatro veces más, y XML con entre dos y cinco veces más que JSON.
🗣️ La razón es la repetición de nombres: CSV los escribe una vez en la cabecera, JSON en cada objeto y
XML dos veces por elemento, en la apertura y en el cierre.
🔬 Y el matiz que hay que añadir siempre: **comprimido, las diferencias casi desaparecen**, porque la
repetición es justo lo que un compresor elimina. Por eso el argumento del tamaño es el más débil de
todos, y el que de verdad decide es el coste de memoria al parsear y la expresividad.

**05 → S7. Nombra tres datos que ninguno de los cuatro formatos representa de forma nativa.**

⏱️ Dinero con precisión decimal, instantes con zona horaria, y binarios.
🗣️ A esos tres se pueden añadir dos más: la distinción entre nulo y ausente —que solo JSON y XML
expresan, y cada uno a su manera— y las referencias entre nodos, porque los cuatro son árboles o
tablas, no grafos.
🔬 Todos se resuelven igual: con un **acuerdo escrito** —cadena decimal con divisa, ISO-8601 con zona,
Base64 o referencia externa— y todos fallan igual, en silencio, cuando ese acuerdo no está escrito y
cada lado supone el suyo.

**05 → S8. ¿Cómo viaja una fecha en cada uno de los cuatro?**

⏱️ Como texto ISO-8601 en JSON, XML y CSV; en YAML, cuidado, porque muchas bibliotecas la convierten
en objeto fecha sola.
🗣️ XML es el único con tipo de fecha **en el esquema**: `xs:date` y `xs:dateTime` los valida el XSD.
En JSON y CSV es una convención que no valida nadie salvo tu código.
🔬 La conversión automática de YAML es la trampa: `fecha: 2026-09-18` sale como objeto fecha en unas
bibliotecas y como cadena en otras, y al reserializar puede cambiar de formato. La regla que evita
todo esto es la misma de siempre: **entrecomillar en YAML, y declarar el formato exacto en el
contrato** — no "una fecha", sino ISO-8601 con zona para instantes y sin ella para fechas de
calendario.

**05 → S9. ¿Cómo viaja el dinero, y por qué no como `number`?**

⏱️ Como cadena decimal con la divisa al lado, o como entero de la unidad mínima. No como `number`
porque en el otro extremo es un `double`.
🗣️ `{"importe": "1250.00", "divisa": "COP"}` sobrevive a cualquier parser. `{"importe": 1250.00}`
depende de que el receptor no lo lea como coma flotante, cosa que JavaScript hace siempre.
🔬 Y la divisa no es decoración: un importe sin divisa no es un importe, y ponerla dentro del mismo
objeto impide que alguien sume cifras de monedas distintas. El desarrollo está en
`06-numeros-tiempo-concurrencia/01`, y aquí lo que se evalúa es que el formato de intercambio no
deshaga lo que el tipo del dominio protegía.

**05 → S10. Un identificador numérico largo. ¿Qué le pasa en cada formato y en cada lenguaje?**

⏱️ En JSON se corrompe en JavaScript y en Go con mapa genérico; en XML, YAML y CSV viaja como texto y
sobrevive — salvo que alguien lo convierta.
🗣️ Verificado: `9007199254740993` llega como `...992` en JavaScript y como `9.007199254740992e+15` en
Go sin `UseNumber()`. En Java con Jackson y en Python llega exacto.
🔬 En XML y CSV el contenido es texto por definición, así que el riesgo no está en el formato sino en
el mapeo: un `xs:long` o un `int` en el `struct` lo vuelve a poner en juego. Y en CSV hay un riesgo
extra que no es de parseo sino de visor: la hoja de cálculo lo pasa a notación científica al abrirlo.
La conclusión es la misma en los cuatro: **los identificadores son texto de punta a punta**.

**05 → S11. ¿Qué formatos distinguen nulo de cadena vacía y cuáles no?**

⏱️ JSON sí, con `null`. XML sí, con `xsi:nil` o con el elemento ausente. YAML sí. CSV **no**.
🗣️ En CSV, `a,,b` es la misma secuencia de octetos para los dos casos, y por eso hay que acordar un
centinela como `\N`.
🔬 Y hay una segunda distinción que se olvida y que importa más: **nulo frente a ausente**. En JSON,
`{"nota": null}` y `{}` son documentos distintos, y muchos contratos no dicen cuál significa qué —en
un `PATCH` con Merge Patch la diferencia es borrar el campo o no tocarlo—. Elegir una y escribirla es
parte del contrato.

**05 → S12. ¿Cuál de los cuatro convierte tipos sin que se lo pidas, y qué haces al respecto?**

⏱️ YAML. Se evita entrecomillando todo lo que sea texto y validando contra un esquema.
🗣️ `NO` se vuelve falso, `022` se vuelve 18, `12:30` se vuelve 750 y `1.10` se vuelve 1.1 — verificado
en Python y en Java, y con divergencias en Go.
🔬 Los otros tres no convierten nada por su cuenta: JSON tiene tipos explícitos en la sintaxis, XML es
texto hasta que un XSD diga lo contrario, y CSV es texto siempre. El caso hermano que sí existe fuera
de YAML es el **visor** de CSV, que convierte al abrir — pero eso ocurre después del formato, no
dentro de él.

**05 → S13. ¿Cuánta memoria cuesta parsear un JSON de 100 MB a árbol? Da el orden de magnitud.**

⏱️ Del orden de 800 MB a un giga. Unas ocho veces el archivo.
🗣️ El factor viene de que cada objeto pequeño ocupa mucho más como estructura —cabecera, punteros,
cadenas— que como texto.
🔬 Medido en el capítulo `01`: 30 MB de archivo dieron 323 MB de memoria residente en la JVM con
`readTree`, frente a 99 MB con flujo y 42 MB de línea base. En Python, `json.load` del mismo archivo
dio 225 MB sobre 14 de línea base. Ese número multiplicado por las peticiones concurrentes es lo que
decide si el servicio sobrevive.

**05 → S14. ¿Qué es parsear en flujo y cuándo deja de ser opcional?**

⏱️ Procesar el documento token a token sin construirlo entero. Deja de ser opcional en cuanto el
tamaño no lo controlas tú.
🗣️ El criterio no es "cuando sea grande": es cuando no haya un límite impuesto por ti. Importaciones,
exportaciones, ficheros de terceros y endpoints sin límite de cuerpo pueden crecer sin avisar.
🔬 Y el error que anula el cambio: pasar a flujo y luego acumular los resultados en una lista. El
flujo solo sirve si procesas y descartas. Si el resultado también es grande, la salida es escribirlo
en flujo —NDJSON, CSV— en vez de materializarlo.

**05 → S15. Diferencia SAX de StAX, y di cuál usarías hoy.**

⏱️ SAX es empuje —el parser llama a tus métodos—; StAX es tirón —tú pides el siguiente evento—. Hoy,
StAX.
🗣️ Con SAX mantienes el estado a mano con banderas y pilas; con StAX escribes un bucle normal, puedes
parar y delegar una subsección a otro método.
🔬 En coste son iguales: `O(n)` en tiempo y `O(profundidad)` en memoria. La diferencia es de
mantenimiento, y por eso StAX ganó. El equivalente exacto en JSON es `JsonParser` de Jackson, que es
de tirón.

**05 → S16. ¿Por qué un servicio que va bien con 2 MB se cae con 200 MB si el parseo es `O(n)`?**

⏱️ Porque `O(n)` es el **tiempo**, y lo que revienta es la **memoria**, que también es `O(n)` pero con
una constante de ocho.
🗣️ Es el ejemplo perfecto de que la notación asintótica no dice todo: dos algoritmos `O(n)` pueden
diferir en un factor que decide si el proceso vive. Y la memoria tiene un techo duro; el tiempo, no.
🔬 Además el crecimiento no es solo del árbol: se multiplica por las peticiones concurrentes, y el
recolector de basura empieza a trabajar mucho antes del límite, con lo que el servicio se degrada
antes de caer. Por eso el síntoma suele ser latencia alta y luego muerte, no un error limpio.

**05 → S17. Tienes que sumar un campo de un archivo de 4 GB. Describe el bucle.**

⏱️ Un parser de flujo, un acumulador, y descartar cada registro tras usarlo.
🗣️ En pseudocódigo: abrir el flujo; mientras haya tokens, avanzar; cuando el nombre del campo sea el
buscado, leer el valor y sumarlo; no guardar nada más.
🔬 Tres detalles de la respuesta completa: el acumulador de un importe va en entero o decimal exacto,
no en `double`, porque millones de sumas acumulan error; la lectura va con búfer, porque sin él el
tiempo lo domina la entrada/salida; y si el archivo fuera NDJSON, el trabajo sería paralelizable por
bloques de líneas, lo que convierte una pregunta de memoria en una de reparto.

**05 → S18. Nombra un ataque propio de cada formato.**

⏱️ XML: XXE y *billion laughs*. YAML: carga insegura con etiquetas de objeto y expansión de alias.
JSON: claves duplicadas y agotamiento por anidamiento. CSV: inyección de fórmulas.
🗣️ Los cuatro tienen la misma forma: el formato permite algo más que datos, y una biblioteca lo
habilita por defecto.
🔬 Y conviene señalar el patrón, que es lo que se evalúa: **el ataque casi nunca está en la
especificación, está en la implementación**. XML es seguro en Go y vulnerable en Java; YAML es seguro
con `safe_load` e inseguro con `load`. Por eso la pregunta correcta ante un formato nuevo no es "¿es
seguro?" sino "¿qué hace por defecto la biblioteca que voy a usar?".

**05 → S19. ¿Qué hace el parser XML por defecto de Java que no hace ninguno de los otros?**

⏱️ Resolver entidades externas: lee archivos del servidor y hace peticiones de red.
🗣️ Verificado contra Python y Go con el mismo documento: los dos rechazan la entidad no definida;
Java la resuelve y devuelve el contenido del archivo.
🔬 Lo irónico es que Java **sí** protege contra la otra familia, la expansión anidada, cortando a las
64 000 entidades. Esa asimetría es lo que da sensación de seguridad y la razón de que el fallo siga
apareciendo veinte años después.

**05 → S20. ¿Qué línea blinda ese parser y por qué esa?**

⏱️ `setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)`, porque prohibir el
`DOCTYPE` cierra las dos familias a la vez.
🗣️ Las alternativas exigen varias banderas y dejar una fuera deja un hueco; una sola línea no se
olvida y se revisa de un vistazo.
🔬 Hay que ponerla en las tres fábricas —`DocumentBuilderFactory`, `SAXParserFactory` y
`XMLInputFactory`—, porque una aplicación normal usa más de una y es habitual endurecer solo la
primera. Si el dominio necesita DTD de verdad, entonces toca la lista larga, y la referencia es la
hoja de OWASP.

**05 → S21. ¿Qué diferencia hay entre `yaml.load` y `yaml.safe_load`, y qué se busca en una revisión?**

⏱️ `load` puede instanciar objetos arbitrarios del lenguaje; `safe_load` solo tipos básicos. En una
revisión se busca `yaml.load(` sin cargador seguro.
🗣️ Verificado: `safe_load` rechaza una etiqueta `!!python/object/apply:...`. En Java el equivalente es
construir `Yaml` sin `SafeConstructor`, con la diferencia de que SnakeYAML 2.x ya viene seguro.
🔬 En la revisión hay que mirar además **de dónde viene el YAML**: un `load` sobre un archivo del
propio repositorio es deuda menor; sobre algo que sube un usuario es un incidente. Y si hay carga de
YAML externo, mirar también si hay límite de tamaño, por el ataque de expansión de alias.

**05 → S22. ¿Por qué una celda de CSV que empieza por `=` es un problema y de quién es la responsabilidad?**

⏱️ Porque la hoja de cálculo la ejecuta como fórmula. La responsabilidad es de quien genera el
archivo.
🗣️ El vector no es tu aplicación sino el escritorio de quien lo abre, y por eso se escapa de las
revisiones: tu servicio no tiene ninguna vulnerabilidad, y aun así eres quien la introduce.
🔬 El argumento que hay que saber defender: el que abre el archivo no eligió el contenido, no puede
protegerse y confía en que una exportación sean datos. Tú puedes evitarlo con una línea al escribir
—apóstrofo o tipo texto forzado ante `=`, `+`, `-`, `@`—. "Es un problema de Excel" es cierto y es
irrelevante.

**05 → S23. ¿Por qué las claves duplicadas en JSON son un problema de seguridad y no solo de estilo?**

⏱️ Porque la norma no define qué valor gana, así que dos parsers de la misma cadena pueden quedarse
con valores distintos.
🗣️ Si el validador de entrada ve `{"rol":"usuario","rol":"admin"}` y se queda con el primero, y el
servicio que ejecuta se queda con el segundo, el control se ha saltado sin explotar ninguna
vulnerabilidad de código.
🔬 Es la misma familia que la desincronización de peticiones, trasladada al cuerpo del mensaje. RFC
8259 dice que las claves *SHOULD* ser únicas, que es una recomendación y no una obligación; la
defensa es un parser estricto que rechace duplicados en la frontera, y verificar que el validador y
el ejecutor usan **el mismo**.

**05 → S24. Llega un campo que tu modelo no conoce. ¿Error o se ignora?**

⏱️ Se ignora por defecto en lectura, y se rechaza en operaciones con efecto irreversible.
🗣️ Ignorar permite que el productor evolucione sin coordinar despliegues, que es la base práctica de
la compatibilidad hacia atrás. Rechazar protege contra ejecutar una orden cuyo significado no
entiendes del todo.
🔬 Y en los dos casos se **registra** lo desconocido: un campo ignorado en silencio durante meses es
un error que nadie descubre. La política completa está en `01 → 25`.

**05 → S25. ¿Qué hace Go por defecto y qué hace Jackson por defecto?**

⏱️ Go ignora el campo desconocido en silencio; Jackson lanza `UnrecognizedPropertyException`.
🗣️ Verificado con `{"a":1,"desconocido":9}`. Son las dos filosofías opuestas, y cada una se puede
invertir: `DisallowUnknownFields()` en Go, `FAIL_ON_UNKNOWN_PROPERTIES` a `false` en Jackson.
🔬 Lo interesante es el valor por defecto, porque es lo que acaba en producción cuando nadie decide.
Go optimiza para que los servicios sigan funcionando; Java, para que los errores de contrato se vean.
Ninguna es correcta siempre, y la decisión pertenece al contrato, no al lenguaje.

**05 → S26. ¿Qué es un *tolerant reader* y cuándo **no** aplicarlo?**

⏱️ Un consumidor que ignora lo que no entiende. No se aplica cuando el campo desconocido puede cambiar
el significado de una operación irreversible.
🗣️ El contraejemplo es una orden financiera con un campo nuevo `condicionEspecial` o `moneda`:
ignorarlo es ejecutar algo distinto de lo que el emisor pidió.
🔬 La formulación moderna del principio de robustez ayuda a decidir: *ignora lo que no conoces, valida
estrictamente lo que sí*. Y la tolerancia tiene un coste que rara vez se dice: propaga errores
silenciosos, porque si nadie se queja de un campo mal escrito, el fallo vive años.

**05 → S27. ¿Cómo se añade un campo obligatorio a un contrato sin romper a nadie?**

⏱️ En dos fases: primero opcional con valor por defecto, y cuando todos los productores lo envían, se
vuelve obligatorio.
🗣️ Añadirlo como obligatorio de golpe rompe a todo productor que aún no lo envía, y no se puede
desplegar a la vez a todo el mundo.
🔬 El paso que se olvida es el intermedio: **medir** qué porcentaje de mensajes ya lo traen, con una
métrica, antes de endurecer. Sin ese dato el segundo despliegue es una apuesta. Y si el campo no
puede tener valor por defecto sensato, entonces no es una evolución compatible: es una versión nueva
del contrato, y hay que decirlo así.

**05 → S28. ¿Qué protege el tipo de TypeScript en la frontera del sistema, y qué no?**

⏱️ Protege tu código contra ti mismo; no protege tus datos contra el exterior.
🗣️ `JSON.parse` devuelve `any` y un `as Pedido` es una afirmación sin comprobación: verificado que
compila con `--strict` y falla en ejecución con un `total` que es cadena.
🔬 Lo que cierra el hueco es un validador en tiempo de ejecución en el borde —Zod, io-ts, Ajv— que
además **devuelva el tipo**, de modo que el tipo estático deje de ser una promesa y pase a ser una
consecuencia. Es exactamente el mismo razonamiento que la validación con XSD en XML: se valida en la
frontera, una vez.

**05 → S29. El entrevistador afirma que `split(',')` es suficiente porque "el CSV lo generamos nosotros". ¿Qué contestas?**

⏱️ Que tiene razón mientras eso siga siendo cierto, y que la pregunta es cuánto va a durar.
🗣️ Es una respuesta correcta bajo una condición muy concreta: generas tú el archivo **y** controlas
los datos. En cuanto entra una razón social con coma, una dirección con salto de línea o un texto de
usuario, deja de serlo — y esos datos suelen entrar sin que nadie revise el importador.
🔬 El argumento que cierra la discusión sin confrontación es de coste: usar la biblioteca no es más
lento —también es una pasada `O(n)`— ni más largo de escribir, así que no hay nada que ganar
manteniendo el `split`. Cuando el beneficio de una opción es cero, el riesgo no importa cuánto sea.

**05 → S30. Te piden migrar de XML a JSON "porque XML está obsoleto". ¿Qué preguntas antes de aceptar?**

⏱️ ¿Usamos esquema, espacios de nombres, firma parcial o contenido mixto? Y ¿quién consume esto?
🗣️ Si la respuesta a la primera es "ninguno", la migración es razonable y el argumento real es
simplicidad, no obsolescencia. Si usamos alguno, hay que decir qué se pierde y cómo se sustituye.
🔬 Las tres preguntas que completan el análisis: **quién más consume el documento** —una migración que
rompe a un socio no es una migración—, **si hay obligación normativa** en el sector, y **qué pasa con
los documentos históricos**, que seguirán en XML y habrá que poder leerlos años. Y conviene desmontar
la premisa con calma: XML no está obsoleto, está especializado.

**05 → S31. ¿Cuándo es correcto escribir tu propio parser de un formato existente?**

⏱️ Casi nunca. Como ejercicio, para un subconjunto muy acotado y controlado, o cuando la
dependencia no es viable.
🗣️ Los casos legítimos existen: un entorno sin dependencias externas permitidas, un subconjunto
fijo y verificado de un formato simple, o un requisito de rendimiento medido que las bibliotecas no
cumplen — medido, no supuesto.
🔬 Y el criterio que hay que aplicar: un parser propio hay que **mantenerlo**, y los formatos tienen
casos borde que no se descubren hasta producción. Los del capítulo `04` —comillas duplicadas, saltos
dentro del campo, BOM— son exactamente los que un parser casero no contempla. Si se escribe, se
escribe con una batería de pruebas comparándolo contra la biblioteca de referencia, que es lo que
hicimos con el problema P1.

**05 → S32. El mismo YAML da resultados distintos en dos servicios y ninguno tiene un bug. Explícalo.**

⏱️ Implementan versiones distintas de la norma: 1.1 y 1.2 no coinciden en los tipos implícitos.
🗣️ Verificado: `yes` es `true` con SnakeYAML y la cadena `"yes"` con `yaml.v3`; `12:30` es `750` en el
primero y `"12:30"` en el segundo. Ninguna de las dos bibliotecas está incumpliendo nada.
🔬 La corrección es del archivo, no de las bibliotecas: entrecomillar todo lo textual, validar contra
un esquema único y, si el archivo es crítico, una prueba en la integración continua que lo cargue con
las dos y compare. El desarrollo está en `03 → 18` y en `03 → 25`.

**05 → S33. ¿Por qué los formatos binarios con esquema no han sustituido a JSON, si son mejores en casi todo?**

⏱️ Porque JSON se lee sin herramientas y no requiere coordinación previa, y eso vale más que el
rendimiento en la mayoría de los casos.
🗣️ Protobuf, Avro o Thrift ganan en tamaño, velocidad, tipado y evolución controlada. Pierden en lo
que decide la adopción: para consumir JSON no necesitas el esquema, ni generar código, ni una versión
compatible de una biblioteca, ni una herramienta para mirar qué llegó por el cable.
🔬 Y hay un factor organizativo que pesa más que el técnico: un formato con esquema exige un flujo de
trabajo —repositorio de esquemas, generación de código, política de compatibilidad, registro— que una
organización tiene que sostener. Donde ese flujo existe y el volumen lo justifica —comunicación
interna entre servicios, gRPC— los binarios sí han ganado. Hacia fuera, donde el consumidor es
desconocido, casi nunca. La respuesta completa dice **dónde sí han ganado**, porque negarlo sería
falso.

**05 → S34. Si tuvieras que enseñar este bloque entero en cinco minutos, ¿qué dirías y qué dejarías fuera?**

⏱️ Diría tres cosas: elige por lo que el formato representa, no por costumbre; el coste real es la
memoria al parsear; y el comportamiento lo decide la biblioteca, no el formato.
🗣️ Las tres con su ejemplo: el identificador que se corrompe en JavaScript, el árbol que multiplica
por ocho, y el mismo YAML que da tipos distintos en Java y en Go. Con esos tres ejemplos se sostiene
todo lo demás.
🔬 Dejaría fuera la sintaxis —se consulta—, la lista de bibliotecas por lenguaje, y los detalles de
cada ataque, que se resumen en una regla: *lo que viene de fuera se carga con la función segura y con
un límite de tamaño*. Lo que **no** dejaría fuera aunque apretara el tiempo es la distinción entre lo
que obliga el formato y lo que hace tu biblioteca, porque es lo que evita atribuir al formato un
problema que tienes tú.

---

# 05 — Simulación: problemas de pizarra

**05 → P1. El parser de CSV.**

⏱️ Es una máquina de estados de dos estados —dentro o fuera de comillas—, una pasada, `O(n)` en tiempo
y `O(1)` en memoria por campo.
🗣️ **La fuerza bruta que no funciona** es `split(',')`, y hay que decir por qué antes de escribir:
falla con la coma dentro del campo, con las comillas duplicadas y con el salto de línea interno. No
es cuestión de parchear el `split`: el problema es que el significado de una coma **depende del
estado**, y eso ya es una máquina de estados.
🔬 La solución, ejecutada y comparada contra `csv.reader`:

```python
def leer_csv(texto, sep=","):
    registros, campos, campo = [], [], []
    dentro = False                      # ¿dentro de un campo entrecomillado?
    i = 0
    while i < len(texto):
        c = texto[i]
        if dentro:
            if c == '"':
                if i + 1 < len(texto) and texto[i + 1] == '"':
                    campo.append('"'); i += 1    # comilla escapada
                else:
                    dentro = False               # comilla de cierre
            else:
                campo.append(c)
        else:
            if c == '"':      dentro = True
            elif c == sep:    campos.append("".join(campo)); campo = []
            elif c == "\r":   pass
            elif c == "\n":
                campos.append("".join(campo)); campo = []
                registros.append(campos); campos = []
            else:             campo.append(c)
        i += 1
    if campo or campos:                  # último registro sin salto final
        campos.append("".join(campo)); registros.append(campos)
    return registros
```

Con la línea del capítulo devuelve 4 campos, `'Muebles "El Roble", S.A.'` incluido, y **coincide
exactamente con `csv.reader`**. Casos borde que hay que nombrar en voz alta: archivo vacío; último
registro sin salto final —lo cubre el `if` final—; campo vacío entre delimitadores; comilla al
principio de un campo no entrecomillado, que es entrada malformada y hay que decidir si se rechaza o
se acepta como literal; y el BOM, que si no se quita se pega al primer campo. La acumulación en lista
y `join` en vez de concatenar cadenas es deliberada: concatenar en un bucle es cuadrático, por
`02-texto/01`.

**05 → P2. Aplanar JSON a tabla.**

⏱️ Recorrido recursivo que compone las claves con un separador, más una decisión declarada para
arrays y para campos ausentes.
🗣️ **No hay respuesta correcta única, y lo que se evalúa es declarar el criterio antes de teclear.**
Las tres decisiones y las opciones reales de cada una:

```text
ANIDAMIENTO  {"cliente":{"id":7}}  →  columna "cliente.id"          (aplanar con separador)
ARRAYS       tres opciones: una fila por elemento (explotar) ·
             columnas indexadas lineas.0.sku · o JSON serializado en una celda
AUSENTES     unión de todas las claves como cabecera, y vacío donde no haya
```
🔬 La implementación es un recorrido con acumulador de prefijo; el coste es `O(n)` sobre los nodos del
documento y la memoria es la de la tabla resultante. Tres casos borde que hay que mencionar: una
**colisión de nombres** si un campo ya se llama `cliente.id`, que obliga a elegir un separador
improbable o a escapar; **arrays de longitud variable**, que con la opción de columnas indexadas
producen una cabecera distinta por archivo y rompen el consumidor; y **el orden de las columnas**, que
tiene que ser determinista o el diff entre dos ejecuciones es ruido. La respuesta senior termina
preguntando lo que debería ser la primera pregunta: *¿quién consume la tabla?* — porque si es una
hoja de cálculo, explotar los arrays es lo correcto, y si es una carga a base de datos, casi nunca.

**05 → P3. Streaming de XML a NDJSON.**

⏱️ StAX de entrada, escritor con búfer de salida, una pasada, memoria constante e independiente de los
2 GB.
🗣️ **Cualquier solución que construya el árbol está mal**, y hay que decirlo antes de escribir: 2 GB
de XML con DOM son más de 16 GB de objetos, y la máquina tiene 512 MB. El bucle: avanzar hasta el
siguiente `<pedido>`; extraer los tres campos a variables locales; escribir una línea JSON; descartar.
🔬 Las cuatro decisiones que hacen buena la respuesta. **(1) NDJSON y no un array JSON**: un objeto por
línea se procesa línea a línea, se trocea y se paraleliza; un array de 2 GB obliga al consumidor al
mismo problema que acabas de resolver. **(2) Búfer de salida** vaciado cada N registros: sin él, el
tiempo lo domina la entrada/salida y no el parseo. **(3) Coste:** `O(n)` en tiempo, `O(1)` en memoria
—decenas de megas de búferes—. **(4) Qué hacer con un registro corrupto en la posición 4 000 001**:
abortar, saltar y contar, o escribir a un archivo de rechazos; hay que elegir y decirlo, porque
procesar 2 GB y morir al final sin haber escrito nada es el peor resultado posible. Si además hay
XSD, se valida en flujo encadenando el validador al lector, no sobre el árbol.

**05 → P4. El diagnóstico del archivo desconocido.**

⏱️ Cuatro comprobaciones en orden —codificación, fin de línea, delimitador, cabecera— y una lista
explícita de lo que no se puede determinar sin preguntar.
🗣️ El procedimiento:

```text
1. CODIFICACIÓN  ¿hay BOM? Si no, intentar UTF-8 estricto: si falla, es otra cosa (Latin-1 no falla nunca)
2. FIN DE LÍNEA  contar \r\n frente a \n solos
3. DELIMITADOR   contar candidatos , ; \t | por línea y quedarse con el de recuento MÁS ESTABLE
4. CABECERA      ¿la primera fila tiene tipos distintos del resto? Entonces probablemente es cabecera
```
🔬 **La parte más valiosa es la lista de lo que no se puede saber**, y es lo que se evalúa: si el vacío
significa nulo o cadena vacía; si los ceros a la izquierda son significativos; qué zona horaria tienen
las fechas; si el archivo está completo o truncado; y si un campo numérico con puntos es un decimal o
un separador de miles. Ninguna heurística resuelve eso: se pregunta. Sobre el punto 1, el detalle
técnico que conviene decir es que **UTF-8 es autoverificable** —una secuencia inválida se detecta— y
Latin-1 no lo es, porque acepta cualquier octeto; por eso el orden correcto es intentar UTF-8 primero
y caer a Latin-1, nunca al revés. Y el punto 3 con `Sniffer` de Python es una línea, pero falla con
archivos de una sola columna, que conviene nombrar.

**05 → P5. Diferencia mínima entre dos JSON.**

⏱️ Recorrido recursivo paralelo sobre los dos documentos, acumulando altas, bajas y cambios con su
ruta. `O(n)` sobre el total de nodos.
🗣️ **La decisión de diseño está en los arrays**, y hay que plantearla antes de teclear: comparar por
**posición** es simple y produce diferencias enormes si alguien inserta un elemento al principio;
comparar por **identidad** —una clave del elemento— da diferencias mínimas pero exige saber cuál es la
clave, que es información del dominio. La solución de referencia usa posición y **lo declara**.
🔬 La implementación, ejecutada:

```python
def diff(a, b, ruta=""):
    cambios = []
    if type(a) is not type(b):
        return [("cambia", ruta, a, b)]
    if isinstance(a, dict):
        for k in a.keys() - b.keys(): cambios.append(("baja", f"{ruta}/{k}", a[k], None))
        for k in b.keys() - a.keys(): cambios.append(("alta", f"{ruta}/{k}", None, b[k]))
        for k in a.keys() & b.keys(): cambios += diff(a[k], b[k], f"{ruta}/{k}")
    elif isinstance(a, list):
        for i in range(min(len(a), len(b))): cambios += diff(a[i], b[i], f"{ruta}/{i}")
        for i in range(len(b), len(a)):      cambios.append(("baja", f"{ruta}/{i}", a[i], None))
        for i in range(len(a), len(b)):      cambios.append(("alta", f"{ruta}/{i}", None, b[i]))
    elif a != b:
        cambios.append(("cambia", ruta, a, b))
    return cambios
```

Sobre dos pedidos reales devuelve exactamente cuatro cambios: alta de `/envio`, baja de `/nota` y
cambios en `/total` y `/lineas/0/n`. Casos borde: **cambio de tipo** —de número a cadena— que se trata
como un cambio y no como baja más alta; **`null` frente a clave ausente**, que son cosas distintas y
el código de arriba las distingue porque `null` sí está en las claves; **profundidad**, que con
documentos muy anidados puede agotar la pila y obliga a pasar a un recorrido con pila explícita; y la
**ruta**, que conviene emitir en formato JSON Pointer (RFC 6901) para que el resultado sea consumible
por otras herramientas — y de ahí a emitir un JSON Patch (RFC 6902) hay un paso.

**05 → P6. Las configuraciones casi iguales.**

⏱️ Doble bucle sobre las 780 parejas. Es la respuesta correcta, y decirlo en voz alta vale más que
cualquier optimización.
🗣️ **La trampa es optimizar.** Con n = 40, el número de parejas es 40 × 39 / 2 = **780**, y comparar
dos mapas de treinta claves son treinta comparaciones: unas 23 000 operaciones en total. Proponer un
índice invertido, *hashing* por similitud o MinHash aquí es sobreingeniería: más código, más
superficie de error y ninguna ganancia medible.
🔬 Ejecutado sobre 40 configuraciones de 30 claves: **780 comparaciones en 2,0 ms**. La solución
completa:

```python
for (na, a), (nb, b) in itertools.combinations(configs, 2):
    distintas = sum(1 for k in a.keys() | b.keys() if a.get(k) != b.get(k))
    if distintas < 3:
        parejas.append((na, nb, distintas))
```

Y lo que hay que añadir para que la respuesta sea senior y no perezosa: **decir a partir de qué n
cambiaría la respuesta**. El coste es `O(n² · k)`; con 40 archivos es instantáneo, con 1 000 son
medio millón de parejas y sigue siendo viable, y a partir de unas decenas de miles conviene un índice
por clave-valor para descartar parejas sin compararlas. Dar ese umbral demuestra que la elección fue
deliberada. Casos borde: claves presentes en uno y ausentes en otro —de ahí la unión de claves y el
`get`—, valores anidados, que exigen comparación profunda, y el orden de las listas dentro de un
valor, que puede dar falsos positivos si el YAML no garantiza orden.

---

**Anterior:** [`05` — Simulación de entrevista](05-simulacion-de-entrevista.md) ·
**Bloque:** [README](README.md)
