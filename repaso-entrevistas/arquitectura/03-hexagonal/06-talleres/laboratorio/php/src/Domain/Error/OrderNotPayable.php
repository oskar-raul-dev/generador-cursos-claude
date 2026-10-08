<?php

declare(strict_types=1);

namespace Hex\Domain\Error;

use Hex\Domain\OrderStatus;

final class OrderNotPayable extends DomainError
{
    public function __construct(public readonly OrderStatus $status)
    {
        parent::__construct("order is {$status->value}");
    }
}
