"""La misma tarea en Huey, con SQLite como broker: un archivo, ningún servidor."""

from huey import SqliteHuey

import tareas

huey = SqliteHuey(filename="cola.db")


@huey.task(retries=3, retry_delay=1)
def build_settlement_pdf(franchise: str, quarter: str) -> str:
    return tareas.build_settlement_pdf(franchise, quarter)
