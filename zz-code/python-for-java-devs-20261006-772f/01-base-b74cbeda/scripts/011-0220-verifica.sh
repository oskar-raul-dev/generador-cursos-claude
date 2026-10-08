# rescatado de la sesión b74cbeda, 2026-09-13T02:20:40Z · Verify the simulator's three odd behaviours
cd /tmp/claude-501/f05 && /opt/homebrew/bin/python3.14 - <<'EOF'
import subprocess, sys, time
from pathlib import Path
PY = sys.executable
# busca una factura que cuelgue (NIT terminado en 7) y una con certificado vencido (en 3)
casos = {}
for p in sorted(Path("facturas").glob("fac-????.xml")):
    nit = "".join(c for c in p.read_text() if c.isdigit())[:9]
    casos.setdefault(nit[-1], p)
for d in ("7", "3", "5"):
    p = casos.get(d)
    if not p: continue
    t0=time.perf_counter()
    try:
        r = subprocess.run([PY, "firmador_simulado.py", "--entrada", str(p), "--salida", "/tmp/o.xml"],
                           capture_output=True, text=True, timeout=2)
        print(f"NIT...{d}: código={r.returncode} stdout={r.stdout.strip()!r} stderr={r.stderr.strip()!r}")
    except subprocess.TimeoutExpired:
        print(f"NIT...{d}: TIMEOUT a los {time.perf_counter()-t0:.1f}s (el proceso se colgó)")
EOF
