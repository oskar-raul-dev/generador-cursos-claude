# ui12 — TUI completas con Textual

Código de la sección [`op075-ui12-textual.md`](../../op075-ui12-textual.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `cierre_tui.py` | La consola del cierre: las sedes en una tabla, y 'r' reprocesa la elegida |
| `prueba_tui.py` | Opera la TUI sin terminal: baja dos filas, aprieta 'r' y lee la tabla |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add textual

python3 prueba_tui.py
python3 cierre_tui.py          # la aplicación, en tu terminal
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
