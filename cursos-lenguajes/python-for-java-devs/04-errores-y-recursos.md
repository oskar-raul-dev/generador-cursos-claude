# 💥 Fase 04 — Errores y recursos

> Python para desarrolladores Java senior · Fase 4 de 18 · Bloque A
> Depende de: Fase 03 · Habilita: Fase 05
> Registro de esta fase: **script** — un archivo, stdlib pura
> Proyecto que avanza: el CLI · **gana sus errores de dominio y su validación**
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Cambiar la disciplina de excepciones verificadas por la de Python, que es **distinta y no es
menor**.

Vienes de un lenguaje donde el compilador te obliga a declarar qué puede fallar. Aquí no hay nada
de eso, y la conclusión fácil —"entonces Python es laxo con los errores"— es exactamente la
equivocada: lo que cambia es dónde vive el contrato, no si existe. Lo que pierdes en verificación
lo tienes que poner en diseño, en documentación y en pruebas.

Y trae una herramienta que en tu mundo no existe y que resuelve un problema que sí tienes:
**reportar todos los errores de un lote en vez del primero.**

---

## ✅ 2. Qué queda listo al terminar

- [ ] Sabes cuándo EAFP le gana a comprobar antes, y tienes el número del umbral donde se invierte.
- [ ] Puedes diseñar una jerarquía de excepciones de dominio corta y decir por qué no tiene cinco
      niveles.
- [ ] Usas el `else` del `try` y puedes explicar qué problema resuelve que Java no tiene.
- [ ] Escribes un context manager propio con `contextlib.contextmanager` en seis líneas.
- [ ] Usas `ExceptionGroup` y `except*` para acumular fallos de un lote sin perder el contexto de
      ninguno.
- [ ] El CLI valida el lote antes de generar y reporta **todas** las filas malas.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Reintentos y *backoff*** → Fase 13, donde hay red de por medio y el reintento tiene sentido.
  Reintentar una lectura de archivo local es casi siempre un error de diseño.
- **`logging`** → Fase 16. Hoy los mensajes van a `stderr` con `print`, que para un script es
  defendible y para una aplicación no.
- **Excepciones en código concurrente** → Fase 14, donde `ExceptionGroup` vuelve con su otro
  motivo de existir: los `TaskGroup`.
- **Validación de datos externos con un esquema** → Fase 10. Hoy validamos a mano, y eso es lo
  correcto para un script.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** *"si no está declarada, no puede lanzarse"*.

Once años de `throws IOException` construyen un modelo mental muy concreto: la firma es el
contrato, el compilador lo verifica, y lo que no aparece ahí no va a pasar. Ese modelo aquí **no
tiene nada que lo sostenga**: cualquier función puede lanzar cualquier cosa, nadie lo declara, y
nadie te avisa.

De ese vacío nacen dos errores gemelos, y los dos son intentos honestos de recuperar la seguridad
que perdiste:

```python
# ❌ Error 1: el catch que se traga lo que importaba
try:
    process_batch(path)
except Exception:          # ¿qué estamos atrapando exactamente?
    print("hubo un error")  # y el usuario ve esto en vez de saber qué pasó
```

Ese `except Exception` atrapa el `KeyError` del aliado que no existe, el `ValueError` del valor mal
formado, y también el error de programación que escribiste tú hace diez minutos —un nombre mal
escrito, un índice fuera de rango—. Los tres se convierten en la misma frase inútil.

```python
# ❌ Error 2: el try de cuarenta líneas
try:
    rows = read_rows(path)
    validated = validate(rows)
    fees = calculate_fees(validated)
    write_output(fees, target)
except Exception as error:
    print(f"falló: {error}")   # ¿falló qué? ¿el archivo, el cálculo, la escritura?
```

Cuando algo aquí falla, no sabes cuál de las cuatro cosas fue, y —peor— no sabes si el archivo de
salida quedó a medias.

**Qué se escribe en su lugar**, y son tres reglas cortas:

```python
# ✅ Atrapar lo específico, y solo alrededor de lo que puede fallar
try:
    rows = list(read_rows(path))
except FileNotFoundError:
    print(f"no existe el archivo: {path}", file=sys.stderr)
    sys.exit(1)
except UnicodeDecodeError:
    print(f"{path} no está en UTF-8 (¿es el export de Odontovía?)", file=sys.stderr)
    sys.exit(1)
```

**Uno: atrapa el tipo específico.** `except Exception` solo es correcto en el borde exterior de un
programa, y ahí se acompaña de la traza completa, no de un mensaje amable.

**Dos: el `try` abraza lo mínimo.** Si el bloque tiene cuatro operaciones que fallan por razones
distintas, son cuatro bloques o es una función por operación.

**Tres: si no vas a hacer nada con el error, no lo atrapes.** Un script que revienta con su traza
le dice a quien lo corre exactamente qué pasó y en qué línea. Eso es más útil que un "hubo un
error" y es una decisión de diseño perfectamente defendible en el registro script.

> 🧭 **Dónde vive el contrato aquí:** en el docstring —qué levanta esta función y cuándo—, en el
> nombre de tus excepciones, y en las pruebas de la Fase 08. Los tres son convención, y por eso
> este ecosistema depende mucho más de la disciplina del que escribe que el tuyo.

### EAFP: intentar en vez de comprobar

La otra mitad del cambio de mentalidad tiene nombre: **EAFP**, *easier to ask forgiveness than
permission*. En vez de comprobar antes de actuar, se actúa y se maneja el fallo.

```python
# LBYL — look before you leap: lo que sale solo
if "valor" in row and row["valor"].isdigit():
    total += int(row["valor"])

# EAFP — el idioma de Python
try:
    total += int(row["valor"])
except (KeyError, ValueError):
    pass
```

No es estilo. Tiene dos razones concretas:

