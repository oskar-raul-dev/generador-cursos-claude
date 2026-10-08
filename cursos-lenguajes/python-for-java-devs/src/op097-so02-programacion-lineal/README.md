# so02 — Programación lineal y entera

Código de la sección [`op097-so02-programacion-lineal.md`](../../op097-so02-programacion-lineal.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `mezcla_chapinero.py` | La mezcla semanal de Chapinero: lineal (con precios sombra) y entera (la que se agenda) |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add pulp highspy

python3 mezcla_chapinero.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
