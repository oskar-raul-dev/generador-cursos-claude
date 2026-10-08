# `ds09` · Servir el modelo, y el ⚖️ veredicto del track

Código de la sección [`ds09-servir-el-modelo.md`](../../ds09-servir-el-modelo.md).

| Archivo | Qué es |
|---|---|
| `upstream.py` | Lo que se toma de `ds07` y `ds08`. Ver la nota de nombres, abajo |
| `export.py` | Entrena y exporta a `pickle` y a ONNX, **comprobando que coinciden** |
| `serve.py` | El endpoint `/riesgo` de AgendaAPI, con los dos backends |
| `pickle_danger.py` | 🧨 Diez líneas que demuestran que cargar un `.pkl` ejecuta código |
| `bench_serving.py` | La medición de la sección 6, **sobre HTTP contra un uvicorn real** |
| `test_servir.py` | 10 pruebas: `pytest -q` |

## Correr las cosas

```bash
python ../ds07-scikit-learn/generar_ausentismo.py --salida data
uv run --with scikit-learn==1.9.1 --with skl2onnx==1.20.0 --with onnxruntime==1.30.0 \
       python export.py --datos data --salida modelos
uv run --with fastapi==0.141.1 --with uvicorn==0.52.4 --with scikit-learn==1.9.1 \
       --with onnxruntime==1.30.0 python bench_serving.py --modelos modelos
python pickle_danger.py
```

## El resultado, en una tabla

| Backend | Arranque en frío | p50 | p95 | Artefacto |
|---|---|---|---|---|
| `pickle` + scikit-learn | 1,10 s | 0,90 ms | 1,22 ms | 1,2 KB |
| **ONNX** + onnxruntime | **0,38 s** | **0,71 ms** | **0,99 ms** | **0,5 KB** |

**La latencia no es el argumento** —0,23 ms de diferencia es irrelevante al lado de la red—.
Los argumentos son el arranque (2,9×), la imagen sin scikit-learn, y que **un grafo ONNX no
puede ejecutar código**.

## ⚠️ El exportador se niega a publicar si los formatos no coinciden

```python
if worst > TOLERANCE:
    raise SystemExit(f"El ONNX no coincide con el original: {worst:.2e} > {TOLERANCE:.0e}")
```

La tolerancia es `1e-6` porque ONNX calcula en `float32` y scikit-learn en `float64`. Sobre los
datos de Áurea la diferencia real es **9,44 × 10⁻⁸**. Un modelo exportado que predice distinto
del original es el peor error posible de esta sección: nada falla, y la diferencia aparece en
producción.

## 🧨 `pickle` ejecuta código al cargar

`pickle_danger.py` lo demuestra con un `__reduce__` propio y un efecto inofensivo. Hay una
prueba que **afirma que la vulnerabilidad existe**, porque el día que `pickle` deje de
comportarse así habría que reescribir media sección.

Y la comprobación que más convence, mirando los bytes:

```python
assert b"sklearn" in pickle_bytes      # el .pkl dice qué módulos va a importar
assert b"sklearn" not in onnx_bytes    # el .onnx no menciona ninguno
```

## Sobre el nombre `upstream.py`

Se llamaba `shared.py` y hubo que renombrarlo: `ds08` ya tiene un módulo con ese nombre, el
directorio del script va primero en `sys.path`, y el de aquí tapaba al de allá con un
`ImportError: cannot import name 'HONEST' from 'shared'` que no menciona al archivo culpable.

Es el costo real del atajo de `sys.path` —**el espacio de nombres pasa a ser plano entre las
tres carpetas**— y conviene verlo una vez para saber por qué los proyectos de verdad usan
paquetes.

Los archivos generados no se versionan.
