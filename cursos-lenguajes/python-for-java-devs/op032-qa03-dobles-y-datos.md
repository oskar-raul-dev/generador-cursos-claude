# 🧪 qa03 — Dobles y datos de prueba

> Python para desarrolladores Java senior · **Carta** · Track `qa` — Calidad, pruebas y
> mantenimiento · sección 3 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta. Conviene haber leído la
> [Fase 08](08-el-contrato-del-codigo.md), que presenta `unittest.mock` y `monkeypatch`.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

La parte de Cartera que marca las glosas por vencer depende de dos cosas que una prueba no controla: la
**API de la prepagada**, que devuelve las glosas notificadas, y **el reloj**, porque "por vencer" depende
de qué día es hoy. Una prueba que llama a la API de verdad es lenta, falla cuando la prepagada se cae y
puede tocar datos reales; una que usa `date.today()` pasa el lunes y falla el viernes.

Y hay un tercer problema, más silencioso: los **datos de prueba**. Cada prueba arma sus glosas a mano, con
nombres como `"x"` y montos como `1`, que nunca se parecen a los reales: ningún nombre con tilde, ningún
monto con centavos, ninguna fecha en fin de semana. Las pruebas pasan y los errores aparecen con el primer
paciente que se llama Ibáñez.

Esta sección enseña los dobles que importan en Python —para HTTP, para el tiempo y para objetos— y las
fábricas de datos que se parecen a la realidad.

---

## 🧠 2. El modelo

| Qué se reemplaza | Con qué | La regla |
|---|---|---|
| Llamadas HTTP con `httpx` | **`respx`** (0.23.1) | Se simula **la red**, no el cliente: el código bajo prueba usa su `httpx` de siempre |
| Llamadas HTTP con `requests` | `responses` (0.26.3) | Lo mismo, para el otro cliente |
| El reloj | **`time-machine`** (3.5.1) o `freezegun` (1.5.5) | El tiempo es una entrada de la prueba, no un accidente |
| Un objeto colaborador | `unittest.mock.create_autospec` | El doble tiene **la forma** del original: un método mal escrito falla |
| Datos de ejemplo | **`polyfactory`** (3.3.0), `factory_boy` (3.3.3), `Faker` (40.40.0) | Valores plausibles por defecto; cada prueba fija solo lo que le importa |

La frase de la Fase 08 sigue mandando: **el doble no prueba nada si reemplaza lo que querías probar**.
Por eso se simula en los bordes —la red, el reloj— y no en el medio del dominio.

### Tu instinto de Java dice… y esta vez se equivoca

En Java, Mockito con `@Mock` es el reflejo para todo, y un `mock(Clase.class)` ya tiene la forma de la
clase porque el compilador lo exige. En Python, `MagicMock()` **no tiene forma**: acepta cualquier
atributo y cualquier llamada. `cliente.fech_objections()` —con un error de tipeo— devuelve otro
`MagicMock` sin quejarse, y la prueba pasa sin probar nada. El equivalente real del mock de Mockito es
`create_autospec`, que hace que el doble conozca los métodos y las firmas del original.

---

## 💻 3. El ejemplo que corre

```bash
uv add httpx pydantic
uv add --dev pytest respx time-machine polyfactory faker
```

`glosas.py`:

```python
"""Glosas notificadas por la prepagada, y cuáles vencen esta semana."""

import datetime as dt
from decimal import Decimal

import httpx
from pydantic import BaseModel

RESPONSE_BUSINESS_DAYS = 15     # plazo de ejemplo; el real lo fija el contrato con cada aseguradora


class Objection(BaseModel):
    invoice: str
    code: str
    patient_name: str
    amount: Decimal
    notified_on: dt.date


def fetch_objections(client: httpx.Client) -> list[Objection]:
    response = client.get("https://api.prepagada.example/v2/glosas")
    response.raise_for_status()
    return [Objection.model_validate(item) for item in response.json()]


def due_date(notified_on: dt.date, business_days: int = RESPONSE_BUSINESS_DAYS) -> dt.date:
    """Suma días hábiles (lunes a viernes). No descuenta festivos: ver §4."""
    day, remaining = notified_on, business_days
    while remaining:
        day += dt.timedelta(days=1)
        if day.weekday() < 5:
            remaining -= 1
    return day


def due_this_week(objections: list[Objection]) -> list[Objection]:
    today = dt.date.today()                          # el reloj: la prueba lo controla
    week_end = today + dt.timedelta(days=6 - today.weekday())
    return [o for o in objections if today <= due_date(o.notified_on) <= week_end]
```

`test_glosas.py`:

```python
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
```

```bash
pytest -q -s test_glosas.py
```

Salida (Python 3.14.7, 05/10/2026); el nombre y el monto los inventa `Faker` en cada corrida:

```text
....Camilo Santiago Espinosa 528274.55
.
5 passed in 0.15s
```

**Detalles con intención**

- **`respx` intercepta la red de `httpx`**, así que `fetch_objections` corre con su cliente de verdad: si
  alguien cambia la URL o el método, la prueba falla. Un `mock` del cliente no lo notaría.
- **`tick=False`** congela el reloj por completo. Sin él, `time-machine` deja que el tiempo avance desde
  el punto de partida, que es lo que se quiere en otras pruebas pero no aquí.
- **El caso de la prueba del reloj está calculado**: 15 días hábiles desde el 18 de septiembre es el 9 de
  octubre (viernes de esa semana); desde el 25, el 16, que ya es la semana siguiente.
- **`Faker("es_CO")`** produce nombres colombianos con tildes y eñes. Es el dato que rompe el código que
  asume ASCII, y la fábrica lo pone en todas las pruebas sin que nadie lo pida.

