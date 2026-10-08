# 🏛️ Fase 12 — Django y el veredicto web

> Python para desarrolladores Java senior · Fase 12 de 18 · Bloque C
> Depende de: Fase 11 · Habilita: Fase 13
> Registro de esta fase: **aplicación**
> Proyecto que avanza: **nace Consultorio**, el back-office
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Que la comparación entre los dos registros web sea una **decisión vivida** y no un párrafo leído.

Llevas dos fases con FastAPI y te ha ido bien. Esta fase construye la misma cosa con Django y pone
los dos resultados al lado, medidos. Y el veredicto que sale de ahí tiene un criterio explícito
que conviene adelantar porque ordena la lectura entera:

> ⚖️ **Son dos registros, no dos calidades.** Si al terminar esta fase te queda la impresión de
> que uno es mejor que el otro, la fase está mal escrita — o la leíste buscando quién gana.

Y nace el proyecto 3: **Consultorio**, el back-office. Cuarenta pantallas, permisos por sede, y
auditoría de accesos que en Áurea no es una mejora: es un requisito legal.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Consultorio corre: alguien entra con su usuario y administra planes de tratamiento.
- [ ] Édgar ve Suba y **solo** Suba — en la lista, en el detalle, en la búsqueda y en la
      exportación.
- [ ] Cada acceso a un dato de paciente queda registrado: quién, cuándo y por qué.
- [ ] Puedes explicar qué hace el admin de Django y por qué no tiene equivalente en la
      conversación que traes de Java.
- [ ] Tienes el veredicto escrito, con **tus** números, sobre cuándo elegir cada registro.
- [ ] Sabes nombrar tres cosas que Django te da bien y que tú habrías escrito mal.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Un frontend propio** —React, Vue, lo que sea—. **No hay equipo de frontend en Áurea, y esa
  restricción es parte del problema**, no una limitación del curso: la solución tiene que poder
  mantenerla una persona que además hace todo lo demás.
- **Django REST Framework.** Áurea ya tiene su API en FastAPI; montar una segunda API en Django
  sería duplicar sin necesidad, y comparar frameworks de API no es el tema de esta fase.
- **Integraciones salientes** → Fase 13. **Concurrencia** → Fase 14. **Despliegue y
  observabilidad** → Fase 16.
- **Personalizar el admin más allá de lo que Áurea necesita.** El admin tiene un límite y esta
  fase lo declara en §5.6 en vez de fingir que no existe.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** elegir el framework por rendimiento.

Es el criterio con el que se discute esto en casi todas las reuniones de arquitectura, y aquí es
el equivocado. Lo que decide entre FastAPI y Django para Áurea **no es cuántas peticiones por
segundo aguanta cada uno**: es cuántas pantallas hay que escribir y quién las va a mantener
cuando tú no estés.

Y hay una razón concreta por la que este perfil llega con ese criterio y le falla: **en el mundo
de Java no existe el admin de Django.** No hay un equivalente. Spring Boot no trae uno, Jakarta EE
no trae uno, y lo más parecido —un generador de *scaffolding*— produce código que hay que
mantener. Como la categoría no existe en tu experiencia, el reflejo natural es **subestimarla**:
suena a "una pantallita de administración para el desarrollador", y entonces la conversación se va
a lo que sí conoces, que es el rendimiento.

Lo que el admin es de verdad: **un back-office completo, generado desde los modelos, con listado,
filtros, búsqueda, formularios validados, permisos por objeto, historial de cambios, acciones
masivas y CSRF** — y todo eso sigue funcionando cuando agregas el modelo número cuarenta y uno.

La sección 6 lo mide: la primera pantalla cuesta **76 líneas contra 204**, y —lo que de verdad
decide— la pantalla siguiente cuesta **23 líneas contra 70**.

**Qué se escribe en su lugar, como criterio:**

> 🧭 **Pregunta cuántas pantallas vas a escribir y quién las va a mantener.** Si la respuesta es
> "cuarenta, y yo solo", eso decide. Si la respuesta es "ninguna, esto lo consume un bot", eso
> decide en la otra dirección. El rendimiento decide en un tercer caso, y hay que reconocerlo
> cuando aparece.

### Los dos registros web, con nombre

Vale la pena nombrar lo que separa a los dos, porque no es una lista de características:

**El registro *servicio*** —FastAPI— produce datos para que **otro programa** los consuma. El
cliente es la web de Áurea, el bot de WhatsApp, un proceso nocturno. El contrato es JSON, la
frontera es un esquema, y la interfaz gráfica es problema de otro. Es lo que construiste en las
Fases 10 y 11.

**El registro *aplicación con baterías*** —Django— produce **pantallas para que las use una
persona**. El cliente es Patricia. El contrato es HTML, la frontera es un formulario, y viene con
todo lo que una aplicación necesita y nadie quiere escribir: sesiones, autenticación, permisos,
CSRF, paginación, mensajes, internacionalización, y el admin.

**El error no es elegir mal: es no darse cuenta de que son dos preguntas distintas.** Áurea
necesita los dos, y por eso el curso construye los dos.

### Esto sí funciona igual

