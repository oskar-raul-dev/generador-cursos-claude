"""La noche de Áurea en Dagster: assets que dependen de los assets que reciben."""

from dagster import asset, materialize


@asset
def rips_consolidado() -> list[dict]:
    return [{"sede": "Suba", "valor": 185000}, {"sede": "Centro", "valor": 95000}]


@asset
def radicacion(rips_consolidado: list[dict]) -> int:
    # Depende de rips_consolidado porque lo recibe por nombre: no hay que declararlo aparte.
    return len(rips_consolidado)


@asset
def regalias(rips_consolidado: list[dict]) -> dict[str, float]:
    return {r["sede"]: r["valor"] * 0.06 for r in rips_consolidado if r["sede"] != "Centro"}


@asset
def informe_patricia(radicacion: int, regalias: dict[str, float]) -> str:
    return f"radicadas {radicacion}, regalías {regalias}"


if __name__ == "__main__":
    result = materialize([rips_consolidado, radicacion, regalias, informe_patricia])
    print("éxito:", result.success)
    print(result.output_for_node("informe_patricia"))
