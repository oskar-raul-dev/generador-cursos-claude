# 🔐 se01 — El modelo: qué pregunta contesta cada primitiva

> Python para desarrolladores Java senior · **Carta** · Track `se` — Seguridad aplicada y
> criptografía · sección 1 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta. Conviene haber leído la
> [Fase 16](16-operacion-y-rendimiento.md), que cubre `pickle`, `yaml`, la cadena de suministro y
> `SecretStr`.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Los aliados de Áurea —los veintitrés consultorios externos que reciben pacientes remitidos— avisan cuando
cobran un caso, porque de ese cobro sale la comisión que le deben a Áurea. Hoy avisan por WhatsApp; el
proyecto es que manden una notificación a Cartera con el número de remisión y el monto cobrado. Y alguien
pregunta en la reunión: *"¿y cómo sabemos que el monto no lo cambió nadie por el camino?"*. Otro contesta:
*"le ponemos un hash"*.

Esa respuesta es el error que esta sección existe para evitar. Un hash no protege contra nadie: quien cambia
el monto recalcula el hash. La pregunta "¿lo cambiaron?" tiene varias versiones, y cada una tiene su
primitiva:

- ¿Lo cambió **alguien**, por accidente? → un resumen (*hash*).
- ¿Lo cambió **alguien que no es el aliado**? → un código de autenticación (HMAC), con un secreto compartido.
- ¿Lo pudo **leer** alguien por el camino? → cifrado autenticado (AES-GCM, ChaCha20-Poly1305).
- ¿Puede el aliado **negar después** que lo mandó? → una firma digital, con su clave privada.

Elegir la primitiva por su nombre —"usemos SHA-256, que es seguro"— en vez de por la pregunta es el error de
diseño criptográfico más común, y no lo arregla ninguna biblioteca.

---

## 🧠 2. El modelo

| Pregunta | Propiedad | Primitiva | Qué necesita | En Python |
|---|---|---|---|---|
| ¿Llegó igual? (sin atacante) | Integridad | Resumen: SHA-256 | Nada | `hashlib` |
| ¿Llegó igual **y** lo mandó quien tiene el secreto? | Integridad + autenticidad | HMAC-SHA256 | Un secreto compartido | `hmac` |
| ¿Nadie más lo pudo leer, y llegó igual? | Confidencialidad + integridad | Cifrado autenticado: AES-GCM | Una clave compartida | `cryptography` |
| ¿Lo firmó el aliado, y puede probarlo un tercero? | Autenticidad + no repudio | Firma: Ed25519 | Clave privada del aliado, pública para todos | `cryptography` |

La columna que decide es **"qué necesita"**. HMAC y cifrado necesitan un secreto que las dos partes
conocen, y por eso cualquiera de las dos pudo haber producido el mensaje: no hay no repudio. La firma usa una
clave que solo tiene el aliado, y por eso Áurea puede mostrarle a un tercero que el mensaje vino de él.

### Tu instinto de Java dice… y esta vez se equivoca

En Java, el reflejo es buscar en la JCA (`MessageDigest`, `Mac`, `Cipher`, `Signature`) el algoritmo que
alguien recomendó, y configurarlo con su cadena de transformación (`"AES/GCM/NoPadding"`). La API invita a
elegir por nombre y modo. En Python, `cryptography` tiene dos capas a propósito: la de arriba —**recetas**
como `Fernet` o `AESGCM`— que no deja elegir mal, y la de abajo, `hazmat` (*materiales peligrosos*), que sí.
El nombre del módulo es la advertencia.

---

## 💻 3. El ejemplo que corre

```bash
uv add cryptography
```

`protecciones.py` manda la misma notificación de cobro protegida de las cuatro formas, y un atacante cambia
el monto de 450.000 a 45.000 en cada una:

```python
"""La misma notificación de un aliado, protegida de cuatro formas, contra un atacante que cambia el monto."""

import hashlib
import hmac
import json
import os

from cryptography.exceptions import InvalidSignature, InvalidTag
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

message = json.dumps({"remision": "REM-4411", "aliado": "ALI-07", "monto": 450000}).encode()


def tamper(data: bytes) -> bytes:
    return data.replace(b"450000", b"045000")


# 1. Resumen: el atacante recalcula el hash. No detecta nada.
digest = hashlib.sha256(message).hexdigest()
forged, forged_digest = tamper(message), hashlib.sha256(tamper(message)).hexdigest()
print("hash:   ", "detecta" if hashlib.sha256(forged).hexdigest() != forged_digest else "NO detecta")

# 2. HMAC: el atacante no tiene el secreto compartido con el aliado.
secret = os.urandom(32)
tag = hmac.new(secret, message, hashlib.sha256).digest()
valid = hmac.compare_digest(hmac.new(secret, tamper(message), hashlib.sha256).digest(), tag)
print("HMAC:   ", "NO detecta" if valid else "detecta")

# 3. AES-GCM: además de detectar el cambio, nadie leyó el monto por el camino.
key = AESGCM.generate_key(bit_length=256)
nonce = os.urandom(12)                      # nunca se repite con la misma clave
ciphertext = AESGCM(key).encrypt(nonce, message, b"cartera-v1")
print("cifrado:", b"450000" in ciphertext and "el monto se lee" or "el monto no se lee", end=" · ")
try:
    AESGCM(key).decrypt(nonce, ciphertext[:-20] + bytes(20), b"cartera-v1")
    print("NO detecta")
except InvalidTag:
    print("detecta")

# 4. Firma: solo el aliado puede firmar; cualquiera con su clave pública verifica.
private = Ed25519PrivateKey.generate()
public = private.public_key()
signature = private.sign(message)
try:
    public.verify(signature, tamper(message))
    print("firma:  ", "NO detecta")
except InvalidSignature:
    print("firma:  ", "detecta, y el aliado no puede negar el original")
```

```bash
python3 protecciones.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
hash:    NO detecta
HMAC:    detecta
cifrado: el monto no se lee · detecta
firma:   detecta, y el aliado no puede negar el original
```

La primera línea es la respuesta a la reunión: el hash solo, frente a alguien que puede cambiar el mensaje,
no protege nada. Las otras tres detectan el cambio, y se eligen por lo que **además** hace falta: que nadie
lea el monto (cifrado), o poder probarle a un tercero quién lo mandó (firma).

**Detalles con intención**

- **`hmac.compare_digest`** compara en tiempo constante. Con `==`, el tiempo que tarda la comparación filtra
  cuántos bytes coinciden, y un atacante paciente reconstruye la etiqueta byte a byte.
- **El *nonce* de AES-GCM no se repite nunca con la misma clave.** Repetirlo una vez permite recuperar la
  clave de autenticación. Doce bytes aleatorios por mensaje es la receta.
- **`b"cartera-v1"` son datos asociados**: se autentican sin cifrarse. Si alguien toma un mensaje cifrado
  para otro sistema y lo reenvía a Cartera, falla, porque los datos asociados no coinciden.
- **Ed25519** en vez de RSA para firmas nuevas: claves y firmas cortas, sin parámetros que elegir mal.

---

## ⚠️ 4. Lo que se rompe

**El "hash con sal" como autenticación.** `sha256(secreto + mensaje)` parece un HMAC y no lo es: con SHA-256,
es vulnerable a la extensión de longitud. HMAC existe exactamente para no inventar esa construcción.

**Cifrar sin autenticar.** AES en modo CBC o CTR cifra pero no detecta cambios: un atacante puede alterar bytes
del texto cifrado y cambiar el texto claro de forma predecible. Por eso la receta es siempre cifrado
**autenticado** (GCM, ChaCha20-Poly1305, o `Fernet`, que es CBC con HMAC ya combinados).

**La firma sin verificar la clave pública.** Una firma prueba que el mensaje lo firmó **quien tiene esa clave
privada**. Si la clave pública del aliado llegó por el mismo canal que el mensaje, un atacante manda la suya.
La clave pública se registra una vez, por un canal confiable, y se fija.

---

## ⚖️ 5. Cuándo NO usarla

**Para lo que ya resuelve TLS.** Si el aliado manda la notificación por HTTPS a Cartera, el canal ya da
confidencialidad e integridad **en tránsito**. HMAC o firma agregan algo solo si el mensaje se guarda, se
reenvía, o pasa por intermediarios en los que no confías; y la autenticidad del remitente, que TLS sin
certificado de cliente no da.

