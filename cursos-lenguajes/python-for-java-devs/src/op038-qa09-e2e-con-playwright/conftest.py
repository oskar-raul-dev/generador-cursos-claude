"""Levanta el sitio en un hilo para la sesión de pruebas."""

import threading
import time

import pytest
import uvicorn

from sitio import app


@pytest.fixture(scope="session", autouse=True)
def site():
    server = uvicorn.Server(uvicorn.Config(app, host="127.0.0.1", port=8765, log_level="warning"))
    thread = threading.Thread(target=server.run, daemon=True)
    thread.start()
    while not server.started:
        time.sleep(0.05)
    yield
    server.should_exit = True
    thread.join()
