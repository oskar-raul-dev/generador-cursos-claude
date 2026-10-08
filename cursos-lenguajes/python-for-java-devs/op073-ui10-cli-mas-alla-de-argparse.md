# ⌨️ ui10 — CLI más allá de argparse

> Python para desarrolladores Java senior · **Carta** · Track `ui` — Interfaces y entregables sin
> frontend · sección 10 de 13
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Patricia no va a usar una terminal, y está bien: las interfaces de terminal de Áurea no son para ella. Son para el
ingeniero y para otros programas: el comando que recalcula la mora de una sede, el que reprocesa el cierre de una noche, el
que el cron de las 4:00 llama y cuyo resultado lee otro script. Para esos usuarios, una herramienta de línea de comandos es
la interfaz correcta, y la calidad se mide distinto: **que otro programa la pueda consumir**.

`argparse` viene con Python y alcanza para casi todo. Encima hay tres capas populares —Click, Typer y `cyclopts`— que
compran menos código a cambio de una dependencia, y Fire, que convierte cualquier función en un comando sin declarar nada.
Esta sección escribe el mismo comando en tres de ellas y mide lo que importa en una herramienta de terminal: **cuánto tarda
en arrancar, qué código de salida devuelve cuando algo falla, y si su salida se puede encadenar**.

---

## 🧠 2. El modelo

| Biblioteca | Cómo se declara | Dependencias | Para qué |
|---|---|---|---|
| `argparse` (biblioteca estándar) | Un *parser* con `add_argument` | Ninguna | Scripts y herramientas pequeñas; cero instalación |
| Click 8.5.0 | Decoradores (`@click.option`) | 1 | La base de muchas CLI famosas; grupos de comandos grandes |
| Typer 0.27.2 | **Las anotaciones de tipo** de la función | Click, `rich` y otras | CLI con ayuda bonita, del autor de FastAPI |
| `cyclopts` 5.1.1 | Las anotaciones de tipo, sin Click debajo | `rich` y pocas más | Lo mismo que Typer, con un modelo propio y más moderno |
| Fire | Nada: expone la función o el objeto tal cual | 1 | Prototipos; casi nunca una herramienta que dure |

Y la ergonomía que hace a una herramienta de terminal buena ciudadana, venga de la biblioteca que venga:

| Regla | Por qué |
|---|---|
| Código de salida 0 si salió bien, distinto de 0 si no | El cron, el CI y `&&` deciden con eso |
| Los datos a `stdout`, los mensajes y errores a `stderr` | Para que `comando > archivo` guarde solo datos |
| `--json` para que otro programa la consuma | El texto bonito es para personas; JSON, para programas |
| Leer de `stdin` si no se da un archivo | Para encadenarla con `|` |
| Configuración en capas: valor por defecto < archivo < variable de entorno < argumento | El cron usa variables; la persona, argumentos |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, una CLI es picocli o JCommander, y el arranque de la JVM hace que nadie se preocupe por cien milisegundos más. En
Python el arranque es corto, y por eso **el tiempo de importación de la biblioteca de CLI se nota**: una herramienta que el
autocompletado del *shell* llama en cada tecla, o que un script llama mil veces, paga ese tiempo cada vez.

---

## 💻 3. El ejemplo que corre

```bash
uv add typer cyclopts
```

El mismo comando —`mora SALDO DIAS [--json]`— en las tres. `cli_argparse.py`:

```python
"""mora SALDO DIAS [--json], con argparse."""

import argparse
import json


def mora(saldo: int, dias: int) -> int:
    return round(saldo * 15 * dias / (1000 * 30))


parser = argparse.ArgumentParser(prog="mora", description="Interés de mora de un saldo.")
parser.add_argument("saldo", type=int, help="saldo en pesos, sin puntos")
parser.add_argument("dias", type=int, help="días de mora")
parser.add_argument("--json", action="store_true", help="salida en JSON para otro programa")
args = parser.parse_args()
value = mora(args.saldo, args.dias)
print(json.dumps({"saldo": args.saldo, "dias": args.dias, "mora": value}) if args.json else f"${value:,}".replace(",", "."))
```

`cli_typer.py`:

