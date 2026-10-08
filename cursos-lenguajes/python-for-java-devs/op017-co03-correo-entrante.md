# 📮 co03 — Correo entrante

> Python para desarrolladores Java senior · **Carta** · Track `co` — Comunicaciones y
> transferencia · sección 3 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: el saneamiento, y el procesamiento del buzón contra un servidor GreenMail 2.1.14 de
> pruebas (dos mensajes a "Procesados", uno a "Revisar").

---

## 🎯 1. Qué problema resuelve

El buzón `cartera@aurea.example` recibe cada semana las respuestas de las aseguradoras: la relación
de glosas en una hoja de cálculo, la circular de cambios en un PDF, el soporte de pago en otro. Hoy
alguien abre cada correo, descarga los adjuntos, los renombra y los deja en una carpeta compartida.
Algunos se quedan sin abrir, y una glosa sin abrir es una glosa que vence.

El buzón **ya es una cola de trabajo**: los mensajes llegan en orden, tienen un identificador y se
pueden mover de carpeta cuando se procesan. Lo que hace falta es un programa que lo trate así:
conectarse por IMAP, tomar los mensajes nuevos de remitentes conocidos, guardar sus adjuntos con
nombres seguros, y moverlos a "Procesados" solo cuando todo salió bien.

Y una advertencia que hace a esta sección distinta de un tutorial: **el correo entrante es entrada no
confiable**. Cualquiera puede mandar un correo a `cartera@` con un adjunto llamado
`../../.bashrc`, un `.pdf.exe`, o un zip de cuarenta kilobytes que se expande a cuarenta gigabytes.

---

## 🧠 2. El modelo

Tres capas, y cada una con su biblioteca:

| Capa | Qué hace | Con qué |
|---|---|---|
| **Transporte** | Conectarse al buzón, buscar, descargar, mover | `imaplib` de la biblioteca estándar, o `imap-tools` (1.15.0) encima |
| **Interpretación** | Convertir los bytes en un árbol MIME con encabezados decodificados | `email` con `policy.default` |
| **Saneamiento** | Decidir qué adjuntos se aceptan y con qué nombre se guardan | Código tuyo, y una lista de permitidos |

**IMAP deja los mensajes en el servidor**, a diferencia de POP3, que los descarga y suele borrarlos.
Para un buzón que comparten personas y programa, IMAP es el que corresponde: la persona sigue viendo
los correos, y el programa los mueve a una carpeta cuando terminó con ellos.

**El `UID` es la identidad del mensaje en la carpeta**, estable entre sesiones. El número de
secuencia, en cambio, cambia cuando se borra o se mueve otro mensaje, y es la fuente clásica de
procesar el mensaje equivocado.

### Tu instinto de Java dice… y esta vez se equivoca

En Java, Jakarta Mail con `Folder` y `Message` es la forma de leer un buzón, y la API trae los
encabezados ya decodificados. En Python, `imaplib` es un cliente IMAP **literal**: le mandas comandos
y te devuelve tuplas de bytes que hay que interpretar. El reflejo es concluir que hay que escribir el
cliente; no hace falta: `imap-tools` es la capa cómoda, y `email.message_from_bytes(..., policy=default)`
devuelve un `EmailMessage` con los encabezados ya decodificados, incluido el asunto con tildes que en
el cable viaja como `=?utf-8?q?Liquidaci=C3=B3n?=`.

---

## 💻 3. El ejemplo que corre

```bash
uv add imap-tools
```

`buzon_cartera.py` separa el transporte (IMAP) del saneamiento (que se prueba sin servidor):

