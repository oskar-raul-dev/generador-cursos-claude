"""Las credenciales de Postgres del laboratorio (Fase 12), sin versionarlas.

La primera vez genera .secrets/postgres.env con una contraseña al azar por usuario. Después imprime,
como YAML para `kubectl apply -f -`, el Secret postgres-users (namespace data) y un Secret <svc>-db
por servicio (namespace apps) con su DATABASE_URL. Solo biblioteca estándar.

    python3 scripts/data/credentials.py | kubectl apply -f -

Con --tenant tenant-b (Fase 14), lo mismo para la segunda cadena: sus contraseñas se agregan al mismo
archivo, sus Secret van a apps-b, y sus bases se llaman <svc>_tenant_b, en el mismo Postgres. Como el
init.sh corre una sola vez, con --sql imprime el SQL que las crea, para psql (se puede repetir):

    python3 scripts/data/credentials.py --tenant tenant-b --sql | kubectl -n data exec -i postgres-0 -- psql -U postgres
"""
import argparse
import base64
import secrets
from pathlib import Path

LAB = Path(__file__).resolve().parents[2]
ENV_FILE = LAB / ".secrets" / "postgres.env"
SERVICES = ["pricing", "inventory", "catalog", "replenish"]
HOST = "postgres.data.svc.cluster.local"
# Las cadenas además de la principal, y su namespace (contrato §4).
TENANTS = {"tenant-b": "apps-b"}


def user(service: str, tenant: str | None) -> str:
    """El usuario y la base de un servicio: pricing en la cadena principal, pricing_tenant_b en la otra."""
    return f"{service}_{tenant.replace('-', '_')}" if tenant else service


def load(tenant: str | None) -> dict[str, str]:
    if not ENV_FILE.exists():
        ENV_FILE.parent.mkdir(exist_ok=True)
        keys = ["POSTGRES_PASSWORD"] + [f"{s.upper()}_DB_PASSWORD" for s in SERVICES]
        ENV_FILE.write_text("".join(f"{k}={secrets.token_urlsafe(18)}\n" for k in keys), encoding="utf-8")
    pairs = (line.split("=", 1) for line in ENV_FILE.read_text(encoding="utf-8").splitlines() if "=" in line)
    env = {k: v for k, v in pairs}
    if tenant:
        # Las de la cadena se agregan la primera vez que se piden, sin tocar las que ya existen.
        missing = [k for k in (f"{user(s, tenant).upper()}_DB_PASSWORD" for s in SERVICES) if k not in env]
        with ENV_FILE.open("a", encoding="utf-8") as f:
            for k in missing:
                env[k] = secrets.token_urlsafe(18)
                f.write(f"{k}={env[k]}\n")
    return env


def secret(name: str, namespace: str, data: dict[str, str], service: str) -> str:
    lines = [f"  {k}: {base64.b64encode(v.encode()).decode()}" for k, v in data.items()]
    return "\n".join(["apiVersion: v1", "kind: Secret", "metadata:", f"  name: {name}", f"  namespace: {namespace}",
                      "  labels:", f"    app.kubernetes.io/name: {service}", "    app.kubernetes.io/part-of: lab",
                      "type: Opaque", "data:", *lines])


def sql(env: dict[str, str], tenant: str) -> str:
    """Los usuarios y las bases de una cadena, como en init.sh. \\gexec ejecuta la sentencia que arma el
    SELECT, y el WHERE NOT EXISTS hace que la segunda corrida no haga nada."""
    out = []
    for s in SERVICES:
        u = user(s, tenant)
        password = env[f"{u.upper()}_DB_PASSWORD"]
        out.append(f"SELECT 'CREATE ROLE {u} LOGIN PASSWORD ''{password}''' "
                   f"WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '{u}')\\gexec")
        out.append(f"SELECT 'CREATE DATABASE {u} OWNER {u}' "
                   f"WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '{u}')\\gexec")
        out.append(f"REVOKE ALL ON DATABASE {u} FROM PUBLIC;")
    return "\n".join(out)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tenant", choices=sorted(TENANTS))
    parser.add_argument("--sql", action="store_true", help="el SQL que crea los usuarios y las bases de la cadena")
    args = parser.parse_args()
    env = load(args.tenant)
    if args.sql:
        print(sql(env, args.tenant))
        return
    docs = [secret("postgres-users", "data", env, "postgres")]
    namespace = TENANTS.get(args.tenant, "apps")
    for s in SERVICES:
        u = user(s, args.tenant)
        url = f"postgres://{u}:{env[f'{u.upper()}_DB_PASSWORD']}@{HOST}:5432/{u}"
        docs.append(secret(f"{s}-db", namespace, {"DATABASE_URL": url}, s))
    print("\n---\n".join(docs))


if __name__ == "__main__":
    main()
