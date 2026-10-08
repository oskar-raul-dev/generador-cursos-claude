<?php

declare(strict_types=1);

namespace App\Payment;

use Hex\Application\Port\PaymentGateway;
use Hex\Domain\Money;
use Hex\Domain\Payment;
use Hex\Domain\PaymentStatus;

/** El proveedor de pagos de las partes 1–3: la regla determinista de §11 de la guía. */
final class DeterministicPaymentGateway implements PaymentGateway
{
    public function authorize(string $operationId, Money $amount): Payment
    {
        if ($amount->isGreaterThan(Money::usd('1000.00'))) {
            return new Payment(PaymentStatus::REJECTED, $operationId, null);
        }
        if ($amount->hasAmount('666.00')) {
            return new Payment(PaymentStatus::PENDING, $operationId, null);   // el proveedor "no respondió"
        }

        return new Payment(PaymentStatus::AUTHORIZED, $operationId, "gw-{$operationId}");
    }
}
