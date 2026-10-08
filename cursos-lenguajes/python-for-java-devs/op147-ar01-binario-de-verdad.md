# 🧮 ar01 — Binario de verdad

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 1 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Antes de Pillow, de los PDF y del vídeo, hay bytes. Un archivo de registros de ancho fijo que exporta el datáfono, un `.zip` con los reportes del mes, un `.tar`
que llega del proveedor, un CSV que alguien guardó en Latin-1. Este track trata de transformar archivos, y empieza por lo que la biblioteca estándar ya resuelve
sin instalar nada: **`struct`** para leer y escribir registros binarios, **`mmap`** para tratar un archivo como memoria, las **codificaciones** de texto, y
**`zipfile`** y **`tarfile`**.

Dos novedades de Python 3.14 cambian la respuesta habitual: `zipfile` ahora comprime con **Zstandard**, y `tarfile` **filtra por defecto** los miembros que intentan
escribir fuera de la carpeta de destino. Esta sección mide la primera y prueba la segunda.

---

## 🧠 2. El modelo

| Pieza | Para qué | El equivalente en Java |
|---|---|---|
| `struct.Struct("<i d 8s")` | Empaquetar y desempaquetar registros de ancho fijo | `ByteBuffer` con `order(LITTLE_ENDIAN)` y `getInt`, `getDouble` |
| `struct.iter_unpack` | Recorrer un *buffer* de registros sin bucle de Python por campo | — |
| `mmap` | El archivo como memoria: leer un registro sin leer el archivo | `FileChannel.map` |
| `bytes.decode("utf-8")` | Bytes a texto, con la codificación dicha en voz alta | `new String(bytes, UTF_8)` |
| `zipfile`, `tarfile` | Contenedores de archivos, con compresión | `java.util.zip`, Commons Compress |

### Esto sí funciona igual

El modelo es el de `ByteBuffer`: un formato declarado (orden de bytes, tamaño de cada campo) y lecturas en posiciones calculadas. `<` en el formato de `struct` es
`ByteOrder.LITTLE_ENDIAN`; sin él, `struct` usa el orden y la alineación de la máquina, como un `ByteBuffer` sin `order`, y el archivo deja de ser portable.

---

## 💻 3. El ejemplo que corre

`binario.py`:

```python
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
```

```bash
python3 binario.py              # solo la biblioteca estándar
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
registro de 20 bytes · archivo de 19.1 MB
CHAPINERO en 8s: b'CHAPINER'
unpack_from en bucle   155 ms · iter_unpack    84 ms · iguales: True
registro 700000 por mmap: id=700000 monto=1106.0 sede=CENTRO
mojibake: 'EngativÃ¡ Â· UsaquÃ©n' · reparado: 'Engativá · Usaquén'
zip stored   19.07 MB · comprimir    35 ms · leer   12 ms
zip deflate   4.15 MB · comprimir   476 ms · leer   36 ms
zip bzip2     1.75 MB · comprimir   800 ms · leer  284 ms
zip lzma      0.58 MB · comprimir  9339 ms · leer   83 ms
zip zstd      1.91 MB · comprimir    69 ms · leer   28 ms
tar: OutsideDestinationError: '../fuera.txt' would be extracted to '/w/fuera.txt', which is outside the destination
```

Seis lecturas. `struct` **corta sin avisar**: `CHAPINERO` en un campo de 8 bytes queda `CHAPINER`. `iter_unpack` lee el millón de registros en la mitad del tiempo
que el bucle. `mmap` saca el registro 700.000 sin leer los 19 MB. El *mojibake* se repara deshaciendo el error al revés. En compresión, **zstd** deja el archivo
en 1,91 MB en **69 ms**: menos de la mitad del tamaño de `deflate` y siete veces más rápido; `lzma` comprime tres veces más que zstd y tarda **135 veces más**. Y el
`.tar` con un `../fuera.txt` adentro no se extrae: `OutsideDestinationError`, sin haber pedido ningún filtro.

**Detalles con intención**

- **`<`** al principio del formato fija el orden de bytes y quita el relleno de alineación: el registro mide 4 + 8 + 8 = 20 bytes. Con el orden nativo (`@`, el
  valor por defecto) mediría 24, porque el `double` se alinea a 8.
- **`8s`** es un campo de bytes de ancho fijo: rellena con ceros los cortos y corta los largos. Al leer, `rstrip(b"\0")` quita el relleno.
- **El *mojibake*** `Ã¡` es la firma de UTF-8 leído como Latin-1. Se repara con `.encode("latin-1").decode("utf-8")`, siempre que nadie haya guardado ya el texto
  roto con otra codificación encima.
