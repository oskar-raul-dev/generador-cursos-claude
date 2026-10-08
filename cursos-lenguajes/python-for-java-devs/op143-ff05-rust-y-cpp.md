# 🦀 ff05 — PyO3, pybind11 y nanobind

> Python para desarrolladores Java senior · **Carta** · Track `ff` — La frontera nativa ·
> sección 5 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

`uv`, `ruff`, `pydantic-core`, `polars` y `orjson` tienen algo en común: son Rust con una capa de Python encima. La generación nueva de herramientas del ecosistema
no se escribe en C ni en Cython, sino en **Rust con PyO3** o en **C++ moderno con pybind11 o nanobind**. Es el lado nativo "de verdad": un lenguaje compilado completo,
con su sistema de tipos y sus bibliotecas, y una capa delgada que lo expone como módulo de Python.

Esta sección escribe el suavizado del track en las tres, con el mismo contrato (recibe un arreglo de NumPy, devuelve otro) y su sistema de construcción
estándar, y mide lo que importa al elegir: velocidad, costo por llamada, tiempo de construcción, tamaño de la rueda y exactitud. La última dio una sorpresa.

---

## 🧠 2. El modelo

| | **PyO3 + maturin** | **pybind11** | **nanobind** |
|---|---|---|---|
| Lenguaje | Rust | C++11 o posterior | C++17 o posterior |
| Construcción | `maturin` (`cargo` por debajo) | CMake + `scikit-build-core` | CMake + `scikit-build-core` |
| Arreglos de NumPy | *Crate* `numpy` | `py::array_t` | `nb::ndarray` (NumPy, PyTorch, JAX…) |
| Lo que lo distingue | Seguridad de memoria del compilador | El más usado, el más documentado | Del autor de pybind11: ruedas más chicas, menos costo |
| Lo usan | `uv`, `ruff`, `pydantic-core`, `polars`, `orjson` | SciPy, PyTorch (partes), muchos científicos | Proyectos nuevos de C++ |

### Tu instinto de Java dice… y esta vez se equivoca

Para quien hizo JNI, código nativo significa archivos de encabezado generados, funciones con nombres de veinte segmentos y referencias locales que se escapan.
El instinto espera lo mismo. Con estas tres, el pegamento es un atributo o una macro (`#[pyfunction]`, `m.def`), y la conversión de tipos la escribe la biblioteca.
Cada archivo del ejemplo tiene unas 20 líneas, con el cálculo incluido.

---

## 💻 3. El ejemplo que corre

**Rust con PyO3.** `rs/Cargo.toml`:

```toml
[package]
name = "ema_rs"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
pyo3 = "0.29.3"
numpy = "0.29.0"
```

`rs/pyproject.toml`:

```toml
[build-system]
requires = ["maturin>=1.15,<2"]
build-backend = "maturin"

[project]
name = "ema-rs"
version = "0.1.0"

[tool.maturin]
module-name = "ema_rs"
```

`rs/src/lib.rs`:

```rust
use numpy::{PyArray1, PyReadonlyArray1};
use pyo3::prelude::*;

/// Suavizado exponencial sobre un arreglo de NumPy.
#[pyfunction]
fn ema<'py>(py: Python<'py>, x: PyReadonlyArray1<'py, f64>, alpha: f64) -> PyResult<Bound<'py, PyArray1<f64>>> {
    let x = x.as_slice()?;
    let mut out = Vec::with_capacity(x.len());
    let mut s = x[0];
    for &v in x {
        s = alpha * v + (1.0 - alpha) * s;
        out.push(s);
    }
    Ok(PyArray1::from_vec(py, out))
}

#[pymodule]
fn ema_rs(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(ema, m)?)
}
```

**C++ con pybind11.** `pb/ema_pb.cpp`:

