<?php

declare(strict_types=1);

namespace Hex\Application\Port;

interface IdGenerator
{
    public function next(): string;
}
