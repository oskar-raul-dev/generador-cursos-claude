# rescatado de la sesión b74cbeda, 2026-09-13T01:32:46Z · Compare bytecode and import cost
cd /tmp/claude-501/mgr && for e in .venv-pip .venv-uv; do echo -n "$e: pyc=$(find $e -name '*.pyc' | wc -l | tr -d ' ')  "; echo -n "pip presente=$(test -e $e/bin/pip && echo sí || echo no)  "; du -sh $e | cut -f1; done && echo "--- primer import de fastapi (proceso nuevo, tras crear el entorno) ---" && for e in .venv-pip .venv-uv; do echo -n "$e: "; /opt/homebrew/bin/python3.14 -c "
import subprocess,time,statistics
xs=[]
for _ in range(5):
    t0=time.perf_counter(); subprocess.run(['$e/bin/python','-c','import fastapi, sqlalchemy'],capture_output=True); xs.append((time.perf_counter()-t0)*1000)
xs.sort(); print(f'mediana {statistics.median(xs):.0f} ms')"; done
