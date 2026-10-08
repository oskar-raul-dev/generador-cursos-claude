<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use DateTimeImmutable;

final readonly class Notification
{
    public function __construct(public string $id, public string $orderId, public string $type, public string $recipient, public DateTimeImmutable $createdAt) {}
}
