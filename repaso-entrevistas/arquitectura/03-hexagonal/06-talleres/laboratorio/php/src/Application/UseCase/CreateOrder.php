<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Error\IdempotencyKeyReused;
use Hex\Application\Error\NotFound;
use Hex\Application\Port\Clock;
use Hex\Application\Port\IdempotencyStore;
use Hex\Application\Port\IdGenerator;
use Hex\Application\Port\Inventory;
use Hex\Application\Port\Orders;
use Hex\Application\Port\Products;
use Hex\Application\Port\UnitOfWork;
use Hex\Domain\Order;
use Hex\Domain\OrderLine;
use RuntimeException;

/**
 * Crear un pedido reservando el inventario de todas sus líneas, o nada. Una transacción rodea
 * idempotencia, catálogo, pedido, reserva y clave: si algo falla, todo se revierte.
 */
final readonly class CreateOrder
{
    public function __construct(
        private Products $products,
        private Inventory $inventory,
        private Orders $orders,
        private IdempotencyStore $idempotency,
        private IdGenerator $ids,
        private Clock $clock,
        private UnitOfWork $unitOfWork,
    ) {}

    public function execute(CreateOrderCommand $command): CreateOrderResult
    {
        return $this->unitOfWork->run(function () use ($command): CreateOrderResult {
            $actorId = $command->actor->id;
            $stored = $this->idempotency->find($actorId, $command->idempotencyKey);
            if ($stored !== null) {
                if ($stored->requestHash !== $command->requestHash) {
                    throw new IdempotencyKeyReused();
                }
                $previous = $this->orders->find($stored->body)
                    ?? throw new RuntimeException("idempotency key points to a missing order {$stored->body}");

                return new CreateOrderResult($previous, replayed: true);
            }

            // Catálogo primero (404), inventario después (409): un SKU inexistente no deja reservas.
            $lines = [];
            foreach ($command->lines as $line) {
                $product = $this->products->find($line->sku) ?? throw new NotFound('PRODUCT', $line->sku);
                $lines[] = new OrderLine($product->sku, $product->name, $line->quantity, $product->unitPrice);
            }

            $order = Order::place($this->ids->next(), $actorId, $lines, $this->clock->now());
            $this->orders->save($order);                    // primero el pedido: las reservas lo referencian
            $this->inventory->reserve($order->id, $lines);  // InsufficientInventory → rollback de todo
            $this->idempotency->save($actorId, $command->idempotencyKey, $command->requestHash, 201, $order->id);

            return new CreateOrderResult($order, replayed: false);
        });
    }
}
