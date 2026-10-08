<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Actor;
use Hex\Application\Error\NotFound;
use Hex\Application\Port\Orders;
use Hex\Domain\Order;

/** Un customer solo ve lo suyo; lo ajeno responde "no existe". */
final class VisibleOrders
{
    public static function load(Orders $orders, Actor $actor, string $orderId): Order
    {
        $order = $orders->find($orderId);
        if ($order === null || ! $actor->canSee($order)) {
            throw new NotFound('ORDER', $orderId);
        }

        return $order;
    }
}
