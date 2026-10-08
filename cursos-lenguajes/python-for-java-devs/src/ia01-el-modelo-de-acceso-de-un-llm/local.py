"""Modelo local con Ollama.

Está por dos razones y conviene no confundirlas. La barata: los ejercicios de este
track no tienen por qué costar dinero. La importante: es la única vía por la que un
dato que roce la frontera clínica puede tocar un modelo, porque nunca sale de la
máquina. Ver 00-historia-de-aurea.md §5.
"""

from __future__ import annotations

from ollama import Client

LOCAL_MODEL = "gemma3"


def ask_local(question: str, *, model: str = LOCAL_MODEL, host: str | None = None) -> str:
    """Hace la misma pregunta a un modelo que corre en esta máquina.

    Sin costo por token y sin salida a la red. A cambio: más lento en un portátil,
    y con una calidad que la sección 6 mide en vez de suponer.
    """
    client = Client(host=host) if host is not None else Client()
    response = client.chat(
        model=model,
        messages=[{"role": "user", "content": question}],
    )
    return response.message.content or ""
