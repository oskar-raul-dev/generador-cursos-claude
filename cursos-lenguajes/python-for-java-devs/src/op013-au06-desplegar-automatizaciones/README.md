# au06 — Desplegar automatizaciones

Código de la sección [`op013-au06-desplegar-automatizaciones.md`](../../op013-au06-desplegar-automatizaciones.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

> ⚠️ **La sección se probó en parte**: su encabezado dice qué quedó sin correr y por qué.

| Archivo | Qué es |
|---|---|
| `revisar_circulares.py` | script |
| `etc/systemd/system/aurea-circulares.service` | Unidad de systemd |
| `etc/systemd/system/aurea-circulares.timer` | Temporizador de systemd |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
PORTAL_TOKEN=prueba uv run --script revisar_circulares.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
