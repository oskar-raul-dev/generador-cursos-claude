# rescatado de la sesión 5c52573d, 2026-10-05T21:12:29Z · Show full numpy subinterpreter error
timeout 300 docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore numpy==2.5.3 >/dev/null 2>&1; python -c "
from concurrent import interpreters
i = interpreters.create()
try: i.exec(\"import numpy\")
except interpreters.ExecutionFailed as e: print(e.excinfo.msg)
i.close()"'