---

## ⚠️ 4. Lo que se rompe

**Simular la función equivocada.** `mock.patch("glosas.httpx.Client")` reemplaza el nombre **donde se
busca**, no donde se define. Si el código hace `from httpx import Client`, hay que parchear
`glosas.Client`. Es la regla de `patch` que más tiempo hace perder, y la razón para preferir simular la red
con `respx` en vez de parchear el cliente.

**Los festivos.** `due_date` cuenta días hábiles sin descontar festivos, y en Colombia hay unos dieciocho
al año, varios trasladados a lunes. Una glosa notificada antes de un puente vence un día después de lo
que calcula el código. La prueba del reloj pasa porque no hay festivos en esa semana; el ejercicio 8 lo
arregla.

**`freezegun` y las extensiones en C.** `freezegun` reemplaza `datetime` en los módulos de Python, pero
no lo que leen las bibliotecas en C. `time-machine` intercepta el reloj más abajo y es más rápido; por eso
el ejemplo lo usa.

**`Faker` sin semilla.** Una prueba que falla con un nombre que `Faker` inventó y no se repite en la
siguiente corrida es imposible de depurar. `Faker.seed(…)` en una fixture, o el plugin de `pytest` que
trae `Faker`, hacen la corrida reproducible.

---

## ⚖️ 5. Cuándo NO usarla

**Para probar la integración de verdad.** `respx` prueba que tu código entiende la respuesta que **tú**
escribiste. Si la prepagada cambia su formato, la prueba sigue pasando. Para eso están las pruebas
doradas con respuestas reales guardadas, y las de contrato.

**Para la base de datos.** Simular SQLAlchemy con `mock` produce pruebas que verifican que llamaste a
`session.add`, no que el dato quedó bien. La base se prueba con una base real: es `qa04`.

**Fábricas para todo.** Un objeto con tres campos se escribe a mano en una línea. La fábrica paga cuando
el modelo tiene muchos campos y cada prueba solo mira dos.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Agrega una prueba con `respx` en la que la API devuelve una glosa sin `notified_on`. **Criterio:**
   falla con `ValidationError` de Pydantic y el mensaje nombra el campo.
2. Cambia `tick=False` por `tick=True` en la prueba del reloj. **Criterio:** explicas si cambia el
   resultado y por qué.
3. Fija la semilla de `Faker` en una fixture. **Criterio:** dos corridas imprimen el mismo nombre.

**🟡 Intermedio (4–6)**

4. Busca en la documentación de `respx` cómo verificar que una ruta se llamó exactamente una vez y con
   qué parámetros. **Criterio:** la prueba falla si `fetch_objections` llama dos veces.
5. Reescribe `test_due_this_week_uses_the_frozen_clock` con `freezegun`. **Criterio:** pasa igual, y
   comparas el tiempo de las dos versiones con 1.000 repeticiones.
6. Haz una fábrica con `factory_boy` para el mismo modelo. **Criterio:** comparas las dos fábricas en
   líneas y en cómo se fija un campo.

**🟠 Difícil (7–9)**

7. Simula la paginación por cursor de la API de glosas con `respx` (dos páginas). **Criterio:** la prueba
   falla si el código pide una tercera página.
8. Agrega los festivos de Colombia a `due_date` (el paquete `holidays`, 0.105, los trae; o una lista propia
   del año) y escribe la prueba con el puente festivo de noviembre. **Criterio:** la glosa vence un día
   hábil después que antes, y la prueba lo fija con una fecha concreta.
9. Encuentra con `Faker` un nombre que rompa algo de tu código (un apóstrofo, una eñe, un nombre de un
   solo apellido). **Criterio:** la prueba que lo reproduce con la semilla y el arreglo.

**🔴 Muy difícil (10)**

10. Revisa la suite de un proyecto tuyo buscando dobles sin forma. **Criterio:** una lista de los
    `MagicMock` sin `spec` y su reemplazo. *Rúbrica:* (a) cuentas cuántos hay; (b) cambias al menos cinco
    por `create_autospec` o por simular la red; (c) encuentras al menos una prueba que pasaba sin probar
    nada; (d) propones la regla para que no vuelva a pasar (un linter, una fixture, una revisión).

---

## 📚 7. Referencias

**Documentación oficial**

- `unittest.mock`, `autospec` y dónde parchear: https://docs.python.org/3/library/unittest.mock.html#autospeccing
- `respx`: https://lundberg.github.io/respx/
- `time-machine`: https://time-machine.readthedocs.io/en/latest/
- `polyfactory`: https://polyfactory.litestar.dev/latest/
- `Faker` y sus *locales*: https://faker.readthedocs.io/en/master/locales/es_CO.html

**Orden de lectura sugerido:** la sección *Where to patch* de `unittest.mock` primero —ahorra horas—;
después `respx`; y `time-machine` para la diferencia con `freezegun`.

---

## 🚀 8. Cierre

Los dobles van en los bordes —la red con `respx`, el reloj con `time-machine`— y los objetos se simulan
con forma (`create_autospec`). Los datos de prueba salen de fábricas que se parecen a los reales, con
tildes y centavos, y con semilla para poder repetirlos.

**La señal de que quedó bien:** *"La prueba de las glosas por vencer pasa todos los días de la semana, y
la primera paciente con eñe la encontró una prueba, no Patricia."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-qa-fase-03 -m "op qa03 cerrada: respx, time-machine, autospec y fábricas"
> ```
>
> Los commits llevan su prefijo (`op qa03: …`) y los de ejercicio su número
> (`op qa03 ej07: …`).
