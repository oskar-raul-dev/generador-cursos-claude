# ar03 — OpenCV, scikit-image y SVG

Código de la sección [`op149-ar03-opencv-y-svg.md`](../../op149-ar03-opencv-y-svg.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `imagenes.py` | OpenCV contra scikit-image con el mismo trabajo, el BGR de OpenCV, y una insignia en SVG y en cairo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
apt-get install libcairo2-dev pkg-config        # pycairo no publica ruedas para Linux: compila contra el cairo del sistema
pip install opencv-python-headless scikit-image drawsvg pycairo Pillow
python3 imagenes.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
