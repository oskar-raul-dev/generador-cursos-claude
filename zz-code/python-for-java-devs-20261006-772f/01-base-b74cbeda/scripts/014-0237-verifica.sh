# rescatado de la sesión b74cbeda, 2026-09-13T02:37:17Z · Verify the return-in-except-star error
cd /tmp/claude-501/f08 && /opt/homebrew/bin/python3.14 -c "
src = '''
def f():
    try:
        pass
    except* ValueError as g:
        return 1
'''
try:
    compile(src, '<test>', 'exec')
    print('compila')
except SyntaxError as e:
    print('SyntaxError:', e.msg)
" && echo "--- ¿y el acceso a los atributos del subgrupo? ---" && /opt/homebrew/bin/python3.14 -c "
class E(Exception):
    def __init__(s, n): s.n=n; super().__init__(str(n))
try:
    raise ExceptionGroup('x', [E(1), E(2)])
except* E as g:
    print('tipo de g:', type(g).__name__)
    print('g.exceptions:', [type(e).__name__ for e in g.exceptions])
    print('acceso directo g.n:', getattr(g, 'n', 'NO EXISTE'))
"
