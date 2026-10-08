# 🗝️ se05 — Secretos: dónde viven y por dónde se escapan

> Python para desarrolladores Java senior · **Carta** · Track `se` — Seguridad aplicada y
> criptografía · sección 5 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Los procesos de Áurea necesitan secretos: la contraseña de la base de Cartera, el token de la API de la pasarela
de pagos, la clave de cifrado de `se02`, el DSN del rastreador de errores. La pregunta de dónde guardarlos tiene
respuestas conocidas —un gestor de secretos, variables de entorno, archivos montados— y casi ningún incidente
real viene de elegir mal entre ellas.

Los incidentes vienen de **por dónde se escapan**. La contraseña estaba bien guardada en una variable de entorno
y apareció en una bitácora porque alguien registró la cadena de conexión al fallar. El token estaba en un
archivo `.env` que se subió al repositorio. La variable de entorno apareció completa en un `docker inspect` que
alguien pegó en un canal para pedir ayuda. Esta sección trata las dos cosas: dónde viven, y cómo se tapan las
salidas.

---

## 🧠 2. El modelo

| Dónde vive | Quién lo puede leer | Se escapa por | Para Áurea |
|---|---|---|---|
| En el código o en el repositorio | Todo el que clona, para siempre (el historial de git no olvida) | Todo | **Nunca** |
| Archivo `.env` fuera del repositorio | El usuario del proceso | Un `git add .` sin `.gitignore`; una copia de respaldo | Desarrollo local |
| Variable de entorno | El proceso, **sus hijos**, `docker inspect`, `/proc/<pid>/environ` | Un volcado de `os.environ`; un subproceso que lo registra | Aceptable, con cuidado |
| Archivo montado (secretos de Docker o Kubernetes) | El proceso que lo lee | Una bitácora que registra el valor ya leído | **Preferido en servidores** |
| Gestor de secretos (Vault, el de la nube) | Quien tenga la credencial del gestor | La credencial del gestor, que también es un secreto | Cuando hay muchos secretos y rotación |
| Llavero del sistema (`keyring`) | El usuario de escritorio | — | Herramientas de escritorio y de línea de comandos |

Y la regla que ataja la mayoría de los escapes, sin importar dónde viva el secreto: **dentro del programa, el
secreto viaja envuelto en un tipo que no se imprime**. Un `SecretStr` de Pydantic se registra como
`'**********'`; el valor solo sale cuando se pide explícitamente, en el único lugar que lo necesita.

### Tu instinto de Java dice… y esta vez se equivoca

En Spring, `application.properties` con `${DB_PASSWORD}` y el valor en la variable de entorno es lo normal, y
Spring Cloud Vault resuelve el resto. El instinto trae la idea de que la variable de entorno es "el lugar seguro".
No es más segura que un archivo: es **más visible** —la heredan todos los subprocesos, la muestra `docker
inspect` y aparece en los volcados de diagnóstico—. En un servidor, un archivo montado con permisos del proceso es
mejor.

---

## 💻 3. El ejemplo que corre

```bash
uv add pydantic-settings
```

`config.py`:

```python
"""Secretos con tipo que no se imprime, leídos de archivos montados, y el filtro que tapa la bitácora."""

import logging
import os
import pathlib

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

# Lo que montaría Docker en /run/secrets; aquí, una carpeta local para el ejemplo.
secrets_dir = pathlib.Path("secrets")
secrets_dir.mkdir(exist_ok=True)
(secrets_dir / "aurea_cartera_db_password").write_text("Cartera-9f3K!")   # con el prefijo
os.environ["AUREA_DB_HOST"] = "cartera-db.interno"
os.environ["AUREA_PAYMENTS_TOKEN"] = "tok_live_51Hx9"            # este sí, por variable de entorno


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="AUREA_", secrets_dir="secrets")
    db_host: str
    cartera_db_password: SecretStr
    payments_token: SecretStr


settings = Settings()
print("configuración:", settings)


# ------------------------------------------------- el escape clásico, y su tapón
class RedactSecrets(logging.Filter):
    """Reemplaza los valores de los secretos conocidos en cualquier registro."""

    def __init__(self, *secrets: SecretStr):
        super().__init__()
        self.values = [s.get_secret_value() for s in secrets]

    def filter(self, record: logging.LogRecord) -> bool:
        message = record.getMessage()
        for value in self.values:
            message = message.replace(value, "[secreto]")
        record.msg, record.args = message, None
        return True


logging.basicConfig(format="%(levelname)s %(message)s", level=logging.INFO)
log = logging.getLogger("cartera")
dsn = (f"postgresql://cartera:{settings.cartera_db_password.get_secret_value()}"
       f"@{settings.db_host}/cartera")

log.error("no se pudo conectar a %s", dsn)                    # sin filtro: la contraseña sale
log.addFilter(RedactSecrets(settings.cartera_db_password, settings.payments_token))
log.error("no se pudo conectar a %s", dsn)                    # con filtro: tapada

# ------------------------------------------------- lo que ve un volcado del entorno
print("en el entorno:", sorted(k for k in os.environ if k.startswith("AUREA_")))
```

