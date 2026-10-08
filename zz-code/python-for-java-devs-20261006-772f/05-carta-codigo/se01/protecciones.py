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
