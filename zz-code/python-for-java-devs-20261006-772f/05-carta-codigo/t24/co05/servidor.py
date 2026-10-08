"""Servidor FTPS de prueba (T24): una CA propia, un certificado para ftps.aseguradora.example y tres archivos."""
import datetime as dt, pathlib, ipaddress
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import NameOID
from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import TLS_FTPHandler
from pyftpdlib.servers import FTPServer

now = dt.datetime.now(dt.UTC)
def name(cn): return x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, cn)])
ca_key = ec.generate_private_key(ec.SECP256R1())
ca = (x509.CertificateBuilder().subject_name(name("CA de prueba")).issuer_name(name("CA de prueba"))
      .public_key(ca_key.public_key()).serial_number(1).not_valid_before(now).not_valid_after(now + dt.timedelta(days=1))
      .add_extension(x509.BasicConstraints(ca=True, path_length=None), critical=True)
      .add_extension(x509.KeyUsage(True, False, False, False, False, True, True, False, False), critical=True)
      .add_extension(x509.SubjectKeyIdentifier.from_public_key(ca_key.public_key()), critical=False)
      .sign(ca_key, hashes.SHA256()))
key = ec.generate_private_key(ec.SECP256R1())
cert = (x509.CertificateBuilder().subject_name(name("ftps.aseguradora.example")).issuer_name(ca.subject)
        .public_key(key.public_key()).serial_number(2).not_valid_before(now).not_valid_after(now + dt.timedelta(days=1))
        .add_extension(x509.SubjectAlternativeName([x509.DNSName("ftps.aseguradora.example")]), critical=False)
        .add_extension(x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key()), critical=False)
        .add_extension(x509.ExtendedKeyUsage([x509.oid.ExtendedKeyUsageOID.SERVER_AUTH]), critical=False)
        .sign(ca_key, hashes.SHA256()))
pathlib.Path("/w/ca.pem").write_bytes(ca.public_bytes(serialization.Encoding.PEM))
pathlib.Path("/tmp/srv.pem").write_bytes(cert.public_bytes(serialization.Encoding.PEM) + key.private_bytes(
    serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
home = pathlib.Path("/srv/ftp"); (home / "salida/aurea").mkdir(parents=True, exist_ok=True)
for n, size in (("pagos-20261006.csv", 2048), ("pagos-20261007.csv", 4096), ("glosas-2026-09.zip", 10240)):
    (home / "salida/aurea" / n).write_bytes(b"x" * size)
auth = DummyAuthorizer(); auth.add_user("aurea", "…", str(home), perm="elr")
TLS_FTPHandler.certfile = "/tmp/srv.pem"; TLS_FTPHandler.authorizer = auth
TLS_FTPHandler.tls_control_required = TLS_FTPHandler.tls_data_required = True    # sin prot_p(), los datos se rechazan
TLS_FTPHandler.passive_ports = range(30000, 30010)
FTPServer(("0.0.0.0", 21), TLS_FTPHandler).serve_forever()
