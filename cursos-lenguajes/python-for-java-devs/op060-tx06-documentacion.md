# 📚 tx06 — Documentación como producto

> Python para desarrolladores Java senior · **Carta** · Track `tx` — Texto, plantillas y
> documentación · sección 6 de 9
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El paquete interno `aurea-cartera` lo usan tres procesos y, desde el año pasado, el desarrollador externo que
contrató la franquicia de Zipaquirá. La documentación es un `README` de hace dos años con ejemplos que ya no
corren: la función `formato_pesos` cambió de nombre, el ejemplo de cálculo de mora devuelve otro número desde que
se corrigió el redondeo, y nadie lo notó porque nadie ejecuta un `README`.

Esa es la enfermedad de toda documentación técnica: **se separa del código**. Python tiene dos remedios que Java no
trae de la misma forma. El primero: los ejemplos de la documentación **son pruebas** (`doctest`), y fallan cuando el
código cambia. El segundo: la referencia de la API **se genera** de los *docstrings* y de las anotaciones de tipo,
que viven al lado del código. Lo que queda escrito a mano —la guía, el porqué— es lo que una máquina no puede generar.

---

## 🧠 2. El modelo

La documentación tiene cuatro tipos distintos, y cada uno se produce de una forma (el marco Diátaxis):

| Tipo | Pregunta que responde | Cómo se produce en Python |
|---|---|---|
| Tutorial | "¿Cómo empiezo?" | A mano, con ejemplos que son `doctest` |
| Guía práctica | "¿Cómo hago X?" | A mano |
| **Referencia** | "¿Qué recibe y qué devuelve esta función?" | **Generada** de *docstrings* y tipos |
| Explicación | "¿Por qué funciona así?" | A mano |

Y las herramientas, de la más liviana a la más completa:

| Herramienta | Qué hace | Para qué |
|---|---|---|
| `doctest` (biblioteca estándar) | Corre los ejemplos `>>>` de los *docstrings* | Que los ejemplos no mientan |
| `pdoc` 16.0.0 | Referencia HTML de un paquete, sin configuración | Una biblioteca interna |
| MkDocs 1.6.1 💤 + Material 9.7.7 + `mkdocstrings` | Sitio en Markdown con la referencia incrustada | Documentación de un proyecto, con guías |
| Sphinx 9.1.0 | El estándar de Python: reStructuredText o MyST, referencias cruzadas, PDF | Proyectos grandes; la documentación de Python misma |
| `griffe` 2.3.0 | Extrae la API como datos, sin importar el código | Detectar cambios que rompen la API entre versiones |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, Javadoc es una herramienta y un formato, y no hay discusión. En Python, el formato de los *docstrings* no está
fijado —Google, NumPy, reStructuredText— y el generador tampoco. El instinto busca "el Javadoc de Python" y encuentra
cuatro. La decisión que sí importa es otra que Javadoc nunca tuvo: **que los ejemplos se ejecuten**.

---

## 💻 3. El ejemplo que corre

```bash
uv add --dev pdoc
```

`cartera.py`:

```python
"""Cálculos de cartera de la red Áurea.

Los montos son enteros en pesos: la plata nunca va en float.

>>> mora = interes_de_mora(1_250_000, dias=45)
>>> formato_pesos(mora)
'$28.125'
"""


def formato_pesos(valor: int) -> str:
    """Formatea un monto en pesos con punto de miles.

    >>> formato_pesos(1234567)
    '$1.234.567'
    >>> formato_pesos(0)
    '$0'
    """
    return "$" + f"{valor:,}".replace(",", ".")


def interes_de_mora(saldo: int, dias: int, tasa_mensual_pct: int = 15) -> int:
    """Interés de mora simple sobre un saldo, por días, redondeado al peso.

    La tasa es mensual y en décimas de punto porcentual (15 = 1,5 %), para no usar float.

    >>> interes_de_mora(1_000_000, dias=30)
    15000
    >>> interes_de_mora(1_000_000, dias=0)
    0
    """
    return round(saldo * tasa_mensual_pct * dias / (1000 * 30))
```

```bash
python3 -m doctest -v cartera.py | tail -3
pdoc cartera.py -o docs && ls docs
```

Salida (Python 3.14.7, 05/10/2026):

```text
6 tests in 3 items.
6 passed.
Test passed.
cartera.html
index.html
search.js
```

Seis ejemplos que son pruebas, y una referencia en HTML generada sin una línea de configuración. Ahora el cambio que
mató al `README` viejo: alguien sube la tasa por defecto a 18 y no toca los *docstrings*.

```bash
sed -i 's/tasa_mensual_pct: int = 15/tasa_mensual_pct: int = 18/' cartera.py
python3 -m doctest cartera.py | head -8
```

Salida (Python 3.14.7, 05/10/2026):

```text
**********************************************************************
File "/w/cartera.py", line 6, in cartera
Failed example:
    formato_pesos(mora)
Expected:
    '$28.125'
Got:
    '$33.750'
```

El ejemplo del módulo falla, y con él el de `interes_de_mora`. La documentación dejó de poder mentir: o se actualiza
el ejemplo, o se revierte el cambio, pero el CI no deja pasar las dos cosas distintas.

**Detalles con intención**

- **`doctest` en el CI** se corre con `pytest --doctest-modules`, junto a las demás pruebas, sin herramienta aparte.
- **Los ejemplos del *docstring* son pocos y claros**: documentan el uso, no prueban casos límite. Las pruebas de
  verdad siguen en `tests/`; el `doctest` garantiza que lo que lee una persona es cierto.
