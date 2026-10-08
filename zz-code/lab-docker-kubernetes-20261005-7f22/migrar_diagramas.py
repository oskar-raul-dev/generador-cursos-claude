"""Reemplaza los bloques `text` que son diagramas por bloques `mermaid` (D44, guía §19.1).

Cada entrada: (archivo, línea de la valla ```text, inicio esperado de la primera línea del cuerpo,
cuerpo Mermaid). Falla sin escribir nada si alguna valla no está donde se espera.
Uso: python3 migrar_diagramas.py <carpeta-del-curso> [--aplicar] [--volcar <dir>]
"""
import pathlib, sys

D = []
def d(archivo, linea, inicio, cuerpo):
    D.append((archivo, linea, inicio, cuerpo.strip("\n")))

d("00-el-ambiente.md", 66, "EL SISTEMA AL FINAL", '''
flowchart TD
    NAV["navegador"] --> GW["Gateway"]
    GW --> SF["storefront<br/>React"]
    GW --> CAT["catalog<br/>PHP · Laravel<br/><i>el maestro de productos</i>"]
    GW --> INV["inventory<br/>Java · Spring<br/><i>las existencias, la venta y el préstamo</i>"]
    GW --> PRI["pricing<br/>Go<br/><i>el precio vigente en cada droguería</i>"]
    GW --> REP["replenish<br/>Node · NestJS<br/><i>la reposición entre droguerías</i>"]
    CAT & INV & PRI & REP --> BASE[("Postgres · Valkey · NATS<br/>y la observabilidad, encendida por piezas")]
''')

d("06-del-compose-al-cluster.md", 261, "EL BUCLE DE RECONCILIACIÓN", '''
flowchart TD
    TU["tú"] -- "«quiero 2 réplicas de pricing»" --> API["API<br/>el estado deseado, guardado"]
    API --> O
    subgraph CTRL["el controlador"]
        O["1. observa<br/>¿cuántos pods de pricing hay listos?"] --> C["2. compara<br/>deseado 2 · actual 1"]
        C --> A["3. actúa<br/>crea un pod"]
    end
    A --> CL["el cluster<br/>lo que de verdad corre"]
    CL -- "y vuelve a empezar, sin parar" --> O
''')

d("10-la-entrada-al-sistema.md", 263, "EL CAMINO DE UNA PETICIÓN", '''
flowchart LR
    CURL["curl"] --> H["127.0.0.1:8080"]
    H --> N["nodo de kind :30080<br/>NodePort"]
    N --> E["proxy Envoy<br/>del Gateway"]
    E -- "HTTPRoute pricing:<br/>api.localhost + /pricing<br/>reescribe a /" --> S["Service pricing<br/>ClusterIP"]
    S --> P["pod pricing"]
''')

d("27-el-veredicto-y-el-proyecto-final.md", 15, "                    api.localhost:8080", '''
flowchart TD
    GW["api.localhost:8080 · storefront.localhost:8080<br/>la puerta: Envoy Gateway, Gateway API"]
    subgraph APPS["apps"]
        SF["storefront<br/>React, nginx"]
        INV["inventory<br/>Java"]
        PRI["pricing<br/>Go"]
        CAT["catalog<br/>PHP-FPM + nginx"]
        REP["replenish<br/>Node"]
        OR["outbox-relay<br/>sidecar de inventory, Go"]
    end
    subgraph DATA["data"]
        PG[("Postgres<br/>una base por servicio")]
        NATS[["NATS JetStream"]]
    end
    subgraph LEGACY["legacy"]
        LEG["Contingencia (GlassFish), el portal, la Braqui<br/>el patrimonio, detrás de la misma puerta"]
    end
    subgraph OBS["observability"]
        O["Prometheus, Grafana, Loki, Fluent Bit, Tempo<br/>cada uno con su interruptor"]
    end
    subgraph APPSB["apps-b"]
        B["la segunda cadena<br/>el mismo chart, otro release"]
    end
    GW --> APPS
    GW --> LEGACY
    INV -- "gRPC + mTLS" --> PRI
    INV --> CAT
    INV -- "saga" --> REP
    INV --> OR
    OR -- "publica" --> NATS
    NATS -- "consume" --> REP
    APPS --> PG
    DATA ~~~ OBS
    DATA ~~~ APPSB
''')

