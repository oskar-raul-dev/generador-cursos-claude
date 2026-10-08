# 🏢 db03 — SQL Server y Oracle

> Python para desarrolladores Java senior · **Carta** · Track `db` — Hablarle a cada sistema de
> datos desde Python · sección 3 de 15
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Áurea no usa ni SQL Server ni Oracle. Sus aliados sí: la aseguradora que paga parte de los tratamientos expone su
información de autorizaciones en una réplica de SQL Server, y el operador de facturación electrónica entrega los estados de
las facturas en una vista de Oracle. Para conciliar, el ingeniero de Áurea tiene que leer las dos desde Python.

Este perfil probablemente usó los dos motores desde Java, donde el *driver* es un `.jar` que se pone en el classpath y ya.
En Python la experiencia es distinta en cada uno, y la diferencia está fuera de Python. **Oracle** se volvió fácil:
`oracledb` en modo *thin* habla el protocolo de Oracle en Python puro, sin instalar nada más. **SQL Server** sigue teniendo
la trampa clásica: `pyodbc`, el *driver* más usado, necesita **un *driver* ODBC del sistema operativo** que no viene con
`pip`. Y cada motor trae además su trampa de datos para quien llega de Postgres.

---

## 🧠 2. El modelo

| Motor | *Driver* | Lo que necesita fuera de Python | `paramstyle` |
|---|---|---|---|
| SQL Server | `pyodbc` 5.3.0 | **unixODBC + el *driver* ODBC de Microsoft** (`msodbcsql18`) | `qmark` (`?`) |
| SQL Server | `pymssql` 2.4.2 | Nada: la rueda trae FreeTDS adentro | `pyformat` (`%s`) |
| Oracle | `oracledb` 26.0.1, modo *thin* | **Nada** | `named` (`:sede`) |
| Oracle | `oracledb`, modo *thick* | Oracle Instant Client | `named` |

| La trampa | Dónde | Qué pasa |
|---|---|---|
| `VARCHAR` contra `NVARCHAR` | SQL Server | Un carácter que no está en la página de códigos de la columna se guarda como `?`, sin error |
| La cadena vacía | Oracle | **`''` es `NULL`**: `WHERE campo = ''` no encuentra nada |
| `NUMBER` | Oracle | Llega como `float` por defecto, también los montos |

### Tu instinto de Java dice… y esta vez se equivoca

Con JDBC, el *driver* de SQL Server es `mssql-jdbc`, un `.jar` sin dependencias del sistema, y el instinto espera lo mismo de
`pip install pyodbc`. Pero `pyodbc` es un puente a ODBC, la API de C de Microsoft de los años noventa, y el *driver* de verdad
es una biblioteca del sistema operativo. El `pip install` funciona; el `import` o la conexión fallan en la primera máquina sin
ese *driver*.

---

## 💻 3. El ejemplo que corre

```bash
uv add pyodbc pymssql oracledb
```

`aliados.py`:

```python
"""Leer a los aliados: SQL Server con pyodbc y pymssql, Oracle con oracledb thin, y sus trampas."""

import os
import time
from decimal import Decimal

import oracledb
import pymssql

MSSQL = dict(server=os.environ.get("AUREA_MSSQL", "mssql"), user="sa", password="Aurea-Local-2026!")
ORACLE = dict(user="system", password="aurea-local", dsn=os.environ.get("AUREA_ORACLE", "oracle/FREEPDB1"))


def retry(connect):
    for _ in range(180):                          # los dos tardan en arrancar la primera vez
        try:
            return connect()
        except Exception:
            time.sleep(1)
    raise SystemExit("no respondió")


# ------------------------------------------------- SQL Server: el driver del sistema operativo
try:
    import pyodbc
    print("pyodbc, drivers ODBC instalados:", pyodbc.drivers())
except ImportError as e:
    print("pyodbc no importa:", e)

with retry(lambda: pymssql.connect(**MSSQL)) as conn, conn.cursor() as cur:
    cur.execute("SELECT SERVERPROPERTY('ProductVersion')")
    print("pymssql conectado a SQL Server", cur.fetchone()[0])     # sql_variant: llega como bytes
    cur.execute("CREATE TABLE #nota (v VARCHAR(50), nv NVARCHAR(50))")
    cur.execute("INSERT INTO #nota VALUES (%s, %s)", ("Quedó feliz 😁", "Quedó feliz 😁"))
    cur.execute("SELECT v, nv FROM #nota")
    print("  VARCHAR / NVARCHAR:", cur.fetchone())

# ------------------------------------------------- Oracle: thin, sin Instant Client
with retry(lambda: oracledb.connect(**ORACLE)) as conn, conn.cursor() as cur:
    print("oracledb modo thin:", conn.thin, "· Oracle", conn.version)
    cur.execute("CREATE TABLE abono (sede VARCHAR2(20), nota VARCHAR2(50), valor NUMBER(12, 2))")
    cur.execute("INSERT INTO abono VALUES (:sede, :nota, :valor)", sede="Suba", nota="", valor=Decimal("1250000.10"))
    cur.execute("SELECT count(*) FROM abono WHERE nota = ''")
    print("  filas con nota = '':", cur.fetchone()[0])
    cur.execute("SELECT count(*) FROM abono WHERE nota IS NULL")
    print("  filas con nota IS NULL:", cur.fetchone()[0])
    cur.execute("SELECT valor FROM abono")
    value = cur.fetchone()[0]
    print("  NUMBER(12,2) llega como:", repr(value), type(value).__name__)
    oracledb.defaults.fetch_decimals = True               # vale para los cursores que se creen después
    with conn.cursor() as cur2:
        cur2.execute("SELECT valor FROM abono")
        print("  con fetch_decimals:", repr(cur2.fetchone()[0]))
    cur.execute("DROP TABLE abono")
```

