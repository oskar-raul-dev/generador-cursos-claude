# `ia02` · Salida estructurada y el contrato del modelo

Código de la sección [`ia02-salida-estructurada.md`](../../ia02-salida-estructurada.md).

| Archivo | Qué es |
|---|---|
| `coverage.py` | El contrato: `CoverageRule` y `CircularExtraction`. El archivo que hay que leer despacio |
| `extract.py` | La extracción, con el bucle que le devuelve al modelo su propio error de validación |
| `bench_extraction.py` | La medición de la sección 6: tres estrategias, mismo corpus |
| `test_coverage.py` | Pruebas del contrato. **No tocan la red**: `pytest test_coverage.py` |

## Dependencias entre secciones

`extract.py` habla con la API a través del cliente de `ia01`. En tu repositorio los dos viven en
el mismo paquete; aquí están separados por sección para que se puedan leer con su lección al lado.
Si copias los archivos sueltos, `llm.py` y `pricing.py` de `src/ia01-…/` tienen que estar
importables.

## Los datos

```bash
python generar_circulares.py     # -> circulares/*.txt (100) y reglas_esperadas.json (197 reglas)
```

Las reglas esperadas **se derivan del texto que se escribió**, no se anotan aparte: por
construcción el corpus y su anotación no pueden discrepar, que es el error más caro de un
conjunto anotado a mano. Una de cada cinco circulares es ambigua a propósito —habla de copago sin
decir nada de cobertura—, y de ahí sale el 22% de reglas que exigen `no_dice`: sin esos casos, el
contrato de tres estados parecería ceremonia.

Las circulares traen **comillas tipográficas**, como las trae un PDF real. Es deliberado: ejercita
el camino de `_normalize` en vez de evitarlo. Las 197 citas esperadas se verifican contra el texto
generado y las 197 pasan.

## Una nota sobre `test_coverage.py`

La prueba `test_normalize_survives_typographic_quotes_and_hard_spaces` existe porque la primera
versión de `_normalize` **fallaba**: la normalización Unicode NFC no pliega las comillas
tipográficas, así que una cita correcta copiada de un PDF no coincidía con la que devolvía el
modelo. La prueba se quedó como está para que el bug no vuelva.
