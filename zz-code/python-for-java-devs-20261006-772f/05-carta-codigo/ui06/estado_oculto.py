"""El estado oculto de Jupyter, simulado: celdas que comparten un espacio de nombres."""

cells = {
    "tasa": "tasa = 0.05",
    "ventas": "ventas = 142_900_000",
    "regalia": "regalia = round(ventas * tasa)",
}
ns: dict = {}
for name in ("tasa", "ventas", "regalia"):
    exec(cells[name], ns)
print("primera corrida:", ns["regalia"])

cells["tasa"] = "tasa = 0.045"           # el contrato de Suba dice 4,5 %: se corrige la celda…
exec(cells["tasa"], ns)                  # …y se corre solo esa
print("la celda dice 4,5 %, el resultado es:", ns["regalia"])