```cpp
#include <pybind11/numpy.h>
#include <pybind11/pybind11.h>

namespace py = pybind11;

// Suavizado exponencial sobre un arreglo de NumPy.
py::array_t<double> ema(py::array_t<double, py::array::c_style | py::array::forcecast> x, double alpha) {
    auto in = x.unchecked<1>();
    py::ssize_t n = in.shape(0);
    py::array_t<double> out(n);
    auto o = out.mutable_unchecked<1>();
    double s = in(0);
    for (py::ssize_t i = 0; i < n; i++) {
        s = alpha * in(i) + (1 - alpha) * s;
        o(i) = s;
    }
    return out;
}

PYBIND11_MODULE(ema_pb, m) { m.def("ema", &ema); }
```

`pb/pyproject.toml`:

```toml
[build-system]
requires = ["scikit-build-core>=1.1", "pybind11>=3.1"]
build-backend = "scikit_build_core.build"

[project]
name = "ema-pb"
version = "0.1.0"
```

`pb/CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.15...3.31)
project(ema_pb LANGUAGES CXX)
find_package(Python COMPONENTS Interpreter Development.Module REQUIRED)
find_package(pybind11 CONFIG REQUIRED)
pybind11_add_module(ema_pb ema_pb.cpp)
install(TARGETS ema_pb LIBRARY DESTINATION .)
```

**C++ con nanobind.** `nb/ema_nb.cpp`:

```cpp
#include <nanobind/nanobind.h>
#include <nanobind/ndarray.h>

namespace nb = nanobind;
using Out = nb::ndarray<nb::numpy, double, nb::ndim<1>>;

// Suavizado exponencial sobre un arreglo de NumPy.
Out ema(nb::ndarray<const double, nb::ndim<1>, nb::c_contig> x, double alpha) {
    size_t n = x.shape(0);
    const double *in = x.data();
    double *out = new double[n];
    nb::capsule owner(out, [](void *p) noexcept { delete[] static_cast<double *>(p); });
    double s = in[0];
    for (size_t i = 0; i < n; i++) {
        s = alpha * in[i] + (1 - alpha) * s;
        out[i] = s;
    }
    return Out(out, {n}, owner);
}

NB_MODULE(ema_nb, m) { m.def("ema", &ema); }
```

`nb/pyproject.toml`:

```toml
[build-system]
requires = ["scikit-build-core>=1.1", "nanobind>=2.0"]
build-backend = "scikit_build_core.build"

[project]
name = "ema-nb"
version = "0.1.0"
```

`nb/CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.15...3.31)
project(ema_nb LANGUAGES CXX)
find_package(Python COMPONENTS Interpreter Development.Module REQUIRED)
find_package(nanobind CONFIG REQUIRED)
nanobind_add_module(ema_nb ema_nb.cpp)
install(TARGETS ema_nb LIBRARY DESTINATION .)
```

`construir.sh` construye las tres ruedas con `pip wheel` (cada una con su *backend*) y las instala:

```bash
set -euo pipefail
for dir in rs pb nb; do
  start=$(date +%s)
  pip wheel --quiet --no-deps --wheel-dir "dist/$dir" "./$dir" >/dev/null 2>&1 || { echo "$dir: falló la construcción"; continue; }
  wheel=$(ls dist/"$dir"/*.whl)
  printf '%-3s construcción %3s s · rueda %4s KB · %s\n' "$dir" "$(( $(date +%s) - start ))" "$(( $(stat -c %s "$wheel") / 1024 ))" "$(basename "$wheel")"
done
pip install --quiet dist/*/*.whl
```

`medir.py`:

```python
"""La misma función en Rust (PyO3), C++ (pybind11) y C++ (nanobind), llamada desde Python y medida."""

import time

import numpy as np
import ema_nb
import ema_pb
import ema_rs


def ema_python(x, alpha):
    out, s = [], x[0]
    for v in x:
        s = alpha * v + (1 - alpha) * s
        out.append(s)
    return np.array(out)


N, ALPHA = 2_000_000, 0.1
x = np.sin(np.arange(N) / 1000) * 100 + 500
reference = ema_python(x.tolist(), ALPHA)
one = x[:1]
for name, module in (("PyO3", ema_rs), ("pybind11", ema_pb), ("nanobind", ema_nb)):
    times = []
    for _ in range(5):
        start = time.perf_counter(); result = module.ema(x, ALPHA); times.append(time.perf_counter() - start)
    start = time.perf_counter()
    for _ in range(100_000):
        module.ema(one, ALPHA)
    per_call = (time.perf_counter() - start) * 10                         # µs por llamada
    print(f"{name:<9} {min(times) * 1000:4.1f} ms · llamada con un elemento {per_call:4.2f} µs"
          f" · diferencia con Python {np.abs(result - reference).max():.1e}")
```

