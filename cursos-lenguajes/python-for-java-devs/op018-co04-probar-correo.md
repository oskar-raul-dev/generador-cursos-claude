# 📮 co04 — Probar correo sin mandarlo

> Python para desarrolladores Java senior · **Carta** · Track `co` — Comunicaciones y
> transferencia · sección 4 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las dos pruebas con `pytest`, y el envío a Mailpit v1.31.4 consultado por su API
> (en una red privada de Docker, sin los puertos del `compose.yaml`).

---

## 🎯 1. Qué problema resuelve

El código que manda las liquidaciones a los franquiciados tiene que probarse, y probarlo mandando
correos de verdad es la peor idea posible: un error en la prueba y Édgar recibe la liquidación de otro
franquiciado, o cien copias de la suya. Y sin embargo es el código que **más** necesita prueba: qué
destinatario recibe qué adjunto es exactamente donde están los errores caros.

Hay tres niveles de prueba para el correo, y cada uno atrapa errores distintos:

- **Unitario**: el mensaje se arma bien —asunto, destinatarios, adjunto correcto— sin ningún servidor.
- **Con un servidor SMTP falso en el proceso**: el código conversa SMTP de verdad y el servidor guarda
  lo que recibe, para inspeccionarlo desde la prueba.
- **Con un servidor de pruebas completo en un contenedor** (Mailpit): el correo se ve en una interfaz
  web como lo vería el franquiciado, y la prueba lo consulta por una API.

---

## 🧠 2. El modelo

La regla de diseño que hace posible probar el correo es la misma que hace posible probar cualquier
efecto externo: **separar el armado del envío**. Una función arma el `EmailMessage`; otra, que recibe
el mensaje, lo manda. La prueba unitaria llama a la primera; la de integración reemplaza solo el
servidor de la segunda.

| Nivel | Qué reemplaza | Con qué | Qué atrapa |
|---|---|---|---|
| Unitario | El envío entero | Nada: se inspecciona el mensaje | Destinatario, asunto, adjunto equivocado |
| SMTP en proceso | El servidor | `aiosmtpd` con un manejador que guarda | Errores del diálogo SMTP, `starttls`, codificaciones |
| Contenedor | El servidor y el buzón | Mailpit | Cómo se **ve** el correo; HTML roto; tamaño |

> 📝 **Nota de ecosistema.** El módulo `smtpd` de la biblioteca estándar, que muchos tutoriales usan
> como servidor de depuración, **se eliminó en Python 3.12** (PEP 594). Su reemplazo es `aiosmtpd`
> (1.4.6, del 2024-05-18): publica despacio, pero responde, y el protocolo no cambia. Y el clásico
> MailHog lleva sin versión desde agosto de 2020 (v1.0.1); su sucesor activo es **Mailpit**
> (v1.31.4, del 2026-10-03), con la misma idea y una API para las pruebas.

### Tu instinto de Java dice… y esta vez se equivoca

En Java el reflejo es GreenMail en las pruebas de integración, o un `JavaMailSender` simulado con
Mockito. En Python, simular `smtplib.SMTP` con `unittest.mock.patch` es tentador y casi siempre un
error: la prueba termina verificando que llamaste a `send_message` con algo, no que ese algo sea un
correo correcto. Un servidor SMTP real de diez líneas en el mismo proceso cuesta lo mismo y prueba
mucho más.

---

## 💻 3. El ejemplo que corre

```bash
uv add --dev pytest aiosmtpd
```

El código bajo prueba, `envio.py`, separa armar de mandar:

```python
"""Arma y manda la liquidación: dos funciones, para poder probar cada una."""

import smtplib
from email.message import EmailMessage


def build_settlement(franchise: str, to: str, pdf_name: str, pdf: bytes) -> EmailMessage:
    msg = EmailMessage()
    msg["Subject"] = f"Liquidación de regalías — sede {franchise}"
    msg["From"] = "administracion@aurea.example"
    msg["To"] = to
    msg.set_content(f"Adjuntamos la liquidación de la sede {franchise}.")
    msg.add_attachment(pdf, maintype="application", subtype="pdf", filename=pdf_name)
    return msg


def send(msg: EmailMessage, host: str, port: int) -> None:
    with smtplib.SMTP(host, port, timeout=10) as smtp:
        smtp.send_message(msg)
```

`test_envio.py`, con los dos primeros niveles:

```python
"""Pruebas del correo: unitaria y con un servidor SMTP real dentro del proceso."""

import socket
from email import message_from_bytes, policy

import pytest
from aiosmtpd.controller import Controller

from envio import build_settlement, send


class Mailbox:
    """Manejador de aiosmtpd: guarda cada mensaje recibido en una lista."""

    def __init__(self):
        self.messages = []

    async def handle_DATA(self, server, session, envelope):
        self.messages.append((envelope.rcpt_tos, message_from_bytes(envelope.content, policy=policy.default)))
        return "250 OK"


@pytest.fixture
def smtp_server():
    with socket.socket() as probe:              # un puerto libre, elegido por el sistema
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    mailbox = Mailbox()
    controller = Controller(mailbox, hostname="127.0.0.1", port=port)
    controller.start()
    yield mailbox, port
    controller.stop()


def test_attachment_belongs_to_franchise():
    msg = build_settlement("Suba", "edgar.rojas@franquicias.example", "liquidacion-suba.pdf", b"%PDF")
    [attachment] = list(msg.iter_attachments())
    assert attachment.get_filename() == "liquidacion-suba.pdf"
    assert "Suba" in msg["Subject"]


def test_real_smtp_conversation(smtp_server):
    mailbox, port = smtp_server
    send(build_settlement("Suba", "edgar.rojas@franquicias.example", "liquidacion-suba.pdf", b"%PDF"),
         "127.0.0.1", port)
    [(recipients, received)] = mailbox.messages
    assert recipients == ["edgar.rojas@franquicias.example"]
    # El asunto viajó codificado (=?utf-8?q?...?=) y vuelve con tildes: eso prueba la codificación.
    assert received["Subject"] == "Liquidación de regalías — sede Suba"
    assert [p.get_filename() for p in received.iter_attachments()] == ["liquidacion-suba.pdf"]
```

```bash
pytest -q test_envio.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
..                                                                       [100%]
2 passed in 0.07s
```

### El tercer nivel: Mailpit

`compose.yaml`:

```yaml
services:
  mailpit:
    image: axllent/mailpit:v1.31.4
    ports:
      - "8025:8025"   # interfaz web y API
      - "1025:1025"   # SMTP
```

```bash
docker compose up -d
python3 -c "
from envio import build_settlement, send
send(build_settlement('Suba', 'edgar.rojas@franquicias.example', 'liquidacion-suba.pdf', b'%PDF'), '127.0.0.1', 1025)"
curl -s http://127.0.0.1:8025/api/v1/messages | python3 -m json.tool | head -20
```

El correo aparece en `http://127.0.0.1:8025` tal como lo vería el franquiciado, con el adjunto y el
HTML dibujado, y la API devuelve la lista de mensajes en JSON para que una prueba de punta a punta
la consulte.

**Detalles con intención**

- **El puerto lo elige el sistema** (`bind(("127.0.0.1", 0))`): dos pruebas en paralelo, o un
  servidor que ya usa el 8025, no chocan.
- **El manejador interpreta el mensaje con `policy.default`**, así la prueba compara texto con tildes
  y no la codificación del cable.
- **La prueba unitaria no necesita servidor**, y es la que atrapa el error caro: el adjunto
  equivocado.

---

## ⚠️ 4. Lo que se rompe

**La salida del servidor de depuración que no aparece.** `python -m aiosmtpd -n` imprime cada mensaje
en la salida estándar, pero si la rediriges a un archivo, Python la guarda en un búfer y el archivo
queda vacío hasta que el proceso termina. `python -u -m aiosmtpd …` desactiva el búfer. Lo encontró la
prueba de la sección `co01` del track, con un registro de cero bytes.

**Probar con la configuración de producción a mano.** Una prueba que lee `SMTP_HOST` del entorno y en
tu máquina apunta al servidor real manda correos reales. El servidor de pruebas se pasa **explícito**
desde la prueba, nunca desde una variable que en algún entorno tiene otro valor.

**`starttls` en las pruebas.** El `Controller` de arriba no ofrece TLS, y un código que siempre llama a
`starttls()` falla contra él. O el TLS es configurable (como en `co01`), o el servidor de pruebas se
levanta con un certificado propio (`aiosmtpd` lo permite con `tls_context`).

---

## ⚖️ 5. Cuándo NO usarla

