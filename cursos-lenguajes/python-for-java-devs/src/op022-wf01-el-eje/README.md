# wf01 — El eje: de cron al flujo durable

Código de la sección [`op022-wf01-el-eje.md`](../../op022-wf01-el-eje.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `noche.py` | La noche de Áurea como grafo: paralelo donde se puede, y nada que dependa de un fallo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 noche.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
