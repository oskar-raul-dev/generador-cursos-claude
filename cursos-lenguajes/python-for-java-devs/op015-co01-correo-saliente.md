# 📮 co01 — Correo saliente

> Python para desarrolladores Java senior · **Carta** · Track `co` — Comunicaciones y
> transferencia · sección 1 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Cada trimestre, Patricia manda a los seis franquiciados su liquidación de regalías: un PDF por
franquiciado, con un correo que explica el total, la fecha de pago y a quién escribir si algo no
cuadra. Lo hace desde su buzón, uno por uno, adjuntando a mano. Un trimestre le mandó a Édgar el PDF
de otro franquiciado, y esa conversación todavía se recuerda.

Mandar correo desde un programa parece un problema resuelto en cinco líneas, y lo es para un texto
plano a una dirección. Para **este** correo hacen falta tres cosas que esas cinco líneas no tienen:

- Un **mensaje bien formado**: versión HTML y versión de texto plano en el mismo correo, un adjunto
  con su tipo y su nombre, tildes en el asunto, y los encabezados (`Date`, `Message-ID`) que los
  filtros de correo no deseado miran primero.
- Una **conexión segura** al servidor de envío, con autenticación, sin mandar la contraseña en claro.
- La certeza de que **cada franquiciado recibe su PDF y solo el suyo**, que es un problema de
  diseño del programa y no del protocolo.

La biblioteca estándar resuelve las dos primeras con `email` y `smtplib`. La tercera es tuya.

---

## 🧠 2. El modelo

Un correo es un **documento MIME**: un árbol de partes, cada una con su tipo. El de la liquidación
tiene esta forma:

```text
multipart/mixed
├── multipart/alternative
│   ├── text/plain        lo que ve un cliente sin HTML (y lo que lee un filtro)
│   └── text/html         lo que ve casi todo el mundo
└── application/pdf       liquidacion-suba-2026T3.pdf
```

La API moderna de Python —`email.message.EmailMessage`, que existe desde 3.6 y es la que se usa—
arma ese árbol sola: `set_content` pone el texto plano, `add_alternative` agrega el HTML y
`add_attachment` agrega el PDF, y el tipo `multipart/mixed` aparece cuando hace falta.

El envío es otra cosa. **SMTP** es un diálogo con un servidor de envío (el de Google Workspace, el de
Microsoft 365, o un servicio de envío como Amazon SES o Postmark): te conectas, te autenticas, le
pasas el mensaje y él se encarga de entregarlo. Dos modos de seguridad, según el puerto:

| Puerto | Modo | En Python |
|---|---|---|
| 587 | Conexión en claro que se convierte en cifrada con `STARTTLS` | `smtplib.SMTP` + `starttls()` |
| 465 | Cifrada desde el primer byte (TLS implícito) | `smtplib.SMTP_SSL` |
| 25 | Entre servidores; casi siempre bloqueado para clientes | No se usa desde una aplicación |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, JavaMail (hoy Jakarta Mail) es una API pesada —`Session`, `Properties`, `MimeMultipart`,
`MimeBodyPart`— y el reflejo es buscar en Python una biblioteca que la esconda. `yagmail` (0.16.0) es
la más conocida, y para Gmail con dos líneas es cómoda. Pero la API moderna de `email` de la
biblioteca estándar **ya es la versión cómoda**: tres métodos arman el árbol MIME, y `smtplib` lo
manda. Antes de agregar una dependencia, vale la pena ver lo corto que queda sin ella.

---

## 💻 3. El ejemplo que corre

Sin dependencias. `liquidaciones.py`:

```python
"""Manda a cada franquiciado su liquidación trimestral: HTML, texto plano y su PDF, y solo el suyo."""

import os
import smtplib
import ssl
import unicodedata
from dataclasses import dataclass
from email.message import EmailMessage
from email.utils import formataddr, formatdate, make_msgid
from pathlib import Path

SENDER = formataddr(("Áurea · Administración", "administracion@aurea.example"))


@dataclass(frozen=True)
class Settlement:
    franchise: str
    franchisee: str
    email: str
    total: str
    pdf: Path


def build_message(item: Settlement, quarter: str) -> EmailMessage:
    msg = EmailMessage()
    msg["Subject"] = f"Liquidación de regalías {quarter} — sede {item.franchise}"
    msg["From"] = SENDER
    msg["To"] = formataddr((item.franchisee, item.email))
    msg["Reply-To"] = "cartera@aurea.example"
    msg["Message-ID"] = make_msgid(domain="aurea.example")
    # smtplib no agrega Date; sin él, el servidor lo pone a su manera y algunos filtros lo penalizan.
    msg["Date"] = formatdate(localtime=True)

    text = (f"Hola, {item.franchisee}:\n\n"
            f"Adjuntamos la liquidación de regalías de la sede {item.franchise} del {quarter}.\n"
            f"Total: {item.total}. Si algo no cuadra, responde a este correo.\n\n— Patricia")
    msg.set_content(text)
    msg.add_alternative(
        f"<p>Hola, {item.franchisee}:</p>"
        f"<p>Adjuntamos la liquidación de regalías de la sede <b>{item.franchise}</b> del {quarter}.</p>"
        f"<p>Total: <b>{item.total}</b>. Si algo no cuadra, responde a este correo.</p><p>— Patricia</p>",
        subtype="html",
    )
    msg.add_attachment(item.pdf.read_bytes(), maintype="application", subtype="pdf",
                       filename=item.pdf.name)
    return msg


def ascii_slug(text: str) -> str:
    # "Zipaquirá" y "zipaquira" tienen que coincidir: los nombres de archivo no llevan tildes.
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()


def check_attachment(item: Settlement) -> None:
    # La regla que evita el error del trimestre pasado: el PDF tiene que ser de esta sede.
    if ascii_slug(item.franchise) not in ascii_slug(item.pdf.name):
        raise ValueError(f"el PDF {item.pdf.name} no parece de la sede {item.franchise}")


def send_all(items: list[Settlement], quarter: str) -> None:
    host, port = os.environ["SMTP_HOST"], int(os.environ.get("SMTP_PORT", "587"))
    for item in items:
        check_attachment(item)  # todos se validan antes de mandar el primero
    with smtplib.SMTP(host, port, timeout=30) as smtp:
        if os.environ.get("SMTP_TLS", "1") == "1":
            smtp.starttls(context=ssl.create_default_context())  # verifica el certificado
        if user := os.environ.get("SMTP_USER"):
            smtp.login(user, os.environ["SMTP_PASSWORD"])
        for item in items:
            refused = smtp.send_message(build_message(item, quarter))
            print(f"{item.franchise}: {'rechazado ' + str(refused) if refused else 'aceptado por el servidor'}")


if __name__ == "__main__":
    Path("liquidacion-suba-2026T3.pdf").write_bytes(b"%PDF-1.4\n% Suba\n")
    Path("liquidacion-zipaquira-2026T3.pdf").write_bytes(b"%PDF-1.4\n% Zipaquira\n")
    items = [
        Settlement("Suba", "Édgar Rojas", "edgar.rojas@franquicias.example", "$ 18.420.000",
                   Path("liquidacion-suba-2026T3.pdf")),
        Settlement("Zipaquirá", "equipo de Zipaquirá", "sede.zipaquira@franquicias.example",
                   "$ 11.075.500", Path("liquidacion-zipaquira-2026T3.pdf")),
    ]
    msg = build_message(items[0], "tercer trimestre de 2026")
    print(msg["Subject"])
    print([part.get_content_type() for part in msg.walk()])
    send_all(items, "tercer trimestre de 2026")
```

Para probarlo sin mandar nada a nadie, un servidor SMTP de mentira que imprime lo que recibe
(la sección `co04` del track lo trata a fondo):

```bash
uv run --with aiosmtpd python -m aiosmtpd -n -l 127.0.0.1:8025 &
SMTP_HOST=127.0.0.1 SMTP_PORT=8025 SMTP_TLS=0 python3 liquidaciones.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
Liquidación de regalías tercer trimestre de 2026 — sede Suba
['multipart/mixed', 'multipart/alternative', 'text/plain', 'text/html', 'application/pdf']
Suba: aceptado por el servidor
Zipaquirá: aceptado por el servidor
```

La segunda línea es el árbol MIME de la §2, tal como lo armó `EmailMessage`. Y **"aceptado por el
servidor" no es "entregado"**: es que el servidor de envío lo tomó. Si llega a la bandeja, a correo no
deseado o a ningún lado es el tema de `co02`.

**Detalles con intención**

- **`formataddr`** escribe `"Édgar Rojas" <edgar…>` con la codificación correcta para el nombre con
  tilde; armarlo con un f-string funciona hasta el primer nombre con coma o tilde.
- **`ascii_slug` antes de comparar.** Sin él, "Zipaquirá" nunca coincide con
  `liquidacion-zipaquira-…pdf` y el programa se niega a mandar un correo correcto.
- **Todos los adjuntos se validan antes de mandar el primer correo.** Si el cuarto está mal, no se
  mandaron tres y quedó uno a medias.
- **`ssl.create_default_context()`** verifica el certificado del servidor. `starttls()` sin contexto
  también cifra, pero sin verificar con quién hablas.
- **`send_message` devuelve los destinatarios rechazados**, no lanza por ellos: un diccionario vacío
  es éxito, y hay que mirarlo.

---

## ⚠️ 4. Lo que se rompe

**El HTML sin versión de texto.** Un correo solo HTML funciona en casi todos los clientes y suma
puntos en los filtros de correo no deseado. `set_content` con el texto plano primero y
`add_alternative` después es el orden correcto: el cliente muestra la **última** alternativa que sabe
dibujar.

**El CSS que el cliente de correo ignora.** Gmail y Outlook ignoran buena parte de las hojas de
estilo en `<style>`. Para un correo con diseño, el CSS se pasa a atributos `style` en cada elemento;
`premailer` (3.10.0) lo hace, y lleva desde 2021 sin versión: está quieto, y el problema que resuelve
casi no cambia.

