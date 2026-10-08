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
