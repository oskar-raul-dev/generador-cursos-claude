<?php

declare(strict_types=1);

namespace Hex\Domain;

/** Resultado de un intento de autorización. operationId es la Idempotency-Key del intento. */
final readonly class Payment
{
    public function __construct(public PaymentStatus $status, public string $operationId, public ?string $reference) {}
}
