<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Actor;
use Hex\Application\Page;
use Hex\Application\PageRequest;
use Hex\Application\Port\Notification;
use Hex\Application\Port\Notifications;

/** Parte 2. Solo operator: una ventana operativa a lo que entregó el Notifier. */
final readonly class ListNotifications
{
    public function __construct(private Notifications $notifications) {}

    /** @return Page<Notification> */
    public function execute(Actor $actor, ?string $orderId, PageRequest $page): Page
    {
        $actor->requireOperator();

        return $this->notifications->list($orderId, $page);
    }
}
