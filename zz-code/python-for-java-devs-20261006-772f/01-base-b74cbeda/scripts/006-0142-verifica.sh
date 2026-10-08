# rescatado de la sesión b74cbeda, 2026-09-13T01:42:07Z · Measure uv tool install
cd /tmp/claude-501/f07 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && export PATH=/tmp/claude-501/mgr/.tool-uv/bin:$PATH
echo "=== 1. uv tool install (aislado) ==="
rm -rf /tmp/claude-501/uvtools
UV_TOOL_DIR=/tmp/claude-501/uvtools UV_TOOL_BIN_DIR=/tmp/claude-501/uvbin /opt/homebrew/bin/python3.14 -c "
import subprocess,time,os
t0=time.perf_counter()
r=subprocess.run(['uv','tool','install','--python','/opt/homebrew/bin/python3.14','.'],capture_output=True,text=True,env=dict(os.environ))
print(f'uv tool install: {(time.perf_counter()-t0):.1f}s exit={r.returncode}'); print((r.stderr or '')[-400:])
"
du -sh /tmp/claude-501/uvtools 2>/dev/null; ls /tmp/claude-501/uvbin 2>/dev/null
echo "=== arranque ==="
/opt/homebrew/bin/python3.14 -c "
import subprocess,time,statistics
xs=[]
for _ in range(10):
    t0=time.perf_counter(); subprocess.run(['/tmp/claude-501/uvbin/aur','--version'],capture_output=True); xs.append((time.perf_counter()-t0)*1000)
xs.sort(); print(f'mediana {statistics.median(xs):.0f} ms  p95 {xs[8]:.0f} ms')"
