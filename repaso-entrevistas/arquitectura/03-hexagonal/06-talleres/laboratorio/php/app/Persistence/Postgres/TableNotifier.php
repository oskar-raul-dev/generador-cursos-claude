<?php

declare(strict_types=1);

namespace App\Persistence\Postgres;

use Hex\Application\Port\Notifier;
use Hex\Domain\Event\DomainEvent;
use Illuminate\Database\ConnectionInterface;

/** Entrega escribiendo una fila; ON CONFLICT DO NOTHING hace que una segunda entrega no cree otra. */
final readonly class TableNotifier implements Notifier
{
    public function __construct(private ConnectionInterface $db) {}

    public function notify(DomainEvent $event, string $recipient): void
    {
        $this->db->insert(
            'INSERT INTO notifications (id, order_id, type, recipient, payload)
             VALUES (CAST(:id AS uuid), CAST(:o AS uuid), :type, :to, CAST(:payload AS jsonb)) ON CONFLICT (id) DO NOTHING',
            ['id' => $event->eventId(), 'o' => $event->orderId(), 'type' => $event->type(), 'to' => $recipient,
                'payload' => json_encode(['eventId' => $event->eventId(), 'occurredAt' => $event->occurredAt()->format(DATE_ATOM)], JSON_THROW_ON_ERROR)],
        );
    }
}
