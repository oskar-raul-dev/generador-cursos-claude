<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use Hex\Application\Page;
use Hex\Application\PageRequest;
use Hex\Domain\Order;

interface Orders
{
    public function find(string $id): ?Order;

    public function save(Order $order): void;

    /** @return Page<Order> */
    public function list(?string $customerId, PageRequest $page): Page;
}
