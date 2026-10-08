# 🔎 Fase 08 — El contrato del código

> Python para desarrolladores Java senior · Fase 8 de 18 · Bloque B
> Depende de: Fase 07 · Habilita: Fase 09
> Registro de esta fase: **herramienta** — `src/`, tipado estricto, pruebas
> Proyecto que avanza: el CLI · **queda blindado el motor de comisiones**
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Ponerle al proyecto las dos redes que en Java venían de fábrica —el compilador y la suite de
pruebas— y entender en qué se parecen y en qué no.

Las dos afirmaciones que hay que desarmar son simétricas y las dos las trae este perfil. La
primera: *"el verificador de tipos es el compilador"*. No lo es, y creer que lo es produce una
confianza que no está respaldada por nada. La segunda: *"las pruebas son JUnit con otra sintaxis"*.
Tampoco, y traducir JUnit línea por línea produce una suite que funciona y que nadie va a
mantener.

Y esta fase tiene la medición más convincente del curso, por una razón que no se puede discutir:
**se hace sobre el código que escribiste tú** en las siete fases anteriores.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `mypy --strict` corre sobre `src/aur/` y pasa limpio, sin un solo `Any` y sin `# type:
      ignore` sin justificar.
- [ ] Sabes distinguir los errores del verificador que son **ruido de adopción** de los que son
      **errores de verdad**, y tienes el número de cada clase sobre tu propio código.
- [ ] Puedes explicar tres cosas que el verificador **no** garantiza y que el compilador de Java
      sí.
- [ ] Escribes pruebas con `pytest` usando `assert` a secas, y sabes por qué su salida es mejor
      que la de una biblioteca de aserciones.
- [ ] Usas fixtures como lo que son —inyección de dependencias con alcance— y no como `@Before`.
- [ ] Tienes una prueba basada en propiedades sobre el invariante del dominio, y **encontró algo**.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Pruebas de integración con base de datos** → Fase 11. Hoy `sqlite3` en memoria alcanza, y
  probar contra Postgres de verdad es otro problema.
- **Pruebas de una API HTTP** → Fase 10, con el cliente de pruebas del framework.
- **Cobertura como métrica de gestión.** Se mide y se usa como herramienta de diagnóstico; el
  número como objetivo se discute en §5.6 y se rechaza con su razón.
- **Mutation testing, contract testing y *fuzzing* dirigido.** Se nombran y se cierran: son
  buenos, y ninguno cabe en el camino base sin quitarle el sitio a algo que se usa más.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

Dos reflejos, uno por cada red.

#### Primero: *"el verificador es el compilador"*

Escribes `amount: Decimal`, corre `mypy`, no dice nada, y aparece una sensación muy familiar y muy
peligrosa: **está garantizado**. No lo está, y hay tres diferencias concretas:

**No hay garantía en tiempo de ejecución.** Las anotaciones no se comprueban al correr. Esto pasa
sin quejarse:

```python
def total_for(rows: list[Row]) -> Decimal: ...

total_for("esto no es una lista")   # corre, y falla donde menos lo esperas
```

En Java eso no compila. Aquí compila, corre, y revienta tres funciones más adentro con un mensaje
sobre `str` que no tiene nada que ver con lo que hiciste mal.

**El verificador es un programa aparte que alguien tiene que correr.** No hay build que lo invoque
por ti. Si nadie lo pone en el CI —o si tú no lo corres antes de commitear— tus anotaciones son
documentación bonita. Esto es casi todo lo que separa un proyecto de Python tipado de uno que
tiene anotaciones.

**Y las bibliotecas pueden mentirte.** Una biblioteca sin anotaciones hace que todo lo que
devuelve sea `Any`, y `Any` es contagioso: se propaga por tu código desactivando la verificación
en silencio. Una biblioteca *con* anotaciones puede tenerlas mal, y el verificador les cree.

> 📝 **La nota honesta, y es obligatoria en esta fase:** el tipado de Python es **gradual**. Está
> diseñado para que puedas tipar una parte y dejar el resto sin tipar, lo cual es su mayor virtud
> —permite adoptarlo en un proyecto de cien mil líneas— y su mayor debilidad: el agujero es parte
> del diseño. Lo que te da a cambio es real y hay que decirlo también: atrapa el 90% de los errores
> de firma, hace navegable un proyecto grande, y convierte el autocompletado en algo que de verdad
> sabe qué está devolviendo cada cosa.

**Qué se escribe en su lugar, entonces:** modo estricto desde el primer día, `Any` prohibido, el
verificador en el CI, y **validación en tiempo de ejecución en la frontera** —donde entran los
datos de afuera—, que es justamente lo que la Fase 10 va a construir con Pydantic. El tipado
estático y la validación en el borde no compiten: se complementan, y quien solo tiene el primero
tiene la mitad.

#### Segundo: *"traduzco JUnit"*

```python
# ❌ Lo que sale solo: JUnit con sintaxis de Python
class TestReferralFee(unittest.TestCase):
    def setUp(self):
        self.rates = {"P001": Decimal("0.15")}
        self.calculator = ReferralFeeCalculator(self.rates)

    def test_simple_fee(self):
        result = self.calculator.calculate("P001", Decimal("1000000"))
        self.assertEqual(result, Decimal("150000"))
```

Funciona. `unittest` está en la biblioteca estándar y es perfectamente válido. Pero arrastra tres
cosas que aquí no hacen falta: la clase, el `setUp` que corre **antes de cada método** con estado
compartido en `self`, y los `assertEqual` de una API que existe porque Java no tiene forma de
inspeccionar una expresión fallida.

```python
# ✅ Lo mismo, en pytest
def test_referral_fee_simple():
    rates = {"P001": Decimal("0.15")}
    assert referral_fee("P001", Decimal("1000000"), rates) == Decimal("150000")
```

Una función, un `assert`. Y cuando falla, `pytest` reescribe la expresión para mostrarte los dos
lados y la diferencia — que es exactamente lo que `assertEqual` venía a dar:

