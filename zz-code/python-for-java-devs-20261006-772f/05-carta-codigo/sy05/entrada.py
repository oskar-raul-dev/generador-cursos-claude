"""La carpeta de la aseguradora: leer al 'crearse' lee a medias; 'closed' y el renombrado leen completo."""

import os
import pathlib
import threading
import time

from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

INBOX = pathlib.Path("entrada")
INBOX.mkdir(exist_ok=True)
ROWS = 50_000
seen: dict[str, list[str]] = {"al crearse": [], "al cerrarse": [], "al renombrarse": []}


def count_rows(path: str) -> int:
    try:
        return max(sum(1 for _ in open(path)) - 1, 0)
    except FileNotFoundError:
        return -1


class Handler(FileSystemEventHandler):
    def on_created(self, event):
        if event.src_path.endswith(".csv"):
            seen["al crearse"].append(f"{pathlib.Path(event.src_path).name}: {count_rows(event.src_path)} filas")

    def on_closed(self, event):
        if event.src_path.endswith(".csv"):
            seen["al cerrarse"].append(f"{pathlib.Path(event.src_path).name}: {count_rows(event.src_path)} filas")

    def on_moved(self, event):
        if event.dest_path.endswith(".csv"):
            seen["al renombrarse"].append(f"{pathlib.Path(event.dest_path).name}: {count_rows(event.dest_path)} filas")


def insurer_writes(name: str, rename: bool):
    """La aseguradora copia el lote despacio, como por una red lenta."""
    target = INBOX / name
    path = target.with_suffix(".part") if rename else target
    with open(path, "w") as f:
        f.write("autorizacion,plan,valor\n")
        for i in range(ROWS):
            f.write(f"AUT-{i:06d},PL-{i % 300:03d},{150_000 + i}\n")
            if i % 5_000 == 0:
                f.flush()
                time.sleep(0.05)
    if rename:
        os.replace(path, target)


observer = Observer()
observer.schedule(Handler(), str(INBOX))
observer.start()
for name, rename in [("lote-1.csv", False), ("lote-2.csv", True)]:
    t = threading.Thread(target=insurer_writes, args=(name, rename))
    t.start()
    t.join()
time.sleep(1)
observer.stop()
observer.join()
for when, items in seen.items():
    print(f"{when:<15}", items)
