# rescatado de la sesión 2859734a, 2026-09-13T20:17:58Z · Measure real memory of a million ints
import sys
xs=list(range(1_000_000))
print("objetos:", sum(sys.getsizeof(x) for x in xs)/1e6, "MB · un int:", sys.getsizeof(10**6))
