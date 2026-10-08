"""Una columna cifrada con rotación de claves, y un archivo que solo la central puede abrir."""

from cryptography.fernet import Fernet, InvalidToken, MultiFernet
from nacl.public import PrivateKey, SealedBox

# ------------------------------------------------- 1. la columna de notas, con rotación de claves

old_key, new_key = Fernet(Fernet.generate_key()), Fernet(Fernet.generate_key())

# Hasta ayer, el back-office cifraba con la clave vieja.
row = old_key.encrypt("Control de periodoncia: buena evolución".encode())
print("guardado en la columna:", row[:24], "…")

# Hoy se rota: la nueva va primero, la vieja se conserva para leer lo que falta.
keys = MultiFernet([new_key, old_key])
print("se lee con la lista:", keys.decrypt(row).decode())
rotated = keys.rotate(row)                     # recifrado con la nueva, sin salir de la función
print("ya se lee solo con la nueva:", new_key.decrypt(rotated).decode())
try:
    old_key.decrypt(rotated)
except InvalidToken:
    print("y la vieja ya no la abre")

# ------------------------------------------------- 2. el archivo del franquiciado, sellado para la central

aurea_private = PrivateKey.generate()          # vive solo en la central
aurea_public = aurea_private.public_key        # se publica: cualquiera puede cifrar con ella

monthly_file = b"documento;plan;fase;valor\n1023456789;AS-221;2;1850000\n"
sealed = SealedBox(aurea_public).encrypt(monthly_file)     # lo hace el franquiciado
print("sellado:", len(sealed), "bytes; el original tenía", len(monthly_file))
print("lo abre la central:", SealedBox(aurea_private).decrypt(sealed).decode().splitlines()[0])

other = PrivateKey.generate()                  # otro franquiciado, con su propia clave
try:
    SealedBox(other).decrypt(sealed)
except Exception as error:
    print("otro franquiciado no puede:", type(error).__name__)
