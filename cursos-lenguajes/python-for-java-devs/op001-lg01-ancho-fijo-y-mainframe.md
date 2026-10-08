# 🧾 lg01 — Ancho fijo y mainframe

> Python para desarrolladores Java senior · **Carta** · Track `lg` — Legado e intercambio
> sectorial · sección 1 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta. Conviene haber leído la
> [Fase 06](06-formatos-en-la-caja.md), que deja el encoding y el CSV resueltos.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Una de las aseguradoras con las que trabaja Áurea no tiene portal ni API para las glosas: las
manda una vez por semana en un archivo que su mainframe produce desde hace veinte años. No es un
CSV. No tiene separadores, no tiene encabezado y, si lo abres en un editor, ves basura: bytes que
no son ni UTF-8 ni Latin-1, y montos que no se parecen a ningún número. Patricia lo recibe, no
puede leerlo, y lo reenvía a alguien que tampoco.

Ese archivo tiene tres propiedades que el formato heredado de cualquier sector financiero o de
salud comparte, y que esta sección enseña a leer:

- **Ancho fijo.** Cada campo ocupa siempre los mismos bytes, en la misma posición. El "esquema"
  no viaja con el archivo: vive en un documento aparte, que en el mundo COBOL se llama
  *copybook*.
- **EBCDIC.** El juego de caracteres de los mainframes de IBM. La `A` no es `0x41` sino `0xC1`,
  y la `Ñ` depende de la página de códigos que eligió alguien en 1998.
- **Decimal empaquetado** (`COMP-3`). Los montos no se guardan como texto ni como binario de
  complemento a dos, sino como dígitos decimales de cuatro bits, dos por byte, con el signo en el
  último medio byte.

Nada de esto es difícil. Es **desconocido**, y por eso la reacción habitual es buscar una
biblioteca que lo resuelva. Esta sección muestra que con la biblioteca estándar —`struct`,
`codecs` y `decimal`— se lee en sesenta líneas que caben en una pantalla, y que esas sesenta
líneas son más fáciles de mantener que cualquier dependencia.

---

## 🧠 2. El modelo

Un registro de ancho fijo es una **estructura de C escrita a disco**. No hay nada que parsear en
el sentido de un lenguaje: hay que cortar bytes en las posiciones que dice el copybook y
convertir cada trozo según su tipo. El copybook de la aseguradora, simplificado, dice esto:

```text
01  GLOSA-REG.
    05  GL-TIPO-REG        PIC X(2).            posición  0, 2 bytes, texto
    05  GL-NIT-PRESTADOR   PIC 9(10).           posición  2, 10 bytes, dígitos en texto
    05  GL-NRO-FACTURA     PIC X(12).           posición 12, 12 bytes, texto
    05  GL-FECHA-NOTIF     PIC 9(8).            posición 24, 8 bytes, AAAAMMDD
    05  GL-COD-GLOSA       PIC X(4).            posición 32, 4 bytes, texto
    05  GL-VALOR-GLOSADO   PIC S9(11)V99 COMP-3. posición 36, 7 bytes, empaquetado
    05  GL-OBSERVACION     PIC X(40).           posición 43, 40 bytes, texto
                                                 total: 83 bytes por registro
```

Tres cosas de esa tabla son la sección entera:

- **`PIC 9(10)` no es un número binario**: son diez caracteres que resultan ser dígitos, en
  EBCDIC. Se decodifican como texto y después se convierten.
- **`S9(11)V99 COMP-3` ocupa 7 bytes**, no 13. Trece dígitos más el signo son catorce medios
  bytes, y catorce medios bytes caben en siete. La `V` es una coma decimal **implícita**: no está
  en el archivo, la pone quien lee.
- **El total es 83 bytes** y no hay salto de línea. Un archivo de mainframe de registros fijos no
  tiene `\n`: es una tira de registros pegados. Si el archivo tiene registros de largo variable,
  cada uno va precedido de un *RDW* (*record descriptor word*): cuatro bytes, los dos primeros con
  el largo del registro en big-endian, incluidos ellos mismos.

El decimal empaquetado, byte a byte, se ve así para el valor `-1.234.567,89`:

```text
dígitos:      0 0 0 0 1 2 3 4 5 6 7 8 9   (13 dígitos, S9(11)V99)
signo:        D                            (C o F = positivo, D = negativo)
medios bytes: 0 0 | 0 0 | 1 2 | 3 4 | 5 6 | 7 8 | 9 D
bytes:        0x00 0x00 0x12 0x34 0x56 0x78 0x9D
```

### Tu instinto de Java dice… y esta vez se equivoca

El reflejo es buscar el equivalente de JRecord o de `cb2java`: una biblioteca que lea el copybook
y genere las clases. En Java tiene sentido, porque cortar un `byte[]` a mano con `ByteBuffer` y
`Charset.forName("IBM037")` es verboso y nadie quiere escribirlo dos veces.

En Python el corte es una línea por campo, el códec EBCDIC viene en la biblioteca estándar
(`cp037`, `cp500`, `cp1140`) y el decimal empaquetado son ocho líneas. **La biblioteca que buscas
cuesta más de mantener que el código que te ahorra**, y además oculta la única parte que
importa: qué posición tiene cada campo y qué pasa cuando la aseguradora la cambia.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| `ByteBuffer.wrap(b).getShort()` | `struct.unpack_from(">H", b, 0)` | `struct` exige el orden de bytes explícito (`>`, `<`); `ByteBuffer` asume big-endian por defecto |
| `new String(b, "IBM037")` | `b.decode("cp037")` | Mismo concepto; Python no trae todas las variantes nacionales de IBM, y para esas está el paquete `ebcdic` |
| `BigDecimal` | `decimal.Decimal` | Igual de exacto; `Decimal` se construye desde enteros y exponente sin pasar por `float` |
| Clases generadas desde el copybook | Una tabla de campos (`tuple`) y una función | No hay generación de código: el copybook se transcribe a datos, no a tipos |

---

## 💻 3. El ejemplo que corre

Sin dependencias: Python 3.14 y la biblioteca estándar. Un solo archivo,
`glosas_mainframe.py`, que hace las dos cosas que hacen falta para aprender esto sin tener un
mainframe: **escribir** un archivo de prueba con el mismo formato, y **leerlo**.

