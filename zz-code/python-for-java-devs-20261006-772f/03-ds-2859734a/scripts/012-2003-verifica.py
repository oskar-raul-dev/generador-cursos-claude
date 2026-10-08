# rescatado de la sesión 2859734a, 2026-09-13T20:03:24Z · Scale to network volume and verify
from datetime import date
p="/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus/citas_historicas.csv"
rows=open(p).read().splitlines()[1:]
n=len(rows); print(f"{n/27:.0f} citas/mes")