```bash
python3 config.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
configuración: db_host='cartera-db.interno' cartera_db_password=SecretStr('**********') payments_token=SecretStr('**********')
ERROR no se pudo conectar a postgresql://cartera:Cartera-9f3K!@cartera-db.interno/cartera
ERROR no se pudo conectar a postgresql://cartera:[secreto]@cartera-db.interno/cartera
en el entorno: ['AUREA_DB_HOST', 'AUREA_PAYMENTS_TOKEN']
```

Cuatro líneas, tres lecciones. La configuración entera se puede registrar al arrancar —es útil y no expone nada—
porque los secretos son `SecretStr`. La segunda línea es el escape real: en cuanto el secreto se saca de su
envoltorio para armar la cadena de conexión, vuelve a ser un `str` cualquiera, y el filtro de la tercera línea es
la red debajo. Y la última: la contraseña de la base, leída de un archivo, **no está en el entorno**; el token
de pagos, sí, y lo verá cualquier subproceso o volcado.

**Detalles con intención**

- **`secrets_dir`** lee cada campo de un archivo con su nombre, que es exactamente la forma de los secretos de
  Docker (`/run/secrets/<nombre>`) y de los volúmenes de secretos de Kubernetes. El nombre del archivo **lleva
  el `env_prefix`** (`aurea_cartera_db_password`): sin él, Pydantic no lo encuentra y falla con *Field
  required*, un error que no dice nada de archivos y que este ejemplo cometió en su primera corrida.
- **`get_secret_value()` aparece una sola vez**, en el punto donde se arma la conexión. Buscar ese nombre en el
  código es la auditoría de dónde salen los secretos.
- **El filtro va en el *logger*, no en el *handler***, para el ejemplo; en producción se pone en el *handler* raíz
  para que cubra también las bitácoras de las bibliotecas.
- **El filtro compara valores exactos**: no tapa el secreto codificado en base64 o recortado. Es la red, no la
  defensa principal.

---

## ⚠️ 4. Lo que se rompe

**El `.env` en el repositorio.** Un `git rm` posterior no lo borra del historial, y los bots que recorren GitHub
buscando claves lo encuentran en minutos. Si pasó, el secreto se **rota** —se considera filtrado—; limpiar el
historial es secundario. `detect-secrets` en un *pre-commit* lo evita antes de que pase; está sin versiones nuevas
desde 2024 (💤), pero sigue funcionando.

**Las variables locales en el rastreador de errores.** Sentry y similares capturan las variables locales de cada
marco del traceback, y `dsn` es una variable local. Es el mismo problema que `ob06` resolvió con `before_send`
para las cédulas: los secretos también se filtran ahí.

**El subproceso que hereda todo.** `subprocess.run(["herramienta"])` le pasa al hijo **todo** el entorno,
incluido `AUREA_PAYMENTS_TOKEN`. Si la herramienta registra su entorno al fallar, el token aparece en su
bitácora. Se le pasa `env=` explícito con solo lo que necesita.

**Vault sin rotación.** Instalar Vault y guardar en él las mismas contraseñas de siempre, sin rotarlas nunca, es
agregar un servicio crítico sin ganar lo que lo justifica: credenciales dinámicas y de vida corta. `hvac` 2.4.0 es
el cliente de Python; su última versión es de octubre de 2025.

