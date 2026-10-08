# db10 — Series de tiempo: TimescaleDB e InfluxDB

Código de la sección [`op086-db10-series-de-tiempo.md`](../../op086-db10-series-de-tiempo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `espera.py` | La misma semana de mediciones en TimescaleDB y en InfluxDB 3, y el promedio diario en las dos |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add "psycopg[binary]" influxdb3-python

docker run -d --name aurea-tsdb -e POSTGRES_PASSWORD=aurea-local -p 5432:5432 timescale/timescaledb:2.30.1-pg18
docker run -d --name aurea-influx -p 8181:8181 influxdb:3.12.0-core \
    influxdb3 serve --node-id aurea --object-store memory --without-auth
AUREA_TSDB="host=localhost dbname=postgres user=postgres password=aurea-local" \
AUREA_INFLUX=http://localhost:8181 python3 espera.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
