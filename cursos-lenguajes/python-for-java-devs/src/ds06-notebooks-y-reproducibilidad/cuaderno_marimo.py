"""El mismo análisis en marimo. **Es un archivo `.py`**, y eso es la mitad del argumento.

    uv run --with marimo==0.24.2 python cuaderno_marimo.py     # corre como script
    uv run --with marimo==0.24.2 marimo edit cuaderno_marimo.py  # se edita como cuaderno

marimo no guarda salidas y no tiene `execution_count`: el orden lo decide el **grafo de
dependencias** entre celdas, no el orden en que alguien les dio a ejecutar. Por eso el
defecto de `estado-oculto.ipynb` no se puede escribir aquí — si una celda usa `adquiridos`,
marimo la ejecuta después de la que lo define, esté donde esté en el archivo.

Y por eso el diff de git es legible: es código Python, no un JSON con imágenes en base64.
"""

import marimo

app = marimo.App()


@app.cell
def _():
    gasto = {"tiktok": 2020, "instagram": 2020, "google": 2020}
    return (gasto,)


@app.cell
def _(gasto, adquiridos):
    # Esta celda está ANTES de la que define `adquiridos` y funciona igual: marimo resuelve
    # el orden por dependencias. En Jupyter, esto mismo es el bug de `estado-oculto.ipynb`.
    costos = {canal: gasto[canal] * 1e6 / adquiridos[canal] for canal in gasto}
    print(sorted(costos, key=costos.get))
    return (costos,)


@app.cell
def _():
    adquiridos = {"tiktok": 182, "instagram": 529, "google": 1275}
    return (adquiridos,)


if __name__ == "__main__":
    app.run()
