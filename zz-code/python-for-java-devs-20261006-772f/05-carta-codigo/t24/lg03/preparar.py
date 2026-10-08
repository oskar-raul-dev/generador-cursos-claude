"""Prepara la prueba de firmar_pdf.py: un certificado de prueba en .p12 y un PDF de una página."""
import datetime as dt
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import NameOID
from pypdf import PdfWriter

key = ec.generate_private_key(ec.SECP256R1())
name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Firmante de prueba")])
now = dt.datetime.now(dt.UTC)
cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(key.public_key())
        .serial_number(x509.random_serial_number()).not_valid_before(now).not_valid_after(now + dt.timedelta(days=30))
        .sign(key, hashes.SHA256()))
with open("firmante.p12", "wb") as f:
    f.write(pkcs12.serialize_key_and_certificates(b"firmante", key, cert, None,
                                                  serialization.BestAvailableEncryption(b"cambia-esto")))
w = PdfWriter(); w.add_blank_page(595, 842)
with open("plan-de-tratamiento.pdf", "wb") as f:
    w.write(f)