**Django es el framework más parecido a lo que ya conoces**, y conviene decirlo porque quita
ansiedad: proyecto con configuración central, aplicaciones que se registran, un ORM con
migraciones, un sistema de plantillas, middleware, y una separación explícita entre petición,
vista y respuesta. Si vienes de Spring MVC con JPA, esto se lee solo.

**El ORM es un ORM.** Consultas perezosas —aquí sí las hay, y son perezosas de verdad—,
relaciones, `select_related` y `prefetch_related` que son los `JOIN FETCH` y los `selectinload`
de la Fase 11 con otro nombre.

**Las migraciones son migraciones**, y las genera el framework comparando los modelos con el
estado anterior. Es Alembic integrado y con menos ceremonia.

**Y el sistema de permisos es el de siempre:** usuarios, grupos, permisos por modelo y por acción.
Lo que Áurea necesita —permisos **por fila**— no viene incluido en ningún framework, aquí tampoco,
y es exactamente el trabajo del miniproyecto.

### Diccionario de traducción

| Java / Spring | Python / Django | Dónde se rompe el paralelo |
|---|---|---|
| `application.properties` | `settings.py` | Es un módulo de Python: puede tener lógica, y eso es bueno y peligroso |
| Módulo Maven / paquete | *app* de Django | Una *app* es una unidad reutilizable con sus modelos, vistas y migraciones |
| JPA / Hibernate | el ORM de Django | Más opinado y más integrado; **sí tiene carga perezosa automática**, al revés que SQLAlchemy |
| `@Entity` | `models.Model` | Los campos son objetos con validación y etiqueta incluidas |
| Flyway | `makemigrations` / `migrate` | Generadas desde los modelos, versionadas por *app* |
| `@Controller` + JSP/Thymeleaf | vista + plantilla | Igual |
| Spring Security | `django.contrib.auth` | Incluido, con usuarios, grupos y permisos ya modelados |
| — | **el admin** | **No tiene equivalente.** Es la diferencia grande |
| `@PreAuthorize` | decoradores y *mixins* de permisos | Similar; el permiso **por fila** no viene en ninguno |
| Bean Validation | validación del campo y del formulario | Está en el modelo y en el formulario, no en una anotación aparte |
| CSRF de Spring Security | middleware de CSRF | Activo por defecto. **En FastAPI lo escribes tú** |
| Hibernate Envers | `LogEntry` del admin, o lo escribes | El admin registra sus propios cambios; la auditoría de **lecturas** la escribes tú |

> 📝 **Nota de ecosistema — Django no es monolítico por accidente.** Nació en 2005 en un periódico,
> para que un equipo pequeño publicara muchas pantallas rápido, y esa decisión sigue explicando
> todo: trae baterías porque el caso de uso era "un equipo chico con mucho que administrar". Las
> alternativas del ecosistema —Flask, FastAPI— nacieron de la posición contraria: un núcleo mínimo
> y tú eliges todo. Las dos posiciones son legítimas, tienen veinte años de discusión encima, y la
> pregunta *"¿cuál es mejor?"* nunca ha tenido respuesta porque está mal formulada.

### El permiso por fila, que es el problema de verdad

Áurea tiene una restricción que ningún framework trae resuelta: **Édgar ve Suba y nada más**. No
es un permiso sobre el modelo —"puede ver planes"— sino sobre **qué filas** de ese modelo.

Y el error que produce el reflejo es ponerlo en la vista:

```python
# ❌ El permiso en la vista: funciona, y deja tres puertas abiertas
def plan_list(request):
    plans = TreatmentPlan.objects.filter(branch=request.user.profile.branch)
    return render(request, "plans.html", {"plans": plans})
```

Eso protege **esa** pantalla. Y quedan sin proteger: el admin, cualquier reporte, la exportación a
CSV, la búsqueda, el endpoint de la API que alguien agregue el mes que viene, y el `shell` de
Django. **La fuga no se cuela por la pantalla que revisaste: se cuela por la que no.**

> 🧭 **El permiso por fila se pone en el punto más cercano a los datos que puedas**, y se repite
> ahí una sola vez. En Django eso es el `get_queryset` del admin y un *manager* del modelo; en
> FastAPI, una función que construye la consulta base y que **toda** consulta tiene que usar. Es
> la misma idea de la Fase 10 —las reglas que protegen datos van donde las ven todas las puertas—
> con consecuencias legales.

---

## 💻 5. Código mínimo con comentarios

### 5.1 Los modelos

```python
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
    # Historia clínica: reservada. Quién la ve se decide en el admin (§5.3).
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


class Profile(models.Model):
    """A qué sede pertenece cada usuario. Édgar ve Suba y nada más."""

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, null=True, blank=True)
```

**Detalles con intención**

- **Las etiquetas en español van en el modelo**, como primer argumento del campo. De ahí salen las
  etiquetas de los formularios, las cabeceras de las tablas y los mensajes de error. Escribirlas
  aquí es escribir la interfaz una vez.
- **`Meta.verbose_name` en singular y plural**, porque el español lo necesita: sin eso, Django
  muestra "plan de tratamientos".
- **`DecimalField` con `max_digits` y `decimal_places`**, nunca `FloatField`. Misma regla de la
  Fase 01, ahora por tercera vez.