**La condición puede cambiar entre la comprobación y el uso.** Es el clásico *time-of-check to
time-of-use*: compruebas que el archivo existe, y entre esa línea y la siguiente otro proceso lo
borra. Con EAFP no hay ventana: la operación y su fallo son lo mismo.

**Y la comprobación casi nunca cubre todo.** `value.isdigit()` parece suficiente hasta que llega
un valor negativo, uno con espacio, uno con separador de miles, o el `"１２３"` en dígitos de ancho
completo que `isdigit()` acepta y `int()` también — pero `"٣"`, un tres árabe, lo acepta `isdigit`
e `int` lo convierte a 3, que probablemente no era lo que querías. La comprobación reimplementa,
mal, lo que la operación ya sabe hacer.

**Y no es dogma**, que es lo que hace creíble el resto: las excepciones cuestan, y cuando el fallo
es frecuente cuestan más que comprobar. La sección 6 tiene el umbral exacto.

### La jerarquía de excepciones propia, y por qué es corta

Aquí tu oficio se transfiere **entero**, y conviene decirlo porque el resto de la fase suena a que
todo cambia:

```python
class AurError(Exception):
    """Error del dominio de Áurea. Todo lo nuestro hereda de aquí."""


class InvalidRow(AurError):
    """Una fila del export que no se puede procesar."""

    def __init__(self, line_number: int, field: str, reason: str) -> None:
        self.line_number = line_number
        self.field = field
        self.reason = reason
        super().__init__(f"fila {line_number}, campo '{field}': {reason}")


class UnknownPartner(AurError):
    """Un aliado que no está en la tabla de tarifas."""
```

Tres clases y para. La razón de que sean pocas es la misma de siempre —una jerarquía de
excepciones profunda no la usa nadie— y aquí hay una adicional: **el que atrapa no necesita que el
tipo sea preciso, necesita que el mensaje lo sea**. Por eso `InvalidRow` guarda la línea, el campo
y el motivo como atributos: eso es lo que el reporte va a imprimir.

**La raíz común importa** y es la única regla no negociable: `except AurError` es lo que le permite
al borde del programa distinguir *"un dato del negocio venía mal"* de *"hay un error en mi
código"*. Sin esa raíz, todo es `Exception` y estás de vuelta en el error 1.

### El `else` del `try`, que en Java no existe

```python
try:
    rows = list(read_rows(path))
except FileNotFoundError:
    ...
else:
    # Solo si el try NO lanzó. Y lo que pase aquí adentro no lo atrapa el except.
    process(rows)
finally:
    # Siempre, haya fallado o no.
    cleanup()
```

Parece cosmético y resuelve un problema real: sin `else`, `process(rows)` tendría que ir **dentro**
del `try`, y entonces un `FileNotFoundError` lanzado desde dentro de `process` —por otra razón
completamente distinta— lo atraparía el mismo `except`. El `else` es cómo se mantiene el `try`
abrazando lo mínimo sin tener que partir la función.

### Context managers, o `try-with-resources` con más alcance

El `with` es el `try-with-resources` que ya conoces, y el paralelo aguanta hasta aquí: garantiza
el cierre pase lo que pase.

**Dónde se rompe, y es a favor:** allá esto sirve para recursos que implementan `AutoCloseable`.
Aquí es un protocolo genérico —`__enter__` y `__exit__`— que se usa para cualquier cosa con forma
de *antes y después*: una transacción, un cronómetro, un directorio temporal, cambiar el
directorio de trabajo y volver, silenciar una advertencia. Escribir uno cuesta seis líneas:

```python
import contextlib
import time


@contextlib.contextmanager
def timed(label):
    """Mide un bloque. El yield separa el antes del después."""
    started = time.perf_counter()
    try:
        yield                     # aquí corre el cuerpo del `with`
    finally:
        # finally, no una línea suelta: si el cuerpo lanza, esto tiene que correr igual.
        print(f"{label}: {(time.perf_counter() - started) * 1000:.0f} ms")


with timed("cierre de marzo"):
    process_batch(path)
```

Es un generador (Fase 02) con un solo `yield`: lo de antes es `__enter__`, lo de después es
`__exit__`. **El `try/finally` no es opcional** — sin él, un fallo dentro del `with` se salta el
cierre, que es justo lo que el `with` venía a garantizar.

Dos utilidades de `contextlib` que vale la pena conocer hoy:

**`contextlib.suppress(FileNotFoundError)`** es un `try/except/pass` que se lee mejor y que deja
claro que ignorar el error fue una decisión, no un olvido.

**`contextlib.ExitStack`** maneja un número variable de recursos: los diez exports de las sedes
abiertos a la vez, cerrados todos aunque el tercero falle al abrirse. Es lo que en Java tendrías
que escribir a mano con `try` anidados.

### `ExceptionGroup`: la herramienta que no tienes en Java

El problema, con el dominio de Áurea en la mano: Patricia manda el lote a la aseguradora, **rebota
entero**, y el mensaje dice que hay un error. Uno. El primero. Patricia lo arregla, vuelve a
mandar, y rebota otra vez por el siguiente. Tres días así.

Lo que hace falta es reportar **todos** los errores de una pasada, sin perder el contexto de
ninguno. Y hasta 3.11 eso se hacía acumulando errores en una lista, que funciona y pierde las
trazas.

```python
def validate_batch(rows):
    """Valida todo el lote y levanta un ExceptionGroup con TODO lo que falló."""
    problems: list[Exception] = []
    for number, row in enumerate(rows, start=2):   # 2: la 1 es el encabezado
        try:
            validate_row(row, number)
        except AurError as error:
            problems.append(error)      # se guarda la excepción entera, con su traza

    if problems:
        raise ExceptionGroup(
            f"{len(problems)} filas no se pueden facturar", problems
        )
```

Y del otro lado, `except*` desempaqueta por tipo:

