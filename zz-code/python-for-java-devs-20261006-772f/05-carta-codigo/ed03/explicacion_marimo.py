import marimo

app = marimo.App()


@app.cell
def _():
    price = 100_000
    rate = 0.19
    return price, rate


@app.cell
def _(price, rate):
    total = price * (1 + rate)
    return (total,)


@app.cell
def _():
    rate = 0.16
    return (rate,)


if __name__ == "__main__":
    app.run()
