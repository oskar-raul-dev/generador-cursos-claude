"""El costo de distribución que nadie mide: cuántas ruedas publica cada paquete en su última versión."""

import json
import urllib.request

PACKAGES = {
    "httpx": "Python puro",
    "numba": "LLVM (C++)",
    "scikit-learn": "Cython",
    "orjson": "Rust (PyO3)",
    "pydantic-core": "Rust (PyO3)",
    "cffi": "C",
}
for package, kind in PACKAGES.items():
    data = json.load(urllib.request.urlopen(f"https://pypi.org/pypi/{package}/json", timeout=20))
    wheels = [f["filename"] for f in data["urls"] if f["filename"].endswith(".whl")]
    free_threaded = sum("cp314t" in w for w in wheels)
    print(f"{package:<14} {kind:<12} {data['info']['version']:<9} {len(wheels):>3} ruedas · {free_threaded:>2} para 3.14t")