```python
try:
    validate_batch(rows)
except* InvalidRow as group:
    for error in group.exceptions:
        print(f"  fila {error.line_number}: campo '{error.field}' — {error.reason}")
except* UnknownPartner as group:
    print(f"  {len(group.exceptions)} derivaciones de aliados que no están en la tabla")
```

El asterisco cambia la semántica de una forma que conviene tener clara: **`except*` puede
ejecutar más de una rama**. Si el grupo trae `InvalidRow` y `UnknownPartner`, corren las dos, cada
una con su subgrupo. Un `except` normal habría corrido una sola.

> ⚠️ **Dentro de un `except*` no se puede `return`, `break` ni `continue`**: es un `SyntaxError`,
> porque saldría de la función con otros subgrupos todavía sin manejar. Por eso el CLI de §5.3
> termina con `sys.exit(1)` en esa posición. La Fase 08 lo encontró al pasar `mypy` por el Bloque
> A: cualquier `except*` dentro de una función que retorna tiene que guardar el resultado y
> devolverlo después del bloque.

> 📝 **Nota de ecosistema.** `ExceptionGroup` y `except*` llegaron en 3.11 (PEP 654) y nacieron
> para otra cosa: los `TaskGroup` de `asyncio`, donde varias tareas concurrentes pueden fallar a
> la vez y no hay forma de elegir cuál excepción "es" el error. Que sirvan tan bien para validar
> lotes es un efecto colateral feliz. En código anterior a 3.11 vas a ver listas de errores
> acumuladas a mano, y en bibliotecas de validación vas a ver objetos de error propios que hacen
> lo mismo; ninguno está roto, y ahora hay una forma del lenguaje.

### Esto sí funciona igual

**Diseñar excepciones es la misma habilidad.** Qué merece ser un tipo propio, qué información
tiene que llevar el error para que alguien pueda actuar, dónde se atrapa y dónde se deja pasar:
todo eso lo sabes, y vale idéntico.

**`finally` es `finally`**, con la misma semántica y las mismas trampas —un `return` dentro de un
`finally` se come la excepción, aquí también.

**El encadenamiento existe y es mejor.** `raise NuevoError(...) from error` es
`initCause(...)`, y Python lo hace **automáticamente** cuando lanzas dentro de un `except`: la
traza muestra las dos, con la línea *"during handling of the above exception, another exception
occurred"*. Nunca pierdes la causa por descuido.

**Y la disciplina de no usar excepciones para control de flujo normal** sigue valiendo, con un
matiz: `StopIteration` es exactamente eso y es el mecanismo del `for`. La regla real es que no las
uses para flujo **frecuente**, y la sección 6 pone el número.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| Excepción verificada + `throws` | no existe | El contrato vive en el docstring y en las pruebas. Es la diferencia grande |
| `RuntimeException` | cualquier excepción | Todas son "no verificadas": la distinción no existe |
| `catch (IOException e)` | `except OSError as error` | `IOError` es un alias de `OSError` desde 3.3; vas a ver los dos |
| `try-with-resources` | `with` | Más general: sirve para cualquier *antes y después*, no solo para recursos |
| `finally` | `finally` | Idéntico, con la misma trampa del `return` que se come la excepción |
| `initCause` / `getCause` | `raise ... from ...` | Automático al lanzar dentro de un `except`: no se pierde la causa |
| `Throwable.getStackTrace()` | `traceback` | Un módulo, no un método del objeto |
| `catch (A \| B e)` | `except (A, B)` | Una tupla, no una barra |
| — | `else` del `try` | No tiene equivalente: sirve para que el `try` abrace lo mínimo |
| — | `ExceptionGroup` / `except*` | No tiene equivalente. Varias excepciones a la vez, y varias ramas ejecutadas |
| `@SuppressWarnings` | `contextlib.suppress` | No es una anotación: es un context manager que de verdad ignora |
| `Objects.requireNonNull` | `assert` (¡ojo!) | `assert` **desaparece** con la bandera `-O`. No lo uses para validar entradas |

> ⚠️ **`assert` no es una validación.** Se compila fuera con `python -O`, así que un
> `assert value > 0` para validar un dato de entrada es una validación que en producción puede no
> existir. Sirve para comprobar invariantes internos durante el desarrollo y para las pruebas de
> la Fase 08 — nada más.

---

## 💻 5. Código mínimo con comentarios

### 5.1 Los errores del CLI

```python
class AurError(Exception):
    """Error del dominio de Áurea.

    Todo error que el CLI sepa explicar hereda de aquí. Lo que NO herede de
    aquí es un error de programación, y ese sí debe reventar con su traza.
    """


class InvalidRow(AurError):
    """Una fila que no se puede facturar.

    Guarda línea, campo y motivo como atributos y no solo en el mensaje:
    el reporte los necesita por separado para poder ordenarlos y agruparlos.
    """

    def __init__(self, line_number: int, field: str, reason: str) -> None:
        self.line_number = line_number
        self.field = field
        self.reason = reason
        super().__init__(f"fila {line_number}, campo '{field}': {reason}")


class UnknownPartner(AurError):
    """Un aliado que no está en la tabla de tarifas."""

    def __init__(self, partner_id: str) -> None:
        self.partner_id = partner_id
        super().__init__(f"aliado sin tarifa registrada: {partner_id}")
```

### 5.2 La validación que acumula

