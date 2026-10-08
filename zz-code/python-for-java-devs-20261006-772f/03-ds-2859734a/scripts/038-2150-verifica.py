# rescatado de la sesión 2859734a, 2026-09-13T21:50:33Z · Count the shared SQL helper in the LOC column
import bench_engines as b
for e in b.ENGINES: print(f"{e:18s} {b.effective_lines(e):>3} líneas")
