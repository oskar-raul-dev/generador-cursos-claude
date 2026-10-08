# rescatado de la sesión 5c52573d, 2026-10-05T19:09:46Z · Inspect PuLP 4 variable API
import pulp, re, pathlib
root = pathlib.Path(pulp.__file__).parent
for f in root.glob(\"*.md\"): print(f)
