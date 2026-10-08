# rescatado de la sesión 5c52573d, 2026-10-05T17:10:31Z · Check py-spy support for Python 3.14
docker run --rm --label curso=python-for-java-devs --cap-add SYS_PTRACE python:3.14.7 sh -c "pip install -q --root-user-action=ignore py-spy==0.4.2 memray==1.20.0 >/dev/null 2>&1; python -c 'import time
def hot():
    s=0
    for i in range(10**9): s+=i*i
hot()' & sleep 2; py-spy dump --pid \$! 2>&1 | head -8; py-spy --version; python -m memray --version 2>&1 | head -1"
