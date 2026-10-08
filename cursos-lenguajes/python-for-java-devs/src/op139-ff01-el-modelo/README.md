# ff01 — El modelo: GIL y módulos de extensión

Código de la sección [`op139-ff01-el-modelo.md`](../../op139-ff01-el-modelo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `frontera.py` | Dónde está la frontera con C: qué ya es nativo, cuánto cuesta el bucle, y quién suelta el GIL |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pip install numpy
python3 frontera.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
