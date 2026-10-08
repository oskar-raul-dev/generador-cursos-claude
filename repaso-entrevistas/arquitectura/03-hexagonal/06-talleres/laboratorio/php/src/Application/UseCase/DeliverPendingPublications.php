<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Port\Notifier;
use Hex\Application\Port\PendingPublications;
use Hex\Application\Port\UnitOfWork;
use Hex\Application\Port\Users;

/**
 * Parte 2. La política de entrega. Quién la dispara (un comando artisan, un cron) es
 * infraestructura. Al menos una vez: si el proceso cae entre notify y markPublished, la siguiente
 * ronda repite la entrega y el Notifier debe tolerarlo.
 */
final readonly class DeliverPendingPublications
{
    public function __construct(
        private PendingPublications $pending,
        private Notifier $notifier,
        private Users $users,
        private UnitOfWork $unitOfWork,
    ) {}

    public function execute(int $batchSize): int
    {
        return $this->unitOfWork->run(function () use ($batchSize): int {
            $batch = $this->pending->nextBatch($batchSize);
            foreach ($batch as $event) {
                $user = $this->users->findById($event->customerId());
                $this->notifier->notify($event, $user?->email ?? 'unknown');
                $this->pending->markPublished($event->eventId());
            }

            return count($batch);
        });
    }
}
