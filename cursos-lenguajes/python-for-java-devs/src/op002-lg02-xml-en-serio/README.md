# lg02 — XML en serio

Código de la sección [`op002-lg02-xml-en-serio.md`](../../op002-lg02-xml-en-serio.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `factura.xml` | Archivo de datos del ejemplo |
| `factura_xml.py` | Lee, valida y transforma la factura UBL con lxml, con un parser que no confía en nadie |
| `factura-minima.xsd` | El esquema XSD del ejemplo |
| `bomba.xml` | Archivo de datos del ejemplo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add lxml

python3 factura_xml.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
