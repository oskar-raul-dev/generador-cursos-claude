"""La paleta de Áurea, y la comprobación de que se puede leer.

    from palette import BRAND, contrast_ratio, check_palette

Marcela va a rechazar un tablero por el color de una barra, y **no le falta razón**: la
marca es de la empresa y el informe lleva su nombre. Lo que esta sección agrega es que la
legibilidad no es una opinión: se mide, y el umbral está escrito desde hace años en las
pautas de accesibilidad —4,5:1 para texto normal, 3:1 para texto grande y elementos de
interfaz—.

🧭 **Un color de marca que no pasa el contraste no se discute con el diseñador: se usa como
relleno y no como texto.** Es la única forma de tener las dos cosas, y evita la
conversación circular de *"pero ese es nuestro dorado"*.
"""

from __future__ import annotations

from itertools import pairwise

# La paleta de Áurea. El dorado es la marca —la proporción áurea es el principio técnico
# del diseño de sonrisa— y los otros cuatro se eligieron para que **también funcionen en
# escala de grises**, porque el comité de franquicia imprime en blanco y negro.
BRAND = {
    "dorado": "#B8860B",
    "carbon": "#2B2B2B",
    "arena": "#E8DCC4",
    "teja": "#A34E2A",
    "pizarra": "#4A6670",
}

BACKGROUND = "#FFFFFF"

# Los dos umbrales de la pauta de accesibilidad, en proporción de contraste.
TEXT_MINIMUM = 4.5
LARGE_TEXT_MINIMUM = 3.0


def _channel(value: int) -> float:
    """Linealiza un canal de color de 0-255 a la escala en que se percibe."""
    fraction = value / 255
    return fraction / 12.92 if fraction <= 0.04045 else ((fraction + 0.055) / 1.055) ** 2.4


def relative_luminance(color: str) -> float:
    """Luminancia relativa de un color `#RRGGBB`, entre 0 (negro) y 1 (blanco).

    Los coeficientes 0,2126 / 0,7152 / 0,0722 no son arbitrarios: el ojo humano es mucho
    más sensible al verde que al azul, y por eso un azul oscuro y un verde oscuro con el
    mismo valor de gris se leen distinto.
    """
    red, green, blue = (int(color[index:index + 2], 16) for index in (1, 3, 5))
    return 0.2126 * _channel(red) + 0.7152 * _channel(green) + 0.0722 * _channel(blue)


def contrast_ratio(foreground: str, background: str = BACKGROUND) -> float:
    """Proporción de contraste entre dos colores. De 1 (idénticos) a 21 (negro sobre blanco)."""
    lighter, darker = sorted((relative_luminance(foreground),
                              relative_luminance(background)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


def check_palette(background: str = BACKGROUND) -> dict[str, tuple[float, bool, bool]]:
    """Cada color de la marca con su contraste y sus dos veredictos.

    Devuelve, por color: la proporción, si sirve para texto normal y si sirve para texto
    grande o para una barra. **Ningún color se descarta**: lo que se decide es para qué
    sirve cada uno, que es la conversación útil con quien defiende la marca.
    """
    return {name: (ratio, ratio >= TEXT_MINIMUM, ratio >= LARGE_TEXT_MINIMUM)
            for name, color in BRAND.items()
            for ratio in (contrast_ratio(color, background),)}


def readable_colors(background: str = BACKGROUND) -> list[str]:
    """Los colores de la marca que sirven para texto, en orden de contraste."""
    return [BRAND[name] for name, (_, text, _) in
            sorted(check_palette(background).items(),
                   key=lambda item: -item[1][0]) if text]


def to_grayscale(color: str) -> str:
    """El mismo color en gris, por luminancia. Para ver qué queda al imprimir."""
    level = round(relative_luminance(color) ** (1 / 2.2) * 255)
    return f"#{level:02X}{level:02X}{level:02X}"


def distinguishable_in_print(colors: list[str], minimum: float = 1.4) -> bool:
    """Si los colores siguen distinguiéndose entre sí en escala de grises.

    El comité de franquicia imprime. Una serie de cinco colores vivos que en gris quedan
    todos en el mismo tono produce un gráfico que solo funciona en la pantalla de quien lo
    hizo — y eso se descubre en la reunión, no antes.
    """
    # `pairwise` y no `zip(grays, grays[1:], strict=True)`: la segunda lista es más corta
    # por construcción, así que el `strict=True` que el curso predica **revienta aquí**. Es
    # el reverso del consejo de `ds01`: `strict` es para secuencias que deben tener el mismo
    # largo, y un recorrido por pares nunca lo es.
    grays = sorted(relative_luminance(to_grayscale(color)) for color in colors)
    return all((later + 0.05) / (earlier + 0.05) >= minimum
               for earlier, later in pairwise(grays))