**La contraseña de la cuenta personal.** Google y Microsoft ya no aceptan la contraseña de la cuenta
para SMTP en casi ningún caso: piden una contraseña de aplicación o OAuth. La cuenta de envío de un
programa es una cuenta de servicio, no el buzón de Patricia.

**Mandar cien correos en una conexión, o cien conexiones.** Los servidores limitan mensajes por
conexión y conexiones por minuto. Para seis franquiciados no importa; para los recordatorios de citas
de toda la red, sí, y el límite está en la documentación del servidor de envío.

---

## ⚖️ 5. Cuándo NO usarla

**Para volumen o correo transaccional crítico.** Recordatorios de citas a miles de pacientes, avisos
de pago: eso va por un **servicio de envío** con API (Amazon SES, Postmark, SendGrid y similares), que
resuelve reputación, rebotes y métricas. El SMTP propio es para el volumen de una oficina.

**Cuando la persona tiene que firmar o acusar recibo con valor legal.** Un correo no prueba que se
leyó. Para notificaciones con efecto legal hay servicios de correo certificado, y la liquidación de
un franquiciado que la discute cada trimestre podría merecerlo.

**Cuando `yagmail` basta.** Para un script personal con una cuenta de Gmail, `yagmail` lo hace en dos
líneas y maneja OAuth. Para un proceso de la empresa con su propio servidor de envío, la biblioteca
estándar alcanza y no agrega nada que mantener.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Cambia el PDF de Zipaquirá por el de Suba en la lista. **Criterio:** el programa no manda **ningún**
   correo y el error nombra el archivo y la sede.
2. Guarda cada mensaje como `.eml` (`msg.as_bytes()`) en vez de mandarlo y ábrelo con tu cliente de
   correo. **Criterio:** ves el HTML, el adjunto y las tildes del asunto bien.
3. Agrega copia oculta a `cartera@aurea.example` sin que aparezca en los encabezados.
   **Criterio:** explicas por qué `Bcc` no va en el mensaje sino en `to_addrs` de `send_message`.

**🟡 Intermedio (4–6)**

4. Busca en la documentación de `email` cómo se agrega una imagen en línea (el logo de Áurea) que el
   HTML referencie con `cid:`. **Criterio:** el logo se ve en el cuerpo, no como adjunto.
5. Cambia a `SMTP_SSL` en el puerto 465. **Criterio:** el código elige el modo por el puerto y explicas
   qué pasa si usas `starttls()` contra el 465.
6. Arma el HTML con una plantilla Jinja2 con autoescape, y pon en el nombre del franquiciado
   `<b>Édgar</b>`. **Criterio:** el correo muestra las etiquetas como texto, no en negrita.

**🟠 Difícil (7–9)**

7. Haz el envío idempotente: si el programa se cae después de mandar tres de seis, al relanzarlo no
   vuelve a mandar los tres. **Criterio:** el registro de lo mandado usa el `Message-ID` y sobrevive a
   un reinicio.
8. Mide el tamaño del correo con un PDF de 3 MB y explica por qué crece. **Criterio:** reportas el
   tamaño del `.eml` y el factor respecto del PDF, y nombras la codificación responsable.
9. Prueba el programa con un servidor que rechaza un destinatario. **Criterio:** el rechazo aparece en
   la salida con el código SMTP, y los demás se mandan.

**🔴 Muy difícil (10)**

10. Diseña el envío trimestral completo como un proceso que Patricia lanza y revisa. **Criterio:** un
    documento de una página y un prototipo. *Rúbrica:* (a) una vista previa de los seis correos antes
    de mandar, que Patricia aprueba; (b) ningún franquiciado puede recibir un PDF ajeno, demostrado con
    una prueba; (c) un registro de qué se mandó, cuándo y con qué `Message-ID`; (d) dices qué haría
    falta para que el acuse de recibo tuviera valor ante una discusión de Édgar.

---

## 📚 7. Referencias

**Documentación oficial**

- `email.message.EmailMessage` y sus métodos de contenido:
  https://docs.python.org/3/library/email.message.html
- Ejemplos del paquete `email`: https://docs.python.org/3/library/email.examples.html
- `smtplib`: https://docs.python.org/3/library/smtplib.html
- `aiosmtpd`, para probar: https://aiosmtpd.aio-libs.org/en/latest/

**Orden de lectura sugerido:** los ejemplos del paquete `email` primero —son cortos y tienen el caso
de HTML con alternativa—; después `EmailMessage`; y `smtplib` solo para `starttls` y el manejo de
errores.

---

## 🚀 8. Cierre

Mandar correo desde Python es armar un árbol MIME con tres métodos y conversar con un servidor con
cuatro. Lo que convierte ese envío en algo confiable está fuera del protocolo: validar todo antes de
mandar lo primero, y que cada persona reciba lo suyo.

**La señal de que quedó bien:** *"Los seis franquiciados recibieron su liquidación, cada uno la suya,
y Patricia no adjuntó nada a mano."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-co-fase-01 -m "op co01 cerrada: liquidaciones por correo con EmailMessage y smtplib"
> ```
>
> Los commits llevan su prefijo (`op co01: …`) y los de ejercicio su número
> (`op co01 ej07: …`).