- **`on_delete=PROTECT` en la auditoría.** Un registro de acceso que desaparece porque alguien
  borró el plan deja de ser una auditoría. Es una decisión legal disfrazada de parámetro.
- **Y el `Profile` existe porque el usuario de Django no tiene sede.** Es la forma canónica de
  extenderlo sin reemplazarlo.

### 5.2 El admin, y lo que trae gratis

```python
"""El admin, con permisos por fila y auditoría."""

from django.contrib import admin

from .models import AccessLog, Branch, Profile, TreatmentPlan


@admin.register(TreatmentPlan)
class TreatmentPlanAdmin(admin.ModelAdmin):
    list_display = ["patient_name", "patient_document", "branch",
                    "opened_on", "total_amount", "status"]
    list_filter = ["branch", "status", "opened_on"]
    search_fields = ["patient_name", "patient_document"]
    date_hierarchy = "opened_on"
```

**Esas cinco líneas producen**: una tabla ordenable, filtros laterales por sede, estado y fecha,
un buscador, una navegación por año/mes/día, paginación, formularios de creación y edición con
validación y etiquetas en español, borrado con confirmación, acciones masivas, y protección CSRF.

Es el punto que no se transmite leyéndolo. **Córrelo antes de seguir**, porque el resto de la fase
depende de que hayas visto lo que sale de ahí:

```bash
uv run python manage.py createsuperuser
uv run python manage.py runserver
# y abre http://localhost:8000/admin/
```

### 5.3 El permiso por fila y la auditoría

Esto es lo que Áurea necesita y ningún framework trae:

```python
@admin.register(TreatmentPlan)
class TreatmentPlanAdmin(admin.ModelAdmin):
    ...

    def get_queryset(self, request):
        """El permiso por fila.

        Va aquí y no en una vista: TODO lo que el admin hace —la lista, el
        detalle, la búsqueda, los filtros, las acciones masivas y la
        exportación— pasa por este método. Una sola puerta.
        """
        queryset = super().get_queryset(request)
        if request.user.is_superuser:
            return queryset
        branch = getattr(getattr(request.user, "profile", None), "branch", None)
        # Sin sede asignada no se ve nada. El valor por defecto es negar.
        return queryset.filter(branch=branch) if branch else queryset.none()

    def get_exclude(self, request, obj=None):
        """La nota clínica solo la ve quien tiene relación asistencial.

        Excluirla del formulario la saca del HTML y del POST: no se puede leer
        ni escribir. Es la misma regla del modelo de salida de la Fase 10.
        """
        if request.user.is_superuser:
            return []
        return ["clinical_note"]

    def change_view(self, request, object_id, form_url="", extra_context=None):
        """Cada acceso a un plan queda registrado: quién, cuándo y por qué."""
        AccessLog.objects.create(
            actor=request.user,
            action="view",
            plan_id=object_id,
            reason=request.GET.get("motivo", "consulta administrativa"),
        )
        return super().change_view(request, object_id, form_url, extra_context)


@admin.register(AccessLog)
class AccessLogAdmin(admin.ModelAdmin):
    """La auditoría se lee y no se toca. Ni siquiera por el superusuario."""

    list_display = ["at", "actor", "action", "plan", "reason"]
    list_filter = ["action", "at"]
    readonly_fields = ["actor", "at", "action", "plan", "reason"]

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
```

**Prueba de fuego**, y hay que correrla porque es el criterio de aceptación del miniproyecto:

