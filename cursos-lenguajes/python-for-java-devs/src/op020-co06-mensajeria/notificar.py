"""Un notificador con dos canales: Slack para el equipo, WhatsApp (Twilio) para pacientes."""

import datetime as dt
import json
from dataclasses import dataclass
from typing import Protocol

import httpx


class TeamChannel(Protocol):
    def alert(self, text: str) -> None: ...


@dataclass
class SlackWebhook:
    url: str            # secreta: quien la tiene, publica en el canal
    client: httpx.Client

    def alert(self, text: str) -> None:
        self.client.post(self.url, json={"text": text}).raise_for_status()


@dataclass(frozen=True)
class Patient:
    patient_id: str
    whatsapp: str | None
    consented_whatsapp: bool


@dataclass
class TwilioWhatsApp:
    account_sid: str
    auth_token: str
    sender: str                 # "whatsapp:+57…", el número de la empresa
    reminder_template: str      # el identificador de la plantilla aprobada (empieza con HX)
    client: httpx.Client

    def remind(self, patient: Patient, starts_at: dt.datetime, branch: str) -> str:
        # La frontera, en el código: sin consentimiento o sin número no sale nada.
        if not (patient.consented_whatsapp and patient.whatsapp):
            raise PermissionError(f"el paciente {patient.patient_id} no autorizó WhatsApp")
        # Solo variables sin datos clínicos: fecha, hora y sede. Nada del tratamiento.
        variables = {"1": starts_at.strftime("%d/%m"), "2": starts_at.strftime("%I:%M %p"), "3": branch}
        response = self.client.post(
            f"https://api.twilio.com/2010-04-01/Accounts/{self.account_sid}/Messages.json",
            auth=(self.account_sid, self.auth_token),
            data={"From": self.sender, "To": f"whatsapp:{patient.whatsapp}",
                  "ContentSid": self.reminder_template, "ContentVariables": json.dumps(variables)},
        )
        response.raise_for_status()
        return response.json()["sid"]


def fake_services() -> httpx.MockTransport:
    """Slack y Twilio simulados: guardan lo que recibieron, para mirarlo en la prueba."""
    sent = []

    def handler(request: httpx.Request) -> httpx.Response:
        sent.append((request.url.host, request.content.decode()))
        if request.url.host == "hooks.slack.com":
            return httpx.Response(200, text="ok")
        return httpx.Response(201, json={"sid": "SM0001", "status": "queued"})

    transport = httpx.MockTransport(handler)
    transport.sent = sent
    return transport


if __name__ == "__main__":
    transport = fake_services()
    with httpx.Client(transport=transport, timeout=10) as client:
        team = SlackWebhook("https://hooks.slack.com/services/T000/B000/XXXX", client)
        team.alert("❌ El cierre nocturno falló en la sede Suba a las 02:47")

        whatsapp = TwilioWhatsApp("AC0001", "token-de-prueba", "whatsapp:+5716000000",
                                  "HX0001", client)
        ana = Patient("PAC-1023", "+573001234567", consented_whatsapp=True)
        luis = Patient("PAC-5298", "+573109876543", consented_whatsapp=False)
        print("recordatorio:", whatsapp.remind(ana, dt.datetime(2026, 10, 6, 15, 40), "Centro"))
        try:
            whatsapp.remind(luis, dt.datetime(2026, 10, 6, 9, 0), "Suba")
        except PermissionError as error:
            print("no enviado:", error)
    for host, body in transport.sent:
        print(host, "←", body[:90])
