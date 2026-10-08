# 📮 co06 — Mensajería y notificaciones

> Python para desarrolladores Java senior · **Carta** · Track `co` — Comunicaciones y
> transferencia · sección 6 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta. Conviene tener presente la
> frontera de datos de [la historia de Áurea](00-historia-de-aurea.md) §5.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Áurea vive en WhatsApp. Yuli contesta mensajes entre paciente y paciente, los recordatorios de cita
salen a mano desde el teléfono de cada sede, y cuando el cierre nocturno falla, alguien se entera a
las nueve de la mañana porque nadie miró el correo. Hay dos necesidades distintas, y conviene no
mezclarlas:

- **Avisos internos**: el cierre falló, una sede no mandó su respaldo, llegó una circular. Van a un
  canal del equipo —Slack, Telegram, Teams— y pueden decir lo que haga falta.
- **Mensajes a pacientes**: el recordatorio de la cita de mañana. Van a WhatsApp o SMS, y cruzan
  una frontera legal: datos personales (Ley 1581 de habeas data), consentimiento para el canal, y
  las reglas de la propia plataforma de mensajería para los mensajes que inicia una empresa.

Esta sección enseña a mandar los dos desde Python con la misma forma de código, y a poner la
frontera en el código en vez de en la buena voluntad de quien lo use.

---

## 🧠 2. El modelo

Un **notificador** es una interfaz con una implementación por canal. El código del dominio dice
*"avisa al equipo"* o *"recuérdale la cita a este paciente"*, y no sabe si eso sale por Slack o por
WhatsApp. Lo que cambia por canal es lo que cada uno exige:

| Canal | Quién recibe | Cómo se manda desde Python | Lo que exige |
|---|---|---|---|
| Slack (webhook entrante) | El equipo | Un `POST` con JSON a una URL secreta | Que la URL no se filtre: quien la tiene, publica |
| Telegram (bot) | El equipo | `python-telegram-bot` (22.8), o un `POST` a la API | El identificador del chat; el bot no puede escribirle primero a nadie |
| WhatsApp Business (por Twilio u otro proveedor) | Pacientes | `twilio` (9.11.2), o un `POST` a la API REST | **Plantilla aprobada** para los mensajes que inicia la empresa, consentimiento del paciente |
| SMS | Pacientes | El mismo proveedor | Consentimiento; costo por mensaje |

La regla que más pesa de la tabla es la de WhatsApp: **los mensajes que inicia una empresa tienen
que usar una plantilla aprobada previamente por la plataforma**, con variables que se rellenan. Los
mensajes libres solo se pueden mandar dentro de una ventana de servicio, después de que el paciente
escribió. Un recordatorio de cita es exactamente el caso de plantilla.

Y la regla que pone Áurea, por la historia clínica: **el mensaje no lleva datos clínicos**. *"Le
recordamos su cita de mañana a las 3:40 p. m. en la sede Centro"* sí; *"su control de periodoncia"*,
no. Quien ve la pantalla bloqueada del teléfono de un paciente no tiene por qué saber su tratamiento.

### Tu instinto de Java dice… y esta vez se equivoca

El reflejo es instalar el SDK de cada servicio —`slack-sdk`, `python-telegram-bot`, `twilio`— y
llamar a cada uno donde haga falta. Para mandar un mensaje, cada SDK trae decenas de dependencias y
una API propia, y el dominio termina sabiendo de tres proveedores. **Para mandar**, un `POST` con
`httpx` contra la API de cada uno son cinco líneas y se prueban todas igual. Los SDK ganan cuando
haces más: bots interactivos, archivos, eventos entrantes.

---

## 💻 3. El ejemplo que corre

```bash
uv add httpx
```

`notificar.py`:

```python
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
```

```bash
python3 notificar.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
recordatorio: SM0001
no enviado: el paciente PAC-5298 no autorizó WhatsApp
hooks.slack.com ← {"text":"❌ El cierre nocturno falló en la sede Suba a las 02:47"}
api.twilio.com ← From=whatsapp%3A%2B5716000000&To=whatsapp%3A%2B573001234567&ContentSid=HX0001&ContentVaria
```

Lo que **no** aparece en el mensaje a Ana es el punto: fecha, hora y sede, y nada de su tratamiento.
El texto que verá lo define la plantilla aprobada en la plataforma, no el código.

**Detalles con intención**

- **La frontera vive en `remind`**, no en quien la llama. Ningún proceso nuevo puede olvidarse de
  revisar el consentimiento, porque sin él la función no manda.
- **Las variables de la plantilla son de formato fijo**: el código no puede meter texto libre en el
  mensaje a un paciente, aunque quiera.
- **`fake_services`** prueba los dos canales con el mismo transporte: el código de producción y el de
  la prueba son el mismo, cambia solo de dónde viene la respuesta.
- **El webhook de Slack es un secreto.** Va en el gestor de secretos, no en el repositorio: quien tiene
  esa URL puede publicar en el canal del equipo.

---

## ⚠️ 4. Lo que se rompe

**El número que no es de WhatsApp, o el paciente que bloqueó a la empresa.** La API acepta el mensaje
(`queued`) y la entrega falla después. El estado final llega por un *webhook* de estado que tu
servicio tiene que recibir, o consultando el mensaje por su `sid`. "Enviado" en la respuesta no es
"entregado".

