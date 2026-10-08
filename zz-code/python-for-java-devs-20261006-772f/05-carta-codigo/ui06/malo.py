import marimo

app = marimo.App()


@app.cell
def _():
    tasa = 0.05
    return (tasa,)


@app.cell
def _():
    tasa = 0.045
    return (tasa,)


if __name__ == "__main__":
    app.run()
