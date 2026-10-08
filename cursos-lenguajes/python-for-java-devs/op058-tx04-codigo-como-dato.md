# 🔬 tx04 — Colorear y entender código

> Python para desarrolladores Java senior · **Carta** · Track `tx` — Texto, plantillas y
> documentación · sección 4 de 9
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Colorear sintaxis parece cosmético: el bloque de código bonito en la documentación, en la consola, en el reporte de
un error. Y es la puerta a algo que este perfil sí necesita: **leer código como dato**. Las mismas herramientas que
colorean un archivo son las que permiten buscar en él con precisión, y la diferencia entre ellas es exactamente la
diferencia entre colorear y entender.

El caso de Áurea: en Cartera hubo un descuadre de $0,01 por factura que tardó una semana en encontrarse. Alguien había
escrito `saldo = 0.0` y sumado montos como `float`. La regla de la casa desde entonces es que **la plata nunca va en
`float`** —`int` en pesos o `Decimal`—, y `ruff` no la conoce, porque no sabe qué variables son plata. Esta sección
sube la escalera de herramientas hasta escribir esa regla en treinta líneas.

---

## 🧠 2. El modelo

| Herramienta | Qué ve | Tolera código roto | Lenguajes | Para qué |
|---|---|---|---|---|
| Pygments 2.21.0 | **Fichas**: palabra clave, nombre, número | Sí | Más de 500 | Colorear; nada más |
| `rich.syntax` 15.0.0 | Las fichas de Pygments, en la consola | Sí | Los de Pygments | Mostrar código en una terminal |
| `tree-sitter` 0.26.0 | **Un árbol concreto**, con nodos de error donde no entiende | **Sí** | Decenas, con gramáticas aparte | Editores, búsqueda estructural en muchos lenguajes |
| `ast` (biblioteca estándar) | **El árbol de Python**, exacto | **No**: un error de sintaxis y no hay árbol | Solo Python | Analizar y reescribir Python (`tx07`) |
| `libcst` 1.9.0 | El árbol de Python **con comentarios y espacios** | No | Solo Python | Reescribir sin cambiar el formato |

Colorear necesita saber que `0.0` es un número. Entender necesita saber que `0.0` es el valor que se le asigna a
`saldo`. Lo primero lo da una ficha; lo segundo, un árbol.

### Tu instinto de Java dice… y esta vez se equivoca

En Java, analizar código es territorio de herramientas pesadas —JavaParser, el compilador con un *annotation
processor*, Error Prone— y escribir una regla propia es un proyecto. En Python, `ast` viene con el lenguaje, y una regla
propia es una función que recorre un árbol. El instinto subestima lo barato que es.

---

## 💻 3. El ejemplo que corre

```bash
uv add pygments tree-sitter tree-sitter-python
```

`plata.py`:

