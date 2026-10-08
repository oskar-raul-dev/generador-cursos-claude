"""PKCE y validación completa de un ID token de OIDC, con un proveedor simulado."""

import secrets
import time

from authlib.oauth2.rfc7636 import create_s256_code_challenge
from joserfc import jwt
from joserfc.errors import JoseError
from joserfc.jwk import KeySet, RSAKey

ISSUER = "https://login.ejemplo.example"
CLIENT_ID = "backoffice-aurea"

# ---------------------------------------------------- el proveedor (simulado)
provider_key = RSAKey.generate_key(2048, parameters={"kid": "k-2026-10"})
jwks_public = {"keys": [provider_key.as_dict(private=False)]}   # lo que publica en /jwks


def provider_issues(nonce: str, audience: str = CLIENT_ID, issuer: str = ISSUER,
                    expires_in: int = 300) -> str:
    now = int(time.time())
    claims = {"iss": issuer, "aud": audience, "sub": "1093", "email": "yuli.chaparro@aurea.example",
              "iat": now, "exp": now + expires_in, "nonce": nonce}
    return jwt.encode({"alg": "RS256", "kid": "k-2026-10"}, claims, provider_key)


# ---------------------------------------------------- el back-office
code_verifier = secrets.token_urlsafe(48)
code_challenge = create_s256_code_challenge(code_verifier)
nonce = secrets.token_urlsafe(16)
print("code_challenge:", code_challenge[:16], "…  (va en la redirección; el verifier se queda aquí)")

keys = KeySet.import_key_set(jwks_public)
rules = jwt.JWTClaimsRegistry(
    iss={"essential": True, "value": ISSUER},
    aud={"essential": True, "value": CLIENT_ID},
    nonce={"essential": True, "value": nonce},
)


def validate(id_token: str) -> str:
    try:
        token = jwt.decode(id_token, keys, algorithms=["RS256"])
        rules.validate(token.claims)          # iss, aud, nonce, y exp / nbf / iat
        return f"aceptado: {token.claims['email']}"
    except JoseError as e:
        return f"rechazado: {type(e).__name__}"


print("token correcto:       ", validate(provider_issues(nonce)))
print("para otra aplicación: ", validate(provider_issues(nonce, audience="otra-app")))
print("de otro emisor:       ", validate(provider_issues(nonce, issuer="https://evil.example")))
print("nonce de otra sesión: ", validate(provider_issues("otro-nonce")))
print("vencido:              ", validate(provider_issues(nonce, expires_in=-60)))

attacker_key = RSAKey.generate_key(2048, parameters={"kid": "k-2026-10"})
forged = jwt.encode({"alg": "RS256", "kid": "k-2026-10"},
                    {"iss": ISSUER, "aud": CLIENT_ID, "sub": "1", "email": "patricia@aurea.example",
                     "exp": int(time.time()) + 300, "nonce": nonce}, attacker_key)
print("firmado por otro:     ", validate(forged))
