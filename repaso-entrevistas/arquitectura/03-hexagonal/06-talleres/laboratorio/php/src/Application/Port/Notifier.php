<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use Hex\Domain\Event\DomainEvent;

interface Notifier
{
    public function notify(DomainEvent $event, string $recipient): void;
}
