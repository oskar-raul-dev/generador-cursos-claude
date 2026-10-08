#!/usr/bin/env bash
# Last smoke-harness run per carta section, as session 5c52573d ran it (05/10/2026).
# A log of whole commands, not a script to run end to end: copy the block of one section.
# Most blocks cd into the carta's zz-code directory (python-for-java-devs-20261005-f516) themselves;
# the harness runs the code in a python:3.14.7 container labelled curso=python-for-java-devs.
set -uo pipefail

# --- ar03 · op149-ar03-opencv-y-svg.md · 2026-10-05T21:22:56Z
python3 - <<'EOF'
p='imagenes.py'; s=open(p).read()
s=s.replace("\nimport os\nprint(f\"insignia.svg","\nprint(f\"insignia.svg").replace('"""\n\nimport time\n','"""\n\nimport os\nimport time\n',1)
open(p,'w').write(s)
EOF
grep -n "^import" imagenes.py; rm -f rojo.png insignia.*
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
code=open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar03/imagenes.py').read().rstrip()
doc='''# 🎨 ar03 — OpenCV, scikit-image y SVG

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 3 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Pillow (`ar02`) redimensiona, rota y convierte. Cuando el trabajo es **analizar** la imagen —encontrar bordes, contar figuras, enderezar un documento
fotografiado—, entran las dos bibliotecas de procesamiento: **OpenCV**, la de C++ con enlaces de Python que usa la industria, y **scikit-image**, la de la comunidad
científica, escrita sobre NumPy y SciPy. Las dos trabajan con arreglos de NumPy, y las dos hacen casi lo mismo; lo que las separa son la velocidad y las
convenciones, y las convenciones son las que muerden.

La otra mitad de la sección va en sentido contrario: **generar** imágenes en vez de leerlas. Un gráfico, una insignia, un diagrama: como vector con SVG
(**drawsvg**) o como mapa de bits con **cairo** (`pycairo`). El ejemplo propio es una imagen de figuras con ruido y una insignia con un nombre de sede.

---

## 🧠 2. El modelo

| | OpenCV (`cv2`) | scikit-image |
|---|---|---|
| Escrita en | C++ con enlaces | Python sobre NumPy, SciPy y Cython |
| Imagen | `ndarray` `uint8`, **BGR** | `ndarray`, **RGB**; muchos filtros devuelven `float64` en [0, 1] |
| Velocidad | La más alta, con varios hilos | Menor; código legible y documentado |
| Instalar en un servidor | **`opencv-python-headless`** | `scikit-image` |
| Lo que la distingue | Video, cámaras, detección | API consistente, algoritmos científicos |

| | SVG (drawsvg) | cairo (`pycairo`) |
|---|---|---|
| Qué produce | Texto XML: vectores | Píxeles (PNG), y también PDF y SVG |
| Escala | Sin perder | Fija al tamaño de la superficie |
| Instalar | Python puro | Necesita la biblioteca de C del sistema |

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

En Java, una imagen es un `BufferedImage` con su tipo declarado (`TYPE_INT_RGB`), y la biblioteca sabe qué tiene. El instinto espera que un arreglo de imagen
también "sepa" su orden de canales. No sabe: es un `ndarray` de números. OpenCV supone BGR y scikit-image o Pillow suponen RGB, y un arreglo pasado de una a otra
cambia el rojo por el azul sin ningún error.

---

## 💻 3. El ejemplo que corre

`imagenes.py`:

```python
''' + code + '''
```

```bash
apt-get install libcairo2-dev pkg-config        # pycairo no publica ruedas para Linux: compila contra el cairo del sistema
pip install opencv-python-headless scikit-image drawsvg pycairo Pillow
python3 imagenes.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
OpenCV      7.5 ms · salida uint8, valores [0, 255], bordes 5,703
scikit-image 246.3 ms · salida bool, valores [False, True], bordes 5,650
filters.gaussian devuelve float64 en [0, 1], no uint8
rojo RGB escrito con OpenCV, leído con Pillow: (0, 0, 255)
insignia.svg 355 bytes (texto, escala sin perder) · insignia.png 4518 bytes (320×80 fijos)
```

El mismo trabajo —suavizar y buscar bordes con Canny— tarda **7,5 ms en OpenCV y 246 ms en scikit-image**, 33 veces más, y encuentran casi los mismos bordes
(5.703 contra 5.650 píxeles; los umbrales no son idénticos entre las dos). Pero devuelven tipos distintos: OpenCV un `uint8` con 0 y 255, scikit-image un `bool`; y
`filters.gaussian` convierte a `float64` en [0, 1], de modo que un umbral pensado en 0–255 no encuentra nada. El rojo escrito por OpenCV llega a Pillow como
**azul** (0, 0, 255). Y la insignia: 355 bytes de SVG que escalan a cualquier tamaño, contra 4,5 KB de PNG fijo.

**Detalles con intención**

- **`opencv-python-headless`** y no `opencv-python`: el segundo trae las ventanas de `cv2.imshow` y necesita `libGL`; en un servidor o un contenedor, el `import`
  falla con `ImportError: libGL.so.1: cannot open shared object file`.
- **`cv2.add`** suma con saturación (255 + 10 = 255); `img + ruido` en NumPy da la vuelta (255 + 10 = 9). Es otra convención que cambia entre bibliotecas.
- **`cv2.cvtColor(img, cv2.COLOR_BGR2RGB)`** es la conversión que falta antes de pasarle a Pillow o scikit-image una imagen de OpenCV.
- **La insignia en cairo** dibuja las esquinas redondeadas con cuatro arcos: cairo es una API de dibujo de bajo nivel, como `Graphics2D`.

---

## ⚠️ 4. Lo que se rompe

**`opencv-python` en el servidor.** Funciona en el portátil, falla en el contenedor por `libGL`. Y si alguna dependencia instala `opencv-python` y otra la versión
`-headless`, las dos pisan el mismo módulo `cv2`. Se instala una sola variante.

**El rojo que sale azul.** Cualquier imagen que cruza entre OpenCV y el resto pasa por `cvtColor`. Se escribe una función de frontera y se usa siempre.

**El umbral en la escala equivocada.** Un `float64` en [0, 1] comparado con 128 da todo falso. Se convierte con `skimage.util.img_as_ubyte` o se piensa el umbral en la
escala del tipo.

**pycairo que no instala.** Sin `libcairo2-dev` y `pkg-config`, `pip install pycairo` falla al compilar en Linux. En contenedores, el paquete del sistema va en el
`Dockerfile`.

---

## ⚖️ 5. Cuándo NO usarlas

**Para redimensionar y convertir.** Pillow (`ar02`) alcanza y pesa mucho menos que OpenCV.

**scikit-image en un bucle de video en tiempo real.** 33 veces más lenta que OpenCV en este trabajo; para prototipar y para ciencia, sí.

**cairo para un gráfico de datos.** Matplotlib o Altair (`vz`) ya dibujan ejes y leyendas; cairo es para dibujos propios.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las cinco líneas, y por qué el rojo sale azul.
2. Corrige el rojo con `cv2.cvtColor`. **Criterio:** Pillow lee (255, 0, 0).
3. Abre `insignia.svg` en el navegador y amplíalo al 800%. **Criterio:** los bordes siguen nítidos; con el PNG, no.

**🟡 Intermedio (4–6)**

4. Cuenta las figuras de la imagen con `cv2.findContours` y con `skimage.measure.label`. **Criterio:** las dos dan 2.
5. Repite la medición de Canny con `cv2.setNumThreads(1)`. **Criterio:** cuánto de la ventaja de OpenCV venía de los hilos.
6. Genera con drawsvg un gráfico de barras de cinco valores con sus etiquetas. **Criterio:** un SVG válido de menos de 2 KB.

**🟠 Difícil (7–9)**

7. Endereza la foto de un documento (detecta sus cuatro esquinas y aplica `cv2.warpPerspective`). **Criterio:** el documento queda rectangular.
8. Haz que cairo escriba la insignia en PDF en vez de PNG (`cairo.PDFSurface`). **Criterio:** un PDF vectorial con el texto seleccionable.
9. Mide la memoria de un *pipeline* de 100 imágenes en OpenCV y en scikit-image. **Criterio:** la memoria máxima de cada uno y por qué difieren.

**🔴 Muy difícil (10)**

10. Decide la biblioteca de un servicio que procesa fotos de documentos. **Criterio:** una página. *Rúbrica:* (a) las operaciones que necesita; (b) los tiempos medidos
    de las dos; (c) cómo se maneja el orden de canales en la frontera; (d) qué se instala en el contenedor y cuánto pesa.

---

## 📚 7. Referencias

**Documentación oficial**

- OpenCV en Python: https://docs.opencv.org/5.x/d6/d00/tutorial_py_root.html
- scikit-image: https://scikit-image.org/docs/stable/
- drawsvg: https://github.com/cduck/drawsvg
- pycairo: https://pycairo.readthedocs.io/en/latest/

**Orden de lectura sugerido:** la guía de usuario de scikit-image sobre tipos de datos (la escala de cada `dtype`); después los tutoriales de OpenCV de procesamiento
de imágenes.

---

## 🚀 8. Cierre

OpenCV y scikit-image hacen el mismo trabajo sobre los mismos arreglos de NumPy, una 33 veces más rápido que la otra en este ejemplo, y con convenciones distintas
que no avisan: BGR contra RGB, `uint8` contra `float64` en [0, 1]. Para generar, SVG escala sin perder y cairo dibuja píxeles con la biblioteca de C del sistema.

**La señal de que quedó bien:** *"Toda imagen que cruza entre OpenCV y el resto pasa por una sola función de conversión, y el contenedor instala la variante
`-headless`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-03 -m "op ar03 cerrada: OpenCV y scikit-image medidas, sus convenciones, SVG y cairo"
> ```
>
> Los commits llevan su prefijo (`op ar03: …`) y los de ejercicio su número
> (`op ar03 ej07: …`).
'''
open('op149-ar03-opencv-y-svg.md','w').write(doc)
PYEOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && timeout 590 python3 humo.py op149-ar03-opencv-y-svg.md ar03 'imagenes.py=@imagenes.py' --cmd 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y libcairo2-dev pkg-config >/dev/null 2>&1; timeout 400 pip install -q --root-user-action=ignore opencv-python-headless==5.0.0.93 scikit-image==0.26.0 drawsvg==2.4.2 pycairo==1.29.2 Pillow==12.3.0 >/dev/null 2>&1; python imagenes.py; python -c "
import numpy as np, cv2
from skimage import measure
img=np.zeros((50,50),np.uint8); a=np.uint8(250); print(\"numpy\", (np.array([250],np.uint8)+np.uint8(10))[0], \"cv2.add\", cv2.add(np.array([[250]],np.uint8), np.array([[10]],np.uint8))[0,0])"'

# --- au02 · op009-au02-scraping.md · 2026-10-05T16:06:29Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 - <<'EOF'
p='humo.py'; t=open(p).read()
a='''blocks = re.findall(r"(?:^|\\n)(.*)\\n\\n?```[a-z]*\\n(.*?)\\n```", text, re.S)'''
b='''def fenced(text):
    """(línea no vacía anterior a la cerca, contenido) de cada bloque de nivel superior."""
    out, lines, i = [], text.splitlines(), 0
    while i < len(lines):
        m = re.match(r"^(`{3,})[\\w-]*\\s*$", lines[i])
        if m:
            fence, j = m.group(1), i + 1
            while j < len(lines) and lines[j].rstrip() != fence:
                j += 1
            before = next((l for l in reversed(lines[:i]) if l.strip()), "")
            out.append((before, "\\n".join(lines[i + 1:j])))
            i = j + 1
        else:
            i += 1
    return out
blocks = fenced(text)'''
assert a in t; t=t.replace(a,b); open(p,'w').write(t)
EOF
python3 humo.py op009-au02-scraping.md au02 'circulares.py="""Extrae las circulares' --pip httpx==0.28.1 selectolax==1.0.0 beautifulsoup4==4.15.0 --cmd "python circulares.py"

# --- au03 · op010-au03-playwright.md · 2026-10-05T16:07:56Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op010-au03-playwright.md au03 'portal/index.html=<!doctype html>' 'portal/glosas.csv=factura;codigo;valor' 'radicar.py="""Radica' --pip playwright==1.63.0 --cmd "playwright install --with-deps chromium >/tmp/inst.log 2>&1 || tail -5 /tmp/inst.log; (python -m http.server 8000 --directory portal --bind 127.0.0.1 >/dev/null 2>&1 &) ; sleep 1; PORTAL_USER=aurea PORTAL_PASSWORD=prueba python radicar.py; ls -la rastro.zip glosas.csv | awk '{print \$5, \$9}'" 2>&1 | tail -15

# --- au04 · op011-au04-ssh-y-sistemas-remotos.md · 2026-10-05T16:10:01Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op011-au04-ssh-y-sistemas-remotos.md au04 'sede/Dockerfile=FROM debian:trixie-slim' 'revisar_respaldos.py="""Revisa por SSH' >/dev/null; cd salidas/au04; rm -f revisor revisor.pub; ssh-keygen -q -t ed25519 -N "" -f revisor -C "revisor de respaldos" && cp revisor.pub sede/; sed -i '' 's/SITES = {"Centro": ("127.0.0.1", 2201), "Suba": ("127.0.0.1", 2202)}/SITES = {"Centro": ("pfjd-centro", 22), "Suba": ("pfjd-suba", 22)}/' revisar_respaldos.py; grep -n "^SITES" revisar_respaldos.py; docker build -q --label curso=python-for-java-devs -t pfjd-sede:humo sede 2>&1 | tail -1; docker network create --label curso=python-for-java-devs pfjd-au04 >/dev/null; for s in centro suba; do docker run -d --rm --label curso=python-for-java-devs --network pfjd-au04 --name pfjd-$s pfjd-sede:humo >/dev/null; done; docker exec pfjd-centro sh -c 'head -c 2000000 /dev/urandom > /respaldos/odontovia.sql.gz'; docker exec pfjd-suba sh -c 'head -c 900000 /dev/urandom > /respaldos/odontovia.sql.gz && touch -d "120 days ago" /respaldos/odontovia.sql.gz'; docker run --rm --label curso=python-for-java-devs --network pfjd-au04 -v $PWD:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore paramiko==5.0.0 >/dev/null 2>&1; ssh-keyscan -t ed25519 pfjd-centro > known_hosts 2>/dev/null; ssh-keyscan -t ed25519 pfjd-suba >> known_hosts 2>/dev/null; python revisar_respaldos.py"

# --- au05 · op012-au05-apis-de-saas.md · 2026-10-05T16:13:47Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep '`keyring`' prompts/inventario-verificado.md; cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op012-au05-apis-de-saas.md au05 'agenda_franquicia.py="""Lee la agenda' 'prueba_agenda.py="""Prueba la renovación' --pip authlib==1.8.0 httpx==0.28.1 keyring --cmd "pip show keyring | grep Version; python prueba_agenda.py"

# --- au06 · op013-au06-desplegar-automatizaciones.md · 2026-10-05T16:16:11Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op013-au06-desplegar-automatizaciones.md au06 'revisar_circulares.py=# /// script' 'aurea-circulares.service=[Unit]
Description=Revisión' 'aurea-circulares.timer=[Unit]
Description=Todos' --pip uv==0.12.23 --cmd "PORTAL_TOKEN=prueba uv run -q --script revisar_circulares.py" 2>&1 | grep -v "^$" | tail -5; ls salidas/au06

# --- au07 · op014-au07-veredicto.md · 2026-10-05T16:18:02Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 -c "
fix=8.5/3
for n in range(3,7): print(n, round((8-n)*4 - n*fix,2))
print('doble', 20-17)"; python3 - <<'EOF'
f='op014-au07-veredicto.md'; t=open(f,encoding='utf-8').read()
a='''once horas y media en dos meses, porque cada corrida buena reemplaza media jornada de clics. Si su
tasa de rotura subiera al 60% con los mismos arreglos, el neto seguiría positivo; si cada arreglo
tomara el doble, ya no tanto —y esa es la pregunta que hay que hacerse cada trimestre—.'''
b='''once horas y media en dos meses, porque cada corrida buena reemplaza media jornada de clics. Pero el
margen es más angosto de lo que parece: con la misma duración media de arreglo (2,8 horas), **cinco
fallas de ocho** ya dan un neto negativo (−2,2 horas), mientras que con tres fallas y arreglos del
doble de largos todavía quedan tres horas a favor. La tasa de rotura pesa más que el tiempo de
arreglo, y esa es la pregunta que hay que hacerse cada trimestre.'''
assert a in t; open(f,'w',encoding='utf-8').write(t.replace(a,b))
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op014-au07-veredicto.md au07 'cuenta_robots.py="""¿Siguen valiendo' --cmd "python cuenta_robots.py"

# --- co01 · op015-co01-correo-saliente.md · 2026-10-05T16:20:22Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op015-co01-correo-saliente.md'; t=open(f,encoding='utf-8').read()
rep=[('''import ssl
from dataclasses import dataclass''','''import ssl
import unicodedata
from dataclasses import dataclass'''),
('''def check_attachment(item: Settlement) -> None:
    # La regla que evita el error del trimestre pasado: el PDF tiene que ser de esta sede.
    if item.franchise.lower() not in item.pdf.name.lower():''','''def ascii_slug(text: str) -> str:
    # "Zipaquirá" y "zipaquira" tienen que coincidir: los nombres de archivo no llevan tildes.
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()


def check_attachment(item: Settlement) -> None:
    # La regla que evita el error del trimestre pasado: el PDF tiene que ser de esta sede.
    if ascii_slug(item.franchise) not in ascii_slug(item.pdf.name):'''),
('''- **Todos los adjuntos se validan antes de mandar el primer correo.**''','''- **`ascii_slug` antes de comparar.** Sin él, "Zipaquirá" nunca coincide con
  `liquidacion-zipaquira-…pdf` y el programa se niega a mandar un correo correcto.
- **Todos los adjuntos se validan antes de mandar el primer correo.**''')]
for a,b in rep:
    assert a in t,a[:40]; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op015-co01-correo-saliente.md co01 'liquidaciones.py="""Manda a cada franquiciado' --pip aiosmtpd==1.4.6 --cmd "(python -m aiosmtpd -n -l 127.0.0.1:8025 > smtp.log 2>&1 &); sleep 1; SMTP_HOST=127.0.0.1 SMTP_PORT=8025 SMTP_TLS=0 python liquidaciones.py; sleep 1; grep -c 'Content-Type: application/pdf' smtp.log; grep -m2 '^Subject' smtp.log"

# --- co02 · op016-co02-que-el-correo-llegue.md · 2026-10-05T16:21:57Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op016-co02-que-el-correo-llegue.md'; t=open(f,encoding='utf-8').read()
for a,b in [('''import dkim
import dns.resolver''','''import base64

import dkim
import dns.resolver'''),('record = b"v=DKIM1; k=rsa; p=" + __import__("base64").b64encode(public_der)','record = b"v=DKIM1; k=rsa; p=" + base64.b64encode(public_der)')]:
    assert a in t; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op016-co02-que-el-correo-llegue.md co02 'diagnostico_correo.py="""Diagnóstico de entrega' --pip dnspython==2.8.0 dkimpy==1.1.8 cryptography==50.0.2 --cmd "python diagnostico_correo.py"

# --- co03 · op017-co03-correo-entrante.md · 2026-10-05T16:23:58Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op017-co03-correo-entrante.md co03 'buzon_cartera.py="""Procesa el buzón' 'prueba_buzon.py="""Mensajes de prueba' --pip imap-tools==1.15.0 --cmd "python prueba_buzon.py"

# --- co04 · op018-co04-probar-correo.md · 2026-10-05T16:25:59Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op018-co04-probar-correo.md co04 'envio.py="""Arma y manda' 'test_envio.py="""Pruebas del correo' --pip pytest aiosmtpd==1.4.6 --cmd "pytest -q -p no:cacheprovider test_envio.py 2>&1 | tail -2" | grep -v "^$"; S=salidas/co04; docker network create --label curso=python-for-java-devs pfjd-co04 >/dev/null; docker run -d --rm --label curso=python-for-java-devs --network pfjd-co04 --name pfjd-mailpit axllent/mailpit:v1.31.4 >/dev/null 2>&1; sleep 3; docker run --rm --label curso=python-for-java-devs --network pfjd-co04 -v $PWD/$S:/w -w /w -e PYTHONPATH=/w python:3.14.7 sh -c "python -c \"from envio import build_settlement, send; send(build_settlement('Suba', 'edgar.rojas@franquicias.example', 'liquidacion-suba.pdf', b'%PDF'), 'pfjd-mailpit', 1025)\"; python -c \"import json,urllib.request; d=json.load(urllib.request.urlopen('http://pfjd-mailpit:8025/api/v1/messages')); m=d['messages'][0]; print(d['total'], m['Subject'], m['Attachments'])\""; docker rm -f -v pfjd-mailpit >/dev/null 2>&1; docker network rm pfjd-co04 >/dev/null; docker image rm axllent/mailpit:v1.31.4 >/dev/null 2>&1; echo limpio

# --- co05 · op019-co05-transferencia-de-archivos.md · 2026-10-05T16:27:49Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op019-co05-transferencia-de-archivos.md'; t=open(f,encoding='utf-8').read()
a='''        source.prefetch(entry.st_size - offset)        # pide los bloques por adelantado: mucho más rápido'''
b='''        source.prefetch(entry.st_size)                 # el tamaño TOTAL, no lo que falta: pide por adelantado'''
assert a in t; t=t.replace(a,b)
a='''- **El `.part` se retoma** con `seek`:'''
b='''- **`prefetch` recibe el tamaño total del archivo**, no lo que falta por bajar: su documentación lo
  describe como el valor que devolvería `stat`. El primer borrador de esta sección le pasaba lo que
  faltaba, y al retomar no habría pedido el final del archivo.
- **El `.part` se retoma** con `seek`:'''
assert a in t; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/co05; mkdir -p $S/sftp; cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op019-co05-transferencia-de-archivos.md co05 'descargar_pagos.py="""Baja las relaciones' >/dev/null; cd $S; rm -f aurea_ed25519*; ssh-keygen -q -t ed25519 -N "" -f aurea_ed25519 -C aurea; cp aurea_ed25519.pub sftp/; cat > sftp/Dockerfile <<'EOF'
FROM debian:trixie-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server \
    && rm -rf /var/lib/apt/lists/* && mkdir -p /run/sshd /salida/aurea \
    && useradd -m -s /bin/bash aurea && chown aurea /salida/aurea
COPY aurea_ed25519.pub /home/aurea/.ssh/authorized_keys
RUN chown -R aurea /home/aurea/.ssh && chmod 600 /home/aurea/.ssh/authorized_keys
CMD ["/usr/sbin/sshd", "-D", "-e"]
EOF
docker build -q --label curso=python-for-java-devs -t pfjd-sftp:humo sftp >/dev/null && echo construida; docker network create --label curso=python-for-java-devs pfjd-co05 >/dev/null; docker run -d --rm --label curso=python-for-java-devs --network pfjd-co05 --name pfjd-sftp pfjd-sftp:humo >/dev/null; sleep 2; docker exec -u aurea pfjd-sftp sh -c 'cd /salida/aurea && python3 -c 1 2>/dev/null; head -c 48213 /dev/zero | tr "\0" "a" > pagos-septiembre.csv && touch -d "2 hours ago" pagos-septiembre.csv && head -c 12002 /dev/zero | tr "\0" "b" > pagos-octubre-1.csv && touch pagos-octubre-1.csv.ok && head -c 500 /dev/zero > pagos-octubre-2.csv'; docker run --rm --label curso=python-for-java-devs --network pfjd-co05 -v $S:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore paramiko==5.0.0 >/dev/null 2>&1; ssh-keyscan -t ed25519 pfjd-sftp > known_hosts 2>/dev/null; python descargar_pagos.py pfjd-sftp 22; python descargar_pagos.py pfjd-sftp 22"

# --- co06 · op020-co06-mensajeria.md · 2026-10-05T16:29:41Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op020-co06-mensajeria.md co06 'notificar.py="""Un notificador' --pip httpx==0.28.1 --cmd "python notificar.py"; for u in https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks/ https://core.telegram.org/bots/api https://www.twilio.com/docs/whatsapp/tutorial/send-whatsapp-notification-messages-templates "https://www.suin-juriscol.gov.co/viewDocument.asp?ruta=Leyes/1684507"; do curl -s -o /dev/null -m 30 -w "%{http_code} $u\n" -L -A "Mozilla/5.0" "$u"; done

# --- co07 · op021-co07-veredicto.md · 2026-10-05T16:31:17Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op021-co07-veredicto.md co07 'canales.py="""Clasifica los envíos' --cmd "python canales.py"

# --- db01 · op077-db01-el-db-api.md · 2026-10-05T18:09:13Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op077-db01-el-db-api.md db01 'dbapi.py=@dbapi.py' --svc pg=postgres:18.6 --env pg:POSTGRES_PASSWORD=aurea-local --pip "psycopg[binary]==3.3.6" --cmd 'python dbapi.py' 2>&1 | tail -8; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'; docker network ls --filter label=curso=python-for-java-devs --format '{{.Name}}'

# --- db02 · op078-db02-mysql-y-mariadb.md · 2026-10-05T18:10:27Z
python3 humo_servicio.py op078-db02-mysql-y-mariadb.md db02 'trampas.py="""Las tres trampas' --svc mysql=mysql:9.7.2 --env mysql:MYSQL_ROOT_PASSWORD=aurea-local --svc maria=mariadb:12.3.3 --env maria:MARIADB_ROOT_PASSWORD=aurea-local --pip PyMySQL==1.2.3 --cmd 'python trampas.py' 2>&1 | tail -16; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- db03 · op079-db03-sql-server-y-oracle.md · 2026-10-05T18:14:02Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op079-db03-sql-server-y-oracle.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''    oracledb.defaults.fetch_decimals = True
    cur.execute("SELECT valor FROM abono")
    print("  con fetch_decimals:", repr(cur.fetchone()[0]))
    cur.execute("DROP TABLE abono")''','''    oracledb.defaults.fetch_decimals = True               # vale para los cursores que se creen después
    with conn.cursor() as cur2:
        cur2.execute("SELECT valor FROM abono")
        print("  con fetch_decimals:", repr(cur2.fetchone()[0]))
    cur.execute("DROP TABLE abono")''')
rep('''    print("pymssql conectado a SQL Server", cur.fetchone()[0])''','''    print("pymssql conectado a SQL Server", cur.fetchone()[0])     # sql_variant: llega como bytes''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op079-db03-sql-server-y-oracle.md db03 'aliados.py=@aliados.py' --svc mssql=mcr.microsoft.com/mssql/server:2022-latest --env mssql:ACCEPT_EULA=Y --env 'mssql:MSSQL_SA_PASSWORD=Aurea-Local-2026!' --svc oracle=gvenzl/oracle-free:23-slim --env oracle:ORACLE_PASSWORD=aurea-local --pip pyodbc==5.3.0 pymssql==2.4.2 oracledb==26.0.1 --cmd 'python aliados.py' 2>&1 | tail -9; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- db04 · op080-db04-sqlite-a-fondo.md · 2026-10-05T18:13:24Z
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op080-db04-sqlite-a-fondo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''db.execute("CREATE TABLE cita (sede TEXT REFERENCES sede(codigo))")
''','''db.execute("CREATE TABLE cita (sede TEXT REFERENCES sede(codigo))")
db.commit()                                                            # el DDL también es transaccional
''')
rep("""- **`PRAGMA foreign_keys` es por conexión**""","""- **El `commit()` después de los `CREATE TABLE`** no es decorativo: en SQLite, como en Postgres, el DDL es transaccional, y el
  `rollback()` de la fila huérfana se habría llevado también las tablas. La primera versión de este ejemplo no lo tenía y
  falló con `no such table: cita`. (En MySQL y Oracle, en cambio, el DDL confirma solo.)
- **`PRAGMA foreign_keys` es por conexión**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op080-db04-sqlite-a-fondo.md db04 'sqlite_trampas.py="""Las tres trampas de SQLite' --cmd 'rm -f agenda.db*; python sqlite_trampas.py' 2>&1 | tail -8

# --- db05 · op081-db05-duckdb.md · 2026-10-05T18:15:38Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op081-db05-duckdb.md db05 'abonos.py=@abonos.py' --pip duckdb==1.5.6 --cmd 'rm -f aurea.duckdb aurea.duckdb.wal abonos.csv abonos.parquet; python abonos.py' 2>&1 | tail -10

# --- db06 · op082-db06-valkey.md · 2026-10-05T18:16:45Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op082-db06-valkey.md db06 'valkey_trampas.py=@valkey_trampas.py' --svc valkey=valkey/valkey:9.1 --pip redis==8.1.0 --cmd 'python valkey_trampas.py' 2>&1 | tail -9; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op082-db06-valkey.md | tail -2

# --- db07 · op083-db07-mongodb.md · 2026-10-05T18:17:59Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op083-db07-mongodb.md db07 'citas_mongo.py=@citas_mongo.py' --svc mongo=mongo:8.0.20 --pip pymongo==4.18.2 --cmd 'python citas_mongo.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op083-db07-mongodb.md | tail -3

# --- db08 · op084-db08-cassandra.md · 2026-10-05T18:19:14Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op084-db08-cassandra.md db08 'mensajeria.py=@mensajeria.py' --svc cassandra=cassandra:5.0 --env cassandra:MAX_HEAP_SIZE=512M --env cassandra:HEAP_NEWSIZE=128M --pip cassandra-driver==3.30.1 --cmd 'python mensajeria.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- db09 · op085-db09-neo4j.md · 2026-10-05T18:21:23Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op085-db09-neo4j.md db09 'derivaciones.py=@derivaciones.py' --svc neo4j=neo4j:2026.09.0-community --env neo4j:NEO4J_AUTH=neo4j/aurea-local-2026 --pip neo4j==6.4.0 --cmd 'python derivaciones.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- db10 · op086-db10-series-de-tiempo.md · 2026-10-05T18:24:31Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op086-db10-series-de-tiempo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('influx = InfluxDBClient3(host=os.environ.get("AUREA_INFLUX", "http://influx:8181"), database="sedes", token="")',
    'influx = InfluxDBClient3(host=os.environ.get("AUREA_INFLUX", "http://influx:8181"), database="sedes",\n                         token="local")                       # el servidor sin auth lo ignora, pero no acepta uno vacío')
rep("""- **`--without-auth`** es solo para el contenedor local del ejemplo. En cualquier otro lado, InfluxDB 3 se usa con *token*.""",
"""- **`--without-auth`** es solo para el contenedor local del ejemplo. En cualquier otro lado, InfluxDB 3 se usa con *token*. Aun sin
  autenticación, el cliente necesita un *token* no vacío: con `token=""` manda un encabezado `Authorization: Token ` incompleto y el
  servidor responde `400 Authorization header was malformed`, que fue el primer error de este ejemplo.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op086-db10-series-de-tiempo.md db10 'espera.py="""La misma semana' --svc tsdb=timescale/timescaledb:2.30.1-pg18 --env tsdb:POSTGRES_PASSWORD=aurea-local --svc influx=influxdb:3.12.0-core --args 'influx:influxdb3 serve --node-id aurea --object-store memory --without-auth' --pip "psycopg[binary]==3.3.6" influxdb3-python==0.21.0 --cmd 'python espera.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- db11 · op087-db11-vectorial.md · 2026-10-05T18:37:11Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op087-db11-vectorial.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''                     optimizers_config=models.OptimizersConfigDiff(indexing_threshold=1_000))   # en KB; ver el detalle''',
'''                     optimizers_config=models.OptimizersConfigDiff(         # ver el detalle: sin esto, no hay HNSW que medir
                         indexing_threshold=1_000, default_segment_number=1, max_segment_size=1_000_000))''')
rep('''print("  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count)''','''print("  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count, "· segmentos:", info.segments_count)''')
rep("""- **`indexing_threshold=1_000`** obliga a Qdrant a construir el índice. Por defecto no indexa segmentos de menos de unos 20 MB y
  los busca de forma exhaustiva: con los 12,8 MB de este ejemplo, la primera corrida dio *recall* 1,00 con cualquier `hnsw_ef` y el
  mismo tiempo que la búsqueda exacta, porque **no había índice**. Es una buena decisión del motor para colecciones chicas, y una
  trampa para quien mide.""","""- **La configuración de optimizadores** es lo que hace que haya un HNSW que medir, y costó dos corridas descubrirlo. En la primera,
  Qdrant no construyó el índice: por defecto no indexa segmentos de menos de unos 20 MB (`indexing_threshold`), y estos vectores
  pesan 12,8 MB. En la segunda, con el índice construido, repartió los vectores en cuatro segmentos chicos y los siguió recorriendo
  enteros, porque prefiere la búsqueda exhaustiva cuando lo que hay que recorrer es chico (`full_scan_threshold`, 10 MB por
  defecto). Las dos veces dio *recall* 1,00 con cualquier `hnsw_ef` y el mismo tiempo que la búsqueda exacta. Con segmentos grandes,
  la curva es la de pgvector. Son buenas decisiones del motor para colecciones chicas, y una trampa para quien mide.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && rm salidas/db11/vecinos_1seg.py salidas/db11/vecinos_nseg.py salidas/db11/correr.sh && python3 humo_servicio.py op087-db11-vectorial.md db11 'vecinos.py=@vecinos.py' --svc pgv=pgvector/pgvector:0.8.6-pg18 --env pgv:POSTGRES_PASSWORD=aurea-local --svc qdrant=qdrant/qdrant:v1.19.1 --pip "psycopg[binary]==3.3.6" pgvector==0.5.0 qdrant-client==1.19.1 numpy==2.5.3 --cmd 'python vecinos.py' 2>&1 | tail -12; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- db12 · op088-db12-busqueda.md · 2026-10-05T18:41:38Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op088-db12-busqueda.md db12 'faq.py=@faq.py' --svc search=opensearchproject/opensearch:3.8.0 --env search:discovery.type=single-node --env search:DISABLE_SECURITY_PLUGIN=true --env search:DISABLE_INSTALL_DEMO_CONFIG=true --env "search:OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m" --svc meili=getmeili/meilisearch:v1.54.3 --pip opensearch-py==3.2.0 meilisearch==0.43.0 --cmd 'python faq.py' 2>&1 | tail -16; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- db13 · op089-db13-objetos-s3.md · 2026-10-05T18:48:36Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op089-db13-objetos-s3.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("| `boto3` | 1.43.108 | La API completa de S3 |","| `boto3` | 1.43.108 (con `s3fs`, 1.43.106: ver §4) | La API completa de S3 |")
rep("""**Depender de MinIO sin mirar.**""","""**`boto3` y `s3fs` en el mismo proyecto.** `s3fs` usa `aiobotocore`, que fija un rango estrecho de `botocore`, y `boto3` exige su
`botocore` exacto. El 05/10/2026, `pip install boto3==1.43.108 s3fs==2026.9.0` falla con `ResolutionImpossible`; sin fijar `boto3`, el
resolvedor baja a 1.43.106, la última que `aiobotocore` 3.9.2 acepta. Con `uv` pasa lo mismo, y el archivo de bloqueo lo deja escrito.
Se fija `s3fs` y se deja que él elija `boto3`, no al revés.

**Depender de MinIO sin mirar.**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op089-db13-objetos-s3.md db13 'exportes.py=@exportes.py' --svc s3=rustfs/rustfs:1.0.1 --env s3:RUSTFS_ACCESS_KEY=aurea-local --env s3:RUSTFS_SECRET_KEY=aurea-local-secret --pip s3fs==2026.9.0 boto3 --cmd 'python exportes.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- db14 · op090-db14-bitacora-de-eventos.md · 2026-10-05T18:50:25Z
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op090-db14-bitacora-de-eventos.md");t=p.read_text()
a='admin = AdminClient({"bootstrap.servers": BROKER})\n'
assert t.count(a)==1
t=t.replace(a,'admin = AdminClient({"bootstrap.servers": BROKER})\nadmin.list_topics(timeout=60)                           # espera a que el broker responda\n')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op090-db14-bitacora-de-eventos.md db14 'eventos.py=@eventos.py' --svc kafka=apache/kafka:4.3.1 --env kafka:KAFKA_NODE_ID=1 --env kafka:KAFKA_PROCESS_ROLES=broker,controller --env kafka:KAFKA_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 --env kafka:KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092 --env kafka:KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER --env kafka:KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT --env kafka:KAFKA_CONTROLLER_QUORUM_VOTERS=1@kafka:9093 --env kafka:KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 --env kafka:KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 --env kafka:KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 --env kafka:KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=0 --svc nats=nats:2.15.0 --args 'nats:-js' --pip confluent-kafka==2.15.1 nats-py==2.16.0 --cmd 'python eventos.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- db15 · op091-db15-veredicto.md · 2026-10-05T18:52:26Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op091-db15-veredicto.md db15 'arbol.py="""¿Postgres o un especializado?' --cmd 'python arbol.py' 2>/dev/null | head -1

# --- ff01 · op139-ff01-el-modelo.md · 2026-10-05T20:46:56Z
python3 - <<'EOF'
p='op139-ff01-el-modelo.md'
s=open(p).read()
old='''3. Importa `json` con el acelerador deshabilitado (`import json.decoder; json.decoder.c_scanstring = None` antes de cargar) y mide `json.loads` de un archivo grande.
   **Criterio:** los dos tiempos.'''
new='''3. Compara `json.decoder.scanstring` (C) con `json.decoder.py_scanstring` (Python) sobre una cadena JSON de un millón de caracteres. **Criterio:** los dos tiempos.'''
assert old in s
s=s.replace(old,new); open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op139-ff01-el-modelo.md ff01 'frontera.py=@frontera.py' --pip numpy==2.5.3 --cmd "python frontera.py; python -c 'import json.decoder as d; print(d.py_scanstring, d.scanstring)'" && python3 plan.py 139 139 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op139-ff01-el-modelo.md | tail -3

# --- ff02 · op140-ff02-ctypes-y-cffi.md · 2026-10-05T20:48:31Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op140-ff02-ctypes-y-cffi.md'
s=open(p).read()
old=s[s.index("**El GIL tomado.**"):s.index("---\n\n## ⚖️ 5")]
new='''**El GIL suelto sin saberlo.** `ctypes` (con `CDLL`; `PyDLL` no) y `cffi` sueltan el GIL durante la llamada. Es lo que permite paralelizar con hilos, y también lo
que permite que dos hilos de Python entren a la vez en una biblioteca de C que no es segura para hilos y corrompan su estado. Se protege con un `threading.Lock`
o se lee la documentación de la biblioteca antes.

'''
s=s.replace(old,new); open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op140-ff02-ctypes-y-cffi.md ff02 'suavizado.c=@suavizado.c' 'frontera_c.py="""La misma' --pip cffi==2.1.1 --cmd "python frontera_c.py; python -c 'import ctypes; l=ctypes.CDLL(\"./libsuavizado.so\"); l.add.argtypes=[ctypes.c_double]*2; print(\"sin restype:\", l.add(1.0, 2.0))'"

# --- ff03 · op141-ff03-cython.md · 2026-10-05T20:51:46Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op141-ff03-cython.md ff03 'ema_v0.pyx=# Paso 0' 'ema_v1.pyx=# Paso 1' 'ema_v2.pyx=# Paso 2' 'ema_v3.pyx=# Paso 3' 'medir.py="""El suavizado' --pip Cython==3.3.0 setuptools==84.0.0 --cmd 'python medir.py; rm -f *.so *.c *.html; CFLAGS="-ffp-contract=off" python medir.py 2>&1 | tail -2'

# --- ff04 · op142-ff04-numba.md · 2026-10-05T20:54:34Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && rm -rf salidas/ff04/__pycache__ && python3 humo.py op142-ff04-numba.md ff04 'jit.py=@jit.py' --pip numba==0.68.0 --cmd 'python3 -X importtime -c "import numba" 2>&1 | tail -1; python3 jit.py; python3 jit.py | head -1; python3 -c "
import numpy as np, jit
jit.ema(np.zeros(3, dtype=np.float32), 0.1); print(jit.ema.signatures)" | tail -1'

# --- ff05b · op143-ff05-rust-y-cpp.md · 2026-10-05T21:00:20Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op143-ff05-rust-y-cpp.md'; s=open(p).read()
old="""El costo por llamada es de fracciones de microsegundo en las tres, centenares de
veces menos que los 0,5 µs… por llamada de `ctypes` en un millón (`ff02`: 497 ms); nanobind, que promete el menor costo, fue el más alto en esta llamada, porque
el resultado se crea con una cápsula que lo libera."""
new="""El costo por llamada es de **0,23 a 0,51 µs**, del orden del de `ctypes` con una suma
(`ff02`: 0,5 µs), aunque aquí cada llamada recibe y crea un arreglo de NumPy; nanobind, que promete el menor costo, fue el más alto en esta llamada, porque el
resultado se crea con una cápsula que lo libera."""
assert old in s; s=s.replace(old,new); open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && rm -rf salidas/ff05b && python3 humo.py op143-ff05-rust-y-cpp.md ff05b 'rs/Cargo.toml=[package]' 'rs/pyproject.toml=[build-system]
requires = ["maturin' 'rs/src/lib.rs=use numpy' 'pb/ema_pb.cpp=#include <pybind11' 'pb/pyproject.toml=[build-system]
requires = ["scikit-build-core>=1.1", "pybind11' 'pb/CMakeLists.txt=cmake_minimum_required(VERSION 3.15...3.31)
project(ema_pb' 'nb/ema_nb.cpp=#include <nanobind' 'nb/pyproject.toml=[build-system]
requires = ["scikit-build-core>=1.1", "nanobind' 'nb/CMakeLists.txt=cmake_minimum_required(VERSION 3.15...3.31)
project(ema_nb' 'construir.sh=set -euo pipefail
for dir' 'medir.py="""La misma función en Rust' --cmd 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y cargo >/dev/null 2>&1; export PIP_ROOT_USER_ACTION=ignore; pip install -q numpy==2.5.3 cmake >/dev/null 2>&1; bash construir.sh; cd /tmp && python /w/medir.py' 2>&1 | tail -8

# --- jv01 · op092-jv01-los-formatos-de-la-jvm.md · 2026-10-05T18:56:52Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op092-jv01-los-formatos-de-la-jvm.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''    print("esquema del archivo:", reader.writer_schema["name"], "· escrito por:", reader.metadata.get("avro.codec"))''','''    print("esquema del archivo:", reader.writer_schema["name"], "· códec:", reader.codec)''')
rep("esquema del archivo: co.aurea.cartera.Abono · escrito por: null","esquema del archivo: co.aurea.cartera.Abono · códec: null")
rep("""- **El archivo Avro lleva su esquema adentro**""","""- **Las tres líneas `SLF4J(W): No SLF4J providers were found`** que imprime Java no son un error: Avro registra con SLF4J y en `lib/`
  no hay implementación. En un servicio de verdad la pone Spring Boot (Logback); aquí se agrega `slf4j-nop` o se ignoran.
- **El archivo Avro lleva su esquema adentro**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op092-jv01-los-formatos-de-la-jvm.md jv01 'lee_abonos.py="""Leer en Python' --cmd 'true' >/dev/null && docker run --rm --label curso=python-for-java-devs -v "$PWD/salidas/jv01:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore fastavro==1.12.2 >/dev/null 2>&1; python lee_abonos.py' 2>&1 | head -2

# --- jv02 · op093-jv02-jpype-y-py4j.md · 2026-10-05T19:00:16Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op093-jv02-jpype-y-py4j.md");t=p.read_text()
a="py = per_call_us(lambda: (142_900_000 * 450 + 5_000) // 10_000, 100_000)"
assert t.count(a)==1
t=t.replace(a,"sales, bps = 142_900_000, 450                 # en variables: con constantes, Python precalcula la cuenta\npy = per_call_us(lambda: (sales * bps + 5_000) // 10_000, 100_000)")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op093-jv02-jpype-y-py4j.md jv02 'src/main/java/co/aurea/Regalias.java=package co.aurea;' 'llamar_java.py="""La liquidación Java' --pip JPype1==1.7.1 py4j==0.10.9.9 --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jdk-headless >/dev/null 2>&1; rm -rf build regalias.jar; javac -d build src/main/java/co/aurea/Regalias.java && jar cf regalias.jar -C build . && python llamar_java.py' 2>&1 | tail -5

# --- jv03 · op094-jv03-graalpy-y-jython.md · 2026-10-05T19:02:05Z
curl -s -o /dev/null -w '%{http_code}\n' https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.4/jython-standalone-2.7.4.jar; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op094-jv03-graalpy-y-jython.md jv03 'cuenta.py="""El mismo bucle' --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jre-headless >/dev/null 2>&1; [ -d graalpy ] || (curl -sfL -o g.tgz https://github.com/oracle/graalpython/releases/download/graal-25.4.4/graalpy3.13-community-25.4.4-linux-aarch64.tar.gz && mkdir graalpy && tar xzf g.tgz -C graalpy --strip-components=1 && rm g.tgz); [ -f jython.jar ] || curl -sfL -o jython.jar https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.4/jython-standalone-2.7.4.jar; python cuenta.py; graalpy/bin/graalpy cuenta.py; echo ---; for i in 1 2 3; do /usr/bin/time -f "python -c pass %e s" python -c pass; done 2>&1 | sort | head -1; for i in 1 2 3; do /usr/bin/time -f "graalpy -c pass %e s" graalpy/bin/graalpy -c pass; done 2>&1 | sort | head -1; echo ---; java -jar jython.jar -c "print \"Python 2 sí\""; java -jar jython.jar -c "sede = \"Suba\"; print(f\"regalía de {sede}\")"' 2>&1 | tail -25

# --- jv04 · op095-jv04-la-arquitectura-mixta.md · 2026-10-05T19:07:15Z
python3 humo.py op095-jv04-la-arquitectura-mixta.md jv04 'ServidorRegalias.java=import com.sun.net.httpserver.HttpServer;' 'frontera.py="""El costo de una frontera' --pip httpx==0.28.1 --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jdk-headless >/dev/null 2>&1; java -Dsun.net.httpserver.nodelay=true ServidorRegalias.java > java.log 2>&1 & python frontera.py' 2>/dev/null | grep "µs\|diferencias"

# --- ob01 · op040-ob01-las-senales.md · 2026-10-05T17:05:57Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op040-ob01-las-senales.md ob01 'eventos.py="""Un evento ancho' --cmd "python eventos.py; head -c 300 eventos-cierre.jsonl"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op040-*.md

# --- ob02 · op041-ob02-bitacoras.md · 2026-10-05T17:07:01Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op041-ob02-bitacoras.md ob02 'registro.py="""logging configurado' --pip structlog==26.1.0 httpx==0.28.1 --cmd "python registro.py"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op041-*.md

# --- ob03 · op042-ob03-metricas.md · 2026-10-05T17:08:15Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op042-ob03-metricas.md ob03 'metricas_cierre.py="""Métricas de un proceso' --pip prometheus-client==0.26.0 --cmd "python metricas_cierre.py | grep -v '^# HELP\|_created'; python -c \"import inspect, prometheus_client.exposition as e; src=inspect.getsource(e.write_to_textfile); print('replace' in src or 'rename' in src)\""

# --- ob04 · op043-ob04-trazas.md · 2026-10-05T17:10:18Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op043-ob04-trazas.md ob04 'trazas_cierre.py="""Trazas del cierre' --pip opentelemetry-sdk==1.45.0 opentelemetry-instrumentation-httpx==0.66b0 httpx==0.28.1 --cmd "python trazas_cierre.py" | grep -E "GET|traceparent"

# --- ob05 · op044-ob05-perfilado-en-produccion.md · 2026-10-05T17:12:10Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op044-ob05-perfilado-en-produccion.md'; t=open(f,encoding='utf-8').read()
a='    _cache[request_id] = b"x" * 2048          # 2 KB por petición, para siempre'
b='    _cache[request_id] = bytes(2048)          # 2 KB nuevos por petición, para siempre'
assert a in t; open(f,'w',encoding='utf-8').write(t.replace(a,b))
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op044-ob05-perfilado-en-produccion.md ob05 'agenda_con_fuga.py="""Un servicio con una fuga' >/dev/null; docker run --rm --label curso=python-for-java-devs --cap-add SYS_PTRACE -v $PWD/salidas/ob05:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore py-spy==0.4.2 >/dev/null 2>&1; python agenda_con_fuga.py > servicio.log 2>&1 & PID=\$!; sleep 2; py-spy dump --pid \$PID 2>&1 | sed -n '3,6p'; kill -USR1 \$PID; sleep 5; kill -USR1 \$PID; sleep 1; kill \$PID; cat servicio.log; python -c 'import dis; dis.dis(compile(\"b\\\"x\\\" * 2048\",\"\",\"eval\"))' | head -3"

# --- ob06 · op045-ob06-errores-como-producto.md · 2026-10-05T17:13:38Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op045-ob06-errores-como-producto.md ob06 'errores.py="""Captura de errores con sentry-sdk' --pip sentry-sdk==2.71.0 --cmd "python errores.py; echo '--- sin before_send'; sed 's/    before_send=before_send,/    before_send=None,/' errores.py > sin.py; python -c \"
import sin, json
for e in sin.SENT[:1]:
    ex = e['exception']['values'][0]
    print('mensaje:', ex['value'])
    print('vars del marco:', [f.get('vars') for f in ex['stacktrace']['frames'] if f.get('vars')][-1:])
\""

# --- ob07 · op046-ob07-veredicto.md · 2026-10-05T17:14:53Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op046-ob07-veredicto.md ob07 'resumen_diario.py="""El resumen de las 7:00' --cmd "python resumen_diario.py"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op046-*.md

# --- or01 · op103-or01-el-eje.md · 2026-10-05T19:24:44Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op103-or01-el-eje.md or01 'eje.py=@eje.py' --pip SQLAlchemy==2.1.3 PyPika==0.51.1 --cmd 'python eje.py' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op103-or01-el-eje.md | tail -2

# --- or02 · op104-or02-sqlalchemy-a-fondo.md · 2026-10-05T19:26:01Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op104-or02-sqlalchemy-a-fondo.md or02 'a_fondo.py=@a_fondo.py' --pip SQLAlchemy==2.1.3 --cmd 'python a_fondo.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op104-or02-sqlalchemy-a-fondo.md | tail -3

# --- or03 · op105-or03-active-record.md · 2026-10-05T19:27:20Z
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op105-or03-active-record.md");t=p.read_text()
t=re.sub(r"^(\s*)(\w+\.\w+ = \"[^\"]+\"); (\w+(?:_s)?\.(?:save|commit)\(\))(\s*#.*)?$", lambda m: f"{m.group(1)}{m.group(2)}{m.group(4) or ''}\n{m.group(1)}{m.group(3)}", t, flags=re.M)
p.write_text(t)
print(t.count("; "))
EOF
grep -n '\.save()\|_s.commit()' op105-or03-active-record.md | head; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op105-or03-active-record.md or03 'perdida.py=@perdida.py' --pip peewee==4.5.2 Django==6.1.1 SQLAlchemy==2.1.3 --cmd 'python perdida.py' 2>&1 | tail -5

# --- or04 · op106-or04-pony.md · 2026-10-05T19:29:25Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op106-or04-pony.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''def is_overdue(plan_code: str) -> bool:                # una función de Python cualquiera
    return plan_code.endswith("3")


with db_session:
    try:
        select(p for p in Plan if is_overdue(p.codigo))[:]
    except Exception as e:
        print(f"\\nno se puede traducir: {type(e).__name__}: {str(e)[:90]}")''','''def ends_in_3(code: str) -> bool:                      # simple: Pony la descompila y la mete en el SQL
    return code.endswith("3")


def has_a_3(code: str) -> bool:                         # con un bucle: no hay SQL que la represente
    for ch in code:
        if ch == "3":
            return True
    return False


with db_session:
    for check in (ends_in_3, has_a_3):
        try:
            q = select(p for p in Plan if check(p.codigo))
            print(f"\\n{check.__name__}: {len(q[:])} planes ·", q.get_sql().splitlines()[-1])
        except Exception as e:
            print(f"\\n{check.__name__}: {type(e).__name__}: {e}")''')
rep("""**Funciones de Python dentro del generador.** Pony traduce lo que conoce: atributos, comparaciones, operadores, sus funciones de agregado y
algunas de cadenas y fechas. Una función propia como `is_overdue` no tiene traducción a SQL, y la consulta falla. La lógica se escribe con lo
traducible o se filtra después en Python.""","""**Funciones de Python dentro del generador.** Pony va más lejos de lo que parece: una función propia **simple** la descompila también y la
mete en el SQL —`ends_in_3` se volvió `LIKE '%3'`, cosa que la primera versión de este ejemplo daba por imposible y la corrida desmintió—. Lo que
no puede traducir es lo que no tiene forma de SQL: un bucle, una expresión regular (`re.search` falla dentro de sus propias funciones internas),
una llamada a otra biblioteca. Ahí la consulta falla con `TranslationError`, y la lógica se escribe con lo traducible o se filtra después en
Python.""")
rep("3. Reescribe `is_overdue` con lo que Pony traduce (`p.codigo.endswith(\"3\")` dentro del generador). **Criterio:** la consulta corre.","3. Reescribe `has_a_3` con lo que Pony traduce (`\"3\" in p.codigo`). **Criterio:** la consulta corre, y muestras el SQL que generó.")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && rm salidas/or04/sonda.py && python3 humo.py op106-or04-pony.md or04 'pony_saldos.py=@pony_saldos.py' --pip pony==0.7.20 --cmd 'python pony_saldos.py' 2>&1 | tail -5

# --- or05 · op107-or05-los-asincronos.md · 2026-10-05T19:31:09Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op107-or05-los-asincronos.md or05 'asincronos.py=@asincronos.py' --pip "SQLAlchemy[asyncio]==2.1.3" aiosqlite==0.22.1 tortoise-orm==1.1.8 --cmd 'python -X dev asincronos.py 2>&1 | head -30' 2>&1 | head -30

# --- or06 · op108-or06-sin-orm.md · 2026-10-05T19:32:44Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op108-or06-sin-orm.md");t=p.read_text()
a='print("los tres con más saldo:", queries.saldos_por_sede(conn, sede="Suba", n=3))'
assert t.count(a)==1
t=t.replace(a,'print("los tres con más saldo:", list(queries.saldos_por_sede(conn, sede="Suba", n=3)))   # aiosql 15: un generador')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op108-or06-sin-orm.md or06 'cartera.sql=-- name: crear_tablas#' 'reporte.py=@reporte.py' --pip aiosql==15.0 sqlglot==30.21.0 --cmd 'python reporte.py' 2>/dev/null | grep -v "^$"

# --- or07 · op109-or07-migraciones.md · 2026-10-05T19:34:13Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op109-or07-migraciones.md");t=p.read_text()
a='''    last = [m for m in read_migrations("migraciones") if m.id == "0002_fases"]
    backend.rollback_migrations(backend.to_rollback(last))'''
assert t.count(a)==1
t=t.replace(a,'''    backend.rollback_one(next(m for m in read_migrations("migraciones") if m.id == "0002_fases"))''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op109-or07-migraciones.md or07 'migraciones/0001_planes.sql=@0001_planes.sql' 'migraciones/0001_planes.rollback.sql=@0001_planes.rollback.sql' 'migraciones/0002_fases.sql=@0002_fases.sql' 'migraciones/0002_fases.rollback.sql=@0002_fases.rollback.sql' 'migrar.py=@migrar.py' --pip yoyo-migrations==9.0.0 --cmd 'rm -f aurea.db; python migrar.py; yoyo list --database sqlite:///aurea.db migraciones' 2>&1 | tail -12

# --- or08 · op110-or08-veredicto.md · 2026-10-05T19:36:04Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op110-or08-veredicto.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''def with_django_navigating():
    owed = {p.codigo: sum(f.valor for f in p.fases.all() if f.estado == "pendiente")
            for p in DjPlan.objects.filter(sede="Suba")}
    return sorted(owed.items(), key=lambda kv: -kv[1])[:3]


def with_django_aggregating():
    q = (DjPlan.objects.filter(sede="Suba")
         .annotate(saldo=Sum("fases__valor", filter=Q(fases__estado="pendiente")))
         .order_by("-saldo").values_list("codigo", "saldo")[:3])
    return list(q)''','''def with_django_navigating():
    owed = {p.codigo: sum(f.valor for f in DjFase.objects.filter(plan=p) if f.estado == "pendiente")
            for p in DjPlan.objects.filter(sede="Suba")}
    return sorted(owed.items(), key=lambda kv: -kv[1])[:3]


def with_django_aggregating():
    q = (DjFase.objects.filter(plan__sede="Suba", estado="pendiente").values("plan__codigo")
         .annotate(saldo=Sum("valor")).order_by("-saldo").values_list("plan__codigo", "saldo")[:3])
    return list(q)''')
rep("from django.db.models import Q, Sum  # noqa: E402","from django.db.models import Sum  # noqa: E402")
rep("| Django ORM | ORM | Active Record | `plan.fases.all()` | `annotate(Sum(...))` |","| Django ORM | ORM | Active Record | Fases de cada plan | `values(...).annotate(Sum(...))` |")
rep("""- **Solo se cuentan los `SELECT`**:""","""- **Django se escribe desde `DjFase`**: en un *script* sin aplicación instalada, Django no registra las relaciones inversas (`plan.fases`) y la
  primera corrida falló con `Cannot resolve keyword 'fases'`. En un proyecto Django normal, las dos direcciones funcionan; la medición no
  cambia.
- **Solo se cuentan los `SELECT`**:""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op110-or08-veredicto.md or08 'seis.py="""La misma consulta en seis' --pip SQLAlchemy==2.1.3 peewee==4.5.2 Django==6.1.1 pony==0.7.20 aiosql==15.0 --cmd 'rm -f aurea.db; python seis.py' 2>&1 | tail -14

# --- pk01 · op131-pk01-el-modelo-real.md · 2026-10-05T20:12:14Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op131-pk01-el-modelo-real.md pk01 'entorno.py="""Abrir un entorno virtual' --cmd 'mkdir -p /tmp/t && cp entorno.py /tmp/t/ && cd /tmp/t && python entorno.py' 2>&1 | tail -9; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op131-pk01-el-modelo-real.md | tail -2

# --- pk02 · op132-pk02-pip-venv-y-pip-tools.md · 2026-10-05T20:13:55Z
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op132-pk02-pip-venv-y-pip-tools.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep(".venv/bin/pip-compile --quiet --generate-hashes --output-file requirements.txt requirements.in",".venv/bin/pip-compile --quiet --strip-extras --generate-hashes --output-file requirements.txt requirements.in")
rep('''# Alguien (o algo) altera un hash: el paquete descargado ya no coincide.
sed -i '0,/--hash=sha256:[0-9a-f]\\{4\\}/s//--hash=sha256:0000/' requirements.txt''','''# Alguien (o algo) altera los hashes: lo que se descarga ya no coincide con ninguno.
sed -i 's/--hash=sha256:[0-9a-f]\\{4\\}/--hash=sha256:0000/g' requirements.txt''')
rep("""- **Una línea en `requirements.in`, seis paquetes fijados**: `httpx` trae `anyio`, `certifi`, `h11`, `httpcore` e `idna`. Sin `pip-compile`, esas cinco quedan a la
  suerte del día de la instalación.""","""- **Una línea en `requirements.in`, siete paquetes fijados**: `httpx` trae `anyio`, `certifi`, `h11`, `httpcore`, `idna` y `typing-extensions`. Sin `pip-compile`,
  esas seis quedan a la suerte del día de la instalación.
- **Dos *hashes* por paquete** (la rueda y el código fuente): `pip` acepta el archivo si coincide con **cualquiera** de los dos. La primera versión de este ejemplo
  alteró uno solo y la instalación pasó igual, porque descargó la rueda, cuyo *hash* seguía bien. La protección es contra un archivo distinto, no contra
  una línea editada del `requirements.txt`; esa la protege la revisión del *diff*.
- **`--strip-extras`** quita los *extras* (`paquete[extra]`) del archivo compilado; `pip-tools` avisa que será el comportamiento por defecto en la versión 8, y
  conviene fijarlo ya.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op132-pk02-pip-venv-y-pip-tools.md pk02 'requirements.in=@requirements.in' 'fijar.sh=@fijar.sh' --cmd 'rm -rf /tmp/t && mkdir -p /tmp/t && cp requirements.in fijar.sh /tmp/t/ && cd /tmp/t && python3 -m venv .venv && .venv/bin/pip install -q pip-tools==7.6.1 && bash fijar.sh' 2>&1 | tail -11

# --- pk03 · op133-pk03-uv.md · 2026-10-05T20:15:35Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op133-pk03-uv.md pk03 'probar_uv.sh=@probar_uv.sh' 'ritmo.py="""Cuántas versiones' --pip uv==0.12.23 --cmd 'rm -rf /tmp/t && mkdir -p /tmp/t && cp probar_uv.sh ritmo.py /tmp/t/ && cd /tmp/t && bash probar_uv.sh; python ritmo.py uv pip poetry pdm' 2>&1 | tail -12; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op133-pk03-uv.md | tail -2

# --- pk04 · op134-pk04-conda-y-compania.md · 2026-10-05T20:23:12Z
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op134-pk04-conda-y-compania.md");t=p.read_text()
a='  pip install --no-cache-dir gdal 2>&1 | grep -m1 -iE "gdal-config|error:" || echo "pip: instaló"'
assert t.count(a)==1
t=t.replace(a,'  pip install --no-cache-dir gdal 2>&1 | grep -m1 "gdal-config" || echo "pip: instaló"')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op134-pk04-conda-y-compania.md pk04 'binario.sh=#!/bin/sh' --cmd 'true' >/dev/null; D=$PWD/salidas/pk04; timeout 280 docker run --rm --label curso=python-for-java-devs -v "$D:/w" python:3.14.7 sh /w/binario.sh 2>&1 | tail -2; echo "-----"; timeout 580 docker run --rm --label curso=python-for-java-devs -v "$D:/w" condaforge/miniforge3:26.7.2-0 sh /w/binario.sh 2>&1 | tail -6

# --- pk05 · op135-pk05-poetry-y-pdm.md · 2026-10-05T20:36:28Z
docker stop dfd3b0a066ff >/dev/null && echo detenido; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op135-pk05-poetry-y-pdm.md pk05 'medir_gestores.sh=set -euo pipefail' --cmd 'timeout 200 pip install -q --root-user-action=ignore uv==0.12.23 && timeout 300 uv pip install --system -q poetry==2.5.1 pdm==2.29.2 && echo herramientas-listas && rm -rf /tmp/t && mkdir -p /tmp/t && cp medir_gestores.sh /tmp/t/ && cd /tmp/t && timeout 900 bash medir_gestores.sh' 2>&1 | tail -6

# --- pk06 · op136-pk06-empaquetar-y-publicar.md · 2026-10-05T20:37:55Z
python3 humo.py op136-pk06-empaquetar-y-publicar.md pk06 'publicar.sh=set -euo pipefail' --cmd 'timeout 200 pip install -q --root-user-action=ignore uv==0.12.23 && timeout 300 uv pip install --system -q twine==7.0.0 pypiserver==2.4.2 && rm -rf /tmp/t && mkdir -p /tmp/t && cp -r aurea-cartera publicar.sh /tmp/t/ && cd /tmp/t && timeout 400 bash publicar.sh' 2>/dev/null | grep -E "publicado|HTTPError|^\\$"

# --- pk07 · op137-pk07-entregar-a-quien-no-es-ingeniero.md · 2026-10-05T20:42:23Z
timeout 600 python3 humo.py op137-pk07-entregar-a-quien-no-es-ingeniero.md pk07 'regalias/regalias.py=@regalias/regalias.py' 'regalias_pep723.py=# /// script' 'entregar.sh=set -euo pipefail' --pip shiv pex uv --cmd "export PIP_ROOT_USER_ACTION=ignore; apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y unzip >/dev/null 2>&1; bash entregar.sh 2>&1"

# --- pk08 · op138-pk08-veredicto.md · 2026-10-05T20:44:01Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op138-pk08-veredicto.md pk08 'gestor.py="""¿uv' --cmd "python3 gestor.py"

# --- pr01 · op123-pr01-el-eje.md · 2026-10-05T19:59:31Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op123-pr01-el-eje.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''syntax = "proto3";
message CitaConfirmada {
  string sede = 1;''','''syntax = "proto3";
package aurea.v1;
message CitaConfirmada {
  string sede = 1;''')
rep('''syntax = "proto3";
message CitaConfirmada {
  string sede_nombre = 1;''','''syntax = "proto3";
package aurea.v2;
message CitaConfirmada {
  string sede_nombre = 1;''')
rep('''python -m grpc_tools.protoc -I v1 --python_out=v1 v1/cita.proto
python -m grpc_tools.protoc -I v2 --python_out=v2 v2/cita.proto''','''python -m grpc_tools.protoc -I . --python_out=. v1/cita.proto v2/cita.proto''')
rep("""**La versión del código generado.**""","""**Dos versiones del mismo archivo en un proceso.** Protobuf registra cada archivo y cada mensaje en un *pool* global del proceso: dos `cita.proto`
generados con `-I v1` y `-I v2` se llaman igual adentro, y el segundo `import` falla con `duplicate file name cita.proto`, que fue el primer error de
este ejemplo. Las versiones conviven con un `package` distinto (`aurea.v1`, `aurea.v2`) y generando desde la raíz, para que la ruta forme parte del
nombre.

**La versión del código generado.**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && rm -f salidas/pr01/v1/*_pb2.py salidas/pr01/v2/*_pb2.py && python3 humo.py op123-pr01-el-eje.md pr01 'v1/cita.proto=@v1/cita.proto' 'v2/cita.proto=@v2/cita.proto' 'eje.py=@eje.py' --pip pydantic==2.13.5 grpcio-tools==1.84.0 protobuf==7.36.2 --cmd 'python -m grpc_tools.protoc -I . --python_out=. v1/cita.proto v2/cita.proto && python eje.py' 2>&1 | tail -6

# --- pr02 · op124-pr02-grpc-y-protobuf.md · 2026-10-05T20:00:46Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op124-pr02-grpc-y-protobuf.md pr02 'agenda.proto=@agenda.proto' 'agenda.py="""Un servicio gRPC de prueba' --pip grpcio==1.84.0 grpcio-tools==1.84.0 protobuf==7.36.2 --cmd 'python -m grpc_tools.protoc -I . --python_out=. --grpc_python_out=. agenda.proto && python agenda.py' 2>&1 | tail -6

# --- pr03 · op125-pr03-formatos-binarios.md · 2026-10-05T20:01:53Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op125-pr03-formatos-binarios.md pr03 'evento.proto=@evento.proto' 'formatos.py=@formatos.py' --pip orjson==3.12.0 msgspec==0.22.0 msgpack==1.2.3 cbor2==6.1.5 protobuf==7.36.2 grpcio-tools==1.84.0 fastavro==1.12.2 --cmd 'python -m grpc_tools.protoc -I . --python_out=. evento.proto && python formatos.py' 2>&1 | tail -14; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op125-pr03-formatos-binarios.md | tail -2

# --- pr04 · op126-pr04-graphql.md · 2026-10-05T20:10:49Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op126-pr04-graphql.md pr04 'portal.py=@portal.py' --pip strawberry-graphql==0.331.5 --cmd 'python portal.py' 2>/dev/null | grep -v "^$" && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/| Strawberry | 0.331.2 | \*\*Clases con anotaciones de tipo\*\* (`@strawberry.type`) |/| Strawberry | 0.331.5 | **Clases con anotaciones de tipo** (`@strawberry.type`) |/' op126-pr04-graphql.md && grep -c "0.331.5" op126-pr04-graphql.md

# --- pr05 · op127-pr05-tiempo-real.md · 2026-10-05T20:04:25Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op127-pr05-tiempo-real.md pr05 'tiempo_real.py=@tiempo_real.py' --pip fastapi==0.142.2 uvicorn==0.54.0 sse-starlette==3.5.0 websockets==17.2 httpx==0.28.1 --cmd 'timeout 60 python tiempo_real.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op127-pr05-tiempo-real.md | tail -2

# --- pr06 · op128-pr06-mensajeria-como-contrato.md · 2026-10-05T20:07:09Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op128-pr06-mensajeria-como-contrato.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''        exchange = await ch.declare_exchange("agenda", aio_pika.ExchangeType.TOPIC)
        dead = await ch.declare_exchange("agenda.muertos", aio_pika.ExchangeType.FANOUT)
        invalid_q = await ch.declare_queue("citas.invalidas")
        await invalid_q.bind(dead)
        queue = await ch.declare_queue("recordatorios", arguments={"x-dead-letter-exchange": "agenda.muertos"})''','''        exchange = await ch.declare_exchange("agenda", aio_pika.ExchangeType.TOPIC, durable=True)
        dead = await ch.declare_exchange("agenda.muertos", aio_pika.ExchangeType.FANOUT, durable=True)
        invalid_q = await ch.declare_queue("citas.invalidas", durable=True)       # RabbitMQ 4: colas durables
        await invalid_q.bind(dead)
        queue = await ch.declare_queue("recordatorios", durable=True,
                                       arguments={"x-dead-letter-exchange": "agenda.muertos"})''')
rep("""**El contrato que solo valida el productor.**""","""**Las colas no durables en RabbitMQ 4.** `declare_queue("x")` sin `durable=True` declara una cola transitoria y compartida, y RabbitMQ 4.3 ya no las
permite por defecto: la conexión se cierra con `INTERNAL_ERROR - Feature transient_nonexcl_queues is deprecated`, que fue el primer error de este ejemplo. El
código de casi todos los tutoriales tiene esa línea. Las colas compartidas se declaran durables (o exclusivas, si son de una sola conexión).

**El contrato que solo valida el productor.**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op128-pr06-mensajeria-como-contrato.md pr06 'asyncapi.yaml=@asyncapi.yaml' 'contrato.py=@contrato.py' --svc rabbit=rabbitmq:4.3.6-alpine --pip aio-pika==10.1.0 jsonschema==4.26.0 PyYAML==6.0.3 --cmd 'timeout 120 python contrato.py' 2>&1 | tail -6; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- pr07 · op129-pr07-versionado-de-contratos.md · 2026-10-05T20:09:01Z
python3 humo.py op129-pr07-versionado-de-contratos.md pr07 'cartera_api.py="""La API de cartera' 'romper.py="""¿La versión nueva' --pip fastapi==0.142.2 uvicorn==0.54.0 schemathesis==4.29.3 --cmd 'uvicorn cartera_api:app --port 8141 --log-level critical > uvicorn.log 2>&1 & sleep 3; schemathesis run http://127.0.0.1:8141/openapi.json --checks not_a_server_error --max-examples 200 > st.log 2>&1; echo "exit=$?"; cat st.log | tail -30; python romper.py' 2>/dev/null | tail -40

# --- pr08 · op130-pr08-veredicto.md · 2026-10-05T20:10:11Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op130-pr08-veredicto.md pr08 'protocolo.py="""¿REST o una' --cmd 'python protocolo.py' 2>/dev/null | grep -v "^$"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op130-pr08-veredicto.md | tail -2

# --- qa01 · op039-qa10-veredicto.md · 2026-10-05T17:03:46Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op039-qa10-veredicto.md qa01 'presupuesto.py="""Lee el reporte JUnit' --pip pytest==9.1.1 hypothesis==6.168.4 --cmd "pytest -q -p no:cacheprovider -m 'not integration' --junitxml=reporte.xml >/dev/null 2>&1; python presupuesto.py reporte.xml; echo exit=\$?"

# --- qa02 · op031-qa02-pytest-a-fondo.md · 2026-10-05T16:47:53Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op031-qa02-pytest-a-fondo.md'; t=open(f,encoding='utf-8').read()
a=t[t.index("def pytest_addoption(parser):"):t.index("```\n\n`test_regalias.py`:")]
b='''def pytest_addoption(parser):
    parser.addoption("--budget", type=float, default=None,
                     help="falla la sesión si alguna prueba tarda más de estos segundos")


BUDGET: list[float | None] = [None]
SLOW: list[tuple[str, float]] = []


def pytest_configure(config):
    BUDGET[0] = config.getoption("--budget")


def pytest_runtest_logreport(report):
    if BUDGET[0] is not None and report.when == "call" and report.duration > BUDGET[0]:
        SLOW.append((report.nodeid, report.duration))


def pytest_terminal_summary(terminalreporter, exitstatus, config):
    if SLOW:
        terminalreporter.section("fuera del presupuesto")
        for nodeid, duration in SLOW:
            terminalreporter.write_line(f"{duration:.2f} s  {nodeid}")


def pytest_sessionfinish(session, exitstatus):
    if SLOW and session.exitstatus == 0:
        session.exitstatus = 1                         # una prueba lenta hace fallar la suite rápida
'''
t=t.replace(a,b)
t=t.replace("..........                                                               [100%]",".........                                                                [100%]").replace("10 passed in 1.02s","9 passed in 1.02s").replace("Diez pruebas pasaron, y la sesión termina","Nueve pruebas pasaron, y la sesión termina")
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op031-qa02-pytest-a-fondo.md qa02 'conftest.py="""Fixtures compartidas' 'test_regalias.py="""Pruebas que usan' --pip pytest==9.1.1 --cmd "pytest -q -p no:cacheprovider --budget 0.5 test_regalias.py; echo exit=\$?; pytest -q -p no:cacheprovider --collect-only test_regalias.py | head -6"

# --- qa03 · op032-qa03-dobles-y-datos.md · 2026-10-05T16:49:24Z
python3 -c "
import datetime as dt
print(dt.date(2026,10,5).strftime('%A'))
def due(d,n=15):
    r=n
    while r:
        d+=dt.timedelta(days=1)
        if d.weekday()<5: r-=1
    return d
print(due(dt.date(2026,9,18)), due(dt.date(2026,9,25)))"; curl -s https://pypi.org/pypi/holidays/json | python3 -c "import json,sys;d=json.load(sys.stdin);v=d['info']['version'];print('holidays',v,d['releases'][v][0]['upload_time'][:10])"; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op032-qa03-dobles-y-datos.md qa03 'glosas.py="""Glosas notificadas' 'test_glosas.py="""La red simulada' --pip pytest==9.1.1 httpx==0.28.1 pydantic==2.13.5 respx==0.23.1 time-machine==3.5.1 polyfactory==3.3.0 Faker==40.40.0 --cmd "pytest -q -s -p no:cacheprovider test_glosas.py 2>&1 | tail -15"

# --- qa04 · op033-qa04-integracion-de-verdad.md · 2026-10-05T16:51:27Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op033-qa04-integracion-de-verdad.md'; t=open(f,encoding='utf-8').read()
a='from testcontainers.postgres import PostgresContainer'
assert a in t; t=t.replace(a,'from testcontainers.community.postgres import PostgresContainer')
a='''- **La imagen tiene etiqueta fija** (`postgres:18.6`),'''
b='''- **`testcontainers.community.postgres`**: en la versión 4.15 los módulos de cada servicio se mudaron a
  `testcontainers.community`, y el import de siempre (`testcontainers.postgres`) sigue funcionando con
  un `DeprecationWarning`. La prueba de esta sección lo encontró así.
- **La imagen tiene etiqueta fija** (`postgres:18.6`),'''
assert a in t; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op033-qa04-integracion-de-verdad.md qa04 'conftest.py="""Un PostgreSQL de verdad' >/dev/null; S=$PWD/salidas/qa04; docker run --rm --label curso=python-for-java-devs -v /var/run/docker.sock:/var/run/docker.sock -v $S:/w -w /w -e TESTCONTAINERS_RYUK_DISABLED=true -e TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal python:3.14.7 sh -c "pip install -q --root-user-action=ignore pytest==9.1.1 'testcontainers[postgres]==4.15.0' sqlalchemy 'psycopg[binary]' >/dev/null 2>&1; pytest -q -p no:cacheprovider test_liquidaciones_db.py 2>&1 | tail -2"; docker ps -a --format '{{.Names}}' | grep -c .

# --- qa05 · op034-qa05-propiedades-y-modelos.md · 2026-10-05T16:52:48Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op034-qa05-propiedades-y-modelos.md qa05 'agenda.py="""La agenda de un odontólogo' 'test_agenda_estado.py="""La agenda contra un modelo' --pip pytest==9.1.1 hypothesis==6.168.4 --cmd "pytest -q -p no:cacheprovider test_agenda_estado.py 2>&1 | grep -E 'AssertionError|Falsifying|state|bookings_|failed|passed' | head -12"

# --- qa06 · op035-qa06-medir-la-suite.md · 2026-10-05T16:54:18Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; mkdir -p salidas/qa06/tests; python3 humo.py op035-qa06-medir-la-suite.md qa06 'regalias.py="""La regalía trimestral' 'tests/test_regalias.py=from decimal import Decimal' 'pyproject.toml=[tool.mutmut]' >/dev/null; S=$PWD/salidas/qa06; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w -e COLUMNS=120 python:3.14.7 sh -c "pip install -q --root-user-action=ignore pytest==9.1.1 pytest-cov==7.1.0 mutmut==3.8.0 >/dev/null 2>&1; pytest -q -p no:cacheprovider --cov=regalias --cov-branch --cov-report=term-missing 2>&1 | grep -A3 '^Name'; mutmut run > run1.log 2>&1; mutmut results 2>&1 | tail -12; echo; mutmut results 2>&1 | grep -c survived"

# --- qa07 · op036-qa07-carga-y-rendimiento.md · 2026-10-05T16:57:28Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op036-qa07-carga-y-rendimiento.md qa07 'agenda_api.py="""AgendaAPI mínima' 'locustfile.py="""Una auxiliar' 'test_rendimiento.py="""El cálculo de vencimientos' --pip fastapi uvicorn locust==2.46.7 pytest==9.1.1 pytest-benchmark==5.3.0 --cmd "(uvicorn agenda_api:app --port 8000 --workers 2 > uvicorn.log 2>&1 &); sleep 3; locust -f locustfile.py --headless -u 60 -r 20 -t 20s --host http://127.0.0.1:8000 --only-summary 2>&1 | grep -E 'Type|/disponibilidad|/reservas|Aggregated|CPU|percentiles' | head -10; pytest -q -p no:cacheprovider test_rendimiento.py --benchmark-autosave 2>&1 | tail -2; pytest -q -p no:cacheprovider test_rendimiento.py --benchmark-compare --benchmark-compare-fail=mean:20% 2>&1 | tail -2"

# --- qa08 · op037-qa08-la-cadena-de-calidad.md · 2026-10-05T16:59:26Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; mkdir -p salidas/qa08/cartera; python3 humo.py op037-qa08-la-cadena-de-calidad.md qa08 'cartera/reporte.py="""Un módulo con un defecto' 'pyproject.toml=[project]' --pip ruff==0.16.10 mypy==2.4.0 bandit==1.9.4 deptry==0.25.1 vulture==2.16 requests --cmd "touch cartera/__init__.py; echo '--- ruff'; ruff check cartera/ --output-format concise 2>&1 | tail -6; echo '--- mypy'; mypy cartera/ 2>&1 | tail -6; echo '--- bandit'; bandit -q -r cartera/ 2>&1 | grep -E 'Issue|Location' ; echo '--- deptry'; deptry . 2>&1 | grep -v '^Scanning\|^$' | head -4; echo '--- vulture'; vulture cartera/"

# --- qa09 · op038-qa09-e2e-con-playwright.md · 2026-10-05T17:01:48Z
curl -s https://pypi.org/pypi/python-multipart/json | python3 -c "import json,sys;d=json.load(sys.stdin);v=d['info']['version'];print('python-multipart',v,d['releases'][v][0]['upload_time'][:10])"; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op038-qa09-e2e-con-playwright.md'; t=open(f,encoding='utf-8').read()
a='''```bash
uv add fastapi uvicorn
uv add --dev pytest pytest-playwright
uv run playwright install chromium
```'''
b='''```bash
uv add fastapi uvicorn python-multipart
uv add --dev pytest pytest-playwright
uv run playwright install chromium
```

`python-multipart` no es opcional: sin él, el primer formulario que recibe FastAPI falla con
`RuntimeError: Form data requires "python-multipart" to be installed.` FastAPI no lo instala solo,
porque no todas las API reciben formularios.'''
assert a in t; open(f,'w',encoding='utf-8').write(t.replace(a,b))
p='prompts/check-inventario.py'; t=open(p,encoding='utf-8').read()
a='"python-fasthtml", "click",'; assert a in t; open(p,'w',encoding='utf-8').write(t.replace(a,'"python-fasthtml", "python-multipart", "fastapi", "uvicorn", "click",'))
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op038-qa09-e2e-con-playwright.md qa09 'sitio.py="""El sitio de reservas' --pip fastapi uvicorn python-multipart pytest==9.1.1 pytest-playwright==0.9.0 --cmd "playwright install --with-deps chromium >/tmp/inst.log 2>&1; pytest -q -p no:cacheprovider --base-url http://127.0.0.1:8765 --tracing retain-on-failure test_reserva_e2e.py 2>&1 | tail -3"

# --- se01 · op047-se01-el-modelo.md · 2026-10-05T17:16:23Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op047-se01-el-modelo.md se01 'protecciones.py="""La misma notificación' --pip cryptography==50.0.2 --cmd "python protecciones.py"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op047-*.md; curl -s -A "Mozilla/5.0" https://nostarch.com/serious-cryptography-2nd-edition | grep -o -i "<title>[^<]*</title>\|20[0-9][0-9]</[^>]*>" | head -3

# --- se02 · op048-se02-cryptography-y-pynacl.md · 2026-10-05T17:17:36Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op048-se02-cryptography-y-pynacl.md se02 'cifrado_backoffice.py="""Una columna cifrada' --pip cryptography==50.0.2 pynacl==1.6.2 --cmd "python cifrado_backoffice.py"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op048-*.md

# --- se03 · op049-se03-contrasenas-y-tokens.md · 2026-10-05T17:19:44Z
python3 humo.py op049-se03-contrasenas-y-tokens.md se03 'acceso.py=@acceso.py' --pip argon2-cffi==25.1.0 pyjwt==2.15.1 --cmd "python acceso.py" 2>&1 | tail -20

# --- se04 · op050-se04-oauth2-y-oidc.md · 2026-10-05T17:21:12Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op050-se04-oauth2-y-oidc.md se04 'oidc.py=@oidc.py' --pip authlib==1.8.0 joserfc==1.7.5 --cmd "python oidc.py" 2>&1 | tail -20

# --- se05 · op051-se05-secretos.md · 2026-10-05T17:22:56Z
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op051-se05-secretos.md");t=p.read_text()
old='(secrets_dir / "cartera_db_password").write_text("Cartera-9f3K!")'
assert old in t
t=t.replace(old,'(secrets_dir / "aurea_cartera_db_password").write_text("Cartera-9f3K!")   # con el prefijo')
old2="""- **`secrets_dir`** lee cada campo de un archivo con su nombre, que es exactamente la forma de los secretos de
  Docker (`/run/secrets/<nombre>`) y de los volúmenes de secretos de Kubernetes."""
assert old2 in t
t=t.replace(old2,"""- **`secrets_dir`** lee cada campo de un archivo con su nombre, que es exactamente la forma de los secretos de
  Docker (`/run/secrets/<nombre>`) y de los volúmenes de secretos de Kubernetes. El nombre del archivo **lleva
  el `env_prefix`** (`aurea_cartera_db_password`): sin él, Pydantic no lo encuentra y falla con *Field
  required*, un error que no dice nada de archivos y que este ejemplo cometió en su primera corrida.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op051-se05-secretos.md se05 'config.py=@config.py' --pip pydantic-settings==2.15.0 pydantic==2.13.5 --cmd "python config.py" 2>&1 | tail -6

# --- se06 · op052-se06-tls-y-certificados.md · 2026-10-05T17:24:28Z
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op052-se06-tls-y-certificados.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""           .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
           .sign(ca_key, hashes.SHA256()))""","""           .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
           .add_extension(x509.KeyUsage(digital_signature=False, content_commitment=False,
                                        key_encipherment=False, data_encipherment=False,
                                        key_agreement=False, key_cert_sign=True, crl_sign=True,
                                        encipher_only=False, decipher_only=False), critical=True)
           .add_extension(x509.SubjectKeyIdentifier.from_public_key(ca_key.public_key()), critical=False)
           .sign(ca_key, hashes.SHA256()))""")
rep("""            .add_extension(x509.SubjectAlternativeName([x509.DNSName("localhost")]), critical=False)
            .sign(ca_key, hashes.SHA256()))""","""            .add_extension(x509.SubjectAlternativeName([x509.DNSName("localhost")]), critical=False)
            .add_extension(x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key()),
                           critical=False)
            .sign(ca_key, hashes.SHA256()))""")
rep("""- **El certificado del servidor dura 90 días**""","""- **`KeyUsage`, `SubjectKeyIdentifier` y `AuthorityKeyIdentifier`** no son adorno: desde Python 3.13,
  `create_default_context()` activa `VERIFY_X509_STRICT`, y un certificado sin el identificador de la clave
  de su emisor se rechaza con `Missing Authority Key Identifier`. La primera versión de este ejemplo no los
  tenía y falló exactamente así.
- **El certificado del servidor dura 90 días**""")
rep("""**`verify=False` "solo en desarrollo".**""","""**La CA vieja que deja de servir al actualizar Python.** Una CA interna hecha hace años con un script de
OpenSSL mínimo funcionaba con Python 3.12 y falla con 3.13 o posterior por `VERIFY_X509_STRICT` (§3). La
tentación es quitar el modo estricto (`ctx.verify_flags &= ~ssl.VERIFY_X509_STRICT`); la corrección es volver a
emitir los certificados con las extensiones que exige el RFC 5280. Lo primero es aceptable como puente de días,
con fecha de retiro escrita.

**`verify=False` "solo en desarrollo".**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op052-se06-tls-y-certificados.md se06 'tls.py=@tls.py' --pip httpx==0.28.1 cryptography==50.0.2 --cmd "python tls.py" 2>&1 | tail -5

# --- se07 · op053-se07-defensa-de-la-aplicacion.md · 2026-10-05T17:26:48Z
python3 humo.py op053-se07-defensa-de-la-aplicacion.md se07 'puertas.py=@puertas.py' --pip PyYAML==6.0.3 Jinja2==3.1.6 --cmd 'python puertas.py' 2>&1 | tail -6 | cat -e

# --- se08 · op054-se08-veredicto.md · 2026-10-05T17:28:04Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op054-se08-veredicto.md se08 'auditoria.py="""Las siete' --cmd 'python auditoria.py' 2>&1 | tail -10; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op054-se08-veredicto.md | tail -3

# --- seccion.md · < · 2026-10-05T16:05:02Z
Z=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; cat > $Z/humo.py <<'EOF'
"""Prueba de humo de una sección de la carta, en contenedor.

Uso: python3 humo.py <seccion.md> <dir> <archivo=inicio-del-bloque>... [--pip paq==v ...] [--cmd "python x.py"]
- Cada <archivo=inicio> extrae el primer bloque de código cuyo contenido empieza con <inicio>
  (o, si <inicio> es '@archivo', el bloque que sigue a la línea "`archivo`:").
- Corre <cmd> en python:3.14.7 con --rm y la etiqueta del curso, montando salidas/<dir>.
"""
import pathlib, re, subprocess, sys

Z = pathlib.Path(__file__).parent
CARTA = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs")
args = sys.argv[1:]
md, d = CARTA / args[0], Z / "salidas" / args[1]
d.mkdir(parents=True, exist_ok=True)
pips, cmd, specs, mode = [], None, [], "spec"
for a in args[2:]:
    if a == "--pip": mode = "pip"; continue
    if a == "--cmd": mode = "cmd"; continue
    if mode == "pip": pips.append(a)
    elif mode == "cmd": cmd = a
    else: specs.append(a)
text = md.read_text(encoding="utf-8")
blocks = re.findall(r"(?:^|\n)(.*)\n\n?```[a-z]*\n(.*?)\n```", text, re.S)
for spec in specs:
    name, start = spec.split("=", 1)
    found = None
    for before, body in blocks:
        if start.startswith("@") and before.strip().rstrip(":").strip("`").endswith(start[1:]):
            found = body; break
        if not start.startswith("@") and body.startswith(start):
            found = body; break
    if found is None:
        sys.exit(f"no encontré el bloque para {spec}")
    (d / name).parent.mkdir(parents=True, exist_ok=True)
    (d / name).write_text(found + "\n", encoding="utf-8")
inst = f"pip install -q --root-user-action=ignore {' '.join(pips)} >/dev/null 2>&1; " if pips else ""
r = subprocess.run(["docker", "run", "--rm", "--label", "curso=python-for-java-devs", "-v", f"{d}:/w",
                    "-w", "/w", "-e", "PYTHONPATH=/w", "-e", "COLUMNS=200", "python:3.14.7", "sh", "-c", inst + (cmd or "true")],
                   capture_output=True, text=True)
print(r.stdout[-6000:], r.stderr[-4000:], sep="\n")
EOF
cat > $Z/probado.py <<'EOF'
"""Marca una sección como probada: encabezado y rótulos. Uso: python3 probado.py <seccion.md> [parcial: texto]"""
import pathlib, sys
CARTA = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs")
p = CARTA / sys.argv[1]
t = p.read_text(encoding="utf-8")
OLD = "> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida."
NEW = "> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida."
assert OLD in t, "el encabezado no es el estándar"
t = t.replace(OLD, NEW).replace("Salida esperada, sin correr", "Salida (Python 3.14.7, 05/10/2026)")
p.write_text(t, encoding="utf-8")
print("probado:", p.name)
EOF
cd $Z; python3 probado.py op008-au01-http-contra-sistemas-ajenos.md; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op008-*.md

# --- so01 · op096-so01-describir-en-vez-de-programar.md · 2026-10-05T19:14:53Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/^random.seed(4)$/random.seed(10)/' op096-so01-describir-en-vez-de-programar.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && rm salidas/so01/semillas.py && python3 humo.py op096-so01-describir-en-vez-de-programar.md so01 'reparto_sabado.py=@reparto_sabado.py' --pip PuLP==4.0.0 highspy==1.15.1 --cmd 'python reparto_sabado.py' 2>/dev/null | grep -v "^$"

# --- so02 · op097-so02-programacion-lineal.md · 2026-10-05T19:13:22Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op097-so02-programacion-lineal.md");t=p.read_text()
def rep(a,b,n=1):
    global t
    assert t.count(a)==n,(a,t.count(a))
    t=t.replace(a,b)
rep("""Suba tiene dos unidades odontológicas (las sillas) y un rehabilitador que va dos tardes por semana. Cada semana, la agenda
mezcla controles de ortodoncia, limpiezas, blanqueamientos y carillas, que ocupan la silla tiempos distintos y dejan márgenes
muy distintos. Édgar Rojas quiere saber qué mezcla le conviene, y la pregunta que de verdad le importa viene después: **¿cuánto
ganaría con una silla más, o con una tarde más del rehabilitador?**""","""Chapinero, sede propia, tiene dos unidades odontológicas (las sillas) y un rehabilitador del Centro que va tres tardes por
semana. Cada semana, la agenda mezcla controles de ortodoncia, limpiezas, blanqueamientos y carillas, que ocupan la silla tiempos
distintos y dejan márgenes muy distintos. Julián quiere saber qué mezcla conviene, y la pregunta que de verdad le importa viene
después: **¿cuánto se ganaría con una silla más, o con una tarde más del rehabilitador?**""")
rep('"""La mezcla semanal de Suba: lineal (con precios sombra) y entera (la que se agenda)."""','"""La mezcla semanal de Chapinero: lineal (con precios sombra) y entera (la que se agenda)."""')
rep("`mezcla_suba.py`:","`mezcla_chapinero.py`:")
rep("python3 mezcla_suba.py","python3 mezcla_chapinero.py")
rep('REHAB_MINUTES = 2 * 4 * 60              # dos tardes de cuatro horas','REHAB_MINUTES = 3 * 210                 # tres tardes de tres horas y media')
rep('    prob = pulp.LpProblem("mezcla_suba", pulp.LpMaximize)','    prob = pulp.LpProblem("mezcla_chapinero", pulp.LpMaximize)')
rep('''for name, c in prob.constraints.items():
    if c.pi:
        print(f"  precio sombra de {name}: ${c.pi:,.0f} por unidad")''','''for c in prob.constraints():                     # PuLP 4: un método que devuelve la lista
    if c.pi:
        print(f"  precio sombra de {c.name}: ${c.pi:,.0f} por unidad")''')
rep("""- **Las restricciones llevan nombre**""","""- **`prob.constraints()` es un método en PuLP 4** (en la 3 era un diccionario, `prob.constraints.items()`): otro cambio de la reescritura
  que encontró la primera corrida.
- **Las restricciones llevan nombre**""")
rep("10. Prepara para Édgar la respuesta a \"¿me conviene una tercera silla?\".","10. Prepara para Julián la respuesta a \"¿nos conviene una tercera silla en Chapinero?\".")
rep("""**La señal de que quedó bien:** *"Édgar preguntó si le convenía otra silla, y la respuesta llegó con el número y con el rango en que ese
número vale."*""","""**La señal de que quedó bien:** *"Julián preguntó si convenía otra silla en Chapinero, y la respuesta llegó con el número y con el rango en
que ese número vale."*""")
rep('git tag -a op-so-fase-02 -m "op so02 cerrada: la mezcla de Suba, lineal con precios sombra y entera"','git tag -a op-so-fase-02 -m "op so02 cerrada: la mezcla de Chapinero, lineal con precios sombra y entera"')
p.write_text(t)
EOF
grep -n "Suba\|Édgar" op097-so02-programacion-lineal.md; cd ../../zz-code/python-for-java-devs-20261005-f516 && rm -f salidas/so02/sonda.py && python3 humo.py op097-so02-programacion-lineal.md so02 'mezcla_chapinero.py=@mezcla_chapinero.py' --pip PuLP==4.0.0 highspy==1.15.1 --cmd 'python mezcla_chapinero.py' 2>&1 | tail -8

# --- so03 · op098-so03-or-tools.md · 2026-10-05T19:16:51Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op098-so03-or-tools.md");t=p.read_text()
a='''    row = [next(p for p in STAFF if solver.value(work[p, s, d, t]))[:3] for d in DAYS for t in SHIFTS]
    print(f"  {s:<10}", " ".join(row))'''
assert t.count(a)==1
t=t.replace(a,'''    row = [next(p for p in STAFF if solver.value(work[p, s, d, t])) for d in DAYS for t in SHIFTS]
    print(f"  {s:<10}", " ".join("Yu" if p == "Yuli" else p[-2:] for p in row))''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op098-so03-or-tools.md so03 'turnos.py=@turnos.py' --pip ortools==9.15.6755 --cmd 'python turnos.py' 2>/dev/null | grep -v "^$"

# --- so04 · op099-so04-rutas-y-grafos.md · 2026-10-05T19:18:29Z
python3 humo.py op099-so04-rutas-y-grafos.md so04 'mensajero.py=@mensajero.py' --pip networkx==3.7 --cmd 'python mensajero.py' 2>/dev/null | head -1

# --- so05 · op100-so05-simulacion-con-simpy.md · 2026-10-05T19:20:04Z
python3 humo.py op100-so05-simulacion-con-simpy.md so05 'sala_de_espera.py=@sala_de_espera.py' --pip simpy==4.1.2 --cmd 'python sala_de_espera.py' 2>/dev/null | grep recepción

# --- so06 · op101-so06-cuando-no-hay-modelo.md · 2026-10-05T19:21:21Z
sed -i '' 's/con la historia de citas (`ds08` del camino base) dice/con la historia de citas (`ds08`) dice/' op101-so06-cuando-no-hay-modelo.md && grep -c "(\`ds08\`) dice" op101-so06-cuando-no-hay-modelo.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op101-so06-cuando-no-hay-modelo.md so06 'recordatorios.py=@recordatorios.py' --pip scipy==1.18.1 optuna==5.0.0 numpy==2.5.3 --cmd 'python recordatorios.py' 2>&1 | tail -6

# --- so07 · op102-so07-veredicto.md · 2026-10-05T19:22:41Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op102-so07-veredicto.md so07 'paga.py="""¿Paga el modelo?' --cmd 'python paga.py' 2>/dev/null | grep -v "^$"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op102-so07-veredicto.md | tail -2

# --- sy01 · op115-sy01-subprocess-a-fondo.md · 2026-10-05T19:45:19Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op115-sy01-subprocess-a-fondo.md sy01 'trampas_subprocess.py="""Las tres trampas de subprocess' --cmd 'python trampas_subprocess.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op115-sy01-subprocess-a-fondo.md | tail -2

# --- sy02 · op116-sy02-las-envolturas.md · 2026-10-05T19:46:29Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op116-sy02-las-envolturas.md sy02 'envolturas.py=@envolturas.py' 'tasks.py=from invoke import task' --pip plumbum==2.0.2 sh==2.4.0 invoke==3.0.3 --cmd 'rm -f cierre.csv.gz; python envolturas.py; echo ---; invoke --list; invoke respaldo' 2>&1 | tail -18; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op116-sy02-las-envolturas.md | tail -2

# --- sy03 · op117-sy03-inspeccion-del-sistema.md · 2026-10-05T19:47:39Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op117-sy03-inspeccion-del-sistema.md sy03 'agente.py=@agente.py' --pip psutil==7.2.2 --cmd 'python agente.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op117-sy03-inspeccion-del-sistema.md | tail -2

# --- sy04 · op118-sy04-el-sistema-de-archivos.md · 2026-10-05T19:49:55Z
python3 humo.py op118-sy04-el-sistema-de-archivos.md sy04 'atomico.py=@atomico.py' --pip filelock==4.0.12 --cmd 'timeout 250 python atomico.py' 2>/dev/null | grep -v "^$"

# --- sy05 · op119-sy05-reaccionar-a-cambios.md · 2026-10-05T19:51:07Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && grep -m1 "| \`watchdog\`" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/inventario-verificado.md; python3 humo.py op119-sy05-reaccionar-a-cambios.md sy05 'entrada.py=@entrada.py' --pip watchdog==6.0.0 --cmd 'rm -rf entrada; python entrada.py' 2>&1 | tail -5; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op119-sy05-reaccionar-a-cambios.md | tail -2

# --- sy06 · op120-sy06-convivir-con-el-sistema.md · 2026-10-05T19:52:41Z
echo "$(curl -s -o /dev/null -w '%{http_code}' -L -m 20 https://man7.org/linux/man-pages/man5/systemd.service.5.html)" && sed -i '' 's#- `systemd.service`: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#- `systemd.service(5)`: https://man7.org/linux/man-pages/man5/systemd.service.5.html#' op120-sy06-convivir-con-el-sistema.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op120-sy06-convivir-con-el-sistema.md sy06 'vigilante.py="""Un servicio que convive' 'probar_vigilante.py="""Hacer de systemd' 'supervisord.conf=[supervisord]' --pip supervisor==4.3.0 --cmd 'python probar_vigilante.py; echo ---; timeout 6 supervisord -c supervisord.conf >/dev/null 2>&1; grep -c "error irrecuperable" /tmp/vigilante.log; grep -E "spawned|exited|gave up" /tmp/supervisord.log | sed "s/^[0-9-]* [0-9:,]* //" | head -8' 2>&1 | tail -16

# --- sy07 · op121-sy07-sincronizacion-y-respaldo.md · 2026-10-05T19:55:49Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op121-sy07-sincronizacion-y-respaldo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''for i in (3, 7):                                             # dos exportes cambian (mismo tamaño, mismo segundo)
    (SRC / f"exporte-{i:02d}.csv").write_bytes(random.randbytes(100_000))''','''for i in (3, 7):                                             # dos exportes cambian, con el mismo tamaño y la misma
    path = SRC / f"exporte-{i:02d}.csv"                      # fecha de modificación: como un cambio en el mismo segundo,
    before = path.stat()                                     # o una herramienta que conserva la fecha al reescribir
    path.write_bytes(random.randbytes(100_000))
    os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op121-sy07-sincronizacion-y-respaldo.md sy07 'respaldo.py=@respaldo.py' --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq rsync >/dev/null 2>&1; mkdir -p /tmp/t && cp respaldo.py /tmp/t/ && cd /tmp/t && python respaldo.py' 2>/dev/null | grep -v "^$"

# --- sy08 · op122-sy08-veredicto.md · 2026-10-05T19:57:08Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op122-sy08-veredicto.md sy08 'ingenuo.sh=for f in $(ls entrada)' 'cuidadoso.sh=set -euo pipefail' 'contar.py=@contar.py' --cmd 'python contar.py' 2>&1 | tail -7; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op122-sy08-veredicto.md | tail -2

# --- tx01 · op055-tx01-el-eje.md · 2026-10-05T17:31:54Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op055-tx01-el-eje.md tx01 'eje.py=@eje.py' --pip Jinja2==3.1.6 htpy==26.5.1 --cmd 'python eje.py' 2>&1 | tail -7; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op055-tx01-el-eje.md | tail -3

# --- tx02 · op056-tx02-jinja2-a-fondo.md · 2026-10-05T17:32:59Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op056-tx02-jinja2-a-fondo.md tx02 'reporte.py=@reporte.py' --pip Jinja2==3.1.6 --cmd 'python reporte.py' 2>&1 | tail -18 | cat -e; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op056-tx02-jinja2-a-fondo.md | tail -3

# --- tx03 · op057-tx03-las-otras-plantillas.md · 2026-10-05T17:34:09Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op057-tx03-las-otras-plantillas.md tx03 'seis.py=@seis.py' --pip Jinja2==3.1.6 Django==6.1.1 Mako==1.4.3 Chameleon==4.6.0 chevron==0.14.0 --cmd 'python seis.py' 2>&1 | tail -10; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op057-tx03-las-otras-plantillas.md | tail -3

# --- tx04 · op058-tx04-codigo-como-dato.md · 2026-10-05T17:35:28Z
python3 humo.py op058-tx04-codigo-como-dato.md tx04 'plata.py=@plata.py' --pip Pygments==2.21.0 tree-sitter==0.26.0 tree-sitter-python==0.25.0 --cmd 'python plata.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op058-tx04-codigo-como-dato.md | tail -3

# --- tx05 · op059-tx05-markdown.md · 2026-10-05T17:36:57Z
python3 humo.py op059-tx05-markdown.md tx05 'procedimiento.py=@procedimiento.py' --pip markdown-it-py==4.2.0 mistune==3.3.4 Markdown==3.11 --cmd 'python procedimiento.py' 2>/dev/null | grep "lista anidada" > /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/scratchpad/tx05.txt; cat /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/scratchpad/tx05.txt

# --- tx06 · op060-tx06-documentacion.md · 2026-10-05T17:38:15Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op060-tx06-documentacion.md tx06 'cartera.py=@cartera.py' --cmd 'python -m doctest -v cartera.py | tail -9' 2>&1 | tail -11

# --- tx07 · op061-tx07-generacion-de-codigo.md · 2026-10-05T17:39:21Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op061-tx07-generacion-de-codigo.md tx07 'generar.py="""Generar Python' --cmd 'python generar.py' 2>&1 | grep -- "--- cadenas"

# --- tx08 · op062-tx08-texto-dificil.md · 2026-10-05T17:40:36Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op062-tx08-texto-dificil.md tx08 'texto.py=@texto.py' --pip regex==2026.9.29 Babel==2.18.0 --cmd 'python texto.py' 2>&1 | tail -13; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op062-tx08-texto-dificil.md | tail -3

# --- tx09 · op063-tx09-veredicto.md · 2026-10-05T17:41:58Z
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op063-tx09-veredicto.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('ARITHMETIC = {"add", "sub", "mul", "div", "floordiv", "mod", "pow"}','ARITHMETIC = {"+", "-", "*", "/", "//", "%", "**"}')
rep("""    for _, kind, value in env.lex(source):
        if kind == "data":""","""    for _, kind, value in env.lex(source):          # tokens crudos: (línea, tipo, valor)
        if kind == "whitespace":
            continue
        if kind == "data":""")
rep("""        elif kind in ARITHMETIC:""","""        elif kind == "operator" and value in ARITHMETIC:""")
rep("""- **`env.lex`** devuelve los mismos *tokens* que Jinja2 usa para compilar: la medición no adivina con expresiones
  regulares (`tx04`).""","""- **`env.lex`** devuelve los mismos *tokens* que Jinja2 usa para compilar: la medición no adivina con expresiones
  regulares (`tx04`). Son los *tokens* **crudos**: los espacios dentro de `{% %}` llegan como `whitespace` y los
  operadores como `operator` con su símbolo. La primera versión de este ejemplo esperaba los nombres ya procesados
  (`add`, `sub`) y declaró "plantilla" a las dos.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op063-tx09-veredicto.md tx09 'densidad.py=@densidad.py' --pip Jinja2==3.1.6 --cmd 'python densidad.py' 2>&1 | tail -4

# --- ui01 · op064-ui01-el-modelo-y-su-costo.md · 2026-10-05T17:44:24Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op064-ui01-el-modelo-y-su-costo.md ui01 'entregas.py="""Los dos escalones' --cmd 'python entregas.py' 2>/dev/null | grep bytes

# --- ui02 · op065-ui02-gradio.md · 2026-10-05T17:47:59Z
python3 humo.py op065-ui02-gradio.md ui02 'mora_app.py=@mora_app.py' 'cliente.py=@cliente.py' --pip gradio==6.29.1 --cmd 'GRADIO_ANALYTICS_ENABLED=False python mora_app.py > app.log 2>&1 & for i in $(seq 60); do python -c "import urllib.request;urllib.request.urlopen(\"http://127.0.0.1:7860/\")" 2>/dev/null && break; sleep 1; done; python cliente.py > out.txt 2>&1; cat out.txt' 2>/dev/null | grep -v "^$" | tail -4

# --- ui03 · op066-ui03-streamlit.md · 2026-10-05T17:49:32Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op066-ui03-streamlit.md ui03 'contador.py=calls = {' 'cartera_app.py=@cartera_app.py' 'prueba_app.py="""Simula a Patricia' --pip streamlit==1.65.0 --cmd 'python prueba_app.py' 2>&1 | tail -6

# --- ui04 · op067-ui04-dash.md · 2026-10-05T17:50:54Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op067-ui04-dash.md ui04 'tablero.py=@tablero.py' 'prueba_tablero.py="""El callback es' --pip dash==4.4.1 --cmd 'python prueba_tablero.py' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op067-ui04-dash.md | tail -3

# --- ui05 · op068-ui05-nicegui-y-compania.md · 2026-10-05T17:54:17Z
python3 humo.py op068-ui05-nicegui-y-compania.md ui05 'medir.py="""Lo que pesa' --cmd 'python medir.py' > salidas/ui05/medir.out 2>&1; tail -12 salidas/ui05/medir.out

# --- ui06 · op069-ui06-marimo.md · 2026-10-05T17:55:35Z
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op069-ui06-marimo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""Ahora el notebook de marimo, `regalias.py`. Se edita con `marimo edit regalias.py`, que guarda exactamente esto:
""","""Ahora el notebook de marimo. Se edita con `marimo edit regalias.py`, que guarda exactamente esto:

`regalias.py`:
""")
rep("""Y la regla que lo garantiza, en `malo.py`: dos celdas que definen la misma variable.
""","""Y la regla que lo garantiza: dos celdas que definen la misma variable.

`malo.py`:
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op069-ui06-marimo.md ui06 'estado_oculto.py="""El estado oculto' 'regalias.py=@regalias.py' 'malo.py=@malo.py' --pip marimo==0.25.1 --cmd 'python estado_oculto.py; echo ---; python regalias.py; echo ---; python malo.py' 2>&1 | tail -25

# --- ui07 · op070-ui07-presentaciones.md · 2026-10-05T17:56:50Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op070-ui07-presentaciones.md ui07 'comite.py=@comite.py' --pip python-pptx==1.0.2 --cmd 'python comite.py' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op070-ui07-presentaciones.md | tail -3

# --- ui08 · op071-ui08-reportes.md · 2026-10-05T17:59:12Z
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op071-ui08-reportes.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("from jinja2 import Template\n","from jinja2 import Environment\n")
rep('PAGE = Template("""<!doctype html>','env = Environment(autoescape=True)\nenv.filters["pesos"] = lambda v: "$" + f"{v:,}".replace(",", ".")\nPAGE = env.from_string("""<!doctype html>')
rep('PAGE.environment.filters["pesos"] = lambda v: "$" + f"{v:,}".replace(",", ".")\n',"")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op071-ui08-reportes.md ui08 'reporte_mensual.py=@reporte_mensual.py' --pip WeasyPrint==70.0 XlsxWriter==3.2.9 Jinja2==3.1.6 openpyxl==3.1.5 --cmd 'python reporte_mensual.py 2>&1 | tail -2; echo ---; apt-get update -qq >/dev/null && apt-get install -y -qq libpango-1.0-0 libpangoft2-1.0-0 >/dev/null 2>&1; python reporte_mensual.py' 2>&1 | tail -8

# --- ui09 · op072-ui09-escritorio.md · 2026-10-05T18:01:09Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op072-ui09-escritorio.md ui09 'mora_tk.py=@mora_tk.py' --cmd 'apt-get update -qq >/dev/null && apt-get install -y -qq xvfb xauth >/dev/null 2>&1; xvfb-run -a python mora_tk.py' 2>&1 | tail -5; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op072-ui09-escritorio.md | tail -3

# --- ui10 · op073-ui10-cli-mas-alla-de-argparse.md · 2026-10-05T18:02:30Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op073-ui10-cli-mas-alla-de-argparse.md ui10 'cli_argparse.py=@cli_argparse.py' 'cli_typer.py=@cli_typer.py' 'cli_cyclopts.py=@cli_cyclopts.py' 'comparar.py="""Arranque, salida' --pip typer==0.27.2 cyclopts==5.1.1 --cmd 'python comparar.py; echo ---; python cli_cyclopts.py 1.250.000 45; echo "exit=$?"' 2>&1 | tail -16; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op073-ui10-cli-mas-alla-de-argparse.md | tail -3

# --- ui11 · op074-ui11-rich-e-interaccion.md · 2026-10-05T18:04:08Z
S=/private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/scratchpad; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op074-ui11-rich-e-interaccion.md ui11 'reproceso.py=@reproceso.py' 'comparar_salidas.py="""La misma herramienta' --pip rich==15.0.0 --cmd 'python comparar_salidas.py' 2>/dev/null | sed -n '/^cron (sin terminal)/,/^persona/p' > $S/ui11.txt; cat -e $S/ui11.txt | head -3; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 - "$S/ui11.txt" <<'EOF'
import pathlib,re,sys
real=pathlib.Path(sys.argv[1]).read_text().rstrip("\n")
p=pathlib.Path("op074-ui11-rich-e-interaccion.md");t=p.read_text()
old=re.search(r"cron \(sin terminal\)      … bytes.*?persona \(FORCE_COLOR\)[^\n]*",t,re.S).group(0)
t=t.replace(old,real)
a="Sin terminal, cero códigos de escape:"
assert t.count(a)==1
t=t.replace(a,"Sin terminal, 477 bytes y cero códigos de escape; para una persona, 1 438 bytes y 101 escapes:")
p.write_text(t)
EOF
sed -n '/^```text$/,/^```$/p' op074-ui11-rich-e-interaccion.md | head -18

# --- ui12 · op075-ui12-textual.md · 2026-10-05T18:05:10Z
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op075-ui12-textual.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('        table.add_columns("Sede", "Estado", "Segundos")\n','        for label in ("Sede", "Estado", "Segundos"):\n            table.add_column(label, key=label.lower())\n')
rep('table.update_cell(row_key, "Estado", "reprocesada")','table.update_cell(row_key, "estado", "reprocesada")')
rep("Para que `update_cell` encuentre la columna por nombre, las columnas se agregan con clave. La prueba,","Las columnas se agregan con clave (`key=`) para que `update_cell` encuentre la del estado por nombre. La prueba,")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op075-ui12-textual.md ui12 'cierre_tui.py=@cierre_tui.py' 'prueba_tui.py="""Opera la TUI' --pip textual==8.2.8 --cmd 'python prueba_tui.py' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op075-ui12-textual.md | tail -3

# --- ui13 · op076-ui13-veredicto.md · 2026-10-05T18:06:06Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op076-ui13-veredicto.md ui13 'escalon.py="""¿Qué escalón?' --cmd 'python escalon.py' 2>&1 | tail -9; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op076-ui13-veredicto.md | tail -2

# --- vz01 · op111-vz01-el-modelo-y-matplotlib.md · 2026-10-05T19:38:27Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op111-vz01-el-modelo-y-matplotlib.md vz01 'recaudo.py=@recaudo.py' --pip matplotlib==3.11.2 --cmd 'python recaudo.py; ls recaudo-*.png | wc -l' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op111-vz01-el-modelo-y-matplotlib.md | tail -3

# --- vz02 · op112-vz02-la-gramatica.md · 2026-10-05T19:40:46Z
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op112-vz02-la-gramatica.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('print("Great Tables: HTML de", len(html), "bytes; primera cifra:", html.split("sem 1")[1].split("$")[1][:12].strip())',
    'print("Great Tables: HTML de", len(html), "bytes; primera cifra:", re.search(r"\\$\\s?[\\d.]+", html).group())')
rep("import json\nimport random\n","import json\nimport random\nimport re\n")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op112-vz02-la-gramatica.md vz02 'gramatica.py=@gramatica.py' --pip altair==6.3.0 vl-convert-python==1.9.0.post1 plotnine==0.15.8 great-tables==1.0.0 pandas==3.0.6 --cmd 'python gramatica.py' 2>/dev/null | grep -v "^$"

# --- vz03 · op113-vz03-graficos-que-no-son-datos.md · 2026-10-05T19:42:30Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op113-vz03-graficos-que-no-son-datos.md vz03 'diagramas.py=@diagramas.py' --pip graphviz==0.21 drawsvg==2.4.2 --cmd 'python diagramas.py 2>&1 | tail -3; echo ---; apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq graphviz >/dev/null 2>&1; python diagramas.py; ls -la *.svg | wc -l' 2>&1 | tail -14; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op113-vz03-graficos-que-no-son-datos.md | tail -3

# --- vz04 · op114-vz04-el-grafico-que-miente.md · 2026-10-05T19:43:50Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op114-vz04-el-grafico-que-miente.md vz04 'mentiras.py=@mentiras.py' --pip numpy==2.5.3 matplotlib==3.11.2 --cmd 'python mentiras.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op114-vz04-el-grafico-que-miente.md | tail -3

# --- wf01 · op022-wf01-el-eje.md · 2026-10-05T16:32:56Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op022-wf01-el-eje.md wf01 'noche.py="""La noche de Áurea' --cmd "python noche.py; python noche.py | tail -7 | head -6"

# --- wf02 · op023-wf02-colas-de-tareas.md · 2026-10-05T16:34:27Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op023-wf02-colas-de-tareas.md wf02 'tareas.py="""La tarea: generar' 'encolar_rq.py="""Encola las liquidaciones' 'cola_huey.py="""La misma tarea en Huey' >/dev/null; S=$PWD/salidas/wf02; docker network create --label curso=python-for-java-devs pfjd-wf02 >/dev/null; docker run -d --rm --label curso=python-for-java-devs --network pfjd-wf02 --name pfjd-valkey valkey/valkey:9.0.6-alpine >/dev/null 2>&1; sleep 2; docker run --rm --label curso=python-for-java-devs --network pfjd-wf02 -v $S:/w -w /w -e PYTHONPATH=/w python:3.14.7 sh -c "pip install -q --root-user-action=ignore rq==2.12.0 huey==3.4.0 >/dev/null 2>&1; rm -rf liquidaciones intentos.log cola.db; echo '--- RQ'; (rq worker liquidaciones --url redis://pfjd-valkey:6379 --with-scheduler > worker.log 2>&1 &); REDIS_URL=redis://pfjd-valkey:6379 timeout 60 python encolar_rq.py; echo '--- Huey'; (huey_consumer cola_huey.huey --workers 2 > huey.log 2>&1 &); sleep 1; timeout 60 python -c \"
from cola_huey import build_settlement_pdf
results = [build_settlement_pdf(s, '2026T4') for s in ('Suba', 'Zipaquirá')]
print([r.get(blocking=True, timeout=30) for r in results])\"; echo '--- intentos'; sort intentos.log | uniq -c"; docker rm -f -v pfjd-valkey >/dev/null 2>&1; docker network rm pfjd-wf02 >/dev/null; echo limpio

# --- wf03 · op024-wf03-programacion-en-proceso.md · 2026-10-05T16:36:47Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op024-wf03-programacion-en-proceso.md wf03 'agenda_cache.py="""Dos réplicas' --pip apscheduler==3.11.3 schedule==1.2.2 --cmd "python agenda_cache.py; echo ---; python agenda_cache.py; echo ---; python -c \"
import schedule
j = schedule.every().day.at('08:00', 'America/Bogota').do(print)
print(j.next_run)\""

# --- wf04 · op025-wf04-airflow.md · 2026-10-05T16:38:29Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; mkdir -p salidas/wf04/dags; python3 humo.py op025-wf04-airflow.md wf04 'dags/noche_aurea.py="""La noche de Áurea como DAG' >/dev/null; ls salidas/wf04/dags; docker run --rm --label curso=python-for-java-devs -v $PWD/salidas/wf04:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore 'apache-airflow==3.3.2' > pip.log 2>&1; echo pip=\$?; tail -3 pip.log; export AIRFLOW_HOME=/w/airflow-home AIRFLOW__CORE__DAGS_FOLDER=/w/dags AIRFLOW__CORE__LOAD_EXAMPLES=False; airflow version; airflow db migrate > migrate.log 2>&1; echo migrate=\$?; airflow dags test noche_aurea 2026-10-05 > test.log 2>&1; echo test=\$?; grep -E 'success|radicadas|DagRun|ERROR|Error' test.log | head -20" > salidas/wf04/humo.out 2>&1; cat salidas/wf04/humo.out | tail -30

# --- wf05 · op026-wf05-prefect-y-dagster.md · 2026-10-05T16:39:58Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op026-wf05-prefect-y-dagster.md wf05 'noche_prefect.py="""La noche de Áurea en Prefect' 'noche_dagster.py="""La noche de Áurea en Dagster' >/dev/null; S=$PWD/salidas/wf05; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore prefect==3.8.7 > pip-p.log 2>&1; echo pip=\$?; timeout 240 python noche_prefect.py 2>&1 | grep -E 'Retry|radicadas|Finished|Error|error' | cut -c1-230 | head -8" ; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore dagster==1.13.25 > pip-d.log 2>&1; echo pip=\$?; timeout 240 python noche_dagster.py 2>/dev/null | tail -3"

# --- wf06 · op027-wf06-temporal.md · 2026-10-05T16:42:07Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op027-wf06-temporal.md wf06 'aprobacion.py="""La aprobación trimestral' 'prueba_aprobacion.py="""Dos trimestres' --pip temporalio==1.34.0 --cmd "timeout 300 python prueba_aprobacion.py"

# --- wf07 · op028-wf07-lo-transversal.md · 2026-10-05T16:43:55Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op028-wf07-lo-transversal.md'; t=open(f,encoding='utf-8').read()
a='''            print(f"{owner}: se cae a la mitad")
            os._exit(1)                         # sin limpiar nada: como un kill -9'''
b='''            print(f"{owner}: se cae a la mitad", flush=True)
            os._exit(1)                         # sin limpiar nada: como un kill -9'''
assert a in t; t=t.replace(a,b)
a='''        print(f"{owner}: {franchise} {'facturada' if written else 'ya estaba'}")'''
b='''        # flush: os._exit no vacía el búfer, y sin esto lo que imprimió la copia que se cae se pierde.
        print(f"{owner}: {franchise} {'facturada' if written else 'ya estaba'}", flush=True)'''
assert a in t; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op028-wf07-lo-transversal.md wf07 'ejecuciones.py="""Ejecuciones con clave' --cmd "python ejecuciones.py" | sed -n 9,14p

# --- wf08 · op029-wf08-veredicto.md · 2026-10-05T16:45:09Z
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op029-wf08-veredicto.md wf08 'memoria_en_reposo.py="""Memoria en reposo' --cmd "(sleep 30 &); python -c \"import memoria_en_reposo as m; print(round(m.process_rss_mb('sleep 30'),1), 'MB'); print(m.container_mb.__doc__)\"" | head -3; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op029-*.md; wc -l op022* op023* op024* op025* op026* op027* op028* op029* | tail -1; docker ps -a --filter label=curso=python-for-java-devs -q | wc -l

