# 02 — XML y los esquemas

> El formato que sigue moviendo la banca y los seguros, y el único del temario con **contrato
> validable de serie**. Qué trae que JSON no tiene, los tres modos de parsearlo y lo que cuesta cada
> uno, y la familia de ataques que hace que el parser por defecto de Java lea archivos de tu
> servidor.
>
> **Asume leído:** [`01` — JSON](01-json.md), del que hereda el vocabulario de árbol frente a flujo.
>
> **Vigencia:** 2026-09-18. Todas las salidas de este capítulo están **ejecutadas**.

---

## 1. 🎯 El problema

Un servicio recibe pedidos en XML de un socio. El código es de manual:

```java
var doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(entrada);
```

El socio —o quien le haya suplantado— envía esto:

```xml
<?xml version="1.0"?>
<!DOCTYPE pedido [ <!ENTITY xxe SYSTEM "file:secreto.txt"> ]>
<pedido><cliente>&xxe;</cliente></pedido>
```

Y el campo `cliente` llega al sistema con el contenido del archivo:

```text
por defecto -> leyó: SECRETO-DEL-SERVIDOR
blindado    -> rechazado: SAXParseException — DOCTYPE is disallowed when the feature
               "http://apache.org/xml/features/disallow-doctype-decl" set to true
```

Eso es **XXE** (*XML External Entity*), y la línea que lo cierra es una sola. Lo que hay que retener
no es el ataque: es que **el parser de la biblioteca estándar de Java viene abierto por defecto**, y
que de los cinco lenguajes del corpus es el único que lo hace.

---

## 2. 🧱 Qué trae XML que JSON no tiene

**Qué es.** Un formato de marcado con etiquetas anidadas, mucho más viejo y mucho más expresivo que
JSON. Lo que aporta de más es lo que explica por qué sigue vivo donde sigue vivo:

| XML tiene | JSON no tiene | Para qué sirve de verdad |
|---|---|---|
| **Atributos** además de elementos | Solo pares clave-valor | Separar metadatos del contenido |
| **Espacios de nombres** | Nada | Mezclar vocabularios de dos organizaciones sin colisión |
| **Esquema** (XSD) de serie | JSON Schema, que es posterior y externo | Validar el documento **antes** de tocarlo |
| **Comentarios** | Nada | Archivos escritos y revisados por personas |
| **Orden significativo** y contenido mixto | Arrays, y nada más | Documentos: un párrafo con negritas dentro |
| **XPath** | Nada estándar | Consultar sin deserializar |
| **Firma y cifrado parcial** | Nada estándar | Firmar *una parte* del documento |

- **Atributo o elemento** es la discusión eterna, y la regla que funciona: si es un dato del dominio,
  elemento; si describe cómo leer el dato —un identificador, una unidad, un idioma—, atributo. No hay
  respuesta normativa, y decirlo así es mejor que defender un bando.
- **El contenido mixto es lo que JSON no puede representar** sin inventarse una convención: en
  `<p>hola <b>mundo</b></p>` el texto y los elementos se alternan, y el orden importa. XML nació para
  documentos y luego se usó para datos; JSON nació para datos.
- **Los espacios de nombres son la razón** de que SOAP, XBRL, ISO 20022 y los formatos bancarios
  vivan en XML: dos organizaciones pueden definir `<cuenta>` sin pisarse.

**Cuánto cuesta.** Entre dos y cinco veces el tamaño de un JSON equivalente, por las etiquetas de
cierre. Comprimido, la diferencia casi desaparece — el coste real de XML no son los bytes, es la
complejidad del parser y de la superficie de ataque.

**Cuándo sí.** Cuando hay un esquema que manda —banca, seguros, facturación electrónica,
administración pública—, cuando hay que firmar una parte del documento, y cuando el documento *es*
un documento.

**Cuándo no.** Una API interna nueva. Ahí XML es ceremonia: pagas la complejidad y no usas ni los
espacios de nombres, ni el esquema, ni la firma.

> **Veredicto:** XML no está obsoleto, está **especializado**. Si tu dominio te da un XSD, XML es la
> respuesta correcta; si lo estás eligiendo tú para una API nueva, casi nunca lo es.

---

## 3. 🧱 Los tres modos de parsear

**Qué es.** XML tiene los dos modos de JSON —árbol y flujo— y el flujo se divide en dos filosofías:

```text
DOM    árbol completo en memoria, navegable en los dos sentidos
SAX    flujo de EMPUJE: el parser llama a tus métodos; tú no controlas el ritmo
StAX   flujo de TIRÓN: tú pides el siguiente evento cuando quieres
```

**Cómo va.** La diferencia entre empuje y tirón parece menor y no lo es:

- **SAX te obliga a mantener el estado a mano** —"estoy dentro de `<pedido>`, y ahora dentro de
  `<total>`"— con banderas y pilas. Es rápido, es viejo y es incómodo.
- **StAX te devuelve el control**: un bucle `while (lector.hasNext())` que puede parar, saltar o
  delegar una subsección a otro método. Es el modo que se usa hoy cuando el documento es grande.

**Cuánto.** El mismo reparto que en JSON, y por el mismo motivo: **el árbol cuesta del orden de ocho
veces el tamaño del archivo**; el flujo, lo que tú decidas guardar. Con XML la diferencia es mayor,
porque un nodo DOM arrastra más metadatos que un nodo JSON.

**Cuándo sí** DOM: documentos pequeños, y sobre todo cuando vas a usar XPath, que necesita el árbol.

**Cuándo no:** ficheros de intercambio. Un fichero bancario diario de medio giga con DOM no se parsea:
se cae.

> **Veredicto:** StAX para lo grande, DOM para lo pequeño, SAX solo si mantienes código que ya lo
> usa. Y la frase que resume el criterio: **el árbol se paga entero por adelantado**, aunque solo
> quieras un campo.

---

## 4. 🧱 XPath y XSD: consultar y validar

**XPath** es un lenguaje de consulta sobre el árbol, y es lo que hace que no tengas que recorrerlo a
mano:

```text
/pedido/lineas/linea[@id='3']/total        el total de la línea con id 3
//cliente[contains(@nombre,'Roble')]       en cualquier profundidad
count(//linea)                             agregados, sin deserializar nada
```

- Está en la biblioteca estándar de Java y de Python. **No tiene equivalente en JSON estándar**: lo
  más parecido es JSONPath, que es una convención sin norma y con dialectos incompatibles.
- **Cuesta lo que cuesta el árbol**, porque lo necesita. Una expresión con `//` recorre todo el
  documento: es `O(n)` por consulta, no `O(1)`.

**XSD** es el esquema: un documento XML que describe qué documentos son válidos —qué elementos, en
qué orden, con qué tipos, cuántas veces—.

- **Lo que compra es rechazar antes de procesar.** Un mensaje que no cumple el esquema no llega a tu
  lógica de negocio, y el error que devuelves señala la línea y el elemento exactos.
- Es la diferencia práctica con JSON: en XML el contrato es un artefacto que el socio te entrega y
  que tu parser aplica solo; en JSON hay que añadir JSON Schema y un validador, y decidir quién lo
  mantiene.
- **Cuesta tiempo de proceso**: validar recorre el documento otra vez, y con esquemas grandes puede
  costar más que parsear. Por eso se valida en el borde y una sola vez.

> **Veredicto:** si el dominio te da XSD, valida siempre y en la frontera. Un esquema que existe y no
> se aplica es documentación, no contrato.

---

## 5. ⚠️ Entidades: XXE y la bomba

**Qué es.** El `<!DOCTYPE>` permite declarar **entidades**, que son sustituciones de texto. De ahí
salen dos ataques distintos que conviene no confundir:

```text
XXE               una entidad EXTERNA lee un archivo o hace una petición de red desde tu servidor
Billion laughs    entidades INTERNAS anidadas que se expanden exponencialmente hasta agotar memoria
```

**Cómo va, medido en los tres lenguajes que traen parser:**

| | Entidad externa (XXE) | Entidades anidadas |
|---|---|---|
| **Java** (JDK 17 y 21, DOM por defecto) | ❌ **la resuelve y lee el archivo** | ✅ corta a las 64 000 expansiones |
| **Python** (`ElementTree`) | ✅ la rechaza: *undefined entity* | ❌ expandió 300 000 caracteres sin quejarse |
| **Go** (`encoding/xml`) | ✅ rechaza toda entidad no estándar | ✅ lo mismo |

- El mensaje exacto del corte de Java es citable: `JAXP00010001: The parser has encountered more than
  "64000" entity expansions in this document; this is the limit imposed by the JDK`.
