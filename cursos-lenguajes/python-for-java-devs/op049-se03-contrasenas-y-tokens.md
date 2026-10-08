# 🔐 se03 — Contraseñas y tokens

> Python para desarrolladores Java senior · **Carta** · Track `se` — Seguridad aplicada y
> criptografía · sección 3 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El back-office de Áurea tiene usuarios: auxiliares, administradoras, los franquiciados que ven solo su sede.
Eso trae dos problemas que este perfil cree resueltos y que se resuelven mal con frecuencia:

- **Guardar contraseñas.** No se cifran —el que tiene la clave las lee todas—: se resumen con una función
  **lenta a propósito** y con sal, para que un respaldo robado no sirva para probar millones de contraseñas
  por segundo.
- **Recordar quién está conectado.** Después de iniciar sesión, cada petición tiene que llevar algo que diga
  quién es. Las dos opciones son una **sesión** (un identificador opaco que el servidor busca en su tabla) o
  un **token autocontenido** (un JWT firmado que el servidor verifica sin buscar nada).

La segunda es la que trae la discusión. Un JWT es cómodo, escala sin tabla y es lo que este perfil usó en sus
microservicios. Y tiene un costo que solo aparece el día que hace falta: **un JWT firmado no se puede
revocar**. Si la auxiliar que despidieron esta mañana tiene un token válido por ocho horas, durante ocho
horas sigue entrando al back-office, con acceso a historias clínicas.

---

## 🧠 2. El modelo

**Contraseñas:**

| Función | Estado | La regla |
|---|---|---|
| **Argon2id** (`argon2-cffi` 25.1.0) | La recomendada hoy | Parámetros de memoria y tiempo; se suben con los años |
| `bcrypt` (5.0.0) | Válida, más vieja | Corta la contraseña en 72 bytes; la versión 5 lo hace explícito |
| PBKDF2 (`hashlib`) | Válida si te la exige una norma | Necesita muchísimas iteraciones para igualar a las anteriores |
| SHA-256 con sal | **No** | Rápida: es exactamente lo que no se quiere |

**Sesión o JWT:**

| | Sesión opaca | JWT |
|---|---|---|
| Qué viaja | Un identificador aleatorio (`secrets.token_urlsafe`) | Un JSON firmado con los datos del usuario |
| Qué hace el servidor | Busca el identificador en su tabla | Verifica la firma, sin buscar nada |
| **Revocar** | Borrar la fila: efecto inmediato | **No se puede** sin agregar estado: lista de revocados o vencimiento corto |
| Escala | Necesita una tabla compartida | Cualquier servidor con la clave lo verifica |

Para un back-office de una empresa con diez sedes, la tabla de sesiones no es un problema de escala: son unas
decenas de filas. Lo que sí es un problema es no poder echar a alguien.

### Tu instinto de Java dice… y esta vez se equivoca

En el mundo Spring de los últimos años, el reflejo es Spring Security con JWT para todo, "porque es sin
estado". Para APIs entre servicios, con tokens de minutos, está bien. Para la sesión de una persona en un
back-office con datos clínicos, **un JWT no es una sesión**: es una credencial al portador que no se puede
retirar. El ejemplo de abajo lo demuestra con la auxiliar despedida.

---

## 💻 3. El ejemplo que corre

```bash
uv add argon2-cffi pyjwt
```

`acceso.py`:

