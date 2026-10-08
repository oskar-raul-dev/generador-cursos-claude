<?php

declare(strict_types=1);

namespace App\Http\Auth;

use DateTimeImmutable;

final readonly class TokenClaims
{
    public function __construct(public string $subject, public string $email, public string $role, public string $tokenId, public DateTimeImmutable $expiresAt) {}
}
