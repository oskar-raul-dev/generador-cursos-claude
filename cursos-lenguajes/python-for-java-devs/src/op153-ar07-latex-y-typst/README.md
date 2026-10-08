# ar07 — LaTeX y Typst

Código de la sección [`op153-ar07-latex-y-typst.md`](../../op153-ar07-latex-y-typst.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `informe.typ` | Los datos llegan como JSON por sys.inputs: no se interpola texto, no hay nada que escapar |
| `documentos.py` | El mismo informe con Typst (en el proceso) y con LaTeX (el binario), y el carácter que rompe la plantilla |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
apt-get install --no-install-recommends texlive-latex-base texlive-fonts-recommended   # 38 s en el contenedor
pip install typst
python3 documentos.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
