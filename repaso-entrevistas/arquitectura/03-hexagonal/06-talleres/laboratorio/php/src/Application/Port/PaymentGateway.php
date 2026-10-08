<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use Hex\Domain\Money;
use Hex\Domain\Payment;

interface PaymentGateway
{
    public function authorize(string $operationId, Money $amount): Payment;
}
