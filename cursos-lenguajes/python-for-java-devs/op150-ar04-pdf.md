# 📄 ar04 — PDF

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 4 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El PDF es el formato donde termina todo lo que se imprime, se firma o se manda a un ente externo: facturas, relaciones de gastos, certificados. Python tiene una
biblioteca para cada parte del ciclo, y conviene saber cuál es cuál: **ReportLab** genera; **pypdf** lee, une y corta; **pdfplumber** extrae tablas; **PyMuPDF**
lee rápido y convierte páginas a imágenes; **pyHanko** firma y verifica; y **Tesseract** (con `pytesseract` u `ocrmypdf`) lee el texto de un PDF que es solo una
imagen escaneada.

La sección recorre el ciclo completo con un documento de muestra —una relación de gastos de tres sedes—: lo genera, extrae su texto y su tabla, lo firma, lo
altera para ver qué dice la verificación, y lo lee con OCR. La verificación tiene una trampa en su API que vale la sección entera.

El OCR es el paso que le falta a NormaRAG, el proyecto del track `ia` ([`ia05`](ia05-normarag.md)): su ingesta detecta y cuenta los PDF escaneados que no
tienen capa de texto y los deja fuera, como un agujero medido. Lo que aquí se aprende es cómo cerrarlo.

---

## 🧠 2. El modelo

| Biblioteca | Para qué | Licencia | El equivalente en Java |
|---|---|---|---|
| **ReportLab** | Generar PDF desde código (*platypus*: párrafos, tablas) | BSD | iText, OpenPDF |
| **pypdf** | Leer, unir, cortar, rotar; texto simple | BSD | PDFBox |
| **pdfplumber** | Extraer **tablas** y posiciones de caracteres | MIT | Tabula |
| **PyMuPDF** | Leer muy rápido, renderizar páginas a imagen | **AGPL** o comercial | — |
| **pyHanko** | Firmar (PAdES) y validar firmas | MIT | iText con firma, DSS |
| **Tesseract** (`pytesseract`, `ocrmypdf`) | OCR: texto desde imágenes | Apache | Tess4J |

### Tu instinto de Java dice… y esta vez se equivoca

Un PDF parece un documento con texto y tablas. No lo es: es una lista de instrucciones de dibujo ("pon este glifo en esta coordenada"). No hay filas ni celdas, solo
caracteres en posiciones. Por eso extraer el texto da cada celda en su propia línea, y por eso extraer la tabla necesita una biblioteca que **reconstruya** las filas a
partir de las líneas dibujadas y las posiciones.

---

## 💻 3. El ejemplo que corre

`pdfs.py`:

```python
"""Un PDF de muestra: generarlo, extraer su texto y su tabla con tres bibliotecas, firmarlo y leerlo con OCR."""

import datetime as dt
import io
import time

import pdfplumber
import pymupdf
import pytesseract
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import NameOID
from PIL import Image
from pyhanko.pdf_utils.incremental_writer import IncrementalPdfFileWriter
from pyhanko.pdf_utils.reader import PdfFileReader
from pyhanko.sign import signers
from pyhanko.sign.validation import validate_pdf_signature
from pyhanko_certvalidator import ValidationContext
from pypdf import PdfReader
from reportlab.lib.pagesizes import letter
from reportlab.platypus import Paragraph, SimpleDocTemplate, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet

ROWS = [["Sede", "Concepto", "Valor"], ["Kennedy", "Arriendo de octubre", "4.200.000"],
        ["Engativá", "Servicios públicos", "1.150.000"], ["Fontibón", "Mantenimiento de sillones", "780.000"]]

# 1) Generar con ReportLab
buffer = io.BytesIO()
doc = SimpleDocTemplate(buffer, pagesize=letter)
table = Table(ROWS)
table.setStyle(TableStyle([("GRID", (0, 0), (-1, -1), 0.5, "grey")]))
doc.build([Paragraph("Relación de gastos de muestra · octubre de 2026", getSampleStyleSheet()["Title"]), table])
pdf = buffer.getvalue()
print(f"ReportLab: {len(pdf):,} bytes")

# 2) Extraer: texto con pypdf y PyMuPDF, tabla con pdfplumber
for name, extract in (("pypdf", lambda: PdfReader(io.BytesIO(pdf)).pages[0].extract_text()),
                      ("PyMuPDF", lambda: pymupdf.open(stream=pdf).load_page(0).get_text())):
    start = time.perf_counter(); text = extract(); ms = (time.perf_counter() - start) * 1000
    lines = text.splitlines()
    print(f"{name:<8} {ms:4.1f} ms · {' | '.join(lines[lines.index('Kennedy') - 3:lines.index('Kennedy') + 3])}")
with pdfplumber.open(io.BytesIO(pdf)) as plumber:
    print("pdfplumber, la tabla:", plumber.pages[0].extract_table()[1])

# 3) Firmar con un certificado de prueba y verificar; después alterar un byte
key = ec.generate_private_key(ec.SECP256R1())
name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Firma de prueba")])
now = dt.datetime.now(dt.UTC)
cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(key.public_key())
        .serial_number(1).not_valid_before(now).not_valid_after(now + dt.timedelta(days=1))
        .sign(key, hashes.SHA256()))
open("clave.pem", "wb").write(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                                   serialization.NoEncryption()))
open("cert.pem", "wb").write(cert.public_bytes(serialization.Encoding.PEM))
signer = signers.SimpleSigner.load("clave.pem", "cert.pem")
signed = io.BytesIO()
signers.sign_pdf(IncrementalPdfFileWriter(io.BytesIO(pdf)), signers.PdfSignatureMetadata(field_name="Firma"),
                 signer=signer, output=signed)
context = ValidationContext(trust_roots=[signer.signing_cert])


def check(data):
    status = validate_pdf_signature(PdfFileReader(io.BytesIO(data)).embedded_signatures[0], context)
    return f"intact={status.intact} · valid={status.valid} · bottom_line={status.bottom_line}"


print("firmado:", check(signed.getvalue()))
tampered = signed.getvalue().replace(b"ReportLab", b"ReportLaX", 1)       # un byte dentro de lo firmado
print("con un byte cambiado:", check(tampered))

# 4) OCR: el PDF como imagen, leído por Tesseract
page = pymupdf.open(stream=pdf).load_page(0).get_pixmap(dpi=200)
image = Image.open(io.BytesIO(page.tobytes("png")))
start = time.perf_counter()
ocr = pytesseract.image_to_string(image, lang="spa")
found = [value for row in ROWS[1:] for value in row if value in ocr]
print(f"OCR {(time.perf_counter() - start) * 1000:5.0f} ms · reconoció {len(found)} de 9 celdas · faltan: {[v for row in ROWS[1:] for v in row if v not in found]}")
```

```bash
apt-get install tesseract-ocr tesseract-ocr-spa    # el motor de OCR y el idioma español; en el contenedor, Tesseract 5.5.0
pip install reportlab pypdf pdfplumber PyMuPDF pyhanko pytesseract Pillow
python3 pdfs.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
ReportLab: 1,927 bytes
pypdf     1.7 ms ·  Sede | Concepto | Valor | Kennedy | Arriendo de octubre | 4.200.000
PyMuPDF   2.3 ms · Sede | Concepto | Valor | Kennedy | Arriendo de octubre | 4.200.000
pdfplumber, la tabla: ['Kennedy', 'Arriendo de octubre', '4.200.000']
firmado: intact=True · valid=True · bottom_line=True
con un byte cambiado: intact=False · valid=True · bottom_line=False
OCR   389 ms · reconoció 9 de 9 celdas · faltan: []
```

ReportLab genera el documento en menos de 2 KB. pypdf y PyMuPDF extraen el texto en 2 ms, **una celda por línea**: la tabla se volvió una lista. pdfplumber la
reconstruye como filas. La firma se verifica, y con un solo byte cambiado dentro del rango firmado la verificación dice **`valid=True`** —la firma criptográfica sigue
siendo correcta— pero **`intact=False`**: el documento ya no es el que se firmó. El veredicto completo es `bottom_line`. Y el OCR, sobre la página convertida en imagen
a 200 ppp, reconoce las nueve celdas, tildes incluidas, en 389 ms: 200 veces más que extraer el texto, cuando hay texto que extraer.

**Detalles con intención**

- **`bottom_line`** es la respuesta a "¿confío en este documento?". `valid` solo dice que la firma corresponde al resumen guardado; `intact`, que el resumen
  corresponde al documento. Hacen falta las dos, y `bottom_line` las combina con la confianza en el certificado.
- **El certificado es autofirmado y vale un día**: para probar el mecanismo. Una firma con validez legal usa un certificado de una entidad acreditada y, para que valga
  años, un sello de tiempo (`pyhanko` lo pide con `timestamper=`).
- **`replace(b"ReportLab", b"ReportLaX", 1)`** cambia el nombre del productor, que está en el rango firmado y sin comprimir. Cambiar `4.200.000` no habría encontrado
  nada: el contenido de la página está comprimido con Flate.
