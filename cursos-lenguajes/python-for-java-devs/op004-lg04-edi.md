# 🧾 lg04 — EDI: X12 y EDIFACT

> Python para desarrolladores Java senior · **Carta** · Track `lg` — Legado e intercambio
> sectorial · sección 4 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

EDI (*Electronic Data Interchange*) es la forma en que las empresas se mandaban documentos entre
sí antes de que existiera la web, y la forma en que muchas se los siguen mandando. Dos estándares
cubren casi todo:

- **ANSI X12**, el de Norteamérica. En salud es obligatorio en Estados Unidos: la reclamación a
  una aseguradora es un *837*, la remesa de pago un *835*, la consulta de cobertura un *270*.
- **UN/EDIFACT**, el de Naciones Unidas, dominante en Europa y en el comercio internacional:
  órdenes de compra (`ORDERS`), facturas (`INVOIC`), avisos de despacho (`DESADV`).

Áurea **no usa EDI hoy**, y esta sección no lo finge. Su contacto más probable con este mundo es
por el lado del suministro: un distribuidor internacional de materiales de ortodoncia que acepta
pedidos en EDIFACT, o un laboratorio extranjero que factura así. Pero el formato aparece en
cualquier trabajo de integración con aseguradoras, aerolíneas, retail o logística, y tiene la
mala fama de ser ilegible. **No lo es**: es un formato con delimitadores, solo que los
delimitadores los declara el propio archivo.

---

## 🧠 2. El modelo

Un intercambio EDI es una tira de **segmentos** separados por un terminador. Cada segmento empieza
con un identificador de dos o tres letras y tiene **elementos** separados por otro carácter; un
elemento puede tener **componentes**, separados por un tercero. Los segmentos se anidan en
**sobres**:

```text
X12                                   EDIFACT
ISA … IEA   intercambio               UNB … UNZ   intercambio
 GS … GE    grupo funcional            UNG … UNE  grupo (opcional, casi nunca)
  ST … SE   transacción (un 837)        UNH … UNT  mensaje (un ORDERS)
   … los segmentos del documento …       … los segmentos del documento …
```

Lo que confunde a todo el mundo la primera vez es que **los delimitadores no son fijos**:

- **X12** los declara por **posición** en el segmento `ISA`, que mide exactamente 106 caracteres.
  El carácter 4 es el separador de elementos, el 105 el de componentes y el 106 el terminador de
  segmento.
- **EDIFACT** los declara, si quiere, en un segmento `UNA` opcional de nueve caracteres
  (`UNA:+.? '`): componentes, elementos, marca decimal, carácter de escape, un reservado y el
  terminador. Si no hay `UNA`, valen esos mismos por defecto. Y tiene **carácter de escape**: `?+`
  es un `+` literal, no un separador.

El otro concepto que hay que traer de casa es el **bucle** (*loop*): un grupo de segmentos que se
repite, como cada línea de servicio de una reclamación. El estándar no marca dónde empieza y
termina un bucle; lo deduce quien lee, por el segmento que lo abre. Por eso un parser genérico te
da segmentos, y la **guía de implementación** de cada transacción te dice cómo agruparlos.

### Tu instinto de Java dice… y esta vez se equivoca

El reflejo es buscar el producto comercial —un traductor EDI con su mapeador gráfico— porque en el
mundo Java el EDI suele vivir dentro de una suite de integración. Para **leer** EDI no hace falta:
el tokenizador son veinte líneas, porque el formato fue diseñado en los setenta para que lo
procesaran máquinas con muy poca memoria. Donde sí hace falta ayuda es en **validar** contra la
guía de implementación de una transacción concreta, y para eso hay bibliotecas específicas.

---

## 💻 3. El ejemplo que corre

Sin dependencias para el tokenizador. Un solo archivo, `edi.py`, que lee X12 y EDIFACT
descubriendo los delimitadores del propio archivo.

