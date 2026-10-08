<?php

declare(strict_types=1);

namespace App\Persistence\Postgres;

use Hex\Application\Port\Payments;
use Hex\Domain\Money;
use Hex\Domain\Payment;
use Illuminate\Database\ConnectionInterface;
use Illuminate\Support\Str;

final readonly class PgPayments implements Payments
{
    public function __construct(private ConnectionInterface $db) {}

    public function record(string $orderId, Payment $payment, Money $amount): void
    {
        $this->db->insert(
            'INSERT INTO payments (id, order_id, operation_id, status, reference, amount, currency)
             VALUES (CAST(:id AS uuid), CAST(:o AS uuid), :op, :status, :ref, CAST(:amount AS numeric), :currency)',
            ['id' => (string) Str::uuid(), 'o' => $orderId, 'op' => $payment->operationId, 'status' => $payment->status->value,
                'ref' => $payment->reference, 'amount' => $amount->text(), 'currency' => $amount->currency],
        );
    }
}
