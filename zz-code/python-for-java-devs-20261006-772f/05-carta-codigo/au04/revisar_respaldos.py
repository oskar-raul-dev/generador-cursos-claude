"""Revisa por SSH el último respaldo de Odontovía en cada sede y el espacio libre del disco."""

import shlex
import time
from dataclasses import dataclass

import paramiko

SITES = {"Centro": ("pfjd-centro", 22), "Suba": ("pfjd-suba", 22)}
BACKUP = "/respaldos/odontovia.sql.gz"
MAX_AGE_HOURS = 26  # el respaldo es diario; dos horas de gracia


@dataclass
class Report:
    site: str
    ok: bool
    detail: str


def run(client: paramiko.SSHClient, command: str, timeout: float = 20) -> str:
    _, stdout, stderr = client.exec_command(command, timeout=timeout)
    status = stdout.channel.recv_exit_status()  # espera a que termine: es el código lo que cuenta
    if status != 0:
        raise RuntimeError(f"{command!r} terminó con {status}: {stderr.read().decode().strip()}")
    return stdout.read().decode()


def check_site(site: str, host: str, port: int) -> Report:
    client = paramiko.SSHClient()
    client.load_host_keys("known_hosts")
    client.set_missing_host_key_policy(paramiko.RejectPolicy())  # explícito: es el de por defecto
    try:
        client.connect(host, port=port, username="revisor", key_filename="revisor",
                       timeout=10, allow_agent=False, look_for_keys=False)
        size, mtime = run(client, f"stat -c '%s %Y' {shlex.quote(BACKUP)}").split()
        age_hours = (time.time() - int(mtime)) / 3600
        free_kb = int(run(client, "df -Pk /respaldos").splitlines()[1].split()[3])
    except (OSError, paramiko.SSHException, RuntimeError) as error:
        return Report(site, False, f"no se pudo revisar: {error}")
    finally:
        client.close()
    problems = []
    if age_hours > MAX_AGE_HOURS:
        problems.append(f"respaldo de hace {age_hours / 24:.0f} días")
    if int(size) < 1_000_000:
        problems.append(f"respaldo de {int(size) / 1e6:.1f} MB, sospechosamente pequeño")
    if free_kb < 5_000_000:
        problems.append(f"quedan {free_kb / 1e6:.1f} GB libres")
    return Report(site, not problems, "; ".join(problems) or f"{int(size) / 1e6:.1f} MB, de hace {age_hours:.0f} h")


if __name__ == "__main__":
    for report in (check_site(name, *address) for name, address in SITES.items()):
        print(f"{'✅' if report.ok else '❌'} {report.site}: {report.detail}")
