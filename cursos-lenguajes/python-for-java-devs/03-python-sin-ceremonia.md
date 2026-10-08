# 🎩 Fase 03 — Python sin ceremonia

> Python para desarrolladores Java senior · Fase 3 de 18 · Bloque A
> Depende de: Fase 02 · Habilita: Fase 04
> Registro de esta fase: **script** — un archivo, stdlib pura
> Proyecto que avanza: el CLI · **nace el motor de comisiones**
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Quitar la ceremonia. Que escribas una función donde escribirías una clase, una `dataclass` donde
escribirías una jerarquía, y una tabla de datos donde escribirías un patrón.

Esta es **la fase más densa del curso** y lo es a propósito: funciones y objetos van juntos
porque atacan **un solo reflejo**, y separarlos lo dejaría a medias. Si el capítulo de funciones
dijera "usa un decorador en vez de una clase" y el de objetos dijera "usa una `dataclass` en vez
de una jerarquía", el lector aprendería dos trucos. Juntos, aprende una cosa: **en Python la
estructura se gana, no se paga por adelantado.**

---

## ✅ 2. Qué queda listo al terminar

- [ ] Puedes mirar una clase con un solo método y reescribirla como función sin pensarlo.
- [ ] Sabes escribir un decorador que preserve la identidad de la función que envuelve, y explicar
      qué se rompe si olvidas `functools.wraps`.
- [ ] Usas `dataclass` con criterio: sabes cuándo `frozen`, cuándo `slots`, y cuándo un `dict`
      basta — con el número de la sección 6 delante.
- [ ] Puedes declarar un `Protocol` y explicar por qué nadie tiene que declarar que lo implementa.
- [ ] Las filas del CLI son `dataclass` y el código que las usa se lee mejor que con tuplas.
- [ ] El motor de comisiones existe, calcula los veintitrés aliados, y **agregar el aliado
      veinticuatro no toca ninguna línea existente**.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Validación de datos que vienen de afuera** → Fase 10, con Pydantic y la idea de validar en la
  frontera. Hoy los datos vienen de un archivo que asumimos bien formado, y cuando no lo está,
  revienta.
- **Manejo de errores** → Fase 04. El motor de comisiones de hoy lanza `KeyError` si el aliado no
  existe, y eso es todo.
- **Tipos verificados** → Fase 08. Vas a escribir anotaciones porque ayudan a leer; nadie las
  comprueba todavía.
- **Metaclases y descriptores.** Se cierran aquí, en una línea cada uno: una **metaclase** es una
  clase que crea clases, la usan los frameworks para registrar cosas automáticamente —Django y
  Pydantic la usan— y tú no la vas a escribir; un **descriptor** es el mecanismo detrás de
  `property` y de los campos de un ORM, y también lo vas a consumir sin escribirlo. Si algún día
  necesitas uno de los dos, lo vas a saber porque habrás agotado todo lo demás. No son de este
  curso.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

Esta fase tiene **un solo reflejo**, y por eso funciones y objetos van juntos: **la ceremonia**.
La creencia, perfectamente razonable donde te la enseñaron, de que el código serio necesita
estructura declarada por adelantado — una clase para agrupar, una interfaz para desacoplar, una
jerarquía para extender.

Se manifiesta en cuatro formas, y las cuatro son la misma:

#### La clase con un solo método

```python
# ❌ Lo que sale solo
class ReferralFeeCalculator:
    def __init__(self, rate):
        self._rate = rate

    def calculate(self, value):
        return value * self._rate

calculator = ReferralFeeCalculator(Decimal("0.15"))
fee = calculator.calculate(Decimal("1000000"))
```

```python
# ✅ Lo mismo
def referral_fee(value, rate):
    return value * rate

fee = referral_fee(Decimal("1000000"), Decimal("0.15"))
```

Si lo que quieres es fijar el `rate` y pasar la función por ahí —que es lo que la clase estaba
haciendo— eso también existe y tiene nombre:

```python
from functools import partial

neira_fee = partial(referral_fee, rate=Decimal("0.15"))
fee = neira_fee(Decimal("1000000"))
```

**Por qué la clase falla aquí y no allá:** en Java, una función suelta no existe. Para pasar
comportamiento necesitas un objeto, y por eso `Comparator`, `Runnable` y media biblioteca son
interfaces de un solo método. La clase no es ceremonia allá: **es el único vehículo disponible**.
En Python las funciones son objetos de primera clase —se asignan, se pasan, se guardan en
diccionarios, se devuelven— así que la clase deja de ser el vehículo y pasa a ser un envoltorio
alrededor de un `self._rate` que nadie necesita.

#### La jerarquía con un `AbstractBase` arriba

Es el mismo reflejo con tres niveles, y la sección 6 lo mide: el mismo cálculo escrito como
jerarquía de estrategias son **54 líneas y 7 clases**; escrito con una tabla de datos y tres
funciones, **22 líneas y ninguna clase**. Los dos producen exactamente los mismos números —se
verificó antes de medir.

#### Los getters y setters sobre atributos públicos

```python
# ❌ Traducción literal de un POJO
class Partner:
    def __init__(self, name):
        self._name = name

    def get_name(self):
        return self._name

    def set_name(self, value):
        self._name = value
```

En Python un atributo es público y se accede directo: `partner.name`. Y si algún día necesitas
interceptar el acceso —validar, calcular, registrar— **puedes hacerlo sin cambiar a quien lo
usa**, convirtiéndolo en `property`:

```python
class Partner:
    def __init__(self, name):
        self.name = name          # público, y así se queda

    @property
    def display_name(self):       # se lee como atributo: partner.display_name
        return self.name.title()
```

Esa es la diferencia de fondo: en Java el getter existe porque **cambiar de campo a método rompe
a quien te usa**, así que se paga el costo desde el día uno por si acaso. En Python ese cambio es
invisible desde afuera, así que el "por si acaso" no compra nada. Escribir getters aquí es pagar
un seguro contra un riesgo que no existe.

#### La interfaz que alguien tiene que declarar que implementa

En Java, para que algo encaje en un hueco, su autor tuvo que saber del hueco: `implements
Comparable`. Si la clase es de una biblioteca de terceros y no lo declaró, no encaja, y hay que
envolverla.

