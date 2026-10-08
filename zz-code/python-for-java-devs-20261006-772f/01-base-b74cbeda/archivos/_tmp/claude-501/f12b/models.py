"""Modelos del back-office."""

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import ForeignKey, Numeric, create_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker


class Base(DeclarativeBase):
    pass


class Branch(Base):
    __tablename__ = "branches"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(unique=True)


class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(unique=True)
    password_hash: Mapped[str]
    is_superuser: Mapped[bool] = mapped_column(default=False)
    branch_id: Mapped[int | None] = mapped_column(ForeignKey("branches.id"))


class TreatmentPlan(Base):
    __tablename__ = "treatment_plans"
    id: Mapped[int] = mapped_column(primary_key=True)
    patient_document: Mapped[str] = mapped_column(index=True)
    patient_name: Mapped[str]
    branch_id: Mapped[int] = mapped_column(ForeignKey("branches.id"))
    opened_on: Mapped[date]
    total_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    status: Mapped[str] = mapped_column(default="open")
    clinical_note: Mapped[str] = mapped_column(default="")


class AccessLog(Base):
    __tablename__ = "access_log"
    id: Mapped[int] = mapped_column(primary_key=True)
    actor_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    at: Mapped[datetime] = mapped_column(default=datetime.now)
    action: Mapped[str]
    plan_id: Mapped[int] = mapped_column(ForeignKey("treatment_plans.id"))
    reason: Mapped[str]


engine = create_engine("sqlite:///backoffice.sqlite3")
SessionFactory = sessionmaker(engine)
