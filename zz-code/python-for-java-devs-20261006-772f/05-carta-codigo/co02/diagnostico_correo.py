"""Diagnóstico de entrega: SPF y DMARC de un dominio, y una firma DKIM firmada y verificada."""

import base64

import dkim
import dns.resolver
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa


def txt_records(name: str) -> list[str]:
    try:
        answers = dns.resolver.resolve(name, "TXT")
    except (dns.resolver.NXDOMAIN, dns.resolver.NoAnswer):
        return []
    # Un registro TXT puede venir partido en varias cadenas de 255 bytes: se unen.
    return [b"".join(r.strings).decode() for r in answers]


def mail_policy(domain: str) -> dict[str, str]:
    spf = [r for r in txt_records(domain) if r.startswith("v=spf1")]
    dmarc = [r for r in txt_records(f"_dmarc.{domain}") if r.startswith("v=DMARC1")]
    tags = dict(t.strip().split("=", 1) for t in dmarc[0].split(";") if "=" in t) if dmarc else {}
    return {
        "spf": spf[0] if len(spf) == 1 else f"{len(spf)} registros SPF (debe haber exactamente uno)",
        "dmarc": tags.get("p", "sin DMARC"),
        "subdominios": tags.get("sp", tags.get("p", "—")),
        "reportes": tags.get("rua", "nadie los recibe"),
    }


def dkim_roundtrip() -> tuple[bool, bool]:
    """Firma un mensaje con una clave propia y lo verifica con un DNS simulado."""
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    private_pem = key.private_bytes(serialization.Encoding.PEM,
                                    serialization.PrivateFormat.TraditionalOpenSSL,
                                    serialization.NoEncryption())
    public_der = key.public_key().public_bytes(serialization.Encoding.DER,
                                               serialization.PublicFormat.SubjectPublicKeyInfo)
    # Esto es exactamente lo que se publica en recordatorios._domainkey.aurea.example
    record = b"v=DKIM1; k=rsa; p=" + base64.b64encode(public_der)

    message = (b"From: Recordatorios <citas@aurea.example>\r\n"
               b"To: paciente@correo.example\r\n"
               b"Subject: Recordatorio de cita\r\n\r\n"
               b"Le recordamos su cita de control el martes a las 3:40 p. m.\r\n")
    signature = dkim.sign(message, b"recordatorios", b"aurea.example", private_pem,
                          include_headers=[b"from", b"to", b"subject"])
    signed = signature + message

    def fake_dns(name: bytes, timeout: int = 5) -> bytes:
        return record if name == b"recordatorios._domainkey.aurea.example." else b""

    intact = dkim.verify(signed, dnsfunc=fake_dns)
    tampered = dkim.verify(signed.replace(b"3:40", b"4:40"), dnsfunc=fake_dns)
    return intact, tampered


if __name__ == "__main__":
    for key, value in mail_policy("gmail.com").items():
        print(f"gmail.com  {key:11} {value}")
    print("DKIM íntegro: %s · alterado: %s" % dkim_roundtrip())
