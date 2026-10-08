# `ia06` · Evaluación, regresiones y el juez que también se equivoca

Código de la sección [`ia06-evaluacion.md`](../../ia06-evaluacion.md).

| Archivo | Qué es |
|---|---|
| `evalset.py` | El conjunto como activo: huella, partición desarrollo/retención, casos de abstención |
| `judge.py` | El juez con su rúbrica escrita. La rúbrica vive en el repositorio, no en la cabeza de nadie |
| `statistics_helpers.py` | Acuerdo, kappa, intervalo de Wilson y tamaño de muestra. Cuatro funciones puras |
| `calibrate.py` | La deuda 💸 de `ia04` pagada: el umbral sale de los datos |
| `provider.py` | La deuda 💸 de `ia01` pagada: el `Protocol` de proveedor, API y Ollama |
| `run_eval.py` | El arnés completo y su informe |
| `bench_judges.py` | La medición de la sección 6: cuatro formas de calificar |
| `test_statistics.py` · `test_calibrate.py` | **19 pruebas sin red, sin modelo y sin Postgres** |

## Correr las pruebas

```bash
pytest test_statistics.py test_calibrate.py -q      # 19 pruebas, milisegundos, sin gastar un peso
```

El número que decide un despliegue tiene que ser el mejor probado del sistema; por eso las cuatro
funciones de estadística son puras y tienen prueba propia. La que más vale es
`test_lazy_judge_has_high_agreement_and_zero_kappa`: acuerdo 0.90, kappa 0.00. Es la trampa de la
sección convertida en aserción.

## Los números que la aritmética ya te da

```bash
python -c "from statistics_helpers import required_sample_size as n; print(n(0.80, 0.05), n(0.80, 0.10))"
# 444 98
```

Partiendo de una calidad del 80%: detectar **diez puntos** necesita ~98 casos; detectar **cinco**,
~444. Con un conjunto de cincuenta, casi todo es *indistinguible*, y eso hay que decirlo antes de
prometer que "medimos la calidad".

## Los datos

```bash
python generar_evalset.py --manifiesto ../ia04-embeddings-y-busqueda-semantica/corpus/manifiesto.json
# -> evalset.jsonl: 50 casos (33 desarrollo / 17 retención), 15 de abstención
```

Las respuestas de referencia **se derivan del manifiesto del corpus** —del hecho que generó el
documento—, no las escribe un modelo: una referencia generada por otro modelo convierte la
evaluación en un espejo.

Los quince casos de abstención van en dos sabores, y son fallos distintos: aseguradora que no
existe (no recupera nada) y **código que no existe en una aseguradora que sí** — este segundo
recupera fragmentos plausibles y es mucho más fácil de contestar mal.

### El único insumo que un script no puede producir

```bash
python preparar_juicios.py --informe informe.json    # -> juicios_humanos.jsonl, con el campo vacío
```

Sale con `veredicto_humano` en blanco y **`bench_judges.py` se niega a correr** si encuentra alguno
sin llenar. Fabricarlos con un modelo daría un kappa alto y completamente vacío: estarías midiendo
cuánto se parece un modelo a otro. Son veinte minutos con la rúbrica de `judge.py` delante, y sin
haber visto el fallo del juez.