- **`pdoc` lee las anotaciones de tipo** y las muestra en la referencia: `saldo: int` no hay que repetirlo en el
  texto. Es la razón para escribir tipos aunque no se corra `mypy`.
- **La salida del primer bloque pasa por `tail -3`**: `doctest -v` imprime cada ejemplo y su resultado, y el resumen
  es lo único que interesa en un informe.

---

## ⚠️ 4. Lo que se rompe

**`doctest` con salidas que cambian.** Un diccionario impreso, una fecha de hoy o la dirección de memoria de un objeto
hacen fallar el ejemplo sin que el código haya cambiado. Se escribe el ejemplo para que su salida sea estable
(ordenar, fijar la fecha), o se usa `# doctest: +ELLIPSIS` para la parte variable.

**MkDocs sin versiones nuevas.** MkDocs 1.6.1 es de agosto de 2024 (💤), y el ecosistema discute su continuidad; Material
for MkDocs, el tema que casi todos usan, sí publica seguido. Para un proyecto nuevo es una dependencia que vigilar; para
uno que ya lo usa, sigue funcionando.

**Sphinx para una biblioteca de tres módulos.** Un `conf.py`, reStructuredText o MyST, extensiones para leer
*docstrings* de Google, un tema. Es la herramienta correcta para la documentación de Python misma; para `aurea-cartera`,
`pdoc` da lo mismo sin configuración.

**La referencia que se publica y nadie lee.** Generar HTML es fácil; lo que el desarrollador de Zipaquirá necesitaba era
una guía práctica de "cómo calculo la mora de un paciente", escrita por una persona.

---

## ⚖️ 5. Cuándo NO usarlo

**`doctest` como única prueba.** Es una prueba de documentación. Los casos límite, los errores y las propiedades van en
`pytest` (`qa`), donde se leen y se mantienen mejor.

**Un sitio de documentación para un script.** Un script de cien líneas que usa una persona necesita un `--help` claro y un
*docstring* de módulo. Nada más.

**Documentación generada sin *docstrings*.** `pdoc` o `mkdocstrings` sobre un código sin *docstrings* produce una lista de
firmas. Es una referencia vacía con apariencia de documentación.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Agrega un ejemplo que muestre que `formato_pesos(-5000)` devuelve `'$-5.000'`. **Criterio:** el `doctest` pasa, y
   opinas si ese formato es el correcto para un franquiciado.
2. Corre los `doctest` con `pytest --doctest-modules`. **Criterio:** reportas cuántas pruebas cuenta `pytest` y por qué no son seis.
3. Abre `docs/cartera.html`. **Criterio:** identificas de dónde salió cada parte (docstring, tipo, valor por defecto).

**🟡 Intermedio (4–6)**

4. Arma un sitio con MkDocs Material y `mkdocstrings` que tenga una guía y la referencia. **Criterio:** la referencia se
   genera del código; la guía es Markdown escrito a mano.
5. Escribe los *docstrings* en formato Google (`Args:`, `Returns:`) y genera con `pdoc --docformat google`. **Criterio:**
   los argumentos salen como lista en el HTML.
6. Usa `griffe` para comparar la API de dos versiones de `cartera.py` donde cambió un argumento. **Criterio:** `griffe`
   reporta el cambio que rompe la compatibilidad.

**🟠 Difícil (7–9)**

7. Haz el tutorial de `aurea-cartera` en un archivo Markdown cuyos ejemplos se ejecuten con `doctest` o con
   `pytest --doctest-glob`. **Criterio:** romper la función rompe el tutorial.
8. Publica la documentación en GitHub Pages desde el CI. **Criterio:** un push a `main` actualiza el sitio.
9. Escribe la guía práctica "cómo calcular la mora de un paciente" pensando en el desarrollador de Zipaquirá.
   **Criterio:** alguien que no conoce el paquete lo hace con la guía en menos de diez minutos (pruébalo con una
   persona).

**🔴 Muy difícil (10)**

10. Audita la documentación de un proyecto tuyo con el marco Diátaxis. **Criterio:** una tabla y una página. *Rúbrica:*
    (a) cada documento clasificado en uno de los cuatro tipos; (b) los tipos que faltan; (c) qué parte se puede generar
    o ejecutar y hoy está escrita a mano; (d) el plan para cerrar el hueco más caro.

---

## 📚 7. Referencias

**Documentación oficial**

- `doctest`: https://docs.python.org/3/library/doctest.html
- `pdoc`: https://pdoc.dev/docs/pdoc.html
- Material for MkDocs: https://squidfunk.github.io/mkdocs-material/
- Sphinx: https://www.sphinx-doc.org/en/master/
- `griffe`: https://mkdocstrings.github.io/griffe/

**Lectura**

- Daniele Procida, *Diátaxis*: https://diataxis.fr/

**Orden de lectura sugerido:** *Diátaxis* (se lee en una hora y cambia cómo se organiza cualquier documentación);
después la documentación de `doctest`.

---

## 🚀 8. Cierre

La documentación se separa del código salvo que se lo impidan. Los ejemplos se escriben como `doctest` y corren en el CI;
la referencia se genera de los *docstrings* y los tipos; y lo que queda a mano —el tutorial, la guía, el porqué— es lo
que una persona necesita y una máquina no sabe escribir.

**La señal de que quedó bien:** *"Cambiamos la tasa de mora y el CI falló en el ejemplo del docstring antes de que
nadie lo leyera mal."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-tx-fase-06 -m "op tx06 cerrada: ejemplos que son pruebas y referencia generada"
> ```
>
> Los commits llevan su prefijo (`op tx06: …`) y los de ejercicio su número
> (`op tx06 ej07: …`).
