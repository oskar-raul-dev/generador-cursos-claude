# ui11 — rich e interacción en terminal

Código de la sección [`op074-ui11-rich-e-interaccion.md`](../../op074-ui11-rich-e-interaccion.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `reproceso.py` | Tabla, pregunta y progreso con rich, moderados solos cuando la salida no es una terminal |
| `comparar_salidas.py` | La misma herramienta, para el cron y para una persona: cuántos códigos de escape escribe cada vez |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add rich

python3 comparar_salidas.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
