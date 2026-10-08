# rescatado de la sesión b74cbeda, 2026-09-13T02:25:30Z · Count each outcome class in the invoice set
cd /tmp/claude-501/f05 && /opt/homebrew/bin/python3.14 -c "
from pathlib import Path
from collections import Counter
c=Counter()
for p in sorted(Path('facturas').glob('fac-????.xml')):
    nit=''.join(ch for ch in p.read_text() if ch.isdigit())[:9]
    d=nit[-1]
    c['cuelga (7)' if d=='7' else 'falla cert (3)' if d=='3' else 'advertencia (5)' if d=='5' else 'ok']+=1
print(dict(c), 'total', sum(c.values()))"
