# `ds06` · Cuadernos y reproducibilidad

Código de la sección [`ds06-notebooks-y-reproducibilidad.md`](../../ds06-notebooks-y-reproducibilidad.md).

| Archivo | Qué es |
|---|---|
| `generar_cuadernos.py` | Los seis cuadernos del Embudo, cinco con su defecto sembrado |
| `check_reproducibility.py` | La medición: ejecutar cada uno en un kernel nuevo, dos veces |
| `cuaderno_marimo.py` | El mismo análisis en marimo. **Es un `.py`**, y eso es media tesis |
| `test_cuadernos.py` | 15 pruebas: `pytest -q` |

## Correr las cosas

```bash
python generar_cuadernos.py --salida cuadernos
uv run --with papermill==2.7.0 --with jupyterlab==4.6.3 \
       python check_reproducibility.py --cuadernos cuadernos --json resultado.json
uv run --with marimo==0.24.2 python cuaderno_marimo.py
```

La auditoría completa —ocho ejecuciones sobre seis cuadernos— tarda **siete segundos**.

## El kernel lo instala `ipykernel`, no papermill

Con papermill y nada más, esto falla con `NoSuchKernel: No such kernel named python3` y
quince líneas de traceback de `jupyter_client` que no dicen qué falta. Lo que registra el
kernel es `ipykernel`, que deja su especificación en `sys.prefix/share/jupyter/kernels/` al
instalarse. `require_kernel()` comprueba eso al arrancar y dice qué agregar.

## Qué mide, y por qué son dos columnas

Cada cuaderno se ejecuta **en un kernel nuevo, desde un directorio temporal vacío y de arriba
abajo**. Las tres condiciones son las que no se cumplen cuando alguien "lo corre otra vez" en
su propia máquina.

Y los que corren se ejecutan **dos veces**, porque **correr no es ser reproducible**:
`azar-sin-semilla.ipynb` pasa la primera prueba y falla la que importa. Es el defecto más
difícil de ver porque no produce ningún error.

**Resultado: 2 de 6 corren, 1 de 6 es estable** — y ese uno es el cuaderno de control, escrito
correcto a propósito.

## marimo resuelve uno de los cinco defectos

En `cuaderno_marimo.py`, la celda que usa `adquiridos` está **antes** que la que lo define, y
corre igual: el orden lo decide el grafo de dependencias. En Jupyter eso mismo es el bug de
`estado-oculto.ipynb`.

Lo que marimo **no** resuelve, y conviene decirlo en la misma frase: la ruta absoluta, la
dependencia no declarada y el azar sin semilla rompen igual.

Los cuadernos generados no se versionan.
