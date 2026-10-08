# sy07 — Sincronización y respaldo

Código de la sección [`op121-sy07-sincronizacion-y-respaldo.md`](../../op121-sy07-sincronizacion-y-respaldo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `respaldo.py` | Instantáneas con rsync, manifiesto calculado del origen, la copia que no copió, y el daño compartido por enlaces duros |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 respaldo.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
