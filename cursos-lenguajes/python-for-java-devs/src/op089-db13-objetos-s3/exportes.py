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
