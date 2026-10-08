"""Extrae las circulares de la página pública de una prepagada, y falla si la página cambió."""

import datetime as dt
from dataclasses import dataclass
from urllib.parse import urljoin

from bs4 import BeautifulSoup
from selectolax.lexbor import LexborHTMLParser

PAGE_URL = "https://www.prepagada.example/prestadores/circulares"

SAVED_PAGE = """
<html><body>
  <nav>Inicio · Prestadores · Circulares</nav>
  <section id="circulares">
    <h2>Circulares a prestadores</h2>
    <table>
      <thead><tr><th>Fecha</th><th>Asunto</th><th>Documento</th></tr></thead>
      <tbody>
        <tr><td>2026-09-30</td><td>Nuevo soporte para ortodoncia: foto intraoral fechada</td>
            <td><a href="/docs/circular-118.pdf">PDF</a></td></tr>
        <tr><td>2026-09-12</td><td>Actualización de tarifas de periodoncia</td>
            <td><a href="/docs/circular-117.pdf">PDF</a></td></tr>
      </tbody>
    </table>
  </section>
</body></html>
"""

EXPECTED_HEADERS = ["Fecha", "Asunto", "Documento"]


class PageChanged(Exception):
    """La página ya no tiene la forma que el scraper conoce."""


@dataclass(frozen=True)
class Circular:
    published_on: dt.date
    subject: str
    pdf_url: str


def check_and_build(headers: list[str], rows: list[tuple[str, str, str | None]]) -> list[Circular]:
    """La misma validación para los dos parsers: forma de la tabla, al menos una fila, tipos."""
    if headers != EXPECTED_HEADERS:
        raise PageChanged(f"encabezados {headers}, se esperaban {EXPECTED_HEADERS}")
    if not rows:
        raise PageChanged("la tabla de circulares está vacía: es más probable un rediseño que un mes sin circulares")
    circulars = []
    for date_text, subject, href in rows:
        if not href or not href.lower().endswith(".pdf"):
            raise PageChanged(f"la circular {subject!r} no enlaza un PDF")
        circulars.append(Circular(dt.date.fromisoformat(date_text), subject, urljoin(PAGE_URL, href)))
    return circulars


def with_selectolax(html: str) -> list[Circular]:
    tree = LexborHTMLParser(html)
    # Anclado en el id de la sección y en la tabla, no en la posición dentro de la página.
    section = tree.css_first("section#circulares")
    if section is None:
        raise PageChanged("no existe section#circulares")
    headers = [th.text(strip=True) for th in section.css("thead th")]
    rows = []
    for tr in section.css("tbody tr"):
        cells = tr.css("td")
        link = tr.css_first("a")
        rows.append((cells[0].text(strip=True), cells[1].text(strip=True),
                     link.attributes.get("href") if link else None))
    return check_and_build(headers, rows)


def with_beautifulsoup(html: str) -> list[Circular]:
    soup = BeautifulSoup(html, "html.parser")
    # Otra forma de anclarse: por el texto del título, que sobrevive a un cambio de id.
    title = soup.find("h2", string=lambda s: s and "Circulares" in s)
    if title is None:
        raise PageChanged("no aparece el título 'Circulares'")
    table = title.find_next("table")
    headers = [th.get_text(strip=True) for th in table.select("thead th")]
    rows = []
    for tr in table.select("tbody tr"):
        cells = tr.find_all("td")
        link = tr.find("a")
        rows.append((cells[0].get_text(strip=True), cells[1].get_text(strip=True),
                     link.get("href") if link else None))
    return check_and_build(headers, rows)


if __name__ == "__main__":
    fast = with_selectolax(SAVED_PAGE)
    tolerant = with_beautifulsoup(SAVED_PAGE)
    assert fast == tolerant, "los dos parsers no coinciden"
    for circular in fast:
        print(circular.published_on, circular.subject[:40], circular.pdf_url)

    redesigned = SAVED_PAGE.replace('id="circulares"', 'id="documentos"').replace("<th>Asunto</th>", "<th>Tema</th>")
    for parser in (with_selectolax, with_beautifulsoup):
        try:
            parser(redesigned)
        except PageChanged as error:
            print(f"{parser.__name__}: {error}")
