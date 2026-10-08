"""Value object: dinero en centavos enteros. Ningún float toca un importe; el contrato lo
serializa como texto ("49.90") y este tipo es el único que hace aritmética con él."""

from __future__ import annotations

import re
from dataclasses import dataclass

_AMOUNT = re.compile(r"^-?[0-9]+\.[0-9]{2}$")


@dataclass(frozen=True, slots=True)
class Money:
    cents: int
    currency: str

    @staticmethod
    def parse(amount: str, currency: str = "USD") -> Money:
        if not _AMOUNT.match(amount):
            raise ValueError(f"invalid amount: {amount!r}")
        negative = amount.startswith("-")
        whole, fraction = amount.lstrip("-").split(".")
        cents = int(whole) * 100 + int(fraction)
        return Money(-cents if negative else cents, currency)

    @staticmethod
    def usd(amount: str) -> Money:
        return Money.parse(amount, "USD")

    def times(self, quantity: int) -> Money:
        return Money(self.cents * quantity, self.currency)

    def plus(self, other: Money) -> Money:
        if other.currency != self.currency:
            raise ValueError(f"currency mismatch: {self.currency} vs {other.currency}")
        return Money(self.cents + other.cents, self.currency)

    def is_greater_than(self, other: Money) -> bool:
        return self.cents > other.cents

    def has_amount(self, literal: str) -> bool:
        return self.cents == Money.parse(literal, self.currency).cents

    def text(self) -> str:
        """"49.90", nunca "49.9"."""
        sign, cents = ("-", -self.cents) if self.cents < 0 else ("", self.cents)
        return f"{sign}{cents // 100}.{cents % 100:02d}"
