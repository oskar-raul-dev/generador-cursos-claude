# co03 — Correo entrante

Código de la sección [`op017-co03-correo-entrante.md`](../../op017-co03-correo-entrante.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `buzon_cartera.py` | Procesa el buzón de cartera: adjuntos de aseguradoras conocidas, guardados con nombres seguros |
| `prueba_buzon.py` | Mensajes de prueba hostiles contra extract() |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add imap-tools

python3 prueba_buzon.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
