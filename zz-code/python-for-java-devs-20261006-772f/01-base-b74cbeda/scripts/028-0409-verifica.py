# rescatado de la sesión b74cbeda, 2026-09-13T04:09:37Z · Measure the course volume to derive the bands
import pathlib, re
bloques = {"A": ["00-ambiente","01-modelo","02-secuencias","03-python","04-errores","05-shell","06-formatos"],
           "B": ["07-cuando","08-el-contrato","09-distribucion"],
           "C": ["10-fastapi","11-persistencia","12-django","13-integraciones","14-concurrencia","15-el-proceso","16-operacion","17-el-duelo"]}
total_pal = 0
for b, pre in bloques.items():
    pal = ej = 0
    for p in pre:
        f = next(pathlib.Path(".").glob(f"{p}*.md"))
        t = f.read_text()
        pal += len(t.split())
        m = re.search(r"## 🧪 8\. Ejercicios \((\d+)\)", t)
        ej += int(m.group(1)) if m else 0
    total_pal += pal
    print(f"Bloque {b}: {len(pre)} fases · {pal:,} palabras · {ej} ejercicios · lectura ≈ {pal/200/60:.1f} h")
print(f"\nTOTAL: {total_pal:,} palabras · lectura ≈ {total_pal/200/60:.1f} h a 200 palabras/minuto")
