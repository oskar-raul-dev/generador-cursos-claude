# 📮 co05 — Transferencia de archivos

> Python para desarrolladores Java senior · **Carta** · Track `co` — Comunicaciones y
> transferencia · sección 5 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor, contra un servidor SFTP de OpenSSH: la descarga, la segunda corrida, la retoma desde
> un `.part` cortado y el archivo reemplazado. El fragmento de FTPS, el 07/10/2026, contra un servidor
> FTPS de prueba con una CA propia.

---

## 🎯 1. Qué problema resuelve

Dos aseguradoras no mandan las relaciones de pago por correo: las dejan en un servidor de
transferencia de archivos, una en FTP con TLS y otra en SFTP. Alguien en Áurea entra con un cliente
gráfico, baja lo nuevo y lo deja en la carpeta compartida. Un lunes bajó un archivo a medio subir —la
aseguradora todavía lo estaba escribiendo— y el cierre de ese mes se hizo con la mitad de los pagos.

Transferir archivos es un problema viejo con soluciones viejas que funcionan, y la sección enseña las
dos que importan desde Python:

- **SFTP**, que es una subsistema de SSH: un canal cifrado, autenticación con clave, y operaciones de
  archivo (listar, leer, escribir, renombrar). Desde Python, con **Paramiko** (5.0.0), directamente.
- **FTP y FTPS** con `ftplib` de la biblioteca estándar: el protocolo de 1971, que sigue vivo en
  medio sector financiero, y su versión con TLS.

Y lo que no depende del protocolo, que es la parte difícil: **saber que un archivo terminó de
llegar**, retomar una transferencia que se cortó, y no procesar dos veces lo mismo.

---

## 🧠 2. El modelo

Una transferencia confiable tiene cuatro reglas, válidas para cualquier protocolo:

1. **Nunca leer un archivo que se está escribiendo.** El emisor sube con un nombre temporal y lo
   renombra al terminar; o publica un archivo de control (`.ok`, `.done`) después del de datos; o, si
   no hace ninguna de las dos, el receptor espera a que el tamaño deje de cambiar.
2. **Nunca dejar a medias lo que tú escribes.** Se baja a `archivo.part` y se renombra al verificar.
   Un proceso que lee la carpeta de destino nunca ve un archivo incompleto.
3. **Verificar.** Tamaño como mínimo; un resumen (SHA-256) si el emisor lo publica.
4. **Recordar lo bajado** por nombre, tamaño y fecha de modificación, para no procesarlo dos veces y
   para detectar que el emisor **reemplazó** un archivo con el mismo nombre.

| | SFTP | FTPS | FTP |
|---|---|---|---|
| Cifrado | Siempre (SSH) | TLS, si se configura bien | Ninguno: usuario y contraseña en claro |
| Puertos | Uno (22) | Control + rango de datos | Control + rango de datos |
| Renombrar atómico | `posix_rename` si el servidor lo soporta | `RNFR`/`RNTO` | `RNFR`/`RNTO` |
| En Python | Paramiko | `ftplib.FTP_TLS` | `ftplib.FTP` |

### Tu instinto de Java dice… y esta vez se equivoca

En Java el reflejo es JSch o Apache Commons Net, y con ellos una clase de utilidad que "baja la
carpeta". En Python el reflejo equivalente es buscar `pysftp`, que aparece primero en todas las
búsquedas: **lleva sin versión desde 2016** y lo que hace es envolver a Paramiko, que sí está vivo.
Paramiko directo es igual de corto y no arrastra un envoltorio muerto.

---

## 💻 3. El ejemplo que corre

```bash
uv add paramiko
```

`descargar_pagos.py`:

