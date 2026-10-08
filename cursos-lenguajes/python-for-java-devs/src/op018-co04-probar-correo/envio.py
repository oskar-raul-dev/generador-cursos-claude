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