```text
E       AssertionError: assert Decimal('160000') == Decimal('150000')
```

> 📝 **Esto no contradice a la Fase 04**, que advirtió que `assert` desaparece con `python -O`.
> Las pruebas corren sin `-O` a propósito, y en ellas `assert` es la forma correcta de afirmar.
> Lo que sigue mal es usar `assert` para validar entradas en el código de producción: ahí va un
> `if` con su excepción, porque `-O` lo borraría.

**La diferencia de fondo no es la sintaxis: es el `setUp`.** En JUnit, la preparación es una fase
del ciclo de vida que corre siempre, para todos los métodos de la clase, y el estado vive en
campos. En `pytest`, la preparación son **fixtures**: funciones que declaran lo que producen, que
se piden por nombre en la firma de la prueba, y que tienen alcance —por prueba, por módulo, por
sesión—. Es inyección de dependencias, no un gancho del ciclo de vida.

```python
import pytest


@pytest.fixture
def rates() -> dict[str, Decimal]:
    """Las tarifas de prueba. Solo la reciben las pruebas que la piden."""
    return {"P001": Decimal("0.15"), "P004": Decimal("0.10")}


def test_referral_fee_simple(rates: dict[str, Decimal]) -> None:
    assert referral_fee("P001", Decimal("1000000"), rates) == Decimal("150000")


def test_minimum_per_case(rates: dict[str, Decimal]) -> None:
    assert referral_fee("P004", Decimal("500000"), rates) == Decimal("150000")
```

Lo que eso compra, y es concreto: **una prueba que no pide una fixture no paga su costo**. En una
suite con una fixture cara —una base de datos, un archivo grande— eso es la diferencia entre una
suite de dos segundos y una de dos minutos.

### Esto sí funciona igual

Y aquí es mucho, más que en ninguna otra fase del curso:

**Todo tu criterio de qué probar se transfiere intacto.** Qué merece una prueba, cómo se elige un
caso límite, cuándo un doble es la respuesta y cuándo es una trampa, por qué una prueba que prueba
el mock no prueba nada, y la pirámide de pruebas entera. Eso es oficio, no lenguaje.

**La disciplina de la prueba que falla primero.** Escribir la prueba, verla fallar por la razón
correcta, y después arreglar. Aquí importa **más** que en Java, porque no hay compilador que
atrape el error de dedo.

**Los dobles son los dobles.** *Stub*, *spy*, *fake*, *mock* significan lo mismo, y el criterio
para elegir entre ellos también.

**Y el arte de nombrar una prueba** por lo que verifica, no por la función que llama.
`test_el_tope_mensual_corta_en_el_segundo_caso` le sirve a quien lo lea en dos años;
`test_monthly_cap_2`, no.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| El compilador verifica tipos | `mypy` / `pyright`, aparte | **Nadie lo corre por ti**, y no hay garantía en ejecución |
| `final` | no hay equivalente real | `Final` es una anotación que solo ve el verificador |
| `Optional<T>` | `T \| None` | Anotación, no envoltorio: no hay `.map()` |
| Genéricos `<T>` | `def f[T](x: T) -> T` (PEP 695) | Sintaxis nueva desde 3.12; vas a ver `TypeVar` en todo el código anterior |
| `interface` | `Protocol` | Estructural: nadie declara que lo implementa |
| `Map<String, Object>` con forma conocida | `TypedDict` | Describe la forma de un `dict`; no existe en ejecución |
| JUnit `@Test` | una función que se llame `test_*` | Sin anotación, sin clase, sin importar nada |
| `@BeforeEach` | `@pytest.fixture` | **No es un gancho del ciclo de vida: es inyección con alcance** |
| `@ParameterizedTest` | `@pytest.mark.parametrize` | Más simple: una lista de tuplas |
| `assertEquals(a, b)` | `assert a == b` | `pytest` reescribe la expresión y muestra los dos lados |
| `assertThrows` | `with pytest.raises(...)` | Un context manager; el objeto queda disponible para inspeccionarlo |
| Mockito | `unittest.mock` / `monkeypatch` | `monkeypatch` sustituye **por nombre** y deshace el cambio al terminar |
| JaCoCo | `pytest-cov` | Igual, con las mismas virtudes y el mismo abuso |
| jqwik / QuickCheck | `hypothesis` | Igual de bueno, y con **reducción del contraejemplo** a su forma mínima |

### Lo que hay que saber de tipos, y no es tanto

**`Protocol` cierra el bucle que la Fase 03 dejó abierto.** Allí `SPECIAL_RULES` era un
diccionario de funciones y el veredicto decía que su pérdida frente a la clase base abstracta era
no declarar la firma. Esto lo recupera, y ahora sí lo verifica alguien:

```python
from typing import Protocol


class SpecialRule(Protocol):
    """La firma que tiene que cumplir toda regla especial de aliado."""

    def __call__(
        self,
        value: Decimal,
        specialty: str,
        month_to_date: Decimal,
        rate: Decimal,
    ) -> Decimal: ...


SPECIAL_RULES: dict[str, SpecialRule] = {}
```

Registrar una función con los parámetros en otro orden ahora **falla en el verificador**, no tres
meses después en una liquidación. Es el ejercicio 15 de la Fase 03, resuelto.

**`TypedDict` para la forma de un diccionario** que viene de afuera y que no vale la pena
convertir en clase:

```python
from typing import TypedDict


class RatesConfig(TypedDict):
    """La forma de tarifas.toml, tal como la devuelve tomllib."""

    vigente_desde: date
    moneda: str
```

**Genéricos, con la sintaxis nueva:**

```python
def first_or_none[T](items: Iterable[T]) -> T | None:
    """El primero, o None si está vacío."""
    for item in items:
        return item
    return None
```

`def f[T](...)` es de 3.12 (PEP 695). Antes había que declarar `T = TypeVar("T")` arriba, y eso es
lo que vas a ver en todo el código existente. Las dos formas funcionan.