```python
"""Baja las relaciones de pago del SFTP de la aseguradora, solo las completas y solo una vez."""

import hashlib
import json
import stat
import time
from pathlib import Path

import paramiko

REMOTE_DIR = "/salida/aurea"
LOCAL_DIR = Path("pagos")
LEDGER = Path("pagos/.descargados.json")
SETTLE_SECONDS = 30  # si el emisor no avisa, un archivo quieto 30 s se da por terminado


def connect(host: str, port: int, user: str, key_file: str) -> paramiko.SFTPClient:
    client = paramiko.SSHClient()
    client.load_host_keys("known_hosts")
    client.set_missing_host_key_policy(paramiko.RejectPolicy())
    client.connect(host, port=port, username=user, key_filename=key_file,
                   allow_agent=False, look_for_keys=False, timeout=15)
    return client.open_sftp()


def ready_files(sftp: paramiko.SFTPClient) -> list[paramiko.SFTPAttributes]:
    entries = {e.filename: e for e in sftp.listdir_attr(REMOTE_DIR) if stat.S_ISREG(e.st_mode)}
    ready = []
    for name, entry in entries.items():
        if name.endswith((".tmp", ".part", ".ok")):
            continue
        # Regla 1: si el emisor publica .ok, manda el .ok; si no, que lleve un rato quieto.
        if f"{name}.ok" in entries or time.time() - entry.st_mtime > SETTLE_SECONDS:
            ready.append(entry)
    return ready


def download(sftp: paramiko.SFTPClient, entry: paramiko.SFTPAttributes, ledger: dict) -> Path | None:
    key = f"{entry.filename}|{entry.st_size}|{entry.st_mtime}"
    if ledger.get(entry.filename) == key:
        return None                                    # Regla 4: ya está, idéntico
    remote = f"{REMOTE_DIR}/{entry.filename}"
    part = LOCAL_DIR / f"{entry.filename}.part"
    offset = part.stat().st_size if part.exists() else 0
    with sftp.open(remote, "rb") as source, part.open("ab") as target:
        source.seek(offset)                            # retoma donde se cortó
        source.prefetch(entry.st_size)                 # el tamaño TOTAL, no lo que falta: pide por adelantado
        while chunk := source.read(1 << 20):
            target.write(chunk)
    if part.stat().st_size != entry.st_size:           # Regla 3: verificar antes de publicar
        raise OSError(f"{entry.filename}: {part.stat().st_size} de {entry.st_size} bytes")
    final = LOCAL_DIR / entry.filename
    part.replace(final)                                # Regla 2: aparece completo o no aparece
    ledger[entry.filename] = key
    return final


def run(host: str, port: int) -> None:
    LOCAL_DIR.mkdir(exist_ok=True)
    ledger = json.loads(LEDGER.read_text()) if LEDGER.exists() else {}
    with connect(host, port, "aurea", "aurea_ed25519") as sftp:
        for entry in ready_files(sftp):
            path = download(sftp, entry, ledger)
            if path:
                digest = hashlib.sha256(path.read_bytes()).hexdigest()[:12]
                print(f"bajado {path.name} ({entry.st_size} bytes, sha256 {digest}…)")
            LEDGER.write_text(json.dumps(ledger, indent=2))  # después de cada archivo, no al final
    print(f"{len(ledger)} archivos en el registro")


if __name__ == "__main__":
    import sys
    run(sys.argv[1], int(sys.argv[2]))
```

### FTPS con la biblioteca estándar

Para la aseguradora que usa FTP con TLS, `ftplib` basta, y la línea que todos olvidan es `prot_p()`:

```python
import ftplib
import ssl

with ftplib.FTP_TLS(context=ssl.create_default_context(), timeout=30) as ftp:
    ftp.connect("ftps.aseguradora.example", 21)
    ftp.login("aurea", "…")
    ftp.prot_p()          # sin esto, el canal de control va cifrado y los DATOS viajan en claro
    for name, facts in ftp.mlsd("salida/aurea"):
        if facts["type"] == "file":
            print(name, facts["size"], facts["modify"])
```

`mlsd` devuelve el listado en un formato definido (RFC 3659), con tamaño y fecha de modificación por
archivo, en vez del texto de `LIST`, que cada servidor formatea a su manera.

Salida (Python 3.14.7, 07/10/2026), contra un servidor FTPS de prueba (`pyftpdlib` con TLS obligatorio en los dos
canales) que responde al nombre `ftps.aseguradora.example` en una red de Docker, con un certificado firmado por una CA
de prueba que el cliente recibe en `SSL_CERT_FILE`; el fragmento corrió sin cambiar una línea:

```text
glosas-2026-09.zip 10240 20261007081847
pagos-20261006.csv 2048 20261007081847
pagos-20261007.csv 4096 20261007081847
```

Y la misma corrida **sin** `ftp.prot_p()`, contra ese servidor que exige TLS en el canal de datos:
`ftplib.error_perm: 550 SSL/TLS required on the data channel.` Un servidor que no lo exige habría contestado igual
que arriba, con el listado viajando en claro: por eso la línea va siempre, aunque "funcione sin ella".

### Probarlo

Un SFTP de pruebas con OpenSSH en un contenedor: el mismo `Dockerfile` de un servidor SSH, con un
usuario `aurea` y la carpeta `/salida/aurea`. Con un archivo terminado, uno publicado con `.ok` y
uno que "se está escribiendo" (modificado hace un segundo):

```bash
python3 descargar_pagos.py 127.0.0.1 2222
python3 descargar_pagos.py 127.0.0.1 2222   # la segunda vez no baja nada
```

Salida (Python 3.14.7, 05/10/2026):

```text
bajado pagos-septiembre.csv (48213 bytes, sha256 5088ecd4b1b2…)
bajado pagos-octubre-1.csv (12002 bytes, sha256 e5f48a0965af…)
2 archivos en el registro
2 archivos en el registro
```

El tercer archivo no aparece: se modificó hace menos de treinta segundos y no tiene `.ok`. La
corrida siguiente lo bajará si ya está quieto.

**Detalles con intención**

- **`prefetch`** cambia todo en archivos grandes: sin él, Paramiko pide un bloque, espera la
  respuesta, pide el siguiente; con él, pide muchos a la vez. En una conexión con latencia, la
  diferencia es de varias veces.
- **El registro se escribe después de cada archivo.** Si la conexión se cae en el tercero, los dos
  primeros no se vuelven a bajar.
- **`prefetch` recibe el tamaño total del archivo**, no lo que falta por bajar: su documentación lo
  describe como el valor que devolvería `stat`. El primer borrador de esta sección le pasaba lo que
  faltaba, y al retomar no habría pedido el final del archivo.
- **El `.part` se retoma** con `seek`: una relación de pagos de 200 MB que se cortó en el 80% no
  empieza de cero.
- **La clave es nombre, tamaño y fecha.** Si la aseguradora reemplaza `pagos-septiembre.csv` por una
  versión corregida con el mismo nombre, la clave cambia y se vuelve a bajar.

---

## ⚠️ 4. Lo que se rompe

**FTP activo y pasivo detrás de un cortafuegos.** FTP abre una segunda conexión para los datos, y en
modo activo la abre el **servidor** hacia ti, cosa que casi ningún cortafuegos permite. `ftplib` usa
modo pasivo por defecto, que es lo correcto; si alguien lo cambió, el listado se queda colgado.

**El `.part` que no corresponde.** Si la aseguradora reemplazó el archivo entre la corrida que se
cortó y la que retoma, el `.part` tiene el principio de una versión y se le pega el final de otra. Por
eso la verificación de tamaño no basta cuando hay reemplazos: el resumen publicado por el emisor, o
borrar el `.part` cuando la fecha remota cambió.

**La hora del servidor.** `st_mtime` viene del reloj del servidor. Si está cinco minutos adelantado,
"lleva treinta segundos quieto" se cumple antes de tiempo. El archivo de control `.ok` no tiene ese
problema, y vale la pena pedírselo al emisor.

**El FTP sin TLS.** Si una aseguradora solo ofrece FTP en claro, el usuario y la contraseña viajan
legibles. No es un problema de Python, pero sí de quien lo acepta: se pide FTPS o SFTP por escrito, y
mientras tanto la cuenta tiene permiso solo de lectura.

---

## ⚖️ 5. Cuándo NO usarla

**Para sincronizar carpetas enteras entre máquinas propias.** `rsync` sobre SSH transfiere solo las
diferencias, retoma, verifica y conserva permisos, y llevarlo desde Python con `subprocess` es más
robusto que reimplementarlo con Paramiko.