- **Ninguno de los tres está protegido en las dos columnas**, y ese es el punto: la protección
  depende de la biblioteca, no del formato.
- En Python la recomendación oficial es usar **`defusedxml`** cuando el XML venga de fuera; en Java,
  endurecer la fábrica; en Go no hace falta, porque nunca lo soportó.

**El blindaje en Java, que es la línea que hay que saber de memoria:**

```java
var f = DocumentBuilderFactory.newInstance();
// Prohibir el DOCTYPE entero cierra las dos familias de golpe
f.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
```

- **Prohibir el DOCTYPE es mejor que desactivar entidades una a una**: es una sola bandera y no deja
  huecos. Solo estorba si tu dominio usa DTD de verdad, que hoy es raro.
- La misma bandera existe en `SAXParserFactory` y en `XMLInputFactory` (StAX). **Hay que ponerla en
  las tres**, porque una aplicación suele usar más de una.

> **Veredicto:** todo parser XML que reciba datos de fuera se endurece en la línea siguiente a
> crearlo. No es una buena práctica opcional: es la diferencia entre un parser y una puerta.

---

## 6. 🧱 El mapa por lenguaje

| Lenguaje | Qué trae de serie | La sorpresa |
|---|---|---|
| **Java** | DOM, SAX, StAX, XPath y validación XSD, todo en el JDK | **JAXB ya no está**: salió del JDK en Java 11 y hoy es una dependencia |
| **Python** | `xml.etree.ElementTree`, `xml.dom`, `xml.sax` | Ligero y cómodo; para datos externos, `defusedxml` |
| **Go** | `encoding/xml` con etiquetas de `struct` | **Sin XPath y con soporte pobre de espacios de nombres** |
| **JavaScript** | **Nada** en Node: `DOMParser` es del navegador | Verificado: `typeof DOMParser` → `undefined` |
| **TypeScript** | Lo de JavaScript, con los tipos de la biblioteca que elijas | El mapeo XML → tipo es siempre manual |

- **Lo de JAXB es la pregunta trampa de Java**: mucha gente responde "uso JAXB, viene en el JDK". Sale
  `ClassNotFoundException` desde Java 11, y hay que añadir `jakarta.xml.bind` — con el cambio de
  paquete de `javax` a `jakarta` de por medio, que es su propia migración.
- **Que Node no traiga parser XML dice mucho del reparto real**: el ecosistema que nació con la web
  no necesita XML, y el que vive en la empresa no puede prescindir de él.

---

## 7. ⏱️ La tabla de costes

| Operación | Tiempo | Memoria | Lo que la tabla no dice |
|---|---|---|---|
| DOM | `O(n)` | **≈ 8 × el archivo, o más** | Es lo único sobre lo que corre XPath |
| SAX / StAX | `O(n)` | `O(profundidad)` | StAX se lee; SAX hay que mantenerlo |
| XPath con `//` | `O(n)` por consulta | la del DOM | Diez consultas son diez recorridos |
| Validar con XSD | `O(n)` × reglas | `O(n)` | Puede costar más que parsear |
| XML frente a JSON en bytes | — | 2–5 × | Comprimido, la diferencia casi desaparece |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "XML está muerto" | Mueve banca, seguros y facturación electrónica. Está especializado |
| "Uso JAXB, viene en el JDK" | Salió en Java 11. Hoy es dependencia, y con `jakarta` en vez de `javax` |
| "El parser por defecto es seguro" | El de Java resuelve entidades externas: es XXE de manual |
| "Prohibir entidades externas basta" | Faltan las internas anidadas. Prohibir el DOCTYPE cierra las dos |
| "SAX y StAX son lo mismo" | Empuje frente a tirón: quién controla el ritmo del bucle |
| "XPath es gratis" | Necesita el árbol entero, y cada `//` es un recorrido completo |
| "Los atributos son para lo pequeño" | El criterio es dato del dominio frente a metadato, no tamaño |
| "Go maneja XML como Java" | No tiene XPath y trata los espacios de nombres a medias |

---

## 📚 Para profundizar

