# ar04 — PDF

Código de la sección [`op150-ar04-pdf.md`](../../op150-ar04-pdf.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `pdfs.py` | Un PDF de muestra: generarlo, extraer su texto y su tabla con tres bibliotecas, firmarlo y leerlo con OCR |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
apt-get install tesseract-ocr tesseract-ocr-spa    # el motor de OCR y el idioma español; en el contenedor, Tesseract 5.5.0
pip install reportlab pypdf pdfplumber PyMuPDF pyhanko pytesseract Pillow
python3 pdfs.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
