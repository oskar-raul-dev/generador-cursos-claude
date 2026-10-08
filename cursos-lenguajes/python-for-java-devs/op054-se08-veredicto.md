# ⚖️ se08 — Veredicto: el mínimo de seguridad que un equipo de uno sostiene

> Python para desarrolladores Java senior · **Carta** · Track `se` — Seguridad aplicada y
> criptografía · sección 8 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las siete anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track recorrió el modelo de amenazas ([`se01`](op047-se01-el-modelo.md)), el cifrado
([`se02`](op048-se02-cryptography-y-pynacl.md)), las contraseñas y las sesiones
([`se03`](op049-se03-contrasenas-y-tokens.md)), la autenticación delegada
([`se04`](op050-se04-oauth2-y-oidc.md)), los secretos ([`se05`](op051-se05-secretos.md)), TLS
([`se06`](op052-se06-tls-y-certificados.md)) y las puertas de datos a código
([`se07`](op053-se07-defensa-de-la-aplicacion.md)).

Cada sección tiene su herramienta de más —Vault, Keycloak, TLS mutuo, un escáner comercial—, y cada una se
justifica en una empresa con un equipo de seguridad. Áurea tiene un ingeniero que además hace todo lo demás, y
datos clínicos que, si se filtran, son un problema legal con nombre (la Ley 1581 de 2012, de protección de datos
personales).

La tesis del track: **la seguridad de un equipo de uno es la que no depende de acordarse**. Lo que una
herramienta revisa en cada push se sostiene; lo que depende de que alguien lo haga bien cada vez, se cae el
viernes a las seis de la tarde.

---

## 🧠 2. El modelo

| Pieza | Costo de operar | Veredicto para Áurea |
|---|---|---|
| Modelo de amenazas de una página (`se01`) | Una tarde al año | **Sí**: decide todo lo demás |
| Cifrado de campos con Fernet y rotación (`se02`) | Bajo | **Sí**, solo para los campos clínicos que salen del servidor |
| Argon2 + sesión opaca revocable (`se03`) | Bajo | **Sí**, si hay contraseñas locales |
| Autenticación delegada en Google Workspace (`se04`) | Bajo: el proveedor ya existe | **Sí** para el personal; los franquiciados, contraseñas locales |
| Keycloak propio (`se04`) | Medio-alto: un servicio crítico más | **No** por ahora |
| Secretos en archivos montados + `SecretStr` + filtro (`se05`) | Casi cero | **Sí** |
| Vault (`se05`) | Alto | **No**: pocos secretos, pocos servidores |
| TLS con CA interna o Let's Encrypt, y aviso de vencimiento (`se06`) | Bajo | **Sí** |
| TLS mutuo (`se06`) | Medio | **No** entre servicios del mismo servidor |
| `pip-audit` + `ruff` con reglas `S` en CI (`se07`) | Casi cero | **Sí**: es lo que no depende de acordarse |

Y la regla que ordena la tabla: **primero lo que se revisa solo, después lo que hay que operar**. Las filas de
"sí" son, casi todas, configuración que se escribe una vez y que una herramienta vigila después.

---

## 💻 3. El ejemplo que corre

Sin dependencias. `auditoria.py` recorre el código con `ast` y busca las siete formas de equivocarse que el
track encontró, una por sección. No reemplaza a `bandit` ni a `ruff`: es la lista propia de Áurea, las que esas
herramientas no conocen o tratan como ruido.

