# db03 — SQL Server y Oracle

Código de la sección [`op079-db03-sql-server-y-oracle.md`](../../op079-db03-sql-server-y-oracle.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `aliados.py` | Leer a los aliados: SQL Server con pyodbc y pymssql, Oracle con oracledb thin, y sus trampas |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add pyodbc pymssql oracledb

docker run -d --name aurea-oracle -e ORACLE_PASSWORD=aurea-local -p 1521:1521 gvenzl/oracle-free:23-slim
docker run -d --name aurea-mssql -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD='Aurea-Local-2026!' -p 1433:1433 \
    mcr.microsoft.com/mssql/server:2022-latest
AUREA_MSSQL=localhost AUREA_ORACLE=localhost/FREEPDB1 python3 aliados.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
