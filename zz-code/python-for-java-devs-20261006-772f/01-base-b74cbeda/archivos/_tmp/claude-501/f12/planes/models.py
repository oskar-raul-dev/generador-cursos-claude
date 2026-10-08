"""El back-office del plan de tratamiento."""

from django.conf import settings
from django.db import models


class Branch(models.Model):
    name = models.CharField("sede", max_length=40, unique=True)

    class Meta:
        verbose_name, verbose_name_plural = "sede", "sedes"

    def __str__(self) -> str:
        return self.name


class TreatmentPlan(models.Model):
    """Un plan de Arquitectura de Sonrisa."""

    STATUS = [("open", "Abierto"), ("done", "Terminado"), ("cancelled", "Cancelado")]

    patient_document = models.CharField("documento del paciente", max_length=12, db_index=True)
    patient_name = models.CharField("paciente", max_length=120)
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, verbose_name="sede")
    opened_on = models.DateField("fecha de apertura")
    total_amount = models.DecimalField("valor total", max_digits=14, decimal_places=2)
    status = models.CharField("estado", max_length=12, choices=STATUS, default="open")
    clinical_note = models.TextField("nota clínica", blank=True)

    class Meta:
        verbose_name, verbose_name_plural = "plan de tratamiento", "planes de tratamiento"
        ordering = ["-opened_on"]

    def __str__(self) -> str:
        return f"{self.patient_name} · {self.branch}"


class AccessLog(models.Model):
    """Auditoría de accesos: requisito legal, no mejora."""

    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    at = models.DateTimeField(auto_now_add=True, db_index=True)
    action = models.CharField(max_length=16)
    plan = models.ForeignKey(TreatmentPlan, on_delete=models.PROTECT)
    reason = models.CharField("motivo del acceso", max_length=120)

    class Meta:
        verbose_name, verbose_name_plural = "acceso a historia", "accesos a historia"


class Profile(models.Model):
    """A qué sede pertenece cada usuario. Édgar ve Suba y nada más."""

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, null=True, blank=True)
