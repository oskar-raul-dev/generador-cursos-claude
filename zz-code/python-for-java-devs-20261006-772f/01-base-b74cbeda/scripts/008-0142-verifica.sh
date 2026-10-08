# rescatado de la sesión b74cbeda, 2026-09-13T01:42:37Z · Measure PEP 723 cold
cd /tmp/claude-501/f07 && rm -rf /tmp/claude-501/cache-pep723 && UV_CACHE_DIR=/tmp/claude-501/cache-pep723 /opt/homebrew/bin/python3.14 -c "
import subprocess,time,os
env=dict(os.environ)
t0=time.perf_counter()
r=subprocess.run(['/tmp/claude-501/mgr/.tool-uv/bin/uv','run','cierre.py'],capture_output=True,text=True,env=env)
print(f'uv run con caché FRIA: {(time.perf_counter()-t0):.1f}s ->', r.stdout.strip())
"; du -sh /tmp/claude-501/cache-pep723
