"""Radica una factura y descarga las glosas en el portal de una aseguradora, con Playwright."""

import os
import re
from pathlib import Path

from playwright.sync_api import Page, expect, sync_playwright

PORTAL_URL = os.environ.get("PORTAL_URL", "http://127.0.0.1:8000/index.html")


class ProviderPortal:
    """Page Object: un método por cosa que hace la persona, sin selectores fuera de aquí."""

    def __init__(self, page: Page):
        self.page = page

    def log_in(self, user: str, password: str) -> None:
        self.page.goto(PORTAL_URL)
        self.page.get_by_label("Usuario").fill(user)
        self.page.get_by_label("Contraseña").fill(password)
        self.page.get_by_role("button", name="Ingresar").click()
        # La única espera explícita: que aparezca el panel. Sin sleep.
        expect(self.page.get_by_role("heading", name="Radicación de facturas")).to_be_visible()

    def file_invoice(self, pdf: Path) -> str:
        self.page.get_by_label("Factura (PDF)").set_input_files(pdf)
        self.page.get_by_role("button", name="Radicar").click()
        status = self.page.get_by_role("status")
        expect(status).to_contain_text("Radicado")
        match = re.search(r"RAD-\d{4}-\d+", status.inner_text())
        if not match:
            raise RuntimeError(f"el portal no devolvió número de radicado: {status.inner_text()!r}")
        return match.group(0)

    def download_objections(self, target_dir: Path) -> Path:
        with self.page.expect_download() as info:
            self.page.get_by_role("link", name="Exportar glosas").click()
        download = info.value
        target = target_dir / download.suggested_filename
        download.save_as(target)
        return target


def main() -> None:
    user, password = os.environ["PORTAL_USER"], os.environ["PORTAL_PASSWORD"]
    invoice = Path("FE-000123.pdf")
    invoice.write_bytes(b"%PDF-1.4\n% factura de prueba\n")
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(accept_downloads=True)
        context.tracing.start(screenshots=True, snapshots=True)
        page = context.new_page()
        portal = ProviderPortal(page)
        try:
            portal.log_in(user, password)
            print("radicado:", portal.file_invoice(invoice))
            print("glosas en:", portal.download_objections(Path(".")))
        finally:
            # El rastro se guarda siempre: cuando falla en la madrugada, es lo único que hay.
            context.tracing.stop(path="rastro.zip")
            browser.close()


if __name__ == "__main__":
    main()
