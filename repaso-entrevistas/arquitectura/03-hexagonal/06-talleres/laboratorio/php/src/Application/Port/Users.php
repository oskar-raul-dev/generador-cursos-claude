<?php

declare(strict_types=1);

namespace Hex\Application\Port;

interface Users
{
    public function findByEmail(string $email): ?User;

    public function findById(string $id): ?User;
}