```python
from decimal import Decimal, InvalidOperation

VALID_BRANCHES = frozenset({
    "Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
    "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira",
})


def validate_row(row, line_number):
    """Comprueba una fila. Levanta InvalidRow con el primer problema que encuentre.

    Levanta:
        InvalidRow: si el documento, la sede, la fecha o el valor están mal.
    """
    if not row.document.strip().isdigit():
        raise InvalidRow(line_number, "documento", f"no es numérico: {row.document!r}")

    if row.branch not in VALID_BRANCHES:
        raise InvalidRow(line_number, "sede", f"no es una sede de la red: {row.branch!r}")

    # EAFP: intentar convertir es más confiable que comprobar el formato con una
    # expresión regular, que siempre se queda corta con los casos raros.
    try:
        amount = Decimal(row.amount)
    except InvalidOperation:
        raise InvalidRow(line_number, "valor", f"no es un número: {row.amount!r}") from None

    if amount <= 0:
        raise InvalidRow(line_number, "valor", f"debe ser positivo: {amount}")


def validate_batch(rows):
    """Valida el lote completo y levanta UN ExceptionGroup con todo lo que falló.

    Es lo contrario de rendirse en la primera fila: Patricia necesita la lista
    completa para arreglar el archivo de una sola vez.
    """
    problems = []
    for line_number, row in enumerate(rows, start=2):   # 2: la línea 1 es el encabezado
        try:
            validate_row(row, line_number)
        except AurError as error:
            problems.append(error)

    if problems:
        raise ExceptionGroup(f"{len(problems)} filas no se pueden facturar", problems)
```

**Detalles con intención**

- **`raise ... from None`** en la conversión del valor. Sin eso, la traza mostraría el
  `InvalidOperation` interno de `Decimal`, que a Patricia no le dice nada. `from None` corta la
  cadena a propósito — y es una decisión, no un descuido: se usa cuando la causa técnica **no
  agrega información** para quien va a leer el error.
- **`validate_row` se rinde en el primer problema de *esa* fila**, y `validate_batch` no se rinde
  con el lote. Son dos decisiones distintas y las dos son correctas: si el documento está mal, el
  resto de la fila da igual; si una fila está mal, las otras 5.999 no.
- **`enumerate(rows, start=2)`** porque el número que Patricia necesita es el de la línea del
  archivo abierto en Excel, no el índice del arreglo. Detalle pequeño, y es la diferencia entre
  que el reporte sirva o no.
- **`frozenset` para las sedes** y no una lista: la pertenencia es constante (Fase 01, §6) y
  además nadie puede modificarlo por accidente.

### 5.3 El reporte, y el `except*`

```python
def report_problems(group):
    """Imprime el grupo agrupado por tipo. En español, con la línea del archivo."""
    print(f"❌ {group.message}\n", file=sys.stderr)

    by_field = {}
    for error in group.exceptions:
        by_field.setdefault(error.field, []).append(error)

    for field, errors in sorted(by_field.items()):
        print(f"  campo '{field}' — {len(errors)} filas:", file=sys.stderr)
        for error in errors[:5]:
            print(f"    línea {error.line_number}: {error.reason}", file=sys.stderr)
        if len(errors) > 5:
            print(f"    ... y {len(errors) - 5} más", file=sys.stderr)


@command("validar")
def validate_command(args):
    """Valida el export de una sede antes de facturar."""
    path = args[0]
    try:
        validate_batch(read_rows(path))
    except* InvalidRow as group:
        report_problems(group)
        sys.exit(1)
    except* UnknownPartner as group:
        print(f"{len(group.exceptions)} aliados sin tarifa", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"✅ {path}: el lote se puede facturar")
```

**Prueba de fuego**

Ensucia el archivo a propósito: cámbiale la sede a una fila, ponle una letra al documento de otra,
y déjale el valor vacío a una tercera.

```bash
python aur_cli.py validar data/centro-2026-03.csv
```

```text
❌ 3 filas no se pueden facturar

  campo 'documento' — 1 filas:
    línea 47: no es numérico: '10192837X'
  campo 'sede' — 1 filas:
    línea 12: no es una sede de la red: 'Chapinerp'
  campo 'valor' — 1 filas:
    línea 203: no es un número: ''
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **el código de salida**.
Si te olvidas del `sys.exit(1)`, ese reporte sale por pantalla y el proceso termina con `0` — y
dentro de once fases, el cierre nocturno va a leer ese `0` y va a seguir adelante facturando un
lote que no se puede facturar. Compruébalo: `echo $?` después de correr.

**El patrón a memorizar**

> Un lote se valida entero antes de procesarse, y los errores se acumulan con su ubicación. La
> pregunta que hay que hacerse siempre es: *quien reciba este error, ¿puede arreglar todo de una
> sola pasada?* Si la respuesta es no, el reporte está mal diseñado aunque el código esté bien.

### 5.4 Un context manager para no dejar archivos a medias

Hay un problema que el CLI ya tiene y que nadie ha nombrado: si la generación del archivo de
salida falla a la mitad, queda un archivo **parcial** en el disco. Y un archivo parcial de RIPS es
peor que ninguno, porque parece válido.

```python
import contextlib
import os
import tempfile
from pathlib import Path


@contextlib.contextmanager
def atomic_write(target: Path, encoding: str = "utf-8"):
    """Escribe en un temporal y renombra al final: o queda completo, o no queda.

    El renombrado dentro del mismo sistema de archivos es atómico en los tres
    sistemas operativos que soporta el curso, y es la forma estándar de no dejar
    archivos a medias.
    """
    temporary = target.with_suffix(target.suffix + ".tmp")
    handle = temporary.open("w", encoding=encoding, newline="")
    try:
        yield handle
    except BaseException:
        # BaseException y no Exception: un Ctrl-C también tiene que limpiar.
        handle.close()
        with contextlib.suppress(FileNotFoundError):
            temporary.unlink()
        raise                      # se relanza: limpiar no es lo mismo que tragarse
    else:
        handle.close()
        os.replace(temporary, target)   # atómico; Path.rename no lo es en Windows
