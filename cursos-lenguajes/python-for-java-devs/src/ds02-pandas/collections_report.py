"""Cuánto se ha cobrado de cada plan de tratamiento, por sede y por interés.

Tres versiones de la misma pregunta, que devuelven la misma tabla y cuestan cosas muy
distintas. La diferencia entre ellas no es "pandas avanzado": es **en qué orden se unen y
se agregan los datos**, que es la única decisión de diseño que tiene un informe así.

    from collections_report import collected_naive, collected_vectorized, collected_lean

El encargo es de Marcela, y es el que abre `ds04`: un plan aceptado no es plata cobrada.
El ingreso llega en veinticuatro cuotas, así que "ventas del mes" y "caja del mes" son dos
cifras distintas y solo una de las dos paga la nómina.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

# Las columnas que de verdad hacen falta. Leer el resto es memoria que se paga sin usarse,
# y en `cuotas.csv` son 81.300 filas por columna de más.
PLAN_COLUMNS = ["plan_id", "sede", "interes", "valor_total_cop"]
INSTALLMENT_COLUMNS = ["plan_id", "valor_cop", "fecha_pago"]

# `category` guarda un código entero por fila y el diccionario una sola vez. Con diez sedes
# repetidas en 81.300 filas ahorra entre un 26% y un 37%, medido en la sección 6 — bastante
# menos de lo que promete su fama.
LEAN_DTYPES = {"sede": "category", "interes": "category", "plan_id": "string"}


def read_plans(path: Path, *, lean: bool = False) -> pd.DataFrame:
    """Los planes de tratamiento. Con `lean`, solo las columnas útiles y con dtypes."""
    if not lean:
        return pd.read_csv(path)
    return pd.read_csv(path, usecols=PLAN_COLUMNS,
                       dtype={key: value for key, value in LEAN_DTYPES.items()
                              if key in PLAN_COLUMNS})


def read_installments(path: Path, *, lean: bool = False) -> pd.DataFrame:
    """Las cuotas. `fecha_pago` vacío significa **no pagada**, y eso no es lo mismo que cero."""
    if not lean:
        return pd.read_csv(path)
    return pd.read_csv(path, usecols=INSTALLMENT_COLUMNS,
                       dtype={"plan_id": "string", "valor_cop": "int64"})


# --- Las tres versiones -------------------------------------------------------------

def collected_naive(plans: pd.DataFrame, installments: pd.DataFrame) -> pd.DataFrame:
    """Unir primero, agregar después, y decidir fila por fila con `apply`.

    Es la versión que sale sola cuando uno piensa en filas —que es como piensa cualquiera
    que venga de un `ResultSet`—: junto todo, recorro y sumo. Funciona, da bien, y
    materializa 81.300 filas anchas para producir una tabla de veinte.
    """
    merged = installments.merge(plans, on="plan_id", how="left")
    # `apply` con `axis=1` recorre fila por fila en Python: es un bucle con otro nombre, y
    # el peor de todos porque construye una Series por fila para pasársela a la función.
    merged["cobrado"] = merged.apply(
        lambda row: row["valor_cop"] if isinstance(row["fecha_pago"], str) else 0, axis=1)
    grouped = merged.groupby(["sede", "interes"], observed=True).agg(
        cobrado_cop=("cobrado", "sum"),
        comprometido_cop=("valor_cop", "sum"),
    )
    return finish(grouped)


def collected_vectorized(plans: pd.DataFrame, installments: pd.DataFrame) -> pd.DataFrame:
    """El mismo `merge`, pero sin `apply`: la condición es una máscara sobre la columna.

    Un solo cambio respecto de la anterior, y es el que más se nota: `notna()` decide las
    81.300 filas de una vez, en C, en vez de llamar a una función de Python por cada una.
    """
    merged = installments.merge(plans, on="plan_id", how="left")
    merged["cobrado"] = merged["valor_cop"].where(merged["fecha_pago"].notna(), 0)
    grouped = merged.groupby(["sede", "interes"], observed=True).agg(
        cobrado_cop=("cobrado", "sum"),
        comprometido_cop=("valor_cop", "sum"),
    )
    return finish(grouped)


def collected_lean(plans: pd.DataFrame, installments: pd.DataFrame) -> pd.DataFrame:
    """Agregar primero, unir después. Es la decisión de diseño de la sección.

    Las cuotas se colapsan a una fila por plan —6.100 filas— **antes** de tocar la tabla de
    planes. El `merge` pasa de unir 81.300 filas contra 6.100 a unir 6.100 contra 6.100, y
    además se vuelve verificable: con `validate="1:1"` pandas falla si la llave no es única
    de los dos lados, que es la clase de error que en otro caso descubres por el total.
    """
    # La columna se calcula ANTES de agrupar, y se agrupa sumando. La tentación es
    # `agg(lambda grupo: ...)`, que es legible y vuelve a ser un bucle de Python: una llamada
    # por grupo, y aquí hay 6.100 grupos.
    collected = installments["valor_cop"].where(installments["fecha_pago"].notna(), 0)
    per_plan = (installments.assign(cobrado=collected)
                .groupby("plan_id", observed=True)
                .agg(cobrado_cop=("cobrado", "sum"),
                     comprometido_cop=("valor_cop", "sum")))

    merged = per_plan.merge(plans.set_index("plan_id"), left_index=True, right_index=True,
                            how="left", validate="1:1")
    grouped = merged.groupby(["sede", "interes"], observed=True)[
        ["cobrado_cop", "comprometido_cop"]].sum()
    return finish(grouped)


def finish(grouped: pd.DataFrame) -> pd.DataFrame:
    """El remate común: el porcentaje cobrado y un orden estable.

    Se factoriza para que las tres versiones terminen igual y la comparación sea de lo que
    cambia, no de lo que no. El orden es explícito porque el de `groupby` depende de los
    dtypes —`category` ordena por categoría, `object` alfabéticamente— y una tabla que
    cambia de orden según cómo se leyó el CSV es una tabla que nadie puede diferenciar.
    """
    result = grouped.copy()
    result["cobrado_pct"] = (result["cobrado_cop"] / result["comprometido_cop"] * 100).round(1)
    return result.sort_index()


def frame_memory_mb(frame: pd.DataFrame) -> float:
    """Memoria real del DataFrame, **con** el texto que cuelga de las columnas `object`.

    Sin `deep=True`, pandas reporta el tamaño del bloque de punteros y no el de las cadenas
    apuntadas: el mismo `getsizeof` mentiroso de `ds01`, un nivel más arriba.
    """
    return float(frame.memory_usage(deep=True).sum()) / 1e6
