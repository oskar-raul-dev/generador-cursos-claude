# 🏗️ tx07 — Generación de código y andamiaje

> Python para desarrolladores Java senior · **Carta** · Track `tx` — Texto, plantillas y
> documentación · sección 7 de 9
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Dos tareas que se parecen y se resuelven distinto. La primera: **arrancar un proyecto** con la forma de la casa —el
`pyproject.toml` con `ruff` y `pytest`, el `Dockerfile`, el CI, la estructura de carpetas— sin copiar el último
proyecto y borrar lo que sobra. La segunda: **generar código a partir de datos** —las clases de Python que
corresponden a las tablas de la base de Cartera, o a un esquema de la API de la pasarela—.

Para la primera hay herramientas de andamiaje: `cookiecutter` y `copier`. Para la segunda, el reflejo es una plantilla
de texto, y ahí está el error de esta sección: **generar Python con cadenas es generar Python sin saber Python**. Una
columna llamada `class`, un valor por defecto con una comilla, una indentación de más, y el archivo generado no
compila. Python trae la alternativa en la biblioteca estándar: construir el árbol con `ast` y dejar que `ast.unparse`
escriba el código.

---

## 🧠 2. El modelo

| Tarea | Herramienta | Qué genera | Se actualiza después |
|---|---|---|---|
| Arrancar un proyecto | `cookiecutter` 2.7.1 | Un directorio desde una plantilla con Jinja2 | **No**: genera una vez |
| Arrancar y mantener | `copier` 9.18.2 | Lo mismo, y recuerda la plantilla y las respuestas | **Sí**: `copier update` trae los cambios de la plantilla |
| Código desde datos (simple) | Plantilla de texto | Texto que debería ser Python | Se regenera |
| Código desde datos (correcto) | `ast` + `ast.unparse` | Un árbol que **es** Python | Se regenera |
| Reescribir código existente | `libcst` (`tx04`) | Cambios que conservan el formato | — |

La diferencia entre `cookiecutter` y `copier` es la que importa en una empresa con varios proyectos: cuando la plantilla
de la casa cambia —una versión nueva de `ruff`, un paso más en el CI—, los proyectos hechos con `copier` la reciben con
un comando, y los hechos con `cookiecutter` no.

### Tu instinto de Java dice… y esta vez se equivoca

En Java, generar código es JavaPoet o un procesador de anotaciones: siempre un modelo del código, nunca cadenas. El
instinto es el correcto, y lo que confunde es que en Python **parece** innecesario, porque el lenguaje es tan simple de
escribir como texto. El ejemplo muestra lo que se rompe.

---

## 💻 3. El ejemplo que corre

Sin dependencias. `generar.py` genera una `dataclass` por tabla a partir de la descripción de sus columnas, de las dos
formas, y prueba si el resultado compila.

```python
"""Generar Python desde datos: con cadenas y con el árbol de sintaxis."""

import ast
import keyword

# Lo que sale del catálogo de la base de Cartera (simplificado).
TABLE = "abono"
COLUMNS = [
    ("id", "int", None),
    ("valor", "int", 0),
    ("class", "str", "efectivo"),                 # la columna se llama así en la base heredada
    ("nota", "str", "pago d'Alessandro"),         # un valor por defecto con comilla
]


def with_strings() -> str:
    lines = ["from dataclasses import dataclass", "", "", "@dataclass",
             f"class {TABLE.title()}:"]
    for name, typ, default in COLUMNS:
        suffix = "" if default is None else f" = '{default}'" if typ == "str" else f" = {default}"
        lines.append(f"    {name}: {typ}{suffix}")
    return "\n".join(lines) + "\n"


def with_ast() -> str:
    body = []
    for name, typ, default in COLUMNS:
        attr = f"{name}_" if keyword.iskeyword(name) else name   # PEP 8: 'class' -> 'class_'
        body.append(ast.AnnAssign(
            target=ast.Name(attr, ast.Store()), annotation=ast.Name(typ, ast.Load()),
            value=None if default is None else ast.Constant(default), simple=1))
    module = ast.Module(body=[
        ast.ImportFrom("dataclasses", [ast.alias("dataclass")], 0),
        ast.ClassDef(name=TABLE.title(), bases=[], keywords=[], body=body,
                     decorator_list=[ast.Name("dataclass", ast.Load())], type_params=[]),
    ], type_ignores=[])
    return ast.unparse(ast.fix_missing_locations(module)) + "\n"


for label, generate in [("cadenas", with_strings), ("ast", with_ast)]:
    code = generate()
    try:
        compile(code, f"<{label}>", "exec")
        print(f"--- {label}: compila\n{code}")
    except SyntaxError as e:
        print(f"--- {label}: NO compila — {e.msg} (línea {e.lineno})\n{code}")
```

