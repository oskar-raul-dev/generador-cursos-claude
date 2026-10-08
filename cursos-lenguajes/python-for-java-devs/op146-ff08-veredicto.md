# ⚖️ ff08 — Veredicto: la misma función en cuatro fronteras

> Python para desarrolladores Java senior · **Carta** · Track `ff` — La frontera nativa ·
> sección 8 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las siete anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track escribió la misma función —un suavizado exponencial de dos millones de valores, donde cada resultado depende del anterior— en Python, en C llamado con
`ctypes` y `cffi` ([`ff02`](op140-ff02-ctypes-y-cffi.md)), en Cython ([`ff03`](op141-ff03-cython.md)), con numba ([`ff04`](op142-ff04-numba.md)) y en Rust y C++
([`ff05`](op143-ff05-rust-y-cpp.md)), sobre el modelo de [`ff01`](op139-ff01-el-modelo.md) y con los *buffers* de [`ff06`](op144-ff06-el-buffer-compartido.md) y
el paralelismo de [`ff07`](op145-ff07-paralelismo-real.md).

El veredicto es que **en velocidad empatan**: todas las fronteras bien hechas dejan el cálculo entre 4,5 y 8,7 ms, de 19 a 36 veces menos que Python. Lo que las
separa no está en el bucle. Está en lo que las comparaciones de internet no miden: el arranque, la cadena de herramientas, la exactitud y, sobre todo, **el costo
de distribuir**: un paquete de Python puro es una rueda; uno con código nativo, decenas.

---

## 🧠 2. El modelo

Las cifras del track, todas de este mismo contenedor:

| Frontera | Tiempo | Contra Python (163 ms) | Lo que cuesta fuera del bucle | Igual a Python |
|---|---|---|---|---|
| C con `ctypes` / `cffi` (`ff02`) | 5,1 ms | 32× | Firmas a mano; 0,5 µs por llamada con `ctypes` | No: FMA (5,7e-13) |
| Cython, *memoryviews* (`ff03`) | 8,7 ms | 19× | `setuptools`, compilar por plataforma; reservar el resultado | No: FMA |
| numba (`ff04`) | 4,5 ms | 36× | 151 ms de `import`, 186 ms la primera llamada | **Sí, bit a bit** (sin `fastmath`) |
| PyO3 (`ff05`) | 5,3 ms | 31× | 18 s de construcción, rueda de 292 KB | **Sí, bit a bit** |
| pybind11 (`ff05`) | 5,1 ms | 32× | 8 s, 65 KB | No: FMA |
| nanobind (`ff05`) | 5,1 ms | 32× | 6 s, 51 KB | No: FMA |

La memoria no entra en la tabla porque no separa a nadie: todas reciben el arreglo sin copiarlo (`ff06`) y crean uno del mismo tamaño para el resultado.

---

## 💻 3. El ejemplo que corre

Dos programas. `ruedas.py` mide en PyPI el costo de distribución: cuántas ruedas tiene que construir y publicar cada paquete en su última versión.

```python
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
```

`frontera.py` es el veredicto como función, aplicado a seis funciones calientes:

```python
"""¿Dónde mover la frontera? El veredicto del track como función, aplicada a cinco funciones calientes."""

from dataclasses import dataclass


@dataclass
class HotFunction:
    name: str
    share_of_time: float               # fracción del tiempo total del programa que se va en ella
    vectorizable: bool = False         # ¿NumPy la expresa como operación de arreglo completo?
    numeric_loop: bool = True          # ¿números y arreglos, sin objetos de Python?
    long_running: bool = True          # ¿el proceso vive lo suficiente para pagar 340 ms de arranque?
    wraps_existing_c: bool = False
    team_writes: str = "Python"        # "Python", "Rust", "C++"


def decide(f: HotFunction) -> str:
    if f.share_of_time < 0.2:
        return "nada: no es el cuello de botella"
    if f.wraps_existing_c:
        return "cffi (ff02)"
    if f.vectorizable:
        return "NumPy, sin compilar nada (ds01)"
    if f.numeric_loop and f.long_running:
        return "numba (ff04)"
    if f.team_writes == "Rust":
        return "PyO3 + maturin (ff05), con cibuildwheel"
    if f.team_writes == "C++":
        return "nanobind (ff05), con cibuildwheel"
    return "Cython (ff03), con cibuildwheel"


FUNCTIONS = [
    HotFunction("Suavizado de la serie de recaudo", 0.7),
    HotFunction("Mora diaria de todos los saldos", 0.5, vectorizable=True),
    HotFunction("Validación de formularios", 0.05, numeric_loop=False),
    HotFunction("Lector de huellas del fabricante", 0.4, wraps_existing_c=True),
    HotFunction("Suavizado en un CLI de 0,3 s", 0.8, long_running=False),
    HotFunction("Normalizar nombres en lotes de texto", 0.6, numeric_loop=False, team_writes="Rust"),
]
for f in FUNCTIONS:
    print(f"{f.name:<38} → {decide(f)}")
```

```bash
python3 ruedas.py
python3 frontera.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
httpx          Python puro  0.28.1      1 ruedas ·  0 para 3.14t
numba          LLVM (C++)   0.68.0     31 ruedas ·  4 para 3.14t
scikit-learn   Cython       1.9.1      42 ruedas ·  6 para 3.14t
orjson         Rust (PyO3)  3.12.0     64 ruedas ·  0 para 3.14t
pydantic-core  Rust (PyO3)  2.49.0    136 ruedas · 15 para 3.14t
cffi           C            2.1.1      99 ruedas · 11 para 3.14t
Suavizado de la serie de recaudo       → numba (ff04)
Mora diaria de todos los saldos        → NumPy, sin compilar nada (ds01)
Validación de formularios              → nada: no es el cuello de botella
Lector de huellas del fabricante       → cffi (ff02)
Suavizado en un CLI de 0,3 s           → Cython (ff03), con cibuildwheel
Normalizar nombres en lotes de texto   → PyO3 + maturin (ff05), con cibuildwheel
```

