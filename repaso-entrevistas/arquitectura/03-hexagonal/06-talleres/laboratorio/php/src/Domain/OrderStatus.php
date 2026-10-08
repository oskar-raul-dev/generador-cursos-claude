<?php

declare(strict_types=1);

namespace Hex\Domain;

/** Los estados del contrato, como enum: un string fuera de esta lista no compila. */
enum OrderStatus: string
{
    case CONFIRMED = 'CONFIRMED';
    case PAID = 'PAID';
    case PAYMENT_REJECTED = 'PAYMENT_REJECTED';
    case PAYMENT_PENDING = 'PAYMENT_PENDING';
    case CANCELLED = 'CANCELLED';
}
