"""Lee la firma de plan-firmado.pdf con pyHanko: integridad y campo."""
from pyhanko.pdf_utils.reader import PdfFileReader
from pyhanko.sign.validation import validate_pdf_signature
with open("plan-firmado.pdf", "rb") as f:
    sig = PdfFileReader(f).embedded_signatures[0]
    status = validate_pdf_signature(sig)
    print("campo:", sig.field_name, "· intacta:", status.intact, "· válida criptográficamente:", status.valid,
          "· confiable:", status.trusted)
