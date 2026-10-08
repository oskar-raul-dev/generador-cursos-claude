# rescatado de la sesión b74cbeda, 2026-09-13T01:43:47Z · Measure onedir frozen build
cd /tmp/claude-501/f07 && /opt/homebrew/bin/python3.14 -c "
import subprocess,time,pathlib,statistics
t0=time.perf_counter()
r=subprocess.run(['.venv/bin/pyinstaller','--onedir','--name','aurdir','--paths','src','--clean','-y',
                  '--specpath','build-spec','--distpath','dist-dir','--workpath','build-work2',
                  'src/aur/__main__entry.py'],capture_output=True,text=True)
print(f'build onedir: {(time.perf_counter()-t0):.1f}s exit={r.returncode}')
p=pathlib.Path('dist-dir/aurdir/aurdir')
total=sum(f.stat().st_size for f in pathlib.Path('dist-dir/aurdir').rglob('*') if f.is_file())
print(f'tamaño carpeta: {total/1e6:.1f} MB · archivos: {sum(1 for _ in pathlib.Path(\"dist-dir/aurdir\").rglob(\"*\") if _.is_file())}')
xs=[]
for _ in range(10):
    t1=time.perf_counter(); subprocess.run([str(p),'--version'],capture_output=True); xs.append((time.perf_counter()-t1)*1000)
xs.sort(); print(f'arranque onedir: mediana {statistics.median(xs):.0f} ms')
"
