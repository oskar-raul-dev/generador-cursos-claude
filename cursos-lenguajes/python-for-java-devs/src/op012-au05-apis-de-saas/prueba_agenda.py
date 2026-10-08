"""Prueba la renovación y la paginación contra un Google simulado."""

import datetime as dt
import time

import httpx
import keyring
from keyring.backend import KeyringBackend

import agenda_franquicia as agenda


class MemoryKeyring(KeyringBackend):
    priority = 1
    store: dict = {}

    def get_password(self, service, user):
        return self.store.get((service, user))

    def set_password(self, service, user, password):
        self.store[(service, user)] = password

    def delete_password(self, service, user):
        self.store.pop((service, user), None)


def fake_google() -> httpx.MockTransport:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.host == "oauth2.googleapis.com":
            return httpx.Response(200, json={"access_token": "nuevo", "expires_in": 3600,
                                             "token_type": "Bearer", "refresh_token": "r1"})
        assert request.headers["Authorization"] == "Bearer nuevo", "no renovó antes de llamar"
        if request.url.params.get("pageToken") == "p2":
            return httpx.Response(200, json={"items": [{"summary": "Control ortodoncia"}]})
        return httpx.Response(200, json={"items": [{"summary": "Valoración"}, {"summary": "Limpieza"}],
                                         "nextPageToken": "p2"})
    return httpx.MockTransport(handler)


keyring.set_keyring(MemoryKeyring())
expired = {"access_token": "viejo", "refresh_token": "r1", "token_type": "Bearer",
           "expires_at": int(time.time()) - 60}
keyring.set_password(agenda.KEYRING_SERVICE, "sede-calendar", __import__("json").dumps(expired))

client = agenda.build_client("id-de-prueba", "secreto-de-prueba", "sede-calendar", transport=fake_google())
print([e["summary"] for e in agenda.fetch_events(client, dt.date(2026, 10, 5))])
print("token guardado:", agenda.load_token("sede-calendar")["access_token"])
