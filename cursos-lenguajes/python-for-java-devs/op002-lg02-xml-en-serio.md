# 🧾 lg02 — XML en serio

> Python para desarrolladores Java senior · **Carta** · Track `lg` — Legado e intercambio
> sectorial · sección 2 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta. Conviene haber leído la
> [Fase 06](06-formatos-en-la-caja.md), que usa `xml.etree.ElementTree` y deja fuera el XML de la
> DIAN con su razón escrita.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor —el resumen y la bomba—; la validación con XSD, el 07/10/2026, con los dos esquemas
> importados escritos aparte (son el ejercicio 4 y no se publican).

---

## 🎯 1. Qué problema resuelve

La factura electrónica colombiana es un documento **UBL 2.1** con extensiones de la DIAN: un XML
con media docena de espacios de nombres, campos que solo existen en ciertos tipos de documento y
un esquema XSD que el validador del Estado aplica sin piedad. Áurea emite una por cada atención
facturada, y la respuesta de la DIAN —el *application response*— vuelve también en XML.

Con `ElementTree` de la biblioteca estándar se puede **leer** ese XML, y la Fase 06 lo hace para
lo simple. Lo que no da es lo que este trabajo necesita de verdad:

- **XPath completo**, con predicados y funciones, para preguntar *"el total de la línea 3"* sin
  recorrer el árbol a mano.
- **Validación contra XSD** antes de mandar nada, para que el lote no rebote con un mensaje que no
  dice cuál fila falló.
- **XSLT**, para convertir la factura en la representación gráfica que se le entrega al paciente.
- **Control explícito del parser**, porque un XML que llega de afuera puede ser un ataque.

Para eso está `lxml` (6.1.3, publicada el 2026-09-02): un enlace a `libxml2` y `libxslt`, las
dos bibliotecas en C que usa medio mundo para XML.

---

## 🧠 2. El modelo

`lxml` expone la misma API de `ElementTree` —`Element`, `SubElement`, `find`, `iter`— y le agrega
lo que `ElementTree` no tiene. El cambio de biblioteca es casi un cambio de `import`. Lo que sí
cambia la forma de trabajar son tres ideas.

**Los espacios de nombres no son decoración.** En `<cbc:ID>`, el prefijo `cbc` no significa nada
por sí mismo: es un alias local para la URI
`urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2`. Dos documentos pueden
usar prefijos distintos para la misma URI y ser el mismo XML. Por eso las consultas se escriben
con **tu** mapa de prefijos, no con los del documento.

**El esquema es un contrato ejecutable.** Un XSD dice qué elementos existen, en qué orden, con qué
tipos y cardinalidades. `lxml` lo compila una vez y valida documentos contra él en milisegundos,
con errores que traen línea y ruta del elemento.

**El parser es una superficie de ataque.** XML permite declarar **entidades** —macros que se
expanden al leer— y entidades **externas** que apuntan a un archivo o a una URL. Un documento
hostil puede pedirle a tu parser que lea `/etc/passwd` y lo meta en un campo (XXE), o que expanda
una entidad que contiene diez copias de otra que contiene diez copias de otra, hasta agotar la
memoria (la *bomba de entidades*, o *billion laughs*).

### Tu instinto de Java dice… y esta vez se equivoca

En Java el reflejo es JAXB: generar clases desde el XSD con `xjc` y deserializar. En Python ese
camino existe (`xsdata` genera dataclasses desde un XSD), pero para un documento que **solo
lees en partes** —el CUFE, el total, la respuesta de la DIAN— generar trescientas clases es
desproporcionado. **XPath sobre el árbol** es la herramienta: cinco consultas con nombre
reemplazan el modelo de objetos entero, y no se rompen cuando la DIAN agrega un elemento opcional.

### Diccionario de traducción

