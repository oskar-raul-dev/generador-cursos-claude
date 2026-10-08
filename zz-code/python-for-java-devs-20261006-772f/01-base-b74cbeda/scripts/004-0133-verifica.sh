# rescatado de la sesión b74cbeda, 2026-09-13T01:33:02Z · Measure true first import cost
cd /tmp/claude-501/mgr && rm -rf .venv-uv3 && UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv ./.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv-uv3 && UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv ./.tool-uv/bin/uv pip sync -q --python .venv-uv3/bin/python reqs-uv.txt && /opt/homebrew/bin/python3.14 -c "
import subprocess,time
for i in range(3):
    t0=time.perf_counter(); subprocess.run(['.venv-uv3/bin/python','-c','import fastapi, sqlalchemy'],capture_output=True)
    print(f'uv   import #{i+1}: {(time.perf_counter()-t0)*1000:.0f} ms')
for i in range(2):
    t0=time.perf_counter(); subprocess.run(['.venv-pip/bin/python','-c','import fastapi, sqlalchemy'],capture_output=True)
    print(f'pip  import #{i+1}: {(time.perf_counter()-t0)*1000:.0f} ms')
"