En Python el encaje es **estructural**: si tiene los métodos, sirve. Esto no es tipado débil — se
puede declarar explícitamente con `Protocol`, y el verificador de la Fase 08 lo comprueba:

```python
from typing import Protocol

class RowValidator(Protocol):
    """Cualquier cosa que sepa validar una fila. Nadie declara que implementa esto."""

    def __call__(self, row: "Row") -> str | None:
        """Devuelve el motivo del rechazo, o None si la fila está bien."""
```

Una función suelta cumple ese `Protocol`. Una clase con `__call__` también. Un objeto de una
biblioteca que nunca oyó hablar de tu código, también. **No hace falta que nadie se entere.**

> 🧭 **La regla que resume las cuatro:** en Python la estructura se agrega **cuando el código la
> pide**, y agregarla después no rompe a quien te usa. Por eso empezar sin ella no es descuido:
> es el orden correcto. Es exactamente la misma idea de la Fase 07 —el archivo antes que el
> proyecto— aplicada un nivel más abajo.

### Esto sí funciona igual

Y en esta fase importa mucho decirlo, porque lo anterior suena a que tu oficio sobra. No sobra:

**Tu criterio de diseño se transfiere intacto.** Cohesión, acoplamiento, una razón para cambiar,
nombres que dicen la verdad, la desconfianza sana hacia el estado compartido. Nada de eso cambia,
y es el 80% de lo que hace bueno a un diseño. Lo que cambia es **cuánto código cuesta expresarlo**.

**Los patrones que conoces siguen siendo válidos** — solo que varios de ellos se vuelven
invisibles. Strategy es un diccionario de funciones. Factory es una función que devuelve algo.
Decorator tiene sintaxis propia. Singleton es un módulo, porque los módulos se importan una sola
vez. Command es una función. Que no se vean **no significa que no estén**: significa que el
lenguaje ya los trae, y reconocerlos en su forma pythónica es lo que te separa de alguien que
lleva dos meses.

**Y hay un sitio donde la clase es exactamente la respuesta correcta**, y esta fase no lo
esconde: cuando hay **estado que varios métodos comparten y mutan**, cuando hay un ciclo de vida
—abrir, usar, cerrar—, o cuando necesitas varias implementaciones intercambiables **de verdad**,
con más de un método cada una. Una conexión, un cliente HTTP con su sesión, un acumulador con
reglas. Ahí se escribe una clase sin pedir perdón. La regla no es "no uses clases": es "no uses
una clase donde una función alcanza".

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| Interfaz de un método (`Comparator`) | una función | No hace falta envolverla: la función **es** el valor |
| `record Partner(String id, BigDecimal rate)` | `@dataclass(frozen=True, slots=True)` | El `dataclass` es mutable salvo que lo congeles, y su igualdad la decides campo por campo |
| `implements Comparable` | `Protocol` | Estructural: nadie declara que lo implementa, y el verificador lo comprueba igual |
| Clase abstracta con estado | clase base normal, o composición | Existe `ABC`, y se usa mucho menos de lo que crees |
| `static` | función a nivel de módulo | El módulo **es** el espacio de nombres. No hace falta una clase para agrupar |
| Singleton | un módulo | Se importa una sola vez por proceso; no hay que escribir nada |
| Strategy | `dict[str, Callable]` | Registrar es una línea, no una clase nueva |
| Builder | argumentos con valor por defecto, o `dataclass` | Casi siempre innecesario: los parámetros por nombre ya hacen el trabajo |
| Decorador (patrón) | `@decorador` (sintaxis) | Aquí es del lenguaje, no un patrón que se arma a mano |
| `equals` / `hashCode` / `toString` | `__eq__` / `__hash__` / `__repr__` | `dataclass` los genera, y el contrato entre los dos primeros es idéntico |
| `@FunctionalInterface` + lambda | una función, y ya | Las lambdas de Python son de **una sola expresión**, y eso es deliberado |
| `Optional<T>` en la firma | `T \| None` | Anotación, no envoltorio |

> 📝 **Nota de ecosistema — de dónde salió `dataclass`, y qué reemplazó.** Antes de 3.7 hacer una
> clase de datos decente eran veinte líneas de `__init__`, `__eq__` y `__repr__` escritos a mano,
> o la biblioteca `attrs`, que era —y sigue siendo— excelente. `dataclasses` llegó en 3.7
> inspirado directamente en `attrs` y se llevó el 90% de los casos. Vas a encontrar las tres
> formas vivas: `attrs` en proyectos serios que necesitan lo que trae de más, `NamedTuple` donde
> se quería inmutabilidad antes de que `frozen=True` existiera, y clases a mano en código
> anterior a 2018. `slots=True` es lo más nuevo de la lista —3.10— y la sección 6 mide qué compra.

### Decoradores: qué son de verdad

Un decorador es **una función que recibe una función y devuelve otra**. La sintaxis `@` es azúcar
para una reasignación, y verlo escrito sin azúcar lo desmitifica del todo:

```python
@timed
def build_report(path): ...

# es exactamente lo mismo que:
def build_report(path): ...
build_report = timed(build_report)
```

Eso es todo. Lo que lo hace útil es que las funciones son objetos: se pueden envolver.

```python
import functools
import time


def timed(function):
    """Registra cuánto tardó la función. El envoltorio más útil del curso."""

    @functools.wraps(function)          # ← sin esto, el envoltorio suplanta al envuelto
    def wrapper(*args, **kwargs):
        started = time.perf_counter()
        try:
            return function(*args, **kwargs)
        finally:
            elapsed = (time.perf_counter() - started) * 1000
            print(f"{function.__name__}: {elapsed:.0f} ms")
    return wrapper
```

**`functools.wraps` no es opcional y conviene ver qué pasa sin él:** el objeto que queda en el
nombre `build_report` es `wrapper`, así que `build_report.__name__` dice `"wrapper"`, el
docstring desaparece, y `help()` no sirve. Peor: las herramientas que dependen de esos metadatos
—incluidos los frameworks de la Fase 10, que leen la firma para construir la documentación de la
API— se rompen sin decir por qué. Una línea.

**`functools.lru_cache`** es el decorador que más rendimiento compra por carácter escrito:
memoiza los resultados de una función pura. Y viene con su advertencia: guarda todo lo que le
pidas hasta el tope, las llaves tienen que ser *hashables* —Fase 01— y sobre una función que no
es pura produce datos viejos sin avisar.

