# 🛡️ se07 — Defensa de la aplicación: deserializar, plantillas y dependencias

> Python para desarrolladores Java senior · **Carta** · Track `se` — Seguridad aplicada y
> criptografía · sección 7 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Las secciones anteriores protegieron los datos y las credenciales. Esta protege el programa de lo que recibe.
Python tiene tres puertas por las que un dato se convierte en código, y las tres aparecen en sistemas como el de
Áurea sin que nadie las haya abierto a propósito:

- **Deserializar con `pickle` o con YAML completo.** Un archivo de configuración o un mensaje de una cola que
  alguien más puede escribir.
- **Compilar una plantilla que vino del usuario.** El back-office deja que cada sede personalice el texto del
  recordatorio de cita, y el texto se compila como plantilla de Jinja2.
- **Instalar una dependencia.** Un paquete con una vulnerabilidad conocida, o con un nombre parecido al que se
  quería.

Este perfil conoce las dos primeras del mundo Java —la deserialización de `ObjectInputStream`, las expresiones de
plantillas en el servidor— y la tercera de Maven Central. La diferencia en Python es lo cortas que son: una
línea de YAML basta.

---

## 🧠 2. El modelo

| Puerta | La forma insegura | La forma segura | Lo detecta |
|---|---|---|---|
| `pickle` | `pickle.loads(datos_externos)` | JSON, o `pickle` solo entre procesos propios y con firma (`se02`) | `bandit` B301 |
| YAML | `yaml.load(texto, Loader=yaml.Loader)` | `yaml.safe_load(texto)` | `bandit` B506 |
| Plantilla del usuario | `jinja2.Template(texto_del_usuario)` | `SandboxedEnvironment`, o variables en vez de plantillas | Solo revisión humana |
| Dependencias | Versiones sin fijar y sin auditar | Archivo de bloqueo + `pip-audit` en CI | `pip-audit` |
| El propio código | `subprocess(shell=True)`, `eval`, SQL armado con f-strings | Listas de argumentos, consultas con parámetros | `bandit`, `ruff` (reglas `S`) |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, la deserialización insegura necesita una cadena de *gadgets* en el classpath —por eso hubo años de
parches a Commons Collections—. En Python no hace falta ninguna cadena: el formato de `pickle` incluye la
instrucción "llama a esta función con estos argumentos", y `yaml.Loader` también. **No hay versión segura de
`pickle` con datos externos**, igual que no la hay de `eval`.

### Esto sí funciona igual

Las consultas con parámetros. `cursor.execute("… WHERE cedula = %s", (cedula,))` en Python es el
`PreparedStatement` de Java, con la misma regla y por la misma razón.

---

## 💻 3. El ejemplo que corre

Las tres puertas, con una carga inofensiva —ejecutar `echo`— que muestra que se ejecutó código, y la forma segura
al lado.

```bash
uv add pyyaml jinja2
uv add --dev bandit
```

`puertas.py`:

```python
"""Tres formas de que un dato se vuelva código en Python, y su versión segura."""

import pickle
import subprocess

import yaml
from jinja2 import Template
from jinja2.sandbox import SandboxedEnvironment, SecurityError

# ------------------------------------------------- 1. YAML
doc = '!!python/object/apply:subprocess.check_output [["echo", "código del atacante (yaml)"]]'
print("yaml.load:     ", yaml.load(doc, Loader=yaml.Loader))
try:
    yaml.safe_load(doc)
except yaml.YAMLError as e:
    print("yaml.safe_load: rechazado:", str(e).splitlines()[0])


# ------------------------------------------------- 2. pickle
class Payload:
    def __reduce__(self):
        return subprocess.check_output, (["echo", "código del atacante (pickle)"],)


message = pickle.dumps(Payload())          # lo que alguien deja en la cola
print("pickle.loads:  ", pickle.loads(message))

# ------------------------------------------------- 3. plantilla escrita por el usuario
reminder = ("Hola {{ name }}, tu cita es mañana. "
            "{{ lipsum.__globals__.__builtins__.__import__('os')"
            ".popen('echo código del atacante: jinja').read() }}")
print("Template:      ", Template(reminder).render(name="Andrés"))
try:
    SandboxedEnvironment().from_string(reminder).render(name="Andrés")
except SecurityError as e:
    print("Sandboxed:      rechazado:", e)
```

