"""Pruebas doradas: cada archivo real anonimizado tiene su salida revisada al lado."""

import dataclasses
import json
from decimal import Decimal
from pathlib import Path

import pytest

from glosas_mainframe import read_fixed  # el parser de la aseguradora (o cualquiera del track)

GOLDEN = Path(__file__).parent / "golden"


def as_jsonable(obj: object) -> object:
    # Decimal y fechas a texto: la comparación es exacta y el JSON se lee en una revisión de código.
    if isinstance(obj, Decimal):
        return str(obj)
    if hasattr(obj, "isoformat"):
        return obj.isoformat()
    raise TypeError(type(obj))


def parse_to_json(path: Path) -> str:
    rows = [dataclasses.asdict(item) for item in read_fixed(path)]
    return json.dumps(rows, default=as_jsonable, indent=2, ensure_ascii=False, sort_keys=True)


@pytest.mark.parametrize("source", sorted(GOLDEN.glob("*.dat")), ids=lambda p: p.name)
def test_golden(source: Path, request: pytest.FixtureRequest) -> None:
    expected_path = source.with_suffix(".expected.json")
    actual = parse_to_json(source)
    if request.config.getoption("--update-golden"):
        # Regenerar es una decisión humana: el diff del JSON se revisa en el commit.
        expected_path.write_text(actual, encoding="utf-8")
        pytest.skip("dorado regenerado; revisa el diff antes de commitear")
    assert actual == expected_path.read_text(encoding="utf-8")