```python
"""Tokenizador de X12 y EDIFACT: descubre los delimitadores y devuelve segmentos."""

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Delimiters:
    segment: str
    element: str
    component: str
    release: str | None = None  # solo EDIFACT tiene carácter de escape


def x12_delimiters(data: str) -> Delimiters:
    if not data.startswith("ISA") or len(data) < 106:
        raise ValueError("un intercambio X12 empieza con un ISA de 106 caracteres")
    # Las posiciones son las del estándar: el ISA es de ancho fijo aunque use separadores.
    return Delimiters(segment=data[105], element=data[3], component=data[104])


def edifact_delimiters(data: str) -> tuple[Delimiters, str]:
    if data.startswith("UNA"):
        component, element, _decimal, release, _reserved, segment = data[3:9]
        return Delimiters(segment, element, component, release), data[9:]
    return Delimiters("'", "+", ":", "?"), data


def split_escaped(text: str, separator: str, release: str | None,
                  unescape: bool = False) -> list[str]:
    """Corta por el separador respetando el carácter de escape de EDIFACT.

    En los niveles de segmento y de elemento el escape se conserva (`?+` sigue siendo `?+`),
    porque el nivel siguiente todavía tiene que saber que ese `+` no separa nada. Solo el último
    nivel, el de componentes, lo quita.
    """
    if not release:
        return text.split(separator)
    parts, current, escaped = [], [], False
    for char in text:
        if escaped:
            current.append(char if unescape else release + char)
            escaped = False
        elif char == release:
            escaped = True
        elif char == separator:
            parts.append("".join(current))
            current = []
        else:
            current.append(char)
    parts.append("".join(current))
    return parts


def segments(data: str) -> list[list[list[str]]]:
    """Devuelve cada segmento como lista de elementos, y cada elemento como lista de componentes."""
    data = data.strip().replace("\r", "").replace("\n", "")
    if data.startswith("ISA"):
        delims, body = x12_delimiters(data), data
    else:
        delims, body = edifact_delimiters(data)
    result = []
    for raw in split_escaped(body, delims.segment, delims.release):
        if not raw:
            continue
        elements = split_escaped(raw, delims.element, delims.release)
        result.append([split_escaped(e, delims.component, delims.release, unescape=True)
                       for e in elements])
    return result


def tag(segment: list[list[str]]) -> str:
    return segment[0][0]


X12_SAMPLE = (
    "ISA*00*          *00*          *ZZ*AUREA          *ZZ*ASEGURADORA    "
    "*260928*1200*^*00501*000000905*0*T*:~"
    "GS*HC*AUREA*ASEGURADORA*20260928*1200*905*X*005010X222A1~"
    "ST*837*0001*005010X222A1~"
    "CLM*FE-000123*280000***11:B:1*Y*A*Y*Y~"
    "SV1*HC:D0120*185000*UN*1***1~"
    "SV1*HC:D1110*95000*UN*1***1~"
    "SE*5*0001~GE*1*905~IEA*1*000000905~"
)

EDIFACT_SAMPLE = (
    "UNA:+.? '"
    "UNB+UNOC:3+AUREA+DISTRIBUIDOR+260928:1200+42'"
    "UNH+1+ORDERS:D:96A:UN'"
    "BGM+220+PO-2026-0917+9'"
    "LIN+1++BRK-0022:SA'QTY+21:40'"
    "FTX+AAI+++Entregar en sede Centro?+ urgente'"
    "UNT+6+1'UNZ+1+42'"
)

if __name__ == "__main__":
    for segment in segments(X12_SAMPLE):
        if tag(segment) == "SV1":
            code = segment[1][1]   # HC:D0120 → el componente 2 es el código
            amount = segment[2][0]
            print("X12 línea de servicio", code, amount)
    for segment in segments(EDIFACT_SAMPLE):
        if tag(segment) in ("LIN", "QTY", "FTX"):
            print("EDIFACT", tag(segment), [e for e in segment[1:] if e != [""]])
```

```bash
python3 edi.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
X12 línea de servicio D0120 185000
X12 línea de servicio D1110 95000
EDIFACT LIN [['1'], ['BRK-0022', 'SA']]
EDIFACT QTY [['21', '40']]
EDIFACT FTX [['AAI'], ['Entregar en sede Centro+ urgente']]
```

