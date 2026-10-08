<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

final readonly class LineRequest
{
    public function __construct(public string $sku, public int $quantity) {}
}
