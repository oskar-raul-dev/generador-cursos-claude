exec(open("respaldo.py").read().split("one_day =")[0])
import hashlib
for name in ("exporte-03.csv", "exporte-07.csv", "exporte-50.csv", "exporte-20.csv"):
    s = hashlib.sha256((SRC / name).read_bytes()).hexdigest()[:8]
    b = hashlib.sha256((BACKUPS / "2026-10-05" / name).read_bytes()).hexdigest()[:8]
    print(name, "origen", s, "respaldo", b, "igual" if s == b else "DISTINTO")
