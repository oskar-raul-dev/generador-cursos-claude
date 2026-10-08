"""El mismo tablero, cuatro veces: tabla, matplotlib, plotly y altair.

    from dashboard import as_table, as_matplotlib, as_plotly, as_altair

Lo que se dibuja es el resultado de `ds04`: el costo por paciente adquirido por canal, **con
la banda entre modelos de atribución**. Esa banda es el requisito y no un adorno — un gráfico
de barras con una sola cifra por canal es exactamente el gráfico bonito con el que se cuenta
la mentira que `ds04` desmontó.

🧭 **Regla de la sección: si el dato tiene incertidumbre, el dibujo la muestra o el dibujo
miente.** Aplica igual a una barra que a una tabla.
"""

from __future__ import annotations

from pathlib import Path

from palette import BRAND

# El resultado medido en `ds04` §6, en millones de pesos. Va aquí como constante y no se
# recalcula: esta sección es sobre **cómo se presenta** un número, y recalcularlo metería
# trece segundos de bootstrap dentro de una medición de render.
#
# canal: (mínimo entre modelos, lineal, máximo entre modelos)
AUREA_CAC = {
    "tiktok": (1.06, 1.93, 7.96),
    "instagram": (1.14, 1.74, 3.35),
    "google": (1.55, 2.01, 2.76),
}

TITLE = "Costo por paciente adquirido · Áurea · corte 2026-03-31"
SUBTITLE = "Punto: atribución lineal. Banda: el mínimo y el máximo entre los cuatro modelos."


def as_table(data: dict[str, tuple[float, float, float]] = AUREA_CAC) -> str:
    """El tablero como tabla de texto. Cero dependencias, cero render, cero color.

    Es el competidor de verdad de esta sección, y la sección 6 dice cuándo gana. No es una
    versión pobre del gráfico: para siete cifras que alguien va a citar en una reunión, el
    valor exacto importa más que la forma, y una tabla se pega en un correo.
    """
    lines = [TITLE, SUBTITLE, "",
             f"{'canal':<12}{'mínimo':>10}{'lineal':>10}{'máximo':>10}{'banda':>10}"]
    for channel, (low, point, high) in sorted(data.items(), key=lambda item: -item[1][1]):
        lines.append(f"{channel:<12}{low:>9.2f}M{point:>9.2f}M{high:>9.2f}M"
                     f"{high / low:>9.1f}×")
    return "\n".join(lines)


def as_matplotlib(data: dict[str, tuple[float, float, float]] = AUREA_CAC,
                  target: Path = Path("tablero.png")) -> Path:
    """Figura estática para un informe que se imprime o se pega en un correo.

    Se elige el backend `Agg` **explícitamente**: sin eso, matplotlib intenta abrir una
    ventana y en un servidor sin pantalla el proceso se cuelga o falla con un error que no
    dice nada. Es el primer tropiezo de cualquiera que ponga un gráfico en producción.
    """
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    channels = sorted(data, key=lambda channel: -data[channel][1])
    points = [data[channel][1] for channel in channels]
    # Las barras de error van como distancias al punto, no como límites absolutos. Es el
    # error más común de la API y produce una banda espejada que parece correcta.
    lower = [data[channel][1] - data[channel][0] for channel in channels]
    upper = [data[channel][2] - data[channel][1] for channel in channels]

    figure, axes = plt.subplots(figsize=(7, 3.5), dpi=150)
    axes.barh(channels, points, color=BRAND["dorado"], height=0.55,
              xerr=[lower, upper], ecolor=BRAND["carbon"], capsize=6)
    axes.set_xlabel("millones de COP por paciente adquirido")
    axes.set_title(TITLE, color=BRAND["carbon"], fontsize=11)
    # El subtítulo es parte del dato: sin él, la banda no se sabe qué es.
    figure.text(0.5, 0.01, SUBTITLE, ha="center", fontsize=8, color=BRAND["pizarra"])
    axes.spines[["top", "right"]].set_visible(False)
    figure.tight_layout(rect=(0, 0.05, 1, 1))
    figure.savefig(target)
    plt.close(figure)
    return target


def as_plotly(data: dict[str, tuple[float, float, float]] = AUREA_CAC,
              target: Path = Path("tablero.html")) -> Path:
    """Tablero interactivo: se pasa el ratón y se ve el valor exacto.

    Sirve para explorar, y por eso se escribe con `include_plotlyjs="cdn"`: el archivo baja
    de megas a kilobytes y a cambio **deja de funcionar sin internet**. Esa es la decisión, y
    la sección 6 la mide en las dos direcciones.
    """
    import plotly.graph_objects as go

    channels = sorted(data, key=lambda channel: -data[channel][1])
    figure = go.Figure(go.Bar(
        x=[data[channel][1] for channel in channels], y=channels, orientation="h",
        marker_color=BRAND["dorado"],
        error_x={"type": "data", "symmetric": False,
                 "array": [data[channel][2] - data[channel][1] for channel in channels],
                 "arrayminus": [data[channel][1] - data[channel][0] for channel in channels],
                 "color": BRAND["carbon"]},
        hovertemplate="%{y}: %{x:.2f}M<extra></extra>"))
    figure.update_layout(title=f"{TITLE}<br><sub>{SUBTITLE}</sub>",
                         xaxis_title="millones de COP", template="simple_white",
                         height=380, margin={"l": 90, "r": 30, "t": 80, "b": 50})
    figure.write_html(target, include_plotlyjs="cdn")
    return target


def as_altair(data: dict[str, tuple[float, float, float]] = AUREA_CAC,
              target: Path = Path("tablero-altair.html")) -> Path:
    """El mismo tablero en gramática de gráficos: se describe el mapeo, no el dibujo.

    Altair no dibuja: produce una especificación de Vega-Lite que otro programa dibuja. Eso
    lo vuelve el más fácil de versionar y revisar —la especificación es un JSON legible— y
    el que peor se lleva con un requisito de diseño muy específico.
    """
    import altair as alt

    rows = [{"canal": channel, "lineal": point, "minimo": low, "maximo": high}
            for channel, (low, point, high) in data.items()]
    base = alt.Chart(alt.Data(values=rows)).encode(
        y=alt.Y("canal:N", sort="-x", title=None))
    bars = base.mark_bar(color=BRAND["dorado"], height=18).encode(
        x=alt.X("lineal:Q", title="millones de COP por paciente adquirido"))
    band = base.mark_rule(color=BRAND["carbon"], strokeWidth=2).encode(
        x="minimo:Q", x2="maximo:Q")
    chart = (bars + band).properties(title={"text": TITLE, "subtitle": SUBTITLE},
                                     width=520, height=140)
    chart.save(target)
    return target


RENDERERS = {
    "tabla": as_table,
    "matplotlib": as_matplotlib,
    "plotly": as_plotly,
    "altair": as_altair,
}


if __name__ == "__main__":
    print(as_table())
