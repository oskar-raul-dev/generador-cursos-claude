<?php

declare(strict_types=1);

namespace Tests\Unit;

use DateTimeImmutable;
use Hex\Domain\Error\EmptyOrder;
use Hex\Domain\Error\OrderNotCancellable;
use Hex\Domain\Error\OrderNotPayable;
use Hex\Domain\Money;
use Hex\Domain\Order;
use Hex\Domain\OrderLine;
use Hex\Domain\OrderStatus;
use Hex\Domain\Payment;
use Hex\Domain\PaymentStatus;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

final class OrderTest extends TestCase
{
    private static function order(): Order
    {
        return Order::place('order-1', 'ana', [new OrderLine('SKU-001', 'Keyboard', 2, Money::usd('49.90'))], new DateTimeImmutable('2026-09-27T12:00:00Z'));
    }

    #[Test]
    public function is_born_confirmed_with_its_total(): void
    {
        $order = self::order();
        self::assertSame(OrderStatus::CONFIRMED, $order->status);
        self::assertSame('99.80', $order->total->text());
    }

    #[Test]
    public function rejects_an_empty_order(): void
    {
        $this->expectException(EmptyOrder::class);
        Order::place('order-2', 'ana', [], new DateTimeImmutable());
    }

    #[Test]
    public function pending_is_not_a_rejection_and_blocks_a_second_payment(): void
    {
        $order = self::order();
        $order->applyPayment(new Payment(PaymentStatus::PENDING, 'op-1', null));
        self::assertSame(OrderStatus::PAYMENT_PENDING, $order->status);
        $this->expectException(OrderNotPayable::class);
        $order->applyPayment(new Payment(PaymentStatus::AUTHORIZED, 'op-2', 'gw-op-2'));
    }

    #[Test]
    public function cancel_is_idempotent_and_emits_once(): void
    {
        $order = self::order();
        self::assertTrue($order->cancel(new DateTimeImmutable(), 'evt-1'));
        self::assertFalse($order->cancel(new DateTimeImmutable(), 'evt-2'));
        self::assertCount(1, $order->pullEvents());
        self::assertCount(0, $order->pullEvents());
    }

    #[Test]
    public function a_paid_order_cannot_be_cancelled(): void
    {
        $order = self::order();
        $order->applyPayment(new Payment(PaymentStatus::AUTHORIZED, 'op-1', 'gw-op-1'));
        $this->expectException(OrderNotCancellable::class);
        $order->cancel(new DateTimeImmutable(), 'evt-1');
    }
}
