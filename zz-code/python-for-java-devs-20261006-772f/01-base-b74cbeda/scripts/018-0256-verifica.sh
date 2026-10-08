# rescatado de la sesión b74cbeda, 2026-09-13T02:56:34Z · Verify Django permissions and audit
cd /tmp/claude-501/f12 && ./.venv/bin/python - <<'EOF' 2>&1 | grep -v "^Invalid\|^Traceback\|^  File\|^    \|^django.core"
import os, django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "consultorio.settings")
django.setup()
from django.contrib.auth.models import User, Permission
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
edgar.user_permissions.set(Permission.objects.filter(content_type__app_label="planes"))

c = Client(); c.login(username="julian", password="x")
r = c.get("/admin/planes/treatmentplan/")
print("Julián (superusuario) ve:", r.content.decode().count("Paciente "), "planes · status", r.status_code)
c2 = Client(); c2.login(username="edgar", password="x")
r2 = c2.get("/admin/planes/treatmentplan/")
print("Édgar (Suba) ve:", r2.content.decode().count("Paciente "), "planes · status", r2.status_code)
plan_centro = TreatmentPlan.objects.filter(branch=centro).first()
r3 = c2.get(f"/admin/planes/treatmentplan/{plan_centro.id}/change/?motivo=revision")
print("Édgar abre un plan de Centro ->", r3.status_code)
plan_suba = TreatmentPlan.objects.filter(branch=suba).first()
r4 = c2.get(f"/admin/planes/treatmentplan/{plan_suba.id}/change/?motivo=revision+de+regalias")
b = r4.content.decode()
print("Édgar abre uno de Suba ->", r4.status_code, "· ¿aparece la nota clínica?", "Apiñamiento" in b)
r5 = c.get(f"/admin/planes/treatmentplan/{plan_suba.id}/change/?motivo=auditoria")
print("Julián abre el mismo -> ¿ve la nota?", "Apiñamiento" in r5.content.decode())
print("accesos auditados:", AccessLog.objects.count())
for a in AccessLog.objects.all()[:3]: print("   ", a.actor.username, a.action, a.plan_id, a.reason)
EOF
