# rescatado de la sesión 5c52573d, 2026-10-05T17:13:48Z · Run ob06 without before_send properly
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ob06; docker run --rm --label curso=python-for-java-devs -v $PWD:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore sentry-sdk==2.71.0 >/dev/null 2>&1; python -c \"
import runpy, io, contextlib
with contextlib.redirect_stdout(io.StringIO()):
    g = runpy.run_path('sin.py', run_name='__main__')
ex = g['SENT'][0]['exception']['values'][0]
print('mensaje:', ex['value'])
print('vars del marco de book:', [f['vars'] for f in ex['stacktrace']['frames'] if f.get('function') == 'book'])
\""
