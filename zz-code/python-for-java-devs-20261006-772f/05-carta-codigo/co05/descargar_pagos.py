"""Baja las relaciones de pago del SFTP de la aseguradora, solo las completas y solo una vez."""

import hashlib
import json
import stat
import time
from pathlib import Path

import paramiko

REMOTE_DIR = "/salida/aurea"
LOCAL_DIR = Path("pagos")
LEDGER = Path("pagos/.descargados.json")
SETTLE_SECONDS = 30  # si el emisor no avisa, un archivo quieto 30 s se da por terminado


def connect(host: str, port: int, user: str, key_file: str) -> paramiko.SFTPClient:
    client = paramiko.SSHClient()
    client.load_host_keys("known_hosts")
    client.set_missing_host_key_policy(paramiko.RejectPolicy())
    client.connect(host, port=port, username=user, key_filename=key_file,
                   allow_agent=False, look_for_keys=False, timeout=15)
    return client.open_sftp()


def ready_files(sftp: paramiko.SFTPClient) -> list[paramiko.SFTPAttributes]:
    entries = {e.filename: e for e in sftp.listdir_attr(REMOTE_DIR) if stat.S_ISREG(e.st_mode)}
    ready = []
    for name, entry in entries.items():
        if name.endswith((".tmp", ".part", ".ok")):
            continue
        # Regla 1: si el emisor publica .ok, manda el .ok; si no, que lleve un rato quieto.
        if f"{name}.ok" in entries or time.time() - entry.st_mtime > SETTLE_SECONDS:
            ready.append(entry)
    return ready


def download(sftp: paramiko.SFTPClient, entry: paramiko.SFTPAttributes, ledger: dict) -> Path | None:
    key = f"{entry.filename}|{entry.st_size}|{entry.st_mtime}"
    if ledger.get(entry.filename) == key:
        return None                                    # Regla 4: ya está, idéntico
    remote = f"{REMOTE_DIR}/{entry.filename}"
    part = LOCAL_DIR / f"{entry.filename}.part"
    offset = part.stat().st_size if part.exists() else 0
    with sftp.open(remote, "rb") as source, part.open("ab") as target:
        source.seek(offset)                            # retoma donde se cortó
        source.prefetch(entry.st_size)                 # el tamaño TOTAL, no lo que falta: pide por adelantado
        while chunk := source.read(1 << 20):
            target.write(chunk)
    if part.stat().st_size != entry.st_size:           # Regla 3: verificar antes de publicar
        raise OSError(f"{entry.filename}: {part.stat().st_size} de {entry.st_size} bytes")
    final = LOCAL_DIR / entry.filename
    part.replace(final)                                # Regla 2: aparece completo o no aparece
    ledger[entry.filename] = key
    return final


def run(host: str, port: int) -> None:
    LOCAL_DIR.mkdir(exist_ok=True)
    ledger = json.loads(LEDGER.read_text()) if LEDGER.exists() else {}
    with connect(host, port, "aurea", "aurea_ed25519") as sftp:
        for entry in ready_files(sftp):
            path = download(sftp, entry, ledger)
            if path:
                digest = hashlib.sha256(path.read_bytes()).hexdigest()[:12]
                print(f"bajado {path.name} ({entry.st_size} bytes, sha256 {digest}…)")
            LEDGER.write_text(json.dumps(ledger, indent=2))  # después de cada archivo, no al final
    print(f"{len(ledger)} archivos en el registro")


if __name__ == "__main__":
    import sys
    run(sys.argv[1], int(sys.argv[2]))