**Y `Optional` como decisión de dominio, no como escape.** Esto es lo que separa una firma útil de
una que solo calla al verificador:

```python
def validity_end(plan: TreatmentPlan) -> date | None:
    """La fecha de vencimiento del plan, o None si no vence.

    `None` significa 'vigente indefinidamente' — que es un estado real del
    dominio, no 'no me molesté en calcularlo'.
    """
```

> 🧭 **La regla:** si tu `| None` no se puede explicar en una frase del negocio, probablemente
> estás usando `None` para tapar un caso que no decidiste. Eso el verificador te lo acepta, y es
> exactamente donde se esconden los errores.

### Lo que hay que saber de `pytest`, y tampoco es tanto

**`parametrize`** convierte una tabla en pruebas independientes, cada una con su nombre y su
fallo por separado:

```python
@pytest.mark.parametrize(
    ("partner", "value", "expected"),
    [
        ("P001", Decimal("1000000"), Decimal("150000")),
        ("P004", Decimal("500000"), Decimal("150000")),    # el mínimo por caso
        ("P004", Decimal("3000000"), Decimal("300000")),   # por encima del mínimo
    ],
)
def test_referral_fee(partner: str, value: Decimal, expected: Decimal,
                      rates: dict[str, Decimal]) -> None:
    assert referral_fee(partner, value, rates) == expected
```

**`conftest.py`** es donde viven las fixtures compartidas. `pytest` lo encuentra solo, sin
importarlo: las fixtures que declares ahí están disponibles para todo el directorio hacia abajo.

**`monkeypatch`** sustituye algo por su nombre completo y **lo deshace al terminar la prueba**:

```python
def test_sin_tocar_el_disco(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.setattr("aur.storage.DEFAULT_DB", tmp_path / "test.sqlite3")
    ...
```

**`tmp_path`** es una fixture incorporada que da un directorio temporal por prueba, limpio y
borrado después. Con esas dos, el 90% de las pruebas que tocan archivos se escriben sin
ceremonia.

**Y `pytest.raises`** para lo que en JUnit es `assertThrows`, con la ventaja de que el objeto
queda a mano:

```python
def test_fila_sin_documento_se_rechaza() -> None:
    with pytest.raises(InvalidRow) as caught:
        validate_row(row_without_document, line_number=42)
    assert caught.value.line_number == 42
    assert caught.value.field == "documento"
```

### Pruebas basadas en propiedades, que es lo nuevo

Las pruebas de ejemplo verifican los casos que se te ocurrieron. Las basadas en propiedades
verifican una **afirmación que tiene que ser cierta siempre**, y dejan que la herramienta busque
el contraejemplo.

En Áurea hay una afirmación así, y es la más importante del dominio: **lo repartido entre los
profesionales de un plan suma exactamente lo cobrado.** Ni un peso más, ni uno menos. Si eso se
rompe, alguien reclama.

```python
from hypothesis import given, settings
from hypothesis import strategies as st

money = st.decimals(min_value=Decimal("1000"), max_value=Decimal("50000000"),
                    places=2, allow_nan=False, allow_infinity=False)


@given(total=money)
@settings(max_examples=300)
def test_lo_repartido_suma_lo_cobrado(total: Decimal) -> None:
    partes = split_fee(total, [0.4, 0.35, 0.25])
    assert sum(partes) == total
```

Y esto es lo que pasa cuando `split_fee` usa `float`, tal como lo escribiría cualquiera:

```text
Falsifying example: test_lo_repartido_suma_lo_cobrado(
    total=Decimal('6214.97'),
)
E   AssertionError: assert Decimal('6214.969999999999') == Decimal('6214.97')
E    +  where 6214.969999999999 = sum([2485.99, 2175.24, 1553.74])
```

**Trescientos ejemplos y un contraejemplo concreto**, reducido a la forma más pequeña que falla.
Nadie habría elegido `6214.97` a mano. Esa es la diferencia entre las dos clases de prueba, y es
la razón por la que esta entra al curso.

---

## 💻 5. Código mínimo con comentarios

### 5.1 Encender el verificador

En `pyproject.toml`, junto a lo de la Fase 07:

```toml
[tool.mypy]
python_version = "3.14"
strict = true                    # enciende una docena de banderas de golpe

# Y las tres que hay que declarar aparte porque strict no las cubre:
warn_unreachable = true          # código que no se puede alcanzar: casi siempre es un bug
disallow_any_explicit = true     # prohibido escribir `Any` a mano (regla del curso, guía §6.5)
enable_error_code = ["ignore-without-code", "redundant-expr"]
# ignore-without-code: prohíbe `# type: ignore` pelado. Si vas a silenciar algo,
# di exactamente qué silencias: `# type: ignore[union-attr]`.
```

```bash
uv run mypy --strict src/
```

Lo que sale la primera vez es la medición de la sección 6, y conviene mirarla antes de arreglar
nada.

### 5.2 Tipar el motor de comisiones

```python
"""El motor de comisiones, con su contrato declarado."""

from decimal import Decimal
from typing import Protocol

from aur.errors import UnknownPartner


class SpecialRule(Protocol):
    """La firma de una regla especial de aliado.

    Declarado como Protocol y no como clase base: las reglas son funciones
    sueltas (Fase 03) y ninguna tiene que heredar de nada. Lo que gana el
    verificador es poder rechazar una regla con la firma equivocada en el
    momento de registrarla.
    """

    def __call__(
        self,
        value: Decimal,
        specialty: str,
        month_to_date: Decimal,
        rate: Decimal,
    ) -> Decimal: ...


SPECIAL_RULES: dict[str, SpecialRule] = {}


def rule_for(partner_id: str) -> Callable[[SpecialRule], SpecialRule]:
    """Registra la regla especial de un aliado."""

    def register(function: SpecialRule) -> SpecialRule:
        SPECIAL_RULES[partner_id] = function
        return function

    return register


