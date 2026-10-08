from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from ..errors import InvalidCredentials
from ..ports import Clock, IssuedToken, PasswordHasher, TokenIssuer, TokenRevocationStore, Users


@dataclass(frozen=True, slots=True)
class Login:
    """Usuario + contraseña → token. La comparación y el formato del token son puertos."""

    users: Users
    hasher: PasswordHasher
    tokens: TokenIssuer

    def execute(self, email: str, password: str) -> IssuedToken:
        # Mismo error exista o no el correo: no se revela quién tiene cuenta.
        user = self.users.find_by_email(email)
        if user is None or not self.hasher.matches(password, user.password_hash):
            raise InvalidCredentials()
        return self.tokens.issue(user)


@dataclass(frozen=True, slots=True)
class Logout:
    """Revoca el token presentado hasta que expire por sí solo."""

    revocations: TokenRevocationStore
    clock: Clock

    def execute(self, token_id: str, expires_at: datetime) -> None:
        remaining = expires_at - self.clock.now()
        if remaining.total_seconds() <= 0:
            return  # ya expiró: no hay nada que recordar
        self.revocations.revoke(token_id, remaining)
