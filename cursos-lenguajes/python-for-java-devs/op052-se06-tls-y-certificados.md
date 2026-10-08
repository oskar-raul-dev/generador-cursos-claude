# 🔏 se06 — TLS y certificados

> Python para desarrolladores Java senior · **Carta** · Track `se` — Seguridad aplicada y
> criptografía · sección 6 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El servidor interno de Cartera atiende por HTTPS con un certificado que emitió la propia Áurea —una CA interna,
porque `cartera.interno` no es un nombre público y ninguna CA pública lo firmaría—. El primer script en Python
que lo llama falla con `CERTIFICATE_VERIFY_FAILED`. Y la respuesta que aparece primero en cualquier búsqueda es
`verify=False`.

Funciona. Y desde ese momento el script le manda la contraseña de Cartera a cualquiera que se ponga en medio:
el cifrado sigue ahí, pero ya no sabe **con quién** está cifrando. Esta sección es la alternativa correcta, que
es una línea más larga: decirle al cliente en qué CA confiar.

Viene con dos casos vecinos que este perfil va a encontrar: el proxy corporativo que intercepta TLS con su propia
CA (y que rompe `pip`, `uv` y cada script), y el TLS mutuo, en el que el servidor también exige un certificado
al cliente.

---

## 🧠 2. El modelo

Verificar un certificado son dos comprobaciones distintas, y fallan por separado:

| Comprobación | Pregunta | El error cuando falla |
|---|---|---|
| **Cadena** | ¿Lo firmó una CA en la que confío? | `unable to get local issuer certificate` |
| **Nombre** | ¿Es para el nombre al que me conecté? | `Hostname mismatch` (o `IP address mismatch`) |

`verify=False` apaga las dos. La corrección apaga ninguna: agrega la CA interna a las CA en las que se confía.

**De dónde saca Python sus CA**, que es lo que confunde a quien viene de Java:

| Cliente | Almacén de confianza por defecto |
|---|---|
| `ssl` de la biblioteca estándar | El del sistema operativo (OpenSSL), con matices por plataforma |
| `httpx` y `requests` | **`certifi`**: una copia de las CA de Mozilla dentro del paquete, que ignora el sistema |
| Con `truststore` | El del sistema operativo, incluido el llavero de macOS y el almacén de Windows |

### Tu instinto de Java dice… y esta vez se equivoca

En Java hay un `cacerts` por JDK, y se agrega la CA con `keytool -importcert`. El instinto busca el `cacerts` de
Python y no lo encuentra, porque `httpx` usa `certifi` y `certifi` es un archivo dentro de un paquete: editarlo
funciona hasta la próxima actualización del paquete. La CA se pasa en el código —un `SSLContext` con
`cafile`— o se usa `truststore` para que valga la del sistema.

---

## 💻 3. El ejemplo que corre

El ejemplo crea una CA interna y un certificado de servidor con `cryptography`, levanta un servidor HTTPS en el
mismo proceso, y lo llama de cuatro formas.

```bash
uv add httpx cryptography
```

`tls.py`:

```python
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
```

```bash
python3 tls.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
por defecto (certifi)        falla: unable to get local issuer certificate
verify=False                 200 cartera ok
con la CA interna            200 cartera ok
CA interna, otro nombre      falla: IP address mismatch, certificate is not valid for '127.0.0.1'.
```

La primera falla es la que lleva a `verify=False`. La segunda línea "funciona" igual que la tercera, y por eso
`verify=False` sobrevive en producción: desde afuera no se distinguen. La cuarta es la comprobación de nombre
haciendo su trabajo: el certificado es para `localhost`, no para `127.0.0.1`, aunque sea la misma máquina.

**Detalles con intención**

- **`ssl.create_default_context(cafile=…)`** confía **solo** en esa CA —para un cliente que solo habla con
  servicios internos, es lo que se quiere—. Para confiar en las públicas y además en la interna, se crea el
  contexto por defecto y se llama a `load_verify_locations("ca.pem")`.
- **El nombre va en el SAN** (`SubjectAlternativeName`), no en el `CN`. Los clientes modernos ignoran el `CN`
  para verificar el nombre.
- **`path_length=0`** en la CA: puede firmar certificados de servidor, pero no otras CA. Una CA interna sin esa
  restricción, si se filtra su clave, permite fabricar CA intermedias.
- **`KeyUsage`, `SubjectKeyIdentifier` y `AuthorityKeyIdentifier`** no son adorno: desde Python 3.13,
  `create_default_context()` activa `VERIFY_X509_STRICT`, y un certificado sin el identificador de la clave
  de su emisor se rechaza con `Missing Authority Key Identifier`. La primera versión de este ejemplo no los
  tenía y falló exactamente así.
- **El certificado del servidor dura 90 días**, y la CA diez años. La CA se guarda fuera de línea; los
  certificados se renuevan con un proceso automático, no con un recordatorio.

---

## ⚠️ 4. Lo que se rompe

**El proxy corporativo.** En algunas redes, un equipo intermedio abre el TLS y lo vuelve a cifrar con la CA de
la empresa, que está instalada en el sistema operativo. El navegador funciona; `pip`, `uv` y `httpx` fallan,
porque usan `certifi` y no el sistema. La salida no es `verify=False` ni `--trusted-host`, sino `truststore`
(`truststore.inject_into_ssl()` al arrancar) o la variable `SSL_CERT_FILE` apuntando a un archivo con la CA del
proxy. `uv` tiene su propia opción: `--native-tls`.

