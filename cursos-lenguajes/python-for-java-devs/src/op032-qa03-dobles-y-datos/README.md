# qa03 — Dobles y datos de prueba

Código de la sección [`op032-qa03-dobles-y-datos.md`](../../op032-qa03-dobles-y-datos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `glosas.py` | Glosas notificadas por la prepagada, y cuáles vencen esta semana |
| `test_glosas.py` | La red simulada con respx, el reloj con time-machine, y datos que se parecen a los reales |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add httpx pydantic
uv add --dev pytest respx time-machine polyfactory faker

pytest -q -s test_glosas.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