```bash
python3 generar.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
--- cadenas: NO compila — unterminated string literal (detected at line 9) (línea 9)
from dataclasses import dataclass


@dataclass
class Abono:
    id: int
    valor: int = 0
    class: str = 'efectivo'
    nota: str = 'pago d'Alessandro'

--- ast: compila
from dataclasses import dataclass

@dataclass
class Abono:
    id: int
    valor: int = 0
    class_: str = 'efectivo'
    nota: str = "pago d'Alessandro"
```

La versión con cadenas tiene dos errores y no compila; los dos son de datos, no de la plantilla, y aparecieron el día
que el catálogo trajo una columna que nadie había previsto. El compilador solo reporta el de la línea 9 —la comilla—
aunque el de la línea 8 está antes: el analizador léxico corre primero sobre todo el archivo. Quien corrija la comilla
se encuentra después con el `class`, en una segunda vuelta. La versión con `ast` no tiene ninguno: `ast.unparse` eligió
comillas dobles para la cadena con apóstrofo, y `class` se convirtió en `class_` porque el generador sabe que está
generando un nombre de Python y pregunta si es palabra reservada.

**Detalles con intención**

- **`ast.Constant(default)`** sabe escribir cualquier constante de Python —cadenas, números, `None`, bytes— con su
  sintaxis correcta. Es la parte del escape que el generador con cadenas tenía que hacer a mano.
- **`keyword.iskeyword`** sigue al intérprete que corre: si una versión futura de Python agrega una palabra reservada,
  el generador la conoce sin cambiar.
- **`ast.unparse` no da formato bonito**: deja una sola línea en blanco y no respeta el estilo de la casa. Se pasa el
  resultado por `ruff format`, y el archivo generado queda igual que uno escrito a mano.
- **`type_params=[]`** es obligatorio en `ClassDef` desde Python 3.12. Los constructores de nodos de `ast` cambian con
  las versiones de Python, y es el costo de este enfoque.

---

## ⚠️ 4. Lo que se rompe

**Código generado editado a mano.** Alguien corrige una clase generada, y la próxima generación borra la corrección. Los
archivos generados llevan un encabezado que lo dice (`# Generado por generar.py; no editar`), y van en un directorio
aparte o con un sufijo.

**`cookiecutter` y la plantilla que evoluciona.** Treinta proyectos generados en tres años, cada uno con la versión de
la plantilla de su momento. Cuando la casa cambia de `flake8` a `ruff`, son treinta cambios a mano. Con `copier`, son
treinta `copier update` que se revisan como cualquier otro cambio.

**`copier update` con conflictos.** Si el proyecto modificó un archivo que la plantilla también cambió, `copier` deja
marcas de conflicto como `git`. Es lo correcto, y obliga a resolverlas; no es automático.

**Generar con Jinja2 lo que tiene árbol.** Una plantilla de Jinja2 que genera Python (o SQL, o JSON) repite el problema de
las cadenas con mejor aspecto. Jinja2 sirve para los archivos de configuración del andamiaje; para código desde datos, el
árbol.

---

## ⚖️ 5. Cuándo NO usarlo

