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
