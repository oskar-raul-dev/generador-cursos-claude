<?php

declare(strict_types=1);

namespace App\Support;

use Hex\Application\Port\IdGenerator;
use Illuminate\Support\Str;

final class RandomIds implements IdGenerator
{
    public function next(): string
    {
        return (string) Str::uuid();
    }
}
