# lg04 — EDI: X12 y EDIFACT

Código de la sección [`op004-lg04-edi.md`](../../op004-lg04-edi.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `edi.py` | Tokenizador de X12 y EDIFACT: descubre los delimitadores y devuelve segmentos |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 edi.py

uv add pyx12
x12valid reclamacion.837
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