**Generar código que podría ser dinámico.** Si las clases se pueden construir en tiempo de ejecución
(`dataclasses.make_dataclass`, o un modelo de Pydantic creado con `create_model`), no hace falta un archivo generado
que mantener. Se genera cuando el código tiene que existir antes de correr: para el autocompletado, para `mypy`, para
leerlo.

**Una plantilla de proyecto para dos proyectos.** `copier` se paga cuando hay varios proyectos que deben seguir la misma
forma. Para dos, copiar y ajustar es más rápido, y la plantilla se extrae el día del tercero.

**`ast` para generar cinco líneas fijas.** Si el código generado no depende de datos externos, una cadena es suficiente y
más legible.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Pasa la salida de `with_ast` por `ruff format`. **Criterio:** muestras la diferencia de formato.
2. Agrega una columna `fecha` de tipo `date` con valor por defecto `None`. **Criterio:** el generador agrega el `import`
   que falta, y el resultado compila.
3. Agrega el encabezado `# Generado; no editar` al archivo generado. **Criterio:** `ast.unparse` no conserva
   comentarios: explicas cómo lo agregaste.

**🟡 Intermedio (4–6)**

4. Genera las clases a partir del catálogo real de una base SQLite (`PRAGMA table_info`). **Criterio:** una clase por
   tabla, todas compilan.
5. Crea una plantilla de `copier` para los proyectos de Áurea con `pyproject.toml`, `ruff` y `pytest`. **Criterio:**
   `copier copy` genera un proyecto cuyas pruebas pasan.
6. Cambia la plantilla (agrega una regla de `ruff`) y corre `copier update` en el proyecto generado. **Criterio:** el
   cambio llega, y lo muestras en un `git diff`.

**🟠 Difícil (7–9)**

7. Genera también las funciones `from_row(row: tuple)` de cada clase con `ast`. **Criterio:** una prueba carga una fila
   de SQLite con la función generada.
8. Agrega una prueba de "regenerar y comparar": falla si el archivo generado en el repositorio no coincide con lo que
   produce el generador. **Criterio:** editar a mano la clase generada hace fallar la prueba.
9. Provoca un conflicto en `copier update` y resuélvelo. **Criterio:** describes qué archivo, por qué, y cómo lo
   resolviste.

**🔴 Muy difícil (10)**

10. Diseña la plantilla de proyecto de Áurea. **Criterio:** una página y la plantilla. *Rúbrica:* (a) qué incluye y qué
    no, con su razón; (b) qué preguntas hace al generar; (c) cómo llega una mejora a los proyectos existentes; (d) quién
    es el dueño de la plantilla y cómo se versiona.

---

## 📚 7. Referencias

**Documentación oficial**

- `ast`, construir y `unparse`: https://docs.python.org/3/library/ast.html#ast.unparse
- `copier`: https://copier.readthedocs.io/en/stable/
- `cookiecutter`: https://cookiecutter.readthedocs.io/en/stable/
- `keyword`: https://docs.python.org/3/library/keyword.html

**Orden de lectura sugerido:** la sección de actualización de proyectos de la documentación de `copier`; después la
documentación de `ast` como referencia de los nodos.

---

## 🚀 8. Cierre

Arrancar proyectos y generar código son dos tareas. Para la primera, `copier`, porque la plantilla evoluciona y los
proyectos la reciben. Para la segunda, el árbol: `ast` construye Python que compila sin importar qué traigan los datos, y
`ruff format` le da la forma de la casa. Las cadenas generan algo que parece Python hasta el día que llega la columna
`class`.

**La señal de que quedó bien:** *"El catálogo trajo una columna con nombre de palabra reservada y el generador produjo
`class_` sin que nadie se enterara."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-tx-fase-07 -m "op tx07 cerrada: copier para proyectos y ast para generar código"
> ```
>
> Los commits llevan su prefijo (`op tx07: …`) y los de ejercicio su número
> (`op tx07 ej07: …`).