```python
"""Tres formas de leer el mismo código: fichas, árbol tolerante y árbol exacto."""

import ast

import tree_sitter_python
from pygments.lexers import PythonLexer
from pygments.token import Number
from tree_sitter import Language, Parser

SOURCE = """\
def cerrar_caja(pagos):
    saldo = 0.0
    tasa = 0.19
    for pago in pagos:
        saldo += pago.monto
    return saldo
"""
BROKEN = SOURCE.replace("for pago in pagos:", "for pago in pagos")      # falta el ':'
MONEY = ("saldo", "monto", "valor", "total", "abono")

# ------------------------------------------------- 1. fichas (Pygments)
floats = [v for t, v in PythonLexer().get_tokens(SOURCE) if t in Number.Float]
print("Pygments ve números decimales:", floats, "— pero no a qué se asignan")

# ------------------------------------------------- 2. árbol tolerante (tree-sitter)
parser = Parser(Language(tree_sitter_python.language()))


def ts_findings(code: str) -> list[str]:
    tree = parser.parse(code.encode())
    found, stack = [], [tree.root_node]
    while stack:
        node = stack.pop()
        stack.extend(node.children)
        if node.type == "assignment":
            left, right = node.child_by_field_name("left"), node.child_by_field_name("right")
            if right is not None and right.type == "float" and left.text.decode().startswith(MONEY):
                found.append(f"línea {node.start_point[0] + 1}: {left.text.decode()} = {right.text.decode()}")
    return found


print("tree-sitter, código sano:", ts_findings(SOURCE))
print("tree-sitter, código roto:", ts_findings(BROKEN))


# ------------------------------------------------- 3. árbol exacto (ast): la regla de la casa
class NoFloatMoney(ast.NodeVisitor):
    def __init__(self):
        self.found = []

    def visit_Assign(self, node: ast.Assign):
        is_float = isinstance(node.value, ast.Constant) and isinstance(node.value.value, float)
        for target in node.targets:
            if is_float and isinstance(target, ast.Name) and target.id.startswith(MONEY):
                self.found.append(f"línea {node.lineno}: '{target.id}' es plata y no puede ser float")
        self.generic_visit(node)


def ast_findings(code: str) -> list[str]:
    try:
        checker = NoFloatMoney()
        checker.visit(ast.parse(code))
        return checker.found
    except SyntaxError as e:
        return [f"sin árbol: {e.msg} (línea {e.lineno})"]


print("ast, código sano:", ast_findings(SOURCE))
print("ast, código roto:", ast_findings(BROKEN))
```

```bash
python3 plata.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
Pygments ve números decimales: ['0.0', '0.19'] — pero no a qué se asignan
tree-sitter, código sano: ['línea 2: saldo = 0.0']
tree-sitter, código roto: ['línea 2: saldo = 0.0']
ast, código sano: ["línea 2: 'saldo' es plata y no puede ser float"]
ast, código roto: ["sin árbol: expected ':' (línea 4)"]
```

La escalera completa en cinco líneas. Pygments encuentra los dos decimales y no puede distinguir `saldo = 0.0`
(prohibido) de `tasa = 0.19` (una tasa de IVA, que puede ser `float`). `tree-sitter` sí distingue, y además lo hace
sobre el código roto, que es la razón por la que los editores lo usan: el archivo que se está escribiendo casi nunca
compila. `ast` distingue con precisión de Python, y no tiene nada que decir de un archivo que no compila.

**Detalles con intención**

- **La regla vive en `ast`**, no en `tree-sitter`: en el CI, el código siempre compila, y `ast` viene con Python, sin
  dependencias ni gramáticas que actualizar. `tree-sitter` se justifica en un editor o con varios lenguajes.
- **`MONEY` es una lista de prefijos**: una heurística deliberada. `saldo_inicial` cae; `tasa` no. Una regla exacta
  necesitaría tipos (`mypy` con un `NewType` para pesos), que es otra solución, más fuerte y más cara.
- **`child_by_field_name("left")`** usa los nombres de campo de la gramática de Python de `tree-sitter`; cada lenguaje
  tiene los suyos, y se consultan en el `grammar.js` de la gramática.

---

## ⚠️ 4. Lo que se rompe

**Buscar con expresiones regulares.** `grep "saldo = 0.0"` no encuentra `saldo=0.` ni `saldo: float = 0.0`, y encuentra
la línea dentro de un comentario o de una cadena. Es el primer reflejo y el error que estas herramientas evitan.

**`ast.unparse` para reescribir el archivo.** Reescribir con `ast` pierde comentarios y formato: el archivo corregido
sale sin un solo comentario. Para *reescribir* código de personas, `libcst`, que conserva todo; `ast` es para leer o
para generar código nuevo (`tx07`).

**Las versiones de `tree-sitter`.** La biblioteca y las gramáticas se versionan aparte, y la API de Python cambió entre
versiones recientes (consultas, cursores). Fijar las dos versiones juntas en el archivo de bloqueo evita la sorpresa.

**El *lexer* equivocado.** Pygments adivina el lenguaje si no se le dice (`guess_lexer`) y se equivoca con fragmentos
cortos: el YAML coloreado como si fuera otra cosa. En documentación, el lenguaje se declara siempre.

