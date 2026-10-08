<?php

declare(strict_types=1);

namespace Hex\Domain\Error;

final class EmptyOrder extends DomainError
{
    public function __construct()
    {
        parent::__construct('an order must have at least one line');
    }
}
