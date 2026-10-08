<?php

declare(strict_types=1);

namespace Hex\Application\Port;

/** La clave se persiste con el efecto, en la misma transacción. */
interface IdempotencyStore
{
    public function find(string $actorId, string $key): ?StoredResponse;

    public function save(string $actorId, string $key, string $requestHash, int $status, string $body): void;
}
