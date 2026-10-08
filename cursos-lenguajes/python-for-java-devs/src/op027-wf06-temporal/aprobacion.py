"""La aprobación trimestral de la liquidación de un franquiciado, como flujo durable."""

import asyncio
from datetime import timedelta

from temporalio import activity, workflow
from temporalio.common import RetryPolicy

SENT: list[str] = []  # registro de efectos, para verlos en la prueba


@activity.defn
async def send_settlement(franchise: str) -> None:
    SENT.append(f"liquidación a {franchise}")


@activity.defn
async def send_reminder(franchise: str) -> None:
    SENT.append(f"recordatorio a {franchise}")


@activity.defn
async def escalate(franchise: str) -> None:
    SENT.append(f"escalado a Julián: {franchise} no respondió")


@activity.defn
async def invoice(franchise: str) -> None:
    SENT.append(f"factura de regalías a {franchise}")


@workflow.defn
class SettlementApproval:
    def __init__(self) -> None:
        self.decision: str | None = None

    @workflow.signal
    def respond(self, decision: str) -> None:
        self.decision = decision

    @workflow.query
    def status(self) -> str:
        return self.decision or "esperando respuesta"

    async def _wait_for_answer(self, days: int) -> bool:
        try:
            await workflow.wait_condition(lambda: self.decision is not None, timeout=timedelta(days=days))
            return True
        except asyncio.TimeoutError:
            return False

    @workflow.run
    async def run(self, franchise: str) -> str:
        options = {"start_to_close_timeout": timedelta(minutes=2),
                   "retry_policy": RetryPolicy(maximum_attempts=5)}
        await workflow.execute_activity(send_settlement, franchise, **options)
        if not await self._wait_for_answer(days=5):
            await workflow.execute_activity(send_reminder, franchise, **options)
            if not await self._wait_for_answer(days=5):
                await workflow.execute_activity(escalate, franchise, **options)
                return "escalada"
        if self.decision == "aprobada":
            await workflow.execute_activity(invoice, franchise, **options)
        return self.decision
