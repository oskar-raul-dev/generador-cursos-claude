<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Domain\Order;

final readonly class CreateOrderResult
{
    public function __construct(public Order $order, public bool $replayed) {}
}
