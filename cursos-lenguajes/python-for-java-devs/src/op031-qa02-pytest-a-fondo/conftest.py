"""Fixtures compartidas y un plugin: el presupuesto de tiempo de la suite rápida, hecho cumplir."""

import json
import time
from decimal import Decimal
from pathlib import Path
from types import MappingProxyType

import pytest

LOADS = {"tariffs": 0}


@pytest.fixture(scope="session")
def tariffs():
    """El catálogo de tarifas: se lee una vez por sesión y se entrega de solo lectura."""
    LOADS["tariffs"] += 1
    time.sleep(0.2)                                   # leerlo de verdad cuesta
    data = {"D0120": Decimal("185000"), "D1110": Decimal("95000"), "D0150": Decimal("60000")}
    return MappingProxyType(data)                     # inmutable: nadie lo contamina


@pytest.fixture
def make_settlement(tariffs):
    """Fábrica: cada prueba dice solo lo que le importa; el resto toma valores sensatos."""
    def make(franchise="Suba", quarter="2026T3", codes=("D0120",), refunds=Decimal(0)):
        billed = sum((tariffs[c] for c in codes), Decimal(0))
        return {"franchise": franchise, "quarter": quarter, "billed": billed, "refunds": refunds}
    return make


@pytest.fixture
def quarter(request):
    """Fixture parametrizable de forma indirecta: recibe '2026T3' y entrega un objeto armado."""
    year, q = request.param.split("T")
    return {"label": request.param, "year": int(year), "q": int(q)}


# ---------------------------------------------------------------- el plugin del presupuesto

def pytest_addoption(parser):
    parser.addoption("--budget", type=float, default=None,
                     help="falla la sesión si alguna prueba tarda más de estos segundos")


BUDGET: list[float | None] = [None]
SLOW: list[tuple[str, float]] = []


def pytest_configure(config):
    BUDGET[0] = config.getoption("--budget")


def pytest_runtest_logreport(report):
    if BUDGET[0] is not None and report.when == "call" and report.duration > BUDGET[0]:
        SLOW.append((report.nodeid, report.duration))


def pytest_terminal_summary(terminalreporter, exitstatus, config):
    if SLOW:
        terminalreporter.section("fuera del presupuesto")
        for nodeid, duration in SLOW:
            terminalreporter.write_line(f"{duration:.2f} s  {nodeid}")


def pytest_sessionfinish(session, exitstatus):
    if SLOW and session.exitstatus == 0:
        session.exitstatus = 1                         # una prueba lenta hace fallar la suite rápida
