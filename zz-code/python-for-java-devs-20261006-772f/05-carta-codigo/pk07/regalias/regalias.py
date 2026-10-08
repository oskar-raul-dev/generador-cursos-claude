"""Reporte de regalías: lee un JSON de ventas y escribe el total por franquicia."""

import sys

import httpx  # noqa: F401  — para la versión que baja las ventas; aquí solo cuenta como dependencia pura
import orjson


def main() -> None:
    ventas = orjson.loads(sys.argv[1] if len(sys.argv) > 1 else '{"Suba": 142900000, "Zipaquirá": 61750000}')
    print(orjson.dumps({sede: round(v * 0.045) for sede, v in ventas.items()}).decode())


if __name__ == "__main__":
    main()
