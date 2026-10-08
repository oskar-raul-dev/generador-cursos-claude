<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use DateTimeImmutable;

final readonly class IssuedToken
{
    public function __construct(public string $value, public string $tokenId, public DateTimeImmutable $expiresAt, public int $expiresInSeconds) {}
}
