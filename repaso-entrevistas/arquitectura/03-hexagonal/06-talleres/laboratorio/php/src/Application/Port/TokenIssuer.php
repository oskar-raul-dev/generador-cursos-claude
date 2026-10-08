<?php

declare(strict_types=1);

namespace Hex\Application\Port;

interface TokenIssuer
{
    public function issue(User $user): IssuedToken;
}
