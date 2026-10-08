<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use DateTimeImmutable;
use Hex\Application\Port\Clock;
use Hex\Application\Port\TokenRevocationStore;

/** Revoca el token presentado hasta que expire por sí solo. */
final readonly class Logout
{
    public function __construct(private TokenRevocationStore $revocations, private Clock $clock) {}

    public function execute(string $tokenId, DateTimeImmutable $expiresAt): void
    {
        $remaining = $expiresAt->getTimestamp() - $this->clock->now()->getTimestamp();
        if ($remaining <= 0) {
            return;  // ya expiró: no hay nada que recordar
        }
        $this->revocations->revoke($tokenId, $remaining);
    }
}
