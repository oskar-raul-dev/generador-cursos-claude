<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Actor;
use Hex\Application\Port\Orders;
use Hex\Domain\Order;

final readonly class GetOrder
{
    public function __construct(private Orders $orders) {}

    public function execute(Actor $actor, string $orderId): Order
    {
        return VisibleOrders::load($this->orders, $actor, $orderId);
    }
}
