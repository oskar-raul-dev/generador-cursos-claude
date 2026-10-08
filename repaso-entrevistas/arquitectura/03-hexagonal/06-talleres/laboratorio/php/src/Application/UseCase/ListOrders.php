<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Actor;
use Hex\Application\Page;
use Hex\Application\PageRequest;
use Hex\Application\Port\Orders;
use Hex\Domain\Order;

final readonly class ListOrders
{
    public function __construct(private Orders $orders) {}

    /** @return Page<Order> */
    public function execute(Actor $actor, PageRequest $page): Page
    {
        return $this->orders->list($actor->isOperator() ? null : $actor->id, $page);
    }
}
