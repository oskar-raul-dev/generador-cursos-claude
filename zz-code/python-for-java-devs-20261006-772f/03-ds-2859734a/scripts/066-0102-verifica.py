# rescatado de la sesión 2859734a, 2026-09-14T01:02:57Z · Check the brand palette contrast figures
from palette import *
print("color      contraste  texto  barra   gris")
for name,(ratio,text,large) in check_palette().items():
    print(f"{name:<10} {ratio:>8.2f}  {'sí' if text else 'NO':<6}{'sí' if large else 'NO':<7}{to_grayscale(BRAND[name])}")
print("\nlegibles para texto:", readable_colors())
print("¿se distinguen impresos los cinco?", distinguishable_in_print(list(BRAND.values())))
sub=[BRAND[n] for n in ("carbon","teja","pizarra")]
print("¿y los tres oscuros?", distinguishable_in_print(sub))
