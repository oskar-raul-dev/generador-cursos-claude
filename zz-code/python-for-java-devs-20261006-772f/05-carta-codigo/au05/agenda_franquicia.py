"""Lee la agenda de Google Calendar de un franquiciado con OAuth 2.0 y renovación automática."""

import datetime as dt
import json
from collections.abc import Callable, Iterator

import keyring
from authlib.integrations.httpx_client import OAuth2Client

AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URL = "https://oauth2.googleapis.com/token"
EVENTS_URL = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
SCOPE = "https://www.googleapis.com/auth/calendar.readonly"
KEYRING_SERVICE = "aurea-agenda-franquicia"


def save_token(site: str) -> Callable[..., None]:
    """El token vive en el llavero del sistema operativo, no en un archivo junto al código."""
    def update(token: dict, refresh_token: str | None = None, access_token: str | None = None) -> None:
        keyring.set_password(KEYRING_SERVICE, site, json.dumps(token))
    return update


def load_token(site: str) -> dict | None:
    stored = keyring.get_password(KEYRING_SERVICE, site)
    return json.loads(stored) if stored else None


def build_client(client_id: str, client_secret: str, site: str, **httpx_options) -> OAuth2Client:
    return OAuth2Client(
        client_id, client_secret,
        scope=SCOPE,
        redirect_uri="http://127.0.0.1:8765/callback",
        token_endpoint=TOKEN_URL,  # con esto, authlib renueva solo cuando el token venció
        token=load_token(site),
        update_token=save_token(site),
        timeout=20,
        **httpx_options,
    )


def authorize(client: OAuth2Client, site: str) -> None:
    """Una sola vez, con la persona delante: muestra la URL y cambia el código por tokens."""
    url, _state = client.create_authorization_url(AUTH_URL, access_type="offline", prompt="consent")
    print("Abre esta dirección y acepta el acceso de solo lectura:\n", url)
    redirected = input("Pega aquí la dirección completa a la que te llevó Google: ")
    token = client.fetch_token(TOKEN_URL, authorization_response=redirected)
    save_token(site)(token)


def fetch_events(client: OAuth2Client, day: dt.date) -> Iterator[dict]:
    """Las citas de un día, siguiendo la paginación por nextPageToken."""
    start = dt.datetime.combine(day, dt.time.min).astimezone()
    params = {"timeMin": start.isoformat(), "timeMax": (start + dt.timedelta(days=1)).isoformat(),
              "singleEvents": "true", "orderBy": "startTime", "maxResults": "250"}
    while True:
        response = client.get(EVENTS_URL, params=params)
        response.raise_for_status()
        page = response.json()
        yield from page.get("items", [])
        if "nextPageToken" not in page:
            return
        params["pageToken"] = page["nextPageToken"]