```python
"""Contraseñas con Argon2, y la diferencia entre una sesión que se revoca y un JWT que no."""

import datetime as dt
import secrets

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError

# ------------------------------------------------- contraseñas

hasher = PasswordHasher()                       # Argon2id con los parámetros por defecto de la biblioteca
stored = hasher.hash("Yuli-Centro-2026!")
print("guardado:", stored[:30], "…")
try:
    hasher.verify(stored, "yuli-centro-2026!")
except VerifyMismatchError:
    print("contraseña equivocada: rechazada")
print("correcta:", hasher.verify(stored, "Yuli-Centro-2026!"))
print("¿hay que volver a resumir con parámetros nuevos?", hasher.check_needs_rehash(stored))

# ------------------------------------------------- la sesión opaca, que se revoca

sessions: dict[str, str] = {}                   # en producción, una tabla con vencimiento
session_id = secrets.token_urlsafe(32)
sessions[session_id] = "yuli.chaparro"


def who_session(token: str) -> str | None:
    return sessions.get(token)


# ------------------------------------------------- el JWT, que no

SIGNING_KEY = secrets.token_bytes(32)
claims = {"sub": "yuli.chaparro", "sede": "Centro",
          "exp": dt.datetime.now(dt.UTC) + dt.timedelta(hours=8)}
access_token = jwt.encode(claims, SIGNING_KEY, algorithm="HS256")


def who_jwt(token: str) -> str | None:
    try:
        # algorithms= fijo: nunca se acepta el algoritmo que diga el token.
        return jwt.decode(token, SIGNING_KEY, algorithms=["HS256"])["sub"]
    except jwt.InvalidTokenError:
        return None


# Despiden a la auxiliar a las 10:00. Se "cierra su sesión" en los dos sistemas.
sessions.pop(session_id)
print("sesión después del despido:", who_session(session_id))
print("JWT después del despido:   ", who_jwt(access_token), "(sigue entrando hasta que venza)")

# El ataque del algoritmo "none": un token sin firma que dice ser de la administradora.
forged = jwt.encode({"sub": "patricia.guzman"}, key=None, algorithm="none")
print("token sin firma aceptado:  ", who_jwt(forged))
```

```bash
python3 acceso.py
```

Salida (Python 3.14.7, 05/10/2026) (el resumen cambia en cada corrida):

```text
guardado: $argon2id$v=19$m=65536,t=3,p=4 …
contraseña equivocada: rechazada
correcta: True
¿hay que volver a resumir con parámetros nuevos? False
sesión después del despido: None
JWT después del despido:    yuli.chaparro (sigue entrando hasta que venza)
token sin firma aceptado:   None
```

La sexta línea es la sección entera: la sesión se revocó al borrar una fila; el JWT sigue diciendo
`yuli.chaparro` y el servidor lo acepta, porque verificar la firma es todo lo que hace. Y la última línea es la
defensa contra el error clásico de JWT: un token con `alg: none` se rechaza porque `algorithms=["HS256"]` está
fijo en el servidor.

**Detalles con intención**

- **El resumen de Argon2 lleva sus parámetros adentro** (`m=65536,t=3,p=4`): memoria, iteraciones y
  paralelismo. Cuando se suben, `check_needs_rehash` dice qué contraseñas resumir de nuevo, en el próximo
  inicio de sesión, sin forzar un cambio de contraseña.
- **`secrets.token_urlsafe(32)`**, no `random` ni `uuid4`: `secrets` usa el generador del sistema
  operativo, que es el adecuado para identificadores que alguien podría intentar adivinar.
- **`algorithms=["HS256"]`** es obligatorio en `jwt.decode` desde hace varias versiones de `pyjwt`, y existe
  por el ataque de la última línea: un servidor que acepta el algoritmo que dice el token acepta tokens sin
  firma.
- **La sesión opaca guarda el usuario en el servidor**: cambiar los permisos de alguien tiene efecto en la
  siguiente petición, no cuando venza su token.

---

## ⚠️ 4. Lo que se rompe

**`passlib`.** Fue la biblioteca de referencia para contraseñas durante una década, y sigue en muchos tutoriales
y proyectos heredados. Su última versión es de octubre de 2020 (1.7.4), y con versiones recientes de `bcrypt`
tiene problemas de compatibilidad conocidos. Para un proyecto nuevo, `argon2-cffi` directo; para uno heredado,
migrar en el próximo inicio de sesión de cada usuario.

**El límite de 72 bytes de `bcrypt`.** `bcrypt` solo usa los primeros 72 bytes de la contraseña: dos
contraseñas largas que empiezan igual se resumen igual. La versión 5 de la biblioteca **lanza un error** con
contraseñas más largas en vez de cortarlas en silencio; el código que funcionaba con la 4 puede empezar a
fallar con frases largas.

**El JWT "con lista de revocados".** La salida habitual al problema de la revocación es una lista de tokens
revocados que el servidor consulta en cada petición. Funciona, y es **una sesión con otro nombre**: hay estado
compartido que consultar. Si de todos modos hay que consultarlo, la sesión opaca es más simple.

**Guardar el JWT en `localStorage`.** Cualquier JavaScript de la página lo lee, incluido el de un ataque de
inyección. Una sesión en una cookie `HttpOnly`, `Secure` y `SameSite` no la lee ningún script.

---

