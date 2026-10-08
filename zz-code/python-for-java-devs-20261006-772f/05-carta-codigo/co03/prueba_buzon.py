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
