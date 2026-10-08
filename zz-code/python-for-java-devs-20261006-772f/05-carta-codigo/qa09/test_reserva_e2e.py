"""El camino que no puede romperse: un paciente reserva en el Centro a las 15:40."""

import re

from playwright.sync_api import Page, expect


def test_patient_books_an_appointment(page: Page):
    page.goto("/reservar")
    page.get_by_label("Sede").select_option("Centro")
    page.get_by_label("Documento").fill("1023456789")
    page.get_by_role("button", name="Ver espacios").click()

    expect(page.get_by_role("heading", name=re.compile("Espacios en Centro"))).to_be_visible()
    page.get_by_role("button", name="15:40").click()

    expect(page.get_by_role("status")).to_have_text("Cita confirmada: Centro, 15:40")


def test_document_is_required(page: Page):
    page.goto("/reservar")
    page.get_by_role("button", name="Ver espacios").click()
    # El navegador no envía el formulario: seguimos en la misma página.
    expect(page.get_by_role("heading", name="Reservar una cita")).to_be_visible()
