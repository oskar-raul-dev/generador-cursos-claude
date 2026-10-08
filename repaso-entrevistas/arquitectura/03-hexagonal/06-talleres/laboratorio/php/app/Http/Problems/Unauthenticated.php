<?php

declare(strict_types=1);

namespace App\Http\Problems;

use RuntimeException;
use Throwable;

final class Unauthenticated extends RuntimeException
{
    /** @param 'UNAUTHENTICATED'|'TOKEN_REVOKED' $code */
    public function __construct(public readonly string $problemCode, ?Throwable $previous = null)
    {
        parent::__construct($problemCode, 0, $previous);
    }
}
