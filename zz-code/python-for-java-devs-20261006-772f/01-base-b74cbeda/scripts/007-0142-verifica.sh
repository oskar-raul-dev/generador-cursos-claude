# rescatado de la sesión b74cbeda, 2026-09-13T01:42:20Z · Build and measure zipapp
cd /tmp/claude-501/f07 && echo "=== 2. zipapp ===" && rm -rf build-pyz && mkdir build-pyz && cp -r src/aur build-pyz/ && /opt/homebrew/bin/python3.14 -c "
import zipapp, time, pathlib
t0=time.perf_counter()
zipapp.create_archive('build-pyz', target='aur.pyz', main='aur.cli:main', interpreter='/usr/bin/env python3')
print(f'zipapp build: {(time.perf_counter()-t0)*1000:.0f} ms  tamaño: {pathlib.Path(\"aur.pyz\").stat().st_size/1024:.0f} KB')
import subprocess, statistics
xs=[]
for _ in range(10):
    t1=time.perf_counter(); subprocess.run(['/opt/homebrew/bin/python3.14','aur.pyz','--version'],capture_output=True); xs.append((time.perf_counter()-t1)*1000)
xs.sort(); print(f'arranque: mediana {statistics.median(xs):.0f} ms')
r=subprocess.run(['/opt/homebrew/bin/python3.14','aur.pyz','--version'],capture_output=True,text=True); print('salida:', r.stdout.strip() or r.stderr.strip()[:200])
"