```

**Detalles con intención**

- **`except BaseException`**, que es de los poquísimos sitios donde está bien: `KeyboardInterrupt`
  y `SystemExit` **no** heredan de `Exception`, y un `Ctrl-C` a mitad de la escritura tiene que
  borrar el temporal igual.
- **`raise` desnudo** al final del `except`: relanza la excepción original con su traza intacta.
  Limpiar no es manejar.
- **`os.replace` y no `Path.rename`**: el segundo falla en Windows si el destino existe. Es
  exactamente el tipo de detalle que hace que media fase se caiga en una plataforma, y es el tema
  de la Fase 05.
- **El archivo que abre un generador** es el caso que la Fase 02 dejó anotado: si el `for` que lo
  consume se corta antes —un `break`, una excepción—, el `with` de adentro del generador no se
  cierra hasta que el recolector lo encuentre. Se cierra a tiempo envolviendo el generador en
  `contextlib.closing(...)` en el sitio que lo consume, o llamando a su `.close()`: eso lanza
  `GeneratorExit` adentro y ejecuta el `finally` y el `with`. Es el mismo context manager de esta
  sección, aplicado al que no se ve.

---

## 📏 6. Medición — qué cuesta una excepción

**Hipótesis.** EAFP le gana a LBYL cuando el fallo es raro, y pierde cuando es frecuente. Existe
un punto de cruce, y está más abajo de lo que la gente supone.

**Condiciones.** CPython 3.14.5 · macOS 26.6 · Apple Silicon · 200.000 filas por corrida,
generadas con semilla `2026` · el mismo trabajo en las dos formas: sumar el campo `valor`
saltándose las filas cuyo valor no es convertible · **se verificó que las dos versiones producen
el mismo total** antes de medir · mediana de 7 repeticiones · se varía la proporción de filas
malas de 0% a 100%.

**Competidores.** LBYL escrito bien —`if value and value.isdigit()`, que es lo que escribiría
cualquiera— contra EAFP con `except (KeyError, ValueError)`. Ninguna de las dos versiones está
saboteada; las dos pasarían una revisión.

**Resultado.**

| Filas malas | LBYL | EAFP | Gana |
|---|---|---|---|
| 0% | 20.9 ms | **14.1 ms** | EAFP, 33% |
| 1% | 20.9 ms | **15.1 ms** | EAFP, 27% |
| 5% | 20.4 ms | **18.8 ms** | EAFP, 8% |
| **10%** | **20.0 ms** | 23.3 ms | LBYL, 14% |
| 25% | **20.0 ms** | 38.9 ms | LBYL, 49% |
| 50% | **16.0 ms** | 59.5 ms | LBYL, 73% |
| 100% | **8.0 ms** | 101.3 ms | LBYL, 92% |

> ⚖️ **Veredicto. El punto de cruce está entre el 5% y el 10% de fallos**, alrededor del 8%. Por
> debajo de eso, EAFP gana y además se lee mejor; por encima, cada excepción cuesta —construir el
> objeto, capturar la traza, desenrollar la pila— y a la tasa de fallo del 100% el precio es
> **12.7 veces** el de comprobar.
>
> **Y lo que de verdad sorprende es la primera fila:** con cero fallos, EAFP es **33% más rápido**
> que LBYL. La razón es que el `try` no cuesta casi nada cuando no se lanza —el intérprete lo
> instala con un salto— mientras que el `if` se evalúa en las 200.000 filas. No es que las
> excepciones sean baratas: es que **no lanzarlas es gratis**, y comprobar nunca lo es.
>
> **Cómo se usa esto en la práctica:** la pregunta no es "¿cuál es más rápido?" sino **"¿con qué
> frecuencia falla esto de verdad?"**. En el export de Odontovía, las filas malas son el 1 o 2%:
> EAFP, sin dudar. En un parseo de entrada de usuario donde la mitad viene mal, comprobar antes.
> Y en el caso intermedio —entre el 5 y el 15%— la diferencia es tan pequeña que decide la
> legibilidad, que es una forma elegante de decir que no importa.
>
> **Lo que esta medición no dice, y hay que decirlo:** el costo de una excepción depende de la
> profundidad de la pila. Aquí se lanza y se atrapa a una llamada de distancia; a diez llamadas
> de profundidad, el desenrollado cuesta más. La relación se mantiene, los números crecen.

**Lo que no se midió:** el costo de construir el objeto de excepción con mensajes formateados
—que aquí son cadenas cortas—, y el de `ExceptionGroup`, que agrupa cientos de excepciones vivas.
El ejercicio 18 lo pide.

---

## 🧱 7. Miniproyecto — *El validador que no se rinde en la primera fila*

**El encargo**

Patricia, un martes a las seis de la tarde, con el tono de quien ya perdió el día: *"Mandé el lote
de febrero a la aseguradora y me lo devolvieron con un mensaje que dice 'error en el registro'. No
dice cuál registro. Son 6.000 filas. Lo mandé otra vez quitando la que me pareció rara y me lo
volvieron a devolver. Llevo tres días en esto. ¿Puedes hacer algo que me diga TODO lo que está mal
antes de que yo lo mande?"*

Escribe el validador del lote: lee el archivo, comprueba todas las reglas, y produce un reporte
con **todas** las filas problemáticas, cada una con su línea, su campo y su motivo.

**Por qué duele**

Porque lo natural —y lo que el lenguaje te empuja a hacer— es lanzar en el primer problema, y lo
que se pide es acumular sin perder el contexto de ninguno. Y porque las reglas no son
independientes: hay filas que fallan por dos motivos a la vez, hay validaciones que solo tienen
sentido si otra pasó, y hay una regla que no se puede comprobar fila por fila porque depende del
lote completo.

**Datos de entrada**

El export consolidado de febrero, que generas con este script — y que trae la suciedad a propósito:

```python
"""Genera el lote de febrero con sus errores sembrados.

Uso:  python generar_lote_febrero.py
Produce data/lote-2026-02.csv con 6.001 filas y 106 problemas repartidos en
siete clases: 105 que se ven fila por fila y uno que solo se ve mirando el lote.
"""

import random
from pathlib import Path

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
CODES = ["D8010", "D8020", "D2740", "D7140", "D1110", "D8670"]
VALUES = [75000, 95000, 120000, 180000, 210000, 890000]