```bash
apt-get install cargo           # o rustup; el contenedor usó el de Debian: rustc 1.85.1
pip install numpy cmake
bash construir.sh
python3 medir.py
```

Salida (Python 3.14.7, 05/10/2026) (los segundos de construcción incluyen bajar las dependencias; los milisegundos son de la máquina que corre):

```text
rs  construcción  18 s · rueda  292 KB · ema_rs-0.1.0-cp314-cp314-linux_aarch64.whl
pb  construcción   8 s · rueda   65 KB · ema_pb-0.1.0-cp314-cp314-linux_aarch64.whl
nb  construcción   6 s · rueda   51 KB · ema_nb-0.1.0-cp314-cp314-linux_aarch64.whl
PyO3       5.3 ms · llamada con un elemento 0.23 µs · diferencia con Python 0.0e+00
pybind11   5.1 ms · llamada con un elemento 0.31 µs · diferencia con Python 5.7e-13
nanobind   5.1 ms · llamada con un elemento 0.51 µs · diferencia con Python 5.7e-13
```

En velocidad empatan: **5,1 a 5,3 ms**, lo mismo que el C de `ff02` y que numba. El costo por llamada es de **0,23 a 0,51 µs**, del orden del de `ctypes` con una suma
(`ff02`: 0,5 µs), aunque aquí cada llamada recibe y crea un arreglo de NumPy; nanobind, que promete el menor costo, fue el más alto en esta llamada, porque el
resultado se crea con una cápsula que lo libera. Donde se separan es en construir: Rust tardó **18 s** y dejó una rueda de **292 KB**; nanobind, **6 s y 51 KB**.
Y la sorpresa: **Rust da exactamente lo mismo que Python**, y las dos de C++ difieren en 5,7e-13. Es la FMA de `ff02`: gcc fusiona la multiplicación y la suma por
defecto, y Rust nunca lo hace sin que se le pida.

**Detalles con intención**

- **`module-name = "ema_rs"`** en `[tool.maturin]`: sin esa línea, `maturin` deriva el nombre del módulo del nombre del proyecto (`ema-rs`), y falla porque un
  módulo de Python no puede tener un guion.
- **`PyReadonlyArray1`** y `as_slice` le dan a Rust la memoria del arreglo de NumPy sin copiarla; `PyArray1::from_vec` entrega el `Vec` a NumPy sin copiarlo de
  vuelta.
- **`forcecast`** en pybind11 convierte si el arreglo no es `float64`; sin él, un arreglo de enteros se rechaza. Es una copia silenciosa que conviene conocer.
- **La cápsula de nanobind** dice quién libera la memoria del resultado; sin ella, el arreglo de NumPy apuntaría a memoria que nadie libera.
- **Las tres ruedas dicen `cp314-cp314-linux_aarch64`**: una por versión de Python y plataforma, como cualquier extensión (`ff08`).

---

## ⚠️ 4. Lo que se rompe

**El nombre del módulo.** `maturin` y CMake toman el nombre de lugares distintos; si el nombre del módulo en el código (`fn ema_rs`, `PYBIND11_MODULE(ema_pb…)`) no
coincide con el del archivo, el `import` falla con `ImportError: dynamic module does not define module export function`.

**El directorio con el mismo nombre del módulo.** Correr `python` desde una carpeta que tiene un subdirectorio `ema_rs/` importa la carpeta como paquete de espacio de
nombres, no la extensión instalada: `module 'ema_rs' has no attribute 'ema'`. Pasó al probar esta sección; por eso los directorios se llaman `rs`, `pb` y `nb`.