**La plantilla rechazada o pausada.** Las plataformas revisan las plantillas y las pausan si los
usuarios las marcan como no deseadas. Un recordatorio que de un día para otro deja de salir puede ser
una plantilla pausada, no un error de código. El aviso interno de "falló el envío" tiene que decir el
código de error del proveedor.

**El horario.** Un recordatorio que sale a las once de la noche porque el proceso nocturno se demoró
genera quejas, y las quejas bajan la calidad del número de la empresa. Los mensajes a pacientes tienen
una ventana horaria propia, independiente de cuándo corre el proceso.

**Mandar desde el teléfono de la sede "mientras tanto".** Automatizar desde una cuenta personal de
WhatsApp con herramientas no oficiales viola los términos de la plataforma y termina con el número
bloqueado, que es el número que los pacientes tienen guardado.

---

## ⚖️ 5. Cuándo NO usarla

**Para lo que tiene que quedar escrito y con valor.** Las liquidaciones, las respuestas a glosas y
todo lo que se pueda discutir después van por correo (o por un canal con constancia), no por un
mensaje que se pierde en un chat.

**Para el equipo, cuando el correo ya funciona y nadie lo mira.** Agregar Slack no resuelve que nadie
mire las alertas. Primero se decide **quién** atiende cada aviso; el canal es lo de menos.

**Para mensajes de marketing a pacientes sin autorización específica.** El consentimiento para
recordatorios de cita no cubre promociones. La Ley 1581 pide autorización para cada finalidad, y la
publicidad es otra finalidad.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Agrega un paciente sin número de WhatsApp y con consentimiento. **Criterio:** no se manda nada y el
   error lo dice.
2. Haz que `SlackWebhook` reciba el texto con formato (negrita, enlace) en el formato de Slack.
   **Criterio:** la prueba muestra el JSON con el formato y explicas cuál es.
3. Implementa `TelegramBot` con la misma interfaz `TeamChannel`, como un `POST` a `sendMessage`.
   **Criterio:** el código que avisa del cierre no cambia al pasar de Slack a Telegram.

**🟡 Intermedio (4–6)**

4. Busca en la documentación de WhatsApp Business qué categorías de plantilla existen y en cuál cae un
   recordatorio de cita. **Criterio:** la categoría y su implicación en el costo por conversación.
5. Agrega la ventana horaria: entre las 7:00 y las 20:00, hora de Bogotá. **Criterio:** un recordatorio
   pedido a las 23:00 se encola para las 7:00 del día siguiente, demostrado con una prueba.
6. Reemplaza el `POST` a Twilio por el SDK `twilio`. **Criterio:** comparas dependencias instaladas y
   cómo se prueba cada versión sin red.

**🟠 Difícil (7–9)**

7. Escribe el receptor del *webhook* de estado de Twilio con FastAPI y actualiza el estado del
   recordatorio (`sent`, `delivered`, `failed`). **Criterio:** la firma del webhook se verifica, y un
   webhook sin firma válida se rechaza.
8. Haz los recordatorios idempotentes: si el proceso se cae y se relanza, ningún paciente recibe dos
   recordatorios de la misma cita. **Criterio:** una prueba con una caída simulada después del tercer
   envío.
9. Agrega un segundo canal de respaldo (SMS) para los pacientes sin WhatsApp que autorizaron SMS.
   **Criterio:** la elección de canal vive en un solo lugar y respeta el consentimiento de cada canal.

**🔴 Muy difícil (10)**

10. Diseña los recordatorios de cita de las diez sedes de punta a punta. **Criterio:** un documento de
    una página y un prototipo con los servicios simulados. *Rúbrica:* (a) el consentimiento y la
    finalidad se registran con su fecha, y retirarlos detiene los envíos; (b) ningún mensaje lleva
    datos clínicos, y lo garantiza el código, no una instrucción; (c) la entrega real se mide y se
    reporta por sede; (d) calculas el costo mensual con las tarifas publicadas del proveedor y la
    fecha en que las consultaste.

---

## 📚 7. Referencias

**Documentación oficial**

- Slack, webhooks entrantes: https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks/
- Telegram Bot API: https://core.telegram.org/bots/api
- Twilio, mensajes de WhatsApp con plantillas: https://www.twilio.com/docs/whatsapp/tutorial/send-whatsapp-notification-messages-templates
- Ley 1581 de 2012 (habeas data), en el gestor normativo de Función Pública:
  https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=49981

**Orden de lectura sugerido:** la página de Twilio sobre plantillas de WhatsApp, porque cambia cómo
diseñas el recordatorio; después la de webhooks de Slack, que se lee en dos minutos; y la Ley 1581
con alguien del área legal, no solo.

---

## 🚀 8. Cierre

Notificar es fácil; notificar a pacientes es una decisión legal escrita en código. Un notificador por
canal, la misma prueba para todos, y la frontera —consentimiento, plantilla, ningún dato clínico—
dentro de la función que manda, no en la memoria de quien la usa.

**La señal de que quedó bien:** *"Un paciente retiró su autorización y no recibió ningún recordatorio
más, sin que nadie tuviera que acordarse."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-co-fase-06 -m "op co06 cerrada: notificador con frontera de consentimiento"
> ```
>
> Los commits llevan su prefijo (`op co06: …`) y los de ejercicio su número
> (`op co06 ej07: …`).
