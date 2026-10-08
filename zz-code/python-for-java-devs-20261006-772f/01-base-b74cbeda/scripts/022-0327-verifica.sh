# rescatado de la sesión b74cbeda, 2026-09-13T03:27:24Z · Verify the batch can import the CLI as a library
cd /tmp/claude-501/f07 && ./.venv/bin/python -c "
from aur.summary import summarize
from aur.reading import read_rows
from pathlib import Path
s = summarize(read_rows(Path('data/centro-2026-03.csv')))
print('el batch importa el CLI como biblioteca:')
print(f\"  procedimientos {s['procedimientos']} · pacientes {s['pacientes']} · total \${s['total']:,.0f}\")
import aur; print('  aur', aur.__version__, 'desde', aur.__file__)
"
