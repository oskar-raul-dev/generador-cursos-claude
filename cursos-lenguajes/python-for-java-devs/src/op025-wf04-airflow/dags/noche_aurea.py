"""La noche de Áurea como DAG de Airflow 3: tareas delgadas que llaman al dominio."""

import datetime as dt

from airflow.sdk import dag, task


# En un proyecto real estas funciones viven en el paquete de Cartera y se importan.
def consolidate_rips(day: str) -> str:
    return f"/datos/rips/{day}.json"


def file_claims(batch: str) -> int:
    return 12


def compute_royalties(batch: str) -> int:
    return 6


@dag(
    schedule="0 2 * * *",
    start_date=dt.datetime(2026, 10, 1, tzinfo=dt.timezone(dt.timedelta(hours=-5))),
    catchup=False,                      # no correr las noches pasadas al activar el DAG
    default_args={"retries": 2, "retry_delay": dt.timedelta(minutes=10)},
    tags=["cartera"],
)
def noche_aurea():
    @task
    def consolidar(logical_date=None) -> str:
        # La tarea procesa SU noche, no "hoy": relanzar la del día 3 procesa el día 3.
        return consolidate_rips(logical_date.strftime("%Y-%m-%d"))

    @task
    def radicar(batch: str) -> int:
        return file_claims(batch)

    @task
    def regalias(batch: str) -> int:
        return compute_royalties(batch)

    @task
    def informe(radicadas: int, liquidadas: int) -> None:
        print(f"radicadas {radicadas}, liquidaciones {liquidadas}")

    batch = consolidar()                       # pasa una RUTA, no los datos
    informe(radicar(batch), regalias(batch))   # radicar y regalias corren en paralelo


noche_aurea()
