<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Actor;
use Hex\Application\Error\IdempotencyKeyReused;
use Hex\Application\Port\IdempotencyStore;
use Hex\Application\Port\Orders;
use Hex\Application\Port\PaymentGateway;
use Hex\Application\Port\Payments;
use Hex\Application\Port\UnitOfWork;
use Hex\Domain\Error\OrderNotPayable;
use Hex\Domain\Order;
use RuntimeException;

/**
 * La llamada al proveedor queda FUERA de la transacción: una transacción abierta durante una
 * llamada remota bloquea filas mientras espera a un tercero. Dos unidades de trabajo.
 */
final readonly class AuthorizePayment
{
    public function __construct(
        private Orders $orders,
        private Payments $payments,
        private PaymentGateway $gateway,
        private IdempotencyStore $idempotency,
        private UnitOfWork $unitOfWork,
    ) {}

    public function execute(Actor $actor, string $orderId, string $idempotencyKey): AuthorizePaymentResult
    {
        $requestHash = "payment:{$orderId}";

        // 1. Comprobar: repetición, existencia, visibilidad y estado pagable.
        $order = $this->unitOfWork->run(function () use ($actor, $orderId, $idempotencyKey, $requestHash): ?Order {
            $stored = $this->idempotency->find($actor->id, $idempotencyKey);
            if ($stored !== null) {
                if ($stored->requestHash !== $requestHash) {
                    throw new IdempotencyKeyReused();
                }

                return null;  // repetición: se resuelve abajo
            }
            $found = VisibleOrders::load($this->orders, $actor, $orderId);
            if (! $found->isPayable()) {
                throw new OrderNotPayable($found->status);
            }

            return $found;
        });
        if ($order === null) {
            $previous = VisibleOrders::load($this->orders, $actor, $orderId);
            $payment = $previous->payment ?? throw new RuntimeException('replayed payment without a recorded result');

            return new AuthorizePaymentResult($previous, $payment, replayed: true);
        }

        // 2. Proveedor, sin transacción abierta. La clave del intento es la del cliente y no se regenera.
        $payment = $this->gateway->authorize($idempotencyKey, $order->total);

        // 3. Aplicar el resultado y guardar la clave con el efecto.
        return $this->unitOfWork->run(function () use ($actor, $orderId, $idempotencyKey, $requestHash, $payment): AuthorizePaymentResult {
            $current = VisibleOrders::load($this->orders, $actor, $orderId);
            $current->applyPayment($payment);
            $this->orders->save($current);
            $this->payments->record($current->id, $payment, $current->total);
            $this->idempotency->save($actor->id, $idempotencyKey, $requestHash, 200, $current->id);

            return new AuthorizePaymentResult($current, $payment, replayed: false);
        });
    }
}
