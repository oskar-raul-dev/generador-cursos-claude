# cv02 — Detección

Código de la sección [`op165-cv02-deteccion.md`](../../op165-cv02-deteccion.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `pyproject.toml` | Configuración del ejemplo |
| `detectores.py` | Tres detectores de rostros contra la escala y el giro, y un detector de códigos QR que no necesita modelo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
sudo apt-get install -y libegl1 libgles2        # Debian/Ubuntu; en macOS, nada
uv add opencv-contrib-python-headless==5.0.0.93 mediapipe==1.1.0 scikit-image==0.26.0 numpy==2.5.3

uv run detectores.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
