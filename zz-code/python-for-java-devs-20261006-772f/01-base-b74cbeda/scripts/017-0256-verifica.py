# rescatado de la sesión b74cbeda, 2026-09-13T02:56:11Z · Verify Django row permissions and audit work
import os, django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "consultorio.settings")
django.setup()
from django.contrib.auth.models import User
from django.test import Client
from planes.models import Branch, Profile, TreatmentPlan, AccessLog
from datetime import date
from decimal import Decimal

for n in ["Centro","Suba","Chapinero"]: Branch.objects.get_or_create(name=n)
suba = Branch.objects.get(name="Suba"); centro = Branch.objects.get(name="Centro")
for i in range(20):
    TreatmentPlan.objects.get_or_create(patient_document=str(10000000+i), defaults=dict(
        patient_name=f"Paciente {i}", branch=suba if i%2 else centro,
        opened_on=date(2026,3,1), total_amount=Decimal("12000000"),
        clinical_note="Apiñamiento severo, clase II"))
julian, _ = User.objects.get_or_create(username="julian", defaults={"is_staff":True,"is_superuser":True})
julian.set_password("x"); julian.save()
edgar, _ = User.objects.get_or_create(username="edgar", defaults={"is_staff":True})
edgar.set_password("x"); edgar.save()
Profile.objects.get_or_create(user=edgar, defaults={"branch": suba})
from django.contrib.auth.models import Permission
edgar.user_permissions.set(Permission.objects.filter(content_type__app_label="planes"))

c = Client()
c.login(username="julian", password="x")
r = c.get("/admin/planes/treatmentplan/")
print("Julián (superusuario) ve:", r.content.decode().count("Paciente"), "menciones · status", r.status_code)
c2 = Client(); c2.login(username="edgar", password="x")
r2 = c2.get("/admin/planes/treatmentplan/")
body = r2.content.decode()
print("Édgar ve:", body.count("Paciente"), "menciones · status", r2.status_code)
plan_centro = TreatmentPlan.objects.filter(branch=centro).first()
r3 = c2.get(f"/admin/planes/treatmentplan/{plan_centro.id}/change/?motivo=revision")
print("Édgar abriendo un plan de Centro:", r3.status_code, "(302/404 = no puede)")
print("accesos auditados:", AccessLog.objects.count())
plan_suba = TreatmentPlan.objects.filter(branch=suba).first()
r4 = c2.get(f"/admin/planes/treatmentplan/{plan_suba.id}/change/?motivo=revision+de+regalias")
print("Édgar abriendo uno de Suba:", r4.status_code, "· ¿ve la nota clínica?", "clinical_note" in r4.content.decode() or "nota clínica" in r4.content.decode())
print("accesos auditados ahora:", AccessLog.objects.count(), "·", AccessLog.objects.last().reason if AccessLog.objects.exists() else "")