```python
"""Procesa el buzón de cartera: adjuntos de aseguradoras conocidas, guardados con nombres seguros."""

import hashlib
import re
import unicodedata
from email import message_from_bytes, policy
from email.message import EmailMessage
from email.utils import parseaddr
from pathlib import Path

KNOWN_SENDERS = {"glosas@prepagada.example", "cartera@aseguradora.example"}
ALLOWED = {".pdf": b"%PDF-", ".xlsx": b"PK\x03\x04", ".csv": None}
MAX_BYTES = 15 * 1024 * 1024
INBOX_DIR = Path("entrantes")


class Rejected(Exception):
    pass


def safe_name(raw: str | None) -> str:
    """Nombre de archivo seguro: sin rutas, sin caracteres raros, con una sola extensión."""
    if not raw:
        raise Rejected("adjunto sin nombre")
    name = Path(raw.replace("\\", "/")).name                 # fuera ../ y rutas de Windows
    name = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    stem, dot, ext = name.rpartition(".")
    stem = re.sub(r"[^A-Za-z0-9_-]+", "-", stem.replace(".", "-")).strip("-")[:80]
    ext = f".{ext.lower()}" if dot else ""
    if ext not in ALLOWED:
        raise Rejected(f"extensión no permitida: {raw!r}")
    if not stem:
        raise Rejected(f"nombre vacío tras sanear: {raw!r}")
    return stem + ext


def extract(raw_message: bytes) -> list[tuple[str, bytes]]:
    msg: EmailMessage = message_from_bytes(raw_message, policy=policy.default)
    sender = parseaddr(msg["From"])[1].lower()
    if sender not in KNOWN_SENDERS:
        raise Rejected(f"remitente desconocido: {sender}")
    accepted = []
    for part in msg.iter_attachments():
        name = safe_name(part.get_filename())
        payload = part.get_content() if part.get_content_maintype() == "text" else part.get_payload(decode=True)
        data = payload.encode() if isinstance(payload, str) else payload
        if len(data) > MAX_BYTES:
            raise Rejected(f"{name}: {len(data)} bytes supera el límite")
        magic = ALLOWED[Path(name).suffix]
        # La extensión la pone quien manda; los primeros bytes, el contenido real.
        if magic and not data.startswith(magic):
            raise Rejected(f"{name}: el contenido no es lo que dice la extensión")
        accepted.append((name, data))
    return accepted


def store(attachments: list[tuple[str, bytes]], message_id: str) -> list[Path]:
    INBOX_DIR.mkdir(exist_ok=True)
    prefix = hashlib.sha256(message_id.encode()).hexdigest()[:10]  # dos adjuntos iguales no chocan
    paths = []
    for name, data in attachments:
        path = INBOX_DIR / f"{prefix}-{name}"
        path.write_bytes(data)
        paths.append(path)
    return paths


def process_mailbox(host: str, user: str, password: str) -> None:
    from imap_tools import AND, MailBox

    with MailBox(host).login(user, password, initial_folder="INBOX") as box:
        for msg in box.fetch(AND(seen=False), mark_seen=False, bulk=True):
            try:
                saved = store(extract(msg.obj.as_bytes()), msg.headers.get("message-id", (msg.uid,))[0])
            except Rejected as reason:
                box.move(msg.uid, "Revisar")       # una persona lo mira; el programa no adivina
                print(f"UID {msg.uid} a Revisar: {reason}")
                continue
            box.move(msg.uid, "Procesados")         # se mueve solo después de guardar
            print(f"UID {msg.uid}: {len(saved)} adjuntos guardados")
```

Lo que se prueba sin servidor es lo que más importa —qué se acepta y qué no—. `prueba_buzon.py`:

```python
"""Mensajes de prueba hostiles contra extract()."""

from email.message import EmailMessage

from buzon_cartera import Rejected, extract, safe_name


def message(sender: str, filename: str, data: bytes, subtype: str = "pdf") -> bytes:
    msg = EmailMessage()
    msg["From"], msg["To"], msg["Subject"] = sender, "cartera@aurea.example", "Relación de glosas"
    msg.set_content("Adjuntamos la relación.")
    msg.add_attachment(data, maintype="application", subtype=subtype, filename=filename)
    return msg.as_bytes()


cases = {
    "glosas normales": message("Glosas <glosas@prepagada.example>", "Relación glosas sept.pdf", b"%PDF-1.7 ..."),
    "remitente extraño": message("x@phishing.example", "glosas.pdf", b"%PDF-1.7"),
    "ruta escondida": message("glosas@prepagada.example", "../../.bashrc.pdf", b"%PDF-1.7"),
    "doble extensión": message("glosas@prepagada.example", "factura.pdf.exe", b"MZ\x90\x00", "octet-stream"),
    "disfrazado": message("glosas@prepagada.example", "glosas.pdf", b"MZ\x90\x00"),
}
for label, raw in cases.items():
    try:
        print(f"{label:18} aceptado: {[name for name, _ in extract(raw)]}")
    except Rejected as reason:
        print(f"{label:18} rechazado: {reason}")
print(safe_name("C:\\Users\\x\\Escritorio\\glosas (2).xlsx"))
```