def referral_fee(
    partner_id: str,
    value: Decimal,
    rates: Mapping[str, Decimal],
    specialty: str = "",
    month_to_date: Decimal = Decimal("0"),
) -> Decimal:
    """La comisión que Áurea le factura a un aliado por un caso derivado.

    Levanta:
        UnknownPartner: si el aliado no está en la tabla de tarifas.
    """
    try:
        rate = rates[partner_id]
    except KeyError:
        raise UnknownPartner(partner_id) from None

    rule = SPECIAL_RULES.get(partner_id)
    return rule(value, specialty, month_to_date, rate) if rule else value * rate
```

**Detalles con intención**

- **`Mapping` en el parámetro, `dict` en el retorno.** La regla es de siempre —acepta lo más
  general, devuelve lo más concreto— y aquí además declara que la función **no va a modificar** el
  diccionario que recibe. Es la única forma de decir "esto es de solo lectura" en un lenguaje donde
  todo se pasa por referencia (Fase 01).
- **El `KeyError` se traduce a un error del dominio.** Antes, un aliado que faltaba producía un
  `KeyError` con el identificador como mensaje; ahora produce un `UnknownPartner` que dice qué pasó.
  Es de la Fase 04, y aquí se aplica.
- **Y el `Protocol` cobra la promesa:** registrar `def mala(rate, value): ...` ahora falla en
  `mypy`, en el decorador, antes de que el código llegue a ningún lado.

### 5.3 La primera prueba, y por qué se escribe así

```python
"""Pruebas del motor de comisiones."""

from decimal import Decimal

import pytest

from aur.errors import UnknownPartner
from aur.fees import referral_fee


@pytest.fixture
def rates() -> dict[str, Decimal]:
    """Tarifas de prueba: las tres que tienen regla especial y una ordinaria."""
    return {
        "P001": Decimal("0.15"),
        "P004": Decimal("0.10"),
        "P005": Decimal("0.18"),
        "P006": Decimal("0.10"),
    }


def test_aliado_ordinario_cobra_su_porcentaje(rates: dict[str, Decimal]) -> None:
    assert referral_fee("P001", Decimal("1000000"), rates) == Decimal("150000.00")


def test_el_minimo_por_caso_se_aplica_cuando_el_porcentaje_queda_corto(
    rates: dict[str, Decimal],
) -> None:
    # 10% de 500.000 son 50.000, por debajo del mínimo de 150.000 que negoció Neira.
    assert referral_fee("P004", Decimal("500000"), rates) == Decimal("150000")


def test_el_tope_mensual_corta_la_comision_en_el_saldo_restante(
    rates: dict[str, Decimal],
) -> None:
    # Buitrago lleva 1.900.000 causados y su tope es 2.000.000: solo caben 100.000.
    fee = referral_fee("P005", Decimal("1000000"), rates, month_to_date=Decimal("1900000"))
    assert fee == Decimal("100000")


def test_un_aliado_que_no_esta_en_la_tabla_se_reporta_con_su_identificador(
    rates: dict[str, Decimal],
) -> None:
    with pytest.raises(UnknownPartner) as caught:
        referral_fee("P999", Decimal("1000000"), rates)
    assert "P999" in str(caught.value)
```

**Detalles con intención**

- **Los nombres dicen la regla de negocio**, no la función. Dentro de dos años, cuando una de
  estas falle, el nombre va a ser lo primero que alguien lea.
- **Cada prueba trae el porqué del número en un comentario.** `Decimal("150000")` no explica nada;
  *"10% de 500.000 son 50.000, por debajo del mínimo"* sí.
- **La fixture no es un `setUp`:** solo la reciben las pruebas que la piden por nombre.
- **Y las pruebas están tipadas**, igual que el resto del código. `mypy --strict` las verifica
  también, y ahí atrapa el error más común de una suite: la prueba que llama a la función con el
  argumento equivocado y "pasa" porque nunca llega a la aserción.

### 5.4 La prueba que encuentra sola el `float`

```python
"""El invariante del dominio: lo repartido suma exactamente lo cobrado."""

from decimal import Decimal

from hypothesis import given, settings
from hypothesis import strategies as st

from aur.fees import split_fee

# Dinero realista de Áurea: de mil pesos a cincuenta millones, con dos decimales.
money = st.decimals(
    min_value=Decimal("1000"),
    max_value=Decimal("50000000"),
    places=2,
    allow_nan=False,
    allow_infinity=False,
)


@given(total=money)
@settings(max_examples=300)
def test_lo_repartido_suma_exactamente_lo_cobrado(total: Decimal) -> None:
    """El invariante que Édgar revisa cada trimestre.

    Si esto falla, alguien recibió de menos o Áurea pagó de más. No hay una
    tercera posibilidad, y por eso es una propiedad y no un caso de prueba.
    """
    parts = split_fee(total, [Decimal("0.4"), Decimal("0.35"), Decimal("0.25")])
    assert sum(parts) == total
```

Y la implementación que la hace pasar, que es donde está la lección:

```python
def split_fee(total: Decimal, shares: Sequence[Decimal]) -> list[Decimal]:
    """Reparte un total entre varios profesionales, sin perder ni un peso.

    El último se lleva el residuo. No es un detalle de implementación: es una
    decisión de negocio —alguien tiene que quedarse con el centavo que sobra—
    y en Áurea se acordó que fuera quien ejecuta la última fase del plan.
    """
    parts: list[Decimal] = []
    remaining = total
    for share in shares[:-1]:
        part = (total * share).quantize(Decimal("0.01"))
        parts.append(part)
        remaining -= part
    parts.append(remaining)      # el residuo, entero, sin redondear otra vez
    return parts
```

**El patrón a memorizar**

> Repartir dinero no es multiplicar por porcentajes: es repartir y **dar el residuo a alguien**.
> Cualquier implementación que redondee cada parte por separado va a fallar, y la pregunta de
> quién se queda el centavo es de negocio, no de código.

### 5.5 Probar lo que toca el disco

```python
def test_el_historico_no_duplica_al_reprocesar_el_mismo_cierre(tmp_path: Path) -> None:
    """Reprocesar el cierre es normal en Áurea, y no puede duplicar nada."""
    connection = open_history(tmp_path / "historico.sqlite3")
    rows = [make_row(document="1019", code="D8010", date="2026-03-04")]

    first = record_batch(connection, rows, batch="2026-03")
    second = record_batch(connection, rows, batch="2026-03")

    assert first == 1
    assert second == 0          # la clave primaria lo impidió, sin lanzar
    connection.close()
