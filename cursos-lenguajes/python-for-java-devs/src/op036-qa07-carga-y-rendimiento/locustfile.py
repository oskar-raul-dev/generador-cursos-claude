"""Una auxiliar de recepción: consulta mucho, reserva poco, y espera entre una cosa y otra."""

import random

from locust import HttpUser, between, task


class Receptionist(HttpUser):
    wait_time = between(1, 3)

    @task(5)
    def check_availability(self):
        sede = random.choice(["centro", "suba", "zipaquira"])
        # name= agrupa las URL con parámetro en una sola fila del reporte.
        self.client.get(f"/disponibilidad/{sede}", name="/disponibilidad/[sede]")

    @task(1)
    def book(self):
        self.client.post("/reservas/centro", name="/reservas/[sede]")
