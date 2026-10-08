"""Instantáneas con rsync, manifiesto calculado del origen, la copia que no copió, y el daño compartido por enlaces duros."""

import hashlib
import json
import os
import pathlib
import random
import shutil
import subprocess

SRC, BACKUPS = pathlib.Path("exportes"), pathlib.Path("respaldos")
for d in (SRC, BACKUPS, pathlib.Path("restaurado")):
    shutil.rmtree(d, ignore_errors=True)
SRC.mkdir()
BACKUPS.mkdir()                                              # rsync solo crea el último nivel del destino
random.seed(3)
for i in range(50):
    (SRC / f"exporte-{i:02d}.csv").write_bytes(random.randbytes(100_000))


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot(day: str, previous: str | None, checksum: bool = False) -> list[str]:
    target = BACKUPS / day
    shutil.rmtree(target, ignore_errors=True)
    cmd = ["rsync", "-a", "--delete"] + (["--checksum"] if checksum else [])
    if previous:
        cmd.append(f"--link-dest=../{previous}")             # relativo al destino
    manifest = {p.name: sha256(p) for p in sorted(SRC.glob("*.csv"))}    # lo que DEBERÍA quedar respaldado
    subprocess.run([*cmd, f"{SRC}/", f"{target}/"], check=True)
    (target / "manifiesto.json").write_text(json.dumps(manifest))
    return verify(target)


def verify(snapshot_dir: pathlib.Path) -> list[str]:
    manifest = json.loads((snapshot_dir / "manifiesto.json").read_text())
    return [name for name, digest in manifest.items() if sha256(snapshot_dir / name) != digest]


def used_mb(path: pathlib.Path) -> float:
    inodes = {p.stat().st_ino: p.stat().st_size for p in path.rglob("*.csv")}
    return sum(inodes.values()) / 1e6


print("2026-10-04:", snapshot("2026-10-04", None) or "verificada")
for i in (3, 7):                                             # dos exportes cambian, con el mismo tamaño y la misma
    path = SRC / f"exporte-{i:02d}.csv"                      # fecha de modificación: como un cambio en el mismo segundo,
    before = path.stat()                                     # o una herramienta que conserva la fecha al reescribir
    path.write_bytes(random.randbytes(100_000))
    os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
(SRC / "exporte-50.csv").write_bytes(random.randbytes(100_000))
print("2026-10-05 con -a:        no coinciden con el origen", snapshot("2026-10-05", "2026-10-04"))
print("2026-10-05 con --checksum: no coinciden con el origen", snapshot("2026-10-05", "2026-10-04", checksum=True))
print(f"las dos instantáneas parecen de {2 * 5.05:.1f} MB y ocupan {used_mb(BACKUPS):.1f} MB")

shutil.copytree(BACKUPS / "2026-10-05", "restaurado")
print("restauración de prueba:", verify(pathlib.Path("restaurado")) or "verificada")

# Un sector del disco de respaldo se daña: un byte de un archivo que no cambió entre los dos días.
victim = BACKUPS / "2026-10-04" / "exporte-20.csv"
data = bytearray(victim.read_bytes())
data[5_000] ^= 0xFF
with open(victim, "r+b") as f:                               # escribir en el mismo inodo, como el daño real
    f.write(data)
for day in ("2026-10-04", "2026-10-05"):
    print(f"verificación de {day}: dañados {verify(BACKUPS / day)}")
print("¿es el mismo archivo en disco?",
      os.path.samefile(BACKUPS / "2026-10-04" / "exporte-20.csv", BACKUPS / "2026-10-05" / "exporte-20.csv"))
