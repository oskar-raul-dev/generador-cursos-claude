# wf08 — Veredicto: el cierre nocturno en cuatro orquestadores

Código de la sección [`op029-wf08-veredicto.md`](../../op029-wf08-veredicto.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

> ⚠️ **La sección se probó en parte**: su encabezado dice qué quedó sin correr y por qué.

| Archivo | Qué es |
|---|---|
| `memoria_en_reposo.py` | Memoria en reposo de un escalón: RSS de sus procesos y memoria de sus contenedores |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 memoria_en_reposo.py celery "celery -A noche" escalon=celery
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
