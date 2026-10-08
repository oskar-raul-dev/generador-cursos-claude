# ob07 — Veredicto: el presupuesto de observabilidad

Código de la sección [`op046-ob07-veredicto.md`](../../op046-ob07-veredicto.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `resumen_diario.py` | El resumen de las 7:00: qué corrió, qué falló y qué se está degradando, en un mensaje |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 resumen_diario.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