| Java | Python con `lxml` | Dónde se rompe el paralelo |
|---|---|---|
| `DocumentBuilderFactory` + `setFeature(...)` para desactivar entidades | `etree.XMLParser(resolve_entities=False, no_network=True)` | En Java las protecciones se activan una por una; en `lxml` se declaran al construir el parser |
| `XPathFactory` + `NamespaceContext` | `tree.xpath(expr, namespaces=NS)` | El mapa de prefijos es un `dict`, no una clase que implementas |
| `SchemaFactory` + `Validator` | `etree.XMLSchema(etree.parse(xsd))` | Igual; `lxml` devuelve un `error_log` iterable con línea y ruta |
| `TransformerFactory` (XSLT) | `etree.XSLT(etree.parse(xsl))` | Igual de capaz; `lxml` implementa XSLT 1.0, no 2.0 ni 3.0 |
| JAXB con `xjc` | `xsdata` | Útil para escribir documentos completos; caro para leer tres campos |

---

## 💻 3. El ejemplo que corre

```bash
uv add lxml
```

El ejemplo trabaja sobre una factura UBL recortada a lo esencial —la de verdad tiene unas
doscientas líneas— y un XSD mínimo escrito para la sección, que exige lo que a Áurea le rebota con
más frecuencia: NIT con dígito de verificación, fecha ISO y al menos una línea.

`factura.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
         xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
  <cbc:ID>FE-000123</cbc:ID>
  <cbc:IssueDate>2026-09-28</cbc:IssueDate>
  <cac:AccountingSupplierParty>
    <cac:Party><cac:PartyTaxScheme><cbc:CompanyID schemeID="8">900123456</cbc:CompanyID>
    </cac:PartyTaxScheme></cac:Party>
  </cac:AccountingSupplierParty>
  <cac:InvoiceLine>
    <cbc:ID>1</cbc:ID>
    <cbc:LineExtensionAmount currencyID="COP">185000.00</cbc:LineExtensionAmount>
  </cac:InvoiceLine>
  <cac:InvoiceLine>
    <cbc:ID>2</cbc:ID>
    <cbc:LineExtensionAmount currencyID="COP">95000.00</cbc:LineExtensionAmount>
  </cac:InvoiceLine>
</Invoice>
```

`factura_xml.py`:

```python
"""Lee, valida y transforma la factura UBL con lxml, con un parser que no confía en nadie."""

from decimal import Decimal
from pathlib import Path

from lxml import etree

# Nuestro mapa de prefijos: las consultas no dependen de los prefijos que traiga el documento.
NS = {
    "inv": "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
    "cac": "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
    "cbc": "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
}

# Un parser para XML que llega de afuera: sin entidades, sin red, sin árboles gigantes.
SAFE_PARSER = etree.XMLParser(
    resolve_entities=False,
    no_network=True,
    huge_tree=False,
    remove_blank_text=True,
)

# Las consultas tienen nombre: el código que las usa no sabe nada de XPath.
INVOICE_ID = etree.XPath("string(/inv:Invoice/cbc:ID)", namespaces=NS)
SUPPLIER_NIT = etree.XPath("string(//cac:AccountingSupplierParty//cbc:CompanyID)", namespaces=NS)
LINE_AMOUNTS = etree.XPath("//cac:InvoiceLine/cbc:LineExtensionAmount/text()", namespaces=NS)
LINE_BY_ID = etree.XPath("//cac:InvoiceLine[cbc:ID=$line]/cbc:LineExtensionAmount/text()",
                         namespaces=NS)


def load(path: Path) -> etree._ElementTree:
    return etree.parse(str(path), SAFE_PARSER)


def check_digit(nit: str) -> int:
    """Dígito de verificación del NIT colombiano: pesos primos, módulo 11."""
    weights = (3, 7, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71)
    total = sum(int(d) * w for d, w in zip(reversed(nit), weights))
    rest = total % 11
    return rest if rest in (0, 1) else 11 - rest


def validate(tree: etree._ElementTree, schema_path: Path) -> list[str]:
    schema = etree.XMLSchema(etree.parse(str(schema_path), SAFE_PARSER))
    if schema.validate(tree):
        return []
    # Cada error trae línea y ruta: es lo que hace falta para decirle a Patricia qué corregir.
    return [f"línea {e.line}: {e.path}: {e.message}" for e in schema.error_log]


def summarize(tree: etree._ElementTree) -> dict[str, object]:
    amounts = [Decimal(a) for a in LINE_AMOUNTS(tree)]
    nit_element = tree.find(".//cac:AccountingSupplierParty//cbc:CompanyID", NS)
    declared_dv = int(nit_element.get("schemeID"))
    nit = SUPPLIER_NIT(tree)
    return {
        "invoice": INVOICE_ID(tree),
        "nit": nit,
        "nit_ok": check_digit(nit) == declared_dv,
        "lines": len(amounts),
        "total": sum(amounts, Decimal(0)),
        "line_2": LINE_BY_ID(tree, line="2"),
    }


if __name__ == "__main__":
    tree = load(Path("factura.xml"))
    print(summarize(tree))
    print(validate(tree, Path("factura-minima.xsd")) or "válida")
```

