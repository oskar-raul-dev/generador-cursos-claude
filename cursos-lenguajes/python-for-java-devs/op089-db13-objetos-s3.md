# 🪣 db13 — Objetos: S3, y la MinIO que ya no está

> Python para desarrolladores Java senior · **Carta** · Track `db` — Hablarle a cada sistema de
> datos desde Python · sección 13 de 15
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Los exportes nocturnos de las diez sedes, los PDF de los reportes mensuales (`ui08`) y las radiografías digitales que el
proveedor de imágenes entrega por convenio son archivos, no filas. Guardarlos en una carpeta compartida funciona hasta que hay
que respaldarlos, darle acceso de solo lectura a un aliado o leerlos desde DuckDB (`db05`). El lugar natural es un almacén de
objetos con la API de S3: el de un proveedor de nube, o uno propio, compatible.

Desde Python se habla con **`boto3`** (el SDK de AWS, que funciona contra cualquier servidor compatible cambiando la
dirección) o con **`s3fs`**/`fsspec`, que lo presenta como un sistema de archivos. Las dos trampas para quien piensa en
carpetas: **no hay directorios** —hay claves con barras—, y **listar cuesta**: una llamada devuelve como máximo mil objetos, y el
código que no pagina pierde el resto en silencio.

Y una advertencia del terreno, que esta sección encontró al prepararse: **MinIO**, el servidor compatible con S3 que casi todos
los tutoriales usan para trabajar en local, dejó de mantener su edición de código abierto. Su repositorio dice desde 2025 *"this
repository is no longer maintained"*, y la imagen `minio/minio` ya no está en Docker Hub (comprobado el 05/10/2026: la página
responde 404 y el registro niega el manifiesto). El ejemplo usa **RustFS** 1.0.1, otro servidor
compatible; el código de Python es el mismo para cualquiera.

---

## 🧠 2. El modelo

| Lo que parece | Lo que es |
|---|---|
| Carpeta `exportes/2026-10-05/` | Un **prefijo** común a varias claves; no existe por sí solo |
| Listar una carpeta | `list_objects_v2` con `Prefix` y `Delimiter="/"`; de a **1 000** por llamada |
| Mover una carpeta | Copiar y borrar **cada objeto**; no hay renombrar |
| Modificar un archivo | Reemplazar el objeto entero |
| Permisos | Por *bucket*, prefijo u objeto, con políticas |

| Cliente | Versión | Para qué |
|---|---|---|
| `boto3` | 1.43.108 (con `s3fs`, 1.43.106: ver §4) | La API completa de S3 |
| `s3fs` / `fsspec` | 2026.9.0 | `s3://` como sistema de archivos; lo usan pandas, Polars y DuckDB |
| `minio` | 7.2.20 | El cliente de MinIO; habla con cualquier S3 |

### Tu instinto de Java dice… y esta vez se equivoca

Con el SDK de Java, `listObjectsV2` también devuelve mil, y el instinto lo sabe; lo que confunde en Python es que `boto3` no lo
oculta ni avisa: el diccionario de respuesta trae `IsTruncated: True` y `NextContinuationToken`, y si nadie los mira, el bucle
procesa los primeros mil exportes y termina "bien".

---

## 💻 3. El ejemplo que corre

```bash
uv add boto3 s3fs
```

`exportes.py`:

```python
"""S3 desde Python: claves con barras, la lista de a mil, el paginador y s3fs."""

import os
import time

import boto3
import s3fs
from botocore.config import Config

ENDPOINT = os.environ.get("AUREA_S3", "http://s3:9000")
KEYS = dict(aws_access_key_id="aurea-local", aws_secret_access_key="aurea-local-secret")
s3 = boto3.client("s3", endpoint_url=ENDPOINT, region_name="us-east-1", config=Config(retries={"max_attempts": 10}), **KEYS)
for _ in range(60):
    try:
        s3.list_buckets()
        break
    except Exception:
        time.sleep(1)

s3.create_bucket(Bucket="exportes")
SEDES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo", "Soacha", "Zipaquirá"]
for day in range(1, 26):
    for sede in SEDES:
        for kind in ("agenda", "abonos", "cartera", "citas", "regalias", "recordatorios", "glosas", "pagos", "planes", "rips"):
            s3.put_object(Bucket="exportes", Key=f"2026-09-{day:02d}/{sede}/{kind}.csv", Body=b"sede,valor\n")

first = s3.list_objects_v2(Bucket="exportes")
print("una llamada:", first["KeyCount"], "objetos · IsTruncated:", first["IsTruncated"])

pages = s3.get_paginator("list_objects_v2").paginate(Bucket="exportes")
print("con el paginador:", sum(page["KeyCount"] for page in pages), "objetos")

folders = s3.list_objects_v2(Bucket="exportes", Prefix="2026-09-05/", Delimiter="/")
print("'carpetas' de un día:", [p["Prefix"] for p in folders["CommonPrefixes"]][:3], "…")

try:
    s3.head_object(Bucket="exportes", Key="2026-09-05/")
except s3.exceptions.ClientError as e:
    print("¿existe '2026-09-05/' como objeto?", e.response["Error"]["Code"])

fs = s3fs.S3FileSystem(endpoint_url=ENDPOINT, key=KEYS["aws_access_key_id"], secret=KEYS["aws_secret_access_key"])
print("s3fs ls:", fs.ls("exportes/2026-09-05/Suba")[:3], "…")
with fs.open("exportes/2026-09-05/Suba/abonos.csv") as f:
    print("s3fs open:", f.read())
```

```bash
docker run -d --name aurea-s3 -e RUSTFS_ACCESS_KEY=aurea-local -e RUSTFS_SECRET_KEY=aurea-local-secret \
    -p 9000:9000 rustfs/rustfs:1.0.1
AUREA_S3=http://localhost:9000 python3 exportes.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
una llamada: 1000 objetos · IsTruncated: True
con el paginador: 2500 objetos
'carpetas' de un día: ['2026-09-05/Centro/', '2026-09-05/Chapinero/', '2026-09-05/Engativá/'] …
¿existe '2026-09-05/' como objeto? 404
s3fs ls: ['exportes/2026-09-05/Suba/abonos.csv', 'exportes/2026-09-05/Suba/agenda.csv', 'exportes/2026-09-05/Suba/cartera.csv'] …
s3fs open: b'sede,valor\n'
```

**Detalles con intención**

- **`endpoint_url`** es todo lo que cambia entre AWS y un servidor compatible. El resto del código es el mismo para AWS S3, un
  servidor propio o el almacenamiento compatible de otro proveedor de nube.
- **El paginador** de `boto3` hace las llamadas sucesivas con el `ContinuationToken`. Cualquier código que liste objetos lo usa,
  aunque "nunca vaya a haber más de mil": los exportes crecen cada noche.
- **`Delimiter="/"`** hace que el servidor agrupe por el siguiente tramo de la clave y devuelva `CommonPrefixes`: es la forma de
  "ver carpetas". La carpeta en sí no existe, como muestra el `404`.
- **`s3fs`** es lo que permite escribir `pd.read_csv("s3://exportes/…")` o que DuckDB lea `s3://` (`db05`): la misma interfaz de
  archivos, con S3 debajo.

---

## ⚠️ 4. Lo que se rompe

**El bucle sin paginar.** Por todo lo de arriba: procesa mil objetos y termina sin error.

**"Renombrar la carpeta" de un día.** Son cien copias y cien borrados, y si el proceso se corta a la mitad, quedan las dos carpetas a
medias. Las claves se diseñan para no tener que renombrar.

**Listar para buscar.** Encontrar "el exporte de cartera de Suba de cualquier día" listando todo el *bucket* es caro y lento. La
clave se diseña para la consulta (`sede/fecha/…` o `fecha/sede/…`, según cómo se lea), o se lleva un índice en una base.

**Las credenciales en el código.** El ejemplo las tiene porque es un contenedor local. En producción vienen del entorno, de un archivo
de credenciales o de un rol (`se05`).

