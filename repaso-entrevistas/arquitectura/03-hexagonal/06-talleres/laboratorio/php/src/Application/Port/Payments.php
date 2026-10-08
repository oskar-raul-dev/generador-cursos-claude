<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use Hex\Domain\Money;
use Hex\Domain\Payment;

interface Payments
{
    public function record(string $orderId, Payment $payment, Money $amount): void;
}
