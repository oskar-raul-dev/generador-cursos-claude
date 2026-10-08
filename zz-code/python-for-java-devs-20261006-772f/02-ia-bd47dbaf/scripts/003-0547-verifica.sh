# rescatado de la sesión bd47dbaf, 2026-09-13T05:47:32Z · Sanity check pricing arithmetic
python3 -c "
from pricing import CATALOG
p = CATALOG['claude-opus-5']
c = p.cost_of(24, 180)
print('opus  24/180 ->', c, f'{c:.6f}')
h = CATALOG['claude-haiku-4-5'].cost_of(24,180)
print('haiku 24/180 ->', f'{h:.6f}', ' ratio', float(c/h))
"
