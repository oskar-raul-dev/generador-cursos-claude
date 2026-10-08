"""Firma el PDF del plan de tratamiento en un campo visible."""

from pyhanko.pdf_utils.incremental_writer import IncrementalPdfFileWriter
from pyhanko.sign import signers

signer = signers.SimpleSigner.load_pkcs12("firmante.p12", passphrase=b"cambia-esto")

with open("plan-de-tratamiento.pdf", "rb") as source:
    writer = IncrementalPdfFileWriter(source)
    metadata = signers.PdfSignatureMetadata(field_name="FirmaPaciente")
    with open("plan-firmado.pdf", "wb") as target:
        # La firma se agrega como una revisión incremental: el PDF original queda intacto adentro.
        signers.sign_pdf(writer, metadata, signer=signer, output=target)