---

## ⚖️ 5. Cuándo NO usarlo

**Vault, para cinco secretos.** Áurea tiene unos pocos procesos en un par de servidores. Archivos montados con
permisos del usuario del proceso, y una rotación manual anual documentada, cubren el riesgo sin operar Vault, que
pide su propia alta disponibilidad, sus copias y el problema de dónde guardar la llave para abrirlo.

**`keyring`, en un servidor.** Depende de un llavero de sesión de escritorio (el de macOS, Secret Service en
Linux). En un servidor o en un contenedor no hay ninguno, y `keyring` falla o cae a un almacenamiento que no
protege nada. Sirve para las herramientas de línea de comandos que el ingeniero corre en su máquina.

**El filtro de bitácora como única defensa.** Tapa lo que conoce. No reemplaza a no armar cadenas con secretos
donde no hace falta.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Imprime `settings.model_dump()`. **Criterio:** reportas si los secretos salen tapados o no, y por qué.
2. Agrega un `.gitignore` y comprueba que `secrets/` y `.env` no se pueden agregar. **Criterio:** `git status`
   no los muestra.
3. Corre un subproceso que imprima su entorno, con y sin `env=`. **Criterio:** el token aparece solo en el
   primer caso.

**🟡 Intermedio (4–6)**

4. Pon el filtro en el *handler* raíz y registra la cadena desde otro *logger*. **Criterio:** la contraseña sale
   tapada en los dos.
5. Instala `detect-secrets` como *pre-commit* e intenta confirmar un archivo con `tok_live_51Hx9`. **Criterio:**
   el *commit* se rechaza, y reportas qué detector lo encontró.
6. Usa `keyring` en tu máquina para guardar el token de una herramienta de línea de comandos. **Criterio:** la
   herramienta funciona sin variable de entorno ni archivo con el token.

**🟠 Difícil (7–9)**

7. Levanta Vault en modo de desarrollo en un contenedor (sin puertos por defecto) y lee el secreto con `hvac`.
   **Criterio:** `Settings` obtiene la contraseña de Vault, y la credencial de Vault viene de un archivo.
8. Monta el secreto con los secretos de Docker Compose. **Criterio:** `docker inspect` no muestra la contraseña;
   muestra el token de la variable de entorno.
9. Agrega al filtro el secreto codificado en base64 y en URL. **Criterio:** una prueba con las tres formas, tapadas.

**🔴 Muy difícil (10)**

10. Inventaría los secretos de Áurea y diseña su manejo. **Criterio:** una tabla y una página. *Rúbrica:* (a) cada
    secreto con dónde vive, quién lo lee y cada cuánto se rota; (b) el procedimiento escrito para rotar uno
    filtrado, con su tiempo; (c) por dónde podría escaparse cada uno y qué lo tapa; (d) cuándo se justificaría
    Vault, con una señal concreta.

---

## 📚 7. Referencias

**Documentación oficial**

- Pydantic Settings, secretos: https://docs.pydantic.dev/latest/concepts/pydantic_settings/#secrets
- Docker, secretos en Compose: https://docs.docker.com/compose/how-tos/use-secrets/
- `hvac`: https://python-hvac.org/en/stable/overview.html
- `keyring`: https://keyring.readthedocs.io/en/latest/
- OWASP, gestión de secretos: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html

**Orden de lectura sugerido:** la hoja de OWASP, que ordena el problema; después la sección de secretos de
Pydantic Settings.

---

## 🚀 8. Cierre

Dónde vive un secreto importa menos que por dónde se escapa. Dentro del programa viaja como `SecretStr` y sale de
su envoltorio en un solo lugar; en el servidor vive en un archivo montado y no en el entorno que heredan todos;
y un filtro en la bitácora es la red debajo. Si se filtra, se rota.

**La señal de que quedó bien:** *"Buscamos la contraseña de Cartera en todas las bitácoras del último mes y no
apareció ni una vez."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-se-fase-05 -m "op se05 cerrada: secretos con tipo, archivos montados y la bitácora tapada"
> ```
>
> Los commits llevan su prefijo (`op se05: …`) y los de ejercicio su número
> (`op se05 ej07: …`).
