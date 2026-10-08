<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Domain\Order;
use Hex\Domain\Payment;

final readonly class AuthorizePaymentResult
{
    public function __construct(public Order $order, public Payment $payment, public bool $replayed) {}
}
