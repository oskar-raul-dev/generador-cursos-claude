"""Tokenizador de X12 y EDIFACT: descubre los delimitadores y devuelve segmentos."""

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Delimiters:
    segment: str
    element: str
    component: str
    release: str | None = None  # solo EDIFACT tiene carácter de escape


def x12_delimiters(data: str) -> Delimiters:
    if not data.startswith("ISA") or len(data) < 106:
        raise ValueError("un intercambio X12 empieza con un ISA de 106 caracteres")
    # Las posiciones son las del estándar: el ISA es de ancho fijo aunque use separadores.
    return Delimiters(segment=data[105], element=data[3], component=data[104])


def edifact_delimiters(data: str) -> tuple[Delimiters, str]:
    if data.startswith("UNA"):
        component, element, _decimal, release, _reserved, segment = data[3:9]
        return Delimiters(segment, element, component, release), data[9:]
    return Delimiters("'", "+", ":", "?"), data


def split_escaped(text: str, separator: str, release: str | None,
                  unescape: bool = False) -> list[str]:
    """Corta por el separador respetando el carácter de escape de EDIFACT.

    En los niveles de segmento y de elemento el escape se conserva (`?+` sigue siendo `?+`),
    porque el nivel siguiente todavía tiene que saber que ese `+` no separa nada. Solo el último
    nivel, el de componentes, lo quita.
    """
    if not release:
        return text.split(separator)
    parts, current, escaped = [], [], False
    for char in text:
        if escaped:
            current.append(char if unescape else release + char)
            escaped = False
        elif char == release:
            escaped = True
        elif char == separator:
            parts.append("".join(current))
            current = []
        else:
            current.append(char)
    parts.append("".join(current))
    return parts


def segments(data: str) -> list[list[list[str]]]:
    """Devuelve cada segmento como lista de elementos, y cada elemento como lista de componentes."""
    data = data.strip().replace("\r", "").replace("\n", "")
    if data.startswith("ISA"):
        delims, body = x12_delimiters(data), data
    else:
        delims, body = edifact_delimiters(data)
    result = []
    for raw in split_escaped(body, delims.segment, delims.release):
        if not raw:
            continue
        elements = split_escaped(raw, delims.element, delims.release)
        result.append([split_escaped(e, delims.component, delims.release, unescape=True)
                       for e in elements])
    return result


def tag(segment: list[list[str]]) -> str:
    return segment[0][0]


X12_SAMPLE = (
    "ISA*00*          *00*          *ZZ*AUREA          *ZZ*ASEGURADORA    "
    "*260928*1200*^*00501*000000905*0*T*:~"
    "GS*HC*AUREA*ASEGURADORA*20260928*1200*905*X*005010X222A1~"
    "ST*837*0001*005010X222A1~"
    "CLM*FE-000123*280000***11:B:1*Y*A*Y*Y~"
    "SV1*HC:D0120*185000*UN*1***1~"
    "SV1*HC:D1110*95000*UN*1***1~"
    "SE*5*0001~GE*1*905~IEA*1*000000905~"
)

EDIFACT_SAMPLE = (
    "UNA:+.? '"
    "UNB+UNOC:3+AUREA+DISTRIBUIDOR+260928:1200+42'"
    "UNH+1+ORDERS:D:96A:UN'"
    "BGM+220+PO-2026-0917+9'"
    "LIN+1++BRK-0022:SA'QTY+21:40'"
    "FTX+AAI+++Entregar en sede Centro?+ urgente'"
    "UNT+6+1'UNZ+1+42'"
)

if __name__ == "__main__":
    for segment in segments(X12_SAMPLE):
        if tag(segment) == "SV1":
            code = segment[1][1]   # HC:D0120 → el componente 2 es el código
            amount = segment[2][0]
            print("X12 línea de servicio", code, amount)
    for segment in segments(EDIFACT_SAMPLE):
        if tag(segment) in ("LIN", "QTY", "FTX"):
            print("EDIFACT", tag(segment), [e for e in segment[1:] if e != [""]])
