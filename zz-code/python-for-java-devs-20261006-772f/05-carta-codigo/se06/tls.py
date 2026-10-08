"""Una CA interna, un servidor HTTPS y las cuatro formas de llamarlo."""

import datetime as dt
import ssl
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import httpx
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import NameOID

now = dt.datetime.now(dt.UTC)


def name(cn: str) -> x509.Name:
    return x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, cn)])


# ------------------------------------------------- la CA interna de Áurea
ca_key = ec.generate_private_key(ec.SECP256R1())
ca_cert = (x509.CertificateBuilder()
           .subject_name(name("CA interna Aurea")).issuer_name(name("CA interna Aurea"))
           .public_key(ca_key.public_key()).serial_number(x509.random_serial_number())
           .not_valid_before(now).not_valid_after(now + dt.timedelta(days=3650))
           .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
           .add_extension(x509.KeyUsage(digital_signature=False, content_commitment=False,
                                        key_encipherment=False, data_encipherment=False,
                                        key_agreement=False, key_cert_sign=True, crl_sign=True,
                                        encipher_only=False, decipher_only=False), critical=True)
           .add_extension(x509.SubjectKeyIdentifier.from_public_key(ca_key.public_key()), critical=False)
           .sign(ca_key, hashes.SHA256()))

# ------------------------------------------------- el certificado del servidor, firmado por la CA
srv_key = ec.generate_private_key(ec.SECP256R1())
srv_cert = (x509.CertificateBuilder()
            .subject_name(name("localhost")).issuer_name(ca_cert.subject)
            .public_key(srv_key.public_key()).serial_number(x509.random_serial_number())
            .not_valid_before(now).not_valid_after(now + dt.timedelta(days=90))
            .add_extension(x509.SubjectAlternativeName([x509.DNSName("localhost")]), critical=False)
            .add_extension(x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key()),
                           critical=False)
            .sign(ca_key, hashes.SHA256()))

with open("ca.pem", "wb") as f:
    f.write(ca_cert.public_bytes(serialization.Encoding.PEM))
with open("server.pem", "wb") as f:
    f.write(srv_cert.public_bytes(serialization.Encoding.PEM))
    f.write(srv_key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                  serialization.NoEncryption()))


# ------------------------------------------------- el servidor
class Hello(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"cartera ok")

    def log_message(self, *args):
        pass


server = ThreadingHTTPServer(("127.0.0.1", 0), Hello)
server_ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
server_ctx.load_cert_chain("server.pem")
server.socket = server_ctx.wrap_socket(server.socket, server_side=True)
port = server.server_address[1]
threading.Thread(target=server.serve_forever, daemon=True).start()


# ------------------------------------------------- las cuatro llamadas
def call(label: str, url: str, verify) -> None:
    try:
        r = httpx.get(url, verify=verify)
        print(f"{label:<28} {r.status_code} {r.text}")
    except httpx.ConnectError as e:
        reason = str(e).split("certificate verify failed: ")[-1].split(" (_ssl")[0]
        print(f"{label:<28} falla: {reason}")


trust_internal_ca = ssl.create_default_context(cafile="ca.pem")

call("por defecto (certifi)", f"https://localhost:{port}/", True)
call("verify=False", f"https://localhost:{port}/", False)
call("con la CA interna", f"https://localhost:{port}/", trust_internal_ca)
call("CA interna, otro nombre", f"https://127.0.0.1:{port}/", trust_internal_ca)
server.shutdown()
