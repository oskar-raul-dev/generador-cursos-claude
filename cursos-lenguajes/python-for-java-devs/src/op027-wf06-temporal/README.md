# wf06 — Temporal: flujos durables

Código de la sección [`op027-wf06-temporal.md`](../../op027-wf06-temporal.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `aprobacion.py` | La aprobación trimestral de la liquidación de un franquiciado, como flujo durable |
| `prueba_aprobacion.py` | Dos trimestres: uno en que Édgar aprueba enseguida y otro en que no responde nunca |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add temporalio

python3 prueba_aprobacion.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
