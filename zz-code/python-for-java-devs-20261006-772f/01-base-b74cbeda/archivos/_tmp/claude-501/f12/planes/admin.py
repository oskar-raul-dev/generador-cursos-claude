"""El admin, con permisos por fila y auditoría."""

from django.contrib import admin

from .models import AccessLog, Branch, Profile, TreatmentPlan


@admin.register(TreatmentPlan)
class TreatmentPlanAdmin(admin.ModelAdmin):
    list_display = ["patient_name", "patient_document", "branch", "opened_on", "total_amount", "status"]
    list_filter = ["branch", "status", "opened_on"]
    search_fields = ["patient_name", "patient_document"]
    date_hierarchy = "opened_on"

    def get_queryset(self, request):
        """El permiso por fila: cada quien ve su sede. Y va aquí, no en la vista."""
        queryset = super().get_queryset(request)
        if request.user.is_superuser:
            return queryset
        branch = getattr(getattr(request.user, "profile", None), "branch", None)
        return queryset.filter(branch=branch) if branch else queryset.none()

    def get_exclude(self, request, obj=None):
        """La nota clínica solo la ve quien tiene relación asistencial."""
        if request.user.is_superuser:
            return []
        return ["clinical_note"]

    def change_view(self, request, object_id, form_url="", extra_context=None):
        """Cada acceso a un plan queda registrado: quién, cuándo y por qué."""
        AccessLog.objects.create(
            actor=request.user, action="view", plan_id=object_id,
            reason=request.GET.get("motivo", "consulta administrativa"),
        )
        return super().change_view(request, object_id, form_url, extra_context)


@admin.register(AccessLog)
class AccessLogAdmin(admin.ModelAdmin):
    list_display = ["at", "actor", "action", "plan", "reason"]
    list_filter = ["action", "at"]
    readonly_fields = ["actor", "at", "action", "plan", "reason"]

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


admin.site.register(Branch)
admin.site.register(Profile)
