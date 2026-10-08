<?php

declare(strict_types=1);

namespace Hex\Application\Port;

final readonly class StoredResponse
{
    public function __construct(public string $requestHash, public int $status, public string $body) {}
}
