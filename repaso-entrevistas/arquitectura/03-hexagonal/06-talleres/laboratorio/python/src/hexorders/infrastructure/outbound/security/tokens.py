"""JWT HS256 con PyJWT (emitir y verificar) y bcrypt para las contraseñas de la semilla."""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt

from hexorders.application.ports import Clock, IssuedToken, User
from hexorders.infrastructure.inbound.http.auth import TokenClaims


class JwtTokens:
    """Satisface el puerto TokenIssuer (para Login) y la interfaz TokenVerifier del borde HTTP."""

    def __init__(self, secret: str, ttl_seconds: int, clock: Clock) -> None:
        self._secret, self._ttl, self._clock = secret, ttl_seconds, clock

    def issue(self, user: User) -> IssuedToken:
        now = self._clock.now()
        expires_at = now + timedelta(seconds=self._ttl)
        jti = uuid.uuid4().hex
        value = jwt.encode({"sub": user.id, "email": user.email, "role": user.role, "jti": jti,
                            "iat": int(now.timestamp()), "exp": int(expires_at.timestamp())},
                           self._secret, algorithm="HS256")
        return IssuedToken(value, jti, expires_at, self._ttl)

    def verify(self, token: str) -> TokenClaims:
        claims = jwt.decode(token, self._secret, algorithms=["HS256"], options={"require": ["sub", "jti", "exp"]})
        return TokenClaims(claims["sub"], claims.get("email", ""), claims.get("role", ""), claims["jti"],
                           datetime.fromtimestamp(claims["exp"], tz=timezone.utc))


class BcryptHasher:
    def matches(self, raw_password: str, hash: str) -> bool:
        return bcrypt.checkpw(raw_password.encode(), hash.encode())
