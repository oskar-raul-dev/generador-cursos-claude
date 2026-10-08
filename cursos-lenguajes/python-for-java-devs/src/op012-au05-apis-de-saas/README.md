# au05 — APIs de SaaS y su OAuth

Código de la sección [`op012-au05-apis-de-saas.md`](../../op012-au05-apis-de-saas.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `agenda_franquicia.py` | Lee la agenda de Google Calendar de un franquiciado con OAuth 2.0 y renovación automática |
| `prueba_agenda.py` | Prueba la renovación y la paginación contra un Google simulado |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add authlib httpx keyring

python3 prueba_agenda.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