```text
Julián (superusuario) ve:  20 planes
Édgar (Suba) ve:           10 planes
Édgar abre un plan de Centro   ->  302 (redirigido: no existe para él)
Édgar abre uno de Suba         ->  200 · ¿aparece la nota clínica? False
Julián abre el mismo           ->  ¿ve la nota? True
accesos auditados: 3
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **que Édgar vea 10 planes
en la lista no significa que no pueda ver los otros**. La lista está filtrada; lo que hay que
comprobar es el acceso **directo por URL** a un plan que no es suyo — ese `302` de la tercera
línea. Un permiso por fila que solo filtra la lista es un permiso que no existe.

### 5.4 Lo que Django hace bien y tú harías mal

Tres cosas concretas, y la primera la descubrí escribiendo la comparación de la sección 6:

**Las contraseñas.** La versión en FastAPI de §6 guarda el hash con `sha256`, que es lo que sale
solo si no te detienes a pensarlo, y **está mal**: SHA-256 es rápido a propósito, así que un
ataque por diccionario contra la base robada va a mil millones de intentos por segundo. Lo
correcto es un algoritmo lento y con sal —PBKDF2, bcrypt, Argon2—. Django usa **PBKDF2 con sal y
600.000 iteraciones** por defecto, migra automáticamente los hashes viejos cuando cambias de
algoritmo, y no te pide opinión. Tú no ibas a hacer eso en 204 líneas.

**El CSRF.** Está activo por defecto en todos los formularios. La versión de FastAPI de §6 **no lo
tiene**, y eso no aparece en el conteo de líneas: son líneas que faltan, no que sobran.

**Y el manejo de `None` en las plantillas, la paginación, los mensajes al usuario y la
internacionalización de la interfaz.** Tres de esas cuatro las habrías escrito; la cuarta la
habrías pospuesto.

> ⚠️ **Ese es el sesgo que hay que corregir al leer cualquier comparación de líneas de código,
> incluida la de la sección 6:** las líneas que no escribiste porque el framework las trae no
> aparecen en ninguna de las dos columnas. Y algunas de ellas son las que te protegen.

### 5.5 Consultorio y AgendaAPI, conviviendo

Dos aplicaciones, dos frameworks, **una base de datos**. Y eso funciona, con una regla:

> 🧭 **Una sola aplicación es dueña del esquema.** En Áurea, las migraciones las manda Django —que
> es quien tiene el modelo más completo del dominio administrativo— y AgendaAPI mapea las tablas
> con SQLAlchemy sin generarlas. Dos sistemas de migraciones sobre las mismas tablas es cómo se
> pierde un fin de semana.

La alternativa —dos bases de datos y sincronización— es peor para una empresa de este tamaño, y
conviene decir por qué: sincronizar es un problema permanente, y aquí el volumen no justifica
pagarlo.

### 5.6 El límite del admin, dicho a tiempo

El admin es excelente para lo que es: una interfaz **de administración de datos** para gente que
entiende el modelo. Deja de serlo cuando:

- El flujo no es "editar un registro" sino un proceso de varios pasos con estados. Un asistente
  para abrir un plan de tratamiento, con las cinco fases y el consentimiento, **no es un
  formulario de modelo**.
- La pantalla la usa alguien que no debería ver la estructura de la base. El admin muestra el
  modelo; a veces eso es exactamente lo que no quieres mostrar.
- El volumen de personalización supera lo que ahorra. Si llevas doscientas líneas peleando con
  `formfield_for_foreignkey`, esa pantalla debió ser una vista normal.

**Las tres tienen la misma respuesta:** una vista de Django con su plantilla, al lado del admin,
en la misma aplicación. No hay que abandonar nada — y eso, que suena obvio, es lo que más cuesta
aceptar cuando uno se enamora del admin.

---

## 📏 6. Medición — el mismo CRUD, en los dos

Esta es la medición que sostiene el veredicto, y es de las pocas del curso donde lo que se mide no
es tiempo.

**Hipótesis.** Para una aplicación con muchas pantallas administrativas, la diferencia entre los
dos registros no está en el rendimiento sino en cuánto código hay que escribir y mantener — y la
diferencia crece con cada pantalla nueva.

**Condiciones.** Django 6.1.1 · FastAPI 0.141.1 con Jinja2 y SQLAlchemy 2.0.52 · CPython 3.14.5 ·
**el mismo encargo en los dos**: un CRUD completo de planes de tratamiento (listar con búsqueda y
filtro por sede, crear, editar, borrar), autenticación con sesión, **permisos por fila** —cada
usuario ve solo su sede—, **ocultamiento de la nota clínica** para quien no es superusuario, y
**registro de auditoría** de cada acceso. Las dos implementaciones **se ejecutaron y producen el
mismo comportamiento**, comprobado con el mismo guion de prueba: Édgar ve 10 de 20 planes, no
puede abrir uno de Centro, no ve la nota clínica, Julián sí, y los accesos quedan registrados.
Líneas contadas sin líneas en blanco, incluyendo comentarios y plantillas.

**Competidores.** Ninguno está saboteado: la versión de FastAPI usa Jinja2, sesiones firmadas y
SQLAlchemy, que es lo que usaría alguien que sabe lo que hace. La de Django usa el admin, que es
lo que usaría alguien que sabe lo que hace.

**Resultado — la primera pantalla:**

| | Django | FastAPI + Jinja2 |
|---|---|---|
| Líneas escritas | **76** | 204 |
| Archivos escritos | **2** (+1 línea en `settings.py`) | 6 |
| Plantillas HTML | **0** | 4 |
| Autenticación | incluida | 25 líneas |
| CSRF | incluido | **no implementado** |
| Paginación | incluida | **no implementada** |
| Filtros, búsqueda y orden | 3 líneas | en cada consulta |

**Resultado — la pantalla número cuarenta y uno** (agregar la entidad *consentimiento*, con su
CRUD y el mismo permiso por fila):

| | Django | FastAPI + Jinja2 |
|---|---|---|
| Líneas | **23** | 70 |
| Archivos nuevos | **0** | 3 |
| Dónde se toca | dos archivos que ya existen | un módulo nuevo y dos plantillas |

> ⚖️ **Veredicto — y es sobre registros, no sobre calidades.**
>
> **Para el back-office de Áurea, Django gana y no está cerca.** 76 líneas contra 204 en la
> primera pantalla, y —lo que decide de verdad— **23 contra 70 en cada pantalla siguiente**. Con
> cuarenta pantallas, esa diferencia por pantalla es la diferencia entre un proyecto que una
> persona mantiene y uno que no. Y las columnas de CSRF y paginación dicen algo peor que el
> conteo: la versión de FastAPI **no las tiene**, así que la comparación honesta es todavía más
> favorable a Django de lo que las líneas sugieren.
>
> **Y para AgendaAPI, FastAPI gana con la misma claridad**, por razones que esta tabla no puede
> mostrar: el contrato en OpenAPI que genera los clientes del bot y de la web, la validación
> declarativa de la Fase 10, y el hecho de que **el 100% de esas 76 líneas de ventaja de Django
> son interfaz de usuario que AgendaAPI no necesita.** Medir AgendaAPI con esta tabla daría un
> resultado invertido y igual de contundente.
>
> **Dónde pierde Django, y hay que decirlo:** el admin resuelve el CRUD y no resuelve un flujo —
> §5.6—, así que las pantallas que **no** son "editar un registro" no reciben ninguna de estas
> ventajas y cuestan lo mismo que en cualquier framework. Y el ORM de Django tiene carga perezosa
> automática, con el N+1 silencioso que la Fase 11 enseñó a odiar: aquí vuelve, y `select_related`
> es la respuesta.
>
> **El umbral, que es lo que hay que llevarse:**
>
> - **¿Quién consume esto?** Si es una persona mirando pantallas, Django. Si es otro programa,
>   FastAPI.
> - **¿Cuántas pantallas?** Por debajo de cinco, da igual y elige la que ya tienes montada. Por
>   encima de veinte, el admin decide solo.
> - **¿Y el rendimiento?** Decide cuando el volumen es alto y la forma es simple — y ese es el
>   caso de AgendaAPI, no el del back-office. La Fase 17 pone ese número.
>
> **El empate, que también hay que nombrarlo:** para las primeras tres o cuatro pantallas de un
> proyecto nuevo, las dos opciones son razonables y la diferencia de setenta líneas no decide
> nada. Elegir por lo que el equipo ya conoce es, en ese caso, una decisión de ingeniería
> perfectamente defendible.

**Lo que no se midió, y se declara:** el rendimiento en peticiones por segundo, a propósito — es
el criterio que §4 identifica como el equivocado para esta decisión, y medirlo aquí invitaría a
usarlo. El "tiempo hasta la primera pantalla usable" tampoco se midió en minutos, porque depende
de cuánto conoce cada quien el framework y sería una anécdota con formato de dato; el conteo de
líneas y archivos es el sustituto honesto. Y no se midió el costo de **mantener** las dos
versiones durante un año, que es donde la diferencia sería mayor y que ninguna medición de una
tarde puede capturar.

---

## 🧱 7. Miniproyecto — *Lo que el franquiciado no debe ver*

**El encargo**

Julián, incómodo: *"Édgar necesita entrar a ver los planes de su sede, y tiene razón en pedirlo.
Pero no puede ver los de las otras sedes, y sobre todo no puede ver lo clínico de pacientes que no
son suyos. Y el abogado me dijo una cosa que me dejó pensando: que si alguien entra a una historia
clínica, tiene que quedar registrado quién fue y por qué. ¿Eso se puede?"*

Construye el back-office del plan de tratamiento con permisos por sede y registro de cada acceso a
un dato de paciente.

**Por qué duele**

Porque el permiso por fila es fácil de poner en la vista, y **es ahí donde no sirve**. La fuga no
se cuela por la pantalla que revisaste: se cuela por el admin, por un reporte, por una
exportación, por la búsqueda, o por el `shell` que alguien abrió para arreglar un dato.

Y porque la auditoría de **lecturas** es más difícil que la de escrituras: escribir es un evento y
se registra solo; leer ocurre en todas partes, y hay que decidir **qué cuenta como un acceso**.

**Datos de entrada**

El modelo de la Fase 11 —planes con sus cinco fases— más lo que esta fase agrega: usuarios con
sede, y el registro de accesos. Y los cuatro actores que tienen que funcionar:

| Usuario | Qué es | Qué debe ver |
|---|---|---|
| **Julián** | superusuario | todo, incluida la nota clínica y la auditoría |
| **Patricia** | administradora | todas las sedes, **sin** nota clínica |
| **Édgar** | franquiciado de Suba | solo Suba, sin nota clínica de pacientes que no trata |
| **Yuli** | auxiliar del Centro | solo Centro, solo lectura |

**Criterios de aceptación**

- [ ] Los cuatro usuarios existen, entran, y **cada uno ve exactamente lo que le corresponde**.
- [ ] El permiso por fila se comprueba por **cinco puertas**, no por una: la lista, el acceso
      directo por URL, la búsqueda, un filtro, y una exportación o acción masiva. Escribe una
      prueba por puerta.
- [ ] Cada acceso a un plan queda en la auditoría con actor, momento, acción y **motivo**. El
      motivo no puede ser un valor por defecto silencioso: si nadie lo declara, se registra como
      tal y se puede buscar.
- [ ] La auditoría es **inmutable desde la aplicación**: nadie la edita ni la borra, ni el
      superusuario.
- [ ] Yuli no puede modificar nada, y eso se comprueba intentándolo por POST directo, no solo
      mirando que no aparezca el botón.
- [ ] **Medición:** líneas escritas y archivos tocados para la primera pantalla, y lo mismo para
      la segunda entidad. Esos cuatro números van en el mensaje del tag.

**Restricciones de registro**

> Esto es una **aplicación con baterías**, y la restricción propia de esta fase es la opuesta a la
> del Bloque A: **usa lo que el framework trae.** Si te descubres escribiendo un sistema de
> permisos, un formulario a mano o una paginación, para y busca si ya existe — porque existe. El
> reflejo que esta fase ataca no es la ceremonia: es **reescribir lo que ya está escrito**, que
> para un senior acostumbrado a controlarlo todo es igual de fuerte.

**La trampa**

Vas a poner el filtro por sede en `get_queryset` del admin, vas a comprobar que Édgar ve diez
planes en vez de veinte, y vas a darlo por resuelto.

Y quedan dos puertas abiertas que ese filtro no cubre, las dos reales y las dos en el admin:

- **Los desplegables de las claves foráneas.** El formulario de un plan tiene un selector de sede
  que lista **todas** las sedes, y uno de paciente que lista **todos** los pacientes. Édgar no
  debería ver esa lista, y ahí está — no como dato del plan, sino como opción del formulario.
- **La búsqueda y los filtros por relación.** Un `search_fields` que navegue a otra tabla puede
  revelar la existencia de registros que el filtro principal excluyó.

Encontrarlas es el ejercicio. **Un permiso por fila que solo filtra la lista no es un permiso por
fila.**

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Haz una lista de **todas** las formas de llegar a un dato de paciente antes de escribir una línea:
la lista, el detalle, la búsqueda, los filtros, los desplegables de los formularios, las acciones
masivas, la exportación, el historial del admin, y el `shell`. Son más de las que parecen.

Después pregúntate, para cada una, **por dónde pasa**. Las que pasan por el mismo sitio se
protegen una sola vez; las que no, hay que cerrarlas una por una.

Para la auditoría, decide antes qué cuenta como acceso: ¿ver la lista es un acceso? ¿Ver un plan
sin la nota clínica lo es? No hay respuesta única, y la tuya tiene que estar escrita.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [`ModelAdmin.get_queryset`](https://docs.djangoproject.com/en/6.1/ref/contrib/admin/) y
  `has_view_permission`, `has_change_permission`, `has_delete_permission` — los ganchos por objeto.
- **`formfield_for_foreignkey`**, que es el que cierra la primera puerta de la trampa.
- [*Managers* personalizados](https://docs.djangoproject.com/en/6.1/topics/db/managers/) si quieres
  el filtro **por debajo del admin**, que es más fuerte y más peligroso.
- [Señales](https://docs.djangoproject.com/en/6.1/topics/signals/) para auditar escrituras sin
  tocar cada vista — y piensa por qué no sirven para auditar **lecturas**.
- [Pruebas de Django](https://docs.djangoproject.com/en/6.1/topics/testing/) con `Client`, que es
  como se comprueban las cinco puertas.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
class BranchScopedAdmin(admin.ModelAdmin):
    """Base para todo modelo con datos de paciente. Una sola puerta."""

    branch_path = "branch"          # o "plan__branch" para modelos relacionados

    def get_queryset(self, request): ...
    def formfield_for_foreignkey(self, db_field, request, **kwargs): ...
    def log_access(self, request, obj_id, action): ...
```

