"""La noche de Áurea en Prefect: funciones con decorador, reintentos y concurrencia."""

from prefect import flow, task

ATTEMPTS = {"radicar": 0}


@task(retries=2, retry_delay_seconds=1)
def consolidar(day: str) -> str:
    return f"/datos/rips/{day}.json"


@task(retries=2, retry_delay_seconds=1)
def radicar(batch: str) -> int:
    ATTEMPTS["radicar"] += 1
    if ATTEMPTS["radicar"] == 1:
        raise ConnectionError("el portal de la aseguradora no responde")
    return 12


@task
def regalias(batch: str) -> int:
    return 6


@flow(log_prints=True)
def noche_aurea(day: str) -> str:
    batch = consolidar(day)
    # .submit lanza las dos tareas a la vez; .result() espera a cada una.
    filed, settled = radicar.submit(batch), regalias.submit(batch)
    summary = f"radicadas {filed.result()}, liquidaciones {settled.result()}"
    print(summary)
    return summary


if __name__ == "__main__":
    print(noche_aurea("2026-10-05"))
