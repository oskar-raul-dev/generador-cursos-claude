# rescatado de la sesión 5c52573d, 2026-10-05T21:18:21Z · Test unzip on a zstd zip
timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /tmp python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y unzip >/dev/null 2>&1; python -c "
import zipfile
with zipfile.ZipFile(\"z.zip\",\"w\",compression=zipfile.ZIP_ZSTANDARD) as z: z.writestr(\"a.txt\",\"hola \"*1000)"; unzip -o z.zip 2>&1 | tail -2; echo "salida: $?"'
