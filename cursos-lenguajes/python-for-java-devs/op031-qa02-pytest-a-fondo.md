# 🧪 qa02 — `pytest` a fondo

> Python para desarrolladores Java senior · **Carta** · Track `qa` — Calidad, pruebas y
> mantenimiento · sección 2 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta. **Empieza donde termina la
> [Fase 08](08-el-contrato-del-codigo.md)**: *fixtures* como inyección, `parametrize` y `conftest.py`.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

La Fase 08 deja claro que una *fixture* no es un `@BeforeEach` sino inyección de dependencias con
alcance, y que `parametrize` convierte una tabla en pruebas. Eso basta para empezar. Cuando la suite de
Cartera llega a cuatrocientas pruebas, aparecen los problemas que la Fase 08 no tenía por qué resolver:

- El catálogo de tarifas se lee del disco **en cada prueba**, y la suite rápida dejó de ser rápida.
- Cada prueba arma su liquidación de ejemplo a mano, con diez campos, y cuando el modelo agrega un
  campo hay que tocar ochenta pruebas.
- Las pruebas de "cada sede por cada trimestre" se escriben como un bucle dentro de una prueba, y cuando
  falla una combinación, el reporte dice "falló `test_todas`" sin decir cuál.
- Hay una regla de la casa —ninguna prueba unitaria puede tardar más de medio segundo— que nadie hace
  cumplir.

Las cuatro se resuelven con lo que `pytest` trae y casi nadie usa: alcances de *fixture*, *fixtures*
fábrica, `parametrize` compuesto, y un *plugin* propio de veinte líneas en el `conftest.py`.

---

## 🧠 2. El modelo

| Herramienta | Qué resuelve | La regla |
|---|---|---|
| **Alcance** (`scope="session"`, `"module"`) | Lo caro se crea una vez | Solo para lo **inmutable**: si una prueba lo modifica, contamina a las demás |
| **Fixture fábrica** | Armar objetos con valores por defecto sensatos | La fixture devuelve una **función**; cada prueba pide solo lo que le importa |
| **`parametrize` apilado** | El producto cartesiano, con un nombre por combinación | Cada combinación es una prueba independiente en el reporte |
| **`indirect=True`** | Que el parámetro pase por una fixture antes de llegar | Para parámetros que hay que construir, no solo leer |
| **Ganchos** (`pytest_*`) | Cambiar cómo se recolecta, corre o reporta | En `conftest.py` para un proyecto; en un paquete para varios |

Los ganchos son el punto donde `pytest` deja de ser una biblioteca y pasa a ser una plataforma: el
propio `pytest` está escrito como un conjunto de *plugins* que implementan esos ganchos, y los tuyos se
cargan igual.

### Tu instinto de Java dice… y esta vez se equivoca

En JUnit, compartir estado caro entre pruebas es un `@BeforeAll` estático, y el reflejo es buscar el
equivalente y poner ahí todo lo que se repite. En `pytest`, el alcance es una propiedad **de la
fixture**, no de la clase de prueba: la misma fixture de sesión la comparten pruebas de veinte archivos
distintos, sin herencia ni clase base. Y extender el *runner* —que en JUnit 5 son *extensions* con su
API— aquí es escribir una función con el nombre del gancho en `conftest.py`.

---

## 💻 3. El ejemplo que corre

```bash
uv add --dev pytest
```

`conftest.py`, con las *fixtures* y el *plugin*:

```python
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
```

`test_regalias.py`:

```python
"""Pruebas que usan la fábrica, la parametrización compuesta y la indirecta."""

import time
from decimal import Decimal

import pytest

from conftest import LOADS


def test_tariffs_are_loaded_once(tariffs):
    assert LOADS["tariffs"] == 1


def test_tariffs_are_read_only(tariffs):
    with pytest.raises(TypeError):
        tariffs["D0120"] = Decimal(0)


@pytest.mark.parametrize("franchise", ["Suba", "Zipaquirá"])
@pytest.mark.parametrize("codes", [("D0120",), ("D0120", "D1110")])
def test_billed_is_sum_of_tariffs(make_settlement, franchise, codes):
    settlement = make_settlement(franchise=franchise, codes=codes)
    assert settlement["billed"] > 0
    assert settlement["franchise"] == franchise


@pytest.mark.parametrize("quarter", ["2026T3", "2026T4"], indirect=True)
def test_quarter_is_built(quarter):
    assert quarter["year"] == 2026 and quarter["q"] in (3, 4)


def test_too_slow_for_the_fast_suite():
    time.sleep(0.6)                                    # viola el presupuesto de medio segundo
```

