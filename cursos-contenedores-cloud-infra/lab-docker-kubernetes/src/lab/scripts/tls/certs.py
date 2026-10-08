"""La CA del laboratorio y los certificados que firma (Fase 19). Un solo script para macOS, Linux y Windows:
no depende de que haya openssl en la máquina.

    python scripts/tls/certs.py ca                                  la CA (una vez; no la pisa)
    python scripts/tls/certs.py leaf gateway --dns api.localhost,storefront.localhost
    python scripts/tls/certs.py leaf vencido --dns api.localhost --days -1     (incidente 18)
    python scripts/tls/certs.py ca --name otra                      otra CA, que nadie conoce (incidente 19)
    python scripts/tls/certs.py leaf ajeno --dns api.localhost --ca otra

Todo queda en .secrets/tls/ (fuera de git): <nombre>.crt y <nombre>.key. Las claves privadas no salen de ahí
salvo hacia un Secret del cluster.
"""

import argparse
import datetime as dt
import ipaddress
import sys
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID

DIR = Path(__file__).resolve().parents[2] / ".secrets" / "tls"


def write(name: str, cert: x509.Certificate, key: ec.EllipticCurvePrivateKey) -> None:
    DIR.mkdir(parents=True, exist_ok=True)
    (DIR / f"{name}.crt").write_bytes(cert.public_bytes(serialization.Encoding.PEM))
    key_path = DIR / f"{name}.key"
    key_path.write_bytes(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                           serialization.NoEncryption()))
    key_path.chmod(0o600)
    print(f"{DIR / name}.crt · vence {cert.not_valid_after_utc:%Y-%m-%d %H:%M} UTC")


def load(name: str):
    cert = x509.load_pem_x509_certificate((DIR / f"{name}.crt").read_bytes())
    key = serialization.load_pem_private_key((DIR / f"{name}.key").read_bytes(), password=None)
    return cert, key


def make_ca(name: str, force: bool) -> None:
    if (DIR / f"{name}.crt").exists() and not force:
        print(f"{DIR / name}.crt ya existe: no se pisa (--force para reemplazarla, y todo lo que firmó deja de valer)")
        return
    key = ec.generate_private_key(ec.SECP256R1())
    subject = x509.Name([x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Droguerías La Vecina"),
                         x509.NameAttribute(NameOID.COMMON_NAME, "La Rebotica · CA del laboratorio" if name == "ca"
                                            else f"La Rebotica · CA {name}")])
    now = dt.datetime.now(dt.timezone.utc)
    cert = (x509.CertificateBuilder().subject_name(subject).issuer_name(subject)
            .public_key(key.public_key()).serial_number(x509.random_serial_number())
            .not_valid_before(now - dt.timedelta(minutes=5)).not_valid_after(now + dt.timedelta(days=3650))
            # Una CA: puede firmar certificados, y no se usa para nada más.
            .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
            .add_extension(x509.KeyUsage(digital_signature=False, content_commitment=False, key_encipherment=False,
                                         data_encipherment=False, key_agreement=False, key_cert_sign=True,
                                         crl_sign=True, encipher_only=False, decipher_only=False), critical=True)
            .add_extension(x509.SubjectKeyIdentifier.from_public_key(key.public_key()), critical=False)
            .sign(key, hashes.SHA256()))
    write(name, cert, key)


def make_leaf(name: str, dns: list[str], days: float, ca_name: str, client: bool) -> None:
    ca_cert, ca_key = load(ca_name)
    key = ec.generate_private_key(ec.SECP256R1())
    now = dt.datetime.now(dt.timezone.utc)
    # Con días negativos, el certificado ya venció: empezó a valer antes y terminó hace |días|.
    start = now - dt.timedelta(days=30) if days < 0 else now - dt.timedelta(minutes=5)
    sans = [x509.IPAddress(ipaddress.ip_address(d)) if d.replace(".", "").isdigit() else x509.DNSName(d) for d in dns]
    usages = [ExtendedKeyUsageOID.SERVER_AUTH] + ([ExtendedKeyUsageOID.CLIENT_AUTH] if client else [])
    cert = (x509.CertificateBuilder()
            .subject_name(x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, dns[0])]))
            .issuer_name(ca_cert.subject).public_key(key.public_key()).serial_number(x509.random_serial_number())
            .not_valid_before(start).not_valid_after(now + dt.timedelta(days=days))
            # El nombre que valida el cliente está aquí, en el SAN; el CN no cuenta hace años.
            .add_extension(x509.SubjectAlternativeName(sans), critical=False)
            .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
            .add_extension(x509.ExtendedKeyUsage(usages), critical=False)
            .add_extension(x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key()), critical=False)
            .sign(ca_key, hashes.SHA256()))
    write(name, cert, key)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p_ca = sub.add_parser("ca")
    p_ca.add_argument("--name", default="ca")
    p_ca.add_argument("--force", action="store_true")
    p_leaf = sub.add_parser("leaf")
    p_leaf.add_argument("name")
    p_leaf.add_argument("--dns", required=True, help="los nombres del SAN, separados por coma")
    p_leaf.add_argument("--days", type=float, default=90)
    p_leaf.add_argument("--ca", default="ca")
    p_leaf.add_argument("--client", action="store_true", help="también para autenticar clientes (mTLS)")
    args = parser.parse_args()
    if args.cmd == "ca":
        make_ca(args.name, args.force)
    else:
        make_leaf(args.name, args.dns.split(","), args.days, args.ca, args.client)
    return 0


if __name__ == "__main__":
    sys.exit(main())