```python
"""Las siete formas de equivocarse del track, buscadas en el árbol de sintaxis."""

import ast
import pathlib
import sys

RULES = {
    "se02": "clave de cifrado escrita en el código",
    "se03": "jwt.decode sin algorithms=",
    "se03b": "resumen rápido (sha256/md5) cerca de una contraseña",
    "se05": "get_secret_value() dentro de una llamada a la bitácora",
    "se06": "verify=False",
    "se07": "yaml.load sin safe_load, o pickle.loads",
    "se07b": "jinja2.Template con texto que no es literal",
}
LOG_METHODS = {"debug", "info", "warning", "error", "exception", "critical"}


def dotted(node: ast.AST) -> str:
    if isinstance(node, ast.Attribute):
        return f"{dotted(node.value)}.{node.attr}"
    return node.id if isinstance(node, ast.Name) else ""


def check(tree: ast.AST) -> list[tuple[int, str]]:
    found = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and isinstance(node.value, ast.Constant):
            names = [dotted(t).lower() for t in node.targets]
            if any("key" in n or "clave" in n for n in names) and isinstance(node.value.value, bytes):
                found.append((node.lineno, "se02"))
        if not isinstance(node, ast.Call):
            continue
        fn, kwargs = dotted(node.func), {k.arg: k.value for k in node.keywords}
        if fn == "jwt.decode" and "algorithms" not in kwargs:
            found.append((node.lineno, "se03"))
        if fn in {"hashlib.sha256", "hashlib.md5"} and "password" in ast.unparse(node).lower():
            found.append((node.lineno, "se03b"))
        if fn.split(".")[-1] in LOG_METHODS and "get_secret_value" in ast.unparse(node):
            found.append((node.lineno, "se05"))
        if isinstance(kwargs.get("verify"), ast.Constant) and kwargs["verify"].value is False:
            found.append((node.lineno, "se06"))
        if fn in {"yaml.load", "pickle.loads", "pickle.load"}:
            found.append((node.lineno, "se07"))
        if fn in {"Template", "jinja2.Template"} and node.args and not isinstance(node.args[0], ast.Constant):
            found.append((node.lineno, "se07b"))
    return sorted(found)


SAMPLE = '''
import hashlib, httpx, jwt, yaml
from jinja2 import Template
FERNET_KEY = b"q0Zt3Vh0bS1N2b3BtZ0pXc2U4bGJjZ3RmT1VzRkR5bE0="
def login(password, token, raw, text, settings, log):
    digest = hashlib.sha256(password.encode()).hexdigest()
    claims = jwt.decode(token, "secreto")
    log.error("fallo con %s", settings.db_password.get_secret_value())
    r = httpx.get("https://cartera.interno", verify=False)
    config = yaml.load(raw, Loader=yaml.Loader)
    return Template(text).render()
'''

if __name__ == "__main__":
    sources = {p: p.read_text() for p in map(pathlib.Path, sys.argv[1:])} or {"ejemplo.py": SAMPLE}
    total = 0
    for path, source in sources.items():
        for line, rule in check(ast.parse(source)):
            print(f"{path}:{line}  [{rule}] {RULES[rule]}")
            total += 1
    print(f"{total} hallazgos")
    sys.exit(1 if total else 0)
```

```bash
python3 auditoria.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
ejemplo.py:4  [se02] clave de cifrado escrita en el código
ejemplo.py:6  [se03b] resumen rápido (sha256/md5) cerca de una contraseña
ejemplo.py:7  [se03] jwt.decode sin algorithms=
ejemplo.py:8  [se05] get_secret_value() dentro de una llamada a la bitácora
ejemplo.py:9  [se06] verify=False
ejemplo.py:10  [se07] yaml.load sin safe_load, o pickle.loads
ejemplo.py:11  [se07b] jinja2.Template con texto que no es literal
7 hallazgos
```

Una línea por sección del track, y un código de salida distinto de cero: con eso, la auditoría va al *pre-commit*
o al CI junto a `pip-audit` y `ruff`, y deja de depender de que alguien se acuerde de las siete reglas.

**Detalles con intención**

- **`ast`, no expresiones regulares**: `verify=False` dentro de un comentario o de una cadena no cuenta, y
  `verify = False` con espacios sí. El árbol de sintaxis ve el código como lo ve Python.
- **Las reglas son heurísticas a propósito.** La de `se03b` mira si la palabra `password` aparece en la llamada:
  dará falsos positivos y falsos negativos. Para un equipo de uno, una regla simple que se entiende vale más que
  una exacta que nadie mantiene.
- **Sale con 1 si encuentra algo**: es lo que hace que un CI la respete.

---

## ⚠️ 4. Lo que se rompe

**La auditoría que crece sin dueño.** Cada incidente agrega una regla, y en un año hay cuarenta y la mitad son
ruido. La misma regla que el resumen diario de `ob07`: una regla entra si atrapa un error que pasó o que estuvo
cerca de pasar, con la referencia al incidente.