```python
"""Lee el archivo de glosas de ancho fijo, en EBCDIC y con decimal empaquetado."""

import datetime as dt
import struct
from dataclasses import dataclass
from decimal import Decimal
from collections.abc import Iterator
from pathlib import Path

CODEC = "cp037"  # EBCDIC de EE. UU./Canadá; la aseguradora lo declara en su manual

# El copybook, transcrito a datos: nombre, posición, largo y tipo. Si la aseguradora cambia el
# formato, esta tabla es lo único que se toca.
FIELDS: tuple[tuple[str, int, int, str], ...] = (
    ("record_type", 0, 2, "text"),
    ("provider_nit", 2, 10, "digits"),
    ("invoice_number", 12, 12, "text"),
    ("notified_on", 24, 8, "date"),
    ("objection_code", 32, 4, "text"),
    ("objected_amount", 36, 7, "packed2"),  # S9(11)V99 COMP-3: dos decimales implícitos
    ("note", 43, 40, "text"),
)
RECORD_LENGTH = 83


@dataclass(frozen=True, slots=True)
class ClaimObjection:
    record_type: str
    provider_nit: str
    invoice_number: str
    notified_on: dt.date
    objection_code: str
    objected_amount: Decimal
    note: str


def unpack_packed(raw: bytes, scale: int) -> Decimal:
    """Decodifica un COMP-3: dos dígitos por byte y el signo en el último medio byte."""
    nibbles = []
    for byte in raw:
        nibbles.append(byte >> 4)
        nibbles.append(byte & 0x0F)
    sign_nibble = nibbles.pop()
    if any(n > 9 for n in nibbles):
        raise ValueError(f"decimal empaquetado inválido: {raw.hex()}")
    if sign_nibble not in (0x0C, 0x0D, 0x0F):
        raise ValueError(f"signo de decimal empaquetado desconocido: {sign_nibble:X}")
    sign = 1 if sign_nibble == 0x0D else 0
    # Decimal se arma desde los dígitos y el exponente: nunca pasa por float.
    return Decimal((sign, tuple(nibbles), -scale))


def pack_packed(value: Decimal, length: int, scale: int) -> bytes:
    """La operación inversa, para fabricar archivos de prueba."""
    sign, digits, exponent = value.quantize(Decimal(1).scaleb(-scale)).as_tuple()
    width = length * 2 - 1
    padded = (0,) * (width - len(digits)) + tuple(digits)
    nibbles = (*padded, 0x0D if sign else 0x0C)
    return bytes((nibbles[i] << 4) | nibbles[i + 1] for i in range(0, len(nibbles), 2))


def decode_field(raw: bytes, kind: str) -> object:
    if kind == "packed2":
        return unpack_packed(raw, scale=2)
    text = raw.decode(CODEC).rstrip()
    if kind == "digits" and not text.isdigit():
        raise ValueError(f"se esperaban dígitos y llegó {text!r}")
    if kind == "date":
        return dt.datetime.strptime(text, "%Y%m%d").date()
    return text


def parse_record(record: bytes) -> ClaimObjection:
    if len(record) != RECORD_LENGTH:
        raise ValueError(f"registro de {len(record)} bytes; el copybook dice {RECORD_LENGTH}")
    values = {name: decode_field(record[start:start + size], kind)
              for name, start, size, kind in FIELDS}
    return ClaimObjection(**values)


def read_fixed(path: Path) -> Iterator[ClaimObjection]:
    """Registros fijos pegados, sin saltos de línea: se leen de a RECORD_LENGTH bytes."""
    with path.open("rb") as stream:
        position = 0
        while chunk := stream.read(RECORD_LENGTH):
            if len(chunk) < RECORD_LENGTH:
                raise ValueError(f"el archivo termina con un registro truncado en el byte {position}")
            try:
                yield parse_record(chunk)
            except ValueError as error:
                # El byte de inicio es lo único que la aseguradora entiende cuando se le reclama.
                raise ValueError(f"registro en el byte {position}: {error}") from error
            position += RECORD_LENGTH


def read_variable(path: Path) -> Iterator[bytes]:
    """Registros variables con RDW: dos bytes de largo (incluido el RDW) y dos en cero."""
    data = path.read_bytes()
    position = 0
    while position < len(data):
        length, reserved = struct.unpack_from(">HH", data, position)
        if reserved != 0 or length < 4:
            raise ValueError(f"RDW inválido en el byte {position}: {data[position:position + 4].hex()}")
        yield data[position + 4:position + length]
        position += length


def encode_record(objection: ClaimObjection) -> bytes:
    """Fabrica un registro con el mismo formato, para pruebas."""
    parts = []
    for name, _, size, kind in FIELDS:
        value = getattr(objection, name)
        if kind == "packed2":
            parts.append(pack_packed(value, size, scale=2))
        elif kind == "date":
            parts.append(value.strftime("%Y%m%d").encode(CODEC))
        else:
            parts.append(str(value).ljust(size)[:size].encode(CODEC))
    return b"".join(parts)


if __name__ == "__main__":
    sample = [
        ClaimObjection("GL", "9001234567", "FE-000123", dt.date(2026, 9, 28), "1102",
                       Decimal("185000.00"), "SOPORTE DE RADIOGRAFIA FALTANTE"),
        ClaimObjection("GL", "9001234567", "FE-000131", dt.date(2026, 9, 29), "2301",
                       Decimal("-12500.50"), "AJUSTE A FAVOR DEL PRESTADOR"),
    ]
    path = Path("glosas.dat")
    path.write_bytes(b"".join(encode_record(item) for item in sample))
    print(path.read_bytes()[:16].hex(" "))
    for objection in read_fixed(path):
        print(objection.invoice_number, objection.objection_code, objection.objected_amount)
```

```bash
python3 glosas_mainframe.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
c7 d3 f9 f0 f0 f1 f2 f3 f4 f5 f6 f7 c6 c5 60 f0
FE-000123 1102 185000.00
FE-000131 2301 -12500.50
```

La primera línea es la que vale la pena mirar: `c7 d3` es `GL` en EBCDIC y `f9 f0 f0` son los
dígitos `900`. Si alguna vez te llega un archivo "corrupto" donde los bytes de los dígitos van de
`f0` a `f9`, ya sabes qué es.

**Detalles con intención**

