# `ds02` · pandas y el modelo de DataFrame

Código de la sección [`ds02-pandas.md`](../../ds02-pandas.md).

| Archivo | Qué es |
|---|---|
| `collections_report.py` | El informe de cobranza, en **tres órdenes de unir y agregar** que dan la misma tabla |
| `bench_merge.py` | La medición de la sección 6, con su línea base de memoria |
| `test_collections_report.py` | 10 pruebas: `pytest test_collections_report.py` |

## Los datos

Son los del Embudo, y los genera `ds01`:

```bash
python ../ds01-numpy-y-el-modelo-vectorizado/generar_embudo.py --salida data
```

El informe usa dos de los ocho archivos: `planes_de_tratamiento.csv` (6.065 filas) y `cuotas.csv`
(81.274). Son el tamaño **real** de Áurea, sin repetir bloque: esta es la única medición del track
que no necesita inflar nada para tener algo que medir.

## Correr las cosas

```bash
uv run --with pandas==3.0.5 python bench_merge.py --datos data
uv run --with pandas==3.0.5 --with pytest pytest -q
```

## Por qué la medición lanza tres procesos

`tracemalloc` —el arnés de la Fase 02— solo ve lo que asigna el asignador de Python, y pandas
guarda buena parte de sus datos fuera de él. Medir memoria con `tracemalloc` aquí daría un número
bonito y falso, así que se reporta el **pico de RSS del proceso**, que es lo que ve el sistema
operativo.

Eso obliga a un proceso por variante: `ru_maxrss` es una marca de agua alta y nunca baja, de modo
que dentro de un solo proceso la segunda variante mediría el pico de la primera. Y obliga a la
fila «solo importar», que es la línea base: **76,9 MB los gasta pandas por existir**, y publicar la
columna de memoria sin descontarlos es contar el intérprete dos veces.

El arnés no se reemplaza, se amplía: el tiempo lo sigue dando `measure`.

## Las tres cosas que las pruebas fijan

1. **Las tres versiones dan la misma tabla.** Sin eso, la tabla de tiempos compara tres programas
   distintos y no significa nada.
2. **`validate=` atrapa la unión muchos-a-muchos.** Unir `etapas` con `toques` por `lead_id` pasa
   de 64.062 filas a 133.288 sin que nadie avise; con `validate="1:1"` es una `MergeError`.
3. **Copy-on-Write hace lo que pandas 3.0 promete.** Filtrar y asignar no toca el original, y la
   asignación encadenada avisa y no hace nada. Está en una prueba porque medio internet todavía
   explica lo contrario.

Los archivos generados no se versionan.
