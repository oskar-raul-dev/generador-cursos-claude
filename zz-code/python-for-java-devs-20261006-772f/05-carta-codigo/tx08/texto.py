"""Normalización, orden en español, grafemas y formatos de Colombia."""

import unicodedata
from datetime import date
from decimal import Decimal

import regex
from babel.dates import format_date
from babel.numbers import format_currency, format_decimal

# ------------------------------------------------- 1. dos representaciones del mismo nombre
typed = "Muñoz"                                         # escrito en el formulario: NFC
exported = unicodedata.normalize("NFD", "Muñoz")       # llegó de la exportación del Mac
print("iguales:", typed == exported, "| largo:", len(typed), len(exported))
print("normalizados:", unicodedata.normalize("NFC", exported) == typed)

# ------------------------------------------------- 2. orden alfabético
names = ["Zuluaga", "Álvarez", "ávila", "Nuñez", "Ñañez", "Ochoa", "Mendoza"]


def strip_accents(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s.casefold())
                   if unicodedata.category(c) != "Mn")


def spanish_key(s: str) -> str:
    """Sin tildes, pero con la ñ como letra propia entre la n y la o."""
    s = unicodedata.normalize("NFC", s.casefold()).replace("ñ", "n￿")
    return strip_accents(s)


print("sorted:          ", sorted(names))
print("sin tildes:      ", sorted(names, key=strip_accents))
print("español:         ", sorted(names, key=spanish_key))

# ------------------------------------------------- 3. grafemas
sms = "Te esperamos mañana 👍🏽"
print("puntos de código:", len(sms), "| grafemas:", len(regex.findall(r"\X", sms)))
print("cortado a 21:    ", repr(sms[:21]))
print("cortado bien:    ", repr("".join(regex.findall(r"\X", sms)[:21])))

# ------------------------------------------------- 4. plata, números y fechas de Colombia
print(format_currency(Decimal("1234567.5"), "COP", locale="es_CO"))
print(format_decimal(Decimal("0.866"), format="#,##0.0 %", locale="es_CO"))
print(format_date(date(2026, 10, 5), format="full", locale="es_CO"))
