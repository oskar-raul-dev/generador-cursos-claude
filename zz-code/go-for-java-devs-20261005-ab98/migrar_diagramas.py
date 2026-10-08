"""Reemplaza los siete bloques text de go-for-java-devs por su versión Mermaid (D-12)."""
import pathlib, re, sys
C = pathlib.Path(sys.argv[1])

def bloque(archivo, primera_linea):
    t = (C / archivo).read_text(encoding="utf-8")
    patron = re.compile(r"```text\n" + re.escape(primera_linea) + r"\n.*?\n```\n", re.S)
    hallados = patron.findall(t)
    assert len(hallados) == 1, (archivo, primera_linea, len(hallados))
    return t, hallados[0]

CAMBIOS = [
("17-capstone.md", "┌─────────────┐  sync HTTP   ┌──────────────────┐", '''```mermaid
flowchart TD
    SA["storeagent<br/>(SQLite)"] -- "sync HTTP · F10" --> CH["ClearingHouse<br/>(PostgreSQL)"]
    CH -- "cierre por lotes · F13" --> OR["OpsReport<br/>(PostgreSQL)"]
    OR -- "F13" --> OB["outbox<br/>(misma tx)"]
    OR -- "reporte en streaming · F13" --> RP["CSV/JSON/HTML"]
    OB -- "SKIP LOCKED" --> ER["EventRelay<br/>(PostgreSQL)"]
    ER -- "HMAC, reintentos · F10, F12" --> FC["fakeconsumer"]
    FC -- "tipo de cambio · F11, F12" --> AS["AtlasSync<br/>(Mongo+Valkey)"]
```
'''),
("13-lotes-scheduling-y-asincronia.md", "┌─ TRANSACCIÓN ────────────────────────────────────┐", '''```mermaid
flowchart TD
    subgraph TX["TRANSACCIÓN"]
        direction TB
        S1["1. leer N movimientos desde el último cursor"] --> S2["2. conciliarlos"]
        S2 --> S3["3. escribir los asientos resultantes"]
        S3 --> S4["4. ESCRIBIR EL PUNTO DE CONTROL<br/>(nuevo cursor)"]
    end
    TX --> CM(["COMMIT"])
```
'''),
("13-lotes-scheduling-y-asincronia.md", "commit del trabajo → ☠️ fallo → punto de control NO escrito", '''```mermaid
flowchart TD
    subgraph V1["Primero el trabajo, después el punto de control"]
        direction LR
        A1["commit del trabajo"] --> F1["☠️ fallo"] --> N1["punto de control NO escrito"]
        N1 --> R1["al reanudar, se reprocesa lo ya hecho<br/>→ DUPLICADOS (salvo idempotencia)"]
    end
    subgraph V2["Primero el punto de control, después el trabajo"]
        direction LR
        A2["punto de control escrito"] --> F2["☠️ fallo"] --> N2["commit del trabajo NO hecho"]
        N2 --> R2["al reanudar, se salta trabajo<br/>→ PÉRDIDA SILENCIOSA, que es peor"]
    end
    V1 ~~~ V2
    style R2 stroke:#d9534f,stroke-width:2px
```
'''),
("12-cache-con-valkey.md", "leer:     mirar caché → si falla, leer origen → guardar en caché → devolver", '''```mermaid
flowchart TD
    subgraph LE["leer"]
        direction LR
        L1{"mirar caché"} -- "acierto" --> L4["devolver"]
        L1 -- "falla" --> L2["leer origen"] --> L3["guardar en caché"] --> L4
    end
    subgraph ES["escribir"]
        direction LR
        E1["escribir origen"] --> E2["INVALIDAR la clave<br/>(no actualizarla)"]
    end
    LE ~~~ ES
```
'''),
("12-cache-con-valkey.md", "t0  Goroutine A: falla la caché, lee de Mongo → obtiene población 52.000.000", '''```mermaid
sequenceDiagram
    participant A as Goroutine A
    participant K as Caché
    participant M as Mongo
    participant B as Goroutine B
    Note over A,B: t0
    A->>K: Get: falla la caché
    A->>M: lee de Mongo
    M-->>A: población 52.000.000
    Note over A,B: t1
    B->>M: escribe población 53.000.000
    B->>K: invalida la clave
    Note over A,B: t2
    A->>K: guarda el valor VIEJO (52.000.000)
    Note over K: La caché queda con un dato obsoleto,<br/>y el TTL es lo único que lo arregla.
```
'''),
("16-go-frente-a-spring-boot.md", "JVM:", '''```mermaid
flowchart TD
    subgraph JV["JVM"]
        direction LR
        J1["arranque"] --> J2["interpretar bytecode"] --> J3["perfilar qué<br/>se ejecuta mucho"]
        J3 --> J4["compilar a código<br/>máquina con C1"] --> J5["recompilar con C2 optimizando<br/>AGRESIVAMENTE con la información<br/>de ejecución real"]
    end
    subgraph GO["Go"]
        direction LR
        G1["compilar todo a código máquina ANTES"] --> G2["ejecutar"]
    end
    JV ~~~ GO
```
'''),
("01-sintaxis-y-valores.md", "slice = { ptr → arreglo de respaldo,  len,  cap }", '''```mermaid
flowchart LR
    MV["movements<br/>cabecera: ptr · len=4 · cap=4"] -- "ptr" --> AR
    FT["firstTwo<br/>cabecera: ptr · len=2 · cap=4"] -- "ptr" --> AR
    AR["arreglo de respaldo, el MISMO para los dos<br/>[SALE] [REFUND] [VOID] [DEPOSIT]"]
```
'''),
]

nuevos = {}
for archivo, primera, mermaid in CAMBIOS:
    t = nuevos.get(archivo) or (C / archivo).read_text(encoding="utf-8")
    patron = re.compile(r"```text\n" + re.escape(primera) + r"\n.*?\n```\n", re.S)
    hallados = patron.findall(t)
    assert len(hallados) == 1, (archivo, primera, len(hallados))
    nuevos[archivo] = t.replace(hallados[0], mermaid, 1)
for archivo, t in nuevos.items():
    (C / archivo).write_text(t, encoding="utf-8")
    print("escrito", archivo)
