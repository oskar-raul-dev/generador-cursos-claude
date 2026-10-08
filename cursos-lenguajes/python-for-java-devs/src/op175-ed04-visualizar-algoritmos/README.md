# ed04 — Visualizar algoritmos

Código de la sección [`op175-ed04-visualizar-algoritmos.md`](../../op175-ed04-visualizar-algoritmos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `animacion.py` | Visualizar algoritmos con matplotlib: grabar los estados de dos ordenamientos y animarlos; cuánto dura cada historia |
| `escena.py` | Una escena de manim: una lista de cinco números se ordena por burbuja, intercambio por intercambio |
| `render.sh` | Renderiza la escena en calidad baja y resume el resultado |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add matplotlib==3.11.2 Pillow==12.3.0

uv run animacion.py

sudo apt-get install -y libcairo2-dev libpango1.0-dev pkg-config ffmpeg     # en macOS: brew install cairo pango ffmpeg
uv add manim==0.21.0

bash render.sh
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
