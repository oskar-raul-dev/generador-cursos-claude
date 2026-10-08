<?php

declare(strict_types=1);

namespace Hex\Application\Port;

interface TokenRevocationStore
{
    public function revoke(string $tokenId, int $ttlSeconds): void;

    public function isRevoked(string $tokenId): bool;
}
