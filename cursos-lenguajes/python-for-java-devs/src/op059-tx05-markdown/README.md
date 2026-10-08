# tx05 — Markdown y su ecosistema

Código de la sección [`op059-tx05-markdown.md`](../../op059-tx05-markdown.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `procedimiento.py` | El mismo procedimiento en tres bibliotecas de Markdown, y su índice sacado del árbol |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add markdown-it-py mistune markdown

python3 procedimiento.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
