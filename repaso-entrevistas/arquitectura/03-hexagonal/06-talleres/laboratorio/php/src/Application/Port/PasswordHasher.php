<?php

declare(strict_types=1);

namespace Hex\Application\Port;

interface PasswordHasher
{
    public function matches(string $rawPassword, string $hash): bool;
}
