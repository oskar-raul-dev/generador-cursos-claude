<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use Hex\Domain\Event\DomainEvent;

interface PendingPublications
{
    public function add(DomainEvent $event): void;

    /** @return list<DomainEvent> */
    public function nextBatch(int $size): array;

    public function markPublished(string $eventId): void;
}
