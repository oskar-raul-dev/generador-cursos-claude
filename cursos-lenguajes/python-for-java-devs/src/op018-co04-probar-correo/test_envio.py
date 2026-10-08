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
