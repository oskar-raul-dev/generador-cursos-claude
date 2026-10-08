<?php

declare(strict_types=1);

namespace Hex\Application;

enum Role: string
{
    case CUSTOMER = 'CUSTOMER';
    case OPERATOR = 'OPERATOR';
}