- **El copybook es una tupla de datos, no una clase por campo.** Cambiar el formato es editar una
  fila; agregar un campo no toca el código que lee.
- **El error dice el byte de inicio del registro.** Es el único dato que la aseguradora puede
  usar para encontrar el registro en su lado.
- **`Decimal` se construye desde la tupla de dígitos.** `Decimal(float(...))` habría metido el
  error de redondeo binario en una glosa, que es dinero que se discute.
- **`read_variable` devuelve bytes, no glosas.** Los registros variables suelen mezclar tipos
  (encabezado, detalle, pie) y el tipo se decide con los dos primeros bytes de cada uno.

---

## ⚠️ 4. Lo que se rompe

**La página de códigos equivocada no falla: miente.** `cp037` y `cp500` comparten casi todo y
difieren en unos pocos caracteres, entre ellos `[`, `]`, `!` y `|`. Un archivo leído con la
equivocada produce texto plausible con tres símbolos cambiados, y nadie lo nota hasta que el
número de factura `FE-[01]` no cruza contra nada. La página la declara el manual de la
aseguradora; si no la declara, se pregunta, y si no contestan se prueba con un registro conocido.

**La Ñ y las tildes.** `cp037` no tiene `Ñ` en la misma posición que las variantes nacionales de
IBM para español (`cp284`, por ejemplo). Si las observaciones llegan con `Ñ` y tu salida muestra
otra letra, el códec no es el correcto. El paquete `ebcdic` (2.0.1, publicado el 2026-03-03) agrega
las páginas que la biblioteca estándar no trae; agrégalo solo si tu archivo usa una de esas.

**El archivo pasó por un FTP en modo texto.** Si alguien bajó el archivo con FTP en modo ASCII, el
servidor ya lo convirtió de EBCDIC a ASCII **y de paso destrozó los campos empaquetados**: trató
cada byte como un carácter, y en un campo empaquetado `0x25` no es un salto de línea EBCDIC sino
los dígitos 2 y 5. El
síntoma es un archivo que se lee bien en los campos de texto y explota en los montos. El arreglo
no está en Python: es bajar en modo binario.

**El decimal "empaquetado" que no lo está.** Algunos sistemas guardan los montos como *zoned
decimal* (`PIC S9(11)V99` sin `COMP-3`): un dígito por byte, en EBCDIC, con el signo metido en el
medio byte alto del último. Ocupan 13 bytes en vez de 7, y `unpack_packed` sobre ellos levanta
"decimal empaquetado inválido" en el primer byte. El copybook dice cuál es; tu código tiene que
tener los dos.

---

## ⚖️ 5. Cuándo NO usarla

**Cuando el formato tiene un estándar con biblioteca mantenida.** Si el archivo de ancho fijo es
en realidad un formato sectorial público —un X12, un HL7 v2—, la biblioteca del estándar trae la
validación que tú no vas a escribir. Esta sección es para el formato **privado** de una
contraparte, donde no hay nada que reutilizar.

**Cuando el volumen es grande y el archivo se procesa muchas veces.** El lector de arriba
decodifica campo por campo en Python. Para el archivo semanal de una aseguradora —unos pocos miles
de registros— eso no importa; para un histórico de cien millones de registros que se consulta
todos los días, lo que corresponde es convertir una vez a Parquet y consultar el Parquet. El
costo de decodificar campo por campo no está medido aquí: queda como el ejercicio 9, con su
hipótesis escrita.

**Cuando la contraparte ofrece otro formato.** Muchas aseguradoras que mandan EBCDIC también
pueden mandar CSV en UTF-8 si alguien lo pide por escrito. Pedirlo cuesta un correo, y es la
opción más barata de esta sección.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Agrega al ejemplo un tercer registro con una observación que lleve `Ñ` y tildes, y verifica
   qué sale al leerlo con `cp037`. **Criterio:** explicas en una línea qué carácter cambió y con
   qué página de códigos se lee bien.
2. Escribe una prueba con `pytest` que fabrique un registro con `encode_record` y lo lea con
   `parse_record`, para tres montos: positivo, negativo y cero. **Criterio:** los tres vuelven
   idénticos, comparados como `Decimal`.
3. Haz que `parse_record` acepte registros de 84 bytes con un salto de línea al final, que es lo
   que pasa cuando alguien abre el archivo y lo guarda. **Criterio:** el mismo archivo con y sin
   `\n` entre registros produce las mismas glosas.