### `dataclass`, y cuándo no

```python
from dataclasses import dataclass, field
from decimal import Decimal


@dataclass(frozen=True, slots=True)
class Row:
    """Una fila del export de Odontovía."""

    document: str
    patient: str
    branch: str
    date: str
    code: str
    amount: Decimal
```

Seis líneas dan `__init__`, `__repr__`, `__eq__` campo por campo, y —por `frozen=True`—
`__hash__` y la imposibilidad de modificarla después de crearla.

Las tres opciones que importan:

**`frozen=True`** la hace inmutable y *hashable*. Es lo que quieres para datos que viajan por tu
programa, y es la respuesta directa al problema de la copia superficial de la Fase 01: una fila
congelada no necesita copia defensiva.

**`slots=True`** le quita el `__dict__` al objeto: los campos viven en un arreglo fijo. Cuesta
que no puedes agregarle atributos al vuelo —cosa que no querías hacer— y compra memoria y
velocidad de acceso. La sección 6 dice cuánto.

**`field(default_factory=list)`** es cómo se declara un valor por defecto mutable sin cometer el
error de la Fase 01. De hecho `dataclass` **se niega** a que escribas `items: list = []` y lanza
un error en tiempo de definición. Es de los pocos sitios donde el lenguaje te protege de esa
trampa.

Y cuándo **no**: si son dos campos que nunca salen de tres líneas de código, una tupla está bien.
Si el dato viene de afuera y hay que validarlo, la respuesta es la Fase 10. Si lo que tienes es
una bolsa de llaves dinámicas que ni siquiera conoces al escribir el código, un `dict` es
correcto — pero mide antes de decidirlo por comodidad, porque la sección 6 tiene una sorpresa.

### Herencia y MRO, o por qué casi nunca

Python tiene herencia múltiple, y por lo tanto tiene un problema que Java no: si dos padres
definen lo mismo, ¿cuál gana? Lo resuelve el **MRO** —el orden de resolución de métodos—, que es
un algoritmo determinista y que puedes consultar con `Clase.__mro__`.

Te lo cuento en tres líneas y no más, porque **la conclusión práctica es que no lo necesitas**:
si tu jerarquía es tan profunda que el MRO importa, el problema es la jerarquía. Y `super()` en
herencia múltiple no significa "mi padre": significa "el siguiente en el MRO", que puede ser un
hermano. Ahí es donde la gente se pierde.

Lo que se usa en su lugar, en orden de frecuencia: **composición** —un objeto que tiene otro—,
**funciones**, y **`Protocol`** cuando de verdad hacen falta varias implementaciones. La herencia
queda para cuando heredas de algo de la biblioteca estándar o de un framework que la exige: una
excepción propia de la Fase 04 hereda de `Exception`, y un modelo de Django hereda de `Model`. Ahí
es correcta y no hay nada que discutir.

---

## 💻 5. Código mínimo con comentarios

### 5.1 La fila deja de ser una tupla

En la Fase 01 las filas eran tuplas y `row[AMOUNT]` se leía gracias a una constante. Con seis
columnas todavía funciona; con la séptima que llega en la Fase 06, deja de funcionar.

Es también la respuesta al ejercicio 24 de la Fase 01, que preguntaba cuál era la señal concreta
para darle una clase a la fila. No era el gusto por los tipos: era que **el registro cambie de
forma** —una columna nueva desplaza cada `row[N]` sin un solo error— y que **se lea por nombre en
más de un sitio**. Las dos cosas pasan ahora; antes, la tupla era la decisión correcta.

```python
from dataclasses import dataclass
from decimal import Decimal


@dataclass(frozen=True, slots=True)
class Row:
    """Una fila del export de Odontovía.

    frozen: nadie la modifica después de leída, y por lo tanto nadie necesita
            copiarla defensivamente (la lección de la Fase 01).
    slots:  sin __dict__ por instancia. Sobre 482.074 filas la diferencia es
            real y está medida en la sección 6.
    """

    document: str
    patient: str
    branch: str
    date: str
    code: str
    amount: Decimal


def read_rows(path):
    """Produce las filas de a una, ya convertidas.

    💸 DEUDA INTENCIONAL — se paga en la Fase 06: seguimos partiendo por comas
    a mano, y eso se rompe con el primer nombre que traiga una coma adentro.
    """
    with open(path, encoding="utf-8") as file:
        next(file)
        for line in file:
            line = line.strip()
            if not line:
                continue
            document, patient, branch, date, code, amount = line.split(",")
            # La conversión ocurre en un solo sitio: de aquí en adelante,
            # `amount` es un Decimal y nadie vuelve a preguntárselo.
            yield Row(document, patient, branch, date, code, Decimal(amount))
```

**Detalles con intención**

- **Desapareció el bloque de constantes `DOCUMENT, PATIENT, ...`** de la Fase 01. Los nombres
  ahora están donde deben estar: en el tipo. `row.amount` no necesita una constante que lo
  explique.
- **La conversión a `Decimal` se mudó a la lectura.** Antes cada función que tocaba el dinero
  hacía su propio `Decimal(row[AMOUNT])`; ahora se hace una vez, en el borde. Es la misma idea que
  la Fase 10 va a llamar *validar en la frontera*, en su versión de script.
- **Sigue siendo un generador** (Fase 02) y sigue sin manejar errores (Fase 04). Una cosa por vez.
- **Y sigue siendo un archivo sin clases decorativas**: `Row` no tiene métodos. Es un registro, y
  eso es todo lo que tiene que ser.

### 5.2 Los comandos del CLI, con un decorador

En la Fase 01 el despacho era un `if`. Con cuatro comandos ya pesa, y el reflejo de Java sería una
jerarquía de `Command` con su `execute()`. Aquí son ocho líneas:

```python
COMMANDS = {}


def command(name):
    """Registra un comando del CLI. Agregar uno no toca este bloque."""
    def register(function):
        COMMANDS[name] = function
        return function      # devolver la función original: el decorador solo registra
    return register


@command("resumen")
def summary_command(args):
    """Resumen del mes de una sede."""
    print(render(summarize(read_rows(args[0])), args[0]))


@command("consolidado")
def consolidated_command(args):
    """Consolidado de las diez sedes."""
    ...
```

Y el despacho, completo:

```python
if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(f"uso: python aur_cli.py <{' | '.join(COMMANDS)}> [...]", file=sys.stderr)
        sys.exit(2)
    COMMANDS[sys.argv[1]](sys.argv[2:])
```

**El patrón a memorizar**

> Un diccionario de funciones **es** el patrón Strategy, y registrar una estrategia nueva es una
> línea que se agrega en vez de un archivo que se modifica. Cuando veas venir una jerarquía de
> clases con un solo método cada una, pregúntate qué pasaría si fuera un diccionario.

### 5.3 El motor de comisiones

Veintitrés aliados, cada uno con su porcentaje, y tres que no encajan. El reflejo de Java produce
una jerarquía de estrategias; lo que el problema pide es otra cosa, y conviene ver por qué.

**La observación que ordena todo el diseño: veinte de los veintitrés aliados no tienen regla —
tienen un número.** Un porcentaje. Eso no es comportamiento, es **dato**, y el dato no va en
código.

```python
"""El motor de comisiones de aliados. Una tabla de datos y tres excepciones."""

from decimal import Decimal

# Los veinte aliados ordinarios no son código: son datos. En la Fase 06 esta
# tabla se va a leer de un archivo TOML y entonces agregar el aliado 24 no va a
# tocar ni una línea de Python. Hoy es un diccionario y ya no es una jerarquía.
PARTNER_RATES: dict[str, Decimal] = {
    "P001": Decimal("0.15"),
    "P002": Decimal("0.12"),
    "P003": Decimal("0.20"),
    "P004": Decimal("0.10"),
    "P005": Decimal("0.18"),
    "P006": Decimal("0.10"),
    # ... hasta P023
}

# Y las tres excepciones son tres funciones, registradas con un decorador.
SPECIAL_RULES: dict[str, object] = {}


def rule_for(partner_id):
    """Registra la regla especial de un aliado.

    Agregar una regla nueva es escribir una función más abajo: no se modifica
    ninguna línea existente, que es exactamente lo que el encargo pide.
    """
    def register(function):
        SPECIAL_RULES[partner_id] = function
        return function
    return register


@rule_for("P004")
def minimum_per_case(value, specialty, month_to_date, rate):
    """Neira cobra un mínimo por caso, por barato que salga el tratamiento."""
    return max(value * rate, Decimal("150000"))


@rule_for("P005")
def monthly_cap(value, specialty, month_to_date, rate):
    """Buitrago negoció un tope mensual: pasado ese punto, no se causa más."""
    return min(value * rate, max(Decimal("2000000") - month_to_date, Decimal("0")))


@rule_for("P006")
def by_specialty(value, specialty, month_to_date, rate):
    """Cárdenas cobra distinto según la especialidad del procedimiento."""
    rates = {"implantologia": Decimal("0.20"), "endodoncia": Decimal("0.12")}
    return value * rates.get(specialty, rate)


def referral_fee(partner_id, value, specialty="", month_to_date=Decimal("0")):
    """La comisión que Áurea le factura a un aliado por un caso derivado.

    Es toda la interfaz pública del motor: una función.
    """
    rate = PARTNER_RATES[partner_id]
    rule = SPECIAL_RULES.get(partner_id)
    return rule(value, specialty, month_to_date, rate) if rule else value * rate
```

**Detalles con intención**

- **`Decimal` en todo**, construido desde texto, y las tasas también. Esto se reparte entre tres
  profesionales y dos sedes: es donde el redondeo de un `float` se convierte en la discusión
  trimestral con Édgar.
- **La regla especial recibe el `rate` como parámetro** en vez de leerlo de la tabla. Así la
  función no sabe de dónde salió el número y se puede probar sola — que es lo que la Fase 08 va a
  hacer.
- **`month_to_date` entra como parámetro y no como estado.** El tope mensual necesita saber
  cuánto lleva causado el aliado, y ese es justo el dato que tentaría a hacer una clase con
  estado. Pasarlo como argumento mantiene la función pura y comprobable.
- **Y no hay `PolicyFactory`.** El diccionario `SPECIAL_RULES` es la fábrica, `get` es el `lookup`,
  y el `if` de la última línea es el despacho.

> ⚠️ **El tope mensual esconde un problema de orden que esta fase no resuelve.** Si el aliado
> P005 tiene tres casos en el mes y el tope se alcanza en el segundo, el resultado depende de en
> qué orden se procesen. Hoy funciona porque el CLI los procesa en el orden del archivo — y eso
> es una garantía frágil que nadie escribió. Anótalo: la Fase 15 lo vuelve a encontrar cuando el
> proceso nocturno sea reanudable, y ahí habrá que decidirlo de verdad.

**Prueba de fuego**