La última línea es la que justifica el carácter de escape: el texto libre del pedido lleva un `+`,
que en EDIFACT es el separador de elementos, y `?+` lo protege. Un `split("+")` ingenuo habría
partido la observación en dos elementos y corrido todos los siguientes.

**Detalles con intención**

- **Los delimitadores salen del archivo**, nunca de una constante. Un socio que cambia `~` por un
  salto de línea como terminador no rompe nada.
- **Tres niveles de lista** —segmento, elemento, componente— en vez de un objeto por segmento. Es
  la forma del dato; los objetos con nombre van una capa más arriba, por transacción.
- **El escape se quita al final.** Si el nivel de segmentos lo quitara, el `+` protegido de la
  observación volvería a ser un separador al cortar los elementos. Es el error que cometí en el
  primer borrador de este archivo, y el que cometen casi todos los tokenizadores caseros.
- **El tokenizador no valida.** Que el `SE` cuente bien los segmentos, que el código de
  procedimiento exista o que el bucle esté completo es trabajo de la capa de validación.

### Validar contra la guía de implementación

Para X12, `pyx12` (4.0.0, del 2026-05-05) valida un archivo contra las guías de implementación de
las transacciones de salud de Estados Unidos y produce el acuse de recibo (*997* o *999*):

```bash
uv add pyx12
x12valid reclamacion.837
```

Para EDIFACT, `pydifact` (0.2.3, del 2026-04-10) lee y escribe intercambios con un modelo de
segmentos, sin validar contra los directorios de mensajes. El traductor de código abierto clásico,
Bots, lleva publicado en PyPI sin cambios desde 2016 (3.3.0): se nombra como antecedente, no como
recomendación.

---

## ⚠️ 4. Lo que se rompe

**Leer el ISA con `split`.** Si el remitente usa `*` como separador pero sus campos de remitente
traen espacios de relleno, el ISA se ve bien partido y lo está; pero si alguien cambia el separador
y tú lo tenías fijo, el primer elemento queda con el intercambio entero adentro. El ISA se lee por
posición, siempre.

**Saltos de línea "de cortesía".** Muchos socios agregan un salto de línea después de cada
terminador para que el archivo sea legible. Otros usan el salto de línea **como** terminador. El
tokenizador de arriba borra los saltos antes de cortar, lo que funciona para el primer caso y
rompe el segundo: el ejercicio 3 lo arregla.

**Contar mal en el pie.** `SE` declara cuántos segmentos tiene la transacción incluyéndose a sí
mismo y al `ST`; `UNT` hace lo mismo en EDIFACT. Un generador propio que se equivoca por uno
produce archivos que el socio rechaza enteros, con un acuse de recibo que dice el código de error y
no la causa.

**Codificación.** EDIFACT declara el juego de caracteres en `UNB` (`UNOA`, `UNOB`, `UNOC`…). `UNOC`
es Latin-1; si lo lees como UTF-8, la primera tilde explota o, peor, se convierte en otra letra.

---

## ⚖️ 5. Cuándo NO usarla

**Cuando hay un traductor EDI en la casa.** Si la empresa ya paga una plataforma de integración que
habla EDI con sus socios, tu código Python debería recibir la salida ya traducida (JSON, CSV o una
tabla) y no tocar el EDI crudo.

**Para generar EDI nuevo contra un socio exigente.** Leer es fácil; **escribir** EDI que pase la
certificación de un socio grande —con sus guías propias encima del estándar, sus acuses y sus
pruebas de conectividad— es un proyecto. Ahí el tokenizador de veinte líneas es la parte trivial.

**Cuando el socio ofrece una API.** Muchos que hablan EDI ya exponen también REST. Si la API existe
y cubre la transacción, gana por mantenimiento, aunque el EDI sea "lo de siempre".

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Agrega al ejemplo la suma de los montos de las líneas `SV1` y compárala con el total del `CLM`.
   **Criterio:** imprime `cuadra` o la diferencia exacta.
