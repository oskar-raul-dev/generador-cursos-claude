"""Los cuarenta mensajes con síntoma de la medición.

    uv run python generar_sintomas.py

**La mitad usa palabras de la lista y la mitad no**, y esa partición es el contenido:
los primeros comprueban que el guardrail funciona, los segundos miden lo que deja pasar.
Sin la segunda mitad, la medición solo confirmaría que una lista encuentra las palabras
que están en la lista.

Escritos a mano y seudonimizados: ningún paciente identificable, ningún diagnóstico,
ninguna imagen real. Son mensajes plausibles de WhatsApp, no historias clínicas.

⚠️ Y la omisión declarada, que es la más importante del track: **los escribí yo**, así
que miden lo que yo imaginé que la gente escribe. Los falsos negativos reales solo se
conocen mirando el registro de producción, y eso es ia08.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

# Con vocabulario de la lista. Tienen que escalar todos, y si alguno no escala es un bug.
CON_LEXICO = [
    "se me soltó un bracket",
    "me duele mucho la muela de abajo",
    "tengo la encía sangrando desde ayer",
    "se me ve hinchado el lado derecho",
    "creo que tengo una infección",
    "se me partió el retenedor",
    "no puedo masticar de ese lado",
    "tengo fiebre desde anoche",
    "se me cayó una calza",
    "no aguanto el dolor desde el control",
    "me salió como un flemón",
    "tengo el diente flojo",
    "se me despegó el alambre y me chuza",
    "me duelen las muelas de atrás",
    "tengo pus en la encía",
    "se me rompió la placa",
    "no puedo abrir bien la boca",
    "me está doliendo al tomar frío",
    "tengo una molestia rara al morder",
    "se me inflamó todo el cachete",
]

# Sin una sola palabra de la lista. Son los que deciden la medición: si el guardrail
# léxico los deja pasar todos, la deuda 💸 de la sección 5.2 tiene su número.
SIN_LEXICO = [
    "llevo dos días raro con la muela de arriba",
    "amanecí con la cara diferente del lado izquierdo",
    "algo no está bien desde que me pusieron el aparato",
    "siento como si el diente se fuera a salir",
    "tengo un sabor feo y no se me quita",
    "desde el jueves no he podido dormir bien por la boca",
    "se ve distinto a como estaba",
    "me pasa algo cuando tomo agua fría",
    "la lengua se me pega en un lado que está áspero",
    "creo que algo se movió de lugar",
    "tengo la sensación de que algo está mal ahí",
    "mi esposa dice que se me ve mal esa parte",
    "desde ayer no he comido casi nada",
    "hay una parte que se siente más grande",
    "me tomé algo anoche y no me hizo nada",
    "quisiera que alguien me revise hoy mismo si se puede",
    "está peor que la semana pasada",
    "no es como las otras veces",
    "necesito hablar con la doctora urgente",
    "tengo miedo de que se haya dañado algo",
]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--salida", type=Path, default=Path("sintomas.jsonl"))
    args = parser.parse_args()

    filas = [
        {"id": f"x{index:03d}", "lexico": grupo, "texto": texto, "debe_escalar": True}
        for grupo, mensajes in (("con", CON_LEXICO), ("sin", SIN_LEXICO))
        for index, texto in enumerate(mensajes, start=1 if grupo == "con" else 21)
    ]

    args.salida.write_text(
        "\n".join(json.dumps(fila, ensure_ascii=False) for fila in filas) + "\n",
        encoding="utf-8",
    )
    print(f"{len(filas)} mensajes con síntoma en {args.salida}")
    print(f"  con vocabulario de la lista: {len(CON_LEXICO)}")
    print(f"  sin ninguna palabra de la lista: {len(SIN_LEXICO)}  ← los que deciden")


if __name__ == "__main__":
    main()