**Cuando el emisor ofrece una API o un almacenamiento de objetos.** Un *bucket* con URL firmadas o una
API con listado y descarga resuelve el "terminó de llegar" por diseño: el objeto no existe hasta que
la subida termina.

**Para volúmenes que justifican un producto.** Una red con decenas de contrapartes y archivos diarios
es el caso de una plataforma de transferencia administrada (MFT), con auditoría y alertas incluidas.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corta la descarga a la mitad (mata el proceso con un archivo grande) y vuelve a correr.
   **Criterio:** la segunda corrida retoma desde el `.part` y el archivo final tiene el resumen
   correcto.
2. Reemplaza en el servidor un archivo ya bajado por una versión distinta con el mismo nombre.
   **Criterio:** la corrida siguiente lo vuelve a bajar y lo dice.
3. Cambia `SETTLE_SECONDS` a cero y explica qué riesgo aparece. **Criterio:** una frase con el caso
   concreto que se rompe.

**🟡 Intermedio (4–6)**

4. Busca en la documentación de Paramiko qué hace `posix_rename` y escribe el lado del **emisor**:
   subir a `.tmp` y renombrar. **Criterio:** un lector que corre en paralelo nunca ve el `.tmp` como
   archivo listo.
5. Si el emisor publica `archivo.csv.sha256`, verifica contra él antes de renombrar el `.part`.
   **Criterio:** un resumen alterado deja el `.part` en su lugar y falla con los dos valores.
6. Escribe la descarga FTPS completa con `mlsd`, `.part` y registro. **Criterio:** contra un servidor
   FTPS de pruebas en un contenedor, baja lo mismo que la versión SFTP.

**🟠 Difícil (7–9)**

7. Mide la descarga de un archivo de 200 MB con y sin `prefetch` en una conexión con 50 ms de
   latencia simulada (`tc netem` en el contenedor). **Criterio:** reportas los dos tiempos y el
   factor.
8. Haz que la descarga de varios archivos use varias conexiones en paralelo, sin pasar de tres.
   **Criterio:** el tiempo total baja, el registro sigue siendo correcto y una caída de una conexión
   no corrompe el registro de las otras.
9. Reemplaza la descarga por `rsync` orquestado con `subprocess` y compara. **Criterio:** una tabla con
   líneas, retoma, verificación y qué pasa con un archivo reemplazado.

**🔴 Muy difícil (10)**

10. Diseña la recepción de archivos de las dos aseguradoras como un proceso desatendido. **Criterio:**
    un documento de una página y un prototipo contra dos servidores de prueba (SFTP y FTPS).
    *Rúbrica:* (a) ningún archivo incompleto llega a la carpeta de procesamiento, demostrado con una
    prueba que corta la transferencia; (b) un archivo reemplazado se detecta y se avisa; (c) las
    credenciales no viven en el código ni en el repositorio; (d) dices qué le pedirías por escrito a
    cada aseguradora para hacer esto más simple.

---

## 📚 7. Referencias

**Documentación oficial**

- Paramiko, `SFTPClient` y `SFTPFile`: https://docs.paramiko.org/en/stable/api/sftp.html
- `ftplib`, incluido `FTP_TLS`: https://docs.python.org/3/library/ftplib.html
- `MLSD`, RFC 3659: https://www.rfc-editor.org/rfc/rfc3659

**Orden de lectura sugerido:** la página de SFTP de Paramiko, buscando `prefetch` y `posix_rename`;
después `ftplib`, solo la parte de `FTP_TLS` y `prot_p`.

---

## 🚀 8. Cierre

Transferir archivos se resuelve con cuatro reglas que no dependen del protocolo: no leer lo que se
está escribiendo, no publicar lo incompleto, verificar y recordar. SFTP con Paramiko y FTPS con
`ftplib` son la parte fácil.

**La señal de que quedó bien:** *"La aseguradora tardó en subir la relación de pagos, y el proceso la
bajó entera en la corrida siguiente, no la mitad en la primera."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-co-fase-05 -m "op co05 cerrada: descarga SFTP que retoma, verifica y recuerda"
> ```
>
> Los commits llevan su prefijo (`op co05: …`) y los de ejercicio su número
> (`op co05 ej07: …`).