Un `Mixin` reutilizable es la respuesta correcta aquí, y **no contradice lo de la Fase 03**: hay
comportamiento compartido de verdad entre varios modelos, no una clase con un método.
</details>

**Cómo se entrega**

```bash
uv run python manage.py migrate
uv run python manage.py crear_usuarios_demo   # un comando de gestión, escrito por ti
uv run python manage.py test
uv run python manage.py runserver
```

```bash
git add consultorio/ planes/
git commit -m "fase 12 mini: back-office con permisos por sede y auditoría"
git tag -a mini-12 -m "Mini F12: back-office · primera pantalla <N> líneas/<A> archivos, segunda <M>/<B>"
```

<details><summary>💡 Solución de referencia — las tres decisiones y las cinco puertas</summary>

**La decisión de diseño que se tomó.** El filtro por sede va en `get_queryset` del admin **y** en
un *manager* del modelo, duplicado a propósito. Es redundante y es deliberado: el `get_queryset`
protege el admin, y el *manager* protege todo lo demás —reportes, comandos de gestión, cualquier
vista futura—. El otro camino —solo el *manager*, que suena más limpio— tiene un problema serio:
un *manager* por defecto que filtra según el usuario actual **necesita saber quién es el usuario
actual**, y eso obliga a un estado global por hilo que es exactamente el tipo de magia que produce
errores imposibles de depurar. La duplicación explícita es más fea y es más segura.

