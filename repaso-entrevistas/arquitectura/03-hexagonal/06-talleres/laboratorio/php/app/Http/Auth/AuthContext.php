<?php

declare(strict_types=1);

namespace App\Http\Auth;

use Hex\Application\Actor;

final readonly class AuthContext
{
    public function __construct(public Actor $actor, public TokenClaims $token) {}
}