def main() -> None:
    random.seed(2026)
    Path("data").mkdir(exist_ok=True)
    rows = []

    for n in range(6000):
        document = str(random.randint(10_000_000, 1_299_999_999))
        branch = random.choice(BRANCHES)
        day = random.randint(1, 28)
        code = random.choice(CODES)
        value = str(random.choice(VALUES))

        # Los problemas sembrados: siete clases, quince casos de cada una
        # repartidos por todo el archivo. El documento vacío y el no numérico
        # fallan por la misma regla, así que esa clase suma treinta.
        if n % 400 == 7:
            document = document[:-1] + "X"          # documento no numérico
        elif n % 400 == 53:
            branch = branch + "p"                    # sede que no existe
        elif n % 400 == 101:
            value = ""                               # valor vacío
        elif n % 400 == 157:
            value = "-" + value                      # valor negativo
        elif n % 400 == 211:
            day = 30                                 # 30 de febrero: fecha imposible
        elif n % 400 == 269:
            code = "D9999"                           # código fuera del manual tarifario
        elif n % 400 == 331:
            document = ""                            # documento vacío

        rows.append(f"{document},Paciente {n},{branch},2026-02-{day:02d},{code},{value}")

    # Y un problema que NO se ve fila por fila: un procedimiento duplicado
    # —mismo paciente, mismo código, mismo día— que la aseguradora rechaza entero.
    rows.append(rows[1500])

    target = Path("data") / "lote-2026-02.csv"
    target.write_text(
        "documento,paciente,sede,fecha,codigo,valor\n" + "\n".join(rows) + "\n",
        encoding="utf-8",
    )
    print(f"{target}: {len(rows)} filas")


if __name__ == "__main__":
    main()
```

Las reglas que la aseguradora aplica, y que tu validador tiene que anticipar:

1. El documento es obligatorio y solo dígitos.
2. La sede tiene que ser una de las diez de la red.
3. La fecha tiene que existir de verdad (ojo con febrero).
4. El valor tiene que ser un número positivo.
5. El código tiene que estar en el manual tarifario —usa los seis de `CODES`.
6. **Y la que no se ve fila por fila:** no puede haber dos procedimientos del mismo paciente, con
   el mismo código, el mismo día.

**Criterios de aceptación**

- [ ] Un solo archivo, `validador.py`, biblioteca estándar pura.
- [ ] Reporta **todos** los problemas de una sola pasada, cada uno con línea, campo y motivo, en
      español.
- [ ] Usa `ExceptionGroup` y `except*`. Una lista de errores acumulada a mano resuelve el
      problema y **no cumple** este criterio: el punto es usar el mecanismo del lenguaje.
- [ ] La regla 6 —el duplicado— se detecta y se reporta con **las dos** líneas involucradas.
- [ ] El reporte agrupa por tipo de problema y no imprime seis mil líneas si todo está mal.
- [ ] Código de salida `0` si el lote se puede facturar y `1` si no. Compruébalo con `echo $?`.
- [ ] **Medición:** cuántos problemas encontró, de cuántas clases, y cuánto tardó sobre las 6.001
      filas. Esos números van en el mensaje del tag. *(Para que puedas comprobarte: el archivo
      trae 106 problemas de siete clases. Si tu validador encuentra menos, te falta una regla; si
      encuentra más, alguna regla está de más.)*

**Restricciones de registro**

> Esto es un **script**. Un archivo, stdlib pura. Puedes usar `dataclass` y decoradores —son de la
> Fase 03— y excepciones propias, que son de esta. Lo que no puedes es construir un framework de
> validación con reglas registrables y un motor genérico: seis reglas no justifican un motor, y
> ese es el mismo reflejo de la ceremonia, mudado de casa.

**La trampa**

La regla 6 no cabe en `validate_row`. Todas las demás miran una fila; esa mira el lote entero, y
si la fuerzas dentro de la función por fila vas a terminar pasando estado por parámetro o —peor—
guardándolo en una variable global.

Y hay una segunda que solo aparece si de verdad lo intentas: **una fila puede fallar por dos
motivos a la vez** —documento vacío *y* valor negativo—. Tu primera versión va a reportar el
primero y callar el segundo, y Patricia va a volver el miércoles con el mismo problema y una fila
distinta.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Son dos clases de validación y conviene aceptarlo en vez de forzarlas a la misma forma: las que
miran una fila, y las que miran el conjunto. Dos funciones distintas, dos recorridos, y un solo
`ExceptionGroup` al final que las junta.

Para la trampa de los dos motivos en una fila: `validate_row` hoy **lanza** en el primero. Si lo
que quieres es que reporte todos, no puede lanzar — tiene que devolver.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [`ExceptionGroup`](https://docs.python.org/3.14/library/exceptions.html#ExceptionGroup) y la
  sintaxis `except*`, con sus ejemplos.
- [`datetime.date`](https://docs.python.org/3.14/library/datetime.html#datetime.date) levanta
  `ValueError` con un 30 de febrero, así que no tienes que escribir el calendario: EAFP.
- Para el duplicado, una llave compuesta —`(documento, código, fecha)`— en un diccionario que
  guarde en qué línea apareció la primera vez. Fase 01 §4 y Fase 02 §7.
- Y [`ExceptionGroup.subgroup`](https://docs.python.org/3.14/library/exceptions.html) si quieres
  filtrar el grupo sin recorrerlo a mano.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def row_problems(row, line_number) -> list[InvalidRow]:
    """TODOS los problemas de una fila. Devuelve; no lanza."""

def batch_problems(rows) -> list[AurError]:
    """Los problemas que solo se ven mirando el lote completo."""

def validate(rows) -> None:
    """Levanta un ExceptionGroup con todo, o no levanta nada."""

def report(group) -> str:
    """Agrupado por tipo, con tope por grupo."""
```
</details>

**Cómo se entrega**

```bash
python generar_lote_febrero.py
python validador.py data/lote-2026-02.csv ; echo $?
```