```

`tmp_path` da un directorio limpio por prueba y lo borra después. No hace falta un `fake` de la
base de datos ni una capa de abstracción sobre `sqlite3`: **la base real, en un archivo temporal,
es más rápida y prueba más.** Un doble aquí probaría el doble.

### 5.6 Cobertura, con criterio

```bash
uv run pytest --cov=aur --cov-report=term-missing
```

La columna que importa no es el porcentaje: es `Missing`, que dice **qué líneas** no se
ejecutaron. Eso es un diagnóstico útil — casi siempre revela una rama de error que nadie probó.

> ⚠️ **Y el porcentaje como objetivo es una mala idea**, por la razón de siempre: una suite que
> ejecuta el 95% del código sin verificar casi nada da 95%. La cobertura mide qué se ejecutó, no
> qué se comprobó. Úsala para encontrar lo que olvidaste, no para reportarle un número a nadie.

---

## 📏 6. Medición — el verificador sobre el código que escribiste tú

Esta es la medición más convincente del curso y lo es por una razón sencilla: **no hay contra
quién discutirla**. No es un benchmark de otro sobre un código que no viste; es tu propio Bloque A.

**Hipótesis.** Al encender el verificador en modo estricto sobre código que nunca lo tuvo, la
mayoría de los errores son ruido de adopción —"falta anotar"— y una minoría pequeña son errores
reales. La minoría justifica el ejercicio.

**Condiciones.** `mypy` 2.3.1 en modo `--strict` · CPython 3.14 · sobre `aur_cli.py` tal como
queda al cerrar la Fase 06: **250 líneas**, sin una sola anotación de tipo en las firmas, con
`dataclass`, decoradores de registro, `ExceptionGroup`, `sqlite3` y `argparse`. Es el archivo del
curso, no uno de laboratorio.

**Resultado: 43 errores.** Clasificados por lo que de verdad son:

| Clase | Código de `mypy` | Cuántos | ¿Es un error? |
|---|---|---|---|
| Falta anotar la función | `no-untyped-def` | 21 | No: es el precio de entrada |
| Llamada a función sin anotar | `no-untyped-call` | 16 | No: consecuencia de lo anterior |
| Falta anotar una variable | `var-annotated` | 3 | No, y las tres son diccionarios vacíos |
| **Atributo que puede no existir** | `union-attr` | **2** | **Sí** |
| **`return` prohibido** | `misc` | **1** | **Sí, y es fatal** |

> ⚖️ **Veredicto. De 43 errores, 40 son ruido de adopción y 3 son reales — un 7%.** Ese 7% es todo
> el argumento, y conviene mirarlo de cerca porque los dos hallazgos son de naturaleza distinta.
>
> **El error fatal** es este, en el comando de validación:
>
> ```text
> aur_cli.py:229: error: "return" not allowed in except* block  [misc]
> ```
>
> `return`, `break` y `continue` **están prohibidos dentro de un bloque `except*`**, y no es una
> opinión de `mypy`: es un `SyntaxError` del intérprete. Comprobado:
>
> ```text
> SyntaxError: 'break', 'continue' and 'return' cannot appear in an except* block
> ```
>
> Es decir: el verificador encontró código que **no se puede ni ejecutar**. Y la razón por la que
> nadie lo había notado es que ese comando solo entra por esa rama cuando el lote tiene errores —
> una ruta que en las pruebas manuales del Bloque A nunca se ejercitó con un lote malo.
>
> **Los otros dos** son más sutiles y más interesantes: `group.exceptions` puede contener
> `ExceptionGroup` anidados, así que acceder a `error.line_number` sobre cada elemento no está
> garantizado. La verdad es que en el código de Áurea nunca hay anidamiento… **hoy**. El día que
> `validate_batch` agrupe a su vez grupos —que es justo lo que el ejercicio 25 de la Fase 04
> propone— la suposición deja de ser cierta y el fallo aparece lejos de la causa.
>
> **Dónde pierde el verificador, y hay que decirlo:** 40 de 43 mensajes son trabajo de anotación
> que no arregla nada roto. En un proyecto heredado de cien mil líneas, esos 40 se convierten en
> miles, y ahí está la razón real de que el tipado de Python sea **gradual**: se enciende por
> módulo, con `mypy` configurado para exigir estrictamente solo donde ya se anotó. Encenderlo todo
> de golpe en un proyecto grande es una forma eficaz de que el equipo lo apague.
>
> **El umbral, que es la respuesta útil:** para un archivo de 250 líneas que escribiste tú,
> anotarlo entero cuesta un rato y se hace de una sentada. Para un proyecto grande, la estrategia
> correcta es módulo por módulo, empezando **por donde vive el dinero** — que aquí sería `fees.py`.

**Lo que no se midió:** cuánto tarda `mypy` sobre un proyecto grande (aquí es instantáneo);
la comparación con `pyright`, que a veces encuentra cosas distintas y que la Fase 16 podría
retomar; y —lo más importante— **cuántos de los errores que el verificador NO encontró habrían
llegado a producción**. Eso no se puede medir sin un histórico de incidentes, y decir lo contrario
sería inventar.

---

## 🧱 7. Miniproyecto — *Blindar el motor de comisiones*

**El encargo**

Julián, después de la reunión trimestral: *"Édgar volvió a discutir su liquidación y esta vez
tenía razón otra vez. Son tres veces en dos años. Yo no puedo revisar la cuenta cada trimestre, y
tú tampoco vas a estar siempre. Necesito poder decirle que el cálculo está bien y que eso lo
verifica algo, no yo."*

Tipa y prueba el motor de comisiones de la Fase 03 hasta que puedas defender el número delante de
un franquiciado que lleva dos años dudando de él.

**Por qué duele**

Porque probar un cálculo de dinero con ejemplos no alcanza, y esta es la fase donde eso se hace
evidente: los ejemplos que se te ocurren son los casos que ya pensaste, y el error está en el que
no. Y porque el invariante de verdad —lo repartido suma lo cobrado— **no se puede verificar con un
caso**: es una afirmación sobre todos los repartos posibles.

**Datos de entrada**

El motor de la Fase 03 y las derivaciones del trimestre (`generar_derivaciones.py`). Más el
requisito nuevo que cambia el problema: **un caso compartido entre dos sedes se reparte entre los
profesionales que lo trabajaron**, con los porcentajes acordados — el caso de Édgar, que hace la
fase 1 en Suba y deriva la fase 3 al Centro.

**Criterios de aceptación**

- [ ] `mypy --strict` pasa limpio sobre el paquete completo, con **cero `Any`** y cero
      `# type: ignore` sin código y sin comentario que lo justifique.
