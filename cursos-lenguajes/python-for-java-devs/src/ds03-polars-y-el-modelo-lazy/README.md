# `ds03` · Polars, DuckDB y el modelo lazy

Código de la sección [`ds03-polars-y-el-modelo-lazy.md`](../../ds03-polars-y-el-modelo-lazy.md).

| Archivo | Qué es |
|---|---|
| `consolidation.py` | El consolidado mensual en **cinco motores** que devuelven lo mismo |
| `preparar_tamanos.py` | Los seis tamaños de la medición, y su copia en Parquet |
| `bench_engines.py` | Tabla 6.1: la consulta con el motor ya cargado |
| `bench_punta_a_punta.py` | Tabla 6.2: proceso, import, consulta y salida |
| `test_consolidation.py` | 11 pruebas: `pytest test_consolidation.py` |

## El orden de las cosas

```bash
uv run --with duckdb==1.5.5 python preparar_tamanos.py --salida data
uv run --with pandas==3.0.5 --with polars==1.44.2 --with duckdb==1.5.5 \
       python bench_engines.py --datos data
```

`preparar_tamanos.py` tarda unos veinticinco segundos y deja unos 280 MB en `data/`. Los seis
tamaños salen de un solo conjunto: cuatro son recortes reales de Áurea —un mes, un trimestre,
un año y la historia completa— y dos son el generador a escala 4 y 16, **declarados
sintéticos** en el propio script.

## Por qué hay dos mediciones y no una

`bench_engines.py` mide **la consulta** con el motor ya importado. Es lo correcto para
comparar motores entre sí, y es lo que publica casi todo el mundo.

`bench_punta_a_punta.py` mide **el informe**: lanzar el proceso, importar la dependencia,
consultar y salir. Es lo que espera Marcela una vez al mes, y da otro ganador.

Las dos son correctas. Publicar solo la primera sería el error que la Fase 17 del camino base
cometió y documentó.

## ⚠️ La medición de DuckDB depende de qué más tengas instalado

```bash
uv run --with duckdb==1.5.5 python bench_punta_a_punta.py --motor 'duckdb (parquet)'
#   97 ms
uv run --with duckdb==1.5.5 --with pandas==3.0.5 python bench_punta_a_punta.py --motor 'duckdb (parquet)'
#  433 ms
```

El mismo código, los mismos datos, **4,5× más lento por una dependencia que no se usa**:
DuckDB importa pandas durante la consulta, cuando su mecanismo de sustitución de nombres va a
ver si algún nombre referenciado es un objeto de pandas o de Arrow.

Por eso la tabla 6.2 se toma con **`--motor`, un entorno por motor**. Medirlos a los cuatro en
el mismo entorno le cobra a DuckDB el arranque de pandas.

## Lo que fijan las pruebas

1. **Los cinco motores devuelven la misma lista de tuplas.** Es la prueba que hace legítima
   toda la sección 6.
2. **El mismo SQL sobre CSV y sobre Parquet da lo mismo**, que es lo que permite atribuirle la
   diferencia al formato y no a la consulta.
3. **La cuota se cuenta en el mes en que se pagó**, no en el que se programó — con la
   comprobación de que los dos números son distintos, porque si fueran iguales la distinción
   sería decorativa.
4. **El recorte por meses es coherente**: ninguna cuota queda sin su plan, o el `join` mediría
   un error de preparación en vez de un motor.

Los archivos generados no se versionan.
