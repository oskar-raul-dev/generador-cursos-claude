"""La red simulada con respx, el reloj con time-machine, y datos que se parecen a los reales."""

import datetime as dt
from decimal import Decimal
from unittest import mock

import httpx
import pytest
import respx
import time_machine
from faker import Faker
from polyfactory.factories.pydantic_factory import ModelFactory

import glosas
from glosas import Objection, due_this_week, fetch_objections

fake = Faker("es_CO")


class ObjectionFactory(ModelFactory[Objection]):
    # Valores plausibles por defecto: nombres con tildes, montos con centavos.
    patient_name = fake.name
    amount = lambda: Decimal(fake.pydecimal(left_digits=6, right_digits=2, positive=True))  # noqa: E731


@respx.mock
def test_fetch_parses_the_api_response():
    respx.get("https://api.prepagada.example/v2/glosas").mock(return_value=httpx.Response(200, json=[
        {"invoice": "FE-000123", "code": "1102", "patient_name": "Sofía Ibáñez",
         "amount": "185000.00", "notified_on": "2026-09-14"},
    ]))
    with httpx.Client() as client:
        [objection] = fetch_objections(client)
    assert objection.patient_name == "Sofía Ibáñez"
    assert objection.amount == Decimal("185000.00")


@respx.mock
def test_fetch_fails_loudly_when_the_api_fails():
    respx.get("https://api.prepagada.example/v2/glosas").mock(return_value=httpx.Response(503))
    with httpx.Client() as client, pytest.raises(httpx.HTTPStatusError):
        fetch_objections(client)


@time_machine.travel(dt.datetime(2026, 10, 5, 9, 0), tick=False)   # lunes 5 de octubre
def test_due_this_week_uses_the_frozen_clock():
    due_friday = ObjectionFactory.build(notified_on=dt.date(2026, 9, 18))   # vence el 9 de octubre
    due_next = ObjectionFactory.build(notified_on=dt.date(2026, 9, 25))     # vence el 16
    assert due_this_week([due_friday, due_next]) == [due_friday]


def test_autospec_catches_the_typo():
    client = mock.create_autospec(httpx.Client, instance=True)
    with pytest.raises(AttributeError):
        client.gett("https://api.prepagada.example/v2/glosas")     # mal escrito: falla
    loose = mock.MagicMock()
    loose.gett("https://api.prepagada.example/v2/glosas")           # sin autospec: pasa sin decir nada


def test_factory_gives_realistic_data():
    objection = ObjectionFactory.build()
    print(objection.patient_name, objection.amount)
    assert objection.amount > 0