**Qué cuenta como acceso**, que es la decisión que el enunciado no toma: **abrir el detalle de un
plan**, sí. **Ver la lista**, no — porque la lista no muestra datos clínicos y auditar cada
listado produciría un registro inútil de tamaño enorme. Esa frontera hay que escribirla, y si el
abogado de Áurea dice otra cosa, se cambia una línea. Lo que no se vale es no haberlo decidido.

**Las cinco puertas, con su cierre:**

1. **La lista** → `get_queryset`.
2. **La URL directa** → el mismo `get_queryset`; el admin devuelve 302 porque el objeto "no
   existe" para ese usuario. Compruébalo: es la prueba que más gente no escribe.
3. **La búsqueda** → el mismo, siempre que `search_fields` no navegue a una tabla sin filtrar.
4. **Los desplegables del formulario** → `formfield_for_foreignkey`. **Esta es la que casi nadie
   cierra**, y la que revela la existencia de pacientes y sedes ajenos sin mostrar un solo plan.
5. **Las acciones masivas y la exportación** → también `get_queryset`, porque operan sobre él. Pero
   compruébalo en vez de suponerlo: una acción escrita a mano que reciba identificadores del POST
   puede saltárselo.

**La trampa, entera.** El permiso por fila se piensa como "filtrar lo que se muestra" y es en
realidad "**cerrar todas las formas de llegar al dato**". La diferencia se ve cuando dejas de
contar pantallas y empiezas a contar caminos: son más, y algunos no tienen interfaz.

