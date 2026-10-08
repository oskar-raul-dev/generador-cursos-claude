"""Binario de verdad: registros con struct, acceso con mmap, mojibake, zip con zstd y el filtro de tar."""

import io
import mmap
import os
import struct
import tarfile
import time
import zipfile

RECORD = struct.Struct("<i d 8s")             # id (int32), monto (float64), sede (8 bytes); little endian, sin relleno
N = 1_000_000
BRANCHES = [b"CENTRO", b"CHAPIN", b"SUBA", b"KENNEDY", b"USAQUEN", b"ENGATIVA", b"FONTIBON", b"RESTREPO"]

with open("pagos.bin", "wb") as f:
    for i in range(N):
        f.write(RECORD.pack(i, 1000.0 + i % 997, BRANCHES[i % 8]))
print(f"registro de {RECORD.size} bytes · archivo de {os.path.getsize('pagos.bin') / 2**20:.1f} MB")
print("CHAPINERO en 8s:", RECORD.unpack(RECORD.pack(0, 0.0, b"CHAPINERO"))[2])   # struct corta sin avisar

# 1) Leer todo: un unpack por registro contra iter_unpack
data = open("pagos.bin", "rb").read()
start = time.perf_counter()
total = 0.0
for offset in range(0, len(data), RECORD.size):
    total += RECORD.unpack_from(data, offset)[1]
loop = time.perf_counter() - start
start = time.perf_counter()
total_iter = sum(amount for _, amount, _ in RECORD.iter_unpack(data))
print(f"unpack_from en bucle {loop * 1000:5.0f} ms · iter_unpack {(time.perf_counter() - start) * 1000:5.0f} ms · iguales: {total == total_iter}")

# 2) Un registro del medio, sin leer el archivo
with open("pagos.bin", "rb") as f, mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as m:
    rid, amount, branch = RECORD.unpack_from(m, 700_000 * RECORD.size)
    print(f"registro 700000 por mmap: id={rid} monto={amount} sede={branch.rstrip(b'\0').decode()}")

# 3) Mojibake: UTF-8 leído como Latin-1, y de vuelta
broken = "Engativá · Usaquén".encode("utf-8").decode("latin-1")
print(f"mojibake: {broken!r} · reparado: {broken.encode('latin-1').decode('utf-8')!r}")

# 4) zip: el mismo archivo con cada compresión (ZIP_ZSTANDARD es nuevo en 3.14)
for name, method in (("stored", zipfile.ZIP_STORED), ("deflate", zipfile.ZIP_DEFLATED), ("bzip2", zipfile.ZIP_BZIP2),
                     ("lzma", zipfile.ZIP_LZMA), ("zstd", zipfile.ZIP_ZSTANDARD)):
    buffer = io.BytesIO()
    start = time.perf_counter()
    with zipfile.ZipFile(buffer, "w", compression=method) as z:
        z.write("pagos.bin")
    packed = time.perf_counter() - start
    start = time.perf_counter()
    with zipfile.ZipFile(buffer) as z:
        z.read("pagos.bin")
    print(f"zip {name:<8} {buffer.tell() / 2**20:5.2f} MB · comprimir {packed * 1000:5.0f} ms · leer {(time.perf_counter() - start) * 1000:4.0f} ms")

# 5) tar: un miembro que intenta salir de la carpeta de destino
evil = io.BytesIO()
with tarfile.open(fileobj=evil, mode="w") as t:
    info = tarfile.TarInfo("../fuera.txt"); payload = b"no deberia estar aqui"; info.size = len(payload)
    t.addfile(info, io.BytesIO(payload))
evil.seek(0)
try:
    with tarfile.open(fileobj=evil) as t:
        t.extractall("destino")
    print("tar: extrajo ../fuera.txt")
except tarfile.FilterError as error:
    print(f"tar: {type(error).__name__}: {error}")
os.remove("pagos.bin")
