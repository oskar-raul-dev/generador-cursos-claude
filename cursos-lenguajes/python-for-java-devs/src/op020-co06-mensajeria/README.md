# co06 — Mensajería y notificaciones

Código de la sección [`op020-co06-mensajeria.md`](../../op020-co06-mensajeria.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `notificar.py` | Un notificador con dos canales: Slack para el equipo, WhatsApp (Twilio) para pacientes |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add httpx

python3 notificar.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
