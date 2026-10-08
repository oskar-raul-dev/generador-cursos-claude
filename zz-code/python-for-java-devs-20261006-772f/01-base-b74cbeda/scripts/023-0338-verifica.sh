# rescatado de la sesión b74cbeda, 2026-09-13T03:38:46Z · Stop services and check markdown balance
export PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH; pg_ctl -D /tmp/claude-501/pgdata stop >/dev/null 2>&1; pkill -f socio_falible; pkill -f uvicorn; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "Veredicto. El registro estructurado" 16-operacion-y-rendimiento.md && python3 -c "
import re,pathlib
for f in sorted(pathlib.Path('.').glob('1[3-6]-*.md')):
    s=f.read_text()
    # asteriscos dobles desbalanceados por línea
    malas=[i+1 for i,l in enumerate(s.splitlines()) if l.count('**')%2]
    print(f.name, '· líneas con ** impar:', malas[:6] if malas else 'ninguna')"