---

## ⚖️ 5. Cuándo NO usarlo

**Una regla que `ruff` ya tiene.** Antes de escribir un recorrido de `ast`, se busca en las reglas de `ruff`: tiene más
de ochocientas, y las mantiene otro.

**`tree-sitter` para analizar solo Python en CI.** Una dependencia nativa, una gramática con su versión y una API que
cambia, para lo que `ast` hace sin instalar nada.

**Un *linter* propio para una regla que se viola una vez al año.** La revisión de código la atrapa. La regla de la
plata se justificó porque costó una semana; ese es el umbral.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Colorea `plata.py` en la consola con `rich.syntax.Syntax`. **Criterio:** se ve con números de línea y el tema que
   elijas.
2. Lista los tipos de ficha que Pygments produce para la línea `saldo += pago.monto`. **Criterio:** la lista, y cuál
   ficha te diría que es una suma.
3. Cambia `saldo = 0.0` por `saldo: float = 0.0` y corre. **Criterio:** reportas qué herramientas lo detectan todavía y
   por qué no las otras.

**🟡 Intermedio (4–6)**

4. Extiende la regla de `ast` a `AnnAssign` y a `float(...)` asignado a un nombre de plata. **Criterio:** una prueba
   con tres casos que caen y dos que no.
5. Usa `ast.dump(..., indent=2)` sobre `SOURCE`. **Criterio:** identificas en el volcado el nodo que la regla revisa.
6. Exporta el código coloreado a HTML con Pygments para la documentación. **Criterio:** un archivo HTML con su CSS
   que se ve igual sin conexión.

**🟠 Difícil (7–9)**

7. Haz la regla con una consulta de `tree-sitter` en vez de recorrer el árbol a mano. **Criterio:** los mismos
   hallazgos que el recorrido.
8. Escribe con `libcst` el *codemod* que cambia `saldo = 0.0` por `saldo = Decimal("0")` y agrega el `import`.
   **Criterio:** los comentarios del archivo sobreviven.
9. Convierte la regla en un *plugin* de `pre-commit` que corra sobre los archivos cambiados. **Criterio:** un
   *commit* con `saldo = 0.0` se rechaza con el número de línea.

**🔴 Muy difícil (10)**

10. Mide cuánto tardan `ast` y `tree-sitter` en analizar un proyecto grande (por ejemplo, el código fuente de una
    biblioteca conocida). **Criterio:** una tabla. *Rúbrica:* (a) tiempo total y por archivo; (b) cuántos archivos
    no pudo leer cada uno; (c) en qué escenario gana cada uno; (d) declaras la máquina y las versiones.

---

## 📚 7. Referencias

**Documentación oficial**

- `ast`: https://docs.python.org/3/library/ast.html
- Pygments: https://pygments.org/docs/
- `py-tree-sitter`: https://tree-sitter.github.io/py-tree-sitter/
- `libcst`: https://libcst.readthedocs.io/en/latest/

**Lectura**

- *Green Tree Snakes*, la guía no oficial de `ast`: https://greentreesnakes.readthedocs.io/en/latest/

**Orden de lectura sugerido:** *Green Tree Snakes*, que explica los nodos con ejemplos; después la documentación de
`ast` como referencia.

---

## 🚀 8. Cierre

Colorear necesita fichas; entender necesita un árbol. Pygments colorea, `tree-sitter` entiende código roto y de muchos
lenguajes, y `ast` entiende Python con la precisión del propio intérprete. Una regla que la casa aprendió a golpes cabe
en treinta líneas sobre `ast`, y corre en cada push.

**La señal de que quedó bien:** *"Desde que corre la regla, nadie volvió a escribir un saldo en `float`, y el CI dice en
qué línea."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-tx-fase-04 -m "op tx04 cerrada: fichas, árboles y la regla de la plata en ast"
> ```
>
> Los commits llevan su prefijo (`op tx04: …`) y los de ejercicio su número
> (`op tx04 ej07: …`).
