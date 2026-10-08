"""El cálculo de vencimientos, medido con pytest-benchmark."""

import datetime as dt


def due_date(notified_on: dt.date, business_days: int = 15) -> dt.date:
    day, remaining = notified_on, business_days
    while remaining:
        day += dt.timedelta(days=1)
        if day.weekday() < 5:
            remaining -= 1
    return day


def test_due_date_speed(benchmark):
    result = benchmark(due_date, dt.date(2026, 9, 18))
    assert result == dt.date(2026, 10, 9)
