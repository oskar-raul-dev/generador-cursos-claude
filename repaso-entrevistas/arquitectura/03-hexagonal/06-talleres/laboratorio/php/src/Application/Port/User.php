<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use Hex\Application\Role;

final readonly class User
{
    public function __construct(public string $id, public string $email, public string $passwordHash, public Role $role) {}
}