**Para inventar un protocolo.** Combinar primitivas para resolver algo nuevo —intercambio de claves, sesiones,
rotación— es el terreno donde se equivocan los expertos. Para eso hay protocolos estándar (TLS, JOSE, Noise)
con bibliotecas mantenidas.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Reemplaza `hmac.compare_digest` por `==`. **Criterio:** explicas qué ataque habilitas, aunque el ejemplo
   siga funcionando.
2. Usa `Fernet` (la receta de `cryptography`) para cifrar la notificación. **Criterio:** cifrar, descifrar y
   detectar un byte cambiado, en cinco líneas.
3. Cambia los datos asociados al descifrar (`b"cartera-v2"`). **Criterio:** el descifrado falla con
   `InvalidTag`, y explicas para qué sirve.

**🟡 Intermedio (4–6)**

4. Escribe el receptor de la notificación del aliado con HMAC en un encabezado, como hacen los *webhooks* de
   los servicios de pago. **Criterio:** una notificación con el encabezado alterado se rechaza con 401.
5. Busca en la documentación de `cryptography` qué recetas trae fuera de `hazmat`. **Criterio:** una lista y
   para qué pregunta sirve cada una.
6. Serializa la clave pública de Ed25519 en PEM y verifica una firma con la clave cargada desde el archivo.
   **Criterio:** la verificación funciona en otro proceso, sin la clave privada.

**🟠 Difícil (7–9)**

7. Demuestra el problema de `sha256(secreto + mensaje)` con una biblioteca de extensión de longitud o
   escribiendo el ataque. **Criterio:** produces un mensaje extendido con una etiqueta válida sin conocer el
   secreto.
8. Agrega a la notificación una marca de tiempo y un identificador único, y rechaza las repetidas.
   **Criterio:** reenviar una notificación válida una segunda vez se rechaza.
9. Mide cuánto tarda cada una de las cuatro protecciones sobre un mensaje de 1 KB, 100.000 veces.
   **Criterio:** los cuatro tiempos con la máquina, y si alguno importa para el volumen de los aliados.

**🔴 Muy difícil (10)**

10. Diseña cómo se protegen las notificaciones de cobro de los veintitrés aliados. **Criterio:** un documento de
    una página. *Rúbrica:* (a) cada propiedad requerida está justificada con un caso de Áurea; (b) la
    primitiva sale de la tabla, no de un nombre; (c) dice cómo se distribuyen y se rotan las claves o secretos;
    (d) dice qué pasa el día que un aliado discute un monto.

---

## 📚 7. Referencias

**Documentación oficial**

- `cryptography`, recetas y `hazmat`: https://cryptography.io/en/latest/
- `hmac` y `compare_digest`: https://docs.python.org/3/library/hmac.html
- `hashlib`: https://docs.python.org/3/library/hashlib.html

**Libros**

- Jean-Philippe Aumasson, *Serious Cryptography*, 2.ª edición (No Starch Press, 2024): la mejor introducción
  práctica a qué contesta cada primitiva. Página del libro: https://nostarch.com/serious-cryptography-2nd-edition

**Orden de lectura sugerido:** la portada de la documentación de `cryptography`, que explica las dos capas; el
libro cuando quieras entender por qué cada receta es como es.

---

## 🚀 8. Cierre

Cada primitiva contesta una pregunta: el resumen, si llegó igual sin atacante; HMAC, si lo mandó quien tiene
el secreto; el cifrado autenticado, si nadie lo leyó; la firma, si el remitente puede negarlo. Se elige por la
pregunta, no por el nombre, y casi siempre con la receta, no con `hazmat`.

**La señal de que quedó bien:** *"Alguien propuso 'ponerle un hash' a las notificaciones de los aliados y la
respuesta fue una pregunta: ¿contra quién?"*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-se-fase-01 -m "op se01 cerrada: cuatro protecciones y la pregunta de cada una"
> ```
>
> Los commits llevan su prefijo (`op se01: …`) y los de ejercicio su número
> (`op se01 ej07: …`).
