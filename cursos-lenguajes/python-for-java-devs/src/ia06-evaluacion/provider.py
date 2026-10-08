"""Pago de la deuda 💸 de ia01: el Protocol de proveedor.

En ia01 se dejó a propósito sin abstraer —abstraer dos proveedores antes de conocer el
tercero es el reflejo que el camino base enseña a no tener—. Aquí la abstracción se gana
el sueldo: el conjunto de evaluación tiene que correr contra la API y contra el modelo
local, y sin una interfaz común son dos arneses que se desincronizan.
"""

from __future__ import annotations

import time
from dataclasses import dataclass
from decimal import Decimal
from typing import Protocol

import anthropic

from local import ask_local
from pricing import CATALOG


@dataclass(frozen=True, slots=True)
class Completion:
    """Lo que devuelve un proveedor. Lo mínimo que el arnés necesita, y ni un campo más."""

    text: str
    cost: Decimal
    latency_ms: float


class Provider(Protocol):
    """Un proveedor de respuestas. La API y Ollama lo cumplen; el arnés no los distingue."""

    name: str

    def complete(self, *, system: str, prompt: str, max_tokens: int) -> Completion: ...


class ApiProvider:
    """La API de Claude."""

    def __init__(self, client: anthropic.Anthropic, model: str = "claude-opus-5"):
        self.name = model
        self._client = client
        self._model = model

    def complete(self, *, system: str, prompt: str, max_tokens: int) -> Completion:
        started = time.perf_counter()
        response = self._client.messages.create(
            model=self._model,
            max_tokens=max_tokens,
            system=system,
            messages=[{"role": "user", "content": prompt}],
        )
        elapsed_ms = (time.perf_counter() - started) * 1000
        usage = response.usage

        return Completion(
            text="".join(b.text for b in response.content if b.type == "text"),
            cost=CATALOG[self._model].cost_of(usage.input_tokens, usage.output_tokens),
            latency_ms=elapsed_ms,
        )


class LocalProvider:
    """Ollama, en la máquina del lector.

    El costo es Decimal(0) y esa es la única mentira cómoda del arnés: cuesta
    electricidad y tiempo de mantenimiento. Se declara aquí para que quien lea el
    informe sepa qué NO incluye la columna de dólares.
    """

    def __init__(self, model: str = "gemma3"):
        self.name = f"ollama:{model}"
        self._model = model

    def complete(self, *, system: str, prompt: str, max_tokens: int) -> Completion:
        started = time.perf_counter()
        text = ask_local(f"{system}\n\n{prompt}", model=self._model)
        return Completion(
            text=text,
            cost=Decimal(0),
            latency_ms=(time.perf_counter() - started) * 1000,
        )