**🟡 Intermedio (4–6)**

4. Implementa `unpack_zoned(raw, scale)` para el decimal zonado y agrega el tipo `"zoned2"` a
   `decode_field`. **Criterio:** `S9(5)V99` con el valor `-123,45` (siete bytes, signo en el medio
   byte alto del último) se lee como `Decimal("-123.45")`.
5. Escribe `read_variable` para un archivo que mezcla registros de encabezado (`HD`), detalle
   (`GL`) y pie (`TR`, con el total de registros y la suma de montos), y valida el pie. **Criterio:**
   un archivo con un detalle borrado a mano falla con un mensaje que dice cuántos registros
   esperaba y cuántos encontró.
6. Busca en la documentación de `codecs` qué páginas EBCDIC trae Python y cuáles no. **Criterio:**
   una tabla de cuatro filas con la página, el país y si está en la biblioteca estándar.

**🟠 Difícil (7–9)**

7. Escribe un transcriptor mínimo de copybook: una función que reciba el texto de las líneas
   `05 … PIC …` y devuelva la tupla `FIELDS`, calculando posiciones y largos (incluido el de
   `COMP-3`). **Criterio:** sobre el copybook de la §2 devuelve exactamente la tupla del ejemplo.
8. Simula el daño del FTP en modo texto: toma `glosas.dat`, conviértelo a ASCII con
   `.decode("cp037").encode("latin-1", "replace")` y vuelve a leerlo. **Criterio:** explicas qué
   campo falla primero y por qué, señalando el byte.
9. Mide cuánto tarda `read_fixed` sobre un millón de registros fabricados con `encode_record`.
   **Criterio:** reportas registros por segundo con la máquina y la versión de Python, y decides
   si a ese ritmo vale la pena convertir a Parquet para un archivo semanal de 5.000 registros.

**🔴 Muy difícil (10)**

10. La aseguradora cambia el formato sin avisar: agrega dos bytes a `GL-NRO-FACTURA` en la mitad
    de los registros de una semana. Diseña la detección: que el lector descubra el cambio y se
    niegue a producir glosas con campos corridos. **Criterio:** el lector falla con un mensaje
    que nombra el primer registro sospechoso. *Rúbrica:* (a) no depende del largo del archivo,
    porque un archivo con registros corridos puede tener un largo válido; (b) usa al menos dos
    señales independientes —fecha válida, dígitos donde se esperan dígitos, signo del
    empaquetado—; (c) una prueba demuestra que el formato correcto sigue pasando; (d) explicas
    qué harías el lunes con la aseguradora.

---

## 📚 7. Referencias

**Documentación oficial**

- `struct`, formatos y orden de bytes: https://docs.python.org/3/library/struct.html
- Las codificaciones de la biblioteca estándar, con las EBCDIC (`cp037`, `cp500`, `cp1140`…):
  https://docs.python.org/3/library/codecs.html#standard-encodings
- `decimal`, y la construcción desde una tupla: https://docs.python.org/3/library/decimal.html

**Bibliotecas**

- `ebcdic` en PyPI, para las páginas que la biblioteca estándar no trae:
  https://pypi.org/project/ebcdic/

**Orden de lectura sugerido:** la tabla de formatos de `struct`; después la lista de
codificaciones, buscando las que empiezan por `cp0` y `cp1`; y `decimal` solo si nunca
construiste un `Decimal` desde una tupla.

---

## 🚀 8. Cierre

Lo que te llevas no es una técnica para COBOL: es la costumbre de **transcribir un esquema a
datos** en vez de a tipos, y de que el error diga dónde está el byte que falló. Es la misma
costumbre que hace legibles el XML de la DIAN y el EDI de una aseguradora, que son las dos
secciones que siguen en este track.

**La señal de que quedó bien:** *"La aseguradora cambió el formato y el lector se negó a leerlo,
y el mensaje decía en qué byte."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-lg-fase-01 -m "op lg01 cerrada: lector de ancho fijo, EBCDIC y COMP-3"
> ```
>
> Los commits llevan su prefijo (`op lg01: …`) y los de ejercicio su número
> (`op lg01 ej07: …`).
