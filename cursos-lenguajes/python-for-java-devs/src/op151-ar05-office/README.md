# ar05 — Office: Word, Excel y PowerPoint

Código de la sección [`op151-ar05-office.md`](../../op151-ar05-office.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `office.py` | Office desde Python: Excel con dos bibliotecas, la fórmula que nadie calculó, Word con plantilla y una diapositiva |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pip install openpyxl XlsxWriter python-docx python-pptx
python3 office.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
