"""La medición de la sección 6: cuántos cuadernos reejecutan limpio de arriba abajo.

    uv run --with papermill==2.7.0 --with jupyterlab==4.6.3 \\
           python check_reproducibility.py --cuadernos cuadernos

Cada cuaderno se ejecuta **en un kernel nuevo, desde un directorio temporal vacío y de la
primera celda a la última**. Las tres condiciones importan y son las tres que no se cumplen
cuando alguien "lo corre otra vez" en su propia máquina:

- **Kernel nuevo**: sin variables heredadas de la sesión anterior.
- **Directorio vacío**: sin los archivos que estaban al lado por casualidad.
- **De arriba abajo**: sin el orden en que se escribió.

Es la medición más barata del curso y la más reveladora.

Y trae una segunda pasada que casi nadie hace: los cuadernos que **sí** corren se ejecutan
**dos veces** y se comparan sus salidas. Correr no es ser reproducible.

📝 **El kernel sale de `ipykernel`, no de Jupyter.** Al instalarse, `ipykernel` deja su
especificación en `sys.prefix/share/jupyter/kernels/python3` y `nbclient` la encuentra sola.
`papermill` **no** lo arrastra: en un entorno con papermill y nada más, esto falla con
`NoSuchKernel` y el mensaje no explica por qué. De ahí `require_kernel`, que falla temprano
y dice qué instalar.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import tempfile
import time
from pathlib import Path

# Los códigos de color que el kernel mete en el traceback porque cree que habla con una
# terminal. Sin quitarlos, el JSON de la medición queda ilegible.
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def require_kernel(name: str = "python3") -> None:
    """Falla temprano y con un mensaje útil si no hay kernel que usar."""
    from jupyter_client.kernelspec import KernelSpecManager

    available = list(KernelSpecManager().find_kernel_specs())
    if name not in available:
        raise SystemExit(
            f"No hay un kernel «{name}» en este entorno "
            f"(encontrados: {available or 'ninguno'}). Lo instala `ipykernel`, que papermill "
            "no arrastra: agrega `--with jupyterlab==4.6.3` o `--with ipykernel`."
        )


def run_once(path: Path, timeout: int = 120) -> tuple[bool, str, list[str]]:
    """Ejecuta un cuaderno en un kernel nuevo desde un directorio vacío.

    Devuelve si terminó, el error si no, y las salidas de texto que produjo.
    """
    import nbformat
    from nbclient import NotebookClient
    from nbclient.exceptions import CellExecutionError

    with tempfile.TemporaryDirectory() as scratch:
        # El cuaderno se copia a un directorio vacío: si depende de un archivo que estaba
        # al lado, aquí se nota. Es la mitad del valor de esta medición.
        copy = Path(scratch) / path.name
        shutil.copy(path, copy)
        document = nbformat.read(copy, as_version=4)
        client = NotebookClient(document, timeout=timeout, kernel_name="python3",
                                resources={"metadata": {"path": scratch}})
        try:
            client.execute()
        except CellExecutionError as error:
            return False, ANSI.sub("", str(error).splitlines()[-1])[:90], []

        outputs = [output.get("text", "")
                   for cell in document.cells
                   for output in cell.get("outputs", [])]
        return True, "", outputs


def check(path: Path) -> dict:
    """Un cuaderno: se ejecuta, se informa, y si corrió se ejecuta otra vez."""
    started = time.perf_counter()
    ran, error, outputs = run_once(path)
    elapsed = (time.perf_counter() - started) * 1000

    stable = None
    if ran:
        # Segunda pasada: correr no es ser reproducible. Un cuaderno que da otro número
        # cada vez pasa la primera prueba y falla la que importa.
        _, _, again = run_once(path)
        stable = outputs == again

    mark = "✅" if stable else ("🟡" if ran else "❌")
    detail = error if not ran else ("" if stable else "salidas distintas entre corridas")
    print(f"{mark} {path.name:<32}{elapsed:>7.0f} ms  {detail}")
    return {"cuaderno": path.name, "corre": ran, "estable": stable,
            "error": error, "ms": round(elapsed)}


def main() -> None:
    parser = argparse.ArgumentParser(description="¿Cuántos cuadernos sobreviven?")
    parser.add_argument("--cuadernos", type=Path, default=Path("cuadernos"))
    parser.add_argument("--json", type=Path, help="Guarda el detalle para la sección 6.")
    args = parser.parse_args()

    require_kernel()
    results = [check(path) for path in sorted(args.cuadernos.glob("*.ipynb"))]

    total = len(results)
    ran = sum(result["corre"] for result in results)
    stable = sum(bool(result["estable"]) for result in results)
    print(f"\n{ran} de {total} corren de arriba abajo en un kernel nuevo.")
    print(f"{stable} de {total} además dan el mismo resultado dos veces seguidas.")

    if args.json:
        args.json.write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n",
                             encoding="utf-8")


if __name__ == "__main__":
    main()
