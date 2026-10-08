"""El back-office en FastAPI: el mismo CRUD con permisos por fila y auditoría."""

import hashlib
from collections.abc import Iterator
from datetime import date
from decimal import Decimal
from typing import Annotated

from fastapi import Depends, FastAPI, Form, HTTPException, Request, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.orm import Session
from starlette.middleware.sessions import SessionMiddleware

from models import AccessLog, Branch, SessionFactory, TreatmentPlan, User

app = FastAPI()
app.add_middleware(SessionMiddleware, secret_key="cambiar-en-produccion")
templates = Jinja2Templates(directory="templates")


def get_session() -> Iterator[Session]:
    with SessionFactory() as session:
        yield session


def hash_password(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()


def current_user(request: Request,
                 session: Annotated[Session, Depends(get_session)]) -> User:
    user_id = request.session.get("user_id")
    if user_id is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "hay que iniciar sesión")
    user = session.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "sesión inválida")
    return user


CurrentUser = Annotated[User, Depends(current_user)]
DbSession = Annotated[Session, Depends(get_session)]


@app.get("/login", response_class=HTMLResponse)
def login_form(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(request, "login.html", {})


@app.post("/login")
def login(request: Request, session: DbSession,
          username: Annotated[str, Form()], password: Annotated[str, Form()]) -> RedirectResponse:
    user = session.scalar(select(User).where(User.username == username))
    if user is None or user.password_hash != hash_password(password):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "usuario o contraseña incorrectos")
    request.session["user_id"] = user.id
    return RedirectResponse("/plans", status_code=303)


@app.get("/logout")
def logout(request: Request) -> RedirectResponse:
    request.session.clear()
    return RedirectResponse("/login", status_code=303)


def visible_plans(user: User):
    """El permiso por fila. Tiene que aplicarse en TODAS las consultas."""
    stmt = select(TreatmentPlan)
    if not user.is_superuser:
        if user.branch_id is None:
            return stmt.where(False)
        stmt = stmt.where(TreatmentPlan.branch_id == user.branch_id)
    return stmt


@app.get("/plans", response_class=HTMLResponse)
def list_plans(request: Request, user: CurrentUser, session: DbSession,
               q: str = "", branch_id: int | None = None) -> HTMLResponse:
    stmt = visible_plans(user)
    if q:
        stmt = stmt.where(TreatmentPlan.patient_name.contains(q))
    if branch_id:
        stmt = stmt.where(TreatmentPlan.branch_id == branch_id)
    plans = session.scalars(stmt.order_by(TreatmentPlan.opened_on.desc())).all()
    branches = session.scalars(select(Branch)).all()
    return templates.TemplateResponse(
        request, "list.html",
        {"plans": plans, "branches": branches, "user": user, "q": q})


@app.get("/plans/{plan_id}", response_class=HTMLResponse)
def edit_form(request: Request, plan_id: int, user: CurrentUser, session: DbSession,
              motivo: str = "consulta administrativa") -> HTMLResponse:
    plan = session.scalar(visible_plans(user).where(TreatmentPlan.id == plan_id))
    if plan is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "no existe o no tiene acceso")
    session.add(AccessLog(actor_id=user.id, action="view", plan_id=plan_id, reason=motivo))
    session.commit()
    branches = session.scalars(select(Branch)).all()
    return templates.TemplateResponse(
        request, "edit.html",
        {"plan": plan, "branches": branches, "user": user,
         "show_note": user.is_superuser})


@app.post("/plans/{plan_id}")
def save_plan(request: Request, plan_id: int, user: CurrentUser, session: DbSession,
              patient_name: Annotated[str, Form()],
              patient_document: Annotated[str, Form()],
              branch_id: Annotated[int, Form()],
              opened_on: Annotated[date, Form()],
              total_amount: Annotated[Decimal, Form()],
              status_value: Annotated[str, Form(alias="status")]) -> RedirectResponse:
    plan = session.scalar(visible_plans(user).where(TreatmentPlan.id == plan_id))
    if plan is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "no existe o no tiene acceso")
    if not user.is_superuser and branch_id != user.branch_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "no puede mover un plan a otra sede")
    plan.patient_name = patient_name
    plan.patient_document = patient_document
    plan.branch_id = branch_id
    plan.opened_on = opened_on
    plan.total_amount = total_amount
    plan.status = status_value
    session.add(AccessLog(actor_id=user.id, action="edit", plan_id=plan_id,
                          reason="edición desde el back-office"))
    session.commit()
    return RedirectResponse("/plans", status_code=303)


@app.post("/plans/{plan_id}/delete")
def delete_plan(plan_id: int, user: CurrentUser, session: DbSession) -> RedirectResponse:
    plan = session.scalar(visible_plans(user).where(TreatmentPlan.id == plan_id))
    if plan is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "no existe o no tiene acceso")
    session.delete(plan)
    session.commit()
    return RedirectResponse("/plans", status_code=303)