```python
>>> referral_fee("P001", Decimal("1000000"))
Decimal('150000.00')
>>> referral_fee("P004", Decimal("500000"))              # mínimo por caso
Decimal('150000')
>>> referral_fee("P005", Decimal("1000000"), month_to_date=Decimal("1900000"))
Decimal('100000')                                         # el tope corta en 2.000.000
>>> referral_fee("P006", Decimal("1000000"), "implantologia")
Decimal('200000.00')
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: fíjate en que unos
resultados traen `.00` y otros no. `Decimal('150000.00')` y `Decimal('150000')` **son iguales**
(`==` da `True`) pero se ven distinto y **no son intercambiables al imprimir ni al escribir un
archivo**. La cantidad de decimales sale de la aritmética, no de una decisión tuya — y para una
factura electrónica de la DIAN, el formato sí importa. `Decimal.quantize` es la respuesta, y es
tuya la decisión de dónde aplicarla.

---

## 📏 6. Medición — dos números, porque la fase tiene dos mitades

### 6.1 El mismo cálculo, los dos estilos

**Hipótesis.** La jerarquía de estrategias y la tabla de datos producen el mismo resultado, y la
diferencia no está en el rendimiento sino en cuánto código hay que escribir y **cuántos sitios hay
que tocar para agregar un aliado**.

**Condiciones.** El motor de comisiones completo, escrito dos veces: como jerarquía de políticas
con clase base abstracta y fábrica —tal como lo escribiría alguien con once años de Java, y está
bien escrito—, y como tabla de datos con excepciones registradas. **Se verificó que los dos
producen resultados idénticos** en los cuatro casos que cubren las tres reglas especiales, antes
de contar nada. Líneas contadas con `ast`, sin docstrings, comentarios ni líneas en blanco.

**Resultado.**

| | Jerarquía de estrategias | Tabla + excepciones |
|---|---|---|
| Líneas de código | 54 | **22** |
| Clases | 7 | **0** |
| Funciones / métodos | 15 | **6** |
| Agregar un aliado **ordinario** | clase nueva + registro en la fábrica: **2 sitios** | una línea en la tabla — **0 sitios de código** cuando la tabla sea un TOML (Fase 06) |
| Agregar un aliado **con regla propia** | clase nueva + registro: **2 sitios** | una función nueva al final: **1 sitio, y no se modifica nada** |
| Cambiar la firma del cálculo | la base abstracta y las 4 subclases: **5 sitios** | las 3 funciones especiales: **3 sitios** |

> ⚖️ **Veredicto.** 2.5 veces menos código y **cero clases** para el mismo resultado. Pero el
> número que decide no es ese: es la fila de agregar un aliado ordinario. Veinte de los
> veintitrés aliados de Áurea **no tienen comportamiento propio, tienen un porcentaje**, y la
> jerarquía los obliga a existir como clases igual. Ese es el costo real del reflejo: no las
> líneas, sino haber convertido datos en código.
>
> **Dónde pierde la tabla, y hay que decirlo:** el diccionario `SPECIAL_RULES` no le dice al
> lector qué firma tienen las funciones que contiene, mientras que la clase base abstracta sí — y
> si alguien registra una función con la firma equivocada, el error aparece en tiempo de
> ejecución, no antes. Esa pérdida es real y es exactamente lo que el `Protocol` de la Fase 08
> recupera, con el verificador comprobándolo.
>
> **Y el umbral donde cambiaría la respuesta:** si cada aliado tuviera **varios** métodos
> —calcular, validar el convenio, decidir si vence—, la clase dejaría de ser ceremonia y pasaría
> a ser lo correcto: ahí sí hay estado y comportamiento que van juntos. Con un método por aliado,
> no.

### 6.2 Qué cuesta cada forma de representar un registro

**Hipótesis.** El `dict` es la opción por defecto de mucha gente y es la que más memoria gasta;
`dataclass` con `slots` gana en memoria y en acceso, y por lo tanto la legibilidad aquí no cuesta
nada.

**Condiciones.** CPython 3.14.5 · macOS 26.6 · Apple Silicon · 100.000 registros de cinco campos
con semilla `2026` · pico de memoria con `tracemalloc` de `bench.py`; tiempo de construcción de la
lista completa; tiempo de acceso a un campo de los 100.000, mediana de 7 repeticiones. Las cadenas
son compartidas por todas las variantes, así que **lo que se mide es el costo del contenedor**, no
el de los datos.

**Resultado.**

| Representación | Memoria | Construir | Acceder a un campo |
|---|---|---|---|
| `tuple` | 9.6 MB | **9 ms** | 2.6 ms |
| `dict` | **19.2 MB** | 21 ms | 3.8 ms |
| `dataclass` | 12.0 MB | 22 ms | **2.4 ms** |
| **`dataclass(slots=True)`** | **8.0 MB** | 20 ms | **2.4 ms** |
| `NamedTuple` | 10.4 MB | 35 ms | 3.1 ms |

> ⚖️ **Veredicto.** `dataclass(slots=True)` gana en las tres columnas que importan: **2.4× menos
> memoria que el `dict`**, el acceso más rápido de todos, y de paso menos memoria que una tupla
> desnuda. Es el resultado que más gente no espera: **el código más legible es también el más
> barato**, y la elección no tiene trade-off.
>
> **Dónde pierde:** `slots` impide agregar atributos al vuelo —que es una restricción, no un
> costo— y `dataclass` sin `slots` cuesta 50% más de memoria, así que la opción vale la pena
> escribirla. El `dict` gana en un solo caso legítimo: cuando las llaves no se conocen al escribir
> el código. Si las conoces, el `dict` es la peor opción de la tabla.
>
> **`NamedTuple` queda en tierra de nadie:** más lento de construir que todo lo demás, sin la
> ventaja de memoria de `slots`. Su caso de uso real es cuando necesitas que el registro **sea**
> una tupla —desempaquetado, índices, compatibilidad con código que espera tuplas—, y solo ahí.
>
> **El umbral:** con mil registros, ninguna de estas diferencias es perceptible y hay que elegir
> por legibilidad. Con cien mil, son 11 MB entre la mejor y la peor. Con los 482.074 del archivo
> del trimestre, la diferencia entre `dict` y `dataclass(slots)` se acerca a los 55 MB — en una
> máquina virtual de dos núcleos, eso ya es una decisión.

**Lo que no se midió:** el costo de `frozen=True` por separado —afecta a la escritura, no a la
lectura, y esta medición no escribe—, y el impacto de `__eq__` generado, que solo se paga si
comparas. El ejercicio 18 lo pide.

---

## 🧱 7. Miniproyecto — *El motor de comisiones*

**El encargo**

Julián, con una hoja impresa en la mano: *"Necesito saber cuánto nos deben los aliados del
trimestre. Son veintitrés y cada uno tiene su porcentaje, pero hay tres que negociaron distinto:
Neira cobra un mínimo por caso porque dice que un implante barato no le paga ni la silla,
Buitrago tiene un tope mensual que le puso el abogado, y Cárdenas cobra según la especialidad. Y
te aviso: estoy hablando con dos aliados nuevos, así que esto va a crecer."*

Escribe el motor que calcula lo que Áurea debe cobrarle a cada aliado por el trimestre, y déjalo
de forma que **agregar el aliado veinticuatro no toque ninguna línea existente**.

**Por qué duele**

Porque el enunciado tiene una frase que parece administrativa y es un requisito de diseño: *"esto
va a crecer"*. Y porque las tres reglas especiales no se parecen entre sí —un mínimo por caso, un
tope acumulado por mes, y una tabla por especialidad—, así que la abstracción que las cubra a las
tres tiene que ser lo bastante floja como para no estorbarle a la cuarta, que todavía no existe.

**Datos de entrada**

Un archivo de derivaciones del trimestre, que generas con este script:

```python
"""Genera las derivaciones a aliados del primer trimestre de 2026.

Uso:  python generar_derivaciones.py
Produce data/derivaciones-2026-Q1.csv con semilla fija.
"""