**La cadena de herramientas en el CI.** Rust, CMake y un compilador de C++ en cada máquina que construye, por cada plataforma (`cibuildwheel`, `ff08`).

**El GIL tomado durante el cálculo.** Ninguna de las tres lo suelta sola. PyO3 lo suelta con `py.detach`, pybind11 con `py::gil_scoped_release` y nanobind con
`nb::gil_scoped_release`; sin eso, cuatro hilos no ganan nada.

---

## ⚖️ 5. Cuándo NO usarlos

**Para un bucle numérico que `numba` compila.** Mismo tiempo, sin cadena de herramientas ni ruedas por plataforma (`ff04`).

**Si nadie en el equipo mantiene Rust o C++.** Una extensión que solo entiende quien la escribió es un riesgo; el ahorro de milisegundos no lo paga.

**Para envolver una biblioteca de C simple.** `cffi` (`ff02`) llega antes, con menos maquinaria.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Construye y mide las tres. **Criterio:** la tabla, y por qué Rust coincide exactamente con Python.
2. Compila la de pybind11 con `-ffp-contract=off`. **Criterio:** la diferencia con Python baja a cero.
3. Pásale a las tres un arreglo de enteros. **Criterio:** qué hace cada una (convierte, rechaza) y con qué mensaje.

**🟡 Intermedio (4–6)**

4. Suelta el GIL durante el bucle en las tres y llámalas desde cuatro hilos. **Criterio:** la ganancia con hilos en cada una.
5. Haz que la función de Rust devuelva un error de Python si el arreglo está vacío (`PyValueError`). **Criterio:** `ValueError` en Python, no un *panic*.
6. Agrega *stubs* de tipos (`.pyi`) a las tres. **Criterio:** `mypy` revisa una llamada con el tipo equivocado.

**🟠 Difícil (7–9)**

7. Construye la de Rust con `maturin build --release` y compara con la construcción de `pip wheel`. **Criterio:** los tiempos y si la rueda cambia.
8. Usa `cibuildwheel` para construir la de nanobind para Linux x86 y ARM. **Criterio:** las dos ruedas y el tiempo del CI.
9. Escribe en Rust una función que procese cadenas (por ejemplo, normalizar nombres de sedes). **Criterio:** el tiempo contra Python, y cuánto se va en convertir cadenas.

**🔴 Muy difícil (10)**

10. Decide el lenguaje de una extensión nueva para tu equipo. **Criterio:** una página. *Rúbrica:* (a) las cifras de esta sección; (b) quién la mantiene y qué sabe;
    (c) la cadena de herramientas en el CI; (d) la seguridad de memoria como argumento, con un ejemplo de error que Rust evita.

---

## 📚 7. Referencias

**Documentación oficial**

- PyO3: https://pyo3.rs/
- `maturin`: https://www.maturin.rs/
- pybind11: https://pybind11.readthedocs.io/en/stable/
- nanobind, y por qué existe: https://nanobind.readthedocs.io/en/latest/why.html

**Orden de lectura sugerido:** la guía de PyO3 hasta "Python functions"; después la página de nanobind que explica en qué se diferencia de pybind11.

---

## 🚀 8. Cierre

PyO3, pybind11 y nanobind exponen Rust o C++ como módulos de Python con veinte líneas de pegamento, y en velocidad empatan con C, Cython y numba. Se eligen por lo que
no está en el bucle: quién mantiene el código, cuánto tarda en construir (18 s Rust, 6 s nanobind), cuánto pesa la rueda y, como se vio, si el resultado coincide
bit a bit con Python.

**La señal de que quedó bien:** *"La extensión está en el lenguaje que el equipo mantiene, suelta el GIL donde corresponde, y el CI construye sus ruedas."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ff-fase-05 -m "op ff05 cerrada: Rust y C++ con la misma función, medidos y construidos"
> ```
>
> Los commits llevan su prefijo (`op ff05: …`) y los de ejercicio su número
> (`op ff05 ej07: …`).