```python
"""mora SALDO DIAS [--json], con Typer: las anotaciones son la declaración."""

import json
from typing import Annotated

import typer


def main(saldo: int, dias: int, as_json: Annotated[bool, typer.Option("--json")] = False):
    """Interés de mora de un saldo."""
    value = round(saldo * 15 * dias / (1000 * 30))
    print(json.dumps({"saldo": saldo, "dias": dias, "mora": value}) if as_json else f"${value:,}".replace(",", "."))


if __name__ == "__main__":
    typer.run(main)
```

`cli_cyclopts.py`:

```python
"""mora SALDO DIAS [--json], con cyclopts."""

import json
from typing import Annotated

from cyclopts import App, Parameter

app = App(name="mora", help="Interés de mora de un saldo.")


@app.default
def main(saldo: int, dias: int, *, as_json: Annotated[bool, Parameter(name="--json")] = False):
    value = round(saldo * 15 * dias / (1000 * 30))
    print(json.dumps({"saldo": saldo, "dias": dias, "mora": value}) if as_json else f"${value:,}".replace(",", "."))


if __name__ == "__main__":
    app()
```

`comparar.py` las mide igual: arranque (`--help`, el mejor de cinco), la salida JSON leída por otro programa, y el código de
salida con la entrada que escribiría una persona de Áurea —`1.250.000`, con puntos—.

```python
"""Arranque, salida encadenable y código de salida de las tres CLI."""

import json
import subprocess
import sys
import time

for cli in ("cli_argparse.py", "cli_typer.py", "cli_cyclopts.py"):
    times = []
    for _ in range(5):
        start = time.perf_counter()
        subprocess.run([sys.executable, cli, "--help"], capture_output=True, check=True)
        times.append(time.perf_counter() - start)
    ok = subprocess.run([sys.executable, cli, "1250000", "45", "--json"], capture_output=True, text=True)
    bad = subprocess.run([sys.executable, cli, "1.250.000", "45"], capture_output=True, text=True)
    print(f"{cli:<17} arranque {min(times) * 1000:4.0f} ms · json → {json.loads(ok.stdout)['mora']} · "
          f"con puntos: salida {bad.returncode}, stdout {len(bad.stdout)} bytes, stderr {len(bad.stderr)} bytes")
```