## ⚖️ 5. Cuándo NO usarla

**El JWT, para la sesión de una persona en el back-office.** Por todo lo de arriba.

**La sesión opaca, entre servicios.** Para que AgendaAPI le pruebe a Cartera quién es, en cada petición, un
token corto (minutos) firmado —o mejor, emitido por un servidor de identidad (`se04`)— evita una tabla
compartida entre servicios, y la revocación importa menos cuando el token dura cinco minutos.

**Tus propias contraseñas, si puedes no tenerlas.** Si los usuarios del back-office ya tienen cuentas de
Google Workspace o de Microsoft, delegar la autenticación (`se04`) elimina el problema entero: no guardas
contraseñas que se puedan robar.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Sube el parámetro de memoria de `PasswordHasher` y verifica la contraseña vieja. **Criterio:**
   `check_needs_rehash` devuelve `True` y explicas qué harías en el próximo inicio de sesión.
2. Haz que el JWT venza en dos segundos y verifícalo a los tres. **Criterio:** `who_jwt` devuelve `None`, y dices
   qué excepción concreta lanzó `pyjwt`.
3. Quita `algorithms=["HS256"]` de `jwt.decode`. **Criterio:** describes qué hace `pyjwt` y por qué.

**🟡 Intermedio (4–6)**

4. Prueba `bcrypt` 5 con una contraseña de 80 bytes. **Criterio:** reportas el error exacto y escribes la función
   que lo maneja (por ejemplo, resumiendo antes con SHA-256 y codificando en base64, con su razón).
5. Busca en la documentación de `argon2-cffi` cómo se eligen los parámetros para tu máquina. **Criterio:** los
   parámetros que hacen que un resumen tarde unos 200 ms, medidos.
6. Implementa la sesión opaca en una tabla de SQLite con vencimiento deslizante. **Criterio:** una sesión sin uso
   por 30 minutos deja de servir; una usada sigue viva.

**🟠 Difícil (7–9)**

7. Migra un usuario de `passlib` con `bcrypt` a Argon2 en su próximo inicio de sesión. **Criterio:** el resumen
   viejo verifica una vez y queda reemplazado por uno de Argon2.
8. Implementa JWT de acceso de cinco minutos más un token de renovación opaco y revocable. **Criterio:** despedir
   a la auxiliar la deja fuera en cinco minutos como máximo, demostrado con el reloj congelado.
9. Mide cuántos resúmenes de Argon2 por segundo hace tu máquina con los parámetros por defecto, y cuántos
   SHA-256. **Criterio:** los dos números, y cuánto tardaría un atacante en probar diez millones de contraseñas
   con cada uno.

**🔴 Muy difícil (10)**

10. Diseña la autenticación del back-office de Áurea. **Criterio:** un documento de una página. *Rúbrica:* (a)
    cómo se revoca el acceso de alguien y en cuánto tiempo surte efecto; (b) dónde viaja y dónde vive la
    credencial de cada petición; (c) qué pasa con los franquiciados, que solo ven su sede; (d) si se guardan
    contraseñas o se delegan, y por qué.

---

## 📚 7. Referencias

**Documentación oficial**

- `argon2-cffi`: https://argon2-cffi.readthedocs.io/en/stable/
- `pyjwt`, uso y algoritmos: https://pyjwt.readthedocs.io/en/stable/usage.html
- `secrets`: https://docs.python.org/3/library/secrets.html
- OWASP, almacenamiento de contraseñas: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html

**Orden de lectura sugerido:** la hoja de OWASP sobre contraseñas, que tiene los parámetros recomendados y su
porqué; después la documentación de `argon2-cffi`.

---

## 🚀 8. Cierre

Las contraseñas se resumen con Argon2 y se vuelven a resumir cuando suben los parámetros. La sesión de una
persona es un identificador opaco que el servidor puede borrar; un JWT es una credencial al portador que sirve
entre servicios, por minutos, y no reemplaza a la sesión el día que hay que echar a alguien.

**La señal de que quedó bien:** *"Despedimos a alguien a las 10:00 y a las 10:01 su sesión ya no abría el
back-office."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-se-fase-03 -m "op se03 cerrada: Argon2, sesión revocable y por qué un JWT no es una sesión"
> ```
>
> Los commits llevan su prefijo (`op se03: …`) y los de ejercicio su número
> (`op se03 ej07: …`).