**Qué se habría hecho distinto si el registro fuera otro.** Como API —FastAPI— esto sería una
función `visible_plans(user)` que **toda** consulta tiene que usar, y el riesgo se movería de
sitio: nada obliga al programador a usarla, así que la protección dependería de la disciplina y de
la revisión de código. Django lo pone en un punto por el que el framework **obliga** a pasar, que
es estructuralmente más seguro. Como script no existiría: los datos clínicos no salen del sistema
de registro, y esa es justamente la frontera legal que el curso no cruza.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Registra un modelo en el admin con solo `list_display` y `list_filter`, y anota todo lo que
   obtuviste sin escribirlo. Es el ejercicio que más cambia la opinión de este perfil.
2. Agrega `date_hierarchy` y `search_fields` y comprueba qué SQL emiten, con `django-debug-toolbar`
   o con el registro de consultas.
3. Crea los cuatro usuarios del miniproyecto y comprueba que cada uno ve lo suyo.
4. Haz que la nota clínica no aparezca para un usuario no superusuario, y comprueba que tampoco
   llega en el HTML —mira el código fuente de la página, no la pantalla—.
5. Escribe una prueba con `Client` que compruebe que Édgar recibe 302 al abrir un plan de Centro.
6. Agrega un `Meta.verbose_name` en español a todos los modelos y mira cómo cambia el admin.

**🟡 Intermedio (7–14)**

7. Cierra la puerta de los desplegables con `formfield_for_foreignkey` y demuestra con una prueba
   que Édgar ya no ve las otras sedes en el selector.
8. Provoca un N+1 en el admin —una columna que navegue a otra tabla— cuéntalo, y arréglalo con
   `list_select_related`.
9. Escribe una acción masiva del admin —cerrar planes seleccionados— y comprueba si respeta el
   permiso por fila. Si no lo respeta, arréglalo.
10. Crea un comando de gestión (`manage.py`) que cargue los datos de demostración. Compáralo con
    el script suelto del Bloque A y anota qué ganaste.
11. Usa señales (`post_save`) para auditar escrituras, y después explica por qué la misma técnica
    no sirve para auditar lecturas.
12. Configura Django para que use la base de datos de AgendaAPI **sin generar migraciones** sobre
    sus tablas (`managed = False`). Averigua cuándo eso es la respuesta correcta.
13. Agrega paginación explícita al listado del admin (`list_per_page`) y mide qué le pasa a la
    consulta con 50.000 planes.
14. Averigua qué es `django.contrib.admin.LogEntry` y qué registra exactamente. Compáralo con tu
    `AccessLog`: ¿cuál de los dos habría servido para el requisito del abogado?

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Un usuario reporta que "a veces ve planes de otra sede". Hay tres causas
    posibles y las tres están en esta fase. Reprodúcelas.
16. **Diagnóstico.** El admin va lento con 50.000 planes. Encuentra las tres causas más probables
    —una es el conteo de la paginación— y mídelas.
17. **Medición.** Reproduce la medición de §6 en tu máquina: escribe el mismo CRUD en los dos y
    cuenta líneas y archivos. Si tu relación es muy distinta, explica en qué se diferencia tu
    implementación.
18. **Medición.** Mide lo que cuesta la **tercera** entidad en cada uno, y proyecta a cuarenta
    pantallas. La proyección es el argumento que le vas a dar a Julián.
19. **Medición.** Compara el tiempo de respuesta del listado del admin contra tu listado en
    FastAPI, con 10.000 planes. El resultado puede sorprenderte en cualquiera de las dos
    direcciones: repórtalo como salga.
20. **De registro.** Áurea quiere que los pacientes vean su propio plan desde la web. Decide el
    registro —¿Django, AgendaAPI, o algo más?— y justifica con el costo de las tres opciones y con
    la frontera legal de la historia clínica.
21. **De registro.** Julián propone "hacer todo en Django y quitar la API, para no mantener dos
    cosas". Es una propuesta seria y tiene argumentos. Escribe la respuesta con las dos caras,
    incluyendo qué se perdería con el bot de WhatsApp.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Encuentra **tres** formas de que un franquiciado acceda a datos de otra sede
    con tu implementación puesta. Al menos una tiene que ser a través del admin y al menos una a
    través de algo que no es una pantalla. Ciérralas todas y escribe una prueba por cada una.
23. **Adversarial.** Demuestra que tu auditoría se puede evadir: encuentra una forma de leer un
    plan sin que quede registro. Hay al menos dos —una por el propio admin—. Después decide
    honestamente si vale la pena cerrarlas o si la defensa razonable tiene un límite, y escribe
    dónde lo pones.