2. Cambia en `X12_SAMPLE` el separador de elementos de `*` a `|` en todos los segmentos, incluido
   el ISA. **Criterio:** la salida es idéntica sin tocar el código.
3. Haz que `segments` acepte el salto de línea **como** terminador de X12 (el carácter 106 del ISA
   es `\n`). **Criterio:** un archivo con `~` y otro con `\n` como terminador dan los mismos
   segmentos.

**🟡 Intermedio (4–6)**

4. Escribe `envelopes(data)` que verifique que cada `ST`/`SE` y `GS`/`GE` están balanceados y que
   los conteos de los pies son correctos. **Criterio:** un archivo con un `SV1` borrado falla con un
   mensaje que nombra la transacción y los dos números.
5. Busca en la documentación de `pyx12` qué devuelve cuando un archivo no cumple la guía y qué es
   un *999*. **Criterio:** explicas en tres líneas qué le mandarías de vuelta al socio.
6. Agrupa las líneas de servicio por reclamación: cada `CLM` abre un bucle que se cierra con el
   siguiente `CLM` o con el `SE`. **Criterio:** una estructura `{número de factura: [líneas]}` con
   dos reclamaciones en un mismo archivo.

**🟠 Difícil (7–9)**

7. Escribe el **generador**: a partir de una lista de pedidos, produce un `ORDERS` de EDIFACT con
   el escape correcto y los conteos de `UNT` bien hechos. **Criterio:** tu tokenizador lee lo que
   generaste y devuelve los mismos pedidos, incluido uno con `'`, `+` y `?` en el texto libre.
8. Lee un archivo EDIFACT declarado `UNOC` que contenga `Ñ` y tildes, primero como UTF-8 y después
   como Latin-1. **Criterio:** muestras qué produce cada lectura y escribes la función que elige el
   códec a partir del `UNB`.
9. Mide cuánto tarda `segments` sobre un archivo de 200.000 segmentos y compáralo con una versión
   que use `re.split` con una expresión que respete el escape. **Criterio:** reportas segmentos por
   segundo de las dos, con la máquina, y eliges una con su razón.

**🔴 Muy difícil (10)**

10. Diseña la capa de validación de una transacción concreta (un `ORDERS` o un `837`) a partir de su
    guía de implementación: obligatoriedad, repeticiones, bucles y códigos permitidos.
    **Criterio:** un archivo válido pasa y cinco archivos con un defecto distinto cada uno fallan
    con mensajes legibles. *Rúbrica:* (a) la guía se transcribe a datos, no a `if`; (b) cada error
    dice segmento, posición y regla; (c) el validador es independiente del tokenizador; (d)
    explicas qué parte comprarías en vez de escribirla y por qué.

---

## 📚 7. Referencias

**Estándares**

- UN/EDIFACT, panorama del estándar y de sus directorios de mensajes:
  https://en.wikipedia.org/wiki/EDIFACT (el sitio de la UNECE, que es la fuente primaria, rechaza
  a los clientes automáticos y no se pudo verificar)
- X12, la organización que mantiene el estándar: https://x12.org/

**Bibliotecas**

- `pyx12`: https://github.com/azoner/pyx12
- `pydifact`: https://github.com/nerdocs/pydifact

**Orden de lectura sugerido:** el panorama de EDIFACT para entender la familia de mensajes;
después el código de `pydifact`, que es corto y muestra el mismo modelo de esta sección con más
cuidado; y la documentación de X12 solo si te toca una transacción concreta, porque las guías de
implementación son documentos de pago.

---

## 🚀 8. Cierre

El EDI parece ilegible porque sus delimitadores viven adentro del archivo. Una vez que el
tokenizador los descubre, lo que queda es una lista de listas, y el trabajo real se muda a la guía
de implementación de cada transacción.

**La señal de que quedó bien:** *"El socio cambió el terminador de segmento y no me enteré, porque
el lector lo leyó del ISA."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-lg-fase-04 -m "op lg04 cerrada: tokenizador X12 y EDIFACT con escape"
> ```
>
> Los commits llevan su prefijo (`op lg04: …`) y los de ejercicio su número
> (`op lg04 ej07: …`).
