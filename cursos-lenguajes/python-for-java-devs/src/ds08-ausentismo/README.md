# `ds08` · Proyecto · Ausentismo

Código de la sección [`ds08-ausentismo.md`](../../ds08-ausentismo.md).

| Archivo | Qué es |
|---|---|
| `shared.py` | La línea base de `ds07`, importada en vez de copiada. **La única excepción del track** |
| `net.py` | La red neuronal en PyTorch, CPU, determinista y con parada temprana |
| `engineered.py` | La columna que iguala a la red: `lluvia × distancia` |
| `calibration.py` | Brier, ECE y la tabla de fiabilidad. **Sin torch ni sklearn** |
| `overbooking.py` | De la probabilidad a la decisión, con la asimetría de costos |
| `bench_net.py` | La medición de la sección 6: cinco tablas |
| `test_red.py` | 14 pruebas: `pytest -q` |

## Correr las cosas

```bash
python ../ds07-scikit-learn/generar_ausentismo.py --salida data
uv run --with torch==2.14.0 --with scikit-learn==1.9.1 python bench_net.py --datos data
```

Unos 23 segundos, de los cuales 2 son entrenar la red.

## ⚠️ PyTorch solo, en macOS, no arranca

```
OMP: Error #15: Initializing libomp.dylib, but found libomp.dylib already initialized.
```

En un entorno con **solo torch** esto aborta el proceso. Con scikit-learn al lado, funciona:
más de una biblioteca trae su copia del runtime de OpenMP y el enlazador encuentra dos. El
mensaje sugiere `KMP_DUPLICATE_LIB_OK=TRUE` y él mismo lo llama *unsafe, unsupported,
undocumented* — sirve para salir del paso, no para producción.

Por eso todos los comandos de esta carpeta traen las dos dependencias.

## `shared.py` es la única vez que una sección importa de otra

La regla del track es que cada carpeta de `src/` corre sola. Aquí se rompe, con motivo: la
comparación con `ds07` **solo vale si las dos usan exactamente las mismas variables**, el
mismo tope de historial y el mismo corte temporal. Copiar `features.py` habría garantizado que
algún día las dos definiciones divergieran sin que nadie se entere, y ese día la tabla de la
sección 6 dejaría de significar algo **sin dar ningún error**.

## Los tres resultados que este código sostiene

1. **La red gana, y la diferencia es real**: 0,8118 contra 0,7993 de AUC, con intervalo
   bootstrap [+0,0109, +0,0141] que no toca el cero.
2. **Una columna a mano la iguala.** `lluvia × distancia` lleva la logística a 0,8118 con un
   intervalo indistinguible. El generador tiene **una** interacción; la red la encuentra y
   escribirla cuesta una línea.
3. **Un puntaje que ordena bien puede decidir catastróficamente.** La regla de `ds07` tiene
   ECE de 0,1918: aplicada al sobreagendamiento pierde **6.336 consultas** contra no hacer
   nada, mientras los modelos calibrados recuperan unas 3.000.

## Lo que no depende de torch

`calibration.py` y `overbooking.py` son aritmética pura y tienen sus pruebas. Es deliberado:
**son los módulos que deciden plata**, y tienen que poder revisarse y correrse sin instalar
cientos de megas.

Los archivos generados no se versionan.
