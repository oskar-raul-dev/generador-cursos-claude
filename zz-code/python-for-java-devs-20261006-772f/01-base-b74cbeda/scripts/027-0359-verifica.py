# rescatado de la sesión b74cbeda, 2026-09-13T03:59:33Z · Build both container images
# syntax=docker/dockerfile:1
FROM python:3.14-slim AS build
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --no-cache fastapi==0.141.1 uvicorn==0.52.4 pydantic==2.13.5
COPY app_duelo.py .
EXPOSE 8000
CMD ["uvicorn", "app_duelo:app", "--host", "0.0.0.0", "--port", "8000", "--log-level", "error"]
