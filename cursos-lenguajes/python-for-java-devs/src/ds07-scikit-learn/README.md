# `ds07` · scikit-learn y la línea base honesta

Código de la sección [`ds07-scikit-learn.md`](../../ds07-scikit-learn.md).

| Archivo | Qué es |
|---|---|
| `generar_ausentismo.py` | El histórico de citas, su clima y sus pacientes seudonimizados |
| `features.py` | Las cinco variables honestas, la columna con fuga y el corte temporal |
| `baseline.py` | Las dos líneas base y las métricas, **sin scikit-learn** |
| `model.py` | La regresión logística en un `Pipeline`, con el escalado dentro |
| `bench_baseline.py` | La medición de la sección 6: cuatro tablas |
| `test_generar_ausentismo.py` · `test_ausentismo.py` | 38 pruebas: `pytest -q` |

## Correr las cosas

```bash
python generar_ausentismo.py --salida data          # ~105.600 citas · 1 segundo
uv run --with scikit-learn==1.9.1 python bench_baseline.py --datos data   # ~10 s
uv run --with scikit-learn==1.9.1 --with pytest pytest -q
```

## `baseline.py` no importa scikit-learn, y es una frontera de diseño

La línea base no puede depender de la biblioteca contra la que compite. Si lo hiciera, la
cuarta tabla de la sección 6 —la del costo de mantener— sería mentira: estaría comparando dos
cosas que pagan el mismo arranque de 857 ms.

Por eso el AUC y la precisión/recall están escritos a mano en `baseline.py`, y hay una prueba
que los compara con los tres casos que los definen (separación perfecta, azar y orden
invertido). El ejercicio 11 pide contrastarlos con `sklearn.metrics`.

## Los datos

**105.620 citas de 12.400 pacientes**, 2024-01-01 a 2026-03-31, 19,3% de inasistencia. El
corte temporal —**2025-10-01**— sale del `manifiesto.json` del conjunto y no de una constante
en el código: así `ds07`, `ds08` y `ds09` parten por la misma fecha y sus números se pueden
poner en la misma tabla.

## ⚠️ La columna con fuga está ahí a propósito

`inasistencias_totales_paciente` es el total del histórico del paciente, **futuro incluido**.
Sale de un `GROUP BY` que cualquiera escribe sin pensar, no falla, no avisa, y **regala 0,063
de AUC**: 0,799 → 0,862.

Vive en `features.LEAKY`, separada de `features.HONEST`, y solo entra en el experimento de la
sección 5.4. La regla que la mantiene fuera: **una variable entra si estaba disponible antes de
la cita**.

## Lo que fijan las pruebas

1. **El AUC está bien implementado**, contra los tres casos que lo definen, y **promedia los
   empates** — sin eso, la regla de tres variables saldría mejor o peor según cómo estuviera
   ordenado el CSV.
2. **La logística le gana a la regla** por más de 0,05 de AUC. Es la tesis de la sección
   convertida en aserción: si deja de ser cierta, el capítulo se reescribe.
3. **La regla no alcanza la capacidad del 20%**: con cuatro puntajes distintos marca el 29%,
   porque el umbral cae dentro de un bloque de empates. Es una limitación operativa que
   ninguna métrica de discriminación muestra.
4. **El escalado vive dentro del `Pipeline`**, que es lo que impide que el entrenamiento vea el
   tramo de prueba a través de la media y la desviación.

Los archivos generados no se versionan.
