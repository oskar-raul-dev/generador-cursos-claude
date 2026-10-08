# Lo que cuesta la segunda entidad en FastAPI: modelo + 3 rutas + 2 plantillas.

class Consent(Base):
    __tablename__ = "consents"
    id: Mapped[int] = mapped_column(primary_key=True)
    plan_id: Mapped[int] = mapped_column(ForeignKey("treatment_plans.id"))
    phase_kind: Mapped[str]
    signed_on: Mapped[date | None]
    document_ref: Mapped[str] = mapped_column(default="")


def visible_consents(user: User):
    stmt = select(Consent).join(TreatmentPlan, TreatmentPlan.id == Consent.plan_id)
    if not user.is_superuser:
        if user.branch_id is None:
            return stmt.where(False)
        stmt = stmt.where(TreatmentPlan.branch_id == user.branch_id)
    return stmt


@app.get("/consents", response_class=HTMLResponse)
def list_consents(request: Request, user: CurrentUser, session: DbSession,
                  q: str = "", phase_kind: str = "") -> HTMLResponse:
    stmt = visible_consents(user)
    if q:
        stmt = stmt.where(Consent.document_ref.contains(q))
    if phase_kind:
        stmt = stmt.where(Consent.phase_kind == phase_kind)
    consents = session.scalars(stmt.order_by(Consent.signed_on.desc())).all()
    return templates.TemplateResponse(
        request, "consents_list.html", {"consents": consents, "user": user, "q": q})


@app.get("/consents/{consent_id}", response_class=HTMLResponse)
def edit_consent_form(request: Request, consent_id: int, user: CurrentUser,
                      session: DbSession) -> HTMLResponse:
    consent = session.scalar(visible_consents(user).where(Consent.id == consent_id))
    if consent is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "no existe o no tiene acceso")
    return templates.TemplateResponse(
        request, "consents_edit.html", {"consent": consent, "user": user})


@app.post("/consents/{consent_id}")
def save_consent(consent_id: int, user: CurrentUser, session: DbSession,
                 phase_kind: Annotated[str, Form()],
                 signed_on: Annotated[date | None, Form()] = None,
                 document_ref: Annotated[str, Form()] = "") -> RedirectResponse:
    consent = session.scalar(visible_consents(user).where(Consent.id == consent_id))
    if consent is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "no existe o no tiene acceso")
    consent.phase_kind = phase_kind
    consent.signed_on = signed_on
    consent.document_ref = document_ref
    session.commit()
    return RedirectResponse("/consents", status_code=303)