```bash
python3 prueba_buzon.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
glosas normales    aceptado: ['Relacion-glosas-sept.pdf']
remitente extraño  rechazado: remitente desconocido: x@phishing.example
ruta escondida     aceptado: ['bashrc.pdf']
doble extensión    rechazado: extensión no permitida: 'factura.pdf.exe'
disfrazado         rechazado: glosas.pdf: el contenido no es lo que dice la extensión
glosas-2.xlsx
```

La "ruta escondida" se **acepta**, y eso es correcto: el nombre `../../.bashrc.pdf` queda reducido a
`bashrc.pdf`, que se guarda dentro de `entrantes/` y en ningún otro lado, y el contenido es un PDF de
verdad. Lo que el saneamiento garantiza no es que el remitente tenga buenas intenciones, sino que el
nombre que eligió no decide **dónde** se escribe.

**Detalles con intención**

- **El remitente conocido es una primera barrera, no una garantía.** El `From:` se falsifica; por eso
  los adjuntos se sanean igual, y `co02` explica cómo se verifica que el remitente es quien dice ser.
- **La extensión y los primeros bytes** se comprueban los dos. Un `.pdf` que empieza con `MZ` es un
  ejecutable de Windows con disfraz.
- **`mark_seen=False` y mover al final.** Si el programa se cae a la mitad, el mensaje sigue en la
  bandeja y se procesa en la próxima corrida. Mover antes de guardar es perder el mensaje.
- **"Revisar" en vez de borrar.** Lo rechazado lo mira una persona; un programa que borra correos que
  no entiende termina borrando la circular con el formato nuevo.

---

## ⚠️ 4. Lo que se rompe

**Los números de secuencia.** `imaplib` habla en números de secuencia salvo que uses los comandos `UID`
(`uid('SEARCH', …)`, `uid('FETCH', …)`). Mover el mensaje 3 desplaza al 4 y al 5, y el bucle siguiente
procesa el equivocado. `imap-tools` trabaja con `UID` por defecto, que es una de sus mejores razones.

**El adjunto que no es un adjunto.** Algunos clientes de correo marcan un PDF como `inline` en vez de
`attachment`, y `iter_attachments()` lo trata distinto según el cliente. Si un remitente concreto
"no manda adjuntos", hay que mirar la estructura MIME de uno de sus mensajes antes de cambiar el
código.

**El zip.** Si las aseguradoras mandan zip, abrirlo es otra superficie de ataque: rutas dentro del zip
(`../`), y la bomba de compresión. `zipfile` no protege de ninguna de las dos por defecto; se revisa
`ZipInfo.filename` de cada entrada y se suma `file_size` antes de extraer nada.

**La contraseña del buzón.** Google Workspace y Microsoft 365 ya no aceptan la contraseña de la cuenta
por IMAP: piden OAuth (`XOAUTH2`), y `imap-tools` lo soporta con `xoauth2()`. La sección `au05` del
track de automatización trata ese ciclo de tokens.

---

## ⚖️ 5. Cuándo NO usarla

**Cuando el remitente puede dejar los archivos en otro lado.** Un correo con adjunto es el peor
canal para un archivo que un programa tiene que procesar: sin garantía de entrega, sin estructura, y
con un buzón que también leen personas. Si la aseguradora acepta dejar la relación de glosas en un
SFTP o una API, gana siempre. Eso es `co05`.

**Cuando el buzón es de una persona.** Procesar automáticamente el buzón personal de Patricia mezcla
lo suyo con lo del programa y le mueve correos que todavía quería leer. El programa necesita su propio
buzón, y las reglas de reenvío llevan ahí lo que corresponde.

