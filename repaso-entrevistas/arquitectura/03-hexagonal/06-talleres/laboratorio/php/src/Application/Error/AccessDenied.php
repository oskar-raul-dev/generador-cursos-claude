<?php

declare(strict_types=1);

namespace Hex\Application\Error;

final class AccessDenied extends ApplicationError
{
    public function __construct()
    {
        parent::__construct('actor lacks the required capability');
    }
}
