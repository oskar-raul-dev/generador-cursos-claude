<?php

declare(strict_types=1);

namespace Hex\Application\Error;

final class InvalidCredentials extends ApplicationError
{
    public function __construct()
    {
        parent::__construct('invalid credentials');
    }
}
