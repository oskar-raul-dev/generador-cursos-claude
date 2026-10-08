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
