<?php

declare(strict_types=1);

namespace Hex\Application\Error;

final class ProductAlreadyExists extends ApplicationError
{
    public function __construct(public readonly string $sku)
    {
        parent::__construct("{$sku} already exists");
    }
}
