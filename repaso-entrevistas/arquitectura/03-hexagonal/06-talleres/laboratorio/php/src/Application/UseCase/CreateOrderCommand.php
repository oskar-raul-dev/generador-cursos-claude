<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Actor;

final readonly class CreateOrderCommand
{
    /** @param list<LineRequest> $lines */
    public function __construct(public Actor $actor, public string $idempotencyKey, public string $requestHash, public array $lines) {}
}
