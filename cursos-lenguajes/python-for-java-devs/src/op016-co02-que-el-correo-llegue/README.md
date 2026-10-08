# co02 — Que el correo llegue

Código de la sección [`op016-co02-que-el-correo-llegue.md`](../../op016-co02-que-el-correo-llegue.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `diagnostico_correo.py` | Diagnóstico de entrega: SPF y DMARC de un dominio, y una firma DKIM firmada y verificada |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add dnspython dkimpy

python3 diagnostico_correo.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
