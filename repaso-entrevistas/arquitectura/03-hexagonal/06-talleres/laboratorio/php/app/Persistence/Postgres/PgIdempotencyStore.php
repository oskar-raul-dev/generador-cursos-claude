<?php

declare(strict_types=1);

namespace App\Persistence\Postgres;

use Hex\Application\Port\IdempotencyStore;
use Hex\Application\Port\StoredResponse;
use Illuminate\Database\ConnectionInterface;

/** La clave vive en PostgreSQL, en la misma transacción que el efecto. response_body es jsonb. */
final readonly class PgIdempotencyStore implements IdempotencyStore
{
    public function __construct(private ConnectionInterface $db) {}

    public function find(string $actorId, string $key): ?StoredResponse
    {
        $rows = $this->db->select(
            'SELECT request_hash, response_status, response_body FROM idempotency_keys WHERE key = :key AND actor_id = CAST(:a AS uuid)',
            ['key' => $key, 'a' => $actorId],
        );
        if ($rows === []) {
            return null;
        }

        return new StoredResponse($rows[0]->request_hash, (int) $rows[0]->response_status, Rows::json($rows[0]->response_body)['ref']);
    }

    public function save(string $actorId, string $key, string $requestHash, int $status, string $body): void
    {
        $this->db->insert(
            'INSERT INTO idempotency_keys (key, actor_id, request_hash, response_status, response_body)
             VALUES (:key, CAST(:a AS uuid), :hash, :status, CAST(:body AS jsonb))',
            ['key' => $key, 'a' => $actorId, 'hash' => $requestHash, 'status' => $status, 'body' => json_encode(['ref' => $body], JSON_THROW_ON_ERROR)],
        );
    }
}
