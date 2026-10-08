# db13 — Objetos: S3, y la MinIO que ya no está

Código de la sección [`op089-db13-objetos-s3.md`](../../op089-db13-objetos-s3.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `exportes.py` | S3 desde Python: claves con barras, la lista de a mil, el paginador y s3fs |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add boto3 s3fs

docker run -d --name aurea-s3 -e RUSTFS_ACCESS_KEY=aurea-local -e RUSTFS_SECRET_KEY=aurea-local-secret \
    -p 9000:9000 rustfs/rustfs:1.0.1
AUREA_S3=http://localhost:9000 python3 exportes.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