```bash
python3 puertas.py
bandit -q -f custom --msg-template "{line}: {test_id} {severity} {msg}" puertas.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
yaml.load:      b'c\xc3\xb3digo del atacante (yaml)\n'
yaml.safe_load: rechazado: could not determine a constructor for the tag 'tag:yaml.org,2002:python/object/apply:subprocess.check_output'
pickle.loads:   b'c\xc3\xb3digo del atacante (pickle)\n'
Template:       Hola Andrés, tu cita es mañana. código del atacante: jinja

Sandboxed:      rechazado: access to attribute '__globals__' of 'function' object is unsafe.
```

Tres puertas, tres ejecuciones de `echo` que podrían haber sido cualquier comando con los permisos del proceso:
leer `/run/secrets` (`se05`), conectarse a la base de Cartera. La plantilla es la más traicionera, porque la
puerta la abrió una funcionalidad legítima —que cada sede personalice su mensaje— y el texto lo escribe un
usuario autenticado, no un atacante externo.

Y lo que dice `bandit` del mismo archivo (bandit 1.9.4, 05/10/2026):

```text
3: B403 LOW Consider possible security implications associated with pickle module.
4: B404 LOW Consider possible security implications associated with the subprocess module.
12: B506 MEDIUM Use of unsafe yaml load. Allows instantiation of arbitrary objects. Consider yaml.safe_load().
26: B301 MEDIUM Pickle and modules that wrap it can be unsafe when used to deserialize untrusted data, possible security issue.
```

`bandit` encontró el YAML y el `pickle`, y **no dice nada de la plantilla**: su regla de Jinja2 (B701, el
`autoescape` apagado) mira las llamadas a `Environment`, no a `Template`, y de todos modos trata otro problema,
el de inyectar HTML. Que el texto de la plantilla lo escriba un usuario no lo ve ninguna herramienta estática,
porque depende de dónde sale el texto.

Una nota de la corrida: la primera versión de la carga de Jinja2 terminaba en `(jinja)`, y `os.popen` la pasó
por `sh`, que falló con `Syntax error: "(" unexpected`. El error salió en la consola del servidor, no en la
respuesta: la carga sí se había ejecutado. Así se ve muchas veces una inyección real en una bitácora.

**Detalles con intención**

- **`SandboxedEnvironment`** bloquea el acceso a atributos internos (`__init__`, `__globals__`) y es la
  defensa correcta si las sedes **tienen** que escribir plantillas. Mejor todavía es no darles plantillas: un
  texto con marcadores fijos (`{nombre}`, `{hora}`) reemplazados con `str.replace` no tiene nada que explotar.
- **`yaml.safe_load`** solo construye tipos básicos (dict, list, str, números, fechas). Para casi toda
  configuración es suficiente, y es la que tiene que ser la costumbre.
- **El `pickle` no se arregla con `safe`**: no existe. Si dos procesos propios lo usan, el mensaje se firma
  (`hmac`, o Fernet de `se02`) y se verifica antes de deserializar.

---

## ⚠️ 4. Lo que se rompe

**El caché en disco con `pickle`.** `joblib`, `shelve`, `diskcache` y muchos cachés usan `pickle` por debajo.
Si el directorio del caché es escribible por otro usuario o por otro servicio, es una puerta. Pasa también con
modelos de aprendizaje automático descargados de internet (`torch.load` sin `weights_only=True`).

**`pip-audit` que nadie mira.** Correrlo una vez da una lista; lo que protege es que corra en CI y **rompa el
build** con una vulnerabilidad nueva. Y con un archivo de bloqueo (`uv.lock`): sin versiones fijas, lo que se
auditó no es lo que se instala.

**El nombre parecido.** `python-dateutil` es real; un paquete con un nombre de una letra de diferencia puede no
serlo. Los ataques de cadena de suministro en PyPI suelen ser así. La defensa es fijar dependencias en un
archivo de bloqueo revisado, y mirar el nombre exacto la primera vez que se agrega uno.

**`bandit` con cientos de avisos de severidad baja.** B404 avisa de *cualquier* `import subprocess`. Si nadie
filtra, el ruido entierra el B506. Se corre con `-ll` (media o más) en CI y se revisan los bajos una vez.

---

## ⚖️ 5. Cuándo NO usarlo