**La lista de "sí" sin el modelo de amenazas.** La tabla de §2 es la de Áurea porque sale de su modelo de
`se01`. Copiarla a otro sistema sin rehacer el modelo es aplicar las respuestas de otro examen.

**Lo que ninguna herramienta ve.** El franquiciado que ve datos de otra sede porque la consulta no filtra por
sede: es un error de autorización, y no hay `bandit` que lo encuentre. Se prueba con pruebas (`qa`) que intentan,
como el franquiciado de Suba, leer una cita de Kennedy.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Con datos de pago con tarjeta.** PCI DSS exige controles que este mínimo no cubre —segmentación de red,
registros de acceso inmutables, revisiones formales—. Si Áurea empieza a guardar tarjetas, el veredicto es otro;
mejor aún, que las guarde la pasarela.

**Con un equipo de seguridad.** Si hay personas cuyo trabajo es operar Vault y Keycloak, las filas de "no"
cambian: el costo de operar se reparte, y lo que ganan esas herramientas —rotación automática, credenciales de vida
corta, una sola identidad para todo— vale más.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Corre la auditoría sobre un proyecto tuyo. **Criterio:** la lista de hallazgos, y cuáles son falsos positivos.
2. Llena la tabla de §2 para un sistema tuyo. **Criterio:** al menos dos filas de "no", con la señal concreta que
   las cambiaría.

**🟡 Intermedio (3–4)**

3. Agrega la regla de `subprocess` con `shell=True` y una cadena armada con f-string. **Criterio:** una prueba
   con un caso que la dispara y otro que no.
4. Pon la auditoría en *pre-commit* junto a `ruff` con reglas `S`. **Criterio:** un *commit* con `verify=False`
   se rechaza.

**🟠 Difícil (5–6)**

5. Escribe la prueba de autorización por sede: el franquiciado de Suba intenta leer una cita de Kennedy.
   **Criterio:** la prueba falla si se quita el filtro por sede de la consulta.
6. Reduce los falsos positivos de `se03b` mirando el nombre de la variable que recibe el resumen. **Criterio:**
   la tasa de falsos positivos sobre un proyecto real, antes y después.

**🔴 Muy difícil (7–8)**

7. Escribe el plan de seguridad de Áurea para los próximos dos años. **Criterio:** una página. *Rúbrica:* (a) qué
   se opera hoy y cuánto cuesta en horas; (b) qué se revisa solo y qué depende de alguien; (c) la señal concreta
   que haría adoptar Vault o Keycloak; (d) el riesgo que se acepta, por escrito.
8. Diseña el simulacro de filtración: una clave de Fernet aparece en un repositorio público. **Criterio:** el
   procedimiento paso a paso con tiempos. *Rúbrica:* (a) quién se entera y cómo; (b) la rotación sin perder los
   datos cifrados (`se02`); (c) cómo se comprueba que la clave vieja ya no descifra nada nuevo; (d) qué dice la
   Ley 1581 sobre avisar.

---

## 📚 7. Referencias

- `ast`: https://docs.python.org/3/library/ast.html
- OWASP, *Application Security Verification Standard* (el repositorio, con la versión vigente): https://github.com/OWASP/ASVS
- Ley 1581 de 2012: https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=49981

**Orden de lectura sugerido:** el nivel 1 del ASVS de OWASP, como lista de comprobación contra la tabla de §2;
el resto del track tiene sus referencias en cada sección.

---

## 🚀 8. Cierre

Para un equipo de uno, la seguridad que se sostiene es la que no depende de acordarse: secretos que no se
imprimen, sesiones que se revocan, dependencias auditadas y una lista corta de errores propios que una herramienta
busca en cada push. Vault, Keycloak y el TLS mutuo esperan a la señal concreta que los justifique.

**La señal de que quedó bien:** *"Un viernes a las seis alguien subió un `verify=False` para salir del paso, y el
CI no lo dejó pasar."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-se-fase-08 -m "op se08 cerrada: el mínimo de seguridad que no depende de acordarse"
> ```
>
> Los commits llevan su prefijo (`op se08: …`) y los de ejercicio su número
> (`op se08 ej07: …`).
