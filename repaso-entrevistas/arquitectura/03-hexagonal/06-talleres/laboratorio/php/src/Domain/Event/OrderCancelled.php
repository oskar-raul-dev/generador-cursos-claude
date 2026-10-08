<?php

declare(strict_types=1);

namespace Hex\Domain\Event;

use DateTimeImmutable;

final readonly class OrderCancelled implements DomainEvent
{
    public function __construct(
        private string $eventId,
        private string $orderId,
        private string $customerId,
        private DateTimeImmutable $occurredAt,
    ) {}

    public function eventId(): string
    {
        return $this->eventId;
    }

    public function type(): string
    {
        return 'ORDER_CANCELLED';
    }

    public function orderId(): string
    {
        return $this->orderId;
    }

    public function customerId(): string
    {
        return $this->customerId;
    }

    public function occurredAt(): DateTimeImmutable
    {
        return $this->occurredAt;
    }
}
