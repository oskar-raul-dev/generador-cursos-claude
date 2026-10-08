import marimo

__generated_with = "0.25.1"
app = marimo.App()


@app.cell
def _():
    tasa = 0.045                       # contrato de franquicia de Suba
    return (tasa,)


@app.cell
def _():
    ventas = 142_900_000
    return (ventas,)


@app.cell
def _(tasa, ventas):
    regalia = round(ventas * tasa)
    print(f"Regalía de Suba: ${regalia:,}".replace(",", "."))
    return (regalia,)


if __name__ == "__main__":
    app.run()
