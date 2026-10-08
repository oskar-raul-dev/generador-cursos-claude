"""Lee el aviso de estudio listo en HL7 v2 y lo convierte en un DiagnosticReport de FHIR."""

import datetime as dt
from zoneinfo import ZoneInfo

import hl7
from fhir.resources.diagnosticreport import DiagnosticReport

# HL7 v2 casi nunca manda la zona horaria: la hora es la local del emisor, y hay que saber cuál es.
SENDER_ZONE = ZoneInfo("America/Bogota")

MESSAGE = "\r".join([
    "MSH|^~\\&|RXCENTRO|ALIADO-07|AUREA|CENTRO|202609281015||ORU^R01^ORU_R01|MSG000183|P|2.5.1",
    "PID|1||CC1023456789^^^RNEC^CC||PEREZ^ANA^MARIA||19880214|F",
    "OBR|1|REM-4411|EST-88213|PAN^Radiografía panorámica^L|||202609280930",
    "OBX|1|TX|INFORME^Informe^L||Sin hallazgos patológicos.||||||F",
])


def parse_hl7_timestamp(value: str) -> dt.datetime:
    # HL7 v2 permite precisión variable (AAAA, AAAAMM, AAAAMMDD, AAAAMMDDHHMM…) y un desplazamiento
    # opcional al final, que casi nadie manda. Si no viene, la hora es la del emisor.
    formats = {4: "%Y", 6: "%Y%m", 8: "%Y%m%d", 12: "%Y%m%d%H%M", 14: "%Y%m%d%H%M%S"}
    digits = value.split("+")[0].split("-")[0]
    naive = dt.datetime.strptime(digits, formats[len(digits)])
    return naive.replace(tzinfo=SENDER_ZONE)


def to_report(message: hl7.Message) -> DiagnosticReport:
    msh = message.segment("MSH")
    if str(msh[9][0][0]) != "ORU":
        raise ValueError(f"se esperaba un ORU y llegó {msh[9]}")
    pid = message.segment("PID")
    obr = message.segment("OBR")
    document = str(pid[3][0][0])           # CC1023456789: el identificador, sin el resto
    study_code = str(obr[4][0][0])         # PAN
    study_name = str(obr[4][0][1])         # Radiografía panorámica
    observed = parse_hl7_timestamp(str(obr[7]))
    conclusion = " ".join(str(obx[5]) for obx in message.segments("OBX"))

    return DiagnosticReport.model_validate({
        "resourceType": "DiagnosticReport",
        "status": "final",
        "code": {"coding": [{"system": "urn:aurea:estudios", "code": study_code}],
                 "text": study_name},
        # La referencia al paciente va por identificador, no por nombre: el nombre no viaja.
        "subject": {"identifier": {"system": "urn:co:rnec:cc", "value": document}},
        "effectiveDateTime": observed.isoformat(),
        "conclusion": conclusion,
        "identifier": [{"system": "urn:aliado-07:estudios", "value": str(obr[3])}],
    })


if __name__ == "__main__":
    message = hl7.parse(MESSAGE)
    print("evento:", message.segment("MSH")[9])
    report = to_report(message)
    print(report.model_dump_json(indent=2, exclude_none=True))
