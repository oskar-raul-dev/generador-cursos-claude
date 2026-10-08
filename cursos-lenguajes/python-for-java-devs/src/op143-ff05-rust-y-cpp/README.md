# ff05 — PyO3, pybind11 y nanobind

Código de la sección [`op143-ff05-rust-y-cpp.md`](../../op143-ff05-rust-y-cpp.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `rs/Cargo.toml` | Configuración del ejemplo |
| `rs/pyproject.toml` | Configuración del ejemplo |
| `rs/src/lib.rs` | Suavizado exponencial sobre un arreglo de NumPy |
| `pb/ema_pb.cpp` | — |
| `pb/pyproject.toml` | Configuración del ejemplo |
| `pb/CMakeLists.txt` | Archivo del ejemplo |
| `nb/ema_nb.cpp` | — |
| `nb/pyproject.toml` | Configuración del ejemplo |
| `nb/CMakeLists.txt` | Archivo del ejemplo |
| `construir.sh` | — |
| `medir.py` | La misma función en Rust (PyO3), C++ (pybind11) y C++ (nanobind), llamada desde Python y medida |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
apt-get install cargo           # o rustup; el contenedor usó el de Debian: rustc 1.85.1
pip install numpy cmake
bash construir.sh
python3 medir.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