`httpx` publica **una** rueda, que sirve en todas partes. `pydantic-core` publica **136**: cada versión de Python, cada sistema operativo, cada arquitectura, y ahora
también cada variante sin GIL. Esa es la cifra que la tabla de §2 no tiene: mover la frontera convierte un `pip install` universal en una matriz de construcción. Y
`orjson`, con 64 ruedas, todavía no tiene ninguna para `3.14t`: quien usa el intérprete sin GIL lo compila al instalar, con Rust, o no lo usa.

**Detalles con intención**

- **La fracción del tiempo se evalúa primero**: una función que es el 5% del programa no justifica ninguna frontera, aunque se acelere 36 veces.
- **numba gana en procesos largos** porque no agrega ruedas propias (las de numba ya existen) ni cadena de herramientas; pierde en un CLI corto por sus 340 ms de
  arranque (151 de `import` más 186 de compilación).
- **"con cibuildwheel"** al lado de Cython, PyO3 y nanobind: es la herramienta que construye la matriz de ruedas en el CI. Elegir una de esas fronteras es elegir
  mantener esa matriz.
- **El umbral de 0,2** es una suposición a la vista: por debajo de un quinto del tiempo, la ganancia total del programa no alcanza a notarse.

---

## ⚠️ 4. Lo que se rompe

**Elegir por el *benchmark* del bucle.** Todas empatan en el bucle. La decisión real es de arranque, mantenimiento y distribución.

**Olvidar la exactitud.** Cuatro de las seis fronteras no dan el mismo resultado que Python, por la FMA. En un cálculo de dinero o en una prueba que compara con
`==`, importa.

**La matriz de ruedas que nadie mantiene.** La extensión que se construyó a mano para Linux x86 un día, y que nadie sabe reconstruir cuando llega Python 3.15 o un
portátil ARM.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Si la función es de cadenas, objetos o E/S.** Ninguna frontera del track fue medida con eso; con cadenas, convertir puede costar más que el cálculo.

**Si el código ya vive en un ecosistema nativo.** Si el equipo mantiene una biblioteca de C++ grande, nanobind no es "una opción más": es el puente natural.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Agrega a `ruedas.py` tres paquetes que uses. **Criterio:** cuántos son Python puro y cuántas ruedas publica el que más.
2. Cambia el umbral de 0,2 a 0,1. **Criterio:** qué función cambia de decisión y si estás de acuerdo.

**🟡 Intermedio (3–4)**

3. Agrega la dimensión "necesita resultado exacto a Python" y úsala. **Criterio:** una función que pase de numba o C++ a PyO3 o a quedarse en Python.
4. Escribe las pruebas de `decide` con un caso por regla. **Criterio:** siete casos, todos pasan.

**🟠 Difícil (5–6)**

5. Configura `cibuildwheel` para la extensión de nanobind de `ff05` con Python 3.13, 3.14 y 3.14t en Linux x86 y ARM. **Criterio:** cuántas ruedas y cuánto tarda el CI.
6. Mide el suavizado con las seis fronteras en tu máquina. **Criterio:** la tabla de §2 con tus números, y si cambia algún orden.

**🔴 Muy difícil (7–8)**

7. Escribe la política de código nativo de tu equipo. **Criterio:** una página. *Rúbrica:* (a) cuándo se permite mover la frontera; (b) qué herramienta por defecto y por
   qué; (c) quién mantiene la matriz de ruedas; (d) cómo se prueba la exactitud contra Python.
8. Audita las dependencias nativas de un proyecto real. **Criterio:** una tabla. *Rúbrica:* (a) cada paquete con su lenguaje nativo; (b) si tiene ruedas para tus
   plataformas y para `3.14t`; (c) cuáles se compilan al instalar; (d) cuáles reemplazarías.

---

## 📚 7. Referencias

- `cibuildwheel`: https://cibuildwheel.pypa.io/en/stable/
- Ralf Gommers y otros, *pypackaging-native*, el problema de empaquetar código nativo contado por quienes lo mantienen: https://pypackaging-native.github.io/

**Orden de lectura sugerido:** *pypackaging-native*, para ver el problema completo; después la documentación de `cibuildwheel`. El resto del track tiene sus
referencias en cada sección.

---

## 🚀 8. Cierre

Bien hechas, todas las fronteras dejan el bucle entre 19 y 36 veces más rápido, y en eso empatan. Se elige por lo demás: numba si el proceso vive lo suficiente,
`cffi` para envolver C que ya existe, PyO3 o nanobind si el equipo los mantiene, y en todos los casos con la matriz de ruedas a la vista: 1 contra 136.

**La señal de que quedó bien:** *"Cada función nativa del proyecto tiene al lado su fracción del tiempo, su herramienta elegida y quién construye sus ruedas."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ff-fase-08 -m "op ff08 cerrada: empatan en el bucle; se elige por arranque, exactitud y ruedas"
> ```
>
> Los commits llevan su prefijo (`op ff08: …`) y los de ejercicio su número
> (`op ff08 ej07: …`).
