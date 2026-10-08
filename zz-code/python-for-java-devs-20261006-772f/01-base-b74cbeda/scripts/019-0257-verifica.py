# rescatado de la sesión b74cbeda, 2026-09-13T02:57:44Z · Verify the FastAPI back-office
from datetime import date
from decimal import Decimal
import hashlib, pathlib
pathlib.Path("backoffice.sqlite3").unlink(missing_ok=True)
from models import Base, engine, SessionFactory, Branch, User, TreatmentPlan, AccessLog
Base.metadata.create_all(engine)
h = lambda s: hashlib.sha256(s.encode()).hexdigest()
with SessionFactory() as s:
    centro, suba = Branch(name="Centro"), Branch(name="Suba")
    s.add_all([centro, suba]); s.flush()
    s.add(User(username="julian", password_hash=h("x"), is_superuser=True))
    s.add(User(username="edgar", password_hash=h("x"), branch_id=suba.id))
    for i in range(20):
        s.add(TreatmentPlan(patient_document=str(10000000+i), patient_name=f"Paciente {i}",
              branch_id=suba.id if i%2 else centro.id, opened_on=date(2026,3,1),
              total_amount=Decimal("12000000"), clinical_note="Apiñamiento severo, clase II"))
    s.commit()

from fastapi.testclient import TestClient
import app as A
c = TestClient(A.app)
c.post("/login", data={"username":"julian","password":"x"}, follow_redirects=False)
r = c.get("/plans"); print("Julián ve:", r.text.count("Paciente "), "planes ·", r.status_code)
c2 = TestClient(A.app)
c2.post("/login", data={"username":"edgar","password":"x"}, follow_redirects=False)
r2 = c2.get("/plans"); print("Édgar ve:", r2.text.count("Paciente "), "planes ·", r2.status_code)
with SessionFactory() as s:
    from sqlalchemy import select
    centro_id = s.scalar(select(Branch.id).where(Branch.name=="Centro"))
    pc = s.scalar(select(TreatmentPlan).where(TreatmentPlan.branch_id==centro_id))
    ps = s.scalar(select(TreatmentPlan).where(TreatmentPlan.branch_id!=centro_id))
    pc_id, ps_id = pc.id, ps.id
print("Édgar abre uno de Centro ->", c2.get(f"/plans/{pc_id}").status_code)
r4 = c2.get(f"/plans/{ps_id}?motivo=revision+de+regalias")
print("Édgar abre uno de Suba ->", r4.status_code, "· ¿nota clínica?", "Apiñamiento" in r4.text)
r5 = c.get(f"/plans/{ps_id}?motivo=auditoria")
print("Julián abre el mismo -> ¿nota?", "Apiñamiento" in r5.text)
with SessionFactory() as s:
    from sqlalchemy import func, select as sel
    print("accesos auditados:", s.scalar(sel(func.count()).select_from(AccessLog)))