**Para correo de alto volumen.** Miles de mensajes por hora no se procesan por IMAP: los servicios de
correo entrante (*inbound parsing*) los convierten en una petición HTTP a tu servicio.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Agrega un caso de prueba con un adjunto `.csv` con tildes en el contenido. **Criterio:** se acepta
   y el contenido guardado conserva las tildes.
2. Agrega un caso con un archivo `.xlsx` que en realidad es texto. **Criterio:** se rechaza por
   contenido, con el nombre del archivo en el mensaje.
3. Decodifica a mano el asunto `=?utf-8?q?Liquidaci=C3=B3n_de_regal=C3=ADas?=` con `email.header`.
   **Criterio:** obtienes el texto con tildes y explicas qué significan la `q` y los `_`.

**🟡 Intermedio (4–6)**

4. Levanta un servidor IMAP de pruebas en un contenedor (`greenmail/standalone`, por ejemplo) y corre
   `process_mailbox` contra él. **Criterio:** tres mensajes, uno rechazado: dos terminan en
   "Procesados" y uno en "Revisar".
5. Busca en la documentación de `imap-tools` cómo se busca por remitente y fecha en el servidor, en
   vez de traer todo y filtrar en Python. **Criterio:** la búsqueda manda la condición al servidor, y lo
   demuestras con el registro del servidor de pruebas.
6. Agrega la verificación del límite de tamaño **antes** de decodificar el adjunto, con el tamaño que
   declara el mensaje. **Criterio:** un adjunto de 50 MB se rechaza sin cargarlo entero en memoria.

**🟠 Difícil (7–9)**

7. Acepta zips de remitentes conocidos y extráelos de forma segura. **Criterio:** un zip con una
   entrada `../../x` y otro que se expande a más de 100 MB se rechazan, y un zip normal se extrae.
8. Haz el procesamiento idempotente por `Message-ID`: si el programa guarda los adjuntos y se cae
   antes de mover el mensaje, la siguiente corrida no los duplica. **Criterio:** una prueba que simula
   la caída entre `store` y `move`.
9. Mide cuánto tarda traer cien mensajes con `bulk=True` contra uno por uno, en el servidor de
   pruebas. **Criterio:** reportas los dos tiempos y explicas de dónde sale la diferencia.

**🔴 Muy difícil (10)**

10. Convierte el buzón de cartera en la entrada del proceso de glosas: cada relación aceptada se
    convierte en filas con su fecha de notificación y su vencimiento. **Criterio:** un prototipo
    contra el servidor de pruebas y un documento de una página. *Rúbrica:* (a) la fecha de
    notificación es la del correo, no la del procesamiento, y lo justificas; (b) un mensaje que no se
    entiende va a "Revisar" con un aviso a una persona; (c) nada se borra del buzón; (d) dices qué
    pasa si el programa no corre un fin de semana largo y cómo te enteras.

---

## 📚 7. Referencias

**Documentación oficial**

- `imaplib`: https://docs.python.org/3/library/imaplib.html
- `email`, interpretar con `policy.default`: https://docs.python.org/3/library/email.parser.html
- `imap-tools`: https://github.com/ikvk/imap_tools
- `zipfile`, y sus advertencias de seguridad: https://docs.python.org/3/library/zipfile.html

**Orden de lectura sugerido:** el README de `imap-tools`, que es su documentación y se lee en diez
minutos; después la página del parser de `email`; y la de `zipfile` antes de aceptar el primer zip.

---

## 🚀 8. Cierre

Un buzón es una cola de trabajo con entrada no confiable. Se procesa por `UID`, se mueve solo al
terminar, se sanea todo lo que llega —nombre, extensión y contenido— y lo que no se entiende va a
una persona, no a la papelera.

**La señal de que quedó bien:** *"Llegó un correo con un `.pdf.exe`, quedó en Revisar, y la relación de
glosas de esa semana se procesó igual."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-co-fase-03 -m "op co03 cerrada: buzón de cartera como cola, con saneamiento"
> ```
>
> Los commits llevan su prefijo (`op co03: …`) y los de ejercicio su número
> (`op co03 ej07: …`).
