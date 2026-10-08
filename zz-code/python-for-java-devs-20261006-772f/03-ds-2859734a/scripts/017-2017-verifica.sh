# rescatado de la sesión 2859734a, 2026-09-13T20:17:45Z · Check int32 overflow semantics precisely
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python -W error::RuntimeWarning - <<'PY'
import numpy as np, warnings
a = np.array([2_000_000_000, 2_000_000_000], dtype=np.int32)
print("sum() por defecto:", a.sum(), a.sum().dtype)
print("sum(dtype=int32):", a.sum(dtype=np.int32))
with warnings.catch_warnings(record=True) as w:
    warnings.simplefilter("always")
    b = a + a
    print("a+a:", b, b.dtype, "· avisos:", [str(x.message) for x in w])
PY
