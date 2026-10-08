<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Actor;
use Hex\Application\Port\Clock;
use Hex\Application\Port\IdGenerator;
use Hex\Application\Port\Inventory;
use Hex\Application\Port\Orders;
use Hex\Application\Port\PendingPublications;
use Hex\Application\Port\UnitOfWork;
use Hex\Domain\Order;

/**
 * Parte 2. El agregado decide si puede; aplicación coordina liberar la reserva y dejar el hecho
 * en la outbox, todo en la misma transacción. La entrega ocurre después del commit.
 */
final readonly class CancelOrder
{
    public function __construct(
        private Orders $orders,
        private Inventory $inventory,
        private PendingPublications $pending,
        private IdGenerator $ids,
        private Clock $clock,
        private UnitOfWork $unitOfWork,
    ) {}

    public function execute(Actor $actor, string $orderId): Order
    {
        return $this->unitOfWork->run(function () use ($actor, $orderId): Order {
            $order = VisibleOrders::load($this->orders, $actor, $orderId);
            if ($order->cancel($this->clock->now(), $this->ids->next())) {
                $this->inventory->release($order->id);
                $this->orders->save($order);
                foreach ($order->pullEvents() as $event) {
                    $this->pending->add($event);
                }
            }

            return $order;
        });
    }
}
