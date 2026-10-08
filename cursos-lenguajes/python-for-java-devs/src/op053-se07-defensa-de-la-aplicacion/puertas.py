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