```bash
python3 comparar.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre; estos, de un contenedor en un portátil):

```text
cli_argparse.py   arranque   29 ms · json → 28125 · con puntos: salida 2, stdout 0 bytes, stderr 97 bytes
cli_typer.py      arranque  102 ms · json → 28125 · con puntos: salida 2, stdout 0 bytes, stderr 684 bytes
cli_cyclopts.py   arranque  114 ms · json → 28125 · con puntos: salida 2, stdout 0 bytes, stderr 603 bytes, stderr … bytes
```

Las tres hacen lo mismo y las tres se portan bien con la entrada inválida: código 2, nada en `stdout`, el mensaje en
`stderr`. Lo que las separa es el arranque: `argparse` arranca en 29 ms y las otras dos en más de 100, unas 3,5 veces más,
porque importan `rich` para dibujar la ayuda y los errores en recuadros (de ahí los 600 bytes de `stderr` contra 97). Para
un comando que el ingeniero escribe a mano, 70 ms no se notan; para uno que un script llama diez mil veces en un
reproceso, son doce minutos.

**Detalles con intención**

- **`--json`** es la línea que convierte una herramienta para personas en una para programas. El texto `$28.125` es para
  leer; `{"mora": 28125}` es para que el cron o `jq` lo usen.
- **La entrada inválida va a `stderr`** con un código distinto de cero, y `stdout` queda vacío: `mora 1.250.000 45 > x.json`
  no deja un archivo con un mensaje de error adentro.
- **Las tres validan el tipo `int`** por la anotación o por `type=int`. El mensaje de error no lo escribiste tú, y está en
  inglés; para una herramienta del ingeniero, aceptable.

---

## ⚠️ 4. Lo que se rompe

**`print` para los errores.** El error impreso en `stdout` con código 0 hace que el cron crea que salió bien y que el script
siguiente lea el mensaje como si fueran datos. Los errores van a `stderr` y con `sys.exit(1)` (o el código que use la
biblioteca).

**La salida bonita que otro programa tiene que leer.** Una tabla de `rich` (`ui11`) es perfecta en la terminal e imposible de
leer desde otro script. Cuando la salida no es una terminal (`sys.stdout.isatty()` falso), se imprime texto plano o JSON.

**Typer y el arranque.** Typer importa Click y `rich`; en una herramienta que se llama mil veces desde un bucle, o en el
autocompletado del *shell*, los milisegundos de arranque se multiplican. Se mide (la tabla de arriba) antes de decidir.

**Fire en una herramienta que dura.** Expone todos los métodos y argumentos de la función sin declarar nada, incluidos los
que no debían ser parte de la interfaz, y la ayuda sale de lo que encuentre. Para un prototipo de una tarde; no para el
comando que corre el cron.

---

## ⚖️ 5. Cuándo NO usarlo

**Typer o `cyclopts` para un script de dos argumentos.** `argparse` lo hace sin dependencias, y el script corre en cualquier
Python del servidor sin instalar nada.

**Una CLI como interfaz para Patricia.** Por todo lo de `ui01`.

**Click si ya se usa Typer** (o al revés) en la misma casa: dos formas de declarar comandos para el mismo equipo.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `comparar.py` en tu máquina. **Criterio:** la tabla con tus milisegundos, y la más rápida.
2. Corre `python3 cli_typer.py --help` y `python3 cli_cyclopts.py --help`. **Criterio:** describes la diferencia en la ayuda.
3. Encadena la salida JSON con `jq .mora`. **Criterio:** imprime solo el número.

**🟡 Intermedio (4–6)**

4. Haz que las tres acepten `1.250.000` (quitando puntos con un tipo propio). **Criterio:** el mismo resultado que sin puntos.
5. Agrega configuración en capas a la versión `cyclopts`: la tasa por defecto, desde un archivo TOML, desde
   `AUREA_TASA_MORA` y desde `--tasa`. **Criterio:** una prueba por capa demuestra cuál gana.
6. Haz que la versión `argparse` lea pares `saldo,dias` de `stdin` si no recibe argumentos. **Criterio:**
   `cat saldos.csv | python3 cli_argparse.py --json` produce una línea JSON por saldo.

**🟠 Difícil (7–9)**

7. Convierte la versión Typer en un grupo de comandos (`mora`, `cierre`, `liquidacion`) con un comando por archivo.
   **Criterio:** `--help` lista los tres, y cada uno tiene su prueba con `typer.testing.CliRunner`.
8. Agrega autocompletado del *shell* a la versión Typer o `cyclopts`. **Criterio:** funciona en tu *shell*, y mides cuánto
   tarda en responder cada tecla.
9. Empaqueta la herramienta con un *entry point* en `pyproject.toml` e instálala con `uv tool install`. **Criterio:** el
   comando `aurea-mora` funciona desde cualquier directorio.

**🔴 Muy difícil (10)**

10. Diseña la CLI de operación de Áurea. **Criterio:** una página y el esqueleto. *Rúbrica:* (a) qué comandos y para quién (el
    ingeniero, el cron, otro programa); (b) biblioteca, con el arranque medido; (c) códigos de salida y formato de salida
    documentados; (d) cómo se configura en producción y en la máquina del ingeniero.

---

## 📚 7. Referencias

**Documentación oficial**

- `argparse`: https://docs.python.org/3/library/argparse.html
- Typer: https://typer.tiangolo.com/
- `cyclopts`: https://cyclopts.readthedocs.io/en/latest/
- Click: https://click.palletsprojects.com/en/stable/

**Lectura**

- *Command Line Interface Guidelines*: https://clig.dev/

**Orden de lectura sugerido:** *Command Line Interface Guidelines* completo —es corto, y es la mejor guía de ergonomía de
terminal que existe—; después la documentación de la biblioteca elegida.

---

## 🚀 8. Cierre

Una herramienta de terminal se juzga por sus usuarios, que muchas veces son otros programas: código de salida correcto, datos
a `stdout`, errores a `stderr`, `--json` y configuración en capas. `argparse` alcanza para casi todo; Typer y `cyclopts`
compran menos código con una dependencia y un arranque que se mide antes de decidir.

**La señal de que quedó bien:** *"El cron de las 4:00 llama a `aurea-mora --json`, lee el número con `jq`, y si algo falla el
código de salida lo dice."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ui-fase-10 -m "op ui10 cerrada: tres CLI medidas y la ergonomía de una buena ciudadana"
> ```
>
> Los commits llevan su prefijo (`op ui10: …`) y los de ejercicio su número
> (`op ui10 ej07: …`).
