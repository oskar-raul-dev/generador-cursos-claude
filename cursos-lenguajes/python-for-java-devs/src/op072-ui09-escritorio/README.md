# ui09 — Escritorio

Código de la sección [`op072-ui09-escritorio.md`](../../op072-ui09-escritorio.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `mora_tk.py` | La calculadora de mora en Tkinter: la ventana, y una prueba que la opera sin manos |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 mora_tk.py          # en un servidor sin pantalla: xvfb-run -a python3 mora_tk.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