- **`get_pixmap(dpi=200)`**: Tesseract necesita resolución; a 72 ppp falla en las tildes y los números.

---

## ⚠️ 4. Lo que se rompe

**Verificar con `valid`.** El código que revisa `status.valid` acepta un documento alterado después de firmar. Se revisa `bottom_line`.

**La licencia de PyMuPDF.** Es AGPL: usarla en un servicio que se ofrece por red obliga a publicar el código del servicio, o a comprar la licencia comercial. pypdf
y pdfplumber, con licencias permisivas, cubren casi todo lo demás.

**Extraer tablas con `extract_text`.** Una celda por línea, y las celdas con dos líneas de texto se mezclan con la siguiente. Tablas, con pdfplumber o Camelot.

**OCR sobre un PDF que ya tiene texto.** 200 veces más lento y con errores posibles. Primero se intenta extraer; si sale vacío, el PDF es una imagen y entra el OCR.
`ocrmypdf` lo decide solo y agrega una capa de texto al PDF.

---

## ⚖️ 5. Cuándo NO usarlo

**Para generar documentos con mucho diseño.** HTML y CSS con WeasyPrint, o Typst (`ar07`), son más fáciles de mantener que el código de ReportLab.

**OCR para documentos con estructura fija y volumen alto.** Un servicio de extracción de documentos (de la nube o un modelo de visión) entiende campos; Tesseract solo
devuelve texto.

**Firmar con validez legal desde un *script*.** La firma con certificado acreditado, sello de tiempo y custodia de la clave es un proceso; el código es la parte chica.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las siete líneas, y la diferencia entre `valid`, `intact` y `bottom_line`.
2. Une el PDF de muestra con otro en uno solo con pypdf. **Criterio:** un PDF de dos páginas.
3. Extrae las posiciones de los caracteres de "Kennedy" con pdfplumber (`page.chars`). **Criterio:** las coordenadas de cada letra.

**🟡 Intermedio (4–6)**

4. Agrega al documento una celda con dos líneas de texto y vuelve a extraer la tabla. **Criterio:** qué hace pdfplumber y qué hace `extract_text`.
5. Corre el OCR a 72, 150 y 300 ppp. **Criterio:** celdas reconocidas y tiempo en cada resolución.
6. Pasa el PDF convertido a imagen por `ocrmypdf`. **Criterio:** el PDF resultante tiene texto seleccionable.

**🟠 Difícil (7–9)**

7. Firma dos veces el mismo PDF (dos firmantes) y altera el documento entre las dos firmas. **Criterio:** qué dice la validación de cada firma.
8. Agrega un sello de tiempo a la firma con un servidor TSA de prueba. **Criterio:** la validación muestra la hora del sello.
9. Extrae la tabla de un PDF real de un banco o un ente público. **Criterio:** las filas correctas, y lo que tuviste que configurar.

**🔴 Muy difícil (10)**

10. Diseña el flujo de un documento firmado que sale de un sistema y vuelve verificado. **Criterio:** una página. *Rúbrica:* (a) cómo se genera; (b) cómo se firma y
    dónde vive la clave; (c) cómo se verifica al volver, con `bottom_line`; (d) qué bibliotecas y sus licencias.

---

## 📚 7. Referencias

**Documentación oficial**

- pypdf: https://pypdf.readthedocs.io/en/stable/
- pdfplumber: https://github.com/jsvine/pdfplumber
- pyHanko: https://docs.pyhanko.eu/en/latest/
- ReportLab, la guía de usuario: https://docs.reportlab.com/reportlab/userguide/ch1_intro/

**Orden de lectura sugerido:** el README de pdfplumber, que explica cómo reconstruye las tablas; después la guía de validación de firmas de pyHanko.

---

## 🚀 8. Cierre

Un PDF son instrucciones de dibujo, no un documento con estructura: el texto sale celda por celda, las tablas hay que reconstruirlas, y el OCR es el último recurso,
200 veces más lento. Para firmar, pyHanko; para verificar, `bottom_line`, porque `valid` sigue en `True` con el documento alterado. Y PyMuPDF es la más rápida, con
licencia AGPL.

**La señal de que quedó bien:** *"La verificación de firmas revisa `bottom_line`, la extracción de tablas usa pdfplumber, y nadie usa PyMuPDF sin haber leído su
licencia."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-04 -m "op ar04 cerrada: generar, extraer, firmar, verificar con bottom_line y OCR"
> ```
>
> Los commits llevan su prefijo (`op ar04: …`) y los de ejercicio su número
> (`op ar04 ej07: …`).
