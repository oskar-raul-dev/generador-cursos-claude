"""El aviso de traslados de 2020: recoge los archivos que deja el lote del Siga y los mete en la base.

Corre cada cinco minutos con cron. Tiene los tres parches del primer año, y ninguno más:
  1. el .ok: solo procesa un .txt cuando ya existe su .ok;
  2. el bloqueo: si otra corrida está en curso (o lo parece), sale sin hacer nada;
  3. la tabla de procesados: no vuelve a procesar un nombre de archivo que ya vio.
"""
import os
import shutil
import sys
from pathlib import Path

import psycopg

TRANSFER_DIR = Path(os.environ.get("TRANSFER_DIR", "/var/lib/contingencia/traslados"))
LOCK = Path(os.environ.get("LOCK_FILE", "/var/lib/braqui/traslados.lock"))


def main() -> int:
    # Parche 2: si el bloqueo existe, otra corrida está andando. Sale callado.
    if LOCK.exists():
        return 0
    LOCK.touch()
    done = TRANSFER_DIR / "procesados"
    done.mkdir(exist_ok=True)
    with psycopg.connect(os.environ["DATABASE_URL"]) as conn:
        for txt in sorted(TRANSFER_DIR.glob("traslados_*.txt")):
            # Parche 1: el .ok dice que el .txt terminó de escribirse.
            if not txt.with_suffix(".ok").exists():
                continue
            # Parche 3: el nombre del archivo es la marca de que ya se procesó.
            seen = conn.execute("SELECT 1 FROM transfer_file_processed WHERE file_name = %s", (txt.name,)).fetchone()
            if seen:
                continue
            count = 0
            for line in txt.read_text(encoding="utf-8").splitlines():
                if not line.strip():
                    continue
                order_id, sku, origin, destination, quantity, _created = line.split("|")
                conn.execute(
                    "INSERT INTO braqui_transfer (order_id, sku, origin_store_id, destination_store_id, quantity, file_name)"
                    " VALUES (%s, %s, %s, %s, %s, %s)",
                    (int(order_id), sku, origin, destination, int(quantity), txt.name))
                count += 1
            conn.execute("INSERT INTO transfer_file_processed (file_name) VALUES (%s)", (txt.name,))
            conn.commit()
            shutil.move(txt, done / txt.name)
            shutil.move(txt.with_suffix(".ok"), done / txt.with_suffix(".ok").name)
            print(f"{txt.name}: {count} traslados recibidos", flush=True)
    LOCK.unlink()
    return 0


if __name__ == "__main__":
    sys.exit(main())