```bash
pytest -q --budget 0.5 test_regalias.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
.........                                                                [100%]
============================= fuera del presupuesto =============================
0.60 s  test_regalias.py::test_too_slow_for_the_fast_suite
9 passed in 0.83s
```

Nueve pruebas pasaron, y la sesión termina con código de salida 1: el *plugin* convirtió la prueba lenta
en un fallo de la suite. `pytest -q --collect-only` muestra los nombres de las cuatro combinaciones del
`parametrize` apilado —`test_billed_is_sum_of_tariffs[codes0-Suba]`, `[codes1-Zipaquir\xe1]`…— que son las que aparecen en el
reporte cuando una falla.

**Detalles con intención**

- **`MappingProxyType`** convierte el catálogo de sesión en una vista de solo lectura. Una fixture de
  sesión mutable es la causa número uno de pruebas que pasan solas y fallan juntas.
- **La fábrica toma `tariffs`**: los valores por defecto salen del mismo catálogo que usa el código, no
  de números copiados en cada prueba.
- **El *plugin* vive en `conftest.py`**: `pytest` lo carga sin registrarlo. Cuando lo quieras en varios
  proyectos, se mueve a un paquete con un *entry point* `pytest11`.
- **`pytest_sessionfinish` cambia el código de salida**: el CI ve un fallo, aunque todas las pruebas
  hayan pasado.

---

## ⚠️ 4. Lo que se rompe

**Una fixture de sesión que alguien modifica.** Si la fábrica devolviera el diccionario de tarifas y una
prueba le cambiara un precio, todas las pruebas siguientes verían el precio cambiado, y el orden de
ejecución decidiría qué pasa. `pytest-randomly` (5.0.0) baraja el orden en cada corrida justamente para
que ese tipo de dependencia oculta salga a la luz.

**El alcance que no coincide.** Una fixture de sesión no puede pedir una de función: `pytest` falla con
*ScopeMismatch*. Es una protección, no un estorbo: la fixture larga no puede depender de algo que muere
antes que ella.

**`parametrize` sobre objetos sin nombre legible.** Los identificadores por defecto (`codes0`, `codes1`)
no dicen nada en el reporte. `ids=` o `pytest.param(..., id="dos-codigos")` le ponen nombre a cada caso,
y en una suite grande es lo que hace legible un fallo.

**Las tildes en los identificadores.** `pytest` escapa los caracteres no ASCII de los parámetros al
armar el nombre de cada caso: en la prueba de esta sección, la combinación de Zipaquirá aparece como
`test_billed_is_sum_of_tariffs[codes0-Zipaquir\xe1]`. Para seleccionar ese caso con `-k` hay que
escribirlo así, o ponerle un `id=` en ASCII. La opción que desactiva el escape existe y su nombre ya
advierte que pierdes el soporte de la comunidad.

**Los ganchos con nombres mal escritos.** `pytest_runtest_logrepor` (sin la `t`) no falla: simplemente
nunca se llama. `pytest` valida los ganchos que conoce si escribes el *plugin* como clase registrada; en
`conftest.py`, un nombre mal escrito es un *plugin* que no hace nada en silencio.

---

## ⚖️ 5. Cuándo NO usarla

**Un *plugin* para algo que ya existe.** Antes de escribir uno, buscar en el índice de *plugins* de
`pytest`: hay más de mil quinientos. `pytest-timeout`, por ejemplo, corta pruebas que tardan demasiado;
el *plugin* de esta sección existe para enseñar los ganchos y porque el presupuesto de `qa01` reporta en
vez de cortar.