**Mailpit en cada prueba unitaria.** Un contenedor para verificar un asunto es lento y frágil. El
contenedor es para la prueba de punta a punta y para **mirar** el correo durante el desarrollo; las
pruebas de cada cambio van en los dos primeros niveles.

**Simular `smtplib` con `mock`.** Prueba que llamaste a una función, no que el correo esté bien. Solo
tiene sentido para verificar el manejo de un error del servidor que no puedes provocar de otra forma
(y `aiosmtpd` también puede devolver errores).

**Como sustituto de probar la entrega.** Nada de esta sección dice si el correo llega a la bandeja de
Gmail. Eso es infraestructura, y está en `co02`.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Agrega una prueba que falle si el adjunto no contiene el nombre de la sede. **Criterio:** con el PDF
   de otra sede, la prueba falla con un mensaje que nombra los dos.
2. Corre `python -u -m aiosmtpd -n -l 127.0.0.1:8025` y manda un correo con `envio.send`.
   **Criterio:** ves el mensaje entero en la terminal, con el asunto codificado.
3. Haz que el manejador devuelva `"550 buzón inexistente"` para una dirección concreta. **Criterio:**
   `send` lanza `SMTPRecipientsRefused` y la prueba lo verifica.

**🟡 Intermedio (4–6)**

4. Levanta Mailpit y escribe una prueba de punta a punta que mande el correo y lo encuentre por la API.
   **Criterio:** la prueba lee el asunto desde `/api/v1/messages` y lo compara.
5. Busca en la documentación de Mailpit cómo se borran los mensajes por la API y úsalo antes de cada
   prueba. **Criterio:** dos corridas seguidas de la prueba no se ven entre sí.
6. Agrega TLS al servidor de prueba con un certificado autofirmado y prueba la rama `starttls`.
   **Criterio:** la prueba pasa con TLS, y falla si quitas el contexto de verificación del cliente.

**🟠 Difícil (7–9)**

7. Prueba el envío de las seis liquidaciones de una vez: cada franquiciado recibe exactamente un
   correo con exactamente su PDF. **Criterio:** una sola aserción sobre el buzón de prueba cubre las
   seis parejas.
8. Usa la API de Mailpit para comprobar que el HTML del correo no tiene enlaces rotos ni imágenes
   externas. **Criterio:** buscas en su documentación el endpoint de revisión y reportas qué encontró.
9. Mide cuánto tarda la suite con el servidor en proceso contra la misma suite con Mailpit en
   contenedor. **Criterio:** reportas los dos tiempos y decides qué nivel corre en cada cambio y cuál
   antes de una entrega.

**🔴 Muy difícil (10)**

10. Diseña la estrategia de pruebas de todo el correo de Áurea (liquidaciones, recordatorios,
    respuestas de glosas). **Criterio:** una página con qué se prueba en cada nivel y un prototipo de
    cada uno. *Rúbrica:* (a) ninguna prueba puede mandar un correo real, y explicas cómo lo
    garantizas; (b) el error caro —adjunto o destinatario equivocado— tiene prueba unitaria; (c) la
    prueba de punta a punta corre en el CI con Mailpit; (d) dices qué riesgo queda sin cubrir.

---

## 📚 7. Referencias

**Documentación oficial**

- `aiosmtpd`, el `Controller`: https://aiosmtpd.aio-libs.org/en/latest/controller.html
- PEP 594, la eliminación de `smtpd` y otros módulos: https://peps.python.org/pep-0594/
- Mailpit: https://mailpit.axllent.org/
- La API de Mailpit: https://mailpit.axllent.org/docs/api-v1/

**Orden de lectura sugerido:** la página del `Controller` de `aiosmtpd`, que tiene casi exactamente
el patrón de esta sección; después la documentación de Mailpit cuando quieras mirar los correos en
una interfaz.

---

## 🚀 8. Cierre

El correo se prueba como cualquier efecto externo: armado separado del envío, un servidor de verdad en
el proceso para la conversación SMTP, y un buzón de pruebas en un contenedor para ver lo que vería la
persona. Ninguno de los tres manda nada a nadie.

**La señal de que quedó bien:** *"Cambiamos el armado de las liquidaciones y la prueba que mira el
adjunto de cada franquiciado nos avisó antes de que lo hiciera Édgar."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-co-fase-04 -m "op co04 cerrada: correo probado en proceso y con Mailpit"
> ```
>
> Los commits llevan su prefijo (`op co04: …`) y los de ejercicio su número
> (`op co04 ej07: …`).
