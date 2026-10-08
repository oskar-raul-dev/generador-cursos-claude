# rescatado de la sesión bd47dbaf, 2026-09-13T18:49:22Z · Verify the float drift claim
python3 -c "
s=0.0
for _ in range(10_000): s += 0.003
print('float:', repr(s), '| == 30.0?', s==30.0)
from decimal import Decimal
d=Decimal(0)
for _ in range(10_000): d += Decimal('0.003')
print('Decimal:', d)
"