**Fixtures de sesión para todo.** Lo que no es caro no necesita alcance largo, y cada fixture de sesión es
estado compartido que hay que vigilar. La regla: alcance largo solo si cuesta y es inmutable.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Pon `ids=` legibles al `parametrize` de códigos. **Criterio:** `--collect-only` muestra nombres que
   dicen qué combinación es.
2. Quita `MappingProxyType` y escribe una prueba que modifique el catálogo. **Criterio:** encuentras un
   orden de ejecución en que otra prueba falla por eso.
3. Corre la suite sin `--budget`. **Criterio:** termina con código 0 y explicas por qué.

**🟡 Intermedio (4–6)**

4. Instala `pytest-randomly` y corre la suite diez veces con la versión mutable del ejercicio 2.
   **Criterio:** reportas en cuántas corridas falló y con qué semilla se reproduce.
5. Busca en la documentación de `pytest` el gancho `pytest_collection_modifyitems` y úsalo para marcar
   como `slow` toda prueba cuyo nombre empiece por `test_e2e_`. **Criterio:** `-m "not slow"` las deja
   fuera sin marcarlas a mano.
6. Convierte el *plugin* del presupuesto en un paquete instalable con su *entry point* `pytest11`.
   **Criterio:** otro proyecto lo usa con `--budget` sin copiar el `conftest.py`.

**🟠 Difícil (7–9)**

7. Haz que el *plugin* guarde las duraciones de cada corrida en un archivo y avise cuando una prueba se
   volvió el doble de lenta que su mediana histórica. **Criterio:** una prueba que pasa de 0,1 a 0,3 s
   aparece en el aviso.
8. Usa `pytest-xdist` (3.8.0) con `-n 4` y explica qué pasa con la fixture de sesión `tariffs`.
   **Criterio:** cuentas cuántas veces se carga con cuatro procesos y explicas por qué.
9. Escribe una fixture con `yield` que cree un directorio temporal con tres archivos de glosas y lo
   limpie, con alcance de módulo. **Criterio:** una prueba que falla a la mitad no deja el directorio.

**🔴 Muy difícil (10)**

10. Reorganiza una suite de 200 pruebas tuya con fábricas y alcances. **Criterio:** la suite tarda menos
    y es más corta. *Rúbrica:* (a) mides el tiempo antes y después con la misma máquina; (b) cuentas las
    líneas de preparación eliminadas; (c) ninguna fixture de alcance largo es mutable; (d) `pytest-randomly`
    no encuentra ninguna dependencia de orden en diez corridas.

---

## 📚 7. Referencias

**Documentación oficial**

- *Fixtures*, alcances y fábricas: https://docs.pytest.org/en/stable/how-to/fixtures.html
- Parametrizar, incluido `indirect`: https://docs.pytest.org/en/stable/how-to/parametrize.html
- Escribir *plugins* y ganchos: https://docs.pytest.org/en/stable/how-to/writing_plugins.html
- Referencia de ganchos: https://docs.pytest.org/en/stable/reference/reference.html#hooks

**Orden de lectura sugerido:** la página de *fixtures* entera, que tiene más de lo que parece; después la
de *plugins*, buscando `conftest.py` como *plugin* local.

---

## 🚀 8. Cierre

`pytest` a fondo es saber que el alcance es de la fixture, que una fixture puede devolver una fábrica,
que `parametrize` se apila, y que el *runner* se extiende con una función en `conftest.py`. Con eso, la
suite de cuatrocientas pruebas se vuelve más corta, más rápida y hace cumplir sus propias reglas.

**La señal de que quedó bien:** *"Agregamos un campo a la liquidación y tocamos una fábrica, no ochenta
pruebas; y la prueba lenta que alguien agregó la atrapó el plugin, no la paciencia."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-qa-fase-02 -m "op qa02 cerrada: fábricas, alcances y un plugin de presupuesto"
> ```
>
> Los commits llevan su prefijo (`op qa02: …`) y los de ejercicio su número
> (`op qa02 ej07: …`).
