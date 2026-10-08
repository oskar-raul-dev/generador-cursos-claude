"""🧨 Un artefacto de modelo es un ejecutable disfrazado de dato.

    python pickle_danger.py

La Fase 16 del camino base ya lo dijo; aquí se cobra en el caso concreto de esta sección.
`pickle.load` **no lee datos: reconstruye objetos**, y para reconstruirlos ejecuta lo que el
archivo le diga. Un `.pkl` que llega por correo, que se baja de un bucket o que alguien dejó
en una carpeta compartida es código que vas a correr con los permisos de tu servidor.

La demostración de abajo es **deliberadamente inofensiva**: escribe un archivo en un
directorio temporal y lo borra. En su lugar podría ir cualquier cosa que el proceso pueda
hacer, que en un servidor de predicciones es bastante.

🧭 **La regla que sale de aquí: un `.pkl` solo se carga si tu propio proceso lo escribió.**
No "si confías en quien te lo pasó", no "si viene de un repositorio interno": si lo escribió
tu proceso de entrenamiento, en tu infraestructura, y nadie más pudo tocarlo desde entonces.
Todo lo demás —incluido el modelo del cuaderno de un compañero— se convierte primero a un
formato que solo sepa describir números.
"""

from __future__ import annotations

import pickle
import tempfile
from pathlib import Path


class InnocentLookingModel:
    """Lo que un modelo malicioso parece desde fuera: una clase con un nombre creíble.

    `__reduce__` es el gancho que `pickle` usa para saber cómo reconstruir un objeto, y
    devuelve **una función y sus argumentos**. Nada obliga a que esa función construya nada:
    aquí devuelve `Path.write_text`, y `pickle` la llama obedientemente al cargar.
    """

    def __init__(self, target: Path) -> None:
        self.target = target

    def __reduce__(self):
        return (Path(self.target).write_text,
                ("Este texto lo escribió el archivo al cargarse.\n",))


def demonstrate() -> str:
    """Serializa el señuelo, lo carga como cargarías un modelo, y mira qué pasó."""
    with tempfile.TemporaryDirectory() as scratch:
        evidence = Path(scratch) / "prueba.txt"
        blob = pickle.dumps(InnocentLookingModel(evidence))

        # Este es el único paso que importa, y es el que hace cualquier servidor que carga
        # un modelo. No hay validación posible antes: para saber qué hay dentro habría que
        # interpretarlo, que es exactamente lo que produce el problema.
        pickle.loads(blob)

        return evidence.read_text(encoding="utf-8") if evidence.exists() else ""


def main() -> None:
    written = demonstrate()
    print("Se serializó un objeto con un `__reduce__` propio y se cargó con `pickle.loads`.")
    print(f"Efecto observado al cargar: {written.strip()!r}")
    print()
    print("No hubo ninguna advertencia, ninguna excepción y ninguna forma de verlo venir.")
    print("El mismo archivo, con otro `__reduce__`, corre lo que el proceso pueda correr.")
    print()
    print("Por eso el endpoint de esta sección se sirve con ONNX: un grafo ONNX describe")
    print("operaciones sobre tensores y no puede llamar a `Path.write_text`.")


if __name__ == "__main__":
    main()
