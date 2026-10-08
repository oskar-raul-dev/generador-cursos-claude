<?php

declare(strict_types=1);

namespace Hex\Application\Error;

final class IdempotencyKeyReused extends ApplicationError
{
    public function __construct()
    {
        parent::__construct('Idempotency-Key reused with a different payload');
    }
}