```bash
git add validador.py generar_lote_febrero.py
git commit -m "fase 04 mini: validador de lote con reporte completo"
git tag -a mini-04 -m "Mini F4: validador de lote · <N> problemas de <M> clases en <T> ms"
```

<details><summary>💡 Solución de referencia — la decisión y las dos trampas</summary>

**La decisión de diseño que se tomó.** `row_problems` **devuelve** una lista en vez de lanzar. Es
la decisión central y va contra el instinto: una función de validación que no lanza parece a medio
hacer. El otro camino defendible —lanzar y atrapar por fila, como en §5.2— es más idiomático y
tiene un defecto fatal para este encargo: **solo puede reportar el primer problema de cada fila**,
porque el `raise` corta la función. Si el encargo fuera "dime si la fila sirve", lanzar sería lo
correcto. El encargo es "dime todo lo que está mal", y eso cambia la forma.

La regla general que queda: **lanza cuando el que llama tiene que parar; devuelve cuando el que
llama tiene que decidir.**

**Las dos trampas, enteras.** La regla 6 no cabe en la validación por fila porque su unidad no es
la fila: es el par. Forzarla adentro obliga a pasar un acumulador por parámetro —que funciona y
ensucia la firma de una función que no lo necesita— o a una global, que es peor. Dos recorridos y
dos funciones cuestan una pasada más sobre 6.000 filas, que es nada, y dejan las dos cosas
legibles.

Y el duplicado tiene un detalle que casi todo el mundo pasa por alto: **hay que reportar las dos
líneas**, la primera y la repetida. Un reporte que solo diga "la línea 6001 está duplicada" obliga
a Patricia a buscar la otra a mano entre seis mil filas, y ahí la herramienta dejó de ayudar tres
metros antes de la meta.

**Qué se habría hecho distinto si el registro fuera otro.** Como herramienta —Bloque B— las reglas
vendrían de un archivo de configuración con su vigencia, porque la aseguradora las cambia; el
reporte saldría también en CSV para que Patricia lo abra al lado del archivo original; y las
pruebas de la Fase 08 tendrían un caso por regla. Como aplicación, la validación correría en la
frontera de la API (Fase 10) y el lote malo ni siquiera entraría al sistema — que es una forma
mucho mejor de resolver este problema y que Áurea no puede pagar todavía.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Toma un `except Exception` de tu código de fases anteriores —o escríbelo— y redúcelo a los dos
   o tres tipos que de verdad pueden ocurrir ahí. Anota cuáles descubriste que no podían.
2. Escribe una excepción de dominio que lleve tres atributos y demuestra que se pueden leer desde
   el `except`.
3. Convierte un `try/except/pass` en `contextlib.suppress` y explica en una línea qué gana el
   lector.
4. Usa el `else` del `try` en el CLI y demuestra con un ejemplo qué error habría atrapado de más
   si el código estuviera dentro del `try`.
5. Escribe un context manager con `@contextlib.contextmanager` que mida un bloque. Después quítale
   el `try/finally` y demuestra qué se rompe.
6. Levanta un `ExceptionGroup` con tres excepciones de dos tipos distintos y atrápalo con dos
   `except*`. Comprueba que **las dos ramas se ejecutan**.

**🟡 Intermedio (7–14)**

7. Reescribe `validate_row` de §5.2 para que reporte todos los problemas de la fila en vez del
   primero. Compara las dos versiones y di cuándo usarías cada una.
8. Usa `contextlib.ExitStack` para abrir los diez exports de sede a la vez y cerrarlos todos
   aunque el quinto no exista. Demuéstralo borrando uno.
9. Provoca un `raise ... from error` y un `raise ... from None` sobre el mismo error, y compara
   las dos trazas. Explica cuándo usarías cada uno.
10. Averigua qué pasa con una excepción lanzada dentro de un `finally` que además tiene un
    `return`. Escríbelo, míralo, y explica por qué es una mala idea.
11. Consulta la jerarquía de excepciones incorporadas y dibuja la rama de `OSError`. Encuentra
    cuáles de sus hijas te pueden ocurrir al leer un archivo del export.
12. Escribe un context manager que cambie el directorio de trabajo y lo restaure al salir, aunque
    el cuerpo lance. Después averigua por qué esa función es peligrosa en un programa con hilos
    —la Fase 14 lo retoma.
13. Haz que `atomic_write` de §5.4 falle a la mitad y comprueba que no queda ni el archivo final
    ni el temporal. Después quítale el `except BaseException` y repite con `Ctrl-C`.
14. Lee la documentación de `ExceptionGroup.subgroup` y úsala para separar los errores de
    documento del resto sin recorrer la lista a mano.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Un script "funciona" pero a veces produce archivos de salida vacíos. El
    código tiene un `except Exception: pass` en un sitio. Reprodúcelo, explica por qué el síntoma
    aparece lejos de la causa, y arréglalo.
16. **Diagnóstico.** Te reportan que el validador "dice que todo está bien" sobre un archivo que
    claramente no lo está. Hay dos causas posibles y las dos son clásicas: una tiene que ver con el
    generador de la Fase 02 y otra con el código de salida. Reprodúcelas las dos.
17. **Medición.** Reproduce la tabla de la sección 6 en tu máquina y encuentra **tu** punto de
    cruce. Después repítela lanzando la excepción desde diez llamadas de profundidad y explica
    qué cambió.
18. **Medición.** Mide cuánto cuesta construir y levantar un `ExceptionGroup` con 10, 100 y 1.000
    excepciones adentro. Decide si hay un tope a partir del cual acumularlas todas deja de ser
    buena idea, y qué harías entonces.
19. **Medición.** Compara `contextlib.suppress` contra `try/except/pass` sobre un millón de
    iteraciones. El resultado te va a sorprender: explica por qué, y decide si cambia tu
    recomendación.