- [ ] `SPECIAL_RULES` está declarado con un `Protocol`, y **demuestras** que registrar una función
      con la firma equivocada ahora falla en el verificador. Copia el mensaje.
- [ ] La suite cubre las tres reglas especiales, el aliado desconocido, y el caso del tope mensual
      justo en el límite.
- [ ] **Una prueba basada en propiedades** sobre el invariante del reparto, con al menos 300
      ejemplos. Tiene que **fallar** contra una implementación con `float` y pasar con `Decimal`:
      entrega las dos y el contraejemplo que Hypothesis encontró.
- [ ] Las pruebas corren sin tocar la red ni el disco del proyecto —`tmp_path` para lo que necesite
      archivos— y la suite completa tarda menos de cinco segundos.
- [ ] **Medición:** cuántos errores reporta `mypy --strict` sobre tu código **antes** de anotar,
      cuántos de ellos eran reales, y cuántos ejemplos necesitó Hypothesis para encontrar el
      contraejemplo del `float`. Esos tres números van en el mensaje del tag.

**Restricciones de registro**

> Esto es una **herramienta**: `src/`, tipos estrictos, pruebas, y `pyproject.toml`. La
> restricción de esta fase va en la dirección contraria a la del Bloque A: aquí **no** se vale
> resolver con un script suelto, y tampoco se vale dejar una función sin tipar "porque es
> obvia". Lo que sí sigue prohibido es la ceremonia: si te descubres escribiendo una clase base
> abstracta para las reglas especiales, el `Protocol` de §5.2 es exactamente lo que la reemplaza.

**La trampa**

`Decimal` no te salva solo. Vas a cambiar `float` por `Decimal` en el reparto, la prueba de
propiedades va a seguir fallando, y ahí está la lección: **el problema no era el tipo, era
redondear cada parte por separado.** Tres partes redondeadas a dos decimales no tienen por qué
sumar el total, use el tipo que use. Hay que decidir **quién se queda el residuo**, y esa es una
pregunta que el código no puede contestar solo.

Y hay una segunda, más incómoda: cuando el caso se reparte **entre sedes** y una es franquiciada,
el residuo que le des a uno u otro cambia la regalía. Con tres partes y un peso, da igual; con
1.400 derivaciones al trimestre, es plata. El ejercicio 23 lo cuantifica.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Empieza por correr `mypy --strict` **antes de anotar nada** y guarda la salida en un archivo: es
la mitad de tu medición y no se puede recuperar después.

Después anota de adentro hacia afuera: primero las funciones puras del cálculo, que son las que
importan y las que no dependen de nada. Las de E/S al final.

