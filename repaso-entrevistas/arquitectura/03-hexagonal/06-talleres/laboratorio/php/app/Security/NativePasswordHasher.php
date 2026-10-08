<?php

declare(strict_types=1);

namespace App\Security;

use Hex\Application\Port\PasswordHasher;

/** password_verify entiende los $2y$ de la semilla sin librería: bcrypt es nativo en PHP. */
final class NativePasswordHasher implements PasswordHasher
{
    public function matches(string $rawPassword, string $hash): bool
    {
        return password_verify($rawPassword, $hash);
    }
}