- **`ZIP_ZSTANDARD`** usa el módulo `compression.zstd`, nuevo en 3.14. No hay que instalar nada.
- **El filtro de `tarfile`** es `"data"` por defecto desde 3.14: rechaza rutas absolutas, `..`, enlaces que salen del destino y archivos de dispositivo. Antes de 3.14
  extraía todo, y era una vulnerabilidad clásica (CVE-2007-4559).

---

## ⚠️ 4. Lo que se rompe

**El zip con zstd que nadie más abre.** Python 3.14 lo escribe y lo lee; `unzip` de Debian lo salta con `skipping: a.txt  need PK compat. v6.3 (can do v4.6)`, y
el explorador de Windows tampoco lo abre. Para archivos que van a otras personas, `deflate`; zstd para lo que solo lee Python (o herramientas que lo soporten).

**El campo que se corta.** `struct` no valida longitudes: un nombre de sede largo se trunca y el archivo sale "bien". Se valida el largo antes de empaquetar.

**El orden de bytes implícito.** Un formato sin `<` ni `>` funciona en el portátil y produce otro archivo en una máquina *big endian* o con otra alineación.

**`open()` sin `encoding`.** Desde Python 3.15 el valor por defecto será UTF-8 en todas partes (PEP 686); hasta entonces, en Windows depende de la configuración
regional. Se escribe `encoding="utf-8"` siempre.

---

## ⚖️ 5. Cuándo NO usarlo

**Para formatos que ya tienen biblioteca.** Un PNG, un PDF o un Parquet no se leen con `struct`: Pillow, `pypdf` o Arrow (`ar02`, `ar04`).

**Para archivos binarios grandes con muchos registros numéricos.** `np.fromfile` con un `dtype` estructurado lee el millón de registros como arreglo, sin bucle.

**zstd en un archivo que va a un cliente.** El formato no es el problema: las herramientas del otro lado sí.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las once líneas, y por qué el registro mide 20 bytes.
2. Cambia `<` por `@` en el formato. **Criterio:** el nuevo tamaño del registro y del archivo.
3. Repara un texto con doble *mojibake* (codificado mal dos veces). **Criterio:** el texto original.

**🟡 Intermedio (4–6)**

4. Lee `pagos.bin` con `np.fromfile` y un `dtype` estructurado. **Criterio:** el total y el tiempo contra `iter_unpack`.
5. Valida el largo de la sede antes de empaquetar y lanza un error claro. **Criterio:** `CHAPINERO` falla con un mensaje que dice el campo y el máximo.
6. Comprime con zstd en niveles 1, 3, 10 y 19 (`compresslevel`). **Criterio:** la tabla de tamaño y tiempo.

**🟠 Difícil (7–9)**

7. Arma un `.tar` con un enlace simbólico a `/etc/passwd` y extráelo con los filtros `"data"`, `"tar"` y `"fully_trusted"`. **Criterio:** qué hace cada uno.
8. Escribe un lector de un formato de ancho fijo real (por ejemplo, el de un datáfono o un banco) con `struct`. **Criterio:** los registros leídos y una prueba.
9. Detecta la codificación de un CSV con `charset-normalizer`. **Criterio:** acierta en UTF-8, Latin-1 y cp1252, y dónde se equivoca.

**🔴 Muy difícil (10)**

10. Diseña el formato de intercambio de un archivo binario entre un servicio Java y uno de Python. **Criterio:** una página. *Rúbrica:* (a) el formato de
    `struct` y su equivalente en `ByteBuffer`; (b) el orden de bytes y la versión del formato; (c) cómo se validan los largos; (d) por qué no Protobuf o Arrow, o
    por qué sí.

---

## 📚 7. Referencias

**Documentación oficial**

- `struct`: https://docs.python.org/3/library/struct.html
- `zipfile` (incluye `ZIP_ZSTANDARD`): https://docs.python.org/3/library/zipfile.html
- Los filtros de extracción de `tarfile`: https://docs.python.org/3/library/tarfile.html#tarfile-extraction-filter

**Orden de lectura sugerido:** la tabla de formatos de `struct` (orden de bytes y alineación); después la sección de filtros de `tarfile`.

---

## 🚀 8. Cierre

La biblioteca estándar lee y escribe binario de verdad: `struct` con el orden de bytes explícito, `mmap` para no leer lo que no hace falta, codificaciones dichas
en voz alta. En 3.14, zstd comprime más que `deflate` siete veces más rápido —para archivos que solo abre Python—, y `tarfile` ya no extrae fuera del destino.

**La señal de que quedó bien:** *"Cada formato binario tiene su `<` o `>`, cada campo su validación de largo, y cada `open` su `encoding`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-01 -m "op ar01 cerrada: struct, mmap, codificaciones, zip con zstd y tar filtrado"
> ```
>
> Los commits llevan su prefijo (`op ar01: …`) y los de ejercicio su número
> (`op ar01 ej07: …`).