Y para la prueba de propiedades, escríbela **antes** de arreglar el reparto. Verla fallar con un
contraejemplo concreto es el punto del ejercicio.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [`typing.Protocol`](https://docs.python.org/3.14/library/typing.html#typing.Protocol) y
  `Callable` para el decorador de registro.
- [`decimal.Decimal.quantize`](https://docs.python.org/3.14/library/decimal.html#decimal.Decimal.quantize)
  y los modos de redondeo: `ROUND_HALF_UP` es el que usa la contabilidad colombiana, y **no** es el
  que Python usa por defecto (que es `ROUND_HALF_EVEN`). Ese detalle solo vale dinero.
- [`hypothesis.strategies.decimals`](https://hypothesis.readthedocs.io/en/latest/data.html) con
  `places=2`, y `@settings(max_examples=...)`.
- [`pytest.raises`](https://docs.pytest.org/en/stable/how-to/assert.html) y la fixture
  `tmp_path`.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
class SpecialRule(Protocol):
    def __call__(self, value: Decimal, specialty: str,
                 month_to_date: Decimal, rate: Decimal) -> Decimal: ...

def split_fee(total: Decimal, shares: Sequence[Decimal]) -> list[Decimal]:
    """Reparte sin perder un peso. Decide quién se queda el residuo."""

# tests/test_fees.py
@given(total=money, shares=...)
def test_lo_repartido_suma_lo_cobrado(total, shares) -> None: ...
```

Y una pregunta para la prueba de propiedades, que sube bastante la dificultad: ¿puedes generar
también los **porcentajes** con Hypothesis, en vez de fijarlos, garantizando que sumen 1?
</details>

**Cómo se entrega**

```bash
uv run mypy --strict src/ > mypy-antes.txt     # ¡antes de anotar!
# ... anotar ...
uv run mypy --strict src/
uv run pytest -q
```

```bash
git add src/ tests/ pyproject.toml mypy-antes.txt
git commit -m "fase 08 mini: motor de comisiones tipado y blindado"
git tag -a mini-08 -m "Mini F8: comisiones blindadas · <N> errores de mypy, <M> reales · Hypothesis lo encontró en <K> ejemplos"
```

<details><summary>💡 Solución de referencia — la decisión, la trampa y el residuo</summary>

**La decisión de diseño que se tomó.** El residuo va al **último** de la lista, y la lista se
ordena por quién ejecuta la última fase del plan. El otro camino defendible —repartir el residuo
centavo a centavo entre todos, en orden— es más justo y es lo que hacen algunos sistemas
contables; se descartó porque produce números con más decimales de los que la factura admite y
porque **la regla tiene que poder explicársele a Édgar en una frase**. "El que cierra el caso se
queda el residuo" es una frase; "el residuo se distribuye cíclicamente" es una discusión.

Y esa decisión hay que **escribirla en el código**, no solo implementarla: el docstring de
`split_fee` es donde vive el acuerdo comercial.

**La trampa, entera.** Cambiar `float` por `Decimal` no arregla nada por sí solo, y es la
confusión más común sobre `Decimal`: no es que `float` "pierda precisión" en abstracto, es que
**redondear tres partes por separado no tiene por qué reconstruir el total**, en cualquier tipo. Lo
que `Decimal` te da es que cuando *sí* decides bien —repartir y dar el residuo— el resultado es
exacto, mientras que con `float` ni siquiera eso alcanza, porque `2485.99 + 2175.24 + 1553.74` no
es exactamente lo que crees.

El contraejemplo que Hypothesis encuentra —`Decimal('6214.97')`, partes que suman
`6214.969999999999`— es la clase de valor que nadie pone en una prueba a mano. Y lo encuentra en
menos de 300 ejemplos porque reduce: no reporta el primer valor que falla, sino el más pequeño y
simple que sigue fallando.

**Qué se habría hecho distinto si el registro fuera otro.** Como script, nada de esto existiría y
el error habría salido en una liquidación — que es exactamente lo que pasó tres veces en dos años
en Áurea. Como aplicación, el reparto viviría en una transacción con su rastro de auditoría fila
por fila, y el invariante sería además una **restricción de la base de datos**: la suma de los
repartos de un caso tiene que igualar el cobro, comprobado en el momento de escribir y no solo en
las pruebas. Eso es la Fase 11, y es más fuerte que cualquier suite.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Corre `mypy --strict` sobre tu propio código del Bloque A y clasifica los errores como hace la
   sección 6. Reporta tus dos números: total y reales.
2. Anota `summarize` y `render` completos, con el tipo de retorno. Comprueba que el error de
   `no-untyped-call` desaparece también en quien las llama.
3. Escribe una prueba con `pytest` para `parse_amount` con los tres formatos de valor de la Fase
   06. Usa `parametrize`.
4. Convierte una prueba escrita como clase `unittest.TestCase` a una función de `pytest`. Anota
   qué desapareció.
5. Usa `pytest.raises` para verificar que `validate_row` rechaza una fila sin documento, y
   comprueba el atributo `field` del error.
6. Usa `tmp_path` para probar `open_history` sin ensuciar el proyecto. Comprueba que el archivo
   deja de existir después.

**🟡 Intermedio (7–14)**

7. Declara `SPECIAL_RULES` con un `Protocol` e intenta registrar una función con los parámetros al
   revés. Copia el mensaje del verificador y explícalo.
8. Averigua qué hace `reveal_type(x)` en `mypy` y úsalo para descubrir qué tipo cree el verificador
   que tiene el resultado de `tomllib.load`.
9. Agrega una fixture en `conftest.py` y úsala desde dos archivos de prueba distintos. Explica por
   qué no hay que importarla.
10. Usa `monkeypatch` para que una prueba no toque el reloj del sistema: sustituye la función que
    da la fecha y verifica un cálculo que depende del mes.
11. Escribe un `TypedDict` para la estructura de `tarifas.toml` y usa `mypy` para comprobar que
    accedes a una llave que no existe.
12. Consulta la documentación de `hypothesis` sobre `assume()` y úsalo para descartar los casos de
    entrada que tu función no promete manejar. Después discute si eso es honesto o si estás
    escondiendo un caso.
13. Corre la cobertura con `--cov-report=term-missing` y encuentra una rama de error que ninguna
    prueba ejecuta. Escríbele la prueba.
14. Averigua la diferencia entre `list[str]` y `Sequence[str]` en un parámetro, y demuestra con
    `mypy` un caso donde la segunda acepta algo que la primera rechaza.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** `mypy` pasa limpio y el programa falla en ejecución con un `TypeError`.
    Construye tres escenarios donde eso ocurra: uno con datos de un archivo, uno con una
    biblioteca sin anotaciones, y uno con un `cast` mal hecho. Explica qué tienen en común.
16. **Diagnóstico.** Una prueba pasa siempre, incluso cuando el código está mal. Hay al menos tres
    formas de escribir una prueba así —una tiene que ver con un mock, otra con un `assert` que no
    se ejecuta, y otra con una aserción que compara algo consigo mismo—. Escribe las tres y
    explica cómo detectarlas.
17. **Medición.** Cronometra la suite completa y encuentra la prueba más lenta con
    `pytest --durations=10`. Decide si vale lo que cuesta.
18. **Medición.** Mide cuántos ejemplos necesita Hypothesis para encontrar el contraejemplo del
    `float`, corriéndolo diez veces con semillas distintas. Reporta la mediana y el peor caso.
19. **Medición.** Compara `mypy` con `pyright` sobre el mismo código: cuántos errores encuentra
    cada uno, cuánto tardan, y si alguno encuentra algo que el otro no. Declara la versión de los
    dos.
20. **De registro.** Julián pregunta si "se puede probar que el sistema está bien". Escribe la
    respuesta honesta, en media página, distinguiendo qué garantiza una suite, qué garantiza el
    verificador, y qué no garantiza ninguno de los dos. Es la respuesta que vas a dar muchas veces
    en tu carrera.
21. **De registro.** Un script de veinte líneas que corres una vez al mes: ¿merece tipos y
    pruebas? Aplica el criterio de las cinco señales de la Fase 07 y responde con su costo. **La
    respuesta esperada es que no**, y el ejercicio es defenderlo sin que suene a excusa.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe código que `mypy --strict` apruebe y que esté claramente mal. Hay al
    menos cuatro caminos: `Any` colado por una biblioteca, un `cast`, un `# type: ignore`, y datos
    externos sin validar. Documenta los cuatro con el fallo que producen en ejecución.
23. **Adversarial y de dinero.** Toma las 1.400 derivaciones del trimestre y calcula la
    liquidación repartiendo el residuo de tres formas: al primero, al último, y distribuido.
    Cuantifica la diferencia total para el aliado más activo y para el franquiciado de Suba.
    Decide cuál defenderías delante de Édgar.
24. **Defiende una decisión.** Un colega dice que el tipado en Python es "teatro" porque no
    garantiza nada en ejecución, y que prefiere pruebas. Escribe la respuesta con las dos caras,
    incluyendo el dato de la sección 6 —tres errores reales de cuarenta y tres— y sé honesto sobre
    lo que ese dato no prueba.
25. **Diseño.** Escribe una propiedad más para el dominio de Áurea, tan fuerte como la del reparto,
    y pruébala con Hypothesis. Candidatas: el consolidado nunca factura dos veces el mismo
    procedimiento; el tope mensual nunca se excede sin importar el orden; la suma por sede iguala
    el total. Elige una que **el código actual pueda violar** y demuéstralo.

**🔥 Opcionales**

- Investiga `mypy --html-report` y mira qué módulos están mejor y peor tipados. Es el mapa de por
  dónde seguir en un proyecto grande.
- Averigua qué es el *mutation testing* (`mutmut`, `cosmic-ray`), córrelo sobre el motor de
  comisiones, y mira cuántas mutaciones sobreviven a tu suite. Es la forma honesta de medir una
  suite, y es cara.
- Lee sobre `typing.assert_never` y úsalo para que el verificador te obligue a cubrir todos los
  casos de un `match` sobre un `Enum`. Es lo más cerca que estarás del `switch` exhaustivo de
  Java.

---

## 📚 9. Referencias

**Documentación oficial**

- [`typing`](https://docs.python.org/3.14/library/typing.html) — la referencia; `Protocol`,
  `TypedDict`, `Final`, `assert_never`.
- [Documentación de `mypy`](https://mypy.readthedocs.io/) — en particular *Common issues* y la
  guía de adopción en proyectos existentes, que es la respuesta al problema de los 40 errores de
  ruido.
- [Documentación de `pytest`](https://docs.pytest.org/) — *How-to guides*, empezando por fixtures
  y `parametrize`.
- [Documentación de `hypothesis`](https://hypothesis.readthedocs.io/) — estrategias, `settings`, y
  la explicación de cómo reduce los contraejemplos.
- [`decimal` — modos de redondeo](https://docs.python.org/3.14/library/decimal.html) — y por qué el
  valor por defecto es `ROUND_HALF_EVEN`.

**PEPs**

- [PEP 484](https://peps.python.org/pep-0484/) — el tipado gradual, y **su propia declaración de
  que no se comprueba en ejecución**. Vale la pena leer esa parte literal.
- [PEP 544](https://peps.python.org/pep-0544/) — `Protocol`.
- [PEP 695](https://peps.python.org/pep-0695/) — la sintaxis nueva de genéricos.
- [PEP 589](https://peps.python.org/pep-0589/) — `TypedDict`.

**Libros / artículos**

- *Robust Python*, de Patrick Viafore — el libro que trata el tipado como decisión de diseño y no
  como sintaxis. Verifica la edición.

**Orden de lectura sugerido.** Antes de escribir: la guía de `pytest` sobre fixtures, que es lo
que más cambia respecto a JUnit. Durante: `typing` y `mypy`, consultados. Después: el PEP 484 en
la parte donde explica qué **no** promete — se lee distinto cuando ya viste los 43 errores.

> ⚠️ URLs y contenidos cambian; fija las versiones que usa esta fase.

---

## 🚀 10. Cierre y conexión con la siguiente fase

El proyecto tiene sus dos redes, y —lo más importante— sabes qué atrapa cada una y qué no. El
verificador atrapó un error que **no se podía ni ejecutar** y que llevaba dos fases escondido en
una rama que nadie ejercitó; la prueba de propiedades encontró un valor que nadie habría elegido a
mano. Ninguna de las dos habría encontrado lo de la otra.

Y te llevas la respuesta a la pregunta que te van a hacer muchas veces: *"¿se puede probar que
esto está bien?"*. La respuesta honesta es que no, y que lo que sí se puede es **acotar lo que
puede estar mal**: el verificador acota las firmas, la suite acota el comportamiento que
verificaste, y la validación en la frontera —que llega en la Fase 10— acota lo que entra. Los tres
juntos no son una garantía; son tres redes con agujeros de distinto tamaño, puestas una encima de
otra.

La **Fase 09** ⭐ cierra el Bloque B con la pregunta que queda: **cómo le entregas esto a
Patricia**. Tienes una herramienta con tipos, pruebas, un lockfile y un ejecutable — todo eso
funciona en tu máquina y en la de alguien que tenga `uv` y una terminal. Ella no tiene ninguna de
las dos cosas.

> **La señal de que quedó bien:** cuando alguien te diga que su código "está tipado", tu primera
> pregunta no va a ser cuál verificador — va a ser si alguien lo corre en el CI.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-08 -m "F8 cerrada:
> - mypy --strict pasa limpio sobre src/aur, sin Any y sin ignores pelados
> - los 43 errores de la primera corrida clasificados: 40 de adopción, 3 reales
> - el return dentro de except* encontrado y corregido: no se podía ejecutar
> - SPECIAL_RULES declarado con Protocol: la firma equivocada ya no compila
> - suite de pytest con fixtures, parametrize y tmp_path, bajo cinco segundos
> - la propiedad del reparto verificada con 300 ejemplos, con su contraejemplo documentado"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 08: …`), los de ejercicio su número
> (`fase 08 ej12: …`) y el miniproyecto el suyo (`fase 08 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-08`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
