<?php

declare(strict_types=1);

namespace Hex\Domain\Event;

use DateTimeImmutable;

/**
 * Hechos del dominio con identidad propia desde que nacen: la outbox y el consumidor deduplican
 * por eventId, y nunca se regenera por intento.
 */
interface DomainEvent
{
    public function eventId(): string;

    public function type(): string;

    public function orderId(): string;

    public function customerId(): string;

    public function occurredAt(): DateTimeImmutable;
}
