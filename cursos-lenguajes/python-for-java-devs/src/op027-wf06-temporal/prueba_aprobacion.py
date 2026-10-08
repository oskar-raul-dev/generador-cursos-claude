"""Dos trimestres: uno en que Édgar aprueba enseguida y otro en que no responde nunca."""

import asyncio
import uuid

from temporalio.testing import WorkflowEnvironment
from temporalio.worker import Worker

import aprobacion as a


async def main() -> None:
    async with await WorkflowEnvironment.start_time_skipping() as env:
        async with Worker(env.client, task_queue="liquidaciones", workflows=[a.SettlementApproval],
                          activities=[a.send_settlement, a.send_reminder, a.escalate, a.invoice]):
            quick = await env.client.start_workflow(a.SettlementApproval.run, "Suba",
                                                    id=f"suba-{uuid.uuid4()}", task_queue="liquidaciones")
            await quick.signal(a.SettlementApproval.respond, "aprobada")
            print("trimestre 3:", await quick.result())

            silent = await env.client.start_workflow(a.SettlementApproval.run, "Suba",
                                                     id=f"suba-{uuid.uuid4()}", task_queue="liquidaciones")
            print("estado:", await silent.query(a.SettlementApproval.status))
            print("trimestre 4:", await silent.result())   # diez días simulados
    for line in a.SENT:
        print(" ·", line)


asyncio.run(main())