d("27-el-veredicto-y-el-proyecto-final.md", 84, "¿Lo resolvía un contenedor", '''
flowchart TD
    Q1{"¿Lo resolvía un contenedor y un servicio<br/>del sistema operativo?"}
    Q1 -- "sí" --> R1["listo. Un contenedor con restart, en una máquina."]
    Q1 -- "no, porque…" --> Q2{"¿Lo resolvía compose en una máquina?"}
    Q2 -- "sí" --> R2["listo. Un archivo, una máquina, un respaldo."]
    Q2 -- "no, porque…" --> Q3{"¿Dos servidores, un balanceador<br/>y una lista de comprobación?"}
    Q3 -- "sí" --> R3["listo. Lo que ya hacía Contingencia."]
    Q3 -- "no, porque…" --> Q4{"¿De verdad un orquestador?<br/>¿Propio o gestionado?"}
''')

d("a03-contratos-y-prompts-de-generacion.md", 49, "  el contrato (OpenAPI)", '''
flowchart LR
    C["el contrato (OpenAPI)<br/><code>contracts/openapi/</code>"] --> S["la suite del paso (Hurl)<br/><code>contracts/conformance/</code>"]
    S --> P["el prompt del paso<br/>este apéndice"]
    P --> K["el código<br/><code>services/#lt;svc#gt;/</code>"]
    K -- "si no pasa, se corrige el prompt, no el código" --> P
''')

d("a16-el-patrimonio.md", 43, "EL PATRIMONIO, EN COMPOSE", '''
flowchart LR
    PORTAL["portal (Laravel)<br/>127.0.0.1:8081"] -- "SOAP, cada noche" --> CONT["contingencia (GlassFish)<br/>/PriceService · /StockService<br/>lote cada 2 min"]
    CONT -- "JPA" --> DB[("contingencia-db<br/>Postgres")]
    CONT -- "escribe" --> VOL[/"volumen «traslados»<br/>traslados_*.txt + .ok"/]
    VOL --> TR["braqui-traslados<br/>Python + cron, 5 min"]
    TR -- "inserta" --> DB
    BRAQUI["braqui<br/>Node, sondea cada 30 s"] -- "lee y escribe" --> DB
''')


def main():
    raiz = pathlib.Path(sys.argv[1]); aplicar = "--aplicar" in sys.argv
    if "--volcar" in sys.argv:
        dest = pathlib.Path(sys.argv[sys.argv.index("--volcar") + 1]); dest.mkdir(parents=True, exist_ok=True)
        for k, (a, l, _, cuerpo) in enumerate(D, 1):
            (dest / f"{k:02d}-{a[:-3]}-{l}.mmd").write_text(cuerpo + "\n", encoding="utf-8")
    por_archivo = {}
    for a, l, ini, cuerpo in D:
        por_archivo.setdefault(a, []).append((l, ini, cuerpo))
    problemas, nuevos = [], {}
    for a, entradas in por_archivo.items():
        lineas = (raiz / a).read_text(encoding="utf-8").split("\n")
        for l, ini, cuerpo in sorted(entradas, reverse=True):
            i = l - 1
            if lineas[i].strip() != "```text" or not lineas[i + 1].startswith(ini):
                problemas.append(f"{a}:{l}: no coincide ({lineas[i]!r} / {lineas[i+1]!r})")
                continue
            j = i + 1
            while lineas[j].strip() != "```":
                j += 1
            lineas[i:j + 1] = ["```mermaid"] + cuerpo.split("\n") + ["```"]
        nuevos[a] = "\n".join(lineas)
    if problemas:
        print("\n".join(problemas)); return 1
    if aplicar:
        for a, t in nuevos.items():
            (raiz / a).write_text(t, encoding="utf-8")
    print(f"{len(D)} diagramas en {len(por_archivo)} archivos" + (" — aplicado" if aplicar else " — sin aplicar"))
    return 0

if __name__ == "__main__":
    sys.exit(main())