**`boto3` y `s3fs` en el mismo proyecto.** `s3fs` usa `aiobotocore`, que fija un rango estrecho de `botocore`, y `boto3` exige su
`botocore` exacto. El 05/10/2026, `pip install boto3==1.43.108 s3fs==2026.9.0` falla con `ResolutionImpossible`; sin fijar `boto3`, el
resolvedor baja a 1.43.106, la última que `aiobotocore` 3.9.2 acepta. Con `uv` pasa lo mismo, y el archivo de bloqueo lo deja escrito.
Se fija `s3fs` y se deja que él elija `boto3`, no al revés.

**Depender de MinIO sin mirar.** Un `docker-compose.yml` heredado con `minio/minio:latest` puede dejar de arrancar el día que esa
imagen desaparezca de la caché. Las imágenes se fijan por versión, y se revisa que el proyecto siga vivo.

---

## ⚖️ 5. Cuándo NO usarlo

**Para datos que se consultan por campo.** Un objeto no se consulta por dentro; para eso, una base o Parquet consultado con DuckDB.

**Para archivos que se modifican a cada rato.** Cada cambio reemplaza el objeto entero.

**Un servidor S3 propio, si hay una nube.** Operar almacenamiento propio (discos, replicación, respaldos) es más difícil de lo que
parece; el de un proveedor es barato para el volumen de Áurea.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas cada línea de la salida.
2. Lista solo los exportes de Suba de todos los días. **Criterio:** describes por qué con esta estructura de claves cuesta, y cuántas
   llamadas hiciste.
3. Escribe un CSV con `pandas` directamente en `s3://exportes/prueba.csv`. **Criterio:** `fs.ls` lo muestra.

**🟡 Intermedio (4–6)**

4. Rediseña las claves para que "todos los exportes de Suba" sea un prefijo. **Criterio:** una sola llamada paginada, y qué consulta se
   vuelve cara con el nuevo diseño.
5. Consulta los CSV de un día con DuckDB y `httpfs` contra el servidor local. **Criterio:** una consulta sobre `s3://exportes/2026-09-05/*/abonos.csv`.
6. Genera una URL prefirmada de un reporte que vence en una hora. **Criterio:** se descarga con `curl` sin credenciales, y falla después.

**🟠 Difícil (7–9)**

7. Mide subir 1 000 objetos de a uno y con un `ThreadPoolExecutor` de 16. **Criterio:** la tabla de tiempos.
8. Implementa "renombrar el día" con copia, verificación y borrado, que se pueda retomar si se corta. **Criterio:** cortarlo a la mitad y
   retomarlo deja el *bucket* consistente.
9. Escribe la política de solo lectura para el aliado de imágenes sobre un prefijo. **Criterio:** con sus credenciales lee su prefijo y
   no lista los demás.

**🔴 Muy difícil (10)**

10. Diseña el almacenamiento de archivos de Áurea. **Criterio:** una página. *Rúbrica:* (a) nube o propio, con su costo; (b) el diseño de
    claves para exportes, reportes e imágenes; (c) permisos de cada aliado; (d) respaldo y retención.

---

## 📚 7. Referencias

**Documentación oficial**

- `boto3`, S3: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3.html
- `boto3`, paginadores: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/paginators.html
- `s3fs`: https://s3fs.readthedocs.io/en/latest/
- MinIO, el aviso de fin de mantenimiento: https://github.com/minio/minio
- RustFS: https://github.com/rustfs/rustfs

**Orden de lectura sugerido:** la guía de paginadores de `boto3` (corta, y es la trampa); después `s3fs` para integrar con pandas y
DuckDB.

---

## 🚀 8. Cierre

S3 se habla desde Python con `boto3` o como sistema de archivos con `s3fs`, y el código es el mismo contra AWS o un servidor compatible.
No hay directorios: hay claves con barras y prefijos. Toda lista se pagina, porque una llamada devuelve mil. Y el servidor local de todos
los tutoriales, MinIO, ya no se mantiene en abierto: las imágenes se fijan y se revisa que el proyecto siga vivo.

**La señal de que quedó bien:** *"El proceso que limpia los exportes viejos recorre los 2 500 de septiembre, no los primeros mil."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-db-fase-13 -m "op db13 cerrada: claves con barras, el paginador y s3fs, contra un S3 compatible"
> ```
>
> Los commits llevan su prefijo (`op db13: …`) y los de ejercicio su número
> (`op db13 ej07: …`).
