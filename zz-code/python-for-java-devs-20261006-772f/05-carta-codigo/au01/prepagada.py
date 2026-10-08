"""Cliente de la API de autorizaciones: paginación, cuota y token que vence."""

import base64
import time
from collections.abc import Iterator

import httpx

BASE_URL = "https://api.prepagada.example/v2"


class ClientCredentials(httpx.Auth):
    """Pide un token OAuth 2.0 (client credentials) y lo renueva antes de que venza."""

    requires_response_body = True

    def __init__(self, client_id: str, client_secret: str, token_url: str, margin: float = 60):
        self._credentials = (client_id, client_secret)
        self._token_url = token_url
        self._margin = margin  # se renueva un minuto antes de vencer, no un segundo después
        self._token: str | None = None
        self._expires_at = 0.0

    def _token_request(self) -> httpx.Request:
        # Las credenciales van en Basic (RFC 6749 §2.3.1). httpx.Request no acepta auth=: eso es
        # del cliente, así que el encabezado se arma aquí.
        basic = base64.b64encode(":".join(self._credentials).encode()).decode()
        return httpx.Request("POST", self._token_url, data={"grant_type": "client_credentials"},
                             headers={"Authorization": f"Basic {basic}"})

    def _store(self, response: httpx.Response) -> None:
        response.raise_for_status()
        payload = response.json()
        self._token = payload["access_token"]
        self._expires_at = time.monotonic() + payload["expires_in"] - self._margin

    def auth_flow(self, request: httpx.Request):
        if self._token is None or time.monotonic() >= self._expires_at:
            self._store((yield self._token_request()))
        request.headers["Authorization"] = f"Bearer {self._token}"
        response = yield request
        if response.status_code == 401:
            # El servidor revocó el token antes de tiempo: uno nuevo y un solo reintento.
            self._store((yield self._token_request()))
            request.headers["Authorization"] = f"Bearer {self._token}"
            yield request


class TokenBucket:
    """Cuota del lado del cliente: `rate` peticiones por segundo, con ráfagas de `burst`."""

    def __init__(self, rate: float, burst: int):
        self.rate, self.capacity = rate, burst
        self.tokens, self.updated = float(burst), time.monotonic()

    def acquire(self) -> None:
        while True:
            now = time.monotonic()
            self.tokens = min(self.capacity, self.tokens + (now - self.updated) * self.rate)
            self.updated = now
            if self.tokens >= 1:
                self.tokens -= 1
                return
            time.sleep((1 - self.tokens) / self.rate)


def get(client: httpx.Client, bucket: TokenBucket, url: str, **params) -> httpx.Response:
    for attempt in range(5):
        bucket.acquire()
        response = client.get(url, params=params or None)
        if response.status_code != 429:
            response.raise_for_status()
            return response
        # El servidor manda; Retry-After en segundos es lo habitual, y se respeta tal cual.
        time.sleep(float(response.headers.get("Retry-After", 2 ** attempt)))
    raise RuntimeError(f"la prepagada sigue respondiendo 429 después de 5 intentos: {url}")


def authorizations(client: httpx.Client, bucket: TokenBucket, since: str) -> Iterator[dict]:
    """Paginación por cursor en el cuerpo."""
    cursor = None
    while True:
        params = {"desde": since, **({"cursor": cursor} if cursor else {})}
        page = get(client, bucket, "/autorizaciones", **params).json()
        yield from page["items"]
        cursor = page.get("siguiente")
        if not cursor:
            return


def objections(client: httpx.Client, bucket: TokenBucket) -> Iterator[dict]:
    """Paginación por encabezado Link (RFC 8288): la URL siguiente la da el servidor."""
    url: str | None = "/glosas"
    while url:
        response = get(client, bucket, url)
        yield from response.json()
        url = response.links.get("next", {}).get("url")


def fake_api() -> httpx.MockTransport:
    """La prepagada, simulada: token, dos endpoints paginados y un 429 de cortesía."""
    state = {"calls": 0}

    def handler(request: httpx.Request) -> httpx.Response:
        path = request.url.path
        if path.endswith("/oauth/token"):
            return httpx.Response(200, json={"access_token": "tok-1", "expires_in": 900})
        assert request.headers["Authorization"] == "Bearer tok-1"
        state["calls"] += 1
        if state["calls"] == 2:
            return httpx.Response(429, headers={"Retry-After": "0"})
        if path.endswith("/autorizaciones"):
            if request.url.params.get("cursor") == "c2":
                return httpx.Response(200, json={"items": [{"id": "AUT-3"}], "siguiente": None})
            return httpx.Response(200, json={"items": [{"id": "AUT-1"}, {"id": "AUT-2"}],
                                             "siguiente": "c2"})
        if path.endswith("/glosas"):
            if request.url.params.get("page") == "2":
                return httpx.Response(200, json=[{"id": "GL-9"}])
            return httpx.Response(200, json=[{"id": "GL-7"}, {"id": "GL-8"}],
                                  headers={"Link": f'<{BASE_URL}/glosas?page=2>; rel="next"'})
        return httpx.Response(404)

    return httpx.MockTransport(handler)


if __name__ == "__main__":
    auth = ClientCredentials("aurea", "secreto-de-prueba", f"{BASE_URL}/oauth/token")
    bucket = TokenBucket(rate=1.0, burst=5)  # 60 por minuto, con ráfagas de 5
    with httpx.Client(base_url=BASE_URL, auth=auth, transport=fake_api(),
                      timeout=httpx.Timeout(10, connect=3)) as client:
        print([a["id"] for a in authorizations(client, bucket, since="2026-09-01")])
        print([g["id"] for g in objections(client, bucket)])