24. **Defiende una decisión.** Escribe el veredicto del curso con tus propios números, en una
    página, dirigido a Julián —que no es ingeniero— y respondiendo a la pregunta que él hizo de
    verdad: *"¿por qué dos sistemas y no uno?"*. Es el entregable más útil de esta fase para tu
    vida profesional.
25. **Diseño.** El abogado vuelve y pide más: que el paciente pueda solicitar el registro de quién
    accedió a su historia, y que ese informe se pueda generar. Diseña qué hace falta —dónde vive
    el dato, cómo se consulta, qué se muestra y qué no— y **qué parte de esto no deberías
    construir tú**. La respuesta incluye un "esto lo revisa un abogado antes".

**🔥 Opcionales**

- Instala `django-debug-toolbar` y mira las consultas que emite cada pantalla del admin. Es la
  mejor herramienta de diagnóstico del ecosistema y no tiene equivalente en FastAPI.
- Investiga `django-guardian` y decide si habrías usado una biblioteca de permisos por objeto en
  vez de escribirlo. Compara el costo de la dependencia contra las líneas que ahorra.
- Personaliza el admin hasta donde aguantes —plantillas propias, un tablero— y anota en qué punto
  sentiste que debiste escribir una vista normal. Ese punto es §5.6, encontrado por ti.

---

## 📚 9. Referencias

**Documentación oficial**

- [Django — Tutorial](https://docs.djangoproject.com/en/6.1/intro/tutorial01/) — las siete partes.
  La cuarta y la séptima son las del admin.
- [El sitio de administración](https://docs.djangoproject.com/en/6.1/ref/contrib/admin/) — la
  referencia completa de `ModelAdmin`, que es donde están todos los ganchos de §5.3.
- [Autenticación y permisos](https://docs.djangoproject.com/en/6.1/topics/auth/) — y en particular
  la sección sobre permisos por objeto, que explica por qué **no** vienen incluidos.
- [ORM de Django — consultas](https://docs.djangoproject.com/en/6.1/topics/db/queries/) y
  [optimización](https://docs.djangoproject.com/en/6.1/topics/db/optimization/) — `select_related`
  y `prefetch_related`.
- [Seguridad en Django](https://docs.djangoproject.com/en/6.1/topics/security/) — CSRF, XSS,
  contraseñas. Lee la parte de contraseñas junto con §5.4.

**Libros / artículos**

- *Two Scoops of Django*, de Daniel y Audrey Roy Greenfeld — el libro de convenciones y decisiones
  de la comunidad. Verifica la edición contra la versión de Django que uses.

**Orden de lectura sugerido.** Antes de escribir: las partes 1, 2 y 7 del tutorial oficial —el
admin sale en la 7 y es lo que hay que ver funcionando—. Durante: la referencia de `ModelAdmin`,
consultada por gancho. Después: la sección de permisos por objeto, que se entiende mucho mejor
cuando ya peleaste con las cinco puertas.

> ⚠️ URLs y contenidos cambian, y Django numera su documentación por versión: asegúrate de estar
> leyendo la de 6.1 y no la de una versión anterior, que es lo que suele salir en los buscadores.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Áurea tiene su back-office, y tú tienes el veredicto con tus números: **76 líneas contra 204 para
la primera pantalla, y 23 contra 70 para cada una de las siguientes.** Con cuarenta pantallas y un
solo ingeniero, eso no es una preferencia: es la diferencia entre un sistema que se mantiene y uno
que se abandona.

Y tienes el criterio, que es lo transferible: **son dos registros, no dos calidades**. La pregunta
que decide no es cuál framework es mejor —esa pregunta no tiene respuesta— sino **quién consume
esto y cuántas pantallas hay**. Áurea necesita los dos, los tiene, y comparten una base de datos
con una regla clara sobre quién manda el esquema.

Te llevas además una incomodidad útil, la de §5.4: **hay cosas que Django hace bien y que tú
habrías hecho mal**, empezando por el hash de las contraseñas. Reconocerlo es lo que separa
elegir un framework de tenerle fe.

La **Fase 13** sale del sistema: hasta ahora todo lo que construiste vive en tu máquina y en tu
base de datos. Ahora hay que hablar con **sistemas que no controlas** —los socios que quieren
recibir la disponibilidad, la pasarela que confirma un pago— sin que un fallo ajeno se convierta
en un error propio ni, mucho peor, en un cobro duplicado. La idea que la ordena es la
**idempotencia**, y no es un apartado: es la fase entera.

> **La señal de que quedó bien:** la próxima vez que alguien pregunte "¿Django o FastAPI?", tu
> primera respuesta va a ser una pregunta — *"¿quién lo va a usar, una persona o un programa?"*.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-12 -m "F12 cerrada:
> - Consultorio corre: CRUD de planes con auth, permisos y auditoría
> - permiso por sede cerrado en las cinco puertas, con una prueba por puerta
> - la nota clínica no llega al HTML de quien no debe verla
> - la auditoría registra actor, momento, acción y motivo, y es inmutable
> - el veredicto escrito con números propios: 76/204 y 23/70
> - dos registros, una base de datos, y una sola aplicación dueña del esquema"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 12: …`), los de ejercicio su número
> (`fase 12 ej12: …`) y el miniproyecto el suyo (`fase 12 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-12`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