import random
from datetime import date, timedelta
from pathlib import Path

SPECIALTIES = ["periodoncia", "implantologia", "endodoncia", "cirugia"]
BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
VALUES = [450000, 800000, 1200000, 1800000, 2400000, 3200000, 4800000]


def main() -> None:
    random.seed(2026)
    Path("data").mkdir(exist_ok=True)
    partners = [f"P{n:03d}" for n in range(1, 24)]

    rows = []
    start = date(2026, 1, 1)
    for _ in range(1400):
        partner = random.choice(partners)
        day = start + timedelta(days=random.randint(0, 89))
        rows.append(
            f"{partner},{random.choice(BRANCHES)},{day.isoformat()},"
            f"{random.choice(SPECIALTIES)},{random.choice(VALUES)}"
        )

    target = Path("data") / "derivaciones-2026-Q1.csv"
    target.write_text(
        "aliado,sede,fecha,especialidad,valor_tratamiento\n" + "\n".join(rows) + "\n",
        encoding="utf-8",
    )
    print(f"{target}: {len(rows)} derivaciones")


if __name__ == "__main__":
    main()
```

Los porcentajes de los veintitrés aliados los defines tú, entre 10% y 20%, con estos tres
especiales: **P004** mínimo de $150.000 por caso, **P005** tope de $2.000.000 al mes, **P006**
20% en implantología, 12% en endodoncia y 10% en lo demás.

**Criterios de aceptación**

- [ ] Un solo archivo, `comisiones.py`, biblioteca estándar pura, sin clases. `Decimal` en todo lo
      que sea dinero.
- [ ] Produce el total por aliado del trimestre, y el detalle por aliado y mes.
- [ ] **La prueba de extensibilidad, y es bloqueante:** agrega un aliado nuevo —P024, con una
      regla que no exista: por ejemplo, uno que cobre el doble cuando el caso viene de una sede
      franquiciada— y demuestra con `git diff` que **no modificaste ninguna línea existente**,
      solo agregaste. Si tu `git diff` tiene una sola línea con `-`, el diseño no pasó.
- [ ] El tope mensual de P005 se calcula correctamente: el mes en que se alcanza, la comisión se
      corta ahí, y los casos posteriores de ese mes causan cero.
- [ ] Las tres reglas especiales son comprobables por separado, sin leer el archivo.
- [ ] **Medición:** líneas de código de tu solución —contadas sin docstrings ni comentarios— y
      cuántas líneas tuviste que agregar para el aliado P024. Esos dos números van en el tag.

**Restricciones de registro**

> Esto es un **script**. Un archivo, stdlib pura, funciones sueltas. Puedes usar `dataclass` para
> los registros —es de esta fase— pero **una clase con un método es el error que la fase entera
> ataca**. Si te descubres escribiendo `class ComisionStrategy(ABC)`, para y relee §4: lo estarías
> cometiendo en el mismo ejercicio que viene a evitarlo.

**La trampa**

Vas a construir una jerarquía de estrategias. Es lo que te enseñaron, es lo correcto en tu
lenguaje, y va a funcionar perfectamente.

Y vas a descubrir el problema al llegar al criterio de aceptación de P024: con la jerarquía, **el
aliado nuevo obliga a tocar la fábrica**, porque alguien tiene que registrar la clase nueva. Ese
`-` en el `git diff` es toda la lección.

Y hay una segunda trampa, más sutil y más cara: **veinte de los veintitrés aliados no necesitan
código**. Si terminas con veintitrés clases, o con veintitrés funciones, convertiste datos en
código y vas a mantener eso para siempre.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Separa lo que varía de lo que no. De los veintitrés aliados, ¿cuántos tienen de verdad un
comportamiento distinto? Tres. Los otros veinte tienen un número diferente, que no es lo mismo.

Lo que varía poco va en una estructura de datos. Lo que varía de verdad va en código. Y el código
que varía tiene que poder **agregarse** sin que nadie lo vaya a buscar.
</details>

<details><summary>Pista 2 — la herramienta</summary>

Un diccionario que va de identificador a función es todo el mecanismo. Para poblarlo sin tener
que mantener una lista en otro lado, un decorador que registre (§5.3) — y si quieres entender por
qué eso funciona, es simplemente que `@algo` es una reasignación (§4).

Para el tope mensual vas a necesitar acumular por aliado y mes: una llave compuesta, que es una
tupla, que es de la Fase 01. Y para agrupar sin materializar, lo de la Fase 02.

[`functools.partial`](https://docs.python.org/3.14/library/functools.html#functools.partial) te
sirve si prefieres fijar el porcentaje en la función en vez de pasarlo.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
@dataclass(frozen=True, slots=True)
class Referral:
    """Una derivación a un aliado."""

def rule_for(partner_id: str):
    """Decorador de registro. Agregar una regla no modifica nada."""

def referral_fee(partner_id, value, specialty, month_to_date) -> Decimal:
    """La comisión de un caso. Una función."""

def settle_quarter(referrals) -> dict[str, Decimal]:
    """El total por aliado. Ojo con el orden: el tope mensual depende de él."""
```
</details>

**Cómo se entrega**

```bash
python generar_derivaciones.py
python comisiones.py data/derivaciones-2026-Q1.csv
```

```bash
git add comisiones.py generar_derivaciones.py
git commit -m "fase 03 mini: motor de comisiones de aliados"
# y después, en un commit aparte, la prueba de extensibilidad:
git commit -m "fase 03 mini: aliado P024 con regla nueva"
git tag -a mini-03 -m "Mini F3: motor de comisiones · <N> líneas · P024 agregado en <M> líneas, 0 modificadas"
```

> 💡 **Haz el P024 en un commit aparte.** Es lo que convierte el criterio de aceptación en algo
> verificable: `git show` de ese commit tiene que ser todo `+`.

<details><summary>💡 Solución de referencia — la forma, y las dos decisiones</summary>

El código de §5.3 **es** el núcleo de la solución de referencia, y eso es deliberado: la parte
difícil de este miniproyecto no es el motor, es el acumulador del tope mensual y la prueba de
extensibilidad. Lo que falta:

```python
from collections import defaultdict


def settle_quarter(referrals):
    """Liquida el trimestre por aliado.

    El acumulado mensual se lleva por (aliado, mes) porque el tope de P005 es
    mensual y no trimestral. Es una llave compuesta: una tupla (Fase 01).
    """
    month_to_date = defaultdict(lambda: Decimal("0"))
    totals = defaultdict(lambda: Decimal("0"))

    for referral in referrals:
        month = referral.date[:7]                      # '2026-01'
        key = (referral.partner_id, month)
        fee = referral_fee(
            referral.partner_id,
            referral.treatment_value,
            referral.specialty,
            month_to_date[key],
        )
        month_to_date[key] += fee
        totals[referral.partner_id] += fee

    return dict(totals)
```

**La decisión de diseño que se tomó.** La tabla de porcentajes y el registro de excepciones, en
vez de la jerarquía. El otro camino es defendible en un caso concreto que conviene nombrar: si
Áurea tuviera que **validar el convenio, calcular la comisión y decidir el vencimiento** por
aliado —tres comportamientos, no uno—, la clase dejaría de ser ceremonia. Con un método, no lo
es.

**La trampa, entera.** La jerarquía funciona y produce los mismos números — lo mide la sección
6.1. Lo que no puede hacer es cumplir el criterio de P024 sin un `-` en el `git diff`, porque la
fábrica tiene que enterarse de la clase nueva. Hay una salida —descubrir las subclases
automáticamente con `__subclasses__()` o `__init_subclass__`— y es exactamente el momento de
notar algo: **esa salida es un registro, igual que el decorador, solo que escondido dentro del
mecanismo de clases.** Llegaste al mismo sitio dando más vueltas.

Y la trampa de los veinte aliados sin regla es la que más cuesta ver, porque no duele hoy: duele
cuando alguien tiene que cambiar un porcentaje y descubre que es un cambio de código, con su
commit, su revisión y su despliegue, en vez de una línea en una tabla.

**Qué se habría hecho distinto si el registro fuera otro.** Como herramienta —Bloque B— la tabla
de porcentajes viviría en un TOML con su fecha de vigencia, el motor tendría tipos verificados y
la prueba basada en propiedades de la Fase 08 —lo repartido suma exactamente lo cobrado—, y
`SPECIAL_RULES` estaría declarado con un `Protocol` para que el verificador atrape la firma
equivocada al registrar. Como aplicación, las tasas estarían en una tabla de la base de datos con
histórico, porque alguien va a preguntar qué porcentaje tenía Neira en 2024 — y esa pregunta
llega en la Fase 11.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Toma una clase con un solo método de tu propio código de fases anteriores —o escribe una— y
   conviértela en función. Anota cuántas líneas desaparecieron.
2. Escribe el decorador `timed` de §4 y aplícalo a `summarize`. Después quítale `functools.wraps`
   y muestra qué cambió en `summarize.__name__` y en `help(summarize)`.
3. Convierte `Row` a `@dataclass(frozen=True)` sin `slots` y demuestra que ahora falla al intentar
   modificar un campo. Copia el mensaje de error.
4. Usa `functools.partial` para crear tres funciones de comisión con el porcentaje ya fijado, y
   guárdalas en un diccionario. Es Strategy en cuatro líneas.
5. Declara un `Protocol` con un método y demuestra que una función y una clase distinta lo
   cumplen sin declararlo. (Nadie lo verifica todavía: eso es la Fase 08.)
6. Agrega `__contains__` a una clase que envuelva la lista de sedes, y usa `"Suba" in sedes`.
   Explica qué método hace que eso funcione.

**🟡 Intermedio (7–14)**

7. Escribe un decorador que reintente una función dos veces antes de fallar. Después averigua por
   qué la Fase 13 dice que esto está mal hecho sin *backoff* y sin idempotencia.
8. Usa `lru_cache` sobre una función que consulte la tarifa de un código de procedimiento. Mide la
   diferencia con `bench.py`, y después encuentra el caso donde la caché te devuelve un dato
   viejo.
9. Consulta la documentación de `dataclasses` y averigua qué hacen `field(compare=False)` y
   `field(repr=False)`. Usa cada uno en `Row` con un caso que lo justifique.
10. Escribe una `dataclass` con un campo de tipo lista y hazlo bien. Después intenta escribirlo
    mal (`items: list = []`) y copia el error exacto que lanza Python.
11. Reescribe el despacho de comandos del CLI de §5.2 usando `match` en vez de un diccionario.
    Decide cuál dejarías y justifica con el criterio de "qué pasa al agregar el comando número
    ocho".
12. Averigua qué es `__post_init__` en una `dataclass` y úsalo para normalizar el documento del
    paciente al construir la fila. Después discute si eso debería estar ahí o en la lectura.
13. Implementa `__eq__` a mano en una clase y descubre qué le pasa a `__hash__`. Lee la
    documentación del modelo de datos sobre esa interacción y explica por qué Python hace eso.
14. Toma las tres reglas especiales del motor y escribe la firma que comparten como un `Protocol`.
    ¿Qué habría atrapado ese `Protocol` que hoy falla en ejecución?

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Alguien registró una regla especial con los parámetros en otro orden y el
    cálculo da mal para un aliado. Reprodúcelo, explica por qué no falla en el registro sino en el
    cálculo, y propón dos formas de que falle antes.
16. **Diagnóstico.** Un decorador mal escrito hace que todas las funciones decoradas compartan
    estado. Escríbelo, reprodúcelo, explica el mecanismo —tiene que ver con la Fase 01— y
    arréglalo.
17. **Medición.** Reproduce la tabla de §6.2 en tu máquina con las cinco representaciones. Después
    agrega una sexta: una clase normal escrita a mano con `__init__`. ¿Dónde cae?
18. **Medición.** Mide qué cuesta `frozen=True` y qué cuesta el `__eq__` generado: compara
    construir y comparar 100.000 registros con y sin cada opción. Reporta con el arnés.
19. **Medición.** Escribe el motor de comisiones en los dos estilos —jerarquía y tabla— y
    compáralos como hace §6.1: líneas, clases, y sitios que hay que tocar. Verifica primero que
    dan los mismos números.
20. **De registro.** Julián quiere que "los porcentajes los pueda cambiar Patricia sin llamarte".
    Decide qué implica eso técnicamente, en qué registro cae, y qué le responderías. Hay una
    respuesta barata y correcta que no cambia el registro.
