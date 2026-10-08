# ar06 — Markdown, HTML y pandoc

Código de la sección [`op152-ar06-markdown-html-y-pandoc.md`](../../op152-ar06-markdown-html-y-pandoc.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `conversion.py` | pandoc orquestado desde Python: costo por llamada, lo que se pierde en el viaje y el HTML que deja pasar |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
apt-get install pandoc          # el de Debian: 3.1.11.1; la última publicada es la 3.12
pip install pypandoc markdown-it-py
python3 conversion.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