`factura-minima.xsd`, el contrato mínimo:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
           xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
           xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
           targetNamespace="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
           elementFormDefault="qualified">
  <xs:import namespace="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
             schemaLocation="cbc-minimo.xsd"/>
  <xs:import namespace="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
             schemaLocation="cac-minimo.xsd"/>
  <xs:element name="Invoice">
    <xs:complexType>
      <xs:sequence>
        <xs:element ref="cbc:ID"/>
        <xs:element ref="cbc:IssueDate"/>
        <xs:element ref="cac:AccountingSupplierParty"/>
        <xs:element ref="cac:InvoiceLine" minOccurs="1" maxOccurs="unbounded"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
```

Los dos esquemas importados (`cbc-minimo.xsd`, con `ID`, `IssueDate` de tipo `xs:date`,
`CompanyID` restringido a nueve o diez dígitos y `LineExtensionAmount` decimal con atributo
`currencyID`; y `cac-minimo.xsd`, con los tres agregados) son el ejercicio 4: escribirlos es la
mejor forma de entender cómo UBL reparte un documento en tres espacios de nombres.

```bash
python3 factura_xml.py
```

Salida (Python 3.14.7, 05/10/2026) del resumen; la línea `válida`, del 07/10/2026, con los dos esquemas del
ejercicio 4 escritos aparte:

```text
{'invoice': 'FE-000123', 'nit': '900123456', 'nit_ok': True, 'lines': 2, 'total': Decimal('280000.00'), 'line_2': ['95000.00']}
válida
```

Con la fecha escrita a la colombiana (`28/09/2026`), la misma validación devuelve el error con línea y ruta, que es lo
que Patricia necesita para corregir:

```text
línea 6: /*/cbc:IssueDate: Element '{urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2}IssueDate': '28/09/2026' is not a valid value of the atomic type 'xs:date'.
```

**Detalles con intención**

- **`etree.XPath` compila la consulta una vez.** En un lote de diez mil facturas eso se nota, y
  además le pone nombre a cada pregunta.
- **`$line` es una variable de XPath**, no una cadena formateada. Es el equivalente a un
  parámetro de SQL, y por la misma razón: concatenar entradas en una consulta XPath es inyección.
- **El mismo `SAFE_PARSER` lee los XSD.** Un esquema también es XML que llegó de algún lado.
- **El dígito de verificación se valida en Python, no en el XSD.** XSD 1.0 no puede calcular un
  módulo 11; lo que no expresa el esquema va en código, y los dos juntos son el contrato.

### La bomba, a propósito

Guarda esto como `bomba.xml` y léelo con los dos parsers:

```xml
<?xml version="1.0"?>
<!DOCTYPE r [
  <!ENTITY a "aaaaaaaaaa">
  <!ENTITY b "&a;&a;&a;&a;&a;&a;&a;&a;&a;&a;">
  <!ENTITY c "&b;&b;&b;&b;&b;&b;&b;&b;&b;&b;">
  <!ENTITY d "&c;&c;&c;&c;&c;&c;&c;&c;&c;&c;">
]>
<r>&d;</r>
```

```python
from lxml import etree

print(len(etree.parse("bomba.xml").getroot().text or ""))            # parser por defecto
print(etree.parse("bomba.xml", SAFE_PARSER).getroot().text)          # sin expandir entidades
```

Con cuatro niveles son diez mil caracteres y no pasa nada; con nueve niveles serían mil millones.
`libxml2` trae límites contra la expansión exponencial y los aplica salvo que actives
`huge_tree=True`, que es exactamente la opción que alguien activa "porque el XML grande no cargaba".
En la prueba de humo, el parser por defecto devolvió 10.000 caracteres y el de la sección `None`:
no expande las entidades en absoluto, y la entidad queda en el árbol como un nodo sin resolver.

---

## ⚠️ 4. Lo que se rompe

**Consultar con los prefijos del documento.** `tree.xpath("//cbc:ID")` sin `namespaces=` falla, y
pasarle el `nsmap` del documento funciona hasta que llega un archivo con otros prefijos. El mapa
es tuyo y se declara una vez.

**El espacio de nombres por defecto.** `/Invoice/cbc:ID` no encuentra nada, porque `Invoice` está
en el espacio de nombres por defecto y XPath 1.0 no tiene "espacio por defecto": hay que darle un
prefijo propio (`inv:` en el ejemplo). Es el error de XML más preguntado del mundo.

**`text` que no es el texto.** `element.text` es solo el texto **antes del primer hijo**. Un
elemento con texto mezclado (`<obs>Paciente <b>no</b> asistió</obs>`) devuelve `"Paciente "`. Para
el texto completo, `"".join(element.itertext())` o `string(.)` en XPath.

**Validar el documento equivocado.** El XSD oficial de la DIAN importa los de UBL, y esos importan
otros. Si tu copia local de los esquemas no está completa, `XMLSchema` falla al **compilar el
esquema**, no al validar el documento, con un error que menciona un archivo que nunca abriste. Los
esquemas se versionan con el proyecto, completos, y se cargan con rutas relativas.

---

## ⚖️ 5. Cuándo NO usarla

**Para XML que tú generas y tú lees.** Si el XML no cruza ninguna frontera de confianza y es
pequeño, `ElementTree` de la biblioteca estándar alcanza y ahorra una dependencia compilada. La
Fase 06 lo usa así, y está bien.

**Para documentos que se escriben enteros, campo por campo.** Generar la factura desde cero con
`SubElement` es tedioso y propenso a errores de orden. Ahí conviene una plantilla (Jinja2, con
escape de XML) o clases generadas desde el XSD con `xsdata`. `lxml` sigue siendo el que valida el
resultado.

**Para XML de varios gigabytes.** `etree.parse` construye el árbol entero en memoria. Para
archivos enormes existe `etree.iterparse`, que entrega elementos a medida que los lee y permite
borrarlos; el ejercicio 7 lo pide.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Agrega una consulta con nombre `ISSUE_DATE` y devuelve la fecha como `datetime.date`.
   **Criterio:** `summarize` incluye la fecha y es de tipo `date`.
2. Calcula el dígito de verificación de tres NIT reales de empresas públicas colombianas (el tuyo
   no) y compáralo con el que publican. **Criterio:** los tres coinciden con `check_digit`.
3. Cambia los prefijos de `factura.xml` (`cbc` → `b`, `cac` → `a`) sin tocar las URI.
   **Criterio:** `summarize` devuelve exactamente lo mismo, sin cambiar una línea de Python.

**🟡 Intermedio (4–6)**

4. Escribe `cbc-minimo.xsd` y `cac-minimo.xsd`. **Criterio:** la factura del ejemplo es válida; la
   misma factura sin líneas, con un NIT de ocho dígitos o con la fecha `28/09/2026` falla, y cada
   error trae la línea.
5. Escribe una XSLT 1.0 que convierta la factura en una tabla HTML con el número, la fecha y las
   líneas, y aplícala con `etree.XSLT`. **Criterio:** el HTML abre en un navegador y la suma de las
   líneas coincide con `total`.
6. Busca en la documentación de `lxml` qué hace `resolve_entities="internal"` y en qué versión
   cambió el valor por defecto del parser. **Criterio:** explicas en dos líneas qué protege y qué
   no protege el valor por defecto actual.

**🟠 Difícil (7–9)**

7. Fabrica un archivo con 200.000 facturas concatenadas dentro de un `<Lote>` y súmalas con
   `etree.iterparse`, liberando cada factura después de leerla. **Criterio:** el pico de memoria
   (`tracemalloc` o RSS) no crece con el número de facturas; lo demuestras con 20.000 y con
   200.000.
8. Escribe un XXE de lectura de archivo (`<!ENTITY x SYSTEM "file:///etc/hostname">`) y
   demuestra qué parser lo ejecuta y cuál no: el de la biblioteca estándar, el de `lxml` por
   defecto y `SAFE_PARSER`. **Criterio:** una tabla de tres filas con lo que devolvió cada uno, y
   la versión de cada biblioteca.
9. Inyección en XPath: escribe la versión ingenua de `LINE_BY_ID` con un f-string y encuentra una
   entrada que devuelva las líneas de **todas** las facturas. **Criterio:** la entrada maliciosa
   funciona contra la versión ingenua y no contra la de la sección.

**🔴 Muy difícil (10)**

10. Descarga el anexo técnico vigente de factura electrónica de la DIAN y sus XSD, y valida
    contra ellos una factura completa generada por ti. **Criterio:** tu factura pasa la
    validación local con los esquemas oficiales. *Rúbrica:* (a) los esquemas viven en el
    repositorio con su versión anotada; (b) la carga es por rutas relativas y funciona desde
    cualquier directorio; (c) un error tuyo produce un mensaje con línea y ruta legible para
    alguien que no sabe XML; (d) dices qué reglas del anexo **no** puede comprobar el XSD y dónde
    las comprobarías.

---

## 📚 7. Referencias

**Documentación oficial**

- `lxml`, la guía de XPath y XSLT: https://lxml.de/xpathxslt.html
- `lxml`, validación con XSD: https://lxml.de/validation.html
- `lxml`, el parser y sus opciones: https://lxml.de/parsing.html
- Python, las vulnerabilidades de XML y qué parser es vulnerable a qué:
  https://docs.python.org/3/library/xml.html#xml-vulnerabilities

**Estándares**

- UBL 2.1, la especificación de OASIS: https://docs.oasis-open.org/ubl/UBL-2.1.html
- OWASP sobre XXE: https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html

**Orden de lectura sugerido:** la tabla de vulnerabilidades de la documentación de Python primero
—es corta y cambia cómo lees todo lo demás—; después la guía de XPath de `lxml`; y UBL solo cuando
tengas que escribir una factura completa.

---

## 🚀 8. Cierre

El XML de la DIAN deja de ser un archivo opaco cuando cada pregunta tiene nombre, el esquema se
valida antes de mandar y el parser no confía en nadie. Lo que sigue en el track es la parte que
esta sección esquiva a propósito: **firmar** ese XML.

**La señal de que quedó bien:** *"El lote no rebotó, y cuando una factura estaba mal, el error
decía la línea y el campo antes de mandarla."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-lg-fase-02 -m "op lg02 cerrada: XPath con nombre, XSD y parser seguro"
> ```
>
> Los commits llevan su prefijo (`op lg02: …`) y los de ejercicio su número
> (`op lg02 ej07: …`).
