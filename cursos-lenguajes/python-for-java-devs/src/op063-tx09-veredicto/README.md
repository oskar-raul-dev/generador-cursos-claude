# tx09 — Veredicto: plantilla o lenguaje mal hecho

Código de la sección [`op063-tx09-veredicto.md`](../../op063-tx09-veredicto.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `densidad.py` | ¿Plantilla o programa? Cuenta la lógica de cada plantilla con el analizador léxico de Jinja2 |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add jinja2

python3 densidad.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