**La CA vieja que deja de servir al actualizar Python.** Una CA interna hecha hace años con un script de
OpenSSL mínimo funcionaba con Python 3.12 y falla con 3.13 o posterior por `VERIFY_X509_STRICT` (§3). La
tentación es quitar el modo estricto (`ctx.verify_flags &= ~ssl.VERIFY_X509_STRICT`); la corrección es volver a
emitir los certificados con las extensiones que exige el RFC 5280. Lo primero es aceptable como puente de días,
con fecha de retiro escrita.

**`verify=False` "solo en desarrollo".** Llega a producción por una variable de configuración que nadie cambió.
Si hace falta en desarrollo, la CA de desarrollo se pasa igual que la interna.

**La cadena incompleta.** El servidor manda su certificado pero no el intermedio, y los navegadores lo resuelven
solos (descargando el intermedio) mientras Python falla. Se arregla en el servidor, mandando la cadena completa,
no en el cliente.

**El certificado que vence un domingo.** El certificado de Cartera dura 90 días y nadie lo renovó. La alerta que
corresponde es la de `au06`/`ob03`: un chequeo diario que avisa a 15 días del vencimiento, no el día en que falla.

---

## ⚖️ 5. Cuándo NO usarlo

**Una CA interna propia, si basta con un nombre público.** Si `cartera.aurea.com.co` puede tener DNS público,
Let's Encrypt emite certificados gratuitos y automáticos que todo cliente reconoce, sin distribuir ninguna CA.
La CA interna se justifica para nombres que no pueden ser públicos.

**TLS mutuo, entre dos servicios de un mismo servidor.** El TLS mutuo prueba la identidad del cliente con un
certificado, y su costo es emitir, distribuir y renovar certificados de cliente. Entre servicios que corren en la
misma máquina o la misma red privada, un token por servicio (`se03`) da la misma garantía práctica con mucho
menos que operar.

**Implementar TLS a mano.** El proceso Python no termina el TLS de cara a internet: eso lo hace el proxy inverso
(Caddy, nginx), que renueva los certificados solo.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Cambia el SAN a `cartera.interno` y conéctate a `localhost`. **Criterio:** reportas el error exacto y por qué.
2. Confía en las CA públicas **y** en la interna con `load_verify_locations`. **Criterio:** el mismo contexto
   llama al servidor interno y a `https://pypi.org`.
3. Mira dónde está el archivo de `certifi` en tu entorno (`python -m certifi`). **Criterio:** la ruta, y cuántas
   CA tiene.

**🟡 Intermedio (4–6)**

4. Activa el TLS mutuo: el servidor exige certificado de cliente (`verify_mode = ssl.CERT_REQUIRED`).
   **Criterio:** sin certificado de cliente la conexión falla; con uno firmado por la CA interna, funciona.
5. Escribe el chequeo de vencimiento: conecta, lee el certificado y avisa si vence en menos de 15 días.
   **Criterio:** con un certificado de 10 días, el aviso sale.
6. Usa `truststore` con la CA interna instalada en el almacén de tu sistema. **Criterio:** `httpx` la acepta sin
   `cafile` en el código.

**🟠 Difícil (7–9)**

7. Arma un servidor que mande solo el certificado hoja, sin el intermedio, con una CA de dos niveles.
   **Criterio:** reproduces el fallo y lo arreglas en el servidor.
8. Pon Caddy delante de un servicio Python en un contenedor (sin puertos por defecto), con su CA interna
   automática. **Criterio:** el cliente confía en la CA de Caddy y el servicio Python no ve TLS.
9. Busca `verify=False` y `CERT_NONE` en un proyecto tuyo con `bandit` (`se07`). **Criterio:** la lista de
   apariciones y la corrección de cada una.

**🔴 Muy difícil (10)**

10. Diseña el TLS de los servicios internos de Áurea. **Criterio:** una página. *Rúbrica:* (a) nombres públicos o
    CA interna, con su razón; (b) cómo se renuevan los certificados y quién se entera si falla la renovación;
    (c) cómo llega la CA a cada cliente, incluidas las máquinas de las sedes; (d) dónde hay TLS mutuo y dónde no.

---

## 📚 7. Referencias

**Documentación oficial**

- `ssl`, consideraciones de seguridad: https://docs.python.org/3/library/ssl.html#security-considerations
- `httpx`, SSL: https://www.python-httpx.org/advanced/ssl/
- `truststore`: https://truststore.readthedocs.io/en/latest/
- `cryptography`, tutorial de X.509: https://cryptography.io/en/latest/x509/tutorial/

**Libro**

- Ivan Ristić, *Bulletproof TLS and PKI*, 2.ª ed. (Feisty Duck, 2022).

**Orden de lectura sugerido:** la página de SSL de `httpx`, que tiene los casos prácticos; después el tutorial de
X.509 de `cryptography`.

---

## 🚀 8. Cierre

`verify=False` no se distingue desde afuera de una conexión verificada, y por eso sobrevive. La alternativa es una
línea: un contexto que confía en la CA interna. El certificado se verifica por cadena y por nombre, el nombre va en
el SAN, y el vencimiento se vigila con quince días de margen.

**La señal de que quedó bien:** *"Buscamos `verify=False` en todos los repositorios de Áurea y no apareció."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-se-fase-06 -m "op se06 cerrada: CA interna, verificación por cadena y por nombre"
> ```
>
> Los commits llevan su prefijo (`op se06: …`) y los de ejercicio su número
> (`op se06 ej07: …`).