20. **De registro.** El validador lo quieren usar también las auxiliares de las sedes, "para
    revisar antes de mandarle el archivo a Patricia". Decide el registro, con el costo de las tres
    opciones. Guarda la respuesta: la Fase 09 la contesta con números.
21. **De registro.** La aseguradora cambia sus reglas dos veces al año y Patricia se entera por
    correo. Decide qué parte de este problema es de software y qué parte no, y qué le propondrías
    a Julián. Hay una respuesta que no requiere escribir código.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Construye un archivo que pase tu validador entero y que la aseguradora
    rechazaría. Tienes al menos tres caminos: el encoding, un carácter invisible dentro de un
    campo, y una regla de negocio que no está en la lista. Documenta los tres.
23. **Adversarial.** Haz que `atomic_write` deje un archivo corrupto. Hay una forma que no tiene
    que ver con excepciones sino con el sistema de archivos, y que la Fase 16 nombra en su parte
    de operación. Investígala, repróducela si puedes, y explica qué haría falta para cerrarla de
    verdad.
24. **Defiende una decisión.** Un colega dice que las excepciones de dominio sobran: *"devuelve un
    `None` o una tupla `(ok, error)` y listo, como en Go"*. Es un estilo legítimo y tiene
    defensores serios. Escribe las dos caras, implementa una versión del validador con ese estilo,
    compáralas en líneas y en legibilidad, y di cuál dejarías en Áurea y por qué.
25. **Diseño.** El validador y el motor de comisiones de la Fase 03 tienen que convivir: hay
    derivaciones cuyo aliado no existe. Diseña cómo se reportan esos errores junto con los de fila
    en un solo `ExceptionGroup`, sin que el código de validación tenga que saber del motor de
    comisiones. Hay más de una respuesta buena.

**🔥 Opcionales**

- Lee el PEP 654 entero y averigua qué problema de `asyncio` motivó `ExceptionGroup`. La Fase 14
  lo vuelve a encontrar por ese lado.
- Investiga `sys.excepthook` y escribe uno que imprima los errores de dominio sin traza y todo lo
  demás con traza completa. Es el patrón que usa media herramienta de línea de comandos.
- Averigua qué es `traceback.TracebackException` y úsalo para guardar la traza de un error en un
  archivo sin imprimirla. La Fase 16 lo necesita.

---

## 📚 9. Referencias

**Documentación oficial**

- [Errores y excepciones](https://docs.python.org/3.14/tutorial/errors.html) — el tutorial, que es
  corto y cubre `else`, `finally` y `ExceptionGroup`.
- [Excepciones incorporadas](https://docs.python.org/3.14/library/exceptions.html) — la jerarquía
  completa. Vale la pena mirarla una vez entera.
- [`contextlib`](https://docs.python.org/3.14/library/contextlib.html) — `contextmanager`,
  `suppress`, `ExitStack`, `closing`.
- [El sentencia `with`](https://docs.python.org/3.14/reference/compound_stmts.html#the-with-statement)
  — la semántica exacta de `__enter__` y `__exit__`, incluido qué pasa si `__exit__` devuelve algo
  verdadero.

**PEPs**

- [PEP 654](https://peps.python.org/pep-0654/) — `ExceptionGroup` y `except*`. Explica bien por
  qué no bastaba con una lista de errores.
- [PEP 343](https://peps.python.org/pep-0343/) — de dónde salió el `with`, y la relación con los
  generadores que hace que `@contextmanager` funcione.
- [PEP 3134](https://peps.python.org/pep-3134/) — el encadenamiento automático de excepciones.

**Orden de lectura sugerido.** Antes de escribir: el tutorial de errores, completo. Durante:
`contextlib` y la jerarquía de excepciones, consultadas. Después: el PEP 654, que se entiende
mucho mejor con el validador ya escrito.

> ⚠️ URLs y contenidos cambian; fija 3.14 en el selector de la documentación.

---

## 🚀 10. Cierre y conexión con la siguiente fase

El CLI ya no revienta con una traza cuando el archivo viene mal: **valida el lote entero y le dice
a Patricia todo lo que tiene que arreglar**, de una vez. Ese cambio es pequeño en líneas y grande
en la vida real de la persona que lo usa, que es lo que distingue una herramienta de un script que
funciona.

Y te llevas dos criterios que valen fuera de Python: **lanza cuando el que llama tiene que parar,
devuelve cuando tiene que decidir**; y **atrapa el tipo específico, alrededor de lo mínimo, o no
atrapes**.

La **Fase 05** ⭐ es donde el Bloque A demuestra su tesis: la biblioteca estándar **es** el
reemplazo del shell. `pathlib` para que las rutas de Windows dejen de romper tu script,
`subprocess` bien hecho —sin `shell=True`, mirando el código de retorno—, señales para que un
`Ctrl-C` no deje un archivo a medias (que es justo lo que `atomic_write` de hoy empezó a
resolver), y `argparse`, que llega cuando `sys.argv` ya no aguanta. Y el miniproyecto es el
binario firmador del proveedor: un programa ajeno que se cuelga, que mezcla `stdout` con `stderr`,
y que devuelve un "éxito" con código distinto de cero.

> **La señal de que quedó bien:** cuando veas un `except Exception` en código ajeno, ya no vas a
> pensar "bueno, por si acaso" — vas a preguntarte qué error de programación está escondiendo.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-04 -m "F4 cerrada:
> - jerarquía de errores de dominio corta, con AurError como raíz
> - EAFP y LBYL medidos, con el punto de cruce encontrado
> - el else del try en uso, y el try abrazando lo mínimo
> - context manager propio, y atomic_write para no dejar archivos a medias
> - ExceptionGroup y except* reportando todo el lote de una pasada
> - el validador corre, reporta todas las filas malas y sale con código 1"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 04: …`), los de ejercicio su número
> (`fase 04 ej12: …`) y el miniproyecto el suyo (`fase 04 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-04`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
