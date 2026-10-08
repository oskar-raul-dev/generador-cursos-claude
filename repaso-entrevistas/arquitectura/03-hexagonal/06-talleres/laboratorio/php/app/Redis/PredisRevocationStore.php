<?php

declare(strict_types=1);

namespace App\Redis;

use Hex\Application\Port\TokenRevocationStore;
use Predis\ClientInterface;

/** Revocación por jti con TTL: Redis olvida la clave cuando el token habría expirado. */
final readonly class PredisRevocationStore implements TokenRevocationStore
{
    private const string PREFIX = 'hex:revoked:';

    public function __construct(private ClientInterface $redis) {}

    public function revoke(string $tokenId, int $ttlSeconds): void
    {
        $this->redis->set(self::PREFIX.$tokenId, '1', 'EX', max(1, $ttlSeconds));
    }

    public function isRevoked(string $tokenId): bool
    {
        return (int) $this->redis->exists(self::PREFIX.$tokenId) === 1;
    }
}