```bash
docker run -d --name aurea-oracle -e ORACLE_PASSWORD=aurea-local -p 1521:1521 gvenzl/oracle-free:23-slim
docker run -d --name aurea-mssql -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD='Aurea-Local-2026!' -p 1433:1433 \
    mcr.microsoft.com/mssql/server:2022-latest
AUREA_MSSQL=localhost AUREA_ORACLE=localhost/FREEPDB1 python3 aliados.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
pyodbc no importa: libodbc.so.2: cannot open shared object file: No such file or directory
pymssql conectado a SQL Server b'16.0.4295.3'
  VARCHAR / NVARCHAR: ('Quedó feliz ??', 'Quedó feliz 😁')
oracledb modo thin: True · Oracle 23.26.3.0.0
  filas con nota = '': 0
  filas con nota IS NULL: 1
  NUMBER(12,2) llega como: 1250000.1 float
  con fetch_decimals: Decimal('1250000.1')
```

Cada línea, una trampa. `pyodbc` instalado con `pip` no importa porque falta unixODBC, y con unixODBC faltaría el *driver*
de Microsoft; `pymssql` conecta sin nada más. En SQL Server, el emoji en la columna `VARCHAR` se convirtió en `??` sin un solo
error; en `NVARCHAR` llegó entero. En Oracle, el modo *thin* conectó sin Instant Client; la nota vacía se guardó como `NULL`
y `= ''` no la encuentra; y el monto de `NUMBER(12,2)` llegó como `float` hasta pedir `Decimal` explícitamente.

**Detalles con intención**

- **`#nota`** es una tabla temporal de SQL Server, que desaparece al cerrar la conexión: para leer a un aliado no se crea nada
  en su base, y el ejemplo tampoco.
- **`oracledb.defaults.fetch_decimals = True`** es global al proceso y **solo vale para los cursores que se crean después**: en la
  primera versión de este ejemplo se cambió a mitad de camino sobre el mismo cursor y el monto siguió llegando como `float`.
  Para plata, se pone al arrancar, antes de la primera conexión, y no se vuelve a tocar. También se puede pedir por columna con
  un *output type handler*.
- **`b'16.0.4295.3'`** llega como `bytes` porque `SERVERPROPERTY` devuelve un `sql_variant`, y `pymssql` no sabe a qué
  convertirlo. Se pide con `CAST(… AS NVARCHAR(128))`.
- **`conn.thin`** dice en qué modo quedó la conexión. El modo *thick* (con Instant Client) solo hace falta para funciones
  avanzadas o versiones viejas de Oracle (anteriores a 12.1).

---

## ⚠️ 4. Lo que se rompe

**`pyodbc` en la imagen de producción.** Funciona en la máquina del ingeniero, que instaló el *driver* de Microsoft hace un
año, y falla en el contenedor. El `Dockerfile` instala `unixodbc` y `msodbcsql18` desde el repositorio de Microsoft,
aceptando su licencia con una variable de entorno; o se usa `pymssql` si alcanza.

**El cifrado obligatorio del *driver* 18.** `msodbcsql18` cifra por defecto y valida el certificado del servidor. Contra una
réplica con certificado autofirmado falla, y la "solución" que aparece primero es `TrustServerCertificate=yes`: es el
`verify=False` de `se06`. Lo correcto es confiar en la CA del aliado.

