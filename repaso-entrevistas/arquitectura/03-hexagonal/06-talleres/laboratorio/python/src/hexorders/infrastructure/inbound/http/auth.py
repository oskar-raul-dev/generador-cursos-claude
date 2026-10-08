"""Autenticación del borde como dependencia de FastAPI. Verifica el bearer (firma, fecha) y la
revocación por jti, y entrega un Actor de aplicación. `Depends` vive aquí, no en los casos de uso."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Protocol

from fastapi import Request

from hexorders.application.actor import Actor, Role
from hexorders.application.ports import TokenRevocationStore

from .problems import Unauthenticated


@dataclass(frozen=True, slots=True)
class TokenClaims:
    subject: str
    email: str
    role: str
    token_id: str
    expires_at: datetime


class TokenVerifier(Protocol):
    """Interfaz del borde de entrada, no un puerto del núcleo: el núcleo nunca ve un token."""

    def verify(self, token: str) -> TokenClaims: ...


@dataclass(frozen=True, slots=True)
class AuthContext:
    actor: Actor
    token: TokenClaims


class Authenticator:
    def __init__(self, verifier: TokenVerifier, revocations: TokenRevocationStore) -> None:
        self._verifier, self._revocations = verifier, revocations

    def __call__(self, request: Request) -> AuthContext:
        header = request.headers.get("authorization", "")
        if not header.startswith("Bearer "):
            raise Unauthenticated("UNAUTHENTICATED")
        try:
            claims = self._verifier.verify(header.removeprefix("Bearer "))
        except Exception as exc:  # firma, expiración, forma: todo es "no autenticado"
            raise Unauthenticated("UNAUTHENTICATED") from exc
        if self._revocations.is_revoked(claims.token_id):
            raise Unauthenticated("TOKEN_REVOKED")
        actor = Actor(claims.subject, claims.email, claims.role)  # type: ignore[arg-type]
        return AuthContext(actor, claims)

