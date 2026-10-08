"""Firma y verifica un XML (XMLDSig) y un PDF (PAdES) con un certificado de prueba."""

import datetime as dt
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID
from lxml import etree
from signxml import XMLSigner, XMLVerifier


def test_certificate(common_name: str) -> tuple[bytes, bytes]:
    """Clave y certificado autofirmado en PEM. Solo para pruebas: ninguna CA lo respalda."""
    key = rsa.generate_private_key(public_exponent=65537, key_size=3072)
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, common_name)])
    now = dt.datetime.now(dt.UTC)
    cert = (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(name)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now)
        .not_valid_after(now + dt.timedelta(days=30))
        .sign(key, hashes.SHA256())
    )
    key_pem = key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    )
    return key_pem, cert.public_bytes(serialization.Encoding.PEM)


def sign_xml(path: Path, key_pem: bytes, cert_pem: bytes) -> bytes:
    root = etree.parse(str(path)).getroot()
    # Firma envolvente con SHA-256: la firma queda dentro del documento que firma.
    signer = XMLSigner(signature_algorithm="rsa-sha256", digest_algorithm="sha256")
    signed = signer.sign(root, key=key_pem, cert=cert_pem)
    return etree.tostring(signed, xml_declaration=True, encoding="UTF-8")


def verify_xml(signed: bytes, cert_pem: bytes) -> etree._Element:
    # Se verifica contra el certificado esperado, no contra el que trae el documento:
    # un atacante también puede adjuntar un certificado.
    result = XMLVerifier().verify(signed, x509_cert=cert_pem)
    return result.signed_xml  # lo que de verdad está firmado: lee de aquí, no del original


if __name__ == "__main__":
    key_pem, cert_pem = test_certificate("Aurea pruebas de firma")
    signed = sign_xml(Path("factura.xml"), key_pem, cert_pem)
    Path("factura-firmada.xml").write_bytes(signed)
    verified = verify_xml(signed, cert_pem)
    print("firma válida; raíz firmada:", etree.QName(verified).localname)

    tampered = signed.replace(b"185000.00", b"18500.00")
    try:
        verify_xml(tampered, cert_pem)
    except Exception as error:  # signxml lanza InvalidDigest o InvalidSignature
        print("alterada:", type(error).__name__)