**Comparar con `''` en Oracle.** Todo filtro que busca "sin nota" con `= ''` devuelve cero filas. En Oracle se busca con
`IS NULL`, y el código que construye consultas para varios motores lo tiene que saber.

**Los montos como `float`.** Sumar diez mil abonos de Oracle como `float` produce un total con centavos fantasma. La conciliación
con la aseguradora no cuadra por $0,01, y es una semana de búsqueda (`tx04`).

---

## ⚖️ 5. Cuándo NO usarlo

**`pyodbc` si `pymssql` alcanza.** Para leer, `pymssql` evita el *driver* del sistema. `pyodbc` gana con funciones de ODBC
específicas, autenticación integrada de Windows o Azure AD, y es el que Microsoft documenta.

**El modo *thick* de `oracledb` sin una razón.** El *thin* cubre casi todo y no necesita instalar nada.

**Leer las bases de los aliados en vivo, en cada pantalla.** Su réplica no es de Áurea y su disponibilidad tampoco. Se extrae de
noche a una base propia y se concilia allí.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Instala `unixodbc` en el contenedor y vuelve a correr. **Criterio:** `pyodbc` importa, y `drivers()` devuelve una lista
   vacía; explicas qué falta todavía.
2. Busca en Oracle las filas "sin nota" de la forma correcta. **Criterio:** la consulta devuelve la fila de Suba.
3. Cambia la columna `v` a `VARCHAR(50) COLLATE Latin1_General_100_CI_AS_SC_UTF8`. **Criterio:** el emoji se guarda entero, y
   explicas por qué.

**🟡 Intermedio (4–6)**

4. Haz un `Dockerfile` que instale `msodbcsql18` y conecta con `pyodbc`. **Criterio:** la misma lectura que con `pymssql`, y el
   tamaño de la imagen antes y después.
5. Usa un *output type handler* de `oracledb` para pedir `Decimal` solo en la columna `valor`. **Criterio:** las demás columnas
   numéricas siguen como `int` o `float`.
6. Conecta a SQL Server con cifrado y la CA del servidor, sin `TrustServerCertificate`. **Criterio:** la conexión funciona y la
   validación está activa.

**🟠 Difícil (7–9)**

7. Extrae 100 000 filas de cada motor a un archivo Parquet. **Criterio:** los tipos del Parquet (fechas, montos) son los
   correctos, verificados con `pyarrow`.
8. Mide `pymssql` contra `pyodbc` leyendo 200 000 filas. **Criterio:** la tabla de tiempos.
9. Escribe la conciliación: abonos de Áurea contra autorizaciones de la aseguradora, con montos en `Decimal`. **Criterio:** las
   diferencias reportadas al peso.

**🔴 Muy difícil (10)**

10. Diseña la extracción nocturna desde los dos aliados. **Criterio:** una página. *Rúbrica:* (a) *driver* de cada uno y qué
    instala la imagen; (b) cómo se tratan cifrado y certificados; (c) las trampas de datos y su conversión; (d) qué pasa si un
    aliado no responde.

---

## 📚 7. Referencias

**Documentación oficial**

- `python-oracledb`, modos *thin* y *thick*: https://python-oracledb.readthedocs.io/en/latest/user_guide/initialization.html
- `pyodbc`: https://github.com/mkleehammer/pyodbc/wiki
- `pymssql`: https://pymssql.readthedocs.io/en/stable/
- Microsoft, instalar el *driver* ODBC en Linux: https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server

**Orden de lectura sugerido:** la página de inicialización de `python-oracledb`; después la de instalación del *driver* ODBC de
Microsoft, para saber lo que cuesta `pyodbc`.

---

## 🚀 8. Cierre

Oracle se lee desde Python sin instalar nada más, con `oracledb` en modo *thin*; SQL Server, con `pymssql` sin nada más o con
`pyodbc` y el *driver* ODBC de Microsoft en el sistema. Las trampas de datos son de cada motor: `VARCHAR` que pierde caracteres
sin error, la cadena vacía que es `NULL`, y `NUMBER` que llega como `float`.

**La señal de que quedó bien:** *"La conciliación con la aseguradora cuadró al peso, y el contenedor que la corre se construye
sin pasos manuales."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-db-fase-03 -m "op db03 cerrada: pymssql, pyodbc, oracledb thin y las trampas de cada motor"
> ```
>
> Los commits llevan su prefijo (`op db03: …`) y los de ejercicio su número
> (`op db03 ej07: …`).
