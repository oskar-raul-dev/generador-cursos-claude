<?php

declare(strict_types=1);

namespace App\Persistence\Postgres;

use Hex\Application\Port\PendingPublications;
use Hex\Domain\Event\DomainEvent;
use Hex\Domain\Event\OrderCancelled;
use Illuminate\Database\ConnectionInterface;

/** La outbox en PostgreSQL (parte 2). */
final readonly class PgPendingPublications implements PendingPublications
{
    public function __construct(private ConnectionInterface $db) {}

    public function add(DomainEvent $event): void
    {
        $this->db->insert(
            "INSERT INTO outbox (id, aggregate_type, aggregate_id, event_type, payload, occurred_at)
             VALUES (CAST(:id AS uuid), 'Order', CAST(:o AS uuid), :type, CAST(:payload AS jsonb), CAST(:at AS timestamptz))",
            ['id' => $event->eventId(), 'o' => $event->orderId(), 'type' => $event->type(),
                'payload' => json_encode(['orderId' => $event->orderId(), 'customerId' => $event->customerId()], JSON_THROW_ON_ERROR),
                'at' => Rows::bindTime($event->occurredAt())],
        );
    }

    public function nextBatch(int $size): array
    {
        $rows = $this->db->select(
            'SELECT id::text AS id, aggregate_id::text AS order_id, payload, occurred_at::text AS occurred_at FROM outbox
             WHERE published_at IS NULL ORDER BY occurred_at LIMIT :n',
            ['n' => $size],
        );
        if ($rows !== []) {
            $marks = implode(', ', array_fill(0, count($rows), 'CAST(? AS uuid)'));
            $this->db->update("UPDATE outbox SET attempts = attempts + 1 WHERE id IN ({$marks})", array_column($rows, 'id'));
        }

        return array_map(
            fn (object $r) => new OrderCancelled($r->id, $r->order_id, Rows::json($r->payload)['customerId'], Rows::time($r->occurred_at)),
            $rows,
        );
    }

    public function markPublished(string $eventId): void
    {
        $this->db->update('UPDATE outbox SET published_at = now() WHERE id = CAST(:id AS uuid)', ['id' => $eventId]);
    }
}
