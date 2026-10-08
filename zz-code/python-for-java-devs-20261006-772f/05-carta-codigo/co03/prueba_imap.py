import functools, smtplib, time
import imap_tools
from prueba_buzon import message
imap_tools.MailBox = functools.partial(imap_tools.MailBoxUnencrypted, port=3143)  # GreenMail de pruebas, sin TLS
import buzon_cartera
H = "pfjd-mail"
with smtplib.SMTP(H, 3025) as s:
    s.sendmail("glosas@prepagada.example", ["cartera@aurea.example"], message("glosas@prepagada.example", "glosas sept.pdf", b"%PDF-1.7 x"))
    s.sendmail("x@phishing.example", ["cartera@aurea.example"], message("x@phishing.example", "glosas.pdf", b"%PDF-1.7"))
    s.sendmail("cartera@aseguradora.example", ["cartera@aurea.example"], message("cartera@aseguradora.example", "pago.pdf", b"%PDF-1.7 y"))
time.sleep(1)
with imap_tools.MailBox(H).login("cartera", "secreto") as box:
    for f in ("Revisar", "Procesados"):
        box.folder.create(f)
buzon_cartera.process_mailbox(H, "cartera", "secreto")
with imap_tools.MailBox(H).login("cartera", "secreto") as box:
    for f in ("INBOX", "Revisar", "Procesados"):
        box.folder.set(f); print(f, len(list(box.fetch(mark_seen=False))))
import os; print(sorted(os.listdir("entrantes")))
