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
