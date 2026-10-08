# db02 — MySQL y MariaDB

Código de la sección [`op078-db02-mysql-y-mariadb.md`](../../op078-db02-mysql-y-mariadb.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `trampas.py` | Las tres trampas de MySQL y MariaDB para quien viene de Postgres, contra los dos motores |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add pymysql

docker run -d --name aurea-mysql -e MYSQL_ROOT_PASSWORD=aurea-local -p 3306:3306 mysql:9.7.2
AUREA_MYSQL=127.0.0.1 python3 trampas.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