**`bandit` y `ruff` a la vez con las mismas reglas.** `ruff` implementa las reglas de `bandit` (prefijo `S`) y
corre en milisegundos. Si el proyecto ya usa `ruff` (`qa02`), activar `S` evita una herramienta más. `bandit`
se justifica por sus reglas que `ruff` no tiene o por un informe para auditoría.

**Un escáner comercial de dependencias, para un proyecto pequeño.** `pip-audit` consulta la base pública de
vulnerabilidades de Python y es suficiente para el tamaño de Áurea.

**`SandboxedEnvironment` como permiso para cualquier cosa.** Reduce el riesgo; no lo elimina, y tiene un
historial de escapes corregidos. Si se puede evitar que el usuario escriba plantillas, se evita.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Cambia `yaml.Loader` por `yaml.FullLoader` y corre. **Criterio:** reportas si la carga se ejecuta y qué dice la
   documentación de PyYAML sobre esa diferencia.
2. Corre `pip-audit` sobre un proyecto tuyo. **Criterio:** la lista, y para cada vulnerabilidad, la versión que la
   corrige.
3. Activa las reglas `S` de `ruff` sobre `puertas.py`. **Criterio:** comparas lo que encuentra con la salida de
   `bandit`.

**🟡 Intermedio (4–6)**

4. Reemplaza la plantilla de recordatorio por marcadores fijos. **Criterio:** la carga de la plantilla queda
   como texto literal en el mensaje.
5. Firma los mensajes `pickle` entre dos procesos con `hmac`. **Criterio:** un mensaje alterado se rechaza
   antes de llamar a `pickle.loads`.
6. Pon `pip-audit` en un *workflow* de CI con una dependencia vulnerable a propósito. **Criterio:** el *build*
   falla y el mensaje nombra el paquete.

**🟠 Difícil (7–9)**

7. Encuentra en un proyecto real (tuyo o de código abierto) un uso de `pickle` o de `yaml.load` y decide si es
   explotable. **Criterio:** quién puede escribir la entrada, y la conclusión con su razón.
8. Escribe una consulta SQL vulnerable con f-string, explótala con una cédula maliciosa contra SQLite, y
   corrígela. **Criterio:** la explotación devuelve filas de otros pacientes ficticios; la corrección, ninguna.
9. Configura `bandit` en *pre-commit* con un archivo de configuración que excluya las pruebas y marque los
   falsos positivos con `# nosec` y su razón. **Criterio:** cero avisos sin justificar.

**🔴 Muy difícil (10)**

10. Haz el inventario de las puertas de un sistema tuyo. **Criterio:** una tabla y una página. *Rúbrica:* (a) cada
    lugar donde un dato externo se deserializa, se compila o se ejecuta; (b) quién puede escribir esa entrada;
    (c) la defensa de cada uno y si una herramienta la vigila; (d) lo que ninguna herramienta ve y cómo se revisa.

---

## 📚 7. Referencias

**Documentación oficial**

- `pickle`, la advertencia: https://docs.python.org/3/library/pickle.html
- PyYAML, `load` y sus cargadores: https://pyyaml.org/wiki/PyYAMLDocumentation
- Jinja2, el entorno con *sandbox*: https://jinja.palletsprojects.com/en/stable/sandbox/
- `bandit`: https://bandit.readthedocs.io/en/latest/
- `pip-audit`: https://github.com/pypa/pip-audit

**Orden de lectura sugerido:** la advertencia de `pickle` (dos párrafos); después la página del *sandbox* de
Jinja2, que dice con honestidad lo que no protege.

---

## 🚀 8. Cierre

En Python, deserializar con `pickle` o con YAML completo y compilar una plantilla que escribió un usuario son
formas de ejecutar código. Se usan `safe_load` y JSON, plantillas con marcadores fijos o en *sandbox*, y
dependencias fijadas y auditadas en CI. Las herramientas encuentran casi todo; lo que no ven es de dónde viene el
texto, y eso se revisa a mano.

**La señal de que quedó bien:** *"`pip-audit` y `bandit -ll` corren en cada push y el build está verde, y nadie
del equipo sabría dónde poner un `pickle.loads` de una cola."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-se-fase-07 -m "op se07 cerrada: las tres puertas de datos a código y las dependencias auditadas"
> ```
>
> Los commits llevan su prefijo (`op se07: …`) y los de ejercicio su número
> (`op se07 ej07: …`).
