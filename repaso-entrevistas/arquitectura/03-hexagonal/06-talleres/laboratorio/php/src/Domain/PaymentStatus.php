<?php

declare(strict_types=1);

namespace Hex\Domain;

enum PaymentStatus: string
{
    case AUTHORIZED = 'AUTHORIZED';
    case REJECTED = 'REJECTED';
    case PENDING = 'PENDING';

    /** A qué estado lleva el pedido cada resultado. PENDING no es un rechazo. */
    public function orderStatus(): OrderStatus
    {
        return match ($this) {
            self::AUTHORIZED => OrderStatus::PAID,
            self::REJECTED => OrderStatus::PAYMENT_REJECTED,
            self::PENDING => OrderStatus::PAYMENT_PENDING,
        };
    }
}