21. **De registro.** El motor de comisiones lo quiere usar también el back-office —que todavía no
    existe— para mostrar el acumulado de un aliado en pantalla. Decide qué tendría que pasar con
    este archivo para que eso sea posible, y si hoy vale la pena. Guarda la respuesta: la Fase 07
    la contesta.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Rompe el motor de comisiones con una regla especial que devuelva un `float`
    en vez de un `Decimal`. Demuestra que el error no aparece donde se cometió, calcula cuánto se
    desvía el total del trimestre, y propón dónde pondrías la defensa.
23. **Adversarial y de orden.** El tope mensual de P005 depende del orden en que se procesen los
    casos. Construye dos ordenamientos del mismo trimestre que produzcan totales distintos para
    ese aliado, cuantifica la diferencia, y escribe qué regla de negocio habría que preguntarle a
    Julián. Es un caso real: la Fase 15 lo vuelve a encontrar.
24. **Defiende una decisión.** Un colega dice que el diccionario de funciones "es magia y no se
    puede navegar en el IDE, mientras que una jerarquía de clases sí". Tiene parte de razón.
    Escribe la respuesta honesta con las dos caras, prueba en tu editor cuál de las dos afirmaciones
    es cierta hoy, y di qué harías si el motor creciera a cuarenta reglas especiales.
25. **Diseño.** Rediseña el motor para que soporte **vigencias**: el porcentaje de Neira cambió en
    julio de 2025 y hay que poder recalcular una liquidación de 2024 con la tasa de entonces.
    Hazlo sin introducir una clase, decide dónde vive el histórico, y di explícitamente qué parte
    de esto no debería resolverse en un script.

**🔥 Opcionales**

- Lee sobre `__init_subclass__` y `__subclasses__` y construye el registro automático de subclases
  que la solución de referencia menciona. Compáralo con el decorador: mismo mecanismo, distinta
  cantidad de magia.
- Averigua qué hace `functools.singledispatch` y reescribe con él una función que se comporte
  distinto según el tipo del argumento. Decide si lo usarías en Áurea.
- Mira el código fuente de `dataclasses` en la biblioteca estándar —está en Python— y encuentra
  dónde genera el `__init__`. Es la mejor demostración de que aquí no hay magia, hay código.

---

## 📚 9. Referencias

**Documentación oficial**

- [`dataclasses`](https://docs.python.org/3.14/library/dataclasses.html) — la referencia completa,
  con `field`, `frozen`, `slots` y `__post_init__`.
- [`functools`](https://docs.python.org/3.14/library/functools.html) — `wraps`, `partial`,
  `lru_cache`, `singledispatch`.
- [`typing.Protocol`](https://docs.python.org/3.14/library/typing.html#typing.Protocol) — el
  tipado estructural, y qué significa `runtime_checkable`.
- [El modelo de datos: métodos especiales](https://docs.python.org/3.14/reference/datamodel.html#special-method-names)
  — la lista completa de dunder, y en particular la relación entre `__eq__` y `__hash__`.
- [Orden de resolución de métodos](https://docs.python.org/3.14/howto/mro.html) — para cuando la
  curiosidad gane. No es material de trabajo de este curso.

**PEPs**

- [PEP 557](https://peps.python.org/pep-0557/) — `dataclasses`, y por qué se prefirió a un
  `namedtuple` mutable.
- [PEP 544](https://peps.python.org/pep-0544/) — `Protocol` y el tipado estructural: explica bien
  la diferencia con las clases base abstractas.
- [PEP 318](https://peps.python.org/pep-0318/) — los decoradores, y la discusión de sintaxis que
  duró años.

**Libros / artículos**

- *Fluent Python*, de Luciano Ramalho — los capítulos sobre funciones como objetos, decoradores y
  clases son la referencia larga de esta fase. Verifica la edición.

**Orden de lectura sugerido.** Antes de escribir: `dataclasses`, entera, que son quince minutos y
cubren la mitad de la fase. Durante: `functools` por función. Después: el PEP 544, que explica
por qué el tipado estructural es lo correcto para un lenguaje así — se entiende mejor con el
motor de comisiones ya escrito.

> ⚠️ URLs y contenidos cambian; fija 3.14 en el selector de la documentación.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Esta era la fase densa, y lo que te llevas es una sola idea con cuatro caras: **la estructura se
gana**. La clase cuando hay estado y varios métodos, la jerarquía cuando hay implementaciones de
verdad, el `Protocol` cuando hay un contrato que importa — y una función, un diccionario o una
tabla de datos el resto del tiempo, que es casi siempre.

Y te llevas el motor de comisiones, que es el cálculo más difícil del dominio de Áurea y el que
la Fase 08 va a blindar con una prueba basada en propiedades: *lo repartido entre los
profesionales de un plan suma exactamente lo cobrado, sin un peso de diferencia*. Esa prueba va a
encontrar sola el `float` donde debía ir `Decimal` — y por eso el motor se escribió con `Decimal`
desde la primera línea.

La **Fase 04** trae lo que hoy falta y se nota: hasta ahora, cuando algo sale mal, el script
revienta. Eso está bien para una herramienta que corre una persona mirando la pantalla, y deja de
estarlo cuando el lote de Patricia rebota entero por una fila mala y el mensaje no dice cuál. Ahí
entran EAFP, los context managers, y `ExceptionGroup` — que es la herramienta para reportar **todos**
los errores de un lote en vez del primero, y que no tiene equivalente en tu mundo.

> **La señal de que quedó bien:** cuando estés a punto de escribir `class`, te va a aparecer una
> pregunta antes: *¿qué estado comparten los métodos de esta clase?* Si la respuesta es "ninguno",
> vas a escribir funciones sin sentir que estás haciendo trampa.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-03 -m "F3 cerrada:
> - la clase con un solo método, la jerarquía y los getters reescritos sin ceremonia
> - decorador propio con functools.wraps, y el registro de comandos del CLI
> - Row es dataclass frozen con slots, y la conversión a Decimal ocurre en la lectura
> - Protocol declarado y entendido: nadie declara que lo implementa
> - el motor de comisiones calcula los 23 aliados y las 3 reglas especiales
> - el aliado P024 se agregó sin modificar ninguna línea existente"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 03: …`), los de ejercicio su número
> (`fase 03 ej12: …`) y el miniproyecto el suyo (`fase 03 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-03`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
