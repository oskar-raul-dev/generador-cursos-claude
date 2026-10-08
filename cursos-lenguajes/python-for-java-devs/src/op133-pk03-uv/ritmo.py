"""Cuántas versiones publicó un paquete en los últimos 90 días, según PyPI."""

import datetime as dt
import json
import sys
import urllib.request

today = dt.datetime(2026, 10, 5, tzinfo=dt.UTC)
for package in sys.argv[1:]:
    data = json.load(urllib.request.urlopen(f"https://pypi.org/pypi/{package}/json", timeout=20))
    dates = [min(dt.datetime.fromisoformat(f["upload_time_iso_8601"]) for f in files)
             for files in data["releases"].values() if files]
    recent = [d for d in dates if (today - d).days <= 90]
    print(f"{package:<10} {len(recent):>3} versiones en 90 días · última: {data['info']['version']}")