- **Norma** — [W3C — *Extensible Markup Language (XML) 1.0*](https://www.w3.org/TR/xml/): la
  especificación. La sección 4 es la de las entidades, que es la que importa para la seguridad.
- **Norma** — [W3C — *XML Schema Part 0: Primer*](https://www.w3.org/TR/xmlschema-0/): la
  introducción a XSD, que se lee sin ser especialista.
- **Seguridad** — [OWASP — *XML External Entity Prevention Cheat Sheet*](https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html):
  el blindaje exacto para cada lenguaje y cada fábrica. Es la referencia que se cita en una revisión.
- **Java** — [Oracle — *Java API for XML Processing (JAXP)*](https://docs.oracle.com/javase/tutorial/jaxp/index.html):
  DOM, SAX, StAX y XPath, con ejemplos.
- **Python** — [`xml.etree.ElementTree`](https://docs.python.org/3/library/xml.etree.elementtree.html)
  y la [advertencia de seguridad del módulo `xml`](https://docs.python.org/3/library/xml.html#xml-vulnerabilities),
  que trae una tabla de qué ataque afecta a qué parser.
- **Go** — [`encoding/xml`](https://pkg.go.dev/encoding/xml): las etiquetas de `struct` y sus
  limitaciones con espacios de nombres, dichas por la propia documentación.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`06` — Respuestas](06-respuestas.md).

1. ¿Qué es un espacio de nombres en XML y para qué sirve? 🟢
2. ¿Qué es XPath? 🟢
3. ¿Qué es un XSD? 🟢
4. ¿Cuáles son los tres modos de parsear XML? 🟢
5. ¿Qué es XXE? 🟢
6. ¿Trae Node un parser de XML? 🟢
7. ¿Está JAXB en el JDK? 🟢
8. ¿Cuánto ocupa un XML frente a un JSON equivalente? 🟢
9. ¿Qué diferencia hay entre SAX y StAX? 🟡
10. ¿Cuándo pones un dato en un atributo y cuándo en un elemento? 🟡
11. ¿Qué puede representar XML que JSON no puede? 🟡
12. Diferencia XXE de *billion laughs*. 🟡
13. ¿Qué hace el parser de Java por defecto ante una entidad externa? ¿Y ante una anidada? 🟡
14. ¿Y el de Python? ¿Y el de Go? 🟡
15. ¿Qué línea blinda el parser de Java y por qué esa y no otra? 🟡
16. ¿Por qué XPath no tiene equivalente estándar en JSON? 🟡
17. ¿Qué se pierde al usar `encoding/xml` de Go frente a Java? 🟡
18. ¿Por qué XML sigue vivo en banca y seguros? 🟠
19. ¿Cuándo dirías que XML es la elección incorrecta? 🟠
20. Un fichero de intercambio de 500 MB tumba el servicio al parsearlo. Diagnostica y corrige. 🟠
21. ¿Por qué validar con XSD en el borde y no dentro de la lógica? 🟠
22. ¿Por qué prohibir el DOCTYPE es mejor blindaje que desactivar entidades externas? 🟠
23. Un socio te manda XML firmado y solo una parte del documento va firmada. ¿Qué implica eso al
    procesarlo? 🟠
24. ¿Por qué un XSD se valida una sola vez y no en cada capa? 🟠
25. Te dan un XML sin XSD de un socio nuevo. ¿Qué haces antes de escribir el primer mapeo? 🟠
26. ¿Cuándo preferirías StAX sobre DOM aunque el documento sea pequeño? 🟠
27. Tienes que exponer el mismo recurso en XML y en JSON. Escribe qué decides para atributos,
    espacios de nombres, fechas y nulos, y qué se pierde en cada dirección. 🔴
28. Escribe la revisión de seguridad de un servicio que recibe XML de terceros: qué miras, en
    qué orden y con qué prueba lo confirmas. 🔴
29. Un XML de 2 GB tiene que convertirse a JSON conservando solo tres campos por registro.
    Diseña el procesamiento y di su coste en memoria. 🔴
30. Un servicio Java lleva años parseando XML de terceros sin endurecer el parser y no ha pasado
    nada. Escribe el argumento para priorizar el arreglo. 🔴
31. Migras un servicio de XML a JSON manteniendo el XML durante un año. Diseña la convivencia:
    modelo, validación, versiones y qué haces con los documentos históricos. 🔴

---

**Anterior:** [`01` — JSON](01-json.md) · **Siguiente:** [`03` — YAML](03-yaml.md) ·
**Bloque:** [README](README.md)
