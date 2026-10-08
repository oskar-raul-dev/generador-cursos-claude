import type { Notifier, PendingPublications, UnitOfWork, Users } from "../ports.js";

// Parte 2. La política de entrega: cada hecho pendiente se entrega a su destinatario y se marca.
// Quién lo dispara es infraestructura. Al menos una vez: si el proceso cae entre notify y
// markPublished, la siguiente ronda repite la entrega y el Notifier debe tolerarlo.
export class DeliverPendingPublications {
  constructor(
    private readonly pending: PendingPublications,
    private readonly notifier: Notifier,
    private readonly users: Users,
    private readonly unitOfWork: UnitOfWork,
  ) {}

  execute(batchSize: number): Promise<number> {
    return this.unitOfWork.run(async () => {
      const batch = await this.pending.nextBatch(batchSize);
      for (const event of batch) {
        const recipient = (await this.users.findById(event.customerId))?.email ?? "unknown";
        await this.notifier.notify(event, recipient);
        await this.pending.markPublished(event.eventId);
      }
      return batch.length;
    });
  }
}
