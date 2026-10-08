<?php

declare(strict_types=1);

namespace Hex\Domain;

use DateTimeImmutable;
use Hex\Domain\Error\EmptyOrder;
use Hex\Domain\Error\OrderNotCancellable;
use Hex\Domain\Error\OrderNotPayable;
use Hex\Domain\Event\DomainEvent;
use Hex\Domain\Event\OrderCancelled;

/**
 * El agregado: protege que haya líneas y que las transiciones sean las del contrato. No sabe de
 * HTTP, de Laravel ni del proveedor de pagos. Es una clase ordinaria, no un modelo Eloquent.
 * `public private(set)` (PHP 8.4): se lee desde fuera, solo se cambia desde dentro.
 */
final class Order
{
    /** @var list<DomainEvent> */
    private array $events = [];

    /** @param list<OrderLine> $lines */
    private function __construct(
        public readonly string $id,
        public readonly string $customerId,
        public readonly array $lines,
        public readonly Money $total,
        public readonly DateTimeImmutable $createdAt,
        public private(set) OrderStatus $status,
        public private(set) ?Payment $payment,
        public readonly int $version,
    ) {}

    /**
     * Crear un pedido: nace CONFIRMED (reservado, sin pagar).
     *
     * @param list<OrderLine> $lines
     */
    public static function place(string $id, string $customerId, array $lines, DateTimeImmutable $now): self
    {
        if ($lines === []) {
            throw new EmptyOrder();
        }
        $total = $lines[0]->lineTotal();
        foreach (array_slice($lines, 1) as $line) {
            $total = $total->plus($line->lineTotal());
        }

        return new self($id, $customerId, $lines, $total, $now, OrderStatus::CONFIRMED, null, 0);
    }

    /** @param list<OrderLine> $lines */
    public static function reconstitute(
        string $id,
        string $customerId,
        array $lines,
        Money $total,
        DateTimeImmutable $createdAt,
        OrderStatus $status,
        ?Payment $payment,
        int $version,
    ): self {
        return new self($id, $customerId, $lines, $total, $createdAt, $status, $payment, $version);
    }

    public function isPayable(): bool
    {
        return in_array($this->status, [OrderStatus::CONFIRMED, OrderStatus::PAYMENT_REJECTED], true);
    }

    public function isCancellable(): bool
    {
        return in_array($this->status, [OrderStatus::CONFIRMED, OrderStatus::PAYMENT_REJECTED, OrderStatus::PAYMENT_PENDING], true);
    }

    /** PENDING no es un rechazo: el pedido queda a la espera y no vuelve a ser pagable. */
    public function applyPayment(Payment $result): void
    {
        if (! $this->isPayable()) {
            throw new OrderNotPayable($this->status);
        }
        $this->payment = $result;
        $this->status = $result->status->orderStatus();
    }

    /** Idempotente: la segunda vez no cambia nada ni emite el hecho. True si hubo transición. */
    public function cancel(DateTimeImmutable $now, string $eventId): bool
    {
        if ($this->status === OrderStatus::CANCELLED) {
            return false;
        }
        if (! $this->isCancellable()) {
            throw new OrderNotCancellable($this->status);
        }
        $this->status = OrderStatus::CANCELLED;
        $this->events[] = new OrderCancelled($eventId, $this->id, $this->customerId, $now);

        return true;
    }

    /** @return list<DomainEvent> */
    public function pullEvents(): array
    {
        [$pulled, $this->events] = [$this->events, []];

        return $pulled;
    }
}
