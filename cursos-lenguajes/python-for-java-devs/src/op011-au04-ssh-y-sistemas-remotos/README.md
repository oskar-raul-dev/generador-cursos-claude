# au04 — SSH y sistemas remotos

Código de la sección [`op011-au04-ssh-y-sistemas-remotos.md`](../../op011-au04-ssh-y-sistemas-remotos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `compose.yaml` | Configuración del ejemplo |
| `revisar_respaldos.py` | Revisa por SSH el último respaldo de Odontovía en cada sede y el espacio libre del disco |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add paramiko fabric

ssh-keygen -t ed25519 -N "" -f revisor -C "revisor de respaldos" && cp revisor.pub sede/
docker compose up -d --build
# Un respaldo reciente en Centro y uno de hace cuatro meses en Suba.
docker compose exec sede-centro sh -c 'head -c 2000000 /dev/urandom > /respaldos/odontovia.sql.gz'
docker compose exec sede-suba sh -c 'head -c 900000 /dev/urandom > /respaldos/odontovia.sql.gz && touch -d "120 days ago" /respaldos/odontovia.sql.gz'
# Las claves de host se registran una vez, aquí, y se revisan.
ssh-keyscan -p 2201 -t ed25519 127.0.0.1 > known_hosts
ssh-keyscan -p 2202 -t ed25519 127.0.0.1 >> known_hosts

python3 revisar_respaldos.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
