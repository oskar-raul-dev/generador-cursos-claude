# pr04 — GraphQL desde Python

Código de la sección [`op126-pr04-graphql.md`](../../op126-pr04-graphql.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `portal.py` | El portal de franquiciados en GraphQL con Strawberry: el N+1 contado, y el DataLoader que lo corrige |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add strawberry-graphql

python3 portal.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
