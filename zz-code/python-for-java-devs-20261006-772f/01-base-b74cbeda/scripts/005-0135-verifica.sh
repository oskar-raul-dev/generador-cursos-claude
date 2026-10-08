# rescatado de la sesión b74cbeda, 2026-09-13T01:35:05Z · Measure uv installing an interpreter
cd /tmp/claude-501/mgr && rm -rf uvpy && UV_PYTHON_INSTALL_DIR=/tmp/claude-501/mgr/uvpy UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv2 /opt/homebrew/bin/python3.14 -c "
import subprocess,time,os
env=dict(os.environ)
t0=time.perf_counter()
r=subprocess.run(['./.tool-uv/bin/uv','python','install','3.14.7'],capture_output=True,text=True,env=env)
print(f'uv python install 3.14.7: {(time.perf_counter()-t0):.1f} s exit={r.returncode}')
print((r.stderr or r.stdout)[-300:])
"; du -sh uvpy 2>/dev/null; ls uvpy 2>/dev/null
